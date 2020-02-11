//
//  RDAddEffectsByTimeline+Collage.m
//  RDVEUISDK
//
//  Created by apple on 2019/5/10.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#define kOthersAlbum @"othersAlbum"

#import "RDAddEffectsByTimeline+Collage.h"
#import "LocalPhotoCell.h"
#import "RDOtherAlbumsViewController.h"
#import <Photos/Photos.h>
#import "RD_ImageManager.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation RDAddEffectsByTimeline (Collage)

- (void)initAlbumTitleToolbarWithFrame:(CGRect)frame {
    self.albumTitleView = [[UIView alloc] initWithFrame:frame];
    self.albumTitleView.hidden = YES;
    
    if(self.editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (self.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
            videoBtn.frame = CGRectMake(0, 0, self.albumTitleView.bounds.size.width, 44);
        }else {
            videoBtn.frame = CGRectMake(0, 0, self.albumTitleView.bounds.size.width/2.0, 44);
        }
        [videoBtn setTitle:RDLocalizedString(@"视频", nil) forState:UIControlStateNormal];
        [videoBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [videoBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        videoBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        videoBtn.tag = 1;
        [videoBtn addTarget:self action:@selector(videoBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.albumTitleView addSubview:videoBtn];
    }
    if(self.editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        UIButton *picBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (self.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
            picBtn.frame = CGRectMake(0, 0, self.albumTitleView.bounds.size.width, 44);
        }else {
            picBtn.frame = CGRectMake(self.albumTitleView.bounds.size.width/2.0, 0, self.albumTitleView.bounds.size.width/2.0, 44);
        }
        [picBtn setTitle:RDLocalizedString(@"图片", nil) forState:UIControlStateNormal];
        [picBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [picBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        picBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        picBtn.tag = 2;
        [picBtn addTarget:self action:@selector(picBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.albumTitleView addSubview:picBtn];
    }
}

- (void)initAlbumViewWithFrame:(CGRect)frame {
    self.albumView = [[UIView alloc] initWithFrame:frame];
    self.albumView.backgroundColor = TOOLBAR_COLOR;
    self.albumView.hidden = YES;
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake((kWIDTH - 37)/2.0, (18 - 4)/2.0, 37, 4)];
    lineView.backgroundColor = UIColorFromRGB(0xb2b2b2);
    lineView.layer.cornerRadius = 2.0;
    [self.albumView addSubview:lineView];
    
    UIButton *pullUpDownAlbumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    pullUpDownAlbumBtn.frame = CGRectMake((kWIDTH - kWIDTH/5.0)/2.0, 0, kWIDTH/5.0, 18);
    [pullUpDownAlbumBtn addTarget:self action:@selector(pullUpDownAlbumBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [pullUpDownAlbumBtn addTarget:self action:@selector(pullUpDownAlbumBtnAction:) forControlEvents:UIControlEventTouchDragExit];
    [self.albumView addSubview:pullUpDownAlbumBtn];
    
    self.albumScrollView = [[UIScrollView alloc] init];
    self.albumScrollView.frame = CGRectMake(0, 18, kWIDTH, self.albumView.bounds.size.height - 18);
    self.albumScrollView.showsHorizontalScrollIndicator = NO;
    self.albumScrollView.showsVerticalScrollIndicator = YES;
    self.albumScrollView.pagingEnabled = YES;
    self.albumScrollView.delegate = self;
    self.albumScrollView.bounces = NO;
    if(self.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO || self.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE){
        self.albumScrollView.contentSize = CGSizeMake(self.albumScrollView.frame.size.width, 0);
    }else{
        self.albumScrollView.contentSize = CGSizeMake(self.albumScrollView.frame.size.width*2, 0);
    }
    [self.albumView addSubview:self.albumScrollView];
    
    float width = (kWIDTH - 4)/5.0;
    if(self.editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        UICollectionViewFlowLayout * flow_video = [[UICollectionViewFlowLayout alloc] init];
        flow_video.scrollDirection = UICollectionViewScrollDirectionVertical;
        flow_video.itemSize = CGSizeMake(width,width);
        flow_video.minimumLineSpacing = 1.0;
        flow_video.minimumInteritemSpacing = 1.0;
        
        UICollectionView *videoCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, self.albumScrollView.bounds.size.height) collectionViewLayout:flow_video];
        videoCollectionView.backgroundColor = [UIColor clearColor];
        videoCollectionView.tag = 1;
        videoCollectionView.dataSource = self;
        videoCollectionView.delegate = self;
        [videoCollectionView registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"albumCell"];
        [self.albumScrollView addSubview:videoCollectionView];
    }
    if(self.editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        CGRect tableRect;
        if(self.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO
           || self.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE)
        {
            tableRect = CGRectMake(0, 0, self.albumScrollView.frame.size.width, self.albumScrollView.frame.size.height);
        }else{
            tableRect = CGRectMake(self.albumScrollView.frame.size.width, 0, self.albumScrollView.frame.size.width, self.albumScrollView.frame.size.height);
        }
        
        UICollectionViewFlowLayout * flow_pic = [[UICollectionViewFlowLayout alloc] init];
        flow_pic.scrollDirection = UICollectionViewScrollDirectionVertical;
        flow_pic.itemSize = CGSizeMake(width,width);
        flow_pic.minimumLineSpacing = 1.0;
        flow_pic.minimumInteritemSpacing = 1.0;
        
        UICollectionView *picCollectionView = [[UICollectionView alloc] initWithFrame: tableRect collectionViewLayout:flow_pic];
        picCollectionView.backgroundColor = [UIColor clearColor];
        picCollectionView.dataSource = self;
        picCollectionView.delegate = self;
        picCollectionView.tag = 2;
        [picCollectionView registerClass:[LocalPhotoCell class] forCellWithReuseIdentifier:@"albumCell"];
        [self.albumScrollView addSubview:picCollectionView];
    }
    
    if(self.editConfiguration.supportFileType != ONLYSUPPORT_IMAGE) {
        self.videoArray = [NSMutableArray arrayWithObject:kOthersAlbum];
    }
    if(self.editConfiguration.supportFileType != ONLYSUPPORT_VIDEO) {
        self.picArray = [NSMutableArray arrayWithObject:kOthersAlbum];
    }
    [self loadVideoAndPhoto];
}

#pragma mark - 加载相册
- (void)loadVideoAndPhoto {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
        {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                      message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                      delegate:self
                                      cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                      otherButtonTitles:RDLocalizedString(@"取消",nil), nil];
            alertView.tag = 102;
            [alertView show];
        }
            break;
        case PHAuthorizationStatusAuthorized:
            if(self.editConfiguration.supportFileType  != ONLYSUPPORT_IMAGE) {
                [self loadMyAppAssets];
            }
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
                        UICollectionView *videoCollectionView = [strongSelf.albumScrollView viewWithTag:1];
                        UICollectionView *photoCollectionView = [strongSelf.albumScrollView viewWithTag:2];
                        if(strongSelf.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
                            [photoCollectionView reloadData];
                        }else if(strongSelf.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
                            [videoCollectionView reloadData];
                        }else {
                            [videoCollectionView reloadData];
                            [photoCollectionView reloadData];
                        }
                    }else if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
                        UIAlertView *alertView = [[UIAlertView alloc]
                                                  initWithTitle:RDLocalizedString(@"无法访问相册!",nil)
                                                  message:RDLocalizedString(@"用户拒绝访问相册,请在<隐私>中开启",nil)
                                                  delegate:strongSelf
                                                  cancelButtonTitle:RDLocalizedString(@"确定",nil)
                                                  otherButtonTitles:RDLocalizedString(@"取消",nil), nil];
                        alertView.tag = 102;
                        [alertView show];
                    }
                });
            }];
        }
            break;
    }
}

/**加载APP内的所有视频
 */
- (void)loadMyAppAssets{
     
    RDNavigationViewController *nav = ((RDNavigationViewController *)((UIViewController*)self.delegate).navigationController);
    
    FolderType folderType = nav.folderType;
    
    if(folderType == kFolderNone){
        nav.appAlbumCacheName = @"";
        return;
    }
    NSString *albumName = nav.appAlbumCacheName;
    NSMutableArray *array =  [self getAllFileName:albumName];
    for (int i= (int)(array.count - 1) ; i>=0;i--) {
        NSString *file = array[i];
        NSString *extString = [file pathExtension];
        
        if(![[extString lowercaseString] isEqualToString:@"mov"] && ![[extString lowercaseString] isEqualToString:@"mp4"])   //取得后缀名这.png的文件名
        {
            [array removeObjectAtIndex:i];
        }
    }
    
    for (NSString *fileName in array) {
        NSString *path;
        if(folderType == kFolderLibrary){
            path = [RDHelpClass pathInCacheDirectory:[NSString stringWithFormat:@"%@/%@",albumName,fileName]];
        }else if(folderType == kFolderDocuments){
            
            path  = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/%@/%@/%@",@"Documents",albumName,fileName]];
            
        }else{
            
            path  = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@/%@",albumName,fileName]];
        }
        
        
        NSURL *url = [NSURL fileURLWithPath:path];
        path = nil;
        //NSLog(@"url:%@",url);
        
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAlasset = [AVURLAsset URLAssetWithURL:url options:opts];
        
        UIImage *image = [RDHelpClass assetGetThumImage:0 url:url urlAsset:nil];
        url = nil;
        opts = nil;
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        
        if(image){
            [dic setObject:image forKey:@"thumbImage"];
            [dic setObject:urlAlasset forKey:@"urlAsset"];
            [dic setObject:[NSValue valueWithCMTime:urlAlasset.duration] forKey:@"durationTime"];
            [self.videoArray addObject:dic];
        }
    }
    
    [array removeAllObjects];
    array = nil;
    //[_videoCollection reloadData];
}

/**在这里获取应用程序albumName文件夹里的文件及文件夹列表
 */
- (NSMutableArray *)getAllFileName:(NSString *)albumName{
    
    @autoreleasepool {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        RDNavigationViewController *nav = ((RDNavigationViewController *)((UIViewController*)self.delegate).navigationController);
        //
        NSString *documentDir;
        FolderType folderType = nav.folderType;
        if(folderType == kFolderLibrary){
            documentDir = [NSString stringWithFormat:@"%@",[RDHelpClass pathInCacheDirectory:albumName]];
            
        }else if(folderType == kFolderDocuments){
            
            documentDir  = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/%@/%@",@"Documents",albumName]];
            
        }else{
            
            documentDir  = [NSTemporaryDirectory() stringByAppendingString:albumName];
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:documentDir]){
            return nil;
        }
        
        NSError *error = nil;
        
        NSMutableArray *fileList;
        
        //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
        
        fileList = [[fileManager contentsOfDirectoryAtPath:documentDir error:&error] mutableCopy];
        
        //    以下这段代码则可以列出给定一个文件夹里的所有子文件夹名
        
        NSMutableArray *dirArray = [[NSMutableArray alloc] init];
        
        BOOL isDir = NO;
        
        //在上面那段程序中获得的fileList中列出文件夹名
        
        for (NSString *file in fileList) {
            
            NSString *path = [documentDir stringByAppendingPathComponent:file];
            
            isDir = [fileManager fileExistsAtPath:path isDirectory:(&isDir)];
            
            if (isDir) {
                
                NSString *filePath = [[NSString stringWithFormat:@"%@/",documentDir] stringByAppendingString:file];
                
                NSString *extString = [file pathExtension];
                
                if([[extString lowercaseString] isEqualToString:@"mov"] || [[extString lowercaseString] isEqualToString:@"mp4"])   //取得后缀名这.png的文件名
                {
                    [dirArray addObject:filePath];
                }
            }
            
            isDir = NO;
            
        }
        NSArray *myary = [fileList sortedArrayUsingComparator:^(NSString * obj1, NSString * obj2){
            obj1 = [obj1 lowercaseString];
            obj2 = [obj2 lowercaseString];
            return (NSComparisonResult)[obj1 compare:obj2 options:NSNumericSearch];
        }];
        [fileList removeAllObjects];
        fileList = nil;
        return [myary mutableCopy];
    }
}

- (void)loadDatasource{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
//    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];//modificationDate
    if(self.editConfiguration.supportFileType == ONLYSUPPORT_IMAGE) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if(self.editConfiguration.supportFileType == ONLYSUPPORT_VIDEO) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                             PHAssetMediaTypeVideo];
    }
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        if (![collection isKindOfClass:[PHAssetCollection class]]// 有可能是PHCollectionList类的的对象，过滤掉
            || collection.estimatedAssetCount <= 0)// 过滤空相册
        {
            continue;
        }
        if ([RDHelpClass isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            for (PHAsset *asset in fetchResult) {
                if (asset.mediaType == PHAssetMediaTypeVideo) {
                    [self.videoArray insertObject:asset atIndex:1];
                }else{
                    [self.picArray insertObject:asset atIndex:1];
                }
            }
            break;
        }
    }
}

//添加画中画完成
- (void)addCollageFinishAction:(UIButton *)sender {
    self.addBtn.hidden = NO;
    self.finishBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.deletedBtn.hidden = YES;

    [self.thumbnailCoreSDK pause];
    
    CaptionRangeView *view = self.trimmerView.currentCaptionView;
    RDWatermark *collage = view.file.collage;
    CGPoint point = CGPointMake(self.pasterView.center.x/self.syncContainer.frame.size.width, self.pasterView.center.y/self.syncContainer.frame.size.height);
    float scale = [self.pasterView getFramescale];
    CGRect rect;
    rect.size = CGSizeMake(self.pasterView.contentImage.frame.size.width*scale / self.syncContainer.bounds.size.width, self.pasterView.contentImage.frame.size.height*scale / self.syncContainer.bounds.size.height);
    rect.origin = CGPointMake(point.x - rect.size.width/2.0, point.y - rect.size.height/2.0);
    collage.vvAsset.rectInVideo = rect;

    CGFloat radius = atan2f(self.pasterView.transform.b, self.pasterView.transform.a);
    double rotate = - radius * (180 / M_PI);
    collage.vvAsset.rotate = rotate;

    if (CGAffineTransformEqualToTransform(self.pasterView.contentImage.transform, kLRFlipTransform)) {
        collage.vvAsset.isHorizontalMirror = YES;
        collage.vvAsset.isVerticalMirror = NO;
    }else if (CGAffineTransformEqualToTransform(self.pasterView.contentImage.transform, kUDFlipTransform)) {
        collage.vvAsset.isHorizontalMirror = NO;
        collage.vvAsset.isVerticalMirror = YES;
    }else if (CGAffineTransformEqualToTransform(self.pasterView.contentImage.transform, kLRUPFlipTransform)) {
        collage.vvAsset.isHorizontalMirror = YES;
        collage.vvAsset.isVerticalMirror = YES;
    }else {
        collage.vvAsset.isHorizontalMirror = NO;
        collage.vvAsset.isVerticalMirror = NO;
    }
    
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    for (CaptionRangeView *view in arr) {
        RDWatermark *collage = view.file.collage;
        if (collage) {
            collage.timeRange = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
            if(CMTimeGetSeconds(collage.timeRange.duration)==0){
                [view removeFromSuperview];
                continue;
            }
            if (collage.vvAsset.type == RDAssetTypeImage) {
                collage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, collage.timeRange.duration);
            }
            [newEffectArray addObject:collage];
            [newFileArray addObject:view.file];
        }
    }
    if (self.isEdittingEffect) {
        [self savePasterView:NO];
    }else {
        [self savePasterView:YES];
    }
//    self.trimmerView.rangeSlider.hidden = YES;
    
    self.albumView.hidden = YES;
    self.albumTitleView.hidden = YES;
    
    if( self.isBlankCaptionRangeView )
    {
        [self.pasterView removeFromSuperview];
        self.pasterView = nil;
        [self.syncContainer removeFromSuperview];
        self.syncContainer = nil;
    }
    else{
        self.syncContainer.hidden = NO;
        self.pasterView.hidden = NO;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]){
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:sender];
    }
    if( self.isAddingEffect )
    {
        if( self.isBlankCaptionRangeView )
            self.trimmerView.rangeSlider.hidden = YES;
    }
    else
    {
        if( self.isBlankCaptionRangeView )
            self.trimmerView.currentCaptionView = nil;
        else
            [self.trimmerView SetCurrentCaptionView:nil];
    }
    
    self.currentCollage = nil;
}

- (void)savePasterView:(BOOL)isScroll {
    CGFloat radius = atan2f(self.pasterView.transform.b, self.pasterView.transform.a);
    float rotate = - radius * (180 / M_PI);
    
    CGPoint point = CGPointMake(self.pasterView.center.x/self.playerView.frame.size.width, self.pasterView.center.y/self.playerView.frame.size.height);
    float scaleValue = kVIDEOWIDTH/self.playerView.bounds.size.width;
    CGRect saveRect = CGRectMake(0, 0, self.pasterView.contentImage.frame.size.width * scaleValue / kVIDEOWIDTH, self.pasterView.contentImage.frame.size.height * scaleValue / kVIDEOWIDTH);
    CGRect contentsCenter = self.pasterView.contentImage.layer.contentsCenter;
    float scale = [self.pasterView getFramescale];
    [self.trimmerView saveCollageCurrentRangeview:isScroll
                                      rotationAngle:rotate
                                          transform:self.pasterView.transform
                                        centerPoint:point
                                              frame:saveRect
                                     contentsCenter:contentsCenter
                                              scale:scale
                                              pSize:self.pasterView.frame.size
                                         thumbImage:self.pasterView.contentImage.image
                                   captionRangeView:nil];
    [self.pasterView removeFromSuperview];
    self.pasterView.delegate = nil;
    
}

- (void)editCollage {
    
    self.currentCollage = [self.trimmerView.currentCaptionView.file.collage mutableCopy];
    
    if ( [RDHelpClass isImageUrl:self.currentCollage.vvAsset.url] )
    {
        self.trimmerView.isCollage = NO;
    }
    else
        self.trimmerView.isCollage = YES;

    [self updateSyncLayerPositionAndTransform];
    CaptionRangeView *rangeView = self.trimmerView.currentCaptionView;
    if( !rangeView )
        rangeView = [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
#if 0
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    for (CaptionRangeView *view in arr) {
        if(view != rangeView){
            RDWatermark *collage = view.file.collage;
            if(collage){
                [newEffectArray addObject:collage];
                [newFileArray addObject:view.file];
            }
        }
    }
#endif
    [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
    [self.trimmerView.scrollView setContentOffset:CGPointMake(rangeView.frame.origin.x, 0) animated:NO];
#if 0
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:NO];
    }
#endif
    rangeView = self.trimmerView.currentCaptionView;
    
    [self rangeView_initPasterView:rangeView];
}

-(UIImage *)RangeView_Image:( CaptionRangeView * ) rangeView atCrop:(CGRect) rect
{
    UIImage *image = nil;
    if( rangeView.file.collage.vvAsset.type == RDAssetTypeVideo )
    {
        float time = (CMTimeGetSeconds(self.thumbnailCoreSDK.currentTime) - CMTimeGetSeconds(rangeView.file.collage.timeRange.start)) + CMTimeGetSeconds(rangeView.file.collage.vvAsset.timeRange.start);
        image= [RDHelpClass geScreenShotImageFromVideoURL:rangeView.file.collage.vvAsset.url atTime:CMTimeMakeWithSeconds(time, TIMESCALE) atSearchDirection:false];
    }
    else
    {
        image = [RDHelpClass getFullScreenImageWithUrl:rangeView.file.collage.vvAsset.url];
    }
    
    image = [RDHelpClass image:image rotation:0 cropRect:rangeView.file.collage.vvAsset.crop];
    
    return image;
}


-(void)rangeView_initPasterView:( CaptionRangeView * ) rangeView 
{
    [self initPasterViewWithFile:[self RangeView_Image:rangeView atCrop:rangeView.file.collage.vvAsset.crop]];
    self.pasterView.isDrag = true;
    
    float ppsc = (rangeView.file.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.file.caption.size.width <1 ? (rangeView.file.caption.size.width * kVIDEOWIDTH)/ (float) rangeView.file.caption.size.width : 1;
    float sc = rangeView.file.scale;
    CGFloat radius = atan2f(rangeView.file.captionTransform.b, rangeView.file.captionTransform.a);
    
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);
    self.pasterView.transform = CGAffineTransformScale(transform2, sc * ppsc, sc * ppsc);
    [self.pasterView setFramescale: sc * ppsc];
    self.pasterView.center = CGPointMake(rangeView.file.centerPoint.x *self.playerView.frame.size.width,rangeView.file.centerPoint.y *self.playerView.frame.size.height);
    
    //    self.pasterView.contentImage.alpha = rangeView.file.collage.vvAsset.alpha;
    self.pasterView.contentImage.alpha = 0.0;
    
    BOOL isHorizontalMirror = rangeView.file.collage.vvAsset.isHorizontalMirror;
    BOOL isVerticalMirror = rangeView.file.collage.vvAsset.isVerticalMirror;
    if (isHorizontalMirror && isVerticalMirror) {
        [self.pasterView setContentImageTransform:kLRUPFlipTransform];
    }else if (isHorizontalMirror) {
        [self.pasterView setContentImageTransform:kLRFlipTransform];
    }else if (isVerticalMirror) {
        [self.pasterView setContentImageTransform:kUDFlipTransform];
    }
}

- (void)startAddCollage:(CMTimeRange)timeRange
               collages:(NSMutableArray *)collages
{
    if(self.isAddingEffect)
        self.trimmerView.rangeSlider.hidden= YES;
    
    if (!self.pasterView && !self.albumView.hidden) {
        self.albumView.hidden = YES;
        self.albumTitleView.hidden = YES;        
        [self.trimmerView deletedcurrentCaption];
        [self.syncContainer removeFromSuperview];
        self.syncContainer = nil;
        return;
    }
    if (!self.albumView.hidden || self.isEdittingEffect) {
        self.albumView.hidden = YES;
        self.albumView.frame = self.superview.frame;
        CGRect frame = self.albumScrollView.frame;
        frame.size.height = self.albumView.bounds.size.height - 18;
        self.albumScrollView.frame = frame;
        
        UICollectionView *collectionView = [self.albumScrollView viewWithTag:1];
        frame = collectionView.frame;
        frame.size.height = self.albumScrollView.bounds.size.height;
        collectionView.frame = frame;
        
        collectionView = [self.albumScrollView viewWithTag:2];
        frame = collectionView.frame;
        frame.size.height = self.albumScrollView.bounds.size.height;
        collectionView.frame = frame;
        
        self.albumScrollView.contentOffset = CGPointMake(0, 0);
        
        self.albumTitleView.hidden = YES;
        self.addBtn.hidden = YES;
        self.deletedBtn.hidden = YES;
        self.finishBtn.hidden = NO;
        self.cancelBtn.hidden = NO;
        [self.pasterView removeFromSuperview];
        
        if (self.isEdittingEffect) {
            [self addCollageFinishAction:self.finishBtn];
        }else {
            CaptionRangeView *view = [[self.trimmerView getTimesFor_videoRangeView] lastObject];
            RDWatermark *collage = view.file.collage;
            if(collage){
                collage.timeRange = timeRange;
                if (collage.vvAsset.type == RDAssetTypeImage) {
                    collage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, collage.timeRange.duration);
                }
                
                CGPoint point = CGPointMake(self.pasterView.center.x/self.syncContainer.frame.size.width, self.pasterView.center.y/self.syncContainer.frame.size.height);
                float scale = [self.pasterView getFramescale];
                CGRect rect;
                rect.size = CGSizeMake(self.pasterView.contentImage.frame.size.width*scale / self.syncContainer.bounds.size.width, self.pasterView.contentImage.frame.size.height*scale / self.syncContainer.bounds.size.height);
                rect.origin = CGPointMake(point.x - rect.size.width/2.0, point.y - rect.size.height/2.0);
                collage.vvAsset.rectInVideo = rect;
                
                CGFloat radius = atan2f(self.pasterView.transform.b, self.pasterView.transform.a);
                double rotate = - radius * (180 / M_PI);
                collage.vvAsset.rotate = rotate;
                
                if (CGAffineTransformEqualToTransform(self.pasterView.contentImage.transform, kLRFlipTransform)) {
                    collage.vvAsset.isHorizontalMirror = YES;
                    collage.vvAsset.isVerticalMirror = NO;
                }else if (CGAffineTransformEqualToTransform(self.pasterView.contentImage.transform, kUDFlipTransform)) {
                    collage.vvAsset.isHorizontalMirror = NO;
                    collage.vvAsset.isVerticalMirror = YES;
                }else if (CGAffineTransformEqualToTransform(self.pasterView.contentImage.transform, kLRUPFlipTransform)) {
                    collage.vvAsset.isHorizontalMirror = YES;
                    collage.vvAsset.isVerticalMirror = YES;
                }else {
                    collage.vvAsset.isHorizontalMirror = NO;
                    collage.vvAsset.isVerticalMirror = NO;
                }
                [collages addObject:collage];
            }
        }
    }else {
        [self addCollageFinishAction:self.finishBtn];
    }
}

- (void)showAlbumView {
    self.albumTitleView.hidden = NO;
    self.albumView.hidden = NO;
    UIButton *videoBtn = [self.albumTitleView viewWithTag:1];
    [self videoBtnAction:videoBtn];
}

- (void)refreshAblumScrollViewViewFrame {
    CGRect frame = self.albumScrollView.frame;
    frame.size.height = self.albumView.bounds.size.height - 18;
    self.albumScrollView.frame = frame;
    
    UICollectionView *collectionView = [self.albumScrollView viewWithTag:1];
    frame = collectionView.frame;
    frame.size.height = self.albumScrollView.bounds.size.height;
    collectionView.frame = frame;
    
    collectionView = [self.albumScrollView viewWithTag:2];
    frame = collectionView.frame;
    frame.size.height = self.albumScrollView.bounds.size.height;
    collectionView.frame = frame;
    
    self.albumScrollView.contentOffset = CGPointMake(0, 0);
}

- (void)pullUpDownAlbumBtnAction:(UIButton *)sender {
    if (self.albumView.frame.origin.y == kNavigationBarHeight) {
        WeakSelf(self);
        [UIView animateWithDuration:0.3 animations:^{
            [weakSelf refreshAblumScrollViewViewFrame];
        }];
    }else {
        WeakSelf(self);
        [UIView animateWithDuration:0.3 animations:^{
            StrongSelf(self);
            strongSelf.albumView.frame = CGRectMake(0, kNavigationBarHeight, kWIDTH, kHEIGHT - kNavigationBarHeight - kToolbarHeight);
            [strongSelf refreshAblumScrollViewViewFrame];
        }];
    }
}
- (void)addCollage:(NSURL *)url thumbImage:(UIImage *)thumbImage {
    if (!thumbImage) {
        
        if( [RDHelpClass isImageUrl:url] )
            thumbImage = [RDHelpClass getFullScreenImageWithUrl:url];
        //2020 1 19 bug iphone6s 无法获取缩略图
        else
            thumbImage = [RDHelpClass geScreenShotImageFromVideoURL:url atTime:CMTimeMakeWithSeconds(0.1, TIMESCALE) atSearchDirection:FALSE];
    }
    [self initPasterViewWithFile:thumbImage];
    self.pasterView.isDrag = true;
    
    RDWatermark *collage = [[RDWatermark alloc] init];
    collage.vvAsset.url = url;
    collage.vvAsset.volume = 0.0;
    if ([RDHelpClass isImageUrl:url]) {
        collage.vvAsset.type = RDAssetTypeImage;
        collage.vvAsset.fillType = RDImageFillTypeFit;
        collage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(KPICDURATION, TIMESCALE));
    }else {
        CMTime duration = [AVURLAsset assetWithURL:url].duration;
        collage.vvAsset.type = RDAssetTypeVideo;
        collage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(CMTimeGetSeconds(duration), TIMESCALE));
    }
    
    float startTime = CMTimeGetSeconds(self.trimmerView.currentCaptionView.file.timeRange.start);
    if( self.trimmerView.currentCaptionView )
        [self.trimmerView deletedcurrentCaption];
    
    float RemainDuration = self.thumbnailCoreSDK.duration - startTime;
    
    if( RemainDuration > CMTimeGetSeconds(collage.vvAsset.timeRange.duration) )
    {
        RemainDuration = CMTimeGetSeconds(collage.vvAsset.timeRange.duration);
    }else{
        collage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(RemainDuration, TIMESCALE));
    }
    
    collage.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, TIMESCALE), CMTimeMakeWithSeconds(RemainDuration, TIMESCALE));
    
    [self.trimmerView addCapation:nil type:4 captionDuration:RemainDuration];
    
    [self.trimmerView changeCollageCurrentRangeviewFile:collage
                                                              thumbImage:thumbImage
                                                             captionView:nil];
    self.pasterView.contentImage.alpha = 1.0;
#if 0
    self.currentCollage = [collage mutableCopy];
    
    if( self.currentCollage )
    {
        CGRect rect = CGRectMake(0, 0, 1, 1);
        double rotate = 0;
        [self pasterView_Rect:&rect atRotate:&rotate];
        
        self.currentCollage.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.thumbnailCoreSDK.duration, TIMESCALE));
         if ([RDHelpClass isImageUrl:url]) {
             self.currentCollage.vvAsset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.thumbnailCoreSDK.duration, TIMESCALE));
         }
        
        
        self.currentCollage.vvAsset.rotate = rotate;
        self.currentCollage.vvAsset.rectInVideo = rect;
        
        [self.thumbnailCoreSDK filterRefresh:self.thumbnailCoreSDK.currentTime];
        
        if( self.delegate && [self.delegate respondsToSelector:@selector(collage_initPlay)] )
        {
            [self.delegate collage_initPlay];
        }
    }
#endif
}
- (void)videoBtnAction:(UIButton *)sender {
    sender.selected = YES;
    UIButton *picBtn = [self.albumTitleView viewWithTag:2];
    picBtn.selected = NO;
    WeakSelf(self);
    [UIView animateWithDuration:0.25 animations:^{
        StrongSelf(self);
        strongSelf.albumScrollView.contentOffset = CGPointMake(0, 0);
    }];
}
- (void)picBtnAction:(UIButton *)sender {
    sender.selected = YES;
    UIButton *videoBtn = [self.albumTitleView viewWithTag:1];
    videoBtn.selected = NO;
    WeakSelf(self);
    [UIView animateWithDuration:0.25 animations:^{
        StrongSelf(self);
        strongSelf.albumScrollView.contentOffset = CGPointMake(self.editConfiguration.supportFileType == SUPPORT_ALL ? strongSelf.albumScrollView.frame.size.width : 0, 0);
    }];
}


#pragma mark- UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if(collectionView.tag == 1){
        return self.videoArray.count;
    }
    else{
        return self.picArray.count;
    }
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
            if([self.videoArray[indexPath.row] isKindOfClass:[NSDictionary class]]){
                NSDictionary *dic = self.videoArray[indexPath.row];
                UIImage *thumbImage = [dic objectForKey:@"thumbImage"];
                cell.durationBlack.hidden = NO;
                cell.duration.hidden = NO;
                double duration = CMTimeGetSeconds([[dic objectForKey:@"durationTime"] CMTimeValue]);
                cell.duration.text = [RDHelpClass timeToStringFormat:duration];
                [cell.ivImageView setImage:thumbImage];
            }
            else if([self.videoArray[indexPath.row] isKindOfClass:[PHAsset class]]){
                PHAsset *asset=self.videoArray[indexPath.row];
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
        //图片集
        else{
            if(indexPath.row < self.picArray.count){
                PHAsset *asset = self.picArray[indexPath.row];
                cell.durationBlack.hidden = YES;
                cell.duration.hidden = YES;
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
                [[RD_ImageManager manager] getPhotoWithAsset:asset photoWidth:thumbWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if(!isDegraded){
                        cell.ivImageView.userInteractionEnabled = YES;
                        [cell.ivImageView setImage:photo];
                        cell.userInteractionEnabled = YES;
                    }
                }];
            }
            return cell;
        }
    }
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
            strongSelf.isAddingEffect = YES;
            [strongSelf addCollage:url thumbImage:thumbImage];
        };
        if (self.delegate && [self.delegate respondsToSelector:@selector(pushOtherAlbumsVC:)]) {
            [self.delegate pushOtherAlbumsVC:otherAlbumsVC];
        }
    }else{
        WeakSelf(self);
        if(collectionView.tag == 1){
            NSInteger index = [collectionView indexPathForCell:cell].row;
            if([self.videoArray[index] isKindOfClass:[NSMutableDictionary class]]){
                AVURLAsset *resultAsset = [self.videoArray[index] objectForKey:@"urlAsset"];
                
                cell.icloudIcon.hidden = YES;
                [cell.progressView setPercent:0];
                [self addCollage:resultAsset.URL thumbImage:cell.ivImageView.image];
            }else{
                PHAsset *resouceAsset = self.videoArray[index];
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
                            [strongSelf addCollage:asseturl thumbImage:nil];
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
        }else{
            NSInteger index = [collectionView indexPathForCell:cell].row;
            PHAsset *result = (PHAsset *)self.picArray[index];
            
            PHImageRequestOptions  *opt_s = [[PHImageRequestOptions alloc] init]; // assets的配置设置
            opt_s.version = PHVideoRequestOptionsVersionCurrent;
            opt_s.networkAccessAllowed = NO;
            opt_s.resizeMode = PHImageRequestOptionsResizeModeExact;
            [[PHImageManager defaultManager] requestImageDataForAsset:result options:opt_s resultHandler:^(NSData * _Nullable imageData_l, NSString * _Nullable dataUTI_l, UIImageOrientation orientation_l, NSDictionary * _Nullable info_l) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    StrongSelf(self);
                    if(imageData_l){
                        cell.isDownloadingInLocal = NO;
                        if([[info_l allKeys] containsObject:@"PHImageFileURLKey"] || [[info_l allKeys] containsObject:@"PHImageFileUTIKey"]){
                            NSURL *url = info_l[@"PHImageFileURLKey"];
                            if (!url) {
                                url = info_l[@"PHImageFileUTIKey"];
                            }
                            NSString *localID = result.localIdentifier;
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
                            [strongSelf addCollage:[NSURL URLWithString:uploadVideoFilePath] thumbImage:nil];
                        }
                        return;
                    }else{
                        [strongSelf.hud setCaption:RDLocalizedString(@"Photos are syncing from iCloud, please retry later", nil)];
                        [strongSelf.hud show];
                        [strongSelf.hud hideAfter:1];
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
                    [[PHImageManager defaultManager] requestImageDataForAsset:result options:opts resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
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

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    UIButton *videoBtn = [self.albumTitleView viewWithTag:1];
    UIButton *photoBtn = [self.albumTitleView viewWithTag:2];
    if (scrollView.contentOffset.x == 0) {
        videoBtn.selected = YES;
        photoBtn.selected = NO;
    }else {
        videoBtn.selected = NO;
        photoBtn.selected = YES;
    }
}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 102:
            if (buttonIndex == 1) {
                [RDHelpClass enterSystemSetting];
            }
            break;
        default:
            break;
    }
}


-(void)editCollage_Features
{
    if( !self.EditCollageView )
    {
        self.EditCollageView = [[editCollageView alloc] initWithFrame:CGRectMake(0, (kHEIGHT - kToolbarHeight) - 16, self.bounds.size.width, kToolbarHeight + 16)];
        self.EditCollageView.delegate = self;
        [self addSubview:self.EditCollageView];
    }
    else{
        self.EditCollageView.hidden =NO;
    }
    
    self.addBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.deletedBtn.hidden = YES;
    self.finishBtn.hidden = YES;

    if( self.EditCollageView.currentVvAsset )
    {
        self.EditCollageView.currentVvAsset = nil;
    }

    self.EditCollageView.currentVvAsset = [self.trimmerView.currentCaptionView.file.collage.vvAsset mutableCopy];

    
    if( self.EditCollageView.currentVvAsset.type == RDAssetTypeImage )
    {
        [self.EditCollageView.toolBarView viewWithTag:KPIP_TRIM].userInteractionEnabled = false;
    }
    else
        [self.EditCollageView.toolBarView viewWithTag:KPIP_TRIM].userInteractionEnabled = true;
    
    
    self.EditCollageView.currentCollage = self.currentCollage;
    self.EditCollageView.videoCoreSDK = self.thumbnailCoreSDK;
    
    
    
    [((UIViewController*)self.delegate).view addSubview:self.EditCollageView];
}

@end
