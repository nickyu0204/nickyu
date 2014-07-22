//
//  ZDDataProcesser.h
//  Zhidao
//
//  Created by Nick Yu on 12/11/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZDDataManager.h"
#import "ZDDataProcesser.h"

@interface ZDDataCoordinator : NSObject
/**
 *  存储类型
 */
@property(nonatomic,assign) ZDDataStoreType storeType;
/**
 *  model名称
 */
@property(nonatomic,strong) NSString * modelName;
/**
 *  model的结构，字段 类型等
 */
@property(nonatomic,strong) NSDictionary * modelSchema;
/**
 *  model的附加信息 如主键
 */
@property(nonatomic,strong) NSDictionary * modelOption;
/**
 *  model 对应的数据处理器 processer
 */
@property(nonatomic,strong) ZDDataProcesser * processer;


/**
 *  通过存储类型 和模块名初始化一个Coordinator
 *
 *  @param storeType 存储类型
 *  @param modelName 模块名
 *
 *  @return 模块对应的Coordinator实例
 */
- (id)initWithDataType:(ZDDataStoreType)storeType modelName:(NSString*)modelName;

/**
 *  根据模块结构 建立模块
 *
 *  @param schema 模块结构信息
 *  @param option 模块附加信息
 */
-(void)createModelWithSchema:(NSDictionary* )schema andOption:(NSDictionary *)option;

/**
 *  删除一个模块
 *
 *  @param block 删除成功的block回调
 */
-(void)removeModelWithBlock:(ZDDMUpdateBlock)block;


//query and update with sql
/**
 *  通过sql语句查询（只对sqlite类型 数据模块有效）
 *
 *  @param sql   sql语句
 *  @param block 查询结果返回block回调
 */
- (void) queryWithSql: (NSString*)sql withBlock:(ZDDMQueryBlock)block;
/**
 *  通过sql语句update 数据
 *
 *  @param sql   sql语句
 *  @param block update返回block回调
 */
- (void) updateWithSql:(NSString*)sql withBlock:(ZDDMUpdateBlock)block;

//query insert delete and update with Dict
/**
 *  通过Dictionary Array查询
 *
 *  @param target     返回的列
 *  @param condiction 查询条件
 *  @param order      结果排序
 *  @param block      查询结构返回block回调
 */
- (void) queryWithDict: (NSDictionary *)target condiction: (NSDictionary *)condiction order: (NSDictionary *)order withBlock: (ZDDMQueryBlock) block;

/**
 *  通过Dictionary 插入单条数据
 *
 *  @param data  要插入的数据
 *  @param block 插入后block回调
 */
- (void) insertWithDict: (NSDictionary *)data withBlock: (ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 插入多条数据
 *
 *  @param dataArr dict数据的数组
 *  @param block 插入后block回调
 */
- (void) insertMultiData: (NSArray *)dataArr withBlock: (ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 更新数据
 *
 *  @param data       要更新的数据
 *  @param condiction 条件
 *  @param block      更新后block回调
 */
- (void) updateWithDict: (NSDictionary *) data condiction: (NSDictionary *)condiction withBlock: (ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 删除数据
 *
 *  @param condiction 删除条件
 *  @param block      删除后回调block
 */
- (void) deleteWithDict: (NSDictionary *) condiction withBlock: (ZDDMUpdateBlock)block;

/**
 *  删除所有数据
 *
 *  @param block 删除后回调block
 */
- (void) deleteAll : (ZDDMUpdateBlock)block;

//model operation
/**
 *  新添加一列
 *
 *  @param column 新增列的信息 包括名称，类型，默认值
 *  @param block  更新后回调
 */
- (void)addColumn:(NSDictionary*)column withBlock:(ZDDMUpdateBlock)block;

/**
 *  修改一个model名
 *
 *  @param newName 新名称
 *  @param block   修改后回调
 */
- (void)renameModel:(NSString*)newName withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过ZDDataRequest查询 查询结构以Entity形式返回
 *
 *  @param request 查询条件
 *  @param block   返回结果回调
 */
- (void) queryWithRequest:(ZDDataRequest *)request withBlock:(ZDDMQueryBlock)block;

/**
 *  通过Entity 新增一条数据
 *
 *  @param entity 要新增的entity
 *  @param block  新增后回调
 */
- (void) insertWithEntity:(id)entity withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Entity 插入多条数据（数据必须完整 否则失败）
 *
 *  @param entitys 要插入的entity数组
 *  @param block   插入后回调
 */
- (void) insertWithMultiEntity:(NSArray*)entitys withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Entity更新数据 （需先对[entity setNewValue: ForKey:]）
 *
 *  @param entity 修改的entity
 *  @param block  更新后回调
 */
- (void) updateEntity:(id)entity withBlock:(ZDDMUpdateBlock)block;

/**
 *  删除一个Entity
 *
 *  @param entity 要删除的Entity
 *  @param block  删除后的回调
 */
- (void) deleteEntity:(id)entity withBlock:(ZDDMUpdateBlock)block;

@end
