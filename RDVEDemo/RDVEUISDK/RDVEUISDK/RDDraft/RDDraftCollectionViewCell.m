//
//  RDDraftCollectionViewCell.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDraftCollectionViewCell.h"

@implementation RDDraftCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _coverIV = [[UIImageView alloc] initWithFrame:CGRectMake(15, (frame.size.height - 80)/2.0, 80, 80)];
        _coverIV.contentMode = UIViewContentModeScaleAspectFill;
        _coverIV.layer.masksToBounds = YES;
        _coverIV.userInteractionEnabled = YES;
        [self addSubview:_coverIV];
        
        _dateLbl = [[UILabel alloc] initWithFrame:CGRectMake(15 + 90, _coverIV.frame.origin.y + 10, frame.size.width - (15 + 90), 20)];
        _dateLbl.textColor = UIColorFromRGB(0x888888);
        _dateLbl.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:_dateLbl];
        
        _durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(15 + 90, _coverIV.frame.origin.y + _coverIV.frame.size.height - 10, frame.size.width - (15 + 90), 20)];
        _durationLbl.textColor = UIColorFromRGB(0x888888);
        _durationLbl.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:_durationLbl];
        
        UIButton *exportBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        exportBtn.backgroundColor = Main_Color;
        exportBtn.frame = CGRectMake(frame.size.width - 75 - 70, _durationLbl.frame.origin.y - 8, 60, 28);
        exportBtn.layer.cornerRadius = 5.0;
        exportBtn.layer.masksToBounds = YES;
        [exportBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [exportBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
        exportBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        [exportBtn addTarget:self action:@selector(exportBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:exportBtn];
        
        UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        editBtn.backgroundColor = Main_Color;
        editBtn.frame = CGRectMake(frame.size.width - 75, _durationLbl.frame.origin.y - 8, 60, 28);
        editBtn.layer.cornerRadius = 5.0;
        editBtn.layer.masksToBounds = YES;
        [editBtn setTitle:RDLocalizedString(@"编辑", nil) forState:UIControlStateNormal];
        [editBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
        editBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        [editBtn addTarget:self action:@selector(editBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:editBtn];
        
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectBtn.frame = CGRectMake(_coverIV.bounds.size.width - 18 - 5, _coverIV.bounds.size.height - 18 - 5, 18, 18);
        [_selectBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/草稿-未选_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_selectBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/草稿-已选_@3x" Type:@"png"]] forState:UIControlStateSelected];
        [_selectBtn addTarget:self action:@selector(selectBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _selectBtn.hidden = YES;
        [_coverIV addSubview:_selectBtn];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - 1, frame.size.width, 1)];
        line.backgroundColor = UIColorFromRGB(0x3c3b43);
        [self addSubview:line];
    }
    return self;
}

- (void)exportBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(publishDraft:)]) {
        [_delegate publishDraft:self];
    }
}

- (void)editBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(editDraft:)]) {
        [_delegate editDraft:self];
    }
}

- (void)selectBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (_delegate && [_delegate respondsToSelector:@selector(selectDraft:)]) {
        [_delegate selectDraft:self];
    }
}

@end
