//
//  MusicTrackModal.h
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

#import "JWModal.h"
#import <Cocoa/Cocoa.h>

typedef enum{
    TrackSortTypeDefault = 0,
    TrackSortTypeArtist,
    TrackSortTypeAlbum
} TrackSortType;

typedef enum{
    TrackPlayModeRandom = 0,
    TrackPlayModeSingle
} TrackPlayMode;

typedef enum{
    TrackSourceTypeItunes = 0,
    TrackSourceTypeLocal
} TrackSourceType;

@interface JWTrack : JWModal

@property (nonatomic, strong) NSString *Name;
@property (nonatomic, strong) NSString *Artist;
@property (nonatomic, strong) NSString *Album;
@property (nonatomic, strong) NSString *Location;
@property (nonatomic, assign) double TotalTime;
@property (nonatomic, assign) TrackSourceType sourceType;

- (instancetype)initFromID3Info:(NSDictionary*)info url:(NSURL*)fileURL;

- (NSString*)pathExtention;
- (NSInteger)compares:(JWTrack*)track sortType:(TrackSortType)sortType;

- (BOOL)respondToSearch:(NSString*)search;

- (NSData*)musicData;
- (NSString*)cacheKey;

- (NSURL*)fileURL;

@end
