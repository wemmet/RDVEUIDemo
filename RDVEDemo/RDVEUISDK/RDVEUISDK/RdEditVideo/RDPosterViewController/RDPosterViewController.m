//
//  RDPosterViewController.m
//  RDVEUISDK
//
//  Created by emmet on 2017/7/31.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//
#import "RDVEUISDK-PrefixHeader.pch"
#import "RDPosterViewController.h"
#import "RDHelpClass.h"
#import "RDMainViewController.h"
#import "RDNavigationViewController.h"

@interface RDPosterViewController (){
    NSMutableArray<RDFile *> *newAssets;
    NSMutableArray *newAssetsImage;
    NSMutableArray *toolItems;
    NSMutableArray *proportionItems;
    NSMutableArray *maskLayers;
    NSMutableArray *childViews;
    RDPosterEditView *selectEditView;

}

@property (nonatomic,strong) UIImageView    * editView;

@property (nonatomic,strong) UIButton       * backButton;

@property (nonatomic,strong) UIButton       * finishButton;

@property (nonatomic,strong) UIScrollView   *toolBarView;

@property (nonatomic,strong) UIScrollView   *proportionView;

@property (nonatomic,strong) UIScrollView   *styleView;

@property (nonatomic,strong) UIScrollView   *borderView;

@property (nonatomic,strong) UIButton       * saveButton;

@end

@implementation RDPosterViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);
    
    
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:[UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)] cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.finishButton];
 
    [self resetViewByStyleIndex:_selectStyleIndex imageCount:[newAssetsImage count] selectEditView:nil];
   
    
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
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    newAssetsImage = [_assetsImage mutableCopy];
    newAssets      = [_assets mutableCopy];
    
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.translucent = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationItem setHidesBackButton:YES];
    
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.title = RDLocalizedString(@"title-poster", nil);
    
    [self.view addSubview:self.toolBarView];
    
    [self.view addSubview:self.styleView];
    
    [self.view addSubview:self.borderView];
    
    [self.view addSubview:self.proportionView];
    
    [self.view addSubview:self.contentView];
    
    [self.view addSubview:self.saveButton];
    
    
    
    // Tap Gesture
    //    UITapGestureRecognizer *tapTextEdit = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textEditTapped)];
    //    tapTextEdit.delegate = self;
    //    [_contentView addGestureRecognizer:tapTextEdit];
    //    [_contentView setUserInteractionEnabled:YES];
    
    // Drag Gesture
    //    UIPanGestureRecognizer *dragTextEdit = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(textEditDrag:)];
    //    [_contentView addGestureRecognizer:dragTextEdit];
}

/**返回按键
 */
- (UIButton *)backButton{
    if(!_backButton){
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.backgroundColor = [UIColor clearColor];
        _backButton.frame = CGRectMake(5, 0, 44, 44);
        [_backButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步取消默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        
        [_backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _backButton;
}

/**完成按键
 */
- (UIButton *)finishButton{
    if(!_finishButton){
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishButton.backgroundColor = [UIColor clearColor];
        _finishButton.frame = CGRectMake(kWIDTH - 60, 0, 60, 44);
        [_finishButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步完成默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_finishButton addTarget:self action:@selector(tapFinishBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _finishButton;
}

/**保存当前操作按键
 */
- (UIButton *)saveButton{
    if(!_saveButton){
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveButton.backgroundColor = [UIColor clearColor];
        _saveButton.frame = CGRectMake(kWIDTH - 75, kHEIGHT - 44 - (iPhone4s ? 73 : 83) - 40, 60, 30);
        [_saveButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_勾默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_saveButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_勾点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];

        [_saveButton addTarget:self action:@selector(tapsaveBtn) forControlEvents:UIControlEventTouchUpInside];
        _saveButton.hidden = YES;
    }
    
    return _saveButton;
}

- (UIImageView *)freeBgView{
    if(!_freeBgView){
        _freeBgView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [_freeBgView setBackgroundColor:[UIColor whiteColor]];
    }
    
    return _freeBgView;
}

- (UIImageView *)bringPosterView{
    if(!_bringPosterView){
        _bringPosterView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [_bringPosterView setBackgroundColor:[UIColor clearColor]];
    }
    
    return _bringPosterView;
}

- (void)removeEditView{
    if(_editView){
        [_editView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_editView removeFromSuperview];
        _editView = nil;
    }
}

- (void)initEditView:(BOOL )top typeImage:(BOOL)typeImage originY:(float)y{
   
    [self removeEditView];
    
    _editView = [UIImageView new];
    _editView.backgroundColor = [UIColor clearColor];
    _editView.userInteractionEnabled = YES;
    UIButton *changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *zoomOutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *zoomInBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *volumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];

    float width = 33;
    float spanwidth = 27;
    float originY = 4;
    
    [changeBtn addTarget:self action:@selector(selectFile) forControlEvents:UIControlEventTouchUpInside];
    [rotateBtn addTarget:self action:@selector(rotateFile) forControlEvents:UIControlEventTouchUpInside];
    [zoomOutBtn addTarget:self action:@selector(zoomOutFile) forControlEvents:UIControlEventTouchUpInside];
    [zoomInBtn addTarget:self action:@selector(zoomInFile) forControlEvents:UIControlEventTouchUpInside];
    [volumeBtn addTarget:self action:@selector(changeFileVolume:) forControlEvents:UIControlEventTouchUpInside];
    
    [changeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_选择素材默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [changeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_选择素材点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    [rotateBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_旋转默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [rotateBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_旋转点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    [zoomOutBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_缩小默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [zoomOutBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_缩小材点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    [zoomInBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_放大默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [zoomInBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_放大点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    if(newAssets[selectEditView.tag].videoVolume == 0){
        [volumeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_无音效默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [volumeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_无音效点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    }else{
        [volumeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_音效默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [volumeBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_音效点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    }
    if(top){
        originY = 4;
        if(typeImage){
            _editView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_上弹1_@3x" Type:@"png"]];
            volumeBtn.hidden = YES;
            _editView.frame = CGRectMake((kWIDTH - _editView.image.size.width)/2.0, y, 235, 48);

        }else{
            _editView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_上弹2_@3x" Type:@"png"]];
            _editView.frame = CGRectMake((kWIDTH - _editView.image.size.width)/2.0,y, 299, 48);

        }
        
    }else{
        originY = 10;
        if(typeImage){
            _editView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_下弹1_@3x" Type:@"png"]];
            volumeBtn.hidden = YES;
            _editView.frame = CGRectMake((kWIDTH - _editView.image.size.width)/2.0, y, 235, 48);

        }else{
            _editView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_下弹2_@3x" Type:@"png"]];
            _editView.frame = CGRectMake((kWIDTH - _editView.image.size.width)/2.0,y, 299, 48);

        }
    }
    changeBtn.frame = CGRectMake(14, originY, width, width);
    rotateBtn.frame = CGRectMake(changeBtn.frame.origin.x + changeBtn.frame.size.width + spanwidth, originY, width, width);
    zoomOutBtn.frame = CGRectMake(rotateBtn.frame.origin.x + rotateBtn.frame.size.width + spanwidth, originY, width, width);
    zoomInBtn.frame = CGRectMake(zoomOutBtn.frame.origin.x + zoomOutBtn.frame.size.width + spanwidth, originY, width, width);
    volumeBtn.frame = CGRectMake(zoomInBtn.frame.origin.x + zoomInBtn.frame.size.width + spanwidth, originY, width, width);
    
    [_editView addSubview:changeBtn];
    [_editView addSubview:rotateBtn];
    [_editView addSubview:zoomOutBtn];
    [_editView addSubview:zoomInBtn];
    [_editView addSubview:volumeBtn];
    
    [_contentView addSubview:_editView];
    
}

- (void)showEditView:(NSInteger )top typeImage:(BOOL)typeImage{
    
}

- (UIScrollView *)contentView{
    if(!_contentView){
        _contentView =  [UIScrollView new];
        
        _contentView.backgroundColor = UIColorFromRGB(0x545454);
        _contentView.showsVerticalScrollIndicator = NO;
        _contentView.showsHorizontalScrollIndicator = NO;
        
        [self changeProportion];
        
        
        
        [self.contentView addSubview:self.freeBgView];
        
        // Border
        
        [self.contentView addSubview:self.bringPosterView];
        
        // LongPress Gesture
//        UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPressGestureRecognized:)];
//        gesture.minimumPressDuration = 0.8;
//        [self.contentView addGestureRecognizer:gesture];
        [self.contentView setUserInteractionEnabled:YES];
        
    }
    return _contentView;

}

- (void)changeProportion{
    float height = kHEIGHT - 44 - (iPhone4s ? 73 : 83);
    if(_proportionValue == kPROPORTION1_1){
        _contentView.frame = CGRectMake(0, (height - kWIDTH)/2.0, kWIDTH, kWIDTH);
    }else if(_proportionValue == kPROPORTION4_3){
        _contentView.frame = CGRectMake(0, (height - (kWIDTH * 3.0/4.0))/2.0, kWIDTH, kWIDTH * 3.0/4.0);
    }
    else if(_proportionValue == kPROPORTION3_4){
        _contentView.frame = CGRectMake(0, (height - (kWIDTH * 4.0/3.0))/2.0, kWIDTH, kWIDTH * 4.0/3.0);
    }
    else if(_proportionValue == kPROPORTION16_9){
        _contentView.frame = CGRectMake(0, (height - (kWIDTH * 9.0/16.0))/2.0 , kWIDTH, kWIDTH * 9.0/16.0);
    }
    else if(_proportionValue == kPROPORTION9_16){
        _contentView.frame = CGRectMake((kWIDTH - ((height - 40) * 9.0/16.0))/2.0, 20, ((height - 40) * 9.0/16.0), height - 40);
    }
    _freeBgView.frame = _contentView.bounds;
}

- (UIScrollView *)borderView{
    if(!_borderView){
        _borderView =  [UIScrollView new];
        _borderView.frame = CGRectMake(0, kHEIGHT - 44 - (iPhone4s ? 73 : 83), kWIDTH, (iPhone4s ? 73 : 83));
        _borderView.backgroundColor = UIColorFromRGB(NV_Color);
        _borderView.showsVerticalScrollIndicator = NO;
        _borderView.showsHorizontalScrollIndicator = NO;
        
        
        float width = 33.0;
        
        float spanwidth = (kWIDTH > 320 ? 24 : 16);
        
        UILabel *borderWidthLabel = [UILabel new];
        borderWidthLabel.frame = CGRectMake(40, 8, 38, width);
        borderWidthLabel.backgroundColor = [UIColor clearColor];
        borderWidthLabel.textColor = UIColorFromRGB(0x888888);
        borderWidthLabel.text = RDLocalizedString(@"边框", nil);
        borderWidthLabel.font = [UIFont systemFontOfSize:15];
        borderWidthLabel.textAlignment = NSTextAlignmentLeft;
        [_borderView addSubview:borderWidthLabel];
        
        UIButton *borderNone = [UIButton buttonWithType:UIButtonTypeCustom];
        borderNone.tag = 1;
        borderNone.backgroundColor = [UIColor clearColor];
        borderNone.frame = CGRectMake(borderWidthLabel.frame.origin.x + borderWidthLabel.frame.size.width + spanwidth, 7, width, width);
        [borderNone addTarget:self action:@selector(clickborderWidthItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        [borderNone setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框无_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [borderNone setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框无_@3x" Type:@"png"]] forState:UIControlStateSelected];
        borderNone.layer.cornerRadius = width/2.0;
        [_borderView addSubview:borderNone];
        
        if (_selectBorderWidthStyle == 0) {
            borderNone.layer.borderColor = [UIColor yellowColor].CGColor;
            borderNone.layer.borderWidth = 2.0;
        }
        
        UIButton *borderFine = [UIButton buttonWithType:UIButtonTypeCustom];
        borderFine.tag = 2;
        borderFine.backgroundColor = [UIColor clearColor];
        borderFine.frame = CGRectMake(borderNone.frame.origin.x + borderNone.frame.size.width + spanwidth, 7, width, width);
        [borderFine addTarget:self action:@selector(clickborderWidthItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        [borderFine setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框1_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [borderFine setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框1_@3x" Type:@"png"]] forState:UIControlStateSelected];
        borderFine.layer.cornerRadius = width/2.0;
        [_borderView addSubview:borderFine];
        
        if (_selectBorderWidthStyle == 1) {
            borderFine.layer.borderColor = [UIColor yellowColor].CGColor;
            borderFine.layer.borderWidth = 2.0;
        }
        
        UIButton *borderMiddle = [UIButton buttonWithType:UIButtonTypeCustom];
        borderMiddle.tag = 3;
        borderMiddle.backgroundColor = [UIColor clearColor];
        borderMiddle.frame = CGRectMake(borderFine.frame.origin.x + borderFine.frame.size.width + spanwidth, 7, width, width);
        [borderMiddle addTarget:self action:@selector(clickborderWidthItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        [borderMiddle setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框2_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [borderMiddle setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框2_@3x" Type:@"png"]] forState:UIControlStateSelected];
        borderMiddle.layer.cornerRadius = width/2.0;
        [_borderView addSubview:borderMiddle];
        
        if (_selectBorderWidthStyle == 2) {
            borderMiddle.layer.borderColor = [UIColor yellowColor].CGColor;
            borderMiddle.layer.borderWidth = 2.0;
        }
        
        UIButton *borderWidth = [UIButton buttonWithType:UIButtonTypeCustom];
        borderWidth.tag = 4;
        borderWidth.backgroundColor = [UIColor clearColor];
        borderWidth.frame = CGRectMake(borderMiddle.frame.origin.x + borderMiddle.frame.size.width + spanwidth, 7, width, width);
        [borderWidth addTarget:self action:@selector(clickborderWidthItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        [borderWidth setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框3_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [borderWidth setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框3_@3x" Type:@"png"]] forState:UIControlStateSelected];
        borderWidth.layer.cornerRadius = width/2.0;
        [_borderView addSubview:borderWidth];
        
        if (_selectBorderWidthStyle == 3) {
            borderWidth.layer.borderColor = [UIColor yellowColor].CGColor;
            borderWidth.layer.borderWidth = 2.0;
        }
        
        UILabel *borderColorLabel = [UILabel new];
        borderColorLabel.frame = CGRectMake(40, (_borderView.frame.size.height - 7 - width), 38, width);
        borderColorLabel.backgroundColor = [UIColor clearColor];
        borderColorLabel.textColor = UIColorFromRGB(0x888888);
        borderColorLabel.text = RDLocalizedString(@"颜色", nil);
        borderColorLabel.font = [UIFont systemFontOfSize:15];
        borderColorLabel.textAlignment = NSTextAlignmentLeft;
        [_borderView addSubview:borderColorLabel];
        
        UIButton *borderColorWhite = [UIButton buttonWithType:UIButtonTypeCustom];
        borderColorWhite.tag = 100;
        borderColorWhite.backgroundColor = [UIColor clearColor];
        borderColorWhite.frame = CGRectMake(borderColorLabel.frame.origin.x + borderColorLabel.frame.size.width + spanwidth, (_borderView.frame.size.height - 7 - width), width, width);
        [borderColorWhite addTarget:self action:@selector(clickborderColorItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        [borderColorWhite setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框白_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [borderColorWhite setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框白_@3x" Type:@"png"]] forState:UIControlStateSelected];
        borderColorWhite.layer.cornerRadius = width/2.0;;
        [_borderView addSubview:borderColorWhite];
        
        if (_selectBorderColorStyle == 0) {
            borderColorWhite.layer.borderColor = [UIColor yellowColor].CGColor;
            borderColorWhite.layer.borderWidth = 2.0;
        }
        
        UIButton *borderColorBlack = [UIButton buttonWithType:UIButtonTypeCustom];
        borderColorBlack.tag = 101;
        borderColorBlack.backgroundColor = [UIColor clearColor];
        borderColorBlack.frame = CGRectMake(borderColorWhite.frame.origin.x + borderColorWhite.frame.size.width + spanwidth, (_borderView.frame.size.height - 7 - width), width, width);
        [borderColorBlack addTarget:self action:@selector(clickborderColorItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        [borderColorBlack setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框黑_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [borderColorBlack setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框黑_@3x" Type:@"png"]] forState:UIControlStateSelected];
        borderColorBlack.layer.cornerRadius = width/2.0;;
        [_borderView addSubview:borderColorBlack];
        
        if (_selectBorderColorStyle == 1) {
            borderColorBlack.layer.borderColor = [UIColor yellowColor].CGColor;
            borderColorBlack.layer.borderWidth = 2.0;
        }
        
        _borderView.hidden = YES;
        
    }
    
    return _borderView;
}

- (UIScrollView *)toolBarView{
    if(!_toolBarView){
        NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"比例", nil),@"title",@(1),@"id", nil];
        NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"板式", nil),@"title",@(2),@"id", nil];
        NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"边框", nil),@"title",@(3),@"id", nil];
        
        toolItems = [NSMutableArray array];
        
        [toolItems addObject:dic1];
        [toolItems addObject:dic2];
        [toolItems addObject:dic3];
        
        
        _toolBarView =  [UIScrollView new];
        _toolBarView.frame = CGRectMake(0, kHEIGHT - 44 - (iPhone4s ? 73 : 83), kWIDTH, (iPhone4s ? 73 : 83));
        _toolBarView.backgroundColor = UIColorFromRGB(NV_Color);
        _toolBarView.showsVerticalScrollIndicator = NO;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        
        __block float toolItemBtnWidth = MAX(kWIDTH/toolItems.count, _toolBarView.frame.size.height + 5);
        __block float contentsWidth = 0;
        [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth, (_toolBarView.frame.size.height - 60)/2.0, toolItemBtnWidth, 60);
            [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self toolItemsImagePath:toolItemBtn.tag - 1]] forState:UIControlStateNormal];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self toolItemsSelectImagePath:toolItemBtn.tag - 1]] forState:UIControlStateSelected];
            [toolItemBtn setTitle:[toolItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
            [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            [_toolBarView addSubview:toolItemBtn];
            contentsWidth += toolItemBtnWidth;
        }];
        _toolBarView.contentSize = CGSizeMake(contentsWidth, 0);
        
    }
    return _toolBarView;
}


- (UIScrollView *)proportionView{
    if(!_proportionView){
        
        proportionItems = [NSMutableArray array];
        
        NSDictionary *dic1 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"1:1", nil),@"title",@(1),@"id", nil];
        NSDictionary *dic2 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"4:3", nil),@"title",@(2),@"id", nil];
        NSDictionary *dic3 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"3:4", nil),@"title",@(3),@"id", nil];
        NSDictionary *dic4 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"16:9", nil),@"title",@(4),@"id", nil];
        NSDictionary *dic5 = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"9:16", nil),@"title",@(5),@"id", nil];
        
        
        [proportionItems addObject:dic1];
        [proportionItems addObject:dic2];
        [proportionItems addObject:dic3];
        [proportionItems addObject:dic4];
        [proportionItems addObject:dic5];
        
        
        _proportionView =  [UIScrollView new];
        _proportionView.frame = CGRectMake(0, kHEIGHT - 44 - (iPhone4s ? 73 : 83), kWIDTH, (iPhone4s ? 73 : 83));
        _proportionView.backgroundColor = UIColorFromRGB(NV_Color);
        _proportionView.showsVerticalScrollIndicator = NO;
        _proportionView.showsHorizontalScrollIndicator = NO;
        
        __block float toolItemBtnWidth = 44;

        float spanWidth = MAX(((kWIDTH - (kWIDTH>320 ? 112 : 40)) - toolItemBtnWidth*proportionItems.count)/(proportionItems.count - 1), 20);
        [proportionItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [[proportionItems[idx] objectForKey:@"id"] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.frame = CGRectMake(idx * (toolItemBtnWidth + spanWidth) + (kWIDTH>320 ? 112 : 40)/2.0, (_proportionView.frame.size.height - 44)/2.0, toolItemBtnWidth, 44);
            [toolItemBtn addTarget:self action:@selector(clickProportionItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:toolItemBtn.tag - 1 type:0]] forState:UIControlStateNormal];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:toolItemBtn.tag - 1 type:0]] forState:UIControlStateSelected];
            [_proportionView addSubview:toolItemBtn];
        }];
        _proportionView.contentSize = CGSizeMake(proportionItems.count * (toolItemBtnWidth + spanWidth) + (kWIDTH>320 ? 112 : 40)/2.0, _proportionView.frame.size.height);
        _proportionView.hidden = YES;
    }
    return _proportionView;
}

- (UIScrollView *)styleView{
    if(!_styleView){
        
        NSMutableArray *styleItems = [NSMutableArray array];
        for(int i=0;i<10;i++){
            [styleItems addObject:@(i+1)];
        }
        
        
        _styleView =  [UIScrollView new];
        _styleView.frame = CGRectMake(0, kHEIGHT - 44 - (iPhone4s ? 73 : 83), kWIDTH, (iPhone4s ? 73 : 83));
        _styleView.backgroundColor = UIColorFromRGB(NV_Color);
        _styleView.showsVerticalScrollIndicator = NO;
        _styleView.showsHorizontalScrollIndicator = NO;
        
        __block float toolItemBtnWidth = 60;
        
        float spanWidth = MAX(((kWIDTH - 30) - toolItemBtnWidth*proportionItems.count)/(proportionItems.count - 1), 20);
        
        [styleItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toolItemBtn.tag = [styleItems[idx] integerValue];
            toolItemBtn.backgroundColor = [UIColor clearColor];
            toolItemBtn.frame = CGRectMake(idx * (toolItemBtnWidth + spanWidth) + 30, (_styleView.frame.size.height - 60)/2.0, toolItemBtnWidth, 60);
            [toolItemBtn addTarget:self action:@selector(clickStyleItemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self styleItemsImagePath:toolItemBtn.tag - 1]] forState:UIControlStateNormal];
            [toolItemBtn setImage:[UIImage imageWithContentsOfFile:[self styleItemsImagePath:toolItemBtn.tag - 1]] forState:UIControlStateSelected];
            [toolItemBtn setTitle:[NSString stringWithFormat:@"style_%ld",(long)[styleItems[idx] integerValue]] forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
            [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            [_styleView addSubview:toolItemBtn];
        }];
        _styleView.contentSize = CGSizeMake(styleItems.count * (toolItemBtnWidth + spanWidth) + 30, 0);
        _styleView.hidden = YES;
    }
    return _styleView;
}


- (void)clickToolItemBtn:(UIButton *)sender{
    switch (sender.tag) {
        case 1://比例
        {
            self.toolBarView.hidden = YES;
            self.proportionView.hidden = NO;
            self.styleView.hidden = YES;
            self.borderView.hidden = YES;
        }
            break;
        case 2://板式
        {
            self.toolBarView.hidden = YES;
            self.proportionView.hidden = YES;
            self.styleView.hidden = NO;
            self.borderView.hidden = YES;
            self.saveButton.hidden = NO;
        }
            break;
        case 3://边框
        {
            self.toolBarView.hidden = YES;
            self.proportionView.hidden = YES;
            self.styleView.hidden = YES;
            self.borderView.hidden = NO;
            self.saveButton.hidden = NO;
        }
            break;
            
        default:
            break;
    }
}

- (void)clickProportionItemBtn:(UIButton *)sender{
    
    selectEditView = nil;
    
    NSInteger tag = [[toolItems[0] objectForKey:@"id"] integerValue];
    
    _toolBarView.hidden = NO;
    
    _proportionView.hidden = YES;
    RDProportionType proportionValue;
    switch (sender.tag) {
        case 1://1:1
        {
            proportionValue = kPROPORTION1_1;
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"1:1", nil) forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"1:1", nil) forState:UIControlStateSelected];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:0 type:1]] forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:0 type:1]] forState:UIControlStateSelected];
        }
            break;
        case 2://4:3
        {
            proportionValue = kPROPORTION4_3;
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"4:3", nil) forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"4:3", nil) forState:UIControlStateSelected];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:1 type:1]] forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:1 type:1]] forState:UIControlStateSelected];
        }
            break;
        case 3://3:4
        {
            proportionValue = kPROPORTION3_4;
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"3:4", nil) forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"3:4", nil) forState:UIControlStateSelected];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:2 type:1]] forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:2 type:1]] forState:UIControlStateSelected];
        }
            break;
        case 4://16:9
        {
            proportionValue = kPROPORTION16_9;
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"16:9", nil) forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"16:9", nil) forState:UIControlStateSelected];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:3 type:1]] forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:3 type:1]] forState:UIControlStateSelected];
        }
            break;
        case 5://9:16
        {
            proportionValue = kPROPORTION9_16;
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"9:16", nil) forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setTitle:RDLocalizedString(@"9:16", nil) forState:UIControlStateSelected];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsImagePath:4 type:1]] forState:UIControlStateNormal];
            [((UIButton *)[_toolBarView viewWithTag:tag]) setImage:[UIImage imageWithContentsOfFile:[self proportionItemsSelectImagePath:4 type:1]] forState:UIControlStateSelected];
        }
            break;
        default:
            proportionValue = _proportionValue;
            break;
    }
    if(proportionValue == _proportionValue){
    
        return;
    }
    _proportionValue = proportionValue;
    [childViews removeAllObjects];
    
    [self changeProportion];
    
    [self removeContentViewChilds];
    [self resetViewByStyleIndex:_selectStyleIndex imageCount:[newAssetsImage count] selectEditView:nil];
}

- (void)clickStyleItemBtn:(UIButton *)sender{
    selectEditView = nil;
    [childViews removeAllObjects];
    [self removeContentViewChilds];
    [self resetViewByStyleIndex:sender.tag-1 imageCount:[newAssetsImage count] selectEditView:nil];
}

- (void)removeContentViewChilds{
    [self.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDPosterEditView class]]){
            [obj removeFromSuperview];
        }
    }];
}

- (void)clickborderWidthItemBtn:(UIButton *)sender{
    UIButton *oldSelectSender = [sender.superview viewWithTag:(_selectBorderWidthStyle +1)];
    oldSelectSender.layer.borderColor = [UIColor clearColor].CGColor;
    oldSelectSender.layer.borderWidth = 0.0;
    sender.layer.borderColor = [UIColor yellowColor].CGColor;
    sender.layer.borderWidth = 2.0;
    _selectBorderWidthStyle = sender.tag - 1;
    selectEditView = nil;
    [self removeContentViewChilds];
    [self resetViewByStyleIndex:_selectStyleIndex imageCount:newAssetsImage.count selectEditView:nil];
    
}

- (void)clickborderColorItemBtn:(UIButton *)sender{
    selectEditView = nil;
    UIButton *oldSelectSender = [sender.superview viewWithTag:(_selectBorderColorStyle +100)];
    oldSelectSender.layer.borderColor = [UIColor clearColor].CGColor;
    oldSelectSender.layer.borderWidth = 0.0;
    sender.layer.borderColor = [UIColor yellowColor].CGColor;
    sender.layer.borderWidth = 2.0;
    _selectBorderColorStyle = sender.tag - 100;
    [self removeContentViewChilds];
    [self resetViewByStyleIndex:_selectStyleIndex imageCount:newAssetsImage.count selectEditView:nil];
    
}
/**返回
 */
- (void)back{
    [self.navigationController popViewControllerAnimated:YES];
}

/**完成
 */
- (void)tapFinishBtn{
    [self.navigationController popViewControllerAnimated:YES];
}

/**保存当前操作
 */
- (void)tapsaveBtn{
    self.toolBarView.hidden = NO;
    self.proportionView.hidden = YES;
    self.styleView.hidden = YES;
    self.borderView.hidden = YES;
    self.saveButton.hidden = YES;
}

/**选择素材
 */
- (void)selectFile{
    
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
//    mainVC.textPhotoProportion = exportSize.width/(float)exportSize.height;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
        UIImage *image = [filelist firstObject].thumbImage;
        for (RDFile *file in filelist) {
            [newAssets replaceObjectAtIndex:selectEditView.tag == kNONESELECTEDIT ? 0 : selectEditView.tag withObject:file];
        }
        [newAssetsImage replaceObjectAtIndex:selectEditView.tag == kNONESELECTEDIT ? 0 : selectEditView.tag withObject:image];
        [selectEditView setImageViewData:image reset:YES];
        
        selectEditView = nil;
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [self setNavConfig:nav];
    nav.editConfiguration.mediaCountLimit = 1;
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];

}

/**旋转
 */
- (void)rotateFile{
    if(newAssets[selectEditView.tag].rotate == 0){
        newAssets[selectEditView.tag].rotate = -270;
    }
    else if(newAssets[selectEditView.tag].rotate == -270){
        newAssets[selectEditView.tag].rotate = -180;
    }
    else if(newAssets[selectEditView.tag].rotate == -180){
        newAssets[selectEditView.tag].rotate = -90;
    }
    else if(newAssets[selectEditView.tag].rotate == -90){
        newAssets[selectEditView.tag].rotate = 0;
    }
    UIImage *image  = [RDHelpClass getFullScreenImageWithUrl:newAssets[selectEditView.tag].contentURL];
    [newAssetsImage replaceObjectAtIndex:selectEditView.tag withObject:[RDHelpClass imageRotatedByDegrees:image rotation:newAssets[selectEditView.tag].rotate]];
    [selectEditView setImageViewData:[newAssetsImage objectAtIndex:selectEditView.tag] reset:YES];
}

/**缩小
 */
- (void)zoomInFile{
    [selectEditView zoomIn];
}

/**放大
 */
- (void)zoomOutFile{
    [selectEditView zoomOut];
}

/**改变音量
 */
- (void)changeFileVolume:(UIButton *)sender{
    newAssets[selectEditView.tag].videoVolume = newAssets[selectEditView.tag].videoVolume==0 ? 1 : 0;
    if(newAssets[selectEditView.tag].videoVolume == 0){
        [sender setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_无音效默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_无音效点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    }else{
        [sender setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_音效默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:kBundName resourceName:@"/poster/ios/剪辑-画中画_音效点击_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    }
}

- (NSString *)toolItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框默认_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_板式默认_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

- (NSString *)toolItemsSelectImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框点击_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_板式点击@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画_边框点击_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

//获取比例icon
- (NSString *)proportionItemsImagePath:(NSInteger)index type:(NSInteger)type{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_1比1默认_@3x" : @"/poster/剪辑-画中画_比例_1比1默认_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_4比3默认_@3x" : @"/poster/剪辑-画中画_比例_4比3默认_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_3比4默认_@3x" : @"/poster/剪辑-画中画_比例_3比4默认_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_16比9默认_@3x" : @"/poster/剪辑-画中画_比例_16比9默认_@3x" Type:@"png"];
        }
            break;
        case 4:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_9比16默认_@3x" : @"/poster/剪辑-画中画_比例_9比16默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

- (NSString *)proportionItemsSelectImagePath:(NSInteger)index type:(NSInteger)type{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_1比1点击_@3x" : @"/poster/剪辑-画中画_比例_1比1选中_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_4比3点击_@3x" : @"/poster/剪辑-画中画_比例_4比3选中_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_3比4点击_@3x" : @"/poster/剪辑-画中画_比例_3比4选中_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_16比9点击_@3x" : @"/poster/剪辑-画中画_比例_16比9选中_@3x" Type:@"png"];
        }
            break;
        case 4:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:type == 1 ? @"/poster/剪辑-画中画_9比16点击_@3x" : @"/poster/剪辑-画中画_比例_9比16选中_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

//获取板式icon
- (NSString *)styleItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画默认_@3x"Type:@"png"];
    
    return imagePath;
}

- (NSString *)styleItemsSelectImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/poster/剪辑-画中画默认_@3x"Type:@"png"];
    
    //imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/poster/styleIcon/number_two_style_%ld.",index] Type:@"png"];

    return imagePath;
}

#pragma mark - Gesture
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)gesture
{
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            break;
        }
        default:
            break;
    }
}

- (void)setNavConfig:(RDNavigationViewController *)nav{
    nav.edit_functionLists = ((RDNavigationViewController *)self.navigationController).edit_functionLists;
    nav.exportConfiguration = ((RDNavigationViewController *)self.navigationController).exportConfiguration;
    nav.editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    nav.cameraConfiguration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration;
    nav.outPath = ((RDNavigationViewController *)self.navigationController).outPath;
    nav.appAlbumCacheName = ((RDNavigationViewController *)self.navigationController).appAlbumCacheName;
    nav.appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    nav.appSecret = ((RDNavigationViewController *)self.navigationController).appSecret;
    nav.statusBarHidden = ((RDNavigationViewController *)self.navigationController).statusBarHidden;
    nav.folderType = ((RDNavigationViewController *)self.navigationController).folderType;
    nav.disable = ((RDNavigationViewController *)self.navigationController).disable;
    nav.videoAverageBitRate = ((RDNavigationViewController *)self.navigationController).videoAverageBitRate;
    nav.waterLayerRect = ((RDNavigationViewController *)self.navigationController).waterLayerRect;
    nav.callbackBlock = ((RDNavigationViewController *)self.navigationController).callbackBlock;
    nav.rdVeUiSdkDelegate = ((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate;
}

- (void)tapImageView
{
    
}

- (void)resetViewByStyleIndex:(NSInteger)index imageCount:(NSInteger)count selectEditView:(RDPosterEditView *)sender
{
    @synchronized(self)
    {
        
        _selectStyleIndex = index;
        
        
        float   lineWidth = 0;
        UIColor *lineColor;
        NSString *arrkey = @"SubViewArray";
        switch (_selectBorderColorStyle) {
            case 0:
                lineColor = UIColorFromRGB(0xffffff);
                break;
            case 1:
                lineColor = UIColorFromRGB(0x000000);
                break;
                
            default:
                lineColor = UIColorFromRGB(0xffffff);
                break;
        }
        switch (_selectBorderWidthStyle) {
            case 0:
                lineWidth = 0;
                break;
            case 1:
                lineWidth = 5;
                break;
            case 2:
                lineWidth = 10;
                break;
            case 3:
                lineWidth = 20;
                break;
            default:
                lineWidth = 0;
                break;
        }
        
        
        if(sender.tag == kNONESELECTEDIT || !sender){
            self.bringPosterView.backgroundColor = [UIColor clearColor];
            [self removeEditView];
            
        }else{
            self.bringPosterView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
            BOOL top = sender.frame.origin.y + sender.frame.size.height + lineWidth *2.0<_contentView.frame.size.height;
            
            float y = top ? MAX(0, sender.frame.origin.y - 48) : _contentView.frame.size.height - 48;
            
            [self initEditView:top typeImage:top originY:y];
        }
        if(!maskLayers){
            maskLayers = [NSMutableArray array];
        }else{
            [maskLayers enumerateObjectsUsingBlock:^(CAShapeLayer *_Nonnull maskLayer, NSUInteger idx, BOOL * _Nonnull stop) {
                [maskLayer removeFromSuperlayer];
                
            }];
            [maskLayers removeAllObjects];
        }
        if (0)//[newAssetsImage count] == 1
        {
#if 0
            UIImage *image = [newAssetsImage objectAtIndex:0];
            
            CGRect rect = CGRectZero;
            rect.origin.x = 0;
            rect.origin.y = 0;
            CGFloat height = image.size.height;
            CGFloat width = image.size.width;
            if (width > _contentView.frame.size.width)
            {
                rect.size.width = _contentView.frame.size.width;
                rect.size.height = height*(_contentView.frame.size.width /width);
            }
            else
            {
                rect.size.width = width;
                rect.size.height = height;
            }
            
            rect.origin.x = (_contentView.frame.size.width - rect.size.width)/2.0f;
            if (rect.size.height < self.contentView.frame.size.height)
            {
                rect.origin.y = (_contentView.frame.size.height - rect.size.height)/2.0f;
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
            [imageView setClipsToBounds:YES];
            [imageView setBackgroundColor:[UIColor grayColor]];
            [imageView setImage:image];
            
            imageView.userInteractionEnabled = YES;
            UIGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapImageView)];
            [imageView addGestureRecognizer:singleTap];
            
            imageView.layer.borderWidth = 0;
            imageView.layer.borderColor = [UIColor cyanColor].CGColor;
            
            
            [_contentView addSubview:imageView];
            imageView = nil;
#endif
        }
        else
        {
           NSString *path = [RDHelpClass getResourceFromBundle:kBundName resourceName:[NSString stringWithFormat:@"/poster/plists/style_%d",(int)index] Type:@"plist"];
            NSDictionary *styleDict = [NSDictionary dictionaryWithContentsOfFile:path];
            if (styleDict)
            {
                CGSize superSize = [self sizeScaleWithScale:1.0f];
                
                
                self.freeBgView.backgroundColor = lineColor;
                
                NSArray *subViewArray = [styleDict objectForKey:arrkey];
                if([subViewArray count]>newAssetsImage.count){
                    for(NSInteger i = newAssetsImage.count;i<subViewArray.count;i++){
                        [newAssetsImage addObject:[newAssetsImage lastObject]];
                        [newAssets addObject:[newAssets lastObject]];
                    }
                }
                for(int j = 0; j <[subViewArray count]; j++)
                {
                    CGRect rect = CGRectZero;
                    UIBezierPath *path = nil;
                    UIImage *image = [newAssetsImage objectAtIndex:j];
                    NSMutableArray *realAreas = [NSMutableArray array];
                    NSDictionary *subDict = [subViewArray objectAtIndex:j];
                    rect = [self rectWithArray:[subDict objectForKey:@"pointArray"] andSuperSize:superSize];
                    if ([subDict objectForKey:@"pointArray"])
                    {
                        NSArray *pointArray = [subDict objectForKey:@"pointArray"];
                        path = [UIBezierPath bezierPath];
                        if (pointArray.count > 2)
                        {
                            // 当点的数量大于2个的时候
                            for(int i = 0; i < [pointArray count]; i++)
                            {
                                NSString *string = [pointArray objectAtIndex:i];
                                NSArray *list = [string componentsSeparatedByString:@"/"];
                                
                                NSString *pointString = [list firstObject];
                                NSString *diffString = list.count>1 ? [list lastObject] : nil;
                                
                                if (pointString)
                                {
                                    CGPoint point = CGPointFromString(pointString);
                                    CGPoint realAreaItem = point;
                                    
                                    point = [self pointScaleWithPoint:point scale:1.0f];
                                    point.x = (point.x)*_contentView.frame.size.width -rect.origin.x;
                                    point.y = (point.y)*_contentView.frame.size.height -rect.origin.y;
                                    
                                    if(diffString){
                                        CGPoint difPoint = CGPointFromString(diffString);
                                        point.x = point.x + difPoint.x * lineWidth;
                                        point.y = point.y + difPoint.y * lineWidth;
                                        realAreaItem.x += (difPoint.x * lineWidth)/_contentView.frame.size.width;
                                        realAreaItem.y += (difPoint.y * lineWidth)/_contentView.frame.size.height;
                                        
                                    }
                                    [realAreas addObject:[NSNumber valueWithCGPoint:realAreaItem]];
                                    
                                    if (i == 0)
                                    {
                                        [path moveToPoint:point];
                                    }
                                    else
                                    {
                                        [path addLineToPoint:point];
                                    }
                                    
                                }
                                
                            }
                        }
                        else
                        {
                            [path moveToPoint:CGPointMake(0, 0)];
                            [path addLineToPoint:CGPointMake(rect.size.width, 0)];
                            [path addLineToPoint:CGPointMake(rect.size.width, rect.size.height)];
                            [path addLineToPoint:CGPointMake(0, rect.size.height)];
                        }
                        
                        [path closePath];
                    }
                    
                    BOOL reset = NO;
                    RDPosterEditView *imageView;
                    if(childViews.count >j){
                         imageView = childViews[j];
                        [imageView setFrame:rect];
                    }else{
                        imageView = [[RDPosterEditView alloc] initWithFrame:rect];
                        [imageView setClipsToBounds:YES];
                        [imageView setBackgroundColor:[UIColor grayColor]];
                        imageView.tapDelegate = self;
                        reset = YES;
                        if(childViews){
                            [childViews addObject:imageView];

                        }else{
                            childViews = [NSMutableArray arrayWithObjects:imageView, nil];

                        }
                    }
                    imageView.tag = j;
                    imageView.realAreas = realAreas;
                    imageView.realCellArea = path;
                    [imageView setImageViewData:image reset:reset];
                    
                    [_contentView addSubview:imageView];
                    
                    CAShapeLayer *maskLayer = [CAShapeLayer layer];
                    maskLayer.path = [path CGPath];
                    if(sender.tag != kNONESELECTEDIT && sender){
                        if(sender.tag == j && sender){
                            maskLayer.lineWidth = 1;
                            maskLayer.strokeColor = [UIColor redColor].CGColor;
                            maskLayer.fillColor = [[UIColor clearColor] CGColor];
                            selectEditView = imageView;
                        }else{
                            maskLayer.lineWidth = 0;
                            maskLayer.strokeColor = [UIColor clearColor].CGColor;
                            maskLayer.fillColor = [[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor];
                        }
                    }else{
                        maskLayer.lineWidth = 0;
                        maskLayer.strokeColor = [UIColor clearColor].CGColor;
                        maskLayer.fillColor = [[UIColor clearColor] CGColor];
                    }
                    
                    maskLayer.frame = imageView.frame;
                    [_contentView.layer addSublayer:maskLayer];
                    [maskLayers addObject:maskLayer];
                    
                    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPressGestureRecognized:)];
                    gesture.minimumPressDuration = 0.8;
                    [imageView addGestureRecognizer:gesture];
                    imageView = nil;
                    
                }
            }
        }
        _contentView.contentSize = _contentView.frame.size;
        self.freeBgView.frame = CGRectMake(0, 0, _contentView.contentSize.width, _contentView.contentSize.height);
        self.bringPosterView.frame = self.freeBgView.frame;
        [_contentView bringSubviewToFront:_editView];
    }
    
}


- (void)tapWithEditView:(RDPosterEditView *)sender
{
    
    if(selectEditView.tag == sender.tag && selectEditView){
        selectEditView = nil;
        [maskLayers enumerateObjectsUsingBlock:^(CAShapeLayer *_Nonnull maskLayer, NSUInteger idx, BOOL * _Nonnull stop) {
            maskLayer.lineWidth = 0;
            maskLayer.strokeColor = [UIColor clearColor].CGColor;
            maskLayer.fillColor = [[UIColor clearColor] CGColor];
        }];
        self.bringPosterView.backgroundColor = [UIColor clearColor];
        [self removeEditView];
        return;
    }
    else{
        selectEditView = sender;
        [maskLayers enumerateObjectsUsingBlock:^(CAShapeLayer *_Nonnull maskLayer, NSUInteger idx, BOOL * _Nonnull stop) {
        if(sender.tag != kNONESELECTEDIT && sender){
            if(sender.tag == idx && sender){
                maskLayer.lineWidth = 1;
                maskLayer.strokeColor = [UIColor redColor].CGColor;
                maskLayer.fillColor = [[UIColor clearColor] CGColor];
                
            }else{
                maskLayer.lineWidth = 0;
                maskLayer.strokeColor = [UIColor clearColor].CGColor;
                maskLayer.fillColor = [[[UIColor blackColor] colorWithAlphaComponent:0.3] CGColor];
            }
        }else{
            maskLayer.lineWidth = 0;
            maskLayer.strokeColor = [UIColor clearColor].CGColor;
            maskLayer.fillColor = [[UIColor clearColor] CGColor];
        }
        }];
        
        float   lineWidth = 0;
        
        switch (_selectBorderWidthStyle) {
            case 0:
                lineWidth = 0;
                break;
            case 1:
                lineWidth = 5;
                break;
            case 2:
                lineWidth = 10;
                break;
            case 3:
                lineWidth = 20;
                break;
            default:
                lineWidth = 0;
                break;
        }

        
        self.bringPosterView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        BOOL top = sender.frame.origin.y + sender.frame.size.height + lineWidth *2.0<_contentView.frame.size.height;
        
        float y = top ? MAX(0, sender.frame.origin.y - 48) : _contentView.frame.size.height - 48;
        
        [self initEditView:top typeImage:newAssets[selectEditView.tag].fileType == kFILEIMAGE originY:y];
    }
    
}

- (void)handpanEditView:(RDPosterEditView *)sender endpointInSuperviewLocation:(CGPoint)point{
   
    __block RDPosterEditView *toPosterEditView = nil;
    [_contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDPosterEditView class]]){
            if(CGRectContainsPoint(obj.frame, point)){
                toPosterEditView = (RDPosterEditView *)obj;
                *stop = YES;
            }
        }
    }];
    
    RDFile *file = [newAssets[sender.tag] copy];
    UIImage *image = [newAssetsImage[sender.tag] copy];
    
    if(toPosterEditView.tag != sender.tag && toPosterEditView){
    
        [newAssets replaceObjectAtIndex:sender.tag withObject:newAssets[toPosterEditView.tag]];
        [newAssetsImage replaceObjectAtIndex:sender.tag withObject:newAssetsImage[toPosterEditView.tag]];
        
        [newAssets replaceObjectAtIndex:toPosterEditView.tag withObject:file];
        [newAssetsImage replaceObjectAtIndex:toPosterEditView.tag withObject:image];
        
        [sender setImageViewData:newAssetsImage[sender.tag] reset:YES];
        [toPosterEditView setImageViewData:newAssetsImage[toPosterEditView.tag] reset:YES];
    }
    
    
}

- (CGRect)rectWithArray:(NSArray *)array andSuperSize:(CGSize)superSize
{
    CGRect rect = CGRectZero;
    CGFloat minX = INT_MAX;
    CGFloat maxX = 0;
    CGFloat minY = INT_MAX;
    CGFloat maxY = 0;
    for (int i = 0; i < [array count]; i++)
    {
        NSString *pointString = [array objectAtIndex:i];
        CGPoint point = CGPointFromString(pointString);
        if (point.x <= minX)
        {
            minX = point.x;
        }
        
        if (point.x >= maxX)
        {
            maxX = point.x;
        }
        
        if (point.y <= minY)
        {
            minY = point.y;
        }
        
        if (point.y >= maxY)
        {
            maxY = point.y;
        }
        rect = CGRectMake(minX, minY, maxX - minX, maxY - minY);
    }
    
    rect = [self rectScaleWithRect:rect scale:1.0f];
    rect.origin.x = rect.origin.x * _contentView.frame.size.width;
    rect.origin.y = rect.origin.y * _contentView.frame.size.height;
    rect.size.width = rect.size.width * _contentView.frame.size.width;
    rect.size.height = rect.size.height * _contentView.frame.size.height;
    return rect;
}

- (CGRect)rectScaleWithRect:(CGRect)rect scale:(CGFloat)scale
{
    if (scale <= 0)
    {
        scale = 1.0f;
    }
    
    CGRect retRect = CGRectZero;
    retRect.origin.x = rect.origin.x/scale;
    retRect.origin.y = rect.origin.y/scale;
    retRect.size.width = rect.size.width/scale;
    retRect.size.height = rect.size.height/scale;
    return  retRect;
}

- (CGPoint)pointScaleWithPoint:(CGPoint)point scale:(CGFloat)scale
{
    if (scale <= 0)
    {
        scale = 1.0f;
    }
    
    CGPoint retPointt = CGPointZero;
    retPointt.x = point.x/scale;
    retPointt.y = point.y/scale;
    return  retPointt;
}

- (CGSize)sizeScaleWithScale:(CGFloat)scale
{
    CGSize size = CGSizeZero;
    if(_proportionValue == kPROPORTION1_1){
        size = CGSizeMake(kWIDTH, kWIDTH);
    }else if(_proportionValue == kPROPORTION4_3){
        size = CGSizeMake(kWIDTH, kWIDTH*3.0/4.0);
    }
    else if(_proportionValue == kPROPORTION3_4){
        size = CGSizeMake(kWIDTH*3.0/4.0, kWIDTH);
    }
    else if(_proportionValue == kPROPORTION16_9){
        size = CGSizeMake(kWIDTH, kWIDTH*9.0/16.0);
    }
    else if(_proportionValue == kPROPORTION9_16){
        size = CGSizeMake(kWIDTH*9.0/16.0, kWIDTH);
    }
//
    if (scale <= 0)
    {
        scale = 1.0f;
    }
    
    CGSize retSize = CGSizeZero;
    retSize.width = size.width/scale;
    retSize.height = size.height/scale;
    return  retSize;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
