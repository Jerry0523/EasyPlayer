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
#import "ORGMInputUnit.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation JWMediaHelper

+ (NSImage*)innerCoverImageForURL:(NSURL*)fileURL {
    AudioFileID audioFile;
    OSStatus theErr = noErr;
    theErr = AudioFileOpenURL((__bridge CFURLRef)fileURL,
                              kAudioFileReadPermission,
                              kAudioFileMP3Type,
                              &audioFile);
    
    if (theErr != noErr) {
        return nil;
    }
    UInt32 picDataSize = 0;
    theErr = AudioFileGetPropertyInfo (audioFile,
                                       kAudioFilePropertyInfoDictionary,
                                       &picDataSize,
                                       0);
    if (theErr != noErr) {
        return nil;
    }
    
    CFDataRef albumPic;
    theErr = AudioFileGetProperty(audioFile, kAudioFilePropertyAlbumArtwork, &picDataSize, &albumPic);
    if(theErr != noErr ){
        return nil;
    }
    NSData *imagedata = (__bridge NSData*)albumPic;
    CFRelease(albumPic);
    theErr = AudioFileClose (audioFile);
    
    return [[NSImage alloc] initWithData:imagedata];
}

+ (NSDictionary *)id3InfoForURL:(NSURL*)fileURL {
    NSString *pathExtension = [[fileURL pathExtension] lowercaseString];
    if ([pathExtension isEqualToString:@"flac"]) {
        ORGMInputUnit *inputUnit = [[ORGMInputUnit alloc] init];
        if ([inputUnit openWithUrl:fileURL]) {
            NSDictionary *meta = [inputUnit metadata];
            [inputUnit close];
            return meta;
        } else {
            return nil;
        }
    }
    
    AudioFileID audioFile;
    OSStatus theErr = noErr;
    theErr = AudioFileOpenURL((__bridge CFURLRef)fileURL,
                              kAudioFileReadPermission,
                              kAudioFileMP3Type,
                              &audioFile);
    
    if (theErr != noErr) {
        return nil;
    }
    
    UInt32 dictionarySize = 0;
    theErr = AudioFileGetPropertyInfo (audioFile,
                                       kAudioFilePropertyInfoDictionary,
                                       &dictionarySize,
                                       0);
    if (theErr != noErr) {
        return nil;
    }
    
    CFDictionaryRef dictionary;
    theErr = AudioFileGetProperty (audioFile,
                                   kAudioFilePropertyInfoDictionary,
                                   &dictionarySize,
                                   &dictionary);
    if (theErr != noErr) {
        return nil;
    }
    
    NSDictionary *resultDic = (__bridge NSDictionary *)(dictionary);  //Convert
    CFRelease (dictionary);
    theErr = AudioFileClose (audioFile);
    
    return resultDic;
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
            
            
//            [self getSongInfoForTrack:track onComplete:^(JWTagInfo *info, NSError *error) {
//                if (info) {
//                    [self downloadLrcInfo:info key:cachedKey onComplete:^(NSString *lrc, NSError *error) {
//                        if (block) {
//                            block(lrc, track, error);
//                        }
//                    }];
//                } else {
//                    if (block) {
//                        block(nil, track, error);
//                    }
//                }
//            }];
        }
        
    }
}

+ (void)getAlbumImageForTrack:(JWTrack*)track onComplete:(void (^)(NSImage*, JWTrack *track, NSError *))block {
    NSString *cachedKey = [track cacheKey];
    NSString *albumPath = [JWFileManager getCoverPath];
    if (albumPath) {
        NSString *destination = [albumPath stringByAppendingPathComponent:cachedKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:destination];
            if (block) {
                block(image, track, nil);
            }
        } else {
            NSImage *albumImg = [self innerCoverImageForURL:[track fileURL]];
            if (albumImg) {
                if (block) {
                    block(albumImg, track, nil);
                }
                NSString *albumPath = [JWFileManager getCoverPath];
                if (albumPath) {
                    NSString *destination = [albumPath stringByAppendingPathComponent:cachedKey];
                    [albumImg saveAsJPGFileForPath:destination];
                }
                
            } else {
                [self getGeCiMiSongInfoForTrack:track onComplete:^(JWTagInfo *info, NSError *error) {
                    if (info) {
                        [self downloadGeCiMiAlbumCover:info key:cachedKey onComplete:^(NSImage *image, NSError *error) {
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
}

+ (void)getBaiduInfoForTrack:(JWTrack*)track onComplete:(void (^)(NSInteger lrcId, NSError *error))block {
    NSMutableString *url = [NSMutableString stringWithString:@"http://box.zhangmen.baidu.com/x?op=12&count=1&title="];
    if (track.Name) {
        [url appendFormat:@"%@$$", track.Name];
    }
    if (track.Artist) {
        [url appendFormat:@"%@$$$$", track.Artist];
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
    if (track.Name) {
        [url appendFormat:@"/%@", track.Name];
    }
    if (track.Artist) {
        [url appendFormat:@"/%@", track.Artist];
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

//- (void)downloadLrcInfo:(JWTagInfo*)info key:(NSString*)key onComplete:(void (^)(NSString*, NSError *))block {
//    if (info.lrc) {
//        [self sendAsynchronousRequestForURL:info.lrc onComplete:^(id data, NSError *error, NSData *rawData) {
//            NSString *aString;
//            if (!error && rawData) {
//                aString = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
//                NSString *lrcPath = [JWFileManager getLrcPath];
//                if (lrcPath) {
//                    NSString *destination = [lrcPath stringByAppendingPathComponent:key];
//                    [aString writeToFile:destination atomically:YES encoding:NSUTF8StringEncoding error:nil];
//                }
//            }
//            if (block) {
//                block(aString, error);
//            }
//        }];
//    }
//}

+ (void)downloadGeCiMiAlbumCover:(JWTagInfo*)info key:(NSString*)key onComplete:(void (^)(NSImage*, NSError *))block {
    if (info.aid) {
        NSString *url = [NSString stringWithFormat:@"http://geci.me/api/cover/%ld", info.aid];
        [[JWNetworkHelper helper] sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
            if (!error && data && data[@"result"][@"cover"]) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    NSURL *imgURL = [NSURL URLWithString:data[@"result"][@"cover"]];
                    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imgURL];
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
