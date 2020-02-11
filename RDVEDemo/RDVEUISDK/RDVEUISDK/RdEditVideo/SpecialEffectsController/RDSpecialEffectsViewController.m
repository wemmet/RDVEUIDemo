//
//  SpecialEffectsViewController.m
//  RDVEUISDK
//
//  Created by apple on 2018/12/25.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#define kIconTag 1000
#define kProgressViewTag    999
#define kSelectedIVTag  666
#define kScrollViewTag  2000

#define kFreezeFrameFxId 575550 //后台返回的“定格”特效分类id

#import "RDSpecialEffectsViewController.h"
#import "RDVECore.h"
#import "RDSVProgressHUD.h"
#import "RD_VideoThumbnailView.h"
#import "RDMBProgressHUD.h"
#import "RDATMHud.h"
#import "UIImageView+RDWebCache.h"
#import "RDGenSpecialEffect.h"
#import "CircleView.h"
#import "RDFileDownloader.h"
#import "RDZipArchive.h"

#import "RDNavigationViewController.h"
#import "RDExportProgressView.h"
@interface RDSpecialEffectsViewController()<RD_VideoThumbnailViewDelegate,RDMBProgressHUDDelegate,UIScrollViewDelegate,RDVECoreDelegate>
{
    NSMutableArray<RDScene *>       *scenes;
    NSMutableArray  *EffectVideothumbTimes;
    //特效视频
    BOOL                    iFXsmodify;                 //是否修改特效
    UIScrollView            * fxTypeScrollView;
    UIScrollView            * fxScrollView ;
    UILabel                 * tipLbl;
    NSMutableArray          * fxArray;
    NSInteger                 selectedTypeIndex;
    UIButton                * FXPlayBtn;
    //动感界面
    CMTime                  filterseekTime;
    float                   _FXHeight;
    
    RDCustomFilter          * currentCustomFilter;
    //时间界面
    UIScrollView            * timeScrollFxView;
    UIImageView             * selectedTimeFxView;       //选中标志
    
    TimeFilterType           CurrentfileTimeFilterType;
    CMTime                   startTimeEffect;
    CMTimeRange              _fileTimeTimeRange;
    CMTime                   seekTime;
    
    BOOL                    cancel;
    NSInteger                 selectedFilterFxIndex;
    int                       selectedFxId;
    
    RD_VideoThumbnailView   * _videoThumbnailView;      //进度条
    
    UIView                  * toolBarView;
    
    UIView                  *MainCircleView;
    RDMBProgressHUD         *ProgressHUD;
    
    RDVECore                *thumbImageVideoCore;//截取缩率图
    
    BOOL                     isRecoveryTimeEffect;                 //是否恢复时间特效
    BOOL                     isFirst;
    BOOL                     isRefreshFxScrollCompletion;
    
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
}

@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic       )UIAlertView      *commonAlertView;
@property(nonatomic,strong)RDATMHud         *hud;

@property (nonatomic, strong) RDExportProgressView *exportProgressView;
@end

@implementation RDSpecialEffectsViewController

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgressView){
        __block typeof(self) myself = self;
        [_videoCoreSDK cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                //移除 “取消导出框”
                [myself.commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
            });
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_videoThumbnailView removeFromSuperview];
    _videoThumbnailView = nil;

    [EffectVideothumbTimes removeAllObjects];
    EffectVideothumbTimes = nil;

    [scenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.customFilter = nil;
        }];
    }];
    [scenes removeAllObjects];
    scenes = nil;
    
    [_videoCoreSDK stop];
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK.delegate = nil;
    _videoCoreSDK = nil;
    
    [thumbImageVideoCore cancelImage];
    [thumbImageVideoCore stop];
    thumbImageVideoCore.delegate = nil;
    thumbImageVideoCore = nil;
    
    currentCustomFilter = nil;
    selectedTimeFxView.image = nil;
    _commonAlertView.delegate = nil;
    _commonAlertView = nil;
    [_hud releaseHud];
    _hud.delegate = nil;
    _hud = nil;
    
    _file = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    isFirst = YES;
    iFXsmodify = NO;
    selectedTypeIndex = 1;
    _FXHeight = kHEIGHT/4.0;
    _exportSize = [RDHelpClass getEditSizeWithFile:_file];
    [self.view addSubview:self.playButton];
    
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
#if isUseCustomLayer
    if (_file.fileType == kTEXTTITLE) {
        _file.imageTimeRange = CMTimeRangeMake(kCMTimeZero, _file.imageTimeRange.duration);
    }
#endif
    thumbImageVideoCore = [self getRdPlayer];
    _videoCoreSDK = [self getRdPlayer];
    [self.view insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
    [self initToolBarView];
    [self initVideoThumbnailView];
    [self.view addSubview:self.FXPlayBtn];
    [self initFxScrollView];
    RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
        fxArray = [RDHelpClass getFxArrayWithAppkey:nav.appKey
                                        typeUrlPath:nav.editConfiguration.netMaterialTypeURL
                               specialEffectUrlPath:nav.editConfiguration.specialEffectResourceURL];
        __block NSInteger index = -1;
        [fxArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"typeId"] intValue] == 575550) {
                index = idx;
                *stop = YES;
            }
        }];
        //定格
        if (index >= 0) {
            [fxArray removeObjectAtIndex:index];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshFxTypeScrollView];
            [self refreshFxScrollView];
            if ([lexiu currentReachabilityStatus] == RDNotReachable) {
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
            }
        });
    });
}

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:nil];
        [self.view addSubview:_hud.view];
    }
    [self.view bringSubviewToFront:_hud.view];
    return _hud;
}

- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton new];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake((kWIDTH - 56)/2.0, (kWIDTH - 56)/2.0, 56, 56);
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    _playButton.hidden = YES;
    return _playButton;
}

- (void)initToolBarView{
    toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    [self.view addSubview:toolBarView];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
    [backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:backBtn];
    
    UIButton *finishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 64, 0, 64, 44)];
    [finishBtn addTarget:self action:@selector(finishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        toolBarView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44);
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        gradientLayer.locations = @[@0.3, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1.0);
        gradientLayer.frame = toolBarView.bounds;
        [toolBarView.layer addSublayer:gradientLayer];
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
        titleLbl.text = RDLocalizedString(@"特效", nil);
        titleLbl.textColor = [UIColor whiteColor];
        titleLbl.font = [UIFont boldSystemFontOfSize:20.0];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        [toolBarView addSubview:titleLbl];
        
        [backBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
        [backBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回点击_"] forState:UIControlStateHighlighted];
        
        finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];

        fxTypeScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, kHEIGHT - kToolbarHeight, kWIDTH - 20*2, 44)];
        [self.view addSubview:fxTypeScrollView];
    }else {
        toolBarView.backgroundColor = TOOLBAR_COLOR;
        [backBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑-裁切关闭默认_"] forState:UIControlStateNormal];
        [backBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑-裁切关闭点击_"] forState:UIControlStateHighlighted];
        
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑-裁切确定默认_"] forState:UIControlStateNormal];
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑-裁切确定点击_"] forState:UIControlStateHighlighted];

        fxTypeScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(64, kHEIGHT - kToolbarHeight, kWIDTH - 64*2, 44)];
        [self.view addSubview:fxTypeScrollView];
    }
    [finishBtn addTarget:self action:@selector(finishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    
    fxTypeScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(64, kHEIGHT - kToolbarHeight, kWIDTH - 64*2, 44)];
    fxTypeScrollView.showsVerticalScrollIndicator  =NO;
    fxTypeScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:fxTypeScrollView];
}

- (void)initFxScrollView {
    fxScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kHEIGHT - _FXHeight - kToolbarHeight + _FXHeight/3.0 - 5, kWIDTH, _FXHeight*2.0/3.0)];
    fxScrollView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    fxScrollView.showsVerticalScrollIndicator = NO;
    fxScrollView.showsHorizontalScrollIndicator = NO;
    fxScrollView.scrollEnabled = NO;
    [self.view addSubview:fxScrollView];
    
    //提示语
    tipLbl = [[UILabel alloc] initWithFrame: CGRectMake(15, fxScrollView.frame.origin.y, kWIDTH-30, 29)];
    tipLbl.text = [NSString stringWithFormat:RDLocalizedString(@"点击添加%@特效",nil), RDLocalizedString(@"动感", nil)];
    tipLbl.textAlignment = NSTextAlignmentLeft;
    tipLbl.font = [UIFont boldSystemFontOfSize:12];
    tipLbl.textColor = [UIColor whiteColor];
    [self.view addSubview:tipLbl];
}

- (void)refreshFxTypeScrollView {
    NSMutableArray *typeArray = [fxArray mutableCopy];
    if (!typeArray) {
        typeArray = [NSMutableArray array];
    }
    if(_file.fileType == kFILEVIDEO) {
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"时间", nil),@"typeName", nil];
        [typeArray addObject:dic];
    }
    float width = 0.0;
    if (typeArray.count < 5) {
        width = fxTypeScrollView.bounds.size.width / typeArray.count;
    }else {
        width = fxTypeScrollView.bounds.size.width / 4.0;
    }
    [typeArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake(idx*width, 0, width, fxTypeScrollView.bounds.size.height);
        [itemBtn setTitle:obj[@"typeName"] forState:UIControlStateNormal];
        [itemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [itemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        itemBtn.tag = idx + 1;
        if (idx == 0) {
            itemBtn.selected = YES;
        }
        [itemBtn addTarget:self action:@selector(typeItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [fxTypeScrollView addSubview:itemBtn];
    }];
    fxTypeScrollView.contentSize = CGSizeMake(typeArray.count*width, 0);
}

- (void)refreshFxScrollView {
    [fxArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *array = obj[@"data"];
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(idx * fxScrollView.bounds.size.width, 20, fxScrollView.bounds.size.width, fxScrollView.bounds.size.height)];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.tag = idx + kScrollViewTag;
        [fxScrollView addSubview:scrollView];
        
        float height = fxScrollView.frame.size.height - 29;
        float width = height*4.0/8.0;
        float imageWidth = height*4.0/8.0;
        float textHeight = height*3.0/8.0;
        [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *fxItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            fxItemBtn.frame = CGRectMake(idx * (width+10) + 10, (fxScrollView.bounds.size.height - height)/2.0, width, height);
            {
                UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth, width, textHeight)];
                label1.textAlignment = NSTextAlignmentCenter;
                label1.textColor = [UIColor whiteColor];
                if(idx == 0){
                    label1.text = @"无";
                }else {
                    label1.text = obj[@"name"];
                }
                label1.font = [UIFont systemFontOfSize:10];
                [fxItemBtn addSubview:label1];
            }
            fxItemBtn.tag = idx + 1;
            [fxItemBtn addTarget:self action:@selector(addFilterFx:) forControlEvents:UIControlEventTouchUpInside];
            
            UIImageView *thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((width - imageWidth)/2.0, 0, imageWidth, imageWidth)];
            if(idx == 0){
                thumbnailIV.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/effect_icon/剪辑-编辑-特效-无" Type:@"png"]];
            }else{
                [thumbnailIV rd_sd_setImageWithURL:[NSURL URLWithString:obj[@"cover"]]];
            }
            thumbnailIV.layer.cornerRadius = (imageWidth)/2.0;
            thumbnailIV.layer.masksToBounds = YES;
            thumbnailIV.tag = kIconTag;
            [fxItemBtn addSubview:thumbnailIV];
            
            [scrollView addSubview:fxItemBtn];
        }];
        
        UIImageView *selectedFxView = [[UIImageView alloc] initWithFrame:CGRectMake(width - 27 + 10, width - 27/2.0, 27, 27)];
        selectedFxView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/特效-选中勾_"];
        selectedFxView.tag = kSelectedIVTag;
        [scrollView addSubview:selectedFxView];
        
        scrollView.contentSize = CGSizeMake(array.count * (width+10) + 10, 0);
    }];
    
    if (_file.fileType == RDAssetTypeVideo) {
        [self initTimeFxView];
        fxScrollView.contentSize = CGSizeMake((fxArray.count + 1)*fxScrollView.bounds.size.width, 0);
    }else {
        fxScrollView.contentSize = CGSizeMake(fxArray.count*fxScrollView.bounds.size.width, 0);
    }
    if(_file.customFilterId != 0 )
    {
        [fxArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if (_file.customFilterId == [obj1[@"id"] intValue]) {
                    UIButton *typeBtn = [fxTypeScrollView viewWithTag:idx + 1];
                    [self typeItemBtnAction:typeBtn];
                    UIScrollView *scrollView = [fxScrollView viewWithTag:idx + kScrollViewTag];
                    UIButton *itemBtn = [scrollView viewWithTag:idx1 + 1];
                    [self addFilterFx:itemBtn];
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
    }
    isRefreshFxScrollCompletion = YES;
    if (!isFirst) {
        [RDSVProgressHUD dismiss];
    }
}

- (void)initTimeFxView {
    float toolItemBtnHeight = fxScrollView.frame.size.height - 29;
    float toolItemWidth = toolItemBtnHeight*4.0/8.0;
    float imageWidth = toolItemBtnHeight*4.0/8.0;
    float textHeight = toolItemBtnHeight*3.0/8.0;
    
    timeScrollFxView = [[UIScrollView alloc] initWithFrame:CGRectMake(fxArray.count*fxScrollView.bounds.size.width, 20, fxScrollView.bounds.size.width, fxScrollView.bounds.size.height)];
    [fxScrollView addSubview:timeScrollFxView];
    NSArray *timeFxArray = [NSArray arrayWithObjects:
                            @"无",
                            @"慢动作",
                            @"反复",
                            //@"倒序",
                            nil];
    
    [timeFxArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *fxItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        fxItemBtn.frame = CGRectMake( idx * (toolItemWidth+10) + 10 , (fxScrollView.bounds.size.height - toolItemBtnHeight)/2.0, toolItemWidth, toolItemBtnHeight);
        fxItemBtn.backgroundColor = [UIColor clearColor];
        {
            UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth, toolItemWidth, textHeight)];
            
            label1.textAlignment = NSTextAlignmentCenter;
            label1.textColor = [UIColor whiteColor];
            label1.text = RDLocalizedString([timeFxArray objectAtIndex:idx],nil);
            label1.font = [UIFont systemFontOfSize:(iPhone4s ? 9 : 10)];
            [fxItemBtn addSubview:label1];
            
            UIImage * image = nil;
            UIImageView *thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((fxItemBtn.frame.size.width - imageWidth)/2.0, 0, imageWidth, imageWidth)];
            image = [RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"/jianji/effect_icon/剪辑-编辑-特效-%@", [timeFxArray objectAtIndex:idx]]];
            thumbnailIV.image = image;
            thumbnailIV.layer.cornerRadius = imageWidth/2.0;
            thumbnailIV.layer.masksToBounds = YES;
            thumbnailIV.tag = kIconTag;
            [fxItemBtn addSubview:thumbnailIV];
        }
        fxItemBtn.tag = idx + 1;
        [fxItemBtn addTarget:self action:@selector(timeFxItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self->timeScrollFxView addSubview:fxItemBtn];
    }];
    timeScrollFxView.contentSize = CGSizeMake(timeFxArray.count*(toolItemWidth+10), 0);
    timeScrollFxView.showsVerticalScrollIndicator = NO;
    timeScrollFxView.showsHorizontalScrollIndicator = NO;
    
    selectedTimeFxView = [[UIImageView alloc] initWithFrame:CGRectMake(toolItemWidth - 27 + 10, toolItemWidth - 27/2.0, 27, 27)];
    selectedTimeFxView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/特效-选中勾_"];
    [timeScrollFxView addSubview:selectedTimeFxView];
    
    if( _file.fileTimeFilterType !=  kTimeFilterTyp_None )
    {
        isRecoveryTimeEffect = true;
        for (UIView *view in timeScrollFxView.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"UIButton")]) {
                UIButton * fxItemBtn = (UIButton*)view;
                if( (fxItemBtn.tag - 1) == _file.fileTimeFilterType )
                    [self timeFxItemBtnAction:fxItemBtn];
            }
        }
    }
}

- (UIButton *)FXPlayBtn{
    if(!FXPlayBtn){
        FXPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        FXPlayBtn.backgroundColor = [UIColor clearColor];
        FXPlayBtn.frame = CGRectMake(5, _videoThumbnailView.frame.origin.y, _FXHeight/3.0 - 10, _FXHeight/3.0 - 10);
        
        [FXPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [FXPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [FXPlayBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return FXPlayBtn;
}

- (void)initVideoThumbnailView {
    _videoThumbnailView = [[RD_VideoThumbnailView alloc] initWithFrame:CGRectMake( (iPhone4s ? 40 : 60) + 5, kHEIGHT - _FXHeight - kToolbarHeight + 5, kWIDTH - ((iPhone4s ? 40 : 60)) - 15, _FXHeight/3.0 - 10 )];
    _videoThumbnailView.trackColor = SCREEN_BACKGROUND_COLOR;
    _videoThumbnailView.borderHeight = 4.5;
    _videoThumbnailView.thumbnailProportion = 1.0;
    _videoThumbnailView.delegate = self;
    _videoThumbnailView.duration = _videoCoreSDK.duration;
    _videoThumbnailView.progress = 0;
    _videoThumbnailView.trackInImage = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/滤镜特效-001_调节条点击_"];
    _videoThumbnailView.trackOutImage = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/滤镜特效-001_调节条默认_"];
    __weak RDSpecialEffectsViewController *myself = self;
    _videoThumbnailView.trackMoveBegin = ^(float progress){
        dispatch_async(dispatch_get_main_queue(), ^{
            [myself playVideo:NO];
        });
    };
    _videoThumbnailView.trackMoving = ^(float progress){
        dispatch_async(dispatch_get_main_queue(), ^{
            CMTime time = CMTimeMakeWithSeconds(myself.videoCoreSDK.duration *progress, TIMESCALE);
            
            [myself.videoCoreSDK seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        });
    };
    _videoThumbnailView.trackMoveEnd  = ^(float progress){
        //滑动结束不自动播放
        dispatch_async(dispatch_get_main_queue(), ^{
            CMTime time = CMTimeMakeWithSeconds(myself.videoCoreSDK.duration *progress, TIMESCALE);
            [myself.videoCoreSDK filterRefresh:time];
        });
        
    };
    [self.view addSubview:_videoThumbnailView];
    
    EffectVideothumbTimes = [NSMutableArray array];
    NSInteger num = 0;
    while (num<(_videoThumbnailView.thumbnailTimes.count-1)) {
        [EffectVideothumbTimes addObject:@(num)];
        num +=1;
    }
    [EffectVideothumbTimes addObject:@(thumbImageVideoCore.duration)];
    NSInteger index = 0;
    [thumbImageVideoCore getImageAtTime:kCMTimeZero scale:0.2 completion:^(UIImage * image) {
        [self->_videoThumbnailView refreshThumbImage:index thumbImage:image];
    }];
    
    [self setEffectForVideoMetadataFxArray];
    
    [_videoThumbnailView setEffectType:kFilterEffect];
}
/**根据_videoMetadata.fxArray设置特效
 *
 */
- (void)setEffectForVideoMetadataFxArray{
    [self playVideo:NO];
    [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
    }];
    _videoThumbnailView.hasChangeEffect = NO;
    //[_videoCoreSDK build];
}

- (RDVECore *)getRdPlayer {
    [scenes removeAllObjects];
    scenes = nil;
    scenes = [NSMutableArray array];
    
    RDScene *scene = [[RDScene alloc] init];
    
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = _file.contentURL;
    
    if ( !((RDNavigationViewController *)self.navigationController).isSingleFunc ) {
        if (_globalFilters.count > 0) {
            RDFilter* filter = _globalFilters[_file.filterIndex];
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
    }
    
    if(_file.fileType == kFILEVIDEO){
        vvasset.videoActualTimeRange = _file.videoActualTimeRange;
        vvasset.type = RDAssetTypeVideo;
        [RDVECore assetMetadata:_file.contentURL];
        
        if(_file.isReverse){
            vvasset.url = _file.reverseVideoURL;
            if (CMTimeRangeEqual(kCMTimeRangeZero, _file.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.reverseDurationTime);
            }else{
                vvasset.timeRange = _file.reverseVideoTimeRange;
            }
            if(CMTimeCompare(vvasset.timeRange.duration, _file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(_file.reverseVideoTrimTimeRange.duration)>0){
                vvasset.timeRange = _file.reverseVideoTrimTimeRange;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, _file.videoDurationTime);
            }else{
                vvasset.timeRange = _file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, _file.videoTrimTimeRange.duration) == 1){
                vvasset.timeRange = _file.videoTrimTimeRange;
            }
        }
        vvasset.speed        = _file.speed;
        vvasset.volume       = _file.videoVolume;
    }else{
        vvasset.type         = RDAssetTypeImage;
        if (CMTimeCompare(_file.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = _file.imageTimeRange;
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, _file.imageDurationTime);
        }
        vvasset.speed        = _file.speed;
#if isUseCustomLayer
        if (_file.fileType == kTEXTTITLE) {
            _file.imageTimeRange = vvasset.timeRange;
            vvasset.fillType = RDImageFillTypeFull;
        }
#endif
    }
    vvasset.rotate = _file.rotate;
    vvasset.isVerticalMirror = _file.isVerticalMirror;
    vvasset.isHorizontalMirror = _file.isHorizontalMirror;
    vvasset.crop = _file.crop;
    
    vvasset.brightness = _file.brightness;
    vvasset.contrast = _file.contrast;
    vvasset.saturation = _file.saturation;
    vvasset.sharpness = _file.sharpness;
    vvasset.whiteBalance = _file.whiteBalance;
    vvasset.vignette = _file.vignette;
    
    [scene.vvAsset addObject:vvasset];
    [scenes addObject:scene];
    
     RDVECore *rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_exportSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
    
    rdPlayer.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
    rdPlayer.delegate = self;
    [rdPlayer setScenes:scenes];
    [rdPlayer build];
    return rdPlayer;
}

- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)playVideo:(BOOL)play{
    
    if(play){
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
        
        [FXPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
    }else{
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [FXPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        if(sender == _videoCoreSDK){
            if (isFirst) {
                isFirst = NO;
                if (isRefreshFxScrollCompletion) {                    
                    [RDSVProgressHUD dismiss];
                }
            }else {
                [RDSVProgressHUD dismiss];
                if(selectedTypeIndex <= fxArray.count)
                {
                    __weak typeof(self) weakSelf = self;
                    [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
//                        [weakSelf playVideo:YES];
                    }];
                }
                else
                {
                    if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
//                        [self playVideo:YES];
                    }else {
                        CMTime time = seekTime;
                        seekTime = kCMTimeZero;
                        __weak typeof(self) weakSelf = self;
                        [_videoCoreSDK seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
//                            [weakSelf playVideo:YES];
                        }];
                    }
                }
            }
        }else {
            [self loadTrimmerViewThumbImage];
        }
    }
}

/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    if([_videoCoreSDK isPlaying]){
        float progress = CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration;
        if( sender == _videoCoreSDK )
        {
            if(_videoThumbnailView)
                [_videoThumbnailView setProgress:progress];
        }
    }
}
#if isUseCustomLayer
- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    [RDHelpClass refreshCustomTextLayerWithCurrentTime:currentTime customDrawLayer:customDrawLayer fileLsit:@[_file]];
}
#endif
/**播放结束
 */
- (void)playToEnd{
    [_videoCoreSDK seekToTime:kCMTimeZero];
    [_videoThumbnailView setProgress:0];
    [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [FXPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
}

/**点击播放器
 */
- (void)tapPlayerView{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    
    
}
#pragma mark-提示消息处理
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

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 1:
            if(buttonIndex == 1){
            }
            break;
        case 2:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [_exportProgressView setProgress:0 animated:NO];
                [_exportProgressView removeFromSuperview];
                _exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:idleTimerDisabled];
                [_videoCoreSDK cancelExportMovie:nil];
            }
            break;
        case 7:
        {
            if(buttonIndex == 1){
                if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                //[self dismissViewControllerAnimated:YES completion:nil];
            }
        }
            break;
        default:
            break;
    }
}
#pragma mark - RDVideoThumbnailViewDelegate

- (void)timeEffectChangeBegin:(CMTimeRange)timerange{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    [_videoCoreSDK stop];
}


- (void)timeEffectchanged:(NSInteger)type timeRange:(CMTimeRange)timeRange{
    [self refreshVideoCoreWithTimeEffectType:type timeEffectTimeRange:timeRange];//20170901
    seekTime = timeRange.start;
}
#pragma mark- 按钮事件
- (void)typeItemBtnAction:(UIButton *)sender {
    if (sender.tag != selectedTypeIndex) {
        UIButton *prevBtn = [fxTypeScrollView viewWithTag:selectedTypeIndex];
        prevBtn.selected = NO;
        sender.selected = YES;
        selectedTypeIndex = sender.tag;
        fxScrollView.contentOffset = CGPointMake((sender.tag - 1) * fxScrollView.bounds.size.width, 0);
        if (selectedTypeIndex > fxArray.count) {
            [_videoThumbnailView setEffectType:kTimeEffect];
            tipLbl.text = [NSString stringWithFormat:RDLocalizedString(@"点击添加%@特效",nil), RDLocalizedString(@"时间", nil)];
        }else {
            [_videoThumbnailView setEffectType:kFilterEffect];
            tipLbl.text = [NSString stringWithFormat:RDLocalizedString(@"点击添加%@特效",nil), RDLocalizedString(@"动感", nil)];
        }
    }
}

- (void)backBtnAction:(UIButton *)sender
{
    //退出特效
    if( !iFXsmodify )
    {
        if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }else {
            [self.navigationController popViewControllerAnimated:NO];
        }
        //[self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"您确定要放弃编辑吗?",nil)
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"取消",nil)
                         otherButtonTitles:RDLocalizedString(@"确定",nil)
                              alertViewTag:7];
    }
}

-(void)finishBtnAction:(UIButton *)sender
{
    if(((RDNavigationViewController *)self.navigationController).isSingleFunc && ((RDNavigationViewController *)self.navigationController).callbackBlock){
        [self exportMovie];
    }else
    {
        [self.navigationController popViewControllerAnimated:NO];
        //[self dismissViewControllerAnimated:YES completion:nil];
        
        if (_changeSpecialEffectFinish) {
            _changeSpecialEffectFinish(selectedFilterFxIndex, selectedFxId,CurrentfileTimeFilterType,_fileTimeTimeRange,false);
        }
    }
}

#pragma mark-添加时间特效
- (void)timeFxItemBtnAction:(UIButton *)sender {
    TimeFilterType timeEffectType = sender.tag - 1;
    if( timeEffectType == CurrentfileTimeFilterType )
    {
        return;
    }
    CGRect frame = selectedTimeFxView.frame;
    frame.origin.x = sender.frame.origin.x + sender.frame.size.width - frame.size.width;
    selectedTimeFxView.frame = frame;
    [self playVideo:NO];
    [_videoCoreSDK stop];
    iFXsmodify = true;
    
    CurrentfileTimeFilterType = timeEffectType;
    startTimeEffect = kCMTimeZero;
    
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(addTimeEffect) object:nil];
    [self performSelector:@selector(addTimeEffect) withObject:nil afterDelay:0.2];
    
    
}
- (void)addTimeEffect{//20170901
    
    if( ( (CurrentfileTimeFilterType == kTimeFilterTyp_Reverse) || (CurrentfileTimeFilterType == kTimeFilterTyp_Repeat) ) && (_file.reverseVideoURL == nil) )
    {
        [self InitMainCircleView];
        cancel  = false;
        NSString * exportPath = [RDGenSpecialEffect ExportURL:_file];
        [RDVECore exportReverseVideo:_file.contentURL outputUrl: [NSURL fileURLWithPath:exportPath]  timeRange:_file.videoTimeRange videoSpeed:1.0 progressBlock:^(NSNumber *prencent) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if( self->ProgressHUD != nil )
                    self->ProgressHUD.progress = [prencent floatValue];
            });
        } callbackBlock:^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                self->MainCircleView.hidden = YES;
                self->_file.reverseVideoURL = [NSURL fileURLWithPath:exportPath];
                
                CMTimeRange effectTimeRange = kCMTimeRangeZero;
                if (self->CurrentfileTimeFilterType == kTimeFilterTyp_None) {
                    [self->_videoThumbnailView annulTimeEffect];
                }else {
                    AVURLAsset *asset;
                    if (self->CurrentfileTimeFilterType == kTimeFilterTyp_Reverse) {
                        asset = [AVURLAsset assetWithURL:self->_file.reverseVideoURL];
                        effectTimeRange = CMTimeRangeMake(kCMTimeZero, self->_file.videoTimeRange.duration);
                    }else {
                        asset = [AVURLAsset assetWithURL:self->_file.contentURL];
                        Float64 duration = CMTimeGetSeconds(self->_file.videoTimeRange.duration);
                        effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(duration/2.0 - (duration/5.0/2.0), TIMESCALE), CMTimeMakeWithSeconds(duration/5.0, TIMESCALE));
                    }
                    
                    if(CMTimeCompare(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), asset.duration) == 1){
                        effectTimeRange.duration = CMTimeSubtract(asset.duration, effectTimeRange.start);
                    }
                    if( isRecoveryTimeEffect )
                    {
                        iFXsmodify = false;
                        isRecoveryTimeEffect = false;
                        effectTimeRange = _file.fileTimeFilterTimeRange;
                    }
                    [self->_videoThumbnailView addTimeEffect:(self->CurrentfileTimeFilterType + 1) color:UIColorFromRGB(0x1fb6ff) withTimeRange:effectTimeRange];
                    self->_videoThumbnailView.hasChangeEffect = YES;
                    effectTimeRange = [self->_videoThumbnailView getTimeEffectTimeRange];
                }
                [self refreshVideoCoreWithTimeEffectType:self->CurrentfileTimeFilterType timeEffectTimeRange:effectTimeRange];
                self->seekTime = effectTimeRange.start;
                self->startTimeEffect = self->seekTime;
            });
        } fail:^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                self->MainCircleView.hidden = YES;
                CurrentfileTimeFilterType = kTimeFilterTyp_None;
                for (UIView *view in timeScrollFxView.subviews) {
                    if ([view isKindOfClass:NSClassFromString(@"UIButton")]) {
                        UIButton * fxItemBtn = (UIButton*)view;
                        if( (fxItemBtn.tag - 1) == kTimeFilterTyp_None )
                            [self timeFxItemBtnAction:fxItemBtn];
                    }
                }
            });
        } cancel:&cancel];
        return;
    }
    
    CMTimeRange effectTimeRange = kCMTimeRangeZero;
    if (CurrentfileTimeFilterType == kTimeFilterTyp_None) {
        [_videoThumbnailView annulTimeEffect];
    }else {
        AVURLAsset *asset;
        if (CurrentfileTimeFilterType == kTimeFilterTyp_Reverse) {
            asset = [AVURLAsset assetWithURL:_file.reverseVideoURL];
            effectTimeRange = CMTimeRangeMake(kCMTimeZero, _file.videoTimeRange.duration);
        }else {
            asset = [AVURLAsset assetWithURL:_file.contentURL];
            Float64 duration = CMTimeGetSeconds(_file.videoTimeRange.duration);
            effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(duration/2.0 - (duration/5.0/2.0), TIMESCALE), CMTimeMakeWithSeconds(duration/5.0, TIMESCALE));
        }
        
        if(CMTimeCompare(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), asset.duration) == 1){
            effectTimeRange.duration = CMTimeSubtract(asset.duration, effectTimeRange.start);
        }
        
        if( isRecoveryTimeEffect )
        {
            iFXsmodify = false;
            isRecoveryTimeEffect = false;
            effectTimeRange = _file.fileTimeFilterTimeRange;
        }
        
        
        [_videoThumbnailView addTimeEffect:(CurrentfileTimeFilterType + 1) color:UIColorFromRGB(0x1fb6ff) withTimeRange:effectTimeRange];
        _videoThumbnailView.hasChangeEffect = YES;
        effectTimeRange = [_videoThumbnailView getTimeEffectTimeRange];
    }
    [self refreshVideoCoreWithTimeEffectType:CurrentfileTimeFilterType timeEffectTimeRange:effectTimeRange];
    seekTime = effectTimeRange.start;
    startTimeEffect = seekTime;
}
#pragma mark-进度提示
-(void)InitMainCircleView
{
    if ( MainCircleView != nil ) {
        MainCircleView = nil;
        ProgressHUD = nil;
    }
    
    MainCircleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    MainCircleView.backgroundColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    //圆形进度条
    ProgressHUD = [[RDMBProgressHUD alloc] initWithView:MainCircleView];
    ProgressHUD.frame = CGRectMake((kWIDTH-kWIDTH/2.0)/2.0, (kHEIGHT-kWIDTH/3.0)/2.0, kWIDTH/2.0, kWIDTH/3.0);
    [MainCircleView addSubview:ProgressHUD];
    ProgressHUD.removeFromSuperViewOnHide = YES;
    ProgressHUD.mode = RDMBProgressHUDModeDeterminate;//MBProgressHUDModeAnnularDeterminate;
    ProgressHUD.animationType = RDMBProgressHUDAnimationFade;
    ProgressHUD.labelText = RDLocalizedString(@"倒放处理中，请稍等...",nil);
    ProgressHUD.labelFont = [UIFont boldSystemFontOfSize:10];
    ProgressHUD.isShowCancelBtn = YES;
    ProgressHUD.delegate = self;
    [ProgressHUD show:YES];
    [self.view addSubview:MainCircleView];
    [MainCircleView setHidden:NO];
}
- (void)cancelDownLoad
{
    cancel  = true;
    MainCircleView.hidden = YES;
}

#pragma mark- 时间特效实现
- (void)refreshVideoCoreWithTimeEffectType:(TimeFilterType)timeEffectType timeEffectTimeRange:(CMTimeRange)effectTimeRange {
    NSLog(@"effectTimeRange start:%@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, effectTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, effectTimeRange.duration)));

    _fileTimeTimeRange = effectTimeRange;
    
    [RDGenSpecialEffect refreshVideoTimeEffectType:timeEffectType timeEffectTimeRange:effectTimeRange atscenes:scenes atFile:_file];
    //[self refreshVideoTimeEffectType:timeEffectType timeEffectTimeRange:effectTimeRange];
    [_videoCoreSDK setScenes:scenes];
    [_videoCoreSDK build];
}
#pragma mark - 添加动感特效
- (void)addFilterFx:(UIButton *)fxItemBtn {
    NSDictionary *itemDic = [[fxArray[selectedTypeIndex - 1] objectForKey:@"data"] objectAtIndex:fxItemBtn.tag - 1];
    if ([itemDic[@"id"] intValue] == selectedFxId) {
        return;
    }
    NSString *path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
    NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
    if (fxItemBtn.tag != 1 && fileCount == 0) {
        UIImageView *item = [fxItemBtn viewWithTag:kIconTag];
        CircleView *progressView = [item viewWithTag:kProgressViewTag];
        if(progressView){
            return;
        }
        CircleView *ddprogress = [[CircleView alloc]initWithFrame:item.bounds];
        ddprogress.progressColor = Main_Color;
        ddprogress.progressWidth = 2.f;
        ddprogress.progressBackgroundColor = [UIColor clearColor];
        ddprogress.tag = kProgressViewTag;
        [item addSubview:ddprogress];
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        
        __weak typeof(self) myself = self;
        [RDFileDownloader downloadFileWithURL:itemDic[@"file"] cachePath:path httpMethod:GET progress:^(NSNumber *numProgress) {
            NSLog(@"%lf",[numProgress floatValue]);
            [ddprogress setPercent:[numProgress floatValue]];
        } finish:^(NSString *fileCachePath) {
            NSLog(@"下载完成");
            BOOL suc =[RDHelpClass OpenZipp:fileCachePath unzipto:[fileCachePath stringByDeletingLastPathComponent]];
            [ddprogress removeFromSuperview];
            if(suc){
                if([myself downLoadingFilterEffectCount]>=1){
                    return ;
                }
                [myself addFilterFx:fxItemBtn];
            }
        } fail:^(NSError *error) {
            NSLog(@"下载失败");
            [myself.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [myself.hud show];
            [myself.hud hideAfter:2];
            [ddprogress removeFromSuperview];
        }];
    }else {
        selectedFilterFxIndex = fxItemBtn.tag;
        selectedFxId = [itemDic[@"id"] intValue];
        iFXsmodify = true;
        
        UIImageView *selectedFxView = [[fxScrollView viewWithTag:selectedTypeIndex - 1 + kScrollViewTag] viewWithTag:kSelectedIVTag];
        CGRect frame = selectedFxView.frame;
        frame.origin.x = fxItemBtn.frame.origin.x + fxItemBtn.frame.size.width - frame.size.width;
        selectedFxView.frame = frame;
        
        for (int i = 0; i < fxArray.count; i++) {
            if (i != selectedTypeIndex - 1) {
                UIScrollView *scrollView = [fxScrollView viewWithTag:i + kScrollViewTag];
                UIButton *firstBtn = [scrollView viewWithTag:1];
                UIImageView *selectedFxView = [scrollView viewWithTag:kSelectedIVTag];
                CGRect frame = selectedFxView.frame;
                frame.origin.x = firstBtn.frame.origin.x + firstBtn.frame.size.width - frame.size.width;
                selectedFxView.frame = frame;
            }
        }
        
        filterseekTime = _file.videoTimeRange.duration;
        [_videoThumbnailView setEffectType:kFilterEffect];
        currentCustomFilter = nil;
    
        if (selectedFilterFxIndex == 1) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource: @"RDVEUISDK" ofType :@"bundle"];
            NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
            path = [[resourceBundle resourcePath] stringByAppendingPathComponent:@"/jianji/effect_icon/shear/无"];
        }else {
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
            NSString *folderName;
            for (NSString *fileName in files) {
                if (![fileName isEqualToString:@"__MACOSX"]) {
                    NSString *folderPath = [path stringByAppendingPathComponent:fileName];
                    BOOL isDirectory = NO;
                    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory];
                    if (isExists && isDirectory) {
                        folderName = fileName;
                        break;
                    }
                }
            }
            path = [path stringByAppendingPathComponent:folderName];
        }
        NSString *itemConfigPath = [path stringByAppendingPathComponent:@"config.json"];
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:itemConfigPath];
        NSMutableDictionary *effectDic = [RDHelpClass objectForData:jsonData];
        jsonData = nil;
        
        NSArray *colorArray = effectDic[@"color"];
        UIColor *color = [RDHelpClass UIColorFromArray:colorArray];
        float duration = [effectDic[@"duration"] floatValue];
//        if (duration == 0.0) {
//            duration = 1.0;
//        }
        CMTimeRange timeRange = CMTimeRangeMake(_videoCoreSDK.currentTime, CMTimeMakeWithSeconds(((duration == 0.0))?1.0:duration, TIMESCALE));
        NSArray *textureParams = effectDic[@"textureParams"];
        __block UIImage *currentFrameTexture;
        [textureParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[obj objectForKey:@"paramName"] isEqualToString:@"currentFrameTexture"]) {
                //需要先截取当前帧
                currentFrameTexture = [_videoCoreSDK getCurrentFrameWithScale:1.0];
                *stop = YES;
            }
        }];
           NSString *currentFrameTexturePath;
        if (currentFrameTexture) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:kCurrentFrameTextureFolder]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:kCurrentFrameTextureFolder withIntermediateDirectories:YES attributes:nil error:nil];
            }
            currentFrameTexturePath = [RDHelpClass getFileUrlWithFolderPath:kCurrentFrameTextureFolder fileName:@"currentFrameTexture.jpg"].path;
            NSData* imagedata = UIImageJPEGRepresentation(currentFrameTexture, 1.0);
            [[NSFileManager defaultManager] createFileAtPath:currentFrameTexturePath contents:imagedata attributes:nil];
            imagedata = nil;
            
            UIImage *image = [RDHelpClass imageWithContentOfPath:currentFrameTexturePath];
            
            currentCustomFilter = [RDGenSpecialEffect getCustomFilerWithFxId:selectedFxId filterFxArray:fxArray timeRange:timeRange currentFrameTexturePath:currentFrameTexturePath];
        }else {
            if (duration == 0.0)
                currentCustomFilter = [RDGenSpecialEffect getCustomFilerWithFxId:selectedFxId filterFxArray:fxArray timeRange:CMTimeRangeMake(_videoCoreSDK.currentTime, CMTimeMakeWithSeconds(_videoCoreSDK.duration-CMTimeGetSeconds(_videoCoreSDK.currentTime), TIMESCALE))];
            else{
                currentCustomFilter = [RDGenSpecialEffect getCustomFilerWithFxId:selectedFxId filterFxArray:fxArray timeRange:timeRange];
            }
        }
        
        [_videoThumbnailView annulLastFilterEffect];
        [_videoThumbnailView addFilterEffect:selectedFxId color:color withTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE),CMTimeMakeWithSeconds(_videoCoreSDK.duration,TIMESCALE)) currentFrameTexturePath:currentFrameTexturePath];
        
        for (int j = 0; j < scenes.count; j++) {
            for ( int i = 0; i < scenes[j].vvAsset.count; i++) {
                scenes[j].vvAsset[i].customFilter = currentCustomFilter;
            }
        }
//        [self playVideo:YES];
    }
}

/**检测有多少个动感特效正在下载
 */
- (NSInteger)downLoadingFilterEffectCount{
    __block int count = 0;
    [fxScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIScrollView class]]){
            [obj.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj1 isKindOfClass:[UIImageView class]]) {
                    CircleView *progressView = [obj viewWithTag:kProgressViewTag];
                    if(progressView){
                        count +=1;
                    }
                }
            }];
        }
    }];
    NSLog(@"dwonloadingFilterEffectCount:%d",count);
    return count;
}

#pragma mark - 特效截图
- (void)loadTrimmerViewThumbImage{
    @autoreleasepool {
        Float64 durationPerFrame = thumbImageVideoCore.duration / (EffectVideothumbTimes.count*1.0);
        for (int i=0; i<EffectVideothumbTimes.count; i++){
            
            CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
            [EffectVideothumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
            
        }
        [self refreshThumb:EffectVideothumbTimes];
    }
}
- (void)refreshThumb:(NSArray *)imageTimes {
    [thumbImageVideoCore getImageWithTimes:[imageTimes mutableCopy] scale:0.1 completionHandler:^(UIImage *image, NSInteger idx) {
        if(!image){
            return;
        }
        NSLog(@"获取图片：%zd",idx);
        //图片更新 特效视频
        if(self->_videoThumbnailView)
            [self->_videoThumbnailView refreshThumbImage:idx thumbImage:image];
        if (idx == imageTimes.count - 1) {
            [self->thumbImageVideoCore stop];
            self->thumbImageVideoCore.delegate = nil;
        }
    }];
}
#pragma mark - 导出

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
       && _videoCoreSDK.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [self.hud setCaption:message];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && _videoCoreSDK.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
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
    
    [_videoCoreSDK stop];
    [_videoCoreSDK seekToTime:kCMTimeZero];
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress:0 animated:NO];
    
    CGSize size = CGSizeMake(_exportSize.width, _exportSize.height);
    [_videoCoreSDK setEditorVideoSize:size];
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:_videoCoreSDK totalDration:_videoCoreSDK.duration exportSize:size exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
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
    [_videoCoreSDK exportMovieURL:[NSURL fileURLWithPath:export]
                             size:size
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
    [_videoCoreSDK removeWaterMark];
    [_videoCoreSDK removeEndLogoMark];
    [_videoCoreSDK filterRefresh:kCMTimeZero];
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
    
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
        if(((RDNavigationViewController *)self.navigationController).callbackBlock){
            ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
        }
    }];
}

@end
