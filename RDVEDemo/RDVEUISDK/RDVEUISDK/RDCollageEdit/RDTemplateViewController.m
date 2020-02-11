//
//  TemplateViewController.m
//  RDAVEDemo
//
//  Created by apple on 2017/8/24.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTemplateViewController.h"
#import "RDCustomSizeLayout.h"
#import "RDTemplateCollectionViewCell.h"
#import "RDChangeTemplateCollectionViewCell.h"
#import "RDCollageEditViewController.h"

@interface RDTemplateViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, RDChangeTemplateCollectionViewCellDelegate>
{
    RDCustomSizeLayout  * templateLayout;
    NSInteger             selectedTemplateIndex;
    UICollectionView    * templateBtnCollectionView;
    NSMutableArray      * templateBtnArray;
    NSInteger             selectedTemplateBtnIndex;
    NSMutableArray      * videosFrameArray;
}

@property (nonatomic, strong) UICollectionView    * templateCollectionView;

@end

@implementation RDTemplateViewController

- (BOOL)prefersStatusBarHidden {
    return !iPhone_X;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    [self initTitleView];
    [self.view addSubview:self.templateCollectionView];
    [self initBtnCollectionView];
}

- (void)initTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
    [self.view addSubview:titleView];
    
    UILabel *titleLbl = [UILabel new];
    titleLbl.frame = CGRectMake(0, 0, kWIDTH, 44);
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:20];
    titleLbl.text = RDLocalizedString(@"选择画框", nil);
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [titleView addSubview:titleLbl];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(5, 0, 44, 44);
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    
    UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nextBtn.frame = CGRectMake(kWIDTH - 67, 0, 60, 44);
    nextBtn.backgroundColor = [UIColor clearColor];
    [nextBtn setTitle:RDLocalizedString(@"下一步", nil) forState:UIControlStateNormal];
    [nextBtn setTitleColor:UIColorFromRGB(Main_Color) forState:UIControlStateNormal];
    nextBtn.titleLabel.textAlignment = NSTextAlignmentRight;
    nextBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:nextBtn];
}

- (UICollectionView *)templateCollectionView {
    if (_templateCollectionView) {
        _templateCollectionView.delegate = nil;
        _templateCollectionView.dataSource = nil;
        [_templateCollectionView removeFromSuperview];
        _templateCollectionView = nil;
    }
    if (!templateLayout) {
        templateLayout = [[RDCustomSizeLayout alloc] init];
        templateLayout.templateIndex = selectedTemplateIndex + 1;
    }
    
    _templateCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 44, kWIDTH, kWIDTH) collectionViewLayout:templateLayout];
    _templateCollectionView.backgroundColor = [UIColor clearColor];
    [_templateCollectionView registerClass:[RDTemplateCollectionViewCell class] forCellWithReuseIdentifier:@"TemplateCollectionViewCell"];
    _templateCollectionView.showsHorizontalScrollIndicator = NO;
    _templateCollectionView.dataSource = self;
    _templateCollectionView.delegate = self;
    _templateCollectionView.tag = 1;
    
    return _templateCollectionView;
}

- (void)initBtnCollectionView {
    templateBtnArray = [NSMutableArray array];
    videosFrameArray = [NSMutableArray array];
    for (int i = 1; i < 9; i++) {
        [templateBtnArray addObject:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/collage/画框480-%zd-1", i] Type:@"png"]];
    }
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 1.0;
    flowLayout.minimumInteritemSpacing = 15.0;
    flowLayout.itemSize = CGSizeMake(50, 50);
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    templateBtnCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 44 + kWIDTH + (kHEIGHT - 44 - kWIDTH - 50)/2.0, kWIDTH, 50) collectionViewLayout:flowLayout];
    templateBtnCollectionView.backgroundColor = [UIColor clearColor];
    [templateBtnCollectionView registerClass:[RDChangeTemplateCollectionViewCell class] forCellWithReuseIdentifier:@"TemplateBtnCollectionViewCell"];
    templateBtnCollectionView.showsHorizontalScrollIndicator = NO;
    templateBtnCollectionView.dataSource = self;
    templateBtnCollectionView.delegate = self;
    templateBtnCollectionView.tag = 2;
    [self.view addSubview:templateBtnCollectionView];
}

#pragma mark - 按钮事件
- (void)backBtnAction:(UIButton *)sender {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)nextBtnAction:(UIButton *)sender {
    videosFrameArray = [NSMutableArray array];
    CGRect frame = CGRectZero;
    float spaceX = 3.0/kWIDTH/2.0;    //边框幅度为3.0
    float spaceY = 3.0/kHEIGHT/2.0;
    switch (selectedTemplateIndex + 1) {
        case 1:
            frame = CGRectMake(0, 0, 1, 1);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        case 2:
            frame = CGRectMake(0, 0, 1.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 0.5 + spaceY, 1.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        case 3:
            frame = CGRectMake(0, 0, 0.5 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0.5 + spaceX, 0, 0.5 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 0.5 + spaceY, 1, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
        case 4:
            frame = CGRectMake(0, 0, 0.5 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0.5 + spaceX, 0, 0.5 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 0.5 + spaceY, 0.5 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0.5 + spaceX, 0.5 + spaceY, 0.5 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        case 5:
            frame = CGRectMake(0, 0, 1/3.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/3.0 + spaceX, 0, 1/3.0 - spaceX*2.0, 1);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/3.0*2.0 + spaceX, 0, 1/3.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 0.5 + spaceY, 1/3.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/3.0*2.0 + spaceX, 0.5 + spaceY, 1/3.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        case 6:
            frame = CGRectMake(0, 0, 0.5 - spaceX, 1/3.0 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0.5 + spaceX, 0, 0.5 - spaceX, 1/3.0 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 1/3.0 + spaceY, 0.5 - spaceX, 1/3.0 - spaceY*2.0);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0.5 + spaceX, 1/3.0 + spaceY, 0.5 - spaceX, 1/3.0 - spaceY*2.0);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 1/3.0*2.0 + spaceY, 0.5 - spaceX, 1/3.0 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0.5 + spaceX, 1/3.0*2.0 + spaceY, 0.5 - spaceX, 1/3.0 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        case 7:
            frame = CGRectMake(0, 0, 1/3.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/3.0 + spaceX, 0, 1/3.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/3.0*2.0 + spaceX, 0, 1/3.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 0.5 + spaceY, 1/4.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0 + spaceX, 0.5 + spaceY, 1/4.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0*2.0 + spaceX, 0.5 + spaceY, 1/4.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0*3.0 + spaceX, 0.5 + spaceY, 1/4.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        case 8:
            frame = CGRectMake(0, 0, 1/4.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0 + spaceX, 0, 1/4.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0*2.0 + spaceX, 0, 1/4.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0*3.0 + spaceX, 0, 1/4.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(0, 0.5 + spaceY, 1/4.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0 + spaceX, 0.5 + spaceY, 1/4.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0*2.0 + spaceX, 0.5 + spaceY, 1/4.0 - spaceX*2.0, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            
            frame = CGRectMake(1/4.0*3.0 + spaceX, 0.5 + spaceY, 1/4.0 - spaceX, 0.5 - spaceY);
            [videosFrameArray addObject:[NSValue valueWithCGRect:frame]];
            break;
            
        default:
            break;
    }

    RDCollageEditViewController *multiVideoEditVC = [[RDCollageEditViewController alloc] init];
    multiVideoEditVC.videosFrameArray = videosFrameArray;
    multiVideoEditVC.selectedTemplateIndex = selectedTemplateIndex + 1;
    [self.navigationController pushViewController:multiVideoEditVC animated:YES];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == 1) {
        return selectedTemplateIndex + 1;
    }
    return templateBtnArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView.tag == 1) {
        static NSString * CellIdentifier = @"TemplateCollectionViewCell";
        RDTemplateCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.backgroundColor = [UIColor clearColor];
        
        return cell;
    }
    static NSString * CellIdentifier = @"TemplateBtnCollectionViewCell";
    RDChangeTemplateCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.delegate = self;
    
    if (indexPath.row == selectedTemplateIndex) {
        cell.templateBtn.selected = YES;
        cell.templateBtn.backgroundColor = UIColorFromRGB(0x2ab4fb);
        
        selectedTemplateBtnIndex = indexPath.row;
    }
    [cell.templateBtn setTitle:[NSString stringWithFormat:@"%zd", indexPath.row + 1] forState:UIControlStateNormal];
    [cell.templateBtn setImage:[RDHelpClass imageWithContentOfPath:[templateBtnArray objectAtIndex:indexPath.row]] forState:UIControlStateNormal];
    
    return cell;
}

#pragma mark - RDChangeTemplateCollectionViewCellDelegate
- (void)changeTemplate:(RDChangeTemplateCollectionViewCell *)cell {
    NSInteger newIndex = [templateBtnCollectionView indexPathForCell:cell].row;
    if (selectedTemplateIndex != newIndex) {
        RDChangeTemplateCollectionViewCell *prevCell = (RDChangeTemplateCollectionViewCell *)[templateBtnCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedTemplateIndex inSection:0]];
        prevCell.templateBtn.selected = NO;
        prevCell.templateBtn.backgroundColor = [UIColor clearColor];
        
        cell.templateBtn.selected = YES;
        cell.templateBtn.backgroundColor = UIColorFromRGB(0x2ab4fb);
        
        selectedTemplateIndex = newIndex;
        templateLayout.templateIndex = selectedTemplateIndex + 1;
        [self.view addSubview:self.templateCollectionView];
    }
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
