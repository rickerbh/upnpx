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

#import "BasicServiceParser.h"
#import "BasicUPnPService.h"
#import "StateVariableRange.h"
#import "StateVariableList.h"
#import "StateVariable.h"
#import "SSDPDB_ObjC.h"

@interface BasicServiceParser ()
@property (readwrite, strong) BasicUPnPService *service;
@property (assign) BOOL mCollectingStateVar;
@property (assign) StateVariableType mCachedType;
@property (strong) StateVariableList *mStatevarListCache;
@property (strong) StateVariableRange *mStatevarRangeCache;
@property (strong) StateVariable *mStatevarCache;
@end

@implementation BasicServiceParser

- (id)initWithUPnPService:(BasicUPnPService *)upnpservice {
  self = [super init];
  if (self) {
    _service = upnpservice;
    _mStatevarCache = [[StateVariable alloc] init];
    _mStatevarRangeCache = [[StateVariableRange alloc] init];
    _mStatevarListCache = [[StateVariableList alloc] init];
    _mCollectingStateVar = NO;
  }
  return self;
}

- (int)parse{
	int ret;
	
	/*
	 * 1. First parse the Device Description XML
	 */
	[self clearAllAssets];
	[self addAsset:@[@"root", @"URLBase"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setBaseURLString:) setStringValueObject:self.service];
	[self addAsset:@[@"*", @"device", @"serviceList", @"service", @"serviceType"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setServiceType:) setStringValueObject:self];
	[self addAsset:@[@"*", @"device", @"serviceList", @"service", @"SCPDURL"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDescriptionURL:) setStringValueObject:self];
	[self addAsset:@[@"*", @"device", @"serviceList", @"service", @"controlURL"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setControlURL:) setStringValueObject:self];
	[self addAsset:@[@"*", @"device", @"serviceList", @"service", @"eventSubURL"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setEventURL:) setStringValueObject:self];
	[self addAsset:@[@"*", @"device", @"serviceList", @"service"] callfunction:@selector(serviceTag:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];

	NSURL *descurl = [NSURL URLWithString:[[self.service ssdpdevice] location]];
	ret = [super parseFromURL:descurl];
	
	if(ret < 0){
		return ret;
	}

	//Do we have a Base URL, if not create one
	//Base URL
	if (![self.service baseURLString]) {
		//Create one based on [device xmlLocation] 
		NSURL *loc = [NSURL URLWithString:[[self.service ssdpdevice] location]];
		if (loc) {
			[self.service setBaseURL:loc];
		}		
	} else {
		NSURL *loc = [NSURL URLWithString:[self.service baseURLString]];
		if (loc) {
			[self.service setBaseURL:loc];
		}				
	}

	/*
	 * 2. Parse the Service Description XML ([service descriptionURL])
	 */
	[self clearAllAssets];
	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable"] callfunction:@selector(stateVariable:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
	//fill our cache
	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"name"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setName:) setStringValueObject:self.mStatevarCache];
	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"dataType"] callfunction:nil functionObject:self setStringValueFunction:@selector(setDataTypeString:) setStringValueObject:self.mStatevarCache];

	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueRange"] callfunction:@selector(allowedValueRange:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueRange", @"minimum"] callfunction:nil functionObject:self setStringValueFunction:@selector(setMinWithString:) setStringValueObject:self.mStatevarRangeCache];
	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueRange", @"maximum"] callfunction:nil functionObject:self setStringValueFunction:@selector(setMaxWithString:) setStringValueObject:self.mStatevarRangeCache];

	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueList"] callfunction:@selector(allowedValueList:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
	[self addAsset:@[@"scpd", @"serviceStateTable", @"stateVariable", @"allowedValueList", @"allowedValue"] callfunction:nil functionObject:self setStringValueFunction:@selector(setAllowedValue:) setStringValueObject:self];

	NSURL *serviceDescUrl = [NSURL URLWithString:[self.service descriptionURL] relativeToURL:[self.service baseURL]];
	ret = [super parseFromURL:serviceDescUrl];

	return ret;
}

- (void)serviceTag:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStop"]) {
		//Is our cached servicetype the same as the one in the ssdp description, if so we can initialize the upnp service object
		if ([self.serviceType compare:[[self.service ssdpdevice] urn]] == NSOrderedSame) {
			//found, copy
			[self.service setServiceType:self.serviceType];
			[self.service setDescriptionURL:self.descriptionURL];
			[self.service setControlURL:self.controlURL];
			[self.service setEventURL:self.eventURL];
		}
	}
}

- (void)stateVariable:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
		self.mCollectingStateVar = YES;
		//clear our cache
		self.mCachedType = StateVariable_Type_Simple;
		[self.mStatevarCache empty];
		[self.mStatevarListCache empty];
		[self.mStatevarRangeCache empty];
	} else {
		self.mCollectingStateVar = NO;
		//add to the BasicUPnPService NSMutableDictionary *stateVariables; 
		switch(self.mCachedType){
			case StateVariable_Type_Simple:
				{
					StateVariable *new = [[StateVariable alloc] init]; 
					[new copyFromStateVariable:self.mStatevarCache];
					[[self.service stateVariables] setObject:new forKey:[new name]];
				}
				break;
			case StateVariable_Type_List:
				{	
					StateVariableList *new = [[StateVariableList alloc] init];
					[new copyFromStateVariableList:self.mStatevarListCache];
					[[self.service stateVariables] setObject:new forKey:[new name]];
				}
				break;
			case StateVariable_Type_Range:
				{
					StateVariableRange *new = [[StateVariableRange alloc] init];
					[new copyFromStateVariableRange:self.mStatevarRangeCache];
					[[self.service stateVariables] setObject:new forKey:[new name]];
				}
				break;
            case StateVariable_Type_Unknown:
                NSLog(@"Error: State is unknown!");
                break;
		}
	}
}

- (void)allowedValueRange:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
		//Copy from mStatevarCache 
		[self.mStatevarRangeCache copyFromStateVariable:self.mStatevarCache];
		self.mCachedType = StateVariable_Type_Range;
	} else {
		//Stop
	}
}

- (void)allowedValueList:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
		//Copy from mStatevarCache 
		[self.mStatevarListCache copyFromStateVariable:self.mStatevarCache];
		self.mCachedType = StateVariable_Type_List;
	} else {
		//Stop
	}
}

- (void)setAllowedValue:(NSString *)value {
	[[self.mStatevarListCache list] addObject:value]; 
}

@end
