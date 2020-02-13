//
//  FaceUManager.m
//  RDVEDemo
//
//  Created by wuxiaoxia on 2019/9/06.
//  Copyright © 2019年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "FaceUManager.h"
#import "FURenderer.h"
#import "faceAuthpack.h"

@interface FaceUManager ()
{
    int items[3];
    int frameID;
}
@end

static FaceUManager *shareManager = NULL;

@implementation FaceUManager

+ (FaceUManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[FaceUManager alloc] init];
    });
    
    return shareManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];
        /**这里新增了一个参数shouldCreateContext，设为YES的话，不用在外部设置context操作，我们会在内部创建并持有一个context。
         还有设置为YES,则需要调用FURenderer.h中的接口，不能再调用funama.h中的接口。*/
        
        [[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_faceuAuth_package authSize:sizeof(g_faceuAuth_package) shouldCreateContext:YES];
        
        NSLog(@"faceunitySDK version:%@",[FURenderer getVersion]);
    }
    
    return self;
}

#pragma -Faceunity Load Data
/**
 加载普通道具
 - 先创建再释放可以有效缓解切换道具卡顿问题
 */
- (void)loadItem:(NSString *)itemPath
{
    /**如果取消了道具的选择，直接销毁道具*/
    if (!itemPath)
    {
        if (items[0] != 0) {
            NSLog(@"faceunity: destroy item");
            [FURenderer destroyItem:items[0]];
        /**为避免道具句柄被销毁会后仍被使用导致程序出错，这里需要将存放道具句柄的items[0]设为0*/
            items[0] = 0;
        }
        return;
    }
    
    /**先创建道具句柄*/
    int itemHandle = [FURenderer itemWithContentsOfFile:itemPath];
    
    /**销毁老的道具句柄*/
    if (items[0] != 0) {
        NSLog(@"faceunity: destroy item");
        [FURenderer destroyItem:items[0]];
    }
    
    /**将刚刚创建的句柄存放在items[0]中*/
    items[0] = itemHandle;
    
    NSLog(@"faceunity: load item");
}

/**加载美颜道具*/
- (void)loadFilter
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"face_beautification.bundle" ofType:nil];
    
    items[1] = [FURenderer itemWithContentsOfFile:path];
}

/**设置美颜参数*/
- (void)setBeautyParams
{
    /*设置美颜效果（磨皮、美白、瘦脸、大眼....）*/
    [FURenderer itemSetParam:items[1] withName:@"blur_level" value:@(self.blurLevel)]; //磨皮 (0、1、2、3、4、5、6)
    [FURenderer itemSetParam:items[1] withName:@"color_level" value:@(self.colorLevel)]; //美白 (0~1)
    [FURenderer itemSetParam:items[1] withName:@"face_shape" value:@(self.faceShape)]; //美型类型 (0、1、2、3) 默认：3，女神：0，网红：1，自然：2
    [FURenderer itemSetParam:items[1] withName:@"face_shape_level" value:@(self.faceShapeLevel)]; //美型等级 (0~1)
    [FURenderer itemSetParam:items[1] withName:@"eye_enlarging" value:@(self.eyeEnlarging)]; //大眼 (0~1)
    [FURenderer itemSetParam:items[1] withName:@"cheek_thinning" value:@(self.cheekThinning)]; //瘦脸 (0~1)
}

/**将道具绘制到pixelBuffer*/
- (void)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    //人脸跟踪
    int isTrack = [FURenderer isTracking];
    if (isTrack) {
        //加载美颜道具
        if (items[1] == 0) {
            [self loadFilter];
        }
        /**设置美颜参数*/
        [self setBeautyParams];
    }
    /*Faceunity核心接口，将道具及美颜效果绘制到pixelBuffer中，执行完此函数后pixelBuffer即包含美颜及贴纸效果*/
    [[FURenderer shareRenderer] renderPixelBuffer:pixelBuffer withFrameId:frameID items:items itemCount:3 flipx:YES];//flipx 参数设为YES可以使道具做水平方向的镜像翻转
    frameID += 1;
}

/**切换摄像头要调用此函数*/
- (void)onCameraChange
{
    [FURenderer onCameraChange];
}

/**销毁全部道具*/
- (void)destoryItems
{
    [FURenderer destroyAllItems];
    
    /**销毁道具后，为保证被销毁的句柄不再被使用，需要将int数组中的元素都设为0*/
    for (int i = 0; i < sizeof(items) / sizeof(int); i++) {
        items[i] = 0;
    }
    
    /**销毁道具后，清除context缓存*/
    [FURenderer OnDeviceLost];
    
    /**销毁道具后，重置人脸检测*/
    [FURenderer onCameraChange];
}

@end
