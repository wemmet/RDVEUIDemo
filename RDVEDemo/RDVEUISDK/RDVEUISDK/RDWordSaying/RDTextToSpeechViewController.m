//
//  RDTextToSpeechViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTextToSpeechViewController.h"
#import "RDSoundWaveProgress.h"
#import "RDRecordTypeView.h"
//#import "decibelLine.h"
#import "RDRecordingTime.h"
#import <MediaPlayer/MediaPlayer.h>
#import "RDWordSayViewController.h"
#import "InscriptionLibView.h"

#import "RDSVProgressHUD.h"

//相册
#import "RDMainViewController.h"

@interface RDTextToSpeechViewController ()<RDSoundWaveProgressDelegate,RDRecordTypeViewDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate,RDInscriptionLibViewDelegate,UITextViewDelegate>
{
    RDSoundWaveProgress * soundWaveProgress;
    UIButton            * cancelBtn;                //关闭
    UIButton            * publishButton;            //下一步
    
    UILabel             * currentTimeLabel;         //当前音频时间
    
    UIView              *inscriptionView;           //题词区域
    UIScrollView        *inscriptionScrollView;     //题词区域显示
    
    bool                isDisplay;                  //是否显示
    
    UIView              *operatingView;             //操作区域
    
    UIButton            *recordBtn;                 //录音按钮
    UIButton            *inscriptionBtn;            //题词库按钮
    UIButton            *albumBtn;                  //相册按钮
    
    UIButton            *deleteFIleBtn;             //删除音频文件按钮
    UIButton            *nextStepBtn;               //下一步按钮
    
    NSInteger           currentTypeIndex;           //当前选中模式
    
    AVAudioRecorder     *audioRecorder;
    
    NSMutableArray<recordingSegment *> *decibelArray;       //记录音频分贝数
    
    float               lowLevelNumber;
    float               lowBitNumber;
    float               moderateNumber;
    float               middleAndUpperNumber;
    float               HighBitNumber;
    NSMutableArray<NSString *> *audioPathArray;         //
    NSMutableArray<RDFile*>    *_fileList;
    int                 currentAudioNumber;
    
    AVAudioSession      *audioSession;
    
    RDRecordingTime     *recordingTime;
    
    float               audioStartTime;
    float               currentAudioTime;
    int               currentAudioFileNumber;
    
    float               currentSoundTime;
    
    
    UIView              *textView;
    UITextView         *customizeTextField;
    bool                isCustomize;            //是否自定义题词
    
    NSTimer             *countdownTimer;        //  倒计时
    int                 countdowSec;           //倒计时时间
    
    NSMutableArray<RDAudioPathTimeRange*> *audioPathTimeRangeArray;
    
    NSMutableArray<NSString*> *insStrArrry;
    
    bool                isText;
    
    BOOL                isVideoFile;            //是否是相册视频
}
@property(nonatomic,strong)UIView               * titleView;

@property(nonatomic,strong)UIView               * recordingView;            //录音转文字界面

@property(nonatomic,strong)RDRecordTypeView     * recordTypeView;           //功能选择界面

@property(nonatomic,strong)CADisplayLink        *displayLink;

@property (nonatomic,strong) NSTimer *timer;

@property(nonatomic       )UIAlertView      *commonAlertView;

//音频
@property(nonatomic,strong)AVAudioPlayer         *audioPlayer;
@property(nonatomic,strong)UIButton         *playerBtn;                     //播放音频

//题词库
@property(nonatomic,strong)InscriptionLibView         *inscriptionLibView;

@property(nonatomic,strong)UIView              *customizeView;

//语音识别
//@property(nonatomic,strong)NSMutableArray                       *requestIdArray;
@property(nonatomic,strong)NSMutableArray<NSString *>           *textAndTimeArray;

@property(nonatomic,strong)UILabel                  *countdownLabel;


@property(nonatomic,strong)UIView               * textView;                 //文字转语音界面
@property(nonatomic,strong)UITextView           *avTextView;

@property(nonatomic,strong)UIButton             *auditionBtn;
@end

@implementation RDTextToSpeechViewController
- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification{
    NSLog(@"内存占用过高");
}
- (void)applicationEnterHome:(NSNotification *)notification{
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
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
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    isText = true;
    isDisplay = false;
    isVideoFile = false;
    [self.view addSubview:self.titleView];
    [self.view addSubview:self.textView];
    [self.view addSubview:self.recordingView];
    [self.view addSubview:self.recordTypeView];
    currentTypeIndex = 1;
    currentAudioNumber = 0;
    decibelArray = [NSMutableArray<recordingSegment*> new];
    audioPathArray = [NSMutableArray<NSString *> new];
    
    soundWaveProgress.decibelArray = decibelArray;
    
    lowLevelNumber = [self decibelPercentage:-45];
    lowBitNumber =  [self decibelPercentage:-25];
    moderateNumber = [self decibelPercentage:-10];
    middleAndUpperNumber = [self decibelPercentage:-4];
    HighBitNumber = 1.0;
    
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Do any additional setup after loading the view.
}
//RDSoundWaveProgressDelegate
-(void)CurrentTime:(float) soundTime
{
    currentSoundTime = soundTime;
    int minu = ((int)soundTime)/60;
    int sec = ((int)soundTime)%60;
    int secRational =  (int)((soundTime - sec - minu*60 )*100);
    NSString *text = @"00:00";
    
    if( sec < 10 )
    {
        text = [NSString stringWithFormat:@"0%d:0%d:",minu,sec];
    }
    else{
        text = [NSString stringWithFormat:@"0%d:%d:",minu,sec];
    }
    if( secRational < 10 )
    {
        text = [NSString stringWithFormat:@"%@0%d",text,secRational];
    }
    else{
        text = [NSString stringWithFormat:@"%@%d",text,secRational];
    }
    currentTimeLabel.text = text;
}
#pragma mark- 语音转文字  界面
-(UIView *)recordingView
{
    if( !_recordingView )
    {
        _recordingView = [[UIView alloc] initWithFrame:CGRectMake(0,_titleView.frame.size.height+_titleView.frame.origin.y, kWIDTH, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (_titleView.frame.size.height+_titleView.frame.origin.y))];
        
        currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 50)];
        currentTimeLabel.text = @"00:00";
        currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        currentTimeLabel.textColor = TEXT_COLOR;
        currentTimeLabel.font = [UIFont systemFontOfSize:40];
        [_recordingView addSubview:currentTimeLabel];
        
        soundWaveProgress = [[RDSoundWaveProgress alloc] initWithFrame:CGRectMake( 0, currentTimeLabel.frame.size.height + currentTimeLabel.frame.origin.y, self.view.frame.size.height, 50*2 + 40)];
        soundWaveProgress.delegate = self;
        [_recordingView addSubview:soundWaveProgress];
        
        inscriptionView = [[UIView alloc] initWithFrame:CGRectMake(0, soundWaveProgress.frame.size.height + soundWaveProgress.frame.origin.y + 5, kWIDTH, _recordingView.frame.size.height - soundWaveProgress.frame.size.height - soundWaveProgress.frame.origin.y - 5 - 90)];
        [_recordingView addSubview:inscriptionView];
        
        operatingView = [[UIView alloc] initWithFrame:CGRectMake(0, inscriptionView.frame.size.height + inscriptionView.frame.origin.y + 5, kWIDTH, 90)];
        [_recordingView addSubview:operatingView];
        
        //录音
        recordBtn = [[UIButton alloc] initWithFrame:CGRectMake((kWIDTH-80)/2.0, 5, 80, 80)];
        [recordBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_录音_默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [recordBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_录音_选中_@3x" Type:@"png"]] forState:UIControlStateSelected];
        [recordBtn addTarget:self action:@selector(record_Btn) forControlEvents:UIControlEventTouchUpInside];
        [operatingView addSubview:recordBtn];
        
        //题词库
        inscriptionBtn = [[UIButton alloc] initWithFrame:CGRectMake((kWIDTH-80)/2.0 - 80 - 20 , 5, 80, 80)];
        UIImageView * inscriptionImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];
        inscriptionImage.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_题词库_默认_@3x" Type:@"png"]];
        [inscriptionBtn addSubview:inscriptionImage];
        UILabel * inscriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 80, 20)];
        inscriptionLabel.text = RDLocalizedString(@"题词库", nil);
        inscriptionLabel.textAlignment = NSTextAlignmentCenter;
        inscriptionLabel.textColor = [UIColor whiteColor];
        inscriptionLabel.font = [UIFont systemFontOfSize:10];
        [inscriptionBtn addTarget:self action:@selector(inscription_btn) forControlEvents:UIControlEventTouchUpInside];
        [inscriptionBtn addSubview:inscriptionLabel];
        [operatingView addSubview:inscriptionBtn];
        
        albumBtn = [[UIButton alloc] initWithFrame:CGRectMake((kWIDTH-80)/2.0 + 80 + 20 , 5, 80, 80)];
        UIImageView * albumBtnImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];
        albumBtnImage.image =  [RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册默认_@3x"];
        [albumBtn addSubview:albumBtnImage];
        UILabel * albumBtnLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 80, 20)];
        albumBtnLabel.text = RDLocalizedString(@"相册视频", nil);
        albumBtnLabel.textAlignment = NSTextAlignmentCenter;
        albumBtnLabel.textColor = [UIColor whiteColor];
        albumBtnLabel.font = [UIFont systemFontOfSize:10];
        [albumBtn addTarget:self action:@selector(album_Btn) forControlEvents:UIControlEventTouchUpInside];
        [albumBtn addSubview:albumBtnLabel];
        [operatingView addSubview:albumBtn];
    }
    return _recordingView;
}

#pragma mark- 相册视频
-(void)album_Btn
{
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.videoCountLimit = 1;
    mainVC.minCountLimit = 1;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist) {
        
        _fileList = [NSMutableArray<RDFile*> new];
        [_fileList addObjectsFromArray:filelist];
        
        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"正在识别中，请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __block int count = 0;
            [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.fileType == kFILEVIDEO && !obj.isReverse) {
                    [RDVECore video2audiowithtype:AVFileTypeAppleM4A
                                         videoUrl:obj.contentURL
                                        trimStart:CMTimeGetSeconds(obj.videoTrimTimeRange.start)
                                         duration:CMTimeGetSeconds(obj.videoTrimTimeRange.duration)
                                 outputFolderPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"speechRecog"]
                                       samplerate:8000
                                       completion:^(BOOL result, NSString *outputFilePath) {
                        count++;
                        isVideoFile = true;
                        if( audioPathArray == nil )
                            audioPathArray = [NSMutableArray new];
                        [audioPathArray addObject:outputFilePath];
                        if( _fileList.count == count )
                        {
                            [self textToSpeech];
                        }
                    }];
                }
            }];
        });
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.editConfiguration.supportFileType = ONLYSUPPORT_VIDEO;
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}



-(void)inscription_btn
{
    if( isDisplay )
    {
        [self creatActionSheet];
    }
    else
        self.inscriptionLibView.hidden = NO;
}

#pragma mark- 标题界面
- (UIView *)titleView{
    if(!_titleView){
        _titleView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, 44)];

        recordingTime = [[RDRecordingTime alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 5)];
        recordingTime.backgroundColor = TOOLBAR_COLOR;
        [_titleView addSubview:recordingTime];
        recordingTime.hidden = YES;
        
        cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.exclusiveTouch = YES;
        cancelBtn.backgroundColor = [UIColor clearColor];
        cancelBtn.frame = CGRectMake(iPhone4s?0:5, (_titleView.frame.size.height - 44), 44, 44);
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        [_titleView addSubview:cancelBtn];
        publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        publishButton.exclusiveTouch = YES;
        publishButton.backgroundColor = [UIColor clearColor];
        publishButton.frame = CGRectMake(kWIDTH - 64, (_titleView.frame.size.height - 44), 64, 44);
        publishButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [publishButton setTitleColor:TEXT_COLOR forState:UIControlStateNormal];
        [publishButton setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
        [publishButton addTarget:self action:@selector(tapPublishBtn) forControlEvents:UIControlEventTouchUpInside];
        publishButton.hidden = YES;
        [_titleView addSubview:publishButton];
    }
    return _titleView;
}
//关闭
-(void)back:(UIButton *) btn
{
    UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
    if(!upView){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
-(void)tapPublishBtn
{
//    NSString * str = _avTextView.text;
//
//    if( str.length == 0 )
//        return;
//
//    NSString *timeText = [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
//    timeText = [timeText stringByReplacingOccurrencesOfString:@"。" withString:@"\n"];
//    timeText = [timeText stringByReplacingOccurrencesOfString:@"，" withString:@"\n"];
//    timeText = [timeText stringByReplacingOccurrencesOfString:@"？" withString:@"\n"];
//    timeText = [timeText stringByReplacingOccurrencesOfString:@"！" withString:@"\n"];
//    timeText = [timeText stringByReplacingOccurrencesOfString:@"；" withString:@"\n"];
    
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"正在识别中，请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    
    __block NSMutableArray<NSString*> *strArrry  =  [NSMutableArray new];
    
    [insStrArrry enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        int count = obj.length/7 + (((obj.length%7)>0)?1:0);
        int RemainCount = obj.length%7;
        for (int i = 0; i < count; i++) {
            if( (i == (count -1)) && (RemainCount != 0) )
                [strArrry addObject:[obj substringWithRange:NSMakeRange(7*i,RemainCount)]];
            else
                [strArrry addObject:[obj substringWithRange:NSMakeRange(7*i,7)]];
        }
    }];
    

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [RDSVProgressHUD dismiss];
        dispatch_async(dispatch_get_main_queue(), ^{
            RDWordSayViewController *textAnimateVC = [[RDWordSayViewController alloc] init];
            textAnimateVC.strArrry = strArrry;
            textAnimateVC.cancelBlock = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    _cancelBlock();
                });
            };
            
            [self.navigationController pushViewController:textAnimateVC animated:YES];
        });
    });
}

#pragma mark- 功能界面
-(RDRecordTypeView*)recordTypeView
{
    if( !_recordTypeView )
    {
        NSArray *itemArray = [NSArray arrayWithObjects:
                              RDLocalizedString(@"", nil),
                              RDLocalizedString(@"60秒", nil),
                              nil];
        _recordTypeView = [[RDRecordTypeView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 44 - (iPhone_X ? 34 : 0), kWIDTH, 44)];
        _recordTypeView.delegate = self;
        [_recordTypeView setItemTitleArray:itemArray selectedIndex:1];
        [_recordTypeView RecordTypeScrollView].scrollEnabled = NO;
    }
    return _recordTypeView;
}
//RDRecordTypeViewDelegate
- (void)selectedTypeIndex:(NSInteger)typeIndex
{
    if( currentTypeIndex == typeIndex )
        return;
    
//    switch (typeIndex) {
//        case 0:
//        {
//            _recordingView.hidden = YES;
//            _textView.hidden = NO;
//            publishButton.hidden = NO;
//            currentTypeIndex = typeIndex;
//        }
//            break;
//        case 1:
//        {
//            _recordingView.hidden = NO;
//            _textView.hidden = YES;
//            publishButton.hidden = YES;
//            currentTypeIndex = typeIndex;
//        }
//            break;
//        default:
//            break;
//    }
}

-(void)startAuido
{
    self.playerBtn.hidden = YES;

    if( _playerBtn.isSelected )
    {
        [self player_Btn];
    }

    _playerBtn.enabled = NO;

    nextStepBtn.hidden = YES;
    deleteFIleBtn.hidden = YES;
    _recordTypeView.hidden = YES;
    recordBtn.selected = YES;
    inscriptionBtn.hidden = YES;
    albumBtn.hidden = YES;
    recordBtn.enabled = YES;
    [self _initVoice];
    
    // 设备开启录音模式
    [audioSession setActive:YES error:nil];
    //创建录音文件，准备录音
    BOOL prepareSuccess = [audioRecorder prepareToRecord];
    [_displayLink setPaused:false];
    [audioRecorder record];
    
    recordingTime.hidden = NO;
    
    //                        deleteFIleBtn.hidden = NO;
    inscriptionBtn.hidden = YES;
    //                        nextStepBtn.hidden = NO;
    albumBtn.hidden = YES;

}
-(void)countdown
{
    
    if( countdowSec == 0 )
    {
        [countdownTimer invalidate];
        countdownTimer = nil;
        _countdownLabel.hidden = YES;
        [self startAuido];
    }
    else
    {
        _countdownLabel.text = [NSString stringWithFormat:@"%d",countdowSec];
        countdowSec--;
    }
}
#pragma mark-
-(void)record_Btn
{
    if( (_countdownLabel != nil) && (_countdownLabel.hidden == NO) )
        return;
    
    if( recordBtn.isSelected )
    {
        [audioRecorder stop];
        audioRecorder = nil;
        
        [_displayLink setPaused:true];
        [audioSession setActive:NO error:nil];
        recordBtn.selected = NO;
        inscriptionBtn.hidden = NO;
        albumBtn.hidden = NO;
        _recordTypeView.hidden = NO;
        _playerBtn.enabled = YES;
        if( currentAudioNumber > 0 )
        {
            [recordBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_录音_继续_默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
            _recordTypeView.hidden = YES;
            if( !deleteFIleBtn )
            {
                deleteFIleBtn = [[UIButton alloc] initWithFrame:CGRectMake((kWIDTH-80)/2.0 - 80 - 20 , 5, 80, 80)];
                UIImageView * deleteFIleImage = [[UIImageView alloc] initWithFrame:CGRectMake(25, 30, 30, 20)];
                deleteFIleImage.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_删除_默认_@3x" Type:@"png"]];
                [deleteFIleBtn addSubview:deleteFIleImage];
                UILabel * deleteFIleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 80, 20)];
                deleteFIleLabel.text = RDLocalizedString(@"删除", nil);
                deleteFIleLabel.textAlignment = NSTextAlignmentCenter;
                deleteFIleLabel.textColor = [UIColor whiteColor];
                deleteFIleLabel.font = [UIFont systemFontOfSize:10];
                [deleteFIleBtn addTarget:self action:@selector(deleteFile) forControlEvents:UIControlEventTouchUpInside];
                [deleteFIleBtn addSubview:deleteFIleLabel];
                [operatingView addSubview:deleteFIleBtn];
            }
            deleteFIleBtn.hidden = NO;
            inscriptionBtn.hidden = YES;
            
            if( !nextStepBtn )
            {
                nextStepBtn = [[UIButton alloc] initWithFrame:CGRectMake((kWIDTH-80)/2.0 + 80 + 20 , 5, 80, 80)];
                UIImageView * nextStepBtnImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];
                nextStepBtnImage.image =  [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_下一步_@3x" Type:@"png"]];
                [nextStepBtn addSubview:nextStepBtnImage];
                UILabel * nextStepBtnLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 80, 20)];
                nextStepBtnLabel.text = RDLocalizedString(@"下一步", nil);
                nextStepBtnLabel.textAlignment = NSTextAlignmentCenter;
                nextStepBtnLabel.textColor = [UIColor whiteColor];
                nextStepBtnLabel.font = [UIFont systemFontOfSize:10];
                [nextStepBtn addSubview:nextStepBtnLabel];
                [nextStepBtn addTarget:self action:@selector(textToSpeech) forControlEvents:UIControlEventTouchUpInside];
                [operatingView addSubview:nextStepBtn];
            }
            nextStepBtn.hidden = NO;
            albumBtn.hidden = YES;
            
            cancelBtn.hidden = YES;
            
            [recordingTime refreshTime:soundWaveProgress.currentAudioDecibelNumber*(1.0/maxInterval) atIsNode:YES];
            
            decibelArray[decibelArray.count-1].endValue = soundWaveProgress.currentAudioDecibelNumber;
            self.playerBtn.hidden = NO;
            
//            audioPathArray[audioPathArray.count-1]  = [RDVECore conventToMp3:audioPathArray[audioPathArray.count-1] spread:@"pcm"];
        }
    }
    else
    {
        AVAudioSession *avSession = [AVAudioSession sharedInstance];
        if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
            __weak typeof(self) weakSelf = self;
            [avSession requestRecordPermission:^(BOOL available) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (available) {
                        
                        if( MAxDecibelNumber <= soundWaveProgress.currentAudioDecibelNumber )
                        {
                            [self initCommonAlertViewWithTitle:RDLocalizedString(@"提示",nil)
                                                       message:RDLocalizedString(@"录音时长已超过60秒",nil)
                                             cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                             otherButtonTitles:nil
                                                  alertViewTag:1];
                            return;
                        }
                        if( audioPathArray.count == 0 )
                        {
                            
                            
                            self.playerBtn.hidden = YES;
                            
                            if( _playerBtn.isSelected )
                            {
                                [self player_Btn];
                            }
                            
                            _playerBtn.enabled = NO;
                            
                            nextStepBtn.hidden = YES;
                            deleteFIleBtn.hidden = YES;
                            _recordTypeView.hidden = YES;
                            recordBtn.selected = YES;
                            inscriptionBtn.hidden = YES;
                            albumBtn.hidden = YES;
                            
                            countdowSec = 3;
                            self.countdownLabel.hidden = NO;
                            _countdownLabel.text = @"";
                            countdownTimer = nil;
                            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdown) userInfo:nil repeats:YES];
                        }
                        else
                            [self startAuido];
                    }
                    else
                    {
                        [self record_Btn];
                        [self initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问麦克风!",nil)
                                                         message:RDLocalizedString(@"请在“设置-隐私-麦克风”中开启",nil)
                                               cancelButtonTitle:RDLocalizedString(@"确认",nil)
                                               otherButtonTitles:RDLocalizedString(@"取消",nil)
                                                    alertViewTag:102];
                    }
                });
            }];
        }
    }
}
//音频录制
- (NSDictionary *)audioParamSetting {
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC ] forKey:AVFormatIDKey];
    //设置录音采样率(Hz)
    [recordSetting setValue:[NSNumber numberWithFloat: 22050] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    return recordSetting;
}
- (void)_initVoice {
    // 初始化录音参数
    
    NSDictionary *recordSetting = [self audioParamSetting];
    
    NSString *strUrl = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    strUrl = [NSString stringWithFormat:@"%@/Video%d.aac", strUrl,currentAudioNumber];
    unlink( [strUrl UTF8String] );
    [audioPathArray addObject:strUrl];
    
    recordingSegment * segment = [[recordingSegment alloc] init];
    segment.decibelArray = [NSMutableArray<NSNumber *> new];
    
    
    
    if( decibelArray.count )
        soundWaveProgress.currentAudioDecibelNumber = decibelArray[decibelArray.count-1].endValue;
    
    segment.startValue = soundWaveProgress.currentAudioDecibelNumber;
    segment.endValue = 0;
    
    [decibelArray addObject:segment];
    
    currentAudioNumber++;
    
    NSURL *url = [NSURL fileURLWithPath:strUrl];
    NSError *error;
    //初始化
    audioRecorder = [[AVAudioRecorder alloc]initWithURL:url settings:recordSetting error:&error];
    
    //开启音量检测
    audioRecorder.meteringEnabled = YES;
    audioRecorder.delegate = self;
//    NSLog(@"准备录音: %d", prepareSuccess);
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshEvent)];
    
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.preferredFramesPerSecond= 60/maxNumber;
    [_displayLink setPaused:true];
}

-(float)decibelPercentage:(float) decibels;
{
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   root            = 2.0f;
    float   minAmp          = powf(10.0f, 0.05f * minDecibels);
    float   inverseAmpRange = 1.0f / (1.0f - minAmp);
    float   amp             = powf(10.0f, 0.05f * decibels);
    float   adjAmp          = (amp - minAmp) * inverseAmpRange;
    
    return powf(adjAmp, 1.0f / root);
}

-(void)refreshEvent
{
    
    if( _playerBtn.hidden == NO )
    {
        [self updateAudioProgress];
    }
    else
    {
        
        
        [audioRecorder updateMeters];           //刷新音量数据
        
        float   level;                // The linear 0.0 .. 1.0 value we need.
        float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
        float   decibels    = [audioRecorder averagePowerForChannel:0];
        
        if( (MAxDecibelNumber-1) <= soundWaveProgress.currentAudioDecibelNumber )
        {

        }
        
        if (decibels < minDecibels)
        {
            level = 0.0f;
        }
        else if (decibels >= 0.0f)
        {
            level = 1.0f;
        }
        else
        {
            level = [self decibelPercentage:decibels];
        }
//        NSLog(@"power = %f，level =%f\n",decibels,level);
//
//        level = ( level - 0.1 )/0.9;
//
//        if( level <= 0.15 )
//        {
//            level = 0.0;
//        }
//        else if( (level > 0.15) && (level <=0.45)  )
//        {
//            level = (level-0.15)/(0.3) * 0.3;
//        }
//        else if( (level > 0.45) && (level <=0.70)  )
//        {
//            level = (level-0.45)/(0.7 - 0.45) * 0.2 + 0.3;
//        }
//        else if( (level > 0.7) && (level <= 1.0)  )
//        {
//            level = (level-0.7)/(1.0 - 0.7) * 0.5 + 0.5;
//        }
        
        [decibelArray[decibelArray.count-1].decibelArray addObject:[NSNumber numberWithFloat:level]];
        soundWaveProgress.currentAudioDecibelNumber++;
        [soundWaveProgress refreshProgress];
        
        [recordingTime refreshTime:soundWaveProgress.currentAudioDecibelNumber*(1.0/maxInterval) atIsNode:NO];
        
        if( MAxDecibelNumber <= soundWaveProgress.currentAudioDecibelNumber )
            [self record_Btn];
    }
}

-(void)AlldeleteFile
{
    _playerBtn.hidden = YES;
    recordingTime.hidden = YES;
    _recordTypeView.hidden = NO;
    deleteFIleBtn.hidden = YES;
    inscriptionBtn.hidden = NO;
    nextStepBtn.hidden = YES;
    albumBtn.hidden = NO;
    cancelBtn.hidden = NO;
    [recordBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_录音_默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
}
-(void)deleteFile
{
    [self initCommonAlertViewWithTitle:nil
                               message:RDLocalizedString(@"是否删除选中的音频",nil)
                     cancelButtonTitle:RDLocalizedString(@"是",nil)
                     otherButtonTitles:RDLocalizedString(@"否",nil)
                          alertViewTag:103];
}

//提示
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
        case 102: //开启麦克风
            if (buttonIndex == 0) {
                [RDHelpClass enterSystemSetting];
            }
            break;
        case 103: //删除选中音频
        {
            if (buttonIndex == 0) {
                [self deleteAudio:soundWaveProgress.currentAudioFileNumber];
            }
        }
            break;
        default:
            break;
    }
}

-(void)deleteAudio:(int) number
{
    if( (audioPathArray.count-1) < number  )
        return;
    
    if( (decibelArray.count-1) < number )
        return;
    
    unlink( [audioPathArray[number] UTF8String] );
    [decibelArray[number].decibelArray removeAllObjects];
    [decibelArray removeObjectAtIndex:number];
    [audioPathArray removeObjectAtIndex:number];
    
    if( number > 0 )
        soundWaveProgress.currentAudioDecibelNumber = decibelArray[number-1].endValue;
    else
        soundWaveProgress.currentAudioDecibelNumber = 0;
    
    [self CurrentTime:soundWaveProgress.currentAudioDecibelNumber/maxInterval];
    
    if( decibelArray.count > 0 )
    {
        if( number <=  (decibelArray.count - 1) )
        {
            
            if( number > 0 )
                decibelArray[number].startValue = decibelArray[number-1].endValue;
            else
                decibelArray[number].startValue = 1;
            
            
            decibelArray[number].endValue = decibelArray[number].startValue + decibelArray[number].decibelArray.count;
            
            [decibelArray enumerateObjectsUsingBlock:^(recordingSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if( number < idx )
                {
                    obj.startValue = decibelArray[idx-1].endValue;
                    obj.endValue = obj.startValue + obj.decibelArray.count;
                }
            }];
        }
    }
    
    if( decibelArray.count > 0 )
    {
        [soundWaveProgress deleteRefresh];
        [recordingTime deleteRefreshTime:decibelArray[decibelArray.count-1].endValue*(1.0/maxInterval) atdecibelArray:decibelArray];
    }
    
    if( decibelArray.count == 0 )
    {
        [recordingTime clearTime];
        [soundWaveProgress clearTime];
        [self CurrentTime:0];
        [self AlldeleteFile];
    }
}

#pragma mark- 播放音频
-(UIButton *)playerBtn
{
    if( !_playerBtn )
    {
        _playerBtn = [[UIButton alloc] initWithFrame:CGRectMake((kWIDTH-44)/2.0, currentTimeLabel.frame.size.height + currentTimeLabel.frame.origin.y + 23 + (soundWaveProgress.frame.size.height - 23 -44)/2.0, 44, 44)];
        [_playerBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_播放_默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playerBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_暂停_选中_@3x" Type:@"png"]] forState:UIControlStateSelected];
        [_playerBtn addTarget:self action:@selector(player_Btn) forControlEvents:UIControlEventTouchUpInside];
        _playerBtn.hidden = YES;
        [_recordingView addSubview:_playerBtn];
    }
    return _playerBtn;
}
-(void)player_Btn
{
    if( _playerBtn.isSelected )
    {
        _playerBtn.selected = NO;
        [_audioPlayer stop];
        _audioPlayer = nil;
        [_displayLink setPaused:true];
    }
    else
    {
        currentAudioFileNumber = soundWaveProgress.currentAudioFileNumber;
        _playerBtn.selected =YES;
        [self playMusic:audioPathArray[currentAudioFileNumber]];
        [_audioPlayer play];
        [_audioPlayer setCurrentTime:currentSoundTime];
        [_displayLink setPaused:false];
    }
}

-(void)playMusic:(NSString *) path
{
    if( !_audioPlayer )
    {
        NSError *playerError;
        @try {
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&playerError];
            NSLog(@"%@",[playerError description]);
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            if(_audioPlayer){
                _audioPlayer.delegate = self;
            }
        }
    }
}
//暂停
-(void)audioPlayerPause
{
    [_audioPlayer pause];
}
//停止
-(void)audioPlayerStop
{
    if( _playerBtn.isSelected )
      [self player_Btn];
//    [_audioPlayer stop];
//    _audioPlayer = nil;
//    [_displayLink setPaused:true];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self audioPlayerStop];
    if( currentAudioFileNumber < (audioPathArray.count-1) )
    {
        currentAudioFileNumber++;
        _playerBtn.selected =YES;
        [self playMusic:audioPathArray[currentAudioFileNumber]];
        [_audioPlayer play];
        [_displayLink setPaused:false];
    }
}
/*
 更新播放器进度
 */
- (void)updateAudioProgress{
    double time = [_audioPlayer currentTime];
    int startValue = decibelArray[currentAudioFileNumber].startValue;
    int curretnValue = startValue  + (time*maxInterval);
    [soundWaveProgress playProgress:curretnValue];
}

#pragma mark- 题词库
-(InscriptionLibView*)inscriptionLibView
{
    if(!_inscriptionLibView )
    {
        _inscriptionLibView = [[InscriptionLibView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, kHEIGHT-(iPhone_X ? 44 : 0))];
        
        _inscriptionLibView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _inscriptionLibView.InscriptionLibDelegate = self;
        [self.view addSubview:_inscriptionLibView];
        _inscriptionLibView.hidden = YES;
    }
    return _inscriptionLibView;
}

-(void)CreateInscriptionScrollView:(NSArray *) str
{
    [inscriptionScrollView removeFromSuperview];
    inscriptionScrollView = nil;
    inscriptionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, inscriptionView.frame.size.width, inscriptionView.frame.size.height)];
    [inscriptionView addSubview:inscriptionScrollView];
    
    for ( int i = 0 ; i < str.count; i++) {
        [self CreaTextteLabel:i str:str[i]];
    }
    inscriptionScrollView.contentSize = CGSizeMake(0, 40*str.count + inscriptionScrollView.frame.size.height - 40 );
}

-(UILabel *)CreaTextteLabel:(int) index str:(NSString *) str
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, index*40, inscriptionScrollView.frame.size.width, 40)];
//    label.textColor = UIColorFromRGB(0x838383);
    label.text = str;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:18];
    
//    if( index == 0 )
        label.textColor = UIColorFromRGB(0xffffff);
    
    [inscriptionScrollView addSubview:label];
    
    return label;
}

#pragma mark- RDInscriptionLibViewDelegate
-(void)select:(NSArray *)str atIsCustomize:(bool)isCustomize
{
    if( insStrArrry != nil )
    {
        [insStrArrry removeAllObjects];
        insStrArrry = nil;
    }
    
    insStrArrry = [NSMutableArray new];
    [insStrArrry addObjectsFromArray:str];
    
    if( !isCustomize )
    {
        isDisplay = true;
        [self CreateInscriptionScrollView:str];
        publishButton.hidden  = NO;
    }
    else
    {
        
    }
}
-(void)CustomInscription
{
    self.customizeView.hidden = NO;
    [customizeTextField becomeFirstResponder];
}
//选择题词操作
-(void)creatActionSheet {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:RDLocalizedString(RDLocalizedString(@"题词", nil), nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:RDLocalizedString(@"更换题词", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _inscriptionLibView.hidden = NO;
        isDisplay = false;
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle: RDLocalizedString(@"自定义题词", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        isDisplay = false;
        self.customizeView.hidden = NO;
        [customizeTextField becomeFirstResponder];
    }];
    
    UIAlertAction *action4 = [UIAlertAction actionWithTitle: RDLocalizedString(@"清除题词", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        isDisplay = false;
        [inscriptionScrollView removeFromSuperview];
        inscriptionScrollView = nil;
        if( insStrArrry != nil )
        {
            [insStrArrry removeAllObjects];
            insStrArrry = nil;
        }
        publishButton.hidden  = YES;
    }];
    
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:RDLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:action1];
    [actionSheet addAction:action2];
    [actionSheet addAction:action4];
    [actionSheet addAction:action3];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark- 自定义题词
-(UIView*)customizeView
{
    if( !_customizeView )
    {
        _customizeView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, kHEIGHT-(iPhone_X ? 44 : 0))];
        _customizeView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        
        textView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 200, kWIDTH, 200)];
        textView.backgroundColor = UIColorFromRGB(0x333333);
        
        customizeTextField = [[UITextView alloc] initWithFrame:CGRectMake(10, 15, kWIDTH-20, 130)];
        customizeTextField.backgroundColor = TOOLBAR_COLOR;
        customizeTextField.layer.masksToBounds = YES;
        customizeTextField.layer.cornerRadius = 5;
        customizeTextField.layer.borderColor = [UIColor whiteColor].CGColor;
        customizeTextField.layer.borderWidth = 1.0;
        customizeTextField.textColor = [UIColor whiteColor];
        customizeTextField.font = [UIFont systemFontOfSize:18];
        [textView addSubview:customizeTextField];
        
        UIButton *confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(customizeTextField.frame.size.width + customizeTextField.frame.origin.x - 50, customizeTextField.frame.size.height + customizeTextField.frame.origin.y + 10, 50, 30)];
        confirmBtn.backgroundColor = Main_Color;
        confirmBtn.layer.cornerRadius = 5;
        confirmBtn.layer.masksToBounds = YES;
        [confirmBtn setTitle:RDLocalizedString(@"确定", nil) forState:UIControlStateNormal];
        [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        confirmBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [confirmBtn addTarget:self action:@selector(confirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        
        [textView addSubview:confirmBtn];
        
        [_customizeView addSubview:textView];
        
        _customizeView.hidden = YES;
        [self.view addSubview:_customizeView];
    }
    customizeTextField.text = @"";
    return _customizeView;
}

-(void)confirm_Btn
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    NSString * str = customizeTextField.text;
    if( str.length > 0 )
    {
        NSString *timeText = [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
        NSArray<NSString*> *contentArray = [timeText componentsSeparatedByString:@"\n"];
        __block NSMutableArray<NSString*> *strArrry  =  [NSMutableArray new];
        
        [contentArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            int count = obj.length/12 + (((obj.length%12)>0)?1:0);
            
            int RemainCount = obj.length%12;
            for (int i = 0; i < count; i++) {
                if( (i == (count -1)) && (RemainCount != 0) )
                    [strArrry addObject:[obj substringWithRange:NSMakeRange(12*i,RemainCount)]];
                else
                    [strArrry addObject:[obj substringWithRange:NSMakeRange(12*i,12)]];
            }
        }];
        
        [self select: strArrry  atIsCustomize:false];
    }
}
#pragma makr- keybordShow&Hidde
- (void)keyboardWillShow:(NSNotification *)notification{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    if( (_customizeView != nil) && (_customizeView.hidden == false) )
    {
        CGRect bottomViewFrame = _customizeView.frame;
        bottomViewFrame.origin.y = _customizeView.frame.origin.x - keyboardSize.height;
        _customizeView.frame = bottomViewFrame;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification{
    if( (_customizeView != nil) && (_customizeView.hidden == false) )
    {
        CGRect bottomViewFrame = _customizeView.frame;
        bottomViewFrame.origin.y = (iPhone_X ? 44 : 0);
        _customizeView.frame = bottomViewFrame;
        _customizeView.hidden = YES;
    }
}

//文字转语音
-(void)textToSpeech
{
    if( (audioPathArray.count > 0) && isText )
    {
        isText = false;
        [RDSVProgressHUD dismiss];
        
        [RDSVProgressHUD showWithStatus:RDLocalizedString(@"正在识别中，请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
        
        EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int code = 0;
            NSMutableArray<NSDictionary*> *DictionaryArray = [NSMutableArray new];
            for (int i = 0; i < audioPathArray.count; i++) {
                NSDictionary *resultCallBack = [RDHelpClass uploadAudioWithPath:audioPathArray[i] appId:editConfig.tencentAIRecogConfig.appId secretId:editConfig.tencentAIRecogConfig.secretId secretKey:editConfig.tencentAIRecogConfig.secretKey serverCallbackPath:editConfig.tencentAIRecogConfig.serverCallbackPath];
                [DictionaryArray addObject:resultCallBack];
                
                bool isOut = true;
                code = [[resultCallBack objectForKey:@"code"] intValue];
                for ( ; isOut ; ) {
                    if (resultCallBack && [[resultCallBack objectForKey:@"code"] intValue] == 0) {
                        NSString *requestId = [resultCallBack objectForKey:@"requestId"];
                        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", [NSNumber numberWithInteger:i], @"fileIndex", nil];
                        //                    [self.requestIdArray addObject:dic];
                        isOut = [self getSpeechRecogCallBackWithDic:dic];
                    }
                    if (isOut) {
                        if( isVideoFile )
                            [audioPathArray removeObjectAtIndex:i];
                        else
                        {
                            dispatch_async(dispatch_get_main_queue(),^{
                                [self deleteAudio:i];
                            });
                        }
                        if (i == 0) {
                            break;
                        }else {
                            i--;
                            isOut = true;
                        }
                    }
                }
            }
            isText = true;
            isVideoFile = false;
            if(!_textAndTimeArray || _textAndTimeArray.count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [RDSVProgressHUD dismiss];
                    if( code == 1016 )
                    {
                        [self initCommonAlertViewWithTitle:nil
                                  message:RDLocalizedString(@"语音识别失败（超出当月试用次数）！",nil)
                        cancelButtonTitle:RDLocalizedString(@"确定",nil)
                        otherButtonTitles:nil
                             alertViewTag:-1];
                    }
                    else
                    {
                        [self initCommonAlertViewWithTitle:nil
                                  message:RDLocalizedString(@"AI识别失败！",nil)
                        cancelButtonTitle:RDLocalizedString(@"确定",nil)
                        otherButtonTitles:nil
                             alertViewTag:-1];
                    }
                });
                NSLog(@"识别失败！");
                return ;
            }
            
            NSMutableArray<NSString*> *strArray  =  [NSMutableArray array];
            NSMutableArray<RDStrTimeRange *> *strTimeRangeArray  =  [NSMutableArray array];
            dispatch_async(dispatch_get_main_queue(), ^{
                float firstStartTime = 0.0;
                float startDuration = 0.0;
                for (int j = 0; j< _textAndTimeArray.count; j++) {
                    NSArray *contentArray = [_textAndTimeArray[j] componentsSeparatedByString:@"\n"];
                    BOOL isStereo = NO;
                    if( j > 0 )
                    {
                        AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioPathArray[j-1]] error:nil];
                        startDuration += player.duration;
                    }
                    for (int i = 0; i < contentArray.count; i++) {
                        NSLog(@"i:%d", i);
                        NSString *obj = contentArray[i];
                        if ([obj hasPrefix:@"["]) {
                            obj = [obj substringToIndex:obj.length - 1];
                            NSRange range = [obj rangeOfString:@","];
                            if (range.location != NSNotFound) {
                                NSString *startTimeStr = [obj substringWithRange:NSMakeRange(1, range.location - 1)];
                                float startTime = [RDHelpClass timeFromStr:startTimeStr];
                                if ( i == 0 ) {
                                    firstStartTime = startTime;
                                }
                                
                                RDStrTimeRange * strTimeRange = [RDStrTimeRange new];
                                strTimeRange.startTime = CMTimeMake( (startDuration + startTime) * 30, 30);
                                
                                obj = [obj substringFromIndex:range.location + 1];
                                range = [obj rangeOfString:@"]"];
                                if (range.location != NSNotFound) {
                                    NSString *endTimeStr = [obj substringToIndex:range.location];
                                    if (!isStereo && [endTimeStr containsString:@","]) {
                                        isStereo = YES;
                                    }
                                    float endTime = [RDHelpClass timeFromStr:endTimeStr];
                                    
                                    strTimeRange.showTime = CMTimeMake((endTime+startDuration)* 30, 30);
                                    
                                    [self typeset:[obj substringFromIndex:range.location + 1] atTimeRange:strTimeRange strArrry:strArray strTimeRangeArray:strTimeRangeArray];
                                    
//                                    startDuration += endTime;
                                    if (isStereo) {
                                        i++;
                                    }
                                }
                            }
                        }
                    }
                }
                
                [RDSVProgressHUD dismiss];
                if (strArray.count == 0) {
                    [self initCommonAlertViewWithTitle:nil
                              message:RDLocalizedString(@"AI识别失败！",nil)
                    cancelButtonTitle:RDLocalizedString(@"确定",nil)
                    otherButtonTitles:nil
                         alertViewTag:-1];
                    return ;
                }
                RDWordSayViewController *textAnimateVC = [[RDWordSayViewController alloc] init];
                textAnimateVC.strArrry = strArray;
                textAnimateVC.strTimeRangeArray = strTimeRangeArray;
                
                double currentDuration = 0;
                audioPathTimeRangeArray = [NSMutableArray new];
                for (int i = 0; i < audioPathArray.count; i++) {
                    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioPathArray[i]] error:nil];
                    double duration = player.duration;
                    
                    RDAudioPathTimeRange * audioPathTimeRange = [RDAudioPathTimeRange new];
                    
                    audioPathTimeRange.audioPath = audioPathArray[i];
                    audioPathTimeRange.timeRang = CMTimeRangeMake(CMTimeMake(currentDuration, 1.0), CMTimeMake(duration, 1.0));
                    
                    [audioPathTimeRangeArray addObject:audioPathTimeRange];
                    
                    currentDuration += duration;
                }
                textAnimateVC.audioPathArray = audioPathTimeRangeArray;
                
                textAnimateVC.cancelBlock = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _cancelBlock();
                    });
                };
                [self.navigationController pushViewController:textAnimateVC animated:YES];
            });
        });
    }
}

//语音转文字
- (BOOL)getSpeechRecogCallBackWithDic:(NSDictionary *)dic {
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSDictionary *resultCallBack = [RDHelpClass updateInfomation:[NSMutableDictionary dictionaryWithObject:dic[@"requestId"] forKey:@"requestId"] andUploadUrl:@"http://d.56show.com/filemanage2/public/filemanage/voice2text/findText"];
    if (resultCallBack) {
        //            dispatch_async(dispatch_get_main_queue(), ^{
        if ([resultCallBack[@"code"] intValue] == 0) {
            NSString *text = [resultCallBack[@"data"] objectForKey:@"text"];
            if (!text || text.length == 0) {
                return true;
            }
            [self addSpeechSubtitleWithText:text fileIndex:[dic[@"fileIndex"] integerValue]];
            return false;
        }else {
            NSLog(@"requestId:%@ errorCode:%d msg:%@", dic[@"requestId"], [resultCallBack[@"code"] intValue], resultCallBack[@"msg"]);
            //                    [self performSelector:@selector(getSpeechRecogCallBackWithDic:) withObject:dic afterDelay:1.0];
            return true;
        }
        //            });
    }
    
    return true;
    //    });
}

- (void)addSpeechSubtitleWithText:(NSString *)text fileIndex:(NSInteger)fileIndex {
    NSString *timeText = [text stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
//    NSArray *contentArray = [timeText componentsSeparatedByString:@"\n"];
    
    if(!_textAndTimeArray)
        _textAndTimeArray = [NSMutableArray<NSString*> array];
    [_textAndTimeArray addObject:timeText];
}


-(void)typeset:( NSString * ) str atTimeRange:(RDStrTimeRange*) timeRange
      strArrry:(NSMutableArray<NSString*> *) strArrry
strTimeRangeArray:(NSMutableArray<RDStrTimeRange *> *) strTimeRangeArray
{
    NSString * timeText = [str stringByReplacingOccurrencesOfString:@"/r" withString:@"\n"];
    timeText = [timeText stringByReplacingOccurrencesOfString:@"。" withString:@"\n"];
    timeText = [timeText stringByReplacingOccurrencesOfString:@"，" withString:@"\n"];
    timeText = [timeText stringByReplacingOccurrencesOfString:@"？" withString:@"\n"];
    timeText = [timeText stringByReplacingOccurrencesOfString:@"！" withString:@"\n"];
    timeText = [timeText stringByReplacingOccurrencesOfString:@"；" withString:@"\n"];
    timeText = [timeText stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
    
    NSArray<NSString*> *contentArray = [timeText componentsSeparatedByString:@"\n"];
    
    float  timeunit = CMTimeGetSeconds(CMTimeSubtract(timeRange.showTime, timeRange.startTime))/(timeText.length-contentArray.count);
    
    float firstStartTime = 0.0;
    for (int i = 0;  i < contentArray.count ; i++) {
        int count = contentArray[i].length/7 + (((contentArray[i].length%7)>0)?1:0);
        int RemainCount = contentArray[i].length%7;
        
        for (int j = 0; j < count; j++) {
            int strNumber = 0;
            RDStrTimeRange* strTimeRange = nil;
            strTimeRange = [RDStrTimeRange new];
            strTimeRange.startTime = CMTimeAdd(timeRange.startTime, CMTimeMake(firstStartTime*30, 30));
            
            if( (j == (count -1)) && (RemainCount != 0) )
            {
                strNumber = RemainCount;
                NSString * str = [contentArray[i] substringWithRange:NSMakeRange(7*j,RemainCount)];
                [strArrry addObject:str];
            }
            else
            {
                NSString * str = [contentArray[i] substringWithRange:NSMakeRange(7*j,7)];
                [strArrry addObject:str];
                strNumber = 7;
            }
        
            if( ( strTimeRangeArray.count > 0 ) && (CMTimeGetSeconds(strTimeRangeArray[strTimeRangeArray.count-1].showTime) > CMTimeGetSeconds(strTimeRange.startTime)) )
            {
                strTimeRangeArray[strTimeRangeArray.count-1].showTime = strTimeRange.startTime;
//                strTimeRange.startTime = strTimeRangeArray[strTimeRangeArray.count-1].showTime = strTimeRange.startTime;
//                firstStartTime = CMTimeGetSeconds(strTimeRangeArray[strTimeRangeArray.count-1].showTime);
            }
            
            firstStartTime = firstStartTime+timeunit*strNumber;
            float  fps = ((timeunit*strNumber)*30)/2.0;
            if( ( i == (contentArray.count-1) ) && ( j == (count-1) ) )
            {
                strTimeRange.showTime = timeRange.showTime;
                fps = ((CMTimeGetSeconds(timeRange.showTime) - CMTimeGetSeconds(timeRange.startTime))*30)/2.0;
            }
            else
                strTimeRange.showTime = CMTimeAdd( strTimeRange.startTime, CMTimeMake( firstStartTime*30, 30) );
            
            fps = (fps>5)?5:fps;
            

            
            
            strTimeRange.AnimationTime = CMTimeAdd( strTimeRange.startTime, CMTimeMake( fps, 30) );
            
            
            
            [strTimeRangeArray addObject:strTimeRange];
        }
    }
}

#pragma mark- 倒计时
-(UILabel*)countdownLabel
{
    if( !_countdownLabel )
    {
        _countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, kHEIGHT - (iPhone_X ? 44 : 0) )];
        _countdownLabel.backgroundColor = [UIColor clearColor];
        _countdownLabel.hidden = YES;
        _countdownLabel.textColor = [UIColor whiteColor];
        _countdownLabel.font = [UIFont systemFontOfSize:150];
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_countdownLabel];
    }
    return _countdownLabel;
}


#pragma mark- 文字转语音
#pragma mark- textView
-(UIView*)textView
{
    if( !_textView )
    {
        _textView = [[UIView alloc] initWithFrame:CGRectMake(0,_titleView.frame.size.height+_titleView.frame.origin.y, kWIDTH, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (_titleView.frame.size.height+_titleView.frame.origin.y))];
        _textView.hidden = YES;
        
        _avTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 15, kWIDTH, _textView.frame.size.height - 44 - 220)];
        _avTextView.backgroundColor = TOOLBAR_COLOR;
        _avTextView.returnKeyType = UIReturnKeyDone;
        _avTextView.textColor = [UIColor whiteColor];
        _avTextView.font = [UIFont systemFontOfSize:20];
        _avTextView.delegate = self;
        [_textView addSubview:_avTextView];
        self.auditionBtn.hidden = NO;
    }
    return _textView;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return FALSE;
    }
    return TRUE;
}

-(UIButton*)auditionBtn
{
    if(!_auditionBtn)
    {
        _auditionBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, _textView.frame.size.height-44, kWIDTH-20, 44)];
        _auditionBtn.backgroundColor = Main_Color;
        _auditionBtn.layer.masksToBounds = YES;
        _auditionBtn.layer.cornerRadius = 5;
        [_auditionBtn setTitle:RDLocalizedString(@"试听效果", nil) forState:UIControlStateNormal];
        [_auditionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_textView addSubview:_auditionBtn];
    }
    return _auditionBtn;
}


@end
