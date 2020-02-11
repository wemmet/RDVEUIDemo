//
//  RDMultiDifferentViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/5/29.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDMultiDifferentViewController.h"
//异形调整
#import "RDTemplateCollectionViewCell.h"
#import "RDPassthroughCollectionView.h"

#import "RDCustomSizeLayout.h"

#import "RDThumbImageView.h"
#import "RDVECore.h"
#import "RDZSlider.h"
#import "RDSVProgressHUD.h"

//截取
#import "RDTrimVideoViewController.h"
//相册
#import "RDMainViewController.h"
//音乐
#import "RDLocalMusicViewController.h"
#import "RDCloudMusicViewController.h"
#import "ScrollViewChildItem.h"
#import "RDATMHud.h"
#import "UIButton+RDWebCache.h"
#import "UIImageView+RDWebCache.h"
#import "RDFileDownloader.h"
//导出
#import "RDExportProgressView.h"
#import "UIImage+RDGIF.h"
#import "SubtitleColorControl.h"

#define HanlfOfCircleWidth 2.5

#define AUTOSCROLL_THRESHOLD 30
typedef  NS_ENUM(NSInteger, RDPlayModeType)
{
    RDPlayModeType_Simultaneously       =0,     //同时
    RDPlayModeType_Order                =1,     //顺序
};

@interface RDMultiDifferentViewController ()<RDTemplateCollectionViewCellDelegate,UICollectionViewDelegate,UICollectionViewDataSource,RDThumbImageViewDelegate,RDVECoreDelegate,ScrollViewChildItemDelegate,UIAlertViewDelegate,SubtitleColorControlDelegate>
{
    //标题
    UIView                      * titleView;
    UIButton                     * titBtn;
    //异形 展示 窗口
    UIView                      * templateView;
    RDPassthroughCollectionView * templatePassthroughCollectionView;
    
    int                         currentSelectFileNumber;
    NSIndexPath                 *currentSelectCell;
    
    //功能
    NSMutableArray          * toolItems;
    
    float                   fPlateStyleHeight;
    float                   fPlateResolution;
    float                   fPlateIntervalI;
    
    CGSize                  proportionVideoSize;  //比例视频分辨率
    CGSize                  selectVideoSize;      //选中视频分辨率
    CGSize                  selectTemplatePassthroughSize;
    int                     CurrentPlateStyleIndex;    //选中效果 板式
    int                     CurrentProportionIndex;    //选中 比例
    float                   BorderWidth;
    
    RDCustomSizeLayout      * templateLayout;
    
    NSMutableArray< RDThumbImageView *> *thumbViewItems;
    NSInteger               selectFileIndex;
    NSTimer                 * _autoscrollTimer;
    float                   _autoscrollDistance;
    
    float                   playSortThumbSlider_Wdith;
    float                   playSortThumbSlider_Height;
    
    //    NSString                *pictureFrameImagePath;         //画框路径
    int                     iBorderLevelL;                 //边框等级
    
    CMTime                  seekTime;
    
    UIColor                 *videoBackgroundColor;      //背景颜色
    int                     currentIndex;
    NSIndexPath             *currentIndexPath;
    
    //音乐
    NSArray                 *musicList;
    NSInteger               selectMusicIndex;
    NSInteger               oldMusicIndex;         //配乐
    RDMusic                      *oldmusic;             //云音乐地址
    BOOL                    yuanyinOn;
    NSMutableArray          *mvMusicArray;
    NSMutableArray<RDMusic *>           *dubbingArr;
    //导出
    BOOL             isContinueExport;
    BOOL             _idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    RDFile                      *coverFile, *oldCoverFile;
    
    bool            isExport;
    
    bool            isMusic;
    
    UIButton *publishBtn;
    
    boolean_t       isAllImage;             //是否全图片
    
    UIButton * simultaneouslyBtn;
    UIButton *  orderBtn;
    
    //旋转
    int                 currentRotateGrade;  //旋转等级
    
    bool                isMask;             //是否异形
    
    float                       volumeMultipleM;
    float                       oldVolume;
    UIImageView             * currentCellImage;
    
    SubtitleColorControl    *colorControl;
}
@property(nonatomic,strong)UIScrollView     * toolBarView;               //功能按钮 列表
//功能界面
@property(nonatomic,strong)UIView           * functionalView;            //功能 界面
//板式
@property(nonatomic,strong)UIView           * plateView;                 //板式 界面
@property(nonatomic,strong)UIScrollView     * plateScrollView;           //板式 Scroll 界面
@property(nonatomic,strong)UIScrollView     * plateStyleScrollView;      //板式样式 界面
@property(nonatomic,strong)UIScrollView     * plateResolutionScrollView; //板式分辨率 界面

//边框
@property(nonatomic,strong)UIView           * frameView;                 //边框 界面
@property(nonatomic,strong)RDZSlider        * frameSlider;               //边框 进度条
@property(nonatomic,strong)UILabel          * frameLabel;                //粗细数字

//播放顺序
@property(nonatomic,assign)RDPlayModeType     playModeType;              //播放顺序的方式
@property(nonatomic,strong)UIView           * playOrderView;             //播放顺序 界面
@property(nonatomic,strong)UIScrollView     * playOrderScrollView;       //播放顺序 Scroll 界面

@property(nonatomic,strong)UIView           * playModeView;              //播放模式
@property(nonatomic,strong)UIScrollView     * playModeBtnVIew;           //按钮界面


@property(nonatomic,strong)UIView           * playSortView;              //播放排序
@property(nonatomic,strong)UILabel          * playSortLabel;

@property(nonatomic,strong)UIView           * playSortThumbSliderView;
@property(nonatomic,strong)UIScrollView     * playSortThumbSlider;
@property(nonatomic,strong)UIView           * playSortThumbSliderback;
@property(nonatomic,strong)UILabel          * playSortPromptLabel;        //提示

@property(nonatomic,strong)UIView           * playSortSimultaneouslyView;       //同时
@property(nonatomic,strong)UIView           * playSortSimultaneouslyShowView;   //展示控件

//音乐
@property(nonatomic,strong)UIScrollView     * musicScrollView;
@property(nonatomic,strong)UIView           * musicView;                 //音乐 界面
@property(nonatomic,strong)UIButton         *dubbingItemBtn;
@property(nonatomic,strong)UILabel          *musicVolumeLabel;
@property(nonatomic,strong)UILabel          *videoVolumelabel;
@property(nonatomic,strong)RDZSlider        *musicVolumeSlider;
@property(nonatomic,strong)UIScrollView     *musicChildsView;

@property(nonatomic,strong)RDATMHud         *hud;
@property(nonatomic       )UIAlertView      *commonAlertView;
@property(nonatomic,strong)RDExportProgressView *exportProgressView;


@property(nonatomic,strong)NSMutableArray <RDMultiDifferentFile *>*multiDifferentFileList;
@property (nonatomic, strong) RDVECore                  *videoCoreSDK;                   //播放核心
@property (nonatomic, assign) float maxVideoDuration;                   //总时长

//播放界面
@property(nonatomic,strong)UIView           * playView;              //播放界面
@property(nonatomic,strong)UIView           * playVideoView;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic,strong)UIView           *playerToolBar;
@property(nonatomic,strong)UILabel          *currentTimeLabel;
@property(nonatomic,strong)UILabel          *durationLabel;
@property(nonatomic,strong)RDZSlider        *videoProgressSlider;

//选中界面
@property(nonatomic,strong)UIView           * selectView;              //选中界面
@property(nonatomic,strong)UIButton         * closeBtn;                //关闭按钮
@property(nonatomic,strong)UIView           * selectFunctionalAreaView;//功能区
@property(nonatomic,strong)UIScrollView     * selectScrollFunctionalAreaView;//功能区


//音量
@property(nonatomic,strong)UIView           *volumeView;
@property(nonatomic,strong)RDZSlider        *originalVolumeSlider;
@property(nonatomic,strong)UIView               *volumeTitleView;

@property (nonatomic, strong) NSMutableArray *colorArray;
@end

@implementation RDMultiDifferentViewController

#pragma mark- 音量
-( UIView *)volumeView
{
    if(!_volumeView )
    {
        _volumeView = [UIView new];
        _volumeView.frame = _selectScrollFunctionalAreaView.frame;
        _volumeView.backgroundColor = BOTTOM_COLOR;
        
        UILabel * VolumeLabel = [UILabel new];
        VolumeLabel.frame = CGRectMake(0, ( _volumeView.frame.size.height - kToolbarHeight - 31 )/2.0, 50, 31);
        VolumeLabel.textAlignment = NSTextAlignmentCenter;
        VolumeLabel.backgroundColor = [UIColor clearColor];
        VolumeLabel.font = [UIFont boldSystemFontOfSize:12];
        VolumeLabel.textColor = [UIColor whiteColor];
        VolumeLabel.text = RDLocalizedString(@"原音", nil);
        
        [_volumeView addSubview:VolumeLabel];
        [_volumeView addSubview:self.originalVolumeSlider];
        
        _volumeView.hidden = YES;
//        [self.view addSubview:_volumeView];
        [_volumeView addSubview:self.volumeTitleView];
        [_selectFunctionalAreaView addSubview:_volumeView];
    }
    return _volumeView;
}
//原音音量比例调节
- (RDZSlider *)originalVolumeSlider{
    if(!_originalVolumeSlider){
        
        __block RDMultiDifferentFile * multiDifferentFile = nil;
        [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( self->currentIndex == obj.number )
                multiDifferentFile = obj;
        }];
        
        _originalVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50,( _volumeView.frame.size.height - kToolbarHeight - 31 )/2.0, kWIDTH - 80, 31)];
        _originalVolumeSlider.alpha = 1.0;
        _originalVolumeSlider.backgroundColor = [UIColor clearColor];
        [_originalVolumeSlider setMaximumValue:1];
        [_originalVolumeSlider setMinimumValue:0];
        [_originalVolumeSlider setMinimumTrackImage:[RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:2.0] forState:UIControlStateNormal];
        [_originalVolumeSlider setMaximumTrackImage:[RDHelpClass rdImageWithColor:UIColorFromRGB(0x888888) cornerRadius:2.0] forState:UIControlStateNormal];
        [_originalVolumeSlider setThumbImage:[RDHelpClass rdImageWithColor:Main_Color cornerRadius:7.0] forState:UIControlStateNormal];
        [_originalVolumeSlider setValue:(multiDifferentFile.file.videoVolume/volumeMultipleM)];
        [_originalVolumeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_originalVolumeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_originalVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_originalVolumeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        _originalVolumeSlider.enabled = YES;
    }
    return _originalVolumeSlider;
}

#pragma mark- 标题
- (UIView *)volumeTitleView {
    if (!_volumeTitleView) {
        _volumeTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, _volumeView.frame.size.height - kToolbarHeight, kWIDTH, kToolbarHeight)];
        _volumeTitleView.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:_volumeTitleView];
        
        UILabel * toolbarTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
        toolbarTitleLbl.text = RDLocalizedString(@"原音音量", nil);
        toolbarTitleLbl.textAlignment = NSTextAlignmentCenter;
        toolbarTitleLbl.font = [UIFont boldSystemFontOfSize:17];
        toolbarTitleLbl.textColor = [UIColor whiteColor];
        [_volumeTitleView addSubview:toolbarTitleLbl];
        
        UIButton * cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        [_volumeTitleView addSubview:cancelBtn];
        
        UIButton * _toolbarTitlefinishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [_toolbarTitlefinishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_toolbarTitlefinishBtn addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
        [_volumeTitleView addSubview:_toolbarTitlefinishBtn];
    }
    return _volumeTitleView;
}

-(void)back
{
    __block RDMultiDifferentFile * multiDifferentFile = nil;
    [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( self->currentIndex == obj.number )
            multiDifferentFile = obj;
    }];
    multiDifferentFile.file.videoVolume = oldVolume;
    _volumeView.hidden = YES;
    _selectScrollFunctionalAreaView.hidden = NO;
}

-(void)tapPublishBtn
{
    _volumeView.hidden = YES;
    _selectScrollFunctionalAreaView.hidden = NO;
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
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgressView){
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __block int imageCount = 0;
    _multiDifferentFileList = [[NSMutableArray alloc] init];
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDMultiDifferentFile * file = [[RDMultiDifferentFile alloc] init];
        file.number = idx;
        file.file = obj;
        UIImage *image = nil;
        if( obj.fileType == kFILEVIDEO )
            image = [RDHelpClass geScreenShotImageFromVideoURL:obj.contentURL atTime:obj.videoTrimTimeRange.start  atSearchDirection:false];
        else
            image = [RDHelpClass getFullScreenImageWithUrl:obj.contentURL];
            
        file.thumbnailImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        file.thumbnailImage.image = image;
        if( obj.fileType == kFILEIMAGE && !obj.isGif) {
            imageCount++;
        }
        [_multiDifferentFileList addObject:file];
    }];
    if( imageCount >= (_multiDifferentFileList.count-1) )
        isAllImage = YES;//只有一个或者没有视频
    else
        isAllImage = NO;
    
    if (CGSizeEqualToSize(_exportVideoSize, CGSizeZero))
        _exportVideoSize = [RDHelpClass getEditVideoSizeWithFileList:_fileList];
    
    isMask = false;
    
    volumeMultipleM= 5.0;
    oldVolume = 1.0;
    isExport = false;
    _musicVolume = 0.5;
    selectMusicIndex = 1;
    
    yuanyinOn = YES;
    iBorderLevelL = 1;
    _playModeType = RDPlayModeType_Simultaneously;
    BorderWidth = 20.0;
    CurrentPlateStyleIndex = 1;
    CurrentProportionIndex = 1;
    videoBackgroundColor = UIColorFromRGB(0xffffff);
    proportionVideoSize = _exportVideoSize;
    selectVideoSize = _exportVideoSize;
    
    //    pictureFrameImagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/pictureFrame/%d-%d-%d", _fileList.count,iBorderLevelL,CurrentPlateStyleIndex] Type:@"png"];
    
    fPlateStyleHeight = 70;
    fPlateResolution = 50;
    playSortThumbSlider_Wdith = 60;
    playSortThumbSlider_Height = fPlateStyleHeight - 20;
    
    self.navigationController.navigationBar.translucent = iPhone4s;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    [self initTitleView];
    [self initTemplateView];
    [self.view addSubview:titleView];
    [self toolBarViewItems:0];
    [self.view addSubview:self.functionalView];
    
    if(!_plateView.superview)
    {
        [self.functionalView addSubview:self.plateView];
        self.plateView.hidden = NO;
        [self plateScrollView_Items];
    }
    
    [self clickToolItemBtn:[self.toolBarView viewWithTag:[[toolItems[0] objectForKey:@"id"] integerValue]]];
}

-(void)tit_Btn
{
    if( titBtn.isSelected )
    {
        titBtn.selected = NO;
        if (isMusic) {
            [self playVideo:NO];
        }else {
            [_videoCoreSDK stop];
            [_videoCoreSDK.view removeFromSuperview];
            _videoCoreSDK.delegate = nil;
            _videoCoreSDK = nil;
            [self deletePlayView];
            _playView.hidden = YES;
            templatePassthroughCollectionView.hidden = NO;
        }
    }
    else
    {
        titBtn.selected = YES;
        if (!_videoCoreSDK) {
            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            [templateView addSubview:self.playView];
            _playView.hidden = YES;
            if( !isExport )
                templatePassthroughCollectionView.hidden = YES;
        }else {
            [self playVideo:YES];
        }
    }
}

#pragma mark-顶部标题栏的设置
- (void)initTitleView {
    titleView = [UIView new];
    titleView.frame = CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, 44);
    if( iPhone4s )
        titleView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    else
        titleView.backgroundColor = BOTTOM_COLOR;
    
    titBtn = [[UIButton alloc] init];
    titBtn.frame = CGRectMake(0, (titleView.frame.size.height - 44), kWIDTH, 44);
    titBtn.backgroundColor = [UIColor clearColor];
    titBtn.font = [UIFont boldSystemFontOfSize:20];
    [titBtn setTitle:RDLocalizedString(@"预览", nil) forState:UIControlStateNormal];
    [titBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [titBtn setTitle:RDLocalizedString(@"停止", nil) forState:UIControlStateSelected];
    [titBtn addTarget:self action:@selector(tit_Btn) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:titBtn];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.backgroundColor = [UIColor clearColor];
    backBtn.frame = CGRectMake(5, (titleView.frame.size.height - 44), 44, 44);
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    publishBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
    publishBtn.exclusiveTouch = YES;
    publishBtn.backgroundColor = [UIColor clearColor];
    publishBtn.frame = CGRectMake(kWIDTH - 69, (titleView.frame.size.height - 44), 64, 44);
    publishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [publishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [publishBtn setTitle:RDLocalizedString(@"导出",nil) forState:UIControlStateNormal];
//    [publishBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"剪辑-裁切确定默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(publishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:publishBtn];
}
#pragma mark-返回
- (void)back:(UIButton *)sender{
//    [_videoCoreSDK stop];
//    _videoCoreSDK.delegate = nil;
//    [_videoCoreSDK.view removeFromSuperview];
//    _videoCoreSDK = nil;
    sender.selected = YES;
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
    if(!upView){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if(_cancelBlock){
        _cancelBlock();
    }
}
#pragma mark-发布
- (void)publishBtnAction:(UIButton *)sender {
    
    if( !_videoCoreSDK )
    {
        isExport = true;
        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
        [templateView addSubview:self.playView];
        _playView.hidden = YES;
    }
    else
        [self exportMovie];
}
-(void)initTemplateView
{
    if( iPhone4s )
        templateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH,kPlayerViewHeight)];
    else
        templateView = [[UIView alloc] initWithFrame:CGRectMake(0, titleView.frame.size.height + titleView.frame.origin.y, kWIDTH, (LASTIPHONE_5 ? ( iPhone_X?  kPlayerViewHeight:( kPlayerViewHeight - (fPlateStyleHeight + 20) ) ) :  kPlayerViewHeight))];
    //    templateView.backgroundColor = [UIColor clearColor];
    templateView.backgroundColor = UIColorFromRGB(0x000000);
    [self.view addSubview:templateView];
    [self adjProportion: 1 ];
    
}
-(void)initTemplatePassthroughCollectionView
{
    if( _videoCoreSDK )
        [self tit_Btn];
    
    [templatePassthroughCollectionView removeFromSuperview];
    templatePassthroughCollectionView = nil;
    currentIndex = -1;
    currentIndexPath = nil;
    
    templateLayout = [[RDCustomSizeLayout alloc] init];
    templateLayout.templateIndex = _multiDifferentFileList.count;
    if( _multiDifferentFileList.count > 1 )
        templateLayout.templateType = CurrentPlateStyleIndex;
    else
        templateLayout.templateType = 1;
    templateLayout.templateBorderWidth = 0;
    
    templatePassthroughCollectionView = [[RDPassthroughCollectionView alloc] initWithFrame:CGRectMake((templateView.frame.size.width - selectTemplatePassthroughSize.width)/2.0, (templateView.frame.size.height - selectTemplatePassthroughSize.height)/2.0, selectTemplatePassthroughSize.width, selectTemplatePassthroughSize.height) collectionViewLayout:templateLayout];
    if( [self getMask] )
        templatePassthroughCollectionView.isMask = true;
    else
        templatePassthroughCollectionView.isMask = false;
    
    //    templatePassthroughCollectionView.layer.borderColor = videoBackgroundColor.CGColor;
    //    templatePassthroughCollectionView.layer.borderWidth = _frameSlider.value * BorderWidth;
    templatePassthroughCollectionView.backgroundColor = videoBackgroundColor;
    [templatePassthroughCollectionView registerClass:[RDTemplateCollectionViewCell class] forCellWithReuseIdentifier:@"TemplateCollectionViewCell"];
    templatePassthroughCollectionView.showsHorizontalScrollIndicator = NO;
    templatePassthroughCollectionView.dataSource = self;
    templatePassthroughCollectionView.delegate = self;
    templatePassthroughCollectionView.tag = 1;
    [templateView addSubview:templatePassthroughCollectionView];
}

#pragma mark- 功能界面
-(UIView *)functionalView
{
    if( !_functionalView )
    {
        _functionalView = [[UIView alloc] initWithFrame:CGRectMake(0, templateView.frame.size.height + templateView.frame.origin.y , kWIDTH, kHEIGHT - (templateView.frame.size.height + templateView.frame.origin.y + 60 + (iPhone_X ? 34 : 0)) )];
        _functionalView.backgroundColor =  SCREEN_BACKGROUND_COLOR;
        //        _functionalView.backgroundColor =  UIColorFromRGB(0xffffff);
        [self.view addSubview:_functionalView];
        
        fPlateIntervalI = ( (_functionalView.frame.size.height - (20 + fPlateStyleHeight + fPlateResolution )) <= 0 )? 0 : (_functionalView.frame.size.height - (20 + fPlateStyleHeight + fPlateResolution ))/2.0;
    }
    return _functionalView;
}
#pragma mark- 功能分类
-(void)toolBarViewItems:(NSInteger) index
{
    [toolItems removeAllObjects];
    [_toolBarView removeFromSuperview];
    _toolBarView = nil;
    
    toolItems = [NSMutableArray array];
    //板式
    NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"板式",@"title",@(1),@"id", nil];
    [toolItems addObject:dic1];
    //边框
    NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"边框",@"title",@(2),@"id", nil];
    [toolItems addObject:dic2];
    //播放顺序
    NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"播放顺序",@"title",@(3),@"id", nil];
    [toolItems addObject:dic3];
    //音乐
    NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"音乐",@"title",@(4),@"id", nil];
    [toolItems addObject:dic4];
    
    EditConfiguration *editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    _toolBarView =  [UIScrollView new];
    _toolBarView.backgroundColor = UIColorFromRGB(0x131313);
    _toolBarView.frame = CGRectMake(0, kHEIGHT - 60 - (iPhone_X ? 34 : 0), kWIDTH, 60 + (iPhone_X ? 34 : 0) );
    _toolBarView.showsVerticalScrollIndicator = NO;
    _toolBarView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_toolBarView];
    NSUInteger count = toolItems.count;
    
    __block float toolItemBtnWidth = MAX(kWIDTH/count, 60 + 5);//_toolBarView.frame.size.height
    __block int iIndex = kWIDTH/toolItemBtnWidth;
    __block float width = toolItemBtnWidth;
    toolItemBtnWidth = toolItemBtnWidth - ((toolItems.count > iIndex)?(toolItemBtnWidth/2.0/(iIndex)):0);
    __block float contentsWidth = 0;
    NSUInteger offset = (count - toolItems.count)/2;
    [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = [self->toolItems[idx] objectForKey:@"title"];
        UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
        toolItemBtn.backgroundColor = [UIColor clearColor];
        toolItemBtn.exclusiveTouch = YES;
        toolItemBtn.frame = CGRectMake((idx+offset) * toolItemBtnWidth + ((toolItems.count > iIndex)?(width/2.0/(iIndex)):0), 0, toolItemBtnWidth, _toolBarView.frame.size.height - (iPhone_X ? 34 : 0));
        [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/%@-默认_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/%@-选中_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:UIColorFromRGB(0x898989) forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateSelected];
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
/**功能选择
 */
- (void)clickToolItemBtn:(UIButton *)sender{
    switch ( sender.tag ) {
        case 1: //板式
        {
            _videoCoreSDK.enableAudioEffect = NO;
            _playOrderView.hidden = YES;
            _musicView.hidden = YES;
            _frameView.hidden = YES;
            [self.functionalView addSubview:self.plateView];
            self.plateView.hidden = NO;
            isMusic = false;
            if( _videoCoreSDK ) {
                titBtn.selected = YES;
                [self tit_Btn];
            }
        }
            break;
        case 2: //边框
        {
            _videoCoreSDK.enableAudioEffect = NO;
            _plateView.hidden = YES;
            _playOrderView.hidden = YES;
            _musicView.hidden = YES;
            [self.functionalView addSubview:self.frameView];
            _frameView.hidden = NO;
            isMusic = false;
            if( _videoCoreSDK ) {
                titBtn.selected = YES;
                [self tit_Btn];
            }
        }
            break;
        case 3: //播放顺序
        {
            _videoCoreSDK.enableAudioEffect = NO;
            _plateView.hidden = YES;
            _frameView.hidden = YES;
            _musicView.hidden = YES;
            [self.functionalView addSubview:self.playOrderView];
            _playOrderView.hidden= NO;
            isMusic = false;
            if( _videoCoreSDK ) {
                titBtn.selected = YES;
                [self tit_Btn];
            }
        }
            break;
        case 4: //音乐
        {
            _videoCoreSDK.enableAudioEffect = YES;
            if( !_videoCoreSDK )
                [self tit_Btn];
            _plateView.hidden = YES;
            _frameView.hidden = YES;
            _playOrderView.hidden= YES;
            [self.functionalView addSubview:self.musicScrollView];
            isMusic = true;
            _musicView.hidden = NO;
        }
            break;
        default:
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

#pragma mark- 板式
-(UIView*)plateView
{
    if( !_plateView )
    {
        _plateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _functionalView.frame.size.width, _functionalView.frame.size.height)];
        //        [_functionalView addSubview:_plateView];
        _plateView.hidden = YES;
        
        [_plateView addSubview:self.plateScrollView];
    }
    return _plateView;
}
-(UIScrollView*)plateScrollView
{
    if( !_plateScrollView )
    {
        _plateScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _plateView.frame.size.width, _plateView.frame.size.height)];
        [_plateScrollView addSubview:self.plateStyleScrollView];
        [_plateScrollView addSubview:self.plateResolutionScrollView];
        _plateScrollView.contentSize = CGSizeMake(kWIDTH,   10  + _plateResolutionScrollView.frame.size.height+_plateStyleScrollView.frame.size.height);
    }
    return _plateScrollView;
}
-(UIScrollView*)plateStyleScrollView
{
    if( !_plateStyleScrollView )
    {
        _plateStyleScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, fPlateIntervalI, _plateScrollView.frame.size.width, fPlateStyleHeight)];
        _plateStyleScrollView.backgroundColor = [UIColor clearColor];
        _plateStyleScrollView.showsVerticalScrollIndicator = NO;
        _plateStyleScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _plateStyleScrollView;
}
-(void)plateScrollView_Items
{
    NSMutableArray * plateResolutionItems = [NSMutableArray array];
    
    int count = 0;
    switch ( _multiDifferentFileList.count ) {
        case 1:
        {
            count = 1;
        }
            break;
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 2:
        {
            count = 6;
        }
            break;
        case 9:
        {
            count = 4;
        }
            break;
        default:
            break;
    }
    for (int i = 0; i < count ; i++) {
        NSString * title = [NSString stringWithFormat:@"%d-%d", _multiDifferentFileList.count, i+1 ];
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:title,@"title",@(i+1),@"id", nil];
        [plateResolutionItems addObject:dic];
    }
    
    __block float toolItemBtnWidth =  self.plateStyleScrollView.frame.size.height - 10 ;
    [plateResolutionItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = [plateResolutionItems[idx] objectForKey:@"title"];
        UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolItemBtn.tag = [[plateResolutionItems[idx] objectForKey:@"id"] integerValue];
        toolItemBtn.backgroundColor = [UIColor clearColor];
        toolItemBtn.exclusiveTouch = YES;
        
        [toolItemBtn addTarget:self action:@selector(plateStyleItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/Puzzle_Images/mix_%d/%@_@3x",_multiDifferentFileList.count ,title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/Puzzle_Images/mix_%d/%@-1_@3x",_multiDifferentFileList.count,title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        toolItemBtn.frame = CGRectMake( idx *(10 + toolItemBtnWidth) + 10 , 5, toolItemBtnWidth, toolItemBtnWidth);
//        if( _multiDifferentFileList.count == 2 )
//        {
//            if(
////               ([[plateResolutionItems[idx] objectForKey:@"id"] integerValue]==5) ||
//               ([[plateResolutionItems[idx] objectForKey:@"id"] integerValue]==6))
//            {
//                toolItemBtn = nil;
//                return;
//            }
//        }
//        if(_multiDifferentFileList.count == 3)
//        {
//            if( ([[plateResolutionItems[idx] objectForKey:@"id"] integerValue]==3)
//               || ([[plateResolutionItems[idx] objectForKey:@"id"] integerValue]==4))
//            {
//                toolItemBtn = nil;
//                return;
//            }
//            if( [[plateResolutionItems[idx] objectForKey:@"id"] integerValue] > 4 )
//            {
//                toolItemBtn.frame = CGRectMake( (idx-2) *(10 + toolItemBtnWidth) + 10 , 5, toolItemBtnWidth, toolItemBtnWidth);
//            }
//        }
        [self.plateStyleScrollView addSubview:toolItemBtn];
    }];
    [self plateStyleItemBtn:[self.plateStyleScrollView viewWithTag:[[toolItems[0] objectForKey:@"id"] integerValue]]];
    self.plateStyleScrollView.contentSize = CGSizeMake((10+toolItemBtnWidth)*count + 10, toolItemBtnWidth);
}
-(void)plateStyleItemBtn:(UIButton *)sender{
    
    CurrentPlateStyleIndex = sender.tag;
    
    //    pictureFrameImagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/pictureFrame/%d-%d-%d", _fileList.count,iBorderLevelL,CurrentPlateStyleIndex] Type:@"png"];
    
    [self adjProportion:CurrentProportionIndex];
    [_plateStyleScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == sender.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

-(UIScrollView*)plateResolutionScrollView
{
    if( !_plateResolutionScrollView )
    {
        _plateResolutionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,  _plateStyleScrollView.frame.origin.y + _plateStyleScrollView.frame.size.height + fPlateIntervalI, _plateScrollView.frame.size.width, fPlateResolution)];
        _plateResolutionScrollView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _plateResolutionScrollView.showsVerticalScrollIndicator = NO;
        _plateResolutionScrollView.showsHorizontalScrollIndicator = NO;
        
        NSMutableArray * plateResolutionItems = [NSMutableArray array];
        //1:1
        [plateResolutionItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1-1",@"title",@(1),@"id", nil]];
        //3:4
        [plateResolutionItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"3-4",@"title",@(2),@"id", nil]];
        //4:3
        [plateResolutionItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"4-3",@"title",@(3),@"id", nil]];
        //9:16
        [plateResolutionItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"9-16",@"title",@(4),@"id", nil]];
        //16:9
        [plateResolutionItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"16-9",@"title",@(5),@"id", nil]];
        
        NSUInteger count = (plateResolutionItems.count>5)?plateResolutionItems.count:5;
        
        if( (count == 5) && (plateResolutionItems.count%2) == 0.0 )
        {
            count = 4;
        }
        __block float toolItemBtnWidth = MAX(kWIDTH/count, 60 + 5);//_toolBarView.frame.size.height
        __block int iIndex = kWIDTH/toolItemBtnWidth + 1.0;
        __block float width = toolItemBtnWidth;
        toolItemBtnWidth = toolItemBtnWidth - ((plateResolutionItems.count > iIndex)?(toolItemBtnWidth/2.0/(iIndex)):0);
        __block float contentsWidth = 0;
        NSUInteger offset = (count - plateResolutionItems.count)/2;
        [plateResolutionItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *title = [plateResolutionItems[idx] objectForKey:@"title"];
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[plateResolutionItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.exclusiveTouch = YES;
            toolItemBtn.frame = CGRectMake((idx+offset) * toolItemBtnWidth + ((plateResolutionItems.count > iIndex)?(width/2.0/(iIndex)):0), 0, toolItemBtnWidth, self.plateResolutionScrollView.frame.size.height);
            [toolItemBtn addTarget:self action:@selector(plateResolutionItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/proportion/比例%@_默认_@3x", title] Type:@"png"];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/proportion/比例%@_选中_@3x", title] Type:@"png"];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
            //            [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            //            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            //            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 0, (toolItemBtnWidth - 44)/2.0)];
            [self.plateResolutionScrollView addSubview:toolItemBtn];
            contentsWidth += toolItemBtnWidth;
        }];
        [self plateResolutionItemBtn:[self.plateResolutionScrollView viewWithTag:[[toolItems[0] objectForKey:@"id"] integerValue]]];
    }
    return _plateResolutionScrollView;
}
-(void)plateResolutionItemBtn:(UIButton *)sender{
    CurrentProportionIndex = sender.tag;
    [self adjProportion:sender.tag];
    [_plateResolutionScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == sender.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

-(void)adjProportion:(NSInteger) tag
{
    float width = MAX(proportionVideoSize.width, proportionVideoSize.height);
    CGSize size = templateView.frame.size;
    switch ( tag ) {
        case 1://正方形
        {
            selectVideoSize = CGSizeMake(width, width);
            size = CGSizeMake(templateView.frame.size.width, templateView.frame.size.width);
        }
            break;
        case 5://16:9
            selectVideoSize = CGSizeMake(width, (9.0/16.0) * width);
            size = CGSizeMake(templateView.frame.size.width, (9.0/16.0) * templateView.frame.size.width);
            break;
        case 4://9:16
            selectVideoSize = CGSizeMake((9.0/16.0) * width, width);
            size = CGSizeMake((9.0/16.0) * templateView.frame.size.height, templateView.frame.size.height);
            break;
        case 3://4:3
            selectVideoSize = CGSizeMake(width, (3.0/4.0) * width);
            size = CGSizeMake(templateView.frame.size.width, (3.0/4.0) *templateView.frame.size.width);
            break;
        case 2://3:4
            selectVideoSize = CGSizeMake((3.0/4.0) * width, width);
            size = CGSizeMake((3.0/4.0) *templateView.frame.size.height, templateView.frame.size.height);
            break;
        default:
            break;
    }
    selectTemplatePassthroughSize = size;
    [self initTemplatePassthroughCollectionView];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _multiDifferentFileList.count;
}
- (CGRect)getCropFrame:(AVURLAsset *)asset vidoInfo:(RDTemplateCollectionViewCell *)cell {
    
    BOOL isPortrait = [RDHelpClass isVideoPortrait:asset];
    CGSize videoSize = [RDHelpClass getVideoSizeForTrack:asset];
    CGRect rectInVideo = cell.currentMultiDifferentFile.rectInVideo;
    
    CGSize frameInViewSize = CGSizeMake(rectInVideo.size.width*templatePassthroughCollectionView.frame.size.width, rectInVideo.size.height*templatePassthroughCollectionView.frame.size.height);
    
    CGRect cropRect = CGRectZero;
    CGRect crop = CGRectZero;
    
    if (isPortrait) {
        float ratiow = frameInViewSize.width/frameInViewSize.height;
        float ratioh = frameInViewSize.height/frameInViewSize.width;
        if (ratiow <= 1.0) {
            cropRect = CGRectMake((videoSize.width - videoSize.height*ratiow)/2.0, 0, videoSize.height*ratiow, videoSize.height);
            crop = CGRectMake(cropRect.origin.x/videoSize.width, 0, cropRect.size.width/videoSize.width, 1.0);
            if (cropRect.size.width > videoSize.width) {
                cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
                crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
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
    return crop;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if( (currentIndexPath != nil) && ( currentIndexPath.row == indexPath.row ))
    {
        RDTemplateCollectionViewCell *currCell = (RDTemplateCollectionViewCell *)[collectionView cellForItemAtIndexPath:currentIndexPath];
        [currCell noSelect];
        collectionView.backgroundColor = videoBackgroundColor;
        currentIndex  = -1;
        currentIndexPath = nil;
        _selectView.hidden = YES;
        NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
        [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj noSelect];
        }];
        return;
    }

    if (currentIndexPath) {
        RDTemplateCollectionViewCell *prevCell = (RDTemplateCollectionViewCell *)[collectionView cellForItemAtIndexPath:currentIndexPath];
        [prevCell setSelect:NO];
    }
    currentIndexPath = indexPath;
    RDTemplateCollectionViewCell *currCell = (RDTemplateCollectionViewCell *)[collectionView cellForItemAtIndexPath:currentIndexPath];
    [currCell setSelect:YES];
    currentRotateGrade = currCell.currentMultiDifferentFile.RotateGrade;
    currentIndex = currCell.currentMultiDifferentFile.number;
    collectionView.backgroundColor = [videoBackgroundColor colorWithAlphaComponent:0.6];

    NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
    [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       if( obj.currentMultiDifferentFile.number != currentIndex )
            [obj setSelect:NO];
    }];
    
    self.selectView.hidden = NO;
    [self initToolItem];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * CellIdentifier = @"TemplateCollectionViewCell";
    RDTemplateCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.contentView.clipsToBounds = YES;
    cell.selectImage.hidden = YES;
    cell.noSelectImage.hidden = YES;
    [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.number == indexPath.row)
        {
            cell.currentMultiDifferentFile = obj;
        }
    }];
    cell.currentMultiDifferentFile.isChangedCrop = NO;
    cell.currentMultiDifferentFile.scale = 1.0;
//    cell.currentMultiDifferentFile.file.rotate = 0;
    cell.currentMultiDifferentFile.RotateGrade = 0;
    
    cell.originalRect = CGRectMake(cell.frame.origin.x/templatePassthroughCollectionView.frame.size.width,
                                   cell.frame.origin.y/templatePassthroughCollectionView.frame.size.height,
                                   cell.frame.size.width/templatePassthroughCollectionView.frame.size.width,
                                   cell.frame.size.height/templatePassthroughCollectionView.frame.size.height
                                   );
//    if( cell.currentMultiDifferentFile.file.fileType == kFILEVIDEO )
//        cell.thumbnailIV.image = [RDHelpClass getLastScreenShotImageFromVideoURL:cell.currentMultiDifferentFile.file.contentURL atTime:cell.currentMultiDifferentFile.file.videoTrimTimeRange.start];
//    else
//        cell.thumbnailIV.image = [RDHelpClass getThumbImageWithUrl:cell.currentMultiDifferentFile.file.contentURL];
    cell.thumbnailIV.image = cell.currentMultiDifferentFile.thumbnailImage.image;
    if( cell.currentMultiDifferentFile.file.rotate != 0 )
        [cell setImageViewRotate:360 - cell.currentMultiDifferentFile.file.rotate];
    [self adjCellFrame:cell];
    [cell addGestureRecognizerToView];
    cell.delegate = self;
    return cell;
}

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

-(void)SetImage:(RDTemplateCollectionViewCell *) cell Rect:(CGRect) rect videoSize:(CGSize) VideRect
{
    bool isExchange = false;
    if( ( cell.currentMultiDifferentFile.file.rotate == 90) || ( cell.currentMultiDifferentFile.file.rotate  == 270) )
        isExchange = true;
    
    float borderWidth = _frameSlider.value * BorderWidth;
    
    float fwidth = (rect.size.width/rect.size.height)*VideRect.height;
    float proportion = VideRect.width/VideRect.height;
    
    if( fwidth <= VideRect.width )
        cell.thumbnailIV.frame = CGRectMake( (int)((rect.size.width - proportion * rect.size.height)/2.0) , 0, proportion * rect.size.height, rect.size.height);
    else
        cell.thumbnailIV.frame = CGRectMake( 0,(int)((rect.size.height - 1.0/proportion * rect.size.width)/2.0) ,rect.size.width, rect.size.width/proportion  );
    
    cell.currentMultiDifferentFile.rectInVideo = CGRectMake(rect.origin.x/templatePassthroughCollectionView.frame.size.width, rect.origin.y/templatePassthroughCollectionView.frame.size.height,
                                                            
                                                            rect.size.width/templatePassthroughCollectionView.frame.size.width,
                                                            rect.size.height/templatePassthroughCollectionView.frame.size.height);
    NSLog(@"UI_rectInVideo:%.2f - %.2f - %.2f - %.2f\n",cell.currentMultiDifferentFile.rectInVideo.origin.x,cell.currentMultiDifferentFile.rectInVideo.origin.y,cell.currentMultiDifferentFile.rectInVideo.size.width,cell.currentMultiDifferentFile.rectInVideo.size.height);
    
    if( !cell.currentMultiDifferentFile.isChangedCrop )
    {
        cell.currentMultiDifferentFile.crop = CGRectMake(fabsf(cell.thumbnailIV.frame.origin.x/cell.thumbnailIV.frame.size.width),fabsf(cell.thumbnailIV.frame.origin.y/cell.thumbnailIV.frame.size.height),
                                                         
            rect.size.width/cell.thumbnailIV.frame.size.width,
            rect.size.height/cell.thumbnailIV.frame.size.height);
        
        cell.crop = cell.currentMultiDifferentFile.crop;
        NSLog(@"UI_crop:%.2f - %.2f - %.2f - %.2f\n",cell.currentMultiDifferentFile.crop.origin.x,cell.currentMultiDifferentFile.crop.origin.y,cell.currentMultiDifferentFile.crop.size.width,cell.currentMultiDifferentFile.crop.size.height);

    }
    cell.originalThumbnailSize = cell.thumbnailIV.frame.size;
}

#pragma mark- 播放顺序
-(UIView *)playOrderView
{
    if( !_playOrderView )
    {
        _playOrderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _functionalView.frame.size.width, _functionalView.frame.size.height)];
        _playOrderView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [_functionalView addSubview:_playOrderView];
        [_playOrderView addSubview:self.playOrderScrollView];
    }
    return _playOrderView;
}
-(UIScrollView*)playOrderScrollView
{
    if( !_playOrderScrollView )
    {
        _playOrderScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _playOrderView.frame.size.width, _playOrderView.frame.size.height)];
        [_playOrderScrollView addSubview:self.playModeView];
        [_playOrderScrollView addSubview:self.playSortView];
        _playOrderScrollView.contentSize = CGSizeMake(0, _playModeView.frame.size.height + _playSortView.frame.size.height);
    }
    return  _playOrderScrollView;
}
-(UIView*)playModeView
{
    if( !_playModeView )
    {
        float fwidth = 100;
        _playModeView = [[UIView alloc] initWithFrame:CGRectMake(0, fPlateIntervalI, _playOrderScrollView.frame.size.width, fPlateResolution)];
        
        UILabel *playModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 50, fPlateResolution)];
        playModeLabel.text = RDLocalizedString(@"播放模式", nil);
        playModeLabel.textAlignment = NSTextAlignmentCenter;
        if( iPhone4s )
            playModeLabel.font = [UIFont systemFontOfSize:11];
        else
            playModeLabel.font = [UIFont systemFontOfSize:12];
        playModeLabel.textColor = TEXT_COLOR;
        [_playModeView addSubview:playModeLabel];
        
        _playModeBtnVIew = [[UIScrollView alloc] initWithFrame:CGRectMake(playModeLabel.frame.origin.x + playModeLabel.frame.size.width + 30,  10, (_playModeView.frame.size.width - (playModeLabel.frame.origin.x + playModeLabel.frame.size.width) ), _playModeView.frame.size.height - 20)];
        [_playModeView addSubview:_playModeBtnVIew];
        
        simultaneouslyBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, fwidth, _playModeBtnVIew.frame.size.height)];
        [simultaneouslyBtn setTitle:RDLocalizedString(@"同时播放", nil) forState:UIControlStateNormal];
        [simultaneouslyBtn setTitleColor:TEXT_COLOR forState:UIControlStateNormal];
        [simultaneouslyBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        simultaneouslyBtn.layer.masksToBounds = YES;
        simultaneouslyBtn.layer.cornerRadius = simultaneouslyBtn.frame.size.height/2.0;
        simultaneouslyBtn.backgroundColor = UIColorFromRGB(0x333333);
        [simultaneouslyBtn addTarget:self action:@selector(playMode_type:) forControlEvents:UIControlEventTouchUpInside];
        simultaneouslyBtn.selected = YES;
        simultaneouslyBtn.tag = RDPlayModeType_Simultaneously;
        if( iPhone4s )
            simultaneouslyBtn.titleLabel.font = [UIFont systemFontOfSize:11];
        else
            simultaneouslyBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_playModeBtnVIew addSubview:simultaneouslyBtn];
        orderBtn = [[UIButton alloc] initWithFrame:CGRectMake(simultaneouslyBtn.frame.size.width + simultaneouslyBtn.frame.origin.x + 10, 0, fwidth, _playModeBtnVIew.frame.size.height)];
        [orderBtn setTitle:RDLocalizedString(@"顺序播放", nil) forState:UIControlStateNormal];
        [orderBtn setTitleColor:TEXT_COLOR forState:UIControlStateNormal];
        [orderBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        orderBtn.layer.masksToBounds = YES;
        orderBtn.layer.cornerRadius = simultaneouslyBtn.frame.size.height/2.0;
        orderBtn.backgroundColor = UIColorFromRGB(0x333333);
        orderBtn.tag = RDPlayModeType_Order;
        [orderBtn addTarget:self action:@selector(playMode_type:) forControlEvents:UIControlEventTouchUpInside];
        if( iPhone4s )
            orderBtn.font = [UIFont systemFontOfSize:11];
        else
            orderBtn.font = [UIFont systemFontOfSize:12];
        [_playModeBtnVIew addSubview:orderBtn];
        _playModeBtnVIew.contentSize = CGSizeMake(orderBtn.frame.size.width + simultaneouslyBtn.frame.size.width + simultaneouslyBtn.frame.origin.x + 20, 0);
    }
    return _playModeView;
}

//选中播放顺序的方式
-(void)playMode_type:(UIButton *) btn
{
    _playModeType = btn.tag;
    
    if( isAllImage )
        _playModeType = RDPlayModeType_Simultaneously;
    
    if( _videoCoreSDK )
        [self tit_Btn];
    
    switch (_playModeType) {
        case RDPlayModeType_Simultaneously:
            self.playSortThumbSliderView.hidden = YES;
            _playSortSimultaneouslyShowView.hidden = NO;
            _playSortPromptLabel.hidden = YES;
            break;
        default:
            self.playSortThumbSliderView.hidden = NO;
            _playSortSimultaneouslyShowView.hidden = YES;
            _playSortPromptLabel.hidden = NO;
            break;
    }
    
    [_playModeBtnVIew.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            if(obj.tag == _playModeType){
                obj.selected = YES;
            }else{
                obj.selected = NO;
            }
        }
    }];
}

-(UIView*)playSortView
{
    if( !_playSortView)
    {
        _playSortView = [[UIView alloc] initWithFrame:CGRectMake(0, _playModeView.frame.size.height + _playModeView.frame.origin.y, _playOrderScrollView.frame.size.width, fPlateStyleHeight)];
        
        _playSortLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 50, fPlateResolution)];
        _playSortLabel.text = RDLocalizedString(@"播放顺序", nil);
        _playSortLabel.textAlignment = NSTextAlignmentCenter;
        if( iPhone4s )
            _playSortLabel.font = [UIFont systemFontOfSize:11];
        else
            _playSortLabel.font = [UIFont systemFontOfSize:12];
        _playSortLabel.textColor = TEXT_COLOR;
        [_playSortView addSubview:_playSortLabel];
        _playSortPromptLabel = [[UILabel alloc] initWithFrame:CGRectMake(_playSortLabel.frame.origin.x + _playSortLabel.frame.size.width + 30, _playSortView.frame.size.height - 20 + 10, _playModeView.frame.size.width - (_playSortLabel.frame.origin.x + _playSortLabel.frame.size.width), 15)];
        _playSortPromptLabel.text = RDLocalizedString(@"长按调整播放先后", nil);
        _playSortPromptLabel.textAlignment = NSTextAlignmentLeft;
        if( iPhone4s )
            _playSortPromptLabel.font = [UIFont systemFontOfSize:11];
        else
            _playSortPromptLabel.font = [UIFont systemFontOfSize:12];
        _playSortPromptLabel.textColor = TEXT_COLOR;
        [_playSortView addSubview:_playSortPromptLabel];
        _playSortPromptLabel.hidden = YES;
        
        [self InitplaySortSimultaneouslyShowView];
        _playSortSimultaneouslyShowView.hidden = NO;
    }
    return _playSortView;
}

/**缩率图控件
 */
-(UIView *)playSortThumbSliderView
{
    if( !_playSortThumbSliderView )
    {
        self.playSortThumbSlider.hidden = NO;
    }
    return _playSortThumbSliderView;
}

- (UIScrollView *) playSortThumbSlider{
    if(!_playSortThumbSlider){
        
        if(_playSortThumbSliderView.superview)
            [_playSortThumbSliderView removeFromSuperview];
        if(_playSortThumbSliderback.superview)
            [_playSortThumbSliderback removeFromSuperview];
        
        _playSortThumbSliderback = nil;
        _playSortThumbSliderView= nil;
        
        _playSortThumbSliderView= [UIScrollView new];
        _playSortThumbSliderView.frame = CGRectMake(_playSortLabel.frame.origin.x + _playSortLabel.frame.size.width + 30,  5, (_playModeView.frame.size.width - (_playSortLabel.frame.origin.x + _playSortLabel.frame.size.width) ), _playSortView.frame.size.height - 15 );
        _playSortThumbSliderView.backgroundColor = [UIColor clearColor];
        
        [_playSortView addSubview:_playSortThumbSliderView];
        
        [_playSortThumbSliderback.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _playSortThumbSlider = [UIScrollView new];
        
        _playSortThumbSlider.frame = CGRectMake(0, 0 , _playSortThumbSliderView.frame.size.width, playSortThumbSlider_Height);
        _playSortThumbSlider.backgroundColor = [UIColor clearColor];
        
        float fwidth  = _multiDifferentFileList.count * playSortThumbSlider_Wdith + (_playSortThumbSlider.frame.size.height) * 2.0 + 20  - (playSortThumbSlider_Height + 10)*2.0   + (_playSortThumbSlider.frame.size.height*2.0/3.0) - _playSortThumbSlider.frame.size.height*1.0/3.0;
        if( fwidth <= kWIDTH )
            fwidth = kWIDTH + 10;
        
        _playSortThumbSlider.contentSize = CGSizeMake( fwidth, 0);
        _playSortThumbSlider.showsVerticalScrollIndicator = NO;
        _playSortThumbSlider.showsHorizontalScrollIndicator = NO;
        
        [_playSortThumbSliderView addSubview:_playSortThumbSlider];
        
        __weak typeof(self) myself = self;
        _playSortThumbSliderback = [UIView new];
        _playSortThumbSliderback.backgroundColor = [UIColor clearColor];
        _playSortThumbSliderback.frame = CGRectMake(0, 0, _multiDifferentFileList.count * playSortThumbSlider_Wdith + (_playSortThumbSlider.frame.size.height) * 2.0 + 20 , _playSortThumbSlider.frame.size.height);
        [_playSortThumbSlider addSubview:_playSortThumbSliderback];
        
        _playSortThumbSliderback.layer.masksToBounds = NO;
        [_playSortThumbSlider setCanCancelContentTouches:NO];
        [_playSortThumbSlider setClipsToBounds:NO];
        [_playSortThumbSliderback setClipsToBounds:NO];
        
        [thumbViewItems removeAllObjects];
        thumbViewItems = nil;
        thumbViewItems = [[NSMutableArray<RDThumbImageView *> alloc] init];
        
        __block int imageCount = 0;
        
        [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( obj.file.fileType == kFILEIMAGE && !obj.file.isGif)
            {
                imageCount++;
                return;
            }
            
            RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(_playSortThumbSlider.bounds.size.height, _playSortThumbSlider.bounds.size.height)];
            thumbView.backgroundColor = [UIColor clearColor];
            thumbView.frame = CGRectMake(playSortThumbSlider_Wdith*(idx-imageCount), 0, _playSortThumbSlider.bounds.size.height, _playSortThumbSlider.bounds.size.height);
            thumbView.home = thumbView.frame;
            thumbView.contentFile = obj.file;
            thumbView.transitionTypeName = obj.file.transitionTypeName;
            thumbView.transitionDuration = obj.file.transitionDuration;
            thumbView.transitionName = obj.file.transitionName;
            thumbView.transitionMask = obj.file.transitionMask;
            if(!obj.file.thumbImage){
                [myself performSelectorInBackground:@selector(refreshThumbImage:) withObject:thumbView];
            }else{
                thumbView.thumbIconView.image = obj.file.thumbImage;
            }
            thumbView.thumbId = (idx-imageCount);
            thumbView.tag = 100;
            thumbView.delegate = self;
            
            [thumbView AddtThumbIconViewSide];
            
            thumbView.thumbDeletedBtn.hidden = YES;
            thumbView.thumbDurationlabel.hidden = YES;
            
            [_playSortThumbSliderback insertSubview:thumbView atIndex:0];
            [thumbViewItems addObject:thumbView];
        }];
        
        //        if( imageCount >= (_multiDifferentFileList.count-1) )
        //            isAllImage = YES;
        //        else
        //            isAllImage = NO;
        
        _playSortThumbSlider.hidden = YES;
    }
    return _playSortThumbSlider;
}

- (void)refreshThumbImage:(RDThumbImageView *)tiv{
    RDFile *obj = _multiDifferentFileList[tiv.thumbId].file;
    obj.thumbImage = [RDHelpClass getThumbImageWithUrl:obj.contentURL];
    dispatch_async(dispatch_get_main_queue(), ^{
        tiv.thumbIconView.image = obj.thumbImage;
    });
}

#pragma mark- ThumbImageViewDelegate
- (void)thumbImageViewWasTapped:(RDThumbImageView *)tiv touchUpTiv:(BOOL)isTouchUpTiv{
    NSLog(@"%s",__func__);
    [_playSortThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDThumbImageView class]]){
            if(((RDThumbImageView *)obj).thumbId == selectFileIndex){
                [((RDThumbImageView *)obj) selectThumb:NO];
                //*stop = YES;
            }
        }
    }];
    selectFileIndex = tiv.thumbId;
    BOOL isLastFile = (_multiDifferentFileList.count - 1) == selectFileIndex;
    [tiv selectThumb:YES];
}


- (void)thumbImageViewWaslongLongTap:(RDThumbImageView *)tiv{
    [self.playSortThumbSliderback bringSubviewToFront:tiv];
    tiv.tap = NO;
    self.playSortThumbSlider.scrollEnabled = NO;
    if(_multiDifferentFileList.count <=1){
        return;
    }
    tiv.canMovePostion = YES;
    
    if(tiv.cancelMovePostion){
        tiv.canMovePostion = NO;
        
        return;
    }
    
    CGPoint touchLocation = tiv.center;
    CGFloat ofset_x = self.playSortThumbSlider.contentOffset.x;
    self.playSortThumbSliderback.frame = CGRectMake(self.playSortThumbSliderback.frame.origin.x, self.playSortThumbSliderback.frame.origin.y, _multiDifferentFileList.count * playSortThumbSlider_Wdith + 20 + playSortThumbSlider_Height + 10, self.playSortThumbSliderback.frame.size.height);
    [self.playSortThumbSlider setContentSize:CGSizeMake(self.playSortThumbSliderback.frame.size.width + 10, 20)];
#if 1
    NSMutableArray *arra = [self.playSortThumbSliderback.subviews mutableCopy];
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
        RDThumbImageView *prompView  = arra[i];
        if([prompView isKindOfClass:[RDThumbImageView class]]){
            [UIView animateWithDuration:0.15 animations:^{
                
                CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
                ((RDThumbImageView *)prompView).frame = CGRectMake(index * playSortThumbSlider_Wdith + 10, tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
                ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
                [((RDThumbImageView *)prompView) selectThumb:NO];
                if((RDThumbImageView *)prompView == tiv){
                    [((RDThumbImageView *)prompView) selectThumb:YES];
                    [self.playSortThumbSlider setContentOffset:CGPointMake( tiv.center.x - (touchLocation.x - ofset_x), 0)];
                }
                
            } completion:^(BOOL finished) {
                
            }];
            
            
            index ++;
        }
    }
}

- (void)thumbImageViewWaslongLongTapEnd:(RDThumbImageView *)tiv{
    
    tiv.canMovePostion = NO;
    if(_multiDifferentFileList.count <=1){
        return;
    }
    self.playSortThumbSlider.scrollEnabled = YES;
    
    CGPoint touchLocation = tiv.center;
    
    CGFloat ofSet_x = self.playSortThumbSlider.contentOffset.x;
    
    self.playSortThumbSliderback.frame = CGRectMake(0, 0, _multiDifferentFileList.count * (playSortThumbSlider_Wdith)+10 + playSortThumbSlider_Height + 10 + playSortThumbSlider_Wdith, self.playSortThumbSlider.frame.size.height);
    
    [self.playSortThumbSlider setContentSize:CGSizeMake(self.playSortThumbSliderback.frame.size.width + 10, 20)];
    
    NSMutableArray *arra = [self.playSortThumbSliderback.subviews mutableCopy];
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
        RDThumbImageView *prompView  = arra[i];
        if([prompView isKindOfClass:[RDThumbImageView class]]){
            CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
            ((RDThumbImageView *)prompView).frame = CGRectMake(index * playSortThumbSlider_Wdith , tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
            ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
            ((RDThumbImageView *)prompView).thumbId = index;
            if((RDThumbImageView *)prompView == tiv){
                selectFileIndex = index;
                [self.playSortThumbSlider setContentOffset:CGPointMake( touchLocation.x + playSortThumbSlider_Wdith < self.playSortThumbSlider.frame.size.width ? 0 : tiv.center.x - (touchLocation.x - ofSet_x), 0)];
            }
            RDFile *file = [((RDThumbImageView *)prompView).contentFile mutableCopy];
            
            [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if( prompView.contentFile == obj.file )
                {
                    RDMultiDifferentFile * oldFile = _multiDifferentFileList[i];
                    _multiDifferentFileList[i] = _multiDifferentFileList[idx];
                    _multiDifferentFileList[idx] = oldFile;
                }
            }];
            index ++;
        }
    }
    [self InitplaySortSimultaneouslyShowView];
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
    
    if (CGRectIntersectsRect([draggingThumb frame], [self.playSortThumbSliderback bounds]))
    {
        BOOL draggingRight = [draggingThumb frame].origin.x > [draggingThumb home].origin.x ? YES : NO;
        
        /* we're going to shift over all the thumbs who live between the home of the moving thumb */
        /* and the current touch location. A thumb counts as living in this area if the midpoint  */
        /* of its home is contained in the area.                                                  */
        NSMutableArray *thumbsToShift = [[NSMutableArray alloc] init];
        
        // get the touch location in the coordinate system of the scroll view
        CGPoint touchLocation = [draggingThumb convertPoint:[draggingThumb touchLocation] toView:self.playSortThumbSliderback];
        
        // calculate minimum and maximum boundaries of the affected area
        float minX = draggingRight ? CGRectGetMaxX([draggingThumb home]) : touchLocation.x;
        float maxX = draggingRight ? touchLocation.x : CGRectGetMinX([draggingThumb home]);
        
        // iterate through thumbnails and see which ones need to move over
        
        for (RDThumbImageView *thumb in [self.playSortThumbSliderback subviews])
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
    _autoscrollTimer = nil;}

- (void)thumbDeletedThumbFile:(RDThumbImageView *)tiv{
    
}


#pragma mark Autoscrolling methods

- (void)maybeAutoscrollForThumb:(RDThumbImageView *)thumb
{
    
    //return;
    _autoscrollDistance = 0;
    
    // only autoscroll if the thumb is overlapping the _libraryListScrollView
    if (CGRectIntersectsRect([thumb frame], self.playSortThumbSlider.bounds))
    {
        
        CGPoint touchLocation = [thumb convertPoint:[thumb touchLocation] toView:self.playSortThumbSlider];
        float distanceFromLeftEdge  = touchLocation.x - CGRectGetMinX(self.playSortThumbSlider.bounds);
        float distanceFromRightEdge = CGRectGetMaxX(self.playSortThumbSlider.bounds) - touchLocation.x;
        if (distanceFromLeftEdge < AUTOSCROLL_THRESHOLD)
        {
            
            if (_multiDifferentFileList.count>3) {
                _autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromLeftEdge] * -1; // if scrolling left, distance is negative
            }
        }
        else if (distanceFromRightEdge < AUTOSCROLL_THRESHOLD)
        {
            
            if (_multiDifferentFileList.count>3) {
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
    float minimumLegalDistance = [self.playSortThumbSlider contentOffset].x * -1;
    float maximumLegalDistance = [self.playSortThumbSlider contentSize].width - ([self.playSortThumbSlider frame].size.width
                                                                                 + [self.playSortThumbSlider contentOffset].x);
    _autoscrollDistance = MAX(_autoscrollDistance, minimumLegalDistance);
    _autoscrollDistance = MIN(_autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer
{
    //return;
    
    [self legalizeAutoscrollDistance];
    // autoscroll by changing content offset
    CGPoint contentOffset = [self.playSortThumbSlider contentOffset];
    contentOffset.x += _autoscrollDistance;
    [self.playSortThumbSlider setContentOffset:contentOffset];
    
    RDThumbImageView *thumb = (RDThumbImageView *)[timer userInfo];
    [thumb moveByOffset:CGPointMake(_autoscrollDistance, 0) withEvent:nil];
}

#pragma mark- 同时播放
-(void)InitplaySortSimultaneouslyShowView
{
    [_playSortSimultaneouslyShowView removeFromSuperview];
    _playSortSimultaneouslyShowView = nil;
    
    if( _videoCoreSDK )
        [self tit_Btn];
    
    _playSortSimultaneouslyShowView = [[UIView alloc] initWithFrame:CGRectMake(_playSortLabel.frame.origin.x + _playSortLabel.frame.size.width + 30, 0, playSortThumbSlider_Height, playSortThumbSlider_Height+5)];
    [_playSortView addSubview:_playSortSimultaneouslyShowView];
    
    if( _multiDifferentFileList.count > 1 )
    {
        UIImageView * imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _playSortSimultaneouslyShowView.frame.size.width - 5, _playSortSimultaneouslyShowView.frame.size.width - 5)];
        imageView1.layer.cornerRadius = 5;
        imageView1.layer.masksToBounds = YES;
        imageView1.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
        imageView1.layer.borderWidth  = 0.5;
        imageView1.image =  _multiDifferentFileList[1].file.thumbImage;
        [_playSortSimultaneouslyShowView addSubview:imageView1];
    }
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(((_multiDifferentFileList.count > 1)?5:0), ((_multiDifferentFileList.count > 1)?5:0), _playSortSimultaneouslyShowView.frame.size.width - 5, _playSortSimultaneouslyShowView.frame.size.width - 5)];
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
    imageView.layer.borderWidth  = 0.5;
    imageView.image =  _multiDifferentFileList[0].file.thumbImage;
    [_playSortSimultaneouslyShowView addSubview:imageView];
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(((_multiDifferentFileList.count > 1)?5:0), ((_multiDifferentFileList.count > 1)?5:0), _playSortSimultaneouslyShowView.frame.size.width - 5, _playSortSimultaneouslyShowView.frame.size.width - 5)];
    label.text = [NSString stringWithFormat:@"X%d",_multiDifferentFileList.count];
    label.textColor = UIColorFromRGB(0xffffff);
    label.textAlignment = NSTextAlignmentCenter;
    [_playSortSimultaneouslyShowView addSubview:label];
    _playSortSimultaneouslyShowView.hidden = YES;
}

#pragma mark- RDVECore
- (RDVECore *)videoCoreSDK {
    if (!_videoCoreSDK) {
        _exportVideoSize = selectVideoSize;
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_exportVideoSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
        _videoCoreSDK.frame = _playView.bounds;
        _videoCoreSDK.view.backgroundColor = [UIColor clearColor];
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.enableAudioEffect = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshVideoCoreSDK];
            if (!isExport) {
                [self playVideo:YES];
            }
        });
    }
    return _videoCoreSDK;
}

- (void)refreshVideoCoreSDK {
    _maxVideoDuration = 0.0;
    RDScene *scene = [[RDScene alloc] init];
    [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        switch ( _playModeType ) {
            case RDPlayModeType_Simultaneously:
            {
                float duration;
                if (obj.file.fileType == kFILEVIDEO) {
                    duration = CMTimeGetSeconds(obj.file.videoTrimTimeRange.duration);
                }else {
                    if (obj.file.isGif && CMTimeCompare(obj.file.imageTimeRange.duration, kCMTimeZero) == 1) {
                        duration = CMTimeGetSeconds(obj.file.imageTimeRange.duration);
                    }else {
                        duration = CMTimeGetSeconds(obj.file.imageDurationTime);
                    }
                }
                if( duration > _maxVideoDuration )
                {
                    _maxVideoDuration = duration;
                }
            }
                break;
            case RDPlayModeType_Order:
                if( obj.file.fileType == kFILEVIDEO )
                    _maxVideoDuration += CMTimeGetSeconds(obj.file.videoTrimTimeRange.duration);
                else if (obj.file.isGif) {
                    _maxVideoDuration += CMTimeGetSeconds(obj.file.imageTimeRange.duration);
                }
                break;
            default:
                break;
        }
    }];
    [self Order_Core:scene];
    NSLog(@"_maxVideoDuration:%f", _maxVideoDuration);
    [_videoCoreSDK setScenes:[NSMutableArray arrayWithObject:scene]];
//    if( !_musicView.hidden )
//        _videoCoreSDK.enableAudioEffect = YES;
//    else
//        _videoCoreSDK.enableAudioEffect = NO;
    [self refreshSound];
    
    [self setBackGroundColorWithRed];
}
//背景颜色回调
-( void )setBackGroundColorWithRed
{
    if(!videoBackgroundColor)
        return;
    CGFloat R, G, B, A;
    CGColorRef color = [videoBackgroundColor CGColor];
    
    int numComponents = CGColorGetNumberOfComponents(color);
    if (numComponents == 4)
    {
        const CGFloat *components = CGColorGetComponents(color);
        R = components[0];
        G = components[1];
        B = components[2];
        A = components[3];
    }
    
    [_videoCoreSDK setBackGroundColorWithRed:R
                                       Green:G
                                        Blue:B
                                       Alpha:A];
}
-(void)Order_Core:(RDScene *) scene
{
    NSMutableArray<NSNumber *> *timeArray = [[NSMutableArray alloc] init];
    if( _playModeType == RDPlayModeType_Order )
    {
        for (int i = 0; i < _multiDifferentFileList.count; i++) {
            
            float fTime = CMTimeGetSeconds(_multiDifferentFileList[i].file.videoTrimTimeRange.duration);
            if (_multiDifferentFileList[i].file.isGif) {
                fTime = CMTimeGetSeconds(_multiDifferentFileList[i].file.imageTimeRange.duration);
            }
            else if( _multiDifferentFileList[i].file.fileType == kFILEIMAGE )
                fTime = 0;
            
            if( timeArray.count > 0 )
                fTime += [timeArray[timeArray.count-1] floatValue];
            
            [timeArray addObject: [NSNumber numberWithFloat:fTime]];
            
        }
    }
    
    for (int i = 0; i < _multiDifferentFileList.count; i++) {
        RDMultiDifferentFile *videoMetadata = _multiDifferentFileList[i];
        NSURL *url = _fileList[ _multiDifferentFileList[i].number ].contentURL;
        VVAsset* vvAsset = [[VVAsset alloc] init];
        if (!url) {
            continue;
        }
        
        vvAsset.url = url;
        if( videoMetadata.file.fileType == kFILEVIDEO )
        {
            vvAsset.videoActualTimeRange = videoMetadata.file.videoActualTimeRange;
            vvAsset.type = RDAssetTypeVideo;
            vvAsset.videoFillType     = RDVideoFillTypeFit;
            if( _playModeType == RDPlayModeType_Order && i > 0)
            {
                vvAsset.startTimeInScene = CMTimeMakeWithSeconds([timeArray[i-1] floatValue], TIMESCALE);
            }
            vvAsset.timeRange =  videoMetadata.file.videoTrimTimeRange;
        }
        else
        {
            vvAsset.type = RDAssetTypeImage;
            vvAsset.fillType = RDImageFillTypeFit;
            if (videoMetadata.file.isGif) {
                if( _playModeType == RDPlayModeType_Order && i > 0)
                {
                    vvAsset.startTimeInScene = CMTimeMakeWithSeconds([timeArray[i-1] floatValue], TIMESCALE);
                }
                if (CMTimeCompare(videoMetadata.file.imageTimeRange.duration, kCMTimeZero) == 1) {
                    vvAsset.timeRange = videoMetadata.file.imageTimeRange;
                }else {
                    vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, videoMetadata.file.imageDurationTime);
                }
            }else {
                vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_maxVideoDuration, TIMESCALE));
            }
        }
        
        vvAsset.rotate = videoMetadata.file.rotate;
        vvAsset.speed        = videoMetadata.file.speed;
        vvAsset.volume       = videoMetadata.file.videoVolume;
        if(!self->yuanyinOn){
            vvAsset.volume = 0;
        }
        
        NSURL * maskURL = nil;
        bool isVideoMask = false;
        
        if( isMask )
        {
            isVideoMask = true;
            int number = videoMetadata.number+1;
            if( _multiDifferentFileList.count == 2 )
            {
                if( (CurrentPlateStyleIndex == 3) || (CurrentPlateStyleIndex == 4) )
                {
                   if( videoMetadata.rectInVideo.size.width <= 0.50 )
                        isVideoMask = false;
                }
            }
            if( isVideoMask )
                maskURL = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/Puzzle_Images/mix_%d/%d-%d-%d",_multiDifferentFileList.count, _multiDifferentFileList.count,CurrentPlateStyleIndex, number ] Type:@"jpg"]];
        }
        vvAsset.rectInVideo = videoMetadata.rectInVideo;
         NSLog(@"CoreSdk_rectInVideo:%.2f - %.2f - %.2f - %.2f\n",vvAsset.rectInVideo.origin.x,vvAsset.rectInVideo.origin.y,vvAsset.rectInVideo.size.width,vvAsset.rectInVideo.size.height);
        if( isVideoMask )
            vvAsset.maskURL = maskURL;
        vvAsset.crop = videoMetadata.crop;
        NSLog(@"CoreSdk_crop:%.2f - %.2f - %.2f - %.2f\n",vvAsset.crop.origin.x,vvAsset.crop.origin.y,vvAsset.crop.size.width,vvAsset.crop.size.height);
        [scene.vvAsset addObject:vvAsset];
        
        if(videoMetadata.file.fileType == kFILEVIDEO || videoMetadata.file.isGif)
        {
            if( _playModeType == RDPlayModeType_Order )
            {
                if( i > 0 )
                {
                    //开始
                    float duration = [timeArray[i-1] floatValue];//20170911
                    if (duration < _maxVideoDuration) {
                        UIImage *lastFrameImage;
                        if (videoMetadata.file.fileType == kFILEVIDEO) {
                            lastFrameImage = [RDHelpClass geScreenShotImageFromVideoURL:url atTime:videoMetadata.file.videoTrimTimeRange.start  atSearchDirection:false];
                        }else {
                            lastFrameImage = [UIImage getGifThumbImageWithData:videoMetadata.file.gifData time:CMTimeGetSeconds(videoMetadata.file.imageTimeRange.start)];
                        }
                        NSURL * lastFrameUrl = [RDHelpClass saveImage:url image:lastFrameImage atPosition:[NSString stringWithFormat:@"start-%d",i]];
                        VVAsset* vvAsset_lastFrame = [[VVAsset alloc] init];
                        vvAsset_lastFrame.url = lastFrameUrl;
                        vvAsset_lastFrame.type = RDAssetTypeImage;
                        vvAsset_lastFrame.volume = vvAsset.volume;
                        vvAsset_lastFrame.startTimeInScene = kCMTimeZero;
                        vvAsset_lastFrame.timeRange = CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds([timeArray[i-1] floatValue], TIMESCALE) );//20170911
                        vvAsset_lastFrame.rectInVideo = vvAsset.rectInVideo;
                        if( isVideoMask )
                           vvAsset_lastFrame.maskURL = maskURL;
                        vvAsset_lastFrame.crop = vvAsset.crop;
                        vvAsset_lastFrame.fillType = RDImageFillTypeFit;
                        vvAsset_lastFrame.rotate = vvAsset.rotate;
                        if (CMTimeCompare(vvAsset_lastFrame.timeRange.duration, kCMTimeZero) == 1) {
                            [scene.vvAsset addObject:vvAsset_lastFrame];
                        }
                    }
                }
                {
                    //结束
                    float duration = CMTimeGetSeconds(vvAsset.timeRange.duration);//20170911
                    if (duration < _maxVideoDuration) {
                        UIImage *lastFrameImage;
                        if (videoMetadata.file.fileType == kFILEVIDEO) {
                            lastFrameImage = [RDHelpClass getLastScreenShotImageFromVideoURL:url atTime:CMTimeAdd(videoMetadata.file.videoTrimTimeRange.start, videoMetadata.file.videoTrimTimeRange.duration)];
                        }else {
                            lastFrameImage = [UIImage getGifThumbImageWithData:videoMetadata.file.gifData time:CMTimeGetSeconds(CMTimeAdd(videoMetadata.file.imageTimeRange.start, videoMetadata.file.imageTimeRange.duration))];
                        }
                        NSURL * lastFrameUrl = [RDHelpClass saveImage:url image:lastFrameImage atPosition:[NSString stringWithFormat:@"end-%d",i]];
                        
                        VVAsset* vvAsset_lastFrame = [[VVAsset alloc] init];
                        vvAsset_lastFrame.url = lastFrameUrl;
                        vvAsset_lastFrame.type = RDAssetTypeImage;
                        vvAsset_lastFrame.volume = vvAsset.volume;
                        vvAsset_lastFrame.startTimeInScene = CMTimeAdd(vvAsset.startTimeInScene, vvAsset.timeRange.duration);
                        vvAsset_lastFrame.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(CMTimeMakeWithSeconds(_maxVideoDuration, TIMESCALE), vvAsset_lastFrame.startTimeInScene));//20170911
                        vvAsset_lastFrame.rectInVideo = vvAsset.rectInVideo;
                        if( isVideoMask )
                            vvAsset_lastFrame.maskURL = maskURL;
                        vvAsset_lastFrame.crop = vvAsset.crop;
                        vvAsset_lastFrame.fillType = RDImageFillTypeFit;
                        vvAsset_lastFrame.rotate = vvAsset.rotate;
                        if (CMTimeCompare(vvAsset_lastFrame.timeRange.duration, kCMTimeZero) == 1) {
                            [scene.vvAsset addObject:vvAsset_lastFrame];
                        }
                    }
                }
            }
            else
            {
                //根据项目需要，可将一个场景中时间短的媒体，补上最后一帧或其它媒体
                float duration = CMTimeGetSeconds(vvAsset.timeRange.duration);//20170911
                if (duration < _maxVideoDuration) {
                    UIImage *lastFrameImage;
                    if (videoMetadata.file.fileType == kFILEVIDEO) {
                        lastFrameImage = [RDHelpClass getLastScreenShotImageFromVideoURL:url atTime:CMTimeAdd(videoMetadata.file.videoTrimTimeRange.start, videoMetadata.file.videoTrimTimeRange.duration)];
                    }else {
                        lastFrameImage = [UIImage getGifThumbImageWithData:videoMetadata.file.gifData time:CMTimeGetSeconds(CMTimeAdd(videoMetadata.file.imageTimeRange.start, videoMetadata.file.imageTimeRange.duration))];
                    }
                    NSURL * lastFrameUrl = [RDHelpClass saveImage:url image:lastFrameImage];
                    
                    VVAsset* vvAsset_lastFrame = [[VVAsset alloc] init];
                    vvAsset_lastFrame.url = lastFrameUrl;
                    vvAsset_lastFrame.type = RDAssetTypeImage;
                    vvAsset_lastFrame.volume = vvAsset.volume;
                    vvAsset_lastFrame.startTimeInScene = vvAsset.timeRange.duration;
                    vvAsset_lastFrame.timeRange = CMTimeRangeMake(vvAsset.timeRange.duration, CMTimeSubtract(CMTimeMakeWithSeconds(_maxVideoDuration, TIMESCALE), vvAsset.timeRange.duration));//20170911
                    vvAsset_lastFrame.rectInVideo = vvAsset.rectInVideo;
                    if( isVideoMask )
                        vvAsset_lastFrame.maskURL = maskURL;
                    vvAsset_lastFrame.crop = vvAsset.crop;
                    vvAsset_lastFrame.fillType = RDImageFillTypeFit;
                    vvAsset_lastFrame.rotate = vvAsset.rotate;
                    if (CMTimeCompare(vvAsset_lastFrame.timeRange.duration, kCMTimeZero) == 1) {
                        [scene.vvAsset addObject:vvAsset_lastFrame];
                    }
                }
            }
        }
    }
}
#pragma mark - RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        if(sender == _videoCoreSDK){
            [RDSVProgressHUD dismiss];
            if( !isExport )
                _playView.hidden = NO;
            _durationLabel.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration];
            if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
                if( isExport )
                {
                    isExport = false;
                    [self publishBtnAction: publishBtn];
                }
                else
                    [self playVideo:YES];
            }else {
                if( isExport )
                {
                    isExport = false;
                    [self publishBtnAction: publishBtn];
                }else {
                    CMTime time = seekTime;
                    seekTime = kCMTimeZero;
                    __weak typeof(self) weakSelf = self;
                    [_videoCoreSDK seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                            [weakSelf playVideo:YES];
                    }];
                }
            }
        }
    }
}

/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    if([_videoCoreSDK isPlaying]){
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), _videoCoreSDK.duration)];
        float progress = CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration;
        [_videoProgressSlider setValue:progress];
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
    [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [_videoProgressSlider setValue:0];
    _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0];
    [self tit_Btn];
    [self playVideo:NO];
}

- (void)tapPlayerView{
    self.playButton.hidden = !self.playButton.hidden;
    _playerToolBar.hidden = self.playButton.hidden;
}

- (void)playerToolbarShow{
    _playerToolBar.hidden = NO;
    self.playButton.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}
- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        self.playButton.hidden = YES;
        _playerToolBar.hidden = YES;
    }];
}

#pragma mark- 播放器
- (void)playVideo:(BOOL)play{
    if(!play){
#if 1
        [_videoCoreSDK pause];
        titBtn.selected = NO;
#else
        if([_videoCoreSDK isPlaying]){//不加这个判断，否则疯狂切换音乐在低配机器上有可能反应不过来
            [_videoCoreSDK pause];
        }
#endif
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        _playButton.hidden = NO;
        
        [self playerToolbarShow];
    }else{
        if (_videoCoreSDK.status != kRDVECoreStatusReadyToPlay) {
            return;
        }
#if 1
        [_videoCoreSDK play];
#else
        if(![_videoCoreSDK isPlaying]){//不加这个判断，否则疯狂切换音乐在低配机器上有可能反应不过来
            [_videoCoreSDK play];
        }
#endif
        titBtn.selected = YES;
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
        _playButton.hidden = YES;
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
        [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
    }
}
-(UIView *) playView
{
    if( !_playView )
    {
        _playView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, templateView.frame.size.width, templateView.frame.size.height)];
        _playView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        
        [_playView addSubview:self.playVideoView];
        
        [_playView addSubview:self.playerToolBar];
        
        [_playVideoView addSubview:self.videoCoreSDK.view];
        [_playVideoView addSubview:self.playButton];
    }
    return _playView;
}

-(UIView *)playVideoView
{
    if( !_playVideoView )
    {
        _playVideoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _playView.frame.size.width, _playView.frame.size.height )];
    }
    return _playVideoView;
}

-(void)deletePlayView
{
    [_playButton  removeFromSuperview];
    _playButton = nil;
    [_durationLabel removeFromSuperview];
    _durationLabel = nil;
    
    [_currentTimeLabel removeFromSuperview];
    _currentTimeLabel = nil;
    
    [_videoProgressSlider removeFromSuperview];
    _videoProgressSlider = nil;
    
    [_playerToolBar removeFromSuperview];
    _playerToolBar = nil;
    
    [_playView removeFromSuperview];
    _playView = nil;
}
/**播放暂停按键
 */
- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton new];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake((_playVideoView.frame.size.width - 56)/2.0, (_playVideoView.frame.size.height - 56)/2.0, 56, 56);
        [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}
/**点击播放暂停按键
 */
- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
}
- (UIView *)playerToolBar{
    if(!_playerToolBar){
        _playerToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, _playView.frame.size.height - ( 44) ,_playView.frame.size.width, 44)];
        _playerToolBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        [_playerToolBar addSubview:self.currentTimeLabel];
        [_playerToolBar addSubview:self.durationLabel];
        [_playerToolBar addSubview:self.videoProgressSlider];
    }
    return _playerToolBar;
}

- (UILabel *)durationLabel{
    if(!_durationLabel){
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.frame = CGRectMake(_playerToolBar.frame.size.width - 65, (_playerToolBar.frame.size.height - 20)/2.0, 60, 20);
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
        _durationLabel.text = [RDHelpClass timeToStringFormat:0];
    }
    return _currentTimeLabel;
}

//进度条
- (RDZSlider *)videoProgressSlider{
    if(!_videoProgressSlider){
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(65, (_playerToolBar.frame.size.height - 30)/2.0, _playerToolBar.frame.size.width - 60 - 60 - 10, 30)];
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
    if(slider == _musicVolumeSlider)
    {
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        if (!_videoCoreSDK.isPlaying) {
            [self playVideo:YES];
        }
    }
    else if( slider == _originalVolumeSlider ){
        __block RDMultiDifferentFile * multiDifferentFile = nil;
        [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( self->currentIndex == obj.number )
                multiDifferentFile = obj;
        }];
        multiDifferentFile.file.videoVolume = _originalVolumeSlider.value*volumeMultipleM;
    }
    else if([_videoCoreSDK isPlaying])
        [self playVideo:NO];
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    if(slider == _musicVolumeSlider){
        _musicVolume = _musicVolumeSlider.value*volumeMultipleM;
        [_videoCoreSDK setVolume:_musicVolume identifier:@"music"];
    }
    else if( slider == _originalVolumeSlider ){
        __block RDMultiDifferentFile * multiDifferentFile = nil;
        [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( self->currentIndex == obj.number )
                multiDifferentFile = obj;
        }];
        multiDifferentFile.file.videoVolume = _originalVolumeSlider.value*volumeMultipleM;
    }else
    {
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
#if !ENABLEAUDIOEFFECT
        if([_videoCoreSDK isPlaying]){
            [self playVideo:NO];
        }
        [self refreshVideoCoreSDK];
#endif
    }
    else if( slider == _originalVolumeSlider ){
        __block RDMultiDifferentFile * multiDifferentFile = nil;
        [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( self->currentIndex == obj.number )
                multiDifferentFile = obj;
        }];
        multiDifferentFile.file.videoVolume = _originalVolumeSlider.value*volumeMultipleM;
    }else {
        CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    }
}

#pragma mark- 边框
-(UIView *) frameView
{
    if( !_frameView )
    {
        _frameView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _functionalView.frame.size.width, _functionalView.frame.size.height)];
        _frameView.backgroundColor = [UIColor clearColor];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, (_frameView.frame.size.height - 80)/2.0+5, 50, 20)];
        label.text = RDLocalizedString(@"粗细", nil);
        label.textAlignment = NSTextAlignmentCenter;
        if( iPhone4s )
            label.font = [UIFont systemFontOfSize:11];
        else
            label.font = [UIFont systemFontOfSize:12];
        label.textColor = TEXT_COLOR;
        [_frameView addSubview:label];
        
        [_frameView addSubview:self.frameSlider];
        
        _frameLabel = [[UILabel alloc] initWithFrame:CGRectMake(_frameSlider.frame.size.width + _frameSlider.frame.origin.x, (_frameView.frame.size.height - 80)/2.0+5, 50, 20)];
        _frameLabel.text = @"100";
        _frameLabel.textAlignment = NSTextAlignmentCenter;
        if( iPhone4s )
            _frameLabel.font = [UIFont systemFontOfSize:11];
        else
            _frameLabel.font = [UIFont systemFontOfSize:12];
        _frameLabel.textColor = TEXT_COLOR;
        [_frameView addSubview:_frameLabel];
        
        float space = (_frameView.frame.size.height - 30*3)/4.0;
        
        UILabel * label1 = [[UILabel alloc] initWithFrame:CGRectMake(20, _frameSlider.frame.size.height + _frameSlider.frame.origin.y + 10 + 5, 50, 20)];
        label1.text = RDLocalizedString(@"背景颜色", nil);
        label1.textAlignment = NSTextAlignmentCenter;
        if( iPhone4s )
            label1.font = [UIFont systemFontOfSize:11];
        else
            label1.font = [UIFont systemFontOfSize:12];
        label1.textColor = TEXT_COLOR;
        [_frameView addSubview:label1];
        colorControl = [[SubtitleColorControl alloc] initWithFrame:CGRectMake(70, _frameSlider.frame.size.height + _frameSlider.frame.origin.y + 15, _frameView.frame.size.width - 70 - 5, 20) Colors:self.colorArray CurrentColor:[UIColor whiteColor] atisDefault:FALSE];
        colorControl.delegate = self;
        [_frameView addSubview:colorControl];
    }
    return _frameView;
}

- (NSMutableArray *)colorArray {
    if (!_colorArray) {
        _colorArray = [NSMutableArray array];
        
        [_colorArray addObject:[UIColor clearColor]];
        [_colorArray addObject:UIColorFromRGB(0xffffff)];
        [_colorArray addObject:UIColorFromRGB(0xf9edb1)];
        [_colorArray addObject:UIColorFromRGB(0xffa078)];
        [_colorArray addObject:UIColorFromRGB(0xfe6c6c)];
        [_colorArray addObject:UIColorFromRGB(0xfe4241)];
        [_colorArray addObject:UIColorFromRGB(0x7cddfe)];
        [_colorArray addObject:UIColorFromRGB(0x41c5dc)];
        
        [_colorArray addObject:UIColorFromRGB(0x0695b5)];
        [_colorArray addObject:UIColorFromRGB(0x2791db)];
        [_colorArray addObject:UIColorFromRGB(0x0271fe)];
        [_colorArray addObject:UIColorFromRGB(0xdcffa3)];
        [_colorArray addObject:UIColorFromRGB(0xc7fe64)];
        [_colorArray addObject:UIColorFromRGB(0x82e23a)];
        [_colorArray addObject:UIColorFromRGB(0x25ba66)];
        [_colorArray addObject:UIColorFromRGB(0x017e54)];
        
        [_colorArray addObject:UIColorFromRGB(0xfdbacc)];
        [_colorArray addObject:UIColorFromRGB(0xff5a85)];
        [_colorArray addObject:UIColorFromRGB(0xff5ab0)];
        [_colorArray addObject:UIColorFromRGB(0xb92cec)];
        [_colorArray addObject:UIColorFromRGB(0x7e01ff)];
        [_colorArray addObject:UIColorFromRGB(0x848484)];
        [_colorArray addObject:UIColorFromRGB(0x88754d)];
        [_colorArray addObject:UIColorFromRGB(0x164c6e)];
    }
    return _colorArray;
}

//进度条
- (RDZSlider *)frameSlider{
    if(!_frameSlider){
        _frameSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50 + 20, (_frameView.frame.size.height - 80)/2.0, _frameView.frame.size.width - 50 - 20 - 50 - 20, 30)];
        _frameSlider.backgroundColor = [UIColor clearColor];
        [_frameSlider setMaximumValue:1];
        [_frameSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        _frameSlider.layer.cornerRadius = 2.0;
        _frameSlider.layer.masksToBounds = YES;
        image = [image imageWithTintColor];
        [_frameSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_frameSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_frameSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_frameSlider setValue:0];
        [_frameSlider addTarget:self action:@selector(frameBeginScrub:) forControlEvents:UIControlEventTouchDown];
        [_frameSlider addTarget:self action:@selector(frameScrub:) forControlEvents:UIControlEventValueChanged];
        [_frameSlider addTarget:self action:@selector(frameEndScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_frameSlider addTarget:self action:@selector(frameEndScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _frameSlider;
}
//MARK: 滑动进度条
/**开始滑动
 */
- (void)frameBeginScrub:(RDZSlider *)slider{
    int i = slider.value*100;
    if( _videoCoreSDK )
        [self tit_Btn];
    _frameLabel.text = [NSString stringWithFormat:@"%d", i  ];
    NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
    [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self adjCellFrame:obj];
    }];
}

/**正在滑动
 */
- (void)frameScrub:(RDZSlider *)slider{
    int i = slider.value*100;
    _frameLabel.text = [NSString stringWithFormat:@"%d", i ];
    NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
    [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self adjCellFrame:obj];
    }];
}
/**滑动结束
 */
- (void)frameEndScrub:(RDZSlider *)slider{
    int i = slider.value*100;
    _frameLabel.text = [NSString stringWithFormat:@"%d", i ];
    NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
    [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self adjCellFrame:obj];
    }];
}

-(void)adjCellFrame:(RDTemplateCollectionViewCell *) obj
{
    CGSize videoSize = obj.currentMultiDifferentFile.thumbnailImage.image.size;
    
    isMask = [self getMask];
    
    if( ( obj.currentMultiDifferentFile.file.rotate  == 90) || ( obj.currentMultiDifferentFile.file.rotate == 270) )
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    
    CGFloat width = templatePassthroughCollectionView.frame.size.width;
    CGFloat height = templatePassthroughCollectionView.frame.size.height;
    float borderWidth = _frameSlider.value * BorderWidth;
    
    width -= borderWidth;
    height-= borderWidth;
    if( isMask )
    {
        bool isEnter = true;
        if( _multiDifferentFileList.count == 2 )
        {
            if( CurrentPlateStyleIndex == 3 )
            {
                float fwidth = width * obj.originalRect.size.width - ((obj.originalRect.size.width == 1.0 )?borderWidth:(borderWidth*3.0/2.0) );
                float fheight = height * obj.originalRect.size.height - ((obj.originalRect.size.height == 1.0 )?borderWidth:(borderWidth*3.0/2.0) );
                obj.frame = CGRectMake(width * obj.originalRect.origin.x + borderWidth, height * obj.originalRect.origin.y + borderWidth, fwidth, fheight);
                
                isEnter = false;
            }
            else if( CurrentPlateStyleIndex == 4 )
            {
                float fwidth = width * obj.originalRect.size.width - ((obj.originalRect.size.width == 1.0 )?borderWidth:(borderWidth*3.0/2.0) );
                float fheight = height * obj.originalRect.size.height - ((obj.originalRect.size.height == 1.0 )?borderWidth:(borderWidth*3.0/2.0) );
                obj.frame = CGRectMake(width * obj.originalRect.origin.x + borderWidth
                                       + ((obj.originalRect.size.width == 1.0 )?0:(borderWidth/2.0) ),
                                       height * obj.originalRect.origin.y + borderWidth
                                       + ((obj.originalRect.size.height == 1.0 )?0:(borderWidth/2.0)),
                                       fwidth,
                                       fheight);
                isEnter = false;
            }
        }
        if( isEnter )
        {
            float fwidth = width * obj.originalRect.size.width - (((obj.originalRect.size.width+obj.originalRect.origin.x) == 1.0 )?borderWidth:(borderWidth*3.0/2.0) );
            float fheight = height * obj.originalRect.size.height - (((obj.originalRect.size.height+obj.originalRect.origin.y) == 1.0 )?borderWidth:(borderWidth*3.0/2.0) );
            obj.frame = CGRectMake(width * obj.originalRect.origin.x + borderWidth, height * obj.originalRect.origin.y + borderWidth, fwidth, fheight);
        }
    }
    else
        obj.frame = CGRectMake(width * obj.originalRect.origin.x + borderWidth, height * obj.originalRect.origin.y + borderWidth, width * obj.originalRect.size.width - borderWidth, height * obj.originalRect.size.height - borderWidth);
    
    [self SetImage:obj Rect:obj.frame videoSize:videoSize];
    [obj setImageScale];
    
    [self Mask_points:obj atIndex:obj.currentMultiDifferentFile.number atBorderWidth:borderWidth atWidth:(float)obj.frame.size.width atWidth:(float)obj.frame.size.height];
    [obj adjSelectImage:obj.frame.size];
}

-(bool)getMask
{
    bool isEnter = false;
    if( _multiDifferentFileList.count == 2 )
    {
        if( CurrentPlateStyleIndex == 5 )
            isEnter = true;
        else if( CurrentPlateStyleIndex == 6 )
            isEnter = true;
        else if( CurrentPlateStyleIndex == 3 )
            isEnter = true;
        else if( CurrentPlateStyleIndex == 4 )
            isEnter = true;
    }
    else if(  _multiDifferentFileList.count == 3  )
    {
        if( CurrentPlateStyleIndex == 5 )
            isEnter = true;
        else if( CurrentPlateStyleIndex == 6 )
            isEnter = true;
    }
    return isEnter;
}


#pragma mark- 异形调整
-( void )Mask_points:(RDTemplateCollectionViewCell *) obj atIndex:(int ) row atBorderWidth:(float) borderWidth
atWidth:(float) Width atWidth:(float) height
{
    NSMutableArray *trackPoints = [NSMutableArray array];
    
    NSMutableArray *  maskDictionary = [RDCustomSizeLayout maskDictionary:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/Puzzle_Images/mix_%d/%d-%d",_multiDifferentFileList.count, _multiDifferentFileList.count,CurrentPlateStyleIndex] Type:@"json"] ];
    
    if( _multiDifferentFileList.count == 2 )
    {
        NSMutableArray * mask = [maskDictionary[row] objectForKey:@"pointF"];
        if( CurrentPlateStyleIndex == 5 )
        {
            for (int i = 0; 4 > i; i++) {
                [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake([[mask[i] objectForKey:@"x"] floatValue], [[mask[i] objectForKey:@"y"] floatValue] )]];
            }
        }
        else if( CurrentPlateStyleIndex == 6 ){
            for (int i = 0; 4 > i; i++) {
                [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake([[mask[i] objectForKey:@"x"] floatValue], [[mask[i] objectForKey:@"y"] floatValue] )]];
            }
        }
        else if( CurrentPlateStyleIndex == 3 )
        {
            switch ( row ) {
                case 0:
                    for (int i = 0; 6 > i; i++) {
                        [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake([[mask[i] objectForKey:@"x"] floatValue], [[mask[i] objectForKey:@"y"] floatValue] )]];
                    }
                    break;
                case 1:
                {
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(0, 0)]];
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(1, 0)]];
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(1, 1)]];
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(0, 1)]];
                }
                    break;
                default:
                    break;
            }
        }
        else if( CurrentPlateStyleIndex == 4 )
        {
            switch ( row ) {
                case 0:
                    for (int i = 0; 6 > i; i++) {
                        [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake([[mask[i] objectForKey:@"x"] floatValue], [[mask[i] objectForKey:@"y"] floatValue] )]];
                    }
                    break;
                case 1:
                {
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(0, 0)]];
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(1, 0)]];
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(1, 1)]];
                    [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake(0, 1)]];
                }
                    break;
                default:
                    break;
            }
        }
    }
    else if(  _multiDifferentFileList.count == 3  )
    {
        NSMutableArray * mask = [maskDictionary[row] objectForKey:@"pointF"];
        if( CurrentPlateStyleIndex == 5 )
        {
            for (int i = 0; 4 > i; i++) {
                [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake([[mask[i] objectForKey:@"x"] floatValue], [[mask[i] objectForKey:@"y"] floatValue] )]];
            }
        }
        else if( CurrentPlateStyleIndex == 6 )
        {
            for (int i = 0; 4 > i; i++) {
                [trackPoints addObject:[NSValue valueWithCGPoint:CGPointMake([[mask[i] objectForKey:@"x"] floatValue], [[mask[i] objectForKey:@"y"] floatValue] )]];
            }
        }
    }
    
    if( trackPoints.count > 0 )
    {
//        obj.currentMultiDifferentFile.pointsInVideoArray = trackPoints;
        for ( int i = 0 ;  trackPoints.count > i ; i++) {
            CGPoint point =  [[trackPoints objectAtIndex:i] CGPointValue];
            trackPoints[ i ] = [NSValue valueWithCGPoint:CGPointMake( point.x * Width , point.y * height)];
        }
        obj.trackPoints = trackPoints;
        [obj setMask];
    }
}


//选中 操作界面
-(UIView *)selectView
{
    if( !_selectView )
    {
        _selectView = [[UIView alloc] initWithFrame:CGRectMake(0, templateView.frame.origin.y + templateView.frame.size.height, kWIDTH, kHEIGHT - templateView.frame.origin.y - templateView.frame.size.height)];
        _selectView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [self.view addSubview:_selectView];
        [_selectView addSubview:self.closeBtn];
        [_selectView addSubview:self.selectFunctionalAreaView];
        _selectView.hidden = YES;
    }
    return _selectView;
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
    NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
    [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj noSelect];
    }];
    templatePassthroughCollectionView.backgroundColor = videoBackgroundColor;
    currentIndex = -1;
    currentIndexPath = nil;
    _selectView.hidden = YES;
}
-(UIView *) selectFunctionalAreaView
{
    if( !_selectFunctionalAreaView )
    {
        _selectFunctionalAreaView = [[UIView alloc] initWithFrame:CGRectMake(0, _closeBtn.frame.size.height + _closeBtn.frame.origin.y, _selectView.frame.size.width, _selectView.frame.size.height - _closeBtn.frame.size.height - _closeBtn.frame.origin.y)];
        [_selectFunctionalAreaView addSubview:self.selectScrollFunctionalAreaView];
    }
    return _selectFunctionalAreaView;
}
-(UIScrollView *)selectScrollFunctionalAreaView
{
    if( !_selectScrollFunctionalAreaView )
    {
        [self initToolItem];
    }
    return _selectScrollFunctionalAreaView;
}
-(void)initToolItem
{
    __block RDMultiDifferentFile * multiDifferentFile = nil;
    [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( self->currentIndex == obj.number )
            multiDifferentFile = obj;
    }];
    
    _volumeView.hidden = YES;
    
    [_selectScrollFunctionalAreaView removeFromSuperview];
    _selectScrollFunctionalAreaView = nil;
    _selectScrollFunctionalAreaView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _selectFunctionalAreaView.frame.size.width, _selectFunctionalAreaView.frame.size.height)];
    _selectScrollFunctionalAreaView.showsVerticalScrollIndicator = NO;
    _selectScrollFunctionalAreaView.showsHorizontalScrollIndicator = NO;
    NSMutableArray * toolItem = [NSMutableArray array];
    if(multiDifferentFile.file.fileType ==  kFILEVIDEO )
    {
        NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"音量",@"title",@(1),@"id", nil];
        [toolItem addObject:dic1];
    }
    NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"旋转",@"title",@(2),@"id", nil];
    [toolItem addObject:dic4];
    if( multiDifferentFile.file.fileType ==  kFILEVIDEO || multiDifferentFile.file.isGif)
    {
        NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"时长截取",@"title",@(3),@"id", nil];
        [toolItem addObject:dic3];
    }
    NSDictionary *dic5 = [[NSDictionary alloc] initWithObjectsAndKeys:@"替换",@"title",@(4),@"id", nil];
    [toolItem addObject:dic5];
    //    NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"删除",@"title",@(5),@"id", nil];
    //    [toolItem addObject:dic2];
    
    __block float toolItemBtnWidth = MAX(kWIDTH/toolItem.count, 60 + 5);//_toolBarView.frame.size.height
    __block float contentsWidth = 0;
    [toolItem enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = [toolItem[idx] objectForKey:@"title"];
        UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolItemBtn.tag = [[toolItem[idx] objectForKey:@"id"] integerValue];
        
        toolItemBtn.backgroundColor = [UIColor clearColor];
        toolItemBtn.exclusiveTouch = YES;
        toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, (_selectScrollFunctionalAreaView.frame.size.height - 60)/2.0  , toolItemBtnWidth, 60);
        [toolItemBtn addTarget:self action:@selector(clickToolFunctionalArea:) forControlEvents:UIControlEventTouchUpInside];
        NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/%@-默认_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/%@-选中_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
        [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
        [_selectScrollFunctionalAreaView addSubview:toolItemBtn];
        
        if( toolItemBtn.tag == 1 )
        {
            if( multiDifferentFile.file.videoVolume == 0.0 )
                toolItemBtn.selected = YES;
            else
                toolItemBtn.selected = NO;
        }
        
        contentsWidth += toolItemBtnWidth;
    }];
    if( contentsWidth <= kWIDTH )
        contentsWidth = kWIDTH + 10;
    _selectScrollFunctionalAreaView.contentSize = CGSizeMake(contentsWidth, 0);
    [_selectFunctionalAreaView addSubview:_selectScrollFunctionalAreaView];
}
/**功能选择
 */
- (void)clickToolFunctionalArea:(UIButton *)sender{
    
    __block RDMultiDifferentFile * multiDifferentFile = nil;
    [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( self->currentIndex == obj.number )
            multiDifferentFile = obj;
    }];
    switch ( sender.tag ) {
        case 1: //音量
        {
            self.volumeView.hidden = NO;
            _selectScrollFunctionalAreaView.hidden = YES;
            [_originalVolumeSlider setValue:multiDifferentFile.file.videoVolume/volumeMultipleM ];
            oldVolume = multiDifferentFile.file.videoVolume;
//            if( multiDifferentFile.file.videoVolume == 0.0 )
//            {
//                multiDifferentFile.file.videoVolume = 1.0;
//                sender.selected = NO;
//            }
//            else
//            {
//                multiDifferentFile.file.videoVolume = 0.0;
//                sender.selected = YES;;
//            }
        }
            break;
        case 2: //旋转
            [self setRotate];
            break;
        case 3: //时长截取
            [self trimVideo];
            break;
        case 4: //替换
            [self mainView];
            break;
        case 5: //删除
        {
            
        }
            break;
        default:
            break;
    }
}
#pragma mark- 时长截取
-(void)trimVideo
{
    __block RDMultiDifferentFile * multiDifferentFile = nil;
    [_multiDifferentFileList enumerateObjectsUsingBlock:^(RDMultiDifferentFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( self->currentIndex == obj.number )
            multiDifferentFile = obj;
    }];
    RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
    trimVideoVC.isRotateEnable = NO;
    trimVideoVC.isAdjustVolumeEnable = NO;
    trimVideoVC.trimFile = [multiDifferentFile.file copy];
    trimVideoVC.trimFile.rotate =  trimVideoVC.trimFile.rotate - 360;
    trimVideoVC.trimFile.crop = CGRectMake(0, 0, 1, 1);
    trimVideoVC.TrimAndRotateVideoFinishBlock = ^(float rotate, CMTimeRange timeRange) {
        RDFile * file = multiDifferentFile.file;
        UIImage *image = nil;
        if (file.isGif) {
            file.imageTimeRange = timeRange;
            _fileList[ multiDifferentFile.number ].imageTimeRange = timeRange;
            image = [UIImage getGifThumbImageWithData:file.gifData time:CMTimeGetSeconds(timeRange.start)];
        }else {
            file.videoTrimTimeRange = timeRange;
            _fileList[ multiDifferentFile.number ].videoTrimTimeRange = timeRange;
            if( file.fileType == kFILEVIDEO )
                image = [RDHelpClass geScreenShotImageFromVideoURL:file.contentURL atTime:file.videoTrimTimeRange.start  atSearchDirection:false];
            else
                image = [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
        }
        
        multiDifferentFile.thumbnailImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        multiDifferentFile.thumbnailImage.image = image;
        
        file.rotate = rotate;
        _fileList[ multiDifferentFile.number].rotate = rotate;
        _fileList[ multiDifferentFile.number ].thumbImage = file.thumbImage;
        
        RDTemplateCollectionViewCell *currCell = (RDTemplateCollectionViewCell *)[templatePassthroughCollectionView cellForItemAtIndexPath:currentIndexPath];
        currCell.thumbnailIV.image = multiDifferentFile.thumbnailImage.image;
    };
    RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    [self presentViewController:nav animated:YES completion:nil];
}
#pragma mark- 替换
-(void)mainView
{
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
        RDFile *file = [filelist firstObject];
        
        for (int i = 0; i < _multiDifferentFileList.count; i++) {
            if( _multiDifferentFileList[i].number == currentIndex )
            {
                _multiDifferentFileList[i].file = nil;
                _multiDifferentFileList[i].file = file;
                
                if(_multiDifferentFileList[i].file.rotate != 0  )
                {
                    RDTemplateCollectionViewCell *currCell = (RDTemplateCollectionViewCell *)[templatePassthroughCollectionView cellForItemAtIndexPath:currentIndexPath];
                    [currCell setImageViewRotate:( 360 - (_multiDifferentFileList[i].file.rotate+360) )];
                    currCell.currentMultiDifferentFile.isChangedCrop = NO;
                    [self adjCellFrame:currCell];
                }
                UIImage *image = nil;
                if( file.fileType == kFILEVIDEO )
                    image = [RDHelpClass geScreenShotImageFromVideoURL:file.contentURL atTime:file.videoTrimTimeRange.start  atSearchDirection:false];
                else
                    image = [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
                
                _multiDifferentFileList[i].thumbnailImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
                _multiDifferentFileList[i].thumbnailImage.image = image;
                
                [_fileList replaceObjectAtIndex:_multiDifferentFileList[i].number withObject:file];
                break;
            }
        }
        
        [self adjPassthroughCollectionView];
//        [self initTemplatePassthroughCollectionView];
//        currentIndex  = -1;
//        currentIndexPath = nil;
//        self.selectView.hidden = YES;
//        [_playSortThumbSlider removeFromSuperview];
//        _playSortThumbSlider = nil;
//
//        __block int imageCount = 0;
//        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            if( obj.fileType == kFILEIMAGE )
//                imageCount++;
//        }];
//        if( imageCount >= (_multiDifferentFileList.count-1) )
//            isAllImage = YES;
//        else
//            isAllImage = NO;
//
//        if( _playModeType == RDPlayModeType_Order )
//        {
//            if( !isAllImage )
//                self.playSortThumbSlider.hidden = NO;
//            else
//            {
//                self.playSortThumbSlider.hidden = YES;
//                [self playMode_type:simultaneouslyBtn];
//            }
//        }
//        else
//        {
//            self.playSortThumbSlider.hidden = NO;
//            [self playMode_type:simultaneouslyBtn];
//        }
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    nav.editConfiguration.mediaCountLimit =  1;
    [self presentViewController:nav animated:YES completion:nil];
}
#pragma mark- 旋转
-(void)setRotate
{
    currentRotateGrade++;
    if( currentRotateGrade > 3 )
        currentRotateGrade = 0;
    float fRotate = currentRotateGrade * 90;
    NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
    [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( obj.currentMultiDifferentFile.number == currentIndex )
        {
            [obj setImageViewRotate:fRotate];
            obj.currentMultiDifferentFile.isChangedCrop = NO;
            [self adjCellFrame:obj];
        }
    }];
}
#pragma mark- 音乐
-(UIScrollView*)musicScrollView
{
    if( !_musicScrollView )
    {
        _musicScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _functionalView.frame.size.width, _functionalView.frame.size.height)];
        self.musicView.hidden = NO;
        _musicScrollView.contentSize = CGSizeMake(_functionalView.frame.size.width, _musicView.frame.size.height);
    }
    return _musicScrollView;
}
- (UIView *)musicView{
    if(!_musicView){
        _musicView = [UIView new];
        
        if( _musicScrollView.frame.size.height < (fPlateStyleHeight+fPlateResolution) )
            _musicView.frame = CGRectMake(0, 0, _functionalView.frame.size.width, fPlateStyleHeight+fPlateResolution);
        else
            _musicView.frame = CGRectMake(0, 0, _functionalView.frame.size.width, _musicScrollView.frame.size.height);
        _musicView.backgroundColor = BOTTOM_COLOR;
        [_musicScrollView addSubview:_musicView];
        
        _musicVolumeLabel = [UILabel new];
        _musicVolumeLabel.frame = CGRectMake(0, (kWIDTH>320 ? 0 : 5), 50, 30);
        _musicVolumeLabel.textAlignment = NSTextAlignmentCenter;
        _musicVolumeLabel.backgroundColor = [UIColor clearColor];
        _musicVolumeLabel.font = [UIFont boldSystemFontOfSize:12];
        _musicVolumeLabel.textColor = [UIColor whiteColor];
        _musicVolumeLabel.text = RDLocalizedString(@"配乐", nil);
        
//        _videoVolumelabel = [UILabel new];
//        _videoVolumelabel.frame = CGRectMake(_musicView.frame.size.width - 50, (kWIDTH>320 ? 10 : 5), 50, 31);
//        _videoVolumelabel.textAlignment = NSTextAlignmentCenter;
//        _videoVolumelabel.backgroundColor = [UIColor clearColor];
//        _videoVolumelabel.font = [UIFont boldSystemFontOfSize:12];
//        _videoVolumelabel.textColor = [UIColor whiteColor];
//        _videoVolumelabel.text = RDLocalizedString(@"原音", nil);
        
        [_musicView addSubview:self.musicVolumeLabel];
//        [_musicView addSubview:self.videoVolumelabel];
        [_musicView addSubview:self.musicVolumeSlider];
        
        [_musicView addSubview: self.musicChildsView];
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDubbing && ((RDNavigationViewController *)self.navigationController).editConfiguration.dubbingType == 1){
            _dubbingItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            _dubbingItemBtn.frame = CGRectMake(5 , (kWIDTH>320 ? 0 : 5), 55, 30);
            //            [_dubbingItemBtn addTarget:self action:@selector(clickDubbingItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            _dubbingItemBtn.layer.cornerRadius = 15.0;
            _dubbingItemBtn.layer.masksToBounds = YES;
            _dubbingItemBtn.titleLabel.font = [UIFont systemFontOfSize:17];
            _dubbingItemBtn.backgroundColor = Main_Color;
            [_dubbingItemBtn setTitle:RDLocalizedString(@"配音", nil) forState:UIControlStateNormal];
            [_dubbingItemBtn setTitle:RDLocalizedString(@"配音", nil) forState:UIControlStateHighlighted];
            [_dubbingItemBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
            [_dubbingItemBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateHighlighted];
            
            _musicVolumeLabel.frame = CGRectMake(60, (kWIDTH>320 ? 0 : 5), 50, 30);
            self.musicVolumeSlider.frame = CGRectMake(50 + 60, (kWIDTH>320 ? 0 : 5), kWIDTH - 100 - 60, 30);
            
            [_musicView addSubview:_dubbingItemBtn];
        }
        _musicView.hidden = YES;
    }
    return _musicView;
}

//配乐音量比例调节
- (RDZSlider *)musicVolumeSlider{
    if(!_musicVolumeSlider){
        _musicVolumeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(50, (kWIDTH>320 ? 0 : 5), kWIDTH - 80, 30)];
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
        float height = (iPhone4s ? 60 : (kWIDTH>320 ? 80 : 65));
        _musicChildsView = [UIScrollView new];
        _musicChildsView.frame = CGRectMake(0, (kWIDTH>320 ? 30 : 35) + (_musicView.frame.size.height - (kWIDTH>320 ? 30 : 35) - height)/2.0, _musicView.frame.size.width, height);
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
#pragma mark- scrollViewChildItemDelegate  水印 配乐 变声 滤镜
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item{
    __weak typeof(self) myself = self;
    if(item.type == 1){//MARK:配乐
        dispatch_async(dispatch_get_main_queue(), ^{
            [RDSVProgressHUD dismiss];
            [mvMusicArray removeAllObjects];
            mvMusicArray = nil;
#if !ENABLEAUDIOEFFECT
            if([_videoCoreSDK isPlaying]){
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
                            [myself.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                            [myself.hud show];
                            [myself.hud hideAfter:2];
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
                        [myself.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                        [myself.hud show];
                        [myself.hud hideAfter:2];
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
                        if (!_videoCoreSDK.isPlaying) {
                            [self playVideo:YES];
                        }
#else
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self refreshVideoCoreSDK];
                            [myself playVideo:YES];
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
                        if (!_videoCoreSDK.isPlaying) {
                            [self playVideo:YES];
                        }
#else
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [RDSVProgressHUD dismiss];
                            [self refreshVideoCoreSDK];
                            [myself playVideo:YES];
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
}
#pragma mark- 云音乐
- (void)enter_cloudMusic:(ScrollViewChildItem *)item{
    if(_videoCoreSDK.isPlaying){
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
            [self refreshVideoCoreSDK];
//            [myself playVideo:YES];
        });
    };
    [self.navigationController pushViewController:cloudMusic animated:YES];
}
#pragma mark-本地音乐
- (void)enter_localMusic:(ScrollViewChildItem *)item{
    if(_videoCoreSDK.isPlaying){
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
            [self refreshVideoCoreSDK];
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

//更新音乐
- (void)refreshSound {
    [_videoCoreSDK stop];//20181105 fix bug:不断切换mv、配乐会因内存问题崩溃
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    [self performSelector:@selector(refreshMusicOrDubbing) withObject:nil afterDelay:0.1];
}
- (void)refreshMusicOrDubbing {
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.identifier = @"music";
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.isFadeInOut = YES;
        music.volume = _musicVolume;
        if (mvMusicArray) {
            [mvMusicArray addObject:music];
            [_videoCoreSDK setMusics:mvMusicArray];
        }else{
            [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
        }
    }
    else{
        [_videoCoreSDK setMusics:nil];
    }
    
    [_videoCoreSDK build];
    [RDSVProgressHUD dismiss];
}

#pragma mark0- 导出视频
- (void)exportMovie{
    
    isContinueExport = NO;
    
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
    //    [self refreshWatermarkArrayWithIsExport:NO];
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
    
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
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
    //    [self refreshWatermarkArrayWithIsExport:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
}
#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 103:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
        case 101:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [self cancelExportBlock];
                [_videoCoreSDK cancelExportMovie:nil];
            }
            break;
        default:
            break;
            
    };
    
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


#pragma mark- RDTemplateCollectionViewCellDelegate
- (void)longPressAction:(UIPanGestureRecognizer *)longPress {
    //获取此次点击的坐标，根据坐标获取cell对应的indexPath
    CGPoint point = [longPress locationInView:templatePassthroughCollectionView];
    __block NSIndexPath *indexPath = [templatePassthroughCollectionView indexPathForItemAtPoint:point];
    
    if( templatePassthroughCollectionView.isMask )
    {
        indexPath = nil;
        __block RDTemplateCollectionViewCell *cell;
        __block CGPoint childPoint;
        [templatePassthroughCollectionView.subviews enumerateObjectsUsingBlock:^(__kindof RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 把当前控件上的坐标系转换成子控件上的坐标系
            childPoint = [templatePassthroughCollectionView convertPoint:point toView:obj];
            if ([obj isKindOfClass:[RDTemplateCollectionViewCell class]] && [obj.path containsPoint:childPoint]) {
                cell = obj;
                *stop = YES;
            }
        }];
        if (cell) {
            indexPath = [templatePassthroughCollectionView indexPathForCell:cell];
        }
    }
    
    //根据长按手势的状态进行处理。
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
        {
            //当没有点击到cell的时候不进行处理
            if (!indexPath) {
                break;
            }
            currentSelectCell = indexPath;
            NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
            [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSIndexPath * cureetnIndex = [templatePassthroughCollectionView indexPathForCell:obj];
                if( cureetnIndex.row == indexPath.row)
                {
                    currentSelectFileNumber = obj.currentMultiDifferentFile.number;
                }
            }];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
//            if (!indexPath) {
//                break;
//            }
            NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
            __block UIImage * image = nil;
            [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSIndexPath * cureetnIndex = [templatePassthroughCollectionView indexPathForCell:obj];
                if( indexPath.row != currentSelectCell.row )
                {
                    if( cureetnIndex.row == indexPath.row)
                    {
                        [obj setSelect:YES];
                    }
                    else
                        [obj noSelect];
                    
                    if(  cureetnIndex.row == currentSelectCell.row )
                    {
                        image = obj.thumbnailIV.image;
                        obj.thumbnailIV.hidden = YES;
                    }
                }
                else{
                    obj.thumbnailIV.hidden = NO;
                    [obj noSelect];
                }
                
            }];
            if( (indexPath.row != currentSelectCell.row)  && (indexPath != nil)  )
            {
                CGSize size = image.size;
                
                float width = templatePassthroughCollectionView.frame.size.width/3.0;
                float height = width*( size.height/size.width );
                if( !currentCellImage )
                {
                    currentCellImage = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - width/2.0, point.y - height/2.0, width, height)];
                    currentCellImage.image = [RDMultiDifferentViewController image:image setAlpha:0.5];
                    currentCellImage.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
                    [templatePassthroughCollectionView addSubview:currentCellImage];
                }
            }
            else{
                if( ( indexPath != nil ) && currentCellImage )
                {
                    currentCellImage.image = nil;
                    [currentCellImage removeFromSuperview];
                    currentCellImage = nil;
                }
            }
            
            if( currentCellImage )
                currentCellImage.frame = CGRectMake(point.x - currentCellImage.frame.size.width/2.0, point.y - currentCellImage.frame.size.height/2.0, currentCellImage.frame.size.width, currentCellImage.frame.size.height);
            
            if( indexPath == nil )
            {
                NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
                [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj noSelect];
                }];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
            //停止移动调用此方法
        {
            if( !currentSelectCell )
                return;
            
            if( currentCellImage )
            {
                currentCellImage.image = nil;
                [currentCellImage removeFromSuperview];
                currentCellImage = nil;
            }
            
//            if (!indexPath) {
//                break;
//            }
            
            if( (indexPath.row != currentSelectCell.row) && (indexPath != nil) )
            {
                __block int index;
                __block RDTemplateCollectionViewCell * currentCell = nil;
                __block RDTemplateCollectionViewCell * lastCell = nil;
                NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
                [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSIndexPath * cureetnIndex = [templatePassthroughCollectionView indexPathForCell:obj];
                    if( cureetnIndex.row == indexPath.row)
                    {
                        index = obj.currentMultiDifferentFile.number;
                        lastCell = obj;
                    }
                    else if( cureetnIndex.row == currentSelectCell.row )
                    {
                        currentCell = obj;
                    }
                    [obj noSelect];
                    obj.thumbnailIV.hidden = NO;
                }];
                
                
                RDFile * file = _fileList[currentSelectFileNumber];
                
                int number = currentSelectFileNumber;
                
//                currentCell.currentMultiDifferentFile.file = lastCell.currentMultiDifferentFile.file;
                float currentRotate = currentCell.currentMultiDifferentFile.file.rotate;
                float lastRotate = lastCell.currentMultiDifferentFile.file.rotate;
                
                _fileList[currentSelectFileNumber] = lastCell.currentMultiDifferentFile.file;
                _fileList[currentSelectFileNumber].rotate = currentRotate;
                currentCell.currentMultiDifferentFile.number = lastCell.currentMultiDifferentFile.number;
                
                
                _fileList[index] = file;
                _fileList[index].rotate = lastRotate;
                lastCell.currentMultiDifferentFile.number = number;
                
                [self adjPassthroughCollectionView];
                currentSelectCell = nil;
            }
            else
            {
                NSArray<RDTemplateCollectionViewCell *> * cellArray =  [templatePassthroughCollectionView visibleCells];
                [cellArray enumerateObjectsUsingBlock:^(RDTemplateCollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj noSelect];
                    obj.thumbnailIV.hidden = NO;
                }];
            }
        }
            break;
        default:
            break;
    }
}

-( void )adjPassthroughCollectionView
{
    [self initTemplatePassthroughCollectionView];
    currentIndex  = -1;
    currentIndexPath = nil;
    self.selectView.hidden = YES;
    if( _playSortThumbSliderView )
    {
        [_playSortThumbSlider removeFromSuperview];
        _playSortThumbSlider = nil;
        
        __block int imageCount = 0;
        [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( obj.fileType == kFILEIMAGE && !obj.isGif)
                imageCount++;
        }];
        if( imageCount >= (_multiDifferentFileList.count-1) )
            isAllImage = YES;
        else
            isAllImage = NO;
        
        if( _playModeType == RDPlayModeType_Order )
        {
            if( !isAllImage )
                self.playSortThumbSlider.hidden = NO;
            else
            {
                self.playSortThumbSlider.hidden = YES;
                [self playMode_type:simultaneouslyBtn];
            }
        }
        else
        {
            self.playSortThumbSlider.hidden = NO;
            [self playMode_type:simultaneouslyBtn];
        }
    }
}


+ (UIImage *)image:(UIImage*)image setAlpha:(CGFloat)alpha {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    CGContextSetAlpha(ctx, alpha);
    CGContextDrawImage(ctx, area, image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)dealloc{
    [_videoCoreSDK stop];
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK.delegate = nil;
    _videoCoreSDK = nil;
    
    [_musicChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            if(((ScrollViewChildItem *)obj).downloading){
                [obj removeFromSuperview];
                obj = nil;
            }
        }
    }];
    
    NSLog(@"%s",__func__);
}

#pragma mark - SubtitleColorControlDelegate
-(void)SubtitleColorChanged:(UIColor *) color  Index:(int) index  View:(UIControl *) SELF {
    videoBackgroundColor = color;
    templatePassthroughCollectionView.backgroundColor = videoBackgroundColor;
}
@end
