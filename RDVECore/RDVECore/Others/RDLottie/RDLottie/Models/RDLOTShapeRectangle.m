//
//  RDLOTShapeRectangle.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTShapeRectangle.h"

@implementation RDLOTShapeRectangle

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
  
  NSDictionary *position = jsonDictionary[@"p"];
  if (position) {
    _position = [[RDLOTKeyframeGroup alloc] initWithData:position];
  }
  
  NSDictionary *cornerRadius = jsonDictionary[@"r"];
  if (cornerRadius) {
    _cornerRadius = [[RDLOTKeyframeGroup alloc] initWithData:cornerRadius];
  }
  
  NSDictionary *size = jsonDictionary[@"s"];
  if (size) {
    _size = [[RDLOTKeyframeGroup alloc] initWithData:size];
  }
  NSNumber *reversed = jsonDictionary[@"d"];
  _reversed = (reversed.integerValue == 3);
}

@end
