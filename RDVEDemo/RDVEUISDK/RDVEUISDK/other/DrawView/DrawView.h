//
//  DrawView.h
//  12
//
//  Created by 吴灶洲 on 2017/5/22.
//  Copyright © 2017年 吴灶洲. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
@class DrawTouchPointView;

@protocol DrawViewDelegate <NSObject>
- (void)showAlertView:(UIAlertController *)alertController;
@end

@interface DrawView : UIImageView

@property (nonatomic, strong) DrawTouchPointView *drawView;

@property (nonatomic,weak) id <DrawViewDelegate> delegate;

+ (DrawView *)initWithImage:(UIImage *)image frame:(CGRect)frame lineWidth:(CGFloat)lineWidth lineColor:(UIColor *)lineColor;
/** 清屏 */
- (void)clearScreen;
/** 撤消操作 */
- (void)revokeScreen;
/** 擦除 */
- (void)eraseSreen;
/** 设置画笔颜色 */
- (void)setStrokeColor:(UIColor *)lineColor;

-(UIColor *)StrokeColor;

/** 设置画笔大小 */
- (void)setStrokeWidth:(CGFloat)lineWidth;
- (float)LineWidth;

- (void)alterDrawBoardDescLabel:(UILabel *)content;

- (UIImage *)getImage;

- (BOOL)isHasContent;//是否还有画的线
@end



@interface DrawTouchPointView : UIView
@property (nonatomic, strong) NSMutableArray *stroks;
@property (nonatomic, strong) NSMutableArray <UILabel *> *textDescs;
@property (nonatomic, assign,readonly) CGPoint touchupCurrentPoint;
@property (nonatomic,assign)BOOL canDrawLine;
/** 清屏 */
- (void)clearScreen;
/** 撤消操作 */
- (void)revokeScreen;
/** 擦除 */
- (void)eraseSreen;
/** 设置画笔颜色 */
- (void)setStrokeColor:(UIColor *)lineColor;
/** 设置画笔大小 */
- (void)setStrokeWidth:(CGFloat)lineWidth;

- (UIImage *)snapsHotView;

@end


typedef struct CGPath *CGMutablePathRef;
typedef enum CGBlendMode CGBlendMode;

@interface DWStroke : NSObject

@property (nonatomic) CGMutablePathRef path;
@property (nonatomic, assign) CGBlendMode blendMode;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, strong) UIColor *lineColor;
- (void)strokeWithContext:(CGContextRef)context;
@end

