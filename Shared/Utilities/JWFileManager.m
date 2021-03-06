//
//  MusicFileManager.m
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

#import "JWFileManager.h"
#import <CoreData/CoreData.h>
#import "EasyPlayer-Swift.h"

#import <Availability.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MediaPlayer/MediaPlayer.h>
#else
#import <iTunesLibrary/iTunesLibrary.h>
#import "JWMediaHelper.h"
#endif

@implementation JWFileManager

+ (NSString*)getAppRootPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES);
    if(paths.count > 0) {
        NSString *musicRootPath = [paths firstObject];
        NSString *appRootPath = [musicRootPath stringByAppendingPathComponent:@"EasyPlayer"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:appRootPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:appRootPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return appRootPath;
    }
    return nil;
}

+ (NSString*)getLrcPath {
    NSString *rootPath = [JWFileManager getAppRootPath];
    if (rootPath) {
        NSString *lrcPath = [rootPath stringByAppendingPathComponent:@"lrc"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:lrcPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:lrcPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return lrcPath;
    }
    return nil;
}

+ (NSString*)getCoverPath {
    NSString *rootPath = [JWFileManager getAppRootPath];
    if (rootPath) {
        NSString *albumPath = [rootPath stringByAppendingPathComponent:@"cover"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:albumPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:albumPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return albumPath;
    }
    return nil;
}

+ (NSString*)getMusicPath {
    NSString *rootPath = [JWFileManager getAppRootPath];
    if (rootPath) {
        NSString *musicPath = [rootPath stringByAppendingPathComponent:@"music"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:musicPath isDirectory:nil]) {
            [fileManager createDirectoryAtPath:musicPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        return musicPath;
    }
    return nil;
}

+ (NSArray*)getItunesMediaArray {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    NSMutableArray *mutable = [NSMutableArray array];
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    for (MPMediaItem *song in itemsFromGenericQuery) {
        if (song.mediaType == MPMediaTypeMusic && song.assetURL) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setObject:song.assetURL.absoluteString forKey:@"location"];
            
            if (song.title) {
                [info setObject:song.title forKey:@"name"];
            }
            if (song.artist) {
                [info setObject:song.artist forKey:@"artist"];
            }
            if (song.albumTitle) {
                [info setObject:song.albumTitle forKey:@"album"];
            }
            [info setObject:@(song.playbackDuration * 1000) forKey:@"TotalTime"];
            [info setObject:song forKey:@"userInfo"];
            
            JWTrack *track = [[JWTrack alloc] initFromDictionary:info];
            [mutable addObject:track];
        }
    }
    return mutable;
#else
    
    NSError * error = nil;
    ITLibrary* library = [[ITLibrary alloc] initWithAPIVersion:@"1.0" error:&error];
    NSMutableArray *mItems = [NSMutableArray array];
    if (library) {
        NSArray *mediaItems = library.allMediaItems;
        
        [mediaItems enumerateObjectsUsingBlock:^(ITLibMediaItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.location && !obj.drmProtected && obj.mediaKind == ITLibMediaItemMediaKindSong && obj.totalTime > 30000) {
                JWTrack *track = [[JWTrack alloc] initWithITMediaItem:obj];
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [JWMediaHelper cacheMetaForTrack:track force:NO];
                });
                [mItems addObject:track];
            }
        }];
    }
    return mItems;
#endif
}

+ (NSManagedObjectContext *)managedContext {
    static NSPersistentContainer *_persistentContainer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
        _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"MediaLibrary" managedObjectModel:model];
        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * description, NSError * error) {
            NSLog(@"%@",description);
            NSLog(@"%@",error);
        }];
    });
    return _persistentContainer.viewContext;
}

+ (NSArray*)getLocalMediaArray {
    NSMutableArray *mutable = [NSMutableArray array];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"JWMediaItemEntity"];
    
    NSError *error = nil;
    NSArray *data = [self.managedContext executeFetchRequest:request error:&error];
    for (JWMediaItemEntity *entity in data) {
        [mutable addObject:[entity toTrack]];
    }
    return mutable;
}

+ (void)addTrackToMediaLibrary:(JWTrack *)track {
    
    JWMediaItemEntity *mediaItem = [NSEntityDescription insertNewObjectForEntityForName:@"JWMediaItemEntity" inManagedObjectContext:self.managedContext];
    [mediaItem syncWithTrack:track];
    NSError *error = nil;
    [self.managedContext save:&error];
    [self copyTrackToLocalMediaPath:track];
}

+ (void)removeTrackFromMediaLibrary:(JWTrack *)track {
    NSError *error = nil;
    JWMediaItemEntity *mediaItem = [self.managedContext existingObjectWithID:track.id error:&error];
    
    if (mediaItem && !error) {
        [self.managedContext deleteObject:mediaItem];
    }
    [self.managedContext save:&error];
}

+ (BOOL)copyTrackToLocalMediaPath:(JWTrack*)track {
    NSString *newTrackName = track.name;
    NSString *newTrackArtist = track.artist;
    NSString *pathExtension = track.fileURL.pathExtension;
    
    NSString *fileName = newTrackName;
    if ([newTrackArtist length]) {
        fileName = [fileName stringByAppendingFormat:@"-%@",newTrackArtist];
    }
    if ([pathExtension length]) {
        fileName = [fileName stringByAppendingFormat:@".%@",pathExtension];
    }
    NSString *finalPath = [[self getMusicPath] stringByAppendingPathComponent:fileName];
    NSString *sourcePath = [track.location stringByRemovingPercentEncoding];
    if ([sourcePath hasPrefix:@"file://"] ) {
        sourcePath = [sourcePath substringFromIndex:7];
    }
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:finalPath error:&error];
    finalPath = [NSString stringWithFormat:@"file://%@", finalPath];
    finalPath = [finalPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    track.location = finalPath;
    return error != nil;
}

@end
