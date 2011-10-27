//
//  NSTimer+MAWeakTimer.h
//  ZeroingWeakRef
//
//  Created by Remy Demarest on 27/10/2011.
//  Copyright (c) 2011 NuLayer Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (MAWeakTimer)
+ (NSTimer *)scheduledWeakTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
+ (NSTimer *)weakTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
@end
