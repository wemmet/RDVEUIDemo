//
//  AETemplateInfoViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/10/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AETemplateInfoViewController.h"
#import "RDNavigationViewController.h"
#import "RD_RDReachabilityLexiu.h"
#import "RDATMHud.h"
#import "RDSVProgressHUD.h"
#import "RDMBProgressHUD.h"
#import "CreateAEVideoViewController.h"
#import "RDPlayer.h"
#import "RDFileDownloader.h"
#import "RDZipArchive.h"
#import "RDMainViewController.h"
#import "AETemplateInfoTableViewCell.h"

@interface AETemplateInfoViewController ()<RDPlayerDelegate, RDMBProgressHUDDelegate, AETemplateInfoTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource>
{
    UITableView                 *templateInfoTableView;
    AETemplateInfoTableViewCell *currentCell;
    AETemplateInfoTableViewCell *prevCell;
    RDPlayer                    *player;
    BOOL                         isResignActive;
    RDATMHud                    *hud;
    RDMBProgressHUD             *progressHUD;
    NSError                     *playerError;
    BOOL                         isNeedPlay;
    NSInteger                    prevIndex;
}

@end

@implementation AETemplateInfoViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //工具栏 是否半透明
    self.navigationController.navigationBar.translucent = iPhone4s;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);    
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.title = [_templateInfoArray[_currentIndex] objectForKey:@"name"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:hud.view];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!currentCell) {
        if (_currentIndex != 0) {
            templateInfoTableView.contentOffset = CGPointMake(0, _currentIndex*templateInfoTableView.frame.size.height);
        }
        currentCell = [templateInfoTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_currentIndex inSection:0]];
        [self refreshCurrentCell];
    }else if (!player) {
        [self initPlayer];
    }
    if (playerError) {
        [hud setCaption:playerError.localizedDescription];
        [hud show];
        [hud hideAfter:2];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [player stop];
    [player removeFromSuperview];
    player = nil;
    [hud.view removeFromSuperview];
    hud.delegate = nil;
    [hud releaseHud];
    hud = nil;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    [currentCell.playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initNavigationItem];
    [self initTemplateInfoTableView];
}

- (void)initNavigationItem{
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [leftBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    leftBtn.titleLabel.textAlignment=NSTextAlignmentRight;
    [leftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [leftBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        spaceItem.width=-9;
    }else{
        spaceItem.width=0;
    }
    
    UIBarButtonItem *leftButton= [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    leftBtn.exclusiveTouch=YES;
    leftButton.tag = 1;
    self.navigationItem.leftBarButtonItems = @[spaceItem,leftButton];
}

- (void)initTemplateInfoTableView {
    templateInfoTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT - (iPhone_X ? 88 : 64)) style:UITableViewStylePlain];
    templateInfoTableView.backgroundColor = [UIColor clearColor];
    templateInfoTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    templateInfoTableView.delegate = self;
    templateInfoTableView.dataSource = self;
    templateInfoTableView.pagingEnabled = YES;
    if (iPhone_X) {
        templateInfoTableView.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
    templateInfoTableView.estimatedRowHeight = templateInfoTableView.frame.size.height;
    templateInfoTableView.estimatedSectionHeaderHeight = 0;
    templateInfoTableView.estimatedSectionFooterHeight = 0;
    [self.view addSubview:templateInfoTableView];
}

- (void)initPlayer {
    isNeedPlay = YES;
    WeakSelf(self);
    if (player) {
        [player removeFromSuperview];
        [currentCell.playerView insertSubview:player atIndex:0];
        [player setPlayerFrame:currentCell.playerView.bounds];
        [player setUrlPath:[_templateInfoArray[_currentIndex] objectForKey:@"video"]
         completionHandler:^(NSError *error) {
            StrongSelf(self);
            if (strongSelf) {
                strongSelf->playerError = error;
                if (!error) {
                    strongSelf->player.mute = NO;
                    strongSelf->player.onlyCache = NO;
                    strongSelf->player.repeat = NO;
                    if (!strongSelf->isResignActive && strongSelf->isNeedPlay) {
                        [strongSelf playVideo:YES];
                    }
                }
            }
        }];
    }else {
        player = [[RDPlayer alloc] initWithFrame:currentCell.playerView.bounds
                                         urlPath:[_templateInfoArray[_currentIndex] objectForKey:@"video"]
                                        delegate:self
                               completionHandler:^(NSError *error) {
                                StrongSelf(self);
                                  if (strongSelf) {
                                      strongSelf->playerError = error;
                                      if (!error) {
                                          strongSelf->player.mute = NO;
                                          strongSelf->player.onlyCache = NO;
                                          strongSelf->player.repeat = NO;
                                          if (!strongSelf->isResignActive && strongSelf->isNeedPlay) {
                                              [strongSelf playVideo:YES];
                                          }
                                      }
                                  }
                               }];
        [currentCell.playerView insertSubview:player atIndex:0];
    }
}

#pragma mark - 按钮事件
- (void)back:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - AETemplateInfoTableViewCellDelegate
- (void)playOrPause {
    [self playVideo:!player.isplaying];
}

- (void)createVideo {
    isNeedPlay = NO;
    [self playVideo:NO];
    NSString *urlstr = [_templateInfoArray[_currentIndex] objectForKey:@"file"];
    
    NSString *file = [[[urlstr stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[urlstr lastPathComponent] stringByDeletingPathExtension]];
    NSString *path = [kMVAnimateFolder stringByAppendingPathComponent:file];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
    NSString *MVName;
    for (NSString *fileName in files) {
        if (![fileName isEqualToString:@"__MACOSX"]) {
            NSString *folderPath = [path stringByAppendingPathComponent:fileName];
            BOOL isDirectory = NO;
            BOOL isExists = [fm fileExistsAtPath:folderPath isDirectory:&isDirectory];
            if (isExists && isDirectory) {
                MVName = fileName;
                break;
            }
        }
    }
    NSString *jsonPath = [[path stringByAppendingPathComponent:MVName] stringByAppendingPathComponent:@"config.json"];
    
    if(files.count == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:jsonPath]){
        RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
        if([lexiu currentReachabilityStatus] == RDNotReachable){
            [hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
            [hud show];
            [hud hideAfter:2];
            return;
        }
        [self initProgressHUD:RDLocalizedString(@"请稍等...", nil)];
        __weak typeof(self) weakSelf = self;
        [RDFileDownloader downloadFileWithURL:urlstr cachePath:kMVAnimateFolder httpMethod:GET cancelBtn:progressHUD.cancelBtn progress:^(NSNumber *numProgress) {
            [weakSelf myProgressTask:[numProgress floatValue]];
        } finish:^(NSString *fileCachePath) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"下载完成");
                if(![fm fileExistsAtPath:path]){
                    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                }
                BOOL suc = [RDHelpClass OpenZipp:fileCachePath unzipto:path];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [progressHUD hide:NO];
                    if(suc){
                        NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
                        NSString *MVName;
                        for (NSString *fileName in files) {
                            if (![fileName isEqualToString:@"__MACOSX"]) {
                                NSString *folderPath = [path stringByAppendingPathComponent:fileName];
                                BOOL isDirectory = NO;
                                BOOL isExists = [fm fileExistsAtPath:folderPath isDirectory:&isDirectory];
                                if (isExists && isDirectory) {
                                    MVName = fileName;
                                    break;
                                }
                            }
                        }
                        NSString *jsonPath = [[path stringByAppendingPathComponent:MVName] stringByAppendingPathComponent:@"config.json"];
                        [weakSelf selectMedia:jsonPath fileName:file];
                    }
                });
            });
        } fail:^(NSError *error) {
            NSLog(@"下载失败");
            [progressHUD hide:NO];
        } cancel:^{
            [progressHUD hide:NO];
        }];
    }else {        
        [self selectMedia:jsonPath fileName:file];
    }
}

- (void)initProgressHUD:(NSString *)message{
    if (progressHUD) {
        progressHUD.delegate = nil;
        progressHUD = nil;
    }
    //圆形进度条
    progressHUD = [[RDMBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:progressHUD];
    progressHUD.removeFromSuperViewOnHide = YES;
    progressHUD.mode = RDMBProgressHUDModeDeterminate;
    progressHUD.animationType = RDMBProgressHUDAnimationFade;
    progressHUD.labelText = message;
    progressHUD.isShowCancelBtn = YES;
    progressHUD.delegate = self;
    [progressHUD show:YES];
    [self myProgressTask:0];
}

- (void)myProgressTask:(float)progress{
    [progressHUD setProgress:progress];
}

- (void)selectMedia:(NSString *)jsonPath fileName:(NSString *)fileName {
    NSDictionary *infoDic = _templateInfoArray[_currentIndex];
    int picCount = [infoDic[@"picture_need"] intValue];
    int videoCount = [infoDic[@"video_need"] intValue];
    if (videoCount == 0 && picCount == 0) {
        CreateAEVideoViewController *createVC = [[CreateAEVideoViewController alloc] init];
        createVC.templateName = infoDic[@"name"];
        createVC.fileName = fileName;
        createVC.jsonPath = jsonPath;
        createVC.isEnableRepeat = NO;
        [self.navigationController pushViewController:createVC animated:YES];
        return;
    }
    __weak typeof(self) weakSelf = self;
    SUPPORTFILETYPE type;
    if (videoCount == 0) {
        type = ONLYSUPPORT_IMAGE;
    }else {
        type = SUPPORT_ALL;
    }
    CGSize size = CGSizeMake([infoDic[@"width"] floatValue], [infoDic[@"height"] floatValue]);
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.textPhotoProportion = size.width/(float)size.height;
    if (type == ONLYSUPPORT_IMAGE) {
        mainVC.showPhotos = YES;
        if (currentCell.repeatSwitch.on) {
            mainVC.minCountLimit = picCount;
        }else {
            mainVC.picCountLimit = picCount;
        }
    }else {
        mainVC.videoCountLimit = videoCount;
        mainVC.picCountLimit = picCount + videoCount;
    }
    if (currentCell.repeatSwitch.on) {
        ((RDNavigationViewController *)self.navigationController).editConfiguration.mediaCountLimit =  0;
    }else {
        ((RDNavigationViewController *)self.navigationController).editConfiguration.mediaCountLimit =  videoCount + picCount;
    }
    ((RDNavigationViewController *)self.navigationController).editConfiguration.supportFileType = type;
    mainVC.isDisableEdit = YES;
    mainVC.selectFinishActionBlock = ^(NSMutableArray<RDFile *> *filelist) {
        StrongSelf(self);
        CreateAEVideoViewController *createVC = [[CreateAEVideoViewController alloc] init];
        createVC.templateName = infoDic[@"name"];
        createVC.fileName = fileName;
        createVC.jsonPath = jsonPath;
        createVC.files = filelist;
        if (picCount == 0) {
            createVC.isAllVideoOrPic = YES;
        }
        createVC.isEnableRepeat = strongSelf->currentCell.repeatSwitch.on;
        if (strongSelf->currentCell.repeatSwitch.on) {
            float count = filelist.count/(float)(picCount);
            createVC.repeatCount = ceilf(count);
        }
        [strongSelf.navigationController pushViewController:createVC animated:YES];
    };
    RDNavigationViewController * nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - RDPlayerDelegate
- (void)playerItemDidReachEnd:(RDPlayer *)player {
    [player seekToTime:kCMTimeZero toleranceTime:kCMTimeZero completionHandler:nil];
    [currentCell.videoProgressSlider setValue:0];
    [currentCell.playProgress setProgress:0 animated:NO];
    [currentCell.playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
    currentCell.playBtn.hidden = NO;
}

- (void)playCurrentTime:(CMTime)currentTime {
    currentCell.currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:MIN(CMTimeGetSeconds(currentTime), player.duration)];
    
    float progress = CMTimeGetSeconds(currentTime)/player.duration;
    if (!isinf(progress)) {
        [currentCell.videoProgressSlider setValue:progress];
        [currentCell.playProgress setProgress:progress animated:NO];
    }    
}

- (void)tapPlayer {
    if(currentCell.playerToolBar.hidden){
        [currentCell setPlayBtnHidden:NO];
    }else{
        [currentCell setPlayBtnHidden:YES];
    }
}

#pragma mark - 滑动进度条
- (void)changeVideoProgress:(float)progress {
    if(player.isplaying){
        [self playVideo:NO];
    }
    CGFloat current = progress * player.duration;
    [player seekToTime:CMTimeMakeWithSeconds(current, TIMESCALE) toleranceTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) completionHandler:nil];
    currentCell.currentTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:current];
}

- (void)playVideo:(BOOL)play{
    if(!play){
        [player pause];
        [currentCell.playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_播放_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [currentCell setPlayBtnHidden:NO];
    }else{
        if (isResignActive) {
            return;
        }
        [player play];
        [currentCell.playBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/剪辑_暂停_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [currentCell setPlayBtnHidden:YES];
    }
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _templateInfoArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *iCell = @"cell";
    AETemplateInfoTableViewCell *cell = [[AETemplateInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:iCell];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (currentCell && indexPath.row != _currentIndex) {
        _currentIndex = indexPath.row;
        currentCell = (AETemplateInfoTableViewCell *)cell;
        self.title = [_templateInfoArray[_currentIndex] objectForKey:@"name"];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (currentCell) {
        if (indexPath.row == _currentIndex) {
            _currentIndex = prevIndex;
            self.title = [_templateInfoArray[_currentIndex] objectForKey:@"name"];
            currentCell = prevCell;
        }else {
            [self refreshCurrentCell];
        }
    }
}

- (void)refreshCurrentCell {
    prevIndex = _currentIndex;
    prevCell = currentCell;
    [currentCell setInfoDic:_templateInfoArray[_currentIndex] cellHeight:templateInfoTableView.frame.size.height];
    self.title = [_templateInfoArray[_currentIndex] objectForKey:@"name"];
    [self initPlayer];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
