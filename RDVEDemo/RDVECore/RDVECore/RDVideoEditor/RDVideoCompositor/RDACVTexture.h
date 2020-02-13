//
//  RDACVTexture.h
//  RDVECore
//
//  Created by 周晓林 on 2017/11/6.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface RDACVTexture : NSObject
@property (readonly) GLuint texture;
- (void)loadACVPath:(NSURL *)path;

- (void) clear;
@end
