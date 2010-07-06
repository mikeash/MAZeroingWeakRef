//
//  MAZeroingWeakRef.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 Michael Ash. All rights reserved.
//

#import "MAZeroingWeakRef.h"

#import <objc/runtime.h>
#import <pthread.h>


@interface MAZeroingWeakRef ()

- (void)_zeroTarget;

@end


@implementation MAZeroingWeakRef

static pthread_mutex_t gMutex;

static char gRefHashTableKeyTarget;
static void *gRefHashTableKey = &gRefHashTableKeyTarget;

static NSMutableSet *gCustomSubclasses;
static NSMutableDictionary *gCustomSubclassMap; // maps regular classes to their custom subclasses

+ (void)initialize
{
    if(self == [MAZeroingWeakRef class])
    {
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&gMutex, &mutexattr);
        pthread_mutexattr_destroy(&mutexattr);
        
        gCustomSubclasses = [[NSMutableSet alloc] init];
        gCustomSubclassMap = [[NSMutableDictionary alloc] init];
    }
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
    pthread_mutex_lock(&gMutex);
    
    Class superclass = GetRealSuperclass(self);
    IMP superRelease = class_getMethodImplementation(superclass, @selector(release));
    ((void (*)(id, SEL))superRelease)(self, _cmd);
    
    pthread_mutex_unlock(&gMutex);
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

static BOOL MustNotSubclass(Class class)
{
    return strncmp(class_getName(class), "NSCF", 4) == 0;
}

static Class CreateCustomSubclass(Class class)
{
    NSCAssert1(!MustNotSubclass(class), @"Cannot create a weak reference to toll-free bridged class %@", class);
    
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

static void EnsureCustomSubclass(id obj)
{
    if(!GetCustomSubclass(obj))
    {
        Class class = object_getClass(obj);
        Class subclass = [gCustomSubclassMap objectForKey: class];
        if(!subclass)
        {
            subclass = CreateCustomSubclass(class);
            [gCustomSubclassMap setObject: subclass forKey: class];
            [gCustomSubclasses addObject: subclass];
        }
        object_setClass(obj, subclass);
    }
}

static void RegisterRef(MAZeroingWeakRef *ref, id target)
{
    pthread_mutex_lock(&gMutex);
    
    EnsureCustomSubclass(target);
    
    NSHashTable *table = objc_getAssociatedObject(target, gRefHashTableKey);
    if(!table)
    {
        table = [NSHashTable hashTableWithWeakObjects];
        objc_setAssociatedObject(target, gRefHashTableKey, table, OBJC_ASSOCIATION_RETAIN);
    }
    [table addObject: ref];
    
    pthread_mutex_unlock(&gMutex);
}

static void UnregisterRef(MAZeroingWeakRef *ref)
{
    pthread_mutex_lock(&gMutex);
    
    id target = ref->_target;
    
    if(target)
    {
        NSHashTable *table = objc_getAssociatedObject(target, gRefHashTableKey);
        [table removeObject: ref];
    }
    
    pthread_mutex_unlock(&gMutex);
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
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"<%@: %p -> %@>", [self class], self, _target];
}

- (id)target
{
    pthread_mutex_lock(&gMutex);
    id ret = [[_target retain] autorelease];
    pthread_mutex_unlock(&gMutex);
    return ret;
}

- (void)_zeroTarget
{
    _target = nil;
}

@end
