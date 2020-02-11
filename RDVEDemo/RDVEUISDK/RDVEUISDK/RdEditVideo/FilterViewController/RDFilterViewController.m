//
//  RDFilterViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/3.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//


#import "RDFilterViewController.h"
#import "ScrollViewChildItem.h"
#import "RDDownTool.h"
#import "RDVECore.h"
#import "UIImageView+RDWebCache.h"
#import "RDSVProgressHUD.h"
#import "CircleView.h"
#import "RDGenSpecialEffect.h"

#import "RDATMHud.h"
#import "RDNavigationViewController.h"
#import "RDExportProgressView.h"
#import "RDZSlider.h"
@interface RDFilterViewController ()<ScrollViewChildItemDelegate, RDVECoreDelegate,UIAlertViewDelegate,UIScrollViewDelegate>
{
    NSMutableArray          <RDScene *>*scenes;
    UIButton                *useToAllBtn;
    
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    
    float                   fheight;
    
    int                     currentlabelFilter;
    int                     currentFilterIndex;
    CMTime                  seekTime;
    
    BOOL                    isSeekTime;
    
    BOOL                    isglobalFilters;
}
@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)UIButton         *playButton;
//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;

@property(nonatomic,strong)RDATMHud         *hud;
@property (nonatomic, strong) RDExportProgressView *exportProgressView;

//新滤镜
@property (nonatomic, strong) UIView    * fileterNewView;
@property (nonatomic, strong) UIScrollView    *fileterLabelNewScroView;
@property (nonatomic, strong) UIScrollView    *fileterScrollView;

@property(nonatomic,strong)ScrollViewChildItem *originalItem;

@property(nonatomic,strong)RDZSlider        *filterProgressSlider;
@property(nonatomic,strong)UILabel          *percentageLabel;

@property(nonatomic,strong)UILabel          *currentTImeLabel;
@end

@implementation RDFilterViewController

-(void)seekTime:(CMTime) time
{
    isSeekTime = true;
    seekTime = time;
}

- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
//        _videoCoreSDK.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
        
        [self.view addSubview:_videoCoreSDK.view];
        scenes = [_videoCoreSDK getScenes];
//        [self.view insertSubview: belowSubview:self.playButton];
    }
    else
        [self initPlayer];
}


-(void)setVideoCoreSDK:(RDVECore *) core
{
    _videoCoreSDK = core;
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    if( !_videoCoreSDK )
        [self initPlayer];
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            CMTime time = _videoCoreSDK.currentTime;
//            [_videoCoreSDK seekToTime:_videoCoreSDK.currentTime];
        });
//        [self performSelector:@selector(videoPrepare) withObject:self afterDelay:0.1];
    }
}

-(void)videoPrepare
{
    [_videoCoreSDK prepare];
}

-(void)initUI
{
    [self.view addSubview:self.filterView];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    if(_exportProgressView){
        __block typeof(self) myself = self;
        [_videoCoreSDK cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    TICK;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    if( !_globalFilters )
    {
        isglobalFilters = false;
    }
    else
        isglobalFilters = true;
    
    currentlabelFilter = 0;
    
//    TOCK; //1
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc)
    {
        [self setFilters];
    }
//    TOCK; //2
    if( _exportSize.width == 0 || _exportSize.height == 0 )
        _exportSize = [RDHelpClass getEditSizeWithFile:_file];
//    TOCK; //3
    [self performSelector:@selector(initUI) withObject:self afterDelay:0.1];
//    [self.view addSubview:self.filterView];
//    TOCK; //4
//    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
#if isUseCustomLayer
    if (_file.fileType == kTEXTTITLE) {
        _file.imageTimeRange = CMTimeRangeMake(kCMTimeZero, _file.imageTimeRange.duration);
    }
#endif
//    TOCK; //5
    [self initChildView];
//    TOCK; //6
    [self.view addSubview:self.playButton];
//    TOCK; //7
    [self initToolBarView];
//    TOCK; //8
    [RDHelpClass animateView:self.filterView atUP:NO];
}



-(void)setFiltersAndPlayer
{
    [self setFilters];
//    [self initPlayer];
}

- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake(5, _videoCoreSDK.frame.origin.y + _videoCoreSDK.frame.size.height - 44, 44, 44);
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
        
        _currentTImeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWIDTH - 80 - 15, kPlayerViewOriginX + kPlayerViewHeight - fheight - _playButton.frame.size.height + (44-20)/2.0, 80, 20)];
        _currentTImeLabel.text = @"00:00.0";
        _currentTImeLabel.font = [UIFont systemFontOfSize:12];
        _currentTImeLabel.textAlignment = NSTextAlignmentRight;
        _currentTImeLabel.textColor = [UIColor whiteColor];
        [self.view addSubview:_currentTImeLabel];
    }
    return _playButton;
}

- (UIView *)filterView{
    if(!_filterView){
        fheight = 0;
        
        if( !_NewFilterSortArray )
        {
            _filterView = [UIView new];
            _filterView.frame = CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight);
            _filterView.backgroundColor = TOOLBAR_COLOR;
            
            useToAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            useToAllBtn.frame = CGRectMake(15, 0, 122, 35 );
            useToAllBtn.titleLabel.font = [UIFont systemFontOfSize:1];
            [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
            [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
            [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
            [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
            [useToAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
            [useToAllBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, useToAllBtn.frame.size.width - 40)];
            [useToAllBtn addTarget:self action:@selector(useToAllBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
            CGSize useToAllTranstionSize = [useToAllBtn.titleLabel sizeThatFits:CGSizeZero];
            useToAllBtn.frame = CGRectMake( 8, useToAllBtn.frame.origin.y, 140, useToAllBtn.frame.size.height);
            if ( !((RDNavigationViewController *)self.navigationController).isSingleFunc )
                [_filterView addSubview:useToAllBtn];
            
            _filterChildsView           = [UIScrollView new];
            
            float height =  _filterView.bounds.size.height - 50;
            if( height > 100 )
                height = 100;
            
            _filterChildsView.frame     = CGRectMake(0, 35 + ( (_filterView.bounds.size.height - 50) - 70 )/2.0, _filterView.frame.size.width, height );
            _filterChildsView.backgroundColor                   = [UIColor clearColor];
            _filterChildsView.showsHorizontalScrollIndicator    = NO;
            _filterChildsView.showsVerticalScrollIndicator      = NO;
            [_filterView addSubview:_filterChildsView];
            
            [_globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(self.filterChildsView.frame.size.height - 15)+10, 0, (self.filterChildsView.frame.size.height - 25), self.filterChildsView.frame.size.height)];
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
                [self.filterChildsView addSubview:item];
                [item setSelected:(idx == _file.filterIndex ? YES : NO)];
            }];
            
            _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
        }
        else{
            _filterView = [[UIView alloc] initWithFrame:CGRectMake(0,kPlayerViewOriginX + kPlayerViewHeight - fheight, kWIDTH, (kHEIGHT - (kPlayerViewOriginX + kPlayerViewHeight) - kToolbarHeight) + fheight)];
            _filterView.backgroundColor = TOOLBAR_COLOR;
            [self.view addSubview:_filterView];
            
            float height = (_filterView.frame.size.height - 40) > 120 ? 120 : 90 ;
            
            float useToAllTranstionWidth =  [RDHelpClass widthForString:RDLocalizedString(@"应用到所有", nil) andHeight:114 fontSize:14] + 50;
            useToAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            useToAllBtn.frame = CGRectMake(5, ( _filterView.frame.size.height*0.203 - 35 )/2.0 + _filterView.frame.size.height*( 0.337 + 0.462 ), useToAllTranstionWidth, 35 );
            useToAllBtn.titleLabel.font = [UIFont systemFontOfSize:14];
            [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
            [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
            [useToAllBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
            [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
            [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
            [useToAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -1, 0, 0)];
            [useToAllBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
            [useToAllBtn addTarget:self action:@selector(useToAllBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
            CGSize useToAllTranstionSize = [useToAllBtn.titleLabel sizeThatFits:CGSizeZero];
            
            if ( !((RDNavigationViewController *)self.navigationController).isSingleFunc )
                [_filterView addSubview:useToAllBtn];
            
            [_filterView addSubview:self.fileterNewView];
            
            if(!self.filterProgressSlider.superview)
                [_filterView addSubview:_filterProgressSlider ];
            _percentageLabel.hidden =  YES;
            float progressSliderHeight = self.filterView.frame.size.width - 35 - 30 - 105;
            _filterProgressSlider.frame = CGRectMake(105 + ( kWIDTH - 105 - progressSliderHeight  )/2.0, _filterView.frame.size.height*( 0.337 + 0.462 ) + (_filterView.frame.size.height*0.203 - 30)/2.0 + 5, progressSliderHeight, 30);
            useToAllBtn.frame =CGRectMake(5, ( _filterView.frame.size.height*0.203 - 35 )/2.0 + _filterView.frame.size.height*( 0.337 + 0.462 ) + 5, 120, 35 );
            
            if( !isglobalFilters )
            {
                float progressSliderHeight = self.filterView.frame.size.width - 100;
                
                _filterProgressSlider.frame = CGRectMake(50, _filterView.frame.size.height*( 0.337 + 0.462 ) + (_filterView.frame.size.height*0.203 - 30)/2.0 + 5, progressSliderHeight, 30);
            }
            
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
    for (int i = 0; i < _NewFiltersNameSortArray.count; i++) {
        NSArray * array = (NSArray *)_NewFiltersNameSortArray[i];
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
    self.fileterScrollView.delegate = self;
    
    btn.selected = YES;
    btn.font = [UIFont boldSystemFontOfSize:14];
//    [self scrollViewChildItemTapCallBlock:_originalItem];
}

-(void)scrollViewIndex:(int) fileterindex
{
    __block int index = 0;
    for (int i = 0; i < _NewFiltersNameSortArray.count; i++) {
        NSArray * array = (NSArray *)_NewFiltersNameSortArray[i];
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
        _fileterNewView = [[UIView alloc] initWithFrame:CGRectMake(0, fheight, kWIDTH, _filterView.frame.size.height*( 0.337 + 0.462 ))];
        [_filterView addSubview:_fileterNewView];
        
        _fileterLabelNewScroView  = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _filterView.frame.size.height*( 0.337 ))];
        
        _fileterLabelNewScroView.showsVerticalScrollIndicator  =NO;
        _fileterLabelNewScroView.showsHorizontalScrollIndicator = NO;
        
        [self scrollViewIndex:_file.filterIndex-1];
        int contentWidth = 0 + _fileterLabelNewScroView.frame.size.height*2.0/5.0 + 20;;
        for (int i = 0; _NewFilterSortArray.count > i; i++) {
            
            float ItemBtnWidth = [RDHelpClass widthForString:[_NewFilterSortArray[i] objectForKey:@"name"] andHeight:14 fontSize:14] + 25;
            
            UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(contentWidth, 0, ItemBtnWidth, _filterView.frame.size.height*( 0.337 ))];
            btn.font = [UIFont systemFontOfSize:14];
            [btn setTitle:[_NewFilterSortArray[i] objectForKey:@"name"] forState:UIControlStateNormal];
            [btn setTitleColor: [UIColor colorWithWhite:1.0 alpha:0.5]  forState:UIControlStateNormal];
            [btn setTitleColor:Main_Color forState:UIControlStateSelected];
            [btn addTarget:self action:@selector(filterLabelBtn:) forControlEvents:UIControlEventTouchUpInside];
            
            btn.tag = i;
            [_fileterLabelNewScroView addSubview:btn];
            btn.selected = NO;
            contentWidth += ItemBtnWidth;
            if( i == currentlabelFilter )
            {
                btn.font = [UIFont boldSystemFontOfSize:14];
                btn.selected = YES;
            }
        }
        _fileterLabelNewScroView.tag = 1000;
        
        UIButton *noBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _fileterLabelNewScroView.frame.size.height*3.0/7.0 + 20, _fileterLabelNewScroView.frame.size.height)];
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, _fileterLabelNewScroView.frame.size.height*4.0/7.0/2.0, _fileterLabelNewScroView.frame.size.height*3.0/7.0, _fileterLabelNewScroView.frame.size.height*3.0/7.0)];
        imageView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无@3x" Type:@"png"]];
        noBtn.tag                            = 100;
        [noBtn addTarget:self action:@selector(noBtn_onclik) forControlEvents:UIControlEventTouchUpInside];
        [noBtn addSubview:imageView];
        
        [_fileterLabelNewScroView addSubview:noBtn];
        
        _fileterLabelNewScroView.contentSize  = CGSizeMake(contentWidth+20, 0);
        {
            float fileterNewScroViewHeight = _filterView.frame.size.height * 0.462;
            _originalItem  = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(10, 0, fileterNewScroViewHeight - 20, fileterNewScroViewHeight)];
            _originalItem.backgroundColor        = TOOLBAR_COLOR;
//            _originalItem.itemIconView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无-选中@3x" Type:@"png"]];
            {
                _originalItem.itemIconView.backgroundColor = UIColorFromRGB(0x27262c);
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _originalItem.itemIconView.frame.size.width, _originalItem.itemIconView.frame.size.height)];
                label.text = RDLocalizedString(@"无", nil);
                label.tag = 1001;
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
            _originalItem.itemTitleLabel.text            =  RDLocalizedString(@"无滤镜", nil);
            _originalItem.tag                            = 0 + 1;
            _originalItem.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            [_originalItem setSelected:(0 == _file.filterIndex ? YES : NO)];
            [_originalItem setCornerRadius:5];
//            [_fileterNewView addSubview:_originalItem];
        }
        
        [_fileterNewView addSubview:_fileterLabelNewScroView];
        self.fileterScrollView.hidden = NO;
    }
    return _fileterNewView;
}

-(void)noBtn_onclik
{
    [self scrollViewChildItemTapCallBlock:_originalItem];
}

-( void )setNewFilterChildsView:( bool ) isYES atTypeIndex:( NSInteger ) tag
{
    if( tag == 0 )
    {
        [_originalItem setSelected:isYES];
        return;
    }
    
    for (UIView *subview in _fileterScrollView.subviews) {
        if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
            [(ScrollViewChildItem*)subview setSelected:NO];
    }
}

-(UIScrollView *)fileterScrollView
{
    if( !_fileterScrollView )
    {
        float fileterNewScroViewHeight = _filterView.frame.size.height * 0.462;
        _fileterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _fileterLabelNewScroView.frame.origin.y + _fileterLabelNewScroView.frame.size.height, kWIDTH, fileterNewScroViewHeight)];
        [_fileterNewView addSubview:_fileterScrollView];
        _fileterScrollView.showsVerticalScrollIndicator = NO;
        _fileterScrollView.showsHorizontalScrollIndicator = NO;
//        [_fileterScrollView addSubview:_originalItem];
        _fileterScrollView.tag = 1000;
    }
    else{
        for (UIView *subview in _fileterScrollView.subviews) {
            if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                
                if( subview != _originalItem )
                    [subview removeFromSuperview];
        }
    }
    __block float  height = _fileterScrollView.frame.size.height;
    __block float  width = _fileterScrollView.frame.size.width;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    NSString * str = nil;
    if (_NewFiltersNameSortArray.count > 0) {
        NSString *str = [_NewFilterSortArray[currentlabelFilter] objectForKey:@"name"];
        if( isEnglish )
            str = [str substringToIndex:1];
        NSArray * array = (NSArray *)_NewFiltersNameSortArray[ currentlabelFilter ];
        __block int index = 0;
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(height - 20 + 10 )  + 10, 0, (height - 20 ), height)];
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
            item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            
            item.itemTitleLabel.text = [NSString stringWithFormat:@"%@%d",str,idx+1];
            
            if( _file.filterIndex == (item.tag-1) )
                index = idx;
            
            if( (item.tag-1)  == _file.filterIndex )
            {
                [item setSelected:YES];
            }
            
            [item setCornerRadius:5];
            dispatch_async(dispatch_get_main_queue(), ^{
                [item setSelected:((item.tag-1) == _file.filterIndex ? YES : NO)];
                [_fileterScrollView addSubview:item];
            });
        }];
        
        float contentWidth = (height - 20 + 10 )*(array.count+1)+10;
        if( contentWidth <=  _fileterScrollView.frame.size.width )
        {
            contentWidth = _fileterScrollView.frame.size.width + 20;
        }
        
        _fileterScrollView.contentSize = CGSizeMake(contentWidth, 0);
        _fileterScrollView.delegate = self;
        
        float draggableX = _fileterScrollView.contentSize.width - width;
        if( draggableX >0 )
        {
            float x = (height + 10 ) *  index;
            
            if( x > draggableX )
                x = draggableX;
            
            _fileterScrollView.contentOffset = CGPointMake(x, 0);
        }
//    });
    }
    return _fileterScrollView;
}

//滤镜进度条
- (RDZSlider *)filterProgressSlider{
    if(!_filterProgressSlider){
        float height = (_filterView.frame.size.height - 40) > 120 ? 120 : 90 ;
        
        if ( !((RDNavigationViewController *)self.navigationController).isSingleFunc )
            _filterProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(132, ( (40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 30 )/2.0 + 35 ,  self.filterView.frame.size.width - 85 - 65, 30)];
        else
            _filterProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(65, ( (40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 30 )/2.0 + 35 ,  self.filterView.frame.size.width - 65 - 65, 30)];
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
        [_filterProgressSlider setValue:1.0];
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
        
        [_filterProgressSlider setValue:_file.filterIntensity];
        
        float percent = 1.0*100.0;
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int)percent];
        [_filterView addSubview:_percentageLabel];
    }
    return _filterProgressSlider;
}
//滤镜强度 滑动进度条
- (void)filterscrub{
    CGFloat current = _filterProgressSlider.value;
    float percent = current*100.0;
    if( !_NewFilterSortArray )
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
    else
    {
        _percentageLabel.hidden = NO;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.frame = CGRectMake(current*_filterProgressSlider.frame.size.width+_filterProgressSlider.frame.origin.x - _percentageLabel.frame.size.width/2.0, _filterProgressSlider.frame.origin.y - _percentageLabel.frame.size.height + 5, _percentageLabel.frame.size.width, _percentageLabel.frame.size.height);
        _percentageLabel.text = [NSString stringWithFormat:@"%d%",(int)percent];
    }
    
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            asset.filterIntensity = current;
        }];
    }];
    _file.filterIntensity = current;
    [_videoCoreSDK refreshCurrentFrame];
}

- (void)filterendScrub{
    CGFloat current = _filterProgressSlider.value;
    float percent = current*100.0;
    if( !_NewFilterSortArray )
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
    else
    {
        _percentageLabel.hidden = YES;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.frame = CGRectMake(current*_filterProgressSlider.frame.size.width+_filterProgressSlider.frame.origin.x - _percentageLabel.frame.size.width/2.0, _filterProgressSlider.frame.origin.y - _percentageLabel.frame.size.height + 5, _percentageLabel.frame.size.width, _percentageLabel.frame.size.height);
        _percentageLabel.text = [NSString stringWithFormat:@"%d%",(int)percent];
    }
        [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            asset.filterIntensity = current;
        }];
    }];
    _file.filterIntensity = current;
    [_videoCoreSDK refreshCurrentFrame];
}

- (void)refreshFilterChildItem{
    __weak typeof(self) myself = self;
    [_globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

- (void)initPlayer {
    scenes = [NSMutableArray array];
    RDScene *scene = [[RDScene alloc] init];
    
    VVAsset* vvasset = [[VVAsset alloc] init];
    vvasset.url = _file.contentURL;
    
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
    
    if(_file.fileType == kFILEVIDEO){
        vvasset.type = RDAssetTypeVideo;
        vvasset.videoActualTimeRange = _file.videoActualTimeRange;
//        [RDVECore assetMetadata:_file.contentURL];
        
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
    
    if(!_videoCoreSDK){
        _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                               APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                              LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                               videoSize:_exportSize
                                                     fps:kEXPORTFPS
                                              resultFail:^(NSError *error) {
                                                  NSLog(@"initSDKError:%@", error.localizedDescription);
                                              }];
    }
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        _videoCoreSDK.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kPlayerViewHeight);
    }else {
        _videoCoreSDK.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
    }
    _videoCoreSDK.delegate = self;
    [_videoCoreSDK setScenes:scenes];
    [_videoCoreSDK build];
    [self.view insertSubview:_videoCoreSDK.view belowSubview:self.playButton];
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"滤镜", nil);
    titleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    titleLbl.font = [UIFont boldSystemFontOfSize:17.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        toolBarView.backgroundColor = [UIColor blackColor];
        toolBarView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44);
        
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回默认_"] forState:UIControlStateNormal];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_返回点击_"] forState:UIControlStateHighlighted];
        
        finishBtn.frame = CGRectMake(kWIDTH - 64, 0, 64, 44);
        finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [finishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [finishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    }else {
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        finishBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    }
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    [RDHelpClass animateView:toolBarView atUP:NO];
}


- (void)tapPlayButton{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)playVideo:(BOOL)play{
    if(play){
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
    }else{
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }
}

- (void)useToAllBtnOnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
}

- (void)back{
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }else {
//        [_videoCoreSDK stop];
//        [_videoCoreSDK.view removeFromSuperview];
//        _videoCoreSDK.delegate = nil;
//        _videoCoreSDK = nil;
        [self dismissViewControllerAnimated:NO completion:nil];
//        [self.navigationController popViewControllerAnimated:NO];
    }
    //    [self dismissViewControllerAnimated:YES completion:^{
    //
    //    }];
}
/**保存
 */
- (void)save{
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        [self exportMovie];
    }else{
//        [_videoCoreSDK stop];
//        [_videoCoreSDK.view removeFromSuperview];
//        _videoCoreSDK.delegate = nil;
//        _videoCoreSDK = nil;
        if (_changeFilterFinish) {
            VVAsset *asset = [[scenes firstObject].vvAsset firstObject];
            _changeFilterFinish(_file.filterIndex, asset.filterType,asset.filterIntensity, asset.filterUrl, useToAllBtn.selected);
        }
        [self dismissViewControllerAnimated:NO completion:nil];
//        [self.navigationController popViewControllerAnimated:NO];
    }
//    [self dismissViewControllerAnimated:YES completion:^{
//
//    }];
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        
//        [_videoCoreSDK filterRefresh:seekTime];
        
        if( isSeekTime )
        {
            isSeekTime = false;
            if( CMTimeGetSeconds(seekTime) >0 )
                [_videoCoreSDK seekToTime:seekTime];
            _currentTImeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(seekTime), _videoCoreSDK.duration)];
            seekTime = kCMTimeZero;
        }
        
        [RDSVProgressHUD dismiss];
    }
}
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    
    if([_videoCoreSDK isPlaying]){
        _currentTImeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), _videoCoreSDK.duration)];
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
    [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
}

/**点击播放器
 */
- (void)tapPlayerView{
    [self playVideo:![_videoCoreSDK isPlaying]];
}

#pragma mark - scrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item {
    //滤镜
    if( _fileterScrollView )
        [self setNewFilterChildsView:NO atTypeIndex:_file.filterIndex];
    
    
    __weak typeof(self) myself = self;
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
        NSDictionary *obj = self.filtersName[item.tag - 1];
        NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
        if(item.tag-1 == 0){
            if( _fileterScrollView )
            {
                [self setNewFilterChildsView:NO atTypeIndex:_file.filterIndex];
            }
            else
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:_file.filterIndex+1]) setSelected:NO];
            [item setSelected:YES];
            [self refreshFilter:item.tag - 1];
            if(![_videoCoreSDK isPlaying]){
                [_videoCoreSDK refreshCurrentFrame];
            }
            return ;
        }
        
        if( filterPath )
        {
            NSString *itemPath = [[[filterPath stringByAppendingPathComponent:obj[@"name"]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
            if([[NSFileManager defaultManager] fileExistsAtPath:itemPath]){
                if( _fileterScrollView )
                {
                    [self setNewFilterChildsView:NO atTypeIndex:_file.filterIndex];
                }
                else
                    [((ScrollViewChildItem *)[_filterChildsView viewWithTag:_file.filterIndex+1]) setSelected:NO];
                [item setSelected:YES];
                [self refreshFilter:item.tag - 1];
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
                [self setNewFilterChildsView:NO atTypeIndex:_file.filterIndex];
            }
            else
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:_file.filterIndex+1]) setSelected:NO];
            
//            ddprogress.progressColor = Main_Color;
//            ddprogress.progressWidth = 2.f;
//            ddprogress.progressBackgroundColor = [UIColor clearColor];
//            [item addSubview:ddprogress];
            [item addSubview:progress];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RDDownTool *tool = [[RDDownTool alloc] initWithURLPath:obj[@"file"] savePath:itemPath];
                tool.Progress = ^(float numProgress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                       if( (numProgress >= 0.0) && (numProgress <= 1.0)   )
                        {
                            [progress.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if( [obj isKindOfClass:[UILabel class]] )
                                {
                                    UILabel * label = (UILabel*)obj;
                                    if(label.tag == 1)
                                    {
                                        label.text = [NSString stringWithFormat:@"%d%%", (int)(numProgress*100.0)];
                                    }
                                }
                            }];
                        }
                    });
                };
                
                tool.Finish = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [ddprogress removeFromSuperview];
                        [progress removeFromSuperview];
                        item.downloading = NO;
                        if([myself downLoadingFilterCount]>=1){
                            return ;
                        }
                        if( _fileterScrollView )
                        {
                            for (UIView *subview in _fileterScrollView.subviews) {
                                if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                                    [(ScrollViewChildItem*)subview setSelected:NO];
                            }
                        }
                        else{
                            [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if([obj isKindOfClass:[ScrollViewChildItem class]]){
                                    
                                    [(ScrollViewChildItem *)obj setSelected:NO];
                                }
                            }];
                        }
                        
                        [item setSelected:YES];
                        [myself refreshFilter:item.tag - 1];
                        if(![_videoCoreSDK isPlaying]){
                            [_videoCoreSDK refreshCurrentFrame];
                        }
                    });
                };
                [tool start];
            });
        }
    }else{
        if( _fileterScrollView )
        {
            [self setNewFilterChildsView:NO atTypeIndex:_file.filterIndex];
        }
        else
            [((ScrollViewChildItem *)[_filterChildsView viewWithTag:_file.filterIndex+1]) setSelected:NO];
        [item setSelected:YES];
        [self refreshFilter:item.tag - 1];
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK refreshCurrentFrame];
        }
    }
}

- (void)refreshFilter:(NSInteger)filterIndex {
    _file.filterIndex = filterIndex;
    RDFilter* filter = _globalFilters[filterIndex];
    [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            if (filter.type == kRDFilterType_LookUp) {
                asset.filterType = VVAssetFilterLookup;
            }else if (filter.type == kRDFilterType_ACV) {
                asset.filterType = VVAssetFilterACV;
            }else {
                asset.filterType = VVAssetFilterEmpty;
            }
            asset.filterIntensity = 1.0;
            if (filter.filterPath.length > 0) {
                asset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }];
    }];
    [_filterProgressSlider setValue:1.0];
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

- (void)dealloc {
    NSLog(@"%s", __func__);
}


#pragma mark- 导出
- (void)setFilters{
    _globalFilters = [NSMutableArray array];
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
    UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
    
    NSString *appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if([lexiu currentReachabilityStatus] != RDNotReachable && nav.editConfiguration.filterResourceURL.length>0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary * dic = [RDHelpClass classificationParams:@"filter2" atAppkey: appKey atURl:editConfig.netMaterialTypeURL];
            if( !dic )
            {
                NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                            appkey:appKey
                                                                           urlPath:editConfig.filterResourceURL];
                if ([filterList[@"code"] intValue] == 0) {
                    _filtersName = [filterList[@"data"] mutableCopy];
                    
                    NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                    if(appKey.length > 0)
                        [itemDic setObject:appKey forKey:@"appkey"];
                    [itemDic setObject:@"" forKey:@"cover"];
                    [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                    [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                    [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                    [_filtersName insertObject:itemDic atIndex:0];
                }
            }
            else
            {
                _NewFilterSortArray = [NSMutableArray arrayWithArray:dic];
                _NewFiltersNameSortArray = [NSMutableArray new];
                for (int i = 0; i < _NewFilterSortArray.count; i++) {
                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    [params setObject:@"filter2" forKey:@"type"];
                    [params setObject:[_NewFilterSortArray[i] objectForKey:@"id"]  forKey:@"category"];
                    [params setObject:[NSString stringWithFormat:@"%d" ,0] forKey: @"page_num"];
                    NSDictionary *dic2 = [RDHelpClass getNetworkMaterialWithParams:params
                                                                            appkey:appKey urlPath:editConfig.effectResourceURL];
                    if(dic2 && [[dic2 objectForKey:@"code"] integerValue] == 0)
                    {
                        NSMutableArray * currentStickerList = [dic2 objectForKey:@"data"];
                        [_NewFiltersNameSortArray addObject:currentStickerList];
                    }
                    else
                    {
                        NSString * message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                    }
                }
                _filtersName = [NSMutableArray new];
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(appKey.length > 0)
                    [itemDic setObject:appKey forKey:@"appkey"];
                [itemDic setObject:@"" forKey:@"cover"];
                [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                [_filtersName addObject:itemDic];
                
                for (int i = 0; _NewFiltersNameSortArray.count > i; i++) {
                    [_filtersName addObjectsFromArray:_NewFiltersNameSortArray[i]];
                }
            }
            
            
            
                NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:filterPath]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:filterPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                [_filtersName enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
                    [_globalFilters addObject:filter];
                    [self AdjGlobalFilters:filter atIndex:_globalFilters.count - 1];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (((RDNavigationViewController *)self.navigationController).isSingleFunc)
                        //                        [self.view addSubview:self.filterView];
                        if( _NewFilterSortArray )
                        {
                            [self filterLabelBtn:[_fileterLabelNewScroView viewWithTag:0]];
                        }
                        else
                        {
                            _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
                            
                        }

                });
        });
    }else{
        _filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        [_filtersName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            RDFilter* filter = [RDFilter new];
            if ([obj isEqualToString:@"原始"]) {
                filter.type = kRDFilterType_YuanShi;
            }
            else{
                filter.type = kRDFilterType_LookUp;
                filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"lookupFilter/%@",obj] Type:@"png"];
            }
            filter.name = obj;
            [_globalFilters addObject:filter];
            
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
            [self AdjGlobalFilters:filter atIndex:_globalFilters.count - 1];
        }];
        if (((RDNavigationViewController *)self.navigationController).isSingleFunc)
//            [self.view addSubview:self.filterView];
        _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    }
    
}

-(void)AdjGlobalFilters:(RDFilter *) obj atIndex:(NSUInteger) idx
{
    dispatch_async(dispatch_get_main_queue(), ^{
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(self.filterChildsView.frame.size.height - 15)+10, 0, (self.filterChildsView.frame.size.height - 25), self.filterChildsView.frame.size.height)];
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
            [self.filterChildsView addSubview:item];
            [item setSelected:(idx == _file.filterIndex ? YES : NO)];
        
        _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    });
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

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
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
        default:
            break;
    }
}

#pragma mark- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( scrollView == _fileterScrollView )
    {
        if( _fileterScrollView.contentOffset.x > (_fileterScrollView.contentSize.width - _fileterScrollView.frame.size.width + KScrollHeight) )
        {
            if(  currentlabelFilter <  (_NewFiltersNameSortArray.count - 1)  )
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
