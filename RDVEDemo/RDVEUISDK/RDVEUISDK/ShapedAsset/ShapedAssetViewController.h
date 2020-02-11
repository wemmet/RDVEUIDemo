//
//  ShapedAssetViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/5/30.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

@interface ShapedAssetViewController : UIViewController

@property(nonatomic,strong)NSURL *assetURL;

@property(nonatomic,copy) void (^cancelBlock)(void);

@end
