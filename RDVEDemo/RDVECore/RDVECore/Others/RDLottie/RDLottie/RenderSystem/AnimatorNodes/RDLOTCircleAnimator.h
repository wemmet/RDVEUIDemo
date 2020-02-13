//
//  RDLOTCircleAnimator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTAnimatorNode.h"
#import "RDLOTShapeCircle.h"

@interface RDLOTCircleAnimator : RDLOTAnimatorNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  shapeCircle:(RDLOTShapeCircle *_Nonnull)shapeCircle;

@end
