//
//  ICGVideoTrimmerView.h
//  ICGVideoTrimmer

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DubbingRangeView.h"
#import "RDVECore.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef enum {
    kCannotAddDubbingforPiantou,
    kCannotAddDubbingforPianwei,
    kCanAddDubbing,
    kCannotAddDubbing,
} RdCanAddDubbingType;


@protocol DubbingTrimmerDelegate;

@interface DubbingTrimmerView : UIView

@property (nonatomic,assign) NSInteger thumbImageTimes;


@property(strong , nonatomic) RDVECore   *videoCore;

@property (strong, nonatomic) UIColor *themeColor;

@property (assign, nonatomic) CGFloat maxLength;

@property (assign, nonatomic) CGFloat minLength;

@property (strong, nonatomic) UIImage *leftThumbImage;

@property (strong, nonatomic) UIImage *rightThumbImage;

@property (strong, nonatomic) UIImageView *contentView;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) UIView *frameView;

@property (strong, nonatomic) UIImageView *videoRangeView;

@property (assign, nonatomic) CGSize contentSize;

@property (assign, nonatomic) CGFloat borderWidth;

@property (weak, nonatomic) id<DubbingTrimmerDelegate> delegate;

@property (assign, nonatomic) BOOL  loadImageFinish;

@property (assign, nonatomic) CMTimeRange  clipTimeRange;

@property (assign, nonatomic) float  piantouDuration;

@property (assign, nonatomic) float  pianweiDuration;

@property (assign, nonatomic) float rightSpace;//右边间距

- (RdCanAddDubbingType)checkCanAddDubbing;

- (void)setFrameRect:(CGRect)rect;
- (instancetype)initWithFrame:(CGRect)frame videoCore:(RDVECore *)videoCore;

- (void)resetSubviews:(UIImage *)thumbImage;

- (void)refreshThumbImage:(NSInteger)index thumbImage:(UIImage *)thumbImage;
- (void)releaseImages;

- (void)addDubbing;
- (void)addDubbingTarget:(DubbingRangeView *)view;//草稿用

- (NSMutableArray *)getTimesFor_videoRangeView;
- (NSMutableArray *)getTimesFor_videoRangeView_withTime;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (BOOL)changecurrentRangeviewppDubbingFile:(float)dubbingDuration volume:(float)volume callBlock:(void (^)(DubbingRangeView *dubbingRange))callBlock;

- (BOOL)changeCurrentVolume:(float)volume;

- (BOOL)savecurrentRangeviewWithMusicPath:(NSString *)musicPath
                              volume:(double)volume
                          dubbingIndex:(NSInteger) index
                                  flag:(BOOL)flag;

- (CMTime)deletedcurrentDubbing;

@end

@protocol DubbingTrimmerDelegate <NSObject>
@optional

- (void)dubbingScrollViewWillBegin:(DubbingTrimmerView *)trimmerView;

- (void)dubbingScrollViewWillEnd:(DubbingTrimmerView *)trimmerView
                        startTime:(Float64)capationStartTime
                          endTime:(Float64)capationEndTime;

- (void)touchescurrentdubbingView:(DubbingRangeView *)sender flag:(BOOL)flag;

- (void)trimmerView:(id)trimmerView
didChangeLeftPosition:(CGFloat)startTime
      rightPosition:(CGFloat)endTime;
@required

@end
