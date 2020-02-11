//
//  AETemplateInfoTableViewCell.m
//  RDVEUISDK
//
//  Created by apple on 2019/11/12.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AETemplateInfoTableViewCell.h"

@implementation AETemplateInfoTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        _playerView = [[UIView alloc] init];
        [self.contentView addSubview:_playerView];
        
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.backgroundColor = [UIColor clearColor];
        [_playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
        [_playerView addSubview:_playBtn];
        
        _playerToolBar = [UIView new];
        _playerToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _playerToolBar.hidden = YES;
        [self.contentView addSubview:_playerToolBar];
        
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.textAlignment = NSTextAlignmentRight;
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:12];
        [_playerToolBar addSubview:_durationLabel];
        
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:0.0];
        _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:12];
        [_playerToolBar addSubview:_currentTimeLabel];
        
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(40, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 80, 30)];
        _videoProgressSlider.backgroundColor = [UIColor clearColor];
        [_videoProgressSlider setMaximumValue:1];
        [_videoProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        _videoProgressSlider.layer.cornerRadius = 2.0;
        _videoProgressSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_videoProgressSlider setValue:0];
        _videoProgressSlider.alpha = 1.0;
        
        [_videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        [_playerToolBar addSubview:_videoProgressSlider];
        
        _playProgress = [[RDMoveProgress alloc] initWithFrame:CGRectMake(0, _playerView.frame.size.height - 5,  _playerView.frame.size.width, 5)];
        [_playProgress setProgress:0 animated:NO];
        [_playProgress setTrackTintColor:Main_Color];
        [_playProgress setBackgroundColor:UIColorFromRGB(0x888888)];
        _playProgress.hidden = YES;
        [_playerView addSubview:_playProgress];

        _bottomView = [[UIView alloc] init];
        _bottomView.hidden = YES;
        [self.contentView addSubview:_bottomView];
        
        _tipLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, kWIDTH - 20, 30)];
        _tipLbl.text = RDLocalizedString(@"视频制作需提供如下资源:", nil);
        _tipLbl.textColor = [UIColor whiteColor];
        _tipLbl.font = [UIFont systemFontOfSize:14.0];
        [_bottomView addSubview:_tipLbl];
        
        _textLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, kWIDTH - 20, 30)];
        _textLbl.textColor = [UIColor whiteColor];
        _textLbl.font = [UIFont systemFontOfSize:14.0];
        _textLbl.hidden = YES;
        [_bottomView addSubview:_textLbl];
        
        _picLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, kWIDTH - 20, 30)];
        _picLbl.textColor = [UIColor whiteColor];
        _picLbl.font = [UIFont systemFontOfSize:14.0];
        _picLbl.hidden = YES;
        [_bottomView addSubview:_picLbl];
        
        _videoLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, kWIDTH - 20, 30)];
        _videoLbl.textColor = [UIColor whiteColor];
        _videoLbl.font = [UIFont systemFontOfSize:14.0];
        _videoLbl.hidden = YES;
        [_bottomView addSubview:_videoLbl];
        
        _createBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _createBtn.frame = CGRectMake(40, 30, kWIDTH - 80, 40);
        _createBtn.backgroundColor = Main_Color;
        _createBtn.layer.cornerRadius = _createBtn.bounds.size.height / 2.0;
        [_createBtn setTitle:RDLocalizedString(@"一键制作", nil) forState:UIControlStateNormal];
        [_createBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
        [_createBtn addTarget:self action:@selector(_createBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_createBtn];
        
        _repeatView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 165)/2.0, _createBtn.frame.origin.y + 50, 165, 30)];
        _repeatView.hidden = YES;
        [_bottomView addSubview:_repeatView];
        
        _repeatLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
        _repeatLbl.text = RDLocalizedString(@"启用循环功能", nil);
        _repeatLbl.textColor = CUSTOM_GRAYCOLOR;
        _repeatLbl.textAlignment = NSTextAlignmentRight;
        _repeatLbl.font = [UIFont systemFontOfSize:14.0];
        [_repeatView addSubview:_repeatLbl];
        
        _repeatSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(165 - 60, 0, 60, 30)];
        _repeatSwitch.onTintColor = Main_Color;
        _repeatSwitch.tintColor = Main_Color;
        _repeatSwitch.thumbTintColor = [UIColor whiteColor];
        [_repeatView addSubview:_repeatSwitch];
    }
    return self;
}

- (void)setInfoDic:(NSDictionary *)infoDic cellHeight:(float)cellHeight {
    CGSize size = CGSizeMake([infoDic[@"width"] floatValue], [infoDic[@"height"] floatValue]);
    float bottomHeight = 30*4 + 50 + (iPhone_X ? 34 : 0);
    float bottomY = cellHeight - bottomHeight;
    float height = bottomY;
    float width = height * (size.width / size.height);
    if (width > kWIDTH) {
        width = kWIDTH;
        height = width / (size.width / size.height);
    }
    _playerView.frame = CGRectMake((kWIDTH - width)/2.0, (bottomY - height)/2.0, width, height);
    _playBtn.frame = CGRectMake((_playerView.frame.size.width - 56)/2.0, (_playerView.frame.size.height - 56)/2.0, 56, 56);
    _playerToolBar.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height - 44, kWIDTH, 44);
    _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 45, (_playerToolBar.frame.size.height - 20)/2.0, 40, 20);
    _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0, 40, 20);
    _videoProgressSlider.frame = CGRectMake(40, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 80, 30);
    _playProgress.frame = CGRectMake(0, _playerView.frame.size.height - 5,  _playerView.frame.size.width, 5);
    _bottomView.frame = CGRectMake(0, bottomY, kWIDTH, bottomHeight);
    _bottomView.hidden = NO;
    
    int textCount = [infoDic[@"text_need"] intValue];
    int picCount = [infoDic[@"picture_need"] intValue];
    int videoCount = [infoDic[@"video_need"] intValue];
    
    NSInteger index = 1;
    if (textCount > 0) {
        _textLbl.hidden = NO;
        _textLbl.text = [NSString stringWithFormat:RDLocalizedString(@"%d. %d个文字", nil), index++, textCount];
    }else {
        _textLbl.hidden = YES;
    }
    if (picCount > 0) {
        _picLbl.frame = CGRectMake(10, 30 + (index - 1)*30, kWIDTH - 20, 30);
        _picLbl.text = [NSString stringWithFormat:RDLocalizedString(@"%d. %d张图片", nil), index++, picCount];
        _picLbl.hidden = NO;
    }else {
        _picLbl.hidden = YES;
    }
    if (videoCount > 0) {
        _videoLbl.frame = CGRectMake(10, 30 + (index - 1)*30, kWIDTH - 20, 30);
        _videoLbl.text = [NSString stringWithFormat:RDLocalizedString(@"%d. %d个视频/图片", nil), index++, videoCount];
        _videoLbl.hidden = NO;
    }else {
        _videoLbl.hidden = YES;
    }
    _createBtn.frame = CGRectMake(40, 30 + (index - 1)*30, kWIDTH - 80, 40);
    if (videoCount == 0 && textCount == 0) {
        _repeatView.frame = CGRectMake((kWIDTH - 165)/2.0, _createBtn.frame.origin.y + 50, 165, 30);
        _repeatView.hidden = NO;
    }else {
        _repeatView.hidden = YES;
    }
}

- (void)_createBtnAction:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(createVideo)]) {
        [_delegate createVideo];
    }
}

- (void)tapPlayButton {
    if (_delegate && [_delegate respondsToSelector:@selector(playOrPause)]) {
        [_delegate playOrPause];
    }
}

#pragma mark - 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    if (_delegate && [_delegate respondsToSelector:@selector(changeVideoProgress:)]) {
        [_delegate changeVideoProgress:slider.value];
    }
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    if (_delegate && [_delegate respondsToSelector:@selector(changeVideoProgress:)]) {
        [_delegate changeVideoProgress:slider.value];
    }
    [_playProgress setProgress:slider.value animated:NO];
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if (_delegate && [_delegate respondsToSelector:@selector(changeVideoProgress:)]) {
        [_delegate changeVideoProgress:slider.value];
    }
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarShow{
    _playerToolBar.hidden = NO;
    _playProgress.hidden = YES;
    _playBtn.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        _playerToolBar.hidden = YES;
        _playBtn.hidden = YES;
        _playProgress.hidden = NO;
    }];
}

- (void)setPlayBtnHidden:(BOOL)hidden {
    if (hidden) {
        _playBtn.hidden = YES;
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
        [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
    }else {
        [self playerToolbarShow];
    }
}

@end
