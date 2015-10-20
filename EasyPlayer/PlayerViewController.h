//
//  PlayerViewController.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/13.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "JWTrack.h"

@interface PlayerViewController : NSWindowController

@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSArray *filteredItems;

@property (strong, nonatomic) AVAudioPlayer* player;
@property (strong, nonatomic) JWTrack *currentTrack;
@property (assign, nonatomic) TrackSortType sortType;
@property (assign, nonatomic) TrackPlayMode playMode;

@property (weak) IBOutlet NSToolbarItem *playToolbarItem;

@property (strong, nonatomic) NSMutableArray *playedList;

@property (weak) IBOutlet NSSegmentedControl *panelSwitchControl;
@property (weak) IBOutlet NSSegmentedControl *modeSegmentControl;
@property (weak) IBOutlet NSSearchField *searchField;

@end

static inline CGFloat skRand(NSInteger low, NSInteger high) {
    return arc4random() % high + low;
}
