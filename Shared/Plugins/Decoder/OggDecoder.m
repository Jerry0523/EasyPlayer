//
//  OggDecoder.m
//  EasyPlayer
//
//  Created by 王杰 on 2018/8/27.
//  Copyright © 2018年 Jerry Wong. All rights reserved.
//

#import "OggDecoder.h"
#include <libVorbis/codec.h>
#include <libVorbis/vorbisfile.h>

@interface OggDecoder () {
    OggVorbis_File _vf;
    int _channels;
    float _frequency;
    long _totalFrames;
}

@property (retain, nonatomic) NSMutableDictionary *metadata;
@property (retain, nonatomic) id<JWMSource> source;

@end

@implementation OggDecoder 

- (void)dealloc {
    [self close];
}

- (void)close {
    ov_clear(&_vf);
    [_source close];
}

+ (NSArray *)fileTypes {
    return @[@"ogg"];
}

- (NSDictionary *)metadata {
    return _metadata;
}

- (BOOL)open:(id<JWMSource>)source {
    _source = source;
    _metadata = [NSMutableDictionary dictionary];
    
    ov_callbacks callbacks = {
        ReadCallback,
        SeekCallback,
        NULL,
        TellCallback,
    };
    
    if(ov_open_callbacks((__bridge void *)(source), &_vf, NULL, 0, callbacks) < 0) {
        return NO;
    }
    
    vorbis_info *vi = ov_info(&_vf, -1);
    
    _channels = vi->channels;
    _frequency = vi->rate;
    _totalFrames = ov_pcm_total(&_vf, -1);
    
    [self parseMetadata];
    
    return YES;
}

- (void)parseMetadata {
    char **ptr = ov_comment(&_vf, -1)->user_comments;
    while(*ptr) {
        NSString *content = [NSString stringWithFormat:@"%s", *ptr];
        NSRange range = [content rangeOfString:@"="];
        if (range.location != NSNotFound) {
            NSString *key = [content substringWithRange:NSMakeRange(0, range.location)];
            NSString *value = [content substringWithRange:NSMakeRange(range.location + 1,
                                                                      content.length - range.location - 1)];
            [self.metadata setObject:value forKey:[key lowercaseString]];
        } else {
            [self.metadata setObject:@"" forKey:content.lowercaseString];
        }
        
        ++ptr;
    }
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:_channels], @"channels",
            @16, @"bitsPerSample",
            [NSNumber numberWithFloat:_frequency], @"sampleRate",
            [NSNumber numberWithDouble:_totalFrames], @"totalFrames",
            [NSNumber numberWithBool:[_source seekable]], @"seekable",
            @"little",@"endian",
            nil];
}

- (NSUInteger)readAudio:(void *)buffer frames:(NSUInteger)frames {
    long samples = ov_read(&_vf, buffer, (int)frames, 0, 2, 1, NULL);
    if (samples < 0) return 0;
    return samples;
}

- (long)seek:(long)frame {
    return ov_pcm_seek(&_vf, frame);
}

#pragma mark - callback
static size_t ReadCallback(void *ptr, size_t size, size_t nmemb, void *dataSource) {
    id<JWMSource> source = (__bridge id<JWMSource>)(dataSource);
    NSUInteger result = [source read:ptr amount:nmemb];
    return (size_t)result;
}

static int SeekCallback(void *dataSource, ogg_int64_t offset, int whence) {
    id<JWMSource> source = (__bridge id<JWMSource>)(dataSource);
    return [source seek:(long)offset whence:whence] ? 0 : -1;
}

static long TellCallback(void *datasource) {
    id<JWMSource> source = (__bridge id<JWMSource>)(datasource);
    return [source tell];
}

@end
