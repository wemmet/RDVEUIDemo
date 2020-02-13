//
//  RDCaptionLayer.h
//  RDVECore
//
//  Created by apple on 2017/11/20.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "RDScene.h"

#define D2R(d) (d * M_PI / 180)  // 旋转角度

@interface RDCaptionLayer : NSObject

@property (nonatomic) CGImageRef imageRef;
@property (nonatomic,strong) CALayer* layer;

@property (nonatomic,assign) CATransform3D pasterTransform;
@property (nonatomic,assign) float pasterAlphaValue;
@property (nonatomic,assign) float pasterWidthProportion;

@property (nonatomic,assign) CATransform3D captionTransform;
@property (nonatomic,assign) float captionAlphaValue;
@property (nonatomic,assign) float captionWidthProportion;

- (id) initWithCaption:(RDCaption *) caption videoSize:(CGSize) _videoSize;
- (void) clean;
- (void)refresh;
- (void)refreshFrame:(CGRect)frame;
@end


@interface RDCaptionLabel : UILabel

@property (nonatomic, assign) BOOL isUseAttributedText;
@property (nonatomic, strong) UIColor *txtColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) float strokeWidth;
@property (nonatomic, assign) BOOL isBold;
@property (nonatomic ,assign) UIEdgeInsets edgeInsets;

@end


@interface RDTextLayer : CATextLayer

@property (nonatomic,assign) CGSize contentsSize;
@property (nonatomic,assign) CFStringRef fontName;

@end
