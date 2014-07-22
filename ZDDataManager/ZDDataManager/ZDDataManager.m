//
//  ZDDataManager.m
//  Zhidao
//
//  Created by Nick Yu on 12/11/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import "ZDDataManager.h"
#import "ZDDataCoordinator.h"


#define kDataManagerDomain @"DataManagerDomain"
#define kNoDataSource      -1


static ZDDataManager * sharedInstance;

@interface ZDDataManager()
{
    /**
     *  数据处理coordinator 和 modelName 对应Dict
     */
    NSMutableDictionary * dataSourceDict;
}
@end

@implementation ZDDataManager

+(ZDDataManager*)sharedManager
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        if (sharedInstance==nil) {
            
            sharedInstance = [[super allocWithZone:NULL] init];
            
        }
        
    });
    return sharedInstance;

}

+ (id)allocWithZone:(NSZone *)zone

{
    
    return [self sharedManager];
    
}

+(BOOL)dropAllOldData
{
    NSError * error = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*  currentDataPath = [paths[0] stringByAppendingPathComponent:@"/DataManagerFiles"];

    [[NSFileManager defaultManager] removeItemAtPath:currentDataPath error:&error];
    [[NSFileManager defaultManager]  createDirectoryAtPath:currentDataPath withIntermediateDirectories:YES attributes:nil error:NULL];

    if (error) {
        return NO;
    }
    return YES;
}

/**
 *  推荐使用单例方式生产，本地存储一个版本信息 如果有旧数据 要做数据迁移
 *
 *  @return Manager 实例
 */
- (id)init
{
    self = [super init];
    if (self) {
        
        dataSourceDict = [[NSMutableDictionary alloc] initWithCapacity:5];
       
    }
    return self;
}

-(void)setUpManagerWithSqliteName:(NSString *)name andVersionNum:(int)version
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*  _diskDataPath = [paths[0] stringByAppendingPathComponent:@"/DataManagerFiles//"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:_diskDataPath])
    {
        [[NSFileManager defaultManager]  createDirectoryAtPath:_diskDataPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    self.mLocalSqlitePath = [_diskDataPath stringByAppendingString:[@"/" stringByAppendingString:name]];
    self.mLocalDataFolder = _diskDataPath;
    self.mCurrentVersion = version;
    
    int deviceVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DataConfigVersion"] intValue];
    
    //无旧数据 或已是新版数据后 直接创建数据源
    if (deviceVersion==0 || deviceVersion >= self.mCurrentVersion) {
        
        [self initDataSource];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.mCurrentVersion] forKey:@"DataConfigVersion"];
        
    }
    else
    {
        [self migrateData];
    }
    
}

-(void)initDataSource
{
    NSDictionary* config = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"DataConfigV%d",self.mCurrentVersion] ofType:@"plist"]];
    
    
    for (NSString* model in [config allKeys]) {
        
        [self addDataStoreWithType:[config[model][@"ModelType"] integerValue] model:config[model][@"ModelName"]];
        [self createModelWithType:[config[model][@"ModelType"] integerValue] model:config[model][@"ModelName"] andSchema:config[model][@"ModelSchema"] andOption:config[model][@"ModelOption"]];
        
        
    }

}

/**
 *  数据迁移 目前通过Plist文件方式实现，支持新增表 删除旧表 添加新字段 其他暂不支持
 */
-(void)migrateData
{
    int deviceVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DataConfigVersion"] intValue];

    NSDictionary* dicCurrent = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"DataConfigV%d",self.mCurrentVersion] ofType:@"plist"]];
    NSDictionary* dicOld = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"DataConfigV%d",deviceVersion] ofType:@"plist"]];
    
    
    //init coordinator first
    for (NSString* model in [dicCurrent allKeys]) {
        
        [self addDataStoreWithType:[dicCurrent[model][@"ModelType"] integerValue] model:dicCurrent[model][@"ModelName"]];
        
    }

    
    NSMutableSet * setCurrent = [NSMutableSet setWithArray:[dicCurrent allKeys]];
    NSMutableSet * setDevice = [NSMutableSet setWithArray:[dicOld allKeys]];
    
    // addTable
    [setCurrent minusSet:setDevice];
    for (NSString* key in setCurrent) {
        NSLog(@"add key %@",key);
        
        [self addDataStoreWithType:[dicCurrent[key][@"ModelType"] integerValue] model:dicCurrent[key][@"ModelName"]];
        [self createModelWithType:[dicCurrent[key][@"ModelType"] integerValue] model:dicCurrent[key][@"ModelName"] andSchema:dicCurrent[key][@"ModelSchema"] andOption:dicCurrent[key][@"ModelOption"]];
        
    }
    
   
    setCurrent = [NSMutableSet setWithArray:[dicCurrent allKeys]];
    [setDevice minusSet:setCurrent];
    // delete Table
    for (NSString* key in setDevice) {
        NSLog(@"drop key %@",key);
        
        [self removeModelWithType:[dicOld[key][@"ModelType"] intValue]model:key withBlock:^(BOOL success, NSError *error) {
            
        }];
    }
    
    setCurrent = [NSMutableSet setWithArray:[dicCurrent allKeys]];
    setDevice = [NSMutableSet setWithArray:[dicOld allKeys]];
    [setCurrent intersectSet:setDevice];
    for (NSString* model in setCurrent ) {
     
        NSDictionary* schemaCurrent = dicCurrent[model][@"ModelSchema"];
        NSDictionary* schemaOld = dicOld[model][@"ModelSchema"];

        NSMutableSet * columnCurrent = [NSMutableSet setWithArray:[schemaCurrent allKeys]];
        NSMutableSet * columnOld = [NSMutableSet setWithArray:[schemaOld allKeys]];
        [columnCurrent minusSet:columnOld];

        //add new columns
        for (NSString* columnName in columnCurrent) {
            NSLog(@"add column %@",columnName);
            
            [self addColumn:@{@"columnName": columnName,@"columnType":schemaCurrent[columnName]} model:model withBlock:^(BOOL success, NSError *error) {
                
            }];
        }
        
    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.mCurrentVersion] forKey:@"DataConfigVersion"];
    
}
/**
 *  数据检查 目前只是检查数据是否符合 表结构
 */
-(void)checkData
{
    
    NSDictionary* config = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"DataConfigV%d",self.mCurrentVersion] ofType:@"plist"]];
    
    for (NSString* model in [config allKeys]) {
        
        //校验迁移后数据
        [self checkModelValidateWithModel:model block:^(BOOL success, NSError *error) {
            if (success) {
                
            }
            else
            {
                [self checkModelDataFailed:model];
            }
        }];
    }

}
-(void)checkModelValidateWithModel:(NSString*)model block:(ZDDMCheckBlock)block
{
   
    ZDDataCoordinator * coordinator = dataSourceDict[model];
    if (coordinator==nil) {
        if (block) {
            block(NO,nil);
        }
    }
    [coordinator queryWithDict:nil condiction:nil order:nil withBlock:^(BOOL success, NSArray *resultArray) {
        success = YES;
        if (resultArray.count >0) {
            
            NSSet * setSample = [NSSet setWithArray:[coordinator.modelSchema allKeys]];
            for (NSDictionary * dict in resultArray) {
                NSSet * set = [NSSet setWithArray:[dict allKeys]];
                if (![set isEqualToSet:setSample]) {
                    success = NO;
                }
            }
        }
        block(success,nil);
    }];
    
    
}

-(void)checkModelDataFailed:(NSString*)model
{
    NSDictionary* config = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"DataConfigV%d",self.mCurrentVersion] ofType:@"plist"]];
    
    [self removeModelWithType:[config[model][@"ModelType"] integerValue] model:model withBlock:^(BOOL success, NSError *error) {
        if (success) {
            [self addDataStoreWithType:[config[model][@"ModelType"] integerValue] model:config[model][@"ModelName"]];
            [self createModelWithType:[config[model][@"ModelType"] integerValue] model:config[model][@"ModelName"] andSchema:config[model][@"ModelSchema"] andOption:config[model][@"ModelOption"]];
             
            
        }
    }];
    
    
        
    
}



-(void)addDataStoreWithType:(ZDDataStoreType)storeType model:(NSString*)modelName
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator == nil) {
        coordinator = [[ZDDataCoordinator alloc] initWithDataType:storeType modelName:modelName];
    
        [dataSourceDict setObject:coordinator forKey:modelName];

    }
    
}

-(void)createModelWithType:(ZDDataStoreType)modelType model:(NSString*)modelName andSchema:(NSDictionary*)schema andOption:(NSDictionary*)option
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        coordinator = [[ZDDataCoordinator alloc] initWithDataType:modelType modelName:modelName];
        
        [dataSourceDict setObject:coordinator forKey:modelName];
    }
    
    [coordinator createModelWithSchema:schema andOption:option];
}

-(void)addDataStoreAndCreateModelWithType:(ZDDataStoreType)modelType model:(NSString*)modelName andSchema:(NSDictionary*)schema andOption:(NSDictionary*)option
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        coordinator = [[ZDDataCoordinator alloc] initWithDataType:modelType modelName:modelName];
        
        [dataSourceDict setObject:coordinator forKey:modelName];
    }
    
    [coordinator createModelWithSchema:schema andOption:option];
}

-(void)removeModelWithType:(ZDDataStoreType)modelType model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        coordinator = [[ZDDataCoordinator alloc] initWithDataType:modelType modelName:modelName];
        
        [dataSourceDict setObject:coordinator forKey:modelName];
    }
    [coordinator removeModelWithBlock:^(BOOL success, NSError *error) {
        if (success) {
            [dataSourceDict removeObjectForKey:modelName];
        }
        block(success,error);
    }];
}

#pragma mark Data Operations

- (void) queryWithSql:(NSString*)sql model:(NSString*)modelName withBlock:(ZDDMQueryBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator queryWithSql:sql withBlock:block];
}

- (void) updateWithSql:(NSString *)sql  model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator updateWithSql:sql withBlock: block];
}

- (void) queryWithDict:(NSDictionary *)target model:(NSString*)modelName condiction:(NSDictionary *)condiction order:(NSDictionary *)order withBlock:(ZDDMQueryBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator queryWithDict: target condiction: condiction order: order withBlock: block];
}

- (void) insertWithDict:(NSDictionary *)data model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator insertWithDict: data withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];
}
- (void) insertMultiData:(NSArray *)dataArr model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator insertMultiData: dataArr withBlock:^(BOOL success, NSError *error) {
        if (block) {
            block(success, error);
        }
    }];
}

- (void) updateWithDict:(NSDictionary *)data condiction:(NSDictionary *)condiction model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator updateWithDict: data condiction: condiction withBlock: block];
}

- (void) deleteWithDict:(NSDictionary *)condiction model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator deleteWithDict: condiction withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];
}

- (void) deleteAllWithModel:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator deleteAll:block];
}

#pragma mark Data Model Update
- (void)addColumn:(NSDictionary*)column model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator addColumn: column withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];
}

- (void)renameModel:(NSString*)modelName newName:(NSString*)newName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator renameModel:newName  withBlock: ^(BOOL success, NSError *error){
        
        if (success) {
            [dataSourceDict setObject:coordinator forKey:newName];
            [dataSourceDict removeObjectForKey:modelName];
        }
        if (block) {
            block(success, error);
        }
    }];
}

- (void) queryWithRequest:(ZDDataRequest *)request model:(NSString*)modelName withBlock:(ZDDMQueryBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator queryWithRequest:request withBlock:block];
}

- (void) insertWithEntity:(id)entity model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator insertWithEntity:entity withBlock:block];

}
- (void) insertWithMultiEntity:(NSArray*)entitys model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator insertWithMultiEntity:entitys withBlock:block];
    
}

- (void) updateEntity:(id)entity model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator updateEntity:entity withBlock:block];
    
}

- (void) deleteEntity:(id)entity model:(NSString*)modelName withBlock:(ZDDMUpdateBlock)block
{
    ZDDataCoordinator * coordinator = dataSourceDict[modelName];
    if (coordinator==nil) {
        if (block) {
            block(NO, [NSError errorWithDomain:kDataManagerDomain code:kNoDataSource userInfo:@{@"NSLocalizedDescription":@"No DataSource"}]);
        }
    }
    [coordinator deleteEntity:entity withBlock:block];
    
}

@end
