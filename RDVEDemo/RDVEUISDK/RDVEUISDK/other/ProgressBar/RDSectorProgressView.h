//
//  RDSectorProgressView.h
//  RDVEUISDK
//
//  Created by emmet on 15/8/26.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDSectorProgressViewDelegate;

//typedef CGFloat (^KKProgressBlock)();

@interface RDSectorProgressView : UIView
@property(nonatomic, weak) id <RDSectorProgressViewDelegate> delegate;

@property(nonatomic, assign) float progress;//CGFloat progress; //20161104 bug205

@property(nonatomic) CGFloat frameWidth;

@property(nonatomic, strong) UIColor *progressColor;

@property(nonatomic, strong) UIColor *progressBackgroundColor;

@property(nonatomic, strong) UIColor *circleBackgroundColor;

- (void)progressValueChange:(float)progress;

@end

@protocol RDSectorProgressViewDelegate <NSObject>
@optional

@end
