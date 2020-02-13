//
//  MainCropViewController.m
//  TSAVITOMP4
//
//  Created by 王全洪 on 2018/4/26.
//  Copyright © 2018年 王全洪. All rights reserved.
//
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#import "MainCropViewController.h"
#import "ScreenViewController.h"
#import "CLClippingTool.h"
#import "RDVECoreHelper.h"
@interface MainCropViewController ()
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) CLClippingPanel * gridView;

@end

@implementation MainCropViewController

- (void)cancel{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clickFinish{
    CGRect rect =  _gridView.clippingRect;
    rect.origin.x = rect.origin.x/_gridView.frame.size.width * _image.size.width;
    rect.origin.y = rect.origin.y/_gridView.frame.size.height *_image.size.height;
    rect.size.width = rect.size.width/_gridView.frame.size.width * _image.size.width;
    rect.size.height = rect.size.height/_gridView.frame.size.height *_image.size.height;
    NSLog(@"rect:%@",NSStringFromCGRect(rect));
    
    RDVECoreHelper *coreHelper = [[RDVECoreHelper alloc] initWithAPPKey:_appkey APPSecret:_appsecret resultFail:^(NSError *error) {
        NSLog(@"error:%@",error);
    }];

    UIImage *iii = self.imageView.image;

    CGRect resultRect;
    UIImage *image = [coreHelper transformImageWithSourceImage:iii sourceRect:rect destLT:CGPointMake(194, 36) destRT:CGPointMake(641, 205) destLB:CGPointMake(180, 440) destRB:CGPointMake(648, 493) destRect:&resultRect];

    UIImage *backImage = [UIImage imageNamed:@"未标题-1.jpg"];

    UIImage *resultImage = [coreHelper drawImage:backImage withImage:image inRect:resultRect];
    
    ScreenViewController *screen = [[ScreenViewController alloc] init];
    screen.image = resultImage;
    [self.navigationController pushViewController:screen animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 20, 44)];
    titleView.backgroundColor = [UIColor clearColor];
    self.navigationItem.titleView = titleView;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.navigationController.navigationBar.barTintColor=UIColorFromRGB(0x0e0e10);
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    self.view.backgroundColor = UIColorFromRGB(0x33333b);
    [self.navigationController setNavigationBarHidden:NO];
    
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 44, 44);
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setTitle:NSLocalizedString(@"返回", nil) forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:backBtn];
    //self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationController.navigationBar.translucent = NO;
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(titleView.frame.size.width - 44, 0, 44, 44);
    finishBtn.backgroundColor = [UIColor clearColor];
    [finishBtn setTitle:NSLocalizedString(@"裁剪", nil) forState:UIControlStateNormal];
    [finishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [finishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [finishBtn addTarget:self action:@selector(clickFinish) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:finishBtn];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:finishBtn];
    
    
    CGSize size = _image.size;
    float pro = size.width/size.height;
    
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height - 64;
    
    float screenPro = [UIScreen mainScreen].bounds.size.width/([UIScreen mainScreen].bounds.size.height - 64);
    CGRect rect;
    if(pro > screenPro){
        rect = CGRectMake(0, (height - width/pro)/2.0, width, width/pro);
    }else{
        rect = CGRectMake((width - height*pro)/2.0, 0, height*pro, height);
    }
    _imageView = [[UIImageView alloc] initWithFrame:rect];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.backgroundColor = [UIColor blackColor];
    _imageView.image = _image;
    [self.view addSubview:_imageView];
    
    _gridView = [[CLClippingPanel alloc] initWithSuperview:self.view frame:self.imageView.frame];
    _gridView.backgroundColor = [UIColor clearColor];
    _gridView.bgColor = [self.view.backgroundColor colorWithAlphaComponent:0.8];
    _gridView.gridColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    _gridView.clipsToBounds = NO;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
