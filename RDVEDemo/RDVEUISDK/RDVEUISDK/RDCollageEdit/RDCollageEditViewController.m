//
//  RDCollageEditViewController.m
//  RDVEUISDK
//
//  Created by apple on 2017/9/6.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCollageEditViewController.h"
#import "RDCustomSizeLayout.h"
#import "RDTemplateCollectionViewCell.h"
#import "RDNavigationViewController.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDFile.h"
#import "ProgressBar.h"
#import "RDMBProgressHUD.h"
#import "RDZSlider.h"
#import "RDMainViewController.h"
#import "RDTrimVideoViewController.h"
#import "CropViewController.h"
#import "RDNextEditVideoViewController.h"
#define KMAXVIDEODURATION 60
#define kEXPORTBITRATE 5

@interface RDCollageEditViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, RDTemplateCollectionViewCellDelegate, RDCameraManagerDelegate, RDVECoreDelegate, UIAlertViewDelegate, RDMBProgressHUDDelegate>
{    
    UILabel                     * titleLbl;
    UIButton                    * backBtn;
    UIButton                    * nextBtn;
    
    RDATMHud                    * hud;
    RDCustomSizeLayout          * templateLayout;
    UICollectionView            * templateCollectionView;
    
    float                         bottomHeight;
    CGSize                        exportSize;
    int                           exportBitrate;
    float                         maxVideoDuration;
    NSMutableArray    <RDFile *>* videoFileList;
    RDFile                      * selectedVideoFile;
    RDFile                      * oldVideoFile;
    NSInteger                     selectedVideoIndex;
    
    UIButton                    * playBtn;
    UIScrollView                * toolBarView;
    
    //录制
    ProgressBar                 * recordProgressBar;
    UIButton                    * recordBtn;
    BOOL                          isRecording;
    BOOL                          isMerging;
    float                         currentRecordDuration;
    float                         _allRecordDuration;
    RDMBProgressHUD             * progressHud;
    UIButton                    * cameraZoomInBtn;
    NSMutableArray <RDCameraFile *>* recordFileList;
    NSString                    * recordStyle;
    
    //编辑
    UIView                      * editBottomView;
}

@property (nonatomic, strong) NSArray<NSString *> * filtersName;
@property (nonatomic, strong) UIView *cameraView;
@property (nonatomic, strong) RDCameraManager *cameraManager;
@property (nonatomic, strong) RDVECore *videoCoreSDK;
@property (nonatomic, strong) RDZSlider *videoProgressSlider;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic       )  UIAlertView *commonAlertView;

@end

@implementation RDCollageEditViewController

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [hud releaseHud];
    hud = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setHidesBackButton:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:hud.view];
    
    if (!_videoCoreSDK) {
        [self.view insertSubview:self.videoCoreSDK.view atIndex:0];
    }    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshVideoCoreSDK:NO];
}

- (void) notification: (NSNotification*) notification{
    if([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        [self playVideo:NO];
        
        if(progressHud){
            if (isMerging) {
                isMerging = NO;
                [_cameraManager cancelMerge];
            }else {
                [_videoCoreSDK cancelExportMovie:^{
                    [progressHud hide:NO];
                }];
            }
        }
        if (isRecording) {
            [self tap:nil];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    // Do any additional setup after loading the view.
    
    [self setupValue];
    [self.view addSubview:self.videoCoreSDK.view];
    [self.view addSubview:self.cameraView];
    [self initTitleView];
    [self initTemplateCollectionView];
    [self initVideoProgressSlider];
    [self initRecordBtn];
    [self initEditBottomView];
}

#pragma mark - 初始化
- (void)setupValue {
    videoFileList = [NSMutableArray arrayWithCapacity:_selectedTemplateIndex];
    for (int i = 0; i < _selectedTemplateIndex; i++) {
        RDFile *videoFile = [RDFile new];
        videoFile.fileType = kFILEVIDEO;
        videoFile.videoVolume = 1.0;
        videoFile.speed = 1.0;
        videoFile.speedIndex = 2;
        videoFile.fileCropModeType = kCropTypeFixed;
        [videoFileList addObject:videoFile];
    }
    exportSize = CGSizeMake(480, 480);
    exportBitrate = kEXPORTBITRATE;
    maxVideoDuration = KMAXVIDEODURATION;
    bottomHeight = MAX(kHEIGHT - 44 - kWIDTH, 110);
    
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake((kWIDTH - 68)/2.0, kHEIGHT - bottomHeight + (bottomHeight - 68)/2.0, 68, 68);
    playBtn.backgroundColor = [UIColor clearColor];
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    playBtn.tag = 11;
    [self.view addSubview:playBtn];
}

- (void)initTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
    [self.view addSubview:titleView];
    
    titleLbl = [UILabel new];
    titleLbl.frame = CGRectMake(0, 0, kWIDTH, 44);
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [titleView addSubview:titleLbl];
    
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(5, 0, 44, 44);
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nextBtn.frame = CGRectMake(kWIDTH - 67, 0, 60, 44);
    nextBtn.backgroundColor = [UIColor clearColor];
    [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
    [nextBtn setTitleColor:UIColorFromRGB(Main_Color) forState:UIControlStateNormal];
    nextBtn.titleLabel.textAlignment = NSTextAlignmentRight;
    nextBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:nextBtn];
}

- (void)initTemplateCollectionView {
    templateLayout = [[RDCustomSizeLayout alloc] init];
    templateLayout.templateIndex = _selectedTemplateIndex;
    
    templateCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 44, kWIDTH, kHEIGHT - 44 - bottomHeight) collectionViewLayout:templateLayout];
    templateCollectionView.backgroundColor = [UIColor clearColor];
    templateCollectionView.layer.masksToBounds = YES;
    [templateCollectionView registerClass:[RDTemplateCollectionViewCell class] forCellWithReuseIdentifier:@"TemplateCollectionViewCell"];
    templateCollectionView.showsHorizontalScrollIndicator = NO;
    templateCollectionView.dataSource = self;
    templateCollectionView.delegate = self;
    templateCollectionView.tag = 1;
    [self.view addSubview:templateCollectionView];
}

- (void)initRecordBtn {
    recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    recordBtn.frame = CGRectMake((kWIDTH - 70)/2.0, 44 + kWIDTH + (bottomHeight - 70)/2.0, 70, 70);
    [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
    
    UILongPressGestureRecognizer* longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    longpressGesture.minimumPressDuration = 0.2;
    [recordBtn addGestureRecognizer:longpressGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [recordBtn addGestureRecognizer:tapGesture];
    recordBtn.hidden = YES;
    [self.view addSubview:recordBtn];
    
    cameraZoomInBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraZoomInBtn.backgroundColor = [UIColor clearColor];
    cameraZoomInBtn.frame = CGRectMake(kWIDTH - 40 - 10, kHEIGHT - bottomHeight - 40 - 10, 40, 40);
    [cameraZoomInBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/拍摄-小屏默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [cameraZoomInBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/拍摄-小屏点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    [cameraZoomInBtn addTarget:self action:@selector(cameraZoomInBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    cameraZoomInBtn.hidden = YES;
    [self.view addSubview:cameraZoomInBtn];
}

- (void)initEditBottomView {
    editBottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - (iPhone4s ? 55 : 60), kWIDTH, (iPhone4s ? 55 : 60))];
    editBottomView.backgroundColor = UIColorFromRGB(NV_Color);
    editBottomView.hidden = YES;
    [self.view addSubview:editBottomView];
    
    float btnWidth = kWIDTH/2.0;
    UIButton *trimBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    trimBtn.frame = CGRectMake(0, 0, btnWidth, 60);
    trimBtn.backgroundColor = [UIColor clearColor];
    [trimBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑截取点击默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [trimBtn setTitle:RDLocalizedString(@"截取", nil) forState:UIControlStateNormal];
    [trimBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [trimBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [trimBtn setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.3] forState:UIControlStateNormal];
    [trimBtn setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.3] forState:UIControlStateHighlighted];
    trimBtn.titleLabel.backgroundColor = [UIColor clearColor];
    trimBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [trimBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (btnWidth - 44)/2.0, 16, (btnWidth - 44)/2.0)];
    [trimBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
    [trimBtn addTarget:self action:@selector(trimBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [editBottomView addSubview:trimBtn];
    
    UIButton *cropBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cropBtn.frame = CGRectMake(btnWidth, 0, btnWidth, 60);
    cropBtn.backgroundColor = [UIColor clearColor];
    [cropBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑编辑点击默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [cropBtn setTitle:RDLocalizedString(@"编辑", nil) forState:UIControlStateNormal];
    [cropBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cropBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [cropBtn setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.3] forState:UIControlStateNormal];
    [cropBtn setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.3] forState:UIControlStateHighlighted];
    cropBtn.titleLabel.backgroundColor = [UIColor clearColor];
    cropBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [cropBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (btnWidth - 44)/2.0, 16, (btnWidth - 44)/2.0)];
    [cropBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
    [cropBtn addTarget:self action:@selector(cropBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [editBottomView addSubview:cropBtn];
}

- (UIView *)cameraView {
    if (!_cameraView) {
        UIView *cameraView = [[UIView alloc] init];
        cameraView.frame = CGRectMake(0, 0, kHEIGHT, kWIDTH);
        cameraView.center = CGPointMake(kWIDTH/2, kHEIGHT/2);
        cameraView.backgroundColor = [UIColor clearColor];
        cameraView.transform = CGAffineTransformMakeRotation(M_PI_2);
        cameraView.hidden = YES;
        _cameraView = cameraView;;
    }
    return _cameraView;
}

#pragma mark - 编辑界面
- (RDVECore *)videoCoreSDK {
    if (!_videoCoreSDK) {
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                               videoSize:exportSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
        _videoCoreSDK.frame = CGRectMake(0, 44, kWIDTH, kWIDTH);
        _videoCoreSDK.view.backgroundColor = [UIColor clearColor];
        _videoCoreSDK.delegate = self;
    }
    return _videoCoreSDK;
}

- (void)initVideoProgressSlider {
    _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(0, 44 + kWIDTH - 15, kWIDTH, 30)];
    [_videoProgressSlider setMaximumValue:1];
    [_videoProgressSlider setMinimumValue:0];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
    [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
    [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
    [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
    [_videoProgressSlider setValue:0];
    _videoProgressSlider.alpha = 1.0;
    _videoProgressSlider.backgroundColor = [UIColor clearColor];
    [_videoProgressSlider addTarget:self action:@selector(beginScrub) forControlEvents:UIControlEventTouchDown];
    [_videoProgressSlider addTarget:self action:@selector(scrub) forControlEvents:UIControlEventValueChanged];
    [_videoProgressSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchUpInside];
    [_videoProgressSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchCancel];
    _videoProgressSlider.hidden = YES;
    [self.view addSubview:_videoProgressSlider];
    
    _durationLabel = [[UILabel alloc] init];
    _durationLabel.frame = CGRectMake(kWIDTH - 130, 44 + kWIDTH - 30, 120, 20);
    _durationLabel.textAlignment = NSTextAlignmentRight;
    _durationLabel.textColor = UIColorFromRGB(0xffffff);
    _durationLabel.font = [UIFont systemFontOfSize:12];
    _durationLabel.hidden = YES;
    [self.view addSubview:_durationLabel];
    
    recordProgressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 5)];
    recordProgressBar.hidden = YES;
    [self.view addSubview:recordProgressBar];
}

#pragma mark - 按钮事件
- (void)backBtnAction:(UIButton *)sender {
    if (!recordBtn.hidden) {
        if (recordFileList.count > 0) {
            [self initCommonAlertViewWithTitle:nil
                                       message:RDLocalizedString(@"是否放弃当前录制？", nil)
                             cancelButtonTitle:RDLocalizedString(@"取消", nil)
                             otherButtonTitles:RDLocalizedString(@"确定", nil)
                                  alertViewTag:1];
        }else {
            [_cameraManager stopCamera];
            playBtn.hidden = NO;
            templateCollectionView.hidden = NO;
            if (maxVideoDuration == 0.0) {
                _videoProgressSlider.hidden = YES;
                _durationLabel.hidden = YES;
            }else {
                _videoProgressSlider.hidden = NO;
                _durationLabel.hidden = NO;
            }
            recordBtn.hidden = YES;
            cameraZoomInBtn.hidden = YES;
            _cameraView.hidden = YES;
            recordProgressBar.hidden = YES;
            [videoFileList replaceObjectAtIndex:selectedVideoIndex withObject:oldVideoFile];
            [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
            
            RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
            cell.zoomBtn.hidden = YES;
            cell.editBtn.hidden = YES;
            cell.deleteBtn.hidden = YES;
            cell.recordBtn.hidden = NO;
            cell.addLocalVideoBtn.hidden = NO;
        }
    }
    else if (!editBottomView.hidden) {
        [self initCommonAlertViewWithTitle:nil
                                   message:RDLocalizedString(@"是否放弃编辑？", nil)
                         cancelButtonTitle:RDLocalizedString(@"否", nil)
                         otherButtonTitles:RDLocalizedString(@"是", nil)
                              alertViewTag:2];
    }
    else {
        [self initCommonAlertViewWithTitle:nil
                                   message:RDLocalizedString(@"是否放弃编辑？", nil)
                         cancelButtonTitle:RDLocalizedString(@"否", nil)
                         otherButtonTitles:RDLocalizedString(@"是", nil)
                              alertViewTag:3];
    }
}

- (void)nextBtnAction:(UIButton *)sender {
    if (!recordBtn.hidden) {//录制完成
        
        
        
        
        [self recordFinish];
    }
    else if (!editBottomView.hidden) {//编辑完成
        titleLbl.text = @"";
        [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
        editBottomView.hidden = YES;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden = NO;
        
        RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
        cell.editBtn.hidden = NO;
        cell.deleteBtn.hidden = YES;
    }
    else {
        [self playVideo:NO];
        [self exportVideo];
    }
}

- (void)playBtnAction:(UIButton *)sender {
    if([_videoCoreSDK isPlaying]){
        [_videoCoreSDK pause];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }else {
        [_videoCoreSDK play];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }
}

- (void)cameraZoomInBtnAction:(UIButton *)sender {
    CGRect frame = [[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue];
    float width = templateCollectionView.frame.size.width;
    float height = templateCollectionView.frame.size.height;
    CGRect cameraFrame = CGRectMake(frame.origin.x*width, 44 + frame.origin.y*height, frame.size.width*width, frame.size.height*height);
    _cameraView.frame = cameraFrame;
    [_cameraManager setVideoViewFrame:CGRectMake(0, 0, cameraFrame.size.height, cameraFrame.size.width)];
    recordProgressBar.frame = CGRectMake(cameraFrame.origin.x, cameraFrame.origin.y + cameraFrame.size.height - 5, cameraFrame.size.width, 5);
    [sender setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/bianji/拍摄-全屏默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    sender.hidden = YES;
    templateCollectionView.hidden = NO;
}

- (void)initProgressHUD:(NSString *)message isShowCancelBtn:(BOOL)isShowCancelBtn{
    if (progressHud) {
        progressHud.delegate = nil;
        progressHud = nil;
    }
    //圆形进度条
    progressHud = [[RDMBProgressHUD alloc] initWithView:self.navigationController.view];
    progressHud.backgroundColor = [UIColorFromRGB(0x000000) colorWithAlphaComponent:0.6];
    [self.navigationController.view addSubview:progressHud];
    progressHud.removeFromSuperViewOnHide = YES;
    progressHud.mode = RDMBProgressHUDModeDeterminate;
    progressHud.animationType = RDMBProgressHUDAnimationFade;
    progressHud.labelText = message;
    progressHud.isShowCancelBtn = isShowCancelBtn;
    progressHud.delegate = self;
    [progressHud show:YES];
}

- (void)exportVideo {
    [_videoCoreSDK stop];
    
    [self initProgressHUD:RDLocalizedString(@"视频导出中，请稍候...", nil) isShowCancelBtn:YES];
    
    NSString *exportVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/publishMultiVideoFile.mp4"];
    unlink([exportVideoPath UTF8String]);
    NSURL *outputURL = [NSURL fileURLWithPath:exportVideoPath];
    __weak typeof(self) weakSelf = self;
    [_videoCoreSDK exportMovieURL:outputURL
                             size:exportSize
                          bitrate:exportBitrate
                              fps:kEXPORTFPS
                     audioBitRate:0
              audioChannelNumbers:2
           maxExportVideoDuration:0.0
                         progress:^(float progress) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [progressHud setProgress:progress];
                             });
                         }
                          success:^{
                              NSLog(@"duration:%f", CMTimeGetSeconds(((AVURLAsset *)[AVURLAsset assetWithURL:outputURL]).duration));
                              NSLog(@"export success");
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  
                                  [weakSelf exportMovieSuc:outputURL];
                              });
                          }
                             fail:^(NSError *error) {
                                 NSLog(@"export failed");
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     
                                     [weakSelf exportMovieFail];
                                 });
                             }];
}

- (void)exportMovieSuc:(NSURL *)exportUrl{
    NSLog(@"导出成功");
    [progressHud hide:NO];
    progressHud = nil;
    [self clearVideoCoreSDK];
    
    RDFile *videoFile = [RDFile new];
    videoFile.contentURL = exportUrl;
    videoFile.fileType = kFILEVIDEO;
    videoFile.videoVolume = 1.0;
    videoFile.speed = 1.0;
    videoFile.speedIndex = 2;
    videoFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero, [AVAsset assetWithURL:exportUrl].duration);
    videoFile.videoDurationTime = videoFile.videoTimeRange.duration;
    
    RDNextEditVideoViewController *nextEditVideoVC = [[RDNextEditVideoViewController alloc] init];
    nextEditVideoVC.fileList = [NSMutableArray arrayWithObject:videoFile];
    nextEditVideoVC.exportVideoSize = exportSize;    
    nextEditVideoVC.cancelActionBlock = ^{
        [_videoCoreSDK prepare];
    };
    [self.navigationController pushViewController:nextEditVideoVC animated:YES];
}

- (void)exportMovieFail{
    NSLog(@"导出失败");
    [progressHud hide:NO];
    progressHud = nil;
    [_videoCoreSDK prepare];
    [hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"导出错误，请重试", nil)]];
    [hud show];
    [hud hideAfter:2];
}

- (void)clearVideoCoreSDK {
    [_videoCoreSDK.view removeFromSuperview];
    [_videoCoreSDK stop];
    _videoCoreSDK = nil;
}

#pragma mark - RDMBProgressHUDDelegate
- (void)cancelDownLoad {
    [self initCommonAlertViewWithTitle:nil
                               message:RDLocalizedString(@"确定取消导出？", nil)
                     cancelButtonTitle:RDLocalizedString(@"取消", nil)
                     otherButtonTitles:RDLocalizedString(@"确定", nil)
                          alertViewTag:5];
}

#pragma mark - 编辑
- (void)playVideo:(BOOL)isplay {
    if(!isplay){
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }else{
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }
}

- (void)refreshVideoCoreSDK:(BOOL)isPlay {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    maxVideoDuration = 0.0;
    RDScene *scene = [[RDScene alloc] init];
    
    for (RDFile *videoFile in videoFileList) {
        if (!videoFile.contentURL) {
            continue;
        }
        CMTimeRange videoTimeRange = kCMTimeRangeZero;
        if (CMTimeRangeEqual(videoFile.videoTrimTimeRange, kCMTimeRangeInvalid)
            || CMTimeRangeEqual(videoFile.videoTrimTimeRange, kCMTimeRangeZero))
        {
            videoTimeRange = videoFile.videoTimeRange;
        }else {
            videoTimeRange = videoFile.videoTrimTimeRange;
        }
        float duration = CMTimeGetSeconds(videoTimeRange.duration);
        if (duration > maxVideoDuration) {
            maxVideoDuration = duration;
        }
        NSLog(@"vvAsset_video start:%@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoFile.videoTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, videoFile.videoTimeRange.duration)));
    }
    [_videoProgressSlider setValue:0];
    if (maxVideoDuration == 0.0) {
        maxVideoDuration = 60.0;
        _videoProgressSlider.hidden = YES;
        _durationLabel.hidden = YES;
    }else {
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden = NO;
    }
    //如需要输出边框，需将边框image作为媒体加入到场景中
    if (_selectedTemplateIndex != 1) {
        NSString *imagePath =  [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/collage/画框480-%zd", _selectedTemplateIndex] Type:@"png"];

        VVAsset* vvAsset_template = [[VVAsset alloc] init];
        vvAsset_template.url = [NSURL fileURLWithPath:imagePath];
        vvAsset_template.type = RDAssetTypeImage;
        vvAsset_template.volume = 0.0;
        vvAsset_template.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(maxVideoDuration, NSEC_PER_SEC));
        vvAsset_template.fillType = RDImageFillTypeFull;//画框必须设置为RDImageFillTypeFull
        [scene.vvAsset addObject:vvAsset_template];
    }
    for (int i = 0; i < videoFileList.count; i++) {
        RDFile *videoFile = [videoFileList objectAtIndex:i];
        NSURL *url = videoFile.contentURL;
        VVAsset* vvAsset = [[VVAsset alloc] init];
        
        if (!url) {
            continue;
        }
        vvAsset.url = url;
        vvAsset.type = RDAssetTypeVideo;
        vvAsset.volume = videoFile.videoVolume;
        if (CMTimeRangeEqual(videoFile.videoTrimTimeRange, kCMTimeRangeInvalid)
            || CMTimeRangeEqual(videoFile.videoTrimTimeRange, kCMTimeRangeZero))
        {
            vvAsset.timeRange = videoFile.videoTimeRange;
        }else {
            vvAsset.timeRange = videoFile.videoTrimTimeRange;
        }
        vvAsset.rectInVideo = [[_videosFrameArray objectAtIndex:i] CGRectValue];
        vvAsset.crop = videoFile.crop;
        vvAsset.isVerticalMirror = videoFile.isVerticalMirror;
        vvAsset.isHorizontalMirror = videoFile.isHorizontalMirror;
        vvAsset.rotate = videoFile.rotate;
        
//        if (i%2==0) {
//            vvAsset.filterType = VVAssetFilterACV;
//            vvAsset.filterPath = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"流年" Type:@"acv"]];
//        }else{
//            vvAsset.filterType = VVAssetFilterLookup;
//            vvAsset.filterPath = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"lookup_amatorka" Type:@"png"]];
//        }
        
        [scene.vvAsset addObject:vvAsset];
        
        
//        //根据项目需要，可将一个场景中时间短的媒体，补上最后一帧或其它媒体
//        float duration = CMTimeGetSeconds(vvAsset.timeRange.duration);
//        if (duration < maxVideoDuration) {
//            if (![[NSFileManager defaultManager] fileExistsAtPath:videoFile.lastFrameURL.path]) {
//                UIImage *lastFrameImage = [RDHelpClass getLastScreenShotImageFromVideoURL:url];
//                videoFile.lastFrameURL = [RDHelpClass saveImage:url image:lastFrameImage];
//            }
//            
//            VVAsset* vvAsset_lastFrame = [[VVAsset alloc] init];
//            vvAsset_lastFrame.url = videoFile.lastFrameURL;
//            vvAsset_lastFrame.type = RDAssetTypeImage;
//            vvAsset_lastFrame.volume = vvAsset.volume;
//            vvAsset_lastFrame.startTimeInScene = vvAsset.timeRange.duration;
//            vvAsset_lastFrame.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(CMTimeMakeWithSeconds(maxVideoDuration, NSEC_PER_SEC), vvAsset.timeRange.duration));
//            vvAsset_lastFrame.rectInVideo = vvAsset.rectInVideo;
//            vvAsset_lastFrame.crop = vvAsset.crop;
//            vvAsset_lastFrame.isVerticalMirror = vvAsset.isVerticalMirror;
//            vvAsset_lastFrame.isHorizontalMirror = vvAsset.isHorizontalMirror;
//            vvAsset_lastFrame.rotate = vvAsset.rotate;
//            vvAsset_lastFrame.fillType = RDImageFillTypeFit;
//            if (CMTimeCompare(vvAsset_lastFrame.timeRange.duration, kCMTimeZero) == 1) {
//                [scene.vvAsset addObject:vvAsset_lastFrame];
//                
//                NSLog(@"vvAsset_lastFrame%zd start:%@  duration:%@", i, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, vvAsset_lastFrame.startTimeInScene)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, vvAsset_lastFrame.timeRange.duration)));
//            }
//        }
    }
    NSLog(@"_maxVideoDuration:%f", maxVideoDuration);
    [_videoCoreSDK setScenes:[NSMutableArray arrayWithObject:scene]];
    [_videoCoreSDK build];
    [RDSVProgressHUD dismissWithDelay:0.1];
    if (isPlay) {
        [self playVideo:YES];
    }
}

- (CGRect)getCropFrame:(AVURLAsset *)asset rectInVideo:(CGRect)rectInVideo {
    
    BOOL isPortrait = [RDHelpClass isVideoPortrait:asset];
    CGSize videoSize = [RDHelpClass getVideoSizeForTrack:asset];
    
    CGSize frameInViewSize = CGSizeMake(rectInVideo.size.width*templateCollectionView.frame.size.width, rectInVideo.size.height*templateCollectionView.frame.size.height);
    
    CGRect cropRect = CGRectZero;
    CGRect crop = CGRectZero;
    
    if (isPortrait) {
        float ratiow = frameInViewSize.width/frameInViewSize.height;
        float ratioh = frameInViewSize.height/frameInViewSize.width;
        if (ratiow <= 1.0) {
            cropRect = CGRectMake((videoSize.width - videoSize.height*ratiow)/2.0, 0, videoSize.height*ratiow, videoSize.height);
            
            if (cropRect.size.width > videoSize.width) {
                cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
                crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
            }else {
                crop = CGRectMake(cropRect.origin.x/videoSize.width, 0, cropRect.size.width/videoSize.width, 1.0);
            }
        }else {
            cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
            crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
        }
    }else {
        float ratiow = frameInViewSize.width/frameInViewSize.height;
        float ratioh = frameInViewSize.height/frameInViewSize.width;
        cropRect = CGRectMake((videoSize.width - videoSize.height*ratiow)/2.0, (videoSize.height - videoSize.height)/2.0, videoSize.height*ratiow, videoSize.height);
        
        if (cropRect.size.width > videoSize.width) {
            cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
            crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
        }else {
            crop = CGRectMake(cropRect.origin.x/videoSize.width, 0, cropRect.size.width/videoSize.width, 1.0);
        }
    }
    NSLog(@"videoSize:%@", NSStringFromCGSize(videoSize));
    NSLog(@"cropRect:%@", NSStringFromCGRect(cropRect));
    NSLog(@"crop:%@", NSStringFromCGRect(crop));
    return crop;
}

- (void)trimBtnAction:(UIButton *)sender {
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
    
    trimVideoVC.trimFile = [selectedVideoFile copy];
    trimVideoVC.editVideoSize = exportSize;
    trimVideoVC.TrimVideoFinishBlock = ^(CMTimeRange timeRange) {
        if(selectedVideoFile.isReverse){
            selectedVideoFile.reverseVideoTrimTimeRange = timeRange;
        }else{
            selectedVideoFile.videoTrimTimeRange = timeRange;
        }
        NSLog(@"%lf : %lf",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
    };
    
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    [self setNavConfig:nav];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cropBtnAction:(UIButton *)sender {
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    CropViewController *cropVC = [[CropViewController alloc] init];
    cropVC.selectFile = [selectedVideoFile copy];
    CGRect rectInVideo = [[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue];
    cropVC.videoInViewSize = CGSizeMake(rectInVideo.size.width*templateCollectionView.frame.size.width, rectInVideo.size.height*templateCollectionView.frame.size.height);
    cropVC.editVideoForOnceFinishAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
        selectedVideoFile.crop = crop;
        selectedVideoFile.cropRect = cropRect;
        selectedVideoFile.isVerticalMirror = verticalMirror;
        selectedVideoFile.isHorizontalMirror = horizontalMirror;
        selectedVideoFile.rotate = rotate;
    };
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
    [self setNavConfig:nav];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark- RDVECoreDelegate

- (void)playerItemStatues:(AVPlayerItemStatus)statues{
    NSLog(@"AVPlayerItemStatus:%zd",statues);
}

/**当前播放时间
 */
- (void)progressCurrentTime:(CMTime)currentTime{
    [_videoProgressSlider setValue:(CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration)];
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@",[RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)],[RDHelpClass timeToStringFormat:_videoCoreSDK.duration]];
}
/**播放结束
 */
- (void)playToEnd{
    [_videoCoreSDK seekToTime:kCMTimeZero];
    [_videoProgressSlider setValue:0];
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
}

#pragma mark - 录制
- (RDCameraManager *)cameraManager {
    if (!_cameraManager) {
        RDCameraManager *cameraManager = [[RDCameraManager alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                                       APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                                      resultFail:^(NSError *error) {
                                                                          NSLog(@"initError:%@", error.localizedDescription);
                                                                      }];
        [cameraManager prepareRecordWithFrame:CGRectZero
                                    superview:_cameraView
                                      bitrate:2.5 *1000*1000
                                          fps:kEXPORTFPS
                                         mode:NO
                                  cameraSize:CGSizeMake(720,720)
                                   outputSize:CGSizeMake(480,480)
                                      isFront:NO
                                        faceU:NO
                                 captureAsYUV:YES
                             disableTakePhoto:NO
                        enableCameraWaterMark:NO];
        [cameraManager setfocus];
        cameraManager.delegate = self;
        cameraManager.beautifyState = BeautifyStateSeleted;
        cameraManager.fillMode = kRDCameraFillModeScaleAspectFill;
        _cameraManager = cameraManager;
    }
    return _cameraManager;
}

- (void) tap:(UITapGestureRecognizer *)gesture{
    
    if (!(currentRecordDuration == 0.0 || currentRecordDuration > 1.0) || _allRecordDuration >= maxVideoDuration) {
        return;
    }
    
    if(gesture.state == UIGestureRecognizerStateBegan){
        [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
    }
    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed){
        [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
    }

    if (_allRecordDuration < maxVideoDuration) {
        if (!isRecording) {
            if ([_cameraManager assetWriterStatus] == 1) {
                return;
            }
            recordStyle = @"tap";
            [self startRecording];
        }else {
            [self stopRecording];
        }
    }
}

- (void) longPressAction: (UILongPressGestureRecognizer *) recognizer{

    if (!(currentRecordDuration == 0.0 || currentRecordDuration > 1.0) || _allRecordDuration >= maxVideoDuration) {
        return;
    }
    
    if(recognizer.state == UIGestureRecognizerStateBegan){
        [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
    }
    if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed){
        [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
    }    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        if ([_cameraManager assetWriterStatus] == 1) {
            return;
        }
        recordStyle = @"longpress";
        
        [self startRecording];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSLog(@"松开录制按钮");
        [self stopRecording];
    }
}

- (double)totalRecordDuration{
    float duration = 0;
    for (RDCameraFile *file in recordFileList) {
        duration += file.duration;
    }
    return duration;
}

- (void)startRecording{
    NSLog(@"%s", __func__);
    recordBtn.userInteractionEnabled = YES;
    
    if(isRecording){
        return;
    }
    _allRecordDuration = [self totalRecordDuration];
    backBtn.hidden = YES;
    nextBtn.enabled = NO;

    currentRecordDuration = 0.0;
    [recordProgressBar addProgressView];
    [recordProgressBar stopShining];
    
    if ([recordProgressBar getProgressIndicatorHiddenState]) {
        [recordProgressBar setAllProgressToNormal];
    }
    
    [[self cameraManager] beginRecording];
}

- (void)stopRecording{
    
    [[self cameraManager] stopRecording];
    [recordProgressBar startShining];
    
    recordBtn.selected = NO;
    backBtn.hidden = NO;
    nextBtn.enabled = YES;
}

- (void)recordWatcher {
    [recordProgressBar setLastProgressToWidth:(currentRecordDuration * (recordProgressBar.frame.size.width/maxVideoDuration))];
    
    if (currentRecordDuration + _allRecordDuration - 1.0/kEXPORTFPS >= maxVideoDuration) {
        [self stopRecording];
        recordBtn.enabled = NO;
    }
}

#pragma mark - RDCameraManagerDelegate
- (void)currentTime:(float)time {
    if (isRecording) {
        currentRecordDuration = time;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self recordWatcher];
        });
    }
}

- (void)movieRecordCancel {
    isRecording = NO;
    [UIView animateWithDuration:0.2 animations:^{
        
        if (recordBtn.selected) {//倒计时拍摄
            [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateSelected];
        }else {
            [recordBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
        }
    }];
    
    recordBtn.selected = NO;
    backBtn.hidden = NO;
    nextBtn.enabled = YES;
}

- (void)movieRecordBegin {
    isRecording = YES;
}

- (void)movieRecordingCompletion:(NSURL *)videoUrl {
    isRecording = NO;
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoUrl];
    if (currentRecordDuration == 0.0 && CMTimeCompare(kCMTimeZero, asset.duration) == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [recordProgressBar deleteLastProgress];
        });
        return;
    }
    RDCameraFile *cameraFile = [RDCameraFile new];
    cameraFile.fileName = [[videoUrl absoluteString] lastPathComponent];
    cameraFile.duration = CMTimeGetSeconds(CMTimeSubtract(asset.duration, CMTimeMake(1, kEXPORTFPS)));//为防止第一帧是黑帧
    cameraFile.speed    = 1.0;
    
    NSLog(@"currentRecordDuration:%f", currentRecordDuration);
    NSLog(@"videoDuration:%f %@", cameraFile.duration, videoUrl.lastPathComponent);
    
    [recordFileList addObject:cameraFile];
    
    _allRecordDuration = [self totalRecordDuration];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"totalDuration:%f maxVideoDuration:%f",_allRecordDuration,maxVideoDuration);
        if(_allRecordDuration>=maxVideoDuration){
            [self recordFinish];
        }else {
            recordBtn.enabled = YES;
        }
    });
}

- (void)recordFinish {
    playBtn.hidden = NO;
    if(isRecording){
        [self stopRecording];
        while (isRecording) {
            usleep(200000);
        }
    }
    [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
    cameraZoomInBtn.hidden = YES;
    templateCollectionView.hidden = NO;
    recordBtn.hidden = YES;
    [_cameraManager stopCamera];
    _cameraView.hidden = YES;
    recordProgressBar.hidden = YES;
    [recordProgressBar deleteAllProgress];
    _videoProgressSlider.hidden = NO;
    _durationLabel.hidden = NO;
    if(_allRecordDuration == 0){
        RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
        cell.deleteBtn.hidden = YES;
        cell.editBtn.hidden = YES;
        cell.recordBtn.hidden = NO;
        cell.addLocalVideoBtn.hidden = NO;
        cell.zoomBtn.hidden= YES;
        [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
        editBottomView.hidden = YES;
        return;
    }
    if(recordFileList.count == 1)
    {
        NSString *filePath = [[[self cameraManager] getVideoSaveFileFolderString] stringByAppendingString:[NSString stringWithFormat:@"/%@",[recordFileList firstObject].fileName]];
        NSURL *videoUrl = [NSURL fileURLWithPath:filePath];
        
        AVURLAsset * asset = [AVURLAsset assetWithURL:videoUrl];
        selectedVideoFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        selectedVideoFile.videoDurationTime = selectedVideoFile.videoTimeRange.duration;
        selectedVideoFile.contentURL = videoUrl;
        selectedVideoFile.crop = [self getCropFrame:asset rectInVideo:[[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue]];
        
        [self refreshVideoCoreSDK:NO];
        
        RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
        cell.zoomBtn.hidden = YES;
        cell.editBtn.hidden = NO;
        cell.deleteBtn.hidden = YES;
    }else{
        [self initProgressHUD:RDLocalizedString(@"视频合并中，请稍候...", nil) isShowCancelBtn:NO];
        NSLog(@"开始合并");
        isMerging = YES;
        __block double currentMediaTime = CFAbsoluteTimeGetCurrent();
        __weak typeof(self) weakSelf = self;
        [_cameraManager mergeAndExportVideosAtFileURLs:recordFileList progress:^(NSNumber *progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressHud setProgress:[progress floatValue]];
            });
        } finish:^(NSURL *videourl) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"合并结束 耗时：%lf:%@",CFAbsoluteTimeGetCurrent() - currentMediaTime,videourl);
                isMerging = NO;
                [progressHud hide:NO];
                progressHud = nil;
                AVURLAsset * asset = [AVURLAsset assetWithURL:videourl];
                selectedVideoFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
                selectedVideoFile.videoDurationTime = selectedVideoFile.videoTimeRange.duration;
                selectedVideoFile.contentURL = videourl;
                selectedVideoFile.crop = [self getCropFrame:[AVURLAsset assetWithURL:selectedVideoFile.contentURL] rectInVideo:[[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue]];
                
                [weakSelf refreshVideoCoreSDK:NO];
                
                RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
                cell.zoomBtn.hidden = YES;
                cell.editBtn.hidden = NO;
                cell.deleteBtn.hidden = YES;
            });
            
        } fail:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"fail:%@",error);
                isMerging = NO;
                [progressHud hide:NO];
                progressHud = nil;
            });
        } cancel:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"取消合并");
                isMerging = NO;
                [progressHud hide:NO];
                progressHud = nil;
            });
        }];
    }
}

#pragma mark - 滑动进度条
- (void)beginScrub{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
}

- (void)scrub{
    CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@",[RDHelpClass timeToStringFormat:current],[RDHelpClass timeToStringFormat:_videoCoreSDK.duration]];
}

- (void)endScrub{
    CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _selectedTemplateIndex;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * CellIdentifier = @"TemplateCollectionViewCell";
    RDTemplateCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.delegate = self;
    cell.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
    
    RDFile *videoFile = (RDFile *)[videoFileList objectAtIndex:indexPath.row];
    if (videoFile.contentURL) {
        cell.recordBtn.hidden = YES;
        cell.addLocalVideoBtn.hidden = YES;
        cell.editBtn.hidden = NO;
        cell.deleteBtn.hidden = YES;
        cell.zoomBtn.hidden = YES;
    }else {
        cell.recordBtn.hidden = NO;
        cell.addLocalVideoBtn.hidden = NO;
        cell.editBtn.hidden = YES;
        cell.deleteBtn.hidden = YES;
    }
    
    return cell;
}

#pragma mark - RDTemplateCollectionViewCellDelegate
- (void)deleteVideo:(RDTemplateCollectionViewCell *)cell {
    selectedVideoIndex = [templateCollectionView indexPathForCell:cell].row;
    [self initCommonAlertViewWithTitle:nil
                               message:RDLocalizedString(@"是否删除当前视频?", nil)
                     cancelButtonTitle:RDLocalizedString(@"否", nil)
                     otherButtonTitles:RDLocalizedString(@"是", nil)
                          alertViewTag:4];
}

- (void)editVideo:(RDTemplateCollectionViewCell *)cell {
    if ([nextBtn.titleLabel.text isEqualToString:RDLocalizedString(@"完成", nil)]) {
        return;
    }
    selectedVideoIndex = [templateCollectionView indexPathForCell:cell].row;
    selectedVideoFile = [videoFileList objectAtIndex:selectedVideoIndex];
    oldVideoFile = [selectedVideoFile copy];
    [_cameraManager stopCamera];
    recordBtn.hidden = YES;
    editBottomView.hidden = NO;
    
    cell.editBtn.hidden = YES;
    cell.recordBtn.hidden = YES;
    cell.deleteBtn.hidden = NO;
    cell.zoomBtn.hidden = YES;
    
    [nextBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateNormal];
}

- (void)recordVideo:(RDTemplateCollectionViewCell *)cell {
    if ([nextBtn.titleLabel.text isEqualToString:RDLocalizedString(@"完成", nil)]) {
        return;
    }
    [self playVideo:NO];
    _videoProgressSlider.hidden = YES;
    _durationLabel.hidden = YES;
    _cameraView.hidden = NO;
    self.cameraView.frame = cell.bounds;
    recordProgressBar.frame = CGRectMake(cell.frame.origin.x, 44 + cell.frame.origin.y + cell.frame.size.height - 5, cell.frame.size.width, 5);
    recordProgressBar.hidden = NO;
    [recordProgressBar startShining];
    selectedVideoIndex = [templateCollectionView indexPathForCell:cell].row;
    [nextBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateNormal];
    selectedVideoFile = [videoFileList objectAtIndex:selectedVideoIndex];
    oldVideoFile = [selectedVideoFile copy];
    
    cell.editBtn.hidden = YES;
    cell.recordBtn.hidden = YES;
    cell.addLocalVideoBtn.hidden = YES;
    if (_selectedTemplateIndex != 1) {
        cell.zoomBtn.hidden = NO;
    }
    
    recordBtn.enabled = YES;
    recordBtn.hidden = NO;
    editBottomView.hidden = YES;
    playBtn.hidden = YES;
    CGRect frame = [[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue];
    float width = templateCollectionView.frame.size.width;
    float height = templateCollectionView.frame.size.height;
    CGRect cameraFrame = CGRectMake(frame.origin.x*width, 44 + frame.origin.y*height, frame.size.width*width, frame.size.height*height);
    _cameraView.frame = cameraFrame;
    [self.cameraManager setVideoViewFrame:CGRectMake(0, 0, cameraFrame.size.height, cameraFrame.size.width)];
    [_cameraManager startCamera];
    
    [recordFileList removeAllObjects];
    recordFileList = nil;
    recordFileList = [NSMutableArray array];
    
    currentRecordDuration = 0.0;
    _allRecordDuration = 0.0;
    
    [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, 600) completionHandler:^(BOOL finished) {
        [self playVideo:YES];
    }];
    
}

- (void)zoomRecord:(RDTemplateCollectionViewCell *)cell {
    CGRect cameraFrame = CGRectMake(0, 44, kWIDTH, kWIDTH);
    _cameraView.frame = cameraFrame;
    [_cameraManager setVideoViewFrame:CGRectMake(0, 0, cameraFrame.size.height, cameraFrame.size.width)];
    recordProgressBar.frame = CGRectMake(0, 44 + kWIDTH - 5, kWIDTH, 5);
    templateCollectionView.hidden = YES;
    cameraZoomInBtn.hidden = NO;
}

- (void)addLocalVideoVideo:(RDTemplateCollectionViewCell *)cell {
    if ([nextBtn.titleLabel.text isEqualToString:RDLocalizedString(@"完成", nil)]) {
        return;
    }
    [self playVideo:NO];
    selectedVideoIndex = [templateCollectionView indexPathForCell:cell].row;
    selectedVideoFile = [videoFileList objectAtIndex:selectedVideoIndex];
    
    __weak typeof(self) weakSelf = self;
    
    if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]){
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideoAndImageResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
            [weakSelf addFileWithList:lists templateCell:cell];
        }];
        return;
    }    
    
    
    NSString *exportVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/videos/compressEditVideoFile%zd.mp4", selectedVideoIndex]];
    if(![[NSFileManager defaultManager] fileExistsAtPath:[exportVideoPath stringByDeletingLastPathComponent]]){
        [[NSFileManager defaultManager] createDirectoryAtPath:[exportVideoPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    CGRect rectInVideo = [[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue];
    mainVC.videoInViewSize = CGSizeMake(rectInVideo.size.width*templateCollectionView.frame.size.width, rectInVideo.size.height*templateCollectionView.frame.size.height);
#if 0
    mainVC.selectFinishActionBlock = ^(NSMutableArray *thumbImageFilelist) {
        [weakSelf addFileWithList:thumbImageFilelist templateCell:cell];
    };
#else
    mainVC.videoTrimPath = exportVideoPath;
    mainVC.selectAndTrimFinishBlock = ^(RDFile *videoFile) {
        [weakSelf addFile:videoFile templateCell:cell];
    };
#endif
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [self setNavConfig:nav];
    nav.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
    nav.editConfiguration.enableAlbumCamera = NO;
    nav.editConfiguration.enableTextTitle = NO;
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addFile:(RDFile *)videoFile templateCell:(RDTemplateCollectionViewCell *)cell {
    cell.recordBtn.hidden = YES;
    cell.addLocalVideoBtn.hidden = YES;
    cell.editBtn.hidden = NO;
    cell.deleteBtn.hidden = YES;
    
    selectedVideoFile.contentURL = videoFile.contentURL;
    selectedVideoFile.videoTimeRange = videoFile.videoTimeRange;
    selectedVideoFile.videoDurationTime = selectedVideoFile.videoTimeRange.duration;
    selectedVideoFile.crop = videoFile.crop;
    selectedVideoFile.cropRect = videoFile.cropRect;
}

- (void)addFileWithList:(NSMutableArray *)fileLists templateCell:(RDTemplateCollectionViewCell *)cell {
    cell.recordBtn.hidden = YES;
    cell.addLocalVideoBtn.hidden = YES;
    cell.editBtn.hidden = NO;
    cell.deleteBtn.hidden = YES;
    
    selectedVideoFile.contentURL = [fileLists firstObject];
    selectedVideoFile.videoTimeRange = CMTimeRangeMake(kCMTimeZero, [AVAsset assetWithURL:selectedVideoFile.contentURL].duration);
    selectedVideoFile.videoDurationTime = selectedVideoFile.videoTimeRange.duration;
    selectedVideoFile.crop = [self getCropFrame:[AVURLAsset assetWithURL:selectedVideoFile.contentURL] rectInVideo:[[_videosFrameArray objectAtIndex:selectedVideoIndex] CGRectValue]];
}

- (void)setNavConfig:(RDNavigationViewController *)nav{
    nav.edit_functionLists = ((RDNavigationViewController *)self.navigationController).edit_functionLists;
    nav.exportConfiguration = ((RDNavigationViewController *)self.navigationController).exportConfiguration;
    nav.editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    nav.cameraConfiguration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration;
    nav.outPath = ((RDNavigationViewController *)self.navigationController).outPath;
    nav.appAlbumCacheName = ((RDNavigationViewController *)self.navigationController).appAlbumCacheName;
    nav.appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    nav.appSecret = ((RDNavigationViewController *)self.navigationController).appSecret;
    nav.statusBarHidden = ((RDNavigationViewController *)self.navigationController).statusBarHidden;
    nav.folderType = ((RDNavigationViewController *)self.navigationController).folderType;
    nav.disable = ((RDNavigationViewController *)self.navigationController).disable;
    nav.videoAverageBitRate = ((RDNavigationViewController *)self.navigationController).videoAverageBitRate;
    nav.waterLayerRect = ((RDNavigationViewController *)self.navigationController).waterLayerRect;
    nav.callbackBlock = ((RDNavigationViewController *)self.navigationController).callbackBlock;
    nav.rdVeUiSdkDelegate = ((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate;
}

- (void)initCommonAlertViewWithTitle:(nullable NSString *)title
                             message:(nullable NSString *)message
                   cancelButtonTitle:(nullable NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSString *)otherButtonTitles
                        alertViewTag:(NSInteger)alertViewTag
{
    if (_commonAlertView) {
        _commonAlertView.delegate = nil;
        _commonAlertView = nil;
    }
    _commonAlertView = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:cancelButtonTitle
                                        otherButtonTitles:otherButtonTitles, nil];
    _commonAlertView.tag = alertViewTag;
    [_commonAlertView show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case 1:
            if (buttonIndex == 1) {//退出录制
                playBtn.hidden = NO;
                _cameraView.hidden = YES;
                recordProgressBar.hidden = YES;
                [recordProgressBar deleteAllProgress];
                [_cameraManager stopCamera];
                recordBtn.hidden = YES;
                cameraZoomInBtn.hidden = YES;
                [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
                selectedVideoFile = oldVideoFile;
                [videoFileList replaceObjectAtIndex:selectedVideoIndex withObject:oldVideoFile];
                templateCollectionView.hidden = NO;
                if (maxVideoDuration == 0.0) {
                    _videoProgressSlider.hidden = YES;
                    _durationLabel.hidden = YES;
                }else {
                    _videoProgressSlider.hidden = NO;
                    _durationLabel.hidden = NO;
                }
                
                RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
                cell.zoomBtn.hidden = YES;
                cell.editBtn.hidden = YES;
                cell.deleteBtn.hidden = YES;
                cell.recordBtn.hidden = NO;
                cell.addLocalVideoBtn.hidden = NO;
            }
            break;
            
        case 2:
            if (buttonIndex == 1) {//退出编辑
                titleLbl.text = @"";
                editBottomView.hidden = YES;
                [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
                selectedVideoFile = oldVideoFile;
                [videoFileList replaceObjectAtIndex:selectedVideoIndex withObject:oldVideoFile];
                [self playVideo:NO];
                [self refreshVideoCoreSDK:NO];
                
                RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
                cell.zoomBtn.hidden = YES;
                cell.editBtn.hidden = NO;
                cell.deleteBtn.hidden = YES;
                cell.recordBtn.hidden = YES;
                cell.addLocalVideoBtn.hidden = YES;
                
                _videoProgressSlider.hidden = NO;
                _durationLabel.hidden = NO;
            }
            break;
            
        case 3:
            if (buttonIndex == 1) {//返回上一界面
                [self.navigationController popViewControllerAnimated:YES];
            }
            break;
            
        case 4:
            if (buttonIndex == 1) {//删除当前视频
                [self playVideo:NO];
                RDTemplateCollectionViewCell *cell = (RDTemplateCollectionViewCell *)[templateCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVideoIndex inSection:0]];
                cell.deleteBtn.hidden = YES;
                cell.editBtn.hidden = YES;
                cell.recordBtn.hidden = NO;
                cell.addLocalVideoBtn.hidden = NO;
                
                [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
                editBottomView.hidden = YES;
                
                RDFile *videoFile = [RDFile new];
                videoFile.fileType = kFILEVIDEO;
                videoFile.videoVolume = 1.0;
                videoFile.speed = 1.0;
                videoFile.speedIndex = 2;
                videoFile.fileCropModeType = kCropTypeFixed;
                [videoFileList replaceObjectAtIndex:selectedVideoIndex withObject:videoFile];
                [self refreshVideoCoreSDK:NO];
            }
            break;
            
        case 5:
            if (buttonIndex == 1) {//取消导出
                [_videoCoreSDK cancelExportMovie:^{
                    [progressHud hide:NO];
                    progressHud = nil;
                }];
            }            
            break;
            
        default:
            break;
    }
}

- (void)deleteAllVideo
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:@"videos"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* fileList = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    if (fileList.count > 0) {
        [fileList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString * filePath = [folderPath stringByAppendingPathComponent:obj];
            if ([fileManager fileExistsAtPath:filePath]) {
                NSError *error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                
                if (error) {
                    NSLog(@"deleteAllVideo删除视频文件出错:%@", error);
                }else{
                    NSLog(@"删除所有视频");
                }
            }
            
            
        }];
    }
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    if (_commonAlertView) {
        _commonAlertView.delegate = nil;
        _commonAlertView = nil;
    }
    [self clearVideoCoreSDK];
    [self deleteAllVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
