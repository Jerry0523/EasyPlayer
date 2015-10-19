//
//  MusicInfoViewController.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JWTrack.h"

@interface MusicInfoViewController : NSViewController

@property (weak) IBOutlet NSImageView *coverImageView;

@property (weak) IBOutlet NSTextField *artistLabel;
@property (weak) IBOutlet NSTextField *albumLabel;
@property (weak) IBOutlet NSTextField *nameLabel;

@property (strong, nonatomic) JWTrack *trackInfo;

@property (assign, nonatomic) NSTimeInterval currentTimerInteval;

@end
