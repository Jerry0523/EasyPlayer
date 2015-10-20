//
//  LrcParser.h
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/15.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWLrcObject : NSObject

@property (nonatomic, assign) NSTimeInterval timeInteval;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *tag;

@end

@interface JWLrcParser : NSObject

- (instancetype)initWithLRCString:(NSString*)rawString;

- (NSArray*)parse;

@end
