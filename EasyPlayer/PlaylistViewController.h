//
//  PlaylistViewController.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/13.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlaylistViewController;

@protocol PlaylistViewDelegate <NSObject>

- (void)playlistViewController:(PlaylistViewController*)controller didSelectTrack:(NSDictionary*)track;

@end

@interface PlaylistViewController : NSViewController

@property (nonatomic, weak) id<PlaylistViewDelegate> playListDelegate;
@property (nonatomic, strong) NSArray *items;

- (void)setSelectedIndex:(NSUInteger)idx;

@end
