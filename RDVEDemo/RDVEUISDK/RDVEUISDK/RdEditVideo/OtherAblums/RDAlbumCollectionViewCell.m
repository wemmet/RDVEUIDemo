//
//  RDAlbumCollectionViewCell.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/3/15.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAlbumCollectionViewCell.h"

@implementation RDAlbumCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _coverIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        _coverIV.backgroundColor = [UIColor clearColor];
        _coverIV.contentMode = UIViewContentModeScaleAspectFill;
        _coverIV.layer.masksToBounds = YES;
        [self.contentView addSubview:_coverIV];
        
        _nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.width, frame.size.width - 20, frame.size.height - frame.size.width)];
        _nameLbl.textColor = [UIColor whiteColor];
        _nameLbl.font = [UIFont systemFontOfSize:14.0];
        [self.contentView addSubview:_nameLbl];
        
        _numberLbl = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 20, frame.size.width, 20, frame.size.height - frame.size.width)];
        _numberLbl.textColor = [UIColor whiteColor];
        _numberLbl.font = [UIFont systemFontOfSize:14.0];
        _numberLbl.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_numberLbl];
    }
    return self;
}

@end
