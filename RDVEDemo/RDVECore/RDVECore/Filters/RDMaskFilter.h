//
//  RDMaskFilter.h
//  RDVECore
//
//  Created by apple on 2018/4/23.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#ifndef RDMaskFilter_h
#define RDMaskFilter_h

#import "RDGPUImageFilter.h"

@interface RDMaskFilter : RDGPUImageFilter
{
    GLint inputImageTexture2Uniform;
}

- (instancetype) initWithImageNamed:(NSString *) name;
- (instancetype) initWithImage:(UIImage *) image;
- (instancetype)initWithImagePath:(NSString *)path;

@end

#endif /* RDMaskFilter_h */
