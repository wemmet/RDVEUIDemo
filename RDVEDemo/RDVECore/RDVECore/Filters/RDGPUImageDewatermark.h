//
//  RDDewatermark.h
//  RDVECore
//
//  Created by xcl on 2018/11/27.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#ifndef RDDEWATERMARK_H
#define RDDEWATERMARK_H

#import <Foundation/Foundation.h>
#import "RDGPUImageFilter.h"
#import "RDScene.h"

@interface RDGPUImageDewatermark :RDGPUImageFilter

@property (nonatomic, strong) NSMutableArray<RDDewatermark*>* watermark;


@end

#endif /* Header_h */
