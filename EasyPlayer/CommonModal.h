//
//  CommonModal.h
//  
//
//  Created by 王杰 on 15/10/18.
//
//

#import <Foundation/Foundation.h>

@interface CommonModal : NSObject<NSCoding>

+ (NSArray *)arrayFromJSON:(NSArray*)array;
- (instancetype)initFromDictionary:(NSDictionary*)json;

@end
