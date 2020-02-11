//
//  RDEditVideoViewController.h
//  RDVEUISDK
//
//  Created by emmet on 2017/6/26.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDVEUISDKConfigure.h"

@interface RDEditVideoViewController : UIViewController


@property(nonatomic,strong)RDVECore         *nextVideoCoreSDK;

@property(nonatomic,strong)RDVECore         *thumbImageVideoCore;

@property (nonatomic,copy)  void(^NextEditThumbImageVideoCoreBlock)(NSMutableArray <RDFile *>* fileList) ;

@property(nonatomic,assign)BOOL           isNoBackground;        //是否无背景


@property(nonatomic,assign)BOOL           isMotion;              //是否图片运动

@property(nonatomic,strong)NSMutableArray <RDFile *>*fileList;
//是否模糊
@property(nonatomic,assign)BOOL           isVague;              //是否模糊背景
@property(nonatomic,assign)FileCropModeType proportionIndex;
@property(nonatomic,strong)NSMutableArray <RDWatermark*>*collages;
@property(nonatomic,strong)NSMutableArray <RDWatermark*>*doodles;
/**视频背景颜色
 */
@property(nonatomic,strong)UIColor             *videoBackgroundColor;
/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;
@property(nonatomic,assign)BOOL             push;
@property(nonatomic,assign)BOOL             fromToNext;
@property(nonatomic,strong)NSMutableArray *filterFxArray;

//设置界面相关----------------------------------------
@property (nonatomic,copy  ) RdVECancelBlock           cancelBlock;
@property (nonatomic,copy  ) void(^backNextEditVideoVCBlock)(NSArray *fileList,CGSize exportVideoSize,CMTime currentTime);
@property (nonatomic,copy)  void(^backNextEditVideoCancelBlock)(RDVECore * core,CMTime currentTime) ;
//--------------------------------

@property (nonatomic,copy)void(^transtionFinishAction)(NSInteger transtionType,NSString *transitionName,double transitionDuration,NSURL *maskUrl,BOOL useAllTranstion,BOOL defaultTranstion,NSArray *systemTransitions,NSArray *e2eTransitionFoodFiles);


//设置视频分辨率
-(void)setExportSize:(CGSize) Size;

-(void)setScenes:(NSMutableArray *) Scenes;

-(void)setCurrentTime:(CMTime) time;

-(void)SetSelectFileIndex:(int) index;

@property (nonatomic,strong)RDWatermark *watermark;              //加水印 画中画
@end


