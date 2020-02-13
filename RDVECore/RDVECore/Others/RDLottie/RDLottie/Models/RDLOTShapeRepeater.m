//
//  RDLOTShapeRepeater.m
//  RDLottie
//
//  Created by brandon_withrow on 7/28/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTShapeRepeater.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTShapeRepeater

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary  {
  self = [super init];
  if (self) {
    [self _mapFromJSON:jsonDictionary];
  }
  return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary {
  
  if (jsonDictionary[@"nm"] ) {
    _keyname = [jsonDictionary[@"nm"] copy];
  }
  
  NSDictionary *copies = jsonDictionary[@"c"];
  if (copies) {
    _copies = [[RDLOTKeyframeGroup alloc] initWithData:copies];
  }
  
  NSDictionary *offset = jsonDictionary[@"o"];
  if (offset) {
    _offset = [[RDLOTKeyframeGroup alloc] initWithData:offset];
  }
  
  NSDictionary *transform = jsonDictionary[@"tr"];
  
  NSDictionary *rotation = transform[@"r"];
  if (rotation) {
    _rotation = [[RDLOTKeyframeGroup alloc] initWithData:rotation];
    [_rotation remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_DegreesToRadians(inValue);
    }];
  }
  
  NSDictionary *startOpacity = transform[@"so"];
  if (startOpacity) {
    _startOpacity = [[RDLOTKeyframeGroup alloc] initWithData:startOpacity];
    [_startOpacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
  }
  
  NSDictionary *endOpacity = transform[@"eo"];
  if (endOpacity) {
    _endOpacity = [[RDLOTKeyframeGroup alloc] initWithData:endOpacity];
    [_endOpacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
  }
  
  NSDictionary *anchorPoint = transform[@"a"];
  if (anchorPoint) {
    _anchorPoint = [[RDLOTKeyframeGroup alloc] initWithData:anchorPoint];
  }
  
  NSDictionary *position = transform[@"p"];
  if (position) {
    _position = [[RDLOTKeyframeGroup alloc] initWithData:position];
  }
  
  NSDictionary *scale = transform[@"s"];
  if (scale) {
    _scale = [[RDLOTKeyframeGroup alloc] initWithData:scale];
    [_scale remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return RDLOT_RemapValue(inValue, -100, 100, -1, 1);
    }];
  }
}

@end
