//
//  RDLOTShapeStroke.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

typedef enum : NSUInteger {
  RDLOTLineCapTypeButt,
  RDLOTLineCapTypeRound,
  RDLOTLineCapTypeUnknown
} RDLOTLineCapType;

typedef enum : NSUInteger {
  RDLOTLineJoinTypeMiter,
  RDLOTLineJoinTypeRound,
  RDLOTLineJoinTypeBevel
} RDLOTLineJoinType;

@interface RDLOTShapeStroke : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) BOOL fillEnabled;
@property (nonatomic, readonly) RDLOTKeyframeGroup *color;
@property (nonatomic, readonly) RDLOTKeyframeGroup *opacity;
@property (nonatomic, readonly) RDLOTKeyframeGroup *width;
@property (nonatomic, readonly) RDLOTKeyframeGroup *dashOffset;
@property (nonatomic, readonly) RDLOTLineCapType capType;
@property (nonatomic, readonly) RDLOTLineJoinType joinType;

@property (nonatomic, readonly) NSArray *lineDashPattern;

@end
