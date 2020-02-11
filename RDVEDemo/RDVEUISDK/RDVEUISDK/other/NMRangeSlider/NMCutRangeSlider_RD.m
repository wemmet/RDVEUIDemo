//
//  NMCutRangeSlider_RD.m
//  RDVEUISDK
//
//  Created by emmet on 16/7/12.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import "NMCutRangeSlider_RD.h"

#import "RDHelpClass.h"

@interface NMCutRangeSlider_RD ()
{
    float _lowerTouchOffset;
    float _upperTouchOffset;
    float _stepValueInternal;
    BOOL  _haveAddedSubviews;
    float _lowerValue;
    float _uperValue;
    CGPoint _touchBeginPoint;
    
    float _moveTouchOffset;
    int loadingIndex;
    
    UIImage * CacheImage;
}
@property (strong, nonatomic) UIImageView* leftCover;
@property (strong, nonatomic) UIImageView* rightCover;
@property (strong, nonatomic) UIImageView* track;
@property (strong, nonatomic) UIImageView* trackBackground;

@end

@implementation NMCutRangeSlider_RD

@synthesize track;
@synthesize trackBackground;
@synthesize minimumRange = _minimumRange;
@synthesize minimumValue = _minimumValue;
@synthesize maximumValue = _maximumValue;
@synthesize stepValue = _stepValue;
@synthesize continuous =  _continuous;
@synthesize lowerValue = _lowerValue;
@synthesize upperValue =  _upperValue;
@synthesize lowerHandle = _lowerHandle;
@synthesize upperHandle = _upperHandle;
@synthesize trackBackgroundImage = _trackBackgroundImage;
@synthesize trackImage = _trackImage;
@synthesize lowerHandleImageNormal = _lowerHandleImageNormal;
@synthesize lowerHandleImageHighlighted = _lowerHandleImageHighlighted;
@synthesize upperHandleImageNormal = _upperHandleImageNormal;
@synthesize upperHandleImageHighlighted = _upperHandleImageHighlighted;
@synthesize stepValueContinuously = _stepValueContinuously;

#pragma mark -
#pragma mark - Constructors

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self configureView];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self configureView];
    }
    
    return self;
}


- (void) configureView
{
    //Setup the default values
    _minimumValue = 0.0;
    _maximumValue = 1.0;
    //_minimumRange = 0.0;
    _stepValue = 0.0;
    _stepValueInternal = 0.0;
    
    _continuous = YES;
    _lowerHandle.highlighted = YES;
    _upperHandle.highlighted = NO;
    _lowerValue = 0.0;
    _upperValue = 1.0;
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Properties

- (CGPoint) lowerCenter
{
    return _lowerHandle.center;
}

- (CGPoint) upperCenter
{
    return _upperHandle.center;
}

- (void) setLowerValue:(float)lowerValue
{
    float value = lowerValue;
    
    if(_stepValueInternal>0)
    {
        value = roundf(value / _stepValueInternal) * _stepValueInternal;
    }
    value = MAX(value, _minimumValue);
    value = MIN(value, _upperValue - _minimumRange);
    _lowerValue = value;
    [self setNeedsLayout];
}

- (void) setUpperValue:(float)upperValue
{
    float value = upperValue;
    if(_stepValueInternal>0)
    {
        value = roundf(value / _stepValueInternal) * _stepValueInternal;
    }
    value = MIN(value, _maximumValue);
    value = MAX(value, _lowerValue+_minimumRange);
    if(!_mode){
        value = MIN(value, _lowerValue + _moveValue);
    }
    _upperValue = value;
    [self setNeedsLayout];
}


- (void) setLowerValue:(float) lowerValue upperValue:(float) upperValue animated:(BOOL)animated
{
    if((!animated) && (isnan(lowerValue) || lowerValue==_lowerValue) && (isnan(upperValue) || upperValue==_upperValue))
    {
        return;
    }
    __block void (^setValuesBlock)(void) = ^ {
        
        if(!isnan(lowerValue))
        {
            [self setLowerValue:lowerValue];
        }
        if(!isnan(upperValue))
        {
            [self setUpperValue:upperValue];
        }
    };
    
    if(animated)
    {
        [UIView animateWithDuration:0.25  delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             setValuesBlock();
                             [self layoutSubviews];
                             
                         } completion:^(BOOL finished) {
                             
                         }];
        
    }
    else
    {
        setValuesBlock();
    }
    
}

- (void)setLowerValue:(float)lowerValue animated:(BOOL) animated
{
    [self setLowerValue:lowerValue upperValue:NAN animated:animated];
}

- (void)setUpperValue:(float)upperValue animated:(BOOL) animated
{
    [self setLowerValue:NAN upperValue:upperValue animated:animated];
}

//ON-Demand images. If the images are not set, then the default values are loaded.

- (UIImage *)trackBackgroundImage
{
    if(_trackBackgroundImage==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-trackBackground"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
        _trackBackgroundImage = image;
    }
    
    return _trackBackgroundImage;
}

- (UIImage *)progressTrackImage{
    if(_progressTrackImage==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-trackBackground"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
        _progressTrackImage = image;
    }
    return _progressTrackImage;
}

- (UIImage *)trackImage
{
    if(_trackImage==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-track"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
        _trackImage = image;
    }
    
    return _trackImage;
}

- (UIImage *)lowerHandleImageNormal
{
    if(_lowerHandleImageNormal==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-handle"];
        _lowerHandleImageNormal = image;
    }
    return _lowerHandleImageNormal;
}

- (UIImage *)lowerHandleImageHighlighted
{
    if(_lowerHandleImageHighlighted==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-handle-highlighted"];
        _lowerHandleImageHighlighted = image;
    }
    return _lowerHandleImageHighlighted;
}

- (UIImage *)upperHandleImageNormal
{
    if(_upperHandleImageNormal==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-handle"];
        _upperHandleImageNormal = image;
    }else{
        if(_uperValue == 0){
            _uperValue = 1;
        }
    }
    return _upperHandleImageNormal;
}

- (UIImage *)upperHandleImageHighlighted
{
    if(_upperHandleImageHighlighted==nil)
    {
        UIImage* image = [RDHelpClass imageWithContentOfFile:@"slider-default-handle-highlighted"];
        _upperHandleImageHighlighted = image;
    }else{
        if(_uperValue == 0){
            _uperValue = 1;
        }
    }
    return _upperHandleImageHighlighted;
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Math Math Math

//Returns the lower value based on the X potion
//The return value is automatically adjust to fit inside the valid range


-(float) lowerValueForCenterX:(float)x
{
    float _padding = _lowerHandle.frame.size.width/2.0f;
//    float value = _minimumValue + (x - _padding)/(self.frame.size.width - _lowerHandle.frame.size.width - _upperHandle.frame.size.width) * (_maximumValue - _minimumValue);
    //20190621 修复bug:只点击把手，松手后把手会往后挪动
    float value = _minimumValue + (x-_padding) / (self.frame.size.width-(_padding*2)) * (_maximumValue - _minimumValue);
    value = MAX(value, _minimumValue);
    value = value < _upperValue - _minimumRange?value : _upperValue - _minimumRange;//MIN(value, _upperValue - _minimumRange);
    _lowerValue = value;
    return value;
}

//Returns the upper value based on the X potion
//The return value is automatically adjust to fit inside the valid range
-(float) upperValueForCenterX:(float)x
{
    float _padding = _upperHandle.frame.size.width/2.0f;
//    float value = _minimumValue + (x-_padding) / ((self.frame.size.width - _lowerHandle.frame.size.width - _upperHandle.frame.size.width)) * (_maximumValue - _minimumValue);
    //20190621 修复bug:只点击把手，松手后把手会往后挪动
    float value = _minimumValue + (x-_padding) / (self.frame.size.width-(_padding*2)) * (_maximumValue - _minimumValue);
    value = MIN(value, _maximumValue);
    value = MAX(value, _lowerValue+_minimumRange);
    _uperValue = value;
    return value;
}

//returns the rect for the track image between the lower and upper values based on the trackimage object
- (CGRect)trackRect
{
    CGRect retValue;
    
    float xLowerValue = ((self.bounds.size.width - _lowerHandle.frame.size.width - _upperHandle.frame.size.width) * (_lowerValue - _minimumValue) / (_maximumValue - _minimumValue));//+_lowerHandle.frame.size.width/2+6.5 -1;
    if (_mode) {
        xLowerValue += _lowerHandle.frame.size.width/2+6.5 -1;
    }
    float xUpperValue = ((self.bounds.size.width - _upperHandle.frame.size.width ) * (_upperValue - _minimumValue) / (_maximumValue - _minimumValue));
    retValue.origin = CGPointMake(xLowerValue, 0);
    if(!_mode){
        retValue.size.width = MIN((xUpperValue-xLowerValue+2+2)>20?(xUpperValue-xLowerValue+2+2):20, (self.bounds.size.width - _upperHandle.frame.size.width ) * _selectedDurationValue/(float)_durationValue);
    }else{
        retValue.size.width = (xUpperValue-xLowerValue+2+2)>20?(xUpperValue-xLowerValue+2+2):20;
    }
    retValue.size.height = self.frame.size.height;
    
    return retValue;
}

- (CGRect)progressTrackRect
{
    CGRect rect = _progressTrack.frame;
    if(isnan(_durationValue)){
        return rect;
    }
    
    float perw = (self.frame.size.width - self.upperHandle.frame.size.width - self.lowerHandle.frame.size.width)/_durationValue;
    float progressWidth = MIN(self.frame.size.width - self.upperHandle.frame.size.width - self.lowerHandle.frame.size.width, perw *_progressValue);
    rect.origin.x = progressWidth + self.lowerHandle.frame.size.width;
    rect.size.width = 6;
    rect.size.height = self.frame.size.height;
    if (!_mode) {
        rect.origin.x = MIN(self.upperHandle.frame.origin.x+self.upperHandle.frame.size.width + self.lowerHandle.frame.size.width/2.0, _progressValue/_durationValue*self.frame.size.width) ;
    }
    return rect;
}

//returns the rect for the background image
-(CGRect) trackBackgroundRect
{
    CGRect trackBackgroundRect;
    trackBackgroundRect.size = CGSizeMake(self.frame.size.width, self.frame.size.height);
    if(_trackBackgroundImage.capInsets.top || _trackBackgroundImage.capInsets.bottom)
    {
        trackBackgroundRect.size.height=self.bounds.size.height;
    }
    if(_trackBackgroundImage.capInsets.left || _trackBackgroundImage.capInsets.right)
    {
        trackBackgroundRect.size.width=self.bounds.size.width;
    }
    trackBackgroundRect.origin = CGPointMake(0, 0);
    return trackBackgroundRect ;
}


//returms the rect of the tumb image for a given track rect and value
- (CGRect)thumbRectForValue:(float)value image:(UIImage*) thumbImage withMode:(BOOL) mode
{
    CGRect thumbRect;
    UIEdgeInsets insets = thumbImage.capInsets;
    thumbRect.size = CGSizeMake(thumbImage.size.width, self.frame.size.height);
    if(insets.top || insets.bottom)
    {
        thumbRect.size.height=self.bounds.size.height;
    }
    float xValue = ((self.bounds.size.width-thumbRect.size.width)*((value - _minimumValue) / (_maximumValue - _minimumValue)));
    thumbRect.origin = CGPointMake(xValue, 0);
    
    if (!mode) {
        thumbRect.size.width = 0;
    }
    return thumbRect;
    
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Layout
- (void) insertColorGradient {
    
    return;
    UIColor *colorOne = UIColorFromRGB(0x3ca2ab);
    UIColor *colorTwo = UIColorFromRGB(0x3ca2ab);
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor,nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.frame = CGRectMake(0, 0, self.track.frame.size.width, self.track.frame.size.height);
    headerLayer.startPoint = CGPointMake(0, 1);
    headerLayer.endPoint = CGPointMake(1, 1);
    [self.track.layer insertSublayer:headerLayer above:0];
    
}


- (void) addSubviews
{
    //------------------------------
    // Track Brackground
    self.trackBackground = [[UIImageView alloc] initWithImage:self.trackBackgroundImage];
    self.trackBackground.frame = [self trackBackgroundRect];
    self.trackBackground.backgroundColor = UIColorFromRGB(0X1e1e28);
    //------------------------------
    // Track
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"RDVEUISDK.bundle/视频截取_选取视频_@3x.png"];
    UIImage* image = [UIImage imageWithContentsOfFile:bundlePath];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(18.0, 18.0, 18.0, 18.0)];
    
    if (!_mode) {
        self.track = [[UIImageView alloc] initWithImage:image];
    }else{
        self.track = [[UIImageView alloc] initWithImage:self.trackImage];
        
    }
    //    self.track.backgroundColor = [UIColor redColor];
    self.track.frame = [self trackRect];
    self.track.layer.cornerRadius = 0;
    self.track.layer.masksToBounds = YES;
    [self insertColorGradient];
    
    self.leftCover = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.track.frame.origin.x, self.frame.size.height)];
    self.leftCover.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    
    self.rightCover = [[UIImageView alloc] initWithFrame:CGRectMake(self.track.frame.origin.x +self.track.frame.size.width, 0,self.frame.size.width - (self.track.frame.origin.x + self.track.frame.size.width) , self.frame.size.height)];
    self.rightCover.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    
    //------------------------------
    //progressTrack
    self.progressTrack = [[UIImageView alloc] initWithImage:self.progressTrackImage];
    self.progressTrack.backgroundColor = UIColorFromRGB(0xffffff);
    self.progressTrack.hidden = NO;
    
    self.progressTrack.frame = [self progressTrackRect];
    
    //------------------------------
    // Lower Handle Handle
    self.lowerHandle = [[UIImageView alloc] initWithImage:self.lowerHandleImageNormal highlightedImage:self.lowerHandleImageHighlighted];
    self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal withMode:_mode];
    _lowerHandle.layer.cornerRadius = 5.0;
    _lowerHandle.clipsToBounds = YES;
    //------------------------------
    // Upper Handle Handle
    self.upperHandle = [[UIImageView alloc] initWithImage:self.upperHandleImageNormal highlightedImage:self.upperHandleImageHighlighted];
    self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal withMode:_mode];
    _upperHandle.layer.cornerRadius = 5.0;
    _upperHandle.clipsToBounds = YES;
    //---------------------
    // Between
    
    [self addSubview:self.trackBackground];
    [self addSubview:self.progressTrack];
    [self addSubview:self.track];
    
    [self addSubview:self.leftCover];
    [self addSubview:self.rightCover];
    
    if (_mode) {
        [self addSubview:self.lowerHandle];
        [self addSubview:self.upperHandle];
        
    }else{
        _lowerHandle.userInteractionEnabled = NO;
        _upperHandle.userInteractionEnabled = NO;
    }
    
}

-(void)loadCutRangeSlider
{
    [self performSelector:@selector(loadThumb) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(loadHighlight) withObject:nil afterDelay:0.1];
}

- (void) loadHighlight{
    if (self.highlightArray) {
        [self.highlightArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            float location = [obj floatValue];
            
            UIView* circle = [[UIView alloc] init];
            circle.frame = CGRectMake(location*self.frame.size.width-3, self.frame.size.height/2-3, 6, 6);
            circle.backgroundColor = [UIColor redColor];
            circle.layer.cornerRadius = 3;
            circle.layer.masksToBounds = YES;
            [self insertSubview:circle belowSubview:self.progressTrack];
            
        }];
        
        
        
    }
}
- (CGRect)rightCoverRect{
    return CGRectMake(self.track.frame.origin.x +self.track.frame.size.width, 0,self.frame.size.width - (self.track.frame.origin.x + self.track.frame.size.width) , self.frame.size.height);
    
}

- (CGRect)leftCoverRect{
    return CGRectMake(0, 0, self.track.frame.origin.x, self.frame.size.height);
    
}

-(void)layoutSubviews
{
    if(_haveAddedSubviews==NO)
    {
        _haveAddedSubviews=YES;
        [self addSubviews];
    }
    
    self.trackBackground.frame = [self trackBackgroundRect];
    self.track.frame = [self trackRect];
    
    self.leftCover.frame = [self leftCoverRect];
    self.rightCover.frame = [self rightCoverRect];
    self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal withMode:_mode];
    self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal withMode:_mode];
    self.progressTrack.frame = [self progressTrackRect];
    self.progressTrack.layer.cornerRadius = 3;
    self.progressTrack.layer.masksToBounds = YES;
    
    self.lowerHandle.image = [self lowerHandleImageNormal];
    self.upperHandle.image = [self  upperHandleImageNormal];
    self.lowerHandle.highlightedImage = self.lowerHandleImageHighlighted;
    self.upperHandle.highlightedImage = self.upperHandleImageHighlighted;
    float width = self.upperHandle.frame.origin.x-self.lowerHandle.frame.origin.x;
    
    if (!_mode) {
        CGRect rect = self.lowerHandle.frame;
        rect.origin.x = -10;
        self.lowerHandle.frame = rect;
        
    }
    
    if (width<16) {
        CGRect frameLower=[self.lowerHandle frame];
        CGRect frameUpper=[self.upperHandle frame];
        if (frameLower.origin.x + 14 >= self.frame.size.width - 15 - 14) {
            frameLower.origin.x-=16-width;
            self.lowerHandle.frame=frameLower;
        }else{
            frameUpper.origin.x+=16-width;
            self.upperHandle.frame=frameUpper;
        }
    }
    _minimumRange = (_lowerHandle.frame.size.width)/(self.frame.size.width - (_lowerHandle.frame.size.width + _upperHandle.frame.size.width));
    
    if(self.progressTrack.frame.origin.x<self.lowerHandle.frame.origin.x || self.progressTrack.frame.origin.x>self.upperHandle.frame.origin.x){
        self.progressTrack.hidden = YES;
    }else{
        self.progressTrack.hidden = NO;
    }
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Touch handling

// The handle size can be a little small, so i make it a little bigger
// TODO: Do it the correct way. I think wwdc 2012 had a video on it...
- (CGRect) touchRectForHandle:(UIImageView*) handleImageView
{
    float xPadding = 20;
    float yPadding = 10; //(self.bounds.size.height-touchRect.size.height)/2.0f
    
    CGRect touchRect = handleImageView.frame;
    touchRect.origin.x -= xPadding/2.0;
    touchRect.origin.y -= yPadding/2.0;
    touchRect.size.width += xPadding;
    touchRect.size.height += yPadding;
    return touchRect;
}

- (CGRect) touchRectForProgressTrack:(UIImageView*) handleImageView
{
    float xPadding = 10;
    float yPadding = 10; //(self.bounds.size.height-touchRect.size.height)/2.0f
    
    CGRect touchRect = handleImageView.frame;
    touchRect.origin.x -= xPadding/2.0;
    touchRect.origin.y -= yPadding/2.0;
    touchRect.size.height += yPadding;
    touchRect.size.width += xPadding;
    return touchRect;
}
- (CGRect) touchRectForCenterTrack:(UIImageView*)lowerImageView upperImageView:(UIImageView *)upperImageView{
    CGRect touchRectLower = lowerImageView.frame;
    CGRect touchRectUpper = upperImageView.frame;
    
    CGRect touchRect;
    touchRect.origin.x = touchRectLower.origin.x;
    touchRect.origin.y = touchRectLower.origin.y;
    touchRect.size.width = touchRectUpper.origin.x - touchRectLower.origin.x;
    touchRect.size.height = touchRectLower.size.height;
    return touchRect;
}
static BOOL isCenter = NO;
static float _originX = 0.0;
-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _touchBeginPoint = [touch locationInView:self];
    
    if(CGRectContainsPoint([self touchRectForProgressTrack:_progressTrack], _touchBeginPoint) && _mode)
    {
        
        _handleLeft = NO;
        _handleRight = NO;
        _isblockHandle = YES;
    }
    
    if(CGRectContainsPoint([self touchRectForHandle:_lowerHandle], _touchBeginPoint) && _mode)
    {
        _isblockHandle = NO;
        _handleLeft = YES;
        _handleRight = NO;
        _upperHandle.highlighted = NO;
        _lowerHandle.highlighted = YES;
        _lowerTouchOffset = _touchBeginPoint.x - _lowerHandle.center.x;
    }else if(CGRectContainsPoint([self touchRectForHandle:_upperHandle], _touchBeginPoint) && _mode)
    {
        _handleRight = YES;
        _handleLeft = NO;
        _lowerHandle.highlighted = NO;
        _upperHandle.highlighted = YES;
        _upperTouchOffset = _touchBeginPoint.x - _upperHandle.center.x;
    }else if(CGRectContainsPoint([self trackRect], _touchBeginPoint)){
        if (!_mode) {
            _originX = _lowerValue;
            isCenter = YES;
            if(CGRectContainsPoint([self touchRectForHandle:_progressTrack], _touchBeginPoint)){
                isCenter = NO;
                _isblockHandle = YES;
                _progressTrack.hidden = NO;
            }
        }
    }
    
    _stepValueInternal= _stepValueContinuously ? _stepValue : 0.0f;
    if([_delegate respondsToSelector:@selector(beginScrub:)]){
        [_delegate beginScrub:self];
    }
    return YES;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    
    if(_continuous && !_mode)
    {
        
        //solaren 移动
        if (isCenter) {
            self.progressTrack.hidden = YES;
            float newValue = MIN(self.upperHandle.center.x + self.upperHandle.frame.size.width, (touchPoint.x -_touchBeginPoint.x )/self.frame.size.width + _originX);
            if (newValue>= -0.01 && (newValue+_moveValue)<=1.01) {
                NSLog(@"_moveValue:%f",_moveValue);
                NSLog(@"newValue:%f",newValue);
                
                if(newValue+_moveValue>=1.0){
                    newValue = MIN(1.0 - _moveValue, newValue);
                }
                self.progressValue = 0;
                [self setLowerValue:newValue animated:_stepValueContinuously ? YES : NO];
                [self setUpperValue:newValue+_moveValue animated:_stepValueContinuously ? YES : NO];
                if([_delegate respondsToSelector:@selector(scrub:)]){
                    [_delegate scrub:self];
                }
            }
            
        }
        if(_isblockHandle){
            if(self.progressTrack.center.x >= self.lowerHandle.center.x && self.progressTrack.center.x <= self.upperHandle.center.x){
                
                float progress = touchPoint.x/(self.frame.size.width- _lowerHandle.frame.size.width - _upperHandle.frame.size.width);
                float lowerx = _lowerHandle.frame.origin.x/(self.frame.size.width- _lowerHandle.frame.size.width - _upperHandle.frame.size.width);
                
                //self.progressValue = progress*_durationValue - (progress1 * _durationValue);
                self.progressValue = progress*(_durationValue - (lowerx * _durationValue));
                [self progress:self.progressValue];
                _isblockHandle = YES;
                if(_handProgressTrackMove){
                    _handProgressTrackMove(_progressValue);
                }
            }
            return YES;
        }
        
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }else{
        if(!_handleLeft&& !_handleRight&& _isblockHandle && _mode){
            if(self.progressTrack.center.x >= self.lowerHandle.center.x && self.progressTrack.center.x <= self.upperHandle.center.x){
                
                float progress = touchPoint.x/(self.frame.size.width);//- _lowerHandle.frame.size.width - _upperHandle.frame.size.width
                //float progress1 = (self.lowerHandle.frame.origin.x + self.lowerHandle.frame.size.width/2.0)/(self.frame.size.width- _lowerHandle.frame.size.width - _upperHandle.frame.size.width);
                //self.progressValue = progress*_durationValue - (progress1 * _durationValue);
                //float lowerx = _lowerHandle.frame.origin.x/(self.frame.size.width- _lowerHandle.frame.size.width - _upperHandle.frame.size.width);
                self.progressValue = progress*(_durationValue);
                [self progress:self.progressValue];
                _isblockHandle = YES;
                if(_handProgressTrackMove){
                    _handProgressTrackMove(_progressValue);
                }
            }
            return YES;
        }
        if(_handleLeft && _mode)
        {
            float newValue = [self lowerValueForCenterX:(touchPoint.x - _lowerTouchOffset)];
            if(!_upperHandle.highlighted || newValue<_lowerValue)
            {
                _handleRight = NO;
                _upperHandle.highlighted=NO;
                [self bringSubviewToFront:_lowerHandle];
                
                [self setLowerValue:newValue animated:_stepValueContinuously ? YES : NO];
            }
            else
            {
                _handleLeft = NO;
                _lowerHandle.highlighted=NO;
            }
            _isblockHandle = NO;
            
            if([_delegate respondsToSelector:@selector(scrub:)]){
                [_delegate scrub:self];
            }
        }
        
        if(_handleRight && _mode)
        {
            float newValue = [self upperValueForCenterX:(touchPoint.x - _upperTouchOffset)];
            if(!_lowerHandle.highlighted || newValue>_upperValue)
            {
                _handleLeft = NO;
                _lowerHandle.highlighted=NO;
                self.progressValue = 0;
                [self bringSubviewToFront:_upperHandle];
                [self setUpperValue:newValue animated:_stepValueContinuously ? YES : NO];
                
            }
            else
            {
                
                _handleRight = NO;
                _upperHandle.highlighted=NO;
            }
            _isblockHandle = NO;
            if([_delegate respondsToSelector:@selector(scrub:)]){
                [_delegate scrub:self];
            }
        }
    }
    
    self.lowerHandle.image = self.lowerHandleImageNormal;
    self.upperHandle.image = self.upperHandleImageNormal;
    self.lowerHandle.highlightedImage = self.lowerHandleImageHighlighted;
    self.upperHandle.highlightedImage = self.upperHandleImageHighlighted;
    
    [self setNeedsLayout];
    
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (isCenter) {
        isCenter = NO;
        _isblockHandle = NO;
        self.progressTrack.hidden = NO;
    }
    if(_handleLeft){
        _upperHandle.highlighted = NO;
    }
    if(_handleRight){
        _lowerHandle.highlighted = NO;
    }
    _handleLeft = NO;
    _handleRight = NO;
    if(_stepValue>0)
    {
        _stepValueInternal=_stepValue;
        
        [self setLowerValue:_lowerValue animated:YES];
        [self setUpperValue:_upperValue animated:YES];
    }
    
    [self progress:MAX(self.progressValue, _lowerValue *_durationValue)];
    self.progressTrack.hidden = NO;
    _isblockHandle = NO;
    if([_delegate respondsToSelector:@selector(endScrub:)]){
        [_delegate endScrub:self];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)progress:(float)value{
    _progressValue = value;
    if(isnan(_durationValue)){
        return;
    }
    //_progressTrack.frame = [self progressTrackRect];
    
    float perw = (self.frame.size.width - self.upperHandle.frame.size.width - self.lowerHandle.frame.size.width)/_durationValue;
    
    float progressWidth = MIN(self.frame.size.width - self.upperHandle.frame.size.width - self.lowerHandle.frame.size.width, perw *value);
    
    CGRect rect = _progressTrack.frame;
    //float progressWidth = (self.frame.size.width - self.upperHandle.frame.size.width - self.lowerHandle.frame.size.width)/(float)_durationValue;
    rect.origin.x = progressWidth + self.lowerHandle.frame.size.width;
    //rect.origin.x = self.lowerHandle.frame.size.width + self.lowerHandle.frame.size.width*(_progressValue/_durationValue) + _progressValue * progressWidth;
    if (!_mode) {
        rect.origin.x = MIN(self.upperHandle.frame.origin.x+self.upperHandle.frame.size.width + self.lowerHandle.frame.size.width/2.0, _progressValue/_durationValue*self.frame.size.width) ;
    }
    _progressTrack.frame = rect;
    
    if(_progressTrack.frame.origin.x + _progressTrack.frame.size.width/2.0 > _upperHandle.frame.origin.x || _progressTrack.frame.origin.x< _lowerHandle.frame.origin.x + _lowerHandle.frame.size.width/2.0){
        
        //        if (_mode) {
        //            self.progressTrack.hidden = NO;
        //        }
        self.progressTrack.hidden = YES;
    }else{
        self.progressTrack.hidden = NO;
    }
    //NSLog(@"_progressValue:%f rect.x:%f rect.width:%f,self.frame.size.width:%f",_progressValue,rect.origin.x,rect.size.width,self.frame.size.width);
    [self setNeedsLayout];
}

- (void)cancelAllCGImageGeneration{
    NSLog(@"%s",__func__);
    [_imageGenerator cancelAllCGImageGeneration];
}

- (void)continueLoadThumb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        float tmpWidth = (self.frame.size.height/2.0);
        float actualFramesNeeded = ceilf(self.frame.size.width/tmpWidth);
        float durationPerFrame = _durationValue/actualFramesNeeded;
        for (; loadingIndex<actualFramesNeeded; loadingIndex++) {
            CMTime time = CMTimeMakeWithSeconds(0.01 + loadingIndex*durationPerFrame, TIMESCALE);
            //CMTime time = [[_thumbImageTimes objectAtIndex:i] CMTimeValue];
            NSError *error;
            CGImageRef imageRef =  [_imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
            
            UIImage *resultImage = [[UIImage alloc] initWithCGImage:imageRef];
            CGImageRelease(imageRef);
            dispatch_sync(dispatch_get_main_queue(), ^{
                //NSLog(@"%s:%d",__func__,i);
                UIImageView *tmpImageView = [trackBackground viewWithTag:(loadingIndex+1)];
                tmpImageView.contentMode = UIViewContentModeScaleAspectFill;
                tmpImageView.layer.masksToBounds = YES;
                if(resultImage){
                    tmpImageView.image = resultImage;
                }
                if(loadingIndex>=actualFramesNeeded-1){
                    _isloadFinishThumb = YES;
                    if (_delegate && [_delegate respondsToSelector:@selector(NMCutRangeSliderLoadThumbsCompletion)]) {
                        [_delegate NMCutRangeSliderLoadThumbsCompletion];
                    }
                }
            });
        }
    });
}

- (void)loadThumb{
    
    float tmpWidth = self.frame.size.height;
    float actualFramesNeeded = ceilf(self.frame.size.width/tmpWidth);
    float durationPerFrame = _durationValue/actualFramesNeeded;
    
    if( _imageGenerator )
    {
        _imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        _imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        
        //    NSMutableArray *_thumbImageTimes = [[NSMutableArray alloc] init];
        
        NSError *error;
        CGImageRef halfWayImage = [_imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(0.2, TIMESCALE) actualTime:NULL error:&error];
        //    UIImage *videoScreen;
        //    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
        //    CGImageRelease(halfWayImage);
        CacheImage = [[UIImage alloc] initWithCGImage:halfWayImage];
    }
    self.trackBackground.layer.masksToBounds = YES;
    for (int i=0; i<actualFramesNeeded; i++){
        UIImageView *tmpImageV = [[UIImageView alloc] initWithFrame:CGRectMake(i * tmpWidth, 0, tmpWidth, self.frame.size.height)];
        tmpImageV.tag = i+1;
        tmpImageV.image = CacheImage;
        tmpImageV.contentMode = UIViewContentModeScaleAspectFill;
        tmpImageV.layer.masksToBounds = YES;
        [self.trackBackground addSubview:tmpImageV];
    }
    
    NSLog(@"actualFramesNeeded:%f",actualFramesNeeded);

    if( !_imageGenerator )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *thumbImageTimes = [[NSMutableArray alloc] init];
            for (int i=0; i < actualFramesNeeded; i++){
                float fTime = 0.2 + i*durationPerFrame;
                if( fTime >= _durationValue )
                {
                    fTime = _durationValue - 0.2;
                }
                int number = ceilf(fTime);
                NSString * strPatch = [_filtImagePatch stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png",number]];
                
                UIImage* videoScreen = [RDHelpClass getThumbImageWithUrl: [NSURL fileURLWithPath:strPatch]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView *tmpImageView = [trackBackground viewWithTag:i+1];
                    tmpImageView.contentMode = UIViewContentModeScaleAspectFill;
                    tmpImageView.layer.masksToBounds = YES;
                    tmpImageView.image = videoScreen;
                });
            }
        });
        return;
    }
    else
    {
#if 1
        _isloadFinishThumb = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *thumbImageTimes = [[NSMutableArray alloc] init];
            for (int i=0; i < actualFramesNeeded; i++){
                float fTime = 0.2 + i*durationPerFrame;
                if( fTime >= _durationValue )
                {
                    fTime = _durationValue - 0.2;
                }
                CMTime time = CMTimeMakeWithSeconds(fTime, TIMESCALE);
                [thumbImageTimes addObject:[ NSValue valueWithCMTime:time] ];
            }
            
            if( _videoCoreSDK )
            {
                //2019 11 26 Core截取
                [_videoCoreSDK getImageWithTimes:[thumbImageTimes mutableCopy] scale:0.1 completionHandler:^(UIImage *image, NSInteger idx) {
                    if(!image){
                        return;
                    }
                    //                dispatch_sync(dispatch_get_main_queue(), ^{
                    UIImageView *tmpImageView = [trackBackground viewWithTag:idx+1];
                    tmpImageView.contentMode = UIViewContentModeScaleAspectFill;
                    tmpImageView.layer.masksToBounds = YES;
                    tmpImageView.image = image;
                    //                });
                }];
            }
            else{
                // 2019 11 26 系统截取 会出现黑帧情况?
                __block int index = 0;
                [_imageGenerator generateCGImagesAsynchronouslyForTimes:thumbImageTimes
                                                      completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,
                                                                          AVAssetImageGeneratorResult result, NSError *error) {
                    NSString *requestedTimeString = (NSString *)
                    CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
                    //NSString *actualTimeString = (NSString *)
                    //CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
                    
                    
                    NSLog(@"requestedTimeString=:%@",requestedTimeString);
                    
                    NSRange range = [requestedTimeString rangeOfString:@"="];
                    requestedTimeString = [requestedTimeString substringFromIndex:range.length + range.location];
                    
                    range = [requestedTimeString rangeOfString:@","];
                    if(range.location != NSNotFound){
                        requestedTimeString = [requestedTimeString substringToIndex:range.location];
                        
                        index++;
                        
                        //                                                      int index = ceilf([requestedTimeString floatValue])/durationPerFrame;
                        NSLog(@"%d",index);
                        if(index > [thumbImageTimes count]){
                            _isloadFinishThumb = YES;
                        }
                        if (result == AVAssetImageGeneratorSucceeded) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                
                                UIImageView *tmpImageView = [trackBackground viewWithTag:index];
                                tmpImageView.contentMode = UIViewContentModeScaleAspectFill;
                                tmpImageView.layer.masksToBounds = YES;
                                UIImage* videoScreen = [UIImage imageWithCGImage: image];
                                //                                                              CGImagerelease(image);
                                
                                if(videoScreen){
                                    tmpImageView.image = videoScreen;
                                }
                                else
                                {
                                    if( index  != 1 )
                                        tmpImageView.image =  ((UIImageView *)[trackBackground viewWithTag:index-1]).image;
                                    else
                                        tmpImageView.image = CacheImage;
                                }
                                
                            });
                        }
                        
                        if (result == AVAssetImageGeneratorFailed) {
                            NSLog(@"Failed with error: %@", [error localizedDescription]);
                        }
                        if (result == AVAssetImageGeneratorCancelled) {
                            NSLog(@"Canceled");
                        }
                    }
                }];
            }
        });
    }
    
#else
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (loadingIndex = 1; loadingIndex<actualFramesNeeded; loadingIndex++) {
                CMTime time = CMTimeMakeWithSeconds(0.01 + loadingIndex*durationPerFrame, TIMESCALE);
                //CMTime time = [[_thumbImageTimes objectAtIndex:i] CMTimeValue];
                NSError *error;
                CGImageRef imageRef =  [_imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
                
                UIImage *resultImage = [[UIImage alloc] initWithCGImage:imageRef];
                CGImageRelease(imageRef);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    //NSLog(@"%s:%d",__func__,i);
                    UIImageView *tmpImageView = [trackBackground viewWithTag:(loadingIndex+1)];
                    tmpImageView.contentMode = UIViewContentModeScaleAspectFill;
                    tmpImageView.layer.masksToBounds = YES;
                    if(resultImage){
                        tmpImageView.image = resultImage;
                    }
                    if(loadingIndex>=actualFramesNeeded-1){
    //                    _imageGenerator = nil;
                        _isloadFinishThumb = YES;
                        if (_delegate && [_delegate respondsToSelector:@selector(NMCutRangeSliderLoadThumbsCompletion)]) {
                            [_delegate NMCutRangeSliderLoadThumbsCompletion];
                        }
                    }
                });
            }
         });
#endif
}
- (void)dealloc{
    
    [trackBackground.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
            [obj removeFromSuperview];
            //            obj = nil;
        }
        
    }];
    _imageGenerator = nil;
    [_lowerHandle removeFromSuperview];
    [_upperHandle removeFromSuperview];
    _handProgressTrackMove = nil;
    [_progressTrack removeFromSuperview];
    NSLog(@"%s",__func__);
}
@end
