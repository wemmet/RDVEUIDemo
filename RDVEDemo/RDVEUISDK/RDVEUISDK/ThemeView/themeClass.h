//
//  themeClass.h
//  RDVEUISDK
//
//  Created by apple on 2018/8/15.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDVEUISDKConfigure.h"

//视频输出分辨率 模式
typedef NS_ENUM(NSInteger, VideoResolvPowerType)
{
    VideoResolvPower_Film,                       //胶片
    VideoResolvPower_Square,                     //正方向
    VideoResolvPower_Portait,                    //纵向
};

//多媒体 图片效果
typedef NS_ENUM(NSInteger, VVAssetImage_EffectType)
{
    VVAssetImage_Effect_ZOOM,                   //图片缩放 图片边界也变化
    VVAssetImage_Effect_PushDown,               //图片下推
    VVAssetImage_Effect_PushUp,                 //图片上推
  
    VVAssetImage_Effect_RotateZoom,             //图片旋转缩放
    VVAssetImage_Effect_Default,                //默认
    VVAssetImage_Effect_ProEnlarge,             //渐进放大
    VVAssetImage_Effect_LeftShift,              //左移缩小
    VVAssetImage_Effect_RightShift,             //右移缩小
    VVAssetImage_Effect_CentralReduction,       //中心缩小
    VVAssetImage_Effect_BandW,                  //黑白
    
    //用于 图片分段推进 整体向下推
    VVAssetImage_Effect_PushUp1,                 //图片上推1
    VVAssetImage_Effect_PushDown1,              //图片下推1
    //用于 图片分段推进 整体向上推
    VVAssetImage_Effect_PushUp2,                 //图片上推2
    VVAssetImage_Effect_PushDown2,              //图片下推2
    
    VVAssetImage_Effect_vague,                  //模糊
};

//图片效果 自制
typedef NS_ENUM(NSInteger, ThemeImage_EffectType)
{
    Image_Effect_Default,                       //默认
    Image_Effect_Enlarge,                       //放大
    Image_Effect_Narrow,                        //缩小
    Image_Effect_PushDown,                      //下推
    Image_Effect_PushUp,                        //上推
    Image_Effect_BandW,                         //黑白
    Image_Effect_Fade,                         //淡入
    Image_Effect_FlashBlack,                    //闪黑
    Image_Effect_RotateEnlarge,                 //放大旋转
    Image_Effect_LeftPush,                      //左推
    Image_Effect_RightPush,                     //右推
    Image_Effect_EnlargeSideChange,             //放大 边界变化
    Image_Effect_ProEnlarge,                    //渐进放大
    Image_Effect_PushProEnlarge,                //上下左右推然后放大
    Image_Effect_PiecewiseDown,                 //分段下推
    Image_Effect_PiecewiseUp,                   //分段上推
    Image_Effect_FlickerAndWhite,               //闪白
    Image_Effect_vague,                        //模糊
    Image_Effect_EnlargeVague,                 //模糊放大
    Image_Effect_TransitionTypeInvert,         //闪白-黑白/反色-反色/黑白-黑白
    Image_Effect_BlinkWhiteGray,               //闪白-中间白色/上下黑白-中间白色/上下原图-原图
    Image_Effect_BulgeDistortion,              //鱼眼
};

//特效
typedef NS_ENUM(NSInteger, Effect)
{
    Effect_Grammy,
    Effect_Action,
    Effect_Boxed,
    Effect_Lapse,
    Effect_Slice,
    Effect_Serene,
    Effect_Flick,
    Effect_Raw,
    Effect_Epic,
    Effect_Light,
    Effect_Sunny,
    Effect_Jolly,
    Effect_Snappy,
    Effect_Tinted,
    Effect_Tender,
    Effect_Over,
    //Image_Effect_PushProEnlarge,                //放大
};

@interface themeClass : NSObject
{
    VideoResolvPowerType                                videoResolvPowerType;   //视频分辨率输出模式
}
@property(nonatomic,strong)NSMutableArray <RDFile *>    *fileList;              //多媒体文件详细信息
-(void) setVideoSize:(CGSize )videoSize atEndTime:(float) endTime;
-(void) setFileList:(NSMutableArray <RDFile *>*) fileList atEndTime:(float) endTime videoSize:(CGSize )videoSize;

-(void) SetVideoResolvPowerType:(VideoResolvPowerType) Type;

//Grammy
-(void) GetGrammyEffect:(NSMutableArray *) scenes;
//Action
-(void) GetActionEffect:(NSMutableArray *) scenes;
//Boxed
-(void) GetBoxedEffect:(NSMutableArray *) scenes;
//Lapse
-(void) GetLapseEffect:(NSMutableArray *) scenes;
//Slice
-(void) GetSliceEffect:(NSMutableArray *) scenes;
//Raw
- (void)GetRawEffect:(NSMutableArray *)scenes;
//Sunny
- (void)GetSunnyEffect:(NSMutableArray *)scenes;
//serene
-(void) GetSerene:(NSMutableArray *) scenes;
//Flick
-(void)GetFlick:(NSMutableArray *) scenes;
//Epic
-(void)GetEpicEffect:(NSMutableArray *) scenes;
//Jolly
-(void)GetJolly:(NSMutableArray *) scenes;
//Snappy
-(void)GetSnappyEffect:(NSMutableArray *) scenes;
//Over
-(void)GetOverEffect:(NSMutableArray *) scenes;
@end
