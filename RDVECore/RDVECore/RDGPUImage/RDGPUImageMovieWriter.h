#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDGPUImageContext.h"

extern NSString *const kRDGPUImageColorSwizzlingFragmentShaderString;

@protocol RDGPUImageMovieWriterDelegate <NSObject>

@optional
- (void)movieRecordingCompleted;
- (void)movieRecordingFailedWithError:(NSError*)error;
- (void)movieRecordingCancelType:(int)type; // 0 完整性判断失败 1 assetwriter.status==2
- (void)movieRecordingBegin;
@end

@interface RDGPUImageMovieWriter : NSObject <RDGPUImageInput>
{
    BOOL alreadyFinishedRecording;
    
    NSURL *movieURL;
    NSString *fileType;
	AVAssetWriter *assetWriter;
	AVAssetWriterInput *assetWriterAudioInput;
	AVAssetWriterInput *assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
    
    RDGPUImageContext *_movieWriterContext;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;

    CGSize videoSize;
    RDGPUImageRotationMode inputRotation;
}

@property(readwrite, nonatomic) BOOL hasAudioTrack;
@property(readwrite, nonatomic) BOOL shouldPassthroughAudio;
@property(readwrite, nonatomic) BOOL shouldInvalidateAudioSampleWhenDone;
@property(nonatomic, copy) void(^completionBlock)(void);
@property(nonatomic, copy) void(^failureBlock)(NSError*);
@property(nonatomic, assign) id<RDGPUImageMovieWriterDelegate> delegate;
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
@property(nonatomic, retain) RDGPUImageContext *movieWriterContext;
@property(nonatomic, assign) BOOL isRecording;

// Initialization and teardown
- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSDictionary *)outputSettings;

- (void)setHasAudioTrack:(BOOL)hasAudioTrack audioSettings:(NSDictionary *)audioOutputSettings;

// Movie recording
- (void)startRecording;
- (void)startRecordingInOrientation:(CGAffineTransform)orientationTransform;
- (void)finishRecording;
- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
- (void)cancelRecording;
- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
- (void)enableSynchronizationCallbacks;

@end
