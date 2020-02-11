//
//  RDDyRecordViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/6/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDyRecordViewController.h"
#import "RDNavigationViewController.h"
#import "RDCameraManager.h"
#import "RDRecordTypeView.h"
#import "RDCustomButton.h"
#import "RDMoveProgress.h"
#import "RDDownTool.h"
#import "ProgressBar.h"
#import "ScrollViewChildItem.h"
#import "UIButton+RDCustomLayout.h"
#import "RDTouchButton.h"
#import "RDCloudMusicViewController.h"

@interface RDDyRecordViewController ()<RDCameraManagerDelegate, RDRecordTypeViewDelegate, ScrollViewChildItemDelegate, RDTouchButtonDelegate>
{    
    CameraConfiguration         *cameraConfig;
    ProgressBar                 *recordProgressBar;
    UIView                      *noRecordingView;
    UIView                      *topView;
    UIButton                    *backBtn;
    ScrollViewChildItem         *musicBtn;
    UIView                      *rightBtnView;
    UIButton                    *trimMusicBtn;
    UIView                      *takePhotoView;
    RDTouchButton               *recordBtn;
    UIButton                    *faceUBtn;
    UIButton                    *albumBtn;
    
    RDRecordTypeView            *recordTypeView;
    NSInteger                    selectedRecordTypeIndex;
    
    UIView                      *faceUView;
    UIScrollView                *faceUScrollView;
    NSInteger                    selectedFaceUIndex;
    NSMutableArray              *faceUArray;
    
    NSMutableArray              *videoArray;
    RDMusic                     *recordMusic;
}
@property (nonatomic, strong) RDCameraManager *cameraManager;

@end

@implementation RDDyRecordViewController

- (BOOL)prefersStatusBarHidden{
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    
    [self checkCameraISOpen];
    [self.cameraManager startCamera];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setValue];
    [self initTopView];
    [self initRightBtnView];
    [self initRecordTypeView];
    [self initBottomBtn];
}

- (void)setValue {
    cameraConfig = ((RDNavigationViewController *)self.navigationController).cameraConfiguration;
    selectedRecordTypeIndex = 0;
    selectedFaceUIndex = 1;
    videoArray = [NSMutableArray array];
    
    noRecordingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    [self.view addSubview:noRecordingView];
}

- (void)initTopView {
    recordProgressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, 10)];
    [self.view addSubview:recordProgressBar];
    
    topView = [[UIView alloc] initWithFrame:CGRectMake(0, recordProgressBar.frame.origin.y + recordProgressBar.bounds.size.height, kHEIGHT, 44)];
    [noRecordingView addSubview:topView];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = topView.bounds;
    gradient.colors = @[(id)[UIColor colorWithWhite:0 alpha:0.3].CGColor,(id)[UIColor clearColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(0, 1.0);
    [topView.layer addSublayer:gradient];
    
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 44, 44);
    [backBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回默认_@3x"] forState:UIControlStateNormal];
    [backBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回点击_@3x"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
    
    musicBtn = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake((kWIDTH - kWIDTH/3.0)/2.0, 0, kWIDTH/3.0, 44)];
    musicBtn.frame = CGRectMake((kWIDTH - kWIDTH/3.0)/2.0, 0, kWIDTH/3.0, 44);
    musicBtn.cornerRadius = 0.0;
    musicBtn.fontSize = 14;
    musicBtn.normalColor = [UIColor whiteColor];
    musicBtn.itemIconView.image = [RDHelpClass getBundleImagePNG:@"dyRecord/musicOff_"];
    musicBtn.itemTitleLabel.text = RDLocalizedString(@"选择音乐", nil);
    musicBtn.delegate = self;
    [topView addSubview:musicBtn];
}

- (void)initRightBtnView {
    rightBtnView = [[UIView alloc] initWithFrame:CGRectMake(kWIDTH - 44, topView.frame.origin.y + 10, 44, kHEIGHT/2.0)];
    [noRecordingView addSubview:rightBtnView];
    
    UIButton *cameraPositionBtn = [self createCustomBtnWithTitle:RDLocalizedString(@"翻转", nil) image:[RDHelpClass getBundleImagePNG:@"dyRecord/cameraFlip_@3x"]];;
    cameraPositionBtn.frame = CGRectMake(0, 0, 44, 44);
    [cameraPositionBtn addTarget:self action:@selector(cameraPositionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtnView addSubview:cameraPositionBtn];
    
    UIButton *speedBtn = [self createCustomBtnWithTitle:RDLocalizedString(@"快慢速", nil) image:[RDHelpClass getBundleImagePNG:@"dyRecord/speedOff_@3x"]];;
    speedBtn.frame = CGRectMake(0, 64, 44, 44);
    [speedBtn addTarget:self action:@selector(speedBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtnView addSubview:speedBtn];
    
    UIButton *filterBtn = [self createCustomBtnWithTitle:RDLocalizedString(@"滤镜", nil) image:[RDHelpClass getBundleImagePNG:@"dyRecord/filter_@3x"]];;
    filterBtn.frame = CGRectMake(0, 64*2, 44, 44);
    [filterBtn addTarget:self action:@selector(filterBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtnView addSubview:filterBtn];
    
    UIButton *beautyBtn = [self createCustomBtnWithTitle:RDLocalizedString(@"美化", nil) image:[RDHelpClass getBundleImagePNG:@"dyRecord/beauty_@3x"]];;
    beautyBtn.frame = CGRectMake(0, 64*3, 44, 44);
    [beautyBtn addTarget:self action:@selector(beautyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtnView addSubview:beautyBtn];
    
    UIButton *timerBtn = [self createCustomBtnWithTitle:RDLocalizedString(@"倒计时", nil) image:[RDHelpClass getBundleImagePNG:@"dyRecord/timer_@3x"]];;
    timerBtn.frame = CGRectMake(0, 64*4, 44, 44);
    [timerBtn addTarget:self action:@selector(timerBtnnAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtnView addSubview:timerBtn];
    
    trimMusicBtn = [self createCustomBtnWithTitle:RDLocalizedString(@"剪音乐", nil) image:[RDHelpClass getBundleImagePNG:@"dyRecord/musicClip_@3x"]];;
    trimMusicBtn.frame = CGRectMake(0, 64*5, 44, 44);
    [trimMusicBtn addTarget:self action:@selector(trimMusicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    trimMusicBtn.hidden = YES;
    [rightBtnView addSubview:trimMusicBtn];
}

- (UIButton *)createCustomBtnWithTitle:(NSString *)title image:(UIImage *)image {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 44, 44);
    [btn setImage:image forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:10.0];
    [btn layoutButtonWithEdgeInsetsStyle:RDButtonEdgeInsetsStyleTop imageTitleSpace:5.0];
    return btn;
}

- (void)initRecordTypeView {
    NSArray *itemArray = [NSArray arrayWithObjects:
                          RDLocalizedString(@"拍照", nil),
                          RDLocalizedString(@"60秒", nil),
                          RDLocalizedString(@"15秒", nil),
                          nil];
    recordTypeView = [[RDRecordTypeView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 44 - (iPhone_X ? 34 : 0), kWIDTH, 44)];
    [recordTypeView setItemTitleArray:itemArray selectedIndex:2];
    [noRecordingView addSubview:recordTypeView];
}

- (void)initBottomBtn {
    takePhotoView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 80)/2.0, recordTypeView.frame.origin.y - 80, 80, 80)];
    takePhotoView.hidden = YES;
    [self.view addSubview:takePhotoView];
    
    UIView *takePhotoBtnCenterView = [[UIView alloc] initWithFrame:CGRectMake((80 - 64)/2.0, (80 - 64)/2.0, 64, 64)];
    takePhotoBtnCenterView.backgroundColor = [UIColor whiteColor];
    takePhotoBtnCenterView.layer.cornerRadius = 32.0;
    [takePhotoView addSubview:takePhotoBtnCenterView];
    
    UIButton *takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    takePhotoBtn.frame = CGRectMake(0, 0, 80, 80);
    takePhotoBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    takePhotoBtn.layer.borderWidth = 6.0;
    takePhotoBtn.layer.cornerRadius = 40.0;
    [takePhotoBtn addTarget:self action:@selector(takePhotoBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [takePhotoView addSubview:takePhotoBtn];
    
    recordBtn = [[RDTouchButton alloc] initWithFrame:takePhotoView.frame];
    recordBtn.delegate = self;
    [self.view addSubview:recordBtn];
    
    if (cameraConfig.enableFaceU && cameraConfig.faceUURL) {
        faceUBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        faceUBtn.frame = CGRectMake(recordBtn.frame.origin.x - 60 - 50, recordBtn.frame.origin.y + (recordBtn.bounds.size.height - 50)/2.0, 50, 50);
        [faceUBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图默认_@3x"] forState:UIControlStateNormal];
        [faceUBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图点击_@3x"] forState:UIControlStateHighlighted];
        [faceUBtn addTarget:self action:@selector(faceUBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:faceUBtn];
    }
    
    if (!cameraConfig.hiddenPhotoLib) {
        albumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        albumBtn.frame = CGRectMake(recordBtn.frame.origin.x + recordBtn.bounds.size.width + 60, recordBtn.frame.origin.y + (recordBtn.bounds.size.height - 50)/2.0, 50, 50);
        [albumBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册默认_@3x"] forState:UIControlStateNormal];
        [albumBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册点击_@3x"] forState:UIControlStateHighlighted];
        [albumBtn addTarget:self action:@selector(albumBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:albumBtn];
    }
}

- (void)initFaceUView {
    faceUView = [[UIView alloc] initWithFrame:CGRectMake(0, topView.frame.origin.y + topView.bounds.size.height, kWIDTH, kHEIGHT - (topView.frame.origin.y + topView.bounds.size.height))];
    faceUView.userInteractionEnabled = YES;
    faceUView.hidden = YES;
    [self.view addSubview:faceUView];
    
    faceUScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, faceUView.bounds.size.height - ((kWIDTH - 18 - 9*4)/5*2 + 9*3) - (iPhone_X ? 34 : 0), kWIDTH, (kWIDTH - 18 - 9*4)/5*2 + 9*3)];
    faceUScrollView.backgroundColor = UIColorFromRGB(0x19181d);
    faceUScrollView.showsVerticalScrollIndicator = NO;
    faceUScrollView.showsHorizontalScrollIndicator = NO;
    [faceUView addSubview:faceUScrollView];
    
    int rowCount = 2;
    WeakSelf(self);
    [faceUArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        StrongSelf(self);
        RDCustomButton *itemBtn = [[RDCustomButton alloc] initWithItem:obj[@"url"] itemName:obj[@"name"] itemPath:obj[@"img"]];
        itemBtn.backgroundColor = [UIColor clearColor];
        if(strongSelf->selectedFaceUIndex == idx+1){
            [itemBtn selected:YES];
        }
        itemBtn.tag = idx + 1;
        itemBtn.frame = CGRectMake(floorf(idx/rowCount)  * ((kWIDTH - 9*4)/5 + 9), 9 + idx%rowCount * ((kWIDTH - 9*4)/5 + 9), (kWIDTH - 9*4)/5, (kWIDTH - 9*4)/5);
        [itemBtn addTarget:self action:@selector(faceItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        if(idx == 0){
            [itemBtn setImage: [RDHelpClass getBundleImagePNG:@"拍摄_滤镜无默认_@3x"] forState:UIControlStateNormal];
        }else{
            [RDHelpClass setFaceUItemBtnImage:obj[@"img"] name:obj[@"name"] item:itemBtn];
        }
        [strongSelf->faceUScrollView addSubview:itemBtn];
    }];
}

- (void)checkCameraISOpen{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:RDLocalizedString(@"无法访问相机!",nil)
                                  message:RDLocalizedString(@"用户拒绝访问相机,请在<设置-隐私-相机>中开启",nil)
                                  delegate:self
                                  cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                  otherButtonTitles:RDLocalizedString(@"取消",nil), nil];
        alertView.tag = 2;
        [alertView show];
        return;
    }
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [avSession requestRecordPermission:^(BOOL available) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!available) {
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:RDLocalizedString(@"无法访问麦克风!",nil)
                                              message:RDLocalizedString(@"请在“设置-隐私-麦克风”中开启",nil)
                                              delegate:self
                                              cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                              otherButtonTitles:RDLocalizedString(@"取消",nil), nil];
                    alertView.tag = 2;
                    [alertView show];
                }
            });
        }];
    }
}

- (RDCameraManager *)cameraManager {
    if (!_cameraManager) {
        CGSize recordSize = cameraConfig.cameraOutputSize;
        int fps = cameraConfig.cameraFrameRate;
        int bitrate = cameraConfig.cameraBitRate;
        if(CGSizeEqualToSize(recordSize, CGSizeZero)){
            recordSize = [RDCameraManager defaultMatchSize];
        }
        if(fps == 0){
            fps = 30;
        }
        int resolutionIndex;
        if (recordSize.width == 1080) {
            resolutionIndex = 3;
        }else if (recordSize.width == 480) {
            resolutionIndex = 1;
        }else if (recordSize.width == 360) {
            resolutionIndex = 0;
        }else {
            resolutionIndex = 2;
        }
        if (bitrate == 0) {
            switch (resolutionIndex) {
                case 0:
                    bitrate = 400 * 1000;
                    break;
                case 1:
                    bitrate = 850 * 1000;
                    break;
                case 2:
                    bitrate = 1800 * 1000;
                    break;
                case 3:
                    bitrate = 3000 * 1000;
                    break;
                    
                default:
                    break;
            }
        }
        AVCaptureDevicePosition cameraPosition = cameraConfig.cameraCaptureDevicePosition;
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"RDAVCaptureDevicePosition"]){
            NSInteger position = [[[NSUserDefaults standardUserDefaults] objectForKey:@"RDAVCaptureDevicePosition"] integerValue];
            cameraPosition = (AVCaptureDevicePosition)position;
        }
        if (cameraPosition == AVCaptureDevicePositionUnspecified) {
            cameraPosition = AVCaptureDevicePositionFront;
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:@(cameraPosition) forKey:@"RDAVCaptureDevicePosition"];
        RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
        
        if(!nav.editConfiguration.enableDraft)
        {
            unlink([cameraConfig.cameraOutputPath UTF8String]);
        }
        UIView* screenView = [[UIView alloc] init];
        screenView.frame = CGRectMake(0, 0, MAX(kHEIGHT, kWIDTH),MIN(kHEIGHT, kWIDTH));
        screenView.center = CGPointMake( MIN(kHEIGHT, kWIDTH)/2,MAX(kHEIGHT, kWIDTH)/2);
        screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
        [self.view insertSubview:screenView atIndex:0];
        
        _cameraManager = [[RDCameraManager alloc] initWithAPPKey:nav.appKey
                                                       APPSecret:nav.appSecret
                                                      LicenceKey:nav.licenceKey
                                                      resultFail:^(NSError *error) {
                                                          NSLog(@"initError:%@", error.localizedDescription);
                                                      }];
        [_cameraManager prepareRecordWithFrame:CGRectMake(0, 0, kHEIGHT, kWIDTH)
                                     superview:screenView
                                       bitrate:bitrate
                                           fps:fps
                                isSquareRecord:NO
                                    cameraSize:recordSize
                                    outputSize:recordSize
                                       isFront:(cameraPosition == AVCaptureDevicePositionFront)
                                  captureAsYUV:YES
                              disableTakePhoto:NO
                         enableCameraWaterMark:cameraConfig.enabelCameraWaterMark
                                enableRdBeauty:!cameraConfig.enableFaceU];
        _cameraManager.swipeScreenIsChangeFilter = NO;
        [_cameraManager setfocus];
        _cameraManager.delegate = self;
        _cameraManager.beautifyState = BeautifyStateSeleted;
        if (iPhone_X) {
            _cameraManager.fillMode = kRDCameraFillModeScaleAspectFill;
        }
    }
    return _cameraManager;
}

#pragma mark - 按钮事件
- (void)backBtnAction:(UIButton *)sender {
    [self deleteItems];
    if(_cancelBlock){
        _cancelBlock(NO, self);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraPositionBtnAction:(UIButton *)sender {
    if (_cameraManager.position == AVCaptureDevicePositionBack) {
        _cameraManager.position = AVCaptureDevicePositionFront;
    }else{
        _cameraManager.position = AVCaptureDevicePositionBack;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(_cameraManager.position) forKey:@"RDAVCaptureDevicePosition"];
}

- (void)speedBtnAction:(UIButton *)sender {
    
}

- (void)filterBtnAction:(UIButton *)sender {
    
}

- (void)beautyBtnAction:(UIButton *)sender {
    
}

- (void)timerBtnnAction:(UIButton *)sender {
    
}

- (void)trimMusicBtnAction:(UIButton *)sender {
    
}

- (void)faceUBtnAction:(UIButton *)sender {
    faceUView.hidden = NO;
}

- (void)albumBtnAction:(UIButton *)sender {
    [self deleteItems];
    WeakSelf(self);
    [self dismissViewControllerAnimated:YES completion:^{
        StrongSelf(self);
        if(strongSelf.cancelBlock){
            strongSelf.cancelBlock(YES, strongSelf);
        }
    }];
}

- (void)faceItemBtnAction:(RDCustomButton *)sender {
    if (sender.tag == selectedFaceUIndex) {
        return;
    }
    if(sender.tag == 1){
        [((RDCustomButton *)[faceUScrollView viewWithTag:selectedFaceUIndex]) selected:NO];
        selectedFaceUIndex = sender.tag;
        [sender selected:YES];
        
        RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
        if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUItemChanged:)]) {
            [nv.rdVeUiSdkDelegate faceUItemChanged:nil];
        }
        return;
    }
    NSString* bundlePath = sender.item;
    NSString* bundleName = sender.itemName;
    NSString* bundleSavePath = [RDHelpClass getFaceUFilePathString:bundleName type:@"bundle"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:bundleSavePath]) {
        
        [((RDCustomButton *)[faceUScrollView viewWithTag:selectedFaceUIndex]) selected:NO];
        selectedFaceUIndex = sender.tag;
        [sender selected:YES];
        
        RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
        if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUItemChanged:)]) {
            [nv.rdVeUiSdkDelegate faceUItemChanged:bundleSavePath];
        }
    }else{
        __block RDMoveProgress *downProgressv = [[RDMoveProgress alloc] initWithFrame:CGRectMake(5, (sender.frame.size.height - 5)/2.0, sender.frame.size.width - 10, 5)];
        [downProgressv setProgress:0 animated:NO];
        [downProgressv setTrackTintColor:Main_Color];
        [downProgressv setBackgroundColor:UIColorFromRGB(0x888888)];
        [sender addSubview:downProgressv];
        RDDownTool *tool = [[RDDownTool alloc] initWithURLPath:bundlePath savePath:bundleSavePath];
        [tool setProgress:^(float value) {
            [downProgressv setProgress:value animated:NO];
        }];
        WeakSelf(self);
        [tool setFinish:^{
            StrongSelf(self);
            [downProgressv removeFromSuperview];
            downProgressv = nil;
            [((RDCustomButton *)[strongSelf->faceUScrollView viewWithTag:strongSelf->selectedFaceUIndex]) selected:NO];
            strongSelf->selectedFaceUIndex = sender.tag;
            [sender selected:YES];
            
            RDNavigationViewController *nv = (RDNavigationViewController *)strongSelf.navigationController;
            if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUItemChanged:)]) {
                [nv.rdVeUiSdkDelegate faceUItemChanged:bundleSavePath];
            }
        }];
        [tool start];
    }
}

- (void)takePhotoBtnAction:(UIButton *)sender {
    WeakSelf(self);
    [_cameraManager takePhoto:UIImageOrientationUp block:^(UIImage *image) {
        [weakSelf takePhotoCompletion:image];
    }];
}

- (void)takePhotoCompletion:(UIImage *)image {
    if (cameraConfig.cameraWriteToAlbum) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    NSString *photoPath = [kRDDraftDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo%d.jpg",0]];
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDraft)
    {
        BOOL have = NO;
        NSInteger exportPathIndex = 0;
        do {
            photoPath = [kRDDraftDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo%ld.jpg",(long)exportPathIndex]];
            exportPathIndex ++;
            have = [[NSFileManager defaultManager] fileExistsAtPath:photoPath];
        } while (have);
    }else {
        unlink([photoPath UTF8String]);
    }
    NSData* imagedata = UIImageJPEGRepresentation(image, 1.0);
    [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
    
    [self deleteItems];
    WeakSelf(self);
    [self dismissViewControllerAnimated:YES completion:^{
        StrongSelf(self);
        if(strongSelf.shootPhotoCompletionBlock){
            strongSelf.shootPhotoCompletionBlock(photoPath);
        }
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    faceUView.hidden = YES;
    backBtn.hidden = NO;
}

#pragma mark- RDTouchButtonDelegate
- (void)touchesRDTouchButtonBegin:(RDTouchButton *)sender{
    
}

- (void)touchesRDTouchButtonEnd:(RDTouchButton *)sender{
    
}

#pragma mark - ScrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item {
    [item stopScrollTitle];
    RDCloudMusicViewController *cloudMusic = [[RDCloudMusicViewController alloc] init];
    cloudMusic.selectedIndex = 0;
    cloudMusic.cloudMusicResourceURL = ((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL;
    cloudMusic.backBlock = ^{
        [item startScrollTitle];
    };
    cloudMusic.selectCloudMusic = ^(RDMusic *music) {
        item.itemTitleLabel.text = music.name;
        [item startScrollTitle];
        
        recordMusic = music;
    };
    [self.navigationController pushViewController:cloudMusic animated:YES];
}

#pragma mark - RDCameraManagerDelegate
- (void)cameraScreenDid{
    self.view.userInteractionEnabled = YES;
}

- (void)currentTime:(float)time {
    
}

- (void)getFaceUData
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"ios" forKey:@"type"];
    NSDictionary *result = [RDHelpClass updateInfomationWithJson:params andUploadUrl:cameraConfig.faceUURL];
    if (result && [[result objectForKey:@"code"] intValue] == 0) {
        faceUArray = [NSMutableArray array];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"noitem", @"url",
                             RDLocalizedString(@"无", nil), @"name",
                             @"", @"img",
                             nil];
        [faceUArray addObject:dic];
        NSArray *array = [[result objectForKey:@"result"] objectForKey:@"bundles"];
        for (NSDictionary *dic in array) {
            if ([[dic objectForKey:@"name"] isEqualToString:@"bg_seg"] && ![RDHelpClass is64bit]) {
                //faceU的背景扣图只支持arm64
                continue;
            }
            [faceUArray addObject:dic];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initFaceUView];
        });
    }else {
        NSLog(@"获取FaceU失败:%@", [result objectForKey:@"message"]);
    }
}

- (void) deleteItems{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_cameraManager stopCamera];
    [_cameraManager deleteItems];
    _cameraManager.delegate = nil;
    _cameraManager = nil;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    
    RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
    if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(destroyFaceU)]) {
        [nv.rdVeUiSdkDelegate destroyFaceU];
    }
}

@end
