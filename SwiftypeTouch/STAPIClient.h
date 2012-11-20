//
//  STAPIClient.h
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Current version number of the SwiftypeTouch client
 */
extern NSString * const SWIFTYPE_API_VERSION;

/**
 Error domain string for `NSError` objects
 */
extern NSString * const STErrorDomain;

/**
 Key used in the NSError's userInfo object to point to the NSHTTPResponse
 */
extern NSString * const STHTTPResponseKey;

/**
 API received an HTTP code outside the 2xx range
 */
extern const NSInteger STHTTPErrorCode;

/**
 Query to the server has timed out
 */
extern const NSInteger STTimeoutErrorCode;

/** Type of search the API has performed.

 `STSearchTypeUndefined` - API hasn't performed any type of search.

 `STSearchTypeSuggest` - API has performed a suggestion search

 `STSearchTypeSearch` - API has performed a regular search
 */
typedef enum {
    STSearchTypeUndefined,
    STSearchTypeSuggest,
    STSearchTypeSearch
} STSearchType;

@class STAPIClient;

/**
 Used by STAPIClient to keep delegate informed of the status of the query.
 */
@protocol STAPIClientDelegate <NSObject>

/**
 Required delegate method that should return the search parameters that will be posted to the server. The possible
 search parameters can be found here `http://swiftype.com/documentation/searching`
 
 @param client Instance of `STAPIClient` making the request
 @param query The query string entered by the user
 @param type The type of search to be performed. Either a search or a suggest.
 
 @return dictionary of search parameters that will be JSON encoded and posted to the server
 */
- (NSDictionary *)clientRequestParameters:(STAPIClient *)client forQuery:(NSString *)query withType:(STSearchType)type;

@optional

/**
 The client started a query with the server. The result of the query will be indicated with
 a call to one of the following methods on the delegate: finish, cancel or failure.
 
 @param client Instance of `STAPIClient` making the request
 @param query The query string entered by the user
 @param type The type of search to be performed. Either a search or a suggest.
 */
- (void)client:(STAPIClient *)client didStartQuery:(NSString *)query withType:(STSearchType)type;

/**
 The client succesfully received the results of query from the server
 
 @param client Instance of `STAPIClient` making the request
 @param query The query string entered by the user
 @param result The `NSDictionary` representation of the search results
 @param type The type of search to be performed. Either a search or a suggest
 */
- (void)client:(STAPIClient *)client didFinishQuery:(NSString *)query withResult:(NSDictionary *)result withType:(STSearchType)type;

/**
 The query was canceled with an explicit call to the `STAPIClient` method `cancelQuery` or
 as a result of the client starting a new query.

 @param client Instance of `STAPIClient` making the request
 @param query The query string entered by the user
 @param type The type of search to be performed. Either a search or a suggest
 */
- (void)client:(STAPIClient *)client didCancelQuery:(NSString *)query withType:(STSearchType)type;

/**
 The client failed to retrieve a result from the server. This can happen as a result of a timeout, server error,
 lack of internet or many other reasons. The exact cause of the failure will be in the `error` parameter.
 
 @param client Instance of `STAPIClient` making the request
 @param query The query string entered by the user
 @param type The type of search to be performed. Either a search or a suggest
 @param error Stores more detailed information about the cause of the failure.
 */
- (void)client:(STAPIClient *)client didFailQuery:(NSString *)query withType:(STSearchType)type error:(NSError *)error;

@end

/**
 The `STAPIClient` is used to communicate with the Swiftype search servers. In order to work correctly
 it must have a delegate that defines the search parameters as well as an engine key. Details on the search
 parameters can be found here: `http://swiftype.com/documentation/searching`. An search engine's key can be
 found within the account's dashboard: `http://swiftype.com/home`.
 
 The `STAPIClient` client is meant to run exactly 1 query at a time. If a query is pending (waiting for
 the server to respond) when another query is issued then that first query is canceled. A query will start
 and then finish or be canceled or fail. A query cannot for example fail and be canceled for the same request.
 
 The client offers two types of queries: search and suggest. More detailed information on suggest queries
 can be found here `http://swiftype.com/documentation/autocomplete`.
 
 It is not common to use `STAPIClient` directly. Instead it is recommended to use `STSearchResultsObject` or
 one of its subclasses.
 */
@interface STAPIClient : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/**
 Key to the engine that queries will run against
 */
@property (nonatomic, copy) NSString *engineKey;

/**
 The delegate which will provide parameter data and receive messages related to the query
 */
@property (nonatomic, weak) id <STAPIClientDelegate> delegate;

/**
 Clear the cache that is used by all instance of STAPIClient
 */
+ (void)clearAPICache;

/**
 Initializes a new `STAPIClient`
 
 @param engineKey The key of the engine that queries will be run against
 */
- (id)initWithApiKey:(NSString *)engineKey;

/**
 Starts a new search query with the server. By default the query will request only the first 20 results
 for each document type.
 
 @param query The query to be used in the search
 
 If an existing suggest or search query is already waiting for a server response then it will
 be canceled in order for the new query to begin. The delegates query cancel method will be called
 for the canceled query.
 */
- (void)searchQuery:(NSString *)query;

/**
 Starts a new search query with the server for a specific page and certain number of results.
 
 @param query The query to be used in the search
 
 @param page The page to request
 
 @param perPage Maximum number of items per page
 
 If an existing suggest or search query is already waiting for a server response then it will
 be canceled in order for the new query to begin. The delegates query cancel method will be called
 for the canceled query.
 */
- (void)searchQuery:(NSString *)query page:(NSUInteger)page perPage:(NSUInteger)perPage;

/**
 Starts a new suggest query with the server. By default the query will request only the first 20 results
 for each document type.
 
 @param query The query to send to the server
 
 If an existing suggest or search query is already waiting for a server response then it will
 be canceled in order for the new query to begin. The delegates query cancel method will be called
 for the canceled query.
 */
- (void)suggestQuery:(NSString *)query;

/**
 Cancel any pending requests with the search server
 */
- (void)cancelQuery;

/**
 Used to log user interaction with the search results. This is typically called by the `STSearchResultObjects`
 postClickAnalyticsWithDocumentId method. 
 
 It is the responsibility of custom UI to call this once a user has selected a search result.
 
 @param query The query the that was run against the server that found a particular result
 
 @param type The search type. Whether it was a suggest or a search query.
 
 @param documentId The id of the document that was selected.
 */
- (void)postClickAnalyticsForQuery:(NSString*)query withType:(STSearchType)type documentId:(NSString *)documentId;

@end
