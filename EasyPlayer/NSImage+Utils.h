//
//  NSImage+Utils.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/15.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Utils)

- (NSColor*) mainColor;

- (CGImageRef) createCGImageRef;
- (CGImageRef) createScaleImageByWidth:(CGFloat)width height:(CGFloat)height;

@end
