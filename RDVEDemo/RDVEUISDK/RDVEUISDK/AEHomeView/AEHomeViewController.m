//
//  AEHomeViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/10/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AEHomeViewController.h"
#import "RDNavigationViewController.h"
#import "RD_RDReachabilityLexiu.h"
#import "RDATMHud.h"
#import "RDSVProgressHUD.h"
#import "UIImageView+RDWebCache.h"
#import "AETemplateInfoViewController.h"
#import "RDWaterFallLayout.h"
#import "AECollectionViewCell.h"
#import "RDVECore.h"

@interface AEHomeViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, RDWaterFallLayoutDataSource, UIScrollViewDelegate>
{
    UIScrollView        *typeScrollView;
    UIView              *selectedTypeView;
    NSInteger            selectedTypeIndex;
    RDATMHud            *hud;
    NSMutableArray      *aeTemplateList;
    UIScrollView        *templateScrollView;
}

@end

@implementation AEHomeViewController

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
    self.navigationController.navigationBar.translucent = NO;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);    
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.title = RDLocalizedString(@"AE模板", nil);
    
    hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:hud.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [hud.view removeFromSuperview];
    hud.delegate = nil;
    [hud releaseHud];
    hud = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"加载中,请稍候...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:kMVAnimateFolder]){
        [fileManager createDirectoryAtPath:kMVAnimateFolder withIntermediateDirectories:YES attributes:nil error:&error];
    }
    [self initTypeScrollView];
    [self initTemplateScrollView];
    [self getAeTemplateList];
    [self initNavigationItem];
}

- (void)initNavigationItem{
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [leftBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    leftBtn.titleLabel.textAlignment=NSTextAlignmentRight;
    [leftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
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

- (void)initTypeScrollView {
    typeScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    typeScrollView.showsVerticalScrollIndicator = NO;
    typeScrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:typeScrollView];
}

- (void)refreshTypeScrollView {
    float space = 20;
    __block float allWidth = 0;
    
    selectedTypeView = [[UIView alloc] initWithFrame:CGRectMake(0, 44 - 6, 20, 2)];
    selectedTypeView.backgroundColor = Main_Color;
    [typeScrollView addSubview:selectedTypeView];
    
    [aeTemplateList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake((idx + 1)*space + allWidth, 0, 20, typeScrollView.bounds.size.height);
        [itemBtn setTitle:obj[@"typeName"] forState:UIControlStateNormal];
        [itemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [itemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        itemBtn.tag = idx + 1;
        float fitWidth = [itemBtn sizeThatFits:CGSizeZero].width;
        CGRect frame = itemBtn.frame;
        frame.size.width = fitWidth;
        itemBtn.frame = frame;
        if (idx == 0) {
            itemBtn.selected = YES;
            selectedTypeView.frame = CGRectMake(itemBtn.frame.origin.x, 44 - 6, fitWidth, 2);
        }
        allWidth += fitWidth;
        [itemBtn addTarget:self action:@selector(typeItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [typeScrollView addSubview:itemBtn];
    }];
    typeScrollView.contentSize = CGSizeMake((aeTemplateList.count + 1)*space + allWidth, 0);
}

- (void)initTemplateScrollView {
    templateScrollView = [[UIScrollView alloc] init];
    if (iPhone_X) {
        templateScrollView.frame = CGRectMake(0, 44, kWIDTH, kHEIGHT - 132);
    }else {
        templateScrollView.frame = CGRectMake(0, 44, kWIDTH, kHEIGHT - 20 - 88);
    }
    templateScrollView.showsHorizontalScrollIndicator = NO;
    templateScrollView.showsVerticalScrollIndicator = NO;
    templateScrollView.pagingEnabled = YES;
    templateScrollView.delegate = self;
    [self.view addSubview:templateScrollView];
}

- (void)refreshTemplateScrollView {
    [aeTemplateList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDWaterFallLayout * flow = [[RDWaterFallLayout alloc] init];
        flow.dataSource = self;
        CGRect frame = templateScrollView.bounds;
        frame.origin.x = kWIDTH*idx;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:flow];
        if (iPhone_X) {
            collectionView.contentInset = UIEdgeInsetsMake(0, 0, 34, 0);
        }
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.tag = idx + 1;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        [collectionView registerClass:[AECollectionViewCell class] forCellWithReuseIdentifier:@"templateCell"];
        [templateScrollView addSubview:collectionView];
    }];
    templateScrollView.contentSize = CGSizeMake(kWIDTH*aeTemplateList.count, 0);
}

- (void)getAeTemplateList {
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if([lexiu currentReachabilityStatus] == RDNotReachable){
        [RDSVProgressHUD dismiss];
        aeTemplateList = [[NSArray arrayWithContentsOfFile:kMVAnimatePlistPath] mutableCopy];
        
        [hud setCaption:RDLocalizedString(@"无可用的网络", nil)];
        [hud show];
        [hud hideAfter:2];
        return;
    }
    RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:nav.appKey forKey:@"appkey"];
        [params setObject:@"videoae" forKey:@"type"];
        NSDictionary *typeDic = [RDHelpClass getNetworkMaterialWithParams:params appkey:nav.appKey urlPath:nav.editConfiguration.netMaterialTypeURL];
        if (typeDic && [typeDic[@"code"] intValue] == 0) {
            NSArray *tempTemplateList = [NSArray arrayWithContentsOfFile:kMVAnimatePlistPath];
            aeTemplateList = [NSMutableArray array];
            NSMutableArray *typeArray = typeDic[@"data"];
            [typeArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableDictionary *paramArray = [NSMutableDictionary dictionary];
                [paramArray setObject:nav.appKey forKey:@"appkey"];
                [paramArray setObject:@"videoae" forKey:@"type"];
                [paramArray setObject:[NSNumber numberWithInt:[obj[@"id"] intValue]] forKey:@"category"];
                NSDictionary *resultDic = [RDHelpClass getNetworkMaterialWithParams:paramArray appkey:nav.appKey urlPath:nav.editConfiguration.newmvResourceURL];
                if (resultDic && [resultDic[@"code"] intValue] == 0) {
                    NSArray *array = resultDic[@"data"];
                    int categoryId = [obj[@"id"] intValue];
                    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:categoryId], @"typeId",
                                         obj[@"name"], @"typeName",
                                         array, @"data",
                                         nil];
                    [aeTemplateList addObject:dic];
                    if (tempTemplateList.count > 0) {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                            NSString *file = [obj1[@"file"] stringByDeletingPathExtension];
                            NSString *updateTime = obj1[@"updatetime"];
                            __block NSString *tmpUpdateTime;
                            [tempTemplateList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
                                if ([[obj2 objectForKey:@"typeId"] intValue] == categoryId) {
                                    [obj2[@"data"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj3, NSUInteger idx3, BOOL * _Nonnull stop3) {
                                        if ([[obj3[@"file"] stringByDeletingPathExtension] isEqualToString:file]) {
                                            tmpUpdateTime = obj3[@"updatetime"];
                                            *stop3 = YES;
                                            *stop2 = YES;
                                        }
                                    }];
                                }
                            }];
                            if(tmpUpdateTime && ![tmpUpdateTime isEqualToString:updateTime])
                            {
                                NSString *file = [[[obj1[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: [[obj1[@"file"] lastPathComponent] stringByDeletingPathExtension]];
                                NSString *path = [kMVAnimateFolder stringByAppendingPathComponent:file];
                                NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:nil];
                                NSString *name = [files lastObject];
                                NSString *jsonPath = [NSString stringWithFormat:@"%@%@.json", [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimate/"], name];
                                if ([fileManager fileExistsAtPath:jsonPath]) {
                                    [fileManager removeItemAtPath:jsonPath error:nil];
                                }
                                jsonPath = [NSString stringWithFormat:@"%@/%@.json", kMVAnimateFolder, file];
                                if ([fileManager fileExistsAtPath:jsonPath]) {
                                    [fileManager removeItemAtPath:jsonPath error:nil];
                                }
                                jsonPath = [NSString stringWithFormat:@"%@%@.json", [NSTemporaryDirectory() stringByAppendingString:@"RDMVAnimate/"], file];
                                if ([fileManager fileExistsAtPath:jsonPath]) {
                                    [fileManager removeItemAtPath:jsonPath error:nil];
                                }
                                if ([fileManager fileExistsAtPath:path]) {
                                    [fileManager removeItemAtPath:path error:nil];
                                }
                            }
                        }];
                    }
                }
            }];
            if (aeTemplateList.count > 0) {
                [aeTemplateList writeToFile:kMVAnimatePlistPath atomically:YES];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [RDSVProgressHUD dismiss];
                [self refreshTypeScrollView];
                [self refreshTemplateScrollView];
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                aeTemplateList = [[NSArray arrayWithContentsOfFile:kMVAnimatePlistPath] mutableCopy];
                [RDSVProgressHUD dismiss];
                [self refreshTypeScrollView];
                [self refreshTemplateScrollView];
            });
        }
    });
}

#pragma mark - RDWaterFallLayoutDataSource
- (CGFloat)waterFallLayout:(RDWaterFallLayout *)waterFallLayout heightForItemAtIndexPath:(NSInteger)indexPath itemWidth:(CGFloat)itemWidth
{
    NSArray *array = [aeTemplateList[waterFallLayout.collectionView.tag - 1] objectForKey:@"data"];
    NSDictionary *itemDic = [array objectAtIndex:indexPath];
    CGSize size = CGSizeMake([[itemDic objectForKey:@"width"] floatValue], [[itemDic objectForKey:@"height"] floatValue]);
    float height = kWIDTH/2.0 / (size.width / size.height) + 35;
    return height;
}

#pragma mark - UICollectionViewDelegate/UICollectViewdataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSArray *array = [aeTemplateList[collectionView.tag - 1] objectForKey:@"data"];
    return array.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"templateCell";
    NSDictionary *dic = [[aeTemplateList[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    AECollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.coverIV.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height - 35);
    [cell.coverIV rd_sd_setImageWithURL:[dic objectForKey:@"cover"]];
    cell.nameLbl.frame = CGRectMake(10, cell.coverIV.bounds.size.height, cell.frame.size.width - 20, 35);
    cell.nameLbl.text = [dic objectForKey:@"name"];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    AETemplateInfoViewController *templateInfoVC = [[AETemplateInfoViewController alloc] init];
    templateInfoVC.templateInfoArray = [aeTemplateList[collectionView.tag - 1] objectForKey:@"data"];
    templateInfoVC.currentIndex = indexPath.row;
    [self.navigationController pushViewController:templateInfoVC animated:YES];
}

#pragma mark - 按钮事件
- (void)back:(UIButton *)sender{
    UIViewController *upView = [self.navigationController popViewControllerAnimated:YES];
    if(!upView){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if(_cancelActionBlock){
        _cancelActionBlock();
    }
}

- (void)typeItemBtnAction:(UIButton *)sender {
    if (sender.tag - 1 != selectedTypeIndex) {
        UIButton *prevBtn = [typeScrollView viewWithTag:selectedTypeIndex + 1];
        prevBtn.selected = NO;
        sender.selected = YES;
        selectedTypeIndex = sender.tag - 1;
        
        if (sender.center.x < kWIDTH/2.0) {
            typeScrollView.contentOffset = CGPointMake(0, 0);
        }else if (sender.center.x - kWIDTH/2.0 <= typeScrollView.contentSize.width - kWIDTH) {
            typeScrollView.contentOffset = CGPointMake(sender.center.x - kWIDTH/2.0, 0);
        }else {
            typeScrollView.contentOffset = CGPointMake(typeScrollView.contentSize.width - kWIDTH, 0);
        }
        
        CGRect frame = selectedTypeView.frame;
        frame.origin.x = sender.frame.origin.x;
        frame.size.width = sender.frame.size.width;
        selectedTypeView.frame = frame;
        
        WeakSelf(self);
        [UIView animateWithDuration:0.3 animations:^{
            StrongSelf(self);
            strongSelf->templateScrollView.contentOffset = CGPointMake(strongSelf->selectedTypeIndex * strongSelf->templateScrollView.bounds.size.width, 0);
        }];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == templateScrollView) {
        NSInteger index = scrollView.contentOffset.x / templateScrollView.bounds.size.width;
        if (index != selectedTypeIndex) {
            UIButton *prevBtn = [typeScrollView viewWithTag:selectedTypeIndex + 1];
            prevBtn.selected = NO;
            
            selectedTypeIndex = index;
            UIButton *currBtn = [typeScrollView viewWithTag:selectedTypeIndex + 1];
            currBtn.selected = YES;
            if (currBtn.center.x < kWIDTH/2.0) {
                typeScrollView.contentOffset = CGPointMake(0, 0);
            }else if (currBtn.center.x - kWIDTH/2.0 <= typeScrollView.contentSize.width - kWIDTH) {
                typeScrollView.contentOffset = CGPointMake(currBtn.center.x - kWIDTH/2.0, 0);
            }else {
                typeScrollView.contentOffset = CGPointMake(typeScrollView.contentSize.width - kWIDTH, 0);
            }
            
            CGRect frame = selectedTypeView.frame;
            frame.origin.x = currBtn.frame.origin.x;
            frame.size.width = currBtn.frame.size.width;
            selectedTypeView.frame = frame;
        }
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
