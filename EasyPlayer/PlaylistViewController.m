//
//  PlaylistViewController.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/13.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "PlaylistViewController.h"
#import "JWFileManager.h"
#import "JWTagHelper.h"

@implementation PlaylistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:.5].CGColor;
}

- (void)setSelectedIndex:(NSUInteger)idx {
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
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
