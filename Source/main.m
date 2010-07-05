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
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    [ref2 release];
    
    NSLog(@"obj: %@  ref: %@", obj, ref);
    NSLog(@"Releasing obj");
    [obj release];
    NSLog(@"ref: %@", ref);
    [ref release];
    
    [pool drain];
    
    sleep(1000);
    
    return 0;
}

