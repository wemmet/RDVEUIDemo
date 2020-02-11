//
//  RDTextToSpeechViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/7/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDTextToSpeechViewController : UIViewController

@property(nonatomic,copy) void (^cancelBlock)(void);

@end

NS_ASSUME_NONNULL_END
