//
//  STAPIClient.m
//  SwiftypeTouch
//
//
//  Copyright (c) 2012 Swiftype, Inc. All rights reserved.
//

#import "STAPIClient.h"

#import "NSDictionary+STUtils.h"

NSString * const SWIFTYPE_API_VERSION = @"1.0";

NSString * const BASE_SUGGEST_URL = @"http://api.swiftype.com/api/v1/public/engines/suggest.json";
NSString * const BASE_SEARCH_URL = @"http://api.swiftype.com/api/v1/public/engines/search.json";
NSString * const BASE_SUGGEST_ANALYTICS_URL = @"http://api.swiftype.com/api/v1/public/analytics/pas";
NSString * const BASE_SEARCH_ANALYTICS_URL = @"http://api.swiftype.com/api/v1/public/analytics/pc";

NSString * const STErrorDomain = @"STErrorDomain";
NSString * const STHTTPResponseKey = @"STHTTPResponseKey";
const NSInteger STHTTPErrorCode = 1;
const NSInteger STTimeoutErrorCode = 2;

@interface STAPIClient ()

@property (nonatomic, copy) NSString *query;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, assign) STSearchType searchType;
@property (nonatomic, strong) NSTimer *timeoutTimer;

+ (NSURLCache *)_sharedAPICache;
+ (dispatch_queue_t)_jsonDecodeQueue;

- (NSDictionary *)_requestParamsForPage:(NSUInteger)page perPage:(NSUInteger)perPage;
- (void)_addTrackingHeaders:(NSMutableURLRequest *)request;
- (void)_doRequestForPage:(NSUInteger)page perPage:(NSUInteger)perPage;
- (void)_cancelPending;
- (void)_cleanUp;
- (void)_connectionTimeout;
- (void)_delegateDidStartQuery:(NSString *)query withType:(STSearchType)type;
- (void)_delegateDidFinishQuery:(NSString *)query withResult:(NSDictionary *)result withType:(STSearchType)type;
- (void)_delegateDidCancelQuery:(NSString *)query withType:(STSearchType)type;
- (void)_delegateDidFailQuery:(NSString *)query withType:(STSearchType)type error:(NSError *)error;

// Possible to page suggest requests but don't want to expose that. UI would be tricky
- (void)suggestQuery:(NSString *)query page:(NSUInteger)page perPage:(NSUInteger)perPage;

@end

@implementation STAPIClient

#pragma mark - NSObject

- (id)init {
    return [self initWithApiKey:@""];
}

#pragma mark - STAPIClient

+ (NSURLCache *)_sharedAPICache {
    static dispatch_once_t onceToken;
    static NSURLCache *apiCache = nil;
    dispatch_once(&onceToken, ^{
        apiCache = [[NSURLCache alloc] initWithMemoryCapacity:1024*1024*5 diskCapacity:1024*1024*20 diskPath:@"PrivateSwiftypeApiCache"];
    });
    return apiCache;
}

+ (dispatch_queue_t)_jsonDecodeQueue {
    static dispatch_queue_t jsonDecodeQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jsonDecodeQueue = dispatch_queue_create("com.swiftype.api.jsonDecode", NULL);
    });
    return jsonDecodeQueue;
}

+ (void)clearAPICache {
    [[self _sharedAPICache] removeAllCachedResponses];
}

- (id)initWithApiKey:(NSString *)engineKey {
    self = [super init];
    if (self) {
        self.engineKey = engineKey;
        self.query = @"";
        self.searchType = STSearchTypeUndefined;
    }
    return self;
}

- (void)searchQuery:(NSString *)query {
    [self searchQuery:query page:1 perPage:20];
}

- (void)searchQuery:(NSString *)query page:(NSUInteger)page perPage:(NSUInteger)perPage {
    [self _cancelPending];
    self.searchType = STSearchTypeSearch;
    self.query = query;
    [self _doRequestForPage:page perPage:perPage];
}

- (void)suggestQuery:(NSString *)query {
    [self suggestQuery:query page:1 perPage:20];
}

- (void)suggestQuery:(NSString *)query page:(NSUInteger)page perPage:(NSUInteger)perPage {
    [self _cancelPending];
    self.searchType = STSearchTypeSuggest;
    self.query = query;
    [self _doRequestForPage:page perPage:perPage];
}

- (void)cancelQuery {
    [self _cancelPending];
}

- (void)postClickAnalyticsForQuery:(NSString*)query withType:(STSearchType)type documentId:(NSString *)documentId {
    if (documentId == nil) return;

    if (type == STSearchTypeSearch || type == STSearchTypeSuggest) {
        NSString *analyticsURL = (type == STSearchTypeSearch) ? BASE_SEARCH_ANALYTICS_URL : BASE_SUGGEST_ANALYTICS_URL;
        NSString *docIdKey = (type == STSearchTypeSearch) ? @"doc_id" : @"entry_id";
        NSString *queryKey = (type == STSearchTypeSearch) ? @"q" : @"prefix";
        
        NSDictionary *analyticsParams = @ {
            @"engine_key" : self.engineKey,
            docIdKey : documentId,
            queryKey : query
        };
        NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", analyticsURL, [analyticsParams STqueryString]]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
        [self _addTrackingHeaders:request];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *r, NSData *d, NSError *e){}];
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self _delegateDidFailQuery:self.query withType:self.searchType error:error];
    [self _cleanUp];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if ((httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299) == NO) {
        // we have failed don't we want to avoid calling the cancel callback as well
        [connection cancel];
        NSError *error = [NSError errorWithDomain:STErrorDomain
                                             code:STHTTPErrorCode
                                         userInfo:@{ STHTTPResponseKey : httpResponse, NSLocalizedDescriptionKey : @"Unexpected response from the server" }];
        [self _delegateDidFailQuery:self.query withType:self.searchType error:error];
        [self _cleanUp];
    }
    else {
        self.response = response;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    /* Capture the environment since a new query could start on the main thread while
     the JSON parse is happening in the background
     */
    NSData *captureData = self.responseData;
    NSURLResponse *captureResponse = self.response;
    NSURLRequest *captureRequest = self.request;
    NSString *captureQuery = self.query;
    STSearchType captureSearchType = self.searchType;
    
    dispatch_async([[self class] _jsonDecodeQueue], ^{
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:captureData
                                                             options:0
                                                               error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self _delegateDidFailQuery:captureQuery withType:captureSearchType error:error];
                return;
            }
            
            [self _delegateDidFinishQuery:captureQuery withResult:dict withType:captureSearchType];
            
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:captureResponse data:captureData];
            [[[self class] _sharedAPICache] storeCachedResponse:cachedResponse forRequest:captureRequest];
        });
    });
    
    /* We finished loading and captured the variables we need later once parsing is complete
     so cleanup now. We don't want to cleanup inside the dispatch_async back to the main queue
     because another query might be running and we could possibly be cleaning up it's environment.
     Which would be a mistake.
     */
    [self _cleanUp];
}

#pragma mark - Private

- (NSDictionary *)_requestParamsForPage:(NSUInteger)page perPage:(NSUInteger)perPage {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:[self.delegate clientRequestParameters:self
                                                                                                                     forQuery:self.query
                                                                                                                     withType:self.searchType]];
    if (self.engineKey) {
        [requestParams setObject:self.engineKey forKey:@"engine_key"];
    }
    if (self.query) {
        [requestParams setObject:self.query forKey:@"q"];
    }

    [requestParams setObject:@(perPage) forKey:@"per_page"];
    [requestParams setObject:@(page) forKey:@"page"];

    return requestParams;
}

- (void)_addTrackingHeaders:(NSMutableURLRequest *)request {
    [request setValue:SWIFTYPE_API_VERSION forHTTPHeaderField:@"X-SwiftypeAPI-ClientVersion"];
    [request setValue:@"iOS" forHTTPHeaderField:@"X-SwiftypeAPI-Platform"];
}

- (void)_doRequestForPage:(NSUInteger)page perPage:(NSUInteger)perPage {
    // Avoid whitespace queries
    NSString *strippedString = [self.query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([strippedString isEqualToString:@""]) {
        return;
    }
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:[self _requestParamsForPage:page perPage:perPage]
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
    
    [self _delegateDidStartQuery:self.query withType:self.searchType];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:
                                    [NSURL URLWithString:(self.searchType == STSearchTypeSuggest) ? BASE_SUGGEST_URL : BASE_SEARCH_URL]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self _addTrackingHeaders:request];
    
    NSCachedURLResponse *cachedResponse = [[[self class] _sharedAPICache] cachedResponseForRequest:request];
    if (cachedResponse) {
        NSString *captureQuery = self.query;
        STSearchType captureSearchType = self.searchType;
        dispatch_async([[self class] _jsonDecodeQueue], ^{
            NSError *error = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:cachedResponse.data
                                                                 options:0
                                                                   error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [self _delegateDidFailQuery:captureQuery withType:captureSearchType error:error];
                    
                    // Remove the cached response since it looks like we got a JSON parse error
                    [[[self class] _sharedAPICache] removeCachedResponseForRequest:request];
                }
                else {
                    [self _delegateDidFinishQuery:captureQuery withResult:dict withType:captureSearchType];
                }
            });
        });

        return;
    }
    
    self.request = request;
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.connection start];
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                         target:self
                                                       selector:@selector(_connectionTimeout)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)_cancelPending {
    [self.connection cancel];
    if (self.connection) {
        [self _delegateDidCancelQuery:self.query withType:self.searchType];
    }
    [self _cleanUp];
}

- (void)_cleanUp {
    self.connection = nil;
    self.responseData = [NSMutableData data];
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    self.request = nil;
    self.response = nil;
    self.query = @"";
    self.searchType = STSearchTypeUndefined;
}

- (void)_connectionTimeout {
    [self _cancelPending];
    NSError *error = [NSError errorWithDomain:STErrorDomain
                                         code:STTimeoutErrorCode
                                     userInfo:@{ NSLocalizedDescriptionKey : @"Connection timeout" }];
    [self _delegateDidFailQuery:self.query withType:self.searchType error:error];
}

- (void)_delegateDidStartQuery:(NSString *)query withType:(STSearchType)type {
    if ([self.delegate respondsToSelector:@selector(client:didStartQuery:withType:)]) {
        [self.delegate client:self didStartQuery:query withType:type];
    }
}

- (void)_delegateDidFinishQuery:(NSString *)query withResult:(NSDictionary *)result withType:(STSearchType)type {
    if ([self.delegate respondsToSelector:@selector(client:didFinishQuery:withResult:withType:)]) {
        [self.delegate client:self didFinishQuery:query withResult:result withType:type];
    }
}

- (void)_delegateDidCancelQuery:(NSString *)query withType:(STSearchType)type {
    if ([self.delegate respondsToSelector:@selector(client:didCancelQuery:withType:)]) {
        [self.delegate client:self didCancelQuery:query withType:type];
    }
}

- (void)_delegateDidFailQuery:(NSString *)query withType:(STSearchType)type error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(client:didFailQuery:withType:error:)]) {
        [self.delegate client:self didFailQuery:query withType:type error:error];
    }
}

@end
