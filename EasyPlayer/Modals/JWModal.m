//
//  CommonModal.m
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

#import "JWModal.h"
#import <objc/runtime.h>

@implementation JWModal

+ (NSArray *)arrayFromJSON:(NSArray*)array {
    if (![array isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray *objects = [NSMutableArray array];
    for (NSDictionary *meta in array) {
        JWModal *oneObject = [[[self class] alloc] initFromDictionary:meta];
        if (oneObject) {
            [objects addObject:oneObject];
        }
    }
    return objects;
}

- (NSData*)archivedData {
   return [NSKeyedArchiver archivedDataWithRootObject:self];
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
            NSMutableString *targetKey = [key mutableCopy];
            if ([targetKey rangeOfString:@" "].location != NSNotFound) {
                [targetKey replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [targetKey length])];
            }
            if (obj && obj != [NSNull null]) {
                if ([propertyList containsObject:[NSString stringWithFormat:@"_%@", targetKey]]) {
                    [self setValue:obj forKey:targetKey];
                } else {
//                    NSLog(@"Class %@ does't have key %@", NSStringFromClass([self class]), targetKey);
                }
            }
        }];
    }
    return self;
}

- (instancetype)initFromArchiveData:(NSData*)archiveData {
    return [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
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

