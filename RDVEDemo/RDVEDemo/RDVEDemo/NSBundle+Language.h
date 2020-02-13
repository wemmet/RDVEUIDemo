//
//  NSBundle+Language.h
//  Reson8
//
//  Created by 王全洪 on 2018/4/28.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (Language)

+ (BOOL)isEnglishLanguage;

+ (void)setLanguage:(NSString *)language;

@end
