//
//  MusicInfoViewController.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MusicInfoViewController.h"
#import "JWTagHelper.h"
#import "NSImage+Utils.h"
#import "JWLrcParser.h"
#import "NSColor+Components.h"

@interface MusicInfoViewController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *lrcTableView;
@property (weak) IBOutlet NSLayoutConstraint *lyricWidthConstraints;

@property (strong, nonatomic) NSArray *lrcLines;

@end

@implementation MusicInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)refreshLabelsColorByTheme:(BOOL)backgroundDark {
    _nameLabel.textColor = backgroundDark ? [NSColor whiteColor] : [NSColor colorWithWhite:70.0 / 255.0 alpha:1.0];
    _artistLabel.textColor = backgroundDark ? [NSColor colorWithWhite:1.0 alpha:.9] : [NSColor colorWithWhite:70.0 / 255.0 alpha:.9];
    _albumLabel.textColor = backgroundDark ? [NSColor colorWithWhite:1.0 alpha:.9] : [NSColor colorWithWhite:70.0 / 255.0 alpha:.9];
}

- (void)setTrackInfo:(JWTrack *)trackInfo {
    if (_trackInfo != trackInfo) {
        _trackInfo = trackInfo;
        JWTagHelper *helper = [JWTagHelper helper];
        
        self.lrcLines = nil;
        self.lyricWidthConstraints.constant = 0;
        [self.lrcTableView reloadData];
        [self.view setNeedsLayout:YES];
        
        self.nameLabel.stringValue = trackInfo.Name;
        self.artistLabel.stringValue = trackInfo.Artist;
        self.albumLabel.stringValue = trackInfo.Album;
        self.coverImageView.image = [NSImage imageNamed:@"album"];
        [self.view.layer removeAllAnimations];
        self.view.layer.backgroundColor = [NSColor colorWithWhite:236.0 alpha:1.0].CGColor;
        [self refreshLabelsColorByTheme:NO];
        
        [helper getAlbumImageForTrack:trackInfo onComplete:^(NSImage *image, JWTrack *track, NSError *error) {
            if (image && !error) {
                if (track == _trackInfo) {
                    self.coverImageView.image = image;
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                         NSColor *mainColor = [image mainColor];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            CGFloat components[3];
                            [mainColor getHSBComponnets:components];
                            
                            CGFloat saturation = components[1];
                            CGFloat bright = components[2];
                            
                            [self refreshLabelsColorByTheme:bright < .5 || saturation > .5];
                            
                            CABasicAnimation *anime = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
                            anime.fromValue = (id)[self.view.layer backgroundColor];
                            anime.toValue = (__bridge id)(mainColor.CGColor);
                            anime.duration = 0.5f;
                            anime.fillMode = kCAFillModeForwards;
                            anime.removedOnCompletion = NO;
                            
                            [self.view.layer addAnimation:anime forKey:nil];

                        });
                    });
                }
            }
        }];
        
        [helper getLrcForTrack:trackInfo onComplete:^(NSString *lrc, JWTrack *track, NSError *error) {
            if (lrc && !error) {
                if (track == _trackInfo) {
                    JWLrcParser *parser = [[JWLrcParser alloc] initWithLRCString:lrc];
                    self.lrcLines = [parser parse];
                    self.lyricWidthConstraints.constant = 400;
                    [self.lrcTableView reloadData];
                }
            }
        }];
    }
}

- (void)setCurrentTimerInteval:(NSTimeInterval)currentTimerInteval {
    if (_currentTimerInteval != currentTimerInteval) {
        _currentTimerInteval = currentTimerInteval;
        if ([self.lrcLines count] > 0) {
            for(int i = 0; i < self.lrcLines.count; i++) {
                JWLrcObject *obj = self.lrcLines[i];
                NSTimeInterval dieta = currentTimerInteval - obj.timeInteval;
                if (dieta <= 0.5 && dieta >= -0.5 ) {
                    [self.lrcTableView scrollPoint:CGPointMake(0, i * 30 - 100)];
                    [self.lrcTableView scrollRowToVisible:i];
                    [self.lrcTableView reloadData];
                    break;
                }
            }
        }
    }
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.lrcLines count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    JWLrcObject *lrcObj = self.lrcLines[row];
    cellView.textField.stringValue = lrcObj.content;
    
    NSTimeInterval dieta = self.currentTimerInteval - lrcObj.timeInteval;
    if (dieta <= 0.5 && dieta >= -0.5 ) {
        cellView.textField.textColor = [NSColor colorWithRed:245.0 / 255.0 green:100.0 / 255.0 blue:20.0 / 255.0 alpha:1.0];
    } else {
        cellView.textField.textColor = [NSColor colorWithWhite:70.0 / 255.0 alpha:1.0];
    }
    
    return cellView;
}

@end
