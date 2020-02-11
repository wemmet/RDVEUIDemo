//
//  LocalPhotoCell.h
//  RDVEUISDK
//
//  Created by emmet on 16/6/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "CircleView.h"
@class LocalPhotoCell;
@protocol LocalPhotoCellDelegate <NSObject>

- (void)addVideo:(LocalPhotoCell *)cell;

@end

@interface LocalPhotoCell : UICollectionViewCell
- (void)setSelectMode:(BOOL)selected;
//@property (strong, nonatomic) ALAsset               *alasset;
//@property (strong, nonatomic) AVURLAsset            *urlAsset;
@property (strong, nonatomic) UIImageView           *ivImageView;

@property (strong, nonatomic) UIView                *durationBlack;

@property (strong, nonatomic) UILabel               *duration;

@property (strong, nonatomic) UILabel               *videoMark;

@property (assign, nonatomic) BOOL                  bSelectHandle;

@property (strong, nonatomic) UIButton              *addBtn;
@property (strong, nonatomic) CircleView            *progressView;
@property (strong, nonatomic) UIImageView           *icloudIcon;
@property (assign, nonatomic) BOOL                  isDownloadingInLocal;

@property (strong, nonatomic) UILabel               *titleLbl;
@property (strong, nonatomic) UILabel               *gifLbl;

@property (nonatomic, weak) id<LocalPhotoCellDelegate> delegate;

@property (nonatomic,assign)  BOOL                  isAll;

//选中动画
@property (nonatomic,strong) UIView                 *animationView;
@property (nonatomic,strong) UILabel                *animationLabel;

-(void)setSelectedAnimation:(int) index;


@property (nonatomic, assign) BOOL                  isPhoto;
@end
