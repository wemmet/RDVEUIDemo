//
//  RDLOTEffectBlurRender.m
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//

#import "RDLOTEffectBlurRender.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"


#define GAUSS_BLUR  (@"Gauss")
#define MOTION_BLUR  (@"Motion")
#define RADIAL_BLUR  (@"Radial")


@implementation RDLOTEffectBlurRender {
    RDLOTNumberInterpolator *valueInterpolator;
    NSString* keyMatchName;
    bool processBlur; //CIGaussianBlur比较耗时，在预览时处理模糊
    CALayer* layerSrc;
    CIContext *context;     //绘制上下文
    CGImageRef imageCopy;
    CGSize frameSize;       // 当前画布大小
    
}
- (bool )initRadialBlurWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                         Effect:(RDLOTEffectBlur *_Nonnull)effect
                        calayer:(CALayer* _Nonnull)layer
{
    // 径向模糊
    
    if(effect.keyType == 0 || effect.keyType == 3)
    {
        valueInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.blur.keyframes];
        
        // 保存数据
        AdbeEffect* blur = [[AdbeEffect alloc] init];
        blur.keyframes = effect.blur.keyframes;
        blur.keyMatchName = keyMatchName;
        if(!inputNode)
            self.effectArray = [[NSMutableArray alloc] init];
        else
            self.effectArray = inputNode.effectArray;
        [self.effectArray addObject:blur];
        
        // 画布大小
        frameSize = effect.frameSize;
        self.outputLayer.bounds = layer.bounds;
        self.outputLayer.anchorPoint = CGPointMake(0, 0);
        self.outputLayer.masksToBounds = YES;
        self.outputLayer.contents =  layer.contents;
        layerSrc = layer;
        if(effect.keyType == 0)
        {
            processBlur = false;
            // copy layer
            CGImageRef inImageRef = (__bridge CGImageRef)(layer.contents);
            int width = (int)CGImageGetWidth(inImageRef);
            int height = (int)CGImageGetHeight(inImageRef);
            if (width > 0 && height > 0)
                imageCopy = CGImageCreateCopy(inImageRef);
        }
        else
        {
            self.outputLayer.contents = nil;
            imageCopy = nil;
            processBlur = true;
        }
            
        
        // cifilter上下文
        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];

        // copy layer
        CGImageRef inImageRef = (__bridge CGImageRef)(layer.contents);
        int width = (int)CGImageGetWidth(inImageRef);
        int height = (int)CGImageGetHeight(inImageRef);
        if (width > 0 && height > 0)
           imageCopy = CGImageCreateCopy(inImageRef);

        return true;
    }
    else
        return false;
    
    
}
- (bool )initMotionBlurWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                         Effect:(RDLOTEffectBlur *_Nonnull)effect
                        calayer:(CALayer* _Nonnull)layer
{
    // 定向模糊
    if(effect.keyType != 0)
        return false;
    
    valueInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.blur.keyframes];
    // 保存数据
    AdbeEffect* blur = [[AdbeEffect alloc] init];
    blur.keyframes = effect.blur.keyframes;
    blur.keyMatchName = keyMatchName;
    if(!inputNode)
        self.effectArray = [[NSMutableArray alloc] init];
    else
        self.effectArray = inputNode.effectArray;
    [self.effectArray addObject:blur];
    // 画布大小
    frameSize = effect.frameSize;
    
    self.outputLayer.bounds = layer.bounds;
    self.outputLayer.anchorPoint = CGPointMake(0, 0);
    self.outputLayer.masksToBounds = YES;
    self.outputLayer.contents =  layer.contents;
    layerSrc = layer;
    if([keyMatchName rangeOfString:@"0002"].location != NSNotFound )
    {
        // 模糊长度需要时时更新
        processBlur = false;
        // copy layer
        CGImageRef inImageRef = (__bridge CGImageRef)(layer.contents);
        int width = (int)CGImageGetWidth(inImageRef);
        int height = (int)CGImageGetHeight(inImageRef);
        if (width > 0 && height > 0)
           imageCopy = CGImageCreateCopy(inImageRef);
    }
    else
    {
        // 模糊方向
        processBlur = true;
        self.outputLayer.contents = nil;
        imageCopy = nil;
    }
    
    // cifilter上下文
    context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];

    

    return true;
}


- (bool )initGaussBlurWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                         Effect:(RDLOTEffectBlur *_Nonnull)effect
                        calayer:(CALayer* _Nonnull)layer
{
    // 高斯模糊
    if(effect.keyType != 0)
        return false;
    
    valueInterpolator = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.blur.keyframes];
    
    AdbeEffect* blur = [[AdbeEffect alloc] init];
    blur.keyframes = effect.blur.keyframes;
    blur.keyMatchName = keyMatchName;
    
    
    
    // 保存json数据
    if(!inputNode)
        self.effectArray = [[NSMutableArray alloc] init];
    else
        self.effectArray = inputNode.effectArray;
    [self.effectArray addObject:blur];
    
    
    // 画布大小
    frameSize = effect.frameSize;
    
    self.outputLayer.bounds = layer.bounds;
    self.outputLayer.anchorPoint = CGPointMake(0, 0);
    self.outputLayer.masksToBounds = YES;
    self.outputLayer.contents =  layer.contents;
    layerSrc = layer;
    processBlur = false;
    
    // cifilter上下文
    context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];

    // copy layer
    CGImageRef inImageRef = (__bridge CGImageRef)(layer.contents);
    int width = (int)CGImageGetWidth(inImageRef);
    int height = (int)CGImageGetHeight(inImageRef);
    if (width > 0 && height > 0)
       imageCopy = CGImageCreateCopy(inImageRef);

    return true;
}


- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               Effect:(RDLOTEffectBlur *_Nonnull)effect
                                   calayer:(CALayer* _Nonnull)layer
{
    self = [super initWithInputNode:inputNode keyName:effect.keyName];
    if (self) {

        //CIGaussianBlur比较耗时，在预览时处理模糊
        
        bool matrixRender = false;
        keyMatchName = effect.keyMatchName;
        if([keyMatchName rangeOfString:GAUSS_BLUR].location != NSNotFound)     //高斯模糊
            matrixRender = [self initGaussBlurWithInputNode:inputNode Effect:effect calayer:layer];
        else if([keyMatchName rangeOfString:RADIAL_BLUR].location != NSNotFound)  //径向模糊
            matrixRender = [self initRadialBlurWithInputNode:inputNode Effect:effect calayer:layer];
        else if([keyMatchName rangeOfString:MOTION_BLUR].location != NSNotFound)  //定向模糊
            matrixRender = [self initMotionBlurWithInputNode:inputNode Effect:effect calayer:layer];
        else
        {
            
        }
        
        if(!matrixRender)
            return nil;
    }
    return self;
    
}

- (void)refreshContents:(CALayer *)layer {
    self.outputLayer.contents =  layer.contents;
    layerSrc = layer;
    if (imageCopy) {
        CGImageRelease(imageCopy);
        CGImageRef inImageRef = (__bridge CGImageRef)(layer.contents);
        int width = (int)CGImageGetWidth(inImageRef);
        int height = (int)CGImageGetHeight(inImageRef);
        if (width > 0 && height > 0)
           imageCopy = CGImageCreateCopy(inImageRef);
    }
}

- (NSDictionary *)valueInterpolators {
    return @{@"Opacity" : valueInterpolator};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
    return [valueInterpolator hasUpdateForFrame:frame];
}
- (UIImage* )getOutPutImageFromCGImageRef:(CGImageRef )cgImg
{
    UIImage *resultImg = nil;
    if(CGImageGetWidth(cgImg) == self.outputLayer.bounds.size.width && CGImageGetHeight(cgImg) == self.outputLayer.bounds.size.height)
        resultImg = [UIImage imageWithCGImage:cgImg];
    else
    {
        //画面裁剪
        resultImg = [UIImage imageWithCGImage:cgImg];
        float factor_w = CGImageGetWidth(imageCopy)/(float)CGImageGetWidth(cgImg);
        float factor_h = CGImageGetHeight(imageCopy)/(float)CGImageGetHeight(cgImg);
        CGRect rtCrop = CGRectMake(0.5 - factor_w/2.0, 0.5 - factor_h/2.0, factor_w, factor_h);
        CGFloat imageWidth = CGImageGetWidth(cgImg);
        CGFloat imageHeight = CGImageGetHeight(cgImg);
        float imagePro = imageWidth/imageHeight;
        CGSize imageSize = CGSizeMake(self.outputLayer.bounds.size.width, self.outputLayer.bounds.size.height);
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
    return resultImg;
}

- (void )renderRotateRadialBlur
{
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    UIImage *resultImg = nil;
    CIImage *outputImg = nil;
    CGImageRef cgImg = nil;
    CIFilter *filter = nil;
    UIImage *uiImage = [UIImage imageWithCGImage: imageCopy];
    CIImage *inputImg = [[CIImage alloc] initWithImage:uiImage];
    int w = layerSrc.bounds.size.width;
    int h = layerSrc.bounds.size.height;
    CGPoint center = CGPointMake(0, 0);
    
    filter = [CIFilter filterWithName:@"CITwirlDistortion"];// CICircularWrap  CITwirlDistortion  CILightTunnel  CIVortexDistortion
    // 设置滤镜属性值为默认值
    [filter setDefaults];
//    RDLOTKeyframe* effect = [self.effectArray objectAtIndex:0].keyframes[0];
    // 旋转角度
//    if(effect.floatValue == 270 || effect.floatValue == 90|| effect.floatValue == -270 || effect.floatValue == -90)
//        [filter setValue:[[NSNumber alloc] initWithFloat:0.0] forKey:@"inputAngle"];
//    else
//        [filter setValue:[[NSNumber alloc] initWithFloat:M_PI/2.0] forKey:@"inputAngle"];
    
    // 中心
   // 中心
    RDLOTKeyframe* effect = [self.effectArray objectAtIndex:1].keyframes[0];
    if (w == frameSize.width && h == frameSize.height) {
        center.x = (float)[[effect.arrayValue objectAtIndex:0] intValue]/(float)frameSize.width*CGImageGetWidth(imageCopy);;
        center.y = (float)[[effect.arrayValue objectAtIndex:1] intValue]/(float)frameSize.height*CGImageGetHeight(imageCopy);
    }
    else
    {
        center.x = (float)[[effect.arrayValue objectAtIndex:0] intValue];
        center.y = (float)[[effect.arrayValue objectAtIndex:1] intValue];
    }
    
    [filter setValue:[[CIVector alloc] initWithX:center.x Y:center.y] forKey:@"inputCenter"];
    [filter setValue:[[NSNumber alloc] initWithFloat:3.14] forKey:@"inputAngle"];
//    [filter setValue:[[NSNumber alloc] initWithFloat:800] forKey:@"inputRadius"];
//    [filter setValue:[[NSNumber alloc] initWithFloat:90] forKey:@"inputRotation"];
    
    // 设置输入图像
    [filter setValue:inputImg forKey:@"inputImage"];
    outputImg = [filter valueForKey:@"outputImage"];
    //        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    
    cgImg = [context createCGImage:outputImg fromRect:[outputImg extent]];
    resultImg = [self getOutPutImageFromCGImageRef:cgImg];
    if(cgImg)
        CGImageRelease(cgImg);
    cgImg = nil;
    
    self.outputLayer.masksToBounds = YES;
    self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
    self.outputLayer.opacity = 1.0;
    NSLog(@"rotate time:%f ",CFAbsoluteTimeGetCurrent() - start);
}

- (void )renderGaussBlur
{
    if(!processBlur && imageCopy)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        UIImage *resultImg = nil;
        CIImage *outputImg = nil;
        CGImageRef cgImg = nil;
        CIFilter *filter = nil;
        UIImage *uiImage = [UIImage imageWithCGImage: imageCopy];
        CIImage *inputImg = [[CIImage alloc] initWithImage:uiImage];
        
        filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        // 设置滤镜属性值为默认值
        [filter setDefaults];
        // 设置输入图像
        [filter setValue:inputImg forKey:@"inputImage"];
        outputImg = [filter valueForKey:@"outputImage"];
        //        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
        
        cgImg = [context createCGImage:outputImg fromRect:[outputImg extent]];
        resultImg = [self getOutPutImageFromCGImageRef:cgImg];
        
        if(cgImg)
            CGImageRelease(cgImg);
        cgImg = nil;
        
        self.outputLayer.masksToBounds = YES;
        self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
        processBlur = true;
        //        layerSrc.contents = nil;
        NSLog(@"blur init name:%@ ",keyMatchName);
    }
    
    
    //设置当前的模糊参数
    CGFloat progress = [valueInterpolator progressForFrame:self.currentFrame];
    float maxBlurValue = 0;
    float value = 0;
    
    for (int j = 0; j<self.effectArray.count; j++) {
        AdbeEffect* effect = [self.effectArray objectAtIndex:j];
        for(int x = 0;x<effect.keyframes.count;x++)
            maxBlurValue = effect.keyframes[x].floatValue > maxBlurValue ? effect.keyframes[x].floatValue : maxBlurValue;
    }
    AdbeEffect* blur = [self.effectArray objectAtIndex:0];
    float curFrame = [self.currentFrame intValue];
    bool updatePositionSuccess = false;
    
    if(blur.keyframes.count >= 2)
    {
        for (int i = 0; i < blur.keyframes.count-1; i++) {
            RDLOTKeyframe* cur = blur.keyframes[i];
            RDLOTKeyframe* next = blur.keyframes[i+1];
            
            //获取对应的时间片
            float startFrame = [cur.keyframeTime intValue];
            float endFrame = [next.keyframeTime intValue];
            
            if (curFrame >= startFrame && curFrame < endFrame)
            {
                progress = (curFrame - startFrame) / (endFrame - startFrame);
                if(cur.floatValue > next.floatValue)
                    value = (cur.floatValue - fabs(cur.floatValue - next.floatValue)*progress);
                else
                    value = (cur.floatValue + fabs(cur.floatValue - next.floatValue)*progress);
                updatePositionSuccess = true;
                break;
            }
        }
        if (!updatePositionSuccess) {
            RDLOTKeyframe* keyFrame = nil;
            if (curFrame <= [blur.keyframes[0].keyframeTime floatValue])    // 比第一个元素小
                keyFrame = blur.keyframes[0];
            else
                keyFrame = blur.keyframes[blur.keyframes.count-1];     //比最后一个元素大
            value = keyFrame.floatValue;
        }
    }
    else
        value = [valueInterpolator floatValueForFrame:self.currentFrame];
    value = value/maxBlurValue;
    NSLog(@"name:%@ self :%p currentFrame:%d value = %g maxBlurValue:%f progress:%f",keyMatchName,self,[self.currentFrame intValue],value,maxBlurValue,progress);
    self.outputLayer.opacity = value;
}

-(CGPoint) getCenterPointFromKeyframe:(RDLOTKeyframe*) keyFrame LayerWidth:(float)w LayerHeight:(float)h
{
    CGPoint center = CGPointMake(0, 0);
    if (w == frameSize.width && h == frameSize.height) {
        center.x = (float)[[keyFrame.arrayValue objectAtIndex:0] doubleValue]/(float)frameSize.width*CGImageGetWidth(imageCopy);;
        center.y = h - (float)[[keyFrame.arrayValue objectAtIndex:1] doubleValue]/(float)frameSize.height*CGImageGetHeight(imageCopy);
    }
    else
    {
        center.x = (float)[[keyFrame.arrayValue objectAtIndex:0] doubleValue];
        center.y = h - (float)[[keyFrame.arrayValue objectAtIndex:1] doubleValue];
    }
    return center;
}

- (void )renderRadialBlur
{

    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    UIImage *resultImg = nil;
    CIImage *outputImg = nil;
    CGImageRef cgImg = nil;
    CIFilter *filter = nil;
    UIImage *uiImage = [UIImage imageWithCGImage: imageCopy];
    CIImage *inputImg = [[CIImage alloc] initWithImage:uiImage];
    
    float curFrame = [self.currentFrame floatValue];
    float radius = 0.0;
    bool updatePositionSuccess = false;
    int w = layerSrc.bounds.size.width;
    int h = layerSrc.bounds.size.height;
    CGPoint center = CGPointMake(0, 0);
    filter = [CIFilter filterWithName:@"CIZoomBlur"];
    // 设置滤镜属性值为默认值
    [filter setDefaults];
    
    //计算模糊长度
    AdbeEffect* effect = [self.effectArray objectAtIndex:0];
    if (effect.keyframes.count >= 2) {
        for (int i = 0 ; i< effect.keyframes.count - 1; i++) {
            RDLOTKeyframe* cur = effect.keyframes[i];
            RDLOTKeyframe* next = effect.keyframes[i+1];
            
            //获取对应的时间片
            float startFrame = [cur.keyframeTime floatValue];
            float endFrame = [next.keyframeTime floatValue];
            
            if (curFrame >= startFrame && curFrame < endFrame)
            {
                float progress = (curFrame - startFrame)/(endFrame - startFrame);
                if (cur.floatValue > next.floatValue)
                    radius = cur.floatValue - fabs(cur.floatValue - next.floatValue)*progress;
                else
                    radius = cur.floatValue + fabs(cur.floatValue - next.floatValue)*progress;
                
                updatePositionSuccess = true;
                break;
            }
        }
    }
    else
        radius = effect.keyframes[0].floatValue;
    
    if (!updatePositionSuccess) {
        RDLOTKeyframe* cur = nil;
        if (effect.keyframes.count >= 2) {
            if(curFrame <= [effect.keyframes[0].keyframeTime floatValue])
                cur = effect.keyframes[0];
            else
                cur = effect.keyframes[effect.keyframes.count-1];
            radius = cur.floatValue;
        }
    }

    radius = radius/100.0*20.0;
    [filter setValue:[[NSNumber alloc] initWithFloat:radius] forKey:@"inputAmount"];
    
    // 中心
    updatePositionSuccess = false;
    effect = [self.effectArray objectAtIndex:1];
    if (effect.keyframes.count >= 2) {
        for (int i = 0 ; i< effect.keyframes.count - 1; i++) {
            RDLOTKeyframe* cur = effect.keyframes[i];
            RDLOTKeyframe* next = effect.keyframes[i+1];
            
            //获取对应的时间片
            float startFrame = [cur.keyframeTime floatValue];
            float endFrame = [next.keyframeTime floatValue];
            
            if (curFrame >= startFrame && curFrame < endFrame)
            {
                float progress = (curFrame - startFrame)/(endFrame - startFrame);
                CGPoint cur_center = [self getCenterPointFromKeyframe:cur LayerWidth:w LayerHeight:h];
                CGPoint next_center = [self getCenterPointFromKeyframe:next LayerWidth:w LayerHeight:h];
                if (cur_center.x > next_center.x)
                    center.x = cur_center.x - fabs(cur_center.x - next_center.x)*progress;
                else
                    center.x = cur_center.x + fabs(cur_center.x - next_center.x)*progress;
                
                if (cur_center.y > next_center.y)
                    center.y = cur_center.y - fabs(cur_center.y - next_center.y)*progress;
                else
                    center.y = cur_center.y + fabs(cur_center.y - next_center.y)*progress;
                
                updatePositionSuccess = true;
                break;
            }
        }
    }
    else
        center = [self getCenterPointFromKeyframe:effect.keyframes[0] LayerWidth:w LayerHeight:h];
    
    if (!updatePositionSuccess) {
        if (effect.keyframes.count >= 2) {
            RDLOTKeyframe* cur = nil;
            if(curFrame <= [effect.keyframes[0].keyframeTime floatValue])
                cur = effect.keyframes[0];
            else
                cur = effect.keyframes[effect.keyframes.count-1];
            center = [self getCenterPointFromKeyframe:cur LayerWidth:w LayerHeight:h];
        }
        else
            center = [self getCenterPointFromKeyframe:effect.keyframes[0] LayerWidth:w LayerHeight:h];
    }

    
    [filter setValue:[[CIVector alloc] initWithX:center.x Y:center.y] forKey:@"inputCenter"];
    
    // 设置输入图像
    [filter setValue:inputImg forKey:@"inputImage"];
    outputImg = [filter valueForKey:@"outputImage"];
    //        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    
    cgImg = [context createCGImage:outputImg fromRect:[outputImg extent]];
    resultImg = [self getOutPutImageFromCGImageRef:cgImg];
    
    if(cgImg)
        CGImageRelease(cgImg);
    cgImg = nil;
    
    self.outputLayer.masksToBounds = YES;
    self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
    processBlur = true;
    if (radius == 0)
        layerSrc.contents = (__bridge id _Nullable)(imageCopy);
    else
        layerSrc.contents = nil;

    
    float value = [valueInterpolator floatValueForFrame:self.currentFrame];
    NSLog(@"name:%@ self :%p opacity:%g currentFrame:%d value = %g radius:%g x:%g y:%g",keyMatchName,self,self.outputLayer.opacity,[self.currentFrame intValue],value,radius,center.x,center.y);
//    self.outputLayer.opacity = value;
}
- (void )renderMotionBlur
{
    
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    UIImage *resultImg = nil;
    CIImage *outputImg = nil;
    CGImageRef cgImg = nil;
    CIFilter *filter = nil;
    UIImage *uiImage = [UIImage imageWithCGImage: imageCopy];
    CIImage *inputImg = [[CIImage alloc] initWithImage:uiImage];
    
    filter = [CIFilter filterWithName:@"CIMotionBlur"];
    // 设置滤镜属性值为默认值
    [filter setDefaults];
    
    RDLOTKeyframe* effectKeyFrame = [self.effectArray objectAtIndex:0].keyframes[0];
    // 方向
    if(effectKeyFrame.floatValue == 270 || effectKeyFrame.floatValue == 90||
       effectKeyFrame.floatValue == -270 || effectKeyFrame.floatValue == -90)
        [filter setValue:[[NSNumber alloc] initWithFloat:0.0] forKey:@"inputAngle"];
    else
        [filter setValue:[[NSNumber alloc] initWithFloat:M_PI/2.0] forKey:@"inputAngle"];
    
    // 模糊长度
    float radius = 0.0;
    float curFrame = [self.currentFrame floatValue];
    bool updatePositionSuccess = false;
    AdbeEffect* effect = [self.effectArray objectAtIndex:1];
    if (effect.keyframes.count >= 2) {
        for (int i = 0 ; i< effect.keyframes.count - 1; i++) {
            RDLOTKeyframe* cur = effect.keyframes[i];
            RDLOTKeyframe* next = effect.keyframes[i+1];
            
            //获取对应的时间片
            float startFrame = [cur.keyframeTime floatValue];
            float endFrame = [next.keyframeTime floatValue];
            
            if (curFrame >= startFrame && curFrame < endFrame)
            {
                float progress = (curFrame - startFrame)/(endFrame - startFrame);
                if (cur.floatValue > next.floatValue)
                    radius = cur.floatValue - fabs(cur.floatValue - next.floatValue)*progress;
                else
                    radius = cur.floatValue + fabs(cur.floatValue - next.floatValue)*progress;
                
                updatePositionSuccess = true;
                break;
            }
        }
    }
    else
        radius = effect.keyframes[0].floatValue;
    
    if (!updatePositionSuccess) {
        RDLOTKeyframe* cur = nil;
        if (effect.keyframes.count >= 2) {
            if(curFrame <= [effect.keyframes[0].keyframeTime floatValue])
                cur = effect.keyframes[0];
            else
                cur = effect.keyframes[effect.keyframes.count-1];
            radius = cur.floatValue;
        }
    }
    
    [filter setValue:[[NSNumber alloc] initWithFloat:radius] forKey:@"inputRadius"];
    
    // 设置输入图像
    [filter setValue:inputImg forKey:@"inputImage"];
    outputImg = [filter valueForKey:@"outputImage"];
    //        context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    
    cgImg = [context createCGImage:outputImg fromRect:[outputImg extent]];
    resultImg = [self getOutPutImageFromCGImageRef:cgImg];
    
    if(cgImg)
        CGImageRelease(cgImg);
    cgImg = nil;
    
    self.outputLayer.masksToBounds = YES;
    self.outputLayer.contents = (__bridge id _Nullable)(resultImg.CGImage);
    processBlur = true;
    if (radius == 0)
        layerSrc.contents = (__bridge id _Nullable)(imageCopy);
    else
        layerSrc.contents = nil;
    
    float value = [valueInterpolator floatValueForFrame:self.currentFrame];
    NSLog(@"name:%@ self :%p opacity:%g currentFrame:%d value = %g radius:%g",keyMatchName,self,self.outputLayer.opacity,[self.currentFrame intValue],value,radius);
//    self.outputLayer.opacity = value;
}

- (void)performLocalUpdate {

    if(!self.outputLayer.contents)
       return;
#if 1
    if([keyMatchName rangeOfString:MOTION_BLUR].location != NSNotFound)  //定向模糊
        [self renderMotionBlur];
    if([keyMatchName rangeOfString:RADIAL_BLUR].location != NSNotFound)  //径向模糊
    {
        [self renderRadialBlur];
//        [self renderRotateRadialBlur];
    }
    if([keyMatchName rangeOfString:GAUSS_BLUR].location != NSNotFound)   //高斯模糊
        [self renderGaussBlur];
    
    return;
#endif
                    
                    
        // 有模糊的时候需要隐藏底层的layer，没有模糊的时候显示底层layer，否则白屏
//        if(value <= 0)
//            layerSrc.contents = (__bridge id _Nullable)(imageCopy);
//        else
//            layerSrc.contents = nil;

}

- (NSDictionary *)actionsForRenderLayer {
    return @{
             @"fillColor": [NSNull null],
             @"opacity" : [NSNull null]};
}



@end
