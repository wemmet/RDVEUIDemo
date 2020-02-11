//
//  AECollectionViewCell.m
//  RDVEUISDK
//
//  Created by apple on 2018/11/1.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AECollectionViewCell.h"

@implementation AECollectionViewCell
    
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 5.0;
        self.layer.masksToBounds = YES;
        
        _coverIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - 35)];
        _coverIV.layer.cornerRadius = 5.0;
        _coverIV.layer.masksToBounds = YES;
        _coverIV.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_coverIV];
        
        _nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, _coverIV.bounds.size.height, frame.size.width - 20, 35)];
        _nameLbl.textColor = UIColorFromRGB(0x888888);
        [self addSubview:_nameLbl];
    }
    return self;
}

@end
