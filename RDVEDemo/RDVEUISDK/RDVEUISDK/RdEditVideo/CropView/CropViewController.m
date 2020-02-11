//
//  CropViewController.m
//  RDVEUISDK
//
//  Created by emmet on 15/8/21.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

#import "CropViewController.h"
#import "RDUICliper.h"
#import <MediaPlayer/MediaPlayer.h>
#import "RDSVProgressHUD.h"
#import <CoreText/CoreText.h>
#import "sys/utsname.h"
#import "RDNavigationViewController.h"
#import "RDGenSpecialEffect.h"
#import "RDMainViewController.h"
#import "RDExportProgressView.h"
#import "RDATMHud.h"

#import "ScrollViewChildItem.h"
#import "UIImageView+RDWebCache.h"
#import "RDDownTool.h"

#define kChildBtnViewTag 200
#define D2R(d) (d * M_PI / 180)
@interface CropViewController ()<UIGestureRecognizerDelegate,CropDelegate,UIActionSheetDelegate,CAAnimationDelegate,RDVECoreDelegate,UIAlertViewDelegate,ScrollViewChildItemDelegate>
{
    RDFile              *_originFile;
    RDVECore            *_videoCoreSDK;
    
    NSInteger            _cropType;
    UIImage             *_currentImage;
    CGSize               _presentationSize;
    CGSize               prevSize;
    UIImageView         *_customPreview;
    UIImageView         *_custom_imagev;
    UIButton            *playBtn;
    UIView              *_syncContainer;
    RDUICliper          *_cliper;
    BOOL                 _isPortrait;
    UISlider            *_videoSlider;
    
    UIScrollView        *rotationMeunView;
    UIScrollView        *proportionScrollView;
    UIButton            *_resetBtn;
    UIButton            *useToAllBtn;
    NSInteger            selectedProportionIndex;
    
    BOOL                 isReplacingSource;
    BOOL                      isContinueExport;
    BOOL                      idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    
    //              AE 图片素材编辑 界面
    UIView              *materialFilterVIew;
    NSMutableArray          <RDScene *>*scenes;
    
    NSMutableArray      <UILabel *> *labelBtnArray;
    CMTime                  seekTime;
    bool                _isCore;
}
@property (nonatomic, strong) RDATMHud *hud;
@property (nonatomic, strong) RDExportProgressView *exportProgressView;

//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;
@property (nonatomic, strong) NSMutableArray *filtersName;

@end

@implementation CropViewController
-(void)seekTime:(CMTime) time
{
    seekTime = time;
}
-(void)setSelectFile:(RDFile *)selectFile
{
    CGRect corp = selectFile.crop;
    if( (selectFile.isVerticalMirror) && ( !selectFile.isHorizontalMirror ))
    {
        if( (selectFile.rotate != -90 ) && ( selectFile.rotate != -270 ) )
            selectFile.crop = CGRectMake( 1.0 - corp.origin.x - corp.size.width, 1.0 -  corp.origin.y - corp.size.height, corp.size.width, corp.size.height);
    }
    if(selectFile.isHorizontalMirror && (!selectFile.isVerticalMirror) )
    {
        if( (selectFile.rotate != -90 ) && ( selectFile.rotate != -270 ) )
            selectFile.crop = CGRectMake( 1.0 - corp.origin.x - corp.size.width, 1.0 -  corp.origin.y - corp.size.height, corp.size.width, corp.size.height);
    }
//    if(selectFile.isHorizontalMirror && (selectFile.isVerticalMirror) )
//    {
//        selectFile.crop = CGRectMake( 1.0 -   corp.origin.x - corp.size.width, 1.0 -  corp.origin.y - corp.size.height, corp.size.width, corp.size.height);
//    }
    
    if( ( selectFile.cropRect.size.height > 0 ) && (selectFile.cropRect.size.width > 0) )
    {
        CGSize videoSize = CGSizeMake( selectFile.cropRect.size.width/selectFile.crop.size.width , selectFile.cropRect.size.height/selectFile.crop.size.height);
        float x = videoSize.width * selectFile.crop.origin.x;
        float y = videoSize.height * selectFile.crop.origin.y;
        selectFile.cropRect = CGRectMake(x, y, selectFile.cropRect.size.width, selectFile.cropRect.size.height);
    }
    

    _selectFile = selectFile;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    _resetBtn.enabled  = NO;
    if(_originFile.fileType == kFILEVIDEO || _originFile.isGif){
        [self initChildView];
        [self initCropView];
        [self updateSyncLayerPositionAndTransform];
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

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (!isReplacingSource) {
        if(_customPreview){
            [_customPreview removeFromSuperview];
            _customPreview = nil;
        }
        if(_cliper){
            _cliper.delegate = nil;
            [_cliper  removeFromSuperview];
            _cliper = nil;
        }
    }
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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    _originFile = [_selectFile copy];
    _cropType = _originFile.fileCropModeType;
    float width = kWIDTH;
    float height = kPlayerViewHeight;
    if( _originFile.cropRect.origin.x == -1 ) {
        _originFile.cropRect = CGRectMake(_originFile.crop.origin.x*width,
                                          _originFile.crop.origin.y*height,
                                          _originFile.crop.size.width*width,
                                          _originFile.crop.size.height*height);
    }
    [self refreshSelectThumbFiles:YES cropOrRotation:YES];
    [self initOtherView];
    
    [RDHelpClass animateView:rotationMeunView atUP:NO];
    prevSize = _presentationSize;
}

- (void)refreshSelectThumbFiles:(BOOL)needRefreshFile cropOrRotation:(BOOL)cropOrRotation{
    if(_originFile.isReverse){
        _isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_originFile.reverseVideoURL]];
    }else{
        _isPortrait = [RDHelpClass isVideoPortrait:[AVURLAsset assetWithURL:_originFile.contentURL]];
    }
    
    if(_originFile.fileType == kFILEIMAGE && !_originFile.isGif){
        UIImage *image = [RDHelpClass getFullScreenImageWithUrl:_originFile.contentURL];
        _currentImage = [RDHelpClass imageRotatedByDegrees:image rotation: _originFile.rotate];
        _presentationSize  = _currentImage.size;
        _custom_imagev.image = _currentImage;
        if(needRefreshFile){
            [self initCustomPreView];
            [self initCropView];
        }
    }
    else{
        CGSize size;
        size = [self getVideoSizeForTrack];
        _presentationSize = size;
        
        if(size.height == size.width){
            
            _presentationSize        = size;
            
        }else if(_isPortrait){
            _presentationSize = size;
            
            if(size.height < size.width){
                _presentationSize  = CGSizeMake(size.height, size.width);
            }
            if(_originFile.rotate == -90 || _originFile.rotate == -270){
                _presentationSize  = CGSizeMake(size.width, size.height);
            }
        }else{
            _presentationSize  = [self getVideoSizeForTrack];
            if(_originFile.rotate == -90 || _originFile.rotate == -270){
                CGSize size = [self getVideoSizeForTrack];
                _presentationSize  = CGSizeMake(size.height, size.width);
            }
        }
    }
}

- (CGSize )getVideoSizeForTrack{
    CGSize size = CGSizeZero;
    AVURLAsset *asset = [AVURLAsset assetWithURL:_originFile.contentURL];
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
    }
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    return size;
}

- (void)initOtherView{
    if(_originFile.fileType != kFILEIMAGE || !_customPreview){
        [self initCustomPreView];
    }
    [self initToolBarView];
    
    if (_isOnlyRotate) {
        UIButton *rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        rotateBtn.frame = CGRectMake(kWIDTH - 44, _customPreview.frame.origin.y + _customPreview.bounds.size.height + 44, 44, 44);
        [rotateBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/bianji/剪辑-编辑旋转默认_"] forState:UIControlStateNormal];
        [rotateBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/bianji/剪辑-编辑旋转点击_"] forState:UIControlStateHighlighted];
        [rotateBtn addTarget:self action:@selector(childBtnsTouchUpInSlide:) forControlEvents:UIControlEventTouchUpInside];
        rotateBtn.tag = 4;
        [self.view addSubview:rotateBtn];
    }else if (!_isOnlyCrop) {
        [self initCropMeunView];
    }
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"裁切", nil);
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
        toolBarView.backgroundColor = [UIColor clearColor];
        toolBarView.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, 44);
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        gradientLayer.locations = @[@0.3, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1.0);
        gradientLayer.frame = toolBarView.bounds;
        [toolBarView.layer addSublayer:gradientLayer];
        
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
    
    if (_isOnlyCrop) {
        titleLbl.text = RDLocalizedString(@"title-crop", nil);
        materialFilterVIew = [[UIView alloc] initWithFrame:CGRectMake(0, kPlayerViewOriginX + kPlayerViewHeight, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight)];
        materialFilterVIew.backgroundColor = TOOLBAR_COLOR;
        [self.view addSubview:materialFilterVIew];
        
        [materialFilterVIew addSubview:self.filterView];
    }
    [RDHelpClass animateView:toolBarView atUP:NO];
}

- (void)initCropMeunView{
    rotationMeunView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _customPreview.frame.origin.y + _customPreview.frame.size.height , kWIDTH, kHEIGHT - _customPreview.frame.origin.y - _customPreview.frame.size.height - kToolbarHeight )];
    rotationMeunView.backgroundColor = TOOLBAR_COLOR;
    playBtn.frame = CGRectMake(5, rotationMeunView.frame.origin.y  - 44, 44, 44);
    [self.view addSubview:rotationMeunView];
    
    if (!_presentModel) {
        useToAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        useToAllBtn.frame = CGRectMake(5, 0, 120, 35 );
        
        useToAllBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateNormal];
        [useToAllBtn setTitle:RDLocalizedString(@"应用到所有", nil) forState:UIControlStateHighlighted];
        [useToAllBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [useToAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到默认"] forState:UIControlStateNormal];
        [useToAllBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/Adjust/剪辑-调色_应用到选择"] forState:UIControlStateSelected];
        [useToAllBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        [useToAllBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 1, 0, 0)];
        [useToAllBtn addTarget:self action:@selector(useToAllBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        CGSize useToAllTranstionSize = [useToAllBtn.titleLabel sizeThatFits:CGSizeZero];
        useToAllBtn.frame = CGRectMake( 5, useToAllBtn.frame.origin.y, 120, useToAllBtn.frame.size.height);
        [rotationMeunView addSubview:useToAllBtn];
    }
    
    
    _resetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _resetBtn.frame = CGRectMake(20, useToAllBtn.frame.size.height + useToAllBtn.frame.origin.y + (rotationMeunView.frame.size.height*0.18 - (useToAllBtn.frame.size.height + useToAllBtn.frame.origin.y) + rotationMeunView.frame.size.height*0.297 -30)/2.0, 30, 30);
    [_resetBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/特效-撤销"] forState:UIControlStateNormal];
    [_resetBtn addTarget:self action:@selector(childBtnsTouchUpInSlide:) forControlEvents:UIControlEventTouchUpInside];
    _resetBtn.tag = 1;
    _resetBtn.enabled = NO;
    [rotationMeunView addSubview:_resetBtn];
    
    float width = 82;
    
    float space = ( rotationMeunView.frame.size.width - (_resetBtn.frame.size.width + _resetBtn.frame.origin.x) - width*3.0 -25 )/3.0;
    
    float space1 = width + space;
    for (int i = 0; i < 3; i++) {
        UIButton *rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        rotateBtn.frame = CGRectMake( _resetBtn.frame.size.width + _resetBtn.frame.origin.x + space + space1*i, _resetBtn.frame.origin.y , width, 30);
        rotateBtn.layer.cornerRadius = 15;
        rotateBtn.layer.borderWidth = 1.0;
        rotateBtn.backgroundColor = UIColorFromRGB(0x1f262c);
        rotateBtn.layer.borderColor = UIColorFromRGB(0x1f262c).CGColor;
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 10/2.0, 20, 20)];
        [rotateBtn addSubview:imageView];
        imageView.backgroundColor = [UIColor clearColor];
        NSString * imagePath = nil;
        if (i == 0) {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/剪辑-剪辑垂直翻转默认_@3x" Type:@"png"];
            [rotateBtn setTitle:RDLocalizedString(@"垂直翻转", nil) forState:UIControlStateNormal];
        }else if (i == 1) {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/剪辑-剪辑水平翻转默认_@3x" Type:@"png"];
            [rotateBtn setTitle:RDLocalizedString(@"水平翻转", nil) forState:UIControlStateNormal];
        }else {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/剪辑-剪辑旋转默认_@3x" Type:@"png"];
            [rotateBtn setTitle:RDLocalizedString(@"旋     转", nil) forState:UIControlStateNormal];
        }
        
        imageView.image = [UIImage imageWithContentsOfFile:imagePath];
        
        rotateBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        [rotateBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        rotateBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [rotateBtn addTarget:self action:@selector(childBtnsTouchUpInSlide:) forControlEvents:UIControlEventTouchUpInside];
        rotateBtn.tag = i + 2;
        [rotationMeunView addSubview:rotateBtn];
    }
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10,rotationMeunView.frame.size.height*0.297 + rotationMeunView.frame.size.height*0.180 + (rotationMeunView.frame.size.height*0.180 - 1.0)/2.0, kWIDTH - 20, 1.0)];
    line.backgroundColor = CUSTOM_GRAYCOLOR;
    [rotationMeunView addSubview:line];
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc) {
        _selectFile.fileCropModeType = kCropTypeOriginal;
    }
    selectedProportionIndex = _selectFile.fileCropModeType + 5 - 1;
    [labelBtnArray removeAllObjects];
    labelBtnArray = nil;
    labelBtnArray = [NSMutableArray new];
    CGPoint point = CGPointZero;
    if (_originFile.fileCropModeType != kCropTypeFixed) {
        proportionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, rotationMeunView.frame.size.height*0.297 + rotationMeunView.frame.size.height*0.180 + rotationMeunView.frame.size.height*0.18, kWIDTH, rotationMeunView.frame.size.height*0.345)];
        proportionScrollView.frame = CGRectMake(0, line.frame.origin.y + (rotationMeunView.frame.size.height - line.frame.origin.y - rotationMeunView.frame.size.height*0.345)/2.0, kWIDTH, rotationMeunView.frame.size.height*0.345);
        proportionScrollView.showsVerticalScrollIndicator = NO;
        proportionScrollView.showsHorizontalScrollIndicator = NO;
        [rotationMeunView addSubview:proportionScrollView];
        float space = (kWIDTH - rotationMeunView.frame.size.height*0.345*4.5)/7.0;
        for (int i = 0; i < 7; i++) {
            UIButton *proportionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            proportionBtn.frame = CGRectMake(proportionScrollView.frame.size.height * i + space * i + 20, 0, proportionScrollView.frame.size.height, proportionScrollView.frame.size.height);
            
            UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15/2.0, 0, proportionBtn.frame.size.width - 15, proportionBtn.frame.size.width - 15)];
            imageView.image = [UIImage imageWithContentsOfFile:[self getProportionBtnImagePath:i isNormal:YES]];
            [proportionBtn addSubview:imageView];
            
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, imageView.frame.size.height, proportionBtn.frame.size.width, 15)];
            label.text = [self getProportionBtnTitle:i];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:12];
            
            [proportionBtn addSubview:label];
            [labelBtnArray addObject:label];
//            [proportionBtn setTitle:[self getProportionBtnTitle:i] forState:UIControlStateNormal];
//            [proportionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [proportionBtn setTitleColor:Main_Color forState:UIControlStateSelected];
//            proportionBtn.titleLabel.font = [UIFont systemFontOfSize:12];
//            [proportionBtn setImage:[UIImage imageWithContentsOfFile:[self getProportionBtnImagePath:i isNormal:YES]] forState:UIControlStateNormal];
//            [proportionBtn setImage:[UIImage imageWithContentsOfFile:[self getProportionBtnImagePath:i isNormal:NO]] forState:UIControlStateSelected];
//            proportionBtn.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 20, 0);
//            proportionBtn.titleEdgeInsets = UIEdgeInsetsMake(rotationMeunView.frame.size.height*0.345 - 10, -rotationMeunView.frame.size.height*0.345 + 5, 0, 0);
            proportionBtn.tag = i + 5;
            if (proportionBtn.tag == selectedProportionIndex) {
                proportionBtn.selected = YES;
                label.textColor = Main_Color;
                point = CGPointMake(proportionBtn.frame.origin.x, 0);
            }
            else{
                label.textColor = [UIColor whiteColor];
            }
            [proportionBtn addTarget:self action:@selector(proportionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [proportionScrollView addSubview:proportionBtn];
        }
        
        proportionScrollView.contentSize = CGSizeMake(rotationMeunView.frame.size.height*0.345 * 7 + space * 8, 0);
        
        point = CGPointMake( (((point.x - (proportionScrollView.contentSize.width - proportionScrollView.frame.size.width))) > 0)?((proportionScrollView.contentSize.width - proportionScrollView.frame.size.width)):(point.x), 0);
        proportionScrollView.contentOffset = point;
    }
}

- (NSString *)getProportionBtnTitle:(int)index {
    NSString *title;
    switch (index) {
        case 0:
            title = @"原比例";
            break;
        case 1:
            title = @"自由";
            break;
        case 2:
            title = @"1:1";
            break;
        case 3:
            title = @"16:9";
            break;
        case 4:
            title = @"9:16";
            break;
        case 5:
            title = @"4:3";
            break;
        default:
            title = @"3:4";
            break;
    }
    
    title = RDLocalizedString(title, nil);
    return title;
}

- (NSString *)getProportionBtnImagePath:(int)index isNormal:(BOOL)isNormal {
    NSString *imageName;
    switch (index) {
        case 0:
            imageName = @"原比例";
            break;
        case 1:
            imageName = @"自由";
            break;
        case 2:
            imageName = @"1-1";
            break;
        case 3:
            imageName = @"16-9";
            break;
        case 4:
            imageName = @"9-16";
            break;
        case 5:
            imageName = @"4-3";
            break;
            
        default:
            imageName = @"3-4";
            break;
    }
    NSString * str = nil;
    if (isNormal) {
        
        if( index > 1 )
            str = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/Proportion/比例%@@3x", imageName] Type:@"png"];
        else
            str = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/clipEditProportion/%@默认@3x", imageName] Type:@"png"];
    }
    else
    {
        if( index > 1 )
            str = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/Proportion/比例%@-选中@3x", imageName] Type:@"png"];
        else
            str = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/clipEditProportion/%@选中@3x", imageName] Type:@"png"];
    }
    return str;
}
/*
 初始化视频播放控件
 */
- (void)initCustomPreView{
    if(!_customPreview){
        _customPreview = [[UIImageView alloc] init];
        if (!_isOnlyCrop)
            _customPreview.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kPlayerViewHeight);
        else
            _customPreview.frame = CGRectMake(0, kPlayerViewOriginX, kWIDTH, kHEIGHT - ( kToolbarHeight + 35 + 0 + 110 ) - kPlayerViewOriginX);
        _customPreview.backgroundColor = [UIColor blackColor];
        _customPreview.userInteractionEnabled = YES;
        _customPreview.contentMode = UIViewContentModeScaleAspectFit;
        _customPreview.layer.masksToBounds = YES;
        [self.view addSubview:_customPreview];
        
        if (_originFile.fileType == kFILEVIDEO || _originFile.isGif) {
            playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            playBtn.backgroundColor = [UIColor clearColor];
            playBtn.frame = CGRectMake(5, (kHEIGHT - ( kToolbarHeight + 35 + 0 + 110 ) - kPlayerViewOriginX)  - 44, 44, 44);
            [playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
            [playBtn addTarget:self action:@selector(playBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_customPreview addSubview:playBtn];
        }
    }
    if(_originFile.fileType == kFILEIMAGE && !_originFile.isGif){
        if (!_custom_imagev) {
            _custom_imagev = [[UIImageView alloc] initWithFrame:_customPreview.bounds];
            _custom_imagev.backgroundColor = [UIColor clearColor];
            _custom_imagev.image = _currentImage;
            _custom_imagev.contentMode = UIViewContentModeScaleAspectFit;
            _custom_imagev.tag = 3000;
            [_customPreview addSubview:_custom_imagev];
        }
        CATransform3D t = CATransform3DIdentity;
        if(_originFile.isHorizontalMirror){
            t = CATransform3DRotate(t , D2R(180),0, 1, 0);//沿着Y轴翻转
        }
        if(_originFile.isVerticalMirror){
            t = CATransform3DRotate(t , D2R(180),1, 0, 0);//沿着X轴翻转
        }
        _custom_imagev.transform = CATransform3DGetAffineTransform(t);
    }
}

- (void)initChildView{
    
    if( _videoCoreSDK  )
    {
        _videoCoreSDK.delegate = self;
        _videoCoreSDK.frame = CGRectMake(0, 0, kWIDTH, kPlayerViewHeight);
        [_customPreview insertSubview:_videoCoreSDK.view atIndex:0];
    }
    else
        [self initPlayer];
}

-(void)setVideoCoreSDK:(RDVECore *) core
{
    if( core )
        _isCore = true;
    _videoCoreSDK = core;
    scenes = [_videoCoreSDK getScenes];
}

/*
 初始化播放器
 */
- (void)initPlayer{
    scenes = [NSMutableArray array];
    RDFile *file = _originFile;
    RDScene *scene = [[RDScene alloc] init];
    
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = file.contentURL;
    
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
    }else{
        vvasset.type         = RDAssetTypeImage;
        
        if( _isOnlyCrop )
            vvasset.fillType = RDImageFillTypeFit;
        
        if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
            vvasset.timeRange = file.imageTimeRange;
        }else {
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;
    }
    
    vvasset.rotate = file.rotate;
    vvasset.isVerticalMirror = file.isVerticalMirror;
    vvasset.isHorizontalMirror = file.isHorizontalMirror;
    vvasset.crop              = CGRectZero;
    
    vvasset.brightness = _originFile.brightness;
    vvasset.contrast = _originFile.contrast;
    vvasset.saturation = _originFile.saturation;
    vvasset.sharpness = _originFile.sharpness;
    vvasset.whiteBalance = _originFile.whiteBalance;
    vvasset.vignette = _originFile.vignette;
    if (_globalFilters.count > 0) {
        RDFilter* filter = _globalFilters[_originFile.filterIndex];
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
    
    [scene.vvAsset addObject:vvasset];
    [scenes addObject:scene];
    CGSize size = _presentationSize;
    if((file.rotate == -90 || file.rotate == -270) && _isPortrait){
        size.width = _presentationSize.height;
        size.height = _presentationSize.width;
    }
    _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                           APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                          LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                           videoSize:size
                                                 fps:kEXPORTFPS
                                          resultFail:^(NSError *error) {
                                                NSLog(@"initSDKError:%@", error.localizedDescription);
                                           }];
    _videoCoreSDK.frame = _customPreview.bounds;
    _videoCoreSDK.delegate = self;
    
    [_videoCoreSDK setScenes:scenes];
    
    if (_musicURL) {
        RDMusic *music = [[RDMusic alloc] init];
        music.url = _musicURL;
        music.clipTimeRange = _musicTimeRange;
        music.volume = _musicVolume;
        music.isFadeInOut = YES;
        [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
    }
    [_videoCoreSDK build];
    [_customPreview insertSubview:_videoCoreSDK.view atIndex:0];
}

- (void)refreshPlayer:(NSNumber *)needRefreshFiles{
    if([needRefreshFiles boolValue]){
        [self refreshSelectThumbFiles:YES cropOrRotation:YES];
        [self initCropView];
        [scenes enumerateObjectsUsingBlock:^(RDScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.rotate = _originFile.rotate;
                obj.isVerticalMirror = _originFile.isVerticalMirror;
                obj.isHorizontalMirror = _originFile.isHorizontalMirror;
            }];
        }];
        [_videoCoreSDK setEditorVideoSize:_presentationSize];
        if (CGSizeEqualToSize(_presentationSize, prevSize)) {
            [_videoCoreSDK refreshCurrentFrame];
        }else {
            [_videoCoreSDK build];
            prevSize = _presentationSize;
        }
    }else {
        scenes = [NSMutableArray new];
        RDFile *file = _originFile;
        RDScene *scene = [[RDScene alloc] init];
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        if(_originFile.fileType == kFILEVIDEO){
            vvasset.videoActualTimeRange = file.videoActualTimeRange;
            vvasset.type = RDAssetTypeVideo;
            if(file.isReverse){
                vvasset.url = file.reverseVideoURL;
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
                }else{
                    vvasset.timeRange = file.reverseVideoTimeRange;
                }
                if(CMTimeCompare(vvasset.timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1){
                    vvasset.timeRange = file.reverseVideoTrimTimeRange;
                }
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
        }
        vvasset.speed = file.speed;
        vvasset.volume = file.videoVolume;
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        if (_exportProgressView) {
            vvasset.crop = file.crop;
        }else {
            vvasset.crop = CGRectZero;
        }
        [scene.vvAsset addObject:vvasset];
        [scenes addObject:scene];
        
        if (_exportProgressView) {
            CGSize size = CGSizeMake(_presentationSize.width * _originFile.crop.size.width, _presentationSize.height * _originFile.crop.size.height);
            [_videoCoreSDK setEditorVideoSize:size];
        }else {
            [_videoCoreSDK setEditorVideoSize:_presentationSize];
        }
        [_videoCoreSDK setScenes:scenes];
        
        if (_musicURL) {
            RDMusic *music = [[RDMusic alloc] init];
            music.url = _musicURL;
            music.clipTimeRange = _musicTimeRange;
            music.volume = _musicVolume;
            music.isFadeInOut = YES;
            [_videoCoreSDK setMusics:[NSMutableArray arrayWithObject:music]];
        }
        if (!_exportProgressView) {
            [_videoCoreSDK build];
        }
    }
}

/*
 初始化裁剪器
 */
- (void)initCropView{
    if(_cliper.superview){
        [_cliper removeFromSuperview];
        _cliper = nil;
    }
    _cliper = [[RDUICliper alloc]initWithView:_customPreview freedom:YES];
    _cliper.backgroundColor = [UIColor clearColor];
    [_cliper setCropText:@" "];
    [_cliper setFrame:_customPreview.frame];
    [_cliper setFrameRect:_customPreview.frame];
    _cliper.clipsToBounds=YES;
    _cliper.delegate = self;
    [_cliper.playBtn removeFromSuperview];
    _cliper.playBtn = nil;
    [self updateSyncLayerPositionAndTransform];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCliper:)];
    [_cliper addGestureRecognizer:tap];
}

- (void)tapCliper:(UITapGestureRecognizer *)gesture{
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

#pragma mark-UICliperDelegate
- (void)cropViewDidChangeClipValue:(CGRect)rect clipRect:(CGRect)clipRect{
    _originFile.crop = rect;
    _originFile.cropRect = clipRect;
    _resetBtn.enabled = YES;
}
- (void)touchesEndSuperView{
    [self playVideo:NO];
}

- (BOOL)touchUpinslidePlayeBtn{
    [self playVideo:![_videoCoreSDK isPlaying]];
    return [_videoCoreSDK isPlaying];
}

#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay && !_exportProgressView) {
//        [self playVideo:YES];
        _videoCoreSDK.view.hidden = NO;
        if (CMTimeCompare(seekTime, kCMTimeZero) == 1) {
            [_videoCoreSDK seekToTime:seekTime];
            seekTime = kCMTimeZero;
        }
    }
}

- (void)progressCurrentTime:(CMTime)currentTime{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self watcher:currentTime];
    });
}

- (void)playToEnd{
    [self playVideo:NO];
    [_videoCoreSDK seekToTime:kCMTimeZero];
    _videoSlider.value = 0.0;
}

#pragma mark- 播放暂停
- (void)playVideo:(BOOL)flag{
    if(!flag){
        if([_videoCoreSDK isPlaying]){
            [_videoCoreSDK pause];
        }
        [playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        if([_videoCoreSDK status] != kRDVECoreStatusReadyToPlay){
            return;
        }
        if(![_videoCoreSDK isPlaying]){
            [_videoCoreSDK play];
        }
        [playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
    }
}

#pragma mark- 播放结束
- (void)watcher:(CMTime )time{
    [_videoSlider setValue:CMTimeGetSeconds(time)/_videoCoreSDK.duration animated:NO];
}

/**改变视频的Size
 */
- (void)updateSyncLayerPositionAndTransform{
   if(_originFile.fileType == kFILEIMAGE && !_originFile.isGif){
       CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(_presentationSize, _customPreview.bounds);
       [_cliper setFrameRect:videoRect];
       if (!CGSizeEqualToSize(_editVideoSize, CGSizeZero)) {
           [_cliper setVideoSize:_editVideoSize];
       }else {
           [_cliper setVideoSize:_presentationSize];
       }
       [_cliper setCropType:_cropType];
       _cliper.fileType = 0;
        [_cliper setClipRect:_originFile.cropRect];
   }
   else{
       if(_originFile.rotate == -90 || _originFile.rotate == -270){
           if(_presentationSize.height>_presentationSize.width && _isPortrait){
               _presentationSize = CGSizeMake(_presentationSize.height, _presentationSize.width);
           }
           CGRect videoRect         = AVMakeRectWithAspectRatioInsideRect(_presentationSize, _customPreview.bounds);
           CGSize viewSize          = _customPreview.bounds.size;
           CGFloat scale            = fmin(viewSize.width /_presentationSize.width,
                                           viewSize.height/_presentationSize.height);
           _syncContainer.center    = CGPointMake( CGRectGetMidX(videoRect), CGRectGetMidY(videoRect));
           
           _syncContainer.transform = CGAffineTransformMakeScale(scale, scale);
           
           if (_originFile.fileCropModeType == kCropTypeFixed && CGRectEqualToRect(_originFile.cropRect, CGRectZero)) {
               float x=0,y=0,w=0,h=0;
//                   size = videoRect.size.height>videoRect.size.width? videoRect.size.width :videoRect.size.height;
               w=videoRect.size.width*_originFile.crop.size.width;
               h=videoRect.size.height*_originFile.crop.size.height;
               x=(videoRect.size.width-w)/2;
               y=(videoRect.size.height-h)/2;
               _originFile.cropRect = CGRectMake(x, y, w, h);
           }
           
           if (!CGSizeEqualToSize(_editVideoSize, CGSizeZero)) {
               [_cliper setVideoSize:_editVideoSize];
           }else {
               [_cliper setVideoSize:_presentationSize];
           }
           [_cliper setFrameRect:videoRect];
           [_cliper setCropType:_cropType];
           [_cliper setClipRect:_originFile.cropRect];
       }
       else{
           CGRect videoRect         = AVMakeRectWithAspectRatioInsideRect(_presentationSize, _customPreview.bounds);
           
           CGSize viewSize          = _customPreview.bounds.size;
           CGFloat scale            = fmin(viewSize.width /_presentationSize.width,
                                           viewSize.height/_presentationSize.height);
           _syncContainer.center    = CGPointMake( CGRectGetMidX(videoRect), CGRectGetMidY(videoRect));
           
           _syncContainer.transform = CGAffineTransformMakeScale(scale, scale);
           
           if (_originFile.fileCropModeType == kCropTypeFixed) {
               if (CGRectEqualToRect(_originFile.cropRect, CGRectZero)
                   && !CGRectEqualToRect(_originFile.crop, CGRectMake(0, 0, 1, 1)))
               {//第一次裁切时,因截取界面与该界面播放器大小不一致
                   float /*size = 0,*/x=0,y=0,w=0,h=0;
//                       size = videoRect.size.height>videoRect.size.width? videoRect.size.width :videoRect.size.height;
                   w=videoRect.size.width*_originFile.crop.size.width;
                   h=videoRect.size.height*_originFile.crop.size.height;
                   x=videoRect.size.width*_originFile.crop.origin.x;
                   y=videoRect.size.height*_originFile.crop.origin.y;
                   _originFile.cropRect = CGRectMake(x, y, w, h);
               }
               else if (CGRectEqualToRect(_originFile.cropRect, CGRectZero)) {
                   float x=0,y=0,w=0,h=0;
//                       size = videoRect.size.height>videoRect.size.width? videoRect.size.width :videoRect.size.height;
                   w=videoRect.size.width*_originFile.crop.size.width;
                   h=videoRect.size.height*_originFile.crop.size.height;
                   x=(videoRect.size.width-w)/2;
                   y=(videoRect.size.height-h)/2;
                   _originFile.cropRect = CGRectMake(x, y, w, h);
               }
           }
           if (!CGSizeEqualToSize(_editVideoSize, CGSizeZero)) {
               [_cliper setVideoSize:_editVideoSize];
           }else {
               [_cliper setVideoSize:_presentationSize];
           }
           [_cliper setFrameRect:videoRect];
           [_cliper setCropType:_cropType];
           [_cliper setClipRect:_originFile.cropRect];
       }
       _cliper.fileType = 1;
       [_cliper setNeedsDisplay];
   }
}

- (CGRect)getVideoCrop {
    AVURLAsset *asset;
    if(_originFile.isReverse){
        asset = [AVURLAsset assetWithURL:_originFile.reverseVideoURL];
    }else {
        asset = [AVURLAsset assetWithURL:_originFile.contentURL];
    }
    BOOL isPortrait = [RDHelpClass isVideoPortrait:asset];
    CGSize videoSize = [RDHelpClass getVideoSizeForTrack:asset];
    
    CGRect cropRect = CGRectZero;
    CGRect crop = CGRectZero;
    if (_originFile.rotate == -90 || _originFile.rotate == -270) {
        isPortrait = !isPortrait;
    }
    if (isPortrait) {
        videoSize = CGSizeMake(MIN(videoSize.width, videoSize.height), MAX(videoSize.width, videoSize.height));
        
        float ratiow = _videoInViewSize.width/_videoInViewSize.height;
        float ratioh = _videoInViewSize.height/_videoInViewSize.width;
        if (ratiow <= 1.0) {
            cropRect = CGRectMake((videoSize.width - videoSize.height*ratiow)/2.0, 0, videoSize.height*ratiow, videoSize.height);
            
            if (cropRect.size.width > videoSize.width) {
                cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
                crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
            }else {
                crop = CGRectMake(cropRect.origin.x/videoSize.width, 0, cropRect.size.width/videoSize.width, 1.0);
            }
        }else {
            cropRect = CGRectMake(0, (videoSize.height - videoSize.width*ratioh)/2.0, videoSize.width, videoSize.width*ratioh);
            crop = CGRectMake(0, cropRect.origin.y/videoSize.height, 1.0, cropRect.size.height/videoSize.height);
        }
    }else {
        videoSize = CGSizeMake(MAX(videoSize.width, videoSize.height), MIN(videoSize.width, videoSize.height));
        
        float ratiow = _videoInViewSize.width/_videoInViewSize.height;
        float ratioh = _videoInViewSize.height/_videoInViewSize.width;
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

#pragma mark - 按钮事件
- (void)save{
    
    
    
    _originFile.crop = [_cliper getclipRect];
    _originFile.cropRect = [_cliper getclipRectFrame];
    if(_presentModel){
        if(((RDNavigationViewController *)self.navigationController).isSingleFunc && ((RDNavigationViewController *)self.navigationController).callbackBlock){
            [self exportMovie];
        }else {
            if( !_isCore )
            {
                [_videoCoreSDK stop];
                [_videoCoreSDK.view removeFromSuperview];
                _videoCoreSDK.delegate = nil;
                _videoCoreSDK = nil;
            }
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }else{
        [self dismissViewControllerAnimated:NO completion:nil];
//        [self.navigationController popViewControllerAnimated:NO];
    }

    if(_editVideoForOnceFinishAction){
        _selectFile.contentURL = _originFile.contentURL; _editVideoForOnceFinishAction(_originFile.crop,_originFile.cropRect,_originFile.isVerticalMirror,_originFile.isHorizontalMirror,_originFile.rotate,_cropType);
    }
    
    if( _editVideoForOnceFinishFiltersAction )
    { _editVideoForOnceFinishFiltersAction(_originFile.crop,_originFile.cropRect,_originFile.isVerticalMirror,_originFile.isHorizontalMirror,_originFile.rotate,_cropType,_originFile.filterIndex);
    }
}

- (void)back{
    
    if(_presentModel){
        if( !_isCore )
        {
        [_videoCoreSDK stop];
        [_videoCoreSDK.view removeFromSuperview];
        _videoCoreSDK.delegate = nil;
        _videoCoreSDK = nil;
        }
        [self dismissViewControllerAnimated:NO completion:nil];
    }else{
        [self dismissViewControllerAnimated:NO completion:nil];
//        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)playBtnAction:(UIButton *)sender {
    [self playVideo:![_videoCoreSDK isPlaying]];
}

- (void)useToAllBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
}

- (void)childBtnsTouchUpInSlide:(UIButton *)sender{
    if(_videoCoreSDK && [_videoCoreSDK isPlaying]){
        [self playVideo:NO];
    }
    _resetBtn.enabled  = YES;
    BOOL needRefreshFiles = YES;
    if(sender == _resetBtn){
        _resetBtn.enabled  = NO;
        _originFile.cropRect            = _selectFile.cropRect;
        _originFile.crop                = _selectFile.crop;
        _originFile.rotate              = _selectFile.rotate;
        _originFile.isVerticalMirror    = _selectFile.isVerticalMirror;
        _originFile.isHorizontalMirror  = _selectFile.isHorizontalMirror;
        float width = kWIDTH;
        float height = kPlayerViewHeight;
        if( _originFile.cropRect.origin.x == -1 ) {
            _originFile.cropRect = CGRectMake(_originFile.crop.origin.x*width,
                                              _originFile.crop.origin.y*height,
                                              _originFile.crop.size.width*width,
                                              _originFile.crop.size.height*height);
        }
        _cropType = _selectFile.fileCropModeType;
        
        UIButton *prevBtn = [rotationMeunView viewWithTag:selectedProportionIndex];
        prevBtn.selected = NO;
        
        selectedProportionIndex = _selectFile.fileCropModeType + 5 - 1;
        UIButton *currBtn = [rotationMeunView viewWithTag:selectedProportionIndex];
        currBtn.selected = YES;
        
        if(_originFile.fileType == kFILEIMAGE && !_originFile.isGif){
            [self refreshSelectThumbFiles:YES cropOrRotation:YES];
        }else {
            [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshPlayer:) object:[NSNumber numberWithBool:needRefreshFiles]];
            [self performSelector:@selector(refreshPlayer:) withObject:[NSNumber numberWithBool:needRefreshFiles] afterDelay:0.2];
        }
    }else {
        CGRect corp = _originFile.crop;
        bool tmpIsVerticalMirror = _originFile.isVerticalMirror;
        bool tmpIsHorizontalMirror = _originFile.isHorizontalMirror;

        if(sender.tag == 4){//旋转
            if(_originFile.rotate == 0){
                _originFile.rotate = -90;
            }else if(_originFile.rotate == -90){
                _originFile.rotate = -180;
            }else if(_originFile.rotate == -180){
                _originFile.rotate = -270;
            }else if(_originFile.rotate == -270){
                _originFile.rotate = 0;
            }
        }else if(sender.tag == 2){//垂直翻转
            _originFile.isVerticalMirror = !_originFile.isVerticalMirror;
        }else if(sender.tag == 3){//水平翻转
            _originFile.isHorizontalMirror = !_originFile.isHorizontalMirror;
        }
        if (_originFile.fileCropModeType == kCropTypeFixed) {
            _originFile.crop = [self getVideoCrop];
        }else {
//            _originFile.crop = CGRectZero;
        }
        if(sender.tag == 4){
             _originFile.cropRect = CGRectZero;
        }
        else
        {
            if( tmpIsVerticalMirror != _originFile.isVerticalMirror )
            {
                _originFile.crop = CGRectMake( corp.origin.x, (1.0 -  corp.origin.y) - corp.size.height , corp.size.width, corp.size.height);
            }
            if( tmpIsHorizontalMirror != _originFile.isHorizontalMirror )
            {
                _originFile.crop = CGRectMake( 1.0 -  corp.origin.x - corp.size.width, corp.origin.y, corp.size.width, corp.size.height);
            }
            CGSize videoSize = CGSizeMake( _originFile.cropRect.size.width/_originFile.crop.size.width , _originFile.cropRect.size.height/_originFile.crop.size.height);
             float x = videoSize.width * _originFile.crop.origin.x;
             float y = videoSize.height * _originFile.crop.origin.y;
            _originFile.cropRect = CGRectMake(x, y, _originFile.cropRect.size.width, _originFile.cropRect.size.height);
        }
        if(_originFile.fileType == kFILEIMAGE && !_originFile.isGif){
            UIImage *image = [RDHelpClass getFullScreenImageWithUrl:_originFile.contentURL];
            _currentImage = [RDHelpClass imageRotatedByDegrees:image rotation:_originFile.rotate];
            _presentationSize  = _currentImage.size;
            
            _custom_imagev.backgroundColor = SCREEN_BACKGROUND_COLOR;
            _custom_imagev.image = _currentImage;
            CATransform3D t = CATransform3DIdentity;
            if(_originFile.rotate == -90 || _originFile.rotate == -270){
                if(_originFile.isVerticalMirror){
                    t = CATransform3DRotate(t , D2R(180),1, 0, 0);//沿着X轴翻转
                }
                if(_originFile.isHorizontalMirror){
                    t = CATransform3DRotate(t , D2R(180),0, 1, 0);//沿着Y轴翻转
                }
            } else{
                if(_originFile.isVerticalMirror){
                    t = CATransform3DRotate(t , D2R(180),1, 0, 0);//沿着x轴翻转
                }
                if(_originFile.isHorizontalMirror){
                    t = CATransform3DRotate(t , D2R(180),0, 1, 0);//沿着y轴翻转
                }
            }
            _custom_imagev.transform = CATransform3DGetAffineTransform(t);
            if ( (sender.tag == 4) || (sender.tag == 2) || (sender.tag == 3) ) {//旋转
                [self initCropView];
            }
        }
        else{
            [self playVideo:NO];
            [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshPlayer:) object:[NSNumber numberWithBool:needRefreshFiles]];
            [self performSelector:@selector(refreshPlayer:) withObject:[NSNumber numberWithBool:needRefreshFiles] afterDelay:0.2];
        }
    }
}

- (void)proportionBtnAction:(UIButton *)sender {
    if (sender.tag == selectedProportionIndex) {
        return;
    }
    if( labelBtnArray!= nil )
    {
        [labelBtnArray enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.textColor = [UIColor whiteColor];
        }];
        
        labelBtnArray[sender.tag-5].textColor = Main_Color;
    }
    UIButton *prevBtn = [proportionScrollView viewWithTag:selectedProportionIndex];
    prevBtn.selected = NO;
    sender.selected = YES;
    selectedProportionIndex = sender.tag;
    
    _cropType = (FileCropModeType)(sender.tag - 4);
    [_cliper setCropType:_cropType];
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
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self refreshPlayer:[NSNumber numberWithBool:NO]];
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress:0 animated:NO];
    
    CGSize size = CGSizeMake(_presentationSize.width * _originFile.crop.size.width, _presentationSize.height * _originFile.crop.size.height);
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
        case 1:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
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
                [self refreshPlayer:[NSNumber numberWithBool:NO]];
            }
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//AE 图片素材编辑
#pragma mark- 图片素材 滤镜
- (UIView *)filterView{
    if(!_filterView){
        
        _filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        
        _filterView = [UIView new];
        _filterView.frame = CGRectMake(0, 0, kWIDTH, kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight);
        _filterView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        
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
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
            if(idx == 0){
                NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
            }else
                item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
            [self.filterChildsView addSubview:item];
            [item setSelected:(idx == _originFile.filterIndex ? YES : NO)];
        }];
        
        _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    }
    return _filterView;
}

#pragma mark - scrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item {
    //滤镜
    __weak typeof(self) myself = self;
    [((ScrollViewChildItem *)[_filterChildsView viewWithTag:_originFile.filterIndex+1]) setSelected:NO];
    [item setSelected:YES];
    [self refreshFilter:item.tag - 1];
    if(![_videoCoreSDK isPlaying]){
        [_videoCoreSDK filterRefresh:_videoCoreSDK.currentTime];
        //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
        [self playVideo:YES];
    }
}

- (void)refreshFilter:(NSInteger)filterIndex {
    _originFile.filterIndex = filterIndex;
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
            if (filter.filterPath.length > 0) {
                asset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }];
    }];
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

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
