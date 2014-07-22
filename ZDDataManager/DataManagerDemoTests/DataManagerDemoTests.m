//
//  DataManagerDemoTests.m
//  DataManagerDemoTests
//
//  Created by Nick Yu on 12/19/13.
//  Copyright (c) 2013 Nick Yu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZDDataManager.h"
#import "Answer.h"
#import "Question.h"

@interface DataManagerDemoTests : XCTestCase

@end

@implementation DataManagerDemoTests

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    ZDDataManager * dataManager = [[ZDDataManager alloc] init];
    XCTAssertNotNil(dataManager,@"manager == nil");
}

- (void)testInsert
{
    Answer * answer = [[Answer alloc] init];
    answer.aid = 1001;
    answer.content = @"this is an answer";
    
    Question * q = [[Question alloc] init];
    q.qid = 1236;
    q.hasoldmsg = NO;
    q.answer = answer;
    
    Question * q2 = [[Question alloc] init];
    q2.qid = 1298;
    q2.hasoldmsg = YES;
    q2.answer = answer;
    
    Question * q3 = [[Question alloc] init];
    q3.qid = 1288;
    q3.hasoldmsg = NO;
    q3.asker = @"asker1288";
    q3.answer = answer;
    q3.piclist = [@"piclist" dataUsingEncoding:NSUTF8StringEncoding];
    q3.question = [@"question" dataUsingEncoding:NSUTF8StringEncoding];
    
    ZDDataManager * dataManager = [[ZDDataManager alloc] init];
    [dataManager setUpManagerWithSqliteName:@"DBFile" andVersionNum:1];

    [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
        XCTAssertTrue(success,@"Query Failed");
        
    }];
    
    [dataManager insertWithDict:@{@"answer": [NSKeyedArchiver archivedDataWithRootObject: answer],@"qid":@1250,@"hasoldmsg":@1} model:@"Question" withBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success,@"Insert Failed");

    }];
    
    [dataManager insertWithEntity:q model:@"Question" withBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success,@"Insert Entity Failed");
        
    }];
    
    [dataManager insertWithMultiEntity:@[q,q2] model:@"Question" withBlock:^(BOOL success, NSError *error) {
        //一次插入多条数据 必须保证所有字段 都有 这里应该是报错(DB）
        XCTAssertFalse(success,@"Insert Multi Failed");
        
    }];
    
    [dataManager insertWithMultiEntity:@[q3] model:@"Question" withBlock:^(BOOL success, NSError *error) {
        //一次插入多条数据 必须保证所有字段 都有
        XCTAssertTrue(success,@"Insert Multi Failed");
        
    }];
    
    [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
        XCTAssertTrue(success,@"Query Failed");
        
    }];
    [[NSRunLoop currentRunLoop] run];

}

-(void)testUpdate
{
    ZDDataManager * dataManager = [[ZDDataManager alloc] init];
    [dataManager setUpManagerWithSqliteName:@"DBFile" andVersionNum:1];

    [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
        XCTAssertTrue(success,@"Query Failed");
        
    }];
    
    [dataManager updateWithSql:@"update Question set hasoldmsg = 0 where qid >= 1250" model:@"Question" withBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success,@"Update Failed");

    }];
    [dataManager updateWithDict:@{@"hasoldmsg":@2} condiction:@{@"qid":@{@"operator":@"!=",@"value":@1236}} model:@"Question" withBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success,@"Update Failed");
     
    }];
    
    [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
        XCTAssertTrue(success,@"Query Failed");
        
    }];
    [[NSRunLoop currentRunLoop] run];

}

- (void)testQuery
{
    ZDDataManager * dataManager = [[ZDDataManager alloc] init];
    [dataManager setUpManagerWithSqliteName:@"DBFile" andVersionNum:1];

    [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
        XCTAssertTrue(success,@"Query Failed");

    }];
    
    ZDDataRequest * req = [[ZDDataRequest alloc] init];
    //req.condition = @{@"qid":@{@"operator":@"!=",@"value":@1236}};
    
    
    [dataManager queryWithRequest:req model:@"Question" withBlock:^(BOOL success, NSArray *resultArray) {
        
        XCTAssertTrue(success,@"Query Request Failed");

        if (resultArray.count>0) {
            Question * ques = resultArray[0];
            
            //更新
            [ques setNewValue:[NSNumber numberWithBool:YES] forKey:@"hasoldmsg"];
            [ques setNewValue:[@"new string" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"question"];

            [dataManager updateEntity:ques model:@"Question" withBlock:^(BOOL success, NSError *error) {
                XCTAssertTrue(success,@"Update Entity Request Failed");

            }];
            [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
                XCTAssertTrue(success,@"Query Failed");
                
            }];

            //删除
            [dataManager deleteEntity:ques model:@"Question" withBlock:^(BOOL success, NSError *error) {
                
                XCTAssertTrue(success,@"Delete Entity Request Failed");

            }];
            [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
                XCTAssertTrue(success,@"Query Failed");
                
            }];

            
        }

    }];
    
    [dataManager queryWithSql:@"select * from Question" model:@"Question" withBlock:^(BOOL success, NSArray *resultArray) {
        XCTAssertTrue(success,@"Delete Entity Request Failed");

    }];

    [[NSRunLoop currentRunLoop] run];

}

- (void)testDelete
{
    ZDDataManager * dataManager = [[ZDDataManager alloc] init];
    [dataManager setUpManagerWithSqliteName:@"DBFile" andVersionNum:1];

    Answer * answer = [[Answer alloc] init];
    answer.aid = 2001;
    answer.content = @" answer of 1123";
    
    Question * q = [[Question alloc] init];
    q.qid = 1123;
    q.hasoldmsg = NO;
    q.answer = answer;
    
    Question * q2 = [[Question alloc] init];
    q2.qid = 1124;
    q2.hasoldmsg = NO;
    q2.answer = answer;
    
    [dataManager insertWithEntity:q model:@"Question" withBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success,@"Insert Entity Failed");
        
    }];
    
    [dataManager deleteWithDict:@{@"qid":@1124} model:@"Question" withBlock:^(BOOL success, NSError *error){
    
        XCTAssertTrue(success,@"Delete Entity Failed");

    }];
    
    
    
    
    [dataManager deleteAllWithModel:@"Question" withBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success,@"Delete Entity Failed");

    }];
    
    [dataManager queryWithSql:@"select * from Question" model:@"Question" withBlock:^(BOOL success, NSArray *resultArray) {
        XCTAssertTrue(success,@"Delete Entity Request Failed");
        
    }];
    
    [[NSRunLoop currentRunLoop] run];

}



@end
