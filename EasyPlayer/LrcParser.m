//
//  LrcParser.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/15.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "LrcParser.h"

@implementation LrcObject

@end

@implementation LrcParser {
    NSString *rawString;
}

- (instancetype)initWithLRCString:(NSString*)aString {
    if (self = [super init]) {
        rawString = aString;
    }
    return self;
}

- (NSArray*)parse {
    NSString *rawParse = [rawString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    NSArray *arr = [rawParse componentsSeparatedByString:@"\n"];
    NSMutableArray *result = [NSMutableArray array];
    NSTimeInterval timeOffset = 0;
    for (NSString *item in arr) {
        if ([item length]) {
            if([item hasPrefix:@"[ti:"] ||
               [item hasPrefix:@"[ar:"] ||
               [item hasPrefix:@"[al:"] ||
               [item hasPrefix:@"[by:"] ||
               [item hasPrefix:@"[title:"] ||
               [item hasPrefix:@"[artist:"] ||
               [item hasPrefix:@"[album:"] ||
               [item rangeOfString:@"http://"].location != NSNotFound ||
               [item rangeOfString:@"www."].location != NSNotFound) {
                continue;
            }
            
            if ([item hasPrefix:@"[offset:"]) {
                NSRange stopRange = [item rangeOfString:@"]"];
                if (stopRange.location != NSNotFound) {
                    NSString *offset =  [item substringWithRange:NSMakeRange(8, stopRange.location - 8)];
                    timeOffset = [offset floatValue] / 1000.0;
                }
                continue;
            }
            
            NSMutableArray *tmpArray = [NSMutableArray array];
            NSString *content = [self parseTimeIntervalFrom:item destination:tmpArray offset:timeOffset];
            if(content.length == 0) {
                continue;
            }
            if ([tmpArray count] == 0) {
                LrcObject *obj = [[LrcObject alloc] init];
                obj.timeInteval = -1;
                [tmpArray addObject:obj];
            }
            
            for (LrcObject *lrcObj in tmpArray) {
                lrcObj.content = content;
            }
            [result addObjectsFromArray:tmpArray];
        }
    }
    
    NSArray *sortedArray = [result sortedArrayUsingComparator:^NSComparisonResult(LrcObject *obj1, LrcObject *obj2) {
        if(obj1.timeInteval > obj2.timeInteval){
            return NSOrderedDescending;
        } else if(obj1.timeInteval < obj2.timeInteval) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
    return sortedArray;
}

- (NSString*)parseTimeIntervalFrom:(NSString*)source destination:(NSMutableArray*)array offset:(NSTimeInterval)offset {
    NSRange startrange = [source rangeOfString:@"["];
    NSRange stoprange = [source rangeOfString:@"]"];
    if (startrange.location == NSNotFound || stoprange.location == NSNotFound) {
        return source;
    }
    NSString *content = [source substringWithRange:NSMakeRange(startrange.location + 1, stoprange.location - startrange.location - 1)];
    if ([content length] == 8) {
        NSString *minute = [content substringWithRange:NSMakeRange(0, 2)];
        NSString *second = [content substringWithRange:NSMakeRange(3, 2)];
        //                NSString *mm = [content substringWithRange:NSMakeRange(6, 2)];
        LrcObject *obj = [[LrcObject alloc] init];
        obj.timeInteval = [minute integerValue] * 60 + [second integerValue] - offset;
        [array addObject:obj];
        NSString *content = [source substringFromIndex:10];
        return [self parseTimeIntervalFrom:content destination:array offset:offset];
    } else {
        return source;
    }
}

@end
