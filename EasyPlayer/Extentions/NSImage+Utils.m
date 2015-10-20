//
//  NSImage+Utils.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/15.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "NSImage+Utils.h"

@implementation NSImage (Utils)

- (NSColor*) mainColor {
    
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGContextRef context = NULL;
    CGSize thumbSize = self.size;
    if (thumbSize.width > 50 || thumbSize.height > 50) {
        thumbSize = CGSizeMake(50, 50);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(NULL,
                                                     thumbSize.width,
                                                     thumbSize.height,
                                                     8,//bits per component
                                                     thumbSize.width*4,
                                                     colorSpace,
                                                     bitmapInfo);
        
        CGRect drawRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height);
        CGImageRef cgRef = [self CGImageForProposedRect:NULL
                                                context:nil
                                                  hints:nil];
        CGContextDrawImage(context, drawRect, cgRef);
        CGColorSpaceRelease(colorSpace);
    }

    unsigned char* data = CGBitmapContextGetData (context);
    
    if (data == NULL) {
        CGContextRelease(context);
        return nil;
    }
    
    NSCountedSet *cls=[NSCountedSet setWithCapacity:thumbSize.width*thumbSize.height];
    
    for (int x=0; x<thumbSize.width; x++) {
        for (int y=0; y<thumbSize.height; y++) {
            
            int offset = 4*(x*y);
            
            int red = data[offset];
            int green = data[offset+1];
            int blue = data[offset+2];
            int alpha =  data[offset+3];
            
            NSArray *clr=@[@(red),@(green),@(blue),@(alpha)];
            [cls addObject:clr];
            
        }
    }
    
    CGContextRelease(context);
    
    NSEnumerator *enumerator = [cls objectEnumerator];
    NSArray *curColor = nil;
    
    NSArray *MaxColor=nil;
    NSUInteger MaxCount=0;
    
    while ( (curColor = [enumerator nextObject]) != nil )
    {
        NSUInteger tmpCount = [cls countForObject:curColor];
        
        if ( tmpCount < MaxCount ) continue;
        
        MaxCount=tmpCount;
        MaxColor=curColor;
        
    }
    
    return [NSColor colorWithRed:([MaxColor[0] intValue]/255.0f) green:([MaxColor[1] intValue]/255.0f) blue:([MaxColor[2] intValue]/255.0f) alpha:([MaxColor[3] intValue] * .7 / 255.0f)];
}

- (void) saveAsJPGFileForPath:(NSString*)path {
    CGImageRef cgRef = [self CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[self size]];   // if you want the same resolution
    NSData *jpgData = [newRep representationUsingType:NSJPEGFileType properties:nil];
    if (path) {
        [jpgData writeToFile:path atomically:YES];
    }
}

- (NSImage*)scaledImageForSize:(CGSize)size {
    CGImageRef cgRef = [self CGImageForProposedRect:NULL
                                            context:nil
                                              hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:size];
    NSData *jpgData = [newRep representationUsingType:NSJPEGFileType properties:nil];
    return [[NSImage alloc] initWithData:jpgData];
}

@end
