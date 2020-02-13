//
//  RDCameraFile.m
//  RDVECore
//
//  Created by emmet on 2017/5/22.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "RDCameraFile.h"

@implementation RDCameraFile

@end

@implementation RDCameraMVEffect

@end

@implementation RDCameraCustomAnimate

- (instancetype)init {
    self = [super init];
    if (self) {
        _scale = 1.0;
        _crop = CGRectMake(0.0, 0.0, 1.0, 1.0);
    }
    
    return self;
}

@end
