//
//  MusicTrackModal.h
//  
//
//  Created by 王杰 on 15/10/18.
//
//

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

- (NSImage*)innerCoverImage;
+ (NSDictionary *)innerTagInfoForURL:(NSURL*)url;

@end
