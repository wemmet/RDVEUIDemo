//
//  AEHomeViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/10/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AEHomeViewController : UIViewController

@property(nonatomic,copy) void (^cancelActionBlock)(void);

@end

NS_ASSUME_NONNULL_END
