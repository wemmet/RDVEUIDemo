//
//  RDTransitionViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDTransitionViewController : UIViewController

@property (nonatomic, strong) NSMutableArray <RDFile *>*fileList;

@property (nonatomic, copy) NSString *outputPath;

@property (nonatomic, assign) CGSize exportSize;

@end
