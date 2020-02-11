//
//  ScrollViewChildItem.h
//  RDVEUISDK
//
//  Created by emmet on 16/10/23.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ScrollViewChildItem;
@protocol ScrollViewChildItemDelegate

@optional
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item;

@end
@interface ScrollViewChildItem : UIButton
@property (nonatomic,assign) NSInteger      type;
@property (nonatomic,strong) UIImageView    *itemIconView;
@property (nonatomic,strong) UILabel        *itemTitleLabel;
//@property (nonatomic,strong) void (^tapBtnCallBlock)(id sender);
@property (nonatomic, weak) id<ScrollViewChildItemDelegate> delegate;
@property (nonatomic,assign) BOOL            play;
@property (nonatomic,assign) BOOL            downloading;
@property (nonatomic,assign,readonly) BOOL   isStartMove;
@property (nonatomic,assign) float           cornerRadius;
@property (nonatomic,assign) float           fontSize;
@property (nonatomic,strong) UIColor        *normalColor;
@property (nonatomic,strong) UIColor        *selectedColor;

- (CGRect )getIconFrame;

- (void)startScrollTitle;

- (void)stopScrollTitle;

//变声
@property (nonatomic,assign) BOOL            isVoiceFX;         //是否 变声

//配乐
@property (nonatomic,assign) BOOL            isMuisc;                   //是否配乐
@property (nonatomic,strong) UIImageView    *itemIconselectedView;      //配乐选中

@property (nonatomic,assign) BOOL            isSwitchMuisc;             //是否配乐开关
@end
