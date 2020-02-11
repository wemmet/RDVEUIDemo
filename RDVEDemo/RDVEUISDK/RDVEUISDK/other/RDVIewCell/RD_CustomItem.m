//
//  RD_CustomItem.m
//  RDVEUISDK
//
//  Created by emmet on 16/6/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "RD_CustomItem.h"
#import "RDHelpClass.h"
@implementation RD_CustomItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.bSelectHandle = NO;
        // 加载nib
        _ivImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _durationBack = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-20, frame.size.width, 20)];
        _duration     = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, _durationBack.frame.size.width-25, 20)];
        
        UIImage *image = [RDHelpClass imageWithContentOfFile:@"选择视频图片_序号圈_"];
        if(image){
            image = [RDHelpClass rdImageWithColor:[UIColor greenColor] cornerRadius:15.0];
            _videoMark = [[UILabel alloc] initWithFrame:CGRectMake((frame.size.width - image.size.width)- 5, 5, image.size.width, image.size.height)];
            
        }else{
            float imageWidth = 20;
            _videoMark = [[UILabel alloc] initWithFrame:CGRectMake((frame.size.width - imageWidth)- 5, 5, imageWidth, imageWidth)];
        }
        _videoMark.backgroundColor = UIColorFromRGB(0x0dc215);
        _videoMark.textColor = [UIColor whiteColor];
        _videoMark.font = [UIFont systemFontOfSize:18];
        _videoMark.layer.masksToBounds = YES;
        _videoMark.layer.cornerRadius=image.size.width/2.0;
        _videoMark.textAlignment = NSTextAlignmentCenter;
        _ivImageView.backgroundColor = [UIColor clearColor];
        _ivImageView.contentMode = UIViewContentModeScaleAspectFill;
        _ivImageView.layer.masksToBounds = YES;
        _duration.backgroundColor = [UIColor clearColor];
        _duration.textAlignment = NSTextAlignmentRight;
        _duration.textColor = UIColorFromRGB(0xffffff);
        _duration.font = [UIFont systemFontOfSize:12];
        
        
        _durationBack.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        [_durationBack addSubview:_duration];
        [_ivImageView addSubview:_durationBack];
        [_ivImageView addSubview:_videoMark];
        _videoMark.alpha = 0;
        _videoMark.hidden = YES;
        [self addSubview:_ivImageView];
        _durationBack.hidden = NO;
        
    }
    return self;
}
- (void)setSelectMode:(BOOL)bSelect
{
    self.bSelectHandle = bSelect;
    WeakSelf(self);
    if (bSelect){
        _videoMark.hidden = NO;
        _ivImageView.layer.borderColor = [UIColor clearColor].CGColor;
        [UIView animateWithDuration:0.1 animations:^{
            StrongSelf(self);
            strongSelf.ivImageView.layer.borderWidth = 3;
            strongSelf.ivImageView.alpha = 0.9;
            strongSelf.videoMark.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }
    else{
        _ivImageView.layer.borderColor = [UIColor clearColor].CGColor;
        [UIView animateWithDuration:0.1 animations:^{
            StrongSelf(self);
            strongSelf.ivImageView.layer.borderWidth = 0;
            strongSelf.videoMark.alpha = 0;
        } completion:^(BOOL finished) {
            StrongSelf(self);
            strongSelf.ivImageView.alpha = 1.0;
            strongSelf.videoMark.hidden = YES;
        }];
        
    }
}
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
