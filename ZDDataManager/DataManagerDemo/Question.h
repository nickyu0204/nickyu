//
//  Question.h
//  Zhidao
//
//  Created by Nick Yu on 12/16/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import "ZDDataEntity.h"
#import "Answer.h"

@interface Question : ZDDataEntity <NSCoding>

@property (nonatomic, assign) int64_t qid;
@property (nonatomic, assign) int32_t hasoldmsg;
@property (nonatomic, strong) NSString *asker;
@property (nonatomic, strong) NSData *question;
@property (nonatomic, strong) NSData *piclist;
@property (nonatomic, strong) Answer *answer;

@end
