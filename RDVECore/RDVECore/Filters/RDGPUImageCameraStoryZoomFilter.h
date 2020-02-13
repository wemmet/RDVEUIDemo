//
//  RDLookupFilter.h
//  RDVECore
//
//  Created by xcl on 2019/5/15.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageFilter.h"
#import "RDCameraFile.h"


@interface RDGPUImageCameraStoryZoomFilter : RDGPUImageFilter


@property (nonatomic, assign) float fps;
@property (nonatomic, strong) NSMutableArray<RDCameraMVEffect*>* storyZooms;

@end


