//
//  PlayBack.m
//  upnpxdemo
//
//  Created by Bruno Keymolen on 03/03/12.
//  Copyright 2012 Bruno Keymolen. All rights reserved.
//

#import "PlayBack.h"

static PlayBack *_playback = nil;

@interface PlayBack ()
@property (assign) int pos;
@end

@implementation PlayBack

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
        self.pos = 0;
    }
    return self;
}

+ (PlayBack *)GetInstance{
	if (_playback == nil){
		_playback = [[PlayBack alloc] init];
	}
	return _playback;
}

- (void)setRenderer:(MediaRenderer1Device *)rend {
    MediaRenderer1Device *old = self.renderer;
    
    //Remove the Old Observer, if any
    if (old!=nil) {
         if ([[old avTransportService] isObserver:self] == YES) {
             [[old avTransportService] removeObserver:self]; 
         }
    }

    _renderer = rend;

    //Add New Observer, if any
    if (self.renderer != nil) {
        if ([[self.renderer avTransportService] isObserver:self] == NO) {
            [[self.renderer avTransportService] addObserver:self];
        }
    }
}

- (int)Play:(NSMutableArray *)playList position:(int)position {
    [self setPlaylist:playList];
    
    //Lazy Observer attach
    if ([[self.renderer avTransportService] isObserver:self] == NO) {
        [[self.renderer avTransportService] addObserver:self]; 
    }
    
    //Play
    return [self Play:position];
}

- (int)Play:(int)position {
    //Do we have a Renderer & a playlist ?
    if (self.renderer == nil || self.playlist == nil) {
        return -1;
    }
    
    if (position >= [self.playlist count]) {
        position = 0; //Loop
    }
    
    self.pos = position;

    //Is it a Media1ServerItem ?
    if (![[self.playlist objectAtIndex:self.pos] isContainer]) {
        MediaServer1ItemObject *item = [self.playlist objectAtIndex:self.pos];
        
        //A few things are missing here:
        // - Find the right URI based on MIME type, do this via: [item resources], also check render capabilities 
        // = The InstanceID is set to @"0", find the right one via: "ConnetionManager PrepareForConnection"
      
        //Find the right URI & Instance ID
        NSString *uri = [item uri];
        NSString *iid = @"0";
      
        //Play
        [[self.renderer avTransport] SetPlayModeWithInstanceID:iid NewPlayMode:@"NORMAL"];
        [[self.renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:@""];
        [[self.renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];        
    }
    return 0;
}

//BasicUPnPServiceObserver
- (void)UPnPEvent:(BasicUPnPService *)sender events:(NSDictionary *)events {
    if (sender == [self.renderer avTransportService]) {
        NSString *newState = [events objectForKey:@"TransportState"];
        
        if ([newState isEqualToString:@"STOPPED"]) {
            //Do your stuff, play next song etc...
            NSLog(@"Event: 'STOPPED', Play next track of playlist.");
           [self Play:self.pos + 1]; //Next
        }
    }
}

@end
