//
//  UILabel+DynamicFontSize.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/16.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDPasterLabel.h"
#import "RDPasterTextView.h"
#import <CoreText/CoreText.h>
@interface RDPasterLabel(){
    float labelWidth;
    float labelHeight;
    TextLayer * textLayer;
}
@end

@implementation RDPasterLabel
#define CATEGORY_DYNAMIC_FONT_SIZE_MAXIMUM_VALUE 101
#define CATEGORY_DYNAMIC_FONT_SIZE_MINIMUM_VALUE 5

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setIsShadow:(BOOL)isShadow{
    _isShadow = isShadow;
    if(_isShadow){
        self.shadowOffset = _tShadowOffset;
    }else{
        self.shadowOffset = CGSizeMake(0, 0);
    }
}

- (void)setFontColor:(UIColor *)fontColor{
    _fontColor = fontColor;
    if(_isShadow){
        self.shadowOffset = _tShadowOffset;
    }else{
        self.shadowOffset = CGSizeMake(0, 0);
    }
}
- (void)setTShadowColor:(UIColor *)tShadowColor{
    _tShadowColor = tShadowColor;
    if(_isShadow){
        self.shadowOffset = _tShadowOffset;
    }else{
        self.shadowOffset = CGSizeMake(0, 0);
    }
}

- (void)adjustsWidthWithSuperOriginalSize:(CGSize)superOriginalSize textRect:(CGRect) textRect syncContainerRect:(CGRect)syncContainerRect; {
    NSString *text = (_pText.length == 0 ? @"" : _pText);
    UIFont *font = [UIFont fontWithName:self.font.fontName size:self.font.pointSize/_tScale];
    NSMutableString * attributedText = [NSMutableString string];
    CGSize size;
    CGRect bgViewFrame = self.superview.bounds;
    if (_isVerticalText) {
        [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
        ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if (substringRange.location + substringRange.length == text.length) {
                [attributedText insertString:substring atIndex:attributedText.length];
            }else {
                [attributedText insertString:[substring stringByAppendingString:@"\n"] atIndex:attributedText.length];
            }
        }];
        text = attributedText;
        size = [attributedText boundingRectWithSize:CGSizeMake(bgViewFrame.size.width, syncContainerRect.size.height - textRect.origin.y - (superOriginalSize.height - textRect.origin.y - textRect.size.height))
           options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
        attributes:@{ NSFontAttributeName : font }
           context:nil].size;
    }else {
        attributedText = [NSMutableString stringWithString:text];
        size = [attributedText boundingRectWithSize:CGSizeMake(syncContainerRect.size.width - textRect.origin.x - (superOriginalSize.width - textRect.origin.x - textRect.size.width), bgViewFrame.size.height)
           options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
        attributes:@{ NSFontAttributeName : font }
           context:nil].size;
    }
    CGRect frame = self.superview.superview.bounds;
    float diff;
    if (_isVerticalText) {
        if (size.height > self.frame.size.height) {
            diff = size.height - self.frame.size.height;
            frame.size.height += diff;
            self.superview.superview.bounds = frame;
            
            bgViewFrame.size.height = size.height;
            self.superview.bounds = bgViewFrame;
            self.frame = self.superview.bounds;
        }
    }else {
        if (size.width > self.frame.size.width) {
            diff = size.width - self.frame.size.width;
            frame.size.width += diff;
            self.superview.superview.bounds = frame;
            
            bgViewFrame.size.width = size.width;
            self.superview.bounds = frame;
            self.frame = self.superview.bounds;
        }
    }
    self.numberOfLines = 0;
}

#if 1
- (void)adjustsWidthToFillItsContents:(CGSize)defaultSize textRect:(CGRect) textRect syncContainerRect:(CGRect)syncContainerRect
{
    NSString *text = (_pText.length == 0 ? @"" : _pText);
    UIFont *font = [UIFont fontWithName:self.font.fontName size:self.font.pointSize/_tScale];
    NSMutableString * attributedText = [NSMutableString string];
    if (_isVerticalText) {
        [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
        ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if (substringRange.location + substringRange.length == text.length) {
                [attributedText insertString:substring atIndex:attributedText.length];
            }else {
                [attributedText insertString:[substring stringByAppendingString:@"\n"] atIndex:attributedText.length];
            }
        }];
        text = attributedText;
    }else {
        attributedText = [NSMutableString stringWithString:text];
    }
    float fHeight = defaultSize.height - textRect.origin.y - textRect.size.height - _globalInset*2.0;
    CGSize size = [attributedText boundingRectWithSize:CGSizeMake(syncContainerRect.size.width, fHeight)
                                                options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                             attributes:@{ NSFontAttributeName : font }
                                                context:nil].size;
    CGRect frame = self.superview.bounds;
    if (_isVerticalText) {
        frame.size.width = defaultSize.width + _globalInset*2;
        frame.size.height = size.height + textRect.origin.y + textRect.size.height + _globalInset*2;
        self.superview.bounds = frame;
        self.frame = CGRectMake(textRect.origin.x + _globalInset, textRect.origin.y + _globalInset, defaultSize.width - textRect.origin.x - textRect.size.width, size.height);
    }else {
        frame.size.width = size.width + textRect.origin.x + textRect.size.width + _globalInset*2;
        frame.size.height = defaultSize.height + _globalInset*2;
        self.superview.bounds = frame;
        self.frame = CGRectMake(textRect.origin.x + _globalInset, textRect.origin.y + _globalInset, size.width, defaultSize.height - textRect.origin.y - textRect.size.height);
    }
    self.numberOfLines = 0;
}
#else
- (void)adjustsWidthToFillItsContents:(CGSize)defaultSize textRect:(CGRect) textRect syncContainerRect:(CGRect)syncContainerRect
{
    float ww = (textRect.origin.x + textRect.size.width) < 44 ? (textRect.origin.x + textRect.size.width) : (textRect.origin.x + textRect.size.width)/2.0;
    float hh = (textRect.origin.y + textRect.size.height)/2.0;
//    float defaultw = defaultSize.width/2.0;
//    float defaulth = defaultSize.height/2.0;
    
    NSString *text = (_pText.length==0 ? @"" : _pText);
    float ss = self.font.pointSize/_tScale;
    CGRect sw = self.frame;
    UIFont *font = [UIFont fontWithName:self.font.fontName size:self.font.pointSize/_tScale];
    NSMutableString * attributedText = [NSMutableString stringWithString:text];
    if (_isVerticalText) {
        NSInteger lines = attributedText.length;
        for (int i = 1; i < lines; i ++) {
            [attributedText insertString:@"\n" atIndex:i*2 - 1];
        }
        text = attributedText;
    }
    CGRect rectSize = CGRectZero;
    //20170508 emmet add (- 40)
//    float width = syncContainerRect.size.width  - (textRect.size.width + textRect.origin.x)  - 16 - 20;//- - 40
    CGRect textR = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingUsesDeviceMetrics
                                             attributes:@{ NSFontAttributeName : font }
                                                context:nil];
    
    _linesNumber = (_onlyoneline ? 1 : textR.size.width/(float)sw.size.width);
    self.numberOfLines = 0;

    
//    if(self.superview.frame.size.width>=width){
//        rectSize = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
//                                                options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingUsesDeviceMetrics
//                                                context:nil];
//    }else{
//        if(textR.size.width > width){
//            rectSize = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
//                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingUsesDeviceMetrics
//                                                    context:nil];
////            float fLineHeight = self.font.lineHeight;
////            float fontSize = self.font.pointSize;
////            float lineHeight = rectSize.size.height/fLineHeight;
////
////            [UIFont fontWithName:self.font.fontName size:lineHeight];
////
//        }else{
            rectSize = textR;
//        }
//    }
    
    
//    float w = rectSize.size.width + ww;
    float w1 =
//    w > defaultw  ?
    (rectSize.size.width) + ww  + 16 + textRect.size.width + textRect.origin.x/*(defaultw//defaultw - 52/2.0)*/
//    : defaultSize.width/2.0 + 16
    ;
    
//    float h = (rectSize.size.height) + hh;
    
//    float h1 =  rectSize.size.height + hh + 16 + ss;
    
    float h1 =
//    h > defaulth && !_onlyoneline ?
    (_isVerticalText ? rectSize.size.height : _labelHeight) + hh + 16 + ss + (_onlyoneline ? 3 : 5.0) * _linesNumber
//    : defaultSize.height/2.0 + 16/* + (_onlyoneline ? 1 : 5.0) * _linesNumber*/
    ;
//    if(_needStretching){
//        h1 = !_onlyoneline ? ceilf(rectSize.size.height) + hh + 16 + ss + (_onlyoneline ? 3 : 5.0) * _linesNumber - 10  : defaultSize.height/2.0 + 16;
//    }
    //float h1 =  h > defaulth && !_onlyoneline ? ceilf(rectSize.size.height) + hh + 16 + ss + (_onlyoneline ? 3 : 5.0) * _linesNumber  : defaultSize.height/2.0 + 16/* + (_onlyoneline ? 1 : 5.0) * _linesNumber*/;
    //    CGPoint center = self.superview.center;
    CGRect viewFrame = self.superview.bounds;
    
    viewFrame.size.width = (w1
                            + ((_isEle)?((self.font.pointSize/_tScale)/2.0):0.0)
    );
    viewFrame.size.height = h1;
    
//    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
//    [RDHelpClass solveUIWidgetFuzzyRect:viewFrame];
    
//    CGPoint center = self.superview.center;
//    if( viewFrame.origin.x == 0 )
//        viewFrame.origin.x = textRect.origin.x/4.0;
//    if( viewFrame.origin.y == 0  )
//        viewFrame.origin.y = textRect.origin.y/4.0;
    
    self.superview.bounds = viewFrame;
    //    if(self.superview.frame.origin.x <= 0){
    //        center.x = self.superview.frame.size.width / 2.0 + 5;
    //        self.superview.center = center;
    //    }
    //
    //    if(self.superview.frame.origin.x + self.superview.frame.size.width > syncContainerRect.size.width){
    //        NSLog(@"%f,%f",self.superview.frame.origin.x,self.superview.frame.size.width);
    //        center.x = syncContainerRect.size.width  - self.superview.frame.size.width/2.0 - 2;
    //        self.superview.center = center;
    //    }
}
#endif
- (void)drawTextInRect:(CGRect)rect {
    
#if 0
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, 1);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = [UIColor whiteColor];
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
    
    return;
#else
    
    //self.adjustsFontSizeToFitWidth = YES;
//    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor =[[UIColor clearColor] colorWithAlphaComponent:_textAlpha];
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, _strokeWidth);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = [UIColor blackColor];
    if(![_strokeColor isEqual:[UIColor clearColor]]){
        if(_strokeColor){
            
            self.textColor = [_strokeColor colorWithAlphaComponent:_strokeAlpha];
        }
        [super drawTextInRect:rect];
        
    }
    
    if(_fontColor){
        if([_fontColor isEqual:[UIColor clearColor]]){
            textColor = [_strokeColor colorWithAlphaComponent:_textAlpha];
        }else{
            textColor = [_fontColor colorWithAlphaComponent:_textAlpha];
        }
    }
    
    if(_isBold){
        
        CGContextSetLineWidth(c, 1.0);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextSetTextDrawingMode(c, kCGTextStroke);
        self.textColor = [UIColor blackColor];
        if(textColor){
            self.textColor = textColor;
        }
        [super drawTextInRect:CGRectIntegral(rect)];
        
    }else{
        CGContextSetLineWidth(c, 0.5);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextSetTextDrawingMode(c, kCGTextStroke);
        self.textColor = [UIColor blackColor];
        if(textColor){
            self.textColor = textColor;
        }
        [super drawTextInRect:CGRectIntegral(rect)];
    }
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:CGRectIntegral(rect)];
    
//    self.shadowOffset = shadowOffset;
#endif
}

#if 0

- (void)drawTextInRect1111:(CGRect)rect {
    [self resetContent];
    self.text = nil;
    [super drawTextInRect:CGRectIntegral(rect)];
    
}

- (void)resetContent{
    //[textLayer removeFromSuperlayer];
    if(!textLayer){
        textLayer = [TextLayer layer];
    }
    
    NSString *string = _pText;
    self.backgroundColor = [UIColor clearColor];
    textLayer.backgroundColor = [UIColor clearColor].CGColor;
    textLayer.frame = CGRectIntegral(self.bounds);
    
    //textLayer.position = CGPointMake(tRect.origin.x , tRect.origin.y);
    //captionT = textLayer.transform;
    
    float fontS = self.font.pointSize;
    if (fontS == 0) {
        fontS = (self.bounds.size.height)/2;
    }
    
    NSAttributedString * attributedString;
    
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping; //换行模式
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    //行间距
    CTParagraphStyleSetting LineSpacing;
    CGFloat spacing = 1.0;  //指定间距
    LineSpacing.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
    LineSpacing.value = &spacing;
    LineSpacing.valueSize = sizeof(CGFloat);
    
    CTParagraphStyleSetting settings[] = {lineBreakMode,LineSpacing};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 2);   //第二个参数为settings的长度
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];
    
    if(self.font.fontName)
        [str addAttribute:NSFontAttributeName
                    value:[UIFont fontWithName:self.font.fontName size:fontS]
                    range:NSMakeRange(0, string.length)];
    if(self.fontColor)
        [str addAttribute:NSForegroundColorAttributeName
                    value:self.fontColor
                    range:NSMakeRange(0, string.length)];
    if(_strokeColor)
        [str addAttributes:@{NSStrokeColorAttributeName:[_strokeColor colorWithAlphaComponent:_strokeAlpha],
                             NSStrokeWidthAttributeName:@(-_strokeWidth * 3.0)}    //宽度正数为空心（前景色失效），负数描边
                     range:NSMakeRange(0, string.length)];
    if (_isBold) {
        [str addAttribute:NSStrokeWidthAttributeName
                    value:@(-4.0)
                    range:NSMakeRange(0, string.length)];
    }
    if (_isItalic) {
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
        UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:self.font.fontName matrix:matrix];
        [str addAttribute:NSFontAttributeName
                    value:[UIFont fontWithDescriptor:desc size:fontS]
                    range:NSMakeRange(0, string.length)];
    }
    
    [str addAttribute:(NSString *)kCTParagraphStyleAttributeName
                value:(id)paragraphStyle
                range:NSMakeRange(0, attributedString.length)];
    if([[[UIDevice currentDevice]systemVersion] floatValue]>=8.0){
        textLayer.string = str;//string;
    }else{
        textLayer.string = string;
    }
    NSLog(@"----------------caption str:%@",str);
    str = nil;
    
    textLayer.truncationMode = @"end";//@"start";
    textLayer.foregroundColor = _fontColor.CGColor;
    if (_isShadow) {
        textLayer.shadowColor = self.tShadowColor.CGColor;
        textLayer.shadowRadius = 2;
        textLayer.shadowOffset = self.tShadowOffset;
        textLayer.shadowOpacity = 1.0;
    }
    if (_tAlignment == UICaptionTextAlignmentLeft) {
        textLayer.alignmentMode   = @"left";
    }else if (_tAlignment == UICaptionTextAlignmentRight) {
        textLayer.alignmentMode   = @"right";
    }else {
        textLayer.alignmentMode   = @"center";
    }
    
    textLayer.wrapped = YES;
    textLayer.opacity = _textAlpha;
    textLayer.contentsGravity = kCAAlignmentCenter;
    
    string
    textLayer.contentsSize = size;
    
    [self.layer addSublayer:textLayer];
    
    [textLayer performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
    
    CFRelease(paragraphStyle);
    
}

#endif

#if 0

- (void)adjustsWidthToFillItsContents{
    NSString *text = self.pText;
    UIFont *font = [UIFont fontWithName:self.font.fontName size:self.font.pointSize];
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                         attributes:@{ NSFontAttributeName : font }];
    CGRect rectSize = CGRectZero;
    if(self.superview.frame.size.width>=300-54){
        self.numberOfLines = 0;
        rectSize = [attributedText boundingRectWithSize:CGSizeMake(300-54, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                context:nil];
    }else{
        self.numberOfLines = 1;
        rectSize = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGRectGetHeight(self.frame)-24)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                context:nil];
    }
    float w1 = (ceilf(rectSize.size.width) + 24 < 54) ? 54 : ceilf(rectSize.size.width) + 44;
    float h1 =(ceilf(rectSize.size.height) + 24 < 50) ? 55 : ceilf(rectSize.size.height) + 44;
    
    CGRect viewFrame = self.superview.bounds;
    viewFrame.size.width = w1 + 24;
    viewFrame.size.height = h1;
    self.superview.bounds = CGRectIntegral(viewFrame);
}

- (void)adjustsFontSizeToFillItsContents
{
    NSString *text = self.pText;
    
    for (int i = CATEGORY_DYNAMIC_FONT_SIZE_MAXIMUM_VALUE; i > CATEGORY_DYNAMIC_FONT_SIZE_MINIMUM_VALUE; i--) {
        UIFont *font = [UIFont fontWithName:self.font.fontName size:(CGFloat)i];
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                             attributes:@{ NSFontAttributeName : font }];
        
        CGRect rectSize = [attributedText boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil];
        
        if (CGRectGetHeight(rectSize) <= CGRectGetHeight(self.frame)) {
            //            ((RDPasterTextView *)self.superview).fontSize = (CGFloat)i-1;
            break;
        }
    }
}
- (void)adjustsFontSizeToFillRect:(CGRect)newBounds{
    NSString *text = self.pText;
    
    for (int i = 1; i > newBounds.size.height/2.0; i--) {
        UIFont *font = [UIFont fontWithName:self.font.fontName  size:(CGFloat)i];
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                             attributes:@{ NSFontAttributeName : font }];
        
        CGRect rectSize = [attributedText boundingRectWithSize:CGSizeMake(CGRectGetWidth(newBounds)-24, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil];
        
        if (CGRectGetHeight(rectSize) <= CGRectGetHeight(newBounds)) {
            //            ((RDPasterTextView *)self.superview).fontSize = (CGFloat)i-1;
            self.font = [UIFont fontWithName:self.font.fontName size:i - 1];
            break;
        }
    }
}
- (void)adjustsFontSizeToFillRect:(CGRect)newBounds defaultSize:(CGSize)defaultSize textRect:(CGRect) textRect
{
    NSString *text = self.pText;
    float ww = (textRect.origin.x + textRect.size.width) < 44 ? (textRect.origin.x + textRect.size.width) : (textRect.origin.x + textRect.size.width)/2.0;
    float hh = (textRect.origin.y + textRect.size.height)/2.0;
    
    for (int i = newBounds.size.height/2.0; i >1 ; i--) {
        UIFont *font = [UIFont fontWithName:self.font.fontName  size:(CGFloat)i];
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                             attributes:@{ NSFontAttributeName : font }];
        
        CGRect rectSize = [attributedText boundingRectWithSize:CGSizeMake(newBounds.size.width - ww - 16, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil];
        
        if (CGRectGetHeight(rectSize) <= CGRectGetHeight(newBounds) - hh - 16) {
            ((RDPasterTextView *)self.superview).fontSize = (CGFloat)i-1;
            self.font = [UIFont fontWithName:self.font.fontName size:i - 1];
            break;
        }
    }
    
    labelWidth = self.frame.size.width;
    labelHeight = self.frame.size.height;
}
#endif


- (void)dealloc{
    NSLog(@"paster-->%s",__func__);
}
@end

@implementation TextLayer

- (void)drawInContext:(CGContextRef)ctx
{
    CGFloat height;//, fontSize;
    
    height = self.bounds.size.height;
    //    fontSize = self.fontSize*2;
    
    CGContextSaveGState(ctx);
    
    //    CGContextTranslateCTM(ctx, 0.0, (height - fontSize)/2.0 - 1.0); // negative
    CGContextTranslateCTM(ctx, 0.0, (height - _contentsSize.height)/2.f - 4.0);
    
    [super drawInContext:ctx];
    CGContextRestoreGState(ctx);
}

@end

