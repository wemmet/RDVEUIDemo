//
//  RDCustomFilter.h
//  RDVECore
//
//  Created by xcl on 2018/11/27.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#ifndef RDQUADRENDER_H
#define RDQUADRENDER_H

#import <Foundation/Foundation.h>
#import "RDGPUImageFilter.h"
#import "RDScene.h"

@interface RDQuadsRender :RDGPUImageFilter

@property (nonatomic, strong) NSMutableArray<RDCaptionLight*>* captionLight;


@end

#endif /* Header_h */
