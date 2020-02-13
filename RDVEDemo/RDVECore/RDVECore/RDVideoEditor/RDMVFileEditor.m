//
//  RDMVFileEditor.m
//  RDVECore
//  解析
//  Created by 周晓林 on 2017/8/1.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDMVFileEditor.h"
#import "RDVideoCompositor.h"
#import "RDVideoCompositorInstruction.h"

@implementation RDMVFileEditor
- (void) build{
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.audioMix = [AVMutableAudioMix audioMix];
    
    NSURL* mvURL = self.movieEffect.url;
    AVURLAsset* mvAsset = [AVURLAsset assetWithURL:mvURL];
    NSArray* mvTracks = [mvAsset tracksWithMediaType:AVMediaTypeVideo];

    
//    self.videoComposition.customVideoCompositorClass = [RDVideoCompositor class];
    AVAssetTrack *videoTrack = [mvTracks objectAtIndex:0];
    self.videoSize = videoTrack.naturalSize;
    if (CGSizeEqualToSize(self.videoSize, CGSizeZero) || self.videoSize.width == 0.0 || self.videoSize.height == 0.0) {
        NSArray * formatDescriptions = [videoTrack formatDescriptions];
        CMFormatDescriptionRef formatDescription = NULL;
        if ([formatDescriptions count] > 0) {
            formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
            if (formatDescription) {
                self.videoSize = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            }
        }
    }

    self.composition.naturalSize = self.videoSize;
    
    NSMutableArray *instructions = [NSMutableArray array];

    
   
    AVMutableCompositionTrack* compositionMVTrack;
    
    float mvAssetDuration = CMTimeGetSeconds(mvAsset.duration);
    if ([mvTracks count] > 0) {
        float totalTimeLocal = self.totalTime;
        compositionMVTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        float mvTime = CMTimeGetSeconds(mvAsset.duration);
        AVAssetTrack* mvTrack = [mvTracks objectAtIndex:0];
        CMTime beginTime = kCMTimeZero;
        while (mvTime < totalTimeLocal) {
            [compositionMVTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, mvAsset.duration) ofTrack:mvTrack atTime:beginTime error:nil];
            totalTimeLocal -= mvTime;
            beginTime = CMTimeAdd(beginTime, CMTimeMakeWithSeconds(mvAssetDuration, TIMESCALE));
        }
        [compositionMVTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(totalTimeLocal, TIMESCALE)) ofTrack:mvTrack atTime:beginTime error:nil];
        
        AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
        AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mvTrack];
//        CGAffineTransform t1 = CGAffineTransformMakeTranslation(-1*mvTrack.naturalSize.width/2, -1*mvTrack.naturalSize.height/2);
        CGAffineTransform t1 = mvTrack.preferredTransform;
        [layerInstruction setTransform:t1 atTime:kCMTimeZero];
        
        instruction.layerInstructions = @[layerInstruction];
        [instructions addObject:instruction];
    }
    
//    RDVideoCompositorInstruction* instruction = [[RDVideoCompositorInstruction alloc] initPassThroughTrackID:compositionMVTrack.trackID forTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(self.totalTime, TIMESCALE))];
   
//    [instructions addObject:instruction];
    
    self.videoComposition.instructions = instructions;
    self.videoComposition.frameDuration = CMTimeMake(1, self.fps);
    self.videoComposition.renderSize = self.videoSize;
    NSLog(@"MVEditor.fps:%d",self.fps);
    
}
- (void)dealloc{
    
    
    NSLog(@"dealloc");
}
@end
