//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "PlayerViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) PlayerViewController *playerController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {    
    self.playerController = [[PlayerViewController alloc] initWithWindowNibName:@"PlayerViewController"];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.playerController showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-  (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *pre = [[NSMenuItem alloc] initWithTitle:@"Previous" action:@selector(playPreSong) keyEquivalent:@""];
    NSMenuItem *play = [[NSMenuItem alloc] initWithTitle:self.playerController.isPlaying ? @"Pause" : @"Play" action:@selector(resumePlaySong) keyEquivalent:@""];
    NSMenuItem *next = [[NSMenuItem alloc] initWithTitle:@"Next" action:@selector(playNextSong) keyEquivalent:@""];
    [menu addItem:pre];
    [menu addItem:play];
    [menu addItem:next];
    return menu;
}

- (void)playPreSong {
    [self.playerController preClicked:nil];
}

- (void)resumePlaySong {
    [self.playerController playClicked:nil];
}

- (void)playNextSong {
    [self.playerController nextClicked:nil];
}

@end
