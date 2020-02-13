//
//  RDLOTFillRenderer.h
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"
#import "RDLOTEffectNoValue.h"

@interface RDLOTTEffectNoValueRenderer : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  effectNoValue:(RDLOTEffectNoValue *_Nonnull)noValue;

@end
