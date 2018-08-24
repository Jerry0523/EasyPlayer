//
// JWMCommonProtocols.h
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
#define kErrorDomain @"com.jerry.engine.error"


typedef NS_ENUM(NSInteger, JWMEngineErrorCodes) {
    JWMEngineErrorCodesSourceFailed,
    JWMEngineErrorCodesConverterFailed,
    JWMEngineErrorCodesDecoderFailed,
    JWMEngineErrorCodesContainerFailed
};

@protocol JWMEngineObject <NSObject>
@end

@protocol JWMSource <JWMEngineObject>

+ (NSString *)scheme;
- (NSURL *)url;
- (long)size;
- (BOOL)open:(NSURL *)url;
- (BOOL)seekable;
- (BOOL)seek:(long)position whence:(int)whence;
- (long)tell;
- (NSUInteger)read:(void *)buffer amount:(NSUInteger)amount;
- (void)close;

@end


@protocol JWMContainer <JWMEngineObject>

+ (NSArray *)fileTypes;
+ (NSArray *)urlsForContainerURL:(NSURL *)url;

@end

@protocol JWMDecoder <JWMEngineObject>
@required

+ (NSArray *)fileTypes;
- (NSDictionary *)properties;
- (NSDictionary *)metadata;
- (NSUInteger)readAudio:(void *)buffer frames:(NSUInteger)frames;
- (BOOL)open:(id<JWMSource>)source;
- (long)seek:(long)frame;
- (void)close;

@end