//
//  ViewController.m
//  DataManagerDemo
//
//  Created by Nick Yu on 12/19/13.
//  Copyright (c) 2013 Nick Yu. All rights reserved.
//

#import "ViewController.h"
#import "ZDDataManager.h"
#import "Question.h"
#import "Answer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    ZDDataManager * dataManager = [[ZDDataManager alloc] init];
    
    [dataManager setUpManagerWithSqliteName:@"DBFile" andVersionNum:1];
    
//    [dataManager queryWithDict:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
//         
//    }];
//    [dataManager renameModel:@"Answer" newName:@"newName" withBlock:^(BOOL success, NSError *error) {
//         
//    }];
  
    /*
    //
    [dataManager query:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {

    }];
    
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
 
    
    //插入数据
    [dataManager insert:@{@"answer": [NSKeyedArchiver archivedDataWithRootObject: answer],@"qid":@1250,@"hasoldmsg":@1} model:@"Question" withBlock:^(BOOL success, NSError *error) {
//    
    }];
//   
    [dataManager insertWithEntity:q2 model:@"Question" withBlock:^(BOOL success, NSError *error) {
        
    }];
//
//    [dataManager insertWithEntity:answer model:@"Answer" withBlock:^(BOOL success, NSError *error) {
//        
//    }];
    [dataManager query:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
        
    }];
    //删除数据
//    [dataManager delete:@{@"qid":@{@"operator":@"!=",@"value":@1236}} model:@"Question" withBlock:^(BOOL success, NSError *error) {
//        
//    }];
    
    //查询
    [dataManager query:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {

    }];
    
    ZDDataRequest * req = [[ZDDataRequest alloc] init];
    req.condition = @{@"qid":@{@"operator":@"!=",@"value":@1236}};
    
 
    [dataManager queryWithRequest:req model:@"Question" withBlock:^(BOOL success, NSArray *resultArray) {
        if (resultArray.count>0) {
            Question * ques = resultArray[0];

            //更新
            [ques setNewValue:[NSNumber numberWithBool:YES] forKey:@"hasoldmsg"];
            [dataManager updateEntity:ques model:@"Question" withBlock:^(BOOL success, NSError *error) {

            }];
            
            //删除
//            [dataManager deleteEntity:ques model:@"Question" withBlock:^(BOOL success, NSError *error) {
//            }];

        }
        
    }];
    
    
   // [dataManager update:@{@"piclist": [NSData data]} condiction:@{@"qid":@{@"operator":@">",@"value":@1236}} model:@"Question" withBlock:^(BOOL success, NSError *error) {
         
   // }];
    
    
    [dataManager query:nil model:@"Question" condiction:nil order:nil withBlock:^(BOOL success,NSArray *resultArray) {
      //  Question * ques = [[Question alloc] initWithProperties: resultArray[0]];

    }];
    
    
    
    //添加列
//    [dataManager addColumn:@{@"columnName": @"newColumn",@"columnType":@"VarChar",@"columnDefault":@"str"} model:@"Question" withBlock:^(BOOL success, NSError *error) {
//
//    }];
    
    
    
    //重命名
    //    [dataManager renameModel:config.QuestionName newName:@"Question" withBlock:^(BOOL success, NSError *error) {
    //        
    //    }];
     
     */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end



#pragma mark samples

/* condition sample
 NSDictionary *condiction = [NSDictionary dictionaryWithObjectsAndKeys:
 [NSNumber numberWithInt: qid], @"qid",
 [NSNumber numberWithInt: createTime], @"createTime",
 [NSNumber numberWithInt: fid], @"fid", nil];
 
 
 @{@"qid":@{@"operator":@"!=",@"value":@1236}};
 操作符目前只 支持 = != > <
*/

/*
 order sample
 @{@"by": @"createTime", @"type": @"ASC"}
*/


