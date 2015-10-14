//
//  MusicProgressView.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "MusicProgressView.h"

@implementation MusicProgressView

- (void)setProgress:(CGFloat)progress {
    if (_progress != progress) {
        _progress = progress;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    NSColor *color = [NSColor colorWithRed:245.0 / 255.0 green:100.2 / 255.0 blue:20.0 / 255.0 alpha:1.0];
    [color setFill];
    CGContextFillRect(context, CGRectMake(0, 0, dirtyRect.size.width * self.progress, dirtyRect.size.height));
}

@end
