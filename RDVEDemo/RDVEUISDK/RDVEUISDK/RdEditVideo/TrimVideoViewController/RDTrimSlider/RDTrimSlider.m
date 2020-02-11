//
//  RDTrimSlider.m
//  RDVEUISDK
//
//  Created by apple on 2019/9/17.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTrimSlider.h"
@interface RDTrimSlider() <UIScrollViewDelegate,CaptionVideoTrimmerDelegate>


@property (strong, nonatomic) UIScrollView *frameVIew;
@property (nonatomic)         NSMutableArray *allImages;

@property (strong, nonatomic) UILabel *currentProgressLabel;
@end

@implementation RDTrimSlider

- (instancetype)initWithFrame:(CGRect)frame videoCore:(RDVECore *)videoCore trimDuration_OneSpecifyTime:(float) trimDuration_OneSpecifyTime
{
    self = [super initWithFrame:frame];
    if (self) {
        _progressValue = 0;
        _currentProgressValue = 0;
        _trimDuration_OneSpecifyTime = trimDuration_OneSpecifyTime;
        _thumbnailCoreSDK = videoCore;
        _TrimmerView = [self TrimmerView];
        [self addSubview:_TrimmerView];
        
        UIImage* image = nil;
        image = [RDHelpClass imageWithContentOfFile:@"AE/剪辑_把手_前_"];
        
        float width = frame.size.width/6;
        
        self.lowerHandle = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width/2.0 - width - 6 + 6, 2.5, 6, frame.size.height)];
        self.lowerHandle.image = image;
        _lowerHandle.layer.cornerRadius = 2.0;
        _lowerHandle.clipsToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"AE/剪辑_把手_后_"];
        self.upperHandle = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2.0 + width, 2.5, 6, self.frame.size.height)];
        self.upperHandle.image = image;
        _upperHandle.layer.cornerRadius = 2.0;
        _upperHandle.clipsToBounds = YES;
        
        _currentProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2.0 - width, 3, 1.5, frame.size.height-6)];
        _currentProgressLabel.layer.cornerRadius = _currentProgressLabel.frame.size.width/2.0;
        _currentProgressLabel.layer.masksToBounds = YES;
        _currentProgressLabel.backgroundColor = [UIColor whiteColor];
        [self addSubview:_currentProgressLabel];
        _currentProgressLabel.hidden = YES;
        
//        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2.0 - width - frame.size.height*( image.size.width/image.size.height )/2.0, 0, width*2+frame.size.height*( image.size.width/image.size.height)+2 , 3)];
//        label.backgroundColor = UIColorFromRGB(0xffffff);
//        [self addSubview:label];
//
//        UILabel * label1 = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2.0 - width - frame.size.height*( image.size.width/image.size.height )/2.0, frame.size.height-3, width*2+frame.size.height*( image.size.width/image.size.height)+2, 3)];
//        label1.backgroundColor = UIColorFromRGB(0xffffff);
//        [self addSubview:label1];
        
        [self addSubview:self.lowerHandle];
        [self addSubview:self.upperHandle];
    }
    return self;
}

- (CaptionVideoTrimmerView *)TrimmerView{
    if(!_TrimmerView)
    {
        CGRect rect = CGRectMake(0, 2, self.frame.size.width, self.frame.size.height - 4);
        _TrimmerView = [[CaptionVideoTrimmerView alloc] initWithFrame:rect videoCore: _thumbnailCoreSDK];
        _TrimmerView.backgroundColor = [UIColor clearColor];
        [_TrimmerView setClipTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_thumbnailCoreSDK.duration, TIMESCALE))];
        [_TrimmerView setThemeColor:[UIColor lightGrayColor]];
        _TrimmerView.tag = 1;
        [_TrimmerView setDelegate:self];
        _TrimmerView.scrollView.decelerationRate = 0.8;
        _TrimmerView.piantouDuration = 0;
        _TrimmerView.pianweiDuration = 0;
        _TrimmerView.rightSpace = 20;
        _TrimmerView.trimDuration_OneSpecifyTime = _trimDuration_OneSpecifyTime;
//        _TrimmerView.layer.borderWidth = 1.0;
//        _TrimmerView.layer.borderColor = TOOLBAR_COLOR.CGColor;
        
        NSMutableArray *thumbTimes = [NSMutableArray array];
        NSNumber *num = [NSNumber numberWithFloat:0.0];
        while ([num floatValue]<_thumbnailCoreSDK.duration) {
            [thumbTimes addObject:num];
            float fNumber = [num floatValue];
            fNumber += (_trimDuration_OneSpecifyTime/2.0);
            num = [NSNumber numberWithFloat:fNumber];
        }
        [thumbTimes addObject: [NSNumber numberWithFloat:_thumbnailCoreSDK.duration]];
        _TrimmerView.thumbTimes = thumbTimes.count;
        [_thumbnailCoreSDK getImageAtTime:kCMTimeZero scale:0.3 completion:^(UIImage *image) {
            [_TrimmerView resetSubviews:image];
        }];
    }
    return _TrimmerView;
}

- (void)loadTrimmerViewThumbImage:(UIImage *)image thumbnailCount:(NSInteger)thumbnailCount
{
    if(_TrimmerView){
        [_TrimmerView setVideoCore:_thumbnailCoreSDK];
        [_TrimmerView setClipTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, TIMESCALE), _thumbnailCoreSDK.composition.duration)];
        _TrimmerView.thumbTimes = thumbnailCount;
        [_TrimmerView resetSubviews:image picWidth:(self.frame.size.width/6)];
        [_TrimmerView setProgress:0 animated:NO];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)interceptProgress:(float) value
{
    _progressValue = value;
    _currentProgressValue = value;
    [_TrimmerView setProgress: (value/_thumbnailCoreSDK.duration)  animated:NO];
}

-(float)progress:(float) value
{
    _currentProgressValue = value;
    float fPercentage = ( (_currentProgressValue - _progressValue)/_trimDuration_OneSpecifyTime );
    float width = (self.frame.size.width/6*2.0 + 3 )*fPercentage;
    _currentProgressLabel.frame = CGRectMake(self.frame.size.width/2.0 - self.frame.size.width/6 + width, 3, 1.5, self.frame.size.height-6);
    if( _currentProgressLabel.hidden )
        _currentProgressLabel.hidden = NO;
    return fPercentage;
}

#pragma mark- CaptionVideoTrimmerDelegate
//进度条
- (void)trimmerView:(id)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    if(startTime < 0)
    {
        startTime = 0;
    }
    
    if( ( startTime > ( _thumbnailCoreSDK.duration - _trimDuration_OneSpecifyTime ) ) )
    {
        startTime = _thumbnailCoreSDK.duration - _trimDuration_OneSpecifyTime;
    }
    
    if( [_delegate respondsToSelector:@selector(trimmerViewProgress:)] )
    {
        _progressValue = startTime;
        _currentProgressValue = startTime;
        [_delegate trimmerViewProgress:startTime];
        if( !_currentProgressLabel.hidden )
            _currentProgressLabel.hidden = YES;
    }
}

@end
