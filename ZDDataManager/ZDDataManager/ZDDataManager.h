//
//  ZDDataManager.h
//  Zhidao
//
//  Created by Nick Yu on 12/11/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZDDataRequest.h"

typedef enum {
    ZDDataStoreTypeSQLite,
    ZDDataStoreTypePlist
}ZDDataStoreType;


#if NS_BLOCKS_AVAILABLE
typedef void (^ZDDMQueryBlock)(BOOL success, NSArray *resultArray);
typedef void (^ZDDMUpdateBlock)(BOOL success, NSError *error);
typedef void (^ZDDMCheckBlock)(BOOL success, NSError *error);

#endif


@interface ZDDataManager : NSObject

/**
 *  数据库存储路径
 */
@property(nonatomic) NSString * mLocalSqlitePath;
/**
 *  DataManager 存储文件夹
 */
@property(nonatomic) NSString * mLocalDataFolder;
/**
 *  版本
 */
@property(nonatomic,assign) int mCurrentVersion;

/**
 *  单例方法
 *
 *  @return ZDDataManager 单例
 */
+(ZDDataManager*)sharedManager;

/**
 *  设置DataManager 这个应该是DataManager的入口初始化
 *
 *  @param name    名称
 *  @param version 版本号
 */
-(void)setUpManagerWithSqliteName:(NSString *)name andVersionNum:(int)version;

/**
 *  增加数据源处理器Coordinator ，新建数据模块
 *
 *  @param modelType 存储类型
 *  @param modelName 模块名称
 *  @param schema    模块结构
 *  @param option    模块附加设置
 */
-(void)addDataStoreAndCreateModelWithType:(ZDDataStoreType)modelType model:(NSString*)modelName andSchema:(NSDictionary*)schema andOption:(NSDictionary*)option;

/**
 *  增加数据源处理器Coordinator
 *
 *  @param storeType 存储类型
 *  @param modelName 模块名称
 */
-(void)addDataStoreWithType:(ZDDataStoreType)storeType model:(NSString*)modelName;

/**
 *  新建数据模块
 *
 *  @param modelType 存储类型
 *  @param modelName 模块名称
 *  @param schema    模块结构
 *  @param option    模块附加设置
 */
-(void)createModelWithType:(ZDDataStoreType)modelType model:(NSString*)modelName andSchema:(NSDictionary*)schema andOption:(NSDictionary*)option;

/**
 *  删除一个数据模块
 *
 *  @param modelType 模块存储类型
 *  @param modelName 模块名称
 *  @param block     删除后回调
 */
-(void)removeModelWithType:(ZDDataStoreType)modelType model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  类方法 删除所有旧数据
 *
 *  @return 删除是否成功
 */
+(BOOL)dropAllOldData;

/**
 *  数据迁移
 */
-(void)migrateData;

 
//直接SQL 操作
/**
 *  通过sql语句查询（只对sqlite类型 数据模块有效）
 *
 *  @param sql   sql语句
 *  @param modelName 模块名称
 *  @param block 查询结果返回block回调
 */
- (void) queryWithSql:(NSString*)sql model:(NSString*)modelName withBlock:(ZDDMQueryBlock)block;

/**
 *  通过sql语句update 数据
 *
 *  @param sql   sql语句
 *  @param modelName 模块名称
 *  @param block update返回block回调
 */
- (void) updateWithSql:(NSString *)sql model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;


//使用Ary Dict 操作
/**
 *  通过Dictionary Array查询
 *
 *  @param target     返回的列
 *  @param modelName 模块名称
 *  @param condiction 查询条件
 *  @param order      结果排序
 *  @param block      查询结构返回block回调
 */
- (void) queryWithDict:(NSDictionary *)target model:(NSString*)modelName condiction:(NSDictionary *)condiction order:(NSDictionary *)order withBlock:(ZDDMQueryBlock)block;

/**
 *  通过Dictionary 插入单条数据
 *
 *  @param data  要插入的数据
 *  @param modelName 模块名称
 *  @param block 插入后block回调
 */
- (void) insertWithDict:(NSDictionary *)data model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 插入多条数据
 *
 *  @param dataArr dict数据的数组
 *  @param modelName 模块名称
 *  @param block 插入后block回调
 */
- (void) insertMultiData:(NSArray *)dataArr model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 更新数据
 *
 *  @param data       要更新的数据
 *  @param modelName 模块名称
 *  @param condiction 条件
 *  @param block      更新后block回调
 */
- (void) updateWithDict:(NSDictionary *)data condiction:(NSDictionary *)condiction model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 删除数据
 *
 *  @param condiction 删除条件
 *  @param modelName 模块名称
 *  @param block      删除后回调block
 */
- (void) deleteWithDict:(NSDictionary *)condiction model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  删除所有数据
 *
 *  @param modelName 模块名称
 *  @param block 删除后回调block
 */
- (void) deleteAllWithModel:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;


//对表操作
/**
 *  新添加一列
 *
 *  @param column 新增列的信息 包括名称，类型，默认值
 *  @param modelName 模块名称
 *  @param block  更新后回调
 */
- (void)addColumn:(NSDictionary*)column model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  修改一个model名
 *
 *  @param newName 新名称
 *  @param modelName 模块名称
 *  @param block   修改后回调
 */
- (void)renameModel:(NSString*)modelName newName:(NSString*)newName withBlock:(ZDDMUpdateBlock)block;


//使用Entity操作
/**
 *  通过ZDDataRequest查询 查询结构以Entity形式返回
 *
 *  @param request 查询条件
 *  @param modelName 模块名称
 *  @param block   返回结果回调
 */
- (void) queryWithRequest:(ZDDataRequest *)request model:(NSString*)modelName withBlock:(ZDDMQueryBlock)block;

/**
 *  通过Entity 新增一条数据
 *
 *  @param entity 要新增的entity
 *  @param modelName 模块名称
 *  @param block  新增后回调
 */
- (void) insertWithEntity:(id)entity model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Entity 插入多条数据（数据必须完整 否则失败）
 *
 *  @param entitys 要插入的entity数组
 *  @param modelName 模块名称
 *  @param block   插入后回调
 */
- (void) insertWithMultiEntity:(NSArray*)entitys model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Entity更新数据 （需先对[entity setNewValue: ForKey:]）
 *
 *  @param entity 修改的entity
 *  @param modelName 模块名称
 *  @param block  更新后回调
 */
- (void) updateEntity:(id)entity model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

/**
 *  删除一个Entity
 *
 *  @param entity 要删除的Entity
 *  @param modelName 模块名称
 *  @param block  删除后的回调
 */
- (void) deleteEntity:(id)entity model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block;

@end



/* condition sample
 NSDictionary *condiction = [NSDictionary dictionaryWithObjectsAndKeys:
 [NSNumber numberWithInt: qid], @"qid",
 [NSNumber numberWithInt: createTime], @"createTime",
 [NSNumber numberWithInt: fid], @"fid", nil];
 
 order sample
 @{@"by": @"createTime", @"type": @"ASC"}
 */


