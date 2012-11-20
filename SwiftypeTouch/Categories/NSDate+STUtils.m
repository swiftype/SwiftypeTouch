//
//  NSDate+STUtils.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "NSDate+STUtils.h"

@implementation NSDate (STUtils)

- (NSString *)STISO8601String {
    // From NSDateFormatting guide: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [formatter stringFromDate:self];
}

@end
