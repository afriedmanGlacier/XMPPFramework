//
//  NSXMLElement+NSXMLElement_XEP_0357.m
//  Pods
//
//  Created by David Chiles on 2/9/16.
//
//

#import "XMPPIQ+XEP_0357.h"
#import "XMPPJID.h"
#import "NSXMLElement+XMPP.h"
#import "XMPPStream.h"

NSString *const XMPPPushXMLNS = @"urn:xmpp:push:0";
NSString *const XMPPRegisterPushTokenXMLNS = @"http://jabber.org/protocol/commands";

@implementation XMPPIQ (XEP0357)

+ (instancetype)enableNotificationsElementWithJID:(XMPPJID *)jid node:(NSString *)node options:(nullable NSDictionary<NSString *,NSString *> *)options {
    return [self enableNotificationsElementWithJID:jid node:node options:options elementId:nil];
}

+ (instancetype)enableNotificationsElementWithJID:(XMPPJID *)jid node:(NSString *)node options:(nullable NSDictionary<NSString *,NSString *> *)options elementId:(NSString *)elementId
{
    if (!elementId) {
        elementId = [XMPPStream generateUUID];
    }
    NSXMLElement *enableElement = [self elementWithName:@"enable" xmlns:XMPPPushXMLNS];
    [enableElement addAttributeWithName:@"jid" stringValue:[jid full]];
    if ([node length]) {
        [enableElement addAttributeWithName:@"node" stringValue:node];
    }
    
    if ([options count]) {
        NSXMLElement *dataForm = [self elementWithName:@"x" xmlns:@"jabber:x:data"];
        [dataForm addAttributeWithName:@"type" stringValue:@"submit"];
        NSXMLElement *formTypeField = [NSXMLElement elementWithName:@"field"];
        [formTypeField addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
        [formTypeField addChild:[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/pubsub#publish-options"]];
        [dataForm addChild:formTypeField];
        
        [options enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            NSXMLElement *formField = [NSXMLElement elementWithName:@"field"];
            [formField addAttributeWithName:@"var" stringValue:key];
            [formField addChild:[NSXMLElement elementWithName:@"value" stringValue:obj]];
            [dataForm addChild:formField];
        }];
        [enableElement addChild:dataForm];
    }
    
    return [self iqWithType:@"set" elementID:elementId child:enableElement];
    
}

+ (instancetype)disableNotificationsElementWithJID:(XMPPJID *)jid node:(NSString *)node {
    return [self disableNotificationsElementWithJID:jid node:node elementId:nil];
}

+ (instancetype)disableNotificationsElementWithJID:(XMPPJID *)jid node:(NSString *)node elementId:(nullable NSString *)elementId
{
    if (!elementId) {
        elementId = [XMPPStream generateUUID];
    }
    NSXMLElement *disableElement = [self elementWithName:@"disable" xmlns:XMPPPushXMLNS];
    [disableElement addAttributeWithName:@"jid" stringValue:[jid full]];
    if ([node length]) {
        [disableElement addAttributeWithName:@"node" stringValue:node];
    }
    return [self iqWithType:@"set" elementID:elementId child:disableElement];
}

/** registerPush IQ, documented here: https://github.com/iNPUTmice/p2/blob/master/README.md#what-conversations-sends-to-the-app-server
    <iq from="xiaomia1@jabber.de/Conversations.sAdA" id="cXo5bNCF6wgD" to="p2.siacs.eu" type="set">
        <command xmlns="http://jabber.org/protocol/commands" action="execute" node="register-push-fcm">
            <x xmlns="jabber:x:data" type="submit">
                <field var="token">
                <value>eeDXSJjASJY:APA91bEKxhXK54-vHhY9O55JmU2R0nDJL2rRENm-W9uPY6x3jHi0i0OyvPu6js9jVPZqDeX9ZQydZCBZE19o7a0kK4_n88fCgufXjaOlvalh9VibB2zOI7dQRTaDNB3H5s4dicpWD0m4</value>
                </field>
                <field var="device-id">
                    <value>92afd7a91cdba9a0</value>
                </field>
            </x>
        </command>
    </iq>
 */
+ (instancetype)registerPushElementWithJID:(XMPPJID *)fromjid tojid:(NSString *)tojid token:(NSString *)token voiptoken:(NSString *)voiptoken elementId:(NSString *)elementId
{
    if (!elementId) {
        elementId = [XMPPStream generateUUID];
    }
    NSXMLElement *commandElement = [self elementWithName:@"command" xmlns:XMPPRegisterPushTokenXMLNS];
    [commandElement addAttributeWithName:@"action" stringValue:@"execute"];
    [commandElement addAttributeWithName:@"node" stringValue:@"register-push-apns"];
    
    NSXMLElement *dataForm = [self elementWithName:@"x" xmlns:@"jabber:x:data"];
    [dataForm addAttributeWithName:@"type" stringValue:@"submit"];
    NSXMLElement *tokenField = [NSXMLElement elementWithName:@"field"];
    [tokenField addAttributeWithName:@"var" stringValue:@"token"];
    [tokenField addChild:[NSXMLElement elementWithName:@"value" stringValue:token]];
    [dataForm addChild:tokenField];
    
    if (voiptoken != nil) {
        NSXMLElement *voiptokenField = [NSXMLElement elementWithName:@"field"];
        [voiptokenField addAttributeWithName:@"var" stringValue:@"voiptoken"];
        [voiptokenField addChild:[NSXMLElement elementWithName:@"value" stringValue:voiptoken]];
        [dataForm addChild:voiptokenField];
    }
    
    NSXMLElement *idField = [NSXMLElement elementWithName:@"field"];
    [idField addAttributeWithName:@"var" stringValue:@"device-id"];
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *deviceId = [[currentDevice identifierForVendor] UUIDString];
    [idField addChild:[NSXMLElement elementWithName:@"value" stringValue:deviceId]];
    [dataForm addChild:idField];
    
    [commandElement addChild:dataForm];
    
    XMPPIQ *iq = [self iqWithType:@"set" elementID:elementId child:commandElement];
    [iq addAttributeWithName:@"from" stringValue:[fromjid full]];
    [iq addAttributeWithName:@"to" stringValue:tojid];
    
    return iq;
}

@end
