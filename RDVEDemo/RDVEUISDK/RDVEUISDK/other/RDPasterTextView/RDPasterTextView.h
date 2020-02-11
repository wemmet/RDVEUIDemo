//
//  RDTextView.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/14.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterLabel.h"
#import "syncContainerView.h"

@class RDPasterTextView;
@protocol RDPasterTextViewDelegate <NSObject>

- (void)pasterViewDidClose:(RDPasterTextView *_Nullable)sticker;
- (void)pasterViewDidChangeFrame:(RDPasterTextView *_Nullable)sticker;
- (void)pasterViewMoved:(RDPasterTextView *_Nullable)sticker;
- (void)pasterViewSizeScale:(RDPasterTextView *_Nullable)sticker atValue:( float ) value;
//是否显示字幕文字编辑界面
- (void)pasterViewShowText;
//背景 画布 中线显示
//-(void)pasterMidline:(RDPasterTextView * _Nullable) canvas_PasterText isHidden:(bool) ishidden;

//抠图颜色提取返回函数
-(void)paster_CutoutColor:(RDPasterTextView * _Nullable) cutOut_PasterText  atColorRed:(float) colorRed atColorGreen:(float) colorGreen atColorBlue:(float) colorBlue atAlpha:(float) colorApha isRefresh:(BOOL) isRefresh;

@end

@interface RDPasterTextView : UIView

@property (nonatomic,strong) syncContainerView            * _Nullable syncContainer;

@property (nonatomic, strong) UIButton *mirrorBtn;
@property (copy, nonatomic) NSString                      * _Nullable fontName;
@property (copy, nonatomic) NSString                      * _Nullable fontCode;
@property (copy, nonatomic) NSString                      * _Nullable fontPath;
@property (assign, nonatomic) CGFloat                        fontSize;
@property (nonatomic, strong) UIView                        *labelBgView;
@property (strong, nonatomic) RDPasterLabel                 * _Nullable contentLabel;
@property (strong, nonatomic) RDPasterLabel                 *shadowLbl;
@property (strong, nonatomic) UIImageView                   * _Nullable contentImage;
@property (weak, nonatomic) id<RDPasterTextViewDelegate>   delegate;
@property (assign, nonatomic) BOOL                           needStretching;
@property (assign, nonatomic) float                          fps;
@property (assign, nonatomic) NSInteger                      typeIndex;
@property (assign, nonatomic) NSInteger                      typeLabelIndex;
@property (assign, nonatomic) BOOL                           isHiddenAlignBtn;
@property (assign, nonatomic) NSTextAlignment                alignment;
@property (copy, nonatomic  ) NSString                       *pText;

@property (nonatomic,assign) BOOL                           isLabelHeight;
@property (nonatomic,assign) CGSize tsize;
@property (nonatomic,assign) float rectW;//配置文件中，初始字幕大小，相对于实际视频size的字幕大小(0.0〜1.0)

@property (nonatomic,assign) BOOL                           isCutout;       //是否为抠图
@property (nonatomic,assign) float                          cutout_Height;
@property (nonatomic,assign) float                          cutoutHeight;
//设置x放大镜
-(void)setCutoutMagnifier:(bool) isCutout;
//放大镜
@property (nonatomic,strong) UIView                         *cutout_MagnifierView;
//放大区域
@property (nonatomic,strong) UIImageView                    * _Nullable cutout_ZoomAreaView;
//原始区域
@property (nonatomic,strong) UIImageView                    * _Nullable cutout_RealAreaView;
@property (nonatomic,strong) UILabel * cutout_label1;
@property (nonatomic,strong) UILabel * cutout_label2;

/**文字字体加粗，默认为NO*/
@property (nonatomic ,assign) BOOL isBold;
/**文字字体斜体，默认为NO*/
@property (nonatomic ,assign) BOOL isItalic;
/**文字字体阴影，默认为NO*/
@property (nonatomic ,assign) BOOL isShadow;
/**文字阴影颜色，默认黑色*/
@property (nonatomic ,strong) UIColor * _Nullable shadowColor;
/**文字阴影偏移量,默认为CGSizeMake(0, -1)*/
@property (nonatomic ,assign) CGSize shadowOffset;
/** 文字竖排，默认为NO*/
@property (nonatomic ,assign) BOOL isVerticalText;

@property (copy, nonatomic  ) NSString                       *pname;

- (instancetype)initWithFrame:(CGRect)frame
               superViewFrame:(CGRect)superRect
                 contentImage:(UIImageView *)contentImageView
            syncContainerRect:(CGRect)syncContainerRect;

- (instancetype _Nullable)initWithFrame:(CGRect)frame
             pasterViewEnbled:(BOOL)pasterViewEnbled
               superViewFrame:(CGRect)superRect
                 contentImage:(UIImageView * _Nullable)contentImageView
                    textLabel:(UILabel * _Nullable)textLabel
                     textRect:(CGRect )textRect
                      ectsize:(CGSize )tsize
                         ect:(CGRect )t
               needStretching:(BOOL)needStretching
                  onlyoneLine:(BOOL)onlyoneLine
                    textColor:(UIColor * _Nullable)textColor
                  strokeColor:(UIColor * _Nullable)strokeColor
                   strokeWidth:(float)strokeWidth
            syncContainerRect:(CGRect)syncContainerRect
                    isRestore:(BOOL)isREstroe;

- (void) hideEditingHandles;
- (void) setFontName:(NSString * _Nullable)fontName;
- (void) setTextString: (NSString * _Nullable) text adjustPosition:(BOOL)adjust;
- (void) setFramescale:(float)value;
- (float)getFramescale;
- (NSInteger)getTextAlign;
- (void)refreshBounds:(CGRect)bounds;
- (void)setContentImageTransform:(CGAffineTransform)transform;

+(CGRect)solveUIWidgetFuzzy:(CGRect) oldFrame;

-(float) selfscale;

//背景 画布
-(void)setCanvasPasterText:(BOOL) isCanvas;
//设置最小倍数
-(void)setMinScale:(float) scale;
@property (nonatomic ,assign)float minScale;

//
@property (nonatomic, assign)bool isDrag;
@property (nonatomic, assign)BOOL isDrag_Upated;
@property (nonatomic, assign)float dragaAlpha;

//加水印
-(void)setWatermarkPasterText:(BOOL) isWatermark;
@property (nonatomic,assign)float waterMaxScale;

- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer;
@end


