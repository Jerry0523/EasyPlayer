//
//  NSImage+Utils.m
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

#import "NSImage+Utils.h"

@implementation JWImage (Utils)

- (JWColor*) mainColor {
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
        CGImageRef cgRef;
#if __IPHONE_OS_VERSION_MIN_REQUIRED
        cgRef = self.CGImage;
#else
        cgRef = [self CGImageForProposedRect:NULL
                                           context:nil
                                                  hints:nil];
#endif
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
    
    return [JWColor colorWithRed:([MaxColor[0] intValue]/255.0f) green:([MaxColor[1] intValue]/255.0f) blue:([MaxColor[2] intValue]/255.0f) alpha:([MaxColor[3] intValue] * .7 / 255.0f)];
}

- (void) saveAsJPGFileForPath:(NSString*)path {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    [UIImagePNGRepresentation(self) writeToFile:path atomically:YES];
#else
    
    CGImageRef cgRef = [self CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[self size]];   // if you want the same resolution
    NSData *jpgData = [newRep representationUsingType:NSJPEGFileType properties:@{}];
    if (path) {
        [jpgData writeToFile:path atomically:YES];
    }
#endif
}

- (JWImage*)scaledImageForSize:(CGSize)size {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    JWImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
#else
    CGImageRef cgRef = [self CGImageForProposedRect:NULL
                                            context:nil
                                              hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:size];
    NSData *jpgData = [newRep representationUsingType:NSJPEGFileType properties:@{}];
    return [[JWImage alloc] initWithData:jpgData];
#endif
}

@end
