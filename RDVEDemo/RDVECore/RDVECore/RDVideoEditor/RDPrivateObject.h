//
//  RDPrivateObject.h
//  RDVECore
//
//  Created by apple on 2018/9/11.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDScene.h"
#include "RDVector.h"

@interface VVAssetAnimatePosition (Private)
@property (nonatomic, strong) NSMutableArray* _Nullable lookupTable;
- (void) generate;
- (CGPoint) calculateWithTimeValue:(float) v;
@end

@interface RDCaptionCustomAnimate (Private)

@property (nonatomic, strong) NSMutableArray* _Nullable lookupTable;
- (void) generate;
- (CGPoint) calculateWithTimeValue:(float) v;

@end

@interface RDScene (Private) //隐藏实现

@property (nonatomic,assign) CMTimeRange fixedTimeRange;

@property (nonatomic,assign) CMTimeRange passThroughTimeRange;

// 在场景中添加Mask属性

@end

@interface RDMusic (Private)
@property (nonatomic,strong) AVAudioMixInputParameters* _Nullable mixParameter;
@end


@interface VVAsset (Private)
@property (nonatomic,assign) CGAffineTransform  transform;
@property (nonatomic,strong) AVCompositionTrack* _Nullable assetCompositionTrack;
@property (nonatomic,assign) CGSize natureSize;

@property (nonatomic,strong) AVAudioMixInputParameters* _Nullable mixParameter;
// 在资源中加Mask属性
/*
 *  轨道ID
 */
@property (nonatomic,strong) NSNumber* _Nullable trackID;
@property (nonatomic,assign) float last;
@property (nonatomic,assign) BOOL hasAudio;
@property (nonatomic,assign) NSInteger trackIndex;
@end

@interface VVMovieEffect (Private)

@property (nonatomic,strong) NSNumber* _Nullable trackID;

@end

