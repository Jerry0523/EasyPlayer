//
//  PlayListCell.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 16/1/4.
//  Copyright © 2016年 Jerry Wong. All rights reserved.
//

#import "PlayListCell.h"

@implementation PlayListCell

- (UILabel*)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont systemFontOfSize:11.0];
        _detailLabel.textColor = [UIColor darkGrayColor];
        _detailLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:_detailLabel];
    }
    return _detailLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIView *selectedView = [[UIView alloc] initWithFrame:self.bounds];
        selectedView.backgroundColor = [UIColor colorWithRed:245.0 / 255.0 green:100.0 / 255.0 blue:20.0 / 255.0 alpha:1.0];
        self.selectedBackgroundView = selectedView;
        self.textLabel.highlightedTextColor = [UIColor whiteColor];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    self.imageView.frame = CGRectMake(5, 5, height - 10, height - 10);
    self.textLabel.frame = CGRectMake(height, 0, width - height, height * .6);
    self.detailLabel.frame = CGRectMake(height, height * .6, width - height, height * .3);
}

@end
