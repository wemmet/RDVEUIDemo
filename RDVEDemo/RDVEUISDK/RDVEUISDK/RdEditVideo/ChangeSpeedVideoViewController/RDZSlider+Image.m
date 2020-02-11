//
//  RDZSlider+Image.m
//  RDVEUISDK
//
//  Created by apple on 2019/4/4.
//  Copyright © 2019年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDZSlider+Image.h"

@implementation RDZSlider (Image)


-(CGRect)minimumValueImageRectForBounds:(CGRect)bounds; {
    
    for(UIView *view in [self subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.clipsToBounds = YES;
            view.contentMode = UIViewContentModeLeft;
        }
    }
    
    return bounds;
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds
{
    for(UIView *view in [self subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.clipsToBounds = YES;
            view.contentMode = UIViewContentModeLeft;
        }
    }
    
    return bounds;
}

@end
