//
//  RDLOTFillRenderer.h
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"
#import "RDLOTShapeFill.h"

@interface RDLOTFillRenderer : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  shapeFill:(RDLOTShapeFill *_Nonnull)fill;

@end
