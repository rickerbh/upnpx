//
//  UPnPEventHTTPResponse.m
//  upnpx
//
//  Created by Hamish Rickerby on 17/05/13.
//  Copyright (c) 2013 Bruno Keymolen. All rights reserved.
//

#import "UPnPEventHTTPResponse.h"

@implementation UPnPEventHTTPResponse

- (UInt64)contentLength {
  return 0;
}

- (UInt64)offset {
  return 0;
}

- (void)setOffset:(UInt64)offset {
  // No implementation
}

- (NSData *)readDataOfLength:(NSUInteger)length {
  return [NSData data];
}

- (BOOL)isDone {
  return YES;
}

- (NSInteger)status {
  return 200;
}

@end
