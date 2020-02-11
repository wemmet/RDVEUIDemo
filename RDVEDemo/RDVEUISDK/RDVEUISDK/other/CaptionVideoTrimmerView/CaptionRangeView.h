//
//  captionRangeView.h
//  RDVEUISDK
//
//  Created by emmet on 15/9/28.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDDraftDataModel.h"
#import "RDFXFilter.h"
//对齐方式
/**
 UIRectCornerTopLeft     = 1 << 0,
 UIRectCornerTopRight    = 1 << 1,
 UIRectCornerBottomLeft  = 1 << 2,
 UIRectCornerBottomRight = 1 << 3,
 */
typedef NS_ENUM(NSInteger, RDSubtitleAlignment) {
    RDSubtitleAlignmentUnknown = 0,
    RDSubtitleAlignmentTopLeft,         //左上
    RDSubtitleAlignmentTopCenter,       //上居中
    RDSubtitleAlignmentTopRight,        //右上
    RDSubtitleAlignmentLeftCenter,      //左居中
    RDSubtitleAlignmentCenter,          //水平垂直居中
    RDSubtitleAlignmentRightCenter,     //右居中
    RDSubtitleAlignmentBottomLeft,      //左下
    RDSubtitleAlignmentBottomCenter,    //下居中
    RDSubtitleAlignmentBottomRight,     //右下
};
//轻移方向
typedef NS_ENUM(NSInteger, RDMoveSlightlyDirection) {
    RDMoveSlightlyLeft = 0,
    RDMoveSlightlyTop,
    RDMoveSlightlyBottom,
    RDMoveSlightlyRight,
};

@interface RDCaptionRangeViewFile : RDDraftDataModel

@property(assign,nonatomic)CMTimeRange  timeRange;
@property(strong,nonatomic)RDCaption    *caption;//字幕、贴纸
@property(strong,nonatomic)RDAssetBlur  *blur;//高斯模糊
@property(strong,nonatomic)RDMosaic     *mosaic;//马赛克
@property(strong,nonatomic)RDDewatermark *dewatermark;//去水印

@property(assign,nonatomic)float        rotate;     //旋转

@property(strong,nonatomic)RDWatermark  *collage;//画中画
//画中画 滤镜
@property(nonatomic,assign)NSInteger     collageFilterIndex;

@property(strong,nonatomic)RDWatermark  *doodle;//涂鸦

@property(strong,nonatomic)RDFXFilter * customFilter; //特效
@property (nonatomic, assign) int fxId;
@property(strong,nonatomic)NSString *currentFrameTexturePath;
@property (nonatomic, assign) bool  isErase;

@property(strong,nonatomic)RDMusic      *music; //配乐

@property(assign,nonatomic)NSInteger    captiontypeIndex;
@property(copy,nonatomic)NSString     *captionText;
@property(assign,nonatomic)float        rotationAngle;
@property(assign,nonatomic)CGAffineTransform captionTransform;
@property(assign,nonatomic)CGPoint      centerPoint;
@property(assign,nonatomic)float        scale;
@property(assign,nonatomic)NSInteger    captionId;
@property(strong,nonatomic)UIColor      *tColor;
@property(strong,nonatomic)UIColor      *strokeColor;
@property(strong,nonatomic)UIColor      *shadowColor;
@property(strong,nonatomic)UIColor      *bgColor;
@property(copy,nonatomic)NSString       *fontName;
//@property(copy,nonatomic)NSString       *fontCode;//20191227 有用吗？
@property(copy,nonatomic)NSString       *fontPath;
@property(assign,nonatomic)float         tFontSize;
@property(copy,nonatomic)NSString       *title;
@property(assign,nonatomic)BOOL          deleted;
@property(assign,nonatomic)CGSize        frameSize;
@property(assign,nonatomic)CGRect        home;
@property(strong,nonatomic)UIImage      *thumbnailImage;
@property(assign,nonatomic)CGSize        pSize;
@property(assign,nonatomic)CGSize        cSize;
@property(copy,nonatomic)NSString       *netCover;
@property(assign,nonatomic)float        rectW;//配置文件中，初始字幕大小，相对于实际视频size的字幕大小(0.0〜1.0)
@property (nonatomic,assign) int        selectTypeId;
@property (nonatomic,assign) NSInteger     selectColorItemIndex;
@property (nonatomic,assign) NSInteger     selectBorderColorItemIndex;
@property (nonatomic,assign) NSInteger     selectShadowColorIndex;
@property (nonatomic,assign) NSInteger     selectBgColorIndex;
@property (nonatomic,assign) NSInteger     inAnimationIndex;
@property (nonatomic,assign) NSInteger     outAnimationIndex;
@property (nonatomic,assign) NSInteger     selectFontItemIndex;
@property (nonatomic,assign) RDSubtitleAlignment alignment;
@end

@protocol RDCaptionRangeViewFile <NSObject>

@end

@interface CaptionRangeView : UIButton

@property(strong,nonatomic)UIImageView * displayImageView;

@property(assign,nonatomic)NSInteger    captionType;

@property(strong, nonatomic)RDCaptionRangeViewFile *file;
@property(assign,nonatomic)NSInteger    index;
@end
