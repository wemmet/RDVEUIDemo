//
//  RDDraftViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDraftViewController.h"
#import "RDDraftCollectionViewCell.h"
#import "RDNextEditVideoViewController.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDATMHud.h"

#import "RDGenSpecialEffect.h"
#import "RD_VideoThumbnailView.h"

@interface RDDraftViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, RDDraftCollectionViewCellDelegate, RDVECoreDelegate>
{
    NSArray             *draftList;
    UICollectionView    *draftCollectionView;
    UIButton            *selectBtn;
    UIView              *bottomView;
    UIButton            *deleteBtn;
    UIButton            *selectAllBtn;
    BOOL                 isContinueExport;
    BOOL                 isResignActive;    //20171026 wuxiaoxia 导出过程中按Home键后会崩溃
    BOOL                _idleTimerDisabled;//20171101 emmet 解决不锁屏的bug
    RDDraftInfo         *publishDraft;
    NSMutableArray      *selectedDraftArray;
}
@property(nonatomic,strong)UIAlertView *commonAlertView;
@property(nonatomic,strong)RDExportProgressView *exportProgressView;
@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,strong)RDATMHud         *hud;

@end

@implementation RDDraftViewController

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
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:(UIColorFromRGB(0x27262c)) cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.title = RDLocalizedString(@"草稿箱", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    _hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.view addSubview:_hud.view];
}

- (void)applicationEnterHome:(NSNotification *)notification{
    isResignActive = YES;
    if(_exportProgressView && [notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        __block typeof(self) myself = self;
        [_videoCoreSDK cancelExportMovie:^{
            //更新UI需在主线程中操作
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself cancelExportBlock];
                //移除 “取消导出框”
                [myself.commonAlertView dismissWithClickedButtonIndex:0 animated:YES];
            });
        }];
    }
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    isResignActive = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_hud.view removeFromSuperview];
    _hud.delegate = nil;
    [_hud releaseHud];
    _hud = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initNavigationItem];
    [self initDraftCollectionView];
    [self initBottomView];
    
    UIView *tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 30)];
    tipView.backgroundColor = UIColorFromRGB(0x3c3b43);
    [self.view addSubview:tipView];
    
    UIImageView *tipIV = [[UIImageView alloc] initWithFrame:CGRectMake(10, (30 - 17)/2.0, 17, 17)];
    tipIV.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/草稿_帮助_@3x" Type:@"png"]];
    [tipView addSubview:tipIV];
    
    UILabel *tipLbl = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, kWIDTH - 30, 30)];
    tipLbl.text = RDLocalizedString(@"请不要删除草稿箱中使用的视频和图片，否则草稿箱的视频将无法使用", nil);
    tipLbl.font = [UIFont systemFontOfSize:13.0];
    tipLbl.textColor = UIColorFromRGB(0x888888);
    tipLbl.adjustsFontSizeToFitWidth = YES;
    [tipView addSubview:tipLbl];
    
    selectedDraftArray = [NSMutableArray array];
    draftList = [[RDDraftManager sharedManager] getALLDraftVideosInfo];
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
    
    selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [selectBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [selectBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [selectBtn setTitle:RDLocalizedString(@"选择", nil) forState:UIControlStateNormal];
    [selectBtn setTitle:RDLocalizedString(@"取消", nil) forState:UIControlStateSelected];
    [selectBtn addTarget:self action:@selector(selectBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *spaceItem_right = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem_right.width = -7;
    
    UIBarButtonItem *rightButton= [[UIBarButtonItem alloc] initWithCustomView:selectBtn];
    selectBtn.exclusiveTouch=YES;
    rightButton.tag = 2;
    self.navigationItem.rightBarButtonItems = @[spaceItem_right,rightButton];
}

- (void)initDraftCollectionView {
    
    UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    flow.itemSize = CGSizeMake(kWIDTH, 120);
    flow.minimumLineSpacing = 0;
    flow.minimumInteritemSpacing = 0;
    
    if (iPhone_X) {
        draftCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 30, kWIDTH, kHEIGHT - 44 - 87 - 34 - 30) collectionViewLayout: flow];
    }else {
        draftCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 30, kWIDTH, kHEIGHT - 20 - 44 - 30) collectionViewLayout: flow];
    }
    draftCollectionView.backgroundColor = [UIColor clearColor];
    draftCollectionView.dataSource = self;
    draftCollectionView.delegate = self;
    [draftCollectionView registerClass:[RDDraftCollectionViewCell class] forCellWithReuseIdentifier:@"draftCell"];
    [self.view addSubview:draftCollectionView];
}

- (void)initBottomView {
    bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - (iPhone_X ? (88 + 24 + 44) :  ((iPhone4s ? 0 : 44) + 53 + 20)), kWIDTH, 53 + (iPhone_X ? 34 : 0))];
    bottomView.backgroundColor = UIColorFromRGB(0x27262c);
    bottomView.hidden = YES;
    [self.view addSubview:bottomView];
    
    selectAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    selectAllBtn.frame = CGRectMake(0, 0, kWIDTH/2.0 - 0.5, 53);
    [selectAllBtn setTitle:RDLocalizedString(@"全选", nil) forState:UIControlStateNormal];
    [selectAllBtn setTitle:RDLocalizedString(@"取消全选", nil) forState:UIControlStateSelected];
    [selectAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [selectAllBtn addTarget:self action:@selector(selectAllBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:selectAllBtn];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(kWIDTH/2.0 - 0.5, 5, 1, 53 - 10)];
    line.backgroundColor = UIColorFromRGB(0x888888);
    [bottomView addSubview:line];
    
    deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteBtn.frame = CGRectMake(kWIDTH/2.0 + 0.5 , 0, kWIDTH/2.0 - 0.5, 53);
    [deleteBtn setTitle:RDLocalizedString(@"删除", nil) forState:UIControlStateNormal];
    [deleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [deleteBtn addTarget:self action:@selector(deleteBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:deleteBtn];
}

#pragma mark - 按钮事件
- (void)back:(UIButton *)sender{
    if(_exportProgressView){
        __weak typeof(self) weakSelf = self;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"确定",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf cancelExportBlock];
            UIViewController *upView = [weakSelf.navigationController popViewControllerAnimated:YES];
            if(!upView){
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }
            if(_cancelActionBlock){
                _cancelActionBlock();
            }
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"取消",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
        if(!upView){
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        if(_cancelActionBlock){
            _cancelActionBlock();
        }
    }
}

- (void)selectBtnAction:(UIButton *)sender{
     if(_exportProgressView){
         return;
     }
    sender.selected = !sender.selected;
    bottomView.hidden = !bottomView.hidden;
    if (bottomView.hidden) {
        if (iPhone_X) {
            draftCollectionView.frame = CGRectMake(0, 30, kWIDTH, kHEIGHT - 44 - 87 - 34 - 30);
        }else {
            draftCollectionView.frame = CGRectMake(0, 30, kWIDTH, kHEIGHT - 20 - 44 - 30);
        }
    }else {
        if (iPhone_X) {
            draftCollectionView.frame = CGRectMake(0, 30, kWIDTH, kHEIGHT - 44 - 87 - 34 - 30 - bottomView.frame.size.height);
        }else {
            draftCollectionView.frame = CGRectMake(0, 30, kWIDTH, kHEIGHT - 20 - 44 - 30 - bottomView.frame.size.height);
        }
    }
    deleteBtn.enabled = NO;
    [draftCollectionView reloadData];
}

- (void)selectAllBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        selectedDraftArray = [draftList mutableCopy];
        deleteBtn.enabled = YES;
    }else {
        [selectedDraftArray removeAllObjects];
        deleteBtn.enabled = NO;
    }
    [draftCollectionView reloadData];
}

- (void)deleteBtnAction:(UIButton *)sender {
    NSString *message;
    if (selectAllBtn.selected) {
        message = RDLocalizedString(@"确定删除所有的草稿？", nil);
    }else {
        message = [NSString stringWithFormat:RDLocalizedString(@"确定删除所选的%d个草稿？", nil), selectedDraftArray.count];
    }
    [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示", nil)
                               message:message
                     cancelButtonTitle:RDLocalizedString(@"取消", nil)
                     otherButtonTitles:RDLocalizedString(@"确定", nil)
                          alertViewTag:1];
}

#pragma mark - RDDraftCollectionViewCellDelegate
- (void)editDraft:(RDDraftCollectionViewCell *)cell {
    if (![[RDDraftManager sharedManager] isEnableDraft:cell.draft]) {
        [selectedDraftArray addObject:cell.draft];
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"相册中的源视频被删除了", nil)
                                   message:RDLocalizedString(@"是否删除该草稿？", nil)
                         cancelButtonTitle:RDLocalizedString(@"取消", nil)
                         otherButtonTitles:RDLocalizedString(@"确定", nil)
                              alertViewTag:1];
    }else {
        RDNextEditVideoViewController *editVC = [[RDNextEditVideoViewController alloc] init];
        editVC.exportVideoSize = cell.draft.exportSize;
        [editVC setFileList:cell.draft.fileList];
        editVC.draft = cell.draft;
        editVC.saveDraftCompletionBlock = ^{
            [draftCollectionView reloadData];
        };
        
        RDNavigationViewController *nav = [[RDNavigationViewController alloc] initWithRootViewController:editVC];
        [RDHelpClass setPresentNavConfig:nav currentNav:((RDNavigationViewController *)self.navigationController)];
        if (cell.draft.movieEffects.count > 0) {
            nav.editConfiguration.enableMV = YES;
        }else {
            nav.editConfiguration.enableMV = ((RDNavigationViewController *)self.navigationController).editConfiguration.enableMV;
        }
        nav.callbackBlock = ^(NSString * videoPath){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:RDLocalizedString(@"是否删除该草稿", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"是", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[RDDraftManager sharedManager] deleteDraft:[@[cell.draft] mutableCopy] completion:nil];
                    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                        ((RDNavigationViewController *)self.navigationController).callbackBlock(videoPath);
                    }
                }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"否", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                        ((RDNavigationViewController *)self.navigationController).callbackBlock(videoPath);
                    }
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        };
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)publishDraft:(RDDraftCollectionViewCell *)cell {
    if (![[RDDraftManager sharedManager] isEnableDraft:cell.draft]) {
        [selectedDraftArray addObject:cell.draft];
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"相册中的源视频被删除了", nil)
                                   message:RDLocalizedString(@"是否删除该草稿？", nil)
                         cancelButtonTitle:RDLocalizedString(@"取消", nil)
                         otherButtonTitles:RDLocalizedString(@"确定", nil)
                              alertViewTag:1];
    }else {
        publishDraft = cell.draft;
        RDFile *file = [cell.draft.fileList firstObject];
        RDDraftEffectTime *timeEffect = [publishDraft.timeEffectArray firstObject];
        if (((RDNavigationViewController *)self.navigationController).exportConfiguration.waterDisabled
            && ((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicDisabled
            && cell.draft.fileList.count == 1
            && file.fileType == kFILEVIDEO
            && ![RDHelpClass isSystemPhotoUrl:file.contentURL]
            && file.speed == 1.0
            && !file.isReverse
            && (CGRectEqualToRect(file.crop, CGRectZero) || CGRectEqualToRect(file.crop, CGRectMake(0, 0, 1, 1)))
            && (file.rotate == 0 || file.rotate == -0)
            && !file.isVerticalMirror
            && !file.isHorizontalMirror
            && CMTimeRangeEqual(file.videoTimeRange, file.videoTrimTimeRange)
            && publishDraft.musics.count == 0
            && publishDraft.originalOn
            && publishDraft.mvIndex == 0
            && publishDraft.filterIndex == 0
            && publishDraft.soundEffectIndex == 0
            && publishDraft.dubbings.count == 0
            && publishDraft.captions.count == 0
            && publishDraft.stickers.count == 0
            && publishDraft.mosaics.count == 0
            && publishDraft.blurs.count == 0
            && publishDraft.dewatermarks.count == 0
            && publishDraft.filterArray.count == 0
            && (publishDraft.timeEffectArray.count == 0 || (publishDraft.timeEffectArray.count == 1 && timeEffect.timeType == kTimeFilterTyp_None))
            && file.fileTimeFilterType == kTimeFilterTyp_None
            && file.customFilterIndex == 0
            && file.brightness == 0.0
            && file.contrast == 1.0
            && file.saturation == 1.0
            && file.vignette == 0.0
            && file.sharpness == 0.0
            && file.whiteBalance == 0.0
            && file.filterIndex == kRDFilterType_YuanShi)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:RDLocalizedString(@"是否删除该草稿", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"是", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[RDDraftManager sharedManager] deleteDraft:[@[cell.draft] mutableCopy] completion:nil];
                if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                    ((RDNavigationViewController *)self.navigationController).callbackBlock(file.contentURL.path);
                }
                [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"否", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if(((RDNavigationViewController *)self.navigationController).callbackBlock){
                    ((RDNavigationViewController *)self.navigationController).callbackBlock(file.contentURL.path);
                }
                [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }else {
            [self exportMovie];
        }
    }
}

- (void)selectDraft:(RDDraftCollectionViewCell *)cell {
    if (cell.selectBtn.selected) {
        [selectedDraftArray addObject:cell.draft];
    }else {
        [selectedDraftArray removeObject:cell.draft];
    }
    if (selectedDraftArray.count == 0) {
        deleteBtn.enabled = NO;
    }else {
        deleteBtn.enabled = YES;
    }
}

- (void)exportMovie{
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration > 0
       && publishDraft.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.inputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导入时长限制%@秒",nil),maxTime];
        [self.hud setCaption:message];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    if(!isContinueExport && ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration > 0
       && publishDraft.duration > ((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration){
        
        NSString *maxTime = [RDHelpClass timeToStringNoSecFormat:((float )((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration)];
        NSString *message = [NSString stringWithFormat:@"%@。%@",[NSString stringWithFormat:RDLocalizedString(@"当前时长超过了导出时长限制%@秒",nil),maxTime],RDLocalizedString(@"您可以关闭本提示去调整，或继续导出。",nil)];
        [self initCommonAlertViewWithTitle:RDLocalizedString(@"温馨提示",nil)
                                   message:message
                         cancelButtonTitle:RDLocalizedString(@"关闭",nil)
                         otherButtonTitles:RDLocalizedString(@"继续",nil)
                              alertViewTag:6];
        return;
    }
    _videoCoreSDK = [[RDVECore alloc] initWithAPPKey:((RDNavigationViewController *)self.navigationController).appKey
                                           APPSecret:((RDNavigationViewController *)self.navigationController).appSecret
                                          LicenceKey:((RDNavigationViewController *)self.navigationController).licenceKey
                                           videoSize:publishDraft.exportSize
                                                 fps:kEXPORTFPS
                                          resultFail:^(NSError *error) {
                                              NSLog(@"initSDKError:%@", error.localizedDescription);
                                          }];
#if isUseCustomLayer
    _videoCoreSDK.delegate = self;
#endif
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    [self.view addSubview:self.exportProgressView];
    self.exportProgressView.hidden = NO;
    [self.exportProgressView setProgress:0 animated:NO];
    
    NSMutableArray *globalFilters = [NSMutableArray array];
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
        NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                    appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                                   urlPath:((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL];
        if ([filterList[@"code"] intValue] == 0) {
            NSMutableArray *filtersName = [filterList[@"data"] mutableCopy];
            NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
            if(((RDNavigationViewController *)self.navigationController).appKey.length>0)
            [itemDic setObject:((RDNavigationViewController *)self.navigationController).appKey forKey:@"appkey"];
            [itemDic setObject:@"" forKey:@"cover"];
            [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
            [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
            [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
            [filtersName insertObject:itemDic atIndex:0];
            
            NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
            [filtersName enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
                [globalFilters addObject:filter];
            }];
        }
    }else{
        NSMutableArray *filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        [filtersName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            RDFilter* filter = [RDFilter new];
            if ([obj isEqualToString:@"原始"]) {
                filter.type = kRDFilterType_YuanShi;
            }
            else{
                filter.type = kRDFilterType_LookUp;
                filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"lookupFilter/%@",obj] Type:@"png"];
            }
            
            filter.name = obj;
            [globalFilters addObject:filter];
        }];
    }        
    NSMutableArray *scenes = [NSMutableArray new];
    for (int i = 0; i< publishDraft.fileList.count; i++) {
        RDFile *file = publishDraft.fileList[i];
        
        RDScene *scene = [[RDScene alloc] init];
        VVAsset* vvasset = [[VVAsset alloc] init];
        vvasset.url = file.contentURL;
        if (globalFilters.count > 0) {
            RDFilter* filter = globalFilters[file.filterIndex];
            if (filter.type == kRDFilterType_LookUp) {
                vvasset.filterType = VVAssetFilterLookup;
            }else if (filter.type == kRDFilterType_ACV) {
                vvasset.filterType = VVAssetFilterACV;
            }else {
                vvasset.filterType = VVAssetFilterEmpty;
            }
            if (filter.filterPath.length > 0) {
                vvasset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
            }
        }
        vvasset.audioFilterType = (RDAudioFilterType)publishDraft.soundEffectIndex;
        if(file.fileType == kFILEVIDEO){
            vvasset.type = RDAssetTypeVideo;
            vvasset.videoActualTimeRange = file.videoActualTimeRange;
            
            if(file.isReverse){
                vvasset.url = file.reverseVideoURL;
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
                }else{
                    vvasset.timeRange = file.reverseVideoTimeRange;
                }
                if(CMTimeCompare(vvasset.timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                    vvasset.timeRange = file.reverseVideoTrimTimeRange;
                }
                NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
            }
            else{
                if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
                }else{
                    vvasset.timeRange = file.videoTimeRange;
                }
                if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                    vvasset.timeRange = file.videoTrimTimeRange;
                }
                NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(vvasset.timeRange.start),CMTimeGetSeconds(vvasset.timeRange.duration));
            }
            vvasset.speed        = file.speed;
            vvasset.volume = file.videoVolume;
        }else{
            vvasset.type         = RDAssetTypeImage;
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, file.imageDurationTime);
            vvasset.speed        = file.speed;
            vvasset.volume       = file.videoVolume;
#if isUseCustomLayer
            if (file.fileType == kTEXTTITLE) {
                vvasset.fillType = RDImageFillTypeFull;
            }
#endif
        }
        CGSize size;
        if (file.fileType == kFILEVIDEO) {
            size = [RDHelpClass getVideoSizeForTrack:[AVURLAsset assetWithURL:file.contentURL]];
        }else {
            UIImage *image = file.thumbImage ? file.thumbImage : [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
            size = image.size;
        }
        CGSize trsize = size;
        if(file.rotate == -270 || file.rotate == -90){
            trsize.width = size.height;
            trsize.height = size.width;
        }
        float exportRatio = publishDraft.exportSize.width/publishDraft.exportSize.height;
        float assetRatio = (trsize.width * file.crop.size.width)/(trsize.height * file.crop.size.height);
        if(assetRatio < exportRatio && publishDraft.isVague)// && trsize.width * file.crop.size.width < publishDraft.exportSize.width)
        {
            vvasset.blurIntensity = 1.0;
        }else{
            vvasset.isBlurredBorder = NO;
        }
        if(i != publishDraft.fileList.count - 1 ){
            [RDHelpClass setTransition:scene.transition file:file];
        }        
        vvasset.rotate = file.rotate;
        vvasset.isVerticalMirror = file.isVerticalMirror;
        vvasset.isHorizontalMirror = file.isHorizontalMirror;
        vvasset.crop = file.crop;
        vvasset.alpha = 1.0;
        
        //调色
        vvasset.brightness = file.brightness;
        vvasset.contrast = file.contrast;
        vvasset.saturation = file.saturation;
        vvasset.sharpness = file.sharpness;
        vvasset.whiteBalance = file.whiteBalance;
        vvasset.vignette = file.vignette;
        
        [scene.vvAsset addObject:vvasset];
        
        RDCustomFilter * customFilteShear = nil;
        if( file.customFilterIndex != 0 ) {
            NSMutableArray *filterFxArray = [NSMutableArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
            customFilteShear = [RDGenSpecialEffect getCustomFilerWithFxId:file.customFilterId filterFxArray:filterFxArray timeRange:vvasset.timeRange];
        }
        
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger        idx2, BOOL * _Nonnull stop2) {
            asset.customFilter = customFilteShear;
        }];
        if( ( publishDraft.timeEffectArray != nil ) && (publishDraft.timeEffectArray.count == 0) )
        {
            if( (  ((RDDraftEffectTime*)publishDraft.timeEffectArray[0]).timeType == kTimeFilterTyp_None ) && ( file.fileTimeFilterType !=  kTimeFilterTyp_None ) )
            {
                [RDGenSpecialEffect refreshVideoTimeEffectType:scenes atFile:file atscene:scene atTimeRange:file.fileTimeFilterTimeRange atIsRemove:NO];
            }
            else
                [scenes addObject:scene];
        }
        else
            [scenes addObject:scene];
    }
    if (!publishDraft.isVague && !publishDraft.oldisNoBackground) {
        UIColor *videoBackgroundColor = [UIColor colorWithRed:publishDraft.videoBackgroundColorR green:publishDraft.videoBackgroundColorG blue:publishDraft.videoBackgroundColorB alpha:publishDraft.videoBackgroundColorA];
        if (videoBackgroundColor) {
            [_videoCoreSDK setBackGroundColorWithRed:publishDraft.videoBackgroundColorR
                                               Green:publishDraft.videoBackgroundColorG
                                                Blue:publishDraft.videoBackgroundColorB
                                               Alpha:publishDraft.videoBackgroundColorA];
        }
    }
    
    //特效
    //时间特效
    if( (publishDraft.fileList.count == 1) && (publishDraft.timeEffectArray.count > 0) )
    {
        [publishDraft.timeEffectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDDraftEffectTime* DraftEffectFilterItem = (RDDraftEffectTime*)obj;
            if( kTimeFilterTyp_None != DraftEffectFilterItem.timeType )
            {
                [RDGenSpecialEffect refreshVideoTimeEffectType:DraftEffectFilterItem.timeType timeEffectTimeRange:DraftEffectFilterItem.effectiveTimeRange atscenes:scenes atFile:publishDraft.fileList[0]];
            }
        }];
    }
    
    //动感特效
    NSMutableArray<RDCustomFilter*>* customFilterArray = [[NSMutableArray alloc] init];
    if(publishDraft.filterArray.count > 0)
    {
        NSArray *filterFxArray = [NSArray arrayWithContentsOfFile:kNewSpecialEffectPlistPath];
        [publishDraft.filterArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDDraftEffectFilterItem* draftEffectFilterItem = (RDDraftEffectFilterItem*)obj;
            
            RDCustomFilter*  customFilter = [RDGenSpecialEffect getCustomFilerWithFxId:draftEffectFilterItem.customFilterId filterFxArray:filterFxArray timeRange:draftEffectFilterItem.effectiveTimeRange];
            RDRangeViewFile*  RangeViewFilter = [[RDRangeViewFile alloc] init];
            //滚动条的设置
            RangeViewFilter.effectType = kFilterEffect;
            RangeViewFilter.typeIndex = draftEffectFilterItem.filterIndex;
            RangeViewFilter.start = CMTimeGetSeconds(draftEffectFilterItem.effectiveTimeRange.start);
            RangeViewFilter.duration = CMTimeGetSeconds(draftEffectFilterItem.effectiveTimeRange.duration);
            
            [customFilterArray addObject:customFilter];               //未保存的滤镜特效
        }];
    }
    [_videoCoreSDK setScenes:scenes];
    if( customFilterArray.count > 0 ) {
        _videoCoreSDK.customFilterArray = customFilterArray;
    }
    NSMutableArray *musicArray = [NSMutableArray array];
    [publishDraft.musics enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [musicArray addObject:[obj getMusic]];
    }];
    if (musicArray.count > 0) {
        [_videoCoreSDK setMusics:musicArray];
    }
    NSMutableArray *dubbingArr = [NSMutableArray array];
    [publishDraft.dubbings enumerateObjectsUsingBlock:^(DubbingRangeViewFile*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *musicPath = [RDHelpClass getFileURLFromAbsolutePath:obj.musicPath].path;
        
        CMTime start = CMTimeMakeWithSeconds(CMTimeGetSeconds(obj.dubbingStartTime) + obj.piantouDuration,TIMESCALE);
        RDMusic *music = [RDMusic new];
        music.url = [NSURL fileURLWithPath:musicPath];
        music.clipTimeRange = CMTimeRangeMake(kCMTimeZero, obj.dubbingDuration);
        music.effectiveTimeRange = CMTimeRangeMake(start, obj.dubbingDuration);
        music.volume = obj.volume;
        music.isRepeat = NO;
        [dubbingArr addObject:music];
    }];
    if (dubbingArr.count > 0) {
        [_videoCoreSDK setDubbingMusics:dubbingArr];
    }
    NSMutableArray *subtitles = [NSMutableArray array];
    [publishDraft.captions enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.fontPath = [[RDHelpClass getFileURLFromAbsolutePath:obj.fontPath] path];
        if (obj.fontPath.length > 0) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:obj.fontPath]) {
                [RDHelpClass customFontArrayWithPath:obj.fontPath];
            }else {
                obj.fontPath = nil;
                obj.fontName = [UIFont systemFontOfSize:10].fontName;
                obj.caption.tFontName = obj.fontName;
            }
        }
        [subtitles addObject:obj.caption];
    }];
    [publishDraft.stickers enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [subtitles addObject:obj.caption];
    }];
    if (subtitles.count > 0) {
        _videoCoreSDK.captions = subtitles;
    }
    NSMutableArray *blurs = [NSMutableArray array];
    [publishDraft.blurs enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [blurs addObject:obj.blur];
    }];
    if (blurs.count > 0) {
        _videoCoreSDK.blurs = blurs;
    }
    NSMutableArray *mosaics = [NSMutableArray array];
    [publishDraft.mosaics enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mosaics addObject:obj.mosaic];
    }];
    if (mosaics.count > 0) {
        _videoCoreSDK.mosaics = mosaics;
    }
    NSMutableArray *dewatermarks = [NSMutableArray array];
    [publishDraft.dewatermarks enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dewatermarks addObject:obj.dewatermark];
    }];
    if (dewatermarks.count > 0) {
        _videoCoreSDK.dewatermarks = dewatermarks;
    }
    NSMutableArray *watermarkArray = [NSMutableArray array];
    [publishDraft.collages enumerateObjectsUsingBlock:^(RDCaptionRangeViewFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [watermarkArray addObject:obj.collage];
    }];
    if (publishDraft.coverFile) {
        RDWatermark *coverWatermark = [[RDWatermark alloc] init];
        coverWatermark.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.3, TIMESCALE));
        coverWatermark.isRepeat = NO;
        coverWatermark.vvAsset.url = publishDraft.coverFile.contentURL;
        coverWatermark.vvAsset.type = RDAssetTypeImage;
        coverWatermark.vvAsset.fillType = RDImageFillTypeFit;
        coverWatermark.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(KPICDURATION, TIMESCALE));
        coverWatermark.vvAsset.crop = publishDraft.coverFile.crop;
        coverWatermark.vvAsset.rotate = publishDraft.coverFile.rotate;
        
        [watermarkArray addObject:coverWatermark];
    }
    if (watermarkArray.count > 0) {
        _videoCoreSDK.watermarkArray = watermarkArray;
    }
    NSMutableArray *selectMVEffects = [NSMutableArray array];
    [publishDraft.movieEffects enumerateObjectsUsingBlock:^(RDDraftMovieEffect*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [selectMVEffects addObject:[obj geMovieEffect]];
    }];
    if (selectMVEffects.count > 0) {
        [_videoCoreSDK addMVEffect:selectMVEffects];
    }
    [_videoCoreSDK addGlobalFilters:globalFilters];
    [_videoCoreSDK setGlobalFilter:publishDraft.filterIndex];
    [RDGenSpecialEffect addWatermarkToVideoCoreSDK:_videoCoreSDK totalDration:publishDraft.duration exportSize:publishDraft.exportSize exportConfig:((RDNavigationViewController *)self.navigationController).exportConfiguration];
    _videoCoreSDK.enableAudioEffect = YES;
    [_videoCoreSDK build];

    __weak typeof(self) myself = self;
    
    NSString *export = ((RDNavigationViewController *)self.navigationController).outPath;
    if(export.length==0){
        export = [NSTemporaryDirectory() stringByAppendingPathComponent:@"exportvideo.mp4"];
    }
    unlink([export UTF8String]);
    _idleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
#if 1
    AVMutableMetadataItem *titleMetadata = [[AVMutableMetadataItem alloc] init];
    titleMetadata.key = AVMetadataCommonKeyTitle;
    titleMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    titleMetadata.locale =[NSLocale currentLocale];
    titleMetadata.value = @"titile";
    
    AVMutableMetadataItem *locationMetadata = [[AVMutableMetadataItem alloc] init];
    locationMetadata.key = AVMetadataCommonKeyLocation;
    locationMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    locationMetadata.locale = [NSLocale currentLocale];
    locationMetadata.value = @"location";
    
    AVMutableMetadataItem *creationDateMetadata = [[AVMutableMetadataItem alloc] init];
    creationDateMetadata.key = AVMetadataCommonKeyCopyrights;
    creationDateMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    creationDateMetadata.locale = [NSLocale currentLocale];
    creationDateMetadata.value = @"copyrights";
    
    AVMutableMetadataItem *descriptionMetadata = [[AVMutableMetadataItem alloc] init];
    descriptionMetadata.key = AVMetadataCommonKeyDescription;
    descriptionMetadata.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    descriptionMetadata.locale = [NSLocale currentLocale];
    descriptionMetadata.value = @"descriptionMetadata";
#endif
    
    [_videoCoreSDK exportMovieURL:[NSURL fileURLWithPath:export]
                             size:publishDraft.exportSize
                          bitrate:((RDNavigationViewController *)self.navigationController).videoAverageBitRate
                              fps:kEXPORTFPS
                         metadata:nil
//                         metadata:@[titleMetadata, locationMetadata, creationDateMetadata, descriptionMetadata]
                     audioBitRate:0
              audioChannelNumbers:1
           maxExportVideoDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.outputVideoMaxDuration
                         progress:^(float progress) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 NSLog(@"progress:%f",progress);
                                 if(_exportProgressView)
                                     [_exportProgressView setProgress:progress*100.0 animated:NO];
                             });
                         } success:^{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 //UISaveVideoAtPathToSavedPhotosAlbum(export, self, nil, nil);
                                 [myself exportMovieSuc:export];
                                 [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
                             });
                         } fail:^(NSError *error) {
                             NSLog(@"失败:%@",error);
                             [myself exportMovieFail:error];
                             [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
                         }];
    
}

#if isUseCustomLayer
- (void)progressCurrentTime:(CMTime)currentTime customDrawLayer:(CALayer *)customDrawLayer {
    [RDHelpClass refreshCustomTextLayerWithCurrentTime:currentTime customDrawLayer:customDrawLayer fileLsit:publishDraft.fileList];
}
#endif

- (void)clearCore {
    [_videoCoreSDK stop];
    _videoCoreSDK.delegate = nil;
    [_videoCoreSDK.view removeFromSuperview];
    [_videoCoreSDK.customFilterArray removeAllObjects];
    _videoCoreSDK = nil;
}

- (void)exportMovieFail:(NSError *)error {
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    self.exportProgressView = nil;
    [self clearCore];
    
    if (error) {
        [self initCommonAlertViewWithTitle:error.localizedDescription
                                   message:@""
                         cancelButtonTitle:RDLocalizedString(@"确定",nil)
                         otherButtonTitles:nil
                              alertViewTag:0];
    }
}

- (void)exportMovieSuc:(NSString *)exportPath{
    isContinueExport = NO;
    if(self.exportProgressView.superview){
        [self.exportProgressView removeFromSuperview];
    }
    self.exportProgressView = nil;
    NSLog(@"成功");
    [self clearCore];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:RDLocalizedString(@"是否删除该草稿", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"是", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[RDDraftManager sharedManager] deleteDraft:[@[publishDraft] mutableCopy] completion:nil];
        if(((RDNavigationViewController *)self.navigationController).callbackBlock){
            ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
        }
        [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:RDLocalizedString(@"否", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if(((RDNavigationViewController *)self.navigationController).callbackBlock){
            ((RDNavigationViewController *)self.navigationController).callbackBlock(exportPath);
        }
        [self.navigationController.childViewControllers[0] dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

/**导出进度条
 */
- (RDExportProgressView *)exportProgressView{
    if(!_exportProgressView){
        _exportProgressView = [[RDExportProgressView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT - (iPhone_X ? 88 : 44))];
        _exportProgressView.canTouchUpCancel = YES;
        [_exportProgressView setProgressTitle:RDLocalizedString(@"视频导出中，请耐心等待...", nil)];
        [_exportProgressView setProgress:0 animated:NO];
        [_exportProgressView setTrackbackTintColor:UIColorFromRGB(0x545454)];
        [_exportProgressView setTrackprogressTintColor:UIColorFromRGB(0xffffff)];
        __weak typeof(self) weakself = self;
        _exportProgressView.cancelExportBlock = ^(){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself initCommonAlertViewWithTitle:RDLocalizedString(@"视频尚未导出完成，确定取消导出？",nil)
                                               message:@""
                                     cancelButtonTitle:RDLocalizedString(@"取消",nil)
                                     otherButtonTitles:RDLocalizedString(@"确定",nil)
                                          alertViewTag:5];
                
            });
            
        };
    }
    return _exportProgressView;
}

- (void)addWaterAndEndpicLogo{
    CGPoint waterposition = CGPointZero;
    
    switch (((RDNavigationViewController *)self.navigationController).exportConfiguration.waterPosition) {
        case WATERPOSITION_LEFTTOP:
            waterposition = CGPointMake(0, 0);
            break;
        case WATERPOSITION_LEFTBOTTOM:
            waterposition = CGPointMake(0, 1);
            break;
        case WATERPOSITION_RIGHTTOP:
            waterposition = CGPointMake(1, 0);
            break;
        case WATERPOSITION_RIGHTBOTTOM:
            waterposition = CGPointMake(1, 1);
            break;
        default:
            break;
    }
    //是否添加水印
    if(!((RDNavigationViewController *)self.navigationController).exportConfiguration.waterDisabled){
        if(((RDNavigationViewController *)self.navigationController).exportConfiguration.waterImage){
            [_videoCoreSDK addWaterMark:((RDNavigationViewController *)self.navigationController).exportConfiguration.waterImage withPoint:waterposition scale:1];
        }
        if(((RDNavigationViewController *)self.navigationController).exportConfiguration.waterText){
            [_videoCoreSDK addWaterMark:((RDNavigationViewController *)self.navigationController).exportConfiguration.waterText color:nil font:nil withPoint:waterposition];
        }
    }
    //是否添加片尾
    if(!((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicDisabled){
        
        [_videoCoreSDK addEndLogoMark:[UIImage imageWithContentsOfFile:((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicImagepath] userName:((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicUserName showDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicDuration fadeDuration:((RDNavigationViewController *)self.navigationController).exportConfiguration.endPicFadeDuration];
    }
}

- (void)cancelExportBlock{
    //将界面上的时间进度设置为零
    [_exportProgressView setProgress:0 animated:NO];
    [_exportProgressView removeFromSuperview];
    _exportProgressView = nil;
    [_videoCoreSDK cancelExportMovie:nil];
    [self clearCore];
    [[UIApplication sharedApplication] setIdleTimerDisabled: _idleTimerDisabled];
}

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
        case 1:
            if (buttonIndex == 1) {
                if (selectAllBtn.selected) {
                    [[RDDraftManager sharedManager] deleteDraft:nil completion:^{
                        selectBtn.hidden = YES;
                        [draftCollectionView reloadData];
                    }];
                }else {
                    [[RDDraftManager sharedManager] deleteDraft:selectedDraftArray completion:^{
                        if (draftList.count == 0) {
                            selectBtn.hidden = YES;
                        }
                        [draftCollectionView reloadData];
                    }];
                }
                [selectedDraftArray removeAllObjects];
                selectBtn.selected = NO;
                selectAllBtn.selected = NO;
                bottomView.hidden = YES;
                if (iPhone_X) {
                    draftCollectionView.frame = CGRectMake(0, 30, kWIDTH, kHEIGHT - 44 - 87 - 34 - 30);
                }else {
                    draftCollectionView.frame = CGRectMake(0, 30, kWIDTH, kHEIGHT - 20 - 44 - 30);
                }
            }
            break;
        case 5:
            if(buttonIndex == 1){
                isContinueExport = NO;
                [self cancelExportBlock];
            }
            break;
            
        case 6:
            if (buttonIndex == 1) {
                isContinueExport = YES;
                [self exportMovie];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return draftList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"draftCell";
    RDDraftCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.coverIV.image = nil;
    
    RDDraftInfo *draft = [draftList objectAtIndex:indexPath.row];
    cell.draft = draft;
#if 1   //20190816 提高封面清晰度
    if (draft.coverFile) {
        cell.coverIV.image = [RDHelpClass getFullScreenImageWithUrl:draft.coverFile.contentURL];
        if (cell.coverIV.image && !CGRectEqualToRect(draft.coverFile.crop, CGRectMake(0, 0, 1, 1))) {
            cell.coverIV.image = [RDHelpClass image:cell.coverIV.image rotation:draft.coverFile.rotate cropRect:draft.coverFile.crop];
        }
    }
    if (!cell.coverIV.image) {
        RDFile *file = [draft.fileList firstObject];
        if (file.isReverse) {
            cell.coverIV.image = [RDHelpClass getFullScreenImageWithUrl:file.reverseVideoURL];
        }else {
            cell.coverIV.image = [RDHelpClass getFullScreenImageWithUrl:file.contentURL];
        }
    }
#else
    if (draft.coverFile) {
        if (draft.coverFile.thumbImage) {
            cell.coverIV.image = draft.coverFile.thumbImage;
        }else {
            cell.coverIV.image = [RDHelpClass getThumbImageWithUrl:draft.coverFile.contentURL];
        }
        if (cell.coverIV.image && !CGRectEqualToRect(draft.coverFile.crop, CGRectMake(0, 0, 1, 1))) {
            cell.coverIV.image = [RDHelpClass image:cell.coverIV.image rotation:draft.coverFile.rotate cropRect:draft.coverFile.crop];
        }
    }
    if (!cell.coverIV.image) {
        RDFile *file = [draft.fileList firstObject];
        if (file.thumbImage) {
            cell.coverIV.image = file.thumbImage;
        }else {
            if (file.isReverse) {
                cell.coverIV.image = [RDHelpClass getThumbImageWithUrl:file.reverseVideoURL];
            }else {
                cell.coverIV.image = [RDHelpClass getThumbImageWithUrl:file.contentURL];
            }
        }
    }
#endif
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"yyyy-MM-dd HH:mm";
    cell.dateLbl.text = [format stringFromDate:draft.modifyTime];
    cell.durationLbl.text = [NSString stringWithFormat:RDLocalizedString(@"时长：%@", nil), [RDHelpClass timeFormat:draft.duration]];
    if (selectBtn.selected) {
        cell.selectBtn.hidden = NO;
        if (selectAllBtn.selected) {
            cell.selectBtn.selected = YES;
        }else {
            cell.selectBtn.selected = NO;
        }
    }else {
        cell.selectBtn.hidden = YES;
        cell.selectBtn.selected = NO;
    }
    
    return cell;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
