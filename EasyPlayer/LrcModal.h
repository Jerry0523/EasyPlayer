//
//  LrcModal.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "CommonModal.h"

@interface LrcInfo : CommonModal

@property (assign, nonatomic) long aid;
@property (assign, nonatomic) long artist_id;
@property (assign, nonatomic) long sid;

@property (strong, nonatomic) NSString *lrc;
@property (strong, nonatomic) NSString *song;

@end