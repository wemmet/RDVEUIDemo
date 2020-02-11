//
//  RDGenSpecialEffect.h
//  RDVEUISDK
//
//  Created by apple on 2018/12/25.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDVECore.h"

@interface RDGenSpecialEffect : NSObject

/**倒序地址生成
 */
+(NSString *)ExportURL:(RDFile *)file;
/**慢动作
 */
+( void )TimeEffectTypeSlow:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                       atS1:(RDScene *)s1 atS2:(RDScene *)s2 atS3:(RDScene *)s3 atFile:(RDFile*) file;
/**慢动作 单个多媒体生成
 */
+( void )TimeEffectTypeSlow:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile *)file;
/**反复
 */
+(void)TimeEffectTypeRepeat:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                            atS1:(RDScene *)s1 atS2:(RDScene *)s2 atr2:(RDScene *)r2
                                atS3:(RDScene *)s3 atr3:(RDScene *)r3
                                    atS4:(RDScene *)s4 atS5:(RDScene *)s5  atFile:(RDFile*) file;
/**反复 单个多媒体生成
 */
+( void )TimeEffectTypeRepeat:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file;
/**倒序
 */
 +(void)TimeEffectTypeReverse:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                         atS1:(RDScene *)s1 atS2:(RDScene *)s2 atS3:(RDScene *)s3  atFile:(RDFile*) file;
/**倒序 单个多媒体生成
 */
+( void )TimeEffectTypeReverse:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file;

/**快动作
 */
+(void)TimeEffectTypeQuick:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                atS1:(RDScene *)s1 atS2:(RDScene *)s2 atS3:(RDScene *)s3 atFile:(RDFile*) file;
+(void)TimeEffectTypeQuick:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file;

/**生成时间特效
 */
+( void )refreshVideoTimeEffectType:(TimeFilterType)timeEffectType timeEffectTimeRange:(CMTimeRange)effectTimeRange atscenes:(NSMutableArray<RDScene *>*)scenes  atFile:(RDFile*) file;
/**生成时间特效 单个多媒体生成
 */
+( void )refreshVideoTimeEffectType:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile *)file  atscene:(RDScene *)scene atTimeRange:(CMTimeRange) TimeRange  atIsRemove:(BOOL) IsRemove;

//---------------------滤镜特效 脚本的获取
+ (RDCustomFilter *)getCustomFilerWithFxId:(int)fxId
                             filterFxArray:(NSArray *)filterFxArray
                                 timeRange:(CMTimeRange)timeRange
                   currentFrameTexturePath:(NSString *)currentFrameTexturePath;

+ (RDCustomFilter *)getCustomFilerWithFxId:(int)fxId
                             filterFxArray:(NSArray *)filterFxArray
                                 timeRange:(CMTimeRange)timeRange;

+ (RDCustomTransition *)getCustomTransitionWithJsonPath:(NSString *)configPath;

/** 添加logo水印及片尾水印
 */
+ (void)addWatermarkToVideoCoreSDK:(RDVECore *)videoCoreSDK
                      totalDration:(float)totalDration
                        exportSize:(CGSize)exportSize
                      exportConfig:(ExportConfiguration *)exportConfig;

@end

