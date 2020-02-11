//
//  RDTouchButton.h
//  dyUIAPI
//
//  Created by emmet on 2017/6/8.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RDCircleView.h"
@class RDTouchButton;

@protocol RDTouchButtonDelegate <NSObject>

@optional

- (void)touchesRDTouchButtonBegin:(RDTouchButton *)sender;
- (void)touchesRDTouchButtonMoving:(RDTouchButton *)sender;
- (void)touchesRDTouchButtonEnd:(RDTouchButton *)sender;
@end

@interface RDTouchButton : UIButton
{
    RDCircleView *_circle;
    
}
@property(nonatomic,assign)CGRect  origionFrame;
@property(weak  , nonatomic)id<RDTouchButtonDelegate>   delegate;

- (void)stopAnimation;

@end
