//
//  RDLOTEffectTint.m
//  RDLottieAnimator
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//

#import "RDLOTEffectTint.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTEffectTint

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary {
    self = [super init];
    if (self) {
      [self _mapFromJSON:jsonDictionary];
    }
    return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary {
  
    if (jsonDictionary[@"nm"] ) {
        _keyName = [jsonDictionary[@"nm"] copy];
    }
    if (jsonDictionary[@"mn"] ) {
        _keyMatchName = [jsonDictionary[@"mn"] copy];
    }
    
    _keyType = -1;
    if (jsonDictionary[@"ty"] ) {
        _keyType = [[jsonDictionary[@"ty"] copy] intValue];
    }
  
    if([_keyMatchName rangeOfString:@"Tint"].location != NSNotFound)
    {
        NSDictionary *color = jsonDictionary[@"v"];
        if (color) {
            _color = [[RDLOTKeyframeGroup alloc] initWithData:color];
        }
    }
    else
    {
        
    }
    
}

@end
