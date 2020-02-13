//
//  RDLOTShapePath.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTShapePath : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) BOOL closed;
@property (nonatomic, readonly) NSNumber *index;
@property (nonatomic, readonly) RDLOTKeyframeGroup *shapePath;

@end
