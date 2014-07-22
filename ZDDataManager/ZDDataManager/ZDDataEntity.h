//
//  ZDBaseEntity.h
//  Zhidao
//
//  Created by //  Created by Nick Yu on 12/19/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZDDataEntity : NSObject

@property (nonatomic, strong) NSMutableDictionary * changedKeyValueDict;

/**
 *  使用Dictionary 初始化 一个entity
 *
 *  @param properties entity对应的 dictionary
 *
 *  @return entity 实例
 */
- (id) initWithProperties: (NSDictionary *)properties;

/**
 *  对Entity 设置属性 用于DataManager updateWithEntity
 *
 *  @param value Entity的属性名
 *  @param key   新属性值
 */
- (void)setNewValue:(id)value forKey:(NSString *)key;
 
@end
