//
//  Answer.m
//  DataManagerDemo
//
//  Created by Nick Yu on 12/20/13.
//  Copyright (c) 2013 Nick Yu. All rights reserved.
//

#import "Answer.h"

@implementation Answer

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt64: self.aid forKey: @"aid"];
    [aCoder encodeObject: self.content forKey: @"content"];
    
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.aid = [aDecoder decodeInt64ForKey: @"aid"];
        self.content = [aDecoder decodeObjectForKey: @"content"];
        
    }
    return self;
}
@end
