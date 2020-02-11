//
//  RDDyRecordViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/6/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDDyRecordViewController : UIViewController

@property (nonatomic, copy) void (^recordCompletionBlock)(NSString *outputPath);

@property (nonatomic, copy) void (^cancelBlock)(BOOL isEnterAlbum, UIViewController *viewController);

@property (nonatomic, copy) void(^ shootPhotoCompletionBlock)(NSString* photoPath);

@end
