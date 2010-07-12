//
//  main.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "MANotificationCenterAdditions.h"
#import "MAZeroingWeakRef.h"


@interface NotificationReceiver : NSObject {} @end
@implementation NotificationReceiver

- (void)gotNote: (NSNotification *)note
{
    NSLog(@"%@ got note %@", self, note);
}

@end

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"obj is %@", obj);
    NSLog(@"Creating weak ref");
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: ref];
    
    [ref target];
    NSLog(@"obj: %@  ref: %@  ref2: %@", obj, ref, ref2);
    NSLog(@"Releasing obj");
    [obj release];
    NSLog(@"ref: %@  ref2: %@", ref, ref2);
    [ref release];
    NSLog(@"ref2: %@", ref2);
    [ref2 release];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSLog(@"array: %@", array);
    ref = [[MAZeroingWeakRef alloc] initWithTarget: array];
    NSLog(@"array: %@  ref: %@", array, ref);
    [array release];
    NSLog(@"ref: %@  target: %p %@", ref, [ref target], [ref target]);
    [ref release];
    
    NSString *str = [[NSMutableString alloc] initWithString: @"Test String"];
    NSLog(@"str: %@", str);
    ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
    NSLog(@"str: %@  ref: %@", str, ref);
    [str release];
    NSLog(@"ref: %@  target: %p %@", ref, [ref target], [ref target]);
    [ref release];
    
    __block BOOL cleanedUp = NO;
    str = [[NSMutableString alloc] initWithString: @"Test String"];
    ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
    [ref setCleanupBlock: ^(id target) { cleanedUp = YES; }];
    [str release];
    NSLog(@"ref: %@  cleanedUp: %d", ref, cleanedUp);
    [ref release];
    
    NotificationReceiver *receiver = [[NotificationReceiver alloc] init];
    [[NSNotificationCenter defaultCenter] addWeakObserver: receiver selector: @selector(gotNote:) name: @"name" object: @"object"];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    NSLog(@"releasing receiver");
    [receiver release];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    
    NSLog(@"Done!");
    [pool drain];
    sleep(1000);
    
    return 0;
}

