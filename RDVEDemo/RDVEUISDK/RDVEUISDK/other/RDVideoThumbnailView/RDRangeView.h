//
//  RDRangeView.h
//  dyUIAPIDemo
//
//  Created by wuxiaoxia on 2017/5/11.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDRangeViewFile.h"
@class RDRangeView;

typedef NS_ENUM(NSInteger,CoverType) {
    kCoverNone,
    kCoverLeft,
    kCoverRight,
    kCoverMiddle,
    kCoverAll
};

@protocol RDRangeViewDelegate <NSObject>
@optional

- (void)touchesRangeViewBegin:(RDRangeView *)rangView;
- (void)touchesRangeViewMoving:(RDRangeView *)rangView;
- (void)touchesRangeViewEnd:(RDRangeView *)rangView;
@end
@interface RDRangeView : UIButton

@property(strong, nonatomic)RDRangeViewFile *file;
@property(assign, nonatomic)BOOL    canChangeWidth;
@property(assign, nonatomic)BOOL    canMoveLeft;
@property(assign, nonatomic)BOOL    hasMiddle;
@property(assign, nonatomic)BOOL    canMoveRight;
@property(assign, nonatomic)float   minWidth;
@property(weak  , nonatomic)id<RDRangeViewDelegate>   delegate;
@property(assign ,nonatomic)CoverType   coverType;
@property(strong, nonatomic)UIColor   * coverColor;
@property(assign, nonatomic)CGRect      coverRect;
@property(strong, nonatomic)UIImage   * tmpImage;

@end
