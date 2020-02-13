//
//  RDLOTEffectRenderer.m
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//

#import "RDLOTEffectDistortionRender.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"
#import "BCMeshTransform+DemoTransforms.h"
#import "BCMeshTransformView.h"
//#import "RDLOTEffectLayerRender.h"

#define USE_OPENGL_TRANSFORMVIEW 1 //使用 opengl 抓图比 cifilter更加耗时，暂时使用的是cifilter处理
#define OPENGL_VIEW_POSITION_ORIGIN_X 1000
#define OPENGL_VIEW_POSITION_ORIGIN_Y 1000


#if USE_OPENGL_TRANSFORMVIEW
BCMeshTransformView *transformView = nil;
UIImageView * imageView = nil;
#endif

@implementation RDLOTEffectDistortionRender {
    RDLOTColorInterpolator *colorInterpolator_;
    RDLOTNumberInterpolator *valueInterpolator_;
    NSString* keyMatchName;
    CALayer* layerSrc;
    CGImageRef imageCopy;   //如果使用边角定位或者贝塞尔曲线，底层的layer需要置为null（深拷贝）
//    CGPoint startPoint;
//    CGPoint endPoint;
    CGSize frameSize;       //当前画布大小
    CIContext *context;     //绘制上下文
//    BCMeshTransformView *transformView ;
//    UIImageView * imageView ;
//    RDLOTEffectLayerRender* glLayer;
}

- (CGRect)getCropRect:(CGSize)dst Radius:(float)radius CenterPoint:(CGPoint)center
{
    CGRect rt = CGRectZero;
    // radius：半径
    // center：中心,左下角为（0，0）
    if (center.x > radius)
        rt.origin.x = 0;
    else
        rt.origin.x = radius - center.x;
    
    rt.size.width = dst.width;
    
    
    if ((dst.height - center.y) > radius)
        rt.origin.y = 0;
    else
        rt.origin.y = radius - (dst.height - center.y);
    
    rt.size.height = dst.height;
    
    
    return rt;
}
- (CGPoint) transformFramePointToLayerPoint:(CGPoint)framePoint withLayerSize:(CGSize)layerSize
{
    CGPoint pt;
    pt.x = framePoint.x/frameSize.width*layerSize.width;
    pt.y = framePoint.y/frameSize.height*layerSize.height;
    return pt;
}
- (UIView *)currentView{
    UIViewController *controller = [[[UIApplication sharedApplication] keyWindow] rootViewController];

    if ([controller isKindOfClass:[UITabBarController class]]) {
        controller = [(UITabBarController *)controller selectedViewController];
    }
    if([controller isKindOfClass:[UINavigationController class]]) {
        controller = [(UINavigationController *)controller visibleViewController];
    }
    if (!controller) {
        return [UIApplication sharedApplication].keyWindow;
    }
    return controller.view;
}

- (bool )initBulgeWithInputNode:(RDLOTAnimatorNode *)inputNode
                                     Effect:(RDLOTEffectDistortion *)effect
                                    calayer:(CALayer* )layer
{
    bool result = false;
#if 0
    valueInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:effect.distortion.keyframes];
    
    //画布大小 并非 layer大小
    frameSize = effect.frameSize;
    
    if(0 == effect.keyType)
    {
        // 获取凸出半径
        self.radius = effect.distortion.keyframes[0].floatValue;
        self.outputLayer.contents = nil;
        result = true;
    }
    else if(3 == effect.keyType)
    {
        CGImageRef imageRef = (__bridge CGImageRef)(layer.contents);
        //计算凸出中心开始结束位置
        if(2 == effect.distortion.keyframes.count)
        {
            startPoint = [self transformFramePointToLayerPoint:effect.distortion.keyframes[0].pointValue withLayerSize:CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))];
            endPoint = [self transformFramePointToLayerPoint:effect.distortion.keyframes[1].pointValue withLayerSize:CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))];
        }
        else if(1 == effect.distortion.keyframes.count)
        {
            startPoint = [self transformFramePointToLayerPoint:effect.distortion.keyframes[0].pointValue withLayerSize:CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))];
            endPoint = startPoint;
        }
        else
            return false;
        
        self.outputLayer.contents = layer.contents;
        self.radius = inputNode.radius;
        // 保存原始layer contents
        layerSrc = layer;
        result = true;

    }
#endif
    return result;
}
- (bool )initBezmeshWithInputNode:(RDLOTAnimatorNode *)inputNode
                                     Effect:(RDLOTEffectDistortion *)distortionEffect
                                    calayer:(CALayer* )layer
{
    CGImageRef inImageRef = nil;
    valueInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:distortionEffect.distortion.keyframes];
    
    //画布大小 并非 layer大小
    frameSize = distortionEffect.frameSize;
    if(3 == distortionEffect.keyType)
    {
        inImageRef = (__bridge CGImageRef)(layer.contents);
        AdbeEffect* effect = [[AdbeEffect alloc] init];
        effect.keyframes = distortionEffect.distortion.keyframes;
        effect.keyMatchName = keyMatchName;
        
        if(!inputNode)
        {
            self.effectArray = [[NSMutableArray alloc] init];
            [self.effectArray addObject:effect];
            
        }
        else
        {
            [inputNode.effectArray addObject:effect];
            self.effectArray = inputNode.effectArray;
            // self.preSnapshotImage = inputNode.preSnapshotImage;
        }
    }
    else
        return false;
    
    self.outputLayer.contents = layer.contents;
    // 保存原始layer contents
    layerSrc = layer;
    
    // cifilter上下文
    context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    
    // copy layer
    int width = (int)CGImageGetWidth(inImageRef);
    int height = (int)CGImageGetHeight(inImageRef);
    if (width > 0 && height > 0) {
        imageCopy = CGImageCreateCopy(inImageRef);
    }
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    if(!transformView)
    {
        UIView* superView =  nil;
        CGImageRef superViewImage = nil;
        CGImageRef inImageRef = imageCopy;
        // 如果 transformView 设置区域为（0，0，width，height），会遮挡当前view，暂停和seek按钮无法点击
        CGRect rt = CGRectMake(OPENGL_VIEW_POSITION_ORIGIN_X, OPENGL_VIEW_POSITION_ORIGIN_Y, CGImageGetWidth(inImageRef), CGImageGetHeight(inImageRef));

        superView =  [self currentView];
        superViewImage = [self getImageFromView:superView].CGImage;

        // 创建transformview
        transformView = [[BCMeshTransformView alloc] initWithFrame:rt];
        transformView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [superView addSubview:transformView];

        NSLog(@"init transformView name:%s time:%f ",[keyMatchName UTF8String],CFAbsoluteTimeGetCurrent() - start);
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage: inImageRef]];
        [transformView.contentView addSubview:imageView];
        transformView.hidden = YES;
                
        // we don't want any shading on this one
        transformView.diffuseLightFactor = 0.0;
        // transformView.meshTransform = [BCMutableMeshTransform buldgeMeshTransformAtPoint:center withRadius:radius boundsSize:transformView.bounds.size];
        self.outputLayer.contents = (__bridge id _Nullable)(imageCopy);

        NSLog(@"init transformView name:%s time:%f ",[keyMatchName UTF8String],CFAbsoluteTimeGetCurrent() - start);
    }
    return true;
}
- (bool )initCornerWithInputNode:(RDLOTAnimatorNode *)inputNode
                                     Effect:(RDLOTEffectDistortion *)distortionEffect
                                    calayer:(CALayer* )layer
{
    CGImageRef inImageRef = nil;
    valueInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:distortionEffect.distortion.keyframes];
    
    //画布大小 并非 layer大小
    frameSize = distortionEffect.frameSize;
    if(3 == distortionEffect.keyType)
    {
        inImageRef = (__bridge CGImageRef)(layer.contents);
        AdbeEffect* effect = [[AdbeEffect alloc] init];
        effect.keyframes = distortionEffect.distortion.keyframes;
        effect.keyMatchName = keyMatchName;
        
        if(distortionEffect.invalidSpatialInTangent && distortionEffect.invalidSpatialOutTangent)
        {
            //ae模版分为两种：
                //  1.普通的边角定位
                //  2.摩擦的边角定位 - demo模版名称：当年我帅不帅，这种类似的模版边角定位需要根据整个显示画布的大小来处理数据（540x960）
            layer.bounds = CGRectMake(0, 0, frameSize.width, frameSize.height);
        }
        
        if(!inputNode)
        {
            self.effectArray = [[NSMutableArray alloc] init];
            [self.effectArray addObject:effect];
            
        }
        else
        {
            [inputNode.effectArray addObject:effect];
            self.effectArray = inputNode.effectArray;
            // self.preSnapshotImage = inputNode.preSnapshotImage;
        }
    }
    else
        return false;
    
    
    
    self.outputLayer.contents = layer.contents;
    // 保存原始layer contents
    layerSrc = layer;
    // cifilter上下文
    context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    // copy layer
    int width = (int)CGImageGetWidth(inImageRef);
    int height = (int)CGImageGetHeight(inImageRef);
    if (width > 0 && height > 0) {
        imageCopy = CGImageCreateCopy(inImageRef);
    }

#if 0
    self.outputLayer.contents = (__bridge id _Nullable)(inImageRef);
    CGImageRef outImage = (__bridge CGImageRef)(self.outputLayer.contents);
    glLayer = [[RDLOTEffectLayerRender alloc] initWithFrame:layer.bounds];
    [self.outputLayer addSublayer:glLayer];
    outImage = (__bridge CGImageRef)(self.outputLayer.contents);
    outImage = (__bridge CGImageRef)(glLayer.contents);
    
#endif
    return true;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               Effect:(RDLOTEffectDistortion *_Nonnull)effect
                                   calayer:(CALayer* _Nonnull)layer
{
    self = [super initWithInputNode:inputNode keyName:effect.keyName];
    if (self) {

        bool matrixRender = true;
        
        keyMatchName = effect.keyMatchName;
        if([keyMatchName rangeOfString:@"Bulge"].location != NSNotFound)
            matrixRender = [self initBulgeWithInputNode:inputNode Effect:effect calayer:layer];
        else if([keyMatchName rangeOfString:@"Corner"].location != NSNotFound)
            matrixRender = [self initCornerWithInputNode:inputNode Effect:effect calayer:layer];
        else if([keyMatchName rangeOfString:@"BEZMESH"].location != NSNotFound)
            matrixRender = [self initBezmeshWithInputNode:inputNode Effect:effect calayer:layer];
        else
            return nil;
        
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
    if (imageCopy) {
        CGImageRelease(imageCopy);
        CGImageRef inImageRef = (__bridge CGImageRef)(layer.contents);
        int width = (int)CGImageGetWidth(inImageRef);
        int height = (int)CGImageGetHeight(inImageRef);
        if (width > 0 && height > 0) {
            imageCopy = CGImageCreateCopy(inImageRef);
        }
    }
}

- (NSDictionary *)valueInterpolators {
    return @{@"Color" : colorInterpolator_,
             @"Opacity" : valueInterpolator_};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
    return [colorInterpolator_ hasUpdateForFrame:frame]  || [valueInterpolator_ hasUpdateForFrame:frame];
}

-(UIImage *)getImageFromView:(UIView *)theView
{
    //UIGraphicsBeginImageContext(theView.bounds.size);
    UIGraphicsBeginImageContextWithOptions(theView.bounds.size, YES, theView.layer.contentsScale);
    [theView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(CGPoint)getGLpoint:(CGPoint) pt
{
    return CGPointMake(MIN(MAX(pt.x, 0.0), 1.0), MIN(MAX(pt.y, 0.0), 1.0));
}

- (void)upDateBezMeshPositionWithTopLeftPoint:(CGPoint*)topLeft
                               TopRightPoint:(CGPoint*)topRight
                             BottomLeftPoint:(CGPoint*)bottomLeft
                            BottomRightPoint:(CGPoint*)bottomRight
                              TopLeftT0Point:(CGPoint*)topLeftT0
                             TopRightT1Point:(CGPoint*)topRightT1
                              TopRightR0Point:(CGPoint*)topRightR0
                          BottomRightR1Point:(CGPoint*)bottomRightR1
                              BottomRightB1Point:(CGPoint*)bottomRightB1
                           BottomLeftB0Point:(CGPoint*)bottomLeftB0
                              BottomLeftL1Point:(CGPoint*)bottomLeftL1
                              TopLeftL0Point:(CGPoint*)topLeftL0
                                  BuoundSize:(CGSize)viewSize
{
    /**  BEZMESH 贝塞尔曲线，一共12个点，4个顶点，8个切点（每个顶点都有两个切点）
    *
    *  topLeft          上左顶点
    *  topLeftT0        上左切点 --- 上切点
    *  topRightT1       上右切点 --- 上切点
    *
    *  topRight         上右顶点
    *  topRightR0       上右切点 --- 右切点
    *  bottomRightR1    下右切点 --- 右切点
    *
    *  bottomRight      下右顶点
    *  bottomRightB1    下右切点 --- 下切点
    *  bottomLeftB0     下左切点 --- 下切点
    *
    *  bottomLeft       下左顶点
    *  bottomLeftL1     下左切点 --- 左切点
    *  topLeftL0        上左切点 --- 左切点
    */

    bool updatePositionSuccess = false;
    int curIndex = -1;
    float progress = 0;
    float curFrame = [self.currentFrame floatValue];
        
    for (int j = 0; j < self.effectArray.count; j++)
    {
        curIndex = -1;
        updatePositionSuccess = false;
        CGPoint pt = CGPointMake(0, 0);
        CGPoint curPoint = CGPointMake(0, 0);
        CGPoint nextPoint = CGPointMake(0, 0);
        AdbeEffect* bezier = [self.effectArray objectAtIndex:j];
        if(bezier.keyframes.count >= 2)
        {
            for (int i = 0; i < bezier.keyframes.count-1; i++)
            {
                        
                RDLOTKeyframe* cur = bezier.keyframes[i];
                RDLOTKeyframe* next = bezier.keyframes[i+1];
                        
                //获取对应的时间片
                float startFrame = [cur.keyframeTime intValue];
                float endFrame = [next.keyframeTime intValue];
                
                if (curFrame >= startFrame && curFrame < endFrame)
                {
                    
                    pt = CGPointMake(0, 0);
                    curPoint = CGPointMake((float)[[cur.arrayValue objectAtIndex:0] longValue], (float)[[cur.arrayValue objectAtIndex:1] longValue]);
                    nextPoint = CGPointMake((float)[[next.arrayValue objectAtIndex:0] longValue], (float)[[next.arrayValue objectAtIndex:1] longValue]);
                        
                    progress = (curFrame - startFrame) / (endFrame - startFrame);
//                    NSLog(@"startFrame:%g  ,endFrame:%g  ,currentFrame:%g   p:%g ",startFrame,endFrame,curFrame,progress);
                    //更新顶点位置
                    if(curPoint.x > nextPoint.x)
                        pt.x = (curPoint.x - fabs(curPoint.x - nextPoint.x)*progress)/viewSize.width;
                    else
                        pt.x = (curPoint.x + fabs(curPoint.x - nextPoint.x)*progress)/viewSize.width;
                            
                    if(curPoint.y > nextPoint.y)
                        pt.y = (curPoint.y - fabs(curPoint.y - nextPoint.y)*progress)/viewSize.height;
                    else
                        pt.y = (curPoint.y + fabs(curPoint.y - nextPoint.y)*progress)/viewSize.height;

                    pt = [self getGLpoint:pt];
                    curIndex = j;
                    updatePositionSuccess = true;
                    break;
                }
            }
        }
        else
        {
            curIndex = j;
            CGPoint curPoint = CGPointMake((float)[[bezier.keyframes[0].arrayValue objectAtIndex:0] longValue],
                                           (float)[[bezier.keyframes[0].arrayValue objectAtIndex:1] longValue]);
            //更新顶点位置
            pt = [self getGLpoint:CGPointMake(curPoint.x/(float)viewSize.width, curPoint.y/(float)viewSize.height)];
            updatePositionSuccess = true;
        }
        if (!updatePositionSuccess)
        {
            //容错处理，如果没有找到时间对应的position，默认取最后时间对应的zposition
            RDLOTKeyframe* lastKeyFrame = nil;
//            NSLog(@"false frame:%d  j:%d",[self.currentFrame intValue],j);
            if(bezier.keyframes.count >= 2)
            {
                if (curFrame <= [bezier.keyframes[0].keyframeTime floatValue])    // 比第一个元素小
                    lastKeyFrame = bezier.keyframes[0];
                else
                    lastKeyFrame = bezier.keyframes[bezier.keyframes.count-1];     //比最后一个元素大
            }
            else
                lastKeyFrame = bezier.keyframes[0];
            CGPoint curPoint = CGPointMake((float)[[lastKeyFrame.arrayValue objectAtIndex:0] longValue], (float)[[lastKeyFrame.arrayValue objectAtIndex:1] longValue]);
            //更新顶点位置
            pt = [self getGLpoint:CGPointMake(curPoint.x/(float)viewSize.width, curPoint.y/(float)viewSize.height)];
            curIndex = j;
        }
        switch (curIndex) {
            case 0:
                *topLeft = pt;
                break;
            case 1:
                *topLeftT0 = pt;
                break;
            case 2:
                *topRightT1 = pt;
                break;

            case 3:
                *topRight = pt;
                break;
            case 4:
                *topRightR0 = pt;
                break;
            case 5:
                *bottomRightR1 = pt;
                break;

            case 6:
                *bottomRight = pt;
                break;
                
            case 7:
                *bottomRightB1 = pt;
                break;
            case 8:
                *bottomLeftB0 = pt;
                break;
            case 9:
                *bottomLeft = pt;
                break;
            case 10:
                *bottomLeftL1 = pt;
                break;
            case 11:
                *topLeftL0 = pt;
                break;
        }
    }


}
- (void)upDateCornerPositionWithTopLeftPoint:(CGPoint*)topLeft TopRightPoint:(CGPoint*)topRight
                             BottomLeftPoint:(CGPoint*)bottomLeft BottomRightPoint:(CGPoint*)bottomRight
                                    Progress:(float)progress
                                  BuoundSize:(CGSize)viewSize
                            
{
    // Corner 边角定位
    bool updatePositionSuccess = false;
    
    for (int j = 0; j < self.effectArray.count; j++)
    {
        CGPoint pt = CGPointMake(0, 0);
        CGPoint curPoint = CGPointMake(0, 0);
        CGPoint nextPoint = CGPointMake(0, 0);
        AdbeEffect* corner = [self.effectArray objectAtIndex:j];
        for (int i = 0; i < corner.keyframes.count-1; i++)
        {
            
            RDLOTKeyframe* cur = corner.keyframes[i];
            RDLOTKeyframe* next = corner.keyframes[i+1];
            
            //获取对应的时间片
            float startFrame = 0;
            float endFrame = 0;
            if([[self currentFrame] intValue] > 0 && cur.spatialInTangent.x == 0 && cur.spatialInTangent.y == 0 &&
               cur.spatialOutTangent.x == 0 && cur.spatialOutTangent.y == 0)
            {
                //摩擦类型的边角定位模版 - demo:当年我帅不帅
                startFrame = roundf([cur.keyframeTime floatValue])+1;
                endFrame = roundf([next.keyframeTime floatValue])+1;
            }
            else
            {
                //普通类型的边角定位模版
                startFrame = roundf([cur.keyframeTime floatValue]);
                endFrame = roundf([next.keyframeTime floatValue]);
            }
            
//            NSLog(@"startFrame:%g  ,endFrame:%g  ,[self.currentFrame intValue]:%d    ",startFrame,endFrame,[self.currentFrame intValue]);
            if (([self.currentFrame intValue]) >= startFrame && ([self.currentFrame intValue]) < endFrame)
            {
                pt = CGPointMake(0, 0);
                curPoint = CGPointMake((float)[[cur.arrayValue objectAtIndex:0] doubleValue], (float)[[cur.arrayValue objectAtIndex:1] doubleValue]);
                nextPoint = CGPointMake((float)[[next.arrayValue objectAtIndex:0] doubleValue], (float)[[next.arrayValue objectAtIndex:1] doubleValue]);
                
                progress = (float)((int)(progress*100.0)/100.0);
                //更新顶点位置
                if(curPoint.x > nextPoint.x)
                    pt.x = (curPoint.x - fabs(curPoint.x - nextPoint.x)*progress)/viewSize.width;
                else
                    pt.x = (curPoint.x + fabs(curPoint.x - nextPoint.x)*progress)/viewSize.width;
                
                if(curPoint.y > nextPoint.y)
                    pt.y = (curPoint.y - fabs(curPoint.y - nextPoint.y)*progress)/viewSize.height;
                else
                    pt.y = (curPoint.y + fabs(curPoint.y - nextPoint.y)*progress)/viewSize.height;
                
                switch (j) {
                    case 0:
                        *topLeft = pt;
                        break;

                    case 1:
                        *topRight = pt;
                        break;

                    case 2:
                        *bottomLeft = pt;
                        break;
                        
                    case 3:
                        *bottomRight = pt;
                        break;
                }
                updatePositionSuccess = true;
                break;
            }
        }
    }
    if(!updatePositionSuccess)
    {
        NSLog(@"can not find position at:%d   count:%d ",[self.currentFrame intValue],self.effectArray.count);
        // 如果没有找到对应的坐标点，默认取最后一个时间点对应的坐标点
        for (int j = 0; j < self.effectArray.count; j++)
        {
    
            AdbeEffect* corner = [self.effectArray objectAtIndex:j];
            RDLOTKeyframe* lastKeyFrame = corner.keyframes[corner.keyframes.count-1];
            CGPoint curPoint = CGPointMake((float)[[lastKeyFrame.arrayValue objectAtIndex:0] doubleValue], (float)[[lastKeyFrame.arrayValue objectAtIndex:1] doubleValue]);
            CGPoint pt = CGPointMake(0, 0);
            
            //更新顶点位置
            pt.x = curPoint.x/viewSize.width;
            pt.y = curPoint.y/viewSize.height;
                
            switch (j)
            {
                case 0:
                    *topLeft = pt;//MIN(MAX(pt.x, 0.0), 1.0);
                    break;

                case 1:
                    *topRight = pt;//MIN(MAX(pt.x, 0.0), 1.0);
                    break;

                case 2:
                    *bottomLeft = pt;//MIN(MAX(pt.x, 0.0), 1.0);
                    break;
                    
                case 3:
                    *bottomRight = pt;//MIN(MAX(pt.x, 0.0), 1.0);
                    break;
            }
        }
    }

    return ;
}

-(NSString*) getNameForCurrentFrame
{
    
    
    NSString* dstString = nil;
    int maxFrame = 0;
    
    for (int j = 0; j < self.effectArray.count; j++)
    {
        AdbeEffect* effect = [self.effectArray objectAtIndex:j];
        if(dstString.length > 0)
            break;
        if(effect.keyframes.count >= 2)
        {
            for (int i = 0; i < effect.keyframes.count-1; i++)
            {
                RDLOTKeyframe* cur = effect.keyframes[i];
                RDLOTKeyframe* next = effect.keyframes[i+1];
                        
                //获取对应的时间片
                float startFrame = [cur.keyframeTime intValue];
                float endFrame = [next.keyframeTime intValue];
                
                if(endFrame > maxFrame)
                    maxFrame = endFrame;
                
                if ([self.currentFrame intValue] >= startFrame && [self.currentFrame intValue] < endFrame)
                {
                    dstString = [[NSString alloc] initWithString:effect.keyMatchName];
                    break;
                }
            }
        }
    }
    
    if(0 == dstString.length)
    {
        //超出取值范围，默认取最接近的节点
        for (int j = 0; j < self.effectArray.count; j++)
        {
            AdbeEffect* effect = [self.effectArray objectAtIndex:j];
            if(dstString.length > 0)
                break;
            if(effect.keyframes.count >= 2)
            {
                for (int i = 0; i < effect.keyframes.count-1; i++)
                {
                    RDLOTKeyframe* cur = effect.keyframes[i];
                    RDLOTKeyframe* next = effect.keyframes[i+1];
                            
                    //获取对应的时间片
                    float startFrame = [cur.keyframeTime intValue];
                    float endFrame = [next.keyframeTime intValue];
            
                    
                    if (maxFrame == startFrame || maxFrame == endFrame)
                    {
                        dstString = [[NSString alloc] initWithString:effect.keyMatchName];
                        break;
                    }
                }
            }
        }
      
    }
    
//    NSLog(@"getName :: %s   ",[dstString UTF8String]);
    if (0 == dstString.length)
        dstString = [[NSString alloc] initWithString:[self.effectArray objectAtIndex:0].keyMatchName]; // 匹配 0001
    
    return dstString;
}


- (void)performLocalUpdate {
    
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    
    CIFilter * filter = nil;
    CGImageRef currentImage = nil;
    UIImage *uiImage = nil;
    CIImage *inputImg = nil;
    CIImage *outputImg = nil;
    CGImageRef cgImg = nil;
    UIImage *resultImg = nil;
    CGImageRef dstImageRef = nil;
    CGFloat progress = [valueInterpolator_ progressForFrame:self.currentFrame];
    
    if(valueInterpolator_ && [keyMatchName rangeOfString:@"Corner"].location != NSNotFound)
    {
//        NSLog(@"name:%s curframe :%d progress:%f",[keyMatchName UTF8String],[self.currentFrame intValue],progress);
//        if([keyMatchName rangeOfString:@"0001"].location != NSNotFound )
        if([keyMatchName isEqualToString:[self getNameForCurrentFrame] ])
        {
            float w = layerSrc.bounds.size.width;
            float h = layerSrc.bounds.size.height;
            CGPoint tl = CGPointMake(0.0,0.0);
            CGPoint tr = CGPointMake(1.0,0.0);
            CGPoint bl = CGPointMake(0.0,1.0);
            CGPoint br = CGPointMake(1.0,1.0);
            CGSize size = layerSrc.bounds.size;
            
            if(layerSrc.contents)
                currentImage = (__bridge CGImageRef)(layerSrc.contents);
            else
                currentImage = imageCopy;
            uiImage = [UIImage imageWithCGImage: currentImage];
            inputImg = [[CIImage alloc] initWithImage:uiImage];
            
            // 设置cifilter
            filter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
            // 设置滤镜属性值为默认值
            [filter setDefaults];
            // 设置输入图像
            [filter setValue:inputImg forKey:@"inputImage"];
            // 更新顶点坐标
            [self upDateCornerPositionWithTopLeftPoint:&tl TopRightPoint:&tr BottomLeftPoint:&bl
                                         BottomRightPoint:&br Progress:progress BuoundSize:size];
            
//            NSLog(@"name:%s layer bound width:%f height:%f curFrame:%g tl.x:%g  ,tl.y:%g  ,tr.x:%g  ,tr.y:%g  ,bl.x:%g  ,bl.y:%g  ,br.x:%g  ,br.y:%g   ",[keyMatchName UTF8String],layerSrc.bounds.size.width,layerSrc.bounds.size.height,[[self currentFrame] floatValue],tl.x*size.width,tl.y*size.height,tr.x*size.width,
//                  tr.y*size.height,bl.x*size.width,bl.y*size.height,br.x*size.width,br.y*size.height);
            
            
            //图像y值取反
            [filter setValue:[[CIVector alloc] initWithX:tl.x*w Y:(1.0 - tl.y)*h] forKey:@"inputTopLeft"];
            [filter setValue:[[CIVector alloc] initWithX:tr.x*w Y:(1.0 - tr.y)*h] forKey:@"inputTopRight"];
            [filter setValue:[[CIVector alloc] initWithX:br.x*w Y:(1.0 - br.y)*h] forKey:@"inputBottomRight"];
            [filter setValue:[[CIVector alloc] initWithX:bl.x*w Y:(1.0 - bl.y)*h] forKey:@"inputBottomLeft"];
            
      
            // 获取输出图像
            outputImg = [filter valueForKey:@"outputImage"];
            cgImg = [context createCGImage:outputImg fromRect:CGRectMake(0, 0, size.width, size.height)];
         
            
            resultImg = [UIImage imageWithCGImage:cgImg];
            CGImageRelease(cgImg);
            dstImageRef = resultImg.CGImage;
            self.outputLayer.contents = (__bridge id _Nullable)(dstImageRef);
            
        }
        else
            self.outputLayer.contents = nil;
        //如果content不置为nil，最底层的原图会一直存在
        layerSrc.contents = nil;
    }
    else
    {
#if 0
        if(!transformView)
        {
            UIView* superView =  nil;
            CGImageRef superViewImage = nil;
            CGImageRef inImageRef = imageCopy;
            // 如果 transformView 设置区域为（0，0，width，height），会遮挡当前view，暂停和seek按钮无法点击
            CGRect rt = CGRectMake(OPENGL_VIEW_POSITION_ORIGIN_X, OPENGL_VIEW_POSITION_ORIGIN_Y, CGImageGetWidth(inImageRef), CGImageGetHeight(inImageRef));

            superView =  [self currentView];
            superViewImage = [self getImageFromView:superView].CGImage;

            // 创建transformview
            transformView = [[BCMeshTransformView alloc] initWithFrame:rt];
            transformView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            [superView addSubview:transformView];

            NSLog(@"init transformView name:%s time:%f ",[keyMatchName UTF8String],CFAbsoluteTimeGetCurrent() - start);
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage: inImageRef]];
            [transformView.contentView addSubview:imageView];
            transformView.hidden = YES;
                    
            // we don't want any shading on this one
            transformView.diffuseLightFactor = 0.0;
            // transformView.meshTransform = [BCMutableMeshTransform buldgeMeshTransformAtPoint:center withRadius:radius boundsSize:transformView.bounds.size];
            self.outputLayer.contents = (__bridge id _Nullable)(imageCopy);

            NSLog(@"init transformView name:%s time:%f ",[keyMatchName UTF8String],CFAbsoluteTimeGetCurrent() - start);
        }
        else
#endif
        {
            
//          if(imageCopy && imageView)
//              imageView.image = [UIImage imageWithCGImage: imageCopy];
            if (layerSrc.contents) {
                //20191122 导出的时候在子线程，不能更新imageView.image
                if ([NSThread isMainThread]) {
                    imageView.image = [UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(layerSrc.contents)];
                }else {
                    [imageView performSelectorOnMainThread:@selector(setImage:) withObject:[UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(layerSrc.contents)] waitUntilDone:YES];
                }                
            }
            
            if(valueInterpolator_ && [keyMatchName rangeOfString:@"BEZMESH"].location != NSNotFound)
            {
                /**  BEZMESH 贝塞尔曲线，一共12个点，4个顶点，8个切点（每个顶点都有两个切点）
                *
                *  topLeft          上左顶点
                *  topLeftT0        上左切点 --- 上切点
                *  topRightT1       上右切点 --- 上切点
                *
                *  topRight         上右顶点
                *  topRightR0       上右切点 --- 右切点
                *  bottomRightR1    下右切点 --- 右切点
                *
                *  bottomRight      下右顶点
                *  bottomRightB1    下右切点 --- 下切点
                *  bottomLeftB0     下左切点 --- 下切点
                *
                *  bottomLeft       下左顶点
                *  bottomLeftL1     下左切点 --- 左切点
                *  topLeftL0        上左切点 --- 左切点
                */
                CGImageRef resultImg = nil;
                float w = layerSrc.bounds.size.width;
                float h = layerSrc.bounds.size.height;

                CGPoint TopLeft = CGPointMake(0.0, 0.0);//0
                CGPoint TopLeftT0Point = CGPointMake(163.464/w, 152.555/h);//1
                CGPoint TopRightT1Point = CGPointMake(368.343/w, 182.087/h);//2
                CGPoint TopRight = CGPointMake(540.0/w, 0);//3
                CGPoint TopRightR0Point = CGPointMake(540.0/w, 181.315/h);//4
                CGPoint BottomRightR1Point = CGPointMake(540.0/w, 362.63/h);//5
                        
                CGPoint BottomRight = CGPointMake(540.0/w, 544.0/h);//6
                CGPoint BottomRightB1Point = CGPointMake(375.734/w, 417.066/h);//7
                CGPoint BottomLeftB0Point = CGPointMake(188.407/w, 407.952/h);//8
                CGPoint BottomLeft = CGPointMake(0, 544.0/h);//9
                CGPoint BottomLeftL1Point = CGPointMake(0.0 , 362.63/h);//10
                CGPoint TopLeftL0Point = CGPointMake(0.0,181.315/h);//11

//                NSLog(@"name:%s curframe :%d progress:%f",[keyMatchName UTF8String],[self.currentFrame intValue],progress);
//                if([keyMatchName rangeOfString:@"0002"].location != NSNotFound)
                if([keyMatchName isEqualToString:[self getNameForCurrentFrame] ])
                {
//                    NSLog(@"use name:%s curframe :%d ",[keyMatchName UTF8String],[self.currentFrame intValue]);
//                    //容错处理，如果当前帧数大于结束时的帧数，默认progress等于1
//                    if([self.currentFrame intValue] > [valueInterpolator_.trailingKeyframe.keyframeTime intValue])
//                        progress = 1.0;
                            
                    //更新顶点坐标
                    [self upDateBezMeshPositionWithTopLeftPoint:&TopLeft TopRightPoint:&TopRight BottomLeftPoint:&BottomLeft BottomRightPoint:&BottomRight TopLeftT0Point:&TopLeftT0Point TopRightT1Point:&TopRightT1Point TopRightR0Point:&TopRightR0Point BottomRightR1Point:&BottomRightR1Point BottomRightB1Point:&BottomRightB1Point BottomLeftB0Point:&BottomLeftB0Point BottomLeftL1Point:&BottomLeftL1Point TopLeftL0Point:&TopLeftL0Point BuoundSize:layerSrc.bounds.size];

                    //获取transform映射后的矩阵
                    transformView.meshTransform = [BCMutableMeshTransform bezierMeshTransformAtTopLeftPoint:TopLeft TopLeftPointT0:TopLeftT0Point TopLeftPointL0:TopLeftL0Point TopRightPoint:TopRight TopRightT1:TopRightT1Point TopRightR0:TopRightR0Point BottomLeft:BottomLeft BottomLeftB0:BottomLeftB0Point BottomLeftL1:BottomLeftL1Point BottomRight:BottomRight BottomRightB1:BottomRightB1Point BottomRightR1:BottomRightR1Point];

                    // 获取opengl画面
                    resultImg = [transformView getGLViewImage].CGImage;
                    self.outputLayer.contents = (__bridge id _Nullable)(resultImg);

                }
                else
                    self.outputLayer.contents = nil;
            }
            //如果content不置为nil，最底层的原图会一直存在
            layerSrc.contents = nil;
        }
    }
    

    self.outputLayer.bounds = CGRectMake(0, 0, layerSrc.bounds.size.width  , layerSrc.bounds.size.height);
    self.outputLayer.anchorPoint = CGPointMake(0, 0);
    self.outputLayer.masksToBounds = YES;
    
//    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
//    NSLog(@"********************************%f", end - start);
}

- (NSDictionary *)actionsForRenderLayer {
    return @{
             @"fillColor": [NSNull null],
             @"opacity" : [NSNull null]};
}


- (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer
        withWidth:(int) width
       withHeight:(int) height {


    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef iref = CGImageCreate(width,
                height,
                bitsPerComponent,
                bitsPerPixel,
                bytesPerRow,
                colorSpaceRef,
                bitmapInfo,
                provider,    // data provider
                NULL,        // decode
                YES,            // should interpolate
                renderingIntent);

    uint32_t* pixels = (uint32_t*)malloc(bufferLength);

    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }

    CGContextRef context = CGBitmapContextCreate(pixels,
                 width,
                 height,
                 bitsPerComponent,
                 bytesPerRow,
                 colorSpaceRef,
                 kCGImageAlphaPremultipliedLast);

    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }

    UIImage *image = nil;
    if(context) {

        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);

        CGImageRef imageRef = CGBitmapContextCreateImage(context);

        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }

        CGImageRelease(imageRef);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);

    if(pixels) {
        free(pixels);
    }
    return image;
}

- (void)clear {
    NSLog(@"%s", __func__);
#if USE_OPENGL_TRANSFORMVIEW
    if(transformView) {
        [transformView removeFromSuperview];
        transformView = nil;
    }
    if(imageView)
        imageView = nil;
#endif
}

@end
