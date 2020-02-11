//
//  RDRangeViewFile.h
//  dyUIAPIDemo
//
//  Created by wuxiaoxia on 2017/5/11.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
typedef NS_ENUM(NSInteger,EffectType) {
    kFilterEffect,
    kTimeEffect,
};
@interface RDRangeViewFile : NSObject

@property (nonatomic, assign) EffectType effectType;
@property (nonatomic, assign) Float64 start;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, assign) NSInteger typeIndex;
@property (nonatomic, assign) int fxId;
@property (nonatomic, strong) NSString *name;
/**当前帧图片地址
 */
@property(strong,nonatomic)NSString *currentFrameTexturePath;
@end
