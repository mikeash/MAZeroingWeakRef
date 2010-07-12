//
//  MAZeroingWeakRef.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 Michael Ash. All rights reserved.
//

#import "MAZeroingWeakRef.h"

#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <pthread.h>


@interface MAZeroingWeakRef ()

- (void)_zeroTarget;

@end


@implementation MAZeroingWeakRef

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
extern Class *__CFRuntimeObjCClassTable;


static pthread_mutex_t gMutex;

static char gRefHashTableKeyTarget;
static void *gRefHashTableKey = &gRefHashTableKeyTarget;

static NSMutableSet *gCustomSubclasses;
static NSMutableDictionary *gCustomSubclassMap; // maps regular classes to their custom subclasses

typedef void (*CFFinalizeFptr)(CFTypeRef);
static CFFinalizeFptr *gCFOriginalFinalizes;
static size_t gCFOriginalFinalizesSize;

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
    if(!class)
    {
        NSLog(@"Coudn't find ZeroingWeakRef subclass in hierarchy starting from %@, should never happen, bailing out", object_getClass(obj));
        abort();
    }
    return class_getSuperclass(class);
}

static void CustomSubclassRelease(id self, SEL _cmd)
{
    WhileLocked(^{
        Class superclass = GetRealSuperclass(self);
        IMP superRelease = class_getMethodImplementation(superclass, @selector(release));
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

static void CustomCFFinalize(CFTypeRef cf)
{
    WhileLocked(^{
        if(CFGetRetainCount(cf) == 1)
        {
            NSHashTable *table = objc_getAssociatedObject((id)cf, gRefHashTableKey);
            for(MAZeroingWeakRef *ref in table)
                [ref _zeroTarget];
            void (*fptr)(CFTypeRef) = gCFOriginalFinalizes[CFGetTypeID(cf)];
            if(fptr)
                fptr(cf);
        }
    });
}

static BOOL IsTollFreeBridged(Class class, id obj)
{
    CFTypeID typeID = CFGetTypeID(obj);
    Class tfbClass = __CFRuntimeObjCClassTable[typeID];
    return class == tfbClass;
}

static Class CreateCustomSubclass(Class class, id obj)
{
    if(IsTollFreeBridged(class, obj))
    {
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
    [_cleanupBlock release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"<%@: %p -> %@>", [self class], self, [self target]];
}

- (void)setCleanupBlock: (void (^)(id target))block
{
    block = [block copy];
    [_cleanupBlock release];
    _cleanupBlock = block;
}

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
    if(_cleanupBlock)
        _cleanupBlock(_target);
    _target = nil;
}

@end
