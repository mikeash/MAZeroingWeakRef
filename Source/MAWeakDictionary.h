//
//  MAWeakDictionary.h
//  ZeroingWeakRef
//
//  Created by Mike Ash on 7/13/10.
//  Copyright 2010 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MAWeakDictionary : NSMutableDictionary
{
    NSMutableDictionary *_dict;
}

@end
