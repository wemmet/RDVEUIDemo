//
//  RDLocalMusicViewController.m
//  RDVEUISDK
//
//  Created by emmet on 2017/5/18.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import "RDLocalMusicViewController.h"
#import "MusicRangeSlider_RD.h"
#import "RDHelpClass.h"
#import "CustomButton.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "RDATMHud.h"
#import "LocalPhotoCell.h"
#import "RDOtherAlbumsViewController.h"
#import "RD_ImageManager.h"
//提取音频
#import "RDExtractAudioViewController.h"

#define kTagOfTableView 100
#define kProgressViewTag 1000
#define kCellNormalHeight 50
#define kCellSelectHeight 137

@interface RDLocalMusicViewController ()<AVAudioPlayerDelegate,UIAlertViewDelegate,UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate, UICollectionViewDataSource>
{
    UIButton                    *localMusicBtn;
    UIButton                    *albumVideoBtn;
    NSMutableArray              *albumVideoArray;
    NSMutableArray              *_libraryMusicArray;
    BOOL                         isMusicAuthorized;
    BOOL                         isAlbumAuthorized;
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
    BOOL                         _isPlaying;
    UIButton                    *_audioPlayButton;
    
    NSURL                       *_selectedMusicURL;
    NSString                    *_selectedMusicName;
    double                       _duration;
    
    UIAlertView                 *commonAlertView;
    UIScrollView                *scrollView;
    
    UICollectionView            *albumVideo;
    
    BOOL                        isSelect;
}
@property(nonatomic,strong)RDATMHud *hud;
@property(nonatomic,strong)UIView   *noLocalMusicView; //无本地音乐

@end


@implementation RDLocalMusicViewController
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationItem setHidesBackButton:YES];
    // 设置导航栏背景图片
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:SCREEN_BACKGROUND_COLOR cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.translucent = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    
    
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    if(_isPlaying){
        [self stopPlayAudio];
    }
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
    
    isSelect = false;
    
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationItem setHidesBackButton:YES];
    // 设置导航栏背景图片
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:TOOLBAR_COLOR cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];

    [self setValue];
    [self initSelectMusicView];
    
    CGRect localmusicRect = CGRectMake(0, 0, kWIDTH, kHEIGHT - 44);
    _localMusicTableView = [[UITableView alloc] initWithFrame:localmusicRect style:UITableViewStylePlain];
    _localMusicTableView.backgroundColor    = [UIColor clearColor];
    _localMusicTableView.backgroundView     = nil;
    _localMusicTableView.delegate           = self;
    _localMusicTableView.dataSource         = self;
    _localMusicTableView.tag                = kTagOfTableView;
    _localMusicTableView.separatorStyle     = UITableViewCellAccessoryNone;
    _localMusicTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_localMusicTableView];
    
    if (iPhone_X) {
        _localMusicTableView.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
    
    localmusicRect = CGRectMake(10, 0, kWIDTH - 20, kHEIGHT - 44);
    UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    float width;
    width = (localmusicRect.size.width - 3.0 * 8.0) / 4.0;
    flow.itemSize = CGSizeMake(width,width);
    flow.minimumLineSpacing = 8.0;
    flow.minimumInteritemSpacing = 8.0;
    
    albumVideo = [[UICollectionView alloc] initWithFrame:localmusicRect collectionViewLayout: flow];
    albumVideo.backgroundColor = [UIColor clearColor];
    albumVideo.tag = 1;
    albumVideo.dataSource=self;
    albumVideo.delegate=self;
    [albumVideo registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"albumCell"];
    if (iPhone_X) {
        albumVideo.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
    [self.view addSubview:albumVideo];
    albumVideo.hidden = YES;
    
    if( _libraryMusicArray.count == 0 )
    {
        _localMusicTableView.hidden = YES;
        self.noLocalMusicView.hidden = NO;
    }
}
/**获取数据
 */
- (void)setValue{
    
    UIBarButtonItem *spaceItem;
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [leftBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateHighlighted];
    UIBarButtonItem *leftButton= [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    spaceItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    leftBtn.exclusiveTouch=YES;
    spaceItem.width=-9;
    self.navigationItem.leftBarButtonItems =@[spaceItem,leftButton];
  
    _selectIndex = nil;
    _selectSection = 0 ;
    _libraryMusicArray = [NSMutableArray array];
    if([[[UIDevice currentDevice] systemVersion] floatValue] < 9.3){
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied){
            if (commonAlertView) {
                commonAlertView.delegate = nil;
                commonAlertView = nil;
            }
            commonAlertView = [[UIAlertView alloc]initWithTitle:RDLocalizedString(@"无法访问媒体资料库",nil) message:RDLocalizedString(@"请更改设置，启用媒体资料库权限",nil) delegate:self cancelButtonTitle:RDLocalizedString(@"取消",nil) otherButtonTitles:RDLocalizedString(@"设置",nil), nil];
            commonAlertView.tag = 200;
            [commonAlertView show];
        }else {
            isMusicAuthorized = YES;
            [self getMusicList];
        }
    }else{
        if ( MPMediaLibrary.authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized)
        {
            //打开了用户访问权限
            isMusicAuthorized = YES;
            [self getMusicList];
        } else {
            //没有权限提示用户是否允许访问
            [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus authorizationStatus)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if ( authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized )
                     {
                         NSLog(@"允许访问");
                         isMusicAuthorized = YES;
                         [self getMusicList];
                     } else {
                         NSLog(@"禁止访问音乐库");
                         if (commonAlertView) {
                             commonAlertView.delegate = nil;
                             commonAlertView = nil;
                         }
                         commonAlertView = [[UIAlertView alloc]initWithTitle:RDLocalizedString(@"无法访问媒体资料库",nil) message:RDLocalizedString(@"请更改设置，启用媒体资料库权限",nil) delegate:self cancelButtonTitle:RDLocalizedString(@"取消",nil) otherButtonTitles:RDLocalizedString(@"设置",nil), nil];
                         commonAlertView.tag = 200;
                         [commonAlertView show];
                     }
                 });
             }];
        }
    }
}

- (void)getMusicList {
    [self loadVideo];
    MPMediaQuery *myPlaylistsQuery = [MPMediaQuery songsQuery];
    NSArray *playlists = [myPlaylistsQuery items];
    for (MPMediaItem *song in playlists) {
        [_libraryMusicArray addObject:song];
    }
    
    
    myPlaylistsQuery = nil;
    playlists = nil;
    [_localMusicTableView reloadData];
}

- (void)initTitleView {
    UIView *titleView = [[UIView alloc] init];
    if (isMusicAuthorized && isAlbumAuthorized) {
        titleView.frame = CGRectMake((kWIDTH - 200)/2.0, 27, 200, 30);
    }else {
        titleView.frame = CGRectMake((kWIDTH - 100)/2.0, 27, 100, 30);
    }
    titleView.layer.borderColor = [UIColor whiteColor].CGColor;
    titleView.layer.borderWidth = 1;
    titleView.layer.masksToBounds = YES;
    titleView.layer.cornerRadius = 5.0;
    self.navigationItem.titleView = titleView;
    
    UIImage *selectedImage = [RDHelpClass rdImageWithColor:[UIColor whiteColor] cornerRadius:0];
    if (isMusicAuthorized) {
        localMusicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (isAlbumAuthorized) {
            localMusicBtn.frame = CGRectMake(0, 1, titleView.frame.size.width/2-0.5, titleView.frame.size.height-2);
        }else {
            localMusicBtn.frame = CGRectMake(titleView.frame.size.width/2.0, 1, titleView.frame.size.width, titleView.frame.size.height-2);
        }
        [localMusicBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [localMusicBtn setTitle:RDLocalizedString(@"本地音乐", nil) forState:UIControlStateNormal];
        [localMusicBtn setTitle:RDLocalizedString(@"本地音乐", nil) forState:UIControlStateSelected];
        [localMusicBtn setTitleColor:UIColorFromRGB(0x8d8e93) forState:UIControlStateNormal];
        [localMusicBtn setTitleColor:UIColorFromRGB(0x27262c)  forState:UIControlStateSelected];
        [localMusicBtn addTarget:self action:@selector(localMusicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        localMusicBtn.selected = YES;
        localMusicBtn.font = [UIFont systemFontOfSize:16];
        [titleView addSubview:localMusicBtn];
    }
    if (isAlbumAuthorized) {
        albumVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (isMusicAuthorized) {
            albumVideoBtn.frame = CGRectMake(titleView.frame.size.width/2+0.5, 1, titleView.frame.size.width/2-0.5, titleView.frame.size.height-2);
        }else {
            albumVideoBtn.frame = CGRectMake(titleView.frame.size.width/2.0, 1, titleView.frame.size.width, titleView.frame.size.height-2);
        }
        [albumVideoBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [albumVideoBtn setTitle:RDLocalizedString(@"视频音乐", nil) forState:UIControlStateNormal];
        [albumVideoBtn setTitle:RDLocalizedString(@"视频音乐", nil) forState:UIControlStateSelected];
        albumVideoBtn.font = [UIFont systemFontOfSize:16];
        [albumVideoBtn setTitleColor:UIColorFromRGB(0x8d8e93) forState:UIControlStateNormal];
        [albumVideoBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateSelected];
        [albumVideoBtn addTarget:self action:@selector(albumVideoBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [titleView addSubview:albumVideoBtn];
    }
}

#pragma mark - 加载相册
- (void)loadVideo {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied)
    {
        if (commonAlertView) {
            commonAlertView.delegate = nil;
            commonAlertView = nil;
        }
        commonAlertView = [[UIAlertView alloc]initWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                                    message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                                   delegate:self
                                          cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                          otherButtonTitles:RDLocalizedString(@"确定",nil), nil];
        commonAlertView.tag = 201;
        [commonAlertView show];
    }else{
        isAlbumAuthorized = YES;
        [self initTitleView];
        
        [self loadDatasource];
    }
}

- (void)loadDatasource{
    albumVideoArray = [NSMutableArray array];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
//    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];//modificationDate
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        if (![collection isKindOfClass:[PHAssetCollection class]]// 有可能是PHCollectionList类的的对象，过滤掉
            || collection.estimatedAssetCount <= 0)// 过滤空相册
        {
            continue;
        }
        if ([RDHelpClass isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            for (PHAsset *asset in fetchResult) {
                if (asset.mediaType == PHAssetMediaTypeVideo) {
                    [albumVideoArray insertObject:asset atIndex:0];
                }
            }
            break;
        }
    }
    [albumVideo reloadData];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 200){
        isMusicAuthorized = NO;
        if(buttonIndex == 1){
            [RDHelpClass enterSystemSetting];
        }else{
            [self loadVideo];
        }
    }else if (alertView.tag == 201) {
        isAlbumAuthorized = NO;
        if (buttonIndex == 1) {
            [RDHelpClass enterSystemSetting];
        }else{
            [self loadVideo];
        }
    }
}

- (void)back{
    if (commonAlertView) {
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
    if(_backBlock){
        _backBlock();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

/**完成选择添加
 */
- (void)done{
    AVURLAsset *musicAsset=[[AVURLAsset alloc]initWithURL:_selectedMusicURL options:nil];
    float duration =CMTimeGetSeconds([musicAsset duration]);
    
    CMTimeRange musicTimeRange;
    musicTimeRange.start   =CMTimeMakeWithSeconds(_audioSlider.lowerValue*duration, TIMESCALE);
    musicTimeRange.duration=CMTimeMakeWithSeconds((_audioSlider.upperValue - _audioSlider.lowerValue)*duration,TIMESCALE);
    
    NSLog(@"%@",_selectedMusicURL.path);
    
    RDMusic *music = [[RDMusic alloc] init];
    music.clipTimeRange = musicTimeRange;//CMTimeRangeMake(kCMTimeZero, musicAsset.duration);
    music.name = _selectedMusicName;
    music.url = _selectedMusicURL;
    music.isRepeat = YES;
    music.volume = 0.5;
    music.isFadeInOut = YES;
    NSLog(@"%lf || %lf",CMTimeGetSeconds(music.clipTimeRange.start),CMTimeGetSeconds(music.clipTimeRange.duration));
    [self stopPlayAudio];
   
    if(_selectLocalMusicBlock){
        _selectLocalMusicBlock(music);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)localMusicBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        albumVideoBtn.selected = NO;
        sender.selected = YES;
        albumVideo.hidden = YES;
        _localMusicTableView.hidden = NO;
        if( (!_libraryMusicArray) || _libraryMusicArray.count == 0 )
        {
            _localMusicTableView.hidden = YES;
            self.noLocalMusicView.hidden = NO;
        }
    }
}

- (void)albumVideoBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        localMusicBtn.selected = NO;
        sender.selected = YES;
        albumVideo.hidden = NO;
        _localMusicTableView.hidden = YES;
        if( (!_libraryMusicArray) || _libraryMusicArray.count == 0 )
            self.noLocalMusicView.hidden = YES;
    }
}

#pragma mark- audioSliderTouchChange
/**开始滑动音乐进度条
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

/**正在滑动音乐进度条
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

/**音乐进度条滑动结束
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

/**初始化选中我的音乐——预览音乐界面
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
        AVURLAsset *url = [AVURLAsset assetWithURL:_selectedMusicURL];
        _duration =url.duration.value/url.duration.timescale ;
        
        _audioSlider.durationValue = _duration;
        
    }else{
        _audioSlider.durationValue = 0;
    }
    
    UIImage* image = nil;
    
    image = [RDHelpClass rdImageWithColor:(UIColorFromRGB(0x545454)) cornerRadius:0];
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
    
    _lowerLabel = [[UILabel alloc] init];
    
    _lowerLabelBack = [[UIImageView alloc] init];
    _lowerLabelBack.frame = CGRectMake(_audioSlider.frame.origin.x, _audioSlider.frame.origin.y-30, 42, 32);
    
    _lowerLabel.textColor = [UIColor whiteColor];
    _lowerLabel.textAlignment = NSTextAlignmentCenter;
    _lowerLabel.font = [UIFont systemFontOfSize:12];
    _lowerLabel.frame = CGRectMake(0, 0, 42, 25);
    _lowerLabel.backgroundColor = [UIColor clearColor];
    
    [_lowerLabelBack addSubview:_lowerLabel];
    
    _upperLabel = [[UILabel alloc] init];
    
    
    
    _upperLabelBack         = [[UIImageView alloc] init];
    _upperLabelBack.frame   = CGRectMake(0, _audioSlider.frame.origin.y-30, 42, 32);
    
    
    _upperLabel.textColor       = [UIColor whiteColor];
    _upperLabel.textAlignment   = NSTextAlignmentCenter;
    _upperLabel.font            = [UIFont systemFontOfSize:12];
    _upperLabel.frame           = CGRectMake(0, 0, 42, 25);
    _upperLabel.backgroundColor = [UIColor clearColor];
    
    
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
    
    _lowerLabel.text = [RDHelpClass timeToStringNoSecFormat:0.0];
    _upperLabel.text = [RDHelpClass timeToStringNoSecFormat:_duration];
    [_audioSlider setNeedsLayout];
    [self updateSliderLabels:@"00:00" stop:[RDHelpClass timeToStringNoSecFormat:_duration]];
}
/**更新悬浮提示的位置和显示内容
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
    return _libraryMusicArray.count;
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
            UITableViewCell *cell_ = [tableView dequeueReusableCellWithIdentifier:identifier_];
            
            if (cell_ == nil){
                
                cell_ = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier_];
                cell_.backgroundColor = SCREEN_BACKGROUND_COLOR;
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
                selectCellBtn.frame = CGRectMake(tableView.frame.size.width-60, 13, 50, 30);
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
            
            MPMediaItem *song = [_libraryMusicArray objectAtIndex:indexPath.row];
            NSString *mname = song.title;
            if(mname)
                musicNameLabel.text = mname;
#if 0   //20171026 wuxiaoxia 有的音频文件返回时长不正确
            double duration = [[song valueForKey:MPMediaItemPropertyPlaybackDuration] doubleValue];
            musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:duration];
#else
            AVURLAsset *musicAsset = [AVURLAsset assetWithURL:[song valueForProperty:MPMediaItemPropertyAssetURL]];
            musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:CMTimeGetSeconds(musicAsset.duration)];
#endif
            mname = nil;
            
            return cell_;
        }
        else{   //非选中状态
            static NSString *identifier = @"cell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            
            if (cell == nil){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                
                UIImageView *cellBackImageView  = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, kCellNormalHeight)];
                cellBackImageView.tag           = indexPath.row;
                cellBackImageView.backgroundColor = [UIColor clearColor];
                
                UIView *spanView2           = [[UIView alloc] initWithFrame:CGRectMake(60, cellBackImageView.frame.size.height-0.5, cellBackImageView.frame.size.width-70, 0.5)];
                spanView2.backgroundColor   = UIColorFromRGB(0x62626e);
                [cellBackImageView addSubview:spanView2];
                
                cell.backgroundColor = SCREEN_BACKGROUND_COLOR;
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
            
            MPMediaItem *song = [_libraryMusicArray objectAtIndex:indexPath.row];
            NSString *mname = song.title;
            if(mname)
                musicNameLabel.text = mname;
#if 0   //20171026 wuxiaoxia 有的音频文件返回时长不正确
            double duration = [[song valueForKey:MPMediaItemPropertyPlaybackDuration] doubleValue];
            musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:duration];
#else
            AVURLAsset *musicAsset = [AVURLAsset assetWithURL:[song valueForProperty:MPMediaItemPropertyAssetURL]];
            musicDurationLabel.text = [RDHelpClass timeToStringNoSecFormat:CMTimeGetSeconds(musicAsset.duration)];
#endif
            
            mname = nil;
           
            return cell;
        }
        return nil;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!_selectIndex){
        _selectIndex = indexPath;
        
        _selectSection = indexPath.section;
        
        [self slectTableView:tableView didSelectRowAtIndexPath:indexPath same:YES];
        
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
            
            //收起上次点击展开的cell;
            NSIndexPath *tempIndexPath = [_selectIndex copy];
            _selectIndex = nil;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:tempIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            //展开新选择的cell;
            _selectIndex = indexPath;
            
            [self slectTableView:tableView didSelectRowAtIndexPath:indexPath same:NO];
            
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_selectIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
        
    }
    _lastSelectMusicIndex = indexPath.row;
    [_localMusicTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    
}

/**选中当前行的音乐
 */
-(void)slectTableView:(UITableView *)slectTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath same:(BOOL)sameCell{
    
    
    MPMediaItem *song = [_libraryMusicArray objectAtIndex:indexPath.row];
    _selectedMusicName = [NSString stringWithFormat:@"%@", [song valueForKey:MPMediaItemPropertyTitle]];
    _selectedMusicURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    
    AVURLAsset *musicAsset = [AVURLAsset assetWithURL:_selectedMusicURL];
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(_selectIndex && _selectIndex.row == indexPath.row && _selectIndex.section == indexPath.section){
        return NO;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
}


/**播放或暂停缓存音乐
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

/**更新播放器进度
 */
- (void)updateAduioProgress{
    if (_audioSlider.progressTrack.frame.size.width >= _audioSlider.upperCenter.x-_audioSlider.lowerCenter.x - _audioSlider.lowerHandle.bounds.size.width) {
        
        [_audioProgressTimer invalidate];
        _audioProgressTimer=nil;
        [_audioPlayer pause];
        _isPlaying=NO;
        [_audioPlayButton setImage:[RDHelpClass imageWithContentOfFile:@"jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
    }else{
        double progress =CMTimeGetSeconds(CMTimeMakeWithSeconds(_audioPlayer.currentTime, TIMESCALE)) - (_audioSlider.lowerHandle.frame.origin.x/_audioSlider.frame.size.width)*_duration;
        //        NSLog(@"progress:%lf",progress);
        
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



/**初始化音乐播放器
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
            AVURLAsset *urlAsset=[[AVURLAsset alloc]initWithURL:_selectedMusicURL options:nil];
            _duration=CMTimeGetSeconds([urlAsset duration]);
            NSLog(@"%@",_selectedMusicURL.path);
       
            NSLog(@"playerError:%@",playerError);
            _audioPlayer.delegate=self;
            _audioPlayer.enableRate = YES;
            _audioPlayer.rate = 1.0;
            _isPlaying = NO;
            [self audioPlayOrPause];
        }
    }
}


/**停止播放音乐
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
        
        float startTime=_audioSlider.lowerValue*_audioSlider.durationValue;
        [_audioPlayer setCurrentTime:startTime];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return albumVideoArray.count;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"albumCell";
    //缩率图的大小这个地方数值不能设置大了
    float thumbWidth = 80;
    LocalPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if(!cell){
        cell = [[LocalPhotoCell alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    }
    cell.addBtn.hidden = YES;
    
    if (indexPath.row == 0) {
        cell.titleLbl.hidden = NO;
        cell.titleLbl.text = RDLocalizedString(@"其他\n相册", nil);
        cell.ivImageView.image = nil;
        cell.ivImageView.hidden = YES;
        cell.durationBlack.hidden = YES;
        return cell;
    }else {
        cell.titleLbl.hidden = YES;
        cell.ivImageView.hidden = NO;
        //视频集
        if(collectionView.tag == 1){
            if([albumVideoArray[indexPath.row-1] isKindOfClass:[NSDictionary class]]){
                NSDictionary *dic = albumVideoArray[indexPath.row-1];
                UIImage *thumbImage = [dic objectForKey:@"thumbImage"];
                cell.durationBlack.hidden = NO;
                cell.duration.hidden = NO;
                double duration = CMTimeGetSeconds([[dic objectForKey:@"durationTime"] CMTimeValue]);
                cell.duration.text = [RDHelpClass timeToStringFormat:duration];
                [cell.ivImageView setImage:thumbImage];
            }
            else if([albumVideoArray[indexPath.row-1] isKindOfClass:[PHAsset class]]){
                PHAsset *asset=albumVideoArray[indexPath.row-1];
                cell.durationBlack.hidden = NO;
                cell.duration.hidden = NO;
                double duration = asset.duration;
                cell.duration.text = [RDHelpClass timeToStringFormat:duration];
                if([[RD_ImageManager manager] isICloudnoDownLoad:asset]){
                    cell.icloudIcon.hidden = NO;
                }else{
                    cell.icloudIcon.hidden = YES;
                }
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                        cell.ivImageView.userInteractionEnabled = YES;
                        [cell.ivImageView setImage:photo];
                        cell.userInteractionEnabled = YES;
                    }
                }];
            }
            return cell;
        }
    }
    return cell;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    LocalPhotoCell *cell = (LocalPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.videoMark.hidden = YES;
    if(indexPath.row == 0){
        RDOtherAlbumsViewController *otherAlbumsVC = [[RDOtherAlbumsViewController alloc] init];
        if (collectionView.tag == 1) {
            otherAlbumsVC.supportFileType = ONLYSUPPORT_VIDEO;
        }else if (collectionView.tag == 2) {
            otherAlbumsVC.supportFileType = ONLYSUPPORT_IMAGE;
        }
        WeakSelf(self);
        otherAlbumsVC.finishBlock = ^(NSURL *url, UIImage *thumbImage) {
            StrongSelf(self);
            [strongSelf selectFile:url];
        };
        [self.navigationController pushViewController:otherAlbumsVC animated:YES];
        
    }else{
        WeakSelf(self);
        NSInteger index = [collectionView indexPathForCell:cell].row - 1;
        if([albumVideoArray[index] isKindOfClass:[NSMutableDictionary class]]){
            AVURLAsset *resultAsset = [albumVideoArray[index] objectForKey:@"urlAsset"];
            
            cell.icloudIcon.hidden = YES;
            [cell.progressView setPercent:0];
            [self selectFile:resultAsset.URL];
        }else{
            PHAsset *resouceAsset = albumVideoArray[index];
            PHVideoRequestOptions *opt_s = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
            opt_s.version = PHVideoRequestOptionsVersionOriginal;
            opt_s.networkAccessAllowed = NO;
            [[PHImageManager defaultManager] requestAVAssetForVideo:resouceAsset options:opt_s resultHandler:^(AVAsset * _Nullable asset_l, AVAudioMix * _Nullable audioMix_l, NSDictionary * _Nullable info_l) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    StrongSelf(self);
                    if(asset_l){
                        cell.isDownloadingInLocal = NO;
                        NSURL *fileUrl = [asset_l valueForKey:@"URL"];
                        NSString *localID = resouceAsset.localIdentifier;
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
                        [strongSelf selectFile:asseturl];
                        return;
                    }
                    if(cell.isDownloadingInLocal){
                        return;
                    }
                    cell.isDownloadingInLocal = YES;
                    [strongSelf.hud setCaption:RDLocalizedString(@"Videos are syncing from iCloud, please retry later", nil)];
                    [strongSelf.hud show];
                    [strongSelf.hud hideAfter:1];                    
                    
                    PHVideoRequestOptions *opts = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
                    opts.version = PHVideoRequestOptionsVersionOriginal;
                    opts.networkAccessAllowed = YES;
                    opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                        [cell.progressView setPercent:progress];
                    };
                    [[PHImageManager defaultManager] requestAVAssetForVideo:resouceAsset options:opts resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            cell.isDownloadingInLocal = NO;
                            [cell.progressView setPercent:0];
                            cell.icloudIcon.hidden = YES;
                        });
                    }];
                });
            }];
        }
    }
}

-(void)selectFile:(NSURL *)url
{
    if( isSelect )
        return;
    
    isSelect = TRUE;
    
    RDFile *file = [RDFile new];
    file.contentURL = url;
    file.fileType = kFILEVIDEO;
    file.isReverse = NO;
    AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
    CMTime duration = asset.duration;
    file.videoDurationTime = duration;
    
    
    
//    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
    file.videoTimeRange = [RDVECore getActualTimeRange:file.contentURL];
    file.reverseVideoTimeRange = file.videoTimeRange;
    file.videoTrimTimeRange = kCMTimeRangeInvalid;
    file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
    file.videoVolume = 1.0;
    file.speedIndex = 2;
    file.isVerticalMirror = NO;
    file.isHorizontalMirror = NO;
    file.speed = 1;
    file.crop = CGRectMake(0, 0, 1, 1);
    
    
    
    [self performSelector:@selector(initExtractAudioView:) withObject:file afterDelay:0.5];
}

-(void)initExtractAudioView:( RDFile * ) file
{
    RDExtractAudioViewController *coverVC = [[RDExtractAudioViewController alloc] init];
    coverVC.file = file;
    coverVC.outputPath = [self getSaveFIleDir:file.contentURL atPosion:@"VAuidio" atExtensionName:@""];
    coverVC.isExtract = NO;
    coverVC.finishAction = ^(NSString *outputPath, CMTimeRange videoTimeRange) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@",outputPath);
            _selectedMusicURL = file.contentURL;
            _selectedMusicName = RDLocalizedString(@"视频音频", nil);
            RDMusic *music = [[RDMusic alloc] init];
            music.clipTimeRange = videoTimeRange;//CMTimeRangeMake(kCMTimeZero, musicAsset.duration);
            music.name = _selectedMusicName;
            music.url = _selectedMusicURL;
            music.isRepeat = YES;
            music.volume = 0.5;
            music.isFadeInOut = YES;
            NSLog(@"%lf || %lf",CMTimeGetSeconds(music.clipTimeRange.start),CMTimeGetSeconds(music.clipTimeRange.duration));
            if(_selectLocalMusicBlock){
                _selectLocalMusicBlock(music);
            }
            isSelect = false;
            [self.navigationController popViewControllerAnimated:YES];
        });
    };
    coverVC.cancelAction = ^{
        isSelect = false;
    };
    
    [self.navigationController pushViewController:coverVC animated:YES];
}

-(NSString *)getSaveFIleDir:(NSURL *)url atPosion:(NSString *) str atExtensionName:(NSString*) Extension
{
    NSString *fileName = @"";
    if ([url.scheme.lowercaseString isEqualToString:@"ipod-library"]
        || [url.scheme.lowercaseString isEqualToString:@"assets-library"])
    {
        NSRange range = [url.absoluteString rangeOfString:@"?id="];
        if (range.location != NSNotFound) {
            fileName = [url.absoluteString substringFromIndex:range.length + range.location];
            range = [fileName rangeOfString:@"&ext"];
            fileName = [fileName substringToIndex:range.location];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }
    }else {
        NSRange range = [url.absoluteString rangeOfString:@"Bundle/Application/"];
        if (range.location != NSNotFound) {
            fileName = [[url.path lastPathComponent] stringByDeletingPathExtension];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmssSSS";
            NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            fileName = [fileName stringByAppendingString:nowTimeStr];
        }else {
            fileName = [[url.path lastPathComponent] stringByDeletingPathExtension];
        }
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths objectAtIndex:0];
    fileName = [NSString stringWithFormat:@"%@-%@",fileName,str];
    return [[folderPath stringByAppendingPathComponent:fileName] stringByAppendingString:Extension];
}

#pragma mark- 无本地音乐
-(UIView *)noLocalMusicView
{
    if( !_noLocalMusicView )
    {
        _noLocalMusicView = [[UIView alloc] initWithFrame:_localMusicTableView.frame];
        [self.view addSubview:_noLocalMusicView];
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake((_noLocalMusicView.frame.size.width - (_noLocalMusicView.frame.size.height*0.091*0.983 - 10) )/2.0, _noLocalMusicView.frame.size.height*0.226, _noLocalMusicView.frame.size.height*0.091*0.983 - 10, _noLocalMusicView.frame.size.height*0.091 - 10)];
        [_noLocalMusicView addSubview:imageView];
        imageView.image = [RDHelpClass imageWithContentOfFile:@"resourceItems/resourceItem/musics/配乐_无本地音乐_"];
        
        UILabel * textLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(0, imageView.frame.size.height + imageView.frame.origin.y + 30, _noLocalMusicView.frame.size.width, 20)];
        textLabel1.font = [UIFont systemFontOfSize:14];
        textLabel1.textColor = UIColorFromRGB(0x8b8a8f);
        textLabel1.textAlignment = NSTextAlignmentCenter;
        textLabel1.text = RDLocalizedString(@"还没有音乐", nil);
        [_noLocalMusicView addSubview:textLabel1];
        
        UILabel * textLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, textLabel1.frame.size.height + textLabel1.frame.origin.y + 10, _noLocalMusicView.frame.size.width, 20)];
        textLabel2.font = [UIFont systemFontOfSize:12];
        textLabel2.textAlignment = NSTextAlignmentCenter;
        textLabel2.textColor = UIColorFromRGB(0x8b8a8f);
        textLabel2.text = RDLocalizedString(@"iTunes视频", nil);
        [_noLocalMusicView addSubview:textLabel2];
        
        UILabel * textLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(0, textLabel2.frame.size.height + textLabel2.frame.origin.y, _noLocalMusicView.frame.size.width, 20)];
        textLabel3.font = [UIFont systemFontOfSize:12];
        textLabel3.textAlignment = NSTextAlignmentCenter;
        textLabel3.textColor = UIColorFromRGB(0x8b8a8f);
        textLabel3.text = RDLocalizedString(@"或是通过iTunes将电脑上的歌曲同步到j您的设备上", nil);
        [_noLocalMusicView addSubview:textLabel3];
        [self.view addSubview:_noLocalMusicView];
        _noLocalMusicView.hidden = YES;
    }
    return _noLocalMusicView;
}

@end
