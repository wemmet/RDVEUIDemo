//
//  RDLOTPathAnimator.m
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import "RDLOTPathAnimator.h"
#import "RDLOTPathInterpolator.h"

@implementation RDLOTPathAnimator {
  RDLOTShapePath *_pathConent;
  RDLOTPathInterpolator *_interpolator;
}

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                  shapePath:(RDLOTShapePath *_Nonnull)shapePath {
  self = [super initWithInputNode:inputNode keyName:shapePath.keyname];
  if (self) {
    _pathConent = shapePath;
    _interpolator = [[RDLOTPathInterpolator alloc] initWithKeyframes:_pathConent.shapePath.keyframes];
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{@"Path" : _interpolator};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return [_interpolator hasUpdateForFrame:frame];
}

- (void)performLocalUpdate {
  self.localPath = [_interpolator pathForFrame:self.currentFrame cacheLengths:self.pathShouldCacheLengths];
}

@end
