//
//  RDVideoEditor.h
//  RDVideoAPI
//  编辑类 根据scenes数组 处理 视频、图片的显示及转场 还有声音的处理
//  场景数组可以根据需要，替换为json文件
//  Created by 周晓林 on 2017/5/8.
//  Copyright © 2017年 Solaren. All rights reserved.
//
//  这个类需要传入场景配置   每个场景包括资源

#import "RDEditorObject.h"
@interface RDVideoEditor : RDEditorObject
@property (nonatomic,readonly) float duration;
@property (nonatomic, assign) BOOL enableAudioEffect;
@property (nonatomic,assign) BOOL isExporting;
- (void) build;
- (CMTimeRange) passThroughTimeRangeAtIndex:(int) index;
- (CMTimeRange) transitionTimeRangeAtIndex:(int) index;
- (void)refreshTransition:(VVTransition *)transition atIndex:(NSInteger)index;
- (void)refreshAssetSpeed:(float)speed;
- (void) setVVAssetVolume:(float)volume asset:(VVAsset *) asset;
- (void) setMusicVolume:(float) volume music:(RDMusic *) music;
- (void) setVolume:(float) volume identifier:(NSString*) identifier;
- (void) setPitch:(float) pitch identifier:(NSString*) identifier;
- (void) setAudioFilter:(RDAudioFilterType)type identifier:(NSString *)identifier;
- (void) setVirtualVideoBgColor:(UIColor *)bgColor;
- (void) setLottieView:(UIView *)lottieView;

@end
