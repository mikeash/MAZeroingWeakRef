//
//  main.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "MAZeroingWeakRef.h"


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
    
    NSLog(@"Done!");
    [pool drain];
    sleep(1000);
    
    return 0;
}

