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

#import "WANConnection2Device.h"
#import "BasicUPnPService.h"
#import "SoapActionsWANPOTSLinkConfig1.h"
#import "SoapActionsWANDSLLinkConfig1.h"
#import "SoapActionsWANCableLinkConfig1.h"
#import "SoapActionsWANEthernetLinkConfig1.h"
#import "SoapActionsWANPPPConnection1.h"
#import "SoapActionsWANIPConnection2.h"
#import "SoapActionsWANIPv6FirewallControl1.h"

@interface WANConnection2Device ()
@property (strong) SoapActionsWANPOTSLinkConfig1 *mPOTSLinkConfig;
@property (strong) SoapActionsWANDSLLinkConfig1 *mDSLLinkConfig;
@property (strong) SoapActionsWANCableLinkConfig1 *mCableLinkConfig;
@property (strong) SoapActionsWANEthernetLinkConfig1 *mEthernetLinkConfig;
@property (strong) SoapActionsWANPPPConnection1 *mPPPConnection;
@property (strong) SoapActionsWANIPConnection2 *mIPConnection;
@property (strong) SoapActionsWANIPv6FirewallControl1 *mIPv6FirewallControl;
@end

@implementation WANConnection2Device

- (SoapActionsWANPOTSLinkConfig1 *)potsLinkConfig {
	if (!self.mPOTSLinkConfig) {
		self.mPOTSLinkConfig = (SoapActionsWANPOTSLinkConfig1 *)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANPOTSLinkConfig:1"] soap];
	}
	return self.mPOTSLinkConfig;
}

- (SoapActionsWANDSLLinkConfig1 *)dslLinkConfig {
	if (!self.mDSLLinkConfig) {
		self.mDSLLinkConfig = (SoapActionsWANDSLLinkConfig1 *)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANDSLLinkConfig:1"] soap];
	}
	return self.mDSLLinkConfig;
}

- (SoapActionsWANCableLinkConfig1 *)cableLinkConfig {
	if (!self.mCableLinkConfig) {
		self.mCableLinkConfig = (SoapActionsWANCableLinkConfig1 *)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANCableLinkConfig:1"] soap];
	}
	return self.mCableLinkConfig;
}

- (SoapActionsWANEthernetLinkConfig1 *)ethernetLinkConfig {
	if (!self.mEthernetLinkConfig) {
		self.mEthernetLinkConfig = (SoapActionsWANEthernetLinkConfig1 *)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANEthernetLinkConfig:1"] soap];
	}
	return self.mEthernetLinkConfig;
}

- (SoapActionsWANPPPConnection1 *)pppConnection {
	if (!self.mPPPConnection) {
		self.mPPPConnection = (SoapActionsWANPPPConnection1 *)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANPPPConnection:1"] soap];
	}
	return self.mPPPConnection;
}

- (SoapActionsWANIPConnection2 *)ipConnection {
	if (!self.mIPConnection) {
		self.mIPConnection = (SoapActionsWANIPConnection2*)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANIPConnection:2"] soap];
	}
	return self.mIPConnection;
}

- (SoapActionsWANIPv6FirewallControl1 *)ipv6FirewallControl {
	if (!self.mIPv6FirewallControl) {
		self.mIPv6FirewallControl = (SoapActionsWANIPv6FirewallControl1 *)[[self getServiceForType:@"urn:schemas-upnp-org:service:WANIPv6FirewallControl:1"] soap];
	}
	return self.mIPv6FirewallControl;
}

- (BasicUPnPService *)potsLinkConfigService {
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANPOTSLinkConfig:1"];
}

- (BasicUPnPService *)dslLinkConfigService {
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANDSLLinkConfig:1"];
}

- (BasicUPnPService *)cableLinkConfigService {
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANCableLinkConfig:1"];
}

- (BasicUPnPService *)ethernetLinkConfigService {
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANEthernetLinkConfig:1"];
}

- (BasicUPnPService *)pppConnectionService {
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANPPPConnection:1"];
}

- (BasicUPnPService *)ipConnectionService{
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANIPConnection:2"];
}

- (BasicUPnPService*)ipv6FirewallControlService {
	return [self getServiceForType:@"urn:schemas-upnp-org:service:WANIPv6FirewallControl:1"];
}

@end
