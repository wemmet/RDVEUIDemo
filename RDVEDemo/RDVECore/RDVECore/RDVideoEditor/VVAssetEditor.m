//
//  VVAssetEditor.m
//  RDVECore
//
//  Created by 周晓林 on 2017/7/4.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "VVAssetEditor.h"
#import "RDVideoCompositor.h"
#import "RDVideoCompositorInstruction.h"
@interface VVAssetEditor()
{
    
}
@end
@implementation VVAssetEditor
- (instancetype)init{
    if (self = [super init]) {
        if (CGSizeEqualToSize(CGSizeZero, _videoSize)) {
            _videoSize = CGSizeMake(1280, 720);
        }
    }
    return self;
}
- (AVAsset *)asset{
    return _composition;
}
- (void) build
{
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.audioMix = [AVMutableAudioMix audioMix];
    
    
   
    self.videoComposition.customVideoCompositorClass = [RDVideoCompositor class];
    
    self.composition.naturalSize = self.videoSize;
    
    NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
    AVURLAsset *bgVideoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:bgVideoPath]];

    float maxTime = 0;
    for (int i = 0; i<_vAssetArray.count; i++) {
        VVAsset* vAsset = _vAssetArray[i];
        float time = vAsset.duration;
        if (time>= maxTime) {
            maxTime = time;
        }
    }
    
    NSMutableArray *instructions = [NSMutableArray array];
    NSMutableArray *inputParameterArray = [NSMutableArray array];
    NSMutableArray *compositionVideoTrackArray = [NSMutableArray array];
    
    for (int i = 0; i<_vAssetArray.count; i++) {
        VVAsset* vAsset = _vAssetArray[i];
        AVURLAsset * urlAsset;
        
        if (vAsset.type == RDAssetTypeImage) {
            urlAsset = bgVideoAsset;
        }else{
            urlAsset = [AVURLAsset assetWithURL:vAsset.url];
        }
        
        if ([[urlAsset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
            
            AVMutableCompositionTrack* compositionVideoTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            AVAssetTrack* clipVideoTrack = [[urlAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            CMTimeRange timeRangeInAsset = vAsset.timeRange;

            float clipVideoTime = vAsset.duration;
            float totalTime = maxTime;
            
            CMTime nextClipStartTime = kCMTimeZero;
            NSError* error;
            BOOL suc;
            
            while (clipVideoTime < totalTime) {
                
                suc = [compositionVideoTrack insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:&error];
                if (!suc) {
                    NSAssert(NO, @"video Index %d Error: %@",i,error.description);
                }
                CMTimeRange speedTimeRange = timeRangeInAsset;
                CMTime scaleTime = CMTimeMakeWithSeconds(clipVideoTime, TIMESCALE);
                speedTimeRange.start = nextClipStartTime;
                [compositionVideoTrack scaleTimeRange:speedTimeRange toDuration:scaleTime];
                
                
                nextClipStartTime = CMTimeAdd(nextClipStartTime, scaleTime);
                totalTime -= clipVideoTime;

            }
            
            {
                
                timeRangeInAsset = CMTimeRangeMake(vAsset.timeRange.start, CMTimeMakeWithSeconds(totalTime*vAsset.speed, TIMESCALE));
                
                suc = [compositionVideoTrack insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:&error];
                if (!suc) {
                    NSAssert(NO, @"video Index %d Error: %@",i,error.description);
                }
                CMTimeRange speedTimeRange = timeRangeInAsset;
                float speedValue = vAsset.speed;
                Float64 scaleDuration = CMTimeGetSeconds(speedTimeRange.duration)/speedValue;
                
                CMTime scaleTime = CMTimeMakeWithSeconds(scaleDuration, TIMESCALE);
                speedTimeRange.start = nextClipStartTime;
                [compositionVideoTrack scaleTimeRange:speedTimeRange toDuration:scaleTime];

            }
            
            [compositionVideoTrackArray addObject:[NSNumber numberWithInt:compositionVideoTrack.trackID]];
        }
        
        if ([[urlAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
            
            AVMutableCompositionTrack* compositionAudioTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            AVAssetTrack* clipVideoTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            CMTimeRange timeRangeInAsset = vAsset.timeRange;
            
            float clipVideoTime = vAsset.duration;
            float totalTime = maxTime;
            
            CMTime nextClipStartTime = kCMTimeZero;
            NSError* error;
            BOOL suc;
            
            while (clipVideoTime < totalTime) {
                
                suc = [compositionAudioTrack insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:&error];
                if (!suc) {
                    NSAssert(NO, @"video Index %d Error: %@",i,error.description);
                }
                CMTimeRange speedTimeRange = timeRangeInAsset;
                CMTime scaleTime = CMTimeMakeWithSeconds(clipVideoTime, TIMESCALE);
                speedTimeRange.start = nextClipStartTime;
                [compositionAudioTrack scaleTimeRange:speedTimeRange toDuration:scaleTime];
                
                
                nextClipStartTime = CMTimeAdd(nextClipStartTime, scaleTime);
                totalTime -= clipVideoTime;
                
            }
            
            {
                
                timeRangeInAsset = CMTimeRangeMake(vAsset.timeRange.start, CMTimeMakeWithSeconds(totalTime*vAsset.speed, TIMESCALE));
                
                suc = [compositionAudioTrack insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:&error];
                if (!suc) {
                    NSAssert(NO, @"video Index %d Error: %@",i,error.description);
                }
                CMTimeRange speedTimeRange = timeRangeInAsset;
                float speedValue = vAsset.speed;
                Float64 scaleDuration = CMTimeGetSeconds(speedTimeRange.duration)/speedValue;
                
                CMTime scaleTime = CMTimeMakeWithSeconds(scaleDuration, TIMESCALE);
                speedTimeRange.start = nextClipStartTime;
                [compositionAudioTrack scaleTimeRange:speedTimeRange toDuration:scaleTime];
                
            }

            AVMutableAudioMixInputParameters* mixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
            mixInputParameters.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmVarispeed;
            [mixInputParameters setVolumeRampFromStartVolume:vAsset.volume toEndVolume:vAsset.volume timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(totalTime, TIMESCALE))];
            [inputParameterArray addObject:mixInputParameters];
        }
        
    }
    
    
    RDVideoCompositorInstruction* instruction = [[RDVideoCompositorInstruction alloc] initTransitionWithSourceTrackIDs:compositionVideoTrackArray forTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(maxTime, TIMESCALE))];
    
    [instructions addObject:instruction];
    
    self.videoComposition.instructions = instructions;
    self.audioMix.inputParameters = inputParameterArray;
    self.videoComposition.frameDuration = CMTimeMake(1, self.fps);
    self.videoComposition.renderSize = self.videoSize;
    
}


@end
