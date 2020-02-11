//
//  UICliper.h
//  image
//
//  Created by 岩 邢 on 12-7-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CropDelegate <NSObject>

- (void)cropViewDidChangeClipValue:(CGRect)rect clipRect:(CGRect)clipRect;

- (BOOL)touchUpinslidePlayeBtn;

- (void)touchesEndSuperView;

@end


typedef NS_ENUM(NSInteger,CropTouchPoint){
    CropNone          = 0,
    CropLeftTop       = 1,
    CropRightTop      = 2,
    CropLeftButtom    = 3,
    CropRightButtom   = 4,
    CropLeftMid       = 5,
    CropRightMid      = 6,
    CropTopMid        = 7,
    CropButtomMid     = 8,
    CropMid           = 9
};

@interface RDUICliper : UIView
{
    
    CGRect cliprect;
    CGColorRef grayAlpha;
    CGPoint touchPoint;
    CGPoint touchBeginPoint;
    BOOL freedom;
    
    //For Clips
    CGRect oFrame;
    CGSize videoSize;
    
    CropTouchPoint cropTouchPoint;
    NSString *textStr;
    BOOL isMoving;//移动
    
}
@property (nonatomic,assign)FileCropModeType crop_Type;
@property (nonatomic,strong)UIButton *playBtn;
@property (nonatomic,assign)NSInteger fileType;
@property (nonatomic,weak)id <CropDelegate>delegate;
@property (nonatomic,assign)BOOL isOutsideTransparent;//区域外透明
@property (nonatomic,assign)float minEdge;

- (id)initWithView:(UIView*)iv freedom:(BOOL )bFree;

- (void)setVideoSize:(CGSize )size;//视频本身分辨率

- (void)setFrameRect:(CGRect )frame;//界面实际大小

- (void)setCropType:(FileCropModeType )type;//界面实际大小

- (void)setCropText:(NSString *)text;//

- (void)ChangeclipEDGE:(float)x1 x2:(float)x2 y1:(float)y1 y2:(float)y2;

- (void)setclipEDGE:(CGRect)rect;

- (CGRect)getclipRect;

- (CGFloat)getclipRectScale;

-(void)setClipRect:(CGRect)rect;

- (CGRect)getclipRectFrame;

- (void)playerVideo:(BOOL) isPlay;
@end
