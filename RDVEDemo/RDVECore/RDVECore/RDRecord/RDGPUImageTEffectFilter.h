//
//  RDGPUImageTEffectFilter.h
//  RDVECore
//
//  Created by 周晓林 on 2017/6/19.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDGPUImageTwoInputFilter.h"
@interface RDGPUImageTEffectFilter : RDGPUImageTwoInputFilter
@property (nonatomic,assign) float value;
@property (nonatomic,assign) int orient;
@end
