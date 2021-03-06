//
//  WeiboDirectMessageStream.m
//  Weibo
//
//  Created by Wutian on 13-9-4.
//  Copyright (c) 2013年 Wutian. All rights reserved.
//

#import "WeiboDirectMessageStream.h"
#import "WTCallback.h"
#import "WeiboRequestError.h"
#import "NSArray+WeiboAdditions.h"

NSString * const WeiboDirectMessageStreamDidUpdateNotification = @"WeiboDirectMessageStreamDidUpdateNotification";
NSString * const WeiboDirectMessageStreamFinishedLoadingNotification = @"WeiboDirectMessageStreamFinishedLoadingNotification";

@interface WeiboDirectMessageStream ()
{
    NSMutableArray * _messages;
    struct {
        unsigned int isLoadingNewer:1;
        unsigned int isLoadingOlder:1;
        unsigned int isAtEnd:1;
        unsigned int messagesLoaded:1;
    } _flags;
}

@end

@implementation WeiboDirectMessageStream

- (void)dealloc
{
    [_messages release], _messages = nil;
    
    [super dealloc];
}

- (instancetype)init
{
    if (self = [super init])
    {
        _messages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
//        self.messages = [aDecoder decodeObjectForKey:@"messages"];
        self.account = [aDecoder decodeObjectForKey:@"account"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
//    [aCoder encodeObject:self.messages forKey:@"messages"];
    [aCoder encodeObject:self.account forKey:@"account"];
}

- (NSArray *)messages
{
    return _messages;
}

- (BOOL)forceReadBit
{
    return NO;
}

- (WeiboMessageID)newestMessageID
{
    return [[_messages lastObject] messageID];
}
- (WeiboMessageID)oldestMessageID
{
    return [[_messages firstObject] messageID];
}

- (void)messagesResponse:(id)response info:(id)info
{
    if ([response isKindOfClass:[WeiboRequestError class]])
    {
        
    }
    else if ([response isKindOfClass:[NSArray class]])
    {
        [self addMessages:response];
        
        _flags.messagesLoaded = YES;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WeiboDirectMessageStreamFinishedLoadingNotification object:self];
}

- (void)_loadNewer
{
    
}
- (void)_loadOlder
{
    
}

- (void)loadNewer
{
    if (_flags.isLoadingNewer) return;
    
    [self _loadNewer];
    
    _flags.isLoadingNewer = YES;
}
- (void)loadOlder
{
    if (_flags.isLoadingOlder) return;
    
    [self _loadOlder];
    
    _flags.isLoadingNewer = YES;
}

- (BOOL)isLoadingNewer
{
    return _flags.isLoadingNewer;
}
- (BOOL)isLoadingOlder
{
    return _flags.isLoadingOlder;
}
- (BOOL)isLoading
{
    return _flags.isLoadingNewer || _flags.isLoadingOlder;
}
- (BOOL)messagesLoaded
{
    return _flags.messagesLoaded;
}

- (void)loadNewerResponse:(id)response info:(id)info
{
    _flags.isLoadingNewer = NO;
    
    [self messagesResponse:response info:info];
}
- (void)loadOlderResponse:(id)response info:(id)info
{
    _flags.isLoadingOlder = NO;
    
    [self messagesResponse:response info:info];
}

- (WTCallback *)loadNewerResponseCallback
{
    return WTCallbackMake(self, @selector(loadNewerResponse:info:), nil);
}

- (WTCallback *)loaderOlderResponseCallback
{
    return WTCallbackMake(self, @selector(loadOlderResponse:info:), nil);
}

- (void)addMessages:(NSArray *)messages
{
    BOOL readBit = [self forceReadBit];
    
    for (WeiboDirectMessage * message in messages)
    {
        NSInteger idx = [_messages indexOfObject:message inSortedRange:NSMakeRange(0, _messages.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(WeiboDirectMessage * obj1, WeiboDirectMessage * obj2) {
            return [obj1 compare:obj2];
        }];
        
        [_messages insertObject:message atIndex:idx];
        
        if (readBit) message.read = YES;
    }
    
    if (messages.count)
    {
        NSDictionary * userInfo = @{@"messages" : messages};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WeiboDirectMessageStreamDidUpdateNotification object:self userInfo:userInfo];
    }
}
- (void)deleteMessage:(WeiboDirectMessage *)message
{
    
}

@end
