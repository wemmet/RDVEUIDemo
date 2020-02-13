//
//  RDLOTPathInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTValueInterpolator.h"
#import "RDLOTPlatformCompat.h"
#import "RDLOTBezierPath.h"
#import "RDLOTValueDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTPathInterpolator : RDLOTValueInterpolator

- (RDLOTBezierPath *)pathForFrame:(NSNumber *)frame cacheLengths:(BOOL)cacheLengths;

@property (nonatomic, weak, nullable) id<RDLOTPathValueDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
