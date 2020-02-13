//
//  RDLOTEffectRenderer.m
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//

#import "RDLOTEffectRenderer.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"

@implementation RDLOTEffectRender {
    RDLOTColorInterpolator *colorInterpolator_;
    RDLOTNumberInterpolator *valueInterpolator_;
    NSString* keyMatchName;
    
}

- (void )initGaussBlurWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                         Effect:(RDLOTEffect *_Nonnull)effect
                        calayer:(CALayer* _Nonnull)layer
{
    valueInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.blur.keyframes];
    
    if(inputNode)
    {
        NSLog(@"width :%d height:%d ",(int)layer.bounds.size.width ,(int)layer.bounds.size.height );
        self.outputLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width , layer.bounds.size.height);
        self.outputLayer.anchorPoint = CGPointMake(0, 0);
        //        self.outputLayer.masksToBounds = YES;
        self.outputLayer.contents = ((RDLOTEffectRender *)inputNode).outputLayer.contents;
    }
    else
    {
        UIImage *resultImg = nil;
        CIImage *outputImg = nil;
        CIContext *context = nil;
        CGImageRef cgImg = nil;
        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];//CIMinimumComponent   CIColorInvert
        CGImageRef ref = (__bridge CGImageRef)(layer.contents);
        
        
        UIImage *uiImage = [UIImage imageWithCGImage: ref];
        CIImage *inputImg = [[CIImage alloc] initWithImage:uiImage];
        
        // 设置滤镜属性值为默认值
        [filter setDefaults];
        // 设置输入图像
        [filter setValue:inputImg forKey:@"inputImage"];
        
        //            [filter setValue:[[NSNumber alloc] initWithFloat:29.7] forKey:@"inputRadius"];
        
        // 获取输出图像
        outputImg = [filter valueForKey:@"outputImage"];
        context = [CIContext contextWithOptions:nil];
        cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
        if(CGImageGetWidth(cgImg) == layer.bounds.size.width && CGImageGetHeight(cgImg) == layer.bounds.size.height)
            resultImg = [UIImage imageWithCGImage:cgImg];
        else
        {
            resultImg = [UIImage imageWithCGImage:cgImg];
            float factor_w = (float)CGImageGetWidth(ref)/(float)CGImageGetWidth(cgImg);
            float factor_h = (float)CGImageGetHeight(ref)/(float)CGImageGetHeight(cgImg);
            CGRect rtCrop = CGRectMake(0.5 - factor_w/2.0, 0.5 - factor_h/2.0, factor_w, factor_h);
            CGFloat imageWidth = CGImageGetWidth(cgImg);
            CGFloat imageHeight = CGImageGetHeight(cgImg);
            float imagePro = imageWidth/imageHeight;
            CGSize imageSize = CGSizeMake(layer.bounds.size.width, layer.bounds.size.height);
            float animationPro = imageSize.width/imageSize.height;
            
            if (imagePro != animationPro) {
                CGRect rect;
                if (CGRectEqualToRect(rtCrop, CGRectMake(0, 0, 1.0, 1.0))) {
                    CGFloat width;
                    CGFloat height;
                    if (imageWidth*imageSize.height <= imageHeight*imageSize.width) {
                        width  = imageWidth;
                        height = imageWidth * imageSize.height / imageSize.width;
                    }else {
                        width  = imageHeight * imageSize.width / imageSize.height;
                        height = imageHeight;
                    }
                    rect = CGRectMake((imageWidth - width)/2.0, (imageHeight - height)/2.0, width, height);
                }else {
                    rect = CGRectMake(imageWidth * rtCrop.origin.x, imageHeight * rtCrop.origin.y, imageWidth * rtCrop.size.width, imageHeight * rtCrop.size.height);
                }
                CGImageRef newImageRef = CGImageCreateWithImageInRect(cgImg, rect);
                resultImg = [UIImage imageWithCGImage:newImageRef];
                CGImageRelease(newImageRef);
            }else {
                if (CGRectEqualToRect(rtCrop, CGRectMake(0, 0, 1.0, 1.0))) {
                    resultImg = [UIImage imageWithCGImage:cgImg];
                }else {
                    CGRect rect = CGRectMake(imageWidth * rtCrop.origin.x, imageHeight * rtCrop.origin.y, imageWidth * rtCrop.size.width, imageHeight * rtCrop.size.height);
                    CGImageRef newImageRef = CGImageCreateWithImageInRect(cgImg, rect);
                    resultImg = [UIImage imageWithCGImage:newImageRef];
                    CGImageRelease(newImageRef);
                }
            }
        }
        
        CGImageRelease(cgImg);
        
        
        self.outputLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width , layer.bounds.size.height);
        self.outputLayer.anchorPoint = CGPointMake(0, 0);
        //            colorlayer.outputLayer.position = CGPointMake(0.5, 0.5);
        //            self.outputLayer.anchorPoint = CGPointMake(0.5, 0.5);
        self.outputLayer.masksToBounds = YES;
        self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
    }
}
- (void )initTintWithInputNode:(RDLOTAnimatorNode *)inputNode
                                     Effect:(RDLOTEffect *)effect
                                    calayer:(CALayer* )layer
{
    int type = effect.keyType;
    if (0 == type) {
        
        // 获取对应的插值
        valueInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.color.keyframes];
        if(inputNode)
        {
            NSLog(@"width :%d height:%d ",(int)layer.bounds.size.width ,(int)layer.bounds.size.height );
            self.outputLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width , layer.bounds.size.height);
            self.outputLayer.anchorPoint = CGPointMake(0, 0);
            //        self.outputLayer.masksToBounds = YES;
            self.outputLayer.contents = ((RDLOTEffectRender *)inputNode).outputLayer.contents;
        }
        else
        {
            NSLog(@"error:invalid json format" );
        }
    }
    else if(2 == type)
    {
        // 获取对应的rgba属性
        colorInterpolator_ = [[RDLOTColorInterpolator alloc] initWithKeyframes:effect.color.keyframes];
        for (int i = 0;i < effect.color.keyframes.count;i++)
        {
            CIFilter * filter = nil;
            CGImageRef ref = nil;
            UIImage *uiImage = nil;
            CIImage *inputImg = nil;
            
            
            if(!inputNode)
            {
                filter = [CIFilter filterWithName:@"CIColorMatrix"];//CIMinimumComponent   CIColorInvert   CIColorMatrix
                ref = (__bridge CGImageRef)(layer.contents);
            }
            else
            {
                RDLOTEffectRender* colorlayer = (RDLOTEffectRender *)inputNode;
                filter = [CIFilter filterWithName:@"CIColorMatrix"];//CIMinimumComponent   CIColorInvert   CIMaximumComponent
                ref = (__bridge CGImageRef)(colorlayer.outputLayer.contents);
            }
            
            uiImage = [UIImage imageWithCGImage: ref];
            inputImg = [[CIImage alloc] initWithImage:uiImage];
            
            
            // 设置滤镜属性值为默认值
            [filter setDefaults];
            // 设置输入图像
            [filter setValue:inputImg forKey:@"inputImage"];
            
            // 获取颜色映射，设置rgba映射矩阵
            double r = 0,g = 0,b = 0,a = 0;
            [effect.color.keyframes[i].colorValue getRed:&r green:&g blue:&b alpha:&a];
            NSLog(@"color components  r: %f g: %f b: %f a: %f", r,g,b,a);
            
            if(!inputNode || (!r && !g && !b) || (1.0 == r && 1.0 == g && 1.0 == b))
            {
                //黑白映射一
//                [filter setValue:[[CIVector alloc] initWithX:0.33 Y:0.59 Z:0.11 W:0] forKey:@"inputRVector"];
//                [filter setValue:[[CIVector alloc] initWithX:0.33 Y:0.59 Z:0.11 W:0] forKey:@"inputGVector"];
//                [filter setValue:[[CIVector alloc] initWithX:0.33 Y:0.59 Z:0.11 W:0] forKey:@"inputBVector"];
//                [filter setValue:[[CIVector alloc] initWithX:0 Y:0 Z:0 W:1] forKey:@"inputAVector"];
                
                //黑白映射二
                const CGFloat color_r[5] = {   0.3333 ,0.3333 ,0.3333, 0, 0};
                [filter setValue:[[CIVector alloc] initWithValues:color_r count:5] forKey:@"inputRVector"];
                const CGFloat color_g[5] = {0.3333, 0.3333, 0.3333 ,0 ,0};
                [filter setValue:[[CIVector alloc] initWithValues:color_g count:5] forKey:@"inputGVector"];
                const CGFloat color_b[5] = {0.3333, 0.3333, 0.3333 ,0, 0};
                [filter setValue:[[CIVector alloc] initWithValues:color_b count:5] forKey:@"inputBVector"];
                const CGFloat color_a[5] = {0,0 ,0 ,1, 0};
                [filter setValue:[[CIVector alloc] initWithValues:color_a count:5] forKey:@"inputAVector"];

                
//                const CGFloat matrix_r[5] = {(1.0-r)/r, 0, 0, 0, 0};
//                const CGFloat matrix_g[5] = {0, (1.0-g)/g, 0, 0, 0};
//                const CGFloat matrix_b[5] = {0, 0, (1.0-b)/b, 0, 0};
//                const CGFloat matrix_a[5] = {0, 0, 0, 1, 0};
//                [filter setValue:[[CIVector alloc] initWithValues:matrix_r count:5] forKey:@"inputRVector"];
//                [filter setValue:[[CIVector alloc] initWithValues:matrix_g count:5] forKey:@"inputGVector"];
//                [filter setValue:[[CIVector alloc] initWithValues:matrix_b count:5] forKey:@"inputBVector"];
//                [filter setValue:[[CIVector alloc] initWithValues:matrix_a count:5] forKey:@"inputAVector"];
                
//                [filter setValue:[[CIVector alloc] initWithX:(1.0-r)/r Y:0 Z:0 W:0] forKey:@"inputRVector"];
//                [filter setValue:[[CIVector alloc] initWithX:0 Y:(1.0-g)/g Z:0 W:0] forKey:@"inputGVector"];
//                [filter setValue:[[CIVector alloc] initWithX:0 Y:0 Z:(1.0-b)/b W:0] forKey:@"inputBVector"];
//                [filter setValue:[[CIVector alloc] initWithX:0 Y:0 Z:0 W:a] forKey:@"inputAVector"];
                
            }
            else
            {
                //矩阵映射
                [filter setValue:[[CIVector alloc] initWithX:r Y:0 Z:0 W:0] forKey:@"inputRVector"];
                [filter setValue:[[CIVector alloc] initWithX:0 Y:g Z:0 W:0] forKey:@"inputGVector"];
                [filter setValue:[[CIVector alloc] initWithX:0 Y:0 Z:b W:0] forKey:@"inputBVector"];
                [filter setValue:[[CIVector alloc] initWithX:0 Y:0 Z:0 W:a] forKey:@"inputAVector"];
                
            }
            // 获取输出图像
            CIImage * outputImg = [filter valueForKey:@"outputImage"];
            CIContext * context = [CIContext contextWithOptions:nil];
            CGImageRef cgImg = [context createCGImage:outputImg fromRect:outputImg.extent];
            UIImage *resultImg = [UIImage imageWithCGImage:cgImg];
            CGImageRelease(cgImg);
//          self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
//          self.outputLayer.bounds = CGRectMake(0, 0, 400 , 711);
//          colorlayer.outputLayer.position = CGPointMake(0.5, 0.5);
//          self.outputLayer.anchorPoint = CGPointMake(0.5, 0.5);
//          self.outputLayer.masksToBounds = YES;
            self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
        }

    }
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               Effect:(RDLOTEffect *_Nonnull)effect
                                   calayer:(CALayer* _Nonnull)layer
{
    self = [super initWithInputNode:inputNode keyName:effect.keyName];
    if (self) {

        keyMatchName = effect.keyMatchName;
        
        if([keyMatchName rangeOfString:@"Tint"].location != NSNotFound)
            [self initTintWithInputNode:inputNode Effect:effect calayer:layer];
        else if([keyMatchName rangeOfString:@"Blur"].location != NSNotFound)
            [self initGaussBlurWithInputNode:inputNode Effect:effect calayer:layer];
        else
        {
            
        }
        
    }
    return self;
    
}

- (NSDictionary *)valueInterpolators {
    return @{@"Color" : colorInterpolator_,
             @"Opacity" : valueInterpolator_};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
    return [colorInterpolator_ hasUpdateForFrame:frame]  || [valueInterpolator_ hasUpdateForFrame:frame];
}

- (void)performLocalUpdate {

    if (colorInterpolator_) {

        CGColorRef color = [colorInterpolator_ colorForFrame:self.currentFrame];
        NSUInteger num = CGColorGetNumberOfComponents(color);
        const CGFloat *colorComponents = CGColorGetComponents(color);
        for (int i = 0; i < num; ++i) {
            NSLog(@"color components %d: %f", i, colorComponents[i]);
        }
    }

    if(valueInterpolator_ && [keyMatchName rangeOfString:@"Blur"].location != NSNotFound)
    {
        float value = [valueInterpolator_ floatValueForFrame:self.currentFrame];
        //    NSLog(@"slider numInterpolator = %g ",value);
        self.outputLayer.opacity = value;

    }
    else if(valueInterpolator_)
    {
        float value = [valueInterpolator_ floatValueForFrame:self.currentFrame];
        NSLog(@"slider numInterpolator = %g ",value);
        self.outputLayer.opacity = value/100.0;
    }
}

- (NSDictionary *)actionsForRenderLayer {
    return @{
             @"fillColor": [NSNull null],
             @"opacity" : [NSNull null]};
}

@end
