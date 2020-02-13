//
//  RDLOTStrokeRenderer.h
//  RDLottie
//
//  Created by brandon_withrow on 7/17/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"
#import "RDLOTShapeStroke.h"

@interface RDLOTStrokeRenderer : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                shapeStroke:(RDLOTShapeStroke *_Nonnull)stroke;


@end
