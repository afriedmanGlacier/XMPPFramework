//
//  XMPPPinned.m
//  XMPPFramework
//
//  Created by Andy Friedman on 5/28/19.

#import "XMPPPinned.h"
#import "NSXMLElement+XMPP.h"

@implementation XMPPPinned

- (instancetype) init {
    NSAssert(NO, @"Use designated initializer.");
    return nil;
}

- (instancetype)initWithURLs:(NSArray *)urls keys:(NSDictionary <NSString*,NSMutableDictionary*> *)keys {
    NSParameterAssert(urls != nil);
    NSParameterAssert(keys != nil);
    if (self = [super init]) {
        _pinnedKeys = [keys copy];
        _pinnedURLs = [urls copy];
    }
    return self;
}

- (nullable instancetype)initWithIQ:(XMPPIQ *)iq {
    NSParameterAssert(iq != nil);
    NSXMLElement *attachments = [iq elementForName:@"attachments"];
    
    if (attachments == nil) {
        return nil;
    }
    
    NSArray <NSXMLElement*> *attachmentAR = [attachments elementsForName:@"attachment"];
    NSMutableArray *urlStrings = [NSMutableArray arrayWithCapacity:attachmentAR.count];
    
    NSMutableDictionary<NSString*,NSMutableDictionary*> *keys = [NSMutableDictionary dictionaryWithCapacity:attachmentAR.count];
    
    [attachmentAR enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *url = [obj attributeStringValueForName:@"url"];
        [urlStrings addObject:url];
        
        NSMutableDictionary<NSString*,NSString*> *encryptAttrs = [NSMutableDictionary dictionaryWithCapacity:4];
        [encryptAttrs setObject:[obj attributeStringValueForName:@"key"] forKey:@"key"];
        [encryptAttrs setObject:[obj attributeStringValueForName:@"iv"] forKey:@"iv"];
        [encryptAttrs setObject:[obj attributeStringValueForName:@"tag"] forKey:@"tag"];
        [encryptAttrs setObject:[obj attributeStringValueForName:@"cipher"] forKey:@"cipher"];
        
        [keys setObject:encryptAttrs forKey:url];
    }];
    return [self initWithURLs:urlStrings keys:keys];
}

- (NSMutableDictionary<NSString*,NSMutableDictionary*>*) getKeys {
    return self.pinnedKeys;
}

- (NSArray<NSString*>*) getURLs {
    return self.pinnedURLs;
}

@end

