//
//  RDLOTMaskContainer.h
//  RDLottie
//
//  Created by brandon_withrow on 7/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RDLOTMask.h"

@interface RDLOTMaskContainer : CALayer

- (instancetype _Nonnull)initWithMasks:(NSArray<RDLOTMask *> * _Nonnull)masks;

@property (nonatomic, strong, nullable) NSNumber *currentFrame;

@end
