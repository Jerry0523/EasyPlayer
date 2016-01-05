//
//  JWHeader.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 16/1/4.
//  Copyright © 2016年 Jerry Wong. All rights reserved.
//

#ifndef JWHeader_h
#define JWHeader_h

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#define JWImage UIImage
#define JWColor UIColor
#import <UIKit/UIKit.h>
#else
#define JWImage NSImage
#define JWColor NSColor
#import <Cocoa/Cocoa.h>
#endif


#endif /* JWHeader_h */
