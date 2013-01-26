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

#import "SSDPDB_ObjC.h"

#include "ssdpdb.h"
#include "ssdpdbobserver.h"
#include "ssdpdbdevice.h"
#include "upnp.h"
#include <vector>


/***
 * C/C++
 */

class SSDPDB_Observer_wrapper:public SSDPDBObserver{
public:
	SSDPDB_ObjC* mObjCObserver;
	SSDPDB_Observer_wrapper(SSDPDB_ObjC* observer){
		mObjCObserver = observer;
		UPNP::GetInstance()->GetSSDP()->GetDB()->AddObserver(this);
	}
	
	virtual ~SSDPDB_Observer_wrapper(){
		UPNP::GetInstance()->GetSSDP()->GetDB()->RemoveObserver(this);
	}
	
	int SSDPDBMessage(SSDPDBMsg* msg){	
		[mObjCObserver SSDPDBUpdate];
		return 0;
	}
private:	
	SSDPDB_Observer_wrapper(){}
};


@interface SSDPDB_ObjC ()
@property (strong) NSMutableArray *mObservers;
@property (readwrite, strong) NSMutableArray *SSDPObjCDevices;
@end

/***
 * Obj-C
 */
@implementation SSDPDB_ObjC

- (id)init {
  self = [super init];

  if (self) {		
    _mObservers = [[NSMutableArray alloc] init];
    _SSDPObjCDevices = [[NSMutableArray alloc] init];
    mWrapper = new SSDPDB_Observer_wrapper(self);
  }

  return self;
}

- (void)dealloc{
  if (mWrapper) {
    delete((SSDPDB_Observer_wrapper*)mWrapper);
  }
}

- (int)startSSDP{
	return UPNP::GetInstance()->GetSSDP()->Start();
}

- (int)stopSSDP{
  return UPNP::GetInstance()->GetSSDP()->Stop();
}

- (int)searchSSDP{
  return UPNP::GetInstance()->GetSSDP()->Search();
}


- (int)addObserver:(NSObject<SSDPDB_ObjC_Observer> *)obs{
  int ret = 0;
  @synchronized(self) {
    [self.mObservers addObject:obs];
    ret = [self.mObservers count];
  }
  return ret;
}

- (int)removeObserver:(NSObject<SSDPDB_ObjC_Observer> *)obs{
  int ret = 0;
  @synchronized(self) {
    [self.mObservers removeObject:obs];
    ret = [self.mObservers count];
  }
  return ret;
}

- (void)setUserAgentProduct:(NSString *)product andOS:(NSString *)os{    
    if(os != nil){
        const char *c_os = [os cStringUsingEncoding:NSASCIIStringEncoding];
        UPNP::GetInstance()->GetSSDP()->SetOS(c_os);        
    }
    if(product != nil){
        const char *c_product = [product cStringUsingEncoding:NSASCIIStringEncoding];
        UPNP::GetInstance()->GetSSDP()->SetProduct(c_product);
    }
}

- (void)SSDPDBUpdate{
  [NSRunLoop currentRunLoop]; //Start our runloop
	
  @autoreleasepool {
    //Inform the listeners
    for (NSObject<SSDPDB_ObjC_Observer> *obs in self.mObservers) {
      [obs SSDPDBWillUpdate:self];
    }
	
    @synchronized(self) {
      [self.SSDPObjCDevices removeAllObjects];
      //Update the Obj-C Array
      UPNP::GetInstance()->GetSSDP()->GetDB()->Lock();
      SSDPDBDevice* thisDevice;
      std::vector<SSDPDBDevice*> devices;
      std::vector<SSDPDBDevice*>::const_iterator it;
      devices = UPNP::GetInstance()->GetSSDP()->GetDB()->GetDevices();
      for(it=devices.begin();it<devices.end();it++){
        thisDevice = *it;
        SSDPDBDevice_ObjC* thisObjCDevice = [[SSDPDBDevice_ObjC alloc] initWithCPPDevice:thisDevice];
        [self.SSDPObjCDevices addObject:thisObjCDevice];
      }
      UPNP::GetInstance()->GetSSDP()->GetDB()->Unlock();
      
      //Inform the listeners
      for (NSObject<SSDPDB_ObjC_Observer> *obs in self.mObservers) {
        [obs SSDPDBUpdated:self];
      }
    }
  }
}
@end


@interface SSDPDBDevice_ObjC ()
@property (readwrite, assign) bool isdevice;
@property (readwrite, assign) bool isroot;
@property (readwrite, assign) bool isservice;
@property (readwrite, strong) NSString *uuid;
@property (readwrite, strong) NSString *urn;
@property (readwrite, strong) NSString *usn;
@property (readwrite, strong) NSString *type;
@property (readwrite, strong) NSString *version;
@property (readwrite, strong) NSString *host;
@property (readwrite, strong) NSString *location;
@property (readwrite, assign) unsigned int ip;
@property (readwrite, assign) unsigned short port;
@end

/**
 * Device class
 */
@implementation SSDPDBDevice_ObjC

- (id)initWithCPPDevice:(void *)cppDevice {
  self = [super init];

  if (self) {
    SSDPDBDevice *dev = (SSDPDBDevice *)cppDevice;

    _isdevice	= dev->isdevice==1?true:false;
    _isroot		= dev->isroot==1?true:false;
    _isservice	= dev->isservice==1?true:false;
    _uuid		= [[NSString alloc] initWithCString:dev->uuid.c_str() encoding:NSASCIIStringEncoding];
    _urn			= [[NSString alloc] initWithCString:dev->urn.c_str() encoding:NSASCIIStringEncoding];
    _usn			= [[NSString alloc] initWithCString:dev->usn.c_str() encoding:NSASCIIStringEncoding];
    _type		= [[NSString alloc] initWithCString:dev->type.c_str() encoding:NSASCIIStringEncoding];
    _version		= [[NSString alloc] initWithCString:dev->version.c_str() encoding:NSASCIIStringEncoding];
    _host		= [[NSString alloc] initWithCString:dev->host.c_str() encoding:NSASCIIStringEncoding];
    _location	= [[NSString alloc] initWithCString:dev->location.c_str() encoding:NSASCIIStringEncoding];
    _ip			= dev->ip;
    _port		= dev->port;
  }

  return self;
}

@end