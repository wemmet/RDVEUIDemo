//
//  RDLOTEffect.h
//  RDLottieAnimator
//
//  Created by xiachunlin Withrow on 2019/09/29.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTEffect : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyName;
@property (nonatomic, readonly) NSString *keyMatchName;
@property (nonatomic, readonly) int keyType; 
@property (nonatomic, readonly) RDLOTKeyframeGroup *color;
@property (nonatomic, readonly) RDLOTKeyframeGroup *blur;

@end
