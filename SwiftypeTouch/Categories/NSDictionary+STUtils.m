//
//  NSDictionary+STUtils.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "NSDictionary+STUtils.h"
#import "NSString+STUtils.h"

@implementation NSDictionary (STUtils)

- (NSString *)STqueryString {
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in self) {
        if ([key isKindOfClass:[NSString class]]) {
            NSString *value = [self objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                NSString *encodedKey = [key STURLEncodedString];
                NSString *encodedValue = [value STURLEncodedString];
                [result addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
            }
        }
    }
    return [result componentsJoinedByString:@"&"];
}

@end
