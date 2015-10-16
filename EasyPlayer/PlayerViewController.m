//
//  PlayerViewController.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/13.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlaylistViewController.h"
#import "MusicProgressView.h"
#import "MusicInfoViewController.h"
#import "NSString+Comparator.h"
#import <AVFoundation/AVFoundation.h>

static inline CGFloat skRand(NSInteger low, NSInteger high) {
    return arc4random() % high + low;
}

@interface PlayerViewController ()<AVAudioPlayerDelegate, PlaylistViewDelegate>

@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) AVAudioPlayer* player;
@property (strong, nonatomic) NSDictionary *currentTrack;

@property (weak) IBOutlet NSToolbarItem *playToolbarItem;

@property (strong, nonatomic) NSMutableArray *playedList;

@property (weak) IBOutlet NSSegmentedControl *panelSwitchControl;

@end

@implementation PlayerViewController {
    PlaylistViewController *playlistController;
    MusicInfoViewController *musicInfoController;
    MusicProgressView *progressView;
    NSTimer *progressTimer;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.playedList = [NSMutableArray array];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES);
    if(paths.count > 0) {
        NSString *musicRootPath = paths[0];
        NSDictionary *iTunesLibrary = [NSDictionary dictionaryWithContentsOfFile:[musicRootPath stringByAppendingPathComponent:@"iTunes/iTunes Music Library.xml"]];
        if (iTunesLibrary) {
            NSDictionary *tracks = iTunesLibrary[@"Tracks"];
            NSArray *keys = tracks.allKeys;
            
            NSMutableArray *mutable = [NSMutableArray array];
            for (id key in keys) {
                NSDictionary *track = tracks[key];
                if ([track[@"Total Time"] longValue] > 30000) {
                    
                    NSString *location = track[@"Location"];
                    if (location && ![location hasSuffix:@".m4p"]) {
                        [mutable addObject:tracks[key]];
                    }
                }
            }
            [mutable sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
                return [obj1[@"Name"] compares:obj2[@"Name"]];
            }];
            self.items = mutable;
        }
    }
    
    NSRect rect = ((NSView*)self.window.contentView).bounds;
    
    musicInfoController = [[MusicInfoViewController alloc] init];
    [self.window.contentView addSubview:musicInfoController.view];
    musicInfoController.view.bounds = rect;
    musicInfoController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    
    playlistController = [[PlaylistViewController alloc] init];
    playlistController.items = self.items;
    playlistController.playListDelegate = self;
    [self.window.contentView addSubview:playlistController.view];
    playlistController.view.bounds = rect;
    playlistController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    
    progressView = [[MusicProgressView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(rect) - 2, CGRectGetWidth(rect), 2)];
    progressView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self.window.contentView addSubview:progressView];
}

- (void)switchToPlayListPanel {
    playlistController.view.hidden = NO;
    self.panelSwitchControl.selectedSegment = 0;
}

- (void)switchToMuscicInfoPanel {
    playlistController.view.hidden = YES;
    self.panelSwitchControl.selectedSegment = 1;
}

- (void)playRandomSong {
    NSInteger idx = skRand(0, self.items.count - 1);
    [self playSongByTrack:self.items[idx]];
    [playlistController setSelectedIndex:idx];
}

- (void)playSongByTrack:(NSDictionary*)track {
    if (self.currentTrack == track) {
        return;
    }
    
    [self.playedList removeObject:track];
    [self.playedList addObject:track];
    
    self.playToolbarItem.image = [NSImage imageNamed:@"pause"];
    
    playlistController.view.hidden = YES;
    
    if (progressTimer) {
        [progressTimer invalidate];
        progressView.progress = 0;
    }
    
    self.currentTrack = track;
    self.window.title = track[@"Name"];

    NSData *musicData = [NSData dataWithContentsOfURL:[NSURL URLWithString:track[@"Location"]]];
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithData:musicData error:&error];
    self.player.delegate = self;
    if (!error) {
        [self.player play];
    } else {
        [self playRandomSong];
        NSLog(@"%@", [error localizedDescription]);
    }
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshProgressByTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:progressTimer forMode:NSRunLoopCommonModes];
    [progressTimer fire];
    
    musicInfoController.trackInfo = track;
}

- (void)refreshProgressByTimer {
    NSTimeInterval currentTime = self.player.currentTime;
    NSTimeInterval totalTime = [self.currentTrack[@"Total Time"] longValue] / 1000.0;
    
    if (totalTime > 0) {
        progressView.progress = currentTime / totalTime;
    }
    musicInfoController.currentTimerInteval = currentTime;
}

#pragma mark - IBActions

- (IBAction)playClicked:(NSToolbarItem*)sender {
    if (self.player) {
        if (self.player.isPlaying) {
            [self.player pause];
            sender.image = [NSImage imageNamed:@"play"];
            [self switchToPlayListPanel];
            if (progressTimer) {
                [progressTimer setFireDate:[NSDate distantFuture]];
            }
        } else {
            [self switchToMuscicInfoPanel];
            [self.player play];
            sender.image = [NSImage imageNamed:@"pause"];
            [progressTimer setFireDate:[NSDate date]];
        }
    } else {
        [self switchToMuscicInfoPanel];
        [self playRandomSong];
    }
}

- (IBAction)nextClicked:(id)sender {
    [self playRandomSong];
}

- (IBAction)preClicked:(id)sender {
    if ([self.playedList count] > 0) {
        [self.playedList removeObject:[self.playedList lastObject]];
    }
    if ([self.playedList count] > 0) {
        id lastTrack = [self.playedList lastObject];
        [self playSongByTrack:lastTrack];
        [playlistController setSelectedIndex:[self.items indexOfObject:lastTrack]];
    } else {
        [self.player stop];
        self.playToolbarItem.image = [NSImage imageNamed:@"play"];
        playlistController.view.hidden = NO;
        if (progressTimer) {
            [progressTimer invalidate];
            progressTimer = nil;
        }
    }
}

- (IBAction)panelSwitched:(NSSegmentedControl*)sender {
    if (sender.selectedSegment == 0) {
        [self switchToPlayListPanel];
    } else {
        [self switchToMuscicInfoPanel];
    }
}

#pragma mark - PlaylistViewDelegate
- (void)playlistViewController:(PlaylistViewController *)controller didSelectTrack:(NSDictionary *)track {
    [self playSongByTrack:track];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self playRandomSong];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self playRandomSong];
}

@end
