//
//  RDDraftCollectionViewCell.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDDraftManager.h"

NS_ASSUME_NONNULL_BEGIN

@class RDDraftCollectionViewCell;

@protocol  RDDraftCollectionViewCellDelegate<NSObject>

@required

- (void)editDraft:(RDDraftCollectionViewCell *)cell;

- (void)publishDraft:(RDDraftCollectionViewCell *)cell;

- (void)selectDraft:(RDDraftCollectionViewCell *)cell;

@end

@interface RDDraftCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong) UIImageView *coverIV;

@property(nonatomic, strong) UILabel *dateLbl;

@property(nonatomic, strong) UILabel *durationLbl;

@property(nonatomic, strong) UIButton *selectBtn;

@property (nonatomic, strong) RDDraftInfo* draft;

@property (nonatomic, weak) id<RDDraftCollectionViewCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
