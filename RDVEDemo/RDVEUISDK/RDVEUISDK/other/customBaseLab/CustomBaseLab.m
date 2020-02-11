//
//  CustomBaseLab.m
//  RDVEUISDK
//
//  Created by 王全洪 on 2018/10/23.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "CustomBaseLab.h"

@implementation CustomBaseLab


- (instancetype)init {
    if (self = [super init]) {
        _textLableInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _textLableInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _textLableInsets)];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
