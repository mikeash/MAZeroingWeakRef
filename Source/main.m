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
    
    NSLog(@"obj: %@  ref: %@", obj, ref);
    NSLog(@"Releasing obj");
    [obj release];
    NSLog(@"ref: %@", ref);
    
    [pool drain];
    
    sleep(1000);
    
    return 0;
}

