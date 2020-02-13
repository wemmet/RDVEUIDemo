//
//  RDLOTValueInterpolator.h
//  Pods
//
//  Created by brandon_withrow on 7/10/17.
//
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"
#import "RDLOTValueDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTValueInterpolator : NSObject

- (instancetype)initWithKeyframes:(NSArray <RDLOTKeyframe *> *)keyframes;

@property (nonatomic, weak, nullable) RDLOTKeyframe *leadingKeyframe;
@property (nonatomic, weak, nullable) RDLOTKeyframe *trailingKeyframe;
@property (nonatomic, readonly) BOOL hasDelegateOverride;

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate;

- (BOOL)hasUpdateForFrame:(NSNumber *)frame;
- (CGFloat)progressForFrame:(NSNumber *)frame;

@end

NS_ASSUME_NONNULL_END
