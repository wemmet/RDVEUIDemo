//
//  ViewController.m
//  RDVEDemo
//
//  Created by wuxiaoxia on 2017/7/15.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "ViewController.h"
#import "UIButton+Block.h"
#import "PlayVideoController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHPhotoLibrary.h>
#import <Photos/Photos.h>
#import "MainCropViewController.h"
#import "AboutSDKViewController.h"
#import "FaceUManager.h"
#import <CoreServices/CoreServices.h>

//选择相册类型
typedef NS_ENUM(NSInteger, AddFileType){
    addVideoAndImages,
    addVideo,
    addImage
};

#define PHOTO_ALBUM_NAME @"RDVEUISDKDemo"
#define VideoAverageBitRate 5.0
#define CUTVIDEOTYPALERTTAG 200

#define FaceUURL  @"http://dianbook.17rd.com/api/shortvideo/getfaceprop2"
#define MVResourceURL @"http://dianbook.17rd.com/api/shortvideo/getmvprop3"
#define MusicResourceURL  @"http://dianbook.17rd.com/api/shortvideo/getbgmusic"
#define CloudMusicResourceURL @"http://dianbook.17rd.com/api/shortvideo/getcloudmusic" //官方配置的云音乐

//素材管理
#define kNewResourceURL [NSBundle isEnglishLanguage]?@"http://d.56show.com/filemanage2/public/file_en/file/appdata":@"http://d.56show.com/filemanage2/public/filemanage/file/appData"
#define kNetMaterialTypeURL [NSBundle isEnglishLanguage]?@"http://d.56show.com/filemanage2/public/file_en/file/typedata":@"http://d.56show.com/filemanage2/public/filemanage/file/typeData"//获取网络素材分类
//MV素材管理
#define kNewmvResourceURL           kNewResourceURL
//背景音乐素材管理
#define kNewmusicResourceURL        kNewResourceURL
//滤镜素材管理
#define kFilterResourceURL          kNewResourceURL
//字幕素材管理
#define kSubtitleResourceURL        kNewResourceURL
//贴纸素材管理
#define kEffectResourceURL          kNewResourceURL
//特效素材管理
#define kSpecialEffectResourceURL   kNewResourceURL
//字体素材管理
#define kFontResourceURL            kNewResourceURL
//转场素材管理
#define kTransitionResourceURL      kNewResourceURL
//云音乐素材管理
#define kCloudMusicResourceURL      kNewResourceURL
//音效素材管理 分类获取
#define kSoundMusicTypeResourceURL      kNetMaterialTypeURL
//音效素材管理 下载地址
#define SoundMusicResourceURL [NSBundle isEnglishLanguage]?@"http://d.56show.com/filemanage2/public/file_en/file/cloudMusicData":@"http://d.56show.com/filemanage2/public/filemanage/file/cloudMusicData"

//腾讯云AI识别账号配置
#define kTencentCloudAppId @"1259660397"
#define kTencentCloudSecretId @"AKIDmOlskNuJdiY8Sqhxf8LI5wXtzpQ63K4Y"
#define kTencentCloudSecretKey @"OXQcYEiwusa1EAqGPIxM5apoXzCBuACy"
#define kTencentCloudServerCallbackPath @"http://d.56show.com/filemanage2/public/filemanage/voice2text/audio2text4tencent"

@interface ViewController (){    
    //拍摄设置
    UISwitch    *_hiddenPhotoLibrarySwitchBtn;
    UILabel     *_hiddenPhotoLibraryswitchLabel;
    UISwitch    *_enableUseMusicSwitchBtn;
    UILabel     *_enableUseMusicLable;
    UIView      *_camerapositionSettingView;
    UIButton    *_cameraMVBtn;
    UIView      *_cameraMixedSettingView;
    UIView      *_MVRecordSettingView;
    UIButton    *_cameraVideoBtn;
    UIView      *_cameraDurationSettingView;
    UIButton    *_cameraPhotoBtn;
    UIView      *_cameraModelSettingView;
    UIView      *_cameraWriteToAlbumSettingView;
    UIView      *_cameraFaceUSettingView;
    UIView      *_cameraWaterMarkSettingView;
    
    //视频编辑设置
    UISwitch    *_switchBtn;
    UILabel     *_wizardLabel;
    UIView      *_editExportSettingView;
    UIView      *_fragmentEditSettingView;
    UIView      *_proportionSettingView;
    UIButton    *_fragmentEditBtn;
    UIView      *_supportFiletypeView;
    UIView      *_dubbingSettingView;
    UIView      *_videoMaxDurationView;
    UIView      *_inputVideoMaxDurationView;
    UIButton    *_endPicDisabledBtn;
    UIView      *_endPicSettingView;
    UIView      *_waterSettingView;
    UIView      *_waterPositionView;
    UIButton    *_waterSettingBtn;
    UITextField *_exportVideoMaxDurationField;
    UITextField *_inputVideoMaxDurationField;
    
    //截取设置
    UIView      *_trimActionSettingView;
    UIView      *_trimTimeSettingView;
    UIView      *_trimVideoProportionSettingView;
    
    //相册设置
    UISwitch    *_enableAlbumCameraBtnSwitchBtn;
    UILabel     *_enableAlbumCameraBtnswitchLabel;
    UIView      *_mediaCountLimitView;
    UITextField *_mediaCountLimitField;
    
    UIImageView     *cameraWaterView;
    
    AddFileType _addFileType;
}
@property(nonatomic,strong)RDVEUISDK    *edittingSdk;
@property(nonatomic,strong)RDVEUISDK    *shortVideoSdk;
@end

@implementation ViewController

//com.dy.fengniao.mt
//NSString *const APPKEY =  @"959963e2cc0448ce";
//NSString *const APPSECRET = @"ae51fc410d9dac989ac4f9055fb89b10KavfO/JPFowf4+YQ0EWz7d+HBGFGpjiDPc2CWv9EcPFLx5VMoljITAoIFmZyYIPFT/L5y+UZSh5UxU1pY7Ek83E2RruilT8IcaJSZItV+rb83pjf5DzOgiIydfvS0nNDwiG6k3QxyifmSzGnstwtri8czKpMPgaapna0YLTvVCFBGqg658+l7/JTGbFdSTz1";
//NSString *const LICENCEKEY = @"";

//com.qmhy.ttjj
//NSString *const APPKEY =  @"44c025596365824d";
//NSString *const APPSECRET = @"0e7dee355c85d4e91ad257bc82860095mJccH8yhjchKmfCByI8oX6OKjqrOhLlhD0Gcb+R3fiFETpMQ8UJpb1kRaJ34VNgJzgTjFieZYG7XQmo/gb2m0W8MrHKa3l5lzsKNZazZEfuWHmK7Wlm+IzFs1mARn1RcXg/aYTa2hQ2C/WfjiI3VGLJvgpSY4Gjp4YvSWbgC0h2i/Rj25n52hUkBdm8TqvPU";
//NSString *const LICENCEKEY = @"";


//com.rd.RDVideoEditUIDemo
NSString *const APPKEY =  @"6ecb39f1c12f1a35";
NSString *const APPSECRET = @"22a44768806a23466dd52ecf954ed6b26sICMKN8iw707KYMWLkJoNaMxb5Xal+afScFJ8/exLzxx1bY5Te7WqZzRD6k4EcUwwJ8a8+AeCO/WSG2qUzso/7u0l758MUsfPzjz7Ih2BY=";
NSString *const LICENCEKEY = @"CSRWXI-JLCZHC-GBVAGX-QJBGRD";

//NSString *const APPKEY =  @"dc8c35492a5e8ccc";
//NSString *const APPSECRET = @"bc1881461c91257c72d0559d6f66ef6dR8jQKLSoEdVgr+hwwEzCU01tG/oQgSuqsEwChG8974nBTYhR7vZGUPwD5MC+H3hLxCb3FiTgTlaxmC2wdy+s76slMrE7k3fgtnXXhMP51PUBaUFRko5ah9vdYDhWf7Ylq4fCqxyzXqAqRdMMtk3Gk0pvBCWKeBnfh/8hFuziT1AZF52nucWFigt0WYX8uK1yhFqJ/4SZ/VEk5vZxGCrsHz+A+5sbiO8T7r2HflJs0yYsENWVdHf5JasI75bewTNT71sluCS1HLabdOtAHs99jciQ80Vd2tO4Igstedlbll4wuxa8FTdXV48gzMHEOcnxJcqMxPML1MSmfuXaXk2HmnV0W1oaWqTIeyO56uoXbnvLsEm4lkzz+ZuoPVV9EPPXMMECtlPeo7cQRJtsKl46ZUAVAjv7a9tbHGLq4js2mFBsqb5RSRN6zB6rjL9RZO2jJk2L7jrAxsL/MbsNIDtyjRtqGDZTkAdC/4qKky/cJ/buvmlUUCByPGLb37Bre4IFnj0/UVA96OGlDwRiWEmpuKquM1XXlXAlbH+eo1vtkaU=";
//NSString *const LICENCEKEY = @"";

//com.17rd.RDVideoEditUIDemo
//NSString *const APPKEY =  @"8cb81dcda440136a";
//NSString *const APPSECRET = @"9ec81b33ca85c9df881750839600346f5drNIyuajvF43FDGVR+ygaBb14Ut8TjBZoAiR063mfqXP5Q3OlTuxuifadTK8bPtNglAx1sZ4+x+Npo9xR8HPaEs5DmKmoGiPIuS5lLNnwzF26ob/PQa2QfuwYnlsp87RSlJOurlyPF5noPbSOcNjHcfNVD19m7kY7fdKo9h8zKSYWMOY/yoskVLU3LnyKRX1SqSUeuzK5qMrAKnVVe3x3T7akamW4mViPITpYG2XCkY6y4Z6sa/YnNKk0IXdfr150r3+A5SPonOvE2PXV2F2NYZYi/P9HGQBnvL6Ekx1p24w64AagI5KjP0/biYAXT7phtWTZyAqbDwiQAAyqYS0niQm4wjbz7oUMn3kz61UgMn0Be4oZKr2JfU7vYvf1J/hCH+uibR1YXUuSeDVMdBps94y1fgTWJxcXGi/+W6fONqNeknjT5Ko3aaG6meed1JPCg6pA2FxKszVGTabmH8lIZlLoOw8PEIfj5u8U9tnfE=";

//com.17rd.editvideoSDK
//NSString *const APPKEY =  @"d7beff1d70c735d2";
//NSString *const APPSECRET = @"6428002b7a53c0d97de7ae183c716260pUrA8+eap++1mLwrbKqPa8Ai6R0B89gkSWp556Zgry4Nzg0VNoZiIOXH6G4o/HJJFSm3ShaPcaCNW0brGIKa0RDqcwb7YMpYfjyvgcL4njQ=";

//com.17rd.VEPRO
//NSString *const APPKEY =  @"b8ab6091f6c68b4c";
//NSString *const APPSECRET = @"6711221671f15b7b67620cfde6fac092AZ7RdVMgjumEUeURdoRoXkh3t4r7Sv9L8358t9z1ObC4WjbmFViEy3Cnm5RA1ezJWpD6AasfdvXQxLGc6apQuEWIvBQZR5xX5UdfF8i7Cn81IiKjXkvoAAYrbO9qej9PVY46xVW15DCIQNKqrXQt1fKw/05mLOdhBMOdWy0PHhDsmD5RL2aXxw4PuICd+f0cG7uxeToUjM6wzHn9mjuOkQVqGLO/vZfHc4G04PWaUZnik0GU1Wch40n6zL4Hk/3ZaOicVnhkd7Rr42vw32SgldMKgfV/Ot51cw5rYpZQQKc+qd6PeIKsx0s3bXeqLx0onjxQzwAZTgfIcrnNvOpaTNVSC6LxVbXrGXcjYXiKJgAz9c3jQrc5TVLXhdIciemwDm1HD/Zh6jJvEad/K6tT73sk2uOYVK7nVZxNhgTNlrmFRsz1Oma1T+bMXx7v9iKbBnfruzUNUE+tjrceGdatHzb7vREK/Ia8TWmTQzAT+so=";

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationItem setHidesBackButton:YES];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.navigationController.navigationBar.barTintColor=UIColorFromRGB(0x0e0e10);
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    self.view.backgroundColor = UIColorFromRGB(0x33333b);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(alertView.tag == CUTVIDEOTYPALERTTAG){
        if(buttonIndex == 1){
            [_edittingSdk trimVideoWithType:RDCutVideoReturnTypeTime];
        }else{
            [_edittingSdk trimVideoWithType:RDCutVideoReturnTypePath];
        }
    }
}

- (void)rightItemOnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [NSBundle setLanguage:@"en"];
        [[NSUserDefaults standardUserDefaults] setObject:@"en" forKey:@"AppLanguage"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else {
        [NSBundle setLanguage:@"zh-Hans"];
        [[NSUserDefaults standardUserDefaults] setObject:@"zh-Hans" forKey:@"AppLanguage"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.title = NSLocalizedString(@"iOS视频编辑SDK", nil);
    [_functionListTable reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.modalPresentationStyle =  UIModalPresentationFullScreen;
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden=NO;
    self.navigationController.navigationBar.translucent=NO;
    [self.navigationController setNavigationBarHidden: NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.title = NSLocalizedString(@"iOS视频编辑SDK", nil);
    
    UIButton *leftItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftItemBtn.frame = CGRectMake(0, 0, 44, 44);
    [leftItemBtn setImage:[UIImage imageNamed:@"邮箱"] forState:UIControlStateNormal];
    [leftItemBtn addTarget:self action:@selector(leftItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarItem = [[UIBarButtonItem alloc] initWithCustomView:leftItemBtn];
    self.navigationItem.leftBarButtonItem = leftBarItem;
    
    UIButton *rightItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightItemBtn.frame = CGRectMake(0, 0, 64, 44);
    [rightItemBtn setTitle:@"中文" forState:UIControlStateNormal];
    [rightItemBtn setTitle:@"English" forState:UIControlStateSelected];
    if ([NSBundle isEnglishLanguage]) {
        rightItemBtn.selected = YES;
        [NSBundle setLanguage:@"en"];
    }
    [rightItemBtn addTarget:self action:@selector(rightItemOnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithCustomView:rightItemBtn];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    
    cameraWaterView = [UIImageView new];
    cameraWaterView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    
    [self createRDVEUISDKAlbum];
    RDVEUISDK *rdveUISDK = [self createSdk];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Function"ofType:@"plist"];
    _functionList = [NSMutableArray arrayWithContentsOfFile:plistPath];
//    [functions_8 addObject:NSLocalizedString(@"(1) MTS 转 MP4", nil)];
//    [functions_Dic8 setObject:NSLocalizedString(@"视频格式转换", nil) forKey:@"title"];
//    [functions_Dic8 setObject:functions_8 forKey:@"functionList"];
//    [functions_9 addObject:NSLocalizedString(@"(1) 随拍", nil)];
//    [functions_9 addObject:NSLocalizedString(@"(1) 录制", nil)];
//    [functions_Dic9 setObject:NSLocalizedString(@"抖音录制", nil) forKey:@"title"];
    
    CGRect rect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
    _functionListTable = [[UITableView alloc] initWithFrame:rect style:UITableViewStyleGrouped];
    _functionListTable.backgroundView = nil;
    _functionListTable.backgroundColor = [UIColor clearColor];
    _functionListTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _functionListTable.delegate = self;
    _functionListTable.dataSource = self;
    [_functionListTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"] ;
    [self.view addSubview:_functionListTable];
    UIView *headView = [UIView new];
    headView.frame = CGRectMake(0, 0, rect.size.width, 20);
    _functionListTable.tableHeaderView = headView;
    if (@available(iOS 11.0, *)) {
        _functionListTable.estimatedRowHeight = 0;
        _functionListTable.estimatedSectionFooterHeight = 0;
        _functionListTable.estimatedSectionHeaderHeight = 0;
    }
}

- (void)leftItemBtnAction:(UIButton *)sender {
    AboutSDKViewController *aboutVC = [[AboutSDKViewController alloc] init];
    [self.navigationController pushViewController:aboutVC animated:YES];
}

- (void)waterMarkProcessingCompletionBlockWithtype:(NSInteger )type status:(RecordStatus)status WithView:(UIView *)view withTime:(float)time{
//    view.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    [view addSubview:cameraWaterView];
    
    float width = view.frame.size.width;
    float height = (type == 1 ? view.frame.size.width : view.frame.size.height);
    
    cameraWaterView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"waterImage1@3x.png" ofType:@""]];

    if(time<4){
        cameraWaterView.frame = CGRectMake(0,0, cameraWaterView.image.size.width, cameraWaterView.image.size.height);
    }else if(time<4*2){
        cameraWaterView.frame = CGRectMake((width - cameraWaterView.image.size.width), 0, cameraWaterView.image.size.width, cameraWaterView.image.size.height);
    }else if(time<4*3){
        cameraWaterView.frame = CGRectMake((width - cameraWaterView.image.size.width), (height - cameraWaterView.image.size.height), cameraWaterView.image.size.width, cameraWaterView.image.size.height);
    }else if(time<4*4){
        cameraWaterView.frame = CGRectMake(0, (height - cameraWaterView.image.size.height), cameraWaterView.image.size.width, cameraWaterView.image.size.height);
    }else{
        cameraWaterView.frame = CGRectMake((width - cameraWaterView.image.size.width)/2.0, (height - cameraWaterView.image.size.height)/2.0, cameraWaterView.image.size.width, cameraWaterView.image.size.height);
    }
    
//    cameraWaterView.textAlignment = NSTextAlignmentCenter;
//    cameraWaterView.text = [self timeFormat:time];
//    cameraWaterView.font = [UIFont systemFontOfSize:22];
    switch (status) {
        case RecordHeader:
            {
                //cameraWaterView.textColor = [UIColor redColor];
                //cameraWaterView.image = _waterHeader;
                //cameraWaterView.frame = CGRectMake((width - _waterHeader.size.width)/2.0, (height - _waterHeader.size.height)/2.0, _waterHeader.size.width, _waterHeader.size.height);
//                NSLog(@"片头");
            }
            break;
        case Recording:
        {
            //cameraWaterView.alpha = 0;
            //cameraWaterView.textColor = [UIColor yellowColor];
            //cameraWaterView.image = _waterBody;
            //cameraWaterView.frame = CGRectMake((width - _waterBody.size.width)/2.0, (height - _waterBody.size.height)/2.0, _waterBody.size.width, _waterBody.size.height);
//            NSLog(@"片中间");
        }
            break;
        case RecordEnd:
        {
            //cameraWaterView.alpha = 1.0;
            //cameraWaterView.textColor = [UIColor whiteColor];
            //cameraWaterView.image = _waterFooter;
            //cameraWaterView.frame = CGRectMake((width - _waterFooter.size.width)/2.0, (height - _waterFooter.size.height)/2.0, _waterFooter.size.width, _waterFooter.size.height);
//            NSLog(@"片尾");
        }
            break;
        default:
            break;
    }
}


- (RDVEUISDK*)createSdk{
    
    //初始化
    RDVEUISDK*rdVESDK = [[RDVEUISDK alloc] initWithAPPKey:APPKEY APPSecret:APPSECRET LicenceKey:LICENCEKEY resultFail:^(NSError *error) {
        NSLog(@"error:%@",error);
    }];
    if ([NSBundle isEnglishLanguage]) {
        rdVESDK.language = ENGLISH;
    }else {
        rdVESDK.language = CHINESE;
    }
//    rdVESDK.mainColor = [UIColor magentaColor];
    rdVESDK.delegate = self;
    //是否需要定制功能
    rdVESDK.editConfiguration.enableWizard                = false;
    //设置编辑所支持的文件类型
    rdVESDK.editConfiguration.supportFileType             = SUPPORT_ALL;
    rdVESDK.editConfiguration.defaultSelectAlbum          = RDDEFAULTSELECTALBUM_VIDEO;
    //设置相册最大选择张数
    rdVESDK.editConfiguration.mediaCountLimit              = 0;
    rdVESDK.editConfiguration.proportionType                = RDPROPORTIONTYPE_AUTO;
    
    //定长截取设置
    rdVESDK.editConfiguration.trimMinDuration_TwoSpecifyTime    = 12.0;
    rdVESDK.editConfiguration.trimMaxDuration_TwoSpecifyTime    = 30.0;
    rdVESDK.editConfiguration.defaultSelectMinOrMax             = kRDDefaultSelectCutMax;
    
    rdVESDK.editConfiguration.presentAnimated                 = true;
    rdVESDK.editConfiguration.dissmissAnimated                = true;
    //拍摄设置    
//    rdVESDK.cameraConfiguration.captureAsYUV                = false;
    rdVESDK.cameraConfiguration.cameraRecord_Type           = RecordType_Video;
    rdVESDK.cameraConfiguration.cameraSquare_MaxVideoDuration = 0;
    rdVESDK.cameraConfiguration.cameraNotSquare_MaxVideoDuration = 0;
    rdVESDK.cameraConfiguration.cameraRecordSizeType        = RecordVideoTypeMixed;
    rdVESDK.cameraConfiguration.cameraRecordOrientation     = RecordVideoOrientationAuto;
    rdVESDK.cameraConfiguration.cameraCollocationPosition   = CameraCollocationPositionBottom;
    NSString * exportPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recordVideoFile.mp4"];
    rdVESDK.cameraConfiguration.cameraOutputPath = exportPath;
    
    //设置faceUnity
    rdVESDK.cameraConfiguration.enableFaceU         = false;
    rdVESDK.cameraConfiguration.faceUURL            = FaceUURL;
    rdVESDK.cameraConfiguration.enableNetFaceUnity  = true;
    
    rdVESDK.cameraConfiguration.enableFilter        = true;
    rdVESDK.cameraConfiguration.hiddenPhotoLib      = false;
    //相机水印相关设置
//    rdVESDK.cameraConfiguration.enabelCameraWaterMark   = false;
    rdVESDK.cameraConfiguration.cameraWaterMarkHeaderDuration = 3.0;
    rdVESDK.cameraConfiguration.cameraWaterMarkEndDuration = 2.0;
    rdVESDK.cameraConfiguration.cameraWaterProcessingCompletionBlock = ^(NSInteger type, RecordStatus status, UIView *waterMarkview, float time) {
        [self waterMarkProcessingCompletionBlockWithtype:type status:status WithView:waterMarkview withTime:time];
    };
    //录制界面播放音乐， 如果需要切换音乐请设置好音乐下载路径,不设置则跳转到本地音乐界面 （editConfiguration.cloudMusicResourceURL）
    rdVESDK.cameraConfiguration.enableUseMusic     = true;
#if 0
    NSString *path = [[NSBundle mainBundle] pathForResource:@"huiyi" ofType:@"mp3"];
    RDMusicInfo *musicInfo = [RDMusicInfo new];
    musicInfo.url = [NSURL fileURLWithPath:path];
    musicInfo.name = @"回忆";
    musicInfo.clipTimeRange = kCMTimeRangeZero;
    rdVESDK.cameraConfiguration.musicInfo = musicInfo;
#endif
    //编辑导出设置
    rdVESDK.exportConfiguration.videoBitRate    = VideoAverageBitRate;
    rdVESDK.exportConfiguration.endPicDisabled  = false;
    rdVESDK.exportConfiguration.endPicUserName  = @"rd.56show.com";
    rdVESDK.exportConfiguration.endPicImagepath = [[NSBundle mainBundle] pathForResource:@"RDVEUISDK.bundle/resourceItems/resourceItem/pianweicaise/片尾caise_03" ofType:@"png"];
    
    rdVESDK.exportConfiguration.waterDisabled       = false;
    rdVESDK.exportConfiguration.waterImage          = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"waterImage" ofType:@"png"]];
    //rdVESDK.exportConfiguration.waterText = @"Hello My World";
    rdVESDK.exportConfiguration.waterPosition       = WATERPOSITION_LEFTTOP;
    rdVESDK.editConfiguration.enableMV              = false;
    rdVESDK.editConfiguration.netMaterialTypeURL    = kNetMaterialTypeURL;
    rdVESDK.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    rdVESDK.editConfiguration.newmusicResourceURL   = kNewmusicResourceURL;
    rdVESDK.editConfiguration.filterResourceURL     = kFilterResourceURL;
    rdVESDK.editConfiguration.subtitleResourceURL   = kSubtitleResourceURL;
    rdVESDK.editConfiguration.effectResourceURL     = kEffectResourceURL;
    rdVESDK.editConfiguration.fontResourceURL       = kFontResourceURL;
    rdVESDK.editConfiguration.transitionURL         = kTransitionResourceURL;
    rdVESDK.editConfiguration.cloudMusicResourceURL =  kCloudMusicResourceURL;
    rdVESDK.editConfiguration.newartist             = NSLocalizedString(@"音乐家 Jason Shaw", nil);
    rdVESDK.editConfiguration.newartistHomepageTitle= @"@audionautix.com";
    rdVESDK.editConfiguration.newartistHomepageUrl  = @"https://audionautix.com";
    rdVESDK.editConfiguration.newmusicAuthorizationTitle= NSLocalizedString(@"授权证书", nil);
    rdVESDK.editConfiguration.newmusicAuthorizationUrl = @"http://d.56show.com/accredit/accredit.jpg";
    rdVESDK.editConfiguration.soundMusicTypeResourceURL =  kSoundMusicTypeResourceURL;
    rdVESDK.editConfiguration.soundMusicResourceURL =   SoundMusicResourceURL;
    rdVESDK.editConfiguration.specialEffectResourceURL = kSpecialEffectResourceURL;
    rdVESDK.editConfiguration.enableAIRecogSubtitle = true;
    rdVESDK.editConfiguration.tencentAIRecogConfig.appId = kTencentCloudAppId;
    rdVESDK.editConfiguration.tencentAIRecogConfig.secretId = kTencentCloudSecretId;
    rdVESDK.editConfiguration.tencentAIRecogConfig.secretKey = kTencentCloudSecretKey;
    rdVESDK.editConfiguration.tencentAIRecogConfig.serverCallbackPath = kTencentCloudServerCallbackPath;
    
    rdVESDK.editConfiguration.enableLocalMusic      = true;
    rdVESDK.editConfiguration.enableTransition      = true;
    //rdVESDK.editConfiguration.enableEffectsVideo              = false;
    if(!_rdVEEditSDKConfigData)
        _rdVEEditSDKConfigData = [self newConfig:rdVESDK];
    if(!_rdVECameraSDKConfigData)
        _rdVECameraSDKConfigData = [self newConfig:rdVESDK];
    if(!_rdVETrimSDKConfigData)
        _rdVETrimSDKConfigData = [self newConfig:rdVESDK];
    if(!_rdVESelectAlbumSDKConfigData)
        _rdVESelectAlbumSDKConfigData = [self newConfig:rdVESDK];
    
    return rdVESDK;
}

-(RDVEUISDK*)createShortSdk{
    
    
#if 1
    //短视频
    RDVEUISDK*shortSdk = [[RDVEUISDK alloc] initWithAPPKey:APPKEY APPSecret:APPSECRET LicenceKey:LICENCEKEY resultFail:^(NSError * _Nonnull error) {
        
    }];
    if ([NSBundle isEnglishLanguage]) {
        shortSdk.language = ENGLISH;
    }else {
        shortSdk.language = CHINESE;
    }
    shortSdk.delegate = self;
    shortSdk.editConfiguration.enableMV = true;//启用MV功能
    shortSdk.editConfiguration.enableDubbing = false;
    shortSdk.editConfiguration.enableDewatermark = false;
    shortSdk.editConfiguration.enableSoundEffect = false;
    shortSdk.editConfiguration.enableEffectsVideo = false;
    shortSdk.editConfiguration.enableCollage = false;
    shortSdk.editConfiguration.enableBackgroundEdit = false;
    shortSdk.editConfiguration.enablePicZoom = false;
    shortSdk.editConfiguration.enableFragmentedit = false;
    shortSdk.editConfiguration.enableSubtitle = false;
    shortSdk.editConfiguration.enableSticker = false;
    shortSdk.editConfiguration.enableEffect = false;
    shortSdk.editConfiguration.enableCover = false;
    shortSdk.editConfiguration.enableDoodle = false;
    shortSdk.editConfiguration.dubbingType = RDDUBBINGTYPE_SECOND;
    shortSdk.editConfiguration.mediaCountLimit = 1;//相册最多选择媒体资源个数
    shortSdk.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;//设置媒体类型
    shortSdk.editConfiguration.trimMode = TRIMMODESPECIFYTIME_ONE;
    shortSdk.editConfiguration.trimDuration_OneSpecifyTime = 15.0;
    shortSdk.editConfiguration.trimExportVideoType = TRIMEXPORTVIDEOTYPE_SQUARE;
    shortSdk.exportConfiguration.endPicDisabled = true;
    shortSdk.exportConfiguration.waterDisabled = true;
    
    NSString * exportPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recordVideoFile.mp4"];
    shortSdk.cameraConfiguration.cameraOutputPath           = exportPath;
    shortSdk.cameraConfiguration.cameraOutputSize           = CGSizeZero;//自动根据设备设置大小传入CGSizeZero
    shortSdk.cameraConfiguration.cameraRecordSizeType       = RecordVideoTypeSquare;//设置输出视频是正方形
    shortSdk.cameraConfiguration.cameraRecordOrientation    = RecordVideoOrientationAuto;//设置界面方向（竖屏还是横屏）
    shortSdk.cameraConfiguration.cameraRecord_Type          = RecordType_MVVideo;
    shortSdk.cameraConfiguration.cameraMV_MaxVideoDuration  = 15.0;
    shortSdk.cameraConfiguration.cameraMV_MinVideoDuration  = 3.0;
    shortSdk.cameraConfiguration.cameraMV                   = true;
    shortSdk.cameraConfiguration.cameraVideo                = false;
    shortSdk.cameraConfiguration.cameraPhoto                = false;
    shortSdk.editConfiguration.netMaterialTypeURL    = kNetMaterialTypeURL;
    shortSdk.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    shortSdk.editConfiguration.newmusicResourceURL   = kNewmusicResourceURL;
    shortSdk.editConfiguration.filterResourceURL     = kFilterResourceURL;
    shortSdk.editConfiguration.subtitleResourceURL   = kSubtitleResourceURL;
    shortSdk.editConfiguration.effectResourceURL     = kEffectResourceURL;
    shortSdk.editConfiguration.fontResourceURL       = kFontResourceURL;
    shortSdk.editConfiguration.transitionURL         = kTransitionResourceURL;
    shortSdk.editConfiguration.cloudMusicResourceURL =  kCloudMusicResourceURL;
    shortSdk.editConfiguration.newartist             = NSLocalizedString(@"音乐家 Jason Shaw", nil);
    shortSdk.editConfiguration.newartistHomepageTitle= @"@audionautix.com";
    shortSdk.editConfiguration.newartistHomepageUrl  = @"https://audionautix.com";
    shortSdk.editConfiguration.newmusicAuthorizationTitle= NSLocalizedString(@"授权证书", nil);
    shortSdk.editConfiguration.newmusicAuthorizationUrl = @"http://d.56show.com/accredit/accredit.jpg";
    shortSdk.editConfiguration.soundMusicTypeResourceURL =  kSoundMusicTypeResourceURL;
    shortSdk.editConfiguration.soundMusicResourceURL =   SoundMusicResourceURL;
    shortSdk.editConfiguration.specialEffectResourceURL = kSpecialEffectResourceURL;
    
    return shortSdk;
    
#else
    bool isMV = true;
    NSUInteger inter = [[NSDate date] timeIntervalSince1970];
    //短视频
    RDVEUISDK*_xpkSDK = [[RDVEUISDK alloc] initWithAPPKey:APPKEY LicenceKey:LICENCEKEY APPSecret:APPSECRET resultFail:^(NSError * _Nonnull error) {
        
    }];
    NSString * exportPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Video_%ld.mp4",inter]];
    
    _xpkSDK.editConfiguration.enableFragmentedit = !isMV;
    _xpkSDK.editConfiguration.defaultSelectAlbum          = RDDEFAULTSELECTALBUM_VIDEO;
    _xpkSDK.editConfiguration.enableMV = isMV;
    _xpkSDK.editConfiguration.enableFragmentedit = true;
    _xpkSDK.editConfiguration.enableSubtitle = true;
    _xpkSDK.editConfiguration.enableSticker = true;
    _xpkSDK.editConfiguration.dubbingType = RDDUBBINGTYPE_SECOND;
    _xpkSDK.editConfiguration.mediaCountLimit = isMV?1:9;//相册最多选择媒体资源个数
    _xpkSDK.editConfiguration.supportFileType = SUPPORT_ALL;//设置媒体类型
    _xpkSDK.editConfiguration.trimMode = TRIMMODESPECIFYTIME_TWO;
    
    _xpkSDK.editConfiguration.trimExportVideoType = isMV?TRIMEXPORTVIDEOTYPE_SQUARE:TRIMEXPORTVIDEOTYPE_ORIGINAL;
    
    _xpkSDK.editConfiguration.trimMinDuration_TwoSpecifyTime    = 3.0;
    
    _xpkSDK.cameraConfiguration.cameraSquare_MaxVideoDuration = 300.0;
    _xpkSDK.cameraConfiguration.cameraNotSquare_MaxVideoDuration = 300.0;
    _xpkSDK.cameraConfiguration.cameraMinVideoDuration = 3.0;
    _xpkSDK.cameraConfiguration.cameraOutputPath = exportPath;
    _xpkSDK.cameraConfiguration.cameraOutputSize = CGSizeZero;//设置输出视频大小
    _xpkSDK.cameraConfiguration.cameraFrameRate = 2.0;
    _xpkSDK.cameraConfiguration.cameraRecordSizeType = isMV ? RecordVideoTypeSquare: RecordVideoTypeMixed;//MV正方形 短视频可切换
    _xpkSDK.cameraConfiguration.cameraRecordOrientation = RecordVideoOrientationPortrait;
    _xpkSDK.cameraConfiguration.cameraRecord_Type = isMV?RecordType_MVVideo: RecordType_Video;
    _xpkSDK.cameraConfiguration.cameraMV = isMV;
    _xpkSDK.editConfiguration.trimMaxDuration_TwoSpecifyTime    = isMV?15:300;
    _xpkSDK.cameraConfiguration.cameraVideo = !isMV;
    _xpkSDK.cameraConfiguration.cameraPhoto = NO;
    _xpkSDK.cameraConfiguration.cameraMV_MaxVideoDuration = 15.0;
    _xpkSDK.cameraConfiguration.cameraMV_MinVideoDuration = 3.0;
    _xpkSDK.cameraConfiguration.enableUseMusic     = true;
    return _xpkSDK;
    
#endif
}

- (ConfigData *)newConfig:(RDVEUISDK*)sdk{
    ConfigData *config = [[ConfigData alloc] init];
    config.editConfiguration = [sdk.editConfiguration mutableCopy];
    config.cameraConfiguration = [sdk.cameraConfiguration mutableCopy];
    config.exportConfiguration = [sdk.exportConfiguration mutableCopy];
    return config;
}

- (void)refreshConfigWithConfigData:(ConfigData *)ConfigData {
    _edittingSdk.editConfiguration = ConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = ConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = ConfigData.exportConfiguration;
    
    _edittingSdk.editConfiguration.netMaterialTypeURL    = kNetMaterialTypeURL;
    _edittingSdk.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    _edittingSdk.editConfiguration.newmusicResourceURL   = kNewmusicResourceURL;
    _edittingSdk.editConfiguration.filterResourceURL     = kFilterResourceURL;
    _edittingSdk.editConfiguration.subtitleResourceURL   = kSubtitleResourceURL;
    _edittingSdk.editConfiguration.effectResourceURL     = kEffectResourceURL;
    _edittingSdk.editConfiguration.fontResourceURL       = kFontResourceURL;
    _edittingSdk.editConfiguration.transitionURL         = kTransitionResourceURL;
    _edittingSdk.editConfiguration.cloudMusicResourceURL =  kCloudMusicResourceURL;
    _edittingSdk.editConfiguration.newartist             = NSLocalizedString(@"音乐家 Jason Shaw", nil);
    _edittingSdk.editConfiguration.newartistHomepageTitle= @"@audionautix.com";
    _edittingSdk.editConfiguration.newartistHomepageUrl  = @"https://audionautix.com";
    _edittingSdk.editConfiguration.newmusicAuthorizationTitle= NSLocalizedString(@"授权证书", nil);
    _edittingSdk.editConfiguration.newmusicAuthorizationUrl = @"http://d.56show.com/accredit/accredit.jpg";
    _edittingSdk.editConfiguration.soundMusicTypeResourceURL =  kSoundMusicTypeResourceURL;
    _edittingSdk.editConfiguration.soundMusicResourceURL =   SoundMusicResourceURL;
}

#pragma mark - custombtn
- (UIButton *)createSingleBtn:(CGRect)frame title:(NSString *)title {
    UIButton *singleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    singleBtn.frame = frame;
    [singleBtn setBackgroundColor:self.view.backgroundColor];
    [singleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [singleBtn setTitleColor:UIColorFromRGB(0x7e8181) forState:UIControlStateNormal];
    [singleBtn setImage:[UIImage imageNamed:@"单选默认"] forState:UIControlStateNormal];
    [singleBtn setImage:[UIImage imageNamed:@"单选选中"] forState:UIControlStateSelected];
    [singleBtn setTitle:title forState:UIControlStateNormal];
    
    CGSize fitSize = [singleBtn.titleLabel sizeThatFits:CGSizeZero];
    singleBtn.frame = CGRectMake(singleBtn.frame.origin.x, singleBtn.frame.origin.y, fitSize.width + 30, singleBtn.frame.size.height);
    [singleBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, singleBtn.frame.size.width - 20)];
    [singleBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, singleBtn.frame.size.width - fitSize.width - 30)];
    
    return singleBtn;
}

- (UIButton *)createMultiSelectBtn:(CGRect)frame title:(NSString *)title {
    UIButton *multiBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    multiBtn.frame = frame;
    [multiBtn setBackgroundColor:self.view.backgroundColor];
    [multiBtn setTitle:title forState:UIControlStateNormal];
    [multiBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [multiBtn setTitleColor:UIColorFromRGB(0x7e8181) forState:UIControlStateSelected];
    [multiBtn setImage:[UIImage imageNamed:@"启用勾_"] forState:UIControlStateNormal];
    [multiBtn setImage:[UIImage imageNamed:@"不启用_"] forState:UIControlStateSelected];
    
    CGSize fitSize = [multiBtn.titleLabel sizeThatFits:CGSizeZero];
    multiBtn.frame = CGRectMake(multiBtn.frame.origin.x, multiBtn.frame.origin.y, fitSize.width + 30, multiBtn.frame.size.height);
    [multiBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, multiBtn.frame.size.width - 20)];
    [multiBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, multiBtn.frame.size.width - fitSize.width - 30)];
    
    return multiBtn;
}


#pragma mark - 进入编辑设置 添加片段编辑小功能
- (void)settingBtnTouch:(UIButton *)sender{
    _oldExportConfig = [_rdVEEditSDKConfigData.exportConfiguration mutableCopy];
    _oldCameraConfig = [_rdVEEditSDKConfigData.cameraConfiguration mutableCopy];
    _oldEditConfig   = [_rdVEEditSDKConfigData.editConfiguration mutableCopy];
    
    _editSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height)];
    _editSettingView.backgroundColor = self.view.backgroundColor;
    
    float width = MIN(_editSettingView.frame.size.width, _editSettingView.frame.size.height);
    
    _editSettingScrollView = [[UIScrollView alloc] init];
    _editSettingScrollView.bounces = NO;
    _editSettingScrollView.frame = CGRectMake((_editSettingView.frame.size.width - width), 20, width, _editSettingView.frame.size.height - 84);
    _editSettingScrollView.backgroundColor = self.view.backgroundColor;
    _editSettingScrollView.tag = 1;
    [_editSettingView addSubview:_editSettingScrollView];
    
    //向导
    _switchBtn = [[UISwitch alloc] initWithFrame:CGRectMake(10, 24, 59, 25)];
    [_switchBtn setOnImage:[self ImageWithColor:UIColorFromRGB(0xffffff) cornerRadius:1]];
    [_switchBtn setOffImage:[self ImageWithColor:UIColorFromRGB(0x000000) cornerRadius:1]];
    [_switchBtn setThumbTintColor:[UIColor whiteColor]];
    [_switchBtn addTarget:self action:@selector(wizardValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_editSettingScrollView addSubview:_switchBtn];
    
    _wizardLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, _switchBtn.frame.origin.y, _editSettingScrollView.frame.size.width - 120, 31)];
    _wizardLabel.font = [UIFont systemFontOfSize:20];
    _wizardLabel.backgroundColor = [UIColor clearColor];
    _wizardLabel.textColor = [UIColor whiteColor];
    _wizardLabel.textAlignment = NSTextAlignmentCenter;
    _wizardLabel.text = _rdVEEditSDKConfigData.editConfiguration.enableWizard ?  NSLocalizedString(@"开启向导模式", nil): NSLocalizedString(@"关闭向导模式", nil);
    _wizardLabel.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_wizardLabel];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[UIFont systemFontOfSize:16] forKey:NSFontAttributeName];
    
    NSString *ts = [NSString stringWithFormat:NSLocalizedString(@"(字幕，贴纸，滤镜，MV，字体。)\n 例_API:%@", nil),kNewmvResourceURL];
    CGRect rec = [ts boundingRectWithSize:CGSizeMake(_editSettingScrollView.frame.size.width - 80, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    UILabel *sourceLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, _wizardLabel.frame.origin.y + _wizardLabel.frame.size.height + 5, rec.size.width, rec.size.height)];
    sourceLabel.font = [UIFont systemFontOfSize:16];
    sourceLabel.numberOfLines = 0;
    sourceLabel.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    //    _netSourceLabel.adjustsFontSizeToFitWidth = YES;
    sourceLabel.backgroundColor = [UIColor clearColor];
    sourceLabel.textColor = [UIColor whiteColor];
    sourceLabel.textAlignment = NSTextAlignmentLeft;
    sourceLabel.text = ts;
    sourceLabel.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:sourceLabel];
    
    NSArray *editSettings = [[NSArray alloc] initWithObjects:@"配 音",@"配 乐",@"滤 镜",@"字 幕",@"贴 纸",@"M V",@"特 效",@"变 声",@"去水印",@"画中画",@"背 景",@"图片动画",@"封 面",@"涂 鸦",@"加水印",@"马赛克",@"画面比例", nil];
    NSArray *fragmentEditSettings = [[NSArray alloc] initWithObjects:@"特 效",@"调 色",@"滤 镜",@"截 取",@"分 割",@"裁切+旋转",@"调 速",@"调整图片时长",@"复 制",@"调 序",@"文字板",@"倒放",@"转 场",@"旋 转",@"镜 像",@"上下翻转",@"音 量",@"替 换",@"透明度",@"动 画",@"美 颜",nil];
    
    _editExportSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, sourceLabel.frame.size.height + sourceLabel.frame.origin.y + 10, _editSettingScrollView.frame.size.width, 80 + 35 * ceilf((editSettings.count - 1)/3.0) + 80)];
    _editExportSettingView.backgroundColor = [UIColor clearColor];
    _editExportSettingView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_editExportSettingView];
    
    for (int i = 0; i<editSettings.count; i++) {
        CGRect frame;
        if (i == 0) {
            frame = CGRectMake(20, 5, 70, 30);
        }else if (i == editSettings.count-1 ) {
            frame = CGRectMake(20, 85 + 35*ceilf(i/3.0), 100, 30);
        }else {
            int count = i%3 - 1;
            if (count < 0) {
                count = 2;
            }
            frame = CGRectMake(20 + (_editSettingScrollView.frame.size.width/3 + 5)*count, 85 + 35*((i - 1)/3), _editSettingScrollView.frame.size.width/3-5, 30);
        }
        UIButton *settingItemBtn = [self createMultiSelectBtn:frame title:NSLocalizedString(editSettings[i], nil)];
        [settingItemBtn addTarget:self action:@selector(editSettingScrollViewChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        if (i == 0) {
            _dubbingSettingView = [[UIView alloc] initWithFrame:CGRectMake(5,settingItemBtn.frame.origin.y + settingItemBtn.frame.size.height - 15, _editExportSettingView.frame.size.width - 10, 40 + 15)];
            _dubbingSettingView.backgroundColor = [UIColor clearColor];
            _dubbingSettingView.layer.cornerRadius = 3.0;
            _dubbingSettingView.layer.borderWidth = 1;
            _dubbingSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
            _dubbingSettingView.layer.masksToBounds = YES;
            [_editExportSettingView addSubview:_dubbingSettingView];
            
            for (int k = 0; k<2; k++) {
                CGRect frame;
                NSString *title;
                if (k == 0) {
                    frame = CGRectMake(10, 5+15, 120, 30);
                    title = NSLocalizedString(@"配音一", nil);
                }else {
                    frame = CGRectMake(_dubbingSettingView.frame.size.width/2.0-30, 5+15, _dubbingSettingView.frame.size.width/2.0 + 30, 30);
                    title = NSLocalizedString(@"配音二(配音放到配乐里)", nil);
                }
                UIButton *dsettingItemBtn = [self createSingleBtn:frame title:title];
                if((_rdVEEditSDKConfigData.editConfiguration.dubbingType == RDDUBBINGTYPE_FIRST && k==0) || (_rdVEEditSDKConfigData.editConfiguration.dubbingType == RDDUBBINGTYPE_SECOND && k==1)){
                    [dsettingItemBtn setSelected:YES];
                }else{
                    [dsettingItemBtn setSelected:NO];
                }
                dsettingItemBtn.titleLabel.font = [UIFont systemFontOfSize:14];
                CGSize fitSize = [dsettingItemBtn.titleLabel sizeThatFits:CGSizeZero];
                dsettingItemBtn.frame = CGRectMake(dsettingItemBtn.frame.origin.x, dsettingItemBtn.frame.origin.y, fitSize.width + 30, dsettingItemBtn.frame.size.height);
                [dsettingItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, dsettingItemBtn.frame.size.width - 20)];
                [dsettingItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, dsettingItemBtn.frame.size.width - fitSize.width - 30)];
                [dsettingItemBtn addTarget:self action:@selector(dsettingItemChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
                dsettingItemBtn.tag = k+1;
                [_dubbingSettingView addSubview:dsettingItemBtn];
            }
        }else if (i== editSettings.count-1){
            _proportionSettingView = [[UIView alloc] initWithFrame:CGRectMake(5,settingItemBtn.frame.origin.y + settingItemBtn.frame.size.height - 15, _editExportSettingView.frame.size.width - 10, 40 + 15)];
            _proportionSettingView.backgroundColor = [UIColor clearColor];
            _proportionSettingView.layer.cornerRadius = 3.0;
            _proportionSettingView.layer.borderWidth = 1;
            _proportionSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
            _proportionSettingView.layer.masksToBounds = YES;
            [_editExportSettingView addSubview:_proportionSettingView];
        
            for (int k = 0; k<3; k++) {
                CGRect frame = CGRectMake((SCREEN_WIDTH - 30)/3.0 * k + 15, 5+15, (SCREEN_WIDTH - 30)/3.0, 30);
                NSString *title;
                if (k == 0) {
                    title = NSLocalizedString(@"自 动", nil);
                }else if (k == 1) {
                    title = NSLocalizedString(@"横 屏", nil);
                }else {
                    title = NSLocalizedString(@"1 : 1", nil);
                }
                UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
                if(_rdVEEditSDKConfigData.editConfiguration.proportionType == i){
                    [settingItemBtn setSelected:YES];
                }else{
                    [settingItemBtn setSelected:NO];
                }
                [settingItemBtn addTarget:self action:@selector(proportionSettingChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
                settingItemBtn.tag = k+1;
                [_proportionSettingView addSubview:settingItemBtn];
            }
        }
        settingItemBtn.tag = i+1;
        [_editExportSettingView addSubview:settingItemBtn];
    }
    
    _fragmentEditBtn = [self createMultiSelectBtn:CGRectMake(20, _editExportSettingView.frame.origin.y+_editExportSettingView.frame.size.height + 20, 100, 30) title:NSLocalizedString(@"剪辑", nil)];
    [_fragmentEditBtn addTarget:self action:@selector(_fragmentEditBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    
    _fragmentEditSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, _fragmentEditBtn.frame.origin.y+_fragmentEditBtn.frame.size.height-15, _editSettingScrollView.frame.size.width,ceil(fragmentEditSettings.count/2.0)*50)];
    _fragmentEditSettingView.backgroundColor = [UIColor clearColor];
    _fragmentEditSettingView.layer.cornerRadius = 2.0;
    _fragmentEditSettingView.layer.borderWidth = 1;
    _fragmentEditSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _fragmentEditSettingView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_fragmentEditSettingView];
    [_editSettingScrollView addSubview:_fragmentEditBtn];
    
    for (int i = 0; i<fragmentEditSettings.count; i++) {
        CGRect frame;
        int cellIndex = floorf(i/2);
        if(i%2==0){
            frame = CGRectMake(20, cellIndex*40+25, _editSettingScrollView.frame.size.width/2-5, 30);
        }else{
            frame = CGRectMake(_editSettingScrollView.frame.size.width/2 - 5 + 20, cellIndex*40+25, _editSettingScrollView.frame.size.width/2-5 - 30, 30);
        }
        UIButton *settingItemBtn = [self createMultiSelectBtn:frame title:NSLocalizedString(fragmentEditSettings[i], nil)];
        [settingItemBtn addTarget:self action:@selector(fragmentEditChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i+1;
        [_fragmentEditSettingView addSubview:settingItemBtn];
    }
    
    //支持的文件类型
    UILabel *supportFileTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _fragmentEditSettingView.frame.origin.y + _fragmentEditSettingView.frame.size.height + 30 , 200, 31)];
    supportFileTypeLabel.font = [UIFont systemFontOfSize:18];
    supportFileTypeLabel.backgroundColor = [UIColor clearColor];
    supportFileTypeLabel.textColor = [UIColor whiteColor];
    supportFileTypeLabel.textAlignment = NSTextAlignmentLeft;
    supportFileTypeLabel.text = NSLocalizedString(@"编辑支持的文件类型:", nil);
    supportFileTypeLabel.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:supportFileTypeLabel];
    
    _supportFiletypeView = [[UIView alloc] initWithFrame:CGRectMake(0, supportFileTypeLabel.frame.size.height + supportFileTypeLabel.frame.origin.y + 10, _editSettingScrollView.frame.size.width, 40*3)];
    _supportFiletypeView.backgroundColor = [UIColor clearColor];
    _supportFiletypeView.layer.cornerRadius = 3.0;
    _supportFiletypeView.layer.borderWidth = 1;
    _supportFiletypeView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _supportFiletypeView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_supportFiletypeView];
    
    for (int i = 0 ; i<3 ; i++) {
        CGRect frame = CGRectMake(5, 5 + i*40, (SCREEN_WIDTH - 10)/3.0, 30);
        NSString *title;
        if (i == 0) {
            title = NSLocalizedString(@"仅视频", nil);
        }else if (i == 1) {
            title = NSLocalizedString(@"仅图片", nil);
        }else {
            title = NSLocalizedString(@"视频+图片", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if(_rdVEEditSDKConfigData.editConfiguration.supportFileType == i){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(supportFiletypeChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i+1;
        [_supportFiletypeView addSubview:settingItemBtn];
    }
    
    //视频导入设置
    UILabel *inputSettingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _supportFiletypeView.frame.origin.y + _supportFiletypeView.frame.size.height + 30 , 200, 31)];
    inputSettingLabel.font = [UIFont systemFontOfSize:18];
    inputSettingLabel.backgroundColor = [UIColor clearColor];
    inputSettingLabel.textColor = [UIColor whiteColor];
    inputSettingLabel.textAlignment = NSTextAlignmentLeft;
    inputSettingLabel.text = NSLocalizedString(@"视频导入设置:", nil);
    inputSettingLabel.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:inputSettingLabel];
    
    _inputVideoMaxDurationView = [[UIView alloc] initWithFrame:CGRectMake(0, inputSettingLabel.frame.size.height + inputSettingLabel.frame.origin.y + 25, _editSettingScrollView.frame.size.width, 60)];
    _inputVideoMaxDurationView.backgroundColor = [UIColor clearColor];
    _inputVideoMaxDurationView.layer.cornerRadius = 3.0;
    _inputVideoMaxDurationView.layer.borderWidth = 1;
    _inputVideoMaxDurationView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _inputVideoMaxDurationView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_inputVideoMaxDurationView];
    
    {
        UIButton *inputVideoMaxDurationBtn;
        inputVideoMaxDurationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [inputVideoMaxDurationBtn setBackgroundColor:self.view.backgroundColor];
        [inputVideoMaxDurationBtn setTitle:NSLocalizedString(@"导入时长限制", nil) forState:UIControlStateNormal];
        [inputVideoMaxDurationBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [inputVideoMaxDurationBtn setTitleColor:UIColorFromRGB(0x7e8181) forState:UIControlStateSelected];
        inputVideoMaxDurationBtn.frame = CGRectMake(20, inputSettingLabel.frame.size.height + inputSettingLabel.frame.origin.y + 10, 140, 30);
        CGSize inputVideoMaxDurationSize = [inputVideoMaxDurationBtn.titleLabel sizeThatFits:CGSizeZero];
        inputVideoMaxDurationBtn.frame = CGRectMake(inputVideoMaxDurationBtn.frame.origin.x, inputVideoMaxDurationBtn.frame.origin.y, inputVideoMaxDurationSize.width, inputVideoMaxDurationBtn.frame.size.height);
        inputVideoMaxDurationBtn.layer.masksToBounds = YES;
        [_editSettingScrollView addSubview:inputVideoMaxDurationBtn];
        
        UILabel *inputMaxDurationSettingLabel;
        inputMaxDurationSettingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20 , _inputVideoMaxDurationView.frame.size.width - 10 - 175, 31)];
        inputMaxDurationSettingLabel.font = [UIFont systemFontOfSize:16];
        inputMaxDurationSettingLabel.backgroundColor = [UIColor clearColor];
        inputMaxDurationSettingLabel.textColor = [UIColor whiteColor];
        inputMaxDurationSettingLabel.textAlignment = NSTextAlignmentLeft;
        inputMaxDurationSettingLabel.text = NSLocalizedString(@"视频导入最大时长:(秒)", nil);
        inputMaxDurationSettingLabel.layer.masksToBounds = YES;
        
        [_inputVideoMaxDurationView addSubview:inputMaxDurationSettingLabel];
        
        _inputVideoMaxDurationField = [[UITextField alloc] init];
        _inputVideoMaxDurationField.frame = CGRectMake(SCREEN_WIDTH - 170, inputMaxDurationSettingLabel.frame.origin.y, 160, 31);
        _inputVideoMaxDurationField.layer.borderColor    = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
        _inputVideoMaxDurationField.layer.borderWidth    = 1;
        _inputVideoMaxDurationField.layer.cornerRadius   = 3;
        _inputVideoMaxDurationField.layer.masksToBounds  = YES;
        _inputVideoMaxDurationField.delegate             = self;
        _inputVideoMaxDurationField.returnKeyType        = UIReturnKeyDone;
        _inputVideoMaxDurationField.textAlignment        = NSTextAlignmentCenter;
        _inputVideoMaxDurationField.textColor            = UIColorFromRGB(0xffffff);
        NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"默认是0,不限制", nil)];
        [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
        _inputVideoMaxDurationField.attributedPlaceholder = attrstr1;
        [_inputVideoMaxDurationView addSubview:_inputVideoMaxDurationField];
        
        _inputVideoMaxDurationField.enabled = YES;
        _inputVideoMaxDurationField.text = (_oldExportConfig.inputVideoMaxDuration ==0) ? @"" : [NSString stringWithFormat:@"%ld",_oldExportConfig.inputVideoMaxDuration];
        inputMaxDurationSettingLabel.textColor = [UIColor whiteColor];
        _inputVideoMaxDurationField.layer.borderColor = [UIColorFromRGB(0xffffff) CGColor];
        
    }
    
    //导出设置
    UILabel *exportSettingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _inputVideoMaxDurationView.frame.origin.y + _inputVideoMaxDurationView.frame.size.height + 30 , 200, 31)];
    exportSettingLabel.font = [UIFont systemFontOfSize:18];
    exportSettingLabel.backgroundColor = [UIColor clearColor];
    exportSettingLabel.textColor = [UIColor whiteColor];
    exportSettingLabel.textAlignment = NSTextAlignmentLeft;
    exportSettingLabel.text = NSLocalizedString(@"视频导出设置:", nil);
    exportSettingLabel.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:exportSettingLabel];
    
    _videoMaxDurationView = [[UIView alloc] initWithFrame:CGRectMake(0, exportSettingLabel.frame.size.height + exportSettingLabel.frame.origin.y + 25, _editSettingScrollView.frame.size.width, 60)];
    _videoMaxDurationView.backgroundColor = [UIColor clearColor];
    _videoMaxDurationView.layer.cornerRadius = 3.0;
    _videoMaxDurationView.layer.borderWidth = 1;
    _videoMaxDurationView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _videoMaxDurationView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_videoMaxDurationView];
    
    {
        UIButton *videoMaxDurationBtn;
        videoMaxDurationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [videoMaxDurationBtn setBackgroundColor:self.view.backgroundColor];
        [videoMaxDurationBtn setTitle:NSLocalizedString(@"导出时长限制", nil) forState:UIControlStateNormal];
        [videoMaxDurationBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [videoMaxDurationBtn setTitleColor:UIColorFromRGB(0x7e8181) forState:UIControlStateSelected];
        videoMaxDurationBtn.frame = CGRectMake(20, exportSettingLabel.frame.size.height + exportSettingLabel.frame.origin.y + 10, 140, 30);
        videoMaxDurationBtn.layer.masksToBounds = YES;
        CGSize videoMaxDurationSize = [videoMaxDurationBtn.titleLabel sizeThatFits:CGSizeZero];
        videoMaxDurationBtn.frame = CGRectMake(videoMaxDurationBtn.frame.origin.x, videoMaxDurationBtn.frame.origin.y, videoMaxDurationSize.width + 20, videoMaxDurationBtn.frame.size.height);
        [_editSettingScrollView addSubview:videoMaxDurationBtn];
        
        UILabel *exportMaxDurationSettingLabel;
        exportMaxDurationSettingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20 , _videoMaxDurationView.frame.size.width - 10 - 175, 31)];
        exportMaxDurationSettingLabel.font = [UIFont systemFontOfSize:16];
        exportMaxDurationSettingLabel.backgroundColor = [UIColor clearColor];
        exportMaxDurationSettingLabel.textColor = [UIColor whiteColor];
        exportMaxDurationSettingLabel.textAlignment = NSTextAlignmentLeft;
        exportMaxDurationSettingLabel.text = NSLocalizedString(@"视频导出最大时长:(秒)", nil);
        exportMaxDurationSettingLabel.layer.masksToBounds = YES;
        
        [_videoMaxDurationView addSubview:exportMaxDurationSettingLabel];
        
        _exportVideoMaxDurationField = [[UITextField alloc] init];
        _exportVideoMaxDurationField.frame = CGRectMake(SCREEN_WIDTH - 170, exportMaxDurationSettingLabel.frame.origin.y, 160, 31);
        _exportVideoMaxDurationField.layer.borderColor    = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
        _exportVideoMaxDurationField.layer.borderWidth    = 1;
        _exportVideoMaxDurationField.layer.cornerRadius   = 3;
        _exportVideoMaxDurationField.layer.masksToBounds  = YES;
        _exportVideoMaxDurationField.delegate             = self;
        _exportVideoMaxDurationField.returnKeyType        = UIReturnKeyDone;
        _exportVideoMaxDurationField.textAlignment        = NSTextAlignmentCenter;
        _exportVideoMaxDurationField.textColor            = UIColorFromRGB(0xffffff);
        NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"默认是0,不限制", nil)];
        [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
        _exportVideoMaxDurationField.attributedPlaceholder = attrstr1;
        [_videoMaxDurationView addSubview:_exportVideoMaxDurationField];
        
        _exportVideoMaxDurationField.enabled = YES;
        _exportVideoMaxDurationField.text = (_oldExportConfig.outputVideoMaxDuration ==0) ? @"" : [NSString stringWithFormat:@"%ld",_oldExportConfig.outputVideoMaxDuration];
        _inputVideoMaxDurationField.text = (_oldExportConfig.inputVideoMaxDuration ==0) ? @"" : [NSString stringWithFormat:@"%ld",_oldExportConfig.inputVideoMaxDuration];

        exportMaxDurationSettingLabel.textColor = [UIColor whiteColor];
        _exportVideoMaxDurationField.layer.borderColor = [UIColorFromRGB(0xffffff) CGColor];
        
    }
    
    //片尾设置
    _endPicDisabledBtn = [self createMultiSelectBtn:CGRectMake(20,  _videoMaxDurationView.frame.origin.y + _videoMaxDurationView.frame.size.height + 10, 100, 30) title:NSLocalizedString(@"片尾水印", nil)];
    [_endPicDisabledBtn addTarget:self action:@selector(endPicDisabled_switchBtnValueChanged:) forControlEvents:UIControlEventTouchUpInside];
    
    _endPicSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, _endPicDisabledBtn.frame.size.height + _endPicDisabledBtn.frame.origin.y - 15, _editSettingScrollView.frame.size.width, 100)];
    _endPicSettingView.backgroundColor = [UIColor clearColor];
    _endPicSettingView.layer.cornerRadius = 3.0;
    _endPicSettingView.layer.borderWidth = 1;
    _endPicSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _endPicSettingView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_endPicSettingView];
    [_editSettingScrollView addSubview:_endPicDisabledBtn];
    
    for (int i = 0 ; i<2 ; i++) {
        UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20 + 40 * i, _endPicSettingView.frame.size.width - 150 - 20, 31)];
        durationLabel.font = [UIFont systemFontOfSize:16];
        durationLabel.backgroundColor = [UIColor clearColor];
        durationLabel.textColor = [UIColor whiteColor];
        durationLabel.textAlignment = NSTextAlignmentLeft;
        switch (i) {
            case 0:
            {
                durationLabel.text = NSLocalizedString(@"淡入时长:(秒)", nil);
            }
                break;
            case 1:
            {
                durationLabel.text = NSLocalizedString(@"持续时长:(秒)", nil);
            }
                break;
            default:
                break;
        }
        durationLabel.layer.masksToBounds = YES;
        
        UITextField *durationField = [[UITextField alloc] init];
        durationField.frame = CGRectMake(SCREEN_WIDTH - 150, 20 + 40 * i, 140, 31);
        durationField.layer.borderColor    = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
        durationField.layer.borderWidth    = 1;
        durationField.layer.cornerRadius   = 3;
        durationField.layer.masksToBounds  = YES;
        durationField.delegate             = self;
        durationField.returnKeyType        = UIReturnKeyDone;
        durationField.textAlignment        = NSTextAlignmentCenter;
        durationField.tintColor            = [UIColor colorWithWhite:1 alpha:0.8];
        durationField.text = i==0 ? [NSString stringWithFormat:@"%d",(int)_rdVEEditSDKConfigData.exportConfiguration.endPicFadeDuration] :[NSString stringWithFormat:@"%d",(int)_rdVEEditSDKConfigData.exportConfiguration.endPicDuration];
        durationField.textColor            = UIColorFromRGB(0xffffff);
        NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:(i==0 ?NSLocalizedString(@"默认是1秒", nil) : NSLocalizedString(@"默认是2秒", nil))];
        [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
        durationField.attributedPlaceholder = attrstr1;
        durationField.tag = i+1;
        [_endPicSettingView addSubview:durationLabel];
        [_endPicSettingView addSubview:durationField];
    }
    
    _waterSettingView = [[UIView alloc] initWithFrame:CGRectMake(5,_endPicSettingView.frame.origin.y + _endPicSettingView.frame.size.height + 25, _editSettingScrollView.frame.size.width - 10, 40 + 25 + 40)];
    _waterSettingView.backgroundColor = [UIColor clearColor];
    _waterSettingView.layer.cornerRadius = 3.0;
    _waterSettingView.layer.borderWidth = 1;
    _waterSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _waterSettingView.layer.masksToBounds = YES;
    [_editSettingScrollView addSubview:_waterSettingView];
    
    for (int k = 0; k<2; k++) {
        CGRect frame = CGRectMake((_waterSettingView.frame.size.width/2.0) * k +((_waterSettingView.frame.size.width/2.0) - 70)/2.0, 5+15, (_waterSettingView.frame.size.width/2.0) - 70, 30);
        NSString *title;
        if (k == 0) {
            title = NSLocalizedString(@"图片", nil);
        }else {
            title = NSLocalizedString(@"文字", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if(!_rdVEEditSDKConfigData.exportConfiguration.waterDisabled){
            if(_rdVEEditSDKConfigData.exportConfiguration.waterText.length>0 && k == 1){
                [settingItemBtn setSelected:YES];
            }
            if(_rdVEEditSDKConfigData.exportConfiguration.waterImage && k == 0){
                [settingItemBtn setSelected:YES];
            }
        }
        [settingItemBtn addTarget:self action:@selector(waterTypeSettingsBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = k+1;
        [_waterSettingView addSubview:settingItemBtn];
    }
    
    _waterPositionView = [[UIView alloc] initWithFrame:CGRectMake(5, 15 + 40, _waterSettingView.frame.size.width - 10, 40)];
    _waterPositionView.backgroundColor = [UIColor clearColor];
    _waterPositionView.layer.cornerRadius = 3.0;
    _waterPositionView.layer.borderWidth = 1;
    _waterPositionView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _waterPositionView.layer.masksToBounds = YES;
    [_waterSettingView addSubview:_waterPositionView];
    
    _waterSettingBtn = [self createMultiSelectBtn:CGRectMake(20, _waterSettingView.frame.origin.y - 15, 100, 30) title:NSLocalizedString(@"视频水印", nil)];
    [_waterSettingBtn addTarget:self action:@selector(_waterSettingBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_editSettingScrollView addSubview:_waterSettingBtn];
    
    for (int k = 0; k<4; k++) {
        CGRect frame = CGRectMake(_waterPositionView.frame.size.width / 4.0 * k, 5, _waterPositionView.frame.size.width / 4.0, 30);
        NSString *title;
        switch (k) {
            case 0:
                title = NSLocalizedString(@"左上", nil);
                break;
            case 1:
                title = NSLocalizedString(@"左下", nil);
                break;
            case 2:
                title = NSLocalizedString(@"右上", nil);
                break;
            case 3:
                title = NSLocalizedString(@"右下", nil);
                break;
            default:
                break;
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if(_rdVEEditSDKConfigData.exportConfiguration.waterPosition == WATERPOSITION_LEFTTOP && k == 0){
            [settingItemBtn setSelected:YES];
        }
        else if(_rdVEEditSDKConfigData.exportConfiguration.waterPosition == WATERPOSITION_LEFTBOTTOM && k==1){
            [settingItemBtn setSelected:YES];
        }
        else if(_rdVEEditSDKConfigData.exportConfiguration.waterPosition == WATERPOSITION_RIGHTTOP && k==2){
            [settingItemBtn setSelected:YES];
        }
        else if(_rdVEEditSDKConfigData.exportConfiguration.waterPosition == WATERPOSITION_RIGHTBOTTOM && k==3){
            [settingItemBtn setSelected:YES];
        }
        else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(waterPositionSettingsBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = k+1;
        [_waterPositionView addSubview:settingItemBtn];
    }
    
    [_editSettingScrollView setContentSize:CGSizeMake(0, _waterSettingView.frame.origin.y + _waterSettingView.frame.size.height + 20 + (iPhone_X ? 34 : 0))];
    
    UIButton *cancelSettingBtn;
    UIButton *saveSettingBtn;
    
    cancelSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [cancelSettingBtn setTitle:NSLocalizedString(@"返回", nil) forState:UIControlStateNormal];
    [cancelSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [cancelSettingBtn addTarget:self action:@selector(cancelSettingBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    cancelSettingBtn.frame = CGRectMake(_editSettingScrollView.frame.origin.x, _editSettingView.frame.size.height - 50 - (iPhone_X ? 34 : 0), _editSettingScrollView.frame.size.width/2.0-5, 40);
    cancelSettingBtn.layer.cornerRadius = 3.0;
    cancelSettingBtn.layer.masksToBounds = YES;
    [_editSettingView addSubview:cancelSettingBtn];
    
    saveSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [saveSettingBtn setTitle:NSLocalizedString(@"保存", nil) forState:UIControlStateNormal];
    [saveSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [saveSettingBtn addTarget:self action:@selector(saveSettingBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    saveSettingBtn.frame = CGRectMake(cancelSettingBtn.frame.origin.x + cancelSettingBtn.frame.size.width+10, cancelSettingBtn.frame.origin.y, _editSettingScrollView.frame.size.width/2.0-5, 40);
    saveSettingBtn.layer.cornerRadius = 3.0;
    saveSettingBtn.layer.masksToBounds = YES;
    
    [_editSettingView addSubview:saveSettingBtn];
    [self.navigationController.view addSubview:_editSettingView];
    
    _wizardLabel.text = _rdVEEditSDKConfigData.editConfiguration.enableWizard ?  NSLocalizedString(@"开启向导模式", nil): NSLocalizedString(@"关闭向导模式", nil);
    for (UIButton *itemBtn in _supportFiletypeView.subviews) {
        if(itemBtn.tag-1 == _rdVEEditSDKConfigData.editConfiguration.supportFileType){
            [itemBtn setSelected:YES];
        }else{
            [itemBtn setSelected:NO];
        }
    }
    
    [_waterSettingBtn setSelected:(!_rdVEEditSDKConfigData.exportConfiguration.waterDisabled ? NO : YES)];
    if(_rdVEEditSDKConfigData.exportConfiguration.waterDisabled){
        for (UIButton *itemBtn in _waterSettingView.subviews) {
            [itemBtn setEnabled:NO];
        }
    }else{
        UIButton *imagetypeBtn = [_waterSettingView viewWithTag:1];
        UIButton *texttypeBtn = [_waterSettingView viewWithTag:2];
        if(_rdVEEditSDKConfigData.exportConfiguration.waterImage){
            [imagetypeBtn setSelected:YES];
            [texttypeBtn setSelected:NO];
        }else if(_rdVEEditSDKConfigData.exportConfiguration.waterText){
            [imagetypeBtn setSelected:NO];
            [texttypeBtn setSelected:YES];
        }
    }
    
   
    
    [_switchBtn setOn:(_rdVEEditSDKConfigData.editConfiguration.enableWizard ? YES : NO)];
    [_fragmentEditBtn setSelected:(_rdVEEditSDKConfigData.editConfiguration.enableFragmentedit ? NO : YES)];
    [_endPicDisabledBtn setSelected:(!_rdVEEditSDKConfigData.exportConfiguration.endPicDisabled ? NO : YES)];
    
    [self checkProportionSettingChildBtn];
    
    [self settingScrollViewChildBtnSelected];
       
    [self fragmentEditChildBtnSelected];
}

- (void)cancelSettingBtnTouch:(UIButton *)sender{
    _rdVECameraSDKConfigData.exportConfiguration = [_oldExportConfig mutableCopy];
    _rdVECameraSDKConfigData.cameraConfiguration = [_oldCameraConfig mutableCopy];
    _rdVECameraSDKConfigData.editConfiguration   = [_oldEditConfig mutableCopy];
    _oldEditConfig = nil;
    _oldCameraConfig = nil;
    _oldExportConfig = nil;
    [self releaseEditSettingView];
}

- (void)saveSettingBtnTouch:(UIButton *)sender{
    UITextField *endPicFadeDurationF = [_endPicSettingView viewWithTag:1];
    UITextField *endPicDurationF = [_endPicSettingView viewWithTag:2];
    if(endPicFadeDurationF.text.length>0){
        _rdVEEditSDKConfigData.exportConfiguration.endPicFadeDuration = [endPicFadeDurationF.text intValue];
    }
    if(endPicDurationF.text.length>0){
        _rdVEEditSDKConfigData.exportConfiguration.endPicDuration = [endPicDurationF.text intValue];
    }
    
    if(_exportVideoMaxDurationField.text){
        _rdVEEditSDKConfigData.exportConfiguration.outputVideoMaxDuration = [_exportVideoMaxDurationField.text intValue];
        [_exportVideoMaxDurationField resignFirstResponder];
    }else {
        _rdVEEditSDKConfigData.exportConfiguration.outputVideoMaxDuration = 0;
    }
    
    if(_inputVideoMaxDurationField.text){
        _rdVEEditSDKConfigData.exportConfiguration.inputVideoMaxDuration = [_inputVideoMaxDurationField.text intValue];
        [_inputVideoMaxDurationField resignFirstResponder];
    }else {
        _rdVEEditSDKConfigData.exportConfiguration.inputVideoMaxDuration = 0;
    }
    
    _oldExportConfig = nil;
    _oldCameraConfig = nil;
    _oldEditConfig = nil;
    [self releaseEditSettingView];
}

- (void)wizardValueChanged:(UISwitch *)sender{
    if (!sender.on) {
        _rdVEEditSDKConfigData.editConfiguration.enableWizard = false;
        
        _wizardLabel.text = NSLocalizedString(@"关闭向导模式", nil);
    }else{
        _rdVEEditSDKConfigData.editConfiguration.enableWizard = true;
        _wizardLabel.text = NSLocalizedString(@"开启向导模式", nil);
    }
}

- (void)editSettingScrollViewChildBtnTouch:(UIButton *)sender{
    switch (sender.tag-1) {
        case 0:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableDubbing = true;
                if (!_rdVEEditSDKConfigData.editConfiguration.enableMusic && _rdVEEditSDKConfigData.editConfiguration.dubbingType == RDDUBBINGTYPE_SECOND) {
                    UIButton *dubbingBtn = [_dubbingSettingView viewWithTag:1];
                    [self dsettingItemChildBtnTouch:dubbingBtn];
                }
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableDubbing = false;
            }
        }
            break;
        case 1:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableMusic = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableMusic = false;
                if (_rdVEEditSDKConfigData.editConfiguration.enableDubbing && _rdVEEditSDKConfigData.editConfiguration.dubbingType == RDDUBBINGTYPE_SECOND) {
                    UIButton *dubbingBtn = [_dubbingSettingView viewWithTag:1];
                    [self dsettingItemChildBtnTouch:dubbingBtn];
                }
            }
        }
            break;
        case 2:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableFilter = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableFilter = false;
            }
        }
            break;
        case 3:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSubtitle = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSubtitle = false;
            }
        }
            break;
        case 4:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSticker = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSticker = false;
            }
            _rdVEEditSDKConfigData.editConfiguration.enableEffect = false;
        }
            break;
        case 5:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableMV = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableMV = false;
            }
            if(_rdVEEditSDKConfigData.editConfiguration.enableMV){
                _rdVEEditSDKConfigData.editConfiguration.proportionType = RDPROPORTIONTYPE_SQUARE;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.proportionType = RDPROPORTIONTYPE_AUTO;
            }
            [self checkProportionSettingChildBtn];
        }
            break;
        case 6:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableEffectsVideo = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableEffectsVideo = false;
            }
        }
            break;
        case 7:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSoundEffect = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSoundEffect = false;
            }
        }
            break;
        case 8:
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableDewatermark = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableDewatermark = false;
            }
        }
            break;
        case 9://画中画
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableCollage = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableCollage = false;
            }
        }
            break;
        case 10://背景
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableBackgroundEdit = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableBackgroundEdit = false;
            }
        }
            break;
        case 11://图片动画
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enablePicZoom = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enablePicZoom = false;
            }
        }
            break;
        case 12://@"封面"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableCover = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableCover = false;
            }
        }
            break;
        case 13://@"涂鸦"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableDoodle = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableDoodle = false;
            }
        }
            break;
        case 14://@"去水印"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableWatermark = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableWatermark = false;
            }
        }
            break;
        case 15://@"马赛克"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableMosaic = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableMosaic = false;
            }
        }
            break;
        case 16://@"画面比例"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableProportion = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableProportion = false;
            }
        }
            break;
        
        default:
            break;
    }
    sender.selected = !sender.selected;
}

- (void)dsettingItemChildBtnTouch:(UIButton *)sender{
    switch (sender.tag) {
        case 1:
            _rdVEEditSDKConfigData.editConfiguration.dubbingType = RDDUBBINGTYPE_FIRST;
            break;
        case 2:
            if (!_rdVEEditSDKConfigData.editConfiguration.enableMusic) {
                return;
            }
            _rdVEEditSDKConfigData.editConfiguration.dubbingType = RDDUBBINGTYPE_SECOND;
            break;
        default:
            break;
    }
    
    for (UIButton *itemBtn in _dubbingSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)_fragmentEditBtnTouch:(UIButton *)sender{
    if(sender.selected){
        _rdVEEditSDKConfigData.editConfiguration.enableFragmentedit = true;
        [_fragmentEditSettingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[UIButton class]]){
                if(![((UIButton *)obj).currentTitle isEqualToString:NSLocalizedString(@"画面比例", nil)]){
                    ((UIButton *)obj).enabled = YES;
                }
            }
        }];
        
    }else{
        _rdVEEditSDKConfigData.editConfiguration.enableFragmentedit   = false;
        [_fragmentEditSettingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[UIButton class]]){
                if(![((UIButton *)obj).currentTitle isEqualToString:NSLocalizedString(@"画面比例", nil)]){
                    ((UIButton *)obj).enabled = NO;
                }
            }
        }];
    }
    
    sender.selected = !sender.selected;
}

- (void)fragmentEditChildBtnTouch:(UIButton *)sender{
    switch (sender.tag-1) {
        case 0://@"特效"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSingleSpecialEffects = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSingleSpecialEffects = false;
            }
        }
            break;
        case 1://@"调 色"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSingleMediaAdjust = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSingleMediaAdjust = false;
            }
        }
            break;
        case 2://@"滤 镜"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSingleMediaFilter = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSingleMediaFilter = false;
            }
        }
            break;
        case 3://@"截 取"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableTrim = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableTrim = false;
            }
        }
            break;
        case 4://@"分 割"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSplit = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSplit = false;
            }
        }
            break;
        case 5://@"裁切+旋转"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableEdit = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableEdit = false;
            }
        }
            break;
        case 6://@"调 速"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSpeedcontrol = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSpeedcontrol = false;
            }
        }
            break;
        case 7://@"调整图片时长"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableImageDurationControl = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableImageDurationControl = false;
            }
        }
            break;
        case 8://@"复 制"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableCopy = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableCopy = false;
            }
            break;
        }
        case 9://@"调 序"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableSort = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableSort = false;
            }
        }
            break;
        case 10://@"文字板"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableTextTitle = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableTextTitle = false;
            }
        }
            break;
        case 11://@"倒放"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableReverseVideo = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableReverseVideo = false;
            }
        }
            break;
        case 12://@"转 场"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableTransition = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableTransition = false;
            }
        }
            break;
        case 13://@"旋 转"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableRotate = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableRotate = false;
            }
        }
            break;
        case 14://@"镜 像"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableMirror = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableMirror = false;
            }
        }
            break;
        case 15://@"上下翻转"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableFlipUpAndDown = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableFlipUpAndDown = false;
            }
        }
            break;
        case 16://@"音 量"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableVolume = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableVolume = false;
            }
        }
            break;
        case 17://@"替 换"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableReplace = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableReplace = false;
            }
        }
            break;
        case 18://@"透明度"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableTransparency = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableTransparency = false;
            }
        }
            break;
        case 19://@"动画"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableAnimation = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableAnimation = false;
            }
        }
            break;
        case 20://@"美颜"
        {
            if(sender.selected){
                _rdVEEditSDKConfigData.editConfiguration.enableBeauty = true;
            }else{
                _rdVEEditSDKConfigData.editConfiguration.enableBeauty = false;
            }
        }
            break;
        default:
            break;
    }
    sender.selected = !sender.selected;
}

- (void)proportionSettingChildBtnTouch:(UIButton *)sender{
    switch (sender.tag) {
        case 1:
            _rdVEEditSDKConfigData.editConfiguration.proportionType = RDPROPORTIONTYPE_AUTO;
            break;
        case 2:
            _rdVEEditSDKConfigData.editConfiguration.proportionType = RDPROPORTIONTYPE_LANDSCAPE;
            break;
        case 3:
            _rdVEEditSDKConfigData.editConfiguration.proportionType = RDPROPORTIONTYPE_SQUARE;
            break;
        default:
            break;
    }
    
    for (UIButton *itemBtn in _proportionSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)supportFiletypeChildBtnTouch:(UIButton *)sender{
    
    switch (sender.tag - 1) {
        case SUPPORT_ALL:
            _rdVEEditSDKConfigData.editConfiguration.supportFileType = SUPPORT_ALL;
            break;
        case ONLYSUPPORT_VIDEO:
            _rdVEEditSDKConfigData.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
            break;
        case ONLYSUPPORT_IMAGE:
            _rdVEEditSDKConfigData.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
            break;
        default:
            break;
    }
    for (UIButton *itembtn in _supportFiletypeView.subviews) {
        if(itembtn.tag == sender.tag){
            itembtn.selected = YES;
        }else{
            itembtn.selected = NO;
        }
    }
}

- (void)endPicDisabled_switchBtnValueChanged:(UIButton *)sender{
    if(sender.selected){
        _rdVEEditSDKConfigData.exportConfiguration.endPicDisabled = false;
    }else{
        _rdVEEditSDKConfigData.exportConfiguration.endPicDisabled = true;
    }
    sender.selected = !sender.selected;
}

- (void)waterTypeSettingsBtnTouch:(UIButton *)sender{
    
    if(sender.tag == 1){
        _rdVEEditSDKConfigData.exportConfiguration.waterImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"waterImage" ofType:@"png"]];
    }else{
        _rdVEEditSDKConfigData.exportConfiguration.waterText = @"rd.56show.com";
    }
    for (UIButton *itemBtn in _waterSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)_waterSettingBtnTouch:(UIButton *)sender{
    if(!sender.selected){
        _rdVEEditSDKConfigData.exportConfiguration.waterDisabled = true;
        for (UIButton *itemBtn in _waterSettingView.subviews) {
            [itemBtn setEnabled:NO];
        }
    }else{
        _rdVEEditSDKConfigData.exportConfiguration.waterDisabled = false;
        for (UIButton *itemBtn in _waterSettingView.subviews) {
            [itemBtn setEnabled:YES];
        }
    }
    sender.selected = !sender.selected;
}

- (void)waterPositionSettingsBtnTouch:(UIButton *)sender{
    
    for (UIButton *itemBtn in _waterPositionView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
        
        switch (sender.tag) {
            case 1:
                _rdVEEditSDKConfigData.exportConfiguration.waterPosition = WATERPOSITION_LEFTTOP;
                break;
            case 2:
                _rdVEEditSDKConfigData.exportConfiguration.waterPosition = WATERPOSITION_LEFTBOTTOM;
                break;
            case 3:
                _rdVEEditSDKConfigData.exportConfiguration.waterPosition = WATERPOSITION_RIGHTTOP;
                break;
            case 4:
                _rdVEEditSDKConfigData.exportConfiguration.waterPosition = WATERPOSITION_RIGHTBOTTOM;
                break;
                
            default:
                break;
        }
    }
}

- (void)checkProportionSettingChildBtn{
    
    UIButton *itemBtn;
    UIButton *sender = [_fragmentEditSettingView viewWithTag:10];
    if(_rdVEEditSDKConfigData.editConfiguration.enableMV){
        _rdVEEditSDKConfigData.editConfiguration.proportionType = RDPROPORTIONTYPE_SQUARE;
        sender.enabled = NO;
    }else{
        sender.enabled = YES;
    }
    switch (_rdVEEditSDKConfigData.editConfiguration.proportionType) {
        case RDPROPORTIONTYPE_AUTO:
        {
            itemBtn = [_proportionSettingView viewWithTag:1];
            
        }
            break;
        case RDPROPORTIONTYPE_LANDSCAPE:
        {
            itemBtn = [_proportionSettingView viewWithTag:2];
        }
            break;
        case RDPROPORTIONTYPE_SQUARE:
        {
            itemBtn = [_proportionSettingView viewWithTag:3];
        }
            break;
        default:
            break;
    }
    for (UIButton *iBtn in _proportionSettingView.subviews) {
        if([iBtn isKindOfClass:[UIButton class]]){
            if(iBtn.tag == itemBtn.tag){
                [iBtn setSelected:YES];
            }else{
                [iBtn setSelected:NO];
            }
        }
        [iBtn setEnabled:(_rdVEEditSDKConfigData.editConfiguration.enableMV?NO : YES)];
        
    }
    if(_rdVEEditSDKConfigData.editConfiguration.enableMV){
        [itemBtn setEnabled:YES];
    }
}

- (void)settingScrollViewChildBtnSelected{
    
    [_editExportSettingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *sender = (UIButton *)obj;
        
        if([sender isKindOfClass:[UIButton class]]){
            switch (sender.tag-1) {
                case 0:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableDubbing){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 1:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableMusic){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }                
                    break;
                case 2:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableFilter){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 3:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSubtitle){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 4:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSticker){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 5:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableMV){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 6:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableEffectsVideo){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 7:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSoundEffect){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 8:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableDewatermark){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 9:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableCollage){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 10:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableBackgroundEdit){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 11:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enablePicZoom){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 12:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableCover){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 13:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableDoodle){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 14:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableWatermark){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 15:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableMosaic){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 16:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableProportion){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                    
                default:
                    break;
            }
        }
    }];
}

#pragma mark- 片段编辑
- (void)fragmentEditChildBtnSelected{
    
    [_fragmentEditSettingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *sender = (UIButton *)obj;
        if([sender isKindOfClass:[UIButton class]]){
            switch (sender.tag-1) {
                case 0:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSingleSpecialEffects){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 1:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSingleMediaAdjust){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 2:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSingleMediaFilter){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 3:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableTrim){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 4:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSplit){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 5:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableEdit){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 6:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSpeedcontrol){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 7:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableImageDurationControl){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 8:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableCopy){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 9:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableSort){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 10:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableTextTitle){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 11:
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableReverseVideo){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 12://@"转 场"
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableTransition){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 13://@"旋 转"
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableRotate){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 14://@"镜 像"
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableMirror){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 15://@"上下翻转"
                {
                if(!self->_rdVEEditSDKConfigData.editConfiguration.enableFlipUpAndDown){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 16://@"音 量"
                {
                    if(!self->_rdVEEditSDKConfigData.editConfiguration.enableVolume){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 17://@"替 换"
                { if(!self->_rdVEEditSDKConfigData.editConfiguration.enableReplace){
                        sender.selected = YES;
                    }else{
                        sender.selected = NO;
                    }
                }
                    break;
                case 18://@"透明度"
                { if(!self->_rdVEEditSDKConfigData.editConfiguration.enableTransparency){
                    sender.selected = YES;
                }else{
                    sender.selected = NO;
                }
                }
                    break;
                case 19://@"动画"
                { if(!self->_rdVEEditSDKConfigData.editConfiguration.enableAnimation){
                    sender.selected = YES;
                }else{
                    sender.selected = NO;
                }
                }
                    break;
                case 20://@"美颜"
                { if(!self->_rdVEEditSDKConfigData.editConfiguration.enableBeauty){
                    sender.selected = YES;
                }else{
                    sender.selected = NO;
                }
                }
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void)releaseEditSettingView{
    
    [_editSettingScrollView removeFromSuperview];
    _editSettingScrollView = nil;
    
    [_editSettingView removeFromSuperview];
    _editSettingView = nil;
}

#pragma mark - 进入相机设置
- (void)setcameraSettings:(UIButton *)sender{
    _oldExportConfig = [_rdVECameraSDKConfigData.exportConfiguration mutableCopy];
    _oldCameraConfig = [_rdVECameraSDKConfigData.cameraConfiguration mutableCopy];
    _oldEditConfig   = [_rdVECameraSDKConfigData.editConfiguration mutableCopy];
    
    _cameraSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height)];
    _cameraSettingView.backgroundColor = self.view.backgroundColor;
    [self.navigationController.view addSubview:_cameraSettingView];
    
    float width = MIN(_cameraSettingView.frame.size.width, _cameraSettingView.frame.size.height);
    _cameraSettingScrollview = [[UIScrollView alloc] init];
    _cameraSettingScrollview.frame = CGRectMake((_cameraSettingView.frame.size.width - width), 20, width, _cameraSettingView.frame.size.height - 84);
    _cameraSettingScrollview.backgroundColor = self.view.backgroundColor;
    [_cameraSettingView addSubview:_cameraSettingScrollview];
    
    //隐藏相册按钮
    _hiddenPhotoLibrarySwitchBtn = [[UISwitch alloc] initWithFrame:CGRectMake(20, 24, 59, 25)];
    [_hiddenPhotoLibrarySwitchBtn setOnImage:[self ImageWithColor:UIColorFromRGB(0xffffff) cornerRadius:1]];
    [_hiddenPhotoLibrarySwitchBtn setOffImage:[self ImageWithColor:UIColorFromRGB(0x000000) cornerRadius:1]];
    [_hiddenPhotoLibrarySwitchBtn setThumbTintColor:[UIColor whiteColor]];
    [_hiddenPhotoLibrarySwitchBtn addTarget:self action:@selector(hiddenPhotoLibChanged:) forControlEvents:UIControlEventValueChanged];
    [_cameraSettingScrollview addSubview:_hiddenPhotoLibrarySwitchBtn];
    [_hiddenPhotoLibrarySwitchBtn setOn:(_rdVECameraSDKConfigData.cameraConfiguration.hiddenPhotoLib ? YES : NO)];
    
    _hiddenPhotoLibraryswitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, _hiddenPhotoLibrarySwitchBtn.frame.origin.y, _cameraSettingScrollview.frame.size.width - 120, 31)];
    _hiddenPhotoLibraryswitchLabel.font = [UIFont systemFontOfSize:16];
    _hiddenPhotoLibraryswitchLabel.backgroundColor = [UIColor clearColor];
    _hiddenPhotoLibraryswitchLabel.textColor = [UIColor whiteColor];
    _hiddenPhotoLibraryswitchLabel.textAlignment = NSTextAlignmentCenter;
    _hiddenPhotoLibraryswitchLabel.text = _rdVECameraSDKConfigData.cameraConfiguration.hiddenPhotoLib ?  NSLocalizedString(@"隐藏相册按钮", nil): NSLocalizedString(@"显示相册按钮", nil);
    _hiddenPhotoLibraryswitchLabel.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_hiddenPhotoLibraryswitchLabel];
    
    UILabel *cameraPositionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, _hiddenPhotoLibrarySwitchBtn.frame.origin.y + _hiddenPhotoLibrarySwitchBtn.frame.size.height + 20, 85, 31)];
    cameraPositionLabel.font = [UIFont systemFontOfSize:16];
    cameraPositionLabel.backgroundColor = self.view.backgroundColor;
    cameraPositionLabel.textColor = [UIColor whiteColor];
    cameraPositionLabel.textAlignment = NSTextAlignmentLeft;
    cameraPositionLabel.text = NSLocalizedString(@"摄像头设置", nil);
    cameraPositionLabel.layer.masksToBounds = YES;
    CGSize cameraPositionSize = [cameraPositionLabel sizeThatFits:CGSizeZero];
    cameraPositionLabel.frame = CGRectMake(cameraPositionLabel.frame.origin.x, cameraPositionLabel.frame.origin.y, cameraPositionSize.width, cameraPositionLabel.frame.size.height);
    
    _camerapositionSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, cameraPositionLabel.frame.size.height + cameraPositionLabel.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width, 60)];
    _camerapositionSettingView.backgroundColor = [UIColor clearColor];
    _camerapositionSettingView.layer.cornerRadius = 3.0;
    _camerapositionSettingView.layer.borderWidth = 1;
    _camerapositionSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _camerapositionSettingView.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_camerapositionSettingView];
    
    [_cameraSettingScrollview addSubview:cameraPositionLabel];
    
    for (int i = 0 ; i<2 ; i++) {
        CGRect frame;
        NSString *title;
        if (i == 0) {
            frame = CGRectMake(30, 25, 70, 30);
            title = NSLocalizedString(@"前置", nil);
        }else {
            frame = CGRectMake(200, 25, 70, 30);
            title = NSLocalizedString(@"后置", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if((_rdVECameraSDKConfigData.cameraConfiguration.cameraCaptureDevicePosition == AVCaptureDevicePositionFront && i == 0) || (_rdVECameraSDKConfigData.cameraConfiguration.cameraCaptureDevicePosition == AVCaptureDevicePositionBack && i == 1)){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(cameraPositionChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i+1;
        [_camerapositionSettingView addSubview:settingItemBtn];
    }
    _enableUseMusicSwitchBtn = [[UISwitch alloc] initWithFrame:CGRectMake(20, _camerapositionSettingView.frame.origin.y + _camerapositionSettingView.frame.size.height + 20, 59, 25)];
    [_enableUseMusicSwitchBtn setOnImage:[self ImageWithColor:UIColorFromRGB(0xffffff) cornerRadius:1]];
    [_enableUseMusicSwitchBtn setOffImage:[self ImageWithColor:UIColorFromRGB(0x000000) cornerRadius:1]];
    [_enableUseMusicSwitchBtn setThumbTintColor:[UIColor whiteColor]];
    [_enableUseMusicSwitchBtn addTarget:self action:@selector(enableUseMusicSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [_cameraSettingScrollview addSubview:_enableUseMusicSwitchBtn];
    [_enableUseMusicSwitchBtn setOn:(_rdVECameraSDKConfigData.cameraConfiguration.enableUseMusic ? YES : NO)];
    
    _enableUseMusicLable = [[UILabel alloc] initWithFrame:CGRectMake(70, _enableUseMusicSwitchBtn.frame.origin.y, _cameraSettingScrollview.frame.size.width - 120, 31)];
    _enableUseMusicLable.font = [UIFont systemFontOfSize:16];
    _enableUseMusicLable.backgroundColor = [UIColor clearColor];
    _enableUseMusicLable.textColor = [UIColor whiteColor];
    _enableUseMusicLable.textAlignment = NSTextAlignmentCenter;
    _enableUseMusicLable.text = _rdVECameraSDKConfigData.cameraConfiguration.enableUseMusic ?  NSLocalizedString(@"录制中播放音乐", nil): NSLocalizedString(@"录制中不播放音乐", nil);
    _enableUseMusicLable.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_enableUseMusicLable];
    
    //支持拍摄类型设置
    UILabel *cameraMixedLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, _enableUseMusicLable.frame.origin.y + _enableUseMusicLable.frame.size.height + 20, 105, 31)];
    cameraMixedLabel.font = [UIFont systemFontOfSize:16];
    cameraMixedLabel.backgroundColor = self.view.backgroundColor;
    cameraMixedLabel.textColor = [UIColor whiteColor];
    cameraMixedLabel.textAlignment = NSTextAlignmentLeft;
    cameraMixedLabel.text = NSLocalizedString(@"支持拍摄类型", nil);
    cameraMixedLabel.layer.masksToBounds = YES;
    CGSize cameraMixedSize = [cameraMixedLabel sizeThatFits:CGSizeZero];
    cameraMixedLabel.frame = CGRectMake(cameraMixedLabel.frame.origin.x, cameraMixedLabel.frame.origin.y, cameraMixedSize.width, cameraMixedLabel.frame.size.height);
    
    _cameraMixedSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, cameraMixedLabel.frame.size.height + cameraMixedLabel.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width, 330)];
    _cameraMixedSettingView.backgroundColor = [UIColor clearColor];
    _cameraMixedSettingView.layer.cornerRadius = 3.0;
    _cameraMixedSettingView.layer.borderWidth = 1;
    _cameraMixedSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _cameraMixedSettingView.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_cameraMixedSettingView];
    [_cameraSettingScrollview addSubview:cameraMixedLabel];
    
    //拍摄类型1:短视频MV设置
    _cameraMVBtn = [self createMultiSelectBtn:CGRectMake(20, 25, 110, 30) title:NSLocalizedString(@"短视频MV", nil)];
    [_cameraMVBtn addTarget:self action:@selector(_cameraMVBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    
    _MVRecordSettingView = [[UIView alloc] initWithFrame:CGRectMake(5, _cameraMVBtn.frame.size.height + _cameraMVBtn.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width - 10, 100)];
    _MVRecordSettingView.backgroundColor = [UIColor clearColor];
    _MVRecordSettingView.layer.cornerRadius = 3.0;
    _MVRecordSettingView.layer.borderWidth = 1;
    _MVRecordSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _MVRecordSettingView.layer.masksToBounds = YES;
    [_cameraMixedSettingView addSubview:_MVRecordSettingView];
    [_cameraMixedSettingView addSubview:_cameraMVBtn];
    
    for (int i = 0 ; i<2 ; i++) {
        
        UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20 + 40 * i, _MVRecordSettingView.frame.size.width - 20 - 140 - 5, 31)];
        durationLabel.font = [UIFont systemFontOfSize:16];
        durationLabel.backgroundColor = [UIColor clearColor];
        durationLabel.textColor = [UIColor whiteColor];
        durationLabel.textAlignment = NSTextAlignmentLeft;
        durationLabel.layer.masksToBounds = YES;
        
        UITextField *durationField = [[UITextField alloc] init];
        durationField.frame = CGRectMake(_MVRecordSettingView.frame.size.width - 145, 20 + 40 * i, 140, 31);
        durationField.layer.borderColor    = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
        durationField.layer.borderWidth    = 1;
        durationField.layer.cornerRadius   = 3;
        durationField.layer.masksToBounds  = YES;
        durationField.delegate             = self;
        durationField.returnKeyType        = UIReturnKeyDone;
        durationField.textAlignment        = NSTextAlignmentCenter;
        durationField.tintColor            = [UIColor colorWithWhite:1 alpha:0.8];
        durationField.textColor            = UIColorFromRGB(0xffffff);
        durationField.tag = i+1;
        NSString *placeholder;
        if (i == 0) {
            durationLabel.text = NSLocalizedString(@"拍摄最小时长:(秒)", nil);
            placeholder = NSLocalizedString(@"默认3秒", nil);
            durationField.text = [NSString stringWithFormat:@"%d",(int)_rdVECameraSDKConfigData.cameraConfiguration.cameraMV_MinVideoDuration];
            
        }else {
            durationLabel.text = NSLocalizedString(@"拍摄最大时长:(秒)", nil);
            placeholder = NSLocalizedString(@"默认15秒", nil);
            durationField.text = [NSString stringWithFormat:@"%d",(int)_rdVECameraSDKConfigData.cameraConfiguration.cameraMV_MaxVideoDuration];
            
        }
        NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:placeholder];
        [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
        durationField.attributedPlaceholder = attrstr1;
        [_MVRecordSettingView addSubview:durationLabel];
        [_MVRecordSettingView addSubview:durationField];
    }
    
    //拍摄类型2:视频设置
    _cameraVideoBtn = [self createMultiSelectBtn:CGRectMake(20, _MVRecordSettingView.frame.origin.y+_MVRecordSettingView.frame.size.height + 20, 80, 30) title:NSLocalizedString(@"视频", nil)];
    [_cameraVideoBtn addTarget:self action:@selector(_cameraVideoBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraVideoBtn setSelected:!_rdVECameraSDKConfigData.cameraConfiguration.cameraVideo];
    
    _cameraDurationSettingView = [[UIView alloc] initWithFrame:CGRectMake(5, _cameraVideoBtn.frame.size.height + _cameraVideoBtn.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width - 10, 100)];
    _cameraDurationSettingView.backgroundColor = [UIColor clearColor];
    _cameraDurationSettingView.layer.cornerRadius = 3.0;
    _cameraDurationSettingView.layer.borderWidth = 1;
    _cameraDurationSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _cameraDurationSettingView.layer.masksToBounds = YES;
    [_cameraMixedSettingView addSubview:_cameraDurationSettingView];
    [_cameraMixedSettingView addSubview:_cameraVideoBtn];
    
    
    for (int i = 0 ; i<2 ; i++) {
        
        UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20 + 40 * i, _cameraDurationSettingView.frame.size.width - 20 - 170, 31)];
        durationLabel.font = [UIFont systemFontOfSize:16];
        durationLabel.backgroundColor = [UIColor clearColor];
        durationLabel.textColor = [UIColor whiteColor];
        durationLabel.textAlignment = NSTextAlignmentLeft;
        durationLabel.layer.masksToBounds = YES;
        
        UITextField *durationField = [[UITextField alloc] init];
        durationField.frame = CGRectMake(_cameraDurationSettingView.frame.size.width - 165, 20 + 40 * i, 160, 31);
        durationField.layer.borderColor    = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
        durationField.layer.borderWidth    = 1;
        durationField.layer.cornerRadius   = 3;
        durationField.layer.masksToBounds  = YES;
        durationField.delegate             = self;
        durationField.returnKeyType        = UIReturnKeyDone;
        durationField.textAlignment        = NSTextAlignmentCenter;
        durationField.tintColor            = [UIColor colorWithWhite:1 alpha:0.8];
        durationField.textColor            = UIColorFromRGB(0xffffff);
        NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"默认是0,不限制", nil)];
        [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
        durationField.attributedPlaceholder = attrstr1;
        durationField.tag = i+1;
        durationField.adjustsFontSizeToFitWidth = YES;
        switch (i) {
            case 0:
            {
                durationLabel.text = NSLocalizedString(@"拍摄最小时长:(秒)", nil);
                durationField.text = [NSString stringWithFormat:@"%d",(int)_rdVECameraSDKConfigData.cameraConfiguration.cameraMinVideoDuration];
            }
                break;
            case 1:
            {
                durationLabel.text = NSLocalizedString(@"拍摄最大时长:(秒)", nil);
                if(_rdVECameraSDKConfigData.cameraConfiguration.cameraRecordSizeType == RecordVideoTypeSquare)
                    durationField.text = _rdVECameraSDKConfigData.cameraConfiguration.cameraSquare_MaxVideoDuration == 0 ? @"" : [NSString stringWithFormat:@"%d",(int)_rdVECameraSDKConfigData.cameraConfiguration.cameraSquare_MaxVideoDuration];
                else{
                    durationField.text = _rdVECameraSDKConfigData.cameraConfiguration.cameraNotSquare_MaxVideoDuration == 0 ? @"" : [NSString stringWithFormat:@"%d",(int)_rdVECameraSDKConfigData.cameraConfiguration.cameraNotSquare_MaxVideoDuration];
                }
                
            }
                break;
            default:
                break;
        }
        
        
        [_cameraDurationSettingView addSubview:durationLabel];
        [_cameraDurationSettingView addSubview:durationField];
    }
    
    //拍摄类型3:照片
    _cameraPhotoBtn = [self createMultiSelectBtn:CGRectMake(20, _cameraDurationSettingView.frame.origin.y+_cameraDurationSettingView.frame.size.height + 20, 100, 30) title:NSLocalizedString(@"照片", nil)];
    [_cameraPhotoBtn addTarget:self action:@selector(_cameraPhotoBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraPhotoBtn setSelected: !_rdVECameraSDKConfigData.cameraConfiguration.cameraPhoto];
    [_cameraMixedSettingView addSubview:_cameraPhotoBtn];
    
    UILabel *cameraModelLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _cameraMixedSettingView.frame.origin.y + _cameraMixedSettingView.frame.size.height + 10, 100, 31)];
    cameraModelLabel.font = [UIFont systemFontOfSize:16];
    cameraModelLabel.backgroundColor = self.view.backgroundColor;
    cameraModelLabel.textColor = [UIColor whiteColor];
    cameraModelLabel.textAlignment = NSTextAlignmentLeft;
    cameraModelLabel.text = NSLocalizedString(@"拍照模式设置", nil);
    cameraModelLabel.layer.masksToBounds = YES;
    CGSize cameraModelSize = [cameraModelLabel sizeThatFits:CGSizeZero];
    cameraModelLabel.frame = CGRectMake(cameraModelLabel.frame.origin.x, cameraModelLabel.frame.origin.y, cameraModelSize.width, cameraModelLabel.frame.size.height);
    
    _cameraModelSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, cameraModelLabel.frame.size.height + cameraModelLabel.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width, 140)];
    _cameraModelSettingView.backgroundColor = [UIColor clearColor];
    _cameraModelSettingView.layer.cornerRadius = 3.0;
    _cameraModelSettingView.layer.borderWidth = 1;
    _cameraModelSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _cameraModelSettingView.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_cameraModelSettingView];
    
    [_cameraSettingScrollview addSubview:cameraModelLabel];
    for (int i = 0 ; i<2 ; i++) {
        CGRect frame;
        NSString *title;
        if (i == 0) {
            frame = CGRectMake(30, 25, 100, 30);
            title = NSLocalizedString(@"多次", nil);
        }else {
            frame = CGRectMake(30, 60, 80, 30);
            title = NSLocalizedString(@"单次", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if((_rdVECameraSDKConfigData.cameraConfiguration.cameraModelType == CameraModel_Onlyone && i == 1) || (_rdVECameraSDKConfigData.cameraConfiguration.cameraModelType == CameraModel_Manytimes && i == 0)){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(cameraModelChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i+11;
        if (i == 1) {
            _cameraWriteToAlbumSettingView = [[UIView alloc] initWithFrame:CGRectMake(5, settingItemBtn.frame.size.height + settingItemBtn.frame.origin.y - 15, _cameraModelSettingView.frame.size.width - 10, 60)];
            _cameraWriteToAlbumSettingView.backgroundColor = [UIColor clearColor];
            _cameraWriteToAlbumSettingView.layer.cornerRadius = 3.0;
            _cameraWriteToAlbumSettingView.layer.borderWidth = 1;
            _cameraWriteToAlbumSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
            _cameraWriteToAlbumSettingView.layer.masksToBounds = YES;
            [_cameraModelSettingView addSubview:_cameraWriteToAlbumSettingView];
            
            for (int i = 0 ; i<2 ; i++) {
                CGRect frame;
                NSString *title;
                if (i == 0) {
                    frame = CGRectMake(10, 20, SCREEN_WIDTH/2.0 - 10, 30);
                    title = NSLocalizedString(@"写入相册", nil);
                }else {
                    frame = CGRectMake(SCREEN_WIDTH/2.0, 20, SCREEN_WIDTH/2.0 - 10, 30);
                    title = NSLocalizedString(@"不写入相册", nil);
                }
                UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
                if((_rdVECameraSDKConfigData.cameraConfiguration.cameraWriteToAlbum && i == 0) || (!_rdVECameraSDKConfigData.cameraConfiguration.cameraWriteToAlbum && i == 1)){
                    [settingItemBtn setSelected:YES];
                }else{
                    [settingItemBtn setSelected:NO];
                }
                [settingItemBtn addTarget:self action:@selector(cameraWriteToAlbumChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
                settingItemBtn.tag = i+1;
                [_cameraWriteToAlbumSettingView addSubview:settingItemBtn];
            }
        }
        [_cameraModelSettingView addSubview:settingItemBtn];
    }
    
    UILabel *cameraFaceULabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _cameraModelSettingView.frame.origin.y + _cameraModelSettingView.frame.size.height + 20, 300, 31)];
    cameraFaceULabel.font = [UIFont systemFontOfSize:16];
    cameraFaceULabel.backgroundColor = self.view.backgroundColor;
    cameraFaceULabel.textColor = [UIColor whiteColor];
    cameraFaceULabel.textAlignment = NSTextAlignmentLeft;
    cameraFaceULabel.text = NSLocalizedString(@"人脸道具贴纸(建议在iPhone5s以上使用)", nil);
    cameraFaceULabel.layer.masksToBounds = YES;
    CGSize cameraFaceUSize = [cameraFaceULabel sizeThatFits:CGSizeZero];
    if (cameraFaceUSize.width > SCREEN_WIDTH - 20) {
        cameraFaceULabel.frame = CGRectMake(cameraFaceULabel.frame.origin.x, cameraFaceULabel.frame.origin.y, SCREEN_WIDTH - 20, cameraFaceULabel.frame.size.height);
        cameraPositionLabel.adjustsFontSizeToFitWidth = YES;
    }else {
        cameraFaceULabel.frame = CGRectMake(cameraFaceULabel.frame.origin.x, cameraFaceULabel.frame.origin.y, cameraFaceUSize.width, cameraFaceULabel.frame.size.height);
    }
    
    _cameraFaceUSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, cameraFaceULabel.frame.size.height + cameraFaceULabel.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width, 60)];
    _cameraFaceUSettingView.backgroundColor = [UIColor clearColor];
    _cameraFaceUSettingView.layer.cornerRadius = 3.0;
    _cameraFaceUSettingView.layer.borderWidth = 1;
    _cameraFaceUSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _cameraFaceUSettingView.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_cameraFaceUSettingView];
    
    [_cameraSettingScrollview addSubview:cameraFaceULabel];
    
    
    for (int i = 0 ; i<2 ; i++) {
        CGRect frame;
        NSString *title;
        if (i == 0) {
            frame = CGRectMake(30, 25, 80, 30);
            title = NSLocalizedString(@"启用", nil);
        }else {
            frame = CGRectMake(200, 25, 95, 30);
            title = NSLocalizedString(@"不启用", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if((_rdVECameraSDKConfigData.cameraConfiguration.enableFaceU && i == 0) || (!_rdVECameraSDKConfigData.cameraConfiguration.enableFaceU && i == 1)){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(cameraFaceUChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i+1;
        [_cameraFaceUSettingView addSubview:settingItemBtn];
    }
    
    UILabel *camerawatermarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _cameraFaceUSettingView.frame.origin.y + _cameraFaceUSettingView.frame.size.height + 20, 150, 31)];
    camerawatermarkLabel.font = [UIFont systemFontOfSize:16];
    camerawatermarkLabel.backgroundColor = self.view.backgroundColor;
    camerawatermarkLabel.textColor = [UIColor whiteColor];
    camerawatermarkLabel.textAlignment = NSTextAlignmentLeft;
    camerawatermarkLabel.text = NSLocalizedString(@"相机水印", nil);
    camerawatermarkLabel.layer.masksToBounds = YES;
    
    _cameraWaterMarkSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, camerawatermarkLabel.frame.size.height + camerawatermarkLabel.frame.origin.y - 15, _cameraSettingScrollview.frame.size.width, 60)];
    _cameraWaterMarkSettingView.backgroundColor = [UIColor clearColor];
    _cameraWaterMarkSettingView.layer.cornerRadius = 3.0;
    _cameraWaterMarkSettingView.layer.borderWidth = 1;
    _cameraWaterMarkSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _cameraWaterMarkSettingView.layer.masksToBounds = YES;
    [_cameraSettingScrollview addSubview:_cameraWaterMarkSettingView];
    
    [_cameraSettingScrollview addSubview:camerawatermarkLabel];
    
    for (int i = 0 ; i<2 ; i++) {
        CGRect frame;
        NSString *title;
        if (i == 0) {
            frame = CGRectMake(30, 25, 80, 30);
            title = NSLocalizedString(@"启用", nil);
        }else {
            frame = CGRectMake(200, 25, 95, 30);
            title = NSLocalizedString(@"不启用", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if((_rdVECameraSDKConfigData.cameraConfiguration.enabelCameraWaterMark && i == 0) || (!_rdVECameraSDKConfigData.cameraConfiguration.enabelCameraWaterMark && i == 1)){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(cameraMarkChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i+1;
        [_cameraWaterMarkSettingView addSubview:settingItemBtn];
    }
    
    _cameraSettingScrollview.contentSize = CGSizeMake(0, _cameraWaterMarkSettingView.frame.size.height + _cameraWaterMarkSettingView.frame.origin.y + (iPhone_X ? 34 : 0));
    
    UIButton *cancelSettingBtn;
    UIButton *saveSettingBtn;
    
    cancelSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [cancelSettingBtn setTitle:NSLocalizedString(@"返回", nil) forState:UIControlStateNormal];
    [cancelSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [cancelSettingBtn addTarget:self action:@selector(cancelCameraSettingBtnTouch) forControlEvents:UIControlEventTouchUpInside];
    cancelSettingBtn.frame = CGRectMake(_cameraSettingScrollview.frame.origin.x, _cameraSettingView.frame.size.height - 50 - (iPhone_X ? 34 : 0), _cameraSettingScrollview.frame.size.width/2.0-5, 40);
    cancelSettingBtn.layer.cornerRadius = 3.0;
    cancelSettingBtn.layer.masksToBounds = YES;
    [_cameraSettingView addSubview:cancelSettingBtn];
    
    saveSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [saveSettingBtn setTitle:NSLocalizedString(@"保存", nil) forState:UIControlStateNormal];
    [saveSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [saveSettingBtn addTarget:self action:@selector(saveCameraSettingBtnTouch) forControlEvents:UIControlEventTouchUpInside];
    saveSettingBtn.frame = CGRectMake(cancelSettingBtn.frame.origin.x + cancelSettingBtn.frame.size.width+10, cancelSettingBtn.frame.origin.y, _cameraSettingScrollview.frame.size.width/2.0-5, 40);
    saveSettingBtn.layer.cornerRadius = 3.0;
    saveSettingBtn.layer.masksToBounds = YES;
    [_cameraSettingView addSubview:saveSettingBtn];
}

- (void)releaseCameraSettingView{
    
    [_cameraSettingScrollview.subviews enumerateObjectsUsingBlock:^(__kindof UIView * obj1, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj1.subviews enumerateObjectsUsingBlock:^(__kindof UIView * obj2, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj2 removeFromSuperview];
            obj2 = nil;
        }];
        [obj1 removeFromSuperview];
        obj1 = nil;
    }];
    
    [_cameraSettingScrollview removeFromSuperview];
    _cameraSettingScrollview = nil;
    [_cameraSettingView removeFromSuperview];
    _cameraSettingView = nil;
}

- (void)cancelCameraSettingBtnTouch{
    _rdVECameraSDKConfigData.exportConfiguration = [_oldExportConfig mutableCopy];
    _rdVECameraSDKConfigData.cameraConfiguration = [_oldCameraConfig mutableCopy];
    _rdVECameraSDKConfigData.editConfiguration   = [_oldEditConfig mutableCopy];
    _oldEditConfig = nil;
    _oldCameraConfig = nil;
    _oldExportConfig = nil;
    
    [self releaseCameraSettingView];
}

- (void)saveCameraSettingBtnTouch{
    
    UITextField *mvminDurationField = [_MVRecordSettingView viewWithTag:1];
    UITextField *mvmaxDurationField = [_MVRecordSettingView viewWithTag:2];
    _rdVECameraSDKConfigData.cameraConfiguration.cameraMV_MinVideoDuration = [mvminDurationField.text floatValue];
    _rdVECameraSDKConfigData.cameraConfiguration.cameraMV_MaxVideoDuration = [mvmaxDurationField.text floatValue];
    
    UITextField *minDurationField = [_cameraDurationSettingView viewWithTag:1];
    UITextField *maxDurationField = [_cameraDurationSettingView viewWithTag:2];
    _rdVECameraSDKConfigData.cameraConfiguration.cameraMinVideoDuration = [minDurationField.text floatValue];
    _rdVECameraSDKConfigData.cameraConfiguration.cameraSquare_MaxVideoDuration = [maxDurationField.text floatValue];
    _rdVECameraSDKConfigData.cameraConfiguration.cameraNotSquare_MaxVideoDuration = [maxDurationField.text floatValue];
    
    _oldEditConfig = nil;
    _oldCameraConfig = nil;
    _oldExportConfig = nil;
    
    [self releaseCameraSettingView];
}

- (void)enableUseMusicSwitchChanged:(UISwitch *)sender{
    if (!sender.on) {
        _rdVECameraSDKConfigData.cameraConfiguration.enableUseMusic = false;
        
        _enableUseMusicLable.text = NSLocalizedString(@"录制中不播放音乐", nil);
    }else{
        _rdVECameraSDKConfigData.cameraConfiguration.enableUseMusic = true;
        _enableUseMusicLable.text = NSLocalizedString(@"录制中播放音乐", nil);
    }
}

- (void)hiddenPhotoLibChanged:(UISwitch *)sender{
    if (!sender.on) {
        _rdVECameraSDKConfigData.cameraConfiguration.hiddenPhotoLib = false;
        
        _hiddenPhotoLibraryswitchLabel.text = NSLocalizedString(@"显示相册按钮", nil);
    }else{
        _rdVECameraSDKConfigData.cameraConfiguration.hiddenPhotoLib = true;
        _hiddenPhotoLibraryswitchLabel.text = NSLocalizedString(@"隐藏相册按钮", nil);
    }
}

- (void)cameraPositionChildBtnTouch:(UIButton *)sender{
    
    switch (sender.tag) {
        case 1:
            _rdVECameraSDKConfigData.cameraConfiguration.cameraCaptureDevicePosition = AVCaptureDevicePositionFront;
            break;
        case 2:
            _rdVECameraSDKConfigData.cameraConfiguration.cameraCaptureDevicePosition = AVCaptureDevicePositionBack;
            break;
        default:
            break;
    }
    
    for (UIButton *itemBtn in _camerapositionSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)_cameraMVBtnTouch:(UIButton *)sender{
    _rdVECameraSDKConfigData.cameraConfiguration.cameraMV = sender.selected;
    sender.selected = !sender.selected;
}
- (void)_cameraVideoBtnTouch:(UIButton *)sender{
    _rdVECameraSDKConfigData.cameraConfiguration.cameraVideo = sender.selected;
    sender.selected = !sender.selected;
}

- (void)_cameraPhotoBtnTouch:(UIButton *)sender{
    _rdVECameraSDKConfigData.cameraConfiguration.cameraPhoto = sender.selected;
    sender.selected = !sender.selected;
}
- (void)cameraModelChildBtnTouch:(UIButton *)sender{
    
    switch (sender.tag) {
        case 11:
            _rdVECameraSDKConfigData.cameraConfiguration.cameraModelType = CameraModel_Manytimes;
            break;
        case 12:
            _rdVECameraSDKConfigData.cameraConfiguration.cameraModelType = CameraModel_Onlyone;
            break;
            
        default:
            break;
    }
    
    for (UIButton *itemBtn in _cameraModelSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}
- (void)cameraWriteToAlbumChildBtnTouch:(UIButton *)sender{
    
    switch (sender.tag) {
        case 1:
            _rdVECameraSDKConfigData.cameraConfiguration.cameraWriteToAlbum = true;
            break;
        case 2:
            _rdVECameraSDKConfigData.cameraConfiguration.cameraWriteToAlbum = false;
            break;
        default:
            break;
    }
    
    for (UIButton *itemBtn in _cameraWriteToAlbumSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)cameraFaceUChildBtnTouch:(UIButton *)sender{
    
    
    switch (sender.tag) {
        case 1:
            _rdVECameraSDKConfigData.cameraConfiguration.enableFaceU = true;
            break;
        case 2:
            _rdVECameraSDKConfigData.cameraConfiguration.enableFaceU = false;
            break;
        default:
            break;
    }
    
    for (UIButton *itemBtn in _cameraFaceUSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)cameraMarkChildBtnTouch:(UIButton *)sender{
    
    
    switch (sender.tag) {
        case 1:
            _rdVECameraSDKConfigData.cameraConfiguration.enabelCameraWaterMark = true;
            break;
        case 2:
            _rdVECameraSDKConfigData.cameraConfiguration.enabelCameraWaterMark = false;
            break;
        default:
            break;
    }
    
    for (UIButton *itemBtn in _cameraWaterMarkSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}
#pragma mark - 截取设置
- (void)setSpecifyCutSettings:(UIButton *)sender{
    _oldExportConfig = [_rdVETrimSDKConfigData.exportConfiguration mutableCopy];
    _oldCameraConfig = [_rdVETrimSDKConfigData.cameraConfiguration mutableCopy];
    _oldEditConfig   = [_rdVETrimSDKConfigData.editConfiguration mutableCopy];
    
    _specifyCutSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height)];
    _specifyCutSettingView.backgroundColor = self.view.backgroundColor;
    [self.navigationController.view addSubview:_specifyCutSettingView];
    
    float width = MIN(_specifyCutSettingView.frame.size.width, _specifyCutSettingView.frame.size.height);
    _specifyCutsettingScrollView = [[UIScrollView alloc] init];
    _specifyCutsettingScrollView.frame = CGRectMake((_specifyCutSettingView.frame.size.width - width), 20, width, _specifyCutSettingView.frame.size.height - 84);
    _specifyCutsettingScrollView.backgroundColor = self.view.backgroundColor;
    [_specifyCutSettingView addSubview:_specifyCutsettingScrollView];
    
    UILabel *trimActionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 70, 31)];
    trimActionLabel.font = [UIFont systemFontOfSize:16];
    trimActionLabel.backgroundColor = self.view.backgroundColor;
    trimActionLabel.textColor = [UIColor whiteColor];
    trimActionLabel.textAlignment = NSTextAlignmentLeft;
    trimActionLabel.text = NSLocalizedString(@"截取行为", nil);
    trimActionLabel.layer.masksToBounds = YES;
    
    _trimActionSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, trimActionLabel.frame.size.height + trimActionLabel.frame.origin.y - 15, _specifyCutsettingScrollView.frame.size.width, 120)];
    _trimActionSettingView.backgroundColor = [UIColor clearColor];
    _trimActionSettingView.layer.cornerRadius = 3.0;
    _trimActionSettingView.layer.borderWidth = 1;
    _trimActionSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _trimActionSettingView.layer.masksToBounds = YES;
    [_specifyCutsettingScrollView addSubview:_trimActionSettingView];
    [_specifyCutsettingScrollView addSubview:trimActionLabel];
    
    for (int i = 0 ; i<3 ; i++) {
        CGRect frame = CGRectMake(20, 30 * i + 15, 105, 30);
        NSString *title;
        if (i == 0) {
            title = NSLocalizedString(@"真实截取", nil);
        }else if (i == 1) {
            title = NSLocalizedString(@"返回时间段", nil);
        }else {
            title = NSLocalizedString(@"动态截取", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if(i == _cutVideoRetrunType){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(trimActionSettingChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i;
        [_trimActionSettingView addSubview:settingItemBtn];
    }
    
    UILabel *trimTimeSettingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, _trimActionSettingView.frame.origin.y + _trimActionSettingView.frame.size.height + 20, 70, 31)];
    trimTimeSettingLabel.font = [UIFont systemFontOfSize:16];
    trimTimeSettingLabel.backgroundColor = self.view.backgroundColor;
    trimTimeSettingLabel.textColor = [UIColor whiteColor];
    trimTimeSettingLabel.textAlignment = NSTextAlignmentLeft;
    trimTimeSettingLabel.text = NSLocalizedString(@"截取时间", nil);
    trimTimeSettingLabel.layer.masksToBounds = YES;
    CGSize trimTimeSettingSize = [trimTimeSettingLabel sizeThatFits:CGSizeZero];
    trimTimeSettingLabel.frame = CGRectMake(trimTimeSettingLabel.frame.origin.x, trimTimeSettingLabel.frame.origin.y, trimTimeSettingSize.width + 10, trimTimeSettingLabel.frame.size.height);
    
    _trimTimeSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, trimTimeSettingLabel.frame.size.height + trimTimeSettingLabel.frame.origin.y - 15, _specifyCutsettingScrollView.frame.size.width, 120)];
    _trimTimeSettingView.backgroundColor = [UIColor clearColor];
    _trimTimeSettingView.layer.cornerRadius = 3.0;
    _trimTimeSettingView.layer.borderWidth = 1;
    _trimTimeSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _trimTimeSettingView.layer.masksToBounds = YES;
    [_specifyCutsettingScrollView addSubview:_trimTimeSettingView];
    [_specifyCutsettingScrollView addSubview:trimTimeSettingLabel];
    
    for (int i = 0 ; i<3 ; i++) {
        CGRect frame = CGRectMake(20, 30 * i + 15, 100, 30);
        NSString *title;
        if (i == 0) {
            title = NSLocalizedString(@"自由截取", nil);
        }else if (i == 1) {
            title = NSLocalizedString(@"单个定长截取", nil);
        } else {
            title = NSLocalizedString(@"两个定长截取", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if(i == _rdVETrimSDKConfigData.editConfiguration.trimMode){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        [settingItemBtn addTarget:self action:@selector(trimTimeSettingChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i;
        [_trimTimeSettingView addSubview:settingItemBtn];
    }
    
    UILabel *videoCropLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, _trimTimeSettingView.frame.origin.y + _trimTimeSettingView.frame.size.height + 20, 100, 31)];
    videoCropLabel.font = [UIFont systemFontOfSize:16];
    videoCropLabel.backgroundColor = self.view.backgroundColor;
    videoCropLabel.textColor = [UIColor whiteColor];
    videoCropLabel.textAlignment = NSTextAlignmentLeft;
    videoCropLabel.text = NSLocalizedString(@"视频裁剪比例", nil);
    videoCropLabel.layer.masksToBounds = YES;
    CGSize videoCropSize = [videoCropLabel sizeThatFits:CGSizeZero];
    videoCropLabel.frame = CGRectMake(videoCropLabel.frame.origin.x, videoCropLabel.frame.origin.y, videoCropSize.width + 10, videoCropLabel.frame.size.height);
    
    _trimVideoProportionSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, videoCropLabel.frame.size.height + videoCropLabel.frame.origin.y - 15, _specifyCutsettingScrollView.frame.size.width, 150)];
    _trimVideoProportionSettingView.backgroundColor = [UIColor clearColor];
    _trimVideoProportionSettingView.layer.cornerRadius = 3.0;
    _trimVideoProportionSettingView.layer.borderWidth = 1;
    _trimVideoProportionSettingView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _trimVideoProportionSettingView.layer.masksToBounds = YES;
    [_specifyCutsettingScrollView addSubview:_trimVideoProportionSettingView];
    [_specifyCutsettingScrollView addSubview:videoCropLabel];
    
    for (int i = 0 ; i<4 ; i++) {
        CGRect frame = CGRectMake(20, 30 * i + 15, 100, 30);
        NSString *title;
        if (i == 0) {
            title = NSLocalizedString(@"原始", nil);
        }else if (i == 1) {
            title = NSLocalizedString(@"1比1", nil);
        }else if (i == 2) {
            title = NSLocalizedString(@"默认为原始,可切换", nil);
        } else {
            title = NSLocalizedString(@"默认为1比1,可切换", nil);
        }
        UIButton *settingItemBtn = [self createSingleBtn:frame title:title];
        if(i == _rdVETrimSDKConfigData.editConfiguration.trimExportVideoType){
            [settingItemBtn setSelected:YES];
        }else{
            [settingItemBtn setSelected:NO];
        }
        if(_rdVETrimSDKConfigData.editConfiguration.trimMode == TRIMMODEAUTOTIME){
            [settingItemBtn setEnabled:NO];
        }else{
            [settingItemBtn setEnabled:YES];
        }
        [settingItemBtn addTarget:self action:@selector(trimVideoCropSettingChildBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        settingItemBtn.tag = i;
        [_trimVideoProportionSettingView addSubview:settingItemBtn];
    }
    
    [_specifyCutsettingScrollView setContentSize:CGSizeMake(0, _trimVideoProportionSettingView.frame.origin.y + _trimVideoProportionSettingView.frame.size.height + 20 + (iPhone_X ? 34 : 0))];
    
    UIButton *cancelSettingBtn;
    UIButton *saveSettingBtn;
    
    cancelSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [cancelSettingBtn setTitle:NSLocalizedString(@"返回", nil) forState:UIControlStateNormal];
    [cancelSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [cancelSettingBtn addTarget:self action:@selector(cancelSpecifyCutSettingBtnTouch) forControlEvents:UIControlEventTouchUpInside];
    cancelSettingBtn.frame = CGRectMake(_specifyCutsettingScrollView.frame.origin.x, _specifyCutSettingView.frame.size.height - 50 - (iPhone_X ? 34 : 0), _specifyCutsettingScrollView.frame.size.width/2.0-5, 40);
    cancelSettingBtn.layer.cornerRadius = 3.0;
    cancelSettingBtn.layer.masksToBounds = YES;
    [_specifyCutSettingView addSubview:cancelSettingBtn];
    
    saveSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [saveSettingBtn setTitle:NSLocalizedString(@"保存", nil) forState:UIControlStateNormal];
    [saveSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [saveSettingBtn addTarget:self action:@selector(saveSpecifyCutSettingBtnTouch) forControlEvents:UIControlEventTouchUpInside];
    saveSettingBtn.frame = CGRectMake(cancelSettingBtn.frame.origin.x + cancelSettingBtn.frame.size.width+10, cancelSettingBtn.frame.origin.y, _specifyCutsettingScrollView.frame.size.width/2.0-5, 40);
    saveSettingBtn.layer.cornerRadius = 3.0;
    saveSettingBtn.layer.masksToBounds = YES;
    
    [_specifyCutSettingView addSubview:saveSettingBtn];
    [self.navigationController.view addSubview:_specifyCutSettingView];
}

- (void)cancelSpecifyCutSettingBtnTouch{
    _rdVETrimSDKConfigData.exportConfiguration = [_oldExportConfig mutableCopy];
    _rdVETrimSDKConfigData.cameraConfiguration = [_oldCameraConfig mutableCopy];
    _rdVETrimSDKConfigData.editConfiguration   = [_oldEditConfig mutableCopy];
    _oldEditConfig = nil;
    _oldCameraConfig = nil;
    _oldExportConfig = nil;
    _cutVideoRetrunType = _cutVideoRetrunTypeOld;
    [self releaseSpecifyCutSettingView];
}

- (void)saveSpecifyCutSettingBtnTouch{
    _oldExportConfig = nil;
    _oldCameraConfig = nil;
    _oldEditConfig = nil;
    [self releaseSpecifyCutSettingView];
}

- (void)trimActionSettingChildBtnTouch:(UIButton *)sender{
    _cutVideoRetrunType = sender.tag;
    for (UIButton *itemBtn in _trimActionSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)trimTimeSettingChildBtnTouch:(UIButton *)sender{
    _rdVETrimSDKConfigData.editConfiguration.trimMode = sender.tag;
    for (UIButton *itemBtn in _trimTimeSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
            
        }
    }
    
    if(_rdVETrimSDKConfigData.editConfiguration.trimMode ==TRIMMODEAUTOTIME){
        _rdVETrimSDKConfigData.editConfiguration.trimExportVideoType = TRIMEXPORTVIDEOTYPE_ORIGINAL;
        for (UIButton *itemBtn in _trimVideoProportionSettingView.subviews) {
            if([itemBtn isKindOfClass:[UIButton class]]){
                [itemBtn setEnabled:NO];
            }
        }
    }else{
        for (UIButton *itemBtn in _trimVideoProportionSettingView.subviews) {
            if([itemBtn isKindOfClass:[UIButton class]]){
                [itemBtn setEnabled:YES];
            }
        }
    }
}

- (void)trimVideoCropSettingChildBtnTouch:(UIButton *)sender{
    _rdVETrimSDKConfigData.editConfiguration.trimExportVideoType = sender.tag;
    for (UIButton *itemBtn in _trimVideoProportionSettingView.subviews) {
        if([itemBtn isKindOfClass:[UIButton class]]){
            if(itemBtn.tag == sender.tag){
                [itemBtn setSelected:YES];
            }else{
                [itemBtn setSelected:NO];
            }
        }
    }
}

- (void)releaseSpecifyCutSettingView{
    
    [_specifyCutsettingScrollView removeFromSuperview];
    _specifyCutsettingScrollView = nil;
    [_specifyCutSettingView removeFromSuperview];
    _specifyCutSettingView = nil;
}

#pragma mark - 进入相册设置
- (void)setSelectPhotoSettings:(UIButton *)sender{
    if(_selectPhotoSettingView){
        NSLog(@"没释放_selectPhotoSettingView");
    }
    _oldExportConfig = [_rdVESelectAlbumSDKConfigData.exportConfiguration mutableCopy];
    _oldCameraConfig = [_rdVESelectAlbumSDKConfigData.cameraConfiguration mutableCopy];
    _oldEditConfig   = [_rdVESelectAlbumSDKConfigData.editConfiguration mutableCopy];
    
    _selectPhotoSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height)];
    _selectPhotoSettingView.backgroundColor = self.view.backgroundColor;
    [self.navigationController.view addSubview:_selectPhotoSettingView];
    
    float width = MIN(_selectPhotoSettingView.frame.size.width, _selectPhotoSettingView.frame.size.height);
    
    _photoAlbumSettingScrollView = [[UIScrollView alloc] init];
    _photoAlbumSettingScrollView.frame = CGRectMake((_selectPhotoSettingView.frame.size.width - width), 20, width, _selectPhotoSettingView.frame.size.height - 84);
    _photoAlbumSettingScrollView.backgroundColor = self.view.backgroundColor;
    [_selectPhotoSettingView addSubview:_photoAlbumSettingScrollView];
    
    //隐藏拍摄按钮
    _enableAlbumCameraBtnSwitchBtn = [[UISwitch alloc] initWithFrame:CGRectMake(20, 24, 59, 25)];
    [_enableAlbumCameraBtnSwitchBtn setOnImage:[self ImageWithColor:UIColorFromRGB(0xffffff) cornerRadius:1]];
    [_enableAlbumCameraBtnSwitchBtn setOffImage:[self ImageWithColor:UIColorFromRGB(0x000000) cornerRadius:1]];
    [_enableAlbumCameraBtnSwitchBtn setThumbTintColor:[UIColor whiteColor]];
    [_enableAlbumCameraBtnSwitchBtn addTarget:self action:@selector(_enableAlbumCameraBtnSwitchBtnChanged:) forControlEvents:UIControlEventValueChanged];
    [_photoAlbumSettingScrollView addSubview:_enableAlbumCameraBtnSwitchBtn];
    
    
    _enableAlbumCameraBtnswitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, _enableAlbumCameraBtnSwitchBtn.frame.origin.y, _photoAlbumSettingScrollView.frame.size.width - 120, 31)];
    _enableAlbumCameraBtnswitchLabel.font = [UIFont systemFontOfSize:16];
    _enableAlbumCameraBtnswitchLabel.backgroundColor = [UIColor clearColor];
    _enableAlbumCameraBtnswitchLabel.textColor = [UIColor whiteColor];
    _enableAlbumCameraBtnswitchLabel.textAlignment = NSTextAlignmentCenter;
    _enableAlbumCameraBtnswitchLabel.text = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera ? NSLocalizedString(@"显示拍摄按钮", nil) : NSLocalizedString(@"隐藏拍摄按钮", nil);
    _enableAlbumCameraBtnswitchLabel.layer.masksToBounds = YES;
    [_photoAlbumSettingScrollView addSubview:_enableAlbumCameraBtnswitchLabel];
    
    
    _mediaCountLimitView = [[UIView alloc] initWithFrame:CGRectMake(0, _enableAlbumCameraBtnSwitchBtn.frame.origin.y + _enableAlbumCameraBtnSwitchBtn.frame.size.height + 24, _photoAlbumSettingScrollView.frame.size.width, 60)];
    _mediaCountLimitView.backgroundColor = [UIColor clearColor];
    _mediaCountLimitView.layer.cornerRadius = 3.0;
    _mediaCountLimitView.layer.borderWidth = 1;
    _mediaCountLimitView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    _mediaCountLimitView.layer.masksToBounds = YES;
    [_photoAlbumSettingScrollView addSubview:_mediaCountLimitView];
    
    UILabel *mediacountLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (_mediaCountLimitView.frame.size.height - 31)/2.0 , _mediaCountLimitView.frame.size.width - 20 - 170, 31)];
    mediacountLabel.font = [UIFont systemFontOfSize:18];
    mediacountLabel.backgroundColor = [UIColor clearColor];
    mediacountLabel.textColor = [UIColor whiteColor];
    mediacountLabel.textAlignment = NSTextAlignmentLeft;
    mediacountLabel.text = NSLocalizedString(@"限制相册选择个数:", nil);
    mediacountLabel.layer.masksToBounds = YES;
    [_mediaCountLimitView addSubview:mediacountLabel];
    
    
    _mediaCountLimitField = [[UITextField alloc] init];
    _mediaCountLimitField.frame = CGRectMake(_mediaCountLimitView.frame.size.width - 165, mediacountLabel.frame.origin.y, 160, 31);
    _mediaCountLimitField.layer.borderColor    = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    _mediaCountLimitField.layer.borderWidth    = 1;
    _mediaCountLimitField.layer.cornerRadius   = 3;
    _mediaCountLimitField.layer.masksToBounds  = YES;
    _mediaCountLimitField.delegate             = self;
    //_mediaCountLimitField.keyboardType         = UIKeyboardTypePhonePad;
    _mediaCountLimitField.returnKeyType        = UIReturnKeyDone;
    _mediaCountLimitField.textAlignment        = NSTextAlignmentCenter;
    _mediaCountLimitField.textColor            = UIColorFromRGB(0xffffff);
    NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"默认是0,不限制", nil)];
    [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
    _mediaCountLimitField.attributedPlaceholder = attrstr1;
    [_mediaCountLimitView addSubview:_mediaCountLimitField];
    
    [_photoAlbumSettingScrollView setContentSize:CGSizeMake(0, _mediaCountLimitView.frame.origin.y + _mediaCountLimitView.frame.size.height + 20 + (iPhone_X ? 34 : 0))];
    
    [_enableAlbumCameraBtnSwitchBtn setOn:(_rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera ? YES : NO)];
    if(_rdVESelectAlbumSDKConfigData.editConfiguration.mediaCountLimit !=0){
        _mediaCountLimitField.text = [NSString stringWithFormat:@"%d",_rdVESelectAlbumSDKConfigData.editConfiguration.mediaCountLimit];
    }
    
    UIButton *cancelSettingBtn;
    UIButton *saveSettingBtn;
    
    cancelSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [cancelSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [cancelSettingBtn setTitle:NSLocalizedString(@"返回", nil) forState:UIControlStateNormal];
    [cancelSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [cancelSettingBtn addTarget:self action:@selector(cancelSelectedPhotoSettingBtnTouch) forControlEvents:UIControlEventTouchUpInside];
    cancelSettingBtn.frame = CGRectMake(_photoAlbumSettingScrollView.frame.origin.x, _selectPhotoSettingView.frame.size.height - 50 - (iPhone_X ? 34 : 0), _selectPhotoSettingView.frame.size.width/2.0-5, 40);
    cancelSettingBtn.layer.cornerRadius = 3.0;
    cancelSettingBtn.layer.masksToBounds = YES;
    [_selectPhotoSettingView addSubview:cancelSettingBtn];
    
    saveSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateNormal];
    [saveSettingBtn setBackgroundImage:[self ImageWithColor:[UIColor whiteColor] cornerRadius:1] forState:UIControlStateSelected];
    [saveSettingBtn setTitle:NSLocalizedString(@"保存", nil) forState:UIControlStateNormal];
    [saveSettingBtn setTitleColor:UIColorFromRGB(0x0e0e10) forState:UIControlStateNormal];
    [saveSettingBtn addTarget:self action:@selector(saveSelectedPhotoSettingBtnTouch) forControlEvents:UIControlEventTouchUpInside];
    saveSettingBtn.frame = CGRectMake(cancelSettingBtn.frame.origin.x + cancelSettingBtn.frame.size.width+10, cancelSettingBtn.frame.origin.y, _selectPhotoSettingView.frame.size.width/2.0-5, 40);
    saveSettingBtn.layer.cornerRadius = 3.0;
    saveSettingBtn.layer.masksToBounds = YES;
    
    [_selectPhotoSettingView addSubview:saveSettingBtn];
}

- (void)releasephotoAlbumsettingView{
    
    [_photoAlbumSettingScrollView removeFromSuperview];
    _photoAlbumSettingScrollView = nil;
    [_selectPhotoSettingView removeFromSuperview];
    _selectPhotoSettingView = nil;
}

- (void)_enableAlbumCameraBtnSwitchBtnChanged:(UISwitch *)sender{
    if (!sender.on) {
        _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera = false;
        
        _enableAlbumCameraBtnswitchLabel.text = NSLocalizedString(@"隐藏拍摄按钮", nil);
    }else{
        _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera = true;
        _enableAlbumCameraBtnswitchLabel.text = NSLocalizedString(@"显示拍摄按钮", nil);
    }
}

- (void)cancelSelectedPhotoSettingBtnTouch{
    _rdVESelectAlbumSDKConfigData.exportConfiguration = [_oldExportConfig mutableCopy];
    _oldExportConfig = nil;
    _rdVESelectAlbumSDKConfigData.cameraConfiguration = [_oldCameraConfig mutableCopy];
    _oldCameraConfig = nil;
    _rdVESelectAlbumSDKConfigData.editConfiguration   = [_oldEditConfig mutableCopy];
    _oldEditConfig = nil;
    [self releasephotoAlbumsettingView];
}

- (void)saveSelectedPhotoSettingBtnTouch{
    int mediacount = [_mediaCountLimitField.text intValue];
    _rdVESelectAlbumSDKConfigData.editConfiguration.mediaCountLimit = mediacount;
    _oldExportConfig = nil;
    _oldCameraConfig = nil;
    _oldEditConfig = nil;
    [self releasephotoAlbumsettingView];
}

#pragma mark- 压缩设置
- (void) initCompressView:(AVURLAsset *) asset exportPath:(NSString *)exportPath{
    if(!_compressOutputPath){
        return;
    }
    
    _compressSettingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height)];
    _compressSettingView.backgroundColor = self.view.backgroundColor;
    
    float width = MIN(_compressSettingView.frame.size.width, _compressSettingView.frame.size.height);
    NSDictionary* information = [_edittingSdk getVideoInformation:asset];
    int videoWidth = [[information objectForKey:@"width"] intValue];
    int videoHeight = [[information objectForKey:@"height"] intValue];
    float videoFps = [[information objectForKey:@"fps"] floatValue];
    float videoBitrate = [[information objectForKey:@"bitrate"] floatValue];
    
    NSLog(@"%d %d %f %f",videoWidth,videoHeight,videoFps,videoBitrate);
    
    UILabel* currentVideoSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    currentVideoSizeLabel.center = CGPointMake(width/2, 80);
    currentVideoSizeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"视频分辨率为:%dX%d", nil),videoWidth,videoHeight];
    currentVideoSizeLabel.textColor = [UIColor whiteColor];
    
    currentVideoSizeLabel.textAlignment = NSTextAlignmentLeft;
    [_compressSettingView addSubview:currentVideoSizeLabel];
    
    UILabel* currentVideoFpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    currentVideoFpsLabel.center = CGPointMake(width/2, 110);
    currentVideoFpsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"视频帧率为:%d", nil),(int)videoFps];
    currentVideoFpsLabel.textColor = [UIColor whiteColor];
    
    currentVideoFpsLabel.textAlignment = NSTextAlignmentLeft;
    [_compressSettingView addSubview:currentVideoFpsLabel];
    
    UILabel* currentVideoBitrateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    currentVideoBitrateLabel.center = CGPointMake(width/2, 140);
    currentVideoBitrateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"视频码率为:%.2fM", nil),videoBitrate/1000000];
    currentVideoBitrateLabel.textColor = [UIColor whiteColor];
    
    currentVideoBitrateLabel.textAlignment = NSTextAlignmentLeft;
    [_compressSettingView addSubview:currentVideoBitrateLabel];
    
    UILabel* changeVideoSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    changeVideoSizeLabel.center = CGPointMake(width/2, 170);
    changeVideoSizeLabel.text = NSLocalizedString(@"改变视频分辨率", nil);
    changeVideoSizeLabel.textColor = [UIColor whiteColor];
    
    changeVideoSizeLabel.textAlignment = NSTextAlignmentLeft;
    [_compressSettingView addSubview:changeVideoSizeLabel];
    
    UITextField* changeVideoWidtheField = [[UITextField alloc] initWithFrame:CGRectMake(125, 158, (width-140)/2 , 25)];
    changeVideoWidtheField.layer.borderColor = [UIColor whiteColor].CGColor;
    changeVideoWidtheField.layer.borderWidth = 1;
    changeVideoWidtheField.layer.cornerRadius = 1;
    changeVideoWidtheField.layer.masksToBounds = YES;
    changeVideoWidtheField.textAlignment = NSTextAlignmentCenter;
    changeVideoWidtheField.delegate = self;
    
    NSMutableAttributedString* attrstr1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@1000", NSLocalizedString(@"默认", nil)]];
    [attrstr1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr1.length)];
    changeVideoWidtheField.attributedPlaceholder = attrstr1;
    changeVideoWidtheField.returnKeyType = UIReturnKeyDefault;
    changeVideoWidtheField.textColor = [UIColor whiteColor];
    [_compressSettingView addSubview:changeVideoWidtheField];
    
    
    UITextField* changeVideoHeightField = [[UITextField alloc] initWithFrame:CGRectMake(125 + (width-140)/2 + 5, 158, (width-140)/2 , 25)];
    changeVideoHeightField.layer.borderColor = [UIColor whiteColor].CGColor;
    changeVideoHeightField.layer.borderWidth = 1;
    changeVideoHeightField.layer.cornerRadius = 1;
    changeVideoHeightField.layer.masksToBounds = YES;
    changeVideoHeightField.delegate = self;
    NSMutableAttributedString* attrstr2 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@800", NSLocalizedString(@"默认", nil)]];
    [attrstr2 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr2.length)];
    
    changeVideoHeightField.attributedPlaceholder = attrstr2;
    changeVideoHeightField.textAlignment = NSTextAlignmentCenter;
    changeVideoHeightField.returnKeyType = UIReturnKeyDefault;
    changeVideoHeightField.textColor = [UIColor whiteColor];
    
    [_compressSettingView addSubview:changeVideoHeightField];
    
    UILabel* changeVideoBitrateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    changeVideoBitrateLabel.center = CGPointMake(width/2, 200);
    changeVideoBitrateLabel.text = NSLocalizedString(@"改变视频码率", nil);
    changeVideoBitrateLabel.textColor = [UIColor whiteColor];
    
    changeVideoBitrateLabel.textAlignment = NSTextAlignmentLeft;
    [_compressSettingView addSubview:changeVideoBitrateLabel];
    
    UITextField* changeVideoBitrateField = [[UITextField alloc] initWithFrame:CGRectMake(125, 188, width-130, 25)];
    changeVideoBitrateField.layer.borderColor = [UIColor whiteColor].CGColor;
    changeVideoBitrateField.layer.borderWidth = 1;
    changeVideoBitrateField.layer.cornerRadius = 1;
    changeVideoBitrateField.layer.masksToBounds = YES;
    changeVideoBitrateField.delegate = self;
    changeVideoBitrateField.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString* attrstr3 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"单位兆(M),默认6", nil)];
    [attrstr3 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrstr3.length)];
    
    changeVideoBitrateField.attributedPlaceholder = attrstr3;
    changeVideoBitrateField.returnKeyType = UIReturnKeyDefault;
    changeVideoBitrateField.textColor = [UIColor whiteColor];
    [_compressSettingView addSubview:changeVideoBitrateField];
    
    UILabel* progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    progressLabel.center = CGPointMake(width/2, 230);
    progressLabel.textColor = [UIColor whiteColor];
    progressLabel.text = NSLocalizedString(@"压缩进度", nil);
    progressLabel.textAlignment = NSTextAlignmentLeft;
    [_compressSettingView addSubview:progressLabel];
    
    UIProgressView* progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    progressView.center = CGPointMake(width/2, 260);
    progressView.trackTintColor = [UIColor whiteColor];
    progressView.progressTintColor = [UIColor blueColor];
    
    [progressView setProgressViewStyle:UIProgressViewStyleDefault];
    [_compressSettingView addSubview:progressView];
    
    UIButton* compressBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    compressBtn.backgroundColor =[UIColor whiteColor];
    compressBtn.frame = CGRectMake(0, 0, 100, 50);
    compressBtn.center = CGPointMake(width/2 - 100, 300);
    [compressBtn setTitle:NSLocalizedString(@"压缩", nil) forState:UIControlStateNormal];
    [compressBtn setTitleColor:UIColorFromRGB(0x7e8181) forState:UIControlStateNormal];
    compressBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    compressBtn.layer.cornerRadius = 4.0;
    compressBtn.layer.masksToBounds = YES;
#if 1
    __weak ViewController *myself = self;
    
    __weak typeof(compressBtn) weakCompressBtn = compressBtn;
    [compressBtn addTapBlock:^(UIButton *btn) {
        
        if(btn.selected){
            return ;
        }
        __strong ViewController *strongSelf = myself;
        btn.selected = YES;
        weakCompressBtn.userInteractionEnabled = NO;
        [changeVideoHeightField resignFirstResponder];
        [changeVideoWidtheField resignFirstResponder];
        [changeVideoBitrateField resignFirstResponder];
        
        int w = [changeVideoWidtheField.text intValue];
        w = w==0?1000:w;
        w = w > 4000?4000:w;
        
        
        int h = [changeVideoHeightField.text intValue];
        h = h==0?800:h;
        h = h > 4000?4000:h;
        
        
        float b = [changeVideoBitrateField.text floatValue];
        b = (b==0.0)?6.0:b;
        
        strongSelf.edittingSdk.exportConfiguration.condenseVideoResolutionRatio = CGSizeMake(w, h);
        strongSelf.edittingSdk.exportConfiguration.videoBitRate = b;
        [strongSelf.edittingSdk compressVideoAsset:asset
                              outputPath:exportPath
                               startTime:kCMTimeZero
                                 endTime:asset.duration
                              outputSize:strongSelf.edittingSdk.exportConfiguration.condenseVideoResolutionRatio
                           outputBitrate:strongSelf.edittingSdk.exportConfiguration.videoBitRate
                              supperView:strongSelf
                           progressBlock:^(float prencent) {
                               NSLog(@"progress:%f",prencent);
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   progressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"压缩进度%.2f%%", nil),prencent*100.0];
                                   [progressView setProgress:prencent animated:YES];
                                   
                               });
                               
                           } callbackBlock:^(NSString *videoPath){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   
                                   [progressView removeFromSuperview];
                                   [progressLabel removeFromSuperview];
                                   
                                   NSLog(@"%f",[strongSelf fileSizeAtPath:videoPath]);
                                   
                                   strongSelf->_compressSettingView.alpha = 0.0;
                                   
                                   PlayVideoController *playVC = [[PlayVideoController alloc] init];
                                   if(!(videoPath.length>0)){
                                       NSString *path = [[NSBundle mainBundle] pathForResource:@"testFile1" ofType:@"mov"];
                                       playVC.videoPath = path;
                                       
                                   }else{
                                       playVC.videoPath = videoPath;
                                   }
                                   btn.selected = NO;
                                   [strongSelf.navigationController pushViewController:playVC animated:NO];
                                   strongSelf.edittingSdk = nil;
                                   [strongSelf releaseCompressSettingView];
                                   
                               });
                           } fail:^(NSError *error){
                               NSLog(@"%@",error);
                               btn.selected = NO;
                               strongSelf.edittingSdk = nil;
                           }];
        
    }];
#endif
    
    [_compressSettingView addSubview:compressBtn];
    
    UIButton* cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 100, 50);
    cancelBtn.center = CGPointMake(width/2 + 100, 300);
    cancelBtn.backgroundColor = [UIColor whiteColor];
    [cancelBtn setTitle:NSLocalizedString(@"取消", nil) forState:UIControlStateNormal];
    
    cancelBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    cancelBtn.layer.cornerRadius = 4.0;
    cancelBtn.layer.masksToBounds = YES;
    [cancelBtn setTitleColor:UIColorFromRGB(0x7e8181) forState:UIControlStateNormal];
#if 1
    [cancelBtn addTapBlock:^(UIButton *btn) {
        NSLog(@"取消");
        [changeVideoHeightField resignFirstResponder];
        [changeVideoWidtheField resignFirstResponder];
        [changeVideoBitrateField resignFirstResponder];
        
        __strong ViewController *strongSelf = myself;
        [strongSelf.edittingSdk compressCancel];
        strongSelf.edittingSdk= nil;
        strongSelf->_compressSettingView.hidden = YES;
        [strongSelf releaseCameraSettingView];
        
    }];
    
#endif
    [_compressSettingView addSubview:cancelBtn];
    
    
    [self.navigationController.view addSubview:_compressSettingView];
    
}

- (void)releaseCompressSettingView{
    [_compressSettingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    
    [_compressSettingView removeFromSuperview];
    _compressSettingView = nil;
}

- (float ) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        long long size = [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
        float s = (float)size/1024.0/1024.0;
        
        return s;
    }
    return 0;
}

#pragma mark-

- (UIImage *) ImageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius {
    CGFloat minEdgeSize = cornerRadius * 2 + 1;
    CGRect rect = CGRectMake(0, 0, minEdgeSize, minEdgeSize);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
    roundedRect.lineWidth = 0;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    [roundedRect fill];
    [roundedRect stroke];
    [roundedRect addClip];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [_functionList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[_functionList[section] objectForKey:@"functionList"] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
    headView.backgroundColor = [UIColor clearColor];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 12, headView.frame.size.width - 60, 20)];
    
    titleLabel.font = [UIFont systemFontOfSize:18];
    titleLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.text = [NSString stringWithFormat:@"%ld.%@", (long)(section + 1), NSLocalizedString([_functionList[section] objectForKey:@"title"], nil)];
    titleLabel.layer.masksToBounds = YES;
    [headView addSubview:titleLabel];
    
    if(section == FunctionType_RDRecord
       || section == FunctionType_VideoEdit
       || section == FunctionType_SmallFunctions
       || section == FunctionType_SelectAlbum)
    {
        UIButton *settingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        settingBtn.backgroundColor = [UIColor clearColor];
        [settingBtn setTitle:NSLocalizedString(@"设置", nil) forState:UIControlStateNormal];
        [settingBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        if(section == FunctionType_RDRecord){
            [settingBtn addTarget:self action:@selector(setcameraSettings:) forControlEvents:UIControlEventTouchUpInside];
        }else if(section == FunctionType_VideoEdit){
            [settingBtn addTarget:self action:@selector(settingBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
        }else if(section == FunctionType_SmallFunctions){
            [settingBtn addTarget:self action:@selector(setSpecifyCutSettings:) forControlEvents:UIControlEventTouchUpInside];
        }else  if(section == FunctionType_SelectAlbum){
            [settingBtn addTarget:self action:@selector(setSelectPhotoSettings:) forControlEvents:UIControlEventTouchUpInside];
        }
        settingBtn.frame = CGRectMake(headView.frame.size.width - 70, 5, 60, 30);
        settingBtn.layer.cornerRadius = 3.0;
        settingBtn.tag = section;
        settingBtn.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
        settingBtn.layer.borderWidth = 1;
        settingBtn.layer.masksToBounds = YES;
        [headView addSubview:settingBtn];
    }
    return headView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"(%ld) %@", indexPath.row + 1, NSLocalizedString([[_functionList[indexPath.section] objectForKey:@"functionList"] objectAtIndex:indexPath.row], nil)];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case FunctionType_RDRecord:
            [self recordVideoWithType:indexPath.row];
            break;
//        case FunctionType_DouYinRecord:
//            [self douYinRecordWithType:indexPath.row];
//            break;
        case FunctionType_VideoEdit:
            if (indexPath.row == 2) {
                [self editDraft];
            }else {
                [self editVideoWithType:indexPath.row];
            }
            break;
        case FunctionType_Doge:
        {
            [self editDogePuzzle];
        }
            break;
        case FunctionType_PictureMovie:
            if (indexPath.row == 0) {
                [self pictureMovie:indexPath.row];
            }else {
                [self aeTemplateMovie:NO];
            }
            break;
        case FunctionType_CreativeVideo:
            if(indexPath.row == 0){
                [self assetAddMVEffect];
            }else if(indexPath.row == 1) {
                [self aeHomeVC];
            }else if(indexPath.row == 2) {
                [self enterTextAnimateVC];
            }else if(indexPath.row == 3)  {
                [self enterCustomDraw];
            }
            else if(indexPath.row == 4)  {
                [self enterTextVideoVC];
            }
            break;
        case FunctionType_Trapezium:
            if(indexPath.row == 0){
                [self shapedAsset];
            } else{
                [self transitionfromPic];
            }
            break;
        case FunctionType_Heteromorphic:
            [self editVideoWithType_SpecialShaped:indexPath.row];
            break;
        case FunctionType_ShortVideo:
            if(indexPath.row == 0){
                [self shortVideoEdit];
            }
            break;
        case FunctionType_VideoTrim:
            [self trimVideo];

            break;
        case FunctionType_SelectAlbum:
            [self onrdVEAlbumWithType:indexPath.row];
            break;
        case FunctionType_SmallFunctions:
            [self smallFunctionWithType:indexPath.row];
            break;
        case FunctionType_VideoCompression:
            [self compressVideo];
            break;
        case FunctionType_SoundEffect:
//            [self mtstomp4];
            [self audioFilter];
            break;
        default:
            break;
    }
}


#pragma mark- 图片异形
- (UIImage *)fullSizeImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation
{
    UIImage *result = nil;
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc((size_t)(sizeof(uint8_t)*[assetRepresentation size]));
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:(int)[assetRepresentation size] error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];
        
        free(buffer);
    }
    
    if ([data length])
    {
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceShouldAllowFloat];
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
        [options setObject:(id)[NSNumber numberWithFloat:1000] forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
        
        CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
        
        if (imageRef) {
            result = [UIImage imageWithCGImage:imageRef scale:[assetRepresentation scale] orientation:(UIImageOrientation)[assetRepresentation orientation]];
            CGImageRelease(imageRef);
        }
        
        if (sourceRef)
            CFRelease(sourceRef);
    }
    
    return result;
}

- (UIImage *)getFullScreenImageWithUrl:(NSURL *)url{
    __block UIImage *image;
    if([[[UIDevice currentDevice] systemVersion] floatValue]>8.0){
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        
        options.synchronous = YES;
        
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        PHFetchResult *phAsset = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
        
        [[PHImageManager defaultManager] requestImageForAsset:[phAsset firstObject] targetSize:CGSizeMake(1000, 1000) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            image = result;
            result = nil;
            info = nil;
        }];
        options = nil;
        phAsset = nil;
        return image;
    }else{
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
        
        dispatch_async(queue, ^{
            [library assetForURL:url resultBlock:^(ALAsset *asset) {
                
                image = [self  fullSizeImageForAssetRepresentation:asset.defaultRepresentation];
                //NSLog(@"获取图片");
                dispatch_semaphore_signal(sema);
            } failureBlock:^(NSError *error) {
                dispatch_semaphore_signal(sema);
            }];
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        return image;
    }
    
}

- (void)transitionfromPic{
    
    self.edittingSdk = [self createSdk];
    self.edittingSdk.editConfiguration.mediaCountLimit = 1;
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    [self.edittingSdk onRdVEAlbumWithSuperController:self albumType:kONLYALBUMIMAGE callBlock:^(NSMutableArray<NSURL *> * _Nonnull urls) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [self getFullScreenImageWithUrl:urls[0]];
            MainCropViewController *crop = [[MainCropViewController alloc] init];
            crop.image = image;
            crop.appkey = APPKEY;
            crop.appsecret = APPSECRET;
            UINavigationController *nav  = [[UINavigationController alloc] initWithRootViewController:crop];
            [self presentViewController:nav animated:YES completion:nil];
        });
        
    } cancelBlock:^{
        
    }];
}

#pragma mark- 录制
- (void)recordVideoWithType:(NSInteger)index{
    __weak ViewController *weakSelf = self;
    NSString * cameraOutputPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recordVideoFile.mp4"];
    
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVECameraSDKConfigData];
    _edittingSdk.editConfiguration.trimMode = TRIMMODEAUTOTIME;
    _edittingSdk.cameraConfiguration.cameraOutputPath = cameraOutputPath;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.enableDraft = true;
    _edittingSdk.editConfiguration.mediaCountLimit = 1;
    if(index == 0){
        //方式一(只录制等宽高的视频，这里设置界面方向不会生效)
//      _edittingSdk.cameraConfiguration.cameraOutputSize = CGSizeMake(1080, 1080);//设置输出视频大小
        _edittingSdk.cameraConfiguration.cameraRecordSizeType = RecordVideoTypeSquare;//设置输出视频是正方形还是长方形
        _edittingSdk.cameraConfiguration.cameraRecordOrientation = RecordVideoOrientationAuto;//设置界面方向（竖屏还是横屏）
    }
    
    else if(index == 1){
        //方式二
        _edittingSdk.cameraConfiguration.cameraOutputSize = CGSizeZero;//自动根据设备设置大小传入CGSizeZero
//        _edittingSdk.cameraConfiguration.cameraOutputSize = CGSizeMake(1080, 1920);//设置输出视频大小
        _edittingSdk.cameraConfiguration.cameraRecordSizeType        = RecordVideoTypeNotSquare;
        _edittingSdk.cameraConfiguration.cameraRecordOrientation     = RecordVideoOrientationAuto;
    }
    else if(index == 2){
        //方式三（自适应尺寸）
        _edittingSdk.cameraConfiguration.cameraOutputSize = CGSizeZero;//自动根据设备设置大小传入CGSizeZero
        _edittingSdk.cameraConfiguration.cameraRecordSizeType = RecordVideoTypeMixed;//设置输出视频是正方形还是长方形
        _edittingSdk.cameraConfiguration.cameraRecordOrientation = RecordVideoOrientationAuto;//设置界面方向（竖屏还是横屏）
    }
    
    //从相机进入相册
    _edittingSdk.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock = ^(RDVEUISDK *sdk){
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [sdk onRdVEAlbumWithSuperController:weakSelf albumType:kALBUMALL callBlock:^(NSMutableArray *list) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
                    __strong ViewController *strongSelf = weakSelf;
                    [strongSelf.edittingSdk editVideoWithSuperController:strongSelf
                                                              foldertype:kFolderDocuments
                                                       appAlbumCacheName:@""
                                                               urlsArray:list
                                                              outputPath:exportPath
                                                                callback:^(NSString * _Nonnull videoPath) {
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        __strong ViewController *strongSelf = weakSelf;
                                                                        strongSelf.edittingSdk = nil;
                                                                        [strongSelf enterPlayView:videoPath];
                                                                    });
                                                                } cancel:^{
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        strongSelf.edittingSdk = nil;
                                                                    });
                                                                }];
                });
            }cancelBlock:^{
                weakSelf.edittingSdk =nil;
                NSLog(@"取消");
            }];
        });
    };
    
    [_edittingSdk videoRecordAutoSizeWithSourceController:self callbackBlock:^(int result/*result : 0 表示MV 1表示视频*/,NSString *videoPath,RDMusicInfo *musicInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong ViewController *strongSelf = weakSelf;
            
            if(result == 1){
                if (videoPath.length > 0) {
                    [weakSelf editVideoWithPath:videoPath type:1 musicInfo:(RDMusicInfo *)musicInfo];
                }
            }else{
                strongSelf.shortVideoSdk = [strongSelf createShortSdk];
                strongSelf.shortVideoSdk.editConfiguration.enableDraft = true;
                //_shortVideoSdk.editConfiguration.enableMusic = _rdVEEditSDKConfigData.editConfiguration.enableMusic;
                //_shortVideoSdk.editConfiguration.enableFilter = _rdVEEditSDKConfigData.editConfiguration.enableFilter;
                
                strongSelf.edittingSdk = nil;
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
                
                NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];//NSHomeDirectory()
                
                [strongSelf.shortVideoSdk editVideoWithSuperController:strongSelf
                                                    urlAsset:asset
                                               clipTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                                        crop:CGRectMake(0, 0, 1, 1)
                                                   musicInfo:musicInfo
                                                  outputPath:outputPath
                                                    callback:^(NSString * _Nonnull videoPath) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            NSLog(@"编辑完成");
                                                            strongSelf.shortVideoSdk = nil;
                                                            [strongSelf enterPlayView:videoPath];
                                                        });
                                                    } cancel:^{
                                                        strongSelf.shortVideoSdk = nil;
                                                    }];
            }
        });
    } imagebackBlock:^(NSString * _Nonnull imagePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (imagePath.length > 0) {
                __strong ViewController *strongSelf = weakSelf;
                strongSelf.edittingSdk = nil;
                [strongSelf editVideoWithPath:imagePath type:2 musicInfo:nil];
            }
        });
        
    } faileBlock:^(NSError *error) {
        [weakSelf restoreCameraConfig];
    } cancel:^{
        [weakSelf restoreCameraConfig];
        //取消录制后在此做自己想做的事
    }];
}

#pragma mark- 抖音录制
- (void)douYinRecordWithType:(RDDouYinRecordType)type {
    NSString * exportPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recordVideoFile.mp4"];
    
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVECameraSDKConfigData];
    _edittingSdk.editConfiguration.trimMode = TRIMMODEAUTOTIME;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.enableDraft = true;
    _edittingSdk.editConfiguration.mediaMinCount = 1;
    _edittingSdk.cameraConfiguration.cameraOutputPath = exportPath;
    _edittingSdk.cameraConfiguration.cameraOutputSize = CGSizeZero;//自动根据设备设置大小传入CGSizeZero
    _edittingSdk.cameraConfiguration.cameraRecordSizeType = RecordVideoTypeNotSquare;
    _edittingSdk.cameraConfiguration.cameraRecordOrientation = RecordVideoOrientationPortrait;
    _edittingSdk.cameraConfiguration.cameraNotSquare_MaxVideoDuration = 10.0;
    _edittingSdk.cameraConfiguration.cameraMinVideoDuration = 2.0;
    __weak typeof(self) weakSelf = self;
    [_edittingSdk douYinRecordWithSourceController:self
                                        recordType:type
                                     callbackBlock:^(int result, NSString * _Nonnull path, RDMusicInfo * _Nonnull music) {
                                         if (path.length > 0) {
                                             [weakSelf editVideoWithPath:path type:1 musicInfo:music];
                                         }
                                     } imagebackBlock:^(NSString * _Nonnull imagePath) {
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             if (imagePath.length > 0) {
                                                 __strong typeof(self) strongSelf = weakSelf;
                                                 [strongSelf restoreCameraConfig];
                                                 [strongSelf editVideoWithPath:imagePath type:2 musicInfo:nil];
                                             }
                                         });
                                     } faileBlock:^(NSError * _Nonnull error) {
                                         NSLog(@"error:%@",error);
                                         [weakSelf restoreCameraConfig];
                                     } cancel:^{
                                         [weakSelf restoreCameraConfig];
                                     }];
}

- (void)restoreCameraConfig {
//    _rdVECameraSDKConfigData.cameraConfiguration.faceShape = _edittingSdk.cameraConfiguration.faceShape;
//    _rdVECameraSDKConfigData.cameraConfiguration.faceShapeLevel = _edittingSdk.cameraConfiguration.faceShapeLevel;
//    _rdVECameraSDKConfigData.cameraConfiguration.colorLevel = _edittingSdk.cameraConfiguration.colorLevel;
//    _rdVECameraSDKConfigData.cameraConfiguration.cheekThinning = _edittingSdk.cameraConfiguration.cheekThinning;
//    _rdVECameraSDKConfigData.cameraConfiguration.blurLevel = _edittingSdk.cameraConfiguration.blurLevel;
//    _rdVECameraSDKConfigData.cameraConfiguration.eyeEnlarging = _edittingSdk.cameraConfiguration.eyeEnlarging;
    
    _edittingSdk = nil;
}

#pragma mark - 进入多格 拼图
-(void)editDogePuzzle
{
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    
    __weak typeof(self) weakSelf = self;
    
    _edittingSdk.editConfiguration.mediaCountLimit = 9;
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableEffectsVideo = false;
    _edittingSdk.editConfiguration.enableFilter = true;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableSubtitle = true;
    ALBUMTYPE mediaType;
    if (_edittingSdk.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
        mediaType = kONLYALBUMIMAGE;
    }else if (_edittingSdk.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
        mediaType = kONLYALBUMVIDEO;
    }else {
        mediaType = kALBUMALL;
    }
    [_edittingSdk dogePuzzleOnRdVEAlbumWithSuperController:weakSelf albumType:mediaType callBlock:^(NSMutableArray *list) {
        //在这里做其他操作得在主线程中进行
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong ViewController *strongSelf = weakSelf;
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            [strongSelf.edittingSdk dogePuzzleWithSuperController:strongSelf
                                                                UrlsArray:list
                                                               outputPath:outputPath
                                                                 callback:^(NSString * _Nonnull videoPath) {
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         strongSelf.edittingSdk = nil;
                                                                         [strongSelf enterPlayView:videoPath];
                                                                     });
                                                                 } cancel:^{
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         strongSelf.edittingSdk = nil;
                                                                     });
                                                                 }];
        });
    }cancelBlock:^{
        NSLog(@"取消");
        weakSelf.edittingSdk = nil;
    }];
}

#pragma mark - 进入编辑
- (void)editVideoWithType:(NSInteger)index{
    
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    _edittingSdk.editConfiguration.enableDraft = true;
    
    NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    
    
    NSMutableArray *lists = [[NSMutableArray alloc] init];
    if (index ==0){
        //NSString *imagepath = [[NSBundle mainBundle] pathForResource:@"test0" ofType:@"JPG"];
        //[lists addObject:[NSURL fileURLWithPath:imagepath]];
        
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"testFile1" ofType:@"mov"];
        [lists addObject:[NSURL fileURLWithPath:videoPath]];
        
        __weak ViewController *weakSelf = self;        
        [_edittingSdk editVideoWithSuperController:self
                                        foldertype:kFolderDocuments
                                 appAlbumCacheName:@"jiyashipin"
                                         urlsArray:lists
                                        outputPath:exportPath
                                          callback:^(NSString * _Nonnull videoPath) {
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  __strong ViewController *strongSelf = weakSelf;
                                                  strongSelf.edittingSdk = nil;
                                                  [strongSelf enterPlayView:videoPath];
                                              });
                                          }cancel:^{
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  weakSelf.edittingSdk = nil;
                                              });
                                          }];
    }
    else if(index ==1){
        
        __weak ViewController *weakSelf = self;
        
        [_edittingSdk editVideoWithSuperController:self foldertype:kFolderDocuments appAlbumCacheName:@"MyAppVideo" urlsArray:lists outputPath:exportPath callback:^(NSString * _Nonnull videoPath) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong ViewController *strongSelf = weakSelf;
                strongSelf.edittingSdk = nil;
                [strongSelf enterPlayView:videoPath];
            });
        } cancel:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.edittingSdk = nil;
            });
        }];
    }
}

-(void)editVideoWithType_SpecialShaped:(NSInteger)index{
    
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    _edittingSdk.editConfiguration.mediaCountLimit = 2;
    
     __weak typeof(self) weakSelf = self;
    if (index == 0) {
    
        [_edittingSdk onRdVEAlbumWithSuperController:weakSelf albumType:kALBUMALL callBlock:^(NSMutableArray *list) {
            //在这里做其他操作得在主线程中进行
            dispatch_async(dispatch_get_main_queue(), ^{
                
                __strong ViewController *strongSelf = weakSelf;
                NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];

                [strongSelf.edittingSdk editVideoWithSuperController_SingleSceneMultimedia:strongSelf foldertype:kFolderNone appAlbumCacheName:@"异形-编辑" lists:list outputPath:outputPath callback:^(NSString * _Nonnull videoPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.edittingSdk = nil;
                        [strongSelf enterPlayView:videoPath];
                    });
                } cancel:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.edittingSdk = nil;
                    });
                }];
                
            });
        }cancelBlock:^{
            NSLog(@"取消");
            weakSelf.edittingSdk = nil;
        }];
        
    }
    
}

- (void)editVideoWithPath:(NSString *)path type:(int)type musicInfo:(RDMusicInfo *)musicInfo{
    if(path.length == 0){
        return;
    }
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    _edittingSdk.editConfiguration.enableDraft = true;

    NSMutableArray *lists = [[NSMutableArray alloc] init];
    [lists addObject:[NSURL fileURLWithPath:path]];
    
    __weak ViewController *weakSelf = self;
    //实例化RDVEUISDK对象
    NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    
    [_edittingSdk editVideoWithSuperController:self
                                    foldertype:kFolderDocuments
                             appAlbumCacheName:@"MyVideo"
                                     urlsArray:lists
                                     musicInfo:musicInfo
                                    outputPath:exportPath
                                      callback:^(NSString *videoPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong ViewController *strongSelf = weakSelf;
            strongSelf.edittingSdk = nil;
            UIInterfaceOrientation deviceOrientation = [UIApplication sharedApplication].statusBarOrientation;
            if(deviceOrientation == UIInterfaceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight){
                if(strongSelf.navigationController.visibleViewController == strongSelf){
                    NSLog(@"横向");
                    strongSelf.navigationController.navigationBarHidden = YES;
                    strongSelf.navigationController.navigationBar.translucent = YES;
                    [strongSelf.navigationController setNavigationBarHidden:YES];
                    [[UIApplication sharedApplication] setStatusBarHidden:YES];
                }
                strongSelf->_functionListTable.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
                
            }
            else if(deviceOrientation == UIInterfaceOrientationPortrait || deviceOrientation == UIInterfaceOrientationPortraitUpsideDown){
                if(strongSelf.navigationController.visibleViewController == strongSelf){
                    NSLog(@"纵向");
                    strongSelf.navigationController.navigationBarHidden=NO;
                    strongSelf.navigationController.navigationBar.translucent=NO;
                    [strongSelf.navigationController setNavigationBarHidden: NO];
                    [[UIApplication sharedApplication] setStatusBarHidden:NO];
                }
                strongSelf->_functionListTable.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
            }
            
            [strongSelf enterPlayView:videoPath];
        });
    } cancel:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.edittingSdk = nil;
        });
    }];
}

- (void)deallocEdittingSdk{
    _edittingSdk = nil;
}

#pragma mark - 草稿箱
- (void)editDraft {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    _edittingSdk.editConfiguration.enableDraft = true;
    NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    __weak typeof(self) weakSelf = self;
    [_edittingSdk editDraftWithSuperController:self
                                    outputPath:exportPath
                                      callback:^(NSString * _Nonnull videoPath) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              __strong ViewController *strongSelf = weakSelf;
                                              strongSelf.edittingSdk = nil;
                                              [strongSelf enterPlayView:videoPath];
                                          });
                                      }
                                      failback:^(NSError * _Nonnull error) {
                                          __strong ViewController *strongSelf = weakSelf;
                                         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                                             message:error.localizedDescription
                                                                                            delegate:strongSelf
                                                                                   cancelButtonTitle:nil
                                                                                   otherButtonTitles:nil, nil];
                                          [alertView show];
                                          [strongSelf performSelector:@selector(dimissAlert:) withObject:alertView afterDelay:2.0];
                                      }
                                        cancel:^{
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              weakSelf.edittingSdk = nil;
                                          });
                                      }];
}

/**移除弹框
  */
- (void)dimissAlert:(UIAlertView *)alert {
    if(alert){
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    }
}

#pragma mark - 照片电影
- (void)pictureMovie:(NSInteger)index {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    
    __weak typeof(self) weakSelf = self;
    
    _edittingSdk.editConfiguration.supportFileType = ONLYSUPPORT_IMAGE;
    _edittingSdk.editConfiguration.mediaCountLimit = 20;
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableEffectsVideo = false;
    _edittingSdk.editConfiguration.enableFilter = true;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableSubtitle = true;
    [_edittingSdk onRdVEAlbumWithSuperController:weakSelf albumType:kONLYALBUMIMAGE callBlock:^(NSMutableArray *list) {
        //在这里做其他操作得在主线程中进行
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong ViewController *strongSelf = weakSelf;
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            [strongSelf.edittingSdk pictureMovieWithSuperController_Theme:strongSelf
                                                       UrlsArray:list
                                                      outputPath:outputPath
                                                        callback:^(NSString * _Nonnull videoPath) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                strongSelf.edittingSdk = nil;
                                                                [strongSelf enterPlayView:videoPath];
                                                            });
                                                        } cancel:^{
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                strongSelf.edittingSdk = nil;
                                                            });
                                                        }];
        });
    }cancelBlock:^{
        NSLog(@"取消");
        weakSelf.edittingSdk = nil;
    }];
}

- (void)aeTemplateMovie:(BOOL)isMask {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.exportConfiguration.endPicDisabled  = true;
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    _edittingSdk.editConfiguration.supportFileType = SUPPORT_ALL;//ONLYSUPPORT_IMAGE;
    if (isMask) {
        _edittingSdk.editConfiguration.mediaCountLimit = 10;
    }else {
        _edittingSdk.editConfiguration.mediaCountLimit = 20;
    }
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableEffectsVideo = false;
    _edittingSdk.editConfiguration.enableFilter = true;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableTextTitle = false;
    
    __weak ViewController *weakSelf = self;
    [_edittingSdk onRdVEAlbumWithSuperController:weakSelf albumType:kALBUMALL callBlock:^(NSMutableArray *list) {
        //在这里做其他操作得在主线程中进行
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            [weakSelf.edittingSdk AETemplateMovieWithSuperController:weakSelf
                                                   UrlsArray:list
                                                  outputPath:outputPath
                                                      isMask:isMask
                                                    callback:^(NSString * _Nonnull videoPath) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            __strong ViewController *strongSelf = weakSelf;
                                                            strongSelf.edittingSdk = nil;
                                                            [strongSelf enterPlayView:videoPath];
                                                        });
                                                    } cancel:^{
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            weakSelf.edittingSdk = nil;
                                                        });
                                                    }];
        });
    }cancelBlock:^{
        NSLog(@"取消");
        weakSelf.edittingSdk = nil;
    }];
}

- (void)aeHomeVC {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.exportConfiguration.endPicDisabled  = true;
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    _edittingSdk.editConfiguration.supportFileType = SUPPORT_ALL;
    _edittingSdk.editConfiguration.mediaCountLimit = 10;
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableEffectsVideo = false;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableFilter = true;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableTextTitle = false;
    
    __weak ViewController *weakSelf = self;
    NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    [_edittingSdk AEHomeWithSuperController:self
                                 outputPath:outputPath
                                   callback:^(NSString * _Nonnull videoPath) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           __strong ViewController *strongSelf = weakSelf;
                                           strongSelf.edittingSdk = nil;
                                           [strongSelf enterPlayView:videoPath];
                                       });
                                   } cancel:^{
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           weakSelf.edittingSdk = nil;
                                       });
                                   }];
}

#pragma mark - 字说
- (void)enterTextAnimateVC {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.exportConfiguration.endPicDisabled  = true;
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    _edittingSdk.editConfiguration.supportFileType = SUPPORT_ALL;
    _edittingSdk.editConfiguration.mediaCountLimit = 10;
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableFilter = true;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableTextTitle = false;
    
    NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    __weak ViewController *weakSelf = self;
    [_edittingSdk aeTextAnimateWithSuperController:self
                                        outputPath:outputPath
                                          callback:^(NSString * _Nonnull videoPath) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  __strong ViewController *strongSelf = weakSelf;
                                                  strongSelf.edittingSdk = nil;
                                                  [strongSelf enterPlayView:videoPath];
                                              });
                                          } cancel:^{
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  weakSelf.edittingSdk = nil;
                                              });
                                          }];
}

#pragma mark - 文字视频
- (void)enterTextVideoVC {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.exportConfiguration.endPicDisabled  = true;
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.newmvResourceURL      = kNewmvResourceURL;
    _edittingSdk.editConfiguration.supportFileType = SUPPORT_ALL;
    _edittingSdk.editConfiguration.mediaCountLimit = 10;
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableFilter = true;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableTextTitle = false;
    
    NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    __weak ViewController *weakSelf = self;
    //字说 界面
    [_edittingSdk aeTextAnimateWithSuperViewController:self
                                            outputPath:outputPath
                                              callback:^(NSString * _Nonnull videoPath) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      __strong ViewController *strongSelf = weakSelf;
                                                      strongSelf.edittingSdk = nil;
                                                      [strongSelf enterPlayView:videoPath];
                                                  });
                                              } cancel:^{
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      weakSelf.edittingSdk = nil;
                                                  });
                                              }];
}

#pragma mark - 自绘
- (void)enterCustomDraw {
    _edittingSdk = [self createSdk];
    _edittingSdk.editConfiguration   = _rdVEEditSDKConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = _rdVEEditSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVEEditSDKConfigData.exportConfiguration;
    _edittingSdk.exportConfiguration.endPicDisabled  = true;
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    _edittingSdk.editConfiguration.enableAlbumCamera = false;
    _edittingSdk.editConfiguration.supportFileType = SUPPORT_ALL;
    _edittingSdk.editConfiguration.mediaCountLimit = 10;
    _edittingSdk.editConfiguration.enableMV = false;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableFilter = false;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEdit = false;
    _edittingSdk.editConfiguration.enableImageDurationControl = false;
    _edittingSdk.editConfiguration.enableCopy = false;
    _edittingSdk.editConfiguration.enableWizard = false;
    _edittingSdk.editConfiguration.enableTextTitle = false;
    
    NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    __weak ViewController *weakSelf = self;
    [_edittingSdk customDrawWithSuperController:self
                                     outputPath:outputPath
                                       callback:^(NSString * _Nonnull videoPath) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               __strong ViewController *strongSelf = weakSelf;
                                               strongSelf.edittingSdk = nil;
                                               [strongSelf enterPlayView:videoPath];
                                           });
                                       } cancel:^{
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               weakSelf.edittingSdk = nil;
                                           });
                                       }];
}

#pragma mark- 短视频编辑
- (void)shortVideoEdit{
    
    __weak ViewController *weakSelf = self;
    NSString * exportPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recordVideoFile.mp4"];
    
    _shortVideoSdk = [self createShortSdk];
    _shortVideoSdk.editConfiguration.enableAlbumCamera = false;
    //从相机进入相册
    _shortVideoSdk.cameraConfiguration.cameraEnterPhotoAlbumCallblackBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"1 mvResourceURL:%@",weakSelf.shortVideoSdk.editConfiguration.mvResourceURL);
            
            [weakSelf.shortVideoSdk onRdVEAlbumWithSuperController:weakSelf albumType:kONLYALBUMVIDEO callBlock:^(NSMutableArray *list) {
                AVURLAsset *asset = [AVURLAsset assetWithURL:[list firstObject]];
                NSDictionary *dic = [weakSelf.shortVideoSdk getVideoInformation:asset];
                float width = [[dic objectForKey:@"width"] floatValue];
                float height = [[dic objectForKey:@"height"] floatValue];
                
                if(width == height && CMTimeGetSeconds(asset.duration)<=weakSelf.shortVideoSdk.cameraConfiguration.cameraMV_MaxVideoDuration){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
                        [weakSelf.shortVideoSdk editVideoWithSuperController:weakSelf
                                                                    urlAsset:asset
                                                               clipTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                                                        crop:CGRectZero
                                                                  outputPath:outputPath
                                                                    callback:^(NSString * _Nonnull videoPath) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            NSLog(@"编辑完成");
                                                                            weakSelf.shortVideoSdk = nil;
                                                                            [weakSelf enterPlayView:videoPath];
                                                                        });
                                                                    } cancel:^{
                                                                        weakSelf.shortVideoSdk = nil;
                                                                    }];
                    });
                    return ;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.shortVideoSdk.rd_CutVideoReturnType = ^(RDCutVideoReturnType *cutType){
                        *cutType = RDCutVideoReturnTypeTime;
                        
                    };
                    NSLog(@"2 mvResourceURL:%@",weakSelf.shortVideoSdk.editConfiguration.mvResourceURL);
                    [weakSelf.shortVideoSdk trimVideoWithSuperController:weakSelf
                                                         controllerTitle:NSLocalizedString(@"修剪片段", nil)
                                                         backgroundColor:weakSelf.view.backgroundColor
                                                       cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                                  cancelButtonTitleColor:UIColorFromRGB(0xffffff)
                                             cancelButtonBackgroundColor:UIColorFromRGB(0x000000)
                                                        otherButtonTitle:NSLocalizedString(@"确定", nil)
                                                   otherButtonTitleColor:UIColorFromRGB(0xffffff)
                                              otherButtonBackgroundColor:UIColorFromRGB(0x00000)
                                                                urlAsset:asset
                                                              outputPath:exportPath
                                                           callbackBlock:^(RDCutVideoReturnType cutType, AVURLAsset * _Nonnull urlAsset, CMTime startTime, CMTime endTime,CGRect cropRect) {
                                                               if(cutType == RDCutVideoReturnTypeTime){
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
                                                                       NSLog(@"3 mvResourceURL:%@",weakSelf.shortVideoSdk.editConfiguration.mvResourceURL);
                                                                       
                                                                       [weakSelf.shortVideoSdk editVideoWithSuperController:weakSelf
                                                                                                                   urlAsset:urlAsset
                                                                                                              clipTimeRange:CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime)) crop:cropRect
                                                                                                                 outputPath:outputPath
                                                                                                                   callback:^(NSString * _Nonnull videoPath) {
                                                                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                           NSLog(@"编辑完成");
                                                                                                                           weakSelf.shortVideoSdk = nil;
                                                                                                                           [weakSelf enterPlayView:videoPath];
                                                                                                                       });
                                                                                                                   } cancel:^{
                                                                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                           weakSelf.shortVideoSdk = nil;
                                                                                                                       });
                                                                                                                   }];
                                                                       
                                                                   });
                                                               }else{
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
                                                                       [weakSelf.shortVideoSdk editVideoWithSuperController:weakSelf
                                                                                                                   urlAsset:urlAsset
                                                                                                              clipTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(endTime, startTime)) crop:CGRectZero
                                                                                                                 outputPath:outputPath
                                                                                                                   callback:^(NSString * _Nonnull videoPath) {
                                                                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                           NSLog(@"编辑完成");
                                                                                                                           weakSelf.shortVideoSdk = nil;
                                                                                                                           [weakSelf enterPlayView:videoPath];
                                                                                                                       });
                                                                                                                   } cancel:^{
                                                                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                           weakSelf.shortVideoSdk = nil;
                                                                                                                       });
                                                                                                                   }];
                                                                       
                                                                   });
                                                               }
                                                           } failback:^(NSError *error) {
                                                               NSLog(@"%@",error);
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   weakSelf.shortVideoSdk = nil;
                                                               });
                                                           } cancel:^{
                                                               NSLog(@"取消截取");
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   weakSelf.shortVideoSdk = nil;
                                                               });
                                                           }];
                });
            }cancelBlock:^{
                NSLog(@"取消");
            }];
        });
    };
    
    [_shortVideoSdk videoRecordAutoSizeWithSourceController:self callbackBlock:^(int result/*result : 0 表示MV 1表示视频*/,NSString *videoPath,RDMusicInfo *musicInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
            musicInfo.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            
            [weakSelf.shortVideoSdk editVideoWithSuperController:weakSelf
                                                        urlAsset:asset
                                                   clipTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                                            crop:CGRectMake(0, 0, 1, 1)
                                                       musicInfo:musicInfo
                                                      outputPath:outputPath
                                                        callback:^(NSString * _Nonnull videoPath) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                NSLog(@"编辑完成");
                                                                weakSelf.shortVideoSdk = nil;
                                                                [weakSelf enterPlayView:videoPath];
                                                            });
                                                        } cancel:^{
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                weakSelf.shortVideoSdk = nil;
                                                            });
                                                        }];
        });
    } imagebackBlock:^(NSString * _Nonnull imagePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.shortVideoSdk = nil;
        });
    } faileBlock:^(NSError *error) {
        NSLog(@"error:%@",error);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.shortVideoSdk = nil;
        });
    } cancel:^{
        //取消录制后在此做自己想做的事
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.shortVideoSdk = nil;
        });
    }];
    
}

#pragma mark- 截取
- (void)trimVideo {
    NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    
    _edittingSdk = [self createSdk];
    _edittingSdk.editConfiguration   = _rdVETrimSDKConfigData.editConfiguration;
    _edittingSdk.editConfiguration.trimMode   = _rdVETrimSDKConfigData.editConfiguration.trimMode;
    _edittingSdk.editConfiguration.trimExportVideoType   = _rdVETrimSDKConfigData.editConfiguration.trimExportVideoType;
    _edittingSdk.editConfiguration.trimDuration_OneSpecifyTime   = _rdVETrimSDKConfigData.editConfiguration.trimDuration_OneSpecifyTime;
    _edittingSdk.editConfiguration.trimMaxDuration_TwoSpecifyTime   = _rdVETrimSDKConfigData.editConfiguration.trimMaxDuration_TwoSpecifyTime;
    _edittingSdk.editConfiguration.trimMinDuration_TwoSpecifyTime   = _rdVETrimSDKConfigData.editConfiguration.trimMinDuration_TwoSpecifyTime;
    
    _edittingSdk.cameraConfiguration = _rdVETrimSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVETrimSDKConfigData.exportConfiguration;
    //定长截取设置
    _edittingSdk.editConfiguration.trimMinDuration_TwoSpecifyTime    = 12.0;
    _edittingSdk.editConfiguration.trimMaxDuration_TwoSpecifyTime    = 30.0;
    _edittingSdk.editConfiguration.defaultSelectMinOrMax             = kRDDefaultSelectCutMax;
    _edittingSdk.editConfiguration.mediaCountLimit = 1;
    __weak ViewController *weakSelf = self;
    _edittingSdk.rd_CutVideoReturnType = ^(RDCutVideoReturnType *cutType){
        __strong ViewController *strongSelf = weakSelf;
        *cutType = strongSelf->_cutVideoRetrunType;
        if (strongSelf->_cutVideoRetrunType == RDCutVideoReturnTypeAuto) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedString(@"请选择", nil)
                                                           delegate:strongSelf
                                                  cancelButtonTitle:NSLocalizedString(@"返回路径", nil)
                                                  otherButtonTitles:NSLocalizedString(@"返回时间", nil), nil];
            
            alert.tag = CUTVIDEOTYPALERTTAG;
            [alert show];
        }
    };
    _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
    
    [_edittingSdk onRdVEAlbumWithSuperController:weakSelf albumType:kONLYALBUMVIDEO callBlock:^(NSMutableArray *list) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_edittingSdk trimVideoWithSuperController:weakSelf
                                       controllerTitle:NSLocalizedString(@"修剪片段", nil)
                                       backgroundColor:self.view.backgroundColor
                                     cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                cancelButtonTitleColor:UIColorFromRGB(0xffffff)
                           cancelButtonBackgroundColor:UIColorFromRGB(0x000000)
                                      otherButtonTitle:NSLocalizedString(@"完成", nil)
                                 otherButtonTitleColor:UIColorFromRGB(0xffffff)
                            otherButtonBackgroundColor:UIColorFromRGB(0x00000)
                                                 urlAsset:[AVURLAsset assetWithURL:[list firstObject]]//[NSURL fileURLWithPath:[list firstObject]]
                                            outputPath:exportPath
                                         callbackBlock:^(RDCutVideoReturnType cutType, AVURLAsset * _Nonnull asset, CMTime startTime, CMTime endTime, CGRect cropRect) {
                                             
                                             __strong ViewController *strongSelf = weakSelf;
                                             if(cutType == RDCutVideoReturnTypePath){
                                                 NSLog(@"path:%@",asset.URL.path);
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     strongSelf.edittingSdk = nil;
                                                     [strongSelf enterPlayView:asset.URL.path];
                                                 });
                                                 
                                             }
                                             
                                             if(cutType == RDCutVideoReturnTypeTime){
                                                 NSLog(@"time:%lf,%lf",CMTimeGetSeconds(startTime),CMTimeGetSeconds(endTime));
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"截取时间范围", nil) message:[NSString stringWithFormat:NSLocalizedString(@"开始时间：%@\n结束时间：%@", nil),[weakSelf timeFormat:CMTimeGetSeconds(startTime)],[weakSelf timeFormat:CMTimeGetSeconds(endTime)]] delegate:strongSelf cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
                                                     [alertView show];
                                                     strongSelf.edittingSdk = nil;
                                                 });
                                             }
                                             
                                         } failback:^(NSError *error) {
                                             NSLog(@"%@",error);
                                             weakSelf.edittingSdk = nil;
                                         } cancel:^{
                                             NSLog(@"取消截取");
                                             weakSelf.edittingSdk = nil;
                                         }];
            
        });
    }cancelBlock:^{
        NSLog(@"取消");
    }];
    
}

#pragma mark- 从相册选择文件
- (void)onrdVEAlbumWithType:(NSInteger)index{
    
    _edittingSdk = [self createSdk];
    
    _edittingSdk.editConfiguration   = _rdVESelectAlbumSDKConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = _rdVESelectAlbumSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVESelectAlbumSDKConfigData.exportConfiguration;
    
    __weak ViewController *weakSelf = self;
    if (index < 3) {
        ALBUMTYPE type = (ALBUMTYPE)index;
        [_edittingSdk onRdVEAlbumWithSuperController:weakSelf albumType:type callBlock:^(NSMutableArray *list) {
            //对选择的视频/图片进行编辑
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            __strong ViewController *strongSelf = weakSelf;
            [strongSelf.edittingSdk editVideoWithSuperController:strongSelf foldertype:kFolderDocuments appAlbumCacheName:@"MyVideo" urlsArray:[list mutableCopy] outputPath:outputPath callback:^(NSString * _Nonnull videoPath) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.edittingSdk = nil;
                    [strongSelf enterPlayView:videoPath];
                });
            } cancel:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.edittingSdk = nil;
                });
            }];
        }cancelBlock:^{
            NSLog(@"取消");
        }];
    }else if (index == 3) {
        _edittingSdk.editConfiguration.clickAlbumCameraBlackBlock = nil;
        _edittingSdk.editConfiguration.mediaCountLimit = 1;
        
        [_edittingSdk onRdVEAlbumWithSuperController:weakSelf albumType:kONLYALBUMVIDEO callBlock:^(NSMutableArray *list) {
            dispatch_async(dispatch_get_main_queue(), ^{
                 __strong ViewController *strongSelf = weakSelf;
//                    AVURLAsset *asset = [AVURLAsset assetWithURL:[list firstObject]];
                NSString * outputFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportAudioFile"];
                [_edittingSdk video2audiowithtype:self atAVFileType:AVFileTypeMPEGLayer3 videoUrl:[list firstObject] outputFolderPath:outputFolderPath samplerate:16000 callback:^(NSString * _Nonnull videoPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.edittingSdk = nil;
                        [strongSelf enterPlayView:videoPath];
                    });
                } cancel:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.edittingSdk = nil;
                    });
                }];
//                    [RDVEUISDK video2audiowithtype:AVFileTypeMPEGLayer3//AVFileTypeAppleM4A//AVFileTypeWAVE//
//                                          videoUrl:asset.URL
//                                         trimStart:0
//                                          duration:0
//                                  outputFolderPath:outputFolderPath
//                                        samplerate:16000
//                                        completion:^(BOOL result,NSString * _Nonnull outputFilePath) {
//
//                                              if(result){
//                                                  NSLog(@"导出音频完成");
//                                              }else{
//                                                  NSLog(@"导出音频失败");
//                                              }
//
//                                          }];
            });
        }cancelBlock:^{
            NSLog(@"取消");
        }];
    }
}

#pragma mark - 小功能
- (void)smallFunctionWithType:(NSInteger)type {
    _edittingSdk = [self createSdk];
    [self refreshConfigWithConfigData:_rdVEEditSDKConfigData];
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    _edittingSdk.editConfiguration.enableDraft = true;
    _edittingSdk.editConfiguration.enableWizard = false;
    
    RDSingleFunctionType funcType = (RDSingleFunctionType)type;
    ALBUMTYPE mediaType;
    if (funcType == RDSingleFunctionType_Transition) {
        if (_edittingSdk.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
            mediaType = kONLYALBUMIMAGE;
        }else if (_edittingSdk.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
            mediaType = kONLYALBUMVIDEO;
        }else {
            mediaType = kALBUMALL;
        }
        _edittingSdk.editConfiguration.mediaMinCount = 2;
    }else if (funcType == RDSingleFunctionType_ClipEditing) {
        mediaType = kALBUMALL;
        _edittingSdk.editConfiguration.enableWizard = true;
    } else {
        mediaType = kONLYALBUMVIDEO;
        _edittingSdk.editConfiguration.mediaCountLimit = 1;
    }
    NSString * exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    __weak ViewController *weakSelf = self;
    [_edittingSdk onRdVEAlbumWithSuperController:self
                                       albumType:mediaType
                                       callBlock:^(NSMutableArray<NSURL *> * _Nonnull urls) {
                                           [_edittingSdk singleMediaWithSuperController:weakSelf
                                                                           functionType:funcType
                                                                             outputPath:exportPath
                                                                               urlArray:urls
                                                                               callback:^(NSString * _Nonnull videoPath) {
                                                                                   __strong ViewController *strongSelf = weakSelf;
                                                                                   strongSelf.edittingSdk = nil;
                                                                                   [strongSelf enterPlayView:videoPath];
                                                                               } cancel:^{
                                                                                   weakSelf.edittingSdk = nil;
                                                                               }];
                                       } cancelBlock:^{
                                           weakSelf.edittingSdk = nil;
                                       }];
}

#pragma mark- 音效处理
- (void) audioFilter{
    _edittingSdk = [self createSdk];
    
    _edittingSdk.editConfiguration   = _rdVEEditSDKConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = _rdVEEditSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVEEditSDKConfigData.exportConfiguration;
    _edittingSdk.editConfiguration.mediaCountLimit = 2;
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    
    __weak typeof(self) weakSelf = self;
    [_edittingSdk onRdVEAlbumWithSuperController:self albumType:kONLYALBUMVIDEO callBlock:^(NSMutableArray *list) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
             NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            __strong ViewController *strongSelf = weakSelf;
            [strongSelf.edittingSdk audioFilterWithSuperController:strongSelf
                                               UrlsArray:list
                                               musicPath:@""
                                              outputPath:outputPath
                                                callback:^(NSString * _Nonnull videoPath) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        strongSelf.edittingSdk = nil;
                                                        [strongSelf enterPlayView:videoPath];
                                                    });
                                                } cancel:^{
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        strongSelf.edittingSdk = nil;
                                                    });
                                                }];
            
        });
        
        
    }cancelBlock:^{
        NSLog(@"取消");
    }];
}

#pragma mark- 压缩

- (void)compressVideo{
    _compressOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
    _edittingSdk = [self createSdk];
    
    _edittingSdk.editConfiguration   = _rdVEEditSDKConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = _rdVEEditSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVEEditSDKConfigData.exportConfiguration;
    _edittingSdk.editConfiguration.mediaCountLimit = 1;
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    
    __weak typeof(self) myself = self;
    [_edittingSdk onRdVEAlbumWithSuperController:self albumType:kONLYALBUMVIDEO callBlock:^(NSMutableArray *list) {
        __strong ViewController *strongSelf = myself;
        AVURLAsset *asset = [AVURLAsset assetWithURL:[list firstObject]];
        strongSelf->_compressAsset = asset;
        [strongSelf initCompressView:asset exportPath:strongSelf->_compressOutputPath];
    }cancelBlock:^{
        NSLog(@"取消");
    }];
}

#pragma mark - 媒体视频特效
- (void)assetAddMVEffect {
    _edittingSdk = [self createSdk];
    
    _edittingSdk.editConfiguration   = _rdVEEditSDKConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = _rdVEEditSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVEEditSDKConfigData.exportConfiguration;
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    _edittingSdk.editConfiguration.mediaCountLimit = 1;
    _edittingSdk.editConfiguration.enableMVEffect = true;
    _edittingSdk.editConfiguration.enableMV = true;
    _edittingSdk.editConfiguration.enableEffectsVideo = false;
    _edittingSdk.editConfiguration.enableFragmentedit = false;
    _edittingSdk.editConfiguration.enableSubtitle = false;
    _edittingSdk.editConfiguration.enableSticker = false;
    _edittingSdk.editConfiguration.enableEffect = false;
    _edittingSdk.editConfiguration.enableFilter = false;
    _edittingSdk.editConfiguration.enableDewatermark = false;
    _edittingSdk.editConfiguration.enableCollage = false;
    _edittingSdk.editConfiguration.enableDoodle = false;
    _edittingSdk.editConfiguration.enableMusic = false;
    _edittingSdk.editConfiguration.enableDubbing = false;
    _edittingSdk.editConfiguration.enableSoundEffect = false;
    _edittingSdk.editConfiguration.enableProportion = false;
    _edittingSdk.editConfiguration.enableMosaic = false;
    _edittingSdk.editConfiguration.enableWatermark = false;
    _edittingSdk.editConfiguration.enablePicZoom = false;
    _edittingSdk.editConfiguration.enableBackgroundEdit = false;
    _edittingSdk.editConfiguration.enableCover = false;
    _edittingSdk.editConfiguration.enableSort = false;
    __weak typeof(self) weakSelf = self;
    [_edittingSdk onRdVEAlbumWithSuperController:self albumType:kALBUMALL callBlock:^(NSMutableArray *list) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            __strong ViewController *strongSelf = weakSelf;
            [strongSelf.edittingSdk editVideoWithSuperController:strongSelf
                                            foldertype:kFolderNone
                                     appAlbumCacheName:@""
                                             urlsArray:list
                                            outputPath:outputPath
                                              callback:^(NSString * _Nonnull videoPath) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      strongSelf.edittingSdk = nil;
                                                      [strongSelf enterPlayView:videoPath];
                                                  });
                                              } cancel:^{
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      strongSelf.edittingSdk = nil;
                                                  });
                                              }];
        });
    }cancelBlock:^{
        NSLog(@"取消");
    }];
}

#pragma mark - 不规则媒体
- (void)shapedAsset {
    _edittingSdk = [self createSdk];
    
    _edittingSdk.editConfiguration   = _rdVEEditSDKConfigData.editConfiguration;
    _edittingSdk.cameraConfiguration = _rdVEEditSDKConfigData.cameraConfiguration;
    _edittingSdk.exportConfiguration = _rdVEEditSDKConfigData.exportConfiguration;
    _edittingSdk.editConfiguration.mediaCountLimit = 1;
    _edittingSdk.editConfiguration.enableAlbumCamera = _rdVESelectAlbumSDKConfigData.editConfiguration.enableAlbumCamera;
    
    __weak typeof(self) weakSelf = self;
    [_edittingSdk onRdVEAlbumWithSuperController:self albumType:kALBUMALL callBlock:^(NSMutableArray *list) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString * outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportVideoFile.mp4"];
            __strong ViewController *strongSelf = weakSelf;
            [strongSelf.edittingSdk shapedAssetWithSuperController:strongSelf
                                                assetUrl:[list firstObject]
                                              outputPath:outputPath
                                                callback:^(NSString * _Nonnull videoPath) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        strongSelf.edittingSdk = nil;
                                                        [strongSelf enterPlayView:videoPath];
                                                    });
                                                } cancel:^{
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        strongSelf.edittingSdk = nil;
                                                    });
                                                }];
            
        });
    }cancelBlock:^{
        NSLog(@"取消");
    }];
}

#pragma mark- mtsToMp4

- (void)mtstomp4{
    
}

#pragma mark-
- (void)enterPlayView:(NSString *)path{
    PlayVideoController *playVC = [[PlayVideoController alloc] init];
    if(!(path.length>0)){
        path = [[NSBundle mainBundle] pathForResource:@"testFile1" ofType:@"mov"];
    }
    
    playVC.videoPath = path;
    [self.navigationController pushViewController:playVC animated:NO];
}

- (BOOL)isNumText:(NSString *)str{
    NSString * regex        = @"^\\d*$";
    NSPredicate * pred      = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isMatch            = [pred evaluateWithObject:str];
    if (isMatch) {
        return YES;
    }else{
        return NO;
    }
}

#pragma mark- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField.text.length>0){
        if([self isNumText:textField.text]){
            [textField resignFirstResponder];
            return YES;
        }else {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                               message:NSLocalizedString(@"请输入数字", nil)
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                                     otherButtonTitles:nil, nil];
            [alertView show];
            return NO;
        }
    }
    [textField resignFirstResponder];
    return YES;
}

#pragma mark 创建相册
-(void)createRDVEUISDKAlbum{
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    NSMutableArray *groups=[[NSMutableArray alloc]init];
    
    __weak ViewController *weakSelf = self;
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         
         if (group)
         {
             [groups addObject:group];
         }
         else
         {
             BOOL haveHDRGroup = NO;
             
             for (ALAssetsGroup *gp in groups)
             {
                 NSString *name =[gp valueForProperty:ALAssetsGroupPropertyName];
                 
                 if ([name isEqualToString:PHOTO_ALBUM_NAME])
                 {
                     haveHDRGroup = YES;
                 }
             }
             //创建相簿
             if (!haveHDRGroup)
             {
                 [ weakSelf createAlbum];
             }
         }
     }
                               failureBlock:nil];
}

-(void)createAlbum{
    
    // PHPhotoLibrary_class will only be non-nil on iOS 8.x.x
    Class PHPhotoLibrary_class = NSClassFromString(@"PHPhotoLibrary");
    
    if (PHPhotoLibrary_class) {
        
        // iOS 8..x. . code that has to be called dynamically at runtime and will not link on iOS 7.x.x ...
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:PHOTO_ALBUM_NAME];
        } completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error creating album: %@", error);
            }else{
                NSLog(@"Created");
            }
        }];
    }else{
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary addAssetsGroupAlbumWithName:PHOTO_ALBUM_NAME resultBlock:^(ALAssetsGroup *group) {
            NSLog(@"adding album:'Compressed Videos', success: %s", group.editable ? "YES" : "NO");
            
        } failureBlock:^(NSError *error) {
            NSLog(@"error adding album");
        }];
    }
}
#pragma mark- 将时间转换成字符串格式
- (NSString *) timeFormat: (float) seconds {
    if(seconds<=0){
        seconds = 0;
    }
    int hours = seconds / 3600;
    int minutes = seconds / 60;
    int sec = fabs(round((int)seconds % 60));
    if (hours>=1) {
        return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, sec];
    }else{
        return [NSString stringWithFormat:@"%02i:%02i",minutes, sec];
    }
}

#pragma mark - faceU
/**设置美颜参数*/
- (void)setFaceUBeautyParams:(RDFaceUBeautyParams *)beautyParams {
    [FaceUManager shareManager].blurLevel = beautyParams.blurLevel;
    [FaceUManager shareManager].faceShapeLevel = beautyParams.faceShapeLevel;
    [FaceUManager shareManager].faceShape = beautyParams.faceShape;
    [FaceUManager shareManager].colorLevel = beautyParams.colorLevel;
    [FaceUManager shareManager].cheekThinning = beautyParams.cheekThinning;
    [FaceUManager shareManager].eyeEnlarging = beautyParams.eyeEnlarging;
}

#pragma mark- RDVEUISDK delegate
- (void)saveDraftResult:(NSError *)error {
    NSString *message;
    if (error) {
        message = error.localizedDescription;
    }else {
        message = NSLocalizedString(@"保存草稿成功，可在草稿箱中查看。", nil);
    }
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:nil
                                             otherButtonTitles:nil, nil];
    [alertView show];
    [self performSelector:@selector(dimissAlert:) withObject:alertView afterDelay:2.0];
    _edittingSdk = nil;
}

//摄像头捕获帧回调，可对帧进行处理
#pragma mark - FaceU
- (void)willOutputCameraSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    //在此处，可对帧进行处理
    if (_rdVECameraSDKConfigData.cameraConfiguration.enableFaceU) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        [[FaceUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
    }
}

- (void)faceUItemChanged:(NSString *)itemPath {
    [[FaceUManager shareManager] loadItem:itemPath];
}

- (void)faceUBeautyParamChanged:(RDFaceUBeautyParams *)beautyParams {
    [self setFaceUBeautyParams:beautyParams];
}

- (void)destroyFaceU {
    [[FaceUManager shareManager] destoryItems];
}

#if 0
- (void)selectVideoAndImageResult:(UINavigationController *)nav callbackBlock:(void (^)(NSMutableArray * _Nonnull))callbackBlock {
    _addFileType = addVideoAndImages;
    _edittingSdk.addVideosAndImagesCallbackBlock = callbackBlock;
    if([self checkCameraISOpen]){
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        
        sourceType                      = UIImagePickerControllerSourceTypePhotoLibrary;//相册库
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate                 = self;
        picker.allowsEditing            = NO;
        picker.sourceType               = sourceType;
        picker.mediaTypes               = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage];
        [nav presentViewController:picker animated:YES completion:nil];
    }
}

- (void)selectVideosResult:(UINavigationController *)nav callbackBlock:(void (^)(NSMutableArray * _Nonnull))callbackBlock {
    _addFileType = addVideo;
    
#if 0
    if([self checkCameraISOpen]){
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        sourceType                      = UIImagePickerControllerSourceTypePhotoLibrary;//相册库
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate                 = self;
        picker.allowsEditing            = NO;
        picker.sourceType               = sourceType;
        picker.mediaTypes               = @[(NSString *)kUTTypeMovie];
        [nav presentViewController:picker animated:YES completion:nil];
    }
    _edittingSdk.addVideosCallbackBlock = callbackBlock;
    
#else
    NSMutableArray *lists = [[NSMutableArray alloc] init];
    
    NSURL *fileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"testFile1" ofType:@"mov"]];
    [lists addObject:fileUrl];
    callbackBlock(lists);//添加视频后回调
    
#endif
}

- (void)selectImagesResult:(UINavigationController *)nav callbackBlock:(void (^)(NSMutableArray * _Nonnull))callbackBlock {
    _addFileType = addImage;
    _edittingSdk.addImagesCallbackBlock = callbackBlock;
    if([self checkCameraISOpen]){
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        sourceType                      = UIImagePickerControllerSourceTypePhotoLibrary;//相册库
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate                 = self;
        picker.allowsEditing            = NO;
        picker.sourceType               = sourceType;
        picker.mediaTypes               = @[(NSString *)kUTTypeImage];
        [nav presentViewController:picker animated:YES completion:nil];
    }
}

- (BOOL)checkCameraISOpen{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        
        NSString * errorMessage = NSLocalizedString(@"用户拒绝访问相机,请在<隐私>中开启", nil);
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"无法访问相机!", nil)
                                                           message:errorMessage
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                                 otherButtonTitles:NSLocalizedString(@"取消", nil), nil];
        alertView.tag = 2000;
        [alertView show];
        return NO;
    }
    
    return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSMutableArray *lists = [[NSMutableArray alloc] init];
    NSURL *fileUrl = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
    [lists addObject:fileUrl];
    
    if(_addFileType == addVideo){
        //Add video
        _edittingSdk.addVideosCallbackBlock(lists);//selectVideosResult callback
    }else if(_addFileType == addImage){
        //Add picture
        _edittingSdk.addImagesCallbackBlock(lists);//selectImageResult callback
    }else{
        //Add video and picture
        _edittingSdk.addVideosAndImagesCallbackBlock(lists);//selectVideoAndImageResult callback
    }    
}

#endif

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
