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
- (void) saveAsJPGFileForPath:(NSString*)path;
- (NSImage*)scaledImageForSize:(CGSize)size;

@end
