//
//  RDWordSayTextLayerParam.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/12.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger,RDDisplayAnimation){
    RDDisplayAnimation_None = 0,               //无
    RDDisplayAnimation_Zoom,                   //缩放
    RDDisplayAnimation_Pan_UpAndDown,          //平移 上下
    RDDisplayAnimation_Swing_UpAndDown,        //摇摆 上下
    RDDisplayAnimation_Swing_BeforeAndAfter,   //摇摆 左右
};

@interface RDWordSayTextLayerParam : NSObject


+(RDWordSayTextLayerParam*)initWordSayTextLayerParam:(CATextLayer *) textlayer atRadian:(float) radian atIsText:(BOOL) isText;

@property(nonatomic,strong)CATextLayer *textLayer;      //字说绘制对象

@property (nonatomic, assign)bool       isText;         //是否为文字

@property (nonatomic, assign)float      textRadian;     //字说旋转弧度

@property (nonatomic, assign)CGPoint    textPoint;      //字说坐标
@property (nonatomic, assign)CGPoint    textAnchor;     //字说锚点

@property (nonatomic, assign)float      textFactor;
@property (nonatomic, assign)CGPoint    textFactorPoint;

@property (nonatomic, assign)CMTime     textStartTime;      //显示开始时间
@property (nonatomic, assign)CMTime     AnimationTime;
@property (nonatomic, assign)CMTime     textShowTime;       //展示结束时间

@property (nonatomic, assign)CMTime     textRotationTime;   //旋转时间 用于需要旋转的自绘对象

@property (nonatomic, assign)int        textRadinIndex;     //显示该文字自绘需要旋转之前的字说绘制对象 对应的h组合的序号

@property (nonatomic, assign)int        textLayerIndex;     //该自绘对象为字说自绘h组合时 启用 表示 对应的在当前序号下得自绘对象出现时 需要开始旋转

//动画
@property(nonatomic,assign)RDDisplayAnimation          textDisplayAnimation;

@property(nonatomic,assign)int          textIndex;
//字体放大倍速
@property (nonatomic, assign)float      textFontSizeSpeed;
@property (nonatomic, assign)float      textCurrentFontSizeSpeed;

@property (nonatomic,assign)CGSize      textSize;

@property (nonatomic, assign)float      textCurrentFontSize;

@end

NS_ASSUME_NONNULL_END
