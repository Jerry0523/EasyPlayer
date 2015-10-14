//
//  PlaylistViewController.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/13.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "PlaylistViewController.h"

@interface PlaylistViewController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;

@end

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
    NSDictionary *item = self.items[row];
    cellView.textField.stringValue = item[@"Name"];
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.playListDelegate) {
        [self.playListDelegate playlistViewController:self didSelectTrack:self.items[self.tableView.selectedRow]];
    }
}

@end
