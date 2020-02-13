//
//  RDLOTRoundedRectAnimator.h
//  RDLottie
//
//  Created by brandon_withrow on 7/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTAnimatorNode.h"
#import "RDLOTShapeRectangle.h"

@interface RDLOTRoundedRectAnimator : RDLOTAnimatorNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                shapeRectangle:(RDLOTShapeRectangle *_Nonnull)shapeRectangle;


@end
