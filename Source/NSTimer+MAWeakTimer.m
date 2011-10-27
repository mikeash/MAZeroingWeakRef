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
    
    NSTimer *timer = [self scheduledTimerWithTimeInterval:seconds target:proxy selector:aSelector userInfo:userInfo repeats:repeats];
    
    // Weak retain of the timer to avoid cyclic reference which would prevent the timer from being deallocated until the target is deallocated
    MAWeakDeclare(timer);
    
    [proxy setCleanupBlock:
     ^(id target)
     {
         MAWeakImportReturn(timer);
         
         [timer invalidate];
     }];
    
    return timer;
}

+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
{
    // Use a proxy so the message sent by the timer is passed down directly to the target
    MAZeroingWeakProxy *proxy = [MAZeroingWeakProxy proxyWithTarget:target];
    
    NSTimer *timer = [self timerWithTimeInterval:seconds target:proxy selector:aSelector userInfo:userInfo repeats:repeats];
    
    // Weak retain of the timer to avoid cyclic reference which would prevent the timer from being deallocated until the target is deallocated
    MAWeakDeclare(timer);
    
    [proxy setCleanupBlock:
     ^(id target)
     {
         MAWeakImportReturn(timer);
         
         [timer invalidate];
     }];
    
    return timer;
}

@end
