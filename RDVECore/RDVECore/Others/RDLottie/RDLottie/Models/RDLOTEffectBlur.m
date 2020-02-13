//
//  RDLOTEffectBlur.m
//  RDLottieAnimator
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//

#import "RDLOTEffectBlur.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTEffectBlur

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary withFrameSize:(CGSize) frameSize {
    self = [super init];
    if (self) {
        _frameSize = frameSize;
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
  
    if([_keyMatchName rangeOfString:@"Blur"].location != NSNotFound)
    {
        NSDictionary *blur = jsonDictionary[@"v"];
        if (blur) {
            _blur = [[RDLOTKeyframeGroup alloc] initWithData:blur];
        }
    }
    else
    {
        
    }
    
}

@end
