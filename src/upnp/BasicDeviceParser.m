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


#import "BasicDeviceParser.h"
#import "BasicUPnPDevice.h"

#define IDEALICONWIDTH 48
#define IDEALICONHEIGHT 48

@interface BasicDeviceParser ()
@property (strong) BasicUPnPDevice *device;
@property (strong) NSMutableArray* friendlyNameStack;
@property (strong) NSMutableArray* udnStack;
@end

@implementation BasicDeviceParser

/****
 © 2002 Contributing Members of the UPnP™ Forum. All Rights Reserved.
 UPnP Basic: Device Template Version 1.01 2
 
 <?xml version="1.0"?>
 <root xmlns="urn:schemas-upnp-org:device-1-0">
	 <specVersion>
		 <major>1</major>
		 <minor>0</minor>
	 </specVersion>
	 <URLBase>base URL for all relative URLs</URLBase>
	 <device>
		 <deviceType>urn:schemas-upnp-org:device:Basic:1</deviceType>
		 <friendlyName>short user-friendly title</friendlyName>
		 <manufacturer>manufacturer name</manufacturer> 
		 <manufacturerURL>URL to manufacturer site</manufacturerURL>
		 <modelDescription>long user-friendly title</modelDescription>
		 <modelName>model name</modelName>
		 <modelNumber>model number</modelNumber>
		 <modelURL>URL to model site</modelURL>
		 <serialNumber>manufacturer's serial number</serialNumber>
		 <UDN>uuid:UUID</UDN>
		 <UPC>Universal Product Code</UPC>
		 <iconList>
			 <icon>
				 <mimetype>image/format</mimetype>
				 <width>horizontal pixels</width>
				 <height>vertical pixels</height>
				 <depth>color depth</depth>
				 <url>URL to icon</url>
			 </icon>
			 XML to declare other icons, if any, go here
		 </iconList>
		 <presentationURL>URL for presentation</presentationURL>
	 </device>
	 ...
	 <deviceList>
		<device>
			....
 </root>
 **/


- (id)initWithUPnPDevice:(BasicUPnPDevice *)upnpdevice {
  self = [super init];

  if (self) {
    _device = upnpdevice;

    _friendlyNameStack = [[NSMutableArray alloc] init];
    _udnStack = [[NSMutableArray alloc] init];

    //Device is the root device
    [self addAsset:@[@"root", @"device"] callfunction:@selector(rootDevice:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    [self addAsset:@[@"root", @"device", @"UDN"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setUdn:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"friendlyName"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setFriendlyName:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"manufacturer"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setManufacturer:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"iconList", @"icon"] callfunction:@selector(iconFound:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    [self addAsset:@[@"root", @"device", @"iconList", @"icon", @"mimetype"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setIconMime:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"iconList", @"icon", @"width"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setIconWidth:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"iconList", @"icon", @"height"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setIconHeight:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"iconList", @"icon", @"depth"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setIconDepth:) setStringValueObject:self];
    [self addAsset:@[@"root", @"device", @"iconList", @"icon", @"url"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setIconURL:) setStringValueObject:self];

    [self addAsset:@[@"root", @"URLBase"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setBaseURLString:) setStringValueObject:self.device];

    //Device is an embedded device (embedded devices can include embedded devices)
    [self addAsset:@[@"*", @"device", @"deviceList", @"device"] callfunction:@selector(embeddedDevice:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    [self addAsset:@[@"*", @"device", @"deviceList", @"device", @"UDN"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setUdn:) setStringValueObject:self];
    [self addAsset:@[@"*", @"device", @"deviceList", @"device", @"friendlyName"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setFriendlyName:) setStringValueObject:self];
    [self addAsset:@[@"*", @"device", @"deviceList", @"device", @"manufacturer"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setManufacturer:) setStringValueObject:self];
  }

  return self;
}

/**
 * XML
 */
- (int)parse {
	int ret=0;

	NSURL *descurl = [NSURL URLWithString:self.device.xmlLocation];
    
	ret = [super parseFromURL:descurl];
	
	//Base URL
	if (![self.device baseURLString]) {
		//Create one based on [device xmlLocation] 
		NSURL *loc = [NSURL URLWithString:[self.device xmlLocation]];
		if (loc) {
//			NSURL *base = [loc host];
			[self.device setBaseURL:loc];
		}		
	} else {
		NSURL *loc = [NSURL URLWithString:[self.device baseURLString]];
		if (loc) {
			[self.device setBaseURL:loc];
		}				
	}
	
	//load icon if any
	if (ret == 0 && self.iconURL) {
		NSURL *u = [NSURL URLWithString:self.iconURL relativeToURL:self.device.baseURL];
		NSData *imageData = [NSData dataWithContentsOfURL:u];
		UIImage *i = [UIImage imageWithData:imageData];
		[self.device setSmallIcon:i];
	}
	
	return ret;
}

//Parse Icon stuff, if any
- (void)iconFound:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
		[self setIconURL:nil];
		[self setIconWidth:nil];
		[self setIconHeight:nil];
		[self setIconMime:nil];
	} else {
		if (self.iconMime &&
       ([self.iconMime rangeOfString:@"jpeg"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"jpg"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"tiff"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"tif"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"gif"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"png"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"bmp"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"BMPf"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"ico"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"cur"].location != NSNotFound ||
        [self.iconMime rangeOfString:@"xbm"].location != NSNotFound)) {
			//we can handle this
			if ([self.device smallIconWidth] == 0 || [self.device smallIconHeight] == 0) {
				self.device.smallIconWidth = [self.iconWidth intValue];
				self.device.smallIconHeight = [self.iconHeight intValue];
				[self.device setSmallIconURL:self.iconURL];			
			} else {
				if ((abs(IDEALICONHEIGHT - [self.device smallIconHeight]) > abs(IDEALICONHEIGHT - [self.iconHeight intValue])) ||
				    (abs(IDEALICONHEIGHT - [self.device smallIconHeight]) - 10 > abs(IDEALICONHEIGHT - [self.iconHeight intValue]) && [self.iconDepth intValue] > [self.device smallIconDepth])) {
					self.device.smallIconWidth = [self.iconWidth intValue];
					self.device.smallIconHeight = [self.iconHeight intValue];
					self.device.smallIconDepth = [self.iconDepth intValue];
					[self.device setSmallIconURL:[NSString stringWithString:self.iconURL] ];			
				}
			}
		}
	}
}

- (void)rootDevice:(NSString *)startStop {
	if (![startStop isEqualToString:@"ElementStart"]){
		//Was this the device we are looking for ?
		if ([self.udn isEqualToString:[self.device uuid]]) {
			//this is our device, copy the collected info to the [device] instance
			[self.device setUdn:self.udn];
			[self.device setFriendlyName:self.friendlyName];
      [self.device setManufacturer:self.manufacturer];
		}
	}
}

- (void)embeddedDevice:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
    [self.friendlyNameStack addObject:self.friendlyName];
    [self.udnStack addObject:self.udn];
	} else {
		//Was this the device we are looking for ?
		if (self.udn) {//@todo check this
			if ([self.udn isEqualToString:[self.device uuid]]) {
				//this is our device, copy the collected info to the [device] instance
				[self.device setFriendlyName:self.friendlyName];
				[self.device setUdn:self.udn];
        [self.device setManufacturer:self.manufacturer];
			}
		}
    [self setUdn:[self.udnStack lastObject]];
    [self setFriendlyName:[self.friendlyNameStack lastObject]];
    [self.friendlyNameStack removeLastObject];
    [self.udnStack removeLastObject];
	}
}

@end
