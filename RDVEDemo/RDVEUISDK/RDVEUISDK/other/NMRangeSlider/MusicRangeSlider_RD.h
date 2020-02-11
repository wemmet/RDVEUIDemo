//
//  RangeSlider.h
//  RangeSlider
//
//  Created by Murray Hughes on 04/08/2012
//  Copyright 2011 Null Monkey Pty Ltd. All rights reserved.
//
// Inspried by: https://github.com/buildmobile/iosrangeslider

#import <UIKit/UIKit.h>

@interface MusicRangeSlider_RD : UIControl

// default 0.0
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

@property (strong, nonatomic) UIImageView* track;

//Setting the lower/upper values with an animation :-)
- (void)setLowerValue:(float)lowerValue animated:(BOOL) animated;

- (void)setUpperValue:(float)upperValue animated:(BOOL) animated;

- (void) setLowerValue:(float) lowerValue upperValue:(float) upperValue animated:(BOOL)animated;

- (void)progress:(float)value;
@end
