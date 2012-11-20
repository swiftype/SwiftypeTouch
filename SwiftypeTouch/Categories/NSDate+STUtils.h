//
//  NSDate+STUtils.h
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Set of NSDate helpers used within SwiftypeTouch
 */
@interface NSDate (STUtils)

/**
 Returns a NSString in the ISO 8601 format for UTC timezone
 
 @return ISO 8601 representation of `NSDate` instance
 */
- (NSString *)STISO8601String;

@end
