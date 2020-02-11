//
//  RDAdjustViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/3.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

/**水印位置
 */
typedef NS_ENUM(NSInteger,AdjustType){
    Adjust_Brightness,      //亮度
    Adjust_Contrast,        //对比度
    Adjust_Saturation,      //饱和度
    Adjust_Sharpness,       //锐度
    Adjust_WhiteBalance,    //色温
    Adjust_Vignette,        //暗角
} ;

@interface RDAdjustViewController : UIViewController

@property (nonatomic, strong) NSMutableArray  *globalFilters;
@property (nonatomic, assign) CGSize exportSize;
@property (nonatomic, copy) RDFile *file;

@property (nonatomic,copy) void (^changeAdjustFinish)(NSArray * floatArray, BOOL useToAll);

-(void)setVideoCoreSDK:(RDVECore *) core;
-(void)seekTime:(CMTime) time;
@end
