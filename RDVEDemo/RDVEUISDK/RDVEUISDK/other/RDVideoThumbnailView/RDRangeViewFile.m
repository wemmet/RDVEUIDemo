//
//  RDRangeViewFile.m
//  dyUIAPIDemo
//
//  Created by wuxiaoxia on 2017/5/11.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDRangeViewFile.h"

@implementation RDRangeViewFile

- (instancetype)init{
    if(self = [super init]){
        _start = 0;
        _duration = 0;
        _timeRange = kCMTimeRangeZero;
    }
    return self;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

- (void)setDuration:(Float64)duration{
    _duration = duration;
    _timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(_start, TIMESCALE), CMTimeMakeWithSeconds(_duration, TIMESCALE));
}

- (void)setStart:(Float64)start{
    _start = start;
    _timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(_start, TIMESCALE), CMTimeMakeWithSeconds(_duration, TIMESCALE));

}

@end
