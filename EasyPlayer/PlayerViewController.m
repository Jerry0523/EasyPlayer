//
//  PlayerViewController.m
//
// Copyright (c) 2015 Jerry Wong
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PlayerViewController.h"
#import "PlaylistViewController.h"
#import "MusicProgressView.h"
#import "MusicInfoViewController.h"
#import "JWFileManager.h"
#import "JWMediaHelper.h"
#import "NSImage+Utils.h"


@interface PlayerViewController ()<JWPlayerDelegate, PlaylistViewDelegate>

@end

@implementation PlayerViewController {
    PlaylistViewController *playlistController;
    MusicInfoViewController *musicInfoController;
    MusicProgressView *progressView;
    NSTimer *progressTimer;
    NSDate *lastPlayDate;
}

- (BOOL)isPlaying {
    return self.player.isPlaying;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.player = [JWPlayer new];
    self.player.delegate = self;
    
    self.playedList = [NSMutableArray array];
    NSMutableArray *mutable = [NSMutableArray arrayWithArray:[JWFileManager getItuensMediaArray]];
    [mutable addObjectsFromArray:[JWFileManager getLocalMediaArray]];
    
    self.items = mutable;
    self.filteredItems = self.items;
    
    
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.sortType = (TrackSortType)[[userDefaults objectForKey:@"JWSortType"] integerValue];
    self.playMode = (TrackPlayMode)[[userDefaults objectForKey:@"JWPlayMode"] integerValue];
    self.modeSegmentControl.selectedSegment = self.playMode;
}

- (void)switchToPlayListPanel {
    if(playlistController.view.hidden == NO) {
        return;
    }
    
    self.window.title = @"";
    
    [self.window.toolbar removeItemAtIndex:6];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"add" atIndex:6];
    [self.window.toolbar insertItemWithItemIdentifier:@"search" atIndex:7];
    
    
    playlistController.view.hidden = NO;
    [playlistController.tableView reloadData];
    if (self.currentTrack) {
        NSInteger selectedRow = [self.filteredItems indexOfObject:self.currentTrack];
        [playlistController.tableView scrollRowToVisible:selectedRow];
        [playlistController.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
    
    self.panelSwitchControl.selectedSegment = 0;
}

- (void)switchToMuscicInfoPanel {
    if(playlistController.view.hidden == YES) {
        return;
    }
    
    self.window.title = self.currentTrack ? self.currentTrack.Name : @"";
    
    [self.window.toolbar removeItemAtIndex:7];
    [self.window.toolbar removeItemAtIndex:6];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"mode" atIndex:6];
    
    playlistController.view.hidden = YES;
    self.panelSwitchControl.selectedSegment = 1;
}

- (void)playRandomSong {
    NSInteger idx = skRand(0, self.items.count - 1);
    [self playSongByTrack:self.items[idx]];
    [playlistController setSelectedIndex:idx];
}

- (void)playSongByTrack:(JWTrack*)track {
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
    self.window.title = track.Name;

    BOOL success = [self.player playWithURL:[track fileURL]];
    if (!success) {
        [self playRandomSong];
        return;
    }
    
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshProgressByTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:progressTimer forMode:NSRunLoopCommonModes];
    [progressTimer fire];
    
    musicInfoController.trackInfo = track;
}

- (void)refreshProgressByTimer {
    NSTimeInterval currentTime = [self.player currentTime];
    NSTimeInterval totalTime = self.currentTrack.TotalTime / 1000.0;
    
    if (totalTime == 0) {
        totalTime = [self.player totalTime];
    }
    
    if (totalTime > 0) {
        progressView.progress = currentTime / totalTime;
    }
    musicInfoController.currentTimerInteval = currentTime;
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

- (void)setSortType:(TrackSortType)sortType {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(sortType) forKey:@"JWSortType"];
    [userDefaults synchronize];
    
    _sortType = sortType;
    NSArray *array = [self.items sortedArrayUsingComparator:^NSComparisonResult(JWTrack *obj0, JWTrack *obj1) {
        return [obj0 compares:obj1 sortType:sortType];
    }];
    self.items = array;
    [self searchFieldValueChanged:self.searchField];
}

#pragma mark - IBActions

- (IBAction)searchFieldValueChanged:(NSSearchField *)sender {
    if ([sender.stringValue length] == 0) {
        self.filteredItems = self.items;
    } else {
        NSString *searchString = [sender.stringValue lowercaseString];
        NSMutableArray *array = [NSMutableArray array];
        for (JWTrack *track in self.items) {
            if ([track respondToSearch:searchString]) {
                [array addObject:track];
            }
        }
        [array sortUsingComparator:^NSComparisonResult(JWTrack *obj0, JWTrack *obj1) {
            return [obj0 compares:obj1 sortType:self.sortType];
        }];
        self.filteredItems = array;
    }
}

- (IBAction)playClicked:(NSToolbarItem*)sender {
    if (self.player.isPlaying) {
        [self.player pause];
        self.playToolbarItem.image = [NSImage imageNamed:@"play"];
        [self switchToPlayListPanel];
        if (progressTimer) {
            [progressTimer setFireDate:[NSDate distantFuture]];
        }
    } else {
        [self switchToMuscicInfoPanel];
        if (self.currentTrack) {
            [self.player resume];
        } else {
            [self playRandomSong];
        }
        self.playToolbarItem.image = [NSImage imageNamed:@"pause"];
        [progressTimer setFireDate:[NSDate date]];
    }
}

- (IBAction)nextClicked:(id)sender {
    lastPlayDate = [NSDate date];
    [self playRandomSong];
}

- (IBAction)preClicked:(id)sender {
    lastPlayDate = [NSDate date];
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

- (IBAction)playModeChanged:(NSSegmentedControl*)sender {
    self.playMode = (TrackPlayMode)sender.selectedSegment;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(self.playMode) forKey:@"JWPlayMode"];
    [userDefaults synchronize];
}

- (IBAction)addButtonClicked:(NSButton *)sender {
    sender.state = 1;
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:YES];
    
    NSArray *urlArray;
    
    if ( [openDlg runModal] == NSModalResponseOK) {
        urlArray = [openDlg URLs];
    }
    
    NSMutableArray *newTracks = [NSMutableArray array];
    
    for (NSURL *url in urlArray) {
        [JWMediaHelper scanSupportedMediaForFileURL:url into:newTracks];
    }
    
    NSMutableArray *mutable = [NSMutableArray arrayWithArray:self.items];
    [mutable addObjectsFromArray:newTracks];
    self.items = mutable;
    [self setSortType:_sortType];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *localLibPath = [JWFileManager getMusicLibraryFilePath];
        NSArray *oldLocalLibArray = [[NSArray alloc] initWithContentsOfFile:localLibPath];
        NSMutableArray *newLocalLibArray = [NSMutableArray array];
        if ([oldLocalLibArray count]) {
            [newLocalLibArray addObjectsFromArray:oldLocalLibArray];
        }
        for (JWTrack *newTrack in newTracks) {
            [JWFileManager copyTrackToLocalMediaPath:newTrack];
            [newLocalLibArray addObject:[newTrack archivedData]];
        }
        
        [newLocalLibArray writeToFile:localLibPath atomically:YES];
    });
}

#pragma mark - PlaylistViewDelegate
- (void)playlistViewController:(PlaylistViewController *)controller didSelectTrack:(JWTrack *)track {
    [self playSongByTrack:track];
}

- (void)playlistViewController:(PlaylistViewController *)controller didSortByType:(TrackSortType)sortType {
    self.sortType = sortType;
}

#pragma mark - JWPlayerDelegate

- (void)errorDidOccur:(JWPlayer*)player {
    [self playRandomSong];
}

- (void)didFinishPlaying:(JWPlayer*)player{
    NSDate *actionDate = [NSDate date];
    if ([actionDate timeIntervalSinceDate:lastPlayDate] < 0.5) {
        return;
    }
    
    if (self.playMode == TrackPlayModeSingle) {
        JWTrack *single = self.currentTrack;
        self.currentTrack = nil;
        [self playSongByTrack:single];
    } else {
        [self playRandomSong];
    }
}

@end
