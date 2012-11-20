//
//  STSearchBar.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STSearchBar.h"

@interface STSearchBar ()

- (void)_privateSetup;

@end

@implementation STSearchBar

- (void)_privateSetup {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _privateSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _privateSetup];
    }
    return self;
}

- (void)didMoveToSuperview {
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.superview.bounds.size.width,
                            self.frame.size.height);
}

@end
