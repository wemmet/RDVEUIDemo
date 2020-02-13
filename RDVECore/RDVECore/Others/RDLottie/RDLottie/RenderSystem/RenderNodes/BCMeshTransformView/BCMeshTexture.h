//
//  BCMeshTexture.h
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <UIKit/UIKit.h>

@interface BCMeshTexture : NSObject

@property (nonatomic, readonly) GLuint texture;

- (void)setupOpenGL;
- (void)renderView:(UIView *)view;

@end
