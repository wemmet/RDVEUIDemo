//
//  RDDraftEffect.m
//  RDVEUISDK
//
//  Created by apple on 2018/12/27.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDraftEffect.h"
@implementation RDDraftEffectFilterItem

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [@[@"effectFilterItem"] containsObject:propertyName];
}

- (NSDictionary *)JSONObjectForEffectiveTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_effectiveTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setEffectiveTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _effectiveTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

@end

@implementation RDDraftEffectTime

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    return [@[@"effectTime"] containsObject:propertyName];
}

- (NSDictionary *)JSONObjectForEffectiveTimeRange {
    NSDictionary *dic = CFBridgingRelease(CMTimeRangeCopyAsDictionary(_effectiveTimeRange, kCFAllocatorDefault));
    return dic;
}

- (void)setEffectiveTimeRangeWithNSDictionary:(NSDictionary *)dict {
    _effectiveTimeRange = CMTimeRangeMakeFromDictionary((__bridge CFDictionaryRef)dict);
}

@end
