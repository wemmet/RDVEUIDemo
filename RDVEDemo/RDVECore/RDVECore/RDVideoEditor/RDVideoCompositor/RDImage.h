//
//  RDImageFrameBuffer.h
//  RDVECore
//  图片缓存
//  Created by 周晓林 on 2017/5/15.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

@interface RDImage : NSObject
@property (nonatomic, readonly) UIImage *currentImage;
@property (readonly) GLuint texture;
@property (readonly) float width;
@property (readonly) float height;
- (instancetype)initWithImagePath:(NSURL *)path;
- (void)loadImagePath:(NSURL *)path;
- (void)setCurrentTime:(float)currentTime;
- (void) clear;
@end
