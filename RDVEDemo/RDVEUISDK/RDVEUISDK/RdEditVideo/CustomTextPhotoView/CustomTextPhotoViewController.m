//
//  CustomTextPhotoViewController.m
//  RDVEUISDK
//
//  Created by emmet on 15/11/4.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import "CustomTextPhotoViewController.h"
#import "RDSectorProgressView.h"
#import "RDFileDownloader.h"
#import "RDATMHud.h"
#import "RDHelpClass.h"
#import "RDNavigationViewController.h"

#define kFONTSIZE 25
#define kFONTCOLORCOUNT 24
#define kCELLFONTCOLORCOUNT 6
#define kCOLORBTNWIDTH 28
#define kCAPTIONTEXTCOLORCHILDTAG 1000
#define kCAPTIONBACKCOLORCHILDTAG 2000
#define kCAPTIONTYPECHILDTAG 3000
//WEBP
#define kFontTitleImageViewTag   10000
@interface CustomTextPhotoViewController ()<UITextViewDelegate>
{
    bool               _editTextView;
    RDATMHud          *_hud;
    UIView          *videoRectBackView;
    UIImageView     *txtBackView;
    UITextView      *photoTextView;
    UILabel         *placeholderLbl;//20161107
    UIButton        *_cancelBtn;
    UIButton        *_saveBtn;
    UIButton        *_saveButton;
    UIImageView     *bottomView;
    UIView          *_selectToolItemBackView;
    UIButton        *_captionHiddenBottomBtn;
    UIButton        *_captionFontTypeBtn;
    UIButton        *_captionTextColorBtn;
    UIButton        *_captionBackColorBtn;
    UIButton        *_captionAlignmentLeftBtn;
    UIButton        *_captionAlignmentCenterBtn;
    UIButton        *_captionAlignmentRightBtn;
    UIImageView     *_backColorView;
    UIImageView     *_textColorView;
    UIScrollView    *_backColorScroll;
    UIScrollView    *_textColorScroll;
    UIScrollView    *_captionTypescroll;
    NSMutableArray      *_netFontList;
    NSDictionary        *_netFontIconList;
    NSMutableDictionary *_netFontListDic;
    NSIndexPath         *_lastIndexPath;
    UIView              *_selectTextView;
    UIImageView         *_selectBackView;
    
    UIButton            *_titlebackButton;
    UIButton            *_titlesaveButton;
    UIButton            *_title_toolbarItemBtn;
    NSString            *fontPath;
    CustomTextPhotoFile *customTextFile;
}
@property (nonatomic,assign) BOOL isChange;

@property (nonatomic,assign)NSInteger textColorIndex;

@property (nonatomic,assign)NSInteger backColorIndex;

@property (nonatomic,copy  )NSString  *textContent;

@property (nonatomic,copy  )NSString  *font_Name;

@property (nonatomic,assign)float      font_pointSize;

@property (nonatomic,assign)CGSize      photoRectSize;

@property (nonatomic,assign)ContentAlignment    contentAlignment;

@end

@implementation CustomTextPhotoViewController
- (instancetype)init{
    self = [super init];
    if(self){
#if isUseCustomLayer
        self.textColorIndex     = kCAPTIONTEXTCOLORCHILDTAG + kFONTCOLORCOUNT-1;
        _backColorIndex         = kCAPTIONBACKCOLORCHILDTAG;
#else
        self.textColorIndex     = kCAPTIONTEXTCOLORCHILDTAG;
        self.backColorIndex     = kCAPTIONBACKCOLORCHILDTAG + kFONTCOLORCOUNT-1;
#endif
        _isChange               = NO;
        self.font_Name          = nil;
        self.contentAlignment   = kContentAlignmentCenter;
    }
    return self;
}
- (instancetype)initWithFile:(CustomTextPhotoFile *)file{
    self = [super init];
    if(self){
        customTextFile = file;
        _isChange               = YES;
        self.textColorIndex     = file.textColorIndex;
        self.textContent        = file.textContent;
        self.backColorIndex     = file.backColorIndex;
        self.font_Name          = file.font_Name;
        fontPath = file.fontPath;
        self.font_pointSize     = file.font_pointSize;
        if(CGSizeEqualToSize(file.photoRectSize , CGSizeZero)){
            file.photoRectSize = CGSizeMake(640, 360);
        }
        self.photoRectSize      = file.photoRectSize;
      
        self.contentAlignment   = file.contentAlignment;
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBarHidden = YES;
    [photoTextView resignFirstResponder];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationItem setHidesBackButton:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:[UIColor colorWithWhite:0.0 alpha:0.5] cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    
    if(iPhone4s){
        _textColorScroll.contentOffset = CGPointMake(0, 10);
        _backColorScroll.contentOffset = CGPointMake(0, 10);
    }
    
    
    NSString *str = _textContent;
    
    float height = [RDHelpClass heightForString:str andWidth:photoTextView.frame.size.width fontSize:photoTextView.font.pointSize];
    if(height>photoTextView.frame.size.height-29){
        height = photoTextView.frame.size.height-29;
       
    }
    photoTextView.contentOffset = CGPointMake(0, (- photoTextView.frame.size.height+height)/2.0);
    [photoTextView setNeedsDisplay];
    
    photoTextView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    if (_textContent.length == 0) {
        placeholderLbl.hidden = NO;
    }else {
        placeholderLbl.hidden = YES;
    }
    [self setFontSize:_textContent];
    
    [photoTextView scrollRangeToVisible:photoTextView.selectedRange];

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
    
    self.title = RDLocalizedString(@"文字板", nil);
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:kFontFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kFontFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    _hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:_hud.view];
    
    [self initTextView];
    
    [self initBottomView];
    
    if(_font_Name){
        for (int k=0;k<_netFontList.count;k++) {
            NSString *font_url = [[_netFontList objectAtIndex:k] objectForKey:@"font"];
            NSString *title = [[_netFontList objectAtIndex:k] objectForKey:@"code"];
            if(([title isEqualToString:_font_Name] && [RDHelpClass hasCachedFont:title url:font_url])){
                [self setFont:k];
                break;
            }
        }
    }
    if(_isChange){
        if(_contentAlignment == kContentAlignmentLeft){
            [self touchesUp:_captionAlignmentLeftBtn];
        }
        else if(_contentAlignment == kContentAlignmentRight){
            [self touchesUp:_captionAlignmentRightBtn];
        }else{
            [self touchesUp:_captionAlignmentCenterBtn];
        }
    }
    
    [self touchesUp:_captionFontTypeBtn];
}

-(UIImage *)screenShot:(CGImageRef *)image{
    
    float screenScale =[UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kWIDTH *[UIScreen mainScreen].scale, kHEIGHT *[UIScreen mainScreen].scale), YES, 0);
    
    //设置截屏大小
    [[videoRectBackView layer] renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGImageRef imageRef = viewImage.CGImage;
    CGRect rect = CGRectMake(txtBackView.frame.origin.x * screenScale, txtBackView.frame.origin.y * screenScale, txtBackView.frame.size.width * screenScale, txtBackView.frame.size.height * screenScale);//这里可以设置想要截图的区域
    
    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *sendImage = [[UIImage alloc] initWithCGImage:imageRefRect];
    
    
    NSData *imageViewData = UIImagePNGRepresentation(sendImage);
    CGImageRelease(imageRefRect);
    UIImage *bgImage2 = [UIImage imageWithData:imageViewData];
    return bgImage2;
}

- (void)initTextView{
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelBtn.frame = CGRectMake(0, 0, 40, 40);
    _cancelBtn.backgroundColor = [UIColor clearColor];
    [_cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
    [_cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消点击_"] forState:UIControlStateHighlighted];
    [_cancelBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:_cancelBtn];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _saveBtn.frame = CGRectMake(0,0, 40, 40);
    _saveBtn.backgroundColor = [UIColor clearColor];
    [_saveBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成默认_"] forState:UIControlStateNormal];
    [_saveBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"] forState:UIControlStateHighlighted];
    [_saveBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:_saveBtn];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    if(iPhone4s){
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_saveButton setFrame:CGRectMake(0, 0, 64, 44)];
        [_saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
        [_saveButton setTitle:RDLocalizedString(@"停止输入", nil) forState:UIControlStateNormal];
        _saveButton.titleLabel.font=[UIFont systemFontOfSize:14];
        _saveButton.titleEdgeInsets=UIEdgeInsetsMake(1, 2, 0, 0);
    }
    
    videoRectBackView = [[UIView alloc] initWithFrame:CGRectMake(0, iPhone_X ? 88 : (LASTIPHONE_5 ? 44 : 0), kWIDTH, kWIDTH)];
    videoRectBackView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:videoRectBackView];
    
    if(_isChange){
        _videoProportion = _photoRectSize.width / (float)_photoRectSize.height;
        if(isnan(_videoProportion)){
            _videoProportion = 16/9.0;
            _photoRectSize = CGSizeMake(640, 360);
        }
    }
    txtBackView = [[UIImageView alloc] init];
    if(_videoProportion<1){
        [txtBackView setFrame:CGRectMake((kWIDTH - (kWIDTH*(float)_videoProportion))/2.0, 0, kWIDTH * (float)_videoProportion, kWIDTH)];
    }else{
        [txtBackView setFrame:CGRectMake(0, (kWIDTH - (kWIDTH / (float)_videoProportion))/2.0, kWIDTH, kWIDTH / (float)_videoProportion)];
    }
    txtBackView.backgroundColor = UIColorFromRGB(0xffffff);
    txtBackView.userInteractionEnabled = YES;
    [videoRectBackView addSubview:txtBackView];
    
    placeholderLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, txtBackView.frame.size.width, txtBackView.frame.size.height)];
    placeholderLbl.backgroundColor = [UIColor clearColor];
    placeholderLbl.enabled = NO;
    placeholderLbl.text = RDLocalizedString(@"点击输入文字...", nil);
    placeholderLbl.textAlignment = NSTextAlignmentCenter;
    placeholderLbl.font =  [UIFont systemFontOfSize:25];
    placeholderLbl.textColor = [UIColor lightGrayColor];
    if (_textContent.length>0) {
        placeholderLbl.hidden = YES;
    }
    [txtBackView addSubview:placeholderLbl];
    
    photoTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, txtBackView.frame.size.width, txtBackView.frame.size.height)];
    photoTextView.backgroundColor = [UIColor clearColor];
    photoTextView.textAlignment = NSTextAlignmentCenter;
    photoTextView.font = [UIFont systemFontOfSize:25];
    photoTextView.delegate = self;
    photoTextView.contentMode = UIViewContentModeCenter;
    [txtBackView addSubview:photoTextView];
    photoTextView.bounces = NO;
    photoTextView.keyboardAppearance =  UIKeyboardAppearanceAlert;
    photoTextView.pagingEnabled = NO;
    photoTextView.scrollEnabled = NO;
    photoTextView.contentSize = photoTextView.frame.size;
    if(_textContent){
        photoTextView.text = self.textContent;
    }
    float height = [RDHelpClass heightForString:photoTextView.text andWidth:photoTextView.frame.size.width fontSize:photoTextView.font.pointSize];
    photoTextView.contentOffset = CGPointMake(0, (- photoTextView.frame.size.height+height)/2.0 + 45);
    photoTextView.textContainerInset = UIEdgeInsetsMake(photoTextView.frame.size.height/2 - 5, 0, 0, 0);
}

- (void)save{
    
    [self touchesUp:_captionFontTypeBtn];
}

- (void)initBottomView{
    if(bottomView.superview){
        [bottomView removeFromSuperview];
    }
    bottomView = [[UIImageView alloc] initWithFrame:CGRectMake(0, videoRectBackView.frame.origin.y + videoRectBackView.frame.size.height, kWIDTH, kHEIGHT - (videoRectBackView.frame.origin.y + videoRectBackView.frame.size.height))];
    bottomView.backgroundColor = UIColorFromRGB(0x27262c);
    bottomView.userInteractionEnabled = YES;

    [self.view addSubview:bottomView];
    
    UIView *toolView = [[UIView alloc] init];
    
    toolView.frame = CGRectMake(0, 0, bottomView.frame.size.width, 50);
    
    toolView.backgroundColor = UIColorFromRGB(0x3c3b43);
   
    _captionFontTypeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _captionFontTypeBtn.backgroundColor = [UIColor clearColor];
    _captionFontTypeBtn.frame = CGRectMake(10, (toolView.frame.size.height - 25)/2.0, 50, 25);
    [_captionFontTypeBtn setTitle:RDLocalizedString(@"字体", nil) forState:UIControlStateNormal];
    [_captionFontTypeBtn setTitle:RDLocalizedString(@"字体", nil) forState:UIControlStateSelected];
    [_captionFontTypeBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [_captionFontTypeBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    _captionFontTypeBtn.tag =1;
    _captionFontTypeBtn.selected = YES;
    
    UIView *span1 = [[UIView alloc] init];
    span1.frame = CGRectMake(_captionFontTypeBtn.frame.origin.x + _captionFontTypeBtn.frame.size.width + 9.25, (toolView.frame.size.height - 20)/2.0, 0.5, 20);
    span1.backgroundColor = UIColorFromRGB(0x888888);
    if(_captionTextColorBtn.superview){
        [_captionTextColorBtn removeFromSuperview];
    }
    _captionTextColorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _captionTextColorBtn.backgroundColor = [UIColor clearColor];
    _captionTextColorBtn.frame = CGRectMake(_captionFontTypeBtn.frame.origin.x + _captionFontTypeBtn.frame.size.width + 20,(toolView.frame.size.height - 25)/2.0,50, 25);
    [_captionTextColorBtn setTitle:RDLocalizedString(@"颜色", nil) forState:UIControlStateNormal];
    [_captionTextColorBtn setTitle:RDLocalizedString(@"颜色", nil) forState:UIControlStateSelected];
    [_captionTextColorBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [_captionTextColorBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *span2 = [[UIView alloc] init];
    span2.frame = CGRectMake(_captionTextColorBtn.frame.origin.x + _captionTextColorBtn.frame.size.width + 9.25, (toolView.frame.size.height - 20)/2.0, 0.5, 20);
    span2.backgroundColor = UIColorFromRGB(0x888888);
    
    if(_captionBackColorBtn.superview){
        [_captionBackColorBtn removeFromSuperview];
    }
    _captionBackColorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _captionBackColorBtn.backgroundColor = [UIColor clearColor];
    _captionBackColorBtn.frame = CGRectMake(_captionTextColorBtn.frame.origin.x + _captionTextColorBtn.frame.size.width + 20, (toolView.frame.size.height - 25)/2.0, 50, 25);
    [_captionBackColorBtn setTitle:RDLocalizedString(@"背景", nil) forState:UIControlStateNormal];
    [_captionBackColorBtn setTitle:RDLocalizedString(@"背景", nil) forState:UIControlStateSelected];
    [_captionBackColorBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [_captionBackColorBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    
    if(_selectToolItemBackView.superview){
        [_selectToolItemBackView removeFromSuperview];
    }
    _selectToolItemBackView = [[UIView alloc] initWithFrame:CGRectMake(_captionFontTypeBtn.frame.origin.x, (toolView.frame.size.height - 2), _captionFontTypeBtn.frame.size.width, 2)];
    _selectToolItemBackView.backgroundColor = Main_Color;

    [_captionFontTypeBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    [_captionTextColorBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    [_captionBackColorBtn setTitleColor:Main_Color forState:UIControlStateSelected];
   
    _captionAlignmentRightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _captionAlignmentRightBtn.backgroundColor = [UIColor clearColor];
    _captionAlignmentRightBtn.frame = CGRectMake(toolView.frame.size.width - 45, (toolView.frame.size.height - 40)/2.0, 40, 40);
    [_captionAlignmentRightBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_右对齐默认_"] forState:UIControlStateNormal];
    [_captionAlignmentRightBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_右对齐点击_"] forState:UIControlStateHighlighted];
    [_captionAlignmentRightBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_右对齐选中_"] forState:UIControlStateSelected];
    [_captionAlignmentRightBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    
    _captionAlignmentCenterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _captionAlignmentCenterBtn.backgroundColor = [UIColor clearColor];
    _captionAlignmentCenterBtn.frame = CGRectMake(_captionAlignmentRightBtn.frame.origin.x - 45, (toolView.frame.size.height - 40)/2.0, 40, 40);
    [_captionAlignmentCenterBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_中对齐默认_"] forState:UIControlStateNormal];
    [_captionAlignmentCenterBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_中对齐点击_"] forState:UIControlStateHighlighted];
    [_captionAlignmentCenterBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_中对齐选中_"] forState:UIControlStateSelected];
    [_captionAlignmentCenterBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    _captionAlignmentCenterBtn.selected = YES;
    
    
    _captionAlignmentLeftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _captionAlignmentLeftBtn.backgroundColor = [UIColor clearColor];
    _captionAlignmentLeftBtn.frame = CGRectMake(_captionAlignmentCenterBtn.frame.origin.x - 45, (toolView.frame.size.height - 40)/2.0, 40, 40);
    [_captionAlignmentLeftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_左对齐默认_"] forState:UIControlStateNormal];
    [_captionAlignmentLeftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_左对齐点击_"] forState:UIControlStateHighlighted];
    [_captionAlignmentLeftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/wenziban/文字板_左对齐选中_"] forState:UIControlStateSelected];
    [_captionAlignmentLeftBtn addTarget:self action:@selector(touchesUp:) forControlEvents:UIControlEventTouchUpInside];
    
    [toolView addSubview:_selectToolItemBackView];
    [toolView addSubview:span1];
    [toolView addSubview:_captionFontTypeBtn];
    [toolView addSubview:span2];
    [toolView addSubview:_captionTextColorBtn];
    [toolView addSubview:_captionBackColorBtn];
    
    [toolView addSubview:_captionAlignmentRightBtn];
    [toolView addSubview:_captionAlignmentCenterBtn];
    [toolView addSubview:_captionAlignmentLeftBtn];
    
    [bottomView addSubview:toolView];
    if(_captionTypescroll.superview){
        [_captionTypescroll removeFromSuperview];
    }
    _captionTypescroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, toolView.frame.size.height, bottomView.frame.size.width, bottomView.frame.size.height - toolView.frame.size.height)];
    _captionTypescroll.backgroundColor = [UIColor clearColor];
    _captionTypescroll.userInteractionEnabled = YES;
    _captionTypescroll.hidden = NO;
    _captionTypescroll.delegate = self;
    NSInteger cellcaptionTypeCount =  1;
    
    if(_backColorView.superview){
        [_backColorView removeFromSuperview];
    }
    _backColorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, toolView.frame.size.height, bottomView.frame.size.width, bottomView.frame.size.height - toolView.frame.size.height)];
    _backColorView.backgroundColor = [UIColor clearColor];
    _backColorView.userInteractionEnabled = YES;
    _backColorView.hidden = YES;
    
    if(_textColorView.superview){
        [_textColorView removeFromSuperview];
    }
    _textColorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, toolView.frame.size.height, bottomView.frame.size.width, bottomView.frame.size.height - toolView.frame.size.height)];
    _textColorView.backgroundColor = [UIColor clearColor];
    _textColorView.userInteractionEnabled = YES;
    _textColorView.hidden = YES;
    
    if(_backColorScroll.superview){
        [_backColorScroll removeFromSuperview];
    }
    _backColorScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 10, _backColorView.frame.size.width, _backColorView.frame.size.height-10)];
    _backColorScroll.backgroundColor = [UIColor clearColor];
    
    if(_textColorScroll.superview){
        [_textColorScroll removeFromSuperview];
    }
    _textColorScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 10, _textColorView.frame.size.width, _textColorView.frame.size.height-10)];
    _textColorScroll.backgroundColor = [UIColor clearColor];
    int cellCount_1 = 6;//((_textColorScroll.frame.size.width-10)/40);
    _textColorScroll.contentSize = CGSizeMake(_textColorScroll.frame.size.width, cellCount_1 * (kCOLORBTNWIDTH +10));
    
    [bottomView addSubview:_textColorView];
    [bottomView addSubview:_backColorView];
    [bottomView addSubview:_captionTypescroll];
    [_textColorView addSubview:_textColorScroll];
    [_backColorView addSubview:_backColorScroll];
    
    _netFontList = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
    RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
    BOOL hasNew = nav.editConfiguration.fontResourceURL.length>0;
    __block BOOL create = NO;
    if(!hasNew){
        _netFontIconList = [NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath];
        
        if(_netFontList && _netFontIconList){
            [self initFontTypeViewChild:cellcaptionTypeCount];
            create = YES;
        }
    }else{
        [self initFontTypeViewChild:cellcaptionTypeCount];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableDictionary *params  = [[NSMutableDictionary alloc] init];
        
        NSString *fontUrl = @"";
        if(hasNew){
            fontUrl = nav.editConfiguration.fontResourceURL;
            _netFontListDic = [RDHelpClass getNetworkMaterialWithType:kFontType
                                                               appkey:nav.appKey
                                                              urlPath:fontUrl];
        }else{
            [params setObject:@"1" forKey:@"os"];
            fontUrl = getFontTypeUrl;
            _netFontListDic = [RDHelpClass updateInfomation:params andUploadUrl:fontUrl];
        }
        NSMutableDictionary *fontdic=[[NSMutableDictionary alloc] initWithCapacity:1];
        
        [fontdic setObject:@"默认字体" forKey:@"title"];
        [fontdic setObject:@"morenziti" forKey:@"code"];
        [fontdic setObject:@"" forKey:@"icon"];
        [fontdic setObject:@"" forKey:@"font"];
        
        BOOL resultInteger = hasNew ? [_netFontListDic[@"code"] intValue] == 0 : [_netFontListDic[@"code"] intValue] == 200;
        if (!resultInteger){
            _netFontListDic=nil;
            if (!_netFontList) {//20161108 bug4320
                _netFontList=[[NSMutableArray alloc] initWithObjects:fontdic, nil];
            }
        }else{
            if([_netFontListDic[@"data"] isKindOfClass:[NSMutableArray class]]){
                _netFontList=[_netFontListDic[@"data"] mutableCopy];
                [_netFontList insertObject:fontdic atIndex:0];
                
                BOOL suc = [_netFontList writeToFile:kFontPlistPath atomically:YES];
                if(!suc){
                    NSLog(@"写文件失败");
                }
                if (!hasNew && (!_netFontIconList || (_netFontIconList && [[[_netFontListDic objectForKey:@"icon"] objectForKey:@"timeunix"] longValue] > [[_netFontIconList objectForKey:@"timeunix"] longValue]))) {
                    NSFileManager *manager = [[NSFileManager alloc] init];
                    NSError *error;
                    NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[_netFontIconList objectForKey:@"name"]];
                    if([manager fileExistsAtPath:path]){
                        [manager removeItemAtPath:path error:&error];
                    }
                    create = NO;
                    _netFontIconList = [_netFontListDic objectForKey:@"icon"];
                    suc = [_netFontIconList writeToFile:kFontIconPlistPath atomically:YES];
                    if(!suc){
                        NSLog(@"写文件失败");
                    }
                    if (!create) {                        
                        [self DownloadThumbnailFile:[_netFontIconList objectForKey:@"caption"] andUnzipToPath:@"SubtitleEffect/Font" andCellcaptionTypeCount:cellcaptionTypeCount];
                    }
                }else if(hasNew && !create){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initFontTypeViewChild:cellcaptionTypeCount];
                    });
                }
            }
        }
    });
   
    UIView *cornerRadius1 = [[UIView alloc] initWithFrame:CGRectMake(4, 4, kCOLORBTNWIDTH+2, kCOLORBTNWIDTH+2)];
    cornerRadius1.backgroundColor = UIColorFromRGB(0x33333b);
    cornerRadius1.layer.cornerRadius = 3.0;
    cornerRadius1.layer.masksToBounds = YES;
    
    _selectBackView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kCOLORBTNWIDTH+10, kCOLORBTNWIDTH+10)];
    _selectBackView.backgroundColor = [UIColor clearColor];
    _selectBackView.layer.cornerRadius = 3.0;
    _selectTextView.layer.masksToBounds = YES;
    [_selectBackView addSubview:cornerRadius1];
    [_backColorScroll addSubview:_selectBackView];
    
    int cellCount =  6;
    int indexColorCount = 0;
    float contentSizeHeight = 0;
    float height =  ((_backColorScroll.frame.size.height - (kCOLORBTNWIDTH*4))/5);
    //选择图片背景
#if isUseCustomLayer
    height =  ((_backColorScroll.frame.size.height - (kCOLORBTNWIDTH*4.5))/5);
#endif
    for (int j=0;j<kFONTCOLORCOUNT;j++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [self returnColor:j];
        btn.tag = kCAPTIONBACKCOLORCHILDTAG+j;
        indexColorCount = j%cellCount;
        int cellIndex = j/cellCount;
        [btn addTarget:self action:@selector(touchescaptionBackColorViewChild:) forControlEvents:UIControlEventTouchUpInside];
        
        if(cellIndex%2==0){
            if(_backColorScroll.frame.size.height>210){
                btn.frame = CGRectMake(indexColorCount * kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH + height)*cellIndex+height, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }else {
                btn.frame = CGRectMake(indexColorCount * kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH+20)*cellIndex+20, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }
        }else{
            if(_backColorScroll.frame.size.height>210){
                btn.frame = CGRectMake((kCOLORBTNWIDTH/2) + indexColorCount*kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH + height)*cellIndex + height, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }else {
               btn.frame = CGRectMake((kCOLORBTNWIDTH/2) + indexColorCount*kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH+20)*cellIndex+20, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }
        }
        if(j==0){
            _selectBackView.backgroundColor = btn.backgroundColor;
            _selectBackView.center = btn.center;
        }
        btn.layer.cornerRadius = 3.0;
        btn.layer.masksToBounds = YES;
        [_backColorScroll addSubview:btn];
        if (j == kFONTCOLORCOUNT - 1) {
            contentSizeHeight = btn.frame.origin.y + height;
        }
    }
#if isUseCustomLayer
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *folderPath = [bundle pathForResource:@"bgImages" ofType:@""];
    NSArray *bgImageArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    for (int i = 0; i < bgImageArray.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = kCAPTIONBACKCOLORCHILDTAG+i + kFONTCOLORCOUNT;
        indexColorCount = (i + kFONTCOLORCOUNT) %cellCount;
        int cellIndex = (i + kFONTCOLORCOUNT) /cellCount;
        [btn setImage:[UIImage imageWithContentsOfFile:[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"bg_%d.jpg", (i + 1)]]] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(touchescaptionBackColorViewChild:) forControlEvents:UIControlEventTouchUpInside];
        
        if(cellIndex%2==0){
            if(_backColorScroll.frame.size.height>210){
                btn.frame = CGRectMake(indexColorCount * kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH + height)*cellIndex+height, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }else {
                 btn.frame = CGRectMake(indexColorCount * kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH+20)*cellIndex+20, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }
        }else{
            if(_backColorScroll.frame.size.height>210){
                btn.frame = CGRectMake((kCOLORBTNWIDTH/2) + indexColorCount*kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH + height)*cellIndex + height, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }else {
               btn.frame = CGRectMake((kCOLORBTNWIDTH/2) + indexColorCount*kCOLORBTNWIDTH+((_backColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount)/(cellCount+1)*(indexColorCount+1)), (kCOLORBTNWIDTH+20)*cellIndex+20, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }
        }
        btn.layer.cornerRadius = 3.0;
        btn.layer.masksToBounds = YES;
        [_backColorScroll addSubview:btn];
        if (i == bgImageArray.count - 1) {
            if (height > 0) {
                contentSizeHeight = btn.frame.origin.y + height;
            }else {
                contentSizeHeight = btn.frame.origin.y + kCOLORBTNWIDTH + 20;
            }
        }
    };
#endif
    _backColorScroll.contentSize = CGSizeMake(0, contentSizeHeight);
    UIView *cornerRadius2 = [[UIView alloc] initWithFrame:CGRectMake(4, 4, kCOLORBTNWIDTH+2, kCOLORBTNWIDTH+2)];
    cornerRadius2.backgroundColor = UIColorFromRGB(0x33333b);
    cornerRadius2.layer.cornerRadius = 3.0;
    cornerRadius2.layer.masksToBounds = YES;
    
    _selectTextView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCOLORBTNWIDTH+10, kCOLORBTNWIDTH+10)];
    _selectTextView.backgroundColor = [UIColor clearColor];
    _selectTextView.layer.cornerRadius = 3.0;
    _selectTextView.layer.masksToBounds = YES;
    [_selectTextView addSubview:cornerRadius2];
    
    [_textColorScroll addSubview:_selectTextView];
    int indexColorCount_1 = 0;
    //选择字体颜色
    for (int j=0;j<kFONTCOLORCOUNT;j++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [self returnColor:j];
        btn.tag = kCAPTIONTEXTCOLORCHILDTAG+j;
        indexColorCount_1 = j%cellCount_1;
        int cellIndex_1 = j/cellCount_1;
        [btn addTarget:self action:@selector(touchescaptionTextColorViewChild:) forControlEvents:UIControlEventTouchUpInside];
        if(cellIndex_1%2==0){
            if(_textColorScroll.frame.size.height>210){
                btn.frame = CGRectMake(indexColorCount_1 * kCOLORBTNWIDTH+((_textColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount_1)/(cellCount_1+1)*(indexColorCount_1+1)), (kCOLORBTNWIDTH + height)*(j/cellCount_1) + height, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }else {
                btn.frame = CGRectMake(indexColorCount_1 * kCOLORBTNWIDTH+((_textColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount_1)/(cellCount_1+1)*(indexColorCount_1+1)), (kCOLORBTNWIDTH+20)*(j/cellCount_1)+20, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }
        }else{
            if(_textColorScroll.frame.size.height>210){
                btn.frame = CGRectMake((kCOLORBTNWIDTH/2) + indexColorCount_1*kCOLORBTNWIDTH+((_textColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount_1)/(cellCount_1+1)*(indexColorCount_1+1)), (kCOLORBTNWIDTH + height)*(j/cellCount_1) + height, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }else {
               btn.frame = CGRectMake((kCOLORBTNWIDTH/2) + indexColorCount_1*kCOLORBTNWIDTH+((_textColorScroll.frame.size.width - (kCOLORBTNWIDTH/2) - kCOLORBTNWIDTH*cellCount_1)/(cellCount_1+1)*(indexColorCount_1+1)), (kCOLORBTNWIDTH+20)*(j/cellCount_1)+20, kCOLORBTNWIDTH, kCOLORBTNWIDTH);
            }
        }
        if(j==0){
            _selectTextView.backgroundColor = btn.backgroundColor;
            _selectTextView.center = btn.center;
        }
        btn.layer.cornerRadius = 3.0;
        btn.layer.masksToBounds = YES;
        [_textColorScroll addSubview:btn];
    }
    
    if (self.textContent.length>0){
        photoTextView.text = self.textContent;
        UIButton *sender_1 = (UIButton *)[_backColorScroll viewWithTag:self.backColorIndex];
        UIButton *sender_2 = (UIButton *)[_textColorScroll viewWithTag:self.textColorIndex];
        [self touchescaptionBackColorViewChild:sender_1];
        [self touchescaptionTextColorViewChild:sender_2];
        [self setFontSize:self.textContent];
    }else{
        UIButton *sender_1 = (UIButton *)[_backColorScroll viewWithTag:self.backColorIndex];
        UIButton *sender_2 = (UIButton *)[_textColorScroll viewWithTag:self.textColorIndex];
        [self touchescaptionBackColorViewChild:sender_1];
        [self touchescaptionTextColorViewChild:sender_2];
    }
}

- (void)initFontTypeViewChild:(NSInteger)cellcaptionTypeCount{
    NSFileManager *manager = [NSFileManager defaultManager];    
    [_captionTypescroll.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    BOOL suc = NO;
    for (int k = 0; k<_netFontList.count; k++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn addTarget:self action:@selector(touchesFontListViewChild:) forControlEvents:UIControlEventTouchUpInside];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = CGRectMake(0, k* 50 + 5, _captionTypescroll.frame.size.width, 50);
        btn.layer.cornerRadius = 0.0;
        btn.layer.masksToBounds = YES;
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 106,btn.frame.size.height)];
        imageV.backgroundColor = [UIColor clearColor];
        imageV.contentMode = UIViewContentModeScaleAspectFit;
            imageV.frame = CGRectMake(10, 0, 145, btn.frame.size.height);
            imageV.backgroundColor = [UIColor clearColor];
        BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length>0 ? YES : NO;
        NSString *fileName = hasNew ? [[[[_netFontList objectAtIndex:k] objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension] : [[_netFontList objectAtIndex:k] objectForKey:@"name"];
        NSString *path = kFontIconPath;
        if(hasNew){
            [imageV rd_sd_setImageWithURL:[NSURL URLWithString:[_netFontList objectAtIndex:k][@"cover"]]];
        }else{
            NSString *imagePath;
            imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@3x.png",fileName]];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            if (image) {
                imageV.image = image;
            }else{
                imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@2x.png",fileName]];
                image = [UIImage imageWithContentsOfFile:imagePath];
                if (image) {
                    imageV.image = image;
                }
            }
        }
        imageV.tag = kFontTitleImageViewTag;
        imageV.layer.masksToBounds = YES;
            
        if(k==0){
            NSString *title = [[_netFontList objectAtIndex:k] objectForKey:@"title"];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, 145, btn.frame.size.height)];
            label.text = title;
            label.tag = 3;
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = Main_Color;
            label.font = [UIFont systemFontOfSize:16.0];
            [btn addSubview:label];
        }else{
            
            NSString *timeunix = [NSString stringWithFormat:@"%ld",[(hasNew ? _netFontList[k][@"updatetime"] : _netFontList[k][@"timeunix"]) integerValue]];
            
            _netFontList = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
            
            NSMutableDictionary *configDic = [[NSMutableDictionary alloc] initWithContentsOfFile:kFontCheckPlistPath];
            BOOL check = [timeunix isEqualToString:[configDic objectForKey:fileName]] ? YES : NO;
            
            NSString *path = [RDHelpClass pathForURL_font_WEBP:fileName extStr:@"ttf" isNetMaterial:(((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length > 0)];
            if(![manager fileExistsAtPath:path] || !check){
                NSError *error;
                if([manager fileExistsAtPath:path]){
                    [manager removeItemAtPath:path error:&error];
                    NSLog(@"error:%@",error);
                }
            }
            suc = [RDHelpClass hasCachedFont_WEBP:(hasNew ? [[[_netFontList[k][@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[_netFontList[k][@"file"] lastPathComponent]] : fileName) extStr:@"ttf" isNetMaterial:hasNew];
        }
        
        
        {
            UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
            UIImageView *markV = [[UIImageView alloc] initWithFrame:CGRectMake(btn.frame.size.width - 35, (btn.frame.size.height-accessory.size.height)/2, accessory.size.width, accessory.size.height)];
            markV.backgroundColor = [UIColor clearColor];
            imageV.layer.masksToBounds = YES;
            markV.tag = 4000;
            [markV setImage:accessory];
            [btn addSubview:markV];
            if(!suc && k != 0){
                markV.hidden = NO;
            }else{
                markV.hidden = YES;
            }
            if(k == 0){
                markV.hidden = YES;
            }
        }
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length>0){
            UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"];
            UIImageView *markV = [[UIImageView alloc] initWithFrame:CGRectMake(btn.frame.size.width - accessory.size.width, (btn.frame.size.height-accessory.size.height)/2, accessory.size.width, accessory.size.height)];
            markV.backgroundColor = [UIColor clearColor];
            markV.tag = 50000;
            [markV setImage:accessory];
            [btn addSubview:markV];
            markV.hidden = YES;
        }
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        btn.tag = k+kCAPTIONTYPECHILDTAG;
        UIView *span = [[UIView alloc] initWithFrame:CGRectMake(0, btn.frame.size.height-1, btn.frame.size.width, 1)];
        span.backgroundColor = UIColorFromRGB(NV_Color);
        [btn addSubview:imageV];
        [btn addSubview:span];
        
        [_captionTypescroll addSubview:btn];
    }
    
    int cellCounts = ceil(_netFontList.count/(float)cellcaptionTypeCount);
    
    _captionTypescroll.contentSize = CGSizeMake(_captionTypescroll.frame.size.width, (50 * cellCounts + 10));
}

- (void)touchesFontListViewChild:(UIButton *)sender{
    if (_captionHiddenBottomBtn.selected) {
        [self captionHiddenBottomBtn_touchUpInSide];
    }
    
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length > 0;
    NSDictionary *itemDic = [_netFontList objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG];
    NSString *title = [itemDic objectForKey:@"name"];
    UIImageView *image = (UIImageView *)[sender viewWithTag:4000];
    NSString *ff = [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[itemDic[@"file"] lastPathComponent]];
    BOOL suc = [RDHelpClass hasCachedFont_WEBP:(hasNew ? ff  : title) extStr:@"ttf" isNetMaterial:hasNew];
    
    NSInteger index = sender.tag - kCAPTIONTYPECHILDTAG;
    if(index == 0){
        [self setFont:index];
    }else if(!suc){
        NSString *url = hasNew ? [_netFontList objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG][@"file"] : [[_netFontList objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG] objectForKey:@"caption"];
        [self downloadfontType_font:url button:image index:index];
    }else{
        [self setFont:index];
    }
   
}

/*
 根据索引获取字幕颜色
 */
- (UIColor *)returnColor:(NSInteger)index{
    
    NSString *colorStr= @"";
    
    switch (index) {
        case 0:
            colorStr= @"000000";
            break;
        case 1:
            colorStr= @"e8ce6b";
            break;
        case 2:
            colorStr= @"f9b73c";
            break;
        case 3:
            colorStr= @"e3573b";
            break;
        case 4:
            colorStr= @"be213b";
            break;
        case 5:
            colorStr= @"00ffff";
            break;
        case 6:
            colorStr= @"5da9cf";
            break;
        case 7:
            colorStr= @"0695b5";
            break;
        case 8:
            colorStr= @"2791db";
            break;
        case 9:
            colorStr= @"3564b7";
            break;
        case 10:
            colorStr= @"e9c930";
            break;
        case 11:
            colorStr= @"a6b45c";
            break;
        case 12:
            colorStr= @"87a522";
            break;
        case 13:
            colorStr= @"32b16c";
            break;
        case 14:
            colorStr= @"017e54";
            break;
        case 15:
            colorStr= @"fdbacc";
            break;
        case 16:
            colorStr= @"ff5a85";
            break;
        case 17:
            colorStr= @"ca4f9b";
            break;
        case 18:
            colorStr= @"71369a";
            break;
        case 19:
            colorStr= @"6720d4";
            break;
        case 20:
            colorStr= @"164c6e";
            break;
        case 21:
            colorStr= @"9f9f9f";
            break;
        case 22:
            colorStr= @"484848";
            break;
        case 23:
            colorStr= @"ffffff";
            break;
        default:
            break;
    }
    return [self colorWithHexString:colorStr];
}
-(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}

//点击按钮的方法
- (void)touchesUp:(UIButton *)sender{
    if(sender == _captionAlignmentLeftBtn){
        photoTextView.textAlignment = NSTextAlignmentLeft;
        _captionAlignmentLeftBtn.selected = YES;
        _captionAlignmentRightBtn.selected = NO;
        _captionAlignmentCenterBtn.selected = NO;
        _contentAlignment = kContentAlignmentLeft;
    }
    else if(sender == _captionAlignmentCenterBtn){
        photoTextView.textAlignment = NSTextAlignmentCenter;
        _captionAlignmentLeftBtn.selected = NO;
        _captionAlignmentRightBtn.selected = NO;
        _captionAlignmentCenterBtn.selected = YES;
        _contentAlignment = kContentAlignmentCenter;
    }
    else if(sender == _captionAlignmentRightBtn){
        photoTextView.textAlignment = NSTextAlignmentRight;
        _captionAlignmentLeftBtn.selected = NO;
        _captionAlignmentRightBtn.selected = YES;
        _captionAlignmentCenterBtn.selected = NO;
        _contentAlignment = kContentAlignmentRight;
    }
    else if(sender == _saveBtn){
        if(photoTextView.text.length==0){
            placeholderLbl.hidden = NO;
            [_hud setCaption:RDLocalizedString(@"没有输入文字哟!", nil)];//20161108 bug4320
            [_hud show];
            [_hud hideAfter:2];
            return;
        }
        [photoTextView resignFirstResponder];
        if(_delegate){
            if([_delegate respondsToSelector:@selector(getCustomTextImagePath:thumbImage:customTextPhotoFile: touchUpType:change:)]){
                
                bottomView.hidden = YES;
                self.navigationController.navigationBar.translucent = NO;
                
                UIImage * thumbImage     = [self screenShot:nil];
                if (!_isChange) {
                    customTextFile = [[CustomTextPhotoFile alloc] init];
                }
                customTextFile.textContent        = photoTextView.text;
                customTextFile.textColorIndex     = self.textColorIndex;
                customTextFile.backColorIndex     = self.backColorIndex;
                customTextFile.font_Name          = self.font_Name;
                customTextFile.fontPath           = fontPath;
                customTextFile.font_pointSize     = photoTextView.font.pointSize;
                customTextFile.contentAlignment   = _contentAlignment;
                customTextFile.photoRectSize      = txtBackView.frame.size;
                customTextFile.textColor          = photoTextView.textColor;
                if (_isChange) {
                    [customTextFile refreshTextLayer];
                }else {
                    [customTextFile textLayer];
                }
#if isUseCustomLayer
                NSInteger index = _backColorIndex - kCAPTIONBACKCOLORCHILDTAG + 1;
                NSString *bgImagePath;
                if (index > kFONTCOLORCOUNT) {
                    bgImagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"bgImages/bg_%ld", index - kFONTCOLORCOUNT] Type:@"jpg"];
                }else {
                    if (![[NSFileManager defaultManager] fileExistsAtPath:kTextboardFolder]) {
                        [[NSFileManager defaultManager] createDirectoryAtPath:kTextboardFolder withIntermediateDirectories:YES attributes:nil error:nil];
                    }
                    bgImagePath = [kTextboardFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"textboard%ld.jpg", (long)index]];
                    if(![[NSFileManager defaultManager] fileExistsAtPath:bgImagePath])
                    {
                        UIImage *image = [RDHelpClass rdImageWithColor:txtBackView.backgroundColor size:CGSizeMake(50, 50) cornerRadius:0];
                        NSData* imagedata = UIImageJPEGRepresentation(image, 1.0);
                        [[NSFileManager defaultManager] createFileAtPath:bgImagePath contents:imagedata attributes:nil];
                        imagedata = nil;
                    }
                }
                [_delegate getCustomTextImagePath:bgImagePath thumbImage:thumbImage customTextPhotoFile:customTextFile touchUpType:_touchUpType change:_isChange];
#else
                [_delegate getCustomTextImagePath:nil thumbImage:thumbImage customTextPhotoFile:customTextFile touchUpType:_touchUpType change:_isChange];
#endif
            }
        }
        UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
        if(!upView){
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
    }else if(sender == _captionBackColorBtn){
        if (_captionHiddenBottomBtn.selected) {
            [self captionHiddenBottomBtn_touchUpInSide];
        }
        [photoTextView resignFirstResponder];
        _selectToolItemBackView.frame = CGRectMake(sender.frame.origin.x, _selectToolItemBackView.frame.origin.y, _selectToolItemBackView.frame.size.width, _selectToolItemBackView.frame.size.height);
        
        _backColorView.hidden = NO;
        _textColorView.hidden = YES;
        _captionTypescroll.hidden = YES;
        _captionBackColorBtn.selected = YES;
        _captionTextColorBtn.selected = NO;
        _captionFontTypeBtn.selected = NO;
        
    }else if(sender == _captionTextColorBtn){
        if (_captionHiddenBottomBtn.selected) {
            [self captionHiddenBottomBtn_touchUpInSide];
        }
        [photoTextView resignFirstResponder];
        _selectToolItemBackView.frame = CGRectMake(sender.frame.origin.x, _selectToolItemBackView.frame.origin.y, _selectToolItemBackView.frame.size.width, _selectToolItemBackView.frame.size.height);
        
        _backColorView.hidden = YES;
        _textColorView.hidden = NO;
        _captionTypescroll.hidden = YES;
        _captionBackColorBtn.selected = NO;
        _captionTextColorBtn.selected = YES;
        _captionFontTypeBtn.selected = NO;
        
    }else if(sender == _captionFontTypeBtn){
        if (_captionHiddenBottomBtn.selected) {
            [self captionHiddenBottomBtn_touchUpInSide];
        }
        [photoTextView resignFirstResponder];
        _selectToolItemBackView.frame = CGRectMake(sender.frame.origin.x, _selectToolItemBackView.frame.origin.y, _selectToolItemBackView.frame.size.width, _selectToolItemBackView.frame.size.height);
        
        _backColorView.hidden = YES;
        _textColorView.hidden = YES;
        _captionTypescroll.hidden = NO;
        _captionBackColorBtn.selected = NO;
        _captionTextColorBtn.selected = NO;
        _captionFontTypeBtn.selected = YES;
        
    }else{
        [photoTextView resignFirstResponder];
        UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
        if(!upView){
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)captionHiddenBottomBtn_touchUpInSide{
    _captionHiddenBottomBtn.selected = !_captionHiddenBottomBtn.selected;
    if(_captionHiddenBottomBtn.selected){
        [_captionHiddenBottomBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/字幕_展开默认_"] forState:UIControlStateNormal];
        [_captionHiddenBottomBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/字幕_展开点击_"] forState:UIControlStateSelected];
        bottomView.frame = CGRectMake(0, kHEIGHT - 60, bottomView.frame.size.width, bottomView.frame.size.height);
    }else{
        [_captionHiddenBottomBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/字幕_收起默认_"] forState:UIControlStateNormal];
        [_captionHiddenBottomBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/字幕_收起点击_"] forState:UIControlStateSelected];
        bottomView.frame = CGRectMake(0, videoRectBackView.frame.origin.y + videoRectBackView.frame.size.height, bottomView.frame.size.width, bottomView.frame.size.height);
    }
}

- (void)touchescaptionBackColorViewChild:(UIButton *)sender{
    if (_captionHiddenBottomBtn.selected) {
        [self captionHiddenBottomBtn_touchUpInSide];
    }
    if(sender){
        if (sender.imageView.image) {
            txtBackView.image = sender.imageView.image;
            _selectBackView.image = sender.imageView.image;
        }else {
            txtBackView.backgroundColor = sender.backgroundColor;
            _selectBackView.backgroundColor = sender.backgroundColor;
            txtBackView.image = nil;
            _selectBackView.image = nil;
        }
        self.backColorIndex = sender.tag;
        _selectBackView.center = sender.center;
    }
}

- (void)touchescaptionTextColorViewChild:(UIButton *)sender{
    if (_captionHiddenBottomBtn.selected) {
        [self captionHiddenBottomBtn_touchUpInSide];
    }
    if(sender){
        photoTextView.textColor = sender.backgroundColor;
        self.textColorIndex = sender.tag;
        _selectTextView.center = sender.center;
        _selectTextView.backgroundColor = sender.backgroundColor;
        [photoTextView setTintColor:sender.backgroundColor];
    }
}

#pragma mark -  下载字体
- (void)downloadfontType_font:(NSString *)url
                       button:(UIImageView *)sender
                        index:(NSUInteger)index
{
    __weak CustomTextPhotoViewController *weakSelf = self;
    UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
    CGRect rect = CGRectMake((sender.frame.size.width - accessory.size.width)/2, (sender.frame.size.height - accessory.size.height)/2, accessory.size.width, accessory.size.height);
    RDSectorProgressView *ddprogress = [[RDSectorProgressView alloc] initWithFrame:rect];
    ddprogress.progressColor = [UIColor greenColor];
    ddprogress.circleBackgroundColor = [UIColor greenColor];
    [sender addSubview:ddprogress];
   
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length > 0;
    NSString *path = @"";
    if(hasNew){
        path = [RDHelpClass pathForURL_font_WEBP_down:([[[[_netFontList objectAtIndex:index][@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[[[[_netFontList objectAtIndex:index] objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension]]) extStr:@"zip"];
    }else{
        path = [RDHelpClass pathForURL_font_WEBP_down:[[_netFontList objectAtIndex:index] objectForKey:@"name"] extStr:@"zipp"];
    }
    
    NSString *url_str=[NSString stringWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    
#if 1
    NSString *cacheFolderPath = [path stringByDeletingLastPathComponent];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:cacheFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    [RDFileDownloader downloadFileWithURL:url_str cachePath:cacheFolderPath httpMethod:GET progress:^(NSNumber *numProgress) {
        [ddprogress setProgress:[numProgress floatValue]];
    } finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSString *cacheFolderPath = [[self pathFontForURL:[NSURL URLWithString:url]] stringByDeletingLastPathComponent];
            [weakSelf OpenZip:fileCachePath unzipto:cacheFolderPath caption:NO];
            
            NSString *openZippath = @"";
            __block NSString *fileTimeKey;
            __block NSString *fileName = [[_netFontList objectAtIndex:index] objectForKey:@"name"];
            if(hasNew){
                [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheFolderPath error:nil] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if([[[obj pathExtension] lowercaseString] isEqualToString:@"zip"]){
                        [[NSFileManager defaultManager] removeItemAtPath:[cacheFolderPath stringByAppendingPathComponent:obj] error:nil];
                    }
                    if([[[obj pathExtension] lowercaseString] isEqualToString:@"ttf"]){
                        fileName = obj;
                    }
                }];
                fileTimeKey = [cacheFolderPath lastPathComponent];
                openZippath = [kFontFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",[[cacheFolderPath lastPathComponent] stringByAppendingPathComponent:fileName]]];
            }else{
                fileTimeKey = fileName;
                openZippath = [kFontFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]];
            }
            NSString *time = [NSString stringWithFormat:@"%ld",[(hasNew ? _netFontList[index][@"updatetime"] : _netFontList[index][@"timeunix"]) integerValue]];
            
            NSString *path = kFontCheckPlistPath;
            if([[NSFileManager defaultManager] fileExistsAtPath:openZippath]){
                NSMutableDictionary *checkConfigDic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                if(!checkConfigDic){
                    checkConfigDic = [[NSMutableDictionary alloc] init];
                }
                if(time.length==0 || !time){
                    [checkConfigDic setObject:@"2015-02-03" forKey:fileTimeKey];
                }else{
                    [checkConfigDic setObject:time forKey:fileTimeKey];
                }
                if([checkConfigDic writeToFile:path atomically:YES]){
                    [weakSelf setFont:index];
                }
                sender.hidden = YES;
                sender.alpha = 0;
                [ddprogress removeFromSuperview];
            }else{
                [_hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                [_hud show];
                [_hud hideAfter:2];
                
                [ddprogress removeFromSuperview];
                sender.hidden = NO;
            }
            
            
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [_hud show];
            [_hud hideAfter:2];
            
            [ddprogress removeFromSuperview];
            sender.hidden = NO;
        });
    }];
#endif
}

#pragma mark - 下载字体
-(void)DownloadThumbnailFile:(NSString*)fileUrl andUnzipToPath:(NSString *)unzipToPath andCellcaptionTypeCount:(NSInteger)cellcaptionTypeCount
{
    NSURL *url = [NSURL URLWithString:fileUrl];
    unlink([[RDHelpClass pathFontForURL:url] UTF8String]);
    __weak CustomTextPhotoViewController *weakSelf= self;

    NSString *cacheFolderPath = [[RDHelpClass pathFontForURL:url] stringByDeletingLastPathComponent];
//    if(![[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingLastPathComponent]]){
//        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
//    }
    
    [RDFileDownloader downloadFileWithURL:fileUrl cachePath:cacheFolderPath httpMethod:GET progress:nil finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf OpenZip:fileCachePath unzipto:[RDHelpClass pathInCacheDirectory:unzipToPath] caption:NO];
            [weakSelf initFontTypeViewChild:cellcaptionTypeCount];
            
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载失败");
            [_hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [_hud show];
            [_hud hideAfter:2];
        });
    }];
    
}

- (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption
{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            
            unlink([zipPath UTF8String]);
            
        }
        [zip RDUnzipCloseFile];
    }
    
}

//根据ID设置字体
- (void)setFont:(NSInteger)index{
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL > 0;
    for (int k=0;k<_netFontList.count;k++) {
        UIButton *sender = (UIButton *)[_captionTypescroll viewWithTag:k + kCAPTIONTYPECHILDTAG];
        if(!sender){
            return;
        }
        NSDictionary *itemDic = [_netFontList objectAtIndex:sender.tag - kCAPTIONTYPECHILDTAG];
        UIImageView *imagev = (UIImageView *)[sender viewWithTag:4000];
        UIImageView *selectv = (UIImageView *)[sender viewWithTag:50000];
        NSString *title = [[_netFontList objectAtIndex:sender.tag - kCAPTIONTYPECHILDTAG] objectForKey:@"name"];
        if(k >0 && hasNew){
            title = [[[itemDic objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension];
        }
        
        
        UIImageView *titleIV = (UIImageView *)[sender viewWithTag:kFontTitleImageViewTag];
        BOOL isCached = [RDHelpClass hasCachedFont_WEBP:(hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[itemDic[@"file"] lastPathComponent]] :title) extStr:@"ttf" isNetMaterial:hasNew];
        if ([titleIV isKindOfClass:[UIImageView class]]) {
            if(isCached && sender.tag - kCAPTIONTYPECHILDTAG == index){
                if(hasNew){
                    [titleIV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *path = [NSString stringWithFormat:@"%@/%@/selected", kFontFolder,title];
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_@3x.png",title]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        titleIV.image = image;
                    }else{
                        imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_@2x.png",title]];
                        image = [UIImage imageWithContentsOfFile:imagePath];
                        if (image) {
                            titleIV.image = image;
                        }
                    }
                }
            }else if (sender.tag - kCAPTIONTYPECHILDTAG != 0) {
                if(hasNew){
                    [titleIV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *path = [NSString stringWithFormat:@"%@/%@", kFontFolder,[_netFontIconList objectForKey:@"name"]];
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@3x.png",title]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        titleIV.image = image;
                    }else{
                        imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@2x.png",title]];
                        image = [UIImage imageWithContentsOfFile:imagePath];
                        if (image) {
                            titleIV.image = image;
                        }
                    }
                }
            }
            UILabel *titleLbl = (UILabel *)[sender viewWithTag:3];
            if ([titleLbl isKindOfClass:[UILabel class]]) {
                if (sender.tag - kCAPTIONTYPECHILDTAG == index) {
                    titleLbl.textColor = Main_Color;
                }else {
                    titleLbl.textColor = UIColorFromRGB(0xbdbdbd);
                }
            }
        }
        if([imagev isKindOfClass:[UIImageView class]]){
            if((sender.tag - kCAPTIONTYPECHILDTAG == index) ||!isCached){
                if(sender.tag - kCAPTIONTYPECHILDTAG == index){
                    imagev.image = [RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"];
                    imagev.hidden = YES;
                    
                }else if(!isCached && sender.tag - kCAPTIONTYPECHILDTAG != 0 ){
                    imagev.image = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
                    imagev.hidden = NO;
                    
                }else{
                    imagev.hidden = YES;
                }
            }else{
                imagev.hidden = YES;
            }
        }
        if([selectv isKindOfClass:[UIImageView class]]){
            if((sender.tag - kCAPTIONTYPECHILDTAG == index) ||!isCached){
                if(sender.tag - kCAPTIONTYPECHILDTAG == index){
                    selectv.hidden = NO;
                }else if(!isCached && sender.tag - kCAPTIONTYPECHILDTAG != 0 ){
                    selectv.hidden = YES;
                }else{
                    selectv.hidden = NO;
                }
            }else{
                selectv.hidden = YES;
            }
        }
        if(k == 0 && index !=0){
            selectv.hidden = YES;
        }
    }
    
    if(index==0){
        self.font_Name = nil;
        fontPath = nil;
        [self setFontSize:photoTextView.text];
        return;
    }
    NSDictionary *itemDic = [_netFontList objectAtIndex:index];
    NSString *fontfile;
    if(hasNew){
        fontfile = [[[itemDic objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension];
    }else{
        fontfile = [itemDic objectForKey:@"name"];
    }
    NSString *netFontName = [itemDic objectForKey:@"fontname"];
        
    if(fontfile.length==0){
        return;
    }
    
    NSString *path = [RDHelpClass pathForURL_font_WEBP:fontfile extStr:@"ttf" isNetMaterial:hasNew];
    if(hasNew){
        NSString *n = [[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent];
        NSString *f = [NSString stringWithFormat:@"%@/%@", kFontFolder,n];
        __block NSString *fn;
        [ [[NSFileManager defaultManager] contentsOfDirectoryAtPath:f error:nil] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([[[obj pathExtension] lowercaseString] isEqualToString:@"ttf"]){
                fn = obj;
            }else{
                NSString * ipath = [NSString stringWithFormat:@"%@/%@/%@", kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],obj];
                [[NSFileManager defaultManager] removeItemAtPath:ipath error:nil];
            }
        }];
        path = [NSString stringWithFormat:@"%@/%@/%@", kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],fn];
    }
    
    self.font_Name = [RDHelpClass customFontWithPath:path fontName:netFontName];
    fontPath = path;
    [self setFontSize:photoTextView.text];
}

//设置文本域的字体大小

- (void)setFontSize:(NSString *)string{
    NSMutableArray *arr = [RDHelpClass getMaxLengthStringArr:string fontSize:kFONTSIZE];
    if(arr){
        string = [arr lastObject];
    }
    
    float width = [RDHelpClass widthForString:string andHeight:30 fontSize:kFONTSIZE];
    float size = (photoTextView.frame.size.width-30)/width;
    if(size<1){
        if(self.font_Name){
            photoTextView.font = [UIFont fontWithName:self.font_Name size:kFONTSIZE*size];
        }else{
            photoTextView.font = [UIFont systemFontOfSize:kFONTSIZE*size];
        }
        
    }else{
        if(self.font_Name){
            photoTextView.font = [UIFont fontWithName:self.font_Name size:kFONTSIZE];
        }else{
            photoTextView.font = [UIFont systemFontOfSize:kFONTSIZE];
        }
    }
    [arr removeAllObjects];
    arr = nil;
    
}
- (void)setFontSize1:(NSString *)string{
    NSMutableArray *arr = [RDHelpClass getMaxLengthStringArr:string fontSize:kFONTSIZE];
    if(arr){
        string = [arr lastObject];
    }
    
    CGSize constraintSize = CGSizeMake(CGFLOAT_MAX, 30);
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:kFONTSIZE]};
    CGRect sizeToFit = [string boundingRectWithSize:constraintSize
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:attributes
                                            context:nil];
    
    //    CGSize sizeToFit = [string sizeWithFont:[UIFont systemFontOfSize:kFONTSIZE] constrainedToSize:CGSizeMake(CGFLOAT_MAX, 30) lineBreakMode:NSLineBreakByClipping];
    float width = sizeToFit.size.width;
    float size = 360/width;
    if(size<1){
        if(self.font_Name){
            photoTextView.font = [UIFont fontWithName:self.font_Name size:kFONTSIZE*size];
        }else{
            photoTextView.font = [UIFont systemFontOfSize:kFONTSIZE*size];
        }
        
    }else{
        if(self.font_Name){
            photoTextView.font = [UIFont fontWithName:self.font_Name size:kFONTSIZE*2];
        }else{
            photoTextView.font = [UIFont systemFontOfSize:kFONTSIZE*2];
        }
    }
    attributes = nil;
    if(arr.count>0)
        [arr removeAllObjects];
    arr = nil;
}
#pragma mark- 文本框的代理方法
- (void)textViewDidChange:(UITextView *)textView{
    photoTextView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    if (textView.text.length == 0) {
        placeholderLbl.hidden = NO;
    }else {
        placeholderLbl.hidden = YES;
        //photoTextView.textColor = [UIColor whiteColor];
    }
    [self setFontSize:textView.text];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView{
    //    [self setFontSize:textView.text];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    NSString *str = textView.text;
    if([text isEqualToString:@"\n"]){
        str=[[str stringByAppendingString:text] stringByAppendingString:@"A"];
    }
    float height = [RDHelpClass heightForString:str andWidth:photoTextView.frame.size.width fontSize:photoTextView.font.pointSize];
    BOOL flag = YES;
    if(height>photoTextView.frame.size.height-29){
        height = photoTextView.frame.size.height-29;
        textView.text = [textView.text substringToIndex:textView.text.length];
        if(![text isEqualToString:@""]){
            flag = NO;
        }
    }
    photoTextView.contentOffset = CGPointMake(0, (- photoTextView.frame.size.height+height)/2.0);
    [photoTextView setNeedsDisplay];
    return flag;
    
}

- (void)keyboardDidShowNotification:(NSNotification *)notification{
    if(notification) {
        
        NSDictionary *info = [notification userInfo];
        NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGSize keyboardSize = [value CGRectValue].size;
        
        if(iPhone4s){
            _saveButton.frame = CGRectMake(0, 0, 64, 44);
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_saveButton];
            self.navigationItem.rightBarButtonItem =item;
        }else{
            bottomView.frame         = CGRectMake(0, kHEIGHT - keyboardSize.height - ( 50), bottomView.frame.size.width, (keyboardSize.height) + ( 50));
            _editTextView = YES;
        }
    }
    [photoTextView selectedTextRange];
    _selectToolItemBackView.hidden = YES;
        
}

/*
 键盘隐藏是触发
 */
- (void)keyboardDidHideNotification:(NSNotification *)notification{
    _editTextView = NO;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_saveBtn];
        self.navigationItem.rightBarButtonItem =item;
    
    bottomView.frame = CGRectMake(0, videoRectBackView.frame.origin.y + videoRectBackView.frame.size.height, kWIDTH, kHEIGHT - (videoRectBackView.frame.origin.y + videoRectBackView.frame.size.height));
        if(!iPhone4s){
            _editTextView = YES;
        }
    
    _selectToolItemBackView.hidden = NO;
    _textColorView.hidden = NO;
    _backColorView.hidden = NO;
    _captionTypescroll.hidden = NO;
    if (_captionFontTypeBtn.selected) {//20161107
        [self touchesUp:_captionFontTypeBtn];
    }
    else if (_captionTextColorBtn.selected) {
        [self touchesUp:_captionTextColorBtn];
    }
    else if (_captionBackColorBtn.selected) {
        [self touchesUp:_captionBackColorBtn];
    }
}

- (UIColor *) colorWithHexString: (NSString *)color
{
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
