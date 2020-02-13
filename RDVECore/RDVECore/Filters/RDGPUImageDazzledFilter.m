//
//  RDGPUImageDazzledFilter.m
//  RDVideoAPI
//
//  Created by 周晓林 on 2017/5/19.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageDazzledFilter.h"
NSString * const RDGPUImageDazzledFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float time; // 由time控制
 
 
 void main(){
     // 第二个 Dazzled
     vec4 color2 = vec4(0.0);
     
     {
         float value = 0.0;
         if(time < 0.5){
             value = time * 2.0;
         }else{
             value = 0.0;
         }
         
         
         
         vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.3333)+vec2(0.5);
         vec2 newCoordinateR = (textureCoordinate - vec2(0.5 - 0.02 * value))*(1.0-value*0.3333)+vec2(0.5 - 0.02 * value);
         vec2 newCoordinateG = (textureCoordinate - vec2(0.5 + 0.02 * value))*(1.0-value*0.3333)+vec2(0.5 + 0.02 * value);
         
         vec4 color_N = texture2D(inputImageTexture,newCoordinate);
         vec4 color_R = texture2D(inputImageTexture,newCoordinateR);
         
         vec4 color_G = texture2D(inputImageTexture,newCoordinateG);
         
         color2 = vec4(color_R.r,color_G.g,color_N.b,1.0);
         //         color2 = vec4(color_N.rgb + vec3(color_R.r,color_G.g,0.0)*0.5,1.0) ;
         
     }
     
     gl_FragColor = color2;
 }
 
 );

@interface RDGPUImageDazzledFilter ()
{
    GLuint timeUniform;
}
@end
@implementation RDGPUImageDazzledFilter
- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:RDGPUImageDazzledFragmentShader];
    if (self) {
        timeUniform = [filterProgram uniformIndex:@"time"];
    }
    self.time = 0.0;
    return self;
}

- (void)setTime:(float)time{
    _time = time- floorf(time);
    [self setFloat:_time forUniform:timeUniform program:filterProgram];
}

@end
