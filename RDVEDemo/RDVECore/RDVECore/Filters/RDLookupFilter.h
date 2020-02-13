//
//  RDLookupFilter.h
//  RDVECore
//
//  Created by 周晓林 on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageFilter.h"

@interface RDLookupFilter : RDGPUImageFilter
{
    GLint intensityUniform;
    GLint inputImageTexture2Uniform;
}
@property(readwrite, nonatomic) CGFloat intensity;
- (instancetype) initWithImageNamed:(NSString *) name intensity:(float)intensity;
- (instancetype) initWithImage:(UIImage *) image intensity:(float)intensity;
- (instancetype)initWithImagePath:(NSString *)path intensity:(float)intensity;
- (instancetype)initWithImageNetPath:(NSString *)path intensity:(float)intensity;
@end
