//
//  RDLOTShapeRepeater.h
//  RDLottie
//
//  Created by brandon_withrow on 7/28/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTShapeRepeater : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *copies;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *offset;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *anchorPoint;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *scale;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *position;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *rotation;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *startOpacity;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *endOpacity;

@end

NS_ASSUME_NONNULL_END
