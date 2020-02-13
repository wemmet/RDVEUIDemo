//
//  RDLOTPathAnimator.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import "RDLOTRenderNode.h"
#import "RDLOTShapePath.h"
#import "RDLOTEffectSlider.h"
#import "RDLOTRenderColorNode.h"

@interface RDLOTEffecSliderRender : RDLOTRenderColorNode



- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                              effectSlider:(RDLOTEffectSlider *_Nonnull)slider
                                   calayer:(CALayer* _Nonnull)layer;

@end
