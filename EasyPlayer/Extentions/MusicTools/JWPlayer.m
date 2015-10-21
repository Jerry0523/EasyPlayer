//
//  JWPlayer.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/21.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

#import "JWPlayer.h"
#import "ORGMEngine.h"
#import <AVFoundation/AVFoundation.h>

@interface JWPlayer()<ORGMEngineDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) ORGMEngine *thirdPlayer;

@end

@implementation JWPlayer {
    id currentPlayer;
}

- (instancetype) init {
    if (self = [super init]) {
        
    }
    return self;
}

- (ORGMEngine*) thirdPlayer {
    if (!_thirdPlayer) {
        _thirdPlayer = [[ORGMEngine alloc] init];
    }
    return _thirdPlayer;
}

- (BOOL)playWithURL:(NSURL *)fileURL {
    if ([_thirdPlayer isPlaying]) {
        [_thirdPlayer stop];
    }
    NSString *pathExtention = [[fileURL pathExtension] lowercaseString];
    if ([pathExtention isEqualToString:@"flac"]) {
        currentPlayer = self.thirdPlayer;
        self.thirdPlayer.delegate = self;
        [self.thirdPlayer playUrl:fileURL];
        return YES;
    } else {
        NSError *error;
        AVAudioPlayer *avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
        avPlayer.delegate = self;
        currentPlayer = avPlayer;
        [avPlayer play];
        return error == nil;
    }
}

- (void)pause {
    SEL selector = NSSelectorFromString(@"pause");
    if ([currentPlayer respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning (
            [currentPlayer performSelector:selector];
        );
    }
}

- (void)resume {
    SEL selector = NSSelectorFromString(@"resume");
    if ([currentPlayer respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning (
            [currentPlayer performSelector:selector];
        );
    } else {
        selector = NSSelectorFromString(@"play");
        if ([currentPlayer respondsToSelector:selector]) {
            SuppressPerformSelectorLeakWarning (
                [currentPlayer performSelector:selector];
            );
        }
    }
}

- (void)stop {
    SEL selector = NSSelectorFromString(@"stop");
    if ([currentPlayer respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning (
            [currentPlayer performSelector:selector];
        );
    }
}

- (BOOL)isPlaying {
    if ([currentPlayer isKindOfClass:[AVAudioPlayer class]]) {
        return ((AVAudioPlayer*)currentPlayer).isPlaying;
    } else {
        return self.thirdPlayer.isPlaying;
    }
}

- (NSTimeInterval)currentTime {
    if ([currentPlayer isKindOfClass:[AVAudioPlayer class]]) {
        return ((AVAudioPlayer*)currentPlayer).currentTime;
    } else {
        return self.thirdPlayer.amountPlayed;
    }
}

- (NSTimeInterval)totalTime {
    if (currentPlayer == self.thirdPlayer) {
        return [self.thirdPlayer trackTime];
    }
    return 0;
}

#pragma mark - ORGMEngineDelegate

- (NSURL *)engineExpectsNextUrl:(ORGMEngine *)engine {
    return nil;
}

- (void)engine:(ORGMEngine *)engine didChangeState:(ORGMEngineState)state {
    switch (state) {
        case ORGMEngineStateStopped: {
            engine.delegate = nil;
            [self.delegate didFinishPlaying:self];
            break;
        }
        case ORGMEngineStatePaused: {
            break;
        }
        case ORGMEngineStatePlaying: {
            break;
        }
        case ORGMEngineStateError: {
           [self.delegate errorDidOccur:self];
            break;
        }
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self.delegate errorDidOccur:self];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self.delegate didFinishPlaying:self];
}

@end
