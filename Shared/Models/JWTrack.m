//
//  MusicTrackModal.m
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

#import "JWTrack.h"
#import "NSString+Comparator.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <AudioToolbox/AudioToolbox.h>

#import <Availability.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MediaPlayer/MediaPlayer.h>
#else
#import <iTunesLibrary/ITLibMediaItem.h>
#import <iTunesLibrary/ITLibAlbum.h>
#import <iTunesLibrary/ITLibArtist.h>
#endif

@implementation JWTrack

#if __IPHONE_OS_VERSION_MIN_REQUIRED

#else
- (instancetype)initWithITMediaItem:(ITLibMediaItem *)mediaItem
{
    if (self = [super init]) {
        self.album = mediaItem.album.title ?: @"";
        self.artist = mediaItem.artist.name ?: @"";
        self.location = mediaItem.location.absoluteString;
        self.name = mediaItem.title;
        self.totalTime = mediaItem.totalTime;
    }
    return self;
}
#endif

- (instancetype)initFromID3Info:(NSDictionary*)info url:(NSURL*)fileURL{
    if (self = [super init]) {
        NSString *album = info[@"album"];
        NSString *artist = info[@"artist"];
        NSString *title = info[@"title"];
        NSString *file = [fileURL absoluteString];
        
        self.album = album ? album : @"";
        self.artist = artist ? artist : @"";
        self.location = file;
        
        if (!title) {
            NSString *filename = [[file lastPathComponent] stringByDeletingPathExtension];
            filename = [filename stringByRemovingPercentEncoding];
            self.name = filename;
        } else {
            self.name = title;
        }
        
        self.totalTime = [info[@"approximate duration in seconds"] doubleValue] * 1000;
    }
    return self;
}

- (instancetype)initFromDictionary:(NSDictionary *)json {
    if (self = [super initFromDictionary:json]) {
        if (!self.name) {
            self.name = @"";
        }
        if (!self.artist) {
            self.artist = @"";
        }
        if (!self.album) {
            self.album = @"";
        }
    }
    return self;
}

- (NSString*)pathExtention {
    NSArray *components = [self.location componentsSeparatedByString:@"."];
    if ([components count] < 2) {
        return nil;
    }
    return [components lastObject];
}

- (NSInteger)compares:(JWTrack*)track sortType:(TrackSortType)sortType {
    NSString *key = @"name";
    if (sortType == TrackSortTypeArtist) {
        key = @"artist";
    } else if(sortType == TrackSortTypeAlbum) {
        key = @"album";
    }
    
    NSString *s0 = [self valueForKey:key];
    NSString *s1 = [track valueForKey:key];
    
    return [s0 compares:s1];
}

- (BOOL)respondToSearch:(NSString *)search {
    return [[self.name lowercaseString] rangeOfString:search].location != NSNotFound ||
        [[self.album lowercaseString] rangeOfString:search].location != NSNotFound ||
    [[self.artist lowercaseString] rangeOfString:search].location != NSNotFound;
}

- (NSString*)cacheKey {
    NSMutableString *mutable = [NSMutableString stringWithString:_name];
    [mutable appendString:_artist ? _artist : @"NULL"];
    
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

- (NSURL*)fileURL {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    MPMediaItem *item = self.userInfo;
    return [item valueForProperty:MPMediaItemPropertyAssetURL];
#else
    if(self.location) {
        return [NSURL URLWithString:self.location];
    }
    return nil;
#endif
   
}

@end
