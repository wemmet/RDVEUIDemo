//
//  RDLookupFilter.h
//  RDVECore
//
//  Created on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageFilter.h"
#import "RDScene.h"

@interface RDGPUImageGaussianBlurDYFilter : RDGPUImageFilter

@property (nonatomic, strong) NSMutableArray<RDAssetBlur*>* blurBlocks;


@end

