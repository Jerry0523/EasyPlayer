//
// CueSheetDecoder.m
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

#import "CueSheetDecoder.h"
#import "CueSheet.h"

#import "JWMPluginManager.h"

@interface CueSheetDecoder () {
	long _framePosition;
    
	long _trackStart;
	long _trackEnd;
}
@property (strong, nonatomic) id<JWMSource> source;
@property (strong, nonatomic) id<JWMDecoder> decoder;
@property (strong, nonatomic) CueSheet *cuesheet;
@end

@implementation CueSheetDecoder

- (void)dealloc {
    [self close];
}

#pragma mark - JWMDecoder

+ (NSArray *)fileTypes  {
	return [NSArray arrayWithObject:@"cue"];
}

- (NSDictionary *)properties {
	NSMutableDictionary *properties = [[_decoder properties] mutableCopy];
	[properties setObject:[NSNumber numberWithLong:(_trackEnd - _trackStart)]
                   forKey:@"totalFrames"];
	return properties;
}

- (NSDictionary *)metadata {
    NSDictionary *resultDict = nil;
    for (CueSheetTrack *track in _cuesheet.tracks) {
        if ([[_source.url fragment] isEqualToString:[track track]]) {
            resultDict = [NSDictionary dictionaryWithObjectsAndKeys:
                          track.artist, @"artist",
                          track.album, @"album",
                          track.title, @"title",
                          [NSNumber numberWithInt:[track.track intValue]], @"track",
                          track.genre, @"genre",
                          track.year, @"year",
                          nil];
        }
    }
    return resultDict;
}

- (NSUInteger)readAudio:(void *)buf frames:(NSUInteger)frames {
	if (_framePosition + frames > _trackEnd) {
		frames = _trackEnd - _framePosition;
	}
    
	if (!frames) {
		return 0;
	}
    
	NSUInteger n = [_decoder readAudio:buf frames:frames];
	_framePosition += n;
	return n;
}

- (BOOL)open:(id<JWMSource>)s {
	NSURL *url = [s url];
	self.cuesheet = [[CueSheet alloc] initWithURL:url];
	
    JWMPluginManager *pluginManager = [JWMPluginManager sharedManager];
	for (int i = 0; i < _cuesheet.tracks.count; i++) {
        CueSheetTrack *track = [_cuesheet.tracks objectAtIndex:i];
		if ([track.track isEqualToString:[url fragment]]) {
			self.source = [pluginManager sourceForURL:track.url error:nil];

			if (![_source open:track.url]) {
				return NO;
			}

			self.decoder = [pluginManager decoderForSource:_source error:nil];
			if (![_decoder open:_source]) {
				return NO;
			}

			CueSheetTrack *nextTrack = nil;
			if (i + 1 < [_cuesheet.tracks count]) {
				nextTrack = [_cuesheet.tracks objectAtIndex:i + 1];
			}

			NSDictionary *properties = [_decoder properties];
			float sampleRate = [[properties objectForKey:@"sampleRate"] floatValue];
			_trackStart = [track time] * sampleRate;

			if (nextTrack && [nextTrack.url isEqual:track.url]) {
				_trackEnd = [nextTrack time] * sampleRate;
			} else {
				_trackEnd = [[properties objectForKey:@"totalFrames"] doubleValue];
			}
			[self seek: 0];

			return YES;
		}
	}

	return NO;
}

- (long)seek:(long)frame {
	if (frame > _trackEnd - _trackStart) {
		return -1;
	}
	
	frame += _trackStart;
	_framePosition = [_decoder seek:frame];
	return _framePosition;
}

- (void)close {
    [_decoder close];
    [_source close];
}

@end
