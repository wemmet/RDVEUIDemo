//
//  RDDraftInfo.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDDraftDataModel.h"
#import "RDDraftCaption.h"
#import "CaptionRangeView.h"
#import "DubbingRangeView.h"
#import "RDDraftEffect.h"

@interface RDDraftInfo : RDDraftDataModel

/**草稿UUID
 */
@property (nonatomic, strong) NSString *draftUUID;

/** 视频修改时间，可用于草稿箱排序
 */
@property (nonatomic, strong) NSDate *modifyTime;

/** 作品所包含的素材列表
 */
@property (nonatomic, strong) NSMutableArray <RDFile>* fileList;

/**视频时长
 */
@property (nonatomic, assign) float duration;

/**视频导出分辨率
 */
@property (nonatomic, assign) CGSize exportSize;

/**原音音量
 */
@property (nonatomic, assign) float volume;

/**配乐
 */
@property (nonatomic, assign) NSInteger musicIndex;
    
/**原音是否开启
 */
@property (nonatomic, assign) BOOL originalOn;

/**变声
 */
@property (nonatomic, assign) NSInteger soundEffectIndex;

/**音调
 */
@property (nonatomic, assign) float pitch;

/**滤镜
 */
@property (nonatomic, assign) NSInteger filterIndex;

/**MV
 */
@property (nonatomic, assign) NSInteger mvIndex;

/**配乐
 */
@property (nonatomic, strong) NSMutableArray <RDDraftMusic> *musics;

/**音效
 */
@property (nonatomic, strong) NSMutableArray <RDDraftMusic> *soundMusics;
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* soundMusicFiles;
/**多段配乐
 */
@property (nonatomic, strong) NSMutableArray <RDDraftMusic> *multi_trackMusics;
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* multi_trackMosaicFiles;

/**配音
 */
@property (nonatomic, strong) NSMutableArray <DubbingRangeViewFile> *dubbings;

/**字幕
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile> *captions;

/**贴纸
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* stickers;

/**高斯模糊
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* blurs;

/**马赛克
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* mosaics;

/**去水印
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* dewatermarks;

/**画中画
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* collages;

/**涂鸦
 */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* doodles;

/**MV
 */
@property (nonatomic, strong) NSMutableArray <RDDraftMovieEffect> *movieEffects;

//----------------------------------------特效----------------------------------------/
/**自定义滤镜特效数组
 */
@property (nonatomic, strong) NSMutableArray <RDDraftEffectFilterItem> *filterArray;
/**时间特效类型
 */
@property (nonatomic, strong) NSMutableArray <RDDraftEffectTime> *timeEffectArray;

//@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile> *customFilterMusicFiles;

/**特效
  */
@property (nonatomic, strong) NSMutableArray <RDCaptionRangeViewFile>* fXFiles;

//比例
@property (nonatomic, assign) CGSize    proportionVideoSize; //比例视频分辨率
@property (nonatomic, assign) NSInteger oldProportionIndex;

//背景颜色
@property (nonatomic, assign) BOOL      isVague;              //是否模糊背景
@property (nonatomic, assign) BOOL      oldisNoBackground;        //是否无背景
@property (nonatomic, assign) int       oldBackgroundColorIndex;  //旧 背景颜色编号
@property (nonatomic, assign) int       proporBackgroundColorIndex;
@property (nonatomic, assign) float     videoBackgroundColorR;
@property (nonatomic, assign) float     videoBackgroundColorG;
@property (nonatomic, assign) float     videoBackgroundColorB;
@property (nonatomic, assign) float     videoBackgroundColorA;

//图片运动
@property (nonatomic, assign) int       oldIsEnlarge;           //是否放大

//封面
@property (nonatomic, strong) RDFile *coverFile;

//是否15秒MV
@property (nonatomic, assign) BOOL      is15S_MV;

/**加水印
*/
@property (nonatomic,strong)NSMutableArray <RDCaptionRangeViewFile>* watermarkCollage;

@property (nonatomic, assign) float watermarkSizeVolume;
@property (nonatomic, assign) float watermarkAlhpavolume;
@property (nonatomic, assign) float watermarkRotatevolume;

@end
