//
//  STPageDocumentTypeResultsObject.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STPageDocumentTypeResultsObject.h"
#import "UI/STWebViewController.h"

@interface STPageDocumentTypeResultsObject ()

@property (nonatomic, copy) NSString *privateEngineKey;

- (void)_webControllerCancel;

@end

@implementation STPageDocumentTypeResultsObject

#pragma mark - STPageDocumentTypeResultsObject

- (id)initWithViewController:(UIViewController *)controller clientEngineKey:(NSString *)engineKey {
    self.privateEngineKey = engineKey;
    self = [super initWithViewController:controller];
    if (self) {
    }
    return self;
}

#pragma mark - STSearchResultsObject

- (NSArray *)recordSectionOrder {
    return @[ @"page" ];
}

- (NSString *)clientEngineKey {
    if (self.privateEngineKey) {
        return self.privateEngineKey;
    }

    return [super clientEngineKey];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        return cell;
    }
    
    static NSString *CellIdentifier = @"Cell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *data = [self recordForType:@"page" atIndex:indexPath.row];
    
    if (self.searchType == STSearchTypeSearch) {
        cell.textLabel.text = [data objectForKey:@"title"];
        cell.detailTextLabel.text = [data objectForKey:@"url"];
    }
    else {
        cell.textLabel.text = [data objectForKey:@"title"];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isIndexPathMoreCell:indexPath]) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    else {
        NSDictionary *data = [self recordForType:@"page" atIndex:indexPath.row];
        
        NSURL *url = [NSURL URLWithString:[data objectForKey:@"url"]];

        STWebViewController *webController = [[STWebViewController alloc] initWithURL:url];
        webController.title = [data objectForKey:@"title"];
        UINavigationController *navCon = self.searchDisplayController.searchContentsController.navigationController;
        if (navCon) {
            [navCon pushViewController:webController animated:YES];
        }
        else {
            UINavigationController *webNavCon = [[UINavigationController alloc] initWithRootViewController:webController];
            webController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                           target:self
                                                                                                           action:@selector(_webControllerCancel)];
            [self.searchDisplayController.searchContentsController presentModalViewController:webNavCon animated:YES];
        }
        
        [self postClickAnalyticsWithDocumentId:[data objectForKey:@"id"]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (void)_webControllerCancel {
    [self.searchDisplayController.searchContentsController dismissModalViewControllerAnimated:YES];
}

@end
