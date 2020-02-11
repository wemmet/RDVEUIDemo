//
//  RDCircleView.h
//  RDVEUISDK
//
//  Created by emmet on 2017/3/29.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDCircleView : UIView
/** 进度值0-1.0之间
 */
@property (nonatomic,assign)CGFloat progressValue;

/** 边宽
 */
@property(nonatomic,assign) CGFloat progressStrokeWidth;

/** 进度条颜色
 */
@property(nonatomic,strong)UIColor *progressColor;

/** 进度条轨道颜色
 */
@property(nonatomic,strong)UIColor *progressTrackColor;

@property(nonatomic,assign) BOOL animation;

/**  执行动画
 */
- (void)startAnimation;
/**  停止动画
 */
- (void)stopAnimation;
- (void)setProgressRect:(CGRect)rect;
@end


