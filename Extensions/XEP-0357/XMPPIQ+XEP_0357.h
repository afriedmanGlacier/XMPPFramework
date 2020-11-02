//
//  NSXMLElement+NSXMLElement_XEP_0357.h
//
//  Created by David Chiles on 2/9/16.
//
//

#import "XMPPIQ.h"
@class XMPPJID;

/**
 XMPPIQ (XEP0357) is a class extension on XMPPIQ for creating the elements for XEP-0357 http://xmpp.org/extensions/xep-0357.html
 */
extern NSString * __nonnull  const XMPPPushXMLNS;
extern NSString * __nonnull  const XMPPRegisterPushTokenXMLNS;

@interface XMPPIQ (XEP0357)

/**
 Creates an IQ stanza for enabling push notificiations. http://xmpp.org/extensions/xep-0357.html#enabling
 
 @param jid The jid of the XMPP Push Service
 @param node Optional node of the XMPP Push Service
 @param options Optional values to passed to your XMPP service (this is likely some sort of secret or token to validate this user/device with teh app server)
 @return An IQ stanza
 */
+ (nonnull instancetype)enableNotificationsElementWithJID:(nonnull XMPPJID *)jid node:(nullable NSString *)node options:(nullable NSDictionary <NSString *,NSString *>*)options;

/**
 Creates an IQ stanza for enabling push notificiations. http://xmpp.org/extensions/xep-0357.html#enabling
 
 @param jid The jid of the XMPP Push Service
 @param node Optional node of the XMPP Push Service
 @param options Optional values to passed to your XMPP service (this is likely some sort of secret or token to validate this user/device with teh app server)
 @param elementId the XMPPElement id for tracking responses
 @return An IQ stanza
 */
+ (nonnull instancetype)enableNotificationsElementWithJID:(nonnull XMPPJID *)jid node:(nullable NSString *)node options:(nullable NSDictionary <NSString *,NSString *>*)options elementId:(nullable NSString*)elementId;

/**
 Creates an IQ stanza for disable push notifications. http://xmpp.org/extensions/xep-0357.html#disabling
 
 @param jid the jid of the XMPP Push Service
 @param node the node of the XMPP push Service
 @return an IQ Stanza
 */
+ (nonnull instancetype)disableNotificationsElementWithJID:(nonnull XMPPJID *)jid node:(nullable NSString *)node
;
/**
 Creates an IQ stanza for disable push notifications. http://xmpp.org/extensions/xep-0357.html#disabling
 
 @param jid the jid of the XMPP Push Service
 @param node the node of the XMPP push Service
 @param elementId the XMPPElement id for tracking responses
 @return an IQ Stanza
 */
+ (nonnull instancetype)disableNotificationsElementWithJID:(nonnull XMPPJID *)jid node:(nullable NSString *)node elementId:(nullable NSString*)elementId;

+ (nonnull instancetype)registerPushElementWithJID:(nonnull XMPPJID *)fromjid tojid:(nonnull NSString *)tojid token:(nonnull NSString *)token voiptoken:(nullable NSString *)voiptoken elementId:(nullable NSString *)elementId;

//this should eventually go away. Added for migration from using push notifications to messages for call setup. 
+ (nonnull instancetype)registerPushElementWithJID:(nonnull XMPPJID *)fromjid tojid:(nonnull NSString *)tojid token:(nonnull NSString *)token voiptoken:(nullable NSString *)voiptoken migrated:(BOOL)migrated elementId:(nullable NSString *)elementId;

+ (nonnull instancetype)unregisterPushElementWithJID:(nonnull XMPPJID *)fromjid tojid:(nonnull NSString *)tojid elementId:(nullable NSString *)elementId;

@end
