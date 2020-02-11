//
//  ICGVideoTrimmerView.h
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "RDComminuteRangeView.h"

@protocol RDICGVideoTrimmerDelegate;

@interface RDICGVideoTrimmerView : UIView
@property (nonatomic, strong) RDFile         *contentFile;
@property (nonatomic, assign) NSInteger      currentIndex;
@property (strong, nonatomic) AVURLAsset    *alasset;
@property (strong, nonatomic) AVURLAsset    *reverseAsset;
@property (nonatomic, assign) BOOL          isReversed;
@property (nonatomic, assign) BOOL          isReversedVideoCached;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) BOOL cannotPlay;
@property (nonatomic,assign) float          lastLowTime;
// Video to be trimmed
@property (strong, nonatomic) AVAsset *asset;

// Theme color for the trimmer view
@property (strong, nonatomic) UIColor *themeColor;

// Maximum length for the trimmed video
@property (assign, nonatomic) CGFloat maxLength;

// Minimum length for the trimmed video
@property (assign, nonatomic) CGFloat minLength;

// Show ruler view on the trimmer view or not
@property (assign, nonatomic) BOOL showsRulerView;

// Show boder view on the trimmer view or not
@property (assign, nonatomic) BOOL showsborderView;

// Custom image for the left thumb
@property (strong, nonatomic) UIImage *leftThumbImage;

// Custom image for the right thumb
@property (strong, nonatomic) UIImage *rightThumbImage;

@property (strong, nonatomic) UIView *contentView;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) UIView *frameView;

@property (strong, nonatomic) UIImageView *videoRangeView;
@property (strong, nonatomic) NSArray *thumbChildrens;

@property (assign, nonatomic) CGSize contentSize;

// Custom width for the top and bottom borders
@property (assign, nonatomic) CGFloat borderWidth;

@property (weak, nonatomic) id<RDICGVideoTrimmerDelegate> delegate;

@property (assign, nonatomic) BOOL  loadImageFinish;

@property (assign, nonatomic) CMTimeRange  clipTimeRange;
@property (assign, nonatomic) Float64 scrollcurrentTime;


@property (nonatomic, strong) NSMutableArray      *movePointsAndcurrentTimes;

@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;

@property (strong, nonatomic) NSMutableArray* highlightArray;

- (instancetype)initWithAsset:(AVAsset *)asset;

- (instancetype)initWithFrame:(CGRect)frame asset:(AVURLAsset *)asset;

- (instancetype)initWithFrame:(CGRect)frame composition:(AVComposition *)composition;

- (void)cancelLoadThumb;

- (void)resetSubviews;

- (NSMutableArray *)getTimesFor_videoRangeView;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (BOOL)cuttingVideo;

- (BOOL)cuttingVideo:(float)beforDuration;
@end

@protocol RDICGVideoTrimmerDelegate <NSObject>
@optional

- (void)trimmerViewRefreshThumbsCompletion;

- (void)trimmerViewScrollViewWillBegin:(UIScrollView *)scrollView;

- (void)trimmerViewScrollViewWillEnd:(UIScrollView *)scrollView startTime:(Float64)startTime endTime:(Float64)endTime;

- (void)deleteForRangeView:(UILongPressGestureRecognizer *)tapGesture;
@required
- (void)trimmerView:(RDICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime;

@end
