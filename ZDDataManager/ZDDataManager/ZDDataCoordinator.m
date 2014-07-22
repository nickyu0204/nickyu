//
//  ZDDataProcesser.m
//  Zhidao
//
//  Created by Nick Yu on 12/11/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import "ZDDataCoordinator.h"
#import "ZDDataEntity.h"
#import <objc/runtime.h>

@interface ZDDataCoordinator()
{
    NSMutableDictionary * dataProcesserDict;
}
@end


@implementation ZDDataCoordinator

- (id)initWithDataType:(ZDDataStoreType)storeType modelName:(NSString*)modelName 
{
    self = [super init];
    if (self) {
       
        _processer = [[ZDDataProcesser alloc] initWithName:modelName andType:storeType];
        
        self.modelName = modelName;
        self.storeType = storeType;
        
 
    }
    return self;

}

-(void)createModelWithSchema:(NSDictionary* )schema andOption:(NSDictionary *)option
{
    self.modelSchema = schema;
    self.modelOption = option;
    
    if (self.storeType == ZDDataStoreTypeSQLite) {
        //建表
        
        [self.processer createTable:schema andOption:option];
        
    }
    else
    {
        [self.processer createFile:schema];
        
    }

}

-(void)removeModelWithBlock:(ZDDMUpdateBlock)block
{
    [self.processer dropModelWithBlock:block];
}

#pragma mark - sql operation

- (void) queryWithSql:sql withBlock:(ZDDMQueryBlock)block
{
    [self.processer query:sql withBlock:block];
}

- (void) updateWithSql:sql withBlock:(ZDDMUpdateBlock)block
{
    [self.processer update:sql withBlock:block];
}


#pragma mark - Dictionary operation

- (void) queryWithDict:(NSDictionary *)target condiction:(NSDictionary *)condiction order:(NSDictionary *)order withBlock:(ZDDMQueryBlock)block
{
    [self.processer query: self.modelName target: target condiction: condiction order: order withBlock: block];
}

- (void) insertWithDict:(NSDictionary *)data withBlock:(ZDDMUpdateBlock)block
{
    [self.processer insert: self.modelSchema data: data withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];
}

- (void) insertMultiData:(NSArray *)dataArr withBlock:(ZDDMUpdateBlock)block
{
    [self.processer insertMultiData: self.modelSchema data: dataArr withBlock:^(BOOL success, NSError *error) {
        if (block) {
            block(success, error);
        }
    }];
}

- (void) updateWithDict:(NSDictionary *)data condiction:(NSDictionary *)condiction withBlock:(ZDDMUpdateBlock)block
{
    [self.processer update: self.modelSchema newData: data condiction: condiction withBlock: block];
}

- (void) deleteWithDict:(NSDictionary *)condiction withBlock:(ZDDMUpdateBlock)block
{
    [self.processer delete: self.modelName condiction: condiction withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];
}

- (void) deleteAll:(ZDDMUpdateBlock)block
{
    [self.processer deleteWithSql: [NSString stringWithFormat: @"DELETE FROM %@ ", self.modelName] withBlock: block];
}

#pragma mark - Entity operation

- (void) queryWithRequest:(ZDDataRequest *)request withBlock:(ZDDMQueryBlock)block
{
    NSDictionary * order = nil;
    if (request.orderBy) {
          order = @{@"by": request.orderBy,@"type":request.isAsc?@"ASC":@"DESC"};
    }
   
    [self.processer query: self.modelName target: request.requestTarget condiction: request.requestCondition order: order withBlock:^(BOOL success, NSArray *resultArray) {
        
        
        NSMutableArray* ary  = [NSMutableArray array];
        for (NSDictionary * dic in resultArray) {

            id objByReflection = [[NSClassFromString(self.modelName) alloc] initWithProperties:dic];

            [ary addObject:objByReflection];
        }
        block(success,ary);
        
    }];
    
}
- (void) insertWithEntity:(id)entity withBlock:(ZDDMUpdateBlock)block
{
    NSMutableDictionary* data = [NSMutableDictionary dictionary];
 
    unsigned int propsCount, i;
    objc_property_t *props = class_copyPropertyList([NSClassFromString(self.modelName) class], &propsCount);
    for (i = 0; i < propsCount; i++) {
        objc_property_t prop = props[i];
        const char * propName = property_getName(prop);
        id value = [entity valueForKey:[NSString stringWithUTF8String:propName]];
        if (value) {
            if ([value isKindOfClass:[ZDDataEntity class]]) {
                value = [NSKeyedArchiver archivedDataWithRootObject: value];
            }
            [data setObject:value forKey:[NSString stringWithUTF8String:propName]];
        }
        
    }

    
    [self.processer insert: self.modelSchema data: data withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];
}

- (void) insertWithMultiEntity:(NSArray*)entitys withBlock:(ZDDMUpdateBlock)block
{
    NSMutableArray* dataAry = [NSMutableArray array];
    
    for (id entity in entitys) {
        NSMutableDictionary* data = [NSMutableDictionary dictionary];
        
        unsigned int propsCount, i;
        objc_property_t *props = class_copyPropertyList([NSClassFromString(self.modelName) class], &propsCount);
        for (i = 0; i < propsCount; i++) {
            objc_property_t prop = props[i];
            const char * propName = property_getName(prop);
            id value = [entity valueForKey:[NSString stringWithUTF8String:propName]];
            if (value) {
                if ([value isKindOfClass:[ZDDataEntity class]]) {
                    value = [NSKeyedArchiver archivedDataWithRootObject: value];
                }
                [data setObject:value forKey:[NSString stringWithUTF8String:propName]];
            }
            
        }

        [dataAry addObject:data];
    }
    
    
    [self.processer insertMultiData: self.modelSchema data: dataAry withBlock:^(BOOL success, NSError *error) {
        if (block) {
            block(success, error);
        }
    }];
}

- (void) updateEntity:(id)entity withBlock:(ZDDMUpdateBlock)block
{
    NSMutableDictionary* data = [NSMutableDictionary dictionary];
    
    unsigned int propsCount, i;
    objc_property_t *props = class_copyPropertyList([NSClassFromString(self.modelName) class], &propsCount);
    for (i = 0; i < propsCount; i++) {
        objc_property_t prop = props[i];
        const char * propName = property_getName(prop);
        id value = [entity valueForKey:[NSString stringWithUTF8String:propName]];
        if (value) {
            if ([value isKindOfClass:[ZDDataEntity class]]) {
                value = [NSKeyedArchiver archivedDataWithRootObject: value];
            }
            [data setObject:value forKey:[NSString stringWithUTF8String:propName]];
        }
        
    }
    
    
   [self.processer update: self.modelSchema newData: ((ZDDataEntity*)entity).changedKeyValueDict condiction: data withBlock:^(BOOL success, NSError *error) {
       if (success) {
           [((ZDDataEntity*)entity).changedKeyValueDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
               [entity setValue:obj forKey:key];
           }];
           [((ZDDataEntity*)entity).changedKeyValueDict removeAllObjects];
           
       }
       block(success,error);

   }];
}

- (void) deleteEntity:(id)entity withBlock:(ZDDMUpdateBlock)block
{
    NSMutableDictionary* condiction = [NSMutableDictionary dictionary];
    
    unsigned int propsCount, i;
    objc_property_t *props = class_copyPropertyList([NSClassFromString(self.modelName) class], &propsCount);
    for (i = 0; i < propsCount; i++) {
        objc_property_t prop = props[i];
        const char * propName = property_getName(prop);
        id value = [entity valueForKey:[NSString stringWithUTF8String:propName]];
        if (value) {
            if ([value isKindOfClass:[ZDDataEntity class]]) {
                value = [NSKeyedArchiver archivedDataWithRootObject: value];
            }
            [condiction setObject:value forKey:[NSString stringWithUTF8String:propName]];
        }
        
    }
    
    
    [self.processer delete: self.modelName condiction: condiction withBlock: ^(BOOL success, NSError *error){
        if (block) {
            block(success, error);
        }
    }];}


#pragma mark - table update operation

- (void)addColumn:(NSDictionary*)column withBlock:(ZDDMUpdateBlock)block
{
    [self.processer addColumn:column withBlock:block];
}

- (void)renameModel:(NSString*)newName withBlock:(ZDDMUpdateBlock)block
{
    [self.processer renameModel:newName withBlock:block];
}
@end
