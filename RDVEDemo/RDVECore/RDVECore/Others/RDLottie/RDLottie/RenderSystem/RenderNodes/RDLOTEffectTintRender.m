//
//  RDLOTEffectTintRender.m
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//

#import "RDLOTEffectTintRender.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"



@implementation RDLOTEffectTintRender {
    RDLOTColorInterpolator *colorInterpolator_;
    RDLOTNumberInterpolator *valueInterpolator_;
    NSString* keyMatchName;
    CGImageRef imageCopy;
    CIContext* context ;
    CALayer* layerSrc ;
    
}

-(CGImageRef) getImageFromCIFilterWith:(RDLOTAnimatorNode *)inputNode
                   Effect:(RDLOTEffectTint *)effect
                  calayer:(CALayer* )layer
{
    
    CIFilter * filter = nil;
    CGImageRef currentImage = nil;
    UIImage *uiImage = nil;
    CIImage *inputImg = nil;
    CIImage *outputImg = nil;
    CIContext *context = nil;
    CGImageRef cgImg = nil;
    UIImage *resultImg = nil;
    CGImageRef dstImageRef = nil;
    CGFloat r = 0,g = 0,b = 0,a = 0;
    NSArray<RDLOTKeyframe *> * keyframes = nil;
    
    NSMutableArray <AdbeEffect*>* tintEffect = inputNode.effectArray;
    if (tintEffect.count < 2) {
        NSLog(@"%s: json data error! ", __PRETTY_FUNCTION__);
        return nil;
    }

    
    // 1.绘制饱和度(着色)
    CGFloat value = effect.color.keyframes[0].floatValue;
    if (value == 100 || value == 0)
    {
        currentImage = (__bridge CGImageRef)(layer.contents);
        filter = [CIFilter filterWithName:@"CIColorControls"];//饱和度
        uiImage = [UIImage imageWithCGImage: currentImage];
        inputImg = [[CIImage alloc] initWithImage:uiImage];
        // 设置滤镜属性值为默认值
        [filter setDefaults];
        // 设置输入图像
        [filter setValue:inputImg forKey:@"inputImage"];
        [filter setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputSaturation"];


        // 获取输出图像
        outputImg = [filter valueForKey:@"outputImage"];
        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
        resultImg = [UIImage imageWithCGImage:cgImg];
        CGImageRelease(cgImg);
        dstImageRef = resultImg.CGImage;
    }
    
    
    // 2.将黑色映射到 rgba
    keyframes = tintEffect[0].keyframes;
    for (int i = 0; i< keyframes.count; i++) {
        // 获取颜色映射对应的rgba
        r = 0.0;
        g = 0.0;
        b = 0.0;
        a = 0.0;
        [keyframes[i].colorValue getRed:&r green:&g blue:&b alpha:&a];
        NSLog(@"color components  r: %f g: %f b: %f a: %f", r,g,b,a);
        if((!r && !g && !b) || (1.0 == r && 1.0 == g && 1.0 == b))
        {
            // 常规Tint001 映射到 (0,0,0,a) 或者 (1,1,1,a)
            continue;
        }
        else
        {
            if(!dstImageRef)
                currentImage = (__bridge CGImageRef)(layer.contents);
            else
                currentImage = dstImageRef;
            filter = [CIFilter filterWithName:@"CIColorMatrix"];//颜色矩阵
            uiImage = [UIImage imageWithCGImage: currentImage];
            inputImg = [[CIImage alloc] initWithImage:uiImage];
            // 设置滤镜属性值为默认值
            [filter setDefaults];
            // 设置输入图像
            [filter setValue:inputImg forKey:@"inputImage"];
            
            [filter setValue:[[CIVector alloc] initWithX:r Y:g Z:b ] forKey:@"inputBiasVector"];
            // 获取输出图像
            outputImg = [filter valueForKey:@"outputImage"];
            context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
            cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
            resultImg = [UIImage imageWithCGImage:cgImg];
            CGImageRelease(cgImg);
            dstImageRef = resultImg.CGImage;
        }
    }


    // 3.将白色映射到 rgba
    keyframes = tintEffect[1].keyframes;
    for (int i = 0; i< keyframes.count; i++) {
        r = 0.0;
        g = 0.0;
        b = 0.0;
        a = 0.0;
        // 获取颜色映射对应的rgba
        [keyframes[i].colorValue getRed:&r green:&g blue:&b alpha:&a];
        NSLog(@"color components  r: %f g: %f b: %f a: %f", r,g,b,a);

        if(!dstImageRef)
            currentImage = (__bridge CGImageRef)(layer.contents);
        else
            currentImage = dstImageRef;
        if((!r && !g && !b) || (1.0 == r && 1.0 == g && 1.0 == b))
        {
            
            filter = [CIFilter filterWithName:@"CIColorControls"];//饱和度/对比度/亮度 CIPinchDistortion  CIColorControls
            uiImage = [UIImage imageWithCGImage: currentImage];
            inputImg = [[CIImage alloc] initWithImage:uiImage];
            // 设置滤镜属性值为默认值
            [filter setDefaults];
            // 设置输入图像
            [filter setValue:inputImg forKey:@"inputImage"];
            [filter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSaturation"];
        }
        else{

            filter = [CIFilter filterWithName:@"CIColorMatrix"];//颜色矩阵
            uiImage = [UIImage imageWithCGImage: currentImage];
            inputImg = [[CIImage alloc] initWithImage:uiImage];
            // 设置滤镜属性值为默认值
            [filter setDefaults];
            // 设置输入图像
            [filter setValue:inputImg forKey:@"inputImage"];
            [filter setValue:[[CIVector alloc] initWithX:r Y:0.0 Z:0.0 W:0.0] forKey:@"inputRVector"];
            [filter setValue:[[CIVector alloc] initWithX:0.0 Y:g Z:0.0 W:0.0] forKey:@"inputGVector"];
            [filter setValue:[[CIVector alloc] initWithX:0.0 Y:0.0 Z:b W:0.0] forKey:@"inputBVector"];
            [filter setValue:[[CIVector alloc] initWithX:0.0 Y:0.0 Z:0.0 W:a] forKey:@"inputAVector"];
        }
        // 获取输出图像
        outputImg = [filter valueForKey:@"outputImage"];
        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
        resultImg = [UIImage imageWithCGImage:cgImg];
        CGImageRelease(cgImg);
        dstImageRef = resultImg.CGImage;

    }

    return dstImageRef;
}
- (bool )initTintWithInputNode:(RDLOTAnimatorNode *)inputNode
                                     Effect:(RDLOTEffectTint *)effect
                                    calayer:(CALayer* )layer
{
    bool result = false;
    
    //保存原始画面
    layerSrc = layer;
    
    
    if (0 == effect.keyType) {
        
        //绘制上下文
        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        
        // 获取对应的插值
        valueInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.color.keyframes];
        if(inputNode)
        {
            //保存节点
            AdbeEffect* tintEffect = [[AdbeEffect alloc] init];
            tintEffect.keyframes = effect.color.keyframes;
            tintEffect.keyMatchName = keyMatchName;
            if(!inputNode)
                self.effectArray = [[NSMutableArray alloc] init];
            else
                self.effectArray = inputNode.effectArray;
            [self.effectArray addObject:tintEffect];
            
            
            
            NSLog(@"width :%d height:%d ",(int)layer.bounds.size.width ,(int)layer.bounds.size.height );
            self.outputLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width , layer.bounds.size.height);
            self.outputLayer.anchorPoint = CGPointMake(0, 0);
            self.outputLayer.contents = layer.contents;//(__bridge id _Nullable)([self getImageFromCIFilterWith:inputNode Effect:effect calayer:layer]);
            result = true;
        }
        else
        {
            result = false;
            NSLog(@"error:invalid json format" );
        }
    }
    else if(2 == effect.keyType)
    {
        
        // 获取对应的rgba属性
        colorInterpolator_ = [[RDLOTColorInterpolator alloc] initWithKeyframes:effect.color.keyframes];
        if([keyMatchName rangeOfString:@"Tint-0001"].location != NSNotFound ||
           [keyMatchName rangeOfString:@"Tint-0002"].location != NSNotFound)
        {
            //将黑色映射到001
            //将白色映射到002
            AdbeEffect* tintEffect = [[AdbeEffect alloc] init];
            tintEffect.keyframes = effect.color.keyframes;
            tintEffect.keyMatchName = keyMatchName;
            if(!inputNode)
                self.effectArray = [[NSMutableArray alloc] init];
            else
                self.effectArray = inputNode.effectArray;
            [self.effectArray addObject:tintEffect];
            result = true;
        }
        else
            NSLog(@"%s: Warning: %s effect not supported! ", __PRETTY_FUNCTION__, [keyMatchName UTF8String]);
        
        self.outputLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width , layer.bounds.size.height);
        self.outputLayer.anchorPoint = CGPointMake(0, 0);
        self.outputLayer.contents = nil;//layer.contents;
    }
    
    return result;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               Effect:(RDLOTEffectTint *_Nonnull)effect
                                   calayer:(CALayer* _Nonnull)layer
{
    self = [super initWithInputNode:inputNode keyName:effect.keyName];
    if (self) {

        bool matrixRender = false;
        keyMatchName = effect.keyMatchName;
        if([keyMatchName rangeOfString:@"Tint"].location != NSNotFound)
            matrixRender = [self initTintWithInputNode:inputNode Effect:effect calayer:layer];
        else
        {
            
        }
        
        if(!matrixRender)
            return nil;
    }
    return self;
    
}

- (void)refreshContents:(CALayer *)layer {
    layerSrc = layer;
    if (self.outputLayer.contents) {
        self.outputLayer.contents = layer.contents;
    }    
}

- (NSDictionary *)valueInterpolators {
    return @{@"Color" : colorInterpolator_,
             @"Opacity" : valueInterpolator_};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
    return [colorInterpolator_ hasUpdateForFrame:frame]  || [valueInterpolator_ hasUpdateForFrame:frame];
}

- (void)performLocalUpdate {



    if(valueInterpolator_)
    {
    
        float curFrame = [self.currentFrame floatValue];
        float curValue = 0;
        CIFilter * filter = nil;
        CGImageRef currentImage = nil;
        UIImage *uiImage = nil;
        CIImage *inputImg = nil;
        CIImage *outputImg = nil;
        CGImageRef cgImg = nil;
        UIImage *resultImg = nil;
        CGImageRef dstImageRef = nil;
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        currentImage = (__bridge CGImageRef)(layerSrc.contents);

        filter = [CIFilter filterWithName:@"RDLOTTintCIFilter"];//饱和度
        uiImage = [UIImage imageWithCGImage: currentImage];
        inputImg = [[CIImage alloc] initWithImage:uiImage];
        // 设置滤镜属性值为默认值
        [filter setDefaults];
        // 设置输入图像
        [filter setValue:inputImg forKey:@"inputImage"];
        // 设置输入参数
        [filter setValue:self.effectArray forKey:@"effectArray"];
        [filter setValue:self.currentFrame forKey:@"curFrame"];

        // 获取输出图像
        outputImg = [filter valueForKey:@"outputImage"];
        //        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
        resultImg = [UIImage imageWithCGImage:cgImg];
        CGImageRelease(cgImg);
        dstImageRef = resultImg.CGImage;
        self.outputLayer.contents = (__bridge id _Nullable)(dstImageRef);
        
        //计算 opacity
        AdbeEffect* effect = [self.effectArray objectAtIndex:2];
        if (effect.keyframes.count >= 2) {
            bool findValue = false;
            for (int i = 0; i < effect.keyframes.count-1; i++)
            {
                RDLOTKeyframe* cur = effect.keyframes[i];
                RDLOTKeyframe* next = effect.keyframes[i+1];
                        
                //获取对应的时间片
                float startFrame = [cur.keyframeTime floatValue];
                float endFrame = [next.keyframeTime floatValue];
                
                if (curFrame >= startFrame && curFrame < endFrame) {

                    if (cur.floatValue > next.floatValue)
                        curValue = cur.floatValue - (curFrame - startFrame)/(endFrame-startFrame)*(cur.floatValue - next.floatValue);
                    else
                        curValue = cur.floatValue + (curFrame - startFrame)/(endFrame-startFrame)*(next.floatValue - cur.floatValue);
                    findValue = true;
                    break;
                }
            }
            if (!findValue) {
                
                RDLOTKeyframe* first = effect.keyframes[0];
                RDLOTKeyframe* last = effect.keyframes[effect.keyframes.count-1];
                
                if (curFrame < [first.keyframeTime floatValue])
                    curValue = first.floatValue;
                else if(curFrame >= [last.keyframeTime floatValue])
                    curValue = last.floatValue;
                else
                    NSLog(@"没有找到对应的value");
            }
        }
        else
            curValue = [valueInterpolator_ floatValueForFrame:self.currentFrame];

        if(curValue != 100.0)
            self.outputLayer.opacity = curValue/100.0;
        else
            self.outputLayer.opacity = 1.0;
        NSLog(@"draw time:%g", CFAbsoluteTimeGetCurrent() - start);
        
        

    }

}

- (NSDictionary *)actionsForRenderLayer {
    return @{
             @"fillColor": [NSNull null],
             @"opacity" : [NSNull null]};
}

@end
