//
//  RDAdjustViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/3.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAdjustViewController.h"
#import "RDVECore.h"
#import "RDSVProgressHUD.h"
#import "RDZSlider.h"
#import "RDGenSpecialEffect.h"
#import "RDATMHud.h"
#import "RDExportProgressView.h"

@interface RDAdjustViewController ()<RDVECoreDelegate,UIAlertViewDelegate>
{
    UIButton                        *useToAllBtn;
    
    NSMutableArray<UIImageView *>   *TrackImageArray;        //调色显示图片
    NSMutableArray<NSString *>      *InitProgressArray;         //调色初始值数组
    NSMutableArray<NSString *>      *ProgressInitArray;         //调色默认值
    NSMutableArray<UISlider *>      *SliderArray;               //调色滚动条数组
    UIScrollView                    *AdjusetScrollView;         //调色
    
    NSMutableArray<RDScene *>       *scenes;
    
    float                           currentFontSize;                     //显示当前修改的字体大小
    UILabel                         *currentValueLbl;                     //显示正在修改的数值
    
    UIButton                        *ContrastBtn;               //对比按钮
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    
    CMTime                  seekTime;
    bool                    _isCore;
}

@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)UIButton         *playButton;
@property(nonatomic       )UIAlertView      *commonAlertView;
@property (nonatomic, strong) RDATMHud *hud;

@property (nonatomic, strong) RDExportProgressView *exportProgressView;

@property (nonatomic,strong)UIScrollView    *featuresScroll;

@end

@implementation RDAdjustViewController
-(void)seekTime:(CMTime) time
{
    seekTime = time;
}
#pragma mark--提示
-(void)ArerShow:(NSString *)str atValue:(NSString *) strValue
{
    if(currentValueLbl != nil)
    {
        if( strValue )
            currentValueLbl.text = [NSString stringWithFormat:@"%@ %@",str,strValue];
        else
            currentValueLbl.text = str;
        currentValueLbl.hidden = NO;
    }
    else
    {
        
        currentValueLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 80)/2.0, 0, 80, 20)];
        currentValueLbl.textAlignment = NSTextAlignmentCenter;
        currentValueLbl.textColor = [UIColor whiteColor];
        //阴影颜色
        currentValueLbl.layer.shadowColor = [UIColor blackColor].CGColor;
        //阴影偏移量
        currentValueLbl.layer.shadowOffset = CGSizeMake(0, 1);
        //阴影不透明度
        currentValueLbl.layer.shadowOpacity = 0.5;
        //阴影半径
        currentValueLbl.layer.shadowRadius = 2;
        if( strValue != nil )
            currentValueLbl.text = strValue;
        currentValueLbl.font = [UIFont systemFontOfSize:currentFontSize];
        [AdjusetScrollView addSubview:currentValueLbl];
        
    }
}
#pragma mark--关闭提示
- (void)performDismiss{
    currentValueLbl.hidden = YES;
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
    
    if( _videoCoreSDK )
    {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
////            [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
//            [_videoCoreSDK refreshCurrentFrame];
//        });
    }
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
    currentFontSize = 12;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX+kPlayerViewHeight, kWIDTH, kHEIGHT - (kPlayerViewOriginX+kPlayerViewHeight))];
    imageView.backgroundColor =  TOOLBAR_COLOR;
    [self.view addSubview:imageView];
    
    _exportSize = [RDHelpClass getEditSizeWithFile:_file];
    [self.view addSubview:self.playButton];
//    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
#if isUseCustomLayer
    if (_file.fileType == kTEXTTITLE) {
        _file.imageTimeRange = CMTimeRangeMake(kCMTimeZero, _file.imageTimeRange.duration);
    }
#endif
//    [self initPlayer];
    [self initChildView];
    
    
    
    [self initBottomView];
    [self initAdjustScrollView];
    [self initToolBarView];
    [RDHelpClass animateView: AdjusetScrollView atUP:NO];
}
- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
        [self.view insertSubview:_videoCoreSDK.view belowSubview:_playButton];
        scenes = [_videoCoreSDK getScenes];
//        [self.view insertSubview: belowSubview:self.playButton];
    }
    else
        [self initPlayer];
}

-(void)setVideoCoreSDK:(RDVECore *) core
{
    if( core )
        _isCore = true;
    _videoCoreSDK = core;
}


- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"调色", nil);
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
#pragma mark-调色 对应的控件 滚动条 初始化
-(void)initAdjustScrollView
{
    AdjusetScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 110 - kToolbarHeight , kWIDTH,110)];
    AdjusetScrollView.showsHorizontalScrollIndicator = NO;
    AdjusetScrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:AdjusetScrollView];
    
    ProgressInitArray = [NSMutableArray array];
    SliderArray = [NSMutableArray array];
    InitProgressArray = [NSMutableArray array];
    TrackImageArray = [NSMutableArray array];
    
    _featuresScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20+30, kWIDTH, 60)];
    _featuresScroll.showsVerticalScrollIndicator = NO;
    _featuresScroll.showsHorizontalScrollIndicator = NO;
    float toolItemBtnWidth = MAX(_featuresScroll.frame.size.width/5, 60 + 5);
    toolItemBtnWidth -= 10;
    _featuresScroll.contentSize = CGSizeMake(toolItemBtnWidth*7 + 25, 0);
    [AdjusetScrollView addSubview:_featuresScroll];
    
//    [self initBtn:0 atString:@"还原"];
    
    //亮度
    [self initBtn:0 atString:@"亮度"];
    [self InitSliberValue:Adjust_Brightness
                  atValue:_file.brightness
              atInitValue:0.0
              atFileValue:_file.brightness
                   atName:@"亮度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
//    SliderArray[SliderArray.count-1].hidden = NO;
    
    
    //对比度
    [self initBtn:1 atString:@"对比度"];
    [self InitSliberValue:Adjust_Contrast
                  atValue:(_file.contrast - 1.0)
              atInitValue:1.0 - 1.0
              atFileValue:_file.contrast
                   atName:@"对比度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    //饱和度
    [self initBtn:2 atString:@"饱和度"];
    [self InitSliberValue:Adjust_Saturation
                  atValue:(_file.saturation/2.0) - 0.5
              atInitValue:(float)( 1.0 /2.0) - 0.5
              atFileValue:_file.saturation
                   atName:@"饱和度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    // 锐度
    [self initBtn:3 atString:@"锐度"];
    [self InitSliberValue:Adjust_Sharpness
                  atValue:(_file.sharpness + 4.0)/8.0 - 0.5
              atInitValue:(float)(0.0 + 4.0)/8.0 - 0.5
              atFileValue:_file.sharpness
                   atName:@"锐度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    // 色温
    [self initBtn:4 atString:@"色温"];
    [self InitSliberValue:Adjust_WhiteBalance
                  atValue:(_file.whiteBalance + 1.0)/2.0 - 0.5
              atInitValue:(float)(0.0 + 1.0)/2.0 - 0.5
              atFileValue:_file.whiteBalance
                   atName:@"色温" atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    //暗角
    [self initBtn:5 atString:@"暗角"];
    [self InitSliberValue:Adjust_Vignette
                  atValue:_file.vignette
              atInitValue:0.0
              atFileValue:_file.vignette
                   atName:@"暗角"
               atMaxValue:1.0
               atMinValue:0.0
               atIsMiddle:NO];
    
    AdjusetScrollView.contentSize=  CGSizeMake(0, 110);
    
    [self clickToolItemBtn:[_featuresScroll viewWithTag:0]];
}

#pragma mark-滑杆控件初始化
-(void)InitSliberValue:(AdjustType) adjustType atValue:(float) value atInitValue:(float) InitValue atFileValue:(float) flieValue atName:(NSString *) name atMaxValue:(float) MaximumValue atMinValue:(float) MinValue atIsMiddle:(BOOL) IsMiddle
{
    NSString * str = @"选中";
    if( value == InitValue )
        str = @"默认";
    
    
    
    [InitProgressArray addObject:[NSString stringWithFormat:@"%.1f",flieValue] ];
    [ ProgressInitArray addObject: [NSString stringWithFormat:@"%.1f",InitValue] ];
    [SliderArray addObject:[self InitSlider:adjustType atMaxValue:MaximumValue atMinValue:MinValue atValue:value
                                    atImage:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@%@@3x",name,str] Type:@"png"] atIsMiddle:IsMiddle atHeight:AdjusetScrollView.bounds.size.height/2.5]];
}

-(void)clickToolItemBtn:(UIButton *) btn
{
    
    [SliderArray enumerateObjectsUsingBlock:^(UISlider * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.hidden = YES;
        
    }];
    [TrackImageArray enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.hidden = YES;
        
    }];
//    if( btn.tag == 0 )
//    {
//        [self SetReduction];
//    }
//    else
    {
        int i = btn.tag;
        SliderArray[i].hidden = NO;
        TrackImageArray[i].hidden = NO;
    }
    
    [_featuresScroll.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == btn.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

-(void)initBtn:(int) idx atString:(NSString *) title
{
    float toolItemBtnWidth = MAX(_featuresScroll.frame.size.width/5, 60 + 5);
    toolItemBtnWidth -= 10;
    
    UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    toolItemBtn.tag = idx;
    toolItemBtn.backgroundColor = [UIColor clearColor];
    toolItemBtn.exclusiveTouch = YES;
    toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth + 25, 0, toolItemBtnWidth, _featuresScroll.frame.size.height);
    [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
    NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@默认@3x", title] Type:@"png"];
    [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@选中@3x", title] Type:@"png"];
    [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
    [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
    [toolItemBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
    [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
    [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
    [_featuresScroll addSubview:toolItemBtn];
}

#pragma mark-设置滚动条设置
-(UISlider *)InitSlider:(int) index atMaxValue:(float) MaximumValue atMinValue:(float) MinValue atValue:(float) value atImage:(NSString *) Image atIsMiddle:(BOOL) IsMiddle atHeight:(float) height
{
    RDZSlider * slider = [[RDZSlider alloc] init];
    slider.frame = CGRectMake( 40, 20, kWIDTH - 80, 30);
    slider.layer.cornerRadius = 2.0;
    slider.layer.masksToBounds = YES;
    slider.maximumValue = MaximumValue;
    slider.minimumValue = MinValue;
    slider.value = value;
    slider.tag = index;
    UIImage *theImage = nil;
    
    
    
    
    slider.hidden = YES;
    
    if( value == [ProgressInitArray[slider.tag] floatValue] )
       theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]];
    else
       theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球2@3x" Type:@"png"]];
    
    [slider setThumbImage:theImage forState:UIControlStateNormal];
    if( IsMiddle )
        [slider setMinimumTrackImage: [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道1@1x" Type:@"png"]] forState:UIControlStateNormal];
    else
        [slider setMinimumTrackImage: [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道2@1x" Type:@"png"]] forState:UIControlStateNormal];
    
    [slider setMaximumTrackImage: [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道1@1x" Type:@"png"]] forState:UIControlStateNormal];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    //[slider setThumbImage: [UIImage imageNamed: forState:UIControlStateHighlighted];
    //滑块拖动时的事件
    //[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    //滑动拖动后的事件
    //[slider addTarget:self action:@selector(ChangeSlider:) forControlEvents:UIControlEventValueChanged];
    
    [slider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    [AdjusetScrollView addSubview:slider];
    
    UIImageView * imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake( slider.frame.size.width/2.0 ,(slider.frame.size.height-3.0)/2.0, 0.1, 0.1)];
    imageView1.backgroundColor = Main_Color;
    imageView1.hidden = YES;
    //    imageView1.image = [UIImage imageNamed: [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道2@1x" Type:@"png"]];
    [TrackImageArray addObject:imageView1];
    [AdjusetScrollView addSubview:imageView1];
    
    if(IsMiddle)
    {
        if( slider.value <= 0.0 )
        {
            float with = slider.frame.size.width/2.0 - (slider.frame.size.width + 38)*( (slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue) ) ;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3) ];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0,0, 3)];
            }
            
        }
        else
        {
            float with = (slider.frame.size.width  - 19 )*((slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue)) - slider.frame.size.width/2.0;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3)];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, 0, 3)];
            }
        }
    }
    
    return slider;
}

- (UIButton *)playButton{
    if(!_playButton){
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = [UIColor clearColor];
        _playButton.frame = CGRectMake(5, kHEIGHT - 35 - 110 - kToolbarHeight - 44 - 2.5, 44, 44);

        [_playButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (void)initBottomView {
    if (!((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        useToAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        useToAllBtn.frame = CGRectMake(60, kHEIGHT - 35 - 110 - kToolbarHeight, 120, 35 );
        useToAllBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
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
        useToAllBtn.frame = CGRectMake( 64 , useToAllBtn.frame.origin.y, 120, useToAllBtn.frame.size.height);
        [self.view addSubview:useToAllBtn];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10 + 50 + 4.5, useToAllBtn.frame.origin.y + ( 35 - 18.0 )/2.0, 1, 18.0)];
        label.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [self.view addSubview:label];
    }
    
    ContrastBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    ContrastBtn.frame = CGRectMake(kWIDTH - (64 + 15), kHEIGHT - 35 - 110 - kToolbarHeight + ( 35 - 28 )/2.0, 64, 28);
    [ContrastBtn setTitle:RDLocalizedString(@"toning_compare", nil) forState:UIControlStateNormal];
    [ContrastBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [ContrastBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateHighlighted];
    ContrastBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    ContrastBtn.layer.cornerRadius = 28/2.0;
    ContrastBtn.layer.borderColor = UIColorFromRGB(0x626267).CGColor;
    ContrastBtn.layer.borderWidth = 1.0;
    [ContrastBtn addTarget:self action:@selector(Contrast_Btn_click) forControlEvents:UIControlEventTouchDown];
    [ContrastBtn addTarget:self action:@selector(Contrast_Btn_Release) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.view addSubview:ContrastBtn];
    
    UIButton * reductionBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, kHEIGHT - 35 - 110 - kToolbarHeight + ( 35 - 28 )/2.0, 50, 28)];
    reductionBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [reductionBtn setTitle:RDLocalizedString(@"还原", nil) forState:UIControlStateNormal];
    [reductionBtn setTitleColor:UIColorFromRGB(0xbebebe) forState:UIControlStateNormal];
    [reductionBtn setTitleColor:Main_Color  forState:UIControlStateHighlighted];
    [reductionBtn addTarget:self action:@selector(SetReduction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reductionBtn];
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
    _videoCoreSDK.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kHEIGHT - 35 - 110 - kToolbarHeight - kPlayerViewOriginX);
    _videoCoreSDK.view.backgroundColor = [UIColor blackColor];
    _videoCoreSDK.delegate = self;
    [_videoCoreSDK setScenes:scenes];
    [_videoCoreSDK build];
    [self.view insertSubview:_videoCoreSDK.view belowSubview:_playButton];
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
    //亮度
    _file.brightness = [InitProgressArray[0] floatValue];
    //对比度
    _file.contrast = [InitProgressArray[1] floatValue];
    //饱和度
    _file.saturation = [InitProgressArray[2] floatValue];
    // 锐度
    _file.sharpness = [InitProgressArray[3] floatValue];
    // 色温
    _file.whiteBalance = [InitProgressArray[4] floatValue];
    //暗角
    _file.vignette = [InitProgressArray[5] floatValue];
    if( !_isCore )
    {
        [_videoCoreSDK stop];
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK.delegate = nil;
        _videoCoreSDK = nil;
    }
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}
#pragma mark-还原设置
-( void )SetReduction
{
    //亮度
    [SliderArray[0] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[0] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    //对比度
    [SliderArray[1] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[1] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    //饱和度
    [SliderArray[2] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[2] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    // 锐度
    [SliderArray[3] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[3] setFrame:CGRectMake( 1,1, 0.1, 0.1) ];
    // 色温
    [SliderArray[4] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[4] setFrame:CGRectMake( 1,1, 0.1, 0.1) ];
    //暗角
    [SliderArray[5] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[5] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    
    //亮度
    SliderArray[0].value  = [ProgressInitArray[0] floatValue];
    _file.brightness = SliderArray[0].value;
    //对比度
    SliderArray[1].value  = [ProgressInitArray[1] floatValue];
    _file.contrast = (SliderArray[1].value + 1.0);
    //饱和度
    SliderArray[2].value  = [ProgressInitArray[2] floatValue];
    _file.saturation = (SliderArray[2].value+0.5) * 2.0;
    // 锐度
    SliderArray[3].value  = [ProgressInitArray[3] floatValue];
    _file.sharpness = (SliderArray[3].value + 0.5)*8.0 - 4.0;
    // 色温
    SliderArray[4].value  = [ProgressInitArray[4] floatValue];
    _file.whiteBalance = (SliderArray[4].value + 0.5)*2.0 - 1.0;
    //暗角
    SliderArray[5].value  = [ProgressInitArray[5] floatValue];
    _file.vignette = SliderArray[5].value;
    
    [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            //亮度
            asset.brightness = self->_file.brightness;
            //对比度
            asset.contrast = self->_file.contrast;
            //饱和度
            asset.saturation = self->_file.saturation;
            // 锐度
            asset.sharpness = self->_file.sharpness;
            // 色温
            asset.whiteBalance = self->_file.whiteBalance;
            //暗角
            asset.vignette = self->_file.vignette;
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
//            [self playVideo:YES];
        }
    });
}

#pragma mark-调色 事件
#pragma mark-还原按钮事件
-(void)Reduction_Btn
{
    [self initCommonAlertViewWithTitle:RDLocalizedString(@"确认要重置吗?",nil)
                               message:@""
                     cancelButtonTitle:RDLocalizedString(@"取消",nil)
                     otherButtonTitles:RDLocalizedString(@"确定",nil)
                          alertViewTag:1];
}
#pragma mark-对比按钮事件
#pragma mark--点击事件
-(void)Contrast_Btn_click
{
    
    [self ArerShow:RDLocalizedString(@"原始效果",nil) atValue:nil];
    
    [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            //亮度
            asset.brightness    =   ([self->ProgressInitArray[0] floatValue]);
            //对比度
            asset.contrast      =   ([self->ProgressInitArray[1] floatValue] + 1.0);
            //饱和度
            asset.saturation    =   ([self->ProgressInitArray[2] floatValue]+0.5) * 2.0;
            // 锐度
            asset.sharpness     =   ([self->ProgressInitArray[3] floatValue] + 0.5)*8.0 - 4.0;
            // 色温
            asset.whiteBalance  =   ([self->ProgressInitArray[4] floatValue] + 0.5)*2.0 - 1.0;
            //暗角
            asset.vignette      =   ([self->ProgressInitArray[5] floatValue]);
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
//            [self playVideo:YES];
        }
    });
}
#pragma mark--松开事件
-(void)Contrast_Btn_Release
{
    
    [self performDismiss];
    [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            //亮度
            asset.brightness    =   (self->SliderArray[0].value);
            //对比度
            asset.contrast      =   (self->SliderArray[1].value + 1.0);
            //饱和度
            asset.saturation    =   (self->SliderArray[2].value+0.5) * 2.0 ;
            // 锐度
            asset.sharpness     =   (self->SliderArray[3].value + 0.5)*8.0 - 4.0;
            // 色温
            asset.whiteBalance  =   (self->SliderArray[4].value + 0.5)*2.0 - 1.0;
            //暗角
            asset.vignette      =   (self->SliderArray[5].value);
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
//            [self playVideo:YES];
        }
    });
}

#pragma mark-滑动进度条
- (void)beginScrub:(UISlider *)slider{
    [self sliderValueChanged:slider];
}

- (void)scrub:(UISlider *)slider{
    [self sliderValueChanged:slider];
}

- (void)endScrub:(UISlider *)slider{
    [self sliderValueChanged:slider];
    [self performSelector:@selector(performDismiss) withObject:nil afterDelay:1.0];
}
#pragma mark-滑块和标志颜色的改变
-(void)sliderValueChanged:(UISlider *)slider
{
    AdjustType adjustType = slider.tag;
    if( adjustType != Adjust_Vignette )
    {
        if( slider.value < 0.0 )
        {
            float with = slider.frame.size.width/2.0 - (slider.frame.size.width  - 21 )*( (slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue))  - 20  ;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3) ];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0,0, 3)];
            }
        }
        else
        {
            
            float with = (slider.frame.size.width  - 20 )*((slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue)) - slider.frame.size.width/2.0;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3)];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, 0, 3)];
            }
        }
    }
    
    switch (adjustType) {
        case Adjust_Brightness:             //亮度
            [self ArerShow:RDLocalizedString(@"亮度", nil) atValue: [NSString stringWithFormat:@"%.1f",slider.value] ];
            _file.brightness    =   (slider.value);
            break;
        case Adjust_Contrast:               //对比度
            [self ArerShow:RDLocalizedString(@"对比度", nil) atValue: [NSString stringWithFormat:@"%.1f",slider.value + 1.0] ];
            _file.contrast      =   (slider.value + 1.0);
            break;
        case Adjust_Saturation:             //饱和度
            [self ArerShow:RDLocalizedString(@"饱和度", nil) atValue: [NSString stringWithFormat:@"%.1f",(slider.value+0.5) * 2.0] ];
            _file.saturation    =   (slider.value+0.5) * 2.0 ;
            break;
        case Adjust_Sharpness:              //锐度
            [self ArerShow:RDLocalizedString(@"锐度", nil) atValue: [NSString stringWithFormat:@"%.1f",(slider.value + 0.5)*8.0 - 4.0] ];
            _file.sharpness     =   (slider.value + 0.5)*8.0 - 4.0;
            break;
        case Adjust_WhiteBalance:           // 色温
            [self ArerShow:RDLocalizedString(@"白平衡", nil) atValue: [NSString stringWithFormat:@"%.1f",(slider.value + 0.5)*2.0 - 1.0] ];
            _file.whiteBalance  =   (slider.value + 0.5)*2.0 - 1.0;
            break;
        case Adjust_Vignette:               //暗角
            [self ArerShow:RDLocalizedString(@"暗角", nil) atValue: [NSString stringWithFormat:@"%.1f",slider.value] ];
            _file.vignette      =   (slider.value);
            break;
        default:
            break;
    }

    float value =  [((NSString*)ProgressInitArray[slider.tag]) floatValue];
    NSString * image = nil;
    NSString * Name = @"亮度";
    NSString * Type = @"选中";
    
    UIImage *theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球2@3x" Type:@"png"]];
    [slider setThumbImage:theImage forState:UIControlStateNormal];
    if( ((value+0.01) >=  slider.value)  && ( (value-0.01) <=  slider.value ) )
    {
        Type =  @"默认";
        UIImage *theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]];
        [slider setThumbImage:theImage forState:UIControlStateNormal];
    }

    //组装
    switch (adjustType) {
        case Adjust_Brightness:             //亮度
            Name = [NSString stringWithFormat:@"亮度%@",Type];
            break;
        case Adjust_Contrast:               //对比度
            Name = [NSString stringWithFormat:@"对比度%@",Type];
            break;
        case Adjust_Saturation:             //饱和度
            Name = [NSString stringWithFormat:@"饱和度%@",Type];
            break;
        case Adjust_Sharpness:              //锐度
            Name = [NSString stringWithFormat:@"锐度%@",Type];
            break;
        case Adjust_WhiteBalance:           //色温
            Name = [NSString stringWithFormat:@"色温%@",Type];
            break;
        case Adjust_Vignette:               //暗角
            Name = [NSString stringWithFormat:@"暗角%@",Type];
            break;
        default:
            break;
    }
    image = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@@3x",Name] Type:@"png"];
    [scenes enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            asset.brightness = self->_file.brightness;
            asset.contrast = self->_file.contrast;
            asset.saturation = self->_file.saturation;
            asset.sharpness = self->_file.sharpness;
            asset.whiteBalance = self->_file.whiteBalance;
            asset.vignette = self->_file.vignette;
        }];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
        }
    });
}
/**保存
 */
- (void)save{
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        [self exportMovie];
    }else {
        if( !_isCore )
        {
            [_videoCoreSDK stop];
            [_videoCoreSDK.view removeFromSuperview];
            _videoCoreSDK.delegate = nil;
            _videoCoreSDK = nil;
        }
        if (_changeAdjustFinish) {
            
            NSArray *floatArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:_file.brightness],[NSNumber numberWithFloat:_file.contrast],[NSNumber numberWithFloat:_file.saturation],[NSNumber numberWithFloat:_file.sharpness],[NSNumber numberWithFloat:_file.whiteBalance],[NSNumber numberWithFloat:_file.vignette],nil];
            
            _changeAdjustFinish(floatArray, useToAllBtn.selected);
        }
        
        [self.navigationController popViewControllerAnimated:NO];
    }
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        [RDSVProgressHUD dismiss];
        [_videoCoreSDK seekToTime:seekTime];
        seekTime = kCMTimeZero;
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

- (void)dealloc {
    
    [TrackImageArray enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.image = nil;
        
    }];
    
    [InitProgressArray removeAllObjects];
    [ProgressInitArray removeAllObjects];
    if( !_isCore )
    {
        _videoCoreSDK.delegate = nil;
        [_videoCoreSDK stop];
        _videoCoreSDK = nil;
    }
    
    [ContrastBtn removeFromSuperview];
    ContrastBtn = nil;
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self SetReduction];
                });
            }
            break;
        case 2:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
        case 3:
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
                alertView.tag = 3;
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
        alertView.tag = 2;
        [alertView show];
        return;
    }
    [_videoCoreSDK stop];
    [_videoCoreSDK seekToTime:kCMTimeZero];
    
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:_videoCoreSDK totalDration:_videoCoreSDK.duration exportSize:_exportSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    
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
        alertView.tag = 4;
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
