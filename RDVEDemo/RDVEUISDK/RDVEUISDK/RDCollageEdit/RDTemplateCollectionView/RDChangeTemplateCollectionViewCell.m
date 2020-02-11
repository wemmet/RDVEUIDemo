//
//  RDChangeTemplateCollectionViewCell.m
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDChangeTemplateCollectionViewCell.h"

@implementation RDChangeTemplateCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _templateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _templateBtn.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _templateBtn.backgroundColor = [UIColor clearColor];
        _templateBtn.layer.cornerRadius = frame.size.height/2.0;
        _templateBtn.layer.masksToBounds = YES;
        [_templateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_templateBtn addTarget:self action:@selector(changeTemplate:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_templateBtn];
    }
    return self;
}

- (void)changeTemplate:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(changeTemplate:)]) {
        [_delegate changeTemplate:self];
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

@end
