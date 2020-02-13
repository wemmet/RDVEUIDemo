//
//  RDLOTSizeInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTValueInterpolator.h"
#import "RDLOTValueDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTSizeInterpolator : RDLOTValueInterpolator

- (CGSize)sizeValueForFrame:(NSNumber *)frame;

@property (nonatomic, weak, nullable) id<RDLOTSizeValueDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
