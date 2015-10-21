//
//  JWPlayer.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/21.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JWPlayer;

@protocol JWPlayerDelegate <NSObject>

- (void)errorDidOccur:(JWPlayer*)player;
- (void)didFinishPlaying:(JWPlayer*)player;

@end

@interface JWPlayer : NSObject

@property (nonatomic, weak) id<JWPlayerDelegate> delegate;

- (BOOL)playWithURL:(NSURL*)fileURL;
- (void)pause;
- (void)resume;
- (void)stop;

- (BOOL)isPlaying;
- (NSTimeInterval)currentTime;
- (NSTimeInterval)totalTime;

@end
