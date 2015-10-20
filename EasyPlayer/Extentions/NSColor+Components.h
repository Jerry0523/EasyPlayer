//
//  NSColor+Components.h
//  
//
//  Created by 王杰 on 15/10/16.
//
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Components)

- (void)getRGBComponents:(CGFloat[4])components;
- (void)getHSBComponnets:(CGFloat[3])components;

@end
