//
//  STWevViewController.m
//  APITester
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STWebViewController.h"

@interface STWebViewController ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation STWebViewController

- (id)initWithURL:(NSURL *)url {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f,
                                                               0.0f,
                                                               self.view.bounds.size.width,
                                                               self.view.bounds.size.height)];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)viewDidUnload {
    self.webView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
