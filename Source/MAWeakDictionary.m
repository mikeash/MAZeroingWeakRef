//
//  MAWeakDictionary.m
//  ZeroingWeakRef
//
//  Created by Mike Ash on 7/13/10.
//  Copyright 2010 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "MAWeakDictionary.h"

#import "MAZeroingWeakRef.h"


@implementation MAWeakDictionary

- (id)init
{
    if((self = [super init]))
    {
        _dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_dict release];
    [super dealloc];
}

- (NSUInteger)count
{
    return [_dict count];
}

- (id)objectForKey: (id)aKey
{
    MAZeroingWeakRef *ref = [_dict objectForKey: aKey];
    id obj = [ref target];
    
    // clean out keys whose objects have gone away
    if(ref && !obj)
        [_dict removeObjectForKey: aKey];
    
    return obj;
}

- (NSEnumerator *)keyEnumerator
{
    return [_dict keyEnumerator];
}

- (void)removeObjectForKey: (id)aKey
{
    [_dict removeObjectForKey: aKey];
}

- (void)setObject: (id)anObject forKey: (id)aKey
{
    [_dict setObject: [MAZeroingWeakRef refWithTarget: anObject]
                                               forKey: aKey];
}

@end
