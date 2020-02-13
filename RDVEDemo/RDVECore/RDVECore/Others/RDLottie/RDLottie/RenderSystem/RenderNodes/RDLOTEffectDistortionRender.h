//
//  RDLOTEffectRender.h
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//

#import "RDLOTRenderEffectNode.h"
#import "RDLOTEffectDistortion.h"
#import "RDLOTRenderNode.h"


@interface RDLOTEffectDistortionRender : RDLOTRenderEffectNode


- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                               Effect:(RDLOTEffectDistortion *_Nonnull)effect
                                   calayer:(CALayer* _Nonnull)layer;

- (void)refreshContents:(CALayer *)layer;

- (void)clear;

@end
