//
//  RDLOTFillRenderer.h
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"
#import "RDLOTEffectDropDown.h"

@interface RDLOTTEffectDropDownRender : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  effectDropDown:(RDLOTEffectDropDown *_Nonnull)dropDown;

@end
