//
//  RDLOTNumberInterpolator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/11/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTValueInterpolator.h"
#import "RDLOTValueDelegate.h"

NS_ASSUME_NONNULL_BEGIN
@interface RDLOTNumberInterpolator : RDLOTValueInterpolator

- (CGFloat)floatValueForFrame:(NSNumber *)frame;

@property (nonatomic, weak, nullable) id<RDLOTNumberValueDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
