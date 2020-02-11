//
//  RDMoveProgress.h
//  RDVEUISDK
//
//  Created by emmet on 15/10/13.
//  Copyright © 2015年 emmet. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface RDMoveProgress : UIView
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIColor* progressTintColor;
@property (nonatomic, strong) UIColor* trackTintColor;
@property (nonatomic, strong) UIImage* progressImag;
@property (nonatomic, strong) UIImage* trackImage;
- (void)setProgress:(double)progress animated:(BOOL)animated;



@end
