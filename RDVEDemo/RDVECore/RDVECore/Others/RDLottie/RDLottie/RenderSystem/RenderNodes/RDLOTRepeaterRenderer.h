//
//  RDLOTRepeaterRenderer.h
//  RDLottie
//
//  Created by brandon_withrow on 7/28/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"
#import "RDLOTShapeRepeater.h"

@interface RDLOTRepeaterRenderer : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                              shapeRepeater:(RDLOTShapeRepeater *_Nonnull)repeater;

@end
