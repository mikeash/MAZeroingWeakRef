//
//  MAWeakDictionary.h
//  ZeroingWeakRef
//
//  Created by Mike Ash on 7/13/10.
//

#import <Cocoa/Cocoa.h>


@interface MAWeakDictionary : NSMutableDictionary
{
    NSMutableDictionary *_dict;
}

@end
