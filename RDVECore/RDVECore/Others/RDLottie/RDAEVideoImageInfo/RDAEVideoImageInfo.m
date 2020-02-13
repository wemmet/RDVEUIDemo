//
//  RDAEVideoImageInfo.m
//  RDVECore
//
//  Created by apple on 2019/3/4.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAEVideoImageInfo.h"

@implementation RDAEScreenshotInfo

- (void)dealloc {
    if (_screenshot) {
        CFRelease(_screenshot);
    }
    _screenshotImage = nil;
}

@end

@implementation RDAEVideoImageInfo

- (instancetype)init{
    self = [super init];
    if (self) {
//        _screenshotArray = [NSMutableArray array];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    RDAEVideoImageInfo *copy   = [[[self class] allocWithZone:zone] init];
    copy.imageName = _imageName;
    copy.startTime = _startTime;
    copy.duration = _duration;
    copy.crop = _crop;
    copy.timeRange = _timeRange;
    copy.size = _size;
    copy.url = _url;
    copy.filterType = _filterType;
    copy.filterUrl = _filterUrl;
    
    return copy;
}

@end
