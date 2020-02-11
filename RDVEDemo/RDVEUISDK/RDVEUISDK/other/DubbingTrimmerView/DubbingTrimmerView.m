//
//  ICGVideoTrimmerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "DubbingTrimmerView.h"
#import "RDICGThumbView.h"
#import "RDICGRulerView.h"

#define kTIMEDURATION 0.0

@interface DubbingTrimmerView() <UIScrollViewDelegate>
{
    BOOL    _needShowBtn;
    UIAlertView         *commonAlertView;   //20170503 wuxiaoxia 防止内存泄露
}
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (strong, nonatomic) UIView *leftOverlayView;
@property (strong, nonatomic) UIView *rightOverlayView;
@property (strong, nonatomic) RDICGThumbView *leftThumbView;
@property (strong, nonatomic) RDICGThumbView *rightThumbView;

@property (strong, nonatomic) UIView *topBorder;
@property (strong, nonatomic) UIView *bottomBorder;

@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat endTime;
@property (strong, nonatomic) NSMutableArray *times;

@property (nonatomic) CGFloat widthPerSecond;

@property (nonatomic) CGPoint leftStartPoint;

@property (nonatomic) CGPoint rightStartPoint;

@property (nonatomic) CGFloat overlayWidth;

@property (nonatomic) NSMutableArray *allImages;

@property (assign,nonatomic)BOOL isdragging;

@property (assign,nonatomic)BOOL endScroll;

@property (strong, nonatomic) UIView    *currentThumbView;

@property (strong, nonatomic) DubbingRangeView *currentDubbingView;

@end

@implementation DubbingTrimmerView

#pragma mark - Initiation


- (instancetype)initWithFrame:(CGRect)frame videoCore:(RDVECore *)videoCore
{
    self = [super initWithFrame:frame];
    if (self) {
        _videoCore = videoCore;
        _needShowBtn = YES;
    }
    return self;
}

#pragma mark - Private methods

- (void)resetSubviews:(UIImage *)thumbImage
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
 
    _loadImageFinish = NO;
    if(duration >= 10){
        self.maxLength = 5;
    }else{
        self.maxLength = duration - 1;
    }
    
    if (self.minLength == 0) {
        self.minLength = 0;
    }
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    [self addSubview:self.scrollView];
    self.scrollView.tag = self.tag;
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    
   _contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    self.contentView.userInteractionEnabled = YES;
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    
    CGFloat ratio = 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];
    

    self.videoRangeView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.videoRangeView.layer setMasksToBounds:YES];
    self.videoRangeView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.videoRangeView];
    [self.videoRangeView.layer setBorderColor:UIColorFromRGB(0xffffff).CGColor];
    [self.videoRangeView.layer setBorderWidth:0];
    
    UITapGestureRecognizer *tapVideoRangeViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchesVideoRangeView:)];
    [self.videoRangeView addGestureRecognizer:tapVideoRangeViewGesture];
    
    [self addFrames:thumbImage];
    
    
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetWidth(self.frameView.frame) : CGRectGetWidth(self.frame)) - (self.minLength * self.widthPerSecond);
    
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
    UIPanGestureRecognizer *leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftOverlayView:)];
    [self.leftOverlayView addGestureRecognizer:leftPanGestureRecognizer];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
    [self addSubview:self.leftOverlayView];
    
    // add right overlay view
    CGFloat rightViewFrameX = CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    
    if (self.rightThumbImage) {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) color:self.themeColor right:YES];
    }
    
    [self.rightThumbView.layer setMasksToBounds:YES];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightOverlayView:)];
    [self.rightOverlayView addGestureRecognizer:rightPanGestureRecognizer];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
    [self addSubview:self.rightOverlayView];
    self.leftThumbView.hidden = YES;
    self.rightThumbView.hidden = YES;
    self.leftOverlayView.hidden = YES;
    self.rightOverlayView.hidden = YES;
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

- (void)notifyDelegate
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
//    NSLog(@"self.scrollView.contentOffset.x:%f",self.scrollView.contentOffset.x);
    
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);

    self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - 10) / self.widthPerSecond;
    if([_delegate respondsToSelector:@selector(trimmerView:didChangeLeftPosition:rightPosition:)]){
        [_delegate trimmerView:self didChangeLeftPosition:MAX(self.startTime, 0.001) rightPosition:MAX(self.endTime, self.startTime)];
    }
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
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    [self addSubview:self.scrollView];
    self.scrollView.tag = self.tag;
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    
    self.contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    self.contentView.userInteractionEnabled = YES;
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    
    CGFloat ratio = 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];
    
    
    self.videoRangeView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame)-20, CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.videoRangeView.layer setMasksToBounds:YES];
    self.videoRangeView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.videoRangeView];
    [self.videoRangeView.layer setBorderColor:UIColorFromRGB(0xffffff).CGColor];
    [self.videoRangeView.layer setBorderWidth:0];
    
    UITapGestureRecognizer *tapVideoRangeViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchesVideoRangeView:)];
    [self.videoRangeView addGestureRecognizer:tapVideoRangeViewGesture];
    
    [self refreshChildrenFrames:itemWidth];
    
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetWidth(self.frameView.frame) : CGRectGetWidth(self.frame)) - (self.minLength * self.widthPerSecond);
    
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
    UIPanGestureRecognizer *leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftOverlayView:)];
    [self.leftOverlayView addGestureRecognizer:leftPanGestureRecognizer];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
    [self addSubview:self.leftOverlayView];
    
    // add right overlay view
    CGFloat rightViewFrameX = CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 0, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    
    if (self.rightThumbImage) {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[RDICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 10, CGRectGetHeight(self.frameView.frame)) color:self.themeColor right:YES];
    }
    
    [self.rightThumbView.layer setMasksToBounds:YES];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightOverlayView:)];
    [self.rightOverlayView addGestureRecognizer:rightPanGestureRecognizer];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.8]];
    [self addSubview:self.rightOverlayView];
    self.leftThumbView.hidden = YES;
    self.rightThumbView.hidden = YES;
    self.leftOverlayView.hidden = YES;
    self.rightOverlayView.hidden = YES;
    [self updateBorderFrames];
    [self notifyDelegate];
}

- (void)addFrames:(UIImage *)thumbImage
{
    _allImages = [[NSMutableArray alloc] init];
    float  preferredWidth = 0;
    Float64 duration = self.videoCore.duration;
    
    float   picWidth = CGRectGetHeight(self.frameView.frame);
//    if(thumbImage){
//        picWidth = CGRectGetHeight(self.frameView.frame) * (thumbImage.size.width/thumbImage.size.height);
//    }
    if(self.thumbImageTimes > 0){
        for (int i=0; i<self.thumbImageTimes; i++) {
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:thumbImage];
            tmp.tag = i+1;
            
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = i*picWidth;
            
            currentFrame.size.width = picWidth;
            
            currentFrame.size.height = CGRectGetHeight(self.frameView.frame);
            
            preferredWidth += currentFrame.size.width;
            
            if( i == self.thumbImageTimes-1){
                currentFrame.size.width-=6;
            }
            tmp.frame = currentFrame;
            tmp.contentMode = UIViewContentModeScaleAspectFill;
            tmp.layer.masksToBounds = YES;
            [self.frameView addSubview:tmp];
            UIView *temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tmp.frame.size.width, tmp.frame.size.height)];
            temp.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
            [tmp addSubview:temp];
            
        }
    }
    float scrollWidth = self.frame.size.width;
    CGFloat screenWidth = CGRectGetWidth(self.frame);
    
    [self.frameView setFrame:CGRectMake((scrollWidth + _rightSpace - self.frame.origin.x)/2.0, 0, picWidth* self.thumbImageTimes, CGRectGetHeight(self.frameView.frame))];
    [self.videoRangeView setFrame:self.frameView.frame];
    
    CGFloat contentViewFrameWidth = duration <= self.maxLength + 0.5 ? screenWidth + 30 : CGRectGetWidth(self.frameView.frame);//frameViewFrameWidth;
    
    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth + scrollWidth-5, CGRectGetHeight(self.contentView.frame))];
    
    CGSize size = self.contentView.frame.size;
    
    [self.scrollView setContentSize:size];
    self.contentSize = size;
    
}
- (void)refreshChildrenFrames:(float)itemWidth
{
    float  preferredWidth = 0;
    Float64 duration = self.videoCore.duration;
    
    float   picWidth = itemWidth;
    if(self.thumbImageTimes > 0){
        for (int i=0; i<self.thumbImageTimes; i++) {
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:_allImages[i]];
            tmp.tag = i+1;
            
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = i*picWidth;
            
            currentFrame.size.width = picWidth;
            
            currentFrame.size.height = CGRectGetHeight(self.frameView.frame);
            
            preferredWidth += currentFrame.size.width;
            
            if( i == self.thumbImageTimes-1){
                currentFrame.size.width-=6;
            }
            tmp.frame = currentFrame;
            tmp.contentMode = UIViewContentModeScaleAspectFill;
            tmp.layer.masksToBounds = YES;
            [self.frameView addSubview:tmp];
            UIView *temp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tmp.frame.size.width, tmp.frame.size.height)];
            temp.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
            [tmp addSubview:temp];
            
        }
    }
    float scrollWidth = self.frame.size.width;
    CGFloat screenWidth = CGRectGetWidth(self.frame);
    
    [self.frameView setFrame:CGRectMake(scrollWidth/2-(self.frame.origin.x/2.0), 0, picWidth* self.thumbImageTimes, CGRectGetHeight(self.frameView.frame))];
    [self.videoRangeView setFrame:self.frameView.frame];
    
    CGFloat contentViewFrameWidth = duration <= self.maxLength + 0.5 ? screenWidth + 30 : CGRectGetWidth(self.frameView.frame);//frameViewFrameWidth;
    
    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth + scrollWidth-5, CGRectGetHeight(self.contentView.frame))];
    
    CGSize size = self.contentView.frame.size;
    
    [self.scrollView setContentSize:size];
    self.contentSize = size;
    
}

- (void)refreshThumbImage:(NSInteger)index thumbImage:(UIImage *)thumbImage{
    @autoreleasepool {
        if(thumbImage)
            [((UIImageView *)[self.frameView viewWithTag:index + 1]) setImage:thumbImage];
        if(index==self.times.count-1){
            _loadImageFinish = YES;
        }
        thumbImage = nil;
    }
    
}

- (BOOL)isRetina
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0));
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    
    if (duration <= self.maxLength + 0.5) {
        [UIView animateWithDuration:0.3 animations:^{
            [scrollView setContentOffset:CGPointZero];
        }];
    }
    [self notifyDelegate];
    if (_needShowBtn) {
        BOOL selectThumbRangeView = NO;
        for (id view in self.videoRangeView.subviews) {
            if([view isKindOfClass:[DubbingRangeView class]]){
                DubbingRangeView *rangeV = (DubbingRangeView *)view;
                if(rangeV.frame.origin.x < self.scrollView.contentOffset.x && self.scrollView.contentOffset.x<rangeV.frame.origin.x + rangeV.frame.size.width){
                    selectThumbRangeView = YES;
                    rangeV.layer.borderColor = [UIColor whiteColor].CGColor;
                    rangeV.layer.borderWidth = 2;
                    self.currentDubbingView = rangeV;
                }else{
                    rangeV.layer.borderColor = [UIColor clearColor].CGColor;
                    rangeV.layer.borderWidth = 0;
                }
            }
        }
        if(_delegate){
            if([_delegate respondsToSelector:@selector(touchescurrentdubbingView:flag:)]){
                [_delegate touchescurrentdubbingView:self.currentDubbingView flag:!selectThumbRangeView];
            }
        }
    
    }
}


//开始滑动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _isdragging = YES;
    if(_delegate){
        if([_delegate respondsToSelector:@selector(dubbingScrollViewWillBegin:)]){
            [_delegate dubbingScrollViewWillBegin:self];
        }
    }
}

//滚动停止
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(_isdragging){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(dubbingScrollViewWillEnd:startTime:endTime:)]){
                [_delegate dubbingScrollViewWillEnd:self startTime:self.startTime endTime:self.endTime];
            }
        }
    }
    _isdragging = NO;
}
//手指停止滑动
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if(!decelerate){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(dubbingScrollViewWillEnd:startTime:endTime:)]){
                [_delegate dubbingScrollViewWillEnd:self startTime:self.startTime endTime:self.endTime];
            }
        }
        _isdragging = NO;
    }
}
- (CGSize)getLeftPointAndRightPoint_X{
    
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    Float64 piantouWidth  =   _piantouDuration * (self.videoRangeView.frame.size.width/duration);
    Float64 pianweiWidth  =   _pianweiDuration * (self.videoRangeView.frame.size.width/duration);
    CGSize size;
    size.width = piantouWidth > 0? piantouWidth : 0;
    size.height = self.videoRangeView.frame.size.width - pianweiWidth;
    return size;
}
- (RdCanAddDubbingType)checkCanAddDubbing{
    CGSize size = [self getLeftPointAndRightPoint_X];
    if(self.scrollView.contentOffset.x>=size.height-5){
        return (_pianweiDuration > 0 ? kCannotAddDubbingforPianwei : kCannotAddDubbing);
    }
    if(self.scrollView.contentOffset.x<=size.width-15){
        return (_piantouDuration > 0 ? kCannotAddDubbingforPiantou : kCanAddDubbing);
    }
    
    float rightX = 0.0;
    NSArray *arr = [self getTimesFor_videoRangeView_withTime];
    for (int i=0; i<arr.count;i++) {
        DubbingRangeView *dubb = arr[i];
        if(i==arr.count-1){
            if(dubb.frame.origin.x >= self.scrollView.contentOffset.x || dubb.frame.origin.x + dubb.frame.size.width >= self.scrollView.contentOffset.x){
                rightX = dubb.frame.origin.x;
                if (!self.currentDubbingView) {
                    self.currentDubbingView = dubb;
                }
            }else {
                Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
                Float64 pianweiWidth  =   _pianweiDuration * (self.videoRangeView.frame.size.width/duration);
                rightX = self.videoRangeView.frame.size.width - pianweiWidth;
            }
        }else{
            if(dubb.frame.origin.x >= self.scrollView.contentOffset.x || dubb.frame.origin.x + dubb.frame.size.width >= self.scrollView.contentOffset.x){
                rightX = dubb.frame.origin.x;
                if (!self.currentDubbingView) {
                    self.currentDubbingView = dubb;
                }
                break;
            }
        }
    }
    float diffTime = (rightX - self.scrollView.contentOffset.x)/(float)self.videoRangeView.frame.size.width*CMTimeGetSeconds(self.clipTimeRange.duration) - _piantouDuration;
    if (arr.count > 0 && diffTime <= 0.0) {
        return kCannotAddDubbing;
    }
    return kCanAddDubbing;
}
- (void)addDubbing{
    _needShowBtn = NO;
    DubbingRangeView *dubbingView = [[DubbingRangeView alloc] initWithFrame:CGRectMake(self.scrollView.contentOffset.x, 0, 1, self.videoRangeView.frame.size.height)];
    [dubbingView addTarget:self action:@selector(touchescurrentdubbingView:) forControlEvents:UIControlEventTouchUpInside];
    self.videoRangeView.userInteractionEnabled = YES;
    float diff = (dubbingView.frame.origin.x/(float)self.videoRangeView.frame.size.width);
    float totald = CMTimeGetSeconds(self.clipTimeRange.duration);
    dubbingView.dubbingStartTime = CMTimeMakeWithSeconds(diff*totald - _piantouDuration, TIMESCALE);
    dubbingView.dubbingIndex = [[self.videoRangeView subviews] count];
    [self.videoRangeView addSubview:dubbingView];
    
    self.currentDubbingView = dubbingView;
    
}

- (void)addDubbingTarget:(DubbingRangeView *)view {
    [view addTarget:self action:@selector(touchescurrentdubbingView:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)touchescurrentdubbingView:(DubbingRangeView *)sender{
   for (id view in self.videoRangeView.subviews) {
        if([view isKindOfClass:[DubbingRangeView class]]){
            DubbingRangeView *rangeV = (DubbingRangeView *)view;
            if(rangeV == sender){
                self.currentDubbingView = rangeV;
                self.currentDubbingView.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
                self.currentDubbingView.layer.borderWidth = 1;
                self.currentDubbingView.hidden = NO;
                if(_delegate){
                    if([_delegate respondsToSelector:@selector(touchescurrentdubbingView:flag:)]){
                        [_delegate touchescurrentdubbingView:self.currentDubbingView flag:NO];
                    }
                }
            }else{
                rangeV.layer.borderColor = [UIColor clearColor].CGColor;
                rangeV.layer.borderWidth = 0;
                rangeV.hidden = NO;
            }
        }
    }
}

- (void)touchesVideoRangeView:(UITapGestureRecognizer *)gesture{
    if(gesture.view == self.videoRangeView){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(touchescurrentdubbingView:flag:)]){
                [_delegate touchescurrentdubbingView:self.currentDubbingView flag:YES];
                self.currentDubbingView.layer.borderColor = [UIColor clearColor].CGColor;
                self.currentDubbingView.layer.borderWidth = 0;
            }
        }
    }
}

- (BOOL)changecurrentRangeviewppDubbingFile:(float)dubbingDuration volume:(float)volume callBlock:(void (^)(DubbingRangeView *dubbingRange))callBlock{
    if(!self.currentDubbingView){
        if(callBlock){
            callBlock(nil);
        }
        return NO;
    }
    float rightX = 0.0;
    NSArray *arr = [self getTimesFor_videoRangeView_withTime];
    for (int i=0; i<arr.count;i++) {
        DubbingRangeView *dubb = arr[i];
       if(i==arr.count-1){
           Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
           //Float64 piantouWidth  =   _piantouDuration * (self.videoRangeView.frame.size.width/duration);
           Float64 pianweiWidth  =   _pianweiDuration * (self.videoRangeView.frame.size.width/duration);
            rightX = self.videoRangeView.frame.size.width - pianweiWidth;
            break;
        }else{
            if(dubb.frame.origin.x == self.currentDubbingView.frame.origin.x){
                DubbingRangeView *dubb2 = arr[i+1];
                rightX = dubb2.frame.origin.x;
                break;
            }
        }
    }
    if(self.currentDubbingView.frame.origin.x +self.currentDubbingView.frame.size.width>rightX-6){
        if(callBlock){
            callBlock(self.currentDubbingView);
        }
         return NO;
    }
    self.currentDubbingView.dubbingDuration = CMTimeMakeWithSeconds(dubbingDuration, TIMESCALE);
    self.currentDubbingView.volume = volume;
    float rangeWidth = dubbingDuration*((self.scrollView.contentSize.width-self.scrollView.frame.size.width)/(float)CMTimeGetSeconds(self.clipTimeRange.duration));
    rangeWidth = self.scrollView.contentOffset.x - self.currentDubbingView.frame.origin.x;
    self.currentDubbingView.frame = CGRectMake(self.currentDubbingView.frame.origin.x, self.currentDubbingView.frame.origin.y, rangeWidth, self.currentDubbingView.frame.size.height);
    if(callBlock){
        callBlock(self.currentDubbingView);
    }
    return YES;
}

- (BOOL)savecurrentRangeviewWithMusicPath:(NSString *)musicPath
                              volume:(double)volume
                   dubbingIndex:(NSInteger) index
                        flag:(BOOL)flag{
    self.currentDubbingView.hidden = NO;
    if(!self.currentDubbingView){
        return NO;
    }
    Float64 duration = CMTimeGetSeconds(self.clipTimeRange.duration);
    if(flag){
        self.currentDubbingView.dubbingDuration = CMTimeMakeWithSeconds((self.currentDubbingView.frame.size.width/(float)self.videoRangeView.frame.size.width) * duration, TIMESCALE);
        self.currentDubbingView.dubbingIndex = index;
        self.currentDubbingView.musicPath = musicPath;
        self.currentDubbingView.volume = volume;
    }
    if(!flag){
        self.currentDubbingView = nil;
    }
    self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
    self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - 10) / self.widthPerSecond;
    _needShowBtn = YES;
    return YES;
}

- (BOOL)changeCurrentVolume:(float)volume {
    if(!self.currentDubbingView){
        return NO;
    }
    self.currentDubbingView.volume = volume;
    return YES;
}

- (CMTime)deletedcurrentDubbing{
    CMTime time = kCMTimeZero;
    if(self.currentDubbingView){
        time = self.currentDubbingView.dubbingStartTime;
        [self.currentDubbingView removeFromSuperview];
        self.currentDubbingView = nil;
    }else{
        if (commonAlertView) {
            commonAlertView.delegate = nil;
            commonAlertView = nil;
        }
        commonAlertView = [[UIAlertView alloc] initWithTitle:RDLocalizedString(@"温馨提示", nil)
                                                     message:RDLocalizedString(@"请选择相应的配音删除", nil)
                                                    delegate:self
                                           cancelButtonTitle:RDLocalizedString(@"取消", nil)
                                           otherButtonTitles:RDLocalizedString(@"确定", nil), nil];
        [commonAlertView show];
    }
    
    return time;
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
    
    
    
    if(CGRectContainsPoint([self touchRectForHandle:self.currentThumbView.frame.origin], touchPoint))
    {

    }
    
    if(CGRectContainsPoint([self touchRectForHandle:CGPointMake(self.currentThumbView.frame.origin.x + self.currentThumbView.frame.size.width, self.currentThumbView.frame.origin.y)], touchPoint))
    {
        
    }
    
    return YES;
}


- (NSMutableArray *)getTimesFor_videoRangeView{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
 

    
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [arra sortUsingComparator:^NSComparisonResult(DubbingRangeView *obj1, DubbingRangeView *obj2) {
        CGFloat obj1X = obj1.dubbingIndex;
        CGFloat obj2X = obj2.dubbingIndex;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    
    
    return arra;//[_videoRangeView.subviews mutableCopy];
}

- (NSMutableArray *)getTimesFor_videoRangeView_withTime{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
    
    
    
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [arra sortUsingComparator:^NSComparisonResult(DubbingRangeView *obj1, DubbingRangeView *obj2) {
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

- (void)setProgress:(float)progress animated:(BOOL)animated{
    if (isnan(progress)) {
        progress = 0;
    }
    if(!_videoCore){
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:animated];
        return;
    }
    float frame = progress*_videoCore.duration * (_videoRangeView.frame.size.width/_videoCore.duration);
    [self.scrollView setContentOffset:CGPointMake(frame, 0) animated:animated];
//    _videoRangeView = nil;
}

- (void)releaseImages {
    [_frameView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
            [obj removeFromSuperview];
        }
    }];
}

- (void)dealloc{
    [self.subviews respondsToSelector:@selector(removeFromSuperview)];
    NSLog(@"%s",__func__);
    if (commonAlertView) {
        commonAlertView.delegate = nil;
        commonAlertView = nil;
    }
    [_frameView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
        }
        [obj removeFromSuperview];
    }];
}
@end
