//
//  RDPlayer.h
//  RDVEUISDK
//
//  Created by emmet on 2018/8/15.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class RDPlayer;
@protocol RDPlayerDelegate <NSObject>

- (void)tapPlayer;
- (void)playCurrentTime:(CMTime) currentTime;
- (void)playerItemDidReachEnd:( RDPlayer * _Nullable) player;

@end


@interface RDPlayer : UIView
/**播放状态
 */
@property (nonatomic,readonly) BOOL isplaying;
/**静音
 */
@property (nonatomic,assign) BOOL mute;
/**重复播放
 */
@property (nonatomic,assign) BOOL repeat;
/**只缓存不播放
 */
@property (nonatomic,assign) BOOL onlyCache;
/**缓存进度条显示距离底端的高度
 */
@property (nonatomic, assign) float lineToBottomHeight;
/**当前播放时间
 */
@property (nonatomic,readonly) CMTime currentTime;
/**视频总时间
 */
@property (nonatomic,readonly) float duration;

/**
 初始化方法

 @param frame frame
 @param urlPath 下载路径

 */
- (instancetype)initWithFrame:(CGRect)frame
                      urlPath:(NSString *)urlPath
                     delegate:(id)delegate
            completionHandler:(void (^)(NSError *error))handler;

- (instancetype)initWithFrame:(CGRect)frame
                      urlPath:(NSString *)urlPath
                wh_Proportion:(float)proportion
                     delegate:(id)delegate
            completionHandler:(void (^)(NSError *error))handler;

- (instancetype)initWithFrame:(CGRect)frame
                      urlPath:(NSString *)urlPath
                wh_Proportion:(float)proportion
                  progressSup:(UIView *)progressSup
                     delegate:(id)delegate
            completionHandler:( void (^)(NSError *error))handler;

- (void)seekToTime:(CMTime)time toleranceTime:(CMTime)tolerance completionHandler:(void (^)(BOOL finished))completionHandler;
//播放
- (void)play;

//暂停
- (void)pause;

- (void)stop;

- (void)setPlayerFrame:(CGRect)frame;

- (void)setUrlPath:(NSString *)urlPath
 completionHandler:( void (^)(NSError *error))handler;

@end
