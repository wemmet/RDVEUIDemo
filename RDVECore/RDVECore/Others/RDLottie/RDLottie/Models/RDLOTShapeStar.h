//
//  RDLOTShapeStar.h
//  RDLottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

typedef enum : NSUInteger {
  RDLOTPolystarShapeNone,
  RDLOTPolystarShapeStar,
  RDLOTPolystarShapePolygon
} RDLOTPolystarShape;

@interface RDLOTShapeStar : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) RDLOTKeyframeGroup *outerRadius;
@property (nonatomic, readonly) RDLOTKeyframeGroup *outerRoundness;

@property (nonatomic, readonly) RDLOTKeyframeGroup *innerRadius;
@property (nonatomic, readonly) RDLOTKeyframeGroup *innerRoundness;

@property (nonatomic, readonly) RDLOTKeyframeGroup *position;
@property (nonatomic, readonly) RDLOTKeyframeGroup *numberOfPoints;
@property (nonatomic, readonly) RDLOTKeyframeGroup *rotation;

@property (nonatomic, readonly) RDLOTPolystarShape type;

@end
