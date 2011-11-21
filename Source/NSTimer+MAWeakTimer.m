//
//  NSTimer+MAWeakTimer.m
//  ZeroingWeakRef
//
//  Created by Remy Demarest on 27/10/2011.
//  Copyright (c) 2011 NuLayer Inc. All rights reserved.
//

#import "NSTimer+MAWeakTimer.h"
#import "MAZeroingWeakRef.h"
#import "MAZeroingWeakProxy.h"

@implementation NSTimer (MAWeakTimer)

+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
{
    // Use a proxy so the message sent by the timer is passed down directly to the target
    MAZeroingWeakProxy *proxy = [MAZeroingWeakProxy proxyWithTarget:target];
    
    // The timer releases its target as soon as it is invalidated
    // thus releasing the proxy object, the proxy object will then release its cleanup block
    // releasing the cleanup block will end in releasing the timer
    // which in turn will remove all traces of renegade objects from memory
    NSTimer *timer = [self scheduledTimerWithTimeInterval:seconds target:proxy selector:aSelector userInfo:userInfo repeats:repeats];
    
    [proxy setCleanupBlock:
     ^(id target)
     {
         [timer invalidate];
     }];
    
    return timer;
}

+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
{
    // Use a proxy so the message sent by the timer is passed down directly to the target
    MAZeroingWeakProxy *proxy = [MAZeroingWeakProxy proxyWithTarget:target];
    
    // The timer releases its target as soon as it is invalidated
    // thus releasing the proxy object, the proxy object will then release its cleanup block
    // releasing the cleanup block will end in releasing the timer
    // which in turn will remove all traces of renegade objects from memory
    NSTimer *timer = [self timerWithTimeInterval:seconds target:proxy selector:aSelector userInfo:userInfo repeats:repeats];
    
    [proxy setCleanupBlock:
     ^(id target)
     {
         [timer invalidate];
     }];
    
    return timer;
}

@end
