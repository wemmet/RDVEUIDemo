//
//  NSBundle+Language.m
//  Reson8
//
//  Created by 王全洪 on 2018/4/28.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "NSBundle+Language.h"
#import <objc/runtime.h>

static const char _bundle = 0;

@interface BundleEx : NSBundle

@end

@implementation BundleEx

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSBundle *bundle = objc_getAssociatedObject(self, &_bundle);
    return bundle ? [bundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
}


@end

@implementation NSBundle (Language)


+ (BOOL)isEnglishLanguage{
    NSString *appLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppLanguage"];
    NSString *appleLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0];
    
    if([appLanguage hasPrefix:@"en"]){
        return YES;
    }else if([appLanguage hasPrefix : @"zh-Hans"]){
        return NO;
    }else if([appleLanguages hasPrefix:@"en"]){
        return YES;
    }else{
        return NO;
    }
}

+ (void)setLanguage:(NSString *)language {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass([NSBundle mainBundle], [BundleEx class]);
    });
    
    objc_setAssociatedObject([NSBundle mainBundle], &_bundle, language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
