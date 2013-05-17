//
//  UPnPEventHTTPConnection.m
//  upnpx
//
//  Created by Hamish Rickerby on 17/05/13.
//  Copyright (c) 2013 Bruno Keymolen. All rights reserved.
//

#import "UPnPEventHTTPConnection.h"
#import "EventServer.h"
#import "HTTPMessage.h"
#import "UPnPEventHTTPResponse.h"

@interface UPnPEventHTTPConnection ()

@end

@implementation UPnPEventHTTPConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
  EventServer *server = (EventServer *)[config server];
  NSObject<EventServerObserver> *observer = [[server getObservers] lastObject];
  if ([observer canProcessMethod:(EventServer *)[config server] requestMethod:method]) {
    return YES;
  }
  return NO;
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path {
  if ([method caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame) {
    return YES;
  }
  return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
  EventServer *server = (EventServer *)[config server];
  NSObject<EventServerObserver> *observer = [[server getObservers] lastObject];
  [observer request:server
             method:[request method]
               path:[[request url] path]
            version:[request version]
            headers:[request allHeaderFields]
               body:[request body]];
  return [[UPnPEventHTTPResponse alloc] init];
}

- (void)processBodyData:(NSData *)postDataChunk {
  [request setBody:postDataChunk];
}

@end
