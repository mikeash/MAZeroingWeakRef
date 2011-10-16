//
//  main.m
//  NativeZWRCheckeriPhone
//
//  Created by Michael Ash on 10/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>


@implementation NSObject (HackHackHackYourBoat)

- (BOOL)_isDeallocating { return NO; }

@end

int main(int argc, char *argv[])
{
    [NSAutoreleasePool new];
    
    char *badClassNames[] = {
        "NSProxy",
        "__NSPlaceholderArray",
        "NSSubrangeData",
        "NSJSONSerialization",
        "NSCGImageSnapshotRep",
        "FEOpenCLContext",
        "_PFEncodedData",
        "NSPropertyListSerialization",
        "FEContext",
        "NSPersistentStore",
        "HICocoaWindowAdapter",
        "NSApplication",
        "NSCachedImageRep",
        "NSCIImageRep",
        "NSCGImageRep",
        "NSPasteboard",
        "NSFileVersion",
        "NSIconRefImageRep",
        "NSIconRefBitmapImageRep",
        "NSColorPanel",
        "NSFontDescriptor",
        "NSKnownKeysDictionary",
        "__NSPlaceholderSet",
        "NSCustomImageRep",
        "_NSTemporaryObjectID2",
        "NSTemporaryObjectID",
        "NSKeyedUnarchiver",
        "NSPICTImageRep",
        "_NSZombie_",
        "NSKnownKeysMappingStrategy2",
        "__NSGenericDeallocHandler",
        "NSPDFImageRep",
        "NSMessageBuilder",
        "NSDistributedLock",
        "NSKeyedArchiver",
        "__CFNotification",
        "NSNavFBETopLevelNode",
        "Protocol",
        "NSTreeNode",
        "NSBitmapImageRep",
        "NSNotification",
        "NSDocumentRevisionsPlaceholderView",
        "__NSPlaceholderDictionary",
        "DDNonTerminal",
        "NSAtomicStoreCacheNode",
        "NSViewTemplate",
        "__NSPlaceholderOrderedSet",
        "Object",
        "NSLeafProxy",
        "__IncompleteProtocol",
        "NSHTTPCookie",
        "_PFEncodedString",
        "NSEPSImageRep",
        "_PFEncodedArray"
    };
    
    NSApplicationLoad();
    
    int count = objc_getClassList(NULL, 0);
    Class *classes = malloc(count * sizeof(*classes));
    objc_getClassList(classes, count);
    
    NSMutableArray *results = [NSMutableArray array];
    
    fprintf(stderr, "starting...\n");
    for(int i = 0; i < count; i++)
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
        
        id instance = [[c alloc] init];
        
        BOOL (*allowsWeakReference)(id, SEL);
        SEL allowsWeakReferenceSEL = @selector(allowsWeakReference);
        allowsWeakReference = (BOOL (*)(id, SEL))class_getMethodImplementation(c, allowsWeakReferenceSEL);
        if((IMP)allowsWeakReference != class_getMethodImplementation(c, @selector(thisHadBetterBeUndefinedIReallyHopeSo)))
        {
            BOOL allows = allowsWeakReference(instance, allowsWeakReferenceSEL);
            if(!allows)
            {
                const char *name = class_getName(c);
                NSMutableData *sha = [NSMutableData dataWithLength: CC_SHA1_DIGEST_LENGTH];
                CC_SHA1(name, (int)strlen(name), [sha mutableBytes]);
                
                NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                                   sha, @"sha",
                                   [NSString stringWithUTF8String: name], @"name",
                                   nil];
                [results addObject: d];
            }
        }
    }
    fprintf(stderr, "done!\n");
    
    NSLog(@"%@", results);
}
