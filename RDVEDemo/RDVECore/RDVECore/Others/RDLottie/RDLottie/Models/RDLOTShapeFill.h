//
//  RDLOTShapeFill.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTShapeFill : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) BOOL fillEnabled;
@property (nonatomic, readonly) RDLOTKeyframeGroup *color;
@property (nonatomic, readonly) RDLOTKeyframeGroup *opacity;
@property (nonatomic, readonly) BOOL evenOddFillRule;

@end

NS_ASSUME_NONNULL_END
