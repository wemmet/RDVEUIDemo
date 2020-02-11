//
//  RDChooseMusic.m
//  RDVEUISDK
//
//  Created by apple on 2019/6/20.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDChooseMusic.h"
#import "RDScollTitleView.h"
#import "RDScrollContentView.h"
#import "RDCloudMusicItemViewController.h"
#import "RD_RDReachabilityLexiu.h"
#import "RDHelpClass.h"
#import "RDATMHud.h"
#import "RDNavigationViewController.h"
#import "CustomWebViewController.h"

#import <MediaPlayer/MediaPlayer.h>
@interface RDChooseMusic ()<RDCloudMusicItemViewControllerDelegate,UITextViewDelegate,UIAlertViewDelegate>
{
    UIButton *_leftBtn;
    NSMutableArray *_cloudMusicList;
    BOOL            _customCloudMusic;
    RDATMHud       *_hud;
    NSMutableArray *_vcs;
    
    NSMutableArray              *_libraryMusicArray;
    RDCloudMusicItemViewController  *localMusicArray;
    UIAlertView                 *commonAlertView;
}
@property (nonatomic, strong) RDScollTitleView *titleView;

@property (nonatomic, strong) RDScrollContentView *contentView;
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation RDChooseMusic

//这个方法写在navagation里不行
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
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationItem setHidesBackButton:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    // 设置导航栏背景图片
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:TOOLBAR_COLOR cornerRadius:0.0];
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    _customCloudMusic = [((RDNavigationViewController *)self.navigationController).editConfiguration.cloudMusicResourceURL isEqualToString:@"http://dianbook.17rd.com/api/shortvideo/getcloudmusic"] ? NO : YES;
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:kMusicFolder]){
        [fileManager createDirectoryAtPath:kMusicFolder withIntermediateDirectories:YES attributes:nil error:&error];
    }
    if(![fileManager fileExistsAtPath:kMusicIconPath]){
        [fileManager createDirectoryAtPath:kMusicIconPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    if(![fileManager fileExistsAtPath:kMusicPath]){
        [fileManager createDirectoryAtPath:kMusicPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
//    _isLocal = NO;
    
    _leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_leftBtn setFrame:CGRectMake(0, (44 - 35)/2.0, 35, 35)];
    [_leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    _leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [_leftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
    [_leftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消点击_"] forState:UIControlStateHighlighted];
    _leftBtn.exclusiveTouch=YES;
    UIBarButtonItem *leftButton= [[UIBarButtonItem alloc] initWithCustomView:_leftBtn];
    UIBarButtonItem *spaceItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width=-9;
    self.navigationItem.leftBarButtonItems =@[spaceItem,leftButton];
    
    [self setupUI];
    [self reloadData];
}
#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 200){
        if(buttonIndex == 1){
            [RDHelpClass enterSystemSetting];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_libraryMusicArray removeAllObjects];
                
                _libraryMusicArray=[[NSMutableArray alloc]init];
                
                NSLog(@"允许访问");
                MPMediaQuery *myPlaylistsQuery = [MPMediaQuery songsQuery];
                NSArray *playlists = [myPlaylistsQuery items];
                for (MPMediaItem *song in playlists) {
                    [_libraryMusicArray addObject:song];
                }
                myPlaylistsQuery = nil;
                playlists = nil;
            });
        }
    }
}
#pragma mark- 获取数据
- (void)setLocalValue{
    [_libraryMusicArray removeAllObjects];
    
    _libraryMusicArray=[[NSMutableArray alloc]init];
    
    
    if([[[UIDevice currentDevice] systemVersion] floatValue]<9.3){
        //打开了用户访问权限
        MPMediaQuery *myPlaylistsQuery = [MPMediaQuery songsQuery];
        NSArray *playlists = [myPlaylistsQuery items];
        for (MPMediaItem *song in playlists) {
            [_libraryMusicArray addObject:song];
        }
        myPlaylistsQuery = nil;
        playlists = nil;
    }else{
        if ( MPMediaLibrary.authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                //打开了用户访问权限
                MPMediaQuery *myPlaylistsQuery = [MPMediaQuery songsQuery];
                NSArray *playlists = [myPlaylistsQuery items];
                for (MPMediaItem *song in playlists) {
                    [_libraryMusicArray addObject:song];
                }
                myPlaylistsQuery = nil;
                playlists = nil;
            });
        }
        else
        {
            //没有权限提示用户是否允许访问
            [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus authorizationStatus)
             {
                 if ( authorizationStatus == MPMediaLibraryAuthorizationStatusAuthorized )
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSLog(@"允许访问");
                         MPMediaQuery *myPlaylistsQuery = [MPMediaQuery songsQuery];
                         NSArray *playlists = [myPlaylistsQuery items];
                         for (MPMediaItem *song in playlists) {
                             [_libraryMusicArray addObject:song];
                         }
                         myPlaylistsQuery = nil;
                         playlists = nil;
                     });
                 }
                 else
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSLog(@"禁止访问音乐库");
                         if (commonAlertView) {
                             commonAlertView.delegate = nil;
                             commonAlertView = nil;
                         }
                         commonAlertView = [[UIAlertView alloc]initWithTitle:RDLocalizedString(@"无法访问媒体资料库",nil) message:RDLocalizedString(@"请更改设置，启用媒体资料库权限",nil) delegate:self cancelButtonTitle:RDLocalizedString(@"取消",nil) otherButtonTitles:RDLocalizedString(@"设置",nil), nil];
                         commonAlertView.tag = 200;
                         [commonAlertView show];
                     });
                 }
             }];
        }
    }
}

-(void)setTitile:(NSString *) title
{
    self.title = RDLocalizedString(title, nil);
}

- (void)setupUI{
    _hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:_hud.view];
    
    _titleView = [[RDScollTitleView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    _titleView.selectedBlock = ^(NSInteger index){
        __weak typeof(self) strongSelf = weakSelf;
        strongSelf.contentView.currentIndex = index;
    };
    _titleView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    _titleView.tintColor = Main_Color;
    _titleView.normalColor = [UIColor whiteColor];
    _titleView.selectedColor = [UIColor blackColor];
    _titleView.selectedIndex = _selectedIndex;
    [self.view addSubview:_titleView];
    
    _contentView = [[RDScrollContentView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.scrollBlock = ^(NSInteger index){
        __block typeof(self) strongSelf = weakSelf;
        strongSelf.titleView.selectedIndex = index;
    };
    [self.view addSubview:_contentView];
    
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    if(_customCloudMusic
       && (editConfig.newartist.length > 0
           || editConfig.newartistHomepageTitle.length > 0
           || editConfig.newmusicAuthorizationTitle.length > 0
           || editConfig.newartistHomepageUrl.length > 0
           || editConfig.newmusicAuthorizationUrl.length > 0))
    {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 49 - (iPhone_X ? 122 : 44), kWIDTH, 49)];
        _bottomView.backgroundColor = self.view.backgroundColor;
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        line.backgroundColor =UIColorFromRGB(0x62626e);
        [_bottomView addSubview:line];
        
        UITextView *singLabel = [[UITextView alloc] initWithFrame:CGRectMake(0, 1, _bottomView.frame.size.width, 48)];
        
        singLabel.textColor = [UIColor whiteColor];
        singLabel.userInteractionEnabled = YES;
        singLabel.editable = NO;
        singLabel.textAlignment = NSTextAlignmentCenter;
        singLabel.font = [UIFont systemFontOfSize:10];
        singLabel.backgroundColor = [UIColor clearColor];
        
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        [ps setAlignment:NSTextAlignmentCenter];
        [ps setLineSpacing:5];
        
        NSString *homepageTile;
        NSString *authorizationTitle;
        NSString *str = @"";
        if (editConfig.newartist.length > 0) {
            str = editConfig.newartist;
        }
        if (editConfig.newartistHomepageTitle.length > 0) {
            str = [str stringByAppendingString:[NSString stringWithFormat:@" %@", editConfig.newartistHomepageTitle]];
            homepageTile = editConfig.newartistHomepageTitle;
        }else if (editConfig.newartistHomepageUrl.length > 0) {
            str = [str stringByAppendingString:[NSString stringWithFormat:@" %@", editConfig.newartistHomepageUrl]];
            homepageTile = editConfig.newartistHomepageUrl;
        }
        if (editConfig.newmusicAuthorizationTitle.length > 0) {
            str = [str stringByAppendingString:[NSString stringWithFormat:@"\n%@", editConfig.newmusicAuthorizationTitle]];
            authorizationTitle = editConfig.newmusicAuthorizationTitle;
        }else if (editConfig.newmusicAuthorizationUrl.length > 0) {
            str = [str stringByAppendingString:[NSString stringWithFormat:@"\n%@", editConfig.newmusicAuthorizationUrl]];
            authorizationTitle = editConfig.newmusicAuthorizationUrl;
        }
        
        NSMutableAttributedString *attTitle = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10],NSForegroundColorAttributeName:UIColorFromRGB(0x8e8e93),NSParagraphStyleAttributeName:ps}];
        
        if (editConfig.newartistHomepageUrl.length > 0) {
            [attTitle addAttribute:NSLinkAttributeName value:editConfig.newartistHomepageUrl range:[str rangeOfString:homepageTile]];
            [attTitle addAttribute:NSUnderlineStyleAttributeName value:@(1) range:[str rangeOfString:homepageTile]];
        }
        
        if (editConfig.newmusicAuthorizationUrl.length > 0) {
            [attTitle addAttribute:NSLinkAttributeName value:editConfig.newmusicAuthorizationUrl range:[str rangeOfString:authorizationTitle]];
            [attTitle addAttribute:NSUnderlineStyleAttributeName value:@(1) range:[str rangeOfString:authorizationTitle]];
        }
        
        singLabel.delegate = self;
        NSDictionary *linkAttributes =@{NSForegroundColorAttributeName: UIColorFromRGB(0xababae)};
        singLabel.linkTextAttributes = linkAttributes;
        singLabel.attributedText = attTitle;
        [_bottomView addSubview:singLabel];
        [self.view addSubview:_bottomView];
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    if ([URL.absoluteString isEqualToString:editConfig.newmusicAuthorizationUrl]) {
        //授权证书点击事件
        CustomWebViewController *webView = [[CustomWebViewController alloc] init];
        webView.linkUrl = URL.absoluteString;
        if (editConfig.newmusicAuthorizationTitle.length > 0) {
            webView.linkTitle = editConfig.newmusicAuthorizationTitle;
        }else {
            webView.linkTitle = RDLocalizedString(@"授权证书", nil);
        }
        [self.navigationController pushViewController:webView animated:YES];
        return NO;
    }else if ([URL.absoluteString isEqualToString:editConfig.newartistHomepageUrl]) {
        //audionautix.com 点击事件
        [[UIApplication sharedApplication] openURL:URL];
        return NO;
    }
    return YES;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if([CloudMusicResourceURL isEqual:_cloudMusicResourceURL]){
        _titleView.frame = CGRectMake(0, 0, self.view.frame.size.width, 55);
        _contentView.frame = CGRectMake(0, 55, self.view.frame.size.width, self.view.frame.size.height - 55);
    }else{
        _titleView.frame = CGRectMake(0, 0, self.view.frame.size.width, 55);
        _contentView.frame = CGRectMake(0, 55, self.view.frame.size.width, self.view.frame.size.height - _bottomView.frame.size.height - 55);
    }
}

- (void)reloadData{
    
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    NSString *musicListPath = [kMusicFolder stringByAppendingPathComponent:@"cloudMusicList.plist"];
//    NSString *soundMusicListPath = [kMusicFolder stringByAppendingPathComponent:@"cloudMusicList.plist"];
    
    if( _isNOSound )
    {
        if( _isLocal )
            [self setLocalValue];
    }
    
    if([lexiu currentReachabilityStatus] == RDNotReachable){
        _cloudMusicList = [[NSArray arrayWithContentsOfFile:musicListPath] mutableCopy];
    }
    
    if(_cloudMusicList){
        if([lexiu currentReachabilityStatus] != RDNotReachable){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableDictionary *params;
                NSDictionary *dic;
                BOOL hasValue = NO;
                if(!_customCloudMusic){
                    params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios",@"type", nil];
                    dic = [RDHelpClass updateInfomationWithJson:params andUploadUrl:_cloudMusicResourceURL];
                    hasValue = [[dic objectForKey:@"state"] boolValue];
                }else{
                    params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"cloud_music_type",@"type",((RDNavigationViewController *)self.navigationController).appKey,@"appkey", nil];
                    
                    dic = [RDHelpClass updateInfomation:params andUploadUrl:_cloudMusicResourceURL];
                    hasValue = [[dic objectForKey:@"code"] integerValue]  == 0;
                }
                if(hasValue){
                    NSMutableArray *resultList;
                    if([[dic allKeys] containsObject:@"result"]){
                        resultList = [[dic objectForKey:@"result"] objectForKey:@"bgmusic"];
                    }else{
                        if([[dic objectForKey:@"data"] isKindOfClass:[NSArray class]]){
                            resultList = [dic objectForKey:@"data"];
                        }else{
                            resultList = [dic objectForKey:@"data"][@"data"];
                        }
                    }
                    if(resultList){
                        BOOL suc = [resultList writeToFile:musicListPath atomically:YES];
                        if (!suc) {
                            NSLog(@"写入失败");
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self refreshContentView];
                    });
                }
            });
        }else{
            [_hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
            [_hud show];
            [_hud hideAfter:2];
            
            [self refreshContentView];
        }
    }
    else{
        if([lexiu currentReachabilityStatus] != RDNotReachable){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if( !_isNOSound )
                {
                    NSDictionary *dic1 = [RDHelpClass getNetworkMaterialWithType:@"audio" appkey:((RDNavigationViewController *)self.navigationController).appKey urlPath:_soundMusicTypeResourceURL];
                    NSMutableArray *soundArray = [NSMutableArray alloc];
                    if( [[dic1 objectForKey:@"code"] integerValue] == 0 )
                    {
                        if([[dic1 objectForKey:@"data"] isKindOfClass:[NSArray class]]){
                            soundArray = [dic1 objectForKey:@"data"];
                        }
                        NSMutableArray *musicList = [[NSMutableArray alloc] init];
                        
                        for (int i = 0; soundArray.count > i; i++) {
                           
                            NSMutableDictionary * soundMusic = [NSMutableDictionary dictionary];
                            [soundMusic setObject:[soundArray[i] objectForKey:@"name"] forKey:@"name"];
                            [soundMusic setObject:[soundArray[i] objectForKey:@"id"]  forKey:@"musiclist"];
                            [musicList addObject:soundMusic];
                        }
                        _cloudMusicList = musicList;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self refreshContentView];
                        });
                    }
                }
                else
                {
                    if( [_cloudMusicResourceURL rangeOfString:@"http://d.56show.com/filemanage2/public/filemanage/file"].location == NSNotFound )
                    {
                        NSMutableDictionary *params;
                        NSDictionary *dic;
                        BOOL hasValue = NO;
                        if(!_customCloudMusic){
                            params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios",@"type", nil];
                            dic = [RDHelpClass updateInfomationWithJson:params andUploadUrl:_cloudMusicResourceURL];
                            hasValue = [[dic objectForKey:@"state"] boolValue];
                        }else{
                            dic = [RDHelpClass getNetworkMaterialWithType:@"cloud_music_type"
                                                                   appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                                  urlPath:_cloudMusicResourceURL];
                            hasValue = [[dic objectForKey:@"code"] integerValue] == 0;
                        }
                        if(hasValue){
                            NSMutableArray *musicList;
                            if([[dic allKeys] containsObject:@"result"]){
                                musicList = [[dic objectForKey:@"result"] objectForKey:@"bgmusic"];
                            }else{
                                if([[dic objectForKey:@"data"] isKindOfClass:[NSArray class]]){
                                    musicList = [dic objectForKey:@"data"];
                                }else{
                                    musicList = [dic objectForKey:@"data"][@"data"];
                                }
                            }
                            _cloudMusicList = musicList;
                            
                            if(musicList){
                                BOOL suc = [musicList writeToFile:musicListPath atomically:YES];
                                if (!suc) {
                                    NSLog(@"写入失败");
                                }
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self refreshContentView];
                            });
                        }
                    }
                    else
                    {
                        NSDictionary *dic1 = [RDHelpClass getNetworkMaterialWithType:@"cloud_music" appkey:((RDNavigationViewController *)self.navigationController).appKey urlPath:_soundMusicTypeResourceURL];
                        NSMutableArray *soundArray = [NSMutableArray alloc];
                        if( [[dic1 objectForKey:@"code"] integerValue] == 0 )
                        {
                            if([[dic1 objectForKey:@"data"] isKindOfClass:[NSArray class]]){
                                soundArray = [dic1 objectForKey:@"data"];
                            }
                            NSMutableArray *musicList = [[NSMutableArray alloc] init];
                            
                            for (int i = 0; soundArray.count > i; i++) {
                                
                                NSMutableDictionary * soundMusic = [NSMutableDictionary dictionary];
                                [soundMusic setObject:[soundArray[i] objectForKey:@"name"] forKey:@"name"];
                                [soundMusic setObject:[soundArray[i] objectForKey:@"id"]  forKey:@"musiclist"];
                                [musicList addObject:soundMusic];
                            }
                            _cloudMusicList = musicList;
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self refreshContentView];
                            });
                        }
                    }
                }
            });
        }else{
            [_hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
            [_hud show];
            [_hud hideAfter:2];
        }
    }
}

- (void)refreshContentView {
    NSMutableArray *titles = [NSMutableArray new];
    if( (_isNOSound) && (_libraryMusicArray.count > 0) )
        [titles addObject:RDLocalizedString(@"本地", nil)];
    
    for (int i = 0; i<_cloudMusicList.count; i ++){
        NSString *title = [_cloudMusicList[i] objectForKey:@"name"];
        [titles addObject:title];
        title = nil;
    }
    
    if (_cloudMusicList.count > 0) {
        [_titleView reloadViewWithTitles:titles];
    }else {
        [_titleView removeFromSuperview];
    }
    
    _vcs = [[NSMutableArray alloc] init];
    for (int i = 0; i<titles.count; i ++) {
        NSString *title = titles[i];
        RDCloudMusicItemViewController *vc = [[RDCloudMusicItemViewController alloc] init];
        vc.category = title;
        vc.vcIndex  = i;
        vc.musicItemDelegate = self;
        vc.isLocal = NO;
        
        if( _isNOSound )
        {
            if( (i > 0) || (_libraryMusicArray.count == 0) )
            {
                if( [_cloudMusicResourceURL rangeOfString:@"http://d.56show.com/filemanage2/public/filemanage/file"].location == NSNotFound )
                {
                    vc.sourceList = [_cloudMusicList[i-((_libraryMusicArray.count > 0)?1:0)] objectForKey:@"musiclist"];
                    vc.isSound = NO;
                }
                else
                {
                    vc.isSound = YES;
                    vc.id = [_cloudMusicList[i-((_libraryMusicArray.count > 0)?1:0)] objectForKey:@"musiclist"] ;
                    vc.soundMusicResourceURL = _soundMusicResourceURL;
                    vc.sourceList = nil;
                    vc.isCloud = YES;
                }
            }
            else
            {
                vc.isLocal = YES;
                vc.sourceList =  [NSArray arrayWithArray:_libraryMusicArray];
                localMusicArray = vc;
                vc.isSound = NO;
            }
        }
        else
        {
            vc.isSound = YES;
            vc.id = [_cloudMusicList[i] objectForKey:@"musiclist"];
            vc.soundMusicResourceURL = _soundMusicResourceURL;
            vc.sourceList = nil;
            vc.isCloud = NO;
        }
        [_vcs addObject:vc];
    }
    if (_vcs.count > 0) {
        [_contentView reloadViewWithChildVcs:_vcs parentVC:self];
    }
}

- (void)getMusicFile:(RDMusic *)music{
    if(_selectCloudMusic){
        _selectCloudMusic(music);
    }
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)back{
    if(_backBlock){
        _backBlock();
    }
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.navigationController.navigationBar.translucent = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTitleIndex" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
