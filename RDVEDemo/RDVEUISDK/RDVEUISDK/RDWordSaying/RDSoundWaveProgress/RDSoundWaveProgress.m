//
//  RDSoundWaveProgress.m
//  RDVEUISDK
//
//  Created by apple on 2019/7/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDSoundWaveProgress.h"
#import "RDSoundTimeLine.h"
#import "decibelLine.h"

@interface RDSoundWaveProgress()<UIScrollViewDelegate>
{
    UIScrollView    *soundScrollTimeLine;
    RDSoundTimeLine *soundTimeLine;             //时间刻度
    decibelLine     *soudnDecibelLine;          //声波图
}
@end

@implementation RDSoundWaveProgress

-(void)playProgress:(int) time
{
    float x = (kWIDTH/6.0/maxInterval);
    float width = (kWIDTH/6.0/maxInterval)/3.0;
    soundScrollTimeLine.contentOffset = CGPointMake(x * time + width, 0);
}

-(void)refreshProgress
{
    soudnDecibelLine.currentAudioDecibelNumber = _currentAudioDecibelNumber;
    soudnDecibelLine.decibelArray = _decibelArray;
    
    float x = (kWIDTH/6.0/maxInterval);
    float width = (kWIDTH/6.0/maxInterval)/3.0;
    
    int number = _decibelArray.count-1;
    if( _decibelArray[_decibelArray.count-1].endValue != 0 )
    {
        for (int i = 0; i< _decibelArray.count; i++) {
            if( (_currentAudioDecibelNumber >= _decibelArray[i].startValue) && (_currentAudioDecibelNumber < _decibelArray[i].endValue) )
            {
                number = i;
                break;
            }
        }
        
        if( number == _currentAudioFileNumber )
            return;
        
        if( (number%2) == ((_decibelArray.count-1)%2) )
        {
            soudnDecibelLine.CurrentNumberColor = Main_Color;
            soudnDecibelLine.lastNumberColor = [UIColor whiteColor];
        }
        else
        {
            soudnDecibelLine.CurrentNumberColor = [UIColor whiteColor];
            soudnDecibelLine.lastNumberColor = Main_Color;
        }
    }
    else
    {
        soudnDecibelLine.CurrentNumberColor = Main_Color;
        soudnDecibelLine.lastNumberColor = [UIColor whiteColor];
        int count = _decibelArray[_decibelArray.count-1].decibelArray.count + _decibelArray[_decibelArray.count-1].startValue;
        
        float fwidthX = x*(count-1)+width;
        
        soundScrollTimeLine.contentSize = CGSizeMake(fwidthX + kWIDTH,0);
        soundScrollTimeLine.contentOffset = CGPointMake(x*(_currentAudioDecibelNumber - 1)+width, 0);
        soudnDecibelLine.frame = CGRectMake(kWIDTH/2.0, 23, fwidthX, self.frame.size.height - 23);
    }
    
    _currentAudioFileNumber = number;
    [soudnDecibelLine setNeedsDisplay];
}

-(void)clearTime
{
    soundScrollTimeLine.contentSize = CGSizeMake(1,0);
    soundScrollTimeLine.contentOffset = CGPointMake(0, 0);
    soudnDecibelLine.frame = CGRectMake(kWIDTH/2.0, 23, 1, self.frame.size.height - 23);
    _currentAudioFileNumber = 0;
    [soudnDecibelLine setNeedsDisplay];
}

-(void)deleteRefresh
{
    soudnDecibelLine.currentAudioDecibelNumber = _currentAudioDecibelNumber;
    soudnDecibelLine.decibelArray = _decibelArray;
    
    float x = (kWIDTH/6.0/maxInterval);
    float width = (kWIDTH/6.0/maxInterval)/3.0;
    
    int number = _decibelArray.count-1;
    if( _decibelArray[_decibelArray.count-1].endValue != 0 )
    {
        for (int i = 0; i< _decibelArray.count; i++) {
            if( (_currentAudioDecibelNumber > _decibelArray[i].startValue) && (_currentAudioDecibelNumber <= _decibelArray[i].endValue) )
            {
                number = i;
                break;
            }
        }
        
        if( (number%2) == ((_decibelArray.count-1)%2) )
        {
            soudnDecibelLine.CurrentNumberColor = Main_Color;
            soudnDecibelLine.lastNumberColor = [UIColor whiteColor];
        }
        else
        {
            soudnDecibelLine.CurrentNumberColor = [UIColor whiteColor];
            soudnDecibelLine.lastNumberColor = Main_Color;
        }
    }
    int count = _decibelArray[_decibelArray.count-1].decibelArray.count + _decibelArray[_decibelArray.count-1].startValue;
    float fwidthX = x*(count-1)+width;
    soundScrollTimeLine.contentSize = CGSizeMake(fwidthX + kWIDTH,0);
    soundScrollTimeLine.contentOffset = CGPointMake(x*(_currentAudioDecibelNumber)+width, 0);
    soudnDecibelLine.frame = CGRectMake(kWIDTH/2.0, 23, fwidthX, self.frame.size.height - 23);
    _currentAudioFileNumber = number;
    [soudnDecibelLine setNeedsDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _currentAudioDecibelNumber = 0;
        _maxTime = 60;
        _minTime = 0;
        _currentTime = 0.0;
        float width = (_maxTime - _minTime)/6.0 * kWIDTH + kWIDTH;
        soundScrollTimeLine = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, frame.size.height)];
        [self addSubview:soundScrollTimeLine];
        soundScrollTimeLine.contentSize = CGSizeMake(1, 0);
        soundScrollTimeLine.showsVerticalScrollIndicator = NO;
        soundScrollTimeLine.showsHorizontalScrollIndicator = NO;
        soundScrollTimeLine.delegate = self;
        soundScrollTimeLine.userInteractionEnabled = YES;
//        soundScrollTimeLine.userInteractionEnabled = NO;
        
        self.backgroundColor = TOOLBAR_COLOR;
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 22)];
        label.backgroundColor = SCREEN_BACKGROUND_COLOR;
        [soundScrollTimeLine addSubview:label];
        
        soundTimeLine = [[RDSoundTimeLine alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
        soundTimeLine.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        [soundScrollTimeLine addSubview:soundTimeLine];
        
        soudnDecibelLine = [[decibelLine alloc] initWithFrame:CGRectMake(kWIDTH/2.0, 23, 1, self.frame.size.height - 23)];
        soudnDecibelLine.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        soudnDecibelLine.currentAudioDecibelNumber = Main_Color;

        [soundScrollTimeLine addSubview:soudnDecibelLine];
        
        UILabel *currrentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake( (kWIDTH-1.0)/2.0 , 23, 1.0, self.frame.size.height - 23)];
        currrentTimeLabel.backgroundColor = Main_Color;
        [self addSubview:currrentTimeLabel];
    }
    return self;
}
//UIScrollViewDelegate
//拖动
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"contentOffset.x = %f",scrollView.contentOffset.x);
    if( _decibelArray.count > 0 )
    {
        if( scrollView.contentOffset.x < 0 )
            scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
        else if( _decibelArray[_decibelArray.count-1].endValue != 0 )
        {
            if( scrollView.contentOffset.x > soudnDecibelLine.frame.size.width )
                scrollView.contentOffset = CGPointMake(soudnDecibelLine.frame.size.width, scrollView.contentOffset.y);
        }
        
        _currentTime = scrollView.contentOffset.x/kWIDTH * 6.0;
        if( _minTime > _currentTime )
        {
            _currentTime = _minTime;
        }
        else if( _maxTime < _currentTime )
        {
            _currentTime = _maxTime;
        }
        
        if(  _decibelArray[_decibelArray.count-1].endValue != 0  )
        {
            _currentAudioDecibelNumber = _currentTime*maxInterval;
            [self refreshProgress];
        }
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(CurrentTime:)]) {
        [_delegate CurrentTime:_currentTime];
    }
}

////锁定 不可拖动
//- (void)lockMove
//{
//   soundScrollTimeLine.userInteractionEnabled = NO;
//}
////解锁 可拖动
//- (void)unLockMove
//{
//    soundScrollTimeLine.userInteractionEnabled = YES;
//}
@end
