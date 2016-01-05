//
//  ViewController.h
//  EasyPlayerIOS
//
//  Created by Jerry Wong's Mac Mini on 16/1/4.
//  Copyright © 2016年 Jerry Wong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayListViewController : UITableViewController

@property (assign, nonatomic) NSArray *rawItems;

- (void)selectItem:(id)item;

@end

