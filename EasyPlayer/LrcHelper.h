//
//  LrcHelper.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LrcModal.h"
#import <Cocoa/Cocoa.h>

@interface LrcHelper : NSObject

+ (instancetype)helper;
+ (NSString*)keyForName:(NSString*)name artist:(NSString*)artist;

+ (NSString*)getAppRootPath;
+ (NSString*)getLrcPath;
+ (NSString*)getCoverPath;



- (void)getLrcForName:(NSString*)name artist:(NSString*)artist onComplete:(void (^)(NSString*, NSString *key,NSError *))block;
- (void)getAlbumImageForName:(NSString*)name artist:(NSString*)artist url:(NSString*)location onComplete:(void (^)(NSImage*, NSString *key, NSError *))block;

@end
