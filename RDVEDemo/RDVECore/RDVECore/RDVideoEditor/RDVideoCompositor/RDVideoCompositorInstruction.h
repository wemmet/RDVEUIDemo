//
//  RDVideoCompositorInstruction.h
//  RDVECore
//
//  Created by 周晓林 on 2017/5/9.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDPrivateObject.h"
#import "RDLottie.h"

typedef NS_ENUM(NSUInteger,RDCustomType) {
    RDCustomTypePassThrough,
    RDCustomTypeTransition
};

@interface RDVideoCompositorInstruction : NSObject<AVVideoCompositionInstruction>

@property (nonatomic,assign) RDCustomType        customType;

/** 虚拟视频背景色
 */
@property (nonatomic,strong) UIColor *virtualVideoBgColor;

@property (nonatomic,strong) RDScene*               scene;

@property (nonatomic,strong) RDScene*               previosScene;

@property (nonatomic,strong) RDScene*               nextScene;

@property (nonatomic,strong) NSMutableArray<VVMovieEffect*>*  mvEffects;

@property (nonatomic,strong) NSMutableArray<RDWatermark*>*  watermarks;

/** 虚拟视频的自定义滤镜
 */
@property (nonatomic, strong) NSMutableArray <RDCustomFilter*>* customFilterArray;
@property (nonatomic,assign) BOOL isExporting;
@property (nonatomic, weak) RDLOTAnimationView *lottieView;
@property (nonatomic, weak) CALayer *lottieViewLayer;

- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange;
- (id)initTransitionWithSourceTrackIDs:(NSArray*)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange;
- (void)refreshTimeRange:(CMTimeRange)timeRange;

@end
