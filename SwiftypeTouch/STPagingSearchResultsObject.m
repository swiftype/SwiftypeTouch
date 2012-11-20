//
//  STPagingSearchResultsObject.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STPagingSearchResultsObject.h"

@interface STPagingSearchResultsObject ()

@property (nonatomic, assign) NSInteger currentPage;

- (NSInteger)_numberOfPagesInSection:(NSInteger)section;
- (NSInteger)_pageOfResult:(NSDictionary *)result;
- (BOOL)_resultTypes:(NSDictionary *)result matchCurrentTypes:(NSDictionary *)current;

@end

@implementation STPagingSearchResultsObject

- (id)initWithViewController:(UIViewController *)controller {
    self = [super initWithViewController:controller];
    if (self) {
        self.currentPage = 0;
    }
    return self;
}

#pragma mark - STPagingSearchResultsObject

- (BOOL)isIndexPathMoreCell:(NSIndexPath *)indexPath {
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    return [self tableView:tableView numberOfRowsInSection:indexPath.section]-1 == indexPath.row && [self hasMorePagesInSection:indexPath.section];
}

- (void)loadNextSearchResultPage {
    if (self.searchType == STSearchTypeSearch) {
        [self.client searchQuery:self.query page:self.currentPage + 1 perPage:20];
    }
}

- (BOOL)hasMorePagesInSection:(NSInteger)section {
    // Only do paging for "search" queries. Not enabled for other queries
    if (self.searchType != STSearchTypeSearch) {
        return NO;
    }
    
    // We need section names that can be paged on
    if ([self recordSectionOrder].count == 0) {
        return NO;
    }
    
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    NSInteger rowsInSection = [super tableView:tableView numberOfRowsInSection:section];
    // Don't need a "more" button if the section has no content
    if (rowsInSection == 0) {
        return NO;
    }
    
    // This section doesn't have any more pages current_page >= num_pages
    NSInteger currentPage = [self _pageOfResult:self.searchResultData];
    if (currentPage >= [self _numberOfPagesInSection:section]) {
        return NO;
    }
    
    NSInteger numberOfSections = [super numberOfSectionsInTableView:tableView];
    
    // No sections no more button
    if (numberOfSections == 0) {
        return NO;
    }
    // Only have one section so we should be able to page this
    else if (numberOfSections == 1) {
        return YES;
    }
    else { // numberOfSections > 1
        // More than one section visible. The more button in the "All" scope
        // will simply switch to the scope of that section
        if ([self shouldDisplaySearchScopeButtons]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Private

- (NSInteger)_numberOfPagesInSection:(NSInteger)section {
    NSDictionary *info = [self.searchResultData objectForKey:@"info"];
    if ([info isKindOfClass:[NSDictionary class]]) {
        NSString *type = [self recordTypeForSection:section];
        if (type) {
            NSDictionary *typeInfo = [info objectForKey:type];
            if ([typeInfo isKindOfClass:[NSDictionary class]]) {
                NSNumber *numPages = [typeInfo objectForKey:@"num_pages"];
                if ([numPages isKindOfClass:[NSNumber class]]) {
                    return [numPages integerValue];
                }
            }
        }
    }
    return 0;
}

- (NSInteger)_pageOfResult:(NSDictionary *)result {
    NSDictionary *info = [result objectForKey:@"info"];
    if ([info isKindOfClass:[NSDictionary class]]) {
        for (id key in info) {
            NSDictionary *typeInfo = [info objectForKey:key];
            if ([typeInfo isKindOfClass:[NSDictionary class]]) {
                NSNumber *n = [typeInfo objectForKey:@"current_page"];
                if ([n isKindOfClass:[NSNumber class]]) {
                    return [n integerValue];
                }
            }
        }
    }
    
    // couldn't figure things out so just say it was the first page
    return 1;
}

- (BOOL)_resultTypes:(NSDictionary *)result matchCurrentTypes:(NSDictionary *)current {
    NSDictionary *resultRecords = [result objectForKey:@"records"];
    NSDictionary *currentRecords = [current objectForKey:@"records"];
    if ([resultRecords isKindOfClass:[NSDictionary class]] && [currentRecords isKindOfClass:[NSDictionary class]]) {
        NSArray *resultSortedKeys = [[resultRecords allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSArray *currentSortedKeys = [[currentRecords allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        return [resultSortedKeys isEqualToArray:currentSortedKeys];
    }
    
    return NO;
}

- (NSDictionary *)_mergeResultRecords:(NSDictionary *)result withCurrentRecords:(NSDictionary *)current {
    if ([self _resultTypes:result matchCurrentTypes:current]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:current];
        
        NSDictionary *resultRecords = [result objectForKey:@"records"];
        NSDictionary *dRecords = [d objectForKey:@"records"];
        NSMutableDictionary *mergedRecords = [NSMutableDictionary dictionary];
        for (id key in resultRecords) {
            NSArray *resultData = [resultRecords objectForKey:key];
            NSArray *dData = [dRecords objectForKey:key];
            if ([resultData isKindOfClass:[NSArray class]] && [dData isKindOfClass:[NSArray class]]) {
                NSArray *mergedArray = [dData arrayByAddingObjectsFromArray:resultData];
                [mergedRecords setObject:mergedArray forKey:key];
            }
        }
        [d setObject:mergedRecords forKey:@"records"];
        [d setObject:[result objectForKey:@"info"] forKey:@"info"];
        
        return d;
    }
    else {
        return result;
    }
}

#pragma mark - STAPIDelegate

- (void)client:(STAPIClient *)client didFinishQuery:(NSString *)query withResult:(NSDictionary *)result withType:(STSearchType)type {
    NSInteger page = [self _pageOfResult:result];
    if (type == STSearchTypeSearch &&
        self.searchResultData &&
        [self.query isEqualToString:query] &&
        page > self.currentPage) {
        result = [self _mergeResultRecords:result withCurrentRecords:self.searchResultData];
    }
    self.currentPage = page;
    [super client:client didFinishQuery:query withResult:result withType:type];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowsInSection = [super tableView:tableView numberOfRowsInSection:section];
    if ([self hasMorePagesInSection:section]) {
        return rowsInSection + 1;
    }
    return rowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isIndexPathMoreCell:indexPath]) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwiftypeReuse"];
        cell.textLabel.text = @"Load More";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isIndexPathMoreCell:indexPath]) {
        NSInteger numberOfSections = [super numberOfSectionsInTableView:tableView];
        if (numberOfSections == 0) return;
        else if (numberOfSections == 1) {
            // load more from API
            [self loadNextSearchResultPage];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            activityView.center = CGPointMake(activityView.frame.size.width, cell.frame.size.height/2.0f);
            [cell.contentView addSubview:activityView];
            [activityView startAnimating];
        }
        else { // numberOfSections > 1
            if ([self shouldDisplaySearchScopeButtons]) {
                // switch to the scope
                self.searchBar.selectedScopeButtonIndex = indexPath.section + 1;
                [self.searchBar.delegate searchBar:self.searchBar selectedScopeButtonIndexDidChange:self.searchBar.selectedScopeButtonIndex];
            }
        }
    }
}

@end
