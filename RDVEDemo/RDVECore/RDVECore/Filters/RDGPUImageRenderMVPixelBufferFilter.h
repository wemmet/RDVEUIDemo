//
//  RDLookupFilter.h
//  RDVECore
//
//  Created by  on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageFilter.h"
#import "RDVideoCompositorInstruction.h"

@interface RDGPUImageRenderMVPixelBufferFilter : RDGPUImageFilter

@property (nonatomic, strong)UIImage *dstImage;
@property (nonatomic, assign)CVPixelBufferRef dstPixels;
@property (nonatomic, assign)CVPixelBufferRef mvPixels;
@property (nonatomic, assign)RDVideoCompositorInstruction* instruction;


@end

