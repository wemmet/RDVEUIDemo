//
//  RDLOTMask.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTMask.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTMask

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary {
  self = [super init];
  if (self) {
    [self _mapFromJSON:jsonDictionary];
  }
  return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary {
  NSNumber *closed = jsonDictionary[@"cl"];
  _closed = closed.boolValue;
  
  NSNumber *inverted = jsonDictionary[@"inv"];
  _inverted = inverted.boolValue;
  
  NSString *mode = jsonDictionary[@"mode"];
  if ([mode isEqualToString:@"a"]) {
    _maskMode = RDLOTMaskModeAdd;
  } else if ([mode isEqualToString:@"s"]) {
    _maskMode = RDLOTMaskModeSubtract;
  } else if ([mode isEqualToString:@"i"]) {
    _maskMode = RDLOTMaskModeIntersect;
  } else {
    _maskMode = RDLOTMaskModeUnknown;
  }
  
  NSDictionary *maskshape = jsonDictionary[@"pt"];
  if (maskshape) {
    _maskPath = [[RDLOTKeyframeGroup alloc] initWithData:maskshape];
  }
  
  NSDictionary *opacity = jsonDictionary[@"o"];
  if (opacity) {
    _opacity = [[RDLOTKeyframeGroup alloc] initWithData:opacity];
    [_opacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
  }
  
  NSDictionary *expansion = jsonDictionary[@"x"];
  if (expansion) {
    _expansion = [[RDLOTKeyframeGroup alloc] initWithData:expansion];
  }
}

@end
