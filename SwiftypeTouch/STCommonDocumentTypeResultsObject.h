//
//  STCommonDocumentTypeResultsObject.h
//  SwiftypeTouch
//
//  Created by Luke Francl on 5/24/13.
//  Copyright (c) 2013 Swiftype. All rights reserved.
//

#import "STPagingSearchResultsObject.h"

/**
 The `STCommonDocumentTypeResultsObject` is a helper used to render results from a DocumentType
 with common fields that must include "title" and "url".
 
 Since the engine key and DocumentType slug are passed as parameters there shouldn't be a
 need to subclass for most cases. It is still required to subclass if it is required to
 render custom cells or handle clicks in a specific way.
 
 Out of the box STCommonDocumentTypeResultsObject will handle paging, render the results of suggest and
 search queries, display a web view controller when one of the results is clicked and post back analytics
 about which items were selected.
 
 Keep in mind `STCommonDocumentTypeResultsObject` is a subclass of `STPagingSearchResultsObject`. When
 overriding methods or pointing `delegate` or `dataSource` at new objects there maybe helpful
 functionality that is disabled as a result. It might be necessary to call `super` or call the
 `delegate` or `dataSource` callbacks implemented by `STPagingSearchResultsObject` to preserver
 some of this functionality.
 
 Here is a list of the delegate methods that `STCommonDocumentTypeResultsObject` implements in addition to
 those implemented by `STSearchResultsObject` and `STPagingSearchResultsObject`:
 
 * `STSearchResultsObject`
    * `recordSectionOrder` - returns `@[ self.documentTypeSlug ]` instead of the empty array
 * `searchResultsDataSource` for `UISearchDisplayController`
    * `tableView:titleForHeaderInSection:` - returns nil
    * `tableView:cellForRowAtIndexPath:` - For suggest queries renders the title of the cell. For
       search queries renders the title and url as the subtitle.
 * `searchResultsDelegate` for `UISearchDisplayController`
    * `tableView:didSelectRowAtIndexPath:` - Opens up a web page of the result
 */
@interface STCommonDocumentTypeResultsObject : STPagingSearchResultsObject

/**
 This is the designated initilizer for `STCommonDocumentTypeResultsObject`.
 
 @param controller The controller that the search results will be presented over. This is the
 same as the UISearchDisplayControllers searchContentsController.
 
 @param engineKey The key of the engine that will be queried
 
 @param documentTypeSlug The slug of the the DocumentType that will be queried
 */
- (id)initWithViewController:(UIViewController *)controller clientEngineKey:(NSString *)engineKey documentTypeSlug:(NSString *)documentTypeSlug;

@end