//
//  RDRecordViewController.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import "RDNavigationViewController.h"
#import "RDRecordViewController.h"
#import "ProgressBar.h"
#import "RDCustomButton.h"
#import "RDFilterChooserView.h"
#import <CoreMotion/CoreMotion.h>
#import "RDProgressHUD.h"
#import "RDEditVideoViewController.h"
#import "RDNextEditVideoViewController.h"
#import "RDMoveProgress.h"
#import "RDRecordSetViewController.h"

#define CHANGEVALUE 1

@interface RDRecordViewController ()<UIAlertViewDelegate,AVAudioPlayerDelegate,RDCameraManagerDelegate>
{
    CMMotionManager* motionManager;
    
    NSMutableArray* _videoArray;
    NSMutableArray* _videoDurationArray;
    
    NSMutableArray* _timeArray;
    BOOL            MODE; // true 方形 false 非方形
    BOOL            oldMODE; // true 方形 false 非方形
    int             isRecording; // 1 正在录制  (不可切换到照片) 0 未录制 (可切换到照片)  -1 准备录制
    BOOL            videoOrPhoto; // true 照片 false 视频
    RDProgressHUD   * hub;
    BOOL            isFirstRecord;
    BOOL            isPortrait;
    BOOL            isSquareTop;
    NSString        * recordStyle;
    int             currentRecordType;  //当前录制类型  0:视频  1:照片  2:短视频MV
    int             recordTypeCounts;   //可拍摄类型数目
    UIAlertView     *commonAlertView;   //20170503 wuxiaoxia 防止内存泄露
    
    NSInteger       filter_index;
    NSInteger       faceU_index;
    RDMusic         *_musicInfo;
    BOOL            _enterSelectMusic;
    float           faceUScrollViewHeight;
    UIImageView     *cameraWaterView;
    BOOL            enterCameraEnd;
    RDFaceUBeautyParams *beautyParams;
    float bottomHeight;
}

@property (nonatomic , assign) UIDeviceOrientation lastOrientation;

//    滤镜数组
@property (nonatomic , strong) NSArray<RDFilter *>  *filters;
@property (nonatomic , strong) NSMutableArray * filtersName;
@property (nonatomic , strong) UIButton* setButton;
@property (nonatomic , strong) UIButton* flashButton;
@property (nonatomic , strong) UIButton* switchButton;
@property (nonatomic , strong) UIButton* autoRecordButton;
@property (nonatomic , strong) UIButton* beautifyButton;

@property (nonatomic , strong) UIButton* backButton;

@property (nonatomic , strong) UIImageView* timeTipImageView;
@property (nonatomic , strong) UILabel* timeLabel;

@property (nonatomic , strong) UIButton* recordButton;

@property (nonatomic , strong) UIButton* filterItemsButton;
@property (nonatomic , strong) RDFilterChooserView *filterChooserView;

@property (nonatomic , strong) UIButton* finishButton;

@property (nonatomic , strong) UIButton* blackScreenButton;
@property (nonatomic , strong) UIView * topView;
@property (nonatomic , strong) UIView * bottomView;

@property (nonatomic , strong) UIView* blackScreenView;
@property (nonatomic , strong) UIView* aSplitView;
@property (nonatomic , strong) UIView* filtergroundView;

@property (nonatomic , strong) UILabel* label1;

@property (nonatomic ,strong) UIView* screenView;

@property (assign, nonatomic) CGFloat currentVideoDur;
@property (assign, nonatomic) CGFloat totalVideoDur;
@property (strong, nonatomic) ProgressBar* progressBar;
@property (strong, nonatomic) RDCustomButton* deleteButton;
@property (strong, nonatomic) UILabel* longSizeSplitTimeLabel;

@property (strong, nonatomic) UIScrollView *faceuScrollview;

@property (strong, nonatomic) UILabel* longSizeSplitCountLabel;
@property (strong, nonatomic) UIButton* changeModeView;
@property (strong, nonatomic) UIButton* hideFiltersButton;
@property (strong, nonatomic) UIView* notSquareDeleteVideoView;

@property (strong, nonatomic) UIButton* finish_Button;
@property (strong, nonatomic) UIView* VideoOrPhotoView;
@property (strong, nonatomic)UIView* buttonBGView;
@property (strong, nonatomic) UISegmentedControl* segmentedControl;

@property (nonatomic , strong) UIButton* changeMusicButton;
@property (nonatomic , strong) UIImageView* musicIcon;
@property (nonatomic , strong) UIButton* clearMusicButton;
@property (nonatomic , strong) AVAudioPlayer *audioPlayer;
//@property (nonatomic , strong) UISlider * exposureSlider;
@end

@implementation RDRecordViewController

@synthesize isSquareTop = _isSquareTop;

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(_enterSelectMusic){
        return;
    }
    [_cameraManager stopCamera];
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

- (void)initAudioPlayer{
    if(_musicInfo){
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_musicInfo.url error:&error];
        _audioPlayer.currentTime = CMTimeGetSeconds(_musicInfo.clipTimeRange.start);
        _audioPlayer.delegate = self;
    }
}
//- (UISlider *)exposureSlider{
//    if (!_exposureSlider) {
//        _exposureSlider = [[UISlider alloc] init];
//        _exposureSlider.frame = CGRectMake(0, kWIDTH + 200, kWIDTH, 5);
//        _exposureSlider.backgroundColor = [UIColor redColor];
//        [_exposureSlider addTarget:self action:@selector(exposureE:) forControlEvents:UIControlEventValueChanged];
//    }
//    return _exposureSlider;
//}
//- (void) exposureE:(UISlider *) slider{
//    float iso = slider.value;
////    [self.cameraManager exposure:iso];
//    [self.cameraManager zoom:iso*2+1];
//}
- (UIImageView *)musicIcon{
    if(!_musicIcon){
        _musicIcon = [UIImageView new];
        _musicIcon.backgroundColor = [UIColor clearColor];
        _musicIcon.image = [RDHelpClass getBundleImagePNG:@"剪辑-剪辑-音乐_乐符_@3x"];
        _musicIcon.contentMode = UIViewContentModeScaleAspectFit;
        _musicIcon.frame = CGRectMake(8, 8, 14, 14);
    }
    return _musicIcon;
}

- (UIButton *)clearMusicButton{
    if(!_clearMusicButton){
        _clearMusicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _clearMusicButton.backgroundColor = [UIColor clearColor];
        [_clearMusicButton setImage:[RDHelpClass getBundleImage:@"拍摄_取消拍摄默认"] forState:UIControlStateNormal];
        [_clearMusicButton addTarget:self action:@selector(clearMusic) forControlEvents:UIControlEventTouchUpInside];
    }
    _clearMusicButton.frame = CGRectMake(_changeMusicButton.frame.size.width - 35, 0, 30, 30);
    return _clearMusicButton;
}

#pragma mark - 摄像头管理器
- (UISegmentedControl *)segmentedControl{
    if (!_segmentedControl) {
        
        NSArray* segmentArray;
        if (_needFilter) {
            segmentArray = [NSArray arrayWithObjects:RDLocalizedString(@"美颜", nil),RDLocalizedString(@"贴纸", nil),RDLocalizedString(@"滤镜", nil),nil];
        }else{
            segmentArray = [NSArray arrayWithObjects:RDLocalizedString(@"美颜", nil),RDLocalizedString(@"贴纸", nil), nil];
        }
        UISegmentedControl * segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentArray];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
#pragma clang diagnostic pop
        segmentedControl.frame = CGRectMake(0, 0, kWIDTH, 40);
        segmentedControl.tintColor = SCREEN_BACKGROUND_COLOR;
        segmentedControl.backgroundColor = SCREEN_BACKGROUND_COLOR;
        NSDictionary *selected = @{NSFontAttributeName:[UIFont systemFontOfSize:18],
                                   NSForegroundColorAttributeName:Main_Color};
        //定义未选中状态下的样式normal，类型为字典
        NSDictionary *normal = @{NSFontAttributeName:[UIFont systemFontOfSize:16],
                                 NSForegroundColorAttributeName:[UIColor whiteColor]};
        
        [segmentedControl setTitleTextAttributes:normal forState:UIControlStateNormal];
        [segmentedControl setTitleTextAttributes:selected forState:UIControlStateSelected];
        
        segmentedControl.selectedSegmentIndex = 2;
        [segmentedControl addTarget:self action:@selector(changes:) forControlEvents:UIControlEventValueChanged];
        
        _segmentedControl = segmentedControl;
        
    }
    return _segmentedControl;
}
- (UIButton *) hideFiltersButton{
    if (!_hideFiltersButton) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 35, 35);
        button.center = CGPointMake(kWIDTH/2, kHEIGHT - 80 - 40/2 - 80);
        [button setImage:[RDHelpClass getBundleImage:@"拍摄_滤镜收起点击_"] forState:UIControlStateHighlighted];
        [button setImage:[RDHelpClass getBundleImage:@"拍摄_滤镜收起默认_"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showFilters:) forControlEvents:UIControlEventTouchUpInside];
        _hideFiltersButton = button;
    }
    return _hideFiltersButton;
}

- (void) changesButtonColor:(BOOL) mak{
    UILabel* filterButton = (UILabel*)([self.hideFiltersButton viewWithTag:123]);
    UILabel* itemButton = (UILabel*)([self.hideFiltersButton viewWithTag:124]);
    
    if (mak) {
        filterButton.textColor = UIColorFromRGB(0xf53333);
        itemButton.textColor = [UIColor whiteColor];
    }else{
        filterButton.textColor = [UIColor whiteColor];
        itemButton.textColor = UIColorFromRGB(0xf53333);
        
    }
}

- (BOOL)is64bit
{
#if defined(__LP64__) && __LP64__
    return YES;
#else
    return NO;
#endif
}

- (void) changes:(UISegmentedControl*)seg{
    __weak typeof(self) weakSelf = self;
    NSInteger index = seg.selectedSegmentIndex;
    
    if(!seg){
        index = 1;
    }
    
    if (index == 2) {
        [self removeBViews];
        [self.faceuScrollview removeFromSuperview];
        [self.view addSubview:self.filterChooserView];
        [self changesButtonColor:YES];
        
        [self.filterChooserView setChooserBlock:^( NSInteger idx,BOOL selectFilter) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(selectFilter){
                    filter_index = (int)idx;
                    [weakSelf.cameraManager setFilterAtIndex:idx];
                }
            });
        }];
        
        [_filterChooserView addFiltersToChooser:self.filters];
        [_filterChooserView setCurrentIndex:filter_index];
    }
    else if (index == 1) {
        [self removeBViews];
        [self.filterChooserView removeFromSuperview];
        [self.view addSubview:self.faceuScrollview];
        [self changesButtonColor:NO];
        
        NSArray* plistArray;
        
        if (_faceUURLString && _faceU) {
            plistArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"bundles"];
//            NSLog(@"%@",plistArray);
            
        }else{
            NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"FaceU" ofType:@"plist"];
            plistArray = [NSArray arrayWithContentsOfFile:plistPath];
        }
        
        NSMutableArray* items = [NSMutableArray array];
        NSMutableArray* itemNames = [NSMutableArray array];
        NSMutableArray* itemPaths = [NSMutableArray array];
        
        [items addObject:@"noitem"];
        [itemNames addObject:RDLocalizedString(@"无", nil)];
        [itemPaths addObject:@""];
        
        for (int i=0; i<plistArray.count; i++) {
            if ([[[plistArray objectAtIndex:i] objectForKey:@"name"] isEqualToString:@"bg_seg"] && ![self is64bit]) {
                //faceU的背景扣图只支持arm64
                continue;
            }
            [items addObject:[[plistArray objectAtIndex:i] objectForKey:@"url"]];
            [itemNames addObject:[[plistArray objectAtIndex:i] objectForKey:@"name"]];
            [itemPaths addObject:[[plistArray objectAtIndex:i] objectForKey:@"img"]];
        }

        int cellCount = 2;
        [_faceuScrollview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [itemNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDCustomButton *itemBtn = [[RDCustomButton alloc] initWithItem:items[idx] itemName:itemNames[idx] itemPath:itemPaths[idx]];
            itemBtn.backgroundColor = [UIColor clearColor];
            if(faceU_index == idx){
                [itemBtn selected:YES];
            }else{
                [itemBtn selected:NO];
            }
            itemBtn.tag = 20000 + idx;
            if(self.lastOrientation == UIDeviceOrientationPortrait){
                itemBtn.frame = CGRectMake(floorf(idx/cellCount)  * ((_faceuScrollview.frame.size.width - 9*4)/5 + 9), 9 + idx%cellCount * ((_faceuScrollview.frame.size.width - 9*4)/5 + 9), (_faceuScrollview.frame.size.width - 9*4)/5, (_faceuScrollview.frame.size.width - 9*4)/5);
            }
            else if(self.lastOrientation == UIDeviceOrientationLandscapeLeft){
                itemBtn.frame = CGRectMake(idx  * (((kWIDTH - 18) - 9*4)/5 + 9),(_faceuScrollview.frame.size.width - ((kWIDTH - 18) - 9*4) /5 )/2.0, ((kWIDTH - 18) - 9*4)/5, ((kWIDTH - 18) - 9*4)/5);
            }
            else if(self.lastOrientation == UIDeviceOrientationLandscapeRight){
                itemBtn.frame = CGRectMake(idx  * (((kWIDTH - 18) - 9*4)/5 + 9),(_faceuScrollview.frame.size.width - ((kWIDTH - 18) - 9*4)/5)/2.0, ((kWIDTH - 18) - 9*4)/5, ((kWIDTH - 18) - 9*4)/5);
            }
            [itemBtn addTarget:self action:@selector(faceuChooserBlock:) forControlEvents:UIControlEventTouchUpInside];
            if(idx==0){
               [itemBtn setImage: [RDHelpClass getBundleImagePNG:@"拍摄_滤镜无默认_@3x"] forState:UIControlStateNormal];
            }else{
                [RDHelpClass setFaceUItemBtnImage:itemPaths[idx] name:itemNames[idx] item:itemBtn];
            }
            
            [_faceuScrollview addSubview:itemBtn];
        }];
        if(self.lastOrientation == UIDeviceOrientationPortrait){
            _faceuScrollview.contentSize = CGSizeMake(ceilf(itemNames.count/2.0) * (((kWIDTH - 18) - 9*4)/5 + 9), 100);//_faceuScrollview.frame.size.height
        }else{
            _faceuScrollview.contentSize = CGSizeMake(itemNames.count * (((kWIDTH - 18) - 9*4)/5 + 9), 80);//_faceuScrollview.frame.size.width
        }
    }
    else if (index == 0){
        [self.filterChooserView removeFromSuperview];
        [self.faceuScrollview removeFromSuperview];

        [_filterChooserView removeItems];
        
        NSArray* names = @[RDLocalizedString(@"磨皮", nil),RDLocalizedString(@"美白", nil),RDLocalizedString(@"瘦脸", nil),RDLocalizedString(@"大眼", nil)];
        [_filterChooserView removeFromSuperview];
        RDFaceUBeautyParams *beautyParams = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.faceUBeautyParams;
        if (self.lastOrientation == UIDeviceOrientationPortrait) {
            
            UILabel* label ;
            
            for (int i= 0; i<4; i++) {
                
                label = [[UILabel alloc] initWithFrame:CGRectMake(5, 45 + 40*i, 60, 30)];
                label.text = names[i];
                label.tag = 432 + i;
                label.textColor = UIColorFromRGB(0xcccccc);
                [_filtergroundView addSubview:label ];
                
            }
            NSArray* segmentArray = [NSArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",nil];
            UISegmentedControl* smoothSegment = [[UISegmentedControl alloc] initWithItems:segmentArray];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            smoothSegment.segmentedControlStyle = UISegmentedControlStylePlain;
#pragma clang diagnostic pop
            smoothSegment.frame = CGRectMake(75, 45 , kWIDTH - 80, 30);
            smoothSegment.tintColor = UIColorFromRGB(0x33333b);
            
            NSDictionary *selected = @{NSFontAttributeName:[UIFont systemFontOfSize:18],
                                       NSForegroundColorAttributeName:Main_Color};
            NSDictionary *normal = @{NSFontAttributeName:[UIFont systemFontOfSize:16],
                                     NSForegroundColorAttributeName:UIColorFromRGB(0xcccccc)};
            
            [smoothSegment setTitleTextAttributes:normal forState:UIControlStateNormal];
            [smoothSegment setTitleTextAttributes:selected forState:UIControlStateSelected];
            smoothSegment.tag = 987 + 0;
            smoothSegment.selectedSegmentIndex = beautyParams.blurLevel - 1;
            
            [smoothSegment addTarget:self action:@selector(smoothingValue:) forControlEvents:UIControlEventValueChanged];
            [_filtergroundView addSubview:smoothSegment];
            
            UISlider* slider;
            for (int i = 1; i<4; i++) {
                slider = [[UISlider alloc] init];
                slider.maximumValue = 1.0;
                slider.minimumValue = 0.0;
                slider.minimumTrackTintColor = Main_Color;
                [slider setThumbImage:[RDHelpClass getBundleImagePNG:@"拍摄_拖动球_@3x"] forState:UIControlStateNormal];
                [slider setThumbImage:[RDHelpClass getBundleImagePNG:@"拍摄_拖动球_@3x"] forState:UIControlStateHighlighted];
                
                if (i==1) {
                    slider.value = beautyParams.colorLevel;
                }else if (i==2){
                    slider.value = beautyParams.cheekThinning;
                }else if (i==3){
                    slider.value = beautyParams.eyeEnlarging;
                }
                NSLog(@"%f",slider.value);
                slider.continuous = YES;
                slider.tag = 987 + i;
                [slider addTarget:self action:@selector(changevalue:) forControlEvents:UIControlEventValueChanged];
                slider.frame = CGRectMake(75, 45 + 40*i, kWIDTH - 80, 30);
                [_filtergroundView addSubview:slider];
            }
            
        }else{
            
            UILabel* label ;
            for (int i= 0; i<4; i++) {
                label = [[UILabel alloc] initWithFrame:CGRectMake((iPhone_X  ? (self.lastOrientation == UIDeviceOrientationLandscapeRight? 10 : 40)  : 10) + kHEIGHT/2*(i%2) - (i%2 * 10), 50 + 40*((int)i/2), 60, 30)];
                label.text = names[i];
                label.tag = 432 + i;
                label.textColor = UIColorFromRGB(0xcccccc);
                [_filtergroundView addSubview:label ];
                
            }
            float x = iPhone_X  ? (self.lastOrientation == UIDeviceOrientationLandscapeRight? 40 : 70) : 45;
            
            NSArray* segmentArray = [NSArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",nil];
            UISegmentedControl* smoothSegment = [[UISegmentedControl alloc] initWithItems:segmentArray];
            smoothSegment.frame = CGRectMake(30 + x , 50 , kHEIGHT/2 - 100, 30);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            smoothSegment.segmentedControlStyle = UISegmentedControlStylePlain;
#pragma clang diagnostic pop
            smoothSegment.tintColor = UIColorFromRGB(0x33333b);
            
            NSDictionary *selected = @{NSFontAttributeName:[UIFont systemFontOfSize:18],
                                       NSForegroundColorAttributeName:Main_Color};
            NSDictionary *normal = @{NSFontAttributeName:[UIFont systemFontOfSize:16],
                                     NSForegroundColorAttributeName:UIColorFromRGB(0xcccccc)};
            
            [smoothSegment setTitleTextAttributes:normal forState:UIControlStateNormal];
            [smoothSegment setTitleTextAttributes:selected forState:UIControlStateSelected];
            smoothSegment.tag = 987 + 0;
            smoothSegment.selectedSegmentIndex = beautyParams.blurLevel;
            
            [_filtergroundView addSubview:smoothSegment];
            
            UISlider* slider;
            for (int i = 1; i<4; i++) {
                slider = [[UISlider alloc] init];
                slider.maximumValue = 1.0;
                slider.minimumValue = 0.0;
                slider.minimumTrackTintColor = Main_Color;
                
                if (i==1) {
                    slider.value = beautyParams.colorLevel;
                }else if (i==2){
                    slider.value = beautyParams.cheekThinning;
                }else if (i==3){
                    slider.value = beautyParams.eyeEnlarging;
                }
                
                slider.continuous = YES;
                slider.tag = 987 + i;
                [slider addTarget:self action:@selector(changevalue:) forControlEvents:UIControlEventValueChanged];
                slider.frame = CGRectMake(30 + x + kHEIGHT/2*(i%2) - (i%2 * 20), 50 + 40*((int)i/2), kHEIGHT/2 - 100, 30);
                
                [_filtergroundView addSubview:slider];
                
            }
        }
    }
}

- (void)faceuChooserBlock:(RDCustomButton *)sender{
    RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
    if(sender.tag == 20000){
        [((RDCustomButton *)[_faceuScrollview viewWithTag:(20000 + faceU_index)]) selected:NO];
        
        
        faceU_index = sender.tag - 20000;
        [sender selected:YES];
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
        
        [((RDCustomButton *)[_faceuScrollview viewWithTag:(20000 + faceU_index)]) selected:NO];
        faceU_index = sender.tag - 20000;
        [sender selected:YES];
        
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
        [tool setFinish:^{
            [downProgressv removeFromSuperview];
            downProgressv = nil;
            [((RDCustomButton *)[_faceuScrollview viewWithTag:(20000 + faceU_index)]) selected:NO];
            faceU_index = sender.tag - 20000;
            [sender selected:YES];
            
            if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUItemChanged:)]) {
                [nv.rdVeUiSdkDelegate faceUItemChanged:bundleSavePath];
            }
        }];
        
        [tool start];
    }
}

- (void) removeBViews{
    for(int i = 0;i<4;i++){
        UIView* view1 = [self.view viewWithTag:987+i];
        [view1 removeFromSuperview];
        UIView* view2 = [self.view viewWithTag:432+i];
        [view2 removeFromSuperview];
        
    }
}

- (void ) getFaceUDataWithURL:(NSString*)urlString
{
    NSURLSession* session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    
    if ([urlString hasPrefix:@"http://www.gxzb.tv"]) { //
        request.HTTPBody = [@"type=ios" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ([urlString hasPrefix:@"http://dianbook.17rd.com"]) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:@"ios" forKey:@"type"];
        NSString *postURL= [RDHelpClass createPostJsonURL:params];
        NSData *postData = [postURL dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        request.HTTPBody = postData;
    }    
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    __weak RDRecordViewController *myself = self;
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error && data) {//20170324
            NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            
            NSArray* bundles = [[dict objectForKey:@"result"] objectForKey:@"bundles"];
            
            [[NSUserDefaults standardUserDefaults] setObject:bundles forKey:@"bundles"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself changes:_segmentedControl];
            });
        }
        
    }];
    [dataTask resume];
}

- (void) smoothingValue:(UISegmentedControl*)seg{
    int index = (int)seg.selectedSegmentIndex;
    beautyParams.blurLevel = index + 1;
    RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
    if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUBeautyParamChanged:)]) {
        [nv.rdVeUiSdkDelegate faceUBeautyParamChanged:beautyParams];
    }
}

- (void) changevalue:(UISlider *) slider{
    double value = slider.value;
    if (slider.tag ==987+1) { //美白
        beautyParams.colorLevel = value;
    }else if(slider.tag ==987+2 ){//瘦脸
        beautyParams.cheekThinning = value;
    }else if (slider.tag == 987 + 3){//大眼
        beautyParams.eyeEnlarging = value;
    }
    RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
    if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUBeautyParamChanged:)]) {
        [nv.rdVeUiSdkDelegate faceUBeautyParamChanged:beautyParams];
    }
}

- (UIView *)screenView{
    if (!_screenView) {
        UIView* screenView = [[UIView alloc] init];
        screenView.frame = CGRectMake(0, 0, MAX(kHEIGHT, kWIDTH),MIN(kHEIGHT, kWIDTH));
        screenView.center = CGPointMake( MIN(kHEIGHT, kWIDTH)/2,MAX(kHEIGHT, kWIDTH)/2);
        screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
        _screenView = screenView;
    }
    return _screenView;
}


- (RDCameraManager *)cameraManager {
    if (!_cameraManager) {
        CGRect rect = CGRectMake(0, 0, kHEIGHT, kWIDTH);
        if(CGSizeEqualToSize(_recordSize, CGSizeZero)){
            _recordSize = [RDCameraManager defaultMatchSize];
        }
        
        if(_bitrate ==0){
            _bitrate = 5 *1000*1000;
        }
        if(_fps == 0){
            _fps = 30.0;
        }
        
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"RDAVCaptureDevicePosition"]){
            NSInteger position = [[[NSUserDefaults standardUserDefaults] objectForKey:@"RDAVCaptureDevicePosition"] integerValue];
            _cameraPosition = (AVCaptureDevicePosition)position;
        }
        if (_cameraPosition == AVCaptureDevicePositionUnspecified) {
            _cameraPosition = AVCaptureDevicePositionFront;
        }
        [[NSUserDefaults standardUserDefaults] setObject:@(_cameraPosition) forKey:@"RDAVCaptureDevicePosition"];
        if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableDraft)
        {
            unlink([_videoPath UTF8String]);
        }
        RDCameraManager *cameraManager = [[RDCameraManager alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                                       APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                                      LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                                      resultFail:^(NSError *error) {
                                                                          NSLog(@"initError:%@", error.localizedDescription);
                                                                      }];
        [cameraManager prepareRecordWithFrame:rect
                                    superview:[self screenView]
                                      bitrate:_bitrate
                                          fps:_fps
                               isSquareRecord:MODE
                                  cameraSize:_recordSize
                                   outputSize:_recordSize
                                      isFront:(_cameraPosition == AVCaptureDevicePositionBack)?NO:YES
                                 captureAsYUV:_captureAsYUV
                             disableTakePhoto:NO
                        enableCameraWaterMark:_enableCameraWaterMark
                               enableRdBeauty:!_faceU];
        cameraManager.swipeScreenIsChangeFilter = NO;
        cameraManager.audioChannelNumbers = 2;
        
        NSMutableArray <RDFilter *> *filters = [NSMutableArray new];
        
        [[self filters] enumerateObjectsUsingBlock:^(RDFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length == 0){
                RDFilter* filter = [RDFilter new];
                if (obj.type == kRDFilterType_HeiBai) {
                    filter.type = kRDFilterType_HeiBai;
                    filter.filterPath = nil;
                    
                }else if (obj.type == kRDFilterType_SLBP){
                    filter.type = kRDFilterType_SLBP;
                    filter.filterPath = nil;
                }
                else if (obj.type == kRDFilterType_Sketch){
                    filter.type = kRDFilterType_Sketch;
                    filter.filterPath = nil;
                }else if (obj.type == kRDFilterType_DistortingMirror){
                    filter.type = kRDFilterType_DistortingMirror;
                    filter.filterPath = nil;
                    
                }else if (obj.type == kRDFilterType_LookUp){
                    filter.type = kRDFilterType_LookUp;
                   filter.filterPath = obj.filterPath;
                }
                
                else{
                    filter.type = kRDFilterType_ACV;
                    filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"Filteracvs/%@",obj.name] Type:@"acv"];
                }
                [filters addObject:filter];
            }else{
                [filters addObject:obj];
            }
        }];
        [cameraManager addFilters:filters];
        [cameraManager setfocus];
        cameraManager.delegate = self;
        cameraManager.beautifyState = BeautifyStateSeleted;
        if (iPhone_X) {
            cameraManager.fillMode = kRDCameraFillModeScaleAspectFill;
        }
        _cameraManager = cameraManager;
    }
    return _cameraManager;
}

-(void)pressHome:(NSNotification *) notification{
    if (_cameraManager.recordStatus == VideoRecordStatusBegin) {
        [self tap:nil];
        [_audioPlayer pause];
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    bottomHeight = (iPhone_X ? 224 : 164);
    
    if(!((RDNavigationViewController *)self.navigationController).editConfiguration.enableDraft)
    {
        unlink([_videoPath UTF8String]);
    }
    [self performSelectorInBackground:@selector(deleteRecordExtraFiles) withObject:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pressHome:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:[UIApplication sharedApplication]];
    self.view.userInteractionEnabled = NO;
    [UIApplication sharedApplication].idleTimerDisabled=YES;
    
    faceUScrollViewHeight = (kWIDTH - 18 - 9*4)/5*2 + 9*3 + (iPhone_X ? 34 : 0);
    if (_faceUURLString && _faceU) {
        beautyParams = ((RDNavigationViewController *)self.navigationController).cameraConfiguration.faceUBeautyParams;
        RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
        if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUBeautyParamChanged:)]) {
            [nv.rdVeUiSdkDelegate faceUBeautyParamChanged:beautyParams];
        }
    }
    _videoArray = [NSMutableArray array];
    _videoDurationArray = [NSMutableArray array];
    _timeArray = [NSMutableArray array];    
    
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    MODE = (_recordsizetype == RecordSizeTypeSquare) ? NO : YES;
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kRDRecordSet]) {
        if(CGSizeEqualToSize(_recordSize, CGSizeZero)){
            _recordSize = [RDCameraManager defaultMatchSize];
        }
        int resolutionIndex;
        if (_recordSize.width == 1080) {
            resolutionIndex = 3;
        }else if (_recordSize.width == 480) {
            resolutionIndex = 1;
        }else if (_recordSize.width == 360) {
            resolutionIndex = 0;
        }else {
            resolutionIndex = 2;
        }
        if (_bitrate == 0) {
            switch (resolutionIndex) {
                case 0:
                    _bitrate = 400 * 1000;
                    break;
                case 1:
                    _bitrate = 850 * 1000;
                    break;
                case 2:
                    _bitrate = 1800 * 1000;
                    break;
                case 3:
                    _bitrate = 3000 * 1000;
                    break;
                    
                default:
                    break;
            }
        }else if (_bitrate > 3000*1000) {
            _bitrate = 3000 * 1000;
        }else if (_bitrate < 400*1000) {
            _bitrate = 400 * 1000;
        }
        NSArray *setArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:_bitrate], [NSNumber numberWithInt:resolutionIndex], nil];
        [[NSUserDefaults standardUserDefaults] setObject:setArray forKey:kRDRecordSet];
    }
    NSArray *setArray = [[NSUserDefaults standardUserDefaults] objectForKey:kRDRecordSet];
    _bitrate = [setArray[0] intValue];
    int resolutionIndex = [setArray[1] intValue];
    switch (resolutionIndex) {
        case 0:
            _recordSize = CGSizeMake(360, 640);
            
            break;
        case 1:
            _recordSize = CGSizeMake(480, 640);
            
            break;
        case 2:
            _recordSize = CGSizeMake(720, 1280);
            
            break;
        case 3:
            _recordSize = CGSizeMake(1080, 1920);
            
            break;
            
        default:
            break;
    }
    if (_cameraMV && _cameraVideo && _cameraPhoto) {
        recordTypeCounts = 3;
    }else if ((_cameraMV && _cameraVideo) || (_cameraMV && _cameraPhoto) || (_cameraVideo && _cameraPhoto)) {
        recordTypeCounts = 2;
    }else {
        recordTypeCounts = 1;
    }

    [self changeMode];
    
    cameraWaterView = [[UIImageView alloc] init];
    cameraWaterView.backgroundColor = [UIColor clearColor];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [RDHelpClass createVideoFolderIfNotExist];
        
        if (_faceUURLString && _faceU) {
            [RDHelpClass createFaceUFolderIfNotExist];
            [self getFaceUDataWithURL:_faceUURLString];
            
        }
        _enterSelectMusic = NO;
    });
//    
//    [self.cameraManager startCamera];
}

- (void)cameraScreenDid{
    NSLog(@"%s",__func__);
    
    self.view.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationItem setHidesBackButton:YES];
    if (_recordorientation == 1 << 1) {
        self.lastOrientation = UIDeviceOrientationPortrait;
        
        [self deviceOrientationDidChangeTo:UIDeviceOrientationPortrait];
        
    }else if (_recordorientation == 1 << 2){
        self.lastOrientation = UIDeviceOrientationLandscapeLeft;
        
        [self deviceOrientationDidChangeTo:UIDeviceOrientationLandscapeLeft];
        
    }else{
        if (MODE) {
            self.lastOrientation = UIDeviceOrientationPortrait;
        }else{
            [self observeOrientation];
        }
    }
    [self checkCameraISOpen];
    
    
    [self.cameraManager startCamera];
    
}
#pragma mark - 滤镜组
- (void)getFilters {

    if (!_filters) {
        NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSMutableArray* filterArray = [NSMutableArray array];
        
        NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
        
        UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
        RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
        if(nav.editConfiguration.filterResourceURL.length>0){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"filter",@"type", nil];
                if(nav.appKey.length>0)
                    [params setObject:nav.appKey forKey:@"appkey"];
                NSMutableDictionary *filterList = [RDHelpClass updateInfomation:params andUploadUrl:nav.editConfiguration.filterResourceURL];
                //filtersName 获取失败
                if(filterList && [filterList[@"code"] intValue] == 0)
                {
                    self.filtersName = [filterList[@"data"] mutableCopy];
                }else {
                    self.filtersName  = [[NSMutableArray alloc] init];
                }                
                
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(nav.appKey.length>0)
                [itemDic setObject:nav.appKey forKey:@"appkey"];
                [itemDic setObject:@"" forKey:@"cover"];
                [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                [self.filtersName insertObject:itemDic atIndex:0];
                
                NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:filterPath]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:filterPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                [self.filtersName enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *itemPath = @"";
                    RDFilter* filter = [RDFilter new];
                    if([obj[@"name"] isEqualToString:RDLocalizedString(@"原始", nil)]){
                        filter.type = kRDFilterType_ACV;
                        NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVECore.bundle"];
                        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
                        itemPath = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"滤镜_正常"] ofType:@"acv"];
                    }else{
                        itemPath = [[[filterPath stringByAppendingPathComponent:[obj[@"name"] lastPathComponent]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
                        if (![[[obj[@"file"] pathExtension] lowercaseString] isEqualToString:@"acv"]){
                            filter.type = kRDFilterType_LookUp;
                        }
                        else{
                            filter.type = kRDFilterType_ACV;
                        }
                    }
                    filter.filterPath = itemPath;
                    filter.netCover = obj[@"cover"];
                    filter.name = obj[@"name"];
                    filter.netFile = obj[@"file"];
                    [filterArray addObject:filter];
                }];
                _filters = [filterArray copy];
                [_cameraManager addFilters:_filters];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_filterChooserView addFiltersToChooser:self.filters];
                });
            });
        }else{
            self.filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
            
            [_filtersName enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                RDFilter* filter = [RDFilter new];
                if ([obj isEqualToString:@"原始"]) {
                    filter.type = kRDFilterType_ACV;
                    filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"Filteracvs/%@",obj] Type:@"acv"];
                }
                else{
                    filter.type = kRDFilterType_LookUp;
                    filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"lookupFilter/%@",obj] Type:@"png"];
                }
                
                filter.name = _filtersName[idx];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",filter.name]];
                    if(![[NSFileManager defaultManager] fileExistsAtPath:photoPath]){
                        [RDCameraManager returnImageWith:inputImage Filter:filter withCompletionHandler:^(UIImage *processedImage) {
                            NSData* imagedata = UIImageJPEGRepresentation(processedImage, 1.0);
                            unlink([photoPath UTF8String]);
                            [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
                        }];
                    }
                });
                [filterArray addObject:filter];
            }];
            _filters = [filterArray copy];
            [_filterChooserView addFiltersToChooser:self.filters];
            [_cameraManager addFilters:_filters];
        }
    }
}

- (UIView *)topView{
    if (!_topView) {
        UIView* topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kHEIGHT, (iPhone_X ? 72 : 44))];
        topView.backgroundColor = [UIColor blackColor];
        topView.alpha = 0.4;
        _topView = topView;
    }
    return _topView;
}

- (UIView *)bottomView{
    if (!_bottomView) {
        UIView* bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT-bottomHeight, kWIDTH, bottomHeight)];
        bottomView.backgroundColor = UIColorFromRGB(0x19181d);
        bottomView.alpha = 0.4;
        _bottomView = bottomView;
    }
    return _bottomView;
}

- (UIButton *)changeMusicButton{
    if (!_changeMusicButton) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(changeMusic:) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        button.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 15;
        _changeMusicButton = button;
        
        [_changeMusicButton addSubview:self.musicIcon];
    }
    if (MODE && _isSquareTop) {
        _changeMusicButton.frame = CGRectMake(kWIDTH - 30 - 15,(( 44 + 45 + 10) + (iPhone_X ? 34 : 0)), 30, 30);
    }else {
        _changeMusicButton.frame = CGRectMake(kWIDTH - 30 - 15, (44 + 10) + (iPhone_X ? 34 : 0), 30, 30);
    }
    
    if (_musicInfo) {
        NSString *musicTitle = @"";
        if(_musicInfo.name){
            musicTitle = _musicInfo.name;
        }
        CGRect rect = [musicTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:_changeMusicButton.titleLabel.font.fontName size:_changeMusicButton.titleLabel.font.pointSize]} context:nil];
        
        CGRect btnRect = _changeMusicButton.frame;
        btnRect.size.width = rect.size.width + 10 + 70;
        
        btnRect.origin.x = kWIDTH - 15 - btnRect.size.width;
        if (MODE && _isSquareTop) {
            btnRect.origin.y = (44 + 45 + 10) + (iPhone_X ? 44 : 0);
        }else {
            btnRect.origin.y = (44 + 10) + (iPhone_X ? 34 : 0);
        }
        _changeMusicButton.frame = btnRect;
        
        [_changeMusicButton setTitle:musicTitle forState:UIControlStateNormal];
        
        CGRect cbtnRect = self.clearMusicButton.frame;
        cbtnRect.origin.x = btnRect.size.width - 30;
        self.clearMusicButton.frame = cbtnRect;
        if(_musicInfo){
            _musicIcon.frame = CGRectMake(14, 8, 14, 14);
        }else{
            _musicIcon.frame = CGRectMake(8, 8, 14, 14);
        }
        if(!self.clearMusicButton.superview)
            [_changeMusicButton addSubview:self.clearMusicButton];
    }
    
    return _changeMusicButton;
}

- (UIButton *)setButton {
    if (!_setButton) {
        UIButton *setBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [setBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_设置默认@3x"] forState:UIControlStateNormal];
        [setBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_设置点击@3x"] forState:UIControlStateHighlighted];
        [setBtn setFrame:CGRectMake(0, (iPhone_X ? 44 : 0), 44, 44)];
        [setBtn addTarget:self action:@selector(setButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _setButton = setBtn;
    }
    return _setButton;
}

- (UIButton *)flashButton{
    if (!_flashButton) {
        UIButton* flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光默认_@3x"] forState:UIControlStateNormal];
        [flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光点击_@3x"] forState:UIControlStateHighlighted];
        [flashButton setFrame:CGRectMake(0, (iPhone_X ? 44 : 0), 44, 44)];
        [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
        _flashButton = flashButton;
    }
    return _flashButton;
}
- (UIButton *)finish_Button{
    if (!_finish_Button) {
        UIButton* finish_Button = [UIButton buttonWithType:UIButtonTypeCustom];
        [finish_Button setImage:[RDHelpClass getBundleImagePNG:@"剪辑_下一步完成默认_@2x"] forState:UIControlStateNormal];
        
        [finish_Button setImage:[RDHelpClass getBundleImagePNG:@"剪辑_下一步完成点击_@2x"] forState:UIControlStateHighlighted];
        [finish_Button setFrame:CGRectMake(_changeMusicButton.frame.size.width - 30, (iPhone_X ? 34 : 0), 30, 30)];
        [finish_Button addTarget:self action:@selector(finish:) forControlEvents:UIControlEventTouchUpInside];
        
        _finish_Button = finish_Button;
        
    }
    return _finish_Button;
}

- (UIButton *)switchButton{
    if (!_switchButton) {
        UIButton* switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [switchButton setImage:[RDHelpClass getBundleImage:@"拍摄_镜头翻转默认"] forState:UIControlStateNormal];
        [switchButton setImage:[RDHelpClass getBundleImage:@"拍摄_镜头翻转点击"] forState:UIControlStateHighlighted];
        [switchButton addTarget:self action:@selector(switchBackOrFront) forControlEvents:UIControlEventTouchUpInside];
        [switchButton setFrame:CGRectMake(kWIDTH-150, 0, 44, 44)];
        _switchButton = switchButton;
    }
    return _switchButton;
}
- (UIButton *)autoRecordButton{
    if (!_autoRecordButton) {
        UIButton* autoRecordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [autoRecordButton setImage:[RDHelpClass getBundleImage:@"拍摄_倒计时默认"] forState:UIControlStateNormal];
        [autoRecordButton setFrame:CGRectMake(kWIDTH-100, (iPhone_X ? (48 + 44) : 48), 44, 44)];
        [autoRecordButton addTarget:self action:@selector(autoRecord:) forControlEvents:UIControlEventTouchUpInside];
        _autoRecordButton = autoRecordButton;
    }
    return _autoRecordButton;
}
- (UILabel *)label1{
    if (!_label1) {
        UILabel * label =  [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        label.backgroundColor = [UIColor whiteColor];
        label.center = self.view.center;
        label.layer.cornerRadius = 5;
        label.layer.masksToBounds = YES;
        label.text = [NSString stringWithFormat:RDLocalizedString(@"%@秒后自动录制", nil),@"5"];
        label.alpha = 0.7;
        label.textAlignment = NSTextAlignmentCenter;
        [label setTextColor:[UIColor blackColor]];
        _label1 = label;
    }
    return _label1;
}

- (void) autoRecord: (UIButton *) button{
    NSLog(@"%s",__func__);
    static int count = 6;
    self.label1.hidden = NO;
    self.autoRecordButton.enabled = NO;
    self.recordButton.enabled = NO;
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
        
        if (count < 2) {
            dispatch_source_cancel(timer);
            dispatch_async(mainQueue, ^{
                [self tap:nil];
                
                
                _label1.hidden = YES;
                count = 6;
                _recordButton.enabled = YES;
            });
        }else{
            count--;
            dispatch_async(mainQueue, ^{
                if (videoOrPhoto) {
                    _label1.text = [NSString stringWithFormat:RDLocalizedString(@"%d秒后拍摄照片", nil),count];
                }else{
                    _label1.text = [NSString stringWithFormat:RDLocalizedString(@"%d秒后开始录制", nil),count];
                }
                
            });
        }
    });
    dispatch_resume(timer);
    
}
- (UIButton *)beautifyButton{
    if (!_beautifyButton) {
        UIButton* beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [beautifyButton setImage:[RDHelpClass getBundleImage:@"拍摄_美颜默认"] forState:UIControlStateNormal];
        [beautifyButton setImage:[RDHelpClass getBundleImage:@"拍摄_美颜选中"] forState:UIControlStateSelected];
        beautifyButton.selected = NO;
        [beautifyButton setFrame:CGRectMake(kWIDTH-200, (iPhone_X ? 44 : 0), 44, 44)];
        [beautifyButton addTarget:self action:@selector(beautify:) forControlEvents:UIControlEventTouchUpInside];
        _beautifyButton = beautifyButton;
    }
    return _beautifyButton;
}

- (UIButton *)backButton{
    if (!_backButton) {
        UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回默认_@3x"] forState:UIControlStateNormal];
        [backButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回点击_@3x"] forState:UIControlStateSelected];
        [backButton setFrame:CGRectMake(1, (iPhone_X ? 72-44 : 0), 44, 44)];
        [backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        _backButton = backButton;
    }
    return _backButton;
}

- (void) back : (UIButton *) button{
    
    
    [self deleteItems];
    if(cancelBlock){
        cancelBlock(0,self);
    }
    if(_push){
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (UIImageView *)timeTipImageView{
    if (!_timeTipImageView) {
        UIImageView* timeTipImageView = [[UIImageView alloc] init];
        [timeTipImageView setFrame:CGRectMake(10, 44, 105, 40)];
        [timeTipImageView setImage:[RDHelpClass getBundleImage:@"拍摄_时间"]];
        _timeTipImageView = timeTipImageView;
    }
    return _timeTipImageView;
}

- (UILabel *)timeLabel{
    if (!_timeLabel) {
        UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, iPhone_X ? 66 : 44, 100, 40)];
        timeLabel.text = @"00:00:00";
        [timeLabel setTextColor:[UIColor whiteColor]];
        _timeLabel = timeLabel;
    }
    return _timeLabel;
}

- (UIButton *)recordButton{
    if (!_recordButton) {
        UIButton* recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
        [recordButton setFrame:CGRectMake(0, 0, 70, 70)];
        
        UILongPressGestureRecognizer* longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        longpressGesture.minimumPressDuration = 0.2;
        [recordButton addGestureRecognizer:longpressGesture];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [recordButton addGestureRecognizer:tapGesture];//
        
        _recordButton = recordButton;
    }
    return _recordButton;
}

- (void) tap:(UITapGestureRecognizer *)gesture{
    
    if (!(self.currentVideoDur == 0.0 || self.currentVideoDur > 1.0)) {
        
        return;
    }
    
    if(gesture.state == UIGestureRecognizerStateBegan){
        [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        
    }
    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed){
        [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
        
    }
    
    if (videoOrPhoto) {
        self.autoRecordButton.enabled = YES;
        
        [_cameraManager takePhoto:UIImageOrientationUp block:^(UIImage *image) {
            if(MODE){
               image = [self cropSquareImage:image];
            }
            if (_more) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }else{
                NSString *photoPath = [kRDDraftDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo%d.jpg",0]];
                if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDraft)
                {
                    BOOL have = NO;
                    NSInteger exportPathIndex = 0;
                    do {
                        photoPath = [kRDDraftDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo%d.jpg",exportPathIndex]];
                        exportPathIndex ++;
                        have = [[NSFileManager defaultManager] fileExistsAtPath:photoPath];
                    } while (have);
                }else {
                    unlink([photoPath UTF8String]);
                }
                //mark solaren 返回一个图片路径
                NSData* imagedata = UIImageJPEGRepresentation(image, 1.0);
                
                [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
                if(_push && finishBlock){
                    [self deleteItems];
                    if (_isWriteToAlbum) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                    }
                    if (_PhotoPathBlock) {
                        _PhotoPathBlock(photoPath);
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }else{
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self deleteItems];
                        if (_isWriteToAlbum) {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                        }
                        
                        if (_PhotoPathBlock) {
                            _PhotoPathBlock(photoPath);
                        }
                    }];
                }
            }
        }];
        
        return;
    }
    
    if (MODE) {
        if (currentRecordType == RecordTypeMVVideo || _MAX_VIDEO_DUR_1 > 0) {
            _progressBar.hidden = NO;
        }
        self.changeModeView.enabled = NO;
        self.timeTipImageView.hidden = NO;
        self.timeLabel.hidden = NO;
    }else {
        if (currentRecordType == RecordTypeMVVideo || _MAX_VIDEO_DUR_2 > 0) {
            _progressBar.hidden = NO;
        }
        _longSizeSplitCountLabel.hidden = NO;
        
        self.timeTipImageView.hidden = NO;
        self.timeLabel.hidden = NO;
        
    }
    if ((currentRecordType != RecordTypeMVVideo && ((MODE && _MAX_VIDEO_DUR_1 == 0) || (!MODE && _MAX_VIDEO_DUR_2 == 0))) || (currentRecordType == RecordTypeMVVideo && _totalVideoDur < _MVRecordMaxDuration)) {
        goto A1;
    }
    if ((_totalVideoDur > _MAX_VIDEO_DUR_1 && MODE && _MAX_VIDEO_DUR_1>0)
        || (_totalVideoDur > _MAX_VIDEO_DUR_2 && !MODE && _MAX_VIDEO_DUR_2>0)
        || (currentRecordType == RecordTypeMVVideo && _totalVideoDur > _MVRecordMaxDuration)) {
        return;
    }
A1:
    self.autoRecordButton.enabled = NO;
    _changeModeView.enabled = NO;
    
    if (_cameraManager.recordStatus == VideoRecordStatusUnknown || _cameraManager.recordStatus == VideoRecordStatusEnd) {
        
        if ([_cameraManager assetWriterStatus] == 1) {
            isRecording = 0;
            self.autoRecordButton.enabled = YES;
            _changeModeView.enabled = YES;
            
            return;
        }
        if(isRecording == 1){
            return;
        }
        NSLog(@"开始录制");
        
        recordStyle = @"tap";
//        if(_cameraManager.recordStatus == VideoRecordStatusPause){
//            _cameraManager.recordStatus = VideoRecordStatusResume;
//        }else{
//            _cameraManager.recordStatus = VideoRecordStatusBegin;
//        }
        _cameraManager.recordStatus = VideoRecordStatusBegin;
        if (MODE) {
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        }
        
        if (!MODE && self.lastOrientation == UIDeviceOrientationPortrait) {
            
            if (CHANGEVALUE == 1) {
                _deleteButton.hidden = YES;
            }else{
                _deleteButton.hidden = NO;
            }
            
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        }else if(!MODE && self.lastOrientation == UIDeviceOrientationLandscapeLeft)
        {
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停横@3x"] forState:UIControlStateNormal];
        }else if(!MODE && self.lastOrientation == UIDeviceOrientationLandscapeRight){
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停横@3x"] forState:UIControlStateNormal];
        }
        [self startCountDurTimer];
        
    }else if (_cameraManager.recordStatus == VideoRecordStatusBegin) {
        NSLog(@"停止录制");
        
        _cameraManager.recordStatus = VideoRecordStatusEnd;
        [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
    }
}

- (UIImage *)cropSquareImage:(UIImage *)image{
    
    CGImageRef sourceImageRef = [image CGImage];//将UIImage转换成CGImageRef
    
    CGFloat _imageWidth = image.size.width * image.scale;
    CGFloat _imageHeight = image.size.height * image.scale;
    CGFloat _width = _imageWidth > _imageHeight ? _imageHeight : _imageWidth;
    CGFloat _offsetX = 0;//(_imageWidth - _width) / 2;
    CGFloat _offsetY = 64* image.scale;//(_imageHeight - _width) / 2;
    
    CGRect rect = CGRectMake(_offsetX, _offsetY, _width, _width);
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);//按照给定的矩形区域进行剪裁
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    if (newImageRef) {
        CGImageRelease(newImageRef);
    }
    
    return newImage;
}

- (void) longPressAction: (UILongPressGestureRecognizer *) recognizer{
    
    if (videoOrPhoto) {
        return;
    }
    if (!(self.currentVideoDur == 0.0 || self.currentVideoDur > 1.0)) {
        
        return;
    }
    
    if(recognizer.state == UIGestureRecognizerStateBegan){
        [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        
    }
    if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed){
        [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
    }
    if (!MODE) {
        _longSizeSplitCountLabel.hidden = NO;
    }
    self.timeTipImageView.hidden = NO;
    self.timeLabel.hidden = NO;
    //
    self.autoRecordButton.enabled = NO;
    _changeModeView.enabled = NO;
    
    if (self.lastOrientation == UIDeviceOrientationPortrait) {
        if (CHANGEVALUE == 1) {
            _deleteButton.hidden = YES;
        }else{
            _deleteButton.hidden = NO;
        }
    }
    
    self.changeModeView.enabled = NO;
    
    if ((currentRecordType != RecordTypeMVVideo && ((MODE && _MAX_VIDEO_DUR_1 == 0) || (!MODE && _MAX_VIDEO_DUR_2 == 0))) || (currentRecordType == RecordTypeMVVideo && _totalVideoDur < _MVRecordMaxDuration)) {
        goto A2;
    }
    if ((_totalVideoDur > _MAX_VIDEO_DUR_1 && MODE && _MAX_VIDEO_DUR_1>0)
        || (_totalVideoDur > _MAX_VIDEO_DUR_2 && !MODE && _MAX_VIDEO_DUR_2 > 0)
        || (currentRecordType == RecordTypeMVVideo && _totalVideoDur > _MVRecordMaxDuration)) {
        return;
    }
A2:
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        if ([_cameraManager assetWriterStatus] == 1) {
            return;
        }
        
        NSLog(@"按住录制按钮");
        
        recordStyle = @"longpress";
        
        [_progressBar setLastProgressToStyle:ProgressBarProgressStyleNormal];
                
        _cameraManager.recordStatus = VideoRecordStatusBegin;
        [self startCountDurTimer];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSLog(@"松开录制按钮");
        
        _cameraManager.recordStatus = VideoRecordStatusEnd;
    }
}

- (void)startCountDurTimer
{
   [_audioPlayer play];
    NSLog(@"开始播放音乐1");
    [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_完成拍摄默认_@3x"] forState:UIControlStateNormal];
    [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_完成拍摄点击_@3x"] forState:UIControlStateSelected];
    _setButton.enabled = NO;
    if (_hiddenPhotoLib) {
        _finishButton.hidden = NO;
    }
    
    [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图默认_@3x"] forState:UIControlStateNormal];
    [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图点击_@3x"] forState:UIControlStateHighlighted];
    
    if (!isFirstRecord) {
        if (self.lastOrientation == UIDeviceOrientationLandscapeRight) {
            //isPortrait = YES;
            _cameraManager.cameraDirection = kRIGHT;
        }else if (self.lastOrientation == UIDeviceOrientationLandscapeLeft) {
            //isPortrait = YES;
            _cameraManager.cameraDirection = kLEFT;
        }else if (self.lastOrientation == UIDeviceOrientationPortraitUpsideDown) {
            //isPortrait = NO;
            _cameraManager.cameraDirection = kDOWN;
        }else{
            //isPortrait = NO;
            _cameraManager.cameraDirection = kUP;
        }
        /*
         if (self.lastOrientation == UIDeviceOrientationPortrait) {
         isPortrait = YES;
         _cameraManager.isPortrait = isPortrait;
         }else{
         isPortrait = NO;
         _cameraManager.isPortrait = isPortrait;
         }
         */
        isFirstRecord = YES;
    }
    //更新录制两段以上有一段删除不掉的bug
    if(isRecording !=1){
        self.currentVideoDur = 0.000;
        [_progressBar addProgressView];
        [_progressBar stopShining];
    }
    isRecording = 1;
    
//    self.currentVideoDur = 0.000;
//    [_progressBar addProgressView];
//    [_progressBar stopShining];
    
    _notSquareDeleteVideoView.userInteractionEnabled = NO;
    _notSquareDeleteVideoView.alpha = 0.4;

    if (!MODE) {
        _blackScreenButton.hidden = NO;
    }
    if (MODE && [_progressBar getProgressIndicatorHiddenState]) {
        [_progressBar setAllProgressToNormal];
    }
    
    [_deleteButton setButtonStyle:DeleteButtonStyleDisable];
    
    [self hideVideoAndPhotoLabel:YES];
}
- (void)currentTime:(float)time{
//    NSLog(@"%s %f",__func__,time);
    if(_cameraManager.recordStatus == VideoRecordStatusEnd){
        return;
    }
    self.currentVideoDur = time;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_cameraManager.recordStatus != VideoRecordStatusEnd){
            [self onTimer];
        }
        
    });
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(isRecording == 1){
            _audioPlayer.currentTime = CMTimeGetSeconds(_musicInfo.clipTimeRange.start);
            [_audioPlayer play];
            NSLog(@"开始播放音乐2");
        }
    });
}

- (void)onTimer
{
    //NSLog(@"statues:%ld, %lf",_cameraManager.recordStatus,_audioPlayer.currentTime);
    if(_audioPlayer.currentTime >=CMTimeGetSeconds(CMTimeAdd(_musicInfo.clipTimeRange.start, _musicInfo.clipTimeRange.duration))){
        _audioPlayer.currentTime = CMTimeGetSeconds(_musicInfo.clipTimeRange.start);
    }
    if (currentRecordType == RecordTypeMVVideo) {//短视频MV
        CGFloat all = (_totalVideoDur+self.currentVideoDur)>=_MVRecordMaxDuration?_MVRecordMaxDuration:(_totalVideoDur+self.currentVideoDur);
        
        int all_ = (int)(all*100);
        _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
        //NSLog(@"4总时间%d",all_);
        [_progressBar setLastProgressToWidth:self.currentVideoDur / _MVRecordMaxDuration * (_progressBar.frame.size.width - _videoArray.count*1)];
        
        if (_totalVideoDur + _currentVideoDur >= _MVRecordMaxDuration ) {
            _cameraManager.recordStatus = VideoRecordStatusEnd;
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
            
            [self finish:_finishButton];
        }
    }else {
        if (MODE) {
            if (_MAX_VIDEO_DUR_1>0) {
                CGFloat all = (_totalVideoDur+self.currentVideoDur)>=_MAX_VIDEO_DUR_1?_MAX_VIDEO_DUR_1:(_totalVideoDur+self.currentVideoDur);
                
                int all_ = (int)(all*100);
                _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
                //NSLog(@"3总时间%d",all_);
                [_progressBar setLastProgressToWidth:self.currentVideoDur / _MAX_VIDEO_DUR_1 * (_progressBar.frame.size.width - _videoArray.count*1)];
                
                if (_totalVideoDur + _currentVideoDur >= _MAX_VIDEO_DUR_1 ) {
                    _cameraManager.recordStatus = VideoRecordStatusEnd;
                    [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
                    
                    [self finish:_finishButton];
                }
            }else{
                CGFloat all = _totalVideoDur+self.currentVideoDur;
                int all_ = (int)(all*100);
                _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
            }
            
        }else{
            
            if (_MAX_VIDEO_DUR_2 > 0) {
                CGFloat all = (_totalVideoDur+self.currentVideoDur)>=_MAX_VIDEO_DUR_2?_MAX_VIDEO_DUR_2:(_totalVideoDur+self.currentVideoDur);
                int all_ = (int)(all*100);
                _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
                //NSLog(@"2总时间%d",all_);
                [_progressBar setLastProgressToWidth:self.currentVideoDur / _MAX_VIDEO_DUR_2 * (_progressBar.frame.size.width - _videoArray.count*1)];
                
                if (_totalVideoDur + _currentVideoDur >= _MAX_VIDEO_DUR_2 ) {
                    _cameraManager.recordStatus = VideoRecordStatusEnd;
                    [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
                    
                    [self finish:_finishButton];
                }
            }else{
                
                CGFloat all = _totalVideoDur+self.currentVideoDur;
                _longSizeSplitTimeLabel.text = [NSString stringWithFormat:@"%05.2lf",all];
                int all_ = (int)(all*100);
                _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
                //NSLog(@"1总时间%d   : %f     :  %f",all_,_totalVideoDur,self.currentVideoDur);
            }
        }
    }
}

- (void)stopCountDurTimer
{
    [_audioPlayer pause];
    if (_videoArray.count > 0) {
        [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_完成拍摄默认_@3x"] forState:UIControlStateNormal];
        [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_完成拍摄点击_@3x"] forState:UIControlStateSelected];
        
        [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_退出拍摄默认_@3x"] forState:UIControlStateNormal];
        [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_退出拍摄点击_@3x"] forState:UIControlStateHighlighted];
        
        [_deleteButton setButtonStyle:DeleteButtonStyleNormal];
    }else {
        _longSizeSplitTimeLabel.hidden = YES;
        _longSizeSplitCountLabel.hidden = YES;
        self.autoRecordButton.enabled = YES;
        _timeLabel.hidden = YES;
        _timeTipImageView.hidden = YES;
        
        [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册默认_@3x"] forState:UIControlStateNormal];
        [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册点击_@3x"] forState:UIControlStateSelected];
        [_deleteButton setButtonStyle:DeleteButtonStyleDisable];
        _setButton.enabled = YES;
        isFirstRecord = NO;
        if (_hiddenPhotoLib) {
            _finishButton.hidden = YES;
        }
        [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图默认_@3x"] forState:UIControlStateNormal];
        [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图点击_@3x"] forState:UIControlStateHighlighted];
        isRecording = -1;
        [self hideVideoAndPhotoLabel:NO];
    }
    [_progressBar startShining];
    
    _totalVideoDur += self.currentVideoDur;
    
    _notSquareDeleteVideoView.userInteractionEnabled = YES;
    _notSquareDeleteVideoView.alpha = 1.;
    
    if (_currentVideoDur > 0) {
        [_timeArray addObject:[NSNumber numberWithFloat:self.currentVideoDur]];
    }
    _longSizeSplitCountLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)_timeArray.count];
    [self.view bringSubviewToFront:_longSizeSplitCountLabel];
    NSLog(@"总时间%f : %f",_totalVideoDur,self.currentVideoDur);
}

- (float)recordTime{
    return [self totalVideoDuration:_videoArray];
}

- (void)waterMarkProcessingCompletionBlockWithView:(UIView *)view withTime:(float)time{
    if(!_enableCameraWaterMark){
        return;
    }
    if(_cameraWaterProcessingCompletionBlock){
        RecordStatus status;
        if(time > MAX(_cameraWaterMarkHeaderDuration, 0)){
            if(enterCameraEnd){
                status = RecordEnd;
            }else{
                status = Recording;
            }
            
        }else{
            status = RecordHeader;
        }
        _cameraWaterProcessingCompletionBlock(MODE,status,view,time);
        return;
    }
    [view addSubview:cameraWaterView];
    
    float width = view.frame.size.width;
    float height = (MODE ? view.frame.size.width : view.frame.size.height);
    if(time > MAX(_cameraWaterMarkHeaderDuration, 0)){
        if(enterCameraEnd){
            cameraWaterView.image = _waterFooter;
            cameraWaterView.frame = CGRectMake((width - _waterFooter.size.width)/2.0, (height - _waterFooter.size.height)/2.0, _waterFooter.size.width, _waterFooter.size.height);
            NSLog(@"片尾");
        }else{
            cameraWaterView.image = _waterBody;
            cameraWaterView.frame = CGRectMake((width - _waterBody.size.width)/2.0, (height - _waterBody.size.height)/2.0, _waterBody.size.width, _waterBody.size.height);
            NSLog(@"片中间");
        }
        
    }else{
        cameraWaterView.image = _waterHeader;
        cameraWaterView.frame = CGRectMake((width - _waterHeader.size.width)/2.0, (height - _waterHeader.size.height)/2.0, _waterHeader.size.width, _waterHeader.size.height);
        NSLog(@"片头");
    }
}


- (float) totalVideoDuration:(NSArray *) videoURLs{
    CMTime totalDuration = kCMTimeZero;
    for (int i = 0;i<_videoDurationArray.count;i++) {
       totalDuration = CMTimeAdd(totalDuration, CMTimeSubtract(CMTimeMakeWithSeconds([_videoDurationArray[i] floatValue], TIMESCALE), CMTimeMake(0, _fps)));
    }
    
//    for (int i = 0;i<videoURLs.count;i++) {
//        if([videoURLs[i] isKindOfClass:[NSURL class]]){
//            NSURL* url = videoURLs[i];
//            AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
//            totalDuration = CMTimeAdd(totalDuration, CMTimeSubtract(asset.duration, CMTimeMake(0, _fps)));
//        }else{
//            NSLog(@"没有录制成功");
//        }
//        
//    }
    return CMTimeGetSeconds(totalDuration);
}

- (UIButton *)filterItemsButton{
    if (!_filterItemsButton) {
        UIButton* filterItemsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [filterItemsButton setFrame:CGRectMake(0,0, 50, 50)];
        if (iPhone4s) {
            [filterItemsButton setCenter:CGPointMake(53, (kWIDTH + kHEIGHT + 48)/2)];
        }else{
            [filterItemsButton setCenter:CGPointMake(53, kHEIGHT - 45 - 18 - (iPhone_X ? 60 : 0))];
        }
        [filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图默认_@3x"] forState:UIControlStateNormal];
        [filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图点击_@3x"] forState:UIControlStateHighlighted];
        [filterItemsButton addTarget:self action:@selector(showFilters:) forControlEvents:UIControlEventTouchUpInside];
        _filterItemsButton = filterItemsButton;
    }
    return _filterItemsButton;
}

- (UIView *)filtergroundView{
    if (!_filtergroundView) {
        float height = _faceU ? (36 + faceUScrollViewHeight + 40) : 171;
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - height, kHEIGHT, height)];
        view.backgroundColor = UIColorFromRGB(0x19181d);
        _filtergroundView = view;
    }
    return _filtergroundView;
}

-(UIScrollView *)faceuScrollview{
    if(!_faceuScrollview){
        _faceuScrollview  = [[UIScrollView alloc] init];
        _faceuScrollview.showsVerticalScrollIndicator = NO;
        _faceuScrollview.showsHorizontalScrollIndicator = NO;
        _faceuScrollview.backgroundColor = [UIColor clearColor];
        if(self.lastOrientation == UIDeviceOrientationPortrait){
            _faceuScrollview.frame = CGRectMake(9, kHEIGHT - 40 - faceUScrollViewHeight, kWIDTH - 18, faceUScrollViewHeight - (iPhone_X ? 34 : 0));
        }
        else if(self.lastOrientation == UIDeviceOrientationLandscapeLeft){
            _faceuScrollview.frame = CGRectMake(100-kHEIGHT/2, kHEIGHT/2-51 , kHEIGHT - 18, 100);
        }
        else if(self.lastOrientation == UIDeviceOrientationLandscapeRight){
            _faceuScrollview.frame = CGRectMake(100-kHEIGHT/2, kHEIGHT/2-51 , kHEIGHT - 18, 100);
        }
    }
    return _faceuScrollview;
}

- (RDFilterChooserView *)filterChooserView{
    if (!_filterChooserView) {
        RDFilterChooserView *scrollView = [[RDFilterChooserView alloc] initWithFrame:CGRectMake(0, kHEIGHT-80, kHEIGHT, 80)];
        scrollView.backgroundColor = UIColorFromRGB(0x19181d);
        
        _filterChooserView = scrollView;
    }
    return _filterChooserView;
    
}
- (UIButton *)finishButton{
    if (!_finishButton) {
        UIButton* finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        
        [finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册默认_@3x"] forState:UIControlStateNormal];
        [finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册点击_@3x"] forState:UIControlStateSelected];
        
        [finishButton setFrame:CGRectMake(0, 0, 50, 50)];
        
        [finishButton addTarget:self action:@selector(finish:) forControlEvents:UIControlEventTouchUpInside];
        
        
        _finishButton = finishButton;
        
    }
    return _finishButton;
}

- (UIButton *)blackScreenButton{
    if (!_blackScreenButton) {
        UIButton* blackScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [blackScreenButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_黑屏默认_@3x"] forState:UIControlStateNormal];
        [blackScreenButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_黑屏点击_@3x"] forState:UIControlStateSelected];
        [blackScreenButton setFrame:CGRectMake(kWIDTH-44 - 4, (iPhone_X ?(72 - 44): (48 + 48)), 44, 44)];
        [blackScreenButton addTarget:self action:@selector(blackScreen) forControlEvents:UIControlEventTouchUpInside];
        _blackScreenButton = blackScreenButton;
    }
    return _blackScreenButton;
}

- (UIView *)blackScreenView{
    if (!_blackScreenView) {
        UIView* blackScreenView = [[UIView alloc] initWithFrame:self.view.bounds];
        blackScreenView.backgroundColor = [UIColor blackColor];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bright)];
        [blackScreenView addGestureRecognizer:tap];
        _blackScreenView = blackScreenView;
    }
    return _blackScreenView;
}

- (void) blackScreen{
    self.blackScreenView.hidden = NO;
    self.changeMusicButton.hidden = YES;
    [self.view bringSubviewToFront:self.blackScreenView];
}
- (void) bright{
    if (!self.blackScreenView.hidden) {
        self.blackScreenView.hidden = YES;
        self.changeMusicButton.hidden = NO;
    }
}
- (UIButton *)changeModeView{
    if (!_changeModeView) {
        self.changeModeView = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeModeView.frame = CGRectMake(0, 0, 44, 44);
        [_changeModeView setImage:[RDHelpClass getBundleImage:@"拍摄_切换拍摄比例默认_"] forState:UIControlStateNormal];
        [_changeModeView setImage:[RDHelpClass getBundleImagePNG:@"拍摄_切换拍摄比例点击_@2x"] forState:UIControlStateHighlighted];
        [_changeModeView addTarget:self action:@selector(changeMode) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeModeView;
}
- (UIView *)buttonBGView{
    if (!_buttonBGView) {
        UIView* buttonBGView = [[UIView alloc] init];
        buttonBGView.backgroundColor = UIColorFromRGB(0x19181d);
        if (iPhone4s) {
            buttonBGView.frame = CGRectMake(0, _isSquareTop ? 44 : kWIDTH, kWIDTH, 45 + kHEIGHT - (kWIDTH-4) - (isSquareTop?44:0));
        }else {
            buttonBGView.frame = CGRectMake(0, 44 + (_isSquareTop ? 0 : (iPhone_X ? (28 + kWIDTH) : kWIDTH)), kWIDTH, kHEIGHT - 44 - kWIDTH);
        }
        _buttonBGView = buttonBGView;
    }
    return _buttonBGView;
}
- (UIView *)VideoOrPhotoView{
    if (!_VideoOrPhotoView) {
        _VideoOrPhotoView = [[UIView alloc] init];
        _VideoOrPhotoView.frame = CGRectMake(0, 0, 170, 20);
        _VideoOrPhotoView.backgroundColor = [UIColor clearColor];
        
        UIView* pointMVView = [[UIView alloc] initWithFrame:CGRectMake(0, 7, 6, 6)];
        pointMVView.backgroundColor = UIColorFromRGB(0xf53333);
        pointMVView.layer.cornerRadius = 3;
        pointMVView.layer.masksToBounds = YES;
        pointMVView.tag = 399;
        [_VideoOrPhotoView addSubview:pointMVView];
        
        if (_MVRecordMinDuration == 0) {
            _MVRecordMinDuration = 3;//默认为3秒
        }
        if (_MVRecordMaxDuration == 0) {
            _MVRecordMaxDuration = 15;//默认为15秒
        }
        UIButton *MVBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        MVBtn.frame = CGRectMake(0, 0, 70, 20);
        MVBtn.backgroundColor = [UIColor clearColor];
        [MVBtn setTitle:[NSString stringWithFormat:@"MV-%@",[NSString stringWithFormat:RDLocalizedString(@"%.f秒", nil),_MVRecordMaxDuration]] forState:UIControlStateNormal];
        [MVBtn setTitleColor:UIColorFromRGB(0xf53333) forState:UIControlStateNormal];
        MVBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        MVBtn.tag = 300;
        [MVBtn addTarget:self action:@selector(changeRecordType:) forControlEvents:UIControlEventTouchUpInside];
        [_VideoOrPhotoView addSubview:MVBtn];
        
        UIView* pointVideoView = [[UIView alloc] initWithFrame:CGRectMake(70, 7, 6, 6)];
        pointVideoView.backgroundColor = UIColorFromRGB(0xf53333);
        pointVideoView.layer.cornerRadius = 3;
        pointVideoView.layer.masksToBounds = YES;
        pointVideoView.tag = 99;
        [_VideoOrPhotoView addSubview:pointVideoView];
        
        UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        videoBtn.frame = CGRectMake(70, 0, 50, 20);
        videoBtn.backgroundColor = [UIColor clearColor];
        [videoBtn setTitle:RDLocalizedString(@"视频", nil) forState:UIControlStateNormal];
        [videoBtn setTitleColor:UIColorFromRGB(0xf53333) forState:UIControlStateNormal];
        videoBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        videoBtn.tag = 100;
        [videoBtn addTarget:self action:@selector(changeRecordType:) forControlEvents:UIControlEventTouchUpInside];
        [_VideoOrPhotoView addSubview:videoBtn];
        
        UIView* pointPhotoView = [[UIView alloc] initWithFrame:CGRectMake(120, 7, 6, 6)];
        pointPhotoView.backgroundColor = UIColorFromRGB(0xf53333);
        pointPhotoView.layer.cornerRadius = 3;
        pointPhotoView.layer.masksToBounds = YES;
        pointPhotoView.tag = 199;
        pointPhotoView.alpha = 0.;
        [_VideoOrPhotoView addSubview:pointPhotoView];
        
        UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        photoBtn.frame = CGRectMake(120, 0, 60, 20);
        photoBtn.backgroundColor = [UIColor clearColor];
        [photoBtn setTitle:RDLocalizedString(@"照片", nil) forState:UIControlStateNormal];
        [photoBtn setTitleColor:UIColorFromRGB(0xf53333) forState:UIControlStateNormal];
        photoBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        photoBtn.tag = 200;
        [photoBtn addTarget:self action:@selector(changeRecordType:) forControlEvents:UIControlEventTouchUpInside];
        [_VideoOrPhotoView addSubview:photoBtn];
        if (_cameraMV && _cameraPhoto && !_cameraVideo) {
            pointPhotoView.frame = CGRectMake(70, 7, 6, 6);
            photoBtn.frame = CGRectMake(70, 0, 60, 20);
        }
    }
    return _VideoOrPhotoView;
}
- (void) setup{
    
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    [self.view insertSubview:self.screenView atIndex:0];
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];
    
    if (MODE) {
        [self.view addSubview:self.buttonBGView];
    }else {
        [_buttonBGView removeFromSuperview];
    }
    
    [self.view addSubview:self.VideoOrPhotoView];
    [self.view addSubview:self.setButton];
    [self.view addSubview:self.flashButton];
    [self.view addSubview:self.switchButton];
    [self.view addSubview:self.autoRecordButton];
    [self.view addSubview:self.beautifyButton];
    
    if (_cameraManager.position == AVCaptureDevicePositionFront) {
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭默认_@3x"] forState:UIControlStateNormal];
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭点击_@3x"] forState:UIControlStateHighlighted];
        _beautifyButton.selected = NO;
    }else {
        _beautifyButton.selected = YES;
    }
    [self beautify:_beautifyButton];
    [self.view addSubview:self.finish_Button];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.changeModeView];
    _changeModeView.hidden = YES;
    [self.view addSubview:self.timeTipImageView];
    [self.view addSubview:self.timeLabel];
    [self.view addSubview:self.label1];
    [self.view addSubview:self.filterItemsButton];
    [self.view addSubview:self.blackScreenButton];
    [self.view addSubview:self.finishButton];
    _finishButton.hidden = NO;
    [self.view addSubview:self.recordButton];
    if (!_deleteButton) {
        self.deleteButton = [[RDCustomButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [_deleteButton addTarget:self action:@selector(pressDeleteButton) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_deleteButton];
        _deleteButton.hidden = YES;
    }
    
//    [self.view addSubview:self.exposureSlider];
    
    if (MODE) {
        if (iPhone4s) {
            _filterItemsButton.center = CGPointMake(53, (kWIDTH + kHEIGHT + 48)/2 + 14);
            [_finishButton setCenter:CGPointMake(kWIDTH-53, (kWIDTH + kHEIGHT + 48)/2 + 14)];
            [_recordButton setCenter:CGPointMake(kWIDTH/2, (kWIDTH + kHEIGHT + 48)/2 + 14)];
            _deleteButton.center = CGPointMake(kWIDTH - 55, (kWIDTH + kHEIGHT + 48)/2 + 14);
        }else {
            _filterItemsButton.center = CGPointMake(53, (kWIDTH + kHEIGHT + 48)/2 + 24 + 18);
            [_finishButton setCenter:CGPointMake(kWIDTH-53, (kWIDTH + kHEIGHT + 48)/2 + 24 + 18)];
            [_recordButton setCenter:CGPointMake(kWIDTH/2, (kWIDTH + kHEIGHT + 48)/2 + 24 + 18)];
            _deleteButton.center = CGPointMake(kWIDTH - 55, (kWIDTH + kHEIGHT + 48)/2 + 24  + 18);
        }
    }else{
        [_finishButton setCenter:CGPointMake(kWIDTH-53, kHEIGHT - 45 - 18)];
        [_recordButton setCenter:CGPointMake(kWIDTH/2, kHEIGHT - 35 - 28 - (iPhone_X ? 60 : 0))];
        _deleteButton.center = CGPointMake(kWIDTH - 40, kHEIGHT - 45);
    }
    
    if (!_notSquareDeleteVideoView) {
        self.notSquareDeleteVideoView = [[UIView alloc] init];
        _notSquareDeleteVideoView.frame = CGRectMake(0, 0,50, 20);
        _notSquareDeleteVideoView.backgroundColor = [UIColor clearColor];
        _notSquareDeleteVideoView.center = CGPointMake(kWIDTH*3./4. - 15, kHEIGHT - 45);
        
        UITapGestureRecognizer *tapDeleteGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressDeleteButton)];
        [_notSquareDeleteVideoView addGestureRecognizer:tapDeleteGesture];//
        [self.view addSubview:_notSquareDeleteVideoView];
    }
    
    [self.view addSubview:self.aSplitView];
    [self.view addSubview:self.filtergroundView];
    
    UIView *span = [[UIView alloc] initWithFrame:CGRectMake(10, 35, kHEIGHT, 1)];
    span.backgroundColor = SCREEN_BACKGROUND_COLOR;
    [_filtergroundView addSubview:span];
    
    if (!_filterChooserView) {
        __weak typeof(self) weakSelf = self;
        
        [self.filterChooserView setChooserBlock:^( NSInteger idx,BOOL selectFilter) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(selectFilter){
                    filter_index = (int)idx;
                    [weakSelf.cameraManager setFilterAtIndex:idx];
                }
            });
        }];
        if (_filters.count > 0) {
            [_filterChooserView addFiltersToChooser:self.filters];
        }else {
            [self getFilters];
        }
    }
    [self.view addSubview:self.filterChooserView];
    
    self.faceuScrollview.hidden = YES;
    self.filterChooserView.hidden = YES;
    
    [self.view addSubview:self.hideFiltersButton];
    
    self.hideFiltersButton.hidden = YES;
    
    self.blackScreenView.hidden = YES;
    self.filtergroundView.hidden = YES;
    self.lastOrientation = UIDeviceOrientationPortrait;
    
    self.label1.hidden = YES;
    
    self.timeTipImageView.hidden = YES;
    
    self.timeLabel.hidden = YES;
    
    self.blackScreenButton.hidden = YES;
    
    if (!_longSizeSplitTimeLabel) {
        self.longSizeSplitTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 44+5, 40, 20)];
        _longSizeSplitTimeLabel.backgroundColor = [UIColor colorWithRed:28./255. green:30./255. blue:40./255. alpha:1.0];
        _longSizeSplitTimeLabel.layer.cornerRadius = 2;
        _longSizeSplitTimeLabel.layer.masksToBounds = YES;
        _longSizeSplitTimeLabel.text = @"00.00";
        _longSizeSplitTimeLabel.layer.borderWidth = 1;
        _longSizeSplitTimeLabel.layer.borderColor = [UIColor colorWithRed:65./255. green:66./255. blue:69./255. alpha:1.0].CGColor;
        _longSizeSplitTimeLabel.hidden = YES;
        _longSizeSplitTimeLabel.textAlignment = NSTextAlignmentCenter;
        _longSizeSplitTimeLabel.textColor = [UIColor whiteColor];
        [_longSizeSplitTimeLabel setFont:[UIFont systemFontOfSize:12]];
        [self.view addSubview:_longSizeSplitTimeLabel];
        
    }
    
    if (!_longSizeSplitCountLabel) {
        self.longSizeSplitCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _longSizeSplitCountLabel.center = CGPointMake(140, (iPhone_X ? 88 : 64));
        _longSizeSplitCountLabel.text = @"0";
        _longSizeSplitCountLabel.hidden = YES;
        _longSizeSplitCountLabel.textAlignment = NSTextAlignmentCenter;
        _longSizeSplitCountLabel.textColor = [UIColor whiteColor];
        
        [self.view addSubview:_longSizeSplitCountLabel];
        [self.view bringSubviewToFront:_longSizeSplitCountLabel];
    }
    
    [_progressBar removeFromSuperview];
    if (!MODE) {
        self.progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(0, kHEIGHT-bottomHeight - 54  - 5, kWIDTH, 5)];
    }else{
        self.progressBar = [[ProgressBar alloc] initWithFrame: CGRectMake(0, (iPhone_X ? 72 : 44), kWIDTH, 5)];        
    }
    
    [self.view insertSubview:_progressBar belowSubview:_filtergroundView];
    [_progressBar startShining];
    
    float x_MV = _MVRecordMinDuration / _MVRecordMaxDuration * _progressBar.frame.size.width;
    CGRect MVMinDurationViewFrame = _progressBar.MVMinDurationView.frame;
    MVMinDurationViewFrame.origin.x = x_MV;
    _progressBar.MVMinDurationView.frame = MVMinDurationViewFrame;
    if (MODE) {
        _progressBar.alpha = 1.0;
        
        if (_isSquareTop) {
            _progressBar.frame = CGRectMake(0, 44 + 44, kWIDTH, 5);
            _timeTipImageView.frame = CGRectMake(10, 44 + 44, 105, 40);
            _timeLabel.frame = CGRectMake(44, 44 + 44, 100, 40);
        }
        _deleteButton.hidden = NO;
        if (_MAX_VIDEO_DUR_1 > 0 && _minRecordDuration > 0) {
            float x_video = _minRecordDuration / _MAX_VIDEO_DUR_1 * _progressBar.frame.size.width;
            
            CGRect videoMinDurationViewFrame = _progressBar.squareMinDurationView.frame;
            videoMinDurationViewFrame.origin.x = x_video;
            _progressBar.squareMinDurationView.frame = videoMinDurationViewFrame;
        }
    }else{
        _progressBar.alpha = 0.8;
        if (_MAX_VIDEO_DUR_2 > 0 && _minRecordDuration > 0) {
            float x_video = _minRecordDuration / _MAX_VIDEO_DUR_2 * _progressBar.frame.size.width;
            
            CGRect videoMinDurationViewFrame = _progressBar.notSquareMinDurationView.frame;
            videoMinDurationViewFrame.origin.x = x_video;
            _progressBar.notSquareMinDurationView.frame = videoMinDurationViewFrame;
        }
    }
    
    if (_faceU) {
        [_segmentedControl removeFromSuperview];
        _segmentedControl = nil;
        [self.filtergroundView addSubview:self.segmentedControl];
    }else {
        _segmentedControl.hidden = YES;
    }
    
    if (currentRecordType != RecordTypeMVVideo && ((MODE && _MAX_VIDEO_DUR_1 == 0) || (!MODE && _MAX_VIDEO_DUR_2 == 0))) {
        _progressBar.hidden = YES;
    }
    
    [self.view addSubview:self.blackScreenView];
}

- (UIView *)aSplitView{
    if (!_aSplitView) {
        _aSplitView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - kWIDTH*0.95)/2.0, 0, kWIDTH*0.95, 1)];
        _aSplitView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.3];
    }
    return _aSplitView;
}
- (void) videoOrPhoto: (UIButton *) button{
    if (button.selected) {
        button.selected = NO;
        NSLog(@"NO");
        button.backgroundColor = [UIColor whiteColor];
    }
    else {
        button.selected = YES;
        NSLog(@"YES");
        button.backgroundColor = [UIColor redColor];
    }
}

- (void) hideVideoAndPhotoLabel:(BOOL)isHideAll{
    UIButton* btn0 = (UIButton*)[_VideoOrPhotoView viewWithTag:300];
    UIButton* btn1 = (UIButton*)[_VideoOrPhotoView viewWithTag:100];
    UIButton* btn2 = (UIButton*)[_VideoOrPhotoView viewWithTag:200];
    UIView* point0 = (UIView*)[_VideoOrPhotoView viewWithTag:399];
    UIView* point1 = (UIView*)[_VideoOrPhotoView viewWithTag:99];
    UIView* point2 = (UIView*)[_VideoOrPhotoView viewWithTag:199];
    
    if (!_cameraMV) {
        btn0.hidden = YES;
        point0.hidden = YES;
    }else {
        btn0.hidden = NO;
        point0.hidden = NO;
    }
    if (!_cameraVideo) {
        btn1.hidden = YES;
        point1.hidden = YES;
    }else {
        btn1.hidden = NO;
        point1.hidden = NO;
    }
    if (!_cameraPhoto) {
        btn2.hidden = YES;
        point2.hidden = YES;
    }else {
        btn2.hidden = NO;
        point2.hidden = NO;
    }
    if (recordTypeCounts == 1 || isHideAll) {
        btn0.hidden = YES;
        point0.hidden = YES;
        btn1.hidden = YES;
        point1.hidden = YES;
        btn2.hidden = YES;
        point2.hidden = YES;
    }
}

- (void)changeRecordType:(UIButton *)sender {
    if (sender.tag == 300) {
//        {
//            //emmet 20171019 更新选择MV时录制的不是正方形的视频的bug
//            MODE = NO;
//            MODE = (_recordsizetype == RecordSizeTypeSquare) ? NO : YES;
//            [self changeMode];
//        }
        [self changeVideoOrPhoto:RecordTypeMVVideo];
        
    }
    else if (sender.tag == 100) {
//        {
//            //emmet 20171019 更新选择MV时录制的不是正方形的视频的bug
//            MODE = (_recordsizetype == RecordSizeTypeSquare) ? NO : YES;
//            [self changeMode];
//        }
        [self changeVideoOrPhoto:RecordTypeVideo];
    }
    else if (sender.tag == 200) {
//        {
//            //emmet 20171019 更新选择MV时录制的不是正方形的视频的bug
//            MODE = (_recordsizetype == RecordSizeTypeSquare) ? NO : YES;
//            [self changeMode];
//        }
        [self changeVideoOrPhoto:RecordTypePhoto];
    }
}

- (void) changeVideoOrPhoto : (int) direction{ // 0 照片 1视频 2短视频MV
    currentRecordType = direction;
    if (currentRecordType != RecordTypeMVVideo && ((MODE && _MAX_VIDEO_DUR_1 == 0) || (!MODE && _MAX_VIDEO_DUR_2 == 0))) {
        _progressBar.hidden = YES;
    }else if(currentRecordType == RecordTypeMVVideo){
        _progressBar.hidden = NO;
        _progressBar.MVMinDurationView.hidden = NO;
    }
    if(direction != RecordTypePhoto){
        if(_enableUseMusic){
            _changeMusicButton.hidden = NO;
        }else{
            _changeMusicButton.hidden = YES;
        }
        
    }
    else{
        _changeMusicButton.hidden = YES;
    }
    if (_videoArray.count > 0 && direction == RecordTypePhoto) {
        return;
    }
    if (direction == RecordTypeMVVideo) {
        if (!MODE && CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2 + 70, kHEIGHT-(bottomHeight - 35)))) {
            return;
        }
        if (MODE && CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2 + 70, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65))) {
            return;
        }
        [UIView animateWithDuration:0.3 animations:^{
            if (MODE) {
                _VideoOrPhotoView.center = CGPointMake(kWIDTH/2 + 70, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65);
                
            }else{
                _VideoOrPhotoView.center = CGPointMake(kWIDTH/2 + 70, kHEIGHT - bottomHeight + 10 + 25);
                
            }
            UIButton* btn0 = (UIButton*)[_VideoOrPhotoView viewWithTag:300];
            UIButton* btn1 = (UIButton*)[_VideoOrPhotoView viewWithTag:100];
            UIButton* btn2 = (UIButton*)[_VideoOrPhotoView viewWithTag:200];
            UIView* point0 = (UIView*)[_VideoOrPhotoView viewWithTag:399];
            UIView* point1 = (UIView*)[_VideoOrPhotoView viewWithTag:99];
            UIView* point2 = (UIView*)[_VideoOrPhotoView viewWithTag:199];
            
            [btn0 setTitleColor:UIColorFromRGB(0xf53333) forState:UIControlStateNormal];
            point0.alpha = 1.;
            [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            point1.alpha = 0.;
            [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            point2.alpha = 0.;
            
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
            
        }];
        //视频态
        videoOrPhoto = NO;
        
        if (self.lastOrientation != UIDeviceOrientationPortrait) {
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            _notSquareDeleteVideoView.hidden = NO;
        }
    }
    
    else if (direction == RecordTypeVideo) {
        if (!MODE && CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2, kHEIGHT- (bottomHeight - 35)))) {
            return;
        }
        if (MODE && CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65))) {
            return;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            if (MODE) {
                _VideoOrPhotoView.center = CGPointMake(kWIDTH/2, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65);
                
            }else{
                _VideoOrPhotoView.center = CGPointMake(kWIDTH/2, kHEIGHT - bottomHeight + 10 + 25);
            }
            UIButton* btn0 = (UIButton*)[_VideoOrPhotoView viewWithTag:300];
            UIButton* btn1 = (UIButton*)[_VideoOrPhotoView viewWithTag:100];
            UIButton* btn2 = (UIButton*)[_VideoOrPhotoView viewWithTag:200];
            UIView* point0 = (UIView*)[_VideoOrPhotoView viewWithTag:399];
            UIView* point1 = (UIView*)[_VideoOrPhotoView viewWithTag:99];
            UIView* point2 = (UIView*)[_VideoOrPhotoView viewWithTag:199];
            
            [btn0 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            point0.alpha = 0.;
            [btn1 setTitleColor:UIColorFromRGB(0xf53333) forState:UIControlStateNormal];
            point1.alpha = 1.;
            [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            point2.alpha = 0.;
            
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
            
        }];
        
        //视频态
        videoOrPhoto = NO;
        
        if (self.lastOrientation != UIDeviceOrientationPortrait) {
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            _notSquareDeleteVideoView.hidden = NO;
        }
    }
    
    else if (direction == RecordTypePhoto){
        if (!MODE) {
            if (_cameraMV && _cameraPhoto && !_cameraVideo && CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2, kHEIGHT-(bottomHeight - 35)))) {
                return;
            }else if (CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2 - 50, kHEIGHT-(bottomHeight - 35)))) {
                return;
            }
        }
        if (MODE) {
            if (_cameraMV && _cameraPhoto && !_cameraVideo && CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65))) {
                return;
            }else if (CGPointEqualToPoint(_VideoOrPhotoView.center, CGPointMake(kWIDTH/2 - 50, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65))) {
                return;
            }
        }
        
        if (isRecording == 1) {
            return;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            if (_cameraMV && _cameraPhoto && !_cameraVideo) {
                if (MODE) {
                    _VideoOrPhotoView.center = CGPointMake(kWIDTH/2, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65);
                    
                }else{
                    _VideoOrPhotoView.center = CGPointMake(kWIDTH/2, kHEIGHT - bottomHeight + 10 + 25);
                }
            }else {
                if (MODE) {
                    _VideoOrPhotoView.center = CGPointMake(kWIDTH/2 - 50, (kWIDTH + kHEIGHT + 48)/2 + 24 - 65);
                    
                }else{
                    _VideoOrPhotoView.center = CGPointMake(kWIDTH/2 - 50, kHEIGHT - bottomHeight + 10 + 25);
                }
            }
            
            UIButton* btn0 = (UIButton*)[_VideoOrPhotoView viewWithTag:300];
            UIButton* btn1 = (UIButton*)[_VideoOrPhotoView viewWithTag:100];
            UIButton* btn2 = (UIButton*)[_VideoOrPhotoView viewWithTag:200];
            UIView* point0 = (UIView*)[_VideoOrPhotoView viewWithTag:399];
            UIView* point1 = (UIView*)[_VideoOrPhotoView viewWithTag:99];
            UIView* point2 = (UIView*)[_VideoOrPhotoView viewWithTag:199];
            
            [btn0 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            point0.alpha = 0.;
            [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            point1.alpha = 0.;
            [btn2 setTitleColor:UIColorFromRGB(0xf53333) forState:UIControlStateNormal];
            point2.alpha = 1.;
            
            if (self.lastOrientation == UIDeviceOrientationPortrait) {
                [self.recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照_"] forState:UIControlStateNormal];
            }else if (self.lastOrientation == UIDeviceOrientationLandscapeLeft){
                [self.recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照左"] forState:UIControlStateNormal];
                
            }else if(self.lastOrientation == UIDeviceOrientationLandscapeRight){
                [self.recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照右"] forState:UIControlStateNormal];
            }
        }];
        //照片态
        videoOrPhoto = YES;
        
        if (self.lastOrientation == UIDeviceOrientationPortrait) {
            _deleteButton.hidden = YES;
        }else{
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            _notSquareDeleteVideoView.hidden = YES;
        }
    }
}

- (void)sendTagVideoOrPhoto:(NSInteger)type{
    if (_videoArray.count > 0 || _currentVideoDur >0){
        return;
    }
    if (_cameraMV && _cameraVideo && _cameraPhoto) {
        if (type == 0) {//左
            if (currentRecordType > RecordTypePhoto) {
                [self changeVideoOrPhoto:--currentRecordType];
            }
        }else {//右
            if (currentRecordType < RecordTypeMVVideo) {
                [self changeVideoOrPhoto:++currentRecordType];
            }
        }
    }else if (_cameraMV && _cameraVideo) {
        if (type == 0) {//左
            [self changeVideoOrPhoto:1];
            currentRecordType = RecordTypeVideo;
        }else {//右
            [self changeVideoOrPhoto:2];
            currentRecordType = RecordTypeMVVideo;
        }
    }else if (_cameraMV && _cameraPhoto) {
        if (type == 0) {
            [self changeVideoOrPhoto:0];
            currentRecordType = RecordTypePhoto;
        }else {
            [self changeVideoOrPhoto:2];
            currentRecordType = RecordTypeMVVideo;
        }
    }else if (_cameraVideo && _cameraPhoto) {
        if (type == 0) {
            [self changeVideoOrPhoto:0];
            currentRecordType = RecordTypePhoto;
        }else {
            [self changeVideoOrPhoto:1];
            currentRecordType = RecordTypeVideo;
        }
    }
    if (currentRecordType == RecordTypeMVVideo) {
        _progressBar.MVMinDurationView.hidden = NO;
        _progressBar.squareMinDurationView.hidden = YES;
        _progressBar.notSquareMinDurationView.hidden = YES;
    }
    else if (MODE && _MAX_VIDEO_DUR_1 > 0 && _minRecordDuration > 0) {
        _progressBar.MVMinDurationView.hidden = YES;
        _progressBar.squareMinDurationView.hidden = NO;
        _progressBar.notSquareMinDurationView.hidden = YES;
    }
    else if (!MODE && _MAX_VIDEO_DUR_2 > 0 && _minRecordDuration > 0) {
        _progressBar.MVMinDurationView.hidden = YES;
        _progressBar.squareMinDurationView.hidden = YES;
        _progressBar.notSquareMinDurationView.hidden = NO;
    }else {
        _progressBar.MVMinDurationView.hidden = YES;
        _progressBar.squareMinDurationView.hidden = YES;
        _progressBar.notSquareMinDurationView.hidden = YES;
    }
}


- (void) changeMode{
    isRecording = -1;
    
    if (_videoArray.count > 0) {
        return;
    }
    NSLog(@"%s",__func__);
    MODE = !MODE;
    videoOrPhoto = NO;
    
    if(CGSizeEqualToSize(_recordSize, CGSizeZero)){
        _recordSize = [RDCameraManager defaultMatchSize];
    }
    
    self.cameraManager.cameraSize = _recordSize;
    self.cameraManager.outputSize = _recordSize;
    CGRect frame;
//    if (MODE) {
//        frame = CGRectMake(44 + (_isSquareTop ? 45 : 0), 0, kWIDTH, kWIDTH);
//    }else {
        frame = CGRectMake(0, 0, kHEIGHT, kWIDTH);
//    }
    [self.cameraManager changeMode:MODE cameraScreenFrame:frame];
    
    [self setup];
    
    if (!_filterChooserView.hidden) {
        [self showFilters:self.filterItemsButton];
    }
    
    [self orientUp];
    
    if (MODE) {
        float y = iPhone_X ? 35 : 0;
        _screenView.transform = CGAffineTransformIdentity;
        _screenView.frame = CGRectMake(0, 0, MAX(kHEIGHT - y, kWIDTH), MIN(kHEIGHT - y, kWIDTH));
        _screenView.center = CGPointMake(_screenView.frame.size.height / 2.0, _screenView.frame.size.width / 2.0);
        _screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
        _screenView.frame = CGRectMake(0, y, _screenView.frame.size.width, _screenView.frame.size.height);
        [_cameraManager setVideoViewFrame:CGRectMake(0, 0, kHEIGHT - y, kWIDTH)];
        _bottomView.alpha = 0.0;
        self.lastOrientation = UIDeviceOrientationPortrait;
    }else{
        _screenView.transform = CGAffineTransformIdentity;
        _screenView.frame = CGRectMake(0, 0, MAX(kHEIGHT, kWIDTH),MIN(kHEIGHT, kWIDTH));
        _screenView.center = CGPointMake( MIN(kHEIGHT, kWIDTH)/2,MAX(kHEIGHT, kWIDTH)/2);
        _screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
        [_cameraManager setVideoViewFrame:CGRectMake(0, 0, kHEIGHT, kWIDTH)];
        _bottomView.alpha = 0.4;
    }
    if (_recordsizetype != RecordSizeTypeMixed) {
        self.changeModeView.hidden = YES;
    }
    
    if (!_cameraMV && !_cameraVideo && _cameraPhoto) {
        _recordtype = RecordTypePhoto;
        _enableUseMusic = NO;
    }else if (_cameraMV && !_cameraVideo) {
        _recordtype = RecordTypeMVVideo;
    }
    
    if (_recordtype == RecordTypePhoto) {//照片
        if (_cameraPhoto) {
            [self changeVideoOrPhoto:RecordTypePhoto];
            currentRecordType = RecordTypePhoto;
        }
        else if (_cameraMV) {
            [self changeVideoOrPhoto:RecordTypeMVVideo];
            currentRecordType = RecordTypeMVVideo;
        }
        else if (_cameraVideo) {
            [self changeVideoOrPhoto:RecordTypeVideo];
            currentRecordType = RecordTypeVideo;
        }
    }else if (_recordtype == RecordTypeMVVideo) {//短视频MV
        if (_cameraMV) {
            [self changeVideoOrPhoto:RecordTypeMVVideo];
            currentRecordType = RecordTypeMVVideo;
        }
        else if (_cameraVideo) {
            [self changeVideoOrPhoto:RecordTypeVideo];
            currentRecordType = RecordTypeVideo;
        }
        else if (_cameraPhoto) {
            [self changeVideoOrPhoto:RecordTypePhoto];
            currentRecordType = RecordTypePhoto;
        }
    }else {//视频
        
        [self changeVideoOrPhoto:currentRecordType];
//        if (_cameraVideo) {
//            [self changeVideoOrPhoto:RecordTypeVideo];
//            currentRecordType = RecordTypeVideo;
//        }
//        else if (_cameraMV) {
//            [self changeVideoOrPhoto:RecordTypeMVVideo];
//            currentRecordType = RecordTypeMVVideo;
//        }
//        else if (_cameraPhoto) {
//            [self changeVideoOrPhoto:RecordTypePhoto];
//            currentRecordType = RecordTypePhoto;
//        }
    }
    if (currentRecordType == RecordTypeMVVideo) {
        _progressBar.hidden = NO;
        _progressBar.MVMinDurationView.hidden = NO;
    }
    else if (MODE && _MAX_VIDEO_DUR_1 > 0) {
        _progressBar.hidden = NO;
        _progressBar.squareMinDurationView.hidden = NO;
    }
    else if (!MODE && _MAX_VIDEO_DUR_2 > 0) {
        _progressBar.hidden = NO;
        _progressBar.notSquareMinDurationView.hidden = NO;
    }else{
        _progressBar.hidden = YES;
    }
    [self hideVideoAndPhotoLabel:NO];
    if(_enableUseMusic){
        [self.changeMusicButton removeFromSuperview];
        [self.view addSubview:self.changeMusicButton];
        
        if(_musicInfo){
            [self changeMusicWithMusicInfo:_musicInfo];
        }
    }
}
- (void) pressDeleteButton{
    NSLog(@"%s %lu",__func__,(unsigned long)_videoArray.count);
    if (_videoArray.count == 0 ) {
        return;
    }
    if (!MODE) {
        
        if (currentRecordType != 0 && _MAX_VIDEO_DUR_2 == 0) {
            goto A4;
        }
        
        if (_deleteButton.style == DeleteButtonStyleNormal) {
            [_progressBar setLastProgressToStyle:ProgressBarProgressStyleDelete];
            [_deleteButton setButtonStyle:DeleteButtonStyleDelete];
        }else if(_deleteButton.style == DeleteButtonStyleDelete){
        A4:
            [_progressBar deleteLastProgress];
            
            
            
            _totalVideoDur -= [[_timeArray lastObject] floatValue];
            CGFloat all = _totalVideoDur<=0?0:_totalVideoDur;
            
            _longSizeSplitTimeLabel.text = [NSString stringWithFormat:@"%05.2lf",all];
            
            int all_ = (int)(all*100);
            _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
            
            
            NSURL* videoFileURL = [_videoArray lastObject];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:filePath]) {
                    NSError *error = nil;
                    [fileManager removeItemAtPath:filePath error:&error];
                    if (!error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_videoArray.count == 0 ) {
                                [self hideVideoAndPhotoLabel:NO];
                            }
                        });
                        NSLog(@"删除成功");
                    }else{
                        NSLog(@"删除失败");
                    }
                }
            });
            
            [_timeArray removeLastObject];
            [_videoArray removeLastObject];
            [_videoDurationArray removeLastObject];
            _currentVideoDur = 0;
            _longSizeSplitCountLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)_timeArray.count];
            [self.view bringSubviewToFront:_longSizeSplitCountLabel];
            NSLog(@"现在时间段 %@",_timeArray);
            NSLog(@"现在地址 %@",_videoArray);
            [_cameraManager refreshRecordTime];
            if (_videoArray.count > 0) {
                [_deleteButton setButtonStyle:DeleteButtonStyleNormal];
            }else{
                
                
                isFirstRecord = NO;
                
                self.changeModeView.enabled = YES;
                self.cameraManager.recordStatus = VideoRecordStatusUnknown;
                [_deleteButton setButtonStyle:DeleteButtonStyleDisable];
                _longSizeSplitTimeLabel.hidden = YES;
                _longSizeSplitCountLabel.hidden = YES;
                self.autoRecordButton.enabled = YES;
                _timeLabel.hidden = YES;
                _timeTipImageView.hidden = YES;
                
                [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册默认_@3x"] forState:UIControlStateNormal];
                [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册点击_@3x"] forState:UIControlStateSelected];
                _setButton.enabled = YES;
                if (_hiddenPhotoLib) {
                    _finishButton.hidden = YES;
                }
                [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图默认_@3x"] forState:UIControlStateNormal];
                [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图点击_@3x"] forState:UIControlStateHighlighted];
                
                isRecording = -1;
            }
        }
    }
    
    if (MODE) {
        
        if (currentRecordType != RecordTypeMVVideo && _MAX_VIDEO_DUR_1 == 0) {
            goto A3;
        }
        
        
        if (_deleteButton.style == DeleteButtonStyleNormal) {
            [_progressBar setLastProgressToStyle:ProgressBarProgressStyleDelete];
            [_deleteButton setButtonStyle:DeleteButtonStyleDelete];
        }else if(_deleteButton.style == DeleteButtonStyleDelete){
        A3:
            [_progressBar deleteLastProgress];
            
            _totalVideoDur -= [[_timeArray lastObject] floatValue];
            CGFloat all = _totalVideoDur<=0?0:_totalVideoDur;
            
            int all_ = (int)(all*100);
            _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
            
            _currentVideoDur = 0;
            NSURL* videoFileURL = [_videoArray lastObject];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:filePath]) {
                    NSError *error = nil;
                    [fileManager removeItemAtPath:filePath error:&error];
                    if (!error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_videoArray.count == 0 ) {
                                [self hideVideoAndPhotoLabel:NO];
                            }
                        });
                        NSLog(@"删除成功");
                    }else{
                        NSLog(@"删除失败");
                    }
                }
            });
            [_timeArray removeLastObject];
            [_videoArray removeLastObject];
            [_videoDurationArray removeLastObject];
            
            NSLog(@"现在时间段 %@",_timeArray);
            NSLog(@"现在地址 %@",_videoArray);
            [_cameraManager refreshRecordTime];
            if (_videoArray.count > 0) {
                [_deleteButton setButtonStyle:DeleteButtonStyleNormal];
            }else{
                isFirstRecord = NO;
                _totalVideoDur = 0;
                CGFloat all = _totalVideoDur<=0?0:_totalVideoDur;
                int all_ = (int)(all*100);
                _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
                
                self.changeModeView.enabled = YES;
                self.cameraManager.recordStatus = VideoRecordStatusUnknown;
                self.autoRecordButton.enabled = YES;
                
                [_deleteButton setButtonStyle:DeleteButtonStyleDisable];
                
                
                [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册默认_@3x"] forState:UIControlStateNormal];
                [_finishButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄相册点击_@3x"] forState:UIControlStateSelected];
                _setButton.enabled = YES;
                if (_hiddenPhotoLib) {
                    _finishButton.hidden = YES;
                }
                [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图默认_@3x"] forState:UIControlStateNormal];
                [_filterItemsButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄人脸贴图点击_@3x"] forState:UIControlStateHighlighted];
                
                isRecording = -1;
                
            }
        }
    }
}

#pragma mark - 美肤效果叠加
- (void) beautify: (UIButton *) button{
    if (!button.selected) {
        button.selected = YES;
        
        if (_faceUURLString && _faceU) {
            RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
            if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUBeautyParamChanged:)]) {
                [nv.rdVeUiSdkDelegate faceUBeautyParamChanged:beautyParams];
            }
        }else {
            self.cameraManager.beautifyState = BeautifyStateSeleted;
        }
    }else{
        button.selected = NO;
        
        if (_faceUURLString && _faceU) {
            RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
            if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(faceUBeautyParamChanged:)]) {
                RDFaceUBeautyParams *params = [RDFaceUBeautyParams new];
                params.colorLevel = 0.0;
                params.blurLevel = 0;
                params.cheekThinning = 0.0;
                params.eyeEnlarging = 0.0;
                [nv.rdVeUiSdkDelegate faceUBeautyParamChanged:params];
            }
        }else {
            self.cameraManager.beautifyState = BeautifyStateNormal;
        }
    }
    
    if (_segmentedControl.selectedSegmentIndex == 1 ) {
        [self removeBViews];
        [self changes:_segmentedControl];
    }
}

static int timeq;
- (void)addFinishBlock:(RDRecordCallbackBlock)block{
    finishBlock = [block copy];
}
#pragma mark 读取视频文件大小
- (long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

- (void)mergeAndExportVideosAtFileURLs:(NSArray *)fileURLArray
{
    NSLog(@"开始合并");
    if (fileURLArray.count == 0) {
        return;
    }
    
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack* videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime totalDuration = kCMTimeZero;
    NSInteger index = 0;
    for (int i = 0 ;i<fileURLArray.count;i++) {
        if(![fileURLArray[i] isKindOfClass:[NSURL class]]){
            continue;
        }
        NSURL* url  = fileURLArray[i];
        AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
        if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
            AVAssetTrack* assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(asset.duration, CMTimeMake(0, _fps))) ofTrack:assetVideoTrack atTime:totalDuration error:nil];
            if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
                AVAssetTrack* assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(asset.duration, CMTimeMake(0, _fps))) ofTrack:assetAudioTrack atTime:totalDuration error:nil];
            }else{
                ;
                AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[RDHelpClass getBundle] pathForResource:@"27_b" ofType:@"m4a"]] options:nil];
                AVAssetTrack* assetAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(asset.duration, CMTimeMake(0, _fps))) ofTrack:assetAudioTrack atTime:totalDuration error:nil];
                NSLog(@"没有声音：%ld",(long)index);
            }
            totalDuration = CMTimeAdd(totalDuration, CMTimeSubtract(asset.duration, CMTimeMake(0, _fps)));
            NSLog(@"next:%lf",CMTimeGetSeconds(totalDuration));
            
        }else{
            NSLog(@"没有录制成功");
        }
        index ++;
    }
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableDraft)
    {
        NSString *path = _videoPath;
        BOOL have = NO;
        NSInteger exportPathIndex = 0;
        do {
            if (exportPathIndex > 0) {
                _videoPath = [[path.stringByDeletingPathExtension stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)exportPathIndex]] stringByAppendingPathExtension:path.pathExtension];
            }
            exportPathIndex ++;
            have = [[NSFileManager defaultManager] fileExistsAtPath:_videoPath];
        } while (have);
    }else {
        unlink([_videoPath UTF8String]);
    }
    NSURL* exportURL  = [NSURL fileURLWithPath:_videoPath];
    
    
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.outputURL = exportURL;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if(exporter.status ==AVAssetExportSessionStatusWaiting){
                NSLog(@"等待中");
            }else if(exporter.status == AVAssetExportSessionStatusExporting){
                NSLog(@"正在导出");
            }else if(exporter.status == AVAssetExportSessionStatusCompleted){
                NSLog(@"合并完成");
                AVURLAsset *asset = [AVURLAsset assetWithURL:exportURL];
                if(asset){
                    [self exportSuc];
                }else{
                    NSLog(@"文件写入失败");
                }
            }else if(exporter.status == AVAssetExportSessionStatusFailed){
                
                NSLog(@"合并失败");
            }else if(exporter.status == AVAssetExportSessionStatusCancelled){
                NSLog(@"合并取消");
            }
            
            [hub hideAnimated:YES];
            [hub removeFromSuperViewOnHide];
            hub = nil;
        });
    }];
}

- (void)exportSuc{
    if (_more) { // solaren  保存视频 清空数据 进行下一次录制
        
        self.view.userInteractionEnabled = YES;
        
        [self deleteAllVideo];
        UISaveVideoAtPathToSavedPhotosAlbum(_videoPath, self, nil, nil);
        
        [_timeArray removeAllObjects];
        _timeLabel.text = @"00:00:00";
        _longSizeSplitTimeLabel.text = [NSString stringWithFormat:@"%05.2d",0];
        _longSizeSplitCountLabel.text = @"0";
        [self.view bringSubviewToFront:_longSizeSplitCountLabel];
        _totalVideoDur = 0.0;
        [_progressBar deleteAllProgress];
        
    }else{
        if(finishBlock){
            finishBlock(_videoPath,currentRecordType,_musicInfo);
            if(_push){
                [self.navigationController popViewControllerAnimated:YES];
            }else{
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }else{
            NSURL *exportURL = [NSURL fileURLWithPath:_videoPath];
            [self enterEditVideoViewController:exportURL];
        }
        [self.cameraManager stopCamera];
        [self deleteItems];
    }
}
- (void) updateProgress: (AVAssetExportSession *) exporter{
    if (exporter.status == AVAssetExportSessionStatusExporting) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"导出进度 %.2f",exporter.progress);
            hub.progress = exporter.progress;
            
        });
    }
    if (exporter.status == AVAssetExportSessionStatusCompleted) {
        [hub hideAnimated:YES];
        [hub removeFromSuperViewOnHide];
        hub = nil;
        return;
    }
    
    NSArray *modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, UITrackingRunLoopMode, nil];
    
    [self performSelector:@selector(updateProgress:)
               withObject:exporter
               afterDelay:0.5
                  inModes:modes];
    
}
- (void)deleteAllVideo
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *folderPath = [path stringByAppendingPathComponent:@"videos"];
    [[NSFileManager defaultManager] removeItemAtPath:folderPath error:nil];
    [_timeArray removeLastObject];
    [_videoArray removeAllObjects];
    [_videoDurationArray removeAllObjects];
    [_cameraManager refreshRecordTime];
    
}

- (void)enterEditVideoViewController:(NSURL *)url{
    NSMutableArray *fileList = [NSMutableArray new];
    NSString *finishPath = [[[_videoPath stringByDeletingPathExtension] stringByAppendingString:@"Finish."] stringByAppendingString:[_videoPath pathExtension]];
    
    unlink([finishPath UTF8String]);
    
    [[NSFileManager defaultManager] moveItemAtPath:_videoPath toPath:finishPath error:nil];
    
    NSURL* exportURL  = [NSURL fileURLWithPath:finishPath];
    
    
    
    
    RDFile  *file = [RDFile new];
    file.contentURL = exportURL;
    file.fileType = kFILEVIDEO;
    file.isReverse = NO;
    file.videoTimeRange = kCMTimeRangeZero;
    file.videoDurationTime =[AVURLAsset assetWithURL:file.contentURL].duration;
    file.reverseVideoTimeRange = kCMTimeRangeZero;
    file.isVerticalMirror = NO;
    file.isHorizontalMirror = NO;
    file.videoVolume = 1.0;
    file.speed = 1;
    file.speedIndex = 2;
    file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    file.crop = CGRectMake(0, 0, 1, 1);
    [fileList addObject:file];
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableWizard){
        
        RDNextEditVideoViewController *edit = [[RDNextEditVideoViewController alloc] init];
        edit.fileList = fileList;
        edit.musicURL = _musicInfo.url;
        edit.musicVolume = _musicInfo.volume;
        edit.musicTimeRange = _musicInfo.clipTimeRange;
        [self.navigationController pushViewController:edit animated:YES];
    }else{
        
        RDEditVideoViewController *edit = [[RDEditVideoViewController alloc] init];
        edit.isVague = YES;
        edit.fileList = fileList;
        edit.musicURL = _musicInfo.url;
        edit.musicVolume = _musicInfo.volume;
        edit.musicTimeRange = _musicInfo.clipTimeRange;
        [self.navigationController pushViewController:edit animated:YES];
    }
}


- (void) finish: (UIButton *) button{
    //__weak RDRecordViewController *myself = self;
    
    if(!_cameraManager){
        return;
    }
    
    if (isRecording == 0 || isRecording == 1) {
        if (videoOrPhoto) {
            //照片状态下 点击完成按钮 直接返回
            
            [self dismissViewControllerAnimated:YES completion:^{
                [self deleteItems];
                
                
                
                //if(finishBlock)
                //finishBlock(@"",currentRecordType);
            }];
            
        }
        if (self.cameraManager.recordStatus == VideoRecordStatusUnknown) {
            
            return;
        }
        
        if (_totalVideoDur + (isRecording == 0 ? 0 : _currentVideoDur) < (currentRecordType == RecordTypeMVVideo ? _MVRecordMinDuration : _minRecordDuration)) {
            
            RDProgressHUD* hud = [RDProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = RDProgressHUDModeText;
            if (currentRecordType == RecordTypeMVVideo ) {
                hud.label.text = [NSString stringWithFormat:RDLocalizedString(@"小主，至少录%.f秒", nil),_MVRecordMinDuration];            }
            else {
                hud.label.text = [NSString stringWithFormat:RDLocalizedString(@"小主，至少录%.f秒", nil),_minRecordDuration];
            }
            hud.margin = 10.f;
            [hud setOffset:CGPointMake(hud.offset.x, 0.f)];
            hud.removeFromSuperViewOnHide = YES;
            [hud hideAnimated:YES afterDelay:1.5];
            return;
        }
        
        button.selected = YES;
        self.view.userInteractionEnabled = NO;
        if (self.cameraManager.recordStatus !=VideoRecordStatusEnd) {
            if(_enableCameraWaterMark && !enterCameraEnd && _cameraWaterMarkEndDuration >0){
                enterCameraEnd = YES;
                [self performSelector:@selector(finish:) withObject:button afterDelay:_cameraWaterMarkEndDuration];
                return;
            }
            self.cameraManager.recordStatus = VideoRecordStatusEnd;
            [self.recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
        }
        
        
        if( (_blackScreenView == nil) || _blackScreenView.hidden )
        {
            hub = [RDProgressHUD showHUDAddedTo:self.view animated:YES];
            hub.mode = RDProgressHUDModeIndeterminate;
        }
        else
            [_longSizeSplitCountLabel setHidden:YES];
        
        
        if(_enableCameraWaterMark && !enterCameraEnd && _cameraWaterMarkEndDuration >0){
            enterCameraEnd = YES;
            [self tap:nil];
            [self performSelector:@selector(finish:) withObject:button afterDelay:_cameraWaterMarkEndDuration];
            return;
        }
        enterCameraEnd = NO;
        if (isRecording == 0 && _videoArray.count > 0) {//20180621 fix bug:录制中点击完成按钮不能跳转到下一界面
            [self mergeAndExportVideosAtFileURLs:_videoArray];
        }
//        [self performSelector:@selector(mergeAndExportVideosAtFileURLs:) withObject:_videoArray afterDelay:1.0];
    }else{
        [self dismissViewControllerAnimated:YES completion:^{
            [self deleteItems];
            if(cancelBlock){
                cancelBlock(1,self);
            }
        }];
    }
}
#pragma mark - 时间显示
- (void) timeshow{
    timeq += 1;
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",timeq/3600,(timeq/60)%60,timeq%60];
}
- (void)addCancelBlock:(RDRecordCancelBlock)block{
    cancelBlock = [block copy];
}

#pragma mark - 设置
- (void)setButtonAction:(UIButton *)sender {
    RDRecordSetViewController *setVC = [[RDRecordSetViewController alloc] init];
    __weak typeof(self) weakself = self;
    setVC.changeRecordSetFinish = ^(int bitrate, int resolutionIndex) {
        _bitrate = bitrate;
        switch (resolutionIndex) {
            case 0:
                _recordSize = CGSizeMake(360, 640);
                
                break;
            case 1:
                _recordSize = CGSizeMake(480, 640);
                
                break;
            case 2:
                _recordSize = CGSizeMake(720, 1280);
                
                break;
            case 3:
                _recordSize = CGSizeMake(1080, 1920);
                
                break;
                
            default:
                break;
        }
        weakself.cameraManager.bitrate = _bitrate;
        weakself.cameraManager.cameraSize = _recordSize;
        weakself.cameraManager.outputSize = _recordSize;
    };
    [self.navigationController pushViewController:setVC animated:YES];
}

#pragma mark - 闪光灯
- (void) switchFlashMode: (UIButton *) button{
    if (self.cameraManager.position == AVCaptureDevicePositionFront) {
        return;
    }
    if(self.cameraManager.flashMode == AVCaptureTorchModeOn){
        self.cameraManager.flashMode = AVCaptureTorchModeOff;
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光默认_@3x"] forState:UIControlStateNormal];
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光点击_@3x"] forState:UIControlStateHighlighted];
        
    }else{
        self.cameraManager.flashMode = AVCaptureTorchModeOn;
        
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭默认_@3x"] forState:UIControlStateNormal];
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭点击_@3x"] forState:UIControlStateHighlighted];
        
    }
}

#pragma mark - 切换音乐

- (void)changeMusic:(UIButton *)button{
    if(isRecording == 1){
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(changeMusicResult:CompletionHandler:)]) {
        _enterSelectMusic = YES;
        __weak typeof(self) weakself = self;
        [_delegate changeMusicResult:self.navigationController CompletionHandler:^(RDMusic * _Nullable musicInfo) {
            [weakself changeMusicWithMusicInfo:musicInfo];
        }];
    }
}

- (void)changeMusicWithMusicInfo:(RDMusic * _Nullable)musicInfo{
    NSLog(@"%s",__func__);
    if(CMTimeRangeEqual(musicInfo.clipTimeRange, kCMTimeRangeZero)){
        CMTimeRange clipTimeRange = kCMTimeRangeZero;
        clipTimeRange.start = kCMTimeZero;
        clipTimeRange.duration = [AVURLAsset assetWithURL:musicInfo.url].duration;
        musicInfo.clipTimeRange = clipTimeRange;
        
    }
    
    if(CMTimeCompare(CMTimeAdd(musicInfo.clipTimeRange.start, musicInfo.clipTimeRange.duration), [AVURLAsset assetWithURL:musicInfo.url].duration) == 1){
        CMTimeRange clipTimeRange = musicInfo.clipTimeRange;
        clipTimeRange.duration = CMTimeSubtract([AVURLAsset assetWithURL:musicInfo.url].duration, clipTimeRange.start);
        musicInfo.clipTimeRange = clipTimeRange;
    }
    
    _musicInfo = musicInfo;
    [self initAudioPlayer];
    NSString *musicTitle = @"";
    if(musicInfo.name){
        musicTitle = musicInfo.name;
    }
    CGRect rect = [musicTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:_changeMusicButton.titleLabel.font.fontName size:_changeMusicButton.titleLabel.font.pointSize]} context:nil];
    
    CGRect btnRect = _changeMusicButton.frame;
    btnRect.size.width = rect.size.width + 10 + 70;
    
    btnRect.origin.x = kWIDTH - 15 - btnRect.size.width;
    if (MODE && _isSquareTop) {
        btnRect.origin.y = (44 + 45 + 10) + (iPhone_X ? 44 : 0);
    }else {
        btnRect.origin.y = (44 + 10) + (iPhone_X ? 34 : 0);
    }
    _changeMusicButton.frame = btnRect;
    
    [_changeMusicButton setTitle:musicTitle forState:UIControlStateNormal];
    
    CGRect cbtnRect = self.clearMusicButton.frame;
    cbtnRect.origin.x = btnRect.size.width - 30;
    self.clearMusicButton.frame = cbtnRect;
    if(_musicInfo){
        _musicIcon.frame = CGRectMake(14, 8, 14, 14);
    }else{
        _musicIcon.frame = CGRectMake(8, 8, 14, 14);
    }
    [_changeMusicButton addSubview:self.clearMusicButton];
}

- (void)clearMusic{
    if(isRecording == 1){
        return;
    }
    [_changeMusicButton setTitle:nil forState:UIControlStateNormal];
    [_clearMusicButton removeFromSuperview];
    CGRect btnRect = _changeMusicButton.frame;
    btnRect.size.width = 30;
    if(iPhone4s){
        btnRect.origin.x = kWIDTH - 29 - btnRect.size.width;
    }else {
        btnRect.origin.x = kWIDTH - 20 - btnRect.size.width;
    }
    _changeMusicButton.frame = btnRect;
    _musicIcon.frame = CGRectMake(8, 8, 14, 14);
    _musicInfo = nil;
    if(_audioPlayer.isPlaying){
        [_audioPlayer stop];
    }
    _audioPlayer = nil;
}

#pragma mark - 摄像头
- (void) switchBackOrFront{
    if (self.cameraManager.position == AVCaptureDevicePositionBack) {
        self.cameraManager.position = AVCaptureDevicePositionFront;
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭默认_@3x"] forState:UIControlStateNormal];
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭点击_@3x"] forState:UIControlStateHighlighted];
        
    }else{
        self.cameraManager.position = AVCaptureDevicePositionBack;
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光默认_@3x"] forState:UIControlStateNormal];
        [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光点击_@3x"] forState:UIControlStateHighlighted];
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(_cameraManager.position) forKey:@"RDAVCaptureDevicePosition"];
}

#pragma mark - 全屏
- (BOOL)prefersStatusBarHidden{
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark 内存溢出
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark 屏幕旋转

- (void)observeOrientation{
    motionManager=[[CMMotionManager alloc]init];
    
    if (motionManager.accelerometerAvailable) {
        [motionManager setAccelerometerUpdateInterval:0.5f];
        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
        __weak typeof(self) weakSelf = self;
        
        [motionManager startAccelerometerUpdatesToQueue:operationQueue withHandler:^(CMAccelerometerData *data,NSError *error)
         {
             CGFloat xx = data.acceleration.x;
             CGFloat yy = -data.acceleration.y;
             CGFloat zz = data.acceleration.z;
             CGFloat device_angle = M_PI / 2.0f - atan2(yy, xx);
             __strong typeof(self) selfBlock = weakSelf;
             
             UIDeviceOrientation orientation = UIDeviceOrientationUnknown;
             if (device_angle > M_PI)
                 device_angle -= 2 * M_PI;
             if ((zz < -.60f) || (zz > .60f)) {
                 if ( UIDeviceOrientationIsLandscape(selfBlock.lastOrientation) )
                     orientation = selfBlock.lastOrientation;
                 else
                     orientation = UIDeviceOrientationUnknown;
             } else {
                 if ( (device_angle > -M_PI_4) && (device_angle < M_PI_4) )
                     orientation = UIDeviceOrientationPortrait;
                 else if ((device_angle < -M_PI_4) && (device_angle > -3 * M_PI_4))
                     orientation = UIDeviceOrientationLandscapeLeft;
                 else if ((device_angle > M_PI_4) && (device_angle < 3 * M_PI_4))
                     orientation = UIDeviceOrientationLandscapeRight;
                 else
                     orientation = UIDeviceOrientationPortraitUpsideDown;
             }
             if (orientation == UIDeviceOrientationUnknown) {
                 return ;
             }
             
             if (orientation != selfBlock.lastOrientation) {
                 selfBlock.lastOrientation = orientation;
                 if (MODE) {
                     selfBlock.lastOrientation = UIDeviceOrientationPortrait;
                 }
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [selfBlock deviceOrientationDidChangeTo:orientation];
                 });
             }
         }];
    }
}

- (void)deviceOrientationDidChangeTo:(UIDeviceOrientation )orientation{
    
    switch (orientation) {
        case  UIDeviceOrientationUnknown:
            NSLog(@"UIDeviceOrientationUnknown");
            [_cameraManager setDeviceOrientation:UIDeviceOrientationPortrait];
            break;
        case  UIDeviceOrientationPortrait:
            NSLog(@"UIDeviceOrientationPortrait");
            [_cameraManager setDeviceOrientation:UIDeviceOrientationPortrait];
            _screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
            if (!MODE) {
                [_filtergroundView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                UIView *span = [[UIView alloc] initWithFrame:CGRectMake(10, 35, kHEIGHT, 1)];
                span.backgroundColor = SCREEN_BACKGROUND_COLOR;
                [_filtergroundView addSubview:span];
                
                if (_faceU) {
                    [_filtergroundView addSubview:self.segmentedControl];
                }
                [self orientUp];
                if (_faceU) {
                    [self changes:_segmentedControl];
                }
            }
            if (_recordsizetype != RecordSizeTypeMixed) {
                self.changeModeView.hidden = YES;
            }
            
            if (videoOrPhoto) {
                _deleteButton.hidden = YES;
            }
            
            break;
        case  UIDeviceOrientationPortraitUpsideDown:
            [_cameraManager setDeviceOrientation:UIDeviceOrientationPortrait];
            NSLog(@"UIDeviceOrientationPortraitUpsideDown");
            _screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
            
            if (!MODE) {
                [_filtergroundView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                UIView *span = [[UIView alloc] initWithFrame:CGRectMake(10, 35, kHEIGHT, 1)];
                span.backgroundColor = SCREEN_BACKGROUND_COLOR;
                [_filtergroundView addSubview:span];
                
                if (_faceU) {
                    [_filtergroundView addSubview:self.segmentedControl];
                }
                [self orientUp];
                if (_faceU) {
                    [self changes:_segmentedControl];
                }
            }
            if (_recordsizetype != RecordSizeTypeMixed) {
                self.changeModeView.hidden = YES;
            }
            
            if (videoOrPhoto) {
                _deleteButton.hidden = YES;
            }
            
            break;
        case  UIDeviceOrientationLandscapeLeft:
            [_cameraManager setDeviceOrientation:UIDeviceOrientationLandscapeLeft];
            NSLog(@"UIDeviceOrientationLandscapeLeft");
            [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformIdentity;
            }];
            _screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
            
            if (!MODE) {
                [self orientLeft];
                [_filtergroundView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                UIView *span = [[UIView alloc] initWithFrame:CGRectMake(10, 35, kHEIGHT, 1)];
                span.backgroundColor = SCREEN_BACKGROUND_COLOR;
                [_filtergroundView addSubview:span];
                
                if (_faceU) {
                    [_filtergroundView addSubview:self.segmentedControl];
                    [self changes:self.segmentedControl];
                }
            }
            if (_recordsizetype != RecordSizeTypeMixed) {
                self.changeModeView.hidden = YES;
            }
            if (videoOrPhoto) {
                _notSquareDeleteVideoView.hidden = YES;
            }
            break;
        case  UIDeviceOrientationLandscapeRight:
            [_cameraManager setDeviceOrientation:UIDeviceOrientationLandscapeRight];
            NSLog(@"UIDeviceOrientationLandscapeRight");
            [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformIdentity;
            }];
            _screenView.transform = CGAffineTransformMakeRotation(M_PI_2);
            if (!MODE) {
                [self orientRight];
                [_filtergroundView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                UIView *span = [[UIView alloc] initWithFrame:CGRectMake(10, 35, kHEIGHT, 1)];
                span.backgroundColor = SCREEN_BACKGROUND_COLOR;
                [_filtergroundView addSubview:span];
                
                if (_faceU) {
                    [_filtergroundView addSubview:self.segmentedControl];
                    [self changes:self.segmentedControl];
                }
            }
            if (_recordsizetype != RecordSizeTypeMixed) {
                self.changeModeView.hidden = YES;
            }
            if (videoOrPhoto) {
                _notSquareDeleteVideoView.hidden = YES;
            }
            
            break;
//        case  UIDeviceOrientationFaceUp:
//            NSLog(@"UIDeviceOrientationFaceUp");
//
//            break;
//        case  UIDeviceOrientationFaceDown:
//            NSLog(@"UIDeviceOrientationFaceDown");
//
//            break;
        default:
            [_cameraManager setDeviceOrientation:UIDeviceOrientationPortrait];
            break;
    }
}
- (void) orientUp{
    if (_segmentedControl.selectedSegmentIndex == 1 ) {
        [self removeBViews];
        [self changes:_segmentedControl];
    }
    [UIView animateWithDuration:0.3f animations:^{
        
        _finish_Button.hidden = NO;
        _notSquareDeleteVideoView.hidden = YES;
        _deleteButton.hidden = YES;
        _finishButton.hidden = NO;
        
        if (_hiddenPhotoLib && (isRecording == -1 )) {
            _finishButton.hidden = YES;
        }
        
        _topView.center = CGPointMake(kWIDTH/2-24,(iPhone_X ? 36 : 22));
        _changeModeView.center = CGPointMake(kWIDTH-178+5,  (iPhone_X ? 50 : 22));
        _autoRecordButton.center = CGPointMake(kWIDTH-108+5, (iPhone_X ? 50 : 22));
        _blackScreenButton.center = CGPointMake(kWIDTH-38+5, (iPhone_X ? 50 : 22));
        
//        _changeModeView.center = CGPointMake(kWIDTH-178+5, 22 + (iPhone_X ? 44 : 0));
//        _autoRecordButton.center = CGPointMake(kWIDTH-108+5, 22 + (iPhone_X ? 44 : 0));
//        _blackScreenButton.center = CGPointMake(kWIDTH-38+5, 22 + (iPhone_X ? 44 : 0));
        
        _finish_Button.hidden = YES;
        _blackScreenButton.hidden = NO;
        _changeModeView.hidden = NO;
        
        float space = (kWIDTH - 44*4)/5.0;
        if (MODE) {
            if(_isSquareTop){
                _setButton.center = CGPointMake(space + 22, 66);
                _beautifyButton.center   = CGPointMake(space*4.0 + 44*3 + 22 , _setButton.center.y);
                _switchButton.center     = CGPointMake(space*3.0 + 44*2 + 22. , _setButton.center.y);
                _flashButton.center      = CGPointMake(space*2.0 + 44 + 22, _setButton.center.y);
            }else{
               if (iPhone4s) {
                   _setButton.center = CGPointMake(space + 22, kWIDTH+22.);
                   _beautifyButton.center   = CGPointMake(space*4.0 + 44*3 + 22 , _setButton.center.y);
                   _switchButton.center     = CGPointMake(space*3.0 + 44*2 + 22. , _setButton.center.y);
                   _flashButton.center      = CGPointMake(space*2.0 + 44 + 22, _setButton.center.y);
                }else{
                    _setButton.center = CGPointMake(space + 22, kWIDTH + (iPhone_X ? 94.0 : 70.0));
                    _beautifyButton.center   = CGPointMake(space*4.0 + 44*3 + 22 , _setButton.center.y);
                    _switchButton.center     = CGPointMake(space*3.0 + 44*2 + 22. , _setButton.center.y);
                    _flashButton.center      = CGPointMake(space*2.0 + 44 + 22, _setButton.center.y);
                }
            }
            _flashButton.hidden = NO;
            _switchButton.hidden = NO;
            _beautifyButton.hidden= NO;
            _aSplitView.frame = CGRectMake(_aSplitView.frame.origin.x, _setButton.frame.origin.y + 45, _aSplitView.frame.size.width, _aSplitView.frame.size.height);
            if (self.cameraManager.position == AVCaptureDevicePositionBack) {
                [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光默认_@3x"] forState:UIControlStateNormal];
                [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光点击_@3x"] forState:UIControlStateHighlighted];
            }else{
                [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭默认_@3x"] forState:UIControlStateNormal];
                [_flashButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_闪光关闭点击_@3x"] forState:UIControlStateHighlighted];
            }
        }else {
            _bottomView.frame = CGRectMake(0, kHEIGHT-(bottomHeight - 20) - 54 + (recordTypeCounts > 1?0:20), kWIDTH, bottomHeight + 54);
            _progressBar.frame = CGRectMake(0, _bottomView.frame.origin.y - 5, kWIDTH, 5);
            _setButton.center = CGPointMake(space + 22, kHEIGHT - (bottomHeight - 20) -25 + (recordTypeCounts > 1?0:20));
            _beautifyButton.center   = CGPointMake(space*4.0 + 44*3 + 22 , _setButton.center.y);
            _switchButton.center     = CGPointMake(space*3.0 + 44*2 + 22. , _setButton.center.y);
            _flashButton.center      = CGPointMake(space*2.0 + 44 + 22, _setButton.center.y);
            
            _aSplitView.center = CGPointMake(kWIDTH/2, kHEIGHT - (bottomHeight - 20) -25 + (recordTypeCounts > 1?0:20) + 20);
            
            [_filterItemsButton setCenter:CGPointMake(53, kHEIGHT - 45 - 18 - (iPhone_X ? 60 : 0))];
            [_finishButton setCenter:CGPointMake(kWIDTH-53, kHEIGHT - 45 - 18 - (iPhone_X ? 60 : 0))];
        }
        _longSizeSplitTimeLabel.center = CGPointMake(30, 44+5+10);
        
        if ((_cameraManager.recordStatus == VideoRecordStatusResume) || (_cameraManager.recordStatus == VideoRecordStatusBegin)) {
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        }
        _notSquareDeleteVideoView.center = CGPointMake(kWIDTH*3./4. - 15, kHEIGHT - 45);        
        _longSizeSplitTimeLabel.transform = CGAffineTransformIdentity;
        _longSizeSplitCountLabel.transform = CGAffineTransformIdentity;
        
        if (videoOrPhoto) {
            if (_lastOrientation == UIDeviceOrientationPortrait) {
                [_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照_"] forState:UIControlStateNormal];
            }else if (_lastOrientation == UIDeviceOrientationLandscapeLeft){
                [_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照左"] forState:UIControlStateNormal];
                
            }else if(_lastOrientation == UIDeviceOrientationLandscapeRight){
                [_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照右"] forState:UIControlStateNormal];
            }
        }
        
        if (!_filtergroundView.hidden) {
            _bottomView.hidden = YES;
            _progressBar.hidden = YES;
            _flashButton.hidden = YES;
            _switchButton.hidden = YES;
            _beautifyButton.hidden= YES;
        }
        UIButton* btn1 = (UIButton*)[_VideoOrPhotoView viewWithTag:100];
        UIButton* btn2 = (UIButton*)[_VideoOrPhotoView viewWithTag:200];
        UIView* point1 = (UIView*)[_VideoOrPhotoView viewWithTag:99];
        UIView* point2 = (UIView*)[_VideoOrPhotoView viewWithTag:199];
        
        point1.center = CGPointMake(73, 10);
        point2.center = CGPointMake(123, 10);
        if (_cameraMV && _cameraPhoto && !_cameraVideo) {
            point2.center = CGPointMake(73, 10);
        }
        
        if (_filterChooserView) {
            [@[btn1,btn2,point1,point2,_finish_Button,_notSquareDeleteVideoView,self.recordButton,_label1 ,_filtergroundView,_timeTipImageView,_timeLabel,_topView, _filterChooserView,self.faceuScrollview, _flashButton,_switchButton,_autoRecordButton,_beautifyButton,_backButton,_finishButton,_blackScreenButton,_filterItemsButton,_hideFiltersButton,_changeModeView] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformIdentity;
            }];
        }else{
            [@[btn1,btn2,point1,point2,_finish_Button,_notSquareDeleteVideoView,self.recordButton,_label1 ,_filtergroundView,_timeTipImageView,_timeLabel,_topView,self.faceuScrollview, _flashButton,_switchButton,_autoRecordButton,_beautifyButton,_backButton,_finishButton,_blackScreenButton,_filterItemsButton,_hideFiltersButton,_changeModeView] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformIdentity;
            }];
        }
        
        _filterChooserView.frame = CGRectMake(0, _faceU ? kHEIGHT - 80 - 40 - (faceUScrollViewHeight - 80)/2.0 : kHEIGHT - 80 - 32, kWIDTH, 80);
        _filterChooserView.contentInset = UIEdgeInsetsZero;
        _faceuScrollview.contentInset = UIEdgeInsetsZero;
        float height = _faceU ? (36 + faceUScrollViewHeight + 40) : 171;
        _filtergroundView.frame = CGRectMake(0, kHEIGHT - height, kHEIGHT, height);
        _hideFiltersButton.center = CGPointMake(kWIDTH/2, kHEIGHT - _filtergroundView.frame.size.height + 35/2.0);
        _segmentedControl.frame = CGRectMake(0, 0, kWIDTH, 40);
        _segmentedControl.center = CGPointMake(kWIDTH/2, _filtergroundView.frame.size.height - (40 + (iPhone_X ? 34 : 0))/2.0);
        _faceuScrollview.frame = CGRectMake(9, kHEIGHT - 40 - faceUScrollViewHeight, kWIDTH - 18, faceUScrollViewHeight - (iPhone_X ? 34 : 0));
        CGSize size = _faceuScrollview.contentSize;
        _faceuScrollview.contentSize =CGSizeMake(size.width,_faceuScrollview.frame.size.height);
        
        _progressBar.alpha = 0.5;
        _timeTipImageView.alpha = 0.0;
        _timeLabel.alpha = 0.0;
        _longSizeSplitCountLabel.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        _progressBar.alpha = 1.0;
        _progressBar.transform = CGAffineTransformMakeRotation(0);
        
        
        if (MODE && _isSquareTop) {
            _timeTipImageView.frame = CGRectMake(10, 44 + 44, 105, 40);
            _timeLabel.frame = CGRectMake(44, 44 + 44, 100, 40);
            _longSizeSplitCountLabel.center = CGPointMake(144, 64);
        }else {
//            _timeLabel.center = CGPointMake(94,64);
//            _timeTipImageView.center = CGPointMake(62, 64);
            _timeLabel.center = CGPointMake(94, (iPhone_X ? 94 : 64));
            _timeTipImageView.center = CGPointMake(62, (iPhone_X ? 94 : 64));
            _longSizeSplitCountLabel.center = CGPointMake(144, (iPhone_X ? 94 : 64));
        }
        
        _timeTipImageView.alpha = 1.0;
        _timeLabel.alpha = 1.0;
        _longSizeSplitCountLabel.alpha = 1.0;
        self.changeMusicButton.alpha = 1.0;
    }];
}

- (void) orientLeft{
    _bottomView.hidden = NO;
    
    if (currentRecordType == RecordTypeMVVideo || !(_MAX_VIDEO_DUR_2 == 0)) {
        _progressBar.hidden = NO;
    }
    
    _flashButton.hidden = NO;
    _switchButton.hidden = NO;
    _beautifyButton.hidden= NO;
    [UIView animateWithDuration:0.3f animations:^{
        
        _bottomView.frame = CGRectMake(0, kHEIGHT-(bottomHeight - 20) - 54 + (recordTypeCounts > 1?0:20), kWIDTH, bottomHeight + 54);
        
        _finish_Button.hidden = YES;
        
        if (!MODE) {
            _deleteButton.hidden = YES;
            _finishButton.hidden = NO;
            if (_hiddenPhotoLib && (isRecording == -1 )) {
                _finishButton.hidden = YES;
            }
            _notSquareDeleteVideoView.hidden = NO;
        }
        _longSizeSplitTimeLabel.center = CGPointMake(kWIDTH-64, 30);
        
        if ((_cameraManager.recordStatus == VideoRecordStatusResume) || (_cameraManager.recordStatus == VideoRecordStatusBegin)) {
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停横@3x"] forState:UIControlStateNormal];
        }
        
        if (videoOrPhoto) {
            if (_lastOrientation == UIDeviceOrientationPortrait) {
                [_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照_"] forState:UIControlStateNormal];
            }else if (_lastOrientation == UIDeviceOrientationLandscapeLeft){
                [_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照左"] forState:UIControlStateNormal];
                
            }else if(_lastOrientation == UIDeviceOrientationLandscapeRight){
                [_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照右"] forState:UIControlStateNormal];
            }
        }
        
        [[_notSquareDeleteVideoView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        
        if (!MODE) {
            [_finishButton setCenter:CGPointMake(kWIDTH-40, kHEIGHT - 45 - 18 - (iPhone_X ? 60 : 0))];
            [_filterItemsButton setCenter:CGPointMake(40, kHEIGHT - 45 - 18 - (iPhone_X ? 60 : 0))];
        }
        _notSquareDeleteVideoView.center = CGPointMake(kWIDTH*3./4. - 15, kHEIGHT - 45);
        _filterChooserView.frame = CGRectMake(60-kHEIGHT/2, kHEIGHT/2-40, kHEIGHT, 80);
        _filterChooserView.center = CGPointMake((171 - 35 - (_faceU ? 40 : 0) - 80)/2.0 + (_faceU ? 40 : 0) + 80/2, kHEIGHT/2);
        if(LASTIPHONE_5){
            if(iPhone_X){
                _filtergroundView.frame = CGRectMake(-(kWIDTH - 171) - 120, (kHEIGHT - 171)/2.0, kHEIGHT, 171);
                _filterChooserView.contentInset = UIEdgeInsetsMake(0, 44, 0, 35);
                _faceuScrollview.contentInset = UIEdgeInsetsMake(0, 44, 0, 35);
                if (_filterChooserView.contentOffset.x == 0) {
                    _filterChooserView.contentOffset = CGPointMake(-44, 0);
                }
                if (_faceuScrollview.contentOffset.x == 0) {
                    _faceuScrollview.contentOffset = CGPointMake(-44, 0);
                }
            }else{
                _filtergroundView.frame = CGRectMake(-(kWIDTH - 171) - 40, (kHEIGHT - 171)/2.0, kHEIGHT, 171);
            }
            _segmentedControl.frame = CGRectMake(0, 171 - 40, kHEIGHT, 40);
            _hideFiltersButton.frame = CGRectMake(171 - 35, (kHEIGHT - 35)/2.0, 35, 35);
        }else{
            _filtergroundView.frame = CGRectMake(-(kWIDTH - 171) - 50, (kHEIGHT - 171)/2.0, kHEIGHT, 171);
            _segmentedControl.frame = CGRectMake(0, 171 - 40, kHEIGHT, 40);
            _hideFiltersButton.frame = CGRectMake(171 - 35, (kHEIGHT - 35)/2.0 - 10, 35, 35);
        }
        _faceuScrollview.transform = CGAffineTransformIdentity;
        _faceuScrollview.frame = CGRectMake(100-kHEIGHT/2, kHEIGHT/2-50 , kHEIGHT - 18, 100);
        
        if (_filterChooserView) {
            [@[_finish_Button,_notSquareDeleteVideoView,_longSizeSplitTimeLabel,_longSizeSplitCountLabel,_label1 ,_filtergroundView,_timeTipImageView,_timeLabel,  _filterChooserView,self.faceuScrollview, _flashButton,_switchButton,_autoRecordButton,_beautifyButton,_backButton,_finishButton,_blackScreenButton,_filterItemsButton,_hideFiltersButton,_changeModeView] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformMakeRotation(M_PI*0.5);
            }];
        }else{
            [@[_finish_Button,_notSquareDeleteVideoView,_longSizeSplitTimeLabel,_longSizeSplitCountLabel,_label1 ,_filtergroundView,_timeTipImageView,_timeLabel,self.faceuScrollview, _flashButton,_switchButton,_autoRecordButton,_beautifyButton,_backButton,_finishButton,_blackScreenButton,_filterItemsButton,_hideFiltersButton,_changeModeView] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformMakeRotation(M_PI*0.5);
            }];
        }
        CGSize size = _faceuScrollview.contentSize;
        _faceuScrollview.contentSize =CGSizeMake(size.width,80);
        
        _progressBar.alpha = 0.5;
        
        _timeTipImageView.alpha = 0.0;
        _timeLabel.alpha = 0.0;
        _longSizeSplitCountLabel.alpha = 0.0;
        self.changeMusicButton.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        _progressBar.transform = CGAffineTransformMakeRotation(0);
        _progressBar.alpha = 1.0;
        
        _timeTipImageView.center = CGPointMake(kWIDTH-30, kHEIGHT/2-34);
        _timeLabel.center = CGPointMake(kWIDTH-30, kHEIGHT/2);
        _longSizeSplitCountLabel.center = CGPointMake(kWIDTH-30, kHEIGHT/2 + 60);
        
        _timeTipImageView.alpha = 1.0;
        _timeLabel.alpha = 1.0;
        _longSizeSplitCountLabel.alpha = 1.0;
    }];
}

- (void) orientRight{
    
    __block typeof(self) bself = self;
    _bottomView.hidden = NO;
    if (currentRecordType == RecordTypeMVVideo || !(_MAX_VIDEO_DUR_2 == 0)) {
        _progressBar.hidden = NO;
        
    }
    _flashButton.hidden = NO;
    _switchButton.hidden = NO;
    _beautifyButton.hidden= NO;
    [UIView animateWithDuration:0.3f animations:^{
        bself->_bottomView.frame = CGRectMake(0, kHEIGHT-(bottomHeight - 20) - 54 + (recordTypeCounts > 1?0:20), kWIDTH, bottomHeight + 54);
        
        self.finish_Button.hidden = YES;
        if (!MODE) {
            bself->_deleteButton.hidden = YES;
            self.finishButton.hidden = NO;
            if (bself->_hiddenPhotoLib && (bself->isRecording == -1 )) {
                bself->_finishButton.hidden = YES;
            }
            
            self.notSquareDeleteVideoView.hidden = NO;
        }
        
        bself->_longSizeSplitTimeLabel.center = CGPointMake(67, 30);
        
        if ((bself->_cameraManager.recordStatus == VideoRecordStatusResume) || (bself->_cameraManager.recordStatus == VideoRecordStatusBegin) ) {
            [bself->_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停横@3x"] forState:UIControlStateNormal];
        }
        if (videoOrPhoto) {
            if (bself->_lastOrientation == UIDeviceOrientationPortrait) {
                [bself->_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照_"] forState:UIControlStateNormal];
            }else if (bself->_lastOrientation == UIDeviceOrientationLandscapeLeft){
                [bself->_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照左"] forState:UIControlStateNormal];
            }else if(bself->_lastOrientation == UIDeviceOrientationLandscapeRight){
                [bself->_recordButton setImage:[RDHelpClass getBundleImage:@"拍摄_拍照右"] forState:UIControlStateNormal];
            }
        }

        bself->_notSquareDeleteVideoView.center = CGPointMake(kWIDTH/4. + 15, kHEIGHT - 45);
        
        [[bself->_notSquareDeleteVideoView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        bself->_filterChooserView.transform = CGAffineTransformIdentity;
        if(LASTIPHONE_5){
            if(iPhone_X){
                bself->_filterChooserView.frame = CGRectMake(-(171 + 40)/2.0 - (_faceU ? 40/2 : 0), kHEIGHT/2-40, kHEIGHT, 80);
                bself->_faceuScrollview.frame = CGRectMake(kWIDTH - 80/2 - (kHEIGHT - 18)/2 - 50, kHEIGHT/2-50 , kHEIGHT - 18, 80);
                _filterChooserView.contentInset = UIEdgeInsetsMake(0, 35, 0, 44);
                _faceuScrollview.contentInset = UIEdgeInsetsMake(0, 35, 0, 44);
                if (_filterChooserView.contentOffset.x == 0) {
                    _filterChooserView.contentOffset = CGPointMake(-35, 0);
                }
                if (_faceuScrollview.contentOffset.x == 0) {
                    _faceuScrollview.contentOffset = CGPointMake(-35, 0);
                }
            }else{
                bself->_filterChooserView.frame = CGRectMake(-(171 - 35 - 80)/2.0 + 19/2.0 - (_faceU ? 40/2 : 0), kHEIGHT/2-40, kHEIGHT, 80);
                bself->_faceuScrollview.frame = CGRectMake(kWIDTH - 80/2 - (kHEIGHT - 18)/2 - 40, kHEIGHT/2-50 , kHEIGHT - 18, 80);
            }
        }else{
            bself->_filterChooserView.frame = CGRectMake(-(171 - 35 - 80)/2.0 + 19/2.0 - (_faceU ? 40/2 : 0), kHEIGHT/2-40, kHEIGHT, 80);
            bself->_faceuScrollview.frame = CGRectMake(kWIDTH - 80/2 - (kHEIGHT - 18)/2 - 40, kHEIGHT/2-50 , kHEIGHT - 18, 80);
        }
        bself->_filtergroundView.frame = CGRectMake(kWIDTH - 171/2.0 - _filtergroundView.frame.size.width/2.0, (kHEIGHT - 171)/2.0, _filtergroundView.frame.size.width, 171);
        bself->_hideFiltersButton.frame = CGRectMake(kWIDTH - 171, (kHEIGHT - 35)/2.0, 35, 35);
        bself->_segmentedControl.frame = CGRectMake(0, 171 - 40, kHEIGHT, 40);
        
        bself->_faceuScrollview.transform = CGAffineTransformIdentity;
        
        if (bself->_filterChooserView) {
            [@[self.finish_Button,self.notSquareDeleteVideoView,self.longSizeSplitTimeLabel,self.longSizeSplitCountLabel,self.label1,self.filtergroundView,self.timeTipImageView,self.timeLabel, bself->_filterChooserView,self.faceuScrollview, self.flashButton,self.switchButton,self.autoRecordButton,self.beautifyButton,self.backButton,self.finishButton,self.blackScreenButton,self.filterItemsButton,self.hideFiltersButton,self.changeModeView]enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformMakeRotation(-M_PI*0.5);
            }];
        }else{
            [@[self.finish_Button,self.notSquareDeleteVideoView,self.longSizeSplitTimeLabel,self.longSizeSplitCountLabel,self.label1,self.filtergroundView,self.timeTipImageView,self.timeLabel,self.faceuScrollview, self.flashButton,self.switchButton,self.autoRecordButton,self.beautifyButton,self.backButton,self.finishButton,self.blackScreenButton,self.filterItemsButton,self.hideFiltersButton,self.changeModeView]enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.transform = CGAffineTransformMakeRotation(-M_PI*0.5);
            }];
        }
        CGSize size = bself->_faceuScrollview.contentSize;
        bself->_faceuScrollview.contentSize =CGSizeMake(size.width,80);
        bself->_progressBar.alpha = 0.5;
        
        bself->_timeTipImageView.alpha = 0.0;
        bself->_timeLabel.alpha = 0.0;
        bself->_longSizeSplitCountLabel.alpha = 0.0;
        self.changeMusicButton.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        bself->_progressBar.transform = CGAffineTransformMakeRotation(M_PI);
        
        bself->_progressBar.alpha = 1.0;
        
        bself->_timeTipImageView.center = CGPointMake(24, kHEIGHT/2+34);
        bself->_timeLabel.center = CGPointMake(24,kHEIGHT/2);
        bself->_longSizeSplitCountLabel.center = CGPointMake(24, kHEIGHT/2 - 60);
        
        bself->_timeTipImageView.alpha = 1.0;
        bself->_timeLabel.alpha = 1.0;
        bself->_longSizeSplitCountLabel.alpha = 1.0;
    }];
}

#pragma mark 适配显示
- (void) showFilters: (UIButton *) button{
    __block typeof(self) bself = self;
    if (isRecording !=0 || button == _hideFiltersButton) {
        if (self.filterChooserView.hidden) {
            [UIView animateWithDuration:0.3f animations:^{
                if (bself->MODE && bself->_faceU && !bself->_isSquareTop) {
                    bself->_setButton.hidden = YES;
                    bself->_flashButton.hidden = YES;
                    bself->_switchButton.hidden = YES;
                    bself->_beautifyButton.hidden = YES;
                }
                
                bself->_filterChooserView.hidden = NO;
                bself->_filtergroundView.hidden = NO;
                bself->_hideFiltersButton.hidden = NO;
                bself->_faceuScrollview.hidden = NO;
                if (bself->_lastOrientation == UIDeviceOrientationPortrait && !bself->MODE) {
                    
                    bself->_bottomView.hidden = YES;
                    if (bself->currentRecordType == RecordTypeMVVideo || !(bself->_MAX_VIDEO_DUR_1 == 0.0 || bself->_MAX_VIDEO_DUR_2 == 0.0)) {
                        bself->_progressBar.hidden = YES;
                    }
                    bself->_setButton.hidden = YES;
                    bself->_flashButton.hidden = YES;
                    bself->_switchButton.hidden = YES;
                    bself->_beautifyButton.hidden= YES;
                }
                
            }completion:^(BOOL finished) {

            }];
            
        }
        else{
            [UIView animateWithDuration:0.3f animations:^{
                
                if (bself->MODE && bself->_faceU && !bself->_isSquareTop) {
                    bself->_setButton.hidden = NO;
                    bself->_flashButton.hidden = NO;
                    bself->_switchButton.hidden = NO;
                    bself->_beautifyButton.hidden = NO;
                }
                
            } completion:^(BOOL finished) {
                bself->_faceuScrollview.hidden = YES;
                bself->_filterChooserView.hidden = YES;
                bself->_filtergroundView.hidden = YES;
                bself->_hideFiltersButton.hidden = YES;
                self.changeMusicButton.alpha = 1.0;
                
                if (bself->_lastOrientation == UIDeviceOrientationPortrait && !bself->MODE) {
                    
                    bself->_bottomView.hidden = NO;
                    
                    if (bself->currentRecordType == RecordTypeMVVideo || !(bself->_MAX_VIDEO_DUR_1 == 0.0 || bself->_MAX_VIDEO_DUR_2 == 0.0)) {
                        bself->_progressBar.hidden = NO;
                    }
                    
                    bself->_setButton.hidden = NO;
                    bself->_flashButton.hidden = NO;
                    bself->_switchButton.hidden = NO;
                    bself->_beautifyButton.hidden= NO;
                    [bself->_faceuScrollview setHidden:YES];
                }
            }];
        }
    }else{
        [self pressDeleteButton];
    }
}

- (void)checkCameraISOpen{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问相机!",nil)
                                   message:RDLocalizedString(@"用户拒绝访问相机,请在<设置-隐私-相机>中开启",nil)
                         cancelButtonTitle:RDLocalizedString(@"确定",nil)
                         otherButtonTitles:RDLocalizedString(@"取消",nil)
                              alertViewTag:2];
        return;
    }
    
    if( self.recordtype !=  RecordTypePhoto)
    {
        AVAudioSession *avSession = [AVAudioSession sharedInstance];
        
        if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
            __weak typeof(self) weakSelf = self;
            [avSession requestRecordPermission:^(BOOL available) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!available) {
                        [weakSelf initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问麦克风!",nil)
                                                   message:RDLocalizedString(@"请在“设置-隐私-麦克风”中开启",nil)
                                         cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                         otherButtonTitles:RDLocalizedString(@"取消",nil)
                                              alertViewTag:2];
                    }
                });
            }];
        }
    }
}
- (void)tapTheScreen{
    if (!_filterChooserView.hidden) {
        [self showFilters:_filterItemsButton];
    }    
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 2){
        UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
        if(!upView){
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        if (buttonIndex == 0) {
            [RDHelpClass enterSystemSetting];
        }
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    _filters = nil;
    //    view1 = nil;
    [self deleteAllVideo];
    
    RDNavigationViewController *nv = (RDNavigationViewController *)self.navigationController;
    if (nv.rdVeUiSdkDelegate && [nv.rdVeUiSdkDelegate respondsToSelector:@selector(destroyFaceU)]) {
        [nv.rdVeUiSdkDelegate destroyFaceU];
    }
}

- (void) deleteItems{
    if(_audioPlayer.isPlaying){
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_cameraManager stopCamera];
    [_cameraManager deleteItems];
    _cameraManager.delegate = nil;
    _cameraManager = nil;

    motionManager = nil;
    _filters  = nil;
    _filtersName = nil;
    [_filterChooserView deleteDownload];
    [_filterChooserView removeItems];
    _filterChooserView.ChooserBlock = nil;
    _filterChooserView = nil;
    
    if (commonAlertView) {
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
}

#pragma mark - RDCameraManagerDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_delegate && [_delegate respondsToSelector:@selector(willOutputSampleBuffer:)]) {
        [_delegate willOutputSampleBuffer:sampleBuffer];
    }
}

- (void)sendFilterIndex:(NSInteger)index{
    filter_index = index;
    if(_filterChooserView.type == 2){
//        if(![[NSFileManager defaultManager] fileExistsAtPath:((RDFilter *)[self filters][index]).filterPath]){
//            
//            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:((RDFilter *)[self filters][index]).netFile]];
//            [data writeToFile:((RDFilter *)[self filters][index]).filterPath atomically:YES];
//            [self.cameraManager resetFilter:((RDFilter *)[self filters][index]) AtIndex:index];
//        }
        [_filterChooserView setCurrentIndex:filter_index];
    }
}

- (void)movieRecordCancel{
    _cameraManager.recordStatus = VideoRecordStatusCancel;
    [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
    isRecording = 0;
    _currentVideoDur = 0;
    [self stopCountDurTimer];
    
}
- (void)movieRecordBegin{
    
    if ([recordStyle isEqualToString:@"tap"]) {
        NSLog(@"开始录制  tap ");
        if (MODE) {
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        }
        
        if (!MODE && self.lastOrientation == UIDeviceOrientationPortrait) {
            
            if (CHANGEVALUE == 1) {
                _deleteButton.hidden = YES;
            }else{
                _deleteButton.hidden = NO;
            }
            
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停@3x"] forState:UIControlStateNormal];
        }else if(!MODE && self.lastOrientation == UIDeviceOrientationLandscapeLeft)
        {
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停横@3x"] forState:UIControlStateNormal];
        }else if(!MODE && self.lastOrientation == UIDeviceOrientationLandscapeRight){
            if (!MODE) {
                _finishButton.hidden = NO;
            }
            [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_暂停横@3x"] forState:UIControlStateNormal];
        }
    }
    
    if ([recordStyle isEqualToString:@"longpress"]) {
        NSLog(@"开始录制  longpress");
        [_progressBar setLastProgressToStyle:ProgressBarProgressStyleNormal];
    }
}

- (void) movieRecordFailed:(NSError *)error{
    NSLog(@"录制失败:%@",error);
    dispatch_async(dispatch_get_main_queue(), ^{
        isRecording = 0;
        _currentVideoDur = 0;
        [_recordButton setImage:[RDHelpClass getBundleImagePNG:@"拍摄_拍摄@3x"] forState:UIControlStateNormal];
        [self stopCountDurTimer];
        CGFloat all = (_totalVideoDur+self.currentVideoDur)>=_MVRecordMaxDuration?_MVRecordMaxDuration:(_totalVideoDur+self.currentVideoDur);
        int all_ = (int)(all*100);
        _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(all_/6000),(all_/100)%60,all_%100];
    });
}

- (void)movieRecordingCompletion:(NSURL *)videoUrl {

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if(tracks.count == 0){
        NSLog(@"声音没有录制起");
    }else{
        AVAssetTrack *audioTrack = [tracks firstObject];
        if(CMTimeGetSeconds(audioTrack.timeRange.duration) == 0){
            NSLog(@"声音录制时间为0");
        }
    }
    
    float duration = CMTimeGetSeconds(asset.duration);
    if(duration >0){
        [_videoArray addObject:videoUrl];
        [_videoDurationArray addObject:[NSNumber numberWithFloat:duration]];
    }
    isRecording = 0;
    _totalVideoDur = [self totalVideoDuration:_videoArray];
    NSLog(@"生成视频 : %f",_totalVideoDur);
    asset = nil;tracks = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopCountDurTimer];
        if (_finishButton.selected) {//20180621 fix bug:录制中点击完成按钮不能跳转到下一界面
            [self performSelector:@selector(mergeAndExportVideosAtFileURLs:) withObject:_videoArray afterDelay:0.25];
        }
    });
}

- (void)deleteRecordExtraFiles {
    NSArray <RDDraftInfo *>*draftList = [[RDDraftManager sharedManager] getALLDraftVideosInfo];
    NSString *path = [_videoPath stringByDeletingLastPathComponent];
    NSString *fileName = [[_videoPath lastPathComponent] stringByDeletingPathExtension];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray <NSString *>*recordFiles = [fm contentsOfDirectoryAtPath:path error:nil];
    if (draftList.count == 0) {
        [recordFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj hasPrefix:fileName]) {
                [fm removeItemAtPath:[path stringByAppendingPathComponent:obj] error:nil];
            }
        }];
        recordFiles = [fm contentsOfDirectoryAtPath:path error:nil];
    }else {
        [recordFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([name hasPrefix:fileName]) {
                __block BOOL isDraftFile = NO;
                [draftList enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull draft, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [draft.fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull file, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        if ([name.lastPathComponent isEqualToString:file.contentURL.lastPathComponent]) {
                            isDraftFile = YES;
                            *stop2 = YES;
                            *stop1 = YES;
                        }
                    }];
                }];
                if (!isDraftFile) {
                    [fm removeItemAtPath:[path stringByAppendingPathComponent:name] error:nil];
                }
            }
        }];
    }
}

@end
