//
//  QuikViewController.m
//  RDVEUISDK
//
//  Created by apple on 2018/8/13.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "QuikViewController.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"
#import "RDCameraManager.h"

#import "RDMainViewController.h"

#import "ScrollViewChildItem.h"

#import "themeClass.h"

#import "RDZSlider.h"
#import "RDMoveProgress.h"
#import "CustomBaseLab.h"
#import "UIImage+RDWebP.h"
#import "UIImageView+RDWebCache.h"
#import "UIButton+RDWebCache.h"
#import "RDSectorProgressView.h"
#import "RDFileDownloader.h"
#import "RDZipArchive.h"

#import "TMVerticallyCenteredTextView.h"
//进度条
#import "RDMBProgressHUD.h"

//滤镜
#import "CircleView.h"
#import "RDDownTool.h"

//文字
#import "RDAddEffectsByTimeline.h"
#import "RDAddEffectsByTimeline+Subtitle.h"
#import "UIImageView+RDWebCache.h"
#define kRefreshThumbMaxCounts 50

@interface SubtitleLabel : UILabel

@property (nonatomic, strong) UIColor *txtColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) float strokeWidth;
@property (nonatomic, assign) BOOL isBold;
@property (nonatomic ,assign) UIEdgeInsets edgeInsets;
@property(nonatomic,assign)BOOL italic;
@end

@implementation SubtitleLabel

- (void)drawTextInRect:(CGRect)rect {
    if(!self.strokeColor){
        _strokeWidth = 0;
    }
    CGSize shadowOffset = CGSizeMake(self.shadowOffset.width *2.0, self.shadowOffset.height*2.0);
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    
    if(_strokeColor){
        CGContextSetLineWidth(c, _strokeWidth*2.0);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextSetTextDrawingMode(c, kCGTextStroke);
        self.textColor = _strokeColor;
        [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
    }
    
    if(_isBold){
        CGContextSetLineWidth(c, 2);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextSetTextDrawingMode(c, kCGTextStroke);
        self.textColor = _txtColor;
        [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
    }else{
        CGContextSetLineWidth(c, 1);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextSetTextDrawingMode(c, kCGTextStroke);
        self.textColor = _txtColor;
        [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
    }
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = _txtColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
    
    self.shadowOffset = shadowOffset;
    
    
}
@end

@interface QuikViewController ()<RDVECoreDelegate, UIAlertViewDelegate, RDATMHudDelegate,ScrollViewChildItemDelegate,UIScrollViewDelegate,RDMBProgressHUDDelegate,AVAudioRecorderDelegate,UITextViewDelegate>
{
    UIView                  * titleView;
    UIButton *backBtn;
    UIButton *publishBtn;
    
    UILabel                 * titleLbl;
    RDVECore                * rdPlayer;
    CGSize                    exportVideoSize;
   
    RDExportProgressView    * exportProgressView;
    UIAlertView             * commonAlertView;
    RDATMHud                * hud;
    BOOL                      idleTimerDisabled;
    //主菜单
    NSMutableArray          *MainItems;
    
    NSMutableArray <RDScene *> * ThemeArray;
    
    themeClass              *themeclass;//主题特效生成
    //主题
     NSInteger       lastThemeMVIndex;
    NSInteger        oldThemeMVIndex;
    
    //设置
    //视频输出分辨率
    NSMutableArray          *SetItems;
    NSInteger       lastSetIndex;
    VideoResolvPowerType    Current_VideoResolvPowerType;
    VideoResolvPowerType    old_VideoResolvPowerType;
    
    BOOL             isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    BOOL             _idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    
    RDVECore        *thumbImageVideoCore;//截取缩率图
    
    //字幕
    BOOL            enterSubtitle;
    BOOL            startAddSubtitle;
    BOOL            enterEditSubtitle;
    BOOL            unTouchSaveSubtitle;
    NSMutableArray  *thumbTimes;
    BOOL            stopAnimated;
    float           rotaionSaveAngle;
    NSDictionary    *subtitleEffectConfig;
    NSString        *subtitleEffectConfigPath;
    
    NSMutableArray <RDCaption *> *subtitles;
    NSMutableArray <RDCaptionRangeViewFile *> *subtitleFiles;
    NSMutableArray <RDCaptionRangeViewFile *> *oldSubtitleFiles;
    NSInteger       selectFilterIndex;
    NSInteger       oldSelectFilterIndex;
    //滤镜
    NSMutableArray  *globalFilters;
    BOOL             yuanyinOn;
    AVAssetImageGenerator *imageGenerator;
    
    UIImageView          * _auxPView;
    CMTime          startPlayTime;
    NSMutableDictionary *piantouDicInfos;
    NSMutableArray         *jsonTextContentObjects;
    
    //字幕
    UIScrollView                * addedSubtitleScrollView;
    UIScrollView                * addedMaterialEffectScrollView;
    UIImageView                 * selectedMaterialEffectItemIV;
    NSInteger                     selectedMaterialEffectIndex;
    BOOL                          isModifiedMaterialEffect;//是否修改过字幕、贴纸、去水印、画中画、涂鸦
    
    RDAdvanceEditType            selecteFunction;
    CMTime                        seekTime;
    UIView *stoolBarView;
    
    CGRect                      subtitleConfigViewRect;
    CMTimeRange             playTimeRange;
}

//播放界面
@property(nonatomic,strong)UIView                       *playerView;         //播放器
@property(nonatomic,strong)UIButton                     *playBtn;            //播放按钮
@property(nonatomic,strong)UIButton                     *editSubtitleTitle;            //播放按钮
@property(nonatomic,strong)UIView                       *playProgressBack;
@property(nonatomic,strong)RDMoveProgress               *playProgress;
@property(nonatomic,strong)UIView                       *playerToolBar;
@property(nonatomic,strong)UILabel                      *currentTimeLabel;   //当前播放时间
@property(nonatomic,strong)UILabel                      *durationLabel;      //视频总时间
@property(nonatomic,strong)UIButton                     *zoomButton;
@property(nonatomic,strong)RDZSlider                    *videoProgressSlider;//滚动条
@property(nonatomic,strong)UIButton                     *publishButton;

//主菜单
@property(nonatomic,strong)UIScrollView                 *MainMenuView;

//主题
@property(nonatomic,strong)UIView                       *ThemeView;
@property(nonatomic,strong)UIScrollView                 *ThememvChildsView;
@property(nonatomic,strong)ScrollViewChildItem          *CurrentThememvMV;

//设置
@property(nonatomic,strong)UIView                       *SetUpView;     //界面
@property(nonatomic,strong)UIScrollView                 *SetUpChildsView;
@property(nonatomic,strong)ScrollViewChildItem          *CurrentSetUpChildItem;

//字幕
@property(nonatomic,strong)UIView                   *quikSubtitle;
@property(nonatomic,strong)UIView                   *subtitleView;
@property(nonatomic,strong)RDAddEffectsByTimeline   *addEffectsByTimeline;
@property (nonatomic, strong) UIView *addedMaterialEffectView;
@property (nonatomic, assign) BOOL isAddingMaterialEffect;
@property (nonatomic, assign) BOOL isEdittingMaterialEffect;
@property (nonatomic, assign) BOOL isCancelMaterialEffect;

//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;
@property(nonatomic,strong)NSMutableArray   *filtersName;
@property(nonatomic,strong)NSMutableArray   *filters;

@property(nonatomic,strong)RDMBProgressHUD  *progressHUD;
@property(nonatomic,strong)UIView           *syncContainer;

@property(nonatomic,strong)UIView           *editItemsSubtitleView;
@property(nonatomic,strong)TMVerticallyCenteredTextView          *subtitleContentTextView;//TMVerticallyCenteredTextView
@property(nonatomic,strong)UIView           *subtitleContentBackView;//TMVerticallyCenteredTextView
@property(nonatomic,strong)UILabel          *subtitleTishiView;
@property(nonatomic,strong)UIView           *contentBackView;
@property(nonatomic,strong)UITextView       *subtitleContent;
@property(nonatomic,strong) RDATMHud        *hud;

@end

@implementation QuikViewController
static float globalInset = 8;

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:self];
        [self.view addSubview:_hud.view];
    }
    [self.view bringSubviewToFront:_hud.view];
    return _hud;
}


- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [rdPlayer cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself cancelExportBlock];
                [exportProgressView removeFromSuperview];
                exportProgressView = nil;
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)setValue{
    yuanyinOn = YES;
    __block typeof(self) bself = self;

    piantouDicInfos = [[NSMutableDictionary alloc] init];
    selectFilterIndex = 0;
    oldSelectFilterIndex = 0;
    
    rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                      APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                     LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                      videoSize:exportVideoSize
                                            fps:kEXPORTFPS
                                     resultFail:^(NSError *error) {
                                         NSLog(@"initError:%@", error.localizedDescription);
                                     }];
    
    globalFilters = [NSMutableArray array];
   
    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kAEJsonSubtitsPath error:nil];
    [arr enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSString *path1 = [kAEJsonSubtitsPath stringByAppendingPathComponent:obj];
            [[NSFileManager defaultManager] removeItemAtPath:[path1 stringByAppendingPathComponent:@"update"] error:nil];
        }
    }];
    
    NSString *itemFolder =(self->Current_VideoResolvPowerType == VideoResolvPower_Film ? @"16-9" : (self->Current_VideoResolvPowerType == VideoResolvPower_Square ? @"1-1" : @"9-16"));
    
    NSString *jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",arr[0],itemFolder]];
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
    if(data){
        NSError *err;
        NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&err];
        jsonTextContentObjects = config[@"textimg"][@"text"];
    }
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                        appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                                       urlPath:((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL];
            if ([filterList[@"code"] intValue] == 0) {
                self.filtersName = [filterList[@"data"] mutableCopy];
                
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(((RDNavigationViewController *)self.navigationController).appKey.length>0)
                [itemDic setObject:((RDNavigationViewController *)self.navigationController).appKey forKey:@"appkey"];
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
                    RDFilter* filter = [RDFilter new];
                    if([obj[@"name"] isEqualToString:RDLocalizedString(@"原始", nil)]){
                        filter.type = kRDFilterType_YuanShi;
                    }else{
                        NSString *itemPath = [[[filterPath stringByAppendingPathComponent:[obj[@"name"] lastPathComponent]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
                        if (![[[obj[@"file"] pathExtension] lowercaseString] isEqualToString:@"acv"]){
                            filter.type = kRDFilterType_LookUp;
                        }
                        else{
                            filter.type = kRDFilterType_ACV;
                        }
                        filter.filterPath = itemPath;
                    }
                    filter.netCover = obj[@"cover"];
                    filter.name = obj[@"name"];
                    [bself->globalFilters addObject:filter];
                }];
                [bself->rdPlayer addGlobalFilters:bself->globalFilters];
            }
        });
    }else{
        NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
        UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
        
        self.filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        [self.filtersName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            RDFilter* filter = [RDFilter new];
            if ([obj isEqualToString:@"原始"]) {
                filter.type = kRDFilterType_YuanShi;
            }
            else{
                filter.type = kRDFilterType_LookUp;
                filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"lookupFilter/%@",obj] Type:@"png"];
            }
            
            filter.name = obj;
            [bself->globalFilters addObject:filter];
            
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",filter.name]];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:photoPath]){
                [RDCameraManager returnImageWith:inputImage Filter:filter withCompletionHandler:^(UIImage *processedImage) {
                    NSData* imagedata = UIImageJPEGRepresentation(processedImage, 1.0);
                    [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
                }];
            }
        }];
        [rdPlayer addGlobalFilters:globalFilters];
    }
}

- (TMVerticallyCenteredTextView *)subtitleContentTextView{
    if(!_subtitleContentTextView){
        _subtitleContentTextView = [[TMVerticallyCenteredTextView alloc] initWithFrame:CGRectMake(0, (_contentBackView.frame.size.height - (kWIDTH*9.0/16.0))/2.0, kWIDTH, kWIDTH*9.0/16.0) isCenter:NO];
        _subtitleContentTextView.backgroundColor = [UIColor blackColor];
        _subtitleContentTextView.font = [UIFont boldSystemFontOfSize:30];
        _subtitleContentTextView.textColor = [UIColor whiteColor];
        _subtitleContentTextView.textAlignment = NSTextAlignmentLeft;
        _subtitleContentTextView.delegate = self;

      }
    return _subtitleContentTextView;
}

- (void)textViewDidChange:(TMVerticallyCenteredTextView *)textView{
    
    {
        NSString *lang = [[UIApplication sharedApplication]textInputMode].primaryLanguage; //ios7之前使用[UITextInputMode currentInputMode].primaryLanguage
        if ([lang isEqualToString:@"zh-Hans"]) { //中文输入
            UITextRange *selectedRange = [textView markedTextRange];
            //获取高亮部分
            UITextPosition *position = [textView positionFromPosition:selectedRange.start offset:0];
            if (!position) {// 没有高亮选择的字，则对已输入的文字进行字数统计和限制
                NSInteger lineNum = 0;
                for (int i =0; i<jsonTextContentObjects.count; i++) {
                    lineNum += [jsonTextContentObjects[i][@"lineNum"] intValue];
                }
                NSMutableArray *texts = [[textView.text componentsSeparatedByString:@"\n"] mutableCopy];
                NSArray *tmpTexts = [texts sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
                    if(obj1.length<obj2.length){
                        return NSOrderedDescending;
                    }else{
                        return NSOrderedAscending;
                    }
                }];
                
                NSString *ct = [tmpTexts firstObject];
                
                NSInteger index = [texts indexOfObject:ct];
                
                NSInteger tCount = floor((textView.frame.size.width - 20)/textView.font.pointSize);
                
                if(ct.length >tCount){
                    ct = [[[ct substringToIndex:tCount] stringByAppendingString:@"\n"] stringByAppendingString:[ct substringFromIndex:tCount]];
                }
                
                [texts replaceObjectAtIndex:index withObject:ct];
                NSString *text = @"";
                for (int i = 0 ; i<texts.count; i++) {
                    if(i<texts.count - 1){
                        text = [[text stringByAppendingString:texts[i]] stringByAppendingString:@"\n"];
                    }else{
                        text = [text stringByAppendingString:texts[i]];
                    }
                }
                textView.text = text;
            }
            else{//有高亮选择的字符串，则暂不对文字进行统计和限制
                
            }
        }else{//中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            
            NSInteger lineNum = 0;
            for (int i =0; i<jsonTextContentObjects.count; i++) {
                lineNum += [jsonTextContentObjects[i][@"lineNum"] intValue];
            }
            NSMutableArray *texts = [[textView.text componentsSeparatedByString:@"\n"] mutableCopy];
            NSArray *tmpTexts = [texts sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
                if(obj1.length<obj2.length){
                    return NSOrderedDescending;
                }else{
                    return NSOrderedAscending;
                }
            }];
            
            NSString *ct = [tmpTexts firstObject];
            
            NSInteger index = [texts indexOfObject:ct];
            
            NSInteger tCount = floor((textView.frame.size.width - 20)/textView.font.pointSize);
            
            if(ct.length >tCount){
                ct = [[[ct substringToIndex:tCount] stringByAppendingString:@"\n"] stringByAppendingString:[ct substringFromIndex:tCount]];
            }
            
            [texts replaceObjectAtIndex:index withObject:ct];
            NSString *text = @"";
            for (int i = 0 ; i<texts.count; i++) {
                if(i<texts.count - 1){
                    text = [[text stringByAppendingString:texts[i]] stringByAppendingString:@"\n"];
                }else{
                    text = [text stringByAppendingString:texts[i]];
                }
            }
            textView.text = text;
        }
    }
    
    UIColor  *color = ([textView.text length] > (self.subtitleTishiView.tag - 5) ? [UIColor redColor] : [UIColor whiteColor]);
    NSString *str = @"";
    if(self.subtitleTishiView.tag >[textView.text length]){
        str = [NSString stringWithFormat:@"%@(%zd)", RDLocalizedString(@"添加标题", nil),(self.subtitleTishiView.tag - [textView.text length])];
    }else{
        str = [NSString stringWithFormat:@"%@(-%zd)", RDLocalizedString(@"添加标题", nil),[textView.text length] - self.subtitleTishiView.tag];
    }
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName: color, NSFontAttributeName : self.subtitleTishiView.font}];
    
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:[str rangeOfString:[NSString stringWithFormat:@"%@(", @"添加标题"]]];
    [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:[str rangeOfString:@")"]];
    self.subtitleTishiView.attributedText = attStr;
    
#if 0
    NSArray *texts = [textView.text componentsSeparatedByString:@"\n"];
    NSArray *tmpTexts = [texts sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        if(obj1.length<obj2.length){
            return NSOrderedDescending;
        }else{
            return NSOrderedAscending;
        }
    }];
    NSString *text = [tmpTexts firstObject];
    float width = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, (kWIDTH - 30)/4.0) options:(NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:((kWIDTH - 30)/4.0)]} context:nil].size.width;
    float p = MAX(1, width/(kWIDTH - 30));
    
    textView.font = [UIFont boldSystemFontOfSize:((kWIDTH - 30)/4.0 / p)];
    [textView refreshContentSize];
    
#endif
    
}
- (UIView *)subtitleContentBackView{
    if(!_subtitleContentBackView){
        _subtitleContentBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
        _subtitleContentBackView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _contentBackView = [[UIView alloc] init];
        _contentBackView.backgroundColor = [UIColor clearColor];
        float pvheight = kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (iPhone4s ? 60 : (kWIDTH>320 ? 120 : 100)) - 1 - titleView.frame.size.height;
        //titleView.frame.size.height
        [_contentBackView setFrame:CGRectMake(0, iPhone_X ? 44 : 0, kWIDTH, MIN(pvheight, kWIDTH + 5) )];
        [_subtitleContentBackView addSubview:_contentBackView];
        [_contentBackView addSubview:self.subtitleContentTextView];
        _subtitleContentBackView.alpha = 0.0;
        
        UIButton * cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIButton * saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        cancelBtn.frame = CGRectMake(kWIDTH/2.0 - (kWIDTH - 130)/2.0 - 40, _contentBackView.frame.size.height + _contentBackView.frame.origin.y - 40, 70, 40);
        cancelBtn.backgroundColor = UIColorFromRGB(0xa4a5a5);
        
        saveBtn.frame = CGRectMake(kWIDTH/2.0 - (kWIDTH - 130)/2.0 + 40,_contentBackView.frame.size.height + _contentBackView.frame.origin.y - 40, kWIDTH - 130, 40);
        saveBtn.backgroundColor = UIColorFromRGB(0x009fdf);
        
        saveBtn.layer.cornerRadius = 5.0;
        saveBtn.layer.masksToBounds = YES;
        cancelBtn.layer.cornerRadius = 5.0;
        cancelBtn.layer.masksToBounds = YES;
        [cancelBtn setTitle:RDLocalizedString(@"取消", nil) forState:UIControlStateNormal];
        [saveBtn setTitle:RDLocalizedString(@"确定", nil) forState:UIControlStateNormal];
        [cancelBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [saveBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        
        [cancelBtn addTarget:self action:@selector(cancelSubtitleTitleAction) forControlEvents:UIControlEventTouchUpInside];
        [saveBtn addTarget:self action:@selector(saveSubtitleTitleAction) forControlEvents:UIControlEventTouchUpInside];
        [_subtitleContentBackView addSubview:cancelBtn];
        [_subtitleContentBackView addSubview:saveBtn];
        [_subtitleContentBackView addSubview:self.subtitleTishiView];
        
        
        
    }
    return _subtitleContentBackView;
}

- (UILabel *)subtitleTishiView{
    if(!_subtitleTishiView){
        _subtitleTishiView = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 160, 20)];
        _subtitleTishiView.backgroundColor = [UIColor clearColor];
        _subtitleTishiView.font = [UIFont boldSystemFontOfSize:15];
        _subtitleTishiView.textColor = [UIColor whiteColor];
        _subtitleTishiView.text = RDLocalizedString(@"添加标题", nil);
        _subtitleTishiView.minimumScaleFactor = 0.5;
        _subtitleTishiView.textAlignment = NSTextAlignmentLeft;
        _subtitleTishiView.adjustsFontSizeToFitWidth = YES;

    }
    return _subtitleTishiView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    NSString *filePath = [[RDHelpClass getBundle] pathForResource:@"SubtitleAnimations.zip" ofType:@""];
    NSString *cachePath = [[kAEJsonSubtitsPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:kAEJsonSubtitsPath]){
        [self OpenZipp:filePath unzipto:cachePath];
    }
    
    self.navigationController.navigationBar.translucent = iPhone4s;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    exportVideoSize = CGSizeMake(kVIDEOWIDTH,kVIDEOWIDTH*9.0/16.0);
    playTimeRange = kCMTimeRangeZero;
    [self setValue];
    
    themeclass = [[themeClass alloc] init];
    [themeclass setFileList:_fileList atEndTime:1.0 videoSize:exportVideoSize];
    lastThemeMVIndex = 0;
    
    hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
    
    [self.view addSubview:self.playerView];
    
    //主题
    [self InitThemeView];
    [self.view addSubview:self.ThemeView];
    [_ThemeView setHidden:YES];
    //设置
    [self InitSetUpView];
    [self.view addSubview:self.SetUpView];
    [_SetUpView setHidden:YES];
    //主菜单
    [self.view addSubview:self.MainMenuView];
    //设置默认显示主题
    [_ThemeView setHidden:NO];
    
    //标题栏
    [self initTitleView];
    [self initPlayer];
}

- (void)refreshCaptions {
    rdPlayer.captions = subtitles;
}

#pragma mark-
- (void)initThumbImageVideoCore{
    NSMutableArray *scenes = [NSMutableArray array];
    //设置主题效果
    __block NSString *musicPath = @"";
    switch (lastThemeMVIndex) {
        case Effect_Grammy:
            [themeclass GetGrammyEffect:scenes];
            
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/The Pass - Colors" ofType:@"mp3"];
            break;
        case Effect_Action:
            [themeclass GetActionEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Stefanie Heinzmann - Like A Bullet" ofType:@"mp3"];
            break;
        case Effect_Boxed:
            [themeclass GetBoxedEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Kalimba" ofType:@"mp3"];
            break;
        case Effect_Lapse:
            [themeclass GetLapseEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Pushim - Colors" ofType:@"mp3"];
            break;
        case Effect_Slice:
            [themeclass GetSliceEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Sleep Away" ofType:@"mp3"];
            break;
        case Effect_Serene:
            [themeclass GetSerene:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
            break;
        case Effect_Flick:
            [themeclass GetFlick:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Kalimba" ofType:@"mp3"];
            break;
        case Effect_Raw:
            [themeclass GetRawEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
            break;
        case Effect_Epic:
            [themeclass GetEpicEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/The Pass - Colors" ofType:@"mp3"];
            break;
        case Effect_Light:
            [themeclass GetActionEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/light/light" ofType:@"mp3"];
            break;
        case Effect_Sunny:
            [themeclass GetSunnyEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
            break;
        case Effect_Jolly:
            [themeclass GetJolly:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/tantan" ofType:@"mp3"];
            break;
        case Effect_Snappy:
            [themeclass GetSnappyEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
            break;
        case Effect_Tinted:
            [themeclass GetOverEffect:scenes];
            musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Sleep Away" ofType:@"mp3"];
            break;
            break;
        default:
            break;
    }
    
    
    if(!thumbImageVideoCore){
        thumbImageVideoCore = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                                     APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                                    LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                                     videoSize:exportVideoSize
                                                           fps:kEXPORTFPS
                                                    resultFail:^(NSError *error) {
                                                        NSLog(@"initSDKError:%@", error.localizedDescription);
                                                    }];
        
    }
    CGRect rect = self.playerView.bounds;
    thumbImageVideoCore.frame = rect;
    thumbImageVideoCore.view.backgroundColor = [UIColor grayColor];
    
    
    
    
    [thumbImageVideoCore setEditorVideoSize:self->exportVideoSize];
    thumbImageVideoCore.delegate = self;
    
    float value1 = (self.playerView.frame.size.height-5);
    thumbImageVideoCore.frame = CGRectMake(0,(self.playerView.frame.size.height - 5 - value1)/2.0, kWIDTH, value1);
    // [self.view addSubview:rdPlayer.view];
    
    
    
    
    NSMutableArray *jsonMVEffects = [[NSMutableArray alloc] init];
    NSString *folderName = @"";
    if(lastThemeMVIndex == Effect_Grammy){
        folderName = @"Grammy";
    }else if(lastThemeMVIndex == Effect_Action){
        folderName = @"Action";
    }else if(lastThemeMVIndex == Effect_Boxed){
        folderName = @"Boxed";
    }else if(lastThemeMVIndex == Effect_Lapse){
        folderName = @"Lapse";
    }else if(lastThemeMVIndex == Effect_Slice){
        folderName = @"Slice";
    }else if(lastThemeMVIndex == Effect_Serene){
        folderName = @"Serene";
    }else if(lastThemeMVIndex == Effect_Flick){
        folderName = @"Flick";
    }else if(lastThemeMVIndex == Effect_Raw){
        folderName = @"Raw";
    }else if(lastThemeMVIndex == Effect_Epic){
        folderName = @"Epic";
    }else if(lastThemeMVIndex == Effect_Light){
        folderName = @"Light";
    }else if(lastThemeMVIndex == Effect_Sunny){
        folderName = @"Sunny";
    }else if(lastThemeMVIndex == Effect_Jolly){
        folderName = @"Jolly";
    }else if(lastThemeMVIndex == Effect_Snappy){
        folderName = @"Snappy";
    }else if(lastThemeMVIndex == Effect_Tinted){
        folderName = @"Serene1";
    }
    
    
    NSString *resourcepath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/Resource",folderName]];
    
    NSArray *resourcefiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcepath error:nil];
    __block NSMutableArray *jsonpaths = [NSMutableArray array];
    [resourcefiles enumerateObjectsUsingBlock:^(NSString *  _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
        if([[[file pathExtension] lowercaseString] isEqualToString:@"json"]){
            [jsonpaths addObject:file];
        }else if([[[file pathExtension] lowercaseString] isEqualToString:@"mp3"]){
            musicPath = [resourcepath stringByAppendingPathComponent:file];
        }
    }];
    
    [jsonpaths sortUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        if ([[obj1 stringByDeletingPathExtension] integerValue] > [[obj2 stringByDeletingPathExtension] integerValue]) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    
    {
        NSString *item =(self->Current_VideoResolvPowerType == VideoResolvPower_Film ? @"16-9" : (self->Current_VideoResolvPowerType == VideoResolvPower_Square ? @"1-1" : @"9-16"));
        
        NSString *path = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update",folderName]];
        
        NSArray *anlis = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        float duration = 0;
        
        
        if(anlis.count>0){
            for(int i = 0 ;i<anlis.count;i++){
                NSString *jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update/%@/%@/data.json",folderName,anlis[i],item]];
                NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
                NSError *err;
                NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&err];
                float dur = [config[@"op"] floatValue]/[config[@"fr"] floatValue];
                
                if(![[self->piantouDicInfos allKeys] containsObject:@"piantouDicInfo"] || [self->piantouDicInfos[@"piantouDicInfo"] length]>0){
                    RDJsonAnimation *animation = [[RDJsonAnimation alloc] init];
                    animation.jsonPath = jsonpath;
                    animation.isJson1V1 = NO;
                    animation.ispiantou = YES;
                    animation.isRepeat = NO;
                    [jsonMVEffects addObject:animation];
                    duration +=dur;
                }
                
            }
        }else{
            
            for (int i = 0; i<3; i++) {
                NSString *itemFolder =(i==1 ? @"16-9" : (i == 0 ? @"1-1" : @"9-16"));
                {
                    NSString *jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",folderName,itemFolder]];
                    
                    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
                    if(data){
                        NSError *err;
                        NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                                options:NSJSONReadingMutableContainers
                                                                                  error:&err];
                        
                        
                        NSArray *assets = config[@"assets"];
                        NSArray *layers = config[@"layers"];
                        
                        
                        [layers enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull layer, NSUInteger lIdx, BOOL * _Nonnull lstop) {
                            if([layer[@"nm"] hasPrefix:@"ReplaceablePic"]){
                                [assets enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull asset, NSUInteger aIdx, BOOL * _Nonnull astop) {
                                    if([layer[@"refId"] isEqualToString:asset[@"id"]]){
                                        NSString *scr = [asset[@"u"] stringByAppendingPathComponent:asset[@"p"]];
                                        float width = [asset[@"w"] floatValue];
                                        float height = [asset[@"h"] floatValue];
                                        
                                        *astop = YES;
                                        
                                        NSString *imagePath = [[jsonpath stringByDeletingLastPathComponent] stringByAppendingPathComponent:scr];
                                        
                                        
                                        unlink([imagePath UTF8String]);
                                        UIImage *image = [RDHelpClass getFullScreenImageWithUrl:self.fileList[0].contentURL];
                                        CGFloat sw = image.size.width;
                                        CGFloat sh = image.size.height;
                                        CGRect clipR = CGRectZero;
                                        if((sw/sh) > (width/height)){
                                            float w = floor(sh*(width/height));
                                            clipR = CGRectMake((sw - w)/2.0, 0, w, sh);
                                        }else{
                                            float h = floor(sw*(height/width));
                                            clipR = CGRectMake(0, (sh - h)/2.0, sw, h);
                                        }
                                        
                                        UIImage *image1 = [self imageByCropToRect:clipR source:image];
                                        [UIImageJPEGRepresentation(image1, 1) writeToFile:imagePath atomically:YES];
                                        
//                                        UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width, image.size.width * height/width), NO, 0);
//                                        UIBezierPath *clipRectPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, image.size.width, image.size.width * height/width)];
//                                        [clipRectPath addClip];
//                                        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
//                                        image = UIGraphicsGetImageFromCurrentImageContext();
//                                        UIGraphicsEndImageContext();
//                                        [UIImageJPEGRepresentation(image, 1) writeToFile:imagePath atomically:YES];
                                        
                                    }
                                }];
                            }
                        }];
                    }
                }
            }
            
            
        }
        if(jsonMVEffects.count>0 &&
           ((lastThemeMVIndex == Effect_Grammy) ||
            (lastThemeMVIndex == Effect_Boxed)  ||
            (lastThemeMVIndex == Effect_Lapse) ||
            (lastThemeMVIndex == Effect_Slice) ||
            (lastThemeMVIndex == Effect_Serene) ||
            (lastThemeMVIndex == Effect_Raw) ||
            (lastThemeMVIndex == Effect_Epic) ||
            (lastThemeMVIndex == Effect_Sunny) ||
            (lastThemeMVIndex == Effect_Snappy))){
               
               if(duration>0){
                   RDScene * scene = [[RDScene alloc] init];
                   VVAsset* vvassetWhite = [[VVAsset alloc] init];
                   vvassetWhite.type = RDAssetTypeVideo;
                   vvassetWhite.videoFillType = RDVideoFillTypeFull;
                   vvassetWhite.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, 600));
                   vvassetWhite.speed        = 1;
                   vvassetWhite.volume       = 0;
                   vvassetWhite.rotate       = 0;
                   vvassetWhite.isVerticalMirror = NO;
                   vvassetWhite.isHorizontalMirror = NO;
                   vvassetWhite.crop = CGRectMake(0, 0, 1, 1);
                   vvassetWhite.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"27_b" Type:@"mp4"]];
                   vvassetWhite.startTimeInScene = kCMTimeZero;
                   scene.transition.type = RDVideoTransitionTypeFade;
                   scene.transition.duration = MIN(duration/2.0, 0.5);
                   [scene.vvAsset addObject:vvassetWhite];
                   [scenes insertObject:scene atIndex:0];
               }
               
           }
        
    }
    [thumbImageVideoCore setScenes:scenes];
    [thumbImageVideoCore addMVEffect:nil];
//    [self refreshCaptions];
    
    
    if(lastThemeMVIndex == Effect_Light){
        
        NSMutableArray<VVMovieEffect *> * mvEffects = [[NSMutableArray alloc] init];
        double startTime = 0;
        VVMovieEffect *mvEffect = [[VVMovieEffect alloc] init];
        NSString *videoFilePath = [[RDHelpClass getBundle] pathForResource:@"assets/light/lightscreen" ofType:@"mp4"];
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoFilePath]];
        
        double duration = CMTimeGetSeconds(asset.duration);
        
        CMTimeRange showTimeRange=CMTimeRangeMake(CMTimeMakeWithSeconds(startTime,TIMESCALE), CMTimeMakeWithSeconds(duration,TIMESCALE));
        mvEffect.url = [NSURL fileURLWithPath:videoFilePath];
        mvEffect.timeRange = showTimeRange;
        mvEffect.shouldRepeat = YES;
        mvEffect.alpha = 0.2;
        mvEffect.type = RDVideoMVEffectTypeScreen;
        [mvEffects addObject:mvEffect];
        
        [thumbImageVideoCore addMVEffect:mvEffects];
        
    }else if(lastThemeMVIndex == Effect_Jolly){
        
        for (int i = 0; i<jsonpaths.count; i++) {
            NSString *itemConfigPath = [resourcepath stringByAppendingPathComponent:jsonpaths[i]];
            
            RDJsonAnimation *animation = [[RDJsonAnimation alloc] init];
            animation.jsonPath = itemConfigPath;
            animation.isJson1V1 = YES;
            animation.isRepeat = YES;
            //animation.name = @"tantan";
            [jsonMVEffects addObject:animation];
            
        }
        
        
    }
    
    [thumbImageVideoCore setAeJsonMVEffects:jsonMVEffects];
    
    thumbImageVideoCore.enableAudioEffect = NO;
    [thumbImageVideoCore build];
    
    if (globalFilters.count > 0) {
        [thumbImageVideoCore addGlobalFilters:globalFilters];
        [thumbImageVideoCore setGlobalFilter:selectFilterIndex];
    }
    [thumbImageVideoCore setShouldRepeat:NO];
}

- (void)initProgressHUD:(NSString *)message{
    if (_progressHUD) {
        _progressHUD.delegate = nil;
        _progressHUD = nil;
    }
    //圆形进度条
    _progressHUD = [[RDMBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:_progressHUD];
    _progressHUD.removeFromSuperViewOnHide = YES;
    _progressHUD.mode = RDMBProgressHUDModeDeterminate;//MBProgressHUDModeAnnularDeterminate;
    _progressHUD.animationType = RDMBProgressHUDAnimationFade;
    _progressHUD.labelText = message;
    _progressHUD.isShowCancelBtn = YES;
    _progressHUD.delegate = self;
    [_progressHUD show:YES];
    [self myProgressTask:0];
    
}
- (void)myProgressTask:(float)progress{
    [_progressHUD setProgress:progress];
}

- (void)updateSyncLayerPositionAndTransform
{
    if(!_syncContainer){
        _syncContainer = [[UIView alloc] init];
    }
    //视频分辨率
    CGSize presentationSize  = exportVideoSize;
    
    CGRect bounds = self.playerView.bounds;
    bounds.size.height -= 5;
    CGRect videoRect         = AVMakeRectWithAspectRatioInsideRect(presentationSize, bounds);
    _syncContainer.frame = videoRect;
    _syncContainer.layer.masksToBounds = YES;
}

#pragma mark- =====DubbingTrimViewDelegate CaptionVideoTrimViewDelegate ======
- (void)seekTime:(NSNumber *)numTime{
    
    __block typeof(self) bself = self;
    
    NSLog(@"%s time :%f",__func__,[numTime floatValue]);
    CMTime time = CMTimeMakeWithSeconds([numTime floatValue], TIMESCALE);
    [rdPlayer seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
        float duration = bself->rdPlayer.duration;
        if(CMTimeGetSeconds(bself->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
            [self playVideo:YES];
        }
    }];
    
}

- (UIImage *)getCover:(UIView *)v{
    CGSize s = v.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)trimmerView:(id)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime{
    [self.view bringSubviewToFront:_auxPView];
    __block typeof(self) bself = self;
    __weak typeof(self) myself = self;
    if(![rdPlayer isPlaying]){
        
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            float duration = bself->rdPlayer.duration;
            if(CMTimeGetSeconds(bself->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [myself playVideo:YES];
            }
        }];
    }
    {
    }
}

- (void)capationScrollViewWillBegin:(CaptionVideoTrimmerView *)trimmerView{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
}

- (void)didEndChangeSelectedMinimumValue_maximumValue{
    [self refreshCaptions];
    CMTime time = [rdPlayer currentTime];
    [rdPlayer filterRefresh:time];
    
}
- (void)capationScrollViewWillEnd:(CaptionVideoTrimmerView *)trimmerView
                        startTime:(Float64)capationStartTime
                          endTime:(Float64)capationEndTime{
    __block typeof(self) bself = self;

    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    [thumbImageVideoCore getImageWithTime:CMTimeMakeWithSeconds(capationStartTime, 600) scale:1 completionHandler:^(UIImage *image) {
        bself->_auxPView.image = image;
    }];
}

- (void)touchescurrentCaptionView:(id)trimmerView
                      showOhidden:(BOOL)flag
                        startTime:(Float64)captionStartTime{
}

#pragma mark-滤镜
- (UIView *)filterView{
    if(!_filterView){
        __block typeof(self) bself = self;
        __weak typeof(self) myself = self;
        _filterView = [UIView new];
        _filterView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        float toolbarheight = (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80));
        float spanheight = (kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60))) - (self.playerView.frame.origin.y + CGRectGetHeight(self.playerView.frame));
        _filterView.frame           = CGRectMake(0, (self.playerView.frame.origin.y + CGRectGetHeight(self.playerView.frame)) + (spanheight - toolbarheight)/2.0 , kWIDTH, toolbarheight);
        //_filterView.frame           = CGRectMake(0, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)) - 1 , kWIDTH, (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)));
        _filterChildsView           = [UIScrollView new];
        _filterChildsView.frame     = CGRectMake(0,0 , _ThemeView.frame.size.width, (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)));
        _filterChildsView.backgroundColor                   = [UIColor clearColor];
        _filterChildsView.showsHorizontalScrollIndicator    = NO;
        _filterChildsView.showsVerticalScrollIndicator      = NO;
        
        [_filterView addSubview:_filterChildsView];
        [globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(myself.filterChildsView.frame.size.height - 15)+10, 0, (myself.filterChildsView.frame.size.height - 25), myself.filterChildsView.frame.size.height)];
            item.backgroundColor        = [UIColor clearColor];
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
                if(idx == 0){
                    NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                    NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                    NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                    item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
                }else{
                    [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
                }
            }else{
                NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                }
                NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
            }
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
            [myself.filterChildsView addSubview:item];
            [item setSelected:(idx == bself->selectFilterIndex ? YES : NO)];
        }];
        
        _filterChildsView.contentSize = CGSizeMake(globalFilters.count * (_filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
        _filterView.hidden = YES;
    }
    return _filterView;
}

#pragma mark- 字幕
- (void)initToolBarView{
    if( !stoolBarView )
    {
        stoolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
        stoolBarView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [self.view addSubview:stoolBarView];
    }
    else
        stoolBarView.hidden = NO;
}
- (UIView *)subtitleView{
    if(!_subtitleView){
        _subtitleView = [UIView new];
        _subtitleView.frame = CGRectMake(0, self.playerView.frame.size.height  + self.playerView.frame.origin.y, kWIDTH, kHEIGHT - (self.playerView.frame.size.height  + self.playerView.frame.origin.y) - kToolbarHeight);
        _subtitleView.backgroundColor = TOOLBAR_COLOR;
        _subtitleView.hidden = YES;
    }
    return _subtitleView;
}
- (RDAddEffectsByTimeline *)addEffectsByTimeline {
    if (!_addEffectsByTimeline) {
        float height = kHEIGHT - kPlayerViewOriginX - kPlayerViewHeight - kToolbarHeight;
        _addEffectsByTimeline = [[RDAddEffectsByTimeline alloc] initWithFrame:CGRectMake(0,( _subtitleView.frame.size.height - height)/2.0, _subtitleView.frame.size.width, height)];
        [_addEffectsByTimeline prepareWithEditConfiguration:((RDNavigationViewController *)self.navigationController).editConfiguration
                                                     appKey:((RDNavigationViewController *)self.navigationController).appKey
                                                 exportSize:exportVideoSize
                                                 playerView:_playerView
                                                        hud:_hud];
        _addEffectsByTimeline.delegate = self;
    }
    return _addEffectsByTimeline;
}

- (UIView *)addedMaterialEffectView {
    if (!_addedMaterialEffectView) {
        _addedMaterialEffectView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, kWIDTH - 40, 44)];
        stoolBarView.backgroundColor =  TOOLBAR_COLOR;
        //        _addedMaterialEffectView.hidden = YES;
        [stoolBarView addSubview:_addedMaterialEffectView];
        _addedMaterialEffectView.backgroundColor = TOOLBAR_COLOR;
        UILabel *addedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 44)];
        addedLbl.text = RDLocalizedString(@"已添加", nil);
        addedLbl.textColor = UIColorFromRGB(0x888888);
        addedLbl.font = [UIFont systemFontOfSize:14.0];
        [_addedMaterialEffectView addSubview:addedLbl];
        
        addedMaterialEffectScrollView =  [UIScrollView new];
        addedMaterialEffectScrollView.frame = CGRectMake(64, 0, _addedMaterialEffectView.bounds.size.width - 64, 44);
        addedMaterialEffectScrollView.showsVerticalScrollIndicator = NO;
        addedMaterialEffectScrollView.showsHorizontalScrollIndicator = NO;
        [_addedMaterialEffectView addSubview:addedMaterialEffectScrollView];
        
        selectedMaterialEffectItemIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, addedMaterialEffectScrollView.bounds.size.height - 27, 27, 27)];
        
        selectedMaterialEffectItemIV.image = [RDHelpClass imageWithContentOfFile:@"/jianji/effectVideo/特效-选中勾_"];
        selectedMaterialEffectItemIV.hidden = YES;
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    return _addedMaterialEffectView;
}


#pragma mark-主菜单界面
-(UIScrollView *)MainMenuView{
    if ( !_MainMenuView ) {
        //获取
        NSDictionary * ThemeDic =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"Quick-theme", nil),@"title",@(1),@"id", nil];
        NSDictionary * SetDic =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"Quick-set", nil),@"title",@(4),@"id", nil];
        NSDictionary * subtitleDic =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"字幕", nil),@"title",@(2),@"id", nil];
        NSDictionary * FilterDic =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"Quick-Filter", nil),@"title",@(3),@"id", nil];
        //添加
        MainItems = [NSMutableArray array];
        [MainItems addObject:ThemeDic];
        [MainItems addObject:subtitleDic];
        [MainItems addObject:FilterDic];
        [MainItems addObject:SetDic];
        
        _MainMenuView = [UIScrollView new];
        _MainMenuView.frame = CGRectMake(0, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)), kWIDTH,(iPhone_X ? 88 : (iPhone4s ? 55 : 60)));
        _MainMenuView.backgroundColor = TOOLBAR_COLOR;
        _MainMenuView.showsVerticalScrollIndicator = NO;
        _MainMenuView.showsHorizontalScrollIndicator = NO;
        [self.view addSubview:self.MainMenuView];
        
        __block float MainItemBtnWidth = MAX(kWIDTH/MainItems.count,60+5);
        __block float contentsWidth = 0;
        
        [MainItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *MainItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            MainItemBtn.tag = [[self->MainItems[idx] objectForKey:@"id"] integerValue];
            MainItemBtn.backgroundColor = [UIColor clearColor];
            MainItemBtn.exclusiveTouch = YES;
            MainItemBtn.frame = CGRectMake(idx * MainItemBtnWidth, 0, MainItemBtnWidth, 60);
            [MainItemBtn addTarget:self action:@selector(clickMainTiemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [MainItemBtn setImage:[UIImage imageWithContentsOfFile:[self MainItemsImagePath:MainItemBtn.tag - 1]] forState:UIControlStateNormal];
            [MainItemBtn setImage:[UIImage imageWithContentsOfFile:[self MainItemsSelectImagePath:MainItemBtn.tag - 1]] forState:UIControlStateSelected];
            [MainItemBtn setTitle:[self->MainItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            [MainItemBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            [MainItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            MainItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
            [MainItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (MainItemBtnWidth - 44)/2.0, 16, (MainItemBtnWidth - 44)/2.0)];
            [MainItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            if( idx == 0 )
                MainItemBtn.selected = YES;
            [self->_MainMenuView addSubview:MainItemBtn];
            contentsWidth += MainItemBtnWidth;
        }];
    }
    return _MainMenuView;
}

/**功能选择
 */
-(void)clickMainTiemBtn:(UIButton *)sender{
    titleLbl.text = sender.currentTitle;
    switch (sender.tag) {
        case 1://主题
            {
                //TODO: 主题
                selecteFunction = RDAdvanceEditType_None;
                [rdPlayer setShouldRepeat:YES];
                [_ThemeView setHidden:NO];
                _playBtn.hidden = NO;
                [self changePublicBtnTitle:NO];
                self.filterView.hidden = YES;
                self.subtitleView.hidden = YES;
                [_SetUpView setHidden:YES];
                [_MainMenuView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.tag == 1){
                        obj.selected = YES;
                    }else{
                        obj.selected = NO;
                    }
                }];
            }
            break;
        case 4://设置
            {
                //TODO: 设置
                _playBtn.hidden = NO;
                selecteFunction = RDAdvanceEditType_None;
                [rdPlayer setShouldRepeat:YES];
                [self changePublicBtnTitle:NO];
                self.filterView.hidden = YES;
                self.subtitleView.hidden = YES;
                [_ThemeView setHidden:YES];
                [_SetUpView setHidden:NO];
                [_MainMenuView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.tag == 4){
                        obj.selected = YES;
                    }else{
                        obj.selected = NO;
                    }
                }];
            }
            break;
        case 2://字幕
            {
                RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
                selecteFunction = RDAdvanceEditType_Subtitle;
                if([lexiu currentReachabilityStatus] == RDNotReachable){
                    [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                    [self.hud show];
                    [self.hud hideAfter:2];
                    return;
                }
                [self initToolBarView];
                [self initThumbImageVideoCore];
                self.filterView.hidden = YES;
                [_ThemeView setHidden:NO];
                [_SetUpView setHidden:NO];
                //TODO:进入字幕
                titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(LASTIPHONE_5 ? 1.0 : 0.6)];
//                self.playerView.frame = CGRectMake(0, LASTIPHONE_5 ? (titleView.frame.origin.y + CGRectGetHeight(titleView.frame)) : 0, kWIDTH, kWIDTH + 5);
                //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                if([rdPlayer isPlaying]){
                    [self playVideo:NO];
                }
                [rdPlayer setShouldRepeat:NO];
                
                
                if(!self.subtitleView.superview)
                    [self.view addSubview:self.subtitleView];
                titleLbl.text = sender.currentTitle;
                [self changePublicBtnTitle:YES];
                enterSubtitle = YES;
                self.subtitleView.hidden = NO;
                self.addEffectsByTimeline.hidden = NO;
                _addEffectsByTimeline.thumbnailCoreSDK = rdPlayer;
                if (!_addEffectsByTimeline.superview) {
                    [_subtitleView addSubview:_addEffectsByTimeline];
                    _addEffectsByTimeline.currentEffect = selecteFunction;
                }else {
                    _addEffectsByTimeline.currentEffect = selecteFunction;
                    [_addEffectsByTimeline removeFromSuperview];
                    [_subtitleView addSubview:_addEffectsByTimeline];
                }
                _addEffectsByTimeline.currentTimeLbl.text = @"0.00";
                [self performSelector:@selector(loadTrimmerViewThumbImage) withObject:nil afterDelay:0.1];
                self.addedMaterialEffectView.hidden = NO;
            }
            break;
        case 3:
            {
                RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
                if([lexiu currentReachabilityStatus] == RDNotReachable){
                    [self.hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
                    [self.hud show];
                    [self.hud hideAfter:2];
                    return;
                }
                [_ThemeView setHidden:YES];
                [_SetUpView setHidden:YES];
                //TODO:进入滤镜
                selecteFunction = RDAdvanceEditType_Filter;
                [rdPlayer setShouldRepeat:NO];
                if(!self.filterView.superview)
                    [self.view addSubview:self.filterView];
                [self changePublicBtnTitle:NO];
                self.filterView.hidden = NO;
                self.subtitleView.hidden = YES;
                [_MainMenuView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.tag == 3){
                        obj.selected = YES;
                    }else{
                        obj.selected = NO;
                    }
                }];
            }
            break;
        default:
            break;
    }
}

- (void)changePublicBtnTitle:(BOOL)image{
    if(image){
        [_publishButton setTitle:@"" forState:UIControlStateNormal];
        [_publishButton setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_下一步完成默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }else{
        [_publishButton setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
        [_publishButton setImage:nil forState:UIControlStateNormal];
    }
}

/**获取工具Icon图标地址
 */
- (NSString *)MainItemsSelectImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑M V选中_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑片段编辑选中_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑字幕选中_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑滤镜选中_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

- (NSString *)MainItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑M V默认_@3x" Type:@"png"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑片段编辑默认_@3x" Type:@"png"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑字幕默认_@3x" Type:@"png"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/scrollViewChildImage/剪辑_剪辑滤镜默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

#pragma mark-主题界面
-(void) InitThemeView{
    _ThemeView = [[UIView alloc] init];
    //_ThemeView.frame = CGRectMake(0, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)) - 1 , kWIDTH, (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)));
    float toolbarheight = (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80));
    float spanheight = (kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60))) - (self.playerView.frame.origin.y + CGRectGetHeight(self.playerView.frame));
    _ThemeView.frame           = CGRectMake(0, (self.playerView.frame.origin.y + CGRectGetHeight(self.playerView.frame)) + (spanheight - toolbarheight)/2.0 , kWIDTH, toolbarheight);

    _ThemeView.backgroundColor = [UIColor clearColor];
    
    _ThememvChildsView = [[UIScrollView new] init];
    _ThememvChildsView.frame = CGRectMake(0,0 , _ThemeView.frame.size.width, (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)));
    _ThememvChildsView.backgroundColor = [UIColor clearColor];//UIColorFromRGB(NV_Color);
    _ThememvChildsView.showsHorizontalScrollIndicator = NO;
    _ThememvChildsView.showsVerticalScrollIndicator = NO;
    
    NSArray *mvNameArray = [NSArray arrayWithObjects:@"Grammy", @"Action", @"Boxed", @"Lapse", @"Slice",@"Serene",@"Flick",@"Raw",@"Epic",@"Light",@"Sunny",@"Jolly",@"Snappy",@"Tinted", nil];
    for (int i = 0; i < mvNameArray.count; i++) {
        
        
        ScrollViewChildItem *item = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(i*(_ThememvChildsView.frame.size.height - 15)+10, 0.0, _ThememvChildsView.frame.size.height - 25, _ThememvChildsView.frame.size.height)];
        item.backgroundColor = [UIColor clearColor];
        item.fontSize = 12;
        item.type = 0;
        item.delegate = self;
        item.selectedColor = Main_Color;
        item.normalColor   = UIColorFromRGB(0x888888);
        item.cornerRadius = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor = [UIColor clearColor];
        item.tag = i;
        [item setSelected:(0 == i ? YES : NO)];
        if( 0 == i )
        {
            _CurrentThememvMV = item;
        }
        UIImage * image;
        
        NSString * str = [self SetItemsThemeImagePath:i];
        
        if( str != nil )
            image = [RDHelpClass getFullScreenImageWithUrl:[NSURL fileURLWithPath:str]];
        
        if( image != nil )
            item.itemIconView.image = image;
        else
            item.itemIconView.image = [RDHelpClass imageWithContentOfFile:@"zhunbeipaishe/拍摄_滤镜无默认_"];
        
        item.itemTitleLabel.text  = RDLocalizedString(mvNameArray[i], nil);
        
        [_ThememvChildsView addSubview:item];
        
        
        
        
        
    }
    
     _ThememvChildsView.contentSize = CGSizeMake((mvNameArray.count) * (_ThememvChildsView.frame.size.height - 10), _ThememvChildsView.frame.size.height);
    
    lastThemeMVIndex = 0;
    
    [_ThemeView addSubview:self.ThememvChildsView];
}

#pragma mark-主题图标
-(NSString *) SetItemsThemeImagePath:(int)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Grammy" Type:@"jpg"];
        }
            break;
        case 1:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Action" Type:@"jpg"];
        }
            break;
        case 2:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Boxed" Type:@"jpg"];
        }
            break;
        case 3:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Lapse" Type:@"jpg"];
        }
            break;
        case 4:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Slice" Type:@"jpg"];
        }
            break;
        case 5:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Serene" Type:@"jpg"];
        }
            break;
        case 6:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Flick" Type:@"jpg"];
        }
            break;
        case 7:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Raw" Type:@"jpg"];
        }
            break;
        case 8:
        {
            imagePath = nil;
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Tender" Type:@"jpg"];
        }
            break;
        case 9:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Light" Type:@"jpg"];
        }
            break;
        case 10:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Sunny" Type:@"jpg"];
        }
            break;
        case 11:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Jolly" Type:@"jpg"];
        }
            break;
        case 12:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Snappy" Type:@"jpg"];
        }
            break;
        case 13:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Tinted" Type:@"jpg"];
        }
            break;
        case 14:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Tender" Type:@"jpg"];
        }
            break;
        case 15:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Over" Type:@"jpg"];
        }
            break;
        case 16:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Over" Type:@"jpg"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

#pragma mark-顶部标题栏的设置
- (void)initTitleView {
    titleView = [UIView new];
    titleView.frame = CGRectMake(0, 0, kWIDTH, iPhone_X ? 88 : 44);
    titleView.backgroundColor = UIColorFromRGB(NV_Color);
    [self.view addSubview:titleView];
    
    titleLbl = [UILabel new];
    titleLbl.frame = CGRectMake(0, (titleView.frame.size.height - 44), kWIDTH, 44);
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.text = RDLocalizedString(@"照片电影", nil);
    [titleView addSubview:titleLbl];
    
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.backgroundColor = [UIColor clearColor];
    backBtn.frame = CGRectMake(5, (titleView.frame.size.height - 44), 44, 44);
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    publishBtn.exclusiveTouch = YES;
    publishBtn.backgroundColor = [UIColor clearColor];
    publishBtn.frame = CGRectMake(kWIDTH - 69, (titleView.frame.size.height - 44), 64, 44);
    publishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [publishBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [publishBtn setTitle:RDLocalizedString(@"导出", nil) forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(publishBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    _publishButton = publishBtn;
    [titleView addSubview:publishBtn];
}

#pragma mark-设置
-(void) InitSetUpView{
    _SetUpView = [[UIView alloc] init];
    
    float toolbarheight = (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80));
    float spanheight = (kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60))) - (self.playerView.frame.origin.y + CGRectGetHeight(self.playerView.frame));
    _SetUpView.frame           = CGRectMake(0, (self.playerView.frame.origin.y + CGRectGetHeight(self.playerView.frame)) + (spanheight - toolbarheight)/2.0 , kWIDTH, toolbarheight);
    
    //_SetUpView.frame = CGRectMake(0, kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)) - 1  , kWIDTH,  );
    _ThemeView.backgroundColor = [UIColor clearColor];
    _SetUpView.backgroundColor = [UIColor clearColor];
    
    [_SetUpView addSubview:self.SetUpChildsView];
}

/**设置界面
 */
-(UIScrollView *)SetUpChildsView
{
    if( !_SetUpChildsView )
    {
        //获取
        NSDictionary * VideoRPDic =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"胶片", nil),@"title",@(1),@"id", nil];
        NSDictionary * VideoRPDic1 =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"正方形", nil),@"title",@(2),@"id", nil];
        NSDictionary * VideoRPDic2 =  [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"纵向", nil),@"title",@(3),@"id", nil];
        //添加
        SetItems = [NSMutableArray array];
        [SetItems addObject:VideoRPDic];
        [SetItems addObject:VideoRPDic1];
        [SetItems addObject:VideoRPDic2];
        
        _SetUpChildsView = [UIScrollView new];
        _SetUpChildsView.frame =  CGRectMake(0, 0  , _SetUpView.frame.size.width, (iPhone4s ? 60 : (kWIDTH>320 ? 100 : 80)));
        _SetUpChildsView.backgroundColor = [UIColor clearColor];//UIColorFromRGB(NV_Color);
        _SetUpChildsView.showsVerticalScrollIndicator = NO;
        _SetUpChildsView.showsHorizontalScrollIndicator = NO;
        [_SetUpView addSubview:self.SetUpChildsView];
        
        __block float SetItemBtnWidth = MAX(kWIDTH/SetItems.count,60+5);
        __block float contentsWidth = 0;
        
        [SetItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *SetItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            SetItemBtn.tag = [[self->SetItems[idx] objectForKey:@"id"] integerValue];
            SetItemBtn.backgroundColor = [UIColor clearColor];
            SetItemBtn.exclusiveTouch = YES;
            SetItemBtn.frame = CGRectMake(idx * SetItemBtnWidth, (self->_SetUpChildsView.frame.size.height - 60)/2, SetItemBtnWidth, 60);
            [SetItemBtn addTarget:self action:@selector(clickSetTiemBtn:) forControlEvents:UIControlEventTouchUpInside];
            [SetItemBtn setImage:[UIImage imageWithContentsOfFile:[self SetItemsHighlightedImagePath:0]] forState:UIControlStateNormal];
            [SetItemBtn setImage:[UIImage imageWithContentsOfFile:[self SetItemsImagePath:0]] forState:UIControlStateSelected];
            [SetItemBtn setTitle:[self->SetItems[idx] objectForKey:@"title"] forState:UIControlStateNormal];
            if( idx == 0 )
                SetItemBtn.selected = YES;
            [SetItemBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            [SetItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
            SetItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
            [SetItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (SetItemBtnWidth - 44)/2.0, 16, (SetItemBtnWidth - 44)/2.0)];
            [SetItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
            [self->_SetUpChildsView addSubview:SetItemBtn];
            contentsWidth += SetItemBtnWidth;
        }];
    }
    Current_VideoResolvPowerType = VideoResolvPower_Film;
    return _SetUpChildsView;
}
//设置
-(void)clickSetTiemBtn:(UIButton *)sender{
    
    VideoResolvPowerType old_Current_VideoResolvPowerType = Current_VideoResolvPowerType;
    
    CGSize videoSize = CGSizeZero;
    
    if(1 == sender.tag)
    {
        videoSize = CGSizeMake(kVIDEOWIDTH, kVIDEOWIDTH*9.0/16.0);
        Current_VideoResolvPowerType = VideoResolvPower_Film;
        [_SetUpChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.tag == 1){
                obj.selected = YES;
            }else{
                obj.selected = NO;
            }
        }];
    }
    else if(2 == sender.tag)
    {
        videoSize = CGSizeMake(kSQUAREVIDEOWIDTH, kSQUAREVIDEOWIDTH);
        Current_VideoResolvPowerType = VideoResolvPower_Square;
        [_SetUpChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.tag == 2){
                obj.selected = YES;
            }else{
                obj.selected = NO;
            }
        }];
    }
    else if(3 == sender.tag)
    {
        videoSize = CGSizeMake(kVIDEOWIDTH*9.0/16.0, kVIDEOWIDTH);
        Current_VideoResolvPowerType = VideoResolvPower_Portait;
        [_SetUpChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.tag == 3){
                obj.selected = YES;
            }else{
                obj.selected = NO;
            }
        }];
    }
    
    if(old_Current_VideoResolvPowerType !=  Current_VideoResolvPowerType){
        
        [subtitles enumerateObjectsUsingBlock:^(RDCaption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"obj:%zd   position:%@",idx,NSStringFromCGPoint(obj.position));
        }];
        
        if(subtitleFiles.count>0){
            [self refreshCaptionsEtcSize:videoSize array:subtitles];
        }
        exportVideoSize = videoSize;
        [self initPlayer];
    }
}

/**获取工具Icon图标地址
 */
- (NSString *)SetItemsHighlightedImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"jianji/剪辑_添加视频默认_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

- (NSString *)SetItemsImagePath:(NSInteger)index{
    NSString *imagePath = nil;
    switch (index) {
        case 0:
        {
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"jianji/剪辑_添加视频点击_@3x" Type:@"png"];
        }
            break;
        default:
            break;
    }
    return imagePath;
}

#pragma mark- -----------

//返回
- (void)back:(UIButton *)sender{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
    
    if (selecteFunction == RDAdvanceEditType_Subtitle)
    {
        if (_isAddingMaterialEffect) {
            [_addEffectsByTimeline cancelEffectAction:nil];
        }else {
            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
        }
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
        selecteFunction = RDAdvanceEditType_None;
        
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
//        _addedMaterialEffectView.hidden = YES;
        _subtitleView.hidden = YES;
        _playerToolBar.hidden = NO;
        
        [self refreshRdPlayer:rdPlayer];
        [self clickMainTiemBtn:[self.MainMenuView viewWithTag:[[MainItems[0] objectForKey:@"id"] integerValue]]];
        stoolBarView.hidden = YES;
        return;
    }
    
    if(_cancelBlock){
        _cancelBlock();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark-播放器
- (void)cancelExportBlock{
    //将界面上的时间进度设置为零
    _videoProgressSlider.value = 0;
    [_playProgress setProgress:0];
    _currentTimeLabel.text = [RDHelpClass timeToStringFormat:0.0];
    [exportProgressView setProgress:0 animated:NO];
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
}

-(UIView *)playerView
{
    if (!_playerView) {
        _playerView = [UIView new];
        float pvheight = kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (iPhone4s ? 60 : (kWIDTH>320 ? 120 : 100)) - 1 - titleView.frame.size.height;
        //titleView.frame.size.height
        [_playerView setFrame:CGRectMake(0, iPhone_X ? 88 : 44, kWIDTH, MIN(pvheight, kWIDTH + 5) )];
        _playerView.backgroundColor =SCREEN_BACKGROUND_COLOR;
        
        _playProgressBack = [UIView new];
        _playProgressBack.frame = CGRectMake(0, _playerView.frame.size.height - 5, kWIDTH, 5);
        _playProgressBack.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [_playerView addSubview:_playProgressBack];
        
        [_playerView addSubview:[self playBtn]];
        [_playerView addSubview:[self editSubtitleTitle]];
        [_playerView addSubview:[self playerToolBar]];
        [_playProgressBack addSubview:self.playProgress];
    }
    return _playerView;
}

//播放器操作界面
-(UIView *)playerToolBar{
    
    if (!_playerToolBar) {
        _playerToolBar = [UIView new];
        _playerToolBar.backgroundColor = UIColorFromRGB(0x100f12);
        _playerToolBar.frame = CGRectMake(0, self.playerView.frame.size.height - 44 , self.playerView.frame.size.width, 44);
        
        [_playerToolBar addSubview:self.currentTimeLabel];
        [_playerToolBar addSubview:self.durationLabel];
        [_playerToolBar addSubview:self.videoProgressSlider];
        [_playerToolBar addSubview:self.zoomButton];
        _playerToolBar.hidden = YES;
    }
    return  _playerToolBar;
}
//总时间 视频label
-(UILabel *) durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.frame = CGRectMake(self.playerToolBar.frame.size.width - 60 - 50, (self.playerToolBar.frame.size.height - 20.0)/2.0, 60, 20);
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = UIColorFromRGB(0xffffff);
        _durationLabel.font = [UIFont systemFontOfSize:12];
        
    }
    return _durationLabel;
}
//当前播放时间
-(UILabel *)currentTimeLabel{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.frame = CGRectMake(5, (self.playerToolBar.frame.size.height - 20)/2.0, 60, 20);
        _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
        _currentTimeLabel.textColor = UIColorFromRGB(0xffffff);
        _currentTimeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _currentTimeLabel;
}
//全屏按钮
- (UIButton *)zoomButton{
    if(!_zoomButton){
        _zoomButton = [UIButton new];
        _zoomButton.backgroundColor = [UIColor clearColor];
        _zoomButton.frame = CGRectMake(self.playerToolBar.frame.size.width - 50, (self.playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_全屏默认_"] forState:UIControlStateNormal];
        [_zoomButton setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/jiequ/剪辑-截取_缩小默认_"] forState:UIControlStateSelected];
        [_zoomButton addTarget:self action:@selector(tapzoomButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _zoomButton;
}

/**进度条
 */
- (RDZSlider *)videoProgressSlider{
    if(!_videoProgressSlider){
        
        _videoProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(60, (self.playerToolBar.frame.size.height - 30)/2.0, self.playerToolBar.frame.size.width - 60 - 60 - 50, 30)];
        [_videoProgressSlider setMaximumValue:1];
        [_videoProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_videoProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        _videoProgressSlider.layer.cornerRadius = 2.0;
        _videoProgressSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_videoProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        
        [_videoProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_videoProgressSlider setValue:0];
        _videoProgressSlider.alpha = 1.0;
        
        _videoProgressSlider.backgroundColor = [UIColor clearColor];
        
        [_videoProgressSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_videoProgressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_videoProgressSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    }
    return _videoProgressSlider;
}
- (RDMoveProgress *)playProgress{
    if(!_playProgress){
        _playProgress = [[RDMoveProgress alloc] initWithFrame:CGRectMake(0,_playProgressBack.frame.size.height - 5, self.playerView.frame.size.width, 5)];
        [_playProgress setProgress:0 animated:NO];
        [_playProgress setTrackTintColor:Main_Color];
        [_playProgress setBackgroundColor:TOOLBAR_COLOR];
        _playProgress.hidden = YES;
    }
    return _playProgress;
}

//是否全屏
/**是否全屏
 */
- (void)tapzoomButton{
    _zoomButton.selected = !_zoomButton.selected;
    if(_zoomButton.selected){
        [self.view bringSubviewToFront:self.playerView];
        //放大
        CGRect videoThumbnailFrame = CGRectZero;
        CGRect playerFrame = CGRectZero;
        self.playerView.transform = CGAffineTransformIdentity;
        if(exportVideoSize.width>exportVideoSize.height){
            self.playerView.transform = CGAffineTransformMakeRotation(90 * M_PI / 180);
            videoThumbnailFrame = [self.playerView frame];
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = [[UIScreen mainScreen] applicationFrame].size.height;
            videoThumbnailFrame.size.width  = [[UIScreen mainScreen] applicationFrame].size.width;
            playerFrame = videoThumbnailFrame;
            playerFrame.origin.x=0;
            playerFrame.origin.y=0;
            playerFrame.size.width = [[UIScreen mainScreen] applicationFrame].size.height;
            playerFrame.size.height  = [[UIScreen mainScreen] applicationFrame].size.width;
        }else{
            self.playerView.transform = CGAffineTransformMakeRotation(0);
            videoThumbnailFrame = [self.playerView frame];
            videoThumbnailFrame.origin.x=0;
            videoThumbnailFrame.origin.y=0;
            videoThumbnailFrame.size.height = [[UIScreen mainScreen] applicationFrame].size.height;
            videoThumbnailFrame.size.width  = [[UIScreen mainScreen] applicationFrame].size.width;
            playerFrame = videoThumbnailFrame;
        }
        [self.playerView setFrame:videoThumbnailFrame];
        
        rdPlayer.frame = playerFrame;
        self.playBtn.frame = CGRectMake((playerFrame.size.width - 44.0)/2.0, (playerFrame.size.height - 44)/2.0, 44, 44);
        self.playerToolBar.frame = CGRectMake(0, playerFrame.size.height - 44, playerFrame.size.width, 44);
        self.playProgress.frame = CGRectMake(0,playerFrame.size.height-5, playerFrame.size.width, 5);
        self.videoProgressSlider.frame = CGRectMake(60, (self.playerToolBar.frame.size.height - 30)/2.0, self.playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        self.durationLabel.frame = CGRectMake(self.playerToolBar.frame.size.width - 60 - 50, self.playerToolBar.frame.size.height - 30, 60, 20);
        self.zoomButton.frame = CGRectMake(self.playerToolBar.frame.size.width - 50, (self.playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        if(![rdPlayer isPlaying]){
            if (CMTimeGetSeconds(CMTimeAdd(rdPlayer.currentTime, CMTimeMake(1, 600))) > rdPlayer.duration) {
                [rdPlayer seekToTime:CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(1, 600))];
            }else {
                [rdPlayer seekToTime:CMTimeAdd(rdPlayer.currentTime, CMTimeMake(1, 600))];
            }
        }
    }else{
        [self.view bringSubviewToFront:titleView];
        //缩小
        self.playerView.transform = CGAffineTransformIdentity;
        self.playerView.transform = CGAffineTransformMakeRotation(0);
        float pvheight = kHEIGHT - (iPhone_X ? 88 : (iPhone4s ? 55 : 60)) - (iPhone4s ? 60 : (kWIDTH>320 ? 120 : 100)) - 1 - titleView.frame.size.height;
        [self.playerView setFrame:CGRectMake(0, titleView.frame.size.height, kWIDTH, MIN(pvheight, kWIDTH + 5) )];
        rdPlayer.frame = CGRectMake(0, 0, self.playerView.bounds.size.width, self.playerView.bounds.size.height - 5);
        self.playProgressBack.frame = CGRectMake(0, _playerView.frame.size.height - 5, kWIDTH, 5);
        self.playBtn.frame = CGRectMake((self.playerView.frame.size.width - 44.0)/2.0, (self.playerView.frame.size.height - 44)/2.0, 44, 44);
        self.playProgress.frame = CGRectMake(0,_playProgressBack.frame.size.height - 5, self.playerView.frame.size.width, 5);
        self.playerToolBar.frame = CGRectMake(0, self.playerView.frame.size.height - 44 , self.playerView.frame.size.width, 44);
        self.videoProgressSlider.frame = CGRectMake(60, (self.playerToolBar.frame.size.height - 30)/2.0, self.playerToolBar.frame.size.width - 60 - 60 - 50, 30);
        self.durationLabel.frame = CGRectMake(self.playerToolBar.frame.size.width - 60 - 50, (self.playerToolBar.frame.size.height - 20.0)/2.0, 60, 20);
        self.zoomButton.frame =  CGRectMake(self.playerToolBar.frame.size.width - 50, (self.playerToolBar.frame.size.height - 44)/2.0, 44, 44);
        if(![rdPlayer isPlaying]){
            if (CMTimeGetSeconds(CMTimeAdd(rdPlayer.currentTime, CMTimeMake(1, 600))) > rdPlayer.duration) {
                [rdPlayer seekToTime:CMTimeSubtract(rdPlayer.currentTime, CMTimeMake(1, 600))];
            }else {
                [rdPlayer seekToTime:CMTimeAdd(rdPlayer.currentTime, CMTimeMake(1, 600))];
            }
        }
    }
}
//滑动进度条
-(void)beginScrub:(RDZSlider *)slider{
    if([rdPlayer isPlaying]){
        [self playVideo:NO];
    }
}
/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{

    CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:current];
    [self.playProgress setProgress:_videoProgressSlider.value animated:NO];
    
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{

    CGFloat current = _videoProgressSlider.value*rdPlayer.duration;
    [rdPlayer seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
}



-(UIButton *)editSubtitleTitle
{
    if (!_editSubtitleTitle) {
        _editSubtitleTitle = [UIButton new];
        _editSubtitleTitle.backgroundColor = UIColorFromRGB(0x1f1e22);
        _editSubtitleTitle.frame = CGRectMake( (_playerView.frame.size.width - 70.0)/2.0, (_playerView.frame.size.height - 35 - 44), 70, 70);//(_playerView.frame.size.height - 56.0)/2.0
        _editSubtitleTitle.layer.cornerRadius = 35.0;
        _editSubtitleTitle.layer.masksToBounds = YES;
        [_editSubtitleTitle setTitle:RDLocalizedString(@"编辑", nil) forState:UIControlStateNormal];
        [_editSubtitleTitle setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_editSubtitleTitle setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 35, 0)];
        //[_editSubtitleTitle setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-编辑特效_"] forState:UIControlStateNormal];
        [_editSubtitleTitle addTarget:self action:@selector(editSubtitleTitleAction:) forControlEvents:UIControlEventTouchUpInside];
        _editSubtitleTitle.hidden = YES;
        
    }
    return _editSubtitleTitle;
}
//播放暂停
-(UIButton *)playBtn
{
    if (!_playBtn) {
        _playBtn = [UIButton new];
        _playBtn.backgroundColor = [UIColor clearColor];
        _playBtn.frame = CGRectMake( (_playerView.frame.size.width - 56.0)/2.0, (_playerView.frame.size.height - 56.0)/2.0, 56, 56);
        [_playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(tapPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (void)cancelSubtitleTitleAction{
    [self.subtitleContentTextView resignFirstResponder];
    [self editSubtitleTitleAction:self.playBtn];
    
}

- (void)lineViewToImg:(NSString *)configPath folderName:(NSString *)folderName itemPath:(NSString *)linePath contenttext:(NSString *)contenttext

{
    
    
    
   for (int i = 0; i<3; i++) {
       NSString *item = (i==0 ? @"1-1" : (i == 1 ? @"16-9" : @"9-16"));
       NSString *jsonname = [configPath lastPathComponent];
       NSString *jsonPath = [[[[configPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:item] stringByAppendingPathComponent:jsonname];
       NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonPath]];
       NSDictionary * textstings;
       if(data){
           NSError *err;
           NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&err];
           
           textstings = config[@"textimg"];
       }
       NSDictionary *config = textstings[@"text"][0];
       
       
       
       NSArray *textPadding =  config[@"textPadding"];
       
       UIEdgeInsets textLableInsets = UIEdgeInsetsMake([textPadding[1] floatValue], [textPadding[0] floatValue], [textPadding[3] floatValue], [textPadding[2] floatValue]);
       
       
       NSArray *textColors = config[@"textColor"];
       
       float r = [textColors[0] floatValue]/255.0;
       float g = [textColors[1] floatValue]/255.0;
       float b = [textColors[2] floatValue]/255.0;
       //文字颜色
       UIColor *textColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
       
       NSArray *strokeColors = config[@"strokeColor"];
       //文字描边颜色
       UIColor *strokeColor =  [UIColor colorWithRed:[strokeColors[0] floatValue]/255.0
                                               green:[strokeColors[1] floatValue]/255.0
                                                blue:[strokeColors[2] floatValue]/255.0
                                               alpha:1];
       
       float strokeWidth = [config[@"strokeWidth"] floatValue];
       BOOL italic = [config[@"italic"] boolValue];
       
//       NSArray *shadowColors = config[@"shadowColor"];
//       //文字描边颜色
//       UIColor *shadowColor =  [UIColor colorWithRed:[shadowColors[0] floatValue]/255.0
//                                               green:[shadowColors[1] floatValue]/255.0
//                                                blue:[shadowColors[2] floatValue]/255.0
//                                               alpha:1];
       
       
       
       
       NSString *iLine = [linePath stringByAppendingPathComponent:item];
       
       
       //NSString *imagepath = [[[[[configPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[iLine lastPathComponent]] stringByAppendingPathComponent:@"images"] stringByAppendingPathComponent:@"img_0.png"];
       
//       NSString *itemname = [iLine lastPathComponent];
       UIImage *image = nil;
       CGSize imageSize = CGSizeMake([config[@"width"] floatValue], [config[@"height"] floatValue]);//[UIImage imageWithContentsOfFile:imagepath].size;
       
//       float maxLenth = contenttext.length;
//       if([folderName isEqualToString:@"Grammy"]){
//           if([itemname isEqualToString:@"1-1"]){
//               maxLenth = 4;
//           }else if([itemname isEqualToString:@"16-9"]){
//               maxLenth = 7;
//           }else{
//               maxLenth = 6;
//           }
//       }
       
       
       [[NSFileManager defaultManager] createDirectoryAtPath:iLine withIntermediateDirectories:YES attributes:nil error:nil];
       
       NSString *imPath = [iLine stringByAppendingPathComponent:@"images"];
       
       
       NSString *resultPath = [imPath stringByAppendingPathComponent:@"img_0.png"];
       
       
       SubtitleLabel *label = [[SubtitleLabel alloc] initWithFrame:CGRectMake((kWIDTH - imageSize.width)/2.0, 0, imageSize.width, imageSize.height)];
       label.numberOfLines = ([config[@"singleline"] boolValue] ? 1 : 0);
       label.adjustsFontSizeToFitWidth = YES;
       label.backgroundColor = [UIColor clearColor];
       label.textAlignment  = [config[@"alignment"] isEqualToString:@"center"] ? NSTextAlignmentCenter : ([config[@"alignment"] isEqualToString:@"right"] ? NSTextAlignmentRight : NSTextAlignmentLeft);
       label.italic         = italic;
       label.edgeInsets     = textLableInsets;
       label.txtColor       = textColor;
       label.strokeWidth    = strokeWidth;
       label.strokeColor    = strokeColor;
       //label.shadowColor    = shadowColor;
       label.shadowOffset   = CGSizeMake(0, 0);
       label.text           = contenttext;
       
       NSArray *textArray = [contenttext componentsSeparatedByString:@"\n"];
       NSArray *tmpTexts = [textArray sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
           if(obj1.length<obj2.length){
               return NSOrderedDescending;
           }else{
               return NSOrderedAscending;
           }
       }];
      NSInteger length = [[tmpTexts firstObject] length];
       
       NSString *fountName = [RDHelpClass customFontArrayWithPath:[[[kAEJsonSubtitsPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Fount"] stringByAppendingPathComponent:config[@"fontSrc"]]][0];
       float fountsize;// = MIN((imageSize.width)/MAX(([config[@"maxNum"] intValue]/[config[@"lineNum"] intValue]),length), imageSize.height - 5);
       int lineNum = [config[@"lineNum"] intValue];
       if (lineNum == 0) {
           lineNum = 1;
       }
       if(([config[@"maxNum"] intValue]/lineNum)<length){
           fountsize = MIN((imageSize.width)/MAX(([config[@"maxNum"] intValue]/lineNum),length), imageSize.height - 5);
       }else{
           fountsize = MIN((imageSize.width)/MIN(([config[@"maxNum"] intValue]/lineNum),length), imageSize.height - 5);
       }
       label.font = [UIFont fontWithName:fountName size:fountsize];
       //[UIFont boldSystemFontOfSize:fountsize];
       //label.font = [UIFont boldSystemFontOfSize:(imageSize.width - 20)/([config[@"maxNum"] intValue]/[config[@"lineNum"] intValue])];
       
       if(label.italic){
           CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
           UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:label.font.fontName matrix:matrix];
           label.font = [UIFont fontWithDescriptor:desc size:fountsize];
       }
       CGSize s = label.bounds.size;
       // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
       UIGraphicsBeginImageContextWithOptions(s, NO, 1);//[UIScreen mainScreen].scale
       [label.layer renderInContext:UIGraphicsGetCurrentContext()];
       
       image = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
       unlink([resultPath UTF8String]);
       BOOL suc = [UIImagePNGRepresentation(image) writeToFile:resultPath atomically:YES];
       if(suc){NSLog(@"保存图片成功");}else{
           NSLog(@"失败");
       }
    }
}
- (void)saveSubtitleTitleAction{
    [self saveSubtitleTitleWithContent:self.subtitleContentTextView.text withEffect:lastThemeMVIndex needRefresh:YES];
}
- (void)saveSubtitleTitleWithContent:(NSString *)contentText withEffect:(Effect)effect needRefresh:(BOOL)needPlay{
    
    [self.subtitleContentTextView resignFirstResponder];
    if(needPlay)
    [self subtitleContentTextView_text:contentText index:effect];
    
    NSString *folderName = @"";
    NSString *item =(Current_VideoResolvPowerType == VideoResolvPower_Film ? @"16-9" : (Current_VideoResolvPowerType == VideoResolvPower_Square ? @"1-1" : @"9-16"));
    
    
    if(effect == Effect_Lapse){
        folderName = @"Lapse";
    }else if(effect == Effect_Slice){
        folderName = @"Slice";
    }else if(effect == Effect_Serene){
        folderName = @"Serene";
    }else if(effect == Effect_Flick){
        folderName = @"Flick";
    }else if(effect == Effect_Raw){
        folderName = @"Raw";
    }else if(effect == Effect_Epic){
        folderName = @"Epic";
    }else if(effect == Effect_Light){
        folderName = @"Light";
    }else if(effect == Effect_Sunny){
        folderName = @"Sunny";
    }else if(effect == Effect_Jolly){
        folderName = @"Jolly";
    }else if(effect == Effect_Snappy){
        folderName = @"Snappy";
    }else if(effect == Effect_Tinted){
        folderName = @"Serene1";
    }else if(effect == Effect_Boxed){
        folderName = @"Boxed";
    }else if(effect == Effect_Action){
        folderName = @"Action";
    }else{
        folderName = @"Grammy";
    }
    
    NSString *configPath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",folderName,item]];
    NSString *upPath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update",folderName]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:upPath]){
        [[NSFileManager defaultManager] removeItemAtPath:upPath error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:upPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    if(effect != Effect_Action && effect != Effect_Boxed){
        NSString *linePath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update/line",folderName]];
        NSError *error = nil;
        BOOL suc = [[NSFileManager defaultManager] copyItemAtPath:[[configPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] toPath:linePath error:&error];
        if(!suc){
            NSLog(@"拷贝文件失败");
        }else
            [self lineViewToImg:configPath folderName:folderName itemPath:linePath contenttext:contentText];
        

    }else if(effect == Effect_Action){
        //contentText = [contentText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSArray *textArray = [contentText componentsSeparatedByString:@"\n"];
        
        for (NSInteger k = 0;k<textArray.count;k++) {
            
            NSString *content = textArray[k];
            NSString *linePath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update/line_%zd",folderName,k]];
            BOOL suc = [[NSFileManager defaultManager] copyItemAtPath:[[configPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] toPath:linePath error:nil];
            if(!suc){
                NSLog(@"拷贝文件失败");
            }else
                [self lineViewToImg:configPath folderName:folderName itemPath:linePath contenttext:content];
        }
        
//        NSString *linePath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update/line_%zd",folderName,k]];
//        NSRange rang = NSMakeRange(contentText.length - len, len);
//        NSString *content = [contentText substringWithRange:rang];
//        BOOL suc = [[NSFileManager defaultManager] copyItemAtPath:[[configPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] toPath:linePath error:nil];
//        if(!suc){
//            NSLog(@"拷贝文件失败");
//        }else
//        [self lineViewToImg:configPath folderName:folderName itemPath:linePath contenttext:content];
        
        
    }else if(effect == Effect_Boxed){
        
        folderName = @"Boxed";
        //contentText = [contentText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSArray *textArray = [contentText componentsSeparatedByString:@"\n"];
//        NSMutableArray *textArray = [[NSMutableArray alloc] init];
//        NSInteger len = 0;
//        NSInteger k = 0;
//        NSInteger maxValue = [jsonTextContentObjects[k][@"maxNum"] integerValue];
//        while (contentText.length > maxValue) {
//
//            [textArray addObject:[contentText substringToIndex:maxValue]];
//            contentText = [contentText substringFromIndex:maxValue];
//            len += maxValue;
//            k += 1;
//            maxValue = [jsonTextContentObjects[k][@"maxNum"] integerValue];
//
//        }
//
//        [textArray addObject:contentText];
        

        
        NSString *linePath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update/line",folderName]];
        
        BOOL suc = [[NSFileManager defaultManager] copyItemAtPath:[[configPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] toPath:linePath error:nil];
        if(!suc){
            NSLog(@"拷贝文件失败");
        }
        
        NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:linePath error:nil];
        for (int k = 0; k<items.count; k++) {
            
            NSString *tmpDataPath = [[linePath stringByAppendingPathComponent: items[k]] stringByAppendingPathComponent: @"data.json"];
            
            NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:tmpDataPath]];
            NSMutableDictionary * config;
            NSDictionary        *textstings;
            if(data){
                NSError *err;
                config = [[NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingMutableContainers
                                                            error:&err] mutableCopy];
                float op = [config[@"op"] integerValue]/10.0* (textArray.count == 1 ? 1 : MAX(textArray.count,3));
                [config setObject:@(op) forKey:@"op"];
                textstings = config[@"textimg"];
            }
            if(config){
                unlink([tmpDataPath UTF8String]);
                [[self DataTOjsonString:config] writeToFile:tmpDataPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            
            NSString *ifolder = [[linePath stringByAppendingPathComponent:items[k]] stringByAppendingPathComponent:@"images"];
            if(textArray.count<10){
                for (int m = 0; m<(10 - textArray.count); m++) {
                    NSString *imagepath = [ifolder stringByAppendingPathComponent:[NSString stringWithFormat:@"img_%d.png",m]];
                    [[NSFileManager defaultManager] removeItemAtPath:imagepath error:nil];
                }
            }else if(textArray.count>10){
                textArray = [textArray subarrayWithRange:NSMakeRange(0, 10)];
            }
            for (NSInteger j = 0; j<textArray.count; j++) {
                
                NSDictionary *cfig =  textstings[@"text"][(j)];
                
                
                
                NSArray *textPadding =  cfig[@"textPadding"];
                BOOL italic = [cfig[@"italic"] boolValue];
                
                UIEdgeInsets textLableInsets = UIEdgeInsetsMake([textPadding[1] floatValue], [textPadding[0] floatValue], [textPadding[3] floatValue], [textPadding[2] floatValue]);
                
                NSArray *textColors = cfig[@"textColor"];
                float r = [textColors[0] floatValue]/255.0;
                float g = [textColors[1] floatValue]/255.0;
                float b = [textColors[2] floatValue]/255.0;
                //文字颜色
                UIColor *textColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
                
                //文字描边颜色
                NSArray *strokeColors = cfig[@"strokeColor"];
                UIColor *strokeColor =  [UIColor colorWithRed:[strokeColors[0] floatValue]/255.0
                                                        green:[strokeColors[1] floatValue]/255.0
                                                         blue:[strokeColors[2] floatValue]/255.0
                                                        alpha:1];
                
                float strokeWidth = [cfig[@"strokeWidth"] floatValue];
                
                //文字描边颜色
                NSArray *shadowColors = cfig[@"shadowColor"];
                UIColor *shadowColor =  [UIColor colorWithRed:[shadowColors[0] floatValue]/255.0
                                                        green:[shadowColors[1] floatValue]/255.0
                                                         blue:[shadowColors[2] floatValue]/255.0
                                                        alpha:1];
                
                
                
                
                
                NSString *imagepath = [ifolder stringByAppendingPathComponent:[NSString stringWithFormat:@"img_%ld.png",(9 - j)]];
                
                
                UIImage *image = nil;
                CGSize imageSize = CGSizeZero;
                imageSize = CGSizeMake([cfig[@"width"] floatValue], [cfig[@"height"] floatValue]);
                NSInteger fountsize = MIN((imageSize.width - 10)/([textArray[j] length]),imageSize.height - 10);//[cfig[@"fontSize"] intValue];
                
                SubtitleLabel *label = [[SubtitleLabel alloc] initWithFrame:CGRectMake((kWIDTH - imageSize.width)/2.0, 0, imageSize.width, imageSize.height)];
                
                label.numberOfLines = ([cfig[@"lineNum"] intValue] == 1 ? 1 : 0);
                label.adjustsFontSizeToFitWidth = YES;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment  = [cfig[@"alignment"] isEqualToString:@"center"] ? NSTextAlignmentCenter : ([cfig[@"alignment"] isEqualToString:@"right"] ? NSTextAlignmentRight : NSTextAlignmentLeft);
                label.italic         = italic;
                label.edgeInsets     = textLableInsets;
                label.shadowColor    = shadowColor;
                label.shadowOffset   = CGSizeMake(1, 1);
                label.strokeWidth    = strokeWidth;
                label.strokeColor    = strokeColor;
                label.txtColor      = textColor;
                label.text           = textArray[j];
                
                //NSArray *founts = [RDHelpClass customFontArrayWithPath:[[[kAEJsonSubtitsPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Fount"] stringByAppendingPathComponent:cfig[@"fontSrc"]]];
                NSString *fountName = @"";
                if([cfig[@"fontSrc"] length] >0){
                    fountName = [RDHelpClass customFontWithPath:[[[kAEJsonSubtitsPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Fount"] stringByAppendingPathComponent:cfig[@"fontSrc"]] fontName:cfig[@"textFont"]];
                }
                if(fountName.length>0){
                    label.font = [UIFont fontWithName:fountName size:fountsize];
                }else{
                    label.font = [UIFont boldSystemFontOfSize:fountsize];
                }
                
                label.adjustsFontSizeToFitWidth = YES;
                CGSize s = label.bounds.size;
                // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
                UIGraphicsBeginImageContextWithOptions(s, NO, 1);//[UIScreen mainScreen].scale
                [label.layer renderInContext:UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                unlink([imagepath UTF8String]);
                
                BOOL suc = [UIImagePNGRepresentation(image) writeToFile:imagepath atomically:YES];
                
                if(suc){NSLog(@"保存图片成功");}
                
            }
        }//for循环结束
        
    }
    
    if(needPlay){
        [self editSubtitleTitleAction:nil];
        [self refreshRdPlayer:rdPlayer];
    }
}

-(NSString*)DataTOjsonString:(id)object
{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}


- (void)editSubtitleTitleAction:(UIButton *)sender{
    if(self.subtitleContentBackView.alpha !=0){
        self.subtitleContentBackView.alpha = 0;
        if(sender){
            [self playVideo:YES];
        }
    }else{
        
        [self.subtitleContentTextView refreshContentSize];
        self.subtitleContentBackView.alpha = 1.0;
        [self.subtitleContentTextView becomeFirstResponder];
        if(sender){
            [self playVideo:NO];
        }
        
        self.subtitleContentTextView.text = [self subtitleContentTextView_text:nil index:lastThemeMVIndex];
    }
    
}

- (NSString *)subtitleContentTextView_text:(NSString *)setContentText index:(Effect)effect{
    if(setContentText){
        [piantouDicInfos setObject:setContentText forKey:@"piantouDicInfo"];
    }
    
#if 0
    NSString *text = @"";
    NSString *jsonpath = @"";
    NSString *item =(self->Current_VideoResolvPowerType == VideoResolvPower_Film ? @"16-9" : (self->Current_VideoResolvPowerType == VideoResolvPower_Square ? @"1-1" : @"9-16"));

    switch (effect) {
        case Effect_Grammy:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Grammy",item]];
            
        }
            break;
        case Effect_Action:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Action",item]];
        }
            break;
        case Effect_Boxed:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Boxed",item]];
            
        }
            break;
        case Effect_Lapse:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Lapse",item]];
            
        }
            break;
        case Effect_Slice:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Slice",item]];
        }
            break;
        case Effect_Serene:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Serene",item]];
        }
            break;
        case Effect_Flick:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Flick",item]];
        }
            break;
        case Effect_Raw:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Raw",item]];
        }
            break;
        case Effect_Epic:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Epic",item]];
        }
            break;
        case Effect_Light:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Light",item]];
            
        }
            break;
        case Effect_Sunny:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Sunny",item]];
        }
            break;
        case Effect_Jolly:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Jolly",item]];
        }
            break;
        case Effect_Snappy:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Snappy",item]];
        }
            break;
        case Effect_Tinted:
        {
            jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",@"Serene1",item]];
        }
            break;
        default:
            break;
    }
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
    if(data){
        NSError *err;
        NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&err];
        NSArray *texts = config[@"textimg"][@"text"];
        
        for (int i = 0; i<texts.count; i++) {
            NSString *str = [texts[i][@"textContent"] length] > 0 ? texts[i][@"textContent"] : texts[i][@"suggestion"];
            if(i == texts.count - 1){
                text = [text stringByAppendingString:([str length]>0 ? str : @"")];
            }else{
                text = [[text stringByAppendingString:([str length]>0 ? str : @"")] stringByAppendingString:@"\n"];
            }
        }
    }
    return [[piantouDicInfos allKeys] containsObject:@"piantouDicInfo"] ? piantouDicInfos[@"piantouDicInfo"] : text;
#else
    return [[piantouDicInfos allKeys] containsObject:@"piantouDicInfo"] ? piantouDicInfos[@"piantouDicInfo"] : RDLocalizedString(@"世界那么大\n因为有你而与众不同", nil);//
#endif
}
/**点击播放暂停按键
 */
- (void)tapPlayButton{
    [self playVideo:![rdPlayer isPlaying]];
}
//播放按钮切换
-(void) playVideo:(BOOL) play{
    if (!play) {
        //不加这个判断 疯狂切换音乐在低配机器上有可能反应不过来
#if 1
        [rdPlayer pause];
#else
        if ( [rdPlayer isPlaying] ) {
            [rdPlayer pause];
        }
#endif
        
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
                _playBtn.hidden = NO;
                [self playerToolbarShow];
            }
                break;
        }

    }
    else
    {
        if (rdPlayer.status != kRDVECoreStatusReadyToPlay || isResignActive) {
            return;
        }
        NSLog(@"%s line:%d",__func__,__LINE__);
        //不加这个判断，疯狂切换音乐在低配机器上有可能反应不过来
#if 1
        [rdPlayer play];
#else
        if(![rdPlayer isPlaying]){
            [rdPlayer play];
        }else{
            NSLog(@"[rdPlayer isPlaying] = YES");
        }
#endif
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                startPlayTime = rdPlayer.currentTime;
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
                [_addEffectsByTimeline.playBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateHighlighted];
            }
                break;
            default:
            {
                [_playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
                _playBtn.hidden = YES;
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
                [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
            }
                break;
        }
    }
}
#pragma mark- RDVECoreDelegate
- (void)statusChanged:(RDVECore *)sender status:(RDVECoreStatus)status {
    if(sender == rdPlayer){
        if (status == kRDVECoreStatusReadyToPlay) {
            [RDSVProgressHUD dismiss];
            [rdPlayer filterRefresh:kCMTimeZero];
            
            if (!isResignActive) {
                [self playVideo:YES];
            }
            
            if(selecteFunction != RDAdvanceEditType_Effect && selecteFunction != RDAdvanceEditType_Cover && selecteFunction != RDAdvanceEditType_Dubbing)
            {
                if (!isResignActive) {
                    [self playVideo:YES];
                }
            }
            else{
                if (CMTimeCompare(seekTime, kCMTimeZero) == 0) {
                    [self playVideo:YES];
                }else {
                    CMTime time = seekTime;
                    seekTime = kCMTimeZero;
                    __weak typeof(self) weakSelf = self;
                    [rdPlayer seekToTime:time toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
                        [weakSelf playVideo:YES];
                    }];
                }
            }
        }
    }
    else{
        if (status == kRDVECoreStatusReadyToPlay) {
            [thumbImageVideoCore filterRefresh:kCMTimeZero];
        }
    }
}

/**更新播放进度条
 */
- (void)progress:(RDVECore *)sender currentTime:(CMTime)currentTime{
    //- (void)progressCurrentTime:(CMTime)currentTime{

    if(sender == thumbImageVideoCore){
        return;
    }
    if([rdPlayer isPlaying]){
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
        float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
        [_videoProgressSlider setValue:progress];
        
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            {
                if (!CMTimeRangeEqual(kCMTimeRangeZero, playTimeRange)) {
                    if (CMTimeCompare(currentTime, CMTimeAdd(playTimeRange.start, playTimeRange.duration)) >= 0) {
                        [self playVideo:NO];
                        WeakSelf(self);
                        [rdPlayer seekToTime:playTimeRange.start toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                            [weakSelf.addEffectsByTimeline previewCompletion];
                        }];
                        float time = CMTimeGetSeconds(playTimeRange.start);
                        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(time, rdPlayer.duration)];
                        float progress = time/rdPlayer.duration;
                        [_videoProgressSlider setValue:progress];
                        _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:time];
                        playTimeRange = kCMTimeRangeZero;
                    }
                }else{
                    if(!_addEffectsByTimeline.trimmerView.videoCore) {
                        [_addEffectsByTimeline.trimmerView setVideoCore:thumbImageVideoCore];
                    }
                    [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
                    _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
                    if(_isAddingMaterialEffect){
                        BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
                        if(!suc){
                            [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                        }
                    }
                }
            }
                break;
            default:
                break;
        }
    }
    self.durationLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:rdPlayer.duration]];
    if([rdPlayer isPlaying]){
        self.currentTimeLabel.text = [RDHelpClass timeToStringFormat:MIN(CMTimeGetSeconds(currentTime), rdPlayer.duration)];
        float progress = CMTimeGetSeconds(currentTime)/rdPlayer.duration;
        [_videoProgressSlider setValue:progress];
        
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            case RDAdvanceEditType_Sticker:
            case RDAdvanceEditType_Dewatermark:
            case RDAdvanceEditType_Doodle:
            case RDAdvanceEditType_Collage:
            case RDAdvanceEditType_Multi_track:
            case RDAdvanceEditType_Sound:
            {
                if(!_addEffectsByTimeline.trimmerView.videoCore) {
                    [_addEffectsByTimeline.trimmerView setVideoCore:thumbImageVideoCore];
                }
                [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
                _addEffectsByTimeline.currentTimeLbl.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(currentTime)];
                if(_isAddingMaterialEffect){
                    BOOL suc = [_addEffectsByTimeline.trimmerView changecurrentCaptionViewTimeRange];
                    if(!suc){
                        [_addEffectsByTimeline finishEffectAction:_addEffectsByTimeline.finishBtn];
                    }
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)tapPlayerView{
        if(self.playerToolBar.hidden){
            if( selecteFunction != RDAdvanceEditType_Subtitle )
                self.playBtn.hidden = NO;
            [self playerToolbarShow];
        }else{
            self.playBtn.hidden = YES;
            [self playerToolbarHidden];
        }
}

/**播放结束
 */
- (void)playToEnd{
    [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Subtitle:
        {
            if(_isAddingMaterialEffect){
                [_addEffectsByTimeline saveSubtitle:YES];
            }else{
                [_addEffectsByTimeline.trimmerView setProgress:0 animated:NO];
            }
        }
            break;
        default:
            break;
    }
    [rdPlayer seekToTime:kCMTimeZero toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    [_videoProgressSlider setValue:0];
    [self.playProgress setProgress:0 animated:NO];
}

-(void)playerToolbarShow
{
    if( selecteFunction == RDAdvanceEditType_Subtitle )
        return;
    self.playerToolBar.hidden = NO;
    self.playProgress.hidden = YES;
    self.playBtn.hidden = NO;
    self.editSubtitleTitle.hidden = (!self.ThemeView.hidden ? NO : YES);
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerToolbarHidden) object:nil];
    [self performSelector:@selector(playerToolbarHidden) withObject:nil afterDelay:2];
}

- (void)playerToolbarHidden{
    [UIView animateWithDuration:0.25 animations:^{
        self.playerToolBar.hidden = YES;
        self.playBtn.hidden = YES;
        self.editSubtitleTitle.hidden = YES;
        self.playProgress.hidden = NO;
    }];
}

#pragma mark-播放设置
- (void)initPlayer{
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    if(!rdPlayer){
        rdPlayer = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                          APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                         LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                          videoSize:exportVideoSize
                                                fps:kEXPORTFPS
                                         resultFail:^(NSError *error) {
                                             NSLog(@"initError:%@", error.localizedDescription);
                                         }];
        [self.playerView insertSubview:self->rdPlayer.view belowSubview:self.playBtn];
    }
    if (!self->rdPlayer.view.superview) {
        [self.playerView insertSubview:self->rdPlayer.view belowSubview:self.playBtn];
    }
    [self performSelector:@selector(refreshRdPlayer:) withObject:rdPlayer afterDelay:0.1];
}
- (void)refreshRdPlayer:(RDVECore *)rdPlayer{
    __block typeof(self) bself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
//        if( rdPlayer.view.superview )
//            [rdPlayer.view removeFromSuperview];
        if(rdPlayer){
            [rdPlayer stop];
        }
        //rdPlayer = nil;
        [bself->themeclass setVideoSize:bself->exportVideoSize atEndTime:1.0];
        NSMutableArray *scenes = [NSMutableArray array];
        //设置主题效果
        [bself->themeclass SetVideoResolvPowerType: self->Current_VideoResolvPowerType];
        
        __block NSString *musicPath = @"";
        switch (bself->lastThemeMVIndex) {
            case Effect_Grammy:
                [bself->themeclass GetGrammyEffect:scenes];
                
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/The Pass - Colors" ofType:@"mp3"];
                break;
            case Effect_Action:
                [bself->themeclass GetActionEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Stefanie Heinzmann - Like A Bullet" ofType:@"mp3"];
                break;
            case Effect_Boxed:
                [bself->themeclass GetBoxedEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Kalimba" ofType:@"mp3"];
                break;
            case Effect_Lapse:
                [bself->themeclass GetLapseEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Pushim - Colors" ofType:@"mp3"];
                break;
            case Effect_Slice:
                [bself->themeclass GetSliceEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Sleep Away" ofType:@"mp3"];
                break;
            case Effect_Serene:
                [bself->themeclass GetSerene:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
                break;
            case Effect_Flick:
                [bself->themeclass GetFlick:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Kalimba" ofType:@"mp3"];
                break;
            case Effect_Raw:
                [bself->themeclass GetRawEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
                break;
            case Effect_Epic:
                [bself->themeclass GetEpicEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/The Pass - Colors" ofType:@"mp3"];
                break;
            case Effect_Light:
                [bself->themeclass GetActionEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/light/light" ofType:@"mp3"];
                break;
            case Effect_Sunny:
                [bself->themeclass GetSunnyEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
                break;
            case Effect_Jolly:
                [bself->themeclass GetJolly:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/tantan" ofType:@"mp3"];
                break;
            case Effect_Snappy:
                [bself->themeclass GetSnappyEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Denny White - Colors" ofType:@"mp3"];
                break;
            case Effect_Tinted:
                [bself->themeclass GetOverEffect:scenes];
                musicPath = [[RDHelpClass getBundle] pathForResource:@"assets/MP3/Sleep Away" ofType:@"mp3"];
                break;
                break;
            default:
                break;
        }
    
        [rdPlayer setEditorVideoSize:bself->exportVideoSize];
        rdPlayer.delegate = bself;
        float value1 = (self.playerView.frame.size.height-5);
        rdPlayer.frame = CGRectMake(0,(bself.playerView.frame.size.height - 5 - value1)/2.0, kWIDTH, value1);
        // [self.view addSubview:rdPlayer.view];
        
        NSMutableArray *jsonMVEffects = [[NSMutableArray alloc] init];
        NSString *folderName = @"";
        if(bself->lastThemeMVIndex == Effect_Grammy){
            folderName = @"Grammy";
        }else if(bself->lastThemeMVIndex == Effect_Action){
            folderName = @"Action";
        }else if(bself->lastThemeMVIndex == Effect_Boxed){
            folderName = @"Boxed";
        }else if(bself->lastThemeMVIndex == Effect_Lapse){
            folderName = @"Lapse";
        }else if(bself->lastThemeMVIndex == Effect_Slice){
            folderName = @"Slice";
        }else if(bself->lastThemeMVIndex == Effect_Serene){
            folderName = @"Serene";
        }else if(bself->lastThemeMVIndex == Effect_Flick){
            folderName = @"Flick";
        }else if(bself->lastThemeMVIndex == Effect_Raw){
            folderName = @"Raw";
        }else if(bself->lastThemeMVIndex == Effect_Epic){
            folderName = @"Epic";
        }else if(bself->lastThemeMVIndex == Effect_Light){
            folderName = @"Light";
        }else if(bself->lastThemeMVIndex == Effect_Sunny){
            folderName = @"Sunny";
        }else if(bself->lastThemeMVIndex == Effect_Jolly){
            folderName = @"Jolly";
        }else if(bself->lastThemeMVIndex == Effect_Snappy){
            folderName = @"Snappy";
        }else if(bself->lastThemeMVIndex == Effect_Tinted){
            folderName = @"Serene1";
        }
        
        
        NSString *resourcepath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/Resource",folderName]];
        
        NSArray *resourcefiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcepath error:nil];
        __block NSMutableArray *jsonpaths = [NSMutableArray array];
        [resourcefiles enumerateObjectsUsingBlock:^(NSString *  _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
            if([[[file pathExtension] lowercaseString] isEqualToString:@"json"]){
                [jsonpaths addObject:file];
            }else if([[[file pathExtension] lowercaseString] isEqualToString:@"mp3"]){
                musicPath = [resourcepath stringByAppendingPathComponent:file];
            }
        }];
        
        [jsonpaths sortUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
            if ([[obj1 stringByDeletingPathExtension] integerValue] > [[obj2 stringByDeletingPathExtension] integerValue]) { // obj1排后面
                return NSOrderedDescending;
            } else { // obj1排前面
                return NSOrderedAscending;
            }
        }];
        
        {
            NSString *item =(self->Current_VideoResolvPowerType == VideoResolvPower_Film ? @"16-9" : (self->Current_VideoResolvPowerType == VideoResolvPower_Square ? @"1-1" : @"9-16"));
            
            NSString *path = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update",folderName]];
            
            NSArray *anlis = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
            float duration = 0;
            
            
            if(anlis.count>0){
               anlis = [anlis sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
                    int num1 = [self returnNumInString:obj1];
                    int num2 = [self returnNumInString:obj2];
                    if(num1<num2){
                        return NSOrderedAscending;
                    }else{
                        return NSOrderedDescending;
                    }
                }];
                
                for(int i = 0 ;i<anlis.count;i++){
                    
                    if(bself->oldThemeMVIndex != bself->lastThemeMVIndex || bself->old_VideoResolvPowerType != bself->Current_VideoResolvPowerType){
                        bself->old_VideoResolvPowerType = bself->Current_VideoResolvPowerType;
                        bself->oldThemeMVIndex = bself->lastThemeMVIndex;
                        NSString *contentText = [self subtitleContentTextView_text:nil index:bself->lastThemeMVIndex];
                        [self saveSubtitleTitleWithContent:contentText withEffect:bself->lastThemeMVIndex needRefresh:NO];
                        [self refreshRdPlayer:rdPlayer];
                        return;
                    }
                    NSString *jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/update/%@/%@/data.json",folderName,anlis[i],item]];
                    
                    
                    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
                    
                    NSError *err;
                    NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:NSJSONReadingMutableContainers
                                                                                 error:&err];
                    float dur = [config[@"op"] floatValue]/[config[@"fr"] floatValue];
                    
                    if(![[self->piantouDicInfos allKeys] containsObject:@"piantouDicInfo"] || [self->piantouDicInfos[@"piantouDicInfo"] length]>0){
                        RDJsonAnimation *animation = [[RDJsonAnimation alloc] init];
                        animation.jsonPath = jsonpath;
                        animation.isJson1V1 = NO;
                        animation.ispiantou = YES;
                        animation.isRepeat = NO;
                        [jsonMVEffects addObject:animation];
                        duration +=dur;
                    }
                    
                }
            }else{
                
                for (int i = 0; i<3; i++) {
                    NSString *itemFolder =(i==1 ? @"16-9" : (i == 0 ? @"1-1" : @"9-16"));
                    {
                        NSString *jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",folderName,itemFolder]];
                        
                        NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
                        if(data){
                            NSError *err;
                            NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:NSJSONReadingMutableContainers
                                                                                      error:&err];
                            
                            
                            NSArray *assets = config[@"assets"];
                            NSArray *layers = config[@"layers"];
                            
                            
                            [layers enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull layer, NSUInteger lIdx, BOOL * _Nonnull lstop) {
                                if([layer[@"nm"] hasPrefix:@"ReplaceablePic"]){
                                    [assets enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull asset, NSUInteger aIdx, BOOL * _Nonnull astop) {
                                        if([layer[@"refId"] isEqualToString:asset[@"id"]]){
                                            NSString *scr = [asset[@"u"] stringByAppendingPathComponent:asset[@"p"]];
                                            float width = [asset[@"w"] floatValue];
                                            float height = [asset[@"h"] floatValue];
                                            
                                            *astop = YES;
                                            
                                            NSString *imagePath = [[jsonpath stringByDeletingLastPathComponent] stringByAppendingPathComponent:scr];
                                            
                                            
                                            unlink([imagePath UTF8String]);
                                            UIImage *image = [RDHelpClass getFullScreenImageWithUrl:self.fileList[0].contentURL];
                                            
                                            
                                            CGFloat sw = image.size.width;
                                            CGFloat sh = image.size.height;
                                            CGRect clipR = CGRectZero;
                                            if((sw/sh) > (width/height)){
                                                float w = sh*(width/height);
                                               clipR = CGRectMake((sw - w)/2.0, 0, w, sh);
                                            }else{
                                                float h = sw*(height/width);
                                               clipR = CGRectMake(0, (sh - h)/2.0, sw, h);
                                            }
                                            
                                            UIImage *image1 = [self imageByCropToRect:clipR source:image];
                                            [UIImageJPEGRepresentation(image1, 1) writeToFile:imagePath atomically:YES];
                                            
                                            
                                            
                                            
//                                            UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width, image.size.width * height/width), NO, 0);
//                                            UIBezierPath *clipRectPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, image.size.width, image.size.width * height/width)];
//                                            [clipRectPath addClip];
//                                            [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height* height/width)];
//                                            image = UIGraphicsGetImageFromCurrentImageContext();
//                                            UIGraphicsEndImageContext();
//                                            [UIImageJPEGRepresentation(image, 1) writeToFile:imagePath atomically:YES];
                                            
                                        }
                                    }];
                                }
                            }];
                        }
                    }
                }
                
                NSString *contentText = [self subtitleContentTextView_text:nil index:bself->lastThemeMVIndex];
                [self saveSubtitleTitleWithContent:contentText withEffect:bself->lastThemeMVIndex needRefresh:NO];
                [self refreshRdPlayer:rdPlayer];
                
                
            }
            
            bself->oldThemeMVIndex = bself->lastThemeMVIndex;
            
            
            if(jsonMVEffects.count>0 &&
               ((bself->lastThemeMVIndex == Effect_Grammy) ||
                (bself->lastThemeMVIndex == Effect_Boxed)  ||
                (bself->lastThemeMVIndex == Effect_Lapse) ||
                (bself->lastThemeMVIndex == Effect_Slice) ||
                (bself->lastThemeMVIndex == Effect_Serene) ||
                (bself->lastThemeMVIndex == Effect_Raw) ||
                (bself->lastThemeMVIndex == Effect_Epic) ||
                (bself->lastThemeMVIndex == Effect_Sunny) ||
                (bself->lastThemeMVIndex == Effect_Snappy))){
                
                if(duration>0){
                    RDScene * scene = [[RDScene alloc] init];
                    VVAsset* vvassetWhite = [[VVAsset alloc] init];
                    vvassetWhite.type = RDAssetTypeVideo;
                    vvassetWhite.videoFillType = RDVideoFillTypeFull;
                    vvassetWhite.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, 600));
                    vvassetWhite.speed        = 1;
                    vvassetWhite.volume       = 0;
                    vvassetWhite.rotate       = 0;
                    vvassetWhite.isVerticalMirror = NO;
                    vvassetWhite.isHorizontalMirror = NO;
                    vvassetWhite.crop = CGRectMake(0, 0, 1, 1);
                    vvassetWhite.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"27_b" Type:@"mp4"]];
                    vvassetWhite.startTimeInScene = kCMTimeZero;
                    scene.transition.type = RDVideoTransitionTypeFade;
                    scene.transition.duration = MIN(duration/2.0, 0.5);
                    [scene.vvAsset addObject:vvassetWhite];
                    [scenes insertObject:scene atIndex:0];
                }
                
            }
            
        }
        
        
        [rdPlayer setScenes:scenes];
        
        
        
        [rdPlayer addMVEffect:nil];
        [bself refreshCaptions];
        
        
        if(bself->lastThemeMVIndex == Effect_Light){
            
            NSMutableArray<VVMovieEffect *> * mvEffects = [[NSMutableArray alloc] init];
            double startTime = 0;
            VVMovieEffect *mvEffect = [[VVMovieEffect alloc] init];
            NSString *videoFilePath = [[RDHelpClass getBundle] pathForResource:@"assets/light/lightscreen" ofType:@"mp4"];
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoFilePath]];
            
            double duration = CMTimeGetSeconds(asset.duration);
            
            CMTimeRange showTimeRange=CMTimeRangeMake(CMTimeMakeWithSeconds(startTime,TIMESCALE), CMTimeMakeWithSeconds(duration,TIMESCALE));
            mvEffect.url = [NSURL fileURLWithPath:videoFilePath];
            mvEffect.timeRange = showTimeRange;
            mvEffect.shouldRepeat = YES;
            mvEffect.alpha = 0.2;
            mvEffect.type = RDVideoMVEffectTypeScreen;
            [mvEffects addObject:mvEffect];
            
            [rdPlayer addMVEffect:mvEffects];

        }else if(bself->lastThemeMVIndex == Effect_Jolly){
            
            for (int i = 0; i<jsonpaths.count; i++) {
                NSString *itemConfigPath = [resourcepath stringByAppendingPathComponent:jsonpaths[i]];
                
                RDJsonAnimation *animation = [[RDJsonAnimation alloc] init];
                animation.jsonPath = itemConfigPath;
                animation.isJson1V1 = YES;
                animation.isRepeat = YES;
                //animation.name = @"tantan";
                [jsonMVEffects addObject:animation];

            }
            
            
        }
        
        [rdPlayer setAeJsonMVEffects:jsonMVEffects];
        
  
        RDMusic *music = [[RDMusic alloc] init];
        music.url = [NSURL fileURLWithPath:musicPath];
        AVURLAsset *asset = [AVURLAsset assetWithURL:music.url];
        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        music.isFadeInOut = NO;
        [rdPlayer setMusics:[NSMutableArray arrayWithObject:music]];
        
        rdPlayer.enableAudioEffect = NO;
        
        [rdPlayer build];
        
        if (bself->globalFilters.count > 0) {
            [rdPlayer setGlobalFilter:bself->selectFilterIndex];
        }
        
        self.durationLabel.text = [NSString stringWithFormat:@"%@",[RDHelpClass timeToStringFormat:rdPlayer.duration]];
        if(!self.subtitleContentBackView.superview){
            [self.view addSubview:self.subtitleContentBackView];
        }
        [self.view bringSubviewToFront:self.subtitleContentBackView];
        
        [self updateSyncLayerPositionAndTransform];
        self.subtitleContentTextView.frame = CGRectMake(0, (self.contentBackView.frame.size.height - (kWIDTH*9.0/16.0))/2.0, kWIDTH, kWIDTH*9.0/16.0);
        self.subtitleTishiView.frame =CGRectMake(10, self.subtitleContentTextView.frame.origin.y - 20, 160, 20);
        
        NSInteger maxNum = 0;
        for (int i =0; i<self->jsonTextContentObjects.count; i++) {
            maxNum += [self->jsonTextContentObjects[i][@"maxNum"] intValue] + [bself->jsonTextContentObjects[i][@"lineNum"] intValue];
        }
        self.subtitleTishiView.tag = maxNum;
        
        UIColor *color = ([[self subtitleContentTextView_text:nil index:bself->lastThemeMVIndex] length] > (self.subtitleTishiView.tag - 5) ? [UIColor redColor] : [UIColor whiteColor]);
        NSString *str = @"";
        if(self.subtitleTishiView.tag >[self.subtitleContentTextView.text length]){
            str = [NSString stringWithFormat:@"%@(%zd)", RDLocalizedString(@"添加标题", nil),(self.subtitleTishiView.tag - [[self subtitleContentTextView_text:nil index:bself->lastThemeMVIndex] length])];
        }else{
            str = [NSString stringWithFormat:@"%@(-%zd)", RDLocalizedString(@"添加标题", nil),([[self subtitleContentTextView_text:nil index:bself->lastThemeMVIndex] length] - self.subtitleTishiView.tag)];
        }
        
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName:color, NSFontAttributeName : self.subtitleTishiView.font}];
        
        [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:[str rangeOfString:[NSString stringWithFormat:@"%@(", @"添加标题"]]];
        [attStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:[str rangeOfString:@")"]];
        self.subtitleTishiView.attributedText = attStr;
    });
}

- (UIImage *)imageByCropToRect:(CGRect)rect source:(UIImage *)image{
    rect.origin.x *= image.scale;
    rect.origin.y *= image.scale;
    rect.size.width *= image.scale;
    rect.size.height *= image.scale; // pt -> px (point -> pixel)
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    return newImage;
}

- (int)returnNumInString:(NSString *)str{
    NSScanner *scanner = [NSScanner scannerWithString:str];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
    int number;
    [scanner scanInt:&number];
    return number;
}




#pragma makr- keybordShow&Hidde
//手机键盘 显示
- (void)keyboardWillShow:(NSNotification *)notification{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    subtitleConfigViewRect = _addEffectsByTimeline.subtitleConfigView.frame;
    
    bottomViewFrame.origin.y = kHEIGHT - keyboardSize.height - 48;
    
    _addEffectsByTimeline.subtitleConfigView.frame = bottomViewFrame;
}
//手机键盘 隐藏
- (void)keyboardWillHide:(NSNotification *)notification{
    //    CGRect bottomViewFrame = _addEffectsByTimeline.subtitleConfigView.frame;
    //    bottomViewFrame.origin.y = subtitleView_Y;
    _addEffectsByTimeline.subtitleConfigView.frame = subtitleConfigViewRect;
}
- (void)initCommonAlertViewWithTitle:(NSString *)title
                             message:(NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(NSString *)otherButtonTitles
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

- (void)initProgressView {
    exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT)];
    [exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
    [exportProgressView setProgress:0 animated:NO];
    [exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
    [exportProgressView setTrackprogressTintColor:[UIColor whiteColor]];
    exportProgressView.canTouchUpCancel = YES;
    __weak typeof(self) weakself = self;
    exportProgressView.cancelExportBlock = ^(){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？", nil)
                                           message:nil
                                 cancelButtonTitle:RDLocalizedString(@"取消", nil)
                                 otherButtonTitles:RDLocalizedString(@"确定", nil)
                                      alertViewTag:5];
        });
        
    };
    [self.view addSubview:exportProgressView];
}

- (void)publishBtnAction:(UIButton *)sender {
    
    if(_addEffectsByTimeline && !_addEffectsByTimeline.trimmerView.rangeSlider.hidden )
    {
        [_addEffectsByTimeline finishEffectAction:nil];
        return;
    }
    
    if(selecteFunction == RDAdvanceEditType_Subtitle){
        if(_isEdittingMaterialEffect || _isAddingMaterialEffect){
            [_addEffectsByTimeline saveSubtitleTimeRange];
            CMTime time = [rdPlayer currentTime];
            [rdPlayer filterRefresh:time];
            self.isEdittingMaterialEffect = NO;
            self.isAddingMaterialEffect = NO;
            return;
        }
        [_addEffectsByTimeline discardEdit];
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        
        _addEffectsByTimeline.currentTimeLbl.hidden = NO;
        //        _addedMaterialEffectView.hidden = YES;
        _subtitleView.hidden = YES;
        _playerToolBar.hidden = NO;
        
        oldSubtitleFiles = [subtitleFiles mutableCopy];
        
        selecteFunction = RDAdvanceEditType_None;
        __weak typeof(self) myself = self;
        [self refreshRdPlayer:rdPlayer];
        [self clickMainTiemBtn:[self.MainMenuView viewWithTag:[[MainItems[0] objectForKey:@"id"] integerValue]]];
        stoolBarView.hidden = YES;
        return;
    }
    else{
        if(((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
           && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
            
            NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
            NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
            [hud setCaption:message];
            [hud show];
            [hud hideAfter:2];
            return;
        }
        if(((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
           && rdPlayer.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
            
            NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration)];
            NSString *message = [NSString stringWithFormat:@"%@。%@",[NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导出时长限制%@秒",nil),maxTime],RDLocalizedString(@"您可以关闭本提示去调整，或继续导出。",nil)];
            [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示",nil)
                                       message:message
                             cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                             otherButtonTitles:RDLocalizedString(@"继续",nil)
                                  alertViewTag:6];
            return;
        }
        [rdPlayer stop];
        [_playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [self initProgressView];
        [RDGenSpecialEffect addWatermarkToVideoCoreSDK:rdPlayer totalDration:rdPlayer.duration exportSize:exportVideoSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
        
        NSString *outputPath = ((RDNavigationViewController *)self.navigationController).outPath;
        if(!outputPath || outputPath.length == 0){
            outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
        }
        unlink([outputPath UTF8String]);
        idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        
        __weak typeof(self) weakSelf = self;
        [rdPlayer exportMovieURL:[NSURL fileURLWithPath:outputPath]
                            size:exportVideoSize
                         bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                             fps:kEXPORTFPS
                    audioBitRate:0
             audioChannelNumbers:1
          maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                        progress:^(float progress) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->exportProgressView setProgress:progress*100.0 animated:NO];
                            });
                        } success:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf exportMovieSuc:outputPath];
                            });
                        } fail:^(NSError *error) {
                            NSLog(@"导出失败:%@",error);
                            [weakSelf exportMovieFail];
                            
                        }];
    }
}

- (void)check{
    
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV || ((RDNavigationViewController *)self.navigationController).editConfiguration.enableMusic){
        [self clickMainTiemBtn:[self.MainMenuView viewWithTag:[[MainItems[0] objectForKey:@"id"] integerValue]]];
    }else{
        [self clickMainTiemBtn:[self.MainMenuView viewWithTag:3]];//点击滤镜
    }
}

- (void)exportMovieFail{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    [rdPlayer removeWaterMark];
    [rdPlayer removeEndLogoMark];
    [rdPlayer filterRefresh:kCMTimeZero];
}

- (void)exportMovieSuc:(NSString *)exportPath{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled];
    
    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
        ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
    }
    [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RDVECoreDelegate
- (void)statusChanged:(RDVECoreStatus)status {
    if (status == kRDVECoreStatusReadyToPlay) {
        _playBtn.enabled = YES;
    }
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 1:
            if(buttonIndex == 1){
                [rdPlayer cancelExportMovie:^{
                    //更新UI需在主线程中操作
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self cancelExportBlock];
                        //移除 “取消导出框”
                        [alertView dismissWithClickedButtonIndex:0 animated:YES];
                    });
                }];
                startAddSubtitle = NO;
                enterEditSubtitle = NO;
                unTouchSaveSubtitle = NO;
                
                titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];

                [_syncContainer removeFromSuperview];
                [self back:nil];
                //[self initPlayer:nil];
            }
            break;
            
        case 2:
            if(buttonIndex == 1){
                [self back:nil];
            }
            break;
            
        case 3:
            if(buttonIndex == 1){
                titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
//                self.playerView.frame = CGRectMake(0, iPhone4s ? 0 : (titleView.frame.origin.y + CGRectGetHeight(titleView.frame)), kWIDTH, kWIDTH + 5);
                [self back:nil];
            }
            break;
            
        case 4:
            if(buttonIndex == 1){
                UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
                if(!upView){
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
            break;
            
        case 5:
            if(buttonIndex == 1){
                [self cancelExportBlock];
                [rdPlayer cancelExportMovie:nil];
            }
            break;
        default:
            break;
    }
}

- (void)cancelExport{
    [exportProgressView removeFromSuperview];
    exportProgressView = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [rdPlayer cancelExportMovie:nil];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [rdPlayer stop];
    rdPlayer.delegate = nil;
    rdPlayer = nil;
    [thumbImageVideoCore stop];
    thumbImageVideoCore.delegate = nil;
    thumbImageVideoCore = nil;
    if (commonAlertView) {
        [commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark-压缩
#if 1
- (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption fileCount:(NSInteger)fileCount progress:(RDSectorProgressView *)progressView completionBlock:(void (^)(void))completionBlock
{
    
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    zip.fileCounts = fileCount;
    zip.delegate = self;
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES completionProgress:^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(progressView){
                    [progressView setProgress:progress];
                }
            });
            
        }];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            
            unlink([zipPath UTF8String]);
            
        }
        [zip RDUnzipCloseFile];
        completionBlock();
        
    }
    
    
}

- (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption
{
    //dispatch_async(dispatch_get_main_queue(), ^{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            
            unlink([zipPath UTF8String]);
            
        }
        [zip RDUnzipCloseFile];
    }
    //});
    
    
}

- (BOOL)OpenZipp:(NSString*)zipPath  unzipto:(NSString*)_unzipto
{
    
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        //NSInteger index =0;
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            
            unlink([zipPath UTF8String]);
            
        }
        [zip RDUnzipCloseFile];
        return YES;
    }
    return NO;
}

#endif

#pragma mark- scrollViewChildItemDelegate
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item{
    __weak typeof(self) myself = self;
    //主题
    if(item.type == 0)
    {
        [_CurrentThememvMV setSelected:NO];
        lastThemeMVIndex = item.tag;
        
        NSString *folderName = @"";
        if(lastThemeMVIndex == Effect_Grammy){
            folderName = @"Grammy";
        }else if(lastThemeMVIndex == Effect_Action){
            folderName = @"Action";
        }else if(lastThemeMVIndex == Effect_Boxed){
            folderName = @"Boxed";
        }else if(lastThemeMVIndex == Effect_Lapse){
            folderName = @"Lapse";
        }else if(lastThemeMVIndex == Effect_Slice){
            folderName = @"Slice";
        }else if(lastThemeMVIndex == Effect_Serene){
            folderName = @"Serene";
        }else if(lastThemeMVIndex == Effect_Flick){
            folderName = @"Flick";
        }else if(lastThemeMVIndex == Effect_Raw){
            folderName = @"Raw";
        }else if(lastThemeMVIndex == Effect_Epic){
            folderName = @"Epic";
        }else if(lastThemeMVIndex == Effect_Light){
            folderName = @"Light";
        }else if(lastThemeMVIndex == Effect_Sunny){
            folderName = @"Sunny";
        }else if(lastThemeMVIndex == Effect_Jolly){
            folderName = @"Jolly";
        }else if(lastThemeMVIndex == Effect_Snappy){
            folderName = @"Snappy";
        }else if(lastThemeMVIndex == Effect_Tinted){
            folderName = @"Serene1";
        }
        
        NSString *itemFolder =(self->Current_VideoResolvPowerType == VideoResolvPower_Film ? @"16-9" : (self->Current_VideoResolvPowerType == VideoResolvPower_Square ? @"1-1" : @"9-16"));
        
        NSString *jsonpath = [kAEJsonSubtitsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/orgin/%@/data.json",folderName,itemFolder]];
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:jsonpath]];
        if(data){
            NSError *err;
            NSDictionary * config = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:NSJSONReadingMutableContainers
                                                                      error:&err];
            jsonTextContentObjects = config[@"textimg"][@"text"];
        }
        
        
        [self initPlayer];
        [item setSelected:YES];
        _CurrentThememvMV = item;
        
        [_playBtn setHidden:NO];
        [_playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    }
    else if(item.type == 2){
        //滤镜
        if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
            NSDictionary *obj = self.filtersName[item.tag - 1];
            NSInteger selectIndex = item.tag - 1;
            NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
            if(selectIndex == 0){
                [((ScrollViewChildItem *)[self.filterChildsView viewWithTag:selectFilterIndex+1]) setSelected:NO];
                [item setSelected:YES];
                self->selectFilterIndex = item.tag-1;
                [self->rdPlayer setGlobalFilter:self->selectFilterIndex];
                if(![self->rdPlayer isPlaying]){
                    [self->rdPlayer filterRefresh:self->rdPlayer.currentTime];
                    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                    [self playVideo:YES];
                }
                return ;
            }
            //                NSString *file = [[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[obj[@"file"] lastPathComponent] stringByDeletingPathExtension]];
            //                filterPath = [filterPath stringByAppendingPathComponent:file];
            //                NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:filterPath error:nil] count];
            
            NSString *itemPath = [[[filterPath stringByAppendingPathComponent:obj[@"name"]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
            if([[NSFileManager defaultManager] fileExistsAtPath:itemPath]){
                [((ScrollViewChildItem *)[self.filterChildsView viewWithTag:self->selectFilterIndex+1]) setSelected:NO];
                [item setSelected:YES];
                self->selectFilterIndex = item.tag-1;
                [self->rdPlayer setGlobalFilter:self->selectFilterIndex];
                if(![self->rdPlayer isPlaying]){
                    [self->rdPlayer filterRefresh:self->rdPlayer.currentTime];
                    //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                    [self playVideo:YES];
                }
                return ;
            }
            __block CircleView *ddprogress;
            CGRect rect = [item getIconFrame];
            ddprogress = [[CircleView alloc]initWithFrame:rect];
            item.downloading = YES;
            [((ScrollViewChildItem *)[self.filterChildsView viewWithTag:self->selectFilterIndex+1]) setSelected:NO];
        
            ddprogress.progressColor = Main_Color;
            ddprogress.progressWidth = 2.f;
            ddprogress.progressBackgroundColor = [UIColor clearColor];
            [item addSubview:ddprogress];
        
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RDDownTool *tool = [[RDDownTool alloc] initWithURLPath:obj[@"file"] savePath:itemPath];
                tool.Progress = ^(float numProgress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ddprogress setPercent:numProgress];
                    });
                };
                
                tool.Finish = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ddprogress removeFromSuperview];
                        item.downloading = NO;
                        if([myself downLoadingFilterCount]>=1){
                            return ;
                        }
                        [self.filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if([obj isKindOfClass:[ScrollViewChildItem class]]){
                                
                                [(ScrollViewChildItem *)obj setSelected:NO];
                            }
                        }];
                        [item setSelected:YES];
                        self->selectFilterIndex = item.tag-1;
                        ((RDFilter *)self->globalFilters[self->selectFilterIndex]).filterPath = itemPath;
                        
                        [self->rdPlayer setGlobalFilter:self->selectFilterIndex];
                        
                        if(![self->rdPlayer isPlaying]){
                            [self->rdPlayer filterRefresh:self->rdPlayer.currentTime];
                            //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                            [self playVideo:YES];
                        }
                    });
                };
                [tool start];
            });
            
        }else{
            [((ScrollViewChildItem *)[self.filterChildsView viewWithTag:self->selectFilterIndex+1]) setSelected:NO];
            [item setSelected:YES];
            self->selectFilterIndex = item.tag-1;
            [self->rdPlayer setGlobalFilter:0];
            
            [self->rdPlayer setGlobalFilter:self->selectFilterIndex];
            
            if(![self->rdPlayer isPlaying]){
                [self->rdPlayer filterRefresh:self->rdPlayer.currentTime];
                //emmet 20171026 修复 “切换滤镜效果视频暂停” bug
                [self playVideo:YES];
            }
        }
        
    }
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
//分辨率调整后，字幕等的大小也要做相应的调整
- (void)refreshCaptionsEtcSize:(CGSize)newVideoSize array:(NSMutableArray<RDCaption*>*)array {
    CGSize oldVideoActualSize = AVMakeRectWithAspectRatioInsideRect(exportVideoSize, _playerView.bounds).size;
    float  oldScale =    exportVideoSize.width/oldVideoActualSize.width;
    CGSize newVideoActualSize = AVMakeRectWithAspectRatioInsideRect(newVideoSize, _playerView.bounds).size;
    float  newScale = newVideoSize.width/newVideoActualSize.width;
    
    for (RDCaption *caption in array) {
        CGSize size = CGSizeMake(caption.size.width * exportVideoSize.width / oldScale, caption.size.height * exportVideoSize.height / oldScale);
        caption.size = CGSizeMake(size.width * newScale / newVideoSize.width, size.height * newScale / newVideoSize.height);
        float fontSize = caption.tFontSize/oldScale;
        caption.tFontSize = fontSize * newScale;
        
        CGRect textRect = CGRectMake(caption.tFrame.origin.x / oldScale, caption.tFrame.origin.y / oldScale, caption.tFrame.size.width / oldScale, caption.tFrame.size.height / oldScale);
        caption.tFrame = CGRectMake(textRect.origin.x * newScale, textRect.origin.y * newScale, textRect.size.width * newScale, textRect.size.height * newScale);
    }
}
#pragma mark- 字幕
#pragma mark - RDAddEffectsByTimelineDelegate
- (void)pauseVideo {
    [self playVideo:NO];
}

- (void)playOrPauseVideo {
    [self playVideo:![rdPlayer isPlaying]];
}

- (void)previewWithTimeRange:(CMTimeRange)timeRange {
    playTimeRange = timeRange;
    [self playVideo:YES];
}

- (void)changeCurrentTime:(float)currentTime {
    if(![rdPlayer isPlaying]){
        WeakSelf(self);
        [rdPlayer seekToTime:CMTimeMakeWithSeconds(currentTime, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:^(BOOL finished) {
            StrongSelf(self);
            float duration = strongSelf->rdPlayer.duration;
            if(CMTimeGetSeconds(strongSelf->startPlayTime)>= CMTimeGetSeconds(CMTimeSubtract(CMTimeMakeWithSeconds(duration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE)))){
                [strongSelf playVideo:YES];
            }
        }];
    }
}

- (void)addMaterialEffect {
    
    backBtn.hidden = YES;
    publishBtn.hidden = YES;
    
    if( [rdPlayer isPlaying] )
        [self playVideo:NO];
    switch (selecteFunction) {
        case RDAdvanceEditType_Subtitle:
            //            [self ToolBarViewShowOhidden:YES];
            self.isAddingMaterialEffect = YES;
            break;
        default:
            break;
    }
    //    _addedMaterialEffectView.hidden = YES;
    //    [self ToolBarViewShowOhidden:NO];
}

- (void)addingStickerWithDuration:(float)addingDuration  captionId:(int ) captionId{
    NSMutableArray *arry = [[NSMutableArray alloc] initWithArray:subtitles];
    rdPlayer.captions = arry;
    if(![rdPlayer isPlaying]){
        _addEffectsByTimeline.trimmerView.isTiming = YES;
//        [self playVideo:YES];
    }
    [self addedMaterialEffectItemBtnAction:[addedMaterialEffectScrollView viewWithTag:captionId]];
}

- (void)cancelMaterialEffect {
    backBtn.hidden = NO;
    publishBtn.hidden = NO;
    self.isCancelMaterialEffect = YES;
    [self deleteMaterialEffect];
    self.isCancelMaterialEffect = NO;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    if (selecteFunction == RDAdvanceEditType_Subtitle) {
        //        [self ToolBarViewShowOhidden:NO];
    }
}

- (void)deleteMaterialEffect {
    backBtn.hidden = NO;
    publishBtn.hidden = NO;
    [self playVideo:NO];
    if (!_isCancelMaterialEffect) {
        seekTime = rdPlayer.currentTime;
    }
    
    if (_isCancelMaterialEffect) {
        seekTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(_addEffectsByTimeline.trimmerView.currentCaptionView.file.timeRange.start) + _addEffectsByTimeline.trimmerView.piantouDuration,TIMESCALE);
    }
    BOOL suc = [_addEffectsByTimeline.trimmerView deletedcurrentCaption];
    BOOL isAddedMaterialEffectScrollViewShow = NO;
    if(suc){
        NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
            {
                [subtitles removeAllObjects];
                [subtitleFiles removeAllObjects];
                
                for(CaptionRangeView *view in arr){
                    RDCaption *subtitle = view.file.caption;
                    if(subtitle){
                        [subtitles addObject:subtitle];
                        [subtitleFiles addObject:view.file];
                    }
                }
                isAddedMaterialEffectScrollViewShow = subtitles.count;
                [self refreshCaptions];
                CMTime time = [rdPlayer currentTime];
                [rdPlayer filterRefresh:time];
            }
                break;
            default:
                break;
        }
    }else{
        NSLog(@"删除失败");
    }
    float progress = CMTimeGetSeconds(seekTime)/rdPlayer.duration;
    [_addEffectsByTimeline.trimmerView setProgress:progress animated:NO];
    [self refreshAddMaterialEffectScrollView];
    selectedMaterialEffectItemIV.hidden = YES;
    self.isAddingMaterialEffect = NO;
    self.isEdittingMaterialEffect = NO;
    self.isCancelMaterialEffect = NO;
    
    if (isAddedMaterialEffectScrollViewShow) {
        //        _addedMaterialEffectView.hidden = NO;
        //        [self ToolBarViewShowOhidden:YES];
    }else {
        //        _addedMaterialEffectView.hidden = YES;
        //        [self ToolBarViewShowOhidden:NO];
    }
    //    [self ToolBarViewShowOhidden:NO];
}

- (void)updateMaterialEffect:(NSMutableArray *)newEffectArray
                newFileArray:(NSMutableArray *)newFileArray
                isSaveEffect:(BOOL)isSaveEffect
{
    if( isSaveEffect )
    {
        backBtn.hidden = NO;
        publishBtn.hidden = NO;
    }
    else{
        if( !backBtn.hidden )
        {
            if( _addEffectsByTimeline.trimmerView.rangeSlider.hidden )
            {
                backBtn.hidden = YES;
                publishBtn.hidden = YES;
            }
        }
        else
        {
            backBtn.hidden = NO;
            publishBtn.hidden = NO;
        }
    }
    _isAddingMaterialEffect = NO;
    _addEffectsByTimeline.currentTimeLbl.hidden = NO;
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    //    if (!cancelBtn.selected) {
    //        isModifiedMaterialEffect = YES;
    //    }
    if (!_isCancelMaterialEffect) {
        seekTime = rdPlayer.currentTime;
    }
    float time = CMTimeGetSeconds(seekTime);
    if (time >= rdPlayer.duration) {
        seekTime = kCMTimeZero;
    }
    self.addedMaterialEffectView.hidden = NO;
    switch (selecteFunction) {
        case RDAdvanceEditType_Subtitle:
        {
            if (!subtitles) {
                subtitles = [NSMutableArray array];
            }
            if (!subtitleFiles) {
                subtitleFiles = [NSMutableArray array];
            }
            seekTime = kCMTimeZero;
            [self refreshMaterialEffectArray:subtitles newArray:newEffectArray];
            [self refreshMaterialEffectArray:subtitleFiles newArray:newFileArray];
            [self refreshCaptions];
            //            [self ToolBarViewShowOhidden:NO];
            CMTime time = [rdPlayer currentTime];
            [rdPlayer filterRefresh:time];
            [_addEffectsByTimeline.trimmerView setProgress:(CMTimeGetSeconds(time)/rdPlayer.duration) animated:NO];
        }
            break;
        default:
            break;
    }
    [self refreshAddMaterialEffectScrollView];
    if (isSaveEffect) {
        [_addEffectsByTimeline.syncContainer removeFromSuperview];
        selectedMaterialEffectItemIV.hidden = YES;
        self.isAddingMaterialEffect = NO;
        self.isEdittingMaterialEffect = NO;
    }
    if (!_isEdittingMaterialEffect) {
        if (newEffectArray.count == 0) {
            //            _addedMaterialEffectView.hidden = YES;
            //            [self ToolBarViewShowOhidden:NO];
        }else {
            //            _addedMaterialEffectView.hidden = NO;
            //            [self ToolBarViewShowOhidden:YES];
        }
    }
}

- (void)refreshMaterialEffectArray:(NSMutableArray *)oldArray newArray:(NSMutableArray *)newArray {
    [oldArray removeAllObjects];
    [newArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [oldArray addObject:obj];
    }];
}

- (void)pushOtherAlbumsVC:(UIViewController *)otherAlbumsVC {
    [self.navigationController pushViewController:otherAlbumsVC animated:YES];
}

-(void)TimesFor_videoRangeView_withTime:(int)captionId
{
    [addedMaterialEffectScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[RDAddItemButton class]]) {
            RDAddItemButton * addItemBtn = (RDAddItemButton*) obj;
            addItemBtn.redDotImageView.hidden = YES;
        }
    }];
    
    NSMutableArray *array = [_addEffectsByTimeline.trimmerView getCaptionsViewForcurrentTime:NO];
    
    if( array && (array.count > 0)  )
    {
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CaptionRangeView * rangeV = (CaptionRangeView*)obj;
            for (int i = 0; i < addedMaterialEffectScrollView.subviews.count; i++) {
                UIView * obj = addedMaterialEffectScrollView.subviews[i];
                
                if ([obj isKindOfClass:[RDAddItemButton class]]) {
                    RDAddItemButton * addItemBtn = (RDAddItemButton*) obj;
                    if( (rangeV.file.captionId == addItemBtn.tag) && ( addItemBtn.tag != _addEffectsByTimeline.trimmerView.currentCaptionView ) )
                    {
                        addItemBtn.redDotImageView.hidden = NO;
                        break;
                    }
                }
                
            }
        }];
    }
}
- (void)refreshAddMaterialEffectScrollView {
    
    if( !addedMaterialEffectScrollView )
    {
        self.addedMaterialEffectView.hidden = NO;
    }
    
    [addedMaterialEffectScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *__strong arr = [_addEffectsByTimeline.trimmerView getTimesFor_videoRangeView_withTime];
    BOOL isNetSource = ((RDNavigationViewController *)self.navigationController).editConfiguration.subtitleResourceURL.length>0;
    NSInteger index = 0;
    for (int i = 0; i < arr.count; i++) {
        CaptionRangeView *view = arr[i];
        BOOL isHasMaterialEffect = NO;
        switch (selecteFunction) {
            case RDAdvanceEditType_Subtitle:
                if (view.file.caption) {
                    isHasMaterialEffect = YES;
                }
                if (_isAddingMaterialEffect && selecteFunction == RDAdvanceEditType_Subtitle && view == _addEffectsByTimeline.trimmerView.currentCaptionView) {
                    index = view.file.captionId;
                }
                break;
            default:
                break;
        }
        if (isHasMaterialEffect) {
            RDAddItemButton *addedItemBtn = [RDAddItemButton buttonWithType:UIButtonTypeCustom];
            addedItemBtn.frame = CGRectMake((view.file.captionId-1) * 50, (44 - 40)/2.0, 40, 40);
            if (selecteFunction == RDAdvanceEditType_Subtitle ) {
                UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0/2.0, (40 - 25.0)/2.0, 25.0, 25.0)];
                if(isNetSource){
                    [imageView rd_sd_setImageWithURL:[NSURL URLWithString:view.file.netCover]];
                }else{
                    NSString *iconPath;
                    if (selecteFunction == RDAdvanceEditType_Subtitle) {
                        iconPath = [NSString stringWithFormat:@"%@/%@.png",kSubtitleIconPath,view.file.caption.imageName];
                    }
                    UIImage *image = [UIImage imageWithContentsOfFile:iconPath];
                    imageView.image = image;
                }
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [addedItemBtn addSubview:imageView];
            }
            addedItemBtn.tag = view.file.captionId;
            [addedItemBtn addTarget:self action:@selector(addedMaterialEffectItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            addedItemBtn.redDotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(addedItemBtn.frame.size.width - addedMaterialEffectScrollView.bounds.size.height/6.0, addedMaterialEffectScrollView.bounds.size.height - addedMaterialEffectScrollView.bounds.size.height/2.0, addedMaterialEffectScrollView.bounds.size.height/6.0, addedMaterialEffectScrollView.bounds.size.height/6.0)];
            
            addedItemBtn.redDotImageView.backgroundColor = [UIColor redColor];
            addedItemBtn.redDotImageView.layer.cornerRadius =  addedItemBtn.redDotImageView.frame.size.height/2.0;
            addedItemBtn.redDotImageView.layer.masksToBounds = YES;
            addedItemBtn.redDotImageView.layer.shadowColor = [UIColor redColor].CGColor;
            addedItemBtn.redDotImageView.layer.shadowOffset = CGSizeZero;
            addedItemBtn.redDotImageView.layer.shadowOpacity = 0.5;
            addedItemBtn.redDotImageView.layer.shadowRadius = 2.0;
            addedItemBtn.redDotImageView.clipsToBounds = NO;
            
            [addedItemBtn addSubview:addedItemBtn.redDotImageView];
            addedItemBtn.redDotImageView.hidden = YES;
            [addedMaterialEffectScrollView addSubview:addedItemBtn];
        }
    }
    [addedMaterialEffectScrollView setContentSize:CGSizeMake(addedMaterialEffectScrollView.subviews.count * 50, 0)];
    if (_isEdittingMaterialEffect) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    if (selecteFunction == RDAdvanceEditType_Subtitle && _isAddingMaterialEffect && !_isEdittingMaterialEffect) {
        selectedMaterialEffectIndex = index;
        _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
        UIButton *itemBtn = [addedMaterialEffectScrollView viewWithTag:index];
        CGRect frame = selectedMaterialEffectItemIV.frame;
        frame.origin.x = itemBtn.frame.origin.x + itemBtn.bounds.size.width - frame.size.width + 6;
        selectedMaterialEffectItemIV.frame = frame;
        selectedMaterialEffectItemIV.hidden = NO;
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    
    if( arr.count > 0 )
    {
        //        _addedMaterialEffectView.hidden = NO;
        //        [self ToolBarViewShowOhidden:YES];
    }
    else
    {
        //        _addedMaterialEffectView.hidden = YES;
        //        [self ToolBarViewShowOhidden:NO];
    }
}

- (void)addedMaterialEffectItemBtnAction:(UIButton *)sender {
    if (!selectedMaterialEffectItemIV.hidden && sender.tag == selectedMaterialEffectIndex)
        return;
    
    if (rdPlayer.isPlaying) {
        [self playVideo:NO];
    }
    seekTime = rdPlayer.currentTime;
    selectedMaterialEffectIndex = sender.tag;
    _addEffectsByTimeline.currentMaterialEffectIndex = selectedMaterialEffectIndex;
    CGRect frame = selectedMaterialEffectItemIV.frame;
    frame.origin.x = sender.frame.origin.x + sender.bounds.size.width - frame.size.width + 6;
    selectedMaterialEffectItemIV.frame = frame;
    
    [_addEffectsByTimeline editAddedEffect];
    if (!selectedMaterialEffectItemIV.superview) {
        [addedMaterialEffectScrollView addSubview:selectedMaterialEffectItemIV];
    }
    selectedMaterialEffectItemIV.hidden = NO;
    //    _addedMaterialEffectView.hidden = NO;
    self.isEdittingMaterialEffect = YES;
    self.isAddingMaterialEffect = NO;
    CMTime time = [rdPlayer currentTime];
    [rdPlayer filterRefresh:time];
}
#pragma mark- 字幕、特效、配音截图
-(void)loadTrimmerViewThumbImage {
    @autoreleasepool {
        [thumbTimes removeAllObjects];
        thumbTimes = nil;
        thumbTimes=[[NSMutableArray alloc] init];
        Float64 duration;
        Float64 start;
        duration = thumbImageVideoCore.duration;
        start = (duration > 2 ? 1 : (duration-0.05));
        [thumbTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(start,TIMESCALE)]];
        NSInteger actualFramesNeeded = duration/2;
        Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
        /*截图为什么用两个for循环：第一个for循环是分配内存，第二个for循环显示图片，截图快一些*/
        for (int i=1; i<actualFramesNeeded; i++){
            CMTime time = CMTimeMakeWithSeconds(start + i*durationPerFrame,TIMESCALE);
            [thumbTimes addObject:[NSValue valueWithCMTime:time]];
        }
        [thumbImageVideoCore getImageWithTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2 completionHandler:^(UIImage *image) {
            if(!image){
                image = [thumbImageVideoCore getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                if (!image) {
                    image = [rdPlayer getImageAtTime:CMTimeMakeWithSeconds(start,TIMESCALE) scale:0.2];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (selecteFunction) {
                    case RDAdvanceEditType_Subtitle://MARK:字幕
                        [_addEffectsByTimeline loadTrimmerViewThumbImage:image
                                                          thumbnailCount:thumbTimes.count
                                                          addEffectArray:subtitles
                                                           oldFileArray:oldSubtitleFiles];
                        
                        if (subtitles.count == 0) {
                            //                            _addedMaterialEffectView.hidden = YES;
                        }else {
                            [self refreshAddMaterialEffectScrollView];
                            //                            _addedMaterialEffectView.hidden = NO;
                        }
                        break;
                    default:
                        break;
                }
                //NSLog(@"截图次数：%d",actualFramesNeeded);
                [self refreshTrimmerViewImage];
            });
        }];
    }
}
- (void)refreshTrimmerViewImage {
    @autoreleasepool {
        
        Float64 durationPerFrame = thumbImageVideoCore.duration / (thumbTimes.count*1.0);
        for (int i=0; i<thumbTimes.count; i++){
            CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame + 0.2,TIMESCALE);
            [thumbTimes replaceObjectAtIndex:i withObject:[NSValue valueWithCMTime:time]];
        }
        [self refreshThumbWithImageTimes:thumbTimes nextRefreshIndex:0 isLastArray:YES];
    }
}
- (void)refreshThumbWithImageTimes:(NSArray *)imageTimes nextRefreshIndex:(int)nextRefreshIndex isLastArray:(BOOL)isLastArray{
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        [thumbImageVideoCore getImageWithTimes:[imageTimes mutableCopy] scale:0.1 completionHandler:^(UIImage *image, NSInteger idx) {
            StrongSelf(self);
            if(!image){
                return;
            }
            NSLog(@"获取图片：%zd",idx);
            switch (selecteFunction) {
                case RDAdvanceEditType_Subtitle:
                case RDAdvanceEditType_Sticker:
                case RDAdvanceEditType_Dewatermark:
                case RDAdvanceEditType_Collage:
                case RDAdvanceEditType_Doodle:
                case RDAdvanceEditType_Multi_track:
                case RDAdvanceEditType_Sound:
                {
                    if(strongSelf.addEffectsByTimeline.trimmerView)
                        [strongSelf.addEffectsByTimeline.trimmerView refreshThumbImage:idx thumbImage:image];
                }
                    break;
                default:
                    break;
            }
            if(idx == imageTimes.count - 1)
            {
                if( strongSelf )
                    [strongSelf->thumbImageVideoCore stop];
                [RDSVProgressHUD dismiss];
            }
        }];
    }
}

@end
