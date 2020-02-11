//
//  RDTrimVideoViewController.h
//  RDVEUISDK
//
//  Created by emmet on 2017/6/29.
//  Copyright © 2017年 com.rd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

//裁剪为原始比例时，cropRect为CGRectMake(0, 0, 1, 1)
typedef void (^RdVE_TrimACallbackBlock)(RDCutVideoReturnType cutType,AVURLAsset *asset,CMTime startTime,CMTime endTime, CGRect cropRect);
typedef void (^RdVE_TrimPCallbackBlock)(RDCutVideoReturnType cutType,NSString * videoPath,CMTime startTime,CMTime endTime, CGRect cropRect);

typedef void(^RD_selectAndTrimFinishAction) (RDFile *videoFile);
//设置界面相关----------------------------------------
typedef void(^RD_CutVideoFinishAction) (RDFile *trimFile);
//----------------------------------------------------------------

@interface RDTrimVideoViewController : UIViewController
/**滤镜
 */
@property (nonatomic, strong) NSMutableArray  *globalFilters;

/**需要截取的视频文件
 */
@property(nonatomic,strong)RDFile           *trimFile;
/**视频预览尺寸
 */
@property (nonatomic, assign ) CGSize       editVideoSize;
/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;
/**是否显示裁切框，默认NO(不显示)
 */
@property(nonatomic,assign)BOOL             isShowClipView;
/**最大裁切尺寸
 */
@property (nonatomic, assign ) CGSize       maxCropSize;
/**截取视频完成
 */
@property(nonatomic,strong) void(^TrimVideoFinishBlock)(CMTimeRange timerange);
/**截取及裁切视频完成
 */
@property(nonatomic,strong) void(^TrimAndCropVideoFinishBlock)(NSURL *url, CGRect crop,CGRect cropRect,CMTimeRange timeRange, float volume);
/**截取及裁切视频  滤镜添加 完成
 */
@property(nonatomic,strong) void(^TrimAndCropVideoFinishFiltersBlock)(NSURL *url, CGRect crop,CGRect cropRect,CMTimeRange timeRange, float volume,NSInteger filterIndex);

/**截取及旋转视频完成
 */
@property(nonatomic,strong) void(^TrimAndRotateVideoFinishBlock)(float rotate,CMTimeRange timeRange);


//设置界面相关----------------------------------------
@property (nonatomic,strong) NSString   *customTitle;
@property (nonatomic,strong) UIColor    *customBackgroundColor;
@property (nonatomic,strong) UIColor    *cancelButtonBackgroundColor;
@property (nonatomic,strong) UIColor    *otherButtonBackgroundColor;
@property (nonatomic,strong) UIColor    *cancelButtonTitleColor;
@property (nonatomic,strong) UIColor    *otherButtonTitleColor;
@property (nonatomic,strong) NSString   *cancelButtonTitle;
@property (nonatomic,strong) NSString   *otherButtonTitle;

//单独进入截取视频时调用下面几个回调函数
@property (nonatomic,strong) AVURLAsset *trimVideoAsset;
@property (nonatomic,copy) NSString     *outputFilePath;

@property (nonatomic,assign) RDCutVideoReturnType    cutType;

@property(nonatomic, copy) void (^rd_CutVideoReturnType)(RDCutVideoReturnType*);

@property (nonatomic, assign) TRIMMODE                  trimType;

/** 单个定长截取：时间 默认15s
 */
@property (nonatomic,assign) float trimDuration_OneSpecifyTime;

/** 两个定长截取：偏小截取时间 默认12s
 */
@property (nonatomic,assign) float trimMinDuration_TwoSpecifyTime;

/** 两个定长截取：偏大截取时间 默认30s
 */
@property (nonatomic,assign) float trimMaxDuration_TwoSpecifyTime;

@property (nonatomic,assign) RDdefaultSelectCutMinOrMax  defaultSelectMinOrMax;

/** 定长截取时，截取后视频分辨率类型 默认TRIMVIDEOTYPE_ORIGINAL
 *  自由截取时，始终为TRIMVIDEOTYPE_ORIGINAL，该设置无效
 */
@property (nonatomic,assign) TRIMEXPORTVIDEOTYPE trimExportVideoType;

@property (nonatomic,copy) RdVE_TrimPCallbackBlock       callbackBlock;
@property (nonatomic,copy) RdVE_TrimACallbackBlock   trimCallbackBlock;
@property (nonatomic,copy) RdVEFailBlock            failback;
@property (nonatomic,copy) RdVECancelBlock          cancelBlock;


@property (nonatomic,copy) RD_CutVideoFinishAction cutVideoFinishAction;
/**多媒体时，视频在video中的大小
 */
@property(nonatomic, assign) CGSize         videoInViewSize;    //20170912 画中画
@property (nonatomic, copy) RD_selectAndTrimFinishAction    selectAndTrimFinishBlock;   //20170912 画中画

/**可旋转
 */
@property (nonatomic, assign) BOOL isRotateEnable;

/**可调节音量
 */
@property (nonatomic, assign) BOOL isAdjustVolumeEnable;

- (void)changeCutVideoReturnType:(RDCutVideoReturnType )type;
//----------------------------------------------------------------

-(void)setVideoCoreSDK:(RDVECore *) core;
-(void)seekTime:(CMTime) time;
@end
