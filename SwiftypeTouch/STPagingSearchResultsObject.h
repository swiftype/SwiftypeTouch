//
//  STPagingSearchResultsObject.h
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STSearchResultsObject.h"

/**
 The purpose of `STPagingSearchResultsObject` is to extend the functionality `STSearchResultsObject`
 to include the paging of results. Currently, "Load More" cells are only displayed on search queries
 and not suggest queries when more pages are available. If multiple sections (displaying multiple 
 document types) are on the screen and the scope filtering is enabled then the "Load More" switches
 from the "All" scope to that sections specific scope. See `hasMorePagesInSection:` for more infomation
 when a section is determined to have another page.
 
 Keep in mind `STPagingSearchResultsObject` is a subclass of `STSearchResultsObject`. When
 overriding methods or pointing `delegate` or `dataSource` at new objects there maybe helpful 
 functionality that is disabled as a result. It might be necessary to call `super` or call
 the `delegate` or `dataSource` callbacks implemented by `STPagingSearchResultsObject` to
 preserver some of this functionality.
 
 Here is a list of the delegate methods that `STPagingSearchResultObject` implements in addition to
 those implemented by `STSearchResultsObject`:
 
  * `searchResultsDataSource` for `UISearchDisplayController`
    * `tableView:numberOfRowsInSection:` - Adds space for an extra cell if that section passes the 
      `hasMorePagesInSection:` test.
    * `tableView:cellForRowAtIndexPath:` - If the index path is that of a "Load More" cell then it returns
      a generic "Load More" cell. Otherwise it will return nil.
    * `tableView:didSelectRowAtIndexPath:` - If the selection was a "Load More" cell then it either switches
      to that section's scope. If it is already in a specific document scope then it requests more results
      from the server and reloads the table view when the new results are available.
  * `delegate` for `STAPIClient`
    * `client:didFinishQuery:withResult:withType:` - merges the new record data in with the current record
      data. Then makes a call to `super` `client:didFinishQuery:withResult:withType:` with the merged records
      as the result.

 */
@interface STPagingSearchResultsObject : STSearchResultsObject

/**
 Determines if the index path could be a load more cell. Which means the section has more pages and the 
 row is the last index.
 
 @param indexPath Index path of the cell
 
 @return `BOOL` indicating if the index path is a "Load More" cell
 */
- (BOOL)isIndexPathMoreCell:(NSIndexPath *)indexPath;

/**
 Requests that the server load the next page of search result data. If the previous `searchType` was a 
 `STSearchTypeSuggest` then this method is a no-op.
 */
- (void)loadNextSearchResultPage;

/**
 Determines if a specific section has more pages to load.
 
 @param section The section index to test
 
 @return `BOOL` indicating if a section has more pages
 
 The result will be true of the following condition are met:
 
   * `searchType` is `STSearchTypeSearch`
   * `recordSectionOrder` length is greater than 0
   * The number of rows in the section is greater than 0
   * Current page is not the last pages
   * The number of sections is greater than 0
   * The number of sections is equal to 1 or if it is greater than 1 the scope bar allows 
     filtering based on the document type.
 
 */
- (BOOL)hasMorePagesInSection:(NSInteger)section;

@end
