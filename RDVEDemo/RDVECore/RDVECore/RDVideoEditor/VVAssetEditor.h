//
//  VVAssetEditor.h
//  RDVECore
//  这个类用于处理传入多个资源时场景生成
//  Created by 周晓林 on 2017/7/4.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RDScene.h"
@interface VVAssetEditor : NSObject
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition* videoComposition;
@property (nonatomic, strong) AVMutableAudioMix *audioMix;


@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) int fps;
@property (nonatomic, strong) NSMutableArray<VVAsset*>* vAssetArray;
@property (nonatomic, strong) NSURL* alphaImageURL;
@property (nonatomic,readonly) AVAsset* asset;
- (void) build;

@end
