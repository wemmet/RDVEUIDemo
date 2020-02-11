//
//  RDSubtitleCollectionViewCell.m
//  RDVEUISDK
//
//  Created by apple on 2019/12/31.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDSubtitleCollectionViewCell.h"

@implementation RDSubtitleCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _coverIV = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:_coverIV];
        
//        UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
//        _downloadIV = [[UIImageView alloc] initWithImage:accessory];
//        _downloadIV.frame = CGRectMake(frame.size.width-accessory.size.width, frame.size.height - accessory.size.height, accessory.size.width, accessory.size.height);
//        _downloadIV.hidden = YES;
//        [self addSubview:_downloadIV];
    }
    return self;
}

@end
