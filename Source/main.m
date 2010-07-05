//
//  main.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "MAZeroingWeakRef.h"


int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"obj is %@", obj);
    NSLog(@"Creating weak ref");
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: ref];
    
    NSLog(@"obj: %@  ref: %@  ref2: %@", obj, ref, ref2);
    NSLog(@"Releasing obj");
    [obj release];
    NSLog(@"ref: %@  ref2: %@", ref, ref2);
    [ref release];
    NSLog(@"ref2: %@", ref2);
    [ref2 release];
    
    [pool drain];
    
    sleep(1000);
    
    return 0;
}

