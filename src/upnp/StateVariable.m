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


#import "StateVariable.h"

@interface StateVariable ()
@property (readwrite, assign) StateVariableDataType dataType;
@end

@implementation StateVariable

- (id)init {
  self = [super init];
  if (self) {
    _variableType = StateVariable_Type_Simple;
    [self empty];
  }
  return self;
}

- (void)empty {
  [self setDataTypeString:nil];
    /* IcY: "dataType:" looks like a goto label but is never used
     * should it be dataType = StateVariable_DataType_Unknown
     */
	//dataType: StateVariable_DataType_Unknown;
}

- (void)setDataTypeString:(NSString *)value{
	_dataTypeString = [value copy];

	if ([self.dataTypeString isEqualToString:@"ui1"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"ui2"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"ui4"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"i1"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"i2"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"i4"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"int"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"r4"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"r8"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"number"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"fixed14.4"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"float"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"boolean"]) {
		self.dataType = StateVariable_DataType_Integer;
	} else if ([self.dataTypeString isEqualToString:@"char"]) {
		self.dataType = StateVariable_DataType_String;
	} else if ([self.dataTypeString isEqualToString:@"string"]) {
		self.dataType = StateVariable_DataType_String;
	} else {
		self.dataType = StateVariable_DataType_Unknown;
	}//complete the list
		
}
		
- (void)copyFromStateVariable:(StateVariable *)stateVar {
	[self setName:[NSString stringWithString:[stateVar name]]];
	self.dataType = [stateVar dataType];
	[self setDataTypeString:[NSString stringWithString:[stateVar dataTypeString]]];
}

@end
