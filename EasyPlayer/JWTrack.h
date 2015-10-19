//
//  MusicTrackModal.h
//  
//
//  Created by 王杰 on 15/10/18.
//
//

#import "JWModal.h"

@interface JWTrack : JWModal

@property (nonatomic, strong) NSString *Name;
@property (nonatomic, strong) NSString *Artist;
@property (nonatomic, strong) NSString *Album;
@property (nonatomic, strong) NSString *Location;
@property (nonatomic, assign) double TotalTime;

- (NSString*)pathExtention;
- (NSInteger)compares:(JWTrack*)track;

- (BOOL)respondToSearch:(NSString*)search;

- (NSData*)musicData;
- (NSString*)cacheKey;

@end
