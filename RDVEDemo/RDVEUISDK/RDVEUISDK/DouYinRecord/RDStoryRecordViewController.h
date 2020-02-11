//
//  RDStoryRecordViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/5/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RDStoryRecordViewController : UIViewController

@property (nonatomic, copy) void (^recordCompletionBlock)(NSString *outputPath);

@property (nonatomic, copy) void (^cancelBlock)(BOOL isEnterAlbum, UIViewController *viewController);

@property (nonatomic, copy) void(^ shootPhotoCompletionBlock)(NSString* photoPath);

@end
