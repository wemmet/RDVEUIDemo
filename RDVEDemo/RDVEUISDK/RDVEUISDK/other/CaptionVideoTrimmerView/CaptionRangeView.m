//
//  captionRangeView.m
//  RDVEUISDK
//
//  Created by emmet on 15/9/28.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import "CaptionRangeView.h"

@implementation RDCaptionRangeViewFile

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDCaptionRangeViewFile *copy = [[self class] allocWithZone:zone];
    copy.timeRange = _timeRange;
    copy.caption = [_caption mutableCopy];
    copy.blur = [_blur mutableCopy];
    copy.mosaic = [_mosaic mutableCopy];
    copy.dewatermark = [_dewatermark mutableCopy];
    copy.collage = [_collage mutableCopy];
    copy.doodle = [_doodle mutableCopy];
    copy.customFilter = [_customFilter mutableCopy];
    copy.fxId = _fxId;
    copy.collageFilterIndex = _collageFilterIndex;
    copy.currentFrameTexturePath = _currentFrameTexturePath;
    copy.isErase = _isErase;
    copy.music = [_music mutableCopy];
    copy.captiontypeIndex = _captiontypeIndex;
    copy.captionText = _captionText;
    copy.rotationAngle = _rotationAngle;
    copy.captionTransform = _captionTransform;
    copy.centerPoint = _centerPoint;
    copy.scale = _scale;
    copy.captionId = _captionId;
    copy.tColor = _tColor;
    copy.strokeColor = _strokeColor;
    copy.shadowColor = _shadowColor;
    copy.bgColor = _bgColor;
    copy.fontName = _fontName;
//    copy.fontCode = _fontCode;
    copy.fontPath = _fontPath;
    copy.tFontSize = _tFontSize;
    copy.title = _title;
    copy.deleted = _deleted;
    copy.frameSize = _frameSize;
    copy.home = _home;
    copy.thumbnailImage = _thumbnailImage;
    copy.selectTypeId = _selectTypeId;
    copy.selectColorItemIndex = _selectColorItemIndex;
    copy.selectBorderColorItemIndex = _selectBorderColorItemIndex;
    copy.selectShadowColorIndex = _selectShadowColorIndex;
    copy.selectBgColorIndex = _selectBgColorIndex;
    copy.inAnimationIndex = _inAnimationIndex;
    copy.outAnimationIndex = _outAnimationIndex;
    copy.selectFontItemIndex = _selectFontItemIndex;
    copy.alignment  = _alignment;
    copy.pSize = _pSize;
    copy.cSize = _cSize;
    copy.netCover = _netCover;
    copy.rectW = _rectW;
    
    return copy;
}

- (id)copyWithZone:(NSZone *)zone{
    RDCaptionRangeViewFile *copy = [[self class] allocWithZone:zone];

    copy.timeRange = _timeRange;
    copy.caption = [_caption mutableCopy];
    copy.blur = [_blur mutableCopy];
    copy.mosaic = [_mosaic mutableCopy];
    copy.dewatermark = [_dewatermark mutableCopy];
    copy.collage = [_collage mutableCopy];
    copy.doodle = [_doodle mutableCopy];
    copy.customFilter = [_customFilter mutableCopy];
    copy.fxId = _fxId;
    copy.collageFilterIndex = _collageFilterIndex;
    copy.currentFrameTexturePath = _currentFrameTexturePath;
    copy.isErase = _isErase;
    copy.music = [_music mutableCopy];
    copy.captiontypeIndex = _captiontypeIndex;
    copy.captionText = _captionText;
    copy.rotationAngle = _rotationAngle;
    copy.captionTransform = _captionTransform;
    copy.centerPoint = _centerPoint;
    copy.scale = _scale;
    copy.captionId = _captionId;
    copy.tColor = _tColor;
    copy.strokeColor = _strokeColor;
    copy.shadowColor = _shadowColor;
    copy.bgColor = _bgColor;
    copy.fontName = _fontName;
//    copy.fontCode = _fontCode;
    copy.fontPath = _fontPath;
    copy.tFontSize = _tFontSize;
    copy.title = _title;
    copy.deleted = _deleted;
    copy.frameSize = _frameSize;
    copy.home = _home;
    copy.thumbnailImage = _thumbnailImage;
    copy.selectTypeId = _selectTypeId;
    copy.selectColorItemIndex = _selectColorItemIndex;
    copy.selectBorderColorItemIndex = _selectBorderColorItemIndex;
    copy.selectShadowColorIndex = _selectShadowColorIndex;
    copy.selectBgColorIndex = _selectBgColorIndex;
    copy.inAnimationIndex = _inAnimationIndex;
    copy.outAnimationIndex = _outAnimationIndex;
    copy.selectFontItemIndex = _selectFontItemIndex;
    copy.alignment  = _alignment;
    copy.pSize = _pSize;
    copy.cSize = _cSize;
    copy.netCover = _netCover;
    copy.rectW = _rectW;
    
    return copy;
}

- (NSDictionary *)JSONObjectForTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_timeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _timeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForCaption {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[RDHelpClass dicFromUIColor:_caption.backgroundColor] forKey:@"backgroundColor"];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_caption.timeRange] forKey:@"timeRange"];
    [dic setObject:[NSNumber numberWithFloat:_caption.angle] forKey:@"angle"];
    [dic setObject:[NSNumber numberWithFloat:_caption.scale] forKey:@"scale"];
    [dic setObject:[NSNumber numberWithInteger:_caption.type] forKey:@"type"];
    [dic setObject:[NSNumber numberWithInteger:_caption.stickerType] forKey:@"stickerType"];
    if (_caption.captionImagePath) {
        [dic setObject:_caption.captionImagePath forKey:@"captionImagePath"];
    }
    if (_caption.imageFolderPath) {
        [dic setObject:_caption.imageFolderPath forKey:@"imageFolderPath"];
    }
    if (_caption.imageName) {
        [dic setObject:_caption.imageName forKey:@"imageName"];
    }
    [dic setObject:[NSNumber numberWithFloat:_caption.duration] forKey:@"duration"];
    [dic setObject:[RDHelpClass dicFromCGPoint:_caption.position] forKey:@"position"];
    [dic setObject:[RDHelpClass dicFromCGSize:_caption.size] forKey:@"size"];
    if (_caption.pText) {
        [dic setObject:_caption.pText forKey:@"pText"];
    }
    if (_caption.tImage) {
        [dic setObject:UIImageJPEGRepresentation(_caption.tImage, 1.0) forKey:@"tImage"];
    }
    if (_caption.tFontName) {
        [dic setObject:_caption.tFontName forKey:@"tFontName"];
    }
    [dic setObject:[NSNumber numberWithFloat:_caption.tFontSize] forKey:@"tFontSize"];
    [dic setObject:[NSNumber numberWithBool:_caption.isBold] forKey:@"isBold"];
    [dic setObject:[NSNumber numberWithBool:_caption.isItalic] forKey:@"isItalic"];
    [dic setObject:[NSNumber numberWithBool:_caption.isVerticalText] forKey:@"isVerticalText"];
    [dic setObject:[NSNumber numberWithInteger:_caption.tAlignment] forKey:@"tAlignment"];
    [dic setObject:[NSNumber numberWithFloat:_caption.tAngle] forKey:@"tAngle"];
    [dic setObject:[RDHelpClass dicFromUIColor:_caption.tColor] forKey:@"tColor"];
    [dic setObject:[NSNumber numberWithBool:_caption.isStroke] forKey:@"isStroke"];
    [dic setObject:[RDHelpClass dicFromUIColor:_caption.strokeColor] forKey:@"strokeColor"];
    [dic setObject:[NSNumber numberWithFloat:_caption.strokeWidth] forKey:@"strokeWidth"];
    [dic setObject:[NSNumber numberWithFloat:_caption.strokeAlpha] forKey:@"strokeAlpha"];
    [dic setObject:[NSNumber numberWithBool:_caption.isShadow] forKey:@"isShadow"];
    [dic setObject:[RDHelpClass dicFromUIColor:_caption.tShadowColor] forKey:@"tShadowColor"];
    [dic setObject:[RDHelpClass dicFromCGRect:_caption.tFrame] forKey:@"tFrame"];
    [dic setObject:[NSNumber numberWithFloat:_caption.textAlpha] forKey:@"textAlpha"];
    if (_caption.frameArray.count > 0) {
        [dic setObject:_caption.frameArray forKey:@"frameArray"];
    }
    if (_caption.timeArray.count > 0) {
        [dic setObject:_caption.timeArray forKey:@"timeArray"];
    }
    [dic setObject:[NSNumber numberWithBool:_caption.isStretch] forKey:@"isStretch"];
    [dic setObject:[RDHelpClass dicFromCGRect:_caption.stretchRect] forKey:@"stretchRect"];
    [dic setObject:[self dicFromRDCaptionAnimate:_caption.textAnimate] forKey:@"textAnimate"];
    [dic setObject:[self dicFromRDCaptionAnimate:_caption.imageAnimate] forKey:@"imageAnimate"];
    
    return dic;
}

- (void)setCaptionWithNSDictionary:(NSDictionary *)dic {
    _caption = [RDCaption new];
    _caption.backgroundColor = [RDHelpClass UIColorFromNSDictionary:dic[@"backgroundColor"]];
    _caption.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
    _caption.angle = [dic[@"angle"] floatValue];
    _caption.scale = [dic[@"scale"] floatValue];
    _caption.type = [dic[@"type"] integerValue];
    _caption.stickerType = [dic[@"stickerType"] integerValue];
    _caption.captionImagePath = [RDHelpClass getFileURLFromAbsolutePath:dic[@"captionImagePath"]].path;
    _caption.imageFolderPath = [RDHelpClass getFileURLFromAbsolutePath:dic[@"imageFolderPath"]].path;
    _caption.imageName = dic[@"imageName"];
    _caption.duration = [dic[@"duration"] floatValue];
    _caption.position = [RDHelpClass CGPointFromNSDictionary:dic[@"position"]];
    _caption.size = [RDHelpClass CGSizeFromNSDictionary:dic[@"size"]];
    _caption.pText = dic[@"pText"];
    _caption.tImage = [UIImage imageWithData:dic[@"tImage"]];
    _caption.tFontName = dic[@"tFontName"];
    _caption.tFontSize = [dic[@"tFontSize"] floatValue];
    _caption.isBold = [dic[@"isBold"] boolValue];
    _caption.isItalic = [dic[@"isItalic"] boolValue];
    _caption.isVerticalText = [dic[@"isVerticalText"] boolValue];
    _caption.tAlignment = [dic[@"tAlignment"] integerValue];
    _caption.tAngle = [dic[@"tAngle"] floatValue];
    _caption.tColor = [RDHelpClass UIColorFromNSDictionary:dic[@"tColor"]];
    _caption.isStroke = [dic[@"isStroke"] boolValue];
    _caption.strokeColor = [RDHelpClass UIColorFromNSDictionary:dic[@"strokeColor"]];
    _caption.strokeWidth = [dic[@"strokeWidth"] floatValue];
    _caption.strokeAlpha = [dic[@"strokeAlpha"] floatValue];
    _caption.isShadow = [dic[@"isShadow"] boolValue];
    _caption.tShadowColor = [RDHelpClass UIColorFromNSDictionary:dic[@"tShadowColor"]];
    _caption.tFrame = [RDHelpClass CGRectFromNSDictionary:dic[@"tFrame"]];
    _caption.textAlpha = [dic[@"textAlpha"] floatValue];
    _caption.frameArray = dic[@"frameArray"];
    _caption.timeArray = dic[@"timeArray"];
    _caption.isStretch = [dic[@"isStretch"] boolValue];
    _caption.stretchRect = [RDHelpClass CGRectFromNSDictionary:dic[@"stretchRect"]];
    _caption.textAnimate = [self getCaptionAnimateFromDic:dic[@"textAnimate"]];
    _caption.imageAnimate = [self getCaptionAnimateFromDic:dic[@"imageAnimate"]];
}

- (NSDictionary *)JSONObjectForBlur {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[NSNumber numberWithInteger:_blur.type] forKey:@"type"];
    [dic setObject:[NSNumber numberWithFloat:_blur.intensity] forKey:@"intensity"];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_blur.timeRange] forKey:@"timeRange"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_blur.pointsArray[0])] forKey:@"leftTop"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_blur.pointsArray[1])] forKey:@"rightTop"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_blur.pointsArray[2])] forKey:@"rightBottom"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_blur.pointsArray[3])] forKey:@"leftBottom"];
    return dic;
}

- (void)setBlurWithNSDictionary:(NSDictionary *)dic {
    _blur = [RDAssetBlur new];
    _blur.type = [dic[@"type"] integerValue];
    _blur.intensity = [dic[@"intensity"] floatValue];
    _blur.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
    [_blur setPointsLeftTop:[RDHelpClass CGPointFromNSDictionary:dic[@"leftTop"]] rightTop:[RDHelpClass CGPointFromNSDictionary:dic[@"rightTop"]] rightBottom:[RDHelpClass CGPointFromNSDictionary:dic[@"rightBottom"]] leftBottom:[RDHelpClass CGPointFromNSDictionary:dic[@"leftBottom"]]];
}

- (NSDictionary *)JSONObjectForMosaic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_mosaic.timeRange] forKey:@"timeRange"];
    [dic setObject:[NSNumber numberWithFloat:_mosaic.mosaicSize] forKey:@"mosaicSize"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_mosaic.pointsArray[0])] forKey:@"leftTop"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_mosaic.pointsArray[1])] forKey:@"rightTop"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_mosaic.pointsArray[2])] forKey:@"rightBottom"];
    [dic setObject:[RDHelpClass dicFromCGPoint:CGPointFromString(_mosaic.pointsArray[3])] forKey:@"leftBottom"];
    return dic;
}

- (void)setMosaicWithNSDictionary:(NSDictionary *)dic {
    _mosaic = [RDMosaic new];
    _mosaic.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
    _mosaic.mosaicSize = [dic[@"mosaicSize"] floatValue];
    [_mosaic setPointsLeftTop:[RDHelpClass CGPointFromNSDictionary:dic[@"leftTop"]] rightTop:[RDHelpClass CGPointFromNSDictionary:dic[@"rightTop"]] rightBottom:[RDHelpClass CGPointFromNSDictionary:dic[@"rightBottom"]] leftBottom:[RDHelpClass CGPointFromNSDictionary:dic[@"leftBottom"]]];
}

- (NSDictionary *)JSONObjectForDewatermark {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_dewatermark.timeRange] forKey:@"timeRange"];
    [dic setObject:[RDHelpClass dicFromCGRect:_dewatermark.rect] forKey:@"rect"];
    return dic;
}

- (void)setDewatermarkWithNSDictionary:(NSDictionary *)dic {
    _dewatermark = [RDDewatermark new];
    _dewatermark.rect = [RDHelpClass CGRectFromNSDictionary:dic[@"rect"]];
    _dewatermark.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
}

- (NSDictionary *)dicFromRDCaptionAnimate:(RDCaptionAnimate*)animate {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[NSNumber numberWithBool:animate.isFade] forKey:@"isFade"];
    [dic setObject:[NSNumber numberWithFloat:animate.fadeInDuration] forKey:@"fadeInDuration"];
    [dic setObject:[NSNumber numberWithFloat:animate.fadeOutDuration] forKey:@"fadeOutDuration"];
    [dic setObject:[NSNumber numberWithInteger:animate.type] forKey:@"type"];
    [dic setObject:[NSNumber numberWithFloat:animate.inDuration] forKey:@"inDuration"];
    [dic setObject:[NSNumber numberWithFloat:animate.outDuration] forKey:@"outDuration"];
    [dic setObject:[RDHelpClass dicFromCGPoint:animate.pushInPoint] forKey:@"pushInPoint"];
    [dic setObject:[RDHelpClass dicFromCGPoint:animate.pushOutPoint] forKey:@"pushOutPoint"];
    [dic setObject:[NSNumber numberWithFloat:animate.scaleIn] forKey:@"scaleIn"];
    [dic setObject:[NSNumber numberWithFloat:animate.scaleOut] forKey:@"scaleOut"];
    
    return dic;
}

- (RDCaptionAnimate *)getCaptionAnimateFromDic:(NSDictionary *)dic {
    RDCaptionAnimate *animate = [RDCaptionAnimate new];
    animate.isFade = [dic[@""] boolValue];
    animate.fadeInDuration = [dic[@"fadeInDuration"] floatValue];
    animate.fadeOutDuration = [dic[@"fadeOutDuration"] floatValue];
    animate.type = [dic[@"type"] integerValue];
    animate.inDuration = [dic[@"inDuration"] floatValue];
    animate.outDuration = [dic[@"outDuration"] floatValue];
    animate.pushInPoint = [RDHelpClass CGPointFromNSDictionary:dic[@"pushInPoint"]];
    animate.pushOutPoint = [RDHelpClass CGPointFromNSDictionary:dic[@"pushOutPoint"]];
    animate.scaleIn = [dic[@"scaleIn"] floatValue];
    animate.scaleOut = [dic[@"scaleOut"] floatValue];
    
    return animate;
}

- (NSDictionary *)JSONObjectForCollage {
    if (!_collage || !_collage.vvAsset.url) {
        return nil;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_collage.timeRange] forKey:@"timeRange"];
    [dic setObject:[NSNumber numberWithBool:_collage.isRepeat] forKey:@"isRepeat"];
    if (_collage.vvAsset.identifier) {
        [dic setObject:_collage.vvAsset.identifier forKey:@"identifier"];
    }
    [dic setObject:_collage.vvAsset.url.absoluteString forKey:@"url"];
    
    [dic setObject:[NSNumber numberWithFloat:_collage.vvAsset.volume] forKey:@"volume"];
    [dic setObject:[NSNumber numberWithInteger:_collage.vvAsset.type] forKey:@"type"];
    [dic setObject:[NSNumber numberWithInteger:_collage.vvAsset.fillType] forKey:@"fillType"];
    [dic setObject:[NSNumber numberWithFloat:_collage.vvAsset.filterIntensity] forKey:@"filterIntensity"];
     [dic setObject:_collage.vvAsset.filterUrl.absoluteString forKey:@"filterUrl"];
    
    [dic setObject:[NSNumber numberWithFloat:_collage.vvAsset.beautyBlurIntensity] forKey:@"beautyBlurIntensity"];
    [dic setObject:[NSNumber numberWithFloat:_collage.vvAsset.beautyBrightIntensity] forKey:@"beautyBrightIntensity"];
    [dic setObject:[NSNumber numberWithFloat:_collage.vvAsset.beautyToneIntensity] forKey:@"beautyToneIntensity"];
    
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_collage.vvAsset.timeRange] forKey:@"vvAssetTimeRange"];
    [dic setObject:[NSNumber numberWithFloat:_collage.vvAsset.alpha] forKey:@"alpha"];
    
    [dic setObject:[RDHelpClass dicFromCMTime:_collage.vvAsset.startTimeInScene] forKey:@"startTimeInScene"];
    [dic setObject:[NSNumber numberWithDouble:_collage.vvAsset.rotate] forKey:@"rotate"];
    [dic setObject:[NSNumber numberWithBool:_collage.vvAsset.isVerticalMirror] forKey:@"isVerticalMirror"];
    [dic setObject:[NSNumber numberWithBool:_collage.vvAsset.isHorizontalMirror] forKey:@"isHorizontalMirror"];
    [dic setObject:[RDHelpClass dicFromCGRect:_collage.vvAsset.rectInVideo] forKey:@"rectInVideo"];
    
    return dic;
}

- (void)setCollageWithNSDictionary:(NSDictionary *)dic {
    _collage = [RDWatermark new];
    _collage.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
    _collage.isRepeat = [dic[@"isRepeat"] boolValue];
    _collage.vvAsset.identifier = dic[@"identifier"];
    _collage.vvAsset.url = [NSURL URLWithString:dic[@"url"]];
    _collage.vvAsset.volume = [dic[@"volume"] floatValue];
    _collage.vvAsset.type = [dic[@"type"] integerValue];
    _collage.vvAsset.fillType = [dic[@"fillType"] integerValue];
    _collage.vvAsset.filterIntensity = [dic[@"filterIntensity"] integerValue];
    _collage.vvAsset.filterUrl = [NSURL URLWithString:[RDHelpClass getFileURLFromAbsolutePath_str:dic[@"filterUrl"]]];
    
    _collage.vvAsset.beautyBlurIntensity = [dic[@"beautyBlurIntensity"] floatValue];
    _collage.vvAsset.beautyBrightIntensity = [dic[@"beautyBrightIntensity"] floatValue];
    _collage.vvAsset.beautyToneIntensity = [dic[@"beautyToneIntensity"] floatValue];
    
    
    _collage.vvAsset.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"vvAssetTimeRange"]];
    _collage.vvAsset.startTimeInScene = [RDHelpClass CMTimeFromNSDictionary:dic[@"startTimeInScene"]];
    _collage.vvAsset.rotate = [dic[@"rotate"] doubleValue];
    _collage.vvAsset.isVerticalMirror = [dic[@"isVerticalMirror"] boolValue];
    _collage.vvAsset.isHorizontalMirror = [dic[@"isHorizontalMirror"] boolValue];
    _collage.vvAsset.rectInVideo = [RDHelpClass CGRectFromNSDictionary:dic[@"rectInVideo"]];
    _collage.vvAsset.alpha = [dic[@"alpha"] floatValue];
}

- (NSDictionary *)JSONObjectForDoodle {
    if (!_doodle || !_doodle.vvAsset.url) {
        return nil;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_doodle.timeRange] forKey:@"timeRange"];
    [dic setObject:[NSNumber numberWithBool:_doodle.isRepeat] forKey:@"isRepeat"];
    if (_doodle.vvAsset.identifier) {
        [dic setObject:_doodle.vvAsset.identifier forKey:@"identifier"];
    }
    [dic setObject:_doodle.vvAsset.url.absoluteString forKey:@"url"];
    [dic setObject:[NSNumber numberWithInteger:_doodle.vvAsset.type] forKey:@"type"];
    [dic setObject:[NSNumber numberWithInteger:_doodle.vvAsset.fillType] forKey:@"fillType"];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_doodle.vvAsset.timeRange] forKey:@"vvAssetTimeRange"];
    
    return dic;
}

- (void)setDoodleWithNSDictionary:(NSDictionary *)dic {
    _doodle = [RDWatermark new];
    _doodle.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
    _doodle.isRepeat = [dic[@"isRepeat"] boolValue];
    _doodle.vvAsset.identifier = dic[@"identifier"];
    _doodle.vvAsset.url = [NSURL URLWithString:dic[@"url"]];
    _doodle.vvAsset.type = [dic[@"type"] integerValue];
    _doodle.vvAsset.fillType = [dic[@"fillType"] integerValue];
    _doodle.vvAsset.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"vvAssetTimeRange"]];
}

- (NSDictionary *)JSONObjectForCustomFilter {
    if ( !_customFilter ) {
        return nil;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if( _customFilter.ratingFrameTexturePath )
        [dic setObject:_customFilter.ratingFrameTexturePath forKey:@"ratingFrameTexturePath"];
    if( _customFilter.customFilter.name )
        [dic setObject:_customFilter.customFilter.name forKey:@"name"];
    if( _customFilter.customFilter.vert )
        [dic setObject:_customFilter.customFilter.vert forKey:@"vert"];
    if( _customFilter.customFilter.frag )
        [dic setObject:_customFilter.customFilter.frag forKey:@"frag"];
    
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_customFilter.customFilter.timeRange] forKey:@"timeRange"];
    [dic setObject:[NSNumber numberWithFloat:_customFilter.customFilter.cycleDuration] forKey:@"cycleDuration"];
    [dic setObject:[NSNumber numberWithFloat:_customFilter.customFilter.builtInType] forKey:@"builtInType"];

    [dic setObject:[NSNumber numberWithInteger:_customFilter.timeFilterType] forKey:@"timeFilterType"];
    [dic setObject:[RDHelpClass dicFromCMTimeRange:_customFilter.filterTimeRangel] forKey:@"filterTimeRangel"];
    
    [dic setObject:[NSNumber numberWithInteger:_customFilter.FXTypeIndex] forKey:@"FXTypeIndex"];
    if( _customFilter.nameStr )
        [dic setObject:_customFilter.nameStr forKey:@"nameStr"];
    
    return dic;
}

- (void)setCustomFilterWithNSDictionary:(NSDictionary *)dic {
    _customFilter = [RDFXFilter new];
    _customFilter.ratingFrameTexturePath =[RDHelpClass getFileURLFromAbsolutePath_str:dic[@"ratingFrameTexturePath"]];
    
    _customFilter.customFilter = [RDCustomFilter new];
    _customFilter.customFilter.name = dic[@"name"];
    _customFilter.customFilter.vert = dic[@"vert"];
    _customFilter.customFilter.frag = dic[@"frag"];
    _customFilter.customFilter.timeRange = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"timeRange"]];
    _customFilter.customFilter.cycleDuration = [dic[@"cycleDuration"] floatValue];
    _customFilter.customFilter.builtInType = [dic[@"builtInType"] floatValue];
    
    _customFilter.timeFilterType = [dic[@"timeFilterType"] integerValue];
    _customFilter.filterTimeRangel = [RDHelpClass CMTimeRangeFromNSDictionary:dic[@"filterTimeRangel"]];
    _customFilter.FXTypeIndex = [dic[@"FXTypeIndex"] intValue];
    _customFilter.nameStr = dic[@"nameStr"];
}

@end

@interface CaptionRangeView ()

@end
@implementation CaptionRangeView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init{
    self = [super init];
    if(self){
        self.file =[[RDCaptionRangeViewFile alloc] init];
        self.file.scale = 0.8;
    }
    return self;
}

- (void)setCaptionText:(NSString *)captionText{
    self.titleLabel.text = captionText;
    
    [self setTitle:captionText forState:UIControlStateNormal];
    [self setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    self.userInteractionEnabled = YES;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.text = self.file.captionText;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    
      
      
  }
  return self;
}


- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
