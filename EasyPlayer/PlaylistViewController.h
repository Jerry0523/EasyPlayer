//
//  PlaylistViewController.h
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

#import <Cocoa/Cocoa.h>
#import "JWTrack.h"

@class PlaylistViewController;

@protocol PlaylistViewDelegate <NSObject>

- (void)playlistViewController:(PlaylistViewController*)controller didRemoveTrack:(JWTrack*)track;
- (void)playlistViewController:(PlaylistViewController*)controller didSelectTrack:(JWTrack*)track;
- (void)playlistViewController:(PlaylistViewController *)controller didSortByType:(TrackSortType)sortType;

@end

@interface PlaylistViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>

@property (nonatomic, weak) id<PlaylistViewDelegate> playListDelegate;
@property (nonatomic, strong) NSArray *items;
@property (weak) IBOutlet NSTableView *tableView;

- (void)setSelectedIndex:(NSUInteger)idx;

@end
