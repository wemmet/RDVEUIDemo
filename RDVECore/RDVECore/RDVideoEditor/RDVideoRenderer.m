//
//  RDCompositorPlayer.m
//  RDVECore
//  这个类用来控制seek 解码 解码后的数据将通过代理送入RDGPUImageMovie
//  Created by 周晓林 on 2017/2/27.
//  Copyright © 2017年 xpkCoreSdk. All rights reserved.
//

#import "RDVideoRenderer.h"
#import "RDGPUImageMovie.h"
#import "RDGPUImageView.h"
#import "RDGPUImageFilter.h"

@interface RDVideoRenderer()<AVPlayerItemOutputPullDelegate>
{
    id          _timeObserver;
    BOOL        isBackground;
    BOOL        isPlaying;
    NSInteger   configPlayerItemOutputCounts;
    
    CMTime      preSeekTime;
    BOOL        isSeeking;
    BOOL        isCanPlay;
    BOOL        isPrepareFinishSeek;//20180606 wuxiaoxia 有的视频刚开始几帧读不出来，seek到CMTimeMake(2, originalFrameRate)才能播放，originalFrameRate为视频原帧率，为了统一改为600.且要在状态为AVPlayerItemStatusReadyToPlay时才能seek
    CMTime      refreshCurrentTime;
}
@property (nonatomic, strong) AVPlayer* player;
@property (nonatomic, strong) AVPlayerItem* playerItem;
@property AVPlayerItemVideoOutput *playerItemOutput;

@property CADisplayLink *displayLink;

@end
@implementation RDVideoRenderer

static NSString* const AVCustomEditPlayerViewControllerStatusObservationContext	= @"AVCustomEditPlayerViewControllerStatusObservationContext";
static NSString* const AVCustomEditPlayerViewControllerRateObservationContext = @"AVCustomEditPlayerViewControllerRateObservationContext";

- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    _playRate = 1.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:UIApplicationDidBecomeActiveNotification object:nil];

    return self;
}

- (void) notification: (NSNotification*) notification {
    if([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        isBackground = YES;
        if (isPlaying) {
            [_player pause];
            [_player seekToTime:CMTimeAdd(_player.currentTime, CMTimeMake(1, 600))];
        }
        
    }
    
    else if([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        
        isBackground = NO;

        if (isPlaying) {
            [_player seekToTime:CMTimeSubtract(_player.currentTime, CMTimeMake(1, 600))];
            [self play];
        }
    }
    
    else if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]){
        
        isBackground = NO;
        if (isPlaying) {
            [_player seekToTime:CMTimeSubtract(_player.currentTime, CMTimeMake(1, 600))];
            [self play];
        }
        
    }
}

- (void)setIsMute:(BOOL)isMute{
    _isMute = isMute;
    if(_isMute){
        _player.volume = 0.0;
    }else
        _player.volume = 1.0;
}


- (void) prepare
{
    NSLog(@"%s",__func__);
    isPlaying = NO;
    isPrepareFinishSeek = NO;
    isCanPlay = NO;
    preSeekTime = kCMTimeInvalid;
    [self clear];
    
    _player = [[AVPlayer alloc] init];
    [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(__bridge void*)(AVCustomEditPlayerViewControllerRateObservationContext)];
    
    if (_playDelegate && [_playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
        [_playDelegate statusChanged:self statues:kRenderStatusUnknown];
    }
    configPlayerItemOutputCounts = -1;
    [self synchronizePlayerWithEditor];
    isSeeking = NO;
}
- (CMTime)currentTime{
    return _player.currentTime;
}
- (float)rate{
    return _player.rate;
}

//20191126 大于2倍速的情况，画面会卡顿，所以调速还是用的build
//- (void)setPlayRate:(float)playRate {
//    _playRate = playRate;
//    isPlaying = YES;
//    isSeeking = NO;
//    [_player setRate:playRate];
//}

- (void)reverse:(CMTime)time{
    
    __weak typeof(self) myself = self;
    [_player seekToTime:time/*[[_player currentItem] duration]*/ toleranceBefore:kCMTimeZero toleranceAfter:kCMTimePositiveInfinity];
    [_player setRate:-1.0];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [myself.player setRate:1.0];
        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [myself.player setRate:-1.0];
        
    });
    
}

- (void)play{
    NSLog(@"%s",__func__);
//    _displayLink.paused = NO;
    isPlaying = YES;
    isSeeking = NO;
    if (_playRate == 0.0) {
        _playRate = 1.0;
    }
    [_player setRate:_playRate];
//    [_player play];
    NSLog(@"rate:%f", _playRate);
}
- (void)pause{
    NSLog(@"%s",__func__);
    isPlaying = NO;
    isSeeking = NO;
//    _displayLink.paused = YES;
    [_player pause];
}
- (void)seekToTime:(CMTime)time toleranceTime:(CMTime) tolerance completionHandler:(void (^)(BOOL finished))completionHandler
{
    BOOL isCanSeek = (CMTimeCompare(time, preSeekTime) != 0);//20191224 后退seek的时候不顺畅
    if (isPlaying || (isSeeking && !isCanSeek)) {
        if (completionHandler) {
            completionHandler(NO);
        }
//        NSLog(@"isSeeking");
        return;
    }
    if (isSeeking) {//20191224 后退seek的时候不顺畅,问题还是没解决
        [_player cancelPendingPrerolls];
        [_playerItem cancelPendingSeeks];
    }
    preSeekTime = time;
    __block typeof(self) bself = self;
    if (_player.status == AVPlayerStatusReadyToPlay) {//AVPlayerItem cannot service a seek request with a completion handler until its status is AVPlayerItemStatusReadyToPlay.
        isSeeking = YES;
        if(isnan(CMTimeGetSeconds(time))){
            time = kCMTimeZero;
        } @try {
//            NSLog(@"seekToTime--->:%@",CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)));
            [_player seekToTime:time toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
//                NSLog(@"seek--->Time:%@ tolerance:%@ %@ :%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, tolerance)), finished ? @"YES" : @"NO", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _player.currentTime)));
                if (!isPlaying) {
                    [bself refreshWithTime:time];
                }
                bself->isSeeking = NO;
                if (completionHandler) {
                    completionHandler(finished);
                }
            }];
        } @catch (NSException *exception) {
            NSLog(@"exception: %@",exception);
            @try {
                [_player seekToTime:time toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
                    //            NSLog(@"seekToTime:%@ %@ :%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time)), finished ? @"YES" : @"NO", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _player.currentTime)));
                    if (completionHandler) {
                        completionHandler(finished);
                    }
                    bself->isSeeking = NO;
                }];
            } @catch (NSException *exception) {
                NSLog(@"exception: %@",exception);
                if (completionHandler) {
                    completionHandler(NO);
                }
            }
        }
        
        //偶尔seek不成功
//        [self refreshWithTime:time];//20191128 刷新当前帧的情况，seek后再调用这个方法，会造成闪动的效果
//        NSLog(@"%s time :%f",__func__,CMTimeGetSeconds(time));
    }else{
        if (completionHandler) {
            completionHandler(NO);
        }
    }
}

- (void)seekToTime:(CMTime)time{
    
    __block typeof(self) bself = self;
    if (_player.status == AVPlayerStatusReadyToPlay) {//AVPlayerItem cannot service a seek request with a completion handler until its status is AVPlayerItemStatusReadyToPlay.
//        NSLog(@"seektotime:%lf",CMTimeGetSeconds(time));
        isSeeking = YES;
        [_player seekToTime:time completionHandler:^(BOOL finished) {
            bself->isSeeking = NO;
        }];
        //偶尔seek不成功
        [self refreshWithTime:time];
    }
}

- (void)refreshCurrentFrame:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler {
    if (_player.status == AVPlayerStatusReadyToPlay && CMTimeCompare(time, refreshCurrentTime) != 0) {
        _isRefreshCurrentFrame = YES;
        refreshCurrentTime = time;
        __weak typeof(self) weakSelf = self;
        //20191126 加一帧startVideoCompositionRequest就可以回调
        [self seekToTime:CMTimeAdd(time, CMTimeMake(1, _editor.fps)) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
           __strong typeof(self) strongSelf = weakSelf;
            [strongSelf seekToTime:time toleranceTime:kCMTimeZero completionHandler:completionHandler];
        }];
    }
}

- (void)synchronizePlayerWithEditor
{
    NSLog(@"%s",__func__);
    if ( _player == nil )
        return;
    AVPlayerItem *playerItem = [self.editor playerItem];
    
    if (self.playerItem != playerItem) {
        if ( self.playerItem ) {
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        }
        
        self.playerItem = playerItem;
        
        if ( self.playerItem ) {
            if ( [self.playerItem respondsToSelector:@selector(setSeekingWaitsForVideoCompositionRendering:)] )
                self.playerItem.seekingWaitsForVideoCompositionRendering = YES;
            
            // Observe the player item "status" key to determine when it is ready to play
            [self.playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial) context:(__bridge void *)(AVCustomEditPlayerViewControllerStatusObservationContext)];
            
            // When the player item has played to its end time we'll set a flag
            // so that the next time the play method is issued the player will
            // be reset to time zero first.
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        }
        [_player replaceCurrentItemWithPlayerItem:playerItem];        
        
        //iPad4需要确保模式成功
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError *error = nil;
        BOOL suc = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
        if(!suc){
            NSLog(@"AVAudioSession setCategory failed:%@", error);
        }
//        double hwSampleRate = 44100;
//        suc = [audioSession setPreferredSampleRate:hwSampleRate error:&error];
//        if(!suc){
//            NSLog(@"AVAudioSession setPreferredSampleRate failed:%@", error);
//        }
//        NSTimeInterval ioBufferDuration = 0.01;
//        suc = [audioSession setPreferredIOBufferDuration:ioBufferDuration error:&error];
//        if(!suc){
//            NSLog(@"AVAudioSession setPreferredIOBufferDuration failed:%@", error);
//        }
//        [audioSession setActive:YES error:&error];
//        if(!suc){
//            NSLog(@"AVAudioSession setActive failed:%@", error);
//        }
        if(!_displayLink)
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        
        if (@available(iOS 10.0,*)) {
            self.displayLink.preferredFramesPerSecond = _editor.fps;
        }else{
            self.displayLink.frameInterval = 60/_editor.fps;
        }
        
        [[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [self configPlayerItemOutput];
    }
}

- (void)configPlayerItemOutput {
    [[self displayLink] setPaused:YES];
    if (_playerItemOutput) {
        [_playerItemOutput setDelegate:nil queue:nil];
        [_playerItem removeOutput:_playerItemOutput];
        _playerItemOutput = nil;
    }
    dispatch_queue_t videoProcessingQueue = [RDGPUImageContext sharedContextQueue];
    NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
    if ([RDGPUImageContext supportsFastTextureUpload]) {
        [pixBuffAttributes setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    }
    else {
        [pixBuffAttributes setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    }
    _playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    [_playerItemOutput setDelegate:self queue:videoProcessingQueue];
    double time = CACurrentMediaTime();
    [_playerItem addOutput:_playerItemOutput];
    NSLog(@"configPlayerItemOutput 耗时:%lf",CACurrentMediaTime() -time);//15ms
    [_playerItemOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.1];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
//    NSLog(@"%s",__func__);
    isPlaying = NO;
    if(_playDelegate){
        if(_isMain && [_playDelegate respondsToSelector:@selector(playCurrentTime:)]){
            [_playDelegate playCurrentTime:[self playerItemDuration]];
        }
        if([_playDelegate respondsToSelector:@selector(playToEnd)]){
            [_playDelegate playToEnd];
        }
    }
    /* After the movie has played to its end time, seek back to time zero to play it again. */
}

#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    NSLog(@"\n\n\n %s \n\n", __func__);
    __weak typeof(self) weakSelf = self;
//    NSLog(@"\n\n\n %s \n\n_playerItem.status:%zd _playerItem.error:%@ _playerItem.errorlog:%@\n",__func__, _playerItem.status,_playerItem.error,_playerItem.errorLog);
    if (![_playerItemOutput hasNewPixelBufferForItemTime:CMTimeMake(1, 10)] && _playerItem.status == AVPlayerItemStatusReadyToPlay) {
        NSLog(@"failed!!!!!!!!!!  _playerItem.status:%zd _playerItem.error:%@ _playerItem.errorlog:%@", _playerItem.status,_playerItem.error,_playerItem.errorLog);
        //20170915 wuxiaoxia 播放时有时黑屏
        
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf->configPlayerItemOutputCounts == 30) {
                strongSelf->configPlayerItemOutputCounts = 0;
                if (strongSelf.playDelegate && [strongSelf.playDelegate respondsToSelector:@selector(statusChanged: statues:)]) {
                    [strongSelf.playDelegate statusChanged:strongSelf statues:kRenderStatusFailed];
                }
            }else {
                strongSelf->configPlayerItemOutputCounts++;
                [strongSelf configPlayerItemOutput];
                if (strongSelf.playDelegate && [strongSelf.playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
                    [strongSelf.playDelegate statusChanged:strongSelf statues:kRenderStatusWillChangeMedia];
                }
            }
        });
    }else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayConfigPlayerItemOutput) object:nil];
        NSLog(@"configPlayerItemOutputCounts:%zd", configPlayerItemOutputCounts);
        configPlayerItemOutputCounts = 0;
        isCanPlay = YES;
//        _playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;
#ifdef ForcedSeek
        if (isPrepareFinishSeek && _playDelegate && [_playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.playDelegate statusChanged:strongSelf statues:kRenderStatusReadyToPlay];
            });
        }
#else
        if (_playDelegate && [_playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.playDelegate statusChanged:strongSelf statues:kRenderStatusReadyToPlay];
            });
        }
#endif
    }
    // Restart display link.
    [[self displayLink] setPaused:NO];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == (__bridge void *)(AVCustomEditPlayerViewControllerRateObservationContext) ) {
#if 0
        float newRate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        NSNumber *oldRateNum = [change objectForKey:NSKeyValueChangeOldKey];
#endif
    }
    else if ( context == (__bridge void *)(AVCustomEditPlayerViewControllerStatusObservationContext) ) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
#ifdef ForcedSeek
            NSLog(@">>>>>>>>>>>>>>>>playerItem.status:%zd isPrepareFinishSeek:%@ isSeeking:%@",playerItem.status, isPrepareFinishSeek ? @"YES" : @"NO", isSeeking ? @"YES" : @"NO");
            if (@available(iOS 10.0,*)) {
                if (!isPrepareFinishSeek) {
                    __weak typeof(self) weakSelf = self;
                    [self seekToTime:CMTimeMake(3, _editor.fps) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        if (finished) {
                            __strong typeof(self) strongSelf = weakSelf;
                            strongSelf->isPrepareFinishSeek = YES;
                            if (strongSelf->isCanPlay && strongSelf.playDelegate && [strongSelf.playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
                                [strongSelf.playDelegate statusChanged:strongSelf statues:kRenderStatusReadyToPlay];
                            }
                        }
                    }];
                }else if (!isSeeking) {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                    [self performSelector:@selector(delayConfigPlayerItemOutput) withObject:nil afterDelay:0.1];//因设置_playerItemOutput的AdvanceInterval为0.1
                }
            }else {//20190315 IOS9.0添加配乐或者配音时，有时会构造虚拟视频失败，不调用outputMediaDataWillChange
                __weak typeof(self) weakSelf = self;
                if (!isPrepareFinishSeek) {
                    [self seekToTime:CMTimeMake(3, _editor.fps) toleranceTime:kCMTimeZero completionHandler:^(BOOL finished) {
                        [weakSelf performSelector:@selector(delayConfigPlayerItemOutput) withObject:nil afterDelay:0.1];
                        
                        if (finished) {
                            __strong typeof(self) strongSelf = weakSelf;
                            strongSelf->isPrepareFinishSeek = YES;
                            if (strongSelf->isCanPlay && strongSelf.playDelegate && [strongSelf.playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
                                [strongSelf.playDelegate statusChanged:strongSelf statues:kRenderStatusReadyToPlay];
                            }
                        }
                    }];
                }else if (!isSeeking) {
                    [self performSelector:@selector(delayConfigPlayerItemOutput) withObject:nil afterDelay:0.1];
                }
            }
#endif
        }
        else if (playerItem.status == AVPlayerItemStatusFailed) {
            if (_playDelegate && [_playDelegate respondsToSelector:@selector(statusChanged:statues:)]) {
                [_playDelegate statusChanged:self statues:kRenderStatusFailed];
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)delayConfigPlayerItemOutput {
    if (configPlayerItemOutputCounts == -1) {
        NSLog(@"%s", __func__);
        configPlayerItemOutputCounts = 0;
        [self configPlayerItemOutput];
    }
}

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [_player currentItem];
    CMTime itemDuration = kCMTimeInvalid;
    
//    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
//        itemDuration = [playerItem duration];
//    }
    itemDuration = [playerItem duration];
    NSLog(@"%s%@",__func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, itemDuration)));
    /* Will be kCMTimeInvalid if the item is not ready to play. */
    return itemDuration;
}

- (void)refreshWithTime:(CMTime)cmtime{
    CMTime outputItemTime = cmtime;
    if ([_playerItemOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        CMTime realTime = kCMTimeInvalid;
        CVPixelBufferRef pixelBuffer = [_playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:&realTime];
        
        if(pixelBuffer){
            __weak typeof(self) weakSelf = self;
            rdRunSynchronouslyOnVideoProcessingQueue(^{
                __strong typeof(self) strongSelf = weakSelf;
                if(strongSelf && strongSelf.delegate){
                    if (_isRefreshCurrentFrame && CMTimeCompare(refreshCurrentTime, realTime) == 0) {
//                        NSLog(@"%s_isRefreshCurrentFrame %@ realTime:%@",__func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, outputItemTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, realTime)));
                        if([strongSelf.delegate respondsToSelector:@selector(willOutputPixelBuffer:time:)]){
                            [strongSelf.delegate willOutputPixelBuffer:pixelBuffer time:outputItemTime];
                            CFRelease(pixelBuffer);
                        }
                        refreshCurrentTime = kCMTimeInvalid;
                        _isRefreshCurrentFrame = NO;
                    }else if (!_isRefreshCurrentFrame) {
//                        NSLog(@"%s %@ realTime:%@",__func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, outputItemTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, realTime)));
                        if([strongSelf.delegate respondsToSelector:@selector(willOutputPixelBuffer:time:)]){
                            [strongSelf.delegate willOutputPixelBuffer:pixelBuffer time:outputItemTime];
                            CFRelease(pixelBuffer);
                        }
                        if(strongSelf.playDelegate && strongSelf.isMain){
                            if([strongSelf.playDelegate respondsToSelector:@selector(playCurrentTime:)]){
                                [strongSelf.playDelegate playCurrentTime:outputItemTime];
                            }
                        }
                    }
//                    else {
//                        NSLog(@"%s??? %@ realTime:%@",__func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, refreshCurrentTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, realTime)));
//                    }
                }
            });
        }
    }
}

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    if ((!isPlaying && CMTimeCompare(preSeekTime, kCMTimeInvalid) != 0) || isBackground || isSeeking) {//20170707 wuxiaoxia 有时按home键崩溃
        return;
    }
    CMTime outputItemTime = kCMTimeInvalid;
//    NSLog(@"%s",__func__);
    // Calculate the nextVsync time which is when the screen will be refreshed next.
    CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
    
    outputItemTime = [[self playerItemOutput] itemTimeForHostTime:nextVSync];
//    outputItemTime = CMTimeMakeWithSeconds((int)CMTimeGetSeconds(outputItemTime), _editor.fps);
    outputItemTime = CMTimeMake(CMTimeGetSeconds(outputItemTime)*_editor.fps, _editor.fps);//20180821 wuxiaoxia 消除警告：warning: error of xxxx introduced due to very low timescale
    if ([_playerItemOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        CMTime realTime = kCMTimeInvalid;
        CVPixelBufferRef pixelBuffer = [_playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:&realTime];
        
//        NSLog(@"%s%@ realTime:%@",__func__, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, outputItemTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, realTime)));

        if(pixelBuffer){
            if (self.playDelegate && [self.playDelegate respondsToSelector:@selector(currentBufferTime:)]) {
                [self.playDelegate currentBufferTime:realTime];
            }
            __weak typeof(self) weakSelf = self;
            rdRunSynchronouslyOnVideoProcessingQueue(^{
                __strong typeof(self) strongSelf = weakSelf;
                if(strongSelf.delegate && !(strongSelf->isBackground || strongSelf->isSeeking)){
                    if([strongSelf.delegate respondsToSelector:@selector(willOutputPixelBuffer:time:)]){
                        [strongSelf.delegate willOutputPixelBuffer:pixelBuffer time:outputItemTime];
                        CFRelease(pixelBuffer);
                    }
                    if(strongSelf.playDelegate && strongSelf.isMain){
                        if([strongSelf.playDelegate respondsToSelector:@selector(playCurrentTime:)]){
                            [strongSelf.playDelegate playCurrentTime:outputItemTime];
                        }
                    }
                }
            });
        }
    }
}

- (UIImage*)getImageAtTime:(CMTime) outputTime scale:(float) scale
{
    //20170817 wuxiaoxia 需要先seek到指定时间，才能获取到buffer
    if (CMTimeCompare(_player.currentTime, outputTime) != 0) {
        NSLog(@"current:%@ output:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _player.currentTime)), CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, outputTime)));
        [_player seekToTime:outputTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
        usleep(200000);
    }
    
    UIImage* image=nil;
    CVPixelBufferRef pixelBuffer = [_playerItemOutput copyPixelBufferForItemTime:outputTime itemTimeForDisplay:NULL];
    if (pixelBuffer) {
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        CGImageRef videoImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
        UIImage* imageO = [UIImage imageWithCGImage:videoImage];
        CGImageRelease(videoImage);
        CFRelease(pixelBuffer);
        if (imageO) {
            UIGraphicsBeginImageContext(CGSizeMake(imageO.size.width*scale,imageO.size.height*scale));
            [imageO drawInRect:CGRectMake(0, 0, imageO.size.width*scale, imageO.size.height*scale)];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
    }
    return image;
}

- (void)getImageAtTime:(CMTime) outputTime scale:(float) scale completion:(void (^)(UIImage *image))completionHandler {
    __weak typeof(self) myself = self;
    [_player seekToTime:outputTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        NSLog(@"图片时间:%f", CMTimeGetSeconds(outputTime));
        @autoreleasepool {
        UIImage* image=nil;
        CVPixelBufferRef pixelBuffer;
        @try {
            pixelBuffer = [myself.playerItemOutput copyPixelBufferForItemTime:outputTime itemTimeForDisplay:NULL];
        } @catch (NSException *exception) {
            NSLog(@"失败 图片时间:%f", CMTimeGetSeconds(outputTime));
        } @finally {
            
        }
        if (pixelBuffer) {
            
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
            CGImageRef videoImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
            UIImage* imageO = [UIImage imageWithCGImage:videoImage];
            CGImageRelease(videoImage);
            CFRelease(pixelBuffer);
            if (imageO) {
                UIGraphicsBeginImageContext(CGSizeMake(imageO.size.width*scale,imageO.size.height*scale));
                [imageO drawInRect:CGRectMake(0, 0, imageO.size.width*scale, imageO.size.height*scale)];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            
        }
        if (completionHandler) {
            completionHandler(image);
        }
        }
    }];
}

- (UIImage *)getCurrentFrameWithScale:(float)scale {
    UIImage* image=nil;
    CVPixelBufferRef pixelBuffer = [_playerItemOutput copyPixelBufferForItemTime:_player.currentTime itemTimeForDisplay:NULL];
    if (pixelBuffer) {        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        CGImageRef videoImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
        UIImage* imageO = [UIImage imageWithCGImage:videoImage];
        CGImageRelease(videoImage);
        CFRelease(pixelBuffer);
        if (imageO) {
            UIGraphicsBeginImageContext(CGSizeMake(imageO.size.width*scale,imageO.size.height*scale));
            [imageO drawInRect:CGRectMake(0, 0, imageO.size.width*scale, imageO.size.height*scale)];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    return image;
}

- (void) clear{
    isPlaying = NO;
    isSeeking = NO;
    isPrepareFinishSeek = NO;
    isCanPlay = NO;
    preSeekTime = kCMTimeInvalid;
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    if (_playerItemOutput) {
        [_playerItemOutput setDelegate:nil queue:nil];
        [_playerItem removeOutput:_playerItemOutput];
        _playerItemOutput = nil;
    }
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        _playerItem.videoComposition = nil;
        _playerItem.audioMix = nil;
        [_playerItem cancelPendingSeeks];
        [_playerItem.asset cancelLoading];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeOutput:_playerItemOutput];
        [_playerItemOutput setDelegate:nil queue:nil];
        _playerItemOutput = nil;
        _playerItem = nil;
    }
    if (_player) {
        [_player pause];
        [_player removeObserver:self forKeyPath:@"rate"];
        [_player replaceCurrentItemWithPlayerItem:nil];
        _player = nil;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_editor) {
        _editor = nil;
    }
    [self clear];
    NSLog(@"%f %s",CACurrentMediaTime(),__func__);
}
@end
