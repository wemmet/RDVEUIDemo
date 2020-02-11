//
//  RDMainViewController.m
//  RDVEUISDK
//
//  Created by emmet on 16/1/12.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//
#import "RDMainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "RDEditVideoViewController.h"
#import "RDNextEditVideoViewController.h"
#import "RDRecordViewController.h"
#import "RDNavigationViewController.h"
#import "RDCloudMusicViewController.h"
#import "RDLocalMusicViewController.h"
#import "RDThumbImageView.h"
#import "RDTrimVideoViewController.h"
#import "CropViewController.h"
#import "CustomTextPhotoViewController.h"
#import "RD_ImageManager.h"
#import "UIImage+RDGIF.h"

#import "RDMBProgressHUD.h"
#define AUTOSCROLL_THRESHOLD 30

@interface RDMainViewController ()<UIAlertViewDelegate,UIImagePickerControllerDelegate,RDRecordViewDelegate, LocalPhotoCellDelegate, RDThumbImageViewDelegate, CustomTextDelegate, RDMBProgressHUDDelegate>
{
    
    BOOL                 _enterApplicationHome;
    int                  _mediaCountLimit;
    BOOL                 _exportVideoFinish;
    BOOL                 _paizhaoOrLuxiang;
    float                _toolbarHeight;
    
    NSMutableArray      *_dsV;      //视频
    int                 _dsVNumber;
    
    NSMutableArray      *_dsP;      //照片
    int                 _dsPNumber;
    
    NSMutableArray      *_dspAndV;  //视频照片
    int                 _dsPAndVNumber;
    
    NSMutableArray      *_dsShow;   //展示
    
    NSMutableArray      *_selectVideoItems;
    NSMutableArray      *_selectPhotoItems;
    
    ALAssetsGroup       *_currentPhotoAlbum;
    ALAssetsGroup       *_currentVideoAlbum;
    
    UIButton            *_paizhaoBtn;
    UIButton            *_luxiangBtn;
    UIAlertView         *commonAlertView;   //20170503 wuxiaoxia 防止内存泄露
    
    float                 thumbWidth;
    UIScrollView        * selectedFilesScrollView;
    NSMutableArray      <RDFile *>* selectedFileArray;
    int                   selectedVideoCount;
    int                   selectedPicCount;
    NSTimer             * autoscrollTimer;
    float                 autoscrollDistance;
    UILabel             * tipLbl;
    NSInteger             editThumbId;
    
    UIView              *progressHUDView;
    
    NSMutableArray<RDOtherAlbumInfo *>* allAlbumVideoArray;             //视频
    NSMutableArray<RDOtherAlbumInfo *>* allAlbumPhotoArray;             //图片
    NSMutableArray<RDOtherAlbumInfo *>* allAlbumVideoAndPhotoArray;     //视频和图片
    
    
    UIView              *albumCategeryView;
    UIScrollView        *albumCategeryScrollView;
    
    float               navBtnheight;
}

@property(nonatomic,strong)RDMBProgressHUD  *progressHUD;

@end

@implementation RDMainViewController

-(void)close_AlbumCategeryView
{
    if( albumCategeryView )
    {
        
        [RDHelpClass animateViewHidden:albumCategeryScrollView atUP:YES atBlock:^{
            
            [albumCategeryView removeFromSuperview];
            albumCategeryView = nil;
            [albumCategeryScrollView removeFromSuperview];
            albumCategeryScrollView = nil;
            
        }];
        
    }
    
    [_cameraRollBtn.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass:[UIImageView class]] )
        {
            UIImageView * imageView = (UIImageView*)obj;
            imageView.image = nil;
            imageView.image = [RDHelpClass imageWithContentOfFile:@"album/相册-箭头下"];
        }
    }];
    
  
}

-(void)albumItemBtn:(UIButton *) sender
{
    
    NSString * str = nil;
    if(_selectPhotoAndVideoBtn && _selectPhotoAndVideoBtn.selected  )
    {
        _dsPAndVNumber = sender.tag;
        _dspAndV = allAlbumVideoAndPhotoArray[_dsPAndVNumber].videoOrPicArray;
        str = allAlbumVideoAndPhotoArray[_dsPAndVNumber].title;
        [_VideoAndPhotoCollection reloadData];
    }
    else if(_selectVideoBtn && _selectVideoBtn.selected  )
    {
        _dsVNumber = sender.tag;
        _dsV = allAlbumVideoArray[_dsVNumber].videoOrPicArray;
        str = allAlbumVideoArray[_dsVNumber].title;
        [_videoCollection reloadData];
    }
    else if(_selectPhotoBtn && _selectPhotoBtn.selected  )
    {
        _dsPNumber = sender.tag;
        _dsP = allAlbumPhotoArray[_dsPNumber].videoOrPicArray;
        str = allAlbumPhotoArray[_dsPNumber].title;
        [_photoCollection reloadData];
    }
    [self close_AlbumCategeryView];
    
    [self setCameraRollBtn:str];
}

-(void)setCameraRollBtn:(NSString *) str
{
    float cameraRollBtnWidth =  [RDHelpClass widthForString:str andHeight:18 fontSize:18] + 28*2.0;
    [_cameraRollBtn setTitle:str forState:UIControlStateNormal];
    _cameraRollBtn.frame = CGRectMake((kWIDTH - cameraRollBtnWidth)/2.0, ( 44 - 28 )/2.0, cameraRollBtnWidth,28);
    [_cameraRollBtn.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass:[UIImageView class]] )
        {
            UIImageView * imageView = (UIImageView*)obj;
            imageView.frame = CGRectMake(_cameraRollBtn.frame.size.width - 28 + ( 28 - 10 )/2.0, ( 28 - 10 )/2.0, 10, 10);
        }
    }];
}

-(void)initAlbumCategeryBtn:(RDOtherAlbumInfo *) allAlbumInfo index:(int) i isSelecd:(bool) isSelecd
{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 5 + 65*i, albumCategeryScrollView.frame.size.width, 65)];
    btn.tag = i;
    
    if( isSelecd )
        btn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.8];
    
    [btn addTarget:self action:@selector(albumItemBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10+5, 5, 55, 55)];
    imageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    [btn addSubview:imageView];
    [self getThumbImage:imageView atds:allAlbumInfo.videoOrPicArray];
    
    UILabel * labelText = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.size.width + imageView.frame.origin.x + 5, 5, btn.frame.size.width - (imageView.frame.size.width + imageView.frame.origin.x + 10), 20)];
    labelText.font = [UIFont boldSystemFontOfSize:14.0];
    labelText.text = allAlbumInfo.title;
    labelText.textColor = [UIColor colorWithWhite:0.0 alpha:1.0];
    [btn addSubview: labelText];
    
    UILabel * labelNumber = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.size.width + imageView.frame.origin.x + 5, btn.frame.size.height - 20 - 5, btn.frame.size.width - (imageView.frame.size.width + imageView.frame.origin.x + 10), 20)];
    labelNumber.font = [UIFont systemFontOfSize:12.0];
    if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle)
        labelNumber.text = [NSString stringWithFormat:@"%d", allAlbumInfo.videoOrPicArray.count-1];
    else
        labelNumber.text = [NSString stringWithFormat:@"%d", allAlbumInfo.videoOrPicArray.count];
    labelNumber.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    [btn addSubview: labelNumber];
    [albumCategeryScrollView addSubview:btn];
}

-(void)initAlbumCategeryView:(int) index
{
    if( albumCategeryView )
    {
        [albumCategeryView removeFromSuperview];
        albumCategeryView = nil;
        [albumCategeryScrollView removeFromSuperview];
        albumCategeryScrollView = nil;
    }
    
    albumCategeryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    albumCategeryView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    
    UITapGestureRecognizer * tapGesture =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close_AlbumCategeryView)];
    [albumCategeryView addGestureRecognizer:tapGesture];
    
    [self.view addSubview:albumCategeryView];
    
    albumCategeryScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kWIDTH/3.0/2.0, (iPhone_X ? 44 : 20) + 44, kWIDTH*2.0/3.0, kHEIGHT - ((iPhone_X ? 44 : 20) + 44 + ((iPhone_X ? 69 : 49) + (kWIDTH - 3.0 * 8.0) / 4.0) ) )];
    albumCategeryScrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:albumCategeryScrollView];
    albumCategeryScrollView.layer.cornerRadius = 5.0;
    albumCategeryScrollView.layer.masksToBounds = YES;
    
    
    UITapGestureRecognizer * tapGesture1 =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close_AlbumCategeryView)];
    [albumCategeryScrollView addGestureRecognizer:tapGesture1];
    
    switch (index) {
        case 0:
        {
            for (int i = 0; allAlbumVideoAndPhotoArray.count > i;  i++) {
                [self initAlbumCategeryBtn:allAlbumVideoAndPhotoArray[i] index:i isSelecd:(_dsPAndVNumber == i)?true:false];
            }
            albumCategeryScrollView.contentSize = CGSizeMake(0, 10 + 65*allAlbumVideoAndPhotoArray.count);
        }
            break;
        case 1:
        {
            for (int i = 0; allAlbumVideoArray.count > i;  i++) {
                [self initAlbumCategeryBtn:allAlbumVideoArray[i] index:i isSelecd:(_dsVNumber == i)?true:false];
            }
            
            albumCategeryScrollView.contentSize = CGSizeMake(0, 10 + 65*allAlbumVideoArray.count);
        }
            break;
        case 2:
        {
            for (int i = 0; allAlbumPhotoArray.count > i;  i++) {
                [self initAlbumCategeryBtn:allAlbumPhotoArray[i] index:i isSelecd:(_dsPNumber == i)?true:false];
            }
            
            albumCategeryScrollView.contentSize = CGSizeMake(0, 10 + 65*allAlbumPhotoArray.count);
        }
            break;
        default:
            break;
    }
    [RDHelpClass animateView:albumCategeryScrollView atUP:YES];
    
}

-(void)getThumbImage:(UIImageView *) imageview atds:(NSMutableArray *) array
{
    int index = 0;
    if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
        index = 1;
    }
    
    PHAsset *asset;
    
    if( _selectPhotoAndVideoBtn && _selectPhotoAndVideoBtn.selected )
    {
        if([array[index] isKindOfClass:[NSDictionary class]]){
            NSDictionary *dic = array[index];
            UIImage *thumbImage = [dic objectForKey:@"thumbImage"];
            [imageview setImage:thumbImage];
        }
        else if([array[index] isKindOfClass:[PHAsset class]]){
            
            asset=array[index];
            
            if( asset.duration > 0 )
            {
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                        [imageview setImage:photo];
                    }
                }];
            }
            else{
                
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){
                        [imageview setImage:photo];
                    }
                }];
            }
        }
    }
    else if( _selectVideoBtn && _selectVideoBtn.selected )
    {
        if([array[index] isKindOfClass:[NSDictionary class]]){
            NSDictionary *dic = array[index];
            imageview.image = [dic objectForKey:@"thumbImage"];
        }
        else if([array[index] isKindOfClass:[PHAsset class]]){
            asset= array[index];
            [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                    [imageview setImage:photo];
                }
            }];
        }
    }
    else if( _selectPhotoBtn && _selectPhotoBtn.selected )
    {
        asset = array[index];
        [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if(!isDegraded){
                [imageview setImage:photo];
            }
        }];
    }
}

- (void)initProgressHUD:(NSString *)message{
    if (_progressHUD) {
        _progressHUD = nil;
    }
    
    progressHUDView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:progressHUDView];
    progressHUDView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    //圆形进度条
    _progressHUD = [[RDMBProgressHUD alloc] initWithView:self.view];
    [progressHUDView addSubview:_progressHUD];
    _progressHUD.removeFromSuperViewOnHide = YES;
    _progressHUD.mode = RDMBProgressHUDModeDeterminate;
    _progressHUD.animationType = RDMBProgressHUDAnimationFade;
    _progressHUD.labelText = message;
    _progressHUD.isShowCancelBtn = NO;
    [_progressHUD show:YES];
    [self myProgressTask:0];
}

- (void)myProgressTask:(float)progress{
    [_progressHUD setProgress:progress];
}

#pragma mark- 进入后台
- (void)applicationEnterHome:(NSNotification *)notification{
    _enterApplicationHome = YES;
}

#pragma mark- 进入前台
- (void)appEnterForegroundNotification:(NSNotification *)notification{
    _enterApplicationHome = NO;
}

- (BOOL)prefersStatusBarHidden {
//    return !iPhone_X;
    return  NO;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
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
    self.view.backgroundColor = UIColorFromRGB(NV_Color);
    _toolbarHeight          = 66;
    _mediaCountLimit = ((RDNavigationViewController *)self.navigationController).editConfiguration.mediaCountLimit;
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        _dsV = [NSMutableArray array];
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        _dsP = [NSMutableArray array];
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL)
    {
        _dspAndV = [NSMutableArray array];
    }
    _selectVideoItems       = [NSMutableArray array];
    _selectPhotoItems       = [NSMutableArray array];
    selectedFileArray = [NSMutableArray array];
    if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
        [_dsV addObject:@"custTextView"];
        [_dsP addObject:@"custTextView"];
        [_dspAndV addObject:@"custTextView"];
    }
    [self initNavgationItem];
    _hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.navigationController.view addSubview:_hud.view];
    
    if (_mediaCountLimit != 1) {
        thumbWidth = (kWIDTH - 3.0 * 8.0) / 4.0;
        [self initBottomView];
    }
    [self loadVideoAndPhoto];
    
    
    [self showTitleNavgationView];
    [self initCollectionView];
    
    [self initMoreBtnContentView];
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL) {
        [self initVideoAndPhotoCollection];
    }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        [self initVideoCollection];
    }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        [self initPhotoCollection];
    }
    if(_showPhotos){
        [self tapPhotoBtn];
    }
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(10, 0, 34, 0);
    }
}

- (void)loadVideoAndPhoto {
    SUPPORTFILETYPE supportFileType = ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType;
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
        {
            [RDSVProgressHUD dismiss];
            
            [self initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                             message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                   cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                   otherButtonTitles:RDLocalizedString(@"取消",nil)
                                        alertViewTag:0];
        }
            break;
        case PHAuthorizationStatusAuthorized:
            if(supportFileType != ONLYSUPPORT_IMAGE) {
                [self loadMyAppAssets];
            }
            [self loadDatasource];
            [self loadDatasourceIiem];
            break;
            
        default:
        {
            WeakSelf(self);
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if (status == PHAuthorizationStatusAuthorized) {
                        if(supportFileType != ONLYSUPPORT_IMAGE) {
                            [strongSelf loadMyAppAssets];
                        }
                        [strongSelf loadDatasource];
                        [strongSelf loadDatasourceIiem];
                        if(supportFileType == ONLYSUPPORT_IMAGE) {
                            [_photoCollection reloadData];
                        }else if(supportFileType == ONLYSUPPORT_VIDEO) {
                            [_videoCollection reloadData];
                        }else {
                            [_photoCollection reloadData];
                            [_videoCollection reloadData];
                            [_VideoAndPhotoCollection reloadData];
                        }
                    }else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                        [RDSVProgressHUD dismiss];
                        
                        [strongSelf initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                                         message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                               cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                               otherButtonTitles:RDLocalizedString(@"取消",nil)
                                                    alertViewTag:0];
                    }
                });
            }];
        }
            break;
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self refreshNavgation];
    
    
}

/**  刷新导航栏
 */
- (void)refreshNavgation{
    //self.navigationController.interactivePopGestureRecognizer.enabled = NO;////关闭滑动返回的手势
//    self.navigationController.navigationBarHidden = NO;
//    [self.navigationController setNavigationBarHidden:NO];
//    self.navigationController.navigationBar.translucent = NO;
//    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
//    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
//    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
//    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0x000000);
//
//    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
//    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
//    UIImage *theImage = [RDHelpClass rdImageWithColor:(UIColorFromRGB(0xffffff)) cornerRadius:0.0];
//    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    
}

/**调整状态栏和导航栏
 */
- (void)showTitleNavgationView{
    
    _navagationTitleView = [[UIView alloc] init];
    _navagationTitleView.frame = CGRectMake(0, (iPhone_X ? 44 : 20), [UIScreen mainScreen].bounds.size.width, 44+35);
    _navagationTitleView.backgroundColor = UIColorFromRGB(NV_Color);
//    _navagationTitleView.layer.borderColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
//    _navagationTitleView.layer.borderWidth = 1;
//    _navagationTitleView.layer.masksToBounds = YES;
//    _navagationTitleView.layer.cornerRadius = 15;
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 2, 40, 40)];
    [leftBtn addTarget:self action:@selector(tapBackBtn) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    leftBtn.titleLabel.textAlignment=NSTextAlignmentRight;
    [leftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [leftBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [_navagationTitleView addSubview:leftBtn];
    
    float selectVideoBtnWidth =  [RDHelpClass widthForString:RDLocalizedString(@"视频", nil) andHeight:16 fontSize:16] + 20;
    float selectPhotoBtnWidth =  [RDHelpClass widthForString:RDLocalizedString(@"图片", nil) andHeight:16 fontSize:16] + 20;
    float selectPhotoAndVideoBtnWidth =  [RDHelpClass widthForString:RDLocalizedString(@"全部", nil) andHeight:16 fontSize:16] + 20;
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE){
        _selectVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if( ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL )
            _selectVideoBtn.frame = CGRectMake(kWIDTH/3.0, (35 - 28)/2.0 + 44, kWIDTH/3.0,28);
        else
             _selectVideoBtn.frame = CGRectMake(0, (35 - 28)/2.0 + 44, kWIDTH/3.0,28);
//        [_selectVideoBtn setBackgroundImage:nomarlImage forState:UIControlStateNormal];
//        [_selectVideoBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [_selectVideoBtn setTitle:RDLocalizedString(@"视频", nil) forState:UIControlStateNormal];
        [_selectVideoBtn setTitle:RDLocalizedString(@"视频", nil) forState:UIControlStateSelected];
        [_selectVideoBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_selectVideoBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        [_selectVideoBtn addTarget:self action:@selector(tapVideoBtn) forControlEvents:UIControlEventTouchUpInside];
        _selectVideoBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        
        _selectVideoLabel = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH/3.0 - selectVideoBtnWidth)/2.0, _selectVideoBtn.frame.size.height - 3.0, selectVideoBtnWidth, 3.0)];
        _selectVideoLabel.backgroundColor = [UIColor clearColor];
        _selectVideoLabel.layer.cornerRadius = _selectVideoLabel.frame.size.height/2.0;
        _selectVideoLabel.layer.masksToBounds = YES;
        [_selectVideoBtn addSubview:_selectVideoLabel];
        _dsVNumber = 0;
        [_navagationTitleView addSubview:_selectVideoBtn];
    }
    if(((RDNavigationViewController *)self.navigationController) .editConfiguration.supportFileType != ONLYSUPPORT_VIDEO){
        _selectPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if( ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE )
            _selectPhotoBtn.frame = CGRectMake(0, (35 - 28)/2.0 + 44, kWIDTH/3.0, 28);
        else
            _selectPhotoBtn.frame = CGRectMake(kWIDTH/3.0*2.0, (35 - 28)/2.0 + 44, kWIDTH/3.0, 28);
//        [_selectPhotoBtn setBackgroundImage:nomarlImage forState:UIControlStateNormal];
//        [_selectPhotoBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [_selectPhotoBtn setTitle:RDLocalizedString(@"图片", nil) forState:UIControlStateNormal];
        [_selectPhotoBtn setTitle:RDLocalizedString(@"图片", nil) forState:UIControlStateSelected];
        [_selectPhotoBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_selectPhotoBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        [_selectPhotoBtn addTarget:self action:@selector(tapPhotoBtn) forControlEvents:UIControlEventTouchUpInside];
        _selectPhotoBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        
        _selectPhotoLabel = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH/3.0 - selectPhotoBtnWidth)/2.0, _selectPhotoBtn.frame.size.height - 3.0, selectPhotoBtnWidth, 3.0)];
        _selectPhotoLabel.backgroundColor = [UIColor clearColor];
        _selectPhotoLabel.layer.cornerRadius = _selectPhotoLabel.frame.size.height/2.0;
        _selectPhotoLabel.layer.masksToBounds = YES;
        [_selectPhotoBtn addSubview:_selectPhotoLabel];
        
        [_navagationTitleView addSubview:_selectPhotoBtn];
        _dsPNumber = 0;
    }
    
    if(((RDNavigationViewController *)self.navigationController) .editConfiguration.supportFileType == SUPPORT_ALL)
    {
         _selectPhotoAndVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectPhotoAndVideoBtn.frame = CGRectMake(0, (35 - 28)/2.0 + 44, kWIDTH/3.0, 28);
        [_selectPhotoAndVideoBtn setTitle:RDLocalizedString(@"全部", nil) forState:UIControlStateNormal];
        [_selectPhotoAndVideoBtn setTitle:RDLocalizedString(@"全部", nil) forState:UIControlStateSelected];
        [_selectPhotoAndVideoBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_selectPhotoAndVideoBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        [_selectPhotoAndVideoBtn addTarget:self action:@selector(tapPhotoAndVideBtn) forControlEvents:UIControlEventTouchUpInside];
        _selectPhotoAndVideoBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        
        _selectPhotoAndVideoLabel = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH/3.0 - selectPhotoBtnWidth)/2.0, _selectPhotoAndVideoBtn.frame.size.height - 3.0, selectPhotoBtnWidth, 3.0)];
        _selectPhotoAndVideoLabel.backgroundColor = [UIColor clearColor];
        _selectPhotoAndVideoLabel.layer.cornerRadius = _selectPhotoAndVideoLabel.frame.size.height/2.0;
        _selectPhotoAndVideoLabel.layer.masksToBounds = YES;
        [_selectPhotoAndVideoBtn addSubview:_selectPhotoAndVideoLabel];
        
        [_navagationTitleView addSubview:_selectPhotoAndVideoBtn];
        _dsPAndVNumber = 0;
    }
    
    NSString * str = RDLocalizedString(@"全部内容", nil);
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
        _selectPhotoBtn.selected = YES;
        _selectPhotoBtn.hidden = YES;
        _selectPhotoLabel.backgroundColor = Main_Color;
        str = RDLocalizedString(@"所有图片", nil);
        _navagationTitleView.frame = CGRectMake(0, (iPhone_X ? 44 : 20), [UIScreen mainScreen].bounds.size.width, 44);
        navBtnheight = 0;
//        _selectPhotoBtn.frame = _navagationTitleView.bounds;
    }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
        _selectVideoBtn.selected = YES;
        _selectVideoBtn.hidden = YES;
        _selectVideoLabel.backgroundColor = Main_Color;
        str = RDLocalizedString(@"所有视频", nil);
         _navagationTitleView.frame = CGRectMake(0, (iPhone_X ? 44 : 20), [UIScreen mainScreen].bounds.size.width, 44);
        navBtnheight = 0;
//        _selectVideoBtn.frame = _navagationTitleView.bounds;
    }else {
        _selectVideoBtn.selected = NO;
        _selectPhotoBtn.selected = NO;
        _selectPhotoAndVideoBtn.selected = YES;
        _selectPhotoAndVideoLabel.backgroundColor = Main_Color;
        navBtnheight = 35;
    }
    
   
    
    float cameraRollBtnWidth =  [RDHelpClass widthForString:str andHeight:18 fontSize:18] + 28*2.0;
    _cameraRollBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _cameraRollBtn.frame = CGRectMake((kWIDTH - cameraRollBtnWidth)/2.0, ( 44 - 28 )/2.0, cameraRollBtnWidth,28);
    //        [_selectVideoBtn setBac kgroundImage:nomarlImage forState:UIControlStateNormal];
    //        [_selectVideoBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
    [_cameraRollBtn setTitle:str forState:UIControlStateNormal];
    _cameraRollBtn.tag = 0;
    [_cameraRollBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [_cameraRollBtn setTitleColor:TEXT_COLOR forState:UIControlStateHighlighted];
    [_cameraRollBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    [_cameraRollBtn addTarget:self action:@selector(tapCameraRollBtn) forControlEvents:UIControlEventTouchUpInside];
    _cameraRollBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    _cameraRollBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(_cameraRollBtn.frame.size.width - 28 + ( 28 - 10 )/2.0, ( 28 - 10 )/2.0, 10, 10)];
    imageView.tag = 10;
    imageView.image = [RDHelpClass imageWithContentOfFile:@"album/相册-箭头下"];
    [_cameraRollBtn addSubview:imageView];
    
    [_navagationTitleView addSubview:_cameraRollBtn];
    
//    self.navigationItem.titleView = _navagationTitleView;
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableAlbumCamera){

        UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [rightBtn setFrame:CGRectMake(_navagationTitleView.frame.size.width - 44 - 10, 0, 44, 44)];
        rightBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [rightBtn setImage:[RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频_拍照默认_"] forState:UIControlStateNormal];
        [rightBtn setImage:[RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频_拍照点击_"] forState:UIControlStateSelected];
        [rightBtn setImage:[RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频_拍照点击_"] forState:UIControlStateHighlighted];
        [rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [rightBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];

        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
            rightBtn.tag = 1;
            [rightBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
            [rightBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
        }else{
            [rightBtn addTarget:self action:@selector(enter_paisheOrRecoderVide) forControlEvents:UIControlEventTouchUpInside];
        }
        [_navagationTitleView addSubview:rightBtn];
        

        
//        float paizhaoBtnWidth =  [RDHelpClass widthForString:RDLocalizedString(@"拍照", nil)  andHeight:14 fontSize:14] + 20;
//
//        float luxiangBtnWidth =  [RDHelpClass widthForString:RDLocalizedString(@"录像", nil)  andHeight:14 fontSize:14] + 20;
//        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_VIDEO)
//        {
//            _paizhaoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//            [_paizhaoBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
//            _paizhaoBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//            [_paizhaoBtn setTitle:RDLocalizedString(@"拍照", nil) forState:UIControlStateNormal];
//            [_paizhaoBtn setTitle:RDLocalizedString(@"拍照", nil) forState:UIControlStateHighlighted];
//            _paizhaoBtn.tag = 1;
//            [_paizhaoBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateHighlighted];
//            [_paizhaoBtn setTitleColor:Main_Color forState:UIControlStateNormal];
//            _paizhaoBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
//            if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE)
//            {
//                [_paizhaoBtn setFrame:CGRectMake(_navagationTitleView.frame.size.width - 10 - paizhaoBtnWidth - luxiangBtnWidth - 1.5, 2, paizhaoBtnWidth, 40)];
//            }
//            else{
//                [_paizhaoBtn setFrame:CGRectMake(_navagationTitleView.frame.size.width - 10 - paizhaoBtnWidth, 2, paizhaoBtnWidth, 40)];
//            }
//            [_navagationTitleView addSubview:_paizhaoBtn];
//        }
//        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType != ONLYSUPPORT_IMAGE)
//        {
//            _luxiangBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//            [_luxiangBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
//            _luxiangBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//            [_luxiangBtn setTitle:RDLocalizedString(@"录像", nil) forState:UIControlStateNormal];
//            [_luxiangBtn setTitle:RDLocalizedString(@"录像", nil) forState:UIControlStateHighlighted];
//            _luxiangBtn.tag = 2;
//            [_luxiangBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateHighlighted];
//            [_luxiangBtn setTitleColor:Main_Color forState:UIControlStateNormal];
//            [_luxiangBtn setFrame:CGRectMake(_navagationTitleView.frame.size.width - 10 - luxiangBtnWidth, 2.0, luxiangBtnWidth, 40)];
//            _luxiangBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
//            [_navagationTitleView addSubview:_luxiangBtn];
//        }
//
//        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL)
//        {
//            UIImageView * image = [[UIImageView alloc] initWithFrame:CGRectMake(_navagationTitleView.frame.size.width - 10 - luxiangBtnWidth - 1.5, (44 - 14)/2.0, 1.5, 14)];
//            image.backgroundColor = UIColorFromRGB(0x000000);
//            [_navagationTitleView addSubview:image];
//        }
    }
    
    [self.view addSubview:_navagationTitleView];
}

#pragma mark- 初始化
/**自定义导航栏按钮控件
 */
- (void)initNavgationItem{
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [leftBtn addTarget:self action:@selector(tapBackBtn) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    leftBtn.titleLabel.textAlignment=NSTextAlignmentRight;
    [leftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
    [leftBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];

    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        spaceItem.width=-9;
    }else{
        spaceItem.width=0;
    }

    UIBarButtonItem *leftButton= [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    leftBtn.exclusiveTouch=YES;
    leftButton.tag = 1;
    self.navigationItem.leftBarButtonItems = @[spaceItem,leftButton];

    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableAlbumCamera){
        UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [rightBtn setFrame:CGRectMake(0, 0, 44, 44)];
        rightBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [rightBtn setImage:[RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频_拍照默认_"] forState:UIControlStateNormal];
        [rightBtn setImage:[RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频_拍照点击_"] forState:UIControlStateSelected];
        [rightBtn setImage:[RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频_拍照点击_"] forState:UIControlStateHighlighted];
        [rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [rightBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];

        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
            rightBtn.tag = 1;
            [rightBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
            [rightBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
        }else{
            [rightBtn addTarget:self action:@selector(enter_paisheOrRecoderVide) forControlEvents:UIControlEventTouchUpInside];
        }

        UIBarButtonItem *spaceItem_right = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceItem_right.width = -7;

        UIBarButtonItem *rightButton= [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        rightBtn.exclusiveTouch=YES;
        rightButton.tag = 2;
        self.navigationItem.rightBarButtonItems = @[spaceItem_right,rightButton];
    }
}

- (void)initMoreBtnContentView{
    
    _moreContentView = [[UIImageView alloc] init];
    _moreContentView.userInteractionEnabled = YES;
    _moreContentView.image = [RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/选择视频拍照选项_"];
    _moreContentView.frame = CGRectMake(kWIDTH - 100, 44 + (iPhone_X ? 44 : 20) , 100, 90);
    _moreContentView.backgroundColor = [UIColor clearColor];
    _moreContentView.alpha = 0;
    _moreContentView.layer.masksToBounds = YES;
    
    _paizhaoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_paizhaoBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
    _paizhaoBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [_paizhaoBtn setTitle:RDLocalizedString(@"拍照", nil) forState:UIControlStateNormal];
    [_paizhaoBtn setTitle:RDLocalizedString(@"拍照", nil) forState:UIControlStateHighlighted];
    _paizhaoBtn.tag = 1;
    [_paizhaoBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
    [_paizhaoBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    
    _luxiangBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_luxiangBtn addTarget:self action:@selector(enter_RecordVideo:) forControlEvents:UIControlEventTouchUpInside];
    _luxiangBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [_luxiangBtn setTitle:RDLocalizedString(@"录像", nil) forState:UIControlStateNormal];
    [_luxiangBtn setTitle:RDLocalizedString(@"录像", nil) forState:UIControlStateHighlighted];
    _luxiangBtn.tag = 2;
    [_luxiangBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
    [_luxiangBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    
    [_paizhaoBtn setFrame:CGRectMake(0, _moreContentView.frame.size.height - 40 * 2  - 3, _moreContentView.frame.size.width, 40)];
    [_luxiangBtn setFrame:CGRectMake(0, _moreContentView.frame.size.height - 41, _moreContentView.frame.size.width, 40)];
    
    [_moreContentView addSubview:_paizhaoBtn];
    [_moreContentView addSubview:_luxiangBtn];
    _moreContentView.frame = CGRectMake(_moreContentView.frame.origin.x, _moreContentView.frame.origin.y + 41, _moreContentView.frame.size.width, 0);
    [self.view addSubview:_moreContentView];
}

/**
 *  初始化视频，图片显示控件
 */
- (void)initCollectionView{
    _collectionScrollView = [[UIScrollView alloc] init];
    _collectionScrollView.backgroundColor =UIColorFromRGB(0xffffff);
    _collectionScrollView.showsHorizontalScrollIndicator = NO;
    _collectionScrollView.showsVerticalScrollIndicator = NO;
    _collectionScrollView.pagingEnabled = YES;
    _collectionScrollView.delegate = self;
    _collectionScrollView.bounces = NO;
    _collectionScrollView.frame = CGRectMake(0, (iPhone_X ? 88 : 44+20) + navBtnheight, kWIDTH, kHEIGHT  - (iPhone_X ? 88 : 44+20) - navBtnheight - _bottomView.bounds.size.height);
    _collectionScrollView.contentSize = CGSizeMake(_collectionScrollView.frame.size.width*2, _collectionScrollView.frame.size.height);
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO || ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
        _collectionScrollView.contentSize = CGSizeMake(_collectionScrollView.frame.size.width, _collectionScrollView.frame.size.height);
    }else{
        _collectionScrollView.contentSize = CGSizeMake(_collectionScrollView.frame.size.width*3.0, _collectionScrollView.frame.size.height);
    }
    [self.view addSubview:_collectionScrollView];
}

/**
 *  初始化底部视图
 */
- (void)initBottomView{
    _bottomView = [[UIView alloc] init];
    _bottomView.frame = CGRectMake(0, kHEIGHT - ((iPhone_X ? (88 + 69) : (44 + 20 + 49)) + thumbWidth) + (iPhone_X ? 88 : 44+20), kWIDTH, (iPhone_X ? 69 : 49) + thumbWidth);
    _bottomView.backgroundColor = UIColorFromRGB(NV_Color);
    [self.view addSubview:_bottomView];
    
    if(_selectCountLabel.superview){
        [_selectCountLabel removeFromSuperview];
    }
    _selectCountLabel = [[UILabel alloc] init];
    _selectCountLabel.frame = CGRectMake(15, (49 - 30)/2, _bottomView.frame.size.width - 49-30, 30);
    _selectCountLabel.backgroundColor = [UIColor clearColor];
    _selectCountLabel.textAlignment = NSTextAlignmentLeft;
    _selectCountLabel.textColor = UIColorFromRGB(0xffffff);
    _selectCountLabel.font=[UIFont systemFontOfSize:14];
    if (_videoCountLimit > 0 || _picCountLimit > 0) {
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%d/%d",RDLocalizedString(@"视频", nil),0, _videoCountLimit];
        }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%d/%d",RDLocalizedString(@"图片", nil),0, _picCountLimit];
        }else{
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%d/%d , %@:%d/%d",RDLocalizedString(@"视频", nil),0, _videoCountLimit,RDLocalizedString(@"图片", nil),0, _picCountLimit];
        }
    }else if (_minCountLimit > 0) {
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
            _selectCountLabel.text = [NSString stringWithFormat:RDLocalizedString(@"视频(至少%d个):%d", nil), _minCountLimit, 0];
        }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
            _selectCountLabel.text = [NSString stringWithFormat:RDLocalizedString(@"图片(至少%d张):%d", nil), _minCountLimit, 0];
        }else{
            _selectCountLabel.text = [NSString stringWithFormat:RDLocalizedString(@"素材(至少%d个):%d", nil), _minCountLimit, 0];
        }
    }else {
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%d",RDLocalizedString(@"视频", nil),0];
        }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%d",RDLocalizedString(@"图片", nil),0];
        }else{
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%d , %@:%d",RDLocalizedString(@"视频", nil),0,RDLocalizedString(@"图片", nil),0];
        }
    }
    [_bottomView addSubview:_selectCountLabel];
    
    if(_selectOkBtn.superview){
        [_selectOkBtn removeFromSuperview];
    }
    _selectOkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_selectOkBtn addTarget:self action:@selector(tapSelectOkBtn) forControlEvents:UIControlEventTouchUpInside];
    [_selectOkBtn setFrame:CGRectMake(_bottomView.frame.size.width - 73, (49 - 28)/2, 63, 28)];
    UIImage *normalImage = [RDHelpClass rdImageWithColor:Main_Color size:_selectOkBtn.bounds.size cornerRadius:14];
    UIImage *disableImage = [RDHelpClass rdImageWithColor:[Main_Color colorWithAlphaComponent:0.5] size:_selectOkBtn.bounds.size cornerRadius:14];
    [_selectOkBtn setBackgroundImage:normalImage forState:UIControlStateNormal];
    [_selectOkBtn setBackgroundImage:disableImage forState:UIControlStateDisabled];
    [_selectOkBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
    [_selectOkBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
    [_selectOkBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateDisabled];
    _selectOkBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    _selectOkBtn.enabled = NO;
    [_bottomView addSubview:_selectOkBtn];
    
    selectedFilesScrollView = [UIScrollView new];
    selectedFilesScrollView.frame = CGRectMake(5, 49, kWIDTH - 10, thumbWidth);
    selectedFilesScrollView.contentSize = CGSizeMake(selectedFileArray.count * (thumbWidth ), 0);
    selectedFilesScrollView.showsVerticalScrollIndicator = NO;
    selectedFilesScrollView.showsHorizontalScrollIndicator = NO;
    [selectedFilesScrollView setCanCancelContentTouches:NO];
    [selectedFilesScrollView setClipsToBounds:NO];
    [_bottomView addSubview:selectedFilesScrollView];
    
    tipLbl = [[UILabel alloc] initWithFrame:selectedFilesScrollView.frame];
    if( ((RDNavigationViewController *)self.navigationController) .editConfiguration.supportFileType == SUPPORT_ALL )
        tipLbl.text = RDLocalizedString(@"请选择视频/图片", nil);
    else if( ((RDNavigationViewController *)self.navigationController) .editConfiguration.supportFileType == ONLYSUPPORT_VIDEO )
    {
        tipLbl.text = RDLocalizedString(@"请选择视频", nil);
    }
    else if( ((RDNavigationViewController *)self.navigationController) .editConfiguration.supportFileType == ONLYSUPPORT_IMAGE )
    {
        tipLbl.text = RDLocalizedString(@"请选择图片", nil);
    }
    tipLbl.textColor = [UIColor whiteColor];
    tipLbl.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:tipLbl];
    
    [self changecountLabel];
}

- (void)initPhotoCollection{
    CGRect tableRect;
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO
       || ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE)
    {
        tableRect = CGRectMake(0, 0, _collectionScrollView.frame.size.width, _collectionScrollView.frame.size.height);
    }else{
        tableRect = CGRectMake(_collectionScrollView.frame.size.width*2.0, 0, _collectionScrollView.frame.size.width, _collectionScrollView.frame.size.height);
    }
    
    UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    float width = (tableRect.size.width - 3.0 * 2.0) / 4.0;
    flow.itemSize = CGSizeMake(width,width);
    flow.minimumLineSpacing = 2.0;
    flow.minimumInteritemSpacing = 2.0;
    
    _photoCollection = [[UICollectionView alloc] initWithFrame: tableRect collectionViewLayout: flow];
    _photoCollection.backgroundColor = [UIColor clearColor];
    _photoCollection.showsVerticalScrollIndicator = NO;
    _photoCollection.showsHorizontalScrollIndicator = NO;
    [_collectionScrollView addSubview:_photoCollection];
    _photoCollection.dataSource=self;
    _photoCollection.delegate=self;
    _photoCollection.tag = 2;
    [_photoCollection registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"photocell"];
    if (iPhone_X) {
        _photoCollection.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
}

- (void)initVideoCollection
{
    CGRect tableRect = CGRectZero;
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO
       || ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE)
    {
        tableRect = CGRectMake(0, 0, _collectionScrollView.frame.size.width, _collectionScrollView.frame.size.height);
    }else{
        tableRect = CGRectMake(_collectionScrollView.frame.size.width, 0, _collectionScrollView.frame.size.width, _collectionScrollView.frame.size.height);
    }
    
    UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    float width;
    width = (tableRect.size.width - 3.0 * 2.0) / 4.0;
    flow.itemSize = CGSizeMake(width,width);
    flow.minimumLineSpacing = 2.0;
    flow.minimumInteritemSpacing = 2.0;
    
    _videoCollection = [[UICollectionView alloc] initWithFrame:tableRect collectionViewLayout: flow];
    _videoCollection.backgroundColor = [UIColor clearColor];
    _videoCollection.showsHorizontalScrollIndicator = NO;
    _videoCollection.showsVerticalScrollIndicator = NO;
    [_collectionScrollView addSubview:_videoCollection];
    _videoCollection.tag = 1;
    _videoCollection.dataSource=self;
    _videoCollection.delegate=self;
    [_videoCollection registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"photocell"];
    if (iPhone_X) {
        _videoCollection.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
}

- (void)initVideoAndPhotoCollection
{
    CGRect tableRect = CGRectMake(0, 0, _collectionScrollView.frame.size.width, _collectionScrollView.frame.size.height);
    
    UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    float width;
    width = (tableRect.size.width - 3.0 * 2.0) / 4.0;
    flow.itemSize = CGSizeMake(width,width);
    flow.minimumLineSpacing = 2.0;
    flow.minimumInteritemSpacing = 2.0;
    
    _VideoAndPhotoCollection = [[UICollectionView alloc] initWithFrame:tableRect collectionViewLayout: flow];
    _VideoAndPhotoCollection.backgroundColor = [UIColor clearColor];
    
    [_collectionScrollView addSubview:_VideoAndPhotoCollection];
    _VideoAndPhotoCollection.tag = 1;
    _VideoAndPhotoCollection.showsHorizontalScrollIndicator = NO;
    _VideoAndPhotoCollection.showsVerticalScrollIndicator = NO;
    _VideoAndPhotoCollection.dataSource=self;
    _VideoAndPhotoCollection.delegate=self;
    [_VideoAndPhotoCollection registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"photocell"];
    if (iPhone_X) {
        _VideoAndPhotoCollection.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
}

#pragma mark- 加载视频和图片相册分类
- (void)loadDatasourceIiem{
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
        allAlbumPhotoArray = [NSMutableArray array];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
        allAlbumVideoArray = [NSMutableArray array];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                            PHAssetMediaTypeVideo];
    }
    else{
        allAlbumPhotoArray = [NSMutableArray array];
        allAlbumVideoArray = [NSMutableArray array];
        allAlbumVideoAndPhotoArray = [NSMutableArray array];
    }
    
    
    
    if( _dsP && (_dsP.count > 0) )
    {
        RDOtherAlbumInfo *infoPhoto = [[RDOtherAlbumInfo alloc] init];
        infoPhoto.title = RDLocalizedString(@"所有图片", nil);
        [infoPhoto.videoOrPicArray addObjectsFromArray:_dsP];
        [allAlbumPhotoArray addObject:infoPhoto];
    }

    if( _dsV && (_dsV.count > 0) )
    {
        RDOtherAlbumInfo *infoVideo = [[RDOtherAlbumInfo alloc] init];
        infoVideo.title = RDLocalizedString(@"所有视频", nil);
        [infoVideo.videoOrPicArray addObjectsFromArray:_dsV];
        [allAlbumVideoArray addObject:infoVideo];
    }
    
    if( _dspAndV && (_dspAndV.count > 0) )
    {
        RDOtherAlbumInfo *infoVideoAndPhoto = [[RDOtherAlbumInfo alloc] init];
        infoVideoAndPhoto.title = RDLocalizedString(@"全部内容", nil);
        [infoVideoAndPhoto.videoOrPicArray addObjectsFromArray:_dspAndV];
        [allAlbumVideoAndPhotoArray addObject:infoVideoAndPhoto];
    }
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        if (![collection isKindOfClass:[PHAssetCollection class]]// 有可能是PHCollectionList类的的对象，过滤掉
            || collection.estimatedAssetCount <= 0
            || fetchResult.count < 1)// 过滤空相册
        {
            continue;
        }
        if (![RDHelpClass isCameraRollAlbum:collection]) {
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            RDOtherAlbumInfo *infoPhoto = nil;
            RDOtherAlbumInfo *infoVideo = nil;
            RDOtherAlbumInfo *infoVideoAndPhoto = nil;
            
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
                infoPhoto = [[RDOtherAlbumInfo alloc] init];
                infoPhoto.title = collection.localizedTitle;
                if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle)
                {
                    [infoPhoto.videoOrPicArray addObject:@"custTextView"];
                }
            }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
                infoVideo = [[RDOtherAlbumInfo alloc] init];
                infoVideo.title = collection.localizedTitle;
                if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle)
                {
                    [infoVideo.videoOrPicArray addObject:@"custTextView"];
                }
            }
            else{
                infoPhoto = [[RDOtherAlbumInfo alloc] init];
                infoVideo = [[RDOtherAlbumInfo alloc] init];
                infoVideoAndPhoto = [[RDOtherAlbumInfo alloc] init];
                
                infoPhoto.title = collection.localizedTitle;
                infoVideo.title = collection.localizedTitle;
                infoVideoAndPhoto.title = collection.localizedTitle;
                if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle)
                {
                    [infoPhoto.videoOrPicArray addObject:@"custTextView"];
                    [infoVideo.videoOrPicArray addObject:@"custTextView"];
                    [infoVideoAndPhoto.videoOrPicArray addObject:@"custTextView"];
                }
            }
            
           
            bool isText = false;
            
            if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
                if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE)
                    isText = true;
                else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO)
                    isText = true;
                else
                    isText = true;
            }
            
            for (PHAsset *asset in fetchResult) {
                if (asset.mediaType == PHAssetMediaTypeVideo) { //视频
                    if( infoVideo )
                        [infoVideo.videoOrPicArray addObject:asset];
                }else{  //图片
                    if( infoPhoto )
                        [infoPhoto.videoOrPicArray addObject:asset];
                }
                //全部
                if( infoVideoAndPhoto )
                    [infoVideoAndPhoto.videoOrPicArray addObject:asset];
            }
            if(  infoPhoto && (infoPhoto.videoOrPicArray.count > 0) )
            {
                if( isText )
                {
                    if( infoPhoto.videoOrPicArray.count > 1 )
                        [allAlbumPhotoArray addObject:infoPhoto];
                }
                else{
                    if( infoPhoto.videoOrPicArray.count > 0 )
                    [allAlbumPhotoArray addObject:infoPhoto];
                }
            }
            if( infoVideo && (infoVideo.videoOrPicArray.count > 0) )
            {
                if( isText )
                {
                    if( infoVideo.videoOrPicArray.count > 1 )
                        [allAlbumVideoArray addObject:infoVideo];
                }
                else{
                    if( infoVideo.videoOrPicArray.count > 0 )
                    [allAlbumVideoArray addObject:infoVideo];
                }
            }
            if( infoVideoAndPhoto && (infoVideoAndPhoto.videoOrPicArray.count > 0) )
            {
                if( isText )
                {
                    if( infoVideoAndPhoto.videoOrPicArray.count > 1 )
                        [allAlbumVideoAndPhotoArray addObject:infoVideoAndPhoto];
                }
                else{
                    if( infoVideoAndPhoto.videoOrPicArray.count > 0 )
                    [allAlbumVideoAndPhotoArray addObject:infoVideoAndPhoto];
                }
            }
        }
    }
}

#pragma mark- 加载视频和图片资源
- (void)loadDatasource{
#if 0   //iOS8.1后，下面的方法获取的不再包含从 iTunes 同步以及在 iCloud 中的照片和视频
    [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    // 这时 assetsFetchResults 中包含的，应该就是各个资源（PHAsset）
    for (NSInteger i = 0; i < assetsFetchResults.count; i++) {
        // 获取一个资源（PHAsset）
        PHAsset *phAsset = assetsFetchResults[i];
        if (phAsset.mediaType == PHAssetMediaTypeVideo) {
            [_dsV addObject:phAsset];
            //NSLog(@"视频个数：%d",_dsV.count);
        }else{
            [_dsP addObject:phAsset];
        }
    }
#else
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
//    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];//@"modificationDate"
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                            PHAssetMediaTypeVideo];
    }
    NSInteger insertIndex = 0;
    if(self.selectFinishActionBlock && ((RDNavigationViewController *)self.navigationController).editConfiguration.enableTextTitle){
        insertIndex = 1;
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
                    [_dsV insertObject:asset atIndex:insertIndex];
                }else{
                    [_dsP insertObject:asset atIndex:insertIndex];
                }
                if( _dspAndV )
                    [_dspAndV insertObject:asset atIndex:insertIndex];
            }
            break;
        }
    }
#endif
}

- (PHImageRequestID)getPhotoWithAsset:(PHAsset *)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    
    PHAsset *phAsset = (PHAsset *)asset;
    CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
    CGFloat pixelWidth = photoWidth * 2.0;
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
    
    // 修复获取图片时出现的瞬间内存过高问题
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        }
        // Download image from iCloud / 从iCloud下载图片
        if ([info objectForKey:PHImageResultIsInCloudKey] && !result) {
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
            option.networkAccessAllowed = YES;
            option.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                
            }];
        }
    }];
    return imageRequestID;
}


/**加载APP内的所有视频
 */
- (void)loadMyAppAssets{
    
    FolderType folderType = (((RDNavigationViewController *)self.navigationController)).folderType;
    
    if(folderType == kFolderNone){
        ((RDNavigationViewController *)self.navigationController).appAlbumCacheName = @"";
        return;
    }
    NSString *albumName = (((RDNavigationViewController *)self.navigationController)).appAlbumCacheName;
    NSMutableArray *array =  [self getAllFileName:albumName];
    for (int i= (int)(array.count - 1) ; i>=0;i--) {
        NSString *file = array[i];
        NSString *extString = [file pathExtension];
        
        if(![[extString lowercaseString] isEqualToString:@"mov"] && ![[extString lowercaseString] isEqualToString:@"mp4"])   //取得后缀名这.png的文件名
        {
            [array removeObjectAtIndex:i];
        }
    }
    
    for (NSString *fileName in array) {
        NSString *path;
        if(folderType == kFolderLibrary){
            path = [RDHelpClass pathInCacheDirectory:[NSString stringWithFormat:@"%@/%@",albumName,fileName]];
        }else if(folderType == kFolderDocuments){
            
            path  = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/%@/%@/%@",@"Documents",albumName,fileName]];
            
        }else{
            
            path  = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@/%@",albumName,fileName]];
        }
        
        
        NSURL *url = [NSURL fileURLWithPath:path];
        path = nil;
        //NSLog(@"url:%@",url);
        
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAlasset = [AVURLAsset URLAssetWithURL:url options:opts];
        
        UIImage *image = [RDHelpClass assetGetThumImage:0 url:url urlAsset:nil];
        url = nil;
        opts = nil;
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        
        if(image){
            [dic setObject:image forKey:@"thumbImage"];
            [dic setObject:urlAlasset forKey:@"urlAsset"];
            [dic setObject:[NSValue valueWithCMTime:urlAlasset.duration] forKey:@"durationTime"];
            [_dsV addObject:dic];
            
            if( _dspAndV )
               [_dspAndV addObject:dic];
        }
    }
    
    [array removeAllObjects];
    array = nil;
    //[_videoCollection reloadData];
}

/**在这里获取应用程序albumName文件夹里的文件及文件夹列表
 */
- (NSMutableArray *)getAllFileName:(NSString *)albumName{
    
    @autoreleasepool {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //
        NSString *documentDir;
        FolderType folderType = (((RDNavigationViewController *)self.navigationController)).folderType;
        if(folderType == kFolderLibrary){
            documentDir = [NSString stringWithFormat:@"%@",[RDHelpClass pathInCacheDirectory:albumName]];
            
        }else if(folderType == kFolderDocuments){
            
            documentDir  = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/%@/%@",@"Documents",albumName]];
            
        }else{
            
            documentDir  = [NSTemporaryDirectory() stringByAppendingString:albumName];
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:documentDir]){
            return nil;
        }
        
        NSError *error = nil;
        
        NSMutableArray *fileList;
        
        //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
        
        fileList = [[fileManager contentsOfDirectoryAtPath:documentDir error:&error] mutableCopy];
        
        //    以下这段代码则可以列出给定一个文件夹里的所有子文件夹名
        
        NSMutableArray *dirArray = [[NSMutableArray alloc] init];
        
        BOOL isDir = NO;
        
        //在上面那段程序中获得的fileList中列出文件夹名
        
        for (NSString *file in fileList) {
            
            NSString *path = [documentDir stringByAppendingPathComponent:file];
            
            isDir = [fileManager fileExistsAtPath:path isDirectory:(&isDir)];
            
            if (isDir) {
                
                NSString *filePath = [[NSString stringWithFormat:@"%@/",documentDir] stringByAppendingString:file];
                
                NSString *extString = [file pathExtension];
                
                if([[extString lowercaseString] isEqualToString:@"mov"] || [[extString lowercaseString] isEqualToString:@"mp4"])   //取得后缀名这.png的文件名
                {
                    [dirArray addObject:filePath];
                }
            }
            
            isDir = NO;
            
        }
        NSArray *myary = [fileList sortedArrayUsingComparator:^(NSString * obj1, NSString * obj2){
            obj1 = [obj1 lowercaseString];
            obj2 = [obj2 lowercaseString];
            return (NSComparisonResult)[obj1 compare:obj2 options:NSNumericSearch];
        }];
        [fileList removeAllObjects];
        fileList = nil;
        return [myary mutableCopy];
    }
}


#pragma mark- 拍照或是录像

- (void)enter_paisheOrRecoderVide{
    if( _moreContentView )
        _moreContentView.hidden = NO;
    __block typeof(self) bself = self;
    if(_moreContentView.alpha == 0){
        _moreContentView.alpha = 1.0;
        [UIView animateWithDuration:0.25 animations:^{
            bself->_moreContentView.frame = CGRectMake(kWIDTH - 100, 44 + (iPhone_X ? 44 : 20) , 100, 90);
        }];
    }else{
        [UIView animateWithDuration:0.25 animations:^{
            bself->_moreContentView.frame = CGRectMake(bself->_moreContentView.frame.origin.x, bself->_moreContentView.frame.origin.y + 41, bself->_moreContentView.frame.size.width, 0);
            
        } completion:^(BOOL finished) {
            bself->_moreContentView.alpha = 0;
            
        }];
    }
    
}

- (void)saveToPhotoLibrary:(NSString *)path isImage:(BOOL)isImage
{
    WeakSelf(self);
    NSMutableArray *imageIds = [NSMutableArray array];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //写入到相册
        if (isImage) {
            PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:path]];
            //记录本地标识，等待完成后取到相册中的图片对象
            [imageIds addObject:req.placeholderForCreatedAsset.localIdentifier];
        }else {
            PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:path]];
            //记录本地标识，等待完成后取到相册中的图片对象
            [imageIds addObject:req.placeholderForCreatedAsset.localIdentifier];
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//        NSLog(@"success = %d, error = %@", success, error);
        if (success)
        {
            //成功后取相册中的图片/视频对象
            PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:imageIds options:nil];
            PHAsset *resultAsset = [result firstObject];
            if (resultAsset)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if (isImage) {
                        
                        if([strongSelf->_dsP containsObject:@"custTextView"]){
                            [strongSelf->_dsP insertObject:resultAsset atIndex:1];
                        }else{
                            [strongSelf->_dsP insertObject:resultAsset atIndex:0];
                        }
                        [strongSelf tapPhotoBtn];
                        [strongSelf->_photoCollection reloadData];
                    }else {
                        if([strongSelf->_dsV containsObject:@"custTextView"]){
                            [strongSelf->_dsV insertObject:resultAsset atIndex:1];
                        }else{
                            [strongSelf->_dsV insertObject:resultAsset atIndex:0];
                        }
                        [strongSelf tapVideoBtn];
                        [strongSelf->_videoCollection reloadData];
                    }
                    
                    [strongSelf->_VideoAndPhotoCollection reloadData];
                });
            }
        }
        unlink([path UTF8String]);
    }];
}

/**进入录制拍摄界面
 */
- (void)enter_RecordVideo:(UIButton *)sender{
    if( _moreContentView )
        _moreContentView.hidden = YES;
    RDRecordViewController *recordVideoVC = [[RDRecordViewController alloc] init];
    recordVideoVC.delegate = self;
    recordVideoVC.captureAsYUV = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.captureAsYUV;
    if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath.length==0){
        NSString * exportPath = [kRDDirectory stringByAppendingPathComponent:@"/recordVideoFile.mp4"];
        ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath = exportPath;
    }
    recordVideoVC.videoPath = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraOutputPath;
    recordVideoVC.fps = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraFrameRate;
    recordVideoVC.recordSize = CGSizeZero;
    recordVideoVC.bitrate = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraBitRate;
    recordVideoVC.cameraPosition = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraCaptureDevicePosition;
    
    if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.enableFaceU
       && ((RDNavigationViewController *)self.navigationController).cameraConfiguration.enableNetFaceUnity
       && ((RDNavigationViewController *)self.navigationController).cameraConfiguration.faceUURL.length>0){
        recordVideoVC.faceUURLString = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.faceUURL;
    }else{
        recordVideoVC.faceUURLString = nil;
    }
    recordVideoVC.faceU = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.enableFaceU;
    recordVideoVC.needFilter = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.enableFilter;
    if(sender.tag == 1) {
        recordVideoVC.recordsizetype = RecordSizeTypeMixed;
        recordVideoVC.recordtype = RecordTypePhoto;
        recordVideoVC.cameraMV = NO;
        recordVideoVC.cameraVideo = NO;
        recordVideoVC.cameraPhoto = YES;
    }else {
        recordVideoVC.recordsizetype =(RecordSizeType)((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraRecordSizeType;
        recordVideoVC.recordtype = RecordTypeVideo;
//        recordVideoVC.recordtype = (RecordType)((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraRecord_Type;
        recordVideoVC.MVRecordMaxDuration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMV_MaxVideoDuration;
        recordVideoVC.MVRecordMinDuration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMV_MinVideoDuration;
        recordVideoVC.cameraMV = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMV;
        recordVideoVC.cameraVideo = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraVideo;
        
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == ONLYSUPPORT_VIDEO){
            recordVideoVC.cameraPhoto = NO;
        }else {
            recordVideoVC.cameraPhoto = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraPhoto;
        }
    }
    recordVideoVC.MAX_VIDEO_DUR_1 = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraSquare_MaxVideoDuration;
    recordVideoVC.MAX_VIDEO_DUR_2 = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraNotSquare_MaxVideoDuration;
    recordVideoVC.more = NO;
    recordVideoVC.isSquareTop = NO;
    
    switch (((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType) {
        case SUPPORT_ALL:
            recordVideoVC.isWriteToAlbum = NO;
            break;
        case ONLYSUPPORT_VIDEO:
            recordVideoVC.cameraPhoto = NO;
            recordVideoVC.isWriteToAlbum = NO;
            break;
        case ONLYSUPPORT_IMAGE:
            recordVideoVC.isWriteToAlbum = NO;
            
            break;
        default:
            break;
    }
    if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraRecordSizeType == RecordVideoTypeMixed){
        if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraSquare_MaxVideoDuration>0){
            ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration = MIN(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration,((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraSquare_MaxVideoDuration);
        }
        
        if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraNotSquare_MaxVideoDuration>0){
            ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration = MIN(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration, ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraNotSquare_MaxVideoDuration);
        }
        recordVideoVC.minRecordDuration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration;
        
    }else{
        if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraRecordSizeType == RecordVideoTypeSquare && ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraSquare_MaxVideoDuration>0){
            
            recordVideoVC.minRecordDuration = MIN(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration, ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraSquare_MaxVideoDuration);
            
        }else if(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraRecordSizeType == RecordVideoTypeNotSquare && ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraNotSquare_MaxVideoDuration>0){
            
            recordVideoVC.minRecordDuration = MIN(((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration, ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraNotSquare_MaxVideoDuration);
        }else{
            recordVideoVC.minRecordDuration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraMinVideoDuration;
        }
    }
    recordVideoVC.hiddenPhotoLib = YES;
    recordVideoVC.recordorientation = (RecordOrientation)((RDNavigationViewController *)self.navigationController).cameraConfiguration.cameraRecordOrientation;
    recordVideoVC.enableUseMusic = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.enableUseMusic;
    if (recordVideoVC.enableUseMusic) {
        recordVideoVC.musicInfo = (RDMusic *)((RDNavigationViewController *)self.navigationController).cameraConfiguration.musicInfo;
    }
    recordVideoVC.push = YES;
    WeakSelf(self);
    recordVideoVC.PhotoPathBlock = ^(NSString * _Nullable path) {
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelf(self);
            if([RDHelpClass freeDiskSpaceInBytes]<sizeof([path UTF8String])){
                
                [strongSelf initCommonAlertViewWithTitle:RDLocalizedString(@"存储空间不足!",nil)
                                           message:RDLocalizedString(@"设备存储空间不足，请到设置中释放空间",nil)
                                 cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                 otherButtonTitles:RDLocalizedString(@"取消",nil)
                                      alertViewTag:0];
            }else {
                [strongSelf saveToPhotoLibrary:path isImage:YES];
            }
        });
    };
    [recordVideoVC addFinishBlock:^(NSString * _Nullable videoPath, int type,RDMusic *music) {
        [weakSelf saveToPhotoLibrary:videoPath isImage:NO];
    }];
//    self.navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    [self.navigationController pushViewController:recordVideoVC animated:YES];
    
    recordVideoVC.push = false;
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:recordVideoVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //2019.10.21 修改 片段编辑跳转
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)initCommonAlertViewWithTitle:(nullable NSString *)title
                             message:(nullable NSString *)message
                   cancelButtonTitle:(nullable NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSString *)otherButtonTitles
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

#pragma mark- alertViewdalegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag !=1){
        if (buttonIndex == 0) {
            [RDHelpClass enterSystemSetting];
        }
    }
}

#pragma mark- 点击事件
/**点击选择视频
 */
- (void)tapVideoBtn{
    if (!_videoCollection) {
        [self initVideoCollection];
    }
    if( _moreContentView )
        _moreContentView.hidden = YES;
    [self setCameraRollBtn:allAlbumVideoArray[_dsVNumber].title];
    
    _collectionScrollView.contentOffset = CGPointMake(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL ? _collectionScrollView.frame.size.width : 0, 0);
//    _collectionScrollView.contentOffset = CGPointMake(0, 0);
    _selectVideoBtn.selected = YES;
    _selectPhotoBtn.selected = NO;
    _selectPhotoAndVideoBtn.selected = NO;
    
    _selectVideoLabel.backgroundColor = Main_Color;
    _selectPhotoLabel.backgroundColor = [UIColor clearColor];
    _selectPhotoAndVideoLabel.backgroundColor = [UIColor clearColor];
    if(_moreContentView.alpha == 1.0){
        [self enter_paisheOrRecoderVide];
    }
    
}
/**点击选择图片
 */
- (void)tapPhotoBtn{
    if (!_photoCollection) {
        [self initPhotoCollection];
    }
    if( _moreContentView )
        _moreContentView.hidden = YES;
    [self setCameraRollBtn:allAlbumPhotoArray[_dsPNumber].title];
    
    _collectionScrollView.contentOffset = CGPointMake(((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType == SUPPORT_ALL ? _collectionScrollView.frame.size.width*2.0 : 0, 0);
    
    _selectPhotoBtn.selected = YES;
    _selectVideoBtn.selected = NO;
    _selectPhotoAndVideoBtn.selected = NO;
    
    _selectVideoLabel.backgroundColor = [UIColor clearColor];
    _selectPhotoLabel.backgroundColor = Main_Color;
    _selectPhotoAndVideoLabel.backgroundColor = [UIColor clearColor];
    
    if(_moreContentView.alpha == 1.0){
        [self enter_paisheOrRecoderVide];
    }
}
/**点击相册胶卷
*/
-(void)tapCameraRollBtn
{
    if( _moreContentView )
        _moreContentView.hidden = YES;
    [_cameraRollBtn.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass:[UIImageView class]] )
        {
            UIImageView * imageView = (UIImageView*)obj;
            imageView.image = nil;
            imageView.image = [RDHelpClass imageWithContentOfFile:@"album/相册-箭头上"];
        }
    }];
    
    int index = 0;
    
    if( _selectVideoBtn.selected )
    {
        index = 1;
    }
    else if( _selectPhotoBtn.selected )
    {
        index = 2;
    }
    
    [self initAlbumCategeryView:index];
    
//    RDOtherAlbumsViewController *otherAlbumsVC = [[RDOtherAlbumsViewController alloc] init];
//    if (_selectVideoBtn.selected) {
//        otherAlbumsVC.supportFileType = ONLYSUPPORT_VIDEO;
//    }else if (_selectPhotoBtn.selected) {
//        otherAlbumsVC.supportFileType = ONLYSUPPORT_IMAGE;
//    }
//    else if (_selectPhotoAndVideoBtn.selected) {
//        otherAlbumsVC.supportFileType = SUPPORT_ALL;
//    }
//
//    WeakSelf(self);
//    otherAlbumsVC.finishBlock_main = ^(PHAsset *asset, UIImage *thumbImage, BOOL isImage) {
//        StrongSelf(self);
//
//        if(asset.duration)
//        {
//            [self videoCell:asset atSelectCell:nil isEdit:NO];
//        }
//        else
//        {
//            [self phtoCell:asset atSelectCell:nil isEdit:NO];
//        }
//
//    };
//    [self.navigationController pushViewController:otherAlbumsVC animated:YES];
}

/**点击选择全部
 */
- (void)tapPhotoAndVideBtn{
    if( _moreContentView )
    _moreContentView.hidden = YES;
    [self setCameraRollBtn:allAlbumVideoAndPhotoArray[_dsPAndVNumber].title];
    
    _collectionScrollView.contentOffset = CGPointMake( 0.0, 0);
    
    _selectPhotoBtn.selected = NO;
    _selectVideoBtn.selected = NO;
    _selectPhotoAndVideoBtn.selected = YES;
    
    _selectVideoLabel.backgroundColor = [UIColor clearColor];
    _selectPhotoLabel.backgroundColor = [UIColor clearColor];
    _selectPhotoAndVideoLabel.backgroundColor = Main_Color;
    
    if(_moreContentView.alpha == 1.0){
        [self enter_paisheOrRecoderVide];
    }
}


/**点击返回按钮
 */
- (void)tapBackBtn{
    
    NSLog(@"%s",__func__);
    
    __weak typeof(self) myself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if(myself.cancelBlock){
            myself.cancelBlock();
        }
    }];
}
/**点击完成按钮
 */
- (void)tapSelectOkBtn{
    _paizhaoOrLuxiang = NO;
    if(selectedFileArray.count == 0){
        
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示", nil)
                                   message:RDLocalizedString(@"您还未选择视频或图片哦!", nil)
                         cancelButtonTitle:RDLocalizedString(@"我知道了", nil)
                         otherButtonTitles:nil
                              alertViewTag:1];
        return;
    }
    _selectOkBtn.enabled = NO;
    [self performSelector:@selector(selectFinish) withObject:self afterDelay:0.2];
}

- (void)cancelDownLoad
{
    
}

/**选择完毕
 */
- (void)selectFinish{
    NSMutableArray *fileArray = [NSMutableArray array];
    [selectedFileArray enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( (obj.fileType == kFILEVIDEO) || obj.isGif )
            obj.filtImagePatch = [RDHelpClass getMaterialThumbnail:obj.contentURL];
        [fileArray addObject:obj.contentURL];
    }];
    
    [self initProgressHUD:RDLocalizedString(@"正在导入中...", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [RDHelpClass fileImage_Save:selectedFileArray atProgress:^(float progress) {
            [self myProgressTask:progress];
        } atReturn:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_onAlbumCallbackBlock){
                
                [[UIApplication sharedApplication] setStatusBarHidden:((RDNavigationViewController *)self.navigationController).statusBarHidden];
                
                [self dismissViewControllerAnimated:YES completion:^{
                    _onAlbumCallbackBlock(fileArray);
                }];
            }
            else if(_selectFinishActionBlock){
                _selectFinishActionBlock(selectedFileArray);
                [self dismissViewControllerAnimated:YES completion:nil];
                
            }else{
                [self enterNext];
            }
        });
    });
        
//    if(_onAlbumCallbackBlock){
//
//        [[UIApplication sharedApplication] setStatusBarHidden:((RDNavigationViewController *)self.navigationController).statusBarHidden];
//
//        [self dismissViewControllerAnimated:YES completion:^{
//            _onAlbumCallbackBlock(fileArray);
//        }];
//    }
//    else if(_selectFinishActionBlock){
//        _selectFinishActionBlock(selectedFileArray);
//        [self dismissViewControllerAnimated:YES completion:nil];
//
//    }else{
//        [self enterNext];
//    }
}


/**进入编辑界面
 */
- (void)enterNext{
    if(_editConfig.enableWizard){
        RDEditVideoViewController *editVideoVC = [[RDEditVideoViewController alloc] init];
//        [selectedFileArray enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//
//            if( (obj.isGif) || (obj.fileType == kFILEVIDEO) )
//            {
//                obj.filtImagePatch = [RDHelpClass getMaterialThumbnail:obj.contentURL];
//            }
//        }];
//
        editVideoVC.fileList = [selectedFileArray mutableCopy];
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//            [RDHelpClass fileImage_Save:editVideoVC.fileList];
//
//        });
        
        editVideoVC.isVague = YES;
        editVideoVC.musicVolume = 0.5;
        editVideoVC.push = YES;
        [self deallocView];
        [self deallocArray];
        [self.navigationController pushViewController:editVideoVC animated:YES];
        
    }else{
        RDNextEditVideoViewController *nextEditVideoVC = [[RDNextEditVideoViewController alloc] init];
//        TICK;
        
//        TOCK;
//        [selectedFileArray enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//
//            if( (obj.isGif) || (obj.fileType == kFILEVIDEO) )
//            {
//                obj.filtImagePatch = [RDHelpClass getMaterialThumbnail:obj.contentURL];
//            }
//        }];
////        TOCK;
//
        nextEditVideoVC.fileList        = [selectedFileArray mutableCopy];
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//            [RDHelpClass fileImage_Save:nextEditVideoVC.fileList];
//
//        });
        
        nextEditVideoVC.musicVolume     = 0.5;
       
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.proportionType == RDPROPORTIONTYPE_LANDSCAPE){
            nextEditVideoVC.exportVideoSize       = CGSizeMake(MAX(kVIDEOWIDTH, kVIDEOHEIGHT), MIN(kVIDEOWIDTH, kVIDEOHEIGHT));
        }
        else if(((RDNavigationViewController *)self.navigationController).editConfiguration.proportionType == RDPROPORTIONTYPE_SQUARE){
            nextEditVideoVC.exportVideoSize       = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        }else{
            nextEditVideoVC.exportVideoSize       = CGSizeZero;
        }
//        TOCK;
        self.navigationController.navigationBarHidden = YES;
        [self deallocView];
        [self deallocArray];
        [self.navigationController pushViewController:nextEditVideoVC animated:YES];
//        TOCK;
    }
}

#pragma mark- RDRecordViewDelegate
/**改变需要播放的音乐
 */
- (void)changeMusicResult:(UINavigationController *)nav CompletionHandler:(void (^)(RDMusic * _Nullable))handler{
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL) {
        RDCloudMusicViewController  *cloudMusic = [[RDCloudMusicViewController alloc] init];
        cloudMusic.selectedIndex = 0;
        cloudMusic.cloudMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL;
        cloudMusic.selectCloudMusic = ^(RDMusic *music) {
            handler(music);
        };
        [nav pushViewController:cloudMusic animated:YES];
    }else{
        RDLocalMusicViewController *localmusic = [[RDLocalMusicViewController alloc] init];
        localmusic.selectLocalMusicBlock = ^(RDMusic *music){
            handler(music);
        };
        [nav pushViewController:localmusic animated:YES];
    }
}

#pragma mark- UIScrollViewDelegate/UIScrollViewDataSource
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    __block typeof(self) bself = self;
    if(_moreContentView.alpha != 0){
        [UIView animateWithDuration:0.25 animations:^{
            bself->_moreContentView.frame = CGRectMake(bself->_moreContentView.frame.origin.x, bself->_moreContentView.frame.origin.y + 41, bself->_moreContentView.frame.size.width, 0);
        } completion:^(BOOL finished) {
            bself->_moreContentView.alpha = 0;
        }];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if(scrollView == _collectionScrollView){
        SUPPORTFILETYPE supportFileType = ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType;
        if(supportFileType == SUPPORT_ALL)
        {
            if (scrollView.contentOffset.x == 0) {
                [self tapPhotoAndVideBtn];
            }else if(scrollView.contentOffset.x == scrollView.frame.size.width) {
                [self tapVideoBtn];
            }else if( scrollView.contentOffset.x == (scrollView.frame.size.width*2.0) ){
                [self tapPhotoBtn];
            }else if (scrollView.contentOffset.x > 0 && scrollView.contentOffset.x < scrollView.frame.size.width) {
                if (!_videoCollection) {
                    [self initVideoCollection];
                }
            }else if (!_photoCollection) {
                [self initPhotoCollection];
            }
        }
    }
}
- (void)changecountLabel{
    
    __block NSInteger pCount =0;
    __block NSInteger vCount = 0;
    
    [selectedFileArray enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.fileType == kFILEIMAGE) {
            pCount++;
        }else {
            vCount++;
        }
    }];
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    if (_videoCountLimit > 0 || _picCountLimit > 0) {
        if(editConfig.supportFileType == ONLYSUPPORT_VIDEO){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%ld/%d ",RDLocalizedString(@"视频", nil),(unsigned long)vCount, _videoCountLimit];
        }else if(editConfig.supportFileType == ONLYSUPPORT_IMAGE){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%ld/%d",RDLocalizedString(@"图片", nil),(unsigned long)pCount, _picCountLimit];
        }else{
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%ld/%d , %@:%ld/%d",RDLocalizedString(@"视频", nil),(unsigned long)vCount, _videoCountLimit,RDLocalizedString(@"图片", nil),(unsigned long)pCount, _picCountLimit];
        }
    }else if (_minCountLimit > 0) {
        if(editConfig.supportFileType == ONLYSUPPORT_VIDEO){
            _selectCountLabel.text = [NSString stringWithFormat:RDLocalizedString(@"视频(至少%d个):%d", nil), _minCountLimit, (unsigned long)vCount];
        }else if(editConfig.supportFileType == ONLYSUPPORT_IMAGE){
            _selectCountLabel.text = [NSString stringWithFormat:RDLocalizedString(@"图片(至少%d张):%d", nil), _minCountLimit, (unsigned long)pCount];
        }else{
            _selectCountLabel.text = [NSString stringWithFormat:RDLocalizedString(@"素材(至少%d个):%d", nil), _minCountLimit, (unsigned long)(vCount+pCount)];
        }
    }else {
        if(editConfig.supportFileType == ONLYSUPPORT_VIDEO){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%ld ",RDLocalizedString(@"视频", nil),(unsigned long)vCount];
        }else if(editConfig.supportFileType == ONLYSUPPORT_IMAGE){
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%ld",RDLocalizedString(@"图片", nil),(unsigned long)pCount];
        }else{
            _selectCountLabel.text = [NSString stringWithFormat:@"%@:%ld , %@:%ld",RDLocalizedString(@"视频", nil),(unsigned long)vCount,RDLocalizedString(@"图片", nil),(unsigned long)pCount];
        }
    }
    NSInteger allCount = pCount + vCount;
    if (pCount == 0 && vCount == 0) {
        _selectOkBtn.enabled = NO;
        tipLbl.hidden = NO;
    }else if (_minCountLimit > 0 && allCount < _minCountLimit) {
        _selectOkBtn.enabled = NO;
        tipLbl.hidden = NO;
    }
    else {
        _selectOkBtn.enabled = YES;
        tipLbl.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

#pragma mark- 图片缩放
/** 缩放图片
 */
- (UIImage *)doubleSizeImage:(UIImage *)image  flag:(BOOL)flag{
    CGSize newSize = CGSizeMake(image.size.width, image.size.height);
    
    if( flag){
        if(image.size.width>image.size.height){
            if(newSize.width>=320){
                float scale = 320/(float)newSize.width;
                newSize = CGSizeMake(floor(newSize.width*scale), floor(newSize.height*scale));
            }
            
        }else{
            if(newSize.height>=320){
                float scale = 320/(float)newSize.width;
                newSize = CGSizeMake(floor(newSize.width*scale), floor(newSize.height*scale));
            }
        }
    }else{
        if(image.size.width>image.size.height){
            if(newSize.width>=854){
                float scale = 854/(float)newSize.width;
                newSize = CGSizeMake(floor(newSize.width*scale), floor(newSize.height*scale));
            }
            
        }else{
            if(newSize.height>=854){
                float scale = 854/(float)newSize.width;
                newSize = CGSizeMake(floor(newSize.width*scale), floor(newSize.height*scale));
            }
        }
    }
    
    UIGraphicsBeginImageContext(newSize);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = nil;
    return newImage;
}
/**  图片缩放
 *
 *  @param image   原始图片
 *  @param newSize 缩放后的大小
 *
 *  @return 缩放后的图片
 */
- (UIImage *)thumbSizeImage:(UIImage *)image size:(CGSize )newSize{
    UIGraphicsBeginImageContext(newSize);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark- UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    [RDSVProgressHUD dismiss];
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if(collectionView == _videoCollection){
        return _dsV.count;
    }
    else if( collectionView == _photoCollection ){
        return _dsP.count;
    }
    else if( collectionView == _VideoAndPhotoCollection )
    {
        return _dspAndV.count;
    }
    else
        return 0;
}

// the image view inside the collection view cell prototype is tagged with "1"
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"photocell";
    //缩率图的大小这个地方数值不能设置大了
    float thumbWidth = 80;//(kWIDTH/4.0 - 0.5*3) * [UIScreen mainScreen].scale;
    LocalPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if(!cell){
        NSLog(@"collectionViewCell is nil");
        cell = [[LocalPhotoCell alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        
    }
    cell.delegate = self;
    cell.duration.text = @"";
    cell.videoMark.alpha = 0;
    
    PHAsset *asset;
    //视频集
    if(collectionView == _videoCollection){
        if([_dsV containsObject:@"custTextView"] && indexPath.row == 0){
            cell.ivImageView.image = [RDHelpClass imageWithContentOfFile:@"选择视频图片_文字板_"];
            cell.videoMark.alpha = 0;
            cell.videoMark.hidden = YES;
            cell.durationBlack.hidden = YES;
            cell.addBtn.hidden = YES;
        }
        else if([_dsV[indexPath.row] isKindOfClass:[NSDictionary class]]){
            
            cell.isPhoto = NO;
            
            NSDictionary *dic = _dsV[indexPath.row];
            UIImage *thumbImage = [dic objectForKey:@"thumbImage"];
            cell.durationBlack.hidden = NO;
            cell.duration.hidden = NO;
            double duration = CMTimeGetSeconds([[dic objectForKey:@"durationTime"] CMTimeValue]);
            cell.duration.text = [RDHelpClass timeToStringFormat_MinSecond:ceilf(duration)];
            [cell.ivImageView setImage:thumbImage];
        }
        else if([_dsV[indexPath.row] isKindOfClass:[PHAsset class]]){
            
            cell.isPhoto = NO;
            
            asset=_dsV[indexPath.row];
            cell.durationBlack.hidden = NO;
            cell.duration.hidden = NO;
            double duration = asset.duration;
            cell.duration.text = [RDHelpClass timeToStringFormat_MinSecond:ceilf(duration)];
            if([[RD_ImageManager manager] isICloudnoDownLoad:asset]){
                cell.icloudIcon.hidden = NO;
            }else{
                cell.icloudIcon.hidden = YES;
            }
            [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                    cell.ivImageView.userInteractionEnabled = YES;
                    [cell.ivImageView setImage:photo];
                    cell.addBtn.hidden = NO;
                    cell.userInteractionEnabled = YES;
                }
            }];
        }
        return cell;
    }
    
    //图片集
    else if(  collectionView == _photoCollection ){
        if([_dsP containsObject:@"custTextView"] && indexPath.row == 0){
            cell.ivImageView.image = [RDHelpClass imageWithContentOfFile:@"选择视频图片_文字板_"];
            cell.videoMark.alpha = 0;
            cell.videoMark.hidden = YES;
            cell.durationBlack.hidden = YES;
            cell.addBtn.hidden = YES;
        }else if(indexPath.row < _dsP.count){
            
            cell.isPhoto = YES;
            
            asset=_dsP[indexPath.row];
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
                    cell.addBtn.hidden = NO;
                    cell.userInteractionEnabled = YES;
                }
            }];
        }
        return cell;
    }
    else   {
        cell.isAll = true;
        
        if([_dspAndV containsObject:@"custTextView"] && indexPath.row == 0){
            cell.ivImageView.image = [RDHelpClass imageWithContentOfFile:@"选择视频图片_文字板_"];
            cell.videoMark.alpha = 0;
            cell.videoMark.hidden = YES;
            cell.durationBlack.hidden = YES;
            cell.addBtn.hidden = YES;
        }
        else if([_dspAndV[indexPath.row] isKindOfClass:[NSDictionary class]]){
            
            cell.isPhoto = NO;
            
            NSDictionary *dic = _dspAndV[indexPath.row];
            UIImage *thumbImage = [dic objectForKey:@"thumbImage"];
            cell.durationBlack.hidden = NO;
            cell.duration.hidden = NO;
            double duration = CMTimeGetSeconds([[dic objectForKey:@"durationTime"] CMTimeValue]);
            cell.duration.text = [RDHelpClass timeToStringFormat_MinSecond:ceilf(duration)];
            [cell.ivImageView setImage:thumbImage];
        }
        else if([_dspAndV[indexPath.row] isKindOfClass:[PHAsset class]]){
            
            asset=_dspAndV[indexPath.row];
            
            if( asset.duration > 0 )
            {
                cell.isPhoto = NO;
                
                cell.durationBlack.hidden = NO;
                cell.duration.hidden = NO;
                double duration = asset.duration;
                cell.duration.text = [RDHelpClass timeToStringFormat_MinSecond:ceilf(duration)];
                if([[RD_ImageManager manager] isICloudnoDownLoad:asset]){
                    cell.icloudIcon.hidden = NO;
                }else{
                    cell.icloudIcon.hidden = YES;
                }
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                        cell.ivImageView.userInteractionEnabled = YES;
                        [cell.ivImageView setImage:photo];
                        cell.addBtn.hidden = NO;
                        cell.userInteractionEnabled = YES;
                    }
                }];
            }
            else{
                
                cell.isPhoto = YES;
                
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
                        cell.addBtn.hidden = NO;
                        cell.userInteractionEnabled = YES;
                    }
                }];
            }
        }
        return cell;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(!_moreContentView.superview){
        [_moreContentView removeFromSuperview];
    }
    
    LocalPhotoCell *cell=(LocalPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.videoMark.hidden = YES;
    if(([_dsP containsObject:@"custTextView"] || [_dsV containsObject:@"custTextView"] || [_dspAndV containsObject:@"custTextView"]) && indexPath.row == 0){
        if (_picCountLimit > 0 && selectedPicCount == _picCountLimit) {
            [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"选择图片数不能超过%d个", nil),_picCountLimit]];
            [_hud show];
            [_hud hideAfter:2];
            return;
        }
        //选中添加文字板
        CustomTextPhotoViewController *cusTextview;
        cusTextview = [[CustomTextPhotoViewController alloc] init];
        cusTextview.videoProportion = _textPhotoProportion > 0 ? _textPhotoProportion : (16/9.0);
        cusTextview.delegate = self;
        cusTextview.touchUpType = 0;
        
        RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cusTextview];
        [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
        [self presentViewController:nav animated:YES completion:nil];
    }else{
        
        //2019 12 11 修改 原 ： [self selectCell:cell isEdit:YES];
        [self selectCell:cell isEdit:NO];
    }
}

#pragma mark - LocalPhotoCellDelegate
- (void)addVideo:(LocalPhotoCell *)cell {
    //2019 12 11 修改 原 ：[self selectCell:cell isEdit:NO];
    if (_onAlbumCallbackBlock || _isDisableEdit) {
        return;
    }
    [self selectCell:cell isEdit:YES];
}

#pragma mark- 照片 PHAsset 转 RDFile
-(void)phtoCell:(PHAsset *) resource atSelectCell:(LocalPhotoCell *)cell isEdit:(BOOL)isEdit
{
    RDFile *file = [RDFile new];
    WeakSelf(self);
    PHImageRequestOptions  *opt_s = [[PHImageRequestOptions alloc] init]; // assets的配置设置
    opt_s.version = PHVideoRequestOptionsVersionCurrent;
    opt_s.networkAccessAllowed = NO;
    opt_s.resizeMode = PHImageRequestOptionsResizeModeExact;
    [[PHImageManager defaultManager] requestImageDataForAsset:resource options:opt_s resultHandler:^(NSData * _Nullable imageData_l, NSString * _Nullable dataUTI_l, UIImageOrientation orientation_l, NSDictionary * _Nullable info_l) {
        StrongSelf(self);
        if(imageData_l){
            if( cell )
                cell.isDownloadingInLocal = NO;
            BOOL isSelected = NO;
            if (isEdit) {
                if([[info_l allKeys] containsObject:@"PHImageFileURLKey"] || [[info_l allKeys] containsObject:@"PHImageFileUTIKey"]){
                    isSelected = YES;
                }
            }else if (![info_l[@"PHImageResultIsDegradedKey"] boolValue]) {
                isSelected = YES;
            }
            if(isSelected){
                NSURL *url = info_l[@"PHImageFileURLKey"];
                if (!url) {
                    url = info_l[@"PHImageFileUTIKey"];
                }
                NSString *localID = resource.localIdentifier;
                NSArray *temp = [localID componentsSeparatedByString:@"/"];
                NSString *uploadVideoFilePath = nil;
                if (temp.count > 0) {
                    NSString *assetID = temp[0];
                    NSString *ext = url.pathExtension;
                    if (assetID && ext) {
                        uploadVideoFilePath = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", ext, assetID, ext];
                    }
                }
                NSURL *asseturl = [NSURL URLWithString:uploadVideoFilePath];
                float imageDuration = [RDVECore isGifWithData:imageData_l];
                if (imageDuration > 0) {
                    file.isGif = YES;
                    file.imageDurationTime = CMTimeMakeWithSeconds(imageDuration, TIMESCALE);
                    file.speedIndex = 2;
                    file.gifData = imageData_l;
                }else {
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                }
                if( cell )
                {
                    cell.isDownloadingInLocal = NO;
                    cell.icloudIcon.hidden = YES;
                }
                file.contentURL = asseturl;
                file.fileType = kFILEIMAGE;
                file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                if (!CGSizeEqualToSize(_inVideoSize, CGSizeZero)) {
                    file.fileCropModeType = kCropTypeFixedRatio;
                }
                if (isEdit) {
                    [strongSelf editFile:file];
                }else {
                    [strongSelf->selectedFileArray addObject:file];
                    strongSelf->selectedPicCount++;
                    
                    CGPoint offset = strongSelf->selectedFilesScrollView.contentOffset;
                    
                    strongSelf->selectedFilesScrollView.contentSize = CGSizeMake(strongSelf->selectedFileArray.count * (strongSelf->thumbWidth ), 0);
                    
                    RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height)];
                    thumbView.isAlbum = TRUE;
                    thumbView.frame = CGRectMake((strongSelf->thumbWidth )*(strongSelf->selectedFileArray.count - 1), 0, strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height);
                    thumbView.home = thumbView.frame;
                    thumbView.thumbIconView.image = file.thumbImage;
                    if (file.isGif) {
                        thumbView.thumbDurationlabel.text = [RDHelpClass timeFormat:imageDuration];
                    }else {
                        thumbView.thumbDurationlabel.hidden = YES;
                    }
                    thumbView.thumbId = strongSelf->selectedFileArray.count - 1;
                    thumbView.contentFile = file;
                    thumbView.delegate = strongSelf;
                    [strongSelf->selectedFilesScrollView addSubview:thumbView];
                    if( (thumbView.frame.origin.x+thumbView.frame.size.width) > strongSelf->selectedFilesScrollView.bounds.size.width )
                    {
                        offset = CGPointMake((thumbView.frame.origin.x+thumbView.frame.size.width) - strongSelf->selectedFilesScrollView.bounds.size.width, offset.y);
                    }
                    [strongSelf->selectedFilesScrollView setContentOffset:offset];
                    [strongSelf changecountLabel];
                    
                    if(strongSelf->_mediaCountLimit == 1){
                        [strongSelf selectFinish];
                    }
                }
            }
        }else{
            [strongSelf->_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"Photos are syncing from iCloud, please retry later", nil),strongSelf->_mediaCountLimit]];
            [strongSelf->_hud show];
            [strongSelf->_hud hideAfter:1];
        }
        if( cell )
        {
            if(cell.isDownloadingInLocal){
                return;
            }
        }
        PHImageRequestOptions  *opts = [[PHImageRequestOptions alloc] init]; // assets的配置设置
        opts.version = PHVideoRequestOptionsVersionCurrent;
        opts.networkAccessAllowed = YES;
        opts.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if( cell )
                cell.progressView.percent = progress;
        };
        [[PHImageManager defaultManager] requestImageDataForAsset:resource options:opts resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            if(![info[@"PHImageResultIsDegradedKey"] boolValue]){
                if( cell )
                {
                    cell.isDownloadingInLocal = NO;
                    cell.icloudIcon.hidden = YES;
                    [cell.progressView setPercent:0];
                }
            }
        }];
    }];
}
#pragma mark- 视频 PHAsset 转 RDFile
-(void)videoCell:(PHAsset *) resource atSelectCell:(LocalPhotoCell *)cell isEdit:(BOOL)isEdit
{
    WeakSelf(self);
    RDFile *file = [RDFile new];
    PHVideoRequestOptions *opt_s = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
    opt_s.version = PHVideoRequestOptionsVersionOriginal;
    opt_s.networkAccessAllowed = NO;
    [[PHImageManager defaultManager] requestAVAssetForVideo:resource options:opt_s resultHandler:^(AVAsset * _Nullable asset_l, AVAudioMix * _Nullable audioMix_l, NSDictionary * _Nullable info_l) {
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelf(self);
            if(asset_l){
                cell.isDownloadingInLocal = NO;
                NSURL *fileUrl = [asset_l valueForKey:@"URL"];
                //                        NSLog(@"%@", fileUrl);
                NSString *localID = resource.localIdentifier;
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
                file.contentURL = asseturl;
                if( cell )
                {
                    cell.isDownloadingInLocal = NO;
                    cell.icloudIcon.hidden = YES;
                    [cell.progressView setPercent:0];
                }
                file.fileType = kFILEVIDEO;
                file.isReverse = NO;
                if(!asseturl) {
                    file.videoDurationTime = CMTimeMakeWithSeconds(resource.duration, TIMESCALE);
                }
                file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                file.reverseVideoTimeRange = file.videoTimeRange;
                file.videoTrimTimeRange = kCMTimeRangeInvalid;
                file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
                file.videoVolume = 1.0;
                file.speedIndex = 2;
                file.rotate = 0;
                
                file.isVerticalMirror = NO;
                file.isHorizontalMirror = NO;
                file.speed = 1;
                file.crop = CGRectMake(0, 0, 1, 1);
                file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                if (isEdit) {
                    [strongSelf editFile:file];
                }else {
                    [strongSelf->selectedFileArray addObject:file];
                    strongSelf->selectedVideoCount++;
                    
                    CGPoint offset = strongSelf->selectedFilesScrollView.contentOffset;
                    
                    strongSelf->selectedFilesScrollView.contentSize = CGSizeMake(strongSelf->selectedFileArray.count * (strongSelf->thumbWidth ), 0);
                    
                    RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height)];
                    thumbView.frame = CGRectMake((strongSelf->thumbWidth )*(strongSelf->selectedFileArray.count - 1), 0, strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height);
                    thumbView.home = thumbView.frame;
                    thumbView.isAlbum = TRUE;
                    thumbView.thumbIconView.image = file.thumbImage;
                    thumbView.thumbDurationlabel.text = [RDHelpClass timeFormat:CMTimeGetSeconds(file.videoTimeRange.duration)];
                    thumbView.thumbId = strongSelf->selectedFileArray.count - 1;
                    thumbView.contentFile = file;
                    thumbView.delegate = strongSelf;
                    [strongSelf->selectedFilesScrollView addSubview:thumbView];
                    
                    if( (thumbView.frame.origin.x+thumbView.frame.size.width) > strongSelf->selectedFilesScrollView.bounds.size.width )
                    {
                        offset = CGPointMake((thumbView.frame.origin.x+thumbView.frame.size.width) - strongSelf->selectedFilesScrollView.bounds.size.width, offset.y);
                    }
                    
                    [strongSelf->selectedFilesScrollView setContentOffset:offset];
                    [strongSelf changecountLabel];
                    
                    if(strongSelf->_mediaCountLimit == 1){
                        [strongSelf selectFinish];
                    }
                }
                return;
            }
            if( cell )
            {
                if(cell.isDownloadingInLocal){
                    return;
                }
                cell.isDownloadingInLocal = YES;
            }
            [strongSelf->_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"Videos are syncing from iCloud, please retry later", nil),strongSelf->_mediaCountLimit]];
            [strongSelf->_hud show];
            [strongSelf->_hud hideAfter:1];
            
            PHVideoRequestOptions *opts = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
            opts.version = PHVideoRequestOptionsVersionOriginal;
            opts.networkAccessAllowed = YES;
            opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                if( cell )
                    cell.progressView.percent = progress;
            };
            [[PHImageManager defaultManager] requestAVAssetForVideo:resource options:opts resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                if( cell )
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.isDownloadingInLocal = NO;
                        cell.icloudIcon.hidden = YES;
                        [cell.progressView setPercent:0];
                    });
                }
            }];
        });
    }];
}
#pragma mark- 视频 AVURLAsset 转 RDFile
-(void)videoAVURLAsset:(AVURLAsset *) resultAsset atSelectCell:(LocalPhotoCell *)cell isEdit:(BOOL)isEdit
{
    WeakSelf(self);
    StrongSelf(self);
    RDFile *file = [RDFile new];
    NSURL *url;
    url = resultAsset.URL;
    cell.icloudIcon.hidden = YES;
    [cell.progressView setPercent:0];
    file.contentURL = url;
    file.fileType = kFILEVIDEO;
    file.isReverse = NO;
    if(!url){
        file.videoDurationTime = resultAsset.duration;
    }
    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
    file.reverseVideoTimeRange = file.videoTimeRange;
    file.videoTrimTimeRange = kCMTimeRangeInvalid;
    file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
    file.videoVolume = 1.0;
    file.speedIndex = 2;
    file.rotate = 0;
    resultAsset = nil;
    
    file.isVerticalMirror = NO;
    file.isHorizontalMirror = NO;
    file.speed = 1;
    file.crop = CGRectMake(0, 0, 1, 1);
    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    if (isEdit) {
        [strongSelf editFile:file];
    }else {
        [strongSelf->selectedFileArray addObject:file];
        selectedVideoCount++;
        
        CGPoint offset = strongSelf->selectedFilesScrollView.contentOffset;
        
        strongSelf->selectedFilesScrollView.contentSize = CGSizeMake(selectedFileArray.count * (thumbWidth ), 0);
        
        RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height)];
        thumbView.frame = CGRectMake((strongSelf->thumbWidth )*(strongSelf->selectedFileArray.count - 1), 0, strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height);
        thumbView.isAlbum = TRUE;
        thumbView.home = thumbView.frame;
        thumbView.thumbIconView.image = file.thumbImage;
        thumbView.thumbDurationlabel.text = [RDHelpClass timeFormat:CMTimeGetSeconds(file.videoTimeRange.duration)];
        thumbView.thumbId = strongSelf->selectedFileArray.count - 1;
        thumbView.contentFile = file;
        thumbView.delegate = strongSelf;
        [strongSelf->selectedFilesScrollView addSubview:thumbView];
        if( (thumbView.frame.origin.x+thumbView.frame.size.width) > strongSelf->selectedFilesScrollView.bounds.size.width )
        {
            offset = CGPointMake((thumbView.frame.origin.x+thumbView.frame.size.width) - strongSelf->selectedFilesScrollView.bounds.size.width, offset.y);
        }
        [strongSelf->selectedFilesScrollView setContentOffset:offset];
        [strongSelf changecountLabel];
        
        if(strongSelf->_mediaCountLimit == 1){
            [strongSelf selectFinish];
        }
    }
}
#pragma mark - 选中的照片和视频的处理
- (void)selectCell:(LocalPhotoCell *)cell isEdit:(BOOL)isEdit {
    if( _moreContentView )
        _moreContentView.hidden = YES;
    
    if (cell.durationBlack.hidden) {//图片
        if (_picCountLimit > 0 && selectedPicCount == _picCountLimit) {
            if (_videoCountLimit == _picCountLimit) {//视频和图片共可选择_picCountLimit个的情况
                [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"单次选择媒体数不能超过%d个", nil),_picCountLimit]];
            }else {
                [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"选择图片数不能超过%d个", nil),_picCountLimit]];
            }
            [_hud show];
            [_hud hideAfter:2];
            return;
        }
    }else if (_videoCountLimit > 0 && selectedVideoCount == _videoCountLimit) {
        if (_videoCountLimit == _picCountLimit) {
            [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"单次选择媒体数不能超过%d个", nil),_picCountLimit]];
        }else {
            [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"选择视频数不能超过%d个", nil),_videoCountLimit]];
        }
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    if (_mediaCountLimit > 0 && selectedFileArray.count == _mediaCountLimit) {
        [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"单次选择媒体数不能超过%d个", nil),_mediaCountLimit]];
        [_hud show];
        [_hud hideAfter:2];
        return;
    }
    WeakSelf(self);
    RDFile *file = [RDFile new];
    
    if( !isEdit )
        [cell setSelectedAnimation:selectedFileArray.count+1];
    
    if( cell.isAll )
    {
        NSInteger index = [_VideoAndPhotoCollection indexPathForCell:cell].row;
        
        if([_dspAndV[index] isKindOfClass:[NSMutableDictionary class]]){
            StrongSelf(self);
            AVURLAsset *resultAsset = [_dspAndV[index] objectForKey:@"urlAsset"];
            [self videoAVURLAsset:resultAsset atSelectCell:cell isEdit:isEdit];
        }
        else{
            PHAsset *resource = _dspAndV[index];
            if( resource.duration )
            {
                [self videoCell:resource atSelectCell:cell isEdit:isEdit];
            }
            else
            {
                [self phtoCell:resource atSelectCell:cell isEdit:isEdit];
            }
        }
        
    }
    else if (cell.durationBlack.hidden) {//图片
        NSInteger index = [_photoCollection indexPathForCell:cell].row;
        PHAsset *resource = _dsP[index];
        [self phtoCell:resource atSelectCell:cell isEdit:isEdit];
    }else {
        NSInteger index = [_videoCollection indexPathForCell:cell].row;
        NSURL *url;
        if([_dsV[index] isKindOfClass:[NSMutableDictionary class]]){
            AVURLAsset *resultAsset = [_dsV[index] objectForKey:@"urlAsset"];
            [self videoAVURLAsset:resultAsset atSelectCell:cell isEdit:isEdit];
        }else{
            PHAsset *resource = (PHAsset *)_dsV[index];
            [self videoCell:resource atSelectCell:cell isEdit:isEdit];
        }
    }
}

#pragma mark - 编辑视频/图片
- (void)editFile:(RDFile *)file {
    WeakSelf(self);
    if (file.fileType == kFILEVIDEO || file.isGif) {
        RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
        trimVideoVC.isRotateEnable = YES;
        trimVideoVC.trimFile = [file copy];
        trimVideoVC.TrimAndRotateVideoFinishBlock = ^(float rotate, CMTimeRange timeRange) {
            StrongSelf(self);
            if (file.isGif) {
                file.imageTimeRange = timeRange;
                file.thumbImage = [UIImage getGifThumbImageWithData:file.gifData time:CMTimeGetSeconds(timeRange.start)];
            }else {
                file.videoTrimTimeRange = timeRange;
                file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(timeRange.start) url:file.contentURL urlAsset:nil];
            }
            file.rotate = rotate;
            [strongSelf->selectedFileArray addObject:file];
            strongSelf->selectedVideoCount++;
            
            CGPoint offset = strongSelf->selectedFilesScrollView.contentOffset;
            strongSelf->selectedFilesScrollView.contentSize = CGSizeMake(strongSelf->selectedFileArray.count * (strongSelf->thumbWidth ), 0);
            
            RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height)];
            thumbView.frame = CGRectMake((strongSelf->thumbWidth )*(strongSelf->selectedFileArray.count - 1), 0, strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height);
            thumbView.home = thumbView.frame;
            thumbView.isAlbum = TRUE;
            thumbView.thumbIconView.image = file.thumbImage;
            thumbView.thumbDurationlabel.text = [RDHelpClass timeFormat:CMTimeGetSeconds(timeRange.duration)];
            thumbView.thumbId = strongSelf->selectedFileArray.count - 1;
            thumbView.contentFile = file;
            thumbView.delegate = strongSelf;
            [strongSelf->selectedFilesScrollView addSubview:thumbView];
            if( (thumbView.frame.origin.x+thumbView.frame.size.width) > strongSelf->selectedFilesScrollView.bounds.size.width )
            {
                offset = CGPointMake((thumbView.frame.origin.x+thumbView.frame.size.width) - strongSelf->selectedFilesScrollView.bounds.size.width, offset.y);
            }
            [strongSelf->selectedFilesScrollView setContentOffset:offset];
            [strongSelf changecountLabel];
            if(strongSelf->_mediaCountLimit == 1){
                [strongSelf selectFinish];
            }
        };
        StrongSelf(self);
        RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
        [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)strongSelf.navigationController)];
        [strongSelf presentViewController:nav animated:YES completion:nil];
    }else {
        CropViewController *cropVC = [[CropViewController alloc] init];
        cropVC.selectFile = file;
        cropVC.presentModel = YES;
        cropVC.isOnlyRotate = YES;
        cropVC.editVideoSize = _inVideoSize;
        cropVC.editVideoForOnceFinishAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
            StrongSelf(self);
            file.rotate = rotate;
            file.crop = crop;
            [strongSelf->selectedFileArray addObject:file];
            strongSelf->selectedPicCount++;
            
            CGPoint offset = strongSelf->selectedFilesScrollView.contentOffset;
            
            strongSelf->selectedFilesScrollView.contentSize = CGSizeMake(strongSelf->selectedFileArray.count * (strongSelf->thumbWidth ), 0);
            
            RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height)];
            thumbView.frame = CGRectMake((strongSelf->thumbWidth )*(strongSelf->selectedFileArray.count - 1), 0, strongSelf->thumbWidth + 7, strongSelf->selectedFilesScrollView.bounds.size.height);
            thumbView.isAlbum = TRUE;
            
            thumbView.home = thumbView.frame;
            thumbView.thumbIconView.image = file.thumbImage;
            thumbView.thumbDurationlabel.hidden = YES;
            thumbView.thumbId = strongSelf->selectedFileArray.count - 1;
            thumbView.contentFile = file;
            thumbView.delegate = strongSelf;
            [strongSelf->selectedFilesScrollView addSubview:thumbView];
            if( (thumbView.frame.origin.x+thumbView.frame.size.width) > strongSelf->selectedFilesScrollView.bounds.size.width )
            {
                offset = CGPointMake((thumbView.frame.origin.x+thumbView.frame.size.width) - strongSelf->selectedFilesScrollView.bounds.size.width, offset.y);
            }
            [strongSelf->selectedFilesScrollView setContentOffset:offset];
            [strongSelf changecountLabel];
            if(strongSelf->_mediaCountLimit == 1){
                [strongSelf selectFinish];
            }
        };
        StrongSelf(self);
        RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
        [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)strongSelf.navigationController)];
        [strongSelf presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark - CustomTextDelegate
- (void)getCustomTextImagePath:(NSString *)textImagePath thumbImage:(UIImage *)thumbImage customTextPhotoFile:(CustomTextPhotoFile *)file touchUpType:(NSInteger)touchUpType change:(BOOL)flag {
    @autoreleasepool {
        __block typeof(self) bself = self;
        if(flag){
            RDFile *selectFile = [selectedFileArray objectAtIndex:editThumbId];
#if isUseCustomLayer
            selectFile.contentURL = [NSURL fileURLWithPath:textImagePath];
            selectFile.thumbImage = thumbImage;
            selectFile.customTextPhotoFile = file;
            RDThumbImageView *thumbIV = [bself->selectedFilesScrollView viewWithTag:bself->editThumbId+10000];
            thumbIV.isAlbum = YES;
            thumbIV.thumbIconView.image = thumbImage;
            selectFile.thumbImage = thumbImage;
#else
            UIImage *image = thumbImage;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageDataFullScreen = UIImageJPEGRepresentation(image, 0.9);
                unlink([selectFile.contentURL.path UTF8String]);
                [imageDataFullScreen writeToFile:selectFile.contentURL.path atomically:YES];
                imageDataFullScreen = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    selectFile.customTextPhotoFile = file;
                    RDThumbImageView *thumbIV = [bself->selectedFilesScrollView viewWithTag:bself->editThumbId+10000];
                    thumbIV.thumbIconView.image = image;
                    selectFile.thumbImage = image;
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
            rdFile.crop                      = CGRectZero;
            rdFile.cropRect                  = CGRectZero;
            rdFile.speed                     = 1;
            rdFile.speedIndex                = 2;
            rdFile.rotate                    = 0;
            rdFile.isHorizontalMirror        = NO;
            rdFile.isVerticalMirror          = NO;
            rdFile.isReverse                 = NO;
            rdFile.customTextPhotoFile       = file;
            [selectedFileArray addObject:rdFile];
            selectedPicCount++;
            if(_mediaCountLimit == 1){
                [self selectFinish];
            }else {
                CGPoint offset = selectedFilesScrollView.contentOffset;
                
                selectedFilesScrollView.contentSize = CGSizeMake(selectedFileArray.count * (thumbWidth ), 0);
                
                RDThumbImageView *thumbView = [[RDThumbImageView alloc] initWithSize:CGSizeMake(thumbWidth + 7, selectedFilesScrollView.bounds.size.height)];
                thumbView.frame = CGRectMake((thumbWidth )*(selectedFileArray.count - 1), 0, thumbWidth + 7, selectedFilesScrollView.bounds.size.height);
                thumbView.home = thumbView.frame;
                thumbView.isAlbum = TRUE;
                thumbView.thumbIconView.image = rdFile.thumbImage;
//                thumbView.thumbDurationlabel.text = [RDHelpClass timeFormat:CMTimeGetSeconds(rdFile.imageDurationTime)];
                thumbView.thumbDurationlabel.hidden = YES;
                thumbView.thumbId = selectedFileArray.count - 1;
                thumbView.contentFile = rdFile;
                thumbView.delegate = self;
                [selectedFilesScrollView addSubview:thumbView];
                if( (thumbView.frame.origin.x+thumbView.frame.size.width) > selectedFilesScrollView.bounds.size.width )
                {
                    offset = CGPointMake((thumbView.frame.origin.x+thumbView.frame.size.width) - selectedFilesScrollView.bounds.size.width, offset.y);
                }
                [selectedFilesScrollView setContentOffset:offset];
                
                [self changecountLabel];
            }
        }
    }
}

#pragma mark - RDThumbImageViewDelegate
- (void)thumbImageViewWasTapped:(RDThumbImageView *)tiv touchUpTiv:(BOOL)isTouchUpTiv{
    RDFile *file = tiv.contentFile;
    if (file.fileType == kTEXTTITLE) {
        editThumbId = tiv.thumbId;
        CustomTextPhotoViewController *cusTextview  = [[CustomTextPhotoViewController alloc] initWithFile:file.customTextPhotoFile];
        cusTextview.delegate = self;
        cusTextview.touchUpType = 0;
        RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cusTextview];
        [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
        [self presentViewController:nav animated:YES completion:nil];
    }else if (!_onAlbumCallbackBlock && !_isDisableEdit) {
        if (file.fileType == kFILEIMAGE && !file.isGif) {
            CropViewController *cropVC = [[CropViewController alloc] init];
            cropVC.selectFile = file;
            cropVC.presentModel = YES;
            cropVC.isOnlyRotate = YES;
            cropVC.editVideoForOnceFinishAction = ^(CGRect crop, CGRect cropRect, BOOL verticalMirror, BOOL horizontalMirror, float rotate, FileCropModeType cropModeType) {
                file.rotate = rotate;
                file.crop = crop;
                file.cropRect = cropRect;
                if (rotate != 0 || !CGRectEqualToRect(crop, CGRectMake(0, 0, 1, 1))) {
                    file.thumbImage = [RDHelpClass image:[RDHelpClass getThumbImageWithUrl:file.contentURL] rotation:rotate cropRect:crop];
                    tiv.thumbIconView.image = file.thumbImage;
                }
            };
            RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:cropVC];
            [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
            [self presentViewController:nav animated:YES completion:nil];
        }else {
            RDTrimVideoViewController *trimVideoVC = [[RDTrimVideoViewController alloc] init];
            trimVideoVC.isRotateEnable = YES;
            trimVideoVC.trimFile = [file copy];
            trimVideoVC.TrimAndRotateVideoFinishBlock = ^(float rotate, CMTimeRange timeRange) {
                if (file.isGif) {
                    file.imageTimeRange = timeRange;
                    file.thumbImage = [UIImage getGifThumbImageWithData:file.gifData time:CMTimeGetSeconds(timeRange.start)];
                }else {
                    file.videoTrimTimeRange = timeRange;
                    file.thumbImage = [RDHelpClass assetGetThumImage:CMTimeGetSeconds(timeRange.start) url:file.contentURL urlAsset:nil];
                }
                file.rotate = rotate;
                if (rotate != 0) {
                    file.thumbImage = [RDHelpClass image:file.thumbImage rotation:rotate cropRect:CGRectZero];
                }
                tiv.thumbIconView.image = file.thumbImage;
                tiv.thumbDurationlabel.text = [RDHelpClass timeFormat:CMTimeGetSeconds(timeRange.duration)];
            };
            
            RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:trimVideoVC];
            [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}

- (void)thumbImageViewWaslongLongTap:(RDThumbImageView *)tiv{
    tiv.tap = NO;
    selectedFilesScrollView.scrollEnabled = NO;
    if(selectedFileArray.count <=1){
        return;
    }
    tiv.canMovePostion = YES;
    
    if(tiv.cancelMovePostion){
        tiv.canMovePostion = NO;
        
        return;
    }
    
    CGPoint touchLocation = tiv.center;
    CGFloat ofset_x = selectedFilesScrollView.contentOffset.x;
    [selectedFilesScrollView setContentSize:CGSizeMake(selectedFileArray.count * (thumbWidth ), 0)];
    
    NSMutableArray *arra = [selectedFilesScrollView.subviews mutableCopy];
    [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    NSInteger index = 0;
    
    __block typeof(self) bself = self;
    for (int i = 0; i < arra.count; i++) {
        RDThumbImageView *thumbImageView = arra[i];
        [UIView animateWithDuration:0.15 animations:^{
            
            CGRect tmpRect = thumbImageView.frame;
            thumbImageView.frame = CGRectMake(index * (bself->thumbWidth ), tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
            thumbImageView.home = thumbImageView.frame;
            [thumbImageView selectThumb:NO];
            if(thumbImageView == tiv){
                [thumbImageView selectThumb:YES];
                CGPoint offset = bself->selectedFilesScrollView.contentOffset;
                if( (thumbImageView.frame.origin.x+thumbImageView.frame.size.width) > bself->selectedFilesScrollView.bounds.size.width )
                {
                    offset = CGPointMake((thumbImageView.frame.origin.x+thumbImageView.frame.size.width) - bself->selectedFilesScrollView.bounds.size.width, offset.y);
                }
                [bself->selectedFilesScrollView setContentOffset:offset];
            }
            
        } completion:^(BOOL finished) {
            
        }];
        
        index ++;
    }
}

- (void)thumbImageViewWaslongLongTapEnd:(RDThumbImageView *)tiv {
    tiv.canMovePostion = NO;
    if(selectedFileArray.count <=1){
        return;
    }
    selectedFilesScrollView.scrollEnabled = YES;
    
    CGPoint touchLocation = tiv.center;
    
    CGFloat ofSet_x = selectedFilesScrollView.contentOffset.x;
    [selectedFilesScrollView setContentSize:CGSizeMake(selectedFileArray.count * (thumbWidth ), 0)];
    
    [selectedFileArray removeAllObjects];
    NSMutableArray *arra = [selectedFilesScrollView.subviews mutableCopy];
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
    
    NSInteger index = 0;
    for (int i = 0; i < arra.count; i++) {
        RDThumbImageView *thumbImageView = arra[i];
        CGRect tmpRect = thumbImageView.frame;
        thumbImageView.frame = CGRectMake(index * (thumbWidth ), tmpRect.origin.y, tmpRect.size.width, tmpRect.size.height);
        thumbImageView.home = thumbImageView.frame;
        thumbImageView.thumbId = index;
        if(thumbImageView == tiv){
            [thumbImageView selectThumb:NO];
            CGPoint offset = selectedFilesScrollView.contentOffset;
            if( (thumbImageView.frame.origin.x+thumbImageView.frame.size.width) > selectedFilesScrollView.bounds.size.width )
            {
                offset = CGPointMake((thumbImageView.frame.origin.x+thumbImageView.frame.size.width) - selectedFilesScrollView.bounds.size.width, offset.y);
            }
            [selectedFilesScrollView setContentOffset:offset];
        }
        [selectedFileArray addObject:thumbImageView.contentFile];
        index ++;
    }
}

- (void)thumbImageViewMoved:(RDThumbImageView *)draggingThumb withEvent:(UIEvent *)event
{
    draggingThumb.tap = NO;
    if(!draggingThumb.canMovePostion){
        return;
    }
    // check if we've moved close enough to an edge to autoscroll, or far enough away to stop autoscrolling
    [self maybeAutoscrollForThumb:draggingThumb];
    
    /* The rest of this method handles the reordering of thumbnails in the _libraryListScrollView. See  */
    /* RDThumbImageView.h and RDThumbImageView.m for more information about how this works.          */
    
    // we'll reorder only if the thumb is overlapping the scroll view
    
    if (CGRectIntersectsRect([draggingThumb frame], CGRectMake(0, 0, selectedFilesScrollView.contentSize.width, selectedFilesScrollView.contentSize.height)))
    {
        BOOL draggingRight = [draggingThumb frame].origin.x > [draggingThumb home].origin.x ? YES : NO;
        
        /* we're going to shift over all the thumbs who live between the home of the moving thumb */
        /* and the current touch location. A thumb counts as living in this area if the midpoint  */
        /* of its home is contained in the area.                                                  */
        NSMutableArray *thumbsToShift = [[NSMutableArray alloc] init];
        
        // get the touch location in the coordinate system of the scroll view
        CGPoint touchLocation = [draggingThumb convertPoint:[draggingThumb touchLocation] toView:selectedFilesScrollView];
        
        // calculate minimum and maximum boundaries of the affected area
        float minX = draggingRight ? CGRectGetMaxX([draggingThumb home]) : touchLocation.x;
        float maxX = draggingRight ? touchLocation.x : CGRectGetMinX([draggingThumb home]);
        
        // iterate through thumbnails and see which ones need to move over
        
        for (RDThumbImageView *thumb in [selectedFilesScrollView subviews])
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
    [autoscrollTimer invalidate];
    autoscrollTimer = nil;
}

- (void)thumbDeletedThumbFile:(RDThumbImageView *)tiv{
    
    __block typeof(self) bself = self;
    if(selectedFileArray.count > 0){
        [selectedFileArray removeObjectAtIndex:tiv.thumbId];
        if (tiv.contentFile.fileType == kFILEVIDEO) {
            selectedVideoCount--;
        }else {
            selectedPicCount--;
        }
        
        CGPoint offset = selectedFilesScrollView.contentOffset;
        
        float diffx = (tiv.frame.origin.x + tiv.frame.size.width) - offset.x;
        offset.x -= MIN(tiv.frame.size.width + 34, diffx);
        offset.x = MAX(offset.x, 0);
        
        NSMutableArray *arra = [selectedFilesScrollView.subviews mutableCopy];
        [arra sortUsingComparator:^NSComparisonResult(RDThumbImageView *obj1, RDThumbImageView *obj2) {
            CGFloat obj1X = obj1.frame.origin.x;
            CGFloat obj2X = obj2.frame.origin.x;
            
            if (obj1X > obj2X) { // obj1排后面
                return NSOrderedDescending;
            } else { // obj1排前面
                return NSOrderedAscending;
            }
        }];
        
        [arra enumerateObjectsUsingBlock:^(UIView* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDThumbImageView *thumbImageView = (RDThumbImageView *)obj;
            if(thumbImageView.thumbId == tiv.thumbId){
                [obj removeFromSuperview];
            }
            if(thumbImageView.thumbId > tiv.thumbId){
                CGRect rect  = obj.frame;
                rect.origin.x = obj.frame.origin.x - (bself->thumbWidth );
                obj.frame = rect;
                thumbImageView.home = obj.frame;
                thumbImageView.thumbId -= 1;
            }
            [thumbImageView selectThumb:NO];
        }];
        if( (tiv.frame.origin.x+tiv.frame.size.width) > selectedFilesScrollView.bounds.size.width )
        {
            offset = CGPointMake((tiv.frame.origin.x+tiv.frame.size.width) - selectedFilesScrollView.bounds.size.width, offset.y);
        }
        [selectedFilesScrollView setContentOffset:offset];
        selectedFilesScrollView.contentSize = CGSizeMake(selectedFileArray.count * (thumbWidth ), 0);
    }
    [self changecountLabel];
}

#pragma mark - Autoscrolling methods
- (void)maybeAutoscrollForThumb:(RDThumbImageView *)thumb
{
    autoscrollDistance = 0;
    
    // only autoscroll if the thumb is overlapping the _libraryListScrollView
    if (CGRectIntersectsRect([thumb frame], selectedFilesScrollView.bounds))
    {
        CGPoint touchLocation = [thumb convertPoint:[thumb touchLocation] toView:selectedFilesScrollView];
        float distanceFromLeftEdge  = touchLocation.x - CGRectGetMinX(selectedFilesScrollView.bounds);
        float distanceFromRightEdge = CGRectGetMaxX(selectedFilesScrollView.bounds) - touchLocation.x;
        if (distanceFromLeftEdge < AUTOSCROLL_THRESHOLD)
        {
            
            if (selectedFileArray.count>3) {
                autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromLeftEdge] * -1; // if scrolling left, distance is negative
            }
        }
        else if (distanceFromRightEdge < AUTOSCROLL_THRESHOLD)
        {
            
            if (selectedFileArray.count>3) {
                autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromRightEdge];
            }
        }
    }
    // if no autoscrolling, stop and clear timer
    if (autoscrollDistance == 0)
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

- (float)autoscrollDistanceForProximityToEdge:(float)proximity
{
    // the scroll distance grows as the proximity to the edge decreases, so that moving the thumb
    // further over results in faster scrolling.
    return ceilf((AUTOSCROLL_THRESHOLD - proximity) / 5.0);
}

- (void)legalizeAutoscrollDistance
{
    // makes sure the autoscroll distance won't result in scrolling past the content of the scroll view
    float minimumLegalDistance = [selectedFilesScrollView contentOffset].x * -1;
    float maximumLegalDistance = [selectedFilesScrollView contentSize].width - ([selectedFilesScrollView frame].size.width
                                                                                 + [selectedFilesScrollView contentOffset].x);
    autoscrollDistance = MAX(autoscrollDistance, minimumLegalDistance);
    autoscrollDistance = MIN(autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer
{
    //return;
    
    [self legalizeAutoscrollDistance];
    // autoscroll by changing content offset
    CGPoint contentOffset = [selectedFilesScrollView contentOffset];
    contentOffset.x += autoscrollDistance;
    [selectedFilesScrollView setContentOffset:contentOffset];
    
    RDThumbImageView *thumb = (RDThumbImageView *)[timer userInfo];
    [thumb moveByOffset:CGPointMake(autoscrollDistance, 0) withEvent:nil];
}

- (void)removeFromSuperview:(UIView *)view{
    if(!view){
        return;
    }
    NSLog(@"%s : %@",__func__,[view class]);
    
    if([view isKindOfClass:[UIImageView class]]){
        ((UIImageView *)view).image = nil;
    }
    [view removeFromSuperview];
}

- (void)deallocView{
    
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    [_hud releaseHud];
    _hud.delegate = nil;
    _hud = nil;
    if (commonAlertView) {
        [commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
    
    [_videoCollection removeFromSuperview];
    [_photoCollection removeFromSuperview];
    _videoCollection = nil;
    _photoCollection = nil;
    
    [selectedFilesScrollView.subviews enumerateObjectsUsingBlock:^(__kindof RDThumbImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)deallocArray{
    for (__strong PHAsset *iAsset in _dsV) {
        iAsset = nil;
    }
    [_dsV removeAllObjects];
    
    for (__strong PHAsset *iAsset in _dsP) {
        iAsset = nil;
    }
    [_dsP removeAllObjects];
    
    for (__strong NSIndexPath *indexPath in _selectVideoItems) {
        indexPath = nil;
    }
    [_selectVideoItems removeAllObjects];
    
    for (__strong NSNumber *number in _selectPhotoItems) {
        number = nil;
    }
    [_selectPhotoItems removeAllObjects];
    
    [selectedFileArray removeAllObjects];
    
    _dsV = nil;
    _dsP = nil;
    _selectVideoItems = nil;
    _selectPhotoItems = nil;
    
    _currentPhotoAlbum = nil;
    _currentVideoAlbum = nil;
    
    _selectFinishActionBlock = nil;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    [self deallocView];
    [self deallocArray];
}

@end

