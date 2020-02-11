//
//  RDCloudMusicViewController.m
//  RDVEUISDK
//

#import "RDCloudMusicViewController.h"
#import "RDScollTitleView.h"
#import "RDScrollContentView.h"
#import "RDCloudMusicItemViewController.h"
#import "RD_RDReachabilityLexiu.h"
#import "RDHelpClass.h"
#import "RDATMHud.h"
#import "RDNavigationViewController.h"
#import "CustomWebViewController.h"
@interface RDCloudMusicViewController ()<RDCloudMusicItemViewControllerDelegate,UITextViewDelegate>
{
    UIButton *_leftBtn;
    NSMutableArray *_cloudMusicList;
    BOOL            _customCloudMusic;
    RDATMHud       *_hud;
    NSMutableArray *_vcs;

}
@property (nonatomic, strong) RDScollTitleView *titleView;

@property (nonatomic, strong) RDScrollContentView *contentView;
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation RDCloudMusicViewController
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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
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
    self.title = RDLocalizedString(@"云音乐", nil);
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.translucent = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
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
    
    
    UIBarButtonItem *spaceItem;
    _leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [_leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    _leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [_leftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
    [_leftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消点击_"] forState:UIControlStateHighlighted];
    UIBarButtonItem *leftButton= [[UIBarButtonItem alloc] initWithCustomView:_leftBtn];
    spaceItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    _leftBtn.exclusiveTouch=YES;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        spaceItem.width=-9;
    }else{
        spaceItem.width=0;
    }
    self.navigationItem.leftBarButtonItems =@[spaceItem,leftButton];
    
    
    
    [self setupUI];
    [self reloadData];
}

- (void)setupUI{
    
    if(_hud.view.superview){
        [_hud.view removeFromSuperview];
    }
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
    _titleView.normalColor = UIColorFromRGB(0xffffff);
    _titleView.selectedColor = UIColorFromRGB(0x000000);
    
    _titleView.selectedIndex = _selectedIndex;
    [self.view addSubview:_titleView];
    
    _contentView = [[RDScrollContentView alloc] initWithFrame:CGRectZero];
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
        _bottomView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomView.frame = CGRectMake(0, self.view.frame.size.height - 49 - 45, self.view.frame.size.width, 49);
        _bottomView.backgroundColor = [UIColor clearColor];
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
        _bottomView.frame = CGRectMake(0, _contentView.frame.origin.y + _contentView.frame.size.height, self.view.frame.size.width, 49);
    }
}

- (void)reloadData{
    
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    NSString *musicListPath = [kMusicFolder stringByAppendingPathComponent:@"cloudMusicList.plist"];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
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
                    params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"cloud_music_type",@"type", nil];
                    if(((RDNavigationViewController *)self.navigationController).appKey.length>0)
                        [params setObject:((RDNavigationViewController *)self.navigationController).appKey forKey:@"appkey"];
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
        vc.sourceList = [_cloudMusicList[i] objectForKey:@"musiclist"];
        
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
