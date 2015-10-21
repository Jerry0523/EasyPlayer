//
//  PlayerViewController.h
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
#import "JWPlayer.h"
#import "JWTrack.h"

@interface PlayerViewController : NSWindowController

@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSArray *filteredItems;

@property (strong, nonatomic) JWPlayer* player;
@property (strong, nonatomic) JWTrack *currentTrack;
@property (assign, nonatomic) TrackSortType sortType;
@property (assign, nonatomic) TrackPlayMode playMode;

@property (weak) IBOutlet NSToolbarItem *playToolbarItem;

@property (strong, nonatomic) NSMutableArray *playedList;

@property (weak) IBOutlet NSSegmentedControl *panelSwitchControl;
@property (weak) IBOutlet NSSegmentedControl *modeSegmentControl;
@property (weak) IBOutlet NSSearchField *searchField;

- (BOOL)isPlaying;

- (IBAction)playClicked:(NSToolbarItem*)sender;
- (IBAction)nextClicked:(id)sender;
- (IBAction)preClicked:(id)sender;

@end

static inline CGFloat skRand(NSInteger low, NSInteger high) {
    return arc4random() % high + low;
}
