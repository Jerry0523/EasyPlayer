//
// JWMEngine.h
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

#import <Foundation/Foundation.h>
#import "JWMAudioUnit.h"

@protocol JWMEngineDelegate;

typedef NS_ENUM(NSInteger, JWMEngineState) {
    JWMEngineStateStopped,
    JWMEngineStatePlaying,
    JWMEngineStatePaused,
    JWMEngineStateError
};

@interface JWMEngine : NSObject


@property (assign, nonatomic) JWMEngineOutputFormat outputFormat;
@property (assign, nonatomic) float volume;
@property (assign, nonatomic, readonly) JWMEngineState currentState;
@property (strong, nonatomic, readonly) NSError *currentError;
@property (unsafe_unretained, nonatomic) id<JWMEngineDelegate> delegate;

- (BOOL)isPlaying;
- (void)playUrl:(NSURL *)url withOutputUnitClass:(Class)outputUnitClass;
- (void)playUrl:(NSURL *)url;
- (void)pause;
- (void)resume;
- (void)stop;
- (double)trackTime;
- (double)amountPlayed;
- (NSDictionary *)metadata;
- (void)seekToTime:(double)time withDataFlush:(BOOL)flush;
- (void)seekToTime:(double)time;
- (void)setNextUrl:(NSURL *)url withDataFlush:(BOOL)flush;

@end


@protocol JWMEngineDelegate <NSObject>

- (NSURL *)engineExpectsNextUrl:(JWMEngine *)engine;

@optional
- (void)engine:(JWMEngine *)engine didChangeState:(JWMEngineState)state;

@end
