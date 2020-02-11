//
//  PictureMovieViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2017/12/1.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

@interface PictureMovieViewController : UIViewController

@property(nonatomic,strong)NSMutableArray <RDFile *>*fileList;

@property(nonatomic,copy) void (^cancelBlock)();

@end
