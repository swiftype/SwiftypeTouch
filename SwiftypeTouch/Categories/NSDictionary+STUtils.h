//
//  NSDictionary+STUtils.h
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Set of NSDictionary helpers used within SwiftypeTouch
 */
@interface NSDictionary (STUtils)

/** 
 @return query string representation of `NSDictionary` instance
 */
- (NSString *)STqueryString;

@end
