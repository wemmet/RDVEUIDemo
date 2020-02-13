//
//  CLClippingTool.h
//
//  Created by sho yakushiji on 2013/10/18.
//  Copyright (c) 2013年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>

static const CGFloat kCLImageToolAnimationDuration = 0.3;
static const CGFloat kCLImageToolFadeoutDuration   = 0.2;

@interface CLRatio : NSObject
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, readonly) CGFloat ratio;
- (id)initWithValue1:(NSInteger)value1 value2:(NSInteger)value2;
- (NSString*)description;
@end


@interface CLRatioMenuItem : UIView
@property (nonatomic, strong) CLRatio *ratio;
- (id)initWithFrame:(CGRect)frame iconImage:(UIImage*)iconImage;
- (void)changeOrientation;
@end


@interface CLClippingPanel : UIView
@property (nonatomic, assign) CGRect clippingRect;
@property (nonatomic, strong) CLRatio *clippingRatio;
- (id)initWithSuperview:(UIView*)superview frame:(CGRect)frame;
- (void)setBgColor:(UIColor*)bgColor;
- (void)setGridColor:(UIColor*)gridColor;
- (void)clippingRatioDidChange;
@end
@interface CLClippingTool : NSObject

@end
