//
//  Answer.h
//  DataManagerDemo
//
//  Created by Nick Yu on 12/20/13.
//  Copyright (c) 2013 Nick Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZDDataEntity.h"

@interface Answer : ZDDataEntity <NSCoding>


@property (nonatomic, assign) int64_t aid;
@property (nonatomic, strong) NSString * content;
 
@end
