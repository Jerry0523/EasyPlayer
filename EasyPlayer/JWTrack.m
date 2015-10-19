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
#import <AudioToolbox/AudioToolbox.h>

@implementation JWTrack

- (instancetype)initFromID3Info:(NSDictionary*)info url:(NSURL*)fileURL{
    if (self = [super init]) {
        NSString *album = info[@"album"];
        NSString *artist = info[@"artist"];
        NSString *title = info[@"title"];
        NSString *file = [fileURL absoluteString];
        
        
        
        self.Album = album ? album : @"";
        self.Artist = artist ? artist : @"";
        self.Location = file;
        
        if (!title) {
            NSString *filename = [[file lastPathComponent] stringByDeletingPathExtension];
            filename = [filename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            self.Name = filename;
        } else {
            self.Name = title;
        }
        
        self.TotalTime = [info[@"approximate duration in seconds"] doubleValue] * 1000;
    }
    return self;
}

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

- (NSImage*)innerCoverImage {
    NSURL *fileURL = [NSURL URLWithString:self.Location];
    AudioFileID audioFile;
    OSStatus theErr = noErr;
    theErr = AudioFileOpenURL((__bridge CFURLRef)fileURL,
                              kAudioFileReadPermission,
                              kAudioFileMP3Type,
                              &audioFile);
    
    if (theErr != noErr) {
        return nil;
    }
    UInt32 picDataSize = 0;
    theErr = AudioFileGetPropertyInfo (audioFile,
                                       kAudioFilePropertyInfoDictionary,
                                       &picDataSize,
                                       0);
    if (theErr != noErr) {
        return nil;
    }
    
    CFDataRef albumPic;
    theErr = AudioFileGetProperty(audioFile, kAudioFilePropertyAlbumArtwork, &picDataSize, &albumPic);
    if(theErr != noErr ){
        return nil;
    }
    NSData *imagedata = (__bridge NSData*)albumPic;
    CFRelease(albumPic);
    theErr = AudioFileClose (audioFile);
    
    return [[NSImage alloc] initWithData:imagedata];
}

+ (NSDictionary *)innerTagInfoForURL:(NSURL*)fileURL{
    AudioFileID audioFile;
    OSStatus theErr = noErr;
    theErr = AudioFileOpenURL((__bridge CFURLRef)fileURL,
                              kAudioFileReadPermission,
                              kAudioFileMP3Type,
                              &audioFile);
    
    if (theErr != noErr) {
        return nil;
    }
    
    UInt32 dictionarySize = 0;
    theErr = AudioFileGetPropertyInfo (audioFile,
                                       kAudioFilePropertyInfoDictionary,
                                       &dictionarySize,
                                       0);
    if (theErr != noErr) {
        return nil;
    }
    
    CFDictionaryRef dictionary;
    theErr = AudioFileGetProperty (audioFile,
                                   kAudioFilePropertyInfoDictionary,
                                   &dictionarySize,
                                   &dictionary);
    if (theErr != noErr) {
        return nil;
    }
    
    NSDictionary *resultDic = (__bridge NSDictionary *)(dictionary);  //Convert
    CFRelease (dictionary);
    theErr = AudioFileClose (audioFile);
    
    return resultDic;
}

@end
