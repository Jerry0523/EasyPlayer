//
//  LrcHelper.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWTagInfo.h"
#import "JWTrack.h"
#import <Cocoa/Cocoa.h>

@interface JWTagHelper : NSObject

+ (instancetype)helper;

- (void)getLrcForTrack:(JWTrack*)track onComplete:(void (^)(NSString*, JWTrack *track, NSError *))block;
- (void)getAlbumImageForTrack:(JWTrack*)track onComplete:(void (^)(NSImage*, JWTrack *track, NSError *))block;

@end
