//
//  RDEditorObject.h
//  RDVECore
//
//  Created by 周晓林 on 2017/8/1.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDScene.h"
@interface RDEditorObject : NSObject
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableAudioMix   *audioMix;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) int fps;
@property (nonatomic, strong) NSMutableArray<RDScene*>* scenes;
@property (nonatomic, strong) NSMutableArray<RDMusic *>* musics;
@property (nonatomic, strong) NSMutableArray<RDMusic *>* dubbingMusics;
@property (nonatomic, strong) NSMutableArray<RDMusic *>* animationVideoMusics;//20180816 使用lottie时，添加视频的音频
@property (nonatomic, strong) NSMutableArray<RDMusic *>* animationBGMusics;//20180930 使用lottie时，添加的背景资源的配乐
@property (nonatomic, strong) NSMutableArray<VVMovieEffect *>* movieEffects;
@property (nonatomic, strong) NSMutableArray<RDWatermark *>* watermarks;
/** 虚拟视频的自定义滤镜
 */
@property (nonatomic, strong) NSMutableArray <RDCustomFilter*>* customFilterArray;

@property (nonatomic,strong) VVMovieEffect* movieEffect;
@property (nonatomic,assign) float totalTime;

- (void) build;
- (AVPlayerItem *) playerItem;
- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;
- (CMTimeRange) passThroughTimeRangeAtIndex:(int) index;
- (CMTimeRange) transitionTimeRangeAtIndex:(int) index;

@end
