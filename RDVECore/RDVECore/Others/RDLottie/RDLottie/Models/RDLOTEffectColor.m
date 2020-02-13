//
//  RDLOTShapeRectangle.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTEffectColor.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTEffectColor

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
  
  NSDictionary *color = jsonDictionary[@"v"];
    
  
  if (color) {
    _color = [[RDLOTKeyframeGroup alloc] initWithData:color];
     
  }
}

@end
