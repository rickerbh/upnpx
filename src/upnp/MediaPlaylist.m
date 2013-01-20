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

/*
 * States:
 * Stopped <-> Playing
 *
 */

#import "MediaPlaylist.h"
#import "MediaServerBasicObjectParser.h"
#import "CocoaTools.h"
#import "MediaServer1Device.h"
//#import "MediaRenderer1Device.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1ItemObject.h"
#import "SoapActionsContentDirectory1.h"

@interface MediaPlaylist()
@property (readwrite, strong) NSMutableArray *playList; //MediaServer1ItemObject[]
@property (readwrite, assign) int currentTrack;
@property (readwrite, strong) MediaServer1Device* mediaServer;
// @property (readwrite, strong) MediaRenderer1Device* mediaRenderer;
@property (readwrite, strong) MediaServer1ContainerObject* container;
@property (readwrite, strong) NSMutableArray *mObservers; //MediaPlaylistObserver[]
@property (readwrite, assign) MediaPlaylistState state;

- (int)changeState:(MediaPlaylistState)newState;

@end

@implementation MediaPlaylist

- (id)init {
  self = [super init];
  if (self) {
    _state = MediaPlaylistState_NotInitialized;
    _mObservers = [[NSMutableArray alloc] init];
    _currentTrack = 0;
    _playList = [[NSMutableArray alloc] init];
	}
	return self;
}

- (int)addObserver:(NSObject<MediaPlaylistObserver> *)obs {
	int ret = 0;
	
	[self.mObservers addObject:obs];
	ret = [self.mObservers count];
	
	return ret;	
}


- (int)removeObserver:(NSObject<MediaPlaylistObserver> *)obs {
	int ret = 0;
	
	[self.mObservers removeObject:obs];
	ret = [self.mObservers count];
	
	return ret;	
}


- (int)loadWithMediaServer:(MediaServer1Device *)server forContainer:(MediaServer1ContainerObject *)selectedContainer {
	int ret = 0;
	
	//Sanity
	if(server == nil || selectedContainer == nil){
		return -1;
	}
	
	//Re-init
	[self.playList removeAllObjects];
	
	self.mediaServer = server;
	
	self.container = selectedContainer;
	
	//Browse the container & create the objects
	NSMutableString *outResult = [[NSMutableString alloc] init];
	NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
	NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
	NSMutableString *outUpdateID = [[NSMutableString alloc] init];
	
	
	ret = [[server contentDirectory] BrowseWithObjectID:[selectedContainer objectID]
                                           BrowseFlag:@"BrowseDirectChildren"
                                               Filter:@"*"
                                        StartingIndex:@"0"
                                       RequestedCount:@"0"
                                         SortCriteria:@"+dc:title"
                                            OutResult:outResult
                                    OutNumberReturned:outNumberReturned
                                      OutTotalMatches:outTotalMatches
                                          OutUpdateID:outUpdateID];
	if (ret == 0) {
    //Fill mediaObjects
    //Parse the return DIDL and store all entries as objects in the 'mediaObjects' array
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding]; // NSASCIIStringEncoding
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:self.playList itemsOnly:YES];
    [parser parseFromData:didl];
	}
	
	self.currentTrack = 0;
	self.state = MediaPlaylistState_Stopped;
	
	return ret;
}


- (int)setTrackByNumber:(int)track {
	if ([self.playList count] > track) {
		self.currentTrack = track;
	} else {
		return -1;
	}
	return self.currentTrack;
}

- (int)setTrackByID:(NSString *)objectID {
	//Set the current track
  [self.playList enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(MediaServer1ItemObject* lobj, NSUInteger idx, BOOL *stop){
    if ([[lobj objectID] isEqualToString:objectID]) {
      self.currentTrack = idx;
      *stop = YES;
    }
  }];
	
	return self.currentTrack;
}

- (int)nextTrack {
	if (self.state == MediaPlaylistState_Playing && [self.playList count] > self.currentTrack + 1) {
		self.currentTrack = self.currentTrack + 1;
	} else {
		return -1;
	}
	return self.currentTrack;
}

- (int)prevTrack{
	if (self.state == MediaPlaylistState_Playing && [self.playList count] > self.currentTrack - 1) {
		if (self.currentTrack > 0) {
			self.currentTrack = self.currentTrack - 1;
		}
	} else {
		return -1;
	}
	return self.currentTrack;	
}

- (int)stop {
	return [self changeState:MediaPlaylistState_Stopped];
}

- (int)play {
	return [self changeState:MediaPlaylistState_Playing];
}

- (int)changeState:(MediaPlaylistState)newState {
	int ret = 0;
	
	MediaPlaylistState oldState = self.state;
	
	switch(self.state){
		//Stop - > Play
		case MediaPlaylistState_Stopped:
			if (newState == MediaPlaylistState_Playing) {
				self.state = newState;
			}				
			break;
		//Play -> Stop
		case MediaPlaylistState_Playing:
			if (newState == MediaPlaylistState_Stopped) {
				self.state = newState;
			}				
			break;
		case MediaPlaylistState_NotInitialized:
		default:
			ret = -1;
			break;
	}

	if (oldState != self.state) {
    for (NSObject<MediaPlaylistObserver> *obs in self.mObservers) {
			[obs StateChanged:self.state];
    }
	}
	return ret;
}
	
- (MediaServer1ItemObject *)GetCurrentTrackItem {
	MediaServer1ItemObject *ret  = nil;
	
	if([self.playList count] > self.currentTrack) {
		ret = [self.playList objectAtIndex:self.currentTrack];
	}
  
	return ret;
}

@end
