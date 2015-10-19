//
//  MusicTrackModal.m
//  
//
//  Created by 王杰 on 15/10/18.
//
//

#import "MusicTrackModal.h"
#import "NSString+Comparator.h"

@implementation MusicTrackModal

- (NSString*)pathExtention {
    NSArray *components = [self.Location componentsSeparatedByString:@"."];
    if ([components count] < 2) {
        return nil;
    }
    return [components lastObject];
}

- (NSInteger)compares:(MusicTrackModal *)track {
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

@end
