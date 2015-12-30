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
}

- (void)setSelectedIndex:(NSUInteger)idx {
    if ([self.items count] > idx) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
    }
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.items count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    JWTrack *item = self.items[row];
    
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        cellView.textField.stringValue = item.Name;
//        [cellView.imageView setWantsLayer:YES];
        
        cellView.imageView.layer.masksToBounds = YES;
        cellView.imageView.layer.cornerRadius = CGRectGetWidth(cellView.imageView.bounds) * .5;
        
        NSString *key = [item cacheKey];
        NSString *albumPath = [JWFileManager getCoverPath];
        if (albumPath) {
            NSString *destination = [albumPath stringByAppendingPathComponent:key];
            if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
                NSImage *image = [[NSImage alloc] initWithContentsOfFile:destination];
                cellView.imageView.image = image;
            } else {
                cellView.imageView.image = [NSImage imageNamed:@"sMusic"];
            }
        } else {
            cellView.imageView.image = [NSImage imageNamed:@"sMusic"];
        }
    } else if([tableColumn.identifier isEqualToString:@"artist"]) {
        cellView.textField.stringValue = item.Artist;
    } else if([tableColumn.identifier isEqualToString:@"album"]) {
        cellView.textField.stringValue = item.Album;
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
