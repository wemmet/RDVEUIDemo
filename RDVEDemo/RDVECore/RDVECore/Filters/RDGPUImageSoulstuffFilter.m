//
//  RDGPUImageSoulstuffFilter.m
//  RDVideoAPI
//
//  Created by 周晓林 on 2017/5/19.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageSoulstuffFilter.h"
NSString* const kRDGPUImageSoulstuffFragmentShader = SHADER_STRING
(
 
 
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float time; // 由time控制
 
 void main(){
     vec4 color = texture2D(inputImageTexture,textureCoordinate);
     
     // 第一个 soulstuff
     vec4 color1 = vec4(0.0);
     {
         
         float value = 0.0;
         //         value = mix(time*2.0,0.0,step(0.5,time));
         
         if(time <0.5){
             value = time * 2.0;
         }else{
             value = 0.0;
         }
         
         vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.3333)+vec2(0.5);
         color1 = texture2D(inputImageTexture,newCoordinate);
         color1 = mix(color,color1,0.2);
     }
     
     gl_FragColor = color1;

 }
);
@interface RDGPUImageSoulstuffFilter ()
{
    GLuint timeUniform;
}
@end
@implementation RDGPUImageSoulstuffFilter
- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kRDGPUImageSoulstuffFragmentShader];
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
