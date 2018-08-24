//
//  LrcHelper.m
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

#import "JWMediaHelper.h"
#import "NSImage+Utils.h"
#import "JWFileManager.h"
#import "JWNetworkHelper.h"
#import "JWMInputUnit.h"

@implementation JWMediaHelper

+ (void)cacheAlbumImageForTrack:(JWTrack*)track force:(BOOL)force
{
    NSString *albumPath = [JWFileManager getCoverPath];
    NSString *destination = [albumPath stringByAppendingPathComponent:[track cacheKey]];
    if (!force && [[NSFileManager defaultManager] fileExistsAtPath:destination]) {
        return;
    }
    JWMInputUnit *inputUnit = [[JWMInputUnit alloc] init];
    if ([inputUnit openWithUrl:track.fileURL]) {
        NSDictionary *meta = [inputUnit metadata];
        if(meta) {
            [self cacheAlbumImageForTrack:track meta:meta];
        }
        [inputUnit close];
    }
}

+ (void)cacheAlbumImageForTrack:(JWTrack*)track meta:(NSDictionary*)meta
{
    if (meta[@"picture"]) {
        JWImage *coverImg = [[JWImage alloc] initWithData:meta[@"picture"]];
        NSString *albumPath = [JWFileManager getCoverPath];
        if (albumPath) {
            NSString *destination = [albumPath stringByAppendingPathComponent:[track cacheKey]];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [coverImg saveAsJPGFileForPath:destination];
            });
        }
    }
}

+ (void)scanSupportedMediaForFileURL:(NSURL*)fileURL into:(NSMutableArray*)array {
    JWMInputUnit *inputUnit = [[JWMInputUnit alloc] init];
    if ([inputUnit openWithUrl:fileURL]) {
        NSDictionary *meta = [inputUnit metadata];
        if(meta) {
            JWTrack *track = [[JWTrack alloc] initFromID3Info:meta url:fileURL];
            track.sourceType = TrackSourceTypeLocal;
            [array addObject:track];
            [self cacheAlbumImageForTrack:track meta:meta];
        }
        [inputUnit close];
    } else {
        return;
    }
}

+ (void)getLrcForTrack:(JWTrack*)track onComplete:(void (^)(NSString*, JWTrack *, NSError *))block {
    NSString *lrcPath = [JWFileManager getLrcPath];
    NSString *cachedKey = [track cacheKey];
    if (lrcPath) {
        NSString *destination = [lrcPath stringByAppendingPathComponent:[track cacheKey]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
            NSString *lrcString = [NSString stringWithContentsOfFile:destination encoding:NSUTF8StringEncoding error:nil];
            if (block) {
                block(lrcString, track, nil);
            }
        } else {
            [self getBaiduInfoForTrack:track onComplete:^(NSInteger lrcId, NSError *error) {
                if (lrcId > 0) {
                    [self downloadBaiduLrcInfo:lrcId key:cachedKey onComplete:^(NSString *lrc, NSError *error) {
                        if (block) {
                            block(lrc, track, error);
                        }
                    }];
                } else {
                    if (block) {
                        block(nil, track, error);
                    }
                }
            }];
        }
        
    }
}

+ (void)getAlbumImageForTrack:(JWTrack*)track onComplete:(void (^)(JWImage*, JWTrack *track, NSError *))block {
    NSString *cachedKey = [track cacheKey];
    NSString *albumPath = [JWFileManager getCoverPath];
    if (albumPath) {
        NSString *destination = [albumPath stringByAppendingPathComponent:cachedKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
            JWImage *image = [[JWImage alloc] initWithContentsOfFile:destination];
            if (block) {
                block(image, track, nil);
            }
        } else {
            [self getGeCiMiSongInfoForTrack:track onComplete:^(JWTagInfo *info, NSError *error) {
                if (info) {
                    [self downloadGeCiMiAlbumCover:info key:cachedKey onComplete:^(JWImage *image, NSError *error) {
                        if (block) {
                            block(image, track, error);
                        }
                    }];
                } else {
                    if (block) {
                        block(nil, track, error);
                    }
                }
            }];
        }
        
    }
}

+ (void)getBaiduInfoForTrack:(JWTrack*)track onComplete:(void (^)(NSInteger lrcId, NSError *error))block {
    NSMutableString *url = [NSMutableString stringWithString:@"http://box.zhangmen.baidu.com/x?op=12&count=1&title="];
    if (track.name) {
        [url appendFormat:@"%@$$", track.name];
    }
    if (track.artist) {
        [url appendFormat:@"%@$$$$", track.artist];
    }
    
    [[JWNetworkHelper helper] sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
        NSInteger lrcId = 0;
        if (!error) {
            NSString *rawString = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
            NSRange startRange = [rawString rangeOfString:@"<lrcid>"];
            if (startRange.location != NSNotFound) {
                NSRange endRange = [rawString rangeOfString:@"</lrcid>"];
                if (endRange.location != NSNotFound) {
                    lrcId = [[rawString substringWithRange:NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length)] integerValue];
                }
            }
        }
        block(lrcId, error);
    }];
}

+ (void)getGeCiMiSongInfoForTrack:(JWTrack*)track onComplete:(void (^)(JWTagInfo *info, NSError *error))block {
    NSMutableString *url = [NSMutableString stringWithString:@"http://geci.me/api/lyric"];
    if (track.name) {
        [url appendFormat:@"/%@", track.name];
    }
    if (track.artist) {
        [url appendFormat:@"/%@", track.artist];
    }
    
    [[JWNetworkHelper helper] sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
        JWTagInfo *lrcInfo;
        if (data && [data[@"result"] count] > 0) {
            lrcInfo = [[JWTagInfo alloc] initFromDictionary:[data[@"result"] firstObject]];
        }
        if (block) {
            block(lrcInfo, error);
        }
    }];
}

+ (void)downloadBaiduLrcInfo:(NSInteger)lrcId key:(NSString*)key onComplete:(void (^)(NSString*, NSError *))block {
    if (lrcId > 0) {
        NSString *url = [NSString stringWithFormat:@"http://box.zhangmen.baidu.com/bdlrc/%ld/%ld.lrc", lrcId / 100, (long)lrcId];
        [[JWNetworkHelper helper] sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
            NSString *aString;
            if (!error && rawData) {
                aString = [[NSString alloc] initWithData:rawData encoding:CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000)];
                NSString *lrcPath = [JWFileManager getLrcPath];
                if (lrcPath) {
                    NSString *destination = [lrcPath stringByAppendingPathComponent:key];
                    [aString writeToFile:destination atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }
            if (block) {
                block(aString, error);
            }
        }];
    }
}

+ (void)downloadGeCiMiAlbumCover:(JWTagInfo*)info key:(NSString*)key onComplete:(void (^)(JWImage*, NSError *))block {
    if (info.aid) {
        NSString *url = [NSString stringWithFormat:@"http://geci.me/api/cover/%ld", info.aid];
        [[JWNetworkHelper helper] sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
            if (!error && data && data[@"result"][@"cover"]) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    NSURL *imgURL = [NSURL URLWithString:data[@"result"][@"cover"]];
                    NSData *data = [NSData dataWithContentsOfURL:imgURL];
                    JWImage *image = [[JWImage alloc] initWithData:data];
                    if (block) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(image, nil);
                        });
                    }
                    NSString *albumPath = [JWFileManager getCoverPath];
                    if (albumPath) {
                        NSString *destination = [albumPath stringByAppendingPathComponent:key];
                        [image saveAsJPGFileForPath:destination];
                    }
                });
            } else {
                if (block) {
                    block(nil, error);
                }
            }
        }];
    }
}

@end
