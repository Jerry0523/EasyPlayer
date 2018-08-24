//
// JWMConverter.m
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

#import "JWMConverter.h"

#import "JWMInputUnit.h"
#import "JWMOutputUnit.h"

@interface JWMConverter () {
    AudioStreamBasicDescription _inputFormat;
    AudioStreamBasicDescription _outputFormat;
    AudioConverterRef _converter;

    void *_callbackBuffer;
    void *_writeBuf;
}

@property (strong, nonatomic) JWMInputUnit *inputUnit;
@property (unsafe_unretained, nonatomic) JWMOutputUnit *outputUnit;
@property (strong, nonatomic) NSMutableData *convertedData;
@end

@implementation JWMConverter

- (id)initWithInputUnit:(JWMInputUnit *)inputUnit {
    self = [super init];
    if (self) {
        self.convertedData = [NSMutableData data];

        self.inputUnit = inputUnit;
        _inputFormat = inputUnit.format;
        _writeBuf = malloc(CHUNK_SIZE);
    }
    return self;
}

- (void)dealloc {
    if (_callbackBuffer) {
        free(_callbackBuffer);
    }
    free(_writeBuf);
}

#pragma mark - public

- (BOOL)setupWithOutputUnit:(JWMOutputUnit *)outputUnit {
    self.outputUnit = outputUnit;
    [_outputUnit setSampleRate:_inputFormat.mSampleRate];

    _outputFormat = outputUnit.format;
    _callbackBuffer = malloc((CHUNK_SIZE/_outputFormat.mBytesPerFrame) * _inputFormat.mBytesPerPacket);

    OSStatus stat = AudioConverterNew(&_inputFormat, &_outputFormat, &_converter);
    if (stat != noErr) {
        NSLog(NSLocalizedString(@"Error creating converter", nil));
        return NO;
    }

    if (_inputFormat.mChannelsPerFrame == 1) {
        SInt32 channelMap[2] = { 0, 0 };

        stat = AudioConverterSetProperty(_converter,
                                         kAudioConverterChannelMap,
                                         sizeof(channelMap),
                                         channelMap);
        if (stat != noErr) {
            NSLog(NSLocalizedString(@"Error mapping channels", nil));
            return NO;
        }
    }

    return YES;
}

- (void)process {
    int amountConverted = 0;
    do {
        if (_convertedData.length >= BUFFER_SIZE) {
            break;
        }
        amountConverted = [self convert:_writeBuf amount:CHUNK_SIZE];
        dispatch_sync([JWMQueues lock_queue], ^{
            [self.convertedData appendBytes:self->_writeBuf length:amountConverted];
        });
    } while (amountConverted > 0);

    if (!_outputUnit.isProcessing) {
        if (_convertedData.length < BUFFER_SIZE) {
            dispatch_source_merge_data([JWMQueues buffering_source], 1);
            return;
        }
        [_outputUnit process];
    }
}

- (void)reinitWithNewInput:(JWMInputUnit *)inputUnit withDataFlush:(BOOL)flush {
    if (flush) {
        [self flushBuffer];
    }
    self.inputUnit = inputUnit;
    _inputFormat = inputUnit.format;
    [self setupWithOutputUnit:_outputUnit];
}

- (NSUInteger)shiftBytes:(NSUInteger)amount buffer:(void *)buffer {
    NSUInteger bytesToRead = MIN(_convertedData.length, amount);

    dispatch_sync([JWMQueues lock_queue], ^{
        memcpy(buffer, self.convertedData.bytes, bytesToRead);
        [self.convertedData replaceBytesInRange:NSMakeRange(0, bytesToRead) withBytes:NULL length:0];
    });

    return bytesToRead;
}

- (BOOL)isReadyForBuffering {
    return (_convertedData.length <= 0.5*BUFFER_SIZE && !_inputUnit.isProcessing);
}

- (void)flushBuffer {
    dispatch_sync([JWMQueues lock_queue], ^{
        self.convertedData = [NSMutableData data];
    });
}

#pragma mark - private

- (int)convert:(void *)dest amount:(int)amount {
    AudioBufferList ioData;
    UInt32 ioNumberFrames;
    OSStatus err;

    ioNumberFrames = amount/_outputFormat.mBytesPerFrame;
    ioData.mBuffers[0].mData = dest;
    ioData.mBuffers[0].mDataByteSize = amount;
    ioData.mBuffers[0].mNumberChannels = _outputFormat.mChannelsPerFrame;
    ioData.mNumberBuffers = 1;

    err = AudioConverterFillComplexBuffer(_converter, ACInputProc, (__bridge void *)(self), &ioNumberFrames, &ioData, NULL);
    int amountRead = ioData.mBuffers[0].mDataByteSize;
    if (err == kAudioConverterErr_InvalidInputSize)	{
        amountRead += [self convert:dest + amountRead amount:amount - amountRead];
    }

    return amountRead;
}

static OSStatus ACInputProc(AudioConverterRef inAudioConverter,
                            UInt32* ioNumberDataPackets, AudioBufferList* ioData,
                            AudioStreamPacketDescription** outDataPacketDescription,
                            void* inUserData) {
    JWMConverter *converter = (__bridge JWMConverter *)inUserData;
    OSStatus err = noErr;
    NSUInteger amountToWrite;

    amountToWrite = [converter.inputUnit shiftBytes:(*ioNumberDataPackets)*(converter->_inputFormat.mBytesPerPacket)
                                             buffer:converter->_callbackBuffer];

    if (amountToWrite == 0) {
        ioData->mBuffers[0].mDataByteSize = 0;
        *ioNumberDataPackets = 0;

        return 100;
    }

    ioData->mBuffers[0].mData = converter->_callbackBuffer;
    ioData->mBuffers[0].mDataByteSize = (UInt32)amountToWrite;
    ioData->mBuffers[0].mNumberChannels = (converter->_inputFormat.mChannelsPerFrame);
    ioData->mNumberBuffers = 1;

    return err;
}

@end
