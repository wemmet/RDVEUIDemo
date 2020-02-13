//
//  RDLOTShapeRectangle.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTEffectSlider : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) RDLOTKeyframeGroup *value;

@end
