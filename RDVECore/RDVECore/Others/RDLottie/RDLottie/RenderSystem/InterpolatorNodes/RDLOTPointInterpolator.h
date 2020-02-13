//
//  RDLOTPointInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/12/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTValueInterpolator.h"
#import "RDLOTValueDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTPointInterpolator : RDLOTValueInterpolator

- (CGPoint)pointValueForFrame:(NSNumber *)frame;

@property (nonatomic, weak, nullable) id<RDLOTPointValueDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
