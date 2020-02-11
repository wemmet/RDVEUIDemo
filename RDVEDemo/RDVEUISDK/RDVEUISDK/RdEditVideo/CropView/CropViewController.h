//
//  CropViewController.h
//  RDVEUISDK
//
//  Created by emmet on 15/8/21.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

#import "RDUICliper.h"
#import <UIKit/UIKit.h>
#import "RDThumbImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "RDVECore.h"
/** 完成单个视频编辑的回调
 */

@interface CropViewController : UIViewController
/**滤镜
 */
@property (nonatomic, strong) NSMutableArray  *globalFilters;
/**需要分割的文件
 */

@property (nonatomic, strong ) RDFile        *selectFile;
/**视频预览尺寸
 */
@property (nonatomic, assign ) CGSize        editVideoSize;
/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;
/**多媒体时，视频在video中的大小
 */
@property(nonatomic, assign) CGSize         videoInViewSize;    //20170912 画中画

/**仅裁剪，不旋转等
 */
@property (nonatomic, assign) BOOL isOnlyCrop;

/**仅旋转
 */
@property (nonatomic, assign) BOOL isOnlyRotate;
/**模态跳转
 */
@property (nonatomic, assign) BOOL presentModel;

@property (nonatomic,copy) void (^editVideoForOnceFinishAction)(CGRect crop,CGRect cropRect,BOOL verticalMirror,BOOL horizontalMirror,float rotation, FileCropModeType cropmodeType);

/**AE图片素材编辑
 */
@property (nonatomic,copy) void (^editVideoForOnceFinishFiltersAction)(CGRect crop,
CGRect cropRect,
BOOL verticalMirror,
BOOL horizontalMirror,
float rotation,
FileCropModeType cropmodeType,
NSInteger filterIndex
);


-(void)setVideoCoreSDK:(RDVECore *) core;
-(void)seekTime:(CMTime) time;
@end

