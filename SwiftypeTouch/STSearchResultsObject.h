//
//  STSearchResultsObject.h
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STAPIClient.h"

/**
 `STSearchResultsObject` is an abstract class the provides a generic way to integrate
 `STAPIClient` into an iOS application. It provides basic functionality for STAPIClient
 or at least an example of how one might integrate STAPIClient into an application.
 
 The `STSearchResultsObject` itself is the delegate or dataSource for the following objects it manages:

   * `delegate` for the `UISearchDisplayController`
   * `searchResultsDelegate` for the `UISearchDisplayController`
   * `searchResultsDataSource` for the `UISearchDisplayController`
   * `delegate` for the `UISearchBar`
   * `delegate` for the `STAPIClient`
 
 The standard workflow is to create a subclass of `STSearchResultsObject` and override the
 following methods:
 
   * `recordSectionOrder` - provide the list of document type keys and order they should be displayed
   * `clientEngineKey` - provide key of the search engine that queries will be run against
   * `clientRequestParameters:forQuery:withType:` (delegate method from `STAPIClientDelegate`) - provide
     search parameters for a query.
 
 The `STSearchResultsObject` provides some basic functionality out of the box. For example, handling the
 keyboard events for starting a suggest or search query. To support additional functionality the subclass
 will need to implement or override additional `delegate` and/or `dataSource` callbacks.
 
 Another option is to change the `delegate` or `dataSource` on the objects managed by `STSearchResultsObject`
 to something else. When this approach is taken it is important to keep in mind that the helpful
 functionality automatically provided will either need to be reimplemented or the new `delegate` or
 `dataSource` will need to callback to `STSearchResultsObject` methods that already provide the functionality.
 
 In order to provide rendering and click functionality for search result cells the various tableView
 `delegate` and `dataSource` methods will need to be overridden. Since it is likely existing projects already
 implement these methods in some other view controller the `STSearchResultsObject` could have
 its `searchDisplayController.searchResultsDelegate` and `searchDisplayController.searchResultsDataSource`
 pointed at that view controller. And it is always possible to callback to the `STSearchResultsObject`
 that are already
 
 Here is a list of the delegate methods that `STSearchResultsObject` already impements with a short 
 description of what it does and the helpful functionality it provides:
 
 * `searchResultsDataSource` for `UISearchDisplayController`
   * `tableView:titleForHeaderInSection:` - returns a section title based on the data returned by `recordSectionOrder`
   * `numberOfSectionsInTableView:` - returns the number of sections in the table view taking into account the current search scope
   * `tableView:numberOfRowsInSection:` - returns the number of rows in a given section taking into account the current search scope
   * `searchBar:selectedScopeButtonIndexDidChange:` -
 * `delegate` for `UISearchDisplayController`
   * `searchDisplayController:shouldReloadTableForSearchString:` - starts a timer that fires after 250ms at which point a suggest
     query will actually be sent to the server. This helps prevent a request being generated for each keystroke
   * `searchDisplayController:didHideSearchResultsTableView:` - the table view is dismissed so clear out the `searchResultData`
 * `delegate` for `UISearchBar`
   * `searchBarTextDidEndEditing:` - clears out the web request cache used to cache API requests
   * `searchBarSearchButtonClicked:` - sends a search query to the server and cancels any pending suggest timer
   * `searchBar:selectedScopeButtonIndexDidChange:` - reloads table view since the search scope has changed
 * `delegate` for `STAPIClient`
   * `clientRequestParameters:forQuery:withType:` - required delegate method so just returns an empty dictionary
   * `client:didFinishQuery:withResult:withType:` - saves the response information to the properties on 
     `query`, `searchType`, and `searchResultData`.

 */
@interface STSearchResultsObject : NSObject
<UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate,
UISearchBarDelegate,
STAPIClientDelegate>

/**
 The `STAPIClient` instance created and managed by the `STSearchResultsObject`.
 
 @note By default the client's delegate is set to the `STSearchResultsObject`.
 */
@property (nonatomic, readonly, strong) STAPIClient *client;

/**
 The query that most recently finished successfully.
 */
@property (nonatomic, readonly, copy) NSString *query;

/**
 The type of query that recently finished successfully.
 */
@property (nonatomic, readonly, assign) STSearchType searchType;

/**
 The searched results from the last query that finished successfully.
 */
@property (nonatomic, readonly, strong) NSDictionary *searchResultData;

/**
 The controller passed to the designated initializer. This is the
 same as the `UISearchDisplayControllers` `searchContentsController`.
 */
@property (nonatomic, readonly) UIViewController *controller;

/**
 The search bar that is managed by `STSearchResultsObject`. 
 
 By default the search bar's delegate is set to the `STSearchResultsObject`.
 */
@property (nonatomic, readonly, strong) UISearchBar *searchBar;

/**
 The search display controller that will be managed by the `STSearchResultsObject`.
 
 By default the search display controller's `delegate`, `searchResultsDelegate` and
 `searchResultsDataSource` will be set to the `STSearchResultsObject`. 
 */
@property (nonatomic, readonly, strong) UISearchDisplayController *searchDisplayController;

/**
 This is the designated initilizer for `STSearchResultsObject`.
 
 @param controller The controller that the search results will be presented over. This is the
 same as the `UISearchDisplayControllers` `searchContentsController`.
 
 If nil is passed to `controller` then `STSearchResultsObject` will not create a `UISearchDisplayController`.
 It is then the responsibility of the subclass to provide UI that renders the search results.
 */
- (id)initWithViewController:(UIViewController *)controller;

/**
 This method should be overriden by subclasses to return
 
 @return A `NSString` of the search engine that will be queried against
 */
- (NSString *)clientEngineKey;

/**
 Subclasses override this method to provide an array of document type names and the order 
 the document types should be rendered in the search results table view.
 
 @return An array of `NSString` objects that represent the document type keys.
 
 By default this method will return an empty array. This method is required to
 return the keys of the document types for various helper aspects of the `STSearchResultsObject`
 to work properly. It is required for `recordTypeForSection:` to return the document type for a 
 particular section index. It is also required for the `UITableViewDataSource` methods
 `numberOfSectionsInTableView:` and `tableView:numberOfRowsInSection:` which are overridden by
 `STSearchResultsObject` to provide the section and row counts based on the search result data.
 The result of this method is also used when automatically setting up the search scope bar.
 
 Every suggest or search query will contain a dictionary called `record`. Within `record`
 each key will be the name of the document type.
 */
- (NSArray *)recordSectionOrder;

/**
 Indicates that the search bar should have the scope indicators set. `STSearchResultsObject` will
 automatically creating an "All" section and handling refreshing the table view when switching between
 sections.
 
 @return Boolean indicating whether or not the search bar's scope indicators should be enabled.
 
 The default value return is `NO`
 
 Even if this method returns `YES` if the result of `recordSectionOrder` is an empty
 array or an array containing exactly one document type then the search bar's scope bar
 will not be displayed.
 */
- (BOOL)shouldDisplaySearchScopeButtons;

/**
 Provides subclasses with the ability to provide their own custom subclass of UISearchBar.
 
 @return Instance of `UISearchBar` used by the `STSearchResultsObject` and exposed with 
 the `searchBar` property.
 
 By default the `STSearchResultsObject` will provide an instance of `STSearchBar`.
 */
- (UISearchBar *)searchBarForResultObject;

/**
 Helper for retrieving an array of records from `searchResultData` based on document type.
 
 @param type Document type which will be a key in the `record` section of the search results
 
 @return Array of records for a specific document type
 
 By default this will return an array of `NSDictionary` representation of the parsed response
 data for the record. Subclasses may want to override this method to parse the `NSDictionary` objects
 into custom Objective-C objects.
 
 This method does not require data provided by the method `recordSectionOrder`. This method
 will return an empty array if the `type` couldn't be found in the search result data.
 */
- (NSArray *)recordsForType:(NSString *)type;

/**
 Helper for retrieving a record from `searchResultData` based on document type.
 
 @param type Document type which will be a key in the `record` section of the search results
 
 @param index Offset into the array
 
 @return Object of record for a specific document type. The default implementation will be a
 `NSDictionary` representation of the parsed response data for the record.
 
 By default this will return a `NSDictionary` for the record. Subclasses may want
 to override this method to parse the `NSDictionary` into a custom Objective-C object.
 
 This method does not require data provided by the method `recordSectionOrder`. This method
 will return an empty dictionary if the `type` couldn't be found or if the index was
 out-of-bounds in the search result data.
 */
- (id)recordForType:(NSString *)type atIndex:(NSUInteger)index;

/**
 Determines the document types being presented in a specfic section of the table view.
 
 @param index The section index being access
 
 @return The string at `index`
 
 Depends on `recordSectionOrder` being specified.
 
 This method will also correctly handle the case where the scope bar has been limited
 to a specfic document type and the table views only have a single section. In that case
 this method will look at which scope has been selected and look up the document type 
 based on the scope filter.
 */
- (NSString *)recordTypeForSection:(NSUInteger)index;

/**
 Posts analytics to the server for a click on a specific document.
 
 @param documentId This will be the property `id` from a search result record.
 */
- (void)postClickAnalyticsWithDocumentId:(NSString *)documentId;

@end
