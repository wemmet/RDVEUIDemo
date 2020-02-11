//
//  TMVerticallyCenteredTextView.h
//  RDVEUISDK
//
//  Created by 王全洪 on 2018/10/16.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMVerticallyCenteredTextView : UITextView
- (id)initWithFrame:(CGRect)frame isCenter:(BOOL)isCenter;
- (void)refreshContentSize;
@end

NS_ASSUME_NONNULL_END
