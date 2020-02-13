//
//  RDGPUImageDYFilter.m
//  RDVideoAPI
//
//  Created by 周晓林 on 2017/5/18.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageDYFilter.h"
NSString *const kRDDYShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;

 uniform float type;
 uniform float time; // 由time控制
 
 uniform float enables[5];
#define eq(x,y) (1.0-abs(sign(x-y)))
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
     
     vec4 color = texture2D(inputImageTexture,textureCoordinate);

     
     
     if(eq(type,0.0) > 0.5){
         gl_FragColor = texture2D(inputImageTexture,textureCoordinate);
     }
     
     if(eq(type,1.0) > 0.5){
         vec4 color1 = vec4(0.0);
         float value = mod(fract(time),0.5)*2.0;
         value = mix(value,0.0,step(0.5,value));
         
         vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.66667)+vec2(0.5);
         color1 = texture2D(inputImageTexture,newCoordinate);
         color1 = mix(color,color1,0.3333*(1.0 - value));

         gl_FragColor = color1;
     }
     
     if(eq(type,2.0) > 0.5){

         float value = mod(fract(time),0.5)*2.0;
         value = mix(value,0.0,step(0.5,value));

         vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.5)+vec2(0.5);
         vec2 newCoordinateR = (textureCoordinate - vec2(0.5 - 0.05 * value))*(1.0-value*0.5)+vec2(0.5 - 0.05 * value);
         vec2 newCoordinateG = (textureCoordinate - vec2(0.5 + 0.05 * value))*(1.0-value*0.5)+vec2(0.5 + 0.05 * value);
         
         vec4 color_N = texture2D(inputImageTexture,newCoordinate);
         vec4 color_R = texture2D(inputImageTexture,newCoordinateR);
         vec4 color_G = texture2D(inputImageTexture,newCoordinateG);
         gl_FragColor = vec4(color_R.r,color_G.g,color_N.b,1.0);

     }
     
     if(eq(type,3.0) > 0.5){
         float value = mix(mod(fract(time),0.16666)*6.0,0.0,step(0.5,fract(time)));
         vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.2)+vec2(0.5);
         gl_FragColor = texture2D(inputImageTexture,newCoordinate);

     }
     
     if(eq(type,4.0) > 0.5){
         vec4 colorA = addSpotlight(vec2(-0.2,-0.1), - PI/4.0, 0.4, 0.1, vec4(0.0,0.0,1.0 ,1.0));
         vec4 colorB = addSpotlight(vec2(0.15,-0.1), - PI/8.0, 0.4, 0.1, vec4(1.0,0.0,1.0 ,1.0));
         vec4 colorC = addSpotlight(vec2(0.5 ,-0.1),   0.0,    0.4, 0.1, vec4(0.0,1.0,0.0 ,1.0));
         vec4 colorD = addSpotlight(vec2(0.85,-0.1),   PI/8.0, 0.4, 0.1, vec4(1.0,1.0,0.0 ,1.0));
         vec4 colorE = addSpotlight(vec2(1.2 ,-0.1),   PI/4.0, 0.4, 0.1, vec4(1.0,0.0,0.0 ,1.0));
         gl_FragColor = colorA*enables[0] + colorB*enables[1] + colorC*enables[2] + colorD*enables[3] + colorE*enables[4];

     }
     
 }
 
 
);

@interface RDGPUImageDYFilter()
{
    GLuint typeUniform;
    GLuint timeUniform;
    GLuint enablesUniform;

}

@end

@implementation RDGPUImageDYFilter
- (instancetype)init{
    if (!(self = [super initWithFragmentShaderFromString:kRDDYShaderString])) {
        return nil;
    }
    
    typeUniform = [filterProgram uniformIndex:@"type"];
    timeUniform = [filterProgram uniformIndex:@"time"];
    enablesUniform = [filterProgram uniformIndex:@"enables"];
    
    self.type = 0;
    self.time = 0.0;
    return self;
}

- (void)setTime:(float)time{
    _time = time;
    static float _ennnnn[5];
    static int count = 0;
    float total = 0;
    if (count%7 == 0) {
        for (int i = 0; i<5; i++) {
            _ennnnn[i] = drand48()>0.5?1.0/7.0:0.0;
            total += _ennnnn[i];
        }
        
        if (total==0.0) {
            _ennnnn[arc4random()%5] = 1.0/7.0;
        }
    }
    
    float _ennn[5];
    for (int i = 0; i<5; i++) {
        _ennn[i] = _ennnnn[i] * (count%7);
    }
    count++;
    
    
    [self setFloatArray:_ennn length:5 forUniform:enablesUniform program:filterProgram];
    
    [self setFloat:time forUniform:timeUniform program:filterProgram];

}


- (void)setType:(int)type{
    _type = type;
    [self setFloat:(float)type forUniform:typeUniform program:filterProgram];
}
@end
