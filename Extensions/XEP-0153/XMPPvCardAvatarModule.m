//
//  XMPPvCardAvatarModule.h
//  XEP-0153 vCard-Based Avatars
//
//  Created by Eric Chamberlain on 3/9/11.
//  Copyright 2011 RF.com. All rights reserved.

#import "XMPPvCardAvatarModule.h"

#import "NSData+XMPP.h"
#import "NSXMLElement+XMPP.h"
#import "XMPPLogging.h"
#import "XMPPPresence.h"
#import "XMPPStream.h"
#import "XMPPvCardTempModule.h"
#import "XMPPvCardTemp.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
  static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
  static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

NSString *const kXMPPvCardAvatarElement = @"x";
NSString *const kXMPPvCardAvatarNS = @"vcard-temp:x:update";
NSString *const kXMPPvCardAvatarPhotoElement = @"photo";
// unorthodox way to update vcard-temp without modifying photo
NSString *const kXMPPvCardAvatarDisplayElement = @"displayname";

@interface XMPPvCardAvatarModule() {
    __strong XMPPvCardTempModule *_xmppvCardTempModule;
    __strong id <XMPPvCardAvatarStorage> _moduleStorage;
    
    BOOL _autoClearMyvcard;
}
@end

@implementation XMPPvCardAvatarModule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Init/dealloc
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithvCardTempModule:(XMPPvCardTempModule *)xmppvCardTempModule
{
  return [self initWithvCardTempModule:xmppvCardTempModule dispatchQueue:NULL];
}

- (id)initWithvCardTempModule:(XMPPvCardTempModule *)xmppvCardTempModule dispatchQueue:(dispatch_queue_t)queue
{
	NSParameterAssert(xmppvCardTempModule != nil);

	if ((self = [super initWithDispatchQueue:queue])) {
		_xmppvCardTempModule = xmppvCardTempModule;

		// we don't need to call the storage configureWithParent:queue: method,
		// because the vCardTempModule already did that.
		_moduleStorage = (id <XMPPvCardAvatarStorage>)xmppvCardTempModule.xmppvCardTempModuleStorage;

		[_xmppvCardTempModule addDelegate:self delegateQueue:moduleQueue];
		
		_autoClearMyvcard = YES;
	}
	return self;
}


- (void)dealloc {
	[_xmppvCardTempModule removeDelegate:self];

	_moduleStorage = nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (BOOL)autoClearMyvcard
{
	__block BOOL result = NO;
	
	dispatch_block_t block = ^{
        result = self->_autoClearMyvcard;
	};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return result;
}

- (void)setAutoClearMyvcard:(BOOL)flag
{
	dispatch_block_t block = ^{
        self->_autoClearMyvcard = flag;
	};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_async(moduleQueue, block);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSData *)photoDataForJID:(XMPPJID *)jid 
{
	// This is a public method, so it may be invoked on any thread/queue.
	// 
	// The vCardTempModule is thread safe.
	// The moduleStorage should be thread safe. (User may be using custom module storage class).
	// The multicastDelegate is NOT thread safe.
	
	__block NSData *photoData;
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
        photoData = [self->_moduleStorage photoDataForJID:jid xmppStream:self->xmppStream];
		
		if (photoData == nil) 
		{
            [self->_xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
		}
		
	}};
	
	if (dispatch_get_specific(moduleQueueTag))
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	return photoData;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	XMPPLogTrace();
	
	if(self.autoClearMyvcard)
	{
		/*
		 * XEP-0153 Section 4.2 rule 1
		 *
		 * A client MUST NOT advertise an avatar image without first downloading the current vCard. 
		 * Once it has done this, it MAY advertise an image. 
		 */
		[_moduleStorage clearvCardTempForJID:[sender myJID] xmppStream:sender];
	}
}


- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender NS_EXTENSION_UNAVAILABLE("not available in extensions") {
    if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) {
        return;
    }
	XMPPLogTrace();
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            //back to xmppQueue
            [self performBlockAsync:^{
                [_xmppvCardTempModule fetchvCardTempForJID:[sender myJID] ignoreStorage:NO];
            }];
        }
    });
}


- (XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence {
	XMPPLogTrace();
    
	NSXMLElement *currentXElement = [presence elementForName:kXMPPvCardAvatarElement xmlns:kXMPPvCardAvatarNS];
    
    BOOL nameupdate = NO;
    NSXMLElement *displayElement = [currentXElement elementForName:@"displayname"];
    NSString *displayname = nil;
    if (displayElement != nil) {
        displayname = [displayElement stringValue];
    }
    
    //If there is already a x element then remove it
    if(currentXElement)
    {
        // if display name only, send as is
        if ([currentXElement elementForName:@"displayonly"] != nil) {
            nameupdate = YES;
        }
        
        NSUInteger currentXElementIndex = [[presence children] indexOfObject:currentXElement];
        
        if(currentXElementIndex != NSNotFound)
        {
            [presence removeChildAtIndex:currentXElementIndex];
        }
    }
    // add our photo info to the presence stanza
    NSXMLElement *photoElement = nil;
    NSXMLElement *xElement = [NSXMLElement elementWithName:kXMPPvCardAvatarElement xmlns:kXMPPvCardAvatarNS];

    NSString *photoHash = [_moduleStorage photoHashForJID:[sender myJID] xmppStream:sender];

    if (photoHash != nil && !nameupdate)
    {
        photoElement = [NSXMLElement elementWithName:kXMPPvCardAvatarPhotoElement stringValue:photoHash];
    } else {
        photoElement = [NSXMLElement elementWithName:kXMPPvCardAvatarPhotoElement];
    }

    [xElement addChild:photoElement];
    
    if (nameupdate && displayname != nil) {
        NSXMLElement *displayEl = [NSXMLElement elementWithName:kXMPPvCardAvatarDisplayElement stringValue:displayname];
        [xElement addChild:displayEl];
    } else {
        XMPPvCardTemp *vCardTemp = [_xmppvCardTempModule.xmppvCardTempModuleStorage vCardTempForJID:[sender myJID] xmppStream:sender];
        if (vCardTemp != nil) {
            if (vCardTemp.nickname != nil) {
                NSXMLElement *displayElement = [NSXMLElement elementWithName:kXMPPvCardAvatarDisplayElement stringValue:vCardTemp.nickname];
                [xElement addChild:displayElement];
            }
        }
    }
    
    [presence addChild:xElement];
    
	// Question: If photoElement is nil, should we be adding xElement?
	
	return presence;
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence  {
	XMPPLogTrace();

	NSXMLElement *xElement = [presence elementForName:kXMPPvCardAvatarElement xmlns:kXMPPvCardAvatarNS];

	if (xElement == nil) {
		return;
	}

	NSXMLElement *photoElement = [xElement elementForName:kXMPPvCardAvatarPhotoElement];
    NSXMLElement *displayElement = [xElement elementForName:kXMPPvCardAvatarDisplayElement];

	if (photoElement == nil && displayElement == nil) {
		return;
	}
    
    NSString *photoHash = @"";
    if (photoElement != nil) {
        photoHash = [photoElement stringValue];
    }

	XMPPJID *jid = [presence from];
    
    NSString *savedPhotoHash = [_moduleStorage photoHashForJID:jid xmppStream:xmppStream];

	// check the hash
    if (photoElement != nil && [photoHash caseInsensitiveCompare:savedPhotoHash] != NSOrderedSame
        && !([photoHash length] == 0 && [savedPhotoHash length] == 0)) {
		//[_xmppvCardTempModule fetchvCardTempForJID:jid ignoreStorage:YES];
        if ([jid.domain hasPrefix:@"conference"]) {
            //[_xmppvCardTempModule fetchvCardTempForJID:jid ignoreStorage:YES];
        } else {
            [_xmppvCardTempModule forceFetchvCardTempForJID:jid];
        }
    } else if (displayElement != nil && !([jid.domain hasPrefix:@"conference"])){
        NSString *displayname = [displayElement stringValue];
        XMPPvCardTemp *vCardTemp = [_xmppvCardTempModule.xmppvCardTempModuleStorage vCardTempForJID:jid xmppStream:xmppStream];
        if ([displayname length] > 0 &&
            (vCardTemp.nickname == nil || !([vCardTemp.nickname isEqualToString:displayname]))) {
            [_xmppvCardTempModule forceFetchvCardTempForJID:jid];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPvCardTempModuleDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule 
        didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp 
                     forJID:(XMPPJID *)jid
{
	XMPPLogTrace();
	
	if (vCardTemp.photo != nil)
	{
	#if TARGET_OS_IPHONE
		UIImage *photo = [UIImage imageWithData:vCardTemp.photo];
	#else
		NSImage *photo = [[NSImage alloc] initWithData:vCardTemp.photo];
	#endif
		
		if (photo != nil)
		{
			[multicastDelegate xmppvCardAvatarModule:self
			                         didReceivePhoto:photo
			                                  forJID:jid];
		}
	}
	
	/*
	 * XEP-0153 4.1.3
	 * If the client subsequently obtains an avatar image (e.g., by updating or retrieving the vCard), 
	 * it SHOULD then publish a new <presence/> stanza with character data in the <photo/> element.
	 */
    
	if ([[xmppStream myJID] isEqualToJID:jid options:XMPPJIDCompareBare])
	{
		XMPPPresence *presence = xmppStream.myPresence;
        
        if(presence)
        {
            [xmppStream sendElement:presence];
        }


	}
}

- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule{
    //The vCard has been updated on the server so we need to cache it
    [_xmppvCardTempModule fetchvCardTempForJID:[xmppStream myJID] ignoreStorage:NO];
}

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error{
		//The vCard failed to update so we fetch the current one from the server
    [_xmppvCardTempModule fetchvCardTempForJID:[xmppStream myJID] ignoreStorage:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Getter/setter
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize xmppvCardTempModule = _xmppvCardTempModule;


@end
