//
//  RDChangeTemplateCollectionViewCell.h
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RDChangeTemplateCollectionViewCell;
@protocol RDChangeTemplateCollectionViewCellDelegate <NSObject>

- (void)changeTemplate:(RDChangeTemplateCollectionViewCell *)cell;

@end

@interface RDChangeTemplateCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *templateBtn;

@property (nonatomic, weak) id<RDChangeTemplateCollectionViewCellDelegate> delegate;

@end
