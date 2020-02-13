//
//  RDVideoRecordGPUImageMovieWriter.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import "RDGPUImageMovieWriter.h"

@interface RDVideoRecordGPUImageMovieWriter : RDGPUImageMovieWriter
@property (nonatomic,assign) BOOL started;
@property (readwrite) int32_t maxFrames; // 计算进度
- (void) startRecording;
- (void) pauseRecording;
- (void) resumeRecording;
- (void) finishRecording;
- (void) finishRecordingWithCompletionHandler:(void (^)(void))handler;
- (float) getProgress;
@end
