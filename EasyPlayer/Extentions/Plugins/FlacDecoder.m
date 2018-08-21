//
// FlacDecoder.m
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

#import <libFLAC/all.h>
#import "FlacDecoder.h"

#define SAMPLES_PER_WRITE 512
#define FLAC__MAX_SUPPORTED_CHANNELS 2
#define SAMPLE_blockBuffer_SIZE ((FLAC__MAX_BLOCK_SIZE + SAMPLES_PER_WRITE) * FLAC__MAX_SUPPORTED_CHANNELS * (24/8))

@interface FlacDecoder () {
    FLAC__StreamDecoder *_decoder;
    void *_blockBuffer;
    int _blockBufferFrames;

    int _bitsPerSample;
    int _channels;
    float _frequency;
    long _totalFrames;
}

@property (retain, nonatomic) NSMutableDictionary *metadata;
@property (retain, nonatomic) id<JWMSource> source;
@property (assign, nonatomic) BOOL endOfStream;

- (FLAC__StreamDecoder *)decoder;
- (char *)blockBuffer;
- (int)blockBufferFrames;
- (void)setBlockBufferFrames:(int)frames;

@end

@implementation FlacDecoder
@synthesize source;
@synthesize endOfStream;

- (void)dealloc {
    [self close];
}

#pragma mark - JWMDecoder
+ (NSArray *)fileTypes {
	return [NSArray arrayWithObjects:@"flac", nil];
}

- (NSDictionary *)properties {
	return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:_channels], @"channels",
            [NSNumber numberWithInt:_bitsPerSample], @"bitsPerSample",
            [NSNumber numberWithFloat:_frequency], @"sampleRate",
            [NSNumber numberWithDouble:_totalFrames], @"totalFrames",
            [NSNumber numberWithBool:[source seekable]], @"seekable",
            @"big",@"endian",
            nil];
}

- (NSMutableDictionary *)metadata {
    return _metadata;
}

- (NSUInteger)readAudio:(void *)buffer frames:(NSUInteger)frames {
	int framesRead = 0;
	int bytesPerFrame = (_bitsPerSample/8) * _channels;
	while (framesRead < frames) {
		if (_blockBufferFrames == 0) {
			if (FLAC__stream_decoder_get_state(_decoder) == FLAC__STREAM_DECODER_END_OF_STREAM ||
                FLAC__stream_decoder_get_state(_decoder) == FLAC__STREAM_DECODER_SEEK_ERROR) {
				break;
			}
            
			FLAC__stream_decoder_process_single(_decoder);
		}
        
		NSUInteger framesToRead = _blockBufferFrames;
		if (_blockBufferFrames > frames) {
			framesToRead = frames;
		}
        
		memcpy(((uint8_t *)buffer) + (framesRead * bytesPerFrame),
               (uint8_t *)_blockBuffer, framesToRead * bytesPerFrame);
        
		frames -= framesToRead;
		framesRead += framesToRead;
		_blockBufferFrames -= framesToRead;
		
		if (_blockBufferFrames > 0) {
			memmove((uint8_t *)_blockBuffer,
                    ((uint8_t *)_blockBuffer) + (framesToRead * bytesPerFrame),
                    _blockBufferFrames * bytesPerFrame);
		}
	}
	
	return framesRead;
}

- (BOOL)open:(id<JWMSource>)s {
	[self setSource:s];
	
    self.metadata = [NSMutableDictionary dictionary];
	_decoder = FLAC__stream_decoder_new();
	if (_decoder == NULL) {
		return NO;
    }
        
    FLAC__stream_decoder_set_metadata_respond(_decoder, FLAC__METADATA_TYPE_VORBIS_COMMENT);
    FLAC__stream_decoder_set_metadata_respond(_decoder, FLAC__METADATA_TYPE_PICTURE);
    
	if (FLAC__stream_decoder_init_stream(_decoder,
										 ReadCallback,
										 ([source seekable] ? SeekCallback : NULL),
										 ([source seekable] ? TellCallback : NULL),
										 ([source seekable] ? LengthCallback : NULL),
										 ([source seekable] ? EOFCallback : NULL),
										 WriteCallback,
										 MetadataCallback,
										 ErrorCallback,
										 (__bridge void *)(self)
										 ) != FLAC__STREAM_DECODER_INIT_STATUS_OK) {
		return NO;
	}
	    
	FLAC__stream_decoder_process_until_end_of_metadata(_decoder);
	_blockBuffer = malloc(SAMPLE_blockBuffer_SIZE);
    
	return YES;
}

- (long)seek:(long)sample {
	FLAC__stream_decoder_seek_absolute(_decoder, sample);
	return sample;
}

- (void)close {
	if (_decoder) {
		FLAC__stream_decoder_finish(_decoder);
		FLAC__stream_decoder_delete(_decoder);
	}
	if (_blockBuffer) {
		free(_blockBuffer);
	}
	[source close];
    
	_decoder = NULL;
	_blockBuffer = NULL;
}

#pragma mark - private
- (char *)blockBuffer {
	return _blockBuffer;
}

- (int)blockBufferFrames {
	return _blockBufferFrames;
}

- (void)setBlockBufferFrames:(int)frames {
	_blockBufferFrames = frames;
}

- (FLAC__StreamDecoder *)decoder {
	return _decoder;
}

#pragma mark - flac callbacks
FLAC__StreamDecoderReadStatus ReadCallback(const FLAC__StreamDecoder *decoder,
                                           FLAC__byte blockBuffer[],
                                           size_t *bytes,
                                           void *client_data) {
	FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
	*bytes = [[flacDecoder source] read:blockBuffer amount:*bytes];
    
    if(*bytes == 0) {
		[flacDecoder setEndOfStream:YES];
		return FLAC__STREAM_DECODER_READ_STATUS_END_OF_STREAM;
	}
	else {
		return FLAC__STREAM_DECODER_READ_STATUS_CONTINUE;
	}
}

FLAC__StreamDecoderSeekStatus SeekCallback(const FLAC__StreamDecoder *decoder,
                                           FLAC__uint64 absolute_byte_offset,
                                           void *client_data) {
	FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
	
	if(![[flacDecoder source] seek:(long)absolute_byte_offset whence:SEEK_SET])
		return FLAC__STREAM_DECODER_SEEK_STATUS_ERROR;
	else
		return FLAC__STREAM_DECODER_SEEK_STATUS_OK;
}

FLAC__StreamDecoderTellStatus TellCallback(const FLAC__StreamDecoder *decoder,
                                           FLAC__uint64 *absolute_byte_offset,
                                           void *client_data) {
	FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;

	off_t pos;
	if((pos = [[flacDecoder source] tell]) < 0) {
		return FLAC__STREAM_DECODER_TELL_STATUS_ERROR;
	} else {
		*absolute_byte_offset = (FLAC__uint64)pos;
		return FLAC__STREAM_DECODER_TELL_STATUS_OK;
	}
}

FLAC__bool EOFCallback(const FLAC__StreamDecoder *decoder, void *client_data) {
	FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
	return (FLAC__bool)[flacDecoder endOfStream];
}

FLAC__StreamDecoderLengthStatus LengthCallback(const FLAC__StreamDecoder *decoder,
                                               FLAC__uint64 *stream_length,
                                               void *client_data) {
	FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
	
	if ([[flacDecoder source] seekable]) {
		long currentPos = [[flacDecoder source] tell];
		
		[[flacDecoder source] seek:0 whence:SEEK_END];
		*stream_length = [[flacDecoder source] tell];
		
		[[flacDecoder source] seek:currentPos whence:SEEK_SET];
		
		return FLAC__STREAM_DECODER_LENGTH_STATUS_OK;
	} else {
		*stream_length = 0;
		return FLAC__STREAM_DECODER_LENGTH_STATUS_ERROR;
	}
}

FLAC__StreamDecoderWriteStatus WriteCallback(const FLAC__StreamDecoder *decoder,
                                             const FLAC__Frame *frame,
                                             const FLAC__int32 * const sampleblockBuffer[],
                                             void *client_data) {
	FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
	
	void *blockBuffer = [flacDecoder blockBuffer];

	int8_t  *alias8;
	int16_t *alias16;
	int32_t *alias32;
	int sample, channel;
	int32_t	audioSample;

    switch(frame->header.bits_per_sample) {
        case 8:
            // Interleave the audio (no need for byte swapping)
            alias8 = blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    *alias8++ = (int8_t)sampleblockBuffer[channel][sample];
                }
            }

            break;

        case 16:
            // Interleave the audio, converting to big endian byte order
            alias16 = blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    *alias16++ = (int16_t)OSSwapHostToBigInt16((int16_t)sampleblockBuffer[channel][sample]);
                }
            }

            break;

        case 24:
            // Interleave the audio (no need for byte swapping)
            alias8 = blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    audioSample = sampleblockBuffer[channel][sample];
                    *alias8++   = (int8_t)(audioSample >> 16);
                    *alias8++   = (int8_t)(audioSample >> 8);
                    *alias8++   = (int8_t)audioSample;
                }
            }

            break;

        case 32:
            // Interleave the audio, converting to big endian byte order
            alias32 = blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    *alias32++ = OSSwapHostToBigInt32(sampleblockBuffer[channel][sample]);
                }
            }
		default:
			NSLog(@"Error, unsupported sample size.");
	}

	[flacDecoder setBlockBufferFrames:frame->header.blocksize];
	return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

void MetadataCallback(const FLAC__StreamDecoder *decoder,
                      const FLAC__StreamMetadata *metadata,
                      void *client_data) {
    if (metadata->type == FLAC__METADATA_TYPE_VORBIS_COMMENT) {
        FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
        FLAC__StreamMetadata_VorbisComment comment = metadata->data.vorbis_comment;
        FLAC__uint32 count = metadata->data.vorbis_comment.num_comments;
        for (int i = 0; i < count; i++) {
            NSString *commentValue = [NSString stringWithUTF8String:(const char*)comment.comments[i].entry];
            NSRange range = [commentValue rangeOfString:@"="];
            NSString *key = [commentValue substringWithRange:NSMakeRange(0, range.location)];
            NSString *value = [commentValue substringWithRange:NSMakeRange(range.location + 1,
                                                                           commentValue.length - range.location - 1)];
            [flacDecoder.metadata setObject:value forKey:[key lowercaseString]];
        }
    } else if (metadata->type == FLAC__METADATA_TYPE_PICTURE) {
        FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;
        FLAC__StreamMetadata_Picture picture = metadata->data.picture;
        NSData *picture_data = [NSData dataWithBytes:picture.data
                                              length:picture.data_length];
        [flacDecoder.metadata setObject:picture_data forKey:@"picture"];
    } else if (metadata->type == FLAC__METADATA_TYPE_STREAMINFO) {
        FlacDecoder *flacDecoder = (__bridge FlacDecoder *)client_data;

        flacDecoder->_channels = metadata->data.stream_info.channels;
        flacDecoder->_frequency = metadata->data.stream_info.sample_rate;
        flacDecoder->_bitsPerSample = metadata->data.stream_info.bits_per_sample;
        
        flacDecoder->_totalFrames = (long)metadata->data.stream_info.total_samples;
    }
}

void ErrorCallback(const FLAC__StreamDecoder *decoder,
                   FLAC__StreamDecoderErrorStatus status,
                   void *client_data) {
}

@end
