//
//  ProgressBar.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/8/16.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
    ProgressBarProgressStyleNormal,
    ProgressBarProgressStyleDelete,
} ProgressBarProgressStyle;

@interface ProgressBar : UIView

//短视频MV最小录制时间提示
@property (nonatomic, strong) UIView    *MVMinDurationView;

//正方形视频最小录制时间提示
@property (nonatomic, strong) UIView    *squareMinDurationView;

//非正方形视频最小录制时间提示
@property (nonatomic, strong) UIView    *notSquareMinDurationView;

+ (ProgressBar *)getInstance;

- (void)setLastProgressToStyle:(ProgressBarProgressStyle)style;
- (void)setLastProgressToWidth:(CGFloat)width;

- (void) deleteLastProgress;
- (void) addProgressView;
- (BOOL) getProgressIndicatorHiddenState;
- (void) setAllProgressToNormal;
- (void) stopShining;
- (void) startShining;
- (void) deleteAllProgress;

@end
