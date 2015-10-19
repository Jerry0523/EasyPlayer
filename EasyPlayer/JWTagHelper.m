//
//  LrcHelper.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "JWTagHelper.h"
#import "NSImage+Utils.h"
#import "JWFileManager.h"

#import <AudioToolbox/AudioToolbox.h>

@interface JWTagHelper()

@property (nonatomic, strong) NSOperationQueue *completionQueue;

@end

@implementation JWTagHelper

+ (instancetype)helper {
    static JWTagHelper *_helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = [JWTagHelper new];
    });
    return _helper;
}

+ (NSString *)URLEncodedString:(NSString*)rawString {
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)rawString,
                                                              (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                              NULL,
                                                              kCFStringEncodingUTF8));
    return encodedString;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.completionQueue = [NSOperationQueue new];
        [self.completionQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    }
    return self;
}

- (void)sendAsynchronousRequestForURL:(NSString*)url onComplete:(void (^)(id data, NSError *error, NSData *rawData))block {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[JWTagHelper URLEncodedString:url]]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    request.HTTPMethod = @"GET";
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.completionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        id json;
        if ([response isKindOfClass:[NSHTTPURLResponse class]] && ((NSHTTPURLResponse*)response).statusCode == 404 && !connectionError) {
            connectionError = [NSError errorWithDomain:@"" code:404 userInfo:@{}];
        }
        if (!connectionError) {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(json, connectionError, data);
            });
        }
    }];
}

- (void)getLrcForTrack:(JWTrack*)track onComplete:(void (^)(NSString*, JWTrack *, NSError *))block {
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
            [self getSongInfoForTrack:track onComplete:^(JWTagInfo *info, NSError *error) {
                if (info) {
                    [self downloadLrcInfo:info key:cachedKey onComplete:^(NSString *lrc, NSError *error) {
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

- (NSImage*)getInnerAlbumImageForURL:(NSString*)url {
    NSURL *fileURL = [NSURL URLWithString:url];
    AudioFileID audioFile;
    OSStatus theErr = noErr;
    theErr = AudioFileOpenURL((__bridge CFURLRef)fileURL,
                              kAudioFileReadPermission,
                              kAudioFileMP3Type,
                              &audioFile);
    
    if (theErr != noErr) {
        return nil;
    }
    

    
    CFDataRef albumPic = nil;
    UInt32 picDataSize;
    theErr = AudioFileGetProperty(audioFile, kAudioFilePropertyAlbumArtwork, &picDataSize, &albumPic);
    if(theErr != noErr ){
        return nil;
    }
    NSData *imagedata = (__bridge NSData*)albumPic;
    CFRelease(albumPic);
    return [[NSImage alloc] initWithData:imagedata];
    
    
//    UInt32 dictionarySize = 0;
//    theErr = AudioFileGetPropertyInfo (audioFile,
//                                       kAudioFilePropertyInfoDictionary,
//                                       &dictionarySize,
//                                       0);
//    assert (theErr == noErr);
//    CFDictionaryRef dictionary;
//    theErr = AudioFileGetProperty (audioFile,
//                                   kAudioFilePropertyInfoDictionary,
//                                   &dictionarySize,
//                                   &dictionary);
//    assert (theErr == noErr);
//    resultDic = (__bridge NSDictionary *)(dictionary);  //Convert
//    CFRelease (dictionary);
//    theErr = AudioFileClose (audioFile);
//    assert (theErr == noErr);
}

- (void)getAlbumImageForTrack:(JWTrack*)track onComplete:(void (^)(NSImage*, JWTrack *track, NSError *))block {
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
            NSImage *albumImg = [self getInnerAlbumImageForURL:track.Location];
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
                [self getSongInfoForTrack:track onComplete:^(JWTagInfo *info, NSError *error) {
                    if (info) {
                        [self downloadAlbumCover:info key:cachedKey onComplete:^(NSImage *image, NSError *error) {
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

- (void)getSongInfoForTrack:(JWTrack*)track onComplete:(void (^)(JWTagInfo *info, NSError *error))block {
    NSMutableString *url = [NSMutableString stringWithString:@"http://geci.me/api/lyric"];
    if (track.Name) {
        [url appendFormat:@"/%@", track.Name];
    }
    if (track.Artist) {
        [url appendFormat:@"/%@", track.Artist];
    }
    
    [self sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
        JWTagInfo *lrcInfo;
        if (data && [data[@"result"] count] > 0) {
            lrcInfo = [[JWTagInfo alloc] initFromDictionary:[data[@"result"] firstObject]];
        }
        if (block) {
            block(lrcInfo, error);
        }
    }];
}

- (void)downloadLrcInfo:(JWTagInfo*)info key:(NSString*)key onComplete:(void (^)(NSString*, NSError *))block {
    if (info.lrc) {
        [self sendAsynchronousRequestForURL:info.lrc onComplete:^(id data, NSError *error, NSData *rawData) {
            NSString *aString;
            if (!error && rawData) {
                aString = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
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

- (void)downloadAlbumCover:(JWTagInfo*)info key:(NSString*)key onComplete:(void (^)(NSImage*, NSError *))block {
    if (info.aid) {
        NSString *url = [NSString stringWithFormat:@"http://geci.me/api/cover/%ld", info.aid];
        [self sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
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
