//
//  RDCustomDrawViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/4/3.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDCustomDrawViewController : UIViewController

@property(nonatomic,copy) void (^cancelBlock)(void);

@end
