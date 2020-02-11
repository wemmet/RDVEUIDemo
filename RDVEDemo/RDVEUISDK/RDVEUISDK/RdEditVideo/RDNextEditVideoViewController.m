//
//  RDNextEditVideoViewController.m
//  RDVEUISDK
//
//  Created by emmet on 2017/6/30.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDEditVideoViewController.h"
#import "RDNextEditVideoViewController.h"
#import "ScrollViewChildItem.h"
#import "DubbingTrimmerView.h"
#import "CaptionVideoTrimmerView.h"
#import "RDATMHud.h"
#import "RDFileDownloader.h"
#import "RDMBProgressHUD.h"
#import "RDSVProgressHUD.h"
#import "RDExportProgressView.h"
#import "RDZipArchive.h"
#import "UIImage+RDWebP.h"
#import "RD_RDReachabilityLexiu.h"
#import "CircleView.h"
#import "RDLocalMusicViewController.h"
#import "RDCloudMusicViewController.h"
#import "UIImageView+RDWebCache.h"
#import "RDDownTool.h"
#import "UIButton+RDWebCache.h"
#import "RD_VideoThumbnailView.h"
#import <math.h>
#import "RD_SortViewController.h"
#import "RDMainViewController.h"
#import "RDAddEffectsByTimeline.h"
#import "RDAddEffectsByTimeline+Subtitle.h"
#import "RDAddEffectsByTimeline+Sticker.h"
#import "RDAddEffectsByTimeline+Dewatermark.h"
#import "RDAddEffectsByTimeline+Collage.h"
#import "RDChooseMusic.h"
#import "RDYYWebImage.h"
//#import "RDAddItemButton.h"

//线程锁
//#import <os/lock.h>

//文字板
#import "CustomTextPhotoViewController.h"

//颜色板
#import "SubtitleColorControl.h"

//特效
#import "RDFXFilter.h"

#import <MediaPlayer/MediaPlayer.h>
#define kRefreshThumbMaxCounts 50
#define ENABLEAUDIOEFFECT 1  //开启实时调整音量及音效

@interface RDNextEditVideoViewController ()<RDVECoreDelegate,RDAlertViewDelegate,DubbingTrimmerDelegate,CaptionVideoTrimmerDelegate,RDMBProgressHUDDelegate,UIScrollViewDelegate,ScrollViewChildItemDelegate,UIAlertViewDelegate,AVAudioRecorderDelegate,RD_VideoThumbnailViewDelegate,RDAddEffectsByTimelineDelegate,AVAudioPlayerDelegate,CustomTextDelegate,SubtitleColorControlDelegate,RDPasterTextViewDelegate>
{
    float                         playerViewOriginX;
    float                         playerViewHeight;
    CGRect                        bottomViewRect;
    UILabel         *titleLabel;
    UIButton        *cancelBtn;
    NSMutableArray  *toolItems;
    NSArray         *mvList;
    NSMutableArray  *_mvDataPointArray;
    float             mvEffectFps;//20180720
    NSInteger       lastThemeMVIndex;
    NSMutableArray  *mvMusicArray;
    NSMutableArray  *selectMVEffects;
    NSMutableDictionary  *selectMVEffectBack;
    NSArray         *musicList;
    NSMutableArray  *globalFilters;
    NSInteger       selectMusicIndex;
    NSInteger       selectFilterIndex;
    
    NSMutableArray<DubbingRangeView *>  *dubbingNewMusicArr;
    NSMutableArray<DubbingRangeView *>  *dubbingMusicArr;
    NSMutableArray<RDMusic *>           *dubbingArr;
    
    CMTime          startDubbingTime;
    CMTime          startPlayTime;
    NSString        *dubbingCafFilePath;
    NSString        *dubbingMp3FilePath;
    AVAudioSession  *session;
    AVAudioRecorder *recorder;
    NSMutableArray  *thumbTimes;
    NSMutableArray  *thumbTimesImageArray;
    
    NSMutableArray  *EffectVideothumbTimes;
    NSMutableArray  *EffectVideothumbTimesIndexArray;
    
    NSMutableArray <RDCaption *> *subtitles;
    NSMutableArray <RDCaptionRangeViewFile *> *subtitleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldSubtitleFiles;
    
    NSMutableArray <RDCaption *> *stickers;
    NSMutableArray <RDCaptionRangeViewFile *> *stickerFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldStickerFiles;
    float addingMaterialDuration;
    
    NSMutableArray <RDAssetBlur *> *blurs;
    NSMutableArray <RDCaptionRangeViewFile *> *blurFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldBlurFiles;
    
    NSMutableArray <RDDewatermark *> *dewatermarks;
    NSMutableArray <RDCaptionRangeViewFile *> *dewatermarkFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldDewatermarkFiles;
    
    NSMutableArray <RDMosaic *> *mosaics;
    NSMutableArray <RDCaptionRangeViewFile *> *mosaicFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldMosaicFiles;
    
    NSMutableArray <RDWatermark *> *collages;
    NSMutableArray <RDCaptionRangeViewFile *> *collageFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldCollageFiles;

    NSMutableArray <RDWatermark *> *doodles;
    NSMutableArray <RDCaptionRangeViewFile *> *doodleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldDoodleFiles;
    
    NSMutableArray <RDMusic *> *soundMusics;
    NSMutableArray <RDCaptionRangeViewFile *> *soundMusicFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldSoundMusicFiles;
    
    NSMutableArray <RDMusic *> *musics;
    NSMutableArray <RDCaptionRangeViewFile *> *musicFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldMusicFiles;
    
    NSMutableArray<RDFXFilter*>*        fXArray;         //未保存的滤镜特效
    NSMutableArray <RDCaptionRangeViewFile *> *fXFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldFXFiles;
    
    RDVECore        *thumbImageVideoCore;//截取缩率图
    BOOL             yuanyinOn;
    BOOL             isContinueExport;
    bool             isExport;
    
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    BOOL             _idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    NSMutableArray      * scenes;
    //特效视频
    UIView                  * FXView;
    NSMutableArray <RDCustomFilter*>*        customFilterArray;         //未保存的滤镜特效
    NSMutableArray <RDCaptionRangeViewFile *> *customFilterFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldcustomFilterFiles;
    
    NSMutableArray<RDCustomFilter*>*        oldCustomFilterArray;      //保存的滤镜特效
    RDCustomFilter  *                       CurrentfilterCustomFilter;
    //时间界面
    UIView                  * timeFxView;
    TimeFilterType _timeEffectType;          //为保存的时间特效
    CMTime          startTimeEffect;
    TimeFilterType oldTimeEffectType;        //保存的时间特效
    CMTime                        seekTime;
    CMTimeRange               _effectTimeRange;         //未保存的时间特效时长
    CMTimeRange               oldEffectTimeRange;       //保存的时间特效时长
    BOOL                    cancel;
    NSMutableArray          * filterFxArray;
    NSMutableArray<UIImageView *> *filterFxImageArray;
    NSInteger                 selectedFilterFxIndex;
    NSInteger                 selectedFxTypeIndex;
    
    //特效 （新）
    NSMutableArray <RDCaptionRangeViewFile *> *customFilterMusicFiles;
    CMTime                  currentFilterTime;
    
    UIView              *MainCircleView;
    RDMBProgressHUD     *ProgressHUD;
    //变声
    NSArray              *soundEffectArray;
    NSInteger             selectedSoundEffectIndex;
    UIScrollView         *soundEffectScrollView;
    RDZSlider            *soundEffectSlider;
    UILabel              *soundEffectLabel;
    float                 oldPitch;
    //画中画
    BOOL                          isNotNeedPlay;
    //字幕
    RDCaptionRangeViewFile      *selectedSubtitleFile;
    //贴纸 Sticker
    RDCaptionRangeViewFile      *selectedStickerFile;
    UILabel                     *toolbarTitleLbl;
    NSMutableArray              *transitionArray;
    //功能栏
    NSMutableArray              *functionalItems;
    NSInteger                    oldFilterType;         //滤镜
    float                        filterStrength;        //滤镜强度
    float                        oldFilterStrength;     //旧 滤镜强度
    NSInteger                    oldMusicIndex;         //配乐
    RDMusic                      *oldmusic;             //云音乐地址
    NSInteger                    oldSoundEffectIndex;  //变声
    RDAdvanceEditType            selecteFunction;
    BOOL                         isNewUI;             //新界面
    CGSize                       proportionVideoSize;  //比例视频分辨率
    CGSize                       selectVideoSize;      //选中视频分辨率
    NSInteger                    oldProportionIndex;
    NSInteger                    selectProportionIndex;
    BOOL                         isVague;              //是否模糊背景
    BOOL                         oldIsVague;              //是否模糊背景
    NSMutableArray<UIColor *>    *fillColorItems;       //背景颜色数组
    BOOL                         isNoBackground;        //是否无背景
    BOOL                         oldisNoBackground;     // 旧 是否无背景
    
    BOOL                         isEnlarge;
    BOOL                         oldIsEnlarge;          //图片运动是否放大
    UIView                      *selectedFunctionView;
    NSInteger                   oldLastThemeMVIndex;    //MV 旧
    bool                        isProprtionUI;          //为 比例修改界面 不显示 播放进度条
    //贴纸
    RDCaptionRangeViewFile                   *oldStickerCaptionRangeViewFile;    //旧 贴纸效果
    CaptionVideoTrimmerView     *bottomTrimmerView;
    UILabel                     *bottomCurrentTimeLbl;
    RDFile                      *coverFile, *oldCoverFile;
    UIImageView                 *coverIV;
    UIView                      *coverAuxView;
    //是否刷新 缩略图
    BOOL                        isRefreshClipEditing;           //从片段编辑出来后是否需要更新缩略图
    BOOL                        isRefreshOrder;                 //从调序出来后是否需要更新缩略图
    
    UIScrollView                *addedMaterialEffectScrollView;
    UIImageView                 *selectedMaterialEffectItemIV;
    NSInteger                    selectedMaterialEffectIndex;
    BOOL                         isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    //音量
    float                       oldVolume;
    float                       volumeMultipleM;
    
    BOOL                        enableMV;
    
//    os_unfair_lock              thumbTimesImageArrayLock;
    
    float                       VideoCurrentTime;
    bool                        isRecording;
    
    bool                        isAdd;
    
    //是否进入片段编辑
    bool                        isEditVideoVC;
    //新滤镜
    NSMutableArray              *newFilterSortArray;
    NSMutableArray              *newFiltersNameSortArray;
    CMTimeRange             playTimeRange;
    
    //素材顺序
    int                         selectFileIndex;
    
    int                     currentlabelFilter;
    int                     currentFilterIndex;
    
    //特效预览
    CMTime                  fxStartTime;
    CMTimeRange             fxTimeRange;
    RDFXFilter              *currentFxFilter;
    BOOL                    isPreviewFx;
    
    bool                    isFXUpdate;     //是否定格更新 缩略图
    
    bool                    isFXUpdateTime;       //是否播放
    //存草稿箱
    UIButton               *saveDraftBtn;
    //画布样式 无
    UIImageView *canvasStyleimageView;
    CMTime                  refreshCurrentTime;
}
@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)UIView           *playerView;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic,strong)UIScrollView     *toolBarView;
@property(nonatomic,strong)UIView           *playerToolBar;
@property(nonatomic,strong)UILabel          *currentTimeLabel;
@property(nonatomic,strong)UILabel          *durationLabel;
@property(nonatomic,strong)UIButton         *zoomButton;
@property(nonatomic,strong)RDZSlider        *videoProgressSlider;

@property(nonatomic,strong)UIView               *toolbarTitleView;
@property(nonatomic,strong)UIButton         *toolbarTitlefinishBtn;
@property(nonatomic,strong)UIView               *titleView;
@property(nonatomic,strong)RDExportProgressView *exportProgressView;
//MV
@property(nonatomic,strong)UIView           *mvView;
@property(nonatomic,strong)UIScrollView     *mvChildsView;
//配乐
@property(nonatomic,strong)UIView           *musicView;
@property(nonatomic,strong)UIButton         *dubbingItemBtn;
@property(nonatomic,strong)UILabel          *musicVolumeLabel;
@property(nonatomic,strong)UIButton         *musicVolumeBtn;
@property(nonatomic,strong)UIButton         *videoVolumeBtn;
@property(nonatomic,strong)RDZSlider        *musicVolumeSlider;
@property(nonatomic,strong)RDZSlider        *videoVolumeSlider;
@property(nonatomic,strong)UIScrollView     *musicChildsView;
//音量
@property(nonatomic,strong)UIView           *volumeView;
@property(nonatomic,assign)  float          originalVolume;            //原音音量
@property(nonatomic,strong)RDZSlider        *originalVolumeSlider;
//音效
@property(nonatomic,strong)UIView           *addedMusicVolumeView;
@property(nonatomic,strong)RDZSlider        *addedMusicVolumeSlider;
@property(nonatomic,strong)UIView           *soundView;
//多段配乐
@property(nonatomic,strong)UIView           *multi_trackView;
@property(nonatomic,strong)AVAudioPlayer    *audioPlayer;
@property(nonatomic,assign)double           audioStart;
@property(nonatomic,assign)double           audioDuration;
@property(nonatomic,strong)NSTimer          *audioTimer;
//配音
@property(nonatomic,strong)UIView               *dubbingView;
@property(nonatomic,strong)UIButton             *dubbingPlayBtn;
@property(nonatomic,strong)DubbingTrimmerView   *dubbingTrimmerView;
@property(nonatomic,strong)UIView               *dubbingVolumeView;
@property(nonatomic,strong)UILabel              *dubbingCurrentTimeLbl;
@property(nonatomic,strong)RDZSlider             *dubbingVolumeSlider;
@property(nonatomic,strong)UIButton             *dubbingBtn;
@property(nonatomic,strong)UIButton             *deletedDubbingBtn;
@property(nonatomic,strong)UIButton             *reDubbingBtn;
@property(nonatomic,strong)UIButton             *auditionDubbingBtn;
//变声
@property(nonatomic,strong)UIView               *soundEffectView;
@property(nonatomic,strong)UIView               *customSoundView;
//字幕
@property(nonatomic,strong)UIView                   *subtitleView;
@property(nonatomic,strong)RDAddEffectsByTimeline   *addEffectsByTimeline;
//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;
@property(nonatomic,strong)NSMutableArray   *filtersName;
@property(nonatomic,strong)NSMutableArray   *filters;
@property(nonatomic,strong)RDZSlider        *filterProgressSlider;
@property(nonatomic,strong)UILabel          *percentageLabel;
//贴纸
@property(nonatomic,strong)UIView                   *stickerView;
//去水印
@property(nonatomic,strong)UIView           *dewatermarkView;
//画中画
@property(nonatomic,strong)UIView           *collageView;
@property(nonatomic,strong)RDATMHud         *hud;
@property(nonatomic       )UIAlertView      *commonAlertView;
//功能区分界面
@property(nonatomic,strong)UIView           *functionalAreaView;            //功能区界面
@property(nonatomic,strong)UIScrollView     *functionalAreaScrollView;      //功能栏
@property(nonatomic,strong)UIButton         *playBtn;                       //播放按钮
//比例
@property(nonatomic,strong)UIView           *proportionView;
@property(nonatomic,strong)NSMutableArray<UIButton *> *proportionBtnItems;   //比例按钮数组


//图片运动
@property(nonatomic,strong)UIView          *contentMagnificationView;      //图片运动界面
@property(nonatomic,strong)UISwitch        *contentMagnificationBtn;      //图片运动界面

//封面
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UIView *bottomThumbnailView;

//涂鸦
@property (nonatomic, strong) UIView *doodleView;

@property (nonatomic, strong) UIView *addedMaterialEffectView;
@property (nonatomic, assign) BOOL isAddingMaterialEffect;
@property (nonatomic, assign) BOOL isEdittingMaterialEffect;
@property (nonatomic, assign) BOOL isCancelMaterialEffect;

//其他功能分类
@property (nonatomic, strong) UIView    *otherView;
@property (nonatomic, strong) UIScrollView    *otherScrollView;
@property (nonatomic, strong) UIButton  *otherReturnBtn;

//进度条

@property (nonatomic, strong) UIView                    *captionVideoView;
@property (nonatomic, strong) UILabel                   *captionVideoDurationTimeLbl;
@property (nonatomic, strong) UILabel                   *captionVideoCurrentTimeLbl;

@property (nonatomic,strong)  UIView                    * spanView;
@property (nonatomic, strong) CaptionVideoTrimmerView   *videoTrimmerView;
//添加素材
@property (nonatomic, strong) UIButton  *addMaterialBtn;
@property(nonatomic,strong)UIView               *addLensView;  //添加镜头 界面
@property (nonatomic,assign)bool                isAdd;        //是否添加

//播放 按钮
@property (nonatomic, strong) UILabel   *filterStrengthLabel;
@property (nonatomic, strong) UIView    *captionPlayBtnView;
@property (nonatomic, strong) UIButton  *captionPlayBtn;

//特效

//新滤镜
@property (nonatomic, strong) UIView    * fileterNewView;
@property (nonatomic, strong) UIScrollView    *fileterLabelNewScroView;

@property (nonatomic, strong) UIScrollView    *fileterScrollView;
@property(nonatomic,strong)ScrollViewChildItem *originalItem;

//背景 画布
@property(nonatomic,assign)int          canvas_CurrentFileIndex;    //当前素材序号
@property(nonatomic,assign)float        canvas_currentFIleAlpha;

@property(nonatomic,assign)float        canvasViewHeight;
@property(nonatomic,assign)int          CurrentCanvasType;

//画布
@property(nonatomic,strong)syncContainerView            *canvas_syncContainer;
@property(nonatomic,strong)UIImageView       *canvas_syncContainer_X_Left;
@property(nonatomic,strong)UIImageView       *canvas_syncContainer_X_Right;

@property(nonatomic,strong)UIImageView       *canvas_syncContainer_Y_Left;
@property(nonatomic,strong)UIImageView       *canvas_syncContainer_Y_Right;

@property(nonatomic,strong)RDPasterTextView *canvas_pasterView;

//状态栏
@property(nonatomic,strong)UIView       *toobarCanvasView;
@property(nonatomic,strong)UILabel      *toobarCanvasLabel;


@property(nonatomic,strong)UIView       *canvasView;
@property(nonatomic,strong)UIScrollView *canvasScrollView;
@property (nonatomic,strong)UIButton    *useToAllCanvas;

//背景 画布颜色  0.269  0.731
@property (nonatomic,strong)UIView      *canvasColorView;
@property(nonatomic,strong)SubtitleColorControl *canvasColorControl;    //画布颜色选择器

//背景 画布样式  0.360
@property (nonatomic,assign)int         canvasStyle_CurrentTag;
@property (nonatomic,strong)UIView      *canvasStyleView;
@property (nonatomic,strong)UIScrollView*canvasStyleScrollView;         //画布样式选择器
@property (nonatomic,strong)RDFile      *canvaStyle_PhotoImage;          //图片

@property (nonatomic,strong)RDFile      *currentCanvasStyleFile;        //当前选择文件

//背景 画布模糊
@property (nonatomic,strong)UIView      *canvasBlurryView;
@property (nonatomic,strong)RDZSlider   *canvasBlurrySlider;            //画布模糊进度
@property (nonatomic,strong)RDFile      *canvasBlurryFile;              //模糊背景媒体
@property (nonatomic,assign)float       canvasBlurryValue;              //模糊程度

//加水印
@property(nonatomic,assign)int          CurrentWatermarkType;
@property(nonatomic,assign)float        watermarkViewHeight;

@property(nonatomic,strong)syncContainerView       *watermark_syncContainer;
@property(nonatomic,strong)RDPasterTextView *watermark_pasterView;
@property(nonatomic,assign)float        maxScale;   //最大倍数

@property (nonatomic,strong)RDWatermark            *currentWatermarkCollage;
@property (nonatomic,strong)RDCaptionRangeViewFile *watermarkCollage;              //加水印 画中画


@property (nonatomic,strong)UIView      *watermarkView;                 //加水印
@property (nonatomic,strong)UIScrollView*watermarkScrollView;           //功能分类

@property (nonatomic,strong)UIView      *toobarWatermarkView;
@property(nonatomic,strong)UILabel      *toobarWatermarkLabel;

//加水印 基础
@property (nonatomic,strong)UIView      *watermarkBasisView;
@property (nonatomic,strong)RDZSlider   *watermarkSizeSlider;
@property (nonatomic,strong)RDZSlider   *watermarkRotateSlider;
@property (nonatomic,strong)RDZSlider   *watermarkAlhpaSlider;
//加水印 位置
@property (nonatomic,strong)UIView      *watermarkPosiView;
@property (nonatomic,strong)NSMutableArray<UIButton *> *watermarkPosiBtnArray;   //位置
@property (nonatomic,strong)NSMutableArray<UIButton *> *watermarkPosiMobileBtnArray; //位置移动



@end

@implementation RDNextEditVideoViewController

-(NSMutableArray *)getFilterFxArray
{
    return filterFxArray;
}

-(NSMutableArray *)getFileList
{
    return _fileList;
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

- (void)viewWillAppear:(BOOL)animated{
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
    
//    if( isEditVideoVC )check
//       [self performSelector:@selector(editVideoVC_Core) withObject:_videoCoreSDK afterDelay:0.1];
//        [_videoCoreSDK prepare];//20171026 wuxiaoxia 优化内存
//    [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
//        _titleView.hidden = NO;
//    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//    [_videoCoreSDK stop];//20171026 wuxiaoxia 优化内存
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(_exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [_videoCoreSDK cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself cancelExportBlock];
                //移除 “取消导出框”
                [myself.commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
                [myself.exportProgressView removeFromSuperview];
                myself.exportProgressView = nil;
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
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

#pragma mark- viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
//    TICK;
//    TOCK;
    if(![[NSFileManager defaultManager] fileExistsAtPath:kThemeMVEffectPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kThemeMVEffectPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:kThemeMVPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kThemeMVPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:kThemeMVIconPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kThemeMVIconPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:kMusicFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kMusicFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
//    TOCK;
    _CurrentWatermarkType = 1;
    isExport = false;
    _currentCanvasStyleFile = nil;
    _canvasBlurryValue = 0.5;
    _canvas_currentFIleAlpha = -1;
    _canvas_CurrentFileIndex = 0;
    _canvasStyle_CurrentTag = 0;
    yuanyinOn = YES;
    isFXUpdateTime = false;
    isFXUpdate = false;
    isPreviewFx = false;
    isEditVideoVC = false;
    isRecording = false;
    isNoBackground = false;
    oldisNoBackground = false;
    isRefreshClipEditing = true;
    isRefreshOrder = true;
    volumeMultipleM = 5.0;
    oldVolume = 1.0;
    _originalVolume = 1.0;
    isNewUI = YES;
    playTimeRange = kCMTimeRangeZero;
    isEnlarge = false;
    oldIsEnlarge = isEnlarge;
    seekTime = kCMTimeZero;
//    TOCK;
    //比例
    EditConfiguration *editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    if( !(editConfiguration.enableMV
        && !editConfiguration.enableDubbing
        && !editConfiguration.enableSoundEffect
        && !editConfiguration.enableSubtitle
        && (!editConfiguration.enableEffect || !editConfiguration.enableSticker)
         && !editConfiguration.enableEffectsVideo
         && !editConfiguration.enableFragmentedit) )
    {
        //比例
        if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect)
            selectProportionIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:kRDProportionIndex] integerValue];
        //图片运动
//        isEnlarge = ![[[NSUserDefaults standardUserDefaults] objectForKey:kRDDisablePicAnimation] boolValue];
//        oldIsEnlarge = isEnlarge;
        //无背景
        isNoBackground = ![[[NSUserDefaults standardUserDefaults] objectForKey:kRDEnableBg] boolValue];
        oldisNoBackground = isNoBackground;
        
        isVague = [[[NSUserDefaults standardUserDefaults] objectForKey:kRDEnableVague] boolValue];
    }
//    TOCK;
    if (selectProportionIndex == 0) {
        selectProportionIndex = 1;
    }
    oldProportionIndex = selectProportionIndex;
    fillColorItems = [[NSMutableArray alloc] init];
    [fillColorItems addObject:UIColorFromRGB(0xffffff)];
    [fillColorItems addObject:UIColorFromRGB(0xf9edb1)];
    [fillColorItems addObject:UIColorFromRGB(0xffa078)];
    [fillColorItems addObject:UIColorFromRGB(0xfe6c6c)];
    [fillColorItems addObject:UIColorFromRGB(0xfe4241)];
    [fillColorItems addObject:UIColorFromRGB(0x7cddfe)];
    [fillColorItems addObject:UIColorFromRGB(0x41c5dc)];
    
    [fillColorItems addObject:UIColorFromRGB(0x0695b5)];
    [fillColorItems addObject:UIColorFromRGB(0x2791db)];
    [fillColorItems addObject:UIColorFromRGB(0x0271fe)];
    [fillColorItems addObject:UIColorFromRGB(0xdcffa3)];
    [fillColorItems addObject:UIColorFromRGB(0x000000)];
    [fillColorItems addObject:UIColorFromRGB(0xc7fe64)];
    [fillColorItems addObject:UIColorFromRGB(0x82e23a)];
    [fillColorItems addObject:UIColorFromRGB(0x25ba66)];
    [fillColorItems addObject:UIColorFromRGB(0x017e54)];
    
    [fillColorItems addObject:UIColorFromRGB(0xfdbacc)];
    [fillColorItems addObject:UIColorFromRGB(0xff5a85)];
    [fillColorItems addObject:UIColorFromRGB(0xff5ab0)];
    [fillColorItems addObject:UIColorFromRGB(0xb92cec)];
    [fillColorItems addObject:UIColorFromRGB(0x7e01ff)];
    [fillColorItems addObject:UIColorFromRGB(0x848484)];
    [fillColorItems addObject:UIColorFromRGB(0x88754d)];
    [fillColorItems addObject:UIColorFromRGB(0x164c6e)];
//    TOCK;
//    TOCK;
    oldIsVague = isVague;
    filterStrength = 1;
    oldFilterStrength = 1.0;
    oldTimeEffectType = kTimeFilterTyp_None;
    [self setValue];
    proportionVideoSize = _exportVideoSize;
//    TOCK;
    [self.view addSubview:self.toolBarView];
    if (!isNewUI ) {
        playerViewHeight = kWIDTH;
        playerViewOriginX = iPhone4s ? 0 : kNavigationBarHeight;
        bottomViewRect = CGRectMake(0, playerViewOriginX + playerViewHeight, kWIDTH, kHEIGHT - playerViewOriginX - playerViewHeight - _toolBarView.bounds.size.height);
        //随机转场
        [self RandomTransition:_fileList];
    }else {
        playerViewHeight = kPlayerViewHeight;
//        float height =  kHEIGHT;
        playerViewOriginX = kPlayerViewOriginX;
//        float width = kWIDTH;
        bottomViewRect = CGRectMake(0, playerViewOriginX + playerViewHeight, kWIDTH, kHEIGHT - playerViewOriginX - playerViewHeight - kToolbarHeight);
    }
//    TOCK;
    [self.view addSubview:self.playerView];
    [self.view addSubview:self.titleView];
    [self.view addSubview:self.playerToolBar];
//    TOCK;
    [self Adjproportion:selectProportionIndex];
//    thumbTimesImageArrayLock = OS_UNFAIR_LOCK_INIT;
//    [self initThumbImageVideoCore];
    
    bool    isThumb = false;
    
    NSArray*paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    __block NSString* path = [paths objectAtIndex:0];
    
    if(_fileList[0].fileType == kFILEVIDEO)
    {
        if( !_fileList[0].filtImagePatch )
        {
            _fileList[0].filtImagePatch = [RDHelpClass getMaterialThumbnail:_fileList[0].contentURL];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [RDHelpClass fileImage_Save:_fileList atProgress:^(float progress) {
                    
                } atReturn:^(bool isSuccess){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self performSelector:@selector( Core_loadTrimmerViewThumbImage ) withObject:nil afterDelay:0.1];
                    });
                }];
            });
        }
        else
        {
            isThumb = true;
        }
    }
    else
    {
        isThumb = true;
    }
    
    [self refreshCaptions];
    [self refreshDewatermark];
    [self check];
//    TOCK;
    if(isNewUI) {
        [self.view insertSubview:self.functionalAreaView belowSubview:_playerView];
    }
    
    NSString * appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [RDHelpClass downloadIconFile:RDAdvanceEditType_Sticker
                           editConfig:editConfiguration
                               appKey:appKey
                            cancelBtn:nil
                        progressBlock:nil
                             callBack:nil
                          cancelBlock:nil];
        
    });
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         [RDHelpClass downloadIconFile:RDAdvanceEditType_Subtitle
                            editConfig:editConfiguration
                                appKey:appKey
                             cancelBtn:nil
                         progressBlock:nil
                              callBack:^(NSError *error)
          {
             [RDHelpClass downloadIconFile:RDAdvanceEditType_None
                                editConfig:editConfiguration
                                    appKey:appKey
                                 cancelBtn:nil
                             progressBlock:nil
                                  callBack:nil
                               cancelBlock:nil];
         }
                           cancelBlock:nil];
     });
    
//    TOCK;
    if( isThumb )
        [self performSelector:@selector( Core_loadTrimmerViewThumbImage ) withObject:nil afterDelay:0.1];
}

- (void)setValue{
    transitionArray = [RDHelpClass getTransitionArray];
    if (CGSizeEqualToSize(_exportVideoSize, CGSizeZero)) {
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
            _exportVideoSize = CGSizeMake(540, 960);//20180720 分辨率与json文件中一致
        }else if (_isMultiMedia || ((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV) {
            _exportVideoSize = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }else {
            _exportVideoSize = [RDHelpClass getEditVideoSizeWithFileList:_fileList];
        }
    }
    int fps = kEXPORTFPS;
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
        fps = 15;//20180720 与json文件中一致
    }
    _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                           APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                          LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                           videoSize:_exportVideoSize
                                                 fps:fps
                                          resultFail:^(NSError *error) {
                                              NSLog(@"initSDKError:%@", error.localizedDescription);
                                          }];
    _videoCoreSDK.delegate = self;
#if ENABLEAUDIOEFFECT
    _videoCoreSDK.enableAudioEffect = YES;
#else
    _videoCoreSDK.enableAudioEffect = (selectedSoundEffectIndex != 0);
#endif
    oldPitch = 1.0;
    yuanyinOn = YES;
    if (_musicVolume == 0.0) {
        _musicVolume = 0.5;
    }
    selectMusicIndex = 1;
    selectFilterIndex = 0;
    customFilterArray = [NSMutableArray array];
    globalFilters = [NSMutableArray array];
    selectedFxTypeIndex = 1;
    NSString *appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if([lexiu currentReachabilityStatus] != RDNotReachable && editConfig.filterResourceURL.length>0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSDictionary * dic = [RDHelpClass classificationParams:@"filter2" atAppkey: appKey atURl:editConfig.netMaterialTypeURL];
            if( !dic )
            {
                NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                            appkey:appKey
                                                                           urlPath:editConfig.filterResourceURL];
                if ([filterList[@"code"] intValue] == 0) {
                    self.filtersName = [filterList[@"data"] mutableCopy];
                    
                    NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                    if(appKey.length > 0)
                        [itemDic setObject:appKey forKey:@"appkey"];
                    [itemDic setObject:@"" forKey:@"cover"];
                    [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                    [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                    [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                    [self.filtersName insertObject:itemDic atIndex:0];
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
                self.filtersName = [NSMutableArray new];
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(appKey.length > 0)
                    [itemDic setObject:appKey forKey:@"appkey"];
                [itemDic setObject:@"" forKey:@"cover"];
                [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                [self.filtersName addObject:itemDic];
                
                for (int i = 0; newFiltersNameSortArray.count > i; i++) {
                    [self.filtersName addObjectsFromArray:newFiltersNameSortArray[i]];
                }
            }
            
            NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:filterPath]){
                [[NSFileManager defaultManager] createDirectoryAtPath:filterPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            [self.filtersName enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
                    [_videoCoreSDK setGlobalFilter:selectFilterIndex];
                    int timeEffectSceneCount = 0;
                    for (int i = 0; i< _fileList.count; i++) {
                        RDFile *file = _fileList[i];
                        if (file.timeEffectSceneCount > 0) {
                            for (int j = timeEffectSceneCount; j < timeEffectSceneCount + file.timeEffectSceneCount; j++) {
                                if (scenes.count < j) {
                                    break;
                                }
                                RDScene *scene = [_videoCoreSDK getScenes][j];
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
                            RDScene *scene = [_videoCoreSDK getScenes][timeEffectSceneCount];
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
                    
                    if( !newFilterSortArray )
                    {
                        if (_filterChildsView && _filterChildsView.subviews.count == 0) {
                            [self initFilterChildsView];
                        }
                    }
                    else{
                        
                    }
                }
            });
        });
    }else{
        NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
        UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
        self.filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        [self.filtersName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
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
        [_videoCoreSDK addGlobalFilters:globalFilters];
    }
    
    filterFxArray = [NSMutableArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
    if ([lexiu currentReachabilityStatus] == RDNotReachable) {
        if (filterFxArray.count == 0) {
            [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
        }
    }else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            filterFxArray = [RDHelpClass getFxArrayWithAppkey:appKey
                                                  typeUrlPath:editConfig.netMaterialTypeURL
                                         specialEffectUrlPath:editConfig.specialEffectResourceURL];
        });
    }
    soundEffectArray = [NSArray arrayWithObjects:@"自定义", @"原音", @"男声", @"女声", @"怪兽", @"卡通", @"回声", @"混响", @"室内", @"舞台", @"KTV", @"厂房", @"竞技场", @"电音", nil];
    if (_draft) {
        enableMV = editConfig.enableMV;
        editConfig.enableDubbing = !_draft.is15S_MV;//配音
        editConfig.enableSoundEffect = !_draft.is15S_MV;//变声
        editConfig.enableSubtitle = !_draft.is15S_MV;//字幕
        editConfig.enableEffect = !_draft.is15S_MV;//贴纸
        editConfig.enableSticker = !_draft.is15S_MV;//贴纸
        editConfig.enableEffectsVideo = !_draft.is15S_MV;//特效
        editConfig.enableFragmentedit = !_draft.is15S_MV;//片段编辑
        editConfig.enableMV = _draft.is15S_MV;//MV

        oldPitch = _draft.pitch;
        selectMusicIndex = _draft.musicIndex;
        selectedSoundEffectIndex = _draft.soundEffectIndex;
        lastThemeMVIndex = _draft.mvIndex;
        selectFilterIndex = _draft.filterIndex;
        yuanyinOn = _draft.originalOn;
        if (_draft.movieEffects.count > 0) {
            RDDraftMusic *music = [_draft.musics firstObject];
            _musicURL = [RDHelpClass getFileURLFromAbsolutePath:music.url.absoluteString];
            _musicTimeRange = music.clipTimeRange;
            _musicVolume = music.volume;
            if (_draft.musics.count > 1) {
                mvMusicArray = [NSMutableArray array];
                [_draft.musics enumerateObjectsUsingBlock:^(RDDraftMusic*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (idx > 0) {
                        [mvMusicArray addObject:[obj getMusic]];
                    }
                }];
            }
            selectMVEffects = [NSMutableArray array];
            [_draft.movieEffects enumerateObjectsUsingBlock:^(RDDraftMovieEffect*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [selectMVEffects addObject:[obj geMovieEffect]];
            }];
        }else if (_draft.musics.count > 0) {
            RDDraftMusic *music = [_draft.musics firstObject];
            _musicURL = [RDHelpClass getFileURLFromAbsolutePath:music.url.absoluteString];
            _musicTimeRange = music.clipTimeRange;
            _musicVolume = music.volume;
        }
        
        //音量
        oldVolume = _draft.volume;
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.videoVolume = oldVolume;
        }];        
        //音效
        soundMusics = [NSMutableArray array];
        [_draft.soundMusics enumerateObjectsUsingBlock:^(RDDraftMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [soundMusics addObject:[obj getMusic]];
        }];
        soundMusicFiles = _draft.soundMusicFiles;
        for (int i = 0; soundMusicFiles.count > i ; i++) {
            soundMusicFiles[i].music = soundMusics[i];
        }
        oldSoundMusicFiles = [soundMusicFiles mutableCopy];
        
        //多段配乐
        musics =  [NSMutableArray array];
        [_draft.multi_trackMusics enumerateObjectsUsingBlock:^(RDDraftMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [musics addObject:[obj getMusic]];
        }];
        musicFiles = _draft.multi_trackMosaicFiles;
        for (int i = 0; musicFiles.count > i ; i++) {
            musicFiles[i].music = musics[i];
        }
        oldMusicFiles = [musicFiles mutableCopy];
        
        subtitles = [NSMutableArray array];
        subtitleFiles = _draft.captions;
        oldSubtitleFiles = [subtitleFiles mutableCopy];
        [subtitleFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.fontPath = [[RDHelpClass getFileURLFromAbsolutePath:obj.fontPath] path];
            if (obj.fontPath.length > 0) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:obj.fontPath]) {
                    [RDHelpClass customFontArrayWithPath:obj.fontPath];
                }else {
                    obj.fontPath = nil;
                    obj.fontName = [UIFont systemFontOfSize:10].fontName;
                    obj.caption.tFontName = obj.fontName;
                }
            }
            [subtitles addObject:obj.caption];
        }];
        stickers = [NSMutableArray array];
        stickerFiles = _draft.stickers;
        oldStickerFiles = [stickerFiles mutableCopy];
        [stickerFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [stickers addObject:obj.caption];
        }];
        blurs = [NSMutableArray array];
        blurFiles = _draft.blurs;
        oldBlurFiles = [blurFiles mutableCopy];
        [blurFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [blurs addObject:obj.blur];
        }];
        mosaics = [NSMutableArray array];
        mosaicFiles = _draft.mosaics;
        oldMosaicFiles = [mosaicFiles mutableCopy];
        [mosaicFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [mosaics addObject:obj.mosaic];
        }];
        dewatermarks = [NSMutableArray array];
        dewatermarkFiles = _draft.dewatermarks;
        oldDewatermarkFiles = [dewatermarkFiles mutableCopy];
        [dewatermarkFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [dewatermarks addObject:obj.dewatermark];
        }];
        collages = [NSMutableArray array];
        collageFiles = _draft.collages;
        oldCollageFiles = [collageFiles mutableCopy];
        [collageFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [collages addObject:obj.collage];
        }];
        
        //加水印
        _watermarkCollage = _draft.watermarkCollage[0];
        _watermarkCollage.collage.vvAsset.alpha = _draft.watermarkAlhpavolume;
        _currentWatermarkCollage = _watermarkCollage.collage;
        
        
        doodles = [NSMutableArray array];
        doodleFiles = _draft.doodles;
        oldDoodleFiles = [doodleFiles mutableCopy];
        [doodleFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [doodles addObject:obj.doodle];
        }];
        dubbingArr = [NSMutableArray array];
        dubbingNewMusicArr = [NSMutableArray array];
        dubbingMusicArr = [NSMutableArray array];
        [_draft.dubbings enumerateObjectsUsingBlock:^(DubbingRangeViewFile*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            DubbingRangeView *view = [[DubbingRangeView alloc] initWithFrame:obj.home];
            view.dubbingStartTime = obj.dubbingStartTime;
            view.dubbingDuration = obj.dubbingDuration;
            view.musicPath = [RDHelpClass getFileURLFromAbsolutePath:obj.musicPath].path;
            view.volume = obj.volume;
            view.dubbingIndex = obj.dubbingIndex;
            [dubbingNewMusicArr addObject:view];
            
            CMTime start = CMTimeMakeWithSeconds(CMTimeGetSeconds(obj.dubbingStartTime) + obj.piantouDuration,TIMESCALE);
            RDMusic *music = [RDMusic new];
            music.url = [NSURL fileURLWithPath:view.musicPath];
            music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, obj.dubbingDuration);
            music.effectiveTimeRange = CMTimeRangeMake(start, obj.dubbingDuration);
            music.volume = obj.volume;
            music.isRepeat = NO;
            [dubbingArr addObject:music];
        }];
        dubbingMusicArr = [dubbingNewMusicArr mutableCopy];
        
        //特效
        //时间特效
        [_draft.timeEffectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDDraftEffectTime* DraftEffectFilterItem = (RDDraftEffectTime*)obj;
            if( kTimeFilterTyp_None != DraftEffectFilterItem.timeType )
            {
                self->_timeEffectType = DraftEffectFilterItem.timeType;//为保存的时间特效
                self->oldTimeEffectType = self->_timeEffectType;//保存的时间特效
                
                self->_effectTimeRange = DraftEffectFilterItem.effectiveTimeRange;
                self->oldEffectTimeRange = self->_effectTimeRange;
            }
        }];
        NSArray *fiterEffectArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        //特效
        fXArray = [[NSMutableArray alloc] init];
        oldFXFiles = _draft.fXFiles;
        fXFiles = [oldFXFiles mutableCopy];
        [fXFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if( obj.customFilter )
           {
               [fXArray addObject:obj.customFilter];
               if( obj.customFilter.customFilter  )
                [customFilterArray addObject:obj.customFilter.customFilter];
           }
        }];
        
        //比例
        selectProportionIndex = _draft.oldProportionIndex;
        oldProportionIndex = _draft.oldProportionIndex;
        
        //背景颜色
        isVague = _draft.isVague;
        oldIsVague = isVague;
        oldisNoBackground = _draft.oldisNoBackground;
        isNoBackground = oldisNoBackground;
        
        
        isNoBackground = true;
        oldisNoBackground = true;
        isEnlarge = _draft.oldIsEnlarge;//图片运动
        oldIsEnlarge = isEnlarge;
        [_contentMagnificationBtn setOn:isEnlarge animated:YES];
        //封面
        coverFile = _draft.coverFile;
        oldCoverFile = coverFile;
    }
    oldMusicIndex = selectMusicIndex;
}

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:nil];
        [self.navigationController.view addSubview:_hud.view];
    }
    return _hud;
}

-(void)showPrompt:(NSString *) string
{
    [self.hud setCaption:string];
    [self.hud show];
    [self.hud hideAfter:2];
}

- (RDAddEffectsByTimeline *)addEffectsByTimeline {
    if (!_addEffectsByTimeline) {
        _addEffectsByTimeline = [[RDAddEffectsByTimeline alloc] initWithFrame:CGRectMake(0, 0, bottomViewRect.size.width, bottomViewRect.size.height)];
        [_addEffectsByTimeline prepareWithEditConfiguration:((RDNavigationViewController *)self.navigationController).editConfiguration
                                                     appKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 exportSize:_exportVideoSize
                                                 playerView:_playerView
                                                        hud:_hud];
        _addEffectsByTimeline.delegate = self;
    }
    return _addEffectsByTimeline;
}

- (UIView *)addedMaterialEffectView {
    if (!_addedMaterialEffectView) {
        _addedMaterialEffectView = [[UIView alloc] initWithFrame:CGRectMake(64, 0, kWIDTH - 64*2, 44)];
        _addedMaterialEffectView.hidden = YES;
        [_toolbarTitleView addSubview:_addedMaterialEffectView];
        
        UILabel *addedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
        addedLbl.text = RDLocalizedString(@"已添加", nil);
        addedLbl.textColor = UIColorFromRGB(0x888888);
        addedLbl.font = [UIFont systemFontOfSize:14.0];
        [_addedMaterialEffectView addSubview:addedLbl];
        
        addedMaterialEffectScrollView =  [UIScrollView new];
        addedMaterialEffectScrollView.tag = 10000;
        addedMaterialEffectScrollView.frame = CGRectMake(64, 0, _addedMaterialEffectView.bounds.size.width - 64, 44);
        addedMaterialEffectScrollView.showsVerticalScrollIndicator = NO;
        addedMaterialEffectScrollView.showsHorizontalScrollIndicator = NO;
        [_addedMaterialEffectView addSubview:addedMaterialEffectScrollView];
        
        selectedMaterialEffectItemIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, addedMaterialEffectScrollView.bounds.size.height - 27, 27, 27)];
        selectedMaterialEffectItemIV.tag = 10001;
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

#pragma mark - 特效
- (UIView *)FXView {
    if (((RDNavigationViewController *)self.navigationController).editConfiguration.specialEffectResourceURL.length == 0
        || !(((RDNavigationViewController *)self.navigationController).editConfiguration.enableEffectsVideo)) {
        return nil;
    }
    if(!FXView) {
        float height = kHEIGHT - playerViewOriginX - playerViewHeight - kToolbarHeight;
        FXView = [[UIView alloc] initWithFrame:CGRectMake(0, playerViewOriginX + playerViewHeight, kWIDTH, height)];
        FXView.backgroundColor = TOOLBAR_COLOR;
        FXView.hidden = YES;
        [self.view addSubview:FXView];
    }
    return FXView;
}
#pragma mark- 音量
-( UIView *)volumeView
{
    if(!_volumeView )
    {
        _volumeView = [UIView new];
        _volumeView.frame = bottomViewRect;
        _volumeView.backgroundColor = TOOLBAR_COLOR;
        
        UILabel * VolumeLabel = [UILabel new];
        VolumeLabel.frame = CGRectMake(( 120 - 50  )/2.0, _volumeView.frame.size.height/2.0, 50, 31);
        VolumeLabel.textAlignment = NSTextAlignmentCenter;
        VolumeLabel.backgroundColor = [UIColor clearColor];
        VolumeLabel.font = [UIFont systemFontOfSize:14];
        VolumeLabel.textColor = [UIColor whiteColor];
        VolumeLabel.text = RDLocalizedString(@"原音", nil);
        
        [_volumeView addSubview:VolumeLabel];
        [_volumeView addSubview:self.originalVolumeSlider];
        
        _volumeView.hidden = YES;
        [self.view addSubview:_volumeView];
    }
    return _volumeView;
}

//原音音量比例调节
- (RDZSlider *)originalVolumeSlider{
    if(!_originalVolumeSlider){
        _originalVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50 + ( 120 - 50  )/2.0, _volumeView.frame.size.height/2.0, kWIDTH - 120, 31)];
        _originalVolumeSlider.alpha = 1.0;
        _originalVolumeSlider.backgroundColor = [UIColor clearColor];
        [_originalVolumeSlider setMaximumValue:1];
        [_originalVolumeSlider setMinimumValue:0];
        [_originalVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_originalVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_originalVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_originalVolumeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_originalVolumeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_originalVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        
        [_originalVolumeSlider setValue:(oldVolume/volumeMultipleM)];
        [_originalVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_originalVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_originalVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_originalVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        _originalVolumeSlider.enabled = YES;
    }
    return _originalVolumeSlider;
}
#pragma mark- 音效
- (UIView *)soundView{
    if(!_soundView){
        _soundView = [UIView new];
        _soundView.frame = bottomViewRect;
        _soundView.backgroundColor = TOOLBAR_COLOR;
        _soundView.hidden = YES;
        [self.view addSubview:_soundView];
    }
    return _soundView;
}
-(UIView *)addedMusicVolumeView
{
    if( !_addedMusicVolumeView )
    {
        _addedMusicVolumeView = [[UIView alloc] initWithFrame:CGRectMake(_playerView.frame.size.width/3.0/2.0, _playerView.frame.origin.x + (_playerView.frame.size.height - 50), _playerView.frame.size.width*2.0/3.0 , 40)];
        
        _addedMusicVolumeView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.4];
        _addedMusicVolumeView.layer.cornerRadius = _addedMusicVolumeView.frame.size.height/2.0;
        _addedMusicVolumeView.layer.masksToBounds = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, (40 - 25)/2.0, 50, 25)];
        label.text = RDLocalizedString(@"配乐", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        
        [_addedMusicVolumeView addSubview:label];
        [_addedMusicVolumeView addSubview:self.addedMusicVolumeSlider];
        
        [self.view addSubview:_addedMusicVolumeView];
    }
    return _addedMusicVolumeView;
}
-(RDZSlider *)addedMusicVolumeSlider
{
    if(!_addedMusicVolumeSlider){
        _addedMusicVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, (_addedMusicVolumeView.frame.size.height - 31)/2.0, _addedMusicVolumeView.frame.size.width - 50 - 10, 31)];
//        _addedMusicVolumeSlider.transform = CGAffineTransformIdentity;
//        _addedMusicVolumeSlider.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
        
//        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
//        image = [image imageWithTintColor];
//        [_addedMusicVolumeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
//        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
//        [_addedMusicVolumeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_addedMusicVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
//        CGRect rect = _addedMusicVolumeSlider.frame;
//        rect.origin.x = -1;
//        rect.origin.y = 20;
//        [_addedMusicVolumeSlider setFrame:rect];
        _addedMusicVolumeSlider.alpha = 1.0;
        _addedMusicVolumeSlider.backgroundColor = [UIColor clearColor];
        [_addedMusicVolumeSlider setMaximumValue:1];
        [_addedMusicVolumeSlider setMinimumValue:0];
        [_addedMusicVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_addedMusicVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
//        [_addedMusicVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        [_addedMusicVolumeSlider setValue:(0.5/volumeMultipleM)];
        [_addedMusicVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_addedMusicVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_addedMusicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_addedMusicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        _addedMusicVolumeSlider.enabled = YES;
        [self replaceSlider:_addedMusicVolumeSlider.enabled atRDZSlider:_addedMusicVolumeSlider];
//        _addedMusicVolumeSlider.enabled = (selectMusicIndex == 1 ? NO : yuanyinOn);
    }
    return _addedMusicVolumeSlider;
}

#pragma mark- 多段配乐
- (UIView *)multi_trackView{
    if(!_multi_trackView){
        _multi_trackView = [UIView new];
        _multi_trackView.frame = bottomViewRect;
        _multi_trackView.backgroundColor = BOTTOM_COLOR;
        _multi_trackView.hidden = YES;
        [self.view addSubview:_multi_trackView];
    }
    return _multi_trackView;
}
#pragma mark- 字幕
- (UIView *)subtitleView{
    if(!_subtitleView){
        _subtitleView = [UIView new];
        _subtitleView.frame = bottomViewRect;
        _subtitleView.backgroundColor = BOTTOM_COLOR;
        _subtitleView.hidden = YES;
        [self.view addSubview:_subtitleView];
    }
    return _subtitleView;
}

#pragma mark - 贴纸
- (UIView *)stickerView{
    if(!_stickerView){
        _stickerView = [UIView new];
        _stickerView.frame = bottomViewRect;
        _stickerView.backgroundColor = BOTTOM_COLOR;
        _stickerView.hidden = YES;
        [self.view addSubview:_stickerView];
    }
    return _stickerView;
}

#pragma mark - MV
- (UIView *)mvView{    
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
        return nil;
    }    
    if(!_mvView){
        _mvView = [UIView new];
        _mvView.frame = bottomViewRect;
        _mvView.backgroundColor = BOTTOM_COLOR;
        _mvView.hidden = YES;
        [self.view addSubview:_mvView];
        [_mvView addSubview:self.mvChildsView];
    }
    return _mvView;
}

- (UIScrollView *)mvChildsView{
    if(!_mvChildsView){    
        _mvChildsView = [UIScrollView new];
        _mvChildsView.frame = CGRectMake(0,  (kWIDTH>320 ? 54 : 44) + (_mvView.frame.size.height - (kWIDTH>320 ? 54 : 44) - (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)))/2.0, _mvView.frame.size.width, (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)));
        _mvChildsView.backgroundColor = [UIColor clearColor];
        _mvChildsView.showsHorizontalScrollIndicator = NO;
        _mvChildsView.showsVerticalScrollIndicator = NO;
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kThemeMVPath]){
            [fileManager createDirectoryAtPath:kThemeMVPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if(![fileManager fileExistsAtPath:kThemeMVIconPath]){
            [fileManager createDirectoryAtPath:kThemeMVIconPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if(![fileManager fileExistsAtPath:kThemeMVEffectPath]){
            [fileManager createDirectoryAtPath:kThemeMVEffectPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
        NSString *mvListPath = [kThemeMVPath stringByAppendingPathComponent:@"mvlist.plist"];
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
            NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle"];
            NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
            mvListPath = [bundle pathForResource:@"MVEffect/mvlist.plist" ofType:@""];            
        }
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.mvResourceURL.length>0 || ((RDNavigationViewController *)self.navigationController).editConfiguration.newmvResourceURL.length>0){
            mvList = [[NSArray arrayWithContentsOfFile:mvListPath] mutableCopy];
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
                [mvList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *file =[obj[@"file"] stringByDeletingPathExtension];
                    NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[kThemeMVEffectPath stringByAppendingPathComponent:file] error:nil] count];
                    if(fileCount == 0){
                        NSString *fileCachePath = [kThemeMVEffectPath stringByAppendingPathComponent:file];
                        NSString *cacheFolderPath = [[mvListPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:obj[@"file"]];
                        [RDHelpClass OpenZipp:cacheFolderPath unzipto:fileCachePath];
                    }
                }];
            }
        }else{
            mvList = nil;
        }
        
        CGRect themeMVEffectScrollViewRect = CGRectMake(0,(_mvView.frame.size.height - (kWIDTH > 320 ? 90 :80) - 30)/2.0+30, _mvView.frame.size.width, (kWIDTH > 320 ? 90 :80));
        if(iPhone4s){
            themeMVEffectScrollViewRect = CGRectMake(0,(_mvView.frame.size.height - 60 - 30)/2.0+30, _mvView.frame.size.width, 60);
        }
        _mvChildsView = [[UIScrollView alloc] initWithFrame:themeMVEffectScrollViewRect];
        _mvChildsView.showsHorizontalScrollIndicator = NO;
        _mvChildsView.showsVerticalScrollIndicator = NO;
        _mvChildsView.backgroundColor = self.view.backgroundColor;
        
        ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(0+5, 0, _mvChildsView.frame.size.height - 20, _mvChildsView.frame.size.height)];
        item.backgroundColor = [UIColor clearColor];
        item.fontSize = 12;
        item.type = 3;
        item.delegate = self;
        item.selectedColor = Main_Color;
        item.normalColor   = UIColorFromRGB(0x888888);
        item.cornerRadius = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor = [UIColor clearColor];
        item.tag = 1;
        [item setSelected:(0 == lastThemeMVIndex ? YES : NO)];
        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/拍摄_滤镜无默认_"];
        item.itemTitleLabel.text  = RDLocalizedString(@"无", nil);        
        [_mvChildsView addSubview:item];
        
        mvList = [[NSArray arrayWithContentsOfFile:mvListPath] mutableCopy];
        BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.newmvResourceURL.length>0;        
        if(mvList){            
            [self initchildMVItem];
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
                _mvChildsView.hidden = NO;
                return _mvChildsView;                
            }
            if([lexiu currentReachabilityStatus] != RDNotReachable){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios",@"type", nil];
                    NSString *mvurl = (hasNew ? ((RDNavigationViewController *)self.navigationController).editConfiguration.newmvResourceURL : ((RDNavigationViewController *)self.navigationController).editConfiguration.mvResourceURL);
                    
                    NSDictionary *dic;
                    if(hasNew){
                        dic = [RDHelpClass getNetworkMaterialWithType:@"mv"
                                                               appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                              urlPath:mvurl];
                    }else{
                        dic = [RDHelpClass updateInfomationWithJson:params andUploadUrl:mvurl];
                    }
                    BOOL suc = (hasNew ? [dic[@"code"] integerValue] == 0 : [[dic objectForKey:@"state"] boolValue]);
                    if(suc){
                        mvList = hasNew ? dic[@"data"] : [[dic objectForKey:@"result"] objectForKey:@"mvlist"];
                        
                        suc = [mvList writeToFile:mvListPath atomically:YES];
                        if (!suc) {
                            //NSLog(@"写入失败");
                        }
                    }
                    if(!hasNew){
                        for (NSDictionary *item in mvList) {
                            @autoreleasepool {
                                NSString *iconUrl = hasNew ? item[@"cover"] : item[@"img"];
                                NSString *iconcachePath = [kThemeMVIconPath stringByAppendingString:[NSString stringWithFormat:@"%@.png", (hasNew ? [[item[@"file"] lastPathComponent] stringByDeletingPathExtension] : item[@"enname"])]];
                                if(![fileManager fileExistsAtPath:iconcachePath]){
                                    NSString *urlString = iconUrl;
                                    NSData *data = [NSData dataWithContentsOfURL:[NSURL  URLWithString:urlString]];
                                    UIImage *image = [UIImage imageWithData:data]; // 取得图片
                                    // 将取得的图片写入本地的沙盒中，其中0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
                                    BOOL suc = [UIImageJPEGRepresentation(image, 1) writeToFile:iconcachePath  atomically:YES];
                                    if (!suc) {
                                        //NSLog(@"写入失败");
                                    }
                                }
                            }
                        }
                    }
                });
            }
        }
        else{
            if([lexiu currentReachabilityStatus] != RDNotReachable){                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios",@"type", nil];
                    NSString *mvurl = (hasNew ? ((RDNavigationViewController *)self.navigationController).editConfiguration.newmvResourceURL : ((RDNavigationViewController *)self.navigationController).editConfiguration.mvResourceURL);

                    NSDictionary *dic;
                    if(hasNew){
                        dic = [RDHelpClass getNetworkMaterialWithType:@"mv"
                                                               appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                              urlPath:mvurl];
                    }else{
                        dic = [RDHelpClass updateInfomationWithJson:params andUploadUrl:mvurl];
                    }
                    BOOL suc = (hasNew ? [dic[@"code"] integerValue] == 0 : [[dic objectForKey:@"state"] boolValue]);
                    if(suc){
                        mvList = hasNew ? dic[@"data"] : [[dic objectForKey:@"result"] objectForKey:@"mvlist"];
                        
                        BOOL suc = [mvList writeToFile:mvListPath atomically:YES];
                        if (!suc) {
                            NSLog(@"写入失败");
                        }
                        for (NSDictionary *item in mvList) {
                            @autoreleasepool {
                                NSString *iconUrl = hasNew ? item[@"cover"] : item[@"img"];
                                NSString *iconcachePath = [kThemeMVIconPath stringByAppendingString:[NSString stringWithFormat:@"%@.png",(hasNew ? [[item[@"file"] lastPathComponent] stringByDeletingPathExtension] : item[@"enname"])]];
                                if(![fileManager fileExistsAtPath:iconcachePath]){
                                    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                NSString *urlString = iconUrl;
                                NSData *data = [NSData dataWithContentsOfURL:[NSURL  URLWithString:urlString]];
                                UIImage *image = [UIImage imageWithData:data]; // 取得图片
                                // 将取得的图片写入本地的沙盒中，其中0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
                                    BOOL suc = [UIImageJPEGRepresentation(image, 1) writeToFile:iconcachePath  atomically:YES];
                                    if (!suc) {
                                        //NSLog(@"写入失败");
                                    }
                                }
                            }
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self initchildMVItem];
                        });
                    }
                });
            }else{
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
                [self initchildMVItem];
            }
        }
        _mvChildsView.hidden = NO;        
    }    
    return _mvChildsView;
}

- (void)initchildMVItem{
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.newmvResourceURL.length>0;
    
    for (int i = 1; i<self->mvList.count+1; i++) {
        ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(i*(self.mvChildsView.frame.size.height - 10)+5, 0, self.mvChildsView.frame.size.height - 20, self.mvChildsView.frame.size.height)];
        item.backgroundColor = [UIColor clearColor];
        item.fontSize = 12;
        item.type = 3;
        item.delegate = self;
        item.selectedColor = Main_Color;
        item.normalColor   = UIColorFromRGB(0x888888);
        item.cornerRadius = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor = [UIColor clearColor];
        if(!hasNew){
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
                NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle"];
                NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
                NSString * iconPath = [bundle pathForResource:[NSString stringWithFormat:@"MVEffect/%@",[self->mvList[i-1][@"cover"] lastPathComponent]] ofType:@""];
                [item.itemIconView setImage:[UIImage imageWithContentsOfFile:iconPath]];
            }else{
                NSString *itemIconPath = [kThemeMVIconPath stringByAppendingString:[NSString stringWithFormat:@"/%@.png",[self->mvList[i-1] objectForKey:@"enname"]]];
                if([[NSFileManager defaultManager]fileExistsAtPath:itemIconPath]){
                    item.itemIconView.image = [UIImage imageWithContentsOfFile:itemIconPath];
                }else{
                    [item.itemIconView rd_sd_setImageWithURL:[self->mvList[i-1] objectForKey:@"img"]];
                }
            }
        }else{
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
                NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle"];
                NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
                NSString * iconPath = [bundle pathForResource:[NSString stringWithFormat:@"MVEffect/%@",[self->mvList[i-1][@"cover"] lastPathComponent]] ofType:@""];
                [item.itemIconView setImage:[UIImage imageWithContentsOfFile:iconPath]];
            }else{
                [item.itemIconView rd_sd_setImageWithURL:[self->mvList[i-1] objectForKey:@"cover"]];
            }
        }
        
        NSString *title = [self->mvList[i-1] objectForKey:@"name"];
        item.itemTitleLabel.text  = title;
        item.tag = i+1;
        [self.mvChildsView addSubview:item];
        [item setSelected:(i == self->lastThemeMVIndex ? YES : NO)];
    }
    self.mvChildsView.contentSize = CGSizeMake((self->mvList.count + 1) * (self.mvChildsView.frame.size.height - 10),self.mvChildsView.frame.size.height);
}

-(ScrollViewChildItem *)getVOlumeItem:(int) idx atImage:(UIImage * ) image atSelectedImage:(UIImage *) selectedImage atWidth:(float) width
 {
    ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(20 + width, _musicView.frame.size.height*(0.392 - 0.127)/2.0, _musicView.frame.size.height*0.127, _musicView.frame.size.height*0.127)];
    item.backgroundColor = [UIColor clearColor];
    item.isMuisc = TRUE;
    item.isSwitchMuisc = true;
    item.fontSize = 12;
    item.type = 1;
    item.delegate = self;
    item.selectedColor = Main_Color;
    item.normalColor   = UIColorFromRGB(0x888888);
    item.itemIconView.layer.cornerRadius = 5.0;
    //            item.cornerRadius = item.frame.size.width/2.0;
    item.exclusiveTouch = YES;
    item.itemIconView.backgroundColor = [UIColor clearColor];
    [_musicChildsView addSubview:item];
    item.tag = idx + 1;
    
    item.itemTitleLabel.hidden = YES;
    item.itemIconView.frame = CGRectMake(0, 0, item.frame.size.width, item.frame.size.height);
    item.itemIconselectedView = [[UIImageView alloc] initWithFrame:item.itemIconView.frame];
    [item addSubview:item.itemIconselectedView];
    item.itemIconselectedView.layer.cornerRadius = 5.0;
    item.itemIconselectedView.hidden = YES;
    item.itemIconView.image = image;
    item.itemIconselectedView.image = selectedImage;
     
     [item setSelected:(idx == (selectMusicIndex) ? YES : NO)];
    return item;
}

#pragma mark - 原音开关
-(void)videoVolume_Btn
{
    yuanyinOn = !yuanyinOn;
    if(yuanyinOn){
        _videoVolumeSlider.enabled = YES;
        _videoVolumeSlider.value = (_originalVolume/volumeMultipleM);
        [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"] forState:UIControlStateNormal];
    }else{
        _videoVolumeSlider.enabled = NO;
        [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音禁用_"] forState:UIControlStateNormal];
    }
    [self replaceSlider:_videoVolumeSlider.enabled atRDZSlider:_videoVolumeSlider];
    __weak typeof(self) weakSelf = self;
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
        StrongSelf(self);
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0) {
                [strongSelf.videoCoreSDK setVolume:(yuanyinOn ? (strongSelf->oldVolume) : 0.0) identifier:obj.identifier];
            }
        }];
    }];
}
#pragma mark - 配乐开关
-(void)musicVolume_Btn
{
    if( _musicVolumeBtn.isSelected ){
        _musicVolumeBtn.selected = NO;
        _musicVolumeSlider.enabled = NO;
        [_videoCoreSDK setVolume:0.0 identifier:@"music"];
        [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音禁用_"] forState:UIControlStateNormal];
    }
    else{
        _musicVolumeBtn.selected = YES;
        _musicVolumeSlider.enabled = YES;
        [_videoCoreSDK setVolume:_musicVolume identifier:@"music"];
        [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音开_"] forState:UIControlStateSelected];
    }
    [self replaceSlider:_musicVolumeSlider.enabled atRDZSlider:_musicVolumeSlider];
}

-(void)replaceSlider:(BOOL) isEnabled atRDZSlider:( RDZSlider * ) slider
{
    UIImage * image = nil;
    UIImage * image1 = nil;
    if( isEnabled )
    {
        image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐-播放进度轨道1"];
        image = [image imageWithTintColor];
        image1 = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐-播放进度轨道2"];
    }
    else{
        image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐-播放进度轨道1_1"];
        image = [image imageWithTintColor];
        image1 = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐-播放进度轨道2_1"];
    }
    [slider setMinimumTrackImage:image forState:UIControlStateNormal];
    [slider setMaximumTrackImage:image1 forState:UIControlStateNormal];
}

#pragma mark - 配乐
- (UIView *)musicView{    
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableMusic){
        return nil;
    }
    if(!_musicView){
        _musicView = [UIView new];
        _musicView.frame = bottomViewRect;
        _musicView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_musicView];
        
        _musicVolumeBtn = [[UIButton alloc] initWithFrame:CGRectMake(20+kWIDTH/2.0,_musicView.frame.size.height*(0.392 - 0.127)/2.0, _musicView.frame.size.height*0.127, _musicView.frame.size.height*0.127)];
        if( selectMusicIndex > 1 )
            [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音开_"] forState:UIControlStateSelected];
        else
            [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音禁用_"] forState:UIControlStateNormal];
        [_musicVolumeBtn addTarget:self action:@selector(musicVolume_Btn) forControlEvents:UIControlEventTouchUpInside];
//        [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音禁用_"] forState:UIControlStateDisabled];
        
        
        _videoVolumeBtn = [[UIButton alloc] initWithFrame:CGRectMake(20,_musicView.frame.size.height*(0.392 - 0.127)/2.0, _musicView.frame.size.height*0.127, _musicView.frame.size.height*0.127)];
        if( yuanyinOn )
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"] forState:UIControlStateNormal];
        else
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音禁用_"] forState:UIControlStateNormal];
        [_videoVolumeBtn addTarget:self action:@selector(videoVolume_Btn) forControlEvents:UIControlEventTouchUpInside];
        
//        [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音禁用_"] forState:UIControlStateDisabled];
        
        [_musicView addSubview:_videoVolumeBtn];
        [_musicView addSubview:_musicVolumeBtn];
        [_musicView addSubview:self.videoVolumeSlider];
        [_musicView addSubview:self.musicVolumeSlider];
        [_musicView addSubview: self.musicChildsView];
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDubbing && ((RDNavigationViewController *)self.navigationController).editConfiguration.dubbingType == 1){
            _dubbingItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            _dubbingItemBtn.frame = CGRectMake(5 , (kWIDTH>320 ? 10 : 5), 55, 30);
            [_dubbingItemBtn addTarget:self action:@selector(clickDubbingItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            _dubbingItemBtn.layer.cornerRadius = 15.0;
            _dubbingItemBtn.layer.masksToBounds = YES;
            _dubbingItemBtn.titleLabel.font = [UIFont systemFontOfSize:17];
            _dubbingItemBtn.backgroundColor = Main_Color;
            [_dubbingItemBtn setTitle:RDLocalizedString(@"配音", nil) forState:UIControlStateNormal];
            [_dubbingItemBtn setTitle:RDLocalizedString(@"配音", nil) forState:UIControlStateHighlighted];
            [_dubbingItemBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
            [_dubbingItemBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateHighlighted];
            
            _musicVolumeLabel.frame = CGRectMake(60, (kWIDTH>320 ? 10 : 5), 50, 31);
            self.musicVolumeSlider.frame = CGRectMake(50 + 60, (kWIDTH>320 ? 10 : 5), kWIDTH - 100 - 60, 31);

            [_musicView addSubview:_dubbingItemBtn];
        }
        _musicView.hidden = YES;
    }
    return _musicView;
}

-(RDZSlider*)videoVolumeSlider
{
    if( !_videoVolumeSlider )
    {
        _videoVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(10 + 50, (_musicView.frame.size.height*0.392 - 31.0)/2.0, kWIDTH/2.0 - (10 + 50 + 10), 31)];
        _videoVolumeSlider.alpha = 1.0;
        _videoVolumeSlider.backgroundColor = [UIColor clearColor];
        [_videoVolumeSlider setMaximumValue:1];
        [_videoVolumeSlider setMinimumValue:0];
        [_videoVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_videoVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
//        [_videoVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:6] forState:UIControlStateNormal];
        
//        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
//        image = [image imageWithTintColor];
//        [_videoVolumeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
//        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
//        [_videoVolumeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_videoVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        [_videoVolumeSlider setValue:(_originalVolume/volumeMultipleM)];
        [_videoVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        _videoVolumeSlider.enabled = yuanyinOn;
        [self replaceSlider:_videoVolumeSlider.enabled atRDZSlider:_videoVolumeSlider];
//        [_videoVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_球_"]  forState:UIControlStateNormal];
    }
    return _videoVolumeSlider;
}

//配乐音量比例调节
- (RDZSlider *)musicVolumeSlider{
    if(!_musicVolumeSlider){
        _musicVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(kWIDTH/2.0 + 50 + 10, (_musicView.frame.size.height*0.392 - 31.0)/2.0, kWIDTH/2.0 - (10 + 50 + 10), 31)];
        _musicVolumeSlider.alpha = 1.0;
        _musicVolumeSlider.backgroundColor = [UIColor clearColor];
        [_musicVolumeSlider setMaximumValue:1];
        [_musicVolumeSlider setMinimumValue:0];
        [_musicVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_musicVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
//        [_musicVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:6] forState:UIControlStateNormal];
        
//        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
//        image = [image imageWithTintColor];
//        [_musicVolumeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
//        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
//        [_musicVolumeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_musicVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        [_musicVolumeSlider setValue:(_musicVolume/volumeMultipleM)];
        [_musicVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_musicVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_musicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_musicVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        
        _musicVolumeSlider.enabled = ( selectMusicIndex > 1 )? YES : NO ;
        [self replaceSlider:_musicVolumeSlider.enabled atRDZSlider:_musicVolumeSlider];
//        [_musicVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_球_"]  forState:UIControlStateNormal];
    }
    return _musicVolumeSlider;
}

//音乐
- (UIScrollView *)musicChildsView{    
    if(!_musicChildsView){
        _musicChildsView = [UIScrollView new];
        _musicChildsView.frame = CGRectMake(0,  (kWIDTH>320 ? 54 : 44) + (_musicView.frame.size.height - (kWIDTH>320 ? 54 : 44) - (iPhone4s ? 60 : (kWIDTH>320 ? 80 :  (LastIphone5?70:65))))/2.0, _musicView.frame.size.width, (iPhone4s ? 60 : (kWIDTH>320 ? 80 : (LastIphone5?70:65))));
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
        for(NSInteger idx = 2;idx<count;idx ++){
            ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake((idx - 2)*(_musicChildsView.frame.size.height - 15)+10, 0, (_musicChildsView.frame.size.height - 25), _musicChildsView.frame.size.height)];
            item.backgroundColor = [UIColor clearColor];
            item.isMuisc = TRUE;
            item.fontSize = 12;
            item.type = 1;
            item.delegate = self;
            item.selectedColor = Main_Color;
            item.normalColor   = UIColorFromRGB(0x888888);
            item.itemIconView.layer.cornerRadius = 5.0;
//            item.cornerRadius = item.frame.size.width/2.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor = [UIColor clearColor];
            [_musicChildsView addSubview:item];
            item.tag = idx + 1;
            [item setSelected:(idx == (selectMusicIndex) ? YES : NO)];
            item.itemTitleLabel.textColor = UIColorFromRGB(0x666666);
            item.itemIconselectedView = [[UIImageView alloc] initWithFrame:item.itemIconView.frame];
            [item addSubview:item.itemIconselectedView];
            item.itemIconselectedView.layer.cornerRadius = 5.0;
            item.itemIconselectedView.hidden = YES;
            
            
            oldMusicIndex = selectMusicIndex;
            switch (idx) {
                case 0:
                {
                    if(!yuanyinOn){
                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音关_"];
                        item.itemTitleLabel.text  = RDLocalizedString(@"原音关", nil);
                    }else{
                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"];
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
                    item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_本地默认_"];
                    item.itemIconselectedView.image  = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_本地选中_"];
                    if (_draft && selectMusicIndex == item.tag - 1) {
                        RDDraftMusic *music = [_draft.musics firstObject];
                        item.itemTitleLabel.text  = music.name;
                        [item startScrollTitle];
                    }else {
                        item.itemTitleLabel.text  = RDLocalizedString(@"本地", nil);
                    }
                }
                    break;
                case 3:
                {
                    item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_云音乐默认_"];
                    item.itemIconselectedView.image  = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_云音乐选中_"];
                    if (_draft && selectMusicIndex == item.tag - 1) {
                        RDDraftMusic *music = [_draft.musics firstObject];
                        item.itemTitleLabel.text  = music.name;
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
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
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
    
    UIImage *defaultImage = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_默认_"];
    
    UIImage *defaultSelectedImage = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_选中_"];
    
    for(NSInteger idx = index;idx<musicList.count + index;idx ++){
        
        NSDictionary *itemDic = musicList[idx - index];
        NSString *title = itemDic[@"name"];
        NSString *iconUrl = hasNewMusic ? itemDic[@"cover"] : itemDic[@"icon"];
        NSString *musicPath = [kMusicPath stringByAppendingString:[(hasNewMusic ? itemDic[@"file"] : itemDic[@"url"]) lastPathComponent]];
        NSString *imageName = [[iconUrl lastPathComponent] stringByDeletingPathExtension];
        
//        NSString *itemIconPath = [kMusicIconPath stringByAppendingString:[NSString stringWithFormat:@"%@.png",imageName]];
//        UIImage *image = [UIImage imageWithContentsOfFile:itemIconPath];
        
        UIImage *image = nil;
        if (!image) {
            image = defaultImage;
        }        
        if(image){
            ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake((idx-2)*(_musicChildsView.frame.size.height - 15)+10, 0, (_musicChildsView.frame.size.height - 25), _musicChildsView.frame.size.height)];
            item.backgroundColor = [UIColor clearColor];
            item.isMuisc = TRUE;
            item.fontSize = 12;
            item.type = 1;
            item.delegate = self;
            item.selectedColor = Main_Color;
            item.normalColor   = UIColorFromRGB(0x888888);
            item.itemIconView.layer.cornerRadius = 2.0;
//            item.cornerRadius = item.frame.size.width/2.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
            [_musicChildsView addSubview:item];
            item.tag = idx + 1;
            [item setSelected:(idx == (selectMusicIndex) ? YES : NO)];
            
            item.itemIconselectedView = [[UIImageView alloc] initWithFrame:item.itemIconView.frame];
            [item addSubview:item.itemIconselectedView];
            item.itemIconselectedView.hidden = YES;
            item.itemIconselectedView.layer.cornerRadius = 5.0;
            item.itemTitleLabel.textColor = UIColorFromRGB(0x666666);
            item.itemIconView.image = defaultImage;
            item.itemIconselectedView.image = defaultSelectedImage;
//            if(hasNewMusic){
//                [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:iconUrl] placeholderImage:defaultImage];
//            }else{
//                //item.itemIconView.image = image;
//                [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:iconUrl]];
//
//            }
            
            float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString(title, nil) andHeight:12 fontSize:12];
            
            
            
            item.itemTitleLabel.text  = title;
            item.normalColor   = UIColorFromRGB(0x888888);
            
            if([[NSFileManager defaultManager] fileExistsAtPath:musicPath]){
                item.normalColor   = UIColorFromRGB(0xe2e2e2);
            }else{
                item.normalColor   = UIColorFromRGB(0x888888);
            }
            
            if( ItemBtnWidth >  item.frame.size.width )
                [item startScrollTitle];
            
            count ++;
        }        
    }
    _musicChildsView.contentSize = CGSizeMake((count + 2) * (_musicChildsView.frame.size.height - 15)+20, _musicChildsView.frame.size.height);
}



- (void)initFilterChildsView {
    [globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(self.filterChildsView.frame.size.height - 15)+10, 0, (self.filterChildsView.frame.size.height - 25), self.filterChildsView.frame.size.height)];
        item.backgroundColor        = [UIColor clearColor];
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
            if(idx == 0){
                NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
            }else{
                [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
            }
        }else{
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
            item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
        }
        item.fontSize       = 12;
        item.type           = 2;
        item.delegate       = self;
        item.selectedColor  = Main_Color;
        item.normalColor    = UIColorFromRGB(0x888888);
        item.cornerRadius   = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor   = [UIColor clearColor];
        item.itemTitleLabel.text            = RDLocalizedString(obj.name, nil);
        item.tag                            = idx + 1;
        item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
        [item setSelected:(idx == self->selectFilterIndex ? YES : NO)];
        
//        item.itemIconView.layer.cornerRadius = 5;
//        item.itemIconView.layer.masksToBounds = YES;
//        item.itemIconView.userInteractionEnabled = YES;
        [self.filterChildsView addSubview:item];
    }];
    _filterChildsView.contentSize = CGSizeMake(globalFilters.count * (_filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    
    if( 0 == self->selectFilterIndex )
    {
        _filterProgressSlider.enabled = NO;
    }
    
    UIImageView *image;
    image.contentMode = UIViewContentModeScaleAspectFit;
}

#pragma mark- 滤镜
- (UIView *)filterView{
    if(!_filterView){
        if( !newFilterSortArray )
        {
            _filterView = [[UIView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y + (iPhone_X?35:0), bottomViewRect.size.width, bottomViewRect.size.height - (iPhone_X?35:0))];
            _filterView.backgroundColor = TOOLBAR_COLOR;
            [self.view addSubview:_filterView];
            _filterChildsView           = [UIScrollView new];
            
            float height = (_filterView.frame.size.height - 40) > 100 ? 100 : 90 ;
            _filterChildsView.frame     = CGRectMake(0,40 + ( (_filterView.frame.size.height - 40) - height )/2.0, _filterView.frame.size.width, height);
            _filterChildsView.backgroundColor                   = [UIColor clearColor];
            _filterChildsView.showsHorizontalScrollIndicator    = NO;
            _filterChildsView.showsVerticalScrollIndicator      = NO;
            _filterView.hidden = YES;
            
            if(!self.filterProgressSlider.superview)
                [_filterView addSubview:_filterProgressSlider ];
            
            [_filterView addSubview:_filterChildsView];
            [self initFilterChildsView];
        }
        else{
            _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, playerViewOriginX + playerViewHeight, kWIDTH, kHEIGHT - playerViewOriginX - playerViewHeight - kToolbarHeight)];
            _filterView.backgroundColor = TOOLBAR_COLOR;
            [self.view addSubview:_filterView];
            
            [_filterView addSubview:self.fileterNewView];
            
            if(!self.filterProgressSlider.superview)
                [_filterView addSubview:_filterProgressSlider ];
            _filterStrengthLabel.hidden = YES;
            _percentageLabel.hidden =  YES;
            _filterProgressSlider.frame = CGRectMake(60, _filterView.frame.size.height*( 0.337 + 0.462 ) + (_filterView.frame.size.height*( 0.203 ) - 30)/2.0 + 5, self.filterView.frame.size.width - 60 - 60, 30);
            
        }
    }
    return _filterView;
}

-(void)filterLabelBtn:(UIButton *) btn
{
    [_fileterLabelNewScroView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
         if([obj isKindOfClass:[UIButton class]]){
             ((UIButton*)obj).selected = NO;
             ((UIButton*)obj).font = [UIFont systemFontOfSize:14];
         }
    }];
    
    int index = 0;
    for (int i = 0; i < newFiltersNameSortArray.count; i++) {
        NSArray * array = (NSArray *)newFiltersNameSortArray[i];
        index += array.count;
        if( i == btn.tag )
        {
            currentlabelFilter = i;
            index -= array.count;
            currentFilterIndex = index;
            break;
        }
    }
    
    self.fileterScrollView.hidden = NO;
    
    btn.selected = YES;
    btn.font = [UIFont boldSystemFontOfSize:14];
//    [self scrollViewChildItemTapCallBlock:_originalItem];
}

-(void)scrollViewIndex:(int) fileterindex
{
    __block int index = 0;
    for (int i = 0; i < newFiltersNameSortArray.count; i++) {
        NSArray * array = (NSArray *)newFiltersNameSortArray[i];
        index += array.count;
        if( fileterindex < index )
        {
            currentlabelFilter = i;
            index -= array.count;
            currentFilterIndex = index;
            break;
        }
    }
}


-(UIView *)fileterNewView
{
    if( !_fileterNewView )
    {
        _fileterNewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _filterView.frame.size.height*( 0.337 + 0.462 ))];
        [_filterView addSubview:_fileterNewView];
        
        _fileterLabelNewScroView  = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _filterView.frame.size.height*( 0.337 ))];
        _fileterLabelNewScroView.tag = 1000;
        _fileterLabelNewScroView.showsVerticalScrollIndicator  =NO;
        _fileterLabelNewScroView.showsHorizontalScrollIndicator = NO;
        
        
        [self scrollViewIndex:selectFilterIndex-1];
        
        float contentWidth = 0 + _fileterLabelNewScroView.frame.size.height*2.0/5.0 + 20;
        
        for (int i = 0; newFilterSortArray.count > i; i++) {
            
            NSString *str = [newFilterSortArray[i] objectForKey:@"name"];
            
            float ItemBtnWidth = [RDHelpClass widthForString:str andHeight:14 fontSize:14] + 20;
            
            
            UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(contentWidth, 0, ItemBtnWidth, _fileterLabelNewScroView.frame.size.height)];
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
            [btn setTitle:str forState:UIControlStateNormal];
            [btn setTitleColor: [UIColor colorWithWhite:1.0 alpha:0.5]  forState:UIControlStateNormal];
            [btn setTitleColor:Main_Color forState:UIControlStateSelected];
            [btn addTarget:self action:@selector(filterLabelBtn:) forControlEvents:UIControlEventTouchUpInside];
            btn.titleLabel.textAlignment = NSTextAlignmentLeft;
            
            btn.tag = i;
            if( i == currentlabelFilter )
            {
                btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
                btn.selected = YES;
            }
            contentWidth += ItemBtnWidth;
            [_fileterLabelNewScroView addSubview:btn];
        }
        
        UIButton *noBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _fileterLabelNewScroView.frame.size.height*3.0/7.0 + 20, _fileterLabelNewScroView.frame.size.height)];
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, _fileterLabelNewScroView.frame.size.height*4.0/7.0/2.0, _fileterLabelNewScroView.frame.size.height*3.0/7.0, _fileterLabelNewScroView.frame.size.height*3.0/7.0)];
        imageView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无@3x" Type:@"png"]];
        noBtn.tag                            = 100;
        [noBtn addTarget:self action:@selector(noBtn_onclik) forControlEvents:UIControlEventTouchUpInside];
        [noBtn addSubview:imageView];
        
        [_fileterLabelNewScroView addSubview:noBtn];
        
        _fileterLabelNewScroView.contentSize = CGSizeMake(contentWidth+20, 0);
        
        float fileterNewScroViewHeight = _filterView.frame.size.height * 0.462;
        {
            _originalItem  = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(10, 0, fileterNewScroViewHeight - 20, fileterNewScroViewHeight)];
            _originalItem.backgroundColor        = [UIColor clearColor];


            {
                _originalItem.itemIconView.backgroundColor = UIColorFromRGB(0x27262c);
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _originalItem.itemIconView.frame.size.width, _originalItem.itemIconView.frame.size.height)];
                label.text = RDLocalizedString(@"无", nil);
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                label.font = [UIFont systemFontOfSize:15.0];
                [_originalItem.itemIconView addSubview:label];
            }

            _originalItem.fontSize       = 12;
            _originalItem.type           = 2;
            _originalItem.delegate       = self;
            _originalItem.selectedColor  = Main_Color;
            _originalItem.normalColor    = [UIColor colorWithWhite:1.0 alpha:0.5];
            _originalItem.cornerRadius   = _originalItem.frame.size.width/2.0;
            _originalItem.exclusiveTouch = YES;
//            _originalItem.itemIconView.backgroundColor   = [UIColor clearColor];
            _originalItem.itemTitleLabel.text            = RDLocalizedString(@"无滤镜", nil);
            _originalItem.tag                            = 0 + 1;
            _originalItem.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            [_originalItem setSelected:(0 == self->selectFilterIndex ? YES : NO)];
            [_originalItem setCornerRadius:5];
//            [_fileterNewView addSubview:_originalItem];
        }
//
        [_fileterNewView addSubview:_fileterLabelNewScroView];
        self.fileterScrollView.hidden = NO;
    }
    return _fileterNewView;
}

-(void)noBtn_onclik
{
    [self scrollViewChildItemTapCallBlock:_originalItem];
}

-( void )setNewFilterChildsView:( bool ) isYES atTypeIndex:(NSInteger) tag
{
    
    for (UIView *subview in _fileterScrollView.subviews) {
        if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
            [(ScrollViewChildItem*)subview setSelected:NO];
    }
    
    if( tag == 0 )
    {
        [_originalItem setSelected:isYES];
        return;
    }
}

-(UIScrollView *)fileterScrollView
{
    if( !_fileterScrollView )
    {
        float fileterNewScroViewHeight = _filterView.frame.size.height * 0.462;
//        (fileterNewScroViewHeight - 20) + 20
        _fileterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _fileterLabelNewScroView.frame.origin.y + _fileterLabelNewScroView.frame.size.height, kWIDTH, fileterNewScroViewHeight)];
        [_fileterNewView addSubview:_fileterScrollView];
        _fileterScrollView.showsVerticalScrollIndicator = NO;
        _fileterScrollView.showsHorizontalScrollIndicator = NO;
        
        
//        [_fileterScrollView addSubview:_originalItem];
        
    }
    else{
        for (UIView *subview in _fileterScrollView.subviews) {
            if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                
                if( subview != _originalItem )
                    [subview removeFromSuperview];
            
        }
    }
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *str = [newFilterSortArray[currentlabelFilter] objectForKey:@"name"];
    if( isEnglish )
        str = [str substringToIndex:1];
    
    NSArray * array = (NSArray *)newFiltersNameSortArray[ currentlabelFilter ];
    __block int index = 0;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*((_fileterScrollView.frame.size.height - 20) + 10) + 10 , 0, (_fileterScrollView.frame.size.height  - 20 ), _fileterScrollView.frame.size.height)];
        item.backgroundColor        = [UIColor clearColor];
        
        [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:[obj  objectForKey:@"cover"]]];
        item.fontSize       = 12;
        item.type           = 2;
        item.delegate       = self;
        item.selectedColor  = Main_Color;
        item.itemTitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        item.normalColor    = [UIColor colorWithWhite:1.0 alpha:0.5];
        //            item.normalColor    = UIColorFromRGB(0x888888);
        item.cornerRadius   = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor   = [UIColor clearColor];
        
        item.tag                            = idx + currentFilterIndex + 2;
        
        item.itemTitleLabel.text = [NSString stringWithFormat:@"%@%d",str,idx+1];
        
        if( (item.tag-1)  == self->selectedFilterFxIndex )
        {
            [item setSelected:YES];
        }
        
        item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
        
        if( (item.tag-1) == self->selectFilterIndex )
            index = idx;
        
        [item setCornerRadius:5];
        dispatch_async(dispatch_get_main_queue(), ^{
            [item setSelected:((item.tag-1) == self->selectFilterIndex ? YES : NO)];
            [_fileterScrollView addSubview:item];
        });
    
    }];
    
    float contentWidth = (_fileterScrollView.frame.size.height - 20 + 10 )*(array.count+1)+10;
    if( contentWidth <=  _fileterScrollView.frame.size.width )
    {
        contentWidth = _fileterScrollView.frame.size.width + 20;
    }
    
    _fileterScrollView.contentSize = CGSizeMake(contentWidth, 0);
    _fileterScrollView.delegate = self;
    
    float draggableX = _fileterScrollView.contentSize.width - _fileterScrollView.frame.size.width;
    if( draggableX >0 )
    {
        float x = (_fileterScrollView.frame.size.height - 20 + 10 ) *  index;
        
        if( x > draggableX )
            x = draggableX;
        
        _fileterScrollView.contentOffset = CGPointMake(x, 0);
    }
    //    });
    
    return _fileterScrollView;
}

//滤镜进度条
- (RDZSlider *)filterProgressSlider{
    if(!_filterProgressSlider){        
        float height = (_filterView.frame.size.height - 40) > 120 ? 120 : 90 ;
        
        _filterStrengthLabel = [[UILabel alloc] init];
        _filterStrengthLabel.frame = CGRectMake(15, ((40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 20 )/2.0, 50, 20);
        _filterStrengthLabel.textAlignment = NSTextAlignmentLeft;
        _filterStrengthLabel.textColor = UIColorFromRGB(0xffffff);
        _filterStrengthLabel.font = [UIFont systemFontOfSize:12];
        _filterStrengthLabel.text = RDLocalizedString(@"滤镜强度", nil);
        [_filterView addSubview:_filterStrengthLabel];
        
        _filterProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(75, ( (40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 30 )/2.0, self.filterView.frame.size.width - 65 - 65, 30)];
        [_filterProgressSlider setMaximumValue:1];
        [_filterProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_filterProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        _filterProgressSlider.layer.cornerRadius = 2.0;
        _filterProgressSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_filterProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        
        [_filterProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_filterProgressSlider setValue:oldFilterStrength];
        _filterProgressSlider.alpha = 1.0;
        _filterProgressSlider.backgroundColor = [UIColor clearColor];
        
        [_filterProgressSlider addTarget:self action:@selector(filterscrub) forControlEvents:UIControlEventValueChanged];
        [_filterProgressSlider addTarget:self action:@selector(filterendScrub) forControlEvents:UIControlEventTouchUpInside];
        [_filterProgressSlider addTarget:self action:@selector(filterendScrub) forControlEvents:UIControlEventTouchCancel];
        
        _percentageLabel = [[UILabel alloc] init];
        _percentageLabel.frame = CGRectMake(self.filterView.frame.size.width - 55, ( (40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 20 )/2.0, 50, 20);
        _percentageLabel.textAlignment = NSTextAlignmentCenter;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = oldFilterStrength*100.0;
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int)percent];
        [_filterView addSubview:_percentageLabel];
    }
    return _filterProgressSlider;
}
//滤镜强度 滑动进度条
- (void)filterscrub{
    CGFloat current = _filterProgressSlider.value;
    float percent = current*100.0;
    if( !newFilterSortArray )
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
    else
    {
        _percentageLabel.hidden = NO;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.frame = CGRectMake(current*_filterProgressSlider.frame.size.width+_filterProgressSlider.frame.origin.x - _percentageLabel.frame.size.width/2.0, _filterProgressSlider.frame.origin.y - _percentageLabel.frame.size.height + 5, _percentageLabel.frame.size.width, _percentageLabel.frame.size.height);
        _percentageLabel.text = [NSString stringWithFormat:@"%d%",(int)percent];
    }
    [_videoCoreSDK setGlobalFilterIntensity:current];
    filterStrength = current;
    [self  playVideo:YES];
}

- (void)filterendScrub{
    CGFloat current = _filterProgressSlider.value;
    float percent = current*100.0;
    if( !newFilterSortArray )
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
    else
    {
        _percentageLabel.hidden = YES;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.frame = CGRectMake(current*_filterProgressSlider.frame.size.width+_filterProgressSlider.frame.origin.x - _percentageLabel.frame.size.width/2.0, _filterProgressSlider.frame.origin.y - _percentageLabel.frame.size.height + 5, _percentageLabel.frame.size.width, _percentageLabel.frame.size.height);
        _percentageLabel.text = [NSString stringWithFormat:@"%d%",(int)percent];
    }
    [_videoCoreSDK setGlobalFilterIntensity:current];
    filterStrength = current;
    [self  playVideo:YES];
}

- (void)refreshFilterChildItem{
    __weak typeof(self) myself = self;
    [globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [myself.filterChildsView viewWithTag:(idx + 1)];
        item.backgroundColor        = [UIColor clearColor];
        if(!item.itemIconView.image){
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
                if(idx == 0){
                    NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                    NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                    NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                    item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
                }else{
                    [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
                }
            }else{
                NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                }
                NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
            }
        }
    }];
}

#pragma mark- 配音
- (UIView *)dubbingView{
    if(!_dubbingView){        
        _dubbingView = [[UIView alloc] initWithFrame:bottomViewRect];
        _dubbingView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_dubbingView];
        
        [_dubbingView addSubview:self.dubbingPlayBtn];
        [_dubbingView addSubview:self.dubbingTrimmerView];

        UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 3)/2.0, _dubbingTrimmerView.frame.origin.y-2, 3, 50)];
        spanView.backgroundColor = [UIColor whiteColor];
        spanView.layer.cornerRadius = 1.5;
        [_dubbingView addSubview:spanView];

        [_dubbingView addSubview:self.dubbingCurrentTimeLbl];
        [_dubbingView addSubview:self.dubbingBtn];
        [_dubbingView addSubview:self.deletedDubbingBtn];
        [_dubbingView addSubview:self.reDubbingBtn];
        [_dubbingView addSubview:self.auditionDubbingBtn];
        
        if (iPhone4s) {
            CGRect frame = _dubbingCurrentTimeLbl.frame;
            frame.origin.y = 0;
            _dubbingCurrentTimeLbl.frame = frame;
            
            frame = _dubbingTrimmerView.frame;
            frame.origin.y = 15;
            _dubbingTrimmerView.frame = frame;
            
            frame = _dubbingPlayBtn.frame;
            frame.origin.y = 13;
            _dubbingPlayBtn.frame = frame;
            
            frame = spanView.frame;
            frame.origin.y = _dubbingTrimmerView.frame.origin.y-2;
            spanView.frame = frame;
        }
        [self.view addSubview:self.dubbingVolumeView];
        
        _dubbingView.hidden = YES;
    }    
    return _dubbingView;    
}

/**配音缩率图进度滑块
 */
- (DubbingTrimmerView *)dubbingTrimmerView{
    if(!_dubbingTrimmerView){
        CGRect rect = CGRectMake(67, _dubbingPlayBtn.frame.origin.y - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0), _dubbingView.bounds.size.width - 67 - 20, 45);
        _dubbingTrimmerView = [[DubbingTrimmerView alloc] initWithFrame:rect videoCore:_videoCoreSDK];
        _dubbingTrimmerView.backgroundColor = [UIColor clearColor];
        [_dubbingTrimmerView setClipTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE))];
        [_dubbingTrimmerView setThemeColor:[UIColor lightGrayColor]];
        [_dubbingTrimmerView setDelegate:self];
        _dubbingTrimmerView.tag = 3;
        _dubbingTrimmerView.piantouDuration = 0;
        _dubbingTrimmerView.pianweiDuration = 0;
        _dubbingTrimmerView.rightSpace = 20;

//        [self initThumbTimes];
//        [thumbTimes addObject:@(_videoCoreSDK.duration)];
        _dubbingTrimmerView.thumbImageTimes = thumbTimes.count;
        [_videoCoreSDK getImageAtTime:kCMTimeZero scale:0.3 completion:^(UIImage *image) {
            [_dubbingTrimmerView resetSubviews:image];
        }];    
    }
    return _dubbingTrimmerView;
}

/**进入配音界面的播放按键
 */
- (UIButton *)dubbingPlayBtn{
    if(!_dubbingPlayBtn){
        _dubbingPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _dubbingPlayBtn.backgroundColor = [UIColor clearColor];
        _dubbingPlayBtn.frame = CGRectMake(5, _dubbingView.bounds.size.height/2.0 - 44, 44, 44);
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [_dubbingPlayBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];        
    }    
    return _dubbingPlayBtn;
}

/**配音按键
 */
- (UIButton *)dubbingBtn{    
    if(!_dubbingBtn){
        _dubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _dubbingBtn.backgroundColor = [UIColor clearColor];
        _dubbingBtn.frame = CGRectMake((kWIDTH - 113)/2.0, _dubbingView.bounds.size.height/2.0 + (_dubbingView.bounds.size.height/2.0 - 35)/2.0, 113, 35);
        _dubbingBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        _dubbingBtn.layer.borderWidth = 1.0;
        _dubbingBtn.layer.cornerRadius = 35/2.0;
        _dubbingBtn.layer.masksToBounds = YES;
        [_dubbingBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
        [_dubbingBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateSelected];
        [_dubbingBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_dubbingBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateSelected];
        [_dubbingBtn setSelected:NO];
        [_dubbingBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_dubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_dubbingBtn addTarget:self action:@selector(touchesDownDubbingBtn) forControlEvents:UIControlEventTouchDown];
    }
    return _dubbingBtn;    
}

/**删除配音按键
 */
- (UIButton *)deletedDubbingBtn{
    if(!_deletedDubbingBtn){
        _deletedDubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deletedDubbingBtn.backgroundColor = [UIColor clearColor];
        _deletedDubbingBtn.frame = _dubbingBtn.frame;
        _deletedDubbingBtn.layer.borderColor = CUSTOM_GRAYCOLOR.CGColor;
        _deletedDubbingBtn.layer.borderWidth = 1.0;
        _deletedDubbingBtn.layer.cornerRadius = 35/2.0;
        _deletedDubbingBtn.layer.masksToBounds = YES;
        [_deletedDubbingBtn setTitle:RDLocalizedString(@"删除", nil) forState:UIControlStateNormal];
        [_deletedDubbingBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [_deletedDubbingBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_deletedDubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_deletedDubbingBtn addTarget:self action:@selector(touchesUpDeletedDubbingBtn) forControlEvents:UIControlEventTouchDown];
        _deletedDubbingBtn.hidden = YES;
    }    
    return _deletedDubbingBtn;    
}

/**重新配音按键
 */
- (UIButton *)reDubbingBtn{
    if(!_reDubbingBtn){
        _reDubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _reDubbingBtn.backgroundColor = [UIColor clearColor];
        _reDubbingBtn.frame = CGRectMake(_dubbingBtn.frame.origin.x - 24 - 65, _dubbingBtn.frame.origin.y + (35 - 27)/2.0, 65, 27);
        _reDubbingBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _reDubbingBtn.layer.borderWidth = 1.0;
        _reDubbingBtn.layer.cornerRadius = _reDubbingBtn.bounds.size.height/2.0;
        _reDubbingBtn.layer.masksToBounds = YES;
        [_reDubbingBtn setTitle:RDLocalizedString(@"重配", nil) forState:UIControlStateNormal];
        [_reDubbingBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_reDubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_reDubbingBtn addTarget:self action:@selector(reDubbingTouchesUp) forControlEvents:UIControlEventTouchUpInside];
        _reDubbingBtn.hidden = YES;
    }
    return _reDubbingBtn;
}

/**试听配音按键
 */
- (UIButton *)auditionDubbingBtn{
    if(!_auditionDubbingBtn){
        _auditionDubbingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _auditionDubbingBtn.backgroundColor = [UIColor clearColor];
        _auditionDubbingBtn.frame = CGRectMake(_dubbingBtn.frame.origin.x + _dubbingBtn.bounds.size.width + 24, _reDubbingBtn.frame.origin.y, 65, 27);
        _auditionDubbingBtn.layer.borderColor = UIColorFromRGB(0xb2b2b2).CGColor;
        _auditionDubbingBtn.layer.borderWidth = 1.0;
        _auditionDubbingBtn.layer.cornerRadius = _auditionDubbingBtn.bounds.size.height/2.0;
        _auditionDubbingBtn.layer.masksToBounds = YES;
        [_auditionDubbingBtn setTitle:RDLocalizedString(@"试听", nil) forState:UIControlStateNormal];
        [_auditionDubbingBtn setTitleColor:UIColorFromRGB(0xb2b2b2) forState:UIControlStateNormal];
        [_auditionDubbingBtn.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_auditionDubbingBtn addTarget:self action:@selector(auditionDubbingTouchesUp) forControlEvents:UIControlEventTouchUpInside];
        _auditionDubbingBtn.hidden = YES;
    }
    return _auditionDubbingBtn;
}

/**配音当前时间
 */
- (UILabel *)dubbingCurrentTimeLbl{
    if(!_dubbingCurrentTimeLbl){
        _dubbingCurrentTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 60)/2.0, _dubbingTrimmerView.frame.origin.y - 15 - 8, 60, 15)];
        _dubbingCurrentTimeLbl.textAlignment = NSTextAlignmentCenter;
        _dubbingCurrentTimeLbl.textColor = [UIColor whiteColor];
        _dubbingCurrentTimeLbl.text = @"0.00";
        _dubbingCurrentTimeLbl.font = [UIFont systemFontOfSize:12];
    }    
    return _dubbingCurrentTimeLbl;
}

/**配音音量
 */
- (UIView *)dubbingVolumeView{
    if(!_dubbingVolumeView){        
        _dubbingVolumeView = [UIView new];
        _dubbingVolumeView.frame = CGRectMake(10, playerViewOriginX + playerViewHeight - 35 - (LastIphone5?0:15), kWIDTH - 20, 35);
        
        _dubbingVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(41, 2, _dubbingVolumeView.frame.size.width-82 + 15, 31)];
        _dubbingVolumeSlider.minimumValue = 0;
        _dubbingVolumeSlider.maximumValue = 1;
        _dubbingVolumeSlider.value = _musicVolume/volumeMultipleM;
        [_dubbingVolumeSlider setMaximumTrackTintColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
        [_dubbingVolumeSlider setMinimumTrackTintColor:[UIColor whiteColor]];
//        UIImage *thumbImage = [RDHelpClass rdImageWithColor:Main_Color cornerRadius:9];
//        [_dubbingVolumeSlider setThumbImage:thumbImage forState:UIControlStateNormal];
        [_dubbingVolumeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_dubbingVolumeSlider addTarget:self action:@selector(dubbingVolumeSliderEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [_dubbingVolumeSlider addTarget:self action:@selector(dubbingVolumeSliderEndScrub) forControlEvents:UIControlEventTouchCancel];
        
        UILabel *peiyueValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
        peiyueValueLabel.textAlignment = NSTextAlignmentCenter;
        peiyueValueLabel.textColor = [UIColor whiteColor];
        peiyueValueLabel.font = [UIFont systemFontOfSize:11];
        peiyueValueLabel.text = RDLocalizedString(@"配音", nil);
        peiyueValueLabel.adjustsFontSizeToFitWidth = YES;
        
        [_dubbingVolumeView addSubview:_dubbingVolumeSlider];
        [_dubbingVolumeView addSubview:peiyueValueLabel];
        
        _dubbingVolumeView.hidden = YES;
    }
    return _dubbingVolumeView;
}

#pragma mark - 变声
- (UIView *)soundEffectView {
    if (!_soundEffectView) {
        _soundEffectView = [[UIView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height)];
        _soundEffectView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_soundEffectView];
        
        soundEffectScrollView           = [UIScrollView new];
        soundEffectScrollView.frame     = CGRectMake(0, bottomViewRect.size.height*0.427, bottomViewRect.size.width, bottomViewRect.size.height*0.385);
        soundEffectScrollView.backgroundColor                   = TOOLBAR_COLOR;
        soundEffectScrollView.showsHorizontalScrollIndicator    = NO;
        soundEffectScrollView.showsVerticalScrollIndicator      = NO;
        [_soundEffectView addSubview:soundEffectScrollView];
        WeakSelf(self);
        [soundEffectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(strongSelf->soundEffectScrollView.frame.size.height + 10)+10, 0, strongSelf->soundEffectScrollView.frame.size.height, strongSelf->soundEffectScrollView.frame.size.height)];
            item.isVoiceFX = true;
            item.backgroundColor = [UIColor clearColor];
            item.fontSize       = 12;
            item.type           = 4;
            item.delegate       = strongSelf;
            item.selectedColor  = Main_Color;
            item.normalColor    = UIColorFromRGB(0x888888);
            item.cornerRadius   = 3.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor   = UIColorFromRGB(0x333333);
//            item.itemIconView.image = [RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"jianji/VoiceFXIcon/剪辑-音效-%@_", obj]];
            item.itemTitleLabel.text            = RDLocalizedString(obj, nil);
            item.tag                            = idx + 1;
//            item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            
            item.itemIconView.frame =  CGRectMake(0, 0, item.frame.size.width, item.frame.size.height);
            
            item.itemTitleLabel.frame = CGRectMake(0, (item.frame.size.height - item.itemTitleLabel.frame.size.height)/2.0, item.itemTitleLabel.frame.size.width, item.itemTitleLabel.frame.size.height);
            [item setFontSize:14];
            item.itemTitleLabel.textColor = [UIColor whiteColor];
            
            [strongSelf->soundEffectScrollView addSubview:item];
            [item setSelected:(idx == strongSelf->selectedSoundEffectIndex+1 ? YES : NO)];
        }];
        
        soundEffectScrollView.contentSize = CGSizeMake(soundEffectArray.count * (soundEffectScrollView.frame.size.height + 10)+20, soundEffectScrollView.frame.size.height);
        _soundEffectView.hidden = YES;
    }
    return _soundEffectView;
}

- (UIView *)customSoundView {
    if (!_customSoundView) {
        _customSoundView = [[UIView alloc] initWithFrame:_soundEffectView.bounds];
        _customSoundView.backgroundColor = TOOLBAR_COLOR;
        [_soundEffectView addSubview:_customSoundView];
        if (selectedSoundEffectIndex >= 0) {
            _customSoundView.hidden = YES;
        }
        
        UIImageView *soundEffectImage = [[UIImageView alloc] initWithFrame:CGRectMake(5, (_customSoundView.bounds.size.height - 30)/2.0, 30, 30)];
        soundEffectImage.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"编辑-变声-变调_@2x" Type:@"png"]];
        [_customSoundView addSubview:soundEffectImage];
        
        soundEffectSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(40, (_customSoundView.bounds.size.height - 20)/2.0, kWIDTH - 100, 20)];
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
        [soundEffectSlider addTarget:self action:@selector(soundEffectEndScrub) forControlEvents:UIControlEventTouchUpInside];
        [soundEffectSlider addTarget:self action:@selector(soundEffectEndScrub) forControlEvents:UIControlEventTouchCancel];
        [_customSoundView addSubview:soundEffectSlider];
        
        soundEffectLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 60 , soundEffectSlider.frame.origin.y, 60, 20)];
        soundEffectLabel.textAlignment = NSTextAlignmentCenter;
        soundEffectLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        soundEffectLabel.font = [UIFont systemFontOfSize:10];
        soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
        [_customSoundView addSubview:soundEffectLabel];
        [UIColor whiteColor];
    }
    return _customSoundView;
}

//变调强度 滑动进度条
- (void)soundEffectScrub{
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pitch];
}

- (void)soundEffectEndScrub{
    float pitch = pow(2.0, soundEffectSlider.value/1200.0);
    __weak typeof(self) weakSelf = self;
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.identifier.length > 0) {
                [weakSelf.videoCoreSDK setPitch:pitch identifier:obj.identifier];
            }
        }];
    }];
    if (!_videoCoreSDK.isPlaying) {
//        [self playVideo:YES];
    }
}

#pragma mark-
- (UIView *)titleView{
    if(!_titleView){
        _titleView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, 44)];
        if (isNewUI) {
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (__bridge id)[UIColor clearColor].CGColor];
            gradientLayer.locations = @[@0.3, @1.0];
            gradientLayer.startPoint = CGPointMake(0, 0);
            gradientLayer.endPoint = CGPointMake(0, 1.0);
            gradientLayer.frame = _titleView.bounds;
            [_titleView.layer addSublayer:gradientLayer];
        }else {
            _titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
        }
        
        titleLabel = [UILabel new];
        titleLabel.frame = CGRectMake(0, 0, kWIDTH, 44);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:20];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.text = RDLocalizedString(@"视频编辑", nil);
        //titleLabel.text = RDLocalizedString(@"视频编辑", nil);
        [_titleView addSubview:titleLabel];
        
        cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.exclusiveTouch = YES;
        cancelBtn.backgroundColor = [UIColor clearColor];
        cancelBtn.frame = CGRectMake(iPhone4s?0:5, (_titleView.frame.size.height - 44), 44, 44);
        [cancelBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        [_titleView addSubview:cancelBtn];
        
        UIButton *publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        publishButton.exclusiveTouch = YES;
        publishButton.backgroundColor = [UIColor clearColor];
        publishButton.frame = CGRectMake(kWIDTH - 64, (_titleView.frame.size.height - 44), 64, 44);
        publishButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [publishButton setTitleColor:Main_Color forState:UIControlStateNormal];
        [publishButton setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [publishButton addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
        [_titleView addSubview:publishButton];
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDraft
           && ((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate
           && [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(saveDraftResult:)])
        {
            saveDraftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            saveDraftBtn.frame = CGRectMake(kWIDTH - 64 - 50, (self.titleView.frame.size.height - 44), 50, 44);
            saveDraftBtn.titleLabel.font = [UIFont systemFontOfSize:16];
            [saveDraftBtn setTitleColor:Main_Color forState:UIControlStateNormal];
            [saveDraftBtn setTitle:RDLocalizedString(@"存草稿", nil) forState:UIControlStateNormal];
            [saveDraftBtn addTarget:self action:@selector(saveDraftBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_titleView addSubview:saveDraftBtn];
        }
    }
    return _titleView;
}

#pragma mark- 标题
- (UIView *)toolbarTitleView {
    if (!_toolbarTitleView) {
        _toolbarTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
        _toolbarTitleView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_toolbarTitleView];
        
        toolbarTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
        toolbarTitleLbl.textAlignment = NSTextAlignmentCenter;
        toolbarTitleLbl.font = [UIFont boldSystemFontOfSize:17];
        toolbarTitleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [_toolbarTitleView addSubview:toolbarTitleLbl];
        
        cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        [_toolbarTitleView addSubview:cancelBtn];
        
        _toolbarTitlefinishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [_toolbarTitlefinishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_toolbarTitlefinishBtn addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
        [_toolbarTitleView addSubview:_toolbarTitlefinishBtn];
    }
    return _toolbarTitleView;
}

/**导出进度条
 */
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
                [weakself initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil)
                                               message:@""
                                     cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                     otherButtonTitles:RDLocalizedString(@"确定",nil)
                                          alertViewTag:101];
                
            });            
        };
    }
    return _exportProgressView;
}

- (void)cancelExportBlock{
    //将界面上的时间进度设置为零
    _videoProgressSlider.value = 0;
    _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    [_exportProgressView setProgress:0 animated:NO];
    [_exportProgressView removeFromSuperview];
    _exportProgressView = nil;
    [self refreshWatermarkArrayWithIsExport:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
}
/**播放器
 */
- (UIView *)playerView{
    if(!_playerView){
        _playerView = [UIView new];
        _playerView.frame = CGRectMake(0, playerViewOriginX, kWIDTH, playerViewHeight);
        _playerView.backgroundColor = [UIColor blackColor];
        [_playerView addSubview:self.playButton];
    }
    return _playerView;
}

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
        _playerToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height - (isNewUI ? 22 : 44), _playerView.frame.size.width, 44)];
        if (!isNewUI) {
            _playerToolBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        }
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

#pragma mark- 功能区分界面
-(UIView *)functionalAreaView
{
    if( !_functionalAreaView )
    {
        _functionalAreaView = [[UIView alloc] initWithFrame:CGRectMake(0, playerViewOriginX + playerViewHeight, kWIDTH, kHEIGHT - playerViewHeight - playerViewOriginX)];
        _functionalAreaView.backgroundColor = TOOLBAR_COLOR;
        //功能区
        [_functionalAreaView addSubview:self.functionalAreaScrollView ];
    }
    return _functionalAreaView;
}

#pragma mark- 播放按钮
-(UIButton *)playBtn
{
    if( !_playBtn )
    {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.backgroundColor = [UIColor clearColor];
        _playBtn.frame = CGRectMake(5, 0, 44, 44);
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [_playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}
#pragma mark- 功能栏
-( UIScrollView * )functionalAreaScrollView
{
    if( !_functionalAreaScrollView )
    {
        EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
        functionalItems = [NSMutableArray array];
        RDFunctionType funcType = RDFunctionType_None;
        if (editConfig.enableMusic || editConfig.enableDubbing || editConfig.enableSoundEffect) {
            NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"声音", nil),@"title",@(RDFunctionType_Sound),@"id", nil];
            [functionalItems addObject:dic2];
            funcType = RDFunctionType_Sound;
        }
        if (editConfig.enableFragmentedit) {
            NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"edit-title", nil),@"title",@(RDFunctionType_FragmentEdit),@"id", nil];
            [functionalItems addObject:dic3];
        }
        if (editConfig.enableMV || editConfig.enableSubtitle || editConfig.enableFilter || editConfig.enableEffect || editConfig.enableSticker || (editConfig.enableEffectsVideo && editConfig.specialEffectResourceURL.length > 0) || editConfig.enableDewatermark || editConfig.enableCollage || editConfig.enableDoodle) {
            NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"高级编辑", nil),@"title",@(RDFunctionType_AdvanceEdit),@"id", nil];
            [functionalItems addObject:dic4];
            funcType = RDFunctionType_AdvanceEdit;
        }
        if (editConfig.enableProportion || editConfig.enablePicZoom || editConfig.enableBackgroundEdit || editConfig.enableCover) {
            NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"Quick-set", nil),@"title",@(RDFunctionType_Setting),@"id", nil];
            [functionalItems addObject:dic1];
            if (funcType == RDFunctionType_None) {
                funcType = RDFunctionType_Setting;
            }
        }
        float height = (iPhone_X ? 88 : (iPhone4s ? 55 : 60));
        _functionalAreaScrollView =  [UIScrollView new];
        _functionalAreaScrollView.frame = CGRectMake(0, _functionalAreaView.frame.size.height - (88 + (iPhone_X ? 34 : 0)) - height, kWIDTH, height);
        _functionalAreaScrollView.showsVerticalScrollIndicator = NO;
        _functionalAreaScrollView.showsHorizontalScrollIndicator = NO;
        float toolItemBtnWidth = MAX(kWIDTH/(functionalItems.count), 60 + 5);
        __block float contentsWidth = 0;
        __block float originX = 0;
        [functionalItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[functionalItems[idx] objectForKey:@"id"] integerValue];
            if (toolItemBtn.tag == funcType) {
                toolItemBtn.selected = YES;
                originX = idx * toolItemBtnWidth;
            }
            toolItemBtn.exclusiveTouch = YES;
            toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, 0, toolItemBtnWidth, height);
            [toolItemBtn addTarget:self action:@selector(clickfunctionalItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setTitle:[functionalItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            toolItemBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
            [_functionalAreaScrollView addSubview:toolItemBtn];
            
            contentsWidth += toolItemBtnWidth;
        }];
        _functionalAreaScrollView.contentSize = CGSizeMake(contentsWidth, 0);
        
        selectedFunctionView = [[UIView alloc] initWithFrame:CGRectMake(originX, height - 2, toolItemBtnWidth, 2)];
        selectedFunctionView.backgroundColor = Main_Color;
        [_functionalAreaScrollView addSubview:selectedFunctionView];
        
        [self toolBarViewItems:funcType];
        selecteFunction = RDAdvanceEditType_None;
        _functionalAreaScrollView.hidden = YES;
    }
    return _functionalAreaScrollView;
}

#pragma mark - 调整函数
//MV
-(void)AdjMVReturn:(BOOL) isSave
{
    if (isSave) {
        oldLastThemeMVIndex = lastThemeMVIndex;
        oldMusicIndex = selectMusicIndex;
    } else if( oldLastThemeMVIndex != lastThemeMVIndex ) {
        seekTime  = _videoCoreSDK.currentTime;
        lastThemeMVIndex = oldLastThemeMVIndex;
        ScrollViewChildItem *item = [_mvChildsView viewWithTag:lastThemeMVIndex + 1];
        [self scrollViewChildItemTapCallBlock:item];
    }
    [_mvChildsView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_mvChildsView removeFromSuperview];
    _mvChildsView = nil;
    [_mvView removeFromSuperview];
    _mvView = nil;
}
//变声
-(void)AdjSoundEffectReturn:(BOOL) isSave
{
    if(isSave)
    {
        oldSoundEffectIndex = selectedSoundEffectIndex;
    }
    else if( oldSoundEffectIndex != selectedSoundEffectIndex ) {
        seekTime  = _videoCoreSDK.currentTime;
        ScrollViewChildItem *itemBtn = [soundEffectScrollView viewWithTag:oldSoundEffectIndex + 2];
        [self scrollViewChildItemTapCallBlock:itemBtn];
    }
    [soundEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [soundEffectScrollView removeFromSuperview];
    soundEffectScrollView = nil;
    [_customSoundView removeFromSuperview];
    _customSoundView = nil;
    [_soundEffectView removeFromSuperview];
    _soundEffectView = nil;
}
//配乐
-(void)AdjMusicReturn:(BOOL) isSave
{
    if(isSave) {
        oldMusicIndex = selectMusicIndex;
    }else if( oldMusicIndex != selectMusicIndex ) {
        seekTime  = _videoCoreSDK.currentTime;
        BOOL enableLocalMusic = ((RDNavigationViewController *)self.navigationController).editConfiguration.enableLocalMusic;
        NSString *cloudMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL;
        
        NSInteger count = enableLocalMusic ? (cloudMusicResourceURL.length>0 ? 4 : 3) : (cloudMusicResourceURL.length>0 ? 3 : 2);
        if( (oldMusicIndex+1) >count)
        {
            [self scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)[_musicChildsView viewWithTag:oldMusicIndex+1]];
        } else {
            switch (oldMusicIndex)
            {
                case 1:
                {
                    [self scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)[_musicChildsView viewWithTag:oldMusicIndex+1]];
                }
                    break;
                case 2:
                case 3:
                {
                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
                    [mvMusicArray removeAllObjects];
                    mvMusicArray = nil;
                    
                    selectMusicIndex = oldMusicIndex;
                    _musicTimeRange = oldmusic.clipTimeRange;
                    _musicURL       = oldmusic.url;
                    ScrollViewChildItem *item;
                    if (oldMusicIndex == 2) {
                        item = [_musicChildsView viewWithTag:3];
                        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]).itemTitleLabel.text = @"云音乐";
                    }else {
                        item = [_musicChildsView viewWithTag:4];
                        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"本地", nil);
                    }
                    item.itemTitleLabel.text = oldmusic.name;
                    [item startScrollTitle];
                    [item setSelected:YES];
                    [self initPlayer];
                }
                    break;
                default:
                    selectMusicIndex = oldMusicIndex;
                    break;
            }
        }
    }
}
//滤镜
-(void)AdjFilterReturn:(BOOL) isSave
{
    if( !isSave )
    {
        if( oldFilterType != selectFilterIndex )
        {
            [self scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)[_filterChildsView viewWithTag:oldFilterType+1]];
        }
        if( oldFilterStrength != filterStrength )
        {
            [_filterProgressSlider setValue:oldFilterStrength];
            float percent = oldFilterStrength*100.0;
            _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
            [_videoCoreSDK setGlobalFilterIntensity:oldFilterStrength];
        }
        selectFilterIndex = oldFilterType;
        
        if( 0 == self->selectFilterIndex )
            _filterProgressSlider.enabled = NO;
        else
            _filterProgressSlider.enabled = YES;
        
        filterStrength = oldFilterStrength;
    }
    else
    {
        oldFilterStrength = filterStrength;
        oldFilterType = selectFilterIndex;
    }
    [_filterView removeFromSuperview];
    _filterView = nil;
    [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            ((ScrollViewChildItem *)obj).itemIconView.image = nil;
            [((ScrollViewChildItem *)obj) removeFromSuperview];
        }
    }];
    [_filterChildsView removeFromSuperview];
    _filterChildsView = nil;
    [_filterProgressSlider removeFromSuperview];
    _filterProgressSlider = nil;
}
//比例
-(void)AdjProportionReturn:(BOOL) isSave
{
    if(isSave)
    {
        oldProportionIndex = selectProportionIndex;
        if (_coverView) {
            CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(_exportVideoSize, _playerView.bounds);
            coverIV.frame = videoRect;
            coverAuxView.frame = coverIV.bounds;
            if (coverFile && CMTimeCompare(coverFile.coverTime, kCMTimeInvalid) == 0) {
                UIImage *image = [RDHelpClass getFullScreenImageWithUrl:coverFile.contentURL];
                coverFile.crop = [RDHelpClass getCropWithImageSize:image.size videoSize:_exportVideoSize];
                image = [RDHelpClass image:image rotation:coverFile.rotate cropRect:coverFile.crop];
                coverIV.image = image;
            }
        }
        if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect)
            [[NSUserDefaults standardUserDefaults] setInteger:oldProportionIndex forKey:kRDProportionIndex];
    }
    else if( oldProportionIndex != selectProportionIndex )
    {
        seekTime  = _videoCoreSDK.currentTime;
        selectProportionIndex = oldProportionIndex;
        UIButton *btn = [_proportionView viewWithTag:oldProportionIndex];
        [self proportionItem:btn];
    }
}
//图片运动
-(void)AdjEnlargeReturn:(BOOL) isSave
{
    if( isSave )
    {
        oldIsEnlarge = isEnlarge;
        [[NSUserDefaults standardUserDefaults] setBool:!isEnlarge forKey:kRDDisablePicAnimation];
    }
    else if( oldIsEnlarge != isEnlarge )
    {
        seekTime  = _videoCoreSDK.currentTime;
        isEnlarge = oldIsEnlarge;
        [_contentMagnificationBtn setOn:oldIsEnlarge];
        [self getValue1:_contentMagnificationBtn];
    }
    
}
//背景
-(void)AdjBackgroundReturn:(BOOL) isSave
{
    
}
//字幕
-(void)AdjSubtitleReturn:(BOOL) isSave
{
    [_subtitleView removeFromSuperview];
    _subtitleView = nil;
}
//贴纸
-(void)AdjStickerReturn:(BOOL) isSave
{
    [_stickerView removeFromSuperview];
    _stickerView = nil;
}
//特效
-(void)AdjFXReturn:(BOOL) isSave
{
    [FXView removeFromSuperview];
    FXView = nil;
}

#pragma mark- 返回调整
-(BOOL)ReturnAdjustment:(BOOL) isSave
{
    addingMaterialDuration = 0;
    isModifiedMaterialEffect = NO;
    isProprtionUI = false;
    if(!isNewUI )
        return NO;
    
    _addEffectsByTimeline.stopAnimated = true;
//    _toolbarTitleView.hidden = YES;
    
//    [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
       
        _titleView.hidden = NO;
        
//    }];
    
    [RDHelpClass animateView:_titleView atUP:YES];
    _functionalAreaView.hidden = NO;
    if( _captionVideoView.hidden )
        _playerToolBar.hidden = NO;
    
    if (selecteFunction != RDAdvanceEditType_None) {
        UIButton *btn = [_toolBarView viewWithTag:selecteFunction];
        btn.selected = NO;
    }
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    
    bool isTrue = false;
    if( _toolBarView.hidden )
    {        
        [_dubbingTrimmerView setProgress:0 animated:NO];
        [_dubbingTrimmerView releaseImages];
//        if( (_otherView == nil) || (_otherView.hidden == YES) )
        _toolBarView.hidden = NO;
        toolbarTitleLbl.hidden = YES;
        _mvView.hidden = YES;
        _subtitleView.hidden = YES;
        _stickerView.hidden = YES;
        _filterView.hidden = YES;
        FXView.hidden = YES;
        _dewatermarkView.hidden = YES;
        _collageView.hidden = YES;
        _doodleView.hidden = YES;
        _addEffectsByTimeline.hidden = YES;
        
        _musicView.hidden = YES;
        _dubbingView.hidden = YES;
        _dubbingVolumeView.hidden = YES;
        _soundEffectView.hidden = YES;
        _customSoundView.hidden = YES;
        
        _proportionView.hidden = YES;
        _contentMagnificationView.hidden = YES;
        _coverView.hidden = YES;
        _bottomThumbnailView.hidden = YES;
        [addedMaterialEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _addedMaterialEffectView.hidden = YES;
        
        //背景 画布
        _canvasView.hidden = TRUE;
        
        isTrue = YES;
    }
    
    switch (selecteFunction) {
        case RDAdvanceEditType_MV://MV
        {
            [RDHelpClass animateViewHidden:self.mvView  atUP:NO atBlock:^{
                [self AdjMVReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_SoundEffect://变声
        {
            [RDHelpClass animateViewHidden:self.soundEffectView  atUP:NO atBlock:^{
                [self AdjSoundEffectReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_Music://配乐
        {
            [RDHelpClass animateViewHidden:_musicView  atUP:NO atBlock:^{
                [self AdjMusicReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_Filter://滤镜
        {
            [RDHelpClass animateViewHidden:_filterView  atUP:NO atBlock:^{
                [self AdjFilterReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_Proportion://比例
        {
            [RDHelpClass animateViewHidden:_proportionView  atUP:NO atBlock:^{
                [self AdjProportionReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_PicZoom://图片运动
        {
            [RDHelpClass animateViewHidden:_coverView atUP:NO atBlock:^{
                [self AdjEnlargeReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_BG://背景
        {
            [RDHelpClass animateViewHidden:_subtitleView atUP:NO atBlock:^{
                [self AdjBackgroundReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_Subtitle://字幕
        {
            [RDHelpClass animateViewHidden:_filterView  atUP:NO atBlock:^{
                [self AdjSubtitleReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_Sticker://贴纸
        {
            [RDHelpClass animateViewHidden:_stickerView  atUP:NO atBlock:^{
                [self AdjStickerReturn:isSave];
            }];
        }
            break;
        case RDAdvanceEditType_Effect://特效
        {
            [RDHelpClass animateViewHidden:FXView  atUP:NO atBlock:^{
                [self AdjFXReturn:isSave];
            }];
        }
            break;
        default:
            break;
    }
    
    selecteFunction = RDAdvanceEditType_None;
    [RDHelpClass animateViewHidden:_toolbarTitleView atUP:NO atBlock:^{
        _toolbarTitleView.hidden = YES;
    }];
    
    selecteFunction = RDAdvanceEditType_None;
    
    return isTrue;
}

-(void)FragmentEdit
{
//    [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
       
//        _titleView.hidden = NO;
        
//    }];
//    [RDHelpClass animateView:_titleView atUP:YES];
    _toolbarTitleView.hidden = YES;
    if( _captionVideoView.hidden )
        _playerToolBar.hidden = NO;
    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    NSMutableArray *array = [NSMutableArray new];
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [array addObject:[obj mutableCopy]];
        
    }];
    
    RDEditVideoViewController *editVideoVC = [[RDEditVideoViewController alloc] init];
    editVideoVC.filterFxArray = filterFxArray;
    editVideoVC.fileList = array;
    editVideoVC.collages = collages;
    editVideoVC.doodles = doodles;
    
    editVideoVC.musicVolume = 0.5;
    editVideoVC.push = NO;
    editVideoVC.fromToNext = YES;
    editVideoVC.isVague = isVague;
    editVideoVC.nextVideoCoreSDK = _videoCoreSDK;
    [editVideoVC setExportSize:_exportVideoSize];
    int CurrentTime = (int)((_videoCoreSDK.duration*VideoCurrentTime)*10.0);
    float fTime = ((float)(CurrentTime/10.0));
    
    [editVideoVC setCurrentTime:CMTimeMakeWithSeconds( fTime , TIMESCALE)];
    editVideoVC.isMotion = isEnlarge;
    editVideoVC.isNoBackground = isNoBackground;
    [editVideoVC setScenes:scenes];
    isEditVideoVC = true;
    editVideoVC.proportionIndex = (FileCropModeType)oldProportionIndex;
    WeakSelf(self);
    editVideoVC.thumbImageVideoCore = thumbImageVideoCore;
    
    editVideoVC.NextEditThumbImageVideoCoreBlock = ^( NSMutableArray <RDFile *>* fileList) {
    };
    
    editVideoVC.backNextEditVideoVCBlock = ^(NSArray *fileList,CGSize exportVideoSize,CMTime currentTime) {
        [_videoCoreSDK pause];
        
        if( fileList != nil )
        {
            isEditVideoVC = false;
            __block BOOL isSetFilter = NO;
            [fileList enumerateObjectsUsingBlock:^(RDFile *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.filterIndex != 0) {
                    isSetFilter = YES;
                    *stop = YES;
                }
            }];
            StrongSelf(self);
            if (isSetFilter) {
                [((ScrollViewChildItem *)[strongSelf.filterChildsView viewWithTag:strongSelf->selectFilterIndex+1]) setSelected:NO];
                strongSelf->selectFilterIndex = 0;
                
                if( 0 == self->selectFilterIndex )
                    _filterProgressSlider.enabled = NO;
                else
                    _filterProgressSlider.enabled = YES;
                
                [((ScrollViewChildItem *)[strongSelf.filterChildsView viewWithTag:strongSelf->selectFilterIndex+1]) setSelected:YES];
            }
            
            strongSelf.fileList = [fileList mutableCopy];
            
            [self Core_loadTrimmerViewThumbImage];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _videoCoreSDK.delegate = self;
            CGRect  rect  = self.playerView.bounds;
            _videoCoreSDK.frame = rect;
            
            scenes = [_videoCoreSDK getScenes];
            
            [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
            
//            [_videoCoreSDK seekToTime:currentTime];
            
            [_videoTrimmerView setProgress:(CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration) animated:NO];
            //                [_videoTrimmerView setProgress:0 animated:NO];
        });
        
    };
    editVideoVC.backNextEditVideoCancelBlock = ^(RDVECore * core,CMTime currentTime){
        
        [_videoCoreSDK pause];
        
        if( core != nil )
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                _videoCoreSDK.delegate = self;
                CGRect  rect  = self.playerView.bounds;
                _videoCoreSDK.frame = rect;
                [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
                
                //                [_videoTrimmerView setProgress:0 animated:NO];
                [_videoCoreSDK seekToTime:currentTime];
                [_videoTrimmerView setProgress:(CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration) animated:NO];
            });
        }
        else{
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
//                _videoCoreSDK = nil;
                [self initPlayer];
                _videoCoreSDK.delegate = self;
                _videoCoreSDK.enableAudioEffect = YES;
                //            [_videoTrimmerView setProgress:0 animated:NO];
                seekTime = currentTime;
                [_videoTrimmerView setProgress:(CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration) animated:NO];
            });
        }
        
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:editVideoVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //2019.10.21 修改 片段编辑跳转
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)editVideoVC_Core
{
        _videoCoreSDK.delegate = self;
    //    if (!_videoCoreSDK.view.superview) {
            CGRect  rect  = self.playerView.bounds;
            _videoCoreSDK.frame = rect;
            [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
    //    }
    //    [_videoCoreSDK setEditorVideoSize:exportSize];
        [_videoCoreSDK prepare];
}

#pragma mark- 编辑功能选择
- (void)clickfunctionalItemBtn:(UIButton *)sender{
    if( isNewUI && (sender.tag != RDFunctionType_FragmentEdit))
    {
        CGRect frame = selectedFunctionView.frame;
        frame.origin.x = sender.frame.origin.x;
        selectedFunctionView.frame = frame;
        
        [_functionalAreaScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIButton class]]) {
                if(obj.tag == sender.tag){
                    obj.selected = YES;
                }else{
                    obj.selected = NO;
                }
            }            
        }];
    }
    if (sender.tag == RDFunctionType_FragmentEdit) {
        [self FragmentEdit];
    }else {
        [self toolBarViewItems:sender.tag];
    }
}

#pragma mark- 功能分类
-(void)toolBarViewItems:(NSInteger) index
{
    [toolItems removeAllObjects];
    [_toolBarView removeFromSuperview];
    _toolBarView = nil;
    EditConfiguration *editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    switch (index) {
        case RDFunctionType_Setting:
        {
            //图片运动
            if(editConfiguration.enablePicZoom){
                NSDictionary *dic12 = [[NSDictionary alloc] initWithObjectsAndKeys:@"图片运动",@"title",@(RDAdvanceEditType_PicZoom),@"id", nil];
                [toolItems addObject:dic12];
            }
        }
            break;
        case RDFunctionType_Sound:
        {
            //音量
            if(editConfiguration.enableMusic){
                NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"音量",@"title",@(RDAdvanceEditType_Volume),@"id", nil];
                [toolItems addObject:dic1];
                NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"配乐",@"title",@(RDAdvanceEditType_Music),@"id", nil];
                [toolItems addObject:dic2];
                if(editConfiguration.soundMusicTypeResourceURL){
                    NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"音效",@"title",@(RDAdvanceEditType_Sound),@"id", nil];
                    [toolItems addObject:dic3];
                }
                NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"多段配乐",@"title",@(RDAdvanceEditType_Multi_track),@"id", nil];
                [toolItems addObject:dic4];
            }
            //配音
            if(editConfiguration.enableDubbing && editConfiguration.dubbingType != 1){
                NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"配音",@"title",@(RDAdvanceEditType_Dubbing),@"id", nil];
                [toolItems addObject:dic3];
            }
            //变声
            if(editConfiguration.enableSoundEffect){
                NSDictionary *dic9 = [[NSDictionary alloc] initWithObjectsAndKeys:@"变声",@"title",@(RDAdvanceEditType_SoundEffect),@"id", nil];
                [toolItems addObject:dic9];
            }
        }
            break;
        case RDFunctionType_AdvanceEdit:
        {
            //片段编辑
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableFragmentedit){
                NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"剪辑",@"title",@(RDAdvanceEditType_FragmentEdit),@"id", nil];
                [toolItems addObject:dic1];
            }
            //MV
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
                NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"M V",@"title",@(RDAdvanceEditType_MV),@"id", nil];
                [toolItems addObject:dic1];
            }
            //字幕
            if(editConfiguration.enableSubtitle){
                NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"字幕",@"title",@(RDAdvanceEditType_Subtitle),@"id", nil];
                [toolItems addObject:dic4];
            }
            //声音
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMusic || ((RDNavigationViewController *)self.navigationController).editConfiguration.enableDubbing || ((RDNavigationViewController *)self.navigationController).editConfiguration.enableSoundEffect){
                NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"声音",@"title",@(RDAdvanceEditType_SoundSettings),@"id", nil];
                [toolItems addObject:dic1];
            }
            //贴纸
            if(editConfiguration.enableEffect || editConfiguration.enableSticker){
                NSDictionary *dic6 = [[NSDictionary alloc] initWithObjectsAndKeys:@"贴纸",@"title",@(RDAdvanceEditType_Sticker),@"id", nil];
                [toolItems addObject:dic6];
            }
            
            //滤镜
            if(editConfiguration.enableFilter){
                NSDictionary *dic5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"滤镜",@"title",@(RDAdvanceEditType_Filter),@"id", nil];
                [toolItems addObject:dic5];
            }
            //特效
            if(editConfiguration.enableEffectsVideo
               && editConfiguration.specialEffectResourceURL.length > 0)
            {
                NSDictionary *dic8 = [[NSDictionary alloc] initWithObjectsAndKeys:@"特效",@"title",@(RDAdvanceEditType_Effect),@"id", nil];
                [toolItems addObject:dic8];
            }
            
            //加水印
            if(editConfiguration.enableWatermark){
                NSDictionary *dic10 = [[NSDictionary alloc] initWithObjectsAndKeys:@"加水印",@"title",@(RDAdvanceEditType_Watermark),@"id", nil];
                [toolItems addObject:dic10];
            }
            
            //马赛克
            if(editConfiguration.enableDewatermark){
                NSDictionary *dic10 = [[NSDictionary alloc] initWithObjectsAndKeys:@"马赛克",@"title",@(RDAdvanceEditType_Mosaic),@"id", nil];
                [toolItems addObject:dic10];
            }
            
            //去水印
            if(editConfiguration.enableDewatermark){
                NSDictionary *dic10 = [[NSDictionary alloc] initWithObjectsAndKeys:@"去水印",@"title",@(RDAdvanceEditType_Dewatermark),@"id", nil];
                [toolItems addObject:dic10];
            }
            //画中画
            if(editConfiguration.enableCollage){
                NSDictionary *dic15 = [[NSDictionary alloc] initWithObjectsAndKeys:@"画中画",@"title",@(RDAdvanceEditType_Collage),@"id", nil];
                [toolItems addObject:dic15];
            }
            //涂鸦
            if(editConfiguration.enableDoodle){
                NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:@"涂鸦",@"title",@(RDAdvanceEditType_Doodle),@"id", nil];
                [toolItems addObject:dic];
            }
            
            //比例
            if(editConfiguration.enableProportion){
                NSDictionary *dic11 = [[NSDictionary alloc] initWithObjectsAndKeys:@"比例",@"title",@(RDAdvanceEditType_Proportion),@"id", nil];
                [toolItems addObject:dic11];
            }
            
            //背景
            if(editConfiguration.enableBackgroundEdit){
                NSDictionary *dic13 = [[NSDictionary alloc] initWithObjectsAndKeys:@"画布",@"title",@(RDAdvanceEditType_BG),@"id", nil];
                [toolItems addObject:dic13];
            }
            //封面
            if(editConfiguration.enableCover){
                NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:@"封面", @"title",@(RDAdvanceEditType_Cover),@"id", nil];
                [toolItems addObject:dic];
            }
            
            //设置
//            if(editConfiguration.enableProportion || editConfiguration.enablePicZoom || editConfiguration.enableBackgroundEdit || editConfiguration.enableCover){
//                NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"设置",@"title",@(RDAdvanceEditType_Setting),@"id", nil];
//                [toolItems addObject:dic1];
//            }
        }
            break;
        default:
            break;
    }
    
    _toolBarView =  [UIScrollView new];
    _toolBarView.frame = CGRectMake(0, _functionalAreaView.bounds.size.height - 60 - (iPhone_X ? 34 : 0), kWIDTH, 60 );
    _toolBarView.showsVerticalScrollIndicator = NO;
    _toolBarView.showsHorizontalScrollIndicator = NO;
    [_functionalAreaView addSubview:_toolBarView];
    NSInteger count = (toolItems.count>5)?toolItems.count:5;
    if( (count == 5) && (toolItems.count%2) == 0.0 )
    {
        count = 4;
    }
    __block float toolItemBtnWidth = MAX(kWIDTH/count, 60 + 5);//_toolBarView.frame.size.height
    __block int iIndex = kWIDTH/toolItemBtnWidth + 1.0;
    __block float width = toolItemBtnWidth;
    toolItemBtnWidth = toolItemBtnWidth - ((toolItems.count > iIndex)?(toolItemBtnWidth/2.0/(iIndex)):0);
    __block float contentsWidth = 0;
    NSInteger offset = (count - toolItems.count)/2;
    [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        
        
        NSString *title = [self->toolItems[idx] objectForKey:@"title"];
        
        float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString(title, nil) andHeight:12 fontSize:12] + 15 ;
        
        if( ItemBtnWidth < toolItemBtnWidth )
            ItemBtnWidth = toolItemBtnWidth;
        
        UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
        toolItemBtn.backgroundColor = [UIColor clearColor];
        toolItemBtn.exclusiveTouch = YES;
        toolItemBtn.frame = CGRectMake(contentsWidth + ((toolItems.count > iIndex)?(width/2.0/(iIndex)):0), 0, ItemBtnWidth, _toolBarView.frame.size.height);
        [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@默认_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@选中_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (ItemBtnWidth - 44)/2.0, 16, (ItemBtnWidth - 44)/2.0)];
        [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
        
        [_toolBarView addSubview:toolItemBtn];
        contentsWidth += ItemBtnWidth;
    }];
    
    if( contentsWidth <= kWIDTH )
        contentsWidth = kWIDTH + 10;
    
    _toolBarView.contentSize = CGSizeMake(contentsWidth, 0);
}

/**工具栏
 */
- (UIScrollView *)toolBarView{
    if(!_toolBarView){
        toolItems = [NSMutableArray array];
        EditConfiguration *editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
        if(editConfiguration.enableMV){
            NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"M V",@"title",@(RDAdvanceEditType_MV),@"id", nil];
            [toolItems addObject:dic1];
        }
        if(editConfiguration.enableMusic){
            NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"配乐",@"title",@(RDAdvanceEditType_Music),@"id", nil];
            [toolItems addObject:dic2];
        }
        if(editConfiguration.enableFilter){
            NSDictionary *dic5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"滤镜",@"title",@(RDAdvanceEditType_Filter),@"id", nil];
            [toolItems addObject:dic5];
        }
        if (editConfiguration.enableMV
            && !editConfiguration.enableDubbing
            && !editConfiguration.enableSoundEffect
            && !editConfiguration.enableSubtitle
            && (!editConfiguration.enableEffect || !editConfiguration.enableSticker)
            && !editConfiguration.enableEffectsVideo
            && !editConfiguration.enableFragmentedit)
        {
            isNewUI = NO;//短视频或一键大片
            if(editConfiguration.enableSort) {
                NSDictionary *dic14 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"排序", nil),@"title",@(RDAdvanceEditType_Sort),@"id", nil];
                [toolItems addObject:dic14];
            }
        }
        else{
            return nil;
        }
        _toolBarView =  [UIScrollView new];
        _toolBarView.frame = CGRectMake(0, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)), kWIDTH, (iPhone_X ? 88 : (iPhone4s ? 55 : 60)));
        _toolBarView.showsVerticalScrollIndicator = NO;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        [self.view addSubview:_toolBarView];
        
        __block float toolItemBtnWidth = MAX(kWIDTH/toolItems.count, 60 + 5);//_toolBarView.frame.size.height
        __block float contentsWidth = 0;
        [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *title = [self->toolItems[idx] objectForKey:@"title"];
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.exclusiveTouch = YES;
            toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, 0, toolItemBtnWidth, 60);
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
            [_toolBarView addSubview:toolItemBtn];
            contentsWidth += toolItemBtnWidth;
        }];
        if( contentsWidth <= kWIDTH )
            contentsWidth = kWIDTH + 10;
        _toolBarView.contentSize = CGSizeMake(contentsWidth, 0);        
    }
    return _toolBarView;
}

- (void)check{
    if( isNewUI )
    {
        [self ReturnAdjustment:YES];
    }
    else
    {
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV || ((RDNavigationViewController *)self.navigationController).editConfiguration.enableMusic){
            [self clickToolItemBtn:[self.toolBarView viewWithTag:[[toolItems[0] objectForKey:@"id"] integerValue]]];
        }else if (((RDNavigationViewController *)self.navigationController).editConfiguration.enableSoundEffect) {
            [self clickToolItemBtn:[self.toolBarView viewWithTag:9]];//点击变声
        }
        else{
            [self clickToolItemBtn:[self.toolBarView viewWithTag:5]];//点击滤镜
        }
    }
}

- (void)initChildView{
    [self.view addSubview:self.filterView];
    [self.view addSubview:self.dubbingView];
    [self.view addSubview:self.subtitleView];
    [self.view addSubview:self.stickerView];
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
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

#pragma mark - 进入排序
- (void)enter_Sort{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    NSMutableArray *arr = [_fileList mutableCopy];
    RD_SortViewController *rdSort = [[RD_SortViewController alloc] init];
    rdSort.allThumbFiles = arr;
    rdSort.isShowDelete = true;
    rdSort.editorVideoSize = _exportVideoSize;
    __weak typeof(self) weakSelf = self;
    rdSort.finishAction = ^(NSMutableArray *sortFileList){
        if(sortFileList.count>0){
            StrongSelf(self);
            isRefreshOrder = true;
            strongSelf.fileList = [sortFileList mutableCopy];
            [strongSelf RandomTransition:strongSelf.fileList];
            [strongSelf initPlayer];
            [strongSelf check];
        }
    };
    rdSort.cancelAction = ^(NSMutableArray *sortFileList){
        [self check];
    };
    [self.navigationController pushViewController:rdSort animated:YES];
}

#pragma mark - 去水印
- (UIView *)dewatermarkView {
    if (!(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDewatermark)) {
        return nil;
    }
    if (!_dewatermarkView) {
        _dewatermarkView = [[UIView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height, kWIDTH, kHEIGHT - (_playerView.frame.origin.y + _playerView.bounds.size.height) - _toolbarTitleView.bounds.size.height)];
        _dewatermarkView.backgroundColor = TOOLBAR_COLOR;
        _dewatermarkView.hidden = YES;
        [self.view addSubview:_dewatermarkView];
    }
    return _dewatermarkView;
}

#pragma mark - 画中画
- (UIView *)collageView {
    if (!_collageView) {
        _collageView = [[UIView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height, kWIDTH, kHEIGHT - (_playerView.frame.origin.y + _playerView.bounds.size.height) - kToolbarHeight)];
        _collageView.backgroundColor = BOTTOM_COLOR;
        [self.view addSubview:_collageView];
        self.addEffectsByTimeline.currentEffect = selecteFunction;
        [_addEffectsByTimeline initAlbumTitleToolbarWithFrame:CGRectMake((kWIDTH - 180)/2.0, 0, 180, 44)];
        [_addEffectsByTimeline initAlbumViewWithFrame:_collageView.frame];
        [_toolbarTitleView addSubview:_addEffectsByTimeline.albumTitleView];
        [self.view addSubview:_addEffectsByTimeline.albumView];
    }
    return _collageView;
}

#pragma mark - 封面
- (UIView *)coverView {
    if (!_coverView) {
        _coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT - kToolbarHeight)];
        _coverView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _coverView.hidden = YES;
        [self.view addSubview:_coverView];
        
        CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(_exportVideoSize, _playerView.bounds);
        coverIV = [[UIImageView alloc] initWithFrame:CGRectMake(videoRect.origin.x, videoRect.origin.y + 44, videoRect.size.width, videoRect.size.height)];
        coverIV.backgroundColor = SCREEN_BACKGROUND_COLOR;
        if (coverFile && CMTimeCompare(coverFile.coverTime, kCMTimeInvalid) == 0) {
            UIImage *image = [RDHelpClass getFullScreenImageWithUrl:coverFile.contentURL];
            image = [RDHelpClass image:image rotation:coverFile.rotate cropRect:coverFile.crop];
            coverIV.image = image;
        }
        [_coverView addSubview:coverIV];
        
        coverAuxView = [_videoCoreSDK auxViewWithCGRect:coverIV.bounds];
        coverAuxView.hidden = YES;
        coverAuxView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [coverIV addSubview:coverAuxView];
        
        UIView * tooView = [[UIView alloc] initWithFrame:bottomViewRect];
        tooView.backgroundColor = TOOLBAR_COLOR;
        [_coverView addSubview:tooView];
        
        float toolItemBtnHeight = tooView.frame.size.height*0.6;
        float toolItemWidth = toolItemBtnHeight*5.0/8.0;
        float ImageWidth = toolItemBtnHeight*5.0/8.0;
        float TextHeight = toolItemBtnHeight*3.0/8.0;
        
        UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        videoBtn.frame = CGRectMake((kWIDTH/2.0 - toolItemWidth)/2.0, (tooView.frame.size.height - toolItemBtnHeight)/2.0, toolItemWidth, toolItemBtnHeight);
        videoBtn.backgroundColor = [UIColor clearColor];
        {
            UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, ImageWidth, videoBtn.frame.size.width, TextHeight)];
            label1.textAlignment = NSTextAlignmentCenter;
            label1.textColor = UIColorFromRGB(0x8d8c91);
            label1.text = RDLocalizedString(@"视频", nil);
            label1.font = [UIFont systemFontOfSize:12];
//            if ([UIScreen mainScreen].bounds.size.width >= 414) {
//                label1.font = [UIFont systemFontOfSize:11];
//            }else {
//                label1.font = [UIFont systemFontOfSize:10];
//            }
            [videoBtn addSubview:label1];
            
            UIImageView *thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((videoBtn.frame.size.width - ImageWidth)/2.0, 0, ImageWidth, ImageWidth)];
            thumbnailIV.image = [UIImage imageWithContentsOfFile:[self addLensViewItemsImagePath:1]];
            thumbnailIV.layer.cornerRadius = (ImageWidth)/2.0;
            thumbnailIV.layer.masksToBounds = YES;
            [videoBtn addSubview:thumbnailIV];
        }
        videoBtn.tag = 1;
        [videoBtn addTarget:self action:@selector(setCover:) forControlEvents:UIControlEventTouchUpInside];
        [tooView addSubview:videoBtn];
        
        UIButton *picBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        picBtn.frame =CGRectMake((kWIDTH/2.0 - toolItemWidth)/2.0 + kWIDTH/2.0, (tooView.frame.size.height - toolItemBtnHeight)/2.0, toolItemWidth, toolItemBtnHeight);
        {
            UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, ImageWidth, picBtn.frame.size.width, TextHeight)];
            label1.textAlignment = NSTextAlignmentCenter;
            label1.textColor = UIColorFromRGB(0x8d8c91);
            label1.text = RDLocalizedString(@"图片", nil);
            label1.font = [UIFont systemFontOfSize:12];
//            if ([UIScreen mainScreen].bounds.size.width >= 414) {
//                label1.font = [UIFont systemFontOfSize:11];
//            }else {
//                label1.font = [UIFont systemFontOfSize:10];
//            }
            [picBtn addSubview:label1];
            
            UIImageView *thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((videoBtn.frame.size.width - ImageWidth)/2.0, 0, ImageWidth, ImageWidth)];
            thumbnailIV.image = [UIImage imageWithContentsOfFile:[self addLensViewItemsImagePath:0]];
            thumbnailIV.layer.cornerRadius = (ImageWidth)/2.0;
            thumbnailIV.layer.masksToBounds = YES;
            [picBtn addSubview:thumbnailIV];
        }
        picBtn.tag = 2;
        [picBtn addTarget:self action:@selector(setCover:) forControlEvents:UIControlEventTouchUpInside];
        [tooView addSubview:picBtn];
    }
    return _coverView;
}

- (UIView *)bottomThumbnailView {
    if (!_bottomThumbnailView) {
        _bottomThumbnailView = [[UIView alloc] initWithFrame:bottomViewRect];
        _bottomThumbnailView.backgroundColor = TOOLBAR_COLOR;
        _bottomThumbnailView.hidden = YES;
        [self.view addSubview:_bottomThumbnailView];
        
        CGRect rect = CGRectMake(0, (_bottomThumbnailView.bounds.size.height - 45)/2.0, _bottomThumbnailView.bounds.size.width, 45);
        bottomTrimmerView = [[CaptionVideoTrimmerView alloc] initWithFrame:rect videoCore:_videoCoreSDK];
        bottomTrimmerView.backgroundColor = [UIColor clearColor];
        [bottomTrimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE))];
        [bottomTrimmerView setThemeColor:[UIColor lightGrayColor]];
        bottomTrimmerView.tag = 1;
        [bottomTrimmerView setDelegate:self];
        bottomTrimmerView.scrollView.decelerationRate = 0.8;
        bottomTrimmerView.piantouDuration = 0;
        bottomTrimmerView.pianweiDuration = 0;
        bottomTrimmerView.rightSpace = 20;
        
//        thumbTimes = [NSMutableArray array];
//        Float64 duration = _videoCoreSDK.duration;
//        NSInteger actualFramesNeeded = duration/2 + 1;
//        Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
//        for (int i = 0; i < actualFramesNeeded; i++){
//            CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
//            [thumbTimes addObject:[NSValue valueWithCMTime:time]];
//        }
        bottomTrimmerView.thumbTimes = thumbTimes.count;
        [bottomTrimmerView resetSubviews:nil];
        [_bottomThumbnailView addSubview:bottomTrimmerView];
        
        UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 3)/2.0, bottomTrimmerView.frame.origin.y-2, 3, 50)];
        spanView.backgroundColor = [UIColor whiteColor];
        spanView.layer.cornerRadius = 1.5;
        [_bottomThumbnailView addSubview:spanView];
        
        bottomCurrentTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 80)/2.0, bottomTrimmerView.frame.origin.y - 15 - 8, 80, 15)];
        bottomCurrentTimeLbl.textAlignment = NSTextAlignmentCenter;
        bottomCurrentTimeLbl.textColor = [UIColor whiteColor];
        bottomCurrentTimeLbl.text = @"0.00";
        bottomCurrentTimeLbl.font = [UIFont systemFontOfSize:12];
        [_bottomThumbnailView addSubview:bottomCurrentTimeLbl];
        
        UILabel *durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 80 - 14, bottomCurrentTimeLbl.frame.origin.y, 80, 15)];
        durationLbl.textAlignment = NSTextAlignmentRight;
        durationLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        durationLbl.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration];
        durationLbl.font = [UIFont systemFontOfSize:12];
        [_bottomThumbnailView addSubview:durationLbl];
    }
    return _bottomThumbnailView;
}

#pragma mark - 涂鸦
- (UIView *)doodleView {
    if (!_doodleView) {
        _doodleView = [[UIView alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height, kWIDTH, kHEIGHT - (_playerView.frame.origin.y + _playerView.bounds.size.height) - _toolbarTitleView.bounds.size.height)];
        _doodleView.backgroundColor = [UIColor clearColor];
        _doodleView.hidden = YES;
        [self.view addSubview:_doodleView];        
    }
    return _doodleView;
}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case RDAdvanceEditType_Subtitle:
        case RDAdvanceEditType_Sticker:
        case RDAdvanceEditType_Dewatermark:
        case RDAdvanceEditType_Collage:
        case RDAdvanceEditType_Doodle:
        case RDAdvanceEditType_Multi_track:
        case RDAdvanceEditType_Sound:
            if(buttonIndex == 1){
                self.isAddingMaterialEffect = NO;
                self.isEdittingMaterialEffect = NO;
                isModifiedMaterialEffect = NO;                
                [_addEffectsByTimeline discardEdit];
                [self back:nil];
            }
            break;
        case RDAdvanceEditType_Dubbing:
            if(buttonIndex == 1){
                [self back:nil];
            }
            break;
        case 100:
            if(buttonIndex == 1){
                [thumbImageVideoCore cancelImage];
                [thumbImageVideoCore stop];
                thumbImageVideoCore = nil;
                [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
                [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
                if(_cancelActionBlock){
                    _cancelActionBlock();
                }
                _cancelActionBlock = nil;
            }
            break;
            
        case 101:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [self cancelExportBlock];
                [_videoCoreSDK cancelExportMovie:nil];
            }
            break;
            
        case 103:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
        case RDAdvanceEditType_Effect: //退出特效
        {
            if(buttonIndex == 1){
                [self check];
                [self ReturnAdjustment:YES];
            }
        }
            break;
        case 102:
            if (buttonIndex == 1) {
                [RDHelpClass enterSystemSetting];
            }
            break;
        case 200:
           if(buttonIndex == 1){
                [RDHelpClass enterSystemSetting];
            }else{
                [self addMulti_track];
            }
            break;
        default:
            break;
    }
}

-(void)addMulti_track
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
//        [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
            _titleView.hidden = YES;
//        }];
        _functionalAreaView.hidden = YES;
        _toolBarView.hidden = YES;
        self.toolbarTitleView.hidden = NO;
        toolbarTitleLbl.hidden = NO;
        _playerToolBar.hidden = YES;
        isProprtionUI = true;
        
       isRecording = true;
       _playButton.hidden = YES;
       self.multi_trackView.hidden = NO;
       self.addEffectsByTimeline.hidden = NO;
       _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
       if (!_addEffectsByTimeline.superview) {
           [_multi_trackView addSubview:_addEffectsByTimeline];
           _addEffectsByTimeline.currentEffect = selecteFunction;
       }else {
           _addEffectsByTimeline.currentEffect = selecteFunction;
           [_addEffectsByTimeline removeFromSuperview];
           [_multi_trackView addSubview:_addEffectsByTimeline];
       }
       _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:VideoCurrentTime*_videoCoreSDK.duration];
       [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
    });
}

#pragma mark-
- (void)initThumbImageVideoCore{
    if(!thumbImageVideoCore){
        int fps = kEXPORTFPS;
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
            fps = 15;//20180720 与json文件中一致
        }
        thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:_exportVideoSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];
        thumbImageVideoCore.delegate = self;
    }
    thumbImageVideoCore.customFilterArray = nil;
    [self refreshRdPlayer:thumbImageVideoCore];
}

/**初始化播放器
 */
- (void)initPlayer {
    [_videoCoreSDK stop];//20181105 fix bug:不断切换mv、配乐会因内存问题崩溃
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    if (!_videoCoreSDK) {
        int fps = kEXPORTFPS;
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMVEffect){
            fps = 15;//20180720 与json文件中一致
        }
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_exportVideoSize
                                                     fps:fps
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
#if ENABLEAUDIOEFFECT
        _videoCoreSDK.enableAudioEffect = YES;
#else
        _videoCoreSDK.enableAudioEffect = (selectedSoundEffectIndex != 0);
#endif
    }
     _videoCoreSDK.delegate = self;
    [scenes removeAllObjects];
    scenes = nil;
    [self performSelector:@selector(refreshRdPlayer:) withObject:_videoCoreSDK afterDelay:0.1];
}

- (void)refreshRdPlayer:(RDVECore *)rdPlayer {
    NSMutableArray *sceneArray = [NSMutableArray array];
    RDScene *sceneMultiMabia = [[RDScene alloc] init];
    for (int i = 0; i< _fileList.count; i++) {
        RDFile *file = _fileList[i];
        RDScene *scene;
        if (!_isMultiMedia)
            scene = [[RDScene alloc] init];
        
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        if (globalFilters.count > 0 && file.filterIndex < globalFilters.count) {
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
        if (selectedSoundEffectIndex == -1) {
            vvasset.audioFilterType = RDAudioFilterTypeCustom;
            vvasset.pitch = oldPitch;
        }
        else if (selectedSoundEffectIndex <= RDAudioFilterTypeCartoon) {
            vvasset.audioFilterType = (RDAudioFilterType)selectedSoundEffectIndex;
        }else {
            vvasset.audioFilterType = (RDAudioFilterType)(selectedSoundEffectIndex + 1);
        }
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
        
        vvasset.identifier = [NSString stringWithFormat:@"video%d", i];
        
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
            }
            else{
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
                    if(CMTimeRangeEqual(kCMTimeRangeZero, vvasset.timeRange)){
                        vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:file.contentURL].duration);
                    }
                }else{
                    vvasset.timeRange = file.videoTimeRange;
                }
                if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                    vvasset.timeRange = file.videoTrimTimeRange;
                }
            }
            vvasset.speed        = file.speed;
            vvasset.volume = file.videoVolume;
            vvasset.audioFadeInDuration = file.audioFadeInDuration;
            vvasset.audioFadeOutDuration = file.audioFadeOutDuration;
            if(!yuanyinOn){
                vvasset.volume = 0;
            }
            if (_isMultiMedia) {
                vvasset.videoFillType = RDVideoFillTypeFull;
            }
        }else{
            vvasset.type         = RDAssetTypeImage;
            if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                vvasset.timeRange = file.imageTimeRange;
            }else {
                vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            }
            vvasset.speed        = file.speed;
            vvasset.volume       = file.videoVolume;
            
            if(!isEnlarge)
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
        float exportRatio = _exportVideoSize.width/_exportVideoSize.height;
        float assetRatio = (trsize.width * file.crop.size.width)/(trsize.height * file.crop.size.height);
        if(file.fileType != kTEXTTITLE && !_isMultiMedia &&
           (assetRatio < exportRatio) && (isVague))
        {
            vvasset.blurIntensity = 1.0;
        }else{
            vvasset.isBlurredBorder = NO;
        }
        if( !_isMultiMedia && (i != _fileList.count - 1) && ( ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition ) ){
            [RDHelpClass setTransition:scene.transition file:file];
        }
        
        if( _isMultiMedia && (i == _fileList.count - 1) )
        {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource: @"RDVEUISDK" ofType :@"bundle"];
            NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
            NSString *imagePath;
            imagePath =  [[resourceBundle resourcePath] stringByAppendingPathComponent:@"异形编辑_多媒体.png"];
            vvasset.maskURL = [NSURL fileURLWithPath:imagePath];
        }
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.crop = file.crop;
        
        if(selectMVEffects && _mvDataPointArray.count>0){
            __block float mskDuration = 0;
            [selectMVEffects enumerateObjectsUsingBlock:^(VVMovieEffect * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.type == RDVideoMVEffectTypeMask){
                    mskDuration = CMTimeGetSeconds([AVURLAsset assetWithURL:obj.url].duration);
                }
            }];
            //添加左边文件读取判断
            NSArray *jsonArray = _mvDataPointArray[0];
            if (jsonArray.count != 0) {
                NSMutableArray *pointsArray = [NSMutableArray array];
                for (NSDictionary *dic in jsonArray) {
                    if ([dic[@"d"] boolValue] == true) {
                        NSArray *arr = dic[@"c"];
                        [pointsArray addObject:arr];
                    }
                }
                    if (mvEffectFps == 0) {
                    mvEffectFps = kEXPORTFPS;
                }
                if (lastThemeMVIndex >= 3) {
                    if (vvasset.type == RDAssetTypeImage) {
                        vvasset.fillType = RDImageFillTypeFull;
                        if (selectMVEffects.count > 0) {
                            VVMovieEffect *mvEffect = [selectMVEffects firstObject];
                            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, mvEffect.timeRange.duration);
                        }
                    }
                    NSMutableArray *animateArray = [NSMutableArray array];
                    for (int j = 0; j < pointsArray.count; j++) {
                        VVAssetAnimatePosition *animate = [[VVAssetAnimatePosition alloc] init];
                        animate.atTime = j/mvEffectFps;
                        if (animate.atTime > CMTimeGetSeconds(vvasset.timeRange.duration)) {
                            break;
                        }
                        [animate setPointsLeftTop:CGPointMake([pointsArray[j][0] floatValue]/_exportVideoSize.width, [pointsArray[j][1] floatValue]/_exportVideoSize.height) rightTop:CGPointMake([pointsArray[j][2] floatValue]/_exportVideoSize.width, [pointsArray[j][3] floatValue]/_exportVideoSize.height) rightBottom:CGPointMake([pointsArray[j][6] floatValue]/_exportVideoSize.width, [pointsArray[j][7] floatValue]/_exportVideoSize.height) leftBottom:CGPointMake([pointsArray[j][4] floatValue]/_exportVideoSize.width, [pointsArray[j][5] floatValue]/_exportVideoSize.height)];
                        [animateArray addObject:animate];
                    }
                    NSInteger j = pointsArray.count - 1;
                    VVAssetAnimatePosition *animate = [[VVAssetAnimatePosition alloc] init];
                    animate.atTime = pointsArray.count/mvEffectFps;
                    [animate setPointsLeftTop:CGPointMake([pointsArray[j][0] floatValue]/_exportVideoSize.width, [pointsArray[j][1] floatValue]/_exportVideoSize.height) rightTop:CGPointMake([pointsArray[j][2] floatValue]/_exportVideoSize.width, [pointsArray[j][3] floatValue]/_exportVideoSize.height) rightBottom:CGPointMake([pointsArray[j][6] floatValue]/_exportVideoSize.width, [pointsArray[j][7] floatValue]/_exportVideoSize.height) leftBottom:CGPointMake([pointsArray[j][4] floatValue]/_exportVideoSize.width, [pointsArray[j][5] floatValue]/_exportVideoSize.height)];
                    [animateArray addObject:animate];
                    
                    vvasset.animate = animateArray;
                    if (CMTimeGetSeconds(vvasset.timeRange.duration) > animate.atTime) {
                        vvasset.timeRange = CMTimeRangeMake(vvasset.timeRange.start, CMTimeMakeWithSeconds(animate.atTime, TIMESCALE));
                    }
                    if(vvasset.type == RDAssetTypeImage && !isEnlarge){
                        vvasset.fillType = RDImageFillTypeFit;
                    }
                }else if (lastThemeMVIndex == 1 && pointsArray.count > 0) {
                    [vvasset setPointsInVideoLeftTop:CGPointMake([pointsArray[0][0] floatValue]/_exportVideoSize.width, [pointsArray[0][1] floatValue]/_exportVideoSize.height) rightTop:CGPointMake([pointsArray[0][2] floatValue]/_exportVideoSize.width, [pointsArray[0][3] floatValue]/_exportVideoSize.height) rightBottom:CGPointMake([pointsArray[0][6] floatValue]/_exportVideoSize.width, [pointsArray[0][7] floatValue]/_exportVideoSize.height) leftBottom:CGPointMake([pointsArray[0][4] floatValue]/_exportVideoSize.width, [pointsArray[0][5] floatValue]/_exportVideoSize.height)];
                }
            }
        }
        if (!_isMultiMedia)
        {
            if( file.backgroundType !=  KCanvasType_None )
            {
                vvasset.rectInVideo = file.rectInScene;
                if( file.backgroundType != KCanvasType_Color )
                    scene.backgroundAsset = [RDHelpClass canvasFile:file.BackgroundFile];
                else
                    scene.backgroundColor = file.backgroundColor;
                
                vvasset.rotate = file.rotate + file.BackgroundRotate;
            }
            
            if( file.animationDuration > 0 )
            {
                [RDHelpClass setAssetAnimationArray:vvasset name:file.animationName duration:file.animationDuration center:
                 CGPointMake(file.rectInScene.origin.x + file.rectInScene.size.width/2.0, file.rectInScene.origin.y + file.rectInScene.size.height/2.0) scale:file.rectInScale];
            }
            
            [scene.vvAsset addObject:vvasset];
        }
        else
            [sceneMultiMabia.vvAsset addObject:vvasset];
        
        if(selectMVEffectBack){
            CMTimeRange range = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds([selectMVEffectBack[@"duration"] doubleValue], 600));
            VVAsset* backvasset = [[VVAsset alloc] init];
            NSString *filepath = [[[kThemeMVPath stringByAppendingPathComponent:@"MVEffects"] stringByAppendingPathComponent:selectMVEffectBack[@"file"]] stringByAppendingPathComponent:selectMVEffectBack[@"path"]];
            
            backvasset.url = [NSURL fileURLWithPath:filepath];
            backvasset.type = RDAssetTypeVideo;
            backvasset.timeRange = range;
            backvasset.blurIntensity = 0.5;
            
            //调色
            backvasset.brightness = file.brightness;
            backvasset.contrast = file.contrast;
            backvasset.saturation = file.saturation;
            backvasset.sharpness = file.sharpness;
            backvasset.whiteBalance = file.whiteBalance;
            backvasset.vignette = file.vignette;
            
            if (!_isMultiMedia)
            {
                if( file.backgroundType !=  KCanvasType_None )
                {
                    vvasset.rectInVideo = file.rectInScene;
                    if( file.backgroundType != KCanvasType_Color )
                        scene.backgroundAsset = [RDHelpClass canvasFile:file.BackgroundFile];
                    else
                        scene.backgroundColor = file.backgroundColor;
                    
                    backvasset.rotate = file.rotate +  file.BackgroundRotate;
                }
                
                if( file.animationDuration > 0 )
                {
                    [RDHelpClass setAssetAnimationArray:backvasset name:file.animationName duration:file.animationDuration center:
                     CGPointMake(file.rectInScene.origin.x + file.rectInScene.size.width/2.0, file.rectInScene.origin.y + file.rectInScene.size.height/2.0) scale:file.rectInScale];
                }
                
                [scene.vvAsset addObject:backvasset];
            }
            else
                [sceneMultiMabia.vvAsset addObject:backvasset];
        }
        if(!_isMultiMedia)
        {
            if(filterFxArray.count > 0 && file.customFilterId != 0 )
            {
                RDCustomFilter *customFilteShear = [RDGenSpecialEffect getCustomFilerWithFxId:file.customFilterId filterFxArray:filterFxArray timeRange:CMTimeRangeMake(kCMTimeZero,vvasset.timeRange.duration)];
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    asset.customFilter = customFilteShear;
                }];
            }
            
            if( (oldTimeEffectType == kTimeFilterTyp_None ) && ( file.fileTimeFilterType !=  kTimeFilterTyp_None ) )
            {
                [RDGenSpecialEffect refreshVideoTimeEffectType:sceneArray atFile:file atscene:scene atTimeRange:file.fileTimeFilterTimeRange atIsRemove:NO];
            }
            else
                [sceneArray addObject:scene];
        }
    }
    
    if (_isMultiMedia)
        [sceneArray addObject:sceneMultiMabia];
    if (rdPlayer == _videoCoreSDK && !scenes) {
        scenes = sceneArray;
    }
    if (globalFilters.count > 0) {
        [rdPlayer addGlobalFilters:globalFilters];
    }
    [rdPlayer setEditorVideoSize:_exportVideoSize];
    [rdPlayer setScenes:sceneArray];
    
    if (!_videoCoreSDK.view.superview) {
        _videoCoreSDK.frame = self.playerView.bounds;
        [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
    }
    NSMutableArray *array = [NSMutableArray arrayWithArray:collages];
    [array addObjectsFromArray:doodles];
    if( _watermarkCollage )
        [array addObject:_watermarkCollage.collage];
    
//    if( _addEffectsByTimeline.currentCollage )
//       [array addObject:_addEffectsByTimeline.currentCollage];
    rdPlayer.watermarkArray = array;
    
    [self refresMusic];
    
    [rdPlayer addMVEffect:[selectMVEffects mutableCopy]];
    [rdPlayer setDubbingMusics:dubbingArr];
    if(oldTimeEffectType != kTimeFilterTyp_None && _fileList.count == 1) {
        [RDGenSpecialEffect refreshVideoTimeEffectType:oldTimeEffectType timeEffectTimeRange:oldEffectTimeRange atscenes:scenes atFile:_fileList[0]];
    }
    rdPlayer.customFilterArray = customFilterArray;
    [rdPlayer build];
    
    [rdPlayer setGlobalFilter:selectFilterIndex];
    //滤镜强度
    [rdPlayer setGlobalFilterIntensity:filterStrength];
    if(_mvView != nil && !_mvView.hidden ){
        [rdPlayer setShouldRepeat:YES];
    }else{
        [rdPlayer setShouldRepeat:NO];
    }
    self.durationLabel.text = [RDHelpClass timeToStringFormat:rdPlayer.duration];
    self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    
    [self refreshCustomTextTimeRange];
}

- (void)refreshSound {
    [_videoCoreSDK stop];//20181105 fix bug:不断切换mv、配乐会因内存问题崩溃
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    [self performSelector:@selector(refreshMusicOrDubbing) withObject:nil afterDelay:0.1];
}

- (void)refresMusic
{
    NSMutableArray *musicSDK = [NSMutableArray new];
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.identifier = @"music";
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.isFadeInOut = YES;
        music.volume = _musicVolume;
        if (mvMusicArray) {
            [musicSDK addObject:music];
            [mvMusicArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [musicSDK addObject:obj];
            }];
        }else{
            [musicSDK addObject:music];
        }
    }
    {
        [musics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [musicSDK addObject:obj];
        }];
        [soundMusics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [musicSDK addObject:obj];
        }];
    }
    [_videoCoreSDK setMusics:musicSDK];
}

- (void)refreshMusicOrDubbing {
    [self refresMusic];
    [_videoCoreSDK setDubbingMusics:dubbingArr];
    [_videoCoreSDK build];
}

- (void)refreshCaptions {
    NSMutableArray *arry = [[NSMutableArray alloc] initWithArray:subtitles];
    [arry addObjectsFromArray:stickers];
    _videoCoreSDK.captions = arry;
}

- (void)refreshDewatermark {
    _videoCoreSDK.blurs = blurs;
    _videoCoreSDK.mosaics = mosaics;
    _videoCoreSDK.dewatermarks = dewatermarks;    
}

//MARK:功能选择
- (void)clickDubbingItemBtn:(UIButton *)sender{
    if(_videoCoreSDK.isPlaying){
        [self playVideo:NO];
    }
    
    _dubbingView.hidden = NO;
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        __weak typeof(self) weakSelf = self;
        [avSession requestRecordPermission:^(BOOL available) {
            dispatch_async(dispatch_get_main_queue(), ^{
                StrongSelf(self);
                if (available) {
                    
                    strongSelf->selecteFunction = RDAdvanceEditType_Dubbing;
                    strongSelf->_playButton.hidden = YES;
                    strongSelf->_soundEffectView.hidden = YES;
                    
                    [strongSelf performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.25];
                }
                else
                {
                    [strongSelf initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问麦克风!",nil)
                                               message:RDLocalizedString(@"请在“设置-隐私-麦克风”中开启",nil)
                                     cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                     otherButtonTitles:RDLocalizedString(@"取消",nil)
                                          alertViewTag:102];
                }
            });
        }];
    }
}
/**功能选择
 */
- (void)clickToolItemBtn:(UIButton *)sender{
    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    
    if (sender.tag == RDAdvanceEditType_Subtitle
        || sender.tag == RDAdvanceEditType_Sticker
        || sender.tag == RDAdvanceEditType_Filter)
    {
        RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
        if([lexiu currentReachabilityStatus] == RDNotReachable){
            [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
            return;
        }
    }
    [_videoCoreSDK setShouldRepeat:NO];
    if (isNewUI) {
        if( ( sender.tag != RDAdvanceEditType_FragmentEdit )
           && ( sender.tag != RDAdvanceEditType_SoundSettings )
           && ( sender.tag != RDAdvanceEditType_Setting )
           )
        {
//            [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
                _titleView.hidden = YES;
//            }];
            _functionalAreaView.hidden = YES;
            _toolBarView.hidden = YES;
            self.toolbarTitleView.hidden = NO;
            toolbarTitleLbl.hidden = NO;
            toolbarTitleLbl.text = sender.currentTitle;
            _playerToolBar.hidden = YES;
            isProprtionUI = true;
        }
        
        selecteFunction = sender.tag;
        
        
    }
    VideoCurrentTime = CMTimeGetSeconds(_videoCoreSDK.currentTime)/_videoCoreSDK.duration;
    switch (sender.tag) {
        case RDAdvanceEditType_MV://MARK:进入MV
        {
            if (!isNewUI) {
                titleLabel.text = sender.currentTitle;
            }
            [_videoCoreSDK setShouldRepeat:YES];
            
            self.mvView.hidden = NO;
            _musicView.hidden = YES;
            _filterView.hidden = YES;
            
            [RDHelpClass animateView:self.mvView atUP:NO];
        }
            break;
        case RDAdvanceEditType_Music://MARK:进入配乐
        {
            if (!isNewUI) {
                titleLabel.text = sender.currentTitle;
            }
            _mvView.hidden = YES;
            self.musicView.hidden = NO;
            _filterView.hidden = YES;
            [RDHelpClass animateView:self.musicView atUP:NO];
        }
            break;
        case RDAdvanceEditType_Dubbing://MARK:进入配音
        {
            selecteFunction = sender.tag;
            self.dubbingView.hidden = NO;
            [self clickDubbingItemBtn:nil];
            [RDHelpClass animateView:self.dubbingView atUP:NO];
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
        }
            break;
        case RDAdvanceEditType_Subtitle://MARK:进入 字幕
        {
            isRecording = true;
            _playButton.hidden = YES;
            self.subtitleView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            _addEffectsByTimeline.fileList = _fileList;
            if (!_addEffectsByTimeline.superview) {
                [_subtitleView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_subtitleView addSubview:_addEffectsByTimeline];
            }
            _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:VideoCurrentTime*_videoCoreSDK.duration];
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.subtitleConfigView atUP:NO];
            if( (subtitles != nil) && ( subtitles.count > 1 ) )
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
        }
            break;
        case RDAdvanceEditType_Filter://MARK:进入滤镜
        {
            if (!isNewUI) {
                titleLabel.text = sender.currentTitle;
            }
            oldFilterType = selectFilterIndex;
            self.filterView.hidden = NO;
            _mvView.hidden = YES;
            _musicView.hidden = YES;
            [RDHelpClass animateView:self.filterView atUP:NO];
        }
            break;
        case RDAdvanceEditType_Sticker://MARK:进入贴纸
        {
            isRecording = true;
            _playButton.hidden = YES;
            self.stickerView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:VideoCurrentTime*_videoCoreSDK.duration];
            if (!_addEffectsByTimeline.superview) {
                [_stickerView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_stickerView addSubview:_addEffectsByTimeline];
            }
            
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.stickerConfigView atUP:NO];
            if( (stickers != nil) && ( stickers.count > 1 ) )
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
            else
            {
                self.toolbarTitleView.hidden = YES;
            }
        }
            break;
        case RDAdvanceEditType_Effect://MARK:进入特效
        {
//            NSMutableArray *typeArray = [filterFxArray mutableCopy];
//            if (!typeArray) {
//                typeArray = [NSMutableArray array];
//            }
//            if(_fileList.count == 1 && _fileList[0].fileType == kFILEVIDEO) {
//                NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"时间", nil),@"typeName", nil];
//                [typeArray addObject:dic];
//            }
            
            isRecording = true;
            _playButton.hidden = YES;
            self.FXView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:VideoCurrentTime*_videoCoreSDK.duration];
            if (!_addEffectsByTimeline.superview) {
                [FXView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [FXView addSubview:_addEffectsByTimeline];
            }
            
            if( _addEffectsByTimeline.filterFxArray )
            {
                [_addEffectsByTimeline.filterFxArray removeAllObjects];
                _addEffectsByTimeline.filterFxArray = nil;
            }
//            _addEffectsByTimeline.filterFxArray = typeArray;
            
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.stickerConfigView atUP:NO];
            if( (customFilterArray != nil) && ( customFilterArray.count > 1 ) )
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
        }
            break;
        case RDAdvanceEditType_SoundEffect://MARK:变声
        {
            self.soundEffectView.hidden = NO;
            [RDHelpClass animateView:self.soundEffectView atUP:NO];
        }
            break;
        case RDAdvanceEditType_Watermark://MARK: 加水印
        {
            self.toolbarTitleView.hidden = YES;
            if( _watermarkCollage )
            {
                [self initPasterViewwithFIle:_watermarkCollage.thumbnailImage];
                self.watermarkView.hidden = NO;
                
                if( _draft )
                {
                    [_watermarkSizeSlider setValue:_draft.watermarkSizeVolume];
                    [_watermarkRotateSlider setValue:_draft.watermarkRotatevolume ];
                    float alpha = _draft.watermarkAlhpavolume;
                    [_watermarkAlhpaSlider setValue:alpha];
                }
            }
            else
                [self watermark_replace:YES];
        }
            break;
        case RDAdvanceEditType_Mosaic://MARK: 马赛克
        {
            toolbarTitleLbl.text = RDLocalizedString(@"去水印", nil);
            
            selecteFunction = RDAdvanceEditType_Dewatermark;
            
            isRecording = true;
            _playButton.hidden = YES;
            toolbarTitleLbl.text = sender.currentTitle;
            self.dewatermarkView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            _addEffectsByTimeline.dewatermarkTypeView.hidden = YES;
            if (!_addEffectsByTimeline.superview) {
                [_dewatermarkView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_dewatermarkView addSubview:_addEffectsByTimeline];
            }
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.dewatermarkTypeView atUP:NO];
            if( ((dewatermarks != nil) && ( dewatermarks.count > 1 ))
               || ( (mosaics != nil) && ( mosaics.count > 1 ) ))
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
            self.addEffectsByTimeline.isMosaic = true;
            return;
        }
            break;
        case RDAdvanceEditType_Dewatermark://MARK:去水印
        {
            isRecording = true;
            _playButton.hidden = YES;
            toolbarTitleLbl.text = sender.currentTitle;
            self.dewatermarkView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            _addEffectsByTimeline.dewatermarkTypeView.hidden = YES;
            if (!_addEffectsByTimeline.superview) {
                [_dewatermarkView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_dewatermarkView addSubview:_addEffectsByTimeline];
            }
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.dewatermarkTypeView atUP:NO];
            if( ((dewatermarks != nil) && ( dewatermarks.count > 1 ))
               || ( (mosaics != nil) && ( mosaics.count > 1 ) ))
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
            self.addEffectsByTimeline.isMosaic = false;
        }
            break;
        case RDAdvanceEditType_Proportion://MARK:比例
        {
            self.proportionView.hidden = NO;
            oldProportionIndex = selectProportionIndex;
            [RDHelpClass animateView:self.proportionView atUP:NO];
        }
            break;
        case RDAdvanceEditType_PicZoom://MARK:图片运动
        {
            self.contentMagnificationView.hidden = NO;
            [RDHelpClass animateView:self.contentMagnificationView atUP:NO];
        }
            break;
        case RDAdvanceEditType_BG://MARK:画布
        {
            _canvas_CurrentFileIndex = [self passThroughIndexAtCurrentTime:_videoCoreSDK.currentTime];
            _CurrentCanvasType = _fileList[_canvas_CurrentFileIndex].backgroundType;
            [self playVideo:NO];
            _playButton.hidden = YES;
            self.canvasView.hidden = NO;
            [RDHelpClass animateView:self.canvasView atUP:NO];
        }
            break;
        case RDAdvanceEditType_Sort://MARK:排序
        {
            [self enter_Sort];
        }
            break;
        case RDAdvanceEditType_Collage://MARK:画中画
        {
            isRecording = true;
            _playButton.hidden = YES;
            self.collageView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            cancelBtn.hidden = NO;
            _toolbarTitlefinishBtn.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            if (!_addEffectsByTimeline.superview) {
                [_collageView addSubview:_addEffectsByTimeline];
                if (_addEffectsByTimeline.currentEffect != selecteFunction) {
                    _addEffectsByTimeline.currentEffect = selecteFunction;
                }
            }else {
                if (_addEffectsByTimeline.currentEffect != selecteFunction) {
                    _addEffectsByTimeline.currentEffect = selecteFunction;
                }
                [_addEffectsByTimeline removeFromSuperview];
                [_collageView addSubview:_addEffectsByTimeline];
            }
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.albumView  atUP:NO];
            if( (collages != nil) && ( collages.count > 1 ) )
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
        }
            break;
        case RDAdvanceEditType_Doodle://MARK:涂鸦
        {
            isRecording = true;
            _playButton.hidden = YES;
            self.doodleView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            cancelBtn.hidden = NO;
            _toolbarTitlefinishBtn.hidden = NO;
            _addEffectsByTimeline.doodleConfigView.hidden = YES;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:VideoCurrentTime*_videoCoreSDK.duration];
            if (!_addEffectsByTimeline.superview) {
                [_doodleView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_doodleView addSubview:_addEffectsByTimeline];
            }
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            [RDHelpClass animateView:_addEffectsByTimeline.doodleConfigView  atUP:NO];
            if( (doodles != nil) && ( doodles.count > 1 ) )
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
        }
            break;
        case RDAdvanceEditType_Cover://MARK:封面
        {
            [self performSelector:@selector(initCover) withObject:nil afterDelay:0.05];
//            [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
                _titleView.hidden = YES;
//            }];
            _playButton.hidden = YES;
            self.coverView.hidden = NO;
            self.toolbarTitleView.hidden = NO;
            cancelBtn.hidden = NO;
            _toolbarTitlefinishBtn.hidden = NO;
            [self.view bringSubviewToFront:self.bottomThumbnailView];
            if (coverFile && CMTimeCompare(coverFile.coverTime, kCMTimeInvalid) == 0) {
                coverAuxView.hidden = YES;
            }else {
                coverAuxView.hidden = NO;
                [_videoCoreSDK seekToTime:coverFile.coverTime];
            }
            [RDHelpClass animateView:self.coverView  atUP:NO];
        }
            break;
        case RDAdvanceEditType_Sound://MARK:音效
        {
            isRecording = true;
            _playButton.hidden = YES;
            self.soundView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            if (!_addEffectsByTimeline.superview) {
                [_soundView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_soundView addSubview:_addEffectsByTimeline];
            }
            _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:VideoCurrentTime*_videoCoreSDK.duration];
            [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.01];
            if( (soundMusics != nil) && ( soundMusics.count > 1 ) )
            {
                self.addEffectsByTimeline.hidden = NO;
                [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
            }
        }
            break;
        case RDAdvanceEditType_Multi_track://MARK:多段配乐
        {
            
//            _titleView.hidden = NO;
            
            [RDHelpClass animateView:_titleView atUP:YES];
            _functionalAreaView.hidden = NO;
            _toolBarView.hidden = NO;
            self.toolbarTitleView.hidden = YES;
            toolbarTitleLbl.hidden = YES;
            _playerToolBar.hidden = NO;
            isProprtionUI = false;
            
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            if (!_addEffectsByTimeline.superview) {
                [_soundView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_soundView addSubview:_addEffectsByTimeline];
            }
            
            if ( MPMediaLibrary.authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized)
            {
                //打开了用户访问权限
                [self addMulti_track];
                if( (musics != nil) && ( musics.count > 1 ) )
                {
                    self.addEffectsByTimeline.hidden = NO;
                    [RDHelpClass animateView:_addEffectsByTimeline atUP:NO];
                }
            }
            else
            {
                //没有权限提示用户是否允许访问
                [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus authorizationStatus)
                 {
                     if ( authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized )
                     {
                         NSLog(@"允许访问");
                         [self addMulti_track];
                     }
                     else
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             NSLog(@"禁止访问音乐库");
                             [self initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问媒体资料库",nil)
                                                        message:RDLocalizedString(@"请更改设置，启用媒体资料库权限",nil)
                                              cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                              otherButtonTitles:RDLocalizedString(@"设置",nil)
                                                   alertViewTag:200];
                         });
                     }
                 }];
            }
        }
            break;
        case RDAdvanceEditType_Volume://MARK: 音量
            self.volumeView.hidden = NO;
            if( scenes.count > 0 )
            {
                RDScene* scene = [_videoCoreSDK getScenes][0];
                [_originalVolumeSlider setValue:scene.vvAsset[0].volume/volumeMultipleM ];
            }
            else
            {
                [_originalVolumeSlider setValue: oldVolume/volumeMultipleM  ];
            }
            [RDHelpClass animateView:self.volumeView  atUP:NO];
            break;
        case RDAdvanceEditType_Setting://MARK: 设置
        {
            [self initSettingOrSoundSettings:RDAdvanceEditType_Setting];
            return;
        }
            break;
        case RDAdvanceEditType_SoundSettings://MARK: 声音
        {
            [self initSettingOrSoundSettings:RDAdvanceEditType_SoundSettings];
            return;
        }
            break;
        case RDAdvanceEditType_FragmentEdit://MARK: 片段编辑
        {
            [self FragmentEdit];
            return;
        }
            break;
        default:
            break;
    }
    
    if( RDAdvanceEditType_FragmentEdit != sender.tag )
        [RDHelpClass animateView:_toolbarTitleView  atUP:NO];
    
    _addEffectsByTimeline.hidden = YES;
    
    [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == sender.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

-(void)initSettingOrSoundSettings:(RDAdvanceEditType) type
{
    EditConfiguration *editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    NSMutableArray  *toolItem = [NSMutableArray new];
    [_otherScrollView removeFromSuperview];
    _otherScrollView = nil;
//    _toolBarView.hidden = YES;
    switch (type) {
         case RDAdvanceEditType_Setting:
               {
//                   //比例
//                   if(editConfiguration.enableProportion){
//                       NSDictionary *dic11 = [[NSDictionary alloc] initWithObjectsAndKeys:@"比例",@"title",@(RDAdvanceEditType_Proportion),@"id", nil];
//                       [toolItem addObject:dic11];
//                   }
                   //图片运动
                   if(editConfiguration.enablePicZoom){
                       NSDictionary *dic12 = [[NSDictionary alloc] initWithObjectsAndKeys:@"图片运动",@"title",@(RDAdvanceEditType_PicZoom),@"id", nil];
                       [toolItem addObject:dic12];
                   }
                   //背景
//                   if(editConfiguration.enableBackgroundEdit){
//                       NSDictionary *dic13 = [[NSDictionary alloc] initWithObjectsAndKeys:@"背景",@"title",@(RDAdvanceEditType_BG),@"id", nil];
//                       [toolItem addObject:dic13];
//                   }
//                   //封面
//                   if(editConfiguration.enableCover){
//                       NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:@"封面", @"title",@(RDAdvanceEditType_Cover),@"id", nil];
//                       [toolItem addObject:dic];
//                   }
               }
                   break;
               case RDAdvanceEditType_SoundSettings:
               {
                   //音量
                   if(editConfiguration.enableMusic){
                       NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"音量",@"title",@(RDAdvanceEditType_Volume),@"id", nil];
                       [toolItem addObject:dic1];
                       NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"配乐",@"title",@(RDAdvanceEditType_Music),@"id", nil];
                       [toolItem addObject:dic2];
                       if(editConfiguration.soundMusicTypeResourceURL){
                           NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"音效",@"title",@(RDAdvanceEditType_Sound),@"id", nil];
                           [toolItem addObject:dic3];
                       }
                       NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"多段配乐",@"title",@(RDAdvanceEditType_Multi_track),@"id", nil];
                       [toolItem addObject:dic4];
                   }
                   //配音
                   if(editConfiguration.enableDubbing && editConfiguration.dubbingType != 1){
                       NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"配音",@"title",@(RDAdvanceEditType_Dubbing),@"id", nil];
                       [toolItem addObject:dic3];
                   }
                   //变声
                   if(editConfiguration.enableSoundEffect){
                       NSDictionary *dic9 = [[NSDictionary alloc] initWithObjectsAndKeys:@"变声",@"title",@(RDAdvanceEditType_SoundEffect),@"id", nil];
                       [toolItem addObject:dic9];
                   }
               }
                   break;
        default:
            break;
    }
    
    self.otherView.hidden = NO;

    int count = 7;
    if( toolItem.count > 7 )
    {
        count = toolItem.count;
    }
    
    __block float toolItemBtnWidth = MAX(_otherView.frame.size.width/count, 60 + 5);//_toolBarView.frame.size.height
    __block float contentsWidth = 0;
    [toolItem enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *title = [toolItem[idx] objectForKey:@"title"];
        
        float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString(title, nil) andHeight:12 fontSize:12] + 15;
        
        if( ItemBtnWidth < toolItemBtnWidth )
            ItemBtnWidth = toolItemBtnWidth;
        
        UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolItemBtn.tag = [[toolItem[idx] objectForKey:@"id"] integerValue];
        toolItemBtn.backgroundColor = [UIColor clearColor];
        toolItemBtn.exclusiveTouch = YES;
        toolItemBtn.frame = CGRectMake(contentsWidth, 0, ItemBtnWidth, _otherScrollView.frame.size.height);
        [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@默认_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@选中_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (ItemBtnWidth - 44)/2.0, 16, (ItemBtnWidth - 44)/2.0)];
        [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
        [_otherScrollView addSubview:toolItemBtn];
        contentsWidth += ItemBtnWidth;
    }];
    if( contentsWidth <= _otherView.frame.size.width )
        contentsWidth = _otherView.frame.size.width + 10;
    _otherScrollView.contentSize = CGSizeMake(contentsWidth, 0);
}

#pragma mark- 其他功能界面
-(UIView *) otherView
{
    if( !_otherView )
    {
        _otherView = [[UIView alloc] initWithFrame:CGRectMake(0, _functionalAreaView.bounds.size.height - 60 - (iPhone_X ? 34 : 0), kWIDTH, 60+(iPhone_X ? 34 : 0))];
        _otherView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        
        _otherReturnBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 3, 60/2.0, _otherView.frame.size.height - (iPhone_X ? 34 : 0) - 6 )];
        _otherReturnBtn.layer.cornerRadius = 3;
        _otherReturnBtn.layer.masksToBounds = YES;
        
        [_otherReturnBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_otherReturnBtn addTarget:self action:@selector(otherReturn_Btn) forControlEvents:UIControlEventTouchUpInside];
        _otherReturnBtn.backgroundColor = TOOLBAR_COLOR;
        [_otherView addSubview:_otherReturnBtn];
        [_functionalAreaView addSubview:_otherView];
    }
    
    _otherScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(_otherReturnBtn.frame.size.width + _otherReturnBtn.frame.origin.x,  0,_otherView.bounds.size.width - _otherReturnBtn.frame.size.width - _otherReturnBtn.frame.origin.x, _otherView.frame.size.height - (iPhone_X ? 34 : 0) )];
    _otherScrollView.showsVerticalScrollIndicator = NO;
    _otherScrollView.showsHorizontalScrollIndicator = NO;
    
    [_otherView addSubview:_otherScrollView];
    
    return _otherView;
}
-( void )otherReturn_Btn
{
    _otherView.hidden = YES;
//    _toolBarView.hidden = NO;
}

/**点击返回按键*/
- (void)back:(UIButton *)sender{
    sender.selected = YES;
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    //MARK:配音
    if(selecteFunction == RDAdvanceEditType_Dubbing){
        if (isModifiedMaterialEffect) {
            [self initCommonAlertViewWithTitle:RDLocalizedString(@"确定放弃所有操作?",nil)
                                       message:@""
                             cancelButtonTitle:RDLocalizedString(@"取消",nil)
                             otherButtonTitles:RDLocalizedString(@"确定",nil)
                                  alertViewTag:selecteFunction];
            isModifiedMaterialEffect = NO;
            return;
        }
        _dubbingBtn.selected = NO;
        sender.selected = NO;
        NSMutableArray *arr = [_dubbingTrimmerView getTimesFor_videoRangeView];
        for (NSInteger i = arr.count-1; i>=0; i--) {
            DubbingRangeView *rangeView = arr[i];
            [rangeView removeFromSuperview];
            rangeView = nil;
        }
        [dubbingArr removeAllObjects];
        for (DubbingRangeView *dubb  in dubbingMusicArr) {
            RDMusic *music = [[RDMusic alloc] init];
            music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
            
            CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
            music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
            music.url = [NSURL fileURLWithPath:dubb.musicPath];
            music.volume = 1;
            music.isRepeat = NO;
            [dubbingArr addObject:music];
        }
        dubbingNewMusicArr = dubbingMusicArr;
        if (dubbingArr.count == 0) {
            _reDubbingBtn.hidden = YES;
            _auditionDubbingBtn.hidden = YES;
        }
        [self check];
        if( arr && arr.count )
            [self initPlayer];
        return;
    }
    if ((_isAddingMaterialEffect || _isEdittingMaterialEffect)
        && (selecteFunction == RDAdvanceEditType_Subtitle
            || selecteFunction == RDAdvanceEditType_Sticker
            || selecteFunction == RDAdvanceEditType_Dewatermark
            || selecteFunction == RDAdvanceEditType_Collage
            || selecteFunction == RDAdvanceEditType_Doodle
            || selecteFunction == RDAdvanceEditType_Multi_track
            || selecteFunction == RDAdvanceEditType_Sound
            || selecteFunction == RDAdvanceEditType_Effect
            ))
    {
        if( (RDAdvanceEditType_Collage == selecteFunction) && (_addEffectsByTimeline.EditCollageView) && (_addEffectsByTimeline.EditCollageView.hidden == NO) )
        {
            //画中画 编辑功能
            
            _addEffectsByTimeline.EditCollageView.hidden = YES;
            return;
        }
        
        toolbarTitleLbl.hidden = NO;
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        
        if (_isAddingMaterialEffect) {
            [_addEffectsByTimeline cancelEffectAction:nil];
        }else {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            isNotNeedPlay = YES;
        }
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        
        cancelBtn.hidden = NO;
        _toolbarTitlefinishBtn.hidden = NO;
        return;
    }
//    if (isModifiedMaterialEffect) {
//        [self initCommonAlertViewWithTitle:RDLocalizedString(@"确定放弃所有操作?",nil)
//                                   message:@""
//                         cancelButtonTitle:RDLocalizedString(@"取消",nil)
//                         otherButtonTitles:RDLocalizedString(@"确定",nil)
//                              alertViewTag:selecteFunction];
//        isModifiedMaterialEffect = NO;
//        return;
//    }
    sender.selected = NO;
    //MARK:音量
    if(selecteFunction == RDAdvanceEditType_Volume){
        __weak typeof(self) weakSelf = self;
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.identifier.length > 0) {
                    [strongSelf.videoCoreSDK setVolume:strongSelf->oldVolume identifier:obj.identifier];
                }
            }];
        }];
        _volumeView.hidden = YES;
        [self check];
        if(![_videoCoreSDK isPlaying]){
//            [self playVideo:YES];
        }
        return;
    }
    //MARK:音效
    if(selecteFunction == RDAdvanceEditType_Sound){
        [self check];
        
        _multi_trackView.hidden = YES;
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        _soundView.hidden = YES;
        if( !_addEffectsByTimeline.isBuild )
        {
            if( (soundMusics && (soundMusics.count > 0) )  || ( oldSoundMusicFiles && (oldSoundMusicFiles.count > 0 ) ) )
            {
                [soundMusics removeAllObjects];
                [soundMusicFiles removeAllObjects];
                for(RDCaptionRangeViewFile *file in oldSoundMusicFiles){
                    RDMusic *music= file.music;
                    if(music){
                        [soundMusics addObject:music];
                        [soundMusicFiles addObject:file];
                    }
                }
                [self initPlayer];
            }
        }
        return;
    }
    //MARK:多段配乐
    if(selecteFunction == RDAdvanceEditType_Multi_track){
        [self check];
        
        [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
            _titleView.hidden = NO;
        }];
        
        _multi_trackView.hidden = YES;
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        _multi_trackView.hidden = YES;
        if( !_addEffectsByTimeline.isBuild )
        {
            if( (musics && (musics.count > 0) )  || ( oldMusicFiles && (oldMusicFiles.count > 0 ) ) )
            {
                [musics removeAllObjects];
                [musicFiles removeAllObjects];
                for(RDCaptionRangeViewFile *file in oldMusicFiles){
                    RDMusic *music= file.music;
                    if(music){
                        [musics addObject:music];
                        [musicFiles addObject:file];
                    }
                }
                [self initPlayer];
            }
        }
        return;
    }
    //MARK:字幕
    if(selecteFunction == RDAdvanceEditType_Subtitle){
        [self check];

        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        [subtitles removeAllObjects];
        [subtitleFiles removeAllObjects];
        for(RDCaptionRangeViewFile *file in oldSubtitleFiles){
            if(file.caption){
                [subtitles addObject:file.caption];
                [subtitleFiles addObject:file];
            }
        }
        [self refreshCaptions];
        [_videoCoreSDK refreshCurrentFrame];
        return;
    }
    //MARK:贴纸
    if (selecteFunction == RDAdvanceEditType_Sticker) {
        if( _captionVideoView.hidden )
            _playerToolBar.hidden = NO;
        _stickerView.hidden = YES;
        
        [self check];
        
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        [stickers removeAllObjects];
        [stickerFiles removeAllObjects];
        for(RDCaptionRangeViewFile *file in oldStickerFiles){
            if(file.caption){
                [stickers addObject:file.caption];
                [stickerFiles addObject:file];
            }
        }
        [self refreshCaptions];
        [_videoCoreSDK refreshCurrentFrame];
        return;
    }
    //MARK:特效
    if(selecteFunction == RDAdvanceEditType_Effect)
    {
        if( _captionVideoView.hidden )
            _playerToolBar.hidden = NO;
        
        [fXArray removeAllObjects];
        [fXFiles removeAllObjects];
        
        fXArray = [[NSMutableArray alloc] init];
        fXFiles = [[NSMutableArray alloc] init];
        
        for(RDCaptionRangeViewFile *file in oldFXFiles){
            if(file.customFilter){
                [fXArray addObject:file.customFilter];
                [fXFiles addObject:file];
            }
        }
        
        NSMutableArray * array = [[NSMutableArray alloc] init];
        
        [fXArray enumerateObjectsUsingBlock:^(RDFXFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( obj.FXTypeIndex < 5 )
            {
                [array addObject:obj.customFilter];
            }
        }];
        [self refreshMaterialEffectArray:customFilterArray newArray:array];
        [self check];
        [self ReturnAdjustment:YES];
        return;
    }
    //MARK:去水印
    if(selecteFunction == RDAdvanceEditType_Dewatermark){
        [self check];
        seekTime = _videoCoreSDK.currentTime;
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        [blurs removeAllObjects];
        [blurFiles removeAllObjects];
        [mosaics removeAllObjects];
        [mosaicFiles removeAllObjects];
        [dewatermarks removeAllObjects];
        [dewatermarkFiles removeAllObjects];
        for(RDCaptionRangeViewFile *file in oldBlurFiles){
            RDAssetBlur *blur = file.blur;
            if (blur) {
                [blurs addObject:blur];
                [blurFiles addObject:file];
            }
        }
        for(RDCaptionRangeViewFile *file in oldMosaicFiles){
            RDMosaic *mosaic = file.mosaic;
            if (mosaic) {
                [mosaics addObject:mosaic];
                [mosaicFiles addObject:file];
            }
        }
        for(RDCaptionRangeViewFile *file in oldDewatermarkFiles){
            RDDewatermark *dewatermark= file.dewatermark;
            if(dewatermark){
                [dewatermarks addObject:dewatermark];
                [dewatermarkFiles addObject:file];
            }
        }
        [self refreshDewatermark];
        [_videoCoreSDK refreshCurrentFrame];
        return;
    }

    //MARK:画中画
    if(selecteFunction == RDAdvanceEditType_Collage){
        [self check];
        seekTime = _videoCoreSDK.currentTime;
        [_addEffectsByTimeline discardEdit];
        
//        [thumbTimes removeAllObjects];
        //        thumbTimes = nil;
        if( !_addEffectsByTimeline.isBuild )
        {
            [collages removeAllObjects];
            [collageFiles removeAllObjects];
            for(RDCaptionRangeViewFile *file in oldCollageFiles){
                RDWatermark *collage = file.collage;
                if (collage) {
                    [collages addObject:collage];
                    [collageFiles addObject:file];
                }
            }
            [self initPlayer];
        }
        return;
    }
    else if (selecteFunction == RDAdvanceEditType_Cover) {//MARK:封面
        if (!_bottomThumbnailView.hidden) {
            _bottomThumbnailView.hidden = YES;
            if (coverFile && CMTimeCompare(coverFile.coverTime, kCMTimeInvalid) == 0) {
                coverAuxView.hidden = YES;
            }
            return;
        }
        coverFile = oldCoverFile;
        [_videoCoreSDK seekToTime:kCMTimeZero];
    }
    else if (selecteFunction == RDAdvanceEditType_Doodle) {//MARK:涂鸦
        if (!_addEffectsByTimeline.doodleConfigView.hidden) {
//            _addEffectsByTimeline.doodleConfigView.hidden = YES;
            [RDHelpClass animateViewHidden:_addEffectsByTimeline.doodleConfigView atUP:NO atBlock:^{
                _addEffectsByTimeline.doodleConfigView.hidden = YES;
            }];
            return;
        }
        seekTime = _videoCoreSDK.currentTime;
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        if( !_addEffectsByTimeline.isBuild )
        {
            [doodles removeAllObjects];
            [doodleFiles removeAllObjects];
            for(RDCaptionRangeViewFile *file in oldDoodleFiles){
                RDWatermark *doodle = file.doodle;
                if (doodle) {
                    [doodles addObject:doodle];
                    [doodleFiles addObject:file];
                }
            }
            [self initPlayer];
        }
    }
    else if (selecteFunction == RDAdvanceEditType_SoundEffect) {//MARK:变声
        if (_customSoundView && !_customSoundView.hidden) {
            _customSoundView.hidden = YES;
            soundEffectSlider.value = logf(oldPitch*1200)/logf(2.0);
            soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
            __weak typeof(self) weakSelf = self;
            [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.identifier.length > 0) {
                        [weakSelf.videoCoreSDK setPitch:oldPitch identifier:obj.identifier];
                    }
                }];
            }];
            return;
        }
    }
    
    if( [self ReturnAdjustment:NO] )
        return;
    
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableWizard){
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"您确定要放弃编辑吗?",nil)
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"取消",nil)
                         otherButtonTitles:RDLocalizedString(@"确定",nil)
                              alertViewTag:100];
        return;
    }
    [thumbImageVideoCore cancelImage];
    [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
    if( _captionVideoView.hidden )
        _playerToolBar.hidden = NO;
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
   UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
    if(!upView){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if(_cancelActionBlock){
        _cancelActionBlock();
    }
}

- (void)saveDraftBtnAction:(UIButton *)sender {
    sender.enabled = NO;
    [thumbImageVideoCore cancelImage];
    [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
    if( [_videoCoreSDK isPlaying] )
       [self playVideo:NO];
    
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
    _addEffectsByTimeline.trimmerView = nil;
    _addEffectsByTimeline.subtitleConfigView = nil;
    _addEffectsByTimeline.trimmerView = nil;
    _addEffectsByTimeline.stickerConfigView = nil;
    
    if (((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate
        && [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(saveDraftResult:)])
    {
        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"保存草稿中...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
        __weak typeof(self) weakSelf = self;
        if (!_draft) {
            _draft = [[RDDraftInfo alloc] init];
        }
        _draft.is15S_MV = !isNewUI;
//        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            if( obj.fileType == kFILEVIDEO )
//            {
//                NSString *path = NSTemporaryDirectory();
//                NSString * fileImagePatch = obj.filtImagePatch;
//                NSRange range = [fileImagePatch rangeOfString:path];
//                fileImagePatch = [fileImagePatch substringFromIndex:range.location + range.length];
//                obj.filtImagePatch = fileImagePatch;
//            }
//
//        }];
        
        _draft.fileList = _fileList;
        _draft.duration = _videoCoreSDK.duration;
        _draft.exportSize = _exportVideoSize;
        _draft.musicIndex = selectMusicIndex;
        _draft.filterIndex = selectFilterIndex;
        _draft.mvIndex = lastThemeMVIndex;
        _draft.originalOn = yuanyinOn;
        _draft.soundEffectIndex = selectedSoundEffectIndex;
        _draft.pitch = oldPitch;
        _draft.coverFile = coverFile;
        _draft.volume = oldVolume;
        [_videoCoreSDK stop];
        _videoCoreSDK.delegate = nil;
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK = nil;
        
        NSMutableArray *musicArray = [NSMutableArray array];
        
        if (mvMusicArray) {
            [mvMusicArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RDDraftMusic *music = [RDDraftMusic new];
                music.music = obj;
                [musicArray addObject:music];
            }];
        }else if (_musicURL) {
            RDDraftMusic *music = [[RDDraftMusic alloc] init];
            music.url = _musicURL;
            if (selectMusicIndex == 2) {
                music.name = ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text;
            }else if (selectMusicIndex == 3) {
                music.name = ((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]).itemTitleLabel.text;
            }
            music.clipTimeRange = _musicTimeRange;
            music.volume = _musicVolume;
            [musicArray addObject:music];
        }
        //音效
        NSMutableArray * draftSoundMusics = [NSMutableArray array];
        [soundMusics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDDraftMusic *music = [[RDDraftMusic alloc] init];
            music.url = obj.url;
            music.effectiveTimeRange = obj.effectiveTimeRange;
            music.clipTimeRange = obj.clipTimeRange;
            music.volume = obj.volume;
            music.name = obj.name;
            music.identifier = obj.identifier;
            [draftSoundMusics addObject:music];
        }];
        _draft.soundMusics = draftSoundMusics;
        [soundMusicFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
            obj.music = nil;
         }];
        
        _draft.soundMusicFiles =  soundMusicFiles;
        
        //多段配乐
        NSMutableArray * draftMulti_trackMusics = [NSMutableArray array];
        [musics enumerateObjectsUsingBlock:^(RDMusic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDDraftMusic *music = [[RDDraftMusic alloc] init];
            music.url = obj.url;
            music.effectiveTimeRange = obj.effectiveTimeRange;
            music.clipTimeRange = obj.clipTimeRange;
            music.volume = obj.volume;
            music.name = obj.name;
            music.identifier = obj.identifier;
            [draftMulti_trackMusics addObject:music];
        }];
        _draft.multi_trackMusics = draftMulti_trackMusics;
        [musicFiles enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
            obj.music = nil;
        }];
        _draft.multi_trackMosaicFiles = musicFiles;
        
        NSMutableArray *dubbingArray = [NSMutableArray array];
        [dubbingNewMusicArr enumerateObjectsUsingBlock:^(DubbingRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            DubbingRangeViewFile *file = [DubbingRangeViewFile new];
            file.home = obj.frame;
            file.dubbingStartTime = obj.dubbingStartTime;
            file.dubbingDuration = obj.dubbingDuration;
            file.musicPath = obj.musicPath;
            file.volume = obj.volume;
            file.dubbingIndex = obj.dubbingIndex;
            file.piantouDuration = _dubbingTrimmerView.piantouDuration;
            file.pianweiDuration = _dubbingTrimmerView.pianweiDuration;
            [dubbingArray addObject:file];
        }];
        _draft.dubbings = dubbingArray;
        NSMutableArray *movieEffectArray = [NSMutableArray array];
        [selectMVEffects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDDraftMovieEffect *movieEffect = [RDDraftMovieEffect new];
            movieEffect.movieEffect = obj;
            [movieEffectArray addObject:movieEffect];
        }];
        _draft.movieEffects = movieEffectArray;
        _draft.musics = musicArray;
        _draft.dubbings = dubbingArray;
        _draft.captions = subtitleFiles;
        _draft.stickers = stickerFiles;
        _draft.blurs = blurFiles;
        _draft.mosaics = mosaicFiles;
        _draft.dewatermarks = dewatermarkFiles;
        _draft.collages = collageFiles;
        _draft.doodles = doodleFiles;
        
        if( _watermarkCollage )
        {
            _draft.watermarkSizeVolume = _watermarkSizeSlider.value;
            _draft.watermarkAlhpavolume = _watermarkAlhpaSlider.value;
            _draft.watermarkRotatevolume = _watermarkRotateSlider.value;
            
            
            NSMutableArray * _watermarkCollages = [[NSMutableArray alloc] init];
            
            [_watermarkCollages addObject:_watermarkCollage];
            
            
            _draft.watermarkCollage = _watermarkCollages;
        }
        //特效
        _draft.fXFiles = fXFiles;
        //时间特效
        NSMutableArray * TimeArray = [[NSMutableArray  alloc] init];
        RDDraftEffectTime * TimeEffectType = [[RDDraftEffectTime alloc] init];
        TimeEffectType.timeType = oldTimeEffectType;
        TimeEffectType.effectiveTimeRange = oldEffectTimeRange;
        [TimeArray addObject:TimeEffectType];
        _draft.timeEffectArray = TimeArray;
        
        //比例
        _draft.oldProportionIndex = oldProportionIndex;
        
        //图片运动
        _draft.oldIsEnlarge = oldIsEnlarge;
        
        [[RDDraftManager sharedManager] saveDraft:_draft completion:^(BOOL success) {
            [RDSVProgressHUD dismiss];
            StrongSelf(self);
            if (success) {
                [((RDNavigationViewController *)strongSelf.navigationController).rdVeUiSdkDelegate saveDraftResult:nil];
                if (_saveDraftCompletionBlock) {
                    _saveDraftCompletionBlock();
                }
            }else {
                NSDictionary *userInfo= [NSDictionary dictionaryWithObject:RDLocalizedString(@"保存草稿失败", nil) forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:RDUISDKCustomErrorDomain code:RDUISDKErrorCode_SaveDraft userInfo:userInfo];
                [((RDNavigationViewController *)strongSelf.navigationController).rdVeUiSdkDelegate saveDraftResult:error];
            }
            [strongSelf.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
        }];
    }else {
        [_videoCoreSDK stop];
        _videoCoreSDK.delegate = nil;
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK = nil;
        [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
    }
}

/**点击发布按键
 */
- (void)tapPublishBtn{
    //MARK:添加/编辑去水印
    if ((selecteFunction == RDAdvanceEditType_Dewatermark) && (_isAddingMaterialEffect || _isEdittingMaterialEffect))
    {
        _addEffectsByTimeline.editBtn.hidden = YES;
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        if (_isAddingMaterialEffect && !_addEffectsByTimeline.dewatermarkTypeView.hidden) {
            [_addEffectsByTimeline startAddDewatermark];
            
            [RDHelpClass animateViewHidden:_addEffectsByTimeline.dewatermarkTypeView atUP:NO atBlock:^{
                _addEffectsByTimeline.dewatermarkTypeView.hidden = YES;
            }];
            
            if(![_videoCoreSDK isPlaying]){
                _addEffectsByTimeline.trimmerView.isTiming = YES;
                _videoTrimmerView.isTiming = YES;
                [self playVideo:YES];
            }
            
            _toolbarTitlefinishBtn.hidden = YES;
            cancelBtn.hidden = YES;
        }else if (_isEdittingMaterialEffect) {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
        }
        return;
    }
    //MARK:添加/编辑画中画
    if ((selecteFunction == RDAdvanceEditType_Collage) && (_isAddingMaterialEffect || _isEdittingMaterialEffect))
    {
        if( (RDAdvanceEditType_Collage == selecteFunction) && (_addEffectsByTimeline.EditCollageView) && (_addEffectsByTimeline.EditCollageView.hidden == NO) )
        {
            //画中画 编辑功能
            _addEffectsByTimeline.EditCollageView.hidden = YES;
            return;
        }
        
        _addEffectsByTimeline.editBtn.hidden = YES;
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        toolbarTitleLbl.hidden = NO;
        if(!_addEffectsByTimeline.albumView.hidden) {
            _addEffectsByTimeline.collageTrimmerView.rangeSlider.hidden= YES;
        }
        if (!_addEffectsByTimeline.pasterView && !_addEffectsByTimeline.albumView.hidden) {
            [_addEffectsByTimeline cancelEffectAction:nil];
            self.isAddingMaterialEffect = NO;
            self.isEdittingMaterialEffect = NO;
            return;
        }
        if (!_addEffectsByTimeline.albumView.hidden) {
            toolbarTitleLbl.hidden = NO;
            if (!collages) {
                collages = [NSMutableArray array];
            }
            
            _addEffectsByTimeline.isBlankCaptionRangeView = false;
            _addEffectsByTimeline.isEdittingEffect = YES;
//            CMTimeRange timeRange = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange;
//            [_addEffectsByTimeline startAddCollage:timeRange collages:collages];
            
            CaptionRangeView * captionRangeView = _addEffectsByTimeline.trimmerView.currentCaptionView;
            
            [_addEffectsByTimeline addCollageFinishAction:_addEffectsByTimeline.finishBtn];
            _addEffectsByTimeline.isBlankCaptionRangeView = true;
            
            [self addedMaterialEffectItemBtnAction:[addedMaterialEffectScrollView viewWithTag:captionRangeView.file.captionId]];
            _addEffectsByTimeline.addBtn.hidden = YES;
            _addEffectsByTimeline.finishBtn.hidden = NO;
        }else {
            self.isAddingMaterialEffect = NO;
            [_addEffectsByTimeline addCollageFinishAction:_addEffectsByTimeline.finishBtn];
        }
        return;
    }
    //MARK:配音
    if(selecteFunction == RDAdvanceEditType_Dubbing){
        if (_isAddingMaterialEffect) {
            [self touchesDownDubbingBtn];
            _dubbingVolumeView.hidden = YES;
            return;
        }
        [self ReturnAdjustment:YES];
        
        dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
        
        [dubbingArr removeAllObjects];
        for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
            RDMusic *music = [[RDMusic alloc] init];
            music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
            
            CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
            music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
            music.url = [NSURL fileURLWithPath:dubb.musicPath];
            music.volume = dubb.volume;
            music.isRepeat = NO;
            [dubbingArr addObject:music];
        }
        dubbingMusicArr = dubbingNewMusicArr;
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        [self check];
        [self initPlayer];
        return;
    }
    if (!_isAddingMaterialEffect) {
        if([_videoCoreSDK isPlaying]){
            [self playVideo:NO];
        }
    }
    //MARK:音量
    if(selecteFunction == RDAdvanceEditType_Volume){
        oldVolume = _originalVolumeSlider.value * volumeMultipleM ;
        
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.videoVolume = oldVolume;
        }];
        
        _volumeView.hidden = YES;
        [self check];
        if(![_videoCoreSDK isPlaying]){
//            [self playVideo:YES];
        }
        return;
    }
    //MARK音效
    if(selecteFunction == RDAdvanceEditType_Sound){
        
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect){
            
            [_addEffectsByTimeline saveSubtitleTimeRange];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            if( _isAddingMaterialEffect )
            {
                cancelBtn.hidden = YES;
                _toolbarTitlefinishBtn.hidden = YES;
            }
            else
            {
                cancelBtn.hidden = NO;
                _toolbarTitlefinishBtn.hidden = NO;
            }
            return;
            
        }
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        _soundView.hidden = YES;
        [self check];
        oldSoundMusicFiles = [soundMusicFiles mutableCopy];
        [self initPlayer];
        return;
    }
    //MARK:多段配乐
    if(selecteFunction == RDAdvanceEditType_Multi_track){
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect){
            [_addEffectsByTimeline saveSubtitleTimeRange];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            if( _isAddingMaterialEffect )
            {
                cancelBtn.hidden = YES;
                _toolbarTitlefinishBtn.hidden = YES;
            }
            else
            {
                cancelBtn.hidden = NO;
                _toolbarTitlefinishBtn.hidden = NO;
            }
            return;
        }
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        
        [RDHelpClass animateViewHidden:_titleView atUP:YES atBlock:^{
            _titleView.hidden = NO;
        }];
        
        
        _multi_trackView.hidden = YES;
        [self check];
        oldMusicFiles = [musicFiles mutableCopy];
        [self initPlayer];
        return;
    }
    //MARK:字幕
    if(selecteFunction == RDAdvanceEditType_Subtitle){
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect || _addEffectsByTimeline.isAddingEffect){
            [_addEffectsByTimeline saveSubtitleTimeRange];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            return;
        }
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        [self check];
        oldSubtitleFiles = [subtitleFiles mutableCopy];
        
//        __weak typeof(self) myself = self;
//        [_videoCoreSDK seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
//            [myself playVideo:NO];
//        }];
        
        return;
    }
    //MARK:贴纸
    if(selecteFunction == RDAdvanceEditType_Sticker){
        if(_isAddingMaterialEffect || _isEdittingMaterialEffect){
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            self.isAddingMaterialEffect = NO;
            self.isEdittingMaterialEffect = NO;
            return;
        }
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        [self check];
        
        oldStickerFiles = [stickerFiles mutableCopy];
        
//        __weak typeof(self) myself = self;
//        [_videoCoreSDK seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
////            [myself playVideo:YES];
//        }];
        return;
    }
    //MARK:特效
    if(selecteFunction == RDAdvanceEditType_Effect)
    {
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect){
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            cancelBtn.hidden = NO;
            _toolbarTitlefinishBtn.hidden = NO;
            
            if( fXFiles && fXFiles.count > 0 )
            {
                selectedMaterialEffectItemIV.hidden = NO;
            }
            
            return;
        }
        
        [_addEffectsByTimeline discardEdit];
        
        [self ReturnAdjustment:YES];
        
        oldFXFiles = [fXFiles mutableCopy];
        
        [self check];
        FXView.hidden = YES;
        return;
    }
    //MARK:去水印
    if (selecteFunction == RDAdvanceEditType_Dewatermark) {
        [_addEffectsByTimeline discardEdit];
        
        [self ReturnAdjustment:YES];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        
        [self check];
        oldBlurFiles = [blurFiles mutableCopy];
        oldMosaicFiles = [mosaicFiles mutableCopy];
        oldDewatermarkFiles = [dewatermarkFiles mutableCopy];
        
//        __weak typeof(self) myself = self;
//        [_videoCoreSDK seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
////            [myself playVideo:YES];
//        }];
        _addEffectsByTimeline.dewatermarkRectView.hidden = YES;
        return;
    }
    //MARK:画中画
    if (selecteFunction == RDAdvanceEditType_Collage) {
        [_addEffectsByTimeline discardEdit];
//        [thumbTimes removeAllObjects];
//        thumbTimes = nil;
        [self check];
        
        oldCollageFiles = [collageFiles mutableCopy];
        
//        __weak typeof(self) myself = self;
//        [_videoCoreSDK seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
////            [myself playVideo:YES];
//        }];
        return;
    }else if (selecteFunction == RDAdvanceEditType_Cover) {//MARK:封面
        if (!_bottomThumbnailView.hidden) {
            _bottomThumbnailView.hidden = YES;
            coverFile = nil;
            coverFile = [RDFile new];
            coverFile.coverTime = _videoCoreSDK.currentTime;
            coverFile.contentURL = [RDHelpClass getFileUrlWithFolderPath:kCoverFolder fileName:@"cover.jpg"];
            WeakSelf(self);
            [_videoCoreSDK getImageWithTime:coverFile.coverTime scale:1.0 completionHandler:^(UIImage *image) {
                StrongSelf(self);
                if (image) {
                    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
                    unlink([strongSelf->coverFile.contentURL.path UTF8String]);
                    [imageData writeToFile:strongSelf->coverFile.contentURL.path atomically:YES];
                }else {
                    strongSelf->coverFile = nil;
                }
            }];
            return;
        }
        oldCoverFile = coverFile;
        [_videoCoreSDK seekToTime:kCMTimeZero];
    }else if (selecteFunction == RDAdvanceEditType_Doodle) {//MARK:涂鸦
        if (!_addEffectsByTimeline.doodleDrawView.hidden) {
            if ([_addEffectsByTimeline.doodleDrawView isHasContent]) {
                RDWatermark *doodle = [[RDWatermark alloc] init];
                doodle.timeRange = CMTimeRangeMake(_videoCoreSDK.currentTime, CMTimeSubtract(CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE), _videoCoreSDK.currentTime));
                doodle.vvAsset.url = [RDHelpClass getFileUrlWithFolderPath:kDoodleFolder fileName:@"doodle.png"];
                doodle.vvAsset.type = RDAssetTypeImage;
                doodle.vvAsset.fillType = RDImageFillTypeFit;
                doodle.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE), _videoCoreSDK.currentTime));
                if (!doodles) {
                    doodles = [NSMutableArray array];
                }
                [doodles addObject:doodle];
                
                UIImage *doodleImage = [_addEffectsByTimeline.doodleDrawView getImage];
                unlink([doodle.vvAsset.url.path UTF8String]);
                [UIImagePNGRepresentation(doodleImage) writeToFile:doodle.vvAsset.url.path atomically:YES];
                _addEffectsByTimeline.doodleDrawView.hidden = YES;
                
                [RDHelpClass animateViewHidden:_addEffectsByTimeline.doodleConfigView atUP:NO atBlock:^{
                    _addEffectsByTimeline.doodleConfigView.hidden = YES;
                }];
                
                
                [_addEffectsByTimeline.trimmerView changeDoodleCurrentRangeviewFile:doodle
                                                                         thumbImage:doodleImage
                                                                        captionView:nil];
                seekTime = _videoCoreSDK.currentTime;
                _addEffectsByTimeline.isAddingEffect = YES;
                cancelBtn.hidden = YES;
                _toolbarTitlefinishBtn.hidden = YES;
                isNotNeedPlay = NO;
                [self initPlayer];
            }else {
                
                [self showPrompt:RDLocalizedString(@"未添加涂鸦", nil)];
                return;
//                [_addEffectsByTimeline cancelEffectAction:nil];
//                self.isAddingMaterialEffect = NO;
            }
            [_addEffectsByTimeline.doodleDrawView clearScreen];
            return;
        }else if (_isAddingMaterialEffect || _isEdittingMaterialEffect) {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            return;
        }
        else {
            oldDoodleFiles = [doodleFiles mutableCopy];
//            __weak typeof(self) myself = self;
//            [_videoCoreSDK seekToTime:CMTimeMake(1, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
////                [myself playVideo:YES];
//            }];
            [_addEffectsByTimeline discardEdit];
        }
    }else if (selecteFunction == RDAdvanceEditType_SoundEffect) {//MARK:变声
        if (_customSoundView && !_customSoundView.hidden) {
            _customSoundView.hidden = YES;
            oldPitch = powf(2.0, soundEffectSlider.value/1200.0);
            [self ReturnAdjustment:YES];
            return;
        }
    }
    if( [self ReturnAdjustment:YES] )
        return;
    if( _captionVideoView.hidden )
        _playerToolBar.hidden = NO;
    isContinueExport = NO;
    
    RDFile *file = [_fileList firstObject];
    if (((RDNavigationViewController *)self.navigationController).exportConfiguration.waterDisabled
        && ((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicDisabled
        && _fileList.count == 1
        && file.fileType == kFILEVIDEO
//        && ![RDHelpClass isSystemPhotoUrl:file.contentURL]
        && file.speed == 1.0
        && !file.isReverse
        && (CGRectEqualToRect(file.crop, CGRectZero) || CGRectEqualToRect(file.crop, CGRectMake(0, 0, 1, 1)))
        && (file.rotate == 0 || file.rotate == -0)
        && !file.isVerticalMirror && !file.isHorizontalMirror
        && CMTimeRangeEqual(file.videoTimeRange, file.videoTrimTimeRange)
        && !_musicURL && soundMusics.count == 0 && musics.count == 0
        && yuanyinOn && file.videoVolume == 1.0
        && selectMVEffects.count == 0 && selectFilterIndex == 0
        && (selectedSoundEffectIndex == 0 || (selectedSoundEffectIndex == -1 && oldPitch == 1.0))
        && dubbingArr.count == 0 && subtitles.count == 0 && stickers.count == 0 && blurs.count == 0 && mosaics.count == 0 && dewatermarks.count == 0 && doodles.count == 0 && collages.count == 0
        && _timeEffectType == kTimeFilterTyp_None
        && customFilterArray.count == 0
        && file.fileTimeFilterType == kTimeFilterTyp_None && file.customFilterIndex == 0 && (file.brightness == 0.0) && (file.contrast == 1.0) && (file.saturation == 1.0 )
        && (file.vignette == 0.0) && (file.sharpness == 0.0) && (file.whiteBalance == 0.0) && (file.filterIndex == kRDFilterType_YuanShi)
        && !CGSizeEqualToSize(proportionVideoSize, selectVideoSize) && !coverFile
        )
    {
        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
        [_videoCoreSDK stop];
        _videoCoreSDK.delegate = nil;
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK = nil;
        
        if( [RDHelpClass isSystemPhotoUrl:file.contentURL] )
        {
            PHAsset * asset =[[PHAsset fetchAssetsWithALAssetURLs:@[file.contentURL] options:nil] objectAtIndex:0];
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.version = PHImageRequestOptionsVersionCurrent;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                
                NSString * sandboxExtensionTokenKey = info[@"PHImageFileSandboxExtensionTokenKey"];
                
                NSArray * arr = [sandboxExtensionTokenKey componentsSeparatedByString:@";"];
                
                NSString * filePath = arr[arr.count - 1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                        ((RDNavigationViewController *)self.navigationController).callbackBlock(filePath);
                    }
                    _addEffectsByTimeline.trimmerView = nil;
                    _addEffectsByTimeline.subtitleConfigView = nil;
                    _addEffectsByTimeline.trimmerView = nil;
                    _addEffectsByTimeline.stickerConfigView = nil;
                    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
                });
            }];
        }
        else
        {
            if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                ((RDNavigationViewController *)self.navigationController).callbackBlock(file.contentURL.path);
            }
            _addEffectsByTimeline.trimmerView = nil;
            _addEffectsByTimeline.subtitleConfigView = nil;
            _addEffectsByTimeline.trimmerView = nil;
            _addEffectsByTimeline.stickerConfigView = nil;
            [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
        }
    }else {
        [self exportMovie];
    }
}

- (void)refreshWatermarkArrayWithIsExport:(BOOL)isExport {
    NSMutableArray *array = [NSMutableArray arrayWithArray:collages];
    if (isExport && coverFile) {
        RDWatermark *coverWatermark = [[RDWatermark alloc] init];
        coverWatermark.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.3, TIMESCALE));
        coverWatermark.isRepeat = NO;
        coverWatermark.vvAsset.url = coverFile.contentURL;
        coverWatermark.vvAsset.type = RDAssetTypeImage;
        coverWatermark.vvAsset.fillType = RDImageFillTypeFit;
        coverWatermark.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(KPICDURATION, TIMESCALE));
        coverWatermark.vvAsset.crop = coverFile.crop;
        coverWatermark.vvAsset.rotate = coverFile.rotate;
        
        [array addObject:coverWatermark];
    }
    [array addObjectsFromArray:doodles];
    if( _watermarkCollage )
        [array addObject:_watermarkCollage.collage];
    _videoCoreSDK.watermarkArray = array;
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
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示",nil)
                                   message:message
                         cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                         otherButtonTitles:RDLocalizedString(@"继续",nil)
                              alertViewTag:103];
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
    
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:_videoCoreSDK totalDration:_videoCoreSDK.duration exportSize:_exportVideoSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
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
    
    [self refreshWatermarkArrayWithIsExport:YES];
    
    [_videoCoreSDK exportMovieURL:[NSURL fileURLWithPath:export]
                             size:_exportVideoSize
                          bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                              fps:kEXPORTFPS
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
            isExport = true;
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
    [_videoCoreSDK removeWaterMark];
    [_videoCoreSDK removeEndLogoMark];
    [_videoCoreSDK filterRefresh:kCMTimeZero];
    [self refreshWatermarkArrayWithIsExport:NO];
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
    [thumbImageVideoCore cancelImage];
    [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    self.exportProgressView = nil;
    NSLog(@"成功");
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK = nil;
    
    [thumbImageVideoCore stop];
    thumbImageVideoCore.delegate = nil;
    [thumbImageVideoCore.view removeFromSuperview];
    thumbImageVideoCore = nil;
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    _addEffectsByTimeline.trimmerView = nil;
    _addEffectsByTimeline.subtitleConfigView = nil;
    _addEffectsByTimeline.trimmerView = nil;
    _addEffectsByTimeline.stickerConfigView = nil;
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
}

/**点击播放暂停按键
 */
- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
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
        if(_exportVideoSize.width>_exportVideoSize.height){
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
            _videoCoreSDK.fillMode = kRDViewFillModeScaleAspectFill;
        }
        [_playerView setFrame:videoThumbnailFrame];
        
        _videoCoreSDK.frame = playerFrame;
        _playButton.frame = CGRectMake((playerFrame.size.width - 44.0)/2.0, (playerFrame.size.height - 44)/2.0, 44, 44);
        if(![_videoCoreSDK isPlaying]){
            if (CMTimeGetSeconds(CMTimeAdd(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))) > _videoCoreSDK.duration) {
                [_videoCoreSDK seekToTime:CMTimeSubtract(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [_videoCoreSDK seekToTime:CMTimeAdd(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }else{
        if (iPhone_X) {
            _videoCoreSDK.fillMode = kRDViewFillModeScaleAspectFit;
        }
        [self.view bringSubviewToFront:_titleView];
        [_playerToolBar removeFromSuperview];
        [self.view insertSubview:_playerToolBar aboveSubview:_playerView];
        //缩小
        _playerView.transform = CGAffineTransformIdentity;
        _playerToolBar.transform = _playerView.transform;
        [_playerView setFrame:CGRectMake(0, playerViewOriginX, kWIDTH, playerViewHeight)];
        _videoCoreSDK.frame = _playerView.bounds;
        _playButton.frame = CGRectMake((_playerView.frame.size.width - 44.0)/2.0, (_playerView.frame.size.height - 44)/2.0, 44, 44);
        _playerToolBar.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.bounds.size.height - (isNewUI ? 22 : 44), _playerView.frame.size.width, 44);
        _currentTimeLabel.frame = CGRectMake(5, (_playerToolBar.frame.size.height - 20)/2.0,60, 20);
        _videoProgressSlider.frame = CGRectMake(60, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 60 - 50, _playerToolBar.frame.size.height - 30, 60, 20);
        _zoomButton.frame = CGRectMake(_playerToolBar.frame.size.width - 50, (_playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        if(![_videoCoreSDK isPlaying]){
            if (CMTimeGetSeconds(CMTimeSubtract(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))) >= 0.0) {
                [_videoCoreSDK seekToTime:CMTimeSubtract(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [_videoCoreSDK seekToTime:CMTimeAdd(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }
}
//MARK: 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if(slider == _musicVolumeSlider){
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        [_videoCoreSDK setVolume:_musicVolume identifier:@"music"];
        
        if( _musicVolume == 0 )
        {
            [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音关_"] forState:UIControlStateSelected];
        }
        else
        {
            [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音开_"] forState:UIControlStateSelected];
        }
        
    }else if( (slider == _originalVolumeSlider)  || (slider == _videoVolumeSlider) )
    {
        _originalVolume = slider.value*volumeMultipleM;
        __weak typeof(self) weakSelf = self;
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.identifier.length > 0) {
                    [strongSelf.videoCoreSDK setVolume:_originalVolume identifier:obj.identifier];
                }
            }];
        }];
        
        
        if( (slider == _videoVolumeSlider) && (_originalVolume == 0) )
        {
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音关_"] forState:UIControlStateNormal];
            yuanyinOn = NO;
        }
        else
        {
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"] forState:UIControlStateNormal];
            yuanyinOn = YES;
        }
    }
    else if( slider == _addedMusicVolumeSlider )
    {
        _audioPlayer.volume = _addedMusicVolumeSlider.value*volumeMultipleM;
        _addEffectsByTimeline.trimmerView.currentCaptionView.file.music.volume = _addedMusicVolumeSlider.value*volumeMultipleM;
    }
    else if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    
    if(slider == _musicVolumeSlider){
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        [_videoCoreSDK setVolume:_musicVolume identifier:@"music"];
        
        if( _musicVolume == 0 )
         {
             [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音关_"] forState:UIControlStateSelected];
         }
         else
         {
             [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音开_"] forState:UIControlStateSelected];
         }
        
    }else if( (slider == _originalVolumeSlider) || (slider == _videoVolumeSlider) )
    {
        _originalVolume = slider.value*volumeMultipleM;
        
        __weak typeof(self) weakSelf = self;
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.identifier.length > 0) {
                    [strongSelf.videoCoreSDK setVolume:strongSelf.originalVolume identifier:obj.identifier];
                }
            }];
        }];
        
        if( (slider == _videoVolumeSlider) && (_originalVolume == 0) )
        {
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音关_"] forState:UIControlStateNormal];
            yuanyinOn = NO;
        }
        else
        {
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"] forState:UIControlStateNormal];
            yuanyinOn = YES;
        }
        
    }else if( slider == _addedMusicVolumeSlider )
    {
        _audioPlayer.volume = _addedMusicVolumeSlider.value*volumeMultipleM;
        _addEffectsByTimeline.trimmerView.currentCaptionView.file.music.volume = _addedMusicVolumeSlider.value*volumeMultipleM;
        
    }else {
        CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:current];
    }
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if(slider == _musicVolumeSlider){
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        [_videoCoreSDK setVolume:_musicVolume identifier:@"music"];
        
        if( _musicVolume == 0 )
        {
            [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音关_"] forState:UIControlStateSelected];
            yuanyinOn = NO;
        }
        else
        {
            [_musicVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_声音开_"] forState:UIControlStateSelected];
            yuanyinOn = YES;
        }
#if !ENABLEAUDIOEFFECT
        if([_videoCoreSDK isPlaying]){
            [self playVideo:NO];
        }
        [self initPlayer];
#endif
    }else if( (slider == _originalVolumeSlider) || (slider == _videoVolumeSlider) )
    {
        __weak typeof(self) weakSelf = self;
        
        _originalVolume = slider.value*volumeMultipleM;
        
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.identifier.length > 0) {
                    [strongSelf.videoCoreSDK setVolume:_originalVolume identifier:obj.identifier];
                }
            }];
        }];
        
        if( (slider == _videoVolumeSlider) && (_originalVolume == 0) )
        {
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音关_"] forState:UIControlStateNormal];
        }
        else
        {
            [_videoVolumeBtn setImage:[RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"] forState:UIControlStateNormal];
        }
    }else if( slider == _addedMusicVolumeSlider )
    {
        _audioPlayer.volume = _addedMusicVolumeSlider.value*volumeMultipleM;
        _addEffectsByTimeline.trimmerView.currentCaptionView.file.music.volume = _addedMusicVolumeSlider.value*volumeMultipleM;
    }else {
        CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    }
}

- (void)playVideo:(BOOL)play{
    if(!play){
#if 1
        [_videoCoreSDK pause];
#else
        if([_videoCoreSDK isPlaying]){//不加这个判断，否则疯狂切换音乐在低配机器上有可能反应不过来
            [_videoCoreSDK pause];
        }
#endif
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            case RDAdvanceEditType_Effect:
            {
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
            }
                break;
            case RDAdvanceEditType_Dubbing:
            {
                [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
                [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
                if (_isAddingMaterialEffect) {
                    [self touchesDownDubbingBtn];
                }
            }
                break;
            default:
            {
                [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
                [_captionPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
                _playButton.hidden = NO;
                [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
            }
                break;
        }
    }else{
        if (_videoCoreSDK.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
#if 1
        [_videoCoreSDK play];
#else
        if(![_videoCoreSDK isPlaying]){//不加这个判断，否则疯狂切换音乐在低配机器上有可能反应不过来
            [_videoCoreSDK play];
        }
#endif
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            case RDAdvanceEditType_Effect:
            {
                startPlayTime = _videoCoreSDK.currentTime;
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
            }
                break;
            case RDAdvanceEditType_Dubbing:
            {
                startPlayTime = _videoCoreSDK.currentTime;
                [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
                [_captionPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                _playButton.hidden = YES;
                
                [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
                [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
            }
                break;
        }
    }
}

- (void)playerToolbarShow{
    if( !isProprtionUI )
        self.playerToolBar.hidden = NO;
    self.playButton.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        self.playButton.hidden = YES;
    }]; }

#pragma mark - RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        if(sender == _videoCoreSDK && !_exportProgressView){
            if(selecteFunction == RDAdvanceEditType_Multi_track || selecteFunction == RDAdvanceEditType_Sound)
            {
                if( VideoCurrentTime != 0 )
                    seekTime = CMTimeMakeWithSeconds(VideoCurrentTime*_videoCoreSDK.duration, TIMESCALE);
                
                if (_isAddingMaterialEffect || _addEffectsByTimeline.isAddingEffect) {
                    if (CMTimeCompare(seekTime, kCMTimeZero) == 1)
                    {
                        [_videoCoreSDK seekToTime:seekTime toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                            seekTime = kCMTimeZero;
                            [self playVideo:YES];
                        }];
                    }else if (!_videoCoreSDK.isPlaying) {
                        [self playVideo:YES];
                    }
                }else if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                    if( _addEffectsByTimeline.isPlay )
                    {
                        WeakSelf(self);
                        [_videoCoreSDK seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                            StrongSelf(self);
                            if (!strongSelf->isNotNeedPlay) {
                                [strongSelf playVideo:YES];
                            }else {
                                strongSelf->isNotNeedPlay = NO;
                            }
                            strongSelf->seekTime = kCMTimeZero;
                            _addEffectsByTimeline.isPlay = false;
                        }];
                    }
                    else{
                        [_videoCoreSDK seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:nil];
                        seekTime = kCMTimeZero;
                        isNotNeedPlay = NO;
                    }
                }
            }else if (selecteFunction == RDAdvanceEditType_Collage || selecteFunction == RDAdvanceEditType_Doodle) {
                if(  VideoCurrentTime != 0 )
                    seekTime = CMTimeMakeWithSeconds(VideoCurrentTime*_videoCoreSDK.duration, TIMESCALE);
                    
                if (_addEffectsByTimeline.isAddingEffect) {
                    if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                        WeakSelf(self);
                        [_videoCoreSDK seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                            StrongSelf(self);
                            if (!strongSelf->isNotNeedPlay && _addEffectsByTimeline.isAddingEffect) {
                                _addEffectsByTimeline.trimmerView.isTiming = YES;
                                _videoTrimmerView.isTiming = YES;
                                [strongSelf playVideo:YES];
                            }else {
                                strongSelf->isNotNeedPlay = NO;
                            }
                            if (_addEffectsByTimeline.isAddingEffect) {
                                strongSelf->seekTime = kCMTimeZero;
                            }
                        }];
                    }else if(!isNotNeedPlay) {
                        [self playVideo:YES];
                    }else {
                        isNotNeedPlay = NO;
                    }
                }else if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                    if( _addEffectsByTimeline.isPlay )
                    {
                        WeakSelf(self);
                        [_videoCoreSDK seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                            StrongSelf(self);
                            if (!strongSelf->isNotNeedPlay) {
                                [strongSelf playVideo:YES];
                            }else {
                                strongSelf->isNotNeedPlay = NO;
                            }
                            strongSelf->seekTime = kCMTimeZero;
                            _addEffectsByTimeline.isPlay = false;
                        }];
                    }
                    else{
                        [_videoCoreSDK seekToTime:seekTime toleranceTime:kCMTimeZero completionHandler:nil];
                        seekTime = kCMTimeZero;
                        isNotNeedPlay = NO;
                    }
                }
            }
            else if(selecteFunction != RDAdvanceEditType_Effect && selecteFunction != RDAdvanceEditType_Cover && selecteFunction != RDAdvanceEditType_Dubbing)
            {
                if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
                    CMTime time = seekTime;
                    seekTime = kCMTimeZero;
                    [_videoCoreSDK seekToTime:time toleranceTime:kCMTimeZero completionHandler:nil];
                    [_videoTrimmerView setProgress:(CMTimeGetSeconds(time)/_videoCoreSDK.duration) animated:NO];
                }
            }
            else{
                if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
                    if( (CMTimeGetSeconds(fxTimeRange.duration) > 0)  || (selecteFunction == RDAdvanceEditType_Effect) )
                    {
                        if( isPreviewFx )
                        {
                            [self playVideo:YES];
                        }
                        else if( isFXUpdateTime )
                        {
                            isFXUpdateTime = false;
                            [self playVideo:YES];
                        }
                    }
                }else {
                    CMTime time = seekTime;
                    seekTime = kCMTimeZero;
                    __weak typeof(self) weakSelf = self;
                    [_videoCoreSDK seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                        StrongSelf(self);
                        if(strongSelf && selecteFunction == RDAdvanceEditType_Effect )
                        {
                            if( isFXUpdate )
                            {
                                [strongSelf Core_loadTrimmerViewThumbImage];
                                [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                                  thumbnailCount:thumbTimes.count
                                                                  addEffectArray:fXArray
                                                                    oldFileArray:fXFiles];
                                [strongSelf refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES atIsVideo:NO];
                                if( _addEffectsByTimeline )
                                {
                                    if( _addEffectsByTimeline.durationTimeLbl )
                                    {
                                        _addEffectsByTimeline.durationTimeLbl.text = [RDHelpClass timeToStringFormat: _videoCoreSDK.duration];
                                    }
                                }
                                
                                isFXUpdate = false;
                                
                                if( _addEffectsByTimeline.fXConfigView && !_addEffectsByTimeline.fXConfigView.hidden )
                                {
                                    [strongSelf playVideo:YES];
                                    [RDHelpClass animateViewHidden:_addEffectsByTimeline.fXConfigView atUP:NO atBlock:^{
                                        
                                        [_addEffectsByTimeline.currentFXScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                            if( [obj isKindOfClass:[RDAddItemButton class]] )
                                            {
                                                RDAddItemButton * fxBtn = (RDAddItemButton *)obj;
                                                [fxBtn stopScrollTitle];
                                            }
                                        }];
                                        
                                        [_addEffectsByTimeline.fXConfigView removeFromSuperview];
                                        _addEffectsByTimeline.fXConfigView = nil;
                                        
                                    }];
                                }
                            }
                            else{
                                if( isPreviewFx )
                                {
                                    [strongSelf playVideo:YES];
                                }
                                else if( isFXUpdateTime )
                                {
                                    isFXUpdateTime = false;
                                    [strongSelf playVideo:YES];
                                }
                            }
                        }
                    }];
                }
            }
        }
    }
}

/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    if(sender == thumbImageVideoCore){
        return;
    }
    if([_videoCoreSDK isPlaying]){
        float currTime = CMTimeGetSeconds(currentTime);
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(currTime, _videoCoreSDK.duration)];
        float progress = currTime/_videoCoreSDK.duration;
        [_videoProgressSlider setValue:progress];
        
        if( _videoTrimmerView )
        {
            if(!_videoTrimmerView.videoCore) {
                [_videoTrimmerView setVideoCore:_videoCoreSDK];
            }
           if( !isRecording && [_videoTrimmerView setProgress:progress animated:NO])
           {
               if (selecteFunction == RDAdvanceEditType_Subtitle) {
                   if (_addEffectsByTimeline.subtitleConfigView.hidden) {
                       VideoCurrentTime = progress;
                   }
               }else {
                   VideoCurrentTime = progress;
               }
           }
            _captionVideoCurrentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(_videoCoreSDK.currentTime)];
        }
        
        switch (selecteFunction) {
            case RDAdvanceEditType_Dubbing:
            {
                if(!_dubbingTrimmerView.videoCore)
                    [_dubbingTrimmerView setVideoCore:_videoCoreSDK];
                
                [_dubbingTrimmerView setProgress:progress animated:NO];
                
                VideoCurrentTime = progress;
                
                if(_isAddingMaterialEffect){
                    BOOL suc = [_dubbingTrimmerView changecurrentRangeviewppDubbingFile:CMTimeGetSeconds(CMTimeSubtract(currentTime, startDubbingTime)) volume:_dubbingVolumeSlider.value*volumeMultipleM callBlock:nil];
                    if(!suc){
                        [self touchesDownDubbingBtn];
                        _dubbingBtn.hidden = YES;
                        _deletedDubbingBtn.hidden = NO;
                        _dubbingVolumeView.hidden = NO;
                    }
                }
            }
                break;
            case RDAdvanceEditType_Effect:
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            {
                if (!CMTimeRangeEqual(kCMTimeRangeZero, playTimeRange)) {
                    if (CMTimeCompare(currentTime, CMTimeAdd(playTimeRange.start, playTimeRange.duration)) >= 0) {
                        [self playVideo:NO];
                        WeakSelf(self);
                        [_videoCoreSDK seekToTime:playTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                            [weakSelf.addEffectsByTimeline previewCompletion];
                        }];
                        float time = CMTimeGetSeconds(playTimeRange.start);
                        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(time, _videoCoreSDK.duration)];
                        float progress = time/_videoCoreSDK.duration;
                        [_videoProgressSlider setValue:progress];
                        [_videoTrimmerView setProgress:progress animated:NO];
                        _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:time];
                        playTimeRange = kCMTimeRangeZero;
                    }
                }else if( currentFxFilter && ( CMTimeGetSeconds(fxTimeRange.duration) > 0 ) )
                {
                    if( (CMTimeGetSeconds(currentTime) >= CMTimeGetSeconds( CMTimeAdd(fxTimeRange.start, fxTimeRange.duration) ) ) )
                    {
                        
                        [self playVideo:NO];
                        [_videoCoreSDK seekToTime:fxTimeRange.start];
//                        [self previewFx:nil];
                    }
                }
                else
                {
                    if(!_addEffectsByTimeline.trimmerView.videoCore) {
                        [_addEffectsByTimeline.trimmerView setVideoCore:_videoCoreSDK];
                    }
                    bool isAdj = [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
                    if( isAdj )
                    {
                        _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:currTime];
                        if (selecteFunction == RDAdvanceEditType_Subtitle) {
                            if (_addEffectsByTimeline.subtitleConfigView.hidden) {
                                VideoCurrentTime = progress;
                            }
                        }else {
                            VideoCurrentTime = progress;
                        }
                    }
                    if(_isAddingMaterialEffect){
                        BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
                        if(!suc){
                            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                        }else if (addingMaterialDuration > 0 && currTime >= _addEffectsByTimeline.trimmerView.startTime - _addEffectsByTimeline.trimmerView.piantouDuration + addingMaterialDuration) {
                            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                        }
                    }
                }
                
            }
                break;
            default:
                break;
        }
    }
    else
    {
//        float currTime = CMTimeGetSeconds(currentTime);
//        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(currTime, _videoCoreSDK.duration)];
//        float progress = currTime/_videoCoreSDK.duration;
//
//        switch (selecteFunction) {
//                    case RDAdvanceEditType_Dubbing:
//                    {
//                        VideoCurrentTime = progress;
//                    }
//                        break;
//                    case RDAdvanceEditType_Effect:
//                    case RDAdvanceEditType_Subtitle:
//                    case RDAdvanceEditType_Sticker:
//                    case RDAdvanceEditType_Dewatermark:
//                    case RDAdvanceEditType_Doodle:
//                    case RDAdvanceEditType_Collage:
//                    case RDAdvanceEditType_Multi_track:
//                    case RDAdvanceEditType_Sound:
//                    {
//                        VideoCurrentTime = progress;
//                    }
//                        break;
//                    default:
//                        break;
//                }
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
    switch (selecteFunction) {
        case RDAdvanceEditType_Dubbing:
        {
            if(!_isAddingMaterialEffect){
                [_dubbingTrimmerView setProgress:0 animated:NO];
                [self touchescurrentdubbingView:[[_dubbingTrimmerView getTimesFor_videoRangeView_withTime] firstObject] flag:YES];
            }else{
                [self touchesDownDubbingBtn];
                _dubbingBtn.hidden = YES;
                _deletedDubbingBtn.hidden = NO;
                _dubbingVolumeView.hidden = NO;
            }
        }
            break;
        case RDAdvanceEditType_Subtitle:
        {
            if(_isAddingMaterialEffect){
                {
                    [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
//                [_addEffectsByTimeline saveSubtitle:YES];
                }
            }else{
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        case RDAdvanceEditType_Sticker:
        {
            if(_isAddingMaterialEffect){
                [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                CMTime time = [_videoCoreSDK currentTime];
                [_videoCoreSDK filterRefresh:time];
                self.isAddingMaterialEffect = NO;
                self.isEdittingMaterialEffect = NO;
            }else{
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        case RDAdvanceEditType_Effect: {
            [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
//            [_videoThumbnailView setProgress:0];
        }
            break;
        case RDAdvanceEditType_Dewatermark:
        case RDAdvanceEditType_Collage:
        case RDAdvanceEditType_Doodle:
        {
            if (_isAddingMaterialEffect) {
                [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
            }else {
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        default:
        {
            [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
            [_videoTrimmerView setProgress:0.0 animated:NO];
            [_videoProgressSlider setValue:0];
        }
            break;
    }
}

- (void)tapPlayerView{
    switch (selecteFunction) {
        case RDAdvanceEditType_Dubbing:
        case RDAdvanceEditType_Subtitle:
        case RDAdvanceEditType_Sticker:
        case RDAdvanceEditType_Effect:
        case RDAdvanceEditType_Dewatermark:
        case RDAdvanceEditType_Collage:
        case RDAdvanceEditType_Doodle:
        {
            if( _addEffectsByTimeline && !_addEffectsByTimeline.fXConfigView )
                [self playVideo:![_videoCoreSDK isPlaying]];
        }
            break;
        default:
        {
            self.playButton.hidden = !self.playButton.hidden;            
        }
            break;
    }
}

#pragma mark- ===配音===
- (void)reDubbingTouchesUp{
    //MARK:重新配音
    [self playToEnd];
    dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
    for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
        //unlink([dubb.musicPath UTF8Stridaong]);
        [dubb removeFromSuperview];
    }
    [dubbingArr removeAllObjects];
    
    [_videoProgressSlider setValue:0];
    [_dubbingTrimmerView setProgress:0 animated:NO];
    _deletedDubbingBtn.hidden = YES;
    _reDubbingBtn.hidden = YES;
    _auditionDubbingBtn.hidden = YES;
    _dubbingBtn.hidden = NO;
    _dubbingBtn.enabled = YES;
    _dubbingVolumeView.hidden = YES;
    isModifiedMaterialEffect = YES;
    [self initPlayer];
}

#ifdef kRECORDAAC
-(AVAudioRecorder *)recorder{
    //AVAudioRecorder * _audioRecorder;
    if (!recorder) {
        //创建录音文件保存路径
        NSString *fileName = [RDHelpClass createFilename];
        
        dubbingCafFilePath = [[RDHelpClass returnEditorVideoPath] stringByAppendingString:[NSString stringWithFormat:@"/DubbingFile%@.aac",fileName]];
        
        NSURL *url=[NSURL URLWithString:dubbingCafFilePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        recorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        recorder.delegate=self;
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return recorder;
}

-(NSDictionary *)getAudioSetting{
    //LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [recordSettings setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey: AVFormatIDKey];
    //采样率
    [recordSettings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//11025.0
    //通道数
    [recordSettings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    [recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    return recordSettings;
}
#endif

- (void)touchesDownDubbingBtn{
    if( _dubbingBtn.selected )
    {
        //停止配音
        [self touchesUpDubbingBtn];
        [_dubbingBtn setSelected:NO];
        return;
    }
    _reDubbingBtn.hidden = YES;
    _auditionDubbingBtn.hidden = YES;
    [_dubbingBtn setSelected:YES];
    //MARK:开始配音
    [_videoCoreSDK playerMute:YES];
    if(![_videoCoreSDK isPlaying]){
        [self playVideo:YES];
    }
    startDubbingTime = _videoCoreSDK.currentTime;
    if (_dubbingTrimmerView.scrollView.contentOffset.x == 0) {
        startDubbingTime = kCMTimeZero;
    }
    _isAddingMaterialEffect = YES;
    isModifiedMaterialEffect = YES;
#ifdef kRECORDAAC
    
    session = [AVAudioSession sharedInstance];
    //session.description;
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil) {
        NSLog(@"Error creating session: %@", [sessionError description]);
    }else {
        [session setActive:YES error:nil];
    }
    
    [[self recorder] record];
#else
    NSString *fileName = [RDHelpClass createFilename];
    
    dubbingCafFilePath = [[RDHelpClass returnEditorVideoPath] stringByAppendingString:[NSString stringWithFormat:@"/DubbingFile%@",fileName]];
    dubbingMp3FilePath = [[RDHelpClass returnEditorVideoPath] stringByAppendingString:[NSString stringWithFormat:@"/DubbingFile%@.mp3",fileName]];
    
    session = [AVAudioSession sharedInstance];
    //session.description;
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil) {
        NSLog(@"Error creating session: %@", [sessionError description]);
    }else {
        [session setActive:YES error:nil];
    }
    //录音设置
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    //    //录音格式 无法使用
    [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [settings setValue :[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    [settings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    NSURL *recordedFile = [[NSURL alloc] initFileURLWithPath:dubbingCafFilePath];
    recorder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:settings error:nil];
    [recorder prepareToRecord];
    [recorder record];
#endif
    
    [_dubbingTrimmerView addDubbing];
}

- (void)touchesUpDubbingBtn{
    if(!_isAddingMaterialEffect){
        return;
    }
    //MARK:结束配音
    [_videoCoreSDK playerMute:NO];
    _isAddingMaterialEffect = NO;
    [self playVideo:NO];
    
    if(recorder)//
    {
        [[self recorder] stop];
        recorder = nil;
        if(!dubbingArr){
            dubbingArr = [NSMutableArray array];
        }
        if(!dubbingNewMusicArr){
            dubbingNewMusicArr = [NSMutableArray array];
        }
        if(!dubbingMusicArr){
            dubbingMusicArr = [NSMutableArray array];
        }
        float dubbingcurrentDuration = CMTimeGetSeconds(_videoCoreSDK.currentTime) - CMTimeGetSeconds(startDubbingTime);
        if(dubbingcurrentDuration<=0){
            dubbingcurrentDuration = _videoCoreSDK.duration - CMTimeGetSeconds(startDubbingTime);
        }
        if(dubbingcurrentDuration !=0 && (_videoCoreSDK.duration < CMTimeGetSeconds(startDubbingTime))){
            [_dubbingTrimmerView changecurrentRangeviewppDubbingFile:dubbingcurrentDuration volume:_dubbingVolumeSlider.value*volumeMultipleM callBlock:nil];
        }
        BOOL suc = [_dubbingTrimmerView savecurrentRangeviewWithMusicPath:dubbingCafFilePath volume:_dubbingVolumeSlider.value*volumeMultipleM dubbingIndex:[[_dubbingTrimmerView getTimesFor_videoRangeView] count]-1 flag:YES];
        if(suc){
            dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
            double duration = CMTimeGetSeconds([dubbingNewMusicArr lastObject].dubbingDuration);
            if(duration<0.2){
                [[dubbingNewMusicArr lastObject] removeFromSuperview];
                [dubbingNewMusicArr removeLastObject];
            }
            [dubbingArr removeAllObjects];
            for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
                if (dubb.musicPath && dubb.musicPath.length > 0) {
                    RDMusic *music = [[RDMusic alloc] init];
                    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
                    
                    CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
                    music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
                    music.url = [NSURL fileURLWithPath:dubb.musicPath];
                    music.volume = dubb.volume;
                    music.isRepeat = NO;
                    [dubbingArr addObject:music];
                }
            }            
        }else{
            [self.hud setCaption:RDLocalizedString(@"时间至少大于0.5秒!", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
            
            [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateNormal];
            [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateHighlighted];
        }
#if 0
        RdCanAddDubbingType type = [_dubbingTrimmerView checkCanAddDubbing];
        if (type == kCanAddDubbing) {
            _dubbingBtn.enabled = YES;
            _dubbingVolumeView.hidden = YES;
        }else if (type == kCannotAddDubbing) {
            _dubbingBtn.hidden = YES;
            _deletedDubbingBtn.hidden = NO;
            _dubbingVolumeView.hidden = NO;
        }else {
            _dubbingBtn.enabled = NO;
            _dubbingVolumeView.hidden = NO;
        }
#endif
        if (CMTimeGetSeconds(_videoCoreSDK.currentTime) >= _videoCoreSDK.duration) {
            _dubbingBtn.hidden = YES;
            _deletedDubbingBtn.hidden = NO;
            _dubbingVolumeView.hidden = NO;
        }
    }
    _reDubbingBtn.hidden = NO;
    _auditionDubbingBtn.hidden = NO;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)touchesUpDeletedDubbingBtn{
    //MARK:删除配音
    if ([_videoCoreSDK isPlaying]) {
        [self playVideo:NO];
    }
    CMTime currentTime = [_dubbingTrimmerView deletedcurrentDubbing];
    dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
    [dubbingArr removeAllObjects];
    for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
        RDMusic *music = [[RDMusic alloc] init];
        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
        
        CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
        music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
        music.url = [NSURL fileURLWithPath:dubb.musicPath];
        music.volume = dubb.volume;
        music.isRepeat = NO;
        [dubbingArr addObject:music];
    }
    _deletedDubbingBtn.hidden = YES;
    if (dubbingNewMusicArr.count == 0) {
        _reDubbingBtn.hidden = YES;
        _auditionDubbingBtn.hidden = YES;
    }
    _dubbingBtn.hidden = NO;
    _dubbingVolumeView.hidden = YES;
    [self touchescurrentdubbingView:nil flag:YES];
    isModifiedMaterialEffect = YES;
    seekTime = currentTime;
    [_dubbingTrimmerView setProgress:(CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration) animated:NO];
    [self initPlayer];
}

- (void)auditionDubbingTouchesUp{
    //MARK:试听配音
    dubbingNewMusicArr = [_dubbingTrimmerView getTimesFor_videoRangeView];
    [dubbingArr removeAllObjects];
    for (DubbingRangeView *dubb  in dubbingNewMusicArr) {
        RDMusic *music = [[RDMusic alloc] init];
        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubb.dubbingDuration);
        
        CMTime start = CMTimeAdd(dubb.dubbingStartTime, CMTimeMake(_dubbingTrimmerView.piantouDuration, TIMESCALE));
        music.effectiveTimeRange = CMTimeRangeMake(start, music.clipTimeRange.duration);
        music.url = [NSURL fileURLWithPath:dubb.musicPath];
        music.volume = dubb.volume;
        music.isRepeat = NO;
        [dubbingArr addObject:music];
    }
    _dubbingBtn.selected = NO;
    [_dubbingTrimmerView setProgress:0 animated:NO];
    [self refreshSound];
}

- (void)dubbingVolumeSliderEndScrub {
    [_dubbingTrimmerView changeCurrentVolume:_dubbingVolumeSlider.value*volumeMultipleM];
    [self auditionDubbingTouchesUp];
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

#pragma mark - 特效
- (void)addTimeEffect:(BOOL) isPlay{//20170901
    if( _timeEffectType == kTimeFilterTyp_None )
    {
//        if( _fileList[0].fileTimeFilterType != kTimeFilterTyp_None )
//        {
            seekTime = fxTimeRange.start;
            [self initPlayer];
            
            fxTimeRange = kCMTimeRangeZero;
            fxStartTime = kCMTimeZero;
            return;
//        }
    }
    if( ( (_timeEffectType == kTimeFilterTyp_Reverse) || (_timeEffectType == kTimeFilterTyp_Repeat) ) && (_fileList[0].reverseVideoURL == nil) )
    {
        [self InitMainCircleView];
        cancel  = false;
        RDFile *file = _fileList[0];
        NSString * exportPath = [RDGenSpecialEffect ExportURL:file];
        [RDVECore exportReverseVideo:file.contentURL outputUrl: [NSURL fileURLWithPath:exportPath]  timeRange:file.videoTimeRange videoSpeed:1.0 progressBlock:^(NSNumber *prencent) {
            if( self->ProgressHUD != nil )
                self->ProgressHUD.progress = [prencent floatValue];
        } callbackBlock:^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                self->MainCircleView.hidden = YES;
                file.reverseVideoURL = [NSURL fileURLWithPath:exportPath];
                
                CMTimeRange effectTimeRange = kCMTimeRangeZero;
                AVURLAsset *asset;
                if (self->_timeEffectType == kTimeFilterTyp_Reverse) {
                    asset = [AVURLAsset assetWithURL:file.reverseVideoURL];
                    effectTimeRange = CMTimeRangeMake(kCMTimeZero, file.videoTimeRange.duration);
                }else {
                    asset = [AVURLAsset assetWithURL:file.contentURL];
                    Float64 duration = CMTimeGetSeconds(file.videoTimeRange.duration);
                    if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && !CMTimeRangeEqual(file.videoTrimTimeRange, kCMTimeRangeInvalid)){
                        duration = CMTimeGetSeconds(file.videoTrimTimeRange.duration);
                    }
                    effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(duration/2.0 - (duration/5.0/2.0), TIMESCALE), CMTimeMakeWithSeconds(duration/5.0, TIMESCALE));
                }
                
                if(CMTimeCompare(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), asset.duration) == 1){
                    effectTimeRange.duration = CMTimeSubtract(asset.duration, effectTimeRange.start);
                }
                
                effectTimeRange = CMTimeRangeMake(currentFilterTime, effectTimeRange.duration);
                if( (CMTimeGetSeconds(effectTimeRange.start)+CMTimeGetSeconds(effectTimeRange.duration)) > _videoCoreSDK.duration )
                {
                    effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(_videoCoreSDK.duration - (CMTimeGetSeconds(effectTimeRange.duration)+0.1), TIMESCALE), effectTimeRange.duration);
                }
                self->seekTime = effectTimeRange.start;
                [self refreshVideoCoreWithTimeEffectType:self->_timeEffectType timeEffectTimeRange:effectTimeRange];
                
                startTimeEffect = seekTime;
                
                if( isPlay )
                {
                    fxStartTime = seekTime;
                    if( isPreviewFx )
                        fxTimeRange = CMTimeRangeMake(effectTimeRange.start, CMTimeMakeWithSeconds(1, TIMESCALE));
                    else
                        fxTimeRange = kCMTimeRangeZero;
                    
//                    [self playVideo:YES];
                    _addEffectsByTimeline.timeFxFilter.filterTimeRangel = effectTimeRange;
                }
            });
        } fail:^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                startTimeEffect = currentFilterTime;
//                [self previewFx:nil];
            });
        } cancel:&cancel];
        return;
    }
    
    CMTimeRange effectTimeRange = kCMTimeRangeZero;
    AVURLAsset *asset;
    if (_timeEffectType == kTimeFilterTyp_Reverse) {
        asset = [AVURLAsset assetWithURL:_fileList[0].reverseVideoURL];
        effectTimeRange = CMTimeRangeMake(_fileList[0].videoTrimTimeRange.start, _fileList[0].videoTrimTimeRange.duration);
    }else {
        RDFile *file = _fileList[0];
        CMTimeRange videoTimeRange;
        if(file.isReverse){
            asset = [AVURLAsset assetWithURL:file.reverseVideoURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange) || CMTimeRangeEqual(file.reverseVideoTimeRange, kCMTimeRangeInvalid)) {
                videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
            }else{
                videoTimeRange = file.reverseVideoTimeRange;
            }
            if(CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration) > 0){
                videoTimeRange = file.reverseVideoTrimTimeRange;
            }
        }
        else{
            asset = [AVURLAsset assetWithURL:file.contentURL];
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange) || CMTimeRangeEqual(kCMTimeRangeInvalid, file.videoTimeRange)) {
                videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                videoTimeRange = file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && !CMTimeRangeEqual(file.videoTrimTimeRange, kCMTimeRangeInvalid)){
                videoTimeRange = file.videoTrimTimeRange;
            }
        }
        Float64 duration = CMTimeGetSeconds(videoTimeRange.duration);
        effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(duration/2.0 - (duration/5.0/2.0), TIMESCALE), CMTimeMakeWithSeconds(duration/5.0, TIMESCALE));
    }
    
    if(CMTimeCompare(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), asset.duration) == 1){
        effectTimeRange.duration = CMTimeSubtract(asset.duration, effectTimeRange.start);
    }

    effectTimeRange = CMTimeRangeMake(currentFilterTime, effectTimeRange.duration);
    if( (CMTimeGetSeconds(effectTimeRange.start)+CMTimeGetSeconds(effectTimeRange.duration)) > _videoCoreSDK.duration )
    {
        effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(_videoCoreSDK.duration - (CMTimeGetSeconds(effectTimeRange.duration)+0.1), TIMESCALE), effectTimeRange.duration);
    }
    seekTime = effectTimeRange.start;
    [self refreshVideoCoreWithTimeEffectType:_timeEffectType timeEffectTimeRange:effectTimeRange];
    
    startTimeEffect = seekTime;
    
    if( isPlay )
    {
        fxStartTime = seekTime;
        
        if( isPreviewFx )
            fxTimeRange = CMTimeRangeMake(effectTimeRange.start, CMTimeMakeWithSeconds(1, TIMESCALE));
        else
            fxTimeRange = kCMTimeRangeZero;
        
        _addEffectsByTimeline.timeFxFilter.filterTimeRangel = effectTimeRange;
    }
}
//进度提示
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
    
    startTimeEffect = currentFilterTime;
//    [self previewFx:nil];
}
//时间特效实现
- (void)refreshVideoCoreWithTimeEffectType:(TimeFilterType)timeEffectType timeEffectTimeRange:(CMTimeRange)effectTimeRange {
    NSLog(@"effectTimeRange start:%@  duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, effectTimeRange.start)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, effectTimeRange.duration)));
    
    _effectTimeRange = effectTimeRange;
    [RDGenSpecialEffect refreshVideoTimeEffectType:timeEffectType timeEffectTimeRange:effectTimeRange atscenes:scenes atFile:_fileList[0]];
    [_videoCoreSDK setScenes:scenes];
    [_videoCoreSDK build];
}

#pragma mark- 视频背景
//颜色选项
-( UIButton * )ColorBtn:(UIButton *)previousBtn atColor:(UIColor *)color
{
    UIButton * btn = nil;
    if( previousBtn == nil )
       btn = [[UIButton alloc] initWithFrame:CGRectMake(1, 1, 40.0*4.0/3.0, 40.0)];
    else
       btn = [[UIButton alloc] initWithFrame:CGRectMake(previousBtn.frame.size.width + previousBtn.frame.origin.x, 0, 40.0*4.0/3.0, 40.0)];

    btn.backgroundColor = color;
    return btn;
}

#pragma mark- SubtitleColorControlDelegate
-(void)SubtitleColorChanged:(UIColor *) color Index:(int) index View:(UIControl *) SELF
{
    RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
    scene.backgroundAsset = nil;
    scene.backgroundColor = color;
    
    [_videoCoreSDK refreshCurrentFrame];
}

//图片模糊
-(UIImage *)coreBlurImage:(UIImage *)image
           withBlurNumber:(CGFloat)blur {
    //博客园-FlyElephant
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    CIImage  *inputImage=[CIImage imageWithCGImage:image.CGImage];
    //设置filter
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:@(blur) forKey: @"inputRadius"];
    //模糊图片
    CIImage *result=[filter valueForKey:kCIOutputImageKey];
    CGImageRef outImage=[context createCGImage:result fromRect:[result extent]];
    UIImage *blurImage=[UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    return blurImage;
}

#pragma mark - 比例
-(UIView *)proportionView
{
    if( !_proportionView )
    {
        _proportionView = [[UIView alloc] initWithFrame:bottomViewRect];
        _proportionView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_proportionView];
        NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:RDLocalizedString(@"原比例", nil),@"title",@(kCropTypeOriginal),@"id", nil];
        NSDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:@"1:1",@"title",@(kCropType1v1),@"id", nil];
        NSDictionary *dic3 = [NSDictionary dictionaryWithObjectsAndKeys:@"16:9",@"title",@(kCropType16v9),@"id", nil];
        NSDictionary *dic4 = [NSDictionary dictionaryWithObjectsAndKeys:@"9:16",@"title",@(kCropType9v16),@"id", nil];
        NSDictionary *dic5 = [NSDictionary dictionaryWithObjectsAndKeys:@"4:3",@"title",@(kCropType4v3),@"id", nil];
        NSDictionary *dic6 = [NSDictionary dictionaryWithObjectsAndKeys:@"3:4",@"title",@(kCropType3v4),@"id", nil];
        
        NSMutableArray * proportionItems = [NSMutableArray array];
        [proportionItems addObject:dic1];
        [proportionItems addObject:dic2];
        [proportionItems addObject:dic3];
        [proportionItems addObject:dic4];
        [proportionItems addObject:dic5];
        [proportionItems addObject:dic6];
        
        _proportionBtnItems = [NSMutableArray array];
        
        [proportionItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *dic = (NSDictionary *) obj;
            [_proportionBtnItems addObject:[self ProportionalButton:idx atDic:dic]];
            
        }];
        
        _proportionView.hidden = YES;
    }
    return _proportionView;
}

-(UIButton *)ProportionalButton:(int) index atDic:(NSDictionary *) dic
{
    float toolItemBtnWidth = kWIDTH/6.0;
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = [[dic objectForKey:@"id"] integerValue];
    btn.backgroundColor = [UIColor clearColor];
    btn.exclusiveTouch = YES;
    btn.frame = CGRectMake( index * toolItemBtnWidth, _proportionView.frame.size.height/4.0, toolItemBtnWidth, _proportionView.frame.size.height/2.0);
    [btn addTarget:self action:@selector(proportionItem:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:[dic objectForKey:@"title"] forState:UIControlStateNormal];
    [btn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
    [btn setTitleColor:Main_Color forState:UIControlStateSelected];
    btn.titleLabel.font = [UIFont systemFontOfSize:11];
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [btn setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:btn.tag]] forState:UIControlStateNormal];
    UIImage *selectedImage = [UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:btn.tag]];
    [btn setImage:selectedImage forState:UIControlStateSelected];
    [btn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
    [btn setTitleEdgeInsets:UIEdgeInsetsMake(44, -44, 0, 0)];
    [_proportionView addSubview:btn];
    
    if( selectProportionIndex == btn.tag )
        btn.selected = YES;
    return btn;
}

-(void)Adjproportion:(NSInteger) index
{
    selectProportionIndex = index;
    [self playVideo:NO];
    float width = MAX(proportionVideoSize.width, proportionVideoSize.height);
    switch ( index ) {
        case kCropType1v1://正方形
            selectVideoSize = CGSizeMake(width, width);
            break;
        case kCropType16v9://16:9
            selectVideoSize = CGSizeMake(width, (9.0/16.0) * width);
            break;
        case kCropType9v16://9:16
            selectVideoSize = CGSizeMake((9.0/16.0) * width, width);
            break;
        case kCropType4v3://4:3
            selectVideoSize = CGSizeMake(width, (3.0/4.0) * width);
            break;
        case kCropType3v4://3:4
            selectVideoSize = CGSizeMake((3.0/4.0) * width, width);
            break;
        default://原始
            selectVideoSize =  proportionVideoSize;
            break;
    }
    if( isNoBackground ) {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

            [self canvasFileCrop:obj atfileCropModeType:selectProportionIndex atEditSize:proportionVideoSize];

            if( obj.BackgroundFile )
            {
                [self canvasFileCrop:obj.BackgroundFile atfileCropModeType:selectProportionIndex atEditSize:proportionVideoSize];
            }
        }];
    }
    else
    {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.crop = CGRectMake( 0 , 0, 1.0, 1.0);
            obj.cropRect = CGRectMake(0, 0, 0, 0);
            obj.fileCropModeType = selectProportionIndex;
        }];
    }
    selectProportionIndex = index;
    [self refreshCaptionsEtcSize:selectVideoSize array:subtitles];
//    [self refreshCaptionsEtcSize:selectVideoSize array:stickers];
    [self refreshSticker];
//    [self refreshCaptionsEtcSize:selectVideoSize array:mosaics];
    _exportVideoSize = selectVideoSize;
    _addEffectsByTimeline.exportSize = _exportVideoSize;
    [self initPlayer];
    [_videoCoreSDK setEditorVideoSize:_exportVideoSize];
    [self refreshCaptions];
}

-(void) proportionItem:(UIButton *)sender{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    [_proportionBtnItems enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == sender.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
    seekTime = _videoCoreSDK.currentTime;
    [self Adjproportion:sender.tag];
}

//分辨率调整后，字幕等的大小也要做相应的调整
- (void)refreshCaptionsEtcSize:(CGSize)newVideoSize array:(NSMutableArray<RDCaption*>*)array {
    CGSize oldVideoActualSize = AVMakeRectWithAspectRatioInsideRect(_exportVideoSize, _playerView.bounds).size;
    float  oldScale = _exportVideoSize.width/oldVideoActualSize.width;
    CGSize newVideoActualSize = AVMakeRectWithAspectRatioInsideRect(newVideoSize, _playerView.bounds).size;
    float  newScale = newVideoSize.width/newVideoActualSize.width;
    
    for (RDCaption *caption in array) {
        CGSize size = CGSizeMake(caption.size.width * _exportVideoSize.width / oldScale, caption.size.height * _exportVideoSize.height / oldScale);
        caption.size = CGSizeMake(size.width * newScale / newVideoSize.width, size.height * newScale / newVideoSize.height);
        float fontSize = caption.tFontSize/oldScale;
        caption.tFontSize = fontSize * newScale;
        
        CGRect textRect = CGRectMake(caption.tFrame.origin.x / oldScale, caption.tFrame.origin.y / oldScale, caption.tFrame.size.width / oldScale, caption.tFrame.size.height / oldScale);
        caption.tFrame = CGRectMake(textRect.origin.x * newScale, textRect.origin.y * newScale, textRect.size.width * newScale, textRect.size.height * newScale);
    }
}

- (void)refreshSticker {
    CGSize newVideoActualSize = AVMakeRectWithAspectRatioInsideRect(selectVideoSize, _playerView.bounds).size;
    for (int i = 0; i < stickerFiles.count; i++) {
        RDCaptionRangeViewFile *file = stickerFiles[i];
        float rectW = file.rectW;
        float imageW = file.frameSize.width;
        float imageH = file.frameSize.height;
        double sizeW = newVideoActualSize.width * rectW;
        double sizeH = sizeW * (imageH / imageW);
        
        RDCaption *caption = stickers[i];
        caption.size = CGSizeMake(rectW, sizeH / newVideoActualSize.height);
//        NSLog(@"caption.size:%@", NSStringFromCGSize(caption.size));
    }
}

- (void)refreshCollageSize:(CGSize)newVideoSize {
    CGSize oldVideoActualSize = AVMakeRectWithAspectRatioInsideRect(_exportVideoSize, _playerView.bounds).size;
    CGSize newVideoActualSize = AVMakeRectWithAspectRatioInsideRect(newVideoSize, _playerView.bounds).size;
    
    for (RDWatermark *collage in collages) {
        CGRect rect = collage.vvAsset.rectInVideo;
        CGPoint origin = CGPointMake(rect.origin.x + rect.size.width/2.0, rect.origin.y + rect.size.height/2.0);
        origin = CGPointMake(origin.x * oldVideoActualSize.width, origin.y * oldVideoActualSize.height);
        
        CGPoint point = CGPointMake(origin.x/newVideoActualSize.width, origin.y/newVideoActualSize.height);
        CGRect newRect = CGRectMake(point.x - rect.size.width/2.0, point.y - rect.size.height/2.0, rect.size.width, rect.size.height);
        collage.vvAsset.rectInVideo = newRect;
    }
}

/**获取比例图标地址
 */
- (NSString *)proportionItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case kCropTypeOriginal:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无@3x" Type:@"png"];
            break;
        case kCropType1v1:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例1-1@3x" Type:@"png"];
            break;
        case kCropType16v9:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例16-9@3x" Type:@"png"];
            break;
        case kCropType9v16:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例9-16@3x" Type:@"png"];
            break;
        case kCropType4v3://4:3
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例4-3@3x" Type:@"png"];
            break;
        case kCropType3v4://3:4
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例3-4@3x" Type:@"png"];
            break;
        default:
            break;
    }
    return imagePath;
}

- (NSString *)proportionItemsSelectImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case kCropTypeOriginal:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无-选中@3x" Type:@"png"];
            break;
        case kCropType1v1:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例1-1-选中@3x" Type:@"png"];
            break;
        case kCropType16v9:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例16-9-选中@3x" Type:@"png"];
            break;
        case kCropType9v16:
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例9-16-选中@3x" Type:@"png"];
            break;
        case kCropType4v3://4:3
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例4-3-选中@3x" Type:@"png"];
            break;
        case kCropType3v4://3:4
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/3-4-选中@3x" Type:@"png"];
            break;
        default:
            break;
    }
    return imagePath;
}

#pragma mark- 图片运动
-( UIView* )contentMagnificationView
{
    if( !_contentMagnificationView )
    {
        _contentMagnificationView = [[UIView alloc] initWithFrame:bottomViewRect];
        _contentMagnificationView.backgroundColor = TOOLBAR_COLOR;
        if(!self.contentMagnificationBtn.superview)
            [_contentMagnificationView addSubview:_contentMagnificationBtn ];
        _contentMagnificationView.hidden = YES;
        [self.view addSubview:_contentMagnificationView];
    }
    return _contentMagnificationView;
}

-(UISwitch *)contentMagnificationBtn
{
    if(!_contentMagnificationBtn)
    {
        _contentMagnificationBtn = [[UISwitch alloc] initWithFrame:CGRectMake( _contentMagnificationView.frame.size.width - 10 - 60, (_contentMagnificationView.frame.size.height-30)/2.0, 60, 30)];
        _contentMagnificationBtn.onTintColor=Main_Color;
        _contentMagnificationBtn.tintColor=Main_Color;
        _contentMagnificationBtn.thumbTintColor= [UIColor whiteColor];
        [_contentMagnificationBtn setOn:oldIsEnlarge animated:NO];
        [_contentMagnificationBtn addTarget:self action:@selector(getValue1:) forControlEvents:UIControlEventValueChanged];
        _contentMagnificationBtn.transform = CGAffineTransformMakeScale( 0.7, 0.7);//缩放
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, (_contentMagnificationView.frame.size.height-80)/2.0, _contentMagnificationView.frame.size.width - 10 - 70, 80)];
        label.text = RDLocalizedString(@"启用动画（仅限图片）", nil);
        label.font  = [UIFont systemFontOfSize:13];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor whiteColor];
        [_contentMagnificationView addSubview:label];
        
    }
    return _contentMagnificationBtn;
}

-(void)getValue1:(UISwitch *)sender{
    isEnlarge = sender.on;
    if([_videoCoreSDK isPlaying]) {
        [self playVideo:NO];
    }
    [self initPlayer];
}

#pragma mark - 封面
-(void)initCover
{
    [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.1];
}

- (void)setCover:(UIButton *)sender {
    if (sender.tag == 1) {
        _bottomThumbnailView.hidden = NO;
        coverAuxView.hidden = NO;
    }else {
        WeakSelf(self);
        if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]){
            [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideoAndImageResult:self.navigationController callbackBlock:^(NSMutableArray <NSURL *>* _Nonnull lists) {
                [weakSelf setCoverFileWithUrl:[lists firstObject]];
            }];
        }else if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
            [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray <NSURL *>* _Nonnull lists) {
                [weakSelf setCoverFileWithUrl:[lists firstObject]];
            }];
        }else {
            WeakSelf(self);
            RDMainViewController *mainVC = [[RDMainViewController alloc] init];
            mainVC.showPhotos = YES;
            mainVC.textPhotoProportion = _exportVideoSize.width/_exportVideoSize.height;
            mainVC.inVideoSize = _exportVideoSize;
            mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {                
                StrongSelf(self);
                strongSelf->coverAuxView.hidden = YES;
                RDFile *file = [filelist firstObject];
                strongSelf->coverFile = nil;
                strongSelf->coverFile = file;
                UIImage *image = [RDHelpClass getFullScreenImageWithUrl:strongSelf->coverFile.contentURL];
                if (CGRectEqualToRect(file.crop, CGRectMake(0, 0, 1, 1))) {
                    strongSelf->coverFile.crop = [RDHelpClass getCropWithImageSize:image.size videoSize:strongSelf.exportVideoSize];
                }
                image = [RDHelpClass image:image rotation:file.rotate cropRect:file.crop];
                strongSelf->coverIV.image = image;
            };
            RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
            [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
            nav.editConfiguration.mediaCountLimit =  1;
            nav.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
            nav.navigationBarHidden = YES;
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}

- (void)setCoverFileWithUrl:(NSURL *)url {
    coverAuxView.hidden = YES;
    coverFile = nil;
    coverFile = [RDFile new];
    coverFile.contentURL = url;
    coverFile.fileType = kFILEIMAGE;
    coverIV.image = [RDHelpClass getImageFromUrl:url crop:CGRectZero cropImageSize:_exportVideoSize];
    UIImage *image = [RDHelpClass getFullScreenImageWithUrl:coverFile.contentURL];
    coverFile.crop = [RDHelpClass getCropWithImageSize:image.size videoSize:_exportVideoSize];
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
            case RDAdvanceEditType_Effect:
            {
                if (view.file.customFilter) {
                    isHasMaterialEffect = YES;
                }
            }
                break;
            case RDAdvanceEditType_Doodle:
                if (view.file.doodle) {
                    isHasMaterialEffect = YES;
                }
                break;
            case RDAdvanceEditType_Collage:
                if (view.file.collage) {
                    isHasMaterialEffect = YES;
                }
                break;
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
                if (view.file.caption) {
                    isHasMaterialEffect = YES;
                }
                if (_isAddingMaterialEffect && selecteFunction == RDAdvanceEditType_Subtitle && view == _addEffectsByTimeline.trimmerView.currentCaptionView) {
                    index = view.file.captionId;
                }
                break;
            case RDAdvanceEditType_Dewatermark:
                if (view.file.blur || view.file.mosaic || view.file.dewatermark) {
                    isHasMaterialEffect = YES;
                }
                break;
            case RDAdvanceEditType_Multi_track:
                if (view.file.music) {
                    isHasMaterialEffect = YES;
                }
                break;
            case RDAdvanceEditType_Sound:
                if (view.file.music) {
                    isHasMaterialEffect = YES;
                }
                break;
            default:
                break;
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
                    if (image) {
                        imageView.image = image;
                    }else {
                        imageView.image = [RDHelpClass imageWithContentOfFile:@"subtitleCover"];
                    }
                }
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [addedItemBtn addSubview:imageView];
            }
            else if (selecteFunction == RDAdvanceEditType_Dewatermark) {
                if (view.file.captiontypeIndex == RDDewatermarkType_Blur) {
                    [addedItemBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/mosaic_blur_n"] forState:UIControlStateNormal];
                }else if (view.file.captiontypeIndex == RDDewatermarkType_Mosaic) {
                    [addedItemBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/去水印_马赛克1默认_"] forState:UIControlStateNormal];
                }else {
                    [addedItemBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/去水印_去水印1默认_"] forState:UIControlStateNormal];
                }
                addedItemBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
            else if ( selecteFunction == RDAdvanceEditType_Multi_track)
            {
                [addedItemBtn setTitle:view.file.music.name forState:UIControlStateNormal];
                [addedItemBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
                [addedItemBtn.titleLabel sizeToFit];
                addedItemBtn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
                addedItemBtn.titleLabel.font = [UIFont systemFontOfSize:7];
                addedItemBtn.titleLabel.numberOfLines = 0;
            }
            else if ( selecteFunction == RDAdvanceEditType_Sound)
            {
                [addedItemBtn setTitle:view.file.music.name forState:UIControlStateNormal];
                [addedItemBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
                [addedItemBtn.titleLabel sizeToFit];
                addedItemBtn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
                addedItemBtn.titleLabel.font = [UIFont systemFontOfSize:7];
                addedItemBtn.titleLabel.numberOfLines = 0;
            }
            else if( selecteFunction == RDAdvanceEditType_Effect ){
                [addedItemBtn setTitle:view.file.customFilter.nameStr forState:UIControlStateNormal];
                [addedItemBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
                [addedItemBtn.titleLabel sizeToFit];
                addedItemBtn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
                addedItemBtn.titleLabel.font = [UIFont systemFontOfSize:7];
                addedItemBtn.titleLabel.numberOfLines = 0;
            }
            else {
                [addedItemBtn setImage:view.file.thumbnailImage forState:UIControlStateNormal];
            }
            
            
            if ( (selecteFunction != RDAdvanceEditType_Multi_track) || (selecteFunction != RDAdvanceEditType_Sound) )
            {
                addedItemBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
            }
            addedItemBtn.tag = view.file.captionId;
            [addedItemBtn addTarget:self action:@selector(addedMaterialEffectItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            
//            CGRectMake(0, addedMaterialEffectScrollView.bounds.size.height - 27, 27, 27)]
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
    if ( ( (selecteFunction == RDAdvanceEditType_Subtitle) || (selecteFunction == RDAdvanceEditType_Sticker) ) && _isAddingMaterialEffect && !_isEdittingMaterialEffect) {
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
    
    [self TimesFor_videoRangeView_withTime:0];
}

- (void)addedMaterialEffectItemBtnAction:(UIButton *)sender {
    if (!selectedMaterialEffectItemIV.hidden && sender.tag == selectedMaterialEffectIndex) {
        return;
    }
    if (_videoCoreSDK.isPlaying) {
        [self playVideo:NO];
    }
    seekTime = _videoCoreSDK.currentTime;
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
    if( (selecteFunction == RDAdvanceEditType_Sound)
       || ( selecteFunction == RDAdvanceEditType_Multi_track ))
    {
        [_addedMusicVolumeSlider setValue:_addEffectsByTimeline.trimmerView.currentCaptionView.file.music.volume/volumeMultipleM];
        self.addedMusicVolumeView.hidden = NO;
        _addEffectsByTimeline.finishBtn.hidden = NO;
        _addEffectsByTimeline.addBtn.hidden = YES;
    }
    if (selecteFunction != RDAdvanceEditType_Subtitle && selecteFunction != RDAdvanceEditType_Sticker && selecteFunction != RDAdvanceEditType_Doodle ) {
        CMTime time = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
        [_videoCoreSDK filterRefresh:time];
    }
    if( selecteFunction == RDAdvanceEditType_Doodle )
    {
        seekTime = CMTimeAdd(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start, CMTimeMakeWithSeconds(0.2, TIMESCALE));
        [_videoCoreSDK seekToTime:seekTime toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
        [_videoCoreSDK filterRefresh:seekTime];
    }
    _addEffectsByTimeline.trimmerView.isJumpTail = false;
}

#pragma mark - RDAddEffectsByTimelineDelegate

-(void)seekToTime:(CMTime)time
{
    [_videoCoreSDK seekToTime:time];
}

- (void)pauseVideo {
    [self playVideo:NO];
}

- (void)playOrPauseVideo {
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)previewWithTimeRange:(CMTimeRange)timeRange {
    playTimeRange = timeRange;
    [self playVideo:YES];
}

- (void)changeCurrentTime:(float)currentTime {
    if( (![_videoCoreSDK isPlaying]) && ( !isRecording ) ){
        WeakSelf(self);
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(currentTime, TIMESCALE) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = strongSelf.videoCoreSDK.duration;
            if(CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
        {
            float currTime = currentTime;
            self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(currTime, _videoCoreSDK.duration)];
            float progress = currTime/_videoCoreSDK.duration;
            switch (selecteFunction) {
                case RDAdvanceEditType_Dubbing:
                case RDAdvanceEditType_Effect:
                case RDAdvanceEditType_Subtitle:
                case RDAdvanceEditType_Sticker:
                case RDAdvanceEditType_Dewatermark:
                case RDAdvanceEditType_Doodle:
                case RDAdvanceEditType_Collage:
                case RDAdvanceEditType_Multi_track:
                case RDAdvanceEditType_Sound:
                    VideoCurrentTime = progress;
                    break;
                default:
                    break;
            }
        }
    }
    _captionVideoCurrentTimeLbl.text = [RDHelpClass timeToStringFormat:currentTime];
}

- (void)addMaterialEffect {
    _addEffectsByTimeline.hidden = NO;
    if( [_videoCoreSDK isPlaying] )
        [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Effect:
            self.isAddingMaterialEffect = YES;
            seekTime = _videoCoreSDK.currentTime;
            break;
        case RDAdvanceEditType_Doodle:
            
            [self showPrompt:RDLocalizedString(@"请在视频上绘制涂鸦", nil)];
            
            _isAddingMaterialEffect = YES;
            seekTime = _videoCoreSDK.currentTime;
            break;
        case RDAdvanceEditType_Subtitle:
            _toolbarTitleView.hidden = YES;
            self.isAddingMaterialEffect = YES;
            break;
        case RDAdvanceEditType_Sticker:
            if( (stickers == nil) || (stickers.count == 0) )
                _addEffectsByTimeline.hidden = YES;
            _toolbarTitleView.hidden = YES;
            seekTime = _videoCoreSDK.currentTime;
            break;
        case RDAdvanceEditType_Collage:
        {
            toolbarTitleLbl.hidden = YES;
            if (!_isEdittingMaterialEffect) {
                seekTime = _videoCoreSDK.currentTime;
            }
            _isAddingMaterialEffect = YES;
            __weak typeof(self) myself = self;
            if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]){
                
                [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideoAndImageResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    [myself.addEffectsByTimeline addCollage:[lists firstObject] thumbImage:nil];
                }];
                return;
            }
            
            if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)]){
                
                [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideosResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    [myself.addEffectsByTimeline addCollage:[lists firstObject] thumbImage:nil];
                }];
                return;
            }
            if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
                
                [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                    [myself.addEffectsByTimeline addCollage:[lists firstObject] thumbImage:nil];
                    
                    
                }];
                return;
            }
            [_addEffectsByTimeline showAlbumView];
            seekTime = _videoCoreSDK.currentTime;
        }            
            break;
        case RDAdvanceEditType_Dewatermark:
            self.isAddingMaterialEffect = YES;
            break;
        case RDAdvanceEditType_Multi_track:
            _toolbarTitleView.hidden = YES;
            seekTime = _videoCoreSDK.currentTime;
            break;
        case RDAdvanceEditType_Sound:
            _toolbarTitleView.hidden = YES;
            seekTime = _videoCoreSDK.currentTime;
            self.addEffectsByTimeline.hidden = YES;
            break;
        default:
            break;
    }
    self.isEdittingMaterialEffect = NO;
    _addedMaterialEffectView.hidden = YES;
    if (selecteFunction == RDAdvanceEditType_Collage) {
        toolbarTitleLbl.hidden = YES;
    }else {
        toolbarTitleLbl.hidden = NO;
    }
}

-(void)collage_initPlay
{
//    float time = CMTimeGetSeconds(seekTime);
//    if (time >= _videoCoreSDK.duration) {
//        seekTime = kCMTimeZero;
//    }
    seekTime = _videoCoreSDK.currentTime;
    [self initPlayer];
}

-(void)addingMusic:(RDMusic *) music
{
    self.addedMusicVolumeView.hidden = NO;
    [_addedMusicVolumeSlider setValue:music.volume/volumeMultipleM];
    self.isAddingMaterialEffect = YES;
    if( _audioPlayer )
    {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    [self initAudioPlayer:music];
    _toolbarTitleView.hidden = NO;
    cancelBtn.hidden = YES;
    _toolbarTitlefinishBtn.hidden = YES;
    [self playVideo:YES];
}
//音频播放器
- (void)initAudioPlayer:(RDMusic *) music{
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:music.url error:&error];
    _audioPlayer.volume = music.volume;
    _audioStart = CMTimeGetSeconds(music.clipTimeRange.start);
    _audioDuration = CMTimeGetSeconds(music.clipTimeRange.duration) + _audioStart;
    _audioPlayer.currentTime = _audioStart ;
    _audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateAduioProgress) userInfo:nil repeats:YES];
    _audioPlayer.delegate = self;
    [_audioPlayer play];
}
-(void)audioPlayerStop
{
    [_audioPlayer stop];
    _audioPlayer = nil;
    
    [_audioTimer invalidate];
    _audioTimer = nil;
}
/*
 更新播放器进度
 */
- (void)updateAduioProgress{
    if( !_audioPlayer )
        return;
    
    if( ![_audioPlayer isPlaying] )
    {
        _audioPlayer.currentTime = _audioStart;
        [_audioPlayer play];
    }
    
    double currentTime = _audioPlayer.currentTime;
    if( currentTime < _audioDuration )
    {
        
    }
    else
    {
        _audioPlayer.currentTime = _audioStart;
        [_audioPlayer play];
    }
}

- (void)addingStickerWithDuration:(float)addingDuration captionId:(int ) captionId{
    NSMutableArray *arry = [[NSMutableArray alloc] initWithArray:subtitles];
    [arry addObjectsFromArray:stickers];
    _videoCoreSDK.captions = arry;
    addingMaterialDuration = addingDuration;
    _addEffectsByTimeline.hidden = NO;
    self.isAddingMaterialEffect = YES;
    _toolbarTitleView.hidden = NO;
//    cancelBtn.hidden = YES;
//    _toolbarTitlefinishBtn.hidden = YES;
    if(![_videoCoreSDK isPlaying]){
        _addEffectsByTimeline.trimmerView.isTiming = YES;
        _videoTrimmerView.isTiming = YES;
        if( VideoCurrentTime != 0 )
            seekTime = CMTimeMakeWithSeconds(VideoCurrentTime*_videoCoreSDK.duration, TIMESCALE);
        [_videoCoreSDK seekToTime:seekTime toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            seekTime = kCMTimeZero;
//            [self playVideo:YES];
        }];
    }
    
    [self addedMaterialEffectItemBtnAction:[addedMaterialEffectScrollView viewWithTag:captionId]];
}

- (void)cancelMaterialEffect {
    
    bool trimmerViewIsTiming = _addEffectsByTimeline.trimmerView.isTiming;
    
    
    self.addedMusicVolumeView.hidden = YES;
    self.isCancelMaterialEffect = YES;
    [self deleteMaterialEffect];
    self.isCancelMaterialEffect = NO;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    
    toolbarTitleLbl.hidden = YES;
    cancelBtn.hidden = NO;
    _toolbarTitlefinishBtn.hidden = NO;
    
    NSMutableArray *filArray = nil;
    switch (selecteFunction) {
        case RDAdvanceEditType_Effect:
            filArray = fXArray;
            _addEffectsByTimeline.trimmerView.isTiming = false;
            break;
        case RDAdvanceEditType_Collage:
            filArray = collages;
            break;
        case RDAdvanceEditType_Doodle:
            filArray =  doodles;
            break;
        case RDAdvanceEditType_Subtitle:
            filArray = subtitles;
            break;
        case RDAdvanceEditType_Multi_track:
            filArray = musics;
            break;
        case RDAdvanceEditType_Sound:
            filArray = soundMusics;
            break;
        default:
            break;
    }
    switch (selecteFunction) {
        case RDAdvanceEditType_Effect:
        {
            if(fXArray.count > 0)
                _addedMaterialEffectView.hidden = NO;
            else
                toolbarTitleLbl.hidden = NO;
        }
            break;
        case RDAdvanceEditType_Sticker:
        {
            if(stickers.count > 0)
                _addedMaterialEffectView.hidden = NO;
            else
                toolbarTitleLbl.hidden = NO;
        }
            break;
        case RDAdvanceEditType_Dewatermark:
        {
            if(blurs.count > 0 || mosaics.count > 0 || dewatermarks.count > 0)
                _addedMaterialEffectView.hidden = NO;
            else
                toolbarTitleLbl.hidden = NO;
        }
            break;
        default:
        {
            if( (filArray != nil) && filArray.count > 0 )
                _addedMaterialEffectView.hidden = NO;
            else
                toolbarTitleLbl.hidden = NO;
        }
            break;
    }
    
    if( trimmerViewIsTiming )
    {
        if(isAdd)
        {
            [self back:nil];
        }
    }
}

-(void)deleteMaterialEffect_Effect:(NSString *) strPatch
{
    if( strPatch )
    {
        for (int i = 0; i < _fileList.count; i++) {
            
            if( _fileList[i].fileType == kFILEIMAGE )
            {
                if( ! [RDHelpClass isSystemPhotoUrl:_fileList[i].contentURL]  )
                {
                    NSString * patch = [_fileList[i].contentURL absoluteString];
                    if( [patch containsString:strPatch] )
                    {
                        isFXUpdate = true;
                        [_fileList removeObjectAtIndex:i];
                        seekTime = _videoCoreSDK.currentTime;
                        isRecording = false;
                        [self performSelector:@selector(initPlayer) withObject:nil afterDelay:0.1];
                        break;
                    }
                }
            }
        }
    }
    else
    {
        _addEffectsByTimeline.trimmerView.timeEffectCapation = nil;
        _timeEffectType = kTimeFilterTyp_None;
        [self initPlayer];
    }
}

- (void)deleteMaterialEffect {
    self.addedMusicVolumeView.hidden = YES;
    
    cancelBtn.hidden = NO;
    _toolbarTitlefinishBtn.hidden = NO;
    
    [self playVideo:NO];
    if (!_isCancelMaterialEffect) {
        seekTime = _videoCoreSDK.currentTime;
    }
    isNotNeedPlay = YES;
    if (!cancelBtn.selected) {
        isModifiedMaterialEffect = YES;
    }
    
    if (_isCancelMaterialEffect) {
        seekTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start) + _addEffectsByTimeline.trimmerView.piantouDuration,TIMESCALE);
    }
    BOOL suc = [_addEffectsByTimeline.trimmerView deletedcurrentCaption];
    BOOL isAddedMaterialEffectScrollViewShow = NO;
    if(suc){
        NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
        switch (selecteFunction) {
                
            case RDAdvanceEditType_Effect:
            {
                [fXArray removeAllObjects];
                [fXFiles removeAllObjects];
                
                fXArray = [[NSMutableArray alloc] init];
                fXFiles = [[NSMutableArray alloc] init];
                
                for(CaptionRangeView *view in arr){
                    RDFXFilter *fxFilter = view.file.customFilter;
                    [fXArray addObject:fxFilter];
                    [fXFiles addObject:view.file];
                }
                isAddedMaterialEffectScrollViewShow = (fXArray.count > 0);
                //待定特效
                
                NSMutableArray * array = [[NSMutableArray alloc] init];
                [fXArray enumerateObjectsUsingBlock:^(RDFXFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if( obj.FXTypeIndex < 5 )
                    {
                        [array addObject:obj.customFilter];
                    }
                }];
                
                [self refreshMaterialEffectArray:customFilterArray newArray:array];
            }
                break;
                
            case RDAdvanceEditType_Collage:
            {
                bool isBuild = true;
                
                if( ( arr == nil ) || ( arr.count == 0 ) )
                {
                    if( (collages == nil) && ( collages.count == 0  ) )
                        isBuild = false;
                }
                if( isBuild )
                {
                    [collages removeAllObjects];
                    [collageFiles removeAllObjects];
                    
                    for(CaptionRangeView *view in arr){
                        RDWatermark *collage= view.file.collage;
                        if(collage){
                            [collages addObject:collage];
                            [collageFiles addObject:view.file];
                        }
                    }
                    isAddedMaterialEffectScrollViewShow = collages.count;
                    
                    seekTime = _videoCoreSDK.currentTime;
                    
                    [self initPlayer];
                }
                else
                {
                    isAddedMaterialEffectScrollViewShow = false;
                }
            }
                break;
            case RDAdvanceEditType_Doodle:
            {
                [doodles removeAllObjects];
                [doodleFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    RDWatermark *doodle = view.file.doodle;
                    if(doodle){
                        [doodles addObject:doodle];
                        [doodleFiles addObject:view.file];
                    }
                }
                isAddedMaterialEffectScrollViewShow = doodles.count;
                seekTime = _videoCoreSDK.currentTime;
                [self initPlayer];
            }
                break;
            case RDAdvanceEditType_Subtitle:
            {
                [subtitles removeAllObjects];
                [subtitleFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    RDCaption *subtitle = view.file.caption;
                    if(subtitle){
                        [subtitles addObject:subtitle];
                        [subtitleFiles addObject:view.file];
                    }
                }
                isAddedMaterialEffectScrollViewShow = subtitles.count;
                [self refreshCaptions];
                CMTime time = [_videoCoreSDK currentTime];
                [_videoCoreSDK filterRefresh:time];
            }
                break;
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
                CMTime time = [_videoCoreSDK currentTime];
                [_videoCoreSDK filterRefresh:time];
            }
                break;
            case RDAdvanceEditType_Dewatermark:
            {
                [blurs removeAllObjects];
                [blurFiles removeAllObjects];
                [dewatermarks removeAllObjects];
                [dewatermarkFiles removeAllObjects];
                [mosaics removeAllObjects];
                [mosaicFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    if (view.file.blur) {
                        [blurs addObject:view.file.blur];
                        [blurFiles addObject:view.file];
                    }else if (view.file.mosaic) {
                        [mosaics addObject:view.file.mosaic];
                        [mosaicFiles addObject:view.file];
                    }else if (view.file.dewatermark) {
                        [dewatermarks addObject:view.file.dewatermark];
                        [dewatermarkFiles addObject:view.file];
                    }
                }
                isAddedMaterialEffectScrollViewShow = (blurs.count > 0 || mosaics.count > 0 || dewatermarks.count > 0);
                [self refreshDewatermark];
                [_videoCoreSDK refreshCurrentFrame];
            }
                break;
            case RDAdvanceEditType_Multi_track:
            {
                [self audioPlayerStop];
                [musics removeAllObjects];
                [musicFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    RDMusic *music = view.file.music;
                    if(music){
                        [musics addObject:music];
                        [oldMusicFiles addObject:view.file];
                    }
                }
                isAddedMaterialEffectScrollViewShow = musics.count;
                seekTime = _videoCoreSDK.currentTime;
                [self refresMusic];
                [_videoCoreSDK build];
            }
                break;
            case RDAdvanceEditType_Sound:
            {
                [self audioPlayerStop];
                [soundMusics removeAllObjects];
                [soundMusicFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    RDMusic *music = view.file.music;
                    if(music){
                        [soundMusics addObject:music];
                        [oldSoundMusicFiles addObject:view.file];
                    }
                }
                isAddedMaterialEffectScrollViewShow = soundMusics.count;
                [self refresMusic];
                seekTime = _videoCoreSDK.currentTime;
                [_videoCoreSDK build];
            }
                break;
            default:
                break;
        }
    }else{
        NSLog(@"删除失败");
        isNotNeedPlay = NO;
    }
    float progress = VideoCurrentTime;
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
    _toolbarTitleView.hidden = NO;
    refreshCurrentTime = kCMTimeInvalid;
    _addEffectsByTimeline.refreshCurrentTime = kCMTimeInvalid;
}

- (void)beforeUpdateMaterialEffect:(BOOL)isSaveEffect {
    _videoTrimmerView.isTiming = NO;
    cancelBtn.hidden = NO;
    _toolbarTitlefinishBtn.hidden = NO;
    
    if( isSaveEffect )
        self.addedMusicVolumeView.hidden = YES;
    if (!_addEffectsByTimeline.isSettingEffect && selecteFunction != RDAdvanceEditType_Collage) {
        _isAddingMaterialEffect = NO;
    }
    _addEffectsByTimeline.currentTimeLbl.hidden = NO;
    if (_videoCoreSDK.isPlaying) {
        [self playVideo:NO];
    }
    if (!cancelBtn.selected) {
        isModifiedMaterialEffect = YES;
    }
    if (!_isCancelMaterialEffect && !_addEffectsByTimeline.isSettingEffect) {
        seekTime = _videoCoreSDK.currentTime;
    }
    float time = CMTimeGetSeconds(seekTime);
    if (time >= _videoCoreSDK.duration) {
        seekTime = kCMTimeZero;
    }
    self.addedMaterialEffectView.hidden = NO;
}

- (void)updateMaterialEffect:(NSMutableArray *)newEffectArray
                newFileArray:(NSMutableArray *)newFileArray
                isSaveEffect:(BOOL)isSaveEffect
{
    _addEffectsByTimeline.isBuild = FALSE;
    [self beforeUpdateMaterialEffect:isSaveEffect];
    switch (selecteFunction) {
        case RDAdvanceEditType_Effect:
        {
            if (!fXArray) {
                fXArray = [NSMutableArray array];
            }
            if (!fXFiles) {
                fXFiles = [NSMutableArray array];
            }
            [self refreshMaterialEffectArray:fXArray newArray:newEffectArray];
            [self refreshMaterialEffectArray:fXFiles newArray:newFileArray];
            
            
            
            seekTime = _videoCoreSDK.currentTime;
            if( isSaveEffect )
            {
                _addEffectsByTimeline.trimmerView.isTiming = false;
                self.isEdittingMaterialEffect = NO;
            }
            else{
                _isAddingMaterialEffect = YES;
            }
            selectedMaterialEffectItemIV.hidden = YES;
            NSMutableArray * array = [[NSMutableArray alloc] init];
            
            fxTimeRange = kCMTimeRangeZero;
            if( (fXArray != nil) && ( fXArray.count > 0 ) )
            {
                [fXArray enumerateObjectsUsingBlock:^(RDFXFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if( obj.FXTypeIndex < 5 )
                    {
                        [array addObject:obj.customFilter];
                    }
                }];
                [self refreshMaterialEffectArray:customFilterArray newArray:array];
                if( (_addEffectsByTimeline.currentFXLabelIndex == 4) )
                {
                    [self playVideo:NO];
                    
                    _addEffectsByTimeline.fXConfigView.hidden = NO;
                    isFXUpdate = true;
                    
                    seekTime = fXArray[fXArray.count-1].customFilter.timeRange.start;
                    
                    [self operationRating:fXArray[fXArray.count-1].customFilter.timeRange.start];
                    isRecording = false;
                    [self performSelector:@selector(initPlayer) withObject:nil afterDelay:0.1];
                }
                else if( _addEffectsByTimeline.currentFXLabelIndex == 5 )
                {
                    isPreviewFx = false;
                    isFXUpdate = false;
                    
                    if( _timeEffectType !=  fXArray[fXArray.count - 1].timeFilterType)
                    {
                        fxTimeRange = kCMTimeRangeZero;
                        currentFilterTime = fXArray[fXArray.count - 1].filterTimeRangel.start;
                        seekTime = currentFilterTime;
                        _timeEffectType = fXArray[fXArray.count - 1].timeFilterType;
                        isFXUpdateTime = true;
                        [self addTimeEffect:NO];
                    }
                    else
                    
                    {
                        isPreviewFx = false;
                        fxStartTime = kCMTimeZero;
                        fxTimeRange = kCMTimeRangeZero;
                        [_videoCoreSDK seekToTime:seekTime];
                        [self playVideo:YES];
                    }
                }
            }
            
            _addEffectsByTimeline.currentFXLabelIndex = 0;
                 
            cancelBtn.hidden = NO;
            _toolbarTitlefinishBtn.hidden = NO;
        }
            break;
        case RDAdvanceEditType_Doodle:
        {
            if (!doodles) {
                doodles = [NSMutableArray array];
            }
            if (!doodleFiles) {
                doodleFiles = [NSMutableArray array];
            }
            [self refreshMaterialEffectArray:doodles newArray:newEffectArray];
            [self refreshMaterialEffectArray:doodleFiles newArray:newFileArray];
            
            seekTime = _videoCoreSDK.currentTime;
            if( isSaveEffect )
                self.isEdittingMaterialEffect = NO;
            selectedMaterialEffectItemIV.hidden = YES;
            
            [self performSelector:@selector(initPlayer) withObject:nil afterDelay:0.1];
//            [self refreshRdPlayer:_videoCoreSDK];
        }
            break;
        case RDAdvanceEditType_Subtitle:
        {
            if (!subtitles) {
                subtitles = [NSMutableArray array];
            }
            if (!subtitleFiles) {
                subtitleFiles = [NSMutableArray array];
            }
            seekTime = kCMTimeZero;
            [self refreshMaterialEffectArray:subtitles newArray:newEffectArray];
            [self refreshMaterialEffectArray:subtitleFiles newArray:newFileArray];
            [self refreshCaptions];
            _addEffectsByTimeline.hidden = NO;
            _toolbarTitleView.hidden = NO;
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
        }
            break;
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
            _addEffectsByTimeline.hidden = NO;
            _toolbarTitleView.hidden = NO;
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
        }
            break;
        case RDAdvanceEditType_Dewatermark:
            [_videoCoreSDK filterRefresh:seekTime];
            break;
        case RDAdvanceEditType_Collage:
        {
            if (!collages) {
                collages = [NSMutableArray array];
            }
            if (!collageFiles) {
                collageFiles = [NSMutableArray array];
            }
            if (!_isCancelMaterialEffect) {
                
                if( _addEffectsByTimeline.trimmerView.currentCaptionView != nil )
                    seekTime = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
                else
                    seekTime = _videoCoreSDK.currentTime;
                
            }
            float time = CMTimeGetSeconds(seekTime);
            if (time >= _videoCoreSDK.duration) {
                seekTime = kCMTimeZero;
            }
            [self refreshMaterialEffectArray:collages newArray:newEffectArray];
            [self refreshMaterialEffectArray:collageFiles newArray:newFileArray];
            if(_isAddingMaterialEffect)
                [self initPlayer];
        }
            break;
        case RDAdvanceEditType_Multi_track:
        {
            [self audioPlayerStop];
            if (!musics) {
                musics = [NSMutableArray array];
            }
            if (!musicFiles) {
                musicFiles = [NSMutableArray array];
            }
            seekTime = kCMTimeZero;
            [self refreshMaterialEffectArray:musics newArray:newEffectArray];
            [self refreshMaterialEffectArray:musicFiles newArray:newFileArray];
            [self refresMusic];
            _toolbarTitleView.hidden = NO;
            if (!_isCancelMaterialEffect) {
                
                if( _addEffectsByTimeline.trimmerView.isJumpTail )
                    seekTime = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
                else
                    seekTime = _videoCoreSDK.currentTime;
                
            }
            float time = CMTimeGetSeconds(seekTime);
            if (time >= _videoCoreSDK.duration) {
                seekTime = kCMTimeZero;
            }
            if( isSaveEffect )
                [_videoCoreSDK build];
        }
            break;
        case RDAdvanceEditType_Sound:
        {
            [self audioPlayerStop];
            if (!soundMusics) {
                soundMusics = [NSMutableArray array];
            }
            if (!soundMusicFiles) {
                soundMusicFiles = [NSMutableArray array];
            }
            seekTime = kCMTimeZero;
            [self refreshMaterialEffectArray:soundMusics newArray:newEffectArray];
            [self refreshMaterialEffectArray:soundMusicFiles newArray:newFileArray];
            [self refresMusic];
            _toolbarTitleView.hidden = NO;
            if (!_isCancelMaterialEffect) {
                
                if( _addEffectsByTimeline.trimmerView.isJumpTail )
                    seekTime = _addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start;
                else
                    seekTime = _videoCoreSDK.currentTime;
                
            }
            float time = CMTimeGetSeconds(seekTime);
            if (time >= _videoCoreSDK.duration) {
                seekTime = kCMTimeZero;
            }
            if( isSaveEffect )
                [_videoCoreSDK build];
        }
            break;
        default:
            break;
    }
    if (isSaveEffect) {
        [self refreshAddMaterialEffectScrollView];
        [_addEffectsByTimeline.syncContainer removeFromSuperview];
        selectedMaterialEffectItemIV.hidden = YES;
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        refreshCurrentTime = kCMTimeInvalid;
        _addEffectsByTimeline.refreshCurrentTime = kCMTimeInvalid;
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
}

- (void)updateDewatermark:(NSMutableArray *)newBlurArray
         newBlurFileArray:(NSMutableArray *)newBlurFileArray
           newMosaicArray:(NSMutableArray *)newMosaicArray
           newMosaicArray:(NSMutableArray *)newMosaicFileArray
      newDewatermarkArray:(NSMutableArray *)newDewatermarkArray
  newDewatermarkFileArray:(NSMutableArray *)newDewatermarkFileArray
             isSaveEffect:(BOOL)isSaveEffect
{
    [self beforeUpdateMaterialEffect:isSaveEffect];
    if (selecteFunction == RDAdvanceEditType_Dewatermark) {
        if (!_addEffectsByTimeline.isSettingEffect) {
            _addEffectsByTimeline.dewatermarkRectView.hidden = YES;
        }
        if (!blurs) {
            blurs = [NSMutableArray array];
        }
        if (!blurFiles) {
            blurFiles = [NSMutableArray array];
        }
        if (!dewatermarks) {
            dewatermarks = [NSMutableArray array];
        }
        if (!dewatermarkFiles) {
            dewatermarkFiles = [NSMutableArray array];
        }
        if (!mosaics) {
            mosaics = [NSMutableArray array];
        }
        if (!mosaicFiles) {
            mosaicFiles = [NSMutableArray array];
        }
        [self refreshMaterialEffectArray:blurs newArray:newBlurArray];
        [self refreshMaterialEffectArray:blurFiles newArray:newBlurFileArray];
        [self refreshMaterialEffectArray:dewatermarks newArray:newDewatermarkArray];
        [self refreshMaterialEffectArray:dewatermarkFiles newArray:newDewatermarkFileArray];
        [self refreshMaterialEffectArray:mosaics newArray:newMosaicArray];
        [self refreshMaterialEffectArray:mosaicFiles newArray:newMosaicFileArray];
        [self refreshDewatermark];
        if (_addEffectsByTimeline.isSettingEffect) {
            if (CMTimeCompare(refreshCurrentTime, kCMTimeInvalid) == 0) {
                refreshCurrentTime = _videoCoreSDK.currentTime;
            }
            [_videoCoreSDK filterRefresh:refreshCurrentTime];
        }else {
            [self playVideo:NO];
        }
    }
    if (isSaveEffect) {
        [self refreshAddMaterialEffectScrollView];
        [_addEffectsByTimeline.syncContainer removeFromSuperview];
        selectedMaterialEffectItemIV.hidden = YES;
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        refreshCurrentTime = kCMTimeInvalid;
        _addEffectsByTimeline.refreshCurrentTime = kCMTimeInvalid;
    }
    if (!_isEdittingMaterialEffect) {
        if ((newBlurArray.count == 0 && newMosaicArray.count == 0 && newDewatermarkArray.count == 0) || _addEffectsByTimeline.isSettingEffect) {
            _addedMaterialEffectView.hidden = YES;
            toolbarTitleLbl.hidden = NO;
        }else {
            _addedMaterialEffectView.hidden = NO;
            toolbarTitleLbl.hidden = YES;
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

- (void)prepareSpeechRecog {
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if ([lexiu currentReachabilityStatus] == RDNotReachable) {
        [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
        [self.hud show];
        [self.hud hideAfter:2];
    }else {
        [_addEffectsByTimeline startSpeechRecog];
    }
}

- (void)uploadSpeechFailed:(NSString *)errorMessage {
    [self.hud setCaption:errorMessage];
    [self.hud show];
    [self.hud hideAfter:1.0];
}

-(void)TimesFor_videoRangeView_withTime:(int)captionId
{
    if( addedMaterialEffectScrollView == nil )
        return;
    
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

- (void)changeDewatermarkType:(RDDewatermarkType)type dewatermarkRectView:(RDUICliper *)dewatermarkRectView {
    if (!_isEdittingMaterialEffect) {
        if (!blurs) {
            blurs = [NSMutableArray array];
        }
        if (!mosaics) {
            mosaics = [NSMutableArray array];
        }
        if (!dewatermarks) {
            dewatermarks = [NSMutableArray array];
        }
        CMTimeRange timeRange = CMTimeRangeMake(_videoCoreSDK.currentTime, CMTimeSubtract(CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE), _videoCoreSDK.currentTime));
        [_addEffectsByTimeline preAddDewatermark:timeRange
                                           blurs:blurs
                                         mosaics:mosaics
                                    dewatermarks:dewatermarks];
        [self refreshDewatermark];
        [_videoCoreSDK refreshCurrentFrame];
    }
}

//特效
-(void)hiddenView
{
    self.addedMaterialEffectView.hidden = YES;
    cancelBtn.hidden = YES;
    _toolbarTitlefinishBtn.hidden = YES;
    toolbarTitleLbl.hidden = NO;
}

//预览 特效
-(void)previewFx:(RDFXFilter *) fxFilter
{
    [self playVideo:NO];
    if( fxFilter )
    {
        if( currentFxFilter )
        {
            if( (currentFxFilter.FXTypeIndex < 5) && (customFilterArray.count >= 1) )
            {
                currentFxFilter = nil;
                [customFilterArray removeObjectAtIndex:customFilterArray.count-1];
            }
            else
            {
                currentFxFilter = nil;
            }
        }
        
        if(fxFilter.FXTypeIndex < 5)
        {
            currentFxFilter = fxFilter;
            fxTimeRange = CMTimeRangeMake(currentFxFilter.customFilter.timeRange.start, CMTimeMakeWithSeconds(1.0, TIMESCALE));
            fxStartTime = currentFxFilter.customFilter.timeRange.start;
            [customFilterArray addObject:currentFxFilter.customFilter];
            if( _timeEffectType != kTimeFilterTyp_None )
            {
                _timeEffectType = kTimeFilterTyp_None;
                isPreviewFx = true;
                seekTime = fxStartTime;
                [self initPlayer];
            }
            else
            {
                isPreviewFx = false;
                [self playVideo:YES];
            }
        }
        else
        {
            currentFxFilter = fxFilter;
            currentFilterTime = _videoCoreSDK.currentTime;
            _timeEffectType = currentFxFilter.timeFilterType;
            isPreviewFx = true;
            [self addTimeEffect:YES];
        }
    }
    else
    {
        fxTimeRange = kCMTimeRangeZero;
        
        if( currentFxFilter )
        {
            if( (currentFxFilter.FXTypeIndex < 5) && (customFilterArray.count >= 1) )
            {
                fxTimeRange = kCMTimeRangeZero;
                [customFilterArray removeObjectAtIndex:customFilterArray.count-1];
                [_videoCoreSDK seekToTime:fxStartTime];
            }
            else
            {
                _timeEffectType = kTimeFilterTyp_None;
                isPreviewFx = false;
                seekTime = fxStartTime;
                [self initPlayer];
                fxStartTime = kCMTimeZero;
            }
        }
        fxStartTime = kCMTimeZero;
        currentFxFilter = nil;
    }
}

#pragma mark- 画中画 编辑
//滤镜
-(void)showCollageBarItem:( RDPIPFunctionType ) pipType
{
    switch (pipType) {
        case kPIP_SINGLEFILTER: //MARK:画中画 滤镜
        {
            _addEffectsByTimeline.EditCollageView.collage_filter_View = [[filter_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            filter_editCollageView *collage_filter_View = _addEffectsByTimeline.EditCollageView.collage_filter_View;
            collage_filter_View.globalFilters = globalFilters;
            collage_filter_View.filters  = _filters;
            collage_filter_View.filtersName = _filtersName;
            collage_filter_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
            
            [collage_filter_View setNewFilterSortArray:newFilterSortArray];
            [collage_filter_View setNewFiltersNameSortArray:newFiltersNameSortArray];
            
            collage_filter_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_filter_View.navigationController = self.navigationController;
            [self.view addSubview:collage_filter_View];
            collage_filter_View.filterView.hidden = NO;
            collage_filter_View.pasterView = _addEffectsByTimeline.pasterView;
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_filter_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_filter_View.videoCoreSDK = _videoCoreSDK;
        }
            break;
        case kPIP_ADJUST://MARK:画中画 调色
        {
//            _addEffectsByTimeline.EditCollageView.collage_toni_View = [[toni_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            _addEffectsByTimeline.EditCollageView.collage_toni_View = [toni_editCollageView initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight) atVVAsset:_addEffectsByTimeline.EditCollageView.currentVvAsset];
            toni_editCollageView *collage_toni_View = _addEffectsByTimeline.EditCollageView.collage_toni_View;
            collage_toni_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_toni_View.navigationController = self.navigationController;
            [self.view addSubview:collage_toni_View];
            collage_toni_View.pasterView = _addEffectsByTimeline.pasterView;
//            collage_toni_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            collage_toni_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_toni_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_toni_View.videoCoreSDK = _videoCoreSDK;
        }
            break;
        case kPIP_MIXEDMODE://MARK:画中画 混合模式
        {
            _addEffectsByTimeline.EditCollageView.collage_mixed_View = [[mixed_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            
            mixed_editCollageView *collage_mixed_View = _addEffectsByTimeline.EditCollageView.collage_mixed_View;
            collage_mixed_View.currentVvAsset = _addEffectsByTimeline.EditCollageView.currentVvAsset;
            collage_mixed_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_mixed_View.navigationController = self.navigationController;
            [self.view addSubview:collage_mixed_View];
            collage_mixed_View.pasterView = _addEffectsByTimeline.pasterView;
            //            collage_cutout_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_mixed_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_mixed_View.videoCoreSDK = _videoCoreSDK;
            
            collage_mixed_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
        }
            break;
        case kPIP_CUTOUT://MARK:画中画 抠图
        {
            _addEffectsByTimeline.EditCollageView.collage_cutout_View = [[cutout_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            
            cutout_editCollageView *collage_cutout_View = _addEffectsByTimeline.EditCollageView.collage_cutout_View;
            collage_cutout_View.currentVvAsset = _addEffectsByTimeline.EditCollageView.currentVvAsset;
            collage_cutout_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_cutout_View.navigationController = self.navigationController;
            [self.view addSubview:collage_cutout_View];
            collage_cutout_View.pasterView = _addEffectsByTimeline.pasterView;
//            collage_cutout_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_cutout_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_cutout_View.videoCoreSDK = _videoCoreSDK;
            
            collage_cutout_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
        }
            break;
        case kPIP_VOLUME://MARK:画中画 声音
        {
            _addEffectsByTimeline.EditCollageView.collage_volume_View = [[volume_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            
            volume_editCollageView *collage_volume_View = _addEffectsByTimeline.EditCollageView.collage_volume_View;
            collage_volume_View.currentVvAsset = _addEffectsByTimeline.EditCollageView.currentVvAsset;
            collage_volume_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_volume_View.navigationController = self.navigationController;
            [self.view addSubview:collage_volume_View];
            collage_volume_View.pasterView = _addEffectsByTimeline.pasterView;
//            collage_volume_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_volume_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_volume_View.videoCoreSDK = _videoCoreSDK;
            
            collage_volume_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
        }
            break;
        case kPIP_BEAUTY://MARK:画中画 美颜
        {
            _addEffectsByTimeline.EditCollageView.collage_beautay_View = [[beautay_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            
            beautay_editCollageView *collage_beautay_View = _addEffectsByTimeline.EditCollageView.collage_beautay_View;
            collage_beautay_View.currentVvAsset = _addEffectsByTimeline.EditCollageView.currentVvAsset;
            collage_beautay_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_beautay_View.navigationController = self.navigationController;
            [self.view addSubview:collage_beautay_View];
            collage_beautay_View.pasterView = _addEffectsByTimeline.pasterView;
//            collage_beautay_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_beautay_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_beautay_View.videoCoreSDK = _videoCoreSDK;
            
            collage_beautay_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
        }
            break;
        case kPIP_TRANSPARENCY://MARK:画中画 透明度
        {
            _addEffectsByTimeline.EditCollageView.collage_transparency_View = [[transparency_editCollageView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + kToolbarHeight)];
            
            transparency_editCollageView *collage_transparency_View = _addEffectsByTimeline.EditCollageView.collage_transparency_View;
            collage_transparency_View.currentVvAsset = _addEffectsByTimeline.EditCollageView.currentVvAsset;
            collage_transparency_View.delegate = _addEffectsByTimeline.EditCollageView;
            collage_transparency_View.navigationController = self.navigationController;
            [self.view addSubview:collage_transparency_View];
            collage_transparency_View.pasterView = _addEffectsByTimeline.pasterView;
//            collage_transparency_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            
            if( _addEffectsByTimeline.EditCollageView.videoCoreSDK )
                collage_transparency_View.videoCoreSDK = _addEffectsByTimeline.EditCollageView.videoCoreSDK;
            else
                collage_transparency_View.videoCoreSDK = _videoCoreSDK;
            
            collage_transparency_View.currentCollage = _addEffectsByTimeline.EditCollageView.currentCollage;
        }
            break;
        case kPIP_ROTATE://MARK:画中画 旋转
        {
            
        }
            break;
        case kPIP_MIRROR://MARK:画中画 左右镜像
        {
            
        }
            break;
        case kPIP_FLIPUPANDDOWN://MARK:画中画 上下镜像
        {
            
        }
            break;
        default:
            break;
    }
}

#pragma mark- =====DubbingTrimViewDelegate CaptionVideoTrimViewDelegate ======
- (void) touchescurrentdubbingView:(DubbingRangeView *)sender flag:(BOOL)flag{
    RdCanAddDubbingType type = [_dubbingTrimmerView checkCanAddDubbing];
    if(type != kCanAddDubbing){
        _dubbingBtn.enabled = NO;
        flag = NO;
    }else{
        _dubbingBtn.enabled = YES;
        flag = YES;
    }
    if(!flag){
        _deletedDubbingBtn.hidden = NO;
        _dubbingBtn.hidden = YES;
        _dubbingVolumeView.hidden = NO;
    }else{
        _deletedDubbingBtn.hidden = YES;
        _dubbingBtn.hidden = NO;
        _dubbingVolumeView.hidden = YES;
    }
}
- (void)dubbingScrollViewWillBegin:(DubbingTrimmerView *)trimmerView{
    _playButton.hidden = YES;
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    [_dubbingPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
}
- (void)dubbingScrollViewWillEnd:(DubbingTrimmerView *)trimmerView
                       startTime:(Float64)capationStartTime
                         endTime:(Float64)capationEndTime
{
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(capationStartTime, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}
- (void)seekTime:(NSNumber *)numTime{
    NSLog(@"%s time :%f",__func__,[numTime floatValue]);
    CMTime time = CMTimeMakeWithSeconds([numTime floatValue], TIMESCALE);
    [_videoCoreSDK seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
        float duration = _videoCoreSDK.duration;
        if(CMTimeGetSeconds(startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
//            [self playVideo:YES];
        }
    }];
}
- (void)trimmerView:(id)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime{
    if(![_videoCoreSDK isPlaying]){
        WeakSelf(self);
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(startTime, TIMESCALE) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = strongSelf.videoCoreSDK.duration;
            if(strongSelf && CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
    }
    if([trimmerView isKindOfClass: [DubbingTrimmerView class]]){
        self.dubbingCurrentTimeLbl.text = [RDHelpClass timeToStringFormat:startTime];
    }else{
        bottomCurrentTimeLbl.text = [RDHelpClass timeToStringFormat:startTime];
    }
    
    if( trimmerView == _videoTrimmerView )
    {
        if( !isRecording )
        {
            _captionVideoCurrentTimeLbl.text = [RDHelpClass timeToStringFormat:startTime];
            if (selecteFunction == RDAdvanceEditType_Subtitle) {
                if (_addEffectsByTimeline.subtitleConfigView.hidden) {
                    VideoCurrentTime = startTime/_videoCoreSDK.duration;
                }
            }else {
                VideoCurrentTime = startTime/_videoCoreSDK.duration;
            }            
        }
    }
}


- (void)capationScrollViewWillEnd:(CaptionVideoTrimmerView *)trimmerView
                        startTime:(Float64)capationStartTime
                          endTime:(Float64)capationEndTime{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
}

-(void)initThumbTimes
{
    [thumbTimes removeAllObjects];
    thumbTimes = nil;
    thumbTimes=[[NSMutableArray alloc] init];
    Float64 duration;
    Float64 start;
    duration = _videoCoreSDK.duration;
    start = (duration > 2 ? 1 : (duration-0.05));
    [thumbTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(start,TIMESCALE)]];
    NSInteger actualFramesNeeded = duration/1.0;
    
    actualFramesNeeded += ((duration - actualFramesNeeded)>0)?1:0;
    
    //        Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
    Float64 durationPerFrame = 1.0;
    /*截图为什么用两个for循环：第一个for循环是分配内存，第二个for循环显示图片，截图快一些*/
    for (int i=1; i<actualFramesNeeded; i++){
        CMTime time = CMTimeMakeWithSeconds(start + i*durationPerFrame,TIMESCALE);
        if( (start + i*durationPerFrame) > duration )
            time = CMTimeMakeWithSeconds(duration - 0.2,TIMESCALE);
        [thumbTimes addObject:[NSValue valueWithCMTime:time]];
    }
}

-(void)Core_loadTrimmerViewThumbImage
{
    @autoreleasepool {
        [self initThumbTimes];
        
        self.captionVideoView.hidden = NO;
        _playerToolBar.hidden = YES;
        [_functionalAreaView addSubview:_captionVideoView];
        
        
        Float64 start = (_videoCoreSDK.duration > 2 ? 1 : (_videoCoreSDK.duration-0.05));
//        [thumbImageVideoCore getImageWithTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2 completionHandler:^(UIImage *image) {
//            if(!image){
//                image = [thumbImageVideoCore getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
////                if (!image) {
////                    image = [_videoCoreSDK getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
////                }
//            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [_videoTrimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [_videoTrimmerView.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                
                if(_videoTrimmerView){
                    [_videoTrimmerView setVideoCore:_videoCoreSDK];
                    [_videoTrimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), _videoCoreSDK.composition.duration)];
                    _videoTrimmerView.thumbTimes = thumbTimes.count;
                    [_videoTrimmerView resetSubviews:nil];
//                    [_videoTrimmerView setProgress:0 animated:NO];
                }
//                [_videoTrimmerView cancelCurrent];
                if( _captionVideoDurationTimeLbl )
                    _captionVideoDurationTimeLbl.text = [RDHelpClass timeToStringFormat: _videoCoreSDK.duration];
                
                [self Core_refreshTrimmerViewImage];
            });
//        }];
    }
}
- (void)Core_refreshTrimmerViewImage {
    Float64 durationPerFrame = thumbImageVideoCore.duration / (thumbTimes.count*1.0);
    for (int i=0; i<thumbTimes.count; i++){
        CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
        [thumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
    }
    
    [self refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES atIsVideo:YES];
}

//- (void)Core_refreshThumbWithImageTimes:(NSArray *)imageTimes nextRefreshIndex:(int)nextRefreshIndex isLastArray:(BOOL)isLastArray{
//    @autoreleasepool {
//        __weak typeof(self) weakSelf = self;
//        os_unfair_lock_lock(&thumbTimesImageArrayLock);
//        [thumbTimesImageArray removeAllObjects];
//        thumbTimesImageArray = nil;
//        thumbTimesImageArray = [[NSMutableArray alloc] init];
//        os_unfair_lock_unlock(&thumbTimesImageArrayLock);
//
//        [thumbImageVideoCore getImageWithTimes:[imageTimes mutableCopy] scale:0.1 completionHandler:^(UIImage *image, NSInteger idx) {
//            StrongSelf(self);
//            if( !image )
//            {
//                return;
//            }
//            os_unfair_lock_lock(&thumbTimesImageArrayLock);
//            [thumbTimesImageArray addObject:image];
//            os_unfair_lock_unlock(&thumbTimesImageArrayLock);
//
//            [_videoTrimmerView refreshThumbImage:thumbTimesImageArray.count-1 thumbImage:image];
//
//            switch (selecteFunction) {
//                case RDAdvanceEditType_Subtitle:
//                case RDAdvanceEditType_Sticker:
//                case RDAdvanceEditType_Dewatermark:
//                case RDAdvanceEditType_Collage:
//                case RDAdvanceEditType_Doodle:
//                case RDAdvanceEditType_Multi_track:
//                case RDAdvanceEditType_Sound:
//                case RDAdvanceEditType_Effect:
//                {
//                    if( (_addEffectsByTimeline != nil) &&  self.addEffectsByTimeline.trimmerView)
//                        [self.addEffectsByTimeline.trimmerView refreshThumbImage:idx thumbImage:image];
//                }
//                    break;
//                case RDAdvanceEditType_Dubbing:
//                {
//                    if( (_dubbingTrimmerView != nil) &&  self.dubbingTrimmerView)
//                        [self.dubbingTrimmerView refreshThumbImage:idx thumbImage:image];
//                }
//                    break;
//                case RDAdvanceEditType_Cover:
//                {
//                    if( (bottomTrimmerView != nil) && self->bottomTrimmerView)
//                        [self->bottomTrimmerView refreshThumbImage:idx thumbImage:image];
//                }
//                    break;
//                default:
//                    break;
//            }
//            if(idx == imageTimes.count - 1)
//            {
//                [strongSelf->thumbImageVideoCore stop];
//                strongSelf->thumbImageVideoCore = nil;
//                if (selecteFunction == RDAdvanceEditType_Effect) {
//                    [RDSVProgressHUD dismiss];
//                }
//            }
//        }];
//    }
//}

- (void)loadTrimmerViewThumbImage {
    @autoreleasepool {
        
        if( thumbTimes == nil )
        {
            [self initThumbTimes];
        }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if( _addEffectsByTimeline )
                {
                    if( _addEffectsByTimeline.durationTimeLbl )
                    {
                        _addEffectsByTimeline.durationTimeLbl.text = [RDHelpClass timeToStringFormat: _videoCoreSDK.duration];
                    }
                }
                
                switch (selecteFunction) {
                    case RDAdvanceEditType_Subtitle://MARK:字幕
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:subtitles
                                                           oldFileArray:oldSubtitleFiles];
                        
                        if (subtitles.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
                        }
                        break;
                    case RDAdvanceEditType_Sticker://MARK:贴纸
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
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
                    case RDAdvanceEditType_Dubbing://MARK:配音
                    {
                        [self.dubbingTrimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        [self.dubbingTrimmerView.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        
                        if(_dubbingTrimmerView){
                            
                            [_dubbingTrimmerView setVideoCore:_videoCoreSDK];
                            [_dubbingTrimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE))];
                            _dubbingTrimmerView.thumbImageTimes = thumbTimes.count;
                            [_dubbingTrimmerView resetSubviews:nil];
                            [self.dubbingTrimmerView setProgress:0 animated:NO];
                            
                            for (DubbingRangeView *dubbing in dubbingMusicArr) {
                                if (dubbing.allControlEvents == 0) {
                                    [_dubbingTrimmerView addDubbingTarget:dubbing];
                                }
                                Float64 start = CMTimeGetSeconds(dubbing.dubbingStartTime);
                                Float64 duration = CMTimeGetSeconds(dubbing.dubbingDuration);
                                float oginx = (start + _dubbingTrimmerView.piantouDuration)*_dubbingTrimmerView.videoRangeView.frame.size.width/CMTimeGetSeconds(_dubbingTrimmerView.clipTimeRange.duration);
                                float width =  duration *_dubbingTrimmerView.videoRangeView.frame.size.width/CMTimeGetSeconds(_dubbingTrimmerView.clipTimeRange.duration);
                                CGRect rect= dubbing.frame;
                                rect.origin.x = oginx;
                                rect.size.width = width;
                                dubbing.frame = rect;
                                RDMusic *music = [[RDMusic alloc] init];
                                music.clipTimeRange = CMTimeRangeMake(kCMTimeZero,dubbing.dubbingDuration);
                                music.effectiveTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(dubbing.dubbingStartTime) + _dubbingTrimmerView.piantouDuration,TIMESCALE), dubbing.dubbingDuration);
                                music.url = [NSURL fileURLWithPath:dubbing.musicPath];
                                music.volume = dubbing.volume;
                                music.isRepeat = NO;
                                
                                [_dubbingTrimmerView.videoRangeView addSubview:dubbing];
                                [dubbingArr addObject:music];
                            }
                            NSArray *dubbingArray = [_dubbingTrimmerView getTimesFor_videoRangeView_withTime];
                            if (dubbingArray.count > 0) {
                                _reDubbingBtn.hidden = NO;
                                _auditionDubbingBtn.hidden = NO;
                            }else {
                                _reDubbingBtn.hidden = YES;
                                _auditionDubbingBtn.hidden = YES;
                            }
                            [self.dubbingTrimmerView setProgress:VideoCurrentTime animated:NO];
                            
                            [self touchescurrentdubbingView:[dubbingArray firstObject] flag:YES];
                        }
                    }
                        break;
                    case RDAdvanceEditType_Dewatermark://MARK:去水印
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadDewatermarkThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                               blurArray:blurs
                                                        oldBlurFileArray:oldBlurFiles
                                                             mosaicArray:mosaics
                                                      oldMosaicFileArray:oldMosaicFiles
                                                        dewatermarkArray:dewatermarks
                                                 oldDewatermarkFileArray:oldDewatermarkFiles];
                        if (blurs.count == 0 && mosaics.count == 0 && dewatermarks.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
                        }
                        break;
                    case RDAdvanceEditType_Collage://MARK:画中画
                    {
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:collages
                                                           oldFileArray:oldCollageFiles];
                        if (collages.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
                        }
                    }
                        break;
                    case RDAdvanceEditType_Doodle:
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:doodles
                                                           oldFileArray:oldDoodleFiles];
                        if (doodles.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
                        }
                        break;
                    case RDAdvanceEditType_Cover:
                    {
                        [bottomTrimmerView.frameView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        [bottomTrimmerView.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        
                        [bottomTrimmerView setVideoCore:_videoCoreSDK];
                        [bottomTrimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), _videoCoreSDK.composition.duration)];
                        bottomTrimmerView.thumbTimes = thumbTimes.count;
                        [bottomTrimmerView resetSubviews:nil];
                        if (coverFile && CMTimeCompare(coverFile.coverTime, kCMTimeInvalid) == 0) {
                            float progress = CMTimeGetSeconds(coverFile.coverTime)/_videoCoreSDK.duration;
                            [bottomTrimmerView setProgress:progress animated:NO];
                            [_videoCoreSDK seekToTime:coverFile.coverTime];
                        }else {
                            [bottomTrimmerView setProgress:0 animated:NO];
                        }
                    }
                        break;
                    case RDAdvanceEditType_Sound://MARK:音效
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:soundMusics
                                                           oldFileArray:oldSoundMusicFiles];
                        
                        
                        if (soundMusics.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
                        }
                        break;
                    case RDAdvanceEditType_Multi_track://MARK:多段配乐
//                        [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:musics
                                                           oldFileArray:oldMusicFiles];
                        
                        
                        if (musics.count == 0) {
                            _addedMaterialEffectView.hidden = YES;
                            toolbarTitleLbl.hidden = NO;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            _addedMaterialEffectView.hidden = NO;
                            toolbarTitleLbl.hidden = YES;
                        }
                        break;
                    case RDAdvanceEditType_Effect://MARK:特效
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:nil
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:fXArray
                                                            oldFileArray:oldFXFiles];
                        if (fXArray.count == 0) {
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
    }
    
}
- (void)refreshTrimmerViewImage {
    @autoreleasepool {
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            case RDAdvanceEditType_Effect:
            {
                [_addEffectsByTimeline.trimmerView setProgress:VideoCurrentTime  animated:NO];
                
                seekTime = CMTimeMakeWithSeconds(VideoCurrentTime*_videoCoreSDK.duration, TIMESCALE);
                
                NSMutableArray * array = [_addEffectsByTimeline.trimmerView getCaptionsViewForcurrentTime:NO];
                if( (array == nil) || ( array.count == 0 ) )
                {
                    
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        self.toolbarTitleView.hidden = YES;
//                    });
                    
                    _addEffectsByTimeline.trimmerView.isTiming = YES;
                    _addEffectsByTimeline.hidden = YES;
                    [_addEffectsByTimeline addEffectAction:_addEffectsByTimeline.addBtn];
                    _addEffectsByTimeline.isBuild = TRUE;
                    isAdd = TRUE;
                }
                else
                {
                    isAdd = FALSE;
                    _addEffectsByTimeline.hidden = NO;
                    self.toolbarTitleView.hidden = NO;
                }
            }
                break;
            case RDAdvanceEditType_Dubbing:
            {
                [self.dubbingTrimmerView setProgress:VideoCurrentTime animated:NO];
            }
                break;
            case RDAdvanceEditType_Cover:
            {
            }
                break;
            default:
                break;
        }
        isRecording = false;
        [self refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES atIsVideo:NO];
    }
}

-(void)save_refreshThumbImage:( NSString * ) patch atIndex:(int) index atIsVideo:(bool) isVideo
{
    __block UIImage * image = nil;
//    bool isSuccess = true;
    
//    for(;isSuccess;)
//    {
////        image = [RDHelpClass getThumbImageWithUrl: [NSURL fileURLWithPath:patch]];
        image = [[UIImage alloc] initWithContentsOfFile:patch];
//        if( image || !patch )
//        {
//            isSuccess = false;
//        }
//        else{
//            sleep(0.1);
//        }
//    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if( isVideo )
        {
            if(self->_videoTrimmerView)
                [self->_videoTrimmerView refreshThumbImage:index thumbImage:image];
            //            [self->_videoTrimmerView refreshThumbImage:fStart+j thumbImage:image];
            
        }
        else
        {
            switch (selecteFunction) {
                case RDAdvanceEditType_Subtitle:
                case RDAdvanceEditType_Sticker:
                case RDAdvanceEditType_Dewatermark:
                case RDAdvanceEditType_Collage:
                case RDAdvanceEditType_Doodle:
                case RDAdvanceEditType_Multi_track:
                case RDAdvanceEditType_Sound:
                case RDAdvanceEditType_Effect:
                {
                    if(self.addEffectsByTimeline.trimmerView)
                        [self.addEffectsByTimeline.trimmerView refreshThumbImage:index thumbImage:image];
                }
                    break;
                case RDAdvanceEditType_Dubbing:
                {
                    if(self.dubbingTrimmerView)
                        [self.dubbingTrimmerView refreshThumbImage:index thumbImage:image];
                }
                    break;
                    
                case RDAdvanceEditType_Cover:
                {
                    if(self->bottomTrimmerView)
                        [self->bottomTrimmerView refreshThumbImage:index thumbImage:image];
                }
                    break;
                default:
                    break;
            }
        }
        
        image = nil;
    });
}

-(void)getImage_ThumbWithImage:(int) i atIsVideo:(bool) isVideo
{
    
    //    return;
    
    bool    islast = ( (_fileList.count -1) == i  ) ? true : false;
    
    __block CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:i];
    
    __block int fStart = ceilf( CMTimeGetSeconds(timeRange.start) );
    
    CMTime duration = timeRange.duration;
    @autoreleasepool {
        //视频或者GIF图片获取缩略图
        if( _fileList[i].isGif || _fileList[i].fileType == kFILEVIDEO )
        {
            
            if( _fileList[i].isGif )
            {
                timeRange = _fileList[i].imageTimeRange;
                
                if( CMTimeGetSeconds(timeRange.duration) <= 0 )
                    timeRange = CMTimeRangeMake(kCMTimeZero, _fileList[i].imageDurationTime);
                
            }
            else{
                if(_fileList[i].isReverse){
                    if (CMTimeRangeEqual(kCMTimeRangeZero, _fileList[i].reverseVideoTimeRange)) {
                        timeRange = CMTimeRangeMake(kCMTimeZero, _fileList[i].reverseDurationTime);
                    }else{
                        timeRange = _fileList[i].reverseVideoTimeRange;
                    }
                    if(CMTimeCompare(timeRange.duration, _fileList[i].reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(_fileList[i].reverseVideoTrimTimeRange.duration)>0){
                        timeRange = _fileList[i].reverseVideoTrimTimeRange;
                    }
                }
                else{
                    if (CMTimeRangeEqual(kCMTimeRangeZero, _fileList[i].videoTimeRange)) {
                        timeRange = CMTimeRangeMake(kCMTimeZero, _fileList[i].videoDurationTime);
                        if(CMTimeRangeEqual(kCMTimeRangeZero, timeRange)){
                            timeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:_fileList[i].contentURL].duration);
                        }
                    }else{
                        timeRange = _fileList[i].videoTimeRange;
                    }
                    if(!CMTimeRangeEqual(kCMTimeRangeZero, _fileList[i].videoTrimTimeRange) && CMTimeCompare(timeRange.duration, _fileList[i].videoTrimTimeRange.duration) == 1){
                        timeRange = _fileList[i].videoTrimTimeRange;
                    }
                }
            }
            
            timeRange = CMTimeRangeMake(timeRange.start, CMTimeMakeWithSeconds(CMTimeGetSeconds(timeRange.duration)/_fileList[i].speed, TIMESCALE));
            
            int numberCount = islast?ceilf(CMTimeGetSeconds(timeRange.duration)):(int)(CMTimeGetSeconds(timeRange.duration)+_fileList[i].transitionDuration);
            
             for (int j = 0; j <= numberCount; j++) {
                @autoreleasepool {
                    
                    int number = j*_fileList[i].speed+ceilf(CMTimeGetSeconds(timeRange.start));
                    
                    if( _fileList[i].isReverse )
                        number = ceilf(CMTimeGetSeconds(_fileList[i].videoDurationTime)) - number;
                    
                    NSString * strPatch = [_fileList[i].filtImagePatch stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png",number]];
                    
//                    NSLog(@"Image:%@,%d",strPatch,fStart+j);
                    
                    [self save_refreshThumbImage:strPatch atIndex:fStart+j atIsVideo:isVideo];
                    
                    strPatch = nil;
                    
                }
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                fStart = (int)( CMTimeGetSeconds(timeRange.start) );
                UIImage * image = [RDHelpClass getThumbImageWithUrl:_fileList[i].contentURL];
                
                int numberCount = islast?ceilf(CMTimeGetSeconds(timeRange.duration)):(int)(CMTimeGetSeconds(timeRange.duration)+_fileList[i].transitionDuration);
                
                for (int j = 0; j <= numberCount; j++) {
                    if( isVideo )
                    {
                        if(self->_videoTrimmerView)
                            [self->_videoTrimmerView refreshThumbImage:fStart+j thumbImage:image];
                    }
                    else
                    {
                        switch (selecteFunction) {
                            case RDAdvanceEditType_Subtitle:
                            case RDAdvanceEditType_Sticker:
                            case RDAdvanceEditType_Dewatermark:
                            case RDAdvanceEditType_Collage:
                            case RDAdvanceEditType_Doodle:
                            case RDAdvanceEditType_Multi_track:
                            case RDAdvanceEditType_Sound:
                            case RDAdvanceEditType_Effect:
                            {
                                if(self.addEffectsByTimeline.trimmerView)
                                    [self.addEffectsByTimeline.trimmerView refreshThumbImage:fStart+j thumbImage:image];
                            }
                                break;
                            case RDAdvanceEditType_Dubbing:
                            {
                                if(self.dubbingTrimmerView)
                                    [self.dubbingTrimmerView refreshThumbImage:fStart+j thumbImage:image];
                            }
                                break;
                                
                            case RDAdvanceEditType_Cover:
                            {
                                if(self->bottomTrimmerView)
                                    [self->bottomTrimmerView refreshThumbImage:fStart+j thumbImage:image];
                            }
                                break;
                            default:
                                break;
                        }
                    }
                }
                image = nil;
            });
        }
    }
}

- (void)refreshThumbWithImageTimes:(NSArray *)imageTimes nextRefreshIndex:(int)nextRefreshIndex isLastArray:(BOOL)isLastArray atIsVideo:(bool) isVideo{
    @autoreleasepool {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (int i = 0; i < _fileList.count; i++) {
                [self getImage_ThumbWithImage:i atIsVideo:isVideo];
            }
        });
        
    }
}

#pragma mark- scrollViewChildItemDelegate  水印 配乐 变声 滤镜
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item{
    if(item.type == 1){//MARK:配乐
        [mvMusicArray removeAllObjects];
        mvMusicArray = nil;
#if !ENABLEAUDIOEFFECT
        if([_videoCoreSDK isPlaying]){
            [self playVideo:NO];
        }
#endif
        seekTime = _videoCoreSDK.currentTime;
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
                WeakSelf(self);
                CGRect rect = [item getIconFrame];
                UIView * progress = [RDHelpClass loadProgressView:rect];
                [item addSubview:progress];
//                CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
//                ddprogress.progressColor = Main_Color;
//                ddprogress.progressWidth = 2.f;
//                ddprogress.progressBackgroundColor = [UIColor clearColor];
//                [item addSubview:ddprogress];
                item.downloading = YES;
                [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
                [RDFileDownloader downloadFileWithURL:urlstr cachePath:filePath httpMethod:GET progress:^(NSNumber *numProgress) {
//                    [ddprogress setPercent:[numProgress floatValue]];
                    
                    if( ([numProgress floatValue] >= 0.0) && ([numProgress floatValue] <= 1.0)   )
                    {
                        [progress.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if( [obj isKindOfClass:[UILabel class]] )
                            {
                                UILabel * label = (UILabel*)obj;
                                if(label.tag == 1)
                                {
                                    label.text = [NSString stringWithFormat:@"%d%%",(int)([numProgress floatValue]*100.0)  ];
                                }
                            }
                        }];
                    }
                } finish:^(NSString *fileCachePath) {
                    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fileCachePath]];
                    double duration = CMTimeGetSeconds(asset.duration);
                    asset = nil;
                    StrongSelf(self);
                    if(duration == 0){
                        [[NSFileManager defaultManager] removeItemAtPath:fileCachePath error:nil];
                        NSLog(@"下载失败");
                        [strongSelf.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                        [strongSelf.hud show];
                        [strongSelf.hud hideAfter:2];
                        item.downloading = NO;
//                        [ddprogress removeFromSuperview];
                        [progress removeFromSuperview];
                    }else{
                        item.downloading = NO;
//                        [ddprogress removeFromSuperview];
                        [progress removeFromSuperview];
                        if([strongSelf downLoadingMusicCount] == 0){
                            [item setSelected:YES];
                            [strongSelf scrollViewChildItemTapCallBlock:item];
                        }
                    }
                } fail:^(NSError *error) {
                    NSLog(@"下载失败");
                    StrongSelf(self);
                    [strongSelf.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                    [strongSelf.hud show];
                    [strongSelf.hud hideAfter:2];
                    item.downloading = NO;
//                    [ddprogress removeFromSuperview];
                    [progress removeFromSuperview];
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
                _musicVolumeBtn.selected = NO;
                [self musicVolume_Btn];
            }
        }
        else{
            
            seekTime = _videoCoreSDK.currentTime;
            
            switch (item.tag - 1) {
//                case 0:
//                {
//                    yuanyinOn = !yuanyinOn;
//                    if(yuanyinOn){
//                        _videoVolumeSlider.enabled = YES;
//                        _videoVolumeSlider.value = (_originalVolume/volumeMultipleM);
//                        [item setSelected:YES];
////                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"];
////                        item.itemTitleLabel.text  = RDLocalizedString(@"原音开", nil);
//                    }else{
//                        _videoVolumeSlider.enabled = NO;
////                        item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音关_"];
////                        item.itemTitleLabel.text  = RDLocalizedString(@"原音关", nil);
//                        [item setSelected:NO];
//                    }
////                    item.itemIconView.image = [item.itemIconView.image imageWithTintColor];
//#if ENABLEAUDIOEFFECT
//                    __weak typeof(self) weakSelf = self;
//                    [scenes enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
//                        StrongSelf(self);
//                        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                            if (obj.identifier.length > 0) {
//                                [strongSelf.videoCoreSDK setVolume:(yuanyinOn ? (strongSelf->oldVolume) : 0.0) identifier:obj.identifier];
//                            }
//                        }];
//                    }];
//                    if (!_videoCoreSDK.isPlaying) {
////                        [self playVideo:YES];
//                    }
//#else
//                    [self initPlayer];
//#endif
//                }
//                    break;
//                case 1:
//                {
//                    _musicVolumeSlider.enabled = NO;
////                    item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_原音开_"];
//                    item.itemIconView.image = [item.itemIconView.image imageWithTintColor];
////                    item.itemTitleLabel.text  = RDLocalizedString(@"无配乐", nil);
//
//                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
//                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
//                    if(enableLocalMusic){
//                        if(cloudMusicResourceURL.length>0){
//                            ((ScrollViewChildItem *)[_musicChildsView viewWithTag:4]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
//                        }
//                        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"本地", nil);
//                    }else{
//                        if(cloudMusicResourceURL.length>0){
//                            ((ScrollViewChildItem *)[_musicChildsView viewWithTag:3]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
//                        }
//                    }
//                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:2]) setSelected:YES];
//                    selectMusicIndex = item.tag-1;
//                    _musicVolumeSlider.enabled = NO;
//#if ENABLEAUDIOEFFECT
//                    [_videoCoreSDK setVolume:0.0 identifier:@"music"];
//                    if (!_videoCoreSDK.isPlaying) {
////                        [self playVideo:YES];
//                    }
//#else
//                    [self initPlayer];
//#endif
//                }
//                    break;
                case 2:
                {
                    [self enter_localMusic:item];
                }
                    break;
                case 3:
                {
                    [self enter_cloudMusic:item];
                }
                    break;
                default:
                    break;
            }
        }
    }
    else if(item.type == 2){//MARK:滤镜
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.filterIndex = 0;
        }];
        [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
                asset.filterType = VVAssetFilterEmpty;
                asset.filterUrl = nil;
            }];
        }];
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
            NSDictionary *obj = self.filtersName[item.tag - 1];
            NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
            if(item.tag-1 == 0){
                if( _fileterScrollView )
                {
                    [self setNewFilterChildsView:NO atTypeIndex:selectFilterIndex];
                }else{
                    [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
                }
                [item setSelected:YES];
                
                selectFilterIndex = item.tag-1;
                
                [_videoCoreSDK setGlobalFilter:selectFilterIndex];
                //滤镜强度
                [_filterProgressSlider setValue:1.0];
                
                if( 0 == self->selectFilterIndex )
                    _filterProgressSlider.enabled = NO;
                else
                    _filterProgressSlider.enabled = YES;
                
                _percentageLabel.text = @"100%";
                filterStrength = 1.0;
                if(![_videoCoreSDK isPlaying]){
                    [_videoCoreSDK refreshCurrentFrame];
                }
                return ;
            }
            
            NSString *itemPath = [[[filterPath stringByAppendingPathComponent:obj[@"name"]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
            if([[NSFileManager defaultManager] fileExistsAtPath:itemPath]){
               if( _fileterScrollView )
                {
                    [self setNewFilterChildsView:NO atTypeIndex:selectFilterIndex];
                }else{
                    [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
                }
                [item setSelected:YES];
                selectFilterIndex = item.tag-1;
                
                if( 0 == self->selectFilterIndex )
                    _filterProgressSlider.enabled = NO;
                else
                    _filterProgressSlider.enabled = YES;
                
                [_videoCoreSDK setGlobalFilter:selectFilterIndex];
                //滤镜强度
                [_filterProgressSlider setValue:1.0];
                _percentageLabel.text = @"100%";
                filterStrength = 1.0;
                if(![_videoCoreSDK isPlaying]){
                    [_videoCoreSDK refreshCurrentFrame];
                }
                return ;
            }
            CGRect rect = [item getIconFrame];
//            CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
            UIView * progress = [RDHelpClass loadProgressView:rect];
            item.downloading = YES;
            if( _fileterScrollView )
            {
                [self setNewFilterChildsView:NO atTypeIndex:selectFilterIndex];
            }else{
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
            }
//            ddprogress.progressColor = Main_Color;
//            ddprogress.progressWidth = 2.f;
//            ddprogress.progressBackgroundColor = [UIColor clearColor];
            [item addSubview:progress];
            WeakSelf(self);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RDDownTool *tool = [[RDDownTool alloc] initWithURLPath:obj[@"file"] savePath:itemPath];
                tool.Progress = ^(float numProgress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [ddprogress setPercent:numProgress];
                        if( (numProgress >= 0.0) && (numProgress <= 1.0)   )
                        {
                            [progress.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if( [obj isKindOfClass:[UILabel class]] )
                                {
                                    UILabel * label = (UILabel*)obj;
                                    if(label.tag == 1)
                                    {
                                        label.text = [NSString stringWithFormat:@"%d%%",(int)(numProgress*100)];
                                    }
                                }
                            }];
                        }
                        
                    });
                };
                tool.Finish = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        StrongSelf(self);
//                        [ddprogress removeFromSuperview];
                        [progress removeFromSuperview];
                        item.downloading = NO;
                        if([strongSelf downLoadingFilterCount]>=1){
                            return ;
                        }
                        if( _fileterScrollView )
                        {
                            for (UIView *subview in _fileterScrollView.subviews) {
                                if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                                    [(ScrollViewChildItem*)subview setSelected:NO];
                            }
                        }
                        else
                        {
                            [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if([obj isKindOfClass:[ScrollViewChildItem class]]){
                                    
                                    [(ScrollViewChildItem *)obj setSelected:NO];
                                }
                            }];
                        }

                        [item setSelected:YES];
                        selectFilterIndex = item.tag-1;
                        
                        if( 0 == self->selectFilterIndex )
                            _filterProgressSlider.enabled = NO;
                        else
                            _filterProgressSlider.enabled = YES;
                        
                        ((RDFilter *)globalFilters[selectFilterIndex]).filterPath = itemPath;
                        [_videoCoreSDK setGlobalFilter:selectFilterIndex];
                        //滤镜强度
                        [_filterProgressSlider setValue:1.0];
                        _percentageLabel.text = @"100%";
                        filterStrength = 1.0;
                        if(![_videoCoreSDK isPlaying]){
                            [_videoCoreSDK refreshCurrentFrame];
                        }
                    });
                };
                [tool start];
            });
        }else{
            if( _fileterScrollView )
            {
                [self setNewFilterChildsView:NO atTypeIndex:selectFilterIndex];
            }
            else{
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
            }
            [item setSelected:YES];
            selectFilterIndex = item.tag-1;
            
            if( 0 == self->selectFilterIndex )
                _filterProgressSlider.enabled = NO;
            else
                _filterProgressSlider.enabled = YES;
            
            [_videoCoreSDK setGlobalFilter:selectFilterIndex];
            //滤镜强度
            [_filterProgressSlider setValue:1.0];
            _percentageLabel.text = @"100%";
            filterStrength = 1.0;
            if(![_videoCoreSDK isPlaying]){
                [_videoCoreSDK refreshCurrentFrame];
            }
        }
    }
    else if(item.type == 3){//MARK:MV
        if([_videoCoreSDK isPlaying]){
            [self playVideo:NO];
        }
        NSString *enname = nil;
        NSString *urlstr = nil;
        NSString *filePath = nil;
        if(item.tag > 1){
            NSDictionary *itemDic = mvList[item.tag-2];
            if([[itemDic allKeys] containsObject:@"cover"]){
                enname    = @"";//[[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension];
                urlstr     = itemDic[@"file"];
            }else{
                enname    = itemDic[@"enname"];
                urlstr     = itemDic[@"url"];
            }
            filePath = [kThemeMVEffectPath stringByAppendingString:[NSString stringWithFormat:@"%@",enname]];
            RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
            if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                if([lexiu currentReachabilityStatus] == RDNotReachable){
                    [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                    [self.hud show];
                    [self.hud hideAfter:2];
                    return;
                }
            }
        }
        ScrollViewChildItem *childItem = [_mvChildsView viewWithTag:lastThemeMVIndex+1];
        [childItem setSelected:NO];
        [mvMusicArray removeAllObjects];
        mvMusicArray = nil;
        if(item.tag==1){
            lastThemeMVIndex = 0;
            [item setSelected:YES];
            selectMVEffects = nil;
            selectMVEffectBack = nil;
            if(_musicURL && selectMusicIndex == 1 && _musicView && oldMusicIndex != 1){
                [_videoCoreSDK addMVEffect:nil];
                [self AdjMusicReturn:NO];
            }else {
                _musicURL = nil;
                [self initPlayer];
            }
        }
        else{
            NSDictionary *itemDic = mvList[item.tag-2];
            NSString *file = enname.length> 0 ? enname : [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]];
            NSString *path = [kThemeMVEffectPath stringByAppendingPathComponent:file];
            NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
            if(fileCount == 0 ){
                if(item.downloading){
                    return;
                }
                WeakSelf(self);
                CGRect rect = [item getIconFrame];
                CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
                ddprogress.progressColor = Main_Color;
                ddprogress.progressWidth = 2.f;
                ddprogress.progressBackgroundColor = [UIColor clearColor];
                [item addSubview:ddprogress];
                item.downloading = YES;
                [RDFileDownloader downloadFileWithURL:urlstr cachePath:kThemeMVEffectPath httpMethod:GET progress:^(NSNumber *numProgress) {
                    NSLog(@"%lf",[numProgress floatValue]);
                    [ddprogress setPercent:[numProgress floatValue]];
                } finish:^(NSString *fileCachePath) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSLog(@"下载完成");
                        StrongSelf(self);
                        item.downloading = NO;
                        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                        }
                        BOOL suc =[RDHelpClass OpenZipp:fileCachePath unzipto:path];
                        if(suc){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [ddprogress removeFromSuperview];
                                if([strongSelf downLoadingMVCount] == 0){
                                    [strongSelf scrollViewChildItemTapCallBlock:item];
                                }
                            });
                        }
                    });
                } fail:^(NSError *error) {
                    NSLog(@"下载失败");
                    item.downloading = NO;
                    [ddprogress removeFromSuperview];
                }];
            }
            else
            {
                lastThemeMVIndex = item.tag-1;
                [item setSelected:YES];
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
                NSString *fileName = [files lastObject];
                if ([fileName isEqualToString:@"__MACOSX"]) {
                    fileName = [files firstObject];
                }
                filePath = [path stringByAppendingPathComponent:fileName];
                NSString *itemConfigPath = [filePath stringByAppendingPathComponent:@"config.json"];
                NSData *jsonData = [[NSData alloc] initWithContentsOfFile:itemConfigPath];
                NSMutableDictionary *themeDic = [RDHelpClass objectForData:jsonData];
                
                NSString *dataPth = [filePath stringByAppendingPathComponent:@"data.json"];
                NSData *data = [[NSData alloc]initWithContentsOfFile:dataPth];
                NSDictionary *jsonDict = [RDHelpClass objectForData:data];
                NSArray *layersArray = jsonDict[@"layers"];
                if (jsonDict) {
                    mvEffectFps = roundf([[jsonDict objectForKey:@"duration"] floatValue]/[[jsonDict objectForKey:@"time"] floatValue]);
                }
                _mvDataPointArray = [NSMutableArray new];
                for (NSDictionary *dict in layersArray) {
                    NSString *dataPointPth = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",dict[@"data"]]];
                    NSData *pointJsonData = [[NSData alloc]initWithContentsOfFile:dataPointPth];
                    NSArray * pointJsonArray  = [RDHelpClass objectForData:pointJsonData];
                    [_mvDataPointArray addObject:pointJsonArray];
                }
                selectMVEffectBack = nil;
                NSMutableArray *effectVideos = [[[themeDic objectForKey:@"middle"] objectForKey:@"effects"] mutableCopy];
                [effectVideos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSDictionary *dic = [effectVideos objectAtIndex:idx];
                    if([[dic objectForKey:@"fileName"] length] == 0)
                    {
                        [effectVideos removeObject:dic];
                    }
                }];
                if(selectMVEffects){
                    [selectMVEffects removeAllObjects];
                    selectMVEffects = nil;
                }
                selectMVEffects = [NSMutableArray array];
                [effectVideos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    VVMovieEffect *mvEffect = [[VVMovieEffect alloc] init];
                    NSString *videoFilePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[obj objectForKey:@"fileName"]]];
                    double start = [[obj objectForKey:@"begintime"] doubleValue];
                    double duration = [[obj objectForKey:@"duration"] doubleValue];
                    NSString *shader = [obj objectForKey:@"filter"];
                    CMTimeRange showTimeRange=CMTimeRangeMake(CMTimeMakeWithSeconds(start,TIMESCALE), CMTimeMakeWithSeconds(duration,TIMESCALE));
                    mvEffect.url = [NSURL fileURLWithPath:videoFilePath];
                    if (duration == 0.0) {
                        showTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(start,TIMESCALE), [AVAsset assetWithURL:mvEffect.url].duration);
                    }
                    mvEffect.timeRange = showTimeRange;
                    mvEffect.shouldRepeat = [obj[@"repeat"] boolValue];
                    
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
                if ([[themeDic objectForKey:@"sound"] length] > 0) {
                    RDMusic *music = [RDMusic new];
                    music.url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",filePath,[themeDic objectForKey:@"sound"]]];
                    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:music.url options:nil];
                    music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
                    music.volume = (yuanyinOn ? self.musicVolume : 1);
                    
                    mvMusicArray = [NSMutableArray arrayWithObject:music];
                }
                NSString *musicFileName = [[themeDic objectForKey:@"music"] objectForKey:@"fileName"];
                if(musicFileName){
                    _musicURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",filePath,musicFileName]];
                    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_musicURL options:nil];
                    float start = [[[themeDic objectForKey:@"music"] objectForKey:@"begintime"] floatValue];
                    float duration = [[[themeDic objectForKey:@"music"] objectForKey:@"duration"] floatValue];
                    if (duration == 0) {
                        duration = CMTimeGetSeconds(asset.duration) - start;
                    }
                    _musicTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(start, TIMESCALE), CMTimeMakeWithSeconds(duration, TIMESCALE));
                    if(selectMusicIndex == 2){
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]) setSelected:NO];
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]) stopScrollTitle];
                        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]).itemTitleLabel.text = RDLocalizedString(@"本地", nil);
                    }else if(selectMusicIndex == 3){
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]) setSelected:NO];
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]) stopScrollTitle];
                        ((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]).itemTitleLabel.text = RDLocalizedString(@"云音乐", nil);
                    }else if(selectMusicIndex > 1) {
                        [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]) setSelected:NO];
                    }
                    selectMusicIndex = 1;
                    _musicVolume = 0.5;
                    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex + 1]) setSelected:YES];
                }
                if(_musicURL){
                    _musicVolumeSlider.value =  0.5/volumeMultipleM;
                }
                [self initPlayer];
            }
        }
    }else if (item.type == 4) {//MARK:变声
        if (item.tag-2 != selectedSoundEffectIndex || item.tag-2 == -1) {
#if !ENABLEAUDIOEFFECT
            [self playVideo:NO];
#endif
            [((ScrollViewChildItem *)[soundEffectScrollView viewWithTag:selectedSoundEffectIndex+2]) setSelected:NO];
            [item setSelected:YES];
            selectedSoundEffectIndex = item.tag-2;
            if (selectedSoundEffectIndex == -1) {
                self.customSoundView.hidden = NO;
                __weak typeof(self) weakSelf = self;
                [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.identifier.length > 0) {
                            [weakSelf.videoCoreSDK setAudioFilter:RDAudioFilterTypeCustom identifier:obj.identifier];
                        }
                    }];
                }];
            }else {
                _customSoundView.hidden = YES;
                __weak typeof(self) weakSelf = self;
                __block float pitch = 1.0;
                [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene*  _Nonnull scene, NSUInteger idx, BOOL * _Nonnull stop) {
                    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.identifier.length > 0) {
                            if (selectedSoundEffectIndex <= RDAudioFilterTypeCartoon) {
                                pitch = [weakSelf.videoCoreSDK setAudioFilter:(RDAudioFilterType)selectedSoundEffectIndex identifier:obj.identifier];
                            }else {
                                pitch = [weakSelf.videoCoreSDK setAudioFilter:(RDAudioFilterType)(selectedSoundEffectIndex+1) identifier:obj.identifier];
                            }
                        }
                    }];
                }];
                soundEffectSlider.value = logf(pitch*1200)/logf(2.0);
                NSLog(@"pitch:%.2f value:%.2f", pitch, soundEffectSlider.value);
                soundEffectLabel.text = [NSString stringWithFormat:@"%.2f", pow(2.0, soundEffectSlider.value/1200.0)];
#if ENABLEAUDIOEFFECT
                if (!_videoCoreSDK.isPlaying) {
//                    [self playVideo:YES];
                }
#else
                if (selectedSoundEffectIndex == 0) {
                    if (_videoCoreSDK.enableAudioEffect) {
                        [_videoCoreSDK stop];
                        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
                        [self performSelector:@selector(refreshAudioEffect:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.1];
                    }
                }else {
                    if (!_videoCoreSDK.enableAudioEffect) {
                        [_videoCoreSDK stop];
                        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
                        [self performSelector:@selector(refreshAudioEffect:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.1];
                    }else {
                        [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                            [weakSelf playVideo:YES];
                        }];
                    }
                }
#endif
            }
        }
    }
}
- (void)refreshAudioEffect:(NSNumber *)enableAudioEffect {
    _videoCoreSDK.enableAudioEffect = [enableAudioEffect boolValue];
    [_videoCoreSDK build];
}

/**检测有多少个Filter正在下载
 */
- (NSInteger)downLoadingFilterCount{
    __block int count = 0;
    [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            if(((ScrollViewChildItem *)obj).downloading){
                count +=1;
            }
        }
    }];
    return count;
}
/**检测有多少个MV正在下载
 */
- (NSInteger)downLoadingMVCount{
    __block int count = 0;
    [_mvChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            if(((ScrollViewChildItem *)obj).downloading){
                count +=1;
            }
        }
    }];
    return count;
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

- (void)enter_cloudMusic:(ScrollViewChildItem *)item{
    if(_videoCoreSDK.isPlaying){
        [self playVideo:NO];
    }
    WeakSelf(self);
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
    RDChooseMusic *cloudMusic = [[RDChooseMusic alloc] init];
    [cloudMusic setTitile:@"选择配乐"];
    cloudMusic.selectedIndex = 0;
    cloudMusic.cloudMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL;
    cloudMusic.soundMusicTypeResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.soundMusicTypeResourceURL;
    cloudMusic.soundMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.soundMusicResourceURL;
    cloudMusic.isNOSound = YES;
    cloudMusic.isLocal = NO;
    cloudMusic.backBlock = ^{
        if(selectMusicIndex > 0){
            [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:YES];
            if(selectMusicIndex ==2 || selectMusicIndex ==3 ){
                [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) startScrollTitle];
            }
        }
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
        _musicVolumeBtn.selected = NO;
        [self musicVolume_Btn];
        [weakSelf initPlayer];
    };
    [self.navigationController pushViewController:cloudMusic animated:YES];
}
- (void)enter_localMusic:(ScrollViewChildItem *)item{
    if(_videoCoreSDK.isPlaying){
        [self playVideo:NO];
    }
    __weak typeof(self) myself = self;
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:NO];
    [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) stopScrollTitle];
    RDLocalMusicViewController *localmusic = [[RDLocalMusicViewController alloc] init];
    localmusic.backBlock = ^{
        if(selectMusicIndex > 0){
            [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) setSelected:YES];
            if(selectMusicIndex ==2 || selectMusicIndex ==3 ){
                [((ScrollViewChildItem *)[_musicChildsView viewWithTag:selectMusicIndex+1]) startScrollTitle];
            }
        }
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
        
        _musicVolumeBtn.selected = NO;
        [self musicVolume_Btn];
        [myself initPlayer];
        
    };
    [self.navigationController pushViewController:localmusic animated:YES];
}

- (void)dealloc{
    NSLog(@"%s",__func__);

    ((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV = enableMV;
    
    [filterFxImageArray enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.image = nil;
    }];
    _videoTrimmerView.delegate = nil;
    
    [_videoTrimmerView.frameView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if( [obj isKindOfClass:[UIImageView class]] )
        {
            ((UIImageView*)obj).image = nil;
        }
    }];
    
    [_videoTrimmerView removeFromSuperview];
    
    _videoCoreSDK.delegate = nil;
    [_videoCoreSDK stop];
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK = nil;
   
    thumbImageVideoCore.delegate = nil;
     [thumbImageVideoCore stop];
    thumbImageVideoCore = nil;
    if (_commonAlertView) {
        [_commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
        _commonAlertView.delegate = nil;
        _commonAlertView = nil;
    }
    [customFilterArray removeAllObjects];
    [fillColorItems removeAllObjects];
    fillColorItems = nil;
    oldStickerCaptionRangeViewFile = nil;
    [_addEffectsByTimeline clear];
    if( saveDraftBtn.enabled )
    {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( obj.filtImagePatch )
                [RDHelpClass deleteMaterialThumbnail:obj.filtImagePatch];
            
        }];
    }
    else if( !_draft )
    {
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if( obj.filtImagePatch )
                [RDHelpClass deleteMaterialThumbnail:obj.filtImagePatch];
            
        }];
    }
    [self deleteCanvasView];
    
    if(_watermarkView)
    {
        [_watermarkScrollView removeFromSuperview];
        _watermarkScrollView = nil;
        
        [_toobarWatermarkView removeFromSuperview];
        _toobarWatermarkView = nil;
        
        [_watermarkSizeSlider removeFromSuperview];
        _watermarkSizeSlider = nil;
        
        [_watermarkRotateSlider removeFromSuperview];
        _watermarkRotateSlider = nil;
        
        [_watermarkAlhpaSlider removeFromSuperview];
        _watermarkAlhpaSlider = nil;
        
        [_watermarkBasisView removeFromSuperview];
        _watermarkBasisView = nil;
        
        [_watermarkPosiView removeFromSuperview];
        _watermarkPosiView = nil;
    }
    
}
    
#pragma mark- 随机转场
-(void)RandomTransition:(NSMutableArray <RDFile *> *) fileList
{
    NSMutableArray *transitionList = [NSMutableArray array];
    [transitionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [transitionList addObjectsFromArray:obj[@"data"]];
    }];
    [fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = arc4random()%(transitionList.count);
        NSString *transitionName = transitionList[index];
        if ([transitionName pathExtension]) {
            transitionName = [transitionName stringByDeletingPathExtension];
        }
        __block NSString *typeName = kDefaultTransitionTypeName;
        [transitionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj1 isEqualToString:transitionName]) {
                    typeName = obj[@"typeName"];
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
        NSString *maskpath = [RDHelpClass getTransitionPath:typeName itemName:transitionName];
        NSURL *maskUrl = maskpath.length == 0 ? nil : [NSURL fileURLWithPath:maskpath];
        if(obj.fileType == kFILEVIDEO)
        {
            float ftime = CMTimeGetSeconds(obj.videoTimeRange.duration)/2.0;
            obj.transitionDuration = (ftime < 1.0) ? ftime : 1.0;
        }
        else {
            obj.transitionDuration = 1.0;
        }
        obj.transitionMask = maskUrl;
        obj.transitionTypeName = typeName;
        obj.transitionName = transitionName;
    }];
}

#pragma mark- 进度条
-(void)initVideoTrimmerView
{
    CGRect rect = CGRectMake(0, 15, _captionVideoView.frame.size.width, _captionVideoView.frame.size.height-15);
    _videoTrimmerView = [[CaptionVideoTrimmerView alloc] initWithFrame:rect videoCore: _videoCoreSDK];
    _videoTrimmerView.backgroundColor = [UIColor clearColor];
    [_videoTrimmerView setClipTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE))];
    [_videoTrimmerView setThemeColor:[UIColor lightGrayColor]];
    _videoTrimmerView.tag = 1;
    [_videoTrimmerView setDelegate:self];
    _videoTrimmerView.scrollView.decelerationRate = 0.8;
    _videoTrimmerView.piantouDuration = 0;
    _videoTrimmerView.pianweiDuration = 0;
    _videoTrimmerView.rightSpace = 20;
    
    _videoTrimmerView.thumbTimes = thumbTimes.count;
//    [_videoCoreSDK getImageAtTime:kCMTimeZero scale:0.3 completion:^(UIImage *image) {
//        [_videoTrimmerView resetSubviews:image];
//    }];
    
    [_captionVideoView addSubview:_videoTrimmerView];
}

- (void)capationScrollViewWillBegin:(CaptionVideoTrimmerView *)trimmerView
{
    [self playVideo:NO];
}
-(UIView *)captionVideoView
{
    if( !_captionVideoView )
    {
        _captionVideoView = [[UIView alloc] initWithFrame:CGRectMake(0, bottomViewRect.size.height/2.0 - 44 - (iPhone4s ? (45 - 44)/2.0 : (50 - 45)/2.0)-15 + 15, _functionalAreaView.frame.size.width, 45+15)];
        _captionVideoView.backgroundColor = TOOLBAR_COLOR;
        [self initVideoTrimmerView];
        
        [_captionVideoView addSubview:self.addMaterialBtn];
        
        _spanView = [[UIView alloc] initWithFrame:CGRectMake((_videoTrimmerView.frame.size.width - 3)/2.0, 5-2+15, 3, _captionVideoView.frame.size.height-15-1)];
        _spanView.backgroundColor = [UIColor whiteColor];
        _spanView.layer.cornerRadius = 1.5;
        [_captionVideoView addSubview:_spanView];
        [_captionVideoView addSubview:self.captionPlayBtnView];
        [_captionVideoView addSubview:self.captionVideoDurationTimeLbl];
        [_captionVideoView addSubview:self.captionVideoCurrentTimeLbl];
    }
    return _captionVideoView;
}

- (UILabel *)captionVideoDurationTimeLbl{
    if(!_captionVideoDurationTimeLbl){
        _captionVideoDurationTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake(_captionVideoView.frame.size.width - 100 - 15,  0, 100, 15)];
        _captionVideoDurationTimeLbl.textAlignment = NSTextAlignmentRight;
        _captionVideoDurationTimeLbl.textColor = UIColorFromRGB(0xababab);
        _captionVideoDurationTimeLbl.text = [RDHelpClass timeToStringFormat: _videoCoreSDK.duration];
        _captionVideoDurationTimeLbl.font = [UIFont systemFontOfSize:10];
    }
    return _captionVideoDurationTimeLbl;
}

- (UILabel *)captionVideoCurrentTimeLbl{
    if(!_captionVideoCurrentTimeLbl){
        _captionVideoCurrentTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake((_captionVideoView.frame.size.width - 100)/2.0,  0, 100, 15)];
        _captionVideoCurrentTimeLbl.textAlignment = NSTextAlignmentCenter;
        _captionVideoCurrentTimeLbl.textColor = [UIColor whiteColor];
        _captionVideoCurrentTimeLbl.text = @"0.00";
        _captionVideoCurrentTimeLbl.font = [UIFont systemFontOfSize:10];
    }
    return _captionVideoCurrentTimeLbl;
}

-(UIView *)captionPlayBtnView
{
    if( !_captionPlayBtnView )
    {
        _captionPlayBtnView = [[UIView alloc] initWithFrame:CGRectMake(0, 5+15, 49, _captionVideoView.frame.size.height-15-5)];
        _captionPlayBtnView.backgroundColor = [UIColor clearColor];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)TOOLBAR_COLOR.CGColor, (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor];
        gradientLayer.locations = @[@0.3, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        gradientLayer.frame = CGRectMake(0, 0, _captionPlayBtnView.bounds.size.width*2/6.0, _captionPlayBtnView.bounds.size.height);
        [_captionPlayBtnView.layer addSublayer:gradientLayer];
        
        _captionPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _captionPlayBtn.backgroundColor = [UIColor clearColor];
        _captionPlayBtn.frame = CGRectMake(5, (_captionPlayBtnView.bounds.size.height-44)/2.0 , 44, 44);
        [_captionPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_captionPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [_captionPlayBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
        [_captionPlayBtnView addSubview:_captionPlayBtn];
    }
    return _captionPlayBtnView;
}


//添加素材
-(UIButton *)addMaterialBtn
{
    if( !_addMaterialBtn )
    {
        _addMaterialBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _addMaterialBtn.backgroundColor = [UIColor clearColor];
        float addBtnHeight = _captionVideoView.frame.size.height - 20;
        _addMaterialBtn.frame = CGRectMake(_captionVideoView.frame.size.width - addBtnHeight,  15 + 5, addBtnHeight, addBtnHeight  );
        UIImageView *btniconView = [[UIImageView alloc] init];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor, (__bridge id)TOOLBAR_COLOR.CGColor];
        
        gradientLayer.locations = @[@0.3, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        gradientLayer.frame = CGRectMake(0, 0, _addMaterialBtn.bounds.size.width*5.0/6.0, _addMaterialBtn.bounds.size.height);
        [_addMaterialBtn.layer addSublayer:gradientLayer];
        
        btniconView.frame = CGRectMake(_addMaterialBtn.bounds.size.width*5.0/6.0, 0, _addMaterialBtn.bounds.size.width*1.0/6.0, _addMaterialBtn.bounds.size.height);
        btniconView.backgroundColor = UIColorFromRGB(0x000000);
         [_addMaterialBtn addSubview:btniconView];
        
        UIImageView *btniconView1 = [[UIImageView alloc] init];
        btniconView1.image = [RDHelpClass imageWithContentOfFile:@"/jianji/scrollviewChildItems/添加镜头默认_"];
        btniconView1.frame = CGRectMake(0, (_addMaterialBtn.bounds.size.height-_addMaterialBtn.bounds.size.width)/2.0, _addMaterialBtn.bounds.size.width, _addMaterialBtn.bounds.size.width);
        [_addMaterialBtn addSubview:btniconView1];
        
        [_addMaterialBtn addTarget:self action:@selector(tapAddButton:) forControlEvents:UIControlEventTouchUpInside];
        [_addMaterialBtn setImageEdgeInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
        
    }
    return _addMaterialBtn;
}
/**添加文件
 */
- (void)tapAddButton:(UIButton *)sender{
    [self.view addSubview:self.addLensView];
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
//
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
    if( _addLensView )
    {
        [_addLensView removeFromSuperview];
        _addLensView = nil;
    }
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
    Btn.frame = CGRectMake((15 +  toolItemWidth*3.0/2.0)*index + fwidth, (_addLensView.frame.size.height - kNavigationBarHeight)/3.0 + (hegiht - toolItemBtnHeight)/2.0  , toolItemWidth, toolItemBtnHeight);
    Btn.backgroundColor = [UIColor clearColor];
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, ImageWidth, Btn.frame.size.width, TextHeight)];
    label1.textAlignment = NSTextAlignmentCenter;
    label1.textColor = UIColorFromRGB(0x8d8c91);
    label1.text = str;
    label1.font = [UIFont systemFontOfSize:12];
//    if ([UIScreen mainScreen].bounds.size.width >= 414) {
//        label1.font = [UIFont systemFontOfSize:11];
//    }else {
//        label1.font = [UIFont systemFontOfSize:10];
//    }
    [Btn addSubview:label1];
    
    UIImageView *thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake((Btn.frame.size.width - ImageWidth)/2.0, 0, ImageWidth, ImageWidth)];
    thumbnailIV.image = [UIImage imageWithContentsOfFile:ImageStr];
    thumbnailIV.layer.cornerRadius = (ImageWidth)/2.0;
    thumbnailIV.layer.masksToBounds = YES;
    [Btn addSubview:thumbnailIV];
    
    [Btn addTarget:self action:@selector(clickConnectToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
    return Btn;
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
//        case 3:
//        {
////            [self changeTransition:selectFileIndex];
//            [self changeTransition];
//        }
//            break;
        default:
            break;
    }
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
    mainVC.textPhotoProportion = _exportVideoSize.width/(float)_exportVideoSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {

        [myself addFileWithList:filelist withType:type touchConnect: isTouch];
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
    
}
- (void)addFileWithList:(NSMutableArray *)filelist withType:(SUPPORTFILETYPE)type touchConnect:(BOOL) istouch{
    [_fileList addObjectsFromArray:filelist];
    
    [filelist enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDFile * file = ((RDFile*)obj);
        [RDHelpClass fileCrop:file atfileCropModeType:selectProportionIndex atEditSize:proportionVideoSize];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        seekTime = _videoCoreSDK.currentTime;
        [self refreshRdPlayer:_videoCoreSDK];
        
        [self Core_loadTrimmerViewThumbImage];
        
//        [thumbImageVideoCore stop];
//        thumbImageVideoCore.delegate = nil;
//        thumbImageVideoCore = nil;
//        [self performSelector:@selector(initThumbImageVideoCore) withObject:nil afterDelay:0.1];
        [self cancelAddLens];
    });
}

/**文字板
 */
- (void)enter_TextPhotoVC:(BOOL)edit{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
        [_videoCoreSDK stop];
    }
    CustomTextPhotoViewController *cusTextview;
    RDFile *file = [_fileList lastObject];
    if(edit){
        if(CGSizeEqualToSize(file.customTextPhotoFile.photoRectSize, CGSizeZero)){
            file.customTextPhotoFile.photoRectSize = _exportVideoSize;
        }
        CustomTextPhotoFile *customTextPhotoFile = file.customTextPhotoFile;
        cusTextview  = [[CustomTextPhotoViewController alloc] initWithFile:customTextPhotoFile];
    }else{
        cusTextview = [[CustomTextPhotoViewController alloc] init];
        cusTextview.videoProportion = _exportVideoSize.width/(float)_exportVideoSize.height;
    }
    cusTextview.delegate = self;
    cusTextview.touchUpType = 0;
    [self.navigationController pushViewController:cusTextview animated:YES];
}
#pragma mark- CustomTextDelegate
- (void)getCustomTextImagePath:(NSString *)textImagePath thumbImage:(UIImage *)thumbImage customTextPhotoFile:(CustomTextPhotoFile *)file touchUpType:(NSInteger)touchUpType change:(BOOL)flag{
    @autoreleasepool {
            [self cancelAddLens];
            if(flag){
                RDFile *selectFile = [_fileList objectAtIndex:_fileList.count-1];
#if isUseCustomLayer
                selectFile.contentURL = [NSURL fileURLWithPath:textImagePath];
                selectFile.thumbImage = thumbImage;
                selectFile.cropRect = CGRectZero;
                selectFile.customTextPhotoFile = file;
                dispatch_async(dispatch_get_main_queue(), ^{
                    seekTime = _videoCoreSDK.currentTime;
                    [self refreshRdPlayer:_videoCoreSDK];
                    [self Core_loadTrimmerViewThumbImage];
//                    [thumbImageVideoCore stop];
//                    thumbImageVideoCore.delegate = nil;
//                    thumbImageVideoCore = nil;
//                    [self performSelector:@selector(initThumbImageVideoCore) withObject:nil afterDelay:0.1];
                });
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
                        dispatch_async(dispatch_get_main_queue(), ^{
                            seekTime = _videoCoreSDK.currentTime;
                            [self refreshRdPlayer:_videoCoreSDK];
                            [self Core_loadTrimmerViewThumbImage];
//                            [thumbImageVideoCore stop];
//                            thumbImageVideoCore.delegate = nil;
//                            thumbImageVideoCore = nil;
//                            [self performSelector:@selector(initThumbImageVideoCore) withObject:nil afterDelay:0.1];
                        });
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
                [_fileList insertObject:rdFile atIndex:_fileList.count-1+1];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    seekTime = _videoCoreSDK.currentTime;
                    [self refreshRdPlayer:_videoCoreSDK];
                    [self Core_loadTrimmerViewThumbImage];
//                    [thumbImageVideoCore stop];
//                    thumbImageVideoCore.delegate = nil;
//                    thumbImageVideoCore = nil;
//                    [self performSelector:@selector(initThumbImageVideoCore) withObject:nil afterDelay:0.1];
                });
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

#pragma mark- 定格

-(int)passThroughIndexAtCurrentTime:(CMTime) currentTime
{
    float fCurrentTime = CMTimeGetSeconds(currentTime);
    int index = 0;
    for (int i = 0; i < _fileList.count; i++) {
        CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:i];
        float start = CMTimeGetSeconds(timeRange.start);
        float end = start + CMTimeGetSeconds(timeRange.duration);
        if( fCurrentTime >= start && fCurrentTime < end )
        {
            index = i;
            break;
        }
    }
    return index;
}

-(NSString *)getImagePatch:( UIImage * ) image atFileURl:(NSURL *) fileURL
{
    NSString *fileName = @"";
    if ([fileURL.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [fileURL.scheme.lowercaseString isEqualToString:@"assets-library"])
    {
        NSRange range = [fileURL.absoluteString rangeOfString:@"?id="];
        if (range.location != NSNotFound) {
            fileName = [fileURL.absoluteString substringFromIndex:range.length + range.location];
            range = [fileName rangeOfString:@"&ext"];
            fileName = [fileName substringToIndex:range.location];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }
    }else {
        fileName = [[fileURL.path lastPathComponent] stringByDeletingPathExtension];
    }
    NSString *path = NSOpenStepRootDirectory();
    NSString *folderPath = [path stringByAppendingPathComponent:@"VideFreeze"];
    fileName = [NSString stringWithFormat:@"%@",fileName];
    NSString *str = [folderPath stringByAppendingPathComponent:fileName];
    
    
    [UIImagePNGRepresentation(image) writeToFile:str atomically:YES];
    
    return str;
}

-(void)operationRating:(CMTime) currentTime
{
    int index = [self passThroughIndexAtCurrentTime:currentTime];
    
     RDFile *file = [RDFile new];
    //定格需要的那一帧图片 保存作为素材使用
    {
        file.contentURL = [NSURL fileURLWithPath:fXArray[fXArray.count-1].ratingFrameTexturePath];
        file.fileType = kFILEIMAGE;
        file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
        file.speedIndex = 1;
    }
    
    RDFile * beforeFile = [_fileList[index] mutableCopy];
    RDFile * RearFile = [_fileList[index] mutableCopy];
    
    CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:index];
    
    
    
    float beforeDuration = (CMTimeGetSeconds(currentTime) - CMTimeGetSeconds(timeRange.start))/_fileList[index].speed;
    if(beforeFile.fileType == kFILEVIDEO){
        if(beforeFile.isReverse){
           beforeFile.reverseVideoTimeRange = CMTimeRangeMake(_fileList[index].imageTimeRange.start , CMTimeMakeWithSeconds(beforeDuration,TIMESCALE));
        }
        else{
            beforeFile.videoTrimTimeRange = CMTimeRangeMake(_fileList[index].imageTimeRange.start , CMTimeMakeWithSeconds(beforeDuration,TIMESCALE));;
        }
    }
    else{
        beforeFile.imageTimeRange = CMTimeRangeMake(_fileList[index].imageTimeRange.start , CMTimeMakeWithSeconds(beforeDuration,TIMESCALE));
    }
    
//    float RearStart = beforeDuration;
    float RearDuratin = CMTimeGetSeconds(timeRange.duration)/_fileList[index].speed - beforeDuration;
    if(RearFile.fileType == kFILEVIDEO){
        if(RearFile.isReverse){
           RearFile.reverseVideoTimeRange = CMTimeRangeMake( CMTimeAdd(beforeFile.videoTrimTimeRange.start, beforeFile.videoTrimTimeRange.duration) , CMTimeMakeWithSeconds(RearDuratin,TIMESCALE));
        }
        else{
            RearFile.videoTrimTimeRange = CMTimeRangeMake(CMTimeAdd(beforeFile.videoTrimTimeRange.start, beforeFile.videoTrimTimeRange.duration) , CMTimeMakeWithSeconds(RearDuratin,TIMESCALE));;
        }
    }
    else{
        RearFile.imageTimeRange = CMTimeRangeMake(CMTimeAdd(beforeFile.videoTrimTimeRange.start, beforeFile.videoTrimTimeRange.duration) , CMTimeMakeWithSeconds(RearDuratin,TIMESCALE));
    }
    
    
    _fileList[index] = beforeFile;
    NSMutableArray * array = [NSMutableArray new];
    [array addObject:file];
    [array addObject:RearFile];
    
    NSRange range = NSMakeRange(index + 1, [array count]);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [_fileList insertObjects:array atIndexes:indexSet];
    
    
}

#pragma mark - 背景 画布 状态栏
-(UIView *)toobarCanvasView
{
    if( !_toobarCanvasView )
    {
        _toobarCanvasView = [[UIView alloc] initWithFrame:CGRectMake(0, _canvasViewHeight, _canvasView.frame.size.width, _toolBarView.bounds.size.height)];
        
        UIButton * toobarCanvasCancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [toobarCanvasCancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [toobarCanvasCancelBtn addTarget:self action:@selector(toobarCanvas_back:) forControlEvents:UIControlEventTouchUpInside];
        [_toobarCanvasView addSubview:toobarCanvasCancelBtn];
        
         UIButton * toobarCanvasFinishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [toobarCanvasFinishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [toobarCanvasFinishBtn addTarget:self action:@selector(toobarCanvas_Finish:) forControlEvents:UIControlEventTouchUpInside];
        [_toobarCanvasView addSubview:toobarCanvasFinishBtn];
        
        _toobarCanvasLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, _toobarCanvasView.frame.size.width - 88, 44)];
        _toobarCanvasLabel.textAlignment = NSTextAlignmentCenter;
        _toobarCanvasLabel.font = [UIFont boldSystemFontOfSize:17];
        _toobarCanvasLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];;
        [_toobarCanvasView addSubview:_toobarCanvasLabel];
//        _toobarCanvasView.hidden = YES;
    }
    return _toobarCanvasView;
}

-(void)toobarCanvas_back:(UIButton *) sender
{
    if( _CurrentCanvasType != 0 )
    {
        if( self.canvas_syncContainer )
        {
            if( _canvas_syncContainer_X_Left )
            {
                [_canvas_syncContainer_X_Left removeFromSuperview];
                _canvas_syncContainer_X_Left = nil;
                [_canvas_syncContainer_X_Right removeFromSuperview];
                _canvas_syncContainer_X_Right = nil;
                [_canvas_syncContainer_Y_Left removeFromSuperview];
                _canvas_syncContainer_Y_Left = nil;
                [_canvas_syncContainer_Y_Right removeFromSuperview];
                _canvas_syncContainer_Y_Right = nil;
            }
            [self.canvas_syncContainer removeFromSuperview];
            self.canvas_syncContainer = nil;
            if( self.canvas_pasterView )
            {
                [self.canvas_pasterView removeFromSuperview];
                self.canvas_pasterView = nil;
            }
        }
        
        if( _canvas_currentFIleAlpha != -1.0 )
        {
            RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = _canvas_currentFIleAlpha;
            }];
            _canvas_currentFIleAlpha = -1;
            [_videoCoreSDK refreshCurrentFrame];
        }
        
        
        RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( _fileList[_canvas_CurrentFileIndex].rectInScene.size.width > 0 )
            {
                obj.rectInVideo = _fileList[_canvas_CurrentFileIndex].rectInScene;
            }
            else
            {
                obj.rectInVideo = _fileList[_canvas_CurrentFileIndex].rectInScene;
                obj.crop = _fileList[_canvas_CurrentFileIndex].crop;
            }
            
            obj.rotate = _fileList[_canvas_CurrentFileIndex].rotate + _fileList[_canvas_CurrentFileIndex].BackgroundRotate;
            
        }];
        
        scene.backgroundAsset = [RDHelpClass canvasFile:_fileList[_canvas_CurrentFileIndex].BackgroundFile];
        scene.backgroundColor = _fileList[_canvas_CurrentFileIndex].backgroundColor;
        
       
    }
    
    _canvasView.hidden = YES;
    _playButton.hidden = NO;
    [self ReturnAdjustment:YES];
    if( self.canvas_syncContainer )
    {
        if( _canvas_syncContainer_X_Left )
        {
            [_canvas_syncContainer_X_Left removeFromSuperview];
            _canvas_syncContainer_X_Left = nil;
            [_canvas_syncContainer_X_Right removeFromSuperview];
            _canvas_syncContainer_X_Right = nil;
            [_canvas_syncContainer_Y_Left removeFromSuperview];
            _canvas_syncContainer_Y_Left = nil;
            [_canvas_syncContainer_Y_Right removeFromSuperview];
            _canvas_syncContainer_Y_Right = nil;
        }
        if( self.canvas_pasterView )
        {
            [self.canvas_pasterView removeFromSuperview];
            self.canvas_pasterView = nil;
        }
        [self.canvas_syncContainer removeFromSuperview];
        self.canvas_syncContainer = nil;
    }
    
    ((UIButton*)[_canvasScrollView viewWithTag:_CurrentCanvasType]).selected = false;
    ((UIButton*)[_canvasScrollView viewWithTag:_CurrentCanvasType]).font = [UIFont systemFontOfSize:14];
    
     [_videoCoreSDK refreshCurrentFrame];
//    _CurrentCanvasType = 0;
}

-(void)pasterView_canvasRect:(  CGRect * ) rect atRotate:( double * ) rotate
{
    CGPoint point = CGPointMake(self.canvas_pasterView.center.x/self.canvas_syncContainer.frame.size.width, self.canvas_pasterView.center.y/self.canvas_syncContainer.frame.size.height);
    float scale = [self.canvas_pasterView getFramescale];
    
    (*rect).size = CGSizeMake(self.canvas_pasterView.contentImage.frame.size.width*scale / self.canvas_syncContainer.bounds.size.width, self.canvas_pasterView.contentImage.frame.size.height*scale / self.canvas_syncContainer.bounds.size.height);
    (*rect).origin = CGPointMake(point.x - (*rect).size.width/2.0, point.y - (*rect).size.height/2.0);
    CGFloat radius = atan2f(self.canvas_pasterView.transform.b, self.canvas_pasterView.transform.a);
    (*rotate) = - radius * (180 / M_PI);
}

-(void)toobarCanvas_Finish:(UIButton *) sender
{
    if( _CurrentCanvasType != 0 )
    {
        float scale = [self.canvas_pasterView getFramescale];
        
        CGRect rect = CGRectMake(0, 0, 1, 1);
        double rotate = 0;
        [self pasterView_canvasRect:&rect atRotate:&rotate];
        
        CGRect rectInFile = CGRectMake(self.canvas_pasterView.frame.origin.x/self.canvas_pasterView.frame.size.width, self.canvas_pasterView.frame.origin.y/self.canvas_pasterView.frame.size.height, self.canvas_pasterView.frame.size.width/self.canvas_pasterView.frame.size.width, self.canvas_pasterView.frame.size.height/self.canvas_pasterView.frame.size.height);
        
        if (self.canvas_syncContainer.bounds.size.width == self.canvas_syncContainer.bounds.size.height) {
            _fileList[_canvas_CurrentFileIndex].rectInScale  = scale*0.25;
        }else if (self.canvas_syncContainer.bounds.size.width < self.canvas_syncContainer.bounds.size.height) {
            _fileList[_canvas_CurrentFileIndex].rectInScale  = scale*0.5;
        }else {
           _fileList[_canvas_CurrentFileIndex].rectInScale  =  scale*0.5;
        }

        
        if( self.canvas_syncContainer )
        {
            if( _canvas_syncContainer_X_Left )
            {
                [_canvas_syncContainer_X_Left removeFromSuperview];
                _canvas_syncContainer_X_Left = nil;
                [_canvas_syncContainer_X_Right removeFromSuperview];
                _canvas_syncContainer_X_Right = nil;
                [_canvas_syncContainer_Y_Left removeFromSuperview];
                _canvas_syncContainer_Y_Left = nil;
                [_canvas_syncContainer_Y_Right removeFromSuperview];
                _canvas_syncContainer_Y_Right = nil;
            }
            [self.canvas_syncContainer removeFromSuperview];
            self.canvas_syncContainer = nil;
            if( self.canvas_pasterView )
            {
                [self.canvas_pasterView removeFromSuperview];
                self.canvas_pasterView = nil;
            }
        }
        
        if( _canvas_currentFIleAlpha != -1.0 )
        {
            RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = _canvas_currentFIleAlpha;
            }];
            _canvas_currentFIleAlpha = -1;
            [_videoCoreSDK refreshCurrentFrame];
        }
        
        _fileList[_canvas_CurrentFileIndex].rectInFile = rectInFile;
               _fileList[_canvas_CurrentFileIndex].rectInScene = rect;
               _fileList[_canvas_CurrentFileIndex].BackgroundRotate = rotate;
               _fileList[_canvas_CurrentFileIndex].fileScale = scale;
               _fileList[_canvas_CurrentFileIndex].backgroundType = _CurrentCanvasType;
        
        RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.alpha = _fileList[_canvas_CurrentFileIndex].backgroundAlpha;
            
            obj.rotate = rotate + _fileList[_canvas_CurrentFileIndex].rotate;
            
            if( _fileList[_canvas_CurrentFileIndex].animationDuration > 0 )
            {
                RDFile * file = _fileList[_canvas_CurrentFileIndex];
                [RDHelpClass setAssetAnimationArray:obj name:file.animationName duration:file.animationDuration center:
                 CGPointMake(file.rectInScene.origin.x + file.rectInScene.size.width/2.0, file.rectInScene.origin.y + file.rectInScene.size.height/2.0) scale:file.rectInScale];
            }
            else
            {
                obj.rectInVideo = rect;
            }
        }];
        
       
        
        if( _CurrentCanvasType == 1 )
        {
            _fileList[_canvas_CurrentFileIndex].backgroundStyle = 0;
            _fileList[_canvas_CurrentFileIndex].BackgroundFile = nil;
            _fileList[_canvas_CurrentFileIndex].BackgroundBlurIntensity = 0;
            
            _fileList[_canvas_CurrentFileIndex].backgroundColor = _canvasColorControl.colorsArr[_canvasColorControl.currentColorIndex];
        }
        else if( _CurrentCanvasType == 2 )
        {
            _fileList[_canvas_CurrentFileIndex].backgroundColor = nil;
            _fileList[_canvas_CurrentFileIndex].backgroundStyle = _canvasStyle_CurrentTag;
            if( _canvasStyle_CurrentTag == 2 )
            {
                _fileList[_canvas_CurrentFileIndex].BackgroundFile = _canvaStyle_PhotoImage;
            }
            else if( _canvasStyle_CurrentTag != 0 ){
                _fileList[_canvas_CurrentFileIndex].BackgroundFile = _currentCanvasStyleFile;
            }
        }
        else
        {
            _fileList[_canvas_CurrentFileIndex].BackgroundFile =_canvasBlurryFile;
            _fileList[_canvas_CurrentFileIndex].BackgroundFile.BackgroundBlurIntensity = _canvasBlurryValue;
        }
        
        if( _useToAllCanvas.selected )
        {
            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                __block bool isBuild = false;
                [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    __block RDFile * file = obj;
                    
                    if( idx != _canvas_CurrentFileIndex )
                    {
                        if( file.fileType == kFILEVIDEO )
                            isBuild = true;
                        
                        file.backgroundStyle = _fileList[_canvas_CurrentFileIndex].backgroundStyle;
                        
                        file.BackgroundFile = [_fileList[_canvas_CurrentFileIndex].BackgroundFile mutableCopy];
                        
                        file.rectInScale = _fileList[_canvas_CurrentFileIndex].rectInScale;
                        
                        file.backgroundColor = _fileList[_canvas_CurrentFileIndex].backgroundColor;
                        file.rectInFile = _fileList[_canvas_CurrentFileIndex].rectInFile;
                        file.rectInScene = _fileList[_canvas_CurrentFileIndex].rectInScene;
                        file.BackgroundRotate = _fileList[_canvas_CurrentFileIndex].BackgroundRotate;
                        file.fileScale = _fileList[_canvas_CurrentFileIndex].fileScale;
                        file.backgroundType = _fileList[_canvas_CurrentFileIndex].backgroundType;
                        
                        if( file.BackgroundFile )
                        {
                            
                            if( _CurrentCanvasType == 2 )
                            {
                                CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:idx];
                                
                                file.BackgroundFile.imageTimeRange = CMTimeRangeMake(kCMTimeZero,timeRange.duration);
                                
                                NSLog(@"场景背景时长%d：%.2f s",idx,CMTimeGetSeconds(file.BackgroundFile.imageTimeRange.duration));
                            }
                            else if( _CurrentCanvasType == 3 ){
                                file.BackgroundFile = [_fileList[idx] mutableCopy];
                                file.BackgroundFile.BackgroundBlurIntensity = _fileList[_canvas_CurrentFileIndex].BackgroundFile.BackgroundBlurIntensity;
                            }
                            
                            RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][idx];
                            
                            if( _CurrentCanvasType == 1 )
                            {
                                scene.backgroundColor = file.backgroundColor;
                            }
                            else
                            {
                                scene.backgroundAsset = [RDHelpClass canvasFile:file.BackgroundFile];
                            }
                            
                            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                
                                
                                obj.rotate = file.rotate + file.BackgroundRotate;
                                
                                if( file.animationDuration > 0 )
                                {
                                    [RDHelpClass setAssetAnimationArray:obj name:file.animationName duration:file.animationDuration center:
                                     CGPointMake(file.rectInScene.origin.x + file.rectInScene.size.width/2.0, file.rectInScene.origin.y + file.rectInScene.size.height/2.0) scale:file.rectInScale];
                                }
                                else{
                                    obj.rectInVideo = file.rectInScene;
                                }
                            }];
                            
                        }
                    }
                }];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if( isBuild )
                    {
                        seekTime = _videoCoreSDK.currentTime;
                        [_videoCoreSDK build];
                        [RDSVProgressHUD dismiss];
                    }
                    else
                    {
                        [_videoCoreSDK refreshCurrentFrame];
                        [RDSVProgressHUD dismiss];
                    }
                });
            });
        }
        else
        {
            [_videoCoreSDK refreshCurrentFrame];
        }
    }
    if( _canvasScrollView )
    {
        UIButton * btn = [_canvasScrollView viewWithTag:_CurrentCanvasType];
        btn.selected = NO;
    }
    
    ((UIButton*)[_canvasScrollView viewWithTag:_CurrentCanvasType]).selected = false;
    ((UIButton*)[_canvasScrollView viewWithTag:_CurrentCanvasType]).font = [UIFont systemFontOfSize:14];
    _canvasView.hidden = YES;
    _playButton.hidden = NO;
    [self ReturnAdjustment:YES];
    
     [_videoCoreSDK refreshCurrentFrame];
}

#pragma mark - 背景 画布
-(UIView *)canvasView
{
    
    bool isRestore = true;
    
    if( !_canvasView )
    {
        isRestore = false;
        _canvasView = [[UIView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + _toolBarView.bounds.size.height )];
        _canvasView.backgroundColor = TOOLBAR_COLOR;
        _canvasViewHeight = bottomViewRect.size.height;
        
        [self.view addSubview:_canvasView];
        
        _canvasScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _canvasView.frame.size.width, _canvasViewHeight*0.269)];
        _canvasScrollView.backgroundColor = TOOLBAR_COLOR;
        _canvasScrollView.showsVerticalScrollIndicator = NO;
        _canvasScrollView.showsHorizontalScrollIndicator = NO;
        _canvasScrollView.tag = 10000;
        [_canvasView addSubview:_canvasScrollView];
        
        float x = 0;
        
        x = [self canvas_Btn:RDLocalizedString(@"颜色", nil) atIndx:1 atX:x atBtn: [[UIButton alloc] init] ];
        x = [self canvas_Btn:RDLocalizedString(@"样式", nil) atIndx:2 atX:x atBtn: [[UIButton alloc] init]];
        x = [self canvas_Btn:RDLocalizedString(@"模糊", nil) atIndx:3 atX:x atBtn: [[UIButton alloc] init]];
        
        //应用到所有场景
        _useToAllCanvas = [UIButton buttonWithType:UIButtonTypeCustom];
        float defaultWidth =  [RDHelpClass widthForString:RDLocalizedString(@"应用到所有", nil)  andHeight:14 fontSize:14] + 50;
        _useToAllCanvas.frame = CGRectMake(_canvasView.frame.size.width - defaultWidth - 5, ( _canvasViewHeight*0.269 - 35 )/2.0  , defaultWidth, 35);
        _useToAllCanvas.titleLabel.font = [UIFont systemFontOfSize:14];
        [_useToAllCanvas setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        _useToAllCanvas.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_useToAllCanvas setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [_useToAllCanvas setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [_useToAllCanvas setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
        [_useToAllCanvas setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_useToAllCanvas setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_useToAllCanvas setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateSelected];
        [_useToAllCanvas setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        [_useToAllCanvas setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
        _useToAllCanvas.backgroundColor = [UIColor clearColor];
        [_useToAllCanvas setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
        [_useToAllCanvas addTarget:self action:@selector(useToAllCanvasOnClick:) forControlEvents:UIControlEventTouchUpInside];
        _useToAllCanvas.selected = NO;
        [_canvasView addSubview:_useToAllCanvas];
        
        [_canvasView addSubview:self.toobarCanvasView];

    }
    
    _toobarCanvasLabel.text = RDLocalizedString(@"画布", nil);
    
    [self showCanvas_pasterView];
    
    if( isRestore )
    {
        [self canvas_restore];
    }
    
    _useToAllCanvas.selected = false;
    
    return _canvasView;
}

-(void)useToAllCanvasOnClick:(UIButton *) sender
{
    sender.selected =  !sender.selected;
}

#pragma mark- 设置画布显示参数
- (void)initCanvas_PasterViewWithFile:(UIImage *)thumbImage {
    [self.canvas_pasterView removeFromSuperview];
    self.canvas_pasterView = nil;
    if (!self.canvas_pasterView) {
        CGSize size = thumbImage.size;
        float width;
        float height;
        if (self.canvas_syncContainer.bounds.size.width == self.canvas_syncContainer.bounds.size.height) {
            width = self.canvas_syncContainer.bounds.size.width/4.0;
            height = width / (size.width / size.height);
        }else if (self.canvas_syncContainer.bounds.size.width < self.canvas_syncContainer.bounds.size.height) {
            width = self.canvas_syncContainer.bounds.size.width/2.0;
            height = width / (size.width / size.height);
        }else {
            height = self.canvas_syncContainer.bounds.size.height/2.0;
            width = height * (size.width / size.height);
        }
        CGRect frame = CGRectMake((self.canvas_syncContainer.bounds.size.width - width)/2.0, (self.canvas_syncContainer.bounds.size.height - height)/2.0, width, height);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        imageView.image = thumbImage;
        
        self.canvas_pasterView = [[RDPasterTextView alloc] initWithFrame:CGRectInset(frame, -8, -8)
                                                   superViewFrame:self.playerView.frame
                                                     contentImage:imageView
                                                syncContainerRect:self.playerView.bounds];
        
        self.canvas_pasterView.mirrorBtn.hidden = NO;
        self.canvas_pasterView.delegate = self;
        [self.canvas_syncContainer addSubview:self.canvas_pasterView];
        [self.canvas_pasterView setSyncContainer:self.canvas_syncContainer];
        if (!_canvas_syncContainer.superview) {
            [_playerView addSubview:_canvas_syncContainer];
        }
    }else {
        self.canvas_pasterView.contentImage.image = thumbImage;
        
        CGSize size = thumbImage.size;
        float width;
        float height;
        if (self.canvas_syncContainer.bounds.size.width == self.canvas_syncContainer.bounds.size.height) {
            width = self.canvas_syncContainer.bounds.size.width/4.0;
            height = width / (size.width / size.height);
        }else if (self.canvas_syncContainer.bounds.size.width <= self.canvas_syncContainer.bounds.size.height) {
            width = self.canvas_syncContainer.bounds.size.width/2.0;
            height = width / (size.width / size.height);
        }else {
            height = self.canvas_syncContainer.bounds.size.height/2.0;
            width = height * (size.width / size.height);
        }
        CGRect frame = CGRectMake((self.canvas_syncContainer.bounds.size.width - width)/2.0, (self.canvas_syncContainer.bounds.size.height - height)/2.0, width, height);
        CGRect rect = CGRectInset(frame, -8, -8);
        [self.canvas_pasterView refreshBounds:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    }
    
    RDFile * file =_fileList[_canvas_CurrentFileIndex];
    
    float fileScale = file.fileScale;
    CGRect rectInScene = file.rectInScene;
    
    if( file.backgroundType == 0 )
    {
        fileScale = 1.0;
        double rotate = 0;
        [self pasterView_canvasRect:&rectInScene atRotate:&rotate];
        
        float scale = [self.canvas_pasterView getFramescale];
        
        if (self.canvas_syncContainer.bounds.size.width == self.canvas_syncContainer.bounds.size.height) {
            scale  = scale*0.25;
        }else if (self.canvas_syncContainer.bounds.size.width < self.canvas_syncContainer.bounds.size.height) {
            scale  = scale*0.5;
        }else {
           scale  =  scale*0.5;
        }

        
        RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.alpha = _fileList[_canvas_CurrentFileIndex].backgroundAlpha;
            
            obj.rotate = rotate + _fileList[_canvas_CurrentFileIndex].rotate;
            
            if( _fileList[_canvas_CurrentFileIndex].animationDuration > 0 )
            {
                RDFile * file = _fileList[_canvas_CurrentFileIndex];
                obj.animate = nil;
                [RDHelpClass setAssetAnimationArray:obj name:file.animationName duration:file.animationDuration center:
                 CGPointMake(rectInScene.origin.x + rectInScene.size.width/2.0, rectInScene.origin.y + rectInScene.size.height/2.0) scale:scale];
            }
            else
            {
                obj.rectInVideo = rectInScene;
            }
        }];
        
        [_videoCoreSDK refreshCurrentFrame];
        
    }
        CGPoint point = CGPointMake(rectInScene.origin.x + rectInScene.size.width/2.0, rectInScene.origin.y + rectInScene.size.height/2.0);
        point = CGPointMake(point.x*self.canvas_syncContainer.frame.size.width, point.y*self.canvas_syncContainer.frame.size.height);
        
        CGAffineTransform transform2 = CGAffineTransformMakeRotation( -file.BackgroundRotate/(180.0/M_PI) );
         self.canvas_pasterView.transform = CGAffineTransformScale(transform2, fileScale, fileScale);
        if( file.fileScale >0 )
            [self.canvas_pasterView setFramescale:file.fileScale];
        else
            [self.canvas_pasterView setFramescale:1.0];
        self.canvas_pasterView.center = point;
    
    [self.canvas_pasterView setCanvasPasterText:true];
    [self.canvas_pasterView setMinScale:1.0/4.0];
    self.canvas_pasterView.mirrorBtn.hidden = YES;
    self.canvas_pasterView.contentImage.alpha = 0.0;
    self.canvas_pasterView.isDrag = true;
}

-(float)canvas_Btn:(NSString *) str atIndx:(int) index atX:(float) x atBtn:(UIButton *) btn
{
    float height = 0;
    
    switch (selecteFunction) {
        case RDAdvanceEditType_BG:
            height = _canvasScrollView.frame.size.height;
            break;
        case RDAdvanceEditType_Watermark:
            height = _watermarkScrollView.frame.size.height;
            break;
        default:
            break;
    }
        
    
    float Width =  [RDHelpClass widthForString:str andHeight:14 fontSize:14] + 20;
    
    UIButton * canvasBtn = btn;
    canvasBtn.tag = index;
    
    canvasBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    canvasBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
    canvasBtn.frame = CGRectMake(x, 0, Width, height);
    
    [canvasBtn setTitle:str forState:UIControlStateNormal];
    [canvasBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
    [canvasBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    
    switch (selecteFunction) {
        case RDAdvanceEditType_BG://画布
            [_canvasScrollView addSubview:canvasBtn];
            [canvasBtn addTarget:self action:@selector(canvasTypeBtnOnClik:) forControlEvents:UIControlEventTouchUpInside];
            if( (index == _CurrentCanvasType) || ( (index == 1) && (_CurrentCanvasType == 0) ) )
            {
                [self canvas_restore];
            }
            break;
        case RDAdvanceEditType_Watermark://加水印
            [_watermarkScrollView addSubview:canvasBtn];
            [canvasBtn addTarget:self action:@selector(WatermarkTypeBtnOnClik:) forControlEvents:UIControlEventTouchUpInside];
            break;
        default:
            break;
    }
    
    return x+Width;
}

-(void)canvasTypeBtnOnClik:(UIButton *) sender
{
    seekTime = _videoCoreSDK.currentTime;
    UIFont *font = [UIFont systemFontOfSize:14];
    self.canvasColorView.hidden = YES;
    self.canvasStyleView.hidden = YES;
    self.canvasBlurryView.hidden = YES;
    
    int canvasType = _CurrentCanvasType;
    
    if( _CurrentCanvasType > 0 )
    {
        ((UIButton*)[_canvasScrollView viewWithTag:_CurrentCanvasType]).selected = false;
        ((UIButton*)[_canvasScrollView viewWithTag:_CurrentCanvasType]).font = font;
    }
    _CurrentCanvasType = sender.tag;
    
    font = [UIFont boldSystemFontOfSize:14];
    
    sender.selected = true;
    sender.font = font;
    
    switch (sender.tag) {
        case 1:
        {
            RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            scene.backgroundAsset = nil;
            scene.backgroundColor = _canvasColorControl.colorsArr[_canvasColorControl.currentColorIndex];
            [_videoCoreSDK refreshCurrentFrame];
            if( (canvasType == 3) && ( _fileList[_canvas_CurrentFileIndex].fileType == kFILEVIDEO ) )
            {
                [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        seekTime = _videoCoreSDK.currentTime;
                        [_videoCoreSDK build];
                        [RDSVProgressHUD dismiss];
                    });
                });
            }
            self.canvasColorView.hidden = NO;
        }
            break;
        case 2:
        {
            self.canvasStyleView.hidden = NO;
            [self initCanvasStyle:[_canvasStyleScrollView viewWithTag:_canvasStyle_CurrentTag]];
            if( ( canvasType == 3 ) && ( _fileList[_canvas_CurrentFileIndex].fileType == kFILEVIDEO ) )
            {
                [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        seekTime = _videoCoreSDK.currentTime;
                        [_videoCoreSDK build];
                        [RDSVProgressHUD dismiss];
                    });
                });
                
            }
        }
            break;
        case 3:
        {
            self.canvasBlurryView.hidden = NO;
            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                _canvasBlurryFile = [_fileList[_canvas_CurrentFileIndex] mutableCopy];
                [self canvasFileCrop:_canvasBlurryFile  atfileCropModeType:selectProportionIndex atEditSize:proportionVideoSize];
                _canvasBlurryFile.BackgroundBlurIntensity = _canvasBlurryValue;
                dispatch_async(dispatch_get_main_queue(), ^{
                    _canvasBlurrySlider.value = _canvasBlurryValue;
                });
                RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
                scene.backgroundAsset = nil;
                scene.backgroundColor = UIColorFromRGB(0x000000);
                
                scene.backgroundAsset = [RDHelpClass canvasFile:_canvasBlurryFile];
                
                if( _fileList[_canvas_CurrentFileIndex].fileType == kFILEVIDEO )
                {
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        seekTime = _videoCoreSDK.currentTime;
                        [_videoCoreSDK build];
                        
                        [RDSVProgressHUD dismiss];
                    });
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        seekTime = _videoCoreSDK.currentTime;
                        [_videoCoreSDK build];
                        [RDSVProgressHUD dismiss];
                    });
                }
                
            });
        }
            break;
        default:
            break;
    }
}

-(void)showCanvas_pasterView
{
    if( !self.canvas_syncContainer )
    {
        self.canvas_syncContainer = [[syncContainerView alloc] init];
        [self.playerView addSubview:_canvas_syncContainer];
        
    }
    
    //视频分辨率
    CGSize presentationSize  = _exportVideoSize;
    CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(presentationSize, _playerView.bounds);
    
    self.canvas_syncContainer.frame = videoRect;
    self.canvas_syncContainer.layer.masksToBounds = YES;
    _playButton.hidden = YES;
    
//    int index = [self passThroughIndexAtCurrentTime:_videoCoreSDK.currentTime];
//
//    _canvas_CurrentFileIndex = index;
    
    RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
    
    _canvas_currentFIleAlpha = _fileList[_canvas_CurrentFileIndex].backgroundAlpha;
    
//    [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//
//        obj.alpha = 0.0;
//    }];
    
    [_videoCoreSDK refreshCurrentFrame];
    
    [self initCanvas_PasterViewWithFile:[self canvasImage:_canvas_CurrentFileIndex]];
    
}

#pragma mark - 画布图片获取
-(UIImage *)canvasImage:(int) index
{
    UIImage *  image = nil;
    if(_fileList[index].fileType == kFILEVIDEO){
    
        CMTime time = kCMTimeZero;
        
        CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:index];
        
        
        float  fTime = CMTimeGetSeconds(_videoCoreSDK.currentTime) - CMTimeGetSeconds(timeRange.start);
        
        CMTimeRange fileTimeRange = kCMTimeRangeZero;
        
        
        if(_fileList[index].isReverse){
            if (CMTimeRangeEqual(kCMTimeRangeZero, _fileList[index].reverseVideoTimeRange)) {
                fileTimeRange = CMTimeRangeMake(kCMTimeZero, _fileList[index].reverseDurationTime);
            }else{
                fileTimeRange = _fileList[index].reverseVideoTimeRange;
            }
            if(CMTimeCompare(fileTimeRange.duration, _fileList[index].reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(_fileList[index].reverseVideoTrimTimeRange.duration)>0){
                fileTimeRange = _fileList[index].reverseVideoTrimTimeRange;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, _fileList[index].videoTimeRange)) {
                fileTimeRange = CMTimeRangeMake(kCMTimeZero, _fileList[index].videoDurationTime);
                if(CMTimeRangeEqual(kCMTimeRangeZero,fileTimeRange)){
                    fileTimeRange = CMTimeRangeMake(kCMTimeZero, [AVURLAsset assetWithURL:_fileList[index].contentURL].duration);
                }
            }else{
                fileTimeRange = _fileList[index].videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _fileList[index].videoTrimTimeRange) && CMTimeCompare(fileTimeRange.duration, _fileList[index].videoTrimTimeRange.duration) == 1){
                fileTimeRange = _fileList[index].videoTrimTimeRange;
            }
        }
        fTime += CMTimeGetSeconds(fileTimeRange.start);
        
        image = [RDHelpClass geScreenShotImageFromVideoURL:_fileList[index].contentURL atTime:CMTimeMakeWithSeconds(fTime, TIMESCALE)  atSearchDirection:false];
        
        
    }else
    {
        image = [RDHelpClass getFullScreenImageWithUrl:_fileList[index].contentURL];
    }
    
    
    image = [RDHelpClass image:image rotation:0 cropRect:_fileList[index].crop];
    image = [RDHelpClass image:image rotation:_fileList[index].rotate cropRect:CGRectZero];
    
    return image;
}


#pragma mark - 背景 画布颜色
-(UIView *)canvasColorView
{
    if( !_canvasColorView )
    {
        _canvasColorView = [[UIView alloc] initWithFrame:CGRectMake(0, _canvasScrollView.frame.size.height, _canvasView.frame.size.width, _canvasViewHeight*0.731 )];
        _canvasColorView.backgroundColor = TOOLBAR_COLOR;
        [_canvasView addSubview:_canvasColorView];
        _canvasColorView.hidden = YES;
        
        //场景背景颜色
        _canvasColorControl = [[SubtitleColorControl alloc] initWithFrame:CGRectMake( 20 , (_canvasColorView.frame.size.height - 30)/2.0, _canvasColorView.frame.size.width-40, 30) Colors:fillColorItems CurrentColor:UIColorFromRGB(0x000000) atisDefault:true];
        [_canvasColorControl  setValue:UIColorFromRGB(0x000000)];
        [_canvasColorView addSubview:_canvasColorControl];
        _canvasColorControl.delegate = self;
    }
    
//    [_canvasView addSubview:self.toobarCanvasView];
//    _toobarCanvasLabel.text = RDLocalizedString(@"颜色", nil);
    
    
    return _canvasColorView;
}

#pragma mark - 背景 画布样式
-(UIView *)canvasStyleView
{
    if( !_canvasStyleView )
    {
        _canvasStyleView = [[UIView alloc] initWithFrame:CGRectMake(0, _canvasScrollView.frame.size.height, _canvasView.frame.size.width, _canvasViewHeight*0.731)];
        _canvasStyleView.backgroundColor = TOOLBAR_COLOR;
        [_canvasView addSubview:_canvasStyleView];
        _canvasStyleView.hidden = YES;
        //场景样式
        float height =  _canvasViewHeight*0.360;
        _canvasStyleScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, ( _canvasStyleView.frame.size.height - height )/2.0 , _canvasStyleView.frame.size.width, height)];
        _canvasStyleScrollView.backgroundColor = [UIColor clearColor];
        _canvasStyleScrollView.tag = 2000;
        [_canvasStyleView addSubview: _canvasStyleScrollView];
        [self refreshCanvasStyle];
        
    }
    
    return _canvasStyleView;
}

-(void)refreshCanvasStyle
{
    for (UIView *subView in _canvasStyleScrollView.subviews)
    {
        [subView removeFromSuperview];
    }
//    @3x 0
    float height = _canvasStyleScrollView.frame.size.height+8;
    [_canvasStyleScrollView addSubview:[self canvasStyleTypeBtn:0]];
    [_canvasStyleScrollView addSubview:[self canvasStyleTypeBtn:1]];
    if( _canvaStyle_PhotoImage )
       [_canvasStyleScrollView addSubview:[self canvasStyleTypeBtn:2]];
    for (int i = 0; i < 20; i++) {
        int index = i + 3;
        [_canvasStyleScrollView addSubview:[self canvasStyleTypeBtn:index]];
    }
    
    if( _canvaStyle_PhotoImage )
        _canvasStyleScrollView.contentSize = CGSizeMake(2+height*23, 0);
    else
        _canvasStyleScrollView.contentSize = CGSizeMake(2+height*22, 0);
}

-(UIButton *)canvasStyleTypeBtn:(int) tag
{
    int index = tag;
    if( (tag>2) && !_canvaStyle_PhotoImage )
    {
        index--;
    }
    
    float height = _canvasStyleScrollView.frame.size.height;
    UIButton * canvasStyleTypeBtn = [[UIButton alloc] initWithFrame:CGRectMake(index*(height+8) + 2, 0, height, height)];
    canvasStyleTypeBtn.backgroundColor = [UIColor clearColor];
    canvasStyleTypeBtn.layer.cornerRadius = 5.0;
    canvasStyleTypeBtn.layer.masksToBounds = YES;
    canvasStyleTypeBtn.layer.borderColor = [UIColor clearColor].CGColor;
    canvasStyleTypeBtn.layer.borderWidth = 1.0;
    canvasStyleTypeBtn.tag = tag;
    
    switch (tag) {
        case 0:
            {
                canvasStyleimageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, height, height)];
                canvasStyleimageView.backgroundColor = UIColorFromRGB(0x27262c);
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, canvasStyleTypeBtn.frame.size.width, canvasStyleTypeBtn.frame.size.height)];
                label.text = RDLocalizedString(@"无", nil);
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor whiteColor];
                [UIColor colorWithWhite:1.0 alpha:0.5];
                [canvasStyleimageView addSubview:label];
                [canvasStyleTypeBtn addSubview:canvasStyleimageView];
            }
            break;
        case 1:
            [canvasStyleTypeBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_添加图片默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
            break;
        case 2:
        {
            UIImage  * image =  [RDHelpClass getThumbImageWithUrl:_canvaStyle_PhotoImage.contentURL];
            
            CGRect cropRect = CGRectMake(0, 0, 1, 1);
            
            if( image.size.width > image.size.height )
            {
                cropRect = CGRectMake( (1 - (image.size.height/image.size.width) )/2.0 , 0, (image.size.height/image.size.width), 1);
            }
            else{
                cropRect = CGRectMake( 0, (1 - (image.size.width/image.size.height) )/2.0, 1.0, (image.size.width/image.size.height));
            }
            image = [RDHelpClass image:image rotation:0 cropRect:cropRect];
            
            [canvasStyleTypeBtn setImage:image  forState:UIControlStateNormal];
        }
            break;
        default:
            [canvasStyleTypeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/background/canvasStyle/bg_style_%d",tag - 2]  Type:@"png"]] forState:UIControlStateNormal];
            break;
    }
    
    if( _canvasStyle_CurrentTag == tag )
    {
        canvasStyleTypeBtn.layer.borderColor = Main_Color.CGColor;
        canvasStyleTypeBtn.selected = true;
    }
    
    [canvasStyleTypeBtn addTarget:self action:@selector(canvasStyleTypeBtnOnClik:) forControlEvents:UIControlEventTouchUpInside];
    
    return canvasStyleTypeBtn;
}

-(void)canvasStyleTypeBtnOnClik:(UIButton *) sender
{
    if( _canvasStyle_CurrentTag == sender.tag )
        return;
    
    UIButton * btn = [_canvasStyleScrollView viewWithTag:_canvasStyle_CurrentTag];
    btn.layer.borderColor = [UIColor blackColor].CGColor;
    _canvasStyle_CurrentTag = 0;
    
    [self initCanvasStyle:sender];
}

-(void)initCanvasStyle:(UIButton *) sender
{
    switch (sender.tag) {
        case 0://无背景图片
        {
            _canvasStyle_CurrentTag = sender.tag;
            sender.layer.borderColor = Main_Color.CGColor;
            
            RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            scene.backgroundAsset = nil;
            scene.backgroundColor = UIColorFromRGB(0x000000);
            
            _currentCanvasStyleFile = nil;
            
            [_videoCoreSDK refreshCurrentFrame];
        }
            break;
        case 1://添加照片
        {
            RDMainViewController *mainVC = [[RDMainViewController alloc] init];
            mainVC.showPhotos = YES;
            mainVC.textPhotoProportion = _exportVideoSize.width/(float)_exportVideoSize.height;
            mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
                if( (filelist != nil) &&  filelist.count > 0 )
                {
                    if( _canvaStyle_PhotoImage )
                        _canvaStyle_PhotoImage = nil;
                    
                    CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:_canvas_CurrentFileIndex];
                    _canvaStyle_PhotoImage = filelist[0];
                    _canvaStyle_PhotoImage.imageTimeRange = CMTimeRangeMake(kCMTimeZero,timeRange.duration);
                    [self canvasFileCrop:_canvaStyle_PhotoImage atfileCropModeType:selectProportionIndex atEditSize:proportionVideoSize];
                    
                    [self refreshCanvasStyle];
                    UIButton * btn = [_canvasStyleScrollView viewWithTag:2];
                    [self canvasStyleTypeBtnOnClik:btn];
                }
            };
            RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
            [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
            nav.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
            nav.editConfiguration.mediaCountLimit = 1;
            nav.navigationBarHidden = YES;
            [self presentViewController:nav animated:YES completion:nil];
        }
            break;
        case 2://选择 照片为对应的背景图
        {
            _canvasStyle_CurrentTag = sender.tag;
            sender.layer.borderColor = Main_Color.CGColor;
            
            
            CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:_canvas_CurrentFileIndex];
            _canvaStyle_PhotoImage.imageTimeRange = CMTimeRangeMake(kCMTimeZero,timeRange.duration);
            
            RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            scene.backgroundColor = UIColorFromRGB(0x000000);
            scene.backgroundAsset = [RDHelpClass canvasFile:_canvaStyle_PhotoImage];
            _currentCanvasStyleFile = _canvaStyle_PhotoImage;
            [_videoCoreSDK refreshCurrentFrame];
        }
            break;
        default://选择 app自带的图片作为背景 图
        {
            _canvasStyle_CurrentTag = sender.tag;
            sender.layer.borderColor = Main_Color.CGColor;
            
            RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            
            NSString * strpatch = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/background/canvasStyle/bg_style_%d",sender.tag - 2]  Type:@"png"];
            
            CMTimeRange timeRange = [_videoCoreSDK passThroughTimeRangeAtIndex:_canvas_CurrentFileIndex];
            
            _currentCanvasStyleFile = [RDHelpClass canvas_BackgroundPicture:strpatch];
            
            _currentCanvasStyleFile.imageTimeRange = CMTimeRangeMake(kCMTimeZero,timeRange.duration);
            
            NSLog(@"场景背景时长%d：%.2f s",_canvas_CurrentFileIndex,CMTimeGetSeconds(_currentCanvasStyleFile.imageTimeRange.duration));
            
            [self canvasFileCrop:_currentCanvasStyleFile  atfileCropModeType:selectProportionIndex atEditSize:proportionVideoSize];
            
            scene.backgroundColor = UIColorFromRGB(0x000000);
            scene.backgroundAsset = [RDHelpClass canvasFile:_currentCanvasStyleFile];
            
            [_videoCoreSDK refreshCurrentFrame];
        }
            break;
    }
}

#pragma mark - 背景 画布模糊
-(UIView *)canvasBlurryView
{
    if( !_canvasBlurryView )
    {
        _canvasBlurryView = [[UIView alloc] initWithFrame:CGRectMake(0, _canvasScrollView.frame.size.height, _canvasView.frame.size.width, _canvasViewHeight*0.731)];
        _canvasBlurryView.backgroundColor = TOOLBAR_COLOR;
        [_canvasView addSubview:_canvasBlurryView];
        _canvasBlurryView.hidden = YES;
        //场景模糊
        _canvasBlurrySlider = [[RDZSlider alloc] init];
        _canvasBlurrySlider.backgroundColor = [UIColor clearColor];
        [_canvasBlurrySlider setMaximumValue:1];
        [_canvasBlurrySlider setMinimumValue:0];
        _canvasBlurrySlider.layer.cornerRadius = 2.0;
        _canvasBlurrySlider.layer.masksToBounds = YES;
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_canvasBlurrySlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_canvasBlurrySlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_canvasBlurrySlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        [_canvasBlurrySlider addTarget:self action:@selector(canvasBlurryBeginScrub:) forControlEvents:UIControlEventTouchDown];
        [_canvasBlurrySlider addTarget:self action:@selector(canvasBlurryScrub:) forControlEvents:UIControlEventValueChanged];
        [_canvasBlurrySlider addTarget:self action:@selector(canvasBlurryEndScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_canvasBlurrySlider addTarget:self action:@selector(canvasBlurryEndScrub:) forControlEvents:UIControlEventTouchCancel];
        _canvasBlurrySlider.frame = CGRectMake(50, (_canvasBlurryView.frame.size.height - 30)/2.0, _canvasBlurryView.frame.size.width - 100, 30);
        [_canvasBlurryView addSubview:_canvasBlurrySlider];
    }
    return _canvasBlurryView;
}
- (void)canvasBlurryBeginScrub:(RDZSlider *)slider {
    
//    RDScene * scene = scenes[_canvas_CurrentFileIndex];
//    scene.backgroundAsset.blurIntensity = slider.value;
//    [_videoCoreSDK refreshCurrentFrame];
    
}
- (void)canvasBlurryScrub:(RDZSlider *)slider {
    
//    RDScene * scene = scenes[_canvas_CurrentFileIndex];
//    scene.backgroundAsset.blurIntensity = slider.value;
//    [_videoCoreSDK refreshCurrentFrame];
    
}
- (void)canvasBlurryEndScrub:(RDZSlider *)slider {
    RDScene * scene = [_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
    scene.backgroundAsset.blurIntensity = slider.value;
    [_videoCoreSDK refreshCurrentFrame];
}

//删除背景 画布
-(void)deleteCanvasView
{
    if( _canvasView )
    {
        //画布颜色
        if( _canvasColorView )
        {
            [_canvasScrollView removeFromSuperview];
            _canvasScrollView = nil;
            
            [_useToAllCanvas removeFromSuperview];
            _useToAllCanvas = nil;
            
            [_canvasColorControl removeFromSuperview];
            _canvasColorControl= nil;
            
            [_canvasColorView removeFromSuperview];
            _canvasColorView = nil;
        }
        //画布样式
        if( _canvasStyleView )
        {
            [_canvasStyleScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if( [obj isKindOfClass:[UIButton class]] )
                {
                    [obj removeFromSuperview];
                    obj = nil;
                }
            }];
            [_canvasStyleScrollView removeFromSuperview];
            _canvasStyleScrollView = nil;
            
            
            [_canvasStyleView removeFromSuperview];
            _canvasStyleView = nil;
        }
        //画布模糊
        if( _canvasBlurryView )
        {
            [_canvasBlurrySlider removeFromSuperview];
            _canvasBlurrySlider = nil;
            
            [_canvasBlurryView removeFromSuperview];
            _canvasBlurryView = nil;
        }
        
        if( _toobarCanvasView )
        {
            [_toobarCanvasLabel removeFromSuperview];
            _toobarCanvasLabel = nil;
            
            [_toobarCanvasView removeFromSuperview];
            _toobarCanvasView = nil;
        }
        
        [_canvasView removeFromSuperview];
        _canvasView = nil;
    }
    
    if( self.canvas_syncContainer )
    {
        if( _canvas_syncContainer_X_Left )
        {
            [_canvas_syncContainer_X_Left removeFromSuperview];
            _canvas_syncContainer_X_Left = nil;
            [_canvas_syncContainer_X_Right removeFromSuperview];
            _canvas_syncContainer_X_Right = nil;
            [_canvas_syncContainer_Y_Left removeFromSuperview];
            _canvas_syncContainer_Y_Left = nil;
            [_canvas_syncContainer_Y_Right removeFromSuperview];
            _canvas_syncContainer_Y_Right = nil;
        }
        [self.canvas_syncContainer removeFromSuperview];
        self.canvas_syncContainer = nil;
        if( self.canvas_pasterView )
        {
            [self.canvas_pasterView removeFromSuperview];
            self.canvas_pasterView = nil;
        }
    }
}

#pragma mark- 场景背景 添加
////背景 画布 中线显示
//-(void)pasterMidline:(RDPasterTextView * _Nullable) canvas_PasterText isHidden:(bool) ishidden
//{
//    float interval = 20;
//
//    float width = 30;
//    float height = 3;
//
//    if( !ishidden && self.canvas_syncContainer )
//    {
//        float x = self.canvas_syncContainer.frame.size.width/2.0;
//        float y = self.canvas_syncContainer.frame.size.height/2.0;
//
//        CGPoint center = canvas_PasterText.center;
//
//        if( ( center.x >= ( x - interval ) ) && ( center.x <= ( x + interval ) )  )
//        {
//
//            if( !_canvas_syncContainer_X_Left )
//            {
//                _canvas_syncContainer_X_Left = [[UIImageView alloc] initWithFrame:CGRectMake((self.canvas_syncContainer.frame.size.width - height)/2.0, 0, height, width)];
//                _canvas_syncContainer_X_Left.backgroundColor = UIColorFromRGB(0xffffff);
//                _canvas_syncContainer_X_Left.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
//                _canvas_syncContainer_X_Left.layer.borderWidth = 0.5;
//                [self.canvas_syncContainer addSubview:_canvas_syncContainer_X_Left];
//
//                _canvas_syncContainer_X_Right = [[UIImageView alloc] initWithFrame:CGRectMake((self.canvas_syncContainer.frame.size.width - height)/2.0, self.canvas_syncContainer.frame.size.height - width, height, width)];
//                _canvas_syncContainer_X_Right.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
//                _canvas_syncContainer_X_Right.layer.borderWidth = 0.5;
//                _canvas_syncContainer_X_Right.backgroundColor = UIColorFromRGB(0xffffff);
//                [self.canvas_syncContainer addSubview:_canvas_syncContainer_X_Right];
//            }
//
//            _canvas_syncContainer_X_Right.hidden = NO;
//            _canvas_syncContainer_X_Left.hidden = NO;
//        }
//        else
//        {
//            _canvas_syncContainer_X_Right.hidden = YES;
//            _canvas_syncContainer_X_Left.hidden = YES;
//        }
//
//        if( ( center.y >= ( y - interval ) ) && ( center.y <= ( y + interval ) )  )
//        {
//            if( !_canvas_syncContainer_Y_Left )
//            {
//                _canvas_syncContainer_Y_Left = [[UIImageView alloc] initWithFrame:CGRectMake(0, (self.canvas_syncContainer.frame.size.height - height)/2.0, width, height)];
//                _canvas_syncContainer_Y_Left.backgroundColor = UIColorFromRGB(0xffffff);
//                _canvas_syncContainer_Y_Left.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
//                _canvas_syncContainer_Y_Left.layer.borderWidth = 0.5;
//                [self.canvas_syncContainer addSubview:_canvas_syncContainer_Y_Left];
//
//                _canvas_syncContainer_Y_Right = [[UIImageView alloc] initWithFrame:CGRectMake( self.canvas_syncContainer.frame.size.width - width,  (self.canvas_syncContainer.frame.size.height - height)/2.0, width, height)];
//                _canvas_syncContainer_Y_Right.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
//                _canvas_syncContainer_Y_Right.layer.borderWidth = 0.5;
//                _canvas_syncContainer_Y_Right.backgroundColor = UIColorFromRGB(0xffffff);
//                [self.canvas_syncContainer addSubview:_canvas_syncContainer_Y_Right];
//            }
//
//            _canvas_syncContainer_Y_Right.hidden = NO;
//            _canvas_syncContainer_Y_Left.hidden = NO;
//        }
//        else{
//            _canvas_syncContainer_Y_Right.hidden = YES;
//            _canvas_syncContainer_Y_Left.hidden = YES;
//        }
//    }
//    else{
//        if( _canvas_syncContainer_Y_Right )
//        {
//            _canvas_syncContainer_Y_Right.hidden = YES;
//            _canvas_syncContainer_Y_Left.hidden = YES;
//        }
//        if( _canvas_syncContainer_X_Right )
//        {
//            _canvas_syncContainer_X_Right.hidden = YES;
//            _canvas_syncContainer_X_Left.hidden = YES;
//        }
//    }
//}

#pragma mark- 场景背景 恢复
-( void )canvas_restore
{
    if( _CurrentCanvasType == 0 )
        _CurrentCanvasType = 1;
    
    if( _CurrentCanvasType == 1 )
    {
        self.canvasColorView.hidden = YES;
        [_canvasColorControl setValue:_fileList[_canvas_CurrentFileIndex].backgroundColor];
    }
    else if( _CurrentCanvasType == 2 )
    {
        _canvasStyle_CurrentTag = _fileList[_canvas_CurrentFileIndex].backgroundStyle;
        if( _canvasStyle_CurrentTag == 2 )
        {
            _canvaStyle_PhotoImage = _fileList[_canvas_CurrentFileIndex].BackgroundFile;
        }
        else if( _canvasStyle_CurrentTag != 0 ){
            _currentCanvasStyleFile = _fileList[_canvas_CurrentFileIndex].BackgroundFile;
        }
    }
    else
    {
        _canvasBlurryFile = _fileList[_canvas_CurrentFileIndex].BackgroundFile;
        _canvasBlurryValue = _fileList[_canvas_CurrentFileIndex].BackgroundFile.BackgroundBlurIntensity;
    }
    
    UIButton * btn = [_canvasScrollView viewWithTag:_CurrentCanvasType];
    
    [self canvasTypeBtnOnClik:btn];
}

#pragma mark-场景背景适配比例 计算裁剪比例
-(void)canvasFileCrop:(RDFile *) file atfileCropModeType:(FileCropModeType) ProportionIndex atEditSize:(CGSize) editSize
{
    [RDHelpClass fileCrop:file atfileCropModeType:ProportionIndex atEditSize:editSize];
}


#pragma mark- 加水印
-(UIView *)watermarkView;
{
    if( !_watermarkView )
    {
        _watermarkView = [[UIView alloc] initWithFrame:CGRectMake(bottomViewRect.origin.x, bottomViewRect.origin.y, bottomViewRect.size.width, bottomViewRect.size.height + _toolBarView.bounds.size.height )];
        _watermarkView.backgroundColor = TOOLBAR_COLOR;
        _watermarkViewHeight = bottomViewRect.size.height;
        
        [self.view addSubview:_watermarkView];
        
        _watermarkScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _watermarkView.frame.size.width,_watermarkViewHeight *0.269)];
        _watermarkScrollView.backgroundColor = TOOLBAR_COLOR;
        _watermarkScrollView.showsVerticalScrollIndicator = NO;
        _watermarkScrollView.showsHorizontalScrollIndicator = NO;
        _watermarkScrollView.tag = 10000;
        [_watermarkView addSubview:_watermarkScrollView];
        
        float x = 0;
        
        x = [self canvas_Btn:RDLocalizedString(@"替换", nil) atIndx:0 atX:x atBtn: [[UIButton alloc] init] ];
        x = [self canvas_Btn:RDLocalizedString(@"基础", nil) atIndx:1 atX:x atBtn: [[UIButton alloc] init]];
        x = [self canvas_Btn:RDLocalizedString(@"位置", nil) atIndx:2 atX:x atBtn: [[UIButton alloc] init]];
        
        [_watermarkView addSubview:self.toobarWatermarkView];
        
        
        if( _watermarkCollage )
            [self WatermarkTypeBtnOnClik: [_watermarkScrollView viewWithTag:1] ];
    }
    return _watermarkView;
}

-(void)WatermarkTypeBtnOnClik:( UIButton * ) sender
{
    if( sender.tag == 0 )
    {
        [self watermark_replace:NO];
        return;
    }
    
    UIFont *font = [UIFont systemFontOfSize:14];
    
    if( _CurrentWatermarkType > 0 )
    {
        ((UIButton*)[_watermarkScrollView viewWithTag:_CurrentWatermarkType]).selected = false;
        ((UIButton*)[_watermarkScrollView viewWithTag:_CurrentWatermarkType]).font = font;
    }
    _CurrentWatermarkType = sender.tag;
    
    font = [UIFont boldSystemFontOfSize:14];
    
    sender.selected = true;
    sender.font = font;
    
    switch (sender.tag) {
        case 1://基础
        {
            self.watermarkBasisView.hidden = NO;
            self.watermarkPosiView.hidden = YES;
        }
            break;
        case 2://位置
        {
            self.watermarkPosiView.hidden = NO;
            self.watermarkBasisView.hidden = YES;
        }
            break;
        default:
            break;
    }
}

#pragma mark - 加水印 状态栏
-(UIView *)toobarWatermarkView
{
    if( !_toobarWatermarkView )
    {
        _toobarWatermarkView = [[UIView alloc] initWithFrame:CGRectMake(0, _watermarkViewHeight, _watermarkView.frame.size.width, _toolBarView.bounds.size.height)];
        
        UIButton * toobarWatermarkCancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [toobarWatermarkCancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [toobarWatermarkCancelBtn addTarget:self action:@selector(toobarWatermark_back) forControlEvents:UIControlEventTouchUpInside];
        [_toobarWatermarkView addSubview:toobarWatermarkCancelBtn];
        
         UIButton * toobarWatermarkFinishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [toobarWatermarkFinishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [toobarWatermarkFinishBtn addTarget:self action:@selector(toobarWatermark_Finish) forControlEvents:UIControlEventTouchUpInside];
        [_toobarWatermarkView addSubview:toobarWatermarkFinishBtn];
        
        _toobarWatermarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, _toobarWatermarkView.frame.size.width - 88, 44)];
        _toobarWatermarkLabel.textAlignment = NSTextAlignmentCenter;
        _toobarWatermarkLabel.font = [UIFont boldSystemFontOfSize:17];
        _toobarWatermarkLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _toobarWatermarkLabel.text = RDLocalizedString(@"加水印", nil);
        [_toobarWatermarkView addSubview:_toobarWatermarkLabel];
//        _toobarWatermarkView.hidden = YES;
    }
    return _toobarWatermarkView;
}

-(void)toobarWatermark_back
{
    _watermarkView.hidden = YES;
    _playButton.hidden = NO;
    [self ReturnAdjustment:YES];
    
    if( self.watermark_syncContainer )
    {
        if( self.watermark_pasterView )
        {
            [self.watermark_pasterView removeFromSuperview];
            self.watermark_pasterView = nil;
        }
        [self.watermark_syncContainer removeFromSuperview];
        self.watermark_syncContainer = nil;
    }
}

-(void)toobarWatermark_Finish
{
    _watermarkView.hidden = YES;
    _playButton.hidden = NO;
    [self ReturnAdjustment:YES];
    
    RDWatermark *collage = _currentWatermarkCollage;
    CGPoint point = CGPointMake(self.watermark_pasterView.center.x/self.watermark_syncContainer.frame.size.width, self.watermark_pasterView.center.y/self.watermark_syncContainer.frame.size.height);
    float scale = [self.watermark_pasterView getFramescale];
    CGRect rect;
    rect.size = CGSizeMake(self.watermark_pasterView.contentImage.frame.size.width*scale / self.watermark_syncContainer.bounds.size.width, self.watermark_pasterView.contentImage.frame.size.height*scale / self.watermark_syncContainer.bounds.size.height);
    rect.origin = CGPointMake(point.x - rect.size.width/2.0, point.y - rect.size.height/2.0);
    collage.vvAsset.rectInVideo = rect;
    
    CGFloat radius = atan2f(self.watermark_pasterView.transform.b, self.watermark_pasterView.transform.a);
    double rotate = - radius * (180 / M_PI);
    collage.vvAsset.rotate = rotate;
    
    if( !_watermarkCollage )
    {
        _watermarkCollage = [[RDCaptionRangeViewFile alloc] init];
    }
    
    
    CGFloat pradius = atan2f(self.watermark_pasterView.transform.b, self.watermark_pasterView.transform.a);
    float rotationAngle = - pradius * (180 / M_PI);
    if(scale !=0){
        _watermarkCollage.scale = scale;
    }
    _watermarkCollage.centerPoint = CGPointMake(self.watermark_pasterView.center.x/self.playerView.frame.size.width, self.watermark_pasterView.center.y/self.playerView.frame.size.height);
    float scaleValue = kVIDEOWIDTH/self.playerView.bounds.size.width;
    CGRect saveRect = CGRectMake(0, 0, self.watermark_pasterView.contentImage.frame.size.width * scaleValue / kVIDEOWIDTH, self.watermark_pasterView.contentImage.frame.size.height * scaleValue / kVIDEOWIDTH);
    _watermarkCollage.caption.stretchRect = self.watermark_pasterView.contentImage.layer.contentsCenter;
    _watermarkCollage.caption.size = saveRect.size;
    _watermarkCollage.home = saveRect;
    _watermarkCollage.rotationAngle = rotationAngle;
    _watermarkCollage.pSize =  self.watermark_pasterView.frame.size;
    _watermarkCollage.collage = _currentWatermarkCollage;
    _watermarkCollage.captionTransform =  self.watermark_pasterView.transform;
    _watermarkCollage.thumbnailImage = self.watermark_pasterView.contentImage.image;
    
    if (CGAffineTransformEqualToTransform(self.watermark_pasterView.contentImage.transform, kLRFlipTransform)) {
        _watermarkCollage.collage.vvAsset.isHorizontalMirror = YES;
        _watermarkCollage.collage.vvAsset.isVerticalMirror = NO;
    }else if (CGAffineTransformEqualToTransform(self.watermark_pasterView.contentImage.transform, kUDFlipTransform)) {
        _watermarkCollage.collage.vvAsset.isHorizontalMirror = NO;
        _watermarkCollage.collage.vvAsset.isVerticalMirror = YES;
    }else if (CGAffineTransformEqualToTransform(self.watermark_pasterView.contentImage.transform, kLRUPFlipTransform)) {
        _watermarkCollage.collage.vvAsset.isHorizontalMirror = YES;
        _watermarkCollage.collage.vvAsset.isVerticalMirror = YES;
    }else {
        _watermarkCollage.collage.vvAsset.isHorizontalMirror = NO;
        _watermarkCollage.collage.vvAsset.isVerticalMirror = NO;
    }
    
    _watermarkCollage.collage.vvAsset.alpha = _watermarkAlhpaSlider.value;
    
    _watermarkCollage.captionTransform = self.watermark_pasterView.transform;
    
    seekTime = _videoCoreSDK.currentTime;
    
    [self initPlayer];
    
    if( self.watermark_syncContainer )
    {
        if( self.watermark_pasterView )
        {
            [self.watermark_pasterView removeFromSuperview];
            self.watermark_pasterView = nil;
        }
        [self.watermark_syncContainer removeFromSuperview];
        self.watermark_syncContainer = nil;
    }
}




#pragma mark-加水印 基础
-(UIView *)watermarkBasisView
{
    if( !_watermarkBasisView )
    {
        _watermarkBasisView = [[UIView alloc] initWithFrame:CGRectMake(0, _watermarkScrollView.frame.origin.y + _watermarkScrollView.frame.size.height, _watermarkView.frame.size.width, _watermarkViewHeight - _watermarkScrollView.frame.size.height)];
        _watermarkBasisView.backgroundColor = [UIColor clearColor];
        
        //大小
        [_watermarkBasisView addSubview:self.watermarkSizeSlider];
        //角度
        [_watermarkBasisView addSubview:self.watermarkRotateSlider];
        //透明度
        [_watermarkBasisView addSubview:self.watermarkAlhpaSlider];
        
        
        [_watermarkView addSubview:_watermarkBasisView];
    }
    return _watermarkBasisView;
}

//水印大小
- (RDZSlider *)watermarkSizeSlider{
    if(!_watermarkSizeSlider){
        
        UILabel * watermarkLabel = [UILabel new];
        watermarkLabel.frame = CGRectMake(( 120 - 50  )/2.0, (_watermarkBasisView.frame.size.height/3 - 31)/2.0, 50, 31);
        watermarkLabel.textAlignment = NSTextAlignmentLeft;
        watermarkLabel.backgroundColor = [UIColor clearColor];
        watermarkLabel.font = [UIFont systemFontOfSize:12];
        watermarkLabel.textColor = [UIColor whiteColor];
        watermarkLabel.text = RDLocalizedString(@"大小", nil);
        
        [_watermarkBasisView addSubview:watermarkLabel];
        
        _watermarkSizeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50 + ( 120 - 50  )/2.0, (_watermarkBasisView.frame.size.height/3 - 31)/2.0, kWIDTH - 120, 31)];
        _watermarkSizeSlider.alpha = 1.0;
        _watermarkSizeSlider.backgroundColor = [UIColor clearColor];
        [_watermarkSizeSlider setMaximumValue:1];
        [_watermarkSizeSlider setMinimumValue:0];
        [_watermarkSizeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_watermarkSizeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_watermarkSizeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        
        [_watermarkSizeSlider setValue:(3.0 - 1.0)/(_maxScale-1.0)];
        
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_watermarkSizeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_watermarkSizeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_watermarkSizeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        
//        [_watermarkSizeSlider setValue:0];
        [_watermarkSizeSlider addTarget:self action:@selector(watermark_beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_watermarkSizeSlider addTarget:self action:@selector(watermark_scrub:) forControlEvents:UIControlEventValueChanged];
        [_watermarkSizeSlider addTarget:self action:@selector(watermark_endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_watermarkSizeSlider addTarget:self action:@selector(watermark_endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _watermarkSizeSlider;
}
//水印旋转角度
- (RDZSlider *)watermarkRotateSlider{
    if(!_watermarkRotateSlider){
       
        UILabel * watermarkLabel = [UILabel new];
        watermarkLabel.frame = CGRectMake(( 120 - 50  )/2.0, (_watermarkBasisView.frame.size.height/3 - 31)/2.0 + _watermarkBasisView.frame.size.height/3, 50, 31);
        watermarkLabel.textAlignment = NSTextAlignmentLeft;
        watermarkLabel.backgroundColor = [UIColor clearColor];
        watermarkLabel.font = [UIFont systemFontOfSize:12];
        watermarkLabel.textColor = [UIColor whiteColor];
        watermarkLabel.text = RDLocalizedString(@"旋转角度", nil);
        
        [_watermarkBasisView addSubview:watermarkLabel];
        
        _watermarkRotateSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50 + ( 120 - 50  )/2.0, (_watermarkBasisView.frame.size.height/3 - 31)/2.0 + _watermarkBasisView.frame.size.height/3, kWIDTH - 120, 31)];
        _watermarkRotateSlider.alpha = 1.0;
        _watermarkRotateSlider.backgroundColor = [UIColor clearColor];
        [_watermarkRotateSlider setMaximumValue:360];
        [_watermarkRotateSlider setMinimumValue:0];
        [_watermarkRotateSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_watermarkRotateSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_watermarkRotateSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_watermarkRotateSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_watermarkRotateSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_watermarkRotateSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        
        [_watermarkRotateSlider setValue:0];
        [_watermarkRotateSlider addTarget:self action:@selector(watermark_beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_watermarkRotateSlider addTarget:self action:@selector(watermark_scrub:) forControlEvents:UIControlEventValueChanged];
        [_watermarkRotateSlider addTarget:self action:@selector(watermark_endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_watermarkRotateSlider addTarget:self action:@selector(watermark_endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _watermarkRotateSlider;
}
//水印透明度
- (RDZSlider *)watermarkAlhpaSlider{
    if(!_watermarkAlhpaSlider){
       
        UILabel * watermarkLabel = [UILabel new];
        watermarkLabel.frame = CGRectMake(( 120 - 50  )/2.0, (_watermarkBasisView.frame.size.height/3 - 31)/2.0 + _watermarkBasisView.frame.size.height*2.0/3, 50, 31);
        watermarkLabel.textAlignment = NSTextAlignmentLeft;
        watermarkLabel.backgroundColor = [UIColor clearColor];
        watermarkLabel.font = [UIFont systemFontOfSize:12];
        watermarkLabel.textColor = [UIColor whiteColor];
        watermarkLabel.text = RDLocalizedString(@"透明度", nil);
        
        [_watermarkBasisView addSubview:watermarkLabel];
        
        _watermarkAlhpaSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50 + ( 120 - 50  )/2.0, (_watermarkBasisView.frame.size.height/3 - 31)/2.0 + _watermarkBasisView.frame.size.height*2.0/3, kWIDTH - 120, 31)];
        _watermarkAlhpaSlider.alpha = 1.0;
        _watermarkAlhpaSlider.backgroundColor = [UIColor clearColor];
        [_watermarkAlhpaSlider setMaximumValue:1];
        [_watermarkAlhpaSlider setMinimumValue:0];
        [_watermarkAlhpaSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_watermarkAlhpaSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_watermarkAlhpaSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_watermarkAlhpaSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_watermarkAlhpaSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_watermarkAlhpaSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"]  forState:UIControlStateNormal];
        
        
        [_watermarkAlhpaSlider setValue:1.0];
        [_watermarkAlhpaSlider addTarget:self action:@selector(watermark_beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_watermarkAlhpaSlider addTarget:self action:@selector(watermark_scrub:) forControlEvents:UIControlEventValueChanged];
        [_watermarkAlhpaSlider addTarget:self action:@selector(watermark_endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_watermarkAlhpaSlider addTarget:self action:@selector(watermark_endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _watermarkAlhpaSlider;
}

- (void)watermark_beginScrub:(RDZSlider *)slider{
    if( slider == _watermarkSizeSlider )
    {
        float scale = (_maxScale - 1.0)*_watermarkSizeSlider.value +  1.0;
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(atan2f(self.watermark_pasterView.transform.b, self.watermark_pasterView.transform.a)), scale, scale);
    }
    else if( slider == _watermarkRotateSlider )
    {
        float rotate = 0;
        if( _watermarkRotateSlider.value > 180 )
        {
            rotate = 360 - _watermarkRotateSlider.value;
        }
        else
        {
            rotate = -_watermarkRotateSlider.value;
        }
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(rotate/(180 / M_PI)), [self.watermark_pasterView selfscale], [self.watermark_pasterView selfscale]);
    }
    else if( slider == _watermarkAlhpaSlider )
    {
        self.watermark_pasterView.contentImage.alpha = _watermarkAlhpaSlider.value;
    }
}
- (void)watermark_scrub:(RDZSlider *)slider{
    if( slider == _watermarkSizeSlider )
    {
        float scale = (_maxScale - 1.0)*_watermarkSizeSlider.value +  1.0;
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(atan2f(self.watermark_pasterView.transform.b, self.watermark_pasterView.transform.a)), scale, scale);
        [self.watermark_pasterView setFramescale: scale];
    }
    else if( slider == _watermarkRotateSlider )
    {
        float rotate = 0;
        if( _watermarkRotateSlider.value > 180 )
        {
            rotate = 360 - _watermarkRotateSlider.value;
        }
        else
        {
            rotate = -_watermarkRotateSlider.value;
        }
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(rotate/(180 / M_PI)), [self.watermark_pasterView selfscale], [self.watermark_pasterView selfscale]);
    }
    else if( slider == _watermarkAlhpaSlider )
    {
        self.watermark_pasterView.contentImage.alpha = _watermarkAlhpaSlider.value;
    }
}
- (void)watermark_endScrub:(RDZSlider *)slider{
    
    if( slider == _watermarkSizeSlider )
    {
        float scale = (_maxScale - 1.0)*_watermarkSizeSlider.value +  1.0;
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(atan2f(self.watermark_pasterView.transform.b, self.watermark_pasterView.transform.a)), scale, scale);
        [self.watermark_pasterView setFramescale: scale];
    }
    else if( slider == _watermarkRotateSlider )
    {
        float rotate = 0;
        if( _watermarkRotateSlider.value > 180 )
        {
            rotate = 360 - _watermarkRotateSlider.value;
        }
        else
        {
            rotate = -_watermarkRotateSlider.value;
        }
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(rotate/(180 / M_PI)), [self.watermark_pasterView selfscale], [self.watermark_pasterView selfscale]);
    }
    else if( slider == _watermarkAlhpaSlider )
    {
        self.watermark_pasterView.contentImage.alpha = _watermarkAlhpaSlider.value;
    }
}
#pragma mark-加水印 位置
-(UIView *)watermarkPosiView
{
    if( !_watermarkPosiView )
    {
        _watermarkPosiView = [[UIView alloc] initWithFrame:CGRectMake(0, _watermarkScrollView.frame.origin.y + _watermarkScrollView.frame.size.height, _watermarkView.frame.size.width, _watermarkViewHeight - _watermarkScrollView.frame.size.height)];
        _watermarkPosiView.backgroundColor = [UIColor clearColor];
        
//        UILabel *alignmentLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, (_watermarkPosiView.frame.size.width - 40)/2.0, 48)];
//        alignmentLbl.text = RDLocalizedString(@"画布对齐", nil);
//        alignmentLbl.textColor = UIColorFromRGB(0x888888);
//        alignmentLbl.font = [UIFont systemFontOfSize:14.0];
//        [_watermarkPosiView addSubview:alignmentLbl];
        
        float spaceH = (_watermarkPosiView.frame.size.height - 20*3 - 20)/3.0;
        float spaceW = (_watermarkPosiView.frame.size.width/2.0 - 40*3 - 20)/2.0;
        for (int i = 0; i < 4; i++) {
            int cellIdx = i%2;
            int rowIdx = ceil(i/2);
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(spaceW + 20 + 50 * cellIdx - ((cellIdx == 0) ? 0 : 2), spaceH + 10 + 30 * (rowIdx%2) - (((rowIdx%2) == 0) ? 0 : 2), 50, 30)];
            bgView.backgroundColor = [UIColor clearColor];
            bgView.layer.borderColor = UIColorFromRGB(0x202020).CGColor;
            bgView.layer.borderWidth = 2.0;
            [_watermarkPosiView addSubview:bgView];
        }
        for (int i = 0; i < 9; i++) {
            int cellIdx = i%3;
            int rowIdx = ceil(i/3);
            UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
            item.frame = CGRectMake(spaceW + (10 + 40) * cellIdx, spaceH + (10 + 20) * (rowIdx%3), 40, 20);
            item.backgroundColor = UIColorFromRGB(0x333333);
            item.tag = i + 1;
            [item addTarget:self action:@selector(clickSubtitlePositionItem:) forControlEvents:UIControlEventTouchUpInside];
            [_watermarkPosiView addSubview:item];
        }
        float width = 33.0;
        float y = 0;
        float height = _watermarkPosiView.frame.size.height - y - 10;
        float x = _watermarkPosiView.frame.size.width/2.0 + (_watermarkPosiView.frame.size.width/2.0 - height)/2.0;
        
//        UILabel *moveLbl = [[UILabel alloc] initWithFrame:CGRectMake(x - 10, 0, (_watermarkPosiView.frame.size.width - 40)/2.0, 48)];
//        moveLbl.text = RDLocalizedString(@"轻移", nil);
//        moveLbl.textColor = UIColorFromRGB(0x888888);
//        moveLbl.font = [UIFont systemFontOfSize:14.0];
//        [_watermarkPosiView addSubview:moveLbl];
        
        for (int i = 0; i < 4; i++) {
            UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            if (i == 0) {
                itemBtn.frame = CGRectMake(x, y + (height - width)/2.0, width, width);
            }else if (i == 1) {
                itemBtn.frame = CGRectMake(x + (x/2.0 - width)/2.0, y, width, width);
            }else if (i == 2) {
                itemBtn.frame = CGRectMake(x + (x/2.0 - width)/2.0, _watermarkPosiView.frame.size.height - 10 - width, width, width);
            }else {
                itemBtn.frame = CGRectMake(x + x/2.0 - width, y + (height - width)/2.0, width, width);
            }
            [itemBtn setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_位置_%02i_", i]] forState:UIControlStateNormal];
            itemBtn.tag = i + 1;
            [itemBtn addTarget:self action:@selector(moveSlightlyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_watermarkPosiView addSubview:itemBtn];
        }
        
        [_watermarkView addSubview:_watermarkPosiView];
    }
    return _watermarkPosiView;
}


#pragma mark- 替换 加水印
-(void)watermark_replace:( BOOL ) isHidden
{
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.showPhotos = YES;
    mainVC.textPhotoProportion = _exportVideoSize.width/(float)_exportVideoSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
       
        [self initPasterViewwithFIle:[RDHelpClass getFullScreenImageWithUrl:filelist[0].contentURL] ];
        
        _currentWatermarkCollage  = nil;
        
        _currentWatermarkCollage = [[RDWatermark alloc] init];
        _currentWatermarkCollage.vvAsset.url = filelist[0].contentURL;
        _currentWatermarkCollage.vvAsset.type = RDAssetTypeImage;
        _currentWatermarkCollage.vvAsset.fillType = RDImageFillTypeFit;
        _currentWatermarkCollage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE));
        _currentWatermarkCollage.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_videoCoreSDK.duration, TIMESCALE));
        
        if( !_watermarkView || (_watermarkView.hidden == YES) )
        {
            self.watermarkView.hidden = NO;
            [self WatermarkTypeBtnOnClik: [_watermarkScrollView viewWithTag:1] ];
        }
    };
    mainVC.cancelBlock = ^{
        if( isHidden )
        {
            _watermarkView.hidden = YES;
            _playButton.hidden = NO;
            [self ReturnAdjustment:YES];
        }
    };
    
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
    nav.editConfiguration.mediaCountLimit = 1;
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)initPasterViewwithFIle:(UIImage *) thumbImage
{
    if( !self.watermark_syncContainer )
    {
        self.watermark_syncContainer = [[syncContainerView alloc] init];
        [self.playerView addSubview:_watermark_syncContainer];
    }
    
    //视频分辨率
    CGSize presentationSize  = _exportVideoSize;
    CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(presentationSize, _playerView.bounds);
    
    self.watermark_syncContainer.frame = videoRect;
    self.watermark_syncContainer.layer.masksToBounds = YES;
    _playButton.hidden = YES;
    
//    [self.watermark_pasterView removeFromSuperview];
//    self.watermark_pasterView = nil;
    
    if (!self.watermark_pasterView) {
        CGSize size = thumbImage.size;
        float width;
        float height;
        if (self.watermark_syncContainer.bounds.size.width == self.watermark_syncContainer.bounds.size.height) {
            width = self.watermark_syncContainer.bounds.size.width/4.0/4.0;
            height = width / (size.width / size.height);
            _maxScale = 16.0;
        }else if (self.watermark_syncContainer.bounds.size.width < self.watermark_syncContainer.bounds.size.height) {
            width = self.watermark_syncContainer.bounds.size.width/2.0/4.0;
            height = width / (size.width / size.height);
            _maxScale = 8.0;
        }else {
            height = self.watermark_syncContainer.bounds.size.height / 2.0/4.0;
            width = height * (size.width / size.height);
            _maxScale = 8.0;
        }
        CGRect frame = CGRectMake( (self.watermark_syncContainer.bounds.size.width - width)/2.0, (self.watermark_syncContainer.bounds.size.height - height)/2.0, width, height);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        imageView.image = thumbImage;
        
        self.watermark_pasterView = [[RDPasterTextView alloc] initWithFrame:CGRectInset(frame, -8, -8)
                                                   superViewFrame:self.playerView.frame
                                                     contentImage:imageView
                                                syncContainerRect:self.playerView.bounds];
        
        self.watermark_pasterView.mirrorBtn.hidden = NO;
        self.watermark_pasterView.delegate = self;
        [self.watermark_syncContainer addSubview:self.watermark_pasterView];
        [self.watermark_pasterView setSyncContainer:self.watermark_syncContainer];
        
        
        self.watermark_pasterView.transform = CGAffineTransformScale(CGAffineTransformMakeRotation( 0/(180.0/M_PI) ), 3, 3);
        [self.watermark_pasterView setFramescale: 3];
        
        
        
        if (!_watermark_syncContainer.superview) {
            [_playerView addSubview:_watermark_syncContainer];
        }
    }else {
        self.watermark_pasterView.contentImage.image = thumbImage;
        
        CGSize size = thumbImage.size;
        float width;
        float height;
        if (self.watermark_syncContainer.bounds.size.width == self.watermark_syncContainer.bounds.size.height) {
            width = self.watermark_syncContainer.bounds.size.width/4.0/4.0;
            height = width / (size.width / size.height);
            _maxScale = 16.0;
        }else if (self.watermark_syncContainer.bounds.size.width <= self.watermark_syncContainer.bounds.size.height) {
            width = self.watermark_syncContainer.bounds.size.width/2.0/4.0;
            height = width / (size.width / size.height);
            _maxScale = 8.0;
        }else {
            height = self.watermark_syncContainer.bounds.size.height / 2.0/4.0;
            width = height * (size.width / size.height);
            _maxScale = 8.0;
        }
        CGRect frame = CGRectMake((self.watermark_syncContainer.bounds.size.width - width)/2.0, (self.watermark_syncContainer.bounds.size.height - height)/2.0, width, height);
        CGRect rect = CGRectInset(frame, -8, -8);
        self.watermark_pasterView.waterMaxScale = _maxScale;
        [self.watermark_pasterView refreshBounds:CGRectMake(0, 0, rect.size.width, rect.size.height)];
        return;
    }
    
    if( _watermarkCollage )
    {
        _watermarkCollage.collage.vvAsset.alpha = 0.0;
        [_videoCoreSDK refreshCurrentFrame];
        
        RDCaptionRangeViewFile * rangeView = _watermarkCollage;
        
        float ppsc = (rangeView.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.caption.size.width <1 ? (rangeView.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.caption.size.width : 1;
        float sc = rangeView.scale;
        
        CGAffineTransform transform2 = CGAffineTransformMakeRotation( -_watermarkCollage.rotationAngle/(180.0/M_PI) );
        self.watermark_pasterView.transform = CGAffineTransformScale(transform2, sc * ppsc, sc * ppsc);
        [self.watermark_pasterView setFramescale: sc * ppsc];
        self.watermark_pasterView.center = CGPointMake(rangeView.centerPoint.x *self.playerView.frame.size.width,rangeView.centerPoint.y *self.playerView.frame.size.height);
        
        BOOL isHorizontalMirror = rangeView.collage.vvAsset.isHorizontalMirror;
        BOOL isVerticalMirror = rangeView.collage.vvAsset.isVerticalMirror;
        if (isHorizontalMirror && isVerticalMirror) {
            [self.watermark_pasterView setContentImageTransform:kLRUPFlipTransform];
        }else if (isHorizontalMirror) {
            [self.watermark_pasterView setContentImageTransform:kLRFlipTransform];
        }else if (isVerticalMirror) {
            [self.watermark_pasterView setContentImageTransform:kUDFlipTransform];
        }
        if( _watermarkAlhpaSlider )
            self.watermark_pasterView.contentImage.alpha = _watermarkAlhpaSlider.value;
    }
    else{
        
        [_watermarkSizeSlider setValue:(3.0-1.0)/(_maxScale-1.0)];
    }
    
    self.watermark_pasterView.waterMaxScale = _maxScale;
    [self.watermark_pasterView setWatermarkPasterText:true];
//    self.watermark_pasterView.mirrorBtn.hidden = YES;
}

#pragma mark- pasterTextViewDelegate
- (void)pasterViewSizeScale:(RDPasterTextView *_Nullable)sticker atValue:( float ) value
{
    if( _watermark_pasterView == sticker )
    {
        [_watermarkSizeSlider setValue:(value*1.2)/(_maxScale-1.0)];
        CGFloat pradius = atan2f(self.watermark_pasterView.transform.b, self.watermark_pasterView.transform.a);
        float protate = - pradius * (180 / M_PI);
        [_watermarkRotateSlider setValue: 360 - (( protate > 0 )?( (180-protate)+180 ):(- protate)) ];
    }
    
//    if( sticker == _canvas_pasterView )
//    {
//        CGRect rect = CGRectMake(0, 0, 1, 1);
//        double rotate = 0;
//        [self pasterView_canvasRect:&rect atRotate:&rotate];
//
//        RDScene * scene = (RDScene *)scenes[_canvas_CurrentFileIndex];
//        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            obj.alpha = _fileList[_canvas_CurrentFileIndex].backgroundAlpha;
//
//            obj.rotate = rotate + _fileList[_canvas_CurrentFileIndex].rotate;
//
//            if( _fileList[_canvas_CurrentFileIndex].animationDuration > 0 )
//            {
//                RDFile * file = _fileList[_canvas_CurrentFileIndex];
//                [RDHelpClass setAssetAnimationArray:obj name:file.animationName duration:file.animationDuration center:
//                 CGPointMake(file.rectInScene.origin.x + file.rectInScene.size.width/2.0, file.rectInScene.origin.y + file.rectInScene.size.height/2.0) scale:file.rectInScale];
//            }
//            else
//            {
//                obj.rectInVideo = rect;
//            }
//        }];
//    }
}

- (void)pasterViewMoved:(RDPasterTextView *_Nullable)sticker 
{
    if( sticker == _canvas_pasterView )
    {
        if( sticker.isDrag_Upated )
        {
            CGRect rect = CGRectMake(0, 0, 1, 1);
            double rotate = 0;
            [self pasterView_canvasRect:&rect atRotate:&rotate];
            float scale = [self.canvas_pasterView getFramescale];
            
            if (self.canvas_syncContainer.bounds.size.width == self.canvas_syncContainer.bounds.size.height) {
                scale  = scale*0.25;
            }else if (self.canvas_syncContainer.bounds.size.width < self.canvas_syncContainer.bounds.size.height) {
                scale  = scale*0.5;
            }else {
                scale  =  scale*0.5;
            }
            
            sticker.dragaAlpha = -1;
            
            RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
            [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = _fileList[_canvas_CurrentFileIndex].backgroundAlpha;
                
                obj.rotate = rotate + _fileList[_canvas_CurrentFileIndex].rotate;
                
                if( _fileList[_canvas_CurrentFileIndex].animationDuration > 0 )
                {
                    RDFile * file = _fileList[_canvas_CurrentFileIndex];
                    obj.animate = nil;
                    [RDHelpClass setAssetAnimationArray:obj name:file.animationName duration:file.animationDuration center:
                     CGPointMake(rect.origin.x + rect.size.width/2.0, rect.origin.y + rect.size.height/2.0) scale:scale];
                }
                else
                {
                    obj.rectInVideo = rect;
                }
            }];
            if (CMTimeCompare(refreshCurrentTime, kCMTimeInvalid) == 0) {
                refreshCurrentTime = _videoCoreSDK.currentTime;
            }
            [_videoCoreSDK refreshCurrentFrame];
        }
        else{
            if( sticker.dragaAlpha == -1 )
            {
                RDScene * scene = (RDScene *)[_videoCoreSDK getScenes][_canvas_CurrentFileIndex];
                [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    sticker.dragaAlpha = obj.alpha;
                    obj.alpha = 0.0;
                }];
                [_videoCoreSDK refreshCurrentFrame];
            }
        }
        
//        [_videoCoreSDK seekToTime:_videoCoreSDK.currentTime toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
//            [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
//        }];
    }
}

-(void)clickSubtitlePositionItem:(UIButton *) sender
{
    float width = self.watermark_pasterView.frame.size.width;
    float height = self.watermark_pasterView.frame.size.height;
    switch (sender.tag) {
        case 1: //左上
            self.watermark_pasterView.frame = CGRectMake(-8, -8, width, height);
            break;
        case 2: //中上
             self.watermark_pasterView.frame = CGRectMake((self.watermark_syncContainer.bounds.size.width - width)/2.0, -8, width, height);
            break;
        case 3: //右上
             self.watermark_pasterView.frame = CGRectMake(self.watermark_syncContainer.bounds.size.width - width + 8, -8, width, height);
            break;
        case 4: //左中
            self.watermark_pasterView.frame = CGRectMake(-8, (self.watermark_syncContainer.bounds.size.height - height)/2.0, width, height);
            break;
        case 5: //中中
            self.watermark_pasterView.frame = CGRectMake((self.watermark_syncContainer.bounds.size.width - width)/2.0, (self.watermark_syncContainer.bounds.size.height - height)/2.0, width, height);
            break;
        case 6: //右中
            self.watermark_pasterView.frame = CGRectMake(self.watermark_syncContainer.bounds.size.width - width + 8, (self.watermark_syncContainer.bounds.size.height - height)/2.0, width, height);
            break;
        case 7: //左下
            self.watermark_pasterView.frame = CGRectMake(-8, self.watermark_syncContainer.bounds.size.height - height + 8, width, height);
            break;
        case 8: //中下
            self.watermark_pasterView.frame = CGRectMake( (self.watermark_syncContainer.bounds.size.width - width), self.watermark_syncContainer.bounds.size.height - height + 8, width, height);
            break;
        case 9: //右下
            self.watermark_pasterView.frame = CGRectMake(self.watermark_syncContainer.bounds.size.width - width + 8, self.watermark_syncContainer.bounds.size.height - height + 8, width, height);
            break;
        default:
            break;
    }
}

-(void)moveSlightlyBtnAction:(UIButton *) sender
{
    float xNumber = self.watermark_syncContainer.bounds.size.width/50.0;
    float yNumber = self.watermark_syncContainer.bounds.size.height/50.0;
    
    float width = self.watermark_pasterView.frame.size.width;
    float height = self.watermark_pasterView.frame.size.height;
    
    float x =  self.watermark_pasterView.frame.origin.x;
    float y = self.watermark_pasterView.frame.origin.y;
    
    float VideoWidth = self.watermark_syncContainer.bounds.size.width - width + 8;
    float VideoHeight = self.watermark_syncContainer.bounds.size.height - height + 8;
    
    switch (sender.tag) {
        case 2: //上
        {
            if( (y-yNumber) > -8 )
            {
                y = y-yNumber;
            }
        }
            break;
        case 1: //左
        {
            if( (x-xNumber) > -8 )
            {
                x = x-xNumber;
            }
        }
            break;
        case 4: //右
        {
            if( (x+xNumber) <= VideoWidth )
            {
                x = x+xNumber;
            }
        }
            break;
        case 3: //下
        {
            if( (y+yNumber) <= VideoHeight )
            {
                y = y+yNumber;
            }
        }
            break;
        default:
            break;
    }
    
    self.watermark_pasterView.frame = CGRectMake(x, y, width, height);
}


#pragma mark- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( scrollView == _fileterScrollView )
    {
        if( _fileterScrollView.contentOffset.x > (_fileterScrollView.contentSize.width - _fileterScrollView.frame.size.width + KScrollHeight) )
        {
            if(  currentlabelFilter <  (newFiltersNameSortArray.count - 1)  )
            {
                for (UIView *subview in _fileterScrollView.subviews) {
                    if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                    {
                        ((ScrollViewChildItem*)subview).itemIconView.image = nil;
                        [((ScrollViewChildItem*)subview) removeFromSuperview];
                    }
                }
                [_fileterScrollView removeFromSuperview];
                _fileterScrollView = nil;
                
                _fileterScrollView.delegate = nil;
                [self filterLabelBtn:[_fileterLabelNewScroView viewWithTag:currentlabelFilter+1]];
            }
        }
        else if(  _fileterScrollView.contentOffset.x < - KScrollHeight )
        {
            if( currentlabelFilter > 0 )
            {
                for (UIView *subview in _fileterScrollView.subviews) {
                    if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                    {
                        ((ScrollViewChildItem*)subview).itemIconView.image = nil;
                        [((ScrollViewChildItem*)subview) removeFromSuperview];
                    }
                }
                [_fileterScrollView removeFromSuperview];
                _fileterScrollView = nil;
                
                _fileterScrollView.delegate = nil;
                [self filterLabelBtn:[_fileterLabelNewScroView viewWithTag:currentlabelFilter-1]];
            }
        }
    }
    
}

@end
