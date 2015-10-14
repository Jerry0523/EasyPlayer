//
//  AppDelegate.m
//  EasyPlayer
//
//  Created by Jerry Wong's Mac Mini on 15/10/13.
//  Copyright © 2015年 Jerry Wong. All rights reserved.
//

#import "AppDelegate.h"
#import "PlayerViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) PlayerViewController *playerController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.playerController = [[PlayerViewController alloc] initWithWindowNibName:@"PlayerViewController"];
    [self.playerController showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
