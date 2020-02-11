/*
 *  ATMHudView.h
 *  ATMHud
 *
 *  Created by Marcel Müller on 2011-03-01.
 *  Copyright (c) 2010-2011, Marcel Müller (atomcraft)
 *  All rights reserved.
 *
 *	https://github.com/atomton/ATMHud
 */

#import <UIKit/UIKit.h>

@class RDATMTextLayer,RDATMProgressLayer, RDATMHud, RDATMHudQueueItem;

typedef NS_ENUM(NSInteger,RDATMHudApplyMode) {
	RDATMHudApplyModeShow = 0,
	RDATMHudApplyModeUpdate,
	RDATMHudApplyModeHide
} ;

@interface RDATMHudView : UIView<CAAnimationDelegate>
{
	NSString *caption;
	UIImage *image;
	UIActivityIndicatorView *activity;
	UIActivityIndicatorViewStyle activityStyle;
	RDATMHud *p;
	
	BOOL showActivity;
 
	CGFloat progress;
	
	CGRect targetBounds;
	CGRect captionRect;
	CGRect progressRect;
	CGRect activityRect;
	CGRect imageRect;
	
	CGSize fixedSize;
	CGSize activitySize;
	
	CALayer *backgroundLayer;
	CALayer *imageLayer;
	RDATMTextLayer *captionLayer;
	RDATMProgressLayer *progressLayer;
}

@property (nonatomic, copy) NSString *caption;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityStyle;
@property (nonatomic, strong) RDATMHud *p;

@property (nonatomic, assign) BOOL showActivity;

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, assign) CGRect targetBounds;
@property (nonatomic, assign) CGRect captionRect;
@property (nonatomic, assign) CGRect progressRect;
@property (nonatomic, assign) CGRect activityRect;
@property (nonatomic, assign) CGRect imageRect;

@property (nonatomic, assign) CGSize fixedSize;
@property (nonatomic, assign) CGSize activitySize;

@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) CALayer *imageLayer;
@property (nonatomic, strong) RDATMTextLayer *captionLayer;
@property (nonatomic, strong) RDATMProgressLayer *progressLayer;

- (id)initWithFrame:(CGRect)frame andController:(RDATMHud *)c;

- (CGRect)sharpRect:(CGRect)rect;
- (CGPoint)sharpPoint:(CGPoint)point;

- (void)calculate;
- (CGSize)calculateSizeForQueueItem:(RDATMHudQueueItem *)item;
- (CGSize)sizeForActivityStyle:(UIActivityIndicatorViewStyle)style;
- (void)applyWithMode:(RDATMHudApplyMode)mode;
- (void)show;
- (void)reset;
- (void)update;
- (void)hide;
- (void)releaseHudView;
@end
