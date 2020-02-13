//
//  RDEditorObject.m
//  RDVECore
//
//  Created by 周晓林 on 2017/8/1.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDEditorObject.h"

@implementation RDEditorObject
- (CMTimeRange)passThroughTimeRangeAtIndex:(int)index{
    return kCMTimeRangeZero;
}
- (CMTimeRange)transitionTimeRangeAtIndex:(int)index{
    return kCMTimeRangeZero;
}
- (void)build{
    [self doesNotRecognizeSelector:_cmd];
}

- (AVPlayerItem *)playerItem{
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:_composition];
    playerItem.videoComposition = _videoComposition;
    playerItem.audioMix = _audioMix;
    return playerItem;
}

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName
{
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:presetName];
    session.videoComposition = self.videoComposition;
    session.audioMix = self.audioMix;
    return session;
}

@end
