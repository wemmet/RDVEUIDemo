//
//  RDLOTArrayInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTValueInterpolator.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTArrayInterpolator : RDLOTValueInterpolator

- (NSArray *)numberArrayForFrame:(NSNumber *)frame;

@end

NS_ASSUME_NONNULL_END
