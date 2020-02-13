//
//  RDLOTAnimationView_Internal.h
//  RDLottie
//
//  Created by Brandon Withrow on 12/7/16.
//  Copyright © 2016 Brandon Withrow. All rights reserved.
//

#import "RDLOTAnimationView.h"

typedef enum : NSUInteger {
  RDLOTConstraintTypeAlignToBounds,
  RDLOTConstraintTypeAlignToLayer,
  RDLOTConstraintTypeNone
} RDLOTConstraintType;

@interface RDLOTAnimationView () <CAAnimationDelegate>

- (CALayer * _Nullable)layerForKey:(NSString * _Nonnull)keyname;
- (NSArray * _Nonnull)compositionLayers;

@end
