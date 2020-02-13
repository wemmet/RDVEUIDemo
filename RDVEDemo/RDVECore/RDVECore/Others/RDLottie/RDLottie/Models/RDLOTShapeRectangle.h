//
//  RDLOTShapeRectangle.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDLOTKeyframe.h"

@interface RDLOTShapeRectangle : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) RDLOTKeyframeGroup *position;
@property (nonatomic, readonly) RDLOTKeyframeGroup *size;
@property (nonatomic, readonly) RDLOTKeyframeGroup *cornerRadius;
@property (nonatomic, readonly) BOOL reversed;

@end
