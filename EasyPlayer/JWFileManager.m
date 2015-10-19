//
//  MusicFileManager.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/19.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "JWFileManager.h"

@implementation JWFileManager

+ (NSString*)getAppRootPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES);
    if(paths.count > 0) {
        NSString *musicRootPath = [paths firstObject];
        NSString *appRootPath = [musicRootPath stringByAppendingPathComponent:@"EasyPlayer"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:appRootPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:appRootPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return appRootPath;
    }
    return nil;
}

+ (NSString*)getLrcPath {
    NSString *rootPath = [JWFileManager getAppRootPath];
    if (rootPath) {
        NSString *lrcPath = [rootPath stringByAppendingPathComponent:@"lrc"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:lrcPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:lrcPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return lrcPath;
    }
    return nil;
}

+ (NSString*)getCoverPath {
    NSString *rootPath = [JWFileManager getAppRootPath];
    if (rootPath) {
        NSString *albumPath = [rootPath stringByAppendingPathComponent:@"cover"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:albumPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:albumPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return albumPath;
    }
    return nil;
}

+ (NSString*)getMusicPath {
    NSString *rootPath = [JWFileManager getAppRootPath];
    if (rootPath) {
        NSString *musicPath = [rootPath stringByAppendingPathComponent:@"music"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:musicPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:musicPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return musicPath;
    }
    return nil;
}


@end
