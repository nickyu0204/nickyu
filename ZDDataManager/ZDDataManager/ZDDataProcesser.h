//
//  DBHelper.h
//  BaiduZhidao
//
//  Created by Nick Yu on 12/11/13.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"
 
#import "ZDDataManager.h"



@interface ZDDataProcesser : NSObject
{
    /**
     *  处理业务的queue
     */
    dispatch_queue_t queue;
    /**
     *  存储plist文件的 临时数组
     */
    NSMutableArray * dataArray;
    
}
/**
 *  数据库
 */
@property(retain) FMDatabase *database;
/**
 *  文件的存储路径
 */
@property(retain) NSString* filePath;
/**
 *  模块名称
 */
@property(retain) NSString * modelName;
/**
 *  存储类型
 */
@property(assign) ZDDataStoreType storeType;

 
/**
 *  根据类型和名称 创建一个processer
 *
 *  @param modelName 模块名
 *  @param storeType 存储类型
 *
 *  @return processer实例
 */
-(id)initWithName:(NSString*)modelName andType:(ZDDataStoreType)storeType;

/**
 *  初始化数据库类型模块
 *
 *  @param databasePath 数据库路径
 *
 *  @return processer实例
 */
- (id) initWithDBPath:(NSString*)databasePath;

/**
 *  数据库 建表
 *
 *  @param schema  表结构
 *  @param _option 附加信息 如主键
 */
- (void) createTable:(NSDictionary *)schema andOption:(NSDictionary*)_option;

/**
 *  文件存储 新建文件
 *
 *  @param schema 文件结构
 */
- (void) createFile:(NSDictionary *)schema;

/**
 *  通过Dictionary 插入单条数据
 *
 *  @param data  要插入的数据
 *  @param block 插入后block回调
 */
- (void) insert: (NSDictionary *)schema data: (NSDictionary *)data withBlock: (ZDDMUpdateBlock)block;

/**
 *  通过Dictionary 插入多条数据
 *
 *  @param dataArr dict数据的数组
 *  @param block 插入后block回调
 */
- (void) insertMultiData: (NSDictionary *)schema data: (NSArray *)dataArr withBlock: (ZDDMUpdateBlock)block;

/**
 *  通过sql语句查询（只对sqlite类型 数据模块有效）
 *
 *  @param sql   sql语句
 *  @param block 查询结果返回block回调
 */
- (void) query:(NSString*)sql withBlock:(ZDDMQueryBlock)block;

/**
 *  通过sql语句update 数据
 *
 *  @param sql   sql语句
 *  @param block update返回block回调
 */
-(void) update:(NSString*)sql withBlock:(ZDDMUpdateBlock)block;

/**
 *  通过Dictionary Array查询
 *
 *  @param target     返回的列
 *  @param condiction 查询条件
 *  @param order      结果排序
 *  @param block      查询结构返回block回调
 */
- (void) query:(NSString *)table target:(NSDictionary *)target condiction:(NSDictionary *)condiction order:(NSDictionary *)order  withBlock:(ZDDMQueryBlock) block;

/**
 *  通过Dictionary 更新数据
 *
 *  @param data       要更新的数据
 *  @param condiction 条件
 *  @param block      更新后block回调
 */
- (void) update: (NSDictionary *)schema newData: (NSDictionary *)data condiction: (NSDictionary *)condiction withBlock: (ZDDMUpdateBlock)block;
/**
 *  通过Dictionary 删除数据
 *
 *  @param condiction 删除条件
 *  @param block      删除后回调block
 */
- (void) delete: (NSString *)table condiction: (NSDictionary *) condiction withBlock: (ZDDMUpdateBlock)block;

/**
 *  使用sql语句删除数据
 *
 *  @param block 删除后回调block
 */
- (void) deleteWithSql: (NSString *)sql withBlock: (ZDDMUpdateBlock)block;




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
 *  删除模块
 *
 *  @param block 删除后回调
 */
- (void) dropModelWithBlock:(ZDDMUpdateBlock)block;

@end
