//
//  RDGPUImageTEffectFilter.m
//  RDVECore
//
//  Created by 周晓林 on 2017/6/19.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDGPUImageTEffectFilter.h"
NSString *const kRDGPUImageChangeEffectFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float value;
 uniform float orient;
 void main()
 {
     
    
     vec4 textureColor= texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     float test = step(value,textureCoordinate.y);
     
     gl_FragColor = mix(textureColor,textureColor2,mix(test,1.0-test,step(0.5,orient)));
         
     
 }
 );
@interface RDGPUImageTEffectFilter()
{
    GLuint valueUniform;
    GLuint orientUniform;
}
@end
@implementation RDGPUImageTEffectFilter
- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDGPUImageChangeEffectFragmentShaderString]))
    {
        return nil;
    }
    valueUniform = [filterProgram uniformIndex:@"value"];
    orientUniform = [filterProgram uniformIndex:@"orient"];
    self.value = 0.5;
    self.orient = 0;
    return self;
}
- (void)setValue:(float)value{
    _value = value;
    [self setFloat:value forUniform:valueUniform program:filterProgram];
}
- (void)setOrient:(int)orient{
    _orient = orient;
    [self setFloat:orient forUniform:orientUniform program:filterProgram];
}
@end
