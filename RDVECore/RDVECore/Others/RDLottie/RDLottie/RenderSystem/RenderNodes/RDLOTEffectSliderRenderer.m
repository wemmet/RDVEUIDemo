//
//  RDLOTPathAnimator.m
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//


#import "RDLOTEffectSliderRenderer.h"
#import "RDLOTPathInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"

@implementation RDLOTEffecSliderRender {

    RDLOTNumberInterpolator *numInterpolator_;
    float intensity; //高斯模糊强度
   
}



- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                              effectSlider:(RDLOTEffectSlider *_Nonnull)slider
                                   calayer:(CALayer* _Nonnull)layer
{
    self = [super initWithInputNode:inputNode keyName:slider.keyname];
    if (self) {
        
        intensity = 0;
        numInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:slider.value.keyframes];
        
        if(inputNode)
        {
            NSLog(@"width :%d height:%d ",(int)layer.bounds.size.width ,(int)layer.bounds.size.height );
            self.outputLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width , layer.bounds.size.height);
            self.outputLayer.anchorPoint = CGPointMake(0, 0);
            //        self.outputLayer.masksToBounds = YES;
            self.outputLayer.contents = ((RDLOTEffecSliderRender *)inputNode).outputLayer.contents;
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
            
            intensity = 30;
          
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
    return self;
}


//- (void)rebuildOutputs {
//    self.outputLayer.path = self.inputNode.outputPath.CGPath;
//}

- (NSDictionary *)actionsForRenderLayer {
    return @{
             @"fillColor": [NSNull null],
             @"opacity" : [NSNull null]};
}



- (void)performLocalUpdate {

    float value = [numInterpolator_ floatValueForFrame:self.currentFrame];
//    NSLog(@"slider numInterpolator = %g ",value);
    if(intensity > 1)
        self.outputLayer.opacity = value;
    else
        self.outputLayer.opacity = value/100.0;
    

}

//- (void)rebuildOutputs {
//    self.outputLayer.path = self.inputNode.outputPath.CGPath;
//}



@end
