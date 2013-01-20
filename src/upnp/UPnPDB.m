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

#import "UPnPDB.h"
#import "UPnPManager.h"

@interface UPnPDB()
@property (readwrite, strong)	NSMutableArray *rootDevices; //BasicUPnPDevice (full info is known)
@property (strong) NSMutableArray *readyForDescription; //BasicUPnPDevice (only some info is known)
@property (strong) NSRecursiveLock *mMutex;
@property (strong) SSDPDB_ObjC *mSSDP;
@property (strong) NSMutableArray *mObservers;
@property (strong) NSThread *mHTTPThread;

- (BasicUPnPDevice*)addToDescriptionQueue:(SSDPDBDevice_ObjC *)ssdpdevice;
@end

@implementation UPnPDB

- (id)initWithSSDP:(SSDPDB_ObjC *)ssdp{
  self = [super init];
  if (self) {
    _mSSDP = ssdp;
    _mMutex = [[NSRecursiveLock alloc] init];
    _rootDevices = [[NSMutableArray alloc] init]; //BasicUPnPDevice
    _readyForDescription = [[NSMutableArray alloc] init]; //BasicUPnPDevice
    _mObservers = [[NSMutableArray alloc] init];
    
    [_mSSDP addObserver:self];
    
    _mHTTPThread = [[NSThread alloc] initWithTarget:self selector:@selector(httpThread:) object:nil];
    [_mHTTPThread start];
	}
	return self;
}

- (void)dealloc{
	[_mHTTPThread cancel];
	[_mSSDP removeObserver:self];
	[_rootDevices removeAllObjects];
}

- (void)lock{
	[self.mMutex lock];
}

- (void)unlock{
	[self.mMutex unlock];
}

- (int)addObserver:(UPnPDBObserver *)obs{
	int ret = 0;
	[self lock];
	[self.mObservers addObject:obs];
	ret = [self.mObservers count];
	[self unlock];
	return ret;
}

- (int)removeObserver:(UPnPDBObserver *)obs{
	int ret = 0;
	[self lock];
	[self.mObservers removeObject:obs];
	ret = [self.mObservers count];
	[self unlock];
	return ret;
}

/**
 * SSDPDB_ObjC_Observer
 */

//The SSDPObjCDevices array might change (this is sent before SSDPDBUpdated)
- (void)SSDPDBWillUpdate:(SSDPDB_ObjC *)sender{
	[self lock]; //Protect the rootDevices tree
}

//The SSDPObjCDevices array is updated
- (void)SSDPDBUpdated:(SSDPDB_ObjC *)sender{
	
	/*
	 * Sync [sender SSDPObjCDevices] with rootDevices
	 */

	//Flag all rootdevices as 'notfound'
  for (BasicUPnPDevice *upnpdevice in self.rootDevices) {
		upnpdevice.found = NO;
  }
  
	__block BOOL found;
	
	//flag all devices still in ssdp as 'found'
  for (SSDPDBDevice_ObjC *ssdpdevice in [sender SSDPObjCDevices]) {
		if (ssdpdevice.isroot == FALSE && ssdpdevice.isdevice == TRUE) {// ssdpdevice.isroot == TRUE){ //@TODO; do something with the embedded devices (they have (or can have) another uuid)
                                                                  //Search it in our root devices
			if ([self.rootDevices count] == 0) {
				//add ssdp device to queue, an emty UPnP device is created and schedulled for description
				[self addToDescriptionQueue:ssdpdevice];
			} else {
				found = NO;
        [self.rootDevices enumerateObjectsUsingBlock:^(BasicUPnPDevice *upnpdevice, NSUInteger idx, BOOL *stop){
					if ([ssdpdevice.usn compare:upnpdevice.usn] == NSOrderedSame){
						upnpdevice.found = YES;
						found = YES;
            *stop = YES;
					}
        }];
				if (found == NO){
					//add ssdp device to queue, an emty UPnP device is created and schedulled for description
					[self addToDescriptionQueue:ssdpdevice];
				}
			}
		}
  }
	
	//remove all non found devices
	NSMutableArray *discardedItems = [[NSMutableArray alloc] init];
  for (BasicUPnPDevice *upnpdevice in self.rootDevices) {
		if (upnpdevice.isFound == NO) {
			[discardedItems addObject:upnpdevice];
		}
  }
	
	if ([discardedItems count] > 0){
		//Inform the listeners so they know the rootDevices array might change
    for (NSObject<UPnPDBObserver> *obs in self.mObservers) {
			[obs UPnPDBWillUpdate:self];
    }

		[self.rootDevices removeObjectsInArray:discardedItems];
				
    for (NSObject<UPnPDBObserver> *obs in self.mObservers) {
			[obs UPnPDBUpdated:self];
    }
	}
	[self unlock];

}

- (BasicUPnPDevice *)addToDescriptionQueue:(SSDPDBDevice_ObjC *)ssdpdevice{
	[self lock];

	__block BasicUPnPDevice *upnpdevice;
  
  [self.readyForDescription enumerateObjectsUsingBlock:^(BasicUPnPDevice *localUPnPDevice, NSUInteger idx, BOOL *stop){
		if( [ssdpdevice.usn compare:localUPnPDevice.usn] == NSOrderedSame ){
      upnpdevice = localUPnPDevice;
			*stop = YES;
		}
  }];
  
	
	if (!upnpdevice) {
		//new one, add to queue
		//this is the only place we create BacicUPnP (or derived classes) devices
		upnpdevice = [[[UPnPManager GetInstance] deviceFactory] allocDeviceForSSDPDevice:ssdpdevice];
		[self.readyForDescription addObject:upnpdevice];
		//Signal the description load thread 
	}
	
	[self unlock];
	
	return upnpdevice; //carefull, it is possible upnpevice will be deleted before the caller can use it
}

//return SSDPDBDevice_ObjC[]
- (NSArray *)getSSDPServicesFor:(BasicUPnPDevice *)device {
	[self lock];
	[self.mSSDP lock];
	NSMutableArray *services = [[NSMutableArray alloc] init];
	
  for (SSDPDBDevice_ObjC *ssdpdevice in [self.mSSDP SSDPObjCDevices]) {
		if ([ssdpdevice isservice] == 1) {
			if ([[ssdpdevice uuid] isEqualToString:[device uuid]]) {
				[services addObject:ssdpdevice]; //change string to service
			}
		}
  }
	
	[self.mSSDP unlock];
	[self unlock];
	
	return services;
}

//return SSDPDBDevice_ObjC[] services
- (NSArray *)getSSDPServicesForUUID:(NSString *)uuid {
	[self lock];
	[self.mSSDP lock];
	NSMutableArray *services = [[NSMutableArray alloc] init];
	
  for (SSDPDBDevice_ObjC *ssdpdevice in [self.mSSDP SSDPObjCDevices]) {
		if ([ssdpdevice isservice] == 1) {
			if ([uuid isEqual:[ssdpdevice uuid]]) {
				[services addObject:ssdpdevice]; //change string to service
			}
		}
  }
	
	[self.mSSDP unlock];
	[self unlock];
	
	return services;
}

//Thread
- (void)httpThread:(id)argument{
	while(1){
    @autoreleasepool {
      if([self.readyForDescription count] > 0) {
        BasicUPnPDevice *upnpdevice;
        //NSEnumerator *descenum = [readyForDescription objectEnumerator];
        //while(upnpdevice = [descenum nextObject]){
        while( [self.readyForDescription count] > 0){
          upnpdevice = [self.readyForDescription objectAtIndex:0];
          //fill the upnpdevice with info from the XML
          int ret = [upnpdevice loadDeviceDescriptionFromXML];
          if (ret == 0){
            [self lock];
            
            //Inform the listeners so they know the rootDevices array might change
            for (NSObject<UPnPDBObserver> *obs in self.mObservers) {
              [obs UPnPDBWillUpdate:self];
            }
            
            //This is the only place we add devices to the rootdevices
            [self.rootDevices addObject:upnpdevice];

            for (NSObject<UPnPDBObserver> *obs in self.mObservers) {
              [obs UPnPDBUpdated:self];
            }

            [self unlock];
          }
          [self.readyForDescription removeObjectAtIndex:0];
          
        }				
      }
    }
		sleep(2); //Wait and get signalled @TODO
	}	
}

@end
