//
//  syncContainerView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/13.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface syncContainerView : UIView

@property(nonatomic,strong)UIImageView       *syncContainer_X_Left;
@property(nonatomic,strong)UIImageView       *syncContainer_X_Right;

@property(nonatomic,strong)UIImageView       *syncContainer_Y_Left;
@property(nonatomic,strong)UIImageView       *syncContainer_Y_Right;

@property(nonatomic,strong)UIView *currentPasterTextView;

-(void)pasterMidline:(UIView *) PasterTextView isHidden:(bool) ishidden;
-(void)setMark;

- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer;

@end

NS_ASSUME_NONNULL_END
