//
//  MusicInfoViewController.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "MusicInfoViewController.h"
#import "LrcHelper.h"

@interface MusicInfoViewController ()

@end

@implementation MusicInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setTrackInfo:(NSDictionary *)trackInfo {
    if (_trackInfo != trackInfo) {
        _trackInfo = trackInfo;
        LrcHelper *helper = [LrcHelper helper];
        self.nameLabel.stringValue = trackInfo[@"Name"];
        self.artistLabel.stringValue = trackInfo[@"Artist"];
        self.albumLabel.stringValue = trackInfo[@"Album"];
        self.coverImageView.image = [NSImage imageNamed:@"album"];
        
        [helper getAlbumImageForName:trackInfo[@"Name"] artist:trackInfo[@"Artist"] onComplete:^(NSImage *image, NSString *key, NSError *error) {
            if (image) {
                NSString *aKey = [helper keyForName:self.nameLabel.stringValue artist:self.artistLabel.stringValue];
                if ([aKey isEqualToString:key]) {
                    self.coverImageView.image = image;
                }
            }
        }];
        
        //    [helper getLrcForName:track[@"Name"] artist:track[@"Artist"] onComplete:^(NSString *lrc, NSError *error) {
        ////        if (lrc) {
        ////            NSLog(lrc);
        ////        } else {
        ////            NSLog([error localizedDescription]);
        ////        }
        //        
        //    }];
        //
    }
}

@end
