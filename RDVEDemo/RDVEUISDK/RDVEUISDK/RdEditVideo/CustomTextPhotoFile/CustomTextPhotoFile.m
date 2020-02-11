//
//  CustomTextPhotoFile.m
//  RDVEUISDK
//
//  Created by emmet on 15/11/9.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import "CustomTextPhotoFile.h"

@implementation CustomTextPhotoFile

- (id)copyWithZone:(NSZone *)zone{
    CustomTextPhotoFile *copy = [[[self class] allocWithZone:zone] init];
    
    copy.photoRectSize = _photoRectSize;
    copy.textColorIndex = _textColorIndex;
    copy.backColorIndex = _backColorIndex;
    copy.textContent = _textContent;
    copy.font_Name = _font_Name;
    copy.fontPath = _fontPath;
    copy.filePath = _filePath;
    copy.font_pointSize = _font_pointSize;
    copy.contentAlignment = _contentAlignment;
    copy.textColor = _textColor;
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    CustomTextPhotoFile *copy = [[[self class] allocWithZone:zone] init];
    
    copy.photoRectSize = _photoRectSize;
    copy.textColorIndex = _textColorIndex;
    copy.backColorIndex = _backColorIndex;
    copy.textContent = _textContent;
    copy.font_Name = _font_Name;
    copy.fontPath = _fontPath;
    copy.filePath = _filePath;
    copy.font_pointSize = _font_pointSize;
    copy.contentAlignment = _contentAlignment;
    copy.textColor = _textColor;
    
    return copy;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [@[@"textLayer"] containsObject:propertyName];
}

- (CATextLayer *)textLayer {
    if (!_textLayer) {
        if (_fontPath.length > 0) {
            [RDHelpClass customFontWithPath:_fontPath fontName:_font_Name];
        }
        CGSize constraintSize = CGSizeMake(_photoRectSize.width, _photoRectSize.height);
        UIFont *font;
        if (_font_Name.length == 0) {
            font = [UIFont systemFontOfSize:_font_pointSize];
        }else {
            font = [UIFont fontWithName:_font_Name size:_font_pointSize];
        }
        NSDictionary *attributes = @{NSFontAttributeName:font};
        CGSize size = [_textContent boundingRectWithSize:constraintSize
                                                 options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                              attributes:attributes
                                                 context:nil].size;
        NSInteger lines = (NSInteger)(size.height / font.lineHeight);
        
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.backgroundColor = [UIColor clearColor].CGColor;
        textLayer.bounds = CGRectMake(0, 0, size.width, size.height + lines * (font.lineHeight - font.pointSize));
        textLayer.foregroundColor = _textColor.CGColor;
        if (_contentAlignment == kContentAlignmentCenter) {
            textLayer.alignmentMode = kCAAlignmentCenter;
        }else if (_contentAlignment == kContentAlignmentLeft) {
            textLayer.alignmentMode = kCAAlignmentLeft;
        }else {
            textLayer.alignmentMode = kCAAlignmentRight;
        }
        textLayer.wrapped = YES;
        //以Retina方式来渲染，防止画出来的文本模糊
        textLayer.contentsScale = [UIScreen mainScreen].scale;
        textLayer.truncationMode = kCATruncationEnd;
        
        CFStringRef fontName;
        if (_font_Name.length == 0) {
            fontName = (__bridge CFStringRef)[UIFont systemFontOfSize:10].fontName;
        }else {
            fontName = (__bridge CFStringRef)_font_Name;
        }
        CGFontRef fontRef = CGFontCreateWithFontName(fontName);
        textLayer.font = fontRef;
        textLayer.fontSize = _font_pointSize;
        CGFontRelease(fontRef);
        
        textLayer.string = _textContent;
        _textLayer = textLayer;
    }
    return _textLayer;
}

- (void)refreshTextLayer {
    if (_fontPath.length > 0) {
        [RDHelpClass customFontWithPath:_fontPath fontName:_font_Name];
    }
    CGSize constraintSize = CGSizeMake(_photoRectSize.width, _photoRectSize.height);
    UIFont *font;
    if (_font_Name.length == 0) {
        font = [UIFont systemFontOfSize:_font_pointSize];
    }else {
        font = [UIFont fontWithName:_font_Name size:_font_pointSize];
    }
    NSDictionary *attributes = @{NSFontAttributeName:font};
    CGSize size = [_textContent boundingRectWithSize:constraintSize
                                             options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          attributes:attributes
                                             context:nil].size;
    NSInteger lines = (NSInteger)(size.height / font.lineHeight);
    _textLayer.bounds = CGRectMake(0, 0, size.width, size.height + lines * (font.lineHeight - font.pointSize));
    _textLayer.foregroundColor = _textColor.CGColor;
    if (_contentAlignment == kContentAlignmentCenter) {
        _textLayer.alignmentMode = kCAAlignmentCenter;
    }else if (_contentAlignment == kContentAlignmentLeft) {
        _textLayer.alignmentMode = kCAAlignmentLeft;
    }else {
        _textLayer.alignmentMode = kCAAlignmentRight;
    }
    
    CFStringRef fontName;
    if (_font_Name.length == 0) {
        fontName = (__bridge CFStringRef)[UIFont systemFontOfSize:10].fontName;
    }else {
        fontName = (__bridge CFStringRef)_font_Name;
    }
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    _textLayer.font = fontRef;
    _textLayer.fontSize = _font_pointSize;
    CGFontRelease(fontRef);
    
    _textLayer.string = _textContent;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
