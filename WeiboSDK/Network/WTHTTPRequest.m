//
//  WTHTTPRequest.m
//  Weibo
//
//  Created by Wu Tian on 12-2-11.
//  Copyright (c) 2012年 Wutian. All rights reserved.
//

#import "WTHTTPRequest.h"
#import "WeiboRequestError.h"
#import "WTCallback.h"

#import "OAuthConsumer.h"
#import "WTOASingnaturer.h"

@interface WTHTTPRequest()
- (void)postFailWithError:(NSError *)error;
- (NSString *)oAuthAuthorizationHeader;
- (NSString *)_parameterStringByDictionary:(NSDictionary *) parameters;
@end

@implementation WTHTTPRequest
@synthesize responseCallback, oAuthToken, oAuthTokenSecret, parameters;
@synthesize oAuth2Token = _oAuth2Token;

+ (WTHTTPRequest *)requestWithURL:(NSURL *)url{
    return [[[self alloc] initWithURL:url] autorelease];
}

- (id)initWithURL:(NSURL *)newURL{
    if ((self = [super initWithURL:newURL])) {
        [self setDelegate:self];
    }
    return self;
}

- (void)prepareAuthrize{
    if ([[self requestMethod] isEqualToString:@"GET"]) {
        NSURL * urlWithQuery = [NSURL URLWithString:[self _parameterStringByDictionary:parameters] 
                                      relativeToURL:[self url]];
        [self setURL:urlWithQuery];
    }else{
        for(NSString * key in parameters){
            NSString * value = [parameters objectForKey:key];
            if(value != nil){
                [self addPostValue:value forKey:key];
            }
        }
    }
}
- (void)v1_startAuthrizedRequest{
    [self prepareAuthrize];
    [self addRequestHeader:@"Authorization" value:[self v1_oAuthAuthorizationHeader]];
    [self startAsynchronous];
}
- (void)startAuthrizedRequest{
    [self prepareAuthrize];
    [self addRequestHeader:@"Authorization" value:[self oAuthAuthorizationHeader]];
    [self startAsynchronous];
}

- (void)dealloc{
    [responseCallback release]; responseCallback = nil;
    [oAuthToken release]; oAuthToken = nil;
    [oAuthTokenSecret release]; oAuthTokenSecret = nil;
    [parameters release]; parameters = nil;
    [super dealloc];
}

- (NSString *)oAuthAuthorizationHeader{
    return [NSString stringWithFormat:@"OAuth2 %@",self.oAuth2Token];
}
- (NSString *)v1_oAuthAuthorizationHeader{
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:WEIBO_CONSUMER_KEY
													secret:WEIBO_CONSUMER_SECRET];
    OAToken * token = [[OAToken alloc] initWithKey:oAuthToken secret:oAuthTokenSecret];
    WTOASingnaturer *singnaturer = [[WTOASingnaturer alloc] initWithURL:[[self url] absoluteString]
                                                           consumer:consumer
                                                              token:token
                                                              realm:nil
                                                  signatureProvider:nil];
    [consumer release];
    [token release];
    
    NSArray * keys = [parameters allKeys];
    NSMutableArray * parameter = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    for (id key in keys) {
        OARequestParameter * requestParameter = [[OARequestParameter alloc] initWithName:key value:[parameters valueForKey:key]];
        [parameter addObject:requestParameter];
        [requestParameter release];
    }
    
    [singnaturer setParameters:parameter];
    [parameter release];
	[singnaturer setMethod:[self requestMethod]];
    [singnaturer setUrlStringWithoutQuery:[[[[self url] absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0]];
    NSString *authString = [NSString stringWithString:[singnaturer getSingnatureString]];
    [singnaturer release];
    
    return authString;
}

- (NSString *)_parameterStringByDictionary:(NSDictionary *) params{
	NSMutableString * result = [NSMutableString string];
    BOOL isFirstParameter = YES;
	for(NSString * key in params){
		NSString * value = [params objectForKey:key];
		if(value != nil){
            if(isFirstParameter) 
                [result appendString:@"?"];
            else 
                [result appendString:@"&"];
            isFirstParameter = NO;
			[result appendFormat:@"%@=%@",key,value];
		}
	}
	return [result stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)postFailWithError:(NSError *)aError{
    NSLog(@"error response:%@",[self responseString]);
    [responseCallback invoke:aError];
}

#pragma mark -
#pragma mark Request delegates
- (void)requestFinished:(ASIHTTPRequest *)request{
    int statusCode = [self responseStatusCode];
    if (statusCode == 200) {
        NSString * responseString = [self responseString];
        [responseCallback invoke:responseString];
    }else{
        WeiboRequestError * requestError = [WeiboRequestError 
                                            errorWithResponseString:[self responseString] statusCode:statusCode];
        [self postFailWithError:requestError];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request{
    WeiboRequestError * requestError = [WeiboRequestError 
                                        errorWithResponseString:[self responseString] statusCode:self.responseStatusCode];
    [self postFailWithError:requestError];
    
    // In weibo api v2, error response has currect status code.
    // For more information, use WeiboRequestError instead.
    /*
    WeiboRequestError * requestError = [WeiboRequestError errorWithHttpRequestError:[self error]];
    [self postFailWithError:requestError];
     */
}

@end
