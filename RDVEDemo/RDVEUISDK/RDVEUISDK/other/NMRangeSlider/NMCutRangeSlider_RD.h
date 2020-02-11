//
//  NMCutRangeSlider_RD.h
//  RDVEUISDK
//
//  Created by emmet on 16/7/12.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVECore.h"
#import <AVFoundation/AVFoundation.h>
typedef void (^CallBlock)(float progressTime);
@class NMCutRangeSlider_RD;
@protocol NMCutRangeSlider_RDDelegate <NSObject>

- (void)NMCutRangeSliderLoadThumbsCompletion;
- (void)beginScrub:(NMCutRangeSlider_RD *)slider;
- (void)scrub:(NMCutRangeSlider_RD *)slider;
- (void)endScrub:(NMCutRangeSlider_RD *)slider;

@end


@interface NMCutRangeSlider_RD : UIControl

@property (nonatomic,copy)CallBlock handProgressTrackMove;
@property(weak,nonatomic)   id<NMCutRangeSlider_RDDelegate> delegate;
@property(assign, nonatomic) float minimumValue;

// default 1.0
@property(assign, nonatomic) float maximumValue;

// default 0.0. This is the minimum distance between between the upper and lower values
@property(assign, nonatomic) float minimumRange;

// default 0.0 (disabled)
@property(assign, nonatomic) float stepValue;

// If NO the slider will move freely with the tounch. When the touch ends, the value will snap to the nearest step value
// If YES the slider will stay in its current position until it reaches a new step value.
// default NO
@property(assign, nonatomic) BOOL stepValueContinuously;

// defafult YES, indicating whether changes in the sliders value generate continuous update events.
@property(assign, nonatomic) BOOL continuous;

// default 0.0. this value will be pinned to min/max
@property(assign, nonatomic) float lowerValue;

// default 1.0. this value will be pinned to min/max
@property(assign, nonatomic) float upperValue;

// center location for the lower handle control
@property(readonly, nonatomic) CGPoint lowerCenter;

// center location for the upper handle control
@property(readonly, nonatomic) CGPoint upperCenter;

@property(assign, nonatomic) float progressValue;

@property(assign, nonatomic) float durationValue;
@property(assign, nonatomic) float speed;

@property(assign, nonatomic) BOOL handleLeft;

@property(assign, nonatomic) BOOL handleRight;

@property (strong, nonatomic) UIImageView* lowerHandle;
@property (strong, nonatomic) UIImageView* upperHandle;

@property (strong, nonatomic) UIImageView* progressTrack;
// Images, these should be set before the control is displayed.
// If they are not set, then the default images are used.
// eg viewDidLoad


//Probably should add support for all control states... Anyone?

@property(strong, nonatomic) UIImage* lowerHandleImageNormal;

@property(strong, nonatomic) UIImage* lowerHandleImageHighlighted;

@property(strong, nonatomic) UIImage* upperHandleImageNormal;

@property(strong, nonatomic) UIImage* upperHandleImageHighlighted;

@property(strong, nonatomic) UIImage* lowerHandleImage;

@property(strong, nonatomic) UIImage* upperHandleImage;

@property(strong, nonatomic) UIImage* trackImage;

@property(strong, nonatomic) UIImage* progressTrackImage;

@property(strong, nonatomic) UIImage* trackBackgroundImage;

@property(strong, nonatomic) UIImageView    *progressView;

@property(assign, nonatomic) BOOL           isblockHandle;

@property(assign, nonatomic) BOOL           isloadFinishThumb;



@property(strong, nonatomic) AVAssetImageGenerator *imageGenerator;
@property(assign, nonatomic) float selectedDurationValue;
@property(assign, nonatomic) float moveValue; // 前后固定比例
@property(assign, nonatomic) BOOL mode; // True  自由模式  False 固定模式
@property(strong, nonatomic) NSMutableArray* highlightArray;
//Setting the lower/upper values with an animation :-)
- (void)setLowerValue:(float)lowerValue animated:(BOOL) animated;

- (void)setUpperValue:(float)upperValue animated:(BOOL) animated;

- (void) setLowerValue:(float) lowerValue upperValue:(float) upperValue animated:(BOOL)animated;
- (void)cancelAllCGImageGeneration;
- (void)continueLoadThumb;
- (void)progress:(float)value;

@property(nonatomic,strong)RDVECore         *videoCoreSDK;
@property(nonatomic,copy) NSString          *filtImagePatch;
-(void)loadCutRangeSlider;
@end
