//
//  RDAlertView.h
//  RDVEUISDK
//
//  Created by emmet on 2017/3/29.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kDuration 0.7   // 动画持续时间(秒)

@class RDAlertView;
@protocol RDAlertViewDelegate <NSObject>
@optional

- (void)rdAlertView:(nullable RDAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void)rdAlertViewCancel:(nullable RDAlertView *)alertView NS_DEPRECATED_IOS(2_0, 9_0);


@end
@interface RDAlertView : UIView

@property (nullable,strong)UIImage *backguoundImage;

- (nullable id)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message delegate:(nullable id)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle otherButtonTitles:(nullable NSString *)otherButtonTitles,...;
- (nullable id)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message delegate:(nullable id)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle otherButtonTitleLists:(nullable NSArray *)titleLists;
- (void)show;
- (void) dismiss;

- (void)changeMessage:(nullable NSString *)string;
@end
