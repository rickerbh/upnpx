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


#import "UPnPEvents.h"

@implementation ObserverEntry
@end

@interface UPnPEvents ()
@property (strong) NSMutableDictionary *mEventSubscribers; //uuid, observer
@property (strong) BasicHTTPServer_ObjC *server;
@property (strong) UPnPEventParser *parser;
@property (strong) NSRecursiveLock *mMutex;
@property (strong) NSTimer *mTimeoutTimer;
@end

@implementation UPnPEvents

- (id)init {
  self = [super init];
  if (self) {
    _mMutex = [[NSRecursiveLock alloc] init];
    _mEventSubscribers = [[NSMutableDictionary alloc] init];
    _parser =[[UPnPEventParser alloc] init];

    _server = [[BasicHTTPServer_ObjC alloc] init];
    [_server start];
    [_server addObserver:self];
	}
	return self;
}

- (void)dealloc{
  [self.server stop];
}

- (void)start {
  //Start the subscription timer
  self.mTimeoutTimer = [NSTimer timerWithTimeInterval:60.0 target:self selector:@selector(ManageSubscriptionTimeouts:) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:self.mTimeoutTimer forMode:NSDefaultRunLoopMode];
}

- (void)stop {
  //Stop the subscription timer
  [self.mTimeoutTimer invalidate];
}

- (NSString *)Subscribe:(NSObject<UPnPEvents_Observer> *)subscriber {
	//Send Event subscription over HTTP
	NSString *retUUID = nil;	
	NSString *timeOut = nil;	
	
	//Construct the HTML SUBSCRIBE 
	NSMutableURLRequest* urlRequest=[NSMutableURLRequest requestWithURL:[subscriber GetUPnPEventURL]
															cachePolicy:NSURLRequestReloadIgnoringCacheData
														timeoutInterval:15.0];	
	
	NSString *callBack = [NSString stringWithFormat:@"<http://%@:%d/Event>", [self.server getIPAddress], [self.server getPort]];
	
	[urlRequest setValue:@"iOS UPnP/1.1 UPNPX/1.2.4" forHTTPHeaderField:@"USER-AGENT"];
	[urlRequest setValue:callBack forHTTPHeaderField:@"CALLBACK"];
	[urlRequest setValue:@"upnp:event" forHTTPHeaderField:@"NT"];
	[urlRequest setValue:@"Second-1800" forHTTPHeaderField:@"TIMEOUT"];
	
	//SUBSCRIBE (Synchronous)
	[urlRequest setHTTPMethod:@"SUBSCRIBE"];	
	
	NSHTTPURLResponse *urlResponse;
	
	[NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:nil];
  
  if ([urlResponse statusCode] == 200) {
    NSDictionary *allReturnedHeaders = [urlResponse allHeaderFields];
    for (NSString* key in allReturnedHeaders) {
      if ([key caseInsensitiveCompare:@"SID"] == NSOrderedSame) {
        retUUID = [NSString stringWithString:[allReturnedHeaders objectForKey:key]];
      }
      if ([key caseInsensitiveCompare:@"TIMEOUT"] == NSOrderedSame) {
        timeOut = [NSString stringWithString:[allReturnedHeaders objectForKey:key]];
      }
		}		
	}
	
	//Add to the subscription Dictionary
	[self.mMutex lock];
	if (retUUID) {
    ObserverEntry *en = [[ObserverEntry alloc] init];
    en.observer = subscriber;
    en.subscriptiontime = [[NSDate date]timeIntervalSince1970];
    
    NSRange r = [timeOut rangeOfString:@"Second-"];
    if (r.length > 0) {
      en.timeout = [[timeOut substringFromIndex:r.location+r.length] intValue];
      if (en.timeout < 300) {
        en.timeout = 300;
      }
    }
    
    [self.mEventSubscribers setObject:en forKey:retUUID];
    
	} else {
		NSLog(@"Cannot subscribe for events, server return code : %ld", (long)[urlResponse statusCode]);
	}

	[self.mMutex unlock];
	
	return retUUID;
}

- (void)UnSubscribe:(NSString *)uuid {
	[self.mMutex lock];
	[self.mEventSubscribers removeObjectForKey:uuid];
	[self.mMutex unlock];
}


/*
 * Incomming HTTP events
 * BasicHTTPServer_ObjC_Observer
 */
- (BOOL)canProcessMethod:(BasicHTTPServer_ObjC *)sender requestMethod:(NSString *)method {
  return [method caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame;
}

//Request / Response is always synchronized 
- (BOOL)request:(BasicHTTPServer_ObjC *)sender method:(NSString *)method path:(NSString *)path version:(NSString *)version headers:(NSDictionary *)headers body:(NSData *)body {
	BOOL ret = NO;
	
	NSString *uuid = [headers objectForKey:@"SID"];
	if(uuid == nil){
		return NO;
	}
	
	//Parse the return
	[self.parser reinit];
	
	
	//Check if the body ends with '0' zero's, MediaTomb does this and the parser does not like it, so cut 0's
	char zbuf[10];
	int cut = 0;
	if ([body length] > 10) {
		NSRange r;
		r.length = 10;
		r.location = [body length] - 10;
		[body getBytes:zbuf range:r];
		int x = 9;
		while (zbuf[x] == 0) {
			x--;
			if (x < 0) {
				break;
			}
		}
		cut = 9 - x;
	}
	
	int parserret;
	if (cut > 0) {
		NSData *tmpbody = [[NSData alloc] initWithBytes:[body bytes] length:[body length] - cut];
		parserret = [self.parser parseFromData:tmpbody];
	} else {
		parserret = [self.parser parseFromData:body];
	}
	
	if (parserret == 0) {
		//ok
		[self.mMutex lock];
    NSObject<UPnPEvents_Observer> *thisObserver = nil;
    ObserverEntry *entry = [self.mEventSubscribers objectForKey:uuid];
    if (entry != nil) {
      thisObserver = entry.observer;
    }
    
		[self.mMutex unlock];
		if (thisObserver != nil) {
      [thisObserver UPnPEvent:[self.parser events]];
    }
	}
		
	return ret;
}

//Request / Response is always synchronized 
- (BOOL)response:(BasicHTTPServer_ObjC *)sender returncode:(int *)returncode headers:(NSMutableDictionary *)retHeaders body:(NSMutableData *)retBody {
	BOOL ret = YES;
	
	[retBody setLength:0];
	[retHeaders removeAllObjects];
	*returncode = 200;

	return ret;
}


- (void)ManageSubscriptionTimeouts:(NSTimer *)timer{
  //NSLog(@"ManageSubscriptionTimeouts");
  double tm = [[NSDate date]timeIntervalSince1970];
  ObserverEntry *entry = nil;
  NSMutableArray *remove = [[NSMutableArray alloc] init];
  NSMutableArray *notify = [[NSMutableArray alloc] init];
  [self.mMutex lock];
  NSString *uuid;
  for (uuid in self.mEventSubscribers) {
    entry = [self.mEventSubscribers objectForKey:uuid];
    if (tm - entry.subscriptiontime >= (double)(entry.timeout)) {
      [remove addObject:uuid];
    } else if (tm - entry.subscriptiontime > (double)(entry.timeout/2)) {
      [notify addObject:uuid];
    }
  }
  [self.mMutex unlock];
    
  //Send Notifications
  for (uuid in notify) {
    [self.mMutex lock];
    entry = [self.mEventSubscribers objectForKey:uuid];
    [self.mMutex unlock];
    if (entry) {
      [[entry observer] SubscriptionTimerExpiresIn:(int)(tm - entry.subscriptiontime) timeoutSubscription:entry.timeout timeSubscription:entry.subscriptiontime];
    }
  }

  //Remove
  for (uuid in remove) {
    [self.mMutex lock];
    [self.mEventSubscribers removeObjectForKey:uuid];
    [self.mMutex unlock];
  }
}

@end
