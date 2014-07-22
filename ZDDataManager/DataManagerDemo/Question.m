//
//  Question.m
//  Zhidao
//
//  Created by Nick Yu on 12/16/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import "Question.h"

@implementation Question

- (id)initWithProperties:(NSDictionary *)properties
{
    if ( self = [super initWithProperties:properties])
    {
        
        _answer  = [NSKeyedUnarchiver unarchiveObjectWithData:properties[@"answer"]];
     
        
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt64: self.qid forKey: @"qid"];
    [aCoder encodeInt32:self.hasoldmsg forKey:@"hasoldmsg"];
    [aCoder encodeObject:self.question forKey:@"question"];
    [aCoder encodeObject:self.piclist forKey:@"piclist"];
    [aCoder encodeObject:self.answer forKey:@"answer"];
    [aCoder encodeObject:self.asker forKey:@"asker"];
    
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.qid = [aDecoder decodeInt64ForKey: @"qid"];
        self.hasoldmsg = [aDecoder decodeInt32ForKey: @"hasoldmsg"];
        self.question = [aDecoder decodeObjectForKey:@"question"];
        self.piclist = [aDecoder decodeObjectForKey:@"piclist"];
        self.answer = [aDecoder decodeObjectForKey:@"answer"];
        self.asker = [aDecoder decodeObjectForKey:@"asker"];

    }
    return self;
}


@end
