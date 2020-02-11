//
//  RDColorView.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/12/26.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDColorControlView.h"

@interface RDColorControlView() {
    UIScrollView *colorScrollView;
}

@end

@implementation RDColorControlView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)setColorArray:(NSArray *)colorArray {
    _colorArray = colorArray;
    if (!colorScrollView) {
        float width = self.frame.size.height / 2.0;
        colorScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        colorScrollView.showsVerticalScrollIndicator = NO;
        colorScrollView.showsHorizontalScrollIndicator = NO;
        colorScrollView.contentSize = CGSizeMake(_colorArray.count * width + 20, 0);
        [self addSubview:colorScrollView];
        
        [_colorArray enumerateObjectsUsingBlock:^(UIColor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            colorBtn.frame = CGRectMake(width * idx, 0, width, self.frame.size.height);
            colorBtn.backgroundColor = obj;
            if (idx == 0 || idx == _colorArray.count - 1) {
                UIRectCorner corners;
                if (idx == 0) {
                    corners = UIRectCornerTopLeft|UIRectCornerBottomLeft;
                }else {
                    corners = UIRectCornerTopRight|UIRectCornerBottomRight;
                }
                UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:colorBtn.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(4.0, 4.0)];
                CAShapeLayer *maskLayer = [CAShapeLayer layer];
                maskLayer.frame = colorBtn.bounds;
                maskLayer.path = maskPath.CGPath;
                colorBtn.layer.mask = maskLayer;
            }
            colorBtn.tag = idx + 1;
            [colorBtn addTarget:self action:@selector(colorBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [colorScrollView addSubview:colorBtn];
        }];
    }
}

- (void)colorBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(colorChanged:index:colorControlView:)]) {
        [_delegate colorChanged:sender.backgroundColor index:(sender.tag - 1) colorControlView:self];
    }
}

- (void)refreshFrame:(CGRect)frame {
    [UIView animateWithDuration:0.1 animations:^{
        self.frame = frame;
        colorScrollView.frame = self.bounds;
    }];
}

@end
