//
//  RDLOTTintCIFilter.h
//  RDLottie
//
//  Created by xiachunlin Withrow on 2019/11/28.
//  Copyright © 2019 Brandon Withrow. All rights reserved.
//
//


#import "RDLOTAnimatorNode.h"


@interface RDLOTTintCIFilter : CIFilter



@property (retain, nonatomic) CIImage *inputImage;
@property (nonatomic, assign) NSNumber *curFrame;
@property (nonatomic, strong) NSMutableArray <AdbeEffect*>* effectArray;

@end
