//
//  RDCaptionLayer.m
//  RDVECore
//
//  Created by apple on 2017/11/20.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCaptionLayer.h"
#import "RDRecordHelper.h"

#define USESHADOWLBL

@interface RDCaptionLayer()
{
    RDCaption* ppCaption;
    CGSize videoSize;
    CALayer* pasterLayer;
    CALayer* currentLayer;
#ifdef USESHADOWLBL
    CALayer *labelBgLayer;
    RDCaptionLabel *shadowLbl;
#endif
    RDCaptionLabel *captionLabel;
    CATransform3D pasterT;
    CATransform3D captionT;
    CGRect pasterOriginalFrame;
    float labelWidthProportion;
    float diffX;
}

@end

@implementation RDCaptionLayer

- (CALayer *)layer{
    return currentLayer;
}

- (void)setImageRef:(CGImageRef)imageRef{
    _imageRef = imageRef;
    pasterLayer.contents = (__bridge id)_imageRef;
    //20190725 wuxiaoxia 设置contentsCenter后，contentsScale需要与图片的scale保持一致，否则图片会变形。pasterLayer大小与图片大小不一致的情况，要根据大小比例设置contentsScale
    if (ppCaption.isStretch && (ppCaption.frameArray.count > 0 || ppCaption.captionImagePath.length > 0)) {
        CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
//        if (imageSize.width >= imageSize.height) {
            if (pasterLayer.bounds.size.height != imageSize.height) {
                pasterLayer.contentsScale = imageSize.height / pasterLayer.bounds.size.height;
            }else {
                pasterLayer.contentsScale = [UIImage imageWithCGImage:imageRef].scale;
            }
//        }else {
//            if (pasterLayer.bounds.size.width != imageSize.width) {
//                pasterLayer.contentsScale = imageSize.width / pasterLayer.bounds.size.width;
//            }else {
//                pasterLayer.contentsScale = [UIImage imageWithCGImage:imageRef].scale;
//            }
//        }
    }
}

- (void)setCaptionAlphaValue:(float)captionAlphaValue{
    _captionAlphaValue = captionAlphaValue;
#ifdef USESHADOWLBL
    labelBgLayer.opacity = captionAlphaValue;
#else
    captionLabel.alpha = captionAlphaValue;
#endif
}

- (CATransform3D)captionTransform{
    return captionT;
}

- (void)setCaptionTransform:(CATransform3D)captionTransform{
#ifdef USESHADOWLBL
    labelBgLayer.transform = captionTransform;
#else
    captionLabel.layer.transform = captionTransform;
#endif
}
- (CATransform3D)pasterTransform{
    return pasterT;
}

- (void)setPasterTransform:(CATransform3D)pasterTransform
{
    pasterLayer.transform = pasterTransform;
}
- (void)setPasterAlphaValue:(float)pasterAlphaValue{
    _pasterAlphaValue = pasterAlphaValue;
    pasterLayer.opacity = pasterAlphaValue;
}

- (void)setPasterWidthProportion:(float)pasterWidthProportion {
    _pasterWidthProportion = pasterWidthProportion;
    CGRect frame = pasterOriginalFrame;
    frame.size.width *= pasterWidthProportion;
    pasterLayer.frame = frame;

    if (ppCaption.isStretch) {
        CGRect contentsCenter = ppCaption.stretchRect;
        if (pasterWidthProportion <= ppCaption.stretchRect.origin.x + ppCaption.stretchRect.size.width) {
            contentsCenter.origin.x = 1.0 - ppCaption.stretchRect.size.width;
            pasterLayer.contentsCenter = contentsCenter;
        }else {
            contentsCenter.origin.x = ppCaption.stretchRect.origin.x + (1.0 - pasterWidthProportion);
            pasterLayer.contentsCenter = contentsCenter;
        }
    }
}

- (void)setCaptionWidthProportion:(float)captionWidthProportion {
    _captionWidthProportion = captionWidthProportion;
    CGRect contentsRect;
    if (captionWidthProportion < diffX) {
        captionWidthProportion = 0.0;
        contentsRect = CGRectMake(0, 0, captionWidthProportion, 1);
    }else {
        if (captionWidthProportion >= diffX + labelWidthProportion) {
            contentsRect = CGRectMake(0, 0, captionWidthProportion, 1);
        }else {
            contentsRect = CGRectMake(0, 0, captionWidthProportion - diffX, 1);
        }
    }
#ifdef USESHADOWLBL
    labelBgLayer.contentsRect = contentsRect;
    labelBgLayer.contentsGravity = kCAAlignmentLeft;//从左至右滚动需要设置为kCAAlignmentLeft
    captionLabel.layer.contentsRect = contentsRect;
    captionLabel.layer.masksToBounds = YES;
    shadowLbl.layer.contentsRect = contentsRect;
    shadowLbl.layer.masksToBounds = YES;
#else
    captionLabel.layer.contentsRect = contentsRect;
    captionLabel.layer.masksToBounds = YES;
#endif
}

- (id)initWithCaption:(RDCaption *)caption videoSize:(CGSize)_videoSize{
    if (self = [super init]) {
        videoSize = _videoSize;
        ppCaption = caption;
        
        [self computeLayer];
    }
    return self;
}
#ifndef USESHADOWLBL
- (void) computeLayer {
    float sc = (ppCaption.size.width * videoSize.width)/ (float) ppCaption.size.width < 1 ? (ppCaption.size.width * videoSize.width)/ (float) ppCaption.size.width : 1;
    
    currentLayer = [CALayer layer];
    currentLayer.bounds   = CGRectMake(0, 0, ppCaption.size.width * videoSize.width ,ppCaption.size.height * sc*videoSize.height);
    currentLayer.position = CGPointMake(ppCaption.position.x*videoSize.width, videoSize.height - ppCaption.position.y*videoSize.height);
    currentLayer.backgroundColor = [UIColor clearColor].CGColor;
    currentLayer.opacity = ppCaption.opacity;
    
    pasterLayer = [CALayer layer];
    pasterLayer.bounds   = CGRectMake(0, 0, ppCaption.size.width * videoSize.width ,ppCaption.size.height * sc*videoSize.height);
    pasterLayer.position = CGPointMake(ppCaption.size.width * videoSize.width / 2.0 , ppCaption.size.height * sc / 2.0 *videoSize.height);
    pasterLayer.backgroundColor = [UIColor clearColor].CGColor;
    pasterLayer.allowsEdgeAntialiasing = YES;
    if (ppCaption.captionImagePath.length > 0) {
//        float iPhone4sScale = 0.7*( ppCaption.scale<1 ? ppCaption.scale : 1);
        UIImage *image = [UIImage imageWithContentsOfFile:ppCaption.captionImagePath];
        image = [RDRecordHelper fixOrientation:image];
//        image = [UIImage imageWithCGImage:image.CGImage scale:iPhone4sScale orientation:UIImageOrientationUp];//20190703 用此方法后会降低图片质量
        pasterLayer.contents = (__bridge id _Nullable)(image.CGImage);
    }
    pasterT = pasterLayer.transform;
    
    [currentLayer addSublayer:pasterLayer];
    
    float angle = ppCaption.angle;
    float scale = ppCaption.scale;
    
    CATransform3D t1 = CATransform3DScale(currentLayer.transform, scale, -scale, 1);
    t1 = CATransform3DRotate(t1, D2R(-angle), 0, 0, 1);
    currentLayer.transform = t1;
    
    // 加入图片
    if (ppCaption.frameArray.count > 0 || ppCaption.captionImagePath.length > 0) {
        if (ppCaption.isStretch) {
            pasterLayer.contentsScale = 1.0;
            pasterLayer.contentsCenter = ppCaption.stretchRect;
        }
    }
    if (ppCaption.tImage) {
        ppCaption.type = 2;
        CALayer *imageLayer = [CALayer layer];
        imageLayer.frame = ppCaption.tFrame;
//        imageLayer.position = CGPointMake(ppCaption.tFrame.origin.x,ppCaption.size.height - ppCaption.tFrame.origin.y);
        imageLayer.position = CGPointMake(ppCaption.tFrame.origin.x,ppCaption.tFrame.origin.y);
        imageLayer.contents = (__bridge id _Nullable)(ppCaption.tImage.CGImage);
        [currentLayer addSublayer:imageLayer];
    }
    pasterOriginalFrame = pasterLayer.frame;
    
    if (ppCaption.type == RDCaptionTypeHasText) {
        CGRect tRect = ppCaption.tFrame;
        tRect.origin.x = ppCaption.tFrame.origin.x * sc;
        tRect.origin.y = ppCaption.tFrame.origin.y * sc;
        tRect.size.width = ppCaption.tFrame.size.width * sc;
        tRect.size.height = ppCaption.tFrame.size.height * sc;
        if (CGRectEqualToRect(tRect, CGRectZero)) {
            tRect = CGRectMake(currentLayer.bounds.size.width/2.0, currentLayer.bounds.size.height/2.0, currentLayer.bounds.size.width, currentLayer.bounds.size.height);
        }
        float fontS = ppCaption.tFontSize;
        if (fontS == 0) {
            fontS = (tRect.size.height)/2;
        }
        CGSize size;
        captionLabel = [[RDCaptionLabel alloc] initWithFrame:tRect];
        captionLabel.center = CGPointMake(tRect.origin.x , tRect.origin.y);
        captionLabel.backgroundColor = ppCaption.backgroundColor;
        captionLabel.layer.allowsEdgeAntialiasing = YES;
        if (ppCaption.attriStr.length > 0) {
            captionLabel.isUseAttributedText = YES;
            captionLabel.attributedText = ppCaption.attriStr;
            size = captionLabel.bounds.size;
//            size = [captionLabel.attributedText boundingRectWithSize:CGSizeMake(captionLabel.bounds.size.width, captionLabel.bounds.size.height)
//                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                                   context:nil].size;
//            captionLabel.bounds = CGRectMake(0, 0, size.width, size.height);
        }else {
            captionLabel.isUseAttributedText = NO;
            NSString *fontName;
            if (ppCaption.isVerticalText) {
                NSMutableString * str = [NSMutableString string];
                [ppCaption.pText enumerateSubstringsInRange:NSMakeRange(0, ppCaption.pText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
                ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                    if (substringRange.location + substringRange.length == ppCaption.pText.length) {
                        [str insertString:substring atIndex:str.length];
                    }else {
                        [str insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                    }
                }];
                captionLabel.text = str;
            }else {
                captionLabel.text = ppCaption.pText;
            }
            captionLabel.textAlignment = (NSTextAlignment)ppCaption.tAlignment;
            if (ppCaption.tFontName.length > 0) {
                captionLabel.font = [UIFont fontWithName:ppCaption.tFontName size:fontS];
                fontName = ppCaption.tFontName;
            }else {
                captionLabel.font = [UIFont systemFontOfSize:fontS];
                fontName = captionLabel.font.fontName;
            }
            if (ppCaption.tColor) {
                captionLabel.textColor = [ppCaption.tColor colorWithAlphaComponent:ppCaption.textAlpha];
                captionLabel.txtColor = captionLabel.textColor;
            }
            if (ppCaption.isStroke) {
                captionLabel.strokeColor = [ppCaption.strokeColor colorWithAlphaComponent:ppCaption.strokeAlpha];
                captionLabel.strokeWidth = ppCaption.strokeWidth;
            }
            captionLabel.isBold = ppCaption.isBold;
            if (ppCaption.isItalic) {
                CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
                UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:fontName matrix:matrix];
                captionLabel.font = [UIFont fontWithDescriptor:desc size:fontS];
            }
            if (ppCaption.isShadow && ppCaption.tShadowColor) {
                captionLabel.shadowColor = [ppCaption.tShadowColor colorWithAlphaComponent:ppCaption.shadowAlpha];
                captionLabel.shadowOffset = ppCaption.tShadowOffset;
            }
            captionLabel.numberOfLines = 0;
            if (ppCaption.tFontName.length > 0) {
                size = [captionLabel.text boundingRectWithSize:CGSizeMake(captionLabel.bounds.size.width, captionLabel.bounds.size.height)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName : [UIFont fontWithName:fontName size:fontS]}
                                                       context:nil].size;
            }else {
                size = [captionLabel.text boundingRectWithSize:CGSizeMake(captionLabel.bounds.size.width, captionLabel.bounds.size.height)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontS]}
                                                       context:nil].size;
            }
            captionLabel.bounds = CGRectMake(0, 0, size.width, size.height);
        }
        
        captionT = captionLabel.layer.transform;
        [currentLayer addSublayer:captionLabel.layer];
        
        diffX = (captionLabel.frame.origin.x - (pasterLayer.bounds.size.width/2.0 - pasterLayer.position.x))/pasterLayer.bounds.size.width;
        labelWidthProportion = size.width/pasterLayer.bounds.size.width;
    }
}
#else
- (void) computeLayer {
    float sc = (ppCaption.size.width * videoSize.width)/ (float) ppCaption.size.width < 1 ? (ppCaption.size.width * videoSize.width)/ (float) ppCaption.size.width : 1;
    
    currentLayer = [CALayer layer];
    currentLayer.bounds   = CGRectMake(0, 0, ppCaption.size.width * videoSize.width ,ppCaption.size.height * sc*videoSize.height);
    currentLayer.position = CGPointMake(ppCaption.position.x*videoSize.width, videoSize.height - ppCaption.position.y*videoSize.height);
    currentLayer.backgroundColor = [UIColor clearColor].CGColor;
    currentLayer.opacity = ppCaption.opacity;
    
    pasterLayer = [CALayer layer];
    pasterLayer.bounds   = CGRectMake(0, 0, ppCaption.size.width * videoSize.width ,ppCaption.size.height * sc*videoSize.height);
    pasterLayer.position = CGPointMake(ppCaption.size.width * videoSize.width / 2.0 , ppCaption.size.height * sc / 2.0 *videoSize.height);
    pasterLayer.backgroundColor = [UIColor clearColor].CGColor;
    pasterLayer.allowsEdgeAntialiasing = YES;
    if (ppCaption.captionImagePath.length > 0) {
//        float iPhone4sScale = 0.7*( ppCaption.scale<1 ? ppCaption.scale : 1);
        UIImage *image = [UIImage imageWithContentsOfFile:ppCaption.captionImagePath];
        image = [RDRecordHelper fixOrientation:image];
//        image = [UIImage imageWithCGImage:image.CGImage scale:iPhone4sScale orientation:UIImageOrientationUp];//20190703 用此方法后会降低图片质量
        pasterLayer.contents = (__bridge id _Nullable)(image.CGImage);
    }
    pasterT = pasterLayer.transform;
    
    [currentLayer addSublayer:pasterLayer];
    
    float angle = ppCaption.angle;
    float scale = ppCaption.scale;
    
    CATransform3D t1 = CATransform3DScale(currentLayer.transform, scale, -scale, 1);
    t1 = CATransform3DRotate(t1, D2R(-angle), 0, 0, 1);
    currentLayer.transform = t1;
    
    // 加入图片
    if (ppCaption.frameArray.count > 0 || ppCaption.captionImagePath.length > 0) {
        if (ppCaption.isStretch) {
            pasterLayer.contentsScale = 1.0;
            pasterLayer.contentsCenter = ppCaption.stretchRect;
        }
    }
    if (ppCaption.tImage) {
        ppCaption.type = 2;
        CALayer *imageLayer = [CALayer layer];
        imageLayer.frame = ppCaption.tFrame;
//        imageLayer.position = CGPointMake(ppCaption.tFrame.origin.x,ppCaption.size.height - ppCaption.tFrame.origin.y);
        imageLayer.position = CGPointMake(ppCaption.tFrame.origin.x,ppCaption.tFrame.origin.y);
        imageLayer.contents = (__bridge id _Nullable)(ppCaption.tImage.CGImage);
        [currentLayer addSublayer:imageLayer];
    }
    pasterOriginalFrame = pasterLayer.frame;
    
    if (ppCaption.type == RDCaptionTypeHasText) {
        CGRect tRect = ppCaption.tFrame;
        tRect.origin.x = ppCaption.tFrame.origin.x * sc;
        tRect.origin.y = ppCaption.tFrame.origin.y * sc;
        tRect.size.width = ppCaption.tFrame.size.width * sc;
        tRect.size.height = ppCaption.tFrame.size.height * sc;
        if (CGRectEqualToRect(tRect, CGRectZero)) {
            tRect = CGRectMake(currentLayer.bounds.size.width/2.0, currentLayer.bounds.size.height/2.0, currentLayer.bounds.size.width, currentLayer.bounds.size.height);
        }else {
            if (tRect.size.width > currentLayer.bounds.size.width) {
                tRect.size.width = currentLayer.bounds.size.width;
            }
            if (tRect.size.height > currentLayer.bounds.size.height) {
                tRect.size.height = currentLayer.bounds.size.height;
            }
        }
        labelBgLayer = [CALayer layer];
        labelBgLayer.frame = tRect;
        labelBgLayer.position = CGPointMake(tRect.origin.x, tRect.origin.y);
        labelBgLayer.backgroundColor = ppCaption.backgroundColor.CGColor;
        labelBgLayer.allowsEdgeAntialiasing = YES;
        labelBgLayer.masksToBounds = YES;
        if(ppCaption.isItalic && !ppCaption.isVerticalText){
            CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(-15 * (CGFloat)M_PI / 180), 1, 0, 0);
            labelBgLayer.transform = CATransform3DMakeAffineTransform(matrix);
        }else{
            labelBgLayer.transform = CATransform3DIdentity;
        }
        
        [currentLayer addSublayer:labelBgLayer];
        if (ppCaption.isShadow) {
            shadowLbl = [[RDCaptionLabel alloc] initWithFrame:labelBgLayer.bounds];
            [self initLabel:shadowLbl];
            shadowLbl.center = CGPointMake(shadowLbl.center.x + ppCaption.tShadowOffset.width * scale, shadowLbl.center.y + ppCaption.tShadowOffset.height * scale);
            shadowLbl.textColor = ppCaption.tShadowColor;
            shadowLbl.txtColor = shadowLbl.textColor;
            if (ppCaption.isStroke) {
                shadowLbl.strokeColor = [ppCaption.tShadowColor colorWithAlphaComponent:ppCaption.strokeAlpha];
                shadowLbl.strokeWidth = ppCaption.strokeWidth;
            }
            [labelBgLayer addSublayer:shadowLbl.layer];
        }
        captionLabel = [[RDCaptionLabel alloc] initWithFrame:labelBgLayer.bounds];
        [self initLabel:captionLabel];
        [labelBgLayer addSublayer:captionLabel.layer];
        
//        labelBgLayer.bounds = captionLabel.bounds;
//        captionLabel.frame = labelBgLayer.bounds;
//        shadowLbl.frame = labelBgLayer.bounds;
//        shadowLbl.center = CGPointMake(shadowLbl.center.x + ppCaption.tShadowOffset.width * scale, shadowLbl.center.y + ppCaption.tShadowOffset.height * scale);
        captionT = labelBgLayer.transform;
        diffX = (labelBgLayer.frame.origin.x - (pasterLayer.bounds.size.width/2.0 - pasterLayer.position.x))/pasterLayer.bounds.size.width;
        labelWidthProportion = captionLabel.bounds.size.width/pasterLayer.bounds.size.width;
    }
}

- (void)initLabel:(RDCaptionLabel *)label {
    float fontS = ppCaption.tFontSize;
    if (fontS == 0) {
        fontS = (label.frame.size.height)/2;
    }
    CGSize size;
    label.backgroundColor = [UIColor clearColor];
    label.layer.allowsEdgeAntialiasing = YES;
    if (ppCaption.attriStr.length > 0) {
        label.isUseAttributedText = YES;
        label.attributedText = ppCaption.attriStr;
//            size = [label.attributedText boundingRectWithSize:CGSizeMake(label.bounds.size.width, label.bounds.size.height)
//                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                                   context:nil].size;
//            label.bounds = CGRectMake(0, 0, size.width, size.height);
    }else {
        label.isUseAttributedText = NO;
        NSString *fontName;
        if (ppCaption.isVerticalText) {
            NSMutableString * str = [NSMutableString string];
            [ppCaption.pText enumerateSubstringsInRange:NSMakeRange(0, ppCaption.pText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
            ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                if (substringRange.location + substringRange.length == ppCaption.pText.length) {
                    [str insertString:substring atIndex:str.length];
                }else {
                    [str insertString:[substring stringByAppendingString:@"\n"] atIndex:str.length];
                }
            }];
            label.text = str;
        }else {
            label.text = ppCaption.pText;
        }
        label.textAlignment = (NSTextAlignment)ppCaption.tAlignment;
        if (ppCaption.tFontName.length > 0) {
            label.font = [UIFont fontWithName:ppCaption.tFontName size:fontS];
            fontName = ppCaption.tFontName;
        }else {
            label.font = [UIFont systemFontOfSize:fontS];
            fontName = label.font.fontName;
        }
        if (ppCaption.tColor) {
            label.textColor = [ppCaption.tColor colorWithAlphaComponent:ppCaption.textAlpha];
            label.txtColor = label.textColor;
        }
        if (ppCaption.isStroke) {
            label.strokeColor = [ppCaption.strokeColor colorWithAlphaComponent:ppCaption.strokeAlpha];
            label.strokeWidth = ppCaption.strokeWidth;
        }
        label.isBold = ppCaption.isBold;
        if (ppCaption.isItalic) {
            CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
            UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:fontName matrix:matrix];
            label.font = [UIFont fontWithDescriptor:desc size:fontS];
        }
        label.numberOfLines = 0;
#if 0
        if (ppCaption.tFontName.length > 0) {
            size = [label.text boundingRectWithSize:CGSizeMake(label.bounds.size.width, label.bounds.size.height)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName : [UIFont fontWithName:fontName size:fontS]}
                                                   context:nil].size;
        }else {
            size = [label.text boundingRectWithSize:CGSizeMake(label.bounds.size.width, label.bounds.size.height)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontS]}
                                                   context:nil].size;
        }
        label.bounds = CGRectMake(0, 0, size.width, size.height);
#endif
    }
}
#endif
- (void)refreshFrame:(CGRect)frame {
    currentLayer.frame = frame;
    pasterLayer.bounds = currentLayer.bounds;
    pasterLayer.position = CGPointMake(frame.size.width/2.0, frame.size.height/2.0);
}

- (void)refresh{
    //    float sc = (ppCaption.size.width * videoSize.width)/ (float) ppCaption.size.width < 1 ? (ppCaption.size.width * videoSize.width)/ (float) ppCaption.size.width : 1;
    //    currentLayer.bounds   = CGRectMake(0, 0, ppCaption.size.width * videoSize.width ,ppCaption.size.height * sc*videoSize.height);
    //    currentLayer.position = CGPointMake(ppCaption.position.x*videoSize.width, videoSize.height - ppCaption.position.y*videoSize.height);
    //
    //    pasterLayer.bounds   = CGRectMake(0, 0, ppCaption.size.width * videoSize.width ,ppCaption.size.height * sc*videoSize.height);
    //    pasterLayer.position = CGPointMake(ppCaption.size.width * videoSize.width / 2.0 , ppCaption.size.height * sc / 2.0 *videoSize.height);
    //
}

- (void) clean
{
    [currentLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end

@implementation RDCaptionLabel

- (void)drawTextInRect:(CGRect)rect {
    if (_isUseAttributedText) {
        [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
    }else {
        if(!self.strokeColor){
            _strokeWidth = 0;
        }
        CGSize shadowOffset = CGSizeMake(self.shadowOffset.width *2.0, self.shadowOffset.height*2.0);
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        if(_strokeColor){
#ifdef USESHADOWLBL
            CGContextSetLineWidth(c, _strokeWidth);
#else
            CGContextSetLineWidth(c, _strokeWidth*2.0);
#endif
            CGContextSetLineJoin(c, kCGLineJoinRound);
            CGContextSetTextDrawingMode(c, kCGTextStroke);
            self.textColor = _strokeColor;
            [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
        }
        
        if(_isBold){
            CGContextSetLineWidth(c, 2);
            CGContextSetLineJoin(c, kCGLineJoinRound);
            CGContextSetTextDrawingMode(c, kCGTextStroke);
            self.textColor = _txtColor;
            [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
        }else{
            CGContextSetLineWidth(c, 0.5);
            CGContextSetLineJoin(c, kCGLineJoinRound);
            CGContextSetTextDrawingMode(c, kCGTextStroke);
            self.textColor = _txtColor;
            [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
        }
        
        CGContextSetTextDrawingMode(c, kCGTextFill);
        self.textColor = _txtColor;
        self.shadowOffset = CGSizeMake(0, 0);
        [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _edgeInsets)];
        
        if (self.shadowColor) {
            self.shadowOffset = shadowOffset;
        }else {
            self.shadowOffset = CGSizeMake(0, 0);
        }
    }
}

@end


@implementation RDTextLayer

- (void)drawInContext:(CGContextRef)ctx
{
    CGFloat height = self.bounds.size.height;
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0.0, (height - _contentsSize.height)/2.f - 4.0);
    [super drawInContext:ctx];
    CGContextRestoreGState(ctx);
#if 0
    CGContextSaveGState(ctx);
    
    UIColor *color = [UIColor redColor];
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
//    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 1.0, color.CGColor);
//    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 2);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetTextDrawingMode(ctx, kCGTextStroke);
    [[UIColor redColor] setStroke];
//    CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1.f, -1.f));
//    CTLineDraw([self lineOfText], ctx);
    [super drawInContext:ctx];
    CGContextRestoreGState(ctx);
#endif
}

- (CTLineRef)lineOfText
{
    CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithNameAndSize(_fontName, self.fontSize);
    if (!fontDescriptor)
    {
        return nil;
    }
    
    CTFontRef fontForDrawing = CTFontCreateWithFontDescriptor(fontDescriptor, self.fontSize, NULL);
    CFRelease(fontDescriptor);
    CFStringRef keys[] = { kCTFontAttributeName, kCTForegroundColorFromContextAttributeName };
    CFTypeRef values[] = { fontForDrawing,		 kCFBooleanTrue };
    CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault,
                                                    (const void**)&keys,
                                                    (const void**)&values,
                                                    sizeof(keys) / sizeof(keys[0]),
                                                    &kCFTypeDictionaryKeyCallBacks,
                                                    &kCFTypeDictionaryValueCallBacks);
    
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, (CFStringRef)@"就是要自拍!", attributes);
    CTLineRef _lineOfText = CTLineCreateWithAttributedString(attrString);
    CFRelease(fontForDrawing);
    CFRelease(attributes);
    CFRelease(attrString);
    
    return _lineOfText;
}

@end
