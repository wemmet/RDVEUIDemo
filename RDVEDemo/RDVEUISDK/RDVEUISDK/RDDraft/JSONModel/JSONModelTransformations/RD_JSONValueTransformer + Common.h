//
//  JSONValueTransformer + Common.h
//  Reson8
//
//  Created by apple on 2018/1/17.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RD_JSONValueTransformer.h"
#import <UIKit/UIKit.h>

@interface RD_JSONValueTransformer (Common)

//CGSize
- (NSDictionary *)JSONObjectFromCGSize:(NSValue *)value;
- (NSValue *)CGSizeFromNSDictionary:(NSDictionary *)dic;

//CGRect
- (NSDictionary *)JSONObjectFromCGRect:(NSValue *)value;
- (NSValue *)CGRectFromNSDictionary:(NSDictionary *)dic;

//CMTimeRange
//- (NSDictionary *)JSONObjectFromCMTimeRange:(NSValue *)value;
//- (NSValue *)CMTimeRangeFromNSDictionary:(NSDictionary *)dic;

//UIImage
- (NSData *)JSONObjectFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromNSData:(NSData *)data;

@end
