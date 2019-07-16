//
//  XMPPPinned.h
//  Pods
//
//  Created by Andy Friedman on 5/28/19.

#import <Foundation/Foundation.h>
#import "XMPPJID.h"
#import "XMPPIQ.h"

@import KissXML;

NS_ASSUME_NONNULL_BEGIN
@interface XMPPPinned: NSObject

@property (nonatomic, readonly) NSArray <NSString*> *pinnedURLs;
@property (nonatomic, readonly) NSMutableDictionary<NSString*,NSMutableDictionary*> *pinnedKeys;

- (instancetype)initWithURLs:(NSArray *)urls keys:(NSDictionary <NSString*,NSMutableDictionary*> *)keys NS_DESIGNATED_INITIALIZER;

/** Will return nil if iq does not contain slot */
- (nullable instancetype)initWithIQ:(XMPPIQ *)iq;

/** Not available, use designated initializer */
- (instancetype) init NS_UNAVAILABLE;

@end
NS_ASSUME_NONNULL_END
