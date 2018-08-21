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


@interface PlayerViewController ()<JWMEngineDelegate, PlaylistViewDelegate>

@end

@implementation PlayerViewController {
    PlaylistViewController *_playlistController;
    MusicInfoViewController *_musicInfoController;
    MusicProgressView *_progressView;
    NSTimer *_progressTimer;
}

- (BOOL)isPlaying {
    return self.player.isPlaying;
}

- (void)rightMouseUp:(NSEvent *)theEvent {

}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *list = [[NSMenuItem alloc] initWithTitle:@"List" action:@selector(rightMouseUp:) keyEquivalent:@""];
    list.state = 1;
    
    NSMenuItem *card = [[NSMenuItem alloc] initWithTitle:@"Card" action:@selector(rightMouseUp:) keyEquivalent:@""];
    [menu addItem:list];
    [menu addItem:card];
    
    [self.panelSwitchControl setMenu:menu forSegment:0];
    
    self.player = [[JWMEngine alloc] init];;
    self.player.delegate = self;
    
    self.playedList = [NSMutableArray array];
    NSMutableArray *mutable = [NSMutableArray arrayWithArray:[JWFileManager getItunesMediaArray]];
    [mutable addObjectsFromArray:[JWFileManager getLocalMediaArray]];
    
    self.items = mutable;
    self.filteredItems = self.items;
    
    
    NSRect rect = ((NSView*)self.window.contentView).bounds;
    
    _musicInfoController = [[MusicInfoViewController alloc] init];
    [self.window.contentView addSubview:_musicInfoController.view];
    _musicInfoController.view.bounds = rect;
    _musicInfoController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    
    _playlistController = [[PlaylistViewController alloc] init];
    _playlistController.items = self.filteredItems;
    _playlistController.playListDelegate = self;
    [self.window.contentView addSubview:_playlistController.view];
    _playlistController.view.bounds = rect;
    _playlistController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    
    _progressView = [[MusicProgressView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(rect) - 2, CGRectGetWidth(rect), 2)];
    _progressView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self.window.contentView addSubview:_progressView];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.sortType = (TrackSortType)[[userDefaults objectForKey:@"JWSortType"] integerValue];
    self.playMode = (TrackPlayMode)[[userDefaults objectForKey:@"JWPlayMode"] integerValue];
    self.modeSegmentControl.selectedSegment = self.playMode;
}

- (void)switchToPlayListPanel {
    if(_playlistController.view.hidden == NO) {
        return;
    }
    
    self.window.title = @"";
    
    [self.window.toolbar removeItemAtIndex:6];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"add" atIndex:6];
    [self.window.toolbar insertItemWithItemIdentifier:@"search" atIndex:7];
    
    
    _playlistController.view.hidden = NO;
    [_playlistController.tableView reloadData];
    if (self.currentTrack) {
        NSInteger selectedRow = [self.filteredItems indexOfObject:self.currentTrack];
        [_playlistController.tableView scrollRowToVisible:selectedRow];
        [_playlistController.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
    
    self.panelSwitchControl.selectedSegment = 0;
}

- (void)switchToMuscicInfoPanel {
    if(_playlistController.view.hidden == YES) {
        return;
    }
    
    self.window.title = self.currentTrack ? self.currentTrack.Name : @"";
    
    [self.window.toolbar removeItemAtIndex:7];
    [self.window.toolbar removeItemAtIndex:6];
    
    [self.window.toolbar insertItemWithItemIdentifier:@"mode" atIndex:6];
    
    _playlistController.view.hidden = YES;
    self.panelSwitchControl.selectedSegment = 1;
}

- (NSUInteger)createRandomIndex {
    return arc4random() % (self.items.count - 1) + 0;
}

- (void)playRandomSong {
    NSUInteger randomIndex = [self createRandomIndex];
    [self playSongByTrack:self.items[randomIndex]];
    
}

- (void)playSongByTrack:(JWTrack*)track {
    if (self.currentTrack == track) {
        return;
    }
    
    [self.playedList removeObject:track];
    [self.playedList addObject:track];
    
    self.window.title = track.Name;

    [self.player playUrl:[track fileURL]];
    self.currentTrack = track;
}

- (void)setCurrentTrack:(JWTrack *)currentTrack {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_currentTrack = currentTrack;
        self.playToolbarItem.image = [NSImage imageNamed:@"pause"];
        [self switchToMuscicInfoPanel];
        
        if (self->_progressTimer) {
            [self->_progressTimer invalidate];
            self->_progressView.progress = 0;
        }
        
        self->_progressTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshProgressByTimer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self->_progressTimer forMode:NSRunLoopCommonModes];
        [self->_progressTimer fire];
        
        self->_musicInfoController.trackInfo = currentTrack;
        [self->_playlistController setSelectedIndex:[self.filteredItems indexOfObject:currentTrack]];
    });
}

- (void)refreshProgressByTimer {
    NSTimeInterval currentTime = self.player.amountPlayed;
    NSTimeInterval totalTime = self.currentTrack.TotalTime / 1000.0;
    
    if (totalTime == 0) {
        totalTime = self.player.trackTime;
    }
    
    if (totalTime > 0) {
        _progressView.progress = currentTime / totalTime;
    }
    _musicInfoController.currentTimerInteval = currentTime;
}

- (void)setFilteredItems:(NSArray *)filteredItems {
    if (_filteredItems != filteredItems) {
        _filteredItems = filteredItems;
        _playlistController.items = filteredItems;
        [_playlistController.tableView reloadData];
        
        if (self.currentTrack) {
            NSInteger selectedRow = [self.items indexOfObject:self.currentTrack];
            _playlistController.playListDelegate = nil;
            [_playlistController.tableView scrollRowToVisible:selectedRow];
            [_playlistController.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            _playlistController.playListDelegate = self;
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
        if (_progressTimer) {
            [_progressTimer setFireDate:[NSDate distantFuture]];
        }
    } else {
        [self switchToMuscicInfoPanel];
        if (self.currentTrack) {
            [self.player resume];
        } else {
            [self playRandomSong];
        }
        self.playToolbarItem.image = [NSImage imageNamed:@"pause"];
        [_progressTimer setFireDate:[NSDate date]];
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
        [_playlistController setSelectedIndex:[self.items indexOfObject:lastTrack]];
    } else {
        [self.player stop];
        self.playToolbarItem.image = [NSImage imageNamed:@"play"];
        [self switchToPlayListPanel];
        if (_progressTimer) {
            [_progressTimer invalidate];
            _progressTimer = nil;
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

#pragma mark - JWMEngineDelegate

- (NSURL *)engineExpectsNextUrl:(JWMEngine *)engine {
    JWTrack *track;
    if (self.playMode == TrackPlayModeSingle) {
        track = self.currentTrack;
    } else {
        NSUInteger randomIndex = [self createRandomIndex];
        track = self.items[randomIndex];
    }
    self.currentTrack = track;
    return [track fileURL];
}

- (void)engine:(JWMEngine *)engine didChangeState:(JWMEngineState)state {
    switch (state) {
        case JWMEngineStateStopped: {
            break;
        }
        case JWMEngineStatePaused: {
            break;
        }
        case JWMEngineStatePlaying: {
            break;
        }
        case JWMEngineStateError: {
            [self playRandomSong];
            break;
        }
    }
}

@end
