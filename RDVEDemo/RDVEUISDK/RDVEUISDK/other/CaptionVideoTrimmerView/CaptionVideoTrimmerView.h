//
//  ICGVideoTrimmerView.h
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "RDVECore.h"
#import "RDTTRangeSlider.h"
#import "CaptionRangeView.h"

typedef enum {
    kCannotAddCaptionforPiantou,
    kCannotAddCaptionforPianwei,
    kCanAddCaption,
} RdCanAddCaptionType;


@protocol CaptionVideoTrimmerDelegate;

@interface CaptionVideoTrimmerView : UIView

//画中画
@property (nonatomic,assign) bool isCollage;   //是否为画中画


@property (nonatomic,assign) bool isTiming;   //是否计时

@property (nonatomic,assign) bool isJumpTail;   //保存时是否需要跳转到尾部  


@property (nonatomic,assign) double changeScaleValue;

@property (nonatomic,assign) NSInteger thumbTimes;

@property(strong , nonatomic) RDVECore *videoCore;


@property (strong, nonatomic) UIColor *themeColor;

@property (assign, nonatomic) CGFloat maxLength;

@property (assign, nonatomic) CGFloat minLength;

@property (strong, nonatomic) UIImage *leftThumbImage;

@property (strong, nonatomic) UIImage *rightThumbImage;

@property (strong, nonatomic) UIImageView *contentView;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) UIView *frameView;

@property (strong, nonatomic) UIImageView *videoRangeView;

@property (assign, nonatomic) CGSize contentSize;

@property (assign, nonatomic) CGFloat borderWidth;

@property (weak, nonatomic) id<CaptionVideoTrimmerDelegate> delegate;

@property (assign, nonatomic) BOOL  loadImageFinish;

@property (assign, nonatomic) CMTimeRange  clipTimeRange;

@property (strong, nonatomic) RDTTRangeSlider *rangeSlider;
@property (strong, nonatomic) UILabel         *rangeTimeLabel;

@property (strong, nonatomic) CaptionRangeView *currentCaptionView;
@property (strong, nonatomic) CaptionRangeView *timeEffectCapation;

@property (copy, nonatomic) NSString *fontName;
@property (nonatomic, assign) float progress;
@property (nonatomic) CGFloat startTime;
@property (assign, nonatomic) float  piantouDuration;

@property (assign, nonatomic) float  pianweiDuration;

@property (assign, nonatomic) float rightSpace;//右边间距

- (instancetype)initWithFrame:(CGRect)frame videoCore:(RDVECore *)videoCore;

- (void)resetSubviews:(UIImage *)thumbImage;

- (void)refreshThumbImage:(NSInteger)index thumbImage:(UIImage *)thumbImage;

- (RdCanAddCaptionType)checkCanAddCaption;

- (CaptionRangeView *)addCapation:(NSString *)themeName type:(NSInteger )type captionDuration:(double)captionDuration;

- (BOOL)changecurrentCaptionViewTimeRange;

- (BOOL)changecurrentCaptionViewTimeRange:(Float64)captionDuration;

- (NSMutableArray *)getTimesFor_videoRangeView;

@property (nonatomic, assign) bool isFX;        //是否为特效进度条
- (NSMutableArray *)getTimesFor_videoRangeView_withTime;

- (bool)setProgress:(float)progress animated:(BOOL)animated;
- (void)setFrameRect:(CGRect)rect;

- (void)useToAllWithTypeToAll:(BOOL)typeToAll animationToAll:(BOOL)animationToAll colorToAll:(BOOL)colorToAll borderToAll:(BOOL)borderToAll fontToAll:(BOOL)fontToAll sizeToAll:(BOOL)sizeToAll positionToAll:(BOOL)positionToAll scale:(float)scale captionView:(CaptionRangeView *)captionRangeView;

- (void)checkAllCaptionSize;

//多段配乐
- (void)changeMulti_trackCurrentRangeviewFile:(RDMusic *)music
                             captionView:(CaptionRangeView *)captionRangeView;

//高斯模糊/马赛克/去水印
- (void)changeDewatermark:(id)dewatermark
                typeIndex:(RDDewatermarkType)type;

//画中画
- (void)changeCollageCurrentRangeviewFile:(RDWatermark *)collage
                               thumbImage:(UIImage *)thumbImage
                              captionView:(CaptionRangeView *)captionRangeView;
//涂鸦
- (void)changeDoodleCurrentRangeviewFile:(RDWatermark *)doodle
                              thumbImage:(UIImage *)thumbImage
                             captionView:(CaptionRangeView *)captionRangeView;
//字幕

- (void) changeCurrentRangeviewFile:(RDCaption *)caption
                             tColor:(UIColor *)tColor
                         strokeColor:(UIColor *)strokeColor
                           fontName:(NSString *)fontName
                           fontCode:(NSString *)fontCode
                          typeIndex:(NSInteger)typeIndex
                          frameSize:(CGSize)frameSize
                        captionText:(NSString *)captionText
                           aligment:(RDCaptionTextAlignment)aligment
                 inAnimateTypeIndex:(NSInteger)inAnimateTypeIndex
                outAnimateTypeIndex:(NSInteger)outAnimateTypeIndex
                        pushInPoint:(CGPoint)pushInPoint
                       pushOutPoint:(CGPoint)pushOutPoint
                        captionView:(CaptionRangeView *)captionRangeView;

- (void) changeCurrentRangeviewFile:(RDCaption *)caption
                          typeIndex:(NSInteger)typeIndex
                          frameSize:(CGSize)frameSize
                        captionText:(NSString *)captionText
                           aligment:(RDCaptionTextAlignment)aligment
                 captionAnimateType:(RDCaptionAnimateType)captionAnimateType
                 inAnimateTypeIndex:(NSInteger)inAnimateTypeIndex
                outAnimateTypeIndex:(NSInteger)outAnimateTypeIndex
                     pushInPoint:(CGPoint)pushInPoint
                       pushOutPoint:(CGPoint)pushOutPoint
                        captionView:(CaptionRangeView *)captionRangeView;

- (void)changeSubtitleTye:(RDCaption *)caption
                typeIndex:(NSInteger)typeIndex
                frameSize:(CGSize)frameSize
              captionView:(CaptionRangeView *)captionRangeView;

- (void)changeCurrentRangeviewWithAlpha:(float)alpha captionView:(CaptionRangeView *)captionRangeView;
- (void) changeCurrentRangeviewWithTColor:(UIColor *)tColor alpha:(float)alpha colorId:(NSInteger)colorId captionView:(CaptionRangeView *)captionRangeView;

- (void) changeCurrentRangeviewWithstrokeColor:(UIColor *)strokeColor borderWidth:(float )borderWidth alpha:(float)alpha borderColorId:(NSInteger)borderColorId captionView:(CaptionRangeView *)captionRangeView;

- (void) changeCurrentRangeviewWithShadowColor:(UIColor *)color width:(float )width colorId:(NSInteger)colorId captionView:(CaptionRangeView *)captionRangeView;

- (void) changeCurrentRangeviewWithBgColor:(UIColor *)color colorId:(NSInteger)colorId captionView:(CaptionRangeView *)captionRangeView;

- (void) changeCurrentRangeviewWithIsBold:(BOOL)isBold isItalic:(BOOL )isItalic isShadow:(BOOL)isShadow shadowColor:(UIColor *)shadowColor shadowOffset:(CGSize)shadowOffset captionView:(CaptionRangeView *)captionRangeView;

- (void) changeCurrentRangeviewWithFontName:(NSString *)fontName
                                   fontCode:(NSString *)fontCode
                                   fontPath:(NSString *)fontPath
                                     fontId:(NSInteger)fontId
                                captionView:(CaptionRangeView *)captionRangeView;
- (void) changeCurrentRangeviewWithNetCover:(NSString *)netCover
                                captionView:(CaptionRangeView *)captionRangeView;
- (void) changeCurrentRangeviewWithSubtitleAlignment:(RDSubtitleAlignment)subtitleAlignment captionView:(CaptionRangeView *)captionRangeView;

- (CaptionRangeView *)getCaptioncurrentView:(BOOL)flag;

- (void)touchesUpInslide;

- (void)refreshVideoRangeViewFromIndexPath:(NSInteger)fromIndex moveToIndex:(NSInteger)toIndex;

- (void)moveEditedSubviews:(NSArray *)editedArray restoreVideoRangeView:(NSArray *)originalSubviewsArray;

- (NSMutableArray *)getEditArrays:(BOOL)flag;

- (BOOL)deletedcurrentCaption;

- (NSMutableArray *)getCaptionsViewForcurrentTime:(BOOL)flag;//获取当前时间段可以编辑的特效段数组

//只适用于在同一时间有多个字幕的情况
- (CaptionRangeView *)getcurrentCaption:(NSInteger)captionId;

- (CaptionRangeView *)getcurrentCaptionFromId:(NSInteger)captionId;

//字幕
- (void)saveCurrentRangeview:(NSString *)captionText
                   typeIndex:(NSInteger) index
               rotationAngle:(float)rotationAngle
                   transform:(CGAffineTransform)captionTransform
                 centerPoint:(CGPoint)centerPoint
              ppcaptionFrame:(CGRect)ppcaptionFrame
              contentsCenter:(CGRect)contentsCenter
                      tFrame:(CGRect)tFrame
                  customSize:(float)captionLastScal
                 tStretching:(BOOL)tStretching
                    fontSize:(float)fontSize
                  strokeWidth:(float)strokeWidth
                    aligment:(RDCaptionTextAlignment)aligment
             inAnimationType:(CaptionAnimateType)inAnimationType
            outAnimationType:(CaptionAnimateType)outAnimationType
                 pushInPoint:(CGPoint)pushInPoint
                pushOutPoint:(CGPoint)pushOutPoint
             widthProportion:(CGFloat)widthProportion
                   themeName:(NSString *)themeName
                       pSize:(CGSize)pSize
                        flag:(BOOL)flag
                 captionView:(CaptionRangeView *)captionRangeView;

//去水印
- (void)saveCurrentRangeview:(BOOL)isScroll;

//画中画
- (void)saveCollageCurrentRangeview:(BOOL)isScroll
                      rotationAngle:(float)rotationAngle
                          transform:(CGAffineTransform)transform
                        centerPoint:(CGPoint)centerPoint
                              frame:(CGRect)frame
                     contentsCenter:(CGRect)contentsCenter
                              scale:(float)scale
                              pSize:(CGSize)pSize
                         thumbImage:(UIImage *)thumbImage
                   captionRangeView:(CaptionRangeView *)captionRangeView;

- (void)showOrHiddenAddBtn;

- (void)clearCaptionRangeVew;

- (void)clear;

-(void)SetCaptionType:(CGFloat) fcaptionType;

-(CGFloat)CaptionType;

//固定截取 所用
- (void)resetSubviews:(UIImage *)thumbImage  picWidth:(float) picWidth;
@property (nonatomic,assign) float trimDuration_OneSpecifyTime;

-(void)cancelCurrent;

//特效
//添加
- (CaptionRangeView *)addCapation:(NSString *)themeName type:(NSInteger )type captionDuration:(double)captionDuration genSpecialFilter:(RDFXFilter *) customFilter;
-(BOOL)deleteFilterCaption;
-(void)setTimeEffectCapation:(CMTimeRange ) timeRange atisShow:(BOOL) isShow;

-(void)SetCurrentCaptionView:( CaptionRangeView * ) rangeV;

-(void)setisSeektime:(BOOL) Seektime;
@end

@protocol CaptionVideoTrimmerDelegate <NSObject>
@optional

- (void)didEndChangeSelectedMinimumValue_maximumValue;

- (void)startMoveTTrangSlider:(id)view;

- (void)stopMoveTTrangSlider:(id)view;

- (void)capationScrollViewWillBegin:(CaptionVideoTrimmerView *)trimmerView;

- (void)capationScrollViewWillEnd:(CaptionVideoTrimmerView *)trimmerView
                        startTime:(Float64)capationStartTime
                          endTime:(Float64)capationEndTime;

- (void)touchescurrentCaptionView:(CaptionRangeView *)rangeView;

- (void)touchescurrentCaptionView:(CaptionVideoTrimmerView *)trimmerView
                      showOhidden:(BOOL)flag
                        startTime:(Float64)captionStartTime;

-(void)TimesFor_videoRangeView_withTime:(int) captionId;

- (void)changeCaptionViewType:(CaptionRangeView *)captionRangeView;

-(void)dragRangeSlider:(float) x dragStartTime:(float) dragStartTime dragTime:( float ) dragTime isLeft:(float) isleft isHidden:(BOOL) isHidden;

-(void)deleteMaterialEffect_Effect:(NSString *) strPatch;

@required
- (void)trimmerView:(id)trimmerView
didChangeLeftPosition:(CGFloat)startTime
      rightPosition:(CGFloat)endTime;



@end
// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com
