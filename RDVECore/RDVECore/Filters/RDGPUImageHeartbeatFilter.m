//
//  RDGPUImageHeartbeatFilter.m
//  RDVideoAPI
//
//  Created by 周晓林 on 2017/5/19.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageHeartbeatFilter.h"
NSString * const RDGPUImageHeartbeatFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float time; // 由time控制
 
 
 void main(){
     // 第三个 heartbeat
     vec4 color3 = vec4(0.0);
     
     {
         float value = 0.0;
         if(time < 0.5){
             value = mod(time,0.16666)*6.0;
         }else{
             value = 0.0;
         }
         
         vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.2)+vec2(0.5);
         
         color3 = texture2D(inputImageTexture,newCoordinate);
         
     }

     gl_FragColor = color3;
 }

);

@interface RDGPUImageHeartbeatFilter ()
{
    GLuint timeUniform;
}
@end
@implementation RDGPUImageHeartbeatFilter
- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:RDGPUImageHeartbeatFragmentShader];
    if (self) {
        timeUniform = [filterProgram uniformIndex:@"time"];
        self.time = 0.0;

    }
    return self;
}

- (void)setTime:(float)time{
        
    _time = time- floorf(time);
    [self setFloat:_time forUniform:timeUniform program:filterProgram];
}
@end
