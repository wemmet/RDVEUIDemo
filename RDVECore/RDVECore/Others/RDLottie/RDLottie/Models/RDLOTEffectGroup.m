//
//  RDLOTShape.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTEffectGroup.h"
#import "RDLOTEffect.h"
#import "RDLOTEffectTint.h"
#import "RDLOTEffectBlur.h"
#import "RDLOTEffectDistortion.h"

@implementation RDLOTEffectGroup

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary
               withFrameSize:(CGSize) frameSize{
    self = [super init];
    if (self) {
        [self _mapFromJSON:jsonDictionary withFrameSize:frameSize];
    }
    return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary
       withFrameSize:(CGSize) frameSize{
    
    if (jsonDictionary[@"nm"] ) {
        _keyname = [jsonDictionary[@"nm"] copy];
    }
    
    NSArray *itemsJSON = jsonDictionary[@"ef"];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *itemJSON in itemsJSON) {
        id newItem = [RDLOTEffectGroup effectItemWithJSON:itemJSON withFrameSize:frameSize];
        if (newItem) {
            [items addObject:newItem];
        }
    }
    _items = items;
}

+ (id)effectItemWithJSON:(NSDictionary *)itemJSON withFrameSize:(CGSize) frameSize{
    
//    NSDictionary *effectNames = @{ @0: @"slider",
//                                   @1: @"angle",
//                                   @2: @"color",
//                                   @3: @"point",
//                                   @4: @"checkbox",
//                                   @5: @"group",
//                                   @6: @"noValue",
//                                   @7: @"dropDown",
//                                   @9: @"customValue",
//                                   @10: @"layerIndex",
//                                   @20: @"tint",
//                                   @21: @"fill",
//                                   @29: @"gaussian",
//                                   };
//
//    NSString *typeString = effectNames[itemJSON[@"ty"]];
    NSString *matchNameString = itemJSON[@"mn"];

    if (matchNameString.length && [matchNameString rangeOfString:@"Tint"].location != NSNotFound) {

        RDLOTEffectTint *tint = [[RDLOTEffectTint alloc] initWithJSON:itemJSON];
        return tint;
    }
    else if (matchNameString.length && [matchNameString rangeOfString:@"Blur"].location != NSNotFound) {
        RDLOTEffectBlur *blur = [[RDLOTEffectBlur alloc] initWithJSON:itemJSON withFrameSize:frameSize];
        return blur;
    }
    else if ((matchNameString.length && [matchNameString rangeOfString:@"Bulge"].location != NSNotFound) ||
          (matchNameString.length && [matchNameString rangeOfString:@"Corner"].location != NSNotFound) ||
             (matchNameString.length && [matchNameString rangeOfString:@"BEZMESH"].location != NSNotFound)) {
        RDLOTEffectDistortion *distortion = [[RDLOTEffectDistortion alloc] initWithJSON:itemJSON withFrameSize:frameSize];
        return distortion;
    }

    else {
        NSString *name = itemJSON[@"nm"];
        NSLog(@"%s: Unsupported effect: %@ name: %@", __PRETTY_FUNCTION__, itemJSON[@"ty"], name);
    }
    
    return nil;
}

- (NSString *)description {
    NSMutableString *text = [[super description] mutableCopy];
    [text appendFormat:@" items: %@", self.items];
    return text;
}

@end
