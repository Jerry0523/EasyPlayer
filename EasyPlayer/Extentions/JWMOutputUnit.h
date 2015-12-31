//
// JWMOutputUnit.h
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

#import "JWAudioUnit.h"

#import "JWMConverter.h"

/**
 `JWMOutputUnit` is a subclass of JWMAudioUnit for playing converted `PCM` data through the output device. This class gets data from the converter buffer.
 */
@interface JWMOutputUnit : JWAudioUnit

/**
 A flag that determines if instance is currently active.
 */
@property (assign, nonatomic, readonly) BOOL isProcessing;

/**
 Engine output format
 */
@property (assign, nonatomic) JWMEngineOutputFormat outputFormat;

/**
 Returns initialized `JWMOutputUnit` object and specifies converter source.

 @param converter An converter object used as a data source.

 @return An initialized `JWMOutputUnit` object.
 **/
- (id)initWithConverter:(JWMConverter *)converter;

/**
 Returns supported `PCM` audio format.

 @return An `ASBD` struct with supported audio format.
 */
- (AudioStreamBasicDescription)format;

/**
 Pauses playback throught the output device. Idempotent method.
 */
- (void)pause;

/**
 Resumes playback throught the output device. Idempotent method.
 */
- (void)resume;

/**
 Stops playback throught the output device and deallocates unnecessary resources. Idempotent method.
 */
- (void)stop;

/**
 Converts `frames` number to `seconds` according to the supported format.

 @param framesCount `Frames` number to convert to `seconds`.

 @return A number of `seconds` for specified number of `frames`.
 */
- (double)framesToSeconds:(double)framesCount;

/**
 Returns amount of played time in `seconds`.
 */
- (double)amountPlayed;

/**
 Seeks to the time within playing track.

 @param time Time interval offset in `seconds`.
 */
- (void)seek:(double)time;

/**
 Sets output unit volume. Default value `1`.

 @param volume Volume value in `percent`.
 */
- (void)setVolume:(float)volume;

- (void)setSampleRate:(double)sampleRate;

@end
