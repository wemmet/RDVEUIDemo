//
//  RDLOTShapeTrimPath.h
//  RDLottieAnimator
//
//  Created by brandon_withrow on 7/26/16.
//  Copyright © 2016 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTShapeTrimPath : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) RDLOTKeyframeGroup *start;
@property (nonatomic, readonly) RDLOTKeyframeGroup *end;
@property (nonatomic, readonly) RDLOTKeyframeGroup *offset;

@end
