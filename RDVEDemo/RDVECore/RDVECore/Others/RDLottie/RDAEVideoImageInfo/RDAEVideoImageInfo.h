//
//  RDAEVideoImageInfo.h
//  RDVECore
//
//  Created by apple on 2019/3/4.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import "RDScene.h"

@interface RDAEScreenshotInfo : NSObject

@property (nonatomic, assign) CMTime screenshotTime;

@property (nonatomic, assign) CGImageRef screenshot;
@property (nonatomic, strong) UIImage *screenshotImage;

@end

@interface RDAEVideoImageInfo : NSObject

@property (nonatomic, strong) NSString *imageName;

@property (nonatomic, assign) float startTime;

@property (nonatomic, assign) float duration;

@property (nonatomic ,assign) CGRect crop;

@property (nonatomic ,assign) CMTimeRange timeRange;

@property (nonatomic ,assign) CMTimeRange actualTimeRange;

@property (nonatomic ,assign) CGSize size;

@property (nonatomic,strong) NSURL*  url;

@property (nonatomic,strong) UIImage *gifImage;

@property (nonatomic, strong) NSMutableArray *gifDurationArray;

/** 滤镜类型
 */
@property (nonatomic , assign) VVAssetFilter filterType;

/**滤镜资源地址
 */
@property (nonatomic , strong)  NSURL*   filterUrl;

@property (nonatomic, strong) NSMutableArray <RDAEScreenshotInfo*>*screenshotArray;

@end
