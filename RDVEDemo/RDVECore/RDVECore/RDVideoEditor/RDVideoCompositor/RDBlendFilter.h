//
//  RDBlendFilter.h
//  RDVECore
//
//  Created by xiachunlin on 2020/1/3.
//  Copyright © 2020年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "RDScene.h"


@interface RDBlendFilter : NSObject

- (BOOL)renderBlendModelWithForegroundTexture:(GLuint)foregroundTexture BackgroundTexture:(GLuint)backgroundTexture BlendType:(RDBlendType)type;

@end
