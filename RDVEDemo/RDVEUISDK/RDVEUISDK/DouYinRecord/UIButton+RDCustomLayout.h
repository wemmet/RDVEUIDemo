//
//  UIButton+RDCustomLayout.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RDButtonEdgeInsetsStyle) {
    RDButtonEdgeInsetsStyleTop,     // image在上，label在下
    RDButtonEdgeInsetsStyleLeft,    // image在左，label在右
    RDButtonEdgeInsetsStyleBottom,  // image在下，label在上
    RDButtonEdgeInsetsStyleRight    // image在右，label在左
};

@interface UIButton (RDCustomLayout)

- (void)layoutButtonWithEdgeInsetsStyle:(RDButtonEdgeInsetsStyle)style
                        imageTitleSpace:(CGFloat)space;

@end

