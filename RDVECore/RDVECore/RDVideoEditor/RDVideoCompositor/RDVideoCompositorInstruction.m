//
//  RDVideoCompositorInstruction.m
//  RDVECore
//
//  Created by 周晓林 on 2017/5/9.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDVideoCompositorInstruction.h"

@implementation RDVideoCompositorInstruction
@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange // 不执行compositor
{
    self = [super init];
    if (self) {
        _virtualVideoBgColor = [UIColor blackColor];
        _passthroughTrackID = passthroughTrackID;
        _requiredSourceTrackIDs = nil;
        _timeRange = timeRange;
        _containsTweening = FALSE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}

- (id)initTransitionWithSourceTrackIDs:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange  // 执行compositor
{
    self = [super init];
    if (self) {
        _virtualVideoBgColor = [UIColor blackColor];
        _requiredSourceTrackIDs = sourceTrackIDs;
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _timeRange = timeRange;
        _containsTweening = TRUE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}

- (void)setLottieView:(RDLOTAnimationView *)lottieView {
    _lottieView = lottieView;
    _lottieViewLayer = lottieView.layer;
}

- (void)refreshTimeRange:(CMTimeRange)timeRange {
    _timeRange = timeRange;
}

@end
