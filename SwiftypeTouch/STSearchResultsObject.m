//
//  STSearchResultsObject.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STSearchResultsObject.h"
#import "UI/STSearchBar.h"

@interface STSearchResultsObject ()

@property (nonatomic, strong) STAPIClient *client;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, assign) STSearchType searchType;
@property (nonatomic, strong) NSDictionary *searchResultData;
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSTimer *suggestTimer;

- (void)_fireSuggestQuery:(NSTimer *)timer;
- (BOOL)_shouldShowSpecificScope;
- (BOOL)_scopingHelperEnabled;

@end

@implementation STSearchResultsObject

- (void)setSearchResultData:(NSDictionary *)searchResultData {
    _searchResultData = searchResultData;
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (UIViewController *)controller {
    return self.searchDisplayController.searchContentsController;
}

/**
 This initializer will call `initWithViewController:` with nil.
 */
- (id)init {
    return [self initWithViewController:nil];
}

- (id)initWithViewController:(UIViewController *)controller {
    self = [super init];
    if (self) {
        self.client = [[STAPIClient alloc] initWithApiKey:[self clientEngineKey]];
        
        self.searchBar = [self searchBarForResultObject];

        if ([self _scopingHelperEnabled]) {
            NSMutableArray *buttonTitles = [NSMutableArray arrayWithObject:@"All"];
            for (NSString *s in [self recordSectionOrder]) {
                [buttonTitles addObject:[s capitalizedString]];
            }
            self.searchBar.scopeButtonTitles = buttonTitles;
        }
        
        if (controller) {
            self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar
                                                                             contentsController:controller];
            self.searchDisplayController.delegate = self;
            self.searchDisplayController.searchResultsDelegate = self;
            self.searchDisplayController.searchResultsDataSource = self;
        }
        self.searchBar.delegate = self;
        self.client.delegate = self;
        
        self.searchResultData = @{};
    }
    return self;
}

- (NSString *)clientEngineKey {
    return @"";
}

- (NSArray *)recordSectionOrder {
    return @[];
}

- (BOOL)shouldDisplaySearchScopeButtons {
    return NO;
}

- (UISearchBar *)searchBarForResultObject {
    return [[STSearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
}

- (NSArray *)recordsForType:(NSString *)type {
    NSDictionary *records = [self.searchResultData objectForKey:@"records"];
    if ([records isKindOfClass:[NSDictionary class]]) {
        NSArray *result = [records objectForKey:type];
        if ([result isKindOfClass:[NSArray class]]) {
            return result;
        }
    }
    return @[];
}

- (NSDictionary *)recordForType:(NSString *)type atIndex:(NSUInteger)index {    
    NSArray *recordsForType = [self recordsForType:type];
    if (index < recordsForType.count) {
        NSDictionary *result = [recordsForType objectAtIndex:index];
        if ([result isKindOfClass:[NSDictionary class]]) {
            return result;
        }
    }
    
    return @{};
}

- (NSString *)recordTypeForSection:(NSUInteger)index {
    // If the section order wasn't specified then we have nothing to return
    if ([self recordSectionOrder].count == 0) {
        return nil;
    }
    
    if ([self _shouldShowSpecificScope]) {
        index = self.searchBar.selectedScopeButtonIndex - 1;
    }
    
    if (index < [self recordSectionOrder].count) {
        return [[self recordSectionOrder] objectAtIndex:index];
    }
    
    return nil;
}

- (void)postClickAnalyticsWithDocumentId:(NSString *)documentId {
    [self.client postClickAnalyticsForQuery:self.query withType:self.searchType documentId:documentId];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self _shouldShowSpecificScope]) {
        return nil;
    }
    
    NSString *s = [self recordTypeForSection:section];
    if ([self recordsForType:s].count > 0) {
        return [s capitalizedString];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self _shouldShowSpecificScope]) {
        return 1;
    }

    return [self recordSectionOrder].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *recordType = [self recordTypeForSection:section];
    if (recordType) {
        NSArray *records = [self recordsForType:recordType];
        return records.count;
    }
    return 0;
}

#pragma mark - Private

- (void)_fireSuggestQuery:(NSTimer *)timer {
    [self.client suggestQuery:timer.userInfo];
    self.suggestTimer = nil;
}

- (BOOL)_shouldShowSpecificScope {
    return self.searchBar.showsScopeBar && self.searchBar.selectedScopeButtonIndex > 0;
}

- (BOOL)_scopingHelperEnabled {
    return [self shouldDisplaySearchScopeButtons] && [self recordSectionOrder].count > 1;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchString {
    if (!searchString.length) {
        self.searchResultData = @{};
    }

    [self.suggestTimer invalidate];
    self.suggestTimer = [NSTimer scheduledTimerWithTimeInterval:.25
                                                         target:self
                                                       selector:@selector(_fireSuggestQuery:)
                                                       userInfo:searchString
                                                        repeats:NO];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [STAPIClient clearAPICache];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchResultData = @{};
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.client searchQuery:searchBar.text];
    [self.suggestTimer invalidate];
    self.suggestTimer = nil;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self.searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark - STAPIDelegate

- (NSDictionary *)clientRequestParameters:(STAPIClient *)client forQuery:(NSString *)query withType:(STSearchType)type {
    return @{};
}

- (void)client:(STAPIClient *)client didFinishQuery:(NSString *)query withResult:(NSDictionary *)result withType:(STSearchType)type {
    self.query = query;
    self.searchType = type;
    self.searchResultData = result;
}

@end
