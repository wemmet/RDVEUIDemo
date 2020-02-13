//
//  RDLOTFillRenderer.m
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//
#import "RDLOTEffectNoValueRenderer.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"
#import "RDLOTHelpers.h"

@implementation RDLOTTEffectNoValueRenderer {
 // RDLOTColorInterpolator *colorInterpolator_;
  RDLOTNumberInterpolator *numInterpolator_;
  

}

- (instancetype)initWithInputNode:(RDLOTAnimatorNode *)inputNode
                                  effectNoValue:(RDLOTEffectNoValue *)noValue {
  self = [super initWithInputNode:inputNode keyName:noValue.keyname];
  if (self) {
      
      numInterpolator_ = [[RDLOTNumberInterpolator alloc] initWithKeyframes:noValue.value.keyframes];
     
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{
           @"Color" : numInterpolator_};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return [numInterpolator_ hasUpdateForFrame:frame];
}

- (void)performLocalUpdate {
//  centerPoint_DEBUG.backgroundColor =  [colorInterpolator_ colorForFrame:self.currentFrame];
//  centerPoint_DEBUG.borderColor = [UIColor lightGrayColor].CGColor;
//  centerPoint_DEBUG.borderWidth = 2.f;
    self.outputLayer.opacity = [numInterpolator_ floatValueForFrame:self.currentFrame];
    self.outputLayer.opacity = 0.2;
    
    self.outputLayer.strokeColor = [UIColor redColor].CGColor;//[colorInterpolator_ colorForFrame:self.currentFrame];
    self.outputLayer.fillColor = [UIColor redColor].CGColor;
    self.outputLayer.borderColor = [UIColor redColor].CGColor;
    self.outputLayer.shadowColor = [UIColor redColor].CGColor;
    self.outputLayer.opacity = 0.2;//[opacityInterpolator_ floatValueForFrame:self.currentFrame];
    self.outputLayer.contentsRect = CGRectMake(0.0, 0.0, 0.5, 0.5);
    
    float value = [numInterpolator_ floatValueForFrame:self.currentFrame];
    NSLog(@"noValue value = %g ",value);
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
