//
//  ZDDataRequest.h
//  Zhidao
//
//  Created by Nick Yu on 12/16/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZDDataRequest : NSObject

/**
 *  查询对象
 */
@property (nonatomic)NSDictionary *requestTarget;
/**
 *  查询条件
 */
@property (nonatomic)NSDictionary *requestCondition;
/**
 *  结果排序
 */
@property (nonatomic)NSString *orderBy;
/**
 *  升序降序 需和orderBy结合使用
 */
@property (nonatomic,assign)BOOL isAsc;

@end
