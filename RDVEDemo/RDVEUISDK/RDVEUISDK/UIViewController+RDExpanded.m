//
//  UIViewController+RDExpanded.m
//  RDVEUISDK
//
//  Created by apple on 2019/9/24.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "UIViewController+RDExpanded.h"

@implementation UIViewController (RDExpanded)

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

@end
