//
//  RDLOTFillRenderer.m
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTFillRenderer.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"

@implementation RDLOTFillRenderer {
  RDLOTColorInterpolator *colorInterpolator_;
  RDLOTNumberInterpolator *opacityInterpolator_;
  BOOL _evenOddFillRule;
  CALayer *centerPoint_DEBUG;
}

- (instancetype)initWithInputNode:(RDLOTAnimatorNode *)inputNode
                                  shapeFill:(RDLOTShapeFill *)fill {
  self = [super initWithInputNode:inputNode keyName:fill.keyname];
  if (self) {
    colorInterpolator_ = [[RDLOTColorInterpolator alloc] initWithKeyframes:fill.color.keyframes];
    opacityInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:fill.opacity.keyframes];
    centerPoint_DEBUG = [CALayer layer];
    centerPoint_DEBUG.bounds = CGRectMake(0, 0, 20, 20);
    if (ENABLE_DEBUG_SHAPES) {
      [self.outputLayer addSublayer:centerPoint_DEBUG];
    }
    _evenOddFillRule = fill.evenOddFillRule;
    self.outputLayer.fillRule = _evenOddFillRule ? @"even-odd" : @"non-zero";
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{@"Color" : colorInterpolator_,
           @"Opacity" : opacityInterpolator_};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return [colorInterpolator_ hasUpdateForFrame:frame] || [opacityInterpolator_ hasUpdateForFrame:frame];
}

- (void)performLocalUpdate {
  centerPoint_DEBUG.backgroundColor =  [colorInterpolator_ colorForFrame:self.currentFrame];
  centerPoint_DEBUG.borderColor = [UIColor lightGrayColor].CGColor;
  centerPoint_DEBUG.borderWidth = 2.f;
  self.outputLayer.fillColor = [colorInterpolator_ colorForFrame:self.currentFrame];
  self.outputLayer.opacity = [opacityInterpolator_ floatValueForFrame:self.currentFrame];
}

- (void)rebuildOutputs {
  self.outputLayer.path = self.inputNode.outputPath.CGPath;
}

- (NSDictionary *)actionsForRenderLayer {
  return @{@"backgroundColor": [NSNull null],
           @"fillColor": [NSNull null],
           @"opacity" : [NSNull null]};
}

@end
