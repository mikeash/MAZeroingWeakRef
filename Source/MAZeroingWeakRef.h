//
//  MAZeroingWeakRef.h
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//

#import <Cocoa/Cocoa.h>


@interface MAZeroingWeakRef : NSObject
{
    id _target;
    void (^_cleanupBlock)(id target);
}

+ (BOOL)canRefCoreFoundationObjects;

+ (id)refWithTarget: (id)target;

- (id)initWithTarget: (id)target;

// cleanup block runs while the global ZWR lock is held
// so make it short and sweet!
// use GCD or something to schedule execution later
// if you need to do something that may take a while
//
// it is unsafe to call -target on the weak ref from
// inside the cleanup block, which is why the target
// is passed in as a parameter
// note that you must not resurrect the target at this point!
- (void)setCleanupBlock: (void (^)(id target))block;

- (id)target;

@end
