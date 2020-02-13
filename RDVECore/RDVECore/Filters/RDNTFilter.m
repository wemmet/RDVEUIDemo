//
//  RDNTFilter.m
//  RDVECore
//
//  Created by 周晓林 on 2017/8/16.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

//vec4 color1 = vec4(0.0);
//float value = mod(fract(time),0.5)*2.0;
//value = mix(value,0.0,step(0.5,value));
//
//vec2 newCoordinate = (textureCoordinate - vec2(0.5))*(1.0-value*0.66667)+vec2(0.5);
//color1 = texture2D(inputImageTexture,newCoordinate);
//color1 = mix(color,color1,0.3333*(1.0 - value));
//
//gl_FragColor = color1;


#import "RDNTFilter.h"
NSString *const kRDNTShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 
 void main()
 {
     
     vec2 newCoordinate = (textureCoordinate - vec2(0.5))*2.0 + vec2(0.5) - vec2(0.5,0);
     float x1 = newCoordinate.x;
     float y1 = newCoordinate.y;
     float c1 = step(0.0,x1)*step(0.0,y1) * (1.0 - step(1.0,x1)) *(1.0 - step(1.0,y1));

     vec2 newCoordinate2 = (textureCoordinate2 - vec2(0.5))*2.0 + vec2(0.5) + vec2(0.5,0);
     float x2 = newCoordinate2.x;
     float y2 = newCoordinate2.y;
     float c2 = step(0.0,x2)*step(0.0,y2) * (1.0 - step(1.0,x2)) *(1.0 - step(1.0,y2));

     
     
     vec4 t1 = texture2D(inputImageTexture, newCoordinate);//right
     
     t1 = mix(vec4(0.0),t1,c1);
     
     vec4 t2 = texture2D(inputImageTexture2, newCoordinate2);//left
     
     t2 = mix(vec4(0.0),t2,c2);
   
     
     
     gl_FragColor = t1 + t2;
 
 }
 );

@implementation RDNTFilter
- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDNTShaderString]))
    {
        return nil;
    }
    
    
    return self;
}


@end
