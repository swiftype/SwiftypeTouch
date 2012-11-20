//
//  NSString+STUtils.h
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Set of NSString helpers used within SwiftypeTouch
 */
@interface NSString (STUtils)

/**
 @return url encoded representation of `NSString` instance
 */
- (NSString *)STURLEncodedString;

@end
