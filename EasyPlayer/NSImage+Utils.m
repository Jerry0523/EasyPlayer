//
//  NSImage+Utils.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/15.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "NSImage+Utils.h"

@implementation NSImage (Utils)

- (CGImageRef) createCGImageRef {
    NSData *imageData;
    CGImageRef imageRef;
    @try {
        imageData = [self TIFFRepresentation];
        if (imageData) {
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
            NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     (id)kCFBooleanFalse, (id)kCGImageSourceShouldCache,
                                     (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat,
                                     nil];
            
            //要用这个带option的 kCGImageSourceShouldCache指出不需要系统做cache操作 默认是会做的
            imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, (CFDictionaryRef)options);
            CFRelease(imageSource);
            return imageRef;
        }else{
            return NULL;
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
    return NULL;
}

- (CGImageRef) createScaleImageByWidth:(CGFloat)width height:(CGFloat)height {
    CGContextRef content = MyCreateBitmapContext(width, height);
    CGContextDrawImage(content, CGRectMake(0, 0, width, height), [self createCGImageRef]);
    CGImageRef img = CGBitmapContextCreateImage(content);
    
    releaseMyContextData(content);
    
    return img;
}

- (NSColor*) mainColor {
    
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGContextRef context;
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
        CGContextDrawImage(context, drawRect, [self createCGImageRef]);
        CGColorSpaceRelease(colorSpace);
    }
    
    //第二步 取每个点的像素值
    unsigned char* data = CGBitmapContextGetData (context);
    
    if (data == NULL) return nil;
    
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
    
    
    //第三步 找到出现次数最多的那个颜色
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
    
    return [NSColor colorWithRed:([MaxColor[0] intValue]/255.0f) green:([MaxColor[1] intValue]/255.0f) blue:([MaxColor[2] intValue]/255.0f) alpha:([MaxColor[3] intValue] * .6 / 255.0f)];
}

CGContextRef MyCreateBitmapContext (int pixelsWide,
                                    int pixelsHigh)
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    GLubyte*bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    bitmapBytesPerRow = (pixelsWide * 4);
    bitmapByteCount = (bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);//CGColorSpaceCreateDeviceRGB();//
    
    //z这里初始化用malloc和calloc都可以 (注意:malloc只能分配内存 初始化所分配的内存空间 calloc则可以)
    //在此需要特别注意的是  第二个参数传0进去  如果传比较大的数值进去的话  则会内存泄漏 比如传8之类的就会出现大的泄漏问题
    /*如果调用成功,函数malloc()和函数calloc()都
     将返回所分配的内存空间的首地址。
     函数malloc()和函数calloc()的主要区别是前
     者不能初始化所分配的内存空间,而后者能。如
     果由malloc()函数分配的内存空间原来没有被
     使用过，则其中的每一位可能都是0;反之,如果
     这部分内存曾经被分配过,则其中可能遗留有各
     种各样的数据。也就是说，使用malloc()函数
     的程序开始时(内存空间还没有被重新分配)能
     正常进行,但经过一段时间(内存空间还已经被
     重新分配)可能会出现问题
     函数calloc()会将所分配的内存空间中的每一
     位都初始化为零,也就是说,如果你是为字符类
     型或整数类型的元素分配内存,那麽这些元素将
     保证会被初始化为0;如果你是为指针类型的元
     素分配内存,那麽这些元素通常会被初始化为空
     指针;如果你为实型数据分配内存,则这些元素
     会被初始化为浮点型的零*/
    //NSLog(@"%lu", sizeof(GLubyte));
    bitmapData = (GLubyte*)calloc(bitmapByteCount,sizeof(GLubyte));//or malloc(bitmapByteCount);//
    
    if (bitmapData == NULL) {
        fprintf(stderr, "Memory not allocated!");
        return NULL;
    }
    
    context = CGBitmapContextCreate(bitmapData,
                                    pixelsWide,
                                    pixelsHigh,
                                    8,
                                    bitmapBytesPerRow,
                                    colorSpace, 
                                    kCGImageAlphaPremultipliedLast);
    if (context == NULL) {
        free(bitmapData);
        fprintf(stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease(colorSpace);
    return context;
}

void releaseMyContextData(CGContextRef content){
    void *imgdata =CGBitmapContextGetData(content);
    CGContextRelease(content);
    if (imgdata) {
        free(imgdata);
    }
}

@end
