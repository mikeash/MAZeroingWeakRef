//
//  MAZeroingWeakRef.h
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 Michael Ash. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MAZeroingWeakRef : NSObject
{
    id _target;
    void (^_cleanupBlock)(id target);
}

+ (id)refWithTarget: (id)target;

- (id)initWithTarget: (id)target;

// cleanup block runs while the global ZWR lock is held
// so make it short and sweet!
// use GCD or something to schedule execution later
// if you need to do something that may take a while
- (void)setCleanupBlock: (void (^)(id target))block;

- (id)target;

@end
