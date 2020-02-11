//
//  RDEditVideoViewController.m
//  RDVEUISDK
//
//  Created by emmet on 2017/6/26.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDEditVideoViewController.h"
#import "RDNextEditVideoViewController.h"
#import "RDVECore.h"
#import "RDATMHud.h"
#import "ComminuteViewController.h"
#import "ChangeSpeedVideoViewController.h"
#import "CropViewController.h"
#import "RD_SortViewController.h"
#import "RDTrimVideoViewController.h"
#import "RDThumbImageView.h"
#import "RDConnectBtn.h"
#import "RDZSlider.h"
#import "RDExportProgressView.h"
#import "RDMainViewController.h"
#import "CustomTextPhotoViewController.h"
#import "RDNavigationViewController.h"
#import "RDFilterViewController.h"
#import "RDAdjustViewController.h"
#import "RDSpecialEffectsViewController.h"
#import "RDGenSpecialEffect.h"
#import "RDTranstionCollectionViewCell.h"
#import "RDFileDownloader.h"
#import "RDZipArchive.h"
#import "RDHeaderView.h"
#import "RDFooterView.h"
#import "RDDownTool.h"
#import "CircleView.h"
#import "UIImageView+RDWebCache.h"

#import "RDAddItemButton.h"
#import "RDYYWebImage.h"
#define AUTOSCROLL_THRESHOLD 30

@interface RDEditVideoViewController ()<RDVECoreDelegate,RDThumbImageViewDelegate,RDAlertViewDelegate,UIActionSheetDelegate,CustomTextDelegate,UIAlertViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>{
    
    BOOL                    isPlaying;
    BOOL                    isCancelExportReverse;
    NSMutableArray          *toolItems;
    NSMutableArray          *connectToolItems;
    CGSize                  exportSize;
    NSInteger               selectFileIndex;
    EditVideoSizeType       editVideoSizeType;
    EditVideoSizeType       oldEditVideoSizeType;
    CGSize                  oldEditVideoSize;
    NSTimer                 * _autoscrollTimer;
    float                     _autoscrollDistance;
    CGPoint                 startTouchPoint;
    double                  startTouchTime;
    double                  startVideoSliderValue;
    RDThumbImageView        *deletedFileView;
    BOOL                    _idleTimerDisabled;
    NSMutableArray          *globalFilters;
    NSMutableArray          <RDScene *>*scenes;
    NSMutableArray          *filtersName;
    BOOL                     isNeedPrepare;
    NSMutableArray          *transitionList;
    
    int                     currentLabelTransitionIndex;
    
    NSString                * selectedTransitionTypeName;
    NSString                * selectedTransitionName;
    NSString                * prevTransitionName;   //用于取消随机转场
    UIScrollView            *transitionTypeScrollView;
    UIScrollView            *transitionScrollView;
    UIView                  *operationView;
    RDAddItemButton                *transitionNoneBtn;
    
    //转场
    UIView              *_bottomView;
    UIButton            *_defaultTranstionBtn;
    UIButton            *_useToAllTranstionBtn;
    UISlider            *_transtionDurationSlider;
    UILabel             *_transtionDurationLabel;
    double                  lastSelectIndexItemDuration;
    
    bool                isToolBarView;                      //是否 主功能
    NSMutableArray< RDThumbImageView *> *thumbViewItems;
    bool                isModifyTranstion;                  //是否修改转场
    bool                isTranstion;                        //是否在转场界面
    CMTime              seekTime;
    
    //转场
    CGRect              transitionRect;
    CGRect              transitionPlayButtonRect;
    CGRect              transitionPlayViewRect;
    
    //新滤镜
    NSMutableArray              *newFilterSortArray;
    NSMutableArray              *newFiltersNameSortArray;
    //音量
    float               volumeMultipleM;
    
    
    bool                isNewCoreSDK;
    RDVECore            *currentMinCoreSDK;
    CGSize              currentMinExportSize;
    
    NSLock              *fileLock;
    
    CMTime              nextVideoTime;
    bool                isRefresh;
    
    //转场
    CMTimeRange                     transitionTimeRange;
    
    BOOL                isRefeshNextThumbCore;          //s
    UIView              *assetVolumeView;
    UILabel             *fadeDurationLbel;
    
    //替换
    bool                isSeplace;
    bool                isAddTransitionBuild;   //转场添加是否需要build
    
    //动画
    UIView              *animationDurationView;
    UIButton            *_useToAllAnimationBtn;
    RDZSlider            *animationDurationSlider;
    UIButton            *defaultAnimationBtn;
    NSMutableArray      *animationArray;
    UILabel             *animationDurationLbl;
    UIScrollView        *animationScrollView;
    NSInteger            selectedAnimationIndex;
    
    CMTimeRange         animationTime;
    bool                isAnimation;        //动画
    
    CMTime              animationStartTime; //动画开始时间
    RDTranstionCollectionViewCell   *currentCell;
    
    bool                isFirst;
    
 }

@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)UIView           *playerView;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic,strong)UIScrollView     *toolBarView;
@property(nonatomic,strong)UILabel          *currentLabel;
@property(nonatomic,strong)UILabel          *durationLabel;

@property(nonatomic,strong)UIScrollView     *connectToolBarView;
@property(nonatomic,strong)UIButton         *addButton;

@property(nonatomic,strong)RDATMHud         *hud;

@property(nonatomic,strong)UIView           *titleView;

@property(nonatomic,strong)UIView           *videoThumbSliderView;
@property(nonatomic,strong)UIScrollView     *videoThumbSlider;
@property(nonatomic,strong)UIView           *videoThumbSliderback;
@property(nonatomic,strong)RDZSlider        *videoProgressSlider;
@property(nonatomic,strong)RDExportProgressView *exportProgressView;

@property(nonatomic       )UIAlertView      *commonAlertView;

//转场
@property (nonatomic,strong)UIView *transitionView;
@property (nonatomic,assign)double                   transitionDuration;
@property (nonatomic,assign)float                    maxFileTimeDuration;
@property(nonatomic,strong)UIView               *transitionToolbarView;

//添加镜头
@property(nonatomic,strong)UIView               *addLensView;  //添加镜头 界面
@property (nonatomic,assign)bool                isAdd;         //是否添加

@property (nonatomic,assign)BOOL                isModigy;      //是否修改

//音量
@property(nonatomic,strong)UIView               *volumeView;  //音量界面
//@property(nonatomic,strong)UIView               *vloumeBtnView;
@property(nonatomic,strong)UIButton             *volumeCloseBtn;
@property(nonatomic,strong)UIButton             *volumeConfirmBtn;

@property(nonatomic,strong)UIButton             *vloumeAllBtn;

@property(nonatomic,strong)UILabel              *vloumeCurrentLabel;
@property(nonatomic,strong)RDZSlider            *volumeProgressSlider;
//淡入淡出
@property(nonatomic,strong)RDZSlider            *fadeInVolumeSlider;
@property(nonatomic,strong)RDZSlider            *fadeOutVolumeSlider;

//选择器
@property(nonatomic,strong)UIButton             *vloume_navagatio_View;
@property(nonatomic,strong)UIButton             *vloumeBtn;
@property(nonatomic,strong)UIButton             *fadeInOrOutBtn;
@property(nonatomic,strong)UIView               *volumeFadeView;
//透明度
@property(nonatomic,strong)UIView               *transparencyView;
@property(nonatomic,strong)UIButton               *transparencyBtn;
@property(nonatomic,strong)UILabel              *transparencyCurrentLabel;
@property(nonatomic,strong)RDZSlider            *transparencyProgressSlider;
@property(nonatomic,strong)UIButton             *transparencyCloseBtn;
@property(nonatomic,strong)UIButton             *transparencyConfirmBtn;

//美颜
@property(nonatomic,strong)UIView               *beautyView;
@property(nonatomic,strong)UIButton             *beautyBtn;
@property(nonatomic,strong)UILabel              *beautyCurrentLabel;
@property(nonatomic,strong)RDZSlider            *beautyProgressSlider;
@property(nonatomic,strong)UIButton             *beautyCloseBtn;
@property(nonatomic,strong)UIButton             *beautyConfirmBtn;

//动画
@property(nonatomic,strong)UIView               *animationLordView;//动画
@property(nonatomic,strong)UIView               *animationView;//动画
@property(nonatomic,strong)UIView               *animationTitleView;//动画
@property(nonatomic,strong)UIButton             *animationCloseBtn;
@property(nonatomic,strong)UIButton             *animationConfirmBtn;


@end

@implementation RDEditVideoViewController
-(void)SetSelectFileIndex:(int) index
{
    selectFileIndex = index;
}

-(void)setScenes:(NSMutableArray *) Scenes
{
    scenes = Scenes;
}

//背景颜色回调
-( void )setBackGroundColorWithRed
{
//    if( _videoBackgroundColor == nil )
//        return;
//    CGFloat R, G, B, A;
//    CGColorRef color = [_videoBackgroundColor CGColor];
//    
//    if( (_isNoBackground) || ( _isVague ) )
//        color = [[UIColor blackColor] CGColor];
//    
//    int numComponents = CGColorGetNumberOfComponents(color);
//    if (numComponents == 4)
//    {
//        const CGFloat *components = CGColorGetComponents(color);
//        R = components[0];
//        G = components[1];
//        B = components[2];
//        A = components[3];
//    }
    
//    [_videoCoreSDK setBackGroundColorWithRed:R
//                                       Green:G
//                                        Blue:B
//                                       Alpha:A];
//    [_videoCoreSDK filterRefresh: [_videoCoreSDK currentTime] ];
}

-(void)setExportSize:(CGSize) Size
{
    exportSize = Size;
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

- (void)notification:(NSNotification *)notification{
    if(notification.name  == UIApplicationWillResignActiveNotification){
        if(_exportProgressView){
            isCancelExportReverse = YES;
            [_exportProgressView removeFromSuperview];
            _exportProgressView = nil;
            [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
        }
    }
    if(notification.name == UIApplicationDidBecomeActiveNotification){

    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
//    [_videoCoreSDK stop];//20171026 wuxiaoxia 优化内存
//    isNeedPrepare = YES;  
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationItem setHidesBackButton:YES];
//    if (isNeedPrepare) {
//        [_videoCoreSDK prepare];//20171026 wuxiaoxia 优化内存
//
//    }
    _playerView.hidden = NO;
    [self performSelector:@selector(getCurrentCore) withObject:self afterDelay:0.05];
    
    if( isSeplace )
        isSeplace = false;
}

-(void)getCurrentCore
{
    if( _videoCoreSDK )
    {
        if( isRefresh )
        {
            CMTime time = currentMinCoreSDK.currentTime;
            
            if( CMTimeGetSeconds(time) == 0 )
                time = CMTimeMakeWithSeconds(0.1, TIMESCALE);
            
            time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
            if( CMTimeGetSeconds(time) != CMTimeGetSeconds(_videoCoreSDK.currentTime) )
            {
                [_videoCoreSDK seekToTime:time];
                seekTime = time;
            }
            else
            {
                [_videoCoreSDK refreshCurrentFrame];
            }
        }
    }
    currentMinCoreSDK = [self getCore:_fileList[selectFileIndex] atIsExpSize:NO];
}

-(void)setCurrentTime:(CMTime) time
{
    nextVideoTime = time;
}

- (void)viewDidLoad {
    
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    isFirst = true;
    isRefresh = false;
    isAddTransitionBuild = true;
    isRefeshNextThumbCore = false;
    isNewCoreSDK = false;
    isTranstion = false;
    isAnimation = false;
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    volumeMultipleM = 2.0;
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    transitionList = [RDHelpClass getTransitionArray];
    isToolBarView = true;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    if( (exportSize.width <= 0) || (exportSize.height <= 0) ) {
        exportSize = [self getEditVideoSize];
        if (exportSize.width == exportSize.height) {
            _proportionIndex = kCropType1v1;
        }else if (exportSize.width > exportSize.height) {
            _proportionIndex = kCropType16v9;
        }else {
            _proportionIndex = kCropType9v16;
        }
    }
    fileLock = [[NSLock alloc] init];
    isNeedPrepare = NO;
    [self setValue];
    //    float videoThumbSlider_Height = (operationView.frame.size.height - (self.toolBarView.frame.size.height + self.toolBarView.frame.origin.y) - 34) - 20;
    
    operationView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewHeight + kPlayerViewOriginX , kWIDTH, kHEIGHT - kPlayerViewHeight - kPlayerViewOriginX ) ];
    operationView.backgroundColor = TOOLBAR_COLOR;
    [operationView addSubview:self.toolBarView];
    
    _bottomView = [[UIView alloc] init];
    _bottomView.frame = CGRectMake(0, kPlayerViewHeight + kPlayerViewOriginX  , kWIDTH, kHEIGHT - kPlayerViewHeight - kPlayerViewOriginX - kToolbarHeight);//kHEIGHT - (30 + 45) - 44
    _bottomView.backgroundColor = [UIColor clearColor];
    _bottomView.hidden = YES;
    
    _videoCoreSDK = _nextVideoCoreSDK;
//    TICK;
    [self performSelector:@selector(initChildView) withObject:nil afterDelay:0.1];
    [self.view addSubview:self.playerView];
    [self.view addSubview:self.videoProgressSlider];
    [self performSelector:@selector(videoThumbSlider) withObject:nil afterDelay:0.2];
    [self.view insertSubview:self.titleView aboveSubview:self.playerView];
    _hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:_hud.view];
    [self.view addSubview:_bottomView];
    [self.view addSubview:operationView];
    [self.view addSubview:[self playButton]];
    [self.view addSubview:self.durationLabel];
    [self.view addSubview:self.currentLabel];
    _videoProgressSlider.frame = CGRectMake(130, self.playerView.frame.size.height + self.playerView.frame.origin.y - 56 + ( 56 - 30 )/2.0 + 28, kWIDTH - 60*2.0 - 80.0, 30);
//    TOCK;
    [self.view addSubview:_videoProgressSlider];
//    TOCK;
    transitionTimeRange = kCMTimeRangeZero;
}

- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
        //    if (!_videoCoreSDK.view.superview) {
        CGRect  rect  = self.playerView.bounds;
        _videoCoreSDK.frame = rect;
        [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
        //    }
        //    [_videoCoreSDK setEditorVideoSize:exportSize];
//        [_videoCoreSDK prepare];
        [_videoCoreSDK seekToTime:nextVideoTime];
//        [_videoCoreSDK refreshCurrentFrame];
        self.currentLabel.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(_videoCoreSDK.currentTime)];
        self.durationLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:_videoCoreSDK.duration]];
        _videoProgressSlider.value = (CMTimeGetSeconds(nextVideoTime))/_videoCoreSDK.duration;
        [_videoCoreSDK refreshCurrentFrame];
    }
    else
        [self initPlayer:nil];
    
    _videoCoreSDK.enableAudioEffect = true;
}

- (void)setValue{
    seekTime = kCMTimeZero;
    _musicVolume = 0.5;
    if( selectFileIndex <= 0 )
        selectFileIndex = 0;
    NSString *appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    if(editConfig.proportionType == RDPROPORTIONTYPE_AUTO){
        editVideoSizeType = kAutomatic;
    }
    else if(editConfig.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
        editVideoSizeType = kLandscape;
    }
    else if(editConfig.proportionType == RDPROPORTIONTYPE_SQUARE){
        editVideoSizeType = kQuadratescape;
    }
    _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:appKey
                                           APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                          LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                           videoSize:exportSize
                                                 fps:kEXPORTFPS
                                          resultFail:^(NSError *error) {
                                              NSLog(@"initSDKError:%@", error.localizedDescription);
                                          }];
    _videoCoreSDK.delegate = self;
    globalFilters = [NSMutableArray array];
    
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];    
    UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
    
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if([lexiu currentReachabilityStatus] != RDNotReachable && ((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary * dic = [RDHelpClass classificationParams:@"filter2" atAppkey: appKey atURl:editConfig.netMaterialTypeURL];
            if( !dic )
            {
                NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                            appkey:appKey
                                                                           urlPath:editConfig.filterResourceURL];
                if ([filterList[@"code"] intValue] == 0) {
                    filtersName = [filterList[@"data"] mutableCopy];
                    
                    NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                    if(appKey.length > 0)
                        [itemDic setObject:appKey forKey:@"appkey"];
                    [itemDic setObject:@"" forKey:@"cover"];
                    [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                    [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                    [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                    [filtersName insertObject:itemDic atIndex:0];
                }
            }
            else
            {
                newFilterSortArray = [NSMutableArray arrayWithArray:dic];
                newFiltersNameSortArray = [NSMutableArray new];
                for (int i = 0; i < newFilterSortArray.count; i++) {
                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    [params setObject:@"filter2" forKey:@"type"];
                    [params setObject:[newFilterSortArray[i] objectForKey:@"id"]  forKey:@"category"];
                    [params setObject:[NSString stringWithFormat:@"%d" ,0] forKey: @"page_num"];
                    NSDictionary *dic2 = [RDHelpClass getNetworkMaterialWithParams:params
                                                                            appkey:appKey urlPath:editConfig.effectResourceURL];
                    if(dic2 && [[dic2 objectForKey:@"code"] integerValue] == 0)
                    {
                        NSMutableArray * currentStickerList = [dic2 objectForKey:@"data"];
                        [newFiltersNameSortArray addObject:currentStickerList];
                    }
                    else
                    {
                        NSString * message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                    }
                }
                filtersName = [NSMutableArray new];
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(appKey.length > 0)
                    [itemDic setObject:appKey forKey:@"appkey"];
                [itemDic setObject:@"" forKey:@"cover"];
                [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                [filtersName addObject:itemDic];
                
                for (int i = 0; newFiltersNameSortArray.count > i; i++) {
                    [filtersName addObjectsFromArray:newFiltersNameSortArray[i]];
                }
            }
            NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:filterPath]){
                [[NSFileManager defaultManager] createDirectoryAtPath:filterPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            [filtersName enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RDFilter* filter = [RDFilter new];
                if([obj[@"name"] isEqualToString:RDLocalizedString(@"原始", nil)]){
                    filter.type = kRDFilterType_YuanShi;
                }else{
                    NSString *itemPath = [[[filterPath stringByAppendingPathComponent:[obj[@"name"] lastPathComponent]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
                    if (![[[obj[@"file"] pathExtension] lowercaseString] isEqualToString:@"acv"]){
                        filter.type = kRDFilterType_LookUp;
                    }
                    else{
                        filter.type = kRDFilterType_ACV;
                    }
                    filter.filterPath = itemPath;
                }
                filter.netCover = obj[@"cover"];
                filter.name = obj[@"name"];
                [globalFilters addObject:filter];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (globalFilters.count > 0) {
                    [_videoCoreSDK addGlobalFilters:globalFilters];
                    if (scenes.count > 0) {
                        int timeEffectSceneCount = 0;
                        for (int i = 0; i< _fileList.count; i++) {
                            RDFile *file = _fileList[i];
                            if (file.timeEffectSceneCount > 0) {
                                for (int j = timeEffectSceneCount; j < timeEffectSceneCount + file.timeEffectSceneCount; j++) {
                                    if (scenes.count < j) {
                                        break;
                                    }
                                    RDScene *scene = scenes[j];
                                    VVAsset* vvasset = [scene.vvAsset firstObject];
                                    RDFilter* filter = globalFilters[file.filterIndex];
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
                                timeEffectSceneCount += file.timeEffectSceneCount;
                            }else if (scenes.count > timeEffectSceneCount) {
                                RDScene *scene = scenes[timeEffectSceneCount];
                                VVAsset* vvasset = [scene.vvAsset firstObject];
                                RDFilter* filter = globalFilters[file.filterIndex];
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
                                timeEffectSceneCount++;
                            }
                        }
                    }
                }
            });
        });
    }else{
        filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        [filtersName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            RDFilter* filter = [RDFilter new];
            if ([obj isEqualToString:@"原始"]) {
                filter.type = kRDFilterType_YuanShi;
            }
            else{
                filter.type = kRDFilterType_LookUp;
                filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"lookupFilter/%@",obj] Type:@"png"];
            }
            filter.name = obj;
            [globalFilters addObject:filter];
            
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",filter.name]];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:photoPath]){
                [RDCameraManager returnImageWith:inputImage Filter:filter withCompletionHandler:^(UIImage *processedImage) {
                    NSData* imagedata = UIImageJPEGRepresentation(processedImage, 1.0);
                    [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
                }];
            }
        }];
    }
    [self getToolBarItemArray];
}
- (void)getToolBarItemArray
{
    NSArray *functionLists = ((RDNavigationViewController *)self.navigationController).edit_functionLists;
    if(functionLists.count>0){
        toolItems = [NSMutableArray array];
        for (int i = 0; i < functionLists.count; i++) {
            RDcustomizationFunctionType functionType = (RDcustomizationFunctionType)[functionLists[i] integerValue];
            switch (functionType) {
                case KTRANSPARENCY://透明度
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"透明度",@"title",@(KTRANSPARENCY),@"id", nil]];
                    break;
                case KREPLACE://替换
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"替换",@"title",@(KREPLACE),@"id", nil]];
                    break;
                case kRDSORT: //排序
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"排序",@"title",@(kRDSORT),@"id", nil]];
                    break;
                case kRDTRIM://截取
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"截取",@"title",@(kRDTRIM),@"id", nil]];
                    break;
                    
                case kRDSPLIT://分割
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"分割",@"title",@(kRDSPLIT),@"id", nil]];
                    break;
                    
                case kRDEDIT://编辑
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"裁切",@"title",@(kRDEDIT),@"id", nil]];
                    break;
                    
                case kRDSINGLEFILTER://滤镜
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"滤镜",@"title",@(kRDSINGLEFILTER),@"id", nil]];
                    break;
                    
                case KRDADJUST://调色
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"调色",@"title",@(KRDADJUST),@"id", nil]];
                    break;
                    
                case KRDEFFECTS://特效
//                    if (((RDNavigationViewController *)self.navigationController).editConfiguration.specialEffectResourceURL.length > 0) {
//                        [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"特效",@"title",@(KRDEFFECTS),@"id", nil]];
//                    }
                    break;
                    
                case kRDCHANGESPEED://变速
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"时长",@"title",@(kRDCHANGESPEED),@"id", nil]];
                    break;
                    
                case kRDCOPY://复制
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"复制",@"title",@(kRDCOPY),@"id", nil]];
                    break;
                    
                case kRDREVERSEVIDEO://倒序
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"倒放",@"title",@(kRDREVERSEVIDEO),@"id", nil]];
                    break;
                case KTRANSITION://转场
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"转场",@"title",@(KTRANSITION),@"id", nil]];
                    break;
                case KROTATE://旋转
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"旋转",@"title",@(KROTATE),@"id", nil]];
                    break;
                case KFLIPUPANDDOWN://上下翻转
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"上下翻转",@"title",@(KFLIPUPANDDOWN),@"id", nil]];
                    break;
                case KMIRROR://镜像
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"左右翻转",@"title",@(KMIRROR),@"id", nil]];
                    break;
                case KVOLUME://音量
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"音量",@"title",@(KVOLUME),@"id", nil]];
                    break;
                case kRDTEXTTITLE://文字版
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"文字",@"title",@(kRDTEXTTITLE),@"id", nil]];
                    break;
                case KRDANIMATION:
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"动画",@"title",@(KRDANIMATION),@"id", nil]];
                    break;
                case KBEAUTY:   //美颜 beauty
                    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"美颜",@"title",@(KBEAUTY),@"id", nil]];
                    break;
                    break;
                default:
                    break;
            }
        }
    }
}

-(void)setEndledBtn:(UIButton *) btn atEndled:(bool) endled
{
    btn.userInteractionEnabled= endled; //控件不能点
    if( endled )
    {
        btn.alpha = 1.0;
        [btn.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.alpha = 1.0;
        }];
    }
    else
    {
        btn.alpha = 0.5;
        [btn.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.alpha = 0.3;
        }];
    }
}

/** 0:显示视频的编辑选项 1：显示图片的编辑选项
 */
- (void)getToolBarItems {
    RDFileType type = _fileList[selectFileIndex].fileType;

    //转场
    if( selectFileIndex < (_fileList.count - 1) )
        [self setEndledBtn:[_toolBarView viewWithTag:13] atEndled:YES];
    else
        [self setEndledBtn:[_toolBarView viewWithTag:13] atEndled:NO];
    //替换
    [self setEndledBtn:[_toolBarView viewWithTag:18] atEndled:YES];
    //透明度
    [self setEndledBtn:[_toolBarView viewWithTag:19] atEndled:YES];
    
    //滤镜
    [self setEndledBtn:[_toolBarView viewWithTag:10] atEndled:YES];
    //调色
    [self setEndledBtn:[_toolBarView viewWithTag:11] atEndled:YES];
    //变速 （显示文字改变）
    [self setEndledBtn:[_toolBarView viewWithTag:4] atEndled:YES];
    //复制
    [self setEndledBtn:[_toolBarView viewWithTag:5] atEndled:YES];
    //编辑
    [self setEndledBtn:[_toolBarView viewWithTag:3] atEndled:YES];
    //旋转
    [self setEndledBtn:[_toolBarView viewWithTag:14] atEndled:YES];
    //左右翻转
    [self setEndledBtn:[_toolBarView viewWithTag:16] atEndled:YES];
    //上下翻转
    [self setEndledBtn:[_toolBarView viewWithTag:15] atEndled:YES];
    //文字
    [self setEndledBtn:[_toolBarView viewWithTag:6] atEndled:NO];
    
    //美颜
    [self setEndledBtn:[_toolBarView viewWithTag:21] atEndled:YES];
    //动画
    [self setEndledBtn:[_toolBarView viewWithTag:20] atEndled:YES];

    if(type == kFILEVIDEO || (type == kFILEIMAGE && _fileList[selectFileIndex].isGif)){
        //截取 2
        [self setEndledBtn:[_toolBarView viewWithTag:1] atEndled:YES];
        //分割 3
        [self setEndledBtn:[_toolBarView viewWithTag:2] atEndled:YES];

        //变速 （显示文字改变 "title-speed"
        [((UIButton *)[_toolBarView viewWithTag:4]) setTitle:RDLocalizedString(@"title-speed", nil) forState:UIControlStateNormal];
//        [self setEndledBtn:[_toolBarView viewWithTag:6] atEndled:YES];
        //音量
        [self setEndledBtn:[_toolBarView viewWithTag:17] atEndled:YES];
        
        //倒放
        if(_fileList[selectFileIndex].isGif)
            [self setEndledBtn:[_toolBarView viewWithTag:7] atEndled:NO];
        else
            [self setEndledBtn:[_toolBarView viewWithTag:7] atEndled:YES];
        
    }else if( type == kFILEIMAGE && !_fileList[selectFileIndex].isGif ) {
        [((UIButton *)[_toolBarView viewWithTag:4]) setTitle:RDLocalizedString(@"时长", nil) forState:UIControlStateNormal];
        //截取
        [self setEndledBtn:[_toolBarView viewWithTag:1] atEndled:NO];
        //分割
        [self setEndledBtn:[_toolBarView viewWithTag:2] atEndled:NO];
        //音量
        [self setEndledBtn:[_toolBarView viewWithTag:17] atEndled:NO];
        //倒放
        [self setEndledBtn:[_toolBarView viewWithTag:7] atEndled:NO];
        //变速 （显示文字改变）   时长
    }
    else if( type == kTEXTTITLE)
    {
        [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( [obj isKindOfClass:[UIButton class]] )
            {
                [self setEndledBtn:[_toolBarView viewWithTag:idx] atEndled:NO];
            }
        }];
        //替换
        [self setEndledBtn:[_toolBarView viewWithTag:18] atEndled:NO];
        //透明度
        [self setEndledBtn:[_toolBarView viewWithTag:19] atEndled:NO];
        //上下翻转
        [self setEndledBtn:[_toolBarView viewWithTag:15] atEndled:NO];
        //音量
        [self setEndledBtn:[_toolBarView viewWithTag:17] atEndled:NO];
        //文字
        [self setEndledBtn:[_toolBarView viewWithTag:6] atEndled:YES];
        //复制
        [self setEndledBtn:[_toolBarView viewWithTag:5] atEndled:YES];
        //排序
        [self setEndledBtn:[_toolBarView viewWithTag:0] atEndled:YES];
        //转场
        if( selectFileIndex < (_fileList.count - 1) )
            [self setEndledBtn:[_toolBarView viewWithTag:13] atEndled:YES];
        else
            [self setEndledBtn:[_toolBarView viewWithTag:13] atEndled:NO];
    }
}

- (void)getconnectToolItems{
    NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"title-video", nil),@"title",@(1),@"id", nil];
    NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"title-image", nil),@"title",@(2),@"id", nil];
    NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"title-texttitle", nil),@"title",@(3),@"id", nil];
    NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"转场", nil),@"title",@(4),@"id", nil];
    
    connectToolItems = [NSMutableArray array];
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
        [connectToolItems addObject:dic2];
    }
    else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
        [connectToolItems addObject:dic1];
    }else{
        [connectToolItems addObject:dic1];
        [connectToolItems addObject:dic2];
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
        [connectToolItems addObject:dic3];
    }
    [connectToolItems addObject:dic4];
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

/**导航栏的标题
 */
- (UIView *)titleView{
    if(!_titleView){
        _titleView = [UIView new];
        _titleView.frame = CGRectMake(0, 0, kWIDTH, 44 + (iPhone_X ? 44 : 0));

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        gradientLayer.locations = @[@0.3, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1.0);
        gradientLayer.frame = _titleView.bounds;
        [_titleView.layer addSublayer:gradientLayer];
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.backgroundColor = [UIColor clearColor];
        backButton.frame = CGRectMake(5, self.titleView.frame.size.height - 44, 44, 44);
        if(_fromToNext){
            [backButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步取消默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        }else{
            [backButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        }
        [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        [_titleView addSubview:backButton];
        
        UIButton *continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
        continueButton.backgroundColor = [UIColor clearColor];
        if(_fromToNext){
            continueButton.frame = CGRectMake(kWIDTH - 60, self.titleView.frame.size.height - 44, 60, 44);
            [continueButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步完成默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        }else{
            continueButton.frame = CGRectMake(kWIDTH - 66, self.titleView.frame.size.height - 44, 60, 44);
            continueButton.titleLabel.font = [UIFont systemFontOfSize:16];
            [continueButton setTitleColor:Main_Color forState:UIControlStateNormal];
            [continueButton setTitle: RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
        }
        [continueButton addTarget:self action:@selector(tapcontinueBtn) forControlEvents:UIControlEventTouchUpInside];
        [_titleView addSubview:continueButton];
        
        UILabel *titleLabel = [UILabel new];
        titleLabel.frame = CGRectMake(self.titleView.frame.size.width/2.0 - 60, self.titleView.frame.size.height - 44, 120, 44);
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = RDLocalizedString(@"剪辑", nil);
        titleLabel.font = [UIFont systemFontOfSize:20];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_titleView addSubview:titleLabel];
    }
    return _titleView;
}

/**导出进度条
 */
- (RDExportProgressView *)exportProgressView{
    if(!_exportProgressView){
        _exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0,0, kWIDTH, kHEIGHT)];
        _exportProgressView.canTouchUpCancel = YES;
        [_exportProgressView setProgress:0 animated:NO];
        [_exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
        [_exportProgressView setTrackprogressTintColor:UIColorFromRGB(0xffffff)];
        _exportProgressView.hidden = YES;
        [_exportProgressView setProgressTitle:RDLocalizedString(@"倒放处理中，请稍等...", nil)];
        __weak typeof(self) myself = self;
        _exportProgressView.cancelExportBlock = ^(){
            isCancelExportReverse = YES;
            __strong typeof(self) strongSelf = myself;
            
            [[UIApplication sharedApplication] setIdleTimerDisabled: strongSelf->_idleTimerDisabled];
            [myself.exportProgressView setProgress2:0 animated:NO];
            myself.exportProgressView.hidden = YES;
            if(myself.exportProgressView.superview)
                [myself.exportProgressView removeFromSuperview];
        };
    }
    return _exportProgressView;
}

- (NSString *)addLensViewItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollviewChildItems/添加图片默认_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollviewChildItems/添加视频默认_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollviewChildItems/剪辑_添加文字板默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}
/** 添加镜头
 */
-(UIView *)addLensView
{
    if( _addLensView )
    {
        [_addLensView removeFromSuperview];
        _addLensView = nil;
    }
    
    _isAdd = true;
    _titleView.hidden = YES;
    _videoProgressSlider.hidden = YES;
    _durationLabel.hidden = YES;
    _currentLabel.hidden = YES;
    _playButton.hidden = YES;
    
    _addLensView = [[UIView alloc] initWithFrame:CGRectMake(0, (self.playerView.frame.size.height + self.playerView.frame.origin.y), kWIDTH, kHEIGHT - (self.playerView.frame.size.height + self.playerView.frame.origin.y))];
    
    _addLensView.backgroundColor = TOOLBAR_COLOR;
    
    UIView *LensView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH,_addLensView.frame.size.height - kNavigationBarHeight)];
    LensView.backgroundColor = TOOLBAR_COLOR;
    [_addLensView addSubview:LensView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, LensView.frame.size.height*1.0/3.0)];
    label.text  = RDLocalizedString(@"添加镜头", nil);
//    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        label.font = [UIFont systemFontOfSize:14];
//    }else {
//        label.font = [UIFont systemFontOfSize:12];
//    }
    label.textColor = UIColorFromRGB(0x8d8c91);
    label.textAlignment = NSTextAlignmentCenter;
    [LensView addSubview:label];
    
    bool isBtn1 = false;
    bool isBtn2 = false;
    bool isBtn3 = false;
    int count = 0;
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
        isBtn1 =true;
        count++;
    }
    else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
        isBtn2 =true;
        count++;
    }else{
        isBtn1 =true;
        count++;
        isBtn2 =true;
        count++;
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
        isBtn3 = true;
        count++;
    }
    
    if( isBtn1 )
    {
        int iBtn = 0;
        if( isBtn2 || isBtn3 )
            iBtn = 0;
        else
            iBtn = 1;
        UIButton *Btn1 = [self LensBtn:iBtn atStr:RDLocalizedString(@"图片", nil) atImageStr:[self addLensViewItemsImagePath:0] atHeight: LensView.frame.size.height*2.0/3.0 atNUmber:0]; //添加图片默认_
        [LensView addSubview:Btn1];
    }
    if( isBtn2 )
    {
        int iBtn = 0;
        if( isBtn1 && isBtn3 )
            iBtn = 1;
        else if( isBtn1 )
            iBtn = 2;
        else if( isBtn3 )
            iBtn = 0;
        else
            iBtn = 1;
        UIButton *Btn2 = [self LensBtn:iBtn atStr:RDLocalizedString(@"视频", nil) atImageStr:[self addLensViewItemsImagePath:1] atHeight: LensView.frame.size.height*2.0/3.0  atNUmber:1]; //添加视频默认_
        [LensView addSubview:Btn2];
    }
    if( isBtn3 )
    {
        int iBtn = 0;
        if( isBtn2 || isBtn1 )
            iBtn = 2;
        else
            iBtn = 1;
        UIButton *Btn3 = [self LensBtn:iBtn atStr:RDLocalizedString(@"文字", nil) atImageStr:[self addLensViewItemsImagePath:2] atHeight: LensView.frame.size.height*2.0/3.0 atNUmber:2]; //剪辑_添加文字板默认_
        [LensView addSubview:Btn3];
    }

//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, LensView.frame.size.height + LensView.frame.origin.y, kWIDTH, 1)];
//    imageView.backgroundColor =  SCREEN_BACKGROUND_COLOR;
//    [_addLensView addSubview:imageView];
    
    UIView *cancelView = [[UIView alloc] initWithFrame:CGRectMake(0, LensView.frame.size.height + LensView.frame.origin.y + 1, kWIDTH, kNavigationBarHeight)];
    cancelView.backgroundColor = TOOLBAR_COLOR;
    [_addLensView addSubview:cancelView];
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake( (kWIDTH - 44.0)/2.0 , 0, 44, 44)];
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(addLens_cancelBtn) forControlEvents:UIControlEventTouchUpInside];
    [cancelView addSubview:cancelBtn];
    
    return _addLensView;
}

-(void)cancelAddLens
{
    [RDHelpClass animateViewHidden:_addLensView atUP:NO atBlock:^{
        if( _addLensView )
        {
            [_addLensView removeFromSuperview];
            _addLensView = nil;
        }
        _titleView.hidden = NO;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden = NO;
        _currentLabel.hidden = NO;
        _playButton.hidden = NO;
    }];
}

-(void)addLens_cancelBtn
{
    _isAdd = false;
    [self cancelAddLens];
}

/** 镜头控件
 */
-(UIButton *)LensBtn:(int) index atStr:(NSString *) str atImageStr:(NSString *) ImageStr atHeight:(float) hegiht atNUmber:(int) number
{
    float toolItemBtnHeight = hegiht;
    float toolItemWidth = toolItemBtnHeight*5.0/8.0;
    float ImageWidth = toolItemBtnHeight*5.0/8.0;
    float TextHeight = toolItemBtnHeight*2.0/8.0;
    
    int fwidth = (kWIDTH - ((15 + toolItemWidth*3.0/2.0)*2 + toolItemWidth))/2.0;
    
    UIButton *Btn  = [UIButton buttonWithType:UIButtonTypeCustom];
    Btn.tag = number + 1;
    Btn.frame = CGRectMake((15 +  toolItemWidth*3.0/2.0)*index + fwidth,  (_addLensView.frame.size.height - kNavigationBarHeight)/3.0 + (hegiht - toolItemBtnHeight)/2.0, toolItemWidth, toolItemBtnHeight);
    Btn.backgroundColor = [UIColor clearColor];
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, ImageWidth, Btn.frame.size.width, TextHeight)];
    label1.textAlignment = NSTextAlignmentCenter;
    label1.textColor = UIColorFromRGB(0x8d8c91);
    label1.text = str;
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        label1.font = [UIFont systemFontOfSize:11];
    }else {
        label1.font = [UIFont systemFontOfSize:10];
    }
    [Btn addSubview:label1];
    
    UIImageView *thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((Btn.frame.size.width - ImageWidth)/2.0, 0, ImageWidth, ImageWidth)];
    thumbnailIV.image = [UIImage imageWithContentsOfFile:ImageStr];
    thumbnailIV.layer.cornerRadius = (ImageWidth)/2.0;
    thumbnailIV.layer.masksToBounds = YES;
    [Btn addSubview:thumbnailIV];
    
    [Btn addTarget:self action:@selector(clickConnectToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
    return Btn;
}

/**缩率图控件
 */
- (UIScrollView *)videoThumbSlider{
    if(!_videoThumbSlider){
        float videoThumbSlider_Height = 95;
        float videoThumbSlider_Wdith = videoThumbSlider_Height + 20;
        if(self.videoThumbSliderView.superview)
            [self.videoThumbSliderView removeFromSuperview];
        _videoThumbSliderView = nil;
        
        _videoThumbSliderView = [UIScrollView new];
        _videoThumbSliderView.frame = CGRectMake(0, self.toolBarView.frame.size.height + ( operationView.frame.size.height - self.toolBarView.frame.size.height - videoThumbSlider_Height )/2.0 , kWIDTH, videoThumbSlider_Height);
        _videoThumbSliderView.backgroundColor = [UIColor clearColor];
        [operationView addSubview:self.videoThumbSliderView];
        [_videoThumbSliderback.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _videoThumbSlider = [UIScrollView new];
        //        _videoThumbSlider.frame = CGRectMake(0, (self.playerView.frame.size.height + self.playerView.frame.origin.y) + (self.toolBarView.frame.origin.y - (self.playerView.frame.size.height + self.playerView.frame.origin.y) - videoThumbSlider_Height)/2.0 , kWIDTH, videoThumbSlider_Height);
        _videoThumbSlider.frame = CGRectMake(0, 0 , kWIDTH, videoThumbSlider_Height);
        _videoThumbSlider.backgroundColor = [UIColor clearColor];
        float fwidth  = _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20  - (videoThumbSlider_Height + 10)*2.0   + (_videoThumbSlider.frame.size.height*2.0/3.0);
        if( fwidth <= kWIDTH )
            fwidth = kWIDTH + 10;
        
        _videoThumbSlider.contentSize = CGSizeMake( fwidth, 0);
        _videoThumbSlider.showsVerticalScrollIndicator = NO;
        _videoThumbSlider.showsHorizontalScrollIndicator = NO;
        
        [self.videoThumbSliderView addSubview:_videoThumbSlider];
        
        __weak typeof(self) myself = self;
        _videoThumbSliderback = [UIView new];
        _videoThumbSliderback.backgroundColor = [UIColor clearColor];
        _videoThumbSliderback.frame = CGRectMake(0, 0, _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20 , _videoThumbSlider.frame.size.height);
        [_videoThumbSlider addSubview:_videoThumbSliderback];
        
        _videoThumbSliderback.layer.masksToBounds = NO;
        [_videoThumbSlider setCanCancelContentTouches:NO];
        [_videoThumbSlider setClipsToBounds:NO];
        [_videoThumbSliderback setClipsToBounds:NO];
        [thumbViewItems removeAllObjects];
        thumbViewItems = nil;
        thumbViewItems = [[NSMutableArray<RDThumbImageView *> alloc] init];
        CGSize size = CGSizeMake(_videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {            
            RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:size];
            thumbView.isEdit = true;
                thumbView.backgroundColor = [UIColor clearColor];
                thumbView.frame = CGRectMake(videoThumbSlider_Wdith*idx + 10, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
                thumbView.contentFile = obj;
                if(!obj.thumbImage){
                    [myself performSelectorInBackground:@selector(refreshThumbImage:) withObject:thumbView];
                }else{
                    thumbView.thumbIconView.image = obj.thumbImage;
                }
                thumbView.thumbId = idx;
                thumbView.transitionTypeName = obj.transitionTypeName;
                thumbView.transitionDuration = obj.transitionDuration;
                thumbView.transitionName = obj.transitionName;
                thumbView.transitionMask = obj.transitionMask;
                thumbView.home = thumbView.frame;
                thumbView.tag = 100;
                
                thumbView.delegate = self;
                if(idx == selectFileIndex){
                    [thumbView selectThumb:YES];
                }else{
                    [thumbView selectThumb:NO];
                }
                
                [_videoThumbSliderback insertSubview:thumbView atIndex:0];
                [thumbViewItems addObject:thumbView];
            
            if(idx !=(_fileList.count - 1)){
                float btnWidth = (videoThumbSlider_Wdith - videoThumbSlider_Height) + 16;
                float btnHeight = btnWidth + 14;
                RDConnectBtn *transitionBtn = [[RDConnectBtn alloc] initWithFrame:CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width - 8, (_videoThumbSlider.frame.size.height - btnHeight)/2.0, btnWidth, btnHeight)];
                transitionBtn.fileIndex = idx;
                transitionBtn.tag = 1000;
                
                transitionBtn.frame = CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width - 8, (_videoThumbSlider.frame.size.height - btnHeight)/2.0, btnWidth, btnHeight);
                if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
                    [transitionBtn setTransitionTypeName:obj.transitionTypeName];
                    [transitionBtn setTransitionTitle:(obj.transitionName.length>0 ? obj.transitionName : RDLocalizedString(@"无", nil))];
                    [transitionBtn addTarget:self action:@selector(enterTransition:) forControlEvents:UIControlEventTouchUpInside];
                }
                [_videoThumbSliderback addSubview:transitionBtn];
            }
        }];
        [RDSVProgressHUD dismiss];
        
        if( CMTimeGetSeconds(nextVideoTime) )
        {
            [self setThumbSlider_CurrentTime:nextVideoTime];
        }
        else
        {
            [self setThumbSlider_CurrentTime: _videoCoreSDK.currentTime ];
        }
        
        [_addButton removeFromSuperview];
        _addButton = nil;
        _addButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _addButton.backgroundColor = [UIColor clearColor];
        float addBtnHeight = _videoThumbSlider.frame.size.height;
        _addButton.frame = CGRectMake(_videoThumbSliderView.frame.size.width - addBtnHeight*2.0/3.0, ( _videoThumbSliderView.frame.size.height - addBtnHeight )/2.0, addBtnHeight*2.0/3.0, addBtnHeight  );
        UIImageView *btniconView = [[UIImageView alloc] init];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor, (__bridge id)[UIColor blackColor].CGColor];
        gradientLayer.locations = @[@0.5, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        gradientLayer.frame = CGRectMake(0, 0, _addButton.bounds.size.width*5.0/6.0, _addButton.bounds.size.height);
        [_addButton.layer addSublayer:gradientLayer];
        
        btniconView.frame = CGRectMake(_addButton.bounds.size.width*5.0/6.0, 0, _addButton.bounds.size.width*1.0/6.0, _addButton.bounds.size.height);
        btniconView.backgroundColor = UIColorFromRGB(0x000000);
        [_addButton addSubview:btniconView];
        
        UIImageView *btniconView1 = [[UIImageView alloc] init];
        btniconView1.image = [RDHelpClass imageWithContentOfFile:@"/jianji/scrollviewChildItems/添加镜头默认_"];
        btniconView1.frame = CGRectMake(_addButton.bounds.size.width*1.0/6.0, (addBtnHeight - _addButton.bounds.size.width*2.0/3.0)/2.0, _addButton.bounds.size.width*2.0/3.0, _addButton.bounds.size.width*2.0/3.0);
        [_addButton addSubview:btniconView1];
        
        [_addButton addTarget:self action:@selector(tapAddButton:) forControlEvents:UIControlEventTouchUpInside];
        [_addButton setImageEdgeInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
        [_videoThumbSliderView addSubview:_addButton];
    }
    return _videoThumbSlider;
}

- (void)refreshThumbImage:(RDThumbImageView *)tiv{
    RDFile *obj = _fileList[tiv.thumbId];
    obj.thumbImage = [RDHelpClass getThumbImageWithUrl:obj.contentURL];
    dispatch_async(dispatch_get_main_queue(), ^{
        tiv.thumbIconView.image = obj.thumbImage;
    });
}

- (void)refreshVideoThumbSlider{
    if(_videoThumbSlider){
        float videoThumbSlider_Height = 95;
        float videoThumbSlider_Wdith = videoThumbSlider_Height + 20;
        float fwidth  = _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20  - (videoThumbSlider_Height + 10)*2.0   + (_videoThumbSlider.frame.size.height*2.0/3.0);
        if( fwidth <= kWIDTH )
            fwidth = kWIDTH + 10;
        _videoThumbSlider.contentSize = CGSizeMake(fwidth, 0);

        _videoThumbSliderback.frame = CGRectMake(0, 0, _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20 , _videoThumbSlider.frame.size.height);
        
        NSArray *arr = [_videoThumbSliderback subviews];
        
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(_videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height)];
            thumbView.isEdit = true;
            thumbView.backgroundColor = [UIColor clearColor];
            thumbView.frame = CGRectMake(videoThumbSlider_Wdith*idx+10, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
            thumbView.home = thumbView.frame;
            thumbView.contentFile = obj;
            if(!obj.thumbImage){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    RDFile *file = _fileList[selectFileIndex];
                    if (file.isGif) {
                        obj.thumbImage = file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(file.imageTimeRange.start) url:file.contentURL urlAsset:nil];
                    }else if (file.isReverse) {
                        obj.thumbImage = file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(file.reverseVideoTrimTimeRange.start) url:file.reverseVideoURL urlAsset:nil];
                    }else {
                        obj.thumbImage = file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(file.videoTrimTimeRange.start) url:file.contentURL urlAsset:nil];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        thumbView.thumbIconView.image = obj.thumbImage;
                    });
                });
            }
            thumbView.thumbId = idx;
            thumbView.tag = 100;
            thumbView.delegate = self;
            if(idx == selectFileIndex){
                [thumbView selectThumb:YES];
            }else{
                [thumbView selectThumb:NO];
            }
            [_videoThumbSliderback insertSubview:thumbView atIndex:0];

            if(idx != (_fileList.count - 1)){
                float btnWidth = (videoThumbSlider_Wdith - videoThumbSlider_Height) + 16;
                float btnHeight = btnWidth + 14;
                RDConnectBtn *transitionBtn = [[RDConnectBtn alloc] initWithFrame:CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width - 8, (_videoThumbSlider.frame.size.height - btnHeight)/2.0, btnWidth, btnHeight)];
                transitionBtn.fileIndex = idx;
                transitionBtn.tag = 1000;
                if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
                    [transitionBtn setTransitionTypeName:obj.transitionTypeName];
                    [transitionBtn setTransitionTitle:(obj.transitionName.length>0 ? obj.transitionName : RDLocalizedString(@"无", nil))];
                    [transitionBtn addTarget:self action:@selector(enterTransition:) forControlEvents:UIControlEventTouchUpInside];
                }
                [_videoThumbSliderback addSubview:transitionBtn];
            }
        }];
        
        [arr enumerateObjectsUsingBlock:^(UIView* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
//            obj = nil;
        }];
        arr = nil;        
    }
}

/**播放器
 */
- (UIView *)playerView{
    if(!_playerView){
        _playerView = [UIView new];
        _playerView.frame = CGRectMake(0, kPlayerViewOriginX , kWIDTH, kPlayerViewHeight);
//         if(iPhone_X)
//             _playerView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
        _playerView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    }
    return _playerView;
}

- (UILabel *)currentLabel{
    if(!_currentLabel){
        _currentLabel = [[UILabel alloc] init];
        _currentLabel.frame = CGRectMake(70,  self.playerView.frame.size.height + self.playerView.frame.origin.y - 56 + ( 56 -20 )/2.0 + 28 , 60, 20);
        _currentLabel.textAlignment = NSTextAlignmentCenter;
        _currentLabel.textColor = UIColorFromRGB(0xffffff);
        _currentLabel.font = [UIFont systemFontOfSize:12];
        _currentLabel.text = [RDHelpClass timeToStringFormat:0];
    }
    return _currentLabel;
}

- (UILabel *)durationLabel{
    if(!_durationLabel){
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.frame = CGRectMake(kWIDTH - 70,  self.playerView.frame.size.height + self.playerView.frame.origin.y  - 56 + ( 56 -20 )/2.0 + 28, 60, 20);
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = UIColorFromRGB(0xffffff);
        _durationLabel.font = [UIFont systemFontOfSize:12];
        _durationLabel.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration];
    }
    return _durationLabel;
}

/**播放暂停按键
 */
- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton new];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake(( 70 - 56)/2.0, self.playerView.frame.size.height + self.playerView.frame.origin.y - 56  + 28, 56, 56);
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

/**进度条
 */
- (RDZSlider *)videoProgressSlider{
    if(!_videoProgressSlider){
        
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(130, self.playerView.frame.size.height + self.playerView.frame.origin.y - 56 + 15 + ( 56 - 30 )/2.0, kWIDTH - 60*2.0 - 80.0, 30)];
        [_videoProgressSlider setMaximumValue:1];
        [_videoProgressSlider setMinimumValue:0];
        _videoProgressSlider.layer.cornerRadius = 2.0;
        _videoProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        
        [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_videoProgressSlider setValue:0];
        _videoProgressSlider.alpha = 1.0;
        
        _videoProgressSlider.backgroundColor = [UIColor clearColor];
        
        [_videoProgressSlider addTarget:self action:@selector(beginScrub) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(scrub) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchUpInside];
        [_videoProgressSlider addTarget:self action:@selector(endScrub) forControlEvents:UIControlEventTouchCancel];
        
        [self.view addSubview:_playerView];
        
    }
    return _videoProgressSlider;
}

- (UIScrollView *)connectToolBarView{
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
        return nil;
    }
    [self getconnectToolItems];
    
    if(!_connectToolBarView){
        _connectToolBarView =  [UIScrollView new];
//        if(iPhone_X){
//            _connectToolBarView.frame = CGRectMake(0, kHEIGHT - 88, kWIDTH, 88);
//        }else
//            _connectToolBarView.frame = CGRectMake(0, kHEIGHT - (iPhone4s ? 55 : 60), kWIDTH, (iPhone4s ? 55 : 60));
//        if(iPhone_X){
//            _connectToolBarView.frame = CGRectMake(0, 0, kWIDTH, 88);
//        }else
       float videoThumbSlider_Height = 95;
        _connectToolBarView.frame = CGRectMake(0, ( ( operationView.frame.size.height - self.toolBarView.frame.size.height - videoThumbSlider_Height )/2.0 + self.toolBarView.frame.size.height - (iPhone4s ? 55 : 60) )/2.0, kWIDTH, (iPhone4s ? 55 : 60));
//        _connectToolBarView.backgroundColor = UIColorFromRGB(NV_Color);
        _connectToolBarView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _connectToolBarView.showsVerticalScrollIndicator = NO;
        _connectToolBarView.showsHorizontalScrollIndicator = NO;
//        __block float toolItemBtnWidth = MAX(kWIDTH/connectToolItems.count, _connectToolBarView.frame.size.height);
        __block float toolItemBtnWidth = kWIDTH/7;
        __block float contentsWidth = 0;
        [connectToolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[connectToolItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, 0, toolItemBtnWidth, (iPhone4s ? 55 : 60));
            [toolItemBtn addTarget:self action:@selector(clickConnectToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self connectToolItemsImagePath:toolItemBtn.tag - 1]] forState:UIControlStateNormal];
            [toolItemBtn setTitle:[connectToolItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            if ([UIScreen mainScreen].bounds.size.width >= 414) {
                toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:11];
            }else {
                toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:10];
            }
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
            [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            [_connectToolBarView addSubview:toolItemBtn];
            contentsWidth += toolItemBtnWidth;
        }];
        _connectToolBarView.contentSize = CGSizeMake(contentsWidth, 0);
        _connectToolBarView.hidden = YES;
    }
    return _connectToolBarView;
}

/**工具栏
 */
- (UIScrollView *)toolBarView{
    if(!_toolBarView){
        _toolBarView =  [UIScrollView new];
//        if(iPhone_X){
//            _toolBarView.frame = CGRectMake(0, (self.playerView.frame.size.height + self.playerView.frame.origin.y), kWIDTH, 88);
//        }else
        _toolBarView.frame = CGRectMake(0,  operationView.frame.size.height*0.5/5.0, kWIDTH, operationView.frame.size.height*2.0/5.0);
        _toolBarView.backgroundColor = [UIColor clearColor];
        _toolBarView.showsVerticalScrollIndicator = NO;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        _toolBarView.tag = 1000;
        NSInteger count = (toolItems.count>5)?toolItems.count:4;
        if( (count == 4) && (toolItems.count%2) == 0.0 )
        {
            count = 3;
        }
        __block float toolItemBtnWidth = MAX(kWIDTH/count, 60 + 5);//_toolBarView.frame.size.height
        __block int iIndex = kWIDTH/toolItemBtnWidth + 1.0;
        __block float width = toolItemBtnWidth;
        toolItemBtnWidth = toolItemBtnWidth - ((toolItems.count > iIndex)?(toolItemBtnWidth/2.0/(iIndex)):0);
        __block float contentsWidth = 0;
        [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString([toolItems[idx] objectForKey:@"title"], nil) andHeight:12 fontSize:12] + 15 ;
            
            if( ItemBtnWidth < toolItemBtnWidth )
                ItemBtnWidth = toolItemBtnWidth;
            
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.frame = CGRectMake( contentsWidth + ((toolItems.count > iIndex)?(width/2.0/(iIndex)):0), 0, ItemBtnWidth, _toolBarView.frame.size.height);
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
            [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@默认_", [toolItems[idx] objectForKey:@"title"]]] forState:UIControlStateNormal];
            [toolItemBtn setTitle:RDLocalizedString([toolItems[idx] objectForKey:@"title"], nil) forState:UIControlStateNormal];
//            if ([UIScreen mainScreen].bounds.size.width >= 414) {
//                toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:11];
//            }else {
//                toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:10];
//            }
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (ItemBtnWidth - 44)/2.0, 16, (ItemBtnWidth - 44)/2.0)];
            [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            [_toolBarView addSubview:toolItemBtn];
            contentsWidth += ItemBtnWidth;
        }];
        
        if( contentsWidth <= kWIDTH )
        contentsWidth = kWIDTH + 10;
        
        _toolBarView.contentSize = CGSizeMake(contentsWidth+ 10, 0);
        [self getToolBarItems];
    }
    return _toolBarView;
}

//TODO:返回
- (void)back{
    [self.videoThumbSlider setContentOffset:CGPointMake(0, 0)];
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.animationDuration = 0;
        obj.animationName = nil;
    }];
    
    if(_cancelBlock){
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK stop];
        }
        _cancelBlock();
    }
    
    if( _backNextEditVideoCancelBlock )
    {
        CMTime time = _videoCoreSDK.currentTime;
        if( _isModigy )
        {
            [_videoCoreSDK stop];
            [_videoCoreSDK.view removeFromSuperview];
            _videoCoreSDK.delegate = nil;
            _videoCoreSDK = nil;
        }
        _backNextEditVideoCancelBlock(_videoCoreSDK,time);
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if(self.push){
        [self.navigationController popViewControllerAnimated:YES];
         [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    

    
    [self dismissViewControllerAnimated:NO completion:nil];
}
//TODO:下一步
- (void)tapcontinueBtn{
    
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && _videoCoreSDK.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [_hud setCaption:message];
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    
    if(_fromToNext){
        CMTime time = _videoCoreSDK.currentTime;
        if( _isModigy )
        {
//            [_videoCoreSDK stop];
//            [_videoCoreSDK.view removeFromSuperview];
//            _videoCoreSDK.delegate = nil;
//            _videoCoreSDK = nil;
            if(_backNextEditVideoVCBlock){
                _backNextEditVideoVCBlock(_fileList, exportSize,time);
            }
        }
        else
        {
            if(_backNextEditVideoVCBlock){
                _backNextEditVideoVCBlock(nil, exportSize,time);
            }
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return;
    }
    
    [_videoCoreSDK stop];
    
    WeakSelf(self);
    RDNextEditVideoViewController *nextEditVideoVC = [[RDNextEditVideoViewController alloc] init];
    nextEditVideoVC.fileList = _fileList;
    nextEditVideoVC.exportVideoSize = exportSize;
    nextEditVideoVC.musicURL = _musicURL;
    nextEditVideoVC.musicVolume = _musicVolume;
    nextEditVideoVC.musicTimeRange = _musicTimeRange;
    nextEditVideoVC.cancelActionBlock = ^{
        [weakSelf playVideo:NO];
    };
    [self.navigationController pushViewController:nextEditVideoVC animated:YES];
}

/**初始化播放器
 */
- (void)initPlayer:(void(^)(void))completedBlock{
    [_videoCoreSDK stop];
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    //exportSize = [self getEditVideoSize];
    [self performSelector:@selector(player:) withObject:completedBlock afterDelay:0.01];
    //[self player: completedBlock ];
}
- (void)player:(void(^)(void))completedBlock{
    [scenes removeAllObjects];
    scenes = nil;
    scenes = [NSMutableArray array];
    
    for (int i = 0; i<_fileList.count; i++) {
        RDFile *file = _fileList[i];
        RDScene *scene = [[RDScene alloc] init];
        if (file.fileCropModeType == kCropTypeNone) {
            file.fileCropModeType = _proportionIndex;
        }
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        vvasset.identifier = [NSString stringWithFormat:@"video%d", i];
        if (globalFilters.count > 0) {
            RDFilter* filter = globalFilters[file.filterIndex];
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
            vvasset.audioFadeInDuration = file.audioFadeInDuration;
            vvasset.audioFadeOutDuration = file.audioFadeOutDuration;
        }else{
            vvasset.type         = RDAssetTypeImage;
            if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                vvasset.timeRange = file.imageTimeRange;
            }else {
                vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            }
            vvasset.speed        = file.speed;
            
            if( !_isMotion  )
                vvasset.fillType = RDImageFillTypeFit;
#if isUseCustomLayer
            if (file.fileType == kTEXTTITLE) {
                vvasset.fillType = RDImageFillTypeFull;
            }
#endif
        }
        CGSize size;
        if (file.fileType == kFILEVIDEO) {
            size = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:file.contentURL]];
        }else {
            UIImage *image = file.thumbImage ? file.thumbImage : [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
            size = image.size;
        }
        CGSize trsize = size;
        if(file.rotate == -270 || file.rotate == -90){
            trsize.width = size.height;
            trsize.height = size.width;
        }
        float exportRatio = exportSize.width/exportSize.height;
        float assetRatio = (trsize.width * file.crop.size.width)/(trsize.height * file.crop.size.height);
        NSLog(@"exportSize:%@ trsize:%@ sR:%f eR:%f sw:%f", NSStringFromCGSize(exportSize), NSStringFromCGSize(trsize), assetRatio, exportRatio, trsize.width * file.crop.size.width);
        if(file.fileType != kTEXTTITLE && (assetRatio < exportRatio)  && self.isVague)
        {
            vvasset.blurIntensity = 1.0;
        }else{
            vvasset.isBlurredBorder = NO;
        }
        if(i != self.fileList.count - 1 && ( ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition )){
            [RDHelpClass setTransition:scene.transition file:file];
        }
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.crop = file.crop;
        //透明度
        vvasset.alpha = file.backgroundAlpha;
        //美颜
        vvasset.beautyBlurIntensity =  file.beautyValue;
//        vvasset.beautyToneIntensity = file.beautyValue;
//        vvasset.beautyBrightIntensity = file.beautyValue;
        //调色
        vvasset.brightness = file.brightness;
        vvasset.contrast = file.contrast;
        vvasset.saturation = file.saturation;
        vvasset.sharpness = file.sharpness;
        vvasset.whiteBalance = file.whiteBalance;
        vvasset.vignette = file.vignette;
        
        if( file.backgroundType !=  KCanvasType_None )
        {
            vvasset.rectInVideo = file.rectInScene;
            if( file.backgroundType != KCanvasType_Color )
            {
                scene.backgroundAsset = [RDHelpClass canvasFile:file.BackgroundFile];
            }
            else
                scene.backgroundColor = file.backgroundColor;
            
            vvasset.rotate = file.rotate +  file.BackgroundRotate;
        }
        
        if( file.animationDuration > 0 )
        {
            [RDHelpClass setAssetAnimationArray:vvasset name:file.animationName duration:file.animationDuration center:
             CGPointMake(file.rectInScene.origin.x + file.rectInScene.size.width/2.0, file.rectInScene.origin.y + file.rectInScene.size.height/2.0) scale:file.rectInScale];
        }
        
        [scene.vvAsset addObject:vvasset];
        
        if(file.customFilterId != 0 ) {
            RDCustomFilter * customFilteShear = nil;
            if (!_filterFxArray && ((RDNavigationViewController *)self.navigationController).editConfiguration.specialEffectResourceURL.length > 0) {
                [self getFilterFxArray];
            }
            if (_filterFxArray.count > 0) {
                customFilteShear = [RDGenSpecialEffect getCustomFilerWithFxId:file.customFilterId filterFxArray:_filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
                
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger        idx2, BOOL * _Nonnull stop2) {
                    asset.customFilter = customFilteShear;
                }];
            }
        }
        
        if( file.fileTimeFilterType !=  kTimeFilterTyp_None )
        {
            [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:file atscene:scene atTimeRange:file.fileTimeFilterTimeRange atIsRemove:NO];
        }
        else
            [scenes addObject:scene];
    }
    if(!_videoCoreSDK){
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:exportSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];        
        _videoCoreSDK.delegate = self;
    }
    if (!_videoCoreSDK.view.superview) {
        _videoCoreSDK.frame = self.playerView.bounds;
        [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
    }
    [_videoCoreSDK setEditorVideoSize:exportSize];
    [_videoCoreSDK setScenes:scenes];
    
    NSMutableArray *array = [NSMutableArray new];
    
    if (_collages.count > 0)
    {
        [array addObjectsFromArray:_collages];
    }
    if (_doodles.count > 0)
    {
        [array addObjectsFromArray:_doodles];
    }
    if( _watermark )
        [array addObject:_watermark];
    
    if( array.count > 0 )
        _videoCoreSDK.watermarkArray = array;
    
    _videoCoreSDK.enableAudioEffect = YES;
    [_videoCoreSDK build];
    
    if( !self.isVague )
        [self setBackGroundColorWithRed];
    
    if(completedBlock)
        completedBlock();
    else
        self.durationLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:_videoCoreSDK.duration]];
    
    if( isRefeshNextThumbCore && _NextEditThumbImageVideoCoreBlock )
    {
        isRefeshNextThumbCore = false;
        _NextEditThumbImageVideoCoreBlock(_fileList);
    }
}

/**获取工具栏Icon图标地址
 */
- (NSString *)connectToolItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_添加图片默认_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_添加视频默认_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_添加文字板默认_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_切换转场默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

- (void)getFilterFxArray {
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    __block NSMutableArray *oldFilterFxArray = [NSMutableArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
    if ([lexiu currentReachabilityStatus] == RDNotReachable) {
        if (oldFilterFxArray.count == 0) {
            [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
        }else {
            _filterFxArray = oldFilterFxArray;
        }
    }else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
            _filterFxArray = [RDHelpClass getFxArrayWithAppkey:nav.appKey
                                                   typeUrlPath:nav.editConfiguration.netMaterialTypeURL
                                          specialEffectUrlPath:nav.editConfiguration.specialEffectResourceURL];
        });
    }
}

#pragma mark- 功能选项
/**功能选择
 */
- (void)clickToolItemBtn:(UIButton *)sender{
    seekTime = _videoCoreSDK.currentTime;
    [self playVideo:NO];
//    TICK;
    if( isNewCoreSDK)
    {
        if (sender.tag == kRDTRIM
            || sender.tag == kRDSPLIT
            || sender.tag == kRDCHANGESPEED
            || sender.tag == kRDSINGLEFILTER
            || sender.tag == KRDADJUST
            || sender.tag == KRDEFFECTS
            || sender.tag == kRDSORT
            || sender.tag == kRDEDIT)
        {
            isNewCoreSDK = false;
//            TOCK;
            currentMinCoreSDK = [self getCore:_fileList[selectFileIndex] atIsExpSize:(sender.tag == kRDEDIT)];
            CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
            [currentMinCoreSDK seekToTime:time];
//            TOCK;
        }
    }
    else if(sender.tag == kRDEDIT)
    {
        isNewCoreSDK = false;
//        TOCK;
        currentMinCoreSDK = [self getCore:_fileList[selectFileIndex] atIsExpSize:true];
        CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        [currentMinCoreSDK seekToTime:time];
//        TOCK;
    }
    switch (sender.tag) {
        case kRDTRIM://1
        {
            [self enter_Trim];
        }
            break;
        case kRDSPLIT://1
        {
            [self enter_Comminte];
        }
            break;
        case kRDEDIT://1
        {
            [self enter_Edit];
        }
            break;
        case kRDCHANGESPEED://1
        {
            [self enter_Speed];
        }
            break;
        case kRDCOPY:
        {
            [self enter_Reproduce];
        }
            break;
        case kRDREVERSEVIDEO:
        {
            [self enter_Reverse];
        }
            break;
        case KTRANSITION:
        {
//            [self changeTransition:selectFileIndex];
            animationStartTime = _videoCoreSDK.currentTime;
            [self changeTransition];
//            [strongSelf setWhetherToModify:YES]; //转场
            
        }
            break;
        case kRDSINGLEFILTER: //1
        {
            [self enter_Filter];
        }
            break;
        case KRDADJUST: //1
        {
            [self enter_adjust];
        }
            break;
        case KRDEFFECTS: //1
        {
            //特效
            [self enter_effects];
        }
            break;
        case kRDSORT: //1
        {
            //调序
            [self enter_Sort];
        }
            break;
        case KMIRROR:
        {
            //水平翻转
            _fileList[selectFileIndex].isHorizontalMirror = !_fileList[selectFileIndex].isHorizontalMirror;
            if( !scenes && ( scenes.count ==0 ) )
            {
                scenes = [_videoCoreSDK getScenes];
            }
            
            _fileList[selectFileIndex].cropRect = CGRectMake(-1, -1, -1, -1);
            
            if( scenes && ( scenes.count > 0 ) )
            {
                [((RDScene *)scenes[selectFileIndex]).vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.isHorizontalMirror = _fileList[selectFileIndex].isHorizontalMirror;
                }];
            }
            [_videoCoreSDK refreshCurrentFrame];
        }
            break;
        case KROTATE:
        {
            //旋转
            if(_fileList[selectFileIndex].rotate == 0){
                _fileList[selectFileIndex].rotate = -90;
            }else if(_fileList[selectFileIndex].rotate == -90){
                _fileList[selectFileIndex].rotate = -180;
            }else if(_fileList[selectFileIndex].rotate == -180){
                _fileList[selectFileIndex].rotate = -270;
            }else if(_fileList[selectFileIndex].rotate == -270){
                _fileList[selectFileIndex].rotate = 0;
            }
            
            [RDHelpClass fileCrop:_fileList[selectFileIndex] atfileCropModeType:_fileList[selectFileIndex].fileCropModeType atEditSize:exportSize];
            
            if( !scenes && ( scenes.count ==0 ) )
            {
                scenes = [_videoCoreSDK getScenes];
            }
            if( scenes && ( scenes.count > 0 ) )
            {
                [((RDScene *)scenes[selectFileIndex]).vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.rotate = _fileList[selectFileIndex].rotate + _fileList[selectFileIndex].BackgroundRotate;
                    obj.crop = _fileList[selectFileIndex].crop;
                }];
            }
            [_videoCoreSDK refreshCurrentFrame];
        }
            break;
        case KFLIPUPANDDOWN:
        {
            //垂直翻转
            _fileList[selectFileIndex].isVerticalMirror = !_fileList[selectFileIndex].isVerticalMirror;
            if( !scenes && ( scenes.count ==0 ) )
            {
                scenes = [_videoCoreSDK getScenes];
            }
            
            _fileList[selectFileIndex].cropRect = CGRectMake(-1, -1, -1, -1);
            
            
            if( scenes && ( scenes.count > 0 ) )
            {
                [((RDScene *)scenes[selectFileIndex]).vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.isVerticalMirror = _fileList[selectFileIndex].isVerticalMirror;
                }];
            }
            [_videoCoreSDK refreshCurrentFrame];
        }
            break;
        case KVOLUME:
        {
            _titleView.hidden = YES;
            
            transitionPlayButtonRect = _playButton.frame;
            [self.view addSubview:_playButton];
            _playButton.frame = CGRectMake(5,_playButton.frame.origin.y - 28, _playButton.frame.size.width, _playButton.frame.size.height);
            transitionPlayViewRect = _playerView.frame;
//            _playerView.frame =  CGRectMake(_playerView.frame.origin.x, kPlayerViewOriginX, _playerView.frame.size.width, kHEIGHT - ( 40 + 35 + 80 + kToolbarHeight ) - kPlayerViewOriginX);
            _videoProgressSlider.hidden = YES;
            _durationLabel.hidden  = YES;
            _currentLabel.hidden = YES;
            
            _videoCoreSDK.frame = _playerView.bounds;
            [self.view insertSubview:self.titleView aboveSubview:self.playerView];
            
            self.volumeView.hidden = NO;
            [_volumeProgressSlider setValue:_fileList[selectFileIndex].videoVolume/2.0];
            [RDHelpClass animateView:_volumeView atUP:NO];
        }
            break;
        case kRDTEXTTITLE:
        {
            if(_fileList[selectFileIndex].fileType == kTEXTTITLE)
                [self enter_TextPhotoVC:YES];
        }
            break;
        case KREPLACE://替换
        {
            isSeplace = true;
            if( _fileList[selectFileIndex].fileType == kFILEIMAGE )
            {
                [self AddFile:ONLYSUPPORT_IMAGE touchConnect: NO];
            }
            else
            {
                [self AddFile:ONLYSUPPORT_VIDEO touchConnect: NO];
            }
        }
            break;
        case KTRANSPARENCY://透明度
        {
            _titleView.hidden = YES;
            _playButton.hidden = YES;
            _videoProgressSlider.hidden = YES;
            _durationLabel.hidden  = YES;
            _currentLabel.hidden = YES;
            
            self.transparencyView.hidden = NO;
            [RDHelpClass animateView:_transparencyView atUP:NO];
            _transparencyProgressSlider.value = _fileList[selectFileIndex].backgroundAlpha;
            [self setTransparency];
        }
            break;
        case KBEAUTY://美颜
        {
            _titleView.hidden = YES;
            _playButton.hidden = YES;
            _videoProgressSlider.hidden = YES;
            _durationLabel.hidden  = YES;
            _currentLabel.hidden = YES;
            
            self.beautyView.hidden = NO;
            [RDHelpClass animateView:_beautyView atUP:NO];
            _beautyProgressSlider.value = _fileList[selectFileIndex].beautyValue;
            [self setBeauty];
        }
            break;
        case KRDANIMATION://动画
        {
            
            animationStartTime = _videoCoreSDK.currentTime;
            isAnimation = true;
            _titleView.hidden = YES;
            _playButton.hidden = YES;
            _videoProgressSlider.hidden = YES;
            _durationLabel.hidden  = YES;
            _currentLabel.hidden = YES;
            operationView.hidden = YES;
            isToolBarView = false;
            _bottomView.hidden = NO;
            RDFile *file = _fileList[selectFileIndex];
            float duration = 0.0;
            if (file.fileType == kFILEVIDEO) {
                if(file.isReverse){
                    if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                        duration = CMTimeGetSeconds(file.reverseDurationTime);
                    }else{
                        duration = CMTimeGetSeconds(file.reverseVideoTimeRange.duration);
                    }
                    if(!CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTrimTimeRange) && duration > CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)){
                        duration = CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration);
                    }
                }else{
                    if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                        duration = CMTimeGetSeconds(file.videoDurationTime);
                        if(duration == 0){
                            duration = CMTimeGetSeconds([AVURLAsset assetWithURL:file.contentURL].duration);
                        }
                    }else{
                        duration = CMTimeGetSeconds(file.videoTimeRange.duration);
                    }
                    if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && duration > CMTimeGetSeconds(file.videoTrimTimeRange.duration)){
                        duration = CMTimeGetSeconds(file.videoTrimTimeRange.duration);
                    }
                }
            }else {
                if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                    duration = CMTimeGetSeconds(file.imageTimeRange.duration);
                }else {
                    duration = CMTimeGetSeconds(file.imageDurationTime);
                }
            }
            animationDurationSlider.maximumValue = duration;
            
            if (file.animationName.length > 0 && file.animationDuration > 0) {
                animationDurationSlider.value = file.animationDuration;
            }else {
                animationDurationSlider.value = (duration>1.0)?1.0:duration;
            }
            
            animationDurationLbl.text = [NSString stringWithFormat:@"%.1f秒",animationDurationSlider.value];
            
            selectedAnimationIndex = 1;
            if (file.animationName.length > 0 && file.animationDuration > 0) {
                [animationArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isEqualToString:file.animationName]) {
                        selectedAnimationIndex = idx + 2;
                        *stop = YES;
                    }
                }];
            }
            
            RDAddItemButton *itemBtn = [animationScrollView viewWithTag:selectedAnimationIndex];
            itemBtn.selected = YES;
            itemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
            [itemBtn  textColor: [UIColor whiteColor] ];
            
            if (selectedAnimationIndex == 1) {
                animationDurationSlider.enabled = FALSE;
                animationDurationView.hidden = YES;
            }else {
                animationDurationSlider.enabled = true;
                animationDurationView.hidden = NO;
            }
            
            self.animationView.hidden = NO;
            
            if( itemBtn.frame.origin.x > ( animationScrollView.contentSize.width - animationScrollView.frame.size.width ) )
                animationScrollView.contentOffset = CGPointMake(( animationScrollView.contentSize.width - animationScrollView.frame.size.width ), 0);
            else
                animationScrollView.contentOffset = CGPointMake( itemBtn.frame.origin.x, 0);
            
        }
            break;
        default:
            break;
    }
}

- (void)clickConnectToolItemBtn:(UIButton *)sender{
    switch (sender.tag - 1) {
        case 0:
        {
           [self AddFile:ONLYSUPPORT_IMAGE touchConnect: NO];
        }
            break;
        case 1:
        {
            [self AddFile:ONLYSUPPORT_VIDEO touchConnect: NO];
        }
            break;
        case 2:
        {
            [self enter_TextPhotoVC:NO];
        }
            break;
        case 3:
        {
//            [self changeTransition:selectFileIndex];
            [self changeTransition];
        }
            break;
        default:
            break;
    }
}


- (void)playVideo:(BOOL)play{
    if(play){
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
         }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
//        _playButton.hidden = YES;
    }else{
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
//        _playButton.hidden = NO;
    }
    isPlaying = _videoCoreSDK.isPlaying;
}

/**点击播放暂停按钮
 */
- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

/**进入滤镜
 */
- (void)enter_Filter {
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if([lexiu currentReachabilityStatus] == RDNotReachable){
        [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    RDFilterViewController *filterVC = [[RDFilterViewController alloc] init];
    filterVC.file = _fileList[selectFileIndex];
    filterVC.exportSize = exportSize;
    CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
    [currentMinCoreSDK seekToTime:time];
    [filterVC seekTime:time];
    [filterVC setVideoCoreSDK:currentMinCoreSDK];
    filterVC.filtersName = filtersName;
    filterVC.NewFilterSortArray = newFilterSortArray;
    filterVC.NewFiltersNameSortArray =  newFiltersNameSortArray;
    filterVC.globalFilters = globalFilters;
    filterVC.changeFilterFinish = ^(NSInteger filterIndex, VVAssetFilter filterType, float filterIntensity, NSURL *filterUrl, BOOL useToAll) {
        [self setWhetherToModify:YES];
        if( !scenes && ( scenes.count == 0 ) )
            scenes = [_videoCoreSDK getScenes];
        if (useToAll) {
            [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.filterIndex = filterIndex;
                obj.filterIntensity = filterIntensity;
            }];
            if( scenes && ( scenes.count > 0 ) )
            {
                [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        asset.filterType = filterType;
                        asset.filterUrl = filterUrl;
                        asset.filterIntensity = filterIntensity;
                    }];
                }];
            }
        }else {
            _fileList[selectFileIndex].filterIndex = filterIndex;
             _fileList[selectFileIndex].filterIntensity = filterIntensity;
            NSString *identifier = [NSString stringWithFormat:@"video%ld", (long)self->selectFileIndex];
            __block NSString *prevIdentifier = nil;
            if( scenes && ( scenes.count > 0 ) ){
                [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        if ([asset.identifier isEqualToString:identifier]) {
                            prevIdentifier = identifier;
                            asset.filterType = filterType;
                            asset.filterUrl = filterUrl;
                            asset.filterIntensity = filterIntensity;
                            *stop2 = YES;
                        }else if (prevIdentifier.length > 0) {
                            *stop1 = YES;
                        }
                    }];
                }];
            }
        }
        
        CMTime time = currentMinCoreSDK.currentTime;
        time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        if( CMTimeGetSeconds(time) != CMTimeGetSeconds(_videoCoreSDK.currentTime) )
        {
            [_videoCoreSDK seekToTime:time];
        }
        else
        {
            [_videoCoreSDK refreshCurrentFrame];
        }
    };
    
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:filterVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nav animated:YES completion:nil];
}

- (CGSize )getVideoSizeForTrack{
    CGSize size = CGSizeZero;
    AVURLAsset *asset = [AVURLAsset assetWithURL:_fileList[selectFileIndex].contentURL];
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
    }
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    return size;
}

-(RDVECore * )getCore:(RDFile *) _file atIsExpSize:(bool) isExpSize
{
    if( currentMinCoreSDK )
    {
        [currentMinCoreSDK stop];
        currentMinCoreSDK.delegate = nil;
        currentMinCoreSDK = nil;
    }
    NSMutableArray *scenes = [NSMutableArray array];
    RDScene *scene = [[RDScene alloc] init];
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = _file.contentURL;
    if (globalFilters.count > 0) {
        RDFilter* filter = globalFilters[_file.filterIndex];
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
    
    if(_file.fileType == kFILEVIDEO){
        vvasset.type = RDAssetTypeVideo;
        vvasset.videoActualTimeRange = _file.videoActualTimeRange;
//        [RDVECore assetMetadata:_file.contentURL];
        vvasset.timeRange = _file.videoTimeRange;
        vvasset.speed        = _file.speed;
        vvasset.volume       = _file.videoVolume;
        vvasset.audioFadeInDuration = _file.audioFadeInDuration;
        vvasset.audioFadeOutDuration = _file.audioFadeOutDuration;
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
    if(!isExpSize)
        vvasset.crop = _file.crop;
    
    vvasset.brightness = _file.brightness;
    vvasset.contrast = _file.contrast;
    vvasset.saturation = _file.saturation;
    vvasset.sharpness = _file.sharpness;
    vvasset.whiteBalance = _file.whiteBalance;
    vvasset.vignette = _file.vignette;
    [scene.vvAsset addObject:vvasset];
    
    //添加特效
    //滤镜特效
    if( _file.customFilterIndex != 0 )
    {
        NSArray *filterFxArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        vvasset.customFilter = [RDGenSpecialEffect getCustomFilerWithFxId:_file.customFilterId filterFxArray:filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
    }
    //时间特效
    if( _file.fileTimeFilterType != kTimeFilterTyp_None )
    {
        [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:_file atscene:scene atTimeRange:_file.fileTimeFilterTimeRange atIsRemove:NO];
    }
    else
        [scenes addObject:scene];
    
    if(isExpSize)
    {
        bool _isPortrait = false;
        if(_file.isReverse){
            _isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_file.reverseVideoURL]];
        }else{
            _isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_file.contentURL]];
        }
        
        if(_file.fileType == kFILEIMAGE){
            UIImage *image = [RDHelpClass getFullScreenImageWithUrl:_file.contentURL];
            
            if(_file.isHorizontalMirror && _file.isVerticalMirror){
                float rotate = 0;
                if(_file.rotate == 0){
                    rotate = -180;
                }else if(_file.rotate == -90){
                    rotate = -270;
                }else if(_file.rotate == -180){
                    rotate = -0;
                }else if(_file.rotate == -270){
                    rotate = -90;
                }
                UIImage * _currentImage = [RDHelpClass imageRotatedByDegrees:image rotation: rotate];
                currentMinExportSize  = _currentImage.size;
                
            }else{
                UIImage * _currentImage = [RDHelpClass imageRotatedByDegrees:image rotation: _file.rotate];
                currentMinExportSize  = _currentImage.size;
            }
        }
        else{
            CGSize size = [self getVideoSizeForTrack];
            currentMinExportSize = size;
            
            if(size.height == size.width){
                
                currentMinExportSize        = size;
                
            }else if(_isPortrait){
                currentMinExportSize = size;
                
                if(size.height < size.width){
                    currentMinExportSize  = CGSizeMake(size.height, size.width);
                }
                if(_file.rotate == -90 || _file.rotate == -270){
                    currentMinExportSize  = CGSizeMake(size.width, size.height);
                }
            }else{
                currentMinExportSize  = [self getVideoSizeForTrack];
                if(_file.rotate == -90 || _file.rotate == -270){
                    CGSize size = [self getVideoSizeForTrack];
                    currentMinExportSize  = CGSizeMake(size.height, size.width);
                }
            }
            if(_file.rotate == -90 || _file.rotate == -270){
                if(currentMinExportSize.height>currentMinExportSize.width && _isPortrait){
                    currentMinExportSize = CGSizeMake(currentMinExportSize.height, currentMinExportSize.width);
                }
            }
        }
    }
    else
        currentMinExportSize = exportSize;
    
    RDVECore *core = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:currentMinExportSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
    core.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
    [core setScenes:scenes];
    [core build];
    return core;
}

/**进入截取
 */
- (void)enter_Trim{
    
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    RDFile *file = [_fileList objectAtIndex:selectFileIndex];
    //时间小于0.2不让截取
    int dd;
    if (file.isGif) {
        dd = CMTimeGetSeconds(file.imageDurationTime)*100 / file.speed;
    }else {
        dd = CMTimeGetSeconds(file.videoTimeRange.duration)*100 / file.speed;
        if(file.isReverse){
            dd = CMTimeGetSeconds(file.reverseVideoTimeRange.duration)*100/ file.speed;
        }
    }
    if(dd<1.0 * 100){
        [_hud setCaption:RDLocalizedString(@"截取不能小于1.0秒!", nil)];
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    
    
    RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
    CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
    [currentMinCoreSDK seekToTime:time];
    [trimVideoVC seekTime:time];
    [trimVideoVC setVideoCoreSDK:currentMinCoreSDK];
    trimVideoVC.globalFilters = globalFilters;
    trimVideoVC.trimFile = [_fileList[selectFileIndex] copy];
    trimVideoVC.editVideoSize = exportSize;
    trimVideoVC.musicURL = _musicURL;
    trimVideoVC.musicVolume = _musicVolume;
    trimVideoVC.musicTimeRange = _musicTimeRange;
    isRefresh = true;
    
    trimVideoVC.TrimVideoFinishBlock = ^(CMTimeRange timeRange) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            
        });
        
        isRefresh = false;
        
        [self trimVideoFinishBlock:timeRange];
        
    };
    
    //    [self.navigationController pushViewController:trimVideoVC animated:NO];
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)trimVideoFinishBlock:(CMTimeRange) timeRange
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        StrongSelf(self);
        
        isRefeshNextThumbCore = true;
        
        [strongSelf setWhetherToModify:YES];
        
        isNeedPrepare = NO;
        RDFile *file = _fileList[selectFileIndex];
        if(file.isReverse){
            file.reverseVideoTrimTimeRange = timeRange;
            if( (file.backgroundType !=  KCanvasType_None) && (file.backgroundType !=  KCanvasType_Color) )
            {
                if( file.backgroundType ==  KCanvasType_Style )
                    file.BackgroundFile.imageTimeRange = timeRange;
                else
                    file.BackgroundFile.reverseVideoTrimTimeRange = timeRange;
            }
        }else if (file.isGif) {
            file.imageTimeRange = timeRange;
            if( (file.backgroundType !=  KCanvasType_None) && (file.backgroundType !=  KCanvasType_Color) )
            {
                file.BackgroundFile.imageTimeRange = timeRange;
            }
        }else {
            file.videoTrimTimeRange = timeRange;
            if( (file.backgroundType !=  KCanvasType_None) && (file.backgroundType !=  KCanvasType_Color) )
            {
                if( file.backgroundType ==  KCanvasType_Style )
                    file.BackgroundFile.imageTimeRange = timeRange;
                else
                    file.BackgroundFile.videoTrimTimeRange = timeRange;
            }
        }
        file.transitionDuration = MIN([weakSelf maxTransitionDuration:selectFileIndex], file.transitionDuration);
        if (selectFileIndex > 0) {
            _fileList[selectFileIndex - 1].transitionDuration = MIN([weakSelf maxTransitionDuration:selectFileIndex], _fileList[selectFileIndex - 1].transitionDuration);
        }
        
        NSLog(@"%lf : %lf",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
        [_fileList replaceObjectAtIndex:selectFileIndex withObject:file];
        
        __block NSMutableArray<__kindof UIView *> *subviews = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            subviews = strongSelf.videoThumbSliderback.subviews;
            
            
            [subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([obj isKindOfClass:[RDThumbImageView class]]){
                    if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            ((RDThumbImageView *)obj).contentFile = _fileList[selectFileIndex];
                            ((RDThumbImageView *)obj).thumbIconView.image = _fileList[selectFileIndex].thumbImage;
                        });
                        *stop = YES;
                    }
                }
            }];
        });
        
        CMTime time = currentMinCoreSDK.currentTime;
        time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        //        [_videoCoreSDK filterRefresh:time];
        seekTime = time;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf player:^{
#if isUseCustomLayer
                [strongSelf refreshCustomTextTimeRange];
#endif
            }];
            
            currentMinCoreSDK = [self getCore:_fileList[selectFileIndex] atIsExpSize:NO];
        });
    });
}

/**进入分割
 */
- (void)enter_Comminte{
    
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    int dd;
    RDFile *file = [_fileList objectAtIndex:selectFileIndex];
    if (file.isGif) {
        dd = CMTimeGetSeconds(file.imageDurationTime)*100 / file.speed;
        if(CMTimeGetSeconds(file.imageTimeRange.duration)>0){
            dd = CMTimeGetSeconds(file.imageTimeRange.duration)*100/ file.speed;
        }
    }else {
        dd = CMTimeGetSeconds(file.videoTimeRange.duration)*100 / file.speed;
        if(CMTimeGetSeconds(file.videoTrimTimeRange.duration)>0){
            dd = CMTimeGetSeconds(file.videoTrimTimeRange.duration)*100/ file.speed;
        }
        if(file.isReverse){
            dd = CMTimeGetSeconds(file.reverseVideoTimeRange.duration)*100/ file.speed;
            if(CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                dd = CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)*100/file.speed;
            }
        }
    }
    if(dd<0.4 * 100){
        [_hud setCaption:RDLocalizedString(@"分割不能小于0.4秒!", nil)];
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    
    ComminuteViewController *comminuteVC = [[ComminuteViewController alloc] init];
    CMTime start = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start;
    CMTime time = CMTimeSubtract(seekTime,start);
    [currentMinCoreSDK seekToTime:time];
    [comminuteVC seekTime:time];
    [comminuteVC setVideoCoreSDK:currentMinCoreSDK];
    comminuteVC.globalFilters = globalFilters;
    comminuteVC.editVideoSize = exportSize;
    comminuteVC.originFile = [[_fileList objectAtIndex:selectFileIndex] mutableCopy];
    comminuteVC.musicURL = _musicURL;
    comminuteVC.musicVolume = _musicVolume;
    comminuteVC.musicTimeRange = _musicTimeRange;
    isRefresh = true;
    comminuteVC.comminuteVideoFinishBlock = ^(NSMutableArray <RDFile *>*childs) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
        });
        isRefresh = false;
        [self comminuteVideoFinishBlock:childs];
    };
    
//    [self.navigationController pushViewController:comminuteVC animated:NO];
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:comminuteVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)comminuteVideoFinishBlock:(NSMutableArray <RDFile *> *) childs
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        StrongSelf(self);
        [strongSelf setWhetherToModify:YES];
        
        isNeedPrepare = NO;
        [_fileList removeObjectAtIndex:selectFileIndex];
        for (NSInteger i = (childs.count- 1) ;i>=0; i--) {
            if(childs[i].transitionName.length==0){
                childs[i].transitionName = RDLocalizedString(@"无", nil);
            }
            [_fileList insertObject:childs[i] atIndex:selectFileIndex];
        }
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _fileList[idx].transitionDuration = MIN([strongSelf maxTransitionDuration:idx], _fileList[idx].transitionDuration);
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGPoint offset = strongSelf.videoThumbSlider.contentOffset;
            [strongSelf refreshVideoThumbSlider];
            [strongSelf.videoThumbSlider setContentOffset:offset];
        });
        
        CMTime time = currentMinCoreSDK.currentTime;
        time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        //        [_videoCoreSDK filterRefresh:time];
        seekTime = time;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            [strongSelf player:^{
#if isUseCustomLayer
                [strongSelf refreshCustomTextTimeRange];
#endif
            }];
        });
    });
}

/**进入编辑
 */
- (void)enter_Edit{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    if(_fileList[selectFileIndex].fileType == kTEXTTITLE){
        [self enter_TextPhotoVC:YES];
    }else{
        __weak typeof(self) weakSelf = self;
        CropViewController *cropVC = [[CropViewController alloc] init];
            
        CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
//        [currentMinCoreSDK seekToTime:time];
        [cropVC setVideoCoreSDK:currentMinCoreSDK];
        [cropVC seekTime:time];
        cropVC.globalFilters = globalFilters;
        cropVC.selectFile       = _fileList[selectFileIndex];
        cropVC.musicURL         = _musicURL;
        cropVC.musicVolume      = _musicVolume;
        cropVC.musicTimeRange   = _musicTimeRange;
        isRefresh = true;
        _playerView.hidden = YES;
        
        cropVC.editVideoForOnceFinishAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
            StrongSelf(self);
            [strongSelf setWhetherToModify:YES];
            isNeedPrepare = NO;
            isRefresh = false;
            
            CGSize videoSize = CGSizeMake( cropRect.size.width/crop.size.width , cropRect.size.height/crop.size.height);
            
            if(verticalMirror != _fileList[selectFileIndex].isVerticalMirror)
            {
                if( (rotate != -90 ) && ( rotate != -270 ) )
                    crop = CGRectMake( 1.0 -   crop.origin.x - crop.size.width, 1.0 -  crop.origin.y - crop.size.height, crop.size.width, crop.size.height);
            }
            if(horizontalMirror != _fileList[selectFileIndex].isHorizontalMirror)
            {
                if( (rotate != -90 ) && ( rotate != -270 ) )
                    crop = CGRectMake( 1.0 -  crop.origin.x - crop.size.width, 1.0 -  crop.origin.y - crop.size.height, crop.size.width, crop.size.height);
            }

            
            float x = videoSize.width * crop.origin.x;
            float y = videoSize.height * crop.origin.y;
            cropRect = CGRectMake(x, y, cropRect.size.width, cropRect.size.height);
            
            _fileList[selectFileIndex].crop = crop;
            _fileList[selectFileIndex].cropRect = cropRect;
            _fileList[selectFileIndex].isVerticalMirror = verticalMirror;
            _fileList[selectFileIndex].isHorizontalMirror = horizontalMirror;
            _fileList[selectFileIndex].rotate = rotate;
            _fileList[selectFileIndex].fileCropModeType = cropModeType;
            
            [strongSelf.videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([obj isKindOfClass:[RDThumbImageView class]]){
                    if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                        ((RDThumbImageView *)obj).contentFile = _fileList[selectFileIndex];
                        ((RDThumbImageView *)obj).thumbIconView.image = _fileList[selectFileIndex].thumbImage;
                        *stop = YES;
                    }
                }
            }];
            
            NSString *identifier = [NSString stringWithFormat:@"video%ld", (long)self->selectFileIndex];
            __block NSString *prevIdentifier = nil;
            if( !scenes && ( scenes.count ==0 ) )
            {
                scenes = [_videoCoreSDK getScenes];
            }
            if( scenes && ( scenes.count > 0 ) )
            {
                [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        if ([asset.identifier isEqualToString:identifier]) {
                            prevIdentifier = identifier;
                            asset.crop = _fileList[selectFileIndex].crop;
                            asset.isVerticalMirror = verticalMirror;
                            asset.isHorizontalMirror = horizontalMirror;
                            asset.rotate = rotate + _fileList[selectFileIndex].BackgroundRotate;
                            *stop2 = YES;
                        }else if (prevIdentifier.length > 0) {
                            *stop1 = YES;
                        }
                    }];
                }];
            }
            
            CMTime time = currentMinCoreSDK.currentTime;
            time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
            if( CMTimeGetSeconds(time) != CMTimeGetSeconds(_videoCoreSDK.currentTime) )
            {
                [_videoCoreSDK seekToTime:time];
            }
            else
            {
                [_videoCoreSDK refreshCurrentFrame];
            }
        };
        
        RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
        [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
        nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:nav animated:YES completion:nil];
    }
    
}

/**进入变速
 */
- (void)enter_Speed{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    RDFile *file = [_fileList objectAtIndex:selectFileIndex];
    __weak typeof(self) weakSelf = self;
    ChangeSpeedVideoViewController *changeSpeedVC = [[ChangeSpeedVideoViewController alloc] init];
    
    CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
    [currentMinCoreSDK seekToTime:time];
    [changeSpeedVC seekTime:time];
    changeSpeedVC.globalFilters = globalFilters;
    [changeSpeedVC setVideoCoreSDK:currentMinCoreSDK];
    changeSpeedVC.editVideoSize = exportSize;
    changeSpeedVC.selectFile = file;
    changeSpeedVC.musicURL = _musicURL;
    changeSpeedVC.musicVolume = _musicVolume;
    changeSpeedVC.musicTimeRange = _musicTimeRange;
    isRefresh = true;
    changeSpeedVC.changeSpeedVideoFinishAction = ^(RDFile *file, BOOL useAllFile) {
        StrongSelf(self);
        isRefresh = false;
        isNeedPrepare = NO;
        [strongSelf setWhetherToModify:YES];
        if(useAllFile)
        {
            if(file.fileType == kFILEIMAGE){
                [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.fileType == kFILEIMAGE){
                        obj.imageDurationTime = file.imageDurationTime;
                        if( (obj.backgroundType !=  KCanvasType_None) && (obj.backgroundType !=  KCanvasType_Color) )
                        {
                            obj.BackgroundFile.imageTimeRange = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
                        }
                    }
                }];
            }else{
                [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.fileType == kFILEVIDEO){
                        obj.speed = file.speed;
                        obj.speedIndex = file.speedIndex;
                        obj.transitionDuration = MIN([weakSelf maxTransitionDuration:idx], obj.transitionDuration);
                        
                        if( (obj.backgroundType !=  KCanvasType_None) && (obj.backgroundType !=  KCanvasType_Color) )
                        {
                            obj.BackgroundFile.speed = file.speed;
                            obj.BackgroundFile.speedIndex = file.speedIndex;
                        }
                    }
                }];
            }
        }
        else{
            [_fileList replaceObjectAtIndex:selectFileIndex withObject:file];
            _fileList[selectFileIndex].transitionDuration = MIN([weakSelf maxTransitionDuration:selectFileIndex], _fileList[selectFileIndex].transitionDuration);
        }
        
        NSMutableArray *arra = [weakSelf.videoThumbSliderback.subviews mutableCopy];
        [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
            CGFloat obj1X = obj1.frame.origin.x;
            CGFloat obj2X = obj2.frame.origin.x;
            
            if (obj1X > obj2X) { // obj1排后面
                return NSOrderedDescending;
            } else { // obj1排前面
                return NSOrderedAscending;
            }
        }];
        
        [arra enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[RDThumbImageView class]]){
                NSInteger index = idx/2;
                _fileList[index].transitionDuration = MIN([weakSelf maxTransitionDuration:index], _fileList[index].transitionDuration);

                ((RDThumbImageView *)obj).contentFile = _fileList[index];
            }
        }];
        
        CMTime time = currentMinCoreSDK.currentTime;
        time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        //        [_videoCoreSDK filterRefresh:time];
        seekTime = time;
        
        [strongSelf player:^{
#if isUseCustomLayer
            [strongSelf refreshCustomTextTimeRange];
#endif
        }];
    };
    
    [self.navigationController pushViewController:changeSpeedVC animated:NO];
//    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:changeSpeedVC];
//    [self setNavConfig:nav];
//    [self presentViewController:nav animated:YES completion:nil];
    
}

/**进入复制
 */
- (void)enter_Reproduce{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    [self setWhetherToModify:YES];
    RDFile *file = [_fileList[selectFileIndex] mutableCopy];
    file.transitionName = (file.transitionName.length==0 ? RDLocalizedString(@"无", nil) : file.transitionName);
    if(file.fileType == kTEXTTITLE){
        NSString *tmpFilePaht = file.customTextPhotoFile.filePath;
        NSString *cachePath = [RDHelpClass getContentTextPhotoPath];
        [[NSFileManager defaultManager] copyItemAtPath:tmpFilePaht toPath:cachePath error:nil];
        file.contentURL = [NSURL fileURLWithPath:cachePath];
        file.customTextPhotoFile.filePath = cachePath;
        cachePath = nil;
        tmpFilePaht = nil;
        
        file.filtImagePatch = _fileList[selectFileIndex].filtImagePatch;
        file.BackgroundFile = [_fileList[selectFileIndex].BackgroundFile mutableCopy];
    }
    [_fileList insertObject:file atIndex:selectFileIndex];
    
//    [_toolBarView removeFromSuperview];
//    _toolBarView = nil;
    [self getToolBarItems];
//    [operationView addSubview:self.toolBarView];
    
    CGPoint offset = self.videoThumbSlider.contentOffset;
    
    [self refreshVideoThumbSlider];
    
    [self.videoThumbSlider setContentOffset:offset];
    
    seekTime = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start;
    WeakSelf(self);
    [self initPlayer:^{
#if isUseCustomLayer
        [weakSelf refreshCustomTextTimeRange];
#endif
    }];
}

/**进入倒序
 */
- (void)enter_Reverse{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    
    [self setWhetherToModify:YES];
    if([_fileList[selectFileIndex].reverseVideoURL absoluteString].length>0){
    
        _fileList[selectFileIndex].isReverse = !_fileList[selectFileIndex].isReverse;
        _fileList[selectFileIndex].thumbImage = [RDHelpClass assetGetThumImage:_fileList[selectFileIndex].isReverse ? CMTimeGetSeconds(_fileList[selectFileIndex].reverseVideoTrimTimeRange.start) : CMTimeGetSeconds(_fileList[selectFileIndex].videoTrimTimeRange.start) url:_fileList[selectFileIndex].isReverse ? _fileList[selectFileIndex].reverseVideoURL : _fileList[selectFileIndex].contentURL urlAsset:nil];

        [self.videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[RDThumbImageView class]]){
                if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                    ((RDThumbImageView *)obj).contentFile = _fileList[selectFileIndex];
                    ((RDThumbImageView *)obj).thumbIconView.image = _fileList[selectFileIndex].thumbImage;
                    *stop = YES;
                }
            }
        }];
        [self initPlayer:nil];
        return;
    }
    
    [self createFolder];
    isCancelExportReverse = NO;
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress2:0 animated:NO];
    [self performSelector:@selector(startReverseVideo) withObject:nil afterDelay:0.2];
}

/**创建存贮倒序文件的文件夹
 */
- (void)createFolder{
    NSString *exportPath = [kRDDraftDirectory stringByAppendingPathComponent:@"/Reverse"];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if(![manager fileExistsAtPath:exportPath]){
        [manager createDirectoryAtPath:exportPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

/**开始倒序操作
 */
- (void)startReverseVideo{
    __weak typeof(self) myself = self;
    NSURL *url = _fileList[selectFileIndex].contentURL;
    NSString * exportPath = nil;
    if([RDHelpClass isSystemPhotoUrl:url]){
        NSString *urlstr = [NSString stringWithFormat:@"%@",url];
        NSInteger loca = [urlstr rangeOfString:@"id="].location+3;
        NSInteger len = [urlstr rangeOfString:@"&ext"].location - loca;
        
        NSString *fileName = [urlstr substringWithRange:NSMakeRange(loca, len)];
        exportPath= [fileName stringByAppendingString:@"_reverseFile.mp4"];
        exportPath = [kRDDraftDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"/Reverse/%@",exportPath]];
        
    }else{
        exportPath= [[[[url absoluteString] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"_reverseFile.mp4"];
        exportPath = [kRDDraftDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"/Reverse/%@",exportPath]];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:kRDDraftDirectory]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kRDDraftDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    CMTimeRange timeRange = _fileList[selectFileIndex].videoTrimTimeRange;
    NSLog(@"reverse-->timeRange-->s:%f d:%f",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
    if(CMTimeRangeEqual(timeRange, kCMTimeRangeZero)){
        timeRange = _fileList[selectFileIndex].videoTimeRange;
        if(CMTimeRangeEqual(timeRange, kCMTimeRangeZero)){
            timeRange.start = kCMTimeZero;
            timeRange.duration = _fileList[selectFileIndex].videoDurationTime;
        }
    }
    _idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    [RDVECore exportReverseVideo:url outputUrl:[NSURL fileURLWithPath:exportPath] timeRange:timeRange videoSpeed:1/*_fileList[selectFileIndex].speed*/ progressBlock:^(NSNumber *prencent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"progress:%f",[prencent floatValue]);
            if(_exportProgressView)
            [_exportProgressView setProgress2:[prencent floatValue]*100.0 animated:NO];
        });
    } callbackBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"完成");
            [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
            myself.exportProgressView.hidden = YES;
            [myself.exportProgressView removeFromSuperview];
            _fileList[selectFileIndex].isReverse = YES;
            _fileList[selectFileIndex].reverseVideoURL = [NSURL fileURLWithPath:exportPath];
            CMTime duration = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:exportPath]].duration;
            _fileList[selectFileIndex].reverseDurationTime = duration;
            _fileList[selectFileIndex].reverseVideoTimeRange = CMTimeRangeMake(kCMTimeZero, _fileList[selectFileIndex].reverseDurationTime);
            _fileList[selectFileIndex].reverseVideoTrimTimeRange = _fileList[selectFileIndex].reverseVideoTimeRange;
            _fileList[selectFileIndex].thumbImage = [RDHelpClass assetGetThumImage:(CMTimeGetSeconds(duration)>1 ? 1 : 0) url:_fileList[selectFileIndex].reverseVideoURL urlAsset:nil];
            
            if( (_fileList[selectFileIndex].backgroundType !=  KCanvasType_None) && (_fileList[selectFileIndex].backgroundType !=  KCanvasType_Color) )
            {
                _fileList[selectFileIndex].BackgroundFile.reverseDurationTime = duration;
                _fileList[selectFileIndex].BackgroundFile.reverseVideoTimeRange =  _fileList[selectFileIndex].reverseVideoTimeRange;
                _fileList[selectFileIndex].BackgroundFile.reverseVideoTrimTimeRange = _fileList[selectFileIndex].reverseVideoTrimTimeRange;
            }
            
            [self.videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([obj isKindOfClass:[RDThumbImageView class]]){
                    if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                        ((RDThumbImageView *)obj).contentFile = _fileList[selectFileIndex];
                        ((RDThumbImageView *)obj).thumbIconView.image = _fileList[selectFileIndex].thumbImage;
                        *stop = YES;
                    }
                }
            }];
            [self initPlayer:nil];
        });
        
    } fail:^{
        NSLog(@"失败");
        [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
        myself.exportProgressView.hidden = YES;
        if(myself.exportProgressView.superview)
        [myself.exportProgressView removeFromSuperview];
    } cancel:&isCancelExportReverse];
    
}
#pragma mark- 进入排序
/**进入排序
 */
- (void)enter_Sort{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    NSMutableArray *arr = [_fileList mutableCopy];
    
    RD_SortViewController *rdSort = [[RD_SortViewController alloc] init];
    rdSort.allThumbFiles = arr;
    rdSort.editorVideoSize = exportSize;
    __weak typeof(self) weakSelf = self;
    isRefresh = true;
    rdSort.finishAction = ^(NSMutableArray *sortFileList){
        if(sortFileList.count>0){
            StrongSelf(self);
            [strongSelf setWhetherToModify:YES];
            isNeedPrepare = NO;
            //完成
            _fileList = [sortFileList mutableCopy];
            
            CGPoint offset = CGPointZero;
            [strongSelf.videoThumbSliderback.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [strongSelf.videoThumbSlider removeFromSuperview];
            strongSelf.videoThumbSlider = nil;
            [strongSelf videoThumbSlider];
            [strongSelf->operationView addSubview:weakSelf.videoThumbSliderView];
            
            [strongSelf.videoThumbSlider setContentOffset:offset];
            
//            [strongSelf.toolBarView removeFromSuperview];
//            strongSelf.toolBarView = nil;
            [strongSelf getToolBarItems];
//            [strongSelf->operationView addSubview:strongSelf.toolBarView];
            
            seekTime = _videoCoreSDK.currentTime;
            
            [strongSelf initPlayer:^{
#if isUseCustomLayer
                [strongSelf refreshCustomTextTimeRange];
#endif
            }];
            isRefresh = false;
        }
    };
    rdSort.cancelAction = ^(NSMutableArray *sortFileList){
        
        isRefresh = false;
        
    };
    [self.navigationController pushViewController:rdSort animated:NO];
    
}

/**添加转场
 */
- (void)enterTransition:(RDConnectBtn *)sender{
    isToolBarView = false;
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    selectFileIndex = sender.fileIndex;
    
    [self.videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDThumbImageView class]]){
            if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                [((RDThumbImageView *)obj) selectThumb:YES];
            }else{
                [((RDThumbImageView *)obj) selectThumb:NO];
            }
        }
    }];
    [_videoCoreSDK seekToTime:[_videoCoreSDK transitionTimeRangeAtIndex:sender.fileIndex].start];
    [self changeTransition];
}

/**文字板
 */
- (void)enter_TextPhotoVC:(BOOL)edit{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
        [_videoCoreSDK stop];
    }
    RDFile *file = _fileList[selectFileIndex];
    CustomTextPhotoViewController *cusTextview;
    if(edit){
        if(CGSizeEqualToSize(file.customTextPhotoFile.photoRectSize, CGSizeZero)){
            file.customTextPhotoFile.photoRectSize = exportSize;
        }
        CustomTextPhotoFile *customTextPhotoFile = file.customTextPhotoFile;
        cusTextview  = [[CustomTextPhotoViewController alloc] initWithFile:customTextPhotoFile];
    }else{
        cusTextview = [[CustomTextPhotoViewController alloc] init];
        cusTextview.videoProportion = exportSize.width/(float)exportSize.height;
    }
    cusTextview.delegate = self;
    cusTextview.touchUpType = 0;
    [self.navigationController pushViewController:cusTextview animated:NO];
}
#pragma mark-特效
- (void)enter_effects {
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    WeakSelf(self);
    RDSpecialEffectsViewController * specialEffectVC = [[RDSpecialEffectsViewController alloc] init];
    specialEffectVC.file = _fileList[selectFileIndex];
    specialEffectVC.exportSize = exportSize;
    specialEffectVC.globalFilters = globalFilters;
    
    specialEffectVC.changeSpecialEffectFinish = ^(NSInteger customFilterIndex, int customFilterId, TimeFilterType timeFilter, CMTimeRange timeRange, BOOL useToAll) {
        isNeedPrepare = NO;
        StrongSelf(self);
        [strongSelf setWhetherToModify:YES];
            if (useToAll) {
                //全部多媒体设置
                [strongSelf->_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.customFilterIndex = customFilterIndex;
                    obj.customFilterId = customFilterId;
                    obj.fileTimeFilterType = timeFilter;
                    if( (timeFilter == kTimeFilterTyp_Repeat)
                       || (timeFilter == kTimeFilterTyp_Reverse) )
                    {
                      obj.reverseVideoURL = [NSURL fileURLWithPath:[RDGenSpecialEffect ExportURL:obj]];
                    }
                    obj.fileTimeFilterTimeRange = timeRange;
                }];
            }else {
                //单个多媒体设置
                RDFile *file = strongSelf.fileList[strongSelf->selectFileIndex];
                file.customFilterIndex = customFilterIndex;
                file.customFilterId = customFilterId;
                file.fileTimeFilterType = timeFilter;
                file.fileTimeFilterTimeRange = timeRange;
                if( (timeFilter == kTimeFilterTyp_Repeat)
                   || (timeFilter == kTimeFilterTyp_Reverse) )
                {
                    file.reverseVideoURL = [NSURL fileURLWithPath:[RDGenSpecialEffect ExportURL:file]];
                }
            }
            [strongSelf performSelector:@selector(initPlayer:) withObject:nil afterDelay:0.5];
    };
    
    [self.navigationController pushViewController:specialEffectVC animated:NO];
//    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:adjustView];
//    [self setNavConfig:nav];
//    [self presentViewController:nav animated:YES completion:nil];
}
#pragma mark-进入调色
- (void)enter_adjust {
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    WeakSelf(self);
    RDAdjustViewController * adjustView = [[RDAdjustViewController alloc] init];
    
    CMTime time = CMTimeSubtract(seekTime, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
    [currentMinCoreSDK seekToTime:time];
    [adjustView seekTime:time];
    adjustView.file = _fileList[selectFileIndex];
    [adjustView setVideoCoreSDK:currentMinCoreSDK];
    adjustView.exportSize = exportSize;
    adjustView.globalFilters = globalFilters;
    isRefresh = true;
    adjustView.changeAdjustFinish = ^(NSArray * floatArray, BOOL useToAll){
        StrongSelf(self);
        isRefresh = false;
        [strongSelf setWhetherToModify:YES];
        if( !scenes && ( scenes.count ==0 ) )
        {
            scenes = [_videoCoreSDK getScenes];
        }
        if (useToAll) {
            [strongSelf->_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.brightness = [floatArray[0] floatValue];
                obj.contrast = [floatArray[1] floatValue];
                obj.saturation = [floatArray[2] floatValue];
                // 锐度
                obj.sharpness     =   [floatArray[3] floatValue];
                // 色温
                obj.whiteBalance  =   [floatArray[4] floatValue];
                //暗角
                obj.vignette      =   [floatArray[5] floatValue];
                
            }];
            
            if( scenes && ( scenes.count > 0 ) )
            {
                [strongSelf->scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        asset.brightness = [floatArray[0] floatValue];
                        asset.contrast = [floatArray[1] floatValue];
                        asset.saturation = [floatArray[2] floatValue];
                        // 锐度
                        asset.sharpness     =   [floatArray[3] floatValue];
                        // 色温
                        asset.whiteBalance  =   [floatArray[4] floatValue];
                        //暗角
                        asset.vignette      =   [floatArray[5] floatValue];
                    }];
                }];
            }
        }else {
            strongSelf->_fileList[strongSelf->selectFileIndex].brightness = [floatArray[0] floatValue];
            strongSelf->_fileList[strongSelf->selectFileIndex].contrast = [floatArray[1] floatValue];
            strongSelf->_fileList[strongSelf->selectFileIndex].saturation = [floatArray[2] floatValue];
            strongSelf->_fileList[strongSelf->selectFileIndex].sharpness = [floatArray[3] floatValue];
            strongSelf->_fileList[strongSelf->selectFileIndex].whiteBalance = [floatArray[4] floatValue];
            strongSelf->_fileList[strongSelf->selectFileIndex].vignette = [floatArray[5] floatValue];
            
            NSString *identifier = [NSString stringWithFormat:@"video%ld", (long)self->selectFileIndex];
            __block NSString *prevIdentifier = nil;
            if( scenes && ( scenes.count > 0 ) )
            {
                [strongSelf->scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        if ([asset.identifier isEqualToString:identifier]) {
                            prevIdentifier = identifier;
                            asset.brightness = [floatArray[0] floatValue];
                            asset.contrast = [floatArray[1] floatValue];
                            asset.saturation = [floatArray[2] floatValue];
                            // 锐度
                            asset.sharpness     =   [floatArray[3] floatValue];
                            // 色温
                            asset.whiteBalance  =   [floatArray[4] floatValue];
                            //暗角
                            asset.vignette      =   [floatArray[5] floatValue];
                            *stop2 = YES;
                        }else if (prevIdentifier.length > 0) {
                            *stop1 = YES;
                        }
                    }];
                }];
            }
        }
        CMTime time = currentMinCoreSDK.currentTime;
        time = CMTimeAdd(time, [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        if( CMTimeGetSeconds(time) != CMTimeGetSeconds(_videoCoreSDK.currentTime) )
        {
            [_videoCoreSDK seekToTime:time];
        }
        else
        {
            [_videoCoreSDK refreshCurrentFrame];
        }
    };
    
    [self.navigationController pushViewController:adjustView animated:NO];
//    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:adjustView];
//    [self setNavConfig:nav];
//    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark- 转场
-(void)changeTransition
{
    isTranstion = true;
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    
    transitionRect  = _bottomView.frame;
    
    _transitionDuration = _fileList[selectFileIndex].transitionDuration;
    _maxFileTimeDuration = [self maxTransitionDuration:selectFileIndex];
    _bottomView.hidden = NO;
    isModifyTranstion = false;
    operationView.hidden = YES;
    _titleView.hidden = YES;
    _bottomView.backgroundColor = TOOLBAR_COLOR;
//    _bottomView.frame = CGRectMake(0, kHEIGHT - ( 40 + 35 + 80 + kToolbarHeight ) , _bottomView.frame.size.width, 40 + 35 + 80);
    
    transitionPlayButtonRect = _playButton.frame;
    [self.view addSubview:_playButton];
    _playButton.frame = CGRectMake(5,_playButton.frame.origin.y - 28, _playButton.frame.size.width, _playButton.frame.size.height);

    transitionPlayViewRect = _playerView.frame;
//    _playerView.frame =  CGRectMake(_playerView.frame.origin.x, kPlayerViewOriginX, _playerView.frame.size.width, kHEIGHT - ( 40 + 35 + 80 + kToolbarHeight ) - kPlayerViewOriginX);
    
    _videoCoreSDK.frame = _playerView.bounds;
    [self.view insertSubview:self.titleView aboveSubview:self.playerView];
    
    _videoProgressSlider.hidden = YES;
    _durationLabel.hidden  = YES;
    _currentLabel.hidden = YES;
    self.transitionView.hidden = NO;
    self.transitionToolbarView.hidden = NO;

    
    _defaultTranstionBtn.selected = NO;
    _useToAllTranstionBtn.selected = NO;
    if( _fileList[selectFileIndex].transitionDuration != 0.0 )
    {
        _transtionDurationLabel.text = [NSString stringWithFormat:RDLocalizedString(@"%.2f", nil),_fileList[selectFileIndex].transitionDuration];
        lastSelectIndexItemDuration = _fileList[selectFileIndex].transitionDuration;
        _transtionDurationSlider.value = _fileList[selectFileIndex].transitionDuration;
    }else
    {
        _transtionDurationLabel.text = [NSString stringWithFormat:RDLocalizedString(@"%.2f", nil),0.0];
        lastSelectIndexItemDuration = 0.0;
        _transtionDurationSlider.value = 0.0;
    }
    __block NSInteger selectedTransitionTypeIndex = 0;
    NSString *transitionName = _fileList[selectFileIndex].transitionName;
    if (!transitionName || [transitionName isEqualToString:RDLocalizedString(@"无", nil)]) {
        transitionNoneBtn.selected = YES;
        RDAddItemButton * addItemBtn = (RDAddItemButton*)transitionNoneBtn;
        addItemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
        [addItemBtn  textColor:[UIColor whiteColor]];
        _transtionDurationSlider.enabled = NO;
        [transitionTypeScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == 1) {
                obj.selected = YES;
                obj.titleLabel.font = [UIFont boldSystemFontOfSize:14];
                
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
        RDAddItemButton * addItemBtn = (RDAddItemButton*)transitionNoneBtn;
        addItemBtn.thumbnailIV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        [addItemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            selectedTransitionTypeName = obj[@"typeName"];
            selectedTransitionTypeIndex = idx;
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
               if ([[obj1 stringByDeletingPathExtension] isEqualToString:transitionName]) {
                   UIButton *itemBtn = [transitionTypeScrollView viewWithTag:idx + 1];
                   itemBtn.selected = YES;
                   
                   UICollectionView *collectionView = [transitionScrollView viewWithTag:idx + 1];
                   CGFloat offsetX = idx1 *( _bottomView.frame.size.height/2.0 * 0.7 + 16);
                   if (offsetX + collectionView.frame.size.width >= collectionView.contentSize.width) {
                       [collectionView setContentOffset:CGPointMake(collectionView.contentSize.width - collectionView.frame.size.width, 0)];
                   }else {
                       [collectionView setContentOffset:CGPointMake(offsetX, 0)];
                   }
                   RDTranstionCollectionViewCell *selectCell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                   selectCell.customImageView.layer.borderColor = Main_Color.CGColor;
                   [selectCell textColor:[UIColor whiteColor]];
                   if( currentCell )
                   {
                       [currentCell textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
                       currentCell.customImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.0].CGColor;
                       currentCell = nil;
                   }
                   currentCell = selectCell;
                   
                   if( transitionNoneBtn.selected )
                   {
                       [transitionNoneBtn textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
                       transitionNoneBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
                   }
                   
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
                   [deselectCell textColor:[UIColor colorWithWhite:1 alpha:0.5]];
                   deselectCell.customImageView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.0].CGColor;
                   *stop1 = YES;
                   *stop = YES;
               }
           }];
        }];
    }
    selectedTransitionName = transitionName;
    transitionScrollView.contentOffset = CGPointMake(selectedTransitionTypeIndex * transitionScrollView.bounds.size.width, 0);
    
    [RDHelpClass animateView:_bottomView atUP:NO];
}

- (void)setTransitionWithTypeName:(NSString *)typeName transitionName:(NSString *)transitionName
                          atIndex:(NSInteger) idx  isPlay:(bool) isPlay
{
    if (transitionNoneBtn.selected) {
        _transtionDurationLabel.text = [NSString stringWithFormat:@"%.2f",0.0];
        _transtionDurationLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        _transtionDurationSlider.value = 0;
        _transtionDurationSlider.enabled = NO;
    }else {
        _transtionDurationSlider.maximumValue = MIN(_maxFileTimeDuration, 2.0);
        _transtionDurationSlider.minimumValue = 0.0;
        _transtionDurationSlider.value = (lastSelectIndexItemDuration == 0 ? _transtionDurationSlider.maximumValue/2.0 : lastSelectIndexItemDuration);
        _transtionDurationSlider.enabled = YES;
        _transtionDurationLabel.text = [NSString stringWithFormat:@"%.2f",_transtionDurationSlider.value];
        _transtionDurationLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    }
    if( isPlay )
    {
        [transitionList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([[obj1 stringByDeletingPathExtension] isEqualToString:selectedTransitionName]) {
                    UICollectionView *prevCollectionView = [transitionScrollView viewWithTag:idx + 1];
                    RDTranstionCollectionViewCell *deselectCell = (RDTranstionCollectionViewCell *)[prevCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                    [deselectCell textColor:[UIColor colorWithWhite:1 alpha:0.5]];
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
    }
    
    NSString *maskpath;
    double transitionDuration = 0;
    if(!transitionNoneBtn.selected){
        maskpath = [RDHelpClass getTransitionPath:typeName itemName:transitionName];
        transitionDuration = _transtionDurationSlider.value;
    }
    NSURL *maskUrl = maskpath.length == 0 ? nil : [NSURL fileURLWithPath:maskpath];
    
    RDFile *selectedFile = self.fileList[idx];
    BOOL isNeedBuild = !(selectedFile.transitionDuration == transitionDuration);
    selectedFile.transitionMask = maskUrl;
    selectedFile.transitionTypeName = typeName;
    selectedFile.transitionName = transitionName;
    if (transitionNoneBtn.selected) {
        selectedFile.transitionDuration = 0;
    }else {
        float maxTransitionDuration;
        if (idx == _fileList.count - 1) {
            maxTransitionDuration = 0;
        }else {
            maxTransitionDuration = [RDHelpClass maxTransitionDuration:selectedFile nextFile:_fileList[idx + 1]];
        }
        selectedFile.transitionDuration = MIN(maxTransitionDuration, transitionDuration);
    }
    
    if( isPlay )
    {
        transitionTimeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex+1];
        transitionTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(transitionTimeRange.start) - selectedFile.transitionDuration - 0.25 , TIMESCALE), CMTimeMakeWithSeconds(selectedFile.transitionDuration + 0.5, TIMESCALE));
    }
    
    if (isNeedBuild) {
        WeakSelf(self);
        if( isPlay )
        {
            [self initPlayer:^{
            #if isUseCustomLayer
                        [weakSelf refreshCustomTextTimeRange];
            #endif
                    }];
        }
        
    }else {
        RDScene *scene = scenes[idx];
        [RDHelpClass setTransition:scene.transition file:selectedFile];
        if( isPlay )
        {
            if (CMTimeCompare(_videoCoreSDK.currentTime, transitionTimeRange.start) != 0) {
                [_videoCoreSDK seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                    [self playVideo:YES];
                }];
            }else {
                [self playVideo:YES];
            }
        }
    }
    if( isPlay )
    {
        selectedTransitionTypeName = typeName;
        selectedTransitionName = transitionName;
    }
}

/**计算转场时间的最大值
 */
- (double)maxTransitionDuration:(NSInteger)index{
    if(index == _fileList.count - 1){
        return 0;
    }
    RDFile *beforeFile = _fileList[index];
    RDFile *behindFile = _fileList[index+1];
    double beforeDuration = 0;
    double behindDuration = 0;
    AVURLAsset *asset;
    if(beforeFile.fileType == kFILEVIDEO){
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(beforeFile.isReverse){
            asset = [AVURLAsset assetWithURL:beforeFile.reverseVideoURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, beforeFile.reverseVideoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, beforeFile.reverseDurationTime);
            }else{
                timeRange = beforeFile.reverseVideoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, beforeFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, beforeFile.reverseVideoTrimTimeRange.duration) == 1){
                timeRange = beforeFile.reverseVideoTrimTimeRange;
            }
        }
        else{
            asset = [AVURLAsset assetWithURL:beforeFile.contentURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, beforeFile.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, beforeFile.videoDurationTime);
            }else{
                timeRange = beforeFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, beforeFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, beforeFile.videoTrimTimeRange.duration) == 1){
                timeRange = beforeFile.videoTrimTimeRange;
            }
        }
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            if (CMTimeCompare(CMTimeAdd(timeRange.start, timeRange.duration), clipVideoTrack.timeRange.duration) == 1) {
                timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(clipVideoTrack.timeRange.duration, timeRange.start));
            }
        }
        beforeDuration = CMTimeGetSeconds(timeRange.duration)/beforeFile.speed;
    }else{
        beforeDuration = CMTimeGetSeconds(beforeFile.imageDurationTime);
        if (beforeFile.isGif && CMTimeCompare(beforeFile.imageTimeRange.duration, kCMTimeZero) == 1) {
            beforeDuration = CMTimeGetSeconds(beforeFile.imageTimeRange.duration);
        }
    }
    
    if(behindFile.fileType == kFILEVIDEO){
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(behindFile.isReverse){
            asset = [AVURLAsset assetWithURL:behindFile.reverseVideoURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, behindFile.reverseVideoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, behindFile.reverseDurationTime);
            }else{
                timeRange = behindFile.reverseVideoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, behindFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, behindFile.reverseVideoTrimTimeRange.duration) == 1){
                timeRange = behindFile.reverseVideoTrimTimeRange;
            }
        }
        else{
            asset = [AVURLAsset assetWithURL:behindFile.contentURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, behindFile.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, behindFile.videoDurationTime);
            }else{
                timeRange = behindFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, behindFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, behindFile.videoTrimTimeRange.duration) == 1){
                timeRange = behindFile.videoTrimTimeRange;
            }
        }
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            if (CMTimeCompare(CMTimeAdd(timeRange.start, timeRange.duration), clipVideoTrack.timeRange.duration) == 1) {
                timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(clipVideoTrack.timeRange.duration, timeRange.start));
            }
        }
        behindDuration = CMTimeGetSeconds(timeRange.duration)/behindFile.speed;
    }else{
        behindDuration = CMTimeGetSeconds(behindFile.imageDurationTime);
        if (behindFile.isGif && CMTimeCompare(behindFile.imageTimeRange.duration, kCMTimeZero) == 1) {
            behindDuration = CMTimeGetSeconds(behindFile.imageTimeRange.duration);
        }
    }
    
    return MIN(MIN(beforeDuration/2.0, behindDuration/2.0), 2.0);
    
}


#pragma mark-滑动进度条

- (void)beginScrub{
    if([_videoCoreSDK isPlaying]){
        [self  playVideo:NO];
    }
}

- (void)scrub{
    CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

- (void)endScrub{
    CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}

#pragma mark - 动画 界面
- (UIView *)animationView {
    if (!_animationView) {
        
        _animationLordView = [[UIView alloc] initWithFrame:CGRectMake(0, _bottomView.frame.origin.y, kWIDTH, _bottomView.frame.size.height+kToolbarHeight)];
        _animationLordView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_animationLordView];
        
        _animationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _bottomView.frame.size.height)];
        
        float height = _bottomView.frame.size.height;
        
        _animationView.backgroundColor = TOOLBAR_COLOR;
        [_animationLordView addSubview:_animationView];
        
        animationDurationView = [[UIView alloc] initWithFrame:CGRectMake(0, height*(0.468+0.266), kWIDTH, height*0.266)];
        [_animationView addSubview:animationDurationView];
        
        float defaultWidth =  [RDHelpClass widthForString:RDLocalizedString(@"随机", nil) andHeight:14 fontSize:14];
        
//        UILabel *animateLbl = [[UILabel alloc] initWithFrame:CGRectMake(defaultWidth+50+10, (height*0.266 - 30)/2.0, 60, 30)];
//        animateLbl.text = RDLocalizedString(@"动画时长", nil);
//        animateLbl.textAlignment = NSTextAlignmentLeft;
//        animateLbl.font = [UIFont systemFontOfSize:14];
//        animateLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
//
//        [animationDurationView addSubview:animateLbl];
        
        animationDurationLbl = [[UILabel alloc] initWithFrame:CGRectMake(defaultWidth+50+10, (height*0.266 - 30)/2.0, 60, 30)];
        animationDurationLbl.textColor = TEXT_COLOR;
        animationDurationLbl.font = [UIFont systemFontOfSize:12];
        animationDurationLbl.textAlignment = NSTextAlignmentCenter;
//        animationDurationLbl.hidden = YES;
        [animationDurationView addSubview:animationDurationLbl];
        
        
        
        animationDurationSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(animationDurationLbl.frame.origin.x + animationDurationLbl.frame.size.width + 10, (height*0.266 - 30)/2.0, kWIDTH - (animationDurationLbl.frame.origin.x + animationDurationLbl.frame.size.width + 10) - 15, 30)];
        animationDurationSlider.maximumValue = 5.0;
        animationDurationSlider.minimumValue = 0.1;
        animationDurationSlider.value = 1.0;
        
        animationDurationLbl.text = [NSString stringWithFormat:@"%.1f秒",animationDurationSlider.value];
        
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [animationDurationSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [animationDurationSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [animationDurationSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        [animationDurationSlider addTarget:self action:@selector(animationBeginScrub:) forControlEvents:UIControlEventTouchDown];
        [animationDurationSlider addTarget:self action:@selector(animationChangeScrub:) forControlEvents:UIControlEventValueChanged];
        [animationDurationSlider addTarget:self action:@selector(animationEndScrub:) forControlEvents:UIControlEventTouchUpInside];
        [animationDurationSlider addTarget:self action:@selector(animationEndScrub:) forControlEvents:UIControlEventTouchCancel];
        [animationDurationView addSubview:animationDurationSlider];
        
        
        defaultAnimationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        defaultAnimationBtn.frame = CGRectMake( 10 , (animationDurationView.frame.size.height - 35)/2.0, 50 + defaultWidth, 35);
        defaultAnimationBtn.layer.cornerRadius = 4;
        defaultAnimationBtn.layer.masksToBounds = YES;
        defaultAnimationBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [defaultAnimationBtn setTitle:RDLocalizedString(@"随机", nil) forState:UIControlStateNormal];
        [defaultAnimationBtn setTitle:RDLocalizedString(@"随机", nil) forState:UIControlStateHighlighted];
        defaultAnimationBtn.titleLabel.textAlignment = NSTextAlignmentRight;
        [defaultAnimationBtn setImage:[RDHelpClass imageWithContentOfFile:@"transitions/剪辑-转场_随机_默认_"] forState:UIControlStateNormal];
        [defaultAnimationBtn setImage:[RDHelpClass imageWithContentOfFile:@"transitions/剪辑-转场_随机_选中_"] forState:UIControlStateSelected];
        [defaultAnimationBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [defaultAnimationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [defaultAnimationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [defaultAnimationBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [defaultAnimationBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 0)];
        [defaultAnimationBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        defaultAnimationBtn.backgroundColor = [UIColor clearColor];
        [defaultAnimationBtn addTarget:self action:@selector( defaultAnimationBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        defaultAnimationBtn.selected = NO;
        [animationDurationView addSubview:defaultAnimationBtn];
        
        
        animationScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, height*0.266, kWIDTH - 5, height*0.468)];
        animationScrollView.showsVerticalScrollIndicator = NO;
        animationScrollView.showsVerticalScrollIndicator = FALSE;
        animationScrollView.showsHorizontalScrollIndicator = FALSE;
        [_animationView addSubview:animationScrollView];
    
        float useToAllTranstionWidth =  [RDHelpClass widthForString:RDLocalizedString(@"应用到所有", nil) andHeight:14 fontSize:14] + 50;
        _useToAllAnimationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _useToAllAnimationBtn.frame = CGRectMake( 0,(height*0.266 - 35)/2.0, useToAllTranstionWidth, 35);
        _useToAllAnimationBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_useToAllAnimationBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        [_useToAllAnimationBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
        _useToAllAnimationBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_useToAllAnimationBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [_useToAllAnimationBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [_useToAllAnimationBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_useToAllAnimationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_useToAllAnimationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_useToAllAnimationBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [_useToAllAnimationBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        [_useToAllAnimationBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        _useToAllAnimationBtn.backgroundColor = [UIColor clearColor];
        [_useToAllAnimationBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
        _useToAllAnimationBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_useToAllAnimationBtn addTarget:self action:@selector(useToAllTranstionBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        _useToAllAnimationBtn.selected = NO;
        [_animationView addSubview:_useToAllAnimationBtn];
        
        if( selectedAnimationIndex == 1 )
            animationDurationSlider.enabled = FALSE;
        
        
        RDAddItemButton *itemBtn = [RDAddItemButton initFXframe:CGRectMake(15, 0, height*0.468*0.75, height*0.468) atpercentage:0.75];
        
        itemBtn.label.text = RDLocalizedString(@"无动画", nil);
        [itemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        float ItemBtnWidth = [RDHelpClass widthForString:itemBtn.label.text andHeight:12 fontSize:12];
        if( ItemBtnWidth > itemBtn.label.frame.size.width )
            [itemBtn startScrollTitle];
//        itemBtn.thumbnailIV.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无-选中@3x" Type:@"png"]];
        itemBtn.thumbnailIV.backgroundColor = UIColorFromRGB(0x27262c);
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, itemBtn.thumbnailIV.frame.size.width, itemBtn.thumbnailIV.frame.size.height)];
        label.text = RDLocalizedString(@"无", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:15.0];
        [itemBtn.thumbnailIV addSubview:label];
        
        [itemBtn addTarget:self action:@selector(animationTypeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//        itemBtn.thumbnailIV.backgroundColor = [UIColor blackColor];
        itemBtn.tag = 1;
        if( selectedAnimationIndex == 1 )
        {
            itemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
            [itemBtn  textColor:[UIColor whiteColor]];
        }
        
        [animationScrollView addSubview:itemBtn];
        
        animationArray = [NSMutableArray array];
        NSArray *animates = [RDResourceBundle URLsForResourcesWithExtension:@"json" subdirectory:@"AssetAnimation/json"];
        
        NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        __block NSString * imagePath = nil;
        [animates enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *name = [NSString stringWithUTF8String:[obj.path UTF8String]];
            name = [name.lastPathComponent stringByDeletingPathExtension];
            [animationArray addObject:name];
            
            RDAddItemButton *itemBtn = [RDAddItemButton initFXframe:CGRectMake((15 + height*0.468*0.75)*(idx + 1) + 15, 0, height*0.468*0.8, height*0.468) atpercentage:0.75];
            
            itemBtn.label.text = RDLocalizedString(name, nil);
            [itemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
            float ItemBtnWidth = [RDHelpClass widthForString:itemBtn.label.text andHeight:12 fontSize:12];
            
            if( ItemBtnWidth > itemBtn.label.frame.size.width )
                [itemBtn startScrollTitle];
            
            [itemBtn.thumbnailIV removeFromSuperview];
            itemBtn.thumbnailIV = nil;
            
            itemBtn.thumbnailIV = [RDYYAnimatedImageView new];
            itemBtn.thumbnailIV.frame = CGRectMake((itemBtn.frame.size.width  - itemBtn.frame.size.height*itemBtn.propor)/2.0, 0,
                                                   itemBtn.frame.size.height*itemBtn.propor, itemBtn.frame.size.height*itemBtn.propor);
            
            imagePath = nil;
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"AssetAnimation/icon/%@_@3x",name] Type:@"apng"];
            NSLog(@"APNG:%d",idx);
            itemBtn.thumbnailIV.yy_imageURL = [NSURL fileURLWithPath:imagePath];
            itemBtn.thumbnailIV.layer.cornerRadius = 5;
            itemBtn.thumbnailIV.layer.masksToBounds = YES;
            itemBtn.thumbnailIV.layer.borderWidth = 1.0;
            itemBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
            itemBtn.thumbnailIV.tag = 1000;
            [itemBtn addSubview: itemBtn.thumbnailIV];
            
            
            [itemBtn addTarget:self action:@selector(animationTypeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            itemBtn.tag = idx + 2;
            [animationScrollView addSubview:itemBtn];
        }];
        animationScrollView.contentSize = CGSizeMake((animationArray.count + 1)*(15 + height*0.468*0.8), 0);
    }
    self.animationTitleView.hidden = NO;
    animationDurationView.hidden = NO;
    _animationLordView.hidden = NO;
    return _animationView;
}

-(UIView *)animationTitleView
{
    if( !_animationTitleView )
    {
        _animationTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, _animationView.frame.size.height+_animationView.frame.origin.y, kWIDTH, kToolbarHeight)];
        _animationTitleView.backgroundColor = TOOLBAR_COLOR;
        
        UILabel * animationLabel = [UILabel new];
        animationLabel.frame = CGRectMake(44, 0, kWIDTH - 88, 44);
        animationLabel.textAlignment = NSTextAlignmentCenter;
        animationLabel.backgroundColor = [UIColor clearColor];
        animationLabel.font = [UIFont boldSystemFontOfSize:17];
        animationLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        animationLabel.text = RDLocalizedString(@"动画", nil);
        
        [_animationTitleView addSubview:animationLabel];
        
        _animationCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [_animationCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_animationCloseBtn addTarget:self action:@selector(animationClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_animationTitleView addSubview:_animationCloseBtn];
        
        _animationConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [_animationConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_animationConfirmBtn addTarget:self action:@selector(animationConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_animationTitleView addSubview:_animationConfirmBtn];
        
        [_animationLordView addSubview:_animationTitleView];
    }
    return _animationTitleView;
}

-(void)animationClose_Btn
{
    _titleView.hidden = false;
    _playButton.hidden = false;
    _videoProgressSlider.hidden = false;
    _durationLabel.hidden  = false;
    _currentLabel.hidden = false;
    operationView.hidden = false;
    isToolBarView = false;
    _bottomView.hidden = TRUE;
    _animationView.hidden = TRUE;
    _animationTitleView.hidden = TRUE;
    _animationLordView.hidden = true;
    
    _useToAllAnimationBtn.selected = NO;
    defaultAnimationBtn.selected = NO;
    
    [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.animate = nil;
        
    }];
    
    RDAddItemButton *itemBtn = [animationScrollView viewWithTag:selectedAnimationIndex];
    itemBtn.selected = NO;
    itemBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
    [itemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    
    selectedAnimationIndex = 1;
    isAnimation  = false;
    
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    
    [_videoCoreSDK seekToTime:animationStartTime];
}
-(void)animationConfirm_Btn
{
    
    _isModigy = YES;
    _titleView.hidden = false;
    _playButton.hidden = false;
    _videoProgressSlider.hidden = false;
    _durationLabel.hidden  = false;
    _currentLabel.hidden = false;
    operationView.hidden = false;
    isToolBarView = false;
    _bottomView.hidden = TRUE;
    _animationView.hidden = TRUE;
    _animationTitleView.hidden = TRUE;
    _animationLordView.hidden = true;
    
    RDAddItemButton *itemBtn = [animationScrollView viewWithTag:selectedAnimationIndex];
    itemBtn.selected = NO;
    itemBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
    [itemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    
    if( selectedAnimationIndex != 1 )
    {
        [animationArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (selectedAnimationIndex ==  (idx + 2) ) {
                _fileList[selectFileIndex].animationName = obj;
                *stop = YES;
            }
        }];
        
        _fileList[selectFileIndex].animationDuration = CMTimeGetSeconds(animationTime.duration);
    }
    else
    {
        _fileList[selectFileIndex].animationDuration = 0;
        _fileList[selectFileIndex].animationName = nil;
    }
    
    if( _useToAllAnimationBtn.selected )  //应用于所有
    {
        
        __block bool isDefault = defaultAnimationBtn.selected;
        __block float value = animationDurationSlider.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            });
            
            [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if( selectFileIndex != idx )
                {
                    float duration = 0.0;
                    if (obj.fileType == kFILEVIDEO) {
                        if(obj.isReverse){
                            if (CMTimeRangeEqual(kCMTimeRangeZero, obj.reverseVideoTimeRange)) {
                                duration = CMTimeGetSeconds(obj.reverseDurationTime);
                            }else{
                                duration = CMTimeGetSeconds(obj.reverseVideoTimeRange.duration);
                            }
                            if(!CMTimeRangeEqual(kCMTimeRangeZero, obj.reverseVideoTrimTimeRange) && duration > CMTimeGetSeconds(obj.reverseVideoTrimTimeRange.duration)){
                                duration = CMTimeGetSeconds(obj.reverseVideoTrimTimeRange.duration);
                            }
                        }else{
                            if (CMTimeRangeEqual(kCMTimeRangeZero, obj.videoTimeRange)) {
                                duration = CMTimeGetSeconds(obj.videoDurationTime);
                                if(duration == 0){
                                    duration = CMTimeGetSeconds([AVURLAsset assetWithURL:obj.contentURL].duration);
                                }
                            }else{
                                duration = CMTimeGetSeconds(obj.videoTimeRange.duration);
                            }
                            if(!CMTimeRangeEqual(kCMTimeRangeZero, obj.videoTrimTimeRange) && duration > CMTimeGetSeconds(obj.videoTrimTimeRange.duration)){
                                duration = CMTimeGetSeconds(obj.videoTrimTimeRange.duration);
                            }
                        }
                    }else {
                        if (CMTimeCompare(obj.imageTimeRange.duration, kCMTimeZero) == 1) {
                            duration = CMTimeGetSeconds(obj.imageTimeRange.duration);
                        }else {
                            duration = CMTimeGetSeconds(obj.imageDurationTime);
                        }
                    }
                    obj.animationDuration = (duration>value)?value:duration;
                    if( isDefault )  //随机动画
                        obj.animationName = animationArray[arc4random()%(animationArray.count)];
                    else //不随机
                        obj.animationName = _fileList[selectFileIndex].animationName;
                }
            }];
            
            [scenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                int index = idx;
                
                if( selectFileIndex != idx )
                {
                    RDScene * scene = obj;
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (_fileList[index].animationName == nil) {
                            obj.animate = nil;
                        }else {
                            [RDHelpClass setAssetAnimationArray:obj name:_fileList[index].animationName duration:_fileList[idx].animationDuration center:CGPointMake(_fileList[index].rectInScene.origin.x + _fileList[index].rectInScene.size.width/2.0, _fileList[index].rectInScene.origin.y + _fileList[index].rectInScene.size.height/2.0) scale:_fileList[index].rectInScale];
                        }
                    }];
                }
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_videoCoreSDK seekToTime:animationStartTime];
                [RDSVProgressHUD dismiss];
            });
        });
    }
    
    selectedAnimationIndex = 1;
    isAnimation = false;
    _useToAllAnimationBtn.selected = NO;
    defaultAnimationBtn.selected = NO;
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    [_videoCoreSDK seekToTime:animationStartTime];
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        if(sender == _videoCoreSDK){
            [RDSVProgressHUD dismiss];
            if( isTranstion)
            {
                [_videoCoreSDK seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                    [self playVideo:YES];
                }];
            }else if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                [_videoCoreSDK seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:nil];
                seekTime = kCMTimeZero;
                _isAdd = false;
            }else if (selectFileIndex != 0) {
                CMTimeRange timerange = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex];
                [_videoCoreSDK seekToTime:timerange.start];
            }
        }
    }
}

-(void)point_ThumbSlider:(int) currentIndex atIndex:(int) i
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //                        currentMinCoreSDK = [self getCore:_fileList[selectFileIndex] atIsExpSize:NO];
        
        __block bool isCurrent = true;  //当前控件是否已经置空
        __block bool isThumbId = true;  //即将 选择的控件
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self getToolBarItems];
            [_videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([obj isKindOfClass:[RDThumbImageView class]]){
                    if(((RDThumbImageView *)obj).thumbId == currentIndex){
                        
                        [((RDThumbImageView *)obj) selectThumb:NO];
                        
                        isCurrent = false;
                        
                        if( !isThumbId )
                            *stop = YES;
                    }
                    else if(((RDThumbImageView *)obj).thumbId == i)
                    {
                        [((RDThumbImageView *)obj) selectThumb:YES];
                        if( isFirst )
                        {
                            
                            if( _videoThumbSlider.contentSize.width >= _videoThumbSlider.frame.size.width )
                            {
                                
                                float x = obj.frame.origin.x;
                                
                                if( (_videoThumbSlider.contentSize.width-_videoThumbSlider.frame.size.width) < x )
                                {
                                    x = _videoThumbSlider.contentSize.width-_videoThumbSlider.frame.size.width;
                                }
                                
                                _videoThumbSlider.contentOffset = CGPointMake(x, _videoThumbSlider.contentOffset.y);
                            }
                        }
                        isThumbId = false;
                        
                        if( !isCurrent )
                            *stop = YES;
                    }
                }
            }];
            
            isFirst = false;
        });
    });
}

-(void)setThumbSlider_CurrentTime:(CMTime) currentTime
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        float fStart = CMTimeGetSeconds([_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start);
        float fEnd = CMTimeGetSeconds([_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].duration) + fStart;
        if( (CMTimeGetSeconds(currentTime) < fStart) || ( CMTimeGetSeconds(currentTime) >= fEnd) )
        {
            for (int i = 0; i < _fileList.count; i++) {
                
                fStart = CMTimeGetSeconds([_videoCoreSDK passThroughTimeRangeAtIndex:i].start);
                
                fEnd = CMTimeGetSeconds([_videoCoreSDK passThroughTimeRangeAtIndex:i].duration) + fStart;
                
                if( (CMTimeGetSeconds(currentTime) >= fStart) && ( CMTimeGetSeconds(currentTime) < fEnd ) )
                {
                    if( i != selectFileIndex )
                    {
                        int currentIndex = selectFileIndex;
                        selectFileIndex = i;
                        isNewCoreSDK = true;
                        NSLog(@"当前素材：%d",i);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self point_ThumbSlider:currentIndex atIndex:i];
                            
                        });
                    }
                    break;
                }
            }
        }
        
    });
}

/**当前播放时间
 */
- (void)progressCurrentTime:(CMTime)currentTime{
    [_videoProgressSlider setValue:(CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration)];
    self.durationLabel.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration];
    self.currentLabel.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
    //转场
    if( isTranstion )
    {
        float time = CMTimeGetSeconds(transitionTimeRange.duration) + CMTimeGetSeconds(transitionTimeRange.start);
        
        if( time <= CMTimeGetSeconds(currentTime) )
        {
            [self playVideo:NO];
            [_videoCoreSDK seekToTime:transitionTimeRange.start];
        }
    }
    else if( isAnimation )
    {
        float time = CMTimeGetSeconds(animationTime.duration) + CMTimeGetSeconds(animationTime.start);
        
        if( time <= CMTimeGetSeconds(currentTime) )
        {
            [self playVideo:NO];
            [_videoCoreSDK seekToTime:animationTime.start];
        }
    }
    else if (isPlaying || _videoProgressSlider.isTracking){
        [self setThumbSlider_CurrentTime:currentTime];
    }
}
#if isUseCustomLayer
- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    [RDHelpClass refreshCustomTextLayerWithCurrentTime:currentTime customDrawLayer:customDrawLayer fileLsit:_fileList];
}
#endif
/**播放结束
 */
- (void)playToEnd{
    [self playVideo:NO];
    [_videoCoreSDK seekToTime:kCMTimeZero];
    [_videoProgressSlider setValue:0];
}

/**点击播放器
 */
- (void)tapPlayerView{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

#pragma mark- ThumbImageViewDelegate
- (void)thumbImageViewWasTapped:(RDThumbImageView *)tiv touchUpTiv:(BOOL)isTouchUpTiv{
    NSLog(@"%s",__func__);
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    [_videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDThumbImageView class]]){
            if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                [((RDThumbImageView *)obj) selectThumb:NO];
                //*stop = YES;
            }
        }
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
            if([obj isKindOfClass:[RDConnectBtn class]]){
                [((RDConnectBtn *)obj) setSelected:NO];
            }
        }
    }];
    selectFileIndex = tiv.thumbId;
    [self getToolBarItems];
    CMTime time = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex].start;
    [_videoCoreSDK seekToTime:time];
    [tiv selectThumb:YES];
    currentMinCoreSDK = [self getCore:_fileList[selectFileIndex] atIsExpSize:NO];
}

- (void)thumbImageViewWaslongLongTap:(RDThumbImageView *)tiv{
    [self.videoThumbSliderback bringSubviewToFront:tiv];
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
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
    
    _isModigy = TRUE;
    
    float videoThumbSlider_Height = 95;
    float videoThumbSlider_Wdith = videoThumbSlider_Height + 20;
    
    CGPoint touchLocation = tiv.center;
    CGFloat ofset_x = self.videoThumbSlider.contentOffset.x;
    self.videoThumbSliderback.frame = CGRectMake(self.videoThumbSliderback.frame.origin.x, self.videoThumbSliderback.frame.origin.y, _fileList.count * videoThumbSlider_Wdith + 20 + videoThumbSlider_Height + 10, self.videoThumbSliderback.frame.size.height);
    [self.videoThumbSlider setContentSize:CGSizeMake(self.videoThumbSliderback.frame.size.width + 10, 20)];
#if 1
    NSMutableArray *arra = [self.videoThumbSliderback.subviews mutableCopy];
    [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
#endif
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
                ((RDThumbImageView *)prompView).frame = CGRectMake(index * videoThumbSlider_Wdith + 10, tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
                ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
                [((RDThumbImageView *)prompView) selectThumb:NO];
                if((RDThumbImageView *)prompView == tiv){
                     [((RDThumbImageView *)prompView) selectThumb:YES];
                    [self.videoThumbSlider setContentOffset:CGPointMake( tiv.center.x - (touchLocation.x - ofset_x), 0)];
                }
                
            } completion:^(BOOL finished) {
                
            }];
            
            
            index ++;
        }
    }
}

- (void)thumbImageViewWaslongLongTapEnd:(RDThumbImageView *)tiv{
//    TICK;
    _isModigy = TRUE;
    
    tiv.canMovePostion = NO;
    if(_fileList.count <=1){
        return;
    }
    self.videoThumbSlider.scrollEnabled = YES;
    __block float videoThumbSlider_Height = 95;
    __block float videoThumbSlider_Wdith = videoThumbSlider_Height + 20;
    
    __block CGPoint touchLocation = tiv.center;
    
    __block CGFloat ofSet_x = self.videoThumbSlider.contentOffset.x;
    
    __block float fwidth  = _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20  - (videoThumbSlider_Height + 10)*2.0   + (_videoThumbSlider.frame.size.height*2.0/3.0);
    if( fwidth <= kWIDTH )
        fwidth = kWIDTH + 10;
    _videoThumbSliderback.frame = CGRectMake(0, 0, _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20 , _videoThumbSlider.frame.size.height);
    [self.videoThumbSlider setContentSize:CGSizeMake(fwidth, 0)];
//    TOCK;
    [_fileList removeAllObjects];
    NSMutableArray *arra = [self.videoThumbSliderback.subviews mutableCopy];
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
//    TOCK;
    selectFileIndex = tiv.thumbId;
//    TOCK;
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block NSInteger index = 0;
        for (int i = 0;i<arra.count;i++) {
            RDConnectBtn *prompView  = arra[i];
            if([prompView isKindOfClass:[RDConnectBtn class]]){
                dispatch_sync(dispatch_get_main_queue(), ^{
                    prompView.hidden = YES;
                });
                continue;
            }
            if([prompView isKindOfClass:[RDThumbImageView class]]){
                dispatch_sync(dispatch_get_main_queue(), ^{
                    CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
                    ((RDThumbImageView *)prompView).frame = CGRectMake(index * videoThumbSlider_Wdith + 10 , tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
                    ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
                    ((RDThumbImageView *)prompView).thumbId = index;
                });
                if((RDThumbImageView *)prompView == tiv){
                    selectFileIndex = index;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.videoThumbSlider setContentOffset:CGPointMake( touchLocation.x + videoThumbSlider_Wdith < self.videoThumbSlider.frame.size.width ? 0 : tiv.center.x - (touchLocation.x - ofSet_x), 0)];
                    });
                    
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
//        TOCK;
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.transitionDuration = MIN([self maxTransitionDuration:idx], obj.transitionDuration);
        }];
        
//        TOCK;
        dispatch_sync(dispatch_get_main_queue(), ^{
            for (RDConnectBtn *prompView in self.videoThumbSliderback.subviews) {
                if([prompView isKindOfClass:[RDConnectBtn class]]){
                    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition){//emmet 201701026 添加是否需要添加转场控制
                        [((RDConnectBtn *)prompView) setMaskURL:(_fileList[((RDConnectBtn *)prompView).fileIndex]).transitionMask];
                        [((RDConnectBtn *)prompView) setTransitionTypeName:(_fileList[((RDConnectBtn *)prompView).fileIndex]).transitionTypeName];
                        [((RDConnectBtn *)prompView) setTransitionTitle:(_fileList[((RDConnectBtn *)prompView).fileIndex]).transitionName];
                    }
                    prompView.hidden = NO;
                }
            }
        });
//        TOCK;
        
        //    [self.toolBarView removeFromSuperview];
        //    self.toolBarView = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self getToolBarItems];
        });
        //    [operationView addSubview:self.toolBarView];
//        TOCK;
        __weak typeof(self) myself = self;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self initPlayer:^{
#if isUseCustomLayer
                [myself refreshCustomTextTimeRange];
#endif
            }];
        });
//        TOCK;
    });
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
    
    if (CGRectIntersectsRect([draggingThumb frame], [self.videoThumbSliderback bounds]))
    {
        BOOL draggingRight = [draggingThumb frame].origin.x > [draggingThumb home].origin.x ? YES : NO;
        
        /* we're going to shift over all the thumbs who live between the home of the moving thumb */
        /* and the current touch location. A thumb counts as living in this area if the midpoint  */
        /* of its home is contained in the area.                                                  */
        NSMutableArray *thumbsToShift = [[NSMutableArray alloc] init];
        
        // get the touch location in the coordinate system of the scroll view
        CGPoint touchLocation = [draggingThumb convertPoint:[draggingThumb touchLocation] toView:self.videoThumbSliderback];
        
        // calculate minimum and maximum boundaries of the affected area
        float minX = draggingRight ? CGRectGetMaxX([draggingThumb home]) : touchLocation.x;
        float maxX = draggingRight ? touchLocation.x : CGRectGetMinX([draggingThumb home]);
        
        // iterate through thumbnails and see which ones need to move over
        
        for (RDThumbImageView *thumb in [self.videoThumbSliderback subviews])
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

        //self.connectToolBarView.hidden = YES;
    self.toolBarView.hidden = NO;
    
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
        [self initCommonAlertViewWithTitle:str
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"否",nil)
                         otherButtonTitles:RDLocalizedString(@"是",nil)
                              alertViewTag:1];
        
    }
}
#pragma mark Autoscrolling methods

- (void)maybeAutoscrollForThumb:(RDThumbImageView *)thumb
{
    
    //return;
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

/**添加文件
 */
- (void)tapAddButton:(UIButton *)sender{
    
    [self.view addSubview:self.addLensView];
    [RDHelpClass animateView:_addLensView atUP:NO];
//    [self AddFile:((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType touchConnect: NO];
}

/**添加文件
 *@params isTouch 是否点击的两个缩略图之间的加号添加文件
 */
- (void)AddFile:(SUPPORTFILETYPE)type touchConnect:(BOOL) isTouch{
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && _videoCoreSDK.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [_hud setCaption:message];
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
        [_videoCoreSDK stop];
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
    
    mainVC.minCountLimit = 1;
    mainVC.textPhotoProportion = exportSize.width/(float)exportSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {

        [myself addFileWithList:filelist withType:type touchConnect: isTouch];
        
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    
    if( isSeplace )
        nav.editConfiguration.mediaCountLimit = 1;
    else
        nav.editConfiguration.mediaCountLimit = 0;
    
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:NO completion:nil];
    
}

- (void)addFileWithList:(NSMutableArray *)filelist withType:(SUPPORTFILETYPE)type touchConnect:(BOOL) istouch{
    
    isRefeshNextThumbCore = true;
    
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
                    
                    file.filtImagePatch = [RDHelpClass getMaterialThumbnail:file.contentURL];
                }
                file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                [filelist replaceObjectAtIndex:i withObject:file];
            }
        }
    }
    
    [filelist enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDFile * file = ((RDFile*)obj);
        [RDHelpClass fileCrop:file atfileCropModeType:_proportionIndex atEditSize:exportSize];
    }];
    
    if( isSeplace )
    {
        _isModigy = true;
        [RDHelpClass deleteMaterialThumbnail:_fileList[selectFileIndex].filtImagePatch];
        _fileList[selectFileIndex] = filelist[0];
        isSeplace = false;
        
        NSMutableArray *arr = [self.videoThumbSliderback.subviews mutableCopy];
        
        for (int i=0;i<arr.count;i++) {
            if([arr[i] isKindOfClass:[RDThumbImageView class]]){
                RDThumbImageView *thumb = arr[i];
                if(thumb.thumbId == selectFileIndex ){
                    thumb.home = thumb.frame;
                    thumb.contentFile = _fileList[selectFileIndex];
                    thumb.transitionTypeName = _fileList[selectFileIndex].transitionTypeName;
                    thumb.transitionDuration = _fileList[selectFileIndex].transitionDuration;
                    thumb.transitionName = _fileList[selectFileIndex].transitionName;
                    thumb.transitionMask = _fileList[selectFileIndex].transitionMask;
                    if(!_fileList[selectFileIndex].thumbImage){
                        [self performSelectorInBackground:@selector(refreshThumbImage:) withObject:thumb];
                    }else{
                        thumb.thumbIconView.image = _fileList[selectFileIndex].thumbImage;
                    }
                    [thumb selectThumb:YES];
                }
            }
        }
    }
    else
    {
        if (istouch) {
            NSRange range = NSMakeRange(selectFileIndex + 1, [filelist count]);
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
            [_fileList insertObjects:filelist atIndexes:indexSet];
        }else {
            [_fileList addObjectsFromArray:filelist];
        }
        _isModigy = true;
        CGPoint offset = self.videoThumbSlider.contentOffset;
        [self.videoThumbSliderback.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.videoThumbSlider removeFromSuperview];
        self.videoThumbSlider = nil;
        [self videoThumbSlider];
        [self->operationView addSubview:self.videoThumbSliderView];
        
        [self.videoThumbSlider setContentOffset:offset];
    }

//    [self.toolBarView removeFromSuperview];
//    self.toolBarView = nil;
    [self getToolBarItems];
//    [operationView addSubview:self.toolBarView];
    self.toolBarView.hidden = NO;
    _videoProgressSlider.hidden = NO;
    _durationLabel.hidden = NO;
    _currentLabel.hidden = NO;
    _playButton.hidden = NO;
    _titleView.hidden = NO;
    
    [self cancelAddLens];
    
    //添加文件后需重新计算输出分辨率
    __weak typeof(self) myself = self;
    [self initPlayer:^{
#if isUseCustomLayer
        [myself refreshCustomTextTimeRange];
#endif
    }];
}

- (void)getCustomTextImagePath:(NSString *)textImagePath thumbImage:(UIImage *)thumbImage customTextPhotoFile:(CustomTextPhotoFile *)file touchUpType:(NSInteger)touchUpType change:(BOOL)flag{
    @autoreleasepool {
        isRefeshNextThumbCore = true;
        [self cancelAddLens];
        if(flag){
            RDFile *selectFile = [_fileList objectAtIndex:selectFileIndex];
#if isUseCustomLayer
            selectFile.contentURL = [NSURL fileURLWithPath:textImagePath];
            selectFile.thumbImage = thumbImage;
            selectFile.cropRect = CGRectZero;
            selectFile.customTextPhotoFile = file;
            CGPoint offset = self.videoThumbSlider.contentOffset;
            [self refreshVideoThumbSlider];
            
            [self.videoThumbSlider setContentOffset:offset];
            
            [self initPlayer:nil];
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
                    [self refreshVideoThumbSlider];
                    
                    [self.videoThumbSlider setContentOffset:offset];
                    
                    [self initPlayer:nil];
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

            [self refreshVideoThumbSlider];
            offset.x = (_videoThumbSlider.contentSize.width < _videoThumbSlider.frame.size.width) ? 0 : offset.x;
            
            [self.videoThumbSlider setContentOffset:offset];
            
            __weak typeof(self) myself = self;
            _isModigy = true;
            [self player:^{
#if isUseCustomLayer
                [myself refreshCustomTextTimeRange];
#endif
            }];
        }
    }
}

- (void)refreshCustomTextTimeRange {
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
        if (file.customTextPhotoFile) {
            file.imageTimeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:idx];
        }
    }];
}
#if 1
- (CGSize)getEditVideoSize{
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    NSInteger pl_Count = 0;
    __block NSInteger pCount = 0;
    __block NSInteger lCount = 0;
    __block NSInteger picPCount = 0;
    __block NSInteger picLCount = 0;
    __block NSInteger picLVPCount = 0;
    NSMutableArray *sizearr = [[NSMutableArray alloc] init];
    NSMutableArray *arr = [self.videoThumbSliderback.subviews mutableCopy];
    for (int i=0;i<arr.count;i++) {
        if([arr[i] isKindOfClass:[RDThumbImageView class]]){
            RDFile *file = ((RDThumbImageView *)arr[i]).contentFile;
            //截取的是正方形
            
            __block CGSize lastSize = CGSizeZero;
            if(file.fileType == kFILEVIDEO){//视频
                AVURLAsset *urlAsset;
                if(file.contentURL){
                    urlAsset  = [AVURLAsset assetWithURL:file.contentURL];
                }
                if (file.isReverse) {
                    urlAsset = [AVURLAsset assetWithURL:file.reverseVideoURL];
                }
                BOOL isp = [RDHelpClass isVideoPortrait:urlAsset];
                lastSize = [RDHelpClass getVideoSizeForTrack:urlAsset];
                if(lastSize.width != lastSize.height){
                    if(isp){
                        if(file.rotate==-90 || file.rotate==-270){
                            lCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }else{
                            pCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }
                        
                    }else{
                        if(file.rotate==-90 || file.rotate==-270){
                            pCount ++;
                            lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        }else{
                            lCount ++;
                            lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        }
                    }
                    
                    CGSize last_Size;
                    if(lastSize.height<=lastSize.width){
                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*(lastSize.height/(float)lastSize.width));
                    }else{
                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height),kVIDEOWIDTH);
                    }
                    if(sizearr.count==0){
                        [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                    }else{
                        if(![sizearr containsObject:[NSValue valueWithCGSize:last_Size]]){
                            [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                        }
                    }
                }else{
                    if(lastSize.height == lastSize.width && lastSize.width>0){
                        pl_Count ++;
                    }
                }
            }
            else{
                //图片
                lastSize = [RDHelpClass getFullScreenImageWithUrl:file.contentURL].size;
                if(lastSize.width < lastSize.height){
                    if(file.rotate==-90){
                        picLCount ++;
                    }else if(file.rotate==-270){
                        picLCount ++;
                    }else{
                        picPCount ++;
                    }
                    
                }else if(lastSize.width == lastSize.height){
                    picLVPCount ++;
                    
                }else{
                    if(file.rotate==-90){
                        picPCount ++;
                    }else if(file.rotate==-270){
                        picPCount ++;
                    }else{
                        picLCount ++;
                    }
                }
            }
        }
    }
    
    CGSize editorSize = CGSizeZero;
    NSMutableArray *filesArr = [NSMutableArray array];
    for (int i=0;i<arr.count;i++) {
        if([arr[i] isKindOfClass:[RDThumbImageView class]]){
            [filesArr addObject:((RDThumbImageView *)arr[i]).contentFile];
        }
    }
    [arr removeAllObjects];
    arr = nil;
    
    if(editVideoSizeType == kVerticalscape){
        if(lCount>0){
            [_hud setCaption:RDLocalizedString(@"横屏视频不适合竖屏输出,系统将选择最佳画面比例", nil)];
            [_hud show];
            [_hud hideAfter:2];
            editVideoSizeType = oldEditVideoSizeType;
            //editorSize = CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);
            return oldEditVideoSize;
        }else{
            if(picLCount>0){
                editVideoSizeType = oldEditVideoSizeType;
                [_hud setCaption:RDLocalizedString(@"横屏视频不适合竖屏输出,系统将选择最佳画面比例", nil)];
                [_hud show];
                [_hud hideAfter:2];
                //editorSize = CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);
                return oldEditVideoSize;
            }
            if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
                CGSize s = [[sizearr firstObject] CGSizeValue];//输出比例为视频源比例
                editorSize = CGSizeMake(MIN(s.height, s.width),MAX(s.height, s.width));
                if(filesArr.count == 1)
                    editorSize = CGSizeMake(editorSize.width * ((RDFile *)filesArr[0]).crop.size.width, editorSize.height * ((RDFile *)filesArr[0]).crop.size.height);
                //                editorSize =  CGSizeMake(680, 512);
            }else{
                editorSize = CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);
            }
        }
    }else if(editVideoSizeType == kLandscape){
        if(pCount>0){
            editorSize = CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);
        }else{
            if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
                CGSize s = [[sizearr firstObject] CGSizeValue];//输出比例为视频源比例
                editorSize = CGSizeMake(MAX(s.height, s.width), MIN(s.height, s.width));
                if(filesArr.count == 1)
                    editorSize = CGSizeMake(editorSize.width * ((RDFile *)filesArr[0]).crop.size.width, editorSize.height * ((RDFile *)filesArr[0]).crop.size.height);
            }else{
                editorSize =  CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);
            }
        }
    }else if(editVideoSizeType == kQuadratescape){
        editorSize =  CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    
    if(editVideoSizeType == kAutomatic){
        
        NSMutableArray *arr = [self.videoThumbSliderback.subviews mutableCopy];
        
        for (int i=0;i<arr.count;i++) {
            if([arr[i] isKindOfClass:[RDThumbImageView class]]){
                RDThumbImageView *thumb = arr[i];
                if(thumb.contentFile.fileCropModeType == kCropType1v1){
                    return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
                }
            }
        }
        if(pl_Count != 0 && pCount == 0 && lCount ==0 && (picLVPCount == 0 && picPCount == 0 && picLCount == 0)){
            return  CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }
        if((pCount != 0 && lCount !=0) || pl_Count != 0){//横屏竖屏视频都有时输出比例1 ：1
            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }
        else if(pCount ==0 && lCount != 0){
            if(sizearr.count == 1 && picPCount == 0  && picLVPCount == 0){
                CGSize size = [[sizearr firstObject] CGSizeValue];
                if(filesArr.count == 1)
                    size = CGSizeMake(size.width * ((RDFile *)filesArr[0]).crop.size.width, size.height * ((RDFile *)filesArr[0]).crop.size.height);
                return size;//输出比例为视频源比例
            }else if(picPCount !=0 /*|| picLVPCount != 0*/){
                return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//横屏视频和竖屏图片组合
            }
            return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//输出比例16 ：9
        }else if(lCount == 0 && pCount != 0){
            if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
                CGSize size = [[sizearr firstObject] CGSizeValue];
                if(filesArr.count == 1)
                    size = CGSizeMake(size.width * ((RDFile *)filesArr[0]).crop.size.width, size.height * ((RDFile *)filesArr[0]).crop.size.height);
                return size;//输出比例为视频源比例
            }else if(picLCount != 0 || picLVPCount != 0){
                return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//竖屏视频和横屏图片组合
            }
            return CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);//输出比例9 ：16
        }else{
            return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//只有图片时输出比例为16 ：9
        }
        
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }else{
        return editorSize;
    }
    
}
#else
- (CGSize)getEditVideoSize{
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    NSInteger pl_Count = 0;
    __block NSInteger pCount = 0;
    __block NSInteger lCount = 0;
    __block NSInteger picPCount = 0;
    __block NSInteger picLCount = 0;
    __block NSInteger picLVPCount = 0;
    NSMutableArray *sizearr = [[NSMutableArray alloc] init];
    NSMutableArray *arr = [self.videoThumbSliderback.subviews mutableCopy];
    for (int i=0;i<arr.count;i++) {
        if([arr[i] isKindOfClass:[RDThumbImageView class]]){
            RDFile *file = ((RDThumbImageView *)arr[i]).contentFile;
            //截取的是正方形
            
            __block CGSize lastSize = CGSizeZero;
            if(file.fileType == kFILEVIDEO){//视频
                AVURLAsset *urlAsset;
                if(file.contentURL){
                    urlAsset  = [AVURLAsset assetWithURL:file.contentURL];
                }
                if (file.isReverse) {
                    urlAsset = [AVURLAsset assetWithURL:file.reverseVideoURL];
                }
                lastSize = [RDHelpClass getVideoSizeForTrack:urlAsset];
                if (file.rotate == -90 || file.rotate == -270) {
                    lastSize = CGSizeMake(lastSize.height, lastSize.width);
                }
                CGSize croppedSize = CGSizeMake(lastSize.width*file.crop.size.width, lastSize.height*file.crop.size.height);
                if(croppedSize.width != croppedSize.height){
                    CGSize last_Size;
                    if(croppedSize.height < croppedSize.width){
                        lCount++;
                        lastSize = CGSizeMake(MAX(lastSize.height, lastSize.width), MIN(lastSize.height, lastSize.width));
                        last_Size = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*(lastSize.height/(float)lastSize.width));
                    }else{
                        pCount ++;
                        lastSize = CGSizeMake(MIN(lastSize.height, lastSize.width), MAX(lastSize.height, lastSize.width));
                        last_Size = CGSizeMake(kVIDEOWIDTH*(lastSize.width/(float)lastSize.height),kVIDEOWIDTH);
                    }
                    if(sizearr.count==0){
                        [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                    }else{
                        if(![sizearr containsObject:[NSValue valueWithCGSize:last_Size]]){
                            [sizearr addObject:[NSValue valueWithCGSize:last_Size]];
                        }
                    }
                }else if(croppedSize.height == croppedSize.width && croppedSize.width>0){
                    pl_Count ++;
                }
            }
            else{
                //图片
                lastSize = [RDHelpClass getFullScreenImageWithUrl:file.contentURL].size;
                CGSize croppedSize = CGSizeMake(lastSize.width*file.crop.size.width, lastSize.height*file.crop.size.height);
                if(croppedSize.width < croppedSize.height){
                    picPCount ++;
                }else if(croppedSize.width == croppedSize.height){
                    picLVPCount ++;
                }else{
                    picLCount ++;
                }
            }
        }
    }
    
    CGSize editorSize = CGSizeZero;
    NSMutableArray *filesArr = [NSMutableArray array];
    for (int i=0;i<arr.count;i++) {
        if([arr[i] isKindOfClass:[RDThumbImageView class]]){
            [filesArr addObject:((RDThumbImageView *)arr[i]).contentFile];
        }
    }
    [arr removeAllObjects];
    arr = nil;
    
    if(editVideoSizeType == kVerticalscape){
        if(lCount>0){
            [_hud setCaption:RDLocalizedString(@"横屏视频不适合竖屏输出,系统将选择最佳画面比例", nil)];
            [_hud show];
            [_hud hideAfter:2];
            editVideoSizeType = oldEditVideoSizeType;
            //editorSize = CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);
            return oldEditVideoSize;
        }else{
            if(picLCount>0){
                editVideoSizeType = oldEditVideoSizeType;
                [_hud setCaption:RDLocalizedString(@"横屏视频不适合竖屏输出,系统将选择最佳画面比例", nil)];
                [_hud show];
                [_hud hideAfter:2];
                //editorSize = CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);
                return oldEditVideoSize;
            }
            if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
                CGSize s = [[sizearr firstObject] CGSizeValue];//输出比例为视频源比例
                editorSize = CGSizeMake(MIN(s.height, s.width),MAX(s.height, s.width));
                if(filesArr.count == 1)
                    editorSize = CGSizeMake(editorSize.width * ((RDFile *)filesArr[0]).crop.size.width, editorSize.height * ((RDFile *)filesArr[0]).crop.size.height);
            }else{
                editorSize = CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);
            }
        }
    }else if(editVideoSizeType == kLandscape){
        if(pCount>0){
            editorSize = CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);
        }else{
            if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
                CGSize s = [[sizearr firstObject] CGSizeValue];//输出比例为视频源比例
                editorSize = CGSizeMake(MAX(s.height, s.width), MIN(s.height, s.width));
                if(filesArr.count == 1)
                    editorSize = CGSizeMake(editorSize.width * ((RDFile *)filesArr[0]).crop.size.width, editorSize.height * ((RDFile *)filesArr[0]).crop.size.height);
            }else{
                editorSize =  CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);
            }
        }
    }else if(editVideoSizeType == kQuadratescape){
        editorSize =  CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    
    if(editVideoSizeType == kAutomatic){
        
        NSMutableArray *arr = [self.videoThumbSliderback.subviews mutableCopy];
        
        for (int i=0;i<arr.count;i++) {
            if([arr[i] isKindOfClass:[RDThumbImageView class]]){
                RDThumbImageView *thumb = arr[i];
                if(thumb.contentFile.fileCropModeType == kCropType1v1){
                    return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
                }
            }
        }
        if(pl_Count != 0 && pCount == 0 && lCount ==0 && (picLVPCount == 0 && picPCount == 0 && picLCount == 0)){
            return  CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }
        if(pCount != 0 && lCount !=0){//横屏竖屏视频都有时输出比例1 ：1
            return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }
        else if(pCount ==0 && lCount != 0){
            if(sizearr.count == 1 && picPCount == 0  && picLVPCount == 0){
                CGSize size = [[sizearr firstObject] CGSizeValue];
                if(filesArr.count == 1)
                    size = CGSizeMake(size.width * ((RDFile *)filesArr[0]).crop.size.width, size.height * ((RDFile *)filesArr[0]).crop.size.height);
                return size;//输出比例为视频源比例
            }else if(picPCount !=0 /*|| picLVPCount != 0*/){
                return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//横屏视频和竖屏图片组合
            }
            return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//输出比例16 ：9
        }else if(lCount == 0 && pCount != 0){
            if(sizearr.count == 1 && picLCount == 0 && picLVPCount == 0){
                CGSize size = [[sizearr firstObject] CGSizeValue];
                if(filesArr.count == 1)
                    size = CGSizeMake(size.width * ((RDFile *)filesArr[0]).crop.size.width, size.height * ((RDFile *)filesArr[0]).crop.size.height);
                return size;//输出比例为视频源比例
            }else if(picLCount != 0 || picLVPCount != 0){
                return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);//竖屏视频和横屏图片组合
            }
            return CGSizeMake(kVIDEOHEIGHT, kVIDEOWIDTH);//输出比例9 ：16
        }else{
            return CGSizeMake(kVIDEOWIDTH, kVIDEOHEIGHT);//只有图片时输出比例为16 ：9
        }
        
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }else{
        return editorSize;
    }
}
#endif

- (void)deletedFile:(RDThumbImageView *)tiv{
    if(_fileList.count>1){
        [RDHelpClass deleteMaterialThumbnail:_fileList[tiv.thumbId].filtImagePatch];
        [_fileList removeObjectAtIndex:tiv.thumbId];
        selectFileIndex = MAX((selectFileIndex>=tiv.thumbId?selectFileIndex - 1 : selectFileIndex), 0);
        
        _fileList[selectFileIndex].transitionDuration = MIN([self maxTransitionDuration:selectFileIndex], _fileList[selectFileIndex].transitionDuration);
        
        CGPoint offset = self.videoThumbSlider.contentOffset;
        
        float diffx = (tiv.frame.origin.x + tiv.frame.size.width) - offset.x;
        offset.x -= MIN(tiv.frame.size.width + 34, diffx);
        offset.x = MAX(offset.x, 0);
        
        
        NSMutableArray *arra = [self.videoThumbSliderback.subviews mutableCopy];
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
        float videoThumbSlider_Height = 95;
        float videoThumbSlider_Wdith = videoThumbSlider_Height + 20;
        
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
        float fwidth  = _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20  - (videoThumbSlider_Height + 10)*2.0   + (_videoThumbSlider.frame.size.height*2.0/3.0);
        if( fwidth <= kWIDTH )
            fwidth = kWIDTH + 10;
        _videoThumbSlider.contentSize = CGSizeMake(fwidth, 0);
        [self getToolBarItems];
//        [self.toolBarView removeFromSuperview];
//        self.toolBarView = nil;
//        [operationView addSubview:self.toolBarView];
        
        __weak typeof(self) myself = self;
        [self initPlayer:^{
#if isUseCustomLayer
            [myself refreshCustomTextTimeRange];
#endif
        }];
        _isModigy = true;
    }else{
        [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"至少保留一个文件", nil)]];
        [_hud show];
        [_hud hideAfter:2];
    }
}

#pragma mark- UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 1){
        if(buttonIndex == 1){
            [self deletedFile:deletedFileView];
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(RDAddItemButton *) TransitionBtn:( NSString * ) str atImage:(UIImage *) image atLableText:(NSString *) text atHeight:(CGSize) size
{
    RDAddItemButton * transitionBtn = [RDAddItemButton initFXframe:CGRectMake(0, 0, size.width, size.height) atpercentage:0.7];
    
    transitionBtn.label.text = str;
    
    if( text )
    {
        transitionBtn.thumbnailIV.backgroundColor = UIColorFromRGB(0x27262c);
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, transitionBtn.thumbnailIV.frame.size.width, transitionBtn.thumbnailIV.frame.size.height)];
        label.text = text;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:15.0];
        [transitionBtn.thumbnailIV addSubview:label];
    }
    else
        transitionBtn.thumbnailIV.image = image;
    
    transitionBtn.thumbnailIV.layer.borderWidth = 1.0;
    transitionBtn.thumbnailIV.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:0.0].CGColor;
    transitionBtn.thumbnailIV.layer.cornerRadius = 5.0;
    transitionBtn.thumbnailIV.layer.masksToBounds = YES;
    
    float ItemBtnWidth = [RDHelpClass widthForString:transitionBtn.label.text andHeight:12 fontSize:12];
    
    if( ItemBtnWidth > transitionBtn.label.frame.size.width )
        [transitionBtn startScrollTitle];
    
    return transitionBtn;
}

#pragma mark - 转场
- (UIView *)transitionView{
    if (_transitionView) {
        return _transitionView;
    }
    float width = _bottomView.frame.size.height/2.0*0.7;
    float height = _bottomView.frame.size.height/2.0;
    
    transitionTypeScrollView =  [UIScrollView new];
    transitionTypeScrollView.frame = CGRectMake(5, 0, _bottomView.frame.size.width, _bottomView.frame.size.height/4.0);
    transitionTypeScrollView.showsVerticalScrollIndicator = NO;
    transitionTypeScrollView.showsHorizontalScrollIndicator = NO;
    [_bottomView addSubview:transitionTypeScrollView];
    
    _transitionView = [[UIView alloc] initWithFrame:CGRectMake(8, _bottomView.frame.size.height/4.0 ,kWIDTH, _bottomView.frame.size.height/2.0 )];
    _transitionView.backgroundColor = TOOLBAR_COLOR;
    [_bottomView addSubview:_transitionView];
    
    transitionNoneBtn = [self TransitionBtn:RDLocalizedString(@"无转场", nil) atImage:nil atLableText:RDLocalizedString(@"无", nil) atHeight:CGSizeMake(height, height)];
    transitionNoneBtn.frame = CGRectMake(0, 2, transitionNoneBtn.frame.size.width, transitionNoneBtn.frame.size.height);
    [transitionNoneBtn addTarget:self action:@selector(transitionNoneBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//    [_transitionView addSubview:transitionNoneBtn];

    
//    transitionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(16 + width + 4, 0.0, kWIDTH - 16 - width - 4, height)];
    transitionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0.0, kWIDTH, height)];
    transitionScrollView.backgroundColor = TOOLBAR_COLOR;
    transitionScrollView.showsVerticalScrollIndicator = NO;
    transitionScrollView.showsHorizontalScrollIndicator = NO;
    transitionScrollView.scrollEnabled = NO;
    transitionScrollView.tag = 1000;
    [_transitionView addSubview:transitionScrollView];
    
    float useToAllTranstionWidth =  [RDHelpClass widthForString:RDLocalizedString(@"应用到所有", nil) andHeight:14 fontSize:14] + 50;
    _useToAllTranstionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _useToAllTranstionBtn.frame = CGRectMake( 5, _transitionView.frame.size.height + _transitionView.frame.origin.y + ((_bottomView.frame.size.height - (_transitionView.frame.size.height + _transitionView.frame.origin.y))-30)/2.0 + 2.5 + 2.5, useToAllTranstionWidth, 35);
    _useToAllTranstionBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [_useToAllTranstionBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
    [_useToAllTranstionBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
    _useToAllTranstionBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    [_useToAllTranstionBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
    [_useToAllTranstionBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
    [_useToAllTranstionBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
    [_useToAllTranstionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_useToAllTranstionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    [_useToAllTranstionBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
    [_useToAllTranstionBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
    [_useToAllTranstionBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
    _useToAllTranstionBtn.backgroundColor = [UIColor clearColor];
    [_useToAllTranstionBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
    _useToAllTranstionBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [_useToAllTranstionBtn addTarget:self action:@selector(useToAllTranstionBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    _useToAllTranstionBtn.selected = NO;
    [_bottomView addSubview:_useToAllTranstionBtn];
    
    _defaultTranstionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    float defaultWidth =  [RDHelpClass widthForString:RDLocalizedString(@"随机", nil) andHeight:12 fontSize:12];
    
    _defaultTranstionBtn.frame = CGRectMake( _transitionView.frame.size.width - (50 + defaultWidth) , (_bottomView.frame.size.height/4.0 - 35)/2.0, 50 + defaultWidth, 35);
    _defaultTranstionBtn.layer.cornerRadius = 4;
    _defaultTranstionBtn.layer.masksToBounds = YES;
    _defaultTranstionBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_defaultTranstionBtn setTitle:RDLocalizedString(@"随机", nil) forState:UIControlStateNormal];
    [_defaultTranstionBtn setTitle:RDLocalizedString(@"随机", nil) forState:UIControlStateHighlighted];
    _defaultTranstionBtn.titleLabel.textAlignment = NSTextAlignmentRight;
    [_defaultTranstionBtn setImage:[RDHelpClass imageWithContentOfFile:@"transitions/剪辑-转场_随机_默认_"] forState:UIControlStateNormal];
    [_defaultTranstionBtn setImage:[RDHelpClass imageWithContentOfFile:@"transitions/剪辑-转场_随机_选中_"] forState:UIControlStateSelected];
    [_defaultTranstionBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
    [_defaultTranstionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_defaultTranstionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    [_defaultTranstionBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
    [_defaultTranstionBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 0)];
    [_defaultTranstionBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
    _defaultTranstionBtn.backgroundColor = [UIColor clearColor];
    [_defaultTranstionBtn addTarget:self action:@selector( defaultTranstionBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    _defaultTranstionBtn.selected = NO;
    [_bottomView addSubview:_defaultTranstionBtn];
    
    _transtionDurationLabel = [[UILabel alloc] init];
    _transtionDurationLabel.backgroundColor = [UIColor clearColor];
    _transtionDurationLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    _transtionDurationLabel.font = [UIFont systemFontOfSize:12];
    _transtionDurationLabel.textAlignment = NSTextAlignmentCenter;
    _transtionDurationLabel.frame = CGRectMake(_useToAllTranstionBtn.frame.size.width + _useToAllTranstionBtn.frame.origin.x, _transitionView.frame.size.height + _transitionView.frame.origin.y + ((_bottomView.frame.size.height - (_transitionView.frame.size.height + _transitionView.frame.origin.y))-30)/2.0 + 5 + 2.5, 40, 30);
    [_bottomView addSubview:_transtionDurationLabel];
    
    _transtionDurationSlider = [[UISlider alloc] init];
    _transtionDurationSlider.frame = CGRectMake(_transtionDurationLabel.frame.size.width + _transtionDurationLabel.frame.origin.x + 10, _transitionView.frame.size.height + _transitionView.frame.origin.y + ((_bottomView.frame.size.height - (_transitionView.frame.size.height + _transitionView.frame.origin.y))-30)/2.0 + 5 + 2.5, kWIDTH - (_transtionDurationLabel.frame.size.width + _transtionDurationLabel.frame.origin.x ) - 25  , 30);
    _transtionDurationSlider.maximumValue = 2.0;
    _transtionDurationSlider.minimumValue = kTransitionMinValue;
    _transtionDurationSlider.value = MAX(kTransitionMinValue, _transitionDuration);
//    UIImage *theImage = [RDHelpClass rdImageWithColor:Main_Color cornerRadius:7];
    [_transtionDurationSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐-播放进度轨道1"];
    image = [image imageWithTintColor];
    [_transtionDurationSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐-播放进度轨道1_1"];
    [_transtionDurationSlider setMaximumTrackImage:image forState:UIControlStateNormal];
//    _transtionDurationSlider.maximumTrackTintColor = [UIColor whiteColor];
//    _transtionDurationSlider.minimumTrackTintColor = [UIColor whiteColor];
    [_transtionDurationSlider addTarget:self action:@selector(changeSlider) forControlEvents:UIControlEventValueChanged];
    [_transtionDurationSlider addTarget:self action:@selector(liftSlider) forControlEvents:UIControlEventTouchUpInside];
    [_transtionDurationSlider addTarget:self action:@selector(liftSlider) forControlEvents:UIControlEventTouchUpOutside];
    [_bottomView addSubview:_transtionDurationSlider];
    
    return _transitionView;
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
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, _transitionToolbarView.frame.size.width - 44 * 2, 44)];
        label.text = RDLocalizedString(@"转场", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17];
        [_transitionToolbarView addSubview:label];
        
        if (transitionList && transitionList.count > 0) {
            [self refreshTransitionTypeView];
        }
    }
    return _transitionToolbarView;
}

-(void)noBtn_onclik
{
    [self transitionNoneBtnAction:transitionNoneBtn];
}

- (void)refreshTransitionTypeView {
    float width = 0.0;
    width = 50;
//    if (transitionList.count < 5) {
//        width = transitionTypeScrollView.bounds.size.width / transitionList.count;
//    }else {
//        width = transitionTypeScrollView.bounds.size.width / 4.0;
//    }
    
    UIButton *noBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, transitionTypeScrollView.frame.size.height*3.0/5.0 + 25, transitionTypeScrollView.frame.size.height)];
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(25.0/2.0, transitionTypeScrollView.frame.size.height*2.0/5.0/2.0, transitionTypeScrollView.frame.size.height*3.0/5.0, transitionTypeScrollView.frame.size.height*3.0/5.0)];
    imageView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无@3x" Type:@"png"]];
    noBtn.tag                            = 100;
    [noBtn addTarget:self action:@selector(noBtn_onclik) forControlEvents:UIControlEventTouchUpInside];
    [noBtn addSubview:imageView];
    
    [transitionTypeScrollView addSubview:noBtn];
    
    transitionTypeScrollView.backgroundColor = TOOLBAR_COLOR;
    __block float contentWidth = transitionTypeScrollView.frame.size.height*3.0/5.0 + 25;
    [transitionList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString(obj[@"typeName"],nil) andHeight:16 fontSize:16] + 25;
        
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake(contentWidth, 0, ItemBtnWidth, transitionTypeScrollView.bounds.size.height);
        itemBtn.backgroundColor = TOOLBAR_COLOR;
        [itemBtn setTitle:RDLocalizedString(obj[@"typeName"], nil) forState:UIControlStateNormal];
        [itemBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [itemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        itemBtn.tag = idx + 1;
        [itemBtn addTarget:self action:@selector(transitionTypeItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [transitionTypeScrollView addSubview:itemBtn];
        contentWidth += ItemBtnWidth;
        
        float width = _bottomView.frame.size.height/2.0 * 0.7;
        float height = _bottomView.frame.size.height/2.0;
        UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flow.itemSize = CGSizeMake(width, height);
        flow.sectionInset = UIEdgeInsetsMake(5.0, 8.0, 0.0, 8.0);
        flow.minimumLineSpacing = 16;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame: CGRectMake(transitionScrollView.bounds.size.width*idx, 0.0, transitionScrollView.bounds.size.width, height) collectionViewLayout: flow];
        collectionView.backgroundColor = TOOLBAR_COLOR;
        collectionView.tag = idx + 1;
        collectionView.delegate = self;
        collectionView.dataSource = self;
         
        ((UIScrollView*)collectionView).delegate = self;
        
        collectionView.alwaysBounceVertical = NO;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        [collectionView registerClass:[RDTranstionCollectionViewCell class] forCellWithReuseIdentifier:@"TransitionCell"];
        collectionView.backgroundColor = TOOLBAR_COLOR;
        collectionView.contentSize = CGSizeMake(0, 0);
        [transitionScrollView addSubview:collectionView];
    }];
    transitionScrollView.backgroundColor = TOOLBAR_COLOR;
    transitionTypeScrollView.contentSize = CGSizeMake(contentWidth+20, 0);
}

-(void)cancel_Btn
{
    if( [_videoCoreSDK isPlaying] )
        [self playVideo:NO];
    isTranstion  = false;
    isAddTransitionBuild = true;
    if(  isModifyTranstion )
    {
        [thumbViewItems enumerateObjectsUsingBlock:^(RDThumbImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger index = obj.thumbId;
            _fileList[index].transitionTypeName = obj.transitionTypeName;
            _fileList[index].transitionDuration = obj.transitionDuration;
            _fileList[index].transitionName = obj.transitionName;
            _fileList[index].transitionMask = obj.transitionMask;
        }];
//        seekTime = _videoCoreSDK.currentTime;
        seekTime = animationStartTime;
        [self initPlayer:nil];
        isModifyTranstion = false;
    }
    else{
        [_videoCoreSDK seekToTime:animationStartTime];
    }
    _toolBarView.hidden = NO;
    [RDHelpClass animateViewHidden:_bottomView atUP:NO atBlock:^{
        _bottomView.hidden = YES;
        _transitionView.hidden = YES;
//        _transitionToolbarView.hidden = YES;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
        _playButton.frame = transitionPlayButtonRect;
        _playerView.frame = transitionPlayViewRect;
        _videoCoreSDK.frame = _playerView.bounds;
        _bottomView.backgroundColor = [UIColor clearColor];
        _bottomView.frame = transitionRect;
        
        operationView.hidden = NO;
        _titleView.hidden = NO;
        _transtionDurationSlider.value = 0.0;
        lastSelectIndexItemDuration = 0.0;
        _useToAllTranstionBtn.selected = NO;
        _defaultTranstionBtn.selected = NO;
    }];
    [RDHelpClass animateViewHidden:_transitionToolbarView atUP:NO atBlock:^{
        _transitionToolbarView.hidden = YES;
    }];
    
}

-(void)finish_Btn
{
    _isModigy = true;
    
    if( [_videoCoreSDK isPlaying] )
        [self playVideo:NO];
    isAddTransitionBuild = true;
    isTranstion = false;
    if (_useToAllTranstionBtn.selected) {
        if( !_defaultTranstionBtn.isSelected )
        {
            RDFile *selectedFile = _fileList[selectFileIndex];
            for (int idx = 0; idx < _fileList.count - 1; idx++) {
                RDFile * obj = _fileList[idx];
                obj.transitionMask = selectedFile.transitionMask;
                obj.transitionDuration = selectedFile.transitionDuration;
                obj.transitionTypeName = selectedFile.transitionTypeName;
                obj.transitionName = selectedFile.transitionName;
                RDScene *scene = scenes[idx];
                [RDHelpClass setTransition:scene.transition file:obj];
            }
        }
        else
        {
            NSMutableArray *transitionArray = [NSMutableArray array];
            [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [transitionArray addObjectsFromArray:obj[@"data"]];
            }];
            for (int idx = 0; idx < _fileList.count - 1; idx++) {
                __block NSString *typeName = kDefaultTransitionTypeName;
                NSInteger index = arc4random()%(transitionArray.count) + 1;
                NSString *itemName = transitionArray[index];
                if ([itemName pathExtension]) {
                    itemName = [itemName stringByDeletingPathExtension];
                }
                [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![itemName isEqualToString:RDLocalizedString(@"无", nil)]) {
                        [obj[@"data"] enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                            if ([[obj1 stringByDeletingPathExtension] isEqualToString:itemName]) {
                                typeName = obj[@"typeName"];;
                                *stop1 = YES;
                                *stop = YES;
                            }
                        }];
                    }
                }];
                [self setTransitionWithTypeName:typeName transitionName:itemName atIndex:idx isPlay:NO];
            }
        }
        seekTime = animationStartTime;
        [self initPlayer:^{
#if isUseCustomLayer
            [self refreshCustomTextTimeRange];
#endif
            [self playVideo:NO];
        }];
    }
    else
    {
        [_videoCoreSDK seekToTime:animationStartTime];
        
    }
    NSMutableArray *arra = [self.videoThumbSliderback.subviews mutableCopy];
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
    [RDHelpClass animateViewHidden:_bottomView atUP:NO atBlock:^{
        _bottomView.hidden = YES;
        _transitionView.hidden = YES;
//        _transitionToolbarView.hidden = YES;
            _videoProgressSlider.hidden = NO;
            _durationLabel.hidden  = NO;
            _currentLabel.hidden = NO;
            _playButton.frame = transitionPlayButtonRect;
            _playerView.frame = transitionPlayViewRect;
            _videoCoreSDK.frame = _playerView.bounds;
            _bottomView.backgroundColor = [UIColor clearColor];
            _bottomView.frame = transitionRect;
            
            [self setWhetherToModify:YES];
        //    _transitionView.hidden = YES;
        //    _transitionToolbarView.hidden = YES;
            operationView.hidden = NO;
            _toolBarView.hidden = NO;
            _titleView.hidden = NO;
        //    _bottomView.hidden = YES;
            _transtionDurationSlider.value = 0.0;
            lastSelectIndexItemDuration = 0.0;
    }];
    [RDHelpClass animateViewHidden:_transitionToolbarView atUP:NO atBlock:^{
        _transitionToolbarView.hidden = YES;
    }];
    [thumbViewItems enumerateObjectsUsingBlock:^(RDThumbImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = obj.thumbId;
        obj.transitionDuration = _fileList[index].transitionDuration;
        obj.transitionTypeName = _fileList[index].transitionTypeName;
        obj.transitionName = _fileList[index].transitionName;
        obj.transitionMask = _fileList[index].transitionMask;
    }];
    
}

- (void)transitionTypeItemBtnAction:(UIButton *)sender {
    if (![sender.titleLabel.text isEqualToString:RDLocalizedString(selectedTransitionTypeName, nil)]) {
        [transitionList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"typeName"] isEqualToString:selectedTransitionTypeName]) {
                UIButton *prevBtn = [transitionTypeScrollView viewWithTag:idx + 1];
                prevBtn.selected = NO;
                prevBtn.titleLabel.font = [UIFont systemFontOfSize:14];
                UICollectionView *prevCV = [transitionScrollView viewWithTag:idx + 1];
                prevCV.contentOffset = CGPointZero;
                *stop = YES;
            }
        }];
        sender.selected = YES;
        currentLabelTransitionIndex = sender.tag;
        sender.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        selectedTransitionTypeName = [transitionList[sender.tag - 1] objectForKey:@"typeName"];
        transitionScrollView.contentOffset = CGPointMake((sender.tag - 1) * transitionScrollView.bounds.size.width, 0);
    }
}

- (void)transitionNoneBtnAction:(UIButton *)sender {
    RDAddItemButton * addItemBtn = (RDAddItemButton*)transitionNoneBtn;
    if (!sender.selected) {
        sender.selected = YES;
        [self setTransitionWithTypeName:kDefaultTransitionTypeName transitionName:nil atIndex:selectFileIndex isPlay:YES];
    }else {
        [self playVideo:YES];
    }
    addItemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
    [addItemBtn  textColor:[UIColor whiteColor]];
    if( currentCell )
    {
        [currentCell  textColor:[UIColor colorWithWhite:1 alpha:0.5]];
        currentCell.customImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        currentCell = nil;
    }
}

/**开始滑动
 */
- (void)backEvent{
    [self.navigationController popViewControllerAnimated:NO];
    //    [self dismissViewControllerAnimated:YES completion:nil];
}
/** 改变转场时长
 */
- (void)changeSlider{
    _transtionDurationLabel.text = [NSString stringWithFormat:RDLocalizedString(@"%.1f秒", nil),_transtionDurationSlider.value];
    lastSelectIndexItemDuration = _transtionDurationSlider.value;
}
/** 改变转场时长 触摸抬起事件
 */
- (void)liftSlider{
    _transtionDurationLabel.text = [NSString stringWithFormat:RDLocalizedString(@"%.1f秒", nil),_transtionDurationSlider.value];
    lastSelectIndexItemDuration = _transtionDurationSlider.value;
    [self setTransitionWithTypeName:selectedTransitionTypeName transitionName:selectedTransitionName atIndex:selectFileIndex isPlay:YES];
}

- (void)defaultTranstionBtnOnClick:(UIButton *)sender{
    isModifyTranstion = true;
    
    sender.selected = !sender.selected;
    NSString *itemName;
    if (sender.selected) {
        transitionNoneBtn.selected = NO;
        RDAddItemButton * addItemBtn = (RDAddItemButton*)transitionNoneBtn;
        addItemBtn.thumbnailIV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        [addItemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
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
        return;
    }
    
    if( currentCell )
    {
        [currentCell  textColor:[UIColor colorWithWhite:1 alpha:0.5]];
        currentCell.customImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        currentCell = nil;
    }
    
    __block NSString *typeName = kDefaultTransitionTypeName;
    __block NSInteger prevTypeIndex;
    __block int count = 0;
    if (!itemName || [itemName isEqualToString:RDLocalizedString(@"无", nil)]) {
        transitionNoneBtn.selected = YES;
        RDAddItemButton * addItemBtn = (RDAddItemButton*)transitionNoneBtn;
        addItemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
        [addItemBtn  textColor:[UIColor whiteColor]];
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
                    CGFloat offsetX = idx1 *( _bottomView.frame.size.height/2.0 * 0.7 + 16) ;
                    if (offsetX + collectionView.frame.size.width >= collectionView.contentSize.width) {
                        [collectionView setContentOffset:CGPointMake(collectionView.contentSize.width - collectionView.frame.size.width, 0)];
                    }else {
                        [collectionView setContentOffset:CGPointMake(offsetX, 0)];
                    }
                    RDTranstionCollectionViewCell *selectCell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                    [selectCell textColor:Main_Color];
                    
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
    [self setTransitionWithTypeName:typeName transitionName:itemName atIndex:selectFileIndex isPlay:YES];
}

- (void)useToAllTranstionBtnOnClick:(UIButton *)sender{
    sender.selected = !sender.selected;
    isModifyTranstion = true;
}

#pragma mark - UICollectionViewDataSource methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[transitionList[collectionView.tag - 1] objectForKey:@"data"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TransitionCell";
    RDTranstionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell delete];
//    for (UIView *view in cell.subviews) {
//        [view removeFromSuperview];
//    }
    cell.exclusiveTouch = NO;
    [cell initwithRect:cell.frame];
    cell.customImageView.highlighted = NO;
    // 设置背景颜色
    cell.backgroundView = nil;
    cell.backgroundColor = TOOLBAR_COLOR;
    NSString *typeName = [transitionList[collectionView.tag - 1] objectForKey:@"typeName"];
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    if ([itemName pathExtension]) {
        itemName = [itemName stringByDeletingPathExtension];
    }
    NSString *imagePath = [RDHelpClass getTransitionIconPath:typeName itemName:itemName];
    cell.customImageView.image = [UIImage imageWithContentsOfFile:imagePath];
    cell.customDetailTextLabel.text = RDLocalizedString(itemName, nil);
    cell.customDetailTextLabel.hidden = NO;
    cell.customDetailTextLabel.font = [UIFont systemFontOfSize:12];
    if([selectedTransitionName isEqualToString:itemName]){
        [cell textColor:[UIColor whiteColor]];
        currentCell = cell;
        cell.customImageView.layer.borderColor = Main_Color.CGColor;
        
    }else{
        [cell textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        cell.customImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
    }
    
//    float defaultWidth =  [RDHelpClass widthForString:RDLocalizedString(RDLocalizedString(itemName, nil), nil) andHeight:13 fontSize:13];
//     if( defaultWidth >= cell.customDetailTextLabel.frame.size.width){
//         [cell startScrollTitle];
//     }
//     else{
//         [cell stopScrollTitle];
//     }
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(RDTranstionCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    if ([selectedTransitionName isEqualToString:[itemName stringByDeletingPathExtension]]) {
        [cell textColor:[UIColor whiteColor]];
        cell.customImageView.layer.borderColor = Main_Color.CGColor;
    }
    
    float defaultWidth =  [RDHelpClass widthForString:RDLocalizedString(itemName, nil) andHeight:13 fontSize:13];
    if( defaultWidth >= cell.customDetailTextLabel.frame.size.width){
        [cell startScrollTitle];
    }
    else{
        [cell stopScrollTitle];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(RDTranstionCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    float defaultWidth =  [RDHelpClass widthForString:RDLocalizedString(itemName, nil) andHeight:13 fontSize:13];
    if( defaultWidth >= cell.customDetailTextLabel.frame.size.width){
        [cell startScrollTitle];
    }
    else{
        [cell stopScrollTitle];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    RDTranstionCollectionViewCell *cell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    [cell textColor:[UIColor colorWithWhite:1 alpha:0.5]];
    cell.customImageView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:0.0].CGColor;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    RDTranstionCollectionViewCell *cell = (RDTranstionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    transitionNoneBtn.selected = NO;
    RDAddItemButton * addItemBtn = (RDAddItemButton*)transitionNoneBtn;
    addItemBtn.thumbnailIV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
    [addItemBtn  textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    
    
    NSString *typeName = [transitionList[collectionView.tag - 1] objectForKey:@"typeName"];
    NSString *itemName = [[transitionList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    if ([itemName pathExtension]) {
        itemName = [itemName stringByDeletingPathExtension];
    }
    
    _defaultTranstionBtn.selected = NO;
    [self playVideo:NO];
    if (![selectedTransitionName isEqualToString:itemName]) {
        isModifyTranstion = YES;
        if (transitionNoneBtn.selected) {
            transitionNoneBtn.selected = NO;
        }else {
            [transitionList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj[@"data"] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    if ([[obj1 stringByDeletingPathExtension] isEqualToString:selectedTransitionName]) {
                        UICollectionView *prevCollectionView = [transitionScrollView viewWithTag:idx + 1];
                        RDTranstionCollectionViewCell *deselectCell = (RDTranstionCollectionViewCell *)[prevCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx1 inSection:0]];
                        [deselectCell textColor:[UIColor colorWithWhite:1 alpha:0.5]];
                        *stop1 = YES;
                        *stop = YES;
                    }
                }];
            }];
        }
        
        if( currentCell )
        {
            [currentCell  textColor:[UIColor colorWithWhite:1 alpha:0.5]];
            currentCell.customImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
            currentCell = nil;
        }
        
        currentCell = cell;
        [cell textColor:[UIColor whiteColor]];
        cell.customImageView.layer.borderColor = Main_Color.CGColor;
        [self setTransitionWithTypeName:typeName transitionName:itemName atIndex:selectFileIndex isPlay:YES];
    }else if (CMTimeCompare(_videoCoreSDK.currentTime, transitionTimeRange.start) != 0) {
        [_videoCoreSDK seekToTime:transitionTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [self playVideo:YES];
        }];
    }else {
        [self playVideo:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UICollectionView * collectionView = (UICollectionView *)scrollView;
    if( collectionView.contentOffset.x > (collectionView.contentSize.width - collectionView.frame.size.width + KScrollHeight) )
    {
        if(  collectionView.tag <  (transitionList.count)  )
        {
            [self transitionTypeItemBtnAction:[transitionTypeScrollView viewWithTag:collectionView.tag+1]];
        }
    }
    else if(  collectionView.contentOffset.x < - KScrollHeight )
    {
        if( collectionView.tag > 1 )
        {
            [self transitionTypeItemBtnAction:[transitionTypeScrollView viewWithTag:collectionView.tag-1]];
        }
    }
}

- (void)dealloc{
    if( !_backNextEditVideoCancelBlock )
    {
        [_videoCoreSDK stop];
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK.delegate = nil;
        _videoCoreSDK = nil;
    }
    
    [thumbViewItems enumerateObjectsUsingBlock:^(RDThumbImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.thumbIconView.image = nil;
        
    }];
    [thumbViewItems removeAllObjects];
    
    [filtersName removeAllObjects];
    
    [toolItems removeAllObjects];
    [connectToolItems removeAllObjects];
    deletedFileView.image = nil;
    [transitionList removeAllObjects];
    
    if( currentMinCoreSDK )
    {
        [currentMinCoreSDK stop];
        currentMinCoreSDK.delegate = nil;
        currentMinCoreSDK = nil;
    }
    
    if( transitionScrollView )
    {
        [((RDAddItemButton*)transitionNoneBtn)  stopScrollTitle];
        [((RDAddItemButton*)transitionNoneBtn) removeFromSuperview];
        transitionNoneBtn = nil;
        [transitionScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( [obj isKindOfClass:[UICollectionView class]] )
            {
                UICollectionView * collection = (UICollectionView *) obj;
                
                
                [collection.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                   
                    if( [obj  isKindOfClass:[RDTranstionCollectionViewCell class]] )
                    {
                        RDTranstionCollectionViewCell * cell = (RDTranstionCollectionViewCell *)obj;
                        
                        [cell delete];
                    }
                    
                }];
                
                [collection removeFromSuperview];
            }
        }];
    }
    
    
    if( _animationView )
    {
        [animationScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( [obj isKindOfClass:[RDAddItemButton class]] )
            {
                RDAddItemButton * itemButton = (RDAddItemButton *) obj;
                [itemButton stopScrollTitle];
                
                [itemButton.thumbnailIV stopAnimating];
                itemButton.thumbnailIV.yy_imageURL = nil;
                
                [itemButton.thumbnailIV removeFromSuperview];
                itemButton.thumbnailIV = nil;
                
                [itemButton removeFromSuperview];
                itemButton = nil;
            }
        }];
        [animationScrollView removeFromSuperview];
        animationScrollView = nil;
        [animationDurationSlider removeFromSuperview];
        animationDurationSlider = nil;
        [animationDurationLbl removeFromSuperview];
        [animationArray removeAllObjects];
        animationArray = nil;
    }
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj remove];
        obj = nil;
    }];
    [_fileList removeAllObjects];
    _fileList = nil;
    
    NSLog(@"%s",__func__);
}

-(void)setWhetherToModify:(BOOL) isModify
{
    _isModigy = isModify;
}

#pragma mark- 音量
- (void)vloumeAllBtnOnClick:(UIButton *)sender{
    sender.selected = !sender.selected;
}

-( UIView *)volumeView
{
    if(!_volumeView )
    {
        _volumeView = [UIView new];
        _volumeView.frame = CGRectMake(0, kPlayerViewHeight + kPlayerViewOriginX  , kWIDTH, kHEIGHT - kPlayerViewHeight - kPlayerViewOriginX);
        _volumeView.backgroundColor = TOOLBAR_COLOR;
        
        _vloumeAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _vloumeAllBtn.frame = CGRectMake( 5, (0.240*(_volumeView.frame.size.height - kToolbarHeight) - 35)/2.0, 120, 35);
        _vloumeAllBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_vloumeAllBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        [_vloumeAllBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
        _vloumeAllBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_vloumeAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [_vloumeAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [_vloumeAllBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_vloumeAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_vloumeAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_vloumeAllBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [_vloumeAllBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        [_vloumeAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        _vloumeAllBtn.backgroundColor = [UIColor clearColor];
        [_vloumeAllBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
        [_vloumeAllBtn addTarget:self action:@selector(vloumeAllBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        _vloumeAllBtn.selected = NO;
        [_volumeView addSubview:_vloumeAllBtn];
        
         _vloume_navagatio_View = [[UIView alloc] init];
        _vloume_navagatio_View.frame = CGRectMake(_volumeView.frame.size.width*(1.0-0.426)/2.0, (_volumeView.frame.size.height - kToolbarHeight)*0.24  + ( (_volumeView.frame.size.height - kToolbarHeight)*( 1.0 - 0.24 - 0.194 ) - 30 )/4.0, _volumeView.frame.size.width*0.426, (_volumeView.frame.size.height - kToolbarHeight)*0.194);
        _vloume_navagatio_View.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
        _vloume_navagatio_View.layer.borderWidth = 1;
        _vloume_navagatio_View.layer.masksToBounds = YES;
        _vloume_navagatio_View.layer.cornerRadius = 5;
        [_volumeView addSubview:_vloume_navagatio_View];
        
        self.vloumeBtn.hidden = NO;
        self.fadeInOrOutBtn.hidden = NO;
        
        assetVolumeView = [[UIView alloc] initWithFrame:CGRectMake(0, (_volumeView.frame.size.height - kToolbarHeight)*(  0.24 + 0.194 ) + ( (_volumeView.frame.size.height - kToolbarHeight)*( 1.0 - 0.24 - 0.194 ) - 30 )/2.0, kWIDTH, 30)];
        [_volumeView addSubview:assetVolumeView];
        
        UILabel * VolumeLabel = [UILabel new];
        VolumeLabel.frame = CGRectMake(40, 0, 60, 30);
        VolumeLabel.textAlignment = NSTextAlignmentCenter;
        VolumeLabel.backgroundColor = [UIColor clearColor];
        VolumeLabel.font = [UIFont systemFontOfSize:14];
        VolumeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        VolumeLabel.text = RDLocalizedString(@"音量", nil);
        
        [assetVolumeView addSubview:VolumeLabel];
        [assetVolumeView addSubview:self.volumeProgressSlider];
        
        _volumeCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _volumeView.frame.size.height - kToolbarHeight, 44, 44)];
        [_volumeCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_volumeCloseBtn addTarget:self action:@selector(volumeClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_volumeView addSubview:_volumeCloseBtn];
        
        _volumeConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, _volumeView.frame.size.height - kToolbarHeight, 44, 44)];
        [_volumeConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_volumeConfirmBtn addTarget:self action:@selector(volumeConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_volumeView addSubview:_volumeConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, _volumeView.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"音量", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17];
        [_volumeView addSubview:label];
        
        _vloumeCurrentLabel = [[UILabel alloc] init];
        _vloumeCurrentLabel.frame = CGRectMake(0, assetVolumeView.frame.origin.y - 15, 50, 20);
        _vloumeCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _vloumeCurrentLabel.textColor = Main_Color;
        _vloumeCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _volumeProgressSlider.value* volumeMultipleM *100.0;
        _vloumeCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [_volumeView addSubview:_vloumeCurrentLabel];
        _vloumeCurrentLabel.hidden = YES;
        
        [self.view addSubview:_volumeView];
    }
    return _volumeView;
}
- (RDZSlider *)volumeProgressSlider{
    if(!_volumeProgressSlider){
        //        _volumeProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(90,  (_volumeView.frame.size.height - kToolbarHeight)*(  0.24 + 0.194 ) + ( (_volumeView.frame.size.height - kToolbarHeight)*0.449 - 30 )/2.0, kWIDTH - 90 - 50, 30)];
        _volumeProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(100, 0, kWIDTH - 100 - 50, 30)];
        
        _volumeProgressSlider.layer.cornerRadius = 2.0;
        _volumeProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_volumeProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_volumeProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_volumeProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_volumeProgressSlider setValue:0];
        _volumeProgressSlider.alpha = 1.0;
        _volumeProgressSlider.backgroundColor = [UIColor clearColor];
        [_volumeProgressSlider addTarget:self action:@selector(volumeBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_volumeProgressSlider addTarget:self action:@selector(volumeEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_volumeProgressSlider addTarget:self action:@selector(volumeEndScrub) forControlEvents:UIControlEventTouchCancel];
    }
    return _volumeProgressSlider;
}

//音量 滑动进度条
- (void)volumeBeginScrub{
    _vloumeCurrentLabel.hidden = NO;
    [self setVolume];
}

- (void)volumeEndScrub{
    _vloumeCurrentLabel.hidden = YES;
    [self setVolume];
}

-(void)volumeClose_Btn
{
    [RDHelpClass animateViewHidden:_volumeView atUP:NO atBlock:^{
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
        _playButton.frame = transitionPlayButtonRect;
        _playerView.frame = transitionPlayViewRect;
        _videoCoreSDK.frame = _playerView.bounds;
        
        _volumeView.hidden = YES;
        _titleView.hidden = NO;
    }];
    [_volumeProgressSlider setValue:_fileList[selectFileIndex].videoVolume/2.0];
    WeakSelf(self);
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) )
    {
        [scenes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDScene * scene = (RDScene *)obj;
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                if (asset.identifier.length > 0 && asset.type == RDAssetTypeVideo) {
                    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull file, NSUInteger idx1, BOOL * _Nonnull stop1) {
                        if (file.contentURL == asset.url) {
                            StrongSelf(self);
                            [strongSelf.videoCoreSDK setVolume:file.videoVolume identifier:asset.identifier];
                            asset.audioFadeInDuration = file.audioFadeInDuration;
                            asset.audioFadeOutDuration = file.audioFadeOutDuration;
                            *stop1 = YES;
                        }
                    }];
                }
            }];
        }];
    }
}
-(void)volumeConfirm_Btn
{
    [RDHelpClass animateViewHidden:_volumeView atUP:NO atBlock:^{
        _volumeView.hidden = YES;
        _titleView.hidden = NO;
        
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
        _playButton.frame = transitionPlayButtonRect;
        _playerView.frame = transitionPlayViewRect;
        _videoCoreSDK.frame = _playerView.bounds;
    }];
    
    CGFloat current = _volumeProgressSlider.value;
    float percent = current * volumeMultipleM;
    RDZSlider *fadeInSlider = [_volumeFadeView viewWithTag:1];
    RDZSlider *fadeOutSlider = [_volumeFadeView viewWithTag:2];
    if( _vloumeAllBtn.selected )
    {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.videoVolume = percent;
            obj.audioFadeInDuration = fadeInSlider.value;
            obj.audioFadeOutDuration = fadeOutSlider.value;
        }];
        WeakSelf(self);
        if( _vloumeAllBtn.selected )
        {
            if( !scenes && ( scenes.count ==0 ) )
            {
                scenes = [_videoCoreSDK getScenes];
            }
            if( scenes && ( scenes.count > 0 ) )
            {
                [scenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        StrongSelf(self);
                        if (obj.identifier.length > 0 && obj.type == RDAssetTypeVideo) {
                            [strongSelf.videoCoreSDK setVolume:percent identifier:obj.identifier];
                            obj.audioFadeInDuration = fadeInSlider.value;
                            obj.audioFadeOutDuration = fadeOutSlider.value;
                        }
                    }];
                }];
            }
        }
    }else{
        _fileList[selectFileIndex].videoVolume = percent;
        _fileList[selectFileIndex].audioFadeInDuration = fadeInSlider.value;
        _fileList[selectFileIndex].audioFadeOutDuration = fadeOutSlider.value;
    }
}

-(void)setVolume
{
    CGFloat current = _volumeProgressSlider.value;
    float percent = current * volumeMultipleM;
    _vloumeCurrentLabel.frame = CGRectMake(current*_volumeProgressSlider.frame.size.width+_volumeProgressSlider.frame.origin.x - _vloumeCurrentLabel.frame.size.width/2.0, _vloumeCurrentLabel.frame.origin.y, _vloumeCurrentLabel.frame.size.width, _vloumeCurrentLabel.frame.size.height);
    _vloumeCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)(percent*100)];
    WeakSelf(self);
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) ){
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            if (obj.identifier.length > 0 && obj.type == RDAssetTypeVideo) {
                [strongSelf.videoCoreSDK setVolume:percent identifier:obj.identifier];
            }
        }];
    }
    [_videoCoreSDK refreshCurrentFrame];
//    [self playVideo:YES];
}

-(UIButton *) vloumeBtn
{
    if( !_vloumeBtn )
    {
        UIImage *nomarlImage = [RDHelpClass rdImageWithColor:SCREEN_BACKGROUND_COLOR cornerRadius:0];
        UIImage *selectedImage = [RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:0];
        
        _vloumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _vloumeBtn.frame = CGRectMake(0,0, _volumeView.frame.size.width*0.426/2.0, (_volumeView.frame.size.height - kToolbarHeight)*0.194 );
        [_vloumeBtn setTitle:RDLocalizedString(@"音    量", nil) forState:UIControlStateNormal];
        [_vloumeBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [_vloumeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        
        
        [_vloumeBtn setBackgroundImage:nomarlImage forState:UIControlStateNormal];
        [_vloumeBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        
        _vloumeBtn.tag = 0;
        _vloumeBtn.font = [UIFont systemFontOfSize:14];
        [_vloumeBtn addTarget:self action:@selector(setAssetVolume:) forControlEvents:UIControlEventTouchUpInside];
        [_vloume_navagatio_View addSubview:_vloumeBtn];
        
        _vloumeBtn.selected = YES;
    }
    return _vloumeBtn;
}
-(UIButton *) fadeInOrOutBtn
{
    if( !_fadeInOrOutBtn )
    {
//        UIRectCornerTopLeft     = 1 << 0,
//        UIRectCornerTopRight    = 1 << 1,
//        UIRectCornerBottomLeft  = 1 << 2,
//        UIRectCornerBottomRight = 1 << 3,
        
        UIImage *nomarlImage = [RDHelpClass rdImageWithColor:SCREEN_BACKGROUND_COLOR cornerRadius:0];
        UIImage *selectedImage = [RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:0];
        
        _fadeInOrOutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fadeInOrOutBtn.frame = CGRectMake(_volumeView.frame.size.width*0.426/2.0, 0, _volumeView.frame.size.width*0.426/2.0, (_volumeView.frame.size.height - kToolbarHeight)*0.194 );
        [_fadeInOrOutBtn setTitle:RDLocalizedString(@"淡入淡出", nil) forState:UIControlStateNormal];
        [_fadeInOrOutBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [_fadeInOrOutBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        [_vloumeBtn setBackgroundImage:nomarlImage forState:UIControlStateNormal];
        [_vloumeBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        
        _fadeInOrOutBtn.tag = 1;
        _fadeInOrOutBtn.font = [UIFont systemFontOfSize:14];
        [_fadeInOrOutBtn addTarget:self action:@selector(setAssetVolume:) forControlEvents:UIControlEventTouchUpInside];
        [_vloume_navagatio_View addSubview:_fadeInOrOutBtn];
    }
    return _fadeInOrOutBtn;
}

- (UIView *)volumeFadeView {
    if (!_volumeFadeView) {
        _volumeFadeView = [[UIView alloc] initWithFrame:CGRectMake(0, (_volumeView.frame.size.height - kToolbarHeight)*(  0.24 + 0.194 ) + ( (_volumeView.frame.size.height - kToolbarHeight)*( 1.0 - 0.24 - 0.194 ) - 30 )/2.0, kWIDTH, 30)];
        [_volumeView addSubview:_volumeFadeView];
        
        fadeDurationLbel = [[UILabel alloc] initWithFrame:CGRectMake(0, _volumeFadeView.frame.origin.y - 15, 50, 20)];
        fadeDurationLbel.textAlignment = NSTextAlignmentCenter;
        fadeDurationLbel.textColor = Main_Color;
        fadeDurationLbel.font = [UIFont systemFontOfSize:12];
        fadeDurationLbel.hidden = YES;
        [_volumeView addSubview:fadeDurationLbel];
        
        for (int i = 0; i < 2; i++) {
            UILabel *label = [[UILabel alloc] init];
            label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
            label.font = [UIFont systemFontOfSize:14];
            
            RDZSlider *fadeSlider = [[RDZSlider alloc] init];
            fadeSlider.backgroundColor = [UIColor clearColor];
            [fadeSlider setMaximumValue:1];
            [fadeSlider setMinimumValue:0];
            fadeSlider.layer.cornerRadius = 2.0;
            fadeSlider.layer.masksToBounds = YES;
            UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
            image = [image imageWithTintColor];
            [fadeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
            image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
            [fadeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
            [fadeSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
            fadeSlider.tag = i + 1;
            [fadeSlider addTarget:self action:@selector(volumeFadeBeginScrub:) forControlEvents:UIControlEventTouchDown];
            [fadeSlider addTarget:self action:@selector(volumeFadeScrub:) forControlEvents:UIControlEventValueChanged];
            [fadeSlider addTarget:self action:@selector(volumeFadeEndScrub:) forControlEvents:UIControlEventTouchUpInside];
            [fadeSlider addTarget:self action:@selector(volumeFadeEndScrub:) forControlEvents:UIControlEventTouchCancel];
            
            if (i == 0) {
                label.frame = CGRectMake(25, 0, 70, 30);
                label.text = RDLocalizedString(@"淡入时长", nil);
                fadeSlider.frame = CGRectMake(85, 0, kWIDTH/2.0 - 100, 30);
            }else {
                label.frame = CGRectMake(kWIDTH/2.0 + 15, 0, 70, 30);
                label.text = RDLocalizedString(@"淡出时长", nil);
                fadeSlider.frame = CGRectMake(kWIDTH/2.0 + 85, 0, kWIDTH/2.0 - 100, 30);
            }
            [_volumeFadeView addSubview:label];
            [_volumeFadeView addSubview:fadeSlider];
        }
    }
    return _volumeFadeView;
}

- (void)setAssetVolume:(UIButton *)sender {
    sender.selected = YES;
    if (sender.tag == 0) {
        _fadeInOrOutBtn.selected = NO;
        _vloumeBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _vloumeBtn.backgroundColor = [UIColor whiteColor];
        _fadeInOrOutBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _fadeInOrOutBtn.backgroundColor = [UIColor clearColor];
        self.volumeFadeView.hidden = YES;
        assetVolumeView.hidden = NO;
    }else {
        _vloumeBtn.selected = NO;
        _vloumeBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _vloumeBtn.backgroundColor = [UIColor clearColor];
        _fadeInOrOutBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _fadeInOrOutBtn.backgroundColor = [UIColor whiteColor];
        assetVolumeView.hidden = YES;
        self.volumeFadeView.hidden = NO;
        
        VVAsset *asset = [scenes[selectFileIndex].vvAsset firstObject];
        RDZSlider *fadeInSlider = [_volumeFadeView viewWithTag:1];
        fadeInSlider.value = asset.audioFadeInDuration;
        fadeInSlider.maximumValue = CMTimeGetSeconds(asset.timeRange.duration)/2.0;
        RDZSlider *fadeOutSlider = [_volumeFadeView viewWithTag:2];
        fadeOutSlider.value = asset.audioFadeOutDuration;
        fadeOutSlider.maximumValue = fadeInSlider.maximumValue;
    }
}

- (void)volumeFadeBeginScrub:(RDZSlider *)slider {
    if (_videoCoreSDK.isPlaying) {
        [self playVideo:NO];
    }
    CGRect rect = [slider thumbRectForBounds:CGRectMake(0, 0, slider.currentThumbImage.size.width, slider.currentThumbImage.size.height) trackRect:slider.frame value:slider.value];
    fadeDurationLbel.center = CGPointMake(rect.origin.x + slider.currentThumbImage.size.width/2.0, fadeDurationLbel.center.y);
    fadeDurationLbel.text = [NSString stringWithFormat:@"%.1fs",slider.value];
    fadeDurationLbel.hidden = NO;
}

- (void)volumeFadeScrub:(RDZSlider *)slider {
    CGRect rect = [slider thumbRectForBounds:CGRectMake(0, 0, slider.currentThumbImage.size.width, slider.currentThumbImage.size.height) trackRect:slider.frame value:slider.value];
    fadeDurationLbel.center = CGPointMake(rect.origin.x + slider.currentThumbImage.size.width/2.0, fadeDurationLbel.center.y);
    fadeDurationLbel.text = [NSString stringWithFormat:@"%.1fs",slider.value];
}

- (void)volumeFadeEndScrub:(RDZSlider *)slider {
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) ){
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0 && obj.type == RDAssetTypeVideo) {
                if (slider.tag == 1) {
                    obj.audioFadeInDuration = slider.value;
                }else {
                    obj.audioFadeOutDuration = slider.value;
                }
            }
        }];
    }
    fadeDurationLbel.hidden = YES;
}

-(void)mode_Btn:(UIButton *) btn
{
    if( btn.tag == 0 )
    {
        btn.selected = YES;
        _fadeInOrOutBtn.selected = NO;
        _fadeInOrOutBtn.layer.borderColor =  [UIColor whiteColor].CGColor;
        _fadeInOrOutBtn.backgroundColor = [UIColor clearColor];
    }
    else if( btn.tag == 1 )
    {
        _vloumeBtn.layer.borderColor =  [UIColor whiteColor].CGColor;
        _vloumeBtn.backgroundColor = [UIColor clearColor];
    }
}
#pragma mark- 透明度
-(void)transparencyClose_Btn
{
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) ){
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0 ) {
                obj.alpha = _fileList[selectFileIndex].backgroundAlpha;
            }
        }];
    }
    [_videoCoreSDK refreshCurrentFrame];
    

    
    [RDHelpClass animateViewHidden:_transparencyView atUP:NO atBlock:^{
        _transparencyView.hidden = YES;
        [_transparencyBtn removeFromSuperview];
        _transparencyBtn = nil;
        [_transparencyCurrentLabel removeFromSuperview];
        _transparencyCurrentLabel = nil;
        [_transparencyProgressSlider removeFromSuperview];
        _transparencyProgressSlider = nil;
        [_transparencyCloseBtn removeFromSuperview];
        _transparencyCloseBtn = nil;
        [_transparencyConfirmBtn removeFromSuperview];
        _transparencyConfirmBtn = nil;
        [_transparencyView removeFromSuperview];
        _transparencyView = nil;
        
        _titleView.hidden = NO;
        _playButton.hidden = NO;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
    }];
}
-(void)transparencyConfirm_Btn
{
    _fileList[selectFileIndex].backgroundAlpha = _transparencyProgressSlider.value;
    
    if( _transparencyBtn.selected )
    {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            obj.backgroundAlpha = _transparencyProgressSlider.value;
            
        }];
        
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                obj.alpha = _transparencyProgressSlider.value;
                
            }];
        }];
        
        [_videoCoreSDK refreshCurrentFrame];
    }
    [RDHelpClass animateViewHidden:_transparencyView atUP:NO atBlock:^{
        _transparencyView.hidden = YES;
        [_transparencyBtn removeFromSuperview];
        _transparencyBtn = nil;
        [_transparencyCurrentLabel removeFromSuperview];
        _transparencyCurrentLabel = nil;
        [_transparencyProgressSlider removeFromSuperview];
        _transparencyProgressSlider = nil;
        [_transparencyCloseBtn removeFromSuperview];
        _transparencyCloseBtn = nil;
        [_transparencyConfirmBtn removeFromSuperview];
        _transparencyConfirmBtn = nil;
        [_transparencyView removeFromSuperview];
        _transparencyView = nil;
        
        _titleView.hidden = NO;
        _playButton.hidden = NO;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
    }];
}
-(UIView *)transparencyView
{
    if( !_transparencyView )
    {
        _transparencyView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewHeight + kPlayerViewOriginX  , kWIDTH, kHEIGHT - kPlayerViewHeight - kPlayerViewOriginX)];
        _transparencyView.backgroundColor = TOOLBAR_COLOR;
        
        [self.view addSubview:_transparencyView];
        [_transparencyView addSubview:self.transparencyBtn];
         
        self.transparencyProgressSlider.hidden = NO;
        
        _transparencyCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _transparencyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_transparencyCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_transparencyCloseBtn addTarget:self action:@selector(transparencyClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyView addSubview:_transparencyCloseBtn];
        
        _transparencyConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, _transparencyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_transparencyConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_transparencyConfirmBtn addTarget:self action:@selector(transparencyConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyView addSubview:_transparencyConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, _transparencyView.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"透明度", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        [_transparencyView addSubview:label];
    }
    return _transparencyView;
}

- (RDZSlider *)transparencyProgressSlider{
    if(!_transparencyProgressSlider){
        
        
        _transparencyProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, 0.240*(_transparencyView.frame.size.height - kToolbarHeight) + ( ( (_transparencyView.frame.size.height - kToolbarHeight)*0.760 ) - 30 )/2.0  , kWIDTH - 50 - 50, 30)];
        
        _transparencyCurrentLabel = [[UILabel alloc] init];
        _transparencyCurrentLabel.frame = CGRectMake(0, _transparencyProgressSlider.frame.origin.y - 25, 50, 20);
        _transparencyCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _transparencyCurrentLabel.textColor = Main_Color;
        _transparencyCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _transparencyProgressSlider.value* volumeMultipleM *100.0;
        _transparencyCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [_transparencyView addSubview:_transparencyCurrentLabel];
        _transparencyCurrentLabel.hidden = YES;

        
        _transparencyProgressSlider.layer.cornerRadius = 2.0;
        _transparencyProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_transparencyProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_transparencyProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_transparencyProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_transparencyProgressSlider setValue:0];
        _transparencyProgressSlider.alpha = 1.0;
        _transparencyProgressSlider.backgroundColor = [UIColor clearColor];
        [_transparencyProgressSlider addTarget:self action:@selector(transparencyBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_transparencyProgressSlider addTarget:self action:@selector(transparencyEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyProgressSlider addTarget:self action:@selector(transparencyEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_transparencyView addSubview:_transparencyProgressSlider];
    }
    return _transparencyProgressSlider;
}
//透明度 滑动进度条
- (void)transparencyBeginScrub{
    _transparencyCurrentLabel.hidden = NO;
    [self setTransparency];
}

- (void)transparencyEndScrub{
    _transparencyCurrentLabel.hidden = YES;
    [self setTransparency];
}

- (void)setTransparency
{
    CGFloat current = _transparencyProgressSlider.value;
    float percent = current * 100;
    _transparencyCurrentLabel.frame = CGRectMake(current*_transparencyProgressSlider.frame.size.width+_transparencyProgressSlider.frame.origin.x - _transparencyCurrentLabel.frame.size.width/2.0, _transparencyCurrentLabel.frame.origin.y, _transparencyCurrentLabel.frame.size.width, _transparencyCurrentLabel.frame.size.height);
    _transparencyCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)percent];
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) ){
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0) {
                obj.alpha = current;
            }
        }];
    }
    [_videoCoreSDK refreshCurrentFrame];
}

-(UIButton*)transparencyBtn
{
    if( !_transparencyBtn )
    {
        _transparencyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _transparencyBtn.frame = CGRectMake( 0, (0.240*(_transparencyView.frame.size.height - kToolbarHeight) - 35)/2.0, 120, 35);
        _transparencyBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_transparencyBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        [_transparencyBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
        _transparencyBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_transparencyBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [_transparencyBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [_transparencyBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_transparencyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_transparencyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_transparencyBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [_transparencyBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        [_transparencyBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        _transparencyBtn.backgroundColor = [UIColor clearColor];
        [_transparencyBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
        [_transparencyBtn addTarget:self action:@selector(useToAllTranstionBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        _transparencyBtn.selected = NO;
        [_transparencyView addSubview:_transparencyBtn];
    }
    return _transparencyBtn;
}

#pragma mark- 旋转 上下翻转 左右翻转
-(void)Crop_Rotate
{
    float ratio=1;
    
    switch (_fileList[selectFileIndex].fileCropModeType) {
           case kCropTypeFreedom:
           case kCropType1v1:
               ratio=1;
               break;
           case kCropType16v9:
               ratio=16.0/9.0;
               break;
           case kCropType9v16:
               ratio=9.0/16.0;
               break;
           case kCropType4v3:
               ratio=4.0/3.0;
               break;
           case kCropType3v4:
               ratio=3.0/4.0;
               break;
           default:
               break;
       }
}

#pragma mark - 动画

-(void)defaultAnimationBtnOnClick:(UIButton *) sender
{
    [self playVideo:NO];
    sender.selected = !sender.selected;
    if (sender.selected) {
    
        NSInteger index = arc4random()%(animationArray.count) + 2;
    
        UIButton * btn = [animationScrollView viewWithTag: index];
        [self animationTypeBtnAction:btn];
        
        float x = btn.frame.origin.x;
        
        float fRemain =  animationScrollView.contentSize.width - animationScrollView.frame.size.width;
        
        if(  fRemain > x )
        {
            animationScrollView.contentOffset = CGPointMake(x - 10, 0);
        }
        else
        {
            animationScrollView.contentOffset = CGPointMake(fRemain, 0);
        }
    }
    else
        return;
}

- (void)animationTypeBtnAction:(UIButton *)sender {
    
    [self playVideo:NO];
    
    if (selectedAnimationIndex != sender.tag) {
        
        RDAddItemButton *prevBtn = [animationScrollView viewWithTag:selectedAnimationIndex];
        if( prevBtn )
        {
            prevBtn.selected = NO;
            prevBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
            [prevBtn   textColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        }
        sender.selected = YES;
        selectedAnimationIndex = sender.tag;
        
        RDAddItemButton * btn = (RDAddItemButton *) sender;
        btn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
        [btn  textColor:[UIColor whiteColor]];
        
        
        if (sender.tag == 1) {
            animationDurationSlider.enabled = FALSE;
//            animationTime = kCMTimeRangeZero;
        }
        else{
            animationDurationSlider.enabled = true;
            
            CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex];
                   
            float time = CMTimeGetSeconds(timeRange.start);
            animationTime = CMTimeRangeMake(CMTimeMakeWithSeconds(time , TIMESCALE), CMTimeMakeWithSeconds(animationDurationSlider.value, TIMESCALE));
        }
        
//        if (sender.tag == 1) {
//            animationDurationView.hidden = YES;
//        }else {
//            animationDurationView.hidden = NO;
//        }
        
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (sender.tag == 1) {
                obj.animate = nil;
            }else {
                [RDHelpClass setAssetAnimationArray:obj name:animationArray[sender.tag - 2] duration:animationDurationSlider.value center:CGPointMake(_fileList[selectFileIndex].rectInScene.origin.x + _fileList[selectFileIndex].rectInScene.size.width/2.0, _fileList[selectFileIndex].rectInScene.origin.y + _fileList[selectFileIndex].rectInScene.size.height/2.0) scale:_fileList[selectFileIndex].rectInScale];
            }
        }];
        
    }
    
    if (sender.tag != 1) {
        if (CMTimeCompare(_videoCoreSDK.currentTime, animationTime.start) != 0) {
            [_videoCoreSDK seekToTime:animationTime.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                [self playVideo:YES];
            }];
        }else {
            [self playVideo:YES];
        }
    }
}

- (void)animationBeginScrub:(UISlider *)slider {
    [self playVideo:NO];
//    animationDurationLbl.hidden = NO;
    animationDurationLbl.text = [NSString stringWithFormat:@"%.1f秒",slider.value];
}

- (void)animationChangeScrub:(UISlider *)slider {
//    animationDurationLbl.hidden = NO;
    animationDurationLbl.text = [NSString stringWithFormat:@"%.1f秒",slider.value];
}

- (void)animationEndScrub:(UISlider *)slider {
//    animationDurationLbl.hidden = YES;
    animationTime = CMTimeRangeMake(animationTime.start, CMTimeMakeWithSeconds(animationDurationSlider.value, TIMESCALE));
    
    [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [RDHelpClass setAssetAnimationArray:obj name:animationArray[selectedAnimationIndex - 2] duration:animationDurationSlider.value center:CGPointMake(_fileList[selectFileIndex].rectInScene.origin.x + _fileList[selectFileIndex].rectInScene.size.width/2.0, _fileList[selectFileIndex].rectInScene.origin.y + _fileList[selectFileIndex].rectInScene.size.height/2.0) scale:_fileList[selectFileIndex].rectInScale];
    }];
    if (CMTimeCompare(_videoCoreSDK.currentTime, animationTime.start) != 0) {
        [_videoCoreSDK seekToTime:animationTime.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [self playVideo:YES];
        }];
    }else {
        [self playVideo:YES];
    }
}

#pragma mark- 美颜
-(void)beautyClose_Btn
{
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) ){
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0 ) {
                
                obj.beautyBlurIntensity = _fileList[selectFileIndex].beautyValue;
//                obj.beautyBrightIntensity = _fileList[selectFileIndex].beautyValue;
//                obj.beautyToneIntensity = _fileList[selectFileIndex].beautyValue;
            }
        }];
    }
    [_videoCoreSDK refreshCurrentFrame];
    

    
    [RDHelpClass animateViewHidden:_beautyView atUP:NO atBlock:^{
        _beautyView.hidden = YES;
        [_beautyBtn removeFromSuperview];
        _beautyBtn = nil;
        [_beautyCurrentLabel removeFromSuperview];
        _beautyCurrentLabel = nil;
        [_beautyProgressSlider removeFromSuperview];
        _beautyProgressSlider = nil;
        [_beautyCloseBtn removeFromSuperview];
        _beautyCloseBtn = nil;
        [_beautyConfirmBtn removeFromSuperview];
        _beautyConfirmBtn = nil;
        [_beautyView removeFromSuperview];
        _beautyView = nil;
        
        _titleView.hidden = NO;
        _playButton.hidden = NO;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
    }];
}
-(void)beautyConfirm_Btn
{
    _fileList[selectFileIndex].beautyValue = _beautyProgressSlider.value;
    
    if( _beautyBtn.selected )
    {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            obj.beautyValue = _beautyProgressSlider.value;
            
        }];
        
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                obj.beautyBlurIntensity = _beautyProgressSlider.value;
//                obj.beautyBrightIntensity = _beautyProgressSlider.value;
//                obj.beautyToneIntensity = _beautyProgressSlider.value;
                
            }];
        }];
        
        [_videoCoreSDK refreshCurrentFrame];
    }
    
    [RDHelpClass animateViewHidden:_beautyView atUP:NO atBlock:^{
        _beautyView.hidden = YES;
        [_beautyBtn removeFromSuperview];
        _beautyBtn = nil;
        [_beautyCurrentLabel removeFromSuperview];
        _beautyCurrentLabel = nil;
        [_beautyProgressSlider removeFromSuperview];
        _beautyProgressSlider = nil;
        [_beautyCloseBtn removeFromSuperview];
        _beautyCloseBtn = nil;
        [_beautyConfirmBtn removeFromSuperview];
        _beautyConfirmBtn = nil;
        [_beautyView removeFromSuperview];
        _beautyView = nil;
        
        _titleView.hidden = NO;
        _playButton.hidden = NO;
        _videoProgressSlider.hidden = NO;
        _durationLabel.hidden  = NO;
        _currentLabel.hidden = NO;
    }];
}
-(UIView *)beautyView
{
    if( !_beautyView )
    {
        _beautyView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewHeight + kPlayerViewOriginX  , kWIDTH, kHEIGHT - kPlayerViewHeight - kPlayerViewOriginX)];
        _beautyView.backgroundColor = TOOLBAR_COLOR;
        
        [self.view addSubview:_beautyView];
        [_beautyView addSubview:self.beautyBtn];
         
        self.beautyProgressSlider.hidden = NO;
        
        _beautyCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, _beautyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_beautyCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_beautyCloseBtn addTarget:self action:@selector(beautyClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_beautyView addSubview:_beautyCloseBtn];
        
        _beautyConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, _beautyView.frame.size.height - kToolbarHeight, 44, 44)];
        [_beautyConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_beautyConfirmBtn addTarget:self action:@selector(beautyConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_beautyView addSubview:_beautyConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, _beautyView.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"美颜", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        [_beautyView addSubview:label];
    }
    return _beautyView;
}

- (RDZSlider *)beautyProgressSlider{
    if(!_beautyProgressSlider){
        
        
        _beautyProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, 0.240*(_beautyView.frame.size.height - kToolbarHeight) + ( ( (_beautyView.frame.size.height - kToolbarHeight)*0.760 ) - 30 )/2.0  , kWIDTH - 50 - 50, 30)];
        
        _beautyCurrentLabel = [[UILabel alloc] init];
        _beautyCurrentLabel.frame = CGRectMake(0, _beautyProgressSlider.frame.origin.y - 25, 50, 20);
        _beautyCurrentLabel.textAlignment = NSTextAlignmentCenter;
        _beautyCurrentLabel.textColor = Main_Color;
        _beautyCurrentLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = _beautyProgressSlider.value *100.0;
        _beautyCurrentLabel.text = [NSString stringWithFormat:@"%d", (int)percent];
        [_beautyView addSubview:_beautyCurrentLabel];
        _beautyCurrentLabel.hidden = YES;

        
        _beautyProgressSlider.layer.cornerRadius = 2.0;
        _beautyProgressSlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_beautyProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_beautyProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_beautyProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_beautyProgressSlider setValue:0];
        _beautyProgressSlider.alpha = 1.0;
        _beautyProgressSlider.backgroundColor = [UIColor clearColor];
        [_beautyProgressSlider addTarget:self action:@selector(beautyBeginScrub) forControlEvents:UIControlEventValueChanged];
        [_beautyProgressSlider addTarget:self action:@selector(beautyEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_beautyProgressSlider addTarget:self action:@selector(beautyEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_beautyView addSubview:_beautyProgressSlider];
    }
    return _beautyProgressSlider;
}
//透明度 滑动进度条
- (void)beautyBeginScrub{
    _beautyCurrentLabel.hidden = NO;
    [self setBeauty];
}

- (void)beautyEndScrub{
    _beautyCurrentLabel.hidden = YES;
    [self setBeauty];
}

- (void)setBeauty
{
    CGFloat current = _beautyProgressSlider.value;
    float percent = current * 100;
    _beautyCurrentLabel.frame = CGRectMake(current*_beautyProgressSlider.frame.size.width+_beautyProgressSlider.frame.origin.x - _beautyCurrentLabel.frame.size.width/2.0, _beautyCurrentLabel.frame.origin.y, _beautyCurrentLabel.frame.size.width, _beautyCurrentLabel.frame.size.height);
    _beautyCurrentLabel.text = [NSString stringWithFormat:@"%d",(int)percent];
    if( !scenes && ( scenes.count ==0 ) )
    {
        scenes = [_videoCoreSDK getScenes];
    }
    if( scenes && ( scenes.count > 0 ) ){
        [scenes[selectFileIndex].vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0) {
                
                obj.beautyBlurIntensity = current;
//                obj.beautyBrightIntensity = current;
//                obj.beautyToneIntensity = current;
            }
        }];
    }
    [_videoCoreSDK refreshCurrentFrame];
}

-(UIButton*)beautyBtn
{
    if( !_beautyBtn )
    {
        _beautyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _beautyBtn.frame = CGRectMake( 0, (0.240*(_beautyView.frame.size.height - kToolbarHeight) - 35)/2.0, 120, 35);
        _beautyBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_beautyBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        [_beautyBtn setTitle: RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
        _beautyBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_beautyBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [_beautyBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [_beautyBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_beautyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_beautyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_beautyBtn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [_beautyBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        [_beautyBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        _beautyBtn.backgroundColor = [UIColor clearColor];
        [_beautyBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
        [_beautyBtn addTarget:self action:@selector(useToAllTranstionBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        _beautyBtn.selected = NO;
        [_beautyView addSubview:_beautyBtn];
    }
    return _beautyBtn;
}

@end
