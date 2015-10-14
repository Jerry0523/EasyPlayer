//
//  LrcModal.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/14.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "LrcModal.h"
#import <objc/runtime.h>

@implementation LrcModal

+ (NSArray *)arrayFromJSON:(NSArray*)array {
    if (![array isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray *objects = [NSMutableArray array];
    for (NSDictionary *meta in array) {
        LrcModal *oneObject = [[[self class] alloc] initFromDictionary:meta];
        if (oneObject) {
            [objects addObject:oneObject];
        }
    }
    return objects;
}

- (instancetype)initFromDictionary:(NSDictionary *)json {
    if (!json) {
        return nil;
    }
    self = [super init];
    if (self) {
        NSDictionary *values = json;
        NSArray *propertyList = [self getPropertyList];
        [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:@"id"]) {
                NSString *className = NSStringFromClass([self class]);
                className = [className substringFromIndex:2];
                className = [className lowercaseString];
                key = [NSString stringWithFormat:@"%@Id", className];
            }
            
            if (obj != [NSNull null]) {
                if ([propertyList containsObject:[NSString stringWithFormat:@"_%@", key]]) {
                    [self setValue:obj forKey:key];
                } else {
                    NSLog(@"Class %@ does't have key %@", NSStringFromClass([self class]), key);
                }
            }
        }];
    }
    return self;
}

- (NSArray *)getPropertyList {
    NSMutableArray* propertyList = [NSMutableArray array];
    Class cls = [self class];
    unsigned int numberOfIvars = 0;
    Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
    for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++) {
        Ivar const ivar = *p;
        NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
        [propertyList addObject:key];
    }
    free(ivars);
    return propertyList;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        for (NSString *key in [self getPropertyList]) {
            NSObject *value = [aDecoder decodeObjectForKey:key];
            [self setValue:value forKey:key];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in [self getPropertyList]) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

@end

@implementation LrcInfo


@end

