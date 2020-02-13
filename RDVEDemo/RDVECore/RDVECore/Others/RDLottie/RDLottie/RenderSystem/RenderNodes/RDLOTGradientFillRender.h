//
//  RDLOTGradientFillRender.h
//  RDLottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"
#import "RDLOTShapeGradientFill.h"

@interface RDLOTGradientFillRender : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                          shapeGradientFill:(RDLOTShapeGradientFill *_Nonnull)fill;

@end
