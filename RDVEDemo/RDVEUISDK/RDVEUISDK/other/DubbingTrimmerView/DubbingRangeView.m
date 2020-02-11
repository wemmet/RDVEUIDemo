//
//  DubbingRangeView.m
//  RDVEUISDK
//
//  Created by emmet on 15/10/9.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import "DubbingRangeView.h"

@implementation DubbingRangeViewFile

- (NSDictionary *)JSONObjectForDubbingStartTime {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_dubbingStartTime, kCFAllocatorDefault));
    return dic;
}

- (void)setDubbingStartTimeWithNSDictionary:(NSDictionary *)dict {
    _dubbingStartTime = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

- (NSDictionary *)JSONObjectForDubbingDuration {
    NSDictionary *dic = CFBridgingRelease(CMTimeCopyAsDictionary(_dubbingDuration, kCFAllocatorDefault));
    return dic;
}

- (void)setDubbingDurationWithNSDictionary:(NSDictionary *)dict {
    _dubbingDuration = CMTimeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

@end

@implementation DubbingRangeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [Main_Color colorWithAlphaComponent:0.66];
        self.alpha = 1;
    }
    return self;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
