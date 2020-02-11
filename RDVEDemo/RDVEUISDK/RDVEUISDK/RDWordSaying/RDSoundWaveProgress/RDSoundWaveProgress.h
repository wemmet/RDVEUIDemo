//
//  RDSoundWaveProgress.h
//  RDVEUISDK
//
//  Created by apple on 2019/7/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "decibelLine.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RDSoundWaveProgressDelegate<NSObject>

-(void)CurrentTime:(float) soundTime;

@end

@interface RDSoundWaveProgress : UIView

@property (nonatomic, strong) NSMutableArray<recordingSegment *> *decibelArray;       //记录音频分贝数

@property (nonatomic, assign) float minTime;    //最小时间
@property (nonatomic, assign) float maxTime;    //最大时间

@property (nonatomic, assign) float currentTime;//当前时间

@property(nullable,nonatomic,weak) id<RDSoundWaveProgressDelegate>        delegate;

@property (nonatomic, assign) int currentAudioDecibelNumber;//当前时间
@property (nonatomic, assign) int currentAudioFileNumber;   //当前音频文件编号

-(void)playProgress:(int) time;
-(void)refreshProgress;         //刷新声波
-(void)deleteRefresh;           //删除刷新声波
-(void)clearTime;

//锁定 不可拖动
- (void)lockMove;
//解锁 可拖动
- (void)unLockMove;

@end

NS_ASSUME_NONNULL_END
