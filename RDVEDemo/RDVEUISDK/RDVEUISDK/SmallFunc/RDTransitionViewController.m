//
//  RDTransitionViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//
#import "RDTransitionViewController.h"
#import "RDDownTool.h"
#import "CircleView.h"
#import "UIImageView+RDWebCache.h"
#import "RDTranstionCollectionViewCell.h"
#import "RDFileDownloader.h"
#import "RDZipArchive.h"
#import "RDSVProgressHUD.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"
#import "RDThumbImageView.h"
#import "RDConnectBtn.h"
#import "RDZSlider.h"
#import "RDMainViewController.h"
#import "CustomTextPhotoViewController.h"

#define AUTOSCROLL_THRESHOLD 30

@interface RDTransitionViewController ()<RDVECoreDelegate, UIAlertViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource, RDThumbImageViewDelegate, CustomTextDelegate>
{
    NSMutableArray          <RDScene *>*scenes;
    UIView                  * titleView;
    float                     bottomHeight;
    UIButton                * finishBtn;
    RDVECore                * rdPlayer;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;
    UIView                  * transitionView;
    UIButton                * useToAllBtn;
    UIButton                * randomBtn;
    UISlider                * durationSlider;
    UILabel                 * durationLbl;
    float                     videoThumbWidth;
    float                     videoThumbHeight;
    double                    lastDuration;
    NSString                * selectedTransitionTypeName;
    NSString                * selectedTransitionName;
    NSString                * prevTransitionName;   //用于取消随机转场
    NSInteger                 selectFileIndex;
    NSTimer                 * _autoscrollTimer;
    float                     _autoscrollDistance;
    CGPoint                   startTouchPoint;
    double                    startTouchTime;
    CMTime                    seekTime;
    RDThumbImageView        * deletedFileView;
    NSMutableArray          * transitionList;
    UIScrollView            *transitionTypeScrollView;
    UIScrollView            *transitionScrollView;
    UIButton                *transitionNoneBtn;
    CMTimeRange              transitionTimeRange;
}

@property (nonatomic,assign)double transitionDuration;
@property(nonatomic,strong)UIScrollView *videoThumbSlider;
@property(nonatomic,strong)RDZSlider *videoProgressSlider;
@property(nonatomic,strong)UILabel *durationLabel;
@property (nonatomic,assign)float maxFileTimeDuration;
@property (nonatomic, strong) RDATMHud *hud;
@property (nonatomic, strong) RDExportProgressView *exportProgressView;
@property(nonatomic,strong)UIView               *transitionToolbarView;

@end

@implementation RDTransitionViewController

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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
    
    [rdPlayer stop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [rdPlayer prepare];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgressView){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
            });
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    transitionList = [RDHelpClass getTransitionArray];
    lastDuration = 0.3;
    bottomHeight = kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight -  (iPhone_X ? 34 : 0);
    videoThumbWidth = kWIDTH >320 ? 120 : 100;
    videoThumbHeight = kWIDTH >320 ? 100 : 80;
    [self initPlayer];
    [self initTitleView];
    [self initAddBtns];
    [self initVideoThumbSlider];
    [self initTransitionView];
    [self initVideoProgressSlider];
}

- (void)initTransitionView{
    transitionView = [[UIView alloc] init];
    transitionView.frame = CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight, kWIDTH, bottomHeight - 44);
    transitionView.backgroundColor = BOTTOM_COLOR;
    transitionView.hidden = YES;
    [self.view addSubview:transitionView];
    
    float width = (kWIDTH - 5.0 * 8.0) / 5.0;
    float height = width+20;
    
    transitionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(16 + width, 50.0 + (bottomHeight - 44 - 50.0 - height)/2.0 - 5, kWIDTH - 16 - width, height)];
    transitionScrollView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    transitionScrollView.showsVerticalScrollIndicator = NO;
    transitionScrollView.showsHorizontalScrollIndicator = NO;
    transitionScrollView.scrollEnabled = NO;
    [transitionView addSubview:transitionScrollView];
    
    UIImageView *noneIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, height - 34, height - 34)];
    if (iPhone4s) {
        noneIV.frame = CGRectMake(0, 0, 40, 40);
    }
    noneIV.image = [RDHelpClass imageWithContentOfFile:@"transitions/剪辑-转场_无默认_"];
    
    transitionNoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    transitionNoneBtn.frame = CGRectMake(16, 5 + transitionScrollView.frame.origin.y, width - 16, height);
    [transitionNoneBtn setTitle:RDLocalizedString(@"无", nil) forState:UIControlStateNormal];
    [transitionNoneBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
    [transitionNoneBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    transitionNoneBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    transitionNoneBtn.titleEdgeInsets = UIEdgeInsetsMake(height - 32, 0, 0, 0);
    [transitionNoneBtn addTarget:self action:@selector(transitionNoneBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [transitionView addSubview:transitionNoneBtn];
    [transitionNoneBtn addSubview:noneIV];
    
    useToAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    useToAllBtn.frame = CGRectMake(0, (50.0 + (bottomHeight - 50.0 - height)/2.0 - 35)/2.0 - 5, 120, 35);
    useToAllBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [useToAllBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
    [useToAllBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
    useToAllBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
    [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
    [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [useToAllBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
    [useToAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
    useToAllBtn.backgroundColor = [UIColor clearColor];
    [useToAllBtn addTarget:self action:@selector(useToAllBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [transitionView addSubview:useToAllBtn];
    
    randomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    randomBtn.frame = CGRectMake(useToAllBtn.frame.size.width + useToAllBtn.frame.origin.x + 5, useToAllBtn.frame.origin.y, 90, 35);
    randomBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [randomBtn setTitle: RDLocalizedString(@"随机转场", nil) forState:UIControlStateNormal];
    [randomBtn setTitle: RDLocalizedString(@"随机转场", nil) forState:UIControlStateHighlighted];
    [randomBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
    [randomBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
    [randomBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [randomBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    [randomBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
    [randomBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
    randomBtn.backgroundColor = [UIColor clearColor];
    [randomBtn addTarget:self action:@selector(randomBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [transitionView addSubview:randomBtn];
    
    durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(randomBtn.frame.size.width + randomBtn.frame.origin.x + 5, useToAllBtn.frame.origin.y, 44, 35)];
    durationLbl.backgroundColor = [UIColor clearColor];
    durationLbl.textColor = [UIColor whiteColor];
    durationLbl.font = [UIFont systemFontOfSize:11];
    durationLbl.textAlignment = NSTextAlignmentCenter;
    [transitionView addSubview:durationLbl];
    
    durationSlider = [[UISlider alloc] init];
    durationSlider.frame = CGRectMake(durationLbl.frame.size.width + durationLbl.frame.origin.x + 5, useToAllBtn.frame.origin.y, kWIDTH - (durationLbl.frame.size.width + durationLbl.frame.origin.x + 15), 35);
    durationSlider.maximumValue = 2.0;
    durationSlider.minimumValue = kTransitionMinValue;
    durationSlider.value = MAX(kTransitionMinValue, _transitionDuration);
    UIImage *theImage = [RDHelpClass rdImageWithColor:Main_Color cornerRadius:9];
    [durationSlider setThumbImage:theImage forState:UIControlStateNormal];
    durationSlider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.5];
    durationSlider.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.5];
    [durationSlider addTarget:self action:@selector(changeSlider) forControlEvents:UIControlEventValueChanged];
    [durationSlider addTarget:self action:@selector(endSlider) forControlEvents:UIControlEventTouchUpOutside];
    [durationSlider addTarget:self action:@selector(endSlider) forControlEvents:UIControlEventTouchUpInside];
    [durationSlider addTarget:self action:@selector(endSlider) forControlEvents:UIControlEventTouchCancel];
    [transitionView addSubview:durationSlider];
}

- (void)initTitleView{
    titleView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, kToolbarHeight)];
    titleView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:titleView];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (__bridge id)[UIColor clearColor].CGColor];
    gradientLayer.locations = @[@0.3, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1.0);
    gradientLayer.frame = titleView.bounds;
    [titleView.layer addSublayer:gradientLayer];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"转场", nil);
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [titleView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:cancelBtn];
    
    finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
    finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:finishBtn];
}

- (UIView *)transitionToolbarView {
    if (!_transitionToolbarView) {
        _transitionToolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
        _transitionToolbarView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_transitionToolbarView];
        
        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(cancel_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_transitionToolbarView addSubview:cancelBtn];
        
        UIButton *finishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [finishBtn addTarget:self action:@selector(finish_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_transitionToolbarView addSubview:finishBtn];
        
        transitionTypeScrollView =  [UIScrollView new];
        transitionTypeScrollView.frame = CGRectMake(44, 0, _transitionToolbarView.frame.size.width - 88, 44);
        transitionTypeScrollView.showsVerticalScrollIndicator = NO;
        transitionTypeScrollView.showsHorizontalScrollIndicator = NO;
        [_transitionToolbarView addSubview:transitionTypeScrollView];
        if (transitionList && transitionList.count > 0) {
            [self refreshTransitionTypeView];
        }
    }
    return _transitionToolbarView;
}

- (void)refreshTransitionTypeView {
    __block float contentWidth = 0;
    [transitionList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *typeName = RDLocalizedString(obj[@"typeName"], nil);
        float itemWidth = [RDHelpClass widthForString:typeName andHeight:16 fontSize:16] + 25;
        contentWidth += itemWidth;
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake(idx*itemWidth, 0, itemWidth, transitionTypeScrollView.bounds.size.height);
        [itemBtn setTitle:typeName forState:UIControlStateNormal];
        [itemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [itemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        itemBtn.tag = idx + 1;
        [itemBtn addTarget:self action:@selector(transitionTypeItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [transitionTypeScrollView addSubview:itemBtn];
        
        float width = (kWIDTH - 5.0 * 8.0) / 5.0;
        float height = width+20;
        UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flow.itemSize = CGSizeMake(width, height);
        flow.sectionInset = UIEdgeInsetsMake(5.0, 8.0, 0.0, 8.0);
        flow.minimumLineSpacing = 8.0;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame: CGRectMake(transitionScrollView.bounds.size.width*idx, 0.0, transitionScrollView.bounds.size.width, height + 5) collectionViewLayout: flow];
        collectionView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        collectionView.tag = idx + 1;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.alwaysBounceVertical = NO;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        [collectionView registerClass:[RDTranstionCollectionViewCell class] forCellWithReuseIdentifier:@"TransitionCell"];
        collectionView.contentSize = CGSizeMake((16 + width)*[obj[@"data"] count], 0);
        [transitionScrollView addSubview:collectionView];
    }];
    transitionTypeScrollView.contentSize = CGSizeMake(contentWidth, 0);
}

- (void)initPlayer {
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    if (!rdPlayer) {
        RDFile *firstFile = [_fileList firstObject];
        NSString *exportOutPath = _outputPath.length>0 ? _outputPath : [RDHelpClass pathAssetVideoForURL:firstFile.contentURL];
        unlink([exportOutPath UTF8String]);
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        
        if (CGSizeEqualToSize(_exportSize, CGSizeZero)) {
            _exportSize = [RDHelpClass getEditSizeWithFile:firstFile];
        }
        
        rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                          APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                         LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                          videoSize:_exportSize
                                                fps:kEXPORTFPS
                                         resultFail:^(NSError *error) {
                                             NSLog(@"initSDKError:%@", error.localizedDescription);
                                         }];
        rdPlayer.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
        rdPlayer.delegate = self;
        [self.view addSubview:rdPlayer.view];
    }
    if (scenes) {
        [scenes removeAllObjects];
    }else {
        scenes = [NSMutableArray array];
    }
    for (int i = 0; i < _fileList.count; i++) {
        RDFile *file = _fileList[i];
        RDScene *scene = [RDScene new];
        VVAsset *vvAsset = [VVAsset new];
        vvAsset.url = file.contentURL;
        if(file.fileType == kFILEVIDEO){
            vvAsset.type = RDAssetTypeVideo;
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                vvAsset.timeRange = file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvAsset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                vvAsset.timeRange = file.videoTrimTimeRange;
            }
        }else {
#if isUseCustomLayer
            if (file.fileType == kTEXTTITLE) {
                vvAsset.fillType = RDImageFillTypeFull;
            }
#endif
            vvAsset.type = RDAssetTypeImage;
            vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
        }
        if(i != _fileList.count - 1 && ( ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition )){
            [RDHelpClass setTransition:scene.transition file:file];
        }
        vvAsset.crop = file.crop;
        vvAsset.volume = file.videoVolume;
        scene.vvAsset = [NSMutableArray arrayWithObject:vvAsset];
        [scenes addObject:scene];
    }    
    [rdPlayer setScenes:scenes];
    [rdPlayer build];
}

- (void)initVideoProgressSlider{
    _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight - 15, kWIDTH, 30)];
    _videoProgressSlider.backgroundColor = [UIColor clearColor];
    [_videoProgressSlider setMaximumValue:1];
    [_videoProgressSlider setMinimumValue:0];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
    image = [image imageWithTintColor];
    [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
    [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
    [_videoProgressSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
    [_videoProgressSlider addTarget:self action:@selector(beginScrub) forControlEvents:UIControlEventTouchDown];
    [_videoProgressSlider addTarget:self action:@selector(scrub) forControlEvents:UIControlEventValueChanged];
    [_videoProgressSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchUpInside];
    [_videoProgressSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchCancel];
    [self.view addSubview:_videoProgressSlider];
    
    _durationLabel = [[UILabel alloc] init];
    _durationLabel.frame = CGRectMake(kWIDTH - 130, kPlayerViewOriginX + kPlayerViewHeight - 30, 120, 20);
    _durationLabel.textAlignment = NSTextAlignmentRight;
    _durationLabel.textColor = [UIColor whiteColor];
    _durationLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:_durationLabel];
}

- (void)initAddBtns {
    NSMutableArray *array = [NSMutableArray array];
    if (((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition) {
        [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"转场",@"title",@(1),@"id", nil]];
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_VIDEO){
        [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"图片",@"title",@(3),@"id", nil]];
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE){
        [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"视频",@"title",@(2),@"id", nil]];
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
        [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"文字",@"title",@(4),@"id", nil]];
    }
    float width = kWIDTH/(float)array.count;
    for (int i = 0; i < array.count; i++) {
        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        addBtn.backgroundColor = [UIColor clearColor];
        addBtn.frame = CGRectMake(i*width, kPlayerViewOriginX + kPlayerViewHeight + (bottomHeight - videoThumbHeight - 10 - (iPhone4s ? 55 : 60))/2.0, width, (iPhone4s ? 55 : 60));
        [addBtn setTitle:RDLocalizedString([array[i] objectForKey:@"title"], nil) forState:UIControlStateNormal];
        int type = [[array[i] objectForKey:@"id"] intValue];
        switch (type) {
            case 1:
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/scrollViewChildImage/剪辑_剪辑转场默认_@3x"] forState:UIControlStateNormal];
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_切换转场点击_@3x"] forState:UIControlStateHighlighted];
                break;
            case 2:
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加视频默认_@3x"] forState:UIControlStateNormal];
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加视频点击_@3x"] forState:UIControlStateHighlighted];
                break;
            case 3:
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加图片默认_@3x"] forState:UIControlStateNormal];
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加图片点击_@3x"] forState:UIControlStateHighlighted];
                break;
            case 4:
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加文字板默认_@3x"] forState:UIControlStateNormal];
                [addBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加文字板点击_@3x"] forState:UIControlStateHighlighted];
                break;
                
            default:
                break;
        }
        if ([UIScreen mainScreen].bounds.size.width >= 414) {
            addBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        }else {
            addBtn.titleLabel.font = [UIFont systemFontOfSize:10];
        }
        [addBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (width - 44)/2.0, 16, (width - 44)/2.0)];
        [addBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
        addBtn.tag = type;
        [addBtn addTarget:self action:@selector(addBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:addBtn];
    }
}

- (void)initVideoThumbSlider{
    if(!_videoThumbSlider){
        _videoThumbSlider = [UIScrollView new];
        _videoThumbSlider.frame = CGRectMake(0, 0, kWIDTH, videoThumbHeight);
        _videoThumbSlider.frame = CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight + bottomHeight - videoThumbHeight - 10 , kWIDTH, videoThumbHeight);
        _videoThumbSlider.backgroundColor = [UIColor clearColor];
        _videoThumbSlider.showsVerticalScrollIndicator = NO;
        _videoThumbSlider.showsHorizontalScrollIndicator = NO;
        [_videoThumbSlider setCanCancelContentTouches:NO];
        [_videoThumbSlider setClipsToBounds:NO];
        [self.view addSubview:_videoThumbSlider];
    }
    [_videoThumbSlider.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDThumbImageView class]]) {
            RDThumbImageView *thumbView = (RDThumbImageView *)obj;
            thumbView.thumbIconView.image = nil;
        }
        [obj removeFromSuperview];
    }];
    float fwidth  = _fileList.count * videoThumbWidth + (_videoThumbSlider.frame.size.height) * 2.0 + 20  - (videoThumbHeight + 10)*2.0 + (_videoThumbSlider.frame.size.height*2.0/3.0) - _videoThumbSlider.frame.size.height*1.0/3.0;
    if( fwidth <= kWIDTH )
        fwidth = kWIDTH + 10;
    _videoThumbSlider.contentSize = CGSizeMake(fwidth, 0);
    __weak typeof(self) myself = self;
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(_videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height)];
        thumbView.backgroundColor = [UIColor clearColor];
        thumbView.frame = CGRectMake(videoThumbWidth*idx, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
        thumbView.home = thumbView.frame;
        thumbView.contentFile = obj;
        thumbView.transitionTypeName = obj.transitionTypeName;
        thumbView.transitionDuration = obj.transitionDuration;
        thumbView.transitionName = obj.transitionName;
        thumbView.transitionMask = obj.transitionMask;
        if(!obj.thumbImage){
            [myself performSelectorInBackground:@selector(refreshThumbImage:) withObject:thumbView];
        }else{
            thumbView.thumbIconView.image = obj.thumbImage;
        }
        thumbView.thumbId = idx;
        thumbView.tag = 100;
        thumbView.delegate = self;
        if(idx == selectFileIndex){
            [thumbView selectThumb:YES];
        }else{
            [thumbView selectThumb:NO];
        }
        [_videoThumbSlider insertSubview:thumbView atIndex:0];
        
        if(idx != (_fileList.count - 1)){
            float btnWidth = (videoThumbWidth - videoThumbHeight) + 16;
            float btnHeight = btnWidth + 14;
            RDConnectBtn *transitionBtn = [[RDConnectBtn alloc] initWithFrame:CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width - 8, (_videoThumbSlider.frame.size.height - btnHeight)/2.0, btnWidth, btnHeight)];
            transitionBtn.fileIndex = idx;
            transitionBtn.tag = 1000;
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
                [transitionBtn setTransitionTypeName:obj.transitionTypeName];
                [transitionBtn setTransitionTitle:(obj.transitionName.length>0 ? obj.transitionName : RDLocalizedString(@"无", nil))];
                [transitionBtn addTarget:self action:@selector(enterTransition:) forControlEvents:UIControlEventTouchUpInside];
            }
            [_videoThumbSlider addSubview:transitionBtn];
        }
    }];
}

- (void)refreshThumbImage:(RDThumbImageView *)tiv{
    RDFile *obj = _fileList[tiv.thumbId];
    obj.thumbImage = [RDHelpClass getThumbImageWithUrl:obj.contentURL];
    dispatch_async(dispatch_get_main_queue(), ^{
        tiv.thumbIconView.image = obj.thumbImage;
    });
}

#pragma mark-滑动进度条
- (void)beginScrub{
    if([rdPlayer isPlaying]){
        [rdPlayer pause];
    }
}

- (void)scrub{
    CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

- (void)endScrub{
    CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}
#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay && sender == rdPlayer) {
        [RDSVProgressHUD dismiss];
        if(!transitionView.hidden)
        {
            transitionTimeRange = [rdPlayer transitionTimeRangeAtIndex:selectFileIndex];
            [rdPlayer seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                [rdPlayer play];
            }];
        }else if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
            [rdPlayer seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                if (!_exportProgressView) {
                    [rdPlayer play];
                }
            }];
            seekTime = kCMTimeZero;
        }else {
            if (!_exportProgressView) {
                [rdPlayer play];
            }
        }
    }
}

- (void)progressCurrentTime:(CMTime)currentTime{
    [_videoProgressSlider setValue:(CMTimeGetSeconds(currentTime)/rdPlayer.duration)];
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@",[RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)],[RDHelpClass timeToStringFormat:rdPlayer.duration]];
    if (!transitionView.hidden && rdPlayer.isPlaying && CMTimeCompare(currentTime, CMTimeAdd(transitionTimeRange.start, transitionTimeRange.duration)) == 1) {
        [rdPlayer pause];
        [rdPlayer seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:nil];
    }
}
#if isUseCustomLayer
- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    [RDHelpClass refreshCustomTextLayerWithCurrentTime:currentTime customDrawLayer:customDrawLayer fileLsit:_fileList];
}
#endif

- (void)playToEnd{
    [rdPlayer seekToTime:kCMTimeZero];
    [_videoProgressSlider setValue:0];
    self.durationLabel.text = [NSString stringWithFormat:@"%@/%@",[RDHelpClass timeToStringFormat:0.0],[RDHelpClass timeToStringFormat:rdPlayer.duration]];
}

- (void)tapPlayerView{
    if (rdPlayer.isPlaying) {
        [rdPlayer pause];
    }else {
        [rdPlayer play];
    }
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
        case 4:
            if(buttonIndex == 0){
                [self deletedFile:deletedFileView];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 按钮事件
- (void)save{
    [self exportMovie];
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).cancelHandler){
            ((RDNavigationViewController *)self.navigationController).cancelHandler();
        }
    }];
}
/** 改变转场时长
 */
- (void)changeSlider{
    durationLbl.text = [NSString stringWithFormat:@"%.2f",durationSlider.value];
    lastDuration = durationSlider.value;
}

- (void)endSlider {
    durationLbl.text = [NSString stringWithFormat:@"%.2f", durationSlider.value];
    lastDuration = durationSlider.value;
    [self setTransitionWithTypeName:selectedTransitionTypeName transitionName:selectedTransitionName];
}

-(void)cancel_Btn
{
    titleView.hidden = NO;
    durationSlider.value = 0.0;
    lastDuration = 0.0;
    useToAllBtn.selected = NO;
    randomBtn.selected = NO;
    
    [_videoThumbSlider.subviews enumerateObjectsUsingBlock:^(RDThumbImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDThumbImageView class]]) {
            NSInteger index = obj.thumbId;
            _fileList[index].transitionTypeName = obj.transitionTypeName;
            _fileList[index].transitionDuration = obj.transitionDuration;
            _fileList[index].transitionName = obj.transitionName;
            _fileList[index].transitionMask = obj.transitionMask;
        }
    }];
    [self initPlayer];
    titleView.hidden = NO;
    transitionView.hidden = YES;
    _transitionToolbarView.hidden = YES;
}

-(void)finish_Btn
{
    transitionView.hidden = YES;
    _transitionToolbarView.hidden = YES;
    titleView.hidden = NO;
    titleView.hidden = NO;
    durationSlider.value = 0.0;
    lastDuration = 0.0;
    if (useToAllBtn.selected) {
        RDFile *selectedFile = _fileList[selectFileIndex];
        for (int idx = 0; idx < _fileList.count - 1; idx++) {
            RDFile * obj = _fileList[idx];
            obj.transitionMask = selectedFile.transitionMask;
            obj.transitionDuration = selectedFile.transitionDuration;
            obj.transitionTypeName = selectedFile.transitionTypeName;
            obj.transitionName = selectedFile.transitionName;
        }
        [self initPlayer];
    }
    NSMutableArray *arra = [_videoThumbSlider.subviews mutableCopy];
    [arra sortUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
        [arra enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[RDConnectBtn class]]){
                NSInteger index = idx/2;
                [((RDConnectBtn *)obj) setTransitionTypeName:(_fileList[index]).transitionTypeName];
                ((RDConnectBtn *)obj).fileIndex = index;
                [((RDConnectBtn *)obj) setTransitionTitle:((_fileList[index]).transitionName.length>0 ? (_fileList[index]).transitionName : RDLocalizedString(@"无", nil))];
            }
        }];
    }
    [_videoThumbSlider.subviews enumerateObjectsUsingBlock:^(RDThumbImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDThumbImageView class]]) {
            NSInteger index = obj.thumbId;
            obj.transitionDuration = _fileList[index].transitionDuration;
            obj.transitionTypeName = _fileList[index].transitionTypeName;
            obj.transitionName = _fileList[index].transitionName;
            obj.transitionMask = _fileList[index].transitionMask;
        }
    }];
}

- (void)transitionTypeItemBtnAction:(UIButton *)sender {
    if (![sender.titleLabel.text isEqualToString:RDLocalizedString(selectedTransitionTypeName, nil)]) {
        [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"typeName"] isEqualToString:selectedTransitionTypeName]) {
                UIButton *prevBtn = [transitionTypeScrollView viewWithTag:idx + 1];
                prevBtn.selected = NO;
                UICollectionView *prevCV = [transitionScrollView viewWithTag:idx + 1];
                prevCV.contentOffset = CGPointZero;
                *stop = YES;
            }
        }];
        sender.selected = YES;
        selectedTransitionTypeName = [transitionList[sender.tag - 1] objectForKey:@"typeName"];
        transitionScrollView.contentOffset = CGPointMake((sender.tag - 1) * transitionScrollView.bounds.size.width, 0);
    }
}

- (void)transitionNoneBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        sender.selected = YES;
        [self setTransitionWithTypeName:kDefaultTransitionTypeName transitionName:nil];
    }else {
        [rdPlayer play];
    }
}

- (void)useToAllBtnAction:(UIButton *)sender{
    sender.selected = !sender.selected;
}

- (void)randomBtnAction:(UIButton *)sender{
    sender.selected = !sender.selected;
    NSString *itemName;
    if (sender.selected) {
        transitionNoneBtn.selected = NO;
        NSMutableArray *transitionArray = [NSMutableArray array];
        [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [transitionArray addObjectsFromArray:obj[@"data"]];
        }];
        NSInteger index = arc4random()%(transitionArray.count);
        itemName = transitionArray[index];
        if ([itemName pathExtension]) {
            itemName = [itemName stringByDeletingPathExtension];
        }
        prevTransitionName = selectedTransitionName;
    }else {
        itemName = prevTransitionName;
    }
    __block NSString *typeName = kDefaultTransitionTypeName;
    __block NSInteger prevTypeIndex;
    __block int count = 0;
    if (!itemName || [itemName isEqualToString:RDLocalizedString(@"无", nil)]) {
        transitionNoneBtn.selected = YES;
        UIButton *typeBtn = [transitionTypeScrollView viewWithTag:1];
        typeBtn.selected = YES;
        count++;
    }
    [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"typeName"] isEqualToString:selectedTransitionTypeName]) {
            prevTypeIndex = idx;
            count++;
            if (count == 2) {
                *stop = YES;
            }
        }
        if (![itemName isEqualToString:RDLocalizedString(@"无", nil)]) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([[obj1 stringByDeletingPathExtension] isEqualToString:itemName]) {
                    typeName = obj[@"typeName"];
                    
                    UIButton *typeBtn = [transitionTypeScrollView viewWithTag:idx + 1];
                    typeBtn.selected = YES;
                    transitionScrollView.contentOffset = CGPointMake(idx * transitionScrollView.bounds.size.width, 0);
                    UICollectionView *collectionView = [transitionScrollView viewWithTag:idx + 1];
                    CGFloat offsetX = idx1 *((kWIDTH - 5.0 * 8.0) / 5.0 + 8);
                    if (offsetX + collectionView.frame.size.width >= collectionView.contentSize.width) {
                        [collectionView setContentOffset:CGPointMake(collectionView.contentSize.width - collectionView.frame.size.width, 0)];
                    }else {
                        [collectionView setContentOffset:CGPointMake(offsetX, 0)];
                    }
                    RDTranstionCollectionViewCell *selectCell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                    selectCell.customDetailTextLabel.textColor = Main_Color;
                    
                    count++;
                    *stop1 = YES;
                    if (count == 2) {
                        *stop = YES;
                    }
                }
            }];
        }
    }];
    if (![typeName isEqualToString:selectedTransitionTypeName]) {
        UIButton *prevTypeBtn = [transitionTypeScrollView viewWithTag:prevTypeIndex + 1];
        prevTypeBtn.selected = NO;
        UICollectionView *prevCollectionView = [transitionScrollView viewWithTag:prevTypeIndex + 1];
        prevCollectionView.contentOffset = CGPointZero;
    }
    [self setTransitionWithTypeName:typeName transitionName:itemName];
}

- (void)addBtnAction:(UIButton *)sender{
    switch (sender.tag) {
        case 1:
        {
            [self changeTransition];
        }
            break;
        case 2:
        {
            [self AddFile:ONLYSUPPORT_VIDEO touchConnect:YES];
        }
            break;
        case 3:
        {
            [self AddFile:ONLYSUPPORT_IMAGE touchConnect:YES];
        }
            break;
        case 4:
        {
            [self enter_TextPhotoVC:NO];
        }
            break;
            
        default:
            break;
    }
}

/**添加文件
 *@params isTouch 是否点击的两个缩略图之间的加号添加文件
 */
- (void)AddFile:(SUPPORTFILETYPE)type touchConnect:(BOOL) isTouch{
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [_hud setCaption:message];
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    __weak typeof(self) myself = self;
    if(([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)] ||
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)] ||
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)])){
        
        if(type == ONLYSUPPORT_VIDEO){
            if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)]){
                [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideosResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    [myself addFileWithList:lists withType:type touchConnect: isTouch];
                }];
                return;
            }
        }
        else if(type == SUPPORT_ALL){
            if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]){
                [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideoAndImageResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    [myself addFileWithList:lists withType:type touchConnect: isTouch];
                }];
                
                return;
            }
        }else {
            if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
                [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    [myself addFileWithList:lists withType:type touchConnect: isTouch];
                }];
                
                return;
            }
        }
    }
    //20171017 wuxiaoxia mantis:0001949
    NSString *cameraOutputPath = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath;
    for (RDFile *file in _fileList) {
        if ([file.contentURL.path isEqualToString:cameraOutputPath]) {
            NSString * exportPath = [kRDDirectory stringByAppendingPathComponent:@"/recordVideoFile_rd.mp4"];
            ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath = exportPath;
            break;
        }
    }
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    if(type == ONLYSUPPORT_IMAGE){
        mainVC.showPhotos = YES;
    }
    mainVC.textPhotoProportion = _exportSize.width/(float)_exportSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
        [myself addFileWithList:filelist withType:type touchConnect: isTouch];
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addFileWithList:(NSMutableArray *)filelist withType:(SUPPORTFILETYPE)type touchConnect:(BOOL) istouch{
    if ([filelist[0] isKindOfClass:[NSURL class]]) {
        for (int i = 0; i < filelist.count; i++) {
            NSURL *url = filelist[i];
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
                [filelist replaceObjectAtIndex:i withObject:file];
            }
        }
    }
    if (istouch) {
        NSRange range = NSMakeRange(selectFileIndex + 1, [filelist count]);
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [_fileList insertObjects:filelist atIndexes:indexSet];
    }else {
        [_fileList addObjectsFromArray:filelist];
    }
    CGPoint offset = self.videoThumbSlider.contentOffset;
    [_videoThumbSlider.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self initVideoThumbSlider];
    [self.videoThumbSlider setContentOffset:offset];
    
    [self initPlayer];
    CMTimeRange timerange = [rdPlayer passThroughTimeRangeAtIndex:selectFileIndex];
    seekTime = timerange.start;
    [rdPlayer seekToTime:timerange.start];
#if isUseCustomLayer
    [self refreshCustomTextTimeRange];
#endif
}


- (void)getCustomTextImagePath:(NSString *)textImagePath thumbImage:(UIImage *)thumbImage customTextPhotoFile:(CustomTextPhotoFile *)file touchUpType:(NSInteger)touchUpType change:(BOOL)flag{
    @autoreleasepool {
        if(flag){
            RDFile *selectFile = [_fileList objectAtIndex:selectFileIndex];
#if isUseCustomLayer
            selectFile.contentURL = [NSURL fileURLWithPath:textImagePath];
            selectFile.thumbImage = thumbImage;
            selectFile.cropRect = CGRectZero;
            selectFile.customTextPhotoFile = file;
            CGPoint offset = self.videoThumbSlider.contentOffset;
            [self initVideoThumbSlider];
            [self.videoThumbSlider setContentOffset:offset];
            
            [self initPlayer];
            CMTimeRange timerange = [rdPlayer passThroughTimeRangeAtIndex:selectFileIndex];
            seekTime = timerange.start;
            [rdPlayer seekToTime:timerange.start];
#else
            __block UIImage *image = thumbImage;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageDataFullScreen = UIImageJPEGRepresentation(image, 0.9);
                unlink([selectFile.contentURL.path UTF8String]);
                [imageDataFullScreen writeToFile:selectFile.contentURL.path atomically:YES];
                image = nil;
                imageDataFullScreen = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    selectFile.cropRect = CGRectZero;
                    selectFile.customTextPhotoFile = file;
                    selectFile.thumbImage = image;
                    CGPoint offset = self.videoThumbSlider.contentOffset;
                    [self initVideoThumbSlider];
                    
                    [self.videoThumbSlider setContentOffset:offset];
                    
                    [self initPlayer];
                    CMTimeRange timerange = [rdPlayer passThroughTimeRangeAtIndex:selectFileIndex];
                    seekTime = timerange.start;
                    [rdPlayer seekToTime:timerange.start];
                });
            });
#endif
        }
        else{
            RDFile *rdFile              = [[RDFile alloc] init];
#if isUseCustomLayer
            file.filePath = textImagePath;
            rdFile.contentURL = [NSURL fileURLWithPath:textImagePath];
            rdFile.thumbImage = thumbImage;
#else
            UIImage *imageFullScreen = thumbImage;
            NSData *imageDataFullScreen = UIImageJPEGRepresentation(imageFullScreen, 0.9);
            NSString *path = [RDHelpClass getContentTextPhotoPath];
            [imageDataFullScreen writeToFile:path atomically:YES];
            imageDataFullScreen = nil;
            file.filePath = path;
            rdFile.contentURL                = [NSURL fileURLWithPath:path];
            rdFile.thumbImage                = imageFullScreen;
#endif
            rdFile.imageTimeRange             = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4,TIMESCALE));
            rdFile.imageDurationTime          = CMTimeMakeWithSeconds(4, TIMESCALE);
            rdFile.fileType                  = kTEXTTITLE;
            rdFile.crop                      = CGRectZero;
            rdFile.cropRect                  = CGRectZero;
            rdFile.speed                     = 1;
            rdFile.speedIndex                = 2;
            rdFile.rotate                    = 0;
            rdFile.isHorizontalMirror        = NO;
            rdFile.isVerticalMirror          = NO;
            rdFile.isReverse                 = NO;
            rdFile.customTextPhotoFile       = file;
            [_fileList insertObject:rdFile atIndex:selectFileIndex+1];
            
            CGPoint offset = self.videoThumbSlider.contentOffset;
            [self initVideoThumbSlider];
            offset.x = (_videoThumbSlider.contentSize.width < _videoThumbSlider.frame.size.width) ? 0 : offset.x;
            [self.videoThumbSlider setContentOffset:offset];
            
            [self initPlayer];
            CMTimeRange timerange = [rdPlayer passThroughTimeRangeAtIndex:selectFileIndex];
            seekTime = timerange.start;
            [rdPlayer seekToTime:timerange.start];
#if isUseCustomLayer
            [self refreshCustomTextTimeRange];
#endif
        }
    }
}

- (void)refreshCustomTextTimeRange {
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
        if (file.customTextPhotoFile) {
            file.imageTimeRange = [rdPlayer passThroughTimeRangeAtIndex:idx];
        }
    }];
}

- (void)enterTransition:(RDConnectBtn *)sender{
    if([rdPlayer isPlaying]){
        [rdPlayer pause];
    }
    selectFileIndex = sender.fileIndex;
    
    [_videoThumbSlider.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDThumbImageView class]]){
            if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                [((RDThumbImageView *)obj) selectThumb:YES];
            }else{
                [((RDThumbImageView *)obj) selectThumb:NO];
            }
        }
    }];
    [rdPlayer seekToTime:[rdPlayer transitionTimeRangeAtIndex:sender.fileIndex].start];
    [self changeTransition];
}

- (void)enter_TextPhotoVC:(BOOL)edit{
    [rdPlayer stop];
    RDFile *file = _fileList[selectFileIndex];
    CustomTextPhotoViewController *cusTextview;
    if(edit){
        if(CGSizeEqualToSize(file.customTextPhotoFile.photoRectSize, CGSizeZero)){
            file.customTextPhotoFile.photoRectSize = _exportSize;
        }
        CustomTextPhotoFile *customTextPhotoFile = file.customTextPhotoFile;
        cusTextview  = [[CustomTextPhotoViewController alloc] initWithFile:customTextPhotoFile];
    }else{
        cusTextview = [[CustomTextPhotoViewController alloc] init];
        cusTextview.videoProportion = _exportSize.width/(float)_exportSize.height;
    }
    cusTextview.delegate = self;
    cusTextview.touchUpType = 0;
    [self.navigationController pushViewController:cusTextview animated:YES];
}

-(void)changeTransition
{
    if([rdPlayer isPlaying]){
        [rdPlayer pause];
    }
    _transitionDuration = _fileList[selectFileIndex].transitionDuration;
    if (selectFileIndex == _fileList.count - 1) {
        _maxFileTimeDuration = 0;
    }else{
        _maxFileTimeDuration = [RDHelpClass maxTransitionDuration:_fileList[selectFileIndex] nextFile:_fileList[selectFileIndex + 1]];
    }
    titleView.hidden = YES;
    transitionView.hidden = NO;
    self.transitionToolbarView.hidden = NO;
    randomBtn.selected = NO;
    useToAllBtn.selected = NO;
    if( _fileList[selectFileIndex].transitionDuration != 0.0 )
    {
        durationLbl.text = [NSString stringWithFormat:RDLocalizedString(@"%.2f", nil),_fileList[selectFileIndex].transitionDuration];
        lastDuration = _fileList[selectFileIndex].transitionDuration;
        durationSlider.value = _fileList[selectFileIndex].transitionDuration;
    }else
    {
        durationLbl.text = [NSString stringWithFormat:RDLocalizedString(@"%.2f", nil),0.0];
        lastDuration = 0.0;
        durationSlider.value = 0.0;
    }
    __block NSInteger selectedTransitionTypeIndex = 0;
    NSString *transitionName = _fileList[selectFileIndex].transitionName;
    if (!transitionName || [transitionName isEqualToString:RDLocalizedString(@"无", nil)]) {
        transitionNoneBtn.selected = YES;
        durationSlider.enabled = NO;
        [transitionTypeScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == 0) {
                obj.selected = YES;
            }else {
                obj.selected = NO;
            }
        }];
        [transitionScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UICollectionView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setContentOffset:CGPointZero];
        }];
        selectedTransitionTypeName = kDefaultTransitionTypeName;
    }else {
        transitionNoneBtn.selected = NO;
        [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            selectedTransitionTypeName = obj[@"typeName"];
            selectedTransitionTypeIndex = idx;
           [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
               if ([[obj1 stringByDeletingPathExtension] isEqualToString:transitionName]) {
                   UIButton *itemBtn = [transitionTypeScrollView viewWithTag:idx + 1];
                   itemBtn.selected = YES;
                   
                   UICollectionView *collectionView = [transitionScrollView viewWithTag:idx + 1];
                   CGFloat offsetX = idx1 *((kWIDTH - 5.0 * 8.0) / 5.0 + 8);
                   if (offsetX + collectionView.frame.size.width >= collectionView.contentSize.width) {
                       [collectionView setContentOffset:CGPointMake(collectionView.contentSize.width - collectionView.frame.size.width, 0)];
                   }else {
                       [collectionView setContentOffset:CGPointMake(offsetX, 0)];
                   }
                   RDTranstionCollectionViewCell *selectCell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                   selectCell.customDetailTextLabel.textColor = Main_Color;
                   *stop1 = YES;
                   *stop = YES;
               }
           }];
        }];
    }
    if (![selectedTransitionName isEqualToString:transitionName]) {
        [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
               if ([[obj1 stringByDeletingPathExtension] isEqualToString:selectedTransitionName]) {
                   UIButton *prevBtn = [transitionTypeScrollView viewWithTag:idx + 1];
                   prevBtn.selected = NO;
                   UICollectionView *prevCollectionView = [transitionScrollView viewWithTag:idx + 1];
                   RDTranstionCollectionViewCell *deselectCell = (RDTranstionCollectionViewCell *)[prevCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                   deselectCell.customDetailTextLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
                   *stop1 = YES;
                   *stop = YES;
               }
           }];
        }];
    }
    selectedTransitionName = transitionName;
    transitionScrollView.contentOffset = CGPointMake(selectedTransitionTypeIndex * transitionScrollView.bounds.size.width, 0);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    return [[transitionList[collectionView.tag - 1] objectForKey:@"data"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TransitionCell";
    RDTranstionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    for (UIView *view in cell.subviews) {
        [view removeFromSuperview];
    }
    cell.exclusiveTouch = NO;
    [cell initwithRect:cell.frame];
    cell.customImageView.highlighted = NO;
    cell.backgroundColor = [UIColor clearColor];

    NSString *typeName = [transitionList[collectionView.tag - 1] objectForKey:@"typeName"];
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    if ([itemName pathExtension]) {
        itemName = [itemName stringByDeletingPathExtension];
    }
    NSString *imagePath = [RDHelpClass getTransitionIconPath:typeName itemName:itemName];
    cell.customImageView.image = [UIImage imageWithContentsOfFile:imagePath];
    cell.customDetailTextLabel.text = RDLocalizedString(itemName, nil);
    cell.customDetailTextLabel.hidden = NO;
    if([selectedTransitionName isEqualToString:itemName]){
        cell.customDetailTextLabel.textColor = Main_Color;
    }else{
        cell.customDetailTextLabel.textColor = UIColorFromRGB(0x888888);
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(RDTranstionCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    if ([selectedTransitionName isEqualToString:[itemName stringByDeletingPathExtension]]) {
        cell.customDetailTextLabel.textColor = Main_Color;
    }
    [cell startScrollTitle];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(RDTranstionCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell stopScrollTitle];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    RDTranstionCollectionViewCell *cell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.customDetailTextLabel.textColor = UIColorFromRGB(0x888888);
    [cell stopScrollTitle];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    transitionNoneBtn.selected = NO;
    NSString *typeName = [transitionList[collectionView.tag - 1] objectForKey:@"typeName"];
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    if ([itemName pathExtension]) {
        itemName = [itemName stringByDeletingPathExtension];
    }
    randomBtn.selected = NO;
    [rdPlayer pause];
    if (![selectedTransitionName isEqualToString:itemName]) {
        if (transitionNoneBtn.selected) {
            transitionNoneBtn.selected = NO;
        }else {
            [transitionList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    if ([[obj1 stringByDeletingPathExtension] isEqualToString:selectedTransitionName]) {
                        UICollectionView *prevCollectionView = [transitionScrollView viewWithTag:idx + 1];
                        RDTranstionCollectionViewCell *deselectCell = (RDTranstionCollectionViewCell *)[prevCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                        deselectCell.customDetailTextLabel.textColor =  [UIColor colorWithWhite:1 alpha:0.5];
                        *stop1 = YES;
                        *stop = YES;
                    }
                }];
            }];
        }
        RDTranstionCollectionViewCell *cell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.customDetailTextLabel.textColor = Main_Color;
        [self setTransitionWithTypeName:typeName transitionName:itemName];
    }else if (CMTimeCompare(rdPlayer.currentTime, transitionTimeRange.start) != 0) {
        [rdPlayer seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [rdPlayer play];
        }];
    }else {
        [rdPlayer play];
    }
}

- (void)setTransitionWithTypeName:(NSString *)typeName transitionName:(NSString *)transitionName {
    NSLog(@"typeName:%@ transitionName:%@", typeName, transitionName);
    if (transitionNoneBtn.selected) {
        durationLbl.text = [NSString stringWithFormat:@"%.2f",0.0];
        durationSlider.value = 0;
        durationSlider.enabled = NO;
        durationLbl.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    }else {
        durationLbl.textColor = [UIColor colorWithWhite:1 alpha:1.0];
        durationSlider.maximumValue = MIN(_maxFileTimeDuration, 2.0);
        durationSlider.minimumValue = 0.0;
        durationSlider.value = (lastDuration == 0 ? durationSlider.maximumValue/2.0 : lastDuration);
        durationLbl.text = [NSString stringWithFormat:@"%.2f",durationSlider.value];
        durationSlider.enabled = YES;
    }
    [transitionList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
            if ([[obj1 stringByDeletingPathExtension] isEqualToString:selectedTransitionName]) {
                UICollectionView *prevCollectionView = [transitionScrollView viewWithTag:idx + 1];
                RDTranstionCollectionViewCell *deselectCell = (RDTranstionCollectionViewCell *)[prevCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                deselectCell.customDetailTextLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
                *stop1 = YES;
                *stop = YES;
            }
        }];
    }];
    NSString *maskpath;
    double transitionDuration = 0;
    if(!transitionNoneBtn.selected){
        maskpath = [RDHelpClass getTransitionPath:typeName itemName:transitionName];
        transitionDuration = durationSlider.value;
    }
    NSURL *maskUrl = maskpath.length == 0 ? nil : [NSURL fileURLWithPath:maskpath];
    
    RDFile *selectedFile = self.fileList[selectFileIndex];
    BOOL isNeedBuild = !(selectedFile.transitionDuration == transitionDuration);
    selectedFile.transitionMask = maskUrl;
    selectedFile.transitionTypeName = typeName;
    selectedFile.transitionName = transitionName;
    if (transitionNoneBtn.selected) {
        selectedFile.transitionDuration = 0;
    }else {
        float maxTransitionDuration;
        if (selectFileIndex == _fileList.count - 1) {
            maxTransitionDuration = 0;
        }else {
            maxTransitionDuration = [RDHelpClass maxTransitionDuration:selectedFile nextFile:_fileList[selectFileIndex + 1]];
        }
        selectedFile.transitionDuration = MIN(maxTransitionDuration, transitionDuration);
    }
    
    if (isNeedBuild) {
        [self initPlayer];
    }else {
        RDScene *scene = scenes[selectFileIndex];
        [RDHelpClass setTransition:scene.transition file:selectedFile];
        if (CMTimeCompare(rdPlayer.currentTime, transitionTimeRange.start) != 0) {
            [rdPlayer seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                [rdPlayer play];
            }];
        }else {
            [rdPlayer play];
        }
    }
    selectedTransitionTypeName = typeName;
    selectedTransitionName = transitionName;
}

#pragma mark- ThumbImageViewDelegate
- (void)thumbImageViewWasTapped:(RDThumbImageView *)tiv touchUpTiv:(BOOL)isTouchUpTiv{
    if(rdPlayer.isPlaying){
        [rdPlayer pause];
    }
    [_videoThumbSlider.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDThumbImageView class]]){
            if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                [((RDThumbImageView *)obj) selectThumb:NO];
            }
        }
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
            if([obj isKindOfClass:[RDConnectBtn class]]){
                [((RDConnectBtn *)obj) setSelected:NO];
            }
        }
    }];
    
    selectFileIndex = tiv.thumbId;
    CMTime time = [rdPlayer passThroughTimeRangeAtIndex:tiv.thumbId].start;
    [rdPlayer seekToTime:time];
    [tiv selectThumb:YES];
}

- (void)thumbImageViewWaslongLongTap:(RDThumbImageView *)tiv{
    [_videoThumbSlider bringSubviewToFront:tiv];
    if(rdPlayer.isPlaying){
        [rdPlayer pause];
    }
    tiv.tap = NO;
    self.videoThumbSlider.scrollEnabled = NO;
    if(_fileList.count <=1){
        return;
    }
    tiv.canMovePostion = YES;
    if(tiv.cancelMovePostion){
        tiv.canMovePostion = NO;
        return;
    }
    CGPoint touchLocation = tiv.center;
    CGFloat ofset_x = _videoThumbSlider.contentOffset.x;
    [_videoThumbSlider setContentSize:CGSizeMake(_fileList.count * videoThumbWidth + 20 + videoThumbHeight + 10 + 10, 20)];
    
    NSMutableArray *arra = [_videoThumbSlider.subviews mutableCopy];
    [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    NSInteger index = 0;
    
    for (int i = 0;i<arra.count;i++) {
        RDConnectBtn *prompView  = arra[i];
        if([prompView isKindOfClass:[RDConnectBtn class]]){
            prompView.hidden = YES;
            continue;
        }
        if([prompView isKindOfClass:[RDThumbImageView class]]){
            [UIView animateWithDuration:0.15 animations:^{
                
                CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
                ((RDThumbImageView *)prompView).frame = CGRectMake(index * videoThumbWidth + 10, tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
                ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
                [((RDThumbImageView *)prompView) selectThumb:NO];
                if((RDThumbImageView *)prompView == tiv){
                    [((RDThumbImageView *)prompView) selectThumb:YES];
                    [_videoThumbSlider setContentOffset:CGPointMake( tiv.center.x - (touchLocation.x - ofset_x), 0)];
                }
            } completion:^(BOOL finished) {
                
            }];
            index ++;
        }
    }
}

- (void)thumbImageViewWaslongLongTapEnd:(RDThumbImageView *)tiv{
    tiv.canMovePostion = NO;
    if(_fileList.count <=1){
        return;
    }
    self.videoThumbSlider.scrollEnabled = YES;
    
    CGPoint touchLocation = tiv.center;
    
    CGFloat ofSet_x = self.videoThumbSlider.contentOffset.x;
    [_videoThumbSlider setContentSize:CGSizeMake(_fileList.count * (videoThumbWidth)+10 + videoThumbHeight + 10 + videoThumbWidth + 10, 20)];
    
    [_fileList removeAllObjects];
    NSMutableArray *arra = [_videoThumbSlider.subviews mutableCopy];
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    selectFileIndex = tiv.thumbId;
    
    NSInteger index = 0;
    for (int i = 0;i<arra.count;i++) {
        RDConnectBtn *prompView  = arra[i];
        if([prompView isKindOfClass:[RDConnectBtn class]]){
            prompView.hidden = YES;
            continue;
        }
        if([prompView isKindOfClass:[RDThumbImageView class]]){
            CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
            ((RDThumbImageView *)prompView).frame = CGRectMake(index * videoThumbWidth , tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
            ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
            ((RDThumbImageView *)prompView).thumbId = index;
            if((RDThumbImageView *)prompView == tiv){
                selectFileIndex = index;
                [self.videoThumbSlider setContentOffset:CGPointMake( touchLocation.x + videoThumbWidth < self.videoThumbSlider.frame.size.width ? 0 : tiv.center.x - (touchLocation.x - ofSet_x), 0)];
            }
            RDFile *file = [((RDThumbImageView *)prompView).contentFile mutableCopy];
            if([file.transitionTypeName isEqualToString:kDefaultTransitionTypeName]){
                file.transitionName = RDLocalizedString(@"无", nil);
                file.transitionMask = nil;
                file.transitionDuration = 0;
            }
            [_fileList addObject:file];
            index ++;
        }
    }
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == _fileList.count - 1) {
            obj.transitionDuration = 0;
        }else {
            obj.transitionDuration = MIN([RDHelpClass maxTransitionDuration:obj nextFile:_fileList[idx + 1]], obj.transitionDuration);
        }
    }];
    
    for (RDConnectBtn *prompView in _videoThumbSlider.subviews) {
        if([prompView isKindOfClass:[RDConnectBtn class]]){
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
                [((RDConnectBtn *)prompView) setMaskURL:(_fileList[((RDConnectBtn *)prompView).fileIndex]).transitionMask];
                [((RDConnectBtn *)prompView) setTransitionTypeName:(_fileList[((RDConnectBtn *)prompView).fileIndex]).transitionTypeName];
                [((RDConnectBtn *)prompView) setTransitionTitle:(_fileList[((RDConnectBtn *)prompView).fileIndex]).transitionName];
            }
            prompView.hidden = NO;
        }
    }
    [self initPlayer];
    seekTime = [rdPlayer passThroughTimeRangeAtIndex:tiv.thumbId].start;
    [rdPlayer seekToTime:seekTime];
#if isUseCustomLayer
    [self refreshCustomTextTimeRange];
#endif
}

- (void)thumbImageViewMoved:(RDThumbImageView *)draggingThumb withEvent:(UIEvent *)event
{
    draggingThumb.tap = NO;
    if(!draggingThumb.canMovePostion){
        return;
    }
    // return;
    // check if we've moved close enough to an edge to autoscroll, or far enough away to stop autoscrolling
    [self maybeAutoscrollForThumb:draggingThumb];
    
    /* The rest of this method handles the reordering of thumbnails in the _libraryListScrollView. See  */
    /* RDThumbImageView.h and RDThumbImageView.m for more information about how this works.          */
    
    //return;
    // we'll reorder only if the thumb is overlapping the scroll view
    
    if (CGRectIntersectsRect([draggingThumb frame], [_videoThumbSlider bounds]))
    {
        BOOL draggingRight = [draggingThumb frame].origin.x > [draggingThumb home].origin.x ? YES : NO;
        
        /* we're going to shift over all the thumbs who live between the home of the moving thumb */
        /* and the current touch location. A thumb counts as living in this area if the midpoint  */
        /* of its home is contained in the area.                                                  */
        NSMutableArray *thumbsToShift = [[NSMutableArray alloc] init];
        
        // get the touch location in the coordinate system of the scroll view
        CGPoint touchLocation = [draggingThumb convertPoint:[draggingThumb touchLocation] toView:_videoThumbSlider];
        
        // calculate minimum and maximum boundaries of the affected area
        float minX = draggingRight ? CGRectGetMaxX([draggingThumb home]) : touchLocation.x;
        float maxX = draggingRight ? touchLocation.x : CGRectGetMinX([draggingThumb home]);
        
        // iterate through thumbnails and see which ones need to move over
        
        for (RDThumbImageView *thumb in [_videoThumbSlider subviews])
        {
            // skip the thumb being dragged
            if (thumb == draggingThumb)
                continue;
            
            // skip non-thumb subviews of the scroll view (such as the scroll indicators)
            if (! [thumb isMemberOfClass:[RDThumbImageView class]]) continue;
            
            float thumbMidpoint = CGRectGetMidX([thumb home]);
            if (thumbMidpoint >= minX && thumbMidpoint <= maxX)
            {
                [thumbsToShift addObject:thumb];
            }
        }
        
        // shift over the other thumbs to make room for the dragging thumb. (if we're dragging right, they shift to the left)
        float otherThumbShift = ([draggingThumb home].size.width) * (draggingRight ? -1 : 1);
        
        // as we shift over the other thumbs, we'll calculate how much the dragging thumb's home is going to move
        float draggingThumbShift = 0.0;
        NSLog(@"otherThumbShift:%lf",otherThumbShift);
        
        // send each of the shifting thumbs to its new home
        for (RDThumbImageView *otherThumb in thumbsToShift)
        {
            CGRect home = [otherThumb home];
            home.origin.x += otherThumbShift;
            [otherThumb setHome:home];
            [otherThumb goHome];
            draggingThumbShift += ([otherThumb frame].size.width) * (draggingRight ? 1 : -1);
        }
        
        // change the home of the dragging thumb, but don't send it there because it's still being dragged
        CGRect home = [draggingThumb home];
        home.origin.x += draggingThumbShift;
        
        [draggingThumb setHome:home];
    }else{
        
    }
    
}
- (void)thumbImageViewStoppedTracking:(RDThumbImageView *)tiv withEvent:(UIEvent *)event
{
    [_autoscrollTimer invalidate];
    _autoscrollTimer = nil;
}

- (void)thumbDeletedThumbFile:(RDThumbImageView *)tiv{
    NSString *str;
    if (((RDFile *)tiv.contentFile).fileType == kFILEVIDEO) {
        str = RDLocalizedString(@"是否删除当前选中视频?", nil);
    }else if (((RDFile *)tiv.contentFile).fileType == kFILEIMAGE) {
        str = RDLocalizedString(@"是否删除当前选中图片?", nil);
    }else {
        str = RDLocalizedString(@"是否删除当前选中文字板?", nil);
    }
    deletedFileView = tiv;
    if(_fileList.count==1){
        [self deletedFile:deletedFileView];
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:str
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:RDLocalizedString(@"是",nil)
                                                  otherButtonTitles:RDLocalizedString(@"否",nil), nil];
        alertView.tag = 4;
        [alertView show];
    }
}

- (void)deletedFile:(RDThumbImageView *)tiv{
    if(_fileList.count>1){
        [_fileList removeObjectAtIndex:tiv.thumbId];
        selectFileIndex = MAX((selectFileIndex>=tiv.thumbId?selectFileIndex - 1 : selectFileIndex), 0);
        if (selectFileIndex == _fileList.count - 1) {
            _fileList[selectFileIndex].transitionDuration = 0;
        }else {
            _fileList[selectFileIndex].transitionDuration = MIN([RDHelpClass maxTransitionDuration:_fileList[selectFileIndex] nextFile:_fileList[selectFileIndex + 1]], _fileList[selectFileIndex].transitionDuration);
        }
        CGPoint offset = _videoThumbSlider.contentOffset;
        float diffx = (tiv.frame.origin.x + tiv.frame.size.width) - offset.x;
        offset.x -= MIN(tiv.frame.size.width + 34, diffx);
        offset.x = MAX(offset.x, 0);
        
        NSMutableArray *arra = [_videoThumbSlider.subviews mutableCopy];
        [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
            CGFloat obj1X = obj1.frame.origin.x;
            CGFloat obj2X = obj2.frame.origin.x;
            
            if (obj1X > obj2X) { // obj1排后面
                return NSOrderedDescending;
            } else { // obj1排前面
                return NSOrderedAscending;
            }
        }];
        
        float tiv_width =  tiv.frame.size.width;
        float videoThumbSlider_Wdith = kWIDTH >320 ? 120 : 100;
        
        __block RDThumbImageView *selectTiv;
        
        [arra enumerateObjectsUsingBlock:^(UIView* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if([obj isKindOfClass:[RDConnectBtn class]]){
                if(((RDConnectBtn *)obj).fileIndex == (tiv.thumbId == _fileList.count ? tiv.thumbId - 1 : tiv.thumbId)){
                    [obj removeFromSuperview];
                }
                if(((RDConnectBtn *)obj).fileIndex > (tiv.thumbId == _fileList.count ? tiv.thumbId - 1 : tiv.thumbId)){
                    CGRect rect  = obj.frame;
                    rect.origin.x = obj.frame.origin.x - obj.frame.size.width - tiv_width + 16;
                    obj.frame = rect;
                    ((RDConnectBtn *)obj).fileIndex -=1;
                    
                }
                if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){
                    [((RDConnectBtn *)obj) setSelected:NO];
                }
            }else if([obj isKindOfClass:[RDThumbImageView class]]){
                if(((RDThumbImageView *)obj).thumbId == tiv.thumbId){
                    [obj removeFromSuperview];
                }
                if(((RDThumbImageView *)obj).thumbId > tiv.thumbId){
                    CGRect rect  = obj.frame;
                    rect.origin.x = obj.frame.origin.x - videoThumbSlider_Wdith;
                    obj.frame = rect;
                    ((RDThumbImageView *)obj).home = obj.frame;
                    ((RDThumbImageView *)obj).thumbId -= 1;
                }
                if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                    [((RDThumbImageView *)obj) selectThumb:YES];
                    selectTiv = (RDThumbImageView *)obj;
                }else{
                    [((RDThumbImageView *)obj) selectThumb:NO];
                }
            }else{
                CGRect rect  = obj.frame;
                rect.origin.x = obj.frame.origin.x - videoThumbSlider_Wdith;
                obj.frame = rect;
            }
            
        }];
        [self.videoThumbSlider setContentOffset:offset];
        float videoThumbSlider_Height = kWIDTH >320 ? 100 : 80;
        float fwidth  = _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20  - (videoThumbSlider_Height + 10)*2.0   + (_videoThumbSlider.frame.size.height*2.0/3.0);
        if( fwidth <= kWIDTH )
            fwidth = kWIDTH + 10;
        _videoThumbSlider.contentSize = CGSizeMake(fwidth, 0);
        [self initPlayer];
        seekTime = [rdPlayer passThroughTimeRangeAtIndex:selectFileIndex].start;
        [rdPlayer seekToTime:seekTime];
#if isUseCustomLayer
        [self refreshCustomTextTimeRange];
#endif
    }else{
        [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"至少保留一个文件", nil)]];
        [_hud show];
        [_hud hideAfter:2];
    }
}

#pragma mark Autoscrolling methods
- (void)maybeAutoscrollForThumb:(RDThumbImageView *)thumb
{
    _autoscrollDistance = 0;
    
    // only autoscroll if the thumb is overlapping the _libraryListScrollView
    if (CGRectIntersectsRect([thumb frame], self.videoThumbSlider.bounds))
    {
        
        CGPoint touchLocation = [thumb convertPoint:[thumb touchLocation] toView:self.videoThumbSlider];
        float distanceFromLeftEdge  = touchLocation.x - CGRectGetMinX(self.videoThumbSlider.bounds);
        float distanceFromRightEdge = CGRectGetMaxX(self.videoThumbSlider.bounds) - touchLocation.x;
        if (distanceFromLeftEdge < AUTOSCROLL_THRESHOLD)
        {
            
            if (_fileList.count>3) {
                _autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromLeftEdge] * -1; // if scrolling left, distance is negative
            }
        }
        else if (distanceFromRightEdge < AUTOSCROLL_THRESHOLD)
        {
            
            if (_fileList.count>3) {
                _autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromRightEdge];
            }
            
        }
    }
    // if no autoscrolling, stop and clear timer
    if (_autoscrollDistance == 0)
    {
        [_autoscrollTimer invalidate];
        _autoscrollTimer = nil;
    }
    
    // otherwise create and start timer (if we don't already have a timer going)
    else if (_autoscrollTimer == nil)
    {
        _autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                                            target:self
                                                          selector:@selector(autoscrollTimerFired:)
                                                          userInfo:thumb
                                                           repeats:YES];
    }
}

- (float)autoscrollDistanceForProximityToEdge:(float)proximity
{
    
    // the scroll distance grows as the proximity to the edge decreases, so that moving the thumb
    // further over results in faster scrolling.
    return ceilf((AUTOSCROLL_THRESHOLD - proximity) / 5.0);
}

- (void)legalizeAutoscrollDistance
{
    // makes sure the autoscroll distance won't result in scrolling past the content of the scroll view
    float minimumLegalDistance = [self.videoThumbSlider contentOffset].x * -1;
    float maximumLegalDistance = [self.videoThumbSlider contentSize].width - ([self.videoThumbSlider frame].size.width
                                                                              + [self.videoThumbSlider contentOffset].x);
    _autoscrollDistance = MAX(_autoscrollDistance, minimumLegalDistance);
    _autoscrollDistance = MIN(_autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer
{
    //return;
    
    [self legalizeAutoscrollDistance];
    // autoscroll by changing content offset
    CGPoint contentOffset = [self.videoThumbSlider contentOffset];
    contentOffset.x += _autoscrollDistance;
    [self.videoThumbSlider setContentOffset:contentOffset];
    
    RDThumbImageView *thumb = (RDThumbImageView *)[timer userInfo];
    [thumb moveByOffset:CGPointMake(_autoscrollDistance, 0) withEvent:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    [_videoThumbSlider.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDThumbImageView class]]) {
            RDThumbImageView *thumbView = (RDThumbImageView *)obj;
            thumbView.thumbIconView.image = nil;
        }
        [obj removeFromSuperview];
    }];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}
@end
