#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDGPUImageContext.h"
#import "RDGPUImageOutput.h"
#import "PPMovieWriter.h"
#import "RDTPCircularBuffer.h"
#import "RDGPUImageMovieWriter.h"
//应当改造
typedef void(^SyncToTimeDone)(void);
@class PPMovie;
@protocol PPMovieDelegate <NSObject>
@optional
- (BOOL)progressCurrentTime:(CMTime )currentTime filter:(NSString *)filterName ppMovie:(PPMovie *)ppMove;

- (void)playerToEnd:(id)ppmovie;

//- (void)didCompletePlayingMovie;
- (void)refreshVAAnimationLayerIndex:(CMTime)time;

- (void)seektimesyncBlock;
- (void)syncToTimeDone;
@end
@interface PPMovie : RDGPUImageOutput
@property (nonatomic, assign) BOOL isCall;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, assign) BOOL isMVEffect;

@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, copy) NSURL *url;

//@property (nonatomic, strong) AVAssetReader *reader;

@property (readwrite, copy) NSString *filterName;

@property (readwrite, nonatomic) BOOL runBenchmark;

@property (readwrite, nonatomic) BOOL playAtActualSpeed;

@property (readwrite, nonatomic) BOOL shouldRepeat;

@property (readonly, nonatomic) float progress;

@property (readwrite, nonatomic, weak) id <PPMovieDelegate>delegate;
//@property (nonatomic, strong)           SyncToTimeDone  syncToTimeDone;

//@property (readonly, nonatomic) AVAssetReader *assetReader;

@property (readonly, nonatomic) BOOL audioEncodingIsFinished;

@property (readonly, nonatomic)  BOOL videoEncodingIsFinished;
@property (readwrite, nonatomic) BOOL videoCopyNextSampleBufferFinish;
@property (readonly, nonatomic)CMTime                     exportcurrentTime;
@property (assign  , nonatomic) BOOL forPlayback;


/**
* 是否有音频可以播放视频
*/
@property (assign  , nonatomic) BOOL  bAudio;
@property (assign  , nonatomic) BOOL  allowEnter;
@property(readwrite, nonatomic) Float64 currentVideoSampleTime;

@property(readwrite, nonatomic) Float64 currentAudioSampleTime;

@property(readwrite, nonatomic) BOOL    audioFull;
//@property(readwrite, nonatomic) BOOL    seekDone;

@property(readwrite, nonatomic) AudioBuffer aBuffer;
@property(assign   , nonatomic) int audioChannelNumbers;

//@property (nonatomic) TPCircularBuffer tpCircularBuffer;

@property (nonatomic, assign) CMTimeRange cutTimeRange;

/// @name Initialization and teardown
- (id)initWithAsset:(AVAsset *)asset;

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;

- (id)initWithURL:(NSURL *)url;

- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix;

- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix audioSampleRate:(NSInteger)audioSampleRate;

- (void)yuvConversionSetup;

- (void)enableSynchronizedEncodingUsingMovieWriter:(RDGPUImageMovieWriter *)movieWriter;

- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerVideoTrackOutput;

- (BOOL)readNextAudioSampleFromOutput:(AVAssetReaderOutput *)readerAudioTrackOutput;

- (void)startProcessing;

- (void)endProcessing;

- (void)cancelProcessing;

- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer;

- (BOOL)renderNextFrame;

@property (nonatomic, assign) Float64   audioSampleRate;
@property (nonatomic, strong) AVComposition *compositon;

@property (nonatomic, nonatomic) AVVideoComposition *videoComposition;

@property (nonatomic, strong) AVAudioMix *audioMix;

- (void)refresh;

- (void)preparePlayer;

- (BOOL)playWithTime:(CMTime )time;

- (BOOL) play;

- (BOOL) pause;

- (CMTime)currentTime;

- (void)seekToTime:(CMTime)time;

- (void)seekToTime:(CMTime)time sync:(BOOL)isSync;

- (void)seekToTime:(CMTime)time sync:(BOOL)isSync callback:(void(^)(void))callbackBlock;

- (void)audioClearUp;

@end
