//
//  AudioFilterViewController.h
//  RDVEUISDK
//
//  Created by 周晓林 on 2018/1/13.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

@interface AudioFilterViewController : UIViewController
@property(nonatomic,strong)NSMutableArray <RDFile *>*fileList;

@property(nonatomic,copy) void (^cancelBlock)(void);

@end
