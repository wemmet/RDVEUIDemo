//
//  UITextTypesetViewCell.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/16.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextFieldKeybordDelete.h"

@interface RDTextObject : NSObject

@property (nonatomic, assign)CMTime     startTime;
@property (nonatomic, assign)CMTime     AnimationTime;
@property (nonatomic, assign)CMTime     showTime;
@property (nonatomic, assign)CMTime     textRotationTime;   //旋转时间 用于需要旋转的自绘对象
@property (nonatomic, assign)float      textRadian;

//字体
@property (nonatomic, strong)NSString   *fontName;
@property (nonatomic, assign)float      textFontSize;
//阴影
@property (nonatomic, assign)float      textFontshadow;
@property (nonatomic, assign)UIColor    *textColorShadow;
//描边
@property (nonatomic, assign)float      textFontStroke;
@property (nonatomic, assign)UIColor    *textFontStrokeColor;
//字体颜色
@property (nonatomic, assign)UIColor    *textColor;

@property (nonatomic, strong)NSString   *strText;

//字体放大倍速
@property (nonatomic, assign)float      textFontSizeSpeed;

@end

@protocol UITextTypesetViewCellDelegate<NSObject>

-(void)select;

@end



@interface UITextTypesetViewCell : UIView

@property (nonatomic,weak) id<UITextTypesetViewCellDelegate> delegate;
//UICollectionViewCell

//是否选中
@property(nonatomic,strong)UIButton     *selectBtn;
@property(nonatomic,strong)UIImageView      *selectLabel;
//编辑文本
@property(nonatomic,strong)UITextFieldKeybordDelete  *textField;
@property(nonatomic,strong)UIView       *selectView;

@property(nonatomic,strong)RDTextObject *textObject;



-(void)setTextFieldTag:(int) tag;

-(void)setText:(NSString*) text;

-(void)setTextStroke:(UIColor *) strokeColor atStrokeSize:(float) strokeSize;
-(void)setTextFont:(NSString *)fontName;
-(void)setTextColor:(UIColor *)fontColor;
-(void)setshadow:(float)shadowSize secondColor:(UIColor*)secondColor;

-(void)setSelect:(BOOL) select;

-(void)dottedLine:(bool) isLine;

-(void)setEndle:(bool) isEndle;
@end
