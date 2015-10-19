//
//  MusicFileManager.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/19.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWFileManager : NSObject

+ (NSString*)getAppRootPath;
+ (NSString*)getLrcPath;
+ (NSString*)getCoverPath;
+ (NSString*)getMusicPath;

@end
