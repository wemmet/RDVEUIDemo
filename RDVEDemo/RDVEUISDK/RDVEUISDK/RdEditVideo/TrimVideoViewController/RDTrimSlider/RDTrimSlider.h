//
//  RDTrimSlider.h
//  RDVEUISDK
//
//  Created by apple on 2019/9/17.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptionVideoTrimmerView.h"

NS_ASSUME_NONNULL_BEGIN


@protocol RDTrimSliderDelegate <NSObject>
-(void)trimmerViewProgress:(CGFloat)startTime;

@end

@interface RDTrimSlider : UIControl
- (instancetype)initWithFrame:(CGRect)frame videoCore:(RDVECore *)videoCore trimDuration_OneSpecifyTime:(float) trimDuration_OneSpecifyTime;

- (void)loadTrimmerViewThumbImage:(UIImage *)image thumbnailCount:(NSInteger)thumbnailCount;

@property (weak, nonatomic) id<RDTrimSliderDelegate> delegate;

@property (strong, nonatomic) UIImageView* lowerHandle;
@property (strong, nonatomic) UIImageView* upperHandle;
@property (strong, nonatomic) CaptionVideoTrimmerView*  TrimmerView;
@property(nonatomic,strong)RDVECore *thumbnailCoreSDK;
@property (nonatomic,assign) float trimDuration_OneSpecifyTime;

@property(nonatomic,assign) float progressValue;
@property(nonatomic,assign) float currentProgressValue;

-(float)progress:(float) value;
-(void)interceptProgress:(float) value;
@end

NS_ASSUME_NONNULL_END
