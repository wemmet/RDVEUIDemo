//
//  RDLOTEffectBlur.h
//  RDLottieAnimator
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTEffectBlur : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary withFrameSize:(CGSize) frameSize;

@property (nonatomic, readonly) NSString *keyName;
@property (nonatomic, readonly) NSString *keyMatchName;
@property (nonatomic, readonly) int keyType;
@property (nonatomic, readonly) CGSize frameSize;
@property (nonatomic, readonly) RDLOTKeyframeGroup *blur;

@end
