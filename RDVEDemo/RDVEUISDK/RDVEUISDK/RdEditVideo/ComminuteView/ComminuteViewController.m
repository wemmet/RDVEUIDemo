//
//  ComminuteViewController.m
//  RDVEUISDK
//
//  Created by emmet on 15/8/24.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

#import "ComminuteViewController.h"
#import "RDICGVideoTrimmerView.h"
#import "RDComminuteRangeView.h"
#import "RDSVProgressHUD.h"
#import "RDATMHud.h"
#import "RDNavigationViewController.h"
#import "RDGenSpecialEffect.h"
#import "UIImage+RDGIF.h"

#define THUMB_HEIGHT 40
#define THUMB_V_PADDING 10
#define THUMB_H_PADDING 10
#define THUMB_IPAD_H_PADDING 20// ipad 宽度 - -间隔
#define CREDIT_LABEL_HEIGHT 20
#define AUTOSCROLL_THRESHOLD 30
//#define AUXPLAYERVIEW
@interface ComminuteViewController ()<RDICGVideoTrimmerDelegate,RDVECoreDelegate>
{
    double                   _clipStartTime;
    RDVECore                *_thumbVideoCore;
    RDATMHud                *_hud;
    float                    _totalDurationWidth;
    AVAssetImageGenerator   *_imageGenerator;
    id                       _obServerTimer;
    UIView                  *_playerView;
#ifdef AUXPLAYERVIEW
    UIView                  *_auxPlayerView;
#endif
    double                  _currentTime;
    double                  _scrollTime;
    RDICGVideoTrimmerView   *_trimmerView;
    UIButton                *_comminuteBtn;
    UILabel                 *_trimmerTimeLabel;
    UIView                  *_comminuteView;
    UIButton                *_comminutePlayButton;
    UILabel                 *_comminuteTitmeLabel;
    UILabel                 *_totalDurationLabel;

    BOOL                     _startRemove;
    UIImageView             *_removeImageView;
    UIImageView             *_removecurrentImageView;
    UIImageView             *_deletedRemoveImageView;
    UILabel                 *_deletedRemovePromptView;
    UIView                  *_backView;
    float                    timeRangeValue;
    float                    currentViewWidth;
    BOOL                     _isDragging;
    UIView                  *_comminuteThumbPromptBackView;
    UIView                  *_comminuteThumbPromptBackView1;
    RDComminuteRangeView    *currentComminuteRange;
   
    float                    moveRangeValueX;
    float                    moveRangeValueY;
    
    BOOL             isResignActive;
    CMTime                  seekTime;
    
    bool                 _isCore;
    
    bool                isFirst;
}
@property (strong, nonatomic) RDVECore    *videoCoreSDK;
@property (strong, nonatomic) NSMutableArray *trimArray;
/**视频
 */
@property(nonatomic,strong)NSMutableArray   *fileList;

@end


@implementation ComminuteViewController

- (void)tapPlayerView{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)scrollViewWillBegin:(UIScrollView *)scrollView{
    [self playVideo:NO];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    _editVideoSize = [RDHelpClass getEditSizeWithFile:_originFile];
    if (_originFile.isGif) {
        _clipStartTime = CMTimeGetSeconds(_originFile.imageTimeRange.duration)>0 ? CMTimeGetSeconds(_originFile.imageTimeRange.start): 0;
    }else {
        if(_originFile.isReverse){
            _clipStartTime = CMTimeGetSeconds(_originFile.reverseVideoTrimTimeRange.duration)>0 ? CMTimeGetSeconds(_originFile.reverseVideoTrimTimeRange.start): CMTimeGetSeconds(_originFile.reverseVideoTimeRange.start);
        }else{
            _clipStartTime = CMTimeGetSeconds(_originFile.videoTimeRange.duration)>0 ? CMTimeGetSeconds(_originFile.videoTrimTimeRange.start): CMTimeGetSeconds(_originFile.videoTimeRange.start);
        }
    }
    _hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:_hud.view];
    
    [self initPlayerView];
    
    if( _videoCoreSDK )
        isFirst = true;
    
    [self initChildView];
//    [self initPlayer];
    
    
    if( _originFile.contentURL )
        [self initThumbVideoCore];
    [self initTrimmerView];
    [self initdeletedRemoveImageView];
    [self initToolBarView];
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunComminutePromptBtn"]){
        [self initPromptComm];
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"firstRunComminutePromptBtn"];
    }
    
    [self performSelector:@selector(comminuteTouchesUp:) withObject:_comminuteBtn afterDelay:0.5];
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"分割", nil);
    titleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    titleLbl.font = [UIFont boldSystemFontOfSize:17];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
    [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    
    [RDHelpClass animateView:toolBarView atUP:NO];
}

- (void)initPromptComm{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunComminutePromptBtn"]) {
    
        _comminuteThumbPromptBackView = [[UIView alloc] initWithFrame:CGRectMake(_comminuteView.bounds.size.width/2-130/2, _trimmerView.center.y - _trimmerView.frame.size.height/2 - 103/2-20, 260/2, 103/2.0)];
        UILabel *_promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _comminuteThumbPromptBackView.frame.size.width, _comminuteThumbPromptBackView.frame.size.height-15/2)];
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.backgroundColor = UIColorFromRGB(0xffffff);
        _promptLabel.textColor = UIColorFromRGB(0x545454);
        _promptLabel.text = RDLocalizedString(@"拖动选择分割位置", nil);
        _promptLabel.font = [UIFont systemFontOfSize:14];
        _promptLabel.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
        _promptLabel.layer.borderWidth = 0.5;
        _promptLabel.layer.cornerRadius = 5;
        _promptLabel.layer.masksToBounds = YES;
    CGSize size = [_promptLabel sizeThatFits:CGSizeZero];
    _comminuteThumbPromptBackView.frame = CGRectMake((_comminuteView.bounds.size.width - size.width - 10)/2, _comminuteThumbPromptBackView.frame.origin.y, size.width + 10, _comminuteThumbPromptBackView.frame.size.height);
    _promptLabel.frame = CGRectMake(0, 0, _comminuteThumbPromptBackView.frame.size.width, _comminuteThumbPromptBackView.frame.size.height-15/2);
        
        UIImageView *sanjiao = [[UIImageView alloc] initWithFrame:CGRectMake(_comminuteThumbPromptBackView.frame.size.width/2 - 15/4.f, _promptLabel.frame.size.height, 15/2, 15/2)];
        sanjiao.backgroundColor = [UIColor clearColor];
        sanjiao.image = [RDHelpClass imageWithContentOfFile:@"sanjiaoxing"];
        [_comminuteThumbPromptBackView addSubview:sanjiao];
        
        
        UITapGestureRecognizer *tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTishiyu:)];
        _comminuteThumbPromptBackView.userInteractionEnabled = YES;
        [_comminuteThumbPromptBackView addGestureRecognizer:tapgesture];
        [_comminuteThumbPromptBackView addSubview:_promptLabel];
        _comminuteThumbPromptBackView.hidden = NO;
        [_comminuteView addSubview:_comminuteThumbPromptBackView];
    }
}

- (void)tapTishiyu:(UITapGestureRecognizer *)gesture{
    gesture.view.hidden = YES;
}

- (void)initPromptCommPP{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunComminutePromptBtn1"]) {
    
        _comminuteThumbPromptBackView1 = [[UIView alloc] initWithFrame:CGRectMake((_comminuteView.bounds.size.width - 235)/2, _trimmerView.center.y - _trimmerView.frame.size.height/2 - 103/2-20, 235, 103/2.0)];
        UILabel *_promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _comminuteThumbPromptBackView1.frame.size.width, _comminuteThumbPromptBackView1.frame.size.height-15/2)];
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.backgroundColor = UIColorFromRGB(0xffffff);
        _promptLabel.textColor = UIColorFromRGB(0x54545454);
        _promptLabel.text = RDLocalizedString(@"长按并向上拖动分割的片段可以删除", nil);
        _promptLabel.font = [UIFont systemFontOfSize:14];
        _promptLabel.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
        _promptLabel.layer.borderWidth = 0.5;
        _promptLabel.layer.cornerRadius = 5;
        _promptLabel.layer.masksToBounds = YES;
        _promptLabel.adjustsFontSizeToFitWidth = YES;
        
        UIImageView *sanjiao = [[UIImageView alloc] initWithFrame:CGRectMake(_comminuteThumbPromptBackView1.frame.size.width/2 - 15/4.f, _promptLabel.frame.size.height, 15/2, 15/2)];
        sanjiao.backgroundColor = [UIColor clearColor];
        sanjiao.image = [RDHelpClass imageWithContentOfFile:@"sanjiaoxing"];
        [_comminuteThumbPromptBackView1 addSubview:sanjiao];
        
        UITapGestureRecognizer *tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTishiyu:)];
        _comminuteThumbPromptBackView1.userInteractionEnabled = YES;
        [_comminuteThumbPromptBackView1 addGestureRecognizer:tapgesture];
        [_comminuteThumbPromptBackView1 addSubview:_promptLabel];
        _comminuteThumbPromptBackView1.hidden = NO;
        [_comminuteView addSubview:_comminuteThumbPromptBackView1];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self playVideo:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _trimmerView = nil;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    
    if (!_deletedRemoveImageView.hidden) {
        NSMutableArray *childs = [_trimmerView getTimesFor_videoRangeView];
        _deletedRemoveImageView.hidden = YES;
        _backView.hidden = YES;
        _deletedRemoveImageView.backgroundColor = [UIColor redColor];
        _deletedRemoveImageView.image = [RDHelpClass imageWithContentOfFile:@"剪辑-删除1_"];
        _deletedRemovePromptView.text = RDLocalizedString(@"拖拽到垃圾箱中删除", nil);
        if(childs.count<2){
            _removeImageView.hidden = YES;
            [_removeImageView removeFromSuperview];
            _removecurrentImageView.hidden = NO;
            _removeImageView = nil;
            _removecurrentImageView = nil;
            _startRemove = NO;
            [_hud setCaption:RDLocalizedString(@"最少保留一段视频!", nil)];
            [_hud show];
            [_hud hideAfter:2];
            
            return;
        }
        if(_removeImageView.center.y<=_deletedRemoveImageView.center.y){
            
            _startRemove = NO;
            float width = 0;
            
            for (UIImageView *rangeView in _trimmerView.videoRangeView.subviews) {
                if(rangeView.frame.origin.x>_removecurrentImageView.frame.origin.x){
                    rangeView.frame = CGRectMake(rangeView.frame.origin.x - _removecurrentImageView.frame.size.width-10, 0, rangeView.frame.size.width, rangeView.frame.size.height);
                }
            }
            _removeImageView.hidden = YES;
            [_removeImageView removeFromSuperview];
            [_removecurrentImageView removeFromSuperview];
            _removeImageView = nil;
            _startRemove = NO;
            
            for (UIImageView *rangeView in _trimmerView.videoRangeView.subviews) {
                width = width + CGRectGetWidth(rangeView.frame)+10;
            }
            CGRect rect2 = _trimmerView.contentView.frame;
            
            
            _trimmerView.contentView.frame = CGRectMake(rect2.origin.x, rect2.origin.y, rect2.size.width - currentViewWidth - 10, rect2.size.height);
            _removecurrentImageView = nil;
            
            [_videoCoreSDK seekToTime:kCMTimeZero];
            [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
            [_trimmerView setProgress:0 animated:NO];
            
            [self refreshPlayer:NO];
        }else{
            _removeImageView.hidden = YES;
            [_removeImageView removeFromSuperview];
            _removecurrentImageView.hidden = NO;
            _removeImageView = nil;
            _removecurrentImageView = nil;
            _startRemove = NO;
        }
    }    
}
- (void)appEnterForegroundNotification:(NSNotification *)notification{
    NSLog(@"进入前台");
    isResignActive = NO;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if( _videoCoreSDK )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           [self seektimeCore];
        });
    }
}
/*
 初始化视频播放控件
 */
- (void)initPlayerView{
    _playerView = [[UIView alloc] init];
    _playerView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
    _playerView.backgroundColor =  [UIColor clearColor];
    [self.view addSubview:_playerView];
#ifdef AUXPLAYERVIEW
    _auxPlayerView = [[UIView alloc] init];
    _auxPlayerView.frame = CGRectMake(0, 0, 40, 40);
    _auxPlayerView.center = CGPointMake(kWIDTH/2, kWIDTH + 25);
    _auxPlayerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_auxPlayerView];
#endif
    _comminutePlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _comminutePlayButton.backgroundColor = [UIColor clearColor];
    _comminutePlayButton.frame = CGRectMake(5, kPlayerViewHeight - 44, 44, 44);
    [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    [_comminutePlayButton addTarget:self action:@selector(tapPlayerBtn) forControlEvents:UIControlEventTouchUpInside];
    [_playerView addSubview:_comminutePlayButton];
}

/**初始化删除按钮
 */
- (void)initdeletedRemoveImageView{
    _backView = [[UIView alloc] initWithFrame:self.view.frame];
    _backView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    _backView.hidden = YES;
    [self.view insertSubview:_backView aboveSubview:_comminuteView];
    
    _deletedRemoveImageView = [[UIImageView alloc] init];
    _deletedRemoveImageView.frame = CGRectMake((_backView.frame.size.width - 50)/2, (_playerView.frame.size.height - 50)/2, 50, 50);
    _deletedRemoveImageView.layer.cornerRadius = 50/2;
    _deletedRemoveImageView.layer.masksToBounds = YES;
    _deletedRemoveImageView.contentMode = UIViewContentModeCenter;
    _deletedRemoveImageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    _deletedRemoveImageView.hidden = YES;
    [_backView addSubview:_deletedRemoveImageView];
    
    _deletedRemovePromptView = [[UILabel alloc] init];
    _deletedRemovePromptView.frame = CGRectMake(0, (_playerView.frame.size.height-50)/2 - 30 , _backView.frame.size.width, 30);
    _deletedRemovePromptView.text = RDLocalizedString(@"拖拽到垃圾箱中删除", nil);
    _deletedRemovePromptView.backgroundColor = [UIColor clearColor];
    _deletedRemovePromptView.textColor = UIColorFromRGB(0xffffff);
    _deletedRemovePromptView.textAlignment = NSTextAlignmentCenter;
    _deletedRemovePromptView.font = [UIFont systemFontOfSize:14];
    [_backView addSubview:_deletedRemovePromptView];
}

#pragma mark- 添加滤镜
- (void)refreshVideoCoreSDK {
    NSMutableArray *scenes = [NSMutableArray new];
    for (int i = 0; i<_fileList.count; i++) {
        RDFile *file = _fileList[i];
        RDScene *scene = [[RDScene alloc] init];
        
        VVAsset* vvasset = [[VVAsset alloc] init];
        
        vvasset.url = file.contentURL;
        
        if(file.fileType == kFILEVIDEO){
            vvasset.type = RDAssetTypeVideo;
            vvasset.videoActualTimeRange = file.videoActualTimeRange;
            if(file.isReverse){
                vvasset.url = file.reverseVideoURL;
                
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
                }else{
                    vvasset.timeRange = file.reverseVideoTimeRange;
                }
                
                NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
            }
            else{
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
                }else{
                    vvasset.timeRange = file.videoTimeRange;
                }
                NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
            }
            vvasset.speed        = file.speed;
            vvasset.volume       = file.videoVolume;
        }else{
            NSLog(@"图片");
            vvasset.type         = RDAssetTypeImage;
            if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                vvasset.timeRange = file.imageTimeRange;
            }else {
                vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            }
            vvasset.speed        = file.speed;
            
        }
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.crop = file.crop;
        
        vvasset.brightness = file.brightness;
        vvasset.contrast = file.contrast;
        vvasset.saturation = file.saturation;
        vvasset.sharpness = file.sharpness;
        vvasset.whiteBalance = file.whiteBalance;
        vvasset.vignette = file.vignette;
        if (_globalFilters.count > 0) {
            RDFilter* filter = _globalFilters[file.filterIndex];
            if (filter.type == kRDFilterType_LookUp) {
                vvasset.filterType = VVAssetFilterLookup;
            }else if (filter.type == kRDFilterType_ACV) {
                vvasset.filterType = VVAssetFilterACV;
            }else {
                vvasset.filterType = VVAssetFilterEmpty;
            }
            if (filter.filterPath.length > 0) {
                vvasset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }
        [scene.vvAsset addObject:vvasset];
        scene.transition.type   = RDVideoTransitionTypeNone;
        scene.transition.duration = 0.0;
        [scenes addObject:scene];
    }
    [_videoCoreSDK setScenes:scenes];
    
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.volume = _musicVolume;
        music.isFadeInOut = YES;
        [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
    }
    [_videoCoreSDK build];
}

- (void)initThumbVideoCore{
    _thumbVideoCore = nil;
    
    NSMutableArray *scenes = [NSMutableArray new];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = _originFile.contentURL;
    
    if(_originFile.fileType == kFILEVIDEO){
        vvasset.type = RDAssetTypeVideo;
        vvasset.videoActualTimeRange = _originFile.videoActualTimeRange;
        if(_originFile.isReverse){
            if (CMTimeRangeEqual(kCMTimeRangeZero, _originFile.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _originFile.reverseDurationTime);
            }else{
                vvasset.timeRange = _originFile.reverseVideoTimeRange;
            }
            
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _originFile.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _originFile.videoDurationTime);
            }else{
                vvasset.timeRange = _originFile.videoTimeRange;
            }
            NSLog(@"timeRange.duration:%f",CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        vvasset.speed        = _originFile.speed;
        vvasset.volume       = _originFile.videoVolume;
    }else{
        NSLog(@"图片");
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(_originFile.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = _originFile.imageTimeRange;
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, _originFile.imageDurationTime);
        }
        vvasset.speed        = _originFile.speed;
        vvasset.volume       = _originFile.videoVolume;
    }
    scene.transition.type   = RDVideoTransitionTypeNone;
    scene.transition.duration = 0.0;
    vvasset.rotate = _originFile.rotate;
    vvasset.isVerticalMirror = _originFile.isVerticalMirror;
    vvasset.isHorizontalMirror = _originFile.isHorizontalMirror;
    vvasset.crop = _originFile.crop;
    [scene.vvAsset addObject:vvasset];
    [scenes addObject:scene];
    
    _thumbVideoCore =  [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                             APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                             LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                             videoSize:_editVideoSize
                                                   fps:kEXPORTFPS
                                            resultFail:^(NSError *error) {
                                                NSLog(@"initSDKError:%@", error.localizedDescription);
                                            }];
    _thumbVideoCore.frame = _playerView.bounds;
    _thumbVideoCore.view.frame = _playerView.bounds;
    [_thumbVideoCore setScenes:scenes];
    [_thumbVideoCore build];
}
-(void)seekTime:(CMTime) time
{
    seekTime = time;
}
- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.frame = CGRectMake(0, 0, kWIDTH, kPlayerViewHeight);
//        [_videoCoreSDK prepare];
        _videoCoreSDK.view.frame = CGRectMake(0, 0, kWIDTH, kPlayerViewHeight);
        [_playerView insertSubview:_videoCoreSDK.view atIndex:0];
//        [_videoCoreSDK getScenes];
//        [self.view insertSubview: belowSubview:self.playButton];
    }
    else
        [self initPlayer];
}

-(void)setVideoCoreSDK:(RDVECore *) core
{
    if( core )
        _isCore = true;
    _videoCoreSDK = core;
}

/*
 初始化播放器
 */
- (void)initPlayer{
    NSMutableArray *scenes = [NSMutableArray new];
    RDFile *file = _originFile;
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = file.contentURL;
    
    if(file.fileType == kFILEVIDEO){
        vvasset.videoActualTimeRange = file.videoActualTimeRange;
        vvasset.type = RDAssetTypeVideo;
        if(file.isReverse){
            vvasset.url = file.reverseVideoURL;
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
            }else{
                vvasset.timeRange = file.reverseVideoTimeRange;
            }
            if(CMTimeCompare(vvasset.timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                vvasset.timeRange = file.reverseVideoTrimTimeRange;
            }
            NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
            
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                vvasset.timeRange = file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                vvasset.timeRange = file.videoTrimTimeRange;
            }
            NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;
    }else{
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = file.imageTimeRange;
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;
    }
    vvasset.rotate = file.rotate;
    vvasset.isVerticalMirror = file.isVerticalMirror;
    vvasset.isHorizontalMirror = file.isHorizontalMirror;
    vvasset.crop = file.crop;
    
    vvasset.brightness = file.brightness;
    vvasset.contrast = file.contrast;
    vvasset.saturation = file.saturation;
    vvasset.sharpness = file.sharpness;
    vvasset.whiteBalance = file.whiteBalance;
    vvasset.vignette = file.vignette;
    if (_globalFilters.count > 0) {
        RDFilter* filter = _globalFilters[file.filterIndex];
        if (filter.type == kRDFilterType_LookUp) {
            vvasset.filterType = VVAssetFilterLookup;
        }else if (filter.type == kRDFilterType_ACV) {
            vvasset.filterType = VVAssetFilterACV;
        }else {
            vvasset.filterType = VVAssetFilterEmpty;
        }
        if (filter.filterPath.length > 0) {
            vvasset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
        }
    }
    
    [scene.vvAsset addObject:vvasset];
    //添加特效
    //滤镜特效
    if( _originFile.customFilterIndex != 0 )
    {
        NSArray *filterFxArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        vvasset.customFilter = [RDGenSpecialEffect getCustomFilerWithFxId:_originFile.customFilterId filterFxArray:filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
    }
    //时间特效
    if( _originFile.fileTimeFilterType != kTimeFilterTyp_None )
    {
        [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:_originFile atscene:scene atTimeRange:_originFile.fileTimeFilterTimeRange atIsRemove:NO];
    }
    else
        [scenes addObject:scene];
    _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                           APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                          LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                           videoSize:_editVideoSize
                                                 fps:15
                                          resultFail:^(NSError *error) {
                                              NSLog(@"initSDKError:%@", error.localizedDescription);
                                          }];
    _videoCoreSDK.frame = _playerView.bounds;
    _videoCoreSDK.view.backgroundColor = [UIColor blackColor];
    _videoCoreSDK.delegate = self;
    [_videoCoreSDK setScenes:scenes];
    
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.volume = _musicVolume;
        music.isFadeInOut = YES;
        [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
    }
    [_videoCoreSDK build];
    [_playerView insertSubview:_videoCoreSDK.view atIndex:0];
#ifdef AUXPLAYERVIEW
    UIView* auxView = [_videoCoreSDK auxViewWithCGRect:CGRectMake(10, 10, 80, 80)];
    
    auxView.center = CGPointMake(20, 20);
    [_auxPlayerView addSubview:auxView];
    _auxPlayerView.layer.masksToBounds = YES;
#endif
    
}

-(void)seektimeCore
{
    if( CMTimeGetSeconds(seekTime) > 0 )
    {
        __block double time = CMTimeGetSeconds(seekTime);
        [_videoCoreSDK seekToTime:seekTime];
        seekTime = kCMTimeZero;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            float duration = _videoCoreSDK.duration;
            _comminuteTitmeLabel.text = [RDHelpClass timeToStringFormat:_trimmerView.scrollcurrentTime];
            _trimmerTimeLabel.text = [RDHelpClass timeToStringFormat:_trimmerView.scrollcurrentTime];
            _trimArray = [_trimmerView getTimesFor_videoRangeView];
            if( duration>0 ){
                if(_trimArray.count>0){
                    float rate = (_totalDurationWidth-_trimmerView.currentIndex*10)/duration;
                    float value = rate * time + _trimmerView.currentIndex*10;
                    [_trimmerView setProgress:value animated:NO];
                    _isDragging = NO;
                    _trimmerView.scrollView.bounces = NO;
                    
                }else{
                    float rate = _trimmerView.videoRangeView.frame.size.width / duration;
                    float value = rate * time;
                    [_trimmerView setProgress:value animated:NO];
                    _isDragging = NO;
                }
            }
        });
    }
}

- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if(status == kRDVECoreStatusReadyToPlay && sender == _videoCoreSDK){
        [RDSVProgressHUD dismiss];
        if (!isResignActive) {
//            [self playVideo:YES];
        }
        [self seektimeCore];
    }
}

- (void)progressCurrentTime:(CMTime)currentTime{
    if(![_videoCoreSDK isPlaying]){
        return;
    }
    if([[NSString stringWithFormat:@"%f", CMTimeGetSeconds(currentTime)] isEqualToString:@"nan"])
    {
        return;
    }
    double time = CMTimeGetSeconds(currentTime);
    
    float duration = _videoCoreSDK.duration;
    _comminuteTitmeLabel.text = [RDHelpClass timeToStringFormat:_trimmerView.scrollcurrentTime];
    _trimmerTimeLabel.text = [RDHelpClass timeToStringFormat:_trimmerView.scrollcurrentTime];
    if(duration>0 && [_videoCoreSDK isPlaying]){
        if(_trimArray.count>0){
            float rate = (_totalDurationWidth-_trimmerView.currentIndex*10)/duration;
            float value = rate * time + _trimmerView.currentIndex*10;
            [_trimmerView setProgress:value animated:NO];
            _isDragging = NO;
            _trimmerView.scrollView.bounces = NO;
            
        }else{
            float rate = _trimmerView.videoRangeView.frame.size.width / duration;
            float value = rate * time;
            [_trimmerView setProgress:value animated:NO];
            _isDragging = NO;
        }
    }
}

- (void)refreshPlayer:(BOOL)play{
    
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];

    NSMutableArray *childs = [_trimmerView getTimesFor_videoRangeView];
    if(!(childs.count>0)){
        [self refreshVideoCoreSDK];
        _trimArray = childs;
        return;
    }
    
    NSMutableArray          *files = [[NSMutableArray alloc] init];
    _totalDurationWidth = 0;
    for (RDComminuteRangeView *thumb in childs) {
        _totalDurationWidth += thumb.frame.size.width+10;
        RDFile *file = thumb.file;
        [files addObject:file];
        
        NSLog(@"%lf || %lf",CMTimeGetSeconds(file.videoTimeRange.start),CMTimeGetSeconds(file.videoTimeRange.duration));
    }
    _fileList = files;
    [self refreshVideoCoreSDK];
    _totalDurationWidth -= 10;
    [_trimmerView.scrollView setContentSize:CGSizeMake(_trimmerView.scrollView.frame.size.width + _totalDurationWidth, _trimmerView.scrollView.contentSize.height)];
  
    _trimArray = childs;
    
    [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
}

- (void)playToEnd{
    dispatch_async(dispatch_get_main_queue(), ^{
        _trimmerView.currentIndex = 0;
        [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:kCMTimeZero completionHandler:nil];
        _comminuteTitmeLabel.text = [RDHelpClass timeToStringFormat:0];
        _trimmerTimeLabel.text = [RDHelpClass timeToStringFormat:0];
        [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_trimmerView setProgress:0 animated:NO];
    });
}

- (void)initTrimmerView{
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight)];
    imageView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:imageView];
    
    _comminuteView = [[UIView alloc] init];
    _comminuteView.frame = CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight + (kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight - 104)/2.0, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight);
    _comminuteView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:_comminuteView];
    
    _comminuteTitmeLabel = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 60)/2, 0, 60, 20)];
    _comminuteTitmeLabel.textAlignment = NSTextAlignmentCenter;
    _comminuteTitmeLabel.textColor = UIColorFromRGB(0xffffff);
    _comminuteTitmeLabel.text = @"+00";
    _comminuteTitmeLabel.font = [UIFont systemFontOfSize:12];
    [_comminuteView addSubview:_comminuteTitmeLabel];
    
    CGRect rect = CGRectMake(0, 24+5, _comminuteView.frame.size.width, 50);
    _trimmerView = [[RDICGVideoTrimmerView alloc] initWithFrame:rect composition:_thumbVideoCore.composition];
    _trimmerView.backgroundColor = [UIColor clearColor];
    _trimmerView.contentFile = _originFile;
    [_trimmerView setThemeColor:[UIColor lightGrayColor]];
    _trimmerView.composition = _thumbVideoCore.composition;
    _trimmerView.videoComposition = _thumbVideoCore.videoComposition;
    [_trimmerView setShowsborderView:NO];
    [_trimmerView setShowsRulerView:NO];
    [_trimmerView setDelegate:self];
    [_trimmerView resetSubviews];
    
    _trimmerView.scrollView.scrollEnabled = YES;
    [_comminuteView addSubview:_trimmerView];
    
    _comminuteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _comminuteBtn.backgroundColor = [UIColor clearColor];
    _comminuteBtn.frame = CGRectMake((_trimmerView.frame.size.width - 40)/2.0, _trimmerView.frame.origin.y -5, 40, 70);

    UILabel * comminuteLabel = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 60)/2, _trimmerView.frame.origin.y + _trimmerView.frame.size.height + 10, 60, 20)];
    comminuteLabel.textAlignment = NSTextAlignmentCenter;
    comminuteLabel.textColor = UIColorFromRGB(0x888888);
    comminuteLabel.text = RDLocalizedString(@"点击分割", nil);
    comminuteLabel.font = [UIFont systemFontOfSize:12];
    [_comminuteView addSubview:comminuteLabel];
        
    _comminuteBtn.layer.cornerRadius =0;
    _comminuteBtn.layer.masksToBounds = YES;
    [_comminuteBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑-分割_"] forState:UIControlStateNormal];
    [_comminuteBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑-分割_"] forState:UIControlStateHighlighted];
    [_comminuteBtn addTarget:self action:@selector(comminuteTouchesUp:) forControlEvents:UIControlEventTouchUpInside];
    [_comminuteView addSubview:_comminuteBtn];
#if ENABLEHIGHLIGHT
    if(_selectVideoThumb.isReverse){
        Float64 start1 = CMTimeGetSeconds(_selectVideoThumb.reverseClipSliderTimeRange.start);
        Float64 duration1 = CMTimeGetSeconds(_selectVideoThumb.reverseClipSliderTimeRange.duration);
        
        NSURL *fileUrl= _selectVideoThumb.reverseUrlAsset.URL;
        [RDHelpClass getHighlightArray:fileUrl start:start1 duration:duration1 andThen:^(NSMutableArray *highlight) {
            _trimmerView.highlightArray = highlight;
        }];
    }else{
        Float64 start1 = CMTimeGetSeconds(_selectVideoThumb.clipSliderTimeRange.start);
        Float64 duration1 = CMTimeGetSeconds(_selectVideoThumb.clipSliderTimeRange.duration);
        
        NSURL *fileUrl= _selectVideoThumb.urlAsset.URL;
        if(_selectVideoThumb.contentURL){
            fileUrl= _selectVideoThumb.contentURL;
        }
        [RDHelpClass getHighlightArray:fileUrl start:start1 duration:duration1 andThen:^(NSMutableArray *highlight) {
            _trimmerView.highlightArray = highlight;
        }];
    }
#endif
     _totalDurationWidth = _trimmerView.videoRangeView.frame.size.width;
     [_trimmerView.scrollView setContentSize:CGSizeMake(_trimmerView.scrollView.frame.size.width + _totalDurationWidth, _trimmerView.scrollView.contentSize.height)];
    
    [RDHelpClass animateView:_comminuteView atUP:NO];
    
}

- (void)initImageGenerator{
    _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_thumbVideoCore.composition];
    _imageGenerator.videoComposition = _thumbVideoCore.videoComposition;
    _imageGenerator.appliesPreferredTrackTransform = YES;
    _imageGenerator.maximumSize = CGSizeMake(CGRectGetWidth(_trimmerView.frameView.frame)*2, 240);
}

/**返回
 */
- (void)back{
    [self realseCore];
    
//    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:NO completion:^{

    }];
}
/**保存
 */
- (void)save{
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];

    NSMutableArray <RDComminuteRangeView *> *childs = [_trimmerView getTimesFor_videoRangeView];
    NSMutableArray *files = [NSMutableArray new];
    for (int i = 0; i<childs.count; i++) {
        float width = childs[i].superview.frame.size.width - ((childs.count - 1)*10);
        float itemorginx = childs[i].frame.origin.x - (i *10);
        float itemWidth = childs[i].frame.size.width;
        
        RDFile *file = childs[i].file;
        file.speed = _originFile.speed;
        if (file.isGif) {
            CMTimeRange timerange = file.imageTimeRange;
            
            timerange.start = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.imageTimeRange.start)*_originFile.speed + _clipStartTime, TIMESCALE);
            timerange.duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.imageTimeRange.duration)*_originFile.speed, TIMESCALE);
            
            file.imageTimeRange = timerange;
            file.imageDurationTime = timerange.duration;
            file.thumbImage = [UIImage getGifThumbImageWithData:file.gifData time:CMTimeGetSeconds(file.imageTimeRange.start)];
            NSLog(@"imageTimeRange: %f : %f ",CMTimeGetSeconds(file.imageTimeRange.start),CMTimeGetSeconds(file.imageTimeRange.duration));
            NSLog(@"----------------");
        }else if(file.isReverse){
            CMTimeRange timerange = file.reverseVideoTimeRange;
            
            timerange.start = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.reverseVideoTimeRange.start)*_originFile.speed + _clipStartTime, TIMESCALE);
            timerange.duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.reverseVideoTimeRange.duration)*_originFile.speed, TIMESCALE);
            file.reverseVideoTrimTimeRange = kCMTimeRangeZero;
            file.reverseVideoTimeRange = timerange;
            file.reverseDurationTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)*_originFile.speed, TIMESCALE);
            
            file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(file.reverseVideoTrimTimeRange.start) url:file.reverseVideoURL urlAsset:nil];
            
            NSLog(@"reverseVideoTrimTimeRange : %f : %f ",CMTimeGetSeconds(file.reverseVideoTrimTimeRange.start),CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration));
            
            NSLog(@"reverseVideoTimeRange: %f : %f ",CMTimeGetSeconds(file.reverseVideoTimeRange.start),CMTimeGetSeconds(file.reverseVideoTimeRange.duration));
            
            float start = CMTimeGetSeconds(_originFile.videoTimeRange.start) + CMTimeGetSeconds(_originFile.videoTimeRange.duration) *((width - itemorginx - itemWidth)/width);
            float duration = CMTimeGetSeconds(_originFile.videoTimeRange.duration) *(itemWidth/width);
            
            file.videoDurationTime = CMTimeMakeWithSeconds(duration, TIMESCALE);
            file.videoTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(start, TIMESCALE), CMTimeMakeWithSeconds(duration, TIMESCALE));
            file.videoTrimTimeRange = kCMTimeRangeZero;//CMTimeRangeMake(CMTimeMakeWithSeconds(start, TIMESCALE), CMTimeMakeWithSeconds(duration, TIMESCALE));
            NSLog(@"file.videoTrimTimeRange : %f : %f ",CMTimeGetSeconds(file.videoTrimTimeRange.start),CMTimeGetSeconds(file.videoTrimTimeRange.duration));
            NSLog(@"file.videoTimeRange: %f : %f ",CMTimeGetSeconds(file.videoTimeRange.start),CMTimeGetSeconds(file.videoTimeRange.duration));
            NSLog(@"----------------");
        }else{
            float reStart = _clipStartTime + CMTimeGetSeconds(_originFile.reverseVideoTimeRange.duration) *((width - itemorginx - itemWidth)/width);
            float reDuration = CMTimeGetSeconds(_originFile.reverseVideoTimeRange.duration) *(itemWidth/width);
            
            file.reverseDurationTime = CMTimeMakeWithSeconds(reDuration * _originFile.speed, TIMESCALE);
            file.reverseVideoTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(reStart, TIMESCALE), CMTimeMakeWithSeconds(reDuration, TIMESCALE));
            file.reverseVideoTrimTimeRange = kCMTimeRangeZero;
            
            CMTimeRange timerange = file.videoTimeRange;
            
            timerange.start = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.videoTimeRange.start)*_originFile.speed + _clipStartTime, TIMESCALE);
            timerange.duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.videoTimeRange.duration)*_originFile.speed, TIMESCALE);
            
            file.videoTrimTimeRange = timerange;
            file.videoTimeRange = timerange;
            
            file.videoDurationTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(file.videoTimeRange.duration), TIMESCALE);
            file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(file.videoTimeRange.start) url:file.contentURL urlAsset:nil];
            //NSLog(@"file.videoTrimTimeRange : %f : %f ",CMTimeGetSeconds(file.videoTrimTimeRange.start),CMTimeGetSeconds(file.videoTrimTimeRange.duration));
            NSLog(@"file.videoTimeRange: %f : %f ",CMTimeGetSeconds(file.videoTimeRange.start),CMTimeGetSeconds(file.videoTimeRange.duration));
            NSLog(@"----------------");
        }
        file.videoVolume = _originFile.videoVolume;
        file.customFilterIndex = _originFile.customFilterIndex;
        file.filtImagePatch = _originFile.filtImagePatch;
        file.fileTimeFilterType = _originFile.fileTimeFilterType;
        file.fileTimeFilterTimeRange = _originFile.fileTimeFilterTimeRange;
        file.brightness = _originFile.brightness;
        file.contrast = _originFile.contrast;
        file.saturation = _originFile.saturation;
        
        if( (_originFile.backgroundType !=  KCanvasType_None) && (_originFile.backgroundType !=  KCanvasType_Color) )
        {
            file.fileScale = _originFile.fileScale;
            file.backgroundType = _originFile.backgroundType;
            file.backgroundStyle = _originFile.backgroundStyle;
            file.BackgroundFile = [_originFile.BackgroundFile mutableCopy];
            file.BackgroundBlurIntensity = _originFile.BackgroundBlurIntensity;
            file.backgroundColor = [_originFile.backgroundColor mutableCopy];
            file.rectInFile = _originFile.rectInFile;
            file.rectInScene = _originFile.rectInScene;
            file.rectInScale = _originFile.rectInScale;
            file.BackgroundRotate = _originFile.BackgroundRotate;
        }
        
        file.filterIndex = _originFile.filterIndex;
        
        [files addObject:file];
    }
    if(childs.count>0 && _comminuteVideoFinishBlock)
    _comminuteVideoFinishBlock(files);
    
    [self realseCore];
    
    
//    [self.navigationController popViewControllerAnimated:NO];
    [RDSVProgressHUD dismiss];
    
    [self dismissViewControllerAnimated:NO completion:^{
//        [RDSVProgressHUD dismiss];
    }];

}

/*
    分割
 */
- (void)comminuteTouchesUp:(UIButton *)sender{
    
    if(!_trimmerView.loadImageFinish){
        return;
    }
    [self playVideo:NO];
    BOOL suc = [_trimmerView cuttingVideo:_trimmerView.scrollcurrentTime];
    if(!suc){
        if( !isFirst && _trimmerView.lastLowTime<0.2){
            [_hud setCaption:RDLocalizedString(@"分割不能小于0.2秒!", nil)];
            [_hud show];
            [_hud hideAfter:2];
        }
        else
            isFirst = false;
        return;
    }else{
        if(![[NSUserDefaults standardUserDefaults] objectForKey:@"firstRunComminutePromptBtn1"]){
            [self initPromptCommPP];
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"firstRunComminutePromptBtn1"];
        }
        _trimArray = [_trimmerView getTimesFor_videoRangeView];
        
        
        _totalDurationWidth = 0;
        for (RDComminuteRangeView *thumb in _trimArray) {
            _totalDurationWidth += thumb.frame.size.width+10;
        }
        _totalDurationWidth -= 10;
    }
}

//20171026 wuxiaoxia 优化内存
- (void)trimmerViewRefreshThumbsCompletion {
    [_thumbVideoCore stop];
    _thumbVideoCore = nil;
}

- (void)trimmerView:(RDICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime{
    //NSLog(@"didChangeLeftPosition");
    float contentSize = _trimmerView.scrollView.contentSize.width - _trimmerView.scrollView.frame.size.width;
    float ofsetx = _trimmerView.scrollView.contentOffset.x;
    _currentTime = _videoCoreSDK.duration * ofsetx/contentSize;
    
    _trimmerTimeLabel.text = [RDHelpClass timeToStringFormat:_currentTime/_originFile.speed];//_trimmerView.scrollcurrentTime

    if(![_videoCoreSDK isPlaying]){
       _comminuteTitmeLabel.text = [RDHelpClass timeToStringFormat:_trimmerView.scrollcurrentTime];
        [self seektoTime];
    }
}

- (void)seektoTime{
    
    float ofsetx = _trimmerView.scrollView.contentOffset.x;

    float duration = _videoCoreSDK.duration;
    
    if(_trimArray.count>0){
        float rate = (_totalDurationWidth-_trimmerView.currentIndex*10)/duration;
        float currentTime = (ofsetx - _trimmerView.currentIndex*10)/rate;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(currentTime,TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
        
    }else{
        float rate = _trimmerView.videoRangeView.frame.size.width / duration;
        float currentTime = ofsetx /rate ;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(currentTime,TIMESCALE) toleranceTime:kCMTimeZero completionHandler:nil];
    }
}

- (void)trimmerViewScrollViewWillBegin:(UIScrollView *)scrollView{
    //NSLog(@"%s",__func__);
    if(_isDragging){
        return;
    }
    if(_comminuteThumbPromptBackView){
        _comminuteThumbPromptBackView.hidden = YES;
    }
    if(_comminuteThumbPromptBackView1){
        _comminuteThumbPromptBackView1.hidden = YES;
    }
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    _isDragging = YES;
}

- (void)trimmerViewScrollViewWillEnd:(UIScrollView *)scrollView startTime:(Float64)comminuteStartTime endTime:(Float64)comminuteEndTime{
    //NSLog(@"%s",__func__);
    _isDragging = NO;
    
    //_comminuteTitmeLabel.text = [RDHelpClass timeToStringFormat:comminuteStartTime];
    [self seektoTime];
    
    
    
}

- (void)tapPlayerBtn{
    if(_comminuteThumbPromptBackView){
        _comminuteThumbPromptBackView.hidden = YES;
    }
    if(_comminuteThumbPromptBackView1){
        _comminuteThumbPromptBackView1.hidden = YES;
    }
    
    [self playVideo:![_videoCoreSDK isPlaying]];
}
#pragma mark- 播放暂停
/*
    播放视频
 */
- (void)playVideo:(BOOL)play{
    if(_trimmerView.cannotPlay){
        return;
    }
    if(!play){
        [_videoCoreSDK pause];
        [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        if(_totalDurationWidth ==0){
            _totalDurationWidth = _trimmerView.videoRangeView.frame.size.width;
        }
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }
    }
}

#pragma mark 删除一个视频中的某一段
- (void)deleteForRangeView:(UILongPressGestureRecognizer *)gesture{
    CGPoint location = [gesture locationInView:_trimmerView.videoRangeView];
    
    CGPoint location2 = [gesture locationInView:self.view];

    if(!_startRemove){
        for (RDComminuteRangeView *imageView  in _trimmerView.videoRangeView.subviews) {
            if(imageView.frame.origin.x<location.x && location.x<imageView.frame.origin.x+imageView.frame.size.width){
                _removeImageView = nil;
                _removeImageView = [[UIImageView alloc] init];
                _removeImageView.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
                _removeImageView.layer.borderWidth = 2;
                _removeImageView.backgroundColor = [UIColor yellowColor];
                _removeImageView.userInteractionEnabled = YES;
                [self.view addSubview:_removeImageView];
                [self.view bringSubviewToFront:_removeImageView];
                
                _removecurrentImageView = imageView;
                _removeImageView.image = imageView.image;
                imageView.hidden = YES;
                currentViewWidth = imageView.frame.size.width;
                timeRangeValue = CMTimeGetSeconds(imageView.file.videoTimeRange.duration);
                _startRemove = YES;
                break;
            }
        }
    }
    if(gesture.state == UIGestureRecognizerStateBegan){
        if([_videoCoreSDK isPlaying]){
            [self playVideo:NO];
        }
        if(_comminuteThumbPromptBackView){
            _comminuteThumbPromptBackView.hidden = YES;
        }
        if(_comminuteThumbPromptBackView1){
            _comminuteThumbPromptBackView1.hidden = YES;
        }
        _deletedRemoveImageView.hidden = NO;
        _backView.hidden = NO;
        _deletedRemoveImageView.image = [RDHelpClass imageWithContentOfFile:@"剪辑-删除1_"];
        _deletedRemovePromptView.text = RDLocalizedString(@"拖拽到垃圾箱中删除", nil);
        _deletedRemoveImageView.backgroundColor = [UIColor redColor];
        
        
        float width = _removecurrentImageView.frame.origin.x - _trimmerView.scrollView.contentOffset.x+40;
        NSLog(@"%lf",width);
        
        moveRangeValueX  = location2.x - width;
        moveRangeValueY = location.y - _removecurrentImageView.frame.origin.y;
        _removeImageView.frame = CGRectMake(width + _trimmerView.frame.size.width/2, _trimmerView.frame.origin.y+_comminuteView.frame.origin.y, _removecurrentImageView.frame.size.width, _removecurrentImageView.frame.size.height);
        NSLog(@"\n\n");
    }
    if(gesture.state == UIGestureRecognizerStateChanged){
        _removeImageView.frame = CGRectMake(location2.x - moveRangeValueX +_trimmerView.frame.size.width/2, location2.y - moveRangeValueY, _removecurrentImageView.frame.size.width, _removecurrentImageView.frame.size.height);
        if(_removeImageView.center.y<=_deletedRemoveImageView.center.y){
            _deletedRemoveImageView.backgroundColor = UIColorFromRGB(0xb60000);
            _deletedRemoveImageView.image = [RDHelpClass imageWithContentOfFile:@"剪辑-删除2_"];
            _deletedRemovePromptView.text = RDLocalizedString(@"松开删除", nil);
        }else{
            _deletedRemoveImageView.backgroundColor = [UIColor redColor];
            _deletedRemoveImageView.image = [RDHelpClass imageWithContentOfFile:@"剪辑-删除1_"];
            _deletedRemovePromptView.text = RDLocalizedString(@"拖拽到垃圾箱中删除", nil);
        }
    }
    if(gesture.state == UIGestureRecognizerStateEnded){
        NSMutableArray *childs = [_trimmerView getTimesFor_videoRangeView];

        
        _deletedRemoveImageView.hidden = YES;
        _backView.hidden = YES;
        _deletedRemoveImageView.backgroundColor = [UIColor redColor];
        _deletedRemoveImageView.image = [RDHelpClass imageWithContentOfFile:@"剪辑-删除1_"];
        _deletedRemovePromptView.text = RDLocalizedString(@"拖拽到垃圾箱中删除", nil);
        if(childs.count<2){
            _removeImageView.hidden = YES;
            [_removeImageView removeFromSuperview];
            _removecurrentImageView.hidden = NO;
            _removeImageView = nil;
            _removecurrentImageView = nil;
            _startRemove = NO;
            [_hud setCaption:RDLocalizedString(@"最少保留一段视频!", nil)];
            [_hud show];
            [_hud hideAfter:2];
            
            return;
        }
        if(_removeImageView.center.y<=_deletedRemoveImageView.center.y){
            
            _startRemove = NO;
            float width = 0;
            
            for (UIImageView *rangeView in _trimmerView.videoRangeView.subviews) {
                if(rangeView.frame.origin.x>_removecurrentImageView.frame.origin.x){
                    rangeView.frame = CGRectMake(rangeView.frame.origin.x - _removecurrentImageView.frame.size.width-10, 0, rangeView.frame.size.width, rangeView.frame.size.height);
                }
            }
            _removeImageView.hidden = YES;
            [_removeImageView removeFromSuperview];
            [_removecurrentImageView removeFromSuperview];
            _removeImageView = nil;
            _startRemove = NO;
            
            for (UIImageView *rangeView in _trimmerView.videoRangeView.subviews) {
                width = width + CGRectGetWidth(rangeView.frame)+10;
            }
            CGRect rect2 = _trimmerView.contentView.frame;
            

            _trimmerView.contentView.frame = CGRectMake(rect2.origin.x, rect2.origin.y, rect2.size.width - currentViewWidth - 10, rect2.size.height);
            _removecurrentImageView = nil;

            [_videoCoreSDK seekToTime:kCMTimeZero];
            [_comminutePlayButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
            [_trimmerView setProgress:0 animated:NO];

            [self refreshPlayer:NO];
        }else{
            _removeImageView.hidden = YES;
            [_removeImageView removeFromSuperview];
            _removecurrentImageView.hidden = NO;
            _removeImageView = nil;
            _removecurrentImageView = nil;
            _startRemove = NO;
        }
        
    }
    if(gesture.state == UIGestureRecognizerStateCancelled){
        
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(_comminuteThumbPromptBackView){
        _comminuteThumbPromptBackView.hidden = YES;
    }
    if(_comminuteThumbPromptBackView1){
        _comminuteThumbPromptBackView1.hidden = YES;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)realseCore{
    if( !_isCore && _videoCoreSDK){
        [_videoCoreSDK stop];
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK.delegate = nil;
        _videoCoreSDK = nil;
    }
    if(_thumbVideoCore){
        [_thumbVideoCore stop];
        _thumbVideoCore = nil;
    }
    
    [_trimmerView cancelLoadThumb];
    _trimmerView.delegate = nil;
    _trimmerView = nil;
    
    
}
- (void)dealloc{
    NSLog(@"%s",__func__);
    [self realseCore];
    
}


@end
