//
//  PlaylistViewController.m
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

#import "PlaylistViewController.h"
#import "JWFileManager.h"
#import "JWMediaHelper.h"

@implementation PlaylistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    self.tableView.menu = menu;
}

- (void)setSelectedIndex:(NSUInteger)idx {
    if ([self.items count] > idx) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
    }
}

- (void)removeTrackWithSender:(NSMenuItem *)sender {
    JWTrack *item = self.items[self.tableView.clickedRow];
    [self.playListDelegate playlistViewController:self didRemoveTrack:item];
}

#pragma mark - NSMenuDelegate
- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    JWTrack *item = self.items[self.tableView.clickedRow];
    if (item.sourceType == TrackSourceTypeItunes) {
        return;
    }
    
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Remove From Library" action:@selector(removeTrackWithSender:) keyEquivalent:@""]];
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.items count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return @(row);
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    JWTrack *item = self.items[row];
    
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        cellView.textField.stringValue = item.name;
        cellView.imageView.layer.masksToBounds = YES;
        cellView.imageView.layer.cornerRadius = CGRectGetWidth(cellView.imageView.bounds) * .5;
        
        NSString *key = [item cacheKey];
        NSString *albumPath = [JWFileManager getCoverPath];
        if (albumPath) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSImage *image = nil;
                NSString *destination = [albumPath stringByAppendingPathComponent:key];
                if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
                    image = [[NSImage alloc] initWithContentsOfFile:destination];
                } else {
                    image = [NSImage imageNamed:@"sMusic"];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([cellView.objectValue integerValue] == row) {
                        cellView.imageView.image = image;
                    }
                });
            });
        } else {
            cellView.imageView.image = [NSImage imageNamed:@"sMusic"];
        }
    } else if([tableColumn.identifier isEqualToString:@"artist"]) {
        cellView.textField.stringValue = item.artist;
    } else if([tableColumn.identifier isEqualToString:@"album"]) {
        cellView.textField.stringValue = item.album;
    } else if([tableColumn.identifier isEqualToString:@"source"]) {
        cellView.textField.stringValue = item.sourceType == TrackSourceTypeItunes ? @"iTunes" : @"Local";
    }
    
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (!self.playListDelegate) {
        return;
    }
    
    if (self.tableView.selectedRow == -1) {
        [self.playListDelegate playlistViewController:self didSortByType:(TrackSortType)self.tableView.selectedColumn];
    } else {
        [self.playListDelegate playlistViewController:self didSelectTrack:self.items[self.tableView.selectedRow]];
    }
}

@end
