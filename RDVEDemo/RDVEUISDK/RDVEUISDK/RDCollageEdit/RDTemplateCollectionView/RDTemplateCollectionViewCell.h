//
//  RDTemplateCollectionViewCell.h
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RDTemplateCollectionViewCell;
@protocol RDTemplateCollectionViewCellDelegate <NSObject>

- (void)deleteVideo:(RDTemplateCollectionViewCell *)cell;
- (void)editVideo:(RDTemplateCollectionViewCell *)cell;
- (void)recordVideo:(RDTemplateCollectionViewCell *)cell;
- (void)zoomRecord:(RDTemplateCollectionViewCell *)cell;
- (void)addLocalVideoVideo:(RDTemplateCollectionViewCell *)cell;

@end

@interface RDTemplateCollectionViewCell : UICollectionViewCell

//视频缩略图
@property (nonatomic, strong) UIImageView *thumbnailIV;

//删除视频
@property (nonatomic, strong) UIButton *deleteBtn;

//编辑视频
@property (nonatomic, strong) UIButton *editBtn;

//录制视频
@property (nonatomic, strong) UIButton *recordBtn;

//全屏／小屏录制视频
@property (nonatomic, strong) UIButton *zoomBtn;

//上传视频
@property (nonatomic, strong) UIButton *addLocalVideoBtn;

@property (nonatomic, weak) id<RDTemplateCollectionViewCellDelegate> delegate;

@end
