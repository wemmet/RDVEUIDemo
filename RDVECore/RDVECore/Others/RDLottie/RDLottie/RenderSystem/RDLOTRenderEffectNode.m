//
//  RDLOTRenderEffectNode.m
//  Pods
//
//  Created by xiachunlin on 0219/09/30.
//
//

#import "RDLOTRenderEffectNode.h"

@implementation RDLOTRenderEffectNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                    keyName:(NSString * _Nullable)keyname {
  self = [super initWithInputNode:inputNode keyName:keyname];
  if (self) {
    _outputLayer = [CALayer new];
    _outputLayer.actions = [self actionsForRenderLayer];
  }
  return self;
}

/// Layer Properties that need to disable implicit animations
- (NSDictionary * _Nonnull)actionsForRenderLayer {
  return @{@"path": [NSNull null]};
}

/// Local interpolators have changed. Update layer specific properties.
- (void)performLocalUpdate {
  
}

/// The path for rendering has changed. Do any rendering required.
- (void)rebuildOutputs {
  
}

- (RDLOTBezierPath *)localPath {
  return self.inputNode.localPath;
}

/// Forwards its input node's output path forwards downstream
- (RDLOTBezierPath *)outputPath {
  return self.inputNode.outputPath;
}

@end
