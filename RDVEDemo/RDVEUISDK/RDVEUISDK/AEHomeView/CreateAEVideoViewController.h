//
//  CreateAEVideoViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/10/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CreateAEVideoViewController : UIViewController

@property (nonatomic, copy) NSString *templateName;

@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, copy) NSString *jsonPath;

@property (nonatomic, strong) NSMutableArray <RDFile *>*files;

/** 是否所有素材都支持视频或图片
 */
@property (nonatomic, assign) BOOL isAllVideoOrPic;

/** 是否循环
 */
@property (nonatomic, assign) BOOL isEnableRepeat;

/** 循环次数
 */
@property (nonatomic, assign) int repeatCount;

@end

NS_ASSUME_NONNULL_END
