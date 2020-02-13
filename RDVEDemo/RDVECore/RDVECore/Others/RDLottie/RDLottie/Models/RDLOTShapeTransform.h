//
//  RDLOTShapeTransform.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "RDLOTKeyframe.h"

@interface RDLOTShapeTransform : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) RDLOTKeyframeGroup *position;
@property (nonatomic, readonly) RDLOTKeyframeGroup *anchor;
@property (nonatomic, readonly) RDLOTKeyframeGroup *scale;
@property (nonatomic, readonly) RDLOTKeyframeGroup *rotation;
@property (nonatomic, readonly) RDLOTKeyframeGroup *opacity;

@end
