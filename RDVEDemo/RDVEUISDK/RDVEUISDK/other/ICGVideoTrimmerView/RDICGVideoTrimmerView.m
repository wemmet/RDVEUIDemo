//
//  ICGVideoTrimmerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "RDICGVideoTrimmerView.h"
#import "RDICGThumbView.h"
#import "RDICGRulerView.h"
#import "RDComminuteRangeView.h"

@interface RDICGVideoTrimmerView() <UIScrollViewDelegate>{
    
    float   scrollcurrentOrginx;
    NSMutableArray *_trimmerArray;
    NSString *cutThumbPath;
    NSArray *thumbTimes;
    BOOL  cancelLoading;
    
    float fprogress;
}


@property (strong, nonatomic) UIView *leftOverlayView;
@property (strong, nonatomic) UIView *rightOverlayView;
@property (strong, nonatomic) RDICGThumbView *leftThumbView;
@property (strong, nonatomic) RDICGThumbView *rightThumbView;

@property (strong, nonatomic) UIView *topBorder;
@property (strong, nonatomic) UIView *bottomBorder;


@property (nonatomic) CGFloat endTime;

@property (nonatomic) CGFloat widthPerSecond;

@property (nonatomic) CGPoint leftStartPoint;
@property (nonatomic) CGPoint rightStartPoint;
@property (nonatomic) CGFloat overlayWidth;

@property (nonatomic) NSMutableArray *allImages;

@property (assign,nonatomic)BOOL isdragging;

@end

@implementation RDICGVideoTrimmerView

#pragma mark - Initiation



- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        self.asset = asset;
        fprogress = 0.0;
        //        [self resetSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame composition:(AVComposition *)composition
{
    self = [super initWithFrame:frame];
    if (self) {
        self.asset = (AVAsset *)composition;
        fprogress = 0.0;
        //        [self resetSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame asset:(AVURLAsset *)asset
{
    self = [super initWithFrame:frame];
    if (self) {
        self.asset = asset;
        fprogress = 0.0;
        //        [self resetSubviews];
    }
    return self;
}

#pragma mark - Private methods
- (float)getstart{
    CMTimeRange timeRange = kCMTimeRangeZero;
    if(_contentFile.isReverse){
        
        if (CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.reverseVideoTimeRange)) {
            timeRange = CMTimeRangeMake(kCMTimeZero, _contentFile.reverseDurationTime);
        }else{
            timeRange = _contentFile.reverseVideoTimeRange;
        }
        if(CMTimeCompare(timeRange.duration, _contentFile.reverseVideoTrimTimeRange.duration) == 1){
            timeRange = _contentFile.reverseVideoTrimTimeRange;
        }
        //NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
        
    }
    else{
        if (_contentFile.isGif) {
            if (CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.imageTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, _contentFile.imageDurationTime);
            }else{
                timeRange = _contentFile.imageTimeRange;
            }
        }else {
            if (CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, _contentFile.videoDurationTime);
            }else{
                timeRange = _contentFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, _contentFile.videoTrimTimeRange.duration) == 1){
                timeRange = _contentFile.videoTrimTimeRange;
            }
        }
        //NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
    }
    
    return CMTimeGetSeconds(timeRange.start);
    
}
- (float)getduration{
    CMTimeRange timeRange = kCMTimeRangeZero;
    if(_contentFile.isReverse){
        
        if (CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.reverseVideoTimeRange)) {
            timeRange = CMTimeRangeMake(kCMTimeZero, _contentFile.reverseDurationTime);
        }else{
            timeRange = _contentFile.reverseVideoTimeRange;
        }
        if(CMTimeCompare(timeRange.duration, _contentFile.reverseVideoTrimTimeRange.duration) == 1){
            timeRange = _contentFile.reverseVideoTrimTimeRange;
        }
        //NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
        
    }
    else{
        if (_contentFile.isGif) {
            if (CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.imageTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, _contentFile.imageDurationTime);
            }else{
                timeRange = _contentFile.imageTimeRange;
            }
        }else {
            if (CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, _contentFile.videoDurationTime);
            }else{
                timeRange = _contentFile.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, _contentFile.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, _contentFile.videoTrimTimeRange.duration) == 1){
                timeRange = _contentFile.videoTrimTimeRange;
            }
        }
        //NSLog(@"timeRange : %f : %f ",CMTimeGetSeconds(timeRange.start),CMTimeGetSeconds(timeRange.duration));
    }
    
    return CMTimeGetSeconds(timeRange.duration)/_contentFile.speed;
    
}

- (void)resetSubviews
{
    Float64 duration = [self getduration];
    
    _loadImageFinish = NO;
    if(duration >= 10){
        self.maxLength = 5;
    }else{
        self.maxLength = duration;
    }
    
    if (self.minLength == 0) {
        self.minLength = 0;
    }
    
    [self setBackgroundColor: [UIColor clearColor] ];
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    [self addSubview:self.scrollView];
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    self.contentView.userInteractionEnabled = YES;
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    self.scrollView.decelerationRate = 1.0;
    CGFloat ratio = self.showsRulerView ? 0.7 : 1.0;
    self.frameView = [[UIView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.frameView.layer setMasksToBounds:YES];
    self.frameView.clipsToBounds = YES;
    [self.contentView addSubview:self.frameView];
    
    
    self.videoRangeView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 0, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame)*ratio)];
    [self.videoRangeView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.videoRangeView];
    [self.videoRangeView.layer setBorderColor:UIColorFromRGB(0xffffff).CGColor];
    [self.videoRangeView.layer setBorderWidth:0];
    
    
    if(_thumbChildrens.count>0){
        float width =0;
        for (int i=0; i<_thumbChildrens.count; i++) {
            CGRect rect = ((UIImageView *)_thumbChildrens[i]).frame;
            rect.size.height = _videoRangeView.frame.size.height;
            width += rect.size.width + 10;
            ((UIImageView *)_thumbChildrens[i]).frame = rect;
            [_videoRangeView addSubview:_thumbChildrens[i]];
            if(i==_thumbChildrens.count - 1){
                width -=10;
            }
        }
        _videoRangeView.image = nil;
        _videoRangeView.frame = CGRectMake(_frameView.frame.size.width/2.0, 0, width, self.frameView.frame.size.height);
        self.frameView.frame = _videoRangeView.frame;
        
        self.scrollView.contentSize = CGSizeMake(_videoRangeView.frame.size.width+self.scrollView.frame.size.width, self.scrollView.contentSize.height);
        self.loadImageFinish = YES;
    }else{
        [self addFrames];
    }
    if (self.showsRulerView) {
        CGRect rulerFrame = CGRectMake(0, CGRectGetHeight(self.contentView.frame)*ratio, CGRectGetWidth(self.contentView.frame)+10, CGRectGetHeight(self.contentView.frame)*0.3);
        RDICGRulerView *rulerView = [[RDICGRulerView alloc] initWithFrame:rulerFrame widthPerSecond:self.widthPerSecond themeColor:self.themeColor];
        [self.contentView addSubview:rulerView];
    }
    
    // add borders
    
    self.topBorder = [[UIView alloc] init];
    if(self.showsborderView){
        [self.topBorder setBackgroundColor:self.themeColor];
        
    }else{
        [self.topBorder setBackgroundColor:[UIColor clearColor]];
    }
    [self addSubview:self.topBorder];
    
    self.bottomBorder = [[UIView alloc] init];
    if(self.showsborderView){
        [self.bottomBorder setBackgroundColor:self.themeColor];
        
    }else{
        [self.bottomBorder setBackgroundColor:[UIColor clearColor]];
    }
    [self addSubview:self.bottomBorder];
    
    // width for left and right overlay views
    self.overlayWidth =  (CGRectGetWidth(self.frameView.frame) < CGRectGetWidth(self.frame) ? CGRectGetWidth(self.frameView.frame) : CGRectGetWidth(self.frame)) - (self.minLength * self.widthPerSecond);
    
    if(isnan(self.overlayWidth)){
        self.overlayWidth = 100;
    }
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
    
    if(self.showsborderView){
        self.leftThumbView.hidden = NO;
        self.rightThumbView.hidden = NO;
        self.leftOverlayView.hidden = NO;
        self.rightOverlayView.hidden = NO;
    }else{
        self.leftThumbView.hidden = YES;
        self.rightThumbView.hidden = YES;
        self.leftOverlayView.hidden = YES;
        self.rightOverlayView.hidden = YES;
    }
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
            CGFloat maxX = CMTimeGetSeconds([self.asset duration]) <= self.maxLength + 0.5 ? CGRectGetMaxX(self.frameView.frame) : CGRectGetWidth(self.frame) - 10;
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
    
    Float64 duration = [self getduration];
    
    NSMutableArray *array = [self getTimesFor_videoRangeView];
    if(array.count>1){
        for (int i=0;i<array.count; i++) {
            RDComminuteRangeView *rangeView = array[i];
            if(rangeView.frame.origin.x - 10 < self.scrollView.contentOffset.x && self.scrollView.contentOffset.x < rangeView.frame.origin.x + rangeView.frame.size.width){
                _currentIndex = i;
            }
            if(rangeView.frame.origin.x<=self.scrollView.contentOffset.x && rangeView.frame.origin.x + rangeView.frame.size.width >=self.scrollView.contentOffset.x){
                scrollcurrentOrginx = self.scrollView.contentOffset.x - rangeView.frame.origin.x;
                float duration;
                if (rangeView.file.isGif) {
                    duration = CMTimeGetSeconds(rangeView.file.imageTimeRange.duration);
                }else {
                    duration = CMTimeGetSeconds((rangeView.file.isReverse ? rangeView.file.reverseVideoTrimTimeRange : rangeView.file.videoTrimTimeRange).duration);
                }
                _scrollcurrentTime = scrollcurrentOrginx * (duration/rangeView.frame.size.width);
                
                if(duration > _scrollcurrentTime){
                    
                    
                    float totalWidth = self.videoRangeView.frame.size.width - (_trimmerArray.count-1)*10;
                    
                    RDComminuteRangeView *rangeView = _trimmerArray[self.currentIndex];
                    
                    float currentWidth = rangeView.frame.origin.x - self.currentIndex *10;
                    
                    float currentTime = currentWidth * duration /totalWidth;
                    
                    
                    if(_scrollcurrentTime >=0){
                        self.startTime = currentTime;
                    }else{
                        self.startTime = currentTime;
                    }
                    
                    self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - 10) / self.widthPerSecond;
                    //NSLog(@"%lf",_scrollcurrentTime);
                    break;
                }
            }
        }
    }else{
        self.startTime = self.scrollView.contentOffset.x * (duration/self.videoRangeView.frame.size.width);
        _scrollcurrentTime = self.startTime;
        
        self.endTime = CGRectGetMinX(self.rightOverlayView.frame) / self.widthPerSecond + (self.scrollView.contentOffset.x - 10) / self.widthPerSecond;
    }
    
    
    [_delegate trimmerView:self didChangeLeftPosition:_startTime rightPosition:self.endTime];
}

- (void)addFrames
{
    _allImages = [[NSMutableArray alloc] init];
    _imageGenerator = [self initthumbImageGenerator];
    CGFloat picWidth = 0;
    Float64 duration = [self getduration];
    Float64 start = [self getstart];
    //这里是用的构建的虚拟视频在截图，所以开始时间就设置为0；
//    start = 0.02;
    // First image
    NSError *error;
    CMTime actualTime;
    
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds((duration > 0.5 ? 0.5 : 0.1), TIMESCALE) actualTime:&actualTime error:&error];
    UIImage *videoScreen;
    if(!halfWayImage){
        halfWayImage = [self.imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(duration-0.5, TIMESCALE) actualTime:&actualTime error:&error];
    }
    if ([self isRetina]){
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:3.0 orientation:UIImageOrientationUp];
    } else {
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
    }
    
    videoScreen = [self ImageCrop: videoScreen];
    
    if (halfWayImage != NULL) {
        UIImageView *tmp = [[UIImageView alloc] initWithImage:nil];
        CGRect rect = tmp.frame;
        
        if(videoScreen.size.width>videoScreen.size.height){
            rect.size.width = [[UIScreen mainScreen] scale]>2 ? self.frameView.frame.size.height*16/9.0 : videoScreen.size.width/2.0;
        }else{
            rect.size.width = [[UIScreen mainScreen] scale]>2 ? self.frameView.frame.size.height*9.0/16 : videoScreen.size.width/2.0;
        }
        NSLog(@"width:%f", rect.size.width);
        rect.size.height = self.frameView.frame.size.height;
        rect.size.width = rect.size.height;
        
        
        tmp.frame = rect;
        tmp.contentMode = UIViewContentModeScaleAspectFill;
        tmp.backgroundColor = [UIColor clearColor];
        [self.frameView addSubview:tmp];
        picWidth = tmp.frame.size.width;
        
        CGImageRelease(halfWayImage);
//        [_allImages addObject:videoScreen];
    }
    
    
    
    CGFloat screenWidth = CGRectGetWidth(self.frame); // quick fix to make up for the width of thumb views
    NSInteger actualFramesNeeded = 0;
    
    CGFloat frameViewFrameWidth = (duration / self.maxLength) * screenWidth;
    float scrollWidth = self.frame.size.width;
    [self.frameView setFrame:CGRectMake(scrollWidth/2, 0, frameViewFrameWidth, CGRectGetHeight(_frameView.frame))];
    [self.videoRangeView setFrame:self.frameView.frame];
    CGFloat contentViewFrameWidth = duration <= self.maxLength + 0.5 ? screenWidth + 30 : frameViewFrameWidth;
    
    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth + scrollWidth, CGRectGetHeight(self.contentView.frame))];
    
    CGSize size = self.contentView.frame.size;
    
    [self.scrollView setContentSize:size];
    self.contentSize = size;
    actualFramesNeeded = ceilf(duration/1.0);
//    if (duration <= 5) {
//        actualFramesNeeded = 2;
//    } else if (duration <= 10) {
//        actualFramesNeeded = 8;
//    } else if (duration <= 60) {
//        actualFramesNeeded = duration / 2;
//    } else if (duration <= 120) {
//        actualFramesNeeded = duration / 3;
//    } else {
//        actualFramesNeeded = duration / 5;
//    }
    
    
    Float64 durationPerFrame = duration / (actualFramesNeeded*1.0);
    self.widthPerSecond = frameViewFrameWidth / duration;
    
    int preferredWidth = 0;
    
    NSMutableArray *times = [[NSMutableArray alloc] init];
    float width = 0;
    for (int i = 0; i<actualFramesNeeded; i++){
        
        CMTime time = CMTimeMakeWithSeconds((isnan(start) ? 0 : start) + i*durationPerFrame, 30);
        [times addObject:[NSValue valueWithCMTime:time]];
        
        UIImageView *tmp = [[UIImageView alloc] initWithImage:nil];
        tmp.tag = i+1;
        tmp.contentMode = UIViewContentModeScaleAspectFill;
        CGRect currentFrame = tmp.frame;
        currentFrame.origin.x = i*picWidth;
        
        if( ((int)duration/1) == actualFramesNeeded )
            currentFrame.size.width = picWidth;
        else
        {
            currentFrame.size.width = picWidth*(actualFramesNeeded - ((int)duration/1) );
        }
        
        currentFrame.size.height = self.frameView.frame.size.height;
        currentFrame.size.width = currentFrame.size.height;
        
        preferredWidth += currentFrame.size.width;
        
        if( i == actualFramesNeeded-1){
            currentFrame.size.width-=6;
        }
        width += currentFrame.size.width;
        tmp.frame = currentFrame;
        tmp.layer.masksToBounds = YES;
        tmp.backgroundColor = [UIColor clearColor];
        [self.frameView addSubview:tmp];
        
    }
    _videoRangeView.frame = CGRectMake(scrollWidth/2, 0, width, self.videoRangeView.frame.size.height);
    _frameView.frame = _videoRangeView.frame;
    _contentView.frame = CGRectMake(0, _contentView.frame.origin.y,_videoRangeView.frame.size.width + _scrollView.frame.size.width , _contentView.frame.size.height);
    _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
    [_scrollView setContentSize:_contentView.frame.size];
    //_imageGenerator = [self initthumbImageGenerator];
    //[self refreshThumbs:times];
    [self refreshTrimmerViewImage:times];
}

#define kRefreshThumbMaxCounts 20

- (void)refreshTrimmerViewImage:(NSArray *)times{
    @autoreleasepool {
        thumbTimes = times;
        __weak typeof(self) weakSelf = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if( _contentFile.filtImagePatch )
            {
                [weakSelf thumbS_refreshThumbwithImageTimes:thumbTimes];
            }
            else{
                NSUInteger end = (thumbTimes.count > kRefreshThumbMaxCounts) ? kRefreshThumbMaxCounts : times.count;
                if(thumbTimes.count>0){
                    NSArray *imageTimes = [thumbTimes subarrayWithRange:NSMakeRange(0,end)];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [weakSelf refreshThumbwithImageTimes:imageTimes nextRefreshIndex:1 isLastArray:(thumbTimes.count > kRefreshThumbMaxCounts ? NO : YES)];
                        
                    });
                }
            }
            
        });
    }
}

-(void)thumbS_refreshThumbwithImageTimes:(NSArray *) imageTimes
{
    @autoreleasepool {
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
            for (int i = 0; i<imageTimes.count; i++) {
    
                int number = ceilf(CMTimeGetSeconds([imageTimes[i] CMTimeValue] ));
                NSString * strPatch = [_contentFile.filtImagePatch stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png",number]];
                
                UIImage* videoScreen = [RDHelpClass getThumbImageWithUrl: [NSURL fileURLWithPath:strPatch]];
                videoScreen = [self ImageCrop: videoScreen];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //刷新控件
                    
                    
                    UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:i+1];
                    
                    UIImage *  videoScreen1 = [RDHelpClass scaleImage:videoScreen toScale:(imageView.frame.size.height/videoScreen.size.height)];
                    
                    
                    [imageView setImage:videoScreen1];
                    if(videoScreen1) [_allImages addObject:videoScreen1];
                    
                    if( i >= (thumbTimes.count - 1) )
                    {
                        UIImage *resultImage = [RDHelpClass drawImages:_allImages size:CGSizeZero animited:NO];
                        
                        _videoRangeView.image = resultImage;
                        CGRect rect = CGRectMake(self.videoRangeView.frame.origin.x, self.videoRangeView.frame.origin.y, resultImage.size.width, self.videoRangeView.frame.size.height);
                        _videoRangeView.frame = rect;
                        _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                        _frameView.frame = _videoRangeView.frame;
                        CGRect contentViewRect = CGRectMake(0, _contentView.frame.origin.y,_videoRangeView.frame.size.width + _scrollView.frame.size.width , _contentView.frame.size.height);
                        _contentView.frame = contentViewRect;
                        _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                        [_scrollView setContentSize:_contentView.frame.size];
                        
                        _videoRangeView.hidden = NO;
                        _videoRangeView.backgroundColor = [UIColor clearColor];
                        _loadImageFinish = YES;
                        [_imageGenerator cancelAllCGImageGeneration];
                        _imageGenerator.videoComposition = nil;
                        _imageGenerator = nil;
                    }
                });
            }
//        });
        
    }
}




-(UIImage *)ImageCrop:(UIImage * ) image
{
    CGRect rectCrop = CGRectMake(0, 0, 1, 1);
    if( image.size.width > image.size.height
       )
    {
        float scale = image.size.height/image.size.width;
        
        rectCrop = CGRectMake((1.0- scale)/2.0, 0, scale, 1);
    }
    else{
        float scale = image.size.width/image.size.height;
        rectCrop = CGRectMake(0, (1.0- scale)/2.0, 1, scale);
    }
    
    return [RDHelpClass image:image rotation:0 cropRect:rectCrop];
}

- (void)refreshThumbwithImageTimes:(NSArray *)imageTimes nextRefreshIndex:(int)nextRefreshIndex isLastArray:(BOOL)isLastArray{
    @autoreleasepool {
        __block NSInteger idx = 0;
        __weak typeof(self) weakSelf = self;
        if(!_imageGenerator || cancelLoading){
            return;
        }
        [_imageGenerator generateCGImagesAsynchronouslyForTimes:imageTimes
                                              completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,
                                                                  AVAssetImageGeneratorResult result, NSError *error) {
                                                  @autoreleasepool {
                                                      NSString *requestedTimeString = (NSString *)
                                                      CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
                                                      NSRange range = [requestedTimeString rangeOfString:@"="];
                                                      requestedTimeString = [requestedTimeString substringFromIndex:range.length + range.location];
                                                      range = [requestedTimeString rangeOfString:@","];
                                                      
                                                      
                                                      idx++;
                                                      if(range.location != NSNotFound){
                                                          NSInteger index = idx + (nextRefreshIndex-1)*kRefreshThumbMaxCounts;
                                                          NSLog(@"index:%zd",index);
                                                          if (result == AVAssetImageGeneratorSucceeded) {
                                                              UIImage* videoScreen;
//                                                              if ([self isRetina]){
                                                                  videoScreen = [[UIImage alloc] initWithCGImage:image scale:3.0 orientation:UIImageOrientationUp];
//                                                              } else {
//                                                                  videoScreen = [[UIImage alloc] initWithCGImage:image];
//                                                              }
                                                              
                                                              videoScreen = [self ImageCrop: videoScreen];
                                                              
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  //刷新控件
                                                                  UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:index];
                                                                  [imageView setImage:videoScreen];
                                                                  if(videoScreen) [_allImages addObject:videoScreen];
                                                                  
                                                              });
                                                              
                                                          }
                                                          
                                                          if (result == AVAssetImageGeneratorFailed) {
                                                              NSLog(@"Failed with error: %@", [error localizedDescription]);
                                                          }
                                                          if (result == AVAssetImageGeneratorCancelled) {
                                                              NSLog(@"Canceled");
                                                          }
                                                          if(isLastArray && index > thumbTimes.count - 1){
                                                              UIImage *resultImage = [RDHelpClass drawImages:_allImages size:CGSizeZero animited:NO];
                                                              
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  _videoRangeView.image = resultImage;
                                                                  CGRect rect = CGRectMake(self.videoRangeView.frame.origin.x, self.videoRangeView.frame.origin.y, resultImage.size.width, self.videoRangeView.frame.size.height);
//                                                                  /([[UIScreen mainScreen] scale]>2 ? 2.0 :1.0)
                                                                  _videoRangeView.frame = rect;
                                                                  _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                                                                  _frameView.frame = _videoRangeView.frame;
                                                                  CGRect contentViewRect = CGRectMake(0, _contentView.frame.origin.y,_videoRangeView.frame.size.width + _scrollView.frame.size.width , _contentView.frame.size.height);
                                                                  _contentView.frame = contentViewRect;
                                                                  _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                                                                  [_scrollView setContentSize:_contentView.frame.size];
                                                                  
                                                                  
                                                                  
                                                                  _videoRangeView.hidden = NO;
                                                                  _videoRangeView.backgroundColor = [UIColor clearColor];
                                                                  _loadImageFinish = YES;
                                                                  [_imageGenerator cancelAllCGImageGeneration];
                                                                  _imageGenerator.videoComposition = nil;
                                                                  _imageGenerator = nil;
                                                              });
                                                              
                                                          }else if (!isLastArray && idx >=kRefreshThumbMaxCounts /*index >= nextRefreshIndex*kRefreshThumbMaxCounts - 1*/) {
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  [_imageGenerator cancelAllCGImageGeneration];
                                                                  _imageGenerator.videoComposition = nil;
                                                                  _imageGenerator = nil;
                                                                  
                                                                  if (thumbTimes.count > 0) {
                                                                      int counts = ceilf(thumbTimes.count/(float)kRefreshThumbMaxCounts);
                                                                      NSUInteger star = nextRefreshIndex*kRefreshThumbMaxCounts;
                                                                      NSUInteger end = (nextRefreshIndex == (counts - 1)) ? (thumbTimes.count-nextRefreshIndex*kRefreshThumbMaxCounts) : kRefreshThumbMaxCounts;
                                                                      NSRange range = NSMakeRange(star,end);
                                                                      NSArray *imageTimes = [thumbTimes subarrayWithRange:range];
                                                                      NSLog(@"initthumbImageGenerator1:%ld",(long)idx);
                                                                      _imageGenerator = [weakSelf initthumbImageGenerator];
                                                                      [weakSelf refreshThumbwithImageTimes:imageTimes nextRefreshIndex:(nextRefreshIndex + 1) isLastArray:(nextRefreshIndex == (counts-1) ? YES : NO)];
                                                                  }
                                                              });
                                                              
                                                          }
                                                      }else {//timescale改为UI_TIMESCALE（NSEC_PER_SEC）后，第一段时间为CMTime: {10000000/1000000000 = 0.010},"0.010"后没有","
                                                          range = [requestedTimeString rangeOfString:@"}"];
                                                          
                                                          if(range.location != NSNotFound){
                                                              //                                                             requestedTimeString = [requestedTimeString substringToIndex:range.location];
                                                              NSInteger index = idx + (nextRefreshIndex-1)*kRefreshThumbMaxCounts;
                                                              //NSLog(@"requestedTimeString2:%@ index:%ld",requestedTimeString,(long)index);
                                                              NSLog(@"index:%zd",index);
                                                              if (result == AVAssetImageGeneratorSucceeded) {
                                                                  UIImage* videoScreen;
//                                                                  if ([self isRetina]){
                                                                      videoScreen = [[UIImage alloc] initWithCGImage:image scale:3.0 orientation:UIImageOrientationUp];
//                                                                  } else {
//                                                                      videoScreen = [[UIImage alloc] initWithCGImage:image];
//                                                                  }
                                                                  
                                                                  videoScreen = [self ImageCrop: videoScreen];
                                                                  
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      //刷新控件
                                                                      UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:index];
                                                                      [imageView setImage:videoScreen];
                                                                      if(videoScreen) [_allImages addObject:videoScreen];
                                                                      
                                                                  });
                                                              }
                                                              
                                                              if (result == AVAssetImageGeneratorFailed) {
                                                                  NSLog(@"Failed with error: %@", [error localizedDescription]);
                                                              }
                                                              if (result == AVAssetImageGeneratorCancelled) {
                                                                  NSLog(@"Canceled");
                                                              }
                                                              if(isLastArray && index > thumbTimes.count - 1){
                                                                  
                                                                  UIImage *resultImage = [RDHelpClass drawImages:_allImages size:CGSizeZero animited:NO];
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      _videoRangeView.image = resultImage;
                                                                      CGRect rect = CGRectMake(self.videoRangeView.frame.origin.x, self.videoRangeView.frame.origin.y, resultImage.size.width, self.videoRangeView.frame.size.height);
                                                                      
//                                                                      /([[UIScreen mainScreen] scale]>2 ? 2.0 :1.0)
                                                                      
                                                                      _videoRangeView.frame = rect;
                                                                      _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                                                                      _frameView.frame = _videoRangeView.frame;
                                                                      CGRect contentViewRect = CGRectMake(0, _contentView.frame.origin.y,_videoRangeView.frame.size.width + _scrollView.frame.size.width , _contentView.frame.size.height);
                                                                      _contentView.frame = contentViewRect;
                                                                      _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                                                                      [_scrollView setContentSize:_contentView.frame.size];
                                                                      
                                                                      _videoRangeView.hidden = NO;
                                                                      _videoRangeView.backgroundColor = [UIColor clearColor];
                                                                      _loadImageFinish = YES;
                                                                      [_imageGenerator cancelAllCGImageGeneration];
                                                                      _imageGenerator.videoComposition = nil;
                                                                      _imageGenerator = nil;
                                                                      
                                                                  });
                                                                  
                                                              }else if (!isLastArray &&  idx >=kRefreshThumbMaxCounts/*index >= nextRefreshIndex*kRefreshThumbMaxCounts - 1*/) {
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      [_imageGenerator cancelAllCGImageGeneration];
                                                                      _imageGenerator.videoComposition = nil;
                                                                      _imageGenerator = nil;
                                                                      
                                                                      if (thumbTimes.count > 0 ) {
                                                                          int counts = ceilf(thumbTimes.count/(float)kRefreshThumbMaxCounts);
                                                                          NSUInteger star = nextRefreshIndex*kRefreshThumbMaxCounts;
                                                                          NSUInteger end = (nextRefreshIndex == (counts - 1)) ? (thumbTimes.count-nextRefreshIndex*kRefreshThumbMaxCounts) : kRefreshThumbMaxCounts;
                                                                          NSRange range = NSMakeRange(star,end);
                                                                          NSArray *imageTimes = [thumbTimes subarrayWithRange:range];
                                                                          NSLog(@"initthumbImageGenerator2:%ld",(long)idx);
                                                                          _imageGenerator = [weakSelf initthumbImageGenerator];
                                                                          [weakSelf refreshThumbwithImageTimes:imageTimes nextRefreshIndex:(nextRefreshIndex + 1) isLastArray:(nextRefreshIndex == (counts-1) ? YES : NO)];
                                                                      }
                                                                  });
                                                              }
                                                          }
                                                      }
                                                  }
                                              }];
    }
}

- (AVAssetImageGenerator *)initthumbImageGenerator{
    AVAssetImageGenerator *imageGenerator;
    imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.composition];
    imageGenerator.videoComposition = self.videoComposition;
    imageGenerator.appliesPreferredTrackTransform = YES;
//    imageGenerator.maximumSize = CGSizeMake(CGRectGetWidth(self.frameView.frame)*2, 240);
    imageGenerator.maximumSize = CGSizeMake(240, 240);
    return imageGenerator;
}


- (void)cancelLoadThumb{
    if(_imageGenerator){
        cancelLoading = YES;
        [_imageGenerator cancelAllCGImageGeneration];
        NSLog(@"%s",__func__);
        
    }
    
}

#if 0

- (void)refreshThumbs:(NSArray *)times{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i=1; i<=[times count]; i++) {
            @autoreleasepool{
                CMTime time = [((NSValue *)[times objectAtIndex:i-1]) CMTimeValue];
                CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
                
                if ([self isRetina]){
                    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:3.0 orientation:UIImageOrientationUp];
                } else {
                    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
                }
                
                videoScreen = [self ImageCrop: videoScreen];
                
                CGImageRelease(halfWayImage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:i];
                    [imageView setImage:videoScreen];
                    if(videoScreen)
                        [_allImages addObject:videoScreen];
                    if(i == times.count){
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            UIImage *resultImage = [RDHelpClass drawImages:_allImages size:CGSizeZero animited:NO];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                if(!(_thumbChildrens.count>0)){
                                    _videoRangeView.image = resultImage;
                                    CGRect rect = CGRectMake(self.videoRangeView.frame.origin.x, self.videoRangeView.frame.origin.y, resultImage.size.width/([[UIScreen mainScreen] scale]>2 ? 2.0 :1.0), self.videoRangeView.frame.size.height);
                                    _videoRangeView.frame = rect;
                                    _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                                    _frameView.frame = _videoRangeView.frame;
                                    CGRect contentViewRect = CGRectMake(0, _contentView.frame.origin.y,_videoRangeView.frame.size.width + _scrollView.frame.size.width , _contentView.frame.size.height);
                                    _contentView.frame = contentViewRect;
                                    _videoRangeView.contentMode = UIViewContentModeScaleAspectFill;
                                    
                                    [_scrollView setContentSize:_contentView.frame.size];
                                }
                                
                                _videoRangeView.hidden = NO;
                                _videoRangeView.backgroundColor = [UIColor clearColor];
                                _loadImageFinish = YES;
                            });
                        });
                        
                        self.imageGenerator = nil;
                        if (_delegate && [_delegate respondsToSelector:@selector(trimmerViewRefreshThumbsCompletion)]) {
                            [_delegate trimmerViewRefreshThumbsCompletion];
                        }
                    }else{
                        
                    }
                });
            }
            
        }
    });
}
#endif

- (BOOL)isRetina
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0));
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self notifyDelegate];
}


//开始滑动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    if(_delegate){
        if([_delegate respondsToSelector:@selector(trimmerViewScrollViewWillBegin:)] && !_isdragging){
            [_delegate trimmerViewScrollViewWillBegin:scrollView];
        }
    }
    _isdragging = YES;
}

//滚动停止
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(_isdragging){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(trimmerViewScrollViewWillEnd:startTime:endTime:)]){
                [_delegate trimmerViewScrollViewWillEnd:scrollView startTime:self.startTime endTime:self.endTime];
            }
        }
    }
    _isdragging = NO;
}
//手指停止滑动
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if(!decelerate){
        if(_delegate){
            if([_delegate respondsToSelector:@selector(trimmerViewScrollViewWillEnd:startTime:endTime:)]){
                [_delegate trimmerViewScrollViewWillEnd:scrollView startTime:self.startTime endTime:self.endTime];
            }
        }
        _isdragging = NO;
    }
}

- (NSMutableArray *)getTimesFor_videoRangeView{
    
    NSMutableArray *arra = [_videoRangeView.subviews mutableCopy];
    
    //运用 sortUsingComparator 排序 比冒泡排序性能要好
    [arra sortUsingComparator:^NSComparisonResult(RDComminuteRangeView *obj1, RDComminuteRangeView *obj2) {
        /*
         NSOrderedAscending = -1L, // 右边的对象排后面
         NSOrderedSame, // 一样
         NSOrderedDescending // 左边的对象排后面
         */
        
        CGFloat obj1X = obj1.frame.origin.x;
        CGFloat obj2X = obj2.frame.origin.x;
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        } else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    
    return arra;
}

- (void)setProgress:(float)progress animated:(BOOL)animated{
    if (isnan(progress)) {
        progress = 0;
    }
    
    fprogress = progress/self.scrollView.contentSize.width;
    [self.scrollView setContentOffset:CGPointMake(progress, 0) animated:animated];
    
    
    
}

- (BOOL)cuttingVideo{
    return [self cuttingVideo:0];
}

- (BOOL)cuttingVideo:(float)beforDuration{
    
    
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    cutThumbPath = [cacheDirectory stringByAppendingString:@"/cutVideoThumb"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cutThumbPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:cutThumbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    {
        int tmpDuration = beforDuration*100;
        beforDuration = tmpDuration/100.0;
    }
    _lastLowTime = 1.0;
    Float64 duration = [self getduration];
    
    float comminuteX = self.scrollView.contentOffset.x;
    if(!self.loadImageFinish){
        return NO;
    }
    
    NSMutableArray *arr = [self getTimesFor_videoRangeView];
    
    NSInteger flag = [UIScreen mainScreen].scale;
    if (_videoRangeView.subviews.count > 0) {
        BOOL animationed = NO;
        for (RDComminuteRangeView *rangeView in arr) {
            if(rangeView.frame.origin.x<comminuteX && rangeView.frame.size.width+rangeView.frame.origin.x>comminuteX){
                animationed= YES;
                break;
            }
        }
        if(animationed){
            for (RDComminuteRangeView *rangeView in arr) {
                if(rangeView.frame.origin.x>comminuteX){
                    rangeView.frame = CGRectMake(rangeView.frame.origin.x+10, 0, rangeView.frame.size.width, rangeView.frame.size.height);
                }
                if(rangeView.frame.origin.x<comminuteX && rangeView.frame.size.width+rangeView.frame.origin.x>comminuteX){
                    
                    UIImage *Image = rangeView.image;
                    CGImageRef imageRef = Image.CGImage;
                    
                    NSLog(@"*****rangeView : %@",NSStringFromCGRect(rangeView.frame));
                    CGRect rect = CGRectMake(rangeView.frame.origin.x, 0, (self.scrollView.contentOffset.x - rangeView.frame.origin.x), _videoRangeView.frame.size.height);
                    
                    CGRect rect1 = CGRectMake(self.scrollView.contentOffset.x + 10, 0, (rangeView.frame.origin.x + rangeView.frame.size.width - self.scrollView.contentOffset.x), _videoRangeView.frame.size.height);
                    NSLog(@"*****rect : %@",NSStringFromCGRect(rect));
                    NSLog(@"*****rect1: %@",NSStringFromCGRect(rect1));
                    
                    CGRect imageRect = CGRectMake(0, 0, (comminuteX-rangeView.frame.origin.x)*flag, Image.size.height*flag);
                    
                    CGRect imageRect1 = CGRectMake(imageRect.size.width, 0, Image.size.width*flag-imageRect.size.width, Image.size.height*flag);
                    
                    float start = 0;
                    float stop = beforDuration;
                    float stop2;
                    if (rangeView.file.isGif) {
                        if (CMTimeCompare(rangeView.file.imageTimeRange.duration, kCMTimeZero) == 1) {
                            start = CMTimeGetSeconds(rangeView.file.imageTimeRange.start);
                            if (beforDuration <= 0) {
                                stop = (comminuteX-rangeView.frame.origin.x) * (CMTimeGetSeconds(rangeView.file.imageTimeRange.duration)/rangeView.frame.size.width);
                                stop2 = ((rangeView.frame.size.width-(comminuteX-rangeView.frame.origin.x)) *(CMTimeGetSeconds(rangeView.file.imageTimeRange.duration)/rangeView.frame.size.width));
                            }else {
                                stop2 = CMTimeGetSeconds(rangeView.file.imageTimeRange.duration) - stop;
                            }
                        }else {
                            if (beforDuration <= 0) {
                                stop = (comminuteX-rangeView.frame.origin.x) * (CMTimeGetSeconds(rangeView.file.imageDurationTime)/rangeView.frame.size.width);
                                stop2 = ((rangeView.frame.size.width-(comminuteX-rangeView.frame.origin.x)) *(CMTimeGetSeconds(rangeView.file.imageDurationTime)/rangeView.frame.size.width));
                            }else {
                                stop2 = CMTimeGetSeconds(rangeView.file.imageDurationTime) - stop;
                            }
                        }
                    }else if (rangeView.file.isReverse) {
                        start = CMTimeGetSeconds(rangeView.file.reverseVideoTimeRange.start);
                        if (beforDuration <= 0) {
                            stop = ((comminuteX-rangeView.frame.origin.x) * (CMTimeGetSeconds(rangeView.file.reverseVideoTrimTimeRange.duration)/rangeView.frame.size.width));
                            stop2 = ((rangeView.frame.size.width-(comminuteX-rangeView.frame.origin.x)) *(CMTimeGetSeconds(rangeView.file.reverseVideoTrimTimeRange.duration)/rangeView.frame.size.width));
                        }else {
                            stop2 = CMTimeGetSeconds(rangeView.file.reverseVideoTimeRange.duration) - stop;
                        }
                    }else {
                        start = CMTimeGetSeconds(rangeView.file.videoTimeRange.start);
                        if (beforDuration <= 0) {
                            stop = (comminuteX-rangeView.frame.origin.x) * (CMTimeGetSeconds( rangeView.file.videoTrimTimeRange.duration)/rangeView.frame.size.width);
                            stop2 = ((rangeView.frame.size.width-(comminuteX-rangeView.frame.origin.x)) *(CMTimeGetSeconds(rangeView.file.videoTrimTimeRange.duration)/rangeView.frame.size.width));
                        }else {
                            stop2 = CMTimeGetSeconds(rangeView.file.videoTimeRange.duration) - stop;
                        }
                    }
                    float start2 = start + stop;
                    
                    CMTimeRange timeRange1 = CMTimeRangeMake(CMTimeMakeWithSeconds(start, TIMESCALE), CMTimeMakeWithSeconds(stop, TIMESCALE));
                    CMTimeRange timeRange2 = CMTimeRangeMake(CMTimeMakeWithSeconds(start2, TIMESCALE), CMTimeMakeWithSeconds(stop2, TIMESCALE));
                    
                    int before = CMTimeGetSeconds(timeRange1.duration) * 100;
                    int behand = CMTimeGetSeconds(timeRange2.duration) * 100;
                    if(before<0.2*100 || behand <0.2*100){
                        _lastLowTime = MIN(CMTimeGetSeconds(timeRange1.duration), CMTimeGetSeconds(timeRange2.duration));
                        return NO;
                    }
                    
                    CGImageRef image = CGImageCreateWithImageInRect(imageRef,imageRect);
                    
                    CGImageRef image1 = CGImageCreateWithImageInRect(imageRef, imageRect1);
                    
                    UIImage*newImage = [[UIImage alloc] initWithCGImage:image];
                    UIImage*newImage1 = [[UIImage alloc] initWithCGImage:image1];
                    
                    //NSString *thumbPath = [cutThumbPath stringByAppendingPathComponent:[RDHelpClass createFilename]];
                    
                    double time = CFAbsoluteTimeGetCurrent();
                    NSString *fileName = [NSString stringWithFormat:@"thumb-%lf",time];
                    
                    NSString *thumbPath = [cutThumbPath stringByAppendingPathComponent:fileName];
                    
                    [UIImageJPEGRepresentation(newImage, 1) writeToFile:thumbPath atomically:YES];
                    RDComminuteRangeView *rangeVi = [[RDComminuteRangeView alloc] init];
                    
                    rangeVi.frame = rect;
                    rangeVi.backgroundColor = [UIColor clearColor];
                    rangeVi.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
                    rangeVi.layer.borderWidth = 1;
                    rangeVi.layer.masksToBounds = YES;
                    rangeVi.image = [UIImage imageWithContentsOfFile:thumbPath];
                    rangeVi.contentMode = UIViewContentModeScaleToFill;
                    rangeVi.userInteractionEnabled = YES;
                    rangeVi.file = [_contentFile mutableCopy];
                    rangeVi.file.fileTimeFilterType = kTimeFilterTyp_None;
                    rangeVi.file.fileTimeFilterTimeRange = kCMTimeRangeZero;
                    if(!_contentFile.isReverse){
                        if (_contentFile.isGif) {
                            rangeVi.file.imageTimeRange = timeRange1;
                            rangeVi.file.imageDurationTime = timeRange1.duration;
                        }else {
                            rangeVi.file.videoTimeRange = timeRange1;
                            rangeVi.file.videoTrimTimeRange = timeRange1;
                            rangeVi.file.videoDurationTime = timeRange1.duration;
                        }
                    }else{
                        rangeVi.file.reverseVideoTimeRange      = timeRange1;
                        rangeVi.file.reverseVideoTrimTimeRange  = timeRange1;
                        rangeVi.file.reverseDurationTime        = timeRange1.duration;
                    }
                    
                    RDComminuteRangeView *rangeVi2 = [[RDComminuteRangeView alloc] init];
                    rangeVi2.frame = rect1;
                    rangeVi2.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
                    rangeVi2.layer.borderWidth = 1;
                    rangeVi2.layer.masksToBounds = YES;
                    rangeVi2.contentMode = UIViewContentModeScaleToFill;
                    rangeVi2.image = newImage1;
                    rangeVi2.file = [_contentFile mutableCopy];
                    rangeVi2.file.fileTimeFilterType = kTimeFilterTyp_None;
                    rangeVi2.file.fileTimeFilterTimeRange = kCMTimeRangeZero;
                    rangeVi2.backgroundColor = [UIColor clearColor];
                    if(!_contentFile.isReverse){
                        if (_contentFile.isGif) {
                            rangeVi2.file.imageTimeRange = timeRange2;
                            rangeVi2.file.imageDurationTime = timeRange2.duration;
                        }else {
                            rangeVi2.file.videoTimeRange = timeRange2;
                            rangeVi2.file.videoTrimTimeRange = timeRange2;
                            rangeVi2.file.videoDurationTime = timeRange2.duration;
                        }
                    }else{
                        rangeVi2.file.reverseVideoTimeRange      = timeRange2;
                        rangeVi2.file.reverseVideoTrimTimeRange  = timeRange2;
                        rangeVi2.file.reverseDurationTime        = timeRange2.duration;
                    }
                    _videoRangeView.hidden = NO;
                    [_videoRangeView addSubview:rangeVi];
                    [_videoRangeView addSubview:rangeVi2];
                    
                    [rangeVi setNeedsLayout];
                    [rangeVi setNeedsDisplay];
                    [rangeVi2 setNeedsLayout];
                    [rangeVi2 setNeedsDisplay];
                    
                    [rangeView removeFromSuperview];
                    
                    NSLog(@"*****rangeVi : %@",NSStringFromCGRect(rangeVi.frame));
                    NSLog(@"*****rangeVi2 : %@",NSStringFromCGRect(rangeVi2.frame));
                    
                    CGImageRelease(image);
                    CGImageRelease(image1);
                    newImage = nil;
                    newImage1 = nil;
                    float clipDuration;
                    CMTimeRange timeRange;
                    if (rangeView.file.isGif) {
                        if (CMTimeCompare(_contentFile.imageTimeRange.duration, kCMTimeZero) == 1) {
                            clipDuration = CMTimeGetSeconds(_contentFile.imageTimeRange.duration) +  10 *(CMTimeGetSeconds(rangeView.file.imageTimeRange.duration)/rangeView.frame.size.width);
                            timeRange = CMTimeRangeMake(_contentFile.imageTimeRange.start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
                        }else {
                            clipDuration = CMTimeGetSeconds(_contentFile.imageDurationTime) +  10 *(CMTimeGetSeconds(rangeView.file.imageDurationTime)/rangeView.frame.size.width);
                            timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
                        }
                        _contentFile.imageTimeRange = timeRange;
                    }else if (rangeView.file.isReverse) {
                        clipDuration = CMTimeGetSeconds(_contentFile.reverseVideoTrimTimeRange.duration) +  10 *(CMTimeGetSeconds(rangeView.file.reverseVideoTrimTimeRange.duration)/rangeView.frame.size.width);
                        timeRange = CMTimeRangeMake((_contentFile.isReverse ? _contentFile.reverseVideoTrimTimeRange : _contentFile.videoTrimTimeRange).start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
                        _contentFile.reverseVideoTimeRange = timeRange;
                    }else {
                        clipDuration = CMTimeGetSeconds(_contentFile.videoTrimTimeRange.duration) +  10 *(CMTimeGetSeconds(rangeView.file.videoTrimTimeRange.duration)/rangeView.frame.size.width);
                        timeRange = CMTimeRangeMake(_contentFile.videoTrimTimeRange.start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
                        _contentFile.videoTimeRange = timeRange;
                    }
                }
            }
            self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width + 10, self.scrollView.contentSize.height);
            self.videoRangeView.frame = CGRectMake(self.videoRangeView.frame.origin.x, self.videoRangeView.frame.origin.y, self.videoRangeView.frame.size.width+10, self.videoRangeView.frame.size.height);
            self.frameView.frame = self.videoRangeView.frame;
            [self.contentView setFrame:CGRectMake(0, 0, CGRectGetWidth(self.videoRangeView.frame) + self.scrollView.frame.size.width, CGRectGetHeight(self.contentView.frame))];
            self.videoRangeView.image = nil;
            
            NSLog(@"*****videoRangeView : %@",NSStringFromCGRect(self.videoRangeView.frame));
            NSLog(@"*****contentView : %@",NSStringFromCGRect(self.contentView.frame));
            NSLog(@"*****frameView : %@",NSStringFromCGRect(self.frameView.frame));
        }
    }
    else{
        UIImage * imageRange = _videoRangeView.image;
        CGImageRef imageRef =_videoRangeView.image.CGImage;
        CGSize imagesize = _videoRangeView.image.size;
        
        CGImageRef imageRef2 =_videoRangeView.image.CGImage;
        
        CGRect rect = CGRectMake(0, 0, comminuteX*flag, imageRange.size.height*flag);
        CGRect rect1 = CGRectMake(rect.size.width, 0,imageRange.size.width*flag-rect.size.width, imageRange.size.height*flag);
        
        float time = 0;
        float start =time;
        float stop = (beforDuration >0 ? beforDuration : (comminuteX * (duration/self.videoRangeView.frame.size.width)));
        
        float start2 = (beforDuration >0 ? (start + stop) :((comminuteX) * (duration/self.videoRangeView.frame.size.width)));
        float stop2 = (beforDuration >0 ? (duration - stop): ((_videoRangeView.frame.size.width-comminuteX-10) * (duration/self.videoRangeView.frame.size.width)));
        
        CMTimeRange timeRange1 = CMTimeRangeMake(CMTimeMakeWithSeconds(start, TIMESCALE), CMTimeMakeWithSeconds(stop, TIMESCALE));
        CMTimeRange timeRange2 = CMTimeRangeMake(CMTimeMakeWithSeconds(start2, TIMESCALE), CMTimeMakeWithSeconds(stop2, TIMESCALE));
        
        int before = CMTimeGetSeconds(timeRange1.duration) * 100;
        int behand = CMTimeGetSeconds(timeRange2.duration) * 100;
        if(before<0.2*100 || behand <0.2*100){
            _lastLowTime = MIN(CMTimeGetSeconds(timeRange1.duration), CMTimeGetSeconds(timeRange2.duration));
            return NO;
        }
        
        CGImageRef image = CGImageCreateWithImageInRect(imageRef,rect);
        
        CGImageRef image1 = CGImageCreateWithImageInRect(imageRef2, rect1);
        
        UIImage*newImage = [[UIImage alloc] initWithCGImage:image];
        
        UIImage*newImage1 = [[UIImage alloc] initWithCGImage:image1];
        
        _videoRangeView.image = nil;
        _videoRangeView.frame = CGRectMake(_videoRangeView.frame.origin.x, 0, _videoRangeView.frame.size.width+10, self.scrollView.frame.size.height);
        self.frameView.frame = _videoRangeView.frame;
        
        self.scrollView.contentSize = CGSizeMake(_videoRangeView.frame.size.width+self.scrollView.frame.size.width, self.scrollView.contentSize.height);
        
        RDComminuteRangeView *rangeVi = [[RDComminuteRangeView alloc] init];
        rangeVi.frame = CGRectMake(0, 0, comminuteX, _videoRangeView.frame.size.height);
        rangeVi.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
        rangeVi.layer.borderWidth = 1;
        rangeVi.image = newImage;
        rangeVi.contentMode = UIViewContentModeScaleToFill;
        rangeVi.userInteractionEnabled = YES;
        rangeVi.file = [_contentFile mutableCopy];
        rangeVi.file.fileTimeFilterType = kTimeFilterTyp_None;
        rangeVi.file.fileTimeFilterTimeRange = kCMTimeRangeZero;
        if(!_contentFile.isReverse){
            if (_contentFile.isGif) {
                rangeVi.file.imageDurationTime = timeRange1.duration;
                rangeVi.file.imageTimeRange = timeRange1;
            }else {
                rangeVi.file.videoTimeRange = timeRange1;
                rangeVi.file.videoTrimTimeRange = timeRange1;
                rangeVi.file.videoDurationTime = timeRange1.duration;
            }
        }else{
            rangeVi.file.reverseVideoTimeRange      = timeRange1;
            rangeVi.file.reverseVideoTrimTimeRange  = timeRange1;
            rangeVi.file.reverseDurationTime        = timeRange1.duration;
        }
        
        RDComminuteRangeView *rangeVi2 = [[RDComminuteRangeView alloc] init];
        rangeVi2.frame = CGRectMake(comminuteX+10, 0, _videoRangeView.frame.size.width-rangeVi.frame.size.width-10, _videoRangeView.frame.size.height);
        rangeVi2.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
        rangeVi2.layer.borderWidth = 1;
        rangeVi2.image = newImage1;
        rangeVi2.contentMode = UIViewContentModeScaleToFill;
        rangeVi2.userInteractionEnabled = YES;
        rangeVi2.file = [_contentFile mutableCopy];
        rangeVi2.file.fileTimeFilterType = kTimeFilterTyp_None;
        rangeVi2.file.fileTimeFilterTimeRange = kCMTimeRangeZero;
        if(!_contentFile.isReverse){
            if (_contentFile.isGif) {
                rangeVi2.file.imageDurationTime = timeRange2.duration;
                rangeVi2.file.imageTimeRange = timeRange2;
            }else {
                rangeVi2.file.videoTimeRange = timeRange2;
                rangeVi2.file.videoTrimTimeRange = timeRange2;
                rangeVi2.file.videoDurationTime = timeRange2.duration;
            }
        }else{
            rangeVi2.file.reverseVideoTimeRange      = timeRange2;
            rangeVi2.file.reverseVideoTrimTimeRange  = timeRange2;
            rangeVi2.file.reverseDurationTime        = timeRange2.duration;
        }
        
        _videoRangeView.hidden = NO;
        
        [_videoRangeView addSubview:rangeVi];
        [_videoRangeView addSubview:rangeVi2];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteForRangeView:)];
        longPress.numberOfTouchesRequired = 1;
        _videoRangeView.backgroundColor = UIColorFromRGB(NV_Color);
        _videoRangeView.userInteractionEnabled = YES;
        
        [_videoRangeView addGestureRecognizer:longPress];
        
        newImage = nil;
        newImage1 = nil;
        CGImageRelease(image);
        CGImageRelease(image1);
        float clipDuration;
        CMTimeRange timeRanger;
        if (_contentFile.isGif) {
            if (CMTimeCompare(_contentFile.imageTimeRange.duration, kCMTimeZero) == 1) {
                clipDuration = CMTimeGetSeconds(_contentFile.imageTimeRange.duration) +  10 *(CMTimeGetSeconds(_contentFile.imageTimeRange.duration)/self.videoRangeView.frame.size.width);
                
                timeRanger = CMTimeRangeMake(_contentFile.imageTimeRange.start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
            }else {
                clipDuration = CMTimeGetSeconds(_contentFile.imageDurationTime) +  10 *(CMTimeGetSeconds(_contentFile.imageDurationTime)/self.videoRangeView.frame.size.width);
                
                timeRanger = CMTimeRangeMake(_contentFile.imageTimeRange.start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
            }
            _contentFile.imageTimeRange = timeRanger;
        }else if (_contentFile.isReverse) {
            clipDuration = CMTimeGetSeconds(_contentFile.reverseVideoTrimTimeRange.duration) +  10 *(CMTimeGetSeconds(_contentFile.reverseVideoTrimTimeRange.duration)/self.videoRangeView.frame.size.width);
            
            timeRanger = CMTimeRangeMake(_contentFile.reverseVideoTrimTimeRange.start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
            _contentFile.reverseVideoTimeRange = timeRanger;
        }else {
            clipDuration = CMTimeGetSeconds(_contentFile.videoTrimTimeRange.duration) +  10 *(CMTimeGetSeconds(_contentFile.videoTrimTimeRange.duration)/self.videoRangeView.frame.size.width);
            
            timeRanger = CMTimeRangeMake(_contentFile.videoTrimTimeRange.start, CMTimeMakeWithSeconds(clipDuration, TIMESCALE));
            _contentFile.videoTimeRange = timeRanger;
        }
    }
    _videoRangeView.backgroundColor = [UIColor clearColor];
    for (UIImageView *frameImage in self.frameView.subviews) {
        [frameImage removeFromSuperview];
    }
    
    _trimmerArray = [self getTimesFor_videoRangeView];
    return YES;
    
}

- (void)deleteForRangeView:(UILongPressGestureRecognizer *)longPress{
    [_delegate deleteForRangeView:longPress];
}


- (void)dealloc{
    NSLog(@"%s",__func__);
    if(_imageGenerator) [_imageGenerator cancelAllCGImageGeneration];
    _imageGenerator = nil;
    _contentFile = nil;
    
    [_trimmerArray removeAllObjects];
    _thumbChildrens  = nil;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:cutThumbPath]){
        [[NSFileManager defaultManager] removeItemAtPath:cutThumbPath error:nil];
    }
}

@end
