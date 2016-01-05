//
//  PlayerViewController.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 16/1/4.
//  Copyright © 2016年 Jerry Wong. All rights reserved.
//

@import AVFoundation;
@import MediaPlayer;

#import "PlayerViewController.h"
#import "PlayListViewController.h"
#import "JWFileManager.h"


@implementation PlayerViewController {
    NSArray *rawItems;
    MPMusicPlayerController *player;
    PlayListViewController *playListController;
}

- (instancetype)init {
    if (self = [super init]) {
        rawItems = [JWFileManager getItuensMediaArray];
        rawItems = [rawItems sortedArrayUsingComparator:^NSComparisonResult(JWTrack *obj0, JWTrack *obj1) {
            return [obj0 compares:obj1 sortType:TrackSortTypeDefault];
        }];
        
        UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 64)];
        UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"EasyPlayer"];
        [bar pushNavigationItem:item animated:NO];
        [self.view addSubview:bar];
        
        playListController = [PlayListViewController alloc];
        playListController.rawItems = rawItems;
        [self addChildViewController:playListController];
        playListController.view.frame = self.view.bounds;
        [self.view insertSubview:playListController.view belowSubview:bar];
    }
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerStateDidChange:)
                                                 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                               object:nil];
    return self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)playerStateDidChange:(NSNotification*)notification {
    if ([notification.userInfo[@"MPMusicPlayerControllerPlaybackStateKey"] integerValue] == MPMusicPlaybackStateStopped) {
        [self playRandomTrack];
    }
}

- (void)playRandomTrack {
    NSUInteger idx = arc4random() % (rawItems.count - 1) + 0;
    [self playTrack:rawItems[idx]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playTrack:(JWTrack*)track {
    [playListController selectItem:track];
    
    if (!player) {
        player = [MPMusicPlayerController applicationMusicPlayer];
    }
    [player beginGeneratingPlaybackNotifications];
    [player setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:@[track.userInfo]]];
    [player play];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [player pause];
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
//                [self playLastButton:self.lastButton];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [self playRandomTrack];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [player play];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [player pause];
                break;
                
            default:
                break;
        }
    }
}

@end
