//
//  RDLOTShapeRectangle.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTEffectDropDown.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTEffectDropDown

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary {
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
  
    NSDictionary *value = jsonDictionary[@"v"];
    if (value) {
        _value = [[RDLOTKeyframeGroup alloc] initWithData:value];
        
    }
}

@end
