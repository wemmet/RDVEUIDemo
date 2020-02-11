//
//  RD_VideoThumbnailView.m
//  dyUIAPI
//
//  Created by emmet on 2017/5/26.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RD_VideoThumbnailView.h"
#define THUMBNAILVIEWTAG 10000

@interface RDTrackView()
{
    float _difxSpan;
}
@end

@implementation RDTrackView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    _difxSpan = 0;
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        CGPoint p = [aTouch locationInView:self.superview];
        
        _difxSpan = p.x - self.frame.origin.x;
        
        if(_delegate){
            if([_delegate respondsToSelector:@selector(touchesBegin)]){
                [_delegate touchesBegin];
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    if (aTouch.tapCount == 1) {
        CGPoint p = [aTouch locationInView:self.superview];
        self.frame = CGRectMake(MAX(MIN(p.x - _difxSpan, self.superview.frame.size.width - self.frame.size.width/2.0), - self.frame.size.width/2.0), self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        if(_delegate){
            if([_delegate respondsToSelector:@selector(touchesMoved)]){
                [_delegate touchesMoved];
            }
        }
    }
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesEnd)]){
            [_delegate touchesEnd];
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesEnd)]){
            [_delegate touchesEnd];
        }
    }
}

@end


@interface RD_VideoThumbnailView()<RDTrackViewDelegate,RDRangeViewDelegate>{
    
    
    UIView      *_thumbnailBackgroundView;
    UIView      *_timeEffectBackgroundView;
    UIView      *_filterEffectBackgroundView;
    UIImageView *_filterEffectView;
    
    RDTrackView *_progressTrack;
    UIImageView *_trackImageView;
    UIView      *_effectTrack;
    NSTimer     *_observer;
    float        _thumbnailCount;
    
    NSMutableArray *_saveFilterEffectList;
    NSMutableArray *_saveTimeEffectList;
    CMTimeRange     _lastTimeEffectTimeRange;
    //记录添加的每一类时间特效的时间范围
    CMTimeRange     _effectTypeSlowTimeRange;
    CMTimeRange     _effectTypeRepeatTimeRange;
    CMTimeRange     _effectTypeReverseTimeRange;
    
}
@end

@implementation RD_VideoThumbnailView

- (instancetype)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        
        _isApla = false;
        
        _thumbnailProportion = 1.0;
        _borderHeight = 0;
        _lastTimeEffectTimeRange = kCMTimeRangeZero;
        _hasChangeEffect = NO;
        _filterEffectList = [NSMutableArray new];
        _timeEffectList = [NSMutableArray new];
        
        _effectTypeReverseTimeRange = kCMTimeRangeZero;
        _effectTypeRepeatTimeRange  = kCMTimeRangeZero;
        _effectTypeSlowTimeRange    = kCMTimeRangeZero;
        if(!_trackColor){
            _trackColor = [UIColor whiteColor];
        }
        
        _thumbnailBackgroundView = [UIView new];
        _timeEffectBackgroundView = [UIView new];
        _filterEffectBackgroundView = [UIView new];
        _filterEffectView = [UIImageView new];
        
        _thumbnailBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        _timeEffectBackgroundView.backgroundColor = [UIColor clearColor];
        _filterEffectBackgroundView.backgroundColor = [UIColor clearColor];
        _filterEffectView.backgroundColor = [UIColor clearColor];
        
        _thumbnailBackgroundView.layer.masksToBounds = YES;
        _timeEffectBackgroundView.layer.masksToBounds = YES;
        _filterEffectBackgroundView.layer.masksToBounds = YES;
        _filterEffectView.layer.masksToBounds = YES;
        
        _filterEffectBackgroundView.hidden = YES;
        _timeEffectBackgroundView.hidden = NO;
        
        _progressTrack = [RDTrackView new];
        
        _trackImageView = [UIImageView new];
        
        
        _trackImageView.layer.cornerRadius = 3;
        _trackImageView.layer.masksToBounds = YES;
        _trackImageView.backgroundColor = _trackColor;
        
        _progressTrack.backgroundColor = [UIColor clearColor];
        _progressTrack.delegate = self;
        
        [self addSubview:_thumbnailBackgroundView];
        [self addSubview:_filterEffectBackgroundView];
        [self addSubview:_timeEffectBackgroundView];
        [self addSubview:_progressTrack];
        
        [_filterEffectBackgroundView addSubview:_filterEffectView];
        
        [_progressTrack addSubview:_trackImageView];
        
        _thumbnailBackgroundView.frame = CGRectMake(0, 3, self.bounds.size.width, self.bounds.size.height - 9);
        _timeEffectBackgroundView.frame = self.bounds;
        _filterEffectBackgroundView.frame = self.bounds;
        _filterEffectView.frame = _filterEffectBackgroundView.bounds;
        _progressTrack.frame = CGRectMake(-10, 0, 20, self.bounds.size.height);
        _trackImageView.frame = CGRectMake(_progressTrack.frame.size.width/2.0-2, 0, 4, self.bounds.size.height);
    }
    
    return self;
    
}

- (void)saveEffect{
    
    _saveFilterEffectList = [_filterEffectList mutableCopy];
    
    _saveTimeEffectList = [_timeEffectList mutableCopy];
    
}


- (void)setTrackOutImage:(UIImage *)trackOutImage{
    _trackOutImage = trackOutImage;
    if(_trackOutImage){
        _trackImageView.backgroundColor = [UIColor clearColor];
        _trackImageView.image = _trackOutImage;
        float height = MIN(_trackOutImage.size.height, _trackImageView.frame.size.height);
        height = height/2.0;
        _trackImageView.frame = CGRectMake((_progressTrack.frame.size.width - height)/2.0, 0, height, self.bounds.size.height);
        
    }
}

#pragma mark- RDTrackViewDelegate

- (void)touchesBegin{
    if(_trackMoveBegin){
        _trackMoveBegin(_progress);
    }
    if(_trackInImage){
        _trackImageView.image = _trackInImage;
    }
}

- (void)touchesMoved{
    _progress = _progressTrack.center.x / self.frame.size.width;
    if(_trackMoving){
        _trackMoving(_progress);
    }
}

- (void)touchesEnd{
    _progress = _progressTrack.center.x / self.frame.size.width;
    if(_trackMoveEnd){
        _trackMoveEnd(_progress);
    }
    if(_trackOutImage){
        _trackImageView.image = _trackOutImage;
    }
}

#pragma mark- RDRangeViewDelegate

- (void)touchesRangeViewBegin:(RDRangeView *)rangView{
    if(rangView.file.effectType == kTimeEffect){
        float progress = rangView.frame.origin.x/_timeEffectBackgroundView.frame.size.width;
        rangView.file.start = _duration * progress;
        rangView.file.duration = rangView.frame.size.width/_timeEffectBackgroundView.frame.size.width *_duration;
        _progressTrack.hidden = YES;
        if(_delegate){
            if([_delegate respondsToSelector:@selector(timeEffectChangeBegin:)]){
                [_delegate timeEffectChangeBegin:rangView.file.timeRange];
            }
        }
    }
}

- (void)touchesRangeViewMoving:(RDRangeView *)rangView{
    if(rangView.file.effectType == kTimeEffect){
        float progress = rangView.frame.origin.x/_timeEffectBackgroundView.frame.size.width;
        rangView.file.start = _duration * progress;
        rangView.file.duration = rangView.frame.size.width/_timeEffectBackgroundView.frame.size.width *_duration;
        
        if(rangView.file.typeIndex == TimeEffectTypeReverse)
            _lastTimeEffectTimeRange = rangView.file.timeRange;
        if(_delegate){
            if([_delegate respondsToSelector:@selector(timeEffectChanging:timeRange:)]){
                [_delegate timeEffectChanging:rangView.file.typeIndex-1 timeRange:rangView.file.timeRange];
            }
        }
        
        switch (rangView.file.typeIndex - 1) {
            case TimeEffectTypeReverse:
                _effectTypeReverseTimeRange = rangView.file.timeRange;
                break;
            case TimeEffectTypeRepeat:
                _effectTypeRepeatTimeRange  = rangView.file.timeRange;
                break;
            case TimeEffectTypeSlow:
                _effectTypeSlowTimeRange    = rangView.file.timeRange;
                break;
                
            default:
                break;
        }
    }
}

- (void)touchesRangeViewEnd:(RDRangeView *)rangView{
    if(rangView.file.effectType == kTimeEffect){
        float progress = rangView.frame.origin.x/_timeEffectBackgroundView.frame.size.width;
        rangView.file.start = _duration * progress;
        rangView.file.duration = rangView.frame.size.width/_timeEffectBackgroundView.frame.size.width *_duration;
        _progress = progress;
        _progressTrack.frame = CGRectMake(_progress*self.frame.size.width - 10, 0 , 20, self.bounds.size.height);
        _progressTrack.hidden = NO;
        
        if(_delegate){
            if([_delegate respondsToSelector:@selector(timeEffectchanged:timeRange:)]){
                [_delegate timeEffectchanged:rangView.file.typeIndex-1 timeRange:rangView.file.timeRange];
            }
        }
    }
}


- (void)setBorderHeight:(float)borderHeight{
    _borderHeight = borderHeight;
    _thumbnailBackgroundView.frame = CGRectMake(0, _borderHeight, self.bounds.size.width, self.bounds.size.height - _borderHeight*2.0);
    _timeEffectBackgroundView.frame = _thumbnailBackgroundView.frame;
    _filterEffectBackgroundView.frame = _thumbnailBackgroundView.frame;
    _filterEffectView.frame = _filterEffectBackgroundView.bounds;
    [_filterEffectView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (int i = 0; i<_filterEffectView.frame.size.width; i++) {
        UIView *coverColorView = [UIView new];
        coverColorView.tag = i+1;
        coverColorView.frame = CGRectMake(i, 0, 1, _filterEffectView.frame.size.height);
        coverColorView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.0];
        [_filterEffectView addSubview:coverColorView];
    }
    _filterEffectView.hidden = NO;
}

- (void)setDuration:(float)duration{
    if (_duration > 0) {
        _duration = duration;
        return;
    }
    _duration = duration;
    [_thumbnailBackgroundView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    float width = (_thumbnailBackgroundView.frame.size.height * _thumbnailProportion);
    
    _thumbnailCount = ceil(_thumbnailBackgroundView.frame.size.width / (width/2.0));
    
    _durationPerFrame = _duration/_thumbnailCount;
    if(_thumbnailTimes){
        [_thumbnailTimes removeAllObjects];
    }
    _thumbnailTimes = nil;
    _thumbnailTimes = [NSMutableArray new];
    
    for (int i = 0 ; i < _thumbnailCount ; i++) {
        
        CMTime time = CMTimeMakeWithSeconds(0.1 + _startTime + i*_durationPerFrame, TIMESCALE);
        [_thumbnailTimes addObject:[NSValue valueWithCMTime:time]];
        
        UIImageView *thumbnailView = [UIImageView new];
        thumbnailView.frame = CGRectMake((width) * i, 0, (width), _thumbnailBackgroundView.frame.size.height);
        thumbnailView.backgroundColor = [UIColor clearColor];
        thumbnailView.tag = i+THUMBNAILVIEWTAG;
        thumbnailView.layer.masksToBounds = YES;
        thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
        [_thumbnailBackgroundView addSubview:thumbnailView];
    }
    
}

- (void)setProgress:(float)progress{
    _progress = progress;
    
    _progressTrack.frame = CGRectMake(_progress*self.frame.size.width - 10, 0 , 20, self.bounds.size.height);
    
}

- (void)setEffectType:(EffectType)effectType{
    _effectType = effectType;
    switch (effectType) {
        case kFilterEffect://滤镜特效
        {
            _timeEffectBackgroundView.hidden = YES;
            _filterEffectBackgroundView.hidden = NO;
        }
            break;
        case kTimeEffect://时间特效
        {
            _timeEffectBackgroundView.hidden = NO;
            _filterEffectBackgroundView.hidden = YES;
        }
            break;
        default:
            break;
    }
}

/**检测是否有重叠部分有重叠部分则干掉底下的颜色
 */
- (void)checkLastRangeCoverWidth{
    WeakSelf(self);
    [_filterEffectView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIColor *color = [UIColor clearColor];
        StrongSelf(self);
        for (NSInteger i = (strongSelf->_filterEffectList.count - 1);i>=0; i--) {
            RDRangeView *samp = strongSelf->_filterEffectList[i];
            samp.alpha = 0;
            if(obj.frame.origin.x + obj.frame.size.width <= samp.frame.size.width + samp.frame.origin.x && obj.frame.origin.x + obj.frame.size.width >= samp.frame.origin.x){
                color = [strongSelf colorWithColor:samp.coverColor Alpha:0.6];
                break;
            }
        }
        
        obj.backgroundColor = color;
    }];
    
    [_filterEffectList enumerateObjectsUsingBlock:^(RDRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hidden = YES;
    }];
}

- (UIColor *) colorWithColor:(UIColor *)color Alpha:(float)alpha
{
    if(color){
        CGFloat r = 0,g = 0,b = 0,a = 0;
        [color getRed:&r green:&g blue:&b alpha:&a];
        if( a != 0 )
            a = alpha;
        color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        
    }
    return color;
}

/**改变最后一次添加的特效时间
 */
- (void)changeEffectWidth{
    switch (_effectType) {
        case kFilterEffect://添加滤镜特效
        {
            
            CGRect rect = [_filterEffectList lastObject].frame;
            rect.size.width = MAX(_filterEffectBackgroundView.frame.size.width*_progress - rect.origin.x+1, rect.size.width);
            [_filterEffectList lastObject].frame = rect;
            [_filterEffectList lastObject].coverRect = [_filterEffectList lastObject].bounds;
            [_filterEffectList lastObject].file.duration = _duration*_progress - [_filterEffectList lastObject].file.start;
//            NSLog(@"start:%f duration:%f",[_filterEffectList lastObject].file.start,[_filterEffectList lastObject].file.duration);
        }
            break;
        case kTimeEffect://添加时间特效
        {
            CGRect rect = [_timeEffectList lastObject].frame;
            rect.size.width = MAX(_timeEffectBackgroundView.frame.size.width*_progress - rect.origin.x+1, rect.size.width);
            [_timeEffectList lastObject].frame = rect;
            [_timeEffectList lastObject].file.duration = _duration*_progress - [_timeEffectList lastObject].file.start;
        }
            break;
        default:
            break;
    }
}

/**获取时间特效的开始时间
 */
- (CMTimeRange)getTimeEffectTimeRange{
    return [_timeEffectList lastObject].file.timeRange;
}

/**添加滤镜特效
 * param: fxId 特效ID
 * param: timeRange 特效时间段
 */
- (void)addFilterEffect:(int)fxId color:(UIColor *)color withTimeRange:(CMTimeRange)timeRange currentFrameTexturePath:(NSString *)currentFrameTexturePath {
    
    RDRangeView *effect = [RDRangeView new];
    float startOffx = _filterEffectBackgroundView.frame.size.width * (CMTimeGetSeconds(timeRange.start)/_duration);
    float durationWidth = _filterEffectBackgroundView.frame.size.width * (CMTimeGetSeconds(timeRange.duration)/_duration);
    effect.frame = CGRectMake(startOffx-1, 0, durationWidth+1, _filterEffectBackgroundView.frame.size.height);
    effect.file = [RDRangeViewFile new];
    effect.file.start = CMTimeGetSeconds(timeRange.start);
    effect.file.duration = CMTimeGetSeconds(timeRange.duration);
    effect.file.fxId = fxId;
    effect.file.effectType = kFilterEffect;
    effect.file.currentFrameTexturePath = currentFrameTexturePath;
    effect.coverColor = color;
    effect.coverRect = effect.bounds;
    [_filterEffectList addObject:effect];
    _filterEffectBackgroundView.hidden = NO;
    [_filterEffectBackgroundView addSubview:effect];
    [self checkLastRangeCoverWidth];
}

/**添加时间特效
 * param: typeindex 特效ID
 * param: timeRange 特效时间段
 */
- (void)addTimeEffect:(NSInteger)typeIndex color:(UIColor *)color withTimeRange:(CMTimeRange)timeRange{
    
    switch (typeIndex - 1) {
        case TimeEffectTypeReverse:
        {
            if(!CMTimeRangeEqual(_effectTypeReverseTimeRange, kCMTimeRangeZero)){
                timeRange = _effectTypeReverseTimeRange;
            }
        }   break;
        case TimeEffectTypeRepeat:
        {
            if(!CMTimeRangeEqual(_effectTypeRepeatTimeRange, kCMTimeRangeZero)){
                timeRange = _effectTypeRepeatTimeRange;
            }
        } break;
        case TimeEffectTypeSlow:
        {
            if(!CMTimeRangeEqual(_effectTypeSlowTimeRange, kCMTimeRangeZero)){
                timeRange = _effectTypeSlowTimeRange;
            }
        } break;
            
        default:
            break;
    }
    [self annulTimeEffect];
    
    RDRangeView *effect = [RDRangeView new];
    float startOffx = _filterEffectBackgroundView.frame.size.width * (CMTimeGetSeconds(timeRange.start)/_duration);
    float durationWidth = _filterEffectBackgroundView.frame.size.width * (CMTimeGetSeconds(timeRange.duration)/_duration);
    effect.canChangeWidth = YES;
    effect.minWidth = _timeEffectBackgroundView.frame.size.width/_duration;
    effect.backgroundColor = [color colorWithAlphaComponent:0.8];
    effect.frame = CGRectMake(startOffx, 0, durationWidth, _filterEffectBackgroundView.frame.size.height);
    effect.file = [RDRangeViewFile new];
    effect.file.effectType = kTimeEffect;
    effect.file.start = CMTimeGetSeconds(timeRange.start);
    effect.file.duration = CMTimeGetSeconds(timeRange.duration);
    effect.file.typeIndex = typeIndex;
    if(typeIndex - 1 == TimeEffectTypeReverse){
        effect.canMoveLeft = YES;
        effect.canMoveRight = YES;
        effect.canChangeWidth = YES;
    }else{
        effect.hasMiddle = YES;
    }
    
    switch (typeIndex - 1) {
        case TimeEffectTypeReverse:
            _effectTypeReverseTimeRange = timeRange;
            break;
        case TimeEffectTypeRepeat:
            _effectTypeRepeatTimeRange  = timeRange;
            break;
        case TimeEffectTypeSlow:
            _effectTypeSlowTimeRange    = timeRange;
            break;
            
        default:
            break;
    }
    
    effect.delegate = self;
    [_timeEffectList addObject:effect];
    [_timeEffectBackgroundView addSubview:effect];
}

/**添加特效
 * param: fxId 特效ID
 * param: time 特效开始时间
 */
- (void)addEffect:(int)fxId color:(UIColor *)color withTime:(float)time{
    _hasChangeEffect = YES;
    if (_effectType == kFilterEffect) {
        RDRangeView *effect = [RDRangeView new];
        float startOffx = _filterEffectBackgroundView.frame.size.width * _progress;
        if( !_isApla )
            effect.backgroundColor = color;
        else
            effect.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
        
        effect.frame = CGRectMake(startOffx, 0, 1, _filterEffectBackgroundView.frame.size.height);
        effect.file = [RDRangeViewFile new];
        effect.file.effectType = _effectType;
        effect.file.start = time;
        effect.file.duration = 0;
        effect.file.fxId = fxId;
        if( !_isApla )
            effect.coverColor = color;
        else
            effect.coverColor = [UIColor colorWithWhite:1 alpha:0];
        effect.coverRect = effect.bounds;
        [_filterEffectList addObject:effect];
        [_filterEffectBackgroundView addSubview:effect];
    }

    [self addObserver];
}

- (void)finishAddEffect{
    _filterEffectView.hidden = NO;
    [self changeEffectWidth];
    [self checkLastRangeCoverWidth];
    [self removeObserver];
}

/**撤销所有特效
 */
- (void)annulAllEffect{
    _hasChangeEffect = YES;
    _filterEffectView.image = nil;
    if(_filterEffectList.count>0){
        
        [_filterEffectList enumerateObjectsUsingBlock:^(RDRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [_filterEffectList removeAllObjects];
        [self checkLastRangeCoverWidth];
    }
    if(_timeEffectList.count>0){
        [[_timeEffectList lastObject] removeFromSuperview];
        [_timeEffectList lastObject].file = nil;
        [_timeEffectList removeLastObject];
    }
}

/**撤销时间特效
 */
- (void)annulTimeEffect{
    _hasChangeEffect = YES;
    if(_timeEffectList.count>0){
        if([_timeEffectList lastObject].file.typeIndex-1 != TimeEffectTypeReverse){
            _lastTimeEffectTimeRange = [_timeEffectList lastObject].file.timeRange;
        }
        [[_timeEffectList lastObject] removeFromSuperview];
        [_timeEffectList lastObject].file = nil;
        [_timeEffectList removeLastObject];
    }
    
}

/**撤销最后一次添加的滤镜特效
 */
- (CMTime)annulLastFilterEffect{
    _hasChangeEffect = YES;
    CMTime lastEffectTime = kCMTimeZero;
    lastEffectTime = [_filterEffectList lastObject].file.timeRange.start;
    float current = CMTimeGetSeconds(lastEffectTime);
    if(isnan(current)){
        lastEffectTime = kCMTimeZero;
    }
    if(_filterEffectList.count>0){
        [[_filterEffectList lastObject] removeFromSuperview];
        [_filterEffectList lastObject].file = nil;
        [_filterEffectList removeLastObject];
    }
    
    [self checkLastRangeCoverWidth];
    
    return lastEffectTime;
}

/**刷新缩率图
 * param: index 第几张缩率图
 * param: thumbnail 缩率图
 */
- (void)refreshThumbImage:(NSInteger)index thumbImage:(UIImage *)thumbnail{
    UIImageView *thumbnailView = (UIImageView *)[_thumbnailBackgroundView viewWithTag:index +THUMBNAILVIEWTAG];
    thumbnailView.image = thumbnail;
    
}

- (void)clearImages {
    [_thumbnailBackgroundView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIImageView class]]) {
            UIImageView *imageIV = (UIImageView *)obj;
            imageIV.image = nil;
        }
    }];
}

/**获取添加的滤镜特效
 */
- (NSArray<RDRangeView *> *)getFilterEffectList{
    return _filterEffectList;
}

/**获取添加的特效
 */
- (NSArray<RDRangeView *> *)getTimeEffectList{
    return _timeEffectList;
}

- (BOOL)hasEffect{
    if(_filterEffectList.count>0 || _timeEffectList.count>0){
        return YES;
    }else{
        return NO;
    }
}


- (void)dealloc{
    NSLog(@"%s",__func__);
    [self clearImages];
    
    [self removeObserver];
    
    [_thumbnailTimes removeAllObjects];
    _thumbnailTimes = nil;
    
    [_filterEffectList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(RDRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj = nil;
    }];
    [_filterEffectList removeAllObjects];
    _filterEffectList = nil;
    
    [_timeEffectList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(RDRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj = nil;
    }];
    [_timeEffectList removeAllObjects];
    _timeEffectList = nil;
    
    
    [_thumbnailBackgroundView removeFromSuperview];
    [_timeEffectBackgroundView removeFromSuperview];
    [_filterEffectBackgroundView removeFromSuperview];
    
    /**进度条图片
     */
    _trackInImage = nil;
    
    /**进度条图片
     */
    _trackOutImage = nil;
}

- (void)addObserver{
    
    [self removeObserver];
    
    _observer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(changeEffectWidth) userInfo:nil repeats:YES];
}

- (void)removeObserver{
    if(_observer){
        [_observer invalidate];
        _observer = nil;
    }
}

@end
