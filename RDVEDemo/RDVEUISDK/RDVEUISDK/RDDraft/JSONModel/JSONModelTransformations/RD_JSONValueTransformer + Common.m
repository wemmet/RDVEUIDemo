//
//  JSONValueTransformer + Common.m
//  Reson8
//
//  Created by apple on 2018/1/17.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RD_JSONValueTransformer + Common.h"

@implementation RD_JSONValueTransformer (Common)

//CGSize
- (NSDictionary *)JSONObjectFromCGSize:(NSValue *)value {
    CGSize size;
    [value getValue:&size];
    NSDictionary *dic = @{@"width":@(size.width),@"height":@(size.height)};
    return dic;
}

- (NSValue *)CGSizeFromNSDictionary:(NSDictionary *)dic {
    CGFloat width = [dic[@"width"] floatValue];
    CGFloat height = [dic[@"height"] floatValue];
    
    CGSize size = {width, height};
    NSValue *value = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
    return value;
}

//CGRect
- (NSDictionary *)JSONObjectFromCGRect:(NSValue *)value {
    CGRect rect;
    [value getValue:&rect];
    NSDictionary *dic = @{@"x":@(rect.origin.x), @"y":@(rect.origin.y), @"width":@(rect.size.width),@"height":@(rect.size.height)};
    return dic;
}

- (NSValue *)CGRectFromNSDictionary:(NSDictionary *)dic {
    CGFloat x = [dic[@"x"] floatValue];
    CGFloat y = [dic[@"y"] floatValue];
    CGFloat width = [dic[@"width"] floatValue];
    CGFloat height = [dic[@"height"] floatValue];
    
    CGRect rect = {x, y, width, height};
    NSValue *value = [NSValue valueWithBytes:&rect objCType:@encode(CGRect)];
    return value;
}

//CMTimeRange
- (NSDictionary *)JSONObjectFromCMTimeRange:(NSValue *)value {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary([value CMTimeRangeValue], kCFAllocatorDefault));
    return dic;
}

- (NSValue *)CMTimeRangeFromNSDictionary:(NSDictionary *)dic {
    CMTimeRange r = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dic);
    NSValue *value = [NSValue valueWithCMTimeRange:r];
    return value;
}

//UIImage
- (NSData *)JSONObjectFromUIImage:(UIImage *)image {
    return UIImageJPEGRepresentation(image, 1.0);
}
- (UIImage *)UIImageFromNSData:(NSData *)data {
    return [UIImage imageWithData:data];
}

//UIColor
- (NSDictionary *)JSONObjectFromUIColor:(UIColor *)color {
    CGFloat r=0,g=0,b=0,a=0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [color getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return @{@"R":@(r),@"G":@(g),@"B":@(b),@"A":@(a)};
}
- (UIColor *)UIColorFromNSDictionary:(NSDictionary *)dic {
    UIColor *color = [UIColor colorWithRed:[dic[@"R"] floatValue] green:[dic[@"G"] floatValue] blue:[dic[@"B"] floatValue] alpha:[dic[@"A"] floatValue]];
    return color;
}

//CGPoint
- (NSDictionary *)JSONObjectFromCGPoint:(NSValue *)value {
    CGPoint point = [value CGPointValue];
    NSDictionary *dic = @{@"x":@(point.x),@"y":@(point.y)};
    return dic;
}
- (NSValue *)CGPointFromNSDictionary:(NSDictionary *)dic {
    CGFloat x = [dic[@"x"] floatValue];
    CGFloat y = [dic[@"y"] floatValue];
    
    CGPoint point = {x, y};
    NSValue *value = [NSValue valueWithBytes:&point objCType:@encode(CGPoint)];
    return value;
}

- (NSDictionary *)JSONObjectFromCGAffineTransform:(NSValue *)value {
    CGAffineTransform transform = [value CGAffineTransformValue];
    NSDictionary *dic = @{@"a":@(transform.a),@"b":@(transform.b),@"c":@(transform.c),@"d":@(transform.d),@"tx":@(transform.tx),@"ty":@(transform.ty)};
    return dic;
}

- (NSValue *)CGAffineTransformFromNSDictionary:(NSDictionary *)dic {
    CGAffineTransform transform = CGAffineTransformMake([dic[@"a"] floatValue], [dic[@"b"] floatValue], [dic[@"c"] floatValue], [dic[@"d"] floatValue], [dic[@"tx"] floatValue], [dic[@"ty"] floatValue]);
    NSValue *value = [NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)];
    return value;
}


@end
