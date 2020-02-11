//
//  RDCloudMusicItemViewController.m

#import "RDCloudMusicItemViewController.h"

#import "MusicRangeSlider_RD.h"
#import "RDHelpClass.h"
#import "CustomButton.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "RDATMHud.h"
#import "RDATMHudDelegate.h"
#import "RDFileDownloader.h"
#import "RDSectorProgressView.h"

#import "RDMJRefresh.h"
#import "UIView+RDMJExtension.h"
#import "RDMJDIYAutoFooter.h"

#define kTagOfTableView 100
#define kProgressViewTag 1000
#define kCellNormalHeight 50
#define kCellSelectHeight 137
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

static NSString *kCellIdentifier = @"kCellIdentifier";
@interface MusicTableCell : UITableViewCell
@property (nonatomic,assign)BOOL downloading;
@end

@implementation MusicTableCell

@end

@interface RDCloudMusicItemViewController ()<UITableViewDelegate,UITableViewDataSource,AVAudioPlayerDelegate,RDATMHudDelegate>
{
    float                       _customPreviewOrginx;
    NSMutableArray              *_libraryMusicArray;
    NSInteger                    _selectSection;
    NSIndexPath                 *_selectIndex;
    NSInteger                   _lastSelectMusicIndex;
    
    NSTimer                     *_audioProgressTimer;
    AVAudioPlayer               *_audioPlayer;
    UIView                      *_selectMusicView;
    UILabel                     *_lowerLabel;
    UILabel                     *_upperLabel;
    UIImageView                 *_lowerLabelBack;
    UIImageView                 *_upperLabelBack;
    MusicRangeSlider_RD         *_audioSlider;
    
    UIButton                    *_audioPlayButton;
    
    NSURL                       *_selectedMusicURL;
    NSString                    *_selectedMusicName;
    double                       _duration;
    
    UIButton                    *_leftBtn;
    UIButton                    *_rightBtn;
    
    UIAlertView                 *commonAlertView;
    NSMutableArray              *_downloaderparams;
    CGRect                      localmusicRect;
    
    int                         currentlocal_page;
    int last_page;
    int current_page;
    
    UILabel                      *showRefreshLabel;      //是否显示刷新
}
@property(nonatomic,strong)RDATMHud         *hud;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation RDCloudMusicItemViewController

- (void)viewDidLoad {
    _animationCount = ceilf( _fheight/kCellNormalHeight );
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self setupUI];
}

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:self];
        [self.view addSubview:_hud.view];
    }
    [self.view bringSubviewToFront:_hud.view];
    return _hud;
}

- (void)changeTitleIndexWithNotification{
    
    [_downloaderparams enumerateObjectsUsingBlock:^(RDFileDownloader *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    
    if(_isPlaying){
        [_audioPlayer stop];
    }
}
- (void)setupUI{
#if 0
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 100)];
    headerLabel.text = self.category;
    headerLabel.font = [UIFont boldSystemFontOfSize:40.f];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.tableHeaderView = headerLabel;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
#endif
    self.title = RDLocalizedString(@"本地音乐", nil);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTitleIndexWithNotification) name:@"changeTitleIndex" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTitleIndexWithNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    _selectIndex = nil;
    _selectSection = 0 ;
    current_page  =  1;
    currentlocal_page = 1;
    
    [self initSelectMusicView];
    
    localmusicRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 44 - 55 - 55);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.20*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{
        if( _vcIndex == 0 )
        {
            if( _isSound )
            {
                [self setSoundValue];
            }
        }
        //    else{
        if(_localMusicTableView.superview){
            [_localMusicTableView removeFromSuperview];
        }
        
        _localMusicTableView = [[UITableView alloc] initWithFrame:localmusicRect style:UITableViewStylePlain];
        
        //禁止回弹 （ 不会有拖过显示范围的情况出现 ）
        _localMusicTableView.bounces = NO;
        
        _localMusicTableView.backgroundColor    = [UIColor clearColor];
        _localMusicTableView.backgroundView     = nil;
        _localMusicTableView.delegate           = self;
        _localMusicTableView.dataSource         = self;
        _localMusicTableView.tag                = kTagOfTableView;
        _localMusicTableView.separatorStyle     = UITableViewCellAccessoryNone;
        _localMusicTableView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 11.0, *)) {
            _localMusicTableView.estimatedRowHeight = 0;
            _localMusicTableView.estimatedSectionFooterHeight = 0;
            _localMusicTableView.estimatedSectionHeaderHeight = 0;
        }
        if (iPhone_X) {
            _localMusicTableView.contentInset = UIEdgeInsetsMake(0, 0, 78, 0);
        }
        //    if( _vcIndex == 0 )
        //    {
        if( _isSound )
        {
            // 设置footer
            _localMusicTableView.mj_footer = [RDMJDIYAutoFooter footerWithRefreshingTarget:self refreshingAction:@selector(footerRereshing)];
        }
        
        if( _fheight )
        {
            _localMusicTableView.backgroundColor = TOOLBAR_COLOR;
           _localMusicTableView.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, _fheight);
        }
        [self.view addSubview:_localMusicTableView];
        
    });
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    _tableView.frame = self.view.bounds;
}

#if 1
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if( !_fheight )
        _localMusicTableView.frame = self.view.bounds;
    else
        _localMusicTableView.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, _fheight);
    
    if( _isSound )
    {
        [self setSoundValue];
    }
}

-(void)setSoundValue
{
    NSMutableArray *SooundMusicList = [[NSMutableArray alloc] init];
    //    last_page = -1;
    while ( current_page <= currentlocal_page ) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        if( !_isCloud )
            [params setObject:@"audio" forKey:@"type"];
        else
            [params setObject:@"cloud_music" forKey:@"type"];
        
        [params setObject:_id forKey:@"category"];
        [params setObject:[NSString stringWithFormat:@"%d" ,current_page] forKey: @"page_num"];
        NSDictionary *dic2 = [RDHelpClass getNetworkMaterialWithParams:params appkey:((RDNavigationViewController *)self.navigationController).appKey urlPath:_soundMusicResourceURL];
        if([[dic2 objectForKey:@"code"] integerValue] == 0)
        {
            NSMutableArray * currentSooundMusicList = nil;
            current_page =  [[dic2 objectForKey:@"data"][@"current_page"] intValue];
            last_page = [[dic2 objectForKey:@"data"][@"last_page"] intValue];
            
            if( last_page <=  currentlocal_page )
            {
                currentlocal_page = last_page;
            }
            
            if([[dic2 objectForKey:@"data"][@"data"] isKindOfClass:[NSArray class]])
            {
                currentSooundMusicList = [dic2 objectForKey:@"data"][@"data"];
                [SooundMusicList addObjectsFromArray:currentSooundMusicList];
                current_page++;
            }
        }
        [params removeAllObjects];
        params = nil;
    }
    NSMutableArray * array = nil;
    if( _sourceList )
        array = [NSMutableArray arrayWithArray:_sourceList];
    else
        array = [NSMutableArray new];
    [array addObjectsFromArray:SooundMusicList];
    _sourceList = nil;
    _sourceList = [NSArray arrayWithArray:array];
    
    
    
    [_localMusicTableView reloadData];
}

-(void)footerRereshing
{
    showRefreshLabel.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.20*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{
                       //刷新
                       if( current_page <= (last_page) )
                       {
                           currentlocal_page++;
                           [self setSoundValue];
                           [_localMusicTableView.mj_footer endRefreshing];
                       }
                       else
                            [_localMusicTableView.mj_footer endRefreshingWithNoMoreData];
                   });
}

- (void)appEnterNotification:(NSNotification *)notification{
    if(notification.name == UIApplicationDidEnterBackgroundNotification){
        if(_isPlaying){
            [self audioPlayOrPause];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 200){
        if(buttonIndex == 1){
            [RDHelpClass enterSystemSetting];
        }
    }
}

- (void)back{
    if (commonAlertView) {
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

/*完成选择添加*/
- (void)done{
    
    
    AVURLAsset *musicAsset=[self AudioDurationFromUrl:_selectedMusicURL];
    
    float duration =CMTimeGetSeconds([musicAsset duration]);
    
    CMTimeRange                 musicTimeRange;
    musicTimeRange.start   =CMTimeMakeWithSeconds(_audioSlider.lowerValue*duration, TIMESCALE);
    
    musicTimeRange.duration=CMTimeMakeWithSeconds((_audioSlider.upperValue - _audioSlider.lowerValue)*duration,TIMESCALE);
    
    
    
    NSLog(@"%@",_selectedMusicURL.path);
    
    RDMusic *music = nil;
    music = [[RDMusic alloc] init];
    music.clipTimeRange = musicTimeRange;//CMTimeRangeMake(kCMTimeZero, musicAsset.duration);
    music.url = musicAsset.URL;
    music.name = _selectedMusicName;
    music.isRepeat = YES;
    music.volume = 0.5;
    music.isFadeInOut = YES;
    NSLog(@"%lf || %lf",CMTimeGetSeconds(music.clipTimeRange.start),CMTimeGetSeconds(music.clipTimeRange.duration));
    [self stopPlayAudio];
    
    if(_musicItemDelegate){
        if([_musicItemDelegate respondsToSelector:@selector(getMusicFile:)]){
            [_musicItemDelegate getMusicFile:music];
        }
    }
    
}


#pragma mark- audioSliderTouchChange
/*开始滑动音乐进度条
 */
- (void)beginScrubbing:(MusicRangeSlider_RD *)slider{
    
    float startTime=_audioSlider.lowerValue*_audioSlider.durationValue;
    [_audioPlayer setCurrentTime:startTime];
    [_audioSlider progress:0];
    float endTime;
    endTime=_audioSlider.upperValue*_audioSlider.durationValue;
    NSString *stringStart = [NSString stringWithFormat:@"%02li:%02li",
                             lround(floor(startTime / 60.)) % 60,
                             lround(floor(startTime/1.)) % 60];
    
    NSString *stringStop=[NSString stringWithFormat:@"%02li:%02li",
                          lround(floor(endTime / 60.)) % 60,
                          lround(floor(endTime/1.)) % 60];
    
    [self updateSliderLabels:stringStart stop:stringStop];
    
    _lowerLabelBack.hidden = NO;
    [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    [_audioPlayer pause];
    _isPlaying=NO;
}

/*正在滑动音乐进度条
 */
- (void)scrub:(MusicRangeSlider_RD *)slider{
    
    float startTime=_audioSlider.lowerValue*_audioSlider.durationValue;
    [_audioPlayer setCurrentTime:startTime];
    [_audioSlider progress:0];
    float endTime;
    endTime=_audioSlider.upperValue*_audioSlider.durationValue;
    NSString *stringStart = [NSString stringWithFormat:@"%02li:%02li",
                             lround(floor(startTime / 60.)) % 60,
                             lround(floor(startTime/1.)) % 60];
    
    NSString *stringStop=[NSString stringWithFormat:@"%02li:%02li",
                          lround(floor(endTime / 60.)) % 60,
                          lround(floor(endTime/1.)) % 60];
    
    
    [self updateSliderLabels:stringStart stop:stringStop];
}

/*音乐进度条滑动结束
 */
- (void)endScrubbing:(MusicRangeSlider_RD *)slider{
    
    NSLog(@"播放时间%f",(_audioSlider.upperValue - _audioSlider.lowerValue)*_duration);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopPlayAudio) object:self];
    [self performSelector:@selector(stopPlayAudio) withObject:self afterDelay:(_audioSlider.upperValue - _audioSlider.lowerValue)*_duration];
    
    [_audioProgressTimer invalidate];
    _audioProgressTimer=nil;
    _audioProgressTimer=[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateAduioProgress) userInfo:nil repeats:YES];
    [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
    [_audioPlayer play];
    _isPlaying=YES;
}



/*初始化选中我的音乐——预览音乐界面
 */
- (void)initSelectMusicView{
    _selectMusicView = [[UIView alloc] init];
    _selectMusicView.frame = CGRectMake(0, 0, kWIDTH , kCellSelectHeight - kCellNormalHeight);
    _selectMusicView.backgroundColor = TOOLBAR_COLOR;
    
    _audioSlider = [[MusicRangeSlider_RD alloc] initWithFrame:CGRectMake(50, (_selectMusicView.frame.size.height - 33 + 10)/2.0, _selectMusicView.frame.size.width - 54 - 15,33)];
    [_audioSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [_audioSlider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [_audioSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [_audioSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    _audioSlider.backgroundColor = [UIColor clearColor];
    
    if(_selectedMusicURL){
        AVURLAsset *url = [self AudioDurationFromUrl:_selectedMusicURL];
        _duration =url.duration.value/url.duration.timescale;
        _audioSlider.durationValue = _duration;
    }else{
        _audioSlider.durationValue = 0;
    }
    
    UIImage* image = nil;
    
    if( _fheight )
        image = [RDHelpClass rdImageWithColor:TOOLBAR_COLOR cornerRadius:0];
    else
        image = [RDHelpClass rdImageWithColor:SCREEN_BACKGROUND_COLOR cornerRadius:0];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
    _audioSlider.trackBackgroundImage = image;
    
    image = [RDHelpClass rdImageWithColor:Main_Color cornerRadius:0];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
    _audioSlider.trackImage = image;
    
    
    image = [RDHelpClass rdImageWithColor:UIColorFromRGB(0xffffff) cornerRadius:0];
    //image = [RDHelpClass rdImageWithColor:UIColorFromRGB(0xf87a00) cornerRadius:0];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
    _audioSlider.progressTrackImage = image;
    
    image = [RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_把手默认_"];
    _audioSlider.lowerHandleImageNormal = image;
    _audioSlider.upperHandleImageNormal = image;
    image = [RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_把手选中_"];
    image = [image imageWithTintColor];
    _audioSlider.lowerHandleImage = image;
    _audioSlider.lowerHandleImageHighlighted = image;
    _audioSlider.upperHandleImage = image;
    _audioSlider.upperHandleImageHighlighted = image;
    
    _audioSlider.minimumValue = 0.0;
    _audioSlider.maximumValue = 1.0;
    _audioSlider.lowerValue=0.0;
    _audioSlider.upperValue=1.0;
    [_audioSlider setLowerValue:0.0 upperValue:1.0 animated:YES];
    _audioSlider.continuous = YES;
    
    [_selectMusicView addSubview:_audioSlider];
    
    _lowerLabelBack = [[UIImageView alloc] init];
    _lowerLabelBack.frame = CGRectMake(_audioSlider.frame.origin.x, _audioSlider.frame.origin.y-30, 42, 32);
    
    _lowerLabel = [[UILabel alloc] init];
    _lowerLabel.textColor = [UIColor whiteColor];
    _lowerLabel.textAlignment = NSTextAlignmentCenter;
    _lowerLabel.font = [UIFont systemFontOfSize:12];
    _lowerLabel.frame = CGRectMake(0, 0, 42, 25);
    _lowerLabel.backgroundColor = [UIColor clearColor];
    _lowerLabel.text = [RDHelpClass timeToStringNoSecFormat:0.0];
    [_lowerLabelBack addSubview:_lowerLabel];
    
    _upperLabelBack         = [[UIImageView alloc] init];
    _upperLabelBack.frame   = CGRectMake(0, _audioSlider.frame.origin.y-30, 42, 32);
    
    _upperLabel = [[UILabel alloc] init];
    _upperLabel.textColor       = [UIColor whiteColor];
    _upperLabel.textAlignment   = NSTextAlignmentCenter;
    _upperLabel.font            = [UIFont systemFontOfSize:12];
    _upperLabel.frame           = CGRectMake(0, 0, 42, 25);
    _upperLabel.backgroundColor = [UIColor clearColor];
    _upperLabel.text = [RDHelpClass timeToStringNoSecFormat:_duration];
    
    _audioPlayButton=[UIButton buttonWithType:UIButtonTypeCustom];
    _audioPlayButton.backgroundColor = [UIColor clearColor];
    [_audioPlayButton addTarget:self action:@selector(audioPlayOrPause) forControlEvents:UIControlEventTouchUpInside];
    [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    _audioPlayButton.frame = CGRectMake(0, (_selectMusicView.frame.size.height - 44 + 10)/2.0, 44, 44);//wuxiaoxia iPhone6、6plus屏幕适配  20150306
    
    [_upperLabelBack addSubview:_upperLabel];
    [_selectMusicView addSubview:_upperLabelBack];
    [_selectMusicView addSubview:_lowerLabelBack];
    
    [_selectMusicView addSubview:_audioSlider];
    [_selectMusicView addSubview:_audioPlayButton];
    [self updateSliderLabels:@"00:00" stop:[RDHelpClass timeToStringNoSecFormat:_duration]];
}
/*
 更新悬浮提示的位置和显示内容
 */
- (void) updateSliderLabels:(NSString *)start stop:(NSString *)stop
{
    CGPoint lowerCenter;
    lowerCenter.x = (_audioSlider.lowerCenter.x + _audioSlider.frame.origin.x);
    lowerCenter.y = (_audioSlider.center.y - 30.0f);
    _lowerLabelBack.center = lowerCenter;
    _lowerLabel.text = start;
    _lowerLabelBack.hidden = NO;
    
    CGPoint upperCenter;
    upperCenter.x = (_audioSlider.upperCenter.x + _audioSlider.frame.origin.x);
    upperCenter.y = (_audioSlider.center.y - 30.0f);
    _upperLabelBack.center = upperCenter;
    _upperLabel.text = stop;
    _upperLabelBack.hidden = NO;
}

#pragma mark- UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //    if(_vcIndex == 0){
    //        return _libraryMusicArray.count;
    //    }else{
    return _sourceList.count;
    //    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //选中之后的cell的高度
    if (indexPath.row == _selectIndex.row && _selectIndex != nil && _selectSection == indexPath.section){
        return kCellSelectHeight;
    }
    else
        return kCellNormalHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    @autoreleasepool {
        if (indexPath.row == _selectIndex.row && _selectIndex!= nil && indexPath.section == _selectSection){
            
            [_selectMusicView removeFromSuperview];
            
            //选中状态
            static NSString *identifier_ = @"cell_";
            MusicTableCell *cell_ = (MusicTableCell *)[tableView dequeueReusableCellWithIdentifier:identifier_];
            
            if (cell_ == nil){
                
                cell_ = [[MusicTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier_];
                cell_.backgroundColor = SCREEN_BACKGROUND_COLOR;
                if( _fheight )
                    cell_.backgroundColor = TOOLBAR_COLOR;
                cell_.backgroundView = nil;
                UILabel *musicNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, tableView.frame.size.width-120, 30)];
                musicNameLabel.tag      = 10;
                musicNameLabel.backgroundColor = [UIColor clearColor];
                [cell_.contentView addSubview:musicNameLabel];
                
                UILabel *musicDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 50, 30)];
                musicDurationLabel.tag      = 12;
                musicDurationLabel.backgroundColor = [UIColor clearColor];
                [cell_.contentView addSubview:musicDurationLabel];
                
                UIButton *selectCellBtn = [[UIButton alloc] init];
                selectCellBtn.frame = CGRectMake(tableView.frame.size.width-60, 10, 50, 30);
                selectCellBtn.backgroundColor = Main_Color;
                selectCellBtn.layer.cornerRadius = 15;
                selectCellBtn.tag = 13;
                selectCellBtn.titleLabel.font = [UIFont systemFontOfSize:14];
                selectCellBtn.layer.masksToBounds = YES;
                [selectCellBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
                [selectCellBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
                [selectCellBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateHighlighted];
                [cell_.contentView addSubview:selectCellBtn];
                
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kCellNormalHeight, tableView.frame.size.width, kCellSelectHeight-kCellNormalHeight)];
                imageView.userInteractionEnabled = YES;
                imageView.tag = 20;
                imageView.backgroundColor = [UIColor clearColor];
                
                [cell_.contentView addSubview:imageView];
                
                UIView *spanView2           = [[UIView alloc] initWithFrame:CGRectMake(60, imageView.frame.size.height-0.5, imageView.frame.size.width - 70, 0.5)];
                spanView2.backgroundColor   = UIColorFromRGB(0x62626e);
                
                [imageView addSubview:spanView2];
                
            }
            cell_.selectionStyle=UITableViewCellSelectionStyleNone;
            
            UILabel *imageView     = (UILabel*)[cell_.contentView viewWithTag:20];
            
            [imageView addSubview:_selectMusicView];
            
            
            UILabel *musicNameLabel          = (UILabel*)[cell_.contentView viewWithTag:10];
            UILabel *musicDurationLabel      = (UILabel*)[cell_.contentView viewWithTag:12];
            UIButton *selectCellBtn          = (UIButton*)[cell_.contentView viewWithTag:13];
            
            musicNameLabel.textColor         = UIColorFromRGB(0xffffff);
            musicDurationLabel.textColor     = UIColorFromRGB(0x888888);
            musicDurationLabel.font          = [UIFont systemFontOfSize:14];
            musicDurationLabel.textAlignment = NSTextAlignmentLeft;
            
            musicNameLabel.font              = [UIFont systemFontOfSize:14];
            musicNameLabel.textAlignment     = NSTextAlignmentLeft;
            
            [selectCellBtn addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
            
            if(_sourceList){
                if( _isLocal )
                {
                    MPMediaItem *song = [_sourceList objectAtIndex:indexPath.row];
                    NSString *mname = song.title;
                    if(mname)
                        musicNameLabel.text = mname;
#if 0   //20171026 wuxiaoxia 有的音频文件返回时长不正确
                    double duration = [[song valueForKey:MPMediaItemPropertyPlaybackDuration] doubleValue];
                    musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:duration];
#else
                    AVURLAsset *musicAsset = [self AudioDurationFromUrl:[song valueForProperty:MPMediaItemPropertyAssetURL]];
                    musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:CMTimeGetSeconds(musicAsset.duration)];
#endif
                    mname = nil;
                }
                else
                {
                    NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
                    NSString *mname = [dic objectForKey:@"name"];
                    double duration = [[dic objectForKey:@"times"] doubleValue];
                    if (duration == 0) {
                        duration = [[dic objectForKey:@"duration"] doubleValue];
                    }
                    if(mname)
                        musicNameLabel.text = mname;
                    musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:duration];
                }
            }
            return cell_;
        }
        else{   //非选中状态
            static NSString *identifier = @"cell";
            MusicTableCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            
            if (cell == nil){
                cell = [[MusicTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                UIImageView *cellBackImageView  = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, kCellNormalHeight)];
                cellBackImageView.tag           = indexPath.row;
                cellBackImageView.backgroundColor = [UIColor clearColor];
                
                UIView *spanView2           = [[UIView alloc] initWithFrame:CGRectMake(60, cellBackImageView.frame.size.height-0.5, cellBackImageView.frame.size.width-70, 0.5)];
                spanView2.backgroundColor   = UIColorFromRGB(0x62626e);
                [cellBackImageView addSubview:spanView2];
                
                cell.backgroundColor = SCREEN_BACKGROUND_COLOR;
                if( _fheight )
                    cell.backgroundColor = TOOLBAR_COLOR;
                cell.backgroundView = nil;
                [cell addSubview:cellBackImageView];
                
                UILabel *musicNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, tableView.frame.size.width-120, 30)];
                musicNameLabel.tag      = 10;
                musicNameLabel.backgroundColor = [UIColor clearColor];
                [cell.contentView addSubview:musicNameLabel];
                
                UILabel *musicDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 50, 30)];
                musicDurationLabel.tag      = 12;
                musicDurationLabel.backgroundColor = [UIColor clearColor];
                [cell.contentView addSubview:musicDurationLabel];
                if( (!_isLocal) && _sourceList){
                    NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
                    NSString *downloadurl = nil;
                    if( _isSound )
                        downloadurl =  [dic objectForKey:@"file"];
                    else
                        downloadurl = [dic objectForKey:@"url"];
                    
                    //新华网的处理 没有添加域名
                    if ( ([downloadurl rangeOfString:@"https://"].location == NSNotFound) && ([downloadurl rangeOfString:@"http://"].location == NSNotFound  ) ) {
                        NSLog(@"downloadurl 不存在 https://");
                        downloadurl = [NSString stringWithFormat:@"%@%@",@"https://shortvideo.v.news.cn",downloadurl];
                    }
                    
                    NSURL *url = [NSURL URLWithString:downloadurl];
                    
                    NSString *cacheMusicFileName = [RDHelpClass cachedMusicNameForURL:url];
                    NSString *cacheFilePath = [self cachedMusicFilePath:cacheMusicFileName];
                    
                    CustomButton *downloadBtn = (CustomButton *)[cell.contentView viewWithTag:14];
                    if((![self hasCachedMusicForPath:cacheFilePath] || CMTimeGetSeconds([self AudioDurationFromUrl:[NSURL fileURLWithPath:cacheFilePath]].duration)==0) && !cell.downloading){
                        if (!downloadBtn) {
                            CustomButton *selectDownLoadCellBtn = [[CustomButton alloc] init];
                            selectDownLoadCellBtn.frame = CGRectMake(tableView.frame.size.width-50, 5, 40, 40);
                            selectDownLoadCellBtn.backgroundColor = [UIColor clearColor];
                            [selectDownLoadCellBtn addTarget:self action:@selector(downloadMusic:) forControlEvents:UIControlEventTouchUpInside];
                            selectDownLoadCellBtn.tag = 14;
                            selectDownLoadCellBtn.indexPath = indexPath;
                            [selectDownLoadCellBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateNormal];
                            [selectDownLoadCellBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateSelected];
                            [cell.contentView addSubview:selectDownLoadCellBtn];
                        }else {
                            [downloadBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateNormal];
                            [downloadBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateSelected];
                        }
                    }else if (downloadBtn){
                        [downloadBtn removeFromSuperview];
                        downloadBtn = nil;
                    }
                }
            }
            else
            {
                if( (!_isLocal) && _sourceList){
                    NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
                    NSString *downloadurl = nil;
                    if( _isSound )
                        downloadurl =  [dic objectForKey:@"file"];
                    else
                        downloadurl = [dic objectForKey:@"url"];
                    
                    //新华网的处理 没有添加域名
                    if ( ([downloadurl rangeOfString:@"https://"].location == NSNotFound) && ([downloadurl rangeOfString:@"http://"].location == NSNotFound  ) ) {
                        NSLog(@"downloadurl 不存在 https://");
                        downloadurl = [NSString stringWithFormat:@"%@%@",@"https://shortvideo.v.news.cn",downloadurl];
                    }
                    
                    NSURL *url = [NSURL URLWithString:downloadurl];
                    
                    NSString *cacheMusicFileName = [RDHelpClass cachedMusicNameForURL:url];
                    NSString *cacheFilePath = [self cachedMusicFilePath:cacheMusicFileName];
                    
                    CustomButton *downloadBtn = (CustomButton *)[cell.contentView viewWithTag:14];
                    if((![self hasCachedMusicForPath:cacheFilePath] || CMTimeGetSeconds([self AudioDurationFromUrl:[NSURL fileURLWithPath:cacheFilePath]].duration)==0) && !cell.downloading){
                        if (!downloadBtn) {
                            CustomButton *selectDownLoadCellBtn = [[CustomButton alloc] init];
                            selectDownLoadCellBtn.frame = CGRectMake(tableView.frame.size.width-50, 5, 40, 40);
                            selectDownLoadCellBtn.backgroundColor = [UIColor clearColor];
                            [selectDownLoadCellBtn addTarget:self action:@selector(downloadMusic:) forControlEvents:UIControlEventTouchUpInside];
                            selectDownLoadCellBtn.tag = 14;
                            selectDownLoadCellBtn.indexPath = indexPath;
                            [selectDownLoadCellBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateNormal];
                            [selectDownLoadCellBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateSelected];
                            [cell.contentView addSubview:selectDownLoadCellBtn];
                        }else {
                            [downloadBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateNormal];
                            [downloadBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"] forState:UIControlStateSelected];
                        }
                    } else if (downloadBtn){
                        [downloadBtn removeFromSuperview];
                        downloadBtn = nil;
                    }
                }
            }
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            UILabel *musicNameLabel          = (UILabel*)[cell.contentView viewWithTag:10];
            UILabel *musicDurationLabel      = (UILabel*)[cell.contentView viewWithTag:12];
            musicNameLabel.font              = [UIFont systemFontOfSize:14];
            musicDurationLabel.font          = [UIFont systemFontOfSize:14];
            musicNameLabel.textAlignment     = NSTextAlignmentLeft;
            musicDurationLabel.textAlignment = NSTextAlignmentLeft;
            musicNameLabel.textColor         = UIColorFromRGB(0xffffff);
            musicDurationLabel.textColor     = UIColorFromRGB(0x888888);
            
            if(_sourceList){
                if( _isLocal )
                {
                    MPMediaItem *song = [_sourceList objectAtIndex:indexPath.row];
                    NSString *mname = song.title;
                    if(mname)
                        musicNameLabel.text = mname;
#if 0   //20171026 wuxiaoxia 有的音频文件返回时长不正确
                    double duration = [[song valueForKey:MPMediaItemPropertyPlaybackDuration] doubleValue];
                    musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:duration];
#else
                    AVURLAsset *musicAsset = [self AudioDurationFromUrl:[song valueForProperty:MPMediaItemPropertyAssetURL]];
                    musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:CMTimeGetSeconds(musicAsset.duration)];
#endif
                    mname = nil;
                }
                else
                {
                    NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
                    NSString *mname = [dic objectForKey:@"name"];
                    double duration = [[dic objectForKey:@"times"] doubleValue];
                    if (duration == 0) {
                        duration = [[dic objectForKey:@"duration"] doubleValue];
                    }
                    if(mname)
                        musicNameLabel.text = mname;
                    musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:duration];
                }
            }
            return cell;
        }
        return nil;
    }
}
#pragma mark - 获取MP3时长
- (AVURLAsset *)AudioDurationFromUrl:(NSURL *)url {
    //只有这个方法获取时间是准确的 audioPlayer.duration获得的时间不准
    AVURLAsset* audioAsset = nil;
    NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    audioAsset =[AVURLAsset URLAssetWithURL:url options:dic];
    return audioAsset;
}

- (void)downloadMusic:(CustomButton *)sender{
    MusicTableCell *cell = (MusicTableCell *)sender.superview.superview;
    NSIndexPath *indexpath = [_localMusicTableView indexPathForCell:cell];
    [self tableView:_localMusicTableView didSelectRowAtIndexPath:indexpath];
#if 0
    if(_sourceList){
        
        NSDictionary *dic = [_sourceList objectAtIndex:sender.indexPath.row];
        NSString *downloadurl = nil;
        if( _isSound )
            downloadurl =  [dic objectForKey:@"file"];
        else
            downloadurl = [dic objectForKey:@"url"];
        NSURL *url = [NSURL URLWithString:downloadurl];
        __weak typeof(self) myself = self;
        NSString *cacheMusicFileName = [RDHelpClass cachedMusicNameForURL:url];
        NSString *cacheFilePath = [self cachedMusicFilePath:cacheMusicFileName];
        if(![self hasCachedMusicForPath:cacheFilePath] || CMTimeGetSeconds([AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:cacheFilePath]].duration)==0){
            if(!_downloaderparams){
                _downloaderparams = [[NSMutableArray alloc] init];
            }
            UITableViewCell *iCell = [_tableView cellForRowAtIndexPath:sender.indexPath];
            CustomButton *downloadBtn = (CustomButton *)[iCell.contentView viewWithTag:14];
            
            UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
            
            CGRect rect = CGRectMake((downloadBtn.frame.size.width-accessory.size.width)/2.0, (downloadBtn.frame.size.height - accessory.size.height)/2.0, accessory.size.width, accessory.size.height);
            
            RDSectorProgressView *ddprogress = [[RDSectorProgressView alloc] initWithFrame:rect];
            
            [downloadBtn addSubview:ddprogress];
            [downloadBtn setImage:nil forState:UIControlStateNormal];
            RDFileDownloader *downloader = [[RDFileDownloader alloc] init];
            downloader.cacheFilePath = cacheFilePath;
            [downloader downloadFileWithURL:downloadurl httpMethod:GET progress:^(NSNumber *numprogress){
                [ddprogress setProgress:[numprogress floatValue]];
            } finish:^(NSString *fileCachePath) {
                NSLog(@"下载完成:%@",fileCachePath);
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    ddprogress.hidden=YES;
                    [ddprogress removeFromSuperview];
                    [sender removeFromSuperview];
                    
                });
                [_downloaderparams removeObject:downloader];
            } fail:^(NSError *error) {
                ddprogress.hidden=YES;
                [ddprogress removeFromSuperview];
                [downloadBtn setImage:accessory forState:UIControlStateNormal];
                [_downloaderparams removeObject:downloader];
            } cancel:^{
                ddprogress.hidden=YES;
                [ddprogress removeFromSuperview];
                [downloadBtn setImage:accessory forState:UIControlStateNormal];
                [_downloaderparams removeObject:downloader];
            }];
            
            [_downloaderparams addObject:downloader];
        }
    }
    
    //[self tableView:_tableView didSelectRowAtIndexPath:sender.indexPath];
#endif
}

- (BOOL)hasCachedMusicForPath:(NSString *)filePath{
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        return YES;
    }
    return NO;
}

- (NSString *)cachedMusicFilePath:(NSString *)cacheMusicFileName{
    if([[kMusicPath substringFromIndex:kMusicPath.length-1] isEqualToString:@"/"]){
        return [kMusicPath stringByAppendingString:[NSString stringWithFormat:@"%@",cacheMusicFileName]];
    }else{
        return [kMusicPath stringByAppendingString:[NSString stringWithFormat:@"/%@",cacheMusicFileName]];
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(_isDisappear){
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(_sourceList){
        if( !_isLocal )
        {
            NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
            NSString *downloadurl = nil;
            if( _isSound )
                downloadurl =  [dic objectForKey:@"file"];
            else
                downloadurl = [dic objectForKey:@"url"];
            
            //新华网的处理 没有添加域名
            if ( ([downloadurl rangeOfString:@"https://"].location == NSNotFound) && ([downloadurl rangeOfString:@"http://"].location == NSNotFound  ) ) {
                NSLog(@"downloadurl 不存在 https://");
                downloadurl = [NSString stringWithFormat:@"%@%@",@"https://shortvideo.v.news.cn",downloadurl];
            }
            
            NSURL *url = [NSURL URLWithString:downloadurl];
            
             NSString *cacheMusicFileName = [RDHelpClass cachedMusicNameForURL:url];
            NSString *cacheFilePath = [self cachedMusicFilePath:cacheMusicFileName];
            if(![self hasCachedMusicForPath:cacheFilePath] || CMTimeGetSeconds([self AudioDurationFromUrl:[NSURL fileURLWithPath:cacheFilePath]].duration)==0){
                [self selectTableView:tableView didSelectRowAtIndexPath:indexPath same:YES];
                return;
            }
        }
    }
    
    if (!_selectIndex){
        _selectIndex = indexPath;
        
        _selectSection = indexPath.section;
        
        [self selectTableView:tableView didSelectRowAtIndexPath:indexPath same:YES];
        
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_selectIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else{
        BOOL selectTheSameRow = indexPath.row == _selectIndex.row? YES:NO;
        
        BOOL selectTheSameSection = indexPath.section == _selectSection ? YES : NO;
        
        _selectSection = indexPath.section;
        
        if (selectTheSameRow && selectTheSameSection){
            [self stopPlayAudio];
            //若点击相同的cell，收起cell
            _selectIndex = nil;
            
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            //两次点击不同的cell
            [self stopPlayAudio];
            //收起上次点击展开的cell;
            NSIndexPath *tempIndexPath = [_selectIndex copy];
            _selectIndex = nil;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:tempIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            //展开新选择的cell;
            _selectIndex = indexPath;
            
            [self selectTableView:tableView didSelectRowAtIndexPath:indexPath same:NO];
            
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_selectIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
    }
    _lastSelectMusicIndex = indexPath.row;
    [_localMusicTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

/*
 选中当前行的音乐
 */
-(void)selectTableView:(UITableView *)selectTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath same:(BOOL)sameCell{
    
    if(_sourceList){
        
        if( _isLocal )
        {
            MPMediaItem *song = [_sourceList objectAtIndex:indexPath.row];
            _selectedMusicName = [NSString stringWithFormat:@"%@", [song valueForKey:MPMediaItemPropertyTitle]];
            _selectedMusicURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
            
            AVURLAsset *musicAsset = [self AudioDurationFromUrl:_selectedMusicURL];
            _duration = CMTimeGetSeconds(musicAsset.duration);
            
            NSString *stringStop=[NSString stringWithFormat:@"%02li:%02li",
                                  lround(floor(_duration / 60.)) % 60,
                                  lround(floor(_duration/1.)) % 60];
            
            _audioSlider.continuous = YES;
            
            _audioSlider.durationValue = _duration;
            [_audioSlider progress:0];
            [_audioSlider setLowerValue:0.0 upperValue:1.0 animated:NO];
            [self updateSliderLabels:@"00:00" stop:stringStop];
            NSLog(@"当前选中的是: %@",_selectedMusicName);
            NSLog(@"当前的URL是: %@",_selectedMusicURL);
            [self playMusic];
        }
        else
        {
            NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
            NSString *mname =
            [dic objectForKey:@"name"];
            NSString *downloadurl = nil;
            if( _isSound )
                downloadurl =  [dic objectForKey:@"file"];
            else
                downloadurl = [dic objectForKey:@"url"];
            
            //新华网的处理 没有添加域名
            if ( ([downloadurl rangeOfString:@"https://"].location == NSNotFound) && ([downloadurl rangeOfString:@"http://"].location == NSNotFound  ) ) {
                NSLog(@"downloadurl 不存在 https://");
                downloadurl = [NSString stringWithFormat:@"%@%@",@"https://shortvideo.v.news.cn",downloadurl];
            }
            
            
            NSURL *url = [NSURL URLWithString:downloadurl];
            __weak RDCloudMusicItemViewController *weakself = self;
            NSString *cacheMusicFileName = [RDHelpClass cachedMusicNameForURL:url];
            NSString *cacheFilePath = [self cachedMusicFilePath:cacheMusicFileName];
            
            
            if(![self hasCachedMusicForPath:cacheFilePath] ||
               CMTimeGetSeconds([self AudioDurationFromUrl:[NSURL fileURLWithPath:cacheFilePath]].duration)==0
               )
            {
                
                if(!_downloaderparams){
                    _downloaderparams = [[NSMutableArray alloc] init];
                }
                MusicTableCell *iCell = (MusicTableCell *)[selectTableView cellForRowAtIndexPath:indexPath];
                CustomButton *downloadBtn = (CustomButton *)[iCell.contentView viewWithTag:14];
                
                UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
                
                CGRect rect = CGRectMake((downloadBtn.frame.size.width-accessory.size.width)/2.0, (downloadBtn.frame.size.height - accessory.size.height)/2.0, accessory.size.width, accessory.size.height);
                
                RDSectorProgressView *ddprogress = [[RDSectorProgressView alloc] initWithFrame:rect];
                
                [downloadBtn addSubview:ddprogress];
                [downloadBtn setImage:nil forState:UIControlStateNormal];
                RDFileDownloader *downloader = [[RDFileDownloader alloc] init];
                downloader.cacheFilePath = cacheFilePath;
                iCell.downloading = YES;
                [downloader downloadFileWithURL:downloadurl httpMethod:GET progress:^(NSNumber *numprogress){
                    [ddprogress setProgress:[numprogress floatValue]];
                } finish:^(NSString *fileCachePath) {
                    AVURLAsset *asset = [self AudioDurationFromUrl:[NSURL fileURLWithPath:fileCachePath]];
                    double duration = CMTimeGetSeconds(asset.duration);
                    asset = nil;
                    iCell.downloading = NO;
                    if(duration == 0){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakself.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                            [weakself.hud show];
                            [weakself.hud hideAfter:2];
                            ddprogress.hidden=YES;
                            [ddprogress removeFromSuperview];
                            [downloadBtn setImage:accessory forState:UIControlStateNormal];
                            [self->_downloaderparams removeObject:downloader];
                        });
                    }else{
                        NSLog(@"下载完成:%@",fileCachePath);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            ddprogress.hidden=YES;
                            [ddprogress removeFromSuperview];
                            [weakself tableView:selectTableView didSelectRowAtIndexPath:indexPath];
                        });
                        [self->_downloaderparams removeObject:downloader];
                    }
                    
                } fail:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.hud setCaption:error.localizedDescription];
                        [weakself.hud show];
                        [weakself.hud hideAfter:2];
                        ddprogress.hidden=YES;
                        [ddprogress removeFromSuperview];
                        [downloadBtn setImage:accessory forState:UIControlStateNormal];
                        [self->_downloaderparams removeObject:downloader];
                    });
                } cancel:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        ddprogress.hidden=YES;
                        [ddprogress removeFromSuperview];
                        [downloadBtn setImage:accessory forState:UIControlStateNormal];
                        [self->_downloaderparams removeObject:downloader];
                    });
                }];
                [_downloaderparams addObject:downloader];
                
            }else{
                
                [_audioSlider progress:0];
                _audioSlider.lowerValue = 0;
                _audioSlider.upperValue = 1.0;
                [_audioSlider setLowerValue:0.0 upperValue:1.0 animated:NO];
                _selectedMusicName = mname;
                _selectedMusicURL = [NSURL fileURLWithPath:cacheFilePath];
                
                AVURLAsset *musicAsset = [self AudioDurationFromUrl:_selectedMusicURL];
                _duration = CMTimeGetSeconds(musicAsset.duration);
                
                NSString *stringStop=[NSString stringWithFormat:@"%02li:%02li",
                                      lround(floor(_duration / 60.)) % 60,
                                      lround(floor(_duration/1.)) % 60];
                
                _audioSlider.continuous = YES;
                
                _audioSlider.durationValue = _duration;
                [self updateSliderLabels:@"00:00" stop:stringStop];
                NSLog(@"当前选中的是: %@",_selectedMusicName);
                NSLog(@"当前的URL是: %@",_selectedMusicURL);
                [self playMusic];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(_selectIndex && _selectIndex.row == indexPath.row && _selectIndex.section == indexPath.section){
        return NO;
    }
    return NO;
}

#pragma mark - 启动动画
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    //1. Setup the CATransform3D structure
    if( _isStart && ( _animationCount > 0 ) )
    {
//        CATransform3D rotation;
//
//        rotation = CATransform3DIdentity;
//
//        rotation =  CATransform3DTranslate(rotation, 0.0, 0, 0); //CATransform3DMakeRotation( (15*M_PI)/180, 0.0, 0.7, 0.5);
//
//        rotation.m34 = 1.0/ -500;
//
//        //2. Define the initial state (Before the animation)
//
//        cell.layer.shadowColor = [[UIColor blackColor]CGColor];
//
//        cell.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        
        cell.alpha = 0.0;
        
//        cell.layer.transform = rotation;
//
//        cell.layer.anchorPoint = CGPointMake(0, 0.5);
        
        //!!!FIX for issue #1 Cell position wrong------------
        
//        if(cell.layer.position.x != 0){
//
//            cell.layer.position = CGPointMake(0, cell.layer.position.y);
//        }
        
        //3. Define the final state (After the animation) and commit the animation
        
        double secondsDelay = indexPath.row *0.08;

        if (secondsDelay > 0.6) {

            secondsDelay = 0.1;

        }
//
        [UIView animateWithDuration:0.5 delay:secondsDelay usingSpringWithDamping:1.0 initialSpringVelocity:0.5 options:0 animations:^{
            
//            cell.layer.transform = CATransform3DIdentity;
            
            cell.alpha = 1;
            
//            cell.layer.shadowOffset = CGSizeMake(0, 0);
            
        } completion:^(BOOL finished) {}];
        
        _animationCount--;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

/*
 播放或暂停缓存音乐
 */
- (void)audioPlayOrPause{
    
    if (_audioSlider.lowerCenter.x>=_audioSlider.bounds.size.width-20) {
        [_audioPlayer setCurrentTime:0];
        [_audioSlider setLowerValue:0 animated:NO];
        _isPlaying=YES;
        [_audioPlayer play];
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        _audioProgressTimer=[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateAduioProgress) userInfo:nil repeats:YES];
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        
    }else if (_isPlaying) {
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_audioPlayer pause];
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        _isPlaying=NO;
    }else{
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateNormal];
        [_audioPlayer play];
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        _audioProgressTimer=[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateAduioProgress) userInfo:nil repeats:YES];
        _isPlaying=YES;
    }
}

/*
 更新播放器进度
 */
- (void)updateAduioProgress{
    if (_audioSlider.progressTrack.frame.size.width >= _audioSlider.upperCenter.x-_audioSlider.lowerCenter.x - _audioSlider.lowerHandle.bounds.size.width) {
        
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        [_audioPlayer pause];
        _isPlaying=NO;
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        float progress = _audioPlayer.currentTime - (_audioSlider.lowerHandle.frame.origin.x/_audioSlider.frame.size.width)*_duration;
//        NSLog(@"progress:%lf",progress);
        
        if( progress < 0.0 ) {
            progress = 0.0;
        }
        [_audioSlider progress:progress];
            
        if(!_isPlaying){
            [_audioProgressTimer invalidate];
            _audioProgressTimer=nil;
        }
    }
    if(!_isPlaying){
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        _isPlaying=NO;
        //20161009 bug27
        [_audioSlider progress:0.1];
        float startTime=_audioSlider.lowerValue*_audioSlider.durationValue;
        [_audioPlayer setCurrentTime:startTime];
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }
}

/*
 初始化音乐播放器
 */
- (void)playMusic{
    NSError *playerError;
    @try {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_selectedMusicURL error:&playerError];
        NSLog(@"%@",[playerError description]);
        
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        if(_audioPlayer){
            AVURLAsset *urlAsset=[self AudioDurationFromUrl:_selectedMusicURL];
            _duration=CMTimeGetSeconds([urlAsset duration]);
            NSLog(@"%@",_selectedMusicURL.path);
            
            NSLog(@"playerError:%@",playerError);
            _audioPlayer.delegate=self;
            _isPlaying = NO;
            [self audioPlayOrPause];
        }
    }
}


/*停止播放音乐
 */
- (void)stopPlayAudio{
    if(_audioPlayer){
        NSLog(@"NSTimer停止播放!");
        [_audioPlayer stop];
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        _isPlaying=NO;
        [_audioSlider progress:0.1];
        [_audioSlider setLowerValue:_audioSlider.lowerValue animated:NO];//20161009 bug27
        [_audioSlider layoutSubviews];
        
        //20161009 bug27
        float startTime=_audioSlider.lowerValue*_audioSlider.durationValue;
        [_audioPlayer setCurrentTime:startTime];
    }
}

- (void)dealloc{
    [_audioPlayer stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeTitleIndex" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    NSLog(@"%s",__func__);
}

#else

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@ 第%ld行",self.category,(long)indexPath.row];
    return cell;
}
#endif
@end
