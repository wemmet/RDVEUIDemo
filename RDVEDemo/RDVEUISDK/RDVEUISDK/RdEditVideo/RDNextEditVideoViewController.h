//
//  RDNextEditVideoViewController.h
//  RDVEUISDK
//
//  Created by emmet on 2017/6/30.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "RDVECore.h"
#import "RDZSlider.h"
#import "RDExportProgressView.h"
#import "RDAlertView.h"
#import "RDVEUISDKConfigure.h"
#import "RDDraftManager.h"

#define STRINGIZEString(x) #x
#define STRINGIZEString2(x) STRINGIZEString(x)
#define SHADER_STRINGString(text) @ STRINGIZEString2(text)
#define kFxIconTag 1000
#define kFxProgressViewTag    999
#define kFxScrollViewTag  2000
#define kTransitionFxId 71 //后台返回的“转场”特效分类id
#define kFreezeFrameFxId 575550 //后台返回的“定格”特效分类id

typedef NS_ENUM(NSInteger, RDFunctionType){
    RDFunctionType_None             = 0,
    RDFunctionType_Sound            = 1,    //声音
    RDFunctionType_FragmentEdit     = 2,    //片段编辑
    RDFunctionType_AdvanceEdit      = 3,    //高级编辑
    RDFunctionType_Setting          = 4,    //设置
};

@interface RDNextEditVideoViewController : UIViewController

/**文件列表
 */
@property(nonatomic,strong)NSMutableArray <RDFile *>*fileList;
/**视频导出分辨率
 */
@property (nonatomic, assign ) CGSize      exportVideoSize;

/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;

@property(nonatomic,copy) void (^cancelActionBlock)(void);
@property(nonatomic,copy) void (^saveDraftCompletionBlock)(void);

/**是否开启多媒体
 */
@property(nonatomic,assign) bool            isMultiMedia;

/**草稿信息
 */
@property(nonatomic,strong)RDDraftInfo      *draft;

-(NSMutableArray *)getFileList;
-(NSMutableArray *)getFilterFxArray;
-(void)showPrompt:(NSString *) string;


//背景 画布
+(VVAsset *)canvasFile:(RDFile *) file;
@end


