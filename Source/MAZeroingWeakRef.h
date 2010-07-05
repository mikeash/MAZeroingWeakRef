//
//  MAZeroingWeakRef.h
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 Michael Ash. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MAZeroingWeakRef : NSObject
{
    id _target;
}

- (id)initWithTarget: (id)target;

- (id)target;

@end
