//
//  RDGPUImageDYFilter.h
//  RDVideoAPI
//
//  Created by 周晓林 on 2017/5/18.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageFilter.h"

@interface RDGPUImageDYFilter : RDGPUImageFilter

@property (nonatomic,assign) int type; // 滤镜类型
@property (nonatomic,assign) float time;
@end
