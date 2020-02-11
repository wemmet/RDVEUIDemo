//
//  RDTTRangeSlider.m
//
//  Created by Tom Thorpe

#import "RDTTRangeSlider.h"
#import "RDHelpClass.h"
//原始 -30
const int RD_HANDLE_TOUCH_AREA_EXPANSION = -30; //expand the touch area of the handle by this much (negative values increase size) so that you don't have to touch right on the handle to activate it.
const float RD_HANDLE_DIAMETER = 20;
const float RD_TEXT_HEIGHT = 14;

@interface RDTTRangeSlider (){
    bool  isUpdateSlider;
    
    CGPoint _startCenter;
    CGPoint _startCenter_leftHandle;
    CGPoint _startCenter_rightHandle;
    
    BOOL    isFristTracking;
    float   fTrackingX;
    
    bool isCollageSilder;
}

@property (nonatomic, strong) CALayer *sliderLine;

@property (nonatomic, strong) CATextLayer *minLabel;
@property (nonatomic, strong) CATextLayer *maxLabel;

@property (nonatomic, strong) NSNumberFormatter *decimalNumberFormatter; // Used to format values if formatType is YLRangeSliderFormatTypeDecimal

@end

static const CGFloat kLabelsFontSize = 12.0f;

@implementation RDTTRangeSlider

//do all the setup in a common place, as there can be two initialisers called depending on if storyboards or code are used. The designated initialiser isn't always called :|
- (void)initialiseControl {
    //defaults:
    _minValue = 0;
    _selectedMinimum = 10;
    _maxValue = 100;
    _selectedMaximum  = 90;

    _minDistance = -1;
    _maxDistance = -1;

    _enableStep = NO;
    _step = 0.1f;
    
    isFristTracking = true;
    //draw the slider line
    self.sliderLine = [CALayer layer];
    self.sliderLine.backgroundColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:self.sliderLine];
    
    _holdDragRecognizer = [[RDDragGestureRecognizer alloc] init];
    [_holdDragRecognizer addTarget:self action:@selector(dragRecognized:)];
    
    _moveCaptionViewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _moveCaptionViewBtn.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite:0.0 alpha:0.8];//test
    [_moveCaptionViewBtn addGestureRecognizer:_holdDragRecognizer];
    _moveCaptionViewBtn.hidden = YES;
    [self addSubview:_moveCaptionViewBtn];

    //draw the minimum slider handle
    self.leftHandle = [CALayer layer];
    self.leftHandle.cornerRadius = 2.0f;
//    self.leftHandle.backgroundColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:self.leftHandle];

    //draw the maximum slider handle
    self.rightHandle = [CALayer layer];
    self.rightHandle.cornerRadius = 2.0f;
//    self.rightHandle.backgroundColor = [UIColor whiteColor].CGColor;
    
    [self.layer addSublayer:self.rightHandle];

    self.leftHandle.frame = CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height);
    self.rightHandle.frame = CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height);
    _leftLabel = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height)];
    _leftLabel.image =  [RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"];
    [self addSubview:_leftLabel];
    _leftLabel.hidden = YES;
    _rightLabel = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height)];
    _rightLabel.image =  [RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"];
    [self addSubview:_rightLabel];
    _rightLabel.hidden = YES;
    
    _leftLayer = [CALayer layer];
    _leftLayer.backgroundColor = [UIColor clearColor].CGColor;
//    leftLayer.frame = self.leftHandle.bounds;
    _leftLayer.frame = CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height);
//    leftLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-特效拖动左默认_"].CGImage;
    _leftLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"].CGImage;
    _leftLayer.hidden = YES;
    
    _leftHightedLayer = [CALayer layer];
    _leftHightedLayer.backgroundColor = [UIColor clearColor].CGColor;
//    leftHightedLayer.frame = self.leftHandle.bounds;
    _leftHightedLayer.frame = CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height);
    _leftHightedLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"].CGImage;
//    leftHightedLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-特效拖动左选中_"].CGImage;
    _leftHightedLayer.hidden = YES;
    [self.leftHandle addSublayer:_leftLayer];
    
    _rightLayer = [CALayer layer];
    _rightLayer.backgroundColor = [UIColor clearColor].CGColor;
    _rightLayer.frame = self.rightHandle.bounds;
    _rightLayer.frame = CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height);
    _rightLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"].CGImage;
    _rightLayer.hidden = YES;
//    rightLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-特效拖动右默认_"].CGImage;
    
    _rightHightedLayer = [CALayer layer];
    _rightHightedLayer.backgroundColor = [UIColor clearColor].CGColor;
//    rightHightedLayer.frame = self.rightHandle.bounds;
    _rightHightedLayer.frame = CGRectMake(0, 0, RD_HANDLE_DIAMETER, self.frame.size.height);
//    rightHightedLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-特效拖动右选中_"].CGImage;
    _rightHightedLayer.contents = (id)[RDHelpClass imageWithContentOfFile:@"jianji/jiequ/剪辑-截取_把手选中_"].CGImage;
    _rightHightedLayer.hidden = YES;
    [self.rightHandle addSublayer:_rightLayer];
    
    //draw the text labels
    self.minLabel = [[CATextLayer alloc] init];
    self.minLabel.alignmentMode = kCAAlignmentCenter;
    self.minLabel.fontSize = kLabelsFontSize;
    self.minLabel.frame = CGRectMake(0, 0, 75, RD_TEXT_HEIGHT);
    self.minLabel.contentsScale = [UIScreen mainScreen].scale;
    self.minLabel.contentsScale = [UIScreen mainScreen].scale;
    if (self.minLabelColour == nil){
        self.minLabel.foregroundColor = self.tintColor.CGColor;
    } else {
        self.minLabel.foregroundColor = self.minLabelColour.CGColor;
    }
    [self.layer addSublayer:self.minLabel];

    self.maxLabel = [[CATextLayer alloc] init];
    self.maxLabel.alignmentMode = kCAAlignmentCenter;
    self.maxLabel.fontSize = kLabelsFontSize;
    self.maxLabel.frame = CGRectMake(0, 0, 75, RD_TEXT_HEIGHT);
    self.maxLabel.contentsScale = [UIScreen mainScreen].scale;
    if (self.maxLabelColour == nil){
        self.maxLabel.foregroundColor = self.tintColor.CGColor;
    } else {
        self.maxLabel.foregroundColor = self.maxLabelColour.CGColor;
    }
    [self.layer addSublayer:self.maxLabel];

    [self refresh];
}

- (void)dragRecognized:(RDDragGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            // When the gesture starts, remember the current position, and animate the it.
            _startCenter = _moveCaptionViewBtn.center;
            _startCenter_leftHandle = _leftHandle.position;
            _startCenter_rightHandle = _rightHandle.position;
            
            if(_delegate){
                if([_delegate respondsToSelector:@selector(startMove)]){
                    [_delegate startMove];
                }
            }
            
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            // During the gesture, we just add the gesture's translation to the saved original position.
            // The translation will account for the changes in contentOffset caused by auto-scrolling.
            CGPoint translation = [recognizer translationInView:self];
            CGPoint center = CGPointMake(_startCenter.x + translation.x, _startCenter.y);
            
            CGSize locationSize = [_delegate getLeftPointAndRightPoint];
            if ((center.x >= _moveCaptionViewBtn.frame.size.width/2.0 + 36)
                && (center.x <= (locationSize.height + 16 - _moveCaptionViewBtn.frame.size.width/2.0 - 5/2.0))) {
                _moveCaptionViewBtn.center = center;
                
                float percentage_left = ((_startCenter_leftHandle.x + translation.x - CGRectGetMinX(self.sliderLine.frame)) - RD_HANDLE_DIAMETER/2) / (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));
                float percentage_right = ((_startCenter_rightHandle.x + translation.x - CGRectGetMinX(self.sliderLine.frame)) - RD_HANDLE_DIAMETER/2) / (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));
                
                _selectedMinimum = percentage_left * (self.maxValue - self.minValue) + self.minValue;
                _selectedMaximum = percentage_right * (self.maxValue - self.minValue) + self.minValue;
                if (_selectedMinimum < 0) {
                    _selectedMaximum -= _selectedMinimum;
                    _selectedMinimum = 0;
                }
                [CATransaction begin];
                [CATransaction setDisableActions:YES] ;
                [self updateHandlePositions];
                [self updateLabelPositions];
                [CATransaction commit];
                [self updateLabelValues];
                
                if(_delegate){
                    if ([_delegate respondsToSelector:@selector(rangeSlider:didChangeSelectedMinimumValue:andMaximumValue:isRight:)]){
                        [_delegate rangeSlider:self didChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum isRight:(self.leftHandleSelected)?false:true];
                    }
                }
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if(_delegate){
                if([_delegate respondsToSelector:@selector(rangeSlider:didEndChangeSelectedMinimumValue:andMaximumValue:)]){
                    [_delegate rangeSlider:self didEndChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum];
                }
                if([_delegate respondsToSelector:@selector(stopMove)]){
                    [_delegate stopMove];
                }
            }
            break;
            
        default:
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    //positioning for the slider line
    float barSidePadding = 16.0f;
    CGRect currentFrame = self.frame;
    float yMiddle = currentFrame.size.height/2.0;
    CGPoint lineLeftSide = CGPointMake(barSidePadding, yMiddle);
    CGPoint lineRightSide = CGPointMake(currentFrame.size.width-barSidePadding, yMiddle);
    self.sliderLine.frame = CGRectMake(lineLeftSide.x, 0, lineRightSide.x-lineLeftSide.x, self.frame.size.height);

    [self updateHandlePositions];
    [self updateLabelPositions];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if(self)
    {
        [self initialiseControl];
    }
    return self;
}

-  (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];

    if (self)
    {
        [self initialiseControl];
    }

    return self;
}

- (CGSize)intrinsicContentSize{
    return CGSizeMake(UIViewNoIntrinsicMetric, 65);
}


- (float)getPercentageAlongLineForValue:(float) value {
    if (self.minValue == self.maxValue){
        return 0; //stops divide by zero errors where maxMinDif would be zero. If the min and max are the same the percentage has no point.
    }

    //get the difference between the maximum and minimum values (e.g if max was 100, and min was 50, difference is 50)
    float maxMinDif = self.maxValue - self.minValue;

    //now subtract value from the minValue (e.g if value is 75, then 75-50 = 25)
    float valueSubtracted = value - self.minValue;

    //now divide valueSubtracted by maxMinDif to get the percentage (e.g 25/50 = 0.5)
    return valueSubtracted / maxMinDif;
}

- (float)getXPositionAlongLineForValue:(float) value {
    //first get the percentage along the line for the value
    float percentage = [self getPercentageAlongLineForValue:value];

    //get the difference between the maximum and minimum coordinate position x values (e.g if max was x = 310, and min was x=10, difference is 300)
    float maxMinDif = CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame);

    //now multiply the percentage by the minMaxDif to see how far along the line the point should be, and add it onto the minimum x position.
    float offset = percentage * maxMinDif;

    return CGRectGetMinX(self.sliderLine.frame) + offset;
}

- (void)updateLabelValues {
    if ([self.numberFormatterOverride isEqual:[NSNull null]]){
        self.minLabel.string = @"";
        self.maxLabel.string = @"";
        return;
    }

    NSNumberFormatter *formatter = (self.numberFormatterOverride != nil) ? self.numberFormatterOverride : self.decimalNumberFormatter;

    self.minLabel.string = [formatter stringFromNumber:@(self.selectedMinimum)];
    self.maxLabel.string = [formatter stringFromNumber:@(self.selectedMaximum)];
}

#pragma mark - Set Positions
- (void)updateHandlePositions {
    @try {
        CGPoint leftHandleCenter = CGPointMake([self getXPositionAlongLineForValue:self.selectedMinimum] - 9, CGRectGetMidY(self.sliderLine.frame));
        if (leftHandleCenter.x<0) {
            leftHandleCenter.x = 0;
        }
        if(isnan(leftHandleCenter.x)){
            leftHandleCenter.x = 0;
        }
        self.leftHandle.position = leftHandleCenter;
        self.leftLabel.frame = CGRectMake(leftHandleCenter.x - 9, 0, self.leftLabel.frame.size.width, self.leftLabel.frame.size.height);
        CGPoint rightHandleCenter = CGPointMake([self getXPositionAlongLineForValue:self.selectedMaximum] + 9 , CGRectGetMidY(self.sliderLine.frame));
        if(isnan(rightHandleCenter.x) || rightHandleCenter.x < 0){
            rightHandleCenter.x = 0;
        }
        self.rightHandle.position= rightHandleCenter;
        self.rightLabel.frame = CGRectMake(rightHandleCenter.x - 10, 0, self.rightLabel.frame.size.width, self.rightLabel.frame.size.height);
    }
    @catch (NSException *exception) {
        
    }
    
}

- (void)updateLabelPositions {
    //the centre points for the labels are X = the same x position as the relevant handle. Y = the y position of the handle minus half the height of the text label, minus some padding.
    int padding = 8;
    float minSpacingBetweenLabels = 8.0f;

    CGPoint leftHandleCentre = [self getCentreOfRect:self.leftHandle.frame];
    CGPoint newMinLabelCenter = CGPointMake(leftHandleCentre.x, self.leftHandle.frame.origin.y - (self.minLabel.frame.size.height/2) - padding);

    CGPoint rightHandleCentre = [self getCentreOfRect:self.rightHandle.frame];
    CGPoint newMaxLabelCenter = CGPointMake(rightHandleCentre.x, self.rightHandle.frame.origin.y - (self.maxLabel.frame.size.height/2) - padding);

    CGSize minLabelTextSize = [self.minLabel.string sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:kLabelsFontSize]}];
    CGSize maxLabelTextSize = [self.maxLabel.string sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:kLabelsFontSize]}];

    float newLeftMostXInMaxLabel = newMaxLabelCenter.x - maxLabelTextSize.width/2;
    float newRightMostXInMinLabel = newMinLabelCenter.x + minLabelTextSize.width/2;
    float newSpacingBetweenTextLabels = newLeftMostXInMaxLabel - newRightMostXInMinLabel;

    if (self.disableRange || newSpacingBetweenTextLabels > minSpacingBetweenLabels) {
        self.minLabel.position = newMinLabelCenter;
        self.maxLabel.position = newMaxLabelCenter;
    }
    else {
        newMinLabelCenter = CGPointMake(self.minLabel.position.x, self.leftHandle.frame.origin.y - (self.minLabel.frame.size.height/2) - padding);
        newMaxLabelCenter = CGPointMake(self.maxLabel.position.x, self.rightHandle.frame.origin.y - (self.maxLabel.frame.size.height/2) - padding);
        self.minLabel.position = newMinLabelCenter;
        self.maxLabel.position = newMaxLabelCenter;

        //Update x if they are still in the original position
        if (self.minLabel.position.x == self.maxLabel.position.x && self.leftHandle != nil) {
            self.minLabel.position = CGPointMake(leftHandleCentre.x, self.minLabel.position.y);
            self.maxLabel.position = CGPointMake(leftHandleCentre.x + self.minLabel.frame.size.width/2 + minSpacingBetweenLabels + self.maxLabel.frame.size.width/2, self.maxLabel.position.y);
        }
    }
}

#pragma mark - Touch Tracking
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint gesturePressLocation = [touch locationInView:self];

    if (CGRectContainsPoint(CGRectInset(self.leftHandle.frame, RD_HANDLE_TOUCH_AREA_EXPANSION, RD_HANDLE_TOUCH_AREA_EXPANSION), gesturePressLocation) || CGRectContainsPoint(CGRectInset(self.rightHandle.frame, RD_HANDLE_TOUCH_AREA_EXPANSION, RD_HANDLE_TOUCH_AREA_EXPANSION), gesturePressLocation))
    {
        //the touch was inside one of the handles so we're definitely going to start movign one of them. But the handles might be quite close to each other, so now we need to find out which handle the touch was closest too, and activate that one.
        float distanceFromLeftHandle = [self distanceBetweenPoint:gesturePressLocation andPoint:[self getCentreOfRect:self.leftHandle.frame]];
        float distanceFromRightHandle =[self distanceBetweenPoint:gesturePressLocation andPoint:[self getCentreOfRect:self.rightHandle.frame]];

        if (distanceFromLeftHandle < distanceFromRightHandle && !self.disableRange){
            self.leftHandleSelected = YES;
            
            [_rightHightedLayer removeFromSuperlayer];
            [self.rightHandle addSublayer:_rightLayer];
            [_leftLayer removeFromSuperlayer];
            [self.leftHandle addSublayer:_leftHightedLayer];
            
            [self animateHandle:self.leftHandle withSelection:NO];
        } else {
            if (self.selectedMaximum == self.maxValue && [self getCentreOfRect:self.leftHandle.frame].x == [self getCentreOfRect:self.rightHandle.frame].x) {
                self.leftHandleSelected = YES;
                
                [_rightHightedLayer removeFromSuperlayer];
                [self.rightHandle addSublayer:_rightLayer];
                [_leftLayer removeFromSuperlayer];
                [self.leftHandle addSublayer:_leftHightedLayer];
                [self animateHandle:self.leftHandle withSelection:NO];
            }
            else {
                self.rightHandleSelected = YES;
                
                [_leftHightedLayer removeFromSuperlayer];
                [self.leftHandle addSublayer:_leftLayer];
                [_rightLayer removeFromSuperlayer];
                [self.rightHandle addSublayer:_rightHightedLayer];
                [self animateHandle:self.rightHandle withSelection:NO];
            }
        }
        if(_delegate){
            if([_delegate respondsToSelector:@selector(startMove)]){
                [_delegate startMove];
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)refresh {

    if (self.enableStep && self.step>=0.0f){
        _selectedMinimum = roundf(self.selectedMinimum/self.step)*self.step;
        _selectedMaximum = roundf(self.selectedMaximum/self.step)*self.step;
    }

    float diff = self.selectedMaximum - self.selectedMinimum;

    if (self.minDistance != -1 && diff < self.minDistance) {
        if(self.leftHandleSelected){
            _selectedMinimum = self.selectedMaximum - self.minDistance;
        }else{
            _selectedMaximum = self.selectedMinimum + self.minDistance;
        }
    }else if(self.maxDistance != -1 && diff > self.maxDistance){

        if(self.leftHandleSelected){
            _selectedMinimum = self.selectedMaximum - self.maxDistance;
        }else if(self.rightHandleSelected){
            _selectedMaximum = self.selectedMinimum + self.maxDistance;
        }
    }

    //ensure the minimum and maximum selected values are within range. Access the values directly so we don't cause this refresh method to be called again (otherwise changing the properties causes a refresh)
    if (self.selectedMinimum < self.minValue){
        _selectedMinimum = self.minValue;
    }
    if (self.selectedMaximum > self.maxValue){
        _selectedMaximum = self.maxValue;
    }
    
    isCollageSilder = true;
    if( self.maxCollageValue > 0 )
    {
        if (self.selectedMinimum < self.minCollageValue){
            isCollageSilder = false;
            _selectedMinimum = self.minCollageValue;
        }
        if (self.selectedMaximum > self.maxCollageValue){
            _selectedMaximum = self.maxCollageValue;
            isCollageSilder = false;
        }
    }
    
    
    //update the frames in a transaction so that the tracking doesn't continue until the frame has moved.
    [CATransaction begin];
    [CATransaction setDisableActions:YES] ;
    [self updateHandlePositions];
    [self updateLabelPositions];
    [CATransaction commit];
    [self updateLabelValues];

    //update the delegate
    if (_delegate && (self.leftHandleSelected || self.rightHandleSelected)){
        [_delegate rangeSlider:self didChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum isRight:(self.leftHandleSelected)?false:true];
    }
}

#pragma mark - 拖拽调整
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [touch locationInView:self];
    CGSize locationSize = [_delegate getLeftPointAndRightPoint];
    if(self.leftHandleSelected){
        
        if(location.x < locationSize.width){
            location.x = locationSize.width;
        }else if(location.x > (locationSize.height)){
            location.x = locationSize.height;
        }
    }
    else
    {
        if(location.x < locationSize.width + 35){
            location.x = locationSize.width + 35;
        }else if(location.x > (locationSize.height + 35)){
            location.x = locationSize.height + 35;
        }
    }
    
    if( isFristTracking )
    {
        isFristTracking = false;
        if(self.leftHandleSelected)
        {
            fTrackingX = self.leftHandle.bounds.size.width/2.0 -  [self convertPoint:location toView:self.leftLabel].x;
            
        }
        else
        {
            fTrackingX =  self.rightHandle.bounds.size.width/2.0 -  [self convertPoint:location toView:self.rightLabel].x;
            
        }
    }
    
    if(self.leftHandleSelected){
        if(location.x > self.rightHandle.frame.origin.x - 11){
            location.x = self.rightHandle.frame.origin.x - 11;
        }
    }
    if(self.rightHandleSelected){
        if(location.x < self.leftHandle.frame.origin.x + self.leftHandle.frame.size.width + 12 ){
            location.x = self.leftHandle.frame.origin.x + self.leftHandle.frame.size.width + 12;
        }
    }
    
    

    
    //find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the handle, not the left hand side)
//    float percentage = ((location.x-CGRectGetMinX(self.sliderLine.frame)) - RD_HANDLE_DIAMETER/2) / (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));
    
    float mainPercentage = fTrackingX/(CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));
    
    float percentage = (location.x - 25 + fTrackingX)/ (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));//20180612 修改bug:在视频最后几秒添加字幕后，再次编辑时，拖动右把手时不能拖动到视频的最后
//
     if(self.leftHandleSelected){
         percentage = (location.x - 8 + fTrackingX)/ (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));//20180612 修改bug:在视频最后几秒添加字幕后，再次编辑时，拖动右把手时不能拖动到视频的最后
     }
    if( percentage > 1.0 )
    {
        percentage = 1.0;
    }
    //multiply that percentage by self.maxValue to get the new selected minimum value
    float selectedValue = percentage * (self.maxValue - self.minValue) + self.minValue;
    
    mainPercentage = mainPercentage * (self.maxValue - self.minValue) + self.minValue;
    
    if( self.rightHandleSelected )
    {
        if( mainPercentage > 0 )
            mainPercentage = 0;
    }
    else
    {
        if( mainPercentage < 0 )
            mainPercentage = 0;
    }
    
    bool isLeft = true;
    bool isIsSlide = false;
    
    if (self.leftHandleSelected)
    {
        if (selectedValue < (self.selectedMaximum - mainPercentage) ){
            self.selectedMinimum = selectedValue;
            isIsSlide = true;
        }
        else {
            self.selectedMinimum = self.selectedMaximum - mainPercentage;
            
        }

    }
    else if (self.rightHandleSelected)
    {
        
        isLeft = false;
        if (selectedValue > (self.selectedMinimum  + fabsf(mainPercentage)) || (self.disableRange && selectedValue >= self.minValue)){ //don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
            self.selectedMaximum = selectedValue;
            isIsSlide = true;
            
        }
        else {
            self.selectedMaximum = self.selectedMinimum + fabsf(mainPercentage);
            
        }
    }
    isUpdateSlider = true;
    //no need to refresh the view because it is done as a sideeffect of setting the property
    if(_delegate){
        if([_delegate respondsToSelector:@selector(dragRangeSlider:didEndChangeSelectedMinimumValue:andMaximumValue:isRight:isUpdate:)]){
            [_delegate dragRangeSlider:self didEndChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum isRight:self.rightHandleSelected isUpdate:&isUpdateSlider];
        }
    }
    if( _delegate )
    {
        if( isCollageSilder && isUpdateSlider && isIsSlide )
        {
            if( isLeft )
            {
                [_delegate getIsSlide:location.x atoriginX: self.frame.origin.x atIsLeft:true];
            }
            else{
                [_delegate getIsSlide:location.x atoriginX: self.frame.origin.x atIsLeft:false];
            }
        }
        else
        {
            if( isIsSlide )
            {
                if( isLeft )
                {
                    if( isCollageSilder )
                        [_delegate getIsSlide:(self.selectedMinimum - self.minValue)/(self.maxValue - self.minValue) * (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame)) + 25 - fTrackingX atoriginX: self.frame.origin.x atIsLeft:true];
                }
                else{
                    
                    (self.selectedMaximum - self.minValue)/(self.maxValue - self.minValue)*(CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame)) +  8  - fTrackingX;
                    if( isCollageSilder )
                        [_delegate getIsSlide:location.x atoriginX: self.frame.origin.x atIsLeft:false];
                }
            }
        }
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    isFristTracking = true;
    fTrackingX = 0;
    if (self.leftHandleSelected){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(rangeSlider:didEndChangeSelectedMinimumValue:andMaximumValue:)]){
                [_delegate rangeSlider:self didEndChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum];
            }
        }
        self.leftHandleSelected = NO;
        [self animateHandle:self.leftHandle withSelection:NO];
    } else {
        if(_delegate){
            if([_delegate respondsToSelector:@selector(rangeSlider:didEndChangeSelectedMinimumValue:andMaximumValue:)]){
                [_delegate rangeSlider:self didEndChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum];
            }
        }
        self.rightHandleSelected = NO;
        [self animateHandle:self.rightHandle withSelection:NO];
    }
    if(_delegate){
        if([_delegate respondsToSelector:@selector(stopMove)]){
            [_delegate stopMove];
        }
    }
    _leftHandleSelected = NO;
    _rightHandleSelected = NO;

}

#pragma mark - Animation
- (void)animateHandle:(CALayer*)handle withSelection:(BOOL)selected {
    if (selected){
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
        handle.transform = CATransform3DMakeScale(1.7, 1.7, 1);

        //the label above the handle will need to move too if the handle changes size
        [self updateLabelPositions];

        [CATransaction setCompletionBlock:^{
            
        }];
        [CATransaction commit];

    } else {
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
        handle.transform = CATransform3DIdentity;

        //the label above the handle will need to move too if the handle changes size
        [self updateLabelPositions];

        [CATransaction commit];
    }
}

#pragma mark - Calculating nearest handle to point
- (float)distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2
{
    CGFloat xDist = (point2.x - point1.x);
    CGFloat yDist = (point2.y - point1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

- (CGPoint)getCentreOfRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}


#pragma mark - Properties
-(void)setTintColor:(UIColor *)tintColor{
    [super setTintColor:tintColor];

    struct CGColor *color = self.tintColor.CGColor;

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.5];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
    self.sliderLine.backgroundColor = color;
    self.leftHandle.backgroundColor = color;
    self.rightHandle.backgroundColor = color;

    if (self.minLabelColour == nil){
        self.minLabel.foregroundColor = color;
    }
    if (self.maxLabelColour == nil){
        self.maxLabel.foregroundColor = color;
    }
    [CATransaction commit];
}

- (void)setDisableRange:(BOOL)disableRange {
    _disableRange = disableRange;
    if (_disableRange){
        self.leftHandle.hidden = YES;
        self.minLabel.hidden = YES;
    } else {
        self.leftHandle.hidden = NO;
    }
}

- (NSNumberFormatter *)decimalNumberFormatter {
    if (!_decimalNumberFormatter){
        _decimalNumberFormatter = [[NSNumberFormatter alloc] init];
        _decimalNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _decimalNumberFormatter.maximumFractionDigits = 0;
    }
    return _decimalNumberFormatter;
}

- (void)setMinValue:(float)minValue {
    _minValue = minValue;
    [self refresh];
}

- (void)setMaxValue:(float)maxValue {
    _maxValue = maxValue;
    [self refresh];
}

- (void)setSelectedMinimum:(float)selectedMinimum {
    if (selectedMinimum < self.minValue){
        selectedMinimum = self.minValue;
    }

    _selectedMinimum = selectedMinimum;
    [self refresh];
}

- (void)setSelectedMaximum:(float)selectedMaximum {
    if (selectedMaximum > self.maxValue){
        selectedMaximum = self.maxValue;
    }

    _selectedMaximum = selectedMaximum;
    [self refresh];
}

-(void)setMinLabelColour:(UIColor *)minLabelColour{
    _minLabelColour = minLabelColour;
    self.minLabel.foregroundColor = _minLabelColour.CGColor;
}

-(void)setMaxLabelColour:(UIColor *)maxLabelColour{
    _maxLabelColour = maxLabelColour;
    self.maxLabel.foregroundColor = _maxLabelColour.CGColor;
}

-(void)setNumberFormatterOverride:(NSNumberFormatter *)numberFormatterOverride{
    _numberFormatterOverride = numberFormatterOverride;
    [self updateLabelValues];
}
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
