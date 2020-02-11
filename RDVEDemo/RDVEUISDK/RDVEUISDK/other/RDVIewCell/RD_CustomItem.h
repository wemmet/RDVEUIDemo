//
//  RD_CustomItem.h
//  RDVEUISDK
//
//  Created by emmet on 16/6/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>



@interface RD_CustomItem : UIButton
@property (strong, nonatomic) ALAsset               *alasset;
@property (strong, nonatomic) AVURLAsset            *urlAsset;
@property (strong, nonatomic) UIImageView           *ivImageView;

@property (strong, nonatomic) UIView                *durationBack;

@property (strong, nonatomic) UILabel               *duration;

@property (strong, nonatomic) UILabel               *videoMark;

@property (assign, nonatomic) BOOL                  bSelectHandle;

- (void)setSelectMode:(BOOL)bSelect;
@end
