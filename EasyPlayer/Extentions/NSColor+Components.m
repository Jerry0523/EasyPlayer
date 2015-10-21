//
//  NSColor+Components.m
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

#import "NSColor+Components.h"

@implementation NSColor (Components)

- (void)getRGBComponents:(CGFloat[4])result {
    CGColorRef color = [self CGColor];
    size_t numComponents = CGColorGetNumberOfComponents(color);
    if (numComponents == 4) {
        const CGFloat *components = CGColorGetComponents(color);
        result[0] = components[0] * 255.0;
        result[1] = components[1] * 255.0;
        result[2] = components[2] * 255.0;
        result[3] = components[3];
    }
}

- (void)getHSBComponnets:(CGFloat[3])result {
    CGFloat values[4];
    [self getRGBComponents:values];
    
    int rgbR = values[0];
    int rgbG = values[1];
    int rgbB = values[2];
    
    assert(0 <= rgbR && rgbR <= 255);
    assert(0 <= rgbG && rgbG <= 255);
    assert(0 <= rgbB && rgbB <= 255);
    
    int max = MAX(MAX(rgbR, rgbG), rgbB);
    int min = MIN(MIN(rgbR, rgbG), rgbB);
    
    float hsbB = max / 255.0f;
    float hsbS = max == 0 ? 0 : (max - min) / (float) max;
    
    float hsbH = 0;
    if (max == rgbR && rgbG >= rgbB) {
        hsbH = (rgbG - rgbB) * 60.0f / (max - min) + 0;
    } else if (max == rgbR && rgbG < rgbB) {
        hsbH = (rgbG - rgbB) * 60.0f / (max - min) + 360;
    } else if (max == rgbG) {
        hsbH = (rgbB - rgbR) * 60.0f / (max - min) + 120;
    } else if (max == rgbB) {
        hsbH = (rgbR - rgbG) * 60.0f / (max - min) + 240;
    }
    
    result[0] = hsbH;
    result[1] = hsbS;
    result[2] = hsbB;
}

@end
