//
//  RDRecordViewController.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import <UIKit/UIKit.h>
#import "RDCameraManager.h"
#import "RDScene.h"
#import "RDVEUISDKConfigure.h"

typedef NS_ENUM(NSUInteger, RecordSizeType) {
    RecordSizeTypeSquare = 1 << 0, // 方形录制  only
    RecordSizeTypeNotSquare = 1 << 1, // 非方形录制 only
    RecordSizeTypeMixed = 1 << 2, // 混合 可切换
};

//此参数在非方形录制下生效
typedef NS_ENUM(NSUInteger, RecordOrientation) {
    RecordOrientationAuto = 1 << 0, // 横竖屏自动切换切换
    RecordOrientationPortrait = 1 << 1, // 保持竖屏
    RecordOrientationLeft = 1 << 2, // 保持横屏
};

typedef NS_ENUM(NSUInteger, RecordType) {
    
    RecordTypeVideo = 0,
    RecordTypePhoto = 1,
    RecordTypeMVVideo = 2,//短视频MV
};

typedef void(^RDRecordCancelBlock) (int type,UIViewController* _Nullable vc);
typedef void(^RDRecordCallbackBlock) (NSString* _Nullable videoPath,int type,RDMusic *music);//type:0 表示MV 2 表示普通视频 4表示编辑完成

@protocol RDRecordViewDelegate <NSObject>

@optional

//摄像头捕获帧回调，可对帧进行处理
- (void)willOutputSampleBuffer:(CMSampleBufferRef _Nonnull )sampleBuffer;

//切换音乐回调
- (void)changeMusicResult:(UINavigationController *_Nullable)nav CompletionHandler:(void (^_Nullable)(RDMusic *_Nullable musicInfo))handler;
@end

@interface RDRecordViewController : UIViewController<RDCameraManagerDelegate>
{
    RDRecordCallbackBlock finishBlock;
    RDRecordCancelBlock   cancelBlock;
}

//设置输出图像格式，默认为YES
//YES:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
//NO:kCVPixelFormatType_32BGRA
@property(nonatomic, assign) BOOL captureAsYUV;

//录制视频分辨率
@property (nonatomic , assign) CGSize                recordSize;
@property (nonatomic , strong) RDCameraManager *    _Nullable cameraManager;
@property (nonatomic , copy  ) NSString *             _Nullable videoPath;

//录制码率
@property (nonatomic , assign) int                   bitrate;

//录制帧率
@property (nonatomic , assign) int                   fps;
@property (nonatomic , assign) float                 MAX_VIDEO_DUR_1;
@property (nonatomic , assign) float                 MAX_VIDEO_DUR_2;

//方形录制下,控制按钮条的位置  YES:在上  NO:在下
@property (nonatomic , assign) BOOL                  isSquareTop;

//录制方式
@property (nonatomic , assign) RecordSizeType        recordsizetype;

//录制方向
@property (nonatomic , assign) RecordOrientation     recordorientation;

//0:照片 1:视频 2:短视频MV
@property (nonatomic , assign) RecordType            recordtype;

//前后置摄像头
@property (nonatomic , assign) AVCaptureDevicePosition cameraPosition;

// NO：单次拍摄 YES：多次拍摄
@property (nonatomic , assign) BOOL                  more;

//more = NO 时 是否直接写入相册
@property (nonatomic , assign) BOOL                  isWriteToAlbum;

// more = NO时，返回照片地址
@property (nonatomic , copy  ) void(^ _Nullable PhotoPathBlock)(NSString* _Nullable path);

//是否启用faceU
@property (nonatomic , assign) BOOL                  faceU;

//faceU下载路径
@property (nonatomic , copy  ) NSString* _Nullable   faceUURLString;

//拍摄最小时长
@property (nonatomic , assign) float                 minRecordDuration;
@property (nonatomic , assign) BOOL                  hiddenPhotoLib;

//YES:可拍摄短视频MV NO:不可拍摄短视频MV ，默认为YES
@property (nonatomic , assign) BOOL                  cameraMV;

//YES:可拍摄视频 NO:不可拍摄视频 ，默认为YES
@property (nonatomic , assign) BOOL                  cameraVideo;

//YES:可拍摄照片 NO:不可拍摄照片 ，默认为YES
@property (nonatomic , assign) BOOL                  cameraPhoto;

//短视频MV的最小时长(秒)，默认为3秒
@property (nonatomic , assign) float                 MVRecordMinDuration;

//短视频MV的最大时长(秒)，默认为15秒
@property (nonatomic , assign) float                 MVRecordMaxDuration;

@property (nonatomic , assign) BOOL                  needFilter;

// 是否开启使用音乐录制
@property (nonatomic , assign) BOOL                  enableUseMusic;

// 传入需要录制时播放的音乐
@property (nonatomic , strong) RDMusic               *_Nullable musicInfo;
@property (nonatomic , assign) BOOL                  push;

@property (nonatomic, weak)   id <RDRecordViewDelegate> _Nullable delegate;

// 是否开启使用相机水印
@property (nonatomic , assign) BOOL                  enableCameraWaterMark;
// 相机水印
@property (nonatomic , strong) UIImage               *waterHeader;
// 相机水印
@property (nonatomic , strong) UIImage               *waterBody;
@property (nonatomic , strong) UIImage               *waterFooter;
// 相机水印头的显示时间
@property (nonatomic , assign) float                 cameraWaterMarkHeaderDuration;
//相机水印尾的显示时间
@property (nonatomic , assign) float                 cameraWaterMarkEndDuration;

@property (nonatomic, copy) void (^cameraWaterProcessingCompletionBlock)(NSInteger type/*1:正方形录制，0：非正方形录制*/,RecordStatus status, UIView *waterMarkview ,float time);


- (void) addFinishBlock : (RDRecordCallbackBlock _Nullable ) block;
- (void) addCancelBlock : (RDRecordCancelBlock _Nullable ) block;
- (void) switchBackOrFront;
- (void) deleteItems;
- (void)changeMusicWithMusicInfo:(RDMusic * _Nullable)musicInfo;

@end
