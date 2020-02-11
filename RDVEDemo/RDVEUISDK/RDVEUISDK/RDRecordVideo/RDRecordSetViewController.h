//
//  RDRecordSetViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/4.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDRecordSetViewController : UIViewController

@property (nonatomic,copy) void (^changeRecordSetFinish)(int bitrate, int resolutionIndex);

@end

NS_ASSUME_NONNULL_END
