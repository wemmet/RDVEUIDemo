//
//  RDLOTPathAnimator.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import "RDLOTAnimatorNode.h"
#import "RDLOTShapePath.h"

@interface RDLOTPathAnimator : RDLOTAnimatorNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  shapePath:(RDLOTShapePath *_Nonnull)shapePath;

@end
