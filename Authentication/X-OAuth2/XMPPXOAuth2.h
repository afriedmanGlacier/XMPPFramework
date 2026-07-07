//
//  XMPPXOAuth2.h
//  XMPPFramework
//
//  Generic X-OAUTH2 SASL mechanism for token-based authentication.
//

#import <Foundation/Foundation.h>
#import "XMPPSASLAuthentication.h"
#import "XMPPStream.h"

NS_ASSUME_NONNULL_BEGIN
@interface XMPPXOAuth2 : NSObject <XMPPSASLAuthentication>

- (instancetype)initWithStream:(XMPPStream *)stream
                      username:(nullable NSString *)username
                   accessToken:(NSString *)accessToken;

@end



@interface XMPPStream (XMPPXOAuth2)


@property (nonatomic, readonly) BOOL supportsXOAuth2Authentication;

- (BOOL)authenticateWithAccessToken:(NSString *)accessToken error:(NSError **)errPtr;

@end
NS_ASSUME_NONNULL_END
