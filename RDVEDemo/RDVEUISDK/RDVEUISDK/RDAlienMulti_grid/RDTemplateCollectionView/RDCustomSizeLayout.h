//
//  CustomSizeLayout.h
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.

#import <UIKit/UIKit.h>

@interface RDCustomRect: NSObject

@property (nonatomic, assign) CGRect rect;

+(RDCustomRect *) InitRDCustomRect:(CGRect) rect;
@end

@interface RDCustomSizeLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) NSInteger templateIndex;
@property (nonatomic, assign) NSInteger templateType;
@property (nonatomic, assign) float templateBorderWidth;

+(id)maskDictionary:(NSString *) path;

@end
