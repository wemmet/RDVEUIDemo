//
//  RDTextAnimateViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/19.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTextAnimateViewController.h"
#import "RDZipArchive.h"
#import "RDZSlider.h"
#import "RDMoveProgress.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"
#import "RDEditTextViewController.h"

@interface RDTextAnimateViewController ()<RDVECoreDelegate, UIAlertViewDelegate, RDATMHudDelegate, RDEditTextViewControllerDelegate>
{
    BOOL                      isResignActive;
    UIView                  * playerView;
    UIButton                * playBtn;
    UIView                  * playerToolBar;
    UILabel                 * currentTimeLabel;
    UILabel                 * durationLabel;
    RDZSlider               * videoProgressSlider;
    RDMoveProgress          * playProgress;
    RDVECore                * rdPlayer;
    CGSize                    exportVideoSize;
    RDExportProgressView    * exportProgressView;
    UIAlertView             * commonAlertView;
    RDATMHud                * hud;
    BOOL                      idleTimerDisabled;
    NSMutableArray          * templateArray;
    NSMutableArray          * textInfoArray;
    NSMutableArray          <RDJsonText *>* textArray;
    int                       oldIndex;
    int                       selectedIndex;
    NSMutableArray          * timeArray;
    NSString                * selectedFontName;
}

@end

@implementation RDTextAnimateViewController

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [exportProgressView removeFromSuperview];
                exportProgressView = nil;
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [hud releaseHud];
    hud = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    NSString *filePath = [[RDHelpClass getBundle] pathForResource:@"TextAnimate.zip" ofType:@""];
    NSString *cachePath = [kTextAnimateFolder stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:kTextAnimateFolder]){
        [self OpenZipp:filePath unzipto:cachePath];
    }
    
    oldIndex = -1;
    selectedIndex = 0;
    timeArray = [NSMutableArray array];
    textInfoArray = [NSMutableArray array];
    textArray = [NSMutableArray array];
    [self initTitleView];
    [self getTemplateArray];
    NSDictionary *dic = templateArray[selectedIndex];
    NSString *path = [kTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[path stringByAppendingPathComponent:@"time.txt"]]) {
        if (![fileManager fileExistsAtPath:[kTempTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]]]) {
            [fileManager createDirectoryAtPath:[kTempTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSError *error = nil;
        [fileManager copyItemAtPath:[path stringByAppendingPathComponent:@"time.txt"] toPath:[[kTempTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]] stringByAppendingPathComponent:@"time.txt"] error:&error];
    }
    [self initPlayerView];
    [self initPlayer];
}

- (void)initTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kNavigationBarHeight)];
    [self.view addSubview:titleView];
    
    UILabel *titleLbl = [UILabel new];
    titleLbl.frame = CGRectMake(0, (titleView.frame.size.height - 44), kWIDTH, 44);
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = RDLocalizedString(@"字说", nil);
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.textColor = UIColorFromRGB(0xffffff);
    [titleView addSubview:titleLbl];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.exclusiveTouch = YES;
    backBtn.backgroundColor = [UIColor clearColor];
    backBtn.frame = CGRectMake(5, (titleView.frame.size.height - 44), 44, 44);
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    UIButton *changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    changeBtn.frame = CGRectMake(5 + 44 + 10, (titleView.frame.size.height - 44), 50, 44);
    changeBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [changeBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [changeBtn setTitle:RDLocalizedString(@"切换", nil) forState:UIControlStateNormal];
    [changeBtn addTarget:self action:@selector(changeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//    [titleView addSubview:changeBtn];
    
    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    editBtn.frame = CGRectMake(kWIDTH - 69 - 5 - 50, (titleView.frame.size.height - 44), 50, 44);
    editBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [editBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [editBtn setTitle:RDLocalizedString(@"编辑", nil) forState:UIControlStateNormal];
    [editBtn addTarget:self action:@selector(editBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:editBtn];
    
    UIButton *publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    publishBtn.exclusiveTouch = YES;
    publishBtn.backgroundColor = [UIColor clearColor];
    publishBtn.frame = CGRectMake(kWIDTH - 69, (titleView.frame.size.height - 44), 64, 44);
    publishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [publishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [publishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(publishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:publishBtn];
}

- (void)initPlayerView {
//    CGRect playerFrame;
//    if (exportVideoSize.width >= exportVideoSize.height) {
//        playerFrame = CGRectMake(0, 0, kWIDTH, kWIDTH / (exportVideoSize.width / exportVideoSize.height) + 50);
//    }else {
//        playerFrame = CGRectMake(kWIDTH/4.0, 0, kWIDTH/2.0, kWIDTH/2.0 / (exportVideoSize.width / exportVideoSize.height) + 50);
//    }
    playerView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 :0) + kNavigationBarHeight, kWIDTH, kHEIGHT - ((iPhone_X ? 44 :0) + kNavigationBarHeight))];
    [self.view addSubview:playerView];
    
    playBtn = [UIButton new];
    playBtn.backgroundColor = [UIColor clearColor];
    playBtn.frame = CGRectMake((playerView.frame.size.width - 56)/2.0, (playerView.frame.size.height - 56)/2.0, 56, 56);
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    [playerView addSubview:playBtn];
    
    playerToolBar = [UIView new];
    playerToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    playerToolBar.frame = CGRectMake(0, playerView.frame.size.height - 44, playerView.frame.size.width, 44);
    playerToolBar.hidden = YES;
    [playerView addSubview:playerToolBar];
    
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
    
    videoProgressSlider.backgroundColor = [UIColor clearColor];
    [videoProgressSlider setMaximumValue:1];
    [videoProgressSlider setMinimumValue:0];
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
    image = [image imageWithTintColor];
    [videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
    videoProgressSlider.layer.cornerRadius = 2.0;
    videoProgressSlider.layer.masksToBounds = YES;
    image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
    [videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
    [videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
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

- (void)getTemplateArray {
    templateArray = [NSMutableArray array];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:@"Boxed" forKey:@"name"];
    
    NSMutableDictionary *dic2 = [NSMutableDictionary dictionary];
    [dic2 setObject:@"Boxed2" forKey:@"name"];
    
    NSMutableDictionary *dic3 = [NSMutableDictionary dictionary];
    [dic3 setObject:@"Boxed3" forKey:@"name"];
    
    [templateArray addObject:dic];
    [templateArray addObject:dic2];
    [templateArray addObject:dic3];
}

- (void)initPlayer {
    [self getTimeArray];
    NSDictionary *dic = templateArray[selectedIndex];
    NSString *path = [kTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]];
    NSString *jsonPath = [path stringByAppendingPathComponent:@"config.json"];
    
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:jsonPath];
    NSMutableDictionary *jsonDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    
    exportVideoSize = CGSizeMake([jsonDic[@"w"] floatValue], [jsonDic[@"h"] floatValue]);
    if (!rdPlayer) {
        rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                          APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                         LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                          videoSize:exportVideoSize
                                                fps:kEXPORTFPS
                                         resultFail:^(NSError *error) {
                                             NSLog(@"initSDKError:%@", error.localizedDescription);
                                         }];
        rdPlayer.frame = playerView.bounds;
        rdPlayer.delegate = self;
        [playerView insertSubview:rdPlayer.view atIndex:0];
    }else {
        [rdPlayer setEditorVideoSize:exportVideoSize];
    }
    
    NSMutableArray *tempTextInfoArray = [[jsonDic objectForKey:@"textimg"] objectForKey:@"text"];
    [textInfoArray removeAllObjects];
    [textArray removeAllObjects];
    textInfoArray = [NSMutableArray array];
    textArray = [NSMutableArray array];
    NSArray *aeSourceInfo = [rdPlayer getAESourceInfoWithJosnPath:jsonPath];
    __block int imageCount = 0;
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
            if (textDic) {
                RDJsonText *textSource = [RDJsonText new];
                textSource.identifier = [NSString stringWithFormat:@"%d", idx];
                textSource.size = obj.size;
                textSource.text = textDic[@"textContent"];
                if (timeArray.count > 0 && idx - imageCount < timeArray.count) {
                    RDTextAnimateInfo *textInfo = [timeArray objectAtIndex:idx - imageCount];
                    textSource.startTime = textInfo.startTime;
                    textSource.duration = textInfo.endTime - textInfo.startTime;
                    textSource.text = textInfo.contentStr;
                }
                if (selectedFontName.length > 0) {
                    textSource.fontName = selectedFontName;
                }else {
                    textSource.fontName = textDic[@"textFont"];
                    NSString *fontPath = textDic[@"fontSrc"];
                    if (fontPath.length > 0) {
                        textSource.fontName = [RDHelpClass customFontWithPath:[[kTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]] stringByAppendingPathComponent:textDic[@"fontSrc"]] fontName:nil];
                    }
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
                if (timeArray.count > 0 && idx - imageCount == timeArray.count - 1) {
                    *stop = YES;
                }
            }
        }else {
            imageCount++;
        }
    }];
    NSDictionary *setting = [jsonDic objectForKey:@"rdsetting"];
    NSMutableArray *noneEditPathArray;
    NSMutableArray *bgSourceArray;
    if (setting) {
        //配乐
        NSDictionary *musicDic = [setting objectForKey:@"music"];
        NSString *musicFileName = [musicDic objectForKey:@"fileName"];
        NSString *musicPath = [NSString stringWithFormat:@"%@/%@", path, musicFileName];
        if (musicPath) {
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
            [rdPlayer setMusics:[NSMutableArray arrayWithObject:music]];
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
                }
                [selectMVEffects addObject:mvEffect];
            }];
            [rdPlayer addMVEffect:[selectMVEffects mutableCopy]];
        }
        //背景资源
        NSArray *bgArray = [setting objectForKey:@"background"];
        bgSourceArray = [NSMutableArray array];
        [bgArray enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDJsonAnimationBGSource *bgSource = [[RDJsonAnimationBGSource alloc] init];
            bgSource.path = [path stringByAppendingPathComponent:[obj objectForKey:@"fileName"]];
            
            NSString *type = [obj objectForKey:@"type"];
            if ([type isEqualToString:@"image"]) {
                bgSource.type = RDAssetTypeImage;
            }else {
                bgSource.type = RDAssetTypeVideo;
            }
            NSDictionary *cropDic = [obj objectForKey:@"crop"];
            if (cropDic) {
                bgSource.crop = CGRectMake([cropDic[@"l"] floatValue], [cropDic[@"t"] floatValue], [cropDic[@"r"] floatValue], [cropDic[@"b"] floatValue]);
            }
            
            float startTime = [[musicDic objectForKey:@"begintime"] floatValue];
            float duration = [[musicDic objectForKey:@"duration"] floatValue];
            if (duration == 0.0) {
                bgSource.timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:[NSURL fileURLWithPath:bgSource.path]].duration);
            }else {
                bgSource.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, TIMESCALE));
            }
            bgSource.startTimeInVideo = CMTimeMakeWithSeconds(startTime, TIMESCALE);
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
                bgSource.music = music;
            }
            [bgSourceArray addObject:bgSource];
        }];
        //不可编辑资源
        NSArray *noneEditArray = [setting objectForKey:@"aeNoneEdit"];
        noneEditPathArray = [NSMutableArray array];
        [noneEditArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [noneEditPathArray addObject:[path stringByAppendingPathComponent:obj]];
        }];
        if (aeSourceInfo.count > textArray.count && oldIndex == -1 && selectedIndex == 0) {
            NSMutableArray *scenes = [NSMutableArray array];
            NSString *imagePath = [path stringByAppendingPathComponent:setting[@"imageFolderName"]];
            NSArray *images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imagePath error:nil];
            [images enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.pathExtension isEqualToString:@"png"] || [obj.pathExtension isEqualToString:@"jpg"]) {
                    RDScene *scene = [RDScene new];
                    VVAsset *vvAsset = [VVAsset new];
                    vvAsset.url = [NSURL URLWithString:[imagePath stringByAppendingPathComponent:obj]];
                    vvAsset.type = RDAssetTypeImage;
                    scene.vvAsset = [NSMutableArray arrayWithObject:vvAsset];
                    [scenes addObject:scene];
                }
            }];
            [rdPlayer setScenes:scenes];
        }
    }
    RDJsonAnimation *jsonAnimation = [RDJsonAnimation new];
    jsonAnimation.name = dic[@"name"];
    jsonAnimation.jsonPath = jsonPath;
    jsonAnimation.textSourceArray = textArray;
    jsonAnimation.nonEditableImagePathArray = noneEditPathArray;
    jsonAnimation.backgroundSourceArray = bgSourceArray;
    [rdPlayer setJsonAnimation:jsonAnimation];
    
    oldIndex = selectedIndex;
}

- (void)getTimeArray {
    NSDictionary *dic = templateArray[selectedIndex];
    NSString *path = [kTempTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]];
    NSString *jsonPath = [path stringByAppendingPathComponent:@"time.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jsonPath]) {
        NSString *content = [[NSString alloc] initWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
        content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
        NSArray *contentArray = [content componentsSeparatedByString:@"\n"];
        
        [timeArray removeAllObjects];
        [contentArray enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj hasPrefix:@"["]) {
                NSRange range = [obj rangeOfString:@","];
                if (range.location != NSNotFound) {
                    RDTextAnimateInfo *info = [RDTextAnimateInfo new];
                    info.startTimeStr = [obj substringWithRange:NSMakeRange(1, range.location - 1)];
                    info.startTime = [RDHelpClass timeFromStr:info.startTimeStr];
                    obj = [obj substringFromIndex:range.location + 1];
                    range = [obj rangeOfString:@"]"];
                    if (range.location != NSNotFound) {
                        info.endTimeStr = [obj substringToIndex:range.location];
                        info.endTime = [RDHelpClass timeFromStr:info.endTimeStr];
                        info.contentStr = [obj substringFromIndex:range.location + 1];
                    }
                    [timeArray addObject:info];
                }
            }
        }];
    }
}

#pragma mark - 按钮事件
- (void)back {
    [rdPlayer pause];
    [self clearRDPlayer];
    
    if(_cancelBlock){
        _cancelBlock();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapPlayButton {
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)changeBtnAction:(UIButton *)sender {
    [rdPlayer pause];
    
    if (selectedIndex == 0) {
        selectedIndex = 1;
    }else if (selectedIndex == 1) {
        selectedIndex = 2;
    }else {
        selectedIndex = 0;
    }
    [sender setTitle:[NSString stringWithFormat:@"%d", selectedIndex] forState:UIControlStateNormal];
    [self initPlayer];
}

- (void)editBtnAction:(UIButton *)sender {
    [rdPlayer pause];
    
    NSDictionary *dic = templateArray[selectedIndex];
    NSString *path = [kTempTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]];
    NSString *jsonPath = [path stringByAppendingPathComponent:@"time.txt"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:jsonPath]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        __block NSString *content = @"";
        [rdPlayer.aeSourceInfo enumerateObjectsUsingBlock:^(RDAESourceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj.type == RDAESourceType_ReplaceableText) {
               NSString *startTimeStr = [RDHelpClass timeToStringFormat:obj.startTime];
               NSString *endTimeStr;
               if (idx == rdPlayer.aeSourceInfo.count - 1) {
                   endTimeStr = [RDHelpClass timeToStringFormat:(obj.startTime + obj.duration)];
               }else {
                   RDAESourceInfo *info = [rdPlayer.aeSourceInfo objectAtIndex:(idx + 1)];
                   endTimeStr = [RDHelpClass timeToStringFormat:info.startTime];
               }
               NSString *str = [textArray objectAtIndex:idx].text;
               if (content.length == 0) {
                   content = [NSString stringWithFormat:@"[%@,%@]%@", startTimeStr, endTimeStr, str];
               }else {
                   content = [content stringByAppendingString:[NSString stringWithFormat:@"\n[%@,%@]%@", startTimeStr, endTimeStr, str]];
               }
               if (idx == textArray.count - 1) {
                   *stop = YES;
               }
           }
        }];
        NSError *error = nil;
        if (![content writeToFile:jsonPath atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"写入文件错误：%@", error.localizedDescription);
        }
    }
    __block int textCount;
    [rdPlayer.aeSourceInfo enumerateObjectsUsingBlock:^(RDAESourceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == RDAESourceType_ReplaceableText) {
            textCount++;
        }
    }];
    
    NSDictionary *textDic = textInfoArray[0];
    RDJsonText *textSource = textArray[0];
    RDEditTextViewController *editTextVC = [[RDEditTextViewController alloc] init];
    editTextVC.textContent = [[NSString alloc] initWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
    NSString *templateFontName = textDic[@"textFont"];
    NSString *fontPath = textDic[@"fontSrc"];
    if (fontPath.length > 0) {
        templateFontName = [RDHelpClass customFontWithPath:[[kTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]] stringByAppendingPathComponent:fontPath] fontName:nil];
    }
    if (templateFontName.length == 0) {
        templateFontName = [UIFont systemFontOfSize:10].fontName;
    }
    editTextVC.templateFontName = templateFontName;
    editTextVC.templateFontPath = [path stringByAppendingPathComponent:textDic[@"fontSrc"]];
    editTextVC.selectedFontName = textSource.fontName;
    editTextVC.lineNum = textCount;
    editTextVC.delegate = self;
    
    RDNavigationViewController * nav = [[RDNavigationViewController alloc] initWithRootViewController:editTextVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - RDEditTextViewControllerDelegate
- (void)editTextFinished:(NSString *)fontName textContent:(NSString *)textContent {
    if (textContent) {
        NSDictionary *dic = templateArray[selectedIndex];
        NSString *path = [kTempTextAnimateFolder stringByAppendingPathComponent:dic[@"name"]];
        NSString *jsonPath = [path stringByAppendingPathComponent:@"time.txt"];
        unlink([jsonPath UTF8String]);
        NSError *error = nil;
        if (![textContent writeToFile:jsonPath atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"写入文件错误：%@", error.localizedDescription);
        }
    }
    selectedFontName = fontName;
    [self initPlayer];
}

- (void)publishBtnAction:(UIButton *)sender {
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [hud setCaption:message];
        [hud show];
        [hud hideAfter:2];
        return;
    }
    if(((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
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
    [playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [self initProgressView];
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:rdPlayer totalDration:rdPlayer.duration exportSize:exportVideoSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
    NSString *outputPath = ((RDNavigationViewController *)self.navigationController).outPath;
    if(!outputPath || outputPath.length == 0){
        outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
    }
    unlink([outputPath UTF8String]);
    idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    __weak typeof(self) weakSelf = self;
    [rdPlayer exportMovieURL:[NSURL fileURLWithPath:outputPath]
                        size:exportVideoSize
                     bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                         fps:kEXPORTFPS
                audioBitRate:0
         audioChannelNumbers:1
      maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                    progress:^(float progress) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [exportProgressView setProgress:progress*100.0 animated:NO];
                        });
                    } success:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf exportMovieSuc:outputPath];
                        });
                    } fail:^(NSError *error) {
                        NSLog(@"导出失败:%@",error);
                        [weakSelf exportMovieFail];
                        
                    }];
}

- (void)initCommonAlertViewWithTitle:(NSString *)title
                             message:(NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(NSString *)otherButtonTitles
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

- (void)initProgressView {
    exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    [exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
    [exportProgressView setProgress:0 animated:NO];
    [exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
    [exportProgressView setTrackprogressTintColor:[UIColor whiteColor]];
    exportProgressView.canTouchUpCancel = YES;
    __weak typeof(self) weakself = self;
    exportProgressView.cancelExportBlock = ^(){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？", nil)
                                           message:nil
                                 cancelButtonTitle:RDLocalizedString(@"取消", nil)
                                 otherButtonTitles:RDLocalizedString(@"确定", nil)
                                      alertViewTag:1];
        });
        
    };
    [self.view addSubview:exportProgressView];
}


- (void)exportMovieFail{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    [rdPlayer removeWaterMark];
    [rdPlayer removeEndLogoMark];
    [rdPlayer filterRefresh:kCMTimeZero];
}

- (void)exportMovieSuc:(NSString *)exportPath{
    [self clearRDPlayer];
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RDVECoreDelegate
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
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    CGFloat current = videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:current];
    [playProgress setProgress:videoProgressSlider.value animated:NO];
    
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    
    CGFloat current = videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
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

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if(buttonIndex == 1){
            [self cancelExport];
        }
    }
}

- (void)cancelExport{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [rdPlayer cancelExportMovie:nil];
}

- (void)clearRDPlayer {
    [rdPlayer stop];
    [rdPlayer.view removeFromSuperview];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

- (BOOL)OpenZipp:(NSString*)zipPath  unzipto:(NSString*)_unzipto
{
    
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            
            unlink([zipPath UTF8String]);
            
        }
        [zip RDUnzipCloseFile];
        return YES;
    }
    return NO;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end
