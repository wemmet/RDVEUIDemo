//
//  UILabel+DynamicFontSize.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/16.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <UIKit/UIKit.h>
//字幕对齐方式
typedef NS_ENUM(NSInteger, UICaptionTextAlignment) {
    UICaptionTextAlignmentLeft = 0,
    UICaptionTextAlignmentCenter,
    UICaptionTextAlignmentRight
};

@interface RDPasterLabel : UILabel

@property (assign,nonatomic) float    tScale;
@property (nonatomic, strong) UIColor *strokeColor;
@property (strong,nonatomic) UIColor *fontColor;
@property (assign,nonatomic) float    textAlpha;
@property (strong,nonatomic) NSString *pText;
@property (assign,nonatomic) float    strokeWidth;
@property (assign,nonatomic) float    strokeAlpha;
@property (assign,nonatomic) BOOL     needStretching;
/** 文字竖排，默认为NO*/
@property (nonatomic ,assign) BOOL isVerticalText;
@property (assign,nonatomic) BOOL     onlyoneline;
@property (assign,nonatomic) UICaptionTextAlignment     tAlignment;
@property (nonatomic ,assign) BOOL isBold;
@property (nonatomic ,assign) BOOL isItalic;/**文字字体加粗，默认为NO*/
@property (nonatomic ,assign) BOOL isShadow;
@property (strong,nonatomic) UIColor *tShadowColor;
@property (assign,nonatomic) CGSize tShadowOffset;
@property (assign,nonatomic) BOOL     defaultH;
@property (assign,nonatomic) float    linesNumber;
- (void)adjustsWidthToFillItsContents:(CGSize)defaultSize textRect:(CGRect) textRect  syncContainerRect:(CGRect)syncContainerRect;
- (void)adjustsWidthWithSuperOriginalSize:(CGSize)superOriginalSize textRect:(CGRect) textRect syncContainerRect:(CGRect)syncContainerRect;
@property (nonatomic,copy,nonnull) void(^setFont)( float fontSize );

@property (assign,nonatomic) float    labelHeight;
@property (assign,nonatomic) CGFloat globalInset;
/*
 
 - (void)adjustsFontSizeToFillItsContents;
 - (void)adjustsFontSizeToFillRect:(CGRect)newBounds;
 - (void)adjustsFontSizeToFillRect:(CGRect)newBounds defaultSize:(CGSize)defaultSize textRect:(CGRect) textRect;
 - (void)adjustsWidthToFillItsContents;
 */
@end

@interface TextLayer : CATextLayer

@property (nonatomic,assign) CGSize contentsSize;

@end

