//
//  RDLOTColorInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTValueInterpolator.h"
#import "RDLOTPlatformCompat.h"
#import "RDLOTValueDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTColorInterpolator : RDLOTValueInterpolator

- (CGColorRef)colorForFrame:(NSNumber *)frame;

@property (nonatomic, weak, nullable) id<RDLOTColorValueDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
