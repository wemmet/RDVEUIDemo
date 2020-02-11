//
//  RDAddEffectsByTimeline.h
//  RDVEUISDK
//
//  Created by apple on 2019/4/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptionVideoTrimmerView.h"
#import "SubtitleScrollView.h"
#import "SubtitleEffectScrollView.h"
#import "RDATMHud.h"
#import "RDUICliper.h"
#import "DrawView.h"
#import "RDAddItemButton.h"

#import "editCollageView.h"

#define kFxIconTag 1000
#define kFxProgressViewTag    999
#define kFxScrollViewTag  2000
#define kTransitionFxId 71 //后台返回的“转场”特效分类id
#define kFreezeFrameFxId 575550 //后台返回的“定格”特效分类id

@protocol RDAddEffectsByTimelineDelegate <NSObject>

@optional
-(void)seekToTime:(CMTime)time;

- (void)pushOtherAlbumsVC:(UIViewController *)otherAlbumsVC;

- (void)pauseVideo;

- (void)playOrPauseVideo;
- (void)previewWithTimeRange:(CMTimeRange)timeRange;

- (void)changeCurrentTime:(float)currentTime;

- (void)addMaterialEffect;
- (void)addingStickerWithDuration:(float)addingDuration captionId:(int ) captionId;

- (void)cancelMaterialEffect;

- (void)deleteMaterialEffect;

/** 更新效果
 *  @param  isSaveEffect    是否完成添加/编辑
 */
- (void)updateMaterialEffect:(NSMutableArray *)newEffectArray
                newFileArray:(NSMutableArray *)newFileArray
                isSaveEffect:(BOOL)isSaveEffect;
                 
- (void)updateDewatermark:(NSMutableArray *)newBlurArray
         newBlurFileArray:(NSMutableArray *)newBlurFileArray
           newMosaicArray:(NSMutableArray *)newMosaicArray
           newMosaicArray:(NSMutableArray *)newMosaicFileArray
      newDewatermarkArray:(NSMutableArray *)newDewatermarkArray
        newDewatermarkFileArray:(NSMutableArray *)newDewatermarkFileArray
             isSaveEffect:(BOOL)isSaveEffect;

/** 撤销上一个涂鸦
 */
- (void)revokePrevDoodle;

-(void)addingMusic:(RDMusic *) music;

- (void)prepareSpeechRecog;
- (void)uploadSpeechFailed:(NSString *)errorMessage;

-(void)TimesFor_videoRangeView_withTime:(int)captionId;

/** 改变去水印类型、位置、大小
 */
- (void)changeDewatermarkType:(RDDewatermarkType)type dewatermarkRectView:(RDUICliper *)dewatermarkRectView;

//特效
-(void)hiddenView;
-(void)deleteMaterialEffect_Effect:(NSString *) strPatch;
//预览 特效
-(void)previewFx:(RDFXFilter *) fxFilter;

//画中画 编辑
-(void)showCollageBarItem:( RDPIPFunctionType ) pipType;
-(void)collage_initPlay;

@end

@interface RDAddEffectsByTimeline : UIView
{
}

@property (nonatomic,assign) bool   isBlankCaptionRangeView;

@property (nonatomic,assign) bool   isBuild;                //判断 直接进入添加界面 点击取消是否不需要build

@property(nonatomic,strong)NSLock *lock; 

@property (nonatomic,assign) bool isPlay;                   //用于 画中画和涂鸦 的时候 点击播放按钮直接播放

@property (nonatomic,assign) bool isCover;

@property(nonatomic,strong)UIView                               *playBtnView;   //播放按钮界面
@property(nonatomic,strong)UIButton                             *playBtn;       //播放按钮

@property(nonatomic,strong)CaptionVideoTrimmerView              *trimmerView;   //滚动条
@property(nonatomic,strong)UILabel                              *durationTimeLbl;//总时间
@property(nonatomic,strong)UILabel                              *currentTimeLbl;//当前播放时间
@property(nonatomic,strong)UIView                               *dragTimeView;   //调整当前的拖拽时间显示
@property(nonatomic,strong)UILabel                              *dragTimeLbl;//当前播放时间
@property(nonatomic,strong)UIButton                             *addBtn;        //添加效果按钮
@property(nonatomic,strong)UIButton                             *finishBtn;     //保存效果按钮
@property(nonatomic,strong)UIButton                             *deletedBtn;    //删除效果按钮
@property(nonatomic,strong)UIButton                             *cancelBtn;     //取消效果按钮
@property(nonatomic,strong)UIButton                             *editBtn;       //编辑效果按钮
@property(nonatomic,strong)UIButton                             *speechRecogBtn;//语音识别
@property(nonatomic,strong)NSMutableArray                       *requestIdArray;
@property(nonatomic,assign)int                                  speechRecogCount;//超过60秒还没有语音识别完就取消识别
@property(nonatomic,strong)NSTimer                              *speechRecogTimer;//
@property(nonatomic,strong)NSMutableArray                       <RDFile *>*fileList;

@property(nonatomic,strong)RDVECore *thumbnailCoreSDK;

@property(nonatomic,strong)RDPasterTextView *pasterView;
@property(nonatomic,strong)syncContainerView *syncContainer;
@property(nonatomic,strong) EditConfiguration *editConfiguration;
@property(nonatomic,copy)NSString *appKey;
@property(nonatomic,assign)CGSize exportSize;
@property(nonatomic,strong)RDATMHud *hud;
@property(nonatomic,strong)UIView *playerView;
@property (nonatomic, assign)NSInteger currentMaterialEffectIndex;
@property (nonatomic, strong) UIScrollView *albumScrollView;

@property (nonatomic, strong)RDCaptionRangeViewFile *oldMaterialEffectFile;


@property(nonatomic,weak)id<RDAddEffectsByTimelineDelegate>   delegate;

@property(nonatomic,assign)RDAdvanceEditType                        currentEffect;                       //当前效果

@property(nonatomic,assign)BOOL isAddingEffect;
@property(nonatomic,assign)BOOL isEdittingEffect;
@property(nonatomic,assign)BOOL isSettingEffect;//设置去水印中
@property(nonatomic,assign)CMTime refreshCurrentTime;

@property(nonatomic,strong)NSDictionary    *subtitleEffectConfig;
@property(nonatomic,copy)NSString        *subtitleEffectConfigPath;
@property(nonatomic,assign)BOOL            stopAnimated;
//音效
@property(nonatomic,strong)CaptionVideoTrimmerView              *soundTrimmerView;   //滚动条

//多段配乐
@property(nonatomic,strong)CaptionVideoTrimmerView              *multi_trackTrimmerView;   //滚动条


//字幕
@property(nonatomic,assign)CGPoint                              pasterTextPoint;
@property(nonatomic,strong)CaptionVideoTrimmerView              *subtitleTrimmerView;   //滚动条
@property(nonatomic,strong)SubtitleScrollView                   *subtitleConfigView;

//贴纸
@property(nonatomic,strong)CaptionVideoTrimmerView              *stickerTrimmerView;   //滚动条
@property(nonatomic,strong)SubtitleEffectScrollView             *stickerConfigView;

//去水印
@property(nonatomic, strong)CaptionVideoTrimmerView             *dewatermarkTrimmerView;   //滚动条
@property(nonatomic, strong)RDUICliper                          *dewatermarkRectView;
@property(nonatomic, assign)RDDewatermarkType                   selectedDewatermarkType;
@property(nonatomic, strong)UIView                              *dewatermarkTypeView;
@property(nonatomic, strong)UISlider                            *dewatermakSlider;
@property(nonatomic, strong)UILabel                             *dewatermakCurrentLabel;
@property(nonatomic, strong)UIView                              *degreeView;

@property(nonatomic, assign)BOOL                                isMosaic;       //是否马赛克

//画中画
@property(nonatomic,strong)CaptionVideoTrimmerView              *collageTrimmerView;   //滚动条
@property (nonatomic, strong) UIView *albumView;
@property (nonatomic, strong) UIView *albumTitleView;
@property (nonatomic, strong) NSMutableArray *videoArray;
@property (nonatomic, strong) NSMutableArray *picArray;
@property(nonatomic,strong)RDATMHud *collageHud;

@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画

@property (nonatomic, strong) editCollageView *EditCollageView;

//画中画编辑

//涂鸦
@property(nonatomic,strong)CaptionVideoTrimmerView              *doodleTrimmerView;   //滚动条
@property(nonatomic,strong)DrawView *doodleDrawView;
@property (nonatomic, strong) UIView *doodleConfigView;

//特效
@property(nonatomic,copy) UIImage                              *currentFXFrameTexture;
@property(nonatomic,assign) BOOL                                isFXFrist;

@property(nonatomic,strong) RDFXFilter                          *timeFxFilter;           //时间特效
@property(nonatomic,assign) int                                 currentFXIndex;
@property(nonatomic,assign) int                                 currentFXLabelIndex;    //特效当前分类

@property(nonatomic,strong)NSMutableArray                       *filterFxArray;         //特效分类

@property(nonatomic,strong)CaptionVideoTrimmerView              *fXTrimmerView;         //滚动条

@property(nonatomic,strong)UIView                               *fXConfigView;

@property(nonatomic,strong)UIScrollView                         *fXLabelScrollView;     //特效分类
@property(nonatomic,strong)UIScrollView                         *currentFXScrollView;   //当前选中特效分类
//特效 选中 取消 界面
@property(nonatomic,strong)UIView                               *fXLabelView;
@property(nonatomic,strong)UIButton                             *fxSaveBtn;             //保存按钮
@property(nonatomic,strong)UIButton                             *fxCancelBtn;           //取消按钮

- (void)prepareWithEditConfiguration:(EditConfiguration *)editConfiguration
                              appKey:(NSString *)appKey
                          exportSize:(CGSize)exportSize
                          playerView:(UIView *)playerView
                                 hud:(RDATMHud *)hud;

- (void)editAddedEffect;
- (void)discardEdit;//放弃编辑

/** 开始添加效果
 */
- (void)startAddMaterialEffect:(CMTimeRange)timeRange;
- (void)cancelEffectAction:(UIButton *)sender;
- (void)finishEffectAction:(UIButton *)sender;
- (void)deleteEffectAction:(UIButton *)sender;
- (BOOL)checkStickerIconDownload;
- (BOOL)checkSubtitleIconDownload;
- (RDCaption *)getCurrentCaptionConfig;
- (RDPasterTextView *)newCreateCurrentlyEditingLabel:(NSInteger)subtitleOrEffect caption:(RDCaption *)caption;
- (void)clear;
/** 刷新缩略图
 */
- (void)loadTrimmerViewThumbImage:(UIImage *)image
                   thumbnailCount:(NSInteger)thumbnailCount
                   addEffectArray:(NSMutableArray *)addEffectArray
                    oldFileArray:(NSMutableArray <RDCaptionRangeViewFile *>*)oldFileArray;

- (void)loadDewatermarkThumbImage:(UIImage *)image
                   thumbnailCount:(NSInteger)thumbnailCount
                        blurArray:(NSMutableArray *)blurArray
                 oldBlurFileArray:(NSMutableArray <RDCaptionRangeViewFile *>*)oldBlurFileArray
                      mosaicArray:(NSMutableArray *)mosaicArray
               oldMosaicFileArray:(NSMutableArray <RDCaptionRangeViewFile *>*)oldMosaicFileArray
                 dewatermarkArray:(NSMutableArray *)dewatermarkArray
          oldDewatermarkFileArray:(NSMutableArray <RDCaptionRangeViewFile *>*)oldDewatermarkFileArray;
//字幕
- (void)pasterViewDidClose:(RDPasterTextView *)sticker;
- (void)previewCompletion;

- (void)saveSubtitleOrEffectWithPasterView:(RDPasterTextView *)pasterTextView;
- (void)touchescurrentCaptionView:(CaptionVideoTrimmerView *)trimmerView
                      showOhidden:(BOOL)flag
                        startTime:(Float64)captionStartTime;

- (void)updateSyncLayerPositionAndTransform;

- (void)initPasterViewWithFile:(UIImage *)thumbImage;


- (void)addEffectAction:(UIButton *)sender;

-(void)pasterView_Rect:(  CGRect * ) rect atRotate:( double * ) rotate;
@end
