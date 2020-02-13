//
//  RDMVFilter.m
//  xpkCoreSdk
//
//  Created by 周晓林 on 2017/3/25.
//  Copyright © 2017年 xpkCoreSdk. All rights reserved.
//

#import "RDMVFilter.h"
NSString *const kRDMVShaderString = SHADER_STRING
(
 precision mediump float;

 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;


 void main()
 {
     
     vec2 newCoordinate1 = vec2(textureCoordinate2.x/2.0,textureCoordinate2.y);
     vec4 t1 = texture2D(inputImageTexture2,newCoordinate1); // view
     
     
     
     vec2 newCoordinate2 = newCoordinate1 + vec2(0.5,0.0);
     
     
     vec4 t2 = texture2D(inputImageTexture2, newCoordinate2);//alpha
     
     
     
     vec4 t3 = texture2D(inputImageTexture, textureCoordinate);//source
     float newAlpha = dot(t2.rgb, vec3(0.33333334)) * t2.a;
     vec4 t = vec4(t1.rgb,newAlpha); //compositor 输出一个综合视频 再与
     //mix(a,b,v) = (1-v)a + v(b)
     gl_FragColor = vec4(mix(t3.rgb,t.rgb,t.a),t3.a);
 }
 );
@interface RDMVFilter()
{
//    GLuint valueUniform;
//    GLuint orientUniform;

}
@end
@implementation RDMVFilter
- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kRDMVShaderString]))
    {
        return nil;
    }

    return self;
}
@end
