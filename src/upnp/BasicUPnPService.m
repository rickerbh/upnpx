// **********************************************************************************
//
// BSD License.
// This file is part of upnpx.
//
// Copyright (c) 2010-2011, Bruno Keymolen, email: bruno.keymolen@gmail.com
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this 
// list of conditions and the following disclaimer in the documentation and/or other 
// materials provided with the distribution.
// Neither the name of "Bruno Keymolen" nor the names of its contributors may be 
// used to endorse or promote products derived from this software without specific 
// prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
// POSSIBILITY OF SUCH DAMAGE.
//
// **********************************************************************************


#import "BasicUPnPService.h"
#import "BasicServiceParser.h"
#import "UPnPManager.h"
#import "SSDPDB_ObjC.h"
#import "SoapAction.h"

@interface BasicUPnPService ()
@property (readwrite, strong) SSDPDBDevice_ObjC *ssdpdevice;
@property (readwrite, strong) SoapAction *soap;
@property (strong) NSString *eventUUID;
@property (readwrite, strong) NSMutableDictionary *stateVariables; //StateVariable
@property (strong) NSMutableArray *mObservers; //BasicUPnPServiceObserver
@property (strong) NSRecursiveLock *mMutex;
@end

@implementation BasicUPnPService

- (id)initWithSSDPDevice:(SSDPDBDevice_ObjC *)device {
  self = [super init];
  if (self) {	
    NSLog(@"BasicUPnPService - initWithSSDPDevice - %@", [device urn] );
    _mMutex = [[NSRecursiveLock alloc] init];
    _ssdpdevice = device;
    _urn = [device urn];
    _processed = NO;
    _supportForEvents = NO;
    _stateVariables = [[NSMutableDictionary alloc] init]; //StateVariable
    _mObservers = [[NSMutableArray alloc] init];
    //We still need to initialze this class with information from the location URL given by the ssdp 'device'
    //this is done in 'process'
  }
  return self;
}

- (void)dealloc {
  NSLog(@"BasicUPnPService - dealloc - %@", [self.ssdpdevice urn]);
	if (self.eventUUID) {
		[[[UPnPManager GetInstance] upnpEvents] UnSubscribe:self.eventUUID];
	}
}

- (int)addObserver:(NSObject<BasicUPnPServiceObserver> *)obs {
	int ret = 0;

	[self.mMutex lock];
	[self.mObservers addObject:obs];
	ret = [self.mObservers count];
	[self.mMutex unlock];
	
	return ret;	
}

- (int)removeObserver:(NSObject<BasicUPnPServiceObserver> *)obs {
	int ret = 0;
	
	[self.mMutex lock];
	[self.mObservers removeObject:obs];
	ret = [self.mObservers count];
	[self.mMutex unlock];
	
	return ret;	
}

- (BOOL)isObserver:(NSObject<BasicUPnPServiceObserver> *)obs {
	BOOL ret = NO;
	[self.mMutex lock];
	ret = [self.mObservers containsObject:obs];
	[self.mMutex unlock];
	
	return ret;	
	
}

//Can be overriden by subclasses if they need other kind of parsing
- (int)process {
	int ret = 0;
	
	if (self.isProcessed) {
		return 1;
	}
	
	//We need to initialze this class with information from the location URL given by the ssdp 'ssdpdevice'
	BasicServiceParser *parser = [[BasicServiceParser alloc] initWithUPnPService:self];
	ret = [parser parse];
	
	//Set the soap actions
	if (ret == 0) {
		self.soap = [[[UPnPManager GetInstance] soapFactory] allocSoapWithURN:self.urn andBaseNSURL:self.baseURL andControlURL:self.controlURL andEventURL:self.eventURL];
		//retain is not needed because we did alloc
		self.processed = YES;
	} else {
		self.processed = NO;
	}
	
	//Start listening for events
	if (self.eventURL) {
		self.eventUUID = [[[UPnPManager GetInstance] upnpEvents] Subscribe:(NSObject<UPnPEvents_Observer>*)self];
		if (self.eventUUID) {
	//		NSLog(@"Service Subscribed for events; uuid:%@", eventUUID);
			self.supportForEvents = YES;
		}
	}
	
	return ret;
}

//UPnPEvents_Observer
- (void)UPnPEvent:(NSDictionary *)events {
	[self.mMutex lock];
  for (NSObject<BasicUPnPServiceObserver> *obs in self.mObservers) {
		[obs UPnPEvent:self events:events];
  }
	[self.mMutex unlock];
}

- (NSURL *)GetUPnPEventURL {
  NSURL *ret = nil;
  if (self.eventURL) {
    ret = [NSURL URLWithString:self.eventURL relativeToURL:self.baseURL];
    NSLog(@"[BasicUPnPService GetUPnPEventURL: %@", ret);
  }
  return ret;
}

- (void)SubscriptionTimerExpiresIn:(int)seconds timeoutSubscription:(int)timeout timeSubscription:(double)subscribed {
	//Re-Subscribe
	if (self.eventURL) {
    NSString *oldUUID = self.eventUUID;
		self.eventUUID = [[[UPnPManager GetInstance] upnpEvents] Subscribe:(NSObject<UPnPEvents_Observer>*)self];
    if (self.eventUUID && oldUUID) {
      //NSLog(@"Service Re-Subscribed for events; uuid:%@, old uuid:%@", self.eventUUID, oldUUID);
      //Unsubscribe old
      [[[UPnPManager GetInstance] upnpEvents] UnSubscribe:oldUUID];
			self.supportForEvents = YES;
		}
	}
}

@end
