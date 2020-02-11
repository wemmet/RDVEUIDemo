//
//  RDPassthroughCollectionView.m
//  dyUIAPI
//
//  Created by apple on 2017/9/28.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDPassthroughCollectionView.h"
#import "RDTemplateCollectionViewCell.h"

@implementation RDPassthroughCollectionView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if( _isMask )
    {
        __block RDTemplateCollectionViewCell *cell;
        __block CGPoint childPoint;
        [self.subviews enumerateObjectsUsingBlock:^(__kindof RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 把当前控件上的坐标系转换成子控件上的坐标系
            childPoint = [self convertPoint:point toView:obj];
            if ([obj isKindOfClass:[RDTemplateCollectionViewCell class]] && [obj.path containsPoint:childPoint]) {
                cell = obj;
                *stop = YES;
            }
        }];
        if (cell) {
            UIView *hitView = [cell hitTest:childPoint withEvent:event];
            if ([hitView isKindOfClass:[UIButton class]]) {
                return hitView;
            }
            if (_isFocus) {
                return nil;
            }
            if (hitView == self)
            {
                return nil;
            }
            else
            {
                return hitView;
            }
        }
    }
    else
    {
        UIView *hitView = [super hitTest:point withEvent:event];
        if ([hitView isKindOfClass:[UIButton class]]) {
            return hitView;
        }
        if (_isFocus) {
            return nil;
        }
        if (hitView == self)
        {
            return nil;
        }
        else
        {
            return hitView;
        }
    }
    return nil;
}
@end
