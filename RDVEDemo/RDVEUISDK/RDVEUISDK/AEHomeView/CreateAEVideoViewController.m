//
//  CreateAEVideoViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/10/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "CreateAEVideoViewController.h"
#import "RDNavigationViewController.h"
#import "RD_RDReachabilityLexiu.h"
#import "RDATMHud.h"
#import "RDVECore.h"
#import "RDZSlider.h"
#import "RDMoveProgress.h"
#import "RDMainViewController.h"
#import "CropViewController.h"
#import "RDTrimVideoViewController.h"
#import "RDExportProgressView.h"
#import "CustomButton.h"
#import "TextViewController.h"
#import "RDLocalMusicViewController.h"

@interface CreateAEVideoViewController ()<RDVECoreDelegate, RDThumbImageViewDelegate, UIAlertViewDelegate, TextViewControllerDelegate>
{
    int                  fps;
    RDATMHud            *hud;
    RDVECore            *rdPlayer;
    BOOL                 isResignActive;
    BOOL                 isContinueExport;
    UIView              *playerView;
    UIButton            *playBtn;
    UIView              *playerToolBar;
    UILabel             *currentTimeLabel;
    UILabel             *durationLabel;
    RDZSlider           *videoProgressSlider;
    RDMoveProgress      *playProgress;
    UIScrollView        *sourceScrollView;
    NSInteger            selectedIndex;
    NSMutableArray      <RDFile *>*fileList;
    NSInteger            selectedTextIndex;
    UIAlertView         *commonAlertView;
    BOOL                 _idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    NSMutableArray      *textInfoArray;
    NSMutableArray      <RDAESourceInfo*>*videoImageSourceArray;
    BOOL                 isNeedPrepare;
    NSMutableArray      *textArray;
    UIScrollView        *scrollView;
    UILabel             *musicVolumeLbl;
    RDZSlider           *musicVolumeSlider;
    UILabel             *replaceMusicLbl;
    UIButton            *useOriginalMusicBtn;
    RDMusic             *selectedMusic;
    NSURL               *defaultMusicURL;
    
    //滤镜
    NSMutableArray  *globalFilters;
}

@property (nonatomic, assign) CGSize exportSize;

@property (nonatomic, strong) RDExportProgressView *exportProgressView;

@end

@implementation CreateAEVideoViewController

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //工具栏 是否半透明
    self.navigationController.navigationBar.translucent = iPhone4s;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);    
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.title = _templateName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [rdPlayer stop];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(_exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself cancelExportBlock];
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isNeedPrepare) {
        [rdPlayer prepare];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:_jsonPath];
    NSMutableDictionary *jsonDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    _exportSize = CGSizeMake([jsonDic[@"w"] floatValue], [jsonDic[@"h"] floatValue]);
    if (_repeatCount == 0) {
        _repeatCount = 1;
    }
    [self initNavigationItem];
    hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:hud.view];
    [self initScrollView];
    [self initPlayerView];
    [self initPlayer];
    durationLabel.text = [RDHelpClass timeToStringNoSecFormat:rdPlayer.duration];
    [self initBottomView];
    
    playProgress.hidden = YES;
    globalFilters = [NSMutableArray array];
    
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
    UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
   NSMutableArray *filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
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

- (void)initNavigationItem{
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [leftBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    leftBtn.titleLabel.textAlignment=NSTextAlignmentRight;
    [leftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [leftBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        spaceItem.width=-9;
    }else{
        spaceItem.width=0;
    }
    
    UIBarButtonItem *leftButton= [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    leftBtn.exclusiveTouch=YES;
    leftButton.tag = 1;
    self.navigationItem.leftBarButtonItems = @[spaceItem,leftButton];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setFrame:CGRectMake(0, 0, 64, 44)];
    [rightBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [rightBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *spaceItem_right = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem_right.width = -7;
    
    UIBarButtonItem *rightButton= [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    rightBtn.exclusiveTouch=YES;
    rightButton.tag = 2;
    self.navigationItem.rightBarButtonItems = @[spaceItem_right,rightButton];
}

- (void)initScrollView {
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:scrollView];
}

- (void)initPlayerView {
    CGRect playerFrame;
    if (_exportSize.width >= _exportSize.height) {
        playerFrame = CGRectMake(0, 0, kWIDTH, kWIDTH / (_exportSize.width / _exportSize.height) + 50);
    }else {
        playerFrame = CGRectMake(kWIDTH/4.0, 0, kWIDTH/2.0, kWIDTH/2.0 / (_exportSize.width / _exportSize.height));
    }
    playerView = [[UIView alloc] initWithFrame:playerFrame];
    [scrollView addSubview:playerView];
    
    playBtn = [UIButton new];
    playBtn.backgroundColor = [UIColor clearColor];
    playBtn.frame = CGRectMake((playerView.frame.size.width - 56)/2.0, (playerView.frame.size.height - 56)/2.0, 56, 56);
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    [playerView addSubview:playBtn];
    
    playerToolBar = [UIView new];
    playerToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    playerToolBar.frame = CGRectMake(0, playerView.frame.size.height - 44, kWIDTH, 44);
    playerToolBar.hidden = YES;
    [scrollView addSubview:playerToolBar];
    
    durationLabel = [[UILabel alloc] init];
    durationLabel.frame = CGRectMake(playerToolBar.frame.size.width - 45, (playerToolBar.frame.size.height - 20)/2.0, 40, 20);
    durationLabel.textAlignment = NSTextAlignmentRight;
    durationLabel.textColor = UIColorFromRGB(0xffffff);
    durationLabel.font = [UIFont systemFontOfSize:12];
    [playerToolBar addSubview:durationLabel];
    
    currentTimeLabel = [[UILabel alloc] init];
    currentTimeLabel.frame = CGRectMake(5, (playerToolBar.frame.size.height - 20)/2.0, 40, 20);
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:0.0];
    currentTimeLabel.textAlignment = NSTextAlignmentLeft;
    currentTimeLabel.textColor = UIColorFromRGB(0xffffff);
    currentTimeLabel.font = [UIFont systemFontOfSize:12];
    [playerToolBar addSubview:currentTimeLabel];
    
    videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(40, (playerToolBar.frame.size.height - 30)/2.0, playerToolBar.frame.size.width - 80, 30)];
    videoProgressSlider.isAETemplate = TRUE;
    videoProgressSlider.backgroundColor = [UIColor clearColor];
    [videoProgressSlider setMaximumValue:1];
    [videoProgressSlider setMinimumValue:0];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
    image = [image imageWithTintColor];
    [videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
    videoProgressSlider.layer.cornerRadius = 2.0;
    videoProgressSlider.layer.masksToBounds = YES;
    [videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
    [videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_AE轨道球_"] forState:UIControlStateNormal];
    [videoProgressSlider setValue:0];
    videoProgressSlider.alpha = 1.0;
    
    [videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
    [videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
    [videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    [playerToolBar addSubview:videoProgressSlider];
    
    playProgress = [[RDMoveProgress alloc] initWithFrame:CGRectMake(0, playerView.frame.size.height - 5,  playerView.frame.size.width, 5)];
    [playProgress setProgress:0 animated:NO];
    [playProgress setTrackTintColor:Main_Color];
    [playProgress setBackgroundColor:UIColorFromRGB(0x888888)];
    [playerView addSubview:playProgress];
}

- (void)getFileListWithTempFiles:(NSMutableArray *)tempFiles themeDic:(NSMutableDictionary *)themeDic {
    NSMutableArray *tempTextInfoArray = [[[themeDic objectForKey:@"textimg"] objectForKey:@"text"] mutableCopy];
    NSArray *aeSourceInfo = [rdPlayer getAESourceInfoWithJosnPath:_jsonPath];
    [aeSourceInfo enumerateObjectsUsingBlock:^(RDAESourceInfo *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == RDAESourceType_ReplaceableText) {
            __block NSDictionary *textDic;
            [tempTextInfoArray enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj.name isEqualToString:obj1[@"name"]]) {
                    [textInfoArray addObject:obj1];
                    [tempTextInfoArray removeObject:obj1];
                    textDic = obj1;
                    *stop1 = YES;
                }
            }];
            RDJsonText *textSource = [RDJsonText new];
            textSource.size = CGSizeMake([textDic[@"width"] floatValue], [textDic[@"height"] floatValue]);
            textSource.text = textDic[@"textContent"];
            textSource.fontName = textDic[@"textFont"];
            NSString *fontPath = textDic[@"fontSrc"];
            if (fontPath.length > 0) {
                textSource.fontName = [RDHelpClass customFontWithPath:[[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fontPath] fontName:nil];
            }
            if ([textDic[@"alignment"] isEqualToString:@"left"]) {
                textSource.textAlignment = RDCaptionTextAlignmentLeft;
            }else if ([textDic[@"alignment"] isEqualToString:@"right"]) {
                textSource.textAlignment = RDCaptionTextAlignmentRight;
            }else {
                textSource.textAlignment = RDCaptionTextAlignmentCenter;
            }
            NSArray *textColors = textDic[@"textColor"];
            float r = [textColors[0] floatValue]/255.0;
            float g = [textColors[1] floatValue]/255.0;
            float b = [textColors[2] floatValue]/255.0;
            textSource.textColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
            textSource.alpha = [textDic[@"alpha"] floatValue] == 0 ? 1 : [textDic[@"alpha"] floatValue];
            textSource.isVerticalText = [textDic[@"vertical"] boolValue];
            textSource.fontSize = [textDic[@"fontSize"] floatValue];
            NSArray *textPadding = textDic[@"textPadding"];//左上右下
            textSource.edgeInsets = UIEdgeInsetsMake([textPadding[1] floatValue], [textPadding[0] floatValue], [textPadding[3] floatValue], [textPadding[2] floatValue]);
            textSource.isBold = [textDic[@"bold"] boolValue];
            textSource.isItalic = [textDic[@"italic"] boolValue];
            
            textColors = textDic[@"strokeColor"];
            r = [textColors[0] floatValue]/255.0;
            g = [textColors[1] floatValue]/255.0;
            b = [textColors[2] floatValue]/255.0;
            textSource.strokeColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
            textSource.strokeWidth = [textDic[@"strokeWidth"] floatValue];
            
            textColors = textDic[@"shadowColor"];
            r = [textColors[0] floatValue]/255.0;
            g = [textColors[1] floatValue]/255.0;
            b = [textColors[2] floatValue]/255.0;
            textSource.isShadow = [textDic[@"shadow"] boolValue];
            textSource.shadowColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
            
            [textArray addObject:textSource];
        }else if (obj.type == RDAESourceType_ReplaceablePic) {
            __block BOOL hasPic = NO;
            [tempFiles enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.fileType == kFILEIMAGE || obj.fileType == kTEXTTITLE) {
                    hasPic = YES;
                    obj.fileCropModeType = kCropTypeFixedRatio;
                    [fileList addObject:obj];
                    [tempFiles removeObjectAtIndex:idx];
                    *stop = YES;
                }
            }];
            if (!hasPic) {
                RDFile * file = [RDFile new];
                file.fileType = kFILEIMAGE;
                file.fileCropModeType = kCropTypeFixedRatio;
                file.crop = CGRectMake(0, 0, 1, 1);
                [fileList addObject:file];
            }
        }else if (obj.type == RDAESourceType_ReplaceableVideoOrPic) {
            __block BOOL hasVideo = NO;
            if (_isAllVideoOrPic) {
                [tempFiles enumerateObjectsUsingBlock:^(RDFile *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    hasVideo = YES;
                    obj.fileCropModeType = kCropTypeFixedRatio;
                    [fileList addObject:obj];
                    [tempFiles removeObjectAtIndex:idx];
                    *stop = YES;
                }];
            }else {
                //先添加视频
                [tempFiles enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.fileType == kFILEVIDEO) {
                        hasVideo = YES;
                        obj.fileCropModeType = kCropTypeFixedRatio;
                        [fileList addObject:obj];
                        [tempFiles removeObjectAtIndex:idx];
                        *stop = YES;
                    }
                }];
                //如果没有视频，再添加图片
                if (!hasVideo) {
                    [tempFiles enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.fileType == kFILEIMAGE || obj.fileType == kTEXTTITLE) {
                            hasVideo = YES;
                            obj.fileCropModeType = kCropTypeFixedRatio;
                            [fileList addObject:obj];
                            [tempFiles removeObjectAtIndex:idx];
                            *stop = YES;
                        }
                    }];
                }
            }
            if (!hasVideo) {
                RDFile * file = [RDFile new];
                file.fileType = kFILEIMAGE;
                file.fileCropModeType = kCropTypeFixedRatio;
                file.crop = CGRectMake(0, 0, 1, 1);
                [fileList addObject:file];
            }
        }
    }];
    [tempTextInfoArray removeAllObjects];
    tempTextInfoArray = nil;
}

-(void)corpInitPlayer
{
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    [rdPlayer.view removeFromSuperview];
    for (int i = 0; i < fileList.count; i++) {
        _files[i] = [fileList[i] copy];
    }
    rdPlayer = nil;
    fileList = nil;
    textArray = nil;
    textInfoArray = nil;
    [self initPlayer];
    [RDSVProgressHUD dismiss];
}

- (void)initPlayer {
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:_jsonPath];
    NSMutableDictionary *themeDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    NSDictionary *setting = [themeDic objectForKey:@"rdsetting"];
    if (setting && [setting[@"swDecode"] boolValue]) {
        //帧率四舍五入
        fps = roundf([themeDic[@"fr"] floatValue]);
    }
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:_exportSize
                                            fps:(fps > 0 ? fps : kEXPORTFPS)
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initSDKError:%@", error.localizedDescription);
                                     }];
    rdPlayer.frame = playerView.bounds;
    rdPlayer.enableAudioEffect = YES;
    rdPlayer.delegate = self;
    [playerView insertSubview:rdPlayer.view atIndex:0];
    
    NSString *path = [_jsonPath stringByDeletingLastPathComponent];
    fileList = [NSMutableArray array];
    textArray = [NSMutableArray array];
    textInfoArray = [NSMutableArray array];
    
    if (_files.count == 0) {
        [self getFileListWithTempFiles:nil themeDic:themeDic];
    }else {
        NSMutableArray *tempFiles = [_files mutableCopy];
        while (tempFiles.count > 0) {
            [self getFileListWithTempFiles:tempFiles themeDic:themeDic];
        }
    }
    
    NSMutableArray *backgroundImageArr = [NSMutableArray array];
    NSMutableArray *replaceableImageArr = [NSMutableArray array];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_jsonPath stringByDeletingLastPathComponent] error:nil];
    float ver = [themeDic[@"ver"] floatValue];
    for (NSString *fileName in files) {
        if ([RDHelpClass isImageUrl:[NSURL fileURLWithPath:[[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName]]]) {
            if (![fileName hasPrefix:@"ReplaceableText"]) {
                if (ver == 1.0) {//不可替换图片命名以background开头
                    if ([fileName hasPrefix:@"background"]) {
                        [backgroundImageArr addObject:fileName];
                    }else {
                        [replaceableImageArr addObject:fileName];
                    }
                }else {//除了Replaceable开头的图片，其它图片都作为不可替换图片
                    if ([fileName hasPrefix:@"Replaceable"]) {
                        [replaceableImageArr addObject:fileName];
                    }else {
                        [backgroundImageArr addObject:fileName];
                    }
                }
            }
        }
    }
    NSMutableArray *scenes = [NSMutableArray array];
    for (int i = 0; i < fileList.count; i++) {
        RDFile *file = fileList[i];
        RDScene *scene = [RDScene new];
        VVAsset *vvAsset = [VVAsset new];
        vvAsset.url = file.contentURL;
        if(file.fileType == kFILEVIDEO){
            vvAsset.type = RDAssetTypeVideo;
            vvAsset.timeRange = file.videoTrimTimeRange;
        }else {
            if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                vvAsset.timeRange = file.imageTimeRange;
            }else {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            }
            vvAsset.type = RDAssetTypeImage;
            if (replaceableImageArr.count > 0) {
                if (!file.contentURL) {
                    vvAsset.url = [NSURL fileURLWithPath:[[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:replaceableImageArr[0]]];
                }
                [replaceableImageArr removeObjectAtIndex:0];
            }
        }
        vvAsset.crop = file.crop;
        vvAsset.volume = file.videoVolume;
        
        if (globalFilters.count > 0) {
            RDFilter* filter = globalFilters[file.filterIndex];
            if (filter.type == kRDFilterType_LookUp) {
                vvAsset.filterType = VVAssetFilterLookup;
            }else if (filter.type == kRDFilterType_ACV) {
                vvAsset.filterType = VVAssetFilterACV;
            }else {
                vvAsset.filterType = VVAssetFilterEmpty;
            }
            if (filter.filterPath.length > 0) {
                vvAsset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }
        
        scene.vvAsset = [NSMutableArray arrayWithObject:vvAsset];
        [scenes addObject:scene];
    }
    [rdPlayer setScenes:scenes];
    
    RDJsonAnimation *jsonAnimation = [RDJsonAnimation new];
    if (setting) {
        //配乐
        NSDictionary *musicDic = [setting objectForKey:@"music"];
        NSString *musicFileName = [musicDic objectForKey:@"fileName"];
        NSString *musicPath = [NSString stringWithFormat:@"%@/%@", path, musicFileName];
        if (musicPath && [[NSFileManager defaultManager] fileExistsAtPath:musicPath]) {
            float startTime = [[musicDic objectForKey:@"begintime"] floatValue];
            float duration = [[musicDic objectForKey:@"duration"] floatValue];
            defaultMusicURL = [NSURL fileURLWithPath:musicPath];
            selectedMusic = [[RDMusic alloc] init];
            selectedMusic.identifier = @"music";
            selectedMusic.url = defaultMusicURL;
            if (duration == 0.0) {
                selectedMusic.clipTimeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:selectedMusic.url].duration);
            }else {
                selectedMusic.clipTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, TIMESCALE));
            }
            if (startTime != 0) {
                selectedMusic.effectiveTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE), selectedMusic.clipTimeRange.duration);
            }
            if (_isEnableRepeat) {
                selectedMusic.isRepeat = YES;
            }
            [rdPlayer setMusics:[NSMutableArray arrayWithObject:selectedMusic]];
        }
        //MV
        NSArray *effects = [setting objectForKey:@"effects"];
        if (effects.count >0) {
            NSMutableArray *effectVideos = [NSMutableArray array];
            [effects enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([[obj objectForKey:@"fileName"] length] > 0)
                {
                    [effectVideos addObject:obj];
                }
            }];
            NSMutableArray *selectMVEffects = [NSMutableArray array];
            [effectVideos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                VVMovieEffect *mvEffect = [[VVMovieEffect alloc] init];
                
                NSString *videoFilePath = [path stringByAppendingPathComponent:[obj objectForKey:@"fileName"]];
                
                NSString *shader = [obj objectForKey:@"filter"];
                mvEffect.url = [NSURL fileURLWithPath:videoFilePath];
                mvEffect.timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:mvEffect.url].duration);
                mvEffect.shouldRepeat = [[obj objectForKey:@"repeat"] boolValue];
                if([shader isEqualToString:@"screen"]){
                    mvEffect.type = RDVideoMVEffectTypeScreen;
                }
                else if([shader isEqualToString:@"gray"]){
                    mvEffect.type = RDVideoMVEffectTypeGray;
                }
                else if([shader isEqualToString:@"green"]){
                    mvEffect.type = RDVideoMVEffectTypeGreen;
                }
                else if([shader isEqualToString:@"mask"]){
                    mvEffect.type = RDVideoMVEffectTypeMask;
                }else if([shader isEqualToString:@"backscreen"]){
                    mvEffect.type = RDVideoMVEffectTypeScreen;
                    mvEffect.alpha = [[obj objectForKey:@"alpha"] floatValue];
                }else if([shader isEqualToString:@"chroma"]){
                    mvEffect.type = RDVideoMVEffectTypeChroma;
                    NSArray *colors = obj[@"color"];
                    float r = [colors[0] floatValue]/255.0;
                    float g = [colors[1] floatValue]/255.0;
                    float b = [colors[2] floatValue]/255.0;
                    mvEffect.chromaColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
                }
                if (_isEnableRepeat) {
                    mvEffect.shouldRepeat = YES;
                }
                [selectMVEffects addObject:mvEffect];
            }];
            [rdPlayer addMVEffect:[selectMVEffects mutableCopy]];
        }
        //背景资源
        NSArray *bgArray = [setting objectForKey:@"background"];
        NSMutableArray *bgSourceArray = [NSMutableArray array];
        NSMutableArray *bgSourceMusicArray = [NSMutableArray array];
        [bgArray enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDScene *scene = [[RDScene alloc] init];
            VVAsset *asset = [[VVAsset alloc] init];
            asset.url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[obj objectForKey:@"fileName"]]];
            NSString *type = [obj objectForKey:@"type"];
            if ([type isEqualToString:@"image"]) {
                asset.type = RDAssetTypeImage;
            }else {
                asset.type = RDAssetTypeVideo;
            }
            NSDictionary *cropDic = [obj objectForKey:@"crop"];
            if (cropDic) {
                asset.crop = CGRectMake([cropDic[@"l"] floatValue], [cropDic[@"t"] floatValue], [cropDic[@"r"] floatValue], [cropDic[@"b"] floatValue]);
            }
            
            float startTime = [[musicDic objectForKey:@"begintime"] floatValue];
            float duration = [[musicDic objectForKey:@"duration"] floatValue];
            if (duration == 0.0) {
                asset.timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:asset.url].duration);
            }else {
                asset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, TIMESCALE));
            }
            asset.startTimeInScene = CMTimeMakeWithSeconds(startTime, TIMESCALE);
            asset.volume = 0;
            NSDictionary *musicDic = [obj objectForKey:@"music"];
            if (musicDic) {
                float startTime = [[musicDic objectForKey:@"begintime"] floatValue];
                float duration = [[musicDic objectForKey:@"duration"] floatValue];
                
                RDMusic *music = [[RDMusic alloc] init];
                music.url = [NSURL fileURLWithPath:musicPath];
                if (duration == 0.0) {
                    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:music.url].duration);
                }else {
                    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, TIMESCALE));
                }
                if (startTime != 0) {
                    music.effectiveTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE), music.clipTimeRange.duration);
                }
                music.volume = 1.0;
                music.isFadeInOut = YES;
                [bgSourceMusicArray addObject:music];
            }
            [scene.vvAsset addObject:asset];
            [bgSourceArray addObject:scene];
        }];
        if (bgSourceMusicArray.count > 0) {
            [rdPlayer setDubbingMusics:bgSourceMusicArray];
        }
        //不可编辑资源
        NSArray *noneEditArray = [setting objectForKey:@"aeNoneEdit"];
        NSMutableArray *noneEditPathArray = [NSMutableArray array];
        [noneEditArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [noneEditPathArray addObject:[path stringByAppendingPathComponent:obj]];
        }];
        
        jsonAnimation.nonEditableImagePathArray = noneEditPathArray;
        jsonAnimation.bgSourceArray = bgSourceArray;
    }
    if (jsonAnimation.nonEditableImagePathArray.count == 0 && backgroundImageArr.count > 0) {
        //不可编辑资源
        NSMutableArray *noneEditPathArray = [NSMutableArray array];
        [backgroundImageArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [noneEditPathArray addObject:[path stringByAppendingPathComponent:obj]];
        }];
        jsonAnimation.nonEditableImagePathArray = noneEditPathArray;
    }
    jsonAnimation.jsonPath = _jsonPath;
    jsonAnimation.textSourceArray = textArray;
    jsonAnimation.isRepeat = _isEnableRepeat;
    if (fps > 0) {
        jsonAnimation.exportFps = fps;
    }
    [rdPlayer setJsonAnimation:jsonAnimation];
}

- (void)refreshPlayer {
    
    NSMutableArray *backgroundImageArr = [NSMutableArray array];
    NSMutableArray *replaceableImageArr = [NSMutableArray array];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_jsonPath stringByDeletingLastPathComponent] error:nil];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:_jsonPath];
    NSMutableDictionary *themeDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    float ver = [themeDic[@"ver"] floatValue];
    for (NSString *fileName in files) {
        if ([RDHelpClass isImageUrl:[NSURL fileURLWithPath:[[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName]]]) {
            if (![fileName hasPrefix:@"ReplaceableText"]) {
                if (ver == 1.0) {//不可替换图片命名以background开头
                    if ([fileName hasPrefix:@"background"]) {
                        [backgroundImageArr addObject:fileName];
                    }else {
                        [replaceableImageArr addObject:fileName];
                    }
                }else {//除了Replaceable开头的图片，其它图片都作为不可替换图片
                    if ([fileName hasPrefix:@"Replaceable"]) {
                        [replaceableImageArr addObject:fileName];
                    }else {
                        [backgroundImageArr addObject:fileName];
                    }
                }
            }
        }
    }
    NSMutableArray *scenes = [NSMutableArray array];
    for (int i = 0; i < fileList.count; i++) {
        RDFile *file = fileList[i];
        RDScene *scene = [RDScene new];
        VVAsset *vvAsset = [VVAsset new];
        vvAsset.url = file.contentURL;
        if(file.fileType == kFILEVIDEO){
            vvAsset.type = RDAssetTypeVideo;
            vvAsset.timeRange = file.videoTrimTimeRange;
        }else {
            vvAsset.type = RDAssetTypeImage;
            if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                vvAsset.timeRange = file.imageTimeRange;
            }else {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            }
            vvAsset.type = RDAssetTypeImage;
            if (replaceableImageArr.count > 0) {
                if (!file.contentURL) {
                    vvAsset.url = [NSURL fileURLWithPath:[[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:replaceableImageArr[0]]];
                }
                [replaceableImageArr removeObjectAtIndex:0];
            }
        }
        vvAsset.crop = file.crop;
        vvAsset.volume = file.videoVolume;
        
        if (globalFilters.count > 0) {
            RDFilter* filter = globalFilters[file.filterIndex];
            if (filter.type == kRDFilterType_LookUp) {
                vvAsset.filterType = VVAssetFilterLookup;
            }else if (filter.type == kRDFilterType_ACV) {
                vvAsset.filterType = VVAssetFilterACV;
            }else {
                vvAsset.filterType = VVAssetFilterEmpty;
            }
            if (filter.filterPath.length > 0) {
                vvAsset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }
        
        scene.vvAsset = [NSMutableArray arrayWithObject:vvAsset];
        [scenes addObject:scene];
    }
    [rdPlayer setScenes:scenes];
    [rdPlayer build];
}

- (void)initBottomView {
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, playerView.bounds.size.height + 10, kWIDTH, (iPhone_X ? 120 : 100) + 75 + 40)];
    [scrollView addSubview:bottomView];
    
    UIImageView *icon1 = [[UIImageView alloc] initWithFrame:CGRectMake(13, 10+2.5, 25, 25)];
    icon1.image = [RDHelpClass imageWithContentOfFile:@"素材"];
    [bottomView addSubview:icon1];
    
    UILabel *tipLbl = [[UILabel alloc] initWithFrame:CGRectMake(43, 10, kWIDTH - 50 , 30)];
    tipLbl.text = RDLocalizedString(@"素材输入(点击下面的素材按钮输入)", nil);
    tipLbl.textColor = [UIColor whiteColor];
    tipLbl.font = [UIFont systemFontOfSize:14.0];
    [bottomView addSubview:tipLbl];
    
    sourceScrollView = [UIScrollView new];
    sourceScrollView.frame = CGRectMake(0, 100 - 30 - 15 , kWIDTH , 75);
    sourceScrollView.backgroundColor = [UIColor clearColor];
    sourceScrollView.showsVerticalScrollIndicator = NO;
    sourceScrollView.showsHorizontalScrollIndicator = NO;
    [sourceScrollView setCanCancelContentTouches: NO];
    [sourceScrollView setClipsToBounds: NO];
    if (_isEnableRepeat) {
        NSInteger count = _repeatCount * rdPlayer.aeSourceInfo.count;
        sourceScrollView.contentSize = CGSizeMake(10 * (count + 1) +  count* 75, 0);
    }else {
        sourceScrollView.contentSize = CGSizeMake(10 * (rdPlayer.aeSourceInfo.count + 1) + rdPlayer.aeSourceInfo.count * 75, 0);
    }
    [bottomView addSubview:sourceScrollView];
    
    videoImageSourceArray = [NSMutableArray array];
    NSMutableArray *tempFiles = [_files mutableCopy];
    for (int i = 0; i < _repeatCount; i++) {
        [self initItemBtnWithTempFiles:tempFiles index:i];
    }
    
    
    bottomView.frame = CGRectMake(0, playerView.bounds.size.height + 10, kWIDTH, sourceScrollView.frame.size.height+sourceScrollView.frame.origin.y);
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, bottomView.frame.origin.y + bottomView.bounds.size.height+10, kWIDTH, 1)];
    line.backgroundColor = SCREEN_BACKGROUND_COLOR;
    [scrollView addSubview:line];
    
    UIImageView *icon2 = [[UIImageView alloc] initWithFrame:CGRectMake(10, line.frame.origin.y + line.bounds.size.height, 30, 30)];
    icon2.image = [RDHelpClass imageWithContentOfFile:@"音量"];
    [scrollView addSubview:icon2];
    
    UILabel *musicLbl = [[UILabel alloc] initWithFrame:CGRectMake(40, line.frame.origin.y + line.bounds.size.height + 13.0/2.0, kWIDTH - 50, 20)];
    musicLbl.text = RDLocalizedString(@"背景音乐音量:", nil);
    musicLbl.textColor = [UIColor whiteColor];
    musicLbl.font = [UIFont systemFontOfSize:14.0];
    [musicLbl sizeToFit];
    [scrollView addSubview:musicLbl];
    
    musicVolumeLbl = [[UILabel alloc] initWithFrame:CGRectMake(musicLbl.frame.origin.x + musicLbl.bounds.size.width, musicLbl.frame.origin.y, 100, 20)];
    musicVolumeLbl.text = @"100";
    musicVolumeLbl.textColor = Main_Color;
    musicVolumeLbl.font = [UIFont boldSystemFontOfSize:14.0];
    [scrollView addSubview:musicVolumeLbl];
    
    float space = 8;
    
    musicVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(25, musicVolumeLbl.frame.origin.y + musicVolumeLbl.bounds.size.height + space, kWIDTH - 50-5, 41)];
    musicVolumeSlider.isAETemplate = TRUE;
    musicVolumeSlider.backgroundColor = [UIColor clearColor];
    [musicVolumeSlider setMaximumValue:1];
    [musicVolumeSlider setMinimumValue:0];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
    musicVolumeSlider.layer.cornerRadius = 2.0;
    musicVolumeSlider.layer.masksToBounds = YES;
    image = [image imageWithTintColor];
    [musicVolumeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
    [musicVolumeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
//    [musicVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
    [musicVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_AE轨道球_"] forState:UIControlStateNormal];
    [musicVolumeSlider setValue:1];
    [musicVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
    [musicVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [musicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
    [musicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    [scrollView addSubview:musicVolumeSlider];
    
    UIImageView *icon3 = [[UIImageView alloc] initWithFrame:CGRectMake(10, musicVolumeSlider.frame.origin.y + musicVolumeSlider.bounds.size.height + space - 5, 30, 30)];
    icon3.image = [RDHelpClass imageWithContentOfFile:@"音乐"];
    [scrollView addSubview:icon3];
    
    replaceMusicLbl = [[UILabel alloc] initWithFrame:CGRectMake(40, musicVolumeSlider.frame.origin.y + musicVolumeSlider.bounds.size.height + space, kWIDTH - 50, 20)];
    replaceMusicLbl.text = RDLocalizedString(@"替换背景音乐", nil);
    replaceMusicLbl.textColor = [UIColor whiteColor];
    replaceMusicLbl.font = [UIFont systemFontOfSize:14.0];
    [scrollView addSubview:replaceMusicLbl];
    
    useOriginalMusicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    useOriginalMusicBtn.frame = CGRectMake(kWIDTH - 100 - 10, replaceMusicLbl.frame.origin.y - 10 + 7.5, 100, 25);
    useOriginalMusicBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    useOriginalMusicBtn.layer.borderWidth = 1.0;
    useOriginalMusicBtn.layer.cornerRadius = 5.0;
    [useOriginalMusicBtn setTitle:RDLocalizedString(@"默认音乐", nil) forState:UIControlStateNormal];
    [useOriginalMusicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    useOriginalMusicBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [useOriginalMusicBtn addTarget:self action:@selector(useOriginalMusicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//    useOriginalMusicBtn.hidden = YES;
    [scrollView addSubview:useOriginalMusicBtn];
    
    UIButton *replaceMusicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    replaceMusicBtn.frame = CGRectMake(10, replaceMusicLbl.frame.origin.y + replaceMusicLbl.bounds.size.height + space + 10, kWIDTH - 20, 40);
    replaceMusicBtn.backgroundColor = Main_Color;
    replaceMusicBtn.layer.cornerRadius = 20;
    [replaceMusicBtn setTitle:RDLocalizedString(@"选择音乐", nil) forState:UIControlStateNormal];
    [replaceMusicBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
    replaceMusicBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [replaceMusicBtn addTarget:self action:@selector(replaceMusicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:replaceMusicBtn];
    
    [scrollView setContentSize:CGSizeMake(0, replaceMusicBtn.frame.origin.y + replaceMusicBtn.bounds.size.height + 100)];
}

- (void)initItemBtnWithTempFiles:(NSMutableArray *)tempFiles index:(int)index {
    NSInteger textTag = 100 + index * (textInfoArray.count/_repeatCount);
    NSInteger videoPicTag = 1 + index * (fileList.count/_repeatCount);
    float leftWidth = index * (10  * rdPlayer.aeSourceInfo.count + rdPlayer.aeSourceInfo.count * 75);
    for (int i = 0; i < rdPlayer.aeSourceInfo.count; i++) {
        RDAESourceInfo *info = rdPlayer.aeSourceInfo[i];
        if (info.type == RDAESourceType_Irreplaceable) {
            continue;
        }
        CustomButton *sourceBtn = [[CustomButton alloc] init];
        sourceBtn.frame = CGRectMake(10 * (i + 1) + i * 75 + leftWidth, 0, 75, 75);
        sourceBtn.layer.borderWidth = 1.0;
        sourceBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
        switch (info.type) {
            case RDAESourceType_ReplaceableText:
            {
                [textInfoArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj[@"name"] isEqualToString:info.name]) {
                        [sourceBtn setTitle:obj[@"textContent"] forState:UIControlStateNormal];
                        *stop = YES;
                    }
                }];
                sourceBtn.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
                sourceBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                sourceBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
                sourceBtn.titleLabel.numberOfLines = 0;
                sourceBtn.clipsToBounds = YES;
            }
                break;
                
            case RDAESourceType_ReplaceablePic:
            {
                __block BOOL hasPic = NO;
                [tempFiles enumerateObjectsUsingBlock:^(RDFile *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.fileType == kFILEIMAGE) {
                        hasPic = YES;
                        [sourceBtn setImage:obj.thumbImage forState:UIControlStateNormal];
                        [tempFiles removeObject:obj];
                        *stop = YES;
                    }
                }];
                if (!hasPic) {
                    [sourceBtn setTitle:RDLocalizedString(@"图片", nil) forState:UIControlStateNormal];
                }
            }
                break;
                
            case RDAESourceType_ReplaceableVideoOrPic:
            {
                __block BOOL hasVideo = NO;
                if (_isAllVideoOrPic) {
                    [tempFiles enumerateObjectsUsingBlock:^(RDFile *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        hasVideo = YES;
                        [sourceBtn setImage:obj.thumbImage forState:UIControlStateNormal];
                        [tempFiles removeObject:obj];
                        *stop = YES;
                    }];
                }else {
                    [tempFiles enumerateObjectsUsingBlock:^(RDFile *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.fileType == kFILEVIDEO) {
                            hasVideo = YES;
                            [sourceBtn setImage:obj.thumbImage forState:UIControlStateNormal];
                            [tempFiles removeObject:obj];
                            *stop = YES;
                        }
                    }];
                    if (!hasVideo) {
                        [tempFiles enumerateObjectsUsingBlock:^(RDFile *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if (obj.fileType == kFILEIMAGE) {
                                hasVideo = YES;
                                [sourceBtn setImage:obj.thumbImage forState:UIControlStateNormal];
                                [tempFiles removeObject:obj];
                                *stop = YES;
                            }
                        }];
                    }
                }
                if (!hasVideo) {
                    [sourceBtn setTitle:RDLocalizedString(@"视频/图片", nil) forState:UIControlStateNormal];
                }
            }
                break;
                
            default:
                break;
        }
        if (info.type != RDAESourceType_ReplaceableText) {
            [videoImageSourceArray addObject:info];
        }
        sourceBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [sourceBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        sourceBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
        sourceBtn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        if (info.type == RDAESourceType_ReplaceableText) {
            sourceBtn.tag = textTag++;
        }else {
            sourceBtn.tag = videoPicTag++;
        }
        sourceBtn.object = info;
        [sourceBtn addTarget:self action:@selector(addSource:) forControlEvents:UIControlEventTouchUpInside];
        [sourceScrollView addSubview:sourceBtn];
    }
}

- (void)initCommonAlertViewWithTitle:(nullable NSString *)title
                             message:(nullable NSString *)message
                   cancelButtonTitle:(nullable NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSString *)otherButtonTitles
                        alertViewTag:(NSInteger)alertViewTag
{
    if (commonAlertView) {
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
    commonAlertView = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:cancelButtonTitle
                                        otherButtonTitles:otherButtonTitles, nil];
    commonAlertView.tag = alertViewTag;
    [commonAlertView show];
}

#pragma mark - 按钮事件
- (void)back:(UIButton *)sender {
    if (_exportProgressView) {
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil)
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"取消",nil)
                         otherButtonTitles:RDLocalizedString(@"确定",nil)
                              alertViewTag:7];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)tapPlayButton {
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)tapPublishBtn{
    if (_exportProgressView) {
        return;
    }
    [self playVideo:NO];
    isContinueExport = NO;
    [self exportMovie];
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        if (!isResignActive) {
            [self playVideo:YES];
        }
    }
}

- (void)progressCurrentTime:(CMTime)currentTime{
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
    
    float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
    [videoProgressSlider setValue:progress];
    [playProgress setProgress:progress animated:NO];
}

- (void)playToEnd{
    [self playVideo:NO];
    
    [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [videoProgressSlider setValue:0];
    [playProgress setProgress:0 animated:NO];
}

- (void)tapPlayerView{
    if(playerToolBar.hidden){
        playBtn.hidden = NO;
        [self playerToolbarShow];
    }else{
        playBtn.hidden = YES;
        [self playerToolbarHidden];
    }
}

#pragma mark -
//TODO: 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if (slider == videoProgressSlider) {
        if ([rdPlayer isPlaying]) {
            [self playVideo:NO];
        }
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    }    
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    if (slider == videoProgressSlider) {
        CGFloat current = videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:current];
        [playProgress setProgress:videoProgressSlider.value animated:NO];
    }else {
        musicVolumeLbl.text = [NSString stringWithFormat:@"%.f", slider.value * 100];
        [rdPlayer setVolume:slider.value identifier:@"music"];
    }
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if (slider == videoProgressSlider) {
        CGFloat current = videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
    }else {
        musicVolumeLbl.text = [NSString stringWithFormat:@"%.f", slider.value * 100];
        selectedMusic.volume = slider.value;
        [rdPlayer setVolume:slider.value identifier:@"music"];
    }
}

- (void)playVideo:(BOOL)play{
    if(!play){
        [rdPlayer pause];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        playBtn.hidden = NO;
        [self playerToolbarShow];
    }else{
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
        [rdPlayer play];
        [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
        playBtn.hidden = YES;
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
        [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
    }
}

- (void)playerToolbarShow{
    playerToolBar.hidden = NO;
    playBtn.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        playerToolBar.hidden = YES;
        playBtn.hidden = YES;
    }];
}

#pragma mark - 添加资源
-(void)addSource:(CustomButton *) sender{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    if (sender.tag >= 100) {
        selectedTextIndex = sender.tag - 100;
        [self enterTextVC:sender.object];
    }else {
        selectedIndex = sender.tag - 1;
        if ( sender.imageView.image ) {
            [self createActionSheet];
        }
        else
        {
            if (videoImageSourceArray[selectedIndex].type == RDAESourceType_ReplaceablePic) {
                [self AddFile:ONLYSUPPORT_IMAGE];
            }else {
                [self AddFile:SUPPORT_ALL];
            }
        }
    }
}

//选择题词操作
-(void)createActionSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:RDLocalizedString(@"替换", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (videoImageSourceArray[selectedIndex].type == RDAESourceType_ReplaceablePic) {
            [self AddFile:ONLYSUPPORT_IMAGE];
        }else {
            [self AddFile:SUPPORT_ALL];
        }
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle: RDLocalizedString(@"编辑", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        isNeedPrepare = YES;
        [self cropSource];
    }];
    //把action添加到actionSheet里
    [actionSheet addAction:action2];
    [actionSheet addAction:action1];
    
    
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:RDLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    [actionSheet addAction:action3];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - 添加文字资源
- (void)enterTextVC:(RDAESourceInfo *)sourceInfo{
    isNeedPrepare = YES;
    NSDictionary *textDic = textInfoArray[selectedTextIndex];
    RDJsonText *textSource = textArray[selectedTextIndex];
    TextViewController *textVC = [[TextViewController alloc] init];
    textVC.textSource = textSource;
    textVC.textIndex = selectedTextIndex + 1;
    textVC.suggestionStr = textDic[@"suggestion"];
    textVC.maxNum = [textDic[@"maxNum"] integerValue];
    textVC.lineNum = [textDic[@"lineNum"] integerValue];
    NSString *templateFontName = textDic[@"textFont"];
    NSString *fontPath = textDic[@"fontSrc"];
    if (fontPath.length > 0) {
        templateFontName = [RDHelpClass customFontWithPath:[[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fontPath] fontName:nil];
    }
    if (templateFontName.length == 0) {
        templateFontName = [UIFont systemFontOfSize:10].fontName;
    }
    textVC.templateFontName = templateFontName;
    textVC.templateFontPath = [[_jsonPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:textDic[@"fontSrc"]];
    textVC.delegate = self;
    
    RDNavigationViewController * nav = [[RDNavigationViewController alloc] initWithRootViewController:textVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - TextViewControllerDelegate
- (void)editTextFinished:(NSInteger)fontIndex {
    isNeedPrepare = NO;
    RDJsonText *textSource = textArray[selectedTextIndex];
    UIButton *textBtn = [sourceScrollView viewWithTag:selectedTextIndex + 100];
    [textBtn setTitle:textSource.text forState:UIControlStateNormal];
    [self refreshPlayer];
}

#pragma mark - 添加图片/视频资源
- (void)AddFile:(SUPPORTFILETYPE)type{
    WeakSelf(self);
    
    if (type == ONLYSUPPORT_IMAGE) {
        if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
            [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                [weakSelf addFileWithList:lists withType:type];
            }];
            
            return;
        }
    }else {
        if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]) {
            [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideoAndImageResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                [weakSelf addFileWithList:lists withType:type];
            }];
            
        }else if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)]){
            [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideosResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                [weakSelf addFileWithList:lists withType:type];
            }];
            
            return;
        }
    }
    isNeedPrepare = NO;
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.textPhotoProportion = _exportSize.width/(float)_exportSize.height;
    if (type == ONLYSUPPORT_IMAGE) {
        mainVC.showPhotos = YES;
    }
    ((RDNavigationViewController *)self.navigationController).editConfiguration.mediaCountLimit =  1;
    ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType = type;
    mainVC.onAlbumCallbackBlock = ^(NSMutableArray<NSURL *> * _Nonnull urls) {
        StrongSelf(self);
        strongSelf->isNeedPrepare = NO;
        [strongSelf addFileWithList:urls withType:type];
    };
    mainVC.cancelBlock = ^{
        [rdPlayer prepare];
    };
    RDNavigationViewController * nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addFileWithList:(NSMutableArray *)thumbFilelist withType:(SUPPORTFILETYPE)type{
    RDFile * file = fileList[selectedIndex];
    if([RDHelpClass isImageUrl:[thumbFilelist firstObject]]){
        file.contentURL = [thumbFilelist firstObject];
        if ([RDHelpClass isSystemPhotoUrl:file.contentURL]) {
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.synchronous = YES;
            option.resizeMode = PHImageRequestOptionsResizeModeExact;
            
            PHAsset* asset =[[PHAsset fetchAssetsWithALAssetURLs:@[file.contentURL] options:nil] objectAtIndex:0];
            if ([[asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
                __block float duration = 0;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                  options:option
                                                            resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                if (imageData && ![info[@"PHImageResultIsDegradedKey"] boolValue]) {
                                                                    file.gifData = imageData;
                                                                    duration = [RDVECore isGifWithData:imageData];
                                                                }
                                                            }];
                file.isGif = YES;
                file.imageDurationTime = CMTimeMakeWithSeconds(duration, TIMESCALE);
                file.speedIndex = 2;
            }else {
                file.imageDurationTime = CMTimeMakeWithSeconds(4, TIMESCALE);
                file.speedIndex = 1;
            }
        }else {
            float duration = [RDVECore isGifWithData:[NSData dataWithContentsOfURL:file.contentURL]];
            if (duration > 0) {
                file.isGif = YES;
                file.imageDurationTime = CMTimeMakeWithSeconds(duration, TIMESCALE);
                file.speedIndex = 2;
            }else {
                file.imageDurationTime = CMTimeMakeWithSeconds(4, TIMESCALE);
                file.speedIndex = 1;
            }
        }
        file.fileType = kFILEIMAGE;
    }else{
        file.contentURL = [thumbFilelist firstObject];
        file.fileType = kFILEVIDEO;
        file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
        file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
        file.reverseVideoTimeRange = file.videoTimeRange;
        file.videoTrimTimeRange = kCMTimeRangeInvalid;
        file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
        file.speedIndex = 2;
    }
    
    [self cropSource];
}

- (void)cropSource {
    isNeedPrepare = YES;
    RDFile *file = fileList[selectedIndex];
    RDNavigationViewController *nav;
    if (file.fileType == kFILEIMAGE) {
        __weak typeof(self) weakSelf = self;
        CropViewController *cropVC = [[CropViewController alloc] init];
        cropVC.isOnlyCrop = YES;
        cropVC.presentModel = YES;
        cropVC.globalFilters = globalFilters;
        cropVC.selectFile = fileList[selectedIndex];
        cropVC.editVideoSize = videoImageSourceArray[selectedIndex].size;
        cropVC.editVideoForOnceFinishFiltersAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType,NSInteger filterIndex) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                StrongSelf(self);
                strongSelf->isNeedPrepare = NO;
                file.filterIndex = filterIndex;
                file.crop = crop;
                if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
                    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                }else {
                    file.thumbImage = [strongSelf imageFromImage:[RDHelpClass getThumbImageWithUrl:file.contentURL] inCrop:crop];
                }
                UIButton *sourceBtn = [strongSelf->sourceScrollView viewWithTag:strongSelf->selectedIndex + 1];
                [sourceBtn setImage:file.thumbImage forState:UIControlStateNormal];
                [sourceBtn setTitle:nil forState:UIControlStateNormal];
                
                [strongSelf refreshPlayer];
//                [strongSelf performSelector:@selector(corpInitPlayer) withObject:nil afterDelay:0.5];
            });
        };
        nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
    }else {
        __weak typeof(self) weakSelf = self;
        RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
        trimVideoVC.isShowClipView = YES;
        trimVideoVC.globalFilters = globalFilters;
        trimVideoVC.trimFile = [file copy];
        trimVideoVC.maxCropSize = videoImageSourceArray[selectedIndex].size;
        trimVideoVC.trimType = TRIMMODESPECIFYTIME_ONE;
        trimVideoVC.trimDuration_OneSpecifyTime = videoImageSourceArray[selectedIndex].duration;
        trimVideoVC.isAdjustVolumeEnable = YES;
        trimVideoVC.TrimAndCropVideoFinishFiltersBlock = ^(NSURL *url, CGRect crop, CGRect cropRect, CMTimeRange timeRange, float volume,NSInteger filterIndex) {
            StrongSelf(self);
            strongSelf->isNeedPrepare = NO;
            file.filterIndex = filterIndex;
            file.contentURL = url;
            if(file.isReverse){
                file.reverseVideoTrimTimeRange = timeRange;
            }else{
                file.videoTrimTimeRange = timeRange;
            }
            file.crop = crop;
            if (CGRectEqualToRect(crop, CGRectMake(0, 0, 1.0, 1.0))) {
                file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(timeRange.start) url:file.contentURL urlAsset:nil];
            }else {
                file.thumbImage = [weakSelf imageFromImage:[RDHelpClass assetGetThumImage:CMTimeGetSeconds(timeRange.start) url:file.contentURL urlAsset:nil] inCrop:crop];
            }
            file.videoVolume = volume;
            UIButton *sourceBtn = [strongSelf->sourceScrollView viewWithTag:strongSelf->selectedIndex + 1];
            [sourceBtn setImage:file.thumbImage forState:UIControlStateNormal];
            [sourceBtn setTitle:nil forState:UIControlStateNormal];
            
            [strongSelf refreshPlayer];
        };
        nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    }
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    [self presentViewController:nav animated:YES completion:nil];
}

- (UIImage *)imageFromImage:(UIImage *)image inCrop:(CGRect)crop{
    @autoreleasepool {
        CGSize size = image.size;
        CGRect rect = CGRectMake(size.width * crop.origin.x, size.height * crop.origin.y, size.width * crop.size.width, size.height * crop.size.height);
        NSLog(@"size:%@ crop:%@ rect:%@", NSStringFromCGSize(size), NSStringFromCGRect(crop), NSStringFromCGRect(rect));
        
        CGImageRef sourceImageRef = [image CGImage];
        CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
        UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
        CGImageRelease(newImageRef);
        return newImage;
    }
}

- (void)replaceMusicBtnAction:(UIButton *)sender {
    isNeedPrepare = YES;
    WeakSelf(self);
    RDLocalMusicViewController *localMusicVC = [[RDLocalMusicViewController alloc] init];
//    localMusicVC.maxDuration = duration;
    localMusicVC.selectLocalMusicBlock = ^(RDMusic *music) {
        StrongSelf(self);
        strongSelf->isNeedPrepare = NO;
        strongSelf->selectedMusic.url = music.url;
        strongSelf->selectedMusic.clipTimeRange = music.clipTimeRange;
        strongSelf->useOriginalMusicBtn.hidden = NO;
        strongSelf->replaceMusicLbl.text = RDLocalizedString(@"替换背景音乐-已自定义", nil);
        [strongSelf refreshPlayer];
    };
    [self.navigationController pushViewController:localMusicVC animated:YES];
}

- (void)useOriginalMusicBtnAction:(UIButton *)sender {
    [self playVideo:NO];
//    sender.hidden = YES;
    replaceMusicLbl.text = RDLocalizedString(@"替换背景音乐", nil);
    selectedMusic.url = defaultMusicURL;
    selectedMusic.clipTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(rdPlayer.duration, TIMESCALE));
    [self refreshPlayer];
    
    [hud setCaption:RDLocalizedString(@"已恢复为默认音乐", nil)];
    [hud show];
    [hud hideAfter:2];
}

#pragma mark - 导出
- (RDExportProgressView *)exportProgressView{
    if(!_exportProgressView){
        _exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0,0, kWIDTH, kHEIGHT)];
        _exportProgressView.canTouchUpCancel = YES;
        [_exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
        [_exportProgressView setProgress:0 animated:NO];
        [_exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
        [_exportProgressView setTrackprogressTintColor:UIColorFromRGB(0xffffff)];
        //        _exportProgressView.hidden = YES;
        __weak typeof(self) weakself = self;
        _exportProgressView.cancelExportBlock = ^(){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil)
                                               message:@""
                                     cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                     otherButtonTitles:RDLocalizedString(@"确定",nil)
                                          alertViewTag:5];
                
            });
            
        };
    }
    return _exportProgressView;
}

- (void)cancelExportBlock{
    //将界面上的时间进度设置为零
    videoProgressSlider.value = 0;
    [playProgress setProgress:0];
    currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    [_exportProgressView setProgress:0 animated:NO];
    [_exportProgressView removeFromSuperview];
    _exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
}

- (void)exportMovie{
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [hud setCaption:message];
        [hud show];
        [hud hideAfter:2];
        return;
    }
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:@"%@。%@",[NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导出时长限制%@秒",nil),maxTime],RDLocalizedString(@"您可以关闭本提示去调整，或继续导出。",nil)];
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示",nil)
                                   message:message
                         cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                         otherButtonTitles:RDLocalizedString(@"继续",nil)
                              alertViewTag:6];
        return;
    }
    [rdPlayer stop];
    
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress:0 animated:NO];
    //水印 添加
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:rdPlayer totalDration:rdPlayer.duration exportSize:rdPlayer.animationSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
    __weak typeof(self) myself = self;
    
    NSString *export = ((RDNavigationViewController *)self.navigationController).outPath;
    if(export.length==0){
        export = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
    }
    unlink([export UTF8String]);
    _idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
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
    
    [rdPlayer exportMovieURL:[NSURL fileURLWithPath:export]
                             size:rdPlayer.animationSize
                          bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                              fps:(fps > 0 ? fps : kEXPORTFPS)
                         metadata:@[titleMetadata, locationMetadata, creationDateMetadata, descriptionMetadata]
                     audioBitRate:0
              audioChannelNumbers:1
           maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                         progress:^(float progress) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 NSLog(@"progress:%f",progress);
                                 if(_exportProgressView)
                                     [_exportProgressView setProgress:progress*100.0 animated:NO];
                             });
                         } success:^{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 //UISaveVideoAtPathToSavedPhotosAlbum(export, self, nil, nil);
                                 [myself exportMovieSuc:export];
                                 [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
                             });
                         } fail:^(NSError *error) {
                             NSLog(@"失败:%@",error);
                             [myself exportMovieFail:error];
                             [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
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
    
    if (error) {
        [self initCommonAlertViewWithTitle:error.localizedDescription
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"确定",nil)
                         otherButtonTitles:nil
                              alertViewTag:0];
    }
}
- (void)exportMovieSuc:(NSString *)exportPath{
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    self.exportProgressView = nil;
    NSLog(@"成功");
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    [rdPlayer.view removeFromSuperview];
    rdPlayer = nil;
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 5:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [self cancelExportBlock];
                [rdPlayer cancelExportMovie:nil];
            }
            break;
            
        case 6:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
            
        case 7:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [self cancelExportBlock];
                [rdPlayer cancelExportMovie:nil];
                [self.navigationController popViewControllerAnimated:YES];
            }
            break;
        default:
            break;
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

@end
