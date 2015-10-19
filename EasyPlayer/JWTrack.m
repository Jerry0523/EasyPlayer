//
//  MusicTrackModal.m
//  
//
//  Created by 王杰 on 15/10/18.
//
//

#import "JWTrack.h"
#import "NSString+Comparator.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation JWTrack

- (instancetype)initFromDictionary:(NSDictionary *)json {
    if (self = [super initFromDictionary:json]) {
        if (!self.Name) {
            self.Name = @"";
        }
        if (!self.Artist) {
            self.Artist = @"";
        }
        if (!self.Album) {
            self.Album = @"";
        }
    }
    return self;
}

- (NSString*)pathExtention {
    NSArray *components = [self.Location componentsSeparatedByString:@"."];
    if ([components count] < 2) {
        return nil;
    }
    return [components lastObject];
}

- (NSInteger)compares:(JWTrack *)track {
    return [self.Name compares:track.Name];
}

- (BOOL)respondToSearch:(NSString *)search {
    return [[self.Name lowercaseString] rangeOfString:search].location != NSNotFound ||
        [[self.Album lowercaseString] rangeOfString:search].location != NSNotFound ||
    [[self.Artist lowercaseString] rangeOfString:search].location != NSNotFound;
}

- (NSData*)musicData {
    return [NSData dataWithContentsOfURL:[NSURL URLWithString:self.Location]];
}

- (NSString*)cacheKey {
    NSMutableString *mutable = [NSMutableString stringWithString:_Name];
    [mutable appendString:_Artist ? _Artist : @"NULL"];
    
    const char *cStr = [mutable UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];

}

@end
