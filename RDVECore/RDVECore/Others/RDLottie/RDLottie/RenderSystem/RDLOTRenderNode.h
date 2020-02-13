//
//  RDLOTRenderNode.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import "RDLOTAnimatorNode.h"

@interface RDLOTRenderNode : RDLOTAnimatorNode

@property (nonatomic, readonly, strong) CAShapeLayer * _Nonnull outputLayer;

- (NSDictionary * _Nonnull)actionsForRenderLayer;

@end
