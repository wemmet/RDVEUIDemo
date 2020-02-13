//
//  RDLOTShape.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTShapeGroup.h"
#import "RDLOTShapeFill.h"
#import "RDLOTShapePath.h"
#import "RDLOTShapeCircle.h"
#import "RDLOTShapeStroke.h"
#import "RDLOTShapeTransform.h"
#import "RDLOTShapeRectangle.h"
#import "RDLOTShapeTrimPath.h"
#import "RDLOTShapeGradientFill.h"
#import "RDLOTShapeStar.h"
#import "RDLOTShapeRepeater.h"

@implementation RDLOTShapeGroup

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
  
  NSArray *itemsJSON = jsonDictionary[@"it"];
  NSMutableArray *items = [NSMutableArray array];
  for (NSDictionary *itemJSON in itemsJSON) {
    id newItem = [RDLOTShapeGroup shapeItemWithJSON:itemJSON];
    if (newItem) {
      [items addObject:newItem];
    }
  }
  _items = items;
}

+ (id)shapeItemWithJSON:(NSDictionary *)itemJSON {
  NSString *type = itemJSON[@"ty"];
  if ([type isEqualToString:@"gr"]) {
    RDLOTShapeGroup *group = [[RDLOTShapeGroup alloc] initWithJSON:itemJSON];
    return group;
  } else if ([type isEqualToString:@"st"]) {
    RDLOTShapeStroke *stroke = [[RDLOTShapeStroke alloc] initWithJSON:itemJSON];
    return stroke;
  } else if ([type isEqualToString:@"fl"]) {
    RDLOTShapeFill *fill = [[RDLOTShapeFill alloc] initWithJSON:itemJSON];
    return fill;
  } else if ([type isEqualToString:@"tr"]) {
    RDLOTShapeTransform *transform = [[RDLOTShapeTransform alloc] initWithJSON:itemJSON];
    return transform;
  } else if ([type isEqualToString:@"sh"]) {
    RDLOTShapePath *path = [[RDLOTShapePath alloc] initWithJSON:itemJSON];
    return path;
  } else if ([type isEqualToString:@"el"]) {
    RDLOTShapeCircle *circle = [[RDLOTShapeCircle alloc] initWithJSON:itemJSON];
    return circle;
  } else if ([type isEqualToString:@"rc"]) {
    RDLOTShapeRectangle *rectangle = [[RDLOTShapeRectangle alloc] initWithJSON:itemJSON];
    return rectangle;
  } else if ([type isEqualToString:@"tm"]) {
    RDLOTShapeTrimPath *trim = [[RDLOTShapeTrimPath alloc] initWithJSON:itemJSON];
    return trim;
  } else  if ([type isEqualToString:@"gs"]) {
    NSLog(@"%s: Warning: gradient strokes are not supported", __PRETTY_FUNCTION__);
  } else  if ([type isEqualToString:@"gf"]) {
    RDLOTShapeGradientFill *gradientFill = [[RDLOTShapeGradientFill alloc] initWithJSON:itemJSON];
    return gradientFill;
  } else if ([type isEqualToString:@"sr"]) {
    RDLOTShapeStar *star = [[RDLOTShapeStar alloc] initWithJSON:itemJSON];
    return star;
  } else if ([type isEqualToString:@"mm"]) {
    NSString *name = itemJSON[@"nm"];
    NSLog(@"%s: Warning: merge shape is not supported. name: %@", __PRETTY_FUNCTION__, name);
  } else if ([type isEqualToString:@"rp"]) {
    RDLOTShapeRepeater *repeater = [[RDLOTShapeRepeater alloc] initWithJSON:itemJSON];
    return repeater;
  } else {
    NSString *name = itemJSON[@"nm"];
    NSLog(@"%s: Unsupported shape: %@ name: %@", __PRETTY_FUNCTION__, type, name);
  }
  
  return nil;
}

- (NSString *)description {
    NSMutableString *text = [[super description] mutableCopy];
    [text appendFormat:@" items: %@", self.items];
    return text;
}

@end
