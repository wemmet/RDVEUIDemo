//
//  RDLOTTrimPathNode.h
//  RDLottie
//
//  Created by brandon_withrow on 7/21/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTAnimatorNode.h"
#import "RDLOTShapeTrimPath.h"

@interface RDLOTTrimPathNode : RDLOTAnimatorNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  trimPath:(RDLOTShapeTrimPath *_Nonnull)trimPath;

@end
