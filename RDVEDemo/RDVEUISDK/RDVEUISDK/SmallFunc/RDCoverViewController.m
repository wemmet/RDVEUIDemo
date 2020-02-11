//
//  RDCoverViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/26.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

/**添加封面类型
 */
typedef NS_ENUM(NSInteger, COVERTYPE)
{
    COVERTYPE_Title = 0,    //片头
    COVERTYPE_End   = 1,    //片尾
};
#import "RDCoverViewController.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "RDZSlider.h"
//时长进度条
#import "RDZImageSlider.h"
//相册
#import "RDMainViewController.h"
//文字
#import "RDAddEffectsByTimeline.h"
#import "RDAddEffectsByTimeline+Subtitle.h"
#import "UIImageView+RDWebCache.h"

@interface RDCoverViewController ()<RDVECoreDelegate, UIAlertViewDelegate,RDAddEffectsByTimelineDelegate>
{
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    
    UIButton                * headBtn;
    UIButton                * endBtn;
    RDVECore                * rdPlayer;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;
    
    UIView                  * bottomView;
    
    BOOL                      isLength;           //是否设置时长
    
    RDFile                  * titleFile;                //片头视频
    double                    titleTime;                //片头时长
    
    RDFile                  * endFile;                  //片尾视频
    double                    endTime;                  //片尾时长
    
    COVERTYPE               coverType;                  //封面类型
    
    //片头文字
    NSMutableArray <RDCaption *> *titleSubtitles;
    NSMutableArray <RDCaptionRangeViewFile *> *titleSubtitleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *titleOldSubtitleFiles;
    //片尾文字
    NSMutableArray<RDCaption*> * oldendSubtitles;
    
    NSMutableArray <RDCaption *> *endSubtitles;
    NSMutableArray <RDCaptionRangeViewFile *> *endSubtitleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *endOldSubtitleFiles;
    
    //当前文字
    NSMutableArray <RDCaption *> *currentSubtitles;
    NSMutableArray <RDCaptionRangeViewFile *> *currentSubtitleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *currentOldSubtitleFiles;
    
    CMTime          startPlayTime;
    
    RDAdvanceEditType            selecteFunction;
    BOOL                          isNotNeedPlay;
    
    UIScrollView                *addedMaterialEffectScrollView;
    UIImageView                 *selectedMaterialEffectItemIV;
    NSInteger                    selectedMaterialEffectIndex;
    BOOL                         isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    UIView *titleView;
    UIView *toolBarView;
    UILabel *toolBarTitleLbl;
    RDVECore        *thumbImageVideoCore;//截取缩率图
    NSMutableArray  *thumbTimes;
    
    UIButton *finishBtn;
    
    CMTime endfendTime;
    CMTimeRange             playTimeRange;
    
}
@property (nonatomic, strong) RDATMHud              * hud;
@property (nonatomic, strong) RDExportProgressView  * exportProgressView;

@property(nonatomic,strong)UIView           *playerView;
@property(nonatomic,strong)UIButton         *playButton;    //播放
@property(nonatomic,strong)UIView           *playerToolBar;
@property(nonatomic,strong)UILabel          *currentTimeLabel;
@property(nonatomic,strong)UILabel          *durationLabel;
@property(nonatomic,strong)UIButton         *zoomButton;
@property(nonatomic,strong)RDZSlider        *videoProgressSlider;

//时长
@property (nonatomic, strong) UIView                * lengthView;
@property (nonatomic, strong) RDZImageSlider        * lengthSlider;

//字幕
@property(nonatomic,strong)UIView                   *subtitleView;
@property(nonatomic,strong)RDAddEffectsByTimeline   *addEffectsByTimeline;
@property (nonatomic, strong) UIView *addedMaterialEffectView;
@property (nonatomic, assign) BOOL isAddingMaterialEffect;
@property (nonatomic, assign) BOOL isEdittingMaterialEffect;

@property (nonatomic, strong)UIView *BtnView;
@end

@implementation RDCoverViewController

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(_exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate{
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
#pragma makr- keybordShow&Hidde
- (void)keyboardWillShow:(NSNotification *)notification{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    bottomViewFrame.origin.y = kHEIGHT - keyboardSize.height - 48;
    _addEffectsByTimeline.subtitleConfigView.frame = bottomViewFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification{
    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    bottomViewFrame.origin.y = kHEIGHT - _addEffectsByTimeline.subtitleConfigView.frame.size.height;
    _addEffectsByTimeline.subtitleConfigView.frame = bottomViewFrame;
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];    
    
    if( !rdPlayer )
        [self initPlayer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    titleTime = 0.5;
    endTime = 0.5;
    playTimeRange = kCMTimeRangeZero;
    
    [self.view addSubview:self.playerView];
    [self initTitleView];
    [self initBottomView];
    [self.view addSubview:self.playerToolBar];
    [self initPlayer];
    [self.view addSubview:self.BtnView];
    [self initToolBarView];
}

- (void)initTitleView {
    titleView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44)];
    titleView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:titleView];
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:20];
    label.textColor = [UIColor whiteColor];
    label.text = RDLocalizedString(@"封面", nil);
    [titleView addSubview:label];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:cancelBtn];
    
    finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
    finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [finishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [finishBtn setTitle:RDLocalizedString(@"导出",nil) forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:finishBtn];
}

- (void)initToolBarView{
    toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    toolBarView.hidden = YES;
    [self.view addSubview:toolBarView];
    
    toolBarTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    toolBarTitleLbl.textAlignment = NSTextAlignmentCenter;
    toolBarTitleLbl.font = [UIFont boldSystemFontOfSize:20];
    toolBarTitleLbl.textColor = [UIColor whiteColor];
    toolBarTitleLbl.text = RDLocalizedString(@"文字", nil);
    [toolBarView addSubview:toolBarTitleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAddSubtitle) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishAddSubtitleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishAddSubtitleBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
    [finishAddSubtitleBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    [finishAddSubtitleBtn addTarget:self action:@selector(finishAddSubtitle) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishAddSubtitleBtn];
}

-(UIView*)BtnView
{
    if( !_BtnView )
    {
        _BtnView = [[UIView alloc] initWithFrame:CGRectMake(0, _playerToolBar.frame.size.height+_playerToolBar.frame.origin.y, kWIDTH, 44)];
        
        headBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        headBtn.frame = CGRectMake(kWIDTH/2.0-77, 0, 80, 30);
        headBtn.layer.borderColor = Main_Color.CGColor;
        headBtn.layer.borderWidth = 1.0;
        [headBtn setTitle:RDLocalizedString(@"片头", nil) forState:UIControlStateNormal];
        [headBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [headBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        headBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        headBtn.tag = 1;
        headBtn.selected = YES;
        [headBtn addTarget:self action:@selector(headEndBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_BtnView addSubview:headBtn];
        
        endBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        endBtn.frame = CGRectMake(kWIDTH/2.0+3, 0, 80, 30);
        [endBtn setTitle:RDLocalizedString(@"片尾", nil) forState:UIControlStateNormal];
        [endBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [endBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        endBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        endBtn.tag = 2;
        endBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        endBtn.layer.borderWidth = 1.0;
        [endBtn addTarget:self action:@selector(headEndBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_BtnView addSubview:endBtn];
    }
    return _BtnView;
}

-(void)titleViewIsHidden:(BOOL) isHidden
{
    headBtn.hidden = isHidden;
    endBtn.hidden = isHidden;
    bottomView.hidden = isHidden;
    titleView.hidden = isHidden;
    toolBarView.hidden = !isHidden;
}

- (void)initBottomView {
    bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight + kPlayerViewHeight, kWIDTH, kHEIGHT - kNavigationBarHeight - kPlayerViewHeight - (iPhone_X ? 34 : 0))];
    bottomView.backgroundColor = BOTTOM_COLOR;
    [self.view addSubview:bottomView];
    
    float width = 90;
    float space = (kWIDTH - width*3)/4.0;
    for (int i = 0; i < 3; i++) {
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake(space*(i + 1) + width*i, 24 + (bottomView.bounds.size.height - 35)/2.0, width, 35);
        itemBtn.layer.cornerRadius = 35/2.0;
        itemBtn.layer.borderWidth = 1.0;
        itemBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        if (i == 0) {
            [itemBtn setTitle:RDLocalizedString(@"添加图片", nil) forState:UIControlStateNormal];
        }else if (i == 1) {
            [itemBtn setTitle:RDLocalizedString(@"添加文字", nil) forState:UIControlStateNormal];
        }else {
            [itemBtn setTitle:RDLocalizedString(@"时长", nil) forState:UIControlStateNormal];
        }
        [itemBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [itemBtn addTarget:self action:@selector(childBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        itemBtn.tag = i + 1;
        [bottomView addSubview:itemBtn];
    }
}

/**播放器
 */
- (UIView *)playerView{
    if(!_playerView){
        _playerView = [UIView new];
        _playerView.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight);
        _playerView.backgroundColor = [UIColor blackColor];
        [_playerView addSubview:[self playButton]];
    }
    return _playerView;
}
#pragma mark- 播放器
/**播放暂停按键
 */
- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton new];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake((_playerView.frame.size.width - 56)/2.0, (_playerView.frame.size.height - 56)/2.0, 56, 56);
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}
- (UIView *)playerToolBar{
    if(!_playerToolBar){
        _playerToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height - 22, _playerView.frame.size.width, 44)];
        [_playerToolBar addSubview:self.currentTimeLabel];
        [_playerToolBar addSubview:self.durationLabel];
        [_playerToolBar addSubview:self.videoProgressSlider];
        [_playerToolBar addSubview:self.zoomButton];
    }
    return _playerToolBar;
}

- (UILabel *)durationLabel{
    if(!_durationLabel){
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, (_playerToolBar.frame.size.height - 20)/2.0, 60, 20);
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:12];
    }
    return _durationLabel;
}

- (UILabel *)currentTimeLabel{
    if(!_currentTimeLabel){
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
        _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _currentTimeLabel;
}

- (UIButton *)zoomButton{
    if(!_zoomButton){
        _zoomButton = [UIButton new];
        _zoomButton.backgroundColor = [UIColor clearColor];
        _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_全屏默认_"] forState:UIControlStateNormal];
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_缩小默认_"] forState:UIControlStateSelected];
        [_zoomButton addTarget:self action:@selector(tapzoomButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _zoomButton;
}
//是否全屏
- (void)tapzoomButton{
    _zoomButton.selected = !_zoomButton.selected;
    if(_zoomButton.selected){
        [self.view bringSubviewToFront:_playerView];
        [_playerToolBar removeFromSuperview];
        [self.view insertSubview:_playerToolBar aboveSubview:_playerView];
        //放大
        CGRect videoThumbnailFrame = CGRectZero;
        CGRect playerFrame = CGRectZero;
        _playerView.transform = CGAffineTransformIdentity;
        if(_exportSize.width>_exportSize.height){
            _playerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
            videoThumbnailFrame = [_playerView frame];
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = kHEIGHT;
            videoThumbnailFrame.size.width  = kWIDTH;
            playerFrame = videoThumbnailFrame;
            playerFrame.origin.x=0;
            playerFrame.origin.y=0;
            playerFrame.size.width = kHEIGHT;
            playerFrame.size.height  = kWIDTH;
            _playerToolBar.transform = _playerView.transform;
            _playerToolBar.frame = CGRectMake(0, 0, 44, playerFrame.size.width);
            _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.width - 20)/2.0, 60, 20);
            _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.width - 30)/2.0, _playerToolBar.frame.size.height - 60 - 60 - 50, 30);
            _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.height - 60 - 50, (_playerToolBar.frame.size.width - 20)/2.0, 60, 20);
            _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.height - 50, 0, 44, 44);
        }else{
            _playerView.transform = CGAffineTransformIdentity;
            videoThumbnailFrame = [_playerView frame];
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = kHEIGHT;
            videoThumbnailFrame.size.width  = kWIDTH;
            playerFrame = videoThumbnailFrame;
            _playerToolBar.transform = _playerView.transform;
            _playerToolBar.frame = CGRectMake(0, playerFrame.size.height - (iPhone_X ? 78 : 44), playerFrame.size.width, (iPhone_X ? 78 : 44));
            _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
            _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30);
            _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, (_playerToolBar.frame.size.height - 20)/2.0, 60, 20);
            _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        }
        if (iPhone_X) {
            rdPlayer.fillMode = kRDViewFillModeScaleAspectFill;
        }
        [_playerView setFrame:videoThumbnailFrame];
        
        rdPlayer.frame = playerFrame;
        _playButton.frame = CGRectMake((playerFrame.size.width - 44.0)/2.0, (playerFrame.size.height - 44)/2.0, 44, 44);
        if(![rdPlayer isPlaying]){
            if (CMTimeGetSeconds(CMTimeAdd(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))) > rdPlayer.duration) {
                [rdPlayer seekToTime:CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [rdPlayer seekToTime:CMTimeAdd(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }else{
        if (iPhone_X) {
            rdPlayer.fillMode = kRDViewFillModeScaleAspectFit;
        }
        [_playerToolBar removeFromSuperview];
        [self.view insertSubview:_playerToolBar aboveSubview:_playerView];
        //缩小
        _playerView.transform = CGAffineTransformIdentity;
        _playerToolBar.transform = _playerView.transform;
        [_playerView setFrame:CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight)];
        rdPlayer.frame = _playerView.bounds;
        _playButton.frame = CGRectMake((_playerView.frame.size.width - 44.0)/2.0, (_playerView.frame.size.height - 44)/2.0, 44, 44);
        _playerToolBar.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height - 22, _playerView.frame.size.width, 44);
        _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
        _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, _playerToolBar.frame.size.height - 30, 60, 20);
        _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        if(![rdPlayer isPlaying]){
            if (CMTimeGetSeconds(CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))) >= 0.0) {
                [rdPlayer seekToTime:CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [rdPlayer seekToTime:CMTimeAdd(rdPlayer.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }
}

//进度条
- (RDZSlider *)videoProgressSlider{
    if(!_videoProgressSlider){
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30)];
        _videoProgressSlider.backgroundColor = [UIColor clearColor];
        [_videoProgressSlider setMaximumValue:1];
        [_videoProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        _videoProgressSlider.layer.cornerRadius = 2.0;
        _videoProgressSlider.layer.masksToBounds = YES;
        image = [image imageWithTintColor];
        [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_videoProgressSlider setValue:0];
        [_videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _videoProgressSlider;
}
//MARK: 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if( slider == _videoProgressSlider )
    {
        if([rdPlayer isPlaying]){
            [self playVideo:NO];
        }
    }
}
/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    if( slider == _videoProgressSlider )
    {
        CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        _currentTimeLabel.text = [RDHelpClass timeToStringFormat:current];
    }
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if( slider == _videoProgressSlider )
    {
        CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    }
}
/**点击播放暂停按键
 */
- (void)tapPlayButton{
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)playerToolbarShow{
    self.playerToolBar.hidden = NO;
    self.playButton.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        self.playButton.hidden = YES;
    }];
}

- (void)playVideo:(BOOL)play{
    if(!play){
        [rdPlayer pause];
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
                _playButton.hidden = NO;
                [self playerToolbarShow];
            }
                break;
        }
        
    }else{
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
        [rdPlayer play];
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                startPlayTime = rdPlayer.currentTime;
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
                _playButton.hidden = YES;
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
                [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
            }
                break;
        }
    }
}
#pragma mark- 播放器初始化
- (void)initPlayer {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    NSString *exportOutPath = _outputPath.length>0 ? _outputPath : [RDHelpClass pathAssetVideoForURL:_file.contentURL];
    unlink([exportOutPath UTF8String]);
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    if (CGSizeEqualToSize(_exportSize, CGSizeZero)) {
        _exportSize = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:_file.contentURL]];
    }
    
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:_exportSize
                                            fps:kEXPORTFPS
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initSDKError:%@", error.localizedDescription);
                                     }];
    rdPlayer.frame = CGRectMake(0, 0, _playerView.frame.size.width, _playerView.frame.size.height);
    rdPlayer.delegate = self;
    [_playerView addSubview:rdPlayer.view];
    [self refreshRdPlayer:rdPlayer];
    [_playerView addSubview:[self playButton]];
}

- (void)refreshRdPlayer:(RDVECore *)Player {
    BOOL isSubtitle = NO;
    if(selecteFunction == RDAdvanceEditType_Subtitle)
        isSubtitle = YES;
    BOOL isTiltle = YES;
    if( coverType == COVERTYPE_End )
        isTiltle = NO;
    
    NSMutableArray *scenes = [NSMutableArray array];
    RDScene *scene = [RDScene new];
    //片头
    CMTime startTime = kCMTimeZero;
    if( titleFile )
    {
        if( !isSubtitle || ( isTiltle  ) )
        {
            VVAsset *titleVvAsset = [VVAsset new];
            titleVvAsset.url = titleFile.contentURL;
            titleVvAsset.fillType = RDImageFillTypeAspectFill;
            titleVvAsset.type = RDAssetTypeImage;
            titleVvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, titleFile.imageDurationTime);
            titleVvAsset.rotate = titleFile.rotate;
            titleVvAsset.crop = titleFile.crop;
            scene.vvAsset = [NSMutableArray arrayWithObject:titleVvAsset];
        }
        startTime = titleFile.imageDurationTime;
    }
    VVAsset *vvAsset = nil;
     if(_file.fileType == kFILEVIDEO)
         endfendTime = _file.videoTimeRange.duration;
     else
         endfendTime = _file.imageDurationTime;
    
    if( !isSubtitle )
    {
        //中间
        vvAsset = [VVAsset new];
        vvAsset.url = _file.contentURL;
        if(_file.fileType == kFILEVIDEO){
            vvAsset.type = RDAssetTypeVideo;
            if (CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTimeRange)) {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.videoDurationTime);
            }else{
                vvAsset.timeRange = _file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTrimTimeRange) && CMTimeCompare(vvAsset.timeRange.duration, _file.videoTrimTimeRange.duration) == 1){
                vvAsset.timeRange = _file.videoTrimTimeRange;
            }
        }else {
            vvAsset.type = RDAssetTypeImage;
            vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.imageDurationTime);
        }
        vvAsset.startTimeInScene = startTime;
        vvAsset.crop = _file.crop;
        vvAsset.volume = _file.videoVolume;
        if( !titleFile )
            scene.vvAsset = [NSMutableArray arrayWithObject:vvAsset];
        else
            [scene.vvAsset addObject:vvAsset];
    }
    
    if( rdPlayer == Player )
    {
        if( !isSubtitle )
            endfendTime = CMTimeAdd(startTime, endfendTime);
    }
    //片尾
    if( endFile  )
    {
        CMTime fendTime = kCMTimeZero;
        if( vvAsset )
          fendTime  = CMTimeAdd(startTime, vvAsset.timeRange.duration);
        if( !isSubtitle || ( !isTiltle  ) )
        {
            VVAsset *endVvAsset = [VVAsset new];
            endVvAsset.url = endFile.contentURL;
            endVvAsset.type = RDAssetTypeImage;
            endVvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, endFile.imageDurationTime);
            endVvAsset.startTimeInScene = fendTime;
            endVvAsset.fillType = RDImageFillTypeAspectFill;
            endVvAsset.rotate = endFile.rotate;
            endVvAsset.crop = endFile.crop;
            [scene.vvAsset addObject:endVvAsset];
        }
    }
    [scenes addObject:scene];
    [Player setScenes:scenes];
    [Player build];
    
    if( rdPlayer == Player )
    {
        [self refreshCaptions];
        _durationLabel.text = [RDHelpClass timeToStringFormat:rdPlayer.duration];
        _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
        [_videoProgressSlider setValue:0];
    }
}


#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
    }
}
/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    if(sender == rdPlayer && [rdPlayer isPlaying]){
        float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
        if (selecteFunction == RDAdvanceEditType_Subtitle) {
            if (!CMTimeRangeEqual(kCMTimeRangeZero, playTimeRange)) {
                if (CMTimeCompare(currentTime, CMTimeAdd(playTimeRange.start, playTimeRange.duration)) >= 0) {
                    [self playVideo:NO];
                    WeakSelf(self);
                    [rdPlayer seekToTime:playTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        [weakSelf.addEffectsByTimeline previewCompletion];
                    }];
                    float time = CMTimeGetSeconds(playTimeRange.start);
                    self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(time, rdPlayer.duration)];
                    float progress = time/rdPlayer.duration;
                    [_videoProgressSlider setValue:progress];
                    _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:time];
                    playTimeRange = kCMTimeRangeZero;
                }
            }else {
                if(!_addEffectsByTimeline.trimmerView.videoCore) {
                    [_addEffectsByTimeline.trimmerView setVideoCore:thumbImageVideoCore];
                }
                [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
                _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
                if(_isAddingMaterialEffect){
                    BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
                    if(!suc){
                        [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                    }
                }
            }
        }else {
            [_videoProgressSlider setValue:progress];
            _currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
        }
    }
}
- (void)playToEnd{
    [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Subtitle:
        {
            if(_isAddingMaterialEffect){
                [_addEffectsByTimeline saveSubtitle:YES];
            }else{
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        default:
        {
            [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
            [_videoProgressSlider setValue:0];
            _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
        }
            break;
    }
}

- (void)tapPlayerView{
    self.playButton.hidden = !self.playButton.hidden;
}

#pragma mark - 导出
- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:nil];
        [self.navigationController.view addSubview:_hud.view];
    }
    return _hud;
}

- (RDExportProgressView *)exportProgressView{
    if(!_exportProgressView){
        _exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0,0, kWIDTH, kHEIGHT)];
        _exportProgressView.canTouchUpCancel = YES;
        [_exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
        [_exportProgressView setProgress:0 animated:NO];
        [_exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
        [_exportProgressView setTrackprogressTintColor:[UIColor whiteColor]];
        __weak typeof(self) weakself = self;
        _exportProgressView.cancelExportBlock = ^(){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil)
                                                                    message:nil
                                                                   delegate:weakself
                                                          cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                                          otherButtonTitles:RDLocalizedString(@"确定",nil), nil];
                alertView.tag = 2;
                [alertView show];
                
            });
        };
    }
    return _exportProgressView;
}

- (void)exportMovie{
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [self.hud setCaption:message];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:@"%@。%@",[NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导出时长限制%@秒",nil),maxTime],RDLocalizedString(@"您可以关闭本提示去调整，或继续导出。",nil)];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"温馨提示",nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                                                  otherButtonTitles:RDLocalizedString(@"继续",nil), nil];
        alertView.tag = 1;
        [alertView show];
        return;
    }
    [rdPlayer stop];
    
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:rdPlayer totalDration:rdPlayer.duration exportSize:_exportSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
    NSString *export = ((RDNavigationViewController *)self.navigationController).outPath;
    if(export.length==0){
        export = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
    }
    unlink([export UTF8String]);
    idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    AVMutableMetadataItem *titleMetadata = [[AVMutableMetadataItem alloc] init];
    titleMetadata.key = AVMetadataCommonKeyTitle;
    titleMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    titleMetadata.locale =[NSLocale currentLocale];
    titleMetadata.value = @"titile";
    
    AVMutableMetadataItem *locationMetadata = [[AVMutableMetadataItem alloc] init];
    locationMetadata.key = AVMetadataCommonKeyLocation;
    locationMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    locationMetadata.locale = [NSLocale currentLocale];
    locationMetadata.value = @"location";
    
    AVMutableMetadataItem *creationDateMetadata = [[AVMutableMetadataItem alloc] init];
    creationDateMetadata.key = AVMetadataCommonKeyCopyrights;
    creationDateMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    creationDateMetadata.locale = [NSLocale currentLocale];
    creationDateMetadata.value = @"copyrights";
    
    AVMutableMetadataItem *descriptionMetadata = [[AVMutableMetadataItem alloc] init];
    descriptionMetadata.key = AVMetadataCommonKeyDescription;
    descriptionMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    descriptionMetadata.locale = [NSLocale currentLocale];
    descriptionMetadata.value = @"descriptionMetadata";
    
    WeakSelf(self);
    [rdPlayer exportMovieURL:[NSURL fileURLWithPath:export]
                        size:_exportSize
                     bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                         fps:kEXPORTFPS
                    metadata:@[titleMetadata, locationMetadata, creationDateMetadata, descriptionMetadata]
                audioBitRate:0
         audioChannelNumbers:1
      maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                    progress:^(float progress) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(_exportProgressView)
                                [_exportProgressView setProgress:progress*100.0 animated:NO];
                        });
                    } success:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf exportMovieSuc:export];
                        });
                    } fail:^(NSError *error) {
                        NSLog(@"失败:%@",error);
                        [weakSelf exportMovieFail:error];
                    }];
    
}
- (void)exportMovieFail:(NSError *)error {
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [rdPlayer removeWaterMark];
    [rdPlayer removeEndLogoMark];
    [rdPlayer filterRefresh:kCMTimeZero];
    self.exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                                  otherButtonTitles:nil, nil];
        alertView.tag = 3;
        [alertView show];
    }
}
- (void)exportMovieSuc:(NSString *)exportPath{
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
        self.exportProgressView = nil;
    }
    
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    [rdPlayer.view removeFromSuperview];
    rdPlayer = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).callbackBlock){
            ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
        }
    }];
}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 1:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
        case 2:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [_exportProgressView setProgress:0 animated:NO];
                [_exportProgressView removeFromSuperview];
                _exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
                [rdPlayer cancelExportMovie:nil];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 按钮事件
- (void)save{
    if( isLength )
    {
        self.lengthView.hidden = YES;
        bottomView.hidden = NO;
        isLength = NO;
        double time = _lengthSlider.value;
        if( time >= 0.5 )
            time = ((time - 0.5)/0.5)*(2.0-0.5) + 0.5;
        else
            time = (time/0.5) * 0.5;
        switch ( coverType ) {
            case COVERTYPE_Title:
                titleTime = time;
                break;
            case COVERTYPE_End:
                endTime = time;
                break;
            default:
                break;
        }
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [finishBtn setImage:nil forState:UIControlStateNormal];
        return;
    }
    [self exportMovie];
}

- (void)back{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    if( isLength )
    {
        self.lengthView.hidden = YES;
        bottomView.hidden = NO;
        isLength = NO;
        RDFile * temFile = nil;
        
        switch ( coverType ) {
            case COVERTYPE_Title:
                temFile = titleFile;
                titleFile.imageDurationTime = CMTimeMake(titleTime, TIMESCALE);
                break;
            case COVERTYPE_End:
                temFile = endFile;
                endFile.imageDurationTime = CMTimeMake(endTime, TIMESCALE);
                break;
            default:
                break;
        }
        if( temFile )
        {
            [rdPlayer stop];
            [rdPlayer.view removeFromSuperview];
            rdPlayer.delegate = nil;
            rdPlayer = nil;
            [self initPlayer];
        }
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [finishBtn setImage:nil forState:UIControlStateNormal];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).cancelHandler){
            ((RDNavigationViewController *)self.navigationController).cancelHandler();
        }
    }];
}

- (void)cancelAddSubtitle {
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    if (selecteFunction == RDAdvanceEditType_Subtitle)
    {
        if (_isAddingMaterialEffect || _isEdittingMaterialEffect)
        {
            _addEffectsByTimeline.currentTimeLbl.hidden = NO;
            
            if (_isAddingMaterialEffect) {
                [_addEffectsByTimeline cancelEffectAction:nil];
            }else {
                [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            }
            self.isAddingMaterialEffect = NO;
            self.isEdittingMaterialEffect = NO;
        }else {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            isNotNeedPlay = YES;
            
            self.isAddingMaterialEffect = NO;
            self.isEdittingMaterialEffect = NO;
            selecteFunction = RDAdvanceEditType_None;
            
            [self titleViewIsHidden:NO];
            _addEffectsByTimeline.currentTimeLbl.hidden = NO;
            _addedMaterialEffectView.hidden = YES;
            _subtitleView.hidden = YES;
            _playerToolBar.hidden = NO;
            
            [self refreshRdPlayer:rdPlayer];
        }
    }
}

- (void)finishAddSubtitle {
    if( !_addEffectsByTimeline.trimmerView.rangeSlider.hidden )
     {
         [_addEffectsByTimeline finishEffectAction:nil];
         return;
     }
    
    //MARK:字幕
    if(selecteFunction == RDAdvanceEditType_Subtitle){
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect){
            [_addEffectsByTimeline saveSubtitleTimeRange];
            CMTime time = [rdPlayer currentTime];
            [rdPlayer filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            return;
        }
        [_addEffectsByTimeline discardEdit];
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        
        [self titleViewIsHidden:NO];
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        _addedMaterialEffectView.hidden = YES;
        _subtitleView.hidden = YES;
        _playerToolBar.hidden = NO;
        
        currentOldSubtitleFiles = [currentSubtitleFiles mutableCopy];
        
        switch (coverType) {
            case COVERTYPE_Title:
                titleSubtitles = currentSubtitles;
                titleSubtitleFiles = currentSubtitleFiles;
                titleOldSubtitleFiles = currentOldSubtitleFiles;
                break;
            case COVERTYPE_End:
                endSubtitles = currentSubtitles;
                endSubtitleFiles = currentSubtitleFiles;
                endOldSubtitleFiles = currentOldSubtitleFiles;
                break;
            default:
                break;
        }
        selecteFunction = RDAdvanceEditType_None;
        [self refreshRdPlayer:rdPlayer];
    }
}

- (void)headEndBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        sender.selected = !sender.selected;
        
        if (sender.tag == 1) {
            endBtn.selected = NO;
            
            coverType = COVERTYPE_Title;
            
            if( !_lengthView.hidden )
            {
                 double time = _lengthSlider.value;
                if( time >= 0.5 )
                    time = ((time - 0.5)/0.5)*(2.0-0.5) + 0.5;
                else
                    time = (time/0.5) * 0.5;
                endTime = time;
                
                if( titleTime >= 0.5 )
                    [_lengthSlider setValue: (titleTime-0.5)/(2.0-0.5) + 0.5];
                else
                    [_lengthSlider setValue: (titleTime/0.5)*0.5];
            }
        }else {
            headBtn.selected = NO;
            coverType = COVERTYPE_End;
           
            if( !_lengthView.hidden )
            {
                 double time = _lengthSlider.value;
                if( time >= 0.5 )
                    time = ((time- 0.5)/0.5)*(2.0-0.5) + 0.5;
                else
                    time = (time/0.5) * 0.5;
                titleTime = time;
                if( endTime >= 0.5 )
                    [_lengthSlider setValue: (endTime-0.5)/(2.0-0.5) + 0.5];
                else
                    [_lengthSlider setValue: (endTime/0.5)*0.5];
            }
        }
    }
    
    switch (sender.tag) {
        case 1:
        {
            if( headBtn.selected )
            {
                endBtn.layer.borderColor = [UIColor whiteColor].CGColor;
                headBtn.layer.borderColor = Main_Color.CGColor;
            }
            else
            {
                headBtn.layer.borderColor = [UIColor whiteColor].CGColor;
                endBtn.layer.borderColor = Main_Color.CGColor;
            }
        }
            break;
        case 2:
        {
            if( endBtn.selected )
            {
                headBtn.layer.borderColor = [UIColor whiteColor].CGColor;
                endBtn.layer.borderColor = Main_Color.CGColor;
            }
            else
            {
                endBtn.layer.borderColor = [UIColor whiteColor].CGColor;
                headBtn.layer.borderColor = Main_Color.CGColor;
            }
        }
            break;
        default:
            break;
    }
}

- (void)childBtnAction:(UIButton *)sender {
    switch (sender.tag) {
        case 1:
            [self creatActionSheet:true];
            break;
        case 2:
            [self Addsubtitle];
            break;
        case 3:
        {
            [self lengthDuration];
        }
            break;
        default:
            break;
    }
}

//添加图片
-(void)AddImage
{
    [self AddImageFile];
}
//网络添加图片
-(void)AddWebImage
{
    
}
//添加横排文字
-(void)AddHorizontalText
{
    [self Addsubtitle];
}
//添加竖排文字
-(void)AddVerticalText
{
    
}

//选择封面
-(void)creatActionSheet:(BOOL) isCover {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:RDLocalizedString(isCover?@"选择封面":@"添加文字", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:RDLocalizedString(isCover?@"本地图片":@"添加横排文字", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if( isCover )
           [self AddImage];
        else
            [self AddHorizontalText];
    }];
//    UIAlertAction *action2 = [UIAlertAction actionWithTitle: RDLocalizedString(isCover?@"丰富照片素材":@"添加竖排文字", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        if( isCover )
//            [self AddWebImage];
//        else
//            [self AddVerticalText];
//    }];
    
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:RDLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:action1];
//    [actionSheet addAction:action2];
    [actionSheet addAction:action3];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark- 时长

-(void)lengthDuration
{
    if( [self isOperatO:@"调整时长"] )
    {
        return;
    }
    [finishBtn setTitle:@"" forState:UIControlStateNormal];
    [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    isLength = YES;
    self.lengthView.hidden = NO;
    bottomView.hidden = YES;
    switch (coverType) {
        case COVERTYPE_Title:
            if( titleTime >= 0.5 )
                [_lengthSlider setValue: (titleTime-0.5)/(2.0-0.5) + 0.5];
            else
                [_lengthSlider setValue: (titleTime/0.5)*0.5];
            break;
        case COVERTYPE_End:
            if( endTime >= 0.5 )
                [_lengthSlider setValue: (endTime-0.5)/(2.0-0.5) + 0.5];
            else
                [_lengthSlider setValue: (endTime/0.5)*0.5];
            break;
        default:
            break;
    }
}

-(UIView * )lengthView
{
    if( !_lengthView )
    {
        _lengthView  = [[UIView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight + kPlayerViewHeight+44+5, kWIDTH, kHEIGHT - kNavigationBarHeight - kPlayerViewHeight - 44 - 5 - (iPhone_X ? 34 : 0))];
        
        [_lengthView addSubview: [self scaleLabel:0 atStr:@"0s" atRect:CGSizeMake(kWIDTH - 60, 13)]];
        [_lengthView addSubview: [self scaleLabel:2 atStr:@"0.5s" atRect:CGSizeMake(kWIDTH - 60, 13)]];
        [_lengthView addSubview: [self scaleLabel:4 atStr:@"2s" atRect:CGSizeMake(kWIDTH - 60, 13)]];
        
        _lengthSlider = [[RDZImageSlider alloc] initWithFrame:CGRectMake(30, (_lengthView.frame.size.height - 27)/2.0, kWIDTH - 60, 27)];
        _lengthSlider.minimumValue = 0.0;
        _lengthSlider.maximumValue = 1.0;
        [_lengthSlider setValue:0.5];
        
        //设置了会减小滚动区域的宽度，但整个slider的宽度不变
        [_lengthSlider setMinimumTrackImage:[RDHelpClass imageWithContentOfFile:@"jianji/时长2_"] forState:UIControlStateNormal];
        [_lengthSlider setMaximumTrackImage:[RDHelpClass imageWithContentOfFile:@"jianji/时长1_"] forState:UIControlStateNormal];
        [_lengthSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        
        [_lengthSlider addTarget:self action:@selector(beginScrub) forControlEvents:UIControlEventTouchDown];
        [_lengthSlider addTarget:self action:@selector(scrub) forControlEvents:UIControlEventValueChanged];
        [_lengthSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchUpInside];
        [_lengthSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchCancel];
        
        [_lengthView addSubview:_lengthSlider];
        [self.view addSubview:_lengthView];
        _lengthView.hidden = YES;
    }
    return _lengthView;
}

-(UILabel *)scaleLabel:(int) index atStr:(NSString *) str atRect:(CGSize) size
{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake( index*(size.width/4.0) + 30 - 27/2.0 , (_lengthView.frame.size.height - 27)/2.0 - ( size.height ), 27, size.height)];
    label.textColor = UIColorFromRGB(0x808080);
    label.font  = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = str;
    return label;
}

//时长设置
-(void)beginScrub
{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
}
-(void)scrub
{
//    RDFile *temFile= nil;
//    NSString * str = nil;
//    switch ( coverType ) {
//        case COVERTYPE_Title:
//            temFile = titleFile;
//            str = RDLocalizedString(@"还未添加片头,请添加后再调整时长",nil);
//            break;
//        case COVERTYPE_End:
//            temFile = endFile;
//            str = RDLocalizedString(@"还未添加片尾,请添加后再调整时长",nil);
//            break;
//        default:
//            break;
//    }
//
//    if(!temFile)
//    {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"提示",nil)
//                                                            message:str
//                                                           delegate:self
//                                                  cancelButtonTitle:RDLocalizedString(@"取消",nil)
//                                                  otherButtonTitles:nil, nil];
//        alertView.tag = 1;
//        [alertView show];
//    }
}
-(void)endScrub
{
    double time = _lengthSlider.value;
    if( time >= 0.5 )
        time = ((time - 0.5)/0.5)*(2.0-0.5) + 0.5;
    else
        time = (time/0.5) * 0.5;
    
    RDFile *temFile= nil;
    
    switch ( coverType ) {
        case COVERTYPE_Title:
            temFile = titleFile;
            break;
        case COVERTYPE_End:
            temFile = endFile;
            break;
        default:
            break;
    }
    
    if(temFile)
    {
        temFile.imageDurationTime = CMTimeMakeWithSeconds(time, TIMESCALE);
        [rdPlayer stop];
        [rdPlayer.view removeFromSuperview];
        rdPlayer.delegate = nil;
        rdPlayer = nil;
        [self initPlayer];
    }
}

//添加图片
/**添加文件
 */
- (void)AddImageFile{
    if([rdPlayer isPlaying]){
        [rdPlayer pause];
    }
    
    ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType =  ONLYSUPPORT_IMAGE;
    
    if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
            if ([lists[0] isKindOfClass:[NSURL class]]) {
                for (int i = 0; i < lists.count; i++) {
                    NSURL *url = lists[i];
                    if ([url isKindOfClass:[NSURL class]]) {
                        RDFile *file = [RDFile new];
                        if([RDHelpClass isImageUrl:url]){
                            //图片
                            file.contentURL = url;
                            file.fileType = kFILEIMAGE;
                            file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                            file.speedIndex = 1;
                        }else{
                            //视频
                            file.contentURL = url;
                            file.fileType = kFILEVIDEO;
                            AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
                            CMTime duration = asset.duration;
                            file.videoDurationTime = duration;
                            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                            file.reverseVideoTimeRange = file.videoTimeRange;
                            file.videoTrimTimeRange = kCMTimeRangeInvalid;
                            file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
                            file.speedIndex = 2;
                        }
                        file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                        [lists replaceObjectAtIndex:i withObject:file];
                    }
                }
            }
            switch (coverType) {
                case COVERTYPE_Title:
                    titleFile = nil;
                    titleFile = lists[0];
                    titleFile.imageDurationTime =  CMTimeMakeWithSeconds(titleTime, TIMESCALE);
                    break;
                case COVERTYPE_End:
                    endFile = nil;
                    endFile = lists[0];
                    endFile.imageDurationTime =  CMTimeMakeWithSeconds(endTime, TIMESCALE);
                    break;
                default:
                    break;
            }
        }];
        return;
    }
    //20171017 wuxiaoxia mantis:0001949
    NSString *cameraOutputPath = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath;
    if ([_file.contentURL.path isEqualToString:cameraOutputPath]) {
        NSString * exportPath = [kRDDirectory stringByAppendingPathComponent:@"/recordVideoFile_rd.mp4"];
        ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath = exportPath;
    }
    
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.showPhotos = YES;
    mainVC.picCountLimit = 1;
    mainVC.textPhotoProportion = _exportSize.width/(float)_exportSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
        switch (coverType) {
            case COVERTYPE_Title:
                titleFile = nil;
                titleFile = filelist[0];
                titleFile.imageDurationTime =  CMTimeMakeWithSeconds(titleTime, TIMESCALE);
                break;
            case COVERTYPE_End:
                endFile = nil;
                endFile = filelist[0];
                endFile.imageDurationTime =  CMTimeMakeWithSeconds(endTime, TIMESCALE);
                break;
            default:
                break;
        }
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark- ThumbImageVideoCore
- (void)initThumbImageVideoCore{
    if(!thumbImageVideoCore){
        int fps = kEXPORTFPS;
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
            fps = 15;//20180720 与json文件中一致
        }
        thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:_exportSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];
        thumbImageVideoCore.delegate = self;
    }
    thumbImageVideoCore.frame = _playerView.bounds;
    thumbImageVideoCore.customFilterArray = nil;
    [self refreshRdPlayer:thumbImageVideoCore];
}

-(bool)isOperatO:(NSString *) textStr
{
    RDFile * temFile = nil;
    NSString * str = nil;
    switch (coverType) {
        case COVERTYPE_Title:
            currentSubtitles = titleSubtitles;
            currentSubtitleFiles = titleSubtitleFiles;
            currentOldSubtitleFiles = titleOldSubtitleFiles;
            temFile = titleFile;
            
//            str = [NSString stringWithFormat:@"还未添加片头,请添加后再%@",textStr];
            
            str = RDLocalizedString(@"请先添加图片",nil);
            break;
        case COVERTYPE_End:
            currentSubtitles = endSubtitles;
            currentSubtitleFiles = endSubtitleFiles;
            currentOldSubtitleFiles = endOldSubtitleFiles;
            temFile = endFile;
//            str = [NSString stringWithFormat:@"还未添加片尾,请添加后再%@",textStr];
            str = RDLocalizedString(@"请先添加图片",nil);
            break;
        default:
            break;
    }
    if(!temFile)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"提示",nil)
                                                            message:str
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                                  otherButtonTitles:nil, nil];
        alertView.tag = 1;
        [alertView show];
        return true;
    }
    return  false;
}

#pragma mark- 文字
-(void)Addsubtitle
{
    if( [self isOperatO:@"添加文字"] )
    {
        return;
    }
    [self titleViewIsHidden:YES];
    isNotNeedPlay = YES;
     selecteFunction = RDAdvanceEditType_Subtitle;
    [self refreshRdPlayer:rdPlayer];
    _durationLabel.text = [RDHelpClass timeToStringFormat:rdPlayer.duration];
    _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    _playerToolBar.hidden = YES;
    
    [self initThumbImageVideoCore];
    _playButton.hidden = YES;
    self.subtitleView.hidden = NO;
    self.addEffectsByTimeline.hidden = NO;
    _addEffectsByTimeline.thumbnailCoreSDK = rdPlayer;
    if (!_addEffectsByTimeline.superview) {
        [_subtitleView addSubview:_addEffectsByTimeline];
        _addEffectsByTimeline.currentEffect = selecteFunction;
    }else {
        _addEffectsByTimeline.currentEffect = selecteFunction;
        [_addEffectsByTimeline removeFromSuperview];
        [_subtitleView addSubview:_addEffectsByTimeline];
    }
    _addEffectsByTimeline.currentTimeLbl.text = @"0.00";
    [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.1];
}
- (void)loadTrimmerViewThumbImage {
    @autoreleasepool {
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        thumbTimes=[[NSMutableArray alloc] init];
        Float64 duration;
        Float64 start;
        duration = thumbImageVideoCore.duration;
        start = (duration > 0.25 ? 0.125 : (duration-0.05));
        [thumbTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(start,TIMESCALE)]];
        NSInteger actualFramesNeeded = duration/0.25;
        Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
        /*截图为什么用两个for循环：第一个for循环是分配内存，第二个for循环显示图片，截图快一些*/
        for (int i=1; i<actualFramesNeeded; i++){
            CMTime time = CMTimeMakeWithSeconds(start + i*durationPerFrame,TIMESCALE);
            [thumbTimes addObject:[NSValue valueWithCMTime:time]];
        }
        [thumbImageVideoCore getImageWithTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2 completionHandler:^(UIImage *image) {
            if(!image){
                image = [thumbImageVideoCore getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                if (!image) {
                    image = [rdPlayer getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (selecteFunction) {
                    case RDAdvanceEditType_Subtitle://MARK:字幕
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:image
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:currentSubtitles
                                                           oldFileArray:currentOldSubtitleFiles];
                        
                        if (currentSubtitles.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolBarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolBarTitleLbl.hidden = YES;
                        }
                        break;
                    default:
                        break;
                }
                //NSLog(@"截图次数：%d",actualFramesNeeded);
                [self refreshTrimmerViewImage];
            });
        }];
    }
}
- (void)refreshTrimmerViewImage {
    @autoreleasepool {
            Float64 durationPerFrame = thumbImageVideoCore.duration / (thumbTimes.count*1.0);
            for (int i=0; i<thumbTimes.count; i++){
                CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
                [thumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
            }
            [self refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES];
    }
}
- (void)refreshThumbWithImageTimes:(NSArray *)imageTimes nextRefreshIndex:(int)nextRefreshIndex isLastArray:(BOOL)isLastArray{
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        [thumbImageVideoCore getImageWithTimes:[imageTimes mutableCopy] scale:0.1 completionHandler:^(UIImage *image, NSInteger idx) {
            StrongSelf(self);
            if(!image){
                return;
            }
            NSLog(@"获取图片：%zd",idx);
            switch (selecteFunction) {
                case RDAdvanceEditType_Subtitle:
                {
                    if(strongSelf.addEffectsByTimeline.trimmerView)
                        [strongSelf.addEffectsByTimeline.trimmerView refreshThumbImage:idx thumbImage:image];
                }
                    break;
                default:
                    break;
            }
            if(idx == imageTimes.count - 1)
            {
                if( strongSelf )
                    [strongSelf->thumbImageVideoCore stop];
            }
        }];
    }
}
#pragma mark- 字幕
- (UIView *)subtitleView{
    if(!_subtitleView){
        _subtitleView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight)];
        _subtitleView.backgroundColor = TOOLBAR_COLOR;
        _subtitleView.hidden = YES;
        [self.view addSubview:_subtitleView];
    }
    return _subtitleView;
}
- (RDAddEffectsByTimeline *)addEffectsByTimeline {
    if (!_addEffectsByTimeline) {
        _addEffectsByTimeline = [[RDAddEffectsByTimeline alloc] initWithFrame:CGRectMake(0, 0, _subtitleView.frame.size.width, _subtitleView.frame.size.height)];
        [_addEffectsByTimeline prepareWithEditConfiguration:((RDNavigationViewController *)self.navigationController).editConfiguration
                                                     appKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 exportSize:_exportSize
                                                 playerView:_playerView
                                                        hud:_hud];
        _addEffectsByTimeline.isCover = YES;
        _addEffectsByTimeline.delegate = self;
    }
    return _addEffectsByTimeline;
}

- (UIView *)addedMaterialEffectView {
    if (!_addedMaterialEffectView) {
        _addedMaterialEffectView = [[UIView alloc] initWithFrame:CGRectMake(44, 0, kWIDTH - 44*2, 44)];
        _addedMaterialEffectView.hidden = YES;
        _addedMaterialEffectView.backgroundColor = TOOLBAR_COLOR;
        [toolBarView addSubview:_addedMaterialEffectView];
        
        UILabel *addedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
        addedLbl.text = RDLocalizedString(@"已添加", nil);
        addedLbl.textColor = UIColorFromRGB(0x888888);
        addedLbl.font = [UIFont systemFontOfSize:14.0];
        [_addedMaterialEffectView addSubview:addedLbl];
        
        addedMaterialEffectScrollView =  [UIScrollView new];
        addedMaterialEffectScrollView.frame = CGRectMake(64, 0, _addedMaterialEffectView.bounds.size.width - 64, 44);
        addedMaterialEffectScrollView.showsVerticalScrollIndicator = NO;
        addedMaterialEffectScrollView.showsHorizontalScrollIndicator = NO;
        [_addedMaterialEffectView addSubview:addedMaterialEffectScrollView];
        
        selectedMaterialEffectItemIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, addedMaterialEffectScrollView.bounds.size.height - 27, 27, 27)];
        
        selectedMaterialEffectItemIV.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/特效-选中勾_"];
        selectedMaterialEffectItemIV.hidden = YES;
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    return _addedMaterialEffectView;
}

- (void)setIsAddingMaterialEffect:(BOOL)isAddingMaterialEffect {
    _isAddingMaterialEffect = isAddingMaterialEffect;
    _addEffectsByTimeline.isAddingEffect = isAddingMaterialEffect;
}

- (void)setIsEdittingMaterialEffect:(BOOL)isEdittingMaterialEffect {
    _isEdittingMaterialEffect = isEdittingMaterialEffect;
    _addEffectsByTimeline.isEdittingEffect = isEdittingMaterialEffect;
}

#pragma mark - RDAddEffectsByTimelineDelegate
- (void)pauseVideo {
    [self playVideo:NO];
}

- (void)playOrPauseVideo {
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)previewWithTimeRange:(CMTimeRange)timeRange {
    playTimeRange = timeRange;
    [self playVideo:YES];
}

- (void)changeCurrentTime:(float)currentTime {
    if(![rdPlayer isPlaying]){
        WeakSelf(self);
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(currentTime, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = strongSelf->rdPlayer.duration;
            if(CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
    }
}

- (void)addMaterialEffect {
    if( [rdPlayer isPlaying] )
        [self playVideo:NO];
    self.isAddingMaterialEffect = YES;
    _addedMaterialEffectView.hidden = YES;
    toolBarView.hidden = YES;
}

- (void)addingStickerWithDuration:(float)addingDuration  captionId:(int ) captionId{
    self.isAddingMaterialEffect = YES;
    NSMutableArray *arry = [[NSMutableArray alloc] initWithArray:currentSubtitles];
    rdPlayer.captions = arry;
    if(![rdPlayer isPlaying]){
        _addEffectsByTimeline.trimmerView.isTiming = YES;
//        [self playVideo:YES];
    }
    [self addedMaterialEffectItemBtnAction:[addedMaterialEffectScrollView viewWithTag:captionId]];
}

- (void)cancelMaterialEffect {
    [self deleteMaterialEffect];
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    toolBarView.hidden = NO;
}

- (void)refreshCaptions {
    
    NSMutableArray *arry = nil;
    if( selecteFunction == RDAdvanceEditType_None )
    {
        arry = [[NSMutableArray alloc] initWithArray:titleSubtitles];
        
        if( oldendSubtitles )
        {
            [oldendSubtitles removeAllObjects];
            oldendSubtitles = nil;
        }
        
        oldendSubtitles = [NSMutableArray new];
        
        [endSubtitles enumerateObjectsUsingBlock:^(RDCaption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [oldendSubtitles addObject:[obj mutableCopy]];
        }];
        
        [oldendSubtitles enumerateObjectsUsingBlock:^(RDCaption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CMTimeRange time = CMTimeRangeMake(CMTimeAdd(obj.timeRange.start, endfendTime), obj.timeRange.duration);
            obj.timeRange = time;
        }];
        
        [arry addObjectsFromArray:oldendSubtitles];
    }
    else
    {
        arry = [[NSMutableArray alloc] initWithArray:currentSubtitles];
    }
    rdPlayer.captions = arry;
}

- (void)deleteMaterialEffect {
    [self playVideo:NO];
    isNotNeedPlay = YES;
    BOOL suc = [_addEffectsByTimeline.trimmerView deletedcurrentCaption];
    if(suc){
        NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
        [currentSubtitles removeAllObjects];
        [currentSubtitleFiles removeAllObjects];
        
        for(CaptionRangeView *view in arr){
            RDCaption *subtitle = view.file.caption;
            if(subtitle){
                [currentSubtitles addObject:subtitle];
                [currentSubtitleFiles addObject:view.file];
            }
        }
        [self refreshCaptions];
        [rdPlayer refreshCurrentFrame];
    }else{
        NSLog(@"删除失败");
        isNotNeedPlay = NO;
    }
    [self refreshAddMaterialEffectScrollView];
    selectedMaterialEffectItemIV.hidden = YES;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    
    if (currentSubtitles.count > 0) {
        _addedMaterialEffectView.hidden = NO;
        toolBarTitleLbl.hidden = YES;
    }else {
        _addedMaterialEffectView.hidden = YES;
        toolBarTitleLbl.hidden = NO;
    }
}

- (void)updateMaterialEffect:(NSMutableArray *)newEffectArray
                newFileArray:(NSMutableArray *)newFileArray
                isSaveEffect:(BOOL)isSaveEffect
{
    _isAddingMaterialEffect = NO;
    _addEffectsByTimeline.currentTimeLbl.hidden = NO;
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    if (!currentSubtitles) {
        currentSubtitles = [NSMutableArray array];
    }
    if (!currentSubtitleFiles) {
        currentSubtitleFiles = [NSMutableArray array];
    }
    [self refreshMaterialEffectArray:currentSubtitles newArray:newEffectArray];
    [self refreshMaterialEffectArray:currentSubtitleFiles newArray:newFileArray];
    [self refreshCaptions];
    [rdPlayer refreshCurrentFrame];
    
    [self refreshAddMaterialEffectScrollView];
    if (isSaveEffect) {
        [_addEffectsByTimeline.syncContainer removeFromSuperview];
        selectedMaterialEffectItemIV.hidden = YES;
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        toolBarView.hidden = NO;
    }
    if (!_isEdittingMaterialEffect) {
        if (newEffectArray.count == 0) {
            _addedMaterialEffectView.hidden = YES;
            toolBarTitleLbl.hidden = NO;
        }else {
            _addedMaterialEffectView.hidden = NO;
            toolBarTitleLbl.hidden = YES;
        }
    }
}

- (void)refreshMaterialEffectArray:(NSMutableArray *)oldArray newArray:(NSMutableArray *)newArray {
    [oldArray removeAllObjects];
    [newArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [oldArray addObject:obj];
    }];
}

- (void)pushOtherAlbumsVC:(UIViewController *)otherAlbumsVC {
    isNotNeedPlay = YES;
    [self.navigationController pushViewController:otherAlbumsVC animated:YES];
}
-(void)TimesFor_videoRangeView_withTime:(int)captionId
{
    [addedMaterialEffectScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDAddItemButton class]]) {
            RDAddItemButton * addItemBtn = (RDAddItemButton*) obj;
            addItemBtn.redDotImageView.hidden = YES;
        }
    }];
    
    NSMutableArray *array = [_addEffectsByTimeline.trimmerView getCaptionsViewForcurrentTime:NO];
    
    if( array && (array.count > 0)  )
    {
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CaptionRangeView * rangeV = (CaptionRangeView*)obj;
            for (int i = 0; i < addedMaterialEffectScrollView.subviews.count; i++) {
                UIView * obj = addedMaterialEffectScrollView.subviews[i];
                
                if ([obj isKindOfClass:[RDAddItemButton class]]) {
                    RDAddItemButton * addItemBtn = (RDAddItemButton*) obj;
                    if( (rangeV.file.captionId == addItemBtn.tag) && ( addItemBtn.tag != _addEffectsByTimeline.trimmerView.currentCaptionView ) )
                    {
                        addItemBtn.redDotImageView.hidden = NO;
                        break;
                    }
                }
                
            }
        }];
    }
}

- (void)refreshAddMaterialEffectScrollView {
    
    if( !addedMaterialEffectScrollView )
    {
        self.addedMaterialEffectView.hidden = NO;
    }
    
    [addedMaterialEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
    BOOL isNetSource = ((RDNavigationViewController *)self.navigationController).editConfiguration.subtitleResourceURL.length>0;
    NSInteger index = 0;
    for (int i = 0; i < arr.count; i++) {
        CaptionRangeView *view = arr[i];
        if (_isAddingMaterialEffect && view == _addEffectsByTimeline.trimmerView.currentCaptionView) {
            index = view.file.captionId;
        }
        if (view.file.caption) {
            RDAddItemButton *addedItemBtn = [RDAddItemButton buttonWithType:UIButtonTypeCustom];
            addedItemBtn.frame = CGRectMake((view.file.captionId-1) * 50, (44 - 40)/2.0, 40, 40);
            UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0/2.0, (40 - 25.0)/2.0, 25.0, 25.0)];
            if(isNetSource){
                [imageView rd_sd_setImageWithURL:[NSURL URLWithString:view.file.netCover]];
            }else{
                NSString *iconPath;
                if (selecteFunction == RDAdvanceEditType_Subtitle) {
                    iconPath = [NSString stringWithFormat:@"%@/%@.png",kSubtitleIconPath,view.file.caption.imageName];
                }
                UIImage *image = [UIImage imageWithContentsOfFile:iconPath];
                imageView.image = image;
            }
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [addedItemBtn addSubview:imageView];
            
            addedItemBtn.tag = view.file.captionId;
            [addedItemBtn addTarget:self action:@selector(addedMaterialEffectItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [addedMaterialEffectScrollView addSubview:addedItemBtn];
            
            addedItemBtn.redDotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(addedItemBtn.frame.size.width - addedMaterialEffectScrollView.bounds.size.height/6.0, addedMaterialEffectScrollView.bounds.size.height - addedMaterialEffectScrollView.bounds.size.height/2.0, addedMaterialEffectScrollView.bounds.size.height/6.0, addedMaterialEffectScrollView.bounds.size.height/6.0)];
            
            addedItemBtn.redDotImageView.backgroundColor = [UIColor redColor];
            addedItemBtn.redDotImageView.layer.cornerRadius =  addedItemBtn.redDotImageView.frame.size.height/2.0;
            addedItemBtn.redDotImageView.layer.masksToBounds = YES;
            addedItemBtn.redDotImageView.layer.shadowColor = [UIColor redColor].CGColor;
            addedItemBtn.redDotImageView.layer.shadowOffset = CGSizeZero;
            addedItemBtn.redDotImageView.layer.shadowOpacity = 0.5;
            addedItemBtn.redDotImageView.layer.shadowRadius = 2.0;
            addedItemBtn.redDotImageView.clipsToBounds = NO;
            
            [addedItemBtn addSubview:addedItemBtn.redDotImageView];
            addedItemBtn.redDotImageView.hidden = YES;
            
            [addedMaterialEffectScrollView addSubview:addedItemBtn];
        }
        
        
    }
    [addedMaterialEffectScrollView setContentSize:CGSizeMake(addedMaterialEffectScrollView.subviews.count * 50, 0)];
    if (_isEdittingMaterialEffect) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    if (_isAddingMaterialEffect && !_isEdittingMaterialEffect) {
        selectedMaterialEffectIndex = index;
        _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
        UIButton *itemBtn = [addedMaterialEffectScrollView viewWithTag:index];
        CGRect frame = selectedMaterialEffectItemIV.frame;
        frame.origin.x = itemBtn.frame.origin.x + itemBtn.bounds.size.width - frame.size.width + 6;
        selectedMaterialEffectItemIV.frame = frame;
        selectedMaterialEffectItemIV.hidden = NO;
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    
    if( arr.count > 0 )
    {
        _addedMaterialEffectView.hidden = NO;
        toolBarTitleLbl.hidden = YES;
    }else
    {
        _addedMaterialEffectView.hidden = YES;
        toolBarTitleLbl.hidden = NO;
    }
}

- (void)addedMaterialEffectItemBtnAction:(UIButton *)sender {
    if (!selectedMaterialEffectItemIV.hidden && sender.tag == selectedMaterialEffectIndex) {
        
        return;
    }
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    selectedMaterialEffectIndex = sender.tag;
    _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
    CGRect frame = selectedMaterialEffectItemIV.frame;
    frame.origin.x = sender.frame.origin.x + sender.bounds.size.width - frame.size.width + 6;
    selectedMaterialEffectItemIV.frame = frame;
    
    _addEffectsByTimeline.trimmerView.isJumpTail = true;
    
    [_addEffectsByTimeline editAddedEffect];
    if (!selectedMaterialEffectItemIV.superview) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    selectedMaterialEffectItemIV.hidden = NO;
    _addedMaterialEffectView.hidden = NO;
    self.isEdittingMaterialEffect = YES;
    self.isAddingMaterialEffect = NO;
    CMTime time = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
    [rdPlayer filterRefresh:time];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}
@end
