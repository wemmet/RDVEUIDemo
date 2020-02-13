//
//  RDGPUImageLookupFilter.h
//  RDVECore
//
//  Created by 周晓林 on 2017/10/27.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageTwoInputFilter.h"

@interface RDGPUImageLookupFilter : RDGPUImageTwoInputFilter
{
    GLint intensityUniform;
}
@property(readwrite, nonatomic) CGFloat intensity;

@end
