//
//  LrcModal.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LrcModal : NSObject<NSCoding>

+ (NSArray *)arrayFromJSON:(NSArray*)array;
- (instancetype)initFromDictionary:(NSDictionary*)json;

@end

@interface LrcInfo : LrcModal

@property (assign, nonatomic) long aid;
@property (assign, nonatomic) long artist_id;
@property (assign, nonatomic) long sid;

@property (strong, nonatomic) NSString *lrc;
@property (strong, nonatomic) NSString *song;

@end