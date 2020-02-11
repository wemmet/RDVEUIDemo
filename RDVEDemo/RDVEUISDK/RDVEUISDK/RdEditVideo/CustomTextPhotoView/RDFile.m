//
//  RDFile.m
//  RDVEUISDK
//
//  Created by emmet on 2017/6/27.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDFile.h"
#import "RDVECore.h"

@implementation RDFile
- (instancetype)init{
    self = [super init];
    if(self){
        self.brightness                 = 0;
        self.contrast                   = 1.0;
        self.saturation                 = 1.0;
        self.vignette                   = 0.0;
        self.sharpness                  = 0.0;
        self.whiteBalance               = 0.0;
        _fileTimeFilterType             = 0;
        _backgroundType                 = KCanvasType_None;
        _BackgroundFile                 = nil;
        _BackgroundBlurIntensity        = 0.0;
        _backgroundStyle                = 0.0;
        _backgroundColor                = UIColorFromRGB(0x000000);
        _rectInFile                     = CGRectZero;
        _rectInScale                    = 1.0;
        _BackgroundRotate               = 0.0;
        _fileScale                      = 1.0;
        
        _filterIntensity                = 1.0;
        _startTimeInScene               = kCMTimeZero;
        _rectInScene                    = CGRectMake(0, 0, 1, 1);
        _rectInScale                    = 1.0;
        _backgroundAlpha = 1.0;
        _videoVolume = 1.0;
        _speed = 1.0;
        _crop = CGRectMake(0, 0, 1, 1);
        _imageTimeRange = kCMTimeRangeZero;
        _videoActualTimeRange = kCMTimeRangeZero;
        _videoTrimTimeRange = kCMTimeRangeInvalid;
        _reverseVideoTrimTimeRange = kCMTimeRangeInvalid;
    }
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDFile *copy = [[[self class] allocWithZone:zone] init];
    
    copy.backgroundColor         = _backgroundColor;
    copy.backgroundType          = _backgroundType;
    copy.BackgroundFile = [_BackgroundFile mutableCopy];
    copy.backgroundStyle = _backgroundStyle;
    copy.BackgroundBlurIntensity = _BackgroundBlurIntensity;
    copy.rectInFile = _rectInFile;
    copy.rectInScale    = _rectInScale;
    copy.BackgroundRotate = _BackgroundRotate;
    copy.fileScale          = _fileScale;
    
    copy.backgroundAlpha        = _backgroundAlpha;
    copy.fileType                = _fileType;
    copy.filtImagePatch          = _filtImagePatch;
    copy.isGif                   = _isGif;
    copy.imageDurationTime       = _imageDurationTime;
    copy.imageTimeRange          = _imageTimeRange;
    copy.coverTime               = _coverTime;
    copy.fileTimeFilterTimeRange = _fileTimeFilterTimeRange;
    copy.contentURL              = _contentURL;
    copy.gifData                 = _gifData;
    copy.reverseVideoURL         = _reverseVideoURL;
    copy.filterIndex             = _filterIndex;
    copy.filterIntensity             = _filterIntensity;
    copy.brightness              = _brightness;
    copy.contrast                = _contrast;
    copy.saturation              = _saturation;
    copy.vignette                = _vignette;
    copy.sharpness               = _sharpness;
    copy.whiteBalance            = _whiteBalance;
    copy.speed                   = _speed;
    copy.speedIndex              = _speedIndex;
    copy.videoVolume             = _videoVolume;
    copy.audioFadeInDuration     = _audioFadeInDuration;
    copy.audioFadeOutDuration    = _audioFadeOutDuration;
    copy.videoTimeRange          = _videoTimeRange;
    copy.videoActualTimeRange    = _videoActualTimeRange;
    copy.reverseVideoTimeRange   = _reverseVideoTimeRange;
    copy.videoDurationTime       = _videoDurationTime;
    copy.reverseDurationTime     = _reverseDurationTime;
    copy.startTimeInScene        = _startTimeInScene;
    copy.crop                    = _crop;
    copy.rotate                  = _rotate;
    copy.isReverse               = _isReverse;
    copy.isVerticalMirror        = _isVerticalMirror;
    copy.isHorizontalMirror      = _isHorizontalMirror;
    copy.transitionDuration      = _transitionDuration;
    copy.transitionTypeName      = _transitionTypeName;
    copy.transitionName          = _transitionName;
    copy.transitionMask          = _transitionMask;
    copy.thumbImage              = _thumbImage;
    copy.cropRect                = _cropRect;
    copy.fileCropModeType        = _fileCropModeType;
    copy.customFilterIndex       = _customFilterIndex;
    copy.customFilterId          = _customFilterId;
    copy.fileTimeFilterType      = _fileTimeFilterType;
    copy.videoTrimTimeRange          = _videoTrimTimeRange;
    copy.reverseVideoTrimTimeRange   = _reverseVideoTrimTimeRange;
    copy.customTextPhotoFile         = [_customTextPhotoFile copy];
    copy.rectInScene                 = _rectInScene;
    copy.timeEffectSceneCount        = _timeEffectSceneCount;
    copy.animationName = _animationName;
    copy.animationDuration = _animationDuration;
    return copy;
}

- (id)copyWithZone:(NSZone *)zone{
    RDFile *copy = [[[self class] allocWithZone:zone] init];
    copy.backgroundColor         = _backgroundColor;
    copy.backgroundType          = _backgroundType;
    copy.BackgroundFile = [_BackgroundFile mutableCopy];
    copy.backgroundStyle = _backgroundStyle;
    copy.BackgroundBlurIntensity = _BackgroundBlurIntensity;
    copy.rectInScale    = _rectInScale;
    copy.BackgroundRotate = _BackgroundRotate;
    copy.fileScale          = _fileScale;
    
//    copy.rectInFile = _rectInFile;
    copy.backgroundAlpha         = _backgroundAlpha;
    copy.fileType                = _fileType;
    copy.filtImagePatch          = _filtImagePatch;
    copy.isGif                   = _isGif;
    copy.fileTimeFilterTimeRange = _fileTimeFilterTimeRange;
    copy.imageDurationTime       = _imageDurationTime;
    copy.imageTimeRange          = _imageTimeRange;
    copy.coverTime               = _coverTime;
    copy.contentURL              = _contentURL;
    copy.gifData                 = _gifData;
    copy.reverseVideoURL         = _reverseVideoURL;
    copy.filterIndex             = _filterIndex;
    copy.filterIntensity         = _filterIntensity;
    copy.brightness              = _brightness;
    copy.contrast                = _contrast;
    copy.saturation              = _saturation;
    copy.vignette                = _vignette;
    copy.sharpness               = _sharpness;
    copy.whiteBalance            = _whiteBalance;
    copy.speed                   = _speed;
    copy.speedIndex              = _speedIndex;
    copy.videoVolume             = _videoVolume;
    copy.audioFadeInDuration     = _audioFadeInDuration;
    copy.audioFadeOutDuration    = _audioFadeOutDuration;
    copy.videoTimeRange          = _videoTimeRange;
    copy.videoActualTimeRange    = _videoActualTimeRange;
    copy.reverseVideoTimeRange   = _reverseVideoTimeRange;
    copy.videoDurationTime       = _videoDurationTime;
    copy.reverseDurationTime     = _reverseDurationTime;
    copy.startTimeInScene        = _startTimeInScene;
    copy.crop                    = _crop;
    copy.fileCropModeType        = _fileCropModeType;
    copy.customFilterIndex       = _customFilterIndex;
    copy.customFilterId          = _customFilterId;
    copy.fileTimeFilterType      = _fileTimeFilterType;
    copy.rotate                  = _rotate;
    copy.isReverse               = _isReverse;
    copy.isVerticalMirror        = _isVerticalMirror;
    copy.isHorizontalMirror      = _isHorizontalMirror;
    copy.transitionDuration      = _transitionDuration;
    copy.transitionTypeName      = _transitionTypeName;
    copy.transitionName          = _transitionName;
    copy.transitionMask          = _transitionMask;
    copy.thumbImage              = _thumbImage;
    copy.cropRect                = _cropRect;
    copy.videoTrimTimeRange          = _videoTrimTimeRange;
    copy.reverseVideoTrimTimeRange   = _reverseVideoTrimTimeRange;
    copy.customTextPhotoFile         = [_customTextPhotoFile copy];
    copy.rectInScene                 = _rectInScene;
    copy.timeEffectSceneCount        = _timeEffectSceneCount;
    copy.animationName = _animationName;
    copy.animationDuration = _animationDuration;
    return copy;
}

- (void)setContentURL:(NSURL *)contentURL {
    _contentURL = contentURL;
    if (contentURL) {
        _videoActualTimeRange = [RDVECore getActualTimeRange:contentURL];
        if (CMTimeCompare(_videoActualTimeRange.duration, kCMTimeZero) == 1) {
            _videoDurationTime = _videoActualTimeRange.duration;
        }
    }
}

- (void)setVideoDurationTime:(CMTime)videoDurationTime {
    _videoDurationTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(videoDurationTime), TIMESCALE);
    if (CMTimeCompare(_videoActualTimeRange.duration, kCMTimeZero) == 1 && CMTimeCompare(_videoDurationTime, _videoActualTimeRange.duration) == 1) {
        _videoDurationTime = _videoActualTimeRange.duration;
    }
}

- (void)setVideoTimeRange:(CMTimeRange)videoTimeRange{
    if(CMTimeRangeEqual(videoTimeRange, kCMTimeRangeInvalid)){
        _videoTimeRange = CMTimeRangeMake(kCMTimeZero, _videoDurationTime);
    }else{
        _videoTimeRange = videoTimeRange;
    }
    if (CMTimeCompare(_videoActualTimeRange.duration, kCMTimeZero) == 1) {
        if (CMTimeCompare(_videoActualTimeRange.start, _videoTimeRange.start) == 1) {
            _videoTimeRange = CMTimeRangeMake(_videoActualTimeRange.start, _videoTimeRange.duration);
        }
        if (CMTimeCompare(_videoTimeRange.duration, _videoActualTimeRange.duration) == 1) {
            _videoTimeRange = _videoActualTimeRange;
        }
    }
}

- (void)setVideoTrimTimeRange:(CMTimeRange)videoTrimTimeRange{
    if(CMTimeRangeEqual(videoTrimTimeRange, kCMTimeRangeInvalid)){
        _videoTrimTimeRange = _videoTimeRange;
    }else{
        _videoTrimTimeRange = videoTrimTimeRange;
    }
    if (CMTimeCompare(_videoActualTimeRange.duration, kCMTimeZero) == 1) {
        if (CMTimeCompare(_videoActualTimeRange.start, _videoTrimTimeRange.start) == 1) {
            _videoTrimTimeRange = CMTimeRangeMake(_videoActualTimeRange.start, _videoTrimTimeRange.duration);
        }
        if (CMTimeCompare(CMTimeAdd(_videoTrimTimeRange.start, _videoTrimTimeRange.duration), _videoActualTimeRange.duration) == 1) {
            _videoTrimTimeRange = CMTimeRangeMake(_videoTrimTimeRange.start, CMTimeSubtract(_videoActualTimeRange.duration, _videoTrimTimeRange.start));
        }
    }
}

- (void)setReverseVideoTimeRange:(CMTimeRange)reverseVideoTimeRange{
    if(CMTimeRangeEqual(reverseVideoTimeRange, kCMTimeRangeInvalid)){
        _reverseVideoTimeRange = CMTimeRangeMake(kCMTimeZero, _reverseDurationTime);
    }else{
        _reverseVideoTimeRange = reverseVideoTimeRange;
    }
}

- (void)setReverseVideoTrimTimeRange:(CMTimeRange)reverseVideoTrimTimeRange{
    if(CMTimeRangeEqual(reverseVideoTrimTimeRange, kCMTimeRangeInvalid)){
        _reverseVideoTrimTimeRange = _reverseVideoTimeRange;
    }else{
        _reverseVideoTrimTimeRange = reverseVideoTrimTimeRange;
    }
}

- (NSDictionary *)JSONObjectForImageDurationTime {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_imageDurationTime, kCFAllocatorDefault));
    return dic;
}

- (void)setImageDurationTimeWithNSDictionary:(NSDictionary *)dict {
    _imageDurationTime = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForImageTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_imageTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setImageTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _imageTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForCoverTime {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_coverTime, kCFAllocatorDefault));
    return dic;
}

- (void)setCoverTimeWithNSDictionary:(NSDictionary *)dict {
    _coverTime = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForVideoTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_videoTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setVideoTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _videoTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForVideoActualTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_videoActualTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setVideoActualTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _videoActualTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForFileTimeFilterTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_fileTimeFilterTimeRange, kCFAllocatorDefault));
    return dic;
}

- (NSDictionary *)JSONObjectForReverseVideoTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_reverseVideoTimeRange, kCFAllocatorDefault));
    return dic;
}


- (void)setFileTimeFilterTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _fileTimeFilterTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (void)setReverseVideoTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _reverseVideoTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForVideoTrimTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_videoTrimTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setVideoTrimTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _videoTrimTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForReverseVideoTrimTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_reverseVideoTrimTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setReverseVideoTrimTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _reverseVideoTrimTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForVideoDurationTime {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_videoDurationTime, kCFAllocatorDefault));
    return dic;
}

- (void)setVideoDurationTimeWithNSDictionary:(NSDictionary *)dict {
    _videoDurationTime = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForReverseDurationTime {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_reverseDurationTime, kCFAllocatorDefault));
    return dic;
}

- (void)setReverseDurationTimeWithNSDictionary:(NSDictionary *)dict {
    _reverseDurationTime = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForStartTimeInScene {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_startTimeInScene, kCFAllocatorDefault));
    return dic;
}

- (void)setStartTimeInSceneWithNSDictionary:(NSDictionary *)dict {
    _startTimeInScene = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (void)remove {
    NSError *err = nil;
    NSFileManager *fman = [NSFileManager defaultManager];
    //视频
    if (_contentURL && ![RDHelpClass isSystemPhotoUrl:_contentURL] && [fman fileExistsAtPath:[[RDHelpClass getFileURLFromAbsolutePath:_contentURL.absoluteString] path]]) {
        [fman removeItemAtPath:[[RDHelpClass getFileURLFromAbsolutePath:_contentURL.absoluteString] path] error:&err];
        if (err) {
            NSLog(@"删除videoURL出错： %@", err);
        }
        _contentURL = nil;
        err = nil;
    }
    //倒序视频
    if (_reverseVideoURL && [fman fileExistsAtPath:[[RDHelpClass getFileURLFromAbsolutePath:_reverseVideoURL.absoluteString] path]]) {
        [fman removeItemAtPath:[[RDHelpClass getFileURLFromAbsolutePath:_reverseVideoURL.absoluteString] path] error:&err];
        if (err) {
            NSLog(@"删除倒序视频出错： %@", err);
        }
        _reverseVideoURL = nil;
        err = nil;
    }
    //文字板
    if (_customTextPhotoFile.filePath && [fman fileExistsAtPath:[[RDHelpClass getFileURLFromAbsolutePath:_customTextPhotoFile.filePath] path]]) {
        [fman removeItemAtPath:[[RDHelpClass getFileURLFromAbsolutePath:_customTextPhotoFile.filePath] path] error:&err];
        if (err) {
            NSLog(@"删除倒序视频出错： %@", err);
        }
        _customTextPhotoFile = nil;
        err = nil;
    }
}

@end
