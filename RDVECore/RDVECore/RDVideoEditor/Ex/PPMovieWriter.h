
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDGPUImageContext.h"

extern NSString *const kPPColorSwizzlingFragmentShaderString;

@protocol PPMovieWriterDelegate <NSObject>

@optional
- (void)movieRecordingCompleted;
- (void)movieRecordingFailedWithError:(NSError*)error;
- (void)movieRecordingProgress:(float)progressvalue;

@end

@interface PPMovieWriter: NSObject <RDGPUImageInput>
{
    BOOL allowAlready;
    BOOL alreadyFinishedRecording;
    NSURL *movieURL;
    NSString *fileType;
	AVAssetWriter *assetWriter;
	AVAssetWriterInput *assetWriterAudioInput;
	AVAssetWriterInput *assetWriterVideoInput;

    
    RDGPUImageContext *_movieWriterContext;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;

    CGSize videoSize;
    RDGPUImageRotationMode inputRotation;
}
//@property (nonatomic,assign)long int   videoMaxDuration;
@property (nonatomic,assign)float   videoMaxDuration;
@property(nonatomic, strong) NSArray *movies;
@property(readwrite, nonatomic) BOOL hasAudioTrack;
@property(readwrite, nonatomic) BOOL cancelReading;
@property(readwrite, nonatomic) BOOL pauseReading;
@property(readwrite, nonatomic) BOOL shouldPassthroughAudio;
@property(readwrite, nonatomic) BOOL shouldInvalidateAudioSampleWhenDone;
@property(nonatomic, copy) void(^completionBlock)(void);
@property(nonatomic, copy) void(^failureBlock)(NSError*);
@property(nonatomic, weak) id<PPMovieWriterDelegate> delegate;
@property(readwrite, nonatomic) BOOL encodingLiveVideo;
@property(nonatomic, copy) BOOL(^videoInputReadyCallback)(void);
@property(nonatomic, copy) BOOL(^audioInputReadyCallback)(void);
@property(nonatomic, copy) void(^audioProcessingCallback)(SInt16 **samplesRef, CMItemCount numSamplesInBuffer);
@property(nonatomic) BOOL enabled;
@property(nonatomic, readonly) AVAssetWriter *assetWriter;
@property(nonatomic, readonly) CMTime duration;
@property(nonatomic, assign) CGAffineTransform transform;
@property(nonatomic, copy) NSArray *metaData;
@property(nonatomic, assign, getter = isPaused) BOOL paused;
@property(nonatomic, strong) RDGPUImageContext *movieWriterContext;
@property(nonatomic, assign) CMTime currentVideoSampleTime;
@property(nonatomic, assign) CMTime currentAudioSampleTime;
// Initialization and teardown
- (id)initWithMovieURL:(NSURL *)newMovieURL
                  size:(CGSize)newSize
                movies:(NSArray *)movies
              metadata:(NSArray<AVMetadataItem*> *)metadata
      videoMaxDuration:(float) videoMaxDuration
   videoAverageBitRate:(float)videoAverageBitRate
          audioBitRate:(int)audioBitRate
   audioChannelNumbers:(int)audioChannelNumbers
         totalDuration:(float)totalDuration
              progress:(void(^)(NSNumber* percent))progress;

- (id)initWithMovieURL:(NSURL *)newMovieURL
                  size:(CGSize)newSize
              fileType:(NSString *)newFileType
        outputSettings:(NSDictionary *)outputSettings
                movies:(NSArray *)movies
              metadata:(NSArray *)metadata;

- (void)setHasAudioTrack:(BOOL)hasAudioTrack audioSettings:(NSDictionary *)audioOutputSettings;

// Movie recording
- (void)startRecording;
- (void)startRecordingInOrientation:(CGAffineTransform)orientationTransform;
- (void)finishRecording;
- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
- (void)cancelRecording;
- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
- (void)enableSynchronizationCallbacks;
- (void)releasecanshu;
//===
@property(nonatomic) CGFloat audioWroteDuration, videoWroteDuration;
@property(nonatomic) CGFloat firstVideoFrameTime;

@property(nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;

@end
