//
//  RDNavigationViewController.m
//  RDVEUISDK
//
//  Created by 周晓林 on 2016/11/4.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDNavigationViewController.h"

@interface RDNavigationViewController ()<UIGestureRecognizerDelegate>

@end

@implementation RDNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalPresentationStyle =  UIModalPresentationFullScreen;
    self.navigationBarHidden = YES;
    // 获取系统自带滑动手势的target对象
    id target = self.interactivePopGestureRecognizer.delegate;
    // 创建全屏滑动手势，调用系统自带滑动手势的target的action方法
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:target action:@selector(handleNavigationTransition:)];
    // 设置手势代理，拦截手势触发
    pan.delegate = self;
    // 给导航控制器的view添加全屏滑动手势
    [self.view addGestureRecognizer:pan];
    // 禁止使用系统自带的滑动手势
    self.interactivePopGestureRecognizer.enabled = NO;
}

- (void)handleNavigationTransition:(UIPanGestureRecognizer *)gesture{
    NSLog(@"%s",__func__);
}
// 什么时候调用：每次触发手势之前都会询问下代理，是否触发。
// 作用：拦截手势触发
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // 注意：只有非根控制器才有滑动返回功能，根控制器没有。
    // 判断导航控制器是否只有一个子控制器，如果只有一个子控制器，肯定是根控制器
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        // 表示用户在根控制器界面，就不需要触发滑动手势，
        return NO;
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
- (BOOL)shouldAutorotate{
    return YES;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}
-(nullable UIViewController *)rdPopViewControllerAnimated:(BOOL)animated{
    if(animated){
        CATransition* transition = [CATransition animation];
        //执行时间长短
        transition.duration = 0.1;
        //动画的开始与结束的快慢
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];//kCAMediaTimingFunctionEaseInEaseOut
        //各种动画效果
        transition.type = kCATransitionMoveIn;
        //动画方向
        transition.subtype = kCATransitionFromBottom;
        //将动画添加在视图层上
        [self.view.layer addAnimation:transition forKey:nil];
    }
    UIViewController *popViewController = [self popViewControllerAnimated:NO];
    return popViewController;
}


- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
