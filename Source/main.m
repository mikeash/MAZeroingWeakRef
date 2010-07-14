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
#import "MAWeakArray.h"
#import "MAWeakDictionary.h"


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
    
    {
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
    }
    
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        NSLog(@"array: %@", array);
        MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: array];
        NSLog(@"array: %@  ref: %@", array, ref);
        [array release];
        NSLog(@"ref: %@  target: %p %@", ref, [ref target], [ref target]);
        [ref release];
    }
    
    {
        NSString *str = [[NSMutableString alloc] initWithString: @"Test String"];
        NSLog(@"str: %@", str);
        MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
        NSLog(@"str: %@  ref: %@", str, ref);
        [str release];
        NSLog(@"ref: %@  target: %p %@", ref, [ref target], [ref target]);
        [ref release];
    }
    
    {
        __block BOOL cleanedUp = NO;
        NSMutableString *str = [[NSMutableString alloc] initWithString: @"Test String"];
        MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
        [ref setCleanupBlock: ^(id target) { cleanedUp = YES; }];
        [str release];
        NSLog(@"ref: %@  cleanedUp: %d", ref, cleanedUp);
        [ref release];
    }
    
    {
        NotificationReceiver *receiver = [[NotificationReceiver alloc] init];
        [[NSNotificationCenter defaultCenter] addWeakObserver: receiver selector: @selector(gotNote:) name: @"name" object: @"object"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
        NSLog(@"releasing receiver");
        [receiver release];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    }
    
    {
        NSString *str1 = [[NSMutableString alloc] initWithString: @"Test String 1"];
        NSString *str2 = [[NSMutableString alloc] initWithString: @"Test String 2"];
        NSString *str3 = [[NSMutableString alloc] initWithString: @"Test String 3"];
        
        MAWeakArray *array = [[MAWeakArray alloc] init];
        [array addObject: str1];
        [array addObject: str2];
        [array addObject: str3];
        
        MAWeakDictionary *dict = [[MAWeakDictionary alloc] init];
        [dict setObject: str1 forKey: @"str1"];
        [dict setObject: str2 forKey: @"str2"];
        [dict setObject: str3 forKey: @"str3"];
        
        NSLog(@"array: %@", array);
        NSLog(@"dict: %@", dict);
        
        [str2 release];
        
        NSLog(@"array: %@", array);
        NSLog(@"dict: %@", dict);
        
        [str1 release];
        [str3 release];
        
        NSLog(@"array: %@", array);
        NSLog(@"dict: %@", dict);
    }
    
    NSLog(@"Done!");
    [pool drain];
    sleep(1000);
    
    return 0;
}

