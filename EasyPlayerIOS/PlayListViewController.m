//
//  ViewController.m
//  EasyPlayerIOS
//
//  Created by Jerry Wong's Mac Mini on 16/1/4.
//  Copyright © 2016年 Jerry Wong. All rights reserved.
//

#import "PlayListViewController.h"
#import "PlayListCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "PlayerViewController.h"

@interface PlayListViewController ()

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *keys;

@end

@implementation PlayListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[PlayListCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tintColor = [UIColor colorWithRed:245.0 / 255.0 green:100.0 / 255.0 blue:20.0 / 255.0 alpha:1.0];
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
}

- (void)selectItem:(id)item {
    for (int i = 0; i < self.items.count; i++) {
        NSArray *section = self.items[i];
        for (int j = 0; j < section.count; j++) {
            if (section[j] == item) {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
        }
    }
}

- (void)setRawItems:(NSArray *)rawItems {
    _rawItems = rawItems;
    NSMutableArray *mItems = [NSMutableArray array];
    NSMutableArray *mKeys = [NSMutableArray array];
    
    NSMutableArray *sectionItems = [NSMutableArray array];
    NSString *lastKey;
    for (JWTrack *track in rawItems) {
        NSString *title = track.Name;
        NSString *firstLetter = [[title substringToIndex:1] uppercaseString];
        if ([firstLetter isEqualToString:lastKey]) {
            [sectionItems addObject:track];
        } else {
            if ([sectionItems count] > 0) {
                [mItems addObject:sectionItems];
            }
            if (lastKey) {
                [mKeys addObject:lastKey];
            }
            sectionItems = [NSMutableArray array];
            [sectionItems addObject:track];
            lastKey = firstLetter;
        }
    }
    
    if ([sectionItems count] > 0) {
        [mItems addObject:sectionItems];
    }
    if (lastKey) {
        [mKeys addObject:lastKey];
    }
    
    self.items = mItems;
    self.keys = mKeys;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.keys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items[section] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PlayListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    JWTrack *track = self.items[indexPath.section][indexPath.row];
    MPMediaItem *info = track.userInfo;
    cell.imageView.image = [info.artwork imageWithSize:CGSizeMake(48, 48)];
    cell.textLabel.text = track.Name;
    cell.detailLabel.text = track.Artist;
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.keys[section];
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.keys;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    JWTrack *track = self.items[indexPath.section][indexPath.row];
    [((PlayerViewController*)self.parentViewController) playTrack:track];
}

@end
