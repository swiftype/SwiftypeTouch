//
//  STWevViewController.h
//  APITester
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Provides a basic view controller wrapper around a `UIWebView`
 */
@interface STWebViewController : UIViewController

/**
 Designated initializer for `STWebViewController`.
 
 @param url URL of the webpage for the web view to load
 */
- (id)initWithURL:(NSURL *)url;

@end
