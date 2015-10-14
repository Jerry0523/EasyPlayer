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

- (NSString*)getAppRootPath;
- (NSString*)getLrcPath;
- (NSString*)getAlbumPath;

- (NSString*)keyForName:(NSString*)name artist:(NSString*)artist;

- (void)getLrcForName:(NSString*)name artist:(NSString*)artist onComplete:(void (^)(NSString*, NSString *key,NSError *))block;
- (void)getAlbumImageForName:(NSString*)name artist:(NSString*)artist onComplete:(void (^)(NSImage*, NSString *key, NSError *))block;

@end
