//
//  ScreenViewController.m
//  TSAVITOMP4
//
//  Created by 王全洪 on 2018/4/26.
//  Copyright © 2018年 王全洪. All rights reserved.
//
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#import "ScreenViewController.h"

@interface ScreenViewController ()
@property (nonatomic,strong) UIImageView *imageView;
@end

@implementation ScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 20, 44)];
//    titleView.backgroundColor = [UIColor clearColor];
//    self.navigationItem.titleView = titleView;
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
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
//    [titleView addSubview:backBtn];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationController.navigationBar.translucent = NO;
//    self.navigationController.navigationItem.hidesBackButton = YES;
    _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.backgroundColor = [UIColor blackColor];
    _imageView.image = _image;
    [self.view addSubview:_imageView];
    // Do any additional setup after loading the view.
    
}

- (void)cancel{
    [self.navigationController popViewControllerAnimated:YES];
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
