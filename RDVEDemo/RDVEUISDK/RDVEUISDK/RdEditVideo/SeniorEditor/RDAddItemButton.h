//
//  RDAddItemButton.h
//  RDVEUISDK
//
//  Created by apple on 2019/10/10.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDAddItemButton : UIButton

@property(nonatomic,strong)UIImageView * redDotImageView;
+(RDAddItemButton *)initFXframe:(CGRect) rect atpercentage:(float) propor;
//特效
@property(nonatomic,strong)UIImageView *thumbnailIV;
@property(nonatomic,strong)UILabel *label;
@property(nonatomic,strong)UILabel *moveTitleLabel;
@property(nonatomic,assign)float propor;

-(void)textColor:(UIColor *) color;

//文字滚动显示
@property (nonatomic,assign,readonly) BOOL   isStartMove;
- (void)startScrollTitle;

- (void)stopScrollTitle;

@end

NS_ASSUME_NONNULL_END
