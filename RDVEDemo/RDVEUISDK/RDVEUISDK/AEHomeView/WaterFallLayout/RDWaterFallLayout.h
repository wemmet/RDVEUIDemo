//
//  RDWaterFallLayout.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RDWaterFallLayout;

@protocol  RDWaterFallLayoutDataSource<NSObject>

@required
/**
 * 每个item的高度
 */
- (CGFloat)waterFallLayout:(RDWaterFallLayout *)waterFallLayout heightForItemAtIndexPath:(NSUInteger)indexPath itemWidth:(CGFloat)itemWidth;

@optional
/**
 * 有多少列
 */
- (NSUInteger)columnCountInWaterFallLayout:(RDWaterFallLayout *)waterFallLayout;

/**
 * 每列之间的间距
 */
- (CGFloat)columnMarginInWaterFallLayout:(RDWaterFallLayout *)waterFallLayout;

/**
 * 每行之间的间距
 */
- (CGFloat)rowMarginInWaterFallLayout:(RDWaterFallLayout *)waterFallLayout;

/**
 * 每个item的内边距
 */
- (UIEdgeInsets)edgeInsetdInWaterFallLayout:(RDWaterFallLayout *)waterFallLayout;


@end

@interface RDWaterFallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<RDWaterFallLayoutDataSource> dataSource;

@end
