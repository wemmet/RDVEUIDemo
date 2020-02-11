//
//  ICGVideoTrimmerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//


#import "CaptionVideoTrimmerView.h"
#import "RDICGThumbView.h"
#import "RDICGRulerView.h"
#import "RDComminuteRangeView.h"

#define kTIMEDURATION 0.0

@interface CaptionVideoTrimmerView() <UIScrollViewDelegate,RDTTRangeSliderDelegate>{
    Float64 _timeWidthSecond;
    BOOL    _needShowcurrentRangeView;
    
    BOOL    isSeektime;
    
    BOOL    isShowCapptionView;
    CaptionRangeView *animateWithDurationShowCaptionView;
    
    NSTimer * animateWithDurationShowTimer;
    
    bool   isShow;
    UIImageView * contentImageView;
}

@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (strong, nonatomic) UIView *leftOverlayView;
@property (strong, nonatomic) UIView *middleOverlayView;
@property (strong, nonatomic) UIView *rightOverlayView;
@property (strong, nonatomic) RDICGThumbView *leftThumbView;
@property (strong, nonatomic) RDICGThumbView *rightThumbView;

@property (strong, nonatomic) UIView *topBorder;
@property (strong, nonatomic) UIView *bottomBorder;
@property (nonatomic) CGFloat captionType;
@property (nonatomic) CGFloat endTime;

@property (nonatomic) CGFloat widthPerSecond;

@property (nonatomic) CGPoint leftStartPoint;

@property (nonatomic) CGPoint rightStartPoint;

@property (nonatomic) CGFloat overlayWidth;

@property (nonatomic) NSMutableArray *allImages;

@property (assign,nonatomic)BOOL isdragging;

@property (assign,nonatomic)BOOL endScroll;

@property (assign,nonatomic)float currentRangeviewLeftValue;

@property (assign,nonatomic)float currentRangeviewrightValue;

@property (strong, nonatomic) UIButton *currentTouchesBtn;

@property (nonatomic,assign)BOOL      needSeekTime;
@end

@implementation CaptionVideoTrimmerView

#pragma mark - Initiations
-(CGFloat)CaptionType
{
    return _captionType;
}

-(void)SetCaptionType:(CGFloat) fcaptionType
{
    _captionType = fcaptionType;
}

- (instancetype)initWithFrame:(CGRect)frame videoCore:(RDVECore *)videoCore
{
    self = [super initWithFrame:frame];
    if (self) {
        _isCollage = false;
        _isFX = false;
        isShowCapptionView = false;
        _videoCore = videoCore;
        _needSeekTime = YES;
        isSeektime = true;
    }
    return self;
}

#pragma mark - Private methods

-(void)setisSeektime:(BOOL) Seektime
{
    isSeektime = Seektime;
}

- (void)resetSubviews:(UIImage *)thumbImage
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    _loadImageFinish = NO;
    if(duration >= 10){
        self.maxLength = 5;
    }else{
        self.maxLength = duration - 1;//20161012 bug39
    }
    
    if (self.minLength == 0) {
        self.minLength = 0;
    }
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
//    contentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame)-5)];
//    contentImageView.backgroundColor = TOOLBAR_COLOR;
//    [self addSubview:contentImageView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    @try {
        [self addSubview:self.scrollView];
    }
    @catch (NSException *exception) {
        
    }
    self.scrollView.tag = self.tag;
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    
    self.contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    self.contentView.userInteractionEnabled = YES;
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    

    
    CGFloat ratio = 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 5, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio-5)];
    [self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];

    self.videoRangeView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio) ];
    self.videoRangeView.backgroundColor = [UIColor clearColor];
    [self.videoRangeView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.videoRangeView];
    [self.videoRangeView.layer setBorderColor:UIColorFromRGB(0xffffff).CGColor];
    [self.videoRangeView.layer setBorderWidth:0];
    
    [self addFrames:thumbImage];
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetWidth(self.frameView.frame) : CGRectGetWidth(self.frame)) - (self.minLength * self.widthPerSecond);
    self.overlayWidth = kWIDTH - 100;
    // add left overlay view
    self.leftOverlayView = [[UIView alloc] initWithFrame:CGRectMake(10 - self.overlayWidth, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    CGRect leftThumbFrame = CGRectMake(self.overlayWidth-10, 0, 10, CGRectGetHeight(self.frameView.frame));
    if (self.leftThumbImage) {
        self.leftThumbView = [[RDICGThumbView alloc] initWithFrame:leftThumbFrame thumbImage:self.leftThumbImage];
    }else {
        self.leftThumbView = [[RDICGThumbView alloc] initWithFrame:leftThumbFrame color:self.themeColor right:NO];
    }
    [self.leftThumbView.layer setMasksToBounds:YES];
    [self.leftOverlayView addSubview:self.leftThumbView];
    [self.leftOverlayView setUserInteractionEnabled:YES];
    
    // add right overlay view
    CGFloat rightViewFrameX;
    rightViewFrameX = CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    if (self.rightThumbImage) {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) color:self.themeColor right:YES];
    }
    [self.rightThumbView.layer setMasksToBounds:YES];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    

    self.rangeSlider = [[RDTTRangeSlider alloc] initWithFrame:CGRectMake(self.videoRangeView.frame.origin.x-16, 5, self.videoRangeView.frame.size.width+32, self.videoRangeView.frame.size.height-5)];
    self.rangeSlider.minValue = 0;
    self.rangeSlider.maxValue = _videoCore.duration;
    self.rangeSlider.selectedMinimum = 0;
    self.rangeSlider.selectedMaximum = kTIMEDURATION;
    self.rangeSlider.hidden = YES;
    self.rangeSlider.delegate = self;
    [self.scrollView addSubview:self.rangeSlider];
    CGRect rect = self.videoRangeView.frame;
    _middleOverlayView = [[UIView alloc] initWithFrame:rect];
    self.leftThumbView.hidden = YES;
    self.rightThumbView.hidden = YES;
    self.leftOverlayView.hidden = NO;
    self.rightOverlayView.hidden = NO;
    [self.scrollView addSubview:self.rightOverlayView];
    [self.scrollView addSubview:self.leftOverlayView];
    [self.scrollView addSubview:self.middleOverlayView];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self.middleOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
        
    [self updateBorderFrames];
    [self notifyDelegate];
}

- (void)updateBorderFrames
{
    CGFloat height = self.borderWidth ? self.borderWidth : 1;
    [self.topBorder setFrame:CGRectMake(CGRectGetMaxX(self.leftOverlayView.frame), 0, CGRectGetMinX(self.rightOverlayView.frame)-CGRectGetMaxX(self.leftOverlayView.frame), height)];
    [self.bottomBorder setFrame:CGRectMake(CGRectGetMaxX(self.leftOverlayView.frame), CGRectGetHeight(self.frameView.frame)-height, CGRectGetMinX(self.rightOverlayView.frame)-CGRectGetMaxX(self.leftOverlayView.frame), height)];
}

- (void)moveLeftOverlayView:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.leftStartPoint = [gesture locationInView:self];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];
            
            int deltaX = point.x - self.leftStartPoint.x;
            
            CGPoint center = self.leftOverlayView.center;
            
            CGFloat newLeftViewMidX = center.x += deltaX;;
            CGFloat maxWidth = CGRectGetMinX(self.rightOverlayView.frame) - (self.minLength * self.widthPerSecond);
            CGFloat newLeftViewMinX = newLeftViewMidX - self.overlayWidth/2;
            if (newLeftViewMinX < 10 - self.overlayWidth) {
                newLeftViewMidX = 10 - self.overlayWidth + self.overlayWidth/2;
            } else if (newLeftViewMinX + self.overlayWidth > maxWidth) {
                newLeftViewMidX = maxWidth - self.overlayWidth / 2;
            }
            
            self.leftOverlayView.center = CGPointMake(newLeftViewMidX, self.leftOverlayView.center.y);
            self.leftStartPoint = point;
            [self updateBorderFrames];
            [self notifyDelegate];
        
            break;
        }
            
        default:
            break;
    }
}

- (void)moveRightOverlayView:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.rightStartPoint = [gesture locationInView:self];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];
            
            int deltaX = point.x - self.rightStartPoint.x;
            
            CGPoint center = self.rightOverlayView.center;
            
            CGFloat newRightViewMidX = center.x += deltaX;
            CGFloat minX = CGRectGetMaxX(self.leftOverlayView.frame) + self.minLength * self.widthPerSecond;
            CGFloat maxX = _videoCore.duration <= self.maxLength + 0.5 ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
            if (newRightViewMidX - self.overlayWidth/2 < minX) {
                newRightViewMidX = minX + self.overlayWidth/2;
            } else if (newRightViewMidX - self.overlayWidth/2 > maxX) {
                newRightViewMidX = maxX + self.overlayWidth/2;
            }
            
            self.rightOverlayView.center = CGPointMake(newRightViewMidX, self.rightOverlayView.center.y);
            self.rightStartPoint = point;
            [self updateBorderFrames];
            [self notifyDelegate];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)ISnotifyDelegate:(bool) isUpdata
{
    if( isUpdata )
       [self notifyDelegate];
}


- (void)notifyDelegate
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - 10) / self.widthPerSecond;
    if([_delegate respondsToSelector:@selector(trimmerView:didChangeLeftPosition:rightPosition:)] && _needSeekTime){
        [_delegate trimmerView:self didChangeLeftPosition:self.startTime rightPosition:self.endTime];
    }
    //20170413解决在iPad mini上划不动的bug
    self.leftOverlayView.frame = CGRectMake(self.videoRangeView.frame.origin.x - 20, self.leftOverlayView.frame.origin.y, self.currentCaptionView.frame.origin.x - 20, self.leftOverlayView.frame.size.height);
    self.rightOverlayView.frame = CGRectMake( 20 + self.videoRangeView.frame.origin.x + self.currentCaptionView.frame.origin.x+self.currentCaptionView.frame.size.width + 10, self.rightOverlayView.frame.origin.y, self.videoRangeView.frame.size.width - (self.currentCaptionView.frame.origin.x + self.currentCaptionView.frame.size.width), self.rightOverlayView.frame.size.height);
    float span = MAX(10, MIN(30, self.currentCaptionView.frame.origin.x));
    self.middleOverlayView.frame = CGRectMake(self.leftOverlayView.frame.origin.x + self.leftOverlayView.frame.size.width + span + 10, 0, self.rightOverlayView.frame.origin.x - (self.leftOverlayView.frame.origin.x + self.leftOverlayView.frame.size.width + span + 20) - 20, self.middleOverlayView.frame.size.height);
}

- (void)addFrames:(UIImage *)thumbImage
{
    float  preferredWidth = 0;
    Float64 duration = _videoCore.duration;
    
    float   picWidth = CGRectGetHeight(self.frameView.frame);
//    if(thumbImage){
//       picWidth = CGRectGetHeight(self.frameView.frame) * (thumbImage.size.width/thumbImage.size.height);
//    }
    if(self.thumbTimes > 0){
        for (int i=0; i<self.thumbTimes; i++) {
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:thumbImage];
            tmp.tag = i+1;
            //NSLog(@"tmp.tag = %ld",tmp.tag);
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = i*picWidth;
            
            currentFrame.size.width = picWidth;
            
            currentFrame.size.height = CGRectGetHeight(self.frameView.frame);
            
            preferredWidth += currentFrame.size.width;
            
            if( i == self.thumbTimes-1){
                currentFrame.size.width-=6;
            }
            tmp.frame = currentFrame;
            tmp.contentMode = UIViewContentModeScaleAspectFill;
            tmp.layer.masksToBounds = YES;
            @try {
                [self.frameView addSubview:tmp];
                
            } @catch (NSException *exception) {
                
            }
            UIView *temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tmp.frame.size.width, tmp.frame.size.height)];
            temp.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            [tmp addSubview:temp];
        }
    }
    float scrollWidth = self.frame.size.width;
    CGFloat screenWidth = CGRectGetWidth(self.frame);
    
//    [self.frameView setFrame:CGRectMake(scrollWidth/2-(self.frame.origin.x/2.0), 0, picWidth* self.thumbTimes - 6, CGRectGetHeight(self.frameView.frame))];
    self.frameView.frame = CGRectMake((scrollWidth - self.frame.origin.x)/2.0, _frameView.frame.origin.y, picWidth* self.thumbTimes - 6, _frameView.frame.size.height);
//    [self.videoRangeView setFrame:self.frameView.frame];
        [self.videoRangeView setFrame:CGRectMake(self.frameView.frame.origin.x, self.videoRangeView.frame.origin.y, self.frameView.frame.size.width, self.videoRangeView.frame.size.height)];
    CGFloat contentViewFrameWidth = duration <= self.maxLength + 0.5 ? screenWidth + 30 : CGRectGetWidth(self.frameView.frame);//frameViewFrameWidth;
    
    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth + scrollWidth, CGRectGetHeight(self.contentView.frame))];
    
    CGSize size = self.contentView.frame.size;
    
    [self.scrollView setContentSize:size];
    self.contentSize = size;
    
}

- (void)refreshChildrenFrames:(float)itemWidth
{
    float  preferredWidth = 0;
    Float64 duration = _videoCore.duration;
    
    [self.videoRangeView.subviews makeObjectsPerformSelector:@selector(removeFileWrapper:)];
    float   picWidth = itemWidth;
    
    if(self.thumbTimes > 0){
        for (int i=0; i<self.thumbTimes; i++) {
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:_allImages[i]];
            tmp.tag = i+1;
            //NSLog(@"tmp.tag = %ld",tmp.tag);
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = i*picWidth;
            
            currentFrame.size.width = picWidth;
            
            currentFrame.size.height = CGRectGetHeight(self.frameView.frame);
            
            preferredWidth += currentFrame.size.width;
            
            if( i == self.thumbTimes-1){
                currentFrame.size.width-=6;
            }
            tmp.frame = currentFrame;
            tmp.contentMode = UIViewContentModeScaleAspectFill;
            tmp.layer.masksToBounds = YES;
            @try {
                [self.frameView addSubview:tmp];

            } @catch (NSException *exception) {
                
            }
            UIView *temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tmp.frame.size.width, tmp.frame.size.height)];
            temp.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            [tmp addSubview:temp];
        }
    }
    float scrollWidth = self.frame.size.width;
    CGFloat screenWidth = CGRectGetWidth(self.frame);

    [self.frameView setFrame:CGRectMake(scrollWidth/2-(self.frame.origin.x/2.0), 0, picWidth* self.thumbTimes, CGRectGetHeight(self.frameView.frame))];
    [self.videoRangeView setFrame:CGRectMake(self.frameView.frame.origin.x, self.videoRangeView.frame.origin.y, self.frameView.frame.size.width, self.videoRangeView.frame.size.height)];
//    [self.videoRangeView setFrame:self.frameView.frame];
    
    CGFloat contentViewFrameWidth = duration <= self.maxLength + 0.5 ? screenWidth + 30 : CGRectGetWidth(self.frameView.frame);//frameViewFrameWidth;
    
    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth + scrollWidth, CGRectGetHeight(self.contentView.frame))];
    
    CGSize size = self.contentView.frame.size;
    
    [self.scrollView setContentSize:size];
    self.contentSize = size;

}


- (void)refreshThumbImage:(NSInteger)index thumbImage:(UIImage *)thumbImage{
   dispatch_async(dispatch_get_main_queue(), ^{
       //NSLog(@"self.thumbTimes:%ld index:%zd",(long)self.thumbTimes,index+1);
       @autoreleasepool {
           if(thumbImage){
               
               UIImageView * imageView = ((UIImageView *)[self.frameView viewWithTag:index + 1]);
               imageView.image = nil;
               
               [imageView setImage:thumbImage];
           }
           if(index==self.thumbTimes-1){
               _loadImageFinish = YES;
           }
       }
   });
    
    
}

- (BOOL)isRetina
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0));
}

- (void)showOrHiddenAddBtn{
    [self scrollViewDidScroll:self.scrollView];
}
#pragma mark - UIScrollViewDelegate

- (CaptionRangeView *)getcurrentCaption:(NSInteger)captionId{
    for (id view in self.videoRangeView.subviews) {
        if([view isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeV = (CaptionRangeView *)view;
//            if(rangeV.frame.origin.x <= self.scrollView.contentOffset.x && self.scrollView.contentOffset.x<=rangeV.frame.origin.x + rangeV.frame.size.width && rangeV.file.captionId == captionId){
            if (rangeV.file.captionId == captionId) {
                CMTimeRange timerange = rangeV.file.timeRange;
                Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
                Float64 duration = CMTimeGetSeconds(timerange.duration);
                self.rangeSlider.selectedMinimum = startTime;
                self.rangeSlider.selectedMaximum = startTime +duration;
                [self.rangeSlider layoutSubviews];
                self.currentCaptionView = rangeV;
                self.currentCaptionView.file = rangeV.file;
                if( self.currentCaptionView.captionType == 3 )
                    self.currentCaptionView.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
                else
                    self.currentCaptionView.layer.borderColor = Main_Color.CGColor;
                self.currentCaptionView.layer.borderWidth = 2;
                self.currentCaptionView.hidden = NO;
                [self.videoRangeView bringSubviewToFront:self.currentCaptionView];
//                self.rangeSlider.hidden = NO;
            }else{
                rangeV.alpha = 1.0;
//                rangeV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
//                rangeV.layer.borderWidth = 1;
            }
        }
    }
    return self.currentCaptionView;
}

- (CaptionRangeView *)getcurrentCaptionFromId:(NSInteger)captionId{
    for (id view in self.videoRangeView.subviews) {
        if([view isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeV = (CaptionRangeView *)view;
            if(rangeV.file.captionId == captionId){
                self.currentCaptionView = rangeV;
            }else{
                rangeV.alpha = 1.0;
//                rangeV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
//                rangeV.layer.borderWidth = 1;
            }
        }
    }
    return self.currentCaptionView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    if (duration <= self.maxLength + 0.5) {
        [UIView animateWithDuration:0.3 animations:^{
            [scrollView setContentOffset:CGPointZero];
        }];
    }

    if(_needShowcurrentRangeView){
        return;
    }
    
    if( isSeektime )
        [self notifyDelegate];
    else
        isSeektime = true;
    //float currentTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    BOOL selectThumbRangeView = NO;

    for (id view in self.videoRangeView.subviews) {
        if([view isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeV = (CaptionRangeView *)view;
            if(rangeV.frame.origin.x <= self.scrollView.contentOffset.x && self.scrollView.contentOffset.x<=rangeV.frame.origin.x + rangeV.frame.size.width){
//                rangeV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
//                rangeV.layer.borderWidth = 1.0;
                if( (rangeV.captionType != 3)  && (rangeV.captionType != 4))
                    rangeV.alpha = 0.7;
                selectThumbRangeView = YES;
            }else{
//                rangeV.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
//                rangeV.layer.borderWidth = 1;
                rangeV.alpha = 1.0;
            }
        }
    }
   
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchescurrentCaptionView:showOhidden:startTime:)]){
            [_delegate touchescurrentCaptionView:self showOhidden:!selectThumbRangeView startTime:self.startTime];
        }
    }
    
}

- (void)touchesUpInslide{
    self.rangeSlider.selectedMaximum = self.currentRangeviewLeftValue;
    self.rangeSlider.selectedMinimum = self.currentRangeviewrightValue;
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchescurrentCaptionView:)]){
            [_delegate touchescurrentCaptionView:self.currentCaptionView];
            self.rangeSlider.hidden = NO;
        }
    }
}
//开始滑动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _isdragging = YES;
    if(_delegate){
        if([_delegate respondsToSelector:@selector(capationScrollViewWillBegin:)]){
            [_delegate capationScrollViewWillBegin:self];
        }
    }
}

/**滚动停止
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(_isdragging){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(capationScrollViewWillEnd:startTime:endTime:)]){
                [_delegate capationScrollViewWillEnd:self startTime:self.startTime endTime:self.endTime];
            }
        }
    }
    _isdragging = NO;
}

/**手指停止滑动
*/
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(!decelerate){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(capationScrollViewWillEnd:startTime:endTime:)]){
                [_delegate capationScrollViewWillEnd:self startTime:self.startTime endTime:self.endTime];
            }
        }
        _isdragging = NO;
    }
}

- (RdCanAddCaptionType)checkCanAddCaption{
    CGSize size = [self getLeftPointAndRightPoint_X];
    if(self.scrollView.contentOffset.x>=size.height/*-5*/){//20190221 wuxiaoxia -5后，添加字幕等不能播放到视频的最后
        return (_pianweiDuration > 0 ? kCannotAddCaptionforPianwei : kCanAddCaption);
    }
    if(self.scrollView.contentOffset.x<=size.width-15){
        return (_piantouDuration > 0 ? kCannotAddCaptionforPiantou : kCanAddCaption);
    }
     return kCanAddCaption;
}

-(void)setTimeEffectCapation:(CMTimeRange ) timeRange atisShow:(BOOL) isShow
{
    if( _timeEffectCapation != nil )
        [_timeEffectCapation removeFromSuperview];
    
    if(isShow)
    {
        [self addCapation:nil type:4 captionDuration:CMTimeGetSeconds(timeRange.duration)];
        self.currentCaptionView.file.customFilter = nil;
        
        self.timeEffectCapation =  self.currentCaptionView;
        _timeEffectCapation.file.timeRange = timeRange;
        Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
        float x =  CMTimeGetSeconds(timeRange.start);
        x = self.videoRangeView.frame.size.width*(x/duration );
        
        if(isnan(x))
            x = 0.0;

        _timeEffectCapation.frame = CGRectMake(x, _timeEffectCapation.frame.origin.y, _timeEffectCapation.frame.size.width, _timeEffectCapation.frame.size.height);
    }
    _needShowcurrentRangeView = NO;
}

- (CaptionRangeView *)addCapation:(NSString *)themeName type:(NSInteger )type captionDuration:(double)captionDuration genSpecialFilter:(RDFXFilter *) customFilter
{
    [self addCapation:themeName type:type captionDuration:captionDuration];
    self.currentCaptionView.file.customFilter = customFilter;
    _needShowcurrentRangeView = NO;
    return self.currentCaptionView;
}

- (CaptionRangeView *)addCapation:(NSString *)themeName type:(NSInteger )type captionDuration:(double)captionDuration{
    isShow = true;
    _captionType = type;
    _needShowcurrentRangeView = YES;
    if(self.currentCaptionView && self.currentTouchesBtn){
        self.currentCaptionView.hidden = YES;
        self.currentTouchesBtn.hidden = NO;
    }
    self.rangeSlider.hidden = YES;
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
 
    self.currentRangeviewrightValue = 0;
    self.currentRangeviewLeftValue = 0;
    
    NSInteger width = 2;//[self getcurrentOrgionX:kTIMEDURATION *    (self.videoRangeView.frame.size.width/duration)];
    
    float addX = 0.0;
//    0.02/(duration/self.videoRangeView.frame.size.width);
    
    
    Float64 timeSecond = width / (self.videoRangeView.frame.size.width/duration);
    self.startTime += 0.02;
    if(timeSecond<kTIMEDURATION){
        _timeWidthSecond = timeSecond;
    }else{
        _timeWidthSecond = kTIMEDURATION;
    }
    
    if( (type == 4) && ( captionDuration > 0 ) ){
        timeSecond = captionDuration;
        width = (self.videoRangeView.frame.size.width/duration) * timeSecond;
        _timeWidthSecond = timeSecond;
    }
    
    
    CaptionRangeView *captionView = nil;
    if( duration < _timeWidthSecond )
       captionView = [[CaptionRangeView alloc] initWithFrame:CGRectMake(self.scrollView.contentOffset.x+addX, 0, width*(duration/_timeWidthSecond), 3)];
    else
    {
        if( (_timeWidthSecond < ( duration - self.startTime ))
//           || ( type != 2 )
           )
            captionView = [[CaptionRangeView alloc] initWithFrame:CGRectMake(self.scrollView.contentOffset.x+addX, 0, width, 3)];
        else
        {
            if( (duration - self.startTime) <= 0 )
                captionView = [[CaptionRangeView alloc] initWithFrame:CGRectMake(self.scrollView.contentOffset.x+addX, 0, width*0.1, 3)];
            else
                captionView = [[CaptionRangeView alloc] initWithFrame:CGRectMake(self.scrollView.contentOffset.x+addX, 0, width*( (duration - self.startTime)/_timeWidthSecond ), 3)];
        }
    }
    captionView.titleLabel.font = [UIFont systemFontOfSize:12];
//    self.videoRangeView.frame.size.height
    self.startTime = captionView.frame.origin.x / (self.videoRangeView.frame.size.width/duration);
    captionView.file = [[RDCaptionRangeViewFile alloc] init];
//    captionView.backgroundColor = Main_Color;
    if( _captionType == 3 )
    {
//        _needShowcurrentRangeView = NO;
        captionView.backgroundColor = UIColorFromRGB(0x000000);
    }
    else
        captionView.backgroundColor = Main_Color;
    captionView.alpha = 1.0;
    captionView.tag =1000;
    captionView.captionType = _captionType;
    captionView.file.captionId = _videoRangeView.subviews.count+1;
    self.videoRangeView.userInteractionEnabled = YES;
    if( duration < _timeWidthSecond )
    {
        captionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(self.startTime - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(duration, TIMESCALE));
    }
    else
    {
        if( _timeWidthSecond < ( duration - self.startTime ) )
            captionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(self.startTime - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(_timeWidthSecond, TIMESCALE));
        else
        {
             if( (duration - self.startTime) <= 0 )
                 captionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(self.startTime - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(0.1, TIMESCALE));
             else
                 captionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(self.startTime - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(( duration - self.startTime ), TIMESCALE));
        }
    }
    [self.videoRangeView addSubview:captionView];
    
    CGRect moveCaptionViewBtnFrame = captionView.frame;
    moveCaptionViewBtnFrame.origin.x += 36;
    if( moveCaptionViewBtnFrame.size.width >= 36 )
        moveCaptionViewBtnFrame.size.width -= 36;
    else
        moveCaptionViewBtnFrame.size.width = 0;
    self.rangeSlider.moveCaptionViewBtn.frame = moveCaptionViewBtnFrame;
    
    isShow = false;
    
//    if( _captionType == 2 )
//        isShow = true;
    
    self.currentCaptionView = captionView;
    self.currentCaptionView.file = captionView.file;
    if( self.currentCaptionView.captionType == 3 )
        self.currentCaptionView.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
    else
        self.currentCaptionView.layer.borderColor = Main_Color.CGColor;
    self.currentCaptionView.layer.borderWidth = 2;
    self.rangeSlider.selectedMinimum = self.startTime;
    self.rangeSlider.selectedMaximum = self.startTime + _timeWidthSecond;
    
    [self.rangeSlider layoutSubviews];
    
//    if( _captionType != 2 )
//    {
        [self.videoRangeView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if([obj isKindOfClass:[CaptionRangeView class]]){
                CaptionRangeView *captionView = (CaptionRangeView *)obj;
                if( captionView.captionType == 3 )
                    captionView.backgroundColor = UIColorFromRGB(0x000000);
                else
                {
                    if( (captionView.captionType != 3) && (captionView.captionType != 4) )
                    {
                        captionView.backgroundColor = Main_Color;
                        captionView.alpha = 0.7;
                    }
                }
                [captionView setTitle:@"" forState:UIControlStateSelected];
                captionView.frame = CGRectMake(captionView.frame.origin.x, 0, captionView.frame.size.width, 3);
                
                
                captionView.layer.borderWidth = 0;
                captionView.selected = YES;
            }
        }];
        _currentCaptionView.layer.borderWidth = 0;
        if( self.currentCaptionView.captionType == 3 )
            _currentCaptionView.backgroundColor = UIColorFromRGB(0x000000);
        else
            _currentCaptionView.backgroundColor = Main_Color;
        self.currentCaptionView.alpha = 1.0;
        _currentCaptionView.frame = CGRectMake(_currentCaptionView.frame.origin.x, 0, _currentCaptionView.frame.size.width, 3);
        _currentCaptionView.selected = YES;
//    }
    self.rangeSlider.hidden = YES;
    return captionView;
}

-(void)animateWithDurationShowCurrentCaptionView
{
//    if( _isFX && ( (_currentCaptionView.file.customFilter.FXTypeIndex == 3) || (_currentCaptionView.file.customFilter.FXTypeIndex == 4) || (_currentCaptionView.file.customFilter.FXTypeIndex == 5) ) )
//        _rangeTimeLabel.hidden = YES;
//    else
        _rangeTimeLabel.hidden = NO;
    
    float width = 40;
    if( (_currentCaptionView.frame.size.width-4) < 40 )
    {
        width = _currentCaptionView.frame.size.width-4;
    }
    self.rangeTimeLabel.frame = CGRectMake(_currentCaptionView.frame.origin.x+_currentCaptionView.frame.size.width - width - 4 + 18, 2, width, self.videoRangeView.frame.size.height/4.0);
    self.rangeTimeLabel.text =  [RDHelpClass timeToSecFormat: CMTimeGetSeconds(_currentCaptionView.file.timeRange.duration)];
    
    _currentCaptionView.layer.borderWidth = 2;
    _currentCaptionView.backgroundColor = [UIColor clearColor];
    if( (self.currentCaptionView.captionType != 3) && (self.currentCaptionView.captionType != 4) )
        self.currentCaptionView.alpha = 0.7;
    _currentCaptionView.frame = CGRectMake(_currentCaptionView.frame.origin.x, 0, _currentCaptionView.frame.size.width, 3);
    _currentCaptionView.selected = NO;
    
    self.rangeSlider.frame = CGRectMake(self.rangeSlider.frame.origin.x, 0, self.rangeSlider.frame.size.width, 3);
//    if( _isFX  && ( (_currentCaptionView.file.customFilter.FXTypeIndex == 3) || (_currentCaptionView.file.customFilter.FXTypeIndex == 4) || (_currentCaptionView.file.customFilter.FXTypeIndex == 5) ) )
//        self.rangeSlider.hidden = YES;
//    else
    self.rangeSlider.hidden = NO;
    if( _isCollage )
    {
        if( _currentCaptionView.file.collage.vvAsset.type == RDAssetTypeVideo )
        {
            float startTime = CMTimeGetSeconds(_currentCaptionView.file.timeRange.start) - CMTimeGetSeconds(_currentCaptionView.file.collage.vvAsset.timeRange.start);
            if( startTime < 0 )
            {
                startTime  = 0;
            }
            CMTime duration = [AVURLAsset assetWithURL:_currentCaptionView.file.collage.vvAsset.url].duration;
            float endTime = startTime + CMTimeGetSeconds(duration);
            
            self.rangeSlider.minCollageValue = startTime;
            self.rangeSlider.maxCollageValue = endTime;
        }
        else
        {
            self.rangeSlider.minCollageValue = 0;
            self.rangeSlider.maxCollageValue = 0;
        }
        
    }
    else
    {
        self.rangeSlider.minCollageValue = 0;
        self.rangeSlider.maxCollageValue = 0;
    }
    //动画效果中的压缩 做处理

    self.rangeSlider.leftLabel.frame =  CGRectMake(self.rangeSlider.leftLabel.frame.origin.x, self.rangeSlider.leftLabel.frame.origin.y, self.rangeSlider.leftLabel.frame.size.width, 3);
    self.rangeSlider.rightLabel.frame =  CGRectMake(self.rangeSlider.rightLabel.frame.origin.x, self.rangeSlider.rightLabel.frame.origin.y, self.rangeSlider.rightLabel.frame.size.width, 3);
    
    if( !(_isFX && ( (_currentCaptionView.file.customFilter.FXTypeIndex == 3) || (_currentCaptionView.file.customFilter.FXTypeIndex == 4) || (_currentCaptionView.file.customFilter.FXTypeIndex == 5) )) )
    {
        self.rangeSlider.leftLabel.hidden = NO;
        self.rangeSlider.rightLabel.hidden = NO;
    }
    else
    {
        self.rangeSlider.leftLabel.hidden = YES;
        self.rangeSlider.rightLabel.hidden = YES;
    }
    

    self.rangeSlider.leftLayer.hidden = YES;
    self.rangeSlider.rightLayer.hidden = YES;
    self.rangeSlider.leftHightedLayer.hidden = YES;
    self.rangeSlider.rightHightedLayer.hidden =YES;
    
    
    [UIView animateWithDuration:0.3 animations:^{
        _currentCaptionView.frame = CGRectMake(_currentCaptionView.frame.origin.x, 5, _currentCaptionView.frame.size.width, self.videoRangeView.frame.size.height - 5);
        self.rangeSlider.frame = CGRectMake(self.rangeSlider.frame.origin.x, 5, self.rangeSlider.frame.size.width, self.videoRangeView.frame.size.height - 5);
        self.rangeSlider.rightLabel.frame =  CGRectMake(self.rangeSlider.rightLabel.frame.origin.x, self.rangeSlider.rightLabel.frame.origin.y, self.rangeSlider.rightLabel.frame.size.width, self.videoRangeView.frame.size.height - 5);
        self.rangeSlider.leftLabel.frame =  CGRectMake(self.rangeSlider.leftLabel.frame.origin.x, self.rangeSlider.leftLabel.frame.origin.y, self.rangeSlider.leftLabel.frame.size.width, self.videoRangeView.frame.size.height - 5);
    }];
    
    if( animateWithDurationShowTimer )
    {
        [animateWithDurationShowTimer invalidate];
        animateWithDurationShowTimer = nil;
    }
    animateWithDurationShowTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(animateWithDurationShow_Timer) userInfo:nil repeats:YES];
    
}

-(void)animateWithDurationShow_Timer
{
//    self.rangeSlider.hidden = NO;
//    self.rangeSlider.leftLabel.hidden = YES;
//    self.rangeSlider.rightLabel.hidden = YES;
    
//    self.rangeSlider.leftLayer.hidden = NO;
//    self.rangeSlider.rightLayer.hidden = NO;
//    self.rangeSlider.leftHightedLayer.hidden = NO;
//    self.rangeSlider.rightHightedLayer.hidden =NO;
    
    [animateWithDurationShowTimer invalidate];
    animateWithDurationShowTimer = nil;
}

-(void)cancelCurrent
{
    if( _currentCaptionView != nil )
    {
        if( self.currentCaptionView.captionType == 3 )
            _currentCaptionView.backgroundColor = UIColorFromRGB(0x000000);
        else
            _currentCaptionView.backgroundColor = Main_Color;
        [_currentCaptionView setTitle:@"" forState:UIControlStateSelected];
        _currentCaptionView.frame = CGRectMake(_currentCaptionView.frame.origin.x, 0, _currentCaptionView.frame.size.width, 3);
        _currentCaptionView.alpha = 1.0;
        _currentCaptionView.layer.borderWidth = 0;
        _currentCaptionView.selected = YES;
        _currentCaptionView = nil;
        self.rangeSlider.hidden = YES;
        [self.rangeTimeLabel removeFromSuperview];
        self.rangeTimeLabel = nil;
    }
    else
    {
        [self.videoRangeView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if([obj isKindOfClass:[CaptionRangeView class]]){
                CaptionRangeView *captionView = (CaptionRangeView *)obj;
                if( captionView.captionType == 3 )
                    captionView.backgroundColor = UIColorFromRGB(0x000000);
                else
                    captionView.backgroundColor = Main_Color;
                [captionView setTitle:@"" forState:UIControlStateSelected];
                captionView.frame = CGRectMake(captionView.frame.origin.x, 0, captionView.frame.size.width, 3);
                captionView.alpha = 1.0;
                captionView.layer.borderWidth = 0;
                captionView.selected = YES;
            }
        }];
    }
}

-(void)setCurrentCaptionView:(CaptionRangeView *)currentCaptionView
{
    if( currentCaptionView == nil )
    {
        if( self.currentCaptionView.captionType == 3 )
            _currentCaptionView.backgroundColor = UIColorFromRGB(0x000000);
        else
            _currentCaptionView.backgroundColor = Main_Color;
        [_currentCaptionView setTitle:@"" forState:UIControlStateSelected];
        if( _currentCaptionView.captionType !=  2 )
            _currentCaptionView.selected = YES;
        else
            _currentCaptionView.selected = YES;
        _currentCaptionView.frame = CGRectMake(_currentCaptionView.frame.origin.x, 0, _currentCaptionView.frame.size.width, 3);
        _currentCaptionView.alpha = 1.0;
        _currentCaptionView.layer.borderWidth = 0;
        _currentCaptionView.selected = YES;
        _currentCaptionView = currentCaptionView;
        self.rangeSlider.hidden = YES;
        [self.rangeTimeLabel removeFromSuperview];
        self.rangeTimeLabel = nil;
    }
    else
    {
        {
            [self SetCurrentCaptionView:currentCaptionView];
            
        }
        [self.videoRangeView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if([obj isKindOfClass:[CaptionRangeView class]]){
                CaptionRangeView *captionView = (CaptionRangeView *)obj;
                if( captionView.captionType == 3 )
                    captionView.backgroundColor = UIColorFromRGB(0x000000);
                else
                    captionView.backgroundColor = Main_Color;
                [captionView setTitle:@"" forState:UIControlStateSelected];
                if( captionView.captionType !=  2 )
                    captionView.selected = YES;
                else
                    captionView.selected = YES;
                captionView.alpha = 1.0;
                captionView.frame = CGRectMake(captionView.frame.origin.x, 0, captionView.frame.size.width, 3);
                captionView.layer.borderWidth = 0;
                captionView.selected = YES;
            }
        }];
        if( _currentCaptionView )
        {
            if( isShow )
                [self animateWithDurationShowCurrentCaptionView];
            else
                isShow = true;
        }
    }
}

-(void)SetCurrentCaptionView:( CaptionRangeView * ) rangeV
{
    CMTimeRange timerange = rangeV.file.timeRange;
    Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
    Float64 duration = CMTimeGetSeconds(timerange.duration);
    self.rangeSlider.selectedMinimum = startTime;
    self.rangeSlider.selectedMaximum = startTime +duration;
    [self.rangeSlider layoutSubviews];
    _currentCaptionView = rangeV;
    _currentCaptionView.file = rangeV.file;
    _currentCaptionView.alpha = 1.0;
    if( self.currentCaptionView.captionType == 3 )
        _currentCaptionView.layer.backgroundColor = UIColorFromRGB(0x000000).CGColor;
    else
        _currentCaptionView.layer.borderColor = Main_Color.CGColor;
    
    if( _captionType !=  2 )
    {
        _currentCaptionView.selected = YES;
        [_currentCaptionView setTitle:@"" forState:UIControlStateNormal];
    }
    else
        _currentCaptionView.selected = NO;
    
    _currentCaptionView.layer.borderWidth = 2;
    _currentCaptionView.hidden = NO;
    [self.videoRangeView bringSubviewToFront:_currentCaptionView];
//    self.rangeSlider.hidden = NO;
    [self.scrollView setContentOffset:CGPointMake(self.currentCaptionView.frame.origin.x, 0) animated:NO];
}

- (void)moveCurrentCaptionView:(CGPoint)moveOffset
{
    self.currentCaptionView.center = CGPointMake(moveOffset.x - 16, _currentCaptionView.center.y);
}

- (BOOL)changecurrentCaptionViewTimeRange{
    CGRect rect = _currentCaptionView.frame;
    CGSize size = [self getLeftPointAndRightPoint_X];
    float x = rect.origin.x + rect.size.width;
    //float x1 = self.scrollView.contentOffset.x;
    //NSLog(@"%s :%f %f",__func__,x,x1);
    if(x > size.height){
        return NO;
    }
    if(x > self.videoRangeView.frame.size.width/*-3*/){//20190221 wuxiaoxia -3后，添加字幕等不能播放到视频的最后
        return NO;
    }
    if(self.scrollView.contentOffset.x > rect.origin.x){
        rect.size.width = self.scrollView.contentOffset.x - _currentCaptionView.frame.origin.x;
        _currentCaptionView.frame = rect;
        
        CGRect moveCaptionViewBtnFrame = rect;
        moveCaptionViewBtnFrame.origin.x += 36;
        if( moveCaptionViewBtnFrame.size.width >= 36 )
            moveCaptionViewBtnFrame.size.width -= 36;
        else
            moveCaptionViewBtnFrame.size.width = 0;
        self.rangeSlider.moveCaptionViewBtn.frame = moveCaptionViewBtnFrame;
        
        float duration = _videoCore.duration;
        Float64 currentStart = duration * rect.origin.x/_videoRangeView.frame.size.width;
        Float64 currentDuration = duration * rect.size.width/_videoRangeView.frame.size.width;
        
        _currentCaptionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(currentStart - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(currentDuration, TIMESCALE));
        if (rect.origin.x + rect.size.width == _videoRangeView.frame.size.width) {
            _currentCaptionView.file.timeRange = CMTimeRangeMake(_currentCaptionView.file.timeRange.start, CMTimeMake(duration * TIMESCALE - _currentCaptionView.file.timeRange.start.value, TIMESCALE));
        }
        _rangeSlider.hidden = YES;
    }
    _currentCaptionView.hidden = NO;
    _currentCaptionView.alpha = 1.0;
//    if( _captionType == 2 )
//    {
//        _currentCaptionView.backgroundColor = [Main_Color colorWithAlphaComponent:0.6];
//        _currentCaptionView.backgroundColor = [Main_Color colorWithAlphaComponent:0.8];
//    }
    return YES;
    
}

- (BOOL)changecurrentCaptionViewTimeRange:(Float64)captionDuration{
    float  duration = _videoCore.duration;
    float  currentCaptionWidth = (self.videoRangeView.frame.size.width/duration) * captionDuration;
    //float  piantouWidth = (self.videoRangeView.frame.size.width/duration) * _piantouDuration;
    float  painweiWidth = (self.videoRangeView.frame.size.width/duration) * _pianweiDuration;
    if(self.currentCaptionView.frame.origin.x + currentCaptionWidth > self.videoRangeView.frame.size.width - painweiWidth){
        currentCaptionWidth = self.videoRangeView.frame.size.width - painweiWidth - self.currentCaptionView.frame.origin.x;
        captionDuration = currentCaptionWidth / (self.videoRangeView.frame.size.width/duration);
    }
    CGRect rect = self.currentCaptionView.frame;
    self.currentCaptionView.hidden = NO;
    self.currentCaptionView.alpha = 1;
    self.currentCaptionView.backgroundColor = [UIColor clearColor];
    CGSize size = [self getLeftPointAndRightPoint_X];
    if(self.scrollView.contentOffset.x>=size.height/*-5*/){//20190221 wuxiaoxia -5后，添加字幕等不能播放到视频的最后
        return NO;
    }
    rect.size.width = currentCaptionWidth;
    self.currentCaptionView.frame = rect;
    
    CGRect moveCaptionViewBtnFrame = rect;
    moveCaptionViewBtnFrame.origin.x += 36;//为了不跟把手的手势冲突
   if( moveCaptionViewBtnFrame.size.width >= 36 )
        moveCaptionViewBtnFrame.size.width -= 36;
    else
        moveCaptionViewBtnFrame.size.width = 0;
    self.rangeSlider.moveCaptionViewBtn.frame = moveCaptionViewBtnFrame;
    
    UIColor *color = Main_Color;
    self.currentCaptionView.backgroundColor = color;
    if( (self.currentCaptionView.captionType != 3) && (self.currentCaptionView.captionType != 4) )
        self.currentCaptionView.alpha = 0.7;
    Float64 currentStart = duration * rect.origin.x/self.videoRangeView.frame.size.width;
    
    self.currentCaptionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(currentStart - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(captionDuration, TIMESCALE));
    if (rect.origin.x + rect.size.width >= _videoRangeView.frame.size.width) {
        _currentCaptionView.file.timeRange = CMTimeRangeMake(_currentCaptionView.file.timeRange.start, CMTimeMake(duration * TIMESCALE - _currentCaptionView.file.timeRange.start.value, TIMESCALE));
    }
    _rangeSlider.hidden = YES;
    return YES;
    
}


- (void)touchescurrentCaptionView:(CaptionRangeView *)sender{
    if(self.currentCaptionView && self.currentTouchesBtn){
        self.currentCaptionView.hidden = YES;
        self.currentTouchesBtn.hidden = NO;
    }
    self.rangeSlider.hidden = YES;
    
    for (id view in self.videoRangeView.subviews) {
        if([view isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeV = (CaptionRangeView *)view;
            if(rangeV == sender){
                CMTimeRange timerange = rangeV.file.timeRange;
                Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
                Float64 duration = CMTimeGetSeconds(timerange.duration);
                
                self.rangeSlider.selectedMinimum = startTime;
                self.rangeSlider.selectedMaximum = startTime +duration;
                [self.rangeSlider layoutSubviews];
                self.currentCaptionView = rangeV;
                self.currentCaptionView.file = rangeV.file;
                self.currentCaptionView.hidden = NO;
//                self.rangeSlider.hidden = NO;
                if(_delegate){
                    if([_delegate respondsToSelector:@selector(touchescurrentCaptionView:)]){
                        [_delegate touchescurrentCaptionView:self.currentCaptionView];
                    }
                }
                
                if( self.currentCaptionView.captionType == 3 )
                    self.currentCaptionView.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
                else
                    self.currentCaptionView.layer.borderColor = Main_Color.CGColor;
                self.currentCaptionView.layer.borderWidth = 2;
                break;
            }
        }
    }
    
    self.rangeSlider.hidden= NO;
}

- (void)setFontName:(NSString *)fontName{
    self.currentCaptionView.file.fontName = fontName;
}

- (void)setChangeScaleValue:(double)changeScaleValue{
    self.currentCaptionView.file.scale = changeScaleValue;
}

- (void) changeCurrentRangeviewWithTColor:(UIColor *)tColor alpha:(float)alpha colorId:(NSInteger)colorId
                              captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    if(tColor){
        captionRangeView.file.tColor = tColor;
        captionRangeView.file.caption.tColor = tColor;
        captionRangeView.file.caption.textAlpha = alpha;
        captionRangeView.file.selectColorItemIndex = colorId;
    }
}
- (void) changeCurrentRangeviewWithSubtitleAlignment:(RDSubtitleAlignment)subtitleAlignment captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView)
        captionRangeView = self.currentCaptionView;
    captionRangeView.file.alignment = subtitleAlignment;
}

- (void)changeCurrentRangeviewWithAlpha:(float)alpha captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView)
    captionRangeView = self.currentCaptionView;
    captionRangeView.file.caption.opacity = alpha;
}

- (void) changeCurrentRangeviewWithstrokeColor:(UIColor *)strokeColor borderWidth:(float )borderWidth alpha:(float)alpha borderColorId:(NSInteger)borderColorId
                                   captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    if(strokeColor){
        captionRangeView.file.strokeColor = strokeColor;
        captionRangeView.file.caption.strokeColor = strokeColor;
        captionRangeView.file.caption.strokeWidth = borderWidth;
        captionRangeView.file.caption.strokeAlpha = alpha;
        captionRangeView.file.caption.isStroke = (borderColorId > 0);
        captionRangeView.file.selectBorderColorItemIndex = borderColorId;
    }
}

- (void)changeCurrentRangeviewWithShadowColor:(UIColor *)color width:(float)width colorId:(NSInteger)colorId captionView:(CaptionRangeView *)captionRangeView
{
    if(!captionRangeView)
        captionRangeView = self.currentCaptionView;
    if(color){
        captionRangeView.file.shadowColor = color;
        captionRangeView.file.caption.tShadowColor = color;
        captionRangeView.file.caption.tShadowOffset = CGSizeMake(width, width);
        captionRangeView.file.caption.isShadow = (colorId > 0);
        captionRangeView.file.selectShadowColorIndex = colorId;
    }
}

- (void)changeCurrentRangeviewWithBgColor:(UIColor *)color colorId:(NSInteger)colorId captionView:(CaptionRangeView *)captionRangeView
{
    if(!captionRangeView)
        captionRangeView = self.currentCaptionView;
    if(color){
        captionRangeView.file.bgColor = color;
        captionRangeView.file.caption.backgroundColor = color;
        captionRangeView.file.selectBgColorIndex = colorId;
    }
}

- (void) changeCurrentRangeviewWithIsBold:(BOOL)isBold isItalic:(BOOL )isItalic isShadow:(BOOL)isShadow shadowColor:(UIColor *)shadowColor shadowOffset:(CGSize)shadowOffset
                              captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    captionRangeView.file.caption.isBold = isBold;
    captionRangeView.file.caption.isItalic = isItalic;
    captionRangeView.file.caption.isShadow = isShadow;
    captionRangeView.file.caption.tShadowColor = shadowColor;
    captionRangeView.file.caption.tShadowOffset = shadowOffset;
    if (!isShadow) {
        captionRangeView.file.selectShadowColorIndex = -1;
    }
}

- (void) changeCurrentRangeviewWithFontName:(NSString *)fontName
                                   fontCode:(NSString *)fontCode
                                     fontPath:(NSString *)fontPath
                                     fontId:(NSInteger)fontId
                                captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    if(fontName){
        captionRangeView.file.selectFontItemIndex = fontId;
        if(captionRangeView.file.selectFontItemIndex ==0){
            fontName = [[UIFont systemFontOfSize:10] fontName];//@"Baskerville-BoldItalic";
            fontCode = @"morenziti";
        }
        captionRangeView.file.caption.tFontName = fontName;
//        captionRangeView.file.fontCode = fontCode;
        captionRangeView.file.fontPath = fontPath;
    }
}

- (void) changeCurrentRangeviewWithNetCover:(NSString *)netCover
                                captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    if(netCover){
        captionRangeView.file.netCover = netCover;
    }else{
        captionRangeView.file.netCover = @"";
    }
    
}

- (void) changeCurrentRangeviewFile:(RDCaption *)caption
                          typeIndex:(NSInteger)typeIndex
                          frameSize:(CGSize)frameSize
                        captionText:(NSString *)captionText
                           aligment:(RDCaptionTextAlignment)aligment
                 captionAnimateType:(RDCaptionAnimateType)captionAnimateType
                  inAnimateTypeIndex:(NSInteger)inAnimateTypeIndex
                 outAnimateTypeIndex:(NSInteger)outAnimateTypeIndex
                     pushInPoint:(CGPoint)pushInPoint
                       pushOutPoint:(CGPoint)pushOutPoint
                        captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    
    if(!captionRangeView){
        return;
    }
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    captionRangeView.file.scale = 1.0;
    
    if(captionText.length>0){
        captionRangeView.file.captionText = captionText;
        if( _captionType == 2 )
            [captionRangeView setTitle:captionText forState:UIControlStateNormal];
        else
            [captionRangeView setTitle:@"" forState:UIControlStateNormal];
    }
    if(caption)
        captionRangeView.file.caption = caption;
    captionRangeView.file.inAnimationIndex = inAnimateTypeIndex;
    captionRangeView.file.outAnimationIndex = outAnimateTypeIndex;
    captionRangeView.file.captiontypeIndex = typeIndex;
    captionRangeView.file.caption.tAlignment = aligment;
    captionRangeView.file.caption.textAnimate.type = captionAnimateType;
    captionRangeView.file.caption.textAnimate.pushInPoint = pushInPoint;
    captionRangeView.file.caption.textAnimate.pushOutPoint = pushOutPoint;
    captionRangeView.file.caption.imageAnimate.type = captionAnimateType;
    captionRangeView.file.caption.imageAnimate.pushInPoint = pushInPoint;
    captionRangeView.file.caption.imageAnimate.pushOutPoint = pushOutPoint;
    if(typeIndex == 0){
        if(!CGSizeEqualToSize(CGSizeZero, frameSize)) {
            captionRangeView.file.frameSize = frameSize;
        }
    }
}

- (void)changeSubtitleTye:(RDCaption *)caption
                typeIndex:(NSInteger)typeIndex
                frameSize:(CGSize)frameSize
              captionView:(CaptionRangeView *)captionRangeView
{
    if(!captionRangeView)
        captionRangeView = self.currentCaptionView;
    if(!captionRangeView){
        return;
    }
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    captionRangeView.file.scale = 1.0;
    if(caption) {
        captionRangeView.file.caption = caption;
        if(caption.pText.length>0){
            if( _captionType == 2 )
                [captionRangeView setTitle:caption.pText forState:UIControlStateNormal];
            else
                [captionRangeView setTitle:@"" forState:UIControlStateNormal];
        }
    }
    captionRangeView.file.captiontypeIndex = typeIndex;
    if(typeIndex == 0){
        if(!CGSizeEqualToSize(CGSizeZero, frameSize)) {
            captionRangeView.file.frameSize = frameSize;
        }
    }
}

- (void)changeMulti_trackCurrentRangeviewFile:(RDMusic *)music
                                  captionView:(CaptionRangeView *)captionRangeView
{
    if( !music )
        return;
    
    if(!captionRangeView) {
        captionRangeView = self.currentCaptionView;
    }
    if(!captionRangeView){
        return;
    }
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
//    if( music ){
//        [captionRangeView setTitle:music.name forState:UIControlStateNormal];
//        [captionRangeView setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
//    }
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    if(music){
        captionRangeView.file.music = music;
    }
    captionRangeView.hidden = NO;
}

- (void)changeDewatermark:(id)dewatermark
                typeIndex:(RDDewatermarkType)type {
    CaptionRangeView *captionRangeView = self.currentCaptionView;
    
    if(!captionRangeView){
        return;
    }
    captionRangeView.file.blur = nil;
    captionRangeView.file.mosaic = nil;
    captionRangeView.file.dewatermark = nil;
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    captionRangeView.file.scale = 1.0;
    if (dewatermark) {
        if([dewatermark isKindOfClass:[RDAssetBlur class]]){
            captionRangeView.file.blur = dewatermark;
        }else if ([dewatermark isKindOfClass:[RDMosaic class]]) {
            captionRangeView.file.mosaic = dewatermark;
        }else if ([dewatermark isKindOfClass:[RDDewatermark class]]) {
            captionRangeView.file.dewatermark = dewatermark;
        }
    }
    captionRangeView.file.captiontypeIndex = type;
}

- (void)changeCollageCurrentRangeviewFile:(RDWatermark *)collage
                               thumbImage:(UIImage *)thumbImage
                              captionView:(CaptionRangeView *)captionRangeView {
    if(!captionRangeView) {
        captionRangeView = self.currentCaptionView;
    }
    if(!captionRangeView){
        return;
    }
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    captionRangeView.file.scale = 1.0;
    if(collage){
        captionRangeView.file.collage = collage;
    }
    if (thumbImage) {
        captionRangeView.file.thumbnailImage = thumbImage;
    }
}

- (void)changeDoodleCurrentRangeviewFile:(RDWatermark *)doodle
                               thumbImage:(UIImage *)thumbImage
                              captionView:(CaptionRangeView *)captionRangeView {
    if(!captionRangeView) {
        captionRangeView = self.currentCaptionView;
    }
    if(!captionRangeView){
        return;
    }
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    captionRangeView.file.scale = 1.0;
    if(doodle){
        captionRangeView.file.doodle = doodle;
    }
    if (thumbImage) {
        captionRangeView.file.thumbnailImage = thumbImage;
    }
}

- (void) changeCurrentRangeviewFile:(RDCaption *)caption
                             tColor:(UIColor *)tColor
                         strokeColor:(UIColor *)strokeColor
                           fontName:(NSString *)fontName
                           fontCode:(NSString *)fontCode
                          typeIndex:(NSInteger)typeIndex
                          frameSize:(CGSize)frameSize
                        captionText:(NSString *)captionText
                           aligment:(RDCaptionTextAlignment)aligment
                 inAnimateTypeIndex:(NSInteger)inAnimateTypeIndex
                outAnimateTypeIndex:(NSInteger)outAnimateTypeIndex
                        pushInPoint:(CGPoint)pushInPoint
                       pushOutPoint:(CGPoint)pushOutPoint
                        captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    
    if(!captionRangeView){
        return;
    }
    captionRangeView.file.dewatermark = nil;
    if(!captionRangeView.file){
        captionRangeView.file = [[RDCaptionRangeViewFile alloc] init];
    }
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    captionRangeView.file.scale = 1.0;
    if(tColor)
        captionRangeView.file.tColor = tColor;
    if(strokeColor)
        captionRangeView.file.strokeColor = strokeColor;
    if(caption){
        captionRangeView.file.caption = caption;
        
    }
    if(captionText.length>0){
        captionRangeView.file.captionText = captionText;
        if( _captionType == 2 )
            [captionRangeView setTitle:captionText forState:UIControlStateNormal];
        else
            [captionRangeView setTitle:@"" forState:UIControlStateNormal];
    }
    if(fontName){
        captionRangeView.file.fontName = fontName;
//        captionRangeView.file.fontCode = fontCode;
    }
    
    captionRangeView.file.captiontypeIndex = typeIndex;
    captionRangeView.file.inAnimationIndex = inAnimateTypeIndex;
    captionRangeView.file.outAnimationIndex = outAnimateTypeIndex;
    captionRangeView.file.caption.tAlignment = aligment;
    //captionRangeView.file.caption.textAnimate.type = captionAnimateType;
    captionRangeView.file.caption.textAnimate.pushInPoint = pushInPoint;
    captionRangeView.file.caption.textAnimate.pushOutPoint = pushOutPoint;
    //captionRangeView.file.caption.imageAnimate.type = captionAnimateType;
    captionRangeView.file.caption.imageAnimate.pushInPoint = pushInPoint;
    captionRangeView.file.caption.imageAnimate.pushOutPoint = pushOutPoint;
    if(!CGSizeEqualToSize(CGSizeZero, frameSize)) {
        captionRangeView.file.frameSize = frameSize;
    }
}

- (void)saveCurrentRangeview:(BOOL)isScroll {
    CaptionRangeView *captionRangeView = self.currentCaptionView;
    _needShowcurrentRangeView = NO;
    //captionLastScal = 1.0;
    
    captionRangeView.hidden = NO;
    if(!captionRangeView){
        return;
    
    }
    
    [self notifyDelegate];
    
    isSeektime =  false;
    if (isScroll) {
        [self.scrollView setContentOffset:CGPointMake(captionRangeView.frame.origin.x, 0) animated:NO];
        [self notifyDelegate];
//        isScroll = false;
    }
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    if (self.startTime == 0) {
        self.startTime = 0.02;
    }
    captionRangeView.file.home = captionRangeView.frame;
    
    
    if (isScroll) {
        if( !_isJumpTail )
            [self.scrollView setContentOffset:CGPointMake(captionRangeView.frame.origin.x + captionRangeView.frame.size.width, 0) animated:NO];
    }
    
    CMTimeRange timerange = captionRangeView.file.timeRange;
    Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
    Float64 rangeDuration = CMTimeGetSeconds(timerange.duration);
    self.rangeSlider.selectedMinimum = startTime;
    self.rangeSlider.selectedMaximum = startTime + rangeDuration;
    [self.rangeSlider layoutSubviews];
//    self.rangeSlider.hidden = NO;
    isSeektime =  true;
}

- (void)saveCurrentRangeview:(NSString *)captionText
                   typeIndex:(NSInteger) index
               rotationAngle:(float)rotationAngle
                   transform:(CGAffineTransform)captionTransform
                 centerPoint:(CGPoint)centerPoint
              ppcaptionFrame:(CGRect)ppcaptionFrame
              contentsCenter:(CGRect)contentsCenter
                      tFrame:(CGRect)tFrame
                  customSize:(float)captionLastScal
                 tStretching:(BOOL)tStretching
                    fontSize:(float)fontSize
                 strokeWidth:(float)strokeWidth
                    aligment:(RDCaptionTextAlignment)aligment
             inAnimationType:(CaptionAnimateType)inAnimationType
            outAnimationType:(CaptionAnimateType)outAnimationType
                 pushInPoint:(CGPoint)pushInPoint
                pushOutPoint:(CGPoint)pushOutPoint
             widthProportion:(CGFloat)widthProportion
                   themeName:(NSString *)themeName
                       pSize:(CGSize)pSize
                        flag:(BOOL)flag
                 captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView)
        captionRangeView = self.currentCaptionView;

    _needShowcurrentRangeView = NO;
    
    self.rangeSlider.hidden = !flag;
    captionRangeView.hidden = NO;
    if(!captionRangeView){
        return;
    }
    
    [self notifyDelegate];
    
    //2019.4.12 为了解决 贴纸 添加完一个后 接着添加下一个 会出现 往前一个贴纸的开始时间seekTime 情况 屏蔽改行代码
    isSeektime =  false;
    if( !_isTiming )
        [self.scrollView setContentOffset:CGPointMake(captionRangeView.frame.origin.x, 0) animated:NO];
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    if (self.startTime == 0) {
        self.startTime = 0.02;
    }
    if(flag){
        captionRangeView.file.captionText = captionText;
        if( _captionType == 2 )
            [captionRangeView setTitle:captionText forState:UIControlStateNormal];
        else
            [captionRangeView setTitle:@"" forState:UIControlStateNormal];
        captionRangeView.file.caption.pText = captionText;
        captionRangeView.file.captiontypeIndex = index;
        captionRangeView.file.rotationAngle = rotationAngle;
        captionRangeView.file.captionTransform = captionTransform;
        captionRangeView.file.centerPoint = centerPoint;
        if(captionLastScal !=0){
            captionRangeView.file.scale = captionLastScal;
        }
        captionRangeView.file.caption.strokeWidth = strokeWidth;
        captionRangeView.file.home = captionRangeView.frame;
//        captionRangeView.file.captionText = captionRangeView.titleLabel.text;
        captionRangeView.file.tFontSize = fontSize;
        captionRangeView.file.inAnimationIndex = inAnimationType;
        captionRangeView.file.outAnimationIndex = outAnimationType;
        captionRangeView.file.caption.tFontSize = fontSize;
        captionRangeView.file.caption.size = ppcaptionFrame.size;
        captionRangeView.file.caption.stretchRect = contentsCenter;
        captionRangeView.file.caption.isStretch = tStretching;
        
        captionRangeView.file.caption.tFrame = tFrame;
        if(captionRangeView.file.selectFontItemIndex ==0)
            captionRangeView.file.caption.tFontName = [[UIFont systemFontOfSize:10] fontName];//@"Baskerville-BoldItalic";
        captionRangeView.file.caption.tAlignment = aligment;
        captionRangeView.file.caption.textAnimate.isFade = NO;
        captionRangeView.file.caption.textAnimate.inType = [RDHelpClass captionAnimateToRDCaptionAnimate: inAnimationType];
        captionRangeView.file.caption.textAnimate.outType = [RDHelpClass captionAnimateToRDCaptionAnimate: outAnimationType];
        captionRangeView.file.caption.textAnimate.pushInPoint = pushInPoint;
        captionRangeView.file.caption.textAnimate.pushOutPoint = pushOutPoint;
        captionRangeView.file.caption.imageAnimate.isFade = NO;
        captionRangeView.file.caption.imageAnimate.inType = captionRangeView.file.caption.textAnimate.inType;
        captionRangeView.file.caption.imageAnimate.outType = captionRangeView.file.caption.textAnimate.outType;
        captionRangeView.file.caption.imageAnimate.pushInPoint = pushInPoint;
        captionRangeView.file.caption.imageAnimate.pushOutPoint = pushOutPoint;
        captionRangeView.file.selectTypeId = index;
        captionRangeView.file.pSize = pSize;
        float defaultAnimationDuration = 0.5;
        if(inAnimationType == RDCaptionAnimateTypeMove){
            captionRangeView.file.caption.textAnimate.inDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/2.0);
            captionRangeView.file.caption.imageAnimate.inDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/2.0);
        }else{
            captionRangeView.file.caption.textAnimate.inDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/3.0);
            captionRangeView.file.caption.imageAnimate.inDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/3.0);
        }
        if(outAnimationType == RDCaptionAnimateTypeMove){
            captionRangeView.file.caption.textAnimate.outDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/2.0);
            captionRangeView.file.caption.imageAnimate.outDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/2.0);
        }else{
            captionRangeView.file.caption.textAnimate.outDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/3.0);
            captionRangeView.file.caption.imageAnimate.outDuration = MIN(defaultAnimationDuration, CMTimeGetSeconds(captionRangeView.file.timeRange.duration)/3.0);
        }
    }
    //2019.4.12 为了解决 贴纸 添加完一个后 接着添加下一个 会出现 往前一个贴纸的开始时间seekTime 情况 屏蔽改行代码
    isSeektime =  true;
//    if(_captionType != 2){
//        if( !_isJumpTail )
//            [self.scrollView setContentOffset:CGPointMake(captionRangeView.frame.origin.x + captionRangeView.frame.size.width, 0) animated:NO];
//
//    }
    if(!flag){
        captionRangeView = nil;
    }
    CMTimeRange timerange = captionRangeView.file.timeRange;
    Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
    Float64 rangeDuration = CMTimeGetSeconds(timerange.duration);
    self.rangeSlider.selectedMinimum = startTime;
    self.rangeSlider.selectedMaximum = startTime +rangeDuration;
    [self.rangeSlider layoutSubviews];
    self.rangeSlider.hidden = NO;
}

//画中画
- (void)saveCollageCurrentRangeview:(BOOL)isScroll
                      rotationAngle:(float)rotationAngle
                          transform:(CGAffineTransform)transform
                        centerPoint:(CGPoint)centerPoint
                              frame:(CGRect)frame
                     contentsCenter:(CGRect)contentsCenter
                              scale:(float)scale
                              pSize:(CGSize)pSize
                         thumbImage:(UIImage *)thumbImage
                   captionRangeView:(CaptionRangeView *)captionRangeView
{
    if(!captionRangeView) {
        captionRangeView = self.currentCaptionView;
    }
    if(!captionRangeView){
        return;
    }
    _needShowcurrentRangeView = NO;
    captionRangeView.hidden = NO;
    
    isSeektime =  false;
    
    if (isScroll) {
        [self.scrollView setContentOffset:CGPointMake(captionRangeView.frame.origin.x, 0) animated:NO];
        [self notifyDelegate];
//        isScroll = false;
    }
    [self notifyDelegate];

    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    if (self.startTime == 0) {
        self.startTime = 0.02;
    }
    captionRangeView.file.rotationAngle = rotationAngle;
    captionRangeView.file.captionTransform = transform;
    captionRangeView.file.centerPoint = centerPoint;
    if(scale !=0){
        captionRangeView.file.scale = scale;
    }
    captionRangeView.file.caption.size = frame.size;
    captionRangeView.file.caption.stretchRect = contentsCenter;
    captionRangeView.file.pSize = pSize;
    captionRangeView.file.home = captionRangeView.frame;
    captionRangeView.file.thumbnailImage = thumbImage;
    
    isSeektime =  true;
    if (isScroll) {
        if( !_isJumpTail )
            [self.scrollView setContentOffset:CGPointMake(captionRangeView.frame.origin.x + captionRangeView.frame.size.width, 0) animated:NO];
    }
    
    CMTimeRange timerange = captionRangeView.file.timeRange;
    Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
    Float64 rangeDuration = CMTimeGetSeconds(timerange.duration);
    self.rangeSlider.selectedMinimum = startTime;
    self.rangeSlider.selectedMaximum = startTime +rangeDuration;
    [self.rangeSlider layoutSubviews];
//    self.rangeSlider.hidden = NO;
}

- (void)checkAllCaptionSize{
    [_videoRangeView.subviews enumerateObjectsUsingBlock:^(__kindof CaptionRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([_delegate respondsToSelector:@selector(changeCaptionViewType:)]){
            NSLog(@"%s, line:%d",__func__,__LINE__);
            [_delegate changeCaptionViewType:obj];
        }
    }];
}

#if 0

- (RDCaptionAnimate *)newCaptionAnimate:(RDCaptionAnimate *)captionAnimate{
    RDCaptionAnimate *newAnimate = [[RDCaptionAnimate alloc] init];
    newAnimate.isFade = captionAnimate.isFade;
    newAnimate.fadeInDuration = captionAnimate.fadeInDuration;
    newAnimate.fadeOutDuration = captionAnimate.fadeOutDuration;
    newAnimate.type = captionAnimate.type;
    newAnimate.inDuration = captionAnimate.inDuration;
    newAnimate.outDuration = captionAnimate.outDuration;
    newAnimate.pushInPoint = captionAnimate.pushInPoint;
    newAnimate.pushOutPoint = captionAnimate.pushOutPoint;
    newAnimate.scaleIn = captionAnimate.scaleIn;
    newAnimate.scaleOut = captionAnimate.scaleOut;
    return newAnimate;
}

#endif

- (void)useToAllWithTypeToAll:(BOOL)typeToAll animationToAll:(BOOL)animationToAll colorToAll:(BOOL)colorToAll borderToAll:(BOOL)borderToAll fontToAll:(BOOL)fontToAll sizeToAll:(BOOL)sizeToAll positionToAll:(BOOL)positionToAll scale:(float)scale captionView:(CaptionRangeView *)captionRangeView{
    if(!captionRangeView) captionRangeView = self.currentCaptionView;
    _needSeekTime = NO;
    [_videoRangeView.subviews enumerateObjectsUsingBlock:^(__kindof CaptionRangeView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if(obj != captionRangeView){
            if(animationToAll){
                obj.file.caption.imageAnimate.type = captionRangeView.file.caption.imageAnimate.type;// [self newCaptionAnimate:captionRangeView.file.caption.imageAnimate];
                obj.file.caption.textAnimate.type = captionRangeView.file.caption.imageAnimate.type;// [self newCaptionAnimate:captionRangeView.file.caption.textAnimate];
                obj.file.inAnimationIndex = captionRangeView.file.inAnimationIndex;
                obj.file.outAnimationIndex = captionRangeView.file.outAnimationIndex;
            }
            if(colorToAll){
                obj.file.tColor = captionRangeView.file.tColor;
                obj.file.caption.tColor = captionRangeView.file.caption.tColor;
                obj.file.caption.textAlpha = captionRangeView.file.caption.textAlpha;
                obj.file.selectColorItemIndex = captionRangeView.file.selectColorItemIndex;
            }
            if(borderToAll){
                obj.file.strokeColor = captionRangeView.file.strokeColor;
                obj.file.caption.isStroke = captionRangeView.file.caption.isStroke;
                obj.file.caption.strokeWidth = captionRangeView.file.caption.strokeWidth;
                obj.file.caption.strokeColor = captionRangeView.file.caption.strokeColor;
                obj.file.caption.strokeAlpha = captionRangeView.file.caption.strokeAlpha;
                obj.file.selectBorderColorItemIndex = captionRangeView.file.selectBorderColorItemIndex;
            }
            if(fontToAll){
                obj.file.fontName = captionRangeView.file.fontName;
//                obj.file.fontCode = captionRangeView.file.fontCode;
                obj.file.caption.tFontName = captionRangeView.file.caption.tFontName;
                obj.file.caption.tFontSize = captionRangeView.file.caption.tFontSize;
                obj.file.selectFontItemIndex = captionRangeView.file.selectFontItemIndex;
                obj.file.caption.isBold = captionRangeView.file.caption.isBold;
                obj.file.caption.isItalic = captionRangeView.file.caption.isItalic;
                obj.file.caption.isVerticalText = captionRangeView.file.caption.isVerticalText;
                obj.file.caption.isShadow = captionRangeView.file.caption.isShadow;
                obj.file.caption.tShadowColor = captionRangeView.file.caption.tShadowColor;
                obj.file.caption.tShadowOffset = captionRangeView.file.caption.tShadowOffset;
            }
            if(sizeToAll){
                captionRangeView.file.caption.scale = scale;
                captionRangeView.file.scale = scale;
                obj.file.caption.scale = captionRangeView.file.caption.scale;
                obj.file.scale = captionRangeView.file.scale;
            }
            if(positionToAll){
                obj.file.caption.position = captionRangeView.file.caption.position;
                obj.file.alignment = captionRangeView.file.alignment;
            }
            if(typeToAll){
                obj.file.caption.imageName = captionRangeView.file.caption.imageName;
                obj.file.caption.imageFolderPath = captionRangeView.file.caption.imageFolderPath;
                obj.file.caption.duration = captionRangeView.file.caption.duration;
                obj.file.captiontypeIndex = captionRangeView.file.captiontypeIndex;
                obj.file.caption.tFontSize = captionRangeView.file.caption.tFontSize;
                
            }
            
            if(typeToAll || positionToAll || animationToAll){
                if([_delegate respondsToSelector:@selector(changeCaptionViewType:)]){
                    NSLog(@"%s, line:%d",__func__,__LINE__);
                    [_delegate changeCaptionViewType:obj];
                }
            }
         }
       
    }];
    _needSeekTime = YES;
}

- (void)refreshVideoRangeViewFromIndexPath:(NSInteger)fromIndex moveToIndex:(NSInteger)toIndex
{    
    NSMutableArray *array = [[self getTimesFor_videoRangeView] mutableCopy];
    CaptionRangeView *moveSubView = [array objectAtIndex:fromIndex];
    [array removeObjectAtIndex:fromIndex];
    [array insertObject:moveSubView atIndex:toIndex];
    
    for (CaptionRangeView *rangeView in self.videoRangeView.subviews) {
        if([rangeView isKindOfClass:[CaptionRangeView class]]){
            [rangeView removeFromSuperview];
        }
    }
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeView = (CaptionRangeView *)obj;
            rangeView.file.captionId = _videoRangeView.subviews.count + 1;
            [_videoRangeView addSubview:rangeView];
        }
    }];
}

- (void)moveEditedSubviews:(NSArray *)editedArray restoreVideoRangeView:(NSArray *)originalSubviewsArray {
    [editedArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeView = (CaptionRangeView *)obj;
            [rangeView removeFromSuperview];
        }
    }];

    [originalSubviewsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[CaptionRangeView class]]){
            CaptionRangeView *rangeView = (CaptionRangeView *)obj;
            [_videoRangeView addSubview:rangeView];
            
            if (self.currentCaptionView && [rangeView.file.caption.imageName isEqualToString:self.currentCaptionView.file.caption.imageName]) {
                self.currentCaptionView = nil;
                self.currentCaptionView = rangeView;
                self.currentCaptionView.file = rangeView.file;
            }
        }
    }];
}

- (NSMutableArray *)getEditArrays:(BOOL)flag{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
    
    NSMutableArray *tmpCaptionViews = [[NSMutableArray alloc] init];
    
    for (int i=(int)arra.count-1;i>=0;i--) {
        CaptionRangeView *obj = arra[i];
        if(obj.frame.origin.x <= _scrollView.contentOffset.x && obj.frame.origin.x+obj.frame.size.width >=_scrollView.contentOffset.x){
            [tmpCaptionViews addObject:obj];
        }
    }
    if(flag){
        if(tmpCaptionViews.count==1){
            CaptionRangeView *rangeV = [tmpCaptionViews firstObject];
            
            CMTimeRange timerange = rangeV.file.timeRange;
            Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
            Float64 duration = CMTimeGetSeconds(timerange.duration);
            self.rangeSlider.selectedMinimum = startTime;
            self.rangeSlider.selectedMaximum = startTime +duration;
            [self.rangeSlider layoutSubviews];
            self.currentCaptionView = rangeV;
            self.currentCaptionView.file = rangeV.file;
            if( self.currentCaptionView.captionType == 3 )
                self.currentCaptionView.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
            else
                self.currentCaptionView.layer.borderColor = Main_Color.CGColor;
            self.currentCaptionView.layer.borderWidth = 2;
            self.currentCaptionView.hidden = NO;
//            self.rangeSlider.hidden = NO;
            [self.videoRangeView bringSubviewToFront:self.currentCaptionView];
            self.rangeSlider.selectedMinimum = startTime;
            self.rangeSlider.selectedMaximum = startTime +duration;
            [self.rangeSlider layoutSubviews];
//            self.rangeSlider.hidden = NO;
        }
    }
    
    [arra removeAllObjects];
    arra = nil;
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [tmpCaptionViews sortUsingComparator:^NSComparisonResult(CaptionRangeView *obj1, CaptionRangeView *obj2) {
        CGFloat obj1X = obj1.file.captionId;
        CGFloat obj2X = obj2.file.captionId;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    
    return tmpCaptionViews;
}

-(BOOL)deleteFilterCaption
{
    int captionId = _videoRangeView.subviews.count;
    if( captionId > 0 ){
        CaptionRangeView * obj = ((CaptionRangeView *)_videoRangeView.subviews[captionId-1]);
        if( captionId == obj.file.captionId )
        {
            if( obj  != _timeEffectCapation )
            {
                [obj removeFromSuperview];
                if( (captionId - 2) >= 0 )
                    _currentCaptionView = _videoRangeView.subviews[captionId-2];
                return true;
            }
            else{
                captionId--;
                if( captionId > 0 )
                {
                    obj = ((CaptionRangeView *)_videoRangeView.subviews[captionId-1]);
                    [obj removeFromSuperview];
                    if( (captionId - 2) >= 0 )
                        _currentCaptionView = _videoRangeView.subviews[captionId-2];
                    return true;
                }
            }
        }
    }
    return false;
}

- (BOOL)deletedcurrentCaption{
    _needShowcurrentRangeView = NO;
    if(self.currentCaptionView){
        RDCaption * caption = self.currentCaptionView.file.caption;
        RDDewatermark *dewatermark = self.currentCaptionView.file.dewatermark;
        RDWatermark *collage = self.currentCaptionView.file.collage;
        RDWatermark *doodle = self.currentCaptionView.file.doodle;
        RDMusic *music =  self.currentCaptionView.file.music;
        RDAssetBlur *blur = self.currentCaptionView.file.blur;
        RDMosaic *mosaic = self.currentCaptionView.file.mosaic;
        RDFXFilter * fxFilter = self.currentCaptionView.file.customFilter;
        NSArray *list = [self getTimesFor_videoRangeView];
        for (CaptionRangeView *rangeView in list) {
            if(rangeView.file.captionId > self.currentCaptionView.file.captionId){
                rangeView.file.captionId --;
            }
        }
        
        if( fxFilter.FXTypeIndex == 5 )
        {
            if([_delegate respondsToSelector:@selector(deleteMaterialEffect_Effect:)]){
                [_delegate deleteMaterialEffect_Effect:nil];
            }
        }
        else if( fxFilter.FXTypeIndex == 4 )
        {
            if([_delegate respondsToSelector:@selector(deleteMaterialEffect_Effect:)]){
                [_delegate deleteMaterialEffect_Effect:fxFilter.ratingFrameTexturePath];
            }
        }
            
        [self.currentCaptionView removeFromSuperview];
        self.rangeSlider.hidden = YES;
        self.currentCaptionView = nil;
        
        if (caption || blur || mosaic || dewatermark || collage || doodle || music || fxFilter) {
            return YES;
        }
        return NO;
    }
    return NO;
}
- (CGSize)getLeftPointAndRightPoint{
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    Float64 piantouWidth  =  _piantouDuration * (self.videoRangeView.frame.size.width/duration);
    Float64 pianweiWidth  =  _pianweiDuration * (self.videoRangeView.frame.size.width/duration);
    CGSize size;
    size.width = piantouWidth;
    size.height = self.videoRangeView.frame.size.width - (pianweiWidth>0 ? pianweiWidth - 20.0 : 0);
    return size;
}

- (CaptionRangeView *)getCaptioncurrentView:(BOOL)flag{
    if(flag){
        _needShowcurrentRangeView = NO;
        return self.currentCaptionView;
    }
    for (CaptionRangeView *captionView in self.videoRangeView.subviews) {
        if(captionView.frame.origin.x<=_scrollView.contentOffset.x && captionView.frame.origin.x + captionView.frame.size.width >=_scrollView.contentOffset.x){
            return captionView;
        }
    }
    return nil;
}

- (void)getIsSlide:( float ) x atoriginX:(float) originX atIsLeft:(BOOL) isLeft
{
    float displacement = 20;
    float regionWidth = 20;
    
    float selfOriginaX = self.scrollView.contentOffset.x;
    float selforiginaX1 = self.scrollView.contentOffset.x + self.scrollView.frame.size.width/2.0;
    if( isLeft )
    {
        if( (selfOriginaX + regionWidth) >= (x+originX) )
        {
            if( (self.scrollView.contentOffset.x-displacement) >= 0 )
            {
                float Interpola =  (selfOriginaX + regionWidth) - (x+originX);
                
                if( Interpola <= (displacement/4.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 );
                }
                else if( Interpola <= (displacement/4.0*2.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*2.0;
                }
                else if( Interpola <= (displacement/4.0*3.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*3.0;
                }
                 
                self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x-displacement, self.scrollView.contentOffset.y);
            }
        }
        else if( selforiginaX1 <= (x + regionWidth) )
        {
            if( (self.scrollView.contentOffset.x+displacement) <= self.scrollView.contentSize.width  )
            {
                float Interpola =  (x + regionWidth) - selforiginaX1;
                
                if( Interpola <= (displacement/4.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 );
                }
                else if( Interpola <= (displacement/4.0*2.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*2.0;
                }
                else if( Interpola <= (displacement/4.0*3.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*3.0;
                }
                
                self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x+displacement , self.scrollView.contentOffset.y);
            }
        }
    }
    else{
        if( selforiginaX1 <= (x + regionWidth) )
        {
            if( (self.scrollView.contentOffset.x+displacement) <= self.scrollView.contentSize.width  )
            {
                float Interpola =  (x + regionWidth) - selforiginaX1;
                
                if( Interpola <= (displacement/4.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 );
                }
                else if( Interpola <= (displacement/4.0*2.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*2.0;
                }
                else if( Interpola <= (displacement/4.0*3.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*3.0;
                }
                
                self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x+displacement , self.scrollView.contentOffset.y);
            }
        }
        else if( (selfOriginaX + regionWidth) >= (x+originX) )
        {
            if( (self.scrollView.contentOffset.x-displacement) >= 0 )
            {
                float Interpola =  (selfOriginaX + regionWidth) - (x+originX);
                
                if( Interpola <= (displacement/4.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 );
                }
                else if( Interpola <= (displacement/4.0*2.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*2.0;
                }
                else if( Interpola <= (displacement/4.0*3.0) )
                {
                    displacement = displacement*( 10.0 / 4.0 / 10.0 )*3.0;
                }
                
                self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x-displacement, self.scrollView.contentOffset.y);
            }
        }
    }
}

- (CGSize)getLeftPointAndRightPoint_X{
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    Float64 piantouWidth  =   _piantouDuration * (self.videoRangeView.frame.size.width/duration);
    Float64 pianweiWidth  =   _pianweiDuration * (self.videoRangeView.frame.size.width/duration);
    CGSize size;
    size.width = piantouWidth > 0? piantouWidth : 0;
    size.height = self.videoRangeView.frame.size.width - pianweiWidth;// - 5;//20190221 wuxiaoxia -5后，添加字幕等不能播放到视频的最后
    return size;
}


- (void)setClipTimeRange:(CMTimeRange)clipTimeRange{
    _clipTimeRange = clipTimeRange;
    if(self.rangeSlider && CMTimeGetSeconds(clipTimeRange.duration) > 0)
        self.rangeSlider.maxValue = CMTimeGetSeconds(clipTimeRange.duration);
}

- (void)startMove{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(startMoveTTrangSlider:)]){
            [_delegate startMoveTTrangSlider:self];
        }
    }
}

- (void)stopMove{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(stopMoveTTrangSlider:)]){
            [_delegate stopMoveTTrangSlider:self];
        }
    }
}

-(void)dragRangeSlider:(RDTTRangeSlider *)sender didEndChangeSelectedMinimumValue:(float)selectedMinimum andMaximumValue:(float)selectedMaximum isRight:(BOOL) isRight isUpdate:(BOOL *) isUpdateSlider
{
    if (sender == self.rangeSlider){
        
        Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(selectedMinimum - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(selectedMaximum - selectedMinimum, TIMESCALE));
        
        CMTimeRange vvAssetTimeRange = self.currentCaptionView.file.collage.vvAsset.timeRange;
        
        bool isUpdate = false;
        
        if( _isCollage )
        {
            if( !isRight )
            {
                if( self.rangeSlider.minCollageValue <  selectedMinimum )
                {
                    vvAssetTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(selectedMinimum - self.rangeSlider.minCollageValue, TIMESCALE),timeRange.duration);
                }
                else{
                    self.currentCaptionView.file.collage.vvAsset.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE),timeRange.duration);
                }
            }
            else
            {
               float duration =CMTimeGetSeconds([AVURLAsset assetWithURL:_currentCaptionView.file.collage.vvAsset.url].duration);
               if( duration > CMTimeGetSeconds(CMTimeMakeWithSeconds(selectedMaximum - selectedMinimum, TIMESCALE)) )
               {
                   if( CMTimeGetSeconds(self.currentCaptionView.file.collage.vvAsset.timeRange.duration) > (selectedMaximum - selectedMinimum)  )
                   {
                       vvAssetTimeRange = CMTimeRangeMake(self.currentCaptionView.file.collage.vvAsset.timeRange.start, CMTimeMakeWithSeconds(selectedMaximum - selectedMinimum, TIMESCALE) );
                   }
                   else
                   {
                       vvAssetTimeRange = CMTimeRangeMake(CMTimeAdd(CMTimeMakeWithSeconds( (selectedMaximum - selectedMinimum) - CMTimeGetSeconds(self.currentCaptionView.file.collage.vvAsset.timeRange.duration), TIMESCALE), self.currentCaptionView.file.collage.vvAsset.timeRange.start), CMTimeMakeWithSeconds(selectedMaximum - selectedMinimum, TIMESCALE) );
                   }
               }
               else{
                   vvAssetTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), CMTimeMakeWithSeconds(selectedMaximum - selectedMinimum, TIMESCALE) );
               }
            }
        }
        
        self.currentCaptionView.file.collage.vvAsset.timeRange = vvAssetTimeRange;
        if( CMTimeGetSeconds(vvAssetTimeRange.duration) < 0 )
        {
            int b = 0;
        }
        
        CGRect rect = self.currentCaptionView.frame;
        rect.origin.x = selectedMinimum  * (self.videoRangeView.frame.size.width/duration);
        rect.size.width = (selectedMaximum-selectedMinimum)  * (self.videoRangeView.frame.size.width/duration);
        
        float width = 40;
        if( (rect.size.width - 4 ) < 40 )
        {
            width = rect.size.width - 4;
        }
        float x = rect.origin.x+rect.size.width - width - 4 + 18;
        if( !isRight )
            x = rect.origin.x + 18;
        self.rangeTimeLabel.frame = CGRectMake(x, 2, width, self.videoRangeView.frame.size.height/4.0);
        self.rangeTimeLabel.text =  [RDHelpClass timeToSecFormat: CMTimeGetSeconds(timeRange.duration)];
        
        if( _delegate )
        {
            float time = CMTimeGetSeconds(timeRange.start);
            if( isRight )
            {
                x = rect.origin.x+rect.size.width - 4 + 18;
                time += CMTimeGetSeconds(timeRange.duration);
            }
            
            x = [self.rangeSlider convertPoint:CGPointMake(x, 0) toView:self].x;
            
            if( [_delegate respondsToSelector:@selector(dragRangeSlider: dragStartTime: dragTime: isLeft: isHidden:)] )
               [_delegate dragRangeSlider:x  dragStartTime:CMTimeGetSeconds(timeRange.start) dragTime:CMTimeGetSeconds(timeRange.duration) isLeft:!isRight isHidden:NO];
        }
    }
}

-( UILabel * )rangeTimeLabel
{
    if( !_rangeTimeLabel )
    {
        _rangeTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2+5, 40, self.videoRangeView.frame.size.height/4.0)];
        _rangeTimeLabel.font = [UIFont systemFontOfSize:8];
        _rangeTimeLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        _rangeTimeLabel.textColor = [UIColor whiteColor];
        _rangeTimeLabel.textAlignment = NSTextAlignmentCenter;
        [self.rangeSlider addSubview:_rangeTimeLabel];
    }
    return _rangeTimeLabel;
}

- (void)rangeSlider:(RDTTRangeSlider *)sender didChangeSelectedMinimumValue:(float)selectedMinimum andMaximumValue:(float)selectedMaximum isRight:(bool) isRight{
    if (sender == self.rangeSlider){
        self.currentRangeviewLeftValue = selectedMinimum;
        self.currentRangeviewrightValue = selectedMaximum;
        Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
        
        CGRect rect = self.currentCaptionView.frame;
        rect.origin.x = selectedMinimum  * (self.videoRangeView.frame.size.width/duration);
        rect.size.width = (selectedMaximum-selectedMinimum)  * (self.videoRangeView.frame.size.width/duration);
        self.currentCaptionView.frame = rect;
        
        //20170413解决在iPad mini上划不动的bug
        self.leftOverlayView.frame = CGRectMake(self.videoRangeView.frame.origin.x-20, self.leftOverlayView.frame.origin.y, self.currentCaptionView.frame.origin.x - 20, self.leftOverlayView.frame.size.height);
        self.rightOverlayView.frame = CGRectMake(20+self.videoRangeView.frame.origin.x + self.currentCaptionView.frame.origin.x+self.currentCaptionView.frame.size.width + 10, self.rightOverlayView.frame.origin.y, self.videoRangeView.frame.size.width - (self.currentCaptionView.frame.origin.x + self.currentCaptionView.frame.size.width), self.rightOverlayView.frame.size.height);
        float span = MAX(10, MIN(30, self.currentCaptionView.frame.origin.x));
        self.middleOverlayView.frame = CGRectMake(self.leftOverlayView.frame.origin.x + self.leftOverlayView.frame.size.width + span + 10, 0, self.rightOverlayView.frame.origin.x - (self.leftOverlayView.frame.origin.x + self.leftOverlayView.frame.size.width + span+20) - 20, self.middleOverlayView.frame.size.height);
        CGRect moveCaptionViewBtnFrame = rect;
        moveCaptionViewBtnFrame.origin.x += 36;
        if( moveCaptionViewBtnFrame.size.width >= 36 )
            moveCaptionViewBtnFrame.size.width -= 36;
        else
            moveCaptionViewBtnFrame.size.width = 0;
        self.rangeSlider.moveCaptionViewBtn.frame = moveCaptionViewBtnFrame;
        
        self.currentCaptionView.file.home = self.currentCaptionView.frame;
        self.currentCaptionView.file.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(self.currentRangeviewLeftValue - _piantouDuration, TIMESCALE), CMTimeMakeWithSeconds(self.currentRangeviewrightValue - self.currentRangeviewLeftValue, TIMESCALE));
       if (rect.origin.x + rect.size.width >= _videoRangeView.frame.size.width) {
           float duration = _videoCore.duration;
           _currentCaptionView.file.timeRange = CMTimeRangeMake(_currentCaptionView.file.timeRange.start, CMTimeMake(duration * TIMESCALE - _currentCaptionView.file.timeRange.start.value, TIMESCALE));
       }
        float width = 40;
        if( (rect.size.width - 4 ) < 40 )
        {
            width = (rect.size.width - 4 );
        }
        self.rangeTimeLabel.frame = CGRectMake(rect.origin.x+rect.size.width - width - 4 + 18, 2, width, self.videoRangeView.frame.size.height/4.0);
        self.rangeTimeLabel.text =  [RDHelpClass timeToSecFormat: CMTimeGetSeconds(self.currentCaptionView.file.timeRange.duration)];
        if( _delegate )
        {
            if( [_delegate respondsToSelector:@selector(dragRangeSlider: dragStartTime: dragTime: isLeft: isHidden:)] )
                [_delegate dragRangeSlider:rect.origin.x+rect.size.width - width - 4 + 18  dragStartTime:CMTimeGetSeconds(self.currentCaptionView.file.timeRange.start) dragTime:CMTimeGetSeconds(self.currentCaptionView.file.timeRange.duration)
                                 isLeft:!isRight isHidden:YES];
        }
    }
}
- (void)rangeSlider:(RDTTRangeSlider *)sender didEndChangeSelectedMinimumValue:(float)selectedMinimum andMaximumValue:(float)selectedMaximum{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(didEndChangeSelectedMinimumValue_maximumValue)]){
            [_delegate didEndChangeSelectedMinimumValue_maximumValue];
        }
    }
}

- (CGRect) touchRectForHandle:(CGPoint) point
{
    float xPadding = 10;
    float yPadding = 10; //(self.bounds.size.height-touchRect.size.height)/2.0f
    
    CGRect touchRect = CGRectMake(point.x, point.y, 10, 10);
    touchRect.origin.x -= xPadding/2.0;
    touchRect.origin.y -= yPadding/2.0;
    touchRect.size.height += xPadding;
    touchRect.size.width += yPadding;
    return touchRect;
}

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    
    
    
    if(CGRectContainsPoint([self touchRectForHandle:self.currentCaptionView.frame.origin], touchPoint))
    {

    }
    
    if(CGRectContainsPoint([self touchRectForHandle:CGPointMake(self.currentCaptionView.frame.origin.x + self.currentCaptionView.frame.size.width, self.currentCaptionView.frame.origin.y)], touchPoint))
    {
        
    }
    return YES;
}


- (NSMutableArray *)getTimesFor_videoRangeView{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
    
    if( _isFX )
        return arra;
    
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [arra sortUsingComparator:^NSComparisonResult(CaptionRangeView *obj1, CaptionRangeView *obj2) {
       CGFloat obj1X = obj1.file.captionId;
        CGFloat obj2X = obj2.file.captionId;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    
    return arra;//[_videoRangeView.subviews mutableCopy];
}

- (NSMutableArray *)getCaptionsViewForcurrentTime:(BOOL)flag{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
 
    NSMutableArray *tmpCaptionViews = [[NSMutableArray alloc] init];
    
    for (int i=(int)arra.count-1;i>=0;i--) {
        CaptionRangeView *obj = arra[i];
        if(obj.frame.origin.x <= _scrollView.contentOffset.x && obj.frame.origin.x+obj.frame.size.width >=_scrollView.contentOffset.x){
            [tmpCaptionViews addObject:obj];
        }
    }
    if(flag){
        if(tmpCaptionViews.count==1){
            CaptionRangeView *rangeV = [tmpCaptionViews firstObject];
            
            CMTimeRange timerange = rangeV.file.timeRange;
            Float64 startTime = CMTimeGetSeconds(timerange.start) + _piantouDuration;
            Float64 duration = CMTimeGetSeconds(timerange.duration);
            self.rangeSlider.selectedMinimum = startTime;
            self.rangeSlider.selectedMaximum = startTime +duration;
            [self.rangeSlider layoutSubviews];
            self.currentCaptionView = rangeV;
            self.currentCaptionView.file = rangeV.file;
            if( self.currentCaptionView.captionType == 3 )
                self.currentCaptionView.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
            else
                self.currentCaptionView.layer.borderColor = Main_Color.CGColor;
            self.currentCaptionView.layer.borderWidth = 2;
            self.currentCaptionView.hidden = NO;
//            self.rangeSlider.hidden = NO;
            [self.videoRangeView bringSubviewToFront:self.currentCaptionView];
            self.rangeSlider.selectedMinimum = startTime;
            self.rangeSlider.selectedMaximum = startTime +duration;
            [self.rangeSlider layoutSubviews];
//            self.rangeSlider.hidden = NO;
        }
    }
    
    //self.rangeSlider.hidden = NO;
    
    [arra removeAllObjects];
    arra = nil;
    
    if( _isFX )
        return tmpCaptionViews;
    
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [tmpCaptionViews sortUsingComparator:^NSComparisonResult(CaptionRangeView *obj1, CaptionRangeView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    
    return tmpCaptionViews;//[_videoRangeView.subviews mutableCopy];
}

- (NSMutableArray *)getTimesFor_videoRangeView_withTime{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
    
    if( _isFX )
        return arra;
    
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [arra sortUsingComparator:^NSComparisonResult(CaptionRangeView *obj1, CaptionRangeView *obj2) {
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    return arra;//[_videoRangeView.subviews mutableCopy];
}

- (void)clearCaptionRangeVew{
    [self.videoRangeView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
        }
        [obj removeFromSuperview];
        obj = nil;
    }];
}

- (void)clear{
    [self.frameView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
        }
    }];
}

- (bool)setProgress:(float)progress animated:(BOOL)animated{
    if (isnan(progress)) {
        progress = 0;
    }
    _progress = progress;
    float frame = progress*CMTimeGetSeconds(self.clipTimeRange.duration) * (_videoRangeView.frame.size.width/CMTimeGetSeconds(self.clipTimeRange.duration));
    
    if( _isTiming )
    {
        if( frame < self.scrollView.contentOffset.x )
            return false;
    }
    if(!isnan(frame)){
        [self.scrollView setContentOffset:CGPointMake(frame, 0) animated:animated];
    }
    return true;
}

- (void)setFrameRect:(CGRect)rect{
    self.frame = rect;
    _allImages = [[NSMutableArray alloc] init];
    float itemWidth = 100;
    for (int i = 0;i<self.frameView.subviews.count;i++) {
        UIImageView *imagev = self.frameView.subviews[i];
        [_allImages addObject:imagev.image];
        itemWidth = imagev.frame.size.width;
    }
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
//    contentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame)-5)];
//    contentImageView.backgroundColor = TOOLBAR_COLOR;
//    [self addSubview:contentImageView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    @try {
        [self addSubview:self.scrollView];
    }
    @catch (NSException *exception) {
        
    }
    self.scrollView.tag = self.tag;
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    
    self.contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    self.contentView.userInteractionEnabled = YES;
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    
    CGFloat ratio = 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2.0, 5, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio - 5)];
    [self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];
    
    
    self.videoRangeView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2.0, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.videoRangeView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.videoRangeView];
    [self.videoRangeView.layer setBorderColor:UIColorFromRGB(0xffffff).CGColor];
    [self.videoRangeView.layer setBorderWidth:0];
    
    
    [self refreshChildrenFrames:itemWidth];
    
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetWidth(self.frameView.frame) : CGRectGetWidth(self.frame)) - (self.minLength * self.widthPerSecond);
    self.overlayWidth = kWIDTH - 100;
    // add left overlay view
    self.leftOverlayView = [[UIView alloc] initWithFrame:CGRectMake(10 - self.overlayWidth, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    CGRect leftThumbFrame = CGRectMake(self.overlayWidth-10, 0, 10, CGRectGetHeight(self.frameView.frame));
    if (self.leftThumbImage) {
        self.leftThumbView = [[RDICGThumbView alloc] initWithFrame:leftThumbFrame thumbImage:self.leftThumbImage];
    }else {
        self.leftThumbView = [[RDICGThumbView alloc] initWithFrame:leftThumbFrame color:self.themeColor right:NO];
    }
    
    [self.leftThumbView.layer setMasksToBounds:YES];
    [self.leftOverlayView addSubview:self.leftThumbView];
    [self.leftOverlayView setUserInteractionEnabled:YES];
    
    // add right overlay view
    CGFloat rightViewFrameX;
    rightViewFrameX = CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    
    if (self.rightThumbImage) {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) color:self.themeColor right:YES];
    }
    
    [self.rightThumbView.layer setMasksToBounds:YES];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    
    
    self.rangeSlider = [[RDTTRangeSlider alloc] initWithFrame:CGRectMake(self.videoRangeView.frame.origin.x-16, 5, self.videoRangeView.frame.size.width+32 + 22 , self.videoRangeView.frame.size.height - 5)];
    self.rangeSlider.minValue = 0;
    self.rangeSlider.maxValue = _videoCore.duration;
    self.rangeSlider.selectedMinimum = 0;
    self.rangeSlider.selectedMaximum = kTIMEDURATION;
    self.rangeSlider.hidden = YES;
    self.rangeSlider.delegate = self;
    [self.scrollView addSubview:self.rangeSlider];
    
    CGRect middlerect = self.videoRangeView.frame;
    _middleOverlayView = [[UIView alloc] initWithFrame:middlerect];
    self.leftThumbView.hidden = YES;
    self.rightThumbView.hidden = YES;
    self.leftOverlayView.hidden = NO;
    self.rightOverlayView.hidden = NO;
    [self.scrollView addSubview:self.rightOverlayView];
    [self.scrollView addSubview:self.leftOverlayView];
    [self.scrollView addSubview:self.middleOverlayView];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self.middleOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self updateBorderFrames];
    [self notifyDelegate];
    [self setNeedsLayout];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    [_frameView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
        }
        [obj removeFromSuperview];
    }];
    _delegate = nil;
}

//固定长度截取
- (void)addFrames:(UIImage *)thumbImage picWidth:(float) picWidth
{
    float  preferredWidth = 0;
    Float64 duration = _videoCore.duration;
    
    float endWidth = picWidth;
    
    if(self.thumbTimes > 0){
        for (int i=0; i<self.thumbTimes; i++) {
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:thumbImage];
            tmp.tag = i+1;
            //NSLog(@"tmp.tag = %ld",tmp.tag);
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = i*picWidth;
            
            if( i != (self.thumbTimes-1) )
                currentFrame.size.width = picWidth;
            else
            {
                float duration = _videoCore.duration*1000.0;
                float fRemain = ( (int)duration )%( (int)(_trimDuration_OneSpecifyTime/2.0*1000) );
                endWidth = endWidth*( (((float)fRemain)/1000.0)/(_trimDuration_OneSpecifyTime/2.0) );
                currentFrame.size.width = endWidth;
            }
            
            currentFrame.size.height = CGRectGetHeight(self.frameView.frame);
            
            preferredWidth += currentFrame.size.width;
            
//            if( i == self.thumbTimes-1){
//                currentFrame.size.width-=6;
//            }
            tmp.frame = currentFrame;
            tmp.contentMode = UIViewContentModeScaleAspectFill;
            tmp.layer.masksToBounds = YES;
            @try {
                [self.frameView addSubview:tmp];
                
            } @catch (NSException *exception) {
                
            }
            UIView *temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tmp.frame.size.width, tmp.frame.size.height)];
            temp.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
            [tmp addSubview:temp];
        }
    }
    float scrollWidth = self.frame.size.width;
    CGFloat screenWidth = CGRectGetWidth(self.frame);
    
    //    [self.frameView setFrame:CGRectMake(scrollWidth/2-(self.frame.origin.x/2.0), 0, picWidth* self.thumbTimes - 6, CGRectGetHeight(self.frameView.frame))];
    self.frameView.frame = CGRectMake((scrollWidth - picWidth*2.0)/2.0+3, _frameView.frame.origin.y
                                      , picWidth* (self.thumbTimes-1)+endWidth, _frameView.frame.size.height);
//    [self.videoRangeView setFrame:self.frameView.frame];
        [self.videoRangeView setFrame:CGRectMake(self.frameView.frame.origin.x, self.videoRangeView.frame.origin.y, self.frameView.frame.size.width, self.videoRangeView.frame.size.height)];
    CGFloat contentViewFrameWidth = duration <= self.maxLength + 0.5 ? screenWidth + 30 : CGRectGetWidth(self.frameView.frame);//frameViewFrameWidth;
    
    float width = contentViewFrameWidth + scrollWidth - picWidth*2.0;
    
    [self.contentView setFrame:CGRectMake(0, 0, width, CGRectGetHeight(self.contentView.frame))];
    
    if( width <= self.scrollView.frame.size.width )
        width = self.scrollView.frame.size.width+1;
    
    CGSize size = CGSizeMake(width, self.contentView.frame.size.height);
    
    [self.scrollView setContentSize:size];
    self.contentSize = size;
}

- (void)resetSubviews:(UIImage *)thumbImage  picWidth:(float) picWidth
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    _loadImageFinish = NO;
    if(duration >= 10){
        self.maxLength = 5;
    }else{
        self.maxLength = duration - 1;//20161012 bug39
    }
    
    if (self.minLength == 0) {
        self.minLength = 0;
    }
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
//    contentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame)-5)];
//    contentImageView.backgroundColor = TOOLBAR_COLOR;
//    [self addSubview:contentImageView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    @try {
        [self addSubview:self.scrollView];
    }
    @catch (NSException *exception) {
        
    }
    self.scrollView.tag = self.tag;
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setBounces:YES];
    
    self.contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    self.contentView.userInteractionEnabled = YES;
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    
    CGFloat ratio = 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 5, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio-5)];
    [self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];
    
    self.videoRangeView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.videoRangeView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.videoRangeView];
    [self.videoRangeView.layer setBorderColor:UIColorFromRGB(0xffffff).CGColor];
    [self.videoRangeView.layer setBorderWidth:0];
    
    [self addFrames:thumbImage picWidth:picWidth];
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetWidth(self.frameView.frame) : CGRectGetWidth(self.frame)) - (self.minLength * self.widthPerSecond);
    self.overlayWidth = kWIDTH - 100;
    // add left overlay view
    self.leftOverlayView = [[UIView alloc] initWithFrame:CGRectMake(10 - self.overlayWidth, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    CGRect leftThumbFrame = CGRectMake(self.overlayWidth-10, 0, 10, CGRectGetHeight(self.frameView.frame));
    if (self.leftThumbImage) {
        self.leftThumbView = [[RDICGThumbView alloc] initWithFrame:leftThumbFrame thumbImage:self.leftThumbImage];
    }else {
        self.leftThumbView = [[RDICGThumbView alloc] initWithFrame:leftThumbFrame color:self.themeColor right:NO];
    }
    [self.leftThumbView.layer setMasksToBounds:YES];
    [self.leftOverlayView addSubview:self.leftThumbView];
    [self.leftOverlayView setUserInteractionEnabled:YES];
    
    // add right overlay view
    CGFloat rightViewFrameX;
    rightViewFrameX = CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    if (self.rightThumbImage) {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) color:self.themeColor right:YES];
    }
    [self.rightThumbView.layer setMasksToBounds:YES];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    
    
    
    self.rangeSlider = [[RDTTRangeSlider alloc] initWithFrame:CGRectMake(self.videoRangeView.frame.origin.x-16, 5, self.videoRangeView.frame.size.width+32, self.videoRangeView.frame.size.height - 5)];
    self.rangeSlider.minValue = 0;
    self.rangeSlider.maxValue = _videoCore.duration;
    self.rangeSlider.selectedMinimum = 0;
    self.rangeSlider.selectedMaximum = kTIMEDURATION;
    self.rangeSlider.hidden = YES;
    self.rangeSlider.delegate = self;
    [self.scrollView addSubview:self.rangeSlider];
    
    CGRect rect = self.videoRangeView.frame;
    _middleOverlayView = [[UIView alloc] initWithFrame:rect];
    self.leftThumbView.hidden = YES;
    self.rightThumbView.hidden = YES;
    self.leftOverlayView.hidden = NO;
    self.rightOverlayView.hidden = NO;
    [self.scrollView addSubview:self.rightOverlayView];
    [self.scrollView addSubview:self.leftOverlayView];
    [self.scrollView addSubview:self.middleOverlayView];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    [self.middleOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.0]];
    
    [self updateBorderFrames];
    [self notifyDelegate];
}

@end
