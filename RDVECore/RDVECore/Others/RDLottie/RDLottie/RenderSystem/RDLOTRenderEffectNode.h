//
//  RDLOTRenderEffectNode.h
//  Pods
//
//  Created by xiachunlin on 0219/09/30.
//
//

#import "RDLOTAnimatorNode.h"

@interface RDLOTRenderEffectNode : RDLOTAnimatorNode

@property (nonatomic, readonly, strong) CALayer * _Nonnull outputLayer;

- (NSDictionary * _Nonnull)actionsForRenderLayer;

@end
