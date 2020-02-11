//
//  RDStoryRecordViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/5/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDStoryRecordViewController.h"
#import "RDNavigationViewController.h"
#import "RDCameraManager.h"
#import "RDCustomButton.h"
#import "CircleView.h"
#import "RDMoveProgress.h"
#import "RDDownTool.h"
#import "RDRecordTypeView.h"
#import "RDMainViewController.h"

@interface RDStoryRecordViewController ()<RDCameraManagerDelegate, UIScrollViewDelegate, RDRecordTypeViewDelegate, AVAudioPlayerDelegate>
{
    CameraConfiguration         *cameraConfig;
    UIView                      *topView;
    UIButton                    *backBtn;
    UIButton                    *recordBtn;
    UIButton                    *faceUBtn;
    UIButton                    *albumBtn;
    
    RDRecordTypeView            *recordTypeView;
    NSInteger                    selectedRecordTypeIndex;
    UIView                      *recordBtnCenterView;
    CircleView                  *recordProgressView;
    UIImageView                 *repeatIV;
    
    UIView                      *faceUView;
    UIScrollView                *faceUScrollView;
    NSInteger                    selectedFaceUIndex;
    NSMutableArray              *faceUArray;
    
    UIView                      *effectView;
    UIScrollView                *effectScrollView;
    NSArray                     *effectArray;
    UILabel                     *currentEffectLbl;
    NSInteger                    selectedEffectIndex;
    
    UILabel                     *normalRecordTipLbl;
    UILabel                     *timeTipLbl;
    
    AVAudioPlayer               *audioPlayer;
    CMTimeRange                  musicTimeRange;
}

@property (nonatomic, strong) RDCameraManager *cameraManager;

@end

@implementation RDStoryRecordViewController

- (BOOL)prefersStatusBarHidden{
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_cameraManager stopCamera];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;

    [self checkCameraISOpen];
    [self.cameraManager startCamera];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(hiddenTipLbl:) withObject:normalRecordTipLbl afterDelay:1.5];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setValue];
    [self initTopView];
    [self initRecordTypeView];
    [self initBottomBtn];
    if (cameraConfig.faceUURL && cameraConfig.enableFaceU) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [RDHelpClass createFaceUFolderIfNotExist];
            [self getFaceUData];
        });
    }
    [self getEffectArray];
    
    normalRecordTipLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, recordBtn.frame.origin.y - 30, kWIDTH, 20)];
    normalRecordTipLbl.text = RDLocalizedString(@"长按拍视频，短按拍照片", nil);
    normalRecordTipLbl.textColor = [UIColor whiteColor];
    normalRecordTipLbl.font = [UIFont systemFontOfSize:15.0];
    normalRecordTipLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:normalRecordTipLbl];
    
    timeTipLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    timeTipLbl.text = RDLocalizedString(@"时间太短啦，多拍一会儿吧", nil);
    timeTipLbl.textColor = [UIColor whiteColor];
    timeTipLbl.font = [UIFont systemFontOfSize:15.0];
    timeTipLbl.textAlignment = NSTextAlignmentCenter;
    timeTipLbl.hidden = YES;
    [self.view addSubview:timeTipLbl];
}

- (void)setValue {
    cameraConfig = ((RDNavigationViewController *)self.navigationController).cameraConfiguration;
    selectedRecordTypeIndex = 0;
    selectedFaceUIndex = 1;
    selectedEffectIndex = 0;
}

- (void)initTopView {
    topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kHEIGHT, (iPhone_X ? 72 : 44))];
    [self.view addSubview:topView];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = topView.bounds;
    gradient.colors = @[(id)[UIColor colorWithWhite:0 alpha:0.3].CGColor,(id)[UIColor clearColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(0, 1.0);
    [topView.layer addSublayer:gradient];
    
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, topView.bounds.size.height - 44, 44, 44);
    [backBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回默认_@3x"] forState:UIControlStateNormal];
    [backBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回点击_@3x"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
    
    UIButton *cameraPositionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraPositionBtn.frame = CGRectMake(kWIDTH - 44, topView.bounds.size.height - 44, 44, 44);
    [cameraPositionBtn setImage:[RDHelpClass getBundleImage:@"拍摄_镜头翻转默认"] forState:UIControlStateNormal];
    [cameraPositionBtn setImage:[RDHelpClass getBundleImage:@"拍摄_镜头翻转点击"] forState:UIControlStateHighlighted];
    [cameraPositionBtn addTarget:self action:@selector(cameraPositionBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:cameraPositionBtn];
}

- (void)initRecordTypeView {
    NSArray *itemArray = [NSArray arrayWithObjects:
                          RDLocalizedString(@"普通", nil),
                          RDLocalizedString(@"反复", nil),
                          RDLocalizedString(@"聚焦", nil),
                          nil];
    recordTypeView = [[RDRecordTypeView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 44 - (iPhone_X ? 34 : 0), kWIDTH, 44)];
    [recordTypeView setItemTitleArray:itemArray selectedIndex:0];
    recordTypeView.delegate = self;
    [self.view addSubview:recordTypeView];
}

- (void)initBottomBtn {
    recordBtnCenterView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 56)/2.0, recordTypeView.frame.origin.y - 100 + (80 - 56)/2.0, 56, 56)];
    recordBtnCenterView.backgroundColor = [UIColor whiteColor];
    recordBtnCenterView.layer.cornerRadius = 28;
    recordBtnCenterView.userInteractionEnabled = YES;
    recordBtnCenterView.tag = 1;
    [self.view addSubview:recordBtnCenterView];
    
    repeatIV = [[UIImageView alloc] initWithFrame:CGRectMake((56 - 25)/2.0, (56 - 25)/2.0, 25, 25)];
    repeatIV.image = [RDHelpClass getBundleImagePNG:@"storyRecord/repeat"];
    repeatIV.hidden = YES;
    [recordBtnCenterView addSubview:repeatIV];
    
    recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    recordBtn.frame = CGRectMake((kWIDTH - 80)/2.0, recordTypeView.frame.origin.y - 100, 80, 80);
    recordBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    recordBtn.layer.cornerRadius = 40.0;
    [recordBtn addTarget:self action:@selector(tapRecordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordBtn];
    
    UILongPressGestureRecognizer* longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shootVideoAction:)];
    longGesture.minimumPressDuration = 0.3;
    [recordBtn addGestureRecognizer:longGesture];
    
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

- (void)initEffectView {
    effectView = [[UIView alloc] initWithFrame:CGRectMake(0, recordTypeView.frame.origin.y - 140, kWIDTH, kHEIGHT - recordTypeView.frame.origin.y + 140 - recordTypeView.bounds.size.height - 20)];
    effectView.hidden = YES;
    [self.view addSubview:effectView];
    
    currentEffectLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 100)/2.0, 0, 100, 30)];
    currentEffectLbl.backgroundColor = [UIColor whiteColor];
    currentEffectLbl.layer.cornerRadius = 5.0;
    currentEffectLbl.layer.masksToBounds = YES;
    currentEffectLbl.text = [NSString stringWithFormat:@" %@ ", [[effectArray firstObject] objectForKey:@"name"]];
    currentEffectLbl.textColor = CUSTOM_GRAYCOLOR;
    currentEffectLbl.font = [UIFont systemFontOfSize:14.0];
    currentEffectLbl.textAlignment = NSTextAlignmentCenter;
    [currentEffectLbl sizeToFit];
    CGRect frame = currentEffectLbl.frame;
    frame.origin.x = (kWIDTH - frame.size.width)/2.0;
    currentEffectLbl.frame = frame;
    [effectView addSubview:currentEffectLbl];
    
    effectScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, kWIDTH, effectView.bounds.size.height - 40)];
    effectScrollView.showsHorizontalScrollIndicator = NO;
    effectScrollView.showsVerticalScrollIndicator = NO;
    effectScrollView.delegate = self;
    [effectView addSubview:effectScrollView];
    
    float y = (effectScrollView.bounds.size.height - 64)/2.0;
    [effectArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake((kWIDTH - 64)/2.0 + (20 + 64)*idx, y, 64, 64);
        itemBtn.layer.cornerRadius = 32.0;
        itemBtn.layer.masksToBounds = YES;
        [itemBtn setImage:[UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"storyRecord/cover/%@", obj[@"name"]] Type:@"jpg"]] forState:UIControlStateNormal];
        itemBtn.tag = idx + 1;
        [itemBtn addTarget:self action:@selector(effectItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [effectScrollView addSubview:itemBtn];
    }];
    effectScrollView.contentSize = CGSizeMake((20 + 64)*(effectArray.count - 1) + kWIDTH, 0);
    
    UIButton *selectedEffectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    selectedEffectBtn.frame = CGRectMake((kWIDTH - 80)/2.0, 40 + (effectView.bounds.size.height - 40 - 80)/2.0, 80, 80);
    selectedEffectBtn.layer.cornerRadius = 40.0;
    selectedEffectBtn.layer.masksToBounds = YES;
    selectedEffectBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    selectedEffectBtn.layer.borderWidth = 5.0;
    [selectedEffectBtn addTarget:self action:@selector(tapRecordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [effectView addSubview:selectedEffectBtn];
    
    UILongPressGestureRecognizer* longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shootVideoAction:)];
    longGesture.minimumPressDuration = 0.3;
    [selectedEffectBtn addGestureRecognizer:longGesture];
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
        NSMutableArray *filterArray = [NSMutableArray array];
        for (int i = 0; i < 2; i++) {
            RDFilter* filter = [RDFilter new];
            filter.type = kRDFilterType_ACV;
            filter.filterPath = [RDHelpClass getResourceFromBundle:@"Filteracvs/原始" Type:@"acv"];
            [filterArray addObject:filter];
        }
        [_cameraManager addFilters:filterArray];
        [_cameraManager setFilterAtIndex:0];
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

- (void)faceUBtnAction:(UIButton *)sender {
    faceUView.hidden = NO;
    backBtn.hidden = YES;
}

- (void)albumBtnAction:(UIButton *)sender {
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
//        [myself addFileWithList:filelist withType:type touchConnect: isTouch];
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)tapRecordBtnAction:(UIButton *)sender {
    if (selectedRecordTypeIndex == 0) {
        WeakSelf(self);
        [_cameraManager takePhoto:UIImageOrientationUp block:^(UIImage *image) {
            [weakSelf takePhotoCompletion:image];
        }];
    }else if (selectedRecordTypeIndex == 1) {
        if (_cameraManager.recordStatus != VideoRecordStatusBegin) {
            [self recordBtnTouchDown];
        }
    }else {
        if (_cameraManager.recordStatus == VideoRecordStatusBegin) {
            [self recordBtnTouchUp];
            [_cameraManager stopRecording];
        }else {
            [self recordBtnTouchDown];
        }
    }
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

- (void)shootVideoAction:(UILongPressGestureRecognizer *) recognizer {
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        [self recordBtnTouchDown];
    }else if(selectedRecordTypeIndex != 1
             && (recognizer.state == UIGestureRecognizerStateEnded
             || recognizer.state == UIGestureRecognizerStateCancelled
             || recognizer.state == UIGestureRecognizerStateFailed)){
        [self recordBtnTouchUp];
        [_cameraManager stopRecording];
    }
}

- (void)recordBtnTouchDown {
    topView.hidden = YES;
    recordTypeView.hidden = YES;
    faceUBtn.hidden = YES;
    albumBtn.hidden = YES;
    if (selectedRecordTypeIndex == 2) {
        effectView.hidden = YES;
        recordBtn.hidden = NO;
        recordBtnCenterView.hidden = NO;
    }
    if (!recordProgressView) {
        recordProgressView = [[CircleView alloc]initWithFrame:CGRectMake((kWIDTH - 120)/2.0, recordTypeView.frame.origin.y - 120, 120, 120)];
        recordProgressView.progressColor = Main_Color;
        recordProgressView.progressWidth = 3.0;
        recordProgressView.progressBackgroundColor = [UIColor clearColor];
        [self.view insertSubview:recordProgressView belowSubview:recordBtn];
    }
    WeakSelf(self);
    [UIView animateWithDuration:0.3 animations:^{
        StrongSelf(self);
        strongSelf->recordBtn.frame = CGRectMake((kWIDTH - 120)/2.0, strongSelf->recordTypeView.frame.origin.y - 120, 120, 120);
        strongSelf->recordBtn.layer.cornerRadius = 60.0;
        strongSelf->recordBtnCenterView.frame = CGRectMake((kWIDTH - 44)/2.0, strongSelf->recordBtn.frame.origin.y + (120 - 44)/2.0, 44, 44);
        if (strongSelf->selectedRecordTypeIndex == 2) {
            strongSelf->recordBtnCenterView.layer.cornerRadius = 5.0;
        }else {
            strongSelf->recordBtnCenterView.layer.cornerRadius = 22.0;
        }
        strongSelf->repeatIV.frame = CGRectMake((44 - 25)/2.0, (44 - 25)/2.0, 25, 25);
    }];
    if (selectedRecordTypeIndex == 2) {
        NSDictionary *dic = effectArray[selectedEffectIndex];
        NSString *path = [[kRDStoryRecordDirectory stringByAppendingPathComponent:dic[@"folderName"]] stringByAppendingPathComponent:dic[@"updatetime"]];
        NSString *jsonPath = [path stringByAppendingPathComponent:@"config.json"];
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:jsonPath];
        NSMutableDictionary *configDic = [RDHelpClass objectForData:jsonData];
        jsonData = nil;
        
        NSString *musicFileName = [configDic[@"music"] objectForKey:@"fileName"];
        if(musicFileName.length > 0){
            NSURL *musicURL = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:musicFileName]];
            float start = [[configDic[@"music"] objectForKey:@"begintime"] floatValue];
            float duration = [[configDic[@"music"] objectForKey:@"duration"] floatValue];
            if (duration == 0) {
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:musicURL options:nil];
                duration = CMTimeGetSeconds(asset.duration) - start;
            }
            musicTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(start, TIMESCALE), CMTimeMakeWithSeconds(duration, TIMESCALE));
            
            NSError *error = nil;
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:&error];
            audioPlayer.currentTime = start;
            audioPlayer.delegate = self;
        }
        NSMutableArray *mvEffectArray = [NSMutableArray array];
        [configDic[@"effects"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *effectPath = [path stringByAppendingPathComponent:obj[@"fileName"]];
             NSString *shader = [obj objectForKey:@"filter"];
            RDCameraMVEffect *mvEffect = [[RDCameraMVEffect alloc] init];
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
            }
            mvEffect.url = [NSURL fileURLWithPath:effectPath];
            [mvEffectArray addObject:mvEffect];
        }];
        [_cameraManager setMVEffects:mvEffectArray];
        NSString *filterName = dic[@"filter"];
        if (filterName.length > 0) {
            RDFilter *filter = [RDFilter new];
            if (![[[filterName pathExtension] lowercaseString] isEqualToString:@"acv"]) {
                filter.type = kRDFilterType_LookUp;
            } else {
                filter.type = kRDFilterType_ACV;
            }
            filter.filterPath = [path stringByAppendingPathComponent:filterName];
            [_cameraManager resetFilter:filter AtIndex:1];
            [_cameraManager setFilterAtIndex:1];
        }else {
            [_cameraManager setFilterAtIndex:0];
        }
    }else {
        [_cameraManager setMVEffects:nil];
    }
    [_cameraManager beginRecording];
}

- (void)recordBtnTouchUp {
    [recordProgressView removeFromSuperview];
    recordProgressView = nil;
    recordBtn.hidden = YES;
    recordBtnCenterView.hidden = YES;
    WeakSelf(self);
    [UIView animateWithDuration:0.3 animations:^{
        StrongSelf(self);
        strongSelf->recordBtn.frame = CGRectMake((kWIDTH - 80)/2.0, strongSelf->recordTypeView.frame.origin.y - 100, 80, 80);
        strongSelf->recordBtn.layer.cornerRadius = 40.0;
        strongSelf->recordBtnCenterView.frame = CGRectMake((kWIDTH - 56)/2.0, strongSelf->recordBtn.frame.origin.y + (80 - 56)/2.0, 56, 56);
        strongSelf->recordBtnCenterView.layer.cornerRadius = 28.0;
        strongSelf->repeatIV.frame = CGRectMake((56 - 25)/2.0, (56 - 25)/2.0, 25, 25);
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

- (void)effectItemBtnAction:(UIButton *)sender {
    selectedEffectIndex = sender.tag - 1;
    currentEffectLbl.hidden = NO;
    currentEffectLbl.text = [NSString stringWithFormat:@" %@ ", [effectArray[selectedEffectIndex] objectForKey:@"name"]];
    [currentEffectLbl sizeToFit];
    CGRect frame = currentEffectLbl.frame;
    frame.origin.x = (kWIDTH - frame.size.width)/2.0;
    currentEffectLbl.frame = frame;
    float firstX = [effectScrollView viewWithTag:1].frame.origin.x;
    WeakSelf(self);
    [UIView animateWithDuration:0.3 animations:^{
        StrongSelf(self);
        strongSelf->effectScrollView.contentOffset = CGPointMake(sender.frame.origin.x - firstX, 0);
    }];
    [self performSelector:@selector(hiddenTipLbl:) withObject:currentEffectLbl afterDelay:1.5];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    faceUView.hidden = YES;
    backBtn.hidden = NO;
}

- (void)hiddenTipLbl:(UILabel *)label {
    label.hidden = YES;
}

#pragma mark - RDRecordTypeViewDelegate
- (void)selectedTypeIndex:(NSInteger)typeIndex {
    selectedRecordTypeIndex = typeIndex;
    if (selectedRecordTypeIndex == 0 || selectedRecordTypeIndex == 1) {//普通//重复
        recordBtn.hidden = NO;
        faceUBtn.hidden = NO;
        recordBtnCenterView.hidden = NO;
        if (selectedRecordTypeIndex == 1) {//重复
            albumBtn.hidden = YES;
            repeatIV.hidden = NO;
            normalRecordTipLbl.hidden = YES;
        }else {
            albumBtn.hidden = NO;
            normalRecordTipLbl.hidden = NO;
            [self performSelector:@selector(hiddenTipLbl:) withObject:normalRecordTipLbl afterDelay:1.5];
        }
        selectedEffectIndex = 0;
        currentEffectLbl.text = [NSString stringWithFormat:@" %@ ", [effectArray[selectedEffectIndex] objectForKey:@"name"]];
        [currentEffectLbl sizeToFit];
        CGRect frame = currentEffectLbl.frame;
        frame.origin.x = (kWIDTH - frame.size.width)/2.0;
        currentEffectLbl.frame = frame;
    }else {//聚焦
        recordBtn.hidden = YES;
        faceUBtn.hidden = YES;
        albumBtn.hidden = YES;
        recordBtnCenterView.hidden = YES;
        normalRecordTipLbl.hidden = YES;
        effectView.hidden = NO;
        [self performSelector:@selector(hiddenTipLbl:) withObject:currentEffectLbl afterDelay:1.5];
    }
    [UIView animateWithDuration:0.3 animations:^{
        if (selectedRecordTypeIndex == 0) {//普通
            effectScrollView.contentOffset = CGPointMake(-(kWIDTH - (kWIDTH - 64)/2.0), 0);
            effectView.hidden = YES;
            
            CGRect frame = repeatIV.frame;
            frame.origin.x = 56;
            repeatIV.frame = frame;
            repeatIV.hidden = YES;
        }else if (selectedRecordTypeIndex == 1) {//重复
            effectScrollView.contentOffset = CGPointMake(-(kWIDTH - (kWIDTH - 64)/2.0), 0);
            effectView.hidden = YES;
            
            CGRect frame = repeatIV.frame;
            frame.origin.x = (56 - 25)/2.0;
            repeatIV.frame = frame;
        }else {
            effectScrollView.contentOffset = CGPointMake(0, 0);
            
            CGRect frame = repeatIV.frame;
            frame.origin.x = 56;
            repeatIV.frame = frame;
            repeatIV.hidden = YES;
        }
    }];
}

#pragma mark - RDCameraManagerDelegate
- (void)cameraScreenDid{
    self.view.userInteractionEnabled = YES;
}

- (void)currentTime:(float)time {
    if (selectedRecordTypeIndex == 1) {
        float progress = time/cameraConfig.repeatRecordDuration;
        recordProgressView.percent = progress;
        if (time >= cameraConfig.repeatRecordDuration) {
            [_cameraManager stopRecording];
        }
    }else {
        if(audioPlayer.currentTime >=CMTimeGetSeconds(CMTimeAdd(musicTimeRange.start, musicTimeRange.duration))){
            audioPlayer.currentTime = CMTimeGetSeconds(musicTimeRange.start);
        }
        float progress = time/cameraConfig.cameraNotSquare_MaxVideoDuration;
        recordProgressView.percent = progress;
        if (time >= cameraConfig.cameraNotSquare_MaxVideoDuration) {
            [_cameraManager stopRecording];
        }
    }
}

- (void) movieRecordBegin {
    [audioPlayer play];
}

- (void)movieRecordingCompletion:(NSURL *)videoUrl {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    float duration = CMTimeGetSeconds(asset.duration);
    if(duration >0){
        asset = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (selectedRecordTypeIndex == 2 && duration < cameraConfig.cameraMinVideoDuration) {
                timeTipLbl.hidden = NO;
                [self performSelector:@selector(hiddenTipLbl:) withObject:timeTipLbl afterDelay:1.5];
                [self cancelRecord];
            }else {
                [self deleteItems];
                WeakSelf(self);
                [self dismissViewControllerAnimated:YES completion:^{
                    StrongSelf(self);
                    if(strongSelf.recordCompletionBlock){
                        strongSelf.recordCompletionBlock(videoUrl.path);
                    }
                }];
            }
        });
    }
}

- (void)movieRecordCancel{
    [self cancelRecord];
}

- (void) movieRecordFailed:(NSError *)error{
    NSLog(@"录制失败:%@",error);
    [self cancelRecord];
}

- (void)cancelRecord {
    [self recordBtnTouchUp];
    [_cameraManager setMVEffects:nil];
    [_cameraManager setFilterAtIndex:0];
    [audioPlayer stop];
    audioPlayer.delegate = nil;
    audioPlayer = nil;
    topView.hidden = NO;
    recordTypeView.hidden = NO;
    if (selectedRecordTypeIndex == 0 || selectedRecordTypeIndex == 1) {
        faceUBtn.hidden = NO;
        if (selectedRecordTypeIndex == 1) {
            albumBtn.hidden = NO;
        }
    }else {
        recordBtn.hidden = YES;
        recordBtnCenterView.hidden = YES;
        effectView.hidden = NO;
    }
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

- (void)getEffectArray {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:kRDStoryRecordDirectory]){
        [fileManager createDirectoryAtPath:kRDStoryRecordDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    NSString *plistPath = [RDHelpClass getResourceFromBundle:@"storyRecord/storyRecord" Type:@"plist"];
    effectArray = [NSArray arrayWithContentsOfFile:plistPath];
    [effectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *file = obj[@"folderName"];
        NSString *path = [kRDStoryRecordDirectory stringByAppendingPathComponent:file];
        NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:nil];
        
        NSString *fileCachePath = [[kRDStoryRecordDirectory stringByAppendingPathComponent:file] stringByAppendingPathComponent:obj[@"updatetime"]];
        NSString *cacheFolderPath = [[[[plistPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"material"] stringByAppendingPathComponent:obj[@"folderName"]] stringByAppendingPathExtension:@"zip"];
        if(files.count == 0){
            [RDHelpClass OpenZipp:cacheFolderPath unzipto:fileCachePath];
        }else {
            NSString *oldUpdatetime;
            for (NSString *fileName in files) {
                if (![fileName isEqualToString:@"__MACOSX"]) {
                    NSString *folderPath = [path stringByAppendingPathComponent:fileName];
                    BOOL isDirectory = NO;
                    BOOL isExists = [fileManager fileExistsAtPath:folderPath isDirectory:&isDirectory];
                    if (isExists && isDirectory) {
                        oldUpdatetime = fileName;
                        break;
                    }
                }
            }
            if (![oldUpdatetime isEqualToString:obj[@"updatetime"]]) {
                [fileManager removeItemAtPath:path error:nil];
                [RDHelpClass OpenZipp:cacheFolderPath unzipto:fileCachePath];
            }
        }
    }];
    [self initEffectView];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_cameraManager.recordStatus == VideoRecordStatusBegin){
            audioPlayer.currentTime = CMTimeGetSeconds(musicTimeRange.start);
            [audioPlayer play];
        }
    });
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self resetContenOffset:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self resetContenOffset:scrollView];
}

- (void)resetContenOffset:(UIScrollView *)scrollView {
    float firstX = [scrollView viewWithTag:1].frame.origin.x;
    WeakSelf(self);
    [scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            if (firstX + scrollView.contentOffset.x <= obj.frame.origin.x + (obj.bounds.size.width + 20)/2.0) {
                [weakSelf effectItemBtnAction:(UIButton *)obj];
                *stop = YES;
            }
        }
    }];
}

- (void) deleteItems{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_cameraManager stopCamera];
    [_cameraManager deleteItems];
    _cameraManager.delegate = nil;
    _cameraManager = nil;
    [audioPlayer stop];
    audioPlayer.delegate = nil;
    audioPlayer = nil;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    
    RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
    if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(destroyFaceU)]) {
        [nv.rdVeUiSdkDelegate destroyFaceU];
    }
}

@end
