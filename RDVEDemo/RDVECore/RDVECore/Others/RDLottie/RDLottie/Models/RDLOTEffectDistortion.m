//
//  RDLOTEffectDistortion.m
//  RDLottieAnimator
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//

#import "RDLOTEffectDistortion.h"
#import "CGGeometry+RDLOTAdditions.h"

@implementation RDLOTEffectDistortion

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary withFrameSize:(CGSize) frameSize{
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
  
    if(([_keyMatchName rangeOfString:@"Bulge"].location != NSNotFound) ||
       ([_keyMatchName rangeOfString:@"Corner"].location != NSNotFound) ||
       ([_keyMatchName rangeOfString:@"BEZMESH"].location != NSNotFound))
    {
        NSDictionary *distortion = jsonDictionary[@"v"];
        if (distortion) {
            _distortion = [[RDLOTKeyframeGroup alloc] initWithData:distortion];
        }
        
        @try{
            NSArray *ti = distortion[@"k"][0][@"ti"];
            NSArray *to = distortion[@"k"][0][@"to"];
            
            float ti_x = [[ti objectAtIndex:0] doubleValue];
            float ti_y = [[ti objectAtIndex:1] doubleValue];
            float to_x = [[to objectAtIndex:0] doubleValue];
            float to_y = [[to objectAtIndex:1] doubleValue];
            
            if (ti_x == 0 && ti_y == 0 && to_x == 0 && to_y == 0)
            {
                // “ti” “to” 属性无效
                _invalidSpatialInTangent = true;
                _invalidSpatialOutTangent = true;
            }
            
        }
        @catch(NSException* exception)
        {
            //没有 “ti” “to” 属性
        }
        
        
    
    }
    else {
        NSLog(@"%s: Unsupported name: %@", __PRETTY_FUNCTION__, _keyMatchName);
    }
}

@end
