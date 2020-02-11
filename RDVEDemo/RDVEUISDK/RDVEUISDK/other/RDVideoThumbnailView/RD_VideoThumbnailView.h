//
//  RD_VideoThumbnailView.h
//  dyUIAPI
//
//  Created by emmet on 2017/5/26.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDRangeView.h"

@protocol RD_VideoThumbnailViewDelegate <NSObject>
@optional

- (void)timeEffectChangeBegin:(CMTimeRange)timerange;
- (void)timeEffectChanging:(NSInteger)type timeRange:(CMTimeRange)timeRange ;
- (void)timeEffectchanged:(NSInteger)type timeRange:(CMTimeRange)timeRange;
@end
typedef NS_ENUM(NSInteger, TimeEffectType) {
    TimeEffectTypeNone = 0,
    TimeEffectTypeSlow,
    TimeEffectTypeRepeat,
    TimeEffectTypeReverse
};
@interface RD_VideoThumbnailView : UIView
{
    
    NSMutableArray <RDRangeView *>*_filterEffectList;//滤镜特效
    NSMutableArray <RDRangeView *>*_timeEffectList;//时间特效
}

/**是否透明
 */
@property(nonatomic,assign)bool         isApla;

@property(nonatomic,weak)id<RD_VideoThumbnailViewDelegate> delegate;


/**缩率图比例 （width/height）
 */
@property(nonatomic,assign)float    thumbnailProportion;

/**特效类型 -->滤镜特效还是时间特效
 */
@property(nonatomic,assign)EffectType   effectType;

/**当前进度
 */
@property(nonatomic,assign)float        progress;

/**视频开始时间
 */
@property(nonatomic,assign)float        startTime;

/**视频总时长
 */
@property(nonatomic,assign)float        duration;

/**截取视频缩率图的时间
 */
@property(nonatomic,readonly)NSMutableArray *thumbnailTimes;

/**截取视频缩率图的时间间隔
 */
@property(nonatomic,readonly)float durationPerFrame;

/**上下留空高度
 */
@property(nonatomic,assign)float    borderHeight;

/**进度条颜色
 */
@property(nonatomic,assign)UIColor  *trackColor;

/**进度条图片
 */
@property(nonatomic,strong)UIImage  *trackInImage;

/**进度条图片
 */
@property(nonatomic,strong)UIImage  *trackOutImage;

/**进度条图片
 */
@property(nonatomic,assign)BOOL      hasChangeEffect;


/**开始滑动进度条
 */
@property(nonatomic,copy) void(^trackMoveBegin)(float progress);

/**滑动进度条结束
 */
@property(nonatomic,copy) void(^trackMoving)(float progress);

/**滑动进度条结束
 */
@property(nonatomic,copy) void(^trackMoveEnd)(float progress);

/**添加特效
 * param: fxId 特效ID
 * param: color 进度块颜色
 * param: timeRange 特效时间段
 * param: currentFrameTexturePath 当前帧图片地址
 */
- (void)addFilterEffect:(int)fxId color:(UIColor *)color withTimeRange:(CMTimeRange)timeRange currentFrameTexturePath:(NSString *)currentFrameTexturePath;

/**添加时间特效
 * param: typeindex 特效ID
 * param: color 进度块颜色
 * param: timeRange 特效时间段
 */
- (void)addTimeEffect:(NSInteger)typeIndex color:(UIColor *)color withTimeRange:(CMTimeRange)timeRange;

/**获取时间特效的开始时间
 */
- (CMTimeRange)getTimeEffectTimeRange;

/**添加特效
 * param: fxId 特效ID
 * param: color 进度块颜色
 * param: time 特效开始时间
 */
- (void)addEffect:(int)fxId color:(UIColor *)color withTime:(float)time;
/**添加特效完成
 */
- (void)finishAddEffect;

/**改变最后一次添加的特效时间
 */
- (void)changeEffectWidth;

/**检测是否有特效
 */
- (BOOL)hasEffect;

/**撤销所有特效
 */
- (void)annulAllEffect;

/**撤销时间特效
 */
- (void)annulTimeEffect;

/**撤销最后一次添加的滤镜特效
 */
- (CMTime)annulLastFilterEffect;

/**保存添加的特效
 */
- (void)saveEffect;

/**刷新缩率图
 * param: index 第几张缩率图
 * param: thumbnail 缩率图
 */
- (void)refreshThumbImage:(NSInteger)index thumbImage:(UIImage *)thumbnail;

/**获取添加的滤镜特效
 */
- (NSArray<RDRangeView *> *)getFilterEffectList;

/**获取添加的时间特效
 */
- (NSArray<RDRangeView *> *)getTimeEffectList;


@end

@protocol RDTrackViewDelegate <NSObject>
@optional

- (void)touchesBegin;
- (void)touchesMoved;
- (void)touchesEnd;
@end

@interface RDTrackView : UIView
@property(nonatomic,weak)id<RDTrackViewDelegate> delegate;
@end
