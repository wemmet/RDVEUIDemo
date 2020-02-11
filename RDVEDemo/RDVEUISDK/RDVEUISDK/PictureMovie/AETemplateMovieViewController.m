//
//  AETemplateMovieViewController.m
//  RDVEUISDK
//
//  Created by apple on 2018/6/21.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AETemplateMovieViewController.h"
#import "RDNavigationViewController.h"
#import "RDEditVideoViewController.h"
#import "ScrollViewChildItem.h"
#import "DubbingTrimmerView.h"
#import "CaptionVideoTrimmerView.h"
#import "RDATMHud.h"
#import "RDFileDownloader.h"
#import "RDMBProgressHUD.h"
#import "RDSVProgressHUD.h"
#import "RDMoveProgress.h"
#import "RDSectorProgressView.h"
#import "RDExportProgressView.h"
#import "RDZipArchive.h"
#import "UIImage+RDWebP.h"
#import "RDATMHudDelegate.h"
#import "RD_RDReachabilityLexiu.h"
#import "CircleView.h"
#import "RDLocalMusicViewController.h"
#import "RDCloudMusicViewController.h"
#import "UIImageView+RDWebCache.h"

//片段编辑
#import "RDThumbImageView.h"
#import "RDConnectBtn.h"
#import "RD_SortViewController.h"

//滤镜
#import "RDDownTool.h"

#import "RDMainViewController.h"//画中画

//文字
#import "RDAddEffectsByTimeline.h"
#import "RDAddEffectsByTimeline+Subtitle.h"
#import "UIImageView+RDWebCache.h"

#define AUTOSCROLL_THRESHOLD 30

#import <math.h>
#import <Photos/Photos.h>

#define kRefreshThumbMaxCounts 50

@interface AETemplateMovieViewController ()<RDVECoreDelegate,RDAlertViewDelegate,CaptionVideoTrimmerDelegate,RDMBProgressHUDDelegate,UIScrollViewDelegate,RDATMHudDelegate,ScrollViewChildItemDelegate,RDThumbImageViewDelegate,UIAlertViewDelegate>
{
    NSMutableArray  *toolItems;
    NSMutableArray  *mvList;
    NSInteger       lastThemeMVIndex;
    NSString        *lastMVName;
    NSMutableArray  *selectMVEffects;
    
    BOOL            enterSubtitle;
    BOOL            startAddSubtitle;
    BOOL            enterEditSubtitle;
    BOOL            unTouchSaveSubtitle;
    BOOL            enterFilter;
    CMTime          startPlayTime;
    BOOL            isRefreshThumb;
    
    BOOL            entervideoThumb;    //片段编辑开启
    
    NSMutableArray  *thumbTimes;
    NSDictionary    *subtitleEffectConfig;
    NSString        *subtitleEffectConfigPath;
    BOOL            stopAnimated;
    float           rotaionSaveAngle;
    
    //滤镜
    NSMutableArray  *globalFilters;
    NSInteger       selectFilterIndex;
    NSInteger       prevFilterIndex;
    
    NSMutableArray <RDCaption *> *subtitles;
    NSMutableArray <RDCaption *> *oldSubtitles;
    
    NSMutableArray <RDCaptionRangeViewFile *> *subtitleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldSubtitleFiles;
    
    BOOL             yuanyinOn;
    BOOL             isContinueExport;
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    BOOL             _idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    
    //片段编辑
    NSInteger               selectFileIndex;                            //当前文件编号
    NSTimer                 * autoscrollTimer;                          //时间
    RDThumbImageView        *deletedFileView;                           //删除的图片
    float                   _autoscrollDistance;
    
    CGRect                  m_PlayRect;             //播放器原始大小
    CGRect                  m_subtitleConfigEditView;
    
    //字幕
    int                     m_CurrentIndex;         //当前选中的项顺序
    bool                    m_CurrentModify;        //是否修改
    CaptionRangeView    *   m_PcurrentCaptionView;  //修改选中的
    
    
    
    //字幕
    UIScrollView                * addedSubtitleScrollView;
    UIScrollView                * addedMaterialEffectScrollView;
    UIImageView                 * selectedMaterialEffectItemIV;
    NSInteger                     selectedMaterialEffectIndex;
    BOOL                          isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    
    RDAdvanceEditType            selecteFunction;
    CMTime                        seekTime;
    UIView *stoolBarView;
    
    RDVECore        *thumbImageVideoCore;//截取缩率图
    CGRect             subtitleConfigViewRect;
    CMTimeRange             playTimeRange;
}


@property(nonatomic,strong)RDVECore         *videoCoreSDK;          //视频处理类
@property(nonatomic,strong)UIView           *playerView;            //播放器
@property(nonatomic,strong)UIButton         *playButton;            //播放按钮
@property(nonatomic,strong)UIScrollView     *toolBarView;           //工具栏
@property(nonatomic,strong)RDMoveProgress   *playProgress;          //视频进展
@property(nonatomic,strong)UIView           *playerToolBar;         //视频播放操作界面
@property(nonatomic,strong)UILabel          *currentTimeLabel;      //当前播放时间
@property(nonatomic,strong)UILabel          *durationLabel;         //总时间
@property(nonatomic,strong)UIButton         *zoomButton;            //全屏按钮
@property(nonatomic,strong)RDZSlider        *videoProgressSlider;   //视频播放当前进度条

@property(nonatomic,strong)UIView               *titleView;         //主界面
@property(nonatomic,strong)UILabel              *titleLabel;
@property(nonatomic,strong)UIButton             *backButton;
@property(nonatomic,strong)UIButton             *publishButton;
@property(nonatomic,strong)RDExportProgressView *exportProgressView;
//MV
@property(nonatomic,strong)UIView               *mvView;
@property(nonatomic,strong)UIScrollView         *mvChildsView;
//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;
@property(nonatomic,strong)NSMutableArray   *filtersName;
@property(nonatomic,strong)NSMutableArray   *filters;
//字幕
@property(nonatomic,strong)UIView                   *subtitleView;
@property(nonatomic,strong)RDAddEffectsByTimeline   *addEffectsByTimeline;
@property (nonatomic, strong) UIView *addedMaterialEffectView;
@property (nonatomic, assign) BOOL isAddingMaterialEffect;
@property (nonatomic, assign) BOOL isEdittingMaterialEffect;
@property (nonatomic, assign) BOOL isCancelMaterialEffect;

//片段编辑
@property(nonatomic,strong)UIScrollView     *videoThumbSlider;  //调整顺序的主视图
@property(nonatomic,strong)UIView           *videoThumbSliderback;//调整顺序的显示视图
@property(nonatomic,strong)UIButton         *addButton;             //图片添加按钮

@property(nonatomic,strong)RDATMHud         *hud;                   //提示语

@property(nonatomic,strong)RDMBProgressHUD  *progressHUD;           //圆形进度条
@property(nonatomic,strong)UIView           *syncContainer;

@property(nonatomic,strong)UIView           *editItemsSubtitleView;
@property(nonatomic       )UIAlertView      *commonAlertView;

@end

@implementation AETemplateMovieViewController

static float globalInset = 8;

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
    
    m_CurrentModify = NO;
    playTimeRange = kCMTimeRangeZero;
    //样式
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    //获取视频分辨率  设置音量  设置默认值
    [self setValue];
    //工具栏 是否半透明
    self.navigationController.navigationBar.translucent = iPhone4s;
    
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    [self.view addSubview:self.playerView];
    //导航栏设置
    [self.view addSubview:self.titleView];
    
    self.titleLabel.text = RDLocalizedString(@"nextedit-title", nil);
    //弹窗提示
     _hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:_hud.view];
    
    [self.view addSubview:self.toolBarView];
    
    [self initPlayer];
    
    //添加MV场景
    [self.view addSubview:self.mvView];
    //添加片段编辑
    [self.view addSubview:self.videoThumbSlider];
    
    //[self.view addSubview:self.musicView];
    //字幕添加 延时添加
    [self performSelector:@selector(initChildView) withObject:nil afterDelay:0.1];
    //初始进入设置
    [self check];
}

//未知
- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:self];
        [self.view addSubview:_hud.view];
    }
    [self.view bringSubviewToFront:_hud.view];
    return _hud;
}

//进度条设置
- (RDMoveProgress *)playProgress{
    if(!_playProgress){
        _playProgress = [[RDMoveProgress alloc] initWithFrame:CGRectMake(0,self.playerView.frame.size.height - 5, self.playerView.frame.size.width, 5)];
        [_playProgress setProgress:0 animated:NO];
        [_playProgress setTrackTintColor:Main_Color];
        [_playProgress setBackgroundColor:TOOLBAR_COLOR];
        _playProgress.hidden = YES;
    }
    return _playProgress;
}
#pragma mark- 滤镜
/**滤镜
 */
- (UIView *)filterView{
    if(!_filterView){
        _filterView = [UIView new];
        _filterView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _filterView.frame           = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height, kWIDTH, kHEIGHT - (_playerView.frame.origin.y + _playerView.frame.size.height) - _toolBarView.frame.size.height);
        _filterChildsView           = [UIScrollView new];
        _filterChildsView.frame     = CGRectMake(0, (_filterView.frame.size.height - (iPhone4s ? 70 : (kWIDTH>320 ? 100 : 80)))/2.0, _filterView.frame.size.width, (iPhone4s ? 70 : (kWIDTH>320 ? 100 : 80)));
        _filterChildsView.backgroundColor                   = [UIColor clearColor];
        _filterChildsView.showsHorizontalScrollIndicator    = NO;
        _filterChildsView.showsVerticalScrollIndicator      = NO;
        [_filterView addSubview:_filterChildsView];
        [self initFilterChildView];
        
        _filterView.hidden = YES;
    }
    return _filterView;
}

- (void)initFilterChildView {
    __weak typeof(self) myself = self;
    [globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(myself.filterChildsView.frame.size.height - 15)+10, 0, (myself.filterChildsView.frame.size.height - 25), _filterChildsView.frame.size.height)];
        item.backgroundColor        = [UIColor clearColor];
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
        [myself.filterChildsView addSubview:item];
        [item setSelected:(idx == self->selectFilterIndex ? YES : NO)];
    }];
    _filterChildsView.contentSize = CGSizeMake(globalFilters.count * (_filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
}

#pragma mark- 字幕
- (void)initToolBarView{
    if( !stoolBarView )
    {
        stoolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
        stoolBarView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [self.view addSubview:stoolBarView];
    }
    else
        stoolBarView.hidden = NO;
}

- (UIView *)subtitleView{
    if(!_subtitleView){
        //场景 坐标设置
        _subtitleView = [UIView new];
        _subtitleView.frame = CGRectMake(0, kPlayerViewHeight  + kPlayerViewOriginX, kWIDTH, kHEIGHT - (kPlayerViewHeight  + kPlayerViewOriginX) - kToolbarHeight);
        _subtitleView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        

        _subtitleView.hidden = YES;
    }
    return _subtitleView;
}
- (RDAddEffectsByTimeline *)addEffectsByTimeline {
    if (!_addEffectsByTimeline) {
        float height = kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight;
        _addEffectsByTimeline = [[RDAddEffectsByTimeline alloc] initWithFrame:CGRectMake(0,( _subtitleView.frame.size.height - height)/2.0, _subtitleView.frame.size.width, height)];
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
        _addedMaterialEffectView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, kWIDTH - 40, 44)];
        stoolBarView.backgroundColor =  TOOLBAR_COLOR;
        _addedMaterialEffectView.backgroundColor = TOOLBAR_COLOR;
//        _addedMaterialEffectView.hidden = YES;
        [stoolBarView addSubview:_addedMaterialEffectView];
        
        UILabel *addedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
        addedLbl.text = RDLocalizedString(@"已添加", nil);
        addedLbl.textColor = UIColorFromRGB(0x888888);
        addedLbl.font = [UIFont systemFontOfSize:14.0];
        [_addedMaterialEffectView addSubview:addedLbl];
        
        addedMaterialEffectScrollView =  [UIScrollView new];
        addedMaterialEffectScrollView.frame = CGRectMake(64, 0, _addedMaterialEffectView.bounds.size.width - 64, 44);
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

#pragma mark- 片段编辑
//控件添加
-(void)enumerateFileList:(NSArray *)arr
{
    
    float videoThumbSlider_Wdith = kWIDTH >320 ? 120 : 100;
    float videoThumbSlider_Height = kWIDTH >320 ? 100 : 80;
    __weak typeof(self) myself = self;
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(_videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height)];
        thumbView.backgroundColor = [UIColor clearColor];
        thumbView.frame = CGRectMake(videoThumbSlider_Wdith*idx, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
        thumbView.home = thumbView.frame;
        thumbView.contentFile = obj;
        if( arr )
        {
            if(!obj.thumbImage){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    obj.thumbImage = _fileList[selectFileIndex].thumbImage = [RDHelpClass assetGetThumImage:_fileList[selectFileIndex].isReverse ? CMTimeGetSeconds(_fileList[selectFileIndex].reverseVideoTrimTimeRange.start) : CMTimeGetSeconds(_fileList[selectFileIndex].videoTrimTimeRange.start) url:_fileList[selectFileIndex].isReverse ? _fileList[selectFileIndex].reverseVideoURL : _fileList[selectFileIndex].contentURL urlAsset:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        thumbView.thumbIconView.image = obj.thumbImage;
                    });
                });
            }
        }
        else{
            if(!obj.thumbImage){
                [myself performSelectorInBackground:@selector(refreshThumbImage:) withObject:thumbView];
            }else{
                thumbView.thumbIconView.image = obj.thumbImage;
            }
        }
        
        thumbView.thumbId = idx;
        thumbView.delegate = self;
        if(idx == selectFileIndex){
            [thumbView selectThumb:YES];
        }else{
            [thumbView selectThumb:NO];
        }
        [_videoThumbSliderback insertSubview:thumbView atIndex:0];
        
        if(idx ==(_fileList.count - 1)){
            [_addButton removeFromSuperview];
            _addButton = nil;
            if(myself.fileList.count < 20)
            {
                _addButton = [UIButton buttonWithType:UIButtonTypeCustom];
                _addButton.backgroundColor = [UIColor clearColor];
                _addButton.frame = CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width + 10, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
                UIImageView *btniconView = [[UIImageView alloc] init];
                btniconView.frame = CGRectMake(8, 8, _addButton.bounds.size.width - 16, _addButton.bounds.size.height - 16);
                btniconView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_添加素材默认_"];
                btniconView.contentMode = UIViewContentModeScaleAspectFit;
                [_addButton addSubview:btniconView];
                [_addButton addTarget:self action:@selector(tapAddButton:) forControlEvents:UIControlEventTouchUpInside];
                [_addButton setImageEdgeInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
                [_videoThumbSliderback addSubview:_addButton];
            }
            
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableSort){
                UIButton *sortButton = [UIButton buttonWithType:UIButtonTypeCustom];
                sortButton.backgroundColor = [UIColor clearColor];
                if(myself.fileList.count < 20)
                {
                    sortButton.frame = CGRectMake(_addButton.frame.origin.x + _addButton.frame.size.width + 10, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
                }
                else
                {
                    sortButton.frame = CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width + 10, 0, _videoThumbSlider.bounds.size.height, _videoThumbSlider.bounds.size.height);
                }
                
                [sortButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_调整顺序默认_"] forState:UIControlStateNormal];
                [sortButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_调整顺序点击_"] forState:UIControlStateHighlighted];
                [sortButton setTitle:RDLocalizedString(@"title-sort", nil) forState:UIControlStateNormal];
                [sortButton setTitle:RDLocalizedString(@"title-sort", nil) forState:UIControlStateHighlighted];
                [sortButton setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
                [sortButton setTitleColor:[UIColor colorWithRed:136/255.0 green:136/255.0 blue:136/255.0 alpha:0.5] forState:UIControlStateHighlighted];
                sortButton.titleLabel.font = [UIFont systemFontOfSize:13];
                [sortButton setTitleEdgeInsets:UIEdgeInsetsMake(40, -_videoThumbSlider.bounds.size.height+4, 0, 0)];
                [sortButton setImageEdgeInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
                [sortButton addTarget:self action:@selector(enter_Sort) forControlEvents:UIControlEventTouchUpInside];
                [_videoThumbSliderback addSubview:sortButton];
            }
            else{
                if(arr)
                {
                    float btnWidth = (videoThumbSlider_Wdith - videoThumbSlider_Height) + 16;
                    float btnHeight = btnWidth + 14;
                    RDConnectBtn *transitionBtn = [[RDConnectBtn alloc] initWithFrame:CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width - 8, (_videoThumbSlider.frame.size.height - btnHeight)/2.0, btnWidth, btnHeight)];
                    
                    transitionBtn.fileIndex = idx;
                    [_videoThumbSliderback addSubview:transitionBtn];
                }
            }
        }else{
            float btnWidth = (videoThumbSlider_Wdith - videoThumbSlider_Height) + 16;
            float btnHeight = btnWidth + 14;
            RDConnectBtn *transitionBtn = [[RDConnectBtn alloc] initWithFrame:CGRectMake(thumbView.frame.origin.x + thumbView.frame.size.width - 8, (_videoThumbSlider.frame.size.height - btnHeight)/2.0, btnWidth, btnHeight)];
            transitionBtn.fileIndex = idx;
            [_videoThumbSliderback addSubview:transitionBtn];
        }
    }];
    
    [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == 7){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

/*缩略图控件 顺序调整的主界面初始化 */
- (UIScrollView *)videoThumbSlider{
    //是否已经判断
    if (!_videoThumbSlider) {
        float videoThumbSlider_Wdith = kWIDTH > 320 ? 120 : 100;
        float  videoThumbSlider_Height = kWIDTH > 320 ? 100 : 80;
        
        //注册 清空
        [_videoThumbSliderback.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
        _videoThumbSlider = [UIScrollView new];
        _videoThumbSlider.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height + (kHEIGHT - (_playerView.frame.origin.y + _playerView.frame.size.height) - _toolBarView.bounds.size.height - videoThumbSlider_Height)/2.0, kWIDTH , videoThumbSlider_Height);
        
        _videoThumbSlider.backgroundColor = [UIColor clearColor];
        _videoThumbSlider.contentSize = CGSizeMake(_fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height)*2.0 + 20, 0);
        _videoThumbSlider.showsVerticalScrollIndicator = NO;
        _videoThumbSlider.showsHorizontalScrollIndicator = NO;
        
        _videoThumbSliderback = [UIView new];
        _videoThumbSliderback.backgroundColor = [UIColor clearColor];
        _videoThumbSliderback.frame = CGRectMake(0, 0, _fileList.count * videoThumbSlider_Wdith + (_videoThumbSlider.frame.size.height) * 2.0 + 20 , _videoThumbSlider.frame.size.height);
        [_videoThumbSlider addSubview: _videoThumbSliderback];
        
        _videoThumbSliderback.layer.masksToBounds = NO;
        [_videoThumbSlider setCanCancelContentTouches: NO];
        [_videoThumbSlider setClipsToBounds: NO];
        [_videoThumbSliderback setClipsToBounds: NO];
        
        //fileList列表枚举
        [self enumerateFileList:NULL];
    }
    return _videoThumbSlider;
}

-(void)refreshThumbImage:(RDThumbImageView *) tiv{
    RDFile * obj = _fileList[ tiv.thumbId ];
    obj.thumbImage = [RDHelpClass getThumbImageWithUrl:obj.contentURL];
    dispatch_async(dispatch_get_main_queue(), ^{
        tiv.thumbIconView.image = obj.thumbImage;
    });
}

-(void)refreshVideoThumbSlider{
    if (_videoThumbSlider) {
        float videoThumbSlider_Width = kWIDTH >320 ? 120 : 100;
        
        _videoThumbSlider.contentSize = CGSizeMake(_fileList.count * videoThumbSlider_Width +(_videoThumbSlider.frame.size.height) * 2.0 + 20 , 0);
        
        _videoThumbSliderback.frame = CGRectMake(0, 0, _fileList.count * videoThumbSlider_Width + (_videoThumbSlider.frame.size.height)*2 + 20, _videoThumbSlider.frame.size.height);
        
        NSArray *arr = [_videoThumbSliderback subviews];
        
        //场景枚举
        [self enumerateFileList:arr];
        
        [arr enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
            [obj removeFromSuperview];
        }];
        arr = nil;
    }
}

//进入排序
-(void)enter_Sort{
    if( [_videoCoreSDK isPlaying] ){
        [self playVideo:NO];
    }
    NSMutableArray * arr = [_fileList mutableCopy];
    
    RD_SortViewController *rdSort = [[RD_SortViewController alloc] init];
    rdSort.allThumbFiles = arr;
    rdSort.editorVideoSize = _exportVideoSize;
    rdSort.maxImageCount = 20;
    __weak typeof(self) weakSelf = self;
    rdSort.finishAction = ^(NSMutableArray *sortFileList) {
        if (sortFileList.count > 0) {
            //完成
            _fileList = [sortFileList mutableCopy];
            
            CGPoint offset = CGPointZero;
            [weakSelf.videoThumbSliderback.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [weakSelf.videoThumbSlider removeFromSuperview];
            weakSelf.videoThumbSlider = nil;
            [weakSelf.view addSubview:weakSelf.videoThumbSlider];
            
            [weakSelf.videoThumbSlider setContentOffset:offset];
            
            [weakSelf.toolBarView removeFromSuperview];
            weakSelf.toolBarView  = nil;
            
            [weakSelf.view addSubview:self.toolBarView];
            [weakSelf initPlayer];
        }
    };
    
    rdSort.cancelAction = ^(NSMutableArray *sortFileList){
        
    };
    [self.navigationController pushViewController:rdSort animated:YES];
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
    }
    
    return MIN(MIN(beforeDuration/2.0, behindDuration/2.0), 2.0);
    
}

#pragma mark- ThumbImageVideoCore
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
    thumbImageVideoCore.frame = _playerView.bounds;
    thumbImageVideoCore.customFilterArray = nil;
    [self refreshRdPlayer:thumbImageVideoCore];
}

#pragma mark- ThumbImageViewDelegate
-(void)thumbImageViewWasTapped:(RDThumbImageView *)tiv touchUpTiv:(BOOL)isTouchUpTiv{
    NSLog(@"%s",__func__);
    if ([_videoCoreSDK isPlaying]) {
        [self playVideo:NO];
    }
    [_videoThumbSliderback.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDThumbImageView class]]) {
            if ( ((RDThumbImageView *)obj).thumbId == selectFileIndex ) {
                [((RDThumbImageView*)obj) selectThumb:NO];
            }
        }
    }];
    
    selectFileIndex = tiv.thumbId;
    CMTime time = [_videoCoreSDK passThroughTimeRangeAtIndex: tiv.thumbId].start;
    
    [_videoCoreSDK seekToTime:time];
    [tiv selectThumb:YES];
    [self.toolBarView removeFromSuperview];
    self.toolBarView = nil;
    
    [self.view addSubview:self.toolBarView];
}

- (void)thumbImageViewWaslongLongTap:(RDThumbImageView *)tiv{
    [self.videoThumbSliderback bringSubviewToFront:tiv];
    if ( [_videoCoreSDK isPlaying] ) {
        [self playVideo:NO];
    }
    tiv.tap = NO;
    self.videoThumbSlider.scrollEnabled = NO;
    if (_fileList.count <= 1) {
        return;
    }
    tiv.canMovePostion = YES;
    
    if (tiv.cancelMovePostion) {
        tiv.canMovePostion = NO;
        
        return;
    }
    
    float videoThumbSlider_Wdith = kWIDTH > 320 ?  120 : 100;
    float videoThumbSlider_Height = kWIDTH > 320 ? 100 : 80;
    
    CGPoint touchLocation = tiv.center;
    CGFloat ofset_x = self.videoThumbSlider.contentOffset.x;
    self.videoThumbSliderback.frame = CGRectMake(self.videoThumbSliderback.frame.origin.x, self.videoThumbSliderback.frame.origin.y, _fileList.count * videoThumbSlider_Wdith + 20 + videoThumbSlider_Height + 10, self.videoThumbSliderback.frame.size.height);
    [self.videoThumbSlider setContentSize:CGSizeMake(self.videoThumbSliderback.frame.size.width + 10, 20)];
    
    NSMutableArray *arra = [self.videoThumbSliderback.subviews mutableCopy];
    [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView * obj1, RDThumbImageView * obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) {
            //obj1排后面
            return NSOrderedDescending;
        }
        else//obj1排前面
            return NSOrderedAscending;
    }];

    NSInteger index = 0;
    
    for (int i = 0; i < arra.count; i++) {
        RDConnectBtn *prompView = arra[i];
        if ([prompView isKindOfClass:[RDConnectBtn class]]) {
            prompView.hidden = YES;
            continue;
        }
        if ( [prompView isKindOfClass:[RDThumbImageView class]]) {
            [UIView animateWithDuration:0.15 animations: ^{
                CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
                ((RDThumbImageView *)prompView).frame = CGRectMake(index * videoThumbSlider_Wdith + 10, tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
                ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
                [((RDThumbImageView *)prompView) selectThumb:NO];
                if (((RDThumbImageView *)prompView) == tiv) {
                    [((RDThumbImageView *)prompView) selectThumb:YES];
                    [self.videoThumbSlider setContentOffset:CGPointMake(tiv.center.x - (touchLocation.x - ofset_x), 0)];
                    
                }
                
            }completion:^(BOOL finished) {
                
            } ];
            
            index ++;
        }
    }
}

-(void)thumbImageViewWaslongLongTapEnd:(RDThumbImageView *)tiv{
    
    tiv.canMovePostion = NO;
    if (_fileList.count <= 1) {
        return;
    }
    self.videoThumbSlider.scrollEnabled = YES;
    
    float videoThumbSlider_Wdith = kWIDTH > 320 ? 120 : 100;
    float vidoeThumbSlider_Height = kWIDTH > 320 ? 100 : 80;
    
    CGPoint touchLocation = tiv.center;
    
    CGFloat ofSet_x = self.videoThumbSlider.contentOffset.x;
    
    self.videoThumbSliderback.frame = CGRectMake(0, 0, _fileList.count * (videoThumbSlider_Wdith)+10 + vidoeThumbSlider_Height + 10 + videoThumbSlider_Wdith, self.videoThumbSlider.frame.size.height);
    
    [self.videoThumbSlider setContentSize:CGSizeMake(self.videoThumbSliderback.frame.size.width + 10, 20)];
    
    [_fileList removeAllObjects];
    NSMutableArray *arra = [self.videoThumbSliderback.subviews mutableCopy];
    //运用 sortUsingsortUsingComparator 排序 比冒泡排序性能要好
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
    for (int i = 0; i < arra.count; i++) {
        RDConnectBtn *prompView = arra[i];
        if ( [prompView isKindOfClass:[RDConnectBtn class] ]) {
            prompView.hidden = YES;
            continue;
        }
        if ( [prompView isKindOfClass: [RDThumbImageView class] ]) {
            CGRect tmpRect = ((RDThumbImageView *)prompView).frame;
            ((RDThumbImageView *)prompView).frame = CGRectMake(index * videoThumbSlider_Wdith, tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
            ((RDThumbImageView *)prompView).home = ((RDThumbImageView *)prompView).frame;
            ((RDThumbImageView *)prompView).thumbId = index;
            if (((RDThumbImageView *)prompView) == tiv) {
                selectFileIndex = index;
                [self.videoThumbSlider setContentOffset:CGPointMake( touchLocation.x + videoThumbSlider_Wdith < self.videoThumbSlider.frame.size.width ? 0 : tiv.center.x - (touchLocation.x - ofSet_x), 0)];
            }
            RDFile *file = [((RDThumbImageView *)prompView).contentFile mutableCopy];
            if ([file.transitionTypeName isEqualToString:kDefaultTransitionTypeName]) {
                file.transitionName = RDLocalizedString(@"无", nil);
                file.transitionMask = nil;
                file.transitionDuration = 0;
            }
            [_fileList addObject:file];
            index ++;
        }
    }
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.transitionDuration = MIN( [self maxTransitionDuration:idx], obj.transitionDuration );
    }];
    
    for (RDConnectBtn *prompView in self.videoThumbSliderback.subviews) {
        if ( [prompView isKindOfClass: [RDConnectBtn class]]) {
            prompView.hidden = NO;
        }
    }
    
    [self.toolBarView removeFromSuperview];
    self.toolBarView = nil;
    
    [self.view addSubview:self.toolBarView];
    
    [self initPlayer];
    [self initThumbImageVideoCore];
    [self refreshVideoThumbSlider];
}

- (void)thumbImageViewMoved:(RDThumbImageView *)draggingThumb withEvent:(UIEvent *)event{
    draggingThumb.tap = NO;
    if (!draggingThumb.canMovePostion) {
        return;
    }
    draggingThumb.tap = NO;
    if(!draggingThumb.canMovePostion){
        return;
    }
    // return;
    //边缘检测
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

- (void)thumbImageViewStoppedTracking:(RDThumbImageView *)tiv withEvent:(UIEvent *)event{
    [autoscrollTimer invalidate];
    autoscrollTimer = nil;
    
    //self.connectToolBarView.hidden = YES;
    self.toolBarView.hidden = NO;
    
    [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == 7){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
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
    
    [self initCommonAlertViewWithTitle:str message:@"" cancelButtonTitle:RDLocalizedString(@"是", nil) otherButtonTitles:RDLocalizedString(@"否", nil) alertViewTag:7];
    
    deletedFileView = tiv;
}

#pragma mark Autoscrolling methods
-(void)maybeAutoscrollForThumb:(RDThumbImageView *)thumb
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
        [autoscrollTimer invalidate];
        autoscrollTimer = nil;
    }
    
    // otherwise create and start timer (if we don't already have a timer going)
    else if (autoscrollTimer == nil)
    {
        autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                                           target:self
                                                         selector:@selector(autoscrollTimerFired:)
                                                         userInfo:thumb
                                                          repeats:YES];
    }
}

-(float)autoscrollDistanceForProximityToEdge:(float) proximity
{
    // the scroll distance grows as the proximity to the edge decreases, so that moving the thumb
    // further over results in faster scrolling.
    return ceilf((AUTOSCROLL_THRESHOLD - proximity)/5.0);
}

-(void)legalizeAutoscrollDistance
{
    // makes sure the autoscroll distance won't result in scrolling past the content of the scroll view
    float minimumLegalDistance = [self.videoThumbSlider contentOffset].x * -1;
    float maximumLegalDistance = [self.videoThumbSlider contentSize].width - ([self.videoThumbSlider frame].size.width
                                                                              + [self.videoThumbSlider contentOffset].x);
    _autoscrollDistance = MAX(_autoscrollDistance, minimumLegalDistance);
    _autoscrollDistance = MIN(_autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer{
    //return;
    
    [self legalizeAutoscrollDistance];
    // autoscroll by changing content offset
    CGPoint contentOffset = [self.videoThumbSlider contentOffset];
    contentOffset.x += _autoscrollDistance;
    [self.videoThumbSlider setContentOffset:contentOffset];
    
    RDThumbImageView *thumb = (RDThumbImageView *)[timer userInfo];
    [thumb moveByOffset:CGPointMake(_autoscrollDistance, 0) withEvent:nil];
}

//添加文件
-(void)tapAddButton:(UIButton *) sender{
    [self AddFile:((RDNavigationViewController*)self.navigationController).editConfiguration.supportFileType touchConnect:NO];
}

/**添加文件
 *@params isTouch 是否点击的两个缩略图之间的加号添加文件
 */
- (void)AddFile:(SUPPORTFILETYPE)type touchConnect:(BOOL) isTouch{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    __weak typeof(self) myself = self;
    
    if(([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)] ||
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)] ||
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)])){
        
        if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
            [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
                [myself addFileWithList:lists withType:type touchConnect: isTouch];
            }];
            
            return;
        }
    }
    //wuxiaoxia mantis:0001949
    NSString *cameraOutputPath = ((RDNavigationViewController*)self.navigationController).cameraConfiguration.cameraOutputPath;
    for (RDFile *file in _fileList) {
        if ( [file.contentURL.path isEqualToString:cameraOutputPath]) {
            NSString * exportPath = [kRDDirectory stringByAppendingPathComponent:@"/recordVideoFile_rd.mp4"];
            ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath = exportPath;
            break;
        }
    }
    
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];    
    if (type == ONLYSUPPORT_IMAGE) {
        mainVC.showPhotos = YES;
    }
    ((RDNavigationViewController *)self.navigationController).editConfiguration.mediaCountLimit =  20 - _fileList.count;
    mainVC.textPhotoProportion = _exportVideoSize.width/(float)_exportVideoSize.height;
    mainVC.onAlbumCallbackBlock = ^(NSMutableArray<NSURL *> * _Nonnull urls) {
        [myself addFileWithList:urls withType:type touchConnect:isTouch];
    };
    
    RDNavigationViewController * nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addFileWithList:(NSMutableArray *)thumbFilelist withType:(SUPPORTFILETYPE)type touchConnect:(BOOL) istouch{
    NSInteger index = _fileList.count;
    for (NSInteger i = (thumbFilelist.count - 1); i>=0; i--) {
        RDFile * file = [RDFile new];
        if([RDHelpClass isImageUrl:thumbFilelist[i]]){
            file.contentURL = thumbFilelist[i];
            file.fileType = kFILEIMAGE;
            file.imageDurationTime = CMTimeMakeWithSeconds(4, TIMESCALE);
            file.speedIndex = 1;
        }else{
            file.contentURL = thumbFilelist[i];
            file.fileType = kFILEVIDEO;
            file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
            file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
            file.reverseVideoTimeRange = file.videoTimeRange;
            file.videoTrimTimeRange = kCMTimeRangeInvalid;
            file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
            file.speedIndex = 2;
        }
        if (!istouch) {
            [_fileList insertObject:file atIndex:index];
        }else{
            [_fileList insertObject:file atIndex:selectFileIndex+1];
        }
    }
    CGPoint offset = self.videoThumbSlider.contentOffset;
    [self.videoThumbSliderback.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.videoThumbSlider removeFromSuperview];
    self.videoThumbSlider = nil;
    [self.view addSubview:self.videoThumbSlider];
    
    [self.videoThumbSlider setContentOffset:offset];
    
    [self.toolBarView removeFromSuperview];
    self.toolBarView = nil;
    
    [self.view addSubview:self.toolBarView];
    //self.connectToolBarView.hidden = YES;
    self.toolBarView.hidden = NO;
    
    [self initPlayer];
}

//对删除文件进行调整
- (void)deletedFile:(RDThumbImageView *)tiv{
    if (_fileList.count > 1) {
        [_fileList removeObjectAtIndex:tiv.thumbId];
        selectFileIndex = MAX( (selectFileIndex >= tiv.thumbId ? selectFileIndex - 1 : selectFileIndex), 0 );
        
        _fileList[selectFileIndex].transitionDuration = MIN( [self maxTransitionDuration:selectFileIndex], _fileList[selectFileIndex].transitionDuration );
        
        CGPoint offset = self.videoThumbSlider.contentOffset;
        
        float diffx = (tiv.frame.origin.x + tiv.frame.size.width) - offset.x;
        offset.x -= MIN( tiv.frame.size.width + 34, diffx);
        offset.y = MAX(offset.x, 0);
        
        NSMutableArray * arra = [self.videoThumbSliderback.subviews mutableCopy];
        [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
            CGFloat obj1X = obj1.frame.origin.x;
            CGFloat obj2X = obj2.frame.origin.x;
            
            if (obj1X > obj2X) { // obj1排后面
                return NSOrderedDescending;
            } else { // obj1排前面
                return NSOrderedAscending;
            }
        }];
        
        float tiv_width = tiv.frame.size.width + 20;
        float videoThumbSlider_width = (kWIDTH > 320 ? 120 : 100);
        
        __block RDThumbImageView * selectTiv;
        
        [arra enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if([obj isKindOfClass:[RDConnectBtn class]]){
                if ( ((RDConnectBtn*)obj).fileIndex == ( tiv.thumbId == _fileList.count ? tiv.thumbId - 1 : tiv.thumbId ) ) {
                    [obj removeFromSuperview];
                }
                if (((RDConnectBtn *)obj).fileIndex > (tiv.thumbId == _fileList.count ? tiv.thumbId - 1 : tiv.thumbId)) {
                    CGRect rect = obj.frame;
                    rect.origin.x = obj.frame.origin.x - obj.frame.size.width - tiv_width + 16;
                    obj.frame = rect;
                    ((RDConnectBtn*)obj).fileIndex -= 1;
                }
                
//                if ( ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTransition ) {
//                    [((RDConnectBtn *)obj) setSelected:NO];
//                }
            }else if( [obj isKindOfClass:[RDThumbImageView class]] )
            {
                if ( ((RDThumbImageView*)obj).thumbId == tiv.thumbId ) {
                    [obj removeFromSuperview];
                }
                if (  ((RDThumbImageView *)obj).thumbId > tiv.thumbId) {
                    CGRect rect = obj.frame;
                    rect.origin.x = obj.frame.origin.x - videoThumbSlider_width;
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
                rect.origin.x = obj.frame.origin.x - videoThumbSlider_width;
                obj.frame = rect;
            }
        }];
        
        [self.videoThumbSlider setContentOffset:offset];
        
        _videoThumbSlider.contentSize = CGSizeMake(_fileList.count * videoThumbSlider_width + (_videoThumbSlider.frame.size.height)*2.0 + 20, 0);
        [self.toolBarView removeFromSuperview];
        self.toolBarView = nil;
        [self.view addSubview:self.toolBarView];
        
        [self initPlayer];
        [self refreshVideoThumbSlider];
    }else{
        [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"至少保留一个文件", nil)]];
        [_hud show];
        [_hud hideAfter:2];
    }
}

- (void)updateSyncLayerPositionAndTransform
{
    if(!_syncContainer){
        _syncContainer = [[UIView alloc] init];
    }
    //视频分辨率
    CGSize presentationSize  = _exportVideoSize;
    
    CGRect bounds = self.playerView.bounds;
    bounds.size.height -= 5;
    CGRect videoRect         = AVMakeRectWithAspectRatioInsideRect(presentationSize, bounds);
    _syncContainer.frame = videoRect;
    _syncContainer.layer.masksToBounds = YES;
}
#pragma mark-
#pragma mark-MV
- (UIView *)mvView{
    
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
        return nil;
    }
    
    if(!_mvView){
        _mvView = [UIView new];
        _mvView.frame = CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height, kWIDTH, (kHEIGHT - (_playerView.frame.origin.y + _playerView.frame.size.height) - _toolBarView.frame.size.height) - 30);
        _mvView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        
        [_mvView addSubview:self.mvChildsView];
        _mvView.hidden = YES;
    }
    return _mvView;
}

- (UIScrollView *)mvChildsView{
    if(!_mvChildsView){
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kMVAnimateFolder]){
            [fileManager createDirectoryAtPath:kMVAnimateFolder withIntermediateDirectories:YES attributes:nil error:&error];
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
        
        RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
        NSString *mvListPath = [kMVAnimateFolder stringByAppendingPathComponent:@"animationlistPic.plist"];
        mvList = [[NSArray arrayWithContentsOfFile:mvListPath] mutableCopy];
        RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
        if(mvList){
            if([lexiu currentReachabilityStatus] != RDNotReachable){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *mvurl = nv.editConfiguration.newmvResourceURL;
                    NSDictionary *dic = [RDHelpClass getNetworkMaterialWithType:@"mvae2"
                                                                         appkey:nv.appKey
                                                                        urlPath:mvurl];
                    if([dic[@"code"] integerValue] == 0){
                        NSMutableArray *tempMvList = mvList;
                        mvList = dic[@"data"];
                        if (![mvList writeToFile:mvListPath atomically:YES]) {
                            //NSLog(@"写入失败");
                        }
                        [mvList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *file = [obj[@"file"] stringByDeletingPathExtension];
                            NSString *updateTime = obj[@"updatetime"];
                            __block NSString *tmpUpdateTime;
                            [tempMvList enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                                if ([[obj1[@"file"] stringByDeletingPathExtension] isEqualToString:file]) {
                                    tmpUpdateTime = obj1[@"updatetime"];
                                    *stop1 = YES;
                                }
                            }];
                            if(tmpUpdateTime && ![tmpUpdateTime isEqualToString:updateTime])
                            {
                                NSString *file = [[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[obj[@"file"] lastPathComponent] stringByDeletingPathExtension]];
                                NSString *path = [kMVAnimateFolder stringByAppendingPathComponent:file];
                                NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:nil];
                                NSString *name = [files lastObject];
                                NSString *jsonPath = [NSString stringWithFormat:@"%@%@.json", kMVAnimateFolder, name];
                                if ([fileManager fileExistsAtPath:jsonPath]) {
                                    [fileManager removeItemAtPath:jsonPath error:nil];
                                }
                                jsonPath = [NSString stringWithFormat:@"%@%@.json", [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimate/"], name];
                                if ([fileManager fileExistsAtPath:jsonPath]) {
                                    [fileManager removeItemAtPath:jsonPath error:nil];
                                }
                                if ([fileManager fileExistsAtPath:path]) {
                                    [fileManager removeItemAtPath:path error:nil];
                                }
                            }
                        }];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self initchildMVItem];
                        });
                    }
                });
            }else {
                [self initchildMVItem];
            }
        }
        else{
            if([lexiu currentReachabilityStatus] != RDNotReachable){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *mvurl = nv.editConfiguration.newmvResourceURL;
                    NSDictionary *dic = [RDHelpClass getNetworkMaterialWithType:@"mvae2"
                                                                         appkey:nv.appKey
                                                                        urlPath:mvurl];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if([dic[@"code"] integerValue] == 0){
                            mvList = dic[@"data"];
                            if (![mvList writeToFile:mvListPath atomically:YES]) {
                                NSLog(@"写入失败");
                            }
                            [self initchildMVItem];
                        }
                    });
                });
            }else{
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [_hud show];
                [_hud hideAfter:2];
                [self initchildMVItem];
            }
        }
        _mvChildsView.hidden = NO;
    }
    
    return _mvChildsView;
}

- (void)initchildMVItem{
    for (int i = 1; i<mvList.count+1; i++) {
        
        ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(i*(_mvChildsView.frame.size.height - 10)+5, 0, _mvChildsView.frame.size.height - 20, _mvChildsView.frame.size.height)];
        item.backgroundColor = [UIColor clearColor];
        item.fontSize = 12;
        item.type = 3;
        item.delegate = self;
        item.selectedColor = Main_Color;
        item.normalColor   = UIColorFromRGB(0x888888);
        item.cornerRadius = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor = [UIColor clearColor];
        [item.itemIconView rd_sd_setImageWithURL:[mvList[i-1] objectForKey:@"cover"]];
        
        NSString *title = [mvList[i-1] objectForKey:@"name"];
        item.itemTitleLabel.text  = title;
        item.tag = i+1;
        [_mvChildsView addSubview:item];
        [item setSelected:(i == lastThemeMVIndex ? YES : NO)];
    }
    _mvChildsView.contentSize = CGSizeMake((mvList.count + 1) * (_mvChildsView.frame.size.height - 10), _mvChildsView.frame.size.height);
}

#pragma mark-
/**导航栏
 */
- (UIView *)titleView{
    if(!_titleView){
        _titleView = [UIView new];
        if(iPhone_X){
            _titleView.frame = CGRectMake(0, 0, kWIDTH, 88);
        }else
            _titleView.frame = CGRectMake(0, 0, kWIDTH, 44);
        _titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
        [_titleView addSubview:self.backButton];
        [_titleView addSubview:self.publishButton];
        [_titleView addSubview:self.titleLabel];
    }
    return _titleView;
}

/**返回按键
 */
- (UIButton *)backButton{
    if(!_backButton){
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.exclusiveTouch = YES;
        _backButton.backgroundColor = [UIColor clearColor];
        _backButton.frame = CGRectMake(5, (self.titleView.frame.size.height - 44), 44, 44);
        [_backButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _backButton;
}

/**标题
 */
- (UILabel *)titleLabel{
    if(!_titleLabel){
        _titleLabel = [UILabel new];
        _titleLabel.frame = CGRectMake(self.titleView.frame.size.width/2.0 - 60, (self.titleView.frame.size.height - 44), 120, 44);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _titleLabel.textColor = UIColorFromRGB(0xffffff);
        
    }
    return _titleLabel;
}

- (void)changePublicBtnTitle:(BOOL)image{
    if(image){
        [_publishButton setTitle:@"" forState:UIControlStateNormal];
        [_publishButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步完成默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }else{
        [_publishButton setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [_publishButton setImage:nil forState:UIControlStateNormal];
    }
}

/**下一步按键
 */
- (UIButton *)publishButton{
    if(!_publishButton){
        _publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _publishButton.exclusiveTouch = YES;
        _publishButton.backgroundColor = [UIColor clearColor];
        _publishButton.frame = CGRectMake(kWIDTH - 69, (self.titleView.frame.size.height - 44), 64, 44);
        _publishButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_publishButton setTitleColor:Main_Color forState:UIControlStateNormal];
        [_publishButton setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [_publishButton addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _publishButton;
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
    _videoProgressSlider.value = 0;
    [_playProgress setProgress:0];
    _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    [_exportProgressView setProgress:0 animated:NO];
    [_exportProgressView removeFromSuperview];
    _exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
}
/**播放器
 */
- (UIView *)playerView{
    if(!_playerView){
        _playerView = [UIView new];
        _playerView.frame = CGRectMake(0, iPhone4s ? 0 : (iPhone_X ? 88 : 44), kWIDTH, kPlayerViewHeight);
        _playerView.backgroundColor = UIColorFromRGB(0x000000);
        
        UIView *playProgressBack= [UIView new];
        playProgressBack.frame = CGRectMake(0, _playerView.frame.size.height - 5, kWIDTH, 5);
        playProgressBack.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [_playerView addSubview:playProgressBack];
        
        [_playerView addSubview:[self playButton]];
        [_playerView addSubview:[self playerToolBar]];
        [_playerView addSubview:self.playProgress];
        
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
        _playerToolBar = [UIView new];
        _playerToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _playerToolBar.frame = CGRectMake(0, self.playerView.frame.size.height - 44, self.playerView.frame.size.width, 44);
        
        [_playerToolBar addSubview:self.currentTimeLabel];
        [_playerToolBar addSubview:self.durationLabel];
        [_playerToolBar addSubview:self.videoProgressSlider];
        [_playerToolBar addSubview:self.zoomButton];
        _playerToolBar.hidden = YES;
    }
    
    return _playerToolBar;
}

- (UILabel *)durationLabel{
    if(!_durationLabel){
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.frame = CGRectMake(self.playerToolBar.frame.size.width - 60 - 50, (self.playerToolBar.frame.size.height - 20)/2.0, 60, 20);
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = UIColorFromRGB(0xffffff);
        _durationLabel.font = [UIFont systemFontOfSize:12];
        
    }
    return _durationLabel;
}

- (UILabel *)currentTimeLabel{
    if(!_currentTimeLabel){
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.frame = CGRectMake(5, (self.playerToolBar.frame.size.height - 20)/2.0,60, 20);
        _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
        _currentTimeLabel.textColor = UIColorFromRGB(0xffffff);
        _currentTimeLabel.font = [UIFont systemFontOfSize:12];
        
    }
    return _currentTimeLabel;
}

- (UIButton *)zoomButton{
    if(!_zoomButton){
        _zoomButton = [UIButton new];
        _zoomButton.backgroundColor = [UIColor clearColor];
        _zoomButton.frame = CGRectMake(self.playerToolBar.frame.size.width - 50, (self.playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_全屏默认_"] forState:UIControlStateNormal];
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_缩小默认_"] forState:UIControlStateSelected];
        [_zoomButton addTarget:self action:@selector(tapzoomButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _zoomButton;
}

/**进度条
 */
- (RDZSlider *)videoProgressSlider{
    if(!_videoProgressSlider){
        
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(60, (self.playerToolBar.frame.size.height - 30)/2.0, self.playerToolBar.frame.size.width - 60 - 60 - 50, 30)];
        [_videoProgressSlider setMaximumValue:1];
        [_videoProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        _videoProgressSlider.layer.cornerRadius = 2.0;
        _videoProgressSlider.layer.masksToBounds = YES;
        [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        
        [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_videoProgressSlider setValue:0];
        _videoProgressSlider.alpha = 1.0;
        
        _videoProgressSlider.backgroundColor = [UIColor clearColor];
        
        [_videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _videoProgressSlider;
}

/**工具栏
 */
- (UIScrollView *)toolBarView{
    if(!_toolBarView){
        
        NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"title-template", nil),@"title",@( RDAdvanceEditType_MV),@"id", nil];
        NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"字幕", nil),@"title",@(RDAdvanceEditType_Subtitle),@"id", nil];
        NSDictionary *dic5 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"滤镜", nil),@"title",@(RDAdvanceEditType_Filter),@"id", nil];
        NSDictionary *dic7 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"title-enableFragmentedit", nil),@"title",@(7),@"id", nil];
        
        toolItems = [NSMutableArray array];
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
            [toolItems addObject:dic1];
        }
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableSubtitle){
            [toolItems addObject:dic4];
        }
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableFilter){
            [toolItems addObject:dic5];
        }
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableFragmentedit && !((RDNavigationViewController *)self.navigationController).editConfiguration.enableWizard){
            [toolItems addObject:dic7];
        }
        
        _toolBarView =  [UIScrollView new];
        _toolBarView.frame = CGRectMake(0, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)), kWIDTH, (iPhone_X ? 88 : (iPhone4s ? 55 : 60)));
        _toolBarView.backgroundColor = TOOLBAR_COLOR;
        _toolBarView.showsVerticalScrollIndicator = NO;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        [self.view addSubview:_toolBarView];
        
        __block float toolItemBtnWidth = MAX(kWIDTH/toolItems.count, _toolBarView.frame.size.height + 5);
        __block float contentsWidth = 0;
        [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.exclusiveTouch = YES;
            toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, 0, toolItemBtnWidth, 60);
            [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self toolItemsImagePath:toolItemBtn.tag - 1]] forState:UIControlStateNormal];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self toolItemsSelectImagePath:toolItemBtn.tag - 1]] forState:UIControlStateSelected];
            [toolItemBtn setTitle:[toolItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
            [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            [_toolBarView addSubview:toolItemBtn];
            contentsWidth += toolItemBtnWidth;
        }];
        _toolBarView.contentSize = CGSizeMake(contentsWidth, 0);
        
    }
    return _toolBarView;
}

/**获取工具栏Icon图标地址
 */
- (NSString *)toolItemsSelectImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑M V选中_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑字幕选中_@3x" Type:@"png"];
        }
            break;
        case 4:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑滤镜选中_@3x" Type:@"png"];
        }
            break;
        case 6:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑片段编辑选中_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

- (NSString *)toolItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑M V默认_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑字幕默认_@3x" Type:@"png"];
        }
            break;
        case 4:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑滤镜默认_@3x" Type:@"png"];
        }
            break;
        case 6:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑片段编辑默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}


- (void)setValue{
    if (CGSizeEqualToSize(_exportVideoSize, CGSizeZero)) {
        _exportVideoSize = [self getEditVideoSize];
    }
    _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                           APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                          LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                           videoSize:_exportVideoSize
                                                 fps:kEXPORTFPS
                                          resultFail:^(NSError *error) {
                                              NSLog(@"initSDKError:%@", error.localizedDescription);
                                          }];
    _videoCoreSDK.delegate = self;
    yuanyinOn = YES;
    
    globalFilters = [NSMutableArray array];
    RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
    if(nav.editConfiguration.filterResourceURL.length>0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                        appkey:nav.appKey  urlPath:nav.editConfiguration.filterResourceURL];
            if ([filterList[@"code"] intValue] == 0) {
                self.filtersName = [filterList[@"data"] mutableCopy];
                
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(nav.appKey.length>0)
                [itemDic setObject:nav.appKey forKey:@"appkey"];
                [itemDic setObject:@"" forKey:@"cover"];
                [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                [self.filtersName insertObject:itemDic atIndex:0];
                
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
                [_videoCoreSDK addGlobalFilters:globalFilters];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_filterChildsView && _filterChildsView.subviews.count == 0) {
                        [self initFilterChildView];
                    }
                });
            }
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
}
- (CGSize)getEditVideoSize{
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV){
        return CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
    }
    return [RDHelpClass getEditVideoSizeWithFileList:_fileList];
}

- (void)check{
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV || ((RDNavigationViewController *)self.navigationController).editConfiguration.enableMusic){
        [self clickToolItemBtn:[self.toolBarView viewWithTag:[[toolItems[0] objectForKey:@"id"] integerValue]]];
    }else{
       [self clickToolItemBtn:[self.toolBarView viewWithTag:5]];//点击滤镜
    }
}


- (void)initChildView{
    
    [self.view addSubview:self.subtitleView];
}


- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}
//通知视图控制器，其视图将被添加到视图层次结构中。  添加
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //设置通知调度机制 等效委托机制
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationItem setHidesBackButton:YES];
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    //UI应用程序确实收到内存警告通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    //UI应用程序将退出主动通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //UI应用程序将进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    //UI应用程序已成为主动通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //UI键盘将显示通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
     //UI键盘将隐藏通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [_videoCoreSDK prepare];//20171026 wuxiaoxia 优化内存
}
//通知视图控制器，其视图即将从视图层次结构中移除  移除
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_videoCoreSDK stop];//20171026 wuxiaoxia 优化内存
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
//手机键盘 显示
- (void)keyboardWillShow:(NSNotification *)notification{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    subtitleConfigViewRect = _addEffectsByTimeline.subtitleConfigView.frame;
    
    bottomViewFrame.origin.y = kHEIGHT - keyboardSize.height - 48;
    
    _addEffectsByTimeline.subtitleConfigView.frame = bottomViewFrame;
}
//手机键盘 隐藏
- (void)keyboardWillHide:(NSNotification *)notification{
//    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
//    bottomViewFrame.origin.y = subtitleView_Y;
    _addEffectsByTimeline.subtitleConfigView.frame = subtitleConfigViewRect;
}
//提示框 弹出
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
//提示框 是否的选择
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 1://MV
            if(buttonIndex == 1){
                if( enterSubtitle )
                    [self adjPlayerRect:NO];
                
                startAddSubtitle = NO;
                enterEditSubtitle = NO;
                unTouchSaveSubtitle = NO;
                self.titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
                self.playerView.frame = CGRectMake(0, iPhone4s ? 0 : (iPhone_X ? 88 : 44), kWIDTH, kWIDTH + 5);
                [_syncContainer removeFromSuperview];
                [self back:nil];
            }
            break;
        case 2://相册
             if(buttonIndex == 1){
                 //返回相册
                 [_videoCoreSDK stop];
                 _videoCoreSDK.delegate = nil;
                 _videoCoreSDK = nil;
                 UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
                 if(!upView){
                     [self dismissViewControllerAnimated:YES completion:nil];
                 }
                 if(_cancelActionBlock){
                     _cancelActionBlock();
                 }
             }
            break;
        case 4://字幕
            if(buttonIndex == 1){
                [_videoCoreSDK stop];
                _videoCoreSDK.delegate = nil;
                _videoCoreSDK = nil;
                UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
                if(!upView){
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                if(_cancelActionBlock){
                    _cancelActionBlock();
                }
            }
            break;
        case 5:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [self cancelExportBlock];
                [_videoCoreSDK cancelExportMovie:nil];
            }
            break;
            
        case 6:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
        case 7:
        {
            //片段编辑
            if(buttonIndex == 0){
                [self deletedFile:deletedFileView];
            }
            break;
        default:
            break;
        }
    }
}

/**初始化播放器
 */
- (void)initPlayer{
    [_videoCoreSDK stop];//20181105 fix bug:不断切换mv、配乐会因内存问题崩溃
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    if(!_videoCoreSDK){
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_exportVideoSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
        _videoCoreSDK.delegate = self;
        [_videoCoreSDK addGlobalFilters:globalFilters];
        [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
    }
    if (!_videoCoreSDK.view.superview) {
        [self.playerView insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
    }
    [self performSelector:@selector(refreshRdPlayer:) withObject:_videoCoreSDK afterDelay:0.1];
}

- (void)refreshRdPlayer:(RDVECore *)rdPlayer {
    NSMutableArray *scenes = [NSMutableArray new];
    for (int i = 0; i<_fileList.count; i++) {
        RDFile *file = _fileList[i];
        RDScene *scene = [[RDScene alloc] init];
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        if(file.fileType == kFILEVIDEO){
            vvasset.videoActualTimeRange = file.videoActualTimeRange;
            vvasset.type = RDAssetTypeVideo;
            vvasset.timeRange = file.videoTimeRange;
        }else {
            vvasset.type         = RDAssetTypeImage;
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;        
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.crop = file.crop;
        
        [scene.vvAsset addObject:vvasset];
        [scenes addObject:scene];
    }
    
    [rdPlayer setEditorVideoSize:_exportVideoSize];
    CGRect rect = self.playerView.bounds;
    rect.size.height -= 5;
    rdPlayer.frame = rect;
    //图片添加
    [rdPlayer setScenes:scenes];
    [rdPlayer setGlobalFilter:selectFilterIndex];
    [rdPlayer addMVEffect:selectMVEffects];
    if (lastThemeMVIndex == 0) {
        [rdPlayer setMusics:nil];
    }else{
        NSDictionary *itemDic = mvList[lastThemeMVIndex - 1];
        NSString *file = [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]];
        NSString *path = [kMVAnimateFolder stringByAppendingPathComponent:file];
        path = [path stringByAppendingPathComponent:lastMVName];
        NSString *itemConfigPath = [path stringByAppendingPathComponent:@"config.json"];
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:itemConfigPath];
        NSMutableDictionary *themeDic = [RDHelpClass objectForData:jsonData];
        jsonData = nil;
        NSDictionary *setting = [themeDic objectForKey:@"rdsetting"];
        if (setting) {
            NSDictionary *musicDic = [setting objectForKey:@"music"];
            NSString *musicPath = [NSString stringWithFormat:@"%@/%@", path, [musicDic objectForKey:@"fileName"]];
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
                music.isFadeInOut = YES;
                [rdPlayer setMusics:[NSMutableArray arrayWithObject:music]];
            }
        }
    }
    
    [rdPlayer build];
    //是否循环播放
    if(self.mvView != nil && !self.mvView.hidden ){
        [rdPlayer setShouldRepeat:YES];
    }else{
        [rdPlayer setShouldRepeat:NO];
    }
    //    [RDSVProgressHUD dismiss];
    self.durationLabel.text = [RDHelpClass timeToStringFormat:rdPlayer.duration];
    self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
}

//字幕添加 到视频预览播放器中
- (void)refreshCaptions {
    _videoCoreSDK.captions = subtitles;
}

/**功能选择
 */
- (void)clickToolItemBtn:(UIButton *)sender{
    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
    //if([_videoCoreSDK isPlaying]){
    //    [self playVideo:NO];
    //}
 
    switch (sender.tag) {
        case 1:
        {
            RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
            if([lexiu currentReachabilityStatus] == RDNotReachable){
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
                return;
            }
            //TODO:进入主题MV
            selecteFunction = RDAdvanceEditType_MV;
            [_videoCoreSDK setShouldRepeat:YES];
            if(!self.mvView.superview)
                [self.view addSubview:self.mvView];
            self.titleLabel.text = sender.currentTitle;
            [self changePublicBtnTitle:NO];
            
            entervideoThumb = NO;
            _filterView.hidden = YES;
            self.toolBarView.hidden = NO;
            _subtitleView.hidden = YES;
            self.playerToolBar.hidden = YES;
            self.playProgress.hidden = YES;
            self.videoThumbSlider.hidden = YES;
            _mvView.hidden = NO;
            [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.tag == 1){
                    obj.selected = YES;
                }else{
                    obj.selected = NO;
                }
            }];
            
        }
            break;
        case 4:
        {
            RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
            if([lexiu currentReachabilityStatus] == RDNotReachable){
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
                return;
            }
            //TODO:进入字幕
            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
            [self initToolBarView];
            selecteFunction = RDAdvanceEditType_Subtitle;
            if([_videoCoreSDK isPlaying]){
                [self playVideo:NO];
            }
            [_videoCoreSDK setShouldRepeat:NO];
//            [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
            if (lastThemeMVIndex > 0) {
                isRefreshThumb = YES;
            }else {
                isRefreshThumb = NO;
            }
            [self initThumbImageVideoCore];
            self.titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(LASTIPHONE_5 ? 1.0 : 0.6)];
            self.playerView.frame = CGRectMake(0, LASTIPHONE_5 ? 44 : 0, kWIDTH, kWIDTH + 5);
            if(!self.subtitleView.superview)
                [self.view addSubview:self.subtitleView];
            self.titleLabel.text = sender.currentTitle;
            [self changePublicBtnTitle:YES];
            _playButton.hidden = YES;
            enterSubtitle = YES;
            entervideoThumb =  NO;
            _mvView.hidden = YES;
            self.subtitleView.hidden = NO;
            self.playerToolBar.hidden = YES;
            self.playProgress.hidden = YES;
            self.videoThumbSlider.hidden = YES;
            _filterView.hidden = YES;
            self.toolBarView.hidden = YES;
            self.subtitleView.hidden = NO;
            self.addEffectsByTimeline.hidden = NO;
            _addEffectsByTimeline.thumbnailCoreSDK = _videoCoreSDK;
            if (!_addEffectsByTimeline.superview) {
                [_subtitleView addSubview:_addEffectsByTimeline];
                _addEffectsByTimeline.currentEffect = selecteFunction;
            }else {
                _addEffectsByTimeline.currentEffect = selecteFunction;
                [_addEffectsByTimeline removeFromSuperview];
                [_subtitleView addSubview:_addEffectsByTimeline];
            }
            _addEffectsByTimeline.currentTimeLbl.text = @"0.00";
            self.addedMaterialEffectView.hidden = NO;
//            [self performSelector:@selector(enterSubtitle) withObject:nil afterDelay:0.1];
        }
            break;
        case 5:
        {
            RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
            if([lexiu currentReachabilityStatus] == RDNotReachable){
                [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
                return;
            }
            //TODO:进入滤镜
            selecteFunction = RDAdvanceEditType_Filter;
            [_videoCoreSDK setShouldRepeat:NO];
            if(!self.filterView.superview)
                [self.view addSubview:self.filterView];
            self.titleLabel.text = sender.currentTitle;
            [self changePublicBtnTitle:NO];
            _mvView.hidden = YES;
            _filterView.hidden = NO;
            _subtitleView.hidden = YES;
            self.playerToolBar.hidden = YES;
            self.playProgress.hidden = NO;
             self.videoThumbSlider.hidden = YES;
            [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.tag == 5){
                    obj.selected = YES;
                }else{
                    obj.selected = NO;
                }
            }];
        }
            break;
        case 7:
        {
            //TODO:进入片段编辑
            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
            if([_videoCoreSDK isPlaying]){
                [self playVideo:NO];
            }
            [_videoCoreSDK setShouldRepeat:YES];
            self.titleLabel.text = sender.currentTitle;
            [self changePublicBtnTitle:NO];
            
            _filterView.hidden = YES;
            _subtitleView.hidden = YES;
            self.playerToolBar.hidden = YES;
            self.toolBarView.hidden = NO;
            self.playProgress.hidden = YES;
           _mvView.hidden = YES;
            
            enterSubtitle = NO;
            entervideoThumb =  YES;
            self.videoThumbSlider.hidden = NO;
            [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.tag == 7){
                    obj.selected = YES;
                }else{
                    obj.selected = NO;
                }
            }];
            
            
        }
            break;
        default:
            break;
    }
}

/**点击返回按键
 */
- (void)back:(UIButton *)sender{
    
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    
    if (selecteFunction == RDAdvanceEditType_Subtitle)
    {
        if (_isAddingMaterialEffect) {
            [_addEffectsByTimeline cancelEffectAction:nil];
        }else {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
        }
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        selecteFunction = RDAdvanceEditType_None;
        
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        _addedMaterialEffectView.hidden = YES;
        _subtitleView.hidden = YES;
        _playerToolBar.hidden = NO;
        
        [self refreshCaptions];
        [self clickToolItemBtn:[self.toolBarView viewWithTag:RDAdvanceEditType_MV]];//MV
        stoolBarView.hidden = YES;
        return;
    }
    
    
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableWizard){
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"您确定要放弃编辑吗?",nil)
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"取消",nil)
                         otherButtonTitles:RDLocalizedString(@"确定",nil)
                              alertViewTag:2];
        return;
    }
    
    [_videoCoreSDK stop];
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK.delegate = nil;
    _videoCoreSDK = nil;
    UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
    if(!upView){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if(_cancelActionBlock){
        _cancelActionBlock();
    }
    
}

/**点击发布按键
 */
- (void)tapPublishBtn{
    
    //暂停
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }    
    if(selecteFunction == RDAdvanceEditType_Subtitle){
        if( !_addEffectsByTimeline.trimmerView.rangeSlider.hidden )
         {
             [_addEffectsByTimeline finishEffectAction:nil];
             return;
         }
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect){
            [_addEffectsByTimeline saveSubtitleTimeRange];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            return;
        }
        [_addEffectsByTimeline discardEdit];
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
//        _addedMaterialEffectView.hidden = YES;
        _subtitleView.hidden = YES;
        _playerToolBar.hidden = NO;
        
        oldSubtitleFiles = [subtitleFiles mutableCopy];
        
        selecteFunction = RDAdvanceEditType_None;
        [self refreshCaptions];
        [self clickToolItemBtn:[self.toolBarView viewWithTag:RDAdvanceEditType_MV]];//MV
        stoolBarView.hidden = YES;
        return;
    }
    
    [self playVideo:NO];
    isContinueExport = NO;
    RDFile *file = [_fileList firstObject];
    if (((RDNavigationViewController *)self.navigationController).exportConfiguration.waterDisabled
        && ((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicDisabled
        && (_fileList.count == 1)
        && (file.fileType == kFILEVIDEO)
        && ((selectMVEffects.count == 0) || (selectMVEffects == nil))
        && (lastThemeMVIndex == 0)
        && (selectFilterIndex == 0)
        && (subtitles.count == 0)
        && (file.customFilterIndex == 0)
        && (file.filterIndex == kRDFilterType_YuanShi)
        )
    {
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

//导出
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
                              alertViewTag:6];
        return;
    }
    [_videoCoreSDK stop];
    
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress:0 animated:NO];
    
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
    
    CGSize exportSize = _exportVideoSize;
    if (!CGSizeEqualToSize(_videoCoreSDK.animationSize, CGSizeZero)) {
        float animationPro = _videoCoreSDK.animationSize.width/_videoCoreSDK.animationSize.height;
        float exportPro = _exportVideoSize.width/_exportVideoSize.height;
        if (animationPro != exportPro) {
            exportSize = _videoCoreSDK.animationSize;
        }
    }
    //水印 添加
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:_videoCoreSDK totalDration:_videoCoreSDK.duration exportSize:exportSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    [_videoCoreSDK setEditorVideoSize:exportSize];
    
    [_videoCoreSDK exportMovieURL:[NSURL fileURLWithPath:export]
                             size:exportSize
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
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    [_videoCoreSDK.view removeFromSuperview];
    _videoCoreSDK = nil;
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
}

/**点击播放暂停按键
 */
- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

/**是否全屏
 */
- (void)tapzoomButton{
    _zoomButton.selected = !_zoomButton.selected;
    if(_zoomButton.selected){
        [self.view bringSubviewToFront:self.playerView];
        //放大
        CGRect videoThumbnailFrame = CGRectZero;
        CGRect playerFrame = CGRectZero;
        self.playerView.transform = CGAffineTransformIdentity;
        if(_exportVideoSize.width>_exportVideoSize.height){
            self.playerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = kHEIGHT;
            videoThumbnailFrame.size.width  = kWIDTH;
            playerFrame = videoThumbnailFrame;
            playerFrame.origin.x=0;
            playerFrame.origin.y=0;
            playerFrame.size.width = kHEIGHT;
            playerFrame.size.height  = kWIDTH;
            self.playerToolBar.frame = CGRectMake(0, playerFrame.size.height - 44, playerFrame.size.width, 44);
        }else{
//            self.playerView.transform = CGAffineTransformMakeRotation(0);
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = kHEIGHT;
            videoThumbnailFrame.size.width  = kWIDTH;
            playerFrame = videoThumbnailFrame;
            self.playerToolBar.frame = CGRectMake(0, playerFrame.size.height - (iPhone_X ? 78 : 44), playerFrame.size.width, (iPhone_X ? 78 : 44));
        }
        if (iPhone_X) {
            _videoCoreSDK.fillMode = kRDViewFillModeScaleAspectFill;
        }
        [self.playerView setFrame:videoThumbnailFrame];
        
        _videoCoreSDK.frame = playerFrame;
        self.playButton.frame = CGRectMake((playerFrame.size.width - 44.0)/2.0, (playerFrame.size.height - 44)/2.0, 44, 44);
        self.playProgress.frame = CGRectMake(0,playerFrame.size.height-5, playerFrame.size.width, 5);
        self.currentTimeLabel.frame = CGRectMake(5, (self.playerToolBar.frame.size.height - 20)/2.0,60, 20);
        self.videoProgressSlider.frame = CGRectMake(60, (self.playerToolBar.frame.size.height - 30)/2.0, self.playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        self.durationLabel.frame = CGRectMake(self.playerToolBar.frame.size.width - 60 - 50, (self.playerToolBar.frame.size.height - 20)/2.0, 60, 20);
        self.zoomButton.frame = CGRectMake(self.playerToolBar.frame.size.width - 50, (self.playerToolBar.frame.size.height - 44)/2.0, 44, 44);
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
        [self.view bringSubviewToFront:self.titleView];
        //缩小
        self.playerView.transform = CGAffineTransformIdentity;
        self.playerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
        [self.playerView setFrame:CGRectMake(0, iPhone4s ? 0 : (iPhone_X ? 88 : 44), kWIDTH, kPlayerViewHeight)];
        _videoCoreSDK.frame = self.playerView.bounds;
        self.playButton.frame = CGRectMake((self.playerView.frame.size.width - 44.0)/2.0, (self.playerView.frame.size.height - 44)/2.0, 44, 44);
        self.playProgress.frame = CGRectMake(0,self.playerView.frame.size.height-5, self.playerView.frame.size.width, 5);
        self.playerToolBar.frame = CGRectMake(0, self.playerView.frame.size.height - 44, self.playerView.frame.size.width, 44);
        self.currentTimeLabel.frame = CGRectMake(5, (self.playerToolBar.frame.size.height - 20)/2.0,60, 20);
        self.videoProgressSlider.frame = CGRectMake(60, (self.playerToolBar.frame.size.height - 30)/2.0, self.playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        self.durationLabel.frame = CGRectMake(self.playerToolBar.frame.size.width - 60 - 50, self.playerToolBar.frame.size.height - 30, 60, 20);
        self.zoomButton.frame = CGRectMake(self.playerToolBar.frame.size.width - 50, (self.playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        if(![_videoCoreSDK isPlaying]){
            if (CMTimeGetSeconds(CMTimeSubtract(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))) >= 0.0) {
                [_videoCoreSDK seekToTime:CMTimeSubtract(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }else {
                [_videoCoreSDK seekToTime:CMTimeAdd(_videoCoreSDK.currentTime, CMTimeMake(2, kEXPORTFPS))];
            }
        }
    }
}

//调整播放器
-(void)adjPlayerRect:(bool)isRect
{
    if (!iPhone4s) {
        return;
    }
    if( (m_PlayRect.size.width > 0) && (m_PlayRect.size.height > 0) )
    {
        if (isRect) {
        
            float height = (float)kHEIGHT -  m_subtitleConfigEditView.size.height;
            float width = ( m_PlayRect.size.width / m_PlayRect.size.height ) * height;
            height = width *( m_PlayRect.size.height / m_PlayRect.size.width );
            
            _playerView.frame  = CGRectMake(   (m_PlayRect.size.width - width )/2.0, 0,  width,  height );
            
            if( m_CurrentModify )
                _videoCoreSDK.frame = CGRectMake( 0 , 0, _playerView.frame.size.width,  _playerView.frame.size.height - 5 );
            else
                _videoCoreSDK.frame = CGRectMake( 0 , 0, _playerView.frame.size.width,  _playerView.frame.size.height);
        }
        else{
            _playerView.frame = m_PlayRect;
            CGRect rect = self.playerView.bounds;
            rect.size.height -= 5;
            _videoCoreSDK.frame = rect;
        }
        
        [self updateSyncLayerPositionAndTransform];
    }
}

//TODO: 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
}

/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:current];
    [self.playProgress setProgress:_videoProgressSlider.value animated:NO];
    
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    
    CGFloat current = _videoProgressSlider.value*_videoCoreSDK.duration;
    [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}


- (void)playVideo:(BOOL)play{
    
    if(!play){
        //不加这个判断，疯狂切换音乐在低配机器上有可能反应不过来
#if 1
        [_videoCoreSDK pause];
#else
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
#endif
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
                _playButton.hidden = NO;
                [self playerToolbarShow];
            }
                break;
        }
        
    }else{
        if (_videoCoreSDK.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
        NSLog(@"%s line:%d",__func__,__LINE__);
        //不加这个判断，疯狂切换音乐在低配机器上有可能反应不过来
#if 1
        [_videoCoreSDK play];
#else
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }else{
            NSLog(@"[_videoCoreSDK isPlaying] = YES");
        }
#endif
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                startPlayTime = _videoCoreSDK.currentTime;
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
                _playButton.hidden = YES;
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
                [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
            }
                break;
        }
    }
}

- (void)playerToolbarShow{
    if( selecteFunction == RDAdvanceEditType_Subtitle )
        return;
    
    self.playerToolBar.hidden = NO;
    self.playProgress.hidden = YES;
    self.playButton.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        self.playerToolBar.hidden = YES;
        self.playButton.hidden = YES;
        if(!enterSubtitle){
            self.playProgress.hidden = NO;
        }
    }];
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        if(sender == _videoCoreSDK){
            if (entervideoThumb) {
                CMTimeRange timerange = [_videoCoreSDK passThroughTimeRangeAtIndex:selectFileIndex];
                __weak typeof(self) weakSelf = self;
                [_videoCoreSDK seekToTime:timerange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                    [weakSelf progress:_videoCoreSDK currentTime:timerange.start];
                    if (!isResignActive) {
                        [weakSelf playVideo:YES];
                    }
                }];
            }
            else if (!isResignActive) {
                if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
                    [self playVideo:YES];
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
        else if (selecteFunction == RDAdvanceEditType_Subtitle){
            [self loadTrimmerViewThumbImage];
        }
    }
}

/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    
    if(sender == thumbImageVideoCore){
        return;
    }
    self.durationLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:_videoCoreSDK.duration]];
    if([_videoCoreSDK isPlaying]){
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), _videoCoreSDK.duration)];
        float progress = CMTimeGetSeconds(currentTime)/_videoCoreSDK.duration;
        [_videoProgressSlider setValue:progress];
        [_playProgress setProgress:progress animated:NO];
        
        switch (selecteFunction) {
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
                        _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:time];
                        playTimeRange = kCMTimeRangeZero;
                    }
                }else {
                    if(!_addEffectsByTimeline.trimmerView.videoCore) {
                        [_addEffectsByTimeline.trimmerView setVideoCore:thumbImageVideoCore];
                    }
                    [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
                    _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
                    if(_isAddingMaterialEffect){
                        BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
                        if(!suc){
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
}

/**播放结束
 */
- (void)playToEnd{
    [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Subtitle:
        {
            if(_isAddingMaterialEffect){
                [_addEffectsByTimeline saveSubtitle:YES];
            }else{
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        default:
            break;
    }
    [_videoCoreSDK seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [_videoProgressSlider setValue:0];
    [self.playProgress setProgress:0 animated:NO];
}

- (void)tapPlayerView{
    if(self.playerToolBar.hidden){
        if( selecteFunction != RDAdvanceEditType_Subtitle )
            self.playButton.hidden = NO;
        [self playerToolbarShow];
    }else{
        self.playButton.hidden = YES;
        [self playerToolbarHidden];
    }
}

#pragma mark- =====DubbingTrimViewDelegate CaptionVideoTrimViewDelegate ======

- (void)seekTime:(NSNumber *)numTime{
    NSLog(@"%s time :%f",__func__,[numTime floatValue]);
    CMTime time = CMTimeMakeWithSeconds([numTime floatValue], TIMESCALE);
    [_videoCoreSDK seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
        float duration = _videoCoreSDK.duration;
        if(CMTimeGetSeconds(startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
            [self playVideo:YES];
        }
    }];
    
}

- (void)trimmerView:(id)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime{
    if(![_videoCoreSDK isPlaying]){
        
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            float duration = _videoCoreSDK.duration;
            if(CMTimeGetSeconds(startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [self playVideo:YES];
            }
        }];
    }
    
    if(enterSubtitle){
//        self.subtitlecurrentTitmeLabel.text = [RDHelpClass timeToSecFormat:startTime];//[NSString stringWithFormat:@"%.2lf",startTime];
    }
}

- (void)capationScrollViewWillBegin:(CaptionVideoTrimmerView *)trimmerView{
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
}

- (void)didEndChangeSelectedMinimumValue_maximumValue{
    if(enterSubtitle){
        
    }
    [self refreshCaptions];
    CMTime time = [_videoCoreSDK currentTime];
    [_videoCoreSDK filterRefresh:time];
    
}
- (void)capationScrollViewWillEnd:(CaptionVideoTrimmerView *)trimmerView
                        startTime:(Float64)capationStartTime
                          endTime:(Float64)capationEndTime{
    
    if((startAddSubtitle || enterEditSubtitle) && enterSubtitle){
        return;
    }
    if([_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    
    // [self seekTime:@(capationStartTime)];
}

- (void)touchescurrentCaptionView:(id)trimmerView
                      showOhidden:(BOOL)flag
                        startTime:(Float64)captionStartTime{
}
#pragma mark- ==========

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
                    image = [_videoCoreSDK getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (selecteFunction) {
                    case RDAdvanceEditType_Subtitle://MARK:字幕
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:image
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:subtitles
                                                           oldFileArray:oldSubtitleFiles];
                        
                        if (subtitles.count == 0) {
//                            _addedMaterialEffectView.hidden = YES;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
//                            _addedMaterialEffectView.hidden = NO;
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

//圆形进度条 启动
- (void)initProgressHUD:(NSString *)message{
    if (_progressHUD) {
        _progressHUD.delegate = nil;
        _progressHUD = nil;
    }
    //圆形进度条
    _progressHUD = [[RDMBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:_progressHUD];
    _progressHUD.removeFromSuperViewOnHide = YES;
    _progressHUD.mode = RDMBProgressHUDModeDeterminate;//MBProgressHUDModeAnnularDeterminate;
    _progressHUD.animationType = RDMBProgressHUDAnimationFade;
    _progressHUD.labelText = message;
    _progressHUD.isShowCancelBtn = YES;
    _progressHUD.delegate = self;
    [_progressHUD show:YES];
    [self myProgressTask:0];
    
}

- (void)myProgressTask:(float)progress{
    [_progressHUD setProgress:progress];
}

//压缩
- (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption fileCount:(NSInteger)fileCount progress:(RDSectorProgressView *)progressView completionBlock:(void (^)())completionBlock
{
    
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    zip.fileCounts = fileCount;
    zip.delegate = self;
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES completionProgress:^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(progressView){
                    [progressView setProgress:progress];
                }
            });
            
        }];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            
            unlink([zipPath UTF8String]);
            
        }
        [zip RDUnzipCloseFile];
        completionBlock();
        
    }
    
    
}

- (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption
{
    //dispatch_async(dispatch_get_main_queue(), ^{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0; 压缩
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            unlink([zipPath UTF8String]);
        }
        [zip RDUnzipCloseFile];
    }
    //});
}

#pragma mark- scrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item{
    if(item.type == 2){
        
        //滤镜
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
            NSDictionary *obj = self.filtersName[item.tag - 1];
            NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
            if(item.tag-1 == 0){
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
                [item setSelected:YES];
                selectFilterIndex = item.tag-1;
                if (![lastMVName isEqualToString:@"old_film"]) {
                    prevFilterIndex = selectFilterIndex;
                }
                [self.videoCoreSDK setGlobalFilter:selectFilterIndex];
                if(!_filterView.hidden && ![self.videoCoreSDK isPlaying]){
                    [self.videoCoreSDK filterRefresh:self.videoCoreSDK.currentTime];
                    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                    [self playVideo:YES];
                }
                return ;
            }
            
            NSString *itemPath = [[[filterPath stringByAppendingPathComponent:obj[@"name"]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
            if([[NSFileManager defaultManager] fileExistsAtPath:itemPath]){
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
                [item setSelected:YES];
                selectFilterIndex = item.tag-1;
                if (![lastMVName isEqualToString:@"old_film"]) {
                    prevFilterIndex = selectFilterIndex;
                }
                [self.videoCoreSDK setGlobalFilter:selectFilterIndex];
                if(!_filterView.hidden && ![self.videoCoreSDK isPlaying]){
                    [self.videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
                    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                    [self playVideo:YES];
                }
                return ;
            }
            
            CGRect rect = [item getIconFrame];
            CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
            item.downloading = YES;
            [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
            
            ddprogress.progressColor = Main_Color;
            ddprogress.progressWidth = 2.f;
            ddprogress.progressBackgroundColor = [UIColor clearColor];
            [item addSubview:ddprogress];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RDDownTool *tool = [[RDDownTool alloc] initWithURLPath:obj[@"file"] savePath:itemPath];
                tool.Progress = ^(float numProgress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ddprogress setPercent:numProgress];
                    });
                };
                
                 __weak typeof(self) myself = self;
                
                tool.Finish = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ddprogress removeFromSuperview];
                        item.downloading = NO;
                        if([myself downLoadingFilterCount]>=1){
                            return ;
                        }
                        [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if([obj isKindOfClass:[ScrollViewChildItem class]]){
                                
                                [(ScrollViewChildItem *)obj setSelected:NO];
                            }
                        }];
                        [item setSelected:YES];
                        selectFilterIndex = item.tag-1;
                        if (![lastMVName isEqualToString:@"old_film"]) {
                            prevFilterIndex = selectFilterIndex;
                        }
                        ((RDFilter *)globalFilters[selectFilterIndex]).filterPath = itemPath;
                        
                        [_videoCoreSDK setGlobalFilter:selectFilterIndex];
                        
                        if(!_filterView.hidden && ![_videoCoreSDK isPlaying]){
                            [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
                            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                            [self playVideo:YES];
                        }
                    });
                };
                [tool start];
            });
            
        }else{
            [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
            [item setSelected:YES];
            selectFilterIndex = item.tag-1;
            if (![lastMVName isEqualToString:@"old_film"]) {
                prevFilterIndex = selectFilterIndex;
            }
            [_videoCoreSDK setGlobalFilter:selectFilterIndex];
            
            if(!_filterView.hidden && ![_videoCoreSDK isPlaying]){
                [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
                //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                [self playVideo:YES];
            }
        }
    }
    else if(item.type == 3){
        if (item.tag - 1 == lastThemeMVIndex) {
            return;
        }
        //MV
        __weak typeof(self) myself = self;
        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeBlack];
        if([self.videoCoreSDK isPlaying]){
            [myself playVideo:NO];
        }
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:0];
        [_videoProgressSlider setValue:0];
        [self.playProgress setProgress:0 animated:NO];
        
        ScrollViewChildItem *childItem = [_mvChildsView viewWithTag:lastThemeMVIndex+1];
        [childItem setSelected:NO];
        
        [selectMVEffects removeAllObjects];
        selectMVEffects = nil;
        if(item.tag == 1){
            [item setSelected:YES];
            lastThemeMVIndex = 0;
            _exportVideoSize = [self getEditVideoSize];
            lastMVName = nil;
            [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
            selectFilterIndex = prevFilterIndex;
            [_videoCoreSDK setGlobalFilter:selectFilterIndex];
            [((ScrollViewChildItem *)[_filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:YES];
            [_videoCoreSDK addMVEffect:[selectMVEffects mutableCopy]];
            [_videoCoreSDK setMusics:nil];
            [_videoCoreSDK setJsonAnimation:nil];
            self.durationLabel.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration];
        }
        else{
            NSDictionary *itemDic = mvList[item.tag-2];
            NSString *urlstr = itemDic[@"file"];
            RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
            
            NSString *file = [[[urlstr stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[urlstr lastPathComponent] stringByDeletingPathExtension]];
            NSString *path = [kMVAnimateFolder stringByAppendingPathComponent:file];
            
            NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
            NSString *MVName = [files lastObject];
            NSString *jsonPath = [[path stringByAppendingPathComponent:MVName] stringByAppendingPathComponent:@"config.json"];
            
            if(fileCount == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:jsonPath]){
                if(item.downloading){
                    return;
                }
                if([lexiu currentReachabilityStatus] == RDNotReachable){
                    [RDSVProgressHUD dismiss];
                    [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                    [self.hud show];
                    [self.hud hideAfter:2];
                    return;
                }
                CGRect rect = [item getIconFrame];
                CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
                ddprogress.progressColor = Main_Color;
                ddprogress.progressWidth = 2.f;
                ddprogress.progressBackgroundColor = [UIColor clearColor];
                [item addSubview:ddprogress];
                item.downloading = YES;
                [RDFileDownloader downloadFileWithURL:urlstr cachePath:kMVAnimateFolder httpMethod:GET progress:^(NSNumber *numProgress) {
                    NSLog(@"%lf",[numProgress floatValue]);
                    [ddprogress setPercent:[numProgress floatValue]];
                } finish:^(NSString *fileCachePath) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSLog(@"下载完成");
                        item.downloading = NO;
                        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                        }
                        BOOL suc =[RDHelpClass OpenZipp:fileCachePath unzipto:path];
                        if(suc){                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [ddprogress removeFromSuperview];
                                if([myself downLoadingMVCount]>=1){
                                    return ;
                                }
                                [myself scrollViewChildItemTapCallBlock:item];
                            });
                        }
                    });
                } fail:^(NSError *error) {
                    NSLog(@"下载失败");
                    [RDSVProgressHUD dismiss];
                    [self.hud setCaption:error.localizedDescription];
                    [self.hud show];
                    [self.hud hideAfter:2];
                    item.downloading = NO;
                    [ddprogress removeFromSuperview];
                }];
            }
            else
            {
                [item setSelected:YES];
                lastThemeMVIndex = item.tag-1;
                
                lastMVName = [files lastObject];
                path = [path stringByAppendingPathComponent:lastMVName];
                NSString *itemConfigPath = [path stringByAppendingPathComponent:@"config.json"];
                NSData *jsonData = [[NSData alloc] initWithContentsOfFile:itemConfigPath];
                NSMutableDictionary *themeDic = [RDHelpClass objectForData:jsonData];
                jsonData = nil;
                NSDictionary *setting = [themeDic objectForKey:@"rdsetting"];
                if (setting) {
                    int fps = 0;
                    if ([setting[@"swDecode"] boolValue]) {
                        //帧率四舍五入
                        fps = roundf([themeDic[@"fr"] floatValue]);
                    }
                    NSDictionary *musicDic = [setting objectForKey:@"music"];
                    NSString *musicFileName = [musicDic objectForKey:@"fileName"];
                    NSString *musicPath = [NSString stringWithFormat:@"%@/%@", path, musicFileName];
                    if (musicPath && [[NSFileManager defaultManager] fileExistsAtPath:musicPath]) {
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
                        [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
                    }
                    NSArray *effects = [setting objectForKey:@"effects"];
                    if (effects.count >0) {
                        NSMutableArray *effectVideos = [NSMutableArray array];
                        [effects enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([[obj objectForKey:@"fileName"] length] > 0)
                            {
                                [effectVideos addObject:obj];
                            }
                        }];
                        selectMVEffects = [NSMutableArray array];
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
                            [selectMVEffects addObject:mvEffect];
                        }];
                    }
                    [_videoCoreSDK addMVEffect:[selectMVEffects mutableCopy]];
                    
                    NSMutableArray *bgSourceArray = [NSMutableArray array];
                    NSMutableArray *bgSourceMusicArray = [NSMutableArray array];
                    NSArray *bgArray = [setting objectForKey:@"background"];
                    
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
                        [_videoCoreSDK setDubbingMusics:bgSourceMusicArray];
                    }
                    NSArray *noneEditArray = [setting objectForKey:@"aeNoneEdit"];
                    NSMutableArray *noneEditPathArray = [NSMutableArray array];
                    [noneEditArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [noneEditPathArray addObject:[path stringByAppendingPathComponent:obj]];
                    }];
                    if (!noneEditArray || noneEditArray.count == 0) {
                        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
                        float ver = [themeDic[@"ver"] floatValue];
                        for (NSString *fileName in files) {
                            if ([RDHelpClass isImageUrl:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:fileName]]]) {
                                if (![fileName hasPrefix:@"ReplaceableText"]) {
                                    if (ver == 1.0) {//不可替换图片命名以background开头
                                        if ([fileName hasPrefix:@"background"]) {
                                            [noneEditPathArray addObject:[path stringByAppendingPathComponent:fileName]];
                                        }
                                    }else {//除了Replaceable开头的图片，其它图片都作为不可替换图片
                                        if (![fileName hasPrefix:@"Replaceable"]) {
                                            [noneEditPathArray addObject:[path stringByAppendingPathComponent:fileName]];
                                        }
                                    }
                                }
                            }
                        }
                    }
                    RDJsonAnimation *jsonAnimation = [RDJsonAnimation new];
                    jsonAnimation.jsonPath = jsonPath;
                    jsonAnimation.nonEditableImagePathArray = noneEditPathArray;
                    jsonAnimation.bgSourceArray = bgSourceArray;
                    if (fps > 0) {
                        jsonAnimation.exportFps = fps;
                    }
                    [_videoCoreSDK setJsonAnimation:jsonAnimation];
                }
                
                CGSize oldSize = _exportVideoSize;
                //分辨率改变后，字幕位置需要重新计算
                if (subtitles.count > 0 && !CGSizeEqualToSize(_videoCoreSDK.animationSize, oldSize)) {
                    [self refreshCaptionsEtcSize:_videoCoreSDK.animationSize array:subtitles];
                    oldSubtitleFiles = [subtitleFiles mutableCopy];
                    [_videoCoreSDK setCaptions:subtitles];
                }
                _exportVideoSize = _videoCoreSDK.animationSize;
                self.durationLabel.text = [RDHelpClass timeToStringFormat:_videoCoreSDK.duration];
            }
        }
    }
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
    NSLog(@"dwonloadingFiltersCount:%d",count);
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
    NSLog(@"dwonloadingMVCount:%d",count);
    return count;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    _videoCoreSDK = nil;
    [thumbImageVideoCore stop];
    thumbImageVideoCore.delegate = nil;
    thumbImageVideoCore = nil;
    
    if (_commonAlertView) {
        [_commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
        _commonAlertView.delegate = nil;
        _commonAlertView = nil;
    }
}

//分辨率调整后，字幕等的大小也要做相应的调整
- (void)refreshCaptionsEtcSize:(CGSize)newVideoSize array:(NSMutableArray<RDCaption*>*)array {
    CGSize oldVideoActualSize = AVMakeRectWithAspectRatioInsideRect(_exportVideoSize, _playerView.bounds).size;
    float  oldScale =    _exportVideoSize.width/oldVideoActualSize.width;
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

#pragma mark- 字幕
#pragma mark - RDAddEffectsByTimelineDelegate
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
    if(![_videoCoreSDK isPlaying]){
        WeakSelf(self);
        [_videoCoreSDK seekToTime:CMTimeMakeWithSeconds(currentTime, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = strongSelf->_videoCoreSDK.duration;
            if(CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
    }
}

- (void)addMaterialEffect {
    
    _backButton.hidden = YES;
    _publishButton.hidden = YES;
    
    if( [_videoCoreSDK isPlaying] )
        [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Subtitle:
//            [self ToolBarViewShowOhidden:YES];
            self.isAddingMaterialEffect = YES;
            break;
        default:
            break;
    }
//    _addedMaterialEffectView.hidden = YES;
//    [self ToolBarViewShowOhidden:NO];
}

- (void)addingStickerWithDuration:(float)addingDuration  captionId:(int ) captionId{
    NSMutableArray *arry = [[NSMutableArray alloc] initWithArray:subtitles];
    _videoCoreSDK.captions = arry;
    if(![_videoCoreSDK isPlaying]){
        _addEffectsByTimeline.trimmerView.isTiming = YES;
//        [self playVideo:YES];
    }
    [self addedMaterialEffectItemBtnAction:[addedMaterialEffectScrollView viewWithTag:captionId]];
}

- (void)cancelMaterialEffect {
    _backButton.hidden = NO;
    _publishButton.hidden = NO;
    self.isCancelMaterialEffect = YES;
    [self deleteMaterialEffect];
    self.isCancelMaterialEffect = NO;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    if (selecteFunction == RDAdvanceEditType_Subtitle) {
//        [self ToolBarViewShowOhidden:NO];
    }
}

- (void)deleteMaterialEffect {
    [self playVideo:NO];
    
    _backButton.hidden = NO;
    _publishButton.hidden = NO;
    
    if (!_isCancelMaterialEffect) {
        seekTime = _videoCoreSDK.currentTime;
    }
    
    if (_isCancelMaterialEffect) {
        seekTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start) + _addEffectsByTimeline.trimmerView.piantouDuration,TIMESCALE);
    }
    BOOL suc = [_addEffectsByTimeline.trimmerView deletedcurrentCaption];
    BOOL isAddedMaterialEffectScrollViewShow = NO;
    if(suc){
        NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
        switch (selecteFunction) {
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
            default:
                break;
        }
    }else{
        NSLog(@"删除失败");
    }
    float progress = CMTimeGetSeconds(seekTime)/_videoCoreSDK.duration;
    [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
    [self refreshAddMaterialEffectScrollView];
    selectedMaterialEffectItemIV.hidden = YES;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    self.isCancelMaterialEffect = NO;
    
    if (isAddedMaterialEffectScrollViewShow) {
//        _addedMaterialEffectView.hidden = NO;
//        [self ToolBarViewShowOhidden:YES];
    }else {
//        _addedMaterialEffectView.hidden = YES;
//        [self ToolBarViewShowOhidden:NO];
    }
//    [self ToolBarViewShowOhidden:NO];
}

- (void)updateMaterialEffect:(NSMutableArray *)newEffectArray
                newFileArray:(NSMutableArray *)newFileArray
                isSaveEffect:(BOOL)isSaveEffect
{
    _backButton.hidden = NO;
    _publishButton.hidden = NO;
    _isAddingMaterialEffect = NO;
    _addEffectsByTimeline.currentTimeLbl.hidden = NO;
    if (_videoCoreSDK.isPlaying) {
        [self playVideo:NO];
    }
    //    if (!cancelBtn.selected) {
    //        isModifiedMaterialEffect = YES;
    //    }
    if (!_isCancelMaterialEffect) {
        seekTime = _videoCoreSDK.currentTime;
    }
    float time = CMTimeGetSeconds(seekTime);
    if (time >= _videoCoreSDK.duration) {
        seekTime = kCMTimeZero;
    }
    self.addedMaterialEffectView.hidden = NO;
    switch (selecteFunction) {
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
//            [self ToolBarViewShowOhidden:NO];
            CMTime time = [_videoCoreSDK currentTime];
            [_videoCoreSDK filterRefresh:time];
            [_addEffectsByTimeline.trimmerView setProgress:(CMTimeGetSeconds(time)/_videoCoreSDK.duration) animated:NO];
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
//            _addedMaterialEffectView.hidden = YES;
//            [self ToolBarViewShowOhidden:NO];
        }else {
//            _addedMaterialEffectView.hidden = NO;
//            [self ToolBarViewShowOhidden:YES];
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
    {
        self.addedMaterialEffectView.hidden = NO;
    }
    
    [addedMaterialEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
    BOOL isNetSource = ((RDNavigationViewController *)self.navigationController).editConfiguration.subtitleResourceURL.length>0;
    NSInteger index = 0;
    for (int i = 0; i < arr.count; i++) {
        CaptionRangeView *view = arr[i];
        BOOL isHasMaterialEffect = NO;
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
                if (view.file.caption) {
                    isHasMaterialEffect = YES;
                }
                if (_isAddingMaterialEffect && selecteFunction == RDAdvanceEditType_Subtitle && view == _addEffectsByTimeline.trimmerView.currentCaptionView) {
                    index = view.file.captionId;
                }
                break;
            default:
                break;
        }
        if (isHasMaterialEffect) {
            RDAddItemButton *addedItemBtn = [RDAddItemButton buttonWithType:UIButtonTypeCustom];
            addedItemBtn.frame = CGRectMake((view.file.captionId-1) * 50, (44 - 40)/2.0, 40, 40);
            if (selecteFunction == RDAdvanceEditType_Subtitle ) {
                UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0/2.0, (40 - 25.0)/2.0, 25.0, 25.0)];
                if(isNetSource){
                    [imageView rd_sd_setImageWithURL:[NSURL URLWithString:view.file.netCover]];
                }else{
                    NSString *iconPath;
                    if (selecteFunction == RDAdvanceEditType_Subtitle) {
                        iconPath = [NSString stringWithFormat:@"%@/%@.png",kSubtitleIconPath,view.file.caption.imageName];
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
    if (selecteFunction == RDAdvanceEditType_Subtitle && _isAddingMaterialEffect && !_isEdittingMaterialEffect) {
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
//        _addedMaterialEffectView.hidden = NO;
//        [self ToolBarViewShowOhidden:YES];
    }
    else
    {
//        _addedMaterialEffectView.hidden = YES;
//        [self ToolBarViewShowOhidden:NO];
    }
}

- (void)addedMaterialEffectItemBtnAction:(UIButton *)sender {
    if (!selectedMaterialEffectItemIV.hidden && sender.tag == selectedMaterialEffectIndex)
        return;

    if (_videoCoreSDK.isPlaying) {
        [self playVideo:NO];
    }
    seekTime = _videoCoreSDK.currentTime;
    selectedMaterialEffectIndex = sender.tag;
    _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
    CGRect frame = selectedMaterialEffectItemIV.frame;
    frame.origin.x = sender.frame.origin.x + sender.bounds.size.width - frame.size.width + 6;
    selectedMaterialEffectItemIV.frame = frame;
    
    [_addEffectsByTimeline editAddedEffect];
    if (!selectedMaterialEffectItemIV.superview) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    selectedMaterialEffectItemIV.hidden = NO;
//    _addedMaterialEffectView.hidden = NO;
    self.isEdittingMaterialEffect = YES;
    self.isAddingMaterialEffect = NO;
    CMTime time = [_videoCoreSDK currentTime];
    [_videoCoreSDK filterRefresh:time];
    _backButton.hidden = NO;
    [self changePublicBtnTitle:YES];
    _publishButton.hidden = NO;
}


@end
