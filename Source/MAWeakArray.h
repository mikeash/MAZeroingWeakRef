//
//  MAWeakArray.h
//  ZeroingWeakRef
//
//  Created by Mike Ash on 7/13/10.
//

#import <Cocoa/Cocoa.h>


@interface MAWeakArray : NSMutableArray
{
    NSMutableArray *_weakRefs;
}

@end
