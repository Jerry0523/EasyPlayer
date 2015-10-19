//
//  MusicTrackModal.h
//  
//
//  Created by 王杰 on 15/10/18.
//
//

#import "CommonModal.h"

@interface MusicTrackModal : CommonModal

@property (nonatomic, strong) NSString *Name;
@property (nonatomic, strong) NSString *Artist;
@property (nonatomic, strong) NSString *Album;
@property (nonatomic, strong) NSString *Location;
@property (nonatomic, assign) double TotalTime;

- (NSString*)pathExtention;
- (NSInteger)compares:(MusicTrackModal*)track;

- (BOOL)respondToSearch:(NSString*)search;

- (NSData*)musicData;

@end
