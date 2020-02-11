//
//  RDWordSayViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDWordSayViewController.h"
#import "RDZipArchive.h"
#import "RDZSlider.h"
#import "RDMoveProgress.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"
#import "RDEditTextViewController.h"
#import "RDSVProgressHUD.h"

#import "ScrollViewChildItem.h"
#import "UIImage+RDWebP.h"
#import "UIImageView+RDWebCache.h"
#import "UIButton+RDWebCache.h"

//富文本
#include <CoreText/CoreText.h>

//贴纸
#import "RDAddEffectsByTimeline.h"
#import "RDAddEffectsByTimeline+Sticker.h"
#import "RDAddEffectsByTimeline+Subtitle.h"

//音乐
#import "RDLocalMusicViewController.h"
#import "RDCloudMusicViewController.h"
#import "RDFileDownloader.h"
#import "CircleView.h"

#import "RDWordSayTextLayerParam.h"

#import "RDATMHud.h"
#import "UIImage+RDGIF.h"
#import "RDTextFontEditor.h"


#import "LocalPhotoCell.h"
#import "RDOtherAlbumsViewController.h"
#import <Photos/Photos.h>
#import "RD_ImageManager.h"


#define kOthersAlbum @"othersAlbum"

//截取
#import "RDTrimVideoViewController.h"

#import "RDMBProgressHUD.h"

#import "RDYYWebImage.h"
#define Background_COLOR Main_Color
#define CG_COLOR(R, G, B, A) [UIColor colorWithRed:(R) green:(G) blue:(B) alpha:(A)].CGColor

#define Margin_X         52.5f

#define Amplification    30

@implementation RDStrTimeRange
@end

@implementation RDAudioPathTimeRange
@end

typedef NS_ENUM(NSInteger,RDDisplayTextType)
{
    RDDisplayTextType_Rotate = 0,               //旋转
    RDDisplayTextType_Horiz,                    //横排
    RDDisplyaTextType_Vertical,                 //竖排
};

@interface RDWordSayViewController ()<RDVECoreDelegate, UIAlertViewDelegate, RDATMHudDelegate, RDEditTextViewControllerDelegate,ScrollViewChildItemDelegate,RDAddEffectsByTimelineDelegate,RDTextFontEditorDelegate,UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
{
    UIView *titleView;
    
    UIView              *MainCircleView;
    
    BOOL                      isResignActive;
    UIView                  * playerView;
    UIButton                * playBtn;
    UIView                  * playerToolBar;
    UILabel                 * currentTimeLabel;
    UILabel                 * durationLabel;
    RDZSlider               * videoProgressSlider;
//    RDMoveProgress          * playProgress;
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
    
    NSMutableArray          *toolItems;
    NSMutableArray              *functionalItems;
    UIView                      *selectedFunctionView;
    NSInteger                    selecteFunction;
    
    //变声
    NSArray                 *soundEffectArray;
    UIScrollView            *soundEffectScrollView;
    NSInteger                selectedSoundEffectIndex;
    RDZSlider               *soundEffectSlider;
    UILabel                 *soundEffectLabel;
    float                    oldPitch;
    
    //贴纸
    NSMutableArray <RDCaption *> *stickers;
    NSMutableArray <RDCaptionRangeViewFile *> *stickerFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldStickerFiles;
    
    CMTime                   startPlayTime;
    UIScrollView            * addedSubtitleScrollView;
    UIScrollView            * addedMaterialEffectScrollView;
    UIImageView             * selectedMaterialEffectItemIV;
    NSInteger                selectedMaterialEffectIndex;
    BOOL                     isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    CMTime                   seekTime;
    
    RDVECore                *thumbImageVideoCore;//截取缩率图
    NSMutableArray          *thumbTimes;
    float                    addingMaterialDuration;
    UILabel                 *toolbarTitleLbl;
    UIButton                *cancelBtn;
    UIButton                *_toolbarTitlefinishBtn;
    
    //音乐
    float                    volumeMultipleM;
    float                    oldVolume;
    
    NSArray                 *musicList;
    NSInteger               selectMusicIndex;
    NSInteger               oldMusicIndex;         //配乐
    RDMusic                      *oldmusic;             //云音乐地址
    BOOL                    yuanyinOn;
    NSMutableArray          *mvMusicArray;
    
    //文字自绘
    NSMutableArray          <RDWordSayTextLayerParam*> *textLayerArray; //文字自绘数组
    NSMutableArray          <RDWordSayTextLayerParam*> *textLayerCombinationArray;//文字自绘 组合 数组
    NSMutableArray          <RDTextObject*>              *textObjectArray;            //文本自绘 数据 数组
    
    RDDisplayTextType       currentDisdisplayTextType;      //当前文字显示类型
    
    int                     IntervalFPS;
    BOOL                    isRebuild;
    
    float                   fwidth;
    
    //
    bool                    isCustomize;
    
    RDFile                  *currentBackgroundFile;
    
    //
    UIButton                *publishBtn;        //发布
    UIButton                *backBtn;           //退出
    
    //背景
    UIButton                *albumBackBtn;      //退出 相册
    
    CMTime                  exportCurrentTime;  //导出当前时间
    BOOL                    isExport;          //是否导出
    
    int                     currentColorIndex;
    
    UIImageView             *backgroundImageView;
}
//功能区分界面
@property(nonatomic,strong)UIView                   *functionalAreaView;            //功能区界面
 //文字排版
@property(nonatomic,strong)UIView                   *typesettView;
@property(nonatomic,strong)UIScrollView             *typesettScrollView;
@property(nonatomic,strong)UIScrollView             *toolBarView;
//变声
@property(nonatomic,strong)UIView                   *soundEffectView;
@property(nonatomic,strong)UIView                   *customSoundView;
@property(nonatomic,strong)UIButton                 *closeBtn;                //关闭按钮

//背景
@property(nonatomic,strong)UIView                   *backgroundView;            //背景

@property(nonatomic,strong)UILabel                  *transparencyVolumelabel;
@property(nonatomic,strong)RDZSlider                *transparencyVolumeSlider;

@property(nonatomic,strong)UIView                   *albumBtnView;              //相册按钮界面
@property(nonatomic,strong)UIButton                 *materialBtn;               //已添加的素材背景
@property(nonatomic,strong)UIImageView              *materialImage;             //
@property(nonatomic,strong)UIButton                 *backgroundBtn;             //添加背景


@property(nonatomic,strong)UIScrollView             *solidColorView;            //纯色按钮界面
@property(nonatomic,strong)NSMutableArray<UIButton *>   *textColorBtnArray;
@property(nonatomic,strong)NSMutableArray<UIColor *>    *textColorArray;

@property (nonatomic, strong) UIView                *albumView;
@property (nonatomic, strong) UIView                *albumTitleView;
@property (nonatomic, strong) UIScrollView          *albumScrollView;
@property (nonatomic, strong) NSMutableArray        *videoArray;
@property (nonatomic, strong) NSMutableArray        *picArray;


//贴纸
@property(nonatomic,strong)UIView                   *addEffects;
@property(nonatomic,strong)UIView                   *addEffectsOpe;
@property(nonatomic,strong)UIView                   *addEffectsByTimelineView;
@property(nonatomic,strong)RDAddEffectsByTimeline   *addEffectsByTimeline;
@property (nonatomic, strong) UIView                *addedMaterialEffectView;
@property (nonatomic, assign) BOOL                   isAddingMaterialEffect;
@property (nonatomic, assign) BOOL                   isEdittingMaterialEffect;
@property (nonatomic, assign) BOOL                   isCancelMaterialEffect;

//文字
@property(nonatomic,strong)RDTextFontEditor         *textEditView;      //编辑界面

//音乐
@property(nonatomic,strong)UIView                   * musicUI;

@property(nonatomic,strong)UIScrollView             * musicScrollView;
@property(nonatomic,strong)UIView                   * musicView;                 //音乐 界面
@property(nonatomic,strong)UILabel                 *dubbingLabel;
@property(nonatomic,assign)float                     dubbingVolume;            //音乐音量
@property(nonatomic,strong)UILabel                  *musicVolumeLabel;
@property(nonatomic,strong)UILabel                  *videoVolumelabel;
@property(nonatomic,strong)RDZSlider                *musicVolumeSlider;
@property(nonatomic,strong)RDZSlider                *dubbingVolumeSlider;
@property(nonatomic,strong)UIScrollView             *musicChildsView;
@property(nonatomic,assign)float                     musicVolume;            //音乐音量
@property(nonatomic,strong)NSURL                    *musicURL;              //音乐地址
@property(nonatomic,assign)CMTimeRange               musicTimeRange;         //音乐时间范围
@property(nonatomic,strong)RDATMHud *hud;

@property(nonatomic,strong)RDMBProgressHUD  *progressHUD;

//动画启动
@property(nonatomic,strong)UISwitch        *animationBtn;
@end

@implementation RDWordSayViewController

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:nil];
        [self.navigationController.view addSubview:_hud.view];
    }
    return _hud;
}

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

#pragma makr- keybordShow&Hidde
- (void)keyboardWillShow:(NSNotification *)notification{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    if( (_textEditView.editTxtView == nil) )
    {
        [_textEditView CreateEditTxtView];
        
        _textEditView.textFontScrollView.hidden = YES;
        _textEditView.textColorScrollView.hidden = YES;
        
        CGRect bottomViewFrame = _textEditView.editTxtView.frame;
        bottomViewFrame.origin.y = kHEIGHT - keyboardSize.height - 44;
        _textEditView.editTxtView.frame = bottomViewFrame;
        _textEditView.editTxtView.hidden = NO;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification{
    CGRect bottomViewFrame = _textEditView.editTxtView.frame;
    bottomViewFrame.origin.y = kHEIGHT - 44;
    _textEditView.editTxtView.frame = bottomViewFrame;
    [_textEditView.editTxtView removeFromSuperview];
    _textEditView.editTxtView = nil;
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
    if( rdPlayer != nil )
       [rdPlayer prepare];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [hud releaseHud];
    hud = nil;
    [rdPlayer stop];
}

- (BOOL)checkSubtitleIconDownload{
    NSArray *icons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kSubtitleIconPath error:nil];
    NSArray *fontIcons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kFontIconPath error:nil];
    
    BOOL hasNewSubtitle =  ((RDNavigationViewController *)self.navigationController).editConfiguration.subtitleResourceURL.length>0;
    
    NSArray *subtitles = [[NSArray alloc] initWithContentsOfFile:kSubtitlePlistPath];
    if((icons.count>0 && fontIcons.count>0 && !hasNewSubtitle) || (hasNewSubtitle && subtitles.count>0)){
        [RDHelpClass downloadIconFile:RDAdvanceEditType_Subtitle
                           editConfig:((RDNavigationViewController *)self.navigationController).editConfiguration
                               appKey:((RDNavigationViewController *)self.navigationController).appKey
                            cancelBtn:_progressHUD.cancelBtn
                        progressBlock:nil
                             callBack:nil
                          cancelBlock:nil];
        return YES;
    }else{
        __weak typeof(self) myself = self;
        if(icons.count>0 && !hasNewSubtitle){
            if(fontIcons.count>0){
            }else{
                [RDHelpClass downloadIconFile:RDAdvanceEditType_None
                                   editConfig:((RDNavigationViewController *)self.navigationController).editConfiguration
                                       appKey:((RDNavigationViewController *)self.navigationController).appKey
                                    cancelBtn:_progressHUD.cancelBtn
                                progressBlock:^(float progress) {
                                    [myself myProgressTask:progress];
                                } callBack:^(NSError *error) {
                                    if(!error){
                                    }
                                    [myself.progressHUD hide:NO];
                                } cancelBlock:^{
                                    [myself.progressHUD hide:NO];
                                }];
            }
        }
        else{
            NSArray *fontIcons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kFontIconPath error:nil];
            [self initProgressHUD:RDLocalizedString(@"请稍等...", nil)];
            [RDHelpClass downloadIconFile:RDAdvanceEditType_Subtitle
                               editConfig:((RDNavigationViewController *)self.navigationController).editConfiguration
                                   appKey:((RDNavigationViewController *)self.navigationController).appKey
                                cancelBtn:_progressHUD.cancelBtn
                            progressBlock:^(float progress) {
                                if(fontIcons.count>0){
                                    [myself myProgressTask:progress];
                                }else{
                                    [myself myProgressTask:progress/2.0];
                                }
                            } callBack:^(NSError *error) {
                                if(fontIcons.count>0 && !hasNewSubtitle){
                                    if(!error){
                                        
                                    }
                                    [myself.progressHUD hide:NO];
                                }else{
                                    [RDHelpClass downloadIconFile:RDAdvanceEditType_None
                                                       editConfig:((RDNavigationViewController *)self.navigationController).editConfiguration
                                                           appKey:((RDNavigationViewController *)self.navigationController).appKey
                                                        cancelBtn:_progressHUD.cancelBtn
                                                    progressBlock:^(float progress) {
                                                        [myself myProgressTask:progress/2.0 + 0.5];
                                                    } callBack:^(NSError *error) {
                                                        if(!error){
                                                        }
                                                        [myself.progressHUD hide:NO];
                                                    } cancelBlock:^{
                                                        [myself.progressHUD hide:NO];
                                                    }];
                                }
                            } cancelBlock:^{
                                [myself.progressHUD hide:NO];
                            }];
        }
        return NO;
    }
}

- (void)initProgressHUD:(NSString *)message{
    if ( MainCircleView != nil ) {
        MainCircleView = nil;
        _progressHUD = nil;
    }
    
    MainCircleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    MainCircleView.backgroundColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    
    if (_progressHUD) {
        _progressHUD = nil;
    }
    //圆形进度条
    _progressHUD = [[RDMBProgressHUD alloc] initWithView:MainCircleView];
    [MainCircleView addSubview:_progressHUD];
    _progressHUD.removeFromSuperViewOnHide = YES;
    _progressHUD.mode = RDMBProgressHUDModeDeterminate;
    _progressHUD.animationType = RDMBProgressHUDAnimationFade;
    _progressHUD.labelText = message;
    _progressHUD.isShowCancelBtn = YES;
    [_progressHUD show:YES];
    [self myProgressTask:0];
    [self.view addSubview:MainCircleView];
    [MainCircleView setHidden:NO];
    
}
- (void)myProgressTask:(float)progress{
    [_progressHUD setProgress:progress];
}

- (int)getRandomNumber:(int)from to:(int)to {
    return (int)(from + (arc4random() % (to - from + 1)));
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
    
    currentColorIndex = -1;
    _dubbingVolume = 1;
    IntervalFPS = 85;
    isExport = false;
    if( _strArrry == nil )
    {
        _strArrry = [NSMutableArray new];
        [_strArrry addObject:@"静夜思"];
        [_strArrry addObject:@"床前明月光"];
        [_strArrry addObject:@"疑是地上霜"];
        [_strArrry addObject:@"举头望明月"];
        [_strArrry addObject:@"低头思故乡"];
        isCustomize = false;
    }
    else
    {
        IntervalFPS = 45;
        isCustomize = true;
    }
    
    [self CreateText];
    
    isRebuild = false;
    [self checkSubtitleIconDownload];
    currentDisdisplayTextType = RDDisplayTextType_Rotate;
   
    volumeMultipleM= 5.0;
    _musicVolume = 0.5;
    oldVolume = 1.0;
    oldIndex = -1;
    selectedIndex = 0;
    oldPitch = 1.0;
    timeArray = [NSMutableArray array];
    textInfoArray = [NSMutableArray array];
    textArray = [NSMutableArray array];
    
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
    
    [self initTextLayerArray];
    
    [self initPlayerView];
    [self initTitleView];
    
    
    [self initPlayer];
}

- (void)initTitleView {
    titleView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, 44)];
    [self.view addSubview:titleView];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (__bridge id)[UIColor clearColor].CGColor];
    gradientLayer.locations = @[@0.3, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1.0);
    gradientLayer.frame = titleView.bounds;
    [titleView.layer addSublayer:gradientLayer];
//    UILabel *titleLbl = [UILabel new];
//    titleLbl.frame = CGRectMake(0, (titleView.frame.size.height - 44), kWIDTH, 44);
//    titleLbl.textAlignment = NSTextAlignmentCenter;
//    titleLbl.backgroundColor = [UIColor clearColor];
//    titleLbl.text = RDLocalizedString(@"字说", nil);
//    titleLbl.font = [UIFont boldSystemFontOfSize:20];
//    titleLbl.textColor = UIColorFromRGB(0xffffff);
//    [titleView addSubview:titleLbl];
//
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.exclusiveTouch = YES;
    backBtn.backgroundColor = [UIColor clearColor];
    backBtn.frame = CGRectMake(5, (titleView.frame.size.height - 44), 44, 44);
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    albumBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    albumBackBtn.exclusiveTouch = YES;
    albumBackBtn.backgroundColor = [UIColor clearColor];
    albumBackBtn.frame = CGRectMake(5, (titleView.frame.size.height - 44), 44, 44);
    [albumBackBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [albumBackBtn addTarget:self action:@selector(albumBack) forControlEvents:UIControlEventTouchUpInside];
    albumBackBtn.hidden = YES;
    [titleView addSubview:albumBackBtn];
    
//    UIButton *changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    changeBtn.frame = CGRectMake(5 + 44 + 10, (titleView.frame.size.height - 44), 50, 44);
//    changeBtn.titleLabel.font = [UIFont systemFontOfSize:16];
//    [changeBtn setTitleColor:Main_Color forState:UIControlStateNormal];
//    [changeBtn setTitle:RDLocalizedString(@"切换", nil) forState:UIControlStateNormal];
//    [changeBtn addTarget:self action:@selector(changeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    //    [titleView addSubview:changeBtn];
    
    publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    publishBtn.exclusiveTouch = YES;
    publishBtn.backgroundColor = [UIColor clearColor];
    publishBtn.frame = CGRectMake(kWIDTH - 69, (titleView.frame.size.height - 44), 64, 44);
    publishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [publishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [publishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(publishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:publishBtn];
    self.animationBtn.hidden = NO;
    [self getValue1];
}

- (void)initPlayerView {
    playerView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight)];
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
    
    [self.view insertSubview:self.functionalAreaView belowSubview:playerView];
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

- (void)initThumbImageVideoCore{
    if( !thumbImageVideoCore )
    {
        thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:exportVideoSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];
        thumbImageVideoCore.delegate = self;
        thumbImageVideoCore.frame = playerView.bounds;
    }
    else {
        [thumbImageVideoCore setEditorVideoSize:exportVideoSize];
    }
    
    [self refreshRdPlayer:thumbImageVideoCore];
}

- (void)refreshRdPlayer:(RDVECore *)Player {
    
    if( (currentColorIndex == -1) && ( currentBackgroundFile != nil ) )
    {
        NSMutableArray<RDScene*> *sceneArray = [NSMutableArray new];
        if( currentBackgroundFile.fileType != kFILEVIDEO )
        {
            RDScene *scene = [[RDScene alloc] init];
            VVAsset *asset = [[VVAsset alloc] init];
            asset.type = RDAssetTypeImage;
            asset.timeRange    = CMTimeRangeMake(kCMTimeZero, currentBackgroundFile.imageDurationTime);
            asset.url = currentBackgroundFile.contentURL;
            asset.speed        = currentBackgroundFile.speed;
            asset.volume       = currentBackgroundFile.videoVolume;
            asset.fillType     = RDImageFillTypeFull;
            asset.crop = currentBackgroundFile.crop;
            
            if( _transparencyVolumeSlider == nil )
                asset.alpha = 1.0;
            else
                asset.alpha = _transparencyVolumeSlider.value;
            
            [scene.vvAsset addObject:asset];
            [sceneArray addObject:scene];
        }
        else
        {
            CMTime time = CMTimeAdd(_audioPathArray[_audioPathArray.count-1].timeRang.start, _audioPathArray[_audioPathArray.count-1].timeRang.duration);
            if( _audioPathArray == nil )
                time = textObjectArray[textObjectArray.count-1].showTime;
            
            float duration = CMTimeGetSeconds(time);
            float fileDuration = CMTimeGetSeconds(currentBackgroundFile.videoTrimTimeRange.duration);
            
            float fCount = duration/fileDuration;
            int count = (int)fCount;
            float Remain = fCount - count;
            if( Remain > 0 )
                count++;
            
            for (int i = 0; i < count; i++) {
                
                CMTime filTime = currentBackgroundFile.videoTrimTimeRange.duration;
                if( ( i == (count-1) ) && ( Remain >0 ) )
                {
                    if( i != 0 )
                        filTime = CMTimeMake(Remain*fileDuration, 30);
                    else
                        filTime = time;
                }
                
                RDScene *scene = [[RDScene alloc] init];
                VVAsset *asset = [[VVAsset alloc] init];
                asset.type = RDAssetTypeVideo;
                asset.timeRange    = CMTimeRangeMake(kCMTimeZero, filTime);
                asset.url = currentBackgroundFile.contentURL;
                asset.videoActualTimeRange = currentBackgroundFile.videoActualTimeRange;
                asset.speed        = currentBackgroundFile.speed;
                asset.volume       = currentBackgroundFile.videoVolume;
                asset.videoFillType =  RDVideoFillTypeFull;
                asset.crop = currentBackgroundFile.crop;
                [scene.vvAsset addObject:asset];
                
                if( _transparencyVolumeSlider == nil )
                    asset.alpha = 1.0;
                else
                    asset.alpha = _transparencyVolumeSlider.value;
                
                [sceneArray addObject:scene];
                
            }
        }
        [Player setScenes:sceneArray];
        [Player setBackGroundColorWithRed:0 Green:0 Blue:0 Alpha:0];
    }
    else
    {
        RDScene *scene = [[RDScene alloc] init];
        VVAsset *asset = [[VVAsset alloc] init];
        if( isCustomize )
        {
            asset.type = RDAssetTypeImage;
            asset.url = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"TextToSpeech/image" Type:@"png"]];
            
            if( currentColorIndex != -1 )
            {
                asset.alpha = 0.0;
            }
            
            asset.speed        = 1.0;
            asset.volume       = 1.0;
            asset.fillType     = RDImageFillTypeFull;
            if( _audioPathArray != nil )
            {
                CMTime time = CMTimeAdd(_audioPathArray[_audioPathArray.count-1].timeRang.start, _audioPathArray[_audioPathArray.count-1].timeRang.duration);
                
                asset.timeRange = CMTimeRangeMake(kCMTimeZero, time);
            }
            else
                asset.timeRange = CMTimeRangeMake(kCMTimeZero, textObjectArray[textObjectArray.count-1].showTime);
        }
        else
        {
            asset.type = RDAssetTypeVideo;
            asset.url = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"background" Type:@"mp4"]];
            asset.timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:asset.url].duration);
        }
        [scene.vvAsset addObject:asset];
        [Player setScenes:[NSMutableArray arrayWithObject:scene]];
        if( currentColorIndex != -1 )
        {
            CGFloat R, G, B, A;
            CGColorRef color = [_textColorArray[currentColorIndex]  CGColor];
            int numComponents = CGColorGetNumberOfComponents(color);
            if (numComponents == 4)
            {
                const CGFloat *components = CGColorGetComponents(color);
                R = components[0];
                G = components[1];
                B = components[2];
                A = components[3];
            }
            
            if( _transparencyVolumeSlider == nil )
                A = 1.0;
            else
                A = _transparencyVolumeSlider.value;
            
            [Player setBackGroundColorWithRed:R Green:G Blue:B Alpha:A];
        }
    }
    
    
    oldIndex = selectedIndex;
    
    if( rdPlayer == Player )
    {
        [self refreshCaptions];
        if( !_musicView.hidden )
            Player.enableAudioEffect = YES;
        else
            Player.enableAudioEffect = NO;
        [self refreshSound];
    }
    else
    {
        [Player setMusics:nil];
        [Player build];
    }
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
    
    fwidth = (exportVideoSize.width - 375)/2.0;
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
    
    [self refreshRdPlayer:rdPlayer];
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
                    info.startTime = [self timeFromStr:info.startTimeStr];
                    obj = [obj substringFromIndex:range.location + 1];
                    range = [obj rangeOfString:@"]"];
                    if (range.location != NSNotFound) {
                        info.endTimeStr = [obj substringToIndex:range.location];
                        info.endTime = [self timeFromStr:info.endTimeStr];
                        info.contentStr = [obj substringFromIndex:range.location + 1];
                    }
                    [timeArray addObject:info];
                }
            }
        }];
    }
}

- (float)timeFromStr:(NSString *)timeStr {
    float min = 0;
    float second = 0;
    float millisecond = 0;
    NSRange range = [timeStr rangeOfString:@":"];
    if (range.location != NSNotFound) {
        min = [[timeStr substringToIndex:range.location] floatValue];
        timeStr = [timeStr substringFromIndex:range.location + 1];
        range = [timeStr rangeOfString:@"."];
        if (range.location != NSNotFound) {
            second = [[timeStr substringToIndex:range.location] floatValue];
            NSString *millisecondStr = [timeStr substringFromIndex:range.location + 1];
            if (millisecondStr.length > 0) {
                if (millisecondStr.length == 1) {
                    millisecond = [[millisecondStr stringByAppendingString:@"00"] floatValue];
                }else if (millisecondStr.length == 2) {
                    millisecond = [[millisecondStr stringByAppendingString:@"0"] floatValue];
                }else {
                    millisecond = [millisecondStr floatValue];
                }
            }
        }else {
            second = [timeStr floatValue];
        }
    }
    
    float time = min * 60 + second + millisecond/1000.0;
    
    return time;
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
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
        [rdPlayer seekToTime:CMTimeMake(0.2, 1.0)];
        [rdPlayer stop];
    }
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
    
    exportCurrentTime = kCMTimeZero;
    isExport = true;
    
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
                        exportCurrentTime = kCMTimeZero;
                        isExport = false;
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
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        if(sender == rdPlayer){
            durationLabel.text = [RDHelpClass timeToStringNoSecFormat:rdPlayer.duration];
            if( (selecteFunction == RDAdvanceEditType_Multi_track)
               || (selecteFunction == RDAdvanceEditType_Sound) )
            {
            }
            else if (selecteFunction == RDAdvanceEditType_Collage || selecteFunction == RDAdvanceEditType_Doodle) {
                NSLog(@"%sisAddingCollage:%@", __func__, _isAddingMaterialEffect ? @"YES" : @"NO");
                if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                    [rdPlayer seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:nil];
                    seekTime = kCMTimeZero;
                }
            }
            else if(selecteFunction != RDAdvanceEditType_Effect && selecteFunction != RDAdvanceEditType_Cover && selecteFunction != RDAdvanceEditType_Dubbing)
            {
                if (!isResignActive) {
                    [self playVideo:YES];
                }
            }
            else{
                if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
                    [self playVideo:YES];
                }else {
                    CMTime time = seekTime;
                    seekTime = kCMTimeZero;
                    __weak typeof(self) weakSelf = self;
                    [rdPlayer seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                        [weakSelf playVideo:YES];
                    }];
                }
            }
        }else{
            [self loadTrimmerViewThumbImage];
        }
    }
}




- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
    
    float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
    [videoProgressSlider setValue:progress];
    if( (_textEditView) && !_textEditView.hidden )
    {
        
        [_textEditView.textVideoProgress setValue:progress];
        
        _textEditView.textTimeLabel.text = [NSString stringWithFormat:@"%@/%@",[_textEditView IntTimeToStringFormat:CMTimeGetSeconds([rdPlayer currentTime])],[_textEditView IntTimeToStringFormat:rdPlayer.duration]];
    }
    
    if(sender == thumbImageVideoCore){
        return;
    }
    if([rdPlayer isPlaying]){
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            {
                if(!_addEffectsByTimeline.trimmerView.videoCore) {
                    [_addEffectsByTimeline.trimmerView setVideoCore:thumbImageVideoCore];
                }
                [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
                _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
                if(_isAddingMaterialEffect){
                    BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
                    if(!suc){
                        [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                    }else if (addingMaterialDuration > 0 && CMTimeGetSeconds(currentTime) >= _addEffectsByTimeline.trimmerView.startTime - _addEffectsByTimeline.trimmerView.piantouDuration + addingMaterialDuration) {
                        [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                    }
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)playToEnd{
    [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Sticker:
        {
            if(_isAddingMaterialEffect){
                [_addEffectsByTimeline saveStickerTouchUp];
            }else{
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        default:
            break;
    }
    
    if( (_textEditView) && !_textEditView.hidden )
    {
        [_textEditView.textVideoProgress setValue:0];
        _textEditView.textTimeLabel.text = [NSString stringWithFormat:@"%@/%@",[_textEditView IntTimeToStringFormat:0],[_textEditView IntTimeToStringFormat:rdPlayer.duration]];
        _textEditView.textPlayBtn.selected = NO;
    }
    
    [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [videoProgressSlider setValue:0];
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
    if(slider == _musicVolumeSlider)
    {
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        if (!rdPlayer.isPlaying) {
            [self playVideo:YES];
        }
    }
    else if(slider == _dubbingVolumeSlider){
        _dubbingVolume = _dubbingVolumeSlider.value*volumeMultipleM;
        if (!rdPlayer.isPlaying) {
            [self playVideo:YES];
        }
    }
    else
    {
        if([rdPlayer isPlaying]){
            [self playVideo:NO];
        }
    }
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    
    if(slider == _musicVolumeSlider){
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        [rdPlayer setVolume:_musicVolume identifier:@"music"];
    }
    else if(slider == _dubbingVolumeSlider){
        _dubbingVolume = _dubbingVolumeSlider.value*volumeMultipleM;
        [rdPlayer setVolume:_dubbingVolume identifier:@"audioWordsSay"];
    }
    else if( slider == videoProgressSlider )
    {
        CGFloat current = videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:current];
    }
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if(slider == _musicVolumeSlider){
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
#if !ENABLEAUDIOEFFECT
        if([rdPlayer isPlaying]){
            [self playVideo:NO];
        }
        [self refreshRdPlayer:rdPlayer];
#endif
    }
    else if(slider == _dubbingVolumeSlider){
        _dubbingVolume = _dubbingVolumeSlider.value*volumeMultipleM;
#if !ENABLEAUDIOEFFECT
        if([rdPlayer isPlaying]){
            [self playVideo:NO];
        }
        [self refreshRdPlayer:rdPlayer];
#endif
    }
    else if( slider == videoProgressSlider ){
        CGFloat current = videoProgressSlider.value*rdPlayer.duration;
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    }
    else if( slider == _transparencyVolumeSlider )
    {
        [self initPlayer];
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
    exportCurrentTime = kCMTimeZero;
    isExport = false;
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

#pragma mark- 功能区分界面
-(UIView *)functionalAreaView
{
    if( !_functionalAreaView )
    {
        _functionalAreaView = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight, kWIDTH, kHEIGHT - kPlayerViewHeight - kPlayerViewOriginX)];
        _functionalAreaView.backgroundColor = TOOLBAR_COLOR;
        
        [_functionalAreaView addSubview:self.typesettView ];
        [_functionalAreaView addSubview:self.toolBarView];
    }
    return _functionalAreaView;
}
#pragma mark- 功能
-( UIScrollView * )toolBarView
{
    if( !_toolBarView )
    {
        toolItems = [NSMutableArray array];
        {
            NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"风格",@"title",@(0),@"id", nil];
            [toolItems addObject:dic1];
        }
        {
            NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"字幕",@"title",@(1),@"id", nil];
            [toolItems addObject:dic1];
        }
        {
            NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"贴纸",@"title",@(RDAdvanceEditType_Sticker),@"id", nil];
            [toolItems addObject:dic1];
        }
        {
            NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"变声",@"title",@(3),@"id", nil];
            [toolItems addObject:dic1];
        }
        {
            NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"音乐",@"title",@(4),@"id", nil];
            [toolItems addObject:dic1];
        }
        {
            NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"背景",@"title",@(5),@"id", nil];
            [toolItems addObject:dic1];
        }
        _toolBarView =  [UIScrollView new];
        _toolBarView.frame = CGRectMake(0, _functionalAreaView.bounds.size.height - 60 - (iPhone_X ? 34 : 0), kWIDTH, 60 + (iPhone_X ? 34 : 0) );
        _toolBarView.showsVerticalScrollIndicator = NO;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        [_functionalAreaView addSubview:_toolBarView];
        int count = (toolItems.count>6)?toolItems.count:6;
        
        if( (count == 6) && (toolItems.count%2) == 0.0 )
        {
            count = 6;
        }
        __block float toolItemBtnWidth = kWIDTH/count;//_toolBarView.frame.size.height
        __block int iIndex = kWIDTH/toolItemBtnWidth + 1.0;
        __block float width = toolItemBtnWidth;
        toolItemBtnWidth = toolItemBtnWidth - ((toolItems.count > iIndex)?(toolItemBtnWidth/2.0/(iIndex)):0);
        __block float contentsWidth = 0;
        __block int   offset = (count - toolItems.count)/2;
        [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *title = [self->toolItems[idx] objectForKey:@"title"];
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.exclusiveTouch = YES;
            toolItemBtn.frame = CGRectMake((idx+offset) * toolItemBtnWidth , 0, toolItemBtnWidth, _toolBarView.frame.size.height);
            [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@默认_@3x", title] Type:@"png"];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@选中_@3x", title] Type:@"png"];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
            [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
            [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            
            if( [[toolItems[idx] objectForKey:@"id"] integerValue] == 0 )
                toolItemBtn.selected = YES;
            
            [_toolBarView addSubview:toolItemBtn];
            contentsWidth += toolItemBtnWidth;
        }];
        
        if( contentsWidth <= kWIDTH )
            contentsWidth = kWIDTH + 10;
        
        _toolBarView.contentSize = CGSizeMake(contentsWidth, 0);
    }
    return _toolBarView;
}
#pragma mark- 文字排版方式
-(UIView *)typesettView
{
    if( !_typesettView )
    {
        _typesettView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _functionalAreaView.frame.size.height - _toolBarView.frame.size.height)];
        [_typesettView addSubview:self.typesettScrollView ];
    }
    return _typesettView;
}


-( UIScrollView * )typesettScrollView
{
    if( !_typesettScrollView )
    {
        functionalItems = [NSMutableArray array];
        {
            NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"旋转文字", nil),@"title",@(RDDisplayTextType_Rotate),@"id", nil];
            [functionalItems addObject:dic2];
        }
        {
            NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"横排文字", nil),@"title",@(RDDisplayTextType_Horiz),@"id", nil];
            [functionalItems addObject:dic2];
        }
        {
            NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"竖排文字", nil),@"title",@(RDDisplyaTextType_Vertical),@"id", nil];
            [functionalItems addObject:dic2];
        }
        
        _typesettScrollView =  [UIScrollView new];
        _typesettScrollView.frame = CGRectMake( 30, ( _typesettView.frame.size.height - 44 )/2.0 - 44/2.0, kWIDTH - 60, 44);
        _typesettScrollView.showsVerticalScrollIndicator = NO;
        _typesettScrollView.showsHorizontalScrollIndicator = NO;
        float toolItemBtnWidth = (kWIDTH - 60)/(functionalItems.count);
        __block float contentsWidth = 0;
        __block float originX = 0;
        [functionalItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[functionalItems[idx] objectForKey:@"id"] integerValue];
            if (toolItemBtn.tag == 0) {
                toolItemBtn.selected = YES;
                originX = idx * toolItemBtnWidth;
            }
            toolItemBtn.exclusiveTouch = YES;
            toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, 0, toolItemBtnWidth, 44);
            [toolItemBtn addTarget:self action:@selector(clickfunctionalItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setTitle:[functionalItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            toolItemBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
            [_typesettScrollView addSubview:toolItemBtn];
            
            contentsWidth += toolItemBtnWidth;
        }];
        _typesettScrollView.contentSize = CGSizeMake(kWIDTH - 60, 0);
        
        selectedFunctionView = [[UIView alloc] initWithFrame:CGRectMake(originX + toolItemBtnWidth*5/6.0/2.0, 44 - 5, toolItemBtnWidth/6.0, 2)];
        selectedFunctionView.backgroundColor = Main_Color;
        [_typesettScrollView addSubview:selectedFunctionView];;
        selecteFunction = 0;
    }
    return _typesettScrollView;
}
#pragma mark- 编辑功能选择
-(void)CreateText
{
    if( textObjectArray != nil )
    {
        [textObjectArray enumerateObjectsUsingBlock:^(RDTextObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj = nil;
        }];
        [textObjectArray removeAllObjects];
        textObjectArray = nil;
    }
    textObjectArray = [NSMutableArray<RDTextObject*> new];
    
    NSString *fontName = [[UIFont systemFontOfSize:10] fontName];//@"Baskerville-BoldItalic";
    CMTime currentTime = CMTimeMake(0, 30);
    
    float Radian = 0;
    
    for (int i = 0; i < _strArrry.count; i++) {
        RDTextObject *textObject = [[RDTextObject alloc] init];
        textObject.strText = _strArrry[i];
        
        textObject.fontName = fontName;
        
        if( !isCustomize )
            textObject.textColor = [UIColor blackColor];
        else
            textObject.textColor = [UIColor whiteColor];
        
        if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
            textObject.textFontSize = [self getRandomNumber:31 to:50];
        else
            textObject.textFontSize = 35;
        
        if( (i > 0) && (currentDisdisplayTextType == RDDisplayTextType_Rotate) )
        {
            if( Radian == 0 )
                textObject.textRadian = [self getRandomNumber:-1 to:1]*(90.0/180.0*3.14);
            else if( Radian > 0 )
                textObject.textRadian = [self getRandomNumber:-1 to:0]*(90.0/180.0*3.14);
            else
                textObject.textRadian = [self getRandomNumber:0 to:1]*(90.0/180.0*3.14);
            if( (textObject.strText.length > 2) || ( textObject.textRadian < 0 ) )
            {
                if( textObject.textRadian != 0 )
                    Radian = textObject.textRadian;
                else
                {
                    textObject.textFontSizeSpeed = ((float)[self getRandomNumber:-Amplification to:Amplification])/100.0;
                }
            }
            else
            {
                if( textObject.textRadian > 0 )
                    textObject.textRadian = 0;
                else
                {
                   textObject.textFontSizeSpeed = ((float)[self getRandomNumber:-Amplification to:Amplification])/100.0;
                }
            }
            
            if( textObject.textRadian > 0 )
            {
                float width = 0;
                int fontSize = 0;
                for (int j = 31; width < 375; j++) {
                    fontSize = j;
                    UIFont *font = [UIFont fontWithName:textObject.fontName size:j];
                    CGSize size = [textObject.strText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT/*MAXFLOAT*/)options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName : font} context:nil].size;
                    width = size.width;
                }
                
                textObject.textFontSize = fontSize - 1;
            }
        }
        textObject.startTime = currentTime;
        
        if( _strTimeRangeArray.count > 0 )
        {
            textObject.AnimationTime = _strTimeRangeArray[i].AnimationTime;
            
            textObject.startTime = _strTimeRangeArray[i].startTime;
            textObject.showTime = _strTimeRangeArray[i].showTime;
            
            if( textObject.textRadian != 0 )
                textObject.textRotationTime = CMTimeAdd( CMTimeSubtract(textObject.AnimationTime, textObject.startTime), currentTime);
        }
        else
        {
            if( textObject.textRadian != 0 )
                textObject.textRotationTime = CMTimeAdd(CMTimeMake(IntervalFPS+10, 30), currentTime);
            
            textObject.AnimationTime = CMTimeAdd(currentTime, CMTimeMake(10, 30));
            
            if( (i == 0) && ( !isCustomize ) )
                currentTime = CMTimeAdd(CMTimeMake(127, 30), currentTime);
            else
                currentTime = CMTimeAdd(CMTimeMake(IntervalFPS, 30), currentTime);
            
            textObject.showTime = currentTime;
        }
        [textObjectArray addObject:textObject];
    }
}
- (void)clickfunctionalItemBtn:(UIButton *)sender{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    currentDisdisplayTextType = sender.tag;
    
//    if( currentDisdisplayTextType ==RDDisplayTextType_Rotate )
//    {
        [self CreateText];
//    }
    
    [_typesettScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass: [UIButton class] ] )
        {
            UIButton * btn = (UIButton*)obj;
            if(btn.tag == sender.tag){
                btn.selected = YES;
            }else{
                btn.selected = NO;
            }
        }
    }];
    
    float toolItemBtnWidth = (kWIDTH - 60)/(functionalItems.count);
    
    selectedFunctionView.frame = CGRectMake(toolItemBtnWidth*5/6.0/2.0 + toolItemBtnWidth*sender.tag, selectedFunctionView.frame.origin.y, selectedFunctionView.frame.size.width, selectedFunctionView.frame.size.height);
    
    [self initTextLayerArray];
    [rdPlayer seekToTime:CMTimeMake(0.2, 1.0)];
    [rdPlayer filterRefresh:CMTimeMake(0.2, 1.0)];
}
#pragma mark- 功能分类
-(void)clickToolItemBtn:(UIButton *)sender{
    
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    selecteFunction = sender.tag;
    
     switch (sender.tag) {
         case 0://MARK:进入风格
         {
             titleView.hidden = NO;

             _soundEffectView.hidden = YES;
             _addEffects.hidden = YES;
             _toolBarView.hidden = NO;
             _typesettView.hidden = NO;
             _musicUI.hidden = YES;
             _textEditView.hidden = YES;
             _backgroundView.hidden = YES;
         }
             break;
         case 1://MARK:进入文字
         {
             titleView.hidden = YES;
             _soundEffectView.hidden = YES;
             _addEffects.hidden = YES;
             _typesettView.hidden = YES;
             _musicUI.hidden = YES;
             
             
             
             self.textEditView.hidden = NO;
             _textEditView.textObjectViewArray = textObjectArray;
             _textEditView.isRenewRotate = false;
             [_textEditView initScrollView];
             _backgroundView.hidden = YES;
         }
             break;
         case 6://MARK:进入贴纸
         {
             titleView.hidden = YES;
             _soundEffectView.hidden = YES;
             _typesettView.hidden = YES;
             _toolBarView.hidden = YES;
             _musicUI.hidden = YES;
             _textEditView.hidden = YES;
             
             [self initThumbImageVideoCore];
             self.addEffects.hidden = NO;
             _addEffectsByTimeline.thumbnailCoreSDK = rdPlayer;
             _addEffectsByTimeline.exportSize = exportVideoSize;
             _addEffectsByTimeline.currentEffect = selecteFunction;
             _addEffectsByTimeline.currentTimeLbl.text = @"0.00";
             _backgroundView.hidden = YES;
             _albumTitleView.hidden = YES;
             [_addEffects addSubview:self.addEffectsOpe];
         }
             break;
             case 3://MARK:进入变声
         {
             _musicUI.hidden = YES;
             _typesettView.hidden = YES;
             _addEffects.hidden = YES;
             self.soundEffectView.hidden = NO;
             _textEditView.hidden = YES;
             _backgroundView.hidden = YES;
         }
             break;
         case 4://MARK:进入音乐
         {
             self.musicUI.hidden = NO;
             _soundEffectView.hidden = YES;
             _addEffects.hidden = YES;
             _typesettView.hidden = YES;
             _textEditView.hidden = YES;
             _backgroundView.hidden = YES;
         }
             break;
         case 5://MARK:进入背景
         {
             _soundEffectView.hidden = YES;
             _addEffects.hidden = YES;
             _typesettView.hidden = YES;
             _musicUI.hidden = YES;
             _textEditView.hidden = YES;
             self.backgroundView.hidden = NO;
             
         }
             break;
     }
    [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == sender.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

#pragma mark- 变声
- (UIView *)soundEffectView {
    if (!_soundEffectView) {
        _soundEffectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _functionalAreaView.frame.size.height - _toolBarView.frame.size.height)];
        _soundEffectView.backgroundColor = BOTTOM_COLOR;
        [_functionalAreaView addSubview:_soundEffectView];
        
        soundEffectScrollView           = [UIScrollView new];
        soundEffectScrollView.frame     = CGRectMake(0, 5, _soundEffectView.frame.size.width, (iPhone4s ? 70 : (kWIDTH>320 ? 100 : 80)));
        soundEffectScrollView.backgroundColor                   = BOTTOM_COLOR;
        soundEffectScrollView.showsHorizontalScrollIndicator    = NO;
        soundEffectScrollView.showsVerticalScrollIndicator      = NO;
        [_soundEffectView addSubview:soundEffectScrollView];
        WeakSelf(self);
        
        
        soundEffectArray = [NSArray arrayWithObjects:@"自定义", @"原音", @"男声", @"女声", @"怪兽", @"卡通", @"回声", @"混响", @"室内", @"舞台", @"KTV", @"厂房", @"竞技场", @"电音", nil];
        
        [soundEffectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(strongSelf->soundEffectScrollView.frame.size.height - 15)+10, 0, (strongSelf->soundEffectScrollView.frame.size.height - 25), strongSelf->soundEffectScrollView.frame.size.height)];
            item.backgroundColor = [UIColor clearColor];
            item.fontSize       = 12;
            item.type           = 4;
            item.delegate       = strongSelf;
            item.selectedColor  = Main_Color;
            item.normalColor    = UIColorFromRGB(0x888888);
            item.cornerRadius   = 3.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor   = [UIColor clearColor];
            item.itemIconView.image = [RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"jianji/VoiceFXIcon/剪辑-音效-%@_", obj]];
            item.itemTitleLabel.text            = RDLocalizedString(obj, nil);
            item.tag                            = idx + 1;
            item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            [strongSelf->soundEffectScrollView addSubview:item];
            [item setSelected:(idx == strongSelf->selectedSoundEffectIndex+1 ? YES : NO)];
        }];
        
        soundEffectScrollView.contentSize = CGSizeMake(soundEffectArray.count * (soundEffectScrollView.frame.size.height - 15)+20, soundEffectScrollView.frame.size.height);
        _soundEffectView.hidden = YES;
    }
    return _soundEffectView;
}
#pragma mark- ScrollViewChildItemDelegate  配乐 变声
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item
{
    __weak typeof(self) myself = self;
    if(item.type == 1){//MARK:配乐
        dispatch_async(dispatch_get_main_queue(), ^{
            [RDSVProgressHUD dismiss];
            [mvMusicArray removeAllObjects];
            mvMusicArray = nil;
#if !ENABLEAUDIOEFFECT
            if([rdPlayer isPlaying]){
                [myself playVideo:NO];
            }
#endif
            NSString *urlstr = nil;
            NSString *filePath = nil;
            BOOL enableLocalMusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.enableLocalMusic;
            NSString *cloudMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL;
            NSInteger count = enableLocalMusic ? (cloudMusicResourceURL.length>0 ? 4 : 3) : (cloudMusicResourceURL.length>0 ? 3 : 2);
            if(item.tag >count){
                _musicVolumeSlider.enabled = YES;
                [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
                NSDictionary *itemDic = musicList[item.tag - (count + 1)];
                NSString *file = [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]];
                if([[itemDic allKeys] containsObject:@"cover"]){
                    urlstr     = itemDic[@"file"];
                    filePath = [kMusicPath stringByAppendingPathComponent:file];
                }else{
                    urlstr     = itemDic[@"url"];
                    filePath = [kMusicPath stringByAppendingPathComponent:[[urlstr lastPathComponent] stringByDeletingPathExtension]];
                }
                NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil] count];
                if(fileCount == 0){
                    if(item.downloading){
                        return;
                    }
                    CGRect rect = [item getIconFrame];
                    CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
                    ddprogress.progressColor = Main_Color;
                    ddprogress.progressWidth = 2.f;
                    ddprogress.progressBackgroundColor = [UIColor clearColor];
                    [item addSubview:ddprogress];
                    item.downloading = YES;
                    [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
                    [RDFileDownloader downloadFileWithURL:urlstr cachePath:filePath httpMethod:GET progress:^(NSNumber *numProgress) {
                        NSLog(@"%lf",[numProgress floatValue]);
                        [ddprogress setPercent:[numProgress floatValue]];
                    } finish:^(NSString *fileCachePath) {
                        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fileCachePath]];
                        double duration = CMTimeGetSeconds(asset.duration);
                        asset = nil;
                        if(duration == 0){
                            [[NSFileManager defaultManager] removeItemAtPath:fileCachePath error:nil];
                            NSLog(@"下载失败");
                            [hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                            [hud show];
                            [hud hideAfter:2];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                item.downloading = NO;
                                [ddprogress removeFromSuperview];
                            });
                        }else{
                            item.downloading = NO;
                            NSLog(@"下载完成");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [ddprogress removeFromSuperview];
                                if([self downLoadingMusicCount]>=1){
                                    return;
                                }
                                [item setSelected:YES];
                                [myself scrollViewChildItemTapCallBlock:item];
                            });
                        }
                    } fail:^(NSError *error) {
                        NSLog(@"下载失败");
                        [hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                        [hud show];
                        [hud hideAfter:2];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            item.downloading = NO;
                            [ddprogress removeFromSuperview];
                        });
                    }];
                }else{
                    if([self downLoadingMusicCount]>=1){
                        return;
                    }
                    _musicVolumeSlider.enabled = YES;
                    [item setSelected:YES];
                    if(item.tag == 1){
                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/拍摄_滤镜无选中_"];
                    }
                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
                    if(enableLocalMusic){
                        if(cloudMusicResourceURL.length>0){
                            ((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
                        }
                        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"本地", nil);
                    }else{
                        if(cloudMusicResourceURL.length>0){
                            ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
                        }
                    }
                    [item setSelected:YES];
                    selectMusicIndex = item.tag-1;
                    NSString *fileName = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil] firstObject];
                    _musicURL = [NSURL fileURLWithPath:[filePath stringByAppendingPathComponent:fileName]];
                    
                    _musicTimeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:_musicURL].duration);
                    [self refreshSound];
                }
            }
            else{
                switch (item.tag - 1) {
                    case 0:
                    {
                        yuanyinOn = !yuanyinOn;
                        if(yuanyinOn){
                            _musicVolumeSlider.value = _musicVolume;
                            item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/剪辑_原音开_"];
                            item.itemTitleLabel.text  = RDLocalizedString(@"原音开", nil);
                            //                            _musicVolumeSlider.enabled = (selectMusicIndex == 1 ? NO : yuanyinOn);
                        }else{
                            item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/剪辑_原音关_"];
                            item.itemTitleLabel.text  = RDLocalizedString(@"原音关", nil);
                            //                            _musicVolumeSlider.enabled = yuanyinOn;
                            //                            _musicVolumeSlider.value =  0;
                        }
                        //                        item.itemIconView.image = [item.itemIconView.image imageWithTintColor];
#if ENABLEAUDIOEFFECT
                        __weak typeof(self) weakSelf = self;
                        [scenes enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                            StrongSelf(self);
                            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (obj.identifier.length > 0) {
                                    [strongSelf.videoCoreSDK setVolume:(yuanyinOn ? (strongSelf->oldVolume) : 0.0) identifier:obj.identifier];
                                }
                            }];
                        }];
                        //                        [_videoCoreSDK setVolume:(yuanyinOn ? _musicVolume : 1.0) identifier:@"music"];
                        if (!rdPlayer.isPlaying) {
                            [self playVideo:YES];
                        }
#else
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self refreshRdPlayer:rdPlayer];
//                            [myself playVideo:YES];
                        });
#endif
                    }
                        break;
                    case 1:
                    {
                        _musicVolumeSlider.enabled = NO;
                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_无配乐_"];
                        item.itemIconView.image = [item.itemIconView.image imageWithTintColor];
                        item.itemTitleLabel.text  = RDLocalizedString(@"无配乐", nil);
                        
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
                        if(enableLocalMusic){
                            if(cloudMusicResourceURL.length>0){
                                ((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
                            }
                            ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"本地", nil);
                        }else{
                            if(cloudMusicResourceURL.length>0){
                                ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
                            }
                        }
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:2]) setSelected:YES];
                        _musicURL = nil;
                        _musicTimeRange = kCMTimeRangeZero;
                        selectMusicIndex = item.tag-1;
                        _musicVolumeSlider.enabled = NO;
#if ENABLEAUDIOEFFECT
                        [_videoCoreSDK setVolume:0.0 identifier:@"music"];
                        if (!rdPlayer.isPlaying) {
                            [self playVideo:YES];
                        }
#else
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [RDSVProgressHUD dismiss];
                            [self refreshRdPlayer:rdPlayer];
//                            [myself playVideo:YES];
                        });
#endif
                    }
                        break;
                    case 2:
                    {
                        [myself enter_localMusic:item];
                    }
                        break;
                    case 3:
                    {
                        [myself enter_cloudMusic:item];
                    }
                        break;
                    default:
                        break;
                }
            }
        });
    }
    else if (item.type == 4) {//MARK:变声
//        [self playVideo:NO];
        if (item.tag-2 != selectedSoundEffectIndex || item.tag-2 == -1) {
            [self playVideo:NO];
            
            [((ScrollViewChildItem *)[soundEffectScrollView viewWithTag:selectedSoundEffectIndex+2]) setSelected:NO];
            
            [item setSelected:YES];
            
            selectedSoundEffectIndex = item.tag-2;
            
            if (selectedSoundEffectIndex == -1)
                self.customSoundView.hidden = NO;
            else
            {
                _customSoundView.hidden = YES;
                [self initPlayer];
            }
            
        }
    }
}
- (void)refreshAudioEffect:(NSNumber *)enableAudioEffect {
    rdPlayer.enableAudioEffect = [enableAudioEffect boolValue];
    [rdPlayer build];
}

-(UIButton *)closeBtn
{
    if(  !_closeBtn )
    {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
        [_closeBtn addTarget:self action:@selector(close_Btn) forControlEvents:UIControlEventTouchUpInside];
        _closeBtn.backgroundColor = [UIColor clearColor];
        //收起
        UIImageView * imageView = [[UIImageView alloc] initWithFrame: CGRectMake((_closeBtn.frame.size.width-44)/2.0, 0, 44, _closeBtn.frame.size.height)];
        imageView.image = [RDHelpClass imageWithContentOfFile:@"MultiDifferent/收起"];
        [_closeBtn addSubview:imageView];
    }
    return _closeBtn;
}
-(void)close_Btn
{
    _customSoundView.hidden = YES;
}

- (UIView *)customSoundView {
    if (!_customSoundView) {
        _customSoundView = [[UIView alloc] initWithFrame:_soundEffectView.bounds];
        _customSoundView.backgroundColor = BOTTOM_COLOR;
        [_soundEffectView addSubview:_customSoundView];
        if (selectedSoundEffectIndex >= 0) {
            _customSoundView.hidden = YES;
        }
        
        [_customSoundView addSubview:self.closeBtn];
        
        UIImageView *soundEffectImage = [[UIImageView alloc] initWithFrame:CGRectMake(5, (_customSoundView.bounds.size.height - 44 - 30)/2.0 + 44, 30, 30)];
        soundEffectImage.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"编辑-变声-变调_@2x" Type:@"png"]];
        [_customSoundView addSubview:soundEffectImage];
        
        soundEffectSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(40, (_customSoundView.bounds.size.height - 44 - 20)/2.0 + 44, kWIDTH - 100, 20)];
        soundEffectSlider.backgroundColor = [UIColor clearColor];
        [soundEffectSlider setMaximumValue:250];
        [soundEffectSlider setMinimumValue:-150];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [soundEffectSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        soundEffectSlider.layer.cornerRadius = 2.0;
        soundEffectSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [soundEffectSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [soundEffectSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [soundEffectSlider setValue:logf(oldPitch*1200)/logf(2.0)];
        [soundEffectSlider addTarget:self action:@selector(soundEffectScrub) forControlEvents:UIControlEventValueChanged];
        [soundEffectSlider addTarget:self action:@selector(soundEffectEndScrub1) forControlEvents:UIControlEventTouchUpInside];
        [soundEffectSlider addTarget:self action:@selector(soundEffectEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_customSoundView addSubview:soundEffectSlider];
        
        soundEffectLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 60 , soundEffectSlider.frame.origin.y, 60, 20)];
        soundEffectLabel.textAlignment = NSTextAlignmentCenter;
        soundEffectLabel.textColor = UIColorFromRGB(0xffffff);
        soundEffectLabel.font = [UIFont systemFontOfSize:10];
        soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
        [_customSoundView addSubview:soundEffectLabel];
    }
    return _customSoundView;
}
//变调强度 滑动进度条
- (void)soundEffectScrub{
    [self playVideo:NO];
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pitch];
}

- (void)soundEffectEndScrub1{
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    __weak typeof(self) weakSelf = self;
    oldPitch = pitch;
    [self initPlayer];
}

- (void)soundEffectEndScrub{
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    __weak typeof(self) weakSelf = self;
    oldPitch = pitch;
    if (!rdPlayer.isPlaying) {
        [self playVideo:YES];
    }

}

#pragma mark- addEffectsByTimeline
-(UIView*)addEffects
{
    if( !_addEffects )
    {
        _addEffects =  [[UIView alloc] initWithFrame:CGRectMake(0, playerView.frame.size.height  + playerView.frame.origin.y, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight)];
        
        [_addEffects addSubview:self.addEffectsByTimelineView];
        [self.view addSubview:_addEffects];
    }
    return _addEffects;
}

- (UIView *)addEffectsByTimelineView{
    if(!_addEffectsByTimelineView){
        _addEffectsByTimelineView = [UIView new];
        _addEffectsByTimelineView.frame = CGRectMake(0, 0, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight);
        _addEffectsByTimelineView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [_addEffectsByTimelineView addSubview:self.addEffectsByTimeline];
////        [self.view addSubview:_addEffectsByTimelineView];
//        _addEffectsByTimelineView.hidden  =YES;
    }
    return _addEffectsByTimelineView;
}
- (RDAddEffectsByTimeline *)addEffectsByTimeline {
    if (!_addEffectsByTimeline) {
        float height = kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight;
        _addEffectsByTimeline = [[RDAddEffectsByTimeline alloc] initWithFrame:CGRectMake(0,0, kWIDTH, height)];
        [_addEffectsByTimeline prepareWithEditConfiguration:((RDNavigationViewController *)self.navigationController).editConfiguration
                                                     appKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 exportSize:exportVideoSize
                                                 playerView:playerView
                                                        hud:hud];
        _addEffectsByTimeline.delegate = self;
    }
    return _addEffectsByTimeline;
}
-( UIView * )addEffectsOpe
{
    if( !_addEffectsOpe )
    {
        _addEffectsOpe = [[UIView alloc] initWithFrame:CGRectMake(0, _addEffects.frame.size.height - kToolbarHeight, kWIDTH, kToolbarHeight)];
        toolbarTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
        toolbarTitleLbl.textAlignment = NSTextAlignmentCenter;
        toolbarTitleLbl.font = [UIFont boldSystemFontOfSize:17];
        toolbarTitleLbl.textColor = [UIColor whiteColor];
        toolbarTitleLbl.text = RDLocalizedString(@"贴纸", nil);
        [_addEffectsOpe addSubview:toolbarTitleLbl];
        
        cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        [_addEffectsOpe addSubview:cancelBtn];
        
        _toolbarTitlefinishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [_toolbarTitlefinishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_toolbarTitlefinishBtn addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
        [_addEffectsOpe addSubview:_toolbarTitlefinishBtn];
        
    }
    return _addEffectsOpe;
}
/**点击返回按键*/
- (void)back:(UIButton *)sender{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    if ((_isAddingMaterialEffect || _isEdittingMaterialEffect)
        && (selecteFunction == RDAdvanceEditType_Subtitle
            || selecteFunction == RDAdvanceEditType_Sticker
            || selecteFunction == RDAdvanceEditType_Dewatermark
            || selecteFunction == RDAdvanceEditType_Collage
            || selecteFunction == RDAdvanceEditType_Doodle
            || selecteFunction == RDAdvanceEditType_Multi_track
            || selecteFunction == RDAdvanceEditType_Sound))
    {
        toolbarTitleLbl.hidden = NO;
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        
        if (_isAddingMaterialEffect) {
            [_addEffectsByTimeline cancelEffectAction:nil];
        }else {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
        }
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        return;
    }
    //MARK:贴纸
    if (selecteFunction == RDAdvanceEditType_Sticker) {
        
        [self clickToolItemBtn:[self.toolBarView viewWithTag:0]];
        
        [_addEffectsByTimeline discardEdit];
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        
        [stickers removeAllObjects];
        [stickerFiles removeAllObjects];
        for(RDCaptionRangeViewFile *file in oldStickerFiles){
            RDCaption *ppcaption= file.caption;
            if(ppcaption){
                [stickers addObject:ppcaption];
            }
            [stickerFiles addObject:file];
        }
        [self refreshCaptions];
        
        __weak typeof(self) myself = self;
        [rdPlayer seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            [myself playVideo:YES];
        }];
        return;
    }
    
}
- (void)tapPublishBtn{
    //MARK:贴纸
    if(selecteFunction == RDAdvanceEditType_Sticker){
        if(_isAddingMaterialEffect || _isEdittingMaterialEffect){
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            CMTime time = [rdPlayer currentTime];
            [rdPlayer filterRefresh:time];
            self.isAddingMaterialEffect = NO;
            self.isEdittingMaterialEffect = NO;
            return;
        }
        
        [self clickToolItemBtn:[self.toolBarView viewWithTag:0]];
        
        [_addEffectsByTimeline discardEdit];
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        
        oldStickerFiles = [stickerFiles mutableCopy];
        
        __weak typeof(self) myself = self;
        [rdPlayer seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            [myself playVideo:YES];
        }];
        return;
    }
}

- (UIView *)addedMaterialEffectView {
    if (!_addedMaterialEffectView) {
        _addedMaterialEffectView = [[UIView alloc] initWithFrame:CGRectMake(64, 0, kWIDTH - 64*2, 44)];
        _addedMaterialEffectView.hidden = YES;
        [_addEffectsOpe addSubview:_addedMaterialEffectView];
        
        UILabel *addedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, (_addedMaterialEffectView.frame.size.height - 44)/2.0, 64, 44)];
        addedLbl.text = RDLocalizedString(@"已添加", nil);
        addedLbl.textColor = UIColorFromRGB(0x888888);
        addedLbl.font = [UIFont systemFontOfSize:14.0];
        [_addedMaterialEffectView addSubview:addedLbl];
        
        addedMaterialEffectScrollView =  [UIScrollView new];
        addedMaterialEffectScrollView.frame = CGRectMake(64, (_addedMaterialEffectView.frame.size.height - 44)/2.0, _addedMaterialEffectView.bounds.size.width - 64, 44);
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
    switch (selecteFunction) {
        case RDAdvanceEditType_Sticker:
            _addEffectsOpe.hidden  = YES;
            break;
        default:
            break;
    }
    
    _addedMaterialEffectView.hidden = YES;
}

- (void)addingStickerWithDuration:(float)addingDuration  captionId:(int ) captionId{
    [self refreshCaptions];
    addingMaterialDuration = addingDuration;
    self.isAddingMaterialEffect = YES;
    _addEffectsOpe.hidden  = NO;
    if(![rdPlayer isPlaying]){
//        [self playVideo:YES];
    }
    [self addedMaterialEffectItemBtnAction:[addedMaterialEffectScrollView viewWithTag:captionId]];
}

- (void)cancelMaterialEffect {
    self.isCancelMaterialEffect = YES;
    [self deleteMaterialEffect];
    self.isCancelMaterialEffect = NO;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    
    toolbarTitleLbl.hidden = YES;
    
    if(stickers.count > 0)
        _addedMaterialEffectView.hidden = NO;
    else
        toolbarTitleLbl.hidden = NO;
    
    _addEffectsOpe.hidden  = NO;
}

- (void)deleteMaterialEffect {
    [self playVideo:NO];
    if (!_isCancelMaterialEffect) {
        seekTime = rdPlayer.currentTime;
    }
    
    if (_isCancelMaterialEffect) {
        seekTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start) + _addEffectsByTimeline.trimmerView.piantouDuration,TIMESCALE);
    }
    BOOL suc = [_addEffectsByTimeline.trimmerView deletedcurrentCaption];
    BOOL isAddedMaterialEffectScrollViewShow = NO;
    if(suc){
        NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
        switch (selecteFunction) {
            case RDAdvanceEditType_Sticker:
            {
                [stickers removeAllObjects];
                [stickerFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    RDCaption *subtitle = view.file.caption;
                    [stickers addObject:subtitle];
                    [stickerFiles addObject:view.file];
                }
                isAddedMaterialEffectScrollViewShow = (stickers.count > 0);
                [self refreshCaptions];
                CMTime time = [rdPlayer currentTime];
                [rdPlayer filterRefresh:time];
            }
                break;
            default:
                break;
        }
    }else{
        NSLog(@"删除失败");
    }
    float progress = CMTimeGetSeconds(seekTime)/rdPlayer.duration;
    [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
    [self refreshAddMaterialEffectScrollView];
    selectedMaterialEffectItemIV.hidden = YES;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    self.isCancelMaterialEffect = NO;
    
    if (isAddedMaterialEffectScrollViewShow) {
        _addedMaterialEffectView.hidden = NO;
        toolbarTitleLbl.hidden = YES;
    }else {
        _addedMaterialEffectView.hidden = YES;
        toolbarTitleLbl.hidden = NO;
    }
    _addEffectsOpe.hidden  = NO;
}

- (void)refreshCaptions {
    rdPlayer.captions = stickers;
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
    //    if (!cancelBtn.selected) {
    //        isModifiedMaterialEffect = YES;
    //    }
    if (!_isCancelMaterialEffect) {
        seekTime = rdPlayer.currentTime;
    }
    float time = CMTimeGetSeconds(seekTime);
    if (time >= rdPlayer.duration) {
        seekTime = kCMTimeZero;
    }
    switch (selecteFunction) {
        case RDAdvanceEditType_Sticker:
        {
            if (!stickers) {
                stickers = [NSMutableArray array];
            }
            if (!stickerFiles) {
                stickerFiles = [NSMutableArray array];
            }
            seekTime = kCMTimeZero;
            [self refreshMaterialEffectArray:stickers newArray:newEffectArray];
            [self refreshMaterialEffectArray:stickerFiles newArray:newFileArray];
            [self refreshCaptions];
            //            CMTime time = [rdPlayer currentTime];
            //            [rdPlayer filterRefresh:time];
        }
            break;
        default:
            break;
    }
    [self refreshAddMaterialEffectScrollView];
    if (isSaveEffect) {
        [_addEffectsByTimeline.syncContainer removeFromSuperview];
        selectedMaterialEffectItemIV.hidden = YES;
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
    }
    if (!_isEdittingMaterialEffect) {
        if (newEffectArray.count == 0) {
            _addedMaterialEffectView.hidden = YES;
            toolbarTitleLbl.hidden = NO;
        }else {
            _addedMaterialEffectView.hidden = NO;
            toolbarTitleLbl.hidden = YES;
        }
    }
    _addEffectsOpe.hidden  = NO;
}

- (void)refreshMaterialEffectArray:(NSMutableArray *)oldArray newArray:(NSMutableArray *)newArray {
    [oldArray removeAllObjects];
    [newArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [oldArray addObject:obj];
    }];
}

- (void)pushOtherAlbumsVC:(UIViewController *)otherAlbumsVC {
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
        self.addedMaterialEffectView.hidden = NO;
    
    [addedMaterialEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
    BOOL isNetSource = ((RDNavigationViewController *)self.navigationController).editConfiguration.subtitleResourceURL.length>0;
    NSInteger index = 0;
    for (int i = 0; i < arr.count; i++) {
        CaptionRangeView *view = arr[i];
        BOOL isHasMaterialEffect = NO;
        switch (selecteFunction) {
            case RDAdvanceEditType_Sticker:
                if (view.file.caption) {
                    isHasMaterialEffect = YES;
                }
                break;
            default:
                break;
        }
        if (_isAddingMaterialEffect && view == _addEffectsByTimeline.trimmerView.currentCaptionView) {
            index = view.file.captionId;
        }
        if (isHasMaterialEffect) {
            RDAddItemButton *addedItemBtn = [RDAddItemButton buttonWithType:UIButtonTypeCustom];
            if( (selecteFunction == RDAdvanceEditType_Subtitle) || (selecteFunction == RDAdvanceEditType_Sticker) )
                addedItemBtn.frame = CGRectMake((view.file.captionId-1) * 50, (44 - 40)/2.0, 40, 40);
            else
                addedItemBtn.frame = CGRectMake(i * 50, (44 - 40)/2.0, 40, 40);
            if (selecteFunction == RDAdvanceEditType_Subtitle || selecteFunction == RDAdvanceEditType_Sticker) {
                UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0/2.0, (40 - 25.0)/2.0, 25.0, 25.0)];
                if(isNetSource){
                    if (view.file.netCover.length > 0) {
                        if( selecteFunction == RDAdvanceEditType_Sticker )
                        {
                            imageView = [RDYYAnimatedImageView new];
                            [imageView stopAnimating];
                            imageView.frame = CGRectMake(5.0/2.0, (40 - 25.0)/2.0, 25.0, 25.0);
                            imageView.yy_imageURL = [NSURL URLWithString:view.file.netCover];
                        }
                        else
                            [imageView rd_sd_setImageWithURL:[NSURL URLWithString:view.file.netCover]];
                    }else {
                        imageView.image = [RDHelpClass imageWithContentOfFile:@"subtitleCover"];
                    }
                }else{
                    NSString *iconPath;
                    if (selecteFunction == RDAdvanceEditType_Subtitle) {
                        iconPath = [NSString stringWithFormat:@"%@/%@.png",kSubtitleIconPath,view.file.caption.imageName];
                    }else {
                        iconPath = [NSString stringWithFormat:@"%@/%@.png",kStickerIconPath,view.file.caption.imageName];
                    }
                    UIImage *image = [UIImage imageWithContentsOfFile:iconPath];
                    imageView.image = image;
                }
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [addedItemBtn addSubview:imageView];
            }
            addedItemBtn.tag = view.file.captionId;
            [addedItemBtn addTarget:self action:@selector(addedMaterialEffectItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
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
    if (selecteFunction == RDAdvanceEditType_Sticker && _isAddingMaterialEffect && !_isEdittingMaterialEffect) {
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
        toolbarTitleLbl.hidden = YES;
    }
    else
    {
        _addedMaterialEffectView.hidden = YES;
        toolbarTitleLbl.hidden = NO;
    }
}

- (void)addedMaterialEffectItemBtnAction:(UIButton *)sender {
    if (!selectedMaterialEffectItemIV.hidden && sender.tag == selectedMaterialEffectIndex)
        return;
    
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    seekTime = rdPlayer.currentTime;
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
    toolbarTitleLbl.hidden = YES;
    _addedMaterialEffectView.hidden = NO;
    self.isEdittingMaterialEffect = YES;
    self.isAddingMaterialEffect = NO;
    CMTime time = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
    [rdPlayer filterRefresh:time];
    _addEffectsByTimeline.trimmerView.isJumpTail = false;
}
#pragma mark- 字幕、特效、配音截图
-(void)loadTrimmerViewThumbImage {
    @autoreleasepool {
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        thumbTimes=[[NSMutableArray alloc] init];
        Float64 duration;
        Float64 start;
        duration = thumbImageVideoCore.duration;
        start = (duration > 2 ? 1 : (duration-0.05));
        [thumbTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(start,TIMESCALE)]];
        NSInteger actualFramesNeeded = duration/2;
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
                    case RDAdvanceEditType_Sticker://MARK:贴纸
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:image
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:stickers
                                                           oldFileArray:oldStickerFiles];
                        if (stickers.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
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
                case RDAdvanceEditType_Sticker:
                case RDAdvanceEditType_Dewatermark:
                case RDAdvanceEditType_Collage:
                case RDAdvanceEditType_Doodle:
                case RDAdvanceEditType_Multi_track:
                case RDAdvanceEditType_Sound:
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
                [RDSVProgressHUD dismiss];
            }
        }];
    }
}
#pragma mark- 音乐
-(UIView*) musicUI
{
    if( !_musicUI )
    {
        _musicUI = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _functionalAreaView.frame.size.height - _toolBarView.frame.size.height)];
        [_musicUI addSubview:self.musicScrollView];
        [_functionalAreaView addSubview:_musicUI ];
        _musicUI.hidden = YES;
    }
    return _musicUI;
}

-(UIScrollView*)musicScrollView
{
    if( !_musicScrollView )
    {
        _musicScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _musicUI.frame.size.width, _musicUI.frame.size.height)];
        self.musicView.hidden = NO;
        _musicScrollView.contentSize = CGSizeMake(_musicUI.frame.size.width, 0);
    }
    return _musicScrollView;
}
- (UIView *)musicView{
    if(!_musicView){
        _musicView = [UIView new];
        
        if( _musicScrollView.frame.size.height < (70+50) )
            _musicView.frame = CGRectMake(0, 0, _musicUI.frame.size.width, 70+50);
        else
            _musicView.frame = CGRectMake(0, 0, _musicUI.frame.size.width, _musicScrollView.frame.size.height);
        _musicView.backgroundColor = BOTTOM_COLOR;
        [_musicScrollView addSubview:_musicView];
        
        _musicVolumeLabel = [UILabel new];
        _musicVolumeLabel.frame = CGRectMake(0, 0, 50, 31);
        _musicVolumeLabel.textAlignment = NSTextAlignmentCenter;
        _musicVolumeLabel.backgroundColor = [UIColor clearColor];
        _musicVolumeLabel.font = [UIFont boldSystemFontOfSize:10];
        _musicVolumeLabel.textColor = [UIColor whiteColor];
        _musicVolumeLabel.text = RDLocalizedString(@"配乐", nil);
        
        [_musicView addSubview:self.musicVolumeLabel];
        //        [_musicView addSubview:self.videoVolumelabel];
        [_musicView addSubview:self.musicVolumeSlider];
        
        [_musicView addSubview: self.musicChildsView];
        
        _dubbingLabel = [UILabel new];
        _dubbingLabel.frame = CGRectMake(kWIDTH/2.0 - 5 , 0, 50, 31);
        //            [_dubbingItemBtn addTarget:self action:@selector(clickDubbingItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        _dubbingLabel.layer.cornerRadius = 15.0;
        _dubbingLabel.layer.masksToBounds = YES;
        _dubbingLabel.textAlignment = NSTextAlignmentCenter;
        _dubbingLabel.backgroundColor = [UIColor clearColor];
        _dubbingLabel.font = [UIFont boldSystemFontOfSize:10];
        _dubbingLabel.textColor = [UIColor whiteColor];
        _dubbingLabel.text = RDLocalizedString(@"原音", nil);
        [_musicView addSubview:_dubbingLabel];
        [_musicView addSubview:self.dubbingVolumeSlider];
        
        _musicView.hidden = YES;
    }
    return _musicView;
}

//原音量比例调节
- (RDZSlider *)dubbingVolumeSlider{
    if(!_dubbingVolumeSlider){
        _dubbingVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50 + kWIDTH/2.0 - 10, 0, kWIDTH/2.0-50, 31)];
        _dubbingVolumeSlider.alpha = 1.0;
        _dubbingVolumeSlider.backgroundColor = [UIColor clearColor];
        [_dubbingVolumeSlider setMaximumValue:1];
        [_dubbingVolumeSlider setMinimumValue:0];
        [_dubbingVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_dubbingVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_dubbingVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        [_dubbingVolumeSlider setValue:(_dubbingVolume/volumeMultipleM)];
        [_dubbingVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_dubbingVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_dubbingVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_dubbingVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        //        _musicVolumeSlider.enabled = (selectMusicIndex == 1 ? NO : yuanyinOn);
        _dubbingVolumeSlider.enabled = YES;
    }
    return _dubbingVolumeSlider;
}

//配乐音量比例调节
- (RDZSlider *)musicVolumeSlider{
    if(!_musicVolumeSlider){
        _musicVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, 0, kWIDTH/2.0 - 50 - 10, 31)];
        _musicVolumeSlider.alpha = 1.0;
        _musicVolumeSlider.backgroundColor = [UIColor clearColor];
        [_musicVolumeSlider setMaximumValue:1];
        [_musicVolumeSlider setMinimumValue:0];
        [_musicVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_musicVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_musicVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        [_musicVolumeSlider setValue:(_musicVolume/volumeMultipleM)];
        [_musicVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_musicVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_musicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_musicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        //        _musicVolumeSlider.enabled = (selectMusicIndex == 1 ? NO : yuanyinOn);
        _musicVolumeSlider.enabled = ( selectMusicIndex > 1 )? YES : NO ;
    }
    return _musicVolumeSlider;
}

//音乐
- (UIScrollView *)musicChildsView{
    if(!_musicChildsView){
        _musicChildsView = [UIScrollView new];
        _musicChildsView.frame = CGRectMake(0,  ((kWIDTH>320 ? 44 : 39) + (_musicView.frame.size.height - (kWIDTH>320 ? 54 : 44) - (iPhone4s ? 60 : (kWIDTH>320 ? 80 :  (LastIphone5?70:65))))/2.0) - 5 , _musicView.frame.size.width, (iPhone4s ? 60 : (kWIDTH>320 ? 80 : (LastIphone5?70:65))));
        _musicChildsView.backgroundColor = [UIColor clearColor];
        _musicChildsView.showsHorizontalScrollIndicator = NO;
        _musicChildsView.showsVerticalScrollIndicator = NO;
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kMusicFolder]){
            [fileManager createDirectoryAtPath:kMusicFolder withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if(![fileManager fileExistsAtPath:kMusicIconPath]){
            [fileManager createDirectoryAtPath:kMusicIconPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if(![fileManager fileExistsAtPath:kMusicPath]){
            [fileManager createDirectoryAtPath:kMusicPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
        NSString *musicListPath = [kMusicFolder stringByAppendingPathComponent:@"musiclist.plist"];
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.musicResourceURL.length>0){
            musicList = [[NSArray arrayWithContentsOfFile:musicListPath] mutableCopy];
        }else{
            musicList = nil;
        }
        BOOL enableLocalMusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.enableLocalMusic;
        
        NSInteger count = enableLocalMusic ? (((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL.length>0 ? 4 : 3) : (((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL.length>0 ? 3 : 2);
        for(NSInteger idx = 0;idx<count;idx ++){
            ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(_musicChildsView.frame.size.height - 15)+10, 0, (_musicChildsView.frame.size.height - 25), _musicChildsView.frame.size.height)];
            item.backgroundColor = [UIColor clearColor];
            item.fontSize = 12;
            item.type = 1;
            item.delegate = self;
            item.selectedColor = Main_Color;
            item.normalColor   = UIColorFromRGB(0x888888);
            item.cornerRadius = item.frame.size.width/2.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor = [UIColor clearColor];
            [_musicChildsView addSubview:item];
            item.tag = idx + 1;
            [item setSelected:(idx == (selectMusicIndex) ? YES : NO)];
            oldMusicIndex = selectMusicIndex;
            switch (idx) {
                case 0:
                {
                    if(!yuanyinOn){
                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/剪辑_原音关_"];
                        item.itemTitleLabel.text  = RDLocalizedString(@"原音关", nil);
                    }else{
                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/剪辑_原音开_"];
                        item.itemTitleLabel.text  = RDLocalizedString(@"原音开", nil);
                    }
                }
                    break;
                case 1:
                {
                    item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_无配乐_"];
                    item.itemTitleLabel.text  = RDLocalizedString(@"无配乐", nil);
                }
                    break;
                case 2:
                {
                    item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_本地_"];
                    if ( selectMusicIndex == item.tag - 1) {
                        [item startScrollTitle];
                    }else {
                        item.itemTitleLabel.text  = RDLocalizedString(@"本地", nil);
                    }
                }
                    break;
                case 3:
                {
                    item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_云音乐_"];
                    if ( selectMusicIndex == item.tag - 1) {
                        [item startScrollTitle];
                    }else {
                        item.itemTitleLabel.text  = RDLocalizedString(@"云音乐", nil);
                    }
                }
                    break;
                default:
                    break;
            }
            item.itemIconView.image = [item.itemIconView.image imageWithTintColor];
        }
        
        BOOL hasNewMusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.newmusicResourceURL.length>0;
        BOOL hasmusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.musicResourceURL.length>0 || ((RDNavigationViewController *)self.navigationController).editConfiguration.newmusicResourceURL.length>0;
        __block NSArray *musicnetArr ;
        if(musicList.count>0){
            if([lexiu currentReachabilityStatus] != RDNotReachable){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios",@"type", nil];
                    NSString *musicUrl = hasNewMusic ? ((RDNavigationViewController *)self.navigationController).editConfiguration.newmusicResourceURL : ((RDNavigationViewController *)self.navigationController).editConfiguration.musicResourceURL;
                    if(hasmusic){
                        NSDictionary *dic;
                        if(hasNewMusic){
                            dic = [RDHelpClass getNetworkMaterialWithType:@"bk_music"
                                                                   appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                                  urlPath:musicUrl];
                        }else{
                            dic = [RDHelpClass updateInfomationWithJson:params andUploadUrl:musicUrl];
                        }
                        BOOL suc = hasNewMusic ? [dic[@"code"] intValue] == 0 : [[dic objectForKey:@"state"] boolValue];
                        if(suc){
                            NSMutableArray *resultList = hasNewMusic ? dic[@"data"]: [[dic objectForKey:@"result"] objectForKey:@"bgmusic"];
                            musicnetArr = resultList;
                            if(resultList){
                                unlink([musicListPath UTF8String]);
                                BOOL suc = [resultList writeToFile:musicListPath atomically:YES];
                                if (!suc) {
                                    NSLog(@"写入失败");
                                }
                            }
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self initMusicChildItem];
                        });
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self initMusicChildItem];
                        });
                    }
                });
            }else{
                [self initMusicChildItem];
            }
        }
        else{
            if([lexiu currentReachabilityStatus] != RDNotReachable){
                if(hasmusic){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSString *musicUrl = hasNewMusic ? ((RDNavigationViewController *)self.navigationController).editConfiguration.newmusicResourceURL : ((RDNavigationViewController *)self.navigationController).editConfiguration.musicResourceURL;
                        
                        NSDictionary *dic;
                        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios",@"type", nil];
                        if(hasNewMusic){
                            dic = [RDHelpClass getNetworkMaterialWithType:@"bk_music"
                                                                   appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                                  urlPath:musicUrl];
                        }
                        else{
                            dic = [RDHelpClass updateInfomationWithJson:params andUploadUrl:musicUrl];
                        }
                        
                        BOOL suc = hasNewMusic ? [dic[@"code"] intValue] == 0 : [[dic objectForKey:@"state"] boolValue];
                        if(suc){
                            NSMutableArray *resultList = hasNewMusic ? dic[@"data"] : [[dic objectForKey:@"result"] objectForKey:@"bgmusic"];
                            musicList = resultList;
                            
                            if(resultList){
                                unlink([musicListPath UTF8String]);
                                BOOL suc = [resultList writeToFile:musicListPath atomically:YES];
                                if (!suc) {
                                    NSLog(@"写入失败");
                                }
                            }
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self initMusicChildItem];
                        });
                    });
                }else{
                    [self initMusicChildItem];
                }
            }else{
                [hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [hud show];
                [hud hideAfter:2];
                [self initMusicChildItem];
            }
        }
    }
    return _musicChildsView;
}

- (void)initMusicChildItem{
    NSInteger count = 0;
    BOOL enableLocalMusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.enableLocalMusic;
    NSInteger index = enableLocalMusic ? (((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL.length>0 ? 4 : 3) : (((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL.length>0 ? 3 : 2);
    
    BOOL hasNewMusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.newmusicResourceURL.length>0;
    
    UIImage *defaultImage = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐默认"];
    for(NSInteger idx = index;idx<musicList.count + index;idx ++){
        
        NSDictionary *itemDic = musicList[idx - index];
        NSString *title = itemDic[@"name"];
        NSString *iconUrl = hasNewMusic ? itemDic[@"cover"] : itemDic[@"icon"];
        NSString *musicPath = [kMusicPath stringByAppendingString:[(hasNewMusic ? itemDic[@"file"] : itemDic[@"url"]) lastPathComponent]];
        NSString *imageName = [[iconUrl lastPathComponent] stringByDeletingPathExtension];
        NSString *itemIconPath = [kMusicIconPath stringByAppendingString:[NSString stringWithFormat:@"%@.png",imageName]];
        UIImage *image = [UIImage imageWithContentsOfFile:itemIconPath];
        if (!image) {
            image = defaultImage;
        }
        if(image){
            ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(_musicChildsView.frame.size.height - 15)+10, 0, (_musicChildsView.frame.size.height - 25), _musicChildsView.frame.size.height)];
            item.backgroundColor = [UIColor clearColor];
            item.fontSize = 12;
            item.type = 1;
            item.delegate = self;
            item.selectedColor = Main_Color;
            item.normalColor   = UIColorFromRGB(0x888888);
            item.cornerRadius = item.frame.size.width/2.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
            [_musicChildsView addSubview:item];
            item.tag = idx + 1;
            [item setSelected:(idx == (selectMusicIndex) ? YES : NO)];
            if(hasNewMusic){
                [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:iconUrl] placeholderImage:defaultImage];
            }else{
                //item.itemIconView.image = image;
                [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:iconUrl]];
                
            }
            item.itemTitleLabel.text  = title;
            item.normalColor   = UIColorFromRGB(0x888888);
            
            if([[NSFileManager defaultManager] fileExistsAtPath:musicPath]){
                item.normalColor   = UIColorFromRGB(0xe2e2e2);
            }else{
                item.normalColor   = UIColorFromRGB(0x888888);
            }
            count ++;
        }
    }
    _musicChildsView.contentSize = CGSizeMake((count + 4) * (_musicChildsView.frame.size.height - 15)+20, _musicChildsView.frame.size.height);
}

#pragma mark- 云音乐
- (void)enter_cloudMusic:(ScrollViewChildItem *)item{
    if(rdPlayer.isPlaying){
        [self playVideo:NO];
    }
    __weak typeof(self) myself = self;
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
    RDCloudMusicViewController *cloudMusic = [[RDCloudMusicViewController alloc] init];
    cloudMusic.selectedIndex = 0;
    cloudMusic.cloudMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL;
    cloudMusic.backBlock = ^{
        if(selectMusicIndex ==0){
            return ;
        }
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:YES];
        if(selectMusicIndex !=2 && selectMusicIndex !=3 ){
            return ;
        }
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) startScrollTitle];
    };
    cloudMusic.selectCloudMusic = ^(RDMusic *music) {
        oldmusic = music;
        [mvMusicArray removeAllObjects];
        mvMusicArray = nil;
        
        selectMusicIndex = item.tag-1;
        _musicVolumeSlider.enabled = YES;
        ScrollViewChildItem *item = [_musicChildsView viewWithTag:4];
        _musicTimeRange = music.clipTimeRange;
        _musicURL       = music.url;
        item.itemTitleLabel.text = music.name;
        
        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"本地", nil);
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]) startScrollTitle];
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]) setSelected:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshRdPlayer:rdPlayer];
            //            [myself playVideo:YES];
        });
    };
    [self.navigationController pushViewController:cloudMusic animated:YES];
}
#pragma mark-本地音乐
- (void)enter_localMusic:(ScrollViewChildItem *)item{
    if(rdPlayer.isPlaying){
        [self playVideo:NO];
    }
    __weak typeof(self) myself = self;
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
    RDLocalMusicViewController *localmusic = [[RDLocalMusicViewController alloc] init];
    localmusic.backBlock = ^{
        if(selectMusicIndex ==0){
            return ;
        }
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:YES];
        if(selectMusicIndex !=2 && selectMusicIndex !=3 ){
            return ;
        }
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) startScrollTitle];
    };
    localmusic.selectLocalMusicBlock = ^(RDMusic *music){
        oldmusic = music;
        [mvMusicArray removeAllObjects];
        mvMusicArray = nil;
        selectMusicIndex = item.tag-1;
        _musicVolumeSlider.enabled = YES;
        ScrollViewChildItem *item = [_musicChildsView viewWithTag:3];
        _musicTimeRange = music.clipTimeRange;
        _musicURL       = music.url;
        item.itemTitleLabel.text = music.name;
        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]).itemTitleLabel.text = @"云音乐";
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]) startScrollTitle];
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]) setSelected:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshRdPlayer:rdPlayer];
            //            [myself playVideo:YES];
        });
    };
    [self.navigationController pushViewController:localmusic animated:YES];
}
/**检测有多少首音乐正在下载
 */
- (NSInteger)downLoadingMusicCount{
    __block int count = 0;
    [_musicChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            if(((ScrollViewChildItem *)obj).downloading){
                count +=1;
            }
        }
    }];
    return count;
}

#pragma makr-更新音乐
- (void)refreshSound {
    [rdPlayer stop];//20181105 fix bug:不断切换mv、配乐会因内存问题崩溃
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    [self performSelector:@selector(refreshMusicOrDubbing) withObject:nil afterDelay:0.1];
}
- (void)refreshMusicOrDubbing {
    NSMutableArray          *MusicArray = [NSMutableArray new];
    if (_musicURL) {
        if( _audioPathArray != nil )
        {
            for (int i = 0; i < _audioPathArray.count; i++) {
                RDMusic *music = [[RDMusic alloc] init];
                music.identifier = @"audioWordsSay";
                music.url = [NSURL fileURLWithPath:_audioPathArray[i].audioPath];
                music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, _audioPathArray[i].timeRang.duration);
                music.effectiveTimeRange = _audioPathArray[i].timeRang;
                music.isFadeInOut = YES;
                music.volume = _dubbingVolume;
                
                if (selectedSoundEffectIndex == -1) {
                    music.audioFilterType = RDAudioFilterTypeCustom;
                    music.pitch = oldPitch;
                }
                else if (selectedSoundEffectIndex <= RDAudioFilterTypeCartoon) {
                    music.audioFilterType = (RDAudioFilterType)selectedSoundEffectIndex;
                }else {
                    music.audioFilterType = (RDAudioFilterType)(selectedSoundEffectIndex + 1);
                }
                
                [MusicArray addObject:music];
            }
        }
        
        RDMusic *music = [[RDMusic alloc] init];
        music.identifier = @"music";
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.isFadeInOut = YES;
        music.volume = _musicVolume;
        if (mvMusicArray) {
            [mvMusicArray addObject:music];
            [rdPlayer setMusics:MusicArray];
        }else{
            [MusicArray addObject:music];
            [rdPlayer setMusics:MusicArray];
        }
    }
    else{
        if( _audioPathArray != nil )
        {
            for (int i = 0; i < _audioPathArray.count; i++) {
                RDMusic *music = [[RDMusic alloc] init];
                music.identifier = @"audioWordsSay";
                music.url = [NSURL fileURLWithPath:_audioPathArray[i].audioPath];
                music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, _audioPathArray[i].timeRang.duration);
                music.effectiveTimeRange = _audioPathArray[i].timeRang;
                music.isFadeInOut = YES;
                music.volume = _dubbingVolume;
                
                
                if (selectedSoundEffectIndex == -1) {
                    music.audioFilterType = RDAudioFilterTypeCustom;
                    music.pitch = oldPitch;
                }
                else if (selectedSoundEffectIndex <= RDAudioFilterTypeCartoon) {
                    music.audioFilterType = (RDAudioFilterType)selectedSoundEffectIndex;
                }else {
                    music.audioFilterType = (RDAudioFilterType)(selectedSoundEffectIndex + 1);
                }
                
                
                [MusicArray addObject:music];
            }
        }
        if( MusicArray.count > 0 )
            [rdPlayer setMusics:MusicArray];
        else
            [rdPlayer setMusics:nil];
    }
    
    [rdPlayer build];
    [RDSVProgressHUD dismiss];
}
#pragma mark- 文字编辑
-(UIView*) textEditView
{
    if( !_textEditView )
    {
        _textEditView = [[RDTextFontEditor alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, kHEIGHT - (iPhone_X ? 44 : 0) )];
        _textEditView.fontResourceURL = ((RDNavigationViewController*)self.navigationController).editConfiguration.fontResourceURL;
        _textEditView.rdPlayer = rdPlayer;
        _textEditView.delegate = self;
        [self.view addSubview:_textEditView];
        _textEditView.hidden = YES;
        
        _textEditView.textObjectViewArray = textObjectArray;
    }
    return _textEditView;
}
#pragma mark-RDTextFontEditorDelegate
-(void)textOut:(BOOL) isRotate
{
    if(  isRotate )
    {
        float Radian = 0;
        for (int i = 0; i<textObjectArray.count; i++) {
            if( (i > 0) && ( textObjectArray[i].strText.length > 0 ) )
            {
                textObjectArray[i].textFontSize = [self getRandomNumber:31 to:50];
                
                if( Radian == 0 )
                    textObjectArray[i].textRadian = [self getRandomNumber:-1 to:1]*(90.0/180.0*3.14);
                else if( Radian > 0 )
                    textObjectArray[i].textRadian = [self getRandomNumber:-1 to:0]*(90.0/180.0*3.14);
                else
                    textObjectArray[i].textRadian = [self getRandomNumber:0 to:1]*(90.0/180.0*3.14);
                if( (textObjectArray[i].strText.length > 2) || ( textObjectArray[i].textRadian < 0 ) )
                {
                    if( textObjectArray[i].textRadian != 0 )
                        Radian = textObjectArray[i].textRadian;
                    else
                    {
                        textObjectArray[i].textFontSizeSpeed = ((float)[self getRandomNumber:-Amplification to:Amplification])/100.0;
                    }
                }
                else
                {
                    if( textObjectArray[i].textRadian > 0 )
                        textObjectArray[i].textRadian = 0;
                    else
                    {
                        textObjectArray[i].textFontSizeSpeed = ((float)[self getRandomNumber:-Amplification to:Amplification])/100.0;
                    }
                }
                
                if( textObjectArray[i].textRadian > 0 )
                {
                    float width = 0;
                    int fontSize = 0;
                    for (int j = 31; width < 375; j++) {
                        fontSize = j;
                        UIFont *font = [UIFont fontWithName:textObjectArray[i].fontName size:j];
                        CGSize size = [textObjectArray[i].strText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT/*MAXFLOAT*/)options:NSStringDrawingUsesLineFragmentOrigin
                                                                    attributes:@{NSFontAttributeName : font} context:nil].size;
                        width = size.width;
                    }
                    textObjectArray[i].textFontSize = fontSize - 1;
                }
            }
        }
    }
    [self initTextLayerArray];
    [self clickToolItemBtn:[self.toolBarView viewWithTag:0]];
    
//    [rdPlayer filterRefresh:rdPlayer.currentTime];
    [rdPlayer filterRefresh:CMTimeMake(0.2, 1.0)];
}
-(void)seekToTime:(CGFloat)current
{
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:current];
}
-(void)play:(bool) isPlay
{
    [self playVideo:isPlay];
}

#pragma mark
//初始化自绘 横排
- (void)initTextLayerArray {
    
    if( textLayerArray != nil )
    {
        isRebuild = true;
    }
    
    [textLayerCombinationArray removeAllObjects];
    textLayerCombinationArray = nil;
    [textLayerArray removeAllObjects];
    textLayerArray = nil;
    
    textLayerCombinationArray = [NSMutableArray array];
    textLayerArray = [NSMutableArray array];
    //设置旋转
    if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
    {
        RDWordSayTextLayerParam *wordSayTextLayerParam = [RDWordSayTextLayerParam initWordSayTextLayerParam:[self CreateLayer] atRadian:0 atIsText:true];
        [textLayerCombinationArray addObject:wordSayTextLayerParam];
    }
    
    __block int count = 0;
    [textObjectArray enumerateObjectsUsingBlock:^(RDTextObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if( obj.strText.length > 0 )
        {
            CGSize size = (currentDisdisplayTextType != RDDisplyaTextType_Vertical )?CGSizeMake(375, obj.textFontSize+10):CGSizeMake(obj.textFontSize+10, exportVideoSize.width);
            [textLayerArray addObject: [RDWordSayTextLayerParam initWordSayTextLayerParam:[self createTextLayerWithSize:size textObject:obj index:0] atRadian:0 atIsText:true] ];
            textLayerArray[textLayerArray.count-1].textIndex = idx;
            textLayerArray[textLayerArray.count-1].textStartTime = obj.startTime;
            textLayerArray[textLayerArray.count-1].AnimationTime = obj.AnimationTime;
            textLayerArray[textLayerArray.count-1].textShowTime = obj.showTime;
            if( textLayerArray[textLayerArray.count-1].textRadian != 0 )
                textLayerArray[textLayerArray.count-1].textRotationTime = obj.textRotationTime;
            
            if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
                textLayerArray[textLayerArray.count-1].textSize =  textLayerArray[textLayerArray.count-1].textLayer.bounds.size;
            
            textLayerArray[textLayerArray.count-1].textFontSizeSpeed = obj.textFontSizeSpeed;
            
//            if( currentDisdisplayTextType == RDDisplayTextType_Horiz )
//                textLayerArray[textLayerArray.count-1].textLayer.alignmentMode = kCAAlignmentCenter;
//            else if( currentDisdisplayTextType == RDDisplyaTextType_Vertical )
//                textLayerArray[textLayerArray.count-1].textLayer.alignmentMode = kCAAlignmentJustified;
            
            if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
            {
                if( obj.textRadian != 0 )
                {
                    {
                        for (int i = count; i < idx ;i++)
                        {
                            [textLayerCombinationArray[textLayerCombinationArray.count-1].textLayer addSublayer:textLayerArray[i].textLayer];
                        }
                        textLayerCombinationArray[textLayerCombinationArray.count-1].textRadian = obj.textRadian;
                        textLayerCombinationArray[textLayerCombinationArray.count-1].textLayerIndex = idx;
                        textLayerArray[idx].textRadinIndex = (int)textLayerCombinationArray.count-1;
                        
                        count = idx;
                    }
                    
                    {
                        CATextLayer * layer = [self CreateLayer];
                        [layer addSublayer:textLayerCombinationArray[textLayerCombinationArray.count-1].textLayer];
                        [layer  addSublayer:textLayerArray[textLayerArray.count-1].textLayer];
                        [textLayerCombinationArray addObject:[RDWordSayTextLayerParam initWordSayTextLayerParam:layer atRadian:0 atIsText:true]];
                    }
                }
                else{
                    [textLayerCombinationArray[textLayerCombinationArray.count-1].textLayer addSublayer:textLayerArray[textLayerArray.count-1].textLayer];
                }
            }
        }
    }];
    
    [self getValue1];
}

-(void)AdjMagnificationm:(int) i factor:(float) factor
{
    for ( int j = 0; j < i; j++) {
        textLayerArray[j].textCurrentFontSizeSpeed = 1.0;
        textLayerArray[j].textCurrentFontSize = textObjectArray[textLayerArray[j].textIndex].textFontSize;
    }
    for ( int j = 1; j < i; j++) {
        for (int k = 0; k < j; k++) {
            textLayerArray[k].textCurrentFontSizeSpeed = textLayerArray[k].textCurrentFontSizeSpeed*(1+textObjectArray[textLayerArray[j].textIndex].textFontSizeSpeed);
        }
    }

    for ( int j = 0; j <= i; j++) {
        textLayerArray[j].textCurrentFontSizeSpeed  = textLayerArray[j].textCurrentFontSizeSpeed*(1+textObjectArray[textLayerArray[i].textIndex].textFontSizeSpeed*factor);
        if( i == j )
        {
            textLayerArray[j].textCurrentFontSizeSpeed = 1.0;
            textLayerArray[j].textCurrentFontSize = textObjectArray[textLayerArray[j].textIndex].textFontSize;
        }
    }
}
-(CATextLayer *)CreateLayer
{
    CATextLayer *layer = [CATextLayer layer];
    layer.bounds = CGRectMake(0, 0, exportVideoSize.width, exportVideoSize.height);
    layer.position = CGPointMake(0, 0);
    layer.anchorPoint = CGPointMake(0, 0);
    layer.backgroundColor = [UIColor clearColor].CGColor;
    return layer;
}
#pragma mark- 创建 字幕
- (CATextLayer *)createTextLayerWithSize:(CGSize)size
                               textObject:(RDTextObject *)textObject
                                   index:(int)index
{
    CATextLayer *textLayer = [self CreateLayer];
    textLayer.bounds = CGRectMake(0, 0, size.width, size.height);
//    textLayer.foregroundColor = textObject.textColor.CGColor;
    if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
        textLayer.alignmentMode = kCAAlignmentLeft;
    else
        textLayer.alignmentMode = kCAAlignmentCenter;
    
    
    textLayer.wrapped = YES;
    //以Retina方式来渲染，防止画出来的文本模糊
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.truncationMode = kCATruncationEnd;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 1;
    shadow.shadowColor = textObject.textColorShadow;
    shadow.shadowOffset = CGSizeMake(textObject.textFontshadow, textObject.textFontshadow);
    
    UIFont *font = [UIFont fontWithName:textObject.fontName size:textObject.textFontSize];
    NSDictionary *myDic = @{
                            NSFontAttributeName:font,
                            NSForegroundColorAttributeName:textObject.textColor,
                            NSStrokeColorAttributeName:textObject.textFontStrokeColor,
                            NSStrokeWidthAttributeName:(id)[NSNumber numberWithFloat:(-textObject.textFontStroke)],
                            NSShadowAttributeName: shadow,
                            };
    
    NSDictionary *myDicShadow = @{
                            NSFontAttributeName:font,
                            NSForegroundColorAttributeName:textObject.textColorShadow,
                            };
    NSString * text = nil;
    if( currentDisdisplayTextType == RDDisplyaTextType_Vertical )
    {
        NSMutableString * attributedText = [NSMutableString string];
        [textObject.strText enumerateSubstringsInRange:NSMakeRange(0, textObject.strText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
        ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if (substringRange.location + substringRange.length == textObject.strText.length) {
                [attributedText insertString:substring atIndex:attributedText.length];
            }else {
                [attributedText insertString:[substring stringByAppendingString:@"\n"] atIndex:attributedText.length];
            }
        }];
        text = attributedText;

        textLayer.string = [[NSMutableAttributedString alloc] initWithString:text attributes:myDic];
        
        textLayer.bounds = CGRectMake(0, 0, [self textWidth:textLayer.string].width, 375);
    }
    else
    {
        text = textObject.strText;
        textLayer.string = [[NSMutableAttributedString alloc] initWithString:textObject.strText attributes:myDic];
        
        if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
            textLayer.bounds = CGRectMake(0, 0, [self textWidth:textLayer.string].width, [self textWidth:textLayer.string].height);
        else
            textLayer.bounds = CGRectMake(0, 0, textLayer.bounds.size.width, [self textWidth:textLayer.string].height);
    }

    textLayer.string = nil;
    if( currentDisdisplayTextType != RDDisplayTextType_Rotate )
    {
        CGSize size = textLayer.bounds.size;
        if( currentDisdisplayTextType == RDDisplyaTextType_Vertical )
        {
            if( CMTimeGetSeconds(textObject.AnimationTime) == 0 )
                size = CGSizeMake(textLayerArray[textLayerArray.count-1].textLayer.bounds.size.width + size.width*2.0, size.height);
        }
        else{
            if( CMTimeGetSeconds(textObject.AnimationTime) == 0 )
                size = CGSizeMake(size.width, textLayerArray[textLayerArray.count-1].textLayer.bounds.size.height + size.height*2.0);
        }
        textLayer.bounds = CGRectMake(0, 0, size.width, size.height);
    }
    
    CATextLayer *textLayer2 = [self CreateLayer];
    if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
        textLayer2.alignmentMode = kCAAlignmentLeft;
    else
        textLayer2.alignmentMode = kCAAlignmentCenter;
    textLayer2.wrapped = YES;
    //以Retina方式来渲染，防止画出来的文本模糊
    textLayer2.contentsScale = [UIScreen mainScreen].scale;
    textLayer2.truncationMode = kCATruncationEnd;
    textLayer2.string =  [[NSMutableAttributedString alloc] initWithString:text attributes:myDicShadow];
    textLayer2.bounds = CGRectMake(-textObject.textFontshadow, -textObject.textFontshadow, textLayer.bounds.size.width, textLayer.bounds.size.height);
    
    [textLayer addSublayer:textLayer2];
    
    CATextLayer *textLayer1 = [self CreateLayer];
    if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
        textLayer1.alignmentMode = kCAAlignmentLeft;
    else
        textLayer1.alignmentMode = kCAAlignmentCenter;
    textLayer1.wrapped = YES;
    //以Retina方式来渲染，防止画出来的文本模糊
    textLayer1.contentsScale = [UIScreen mainScreen].scale;
    textLayer1.truncationMode = kCATruncationEnd;
    textLayer1.string =  [[NSMutableAttributedString alloc] initWithString:text attributes:myDic];
    textLayer1.bounds = CGRectMake(0, 0, textLayer.bounds.size.width, textLayer.bounds.size.height);
    [textLayer addSublayer:textLayer1];
    
    textLayer.hidden = YES;
    return textLayer;
}


- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    
//    if( isExport )
//    {
        if( CMTimeCompare(currentTime, exportCurrentTime) != 0 )
        {
            exportCurrentTime = currentTime;
        }
        else
            return;
//    }
    
    if( isRebuild )
    {
        NSArray<CALayer *> *subLayers = customDrawLayer.sublayers;
        NSArray<CALayer *> *removedLayers = [subLayers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject isKindOfClass:[CATextLayer class]];
        }]];
        [removedLayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperlayer];
        }];
        isRebuild = false;
    }
    
    if (customDrawLayer.sublayers.count == 0) {
        if( currentDisdisplayTextType == RDDisplayTextType_Rotate )
            [customDrawLayer addSublayer:textLayerCombinationArray[textLayerCombinationArray.count-1].textLayer];
        else
        {
            [textLayerArray enumerateObjectsUsingBlock:^(RDWordSayTextLayerParam * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [customDrawLayer addSublayer:obj.textLayer];
            }];
        }
    }
    
    switch ( currentDisdisplayTextType ) {
        case RDDisplayTextType_Rotate:
            [self RotateText:currentTime];
            break;
        case RDDisplayTextType_Horiz:
            [self HorizText:currentTime];
            break;
        case RDDisplyaTextType_Vertical:
            [self VerticalTExt:currentTime];
            break;
        default:
            break;
    }
}

//计算文字所占宽度
-(CGSize)textWidth:(NSMutableAttributedString *) txt
{
    CGSize maxSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGSize rectSize = [txt boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   context:nil].size;
    return rectSize;
}

////旋转
#pragma mark- 字幕旋转操作
-(void)textLyaerRotatePoision:(int) index atFactor:(float) factor  isRotate:(BOOL) isRotate
{
    float rotate = [self rotateMixed:0 b:textLayerCombinationArray[index].textRadian factor:factor];
    CGPoint position = CGPointZero;
    int tIndex = textLayerCombinationArray[index].textLayerIndex;

    //当前旋转字幕的 缩放倍数
    float textCurrentFontSizeSpeed = textLayerArray[tIndex].textCurrentFontSizeSpeed;
    //当前旋转前一个字幕的 缩放倍数
    float textCurrentFontSizeSpeed1 = textLayerArray[tIndex-1].textCurrentFontSizeSpeed;
    
    float heightText1 = textLayerArray[tIndex-1].textLayer.bounds.size.height*textCurrentFontSizeSpeed1;
    float heightText2 = textLayerArray[tIndex].textLayer.bounds.size.height*textCurrentFontSizeSpeed;

    float height = heightText2;
    float width = Margin_X - (heightText2/2.0- heightText1/2.0);
    float x = textLayerArray[tIndex-1].textLayer.bounds.size.height*textCurrentFontSizeSpeed1;

    if( (textLayerArray[tIndex-1].textLayer.bounds.size.height*textCurrentFontSizeSpeed1) > heightText2 )
    {
        height = heightText1;
        width = Margin_X - (heightText1/2.0 -heightText2/2.0);
        x = textLayerArray[tIndex].textLayer.bounds.size.height*textCurrentFontSizeSpeed;
    }

    textLayerCombinationArray[index].textFactor = factor;
    if(textLayerCombinationArray[index].textRadian >= (90.0/180.0*3.14))
    {
        float fwidthx  = textLayerArray[tIndex-1].textLayer.bounds.size.width*textCurrentFontSizeSpeed1;
        
        textLayerCombinationArray[index].textAnchor = CGPointMake(Margin_X/2.0 + textLayerArray[tIndex].textLayer.bounds.size.width*textCurrentFontSizeSpeed, 460);
        
        textLayerCombinationArray[index].textFactorPoint = [self CGPointMixed:CGPointMake(Margin_X/2.0 + textLayerArray[tIndex].textLayer.bounds.size.width*textCurrentFontSizeSpeed, 460) b:CGPointMake( Margin_X/2.0 + textLayerArray[tIndex].textLayer.bounds.size.width*textCurrentFontSizeSpeed, 460 + 28*textCurrentFontSizeSpeed1                                               +  (426 - Margin_X*2.0)*textCurrentFontSizeSpeed1 - fwidthx + textLayerArray[tIndex].textLayer.bounds.size.height/2.0*textCurrentFontSizeSpeed1
                                                            ) factor:factor];

        if( isRotate )
            textLayerArray[tIndex].textAnchor = CGPointMake(372.5,126);
        
        position = [self CGPointMixed:CGPointMake(394, 426 + x + width/2.0 - (x-height) ) b:CGPointMake(394, 426 + x + width/2.0 - (x-height)) factor:factor];
    }
    else{
        textLayerCombinationArray[index].textAnchor = CGPointMake(Margin_X,426);

//        float fx = (heightText1/2.0 -heightText2/2.0);
        
        textLayerCombinationArray[index].textFactorPoint = [self CGPointMixed:CGPointMake(Margin_X, 426) b:CGPointMake(Margin_X - 5, 426 + textLayerArray[tIndex].textLayer.bounds.size.height*textCurrentFontSizeSpeed )factor:factor];
        
        if( isRotate )
            textLayerArray[tIndex].textAnchor = CGPointMake(Margin_X,Margin_X);

        position = [self CGPointMixed:CGPointMake(Margin_X, 426 + x + width/2.0 )
                                    b:CGPointMake(Margin_X + Margin_X, 426 + x )factor:factor];
    }

    textLayerCombinationArray[index].textPoint = textLayerCombinationArray[index].textFactorPoint;
    [self setTextLayerTransform:index  position:textLayerCombinationArray[index].textFactorPoint  rotation:rotate scale:CGSizeMake(1, 1) isCombination:true];
    
    if( isRotate )
    {
        rotate = [self rotateMixed:-textLayerCombinationArray[index].textRadian b:0 factor:factor];
        CGSize scale = [self CGSizeMixed:CGSizeMake(0, 0) b:CGSizeMake(0.9, 0.9) factor:factor];
        [self setTextLayerTransform:tIndex position:position rotation:rotate scale:scale isCombination:false];
    }
}
#pragma mark- 字幕显示操作
-(void)textLyaerPoision:(int) index atWidthX:(float) fWidthX atFactor:(float) factor
{
    textLayerArray[index].textAnchor = CGPointMake(0.0, 0.0);
    
    textLayerArray[index].textPoint = CGPointMake(fWidthX, 426 + ((index>0)?textLayerArray[index-1].textLayer.bounds.size.height*textLayerArray[index-1].textCurrentFontSizeSpeed:textLayerArray[index].textLayer.bounds.size.height*textLayerArray[index].textCurrentFontSizeSpeed) );
    textLayerArray[index].textFactor = factor;
    textLayerArray[index].textFactorPoint = [self CGPointMixed:textLayerArray[index].textPoint b: CGPointMake(textLayerArray[index].textPoint.x, 426)  factor:factor];
    
    [self setTextLayerTransform:index position:textLayerArray[index].textFactorPoint  rotation:0 scale:[self CGSizeMixed:CGSizeMake(0, 0) b:CGSizeMake(1, 1) factor:factor]isCombination:false];
}


- (float)rotateMixed:(float)a b:(float)b factor:(float)factor {
    return (a + (b - a)*factor);
}

- (CGPoint)CGPointMixed:(CGPoint)a  b:(CGPoint)b factor:(float)factor {
    float x = a.x + (b.x - a.x) * factor;
    float y = a.y + (b.y - a.y) * factor;
    return CGPointMake(x, y);
}

- (CGSize)CGSizeMixed:(CGSize)a  b:(CGSize)b factor:(float)factor {
    float w = a.width + (b.width - a.width) * factor;
    float h = a.height + (b.height - a.height) * factor;
    return CGSizeMake(w, h);
}
#pragma mark-设置 字幕显示
- (void)setTextLayerTransform:(int) textIndex
                     position:(CGPoint) position
                     rotation:(CGFloat)rotation
                        scale:(CGSize)scale
                isCombination:(bool)isCombination

{
    CATextLayer * textLayer = nil;
    if( !isCombination )
        textLayer = textLayerArray[textIndex].textLayer;
    else
        textLayer = textLayerCombinationArray[textIndex].textLayer;
    
    CGPoint anchor = CGPointZero;
    if( !isCombination )
        anchor = textLayerArray[textIndex].textAnchor;
    else
        anchor = textLayerCombinationArray[textIndex].textAnchor;
    
    CATransform3D baseXform = CATransform3DIdentity;
    CATransform3D translateXform = CATransform3DTranslate(baseXform, position.x, position.y, 0);
    CATransform3D rotateXform= CATransform3DRotate(translateXform, rotation, 0, 0, 1);
    
    if( (!isCombination) && ( currentDisdisplayTextType == RDDisplayTextType_Rotate )  )
        scale = CGSizeMake(scale.width*textLayerArray[textIndex].textCurrentFontSizeSpeed, scale.height*textLayerArray[textIndex].textCurrentFontSizeSpeed);
    
    CATransform3D scaleXform = CATransform3DScale(rotateXform, scale.width, scale.height, 1);
    CATransform3D anchorXform = CATransform3DTranslate(scaleXform, -1 * anchor.x, -1 * anchor.y, 0);
    textLayer.transform = anchorXform;
}
#pragma mark- 旋转文字
-(void)RotateText:(CMTime)currentTime
{
    for (int j = 0; j < textLayerCombinationArray.count; j++) {
        textLayerCombinationArray[j].textAnchor = CGPointMake(0.5, 0.5);
        [self setTextLayerTransform:j position:CGPointMake(0, 0) rotation:0 scale:CGSizeMake(1, 1) isCombination:true];
        textLayerCombinationArray[j].textPoint = CGPointZero;
        textLayerCombinationArray[j].textFactorPoint = CGPointZero;
        textLayerCombinationArray[j].textFactor = -1;
    }
    for (int j = 0; j < textLayerArray.count; j++) {
        textLayerArray[j].textLayer.hidden = YES;
        textLayerArray[j].textPoint = CGPointZero;
        textLayerArray[j].textFactorPoint = CGPointZero;
        textLayerArray[j].textAnchor = CGPointZero;
        textLayerArray[j].textFactor = -1;
        textLayerArray[j].textLayer.anchorPoint = CGPointMake(0.0, 0.0);
    }
    
    float  fCurrentTime = CMTimeGetSeconds(currentTime);
    NSLog(@"当前时间：%.2f",fCurrentTime);
    
    int count = 0;
    for (int i = 0; i < textLayerArray.count; i++) {
        bool isEnter = true;
        if( i != (textLayerArray.count-1) )
            isEnter =  (CMTimeCompare(currentTime, textLayerArray[i+1].textStartTime) == -1);
        if( CMTimeCompare(currentTime, textLayerArray[i].textStartTime) >= 0 && isEnter )
            count = i;
    }
    
    CMTime time = textLayerArray[count].AnimationTime;
    float factor = (CMTimeGetSeconds(currentTime) - CMTimeGetSeconds(textLayerArray[count].textStartTime)) / (CMTimeGetSeconds(time) - CMTimeGetSeconds(textLayerArray[count].textStartTime));
    factor = factor > 1.0 ? 1.0 : factor;
    [self AdjMagnificationm:count factor:factor];
    
    if( CMTimeCompare(currentTime, textLayerArray[count].textStartTime) >= 0 && CMTimeCompare(currentTime,time ) == -1 )
    {
        //动画过度 字幕的位置设置
        if( count > 0 )
        {
            [self DisplayText:count];
            [self moveText:count atfactor:factor];
        }
        if( textLayerArray[count].textRadinIndex >= 0 )
            [self textLyaerRotatePoision:textLayerArray[count].textRadinIndex atFactor:factor isRotate:true];
        else
            [self textLyaerPoision:count atWidthX:Margin_X atFactor:factor];
    }
    else
    {
        [self DisplayText:count+1];
        
        switch (textLayerArray[count].textDisplayAnimation) {
            case RDDisplayAnimation_None:
                
                break;
            case RDDisplayAnimation_Zoom:
                [self textZoomAnimation:count time:currentTime];
                break;
            case RDDisplayAnimation_Pan_UpAndDown:
                [self textPanUpAndDown:count time:currentTime];
                break;
            case RDDisplayAnimation_Swing_UpAndDown:
                [self textSwingUpAndDown:count time:currentTime];
                break;
            case RDDisplayAnimation_Swing_BeforeAndAfter:
                [self textSwingBeforeAndAfter:count time:currentTime];
                break;
            default:
                break;
        }
        
    }
    
    for (int i = 0; i < textLayerArray.count; i++) {
        if( i <= count )
            textLayerArray[i].textLayer.hidden = NO;
        else
            textLayerArray[i].textLayer.hidden = YES;
    }
}

#pragma mark- 字幕缩放动画 (完成)
-(void)textZoomAnimation:(int) index time:(CMTime) currenTime
{
    int fps = (CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime))*30.0;
    float percentage =  ((float)(fps%10))/10.0;
    
    float startTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime);
    float endTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(textLayerArray[index].AnimationTime);
    
    float fAttenuation = startTime/(endTime*0.5);
    fAttenuation = fAttenuation>1.0?1.0:fAttenuation;
    
    float rotation = (-0.1+percentage*0.2)*(1-fAttenuation);
    
    if( fAttenuation == 1.0 )
        rotation = 0.0;
    
    textLayerArray[index].textAnchor = CGPointMake(textLayerArray[index].textLayer.bounds.size.width/2.0, textLayerArray[index].textLayer.bounds.size.height/2.0);
     [self setTextLayerTransform:index position:CGPointMake(textLayerArray[index].textPoint.x+textLayerArray[index].textLayer.bounds.size.width/2.0, 426+textLayerArray[index].textLayer.bounds.size.height/2.0)  rotation:0.0 scale:CGSizeMake(1.0-rotation, 1.0-rotation) isCombination:false];
}
#pragma mark- 字幕上下移动 (完成)
-(void)textPanUpAndDown:(int) index time:(CMTime) currenTime
{
    int fps = (CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime))*30.0;
    float percentage =  ((float)(fps%10))/10.0;
    
    float startTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime);
    float endTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(textLayerArray[index].AnimationTime);
    
    float fAttenuation = startTime/(endTime*0.5);
    fAttenuation = fAttenuation>1.0?1.0:fAttenuation;
    
    float rotation = (-10.0+percentage*20.0)*(1-fAttenuation);
    
    if( fAttenuation == 1.0 )
        rotation = 0.0;
    
    [self setTextLayerTransform:index position:CGPointMake(textLayerArray[index].textPoint.x, 426+rotation)  rotation:0 scale:CGSizeMake(1, 1) isCombination:false];
}
#pragma mark- 字幕摇摆 前后 (未完成)
-(void)textSwingBeforeAndAfter:(int) index time:(CMTime) currenTime
{
//    int fps = (CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime))*30.0;
//    float percentage =  ((float)(fps%15))/15.0;
//    float startTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime);
//    float endTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(textLayerArray[index].AnimationTime);
//    float fAttenuation = startTime/(endTime*0.6);
//    fAttenuation = fAttenuation>1.0?1.0:fAttenuation;
//    float rotation = (-30.0+percentage*60.0)*(1-fAttenuation)/180.0*3.14;
//    if( fAttenuation == 1.0 )
//        rotation = 0.0;
//    CGPoint position = CGPointMake(textLayerArray[index].textPoint.x, 426);
//
//    CATextLayer * textLayer = nil;
//    textLayer = textLayerArray[index].textLayer;
//    CATransform3D baseXform = CATransform3DIdentity;
////    CATransform3D translateXform = CATransform3DTranslate(baseXform, position.x, position.y, 0);
////    CATransform3D rotateXform= CATransform3DRotate(translateXform, rotation, 0.0, 0.0, 1.0);
////    CATransform3D scaleXform = CATransform3DScale(rotateXform, 1.0, 1.0, 1);
////    CATransform3D anchorXform = CATransform3DTranslate(scaleXform, -1 * 0.0, -1 * 0.0, 0);
////    textLayer.transform = anchorXform;
//    CGFloat m34 = 800;
//    CGFloat value = rotation;//（控制翻转角度）
////    NSLog(@"当前旋转：%.2f",rotation);
//    CGPoint point = CGPointMake(0.5, 0.5);//设定翻转时的中心点，0.5为视图layer的正中
//    CATransform3D transfrom = CATransform3DIdentity;
//    transfrom.m34 = (0.5 - 0.5) * 10 / m34;
//    CGFloat radiants = value / 360.0 * 2 * M_PI;
//    CGFloat x = 0.0f;
//    CGFloat y = 1.0f;
//    CGFloat z = 0.0f;
//    transfrom = CATransform3DTranslate(transfrom, position.x, position.y, 0);
//    transfrom = CATransform3DRotate(transfrom, value, x, y, z);//(后面3个 数字分别代表不同的轴来翻转，本处为x轴)
//
//    CATransform3D trans = CATransform3DMakeRotation(M_PI/4, 1, 0, 0);
//    trans = CATransform3DInvert(trans);
////
//    CALayer *layer = textLayerArray[index].textLayer;
////    layer.anchorPoint = point;
////    layer.transform = trans;
//    CATransformLayer *cube = [CATransformLayer layer];
//    cube.borderWidth = 1.0;
//    cube.borderColor = [UIColor whiteColor].CGColor;
//    cube.backgroundColor = [UIColor redColor].CGColor;
//    cube.transform = trans;
//    [layer addSublayer:cube];
}
#pragma mark- 字幕摇摆 上下 （完成）
-(void)textSwingUpAndDown:(int) index time:(CMTime) currenTime
{
    int fps = (CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime))*30.0;
    float percentage =  ((float)(fps%15))/15.0;
    
    float startTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(currenTime);
    float endTime = CMTimeGetSeconds(textLayerArray[index].textShowTime) - CMTimeGetSeconds(textLayerArray[index].AnimationTime);
    
    float fAttenuation = startTime/(endTime*0.6);
    fAttenuation = fAttenuation>1.0?1.0:fAttenuation;
    
    float rotation = (-5.0+percentage*10.0)*(1-fAttenuation)/180.0*3.14;

    if( fAttenuation == 1.0 )
        rotation = 0.0;
    
    textLayerArray[index].textAnchor = CGPointMake(textLayerArray[index].textLayer.bounds.size.width/2.0, textLayerArray[index].textLayer.bounds.size.height/2.0);
    
    [self setTextLayerTransform:index position:CGPointMake(textLayerArray[index].textPoint.x+textLayerArray[index].textLayer.bounds.size.width/2.0, 426+textLayerArray[index].textLayer.bounds.size.height/2.0)  rotation:rotation scale:CGSizeMake(1, 1) isCombination:false];
}

#pragma mark- 字幕平移操作
-(void)DisplayText:(int) count
{
    int radinIndex = -1;
    for (int i = 0; i < count; i++) {
        
        [self textLyaerPoision:i atWidthX:Margin_X atFactor:1.0];
        
        textLayerArray[i].textAnchor = CGPointZero;
        textLayerArray[i].textFactor = -1;
        textLayerArray[i].textPoint = textLayerArray[i].textFactorPoint;
        
        if( radinIndex < textLayerArray[i].textRadinIndex )
            radinIndex = textLayerArray[i].textRadinIndex;
    }
    
    for (int i = 0; i <=  radinIndex; i++) {
        int index = 0;
        if ( i > 0) {
            index = textLayerCombinationArray[i-1].textLayerIndex;
        }
        
        for (int j = index; j < textLayerCombinationArray[i].textLayerIndex; j++) {
            if( j > 0 )
            {
                [self DisplayText_moveText:j atEnd:index];
            }
        }
        
        [self textLyaerRotatePoision:i atFactor:1.0 isRotate:false];
        textLayerCombinationArray[i].textFactor = -1;
        textLayerCombinationArray[i].textFactorPoint = textLayerCombinationArray[i].textPoint;
    }
    
    if( radinIndex >= 0 )
    {
        for (int i = textLayerCombinationArray[ radinIndex ].textLayerIndex; i < count; i++) {
            
            [self DisplayText_moveText:i atEnd:textLayerCombinationArray[ radinIndex ].textLayerIndex];
            

        }
    }
    else
    {
        for (int i = 0; i < count; i++) {
            if( i > 0 )
            {
                [self DisplayText_moveText:i atEnd:0];
            }
        }
    }
}
-(void)DisplayText_moveText:(int) index atEnd:(int) endIndex
{
    [self moveText:index atfactor:1.0];
    for (int j = 0; j <= index; j++) {
        textLayerArray[j].textFactor = -1;
        textLayerArray[j].textPoint = textLayerArray[j].textFactorPoint;
    }
    
    for (int j = 0; j < textLayerCombinationArray.count; j++) {
        textLayerCombinationArray[j].textFactor = -1;
        textLayerCombinationArray[j].textPoint = textLayerCombinationArray[j].textFactorPoint;
    }

}
-(void)moveText:(int) count atfactor:(float) factor
{
    float fHeighty = textLayerArray[count-1].textLayer.bounds.size.height*textLayerArray[count-1].textCurrentFontSizeSpeed ;
    
    int start = 0;
    
    int icount = count;
    
    for (int i = (textLayerCombinationArray.count-1); i >= 0; i--) {
        if( (textLayerCombinationArray[i].textLayerIndex < icount) && (textLayerCombinationArray[i].textLayerIndex != -1) && (start < textLayerCombinationArray[i].textLayerIndex ) )
        {
            if(textLayerCombinationArray[i].textRadian >= (90.0/180.0*3.14))
            {
                textLayerCombinationArray[i].textAnchor = CGPointMake(Margin_X/2.0 + textLayerArray[textLayerCombinationArray[i].textLayerIndex].textLayer.bounds.size.width*textLayerArray[textLayerCombinationArray[i].textLayerIndex].textCurrentFontSizeSpeed, 460);
            }
            else
                textLayerCombinationArray[i].textAnchor = CGPointMake(Margin_X,426);
            
            CGPoint textPoint = CGPointMake(textLayerCombinationArray[i].textPoint.x,textLayerCombinationArray[i].textPoint.y - ((start==0)? fHeighty:0) );
            textLayerCombinationArray[i].textFactor = factor;
            textLayerCombinationArray[i].textFactorPoint = [self CGPointMixed:textLayerCombinationArray[i].textPoint b:textPoint factor:factor];
            [self setTextLayerTransform:i  position:textLayerCombinationArray[i].textFactorPoint  rotation:textLayerCombinationArray[i].textRadian scale:CGSizeMake(1, 1) isCombination:true];
            
            if( start < textLayerCombinationArray[i].textLayerIndex )
                start = textLayerCombinationArray[i].textLayerIndex;
        }
    }
    
    for (int i = start; i < count; i++) {
        CGPoint textPoint = CGPointMake(textLayerArray[i].textPoint.x,textLayerArray[i].textPoint.y - fHeighty);
        textLayerArray[i].textFactor = factor;
        textLayerArray[i].textFactorPoint = [self CGPointMixed:textLayerArray[i].textPoint b:textPoint factor:factor];
        [self setTextLayerTransform:i position:textLayerArray[i].textFactorPoint  rotation:textLayerArray[i].textRadian scale:CGSizeMake(1, 1) isCombination:false];
    }
}

#pragma mark- 横排文字
-(void)HorizText:(CMTime)currentTime
{
    for (int i = 0; i < textLayerArray.count; i++) {
        if (CMTimeCompare(currentTime, textLayerArray[i].textStartTime) >= 0 && CMTimeCompare(currentTime, textLayerArray[i].textShowTime) == -1)
        {
            textLayerArray[i].textLayer.hidden = NO;
            float fWidthX = (exportVideoSize.width-375)/2.0;
            
            CMTime time = textLayerArray[i].AnimationTime;
            
            float factor = 1.0;
            if( CMTimeGetSeconds(time) >0 )
               factor = (CMTimeGetSeconds(currentTime) - CMTimeGetSeconds(textLayerArray[i].textStartTime)) / (CMTimeGetSeconds(time) - CMTimeGetSeconds(textLayerArray[i].textStartTime));
            factor = factor > 1.0 ? 1.0 : factor;
            
            textLayerArray[i].textFactor = factor;
            textLayerArray[i].textFactorPoint = [self CGPointMixed:CGPointMake(fWidthX, 426 + textLayerArray[i].textLayer.bounds.size.height/2.0 ) b: CGPointMake(fWidthX, 426 - textLayerArray[i].textLayer.bounds.size.height/2.0 )  factor:factor];
            
            [self setTextLayerTransform:i position:textLayerArray[i].textFactorPoint  rotation:0 scale:[self CGSizeMixed:CGSizeMake(0, 0) b:CGSizeMake(1, 1) factor:factor]isCombination:false];
        }
        else
            textLayerArray[i].textLayer.hidden = YES;
    }
}

#pragma mark- 竖排文字
-(void)VerticalTExt:(CMTime)currentTime
{
    for (int i = 0; i < textLayerArray.count; i++) {
        if (CMTimeCompare(currentTime, textLayerArray[i].textStartTime) >= 0 && CMTimeCompare(currentTime, textLayerArray[i].textShowTime) == -1)
        {
            textLayerArray[i].textLayer.hidden = NO;
            
            CMTime time = textLayerArray[i].AnimationTime;
            
            float factor = 1.0;
            if( CMTimeGetSeconds(time) >0 )
                factor = (CMTimeGetSeconds(currentTime) - CMTimeGetSeconds(textLayerArray[i].textStartTime)) / (CMTimeGetSeconds(time) - CMTimeGetSeconds(textLayerArray[i].textStartTime));
            factor = factor > 1.0 ? 1.0 : factor;

            
            textLayerArray[i].textFactor = factor;
            textLayerArray[i].textFactorPoint = [self CGPointMixed:CGPointMake( (exportVideoSize.width - textLayerArray[i].textLayer.bounds.size.width)/2.0 , (exportVideoSize.height-textLayerArray[i].textLayer.bounds.size.height)/2.0 ) b: CGPointMake( (exportVideoSize.width - textLayerArray[i].textLayer.bounds.size.width)/2.0, (exportVideoSize.height-textLayerArray[i].textLayer.bounds.size.height)/2.0 )  factor:factor];
            
            [self setTextLayerTransform:i position:textLayerArray[i].textFactorPoint  rotation:0 scale:[self CGSizeMixed:CGSizeMake(0, 0) b:CGSizeMake(1, 1) factor:factor]isCombination:false];
        }
        else
            textLayerArray[i].textLayer.hidden = YES;
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [rdPlayer stop];
    rdPlayer = nil;
    [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
}

#pragma mark-背景
-(UIView*)backgroundView
{
    if( !_backgroundView )
    {
        _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _functionalAreaView.frame.size.height - _toolBarView.frame.size.height)];
        _backgroundView.backgroundColor = TOOLBAR_COLOR;
        [_functionalAreaView addSubview:_backgroundView];
        
        float fwidthx = (_backgroundView.frame.size.height-31-20)*9.0/16.0;
        
        _albumBtnView = [[UIView alloc] initWithFrame:CGRectMake(0, 31, fwidthx+20,_backgroundView.frame.size.height-31 )];
        _albumBtnView.backgroundColor = TOOLBAR_COLOR;
        [_backgroundView addSubview:_albumBtnView];
        
        _backgroundBtn = [[UIButton alloc] initWithFrame:CGRectMake( 10, 10, fwidthx, _backgroundView.frame.size.height-31-20)];
        _backgroundBtn.backgroundColor = BOTTOM_COLOR;
        _backgroundBtn.layer.borderColor = BOTTOM_COLOR.CGColor;
        _backgroundBtn.layer.borderWidth = 1.0;
        _backgroundBtn.layer.cornerRadius = 5;
        _backgroundBtn.layer.masksToBounds = YES;
        [_backgroundBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
        [_backgroundBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_backgroundBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_backgroundBtn.titleLabel setFont:[UIFont systemFontOfSize:10]];
        [_backgroundBtn addTarget:self action:@selector(background_Btn:) forControlEvents:UIControlEventTouchUpInside];
        [_albumBtnView addSubview:_backgroundBtn];
        
        [_backgroundView addSubview:self.solidColorView];
        

        backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, (_backgroundView.frame.size.height-31-20 - (fwidthx-10)/3.0 )/2.0, fwidthx-10, (fwidthx-10)/3.0)];
        backgroundImageView.backgroundColor = [UIColor clearColor];
        backgroundImageView.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/选中" Type:@"png"]];
        
        
        _transparencyVolumelabel = [UILabel new];
        _transparencyVolumelabel.frame = CGRectMake(0, 0, 60, 31);
        _transparencyVolumelabel.textAlignment = NSTextAlignmentCenter;
        _transparencyVolumelabel.backgroundColor = [UIColor clearColor];
        _transparencyVolumelabel.font = [UIFont boldSystemFontOfSize:12];
        _transparencyVolumelabel.textColor = [UIColor whiteColor];
        _transparencyVolumelabel.text = RDLocalizedString(@"透明度", nil);
        [_backgroundView addSubview:_transparencyVolumelabel];
        
       [_backgroundView addSubview:self.transparencyVolumeSlider];
    }
    return _backgroundView;
}

- (RDZSlider *)transparencyVolumeSlider{
    if(!_transparencyVolumeSlider){
        _transparencyVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake( 60, 0, kWIDTH-60-10, 31)];
        _transparencyVolumeSlider.alpha = 1.0;
        _transparencyVolumeSlider.backgroundColor = [UIColor clearColor];
        [_transparencyVolumeSlider setMaximumValue:1];
        [_transparencyVolumeSlider setMinimumValue:0];
        [_transparencyVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_transparencyVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_transparencyVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        [_transparencyVolumeSlider setValue:1.0];
        [_transparencyVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_transparencyVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_transparencyVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_transparencyVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _transparencyVolumeSlider;
}


-(UIScrollView *)solidColorView
{
    if( !_solidColorView )
    {
        _solidColorView = [[UIScrollView alloc] initWithFrame:CGRectMake(_albumBtnView.frame.size.width+_albumBtnView.frame.origin.x, 31, _backgroundView.frame.size.width-(_albumBtnView.frame.size.width+_albumBtnView.frame.origin.x), _backgroundView.frame.size.height-31)];
        
        _textColorBtnArray = [NSMutableArray<UIButton*> new];
        _textColorArray    = [NSMutableArray<UIColor*> new];
        
        [_textColorArray addObject:UIColorFromRGB(0xffffff)];
        [_textColorArray addObject:UIColorFromRGB(0x827f8e)];
        [_textColorArray addObject:UIColorFromRGB(0x4a4758)];
        [_textColorArray addObject:UIColorFromRGB(0x000000)];
        [_textColorArray addObject:UIColorFromRGB(0xa90116)];
        [_textColorArray addObject:UIColorFromRGB(0xec001c)];
        [_textColorArray addObject:UIColorFromRGB(0xff441c)];
        [_textColorArray addObject:UIColorFromRGB(0xff8514)];
        [_textColorArray addObject:UIColorFromRGB(0xffbd18)];
        [_textColorArray addObject:UIColorFromRGB(0xfff013)];
        [_textColorArray addObject:UIColorFromRGB(0xadd321)];
        [_textColorArray addObject:UIColorFromRGB(0x23c203)];
        [_textColorArray addObject:UIColorFromRGB(0x007f23)];
        [_textColorArray addObject:UIColorFromRGB(0x0ce397)];
        [_textColorArray addObject:UIColorFromRGB(0x06a998)];
        [_textColorArray addObject:UIColorFromRGB(0x00d0ff)];
        [_textColorArray addObject:UIColorFromRGB(0x1975ff)];
        [_textColorArray addObject:UIColorFromRGB(0x2c2ad4)];
        [_textColorArray addObject:UIColorFromRGB(0x4a07b7)];
        [_textColorArray addObject:UIColorFromRGB(0xb52fe3)];
        [_textColorArray addObject:UIColorFromRGB(0xff5ab0)];
        [_textColorArray addObject:UIColorFromRGB(0xde07a2)];
        [_textColorArray addObject:UIColorFromRGB(0xde0755)];
        [_textColorArray addObject:UIColorFromRGB(0x7b0039)];
        [_textColorArray addObject:UIColorFromRGB(0x422922)];
        [_textColorArray addObject:UIColorFromRGB(0x602c12)];
        [_textColorArray addObject:UIColorFromRGB(0x8b572a)];
        [_textColorArray addObject:UIColorFromRGB(0xae7a28)];
     
        [_textColorArray enumerateObjectsUsingBlock:^(UIColor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [_textColorBtnArray addObject:[self solidColorBtn:obj index:idx]];
        }];
        float fwidthx = (_backgroundView.frame.size.height-31-20)*9.0/16.0 + 10;
        _solidColorView.showsVerticalScrollIndicator = NO;
        _solidColorView.showsHorizontalScrollIndicator = NO;
        _solidColorView.contentSize = CGSizeMake(_textColorBtnArray.count*fwidthx + 20, 0);
    }
    return _solidColorView;
}

-(UIButton*)solidColorBtn:(UIColor *) color  index:(int) index
{
    float fwidthx = (_backgroundView.frame.size.height-31-20)*9.0/16.0;
    
    UIButton *solidColorBtn = [[UIButton alloc] initWithFrame:CGRectMake( 10+(10+fwidthx)*index , 10, fwidthx, _backgroundView.frame.size.height-31-20)];
    solidColorBtn.backgroundColor = color;
    solidColorBtn.layer.borderColor = color.CGColor;
    solidColorBtn.layer.borderWidth = 2.0;
    solidColorBtn.tag = index;
    solidColorBtn.layer.cornerRadius = 5;
    solidColorBtn.layer.masksToBounds = YES;
    [solidColorBtn addTarget:self action:@selector(solidColor_Btn:) forControlEvents:UIControlEventTouchUpInside];
    [_solidColorView addSubview:solidColorBtn];
    
    return solidColorBtn;
}
-(void)solidColor_Btn:(UIButton *) btn
{
    [_textColorBtnArray enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.layer.borderColor = obj.backgroundColor.CGColor;
    }];
    btn.layer.borderColor = Background_COLOR.CGColor;
    [btn addSubview:backgroundImageView];
    
    _materialImage.layer.borderColor =  [UIColor clearColor].CGColor;
    [_transparencyVolumeSlider setValue:1.0];
    currentColorIndex = btn.tag;
    
    [self initPlayer];
}

- (void)background_Btn:(UIButton *)sender {
    self.albumTitleView.hidden = NO;
    self.albumView.hidden = NO;
    publishBtn.hidden = YES;
    backBtn.hidden = YES;
    albumBackBtn.hidden = NO;
    UIButton *videoBtn = [self.albumTitleView viewWithTag:1];
    [self videoBtnAction:videoBtn];
}

-(UIView*)albumTitleView
{
    if( !_albumTitleView )
    {
        _albumTitleView =  [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH , kToolbarHeight)];
        _albumTitleView.backgroundColor = [UIColor blackColor];
        UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        videoBtn.frame = CGRectMake(64, 0, _albumTitleView.frame.size.width/2.0-64, 44);
        
        [videoBtn setTitle:RDLocalizedString(@"视频", nil) forState:UIControlStateNormal];
        [videoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [videoBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        videoBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
        videoBtn.tag = 1;
        videoBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [videoBtn addTarget:self action:@selector(videoBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.albumTitleView addSubview:videoBtn];
        
        UIButton *picBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        picBtn.frame = CGRectMake(_albumTitleView.frame.size.width/2.0, 0, _albumTitleView.frame.size.width/2.0-64, 44);
        picBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [picBtn setTitle:RDLocalizedString(@"图片", nil) forState:UIControlStateNormal];
        [picBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [picBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        picBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
        picBtn.tag = 2;
        [picBtn addTarget:self action:@selector(picBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.albumTitleView addSubview:picBtn];
        
        [self initAlbumViewWithFrame:CGRectMake(0, playerView.frame.size.height + playerView.frame.origin.y, kWIDTH, kHEIGHT - playerView.frame.size.height - playerView.frame.origin.y - kToolbarHeight)];
        [self.view addSubview:_albumTitleView];
        _albumTitleView.hidden = YES;
    }
    return _albumTitleView;
}

- (void)initAlbumViewWithFrame:(CGRect)frame {
    self.albumView = [[UIView alloc] initWithFrame:frame];
    self.albumView.backgroundColor = [UIColor blackColor];
    self.albumView.hidden = YES;
    [self.view addSubview:self.albumView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 37)/2.0, (18 - 4)/2.0, 37, 4)];
    lineView.backgroundColor = UIColorFromRGB(0xb2b2b2);
    lineView.layer.cornerRadius = 2.0;
    [self.albumView addSubview:lineView];
    
    UIButton *pullUpDownAlbumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    pullUpDownAlbumBtn.frame = CGRectMake((kWIDTH - kWIDTH/5.0)/2.0, 0, kWIDTH/5.0, 18);
    [pullUpDownAlbumBtn addTarget:self action:@selector(pullUpDownAlbumBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [pullUpDownAlbumBtn addTarget:self action:@selector(pullUpDownAlbumBtnAction:) forControlEvents:UIControlEventTouchDragExit];
    [self.albumView addSubview:pullUpDownAlbumBtn];
    
    self.albumScrollView = [[UIScrollView alloc] init];
    self.albumScrollView.frame = CGRectMake(0, 18, kWIDTH, self.albumView.bounds.size.height - 18);
    self.albumScrollView.showsHorizontalScrollIndicator = NO;
    self.albumScrollView.showsVerticalScrollIndicator = YES;
    self.albumScrollView.pagingEnabled = YES;
    self.albumScrollView.delegate = self;
    self.albumScrollView.bounces = NO;
    if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO || ((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
        self.albumScrollView.contentSize = CGSizeMake(self.albumScrollView.frame.size.width, 0);
    }else{
        self.albumScrollView.contentSize = CGSizeMake(self.albumScrollView.frame.size.width*2, 0);
    }
    [self.albumView addSubview:self.albumScrollView];
    
    float width = (kWIDTH - 4)/5.0;
    if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        UICollectionViewFlowLayout * flow_video = [[UICollectionViewFlowLayout alloc] init];
        flow_video.scrollDirection = UICollectionViewScrollDirectionVertical;
        flow_video.itemSize = CGSizeMake(width,width);
        flow_video.minimumLineSpacing = 1.0;
        flow_video.minimumInteritemSpacing = 1.0;
        
        UICollectionView *videoCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, self.albumScrollView.bounds.size.height) collectionViewLayout:flow_video];
        videoCollectionView.backgroundColor = [UIColor clearColor];
        videoCollectionView.tag = 1;
        videoCollectionView.dataSource = self;
        videoCollectionView.delegate = self;
        [videoCollectionView registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"albumCell"];
        [self.albumScrollView addSubview:videoCollectionView];
    }
    if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        CGRect tableRect;
        if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO
           || ((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE)
        {
            tableRect = CGRectMake(0, 0, self.albumScrollView.frame.size.width, self.albumScrollView.frame.size.height);
        }else{
            tableRect = CGRectMake(self.albumScrollView.frame.size.width, 0, self.albumScrollView.frame.size.width, self.albumScrollView.frame.size.height);
        }
        
        UICollectionViewFlowLayout * flow_pic = [[UICollectionViewFlowLayout alloc] init];
        flow_pic.scrollDirection = UICollectionViewScrollDirectionVertical;
        flow_pic.itemSize = CGSizeMake(width,width);
        flow_pic.minimumLineSpacing = 1.0;
        flow_pic.minimumInteritemSpacing = 1.0;
        
        UICollectionView *picCollectionView = [[UICollectionView alloc] initWithFrame: tableRect collectionViewLayout:flow_pic];
        picCollectionView.backgroundColor = [UIColor clearColor];
        picCollectionView.dataSource = self;
        picCollectionView.delegate = self;
        picCollectionView.tag = 2;
        [picCollectionView registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"albumCell"];
        [self.albumScrollView addSubview:picCollectionView];
    }
    
    if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        self.videoArray = [NSMutableArray arrayWithObject:kOthersAlbum];
    }
    if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        self.picArray = [NSMutableArray arrayWithObject:kOthersAlbum];
    }
    [self loadVideoAndPhoto];
}

- (void)videoBtnAction:(UIButton *)sender {
    sender.selected = YES;
    UIButton *picBtn = [self.albumTitleView viewWithTag:2];
    picBtn.selected = NO;
    WeakSelf(self);
    [UIView animateWithDuration:0.25 animations:^{
        StrongSelf(self);
        strongSelf.albumScrollView.contentOffset = CGPointMake(0, 0);
    }];
}
- (void)picBtnAction:(UIButton *)sender {
    sender.selected = YES;
    UIButton *videoBtn = [self.albumTitleView viewWithTag:1];
    videoBtn.selected = NO;
    WeakSelf(self);
    [UIView animateWithDuration:0.25 animations:^{
        StrongSelf(self);
        strongSelf.albumScrollView.contentOffset = CGPointMake(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL ? strongSelf.albumScrollView.frame.size.width : 0, 0);
    }];
}

- (void)refreshAblumScrollViewViewFrame {
    CGRect frame = self.albumScrollView.frame;
    frame.size.height = self.albumView.bounds.size.height - 18;
    self.albumScrollView.frame = frame;
    
    UICollectionView *collectionView = [self.albumScrollView viewWithTag:1];
    frame = collectionView.frame;
    frame.size.height = self.albumScrollView.bounds.size.height;
    collectionView.frame = frame;
    
    collectionView = [self.albumScrollView viewWithTag:2];
    frame = collectionView.frame;
    frame.size.height = self.albumScrollView.bounds.size.height;
    collectionView.frame = frame;
    
    self.albumScrollView.contentOffset = CGPointMake(0, 0);
}

- (void)pullUpDownAlbumBtnAction:(UIButton *)sender {
    if (self.albumView.frame.origin.y == kNavigationBarHeight) {
        WeakSelf(self);
        [UIView animateWithDuration:0.3 animations:^{
            [weakSelf refreshAblumScrollViewViewFrame];
        }];
    }else {
        WeakSelf(self);
        [UIView animateWithDuration:0.3 animations:^{
            StrongSelf(self);
            strongSelf.albumView.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kHEIGHT - kNavigationBarHeight - kToolbarHeight);
            [strongSelf refreshAblumScrollViewViewFrame];
        }];
    }
}

#pragma mark - 加载相册
- (void)loadVideoAndPhoto {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
        {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                      message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                      delegate:self
                                      cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                      otherButtonTitles:RDLocalizedString(@"取消",nil), nil];
            alertView.tag = 102;
            [alertView show];
        }
            break;
        case PHAuthorizationStatusAuthorized:
            [self loadDatasource];
            break;
            
        default:
        {
            WeakSelf(self);
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if (status == PHAuthorizationStatusAuthorized) {
                        [strongSelf loadDatasource];
                        UICollectionView *videoCollectionView = [strongSelf.albumScrollView viewWithTag:1];
                        UICollectionView *photoCollectionView = [strongSelf.albumScrollView viewWithTag:2];
                        if(((RDNavigationViewController *)strongSelf.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
                            [photoCollectionView reloadData];
                        }else if(((RDNavigationViewController *)strongSelf.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
                            [videoCollectionView reloadData];
                        }else {
                            [videoCollectionView reloadData];
                            [photoCollectionView reloadData];
                        }
                    }else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                        UIAlertView *alertView = [[UIAlertView alloc]
                                                  initWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                                  message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                                  delegate:strongSelf
                                                  cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                                  otherButtonTitles:RDLocalizedString(@"取消",nil), nil];
                        alertView.tag = 102;
                        [alertView show];
                    }
                });
            }];
        }
            break;
    }
}

- (void)loadDatasource{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    //    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];//modificationDate
    if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if(((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                             PHAssetMediaTypeVideo];
    }
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        if (![collection isKindOfClass:[PHAssetCollection class]]// 有可能是PHCollectionList类的的对象，过滤掉
            || collection.estimatedAssetCount <= 0)// 过滤空相册
        {
            continue;
        }
        if ([RDHelpClass isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            for (PHAsset *asset in fetchResult) {
                if (asset.mediaType == PHAssetMediaTypeVideo) {
                    [self.videoArray insertObject:asset atIndex:1];
                }else{
                    [self.picArray insertObject:asset atIndex:1];
                }
            }
            break;
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    UIButton *videoBtn = [self.albumTitleView viewWithTag:1];
    UIButton *photoBtn = [self.albumTitleView viewWithTag:2];
    if (scrollView.contentOffset.x == 0) {
        videoBtn.selected = YES;
        photoBtn.selected = NO;
    }else {
        videoBtn.selected = NO;
        photoBtn.selected = YES;
    }
}

#pragma mark- UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if(collectionView.tag == 1){
        return self.videoArray.count;
    }
    else{
        return self.picArray.count;
    }
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"albumCell";
    //缩率图的大小这个地方数值不能设置大了
    float thumbWidth = 80;
    LocalPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if(!cell){
        cell = [[LocalPhotoCell alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    }
    cell.addBtn.hidden = YES;
    
    if (indexPath.row == 0) {
        cell.titleLbl.hidden = NO;
        cell.titleLbl.text = RDLocalizedString(@"其他\n相册", nil);
        cell.ivImageView.image = nil;
        cell.ivImageView.hidden = YES;
        cell.durationBlack.hidden = YES;
        return cell;
    }else {
        cell.titleLbl.hidden = YES;
        cell.ivImageView.hidden = NO;
        //视频集
        if(collectionView.tag == 1){
            if([self.videoArray[indexPath.row] isKindOfClass:[NSDictionary class]]){
                NSDictionary *dic = self.videoArray[indexPath.row];
                UIImage *thumbImage = [dic objectForKey:@"thumbImage"];
                cell.durationBlack.hidden = NO;
                cell.duration.hidden = NO;
                double duration = CMTimeGetSeconds([[dic objectForKey:@"durationTime"] CMTimeValue]);
                cell.duration.text = [RDHelpClass timeToStringFormat:duration];
                [cell.ivImageView setImage:thumbImage];
            }
            else if([self.videoArray[indexPath.row] isKindOfClass:[PHAsset class]]){
                PHAsset *asset=self.videoArray[indexPath.row];
                cell.durationBlack.hidden = NO;
                cell.duration.hidden = NO;
                double duration = asset.duration;
                cell.duration.text = [RDHelpClass timeToStringFormat:duration];
                if([[RD_ImageManager manager] isICloudnoDownLoad:asset]){
                    cell.icloudIcon.hidden = NO;
                }else{
                    cell.icloudIcon.hidden = YES;
                }
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                        cell.ivImageView.userInteractionEnabled = YES;
                        [cell.ivImageView setImage:photo];
                        cell.userInteractionEnabled = YES;
                    }
                }];
            }
            return cell;
        }
        //图片集
        else{
            if(indexPath.row < self.picArray.count){
                PHAsset *asset = self.picArray[indexPath.row];
                cell.durationBlack.hidden = YES;
                cell.duration.hidden = YES;
                if([[RD_ImageManager manager] isICloudnoDownLoad:asset]){
                    cell.icloudIcon.hidden = NO;
                }else{
                    cell.icloudIcon.hidden = YES;
                }
                if ([[asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
                    cell.gifLbl.hidden = NO;
                }else {
                    cell.gifLbl.hidden = YES;
                }
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){
                        cell.ivImageView.userInteractionEnabled = YES;
                        [cell.ivImageView setImage:photo];
                        cell.userInteractionEnabled = YES;
                    }
                }];
            }
            return cell;
        }
    }
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    LocalPhotoCell *cell = (LocalPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.videoMark.hidden = YES;
    if(indexPath.row == 0){
        RDOtherAlbumsViewController *otherAlbumsVC = [[RDOtherAlbumsViewController alloc] init];
        if (collectionView.tag == 1) {
            otherAlbumsVC.supportFileType = ONLYSUPPORT_VIDEO;
        }else if (collectionView.tag == 2) {
            otherAlbumsVC.supportFileType = ONLYSUPPORT_IMAGE;
        }
        WeakSelf(self);
        otherAlbumsVC.finishBlock = ^(NSURL *url, UIImage *thumbImage) {
            //添加
            [weakSelf backgroundFile:url image:thumbImage isGIF:false imageData:nil];
        };
        [self.navigationController pushViewController:otherAlbumsVC animated:YES];
    }else{
        WeakSelf(self);
        if(collectionView.tag == 1){
            NSInteger index = [collectionView indexPathForCell:cell].row;
            if([self.videoArray[index] isKindOfClass:[NSMutableDictionary class]]){
                AVURLAsset *resultAsset = [self.videoArray[index] objectForKey:@"urlAsset"];
                
                cell.icloudIcon.hidden = YES;
                [cell.progressView setPercent:0];
                //添加
                [self backgroundFile:resultAsset.URL image:cell.ivImageView.image isGIF:false imageData:nil];
            }else{
                PHAsset *resouceAsset = self.videoArray[index];
                PHVideoRequestOptions *opt_s = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
                opt_s.version = PHVideoRequestOptionsVersionOriginal;
                opt_s.networkAccessAllowed = NO;
                [[PHImageManager defaultManager] requestAVAssetForVideo:resouceAsset options:opt_s resultHandler:^(AVAsset * _Nullable asset_l, AVAudioMix * _Nullable audioMix_l, NSDictionary * _Nullable info_l) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        StrongSelf(self);
                        if(asset_l){
                            cell.isDownloadingInLocal = NO;
                            NSURL *fileUrl = [asset_l valueForKey:@"URL"];
                            NSString *localID = resouceAsset.localIdentifier;
                            NSArray *temp = [localID componentsSeparatedByString:@"/"];
                            NSString *uploadVideoFilePath = nil;
                            if (temp.count > 0) {
                                NSString *assetID = temp[0];
                                NSString *ext = fileUrl.pathExtension;
                                if (assetID && ext) {
                                    uploadVideoFilePath = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", ext, assetID, ext];
                                }
                            }
                            NSURL *asseturl = [NSURL URLWithString:uploadVideoFilePath];
#if 1   //20191029  iPhone6s/7(系统iOS 13.1.3)从iCloud上下载的视频用上面的路径，读取不到视频轨道
                            AVURLAsset *asset = [AVURLAsset assetWithURL:asseturl];
                            if (![asset isPlayable]) {
                                asseturl = fileUrl;
                            }
#endif
                            //添加
                            [strongSelf backgroundFile:asseturl image:cell.ivImageView.image isGIF:false imageData:nil];
                            return;
                        }
                        if(cell.isDownloadingInLocal){
                            return;
                        }
                        cell.isDownloadingInLocal = YES;
                        [strongSelf.hud setCaption:RDLocalizedString(@"Videos are syncing from iCloud, please retry later", nil)];
                        [strongSelf.hud show];
                        [strongSelf.hud hideAfter:1];
                        
                        PHVideoRequestOptions *opts = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
                        opts.version = PHVideoRequestOptionsVersionOriginal;
                        opts.networkAccessAllowed = YES;
                        opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                            [cell.progressView setPercent:progress];
                        };
                        [[PHImageManager defaultManager] requestAVAssetForVideo:resouceAsset options:opts resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                cell.isDownloadingInLocal = NO;
                                [cell.progressView setPercent:0];
                                cell.icloudIcon.hidden = YES;
                            });
                        }];
                    });
                }];
            }
        }else{
            NSInteger index = [collectionView indexPathForCell:cell].row;
            PHAsset *result = (PHAsset *)self.picArray[index];
            
            PHImageRequestOptions  *opt_s = [[PHImageRequestOptions alloc] init]; // assets的配置设置
            opt_s.version = PHVideoRequestOptionsVersionCurrent;
            opt_s.networkAccessAllowed = NO;
            opt_s.resizeMode = PHImageRequestOptionsResizeModeExact;
            [[PHImageManager defaultManager] requestImageDataForAsset:result options:opt_s resultHandler:^(NSData * _Nullable imageData_l, NSString * _Nullable dataUTI_l, UIImageOrientation orientation_l, NSDictionary * _Nullable info_l) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if(imageData_l){
                        cell.isDownloadingInLocal = NO;
                        if([[info_l allKeys] containsObject:@"PHImageFileURLKey"] || [[info_l allKeys] containsObject:@"PHImageFileUTIKey"]){
                            NSURL *url = info_l[@"PHImageFileURLKey"];
                            if (!url) {
                                url = info_l[@"PHImageFileUTIKey"];
                            }
                            NSString *localID = result.localIdentifier;
                            NSArray *temp = [localID componentsSeparatedByString:@"/"];
                            NSString *uploadVideoFilePath = nil;
                            if (temp.count > 0) {
                                NSString *assetID = temp[0];
                                NSString *ext = url.pathExtension;
                                if (assetID && ext) {
                                    uploadVideoFilePath = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", ext, assetID, ext];
                                }
                            }
                            cell.icloudIcon.hidden = YES;
                            //添加
                            float imageDuration = [RDVECore isGifWithData:imageData_l];
                            [strongSelf backgroundFile:[NSURL URLWithString:uploadVideoFilePath] image:nil isGIF: (imageDuration>0) imageData:imageData_l];
                        }
                        return;
                    }else{
                        [strongSelf.hud setCaption:RDLocalizedString(@"Photos are syncing from iCloud, please retry later", nil)];
                        [strongSelf.hud show];
                        [strongSelf.hud hideAfter:1];
                    }
                    if(cell.isDownloadingInLocal){
                        return;
                    }
                    cell.isDownloadingInLocal = YES;
                    
                    PHImageRequestOptions  *opts = [[PHImageRequestOptions alloc] init]; // assets的配置设置
                    opts.version = PHVideoRequestOptionsVersionCurrent;
                    opts.networkAccessAllowed = YES;
                    opts.resizeMode = PHImageRequestOptionsResizeModeExact;
                    opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                        cell.progressView.percent = progress;
                    };
                    [[PHImageManager defaultManager] requestImageDataForAsset:result options:opts resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                        if([[info allKeys] containsObject:@"PHImageFileURLKey"] || [[info_l allKeys] containsObject:@"PHImageFileUTIKey"]){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                cell.isDownloadingInLocal = NO;
                                cell.icloudIcon.hidden = YES;
                            });
                        }
                    }];
                });
            }];
        }
    }
}

#pragma mark- 选中 背景
-(void)backgroundFile:(NSURL *) url image:(UIImage * ) image isGIF:(BOOL) isGIF imageData:(NSData *)imageData
{
    _albumTitleView.hidden = YES;
    _albumView.hidden = YES;
    albumBackBtn.hidden = YES;
    publishBtn.hidden = NO;
    backBtn.hidden = NO;
//    albumDeleteBtn.hidden = NO;
    
    RDFile *file = [RDFile new];
    if( _albumScrollView.contentOffset.x == 0 )
    {
        //视频
        file.contentURL = url;
        file.fileType = kFILEVIDEO;
        file.isReverse = NO;
        AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
        CMTime duration = asset.duration;
        file.videoDurationTime = duration;
        file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
        file.reverseVideoTimeRange = file.videoTimeRange;
        file.videoTrimTimeRange = kCMTimeRangeInvalid;
        file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
        file.videoVolume = 1.0;
        file.speedIndex = 2;
        file.isVerticalMirror = NO;
        file.isHorizontalMirror = NO;
        file.speed = 1;
        file.crop = CGRectMake(0, 0, 1, 1);
        
        __weak typeof(self) weakSelf = self;
        RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
        trimVideoVC.globalFilters = nil;
        trimVideoVC.trimFile = [file copy];
        trimVideoVC.editVideoSize = exportVideoSize;
        trimVideoVC.musicURL = _musicURL;
        trimVideoVC.musicVolume = _musicVolume;
        trimVideoVC.musicTimeRange = _musicTimeRange;
        trimVideoVC.TrimVideoFinishBlock = ^(CMTimeRange timeRange) {
            StrongSelf(self);
            if(file.isReverse){
                file.reverseVideoTrimTimeRange = timeRange;
            }else if (file.isGif) {
                file.imageTimeRange = timeRange;
            }else {
                file.videoTrimTimeRange = timeRange;
            }
            [strongSelf mater_void:file];
        };
        
        [self.navigationController pushViewController:trimVideoVC animated:YES];
        
    }
    else
    {
        //图片
        if (isGIF) {
            file.isGif = YES;
            file.speedIndex = 2;
            file.gifData = imageData;
        }else {
            file.speedIndex = 1;
        }
        
        CMTime time = CMTimeAdd(_audioPathArray[_audioPathArray.count-1].timeRang.start, _audioPathArray[_audioPathArray.count-1].timeRang.duration);
        if( _audioPathArray == nil )
            time = textObjectArray[textObjectArray.count-1].showTime;
        
        file.imageDurationTime = time;
        
        file.contentURL = url;
        file.fileType = kFILEIMAGE;
        [self mater_void:file];
    }

}

-(void)mater_void:(RDFile *) file
{
    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    
    [self adaptation:file];
    
    
    [_textColorBtnArray enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.layer.borderColor = obj.backgroundColor.CGColor;
    }];
    
    
    if( !_materialBtn )
    {
        float fwidthx = (_backgroundView.frame.size.height-31-20)*9.0/16.0;
        _albumBtnView.frame = CGRectMake( 0, 31, fwidthx*2.0+30, _backgroundView.frame.size.height-31 );
        
        _solidColorView.frame = CGRectMake(_albumBtnView.frame.size.width+_albumBtnView.frame.origin.x, 31, _backgroundView.frame.size.width-(_albumBtnView.frame.size.width+_albumBtnView.frame.origin.x), _backgroundView.frame.size.height-31);
        
        _materialBtn = [[UIButton alloc] initWithFrame:CGRectMake( fwidthx + 20, 10, fwidthx, _backgroundView.frame.size.height-31-20)];
        _materialBtn.backgroundColor = BOTTOM_COLOR;
        _materialBtn.layer.borderColor = BOTTOM_COLOR.CGColor;
        _materialBtn.layer.borderWidth = 1.0;
        _materialBtn.layer.cornerRadius = 5;
        _materialBtn.layer.masksToBounds = YES;
        [_materialBtn addTarget:self action:@selector(mater_btn:) forControlEvents:UIControlEventTouchUpInside];
        [_albumBtnView addSubview:_materialBtn];
        
        _materialImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _materialBtn.frame.size.width, _materialBtn.frame.size.height)];
        _materialImage.contentMode = UIViewContentModeScaleAspectFill;
        
        [_materialBtn addSubview:_materialImage];
        _materialImage.layer.cornerRadius = 5;
        _materialImage.layer.masksToBounds = YES;
        _materialImage.layer.borderColor = Background_COLOR.CGColor;
        _materialImage.layer.borderWidth = 3.0;
    }
    else
        _materialImage.layer.borderColor = Background_COLOR.CGColor;
    
    [_materialBtn addSubview:backgroundImageView];
    _materialImage.image = file.thumbImage;
    
    [_transparencyVolumeSlider setValue:1.0];
    currentColorIndex = -1;
    currentBackgroundFile = file;
    
    [self initPlayer];
//    [self initThumbImageVideoCore];
}

-(void)mater_btn:(UIButton *) btn
{
    [_transparencyVolumeSlider setValue:1.0];
    [_materialBtn addSubview:backgroundImageView];
    currentColorIndex = -1;
    _materialImage.layer.borderColor = Background_COLOR.CGColor;
    [self initPlayer];
//    [self initThumbImageVideoCore];
}


-(void)adaptation:(RDFile *) file
{
    float fProportionP = exportVideoSize.width/exportVideoSize.height;
    CGSize  fileVideoSize = CGSizeZero;
    if( file.fileType == kFILEVIDEO )
        fileVideoSize = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:file.contentURL]];
    else
    {
        UIImage *image = file.thumbImage ? file.thumbImage : [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
        fileVideoSize = image.size;
    }
    CGSize  size = CGSizeZero;
    float width = (fProportionP) * fileVideoSize.height;
    if( width <= fileVideoSize.width )
    {
        size = CGSizeMake(width, fileVideoSize.height);
    }
    else
    {
        float height = (1.0/fProportionP) * fileVideoSize.width;
        size = CGSizeMake(fileVideoSize.width, height);
    }
    
    float fwidth = (fileVideoSize.width - size.width)/fileVideoSize.width;
    float fheight = (fileVideoSize.height - size.height)/fileVideoSize.height;
    
    file.crop = CGRectMake( fwidth/2.0 , fheight/2.0, 1.0 - fwidth, 1.0 - fheight);
    file.cropRect = CGRectMake(-1, -1, -1, -1);
    file.fileCropModeType =  kCropTypeOriginal;
}

-(void)albumBack
{
    _albumTitleView.hidden = YES;
    _albumView.hidden = YES;
    
    publishBtn.hidden = NO;
    backBtn.hidden = NO;
    albumBackBtn.hidden = YES;
}

-(UISwitch *)animationBtn
{
    if(!_animationBtn)
    {
        _animationBtn = [[UISwitch alloc] initWithFrame:CGRectMake(titleView.frame.size.width - 69 - 60 - 60, (44-15)/2.0 - 8, 60, 15)];
        _animationBtn.onTintColor=Main_Color;
        _animationBtn.tintColor=Main_Color;
        _animationBtn.thumbTintColor= [UIColor whiteColor];
        [_animationBtn setOn:YES animated:YES];
        [_animationBtn addTarget:self action:@selector(getValue1) forControlEvents:UIControlEventValueChanged];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(titleView.frame.size.width - 69 - 60, (44-25)/2.0, 60, 25)];
        label.text = RDLocalizedString(@"更多动画", nil);
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12.0];
        [titleView addSubview:label];
        [titleView addSubview:_animationBtn];
        
    }
    return _animationBtn;
}
-(void)getValue1{
    if( (_animationBtn == nil) || (_animationBtn.isOn) )
    {
        for (int i = 0; i<textLayerArray.count; i++) {
            textLayerArray[i].textDisplayAnimation = [self getRandomNumber:0 to:3];
        }
    }
    else
    {
        for (int i = 0; i<textLayerArray.count; i++) {
            textLayerArray[i].textDisplayAnimation = 0;
        }
    }
}

@end
