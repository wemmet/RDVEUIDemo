//
//  RDDraftCaption.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDScene.h"
#import "CaptionRangeView.h"

@interface RDDraftCaptionAnimate : RDDraftDataModel

@property (nonatomic, strong) RDCaptionAnimate *animate;

/**是否淡入淡出，默认YES
 */
@property (nonatomic, assign) BOOL isFade;

/**淡入时长，默认为1.0
 */
@property (nonatomic, assign) float fadeInDuration;

/**淡出时长，默认为1.0
 */
@property (nonatomic, assign) float fadeOutDuration;

/**动画类型
 */
@property (nonatomic, assign) RDCaptionAnimateType type;

/**动画进入时展示时长，默认为2.0
 */
@property (nonatomic, assign) float inDuration;

/**动画消失时展示时长，默认为2.0
 */
@property (nonatomic, assign) float outDuration;

/**推入点，动画类型为RDCaptionAnimateTypeMove时有效(CGPointMake(0, 0)〜CGPointMake(1, 1))。默认为CGPointZero
 * 以字幕center为基准，相对于实际视频size的移动Point
 */
@property (nonatomic, assign) CGPoint pushInPoint;

/**推出点，动画类型为RDCaptionAnimateTypeMove时有效(CGPointMake(0, 0)〜CGPointMake(1, 1))。默认为CGPointZero
 * 以字幕center为基准，相对于实际视频size的移动Point
 */
@property (nonatomic, assign) CGPoint pushOutPoint;

/**动画类型为RDCaptionAnimateTypeScaleInOut时有效，设置进入时的放大/缩小倍数(0.0~1.0)。
 * 默认为0.0。效果为进入时，字幕从0.5倍，在duration内逐渐放大到scaleOut倍。
 */
@property (nonatomic, assign) float scaleIn;

/**动画类型为RDCaptionAnimateTypeScaleInOut时有效，设置消失时的放大/缩小倍数(0.0~1.0)。
 * 默认为1.0。效果为消失时，字幕从1.0倍，在duration内逐渐缩小到scaleIn倍再消失。
 */
@property (nonatomic, assign) float scaleOut;

- (RDCaptionAnimate *)getAnimate;

@end

@protocol RDDraftCaptionAnimate <NSObject>

@end

@interface RDDraftMusic : RDDraftDataModel

@property (nonatomic, strong) RDMusic *music;

/** 标识符
 */
@property (nonatomic,strong) NSString*  identifier;

/**使用音乐地址
 */
@property (nonatomic, strong) NSURL *  url;

/**音乐在整个视频中的时间范围，默认为整个视频的TimeRange
 */
@property (nonatomic, assign) CMTimeRange effectiveTimeRange;

/**音乐截取时间范围
 */
@property (nonatomic, assign) CMTimeRange clipTimeRange;

/**音乐名称
 */
@property (nonatomic, strong) NSString * name;

/**音量(0.0-1.0)，默认为1.0
 */
@property (nonatomic, assign) float volume;

/**是否重复播放，默认为YES
 */
@property (nonatomic, assign) BOOL isRepeat;

/**配乐是否淡入淡出，默认为NO
 */
@property (nonatomic, assign) BOOL isFadeInOut;

/**配乐开头淡入淡出时长，默认为2.0秒
 */
@property (nonatomic, assign) float headFadeDuration;

/**配乐结尾淡入淡出时长，默认为2.0秒
 */
@property (nonatomic, assign) float endFadeDuration;

/** 音乐滤镜
 */
@property (nonatomic, assign) RDAudioFilterType audioFilterType;

- (RDMusic *)getMusic;

@end

@protocol RDDraftMusic <NSObject>

@end

@interface RDDraftMovieEffect : RDDraftDataModel

@property (nonatomic, strong) VVMovieEffect *movieEffect;

/** MV路径
 */
@property (nonatomic,strong) NSURL*  url;

/** MV显示时长
 */
@property (nonatomic,assign) CMTimeRange timeRange;

/** MV类型
 */
@property (nonatomic,assign) RDVideoMVEffectType type;
/** MV显示透明度
 */
@property (nonatomic,assign) float alpha;
/** 是否循环播放。默认为YES
 */
@property(readwrite, nonatomic) BOOL shouldRepeat;

- (VVMovieEffect *)geMovieEffect;

@end

@protocol RDDraftMovieEffect <NSObject>

@end
