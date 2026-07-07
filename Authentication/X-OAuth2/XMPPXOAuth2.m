//
//  XMPPXOAuth2.m
//  XMPPFramework
//
//  Generic X-OAUTH2 SASL mechanism for token-based authentication.
//  Modeled on XMPPXOAuth2Google, with the Google-proprietary
//  namespaces and host override stripped out so it can be pointed
//  at any server (e.g. ejabberd) advertising the X-OAUTH2 mechanism.
//

#import "XMPPXOAuth2.h"
#import "XMPP.h"
#import "XMPPLogging.h"
#import "XMPPInternal.h"
#import "NSData+XMPP.h"

#import <objc/runtime.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_INFO; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@interface XMPPXOAuth2 ()
{
#if __has_feature(objc_arc_weak)
	__weak XMPPStream *xmppStream;
#else
	__unsafe_unretained XMPPStream *xmppStream;
#endif

	NSString *username;
	NSString *accessToken;
}

@end

@implementation XMPPXOAuth2

+ (NSString *)mechanismName
{
	return @"X-OAUTH2";
}

- (instancetype)initWithStream:(XMPPStream *)stream password:(NSString *)password
{
	if ((self = [super init]))
	{
		xmppStream = stream;
	}
	return self;
}

- (instancetype)initWithStream:(XMPPStream *)stream
                      username:(NSString *)inUsername
                   accessToken:(NSString *)inAccessToken
{
	if ((self = [super init]))
	{
		xmppStream = stream;
		username = inUsername;
		accessToken = inAccessToken;
	}
	return self;
}

- (BOOL)start:(NSError **)errPtr
{
	if (!accessToken)
	{
		NSString *errMsg = @"Missing accessToken.";
		NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};

		NSError *err = [NSError errorWithDomain:XMPPStreamErrorDomain code:XMPPStreamInvalidState userInfo:info];

		if (errPtr) *errPtr = err;
		return NO;
	}
	XMPPLogTrace();

	// From RFC 4616 - PLAIN SASL Mechanism:
	// [authzid] UTF8NUL authcid UTF8NUL passwd
	//
	// authzid: authorization identity
	// authcid: authentication identity (username)
	// passwd : password for authcid (the access token, in our case)

	NSString *authUsername = username;
	if (authUsername == nil)
	{
		authUsername = [xmppStream.myJID user];
	}

	NSString *payload = [NSString stringWithFormat:@"\0%@\0%@", authUsername, accessToken];
	NSString *base64 = [[payload dataUsingEncoding:NSUTF8StringEncoding] xmpp_base64Encoded];

	// <auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="X-OAUTH2">Base-64-Info</auth>

	NSXMLElement *auth = [NSXMLElement elementWithName:@"auth" xmlns:@"urn:ietf:params:xml:ns:xmpp-sasl"];
	[auth addAttributeWithName:@"mechanism" stringValue:@"X-OAUTH2"];
	[auth setStringValue:base64];

	[xmppStream sendAuthElement:auth];

	return YES;
}

- (XMPPHandleAuthResponse)handleAuth:(NSXMLElement *)authResponse
{
	XMPPLogTrace();

	// We're expecting a success response.
	// If we get anything else we can safely assume it's the equivalent of a failure response.

	if ([[authResponse name] isEqualToString:@"success"])
	{
		return XMPPHandleAuthResponseSuccess;
	}
	else
	{
		return XMPPHandleAuthResponseFailed;
	}
}
@end

@implementation XMPPStream (XMPPXOAuth2)


- (BOOL)supportsXOAuth2Authentication
{
	return [self supportsAuthenticationMechanism:[XMPPXOAuth2 mechanismName]];
}

- (BOOL)authenticateWithAccessToken:(NSString *)accessToken error:(NSError **)errPtr
{
	XMPPLogTrace();

	__block BOOL result = YES;
	__block NSError *err = nil;

	dispatch_block_t block = ^{ @autoreleasepool {

		if ([self supportsXOAuth2Authentication])
		{
			XMPPXOAuth2 *xoauth2Auth = [[XMPPXOAuth2 alloc] initWithStream:self
			                                                      username:nil
			                                                   accessToken:accessToken];

			result = [self authenticate:xoauth2Auth error:&err];
		}
		else
		{
			NSString *errMsg = @"The server does not support X-OAUTH2 authentication.";
			NSDictionary *info = @{NSLocalizedDescriptionKey : errMsg};

			err = [NSError errorWithDomain:XMPPStreamErrorDomain code:XMPPStreamUnsupportedAction userInfo:info];

			result = NO;
		}
	}};

	if (dispatch_get_specific(self.xmppQueueTag))
		block();
	else
		dispatch_sync(self.xmppQueue, block);

	if (errPtr)
		*errPtr = err;

	return result;
}

@end
