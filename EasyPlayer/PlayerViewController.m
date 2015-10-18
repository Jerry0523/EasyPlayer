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
@property (strong, nonatomic) NSArray *filteredItems;

@property (strong, nonatomic) AVAudioPlayer* player;
@property (strong, nonatomic) NSDictionary *currentTrack;

@property (weak) IBOutlet NSToolbarItem *playToolbarItem;

@property (strong, nonatomic) NSMutableArray *playedList;

@property (weak) IBOutlet NSSegmentedControl *panelSwitchControl;
@property (weak) IBOutlet NSSearchField *searchField;

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
                    if (location && ![location hasSuffix:@".m4p"] && ![location hasSuffix:@".mp4"]) {
                        [mutable addObject:tracks[key]];
                    }
                }
            }
            [mutable sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
                return [obj1[@"Name"] compares:obj2[@"Name"]];
            }];
            self.items = mutable;
            self.filteredItems = self.items;
        }
    }
    
    NSRect rect = ((NSView*)self.window.contentView).bounds;
    
    musicInfoController = [[MusicInfoViewController alloc] init];
    [self.window.contentView addSubview:musicInfoController.view];
    musicInfoController.view.bounds = rect;
    musicInfoController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    
    playlistController = [[PlaylistViewController alloc] init];
    playlistController.items = self.filteredItems;
    playlistController.playListDelegate = self;
    [self.window.contentView addSubview:playlistController.view];
    playlistController.view.bounds = rect;
    playlistController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    
    progressView = [[MusicProgressView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(rect) - 2, CGRectGetWidth(rect), 2)];
    progressView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self.window.contentView addSubview:progressView];
}

- (void)switchToPlayListPanel {
    if(playlistController.view.hidden == NO) {
        return;
    }
    
    [self.window.toolbar removeItemAtIndex:6];
    [self.window.toolbar removeItemAtIndex:5];
    [self.window.toolbar removeItemAtIndex:4];
    [self.window.toolbar removeItemAtIndex:3];
    [self.window.toolbar removeItemAtIndex:2];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"add" atIndex:2];
    [self.window.toolbar insertItemWithItemIdentifier:@"search" atIndex:3];
    
    
    playlistController.view.hidden = NO;
    [playlistController.tableView reloadData];
    if (self.currentTrack) {
        NSInteger selectedRow = [self.items indexOfObject:self.currentTrack];
        [playlistController.tableView scrollRowToVisible:selectedRow];
        [playlistController.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
    
    self.panelSwitchControl.selectedSegment = 0;
}

- (void)switchToMuscicInfoPanel {
    if(playlistController.view.hidden == YES) {
        return;
    }
    
    [self.window.toolbar removeItemAtIndex:3];
    [self.window.toolbar removeItemAtIndex:2];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"pre" atIndex:2];
    [self.window.toolbar insertItemWithItemIdentifier:@"play" atIndex:3];
    [self.window.toolbar insertItemWithItemIdentifier:@"next" atIndex:4];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"NSToolbarFlexibleSpaceItem" atIndex:5];
    [self.window.toolbar insertItemWithItemIdentifier:@"mode" atIndex:6];
    
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
    
    [self switchToMuscicInfoPanel];
    
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
- (IBAction)searchFieldValueChanged:(NSSearchField *)sender {
    if ([sender.stringValue length] == 0) {
        self.filteredItems = self.items;
    } else {
        NSString *searchString = [sender.stringValue lowercaseString];
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *track in self.items) {
            if ([[track[@"Name"] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
                [[track[@"Album"] lowercaseString] rangeOfString:searchString].location != NSNotFound ||
                [[track[@"Artist"] lowercaseString] rangeOfString:searchString].location != NSNotFound) {
                [array addObject:track];
            }
        }
        self.filteredItems = array;
    }
}

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
        [self switchToPlayListPanel];
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

- (void)setFilteredItems:(NSArray *)filteredItems {
    if (_filteredItems != filteredItems) {
        _filteredItems = filteredItems;
        playlistController.items = filteredItems;
        [playlistController.tableView reloadData];
        
        if (self.currentTrack) {
            NSInteger selectedRow = [self.items indexOfObject:self.currentTrack];
            [playlistController.tableView scrollRowToVisible:selectedRow];
            [playlistController.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
        }
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
