//
//  MusicInfoViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import "MusicInfoViewController.h"
#import "JWMediaHelper.h"
#import "NSImage+Utils.h"
#import "JWLrcParser.h"
#import "NSColor+Components.h"

@interface MusicInfoViewController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *lrcTableView;
@property (weak) IBOutlet NSLayoutConstraint *lyricWidthConstraints;

@property (strong, nonatomic) NSArray<JWLrcObject *> *lrcLines;
@property (strong, nonatomic) NSArray<NSString *> *plainLrcLines;

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
        
        self.lrcLines = nil;
        self.lyricWidthConstraints.constant = 0;
        [self.lrcTableView reloadData];
        [self.view setNeedsLayout:YES];
        
        self.nameLabel.stringValue = trackInfo.name;
        self.artistLabel.stringValue = trackInfo.artist;
        self.albumLabel.stringValue = trackInfo.album;
        self.coverImageView.image = [NSImage imageNamed:@"album"];
        [self.view.layer removeAllAnimations];
        self.view.layer.backgroundColor = [NSColor colorWithWhite:236.0 alpha:1.0].CGColor;
        [self refreshLabelsColorByTheme:NO];
        
        [JWMediaHelper getAlbumImageForTrack:trackInfo onComplete:^(NSImage *image, JWTrack *track, NSError *error) {
            if (image && !error) {
                if (track == self.trackInfo) {
                    self.coverImageView.image = image;
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                         NSColor *mainColor = [image mainColor];
                        CGFloat components[3];
                        [mainColor getHSBComponnets:components];
                        
                        CGFloat saturation = components[1];
                        CGFloat bright = components[2];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self refreshLabelsColorByTheme:bright < .5 || saturation > .5];
                            self.view.layer.backgroundColor = mainColor.CGColor;
                            
//                            CABasicAnimation *anime = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
//                            anime.fromValue = (id)[self.view.layer backgroundColor];
//                            anime.toValue = (__bridge id _Nullable)(mainColor.CGColor);
//                            anime.duration = 1.0f;
//                            anime.fillMode = kCAFillModeForwards;
//                            anime.removedOnCompletion = NO;
//
//                            [self.view.layer addAnimation:anime forKey:anime.keyPath];
                        });
                    });
                }
            }
        }];
        
        [JWMediaHelper getLrcForTrack:trackInfo onComplete:^(NSString *lrc, JWTrack *track, NSError *error) {
            if (lrc && !error) {
                if (track == self.trackInfo) {
                    JWLrcParser *parser = [[JWLrcParser alloc] initWithLRCString:lrc];
                    NSArray *lrcLines = [parser parse];
                    if (lrcLines.count > 1) {
                        self.lrcLines = lrcLines;
                    } else {
                        self.lrcLines = nil;
                        self.plainLrcLines = [lrc componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    }
                    
                    self.lyricWidthConstraints.constant = 450;
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
    if (self.lrcLines) {
        return self.lrcLines.count;
    }
    return self.plainLrcLines.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if (self.lrcLines.count > row) {
        JWLrcObject *lrcObj = self.lrcLines[row];
        cellView.textField.stringValue = lrcObj.content;
        
        NSTimeInterval dieta = self.currentTimerInteval - lrcObj.timeInteval;
        if (dieta <= 0.5 && dieta >= -0.5 ) {
            cellView.textField.textColor = [NSColor colorWithRed:245.0 / 255.0 green:100.0 / 255.0 blue:20.0 / 255.0 alpha:1.0];
        } else {
            cellView.textField.textColor = [NSColor colorWithWhite:70.0 / 255.0 alpha:1.0];
        }
    } else {
        cellView.textField.stringValue = self.plainLrcLines[row];
        cellView.textField.textColor = [NSColor colorWithWhite:70.0 / 255.0 alpha:1.0];
    }
    
    return cellView;
}

@end
