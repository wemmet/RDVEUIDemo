//
//  RDZSlider+Image.m
//  RDVEUISDK
//
//  Created by apple on 2019/4/4.
//  Copyright © 2019年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDZImageSlider.h"

@implementation RDZImageSlider


-(CGRect)minimumValueImageRectForBounds:(CGRect)bounds; {

    for(UIView *view in [self subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.clipsToBounds = YES;
            view.contentMode = UIViewContentModeTopLeft;
        }
    }

    return bounds;
}

//-(CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value{
//
//    rect.origin.x=rect.origin.x-10;
//
//    rect.size.width=rect.size.width+20;
//
//    return CGRectInset([super thumbRectForBounds:bounds trackRect:rect value:value],10,10);
//}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds
{
    for(UIView *view in [self subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.clipsToBounds = YES;
            view.contentMode = UIViewContentModeTopLeft;
        }
    }

    return bounds;
}

@end
