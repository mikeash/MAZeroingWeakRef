//
//  main.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "MANotificationCenterAdditions.h"
#import "MAZeroingWeakProxy.h"
#import "MAZeroingWeakRef.h"
#import "MAWeakArray.h"
#import "MAWeakDictionary.h"


@interface NotificationReceiver : NSObject
{
    int *_noteCounter;
}

- (id)initWithCounter: (int *)counter;

@end

@implementation NotificationReceiver

- (id)initWithCounter: (int *)counter
{
    _noteCounter = counter;
    return self;
}

- (void)gotNote: (NSNotification *)note
{
    (*_noteCounter)++;
}

@end

static void WithPool(void (^block)(void))
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    block();
    [pool release];
}

static int gFailureCount;

#define TEST(func) WithPool(^{ \
    int failureCount = gFailureCount; \
    NSLog(@"Testing %s", #func); \
    func(); \
    NSLog(@"%s: %s", #func, failureCount == gFailureCount ? "SUCCESS" : "FAILED"); \
})

#define TEST_ASSERT(cond, ...) do { \
    if(!(cond)) { \
        gFailureCount++; \
        NSString *message = [NSString stringWithFormat: @"" __VA_ARGS__]; \
        NSLog(@"%s:%d: assertion failed: %s %@", __func__, __LINE__, #cond, message); \
    } \
} while(0)

static void TestBasic(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [obj release];
    });
    TEST_ASSERT([ref target] == nil, @"ref target still live after object destroyed: %@", ref);
    [ref release];
}

static void TestRefDestroyedFirst(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [ref release];
    });
    [obj release];
}

static void TestDoubleRef(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref1 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    WithPool(^{
        TEST_ASSERT([ref1 target]);
        TEST_ASSERT([ref2 target]);
        [obj release];
    });
    TEST_ASSERT([ref1 target] == nil, @"ref target still live after object destroyed: %@", ref1);
    TEST_ASSERT([ref2 target] == nil, @"ref target still live after object destroyed: %@", ref2);
    [ref1 release];
    [ref2 release];
}

static void TestRefToRef(void)
{
    NSObject *obj = [[NSObject alloc] init];
    MAZeroingWeakRef *ref1 = [[MAZeroingWeakRef alloc] initWithTarget: obj];
    MAZeroingWeakRef *ref2 = [[MAZeroingWeakRef alloc] initWithTarget: ref1];
    WithPool(^{
        TEST_ASSERT([ref1 target]);
        TEST_ASSERT([ref2 target]);
        [obj release];
    });
    WithPool(^{
        TEST_ASSERT([ref1 target] == nil, @"ref target still live after object destroyed: %@", ref1);
        TEST_ASSERT([ref2 target], @"ref target dead even though target ref still alive: %@", ref2);
        [ref1 release];
    });
    TEST_ASSERT([ref2 target] == nil, @"ref target still live after object destroyed: %@", ref2);
    [ref2 release];
}

static void TestNSArrayTarget(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: array];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [array release];
    });
    TEST_ASSERT([ref target] == nil, @"ref target still live after object destroyed: %@", ref);
    [ref release];
}

static void TestNSStringTarget(void)
{
    if(![MAZeroingWeakRef canRefCoreFoundationObjects])
    {
        NSLog(@"MAZeroingWeakRef can't reference CF objects, not testing them");
        return;
    }
    
    NSString *str = [[NSMutableString alloc] initWithString: @"Test String"];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
    WithPool(^{
        TEST_ASSERT([ref target]);
        [str release];
    });
    [ref release];
}

static void TestCleanup(void)
{
    __block BOOL cleanedUp = NO;
    NSMutableString *str = [[NSMutableString alloc] initWithString: @"Test String"];
    MAZeroingWeakRef *ref = [[MAZeroingWeakRef alloc] initWithTarget: str];
    [ref setCleanupBlock: ^(id target) { cleanedUp = YES; }];
    [str release];
    TEST_ASSERT(cleanedUp);
    [ref release];
}

static void TestNotification(void)
{
    int notificationCounter = 0;
    NotificationReceiver *receiver = [[NotificationReceiver alloc] initWithCounter: &notificationCounter];
    [[NSNotificationCenter defaultCenter] addWeakObserver: receiver selector: @selector(gotNote:) name: @"name" object: @"object"];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    TEST_ASSERT(notificationCounter == 1);
    [receiver release];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"name" object: @"object"];
    TEST_ASSERT(notificationCounter == 1);
}

static void TestWeakArray(void)
{
    NSString *str1 = [[NSMutableString alloc] initWithString: @"Test String 1"];
    NSString *str2 = [[NSMutableString alloc] initWithString: @"Test String 2"];
    NSString *str3 = [[NSMutableString alloc] initWithString: @"Test String 3"];
    
    MAWeakArray *array = [[MAWeakArray alloc] init];
    [array addObject: str1];
    [array addObject: str2];
    [array addObject: str3];
    
    [str2 release];
    
    WithPool(^{
        TEST_ASSERT([array objectAtIndex: 0]);
        TEST_ASSERT([array objectAtIndex: 1] == nil);
        TEST_ASSERT([array objectAtIndex: 2]);
    });
    
    [str1 release];
    [str3 release];
    
    TEST_ASSERT([array objectAtIndex: 0] == nil);
    TEST_ASSERT([array objectAtIndex: 1] == nil);
    TEST_ASSERT([array objectAtIndex: 2] == nil);
    [array release];
}

static void TestWeakDictionary(void)
{
    NSString *str1 = [[NSMutableString alloc] initWithString: @"Test String 1"];
    NSString *str2 = [[NSMutableString alloc] initWithString: @"Test String 2"];
    NSString *str3 = [[NSMutableString alloc] initWithString: @"Test String 3"];
    
    MAWeakDictionary *dict = [[MAWeakDictionary alloc] init];
    [dict setObject: str1 forKey: @"str1"];
    [dict setObject: str2 forKey: @"str2"];
    [dict setObject: str3 forKey: @"str3"];
    
    [str2 release];
    
    WithPool(^{
        TEST_ASSERT([dict objectForKey: @"str1"]);
        TEST_ASSERT([dict objectForKey: @"str2"] == nil);
        TEST_ASSERT([dict objectForKey: @"str3"]);
    });
    
    [str1 release];
    [str3 release];
    
    TEST_ASSERT([dict objectForKey: @"str1"] == nil);
    TEST_ASSERT([dict objectForKey: @"str2"] == nil);
    TEST_ASSERT([dict objectForKey: @"str3"] == nil);
    [dict release];
}

static void TestWeakProxy(void)
{
    NSMutableString *str = [[NSMutableString alloc] init];
    NSMutableString *proxy = [[MAZeroingWeakProxy alloc] initWithTarget: str];
    
    WithPool(^{
        TEST_ASSERT([proxy isEqual: @""]);
        [proxy appendString: @"Hello, world!"];
        TEST_ASSERT([proxy isEqual: @"Hello, world!"]);
        TEST_ASSERT([proxy length] == [@"Hello, world!" length]);
        [proxy deleteCharactersInRange: NSMakeRange(0, 7)];
        TEST_ASSERT([proxy isEqual: @"world!"]);
    });
    
    [str release];
    
    TEST_ASSERT([proxy length] == 0);
    TEST_ASSERT([(id)proxy zeroingProxyTarget] == nil);
    [proxy release];
}
    
int main(int argc, const char * argv[])
{
    WithPool(^{
        TEST(TestBasic);
        TEST(TestRefDestroyedFirst);
        TEST(TestDoubleRef);
        TEST(TestRefToRef);
        TEST(TestNSArrayTarget);
        TEST(TestNSStringTarget);
        TEST(TestCleanup);
        TEST(TestNotification);
        TEST(TestWeakArray);
        TEST(TestWeakDictionary);
        TEST(TestWeakProxy);
        
        NSString *message;
        if(gFailureCount)
            message = [NSString stringWithFormat: @"FAILED: %d total assertion failure%s", gFailureCount, gFailureCount > 1 ? "s" : ""];
        else
            message = @"SUCCESS";
        NSLog(@"Tests complete: %@", message);
    });
    sleep(1000);
    return 0;
}

