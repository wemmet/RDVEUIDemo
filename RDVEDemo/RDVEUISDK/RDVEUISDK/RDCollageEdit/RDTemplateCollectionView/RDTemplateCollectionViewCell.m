//
//  RDTemplateCollectionViewCell.m
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTemplateCollectionViewCell.h"

@implementation RDTemplateCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _thumbnailIV.backgroundColor = [UIColor clearColor];
        _thumbnailIV.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailIV.layer.borderWidth = 1.5;
        _thumbnailIV.layer.borderColor = [UIColor whiteColor].CGColor;
        _thumbnailIV.clipsToBounds = YES;
        [self.contentView addSubview:_thumbnailIV];
        
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _editBtn.backgroundColor = [UIColor clearColor];
        _editBtn.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);//jianji  bianji
        [_editBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-编辑视频默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_editBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-编辑视频点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
        [_editBtn addTarget:self action:@selector(editBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _editBtn.hidden = YES;
        [self.contentView addSubview:_editBtn];
        
        _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordBtn.backgroundColor = [UIColor clearColor];
        _recordBtn.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [_recordBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-添加视频默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_recordBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-添加视频点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
        [_recordBtn addTarget:self action:@selector(recordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _recordBtn.hidden = YES;
        [self.contentView addSubview:_recordBtn];
        
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteBtn.frame = CGRectMake(10, frame.size.height - 33 - 10, 33, 33);
        _deleteBtn.backgroundColor = [UIColor clearColor];
        [_deleteBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-删除视频默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_deleteBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-删除视频点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
        [_deleteBtn addTarget:self action:@selector(deleteBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _deleteBtn.hidden = YES;
        [self.contentView addSubview:_deleteBtn];
        
        _zoomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _zoomBtn.backgroundColor = [UIColor clearColor];
        _zoomBtn.frame = CGRectMake(self.frame.size.width - 40 - 10, self.frame.size.height - 40 - 10, 40, 40);
        [_zoomBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/拍摄-全屏默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_zoomBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/拍摄-全屏点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
        [_zoomBtn addTarget:self action:@selector(zoomBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _zoomBtn.hidden = YES;
        [self.contentView addSubview:_zoomBtn];
        
        _addLocalVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addLocalVideoBtn.backgroundColor = [UIColor clearColor];
        _addLocalVideoBtn.frame = CGRectMake(10, self.frame.size.height - 40 - 10, 40, 40);
        [_addLocalVideoBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-选择视频默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_addLocalVideoBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/编辑-选择视频点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
        [_addLocalVideoBtn addTarget:self action:@selector(addLocalVideoBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _addLocalVideoBtn.hidden = YES;
        [self.contentView addSubview:_addLocalVideoBtn];
    }
    
    return self;
}

- (void)deleteBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(deleteVideo:)]) {
        [_delegate deleteVideo:self];
    }
}

- (void)editBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(editVideo:)]) {
        [_delegate editVideo:self];
    }
}

- (void)recordBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(recordVideo:)]) {
        [_delegate recordVideo:self];
    }
}

- (void)zoomBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(zoomRecord:)]) {
        [_delegate zoomRecord:self];
    }
}

- (void)addLocalVideoBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(addLocalVideoVideo:)]) {
        [_delegate addLocalVideoVideo:self];
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

@end
