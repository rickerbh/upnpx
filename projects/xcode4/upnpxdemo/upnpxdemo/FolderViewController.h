//
//  FolderViewController.h
//  upnpxdemo
//
//  Created by Bruno Keymolen on 02/07/11.
//  Copyright 2011 Bruno Keymolen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaServer1Device.h"

@interface FolderViewController : UITableViewController

@property (strong) UILabel *titleLabel;

- (id)initWithMediaDevice:(MediaServer1Device *)device andHeader:(NSString*)header andRootId:(NSString*)rootId;

@end
