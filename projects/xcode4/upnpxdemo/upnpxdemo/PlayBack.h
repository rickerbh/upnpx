//
//  PlayBack.h
//  upnpxdemo
//
//  Created by Bruno Keymolen on 03/03/12.
//  Copyright 2012 Bruno Keymolen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UPnPx.h"

@interface PlayBack : NSObject <BasicUPnPServiceObserver>

+(PlayBack*)GetInstance;

@property (nonatomic, strong) MediaRenderer1Device *renderer;

-(int)Play:(NSMutableArray*)playList position:(int)position;
-(int)Play:(int)position;

//BasicUPnPServiceObserver
-(void)UPnPEvent:(BasicUPnPService*)sender events:(NSDictionary*)events;

@property (retain) MediaServer1Device *server;
@property (retain) NSMutableArray *playlist;

@end

