//
//  RDLOTShapeGradientFill.h
//  RDLottie
//
//  Created by brandon_withrow on 7/26/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
  RDLOTGradientTypeLinear,
  RDLOTGradientTypeRadial
} RDLOTGradientType;

@interface RDLOTShapeGradientFill : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) NSNumber *numberOfColors;
@property (nonatomic, readonly) RDLOTKeyframeGroup *startPoint;
@property (nonatomic, readonly) RDLOTKeyframeGroup *endPoint;
@property (nonatomic, readonly) RDLOTKeyframeGroup *gradient;
@property (nonatomic, readonly) RDLOTKeyframeGroup *opacity;
@property (nonatomic, readonly) BOOL evenOddFillRule;
@property (nonatomic, readonly) RDLOTGradientType type;

@end

NS_ASSUME_NONNULL_END
