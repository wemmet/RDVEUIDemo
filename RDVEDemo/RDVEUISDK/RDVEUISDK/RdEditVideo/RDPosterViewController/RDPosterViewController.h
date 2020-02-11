//
//  RDPosterViewController.h
//  RDVEUISDK
//
//  Created by emmet on 2017/7/31.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDFile.h"
#import "RDPosterEditView.h"
#define kNONESELECTEDIT 100
typedef NS_ENUM(NSInteger ,RDProportionType) {
    kPROPORTION_ORIGIN,
    kPROPORTION1_1,
    kPROPORTION4_3,
    kPROPORTION3_4,
    kPROPORTION16_9,
    kPROPORTION9_16,
};

typedef NS_ENUM(NSUInteger, ScrollViewStatus)
{
    kPuzzleScrollView = 0,
    kBorderScrollView,
    kStickerScrollView,
    kFaceScrollView,
    kFilterScrollView,
};

@interface RDPosterViewController : UIViewController<RDPosterEditViewDelegate>

@property(nonatomic,strong) UIImage *image;

@property (nonatomic, strong) NSMutableArray    *assetsImage;

@property (nonatomic, strong) NSMutableArray<RDFile *> *assets;

@property (nonatomic, strong) UIScrollView      *contentView;

@property (nonatomic, assign) BOOL              *isCallBack;

@property (nonatomic, strong) UIImageView       *bringPosterView;

@property (nonatomic, strong) UIImageView       *freeBgView;

@property (nonatomic,assign)RDProportionType proportionValue;
@property (nonatomic,assign)NSInteger      selectStyleIndex;
@property (nonatomic,assign)NSInteger      selectBorderWidthStyle;
@property (nonatomic,assign)NSInteger      selectBorderColorStyle;

@end
