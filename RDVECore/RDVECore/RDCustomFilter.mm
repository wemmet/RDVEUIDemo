//
//  RDParticleRender.m
//  RDVECore
//
//  Created by apple on 2018/5/16.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCustomFilter.h"
#import "RDCustomFilterPrivate.h"
#import "TTextCipher.h"

@implementation RDTextureParams
@end

@implementation RDShaderParams
@end

@interface RDCustomFilter()
{
    BOOL isDecryptedFrag;
    BOOL isDecryptedVert;
}

@property(nonatomic, readwrite) GLuint vertShader, fragShader;
@property(nonatomic, readwrite) GLuint filterProgram;
@property(nonatomic, readwrite) GLuint positionAttribute,textureCoordinateAttribute,timeUniform,inputTextureUniform,resolutionUniform;
@property(nonatomic, readwrite) GLuint progressUniform,rotateAngleUniform,fromUnifrom,toUnifrom;
@property(nonatomic, readwrite) struct SHADER_UNIFORM_LIST* pUniformList;
@property(nonatomic, readwrite) struct SHADER_TEXTURE_SAMPLER2D_LIST* pTextureSamplerList;
@end
@implementation RDCustomFilter

- (id)init
{
    self = [super init];
    if(self) {
        _cycleDuration = 1.0;
        //        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:[RDGPUImageContext sharedImageProcessingContext].context.sharegroup];
        
    }
    
    return self;
}

- (void)setName:(NSString *)name {
    _name = name;
    if (name.length > 0 && _frag && !isDecryptedFrag) {
        _frag = [self decryptWithOriginalStr:_frag];
        isDecryptedFrag = YES;
    }
    if (name.length > 0 &&_vert && !isDecryptedVert) {
        _vert = [self decryptWithOriginalStr:_vert];
        isDecryptedVert = YES;
    }
}

- (void)setFrag:(NSString *)frag {
    _frag = frag;
    if (_name.length > 0) {
        _frag = [self decryptWithOriginalStr:frag];
        isDecryptedFrag = YES;
    }
}

- (void)setVert:(NSString *)vert {
    _vert = vert;
    if (_name.length > 0) {
        _vert = [self decryptWithOriginalStr:vert];
        isDecryptedVert = YES;
    }
}

- (NSString *)encryptWithOriginalStr:(NSString *)originalStr {
    NSData *data = [_name dataUsingEncoding:NSUTF8StringEncoding];
    int length = (int)[data length];
    std::string resultString = RDCipherEncrypt((uint8_t*)[data bytes], length, [originalStr UTF8String]);
    NSString *encryptedStr = [NSString stringWithCString:resultString.c_str() encoding:[NSString defaultCStringEncoding]];
    return encryptedStr;
}

- (NSString *)decryptWithOriginalStr:(NSString *)originalStr {
    NSData *data = [_name dataUsingEncoding:NSUTF8StringEncoding];
    int length = (int)[data length];
    std::string resultString = RDCipherDecrypt((uint8_t*)[data bytes], length, [originalStr UTF8String]);
    NSString *decryptedStr = [NSString stringWithCString:resultString.c_str() encoding:[NSString defaultCStringEncoding]];
    if (!decryptedStr || decryptedStr.length == 0) {
        return nil;
    }
    NSString *encryptedStr = [self encryptWithOriginalStr:decryptedStr];
    if ([encryptedStr isEqualToString:originalStr]) {
        return decryptedStr;
    }
    return originalStr;
}

- (NSError *) setShaderTextureParams:(RDTextureParams *)textureParams
{
    return [self setshaderTextureParams:textureParams];
}
- (NSError *) setShaderUniformParams:(NSMutableArray<RDShaderParams*> *)params   isRepeat:(BOOL)isRepeat  forUniform:(NSString *)uniform
{
    return [self setshaderUniformParams:params TimeRepeats:isRepeat forUniform:uniform];
}

- (void)dealloc
{
//    if (self.vertShader)
//        glDeleteShader(self.vertShader);
//
//    if (self.fragShader)
//        glDeleteShader(self.fragShader);
//
//    if (self.filterProgram) {
//        glDeleteProgram(self.filterProgram);
//        self.filterProgram = 0;
//    }
    
    while (self.pUniformList) {
        struct SHADER_UNIFORM_LIST* pList = self.pUniformList->next;
        
        while (self.pUniformList->data) {
            struct SHADER_PARAMS_LIST* pParamsList = self.pUniformList->data->next;
            if(UNIFORM_ARRAY == self.pUniformList->type)
            {
                if(self.pUniformList->data && self.pUniformList->data->array)
                    free(self.pUniformList->data->array);
            }
            free(self.pUniformList->data);
            self.pUniformList->data = pParamsList;
        }
        free(self.pUniformList);
        self.pUniformList = pList;
    }
    while (self.pTextureSamplerList) {
        
        struct SHADER_TEXTURE_SAMPLER2D_LIST* pList = self.pTextureSamplerList->next;
        if(self.pTextureSamplerList->type == RDSample2DBufferTexture && self.pTextureSamplerList->texture)
            glDeleteTextures(1, &self.pTextureSamplerList->texture);
        free(self.pTextureSamplerList);
        self.pTextureSamplerList = pList;
    }
    
}

@end

