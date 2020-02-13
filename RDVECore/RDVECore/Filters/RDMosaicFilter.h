//
//  RDMosaicFilter.h
//  RDVECore
//
//  Created by 周晓林 on 2018/4/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageFilter.h"
#import "RDScene.h"

@interface RDMosaicFilter : RDGPUImageFilter


@property (nonatomic, strong) NSMutableArray<RDMosaic*>* mosaics;

- (instancetype) initWithImageNamed:(NSString *) name;
- (instancetype) initWithImage:(UIImage *) image;
- (instancetype)initWithImagePath:(NSString *)path;
- (instancetype)initWithImageNetPath:(NSString *)path;


@end
