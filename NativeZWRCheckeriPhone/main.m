//
//  main.m
//  NativeZWRCheckeriPhone
//
//  Created by Michael Ash on 10/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>


int main(int argc, char *argv[])
{
    char *badClassNames[] = {
        "NSProxy"
    };
    
    int count = objc_getClassList(NULL, 0);
    Class *classes = malloc(count * sizeof(*classes));
    objc_getClassList(classes, count);
    
    fprintf(stderr, "starting...\n");
    for(int i = 0; i < count; i++)
    {
        @autoreleasepool
        {
            Class c = classes[i];
            
            BOOL isBad = NO;
            for(Class toCheck = c; toCheck; toCheck = class_getSuperclass(toCheck))
            {
                for(unsigned i = 0; i < sizeof(badClassNames) / sizeof(*badClassNames); i++)
                {
                    if(strcmp(class_getName(toCheck), badClassNames[i]) == 0)
                        isBad = YES;
                }
            }
            if(isBad)
                continue;
            
            id instance = (id){ c };
            
            BOOL (*allowsWeakReference)(id, SEL);
            SEL allowsWeakReferenceSEL = @selector(allowsWeakReference);
            allowsWeakReference = (BOOL (*)(id, SEL))class_getMethodImplementation(c, allowsWeakReferenceSEL);
            if((IMP)allowsWeakReference != class_getMethodImplementation(c, @selector(thisHadBetterBeUndefinedIReallyHopeSo)))
            {
                BOOL allows = allowsWeakReference(instance, allowsWeakReferenceSEL);
                if(!allows)
                    fprintf(stderr, "%s does not allow weak references\n", class_getName(c));
            }
        }
    }
    fprintf(stderr, "done!\n");
}
