//
//  RDGPUImageSpotlightsFilter.m
//  RDVideoAPI
//
//  Created by 周晓林 on 2017/5/19.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageSpotlightsFilter.h"
NSString * const RDGPUImageSpotlightsFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float orign; // 由time控制
 uniform float enables[5];
#define PI 3.1415926
 
 
 vec4 addSpotlight( vec2 spotCoord, float direction, float maxLight,  float minLight ,vec4 lightColor ){
     vec4 color = texture2D(inputImageTexture,textureCoordinate);
     vec4 result = vec4(0.0);
     
     vec2 tanvec = textureCoordinate - spotCoord; // 聚光灯位置
     
     float tanv = tanvec.x/tanvec.y;
     
     float vangle = atan(tanv);
     
     vangle = abs(vangle + direction); // 聚光灯方向
     
     if(vangle < maxLight){ //聚光灯范围
         
         result =  color*lightColor; // 聚光灯颜色
         if(vangle > minLight){ // 聚光灯核心范围
             result =  mix(result,vec4(0.0),smoothstep(minLight,maxLight,vangle));
         }
     }
     
     return result;
     
 }

 void main(){
     // 第四个类 Spotlights
     vec4 color4 = vec4(0.0);
     
     {
         vec4 colorA = addSpotlight(vec2(1.2,-0.1),   PI/4.0, 0.4, 0.1, vec4(1.0,0.0,0.0,1.0));
         vec4 colorB = addSpotlight(vec2(0.85,-0.1),   PI/8.0, 0.4, 0.1, vec4(1.0,1.0,0.0 ,1.0));
         vec4 colorC = addSpotlight(vec2(0.5,-0.1),   0.0,    0.4, 0.1, vec4(0.0,1.0,1.0 ,1.0));
         vec4 colorD = addSpotlight(vec2(0.15,-0.1), - PI/8.0, 0.4, 0.1, vec4(1.0,0.0,1.0 ,1.0));
         vec4 colorE = addSpotlight(vec2(-0.2,-0.1), - PI/4.0, 0.4, 0.1, vec4(0.0,1.0,0.0 ,1.0));
         
         color4 = colorA*enables[0] + colorB*enables[1] + colorC*enables[2] + colorD*enables[3] + colorE*enables[4];
         
     }
     
     if(orign < 0.0){
         gl_FragColor = texture2D(inputImageTexture,textureCoordinate);
     }else{
         gl_FragColor = color4;

     }
     
 }
 
 );
@interface RDGPUImageSpotlightsFilter ()
{
    GLuint orignUniform;
    GLuint enablesUniform;
}
@end
@implementation RDGPUImageSpotlightsFilter
- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:RDGPUImageSpotlightsFragmentShader];
    if (self) {
        orignUniform = [filterProgram uniformIndex:@"orign"];
        enablesUniform = [filterProgram uniformIndex:@"enables"];
//    self.time = 0.0;
        glUniform1f(orignUniform, -1.0);
    }
    
    return self;
}

- (void)setEnables:(NSMutableArray *)enables{
    
    
}

- (void)setTime:(float)time{
    
    float value = time - 0.25*floorf(time/0.25);
    static float _ennn[5];

    if (value < 0.04) {
        for (int i = 0; i<5; i++) {
            _ennn[i] = drand48()>0.5?1.0:0.0;
        }

    }
    
    
    
    [self setFloatArray:_ennn length:5 forUniform:enablesUniform program:filterProgram];

//    _time = time;
    [self setFloat:1.0 forUniform:orignUniform program:filterProgram];
}

@end
