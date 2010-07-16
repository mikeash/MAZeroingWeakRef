//
//  MAZeroingWeakRef.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//

#import "MAZeroingWeakRef.h"

#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <pthread.h>


/*
 The COREFOUNDATION_HACK_LEVEL macro allows you to control how much horrible CF
 hackery is enabled. The following levels are defined:
 
 2 - Full-on hackery allows weak references to CF objects by doing horrible
 things with the private CF class table.
 
 1 - Mild hackery allows foolproof identification of CF objects and will assert
 if trying to make a ZWR to one.
 
 0 - No hackery, checks for an "NSCF" prefix in the class name to identify CF
 objects and will assert if trying to make a ZWR to one
 */
#define COREFOUNDATION_HACK_LEVEL 2

@interface MAZeroingWeakRef ()

- (void)_zeroTarget;

@end


@implementation MAZeroingWeakRef

#if COREFOUNDATION_HACK_LEVEL >= 2

typedef struct __CFRuntimeClass {	// Version 0 struct
    CFIndex version;
    const char *className;
    void (*init)(CFTypeRef cf);
    CFTypeRef (*copy)(CFAllocatorRef allocator, CFTypeRef cf);
    void (*finalize)(CFTypeRef cf);
    Boolean (*equal)(CFTypeRef cf1, CFTypeRef cf2);
    CFHashCode (*hash)(CFTypeRef cf);
    CFStringRef (*copyFormattingDesc)(CFTypeRef cf, CFDictionaryRef formatOptions);	// str with retain
    CFStringRef (*copyDebugDesc)(CFTypeRef cf);	// str with retain
    void (*reclaim)(CFTypeRef cf);
} CFRuntimeClass;

extern CFRuntimeClass * _CFRuntimeGetClassWithTypeID(CFTypeID typeID);

typedef void (*CFFinalizeFptr)(CFTypeRef);
static CFFinalizeFptr *gCFOriginalFinalizes;
static size_t gCFOriginalFinalizesSize;

#endif

#if COREFOUNDATION_HACK_LEVEL >= 1

extern Class *__CFRuntimeObjCClassTable;

#endif

static pthread_mutex_t gMutex;

static void *gRefHashTableKey = &gRefHashTableKey;

static NSMutableSet *gCustomSubclasses;
static NSMutableDictionary *gCustomSubclassMap; // maps regular classes to their custom subclasses

+ (void)initialize
{
    if(self == [MAZeroingWeakRef class])
    {
        CFStringCreateMutable(NULL, 0);
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&gMutex, &mutexattr);
        pthread_mutexattr_destroy(&mutexattr);
        
        gCustomSubclasses = [[NSMutableSet alloc] init];
        gCustomSubclassMap = [[NSMutableDictionary alloc] init];
    }
}

static void WhileLocked(void (^block)(void))
{
    pthread_mutex_lock(&gMutex);
    block();
    pthread_mutex_unlock(&gMutex);
}

static Class GetCustomSubclass(id obj)
{
    Class class = object_getClass(obj);
    while(class && ![gCustomSubclasses containsObject: class])
        class = class_getSuperclass(class);
    return class;
}

static Class GetRealSuperclass(id obj)
{
    Class class = GetCustomSubclass(obj);
    NSCAssert(class, @"Coudn't find ZeroingWeakRef subclass in hierarchy starting from %@, should never happen", object_getClass(obj));
    return class_getSuperclass(class);
}

static void CustomSubclassRelease(id self, SEL _cmd)
{
    Class superclass = GetRealSuperclass(self);
    IMP superRelease = class_getMethodImplementation(superclass, @selector(release));
    WhileLocked(^{
        ((void (*)(id, SEL))superRelease)(self, _cmd);
    });
}

static void CustomSubclassDealloc(id self, SEL _cmd)
{
    NSHashTable *table = objc_getAssociatedObject(self, gRefHashTableKey);
    for(MAZeroingWeakRef *ref in table)
        [ref _zeroTarget];
    
    Class superclass = GetRealSuperclass(self);
    IMP superDealloc = class_getMethodImplementation(superclass, @selector(dealloc));
    ((void (*)(id, SEL))superDealloc)(self, _cmd);
}

#if COREFOUNDATION_HACK_LEVEL >= 2

static void CustomCFFinalize(CFTypeRef cf)
{
    WhileLocked(^{
        if(CFGetRetainCount(cf) == 1)
        {
            NSHashTable *table = objc_getAssociatedObject((id)cf, gRefHashTableKey);
            for(MAZeroingWeakRef *ref in table)
                [ref _zeroTarget];
            [table removeAllObjects];
            
            void (*fptr)(CFTypeRef) = gCFOriginalFinalizes[CFGetTypeID(cf)];
            if(fptr)
                fptr(cf);
        }
    });
}

#endif

static BOOL IsTollFreeBridged(Class class, id obj)
{
#if COREFOUNDATION_HACK_LEVEL >= 1
    CFTypeID typeID = CFGetTypeID(obj);
    Class tfbClass = __CFRuntimeObjCClassTable[typeID];
    return class == tfbClass;
#else
    return [NSStringFromClass(class) hasPrefix: @"NSCF"];
#endif
}

static Class CreateCustomSubclass(Class class, id obj)
{
    if(IsTollFreeBridged(class, obj))
    {
#if COREFOUNDATION_HACK_LEVEL >= 2
        CFTypeID typeID = CFGetTypeID(obj);
        CFRuntimeClass *cfclass = _CFRuntimeGetClassWithTypeID(typeID);
        
        if(typeID >= gCFOriginalFinalizesSize)
        {
            gCFOriginalFinalizesSize = typeID + 1;
            gCFOriginalFinalizes = realloc(gCFOriginalFinalizes, gCFOriginalFinalizesSize * sizeof(*gCFOriginalFinalizes));
        }
        
        do {
            gCFOriginalFinalizes[typeID] = cfclass->finalize;
        } while(!OSAtomicCompareAndSwapPtrBarrier(gCFOriginalFinalizes[typeID], CustomCFFinalize, (void *)&cfclass->finalize));
#else
        NSCAssert(0, @"Cannot create zeroing weak reference to object of type %@ with COREFOUNDATION_HACK_LEVEL set to %d", class, COREFOUNDATION_HACK_LEVEL);
#endif
        return class;
    }
    else
    {
        NSString *newName = [NSString stringWithFormat: @"%s_MAZeroingWeakRefSubclass", class_getName(class)];
        const char *newNameC = [newName UTF8String];
        
        Class subclass = objc_allocateClassPair(class, newNameC, 0);
        
        Method release = class_getInstanceMethod(class, @selector(release));
        Method dealloc = class_getInstanceMethod(class, @selector(dealloc));
        class_addMethod(subclass, @selector(release), (IMP)CustomSubclassRelease, method_getTypeEncoding(release));
        class_addMethod(subclass, @selector(dealloc), (IMP)CustomSubclassDealloc, method_getTypeEncoding(dealloc));
        
        objc_registerClassPair(subclass);
        
        return subclass;
    }
}

static void EnsureCustomSubclass(id obj)
{
    if(!GetCustomSubclass(obj))
    {
        Class class = object_getClass(obj);
        Class subclass = [gCustomSubclassMap objectForKey: class];
        if(!subclass)
        {
            subclass = CreateCustomSubclass(class, obj);
            [gCustomSubclassMap setObject: subclass forKey: class];
            [gCustomSubclasses addObject: subclass];
        }
        object_setClass(obj, subclass);
    }
}

static void RegisterRef(MAZeroingWeakRef *ref, id target)
{
    WhileLocked(^{
        EnsureCustomSubclass(target);
        
        NSHashTable *table = objc_getAssociatedObject(target, gRefHashTableKey);
        if(!table)
        {
            table = [NSHashTable hashTableWithWeakObjects];
            objc_setAssociatedObject(target, gRefHashTableKey, table, OBJC_ASSOCIATION_RETAIN);
        }
        [table addObject: ref];
    });
}

static void UnregisterRef(MAZeroingWeakRef *ref)
{
    WhileLocked(^{
        id target = ref->_target;
        
        if(target)
        {
            NSHashTable *table = objc_getAssociatedObject(target, gRefHashTableKey);
            [table removeObject: ref];
        }
    });
}

+ (BOOL)canRefCoreFoundationObjects
{
    return COREFOUNDATION_HACK_LEVEL >= 2;
}

+ (id)refWithTarget: (id)target
{
    return [[[self alloc] initWithTarget: target] autorelease];
}

- (id)initWithTarget: (id)target
{
    if((self = [self init]))
    {
        _target = target;
        RegisterRef(self, target);
    }
    return self;
}

- (void)dealloc
{
    UnregisterRef(self);
#if NS_BLOCKS_AVAILABLE
    [_cleanupBlock release];
#endif
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"<%@: %p -> %@>", [self class], self, [self target]];
}

#if NS_BLOCKS_AVAILABLE
- (void)setCleanupBlock: (void (^)(id target))block
{
    block = [block copy];
    [_cleanupBlock release];
    _cleanupBlock = block;
}
#endif

- (id)target
{
    __block id ret;
    WhileLocked(^{
        ret = [_target retain];
    });
    return [ret autorelease];
}

- (void)_zeroTarget
{
#if NS_BLOCKS_AVAILABLE
    if(_cleanupBlock)
    {
        _cleanupBlock(_target);
        [_cleanupBlock release];
        _cleanupBlock = nil;
    }
#endif
    _target = nil;
}

@end
