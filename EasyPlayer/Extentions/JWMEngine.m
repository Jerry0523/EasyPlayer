//
// JWMEngine.m
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

#import "JWMEngine.h"

#import "JWMInputUnit.h"
#import "JWMOutputUnit.h"
#import "JWMConverter.h"
#import "JWMCommonProtocols.h"

@interface JWMEngine ()
@property (strong, nonatomic) JWMInputUnit *input;
@property (strong, nonatomic) JWMOutputUnit *output;
@property (strong, nonatomic) JWMConverter *converter;
@property (assign, nonatomic) JWMEngineState currentState;
@property (strong, nonatomic) NSError *currentError;
@end

@implementation JWMEngine

- (id)init {
    self = [super init];
    if (self) {
        self.volume = 100.0f;
        [self setup];
        [self setCurrentState:JWMEngineStateStopped];
        [self addObserver:self forKeyPath:@"currentState"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"currentState"];
}

#pragma mark - public

- (BOOL)isPlaying {
    return self.currentState == JWMEngineStatePlaying;
}

- (void)playUrl:(NSURL *)url withOutputUnitClass:(Class)outputUnitClass {
    if (!outputUnitClass || ![outputUnitClass isSubclassOfClass:[JWMOutputUnit class]]) {

        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:NSLocalizedString(@"Output unit should be subclass of JWMOutputUnit", nil)
                                     userInfo:nil];
    }

    if (self.currentState == JWMEngineStatePlaying) [self stop];
    dispatch_async([JWMQueues processing_queue], ^{
        self.currentError = nil;

        self.input = [[JWMInputUnit alloc] init];

        if (![_input openWithUrl:url]) {
            self.currentState = JWMEngineStateError;
            self.currentError = [NSError errorWithDomain:kErrorDomain
                                                    code:JWMEngineErrorCodesSourceFailed
                                                userInfo:@{ NSLocalizedDescriptionKey:
                                                            NSLocalizedString(@"Couldn't open source", nil) }];
            return;
        }
        [_input addObserver:self forKeyPath:@"endOfInput"
                    options:NSKeyValueObservingOptionNew
                    context:nil];

        self.converter = [[JWMConverter alloc] initWithInputUnit:_input];

        JWMOutputUnit *output = [[outputUnitClass alloc] initWithConverter:_converter];
        output.outputFormat = _outputFormat;
        self.output = output;
        [_output setVolume:_volume];

        if (![_converter setupWithOutputUnit:_output]) {
            self.currentState = JWMEngineStateError;
            self.currentError = [NSError errorWithDomain:kErrorDomain
                                                    code:JWMEngineErrorCodesConverterFailed
                                                userInfo:@{ NSLocalizedDescriptionKey:
                                                            NSLocalizedString(@"Couldn't setup converter", nil) }];
            return;
        }

        [self setCurrentState:JWMEngineStatePlaying];
        dispatch_source_merge_data([JWMQueues buffering_source], 1);
    });
}

- (void)playUrl:(NSURL *)url {

  [self playUrl:url withOutputUnitClass:[JWMOutputUnit class]];
}

- (void)pause {
    if (_currentState != JWMEngineStatePlaying)
        return;

    [_output pause];
    [self setCurrentState:JWMEngineStatePaused];
}

- (void)resume {
    if (_currentState != JWMEngineStatePaused)
        return;

    [_output resume];
    [self setCurrentState:JWMEngineStatePlaying];
}

- (void)stop {
    dispatch_async([JWMQueues processing_queue], ^{
        [_input removeObserver:self forKeyPath:@"endOfInput"];
        self.output = nil;
        self.input = nil;
        self.converter = nil;
        [self setCurrentState:JWMEngineStateStopped];
    });
}

- (double)trackTime {
    return [_output framesToSeconds:_input.framesCount];
}

- (double)amountPlayed {
    return [_output amountPlayed];
}

- (NSDictionary *)metadata {
    return [_input metadata];
}

- (void)seekToTime:(double)time withDataFlush:(BOOL)flush {
    [_output seek:time];
    [_input seek:time withDataFlush:flush];
    if (flush) [_converter flushBuffer];
}

- (void)seekToTime:(double)time {
    [self seekToTime:time withDataFlush:NO];
}

- (void)setNextUrl:(NSURL *)url withDataFlush:(BOOL)flush {
    if (!url) {
        [self stop];
    } else {
        dispatch_async([JWMQueues processing_queue], ^{
            if (![_input openWithUrl:url]) {
                [self stop];
            }
            [_converter reinitWithNewInput:_input withDataFlush:flush];
            [_output seek:0.0]; //to reset amount played
            [self setCurrentState:JWMEngineStatePlaying]; //trigger delegate method
        });
    }
}

#pragma mark - private

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!_delegate)
        return;

    if ([keyPath isEqualToString:@"currentState"] &&
        [_delegate respondsToSelector:@selector(engine:didChangeState:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate engine:self didChangeState:_currentState];
        });
    } else if ([keyPath isEqualToString:@"endOfInput"]) {
        NSURL *nextUrl = [_delegate engineExpectsNextUrl:self];
        if (!nextUrl) {
            [self setCurrentState:JWMEngineStateStopped];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNextUrl:nextUrl withDataFlush:NO];
        });
    }
}

- (void)setup {
    dispatch_source_set_event_handler([JWMQueues buffering_source], ^{
        [_input process];
        [_converter process];
    });
}

- (void)setVolume:(float)volume {
    _volume = volume;
    [_output setVolume:volume];
}

@end
