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


#import <Foundation/Foundation.h>
#import "UPnPEvents.h"

@class BasicUPnPServiceObserver;
@class BasicUPnPService;
@class SoapAction;
@class SSDPDBDevice_ObjC;

@protocol BasicUPnPServiceObserver
- (void)UPnPEvent:(BasicUPnPService*)sender events:(NSDictionary *)events;
@end

@interface BasicUPnPService : NSObject <UPnPEvents_Observer>
@property (strong) NSURL* baseURL;
@property (strong) NSString* baseURLString;
@property (strong) NSString* descriptionURL;
@property (strong) NSString* eventURL;
@property (strong) NSString* controlURL;
@property (strong) NSString* serviceType;
@property (readonly, strong) SSDPDBDevice_ObjC *ssdpdevice;
@property (readonly, strong) NSMutableDictionary *stateVariables;
@property (readonly, strong) SoapAction *soap;
@property (strong) NSString* urn;
@property (assign, getter = isProcessed) BOOL processed;
@property (assign, getter = isSupportForEvents) BOOL supportForEvents;

- (id)initWithSSDPDevice:(SSDPDBDevice_ObjC*)device;
- (int)addObserver:(NSObject<BasicUPnPServiceObserver> *)obs;
- (int)removeObserver:(NSObject<BasicUPnPServiceObserver> *)obs;
- (BOOL)isObserver:(NSObject<BasicUPnPServiceObserver> *)obs;

//Process is called by the ServiceFactory after basic parsing is done and succeeded
//The BasicUPnPService (this) members are set with the right values
//Further processing is service dependent and must be handled by the derived classes 
//The return value must be 0 when implenented
- (int)process; //in C++ this should be a pure virtual function

@end
