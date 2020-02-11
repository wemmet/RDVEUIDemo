//
//  RangeSlider.m
//  RangeSlider
//
//  Created by Murray Hughes on 04/08/2012
//  Copyright 2011 Null Monkey Pty Ltd. All rights reserved.
//

#import "MusicRangeSlider_RD.h"
#import "RDHelpClass.h"
@interface MusicRangeSlider_RD ()
{
    float _lowerTouchOffset;
    float _upperTouchOffset;
    float _stepValueInternal;
    BOOL  _haveAddedSubviews;
    float _lowerValue;
    float _lastTouchPoint_x;
}

@property (strong, nonatomic) UIImageView* trackBackground;

@end

@implementation MusicRangeSlider_RD

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

- (void) setLowerValue:(float) lowerValue upperValue:(float) upperValue animated:(BOOL)animated
{
    if((!animated) && (isnan(lowerValue)) && (isnan(upperValue)))
    {
        //nothing to set
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
        [self layoutSubviews];
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

    return _lowerHandleImageNormal;
}

- (UIImage *)lowerHandleImageHighlighted
{
  
    return _lowerHandleImageHighlighted;
}

- (UIImage *)upperHandleImageNormal
{
    return _upperHandleImageNormal;
}

- (UIImage *)upperHandleImageHighlighted
{
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
    float value = _minimumValue + (x-_padding) / (self.frame.size.width- 15 -(_padding*2)) * (_maximumValue - _minimumValue);
    
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
    
    float value = _minimumValue + (x-_padding) / (self.frame.size.width- 15 -(_padding*2)) * (_maximumValue - _minimumValue);
    
    value = MIN(value, _maximumValue);
    value = MAX(value, _lowerValue+_minimumRange);
    _upperValue = value;
    return value;
}

//returns the rect for the track image between the lower and upper values based on the trackimage object
- (CGRect)trackRect
{
    CGRect retValue;
    
    retValue.size = CGSizeMake(_trackImage.size.width, 3.0);
    
    if(_trackImage.capInsets.top || _trackImage.capInsets.bottom)
    {
        retValue.size.height=3.0;
    }
    
    float xLowerValue = _lowerHandle.frame.origin.x + _lowerHandle.frame.size.width;
    float xUpperValue = _upperHandle.frame.origin.x;
    
     retValue.origin = CGPointMake(xLowerValue, (self.bounds.size.height - 3.0)/2.0);
    retValue.size.width = xUpperValue-xLowerValue;
    
    return retValue;
}

//returns the rect for the track image between the lower and upper values based on the trackimage object
- (CGRect)progressTrackRect
{
    CGRect retValue;
    if(!_progressTrackImage){
        _progressTrackImage = [RDHelpClass imageWithContentOfFile:@"slider-default-handle"];
    }
    retValue.size = CGSizeMake(_progressTrackImage.size.width, 3.0);
    
    if(_progressTrackImage.capInsets.top || _progressTrackImage.capInsets.bottom)
    {
        retValue.size.height = 3.0;
    }
    
    retValue.origin = CGPointMake(self.track.frame.origin.x, (self.bounds.size.height - 3.0)/2.0);
    if(_progressValue>0){
        retValue.size.width = _progressValue*(self.frame.size.width + 10)/_durationValue;

    }else{
        retValue.size.width = 0;

    }
    
    return retValue;
}

//returns the rect for the background image
-(CGRect) trackBackgroundRect
{
    CGRect trackBackgroundRect;
    
    trackBackgroundRect.size = CGSizeMake(_trackBackgroundImage.size.width-_lowerHandle.frame.size.width*2.0, 3.0);
    
    if(_trackBackgroundImage.capInsets.top || _trackBackgroundImage.capInsets.bottom)
    {
        trackBackgroundRect.size.height = 3.0;
    }
    
    if(_trackBackgroundImage.capInsets.left || _trackBackgroundImage.capInsets.right)
    {
        trackBackgroundRect.size.width=self.bounds.size.width-_lowerHandle.frame.size.width*2.0;
    }
    
//    trackBackgroundRect.origin = CGPointMake(14, (self.bounds.size.height/2.0f) - (trackBackgroundRect.size.height/2.0f)-5);
    trackBackgroundRect.origin = CGPointMake(_lowerHandle.frame.size.width, (self.bounds.size.height - 3.0)/2.0);
    
    return trackBackgroundRect ;
}

//returms the rect of the tumb image for a given track rect and value
- (CGRect)thumbRectForValue:(float)value image:(UIImage*) thumbImage
{
    CGRect thumbRect;
    UIEdgeInsets insets = thumbImage.capInsets;
    
    thumbRect.size = CGSizeMake(thumbImage.size.width, thumbImage.size.height);
    
    if(insets.top || insets.bottom)
    {
        thumbRect.size.height=self.bounds.size.height;
    }
    
    float xValue = MIN(MAX(((self.bounds.size.width-thumbRect.size.width)*((value - _minimumValue) / (_maximumValue - _minimumValue))), 0), self.frame.size.width - _upperHandle.frame.size.width);
    thumbRect.origin = CGPointMake(xValue, 0);//(self.bounds.size.height/2.0f) - (thumbRect.size.height/2.0f)
    
    return thumbRect;
    
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Layout


- (void) addSubviews
{
    
    // Lower Handle Handle
    self.lowerHandle = [[UIImageView alloc] initWithImage:self.lowerHandleImageNormal highlightedImage:self.lowerHandleImageHighlighted];
    
    self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal];
    
    //------------------------------
    // Upper Handle Handle
    self.upperHandle = [[UIImageView alloc] initWithImage:self.upperHandleImageNormal highlightedImage:self.upperHandleImageHighlighted];
    self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal];
    

    //------------------------------
    // Track Brackground
    self.trackBackground = [[UIImageView alloc] initWithImage:self.trackBackgroundImage];
    self.trackBackground.frame = [self trackBackgroundRect];
    
    //------------------------------
    // Track
    self.track = [[UIImageView alloc] initWithImage:self.trackImage];
    self.track.frame = [self trackRect];
    self.track.backgroundColor = [UIColor greenColor];
    self.track.layer.cornerRadius = 0;
    self.track.layer.masksToBounds = YES;
    
    //------------------------------
    //progressTrack
    self.progressTrack = [[UIImageView alloc] initWithImage:self.progressTrackImage];
    //self.progressTrack.frame = [self progressTrackRect];
    
    //------------------------------
    [self addSubview:self.trackBackground];
    [self addSubview:self.track];
    [self addSubview:self.progressTrack];
    [self addSubview:self.lowerHandle];
    [self addSubview:self.upperHandle];
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
    self.progressTrack.frame = [self progressTrackRect];
    if(!_handleRight)
        self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal];
    if(!_handleLeft)
        self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal];
    self.lowerHandle.image = [self lowerHandleImageNormal];
    self.upperHandle.image = [self  upperHandleImageNormal];
    self.lowerHandle.highlightedImage = self.lowerHandleImageHighlighted;
    self.upperHandle.highlightedImage = self.upperHandleImageHighlighted;
    float width = self.upperHandle.frame.origin.x-self.lowerHandle.frame.origin.x;
    self.track.backgroundColor = [UIColor blackColor];
    
    
    if (width<16) {
        CGRect frameLower=[self.lowerHandle frame];
        CGRect frameUpper=[self.upperHandle frame];
        if(_handleLeft){
            frameLower.origin.x = MIN(frameLower.origin.x, frameUpper.origin.x - frameLower.size.width-5);
            self.lowerHandle.frame = frameLower;
        }
        
        if(_handleRight){
            frameUpper.origin.x = MAX(frameLower.origin.x + frameLower.size.width+5, frameUpper.origin.x);
            self.upperHandle.frame = frameUpper;
        }
        
    }
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Touch handling

// The handle size can be a little small, so i make it a little bigger
// TODO: Do it the correct way. I think wwdc 2012 had a video on it...
- (CGRect) touchRectForHandle:(UIImageView*) handleImageView
{
    float xPadding = 10;
    float yPadding = 40; //(self.bounds.size.height-touchRect.size.height)/2.0f
    
    CGRect touchRect = handleImageView.frame;
    touchRect.origin.x -= xPadding/2.0;
    touchRect.origin.y -= yPadding/2.0;
    touchRect.size.height += xPadding/1.0;
    touchRect.size.width += yPadding;
    return touchRect;
}

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    
    
    //Check both buttons upper and lower thumb handles because
    //they could be on top of each other.
    
    if(CGRectContainsPoint([self touchRectForHandle:_lowerHandle], touchPoint))
    {
        _handleLeft = YES;
        _handleRight = NO;
        _lowerHandle.highlighted = YES;
        _upperHandle.highlighted = NO;
        _lowerTouchOffset = touchPoint.x - _lowerHandle.center.x;
    }
    if(CGRectContainsPoint([self touchRectForHandle:_upperHandle], touchPoint))
    {
        _handleRight = YES;
        _handleLeft = NO;
        _lowerHandle.highlighted = NO;
        _upperHandle.highlighted = YES;
        _upperTouchOffset = touchPoint.x - _upperHandle.center.x;
    }
    
    _stepValueInternal= _stepValueContinuously ? _stepValue : 0.0f;
    
    return YES;
}


-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#if 1
    CGPoint touchPoint = [touch locationInView:self];

    if(_handleLeft){
        NSLog(@"touchPoint.x:%f",touchPoint.x);
        CGPoint center = _lowerHandle.center;
        center.x = MIN(MAX(touchPoint.x, _lowerHandle.frame.size.width), _upperHandle.frame.origin.x - _lowerHandle.frame.size.width);
        _lowerHandle.center = center;
        
        _lowerValue = _lowerHandle.frame.origin.x /(self.frame.size.width - _upperHandle.frame.size.width);
    }
    
    if(_handleRight){
        NSLog(@"touchPoint.x:%f",touchPoint.x);
        CGPoint center = _upperHandle.center;
        center.x = MAX(MIN(touchPoint.x, self.frame.size.width), _lowerHandle.frame.origin.x + _lowerHandle.frame.size.width + _upperHandle.frame.size.width);
        _upperHandle.center = center;
        
        _upperValue = _upperHandle.frame.origin.x /(self.frame.size.width - _upperHandle.frame.size.width);
    }
#else
    
    if(!_lowerHandle.highlighted && !_upperHandle.highlighted ){
        return YES;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    if(_lowerHandle.highlighted)
    {
        //get new lower value based on the touch location.
        //This is automatically contained within a valid range.
        
        if(touchPoint.x>_lowerHandle.center.x){
            
            if(touchPoint.x >_upperHandle.center.x - _upperHandle.frame.size.width){
                
                return YES;
            }
        }
        else{
            if(touchPoint.x >_upperHandle.center.x - _upperHandle.frame.size.width*3/2){
                
                return YES;
            }
        }
        
        float newValue = [self lowerValueForCenterX:(touchPoint.x - _lowerTouchOffset)];
        
        //if both upper and lower is selected, then the new value must be LOWER
        //otherwise the touch event is ignored.
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
    }
    
    if(_upperHandle.highlighted )
    {
        if(touchPoint.x > _upperHandle.center.x){
            if(touchPoint.x < _lowerHandle.center.x + _lowerHandle.frame.size.width*3/2){
                return YES;
            }
        }else{
            if(touchPoint.x <_lowerHandle.center.x + _lowerHandle.frame.size.width){
                return YES;
            }
        }
        
        float newValue = [self upperValueForCenterX:(touchPoint.x - _upperTouchOffset)];
        
        //if both upper and lower is selected, then the new value must be HIGHER
        //otherwise the touch event is ignored.
        if(!_lowerHandle.highlighted || newValue>_upperValue)
        {
            _handleLeft = NO;
            _lowerHandle.highlighted=NO;
            [self bringSubviewToFront:_upperHandle];
            [self setUpperValue:newValue animated:_stepValueContinuously ? YES : NO];
        }
        else
        {
            _handleRight = NO;
            _upperHandle.highlighted=NO;
        }
    }
    
#endif
    
    
    //send the control event
    if(_continuous)
    {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    self.track.frame = [self trackRect];
    self.progressTrack.frame = [self progressTrackRect];
    if(!_handleRight)
        self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal];
    if(!_handleLeft)
        self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal];
    
    self.lowerHandle.image = self.lowerHandleImageNormal;
    self.upperHandle.image = self.upperHandleImageNormal;
    self.lowerHandle.highlightedImage = self.lowerHandleImageHighlighted;
    self.upperHandle.highlightedImage = self.upperHandleImageHighlighted;
    
    //redraw
//    [self setNeedsLayout];
    
    return YES;
}



-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _lowerHandle.highlighted = NO;
    _upperHandle.highlighted = NO;
    _handleLeft = NO;
    _handleRight = NO;
    if(_stepValue>0)
    {
        _stepValueInternal=_stepValue;
        [self setLowerValue:_lowerValue animated:YES];
        [self setUpperValue:_upperValue animated:YES];
        
    }
    
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)progress:(float)value{
    _progressValue = value;
    if(_progressValue>0<=_durationValue)
    self.progressTrack.frame = [self progressTrackRect];
}
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
