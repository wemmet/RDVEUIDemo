//
//  ProgressBar.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/8/16.
//  Copyright © 2016年 周晓林. All rights reserved.
//
#import "RDHelpClass.h"
#import "ProgressBar.h"
#define BAR_H 5
#define BAR_MARGIN 0

#define BAR_BLUE_COLOR UIColorFromRGB(0x00bebe)
#define BAR_RED_COLOR color(224, 66, 39, 1)
#define BAR_BG_COLOR color(38, 38, 38, 1)

#define BAR_MIN_W 80

#define BG_COLOR color(11, 11, 11, 1)

#define INDICATOR_W 8
#define INDICATOR_H 12
#define color(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define TIMER_INTERVAL 1.0f
#define DEVICE_SIZE [[UIScreen mainScreen] applicationFrame].size

@interface ProgressBar ()

@property (strong, nonatomic) NSMutableArray *progressViewArray;

@property (strong, nonatomic) UIView *barView;
@property (strong, nonatomic) UIImageView *progressIndicator;

@property (strong, nonatomic) NSTimer *shiningTimer;

@end

@implementation ProgressBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize
{
    self.autoresizingMask = UIViewAutoresizingNone;
    self.backgroundColor = BG_COLOR;
    self.progressViewArray = [[NSMutableArray alloc] init];
    self.layer.masksToBounds = YES;
    //barView
    self.barView = [[UIView alloc] initWithFrame:CGRectMake(0, BAR_MARGIN, self.frame.size.width, BAR_H)];
    _barView.backgroundColor = [UIColor grayColor];
    [self addSubview:_barView];
    
    //最短分割线
//    UIView *intervalView = [[UIView alloc] initWithFrame:CGRectMake(BAR_MIN_W, 0, 1, BAR_H)];
//    intervalView.backgroundColor = [UIColor blackColor];
//    [_barView addSubview:intervalView];
    
    self.MVMinDurationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, BAR_H)];
    _MVMinDurationView.backgroundColor = [UIColor lightGrayColor];
    _MVMinDurationView.hidden = YES;
    [self addSubview:_MVMinDurationView];
    
    self.squareMinDurationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, BAR_H)];
    _squareMinDurationView.backgroundColor = [UIColor lightGrayColor];
    _squareMinDurationView.hidden = YES;
    [self addSubview:_squareMinDurationView];
    
    self.notSquareMinDurationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, BAR_H)];
    _notSquareMinDurationView.backgroundColor = [UIColor lightGrayColor];
    _notSquareMinDurationView.hidden = YES;
    [self addSubview:_notSquareMinDurationView];
    
    //indicator
    self.progressIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 4, 5)];
    _progressIndicator.backgroundColor = [UIColor clearColor];
    //    _progressIndicator.image = [UIImage imageNamed:@"record_progressbar_front.png"];
    _progressIndicator.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"拍摄_轨道闪烁_@2x" Type:@"png"]];
    
    _progressIndicator.center = CGPointMake(0, BAR_H / 2.0);
    [self addSubview:_progressIndicator];
}

- (UIView *)getProgressView
{
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, BAR_H)];
    progressView.backgroundColor = UIColorFromRGB(0xf87a00);
    progressView.autoresizesSubviews = YES;
    
    return progressView;
}

- (void)refreshIndicatorPosition
{
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        _progressIndicator.center = CGPointMake(0, BAR_H / 2.0 );
        return;
    }
    
    _progressIndicator.center = CGPointMake(MIN(lastProgressView.frame.origin.x + lastProgressView.frame.size.width, self.frame.size.width - _progressIndicator.frame.size.width / 2 + 2), BAR_H / 2.0);
}

- (void)onTimer:(NSTimer *)timer
{
    [UIView animateWithDuration:TIMER_INTERVAL / 2 animations:^{
        _progressIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:TIMER_INTERVAL / 2 animations:^{
            _progressIndicator.alpha = 1;
        }];
    }];
}

#pragma mark - method
- (void)startShining
{
    self.shiningTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}

- (void)stopShining
{
    [_shiningTimer invalidate];
    self.shiningTimer = nil;
    _progressIndicator.alpha = 1;
}

- (void)addProgressView
{
    UIView *lastProgressView = [_progressViewArray lastObject];
    CGFloat newProgressX = 0.0f;
    
    if (lastProgressView) {
        CGRect frame = lastProgressView.frame;
        frame.size.width -= 1;
        lastProgressView.frame = frame;
        
        newProgressX = frame.origin.x + frame.size.width + 1;
    }
    
    UIView *newProgressView = [self getProgressView];
    [RDHelpClass setView:newProgressView toOriginX:newProgressX];
    
    [_barView addSubview:newProgressView];
    
    [_progressViewArray addObject:newProgressView];
}

- (void)setLastProgressToWidth:(CGFloat)width
{
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        return;
    }
    
    [RDHelpClass setView:lastProgressView toSizeWidth:width];
    [self refreshIndicatorPosition];
}
- (BOOL) getProgressIndicatorHiddenState
{
    return _progressIndicator.hidden;
}
- (void) setAllProgressToNormal
{
    [_progressViewArray enumerateObjectsUsingBlock:^(UIView*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.backgroundColor = UIColorFromRGB(0xf87a00);
    }];
}
- (void)setLastProgressToStyle:(ProgressBarProgressStyle)style
{
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        return;
    }
    
    switch (style) {
        case ProgressBarProgressStyleDelete:
        {
            lastProgressView.backgroundColor = BAR_RED_COLOR;
            _progressIndicator.hidden = YES;
        }
            break;
        case ProgressBarProgressStyleNormal:
        {
            lastProgressView.backgroundColor = UIColorFromRGB(0xf87a00);
            _progressIndicator.hidden = NO;
        }
            break;
        default:
            break;
    }
}
- (void) deleteAllProgress
{
    [_progressViewArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [_progressViewArray removeAllObjects];
    _progressIndicator.hidden = NO;
    
    [self refreshIndicatorPosition];

}
- (void)deleteLastProgress
{
    UIView *lastProgressView = [_progressViewArray lastObject];
    if (!lastProgressView) {
        return;
    }
    
    [lastProgressView removeFromSuperview];
    [_progressViewArray removeLastObject];
    
    _progressIndicator.hidden = NO;
    
    [self refreshIndicatorPosition];
}

+ (ProgressBar *)getInstance
{
    ProgressBar *progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, BAR_H)];
    return progressBar;
}

@end
