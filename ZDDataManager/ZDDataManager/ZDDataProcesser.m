//
//  DBHelper.m
//  BaiduZhidao
//
//  Created by Nick Yu on 12/11/13.
//
//

#import "ZDDataProcesser.h"
#import "FMResultSet.h"


 
@implementation ZDDataProcesser

@synthesize database;





-(id)initWithName:(NSString*)modelName andType:(ZDDataStoreType)storeType
{
    self.modelName = modelName;
    self.storeType = storeType;
    
    if (storeType == ZDDataStoreTypePlist) {
        
        self = [self initWithFilePath:[[ZDDataManager sharedManager].mLocalDataFolder stringByAppendingString:[@"/" stringByAppendingString:self.modelName]]];

    }
    else
    {
        self = [self initWithDBPath:[ZDDataManager sharedManager].mLocalSqlitePath];
    }

    if (self) {
     
        NSString * queueName = [NSString stringWithFormat:@"com.baidu.iknow.%@",self.modelName];
        queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        
    }
    return  self;
}

- (id) initWithDBPath:(NSString*)path
{
    self = [super init];
    if (self) {
        self.database = [FMDatabase databaseWithPath: path];
        [self.database open];
          }
    return  self;
}
- (id) initWithFilePath:(NSString*)path
{
    self = [super init];
    if (self) {
        self.filePath = path;
       
    }
    return  self;
}

 
- (void) createTable:(NSDictionary *)schema andOption:(NSDictionary*)_option
{
    NSDictionary *structure = schema;
    NSArray *option = [_option objectForKey: @"primaryKey"];
    NSMutableString *sql = [NSMutableString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@", self.modelName];
    NSMutableArray *keyAndValues = [NSMutableArray arrayWithCapacity: 0];
    
    for (id key in structure) {
        [keyAndValues addObject: [NSString stringWithFormat: @"%@ %@", key, [structure objectForKey: key]]];
    }
    NSMutableString *optionString = [NSMutableString stringWithString: @""];
    if (option != nil) {
        optionString = (NSMutableString *)[optionString stringByAppendingFormat: @"PRIMARY KEY(%@)",[option componentsJoinedByString: @","]];
        sql = (NSMutableString *)[sql stringByAppendingFormat: @"(%@, %@)",[keyAndValues componentsJoinedByString: @", "], optionString];
    } else {
        sql = (NSMutableString *)[sql stringByAppendingFormat: @"(%@)",[keyAndValues componentsJoinedByString: @", "]];
    }
    
    [self sqlUpdateOperation: sql arugments: nil withBlock: nil];
}

- (void) createFile:(NSDictionary *)schema
{
 
    NSString * filePath = [[ZDDataManager sharedManager].mLocalDataFolder stringByAppendingString: [@"/" stringByAppendingString:self.modelName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        NSArray * ary = [NSArray array];
        [ary writeToFile:filePath atomically:NO];
    }
}
- (void) dropModelWithBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self deletePlistFileWithBlock:block];
        return;
    }
    NSMutableString *sql = [NSMutableString stringWithFormat: @"DROP TABLE IF EXISTS %@", self.modelName];
    [self sqlUpdateOperation: sql arugments: nil withBlock: block];

}

-(void) query:(NSString*)sql withBlock:(ZDDMQueryBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        block(NO,[NSError errorWithDomain:@"DataManagerDomain" code:1001 userInfo:@{@"NSLocalizedDescription":@"Plist Not Support"}]);
    }
    else
        [self sqlQueryOperation: sql arguments: nil withBlock: block];
}

-(void) update:(NSString*)sql withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        block(NO, [NSError errorWithDomain:@"DataManagerDomain" code:1001 userInfo:@{@"NSLocalizedDescription":@"Plist Not Support"}]);
    }
    else
        [self sqlUpdateOperation:sql arugments:nil withBlock: block];
}

- (void) insert:(NSDictionary *)schema data:(NSDictionary *)data withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self insertPlist: schema data: data withBlock: block];
        return;
    }
   
    NSMutableString *sql = [NSMutableString stringWithFormat: @"INSERT OR REPLACE INTO %@", self.modelName];
    NSMutableArray *mergeKey = [NSMutableArray arrayWithCapacity: 0];
    NSMutableArray *mergeValue = [NSMutableArray arrayWithCapacity: 0];
    NSMutableArray *questionMark = [NSMutableArray arrayWithCapacity: 0];
    for (NSString *key in schema ) {
        if (![data objectForKey: key]) {
            continue;
        }
        [mergeKey addObject: key];
        [mergeValue addObject: [data objectForKey: key]];
        [questionMark addObject: @"?"];
    }
    sql = (NSMutableString *)[sql stringByAppendingFormat: @"(%@) VALUES (%@)",[mergeKey componentsJoinedByString: @","] ,[questionMark componentsJoinedByString: @","]];
    
    [self sqlUpdateOperation: sql arugments: mergeValue withBlock: block];
}

- (void) insertMultiData:(NSDictionary *)schema data:(NSArray *)dataArr withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self insertMultiDatainPlist: schema data: dataArr withBlock: block];
        return;
    }

    NSMutableString *sql = [NSMutableString stringWithFormat: @"INSERT OR REPLACE INTO %@ SELECT ", self.modelName];
    NSMutableArray *mergeKey = [NSMutableArray arrayWithCapacity: 0];
    NSMutableArray *mergeValue = [NSMutableArray arrayWithCapacity: 0];
    NSMutableArray *questionMark = [NSMutableArray arrayWithCapacity: 0];
    NSDictionary *data = [dataArr lastObject];
    
    // SQL:
    // INSERT INTO CHATROOMMESSAGE_V3 SELECT ? AS msgData, ? AS fid, ? AS createTime, ? AS qid UNION SELECT ?,?,?,? 
    
    for (NSString *key in schema) {
        if (![data objectForKey: key]) {
            continue;
        }
    }
    
    NSMutableString *unionString = [NSMutableString stringWithString: @""];
    for (int i=0; i < dataArr.count; i++) {
        NSDictionary *item = [dataArr objectAtIndex: i];
        [questionMark removeAllObjects];
        for (NSString *key in schema  ) {
            if (![item objectForKey: key]) {
                continue;
            }
            if (i == 0) {
                [mergeKey addObject: [NSString stringWithFormat: @" ? AS %@", key]];
            } else {
                [questionMark addObject: @"?"];
            }
            [mergeValue addObject: [item objectForKey: key]];
        }
        if (i > 0) {
            unionString = (NSMutableString *)[unionString stringByAppendingFormat: @" UNION SELECT %@", [questionMark componentsJoinedByString: @","]];
        }
    }
    
    sql = (NSMutableString *)[sql stringByAppendingFormat: @"%@%@", [mergeKey componentsJoinedByString: @","], unionString];
    
    [self sqlUpdateOperation: sql arugments: mergeValue withBlock: block];
}


- (void) query:(NSString *)table target:(NSDictionary *)target condiction:(NSDictionary *)condiction order:(NSDictionary *)order  withBlock:(ZDDMQueryBlock) block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self _queryPlist: table target: target condiction: condiction order: order withBlock: block];
        return;
    }
    NSMutableString *sqlQuery = [NSMutableString stringWithString: @"SELECT "];
    NSMutableString *targetString = [NSMutableString stringWithString: @"* "];
    NSMutableString *condictionString = [NSMutableString stringWithString: @""];
    NSMutableString *orderString = [NSMutableString stringWithString: @" ORDER BY"];
    NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity: 0];
    
    if (target != nil) {
        targetString = [NSMutableString stringWithString:@" "];
        NSArray *keys = [target allKeys];
        NSString *condictionString = [keys componentsJoinedByString: @", "];
        targetString = (NSMutableString *)[targetString stringByAppendingString: condictionString];
    }
    sqlQuery = (NSMutableString *)[sqlQuery stringByAppendingFormat: @"%@ FROM %@ ", targetString, table];
    
    if (condiction != nil) {
 

        condictionString = [self convertCondition:condiction ToSql:condictionString AndArray:valueArr];
        sqlQuery = (NSMutableString *)[sqlQuery stringByAppendingFormat: @"WHERE %@", condictionString];
    }
    
    if (order != nil) {
        if ([order objectForKey: @"by"]) {
            orderString = (NSMutableString *)[orderString stringByAppendingFormat: @" %@", [order objectForKey: @"by"]];
            if ([order objectForKey: @"type"]) {
                orderString = (NSMutableString *)[orderString stringByAppendingFormat: @" %@", [order objectForKey: @"type"]];
            }
            sqlQuery = (NSMutableString *)[sqlQuery stringByAppendingString: orderString];
        }
    }
    

    [self sqlQueryOperation: sqlQuery arguments: valueArr withBlock: block];
     
}

- (void) update:(NSDictionary *)schema newData:(NSDictionary *)data condiction:(NSDictionary *)condiction withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self updatePlist: schema newData: data condiction: condiction withBlock: block];
        return;
    }
    
    NSMutableString *sql = [NSMutableString stringWithFormat: @"UPDATE %@ SET ", self.modelName];
    NSMutableArray *mergeKey = [NSMutableArray arrayWithCapacity: 0];
    NSMutableArray *mergeValue = [NSMutableArray arrayWithCapacity: 0];
    
    NSMutableString *condictionString = [NSMutableString stringWithString: @" WHERE "];
    for (NSString *key in schema ) {
        if ([data objectForKey: key]) {
            [mergeKey addObject: [NSString stringWithFormat: @"%@ = ?", key]];
            [mergeValue addObject: [data objectForKey: key]];
        }
    }
    sql = (NSMutableString *)[sql stringByAppendingFormat: @"%@",[mergeKey componentsJoinedByString: @","]];
    
    condictionString = [self convertCondition:condiction ToSql:condictionString AndArray:mergeValue];

    sql = (NSMutableString *)[sql stringByAppendingFormat: @"%@", condictionString];
    
    
    [self sqlUpdateOperation: sql arugments: mergeValue withBlock: block];
}



- (void) delete:(NSString *)table condiction:(NSDictionary *)condiction withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self deleteFile: table condiction: condiction withBlock: block];
        return;
    }
    NSMutableString *sql = [NSMutableString stringWithFormat: @"DELETE FROM %@", table];
    NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity: 0];
    NSMutableString *condictionString = [NSMutableString stringWithString: @" WHERE "];
    if (condiction != nil) {

        condictionString = [self convertCondition:condiction ToSql:condictionString AndArray:valueArr];
        sql = (NSMutableString *)[sql stringByAppendingString: condictionString];
    }
    
    [self sqlUpdateOperation: sql arugments: valueArr withBlock: block];
}

-(NSMutableString*)convertCondition:(NSDictionary*)condition ToSql:(NSMutableString*)condictionString AndArray:(NSMutableArray*)array
{
    NSArray *condictionKey = [condition allKeys];
    NSArray *condictionValue = [condition allValues];
    for (int i=0; i<condictionKey.count; i++) {
        if ([condictionValue[i] isKindOfClass:[NSDictionary class]]) {
            condictionString = (NSMutableString *)[condictionString stringByAppendingFormat: @"%@ %@ ?", [condictionKey objectAtIndex: i],condictionValue[i][@"operator"]];
            [array addObject: condictionValue[i][@"value"]];
            
        }
        else
        {
            condictionString = (NSMutableString *)[condictionString stringByAppendingFormat: @"%@ = ?", [condictionKey objectAtIndex: i]];
            [array addObject: condictionValue[i]];
            
        }
        if (i + 1 < [condictionKey count]) {
            condictionString = (NSMutableString *)[condictionString stringByAppendingString: @" AND "];
        }
        
        
    }

    return condictionString;
}

#pragma mark DB Operations

- (void) deleteWithSql:(NSString *)sql withBlock:(ZDDMUpdateBlock)block
{
    
    dispatch_async(queue, ^{
    
        BOOL result = [self.database executeUpdate: sql];
        if (block != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                if (block) {
                    block(YES, nil);
                }
                
            } else {
                if (block) {
                    block(NO, [self.database lastError]);
                }
                
            }
            });
        }
        
    });
   
}

- (void) sqlQueryOperation: (NSString *)sql arguments: (NSArray *)argument withBlock: (ZDDMQueryBlock) block
{
    dispatch_async(queue, ^{

        FMResultSet *result = [self.database executeQuery: sql withArgumentsInArray: argument];
        NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity: 0];
        if (result==nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(NO,resultArr);
                }
                
            });
        }
        else{
            
            while ([result next]) {
                NSDictionary *item = [result resultDict];
                [resultArr addObject: item];
            }
            if (block != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (block) {
                        block(YES,resultArr);
                    }
                    
                });
            }
            [result close];
        }
        
        
    });
}

- (void) sqlUpdateOperation: (NSString *)sql arugments: (NSArray *)argument withBlock: (ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{

        BOOL result = [self.database executeUpdate: sql withArgumentsInArray: argument];
        if (block != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) {
                    if (block) {
                         block(YES, nil);
                    }
                   
                } else {
                    if (block) {
                         block(NO, [self.database lastError]);
                    }
                   
                }
            });
        }
    });
}


- (void)addColumn:(NSDictionary*)column withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self addColumnToPlist:column withBlock:block];
    }
    else
    {
        NSString * columnName = column[@"columnName"];
        if (!columnName) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO,nil);
            });
            return;
        }
        NSString * columnType = column[@"columnType"];
        NSString * columnDefaultStr;
        id columnDefault = column[@"columnDefault"];
        if ([columnDefault isKindOfClass:[NSNumber class]]) {
            columnDefaultStr = [NSString stringWithFormat:@"DEFAULT %f",[columnDefault doubleValue]];
        }
        else
            columnDefaultStr = [NSString stringWithFormat:@"DEFAULT %@",columnDefault];

        NSString * sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@ %@",self.modelName,columnName,columnType?columnType:@"",columnDefaultStr];
        
        [self update:sql withBlock:block];
    }
}

- (void)renameModel:(NSString*)newName withBlock:(ZDDMUpdateBlock)block
{
    if (self.storeType == ZDDataStoreTypePlist) {
        [self renamePlist:newName withBlock:block];
    }
    else
    {
        if (newName) {
            NSString * sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@",self.modelName,newName];
            [self update:sql withBlock:^(BOOL success, NSError *error) {
                if (success) {
                    self.modelName = newName;
                }
                block(success,error);
            }];
        }
        else
            block(NO,nil);

    }
}



#pragma mark Plist Operations

- (void)initPlistDataWithArray:(NSArray*) array
{
    dispatch_async(queue, ^{
        [array writeToFile:self.filePath atomically:YES];
    });
}

-(void)deletePlistFileWithBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
        block(result,nil);
    });
}

- (void) _queryPlist:(NSString *)table target:(NSDictionary *)target condiction:(NSDictionary *)condiction order:(NSDictionary *)order withBlock:(ZDDMQueryBlock) block
{
    dispatch_async(queue, ^{


        dataArray = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        
       
        NSMutableArray * outputAry = [NSMutableArray arrayWithCapacity:10];
        
        for (id obj in dataArray) {
            
            if ([obj isKindOfClass:[NSDictionary class]]) {
                
                BOOL conditionOk = YES;
                
                if (condiction != nil) {
                    
                    conditionOk = [self checkConditionWithObj:obj condition:condiction];
                    
                }
                if (conditionOk) {
                    [outputAry addObject:obj];
                }
     
            }
            
        }
      
        
        if (order != nil) {

            NSSortDescriptor *sortDescriptor;
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:order[@"by"] ascending:[order[@"type"] isEqualToString:@"ASC"]?YES:NO];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            NSArray *sortedArray;
            sortedArray = [outputAry sortedArrayUsingDescriptors:sortDescriptors];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                block(YES,sortedArray);
            });
     
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{

                block(YES,outputAry);
            });
        }
    });
}

- (void) deleteFile:(NSString *)table condiction:(NSDictionary *)condiction withBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{


        dataArray = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        
        
        NSMutableArray * deleteAry = [NSMutableArray array];
        
        for (id obj in dataArray) {
            
            if ([obj isKindOfClass:[NSDictionary class]]) {
                
                BOOL conditionOk = YES;
                
                if (condiction != nil) {
                    
                    conditionOk = [self checkConditionWithObj:obj condition:condiction];

                }
                if (conditionOk) {
                    [deleteAry addObject:obj];
                }
                
            }
            
        }

        [dataArray removeObjectsInArray:deleteAry];
        BOOL succ = [dataArray writeToFile:self.filePath atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(succ,nil);
        });
    });

}

- (void) updatePlist:(NSDictionary *)schema newData:(NSDictionary *)data condiction:(NSDictionary *)condiction withBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{


        dataArray = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        
       
        NSMutableArray * tAry = [NSMutableArray array];
        for (id obj in dataArray) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                
                NSMutableDictionary *  mObj = [obj mutableCopy];
                
                BOOL conditionOk = YES;
                
                if (condiction != nil) {

                    conditionOk = [self checkConditionWithObj:mObj condition:condiction];
                }
                if (conditionOk) {
                    NSArray *dataKeys = [data allKeys];
                    NSArray *dataValues = [data allValues];
                    for (int i = 0; i < [dataKeys count]; i++) {
                        
                        [mObj setObject:dataValues[i] forKey:dataKeys[i]];
                        
                    }
                }
                
                
                [tAry addObject:mObj];
            }
            
        }
        
        BOOL succ = [tAry writeToFile:self.filePath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(succ,nil);
        });
        
    });
   
}
- (void) insertPlist:(NSDictionary *)schema data:(NSDictionary *)data withBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{


        dataArray = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        
        [dataArray addObject:data];
        
        BOOL succ = [dataArray writeToFile:self.filePath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(succ,nil);
        });
    });
    
}
- (void) insertMultiDatainPlist:(NSDictionary *)schema data:(NSArray *)dataAry withBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{


        dataArray = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        
        [dataArray addObjectsFromArray:dataAry];
        
        BOOL succ = [dataArray writeToFile:self.filePath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(succ,nil);
        });
    });
    
}

-(void)addColumnToPlist:(NSDictionary *)column  withBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{
        
        
        dataArray = [[NSMutableArray alloc] initWithContentsOfFile:self.filePath];
        
        
        NSString * columnName = column[@"columnName"];
        if (!columnName) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO,nil);
            });
            return;
        }
        //NSString * columnType = column[@"columnType"];
        id columnDefault = column[@"columnDefault"];
        
        NSMutableArray * array = [NSMutableArray array];
        [dataArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary * dict = [obj mutableCopy];
            
            [dict setObject:columnDefault forKey:columnName];
            [array addObject:dict];
        }];
        
        BOOL succ = [array writeToFile:self.filePath atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(succ,nil);
        });
    });
}

- (void)renamePlist:(NSString*)newName withBlock:(ZDDMUpdateBlock)block
{
    dispatch_async(queue, ^{
        NSError * err = NULL;
        NSFileManager * fm = [NSFileManager defaultManager];
        BOOL result = [fm moveItemAtPath:[[ZDDataManager sharedManager].mLocalDataFolder stringByAppendingString:[@"/" stringByAppendingString:self.modelName]] toPath:[[ZDDataManager sharedManager].mLocalDataFolder stringByAppendingString:[@"/" stringByAppendingString:newName]] error:&err];
        if (result) {
            self.modelName = newName;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            block(result,err);
        });
    });
}
//condition Check func
-(BOOL)checkConditionWithObj:(id)obj condition:(NSDictionary*)condiction
{
    BOOL conditionOk = NO;

    for (NSString * key in [condiction allKeys] ) {
        
        
        if([condiction[key] isKindOfClass:[NSDictionary class]])
        {
            if ([condiction[key][@"operator"] isEqualToString:@">"]) {
                if ([obj[key] doubleValue] > [condiction[key][@"value"] doubleValue]) {
                    conditionOk = YES;
                    break;
                }
            }
            if ([condiction[key][@"operator"] isEqualToString:@"<"]) {
                if ([obj[key] doubleValue] < [condiction[key][@"value"] doubleValue]) {
                    conditionOk = YES;
                    break;
                }
            }
            if ([condiction[key][@"operator"] isEqualToString:@"!="]) {
                if ([obj[key] doubleValue] != [condiction[key][@"value"] doubleValue]) {
                    conditionOk = YES;
                    break;
                }
            }
        }
        else if([condiction[key] isKindOfClass:[NSNumber class]])
        {
            if ([obj[key] doubleValue] == [condiction[key] doubleValue]) {
                conditionOk = YES;
                break;
            }
        }
        else if([condiction[key] isKindOfClass:[NSString class]])
        {
            if ([obj[key] isEqual:condiction[key]]) {
                conditionOk = YES;
                break;
            }
        }
        
    }
    
    return conditionOk;

}


@end
