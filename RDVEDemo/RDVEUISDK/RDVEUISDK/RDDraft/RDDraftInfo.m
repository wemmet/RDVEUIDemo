//
//  RDDraftInfo.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDraftInfo.h"

@implementation RDDraftInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (float)getTotalDuration {
    __block float totalDuration;
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.fileType == kFILEIMAGE || obj.fileType == kTEXTTITLE) {
            totalDuration += CMTimeGetSeconds(obj.imageDurationTime);
        }else {
            if (obj.isReverse) {
                if (CMTimeRangeEqual(kCMTimeRangeZero, obj.reverseVideoTrimTimeRange) || CMTimeRangeEqual(kCMTimeRangeInvalid, obj.reverseVideoTrimTimeRange)) {
                    totalDuration += CMTimeGetSeconds(obj.reverseVideoTimeRange.duration);
                }else {
                    totalDuration += CMTimeGetSeconds(obj.reverseVideoTrimTimeRange.duration);
                }
            }else {
                if (CMTimeRangeEqual(kCMTimeRangeZero, obj.videoTrimTimeRange) || CMTimeRangeEqual(kCMTimeRangeInvalid, obj.videoTrimTimeRange)) {
                    totalDuration += CMTimeGetSeconds(obj.videoTimeRange.duration);
                }else {
                    totalDuration += CMTimeGetSeconds(obj.videoTrimTimeRange.duration);
                }
            }
        }
    }];
    
    return totalDuration;
}

@end
