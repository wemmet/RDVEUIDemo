//
//  RDFXFilter.m
//  RDVEUISDK
//
//  Created by apple on 2019/11/26.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDFXFilter.h"

@implementation RDFXFilter

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDFXFilter *copy = [[self class] allocWithZone:zone];
    copy.ratingFrameTexturePath = _ratingFrameTexturePath;
    copy.customFilter = _customFilter;
    copy.timeFilterType = _timeFilterType;
    copy.filterTimeRangel = _filterTimeRangel;
    copy.FXTypeIndex = _FXTypeIndex;
    copy.nameStr = _nameStr;
    return copy;
}
- (id)copyWithZone:(NSZone *)zone{
    RDFXFilter *copy = [[self class] allocWithZone:zone];
    copy.customFilter = _customFilter;
    copy.timeFilterType = _timeFilterType;
    copy.filterTimeRangel = _filterTimeRangel;
    copy.FXTypeIndex = _FXTypeIndex;
    copy.nameStr = _nameStr;
    return copy;
}

@end
