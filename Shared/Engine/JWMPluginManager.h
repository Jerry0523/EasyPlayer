//
// JWMPluginManager.h
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
#import "JWMCommonProtocols.h"

@interface JWMPluginManager : NSObject

@property (nonatomic, strong, class, readonly) JWMPluginManager *sharedManager;

@property (nonatomic, copy, class, readonly) NSArray<NSString *> *supportedFileTypes;

- (id<JWMSource>)sourceForURL:(NSURL *)url error:(NSError **)error;

- (id<JWMDecoder>)decoderForSource:(id<JWMSource>)source error:(NSError **)error;

- (NSArray *)urlsForContainerURL:(NSURL *)url error:(NSError **)error;

@end
