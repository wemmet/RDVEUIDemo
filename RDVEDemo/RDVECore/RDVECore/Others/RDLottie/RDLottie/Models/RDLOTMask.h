//
//  RDLOTMask.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

typedef enum : NSUInteger {
  RDLOTMaskModeAdd,
  RDLOTMaskModeSubtract,
  RDLOTMaskModeIntersect,
  RDLOTMaskModeUnknown
} RDLOTMaskMode;

@interface RDLOTMask : NSObject

- (instancetype _Nonnull)initWithJSON:(NSDictionary * _Nonnull)jsonDictionary;

@property (nonatomic, readonly) BOOL closed;
@property (nonatomic, readonly) BOOL inverted;
@property (nonatomic, readonly) RDLOTMaskMode maskMode;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *maskPath;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *opacity;
@property (nonatomic, readonly, nullable) RDLOTKeyframeGroup *expansion;
@end
