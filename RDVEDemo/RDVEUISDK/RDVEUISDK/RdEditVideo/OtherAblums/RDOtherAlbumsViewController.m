//
//  RDOtherAlbumsViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/3/15.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDOtherAlbumsViewController.h"
#import <Photos/Photos.h>
#import "RD_ImageManager.h"
#import "LocalPhotoCell.h"
#import "RDAlbumCollectionViewCell.h"
#import "RDATMHud.h"

#define kTitle @"albumTilte"
#define kAlbumArray @"albumArray"

@implementation RDOtherAlbumInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        _videoOrPicArray = [NSMutableArray array];
    }
    return self;
}

@end

@interface RDOtherAlbumsViewController ()<UIAlertViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
{
    RDATMHud                    * hud;
    UIAlertView                 * commonAlertView;
    NSMutableArray<RDOtherAlbumInfo *>* allAlbumArray;
    NSMutableArray              * videoArray;
    NSMutableArray              * picArray;
    UICollectionView            * allAlbumCollectionView;
    UICollectionView            * singleAlbumCollectionView;
    NSInteger                     selectedAlbumIndex;
}

@end

@implementation RDOtherAlbumsViewController

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

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    

    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self refreshNavigationBar];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    hud = [[RDATMHud alloc] initWithDelegate:self];
    [self.navigationController.view addSubview:hud.view];
    
    [self initAllAlbumCollectionView];
    [self loadVideoAndPhoto];
    [self initSingleAlbumCollectionView];
}

- (void)refreshNavigationBar {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    [self.navigationItem setHidesBackButton:YES];
    //设置导航栏背景图片
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:18];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:[UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)] cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setFrame:CGRectMake(0, 0, 44, 44)];
    backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [backBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
    [backBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消点击_"] forState:UIControlStateHighlighted];
    backBtn.exclusiveTouch = YES;
    [backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width = -9;
    self.navigationItem.leftBarButtonItems = @[spaceItem,leftButton];
    
    if (_supportFileType == ONLYSUPPORT_VIDEO) {
        self.title = RDLocalizedString(@"选择视频", nil);
    }else if (_supportFileType == ONLYSUPPORT_IMAGE) {
        self.title = RDLocalizedString(@"选择图片", nil);
    }
    else if( _supportFileType == SUPPORT_ALL )
        self.title = RDLocalizedString(@"选择视频/图片", nil);
}

- (void)initAllAlbumCollectionView {
    float width = (kWIDTH - 30)/2.0;
    
    UICollectionViewFlowLayout *flow_allAlbum = [[UICollectionViewFlowLayout alloc] init];
    flow_allAlbum.scrollDirection = UICollectionViewScrollDirectionVertical;
    flow_allAlbum.itemSize = CGSizeMake(width, width + 20);
    flow_allAlbum.minimumLineSpacing = 10.0;
    flow_allAlbum.minimumInteritemSpacing = 10.0;
    flow_allAlbum.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    allAlbumCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT - kNavigationBarHeight) collectionViewLayout:flow_allAlbum];
    allAlbumCollectionView.backgroundColor = [UIColor clearColor];
    allAlbumCollectionView.tag = 1;
    allAlbumCollectionView.dataSource = self;
    allAlbumCollectionView.delegate = self;
    [allAlbumCollectionView registerClass:[RDAlbumCollectionViewCell class] forCellWithReuseIdentifier:@"allAlbumCell"];
    if (iPhone_X) {
        allAlbumCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
    [self.view addSubview:allAlbumCollectionView];
}

- (void)initSingleAlbumCollectionView {
    float width = (kWIDTH - 50)/4.0;
    
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    flow.itemSize = CGSizeMake(width, width);
    flow.minimumLineSpacing = 10.0;
    flow.minimumInteritemSpacing = 10.0;
    flow.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    singleAlbumCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT - kNavigationBarHeight) collectionViewLayout:flow];
    singleAlbumCollectionView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    singleAlbumCollectionView.tag = 2;
    singleAlbumCollectionView.dataSource = self;
    singleAlbumCollectionView.delegate = self;
    [singleAlbumCollectionView registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"singleAlbumCell"];
    if (iPhone_X) {
        singleAlbumCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
    }
    singleAlbumCollectionView.hidden = YES;
    [self.view addSubview:singleAlbumCollectionView];
}

#pragma mark - 加载相册
- (void)loadVideoAndPhoto {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
            [self initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                       message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                             cancelButtonTitle:RDLocalizedString(@"确定",nil)
                             otherButtonTitles:RDLocalizedString(@"取消",nil)
                                  alertViewTag:1];
            break;
        case PHAuthorizationStatusAuthorized:
            [self loadDatasource];
            break;
            
        default:
        {
            WeakSelf(self);
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if (status == PHAuthorizationStatusAuthorized) {
                        [strongSelf loadDatasource];
                        [allAlbumCollectionView reloadData];
                    }else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                        [strongSelf initCommonAlertViewWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                                         message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                               cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                               otherButtonTitles:RDLocalizedString(@"取消",nil)
                                                    alertViewTag:1];
                    }
                });
            }];
        }
            break;
    }
}

- (void)loadDatasource{
    allAlbumArray = [NSMutableArray array];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
//    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];//modificationDate
    if(_supportFileType == ONLYSUPPORT_IMAGE) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if(_supportFileType == ONLYSUPPORT_VIDEO) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                             PHAssetMediaTypeVideo];
    }
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        if (![collection isKindOfClass:[PHAssetCollection class]]// 有可能是PHCollectionList类的的对象，过滤掉
            || collection.estimatedAssetCount <= 0
            || fetchResult.count < 1)// 过滤空相册
        {
            continue;
        }
        if (![RDHelpClass isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            RDOtherAlbumInfo *info = [[RDOtherAlbumInfo alloc] init];
            info.title = collection.localizedTitle;
            [allAlbumArray addObject:info];
            for (PHAsset *asset in fetchResult) {
                [info.videoOrPicArray insertObject:asset atIndex:0];
            }
        }
    }
}

#pragma mark - 按钮事件
- (void)backBtnAction:(UIButton *)sender {
    if (!singleAlbumCollectionView.hidden) {
        singleAlbumCollectionView.hidden = YES;
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - alertViewdalegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 1){
        if (buttonIndex == 0) {
            [RDHelpClass enterSystemSetting];
        }
    }
}

#pragma mark- UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (collectionView.tag == 1) {
        return allAlbumArray.count;
    }
    if (allAlbumArray.count == 0) {
        return 0;
    }else {
        return allAlbumArray[selectedAlbumIndex].videoOrPicArray.count;
    }
}

// the image view inside the collection view cell prototype is tagged with "1"
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    //缩率图的大小这个地方数值不能设置大了
    float thumbWidth = 80;//(kWIDTH/4.0 - 0.5*3) * [UIScreen mainScreen].scale;
    if (collectionView.tag == 1) {
        static NSString *CellIdentifier = @"allAlbumCell";
        RDAlbumCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        RDOtherAlbumInfo *info = allAlbumArray[indexPath.row];
        cell.nameLbl.text = info.title;
        cell.numberLbl.text = [NSString stringWithFormat:@"%lu", (unsigned long)info.videoOrPicArray.count];
        PHAsset *asset = [info.videoOrPicArray firstObject];
        [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
                cell.coverIV.userInteractionEnabled = YES;
                cell.coverIV.image = photo;
                cell.userInteractionEnabled = YES;
            }
        }];
        return cell;
    }
    static NSString *CellIdentifier = @"singleAlbumCell";
    LocalPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PHAsset *asset = allAlbumArray[selectedAlbumIndex].videoOrPicArray[indexPath.row];
    if (_supportFileType == ONLYSUPPORT_IMAGE) {
        cell.durationBlack.hidden = YES;
        cell.duration.hidden = YES;
    }
    else if( _supportFileType == SUPPORT_ALL )
    {
        if( !asset.duration )
        {
            cell.durationBlack.hidden = YES;
            cell.duration.hidden = YES;
        }
    }
    
    cell.addBtn.hidden = YES;
    double duration = asset.duration;
    cell.duration.text = [RDHelpClass timeToStringFormat:duration];
    if([[RD_ImageManager manager] isICloudnoDownLoad:asset]){
        cell.icloudIcon.hidden = NO;
    }else{
        cell.icloudIcon.hidden = YES;
    }
    if ([[asset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
        cell.gifLbl.hidden = NO;
    }else {
        cell.gifLbl.hidden = YES;
    }
    [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth  completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if(!isDegraded){//isDegraded为YES表示当前返回的是低清图
            cell.ivImageView.userInteractionEnabled = YES;
            [cell.ivImageView setImage:photo];
            cell.userInteractionEnabled = YES;
        }
    }];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 1) {
        if (selectedAlbumIndex != indexPath.row) {
            selectedAlbumIndex = indexPath.row;
            [singleAlbumCollectionView reloadData];
        }
        singleAlbumCollectionView.hidden = NO;
    }else {
        WeakSelf(self);
        PHAsset *asset = allAlbumArray[selectedAlbumIndex].videoOrPicArray[indexPath.row];
        LocalPhotoCell *cell = (LocalPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
        
        __block PHAsset * phAsset = asset;
        if (_supportFileType == ONLYSUPPORT_VIDEO) {
            PHVideoRequestOptions *opt_s = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
            opt_s.version = PHVideoRequestOptionsVersionOriginal;
            opt_s.networkAccessAllowed = NO;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:opt_s resultHandler:^(AVAsset * _Nullable asset_l, AVAudioMix * _Nullable audioMix_l, NSDictionary * _Nullable info_l) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    StrongSelf(self);
                    if(asset_l){
                        cell.isDownloadingInLocal = NO;
                        NSURL *fileUrl = [asset_l valueForKey:@"URL"];
                        NSString *localID = asset.localIdentifier;
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
                        if (strongSelf.finishBlock) {
                            strongSelf.finishBlock(asseturl, cell.ivImageView.image);
                            [strongSelf.navigationController popViewControllerAnimated:YES];
                        }
                        if (strongSelf.finishBlock_main) {
                            strongSelf.finishBlock_main(phAsset, nil,YES);
                            [strongSelf.navigationController popViewControllerAnimated:YES];
                        }
                        return;
                    }
                    if(cell.isDownloadingInLocal){
                        return;
                    }
                    cell.isDownloadingInLocal = YES;
                    [strongSelf->hud setCaption:RDLocalizedString(@"Videos are syncing from iCloud, please retry later", nil)];
                    [strongSelf->hud show];
                    [strongSelf->hud hideAfter:1];
                    
                    PHVideoRequestOptions *opts = [[PHVideoRequestOptions alloc] init]; // assets的配置设置
                    opts.version = PHVideoRequestOptionsVersionOriginal;
                    opts.networkAccessAllowed = YES;
                    opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                        [cell.progressView setPercent:progress];
                    };
                    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:opts resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            cell.isDownloadingInLocal = NO;
                            [cell.progressView setPercent:0];
                            cell.icloudIcon.hidden = YES;
                        });
                    }];
                });
            }];
        }else {
            PHImageRequestOptions  *opt_s = [[PHImageRequestOptions alloc] init]; // assets的配置设置
            opt_s.version = PHVideoRequestOptionsVersionCurrent;
            opt_s.networkAccessAllowed = NO;
            opt_s.resizeMode = PHImageRequestOptionsResizeModeExact;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:opt_s resultHandler:^(NSData * _Nullable imageData_l, NSString * _Nullable dataUTI_l, UIImageOrientation orientation_l, NSDictionary * _Nullable info_l) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if(imageData_l){
                        cell.isDownloadingInLocal = NO;
                        if([[info_l allKeys] containsObject:@"PHImageFileURLKey"] || [[info_l allKeys] containsObject:@"PHImageFileUTIKey"]){
                            NSURL *url = info_l[@"PHImageFileURLKey"];
                            if (!url) {
                                url = info_l[@"PHImageFileUTIKey"];
                            }
                            NSString *localID = asset.localIdentifier;
                            NSArray *temp = [localID componentsSeparatedByString:@"/"];
                            NSString *uploadVideoFilePath = nil;
                            if (temp.count > 0) {
                                NSString *assetID = temp[0];
                                NSString *ext = url.pathExtension;
                                if (assetID && ext) {
                                    uploadVideoFilePath = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", ext, assetID, ext];
                                }
                            }
                            cell.icloudIcon.hidden = YES;
                            if (strongSelf.finishBlock) {
                                strongSelf.finishBlock([NSURL URLWithString:uploadVideoFilePath], nil);
                                [strongSelf.navigationController popViewControllerAnimated:YES];
                            }
                            if (strongSelf.finishBlock_main) {
                                strongSelf.finishBlock_main(phAsset, nil,YES);
                                [strongSelf.navigationController popViewControllerAnimated:YES];
                            }
                        }
                        return;
                    }else{
                        [strongSelf->hud setCaption:RDLocalizedString(@"Photos are syncing from iCloud, please retry later", nil)];
                        [strongSelf->hud show];
                        [strongSelf->hud hideAfter:1];
                    }
                    if(cell.isDownloadingInLocal){
                        return;
                    }
                    cell.isDownloadingInLocal = YES;
                    
                    PHImageRequestOptions  *opts = [[PHImageRequestOptions alloc] init]; // assets的配置设置
                    opts.version = PHVideoRequestOptionsVersionCurrent;
                    opts.networkAccessAllowed = YES;
                    opts.resizeMode = PHImageRequestOptionsResizeModeExact;
                    opts.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                        cell.progressView.percent = progress;
                    };
                    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:opts resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                        if([[info allKeys] containsObject:@"PHImageFileURLKey"] || [[info_l allKeys] containsObject:@"PHImageFileUTIKey"]){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                cell.isDownloadingInLocal = NO;
                                cell.icloudIcon.hidden = YES;
                            });
                        }
                    }];
                });
            }];
        }
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

- (void)dealloc {
    NSLog(@"%s", __func__);
    [allAlbumCollectionView removeFromSuperview];
    [singleAlbumCollectionView removeFromSuperview];
    allAlbumCollectionView = nil;
    singleAlbumCollectionView = nil;
    [allAlbumArray removeAllObjects];
    [hud releaseHud];
}

@end
