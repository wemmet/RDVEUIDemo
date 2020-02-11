//
//  RDCollageViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/7/12.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDCollageViewController : UIViewController

@property (nonatomic, strong) RDFile *file;

@property (nonatomic, copy) NSString *outputPath;

@property (nonatomic, assign) CGSize exportSize;

@end

NS_ASSUME_NONNULL_END
