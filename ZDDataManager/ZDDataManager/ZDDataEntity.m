//
//  ZDBaseEntity.m
//  Zhidao
//
//  Created by Nick Yu on 12/19/13.
//  Copyright (c) 2013 Baidu. All rights reserved.
//

#import "ZDDataEntity.h"
#import <objc/runtime.h>


@implementation ZDDataEntity
- (id) initWithProperties:(NSDictionary *)properties
{
    if (self = [self init]) {
        
        self.changedKeyValueDict = [NSMutableDictionary dictionary];
        for (NSString *key in properties) {
            if ([self respondsToSelector: NSSelectorFromString(key)]) {
                
                if ([properties objectForKey: key] == NSNull.null) {
                    continue;
                }
                
                //运行时判断 太复杂 放到子类去自己实现吧
//                objc_property_t property =  class_getProperty([self class], [key cStringUsingEncoding:NSASCIIStringEncoding]);
//                const char *property_type = property_getAttributes(property);
//                
//                switch(property_type[1]) {
//                    case 'f' : //float
//                        break;
//                    case 's' : //short
//                        break;
//                    case '@' : //ObjC object
//                        //Handle different clases in here
//                         break;
//                }
                
                
                [self setValue: [properties objectForKey: key] forKey: key];
            }
        }
    }
    return self;
}

- (void)setNewValue:(id)value forKey:(NSString *)key
{
    if ([value isKindOfClass:[ZDDataEntity class]]) {
        value = [NSKeyedArchiver archivedDataWithRootObject: value];
    }
    [self.changedKeyValueDict setObject:value forKey:key];
}

//+ (id) customClassWithProperties:(NSDictionary *)properties
//{
//    return [[self alloc] initWithProperties: properties];
//}
//- (NSString *)printSelf
//{
//    unsigned int propsCount, i;
//    objc_property_t *props = class_copyPropertyList([self class], &propsCount);
//    NSMutableString *tmp = [[NSMutableString alloc] initWithCapacity:0];
//    for (i = 0; i < propsCount; i++) {
//        objc_property_t prop = props[i];
//        const char * propName = property_getName(prop);
//        id value = [self valueForKey:[NSString stringWithUTF8String:propName]];
//        [tmp appendFormat:@"%s=%@ ", propName, value];
//    }
//
//    NSLog(@"%@", tmp);
//    return tmp;
//}
//
//- (NSString *)description
//{
//    return [self printSelf];
//}
@end
