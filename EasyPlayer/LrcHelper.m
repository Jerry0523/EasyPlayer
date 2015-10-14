//
//  LrcHelper.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "LrcHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@interface LrcHelper()

@property (nonatomic, strong) NSOperationQueue *completionQueue;

@end

@implementation LrcHelper

+ (instancetype)helper {
    static LrcHelper *_helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = [LrcHelper new];
    });
    return _helper;
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

- (NSString *)URLEncodedString:(NSString*)rawString {
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)rawString,
                                                              (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                              NULL,
                                                              kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString*)keyForName:(NSString*)name artist:(NSString*)artist {
    NSMutableString *mutable = [NSMutableString stringWithString:name];
    [mutable appendString:artist ? artist : @"NULL"];
    
    const char *cStr = [mutable UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (void)sendAsynchronousRequestForURL:(NSString*)url onComplete:(void (^)(id data, NSError *error, NSData *rawData))block {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self URLEncodedString:url]]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    request.HTTPMethod = @"GET";
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.completionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError * connectionError) {
        id json;
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

- (NSString*)getAppRootPath {
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

- (NSString*)getLrcPath {
    NSString *rootPath = [self getAppRootPath];
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

- (NSString*)getAlbumPath {
    NSString *rootPath = [self getAppRootPath];
    if (rootPath) {
        NSString *albumPath = [rootPath stringByAppendingPathComponent:@"album"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:albumPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:albumPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return albumPath;
    }
    return nil;
}

- (void)getLrcForName:(NSString*)name artist:(NSString*)artist onComplete:(void (^)(NSString*, NSString *key, NSError *))block {
    NSString *key = [self keyForName:name artist:artist];
    NSString *lrcPath = [self getLrcPath];
    if (lrcPath) {
        NSString *destination = [lrcPath stringByAppendingPathComponent:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
            NSString *lrcString = [NSString stringWithContentsOfFile:destination encoding:NSUTF8StringEncoding error:nil];
            if (block) {
                block(lrcString, key, nil);
            }
        } else {
            [self getSongInfoWithName:name artist:artist onComplete:^(LrcInfo *info, NSError *error) {
                if (info) {
                    [self downloadLrcInfo:info key:key onComplete:^(NSString *lrc, NSError *error) {
                        if (block) {
                            block(lrc, key, error);
                        }
                    }];
                } else {
                    if (block) {
                        block(nil, key, error);
                    }
                }
            }];
        }
        
    }
}

- (void)getAlbumImageForName:(NSString*)name artist:(NSString*)artist onComplete:(void (^)(NSImage*, NSString *key,NSError *))block {
    NSString *key = [self keyForName:name artist:artist];
    NSString *albumPath = [self getAlbumPath];
    if (albumPath) {
        NSString *destination = [albumPath stringByAppendingPathComponent:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:nil]) {
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:destination];
            if (block) {
                block(image, key, nil);
            }
        } else {
            [self getSongInfoWithName:name artist:artist onComplete:^(LrcInfo *info, NSError *error) {
                if (info) {
                    [self downloadAlbumCover:info key:key onComplete:^(NSImage *image, NSError *error) {
                        if (block) {
                            block(image, key, error);
                        }
                    }];
                } else {
                    if (block) {
                        block(nil, key, error);
                    }
                }
            }];
        }
        
    }
}

- (void)getSongInfoWithName:(NSString*)name artist:(NSString*)artist onComplete:(void (^)(LrcInfo *info, NSError *error))block {
    NSMutableString *url = [NSMutableString stringWithString:@"http://geci.me/api/lyric"];
    if (name) {
        [url appendFormat:@"/%@", name];
    }
    if (artist) {
        [url appendFormat:@"/%@", artist];
    }
    
    [self sendAsynchronousRequestForURL:url onComplete:^(id data, NSError *error, NSData *rawData) {
        LrcInfo *lrcInfo;
        if (data && [data[@"result"] count] > 0) {
            lrcInfo = [[LrcInfo alloc] initFromDictionary:[data[@"result"] firstObject]];
        }
        if (block) {
            block(lrcInfo, error);
        }
    }];
}

- (void)downloadLrcInfo:(LrcInfo*)info key:(NSString*)key onComplete:(void (^)(NSString*, NSError *))block {
    if (info.lrc) {
        [self sendAsynchronousRequestForURL:info.lrc onComplete:^(id data, NSError *error, NSData *rawData) {
            NSString *aString;
            if (!error && rawData) {
                aString = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
                NSString *lrcPath = [self getLrcPath];
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

- (void)downloadAlbumCover:(LrcInfo*)info key:(NSString*)key onComplete:(void (^)(NSImage*, NSError *))block {
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
                    
                    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                                             context:nil
                                                               hints:nil];
                    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
                    [newRep setSize:[image size]];   // if you want the same resolution
                    NSData *jpgData = [newRep representationUsingType:NSJPEGFileType properties:nil];
                    NSString *albumPath = [self getAlbumPath];
                    if (albumPath) {
                        NSString *destination = [albumPath stringByAppendingPathComponent:key];
                        [jpgData writeToFile:destination atomically:YES];
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
