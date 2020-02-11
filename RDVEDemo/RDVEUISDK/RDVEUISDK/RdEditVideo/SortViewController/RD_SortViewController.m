//
//  RD_SortViewController.m
//  RDVEUISDK
//
//  Created by emmet on 16/7/7.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "RD_SortViewController.h"
#import "RDHelpClass.h"
#import "RD_SelectionCollectionViewCell.h"
#import "RDMainViewController.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDHeaderView.h"
#import "RDFooterView.h"
#import "RDSVProgressHUD.h"

@interface RD_SortViewController ()<RDReorderableCollectionViewDataSource, RDReorderableCollectionViewDelegateFlowLayout>
{
    UICollectionView *_sortCollectionView;
    UILabel *sortLabel;
    NSMutableArray *_selectedFiles;
    NSMutableArray *_oldSelectedFiles;
    NSIndexPath *_selectedIndexpath;
    RDATMHud *_hud;
    RDReorderableCollectionViewFlowLayout * flow;
}
@end

@implementation RD_SortViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;////关闭滑动返回的手势
}

- (void)refreshAllView{
    if(_sortCollectionView.superview){
        [_sortCollectionView removeFromSuperview];
        [sortLabel reloadInputViews];
        sortLabel = nil;
    }
    CGRect cllectionRect;
    cllectionRect = CGRectMake(0.0, iPhone_X ? 44 : 0, kWIDTH, kHEIGHT - kToolbarHeight);
   
    flow = [[RDReorderableCollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    float width = (cllectionRect.size.width - (5.0) * 8.0) / (4.0);
    flow.itemSize = CGSizeMake(width,width);
    flow.sectionInset = UIEdgeInsetsMake(0.0, 8.0,  0.0, 8.0);
    flow.minimumLineSpacing = 8.0;
    flow.minimumInteritemSpacing = 5.0;
    
    _sortCollectionView = [[UICollectionView alloc] initWithFrame:cllectionRect  collectionViewLayout: flow];
    _sortCollectionView.delegate = self;
    _sortCollectionView.dataSource = self;
    _sortCollectionView.alwaysBounceVertical = YES;
    _sortCollectionView.alwaysBounceHorizontal = NO;
    [_sortCollectionView registerClass:[RDHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader  withReuseIdentifier:@"headView"];
    [_sortCollectionView registerClass:[RDFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter  withReuseIdentifier:@"footView"];
    [_sortCollectionView registerClass:[RD_SelectionCollectionViewCell class] forCellWithReuseIdentifier:@"PlayingCardCell"];
    [self.view addSubview:_sortCollectionView];
    _sortCollectionView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
                                                                         
   sortLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (_selectedFiles.count/4 + 1) * ( width + 8.0 ) + 8.0 + ( width  - 20 )/2.0, kWIDTH, 20)];
   sortLabel.font = [UIFont systemFontOfSize:14];
   sortLabel.textColor = UIColorFromRGB(0x8b8a8f);
   sortLabel.textAlignment = NSTextAlignmentCenter;
   sortLabel.text =                             RDLocalizedString(@"长按并拖动某一素材，调整顺序", nil);
   [_sortCollectionView addSubview:sortLabel];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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
    
    _selectedIndexpath = [NSIndexPath indexPathForRow:0 inSection:0];
    _selectedFiles = [_allThumbFiles mutableCopy];
    _oldSelectedFiles = [_allThumbFiles mutableCopy];
    
    CGRect cllectionRect = CGRectMake(0.0, iPhone_X ? 44 : 0, kWIDTH, kHEIGHT - kToolbarHeight);
    
    flow = [[RDReorderableCollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionVertical;
    float width = (cllectionRect.size.width - (5.0) * 8.0) / (4.0);
    flow.itemSize = CGSizeMake(width,width);
    flow.sectionInset = UIEdgeInsetsMake(0.0, 8.0,  0.0 , 8.0);
    flow.minimumLineSpacing = 8.0;
    flow.minimumInteritemSpacing = 5.0;

    _sortCollectionView = [[UICollectionView alloc] initWithFrame:cllectionRect  collectionViewLayout: flow];
    _sortCollectionView.delegate = self;
    _sortCollectionView.dataSource = self;
    _sortCollectionView.alwaysBounceVertical = YES;
    _sortCollectionView.alwaysBounceHorizontal = NO;
    [_sortCollectionView registerClass:[RDHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader  withReuseIdentifier:@"headView"];
    [_sortCollectionView registerClass:[RDFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter  withReuseIdentifier:@"footView"];
    [_sortCollectionView registerClass:[RD_SelectionCollectionViewCell class] forCellWithReuseIdentifier:@"PlayingCardCell"];
    [self.view addSubview:_sortCollectionView];
    
//    _sortCollectionView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    _sortCollectionView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    
    sortLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (_selectedFiles.count/4 + 1) * ( width + 8.0 ) + 8.0 +  ( width - 20 )/2.0, kWIDTH, 20)];
    sortLabel.font = [UIFont systemFontOfSize:14];
    sortLabel.textColor = UIColorFromRGB(0x8b8a8f);
    sortLabel.textAlignment = NSTextAlignmentCenter;
    sortLabel.text =                             RDLocalizedString(@"长按并拖动某一素材，调整顺序", nil);
    [_sortCollectionView addSubview:sortLabel];
    
    _hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:_hud.view];
    
    [self initToolBarView];
}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self.view addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"title-sort", nil);
    titleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    titleLbl.font = [UIFont boldSystemFontOfSize:17.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelBtnBtnOnClick) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
    [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(finishBtnBtnOnClick) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
}

- (void)cancelBtnBtnOnClick{
    _sortCollectionView.delegate = nil;
    _sortCollectionView.dataSource = NULL;
    [_sortCollectionView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if(_sortCollectionView.superview)
       [_sortCollectionView removeFromSuperview];
    _sortCollectionView = nil;
    
    [_selectedFiles removeAllObjects];
    _selectedFiles = nil;
    [_oldSelectedFiles removeAllObjects];
    _oldSelectedFiles = nil;
    
    [_allThumbFiles removeAllObjects];
    _allThumbFiles = nil;
    [flow invalidatesScrollTimer];
    flow = nil;
    if(_hud.view.superview)
       [_hud.view removeFromSuperview];
    _hud.delegate = nil;
    [_hud releaseHud];
    _hud = nil;
    _cancelAction(_oldSelectedFiles);

    _cancelAction = nil;
    
    _finishAction = nil;
    [self.navigationController popViewControllerAnimated:NO];
    
}

- (void)finishBtnBtnOnClick{
    _finishAction(_selectedFiles);
    
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)theCollectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    return _selectedFiles.count + ((_maxImageCount == 0 || _selectedFiles.count < _maxImageCount) ? 1 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RD_SelectionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlayingCardCell" forIndexPath:indexPath];
    cell.state = UIControlStateNormal;//_onlyShowTheFirstSection ? UIControlStateSelected : UIControlStateNormal;
    cell.thumbIconView.image = nil;
    if(indexPath.row==_selectedFiles.count && _selectedIndexpath.row != indexPath.row && (_maxImageCount == 0 || _selectedFiles.count < _maxImageCount)){
        [cell setDeleteBtn:false deleteAction:nil];
        cell.durationBackView.hidden = YES;
        cell.thumbIdlabel.hidden = YES;
        cell.canAddTouch = YES;
        cell.thumbfile = nil;
        cell.thumbDurationlabel.hidden = YES;
        cell.thumbIconView.image = [RDHelpClass imageWithContentOfFile:@"jianji/剪辑_添加素材默认_"];
    }else{
        if( _isShowDelete )
        {
            [cell setDeleteBtn:YES deleteAction:^(RDFile *file) {
                if( self->_selectedFiles.count > 1 )
                {
                    [self->_selectedFiles removeObject:file];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_sortCollectionView reloadData];
                    });
                }
                else
                {
                    [_hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"至少保留一个文件", nil)]];
                    [_hud show];
                    [_hud hideAfter:2];
                }
            }];
        }
        else
        {
            [cell setDeleteBtn:false deleteAction:nil];
        }
        cell.canAddTouch = NO;
        cell.thumbIdlabel.hidden = NO;
        cell.durationBackView.hidden = NO;
        cell.thumbDurationlabel.hidden = NO;
        RDFile *cellFile = ((RDFile *) _selectedFiles[indexPath.item]);
        cell.thumbIdlabel.text = [NSString stringWithFormat:@"%zd",[indexPath item]+1];
        if(!cellFile.thumbImage && cellFile.fileType == kFILEIMAGE){
            cellFile.thumbImage = [RDHelpClass getThumbImageWithUrl:cellFile.contentURL];
            
        }
        if(cellFile.fileType == kFILEVIDEO){
            if(cellFile.isReverse){
                NSString *str = [RDHelpClass timeToStringFormat:((CMTimeGetSeconds(cellFile.reverseDurationTime) > CMTimeGetSeconds(cellFile.reverseVideoTimeRange.duration) && CMTimeCompare(kCMTimeZero, cellFile.reverseVideoTrimTimeRange.duration) == -1) ?  CMTimeGetSeconds(cellFile.reverseVideoTrimTimeRange.duration) : CMTimeGetSeconds(cellFile.reverseDurationTime))/cellFile.speed];
                cell.thumbDurationlabel.text = str;
            }else{
                NSString *str = [RDHelpClass timeToStringFormat:((CMTimeGetSeconds(cellFile.videoDurationTime) > CMTimeGetSeconds(cellFile.videoTimeRange.duration) && CMTimeCompare(kCMTimeZero, cellFile.videoTrimTimeRange.duration) == -1) ?  CMTimeGetSeconds(cellFile.videoTrimTimeRange.duration) : CMTimeGetSeconds(cellFile.videoDurationTime))/cellFile.speed];
                cell.thumbDurationlabel.text = str;
            }
            
        }
        else{
            NSString *str = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(cellFile.imageDurationTime)];
            cell.thumbDurationlabel.text = str;
        }
        
        cell.thumbfile = cellFile;
        
        cell.thumbIconView.image = cellFile.thumbImage;
        
        
        if(_selectedIndexpath.item == indexPath.item){
            [cell setSelected:YES];
            cell.coverView.alpha = 0.66;
        }else{
            [cell setSelected:NO];
            cell.coverView.alpha = 0.0;
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    RD_SelectionCollectionViewCell * cell = (RD_SelectionCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if(indexPath.row == _selectedFiles.count){
        cell.thumbIconView.highlighted = NO;
        [[collectionView class] cancelPreviousPerformRequestsWithTarget:collectionView selector:@selector(reloadData) object:nil];
        [self addThumbFile];
    }else {
        _selectedIndexpath = indexPath;
        for (RD_SelectionCollectionViewCell *iCell in [collectionView visibleCells]) {
            NSIndexPath *icellIndexPath = [collectionView indexPathForCell:iCell];
            if(_selectedIndexpath.item == icellIndexPath.item){
                [iCell setSelected:YES];
                iCell.coverView.alpha = 0.66;
            }else{
                [iCell setSelected:NO];
                iCell.coverView.alpha = 0.0;
            }
        }
    }
}

- (void)addThumbFile{
    if (_maxImageCount > 0) {
        ((RDNavigationViewController *)self.navigationController).editConfiguration.mediaCountLimit =  _maxImageCount - _selectedFiles.count;
    }
    __weak typeof(self) myself = self;
    
    if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideoAndImageResult:callbackBlock:)]){
        
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideoAndImageResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
            [myself addFileLists:lists];
        }];
        
        return;
    }
    
    if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectVideosResult:callbackBlock:)]){
        
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectVideosResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
            [myself addFileLists:lists];
        }];
        
        return;
    }
    if([((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate respondsToSelector:@selector(selectImagesResult:callbackBlock:)]){
       
        [((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate selectImagesResult:self.navigationController callbackBlock:^(NSMutableArray * _Nonnull lists) {
            [myself addFileLists:lists];
        }];
        
        return;
    }
    
    
    RDMainViewController *mainVC = [[RDMainViewController alloc] init];
    mainVC.needPush = NO;
    mainVC.selectFinishActionBlock = ^(NSMutableArray <RDFile *>*filelist){
        [myself addFileLists:filelist];
    };
    RDNavigationViewController* nav = [[RDNavigationViewController alloc] initWithRootViewController:mainVC];
    nav.edit_functionLists = ((RDNavigationViewController *)self.navigationController).edit_functionLists;
    nav.exportConfiguration = ((RDNavigationViewController *)self.navigationController).exportConfiguration;
    nav.editConfiguration = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    nav.cameraConfiguration = ((RDNavigationViewController *)self.navigationController).cameraConfiguration;
    nav.outPath = ((RDNavigationViewController *)self.navigationController).outPath;
    nav.appAlbumCacheName = ((RDNavigationViewController *)self.navigationController).appAlbumCacheName;
    nav.appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    nav.appSecret = ((RDNavigationViewController *)self.navigationController).appSecret;
    nav.statusBarHidden = ((RDNavigationViewController *)self.navigationController).statusBarHidden;
    nav.folderType = ((RDNavigationViewController *)self.navigationController).folderType;
    nav.videoAverageBitRate = ((RDNavigationViewController *)self.navigationController).videoAverageBitRate;
    nav.waterLayerRect = ((RDNavigationViewController *)self.navigationController).waterLayerRect;
    nav.callbackBlock = ((RDNavigationViewController *)self.navigationController).callbackBlock;
    nav.rdVeUiSdkDelegate = ((RDNavigationViewController *)self.navigationController).rdVeUiSdkDelegate;
    
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addFileLists:(NSMutableArray *)fileList {
    if ([fileList[0] isKindOfClass:[NSURL class]]) {
        for (int i = 0; i < fileList.count; i++) {
            NSURL *url = fileList[i];
            if ([url isKindOfClass:[NSURL class]]) {
                RDFile *file = [RDFile new];
                if([RDHelpClass isImageUrl:url]){
                    //图片
                    file.contentURL = url;
                    file.fileType = kFILEIMAGE;
                    file.imageDurationTime = CMTimeMakeWithSeconds(3, TIMESCALE);
                    file.speedIndex = 1;
                }else{
                    //视频
                    file.contentURL = url;
                    file.fileType = kFILEVIDEO;
                    AVURLAsset * asset = [AVURLAsset assetWithURL:file.contentURL];
                    CMTime duration = asset.duration;
                    file.videoDurationTime = duration;
                    file.videoTimeRange = CMTimeRangeMake(kCMTimeZero,file.videoDurationTime);
                    file.reverseVideoTimeRange = file.videoTimeRange;
                    file.videoTrimTimeRange = kCMTimeRangeInvalid;
                    file.reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
                    file.speedIndex = 2;
                }
                file.thumbImage = [RDHelpClass getThumbImageWithUrl:file.contentURL];
                [fileList replaceObjectAtIndex:i withObject:file];
            }
        }
    }
    NSRange range = NSMakeRange(_selectedIndexpath.item+1, [fileList count]);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    
    
    [_selectedFiles insertObjects:fileList atIndexes:indexSet];
     
    float width = (_sortCollectionView.frame.size.width - (5.0) * 8.0) / (4.0);
    
    sortLabel.frame = CGRectMake(0, (_selectedFiles.count/4 + 1) * ( width + 8.0 ) + 8.0  + ( width - 20 )/2.0, kWIDTH, 20);
    sortLabel.font = [UIFont systemFontOfSize:14];
    sortLabel.textColor = UIColorFromRGB(0x8b8a8f          );
    sortLabel.textAlignment = NSTextAlignmentCenter;
    sortLabel.text =                             RDLocalizedString(@"长按并拖动某一素材，调整顺序", nil);
    [_sortCollectionView addSubview:sortLabel];
    
    [_sortCollectionView reloadData];
}

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    
    if(toIndexPath.item != _selectedFiles.count && fromIndexPath.item != _selectedFiles.count){
        RDFile *playingCard = _selectedFiles[fromIndexPath.item];
        
        [_selectedFiles removeObjectAtIndex:fromIndexPath.item];
        [_selectedFiles insertObject:playingCard atIndex:toIndexPath.item];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.item == _selectedFiles.count){
        return NO;
    }
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    if(toIndexPath.item == _selectedFiles.count || fromIndexPath.item == _selectedFiles.count){
        return NO;
    }
    return YES;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader){
        RDHeaderView *headview =  (RDHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind  withReuseIdentifier:@"headView"  forIndexPath: indexPath];
        headview.backgroundColor = [UIColor clearColor];
        return headview;
    }
    else {
        RDFooterView *footView =  (RDFooterView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind  withReuseIdentifier:@"footView"  forIndexPath: indexPath];
        footView.backgroundColor = [UIColor clearColor];

        return footView;
    }
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, 8);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, 8);
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"will end drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did end drag");
    _selectedIndexpath = indexPath;
     [collectionView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc{
    NSLog(@"%s",__func__);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
