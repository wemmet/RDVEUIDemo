//
//  RDDraftCaption.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/9.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDraftCaption.h"

@implementation RDDraftCaptionAnimate

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [@[@"animate"] containsObject:propertyName];
}

- (void)setAnimate:(RDCaptionAnimate *)animate {
    _isFade = animate.isFade;
    _fadeInDuration = animate.fadeInDuration;
    _fadeOutDuration = animate.fadeOutDuration;
    _type = animate.type;
    _inDuration = animate.inDuration;
    _outDuration = animate.outDuration;
    _pushInPoint = animate.pushInPoint;
    _pushOutPoint = animate.pushOutPoint;
    _scaleIn = animate.scaleIn;
    _scaleOut = animate.scaleOut;
}


@end

@implementation RDDraftMusic

- (instancetype)init {
    self = [super init];
    if (self) {
        _effectiveTimeRange = kCMTimeRangeZero;
    }
    return self;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [@[@"music"] containsObject:propertyName];
}

- (void)setMusic:(RDMusic *)music {
    _identifier = music.identifier;
    _url = music.url;
    _effectiveTimeRange = music.effectiveTimeRange;
    _clipTimeRange = music.clipTimeRange;
    _name = music.name;
    _volume = music.volume;
    _isRepeat = music.isRepeat;
    _isFadeInOut = music.isFadeInOut;
    _headFadeDuration = music.headFadeDuration;
    _endFadeDuration = music.endFadeDuration;
    _audioFilterType = music.audioFilterType;
}

- (RDMusic *)getMusic {
    RDMusic *music = [RDMusic new];
    music.identifier= _identifier;
    music.url = [RDHelpClass getFileURLFromAbsolutePath:_url.absoluteString];
    music.effectiveTimeRange = _effectiveTimeRange;
    music.clipTimeRange = _clipTimeRange;
    music.name = _name;
    music.volume = _volume;
    music.isRepeat = _isRepeat;
    music.isFadeInOut = _isFadeInOut;
    music.headFadeDuration = _headFadeDuration;
    music.endFadeDuration = _endFadeDuration;
    music.audioFilterType = _audioFilterType;
    return music;
}

- (NSDictionary *)JSONObjectForEffectiveTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_effectiveTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setEffectiveTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _effectiveTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForClipTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_clipTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setClipTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _clipTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

@end

@implementation RDDraftMovieEffect

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [@[@"movieEffect"] containsObject:propertyName];
}

- (void)setMovieEffect:(VVMovieEffect *)movieEffect {
    _url = movieEffect.url;
    _timeRange = movieEffect.timeRange;
    _type = movieEffect.type;
    _alpha = movieEffect.alpha;
    _shouldRepeat = movieEffect.shouldRepeat;
}

- (VVMovieEffect *)geMovieEffect {
    VVMovieEffect *movieEffect = [VVMovieEffect new];
    movieEffect.url = [RDHelpClass getFileURLFromAbsolutePath:_url.absoluteString];
    movieEffect.timeRange = _timeRange;
    movieEffect.type = _type;
    movieEffect.alpha = _alpha;
    movieEffect.shouldRepeat = _shouldRepeat;
    
    return movieEffect;
}

- (NSDictionary *)JSONObjectForTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_timeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _timeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

@end
