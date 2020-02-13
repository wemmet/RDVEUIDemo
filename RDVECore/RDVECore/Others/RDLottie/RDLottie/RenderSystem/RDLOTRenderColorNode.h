//
//  RDLOTRenderNode.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import "RDLOTAnimatorNode.h"

@interface RDLOTRenderColorNode : RDLOTAnimatorNode

@property (nonatomic, readonly, strong) CALayer * _Nonnull outputLayer;

- (NSDictionary * _Nonnull)actionsForRenderLayer;

@end
