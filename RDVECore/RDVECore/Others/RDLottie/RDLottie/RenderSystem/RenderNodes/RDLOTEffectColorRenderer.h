//
//  RDLOTFillRenderer.h
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderColorNode.h"
#import "RDLOTEffectColor.h"

@interface RDLOTEffectColorRenderer : RDLOTRenderColorNode


- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               effectColor:(RDLOTEffectColor *_Nonnull)color
                                   calayer:(CALayer* _Nonnull)layer;

@end
