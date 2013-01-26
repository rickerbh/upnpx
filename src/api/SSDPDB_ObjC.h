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

@class SSDPDB_ObjC;

/**
 * Interface
 */
@protocol SSDPDB_ObjC_Observer
- (void)SSDPDBUpdated:(SSDPDB_ObjC *)sender;
- (void)SSDPDBWillUpdate:(SSDPDB_ObjC *)sender;
@end


/**
 * DB Class
 */
@interface SSDPDB_ObjC : NSObject {
@private
	void* mWrapper;
}
@property (readonly, strong) NSMutableArray *SSDPObjCDevices;

- (int)startSSDP;
- (int)stopSSDP;
- (int)searchSSDP;
- (int)addObserver:(NSObject<SSDPDB_ObjC_Observer> *)obs;
- (int)removeObserver:(NSObject<SSDPDB_ObjC_Observer> *)obs;
- (void)SSDPDBUpdate;
- (void)setUserAgentProduct:(NSString *)product andOS:(NSString *)os;

@end

/**
 * Device class
 */
@interface SSDPDBDevice_ObjC : NSObject
@property (readonly, assign) bool isdevice;
@property (readonly, assign) bool isroot;
@property (readonly, assign) bool isservice;
@property (readonly, strong) NSString *uuid;
@property (readonly, strong) NSString *urn;
@property (readonly, strong) NSString *usn;
@property (readonly, strong) NSString *type;
@property (readonly, strong) NSString *version;
@property (readonly, strong) NSString *host;
@property (readonly, strong) NSString *location;
@property (readonly, assign) unsigned int ip;
@property (readonly, assign) unsigned short port;

-(id)initWithCPPDevice:(void*)cppDevice;

@end