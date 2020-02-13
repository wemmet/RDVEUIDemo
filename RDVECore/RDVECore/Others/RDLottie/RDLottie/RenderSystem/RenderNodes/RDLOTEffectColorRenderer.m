//
//  RDLOTFillRenderer.m
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTEffectColorRenderer.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"

@implementation RDLOTEffectColorRenderer {
    RDLOTColorInterpolator *colorInterpolator_;
    
}




- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               effectColor:(RDLOTEffectColor *_Nonnull)color
                                   calayer:(CALayer* )layer
{
    self = [super initWithInputNode:inputNode keyName:color.keyname];
    if (self) {

        // 获取对应的rgba属性
        colorInterpolator_ = [[RDLOTColorInterpolator alloc] initWithKeyframes:color.color.keyframes];
 
        for (int i = 0;i < color.color.keyframes.count;i++)
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
                RDLOTEffectColorRenderer* colorlayer = (RDLOTEffectColorRenderer *)inputNode;
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
            [color.color.keyframes[i].colorValue getRed:&r green:&g blue:&b alpha:&a];
            NSLog(@"color components  r: %f g: %f b: %f a: %f", r,g,b,a);
            
            if(!inputNode || (!r && !g && !b) || (1.0 == r && 1.0 == g && 1.0 == b))
            {
                //黑白映射
                [filter setValue:[[CIVector alloc] initWithX:0.33 Y:0.59 Z:0.11 W:0] forKey:@"inputRVector"];
                [filter setValue:[[CIVector alloc] initWithX:0.33 Y:0.59 Z:0.11 W:0] forKey:@"inputGVector"];
                [filter setValue:[[CIVector alloc] initWithX:0.33 Y:0.59 Z:0.11 W:0] forKey:@"inputBVector"];
                [filter setValue:[[CIVector alloc] initWithX:0 Y:0 Z:0 W:1] forKey:@"inputAVector"];
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
    return self;
    
}

- (NSDictionary *)valueInterpolators {
    return @{@"Color" : colorInterpolator_};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
    return [colorInterpolator_ hasUpdateForFrame:frame];
}

- (void)performLocalUpdate {
    
    CGColorRef color = [colorInterpolator_ colorForFrame:self.currentFrame];
    NSUInteger num = CGColorGetNumberOfComponents(color);
    const CGFloat *colorComponents = CGColorGetComponents(color);
    UIImage* img = self.outputLayer.contents;
    for (int i = 0; i < num; ++i) {
        //red is componentColors[0];
        //green is componentColors[1];
        //blue is componentColors[2];
        //alpha is componentColors[3];
        NSLog(@"color components %d: %f", i, colorComponents[i]);
        
    }
    
}

//- (void)rebuildOutputs {
//    self.outputLayer.path = self.inputNode.outputPath.CGPath;
//}

- (NSDictionary *)actionsForRenderLayer {
    return @{
             @"fillColor": [NSNull null],
             @"opacity" : [NSNull null]};
}

@end
