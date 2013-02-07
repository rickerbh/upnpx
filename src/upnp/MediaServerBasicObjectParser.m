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

#import "MediaServerBasicObjectParser.h"
#import "MediaServer1BasicObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1VideoItemObject.h"
#import "MediaServer1MovieVideoItemObject.h"
#import "CocoaTools.h"
#import "OrderedDictionary.h"
#import "MediaServer1ItemRes.h"

// object.item.audioItem.musicTrack

/*
  <container id="7" parentID="0" restricted="1" childCount="6">
    <dc:title>Audio</dc:title>
    <upnp:class>object.container</upnp:class>
  </container>
 
  <item id="27934" parentID="27933" restricted="0">
    <dc:title>01-Mis-Shapes.mp3</dc:title>
    <upnp:class>object.item.audioItem.musicTrack</upnp:class>
    <upnp:artist>Pulp</upnp:artist>
    <upnp:album>Different Class</upnp:album>
    <dc:date>1995-01-01</dc:date>
    <upnp:genre>Rock</upnp:genre>
    <upnp:originalTrackNumber>1</upnp:originalTrackNumber>
    <res protocolInfo="http-get:*:audio/mpeg:*" sampleFrequency="48000" nrAudioChannels="2">http://192.168.123.15:49152/content/media/object_id=27934&amp;res_id=0&amp;ext=.mp3</res>
  </item>
*/
/* From XBMC
  <item id="musicdb://1/17/-1/-1/989.mp3?genreid=17" parentID="musicdb://1/17/-1/-1/?genreid=17" refID="musicdb://4/989.mp3" restricted="1">
    <dc:title>Breathe</dc:title>
    <dc:creator>Alexi Murdoch</dc:creator>
    <upnp:artist>Alexi Murdoch</upnp:artist>
    <upnp:artist role="Performer">Alexi Murdoch</upnp:artist>
    <upnp:artist role="AlbumArtist">Alexi Murdoch</upnp:artist>
    <upnp:album>Time Without Consequence</upnp:album>
    <upnp:genre>Alternative</upnp:genre>
    <upnp:albumArtURI dlna:profileID="JPEG_TN">http://192.168.1.10:1776/%25/A5F407852DD2C0476D1B9131684FA50E/01%20All%20My%20Days.mp3</upnp:albumArtURI>
    <upnp:originalTrackNumber>2</upnp:originalTrackNumber>
    <upnp:lastPlaybackTime>1969-12-31</upnp:lastPlaybackTime>
    <upnp:playbackCount>0</upnp:playbackCount>
    <res duration="0:04:19.000" protocolInfo="http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01500000000000000000000000000000">http://192.168.1.10:1776/%25/E572559EE1791A3D8A79193DA3E164D0/Alexi%20Murdoch-%20Breathe.mp3</res>
    <upnp:class>object.item.audioItem.musicTrack</upnp:class>
  </item>
*/

// object.item.videoItem.movie

/* From XBMC
  <item id="videodb://1/2/146" parentID="" restricted="1">
    <dc:title>You Can Count on Me</dc:title>
    <dc:creator>Unknown</dc:creator>
    <dc:date>2000-01-01</dc:date>
    <upnp:author>Kenneth Lonergan</upnp:author>
    <upnp:director>Kenneth Lonergan</upnp:director>
    <upnp:genre>Drama</upnp:genre>
    <upnp:genre>Romance</upnp:genre>
    <upnp:genre>Indie</upnp:genre>
    <dc:description>A single mother&apos;s life is thrown into turmoil after her struggling, rarely-seen younger brother returns to town.</dc:description>
    <upnp:longDescription>A single mother&apos;s life is thrown into turmoil after her struggling, rarely-seen younger brother returns to town.</upnp:longDescription>
    <upnp:rating>Rated </upnp:rating>
    <upnp:lastPlaybackTime>1969-12-31</upnp:lastPlaybackTime>
    <upnp:playbackCount>0</upnp:playbackCount><res duration="1:51:00.000" protocolInfo="http-get:*:video/mp4:DLNA.ORG_PN=MPEG4_P2_SP_AAC;DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01500000000000000000000000000000">http://192.168.1.10:1776/%25/47B5FF7802E8417D713628400F19349C/You%20Can%20Count%20On%20Me.m4v</res>
    <upnp:class>object.item.videoItem.movie</upnp:class>
  </item>
*/

@interface MediaServerBasicObjectParser ()
@property (strong) NSMutableArray *mediaObjects;
@property (strong) NSMutableDictionary *uriCollection;  //key: NSString* protocolinfo -> value:NSString* uri
@property (strong) NSMutableArray *resources;
@property (readwrite, strong) NSString *uri;
@end

@implementation MediaServerBasicObjectParser
/**
 * All Objects; Items + Containers
 */
-(id)initWithMediaObjectArray:(NSMutableArray*)mediaObjectsArray{
	return [self initWithMediaObjectArray:mediaObjectsArray itemsOnly:NO];
}

- (id)initWithMediaObjectArray:(NSMutableArray *)mediaObjectsArray itemsOnly:(BOOL)onlyItems {
  self = [super initWithNamespaceSupport:YES];
  if (self) {
    _uriCollection = [[OrderedDictionary alloc] init];
    _resources = [[NSMutableArray alloc] init];
        
    _mediaObjects = mediaObjectsArray;

    //Container
    if (!onlyItems) {
      [self addAsset:@[@"DIDL-Lite", @"container"] callfunction:@selector(container:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
      [self addAsset:@[@"DIDL-Lite", @"container", @"title"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaTitle:) setStringValueObject:self];
      [self addAsset:@[@"DIDL-Lite", @"container", @"class"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaClass:) setStringValueObject:self];
      [self addAsset:@[@"DIDL-Lite", @"container", @"albumArtURI"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAlbumArt:) setStringValueObject:self];
    }
    
    //Item
    [self addAsset:@[@"DIDL-Lite", @"item"] callfunction:@selector(item:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
    [self addAsset:@[@"DIDL-Lite", @"item", @"title"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaTitle:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"class"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaClass:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"artist"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setArtist:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"album"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAlbum:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"date"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDate:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"genre"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setGenre:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"originalTrackNumber"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setOriginalTrackNumber:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"albumArtURI"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAlbumArt:) setStringValueObject:self];

    [self addAsset:@[@"DIDL-Lite", @"item", @"res"] callfunction:@selector(res:) functionObject:self setStringValueFunction:@selector(setUri:) setStringValueObject:self];
    
    // Video Item
    [self addAsset:@[@"DIDL-Lite", @"item", @"longDescription"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setLongDescription:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"producer"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setProducer:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"rating"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setRating:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"actor"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setActor:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"director"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDirector:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"description"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMovieDescription:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"publisher"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setPublisher:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"language"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setLanguage:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"relation"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setRelation:) setStringValueObject:self];

    // Movie Item
    [self addAsset:@[@"DIDL-Lite", @"item", @"storageMedium"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setStorageMedium:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"DVDRegionCode"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDVDRegionCode:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"channelName"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setChannelName:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"scheduledStartTime"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setScheduledStartTime:) setStringValueObject:self];
    [self addAsset:@[@"DIDL-Lite", @"item", @"scheduledEndTime"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setScheduledEndTime:) setStringValueObject:self];
  }
    
	return self;
}

- (void)empty {
	[self setMediaClass:@""];
	[self setMediaTitle:@""];
	[self setMediaID:@""];
	[self setRefID:@""];
	[self setArtist:@""];
	[self setAlbum:@""];
	[self setDate:nil];
	[self setGenre:@""];
	[self setAlbumArt:nil];
	[self setDuration:nil];
  
  [self.resources removeAllObjects];
  [self.uriCollection removeAllObjects];

  // Video Item
  self.longDescription = @"";
  self.producer = @"";
  self.rating = @"";
  self.actor = @"";
  self.director = @"";
  self.movieDescription = @"";
  self.publisher = @"";
  self.language = @"";
  self.relation = @"";
  
  // Movie Item
  self.storageMedium = @"";
  self.DVDRegionCode = @"";
  self.channelName = @"";
  self.scheduledStartTime = @"";
  self.scheduledEndTime = @"";

}

- (void)container:(NSString *)startStop{
	if ([startStop isEqualToString:@"ElementStart"]) {
		//Clear
		[self empty];
		
		//Get the attributes
		[self setMediaID:[self.elementAttributeDict objectForKey:@"id"]];
		[self setParentID:[self.elementAttributeDict objectForKey:@"parentID"]];
		[self setChildCount:[self.elementAttributeDict objectForKey:@"childCount"]];
		[self setRefID:[self.elementAttributeDict objectForKey:@"refID"]];
	} else {
		MediaServer1ContainerObject *media = [[MediaServer1ContainerObject alloc] init];

		[media setContainer:YES];
 
		[media setObjectID:self.mediaID];
		[media setParentID:self.parentID];
		[media setTitle:self.mediaTitle];	
		[media setObjectClass:self.mediaClass];
		[media setChildCount:self.childCount];
		[media setAlbumArt:self.albumArt];
		
		[self.mediaObjects addObject:media];
	}
}

- (void)item:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
		//Clear
		[self empty];

		//Get the attributes
		[self setMediaID:self.elementAttributeDict[@"id"]];
		[self setParentID:self.elementAttributeDict[@"parentID"]];
		[self setRefID:self.elementAttributeDict[@"refID"]];
	} else {
		MediaServer1ItemObject *media;
    if ([self.mediaClass isEqualToString:@"object.item.videoItem"]) {
      media = [[MediaServer1VideoItemObject alloc] init];
    } else if ([self.mediaClass isEqualToString:@"object.item.videoItem.movie"]) {
      media = [[MediaServer1MovieVideoItemObject alloc] init];
    } else {
      media = [[MediaServer1ItemObject alloc] init];
    }
		
		[media setContainer:NO];

		[media setObjectID:self.mediaID];
    [media setObjectClass:self.mediaClass];
		[media setParentID:self.parentID];
    [media setRefID:self.refID];
		[media setTitle:self.mediaTitle];	
		[media setArtist:self.artist];
		[media setAlbum:self.album];
		[media setDate:self.date];	
		[media setGenre:self.genre];	
		[media setOriginalTrackNumber:self.originalTrackNumber];	
		[media setUri:self.uri];	
		[media setProtocolInfo:self.protocolInfo]; 	
		[media setFrequency:self.frequency];	
		[media setAudioChannels:self.audioChannels];	
		[media setSize:self.size];
		[media setDuration:self.duration];
    [media setDurationInSeconds:[self.duration HMS2Seconds]];
		[media setBitrate:self.bitrate];
		[media setIcon:self.icon]; //REMOVE THIS ?
		[media setAlbumArt:self.albumArt];
    [media setUriCollection:self.uriCollection];
    
    for (MediaServer1ItemRes *resource in self.resources) {
      [media addRes:resource];
    }
    [self.resources removeAllObjects];
    
    // Populate subclass details if the media is a vaild subclass
    if ([media isKindOfClass:[MediaServer1VideoItemObject class]]) {
      MediaServer1VideoItemObject *videoItem = (MediaServer1VideoItemObject *)media;
      videoItem.longDescription = self.longDescription;
      videoItem.producer = self.producer;
      videoItem.rating = self.rating;
      videoItem.actor = self.actor;
      videoItem.director = self.director;
      videoItem.movieDescription = self.movieDescription;
      videoItem.publisher = self.publisher;
      videoItem.language = self.language;
      videoItem.relation = self.relation;
    }

    if ([media isKindOfClass:[MediaServer1MovieVideoItemObject class]]) {
      MediaServer1MovieVideoItemObject *movieItem = (MediaServer1MovieVideoItemObject *)media;
      movieItem.storageMedium = self.storageMedium;
      movieItem.DVDRegionCode = self.DVDRegionCode;
      movieItem.channelName = self.channelName;
      movieItem.scheduledStartTime = self.scheduledStartTime;
      movieItem.scheduledEndTime = self.scheduledEndTime;
    }
    
    [self.mediaObjects addObject:media];
	}
}

- (void)res:(NSString *)startStop {
	if ([startStop isEqualToString:@"ElementStart"]) {
		//Get the attributes
		[self setProtocolInfo:[self.elementAttributeDict objectForKey:@"protocolInfo"]];
		[self setFrequency:[self.elementAttributeDict objectForKey:@"sampleFrequency"]];
		[self setAudioChannels:[self.elementAttributeDict objectForKey:@"nrAudioChannels"]];
		
		[self setSize:[self.elementAttributeDict objectForKey:@"size"]];
		[self setDuration:[self.elementAttributeDict objectForKey:@"duration"]];
		[self setBitrate:[self.elementAttributeDict objectForKey:@"bitrate"]];
		
		[self setIcon:[self.elementAttributeDict objectForKey:@"icon"]];
		
        
    //Add to the recource connection, there can be multiple resources per media item
    MediaServer1ItemRes *r = [[MediaServer1ItemRes alloc] init];
    [r setBitrate:[self.bitrate intValue]];
    [r setDuration:self.duration];
    [r setNrAudioChannels: [self.audioChannels intValue]];
    [r setProtocolInfo:self.protocolInfo];
    [r setSize: [self.size intValue]];
    [r setDurationInSeconds:[self.duration HMS2Seconds]];
    
    [self.resources addObject:r];      
	} else {
    [self.uriCollection setObject:self.uri forKey:self.protocolInfo]; //@todo: we overwrite uri's with same protocol info
	}
}

@end
