//
//  cutout_editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/9.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterTextView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol cutout_editCollageViewDelegate <NSObject>

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

@end

@interface cutout_editCollageView : UIView

@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core
@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画
/** 媒体
 */
@property (nonatomic,strong) VVAsset*  currentVvAsset;

@property(nonatomic,strong)RDPasterTextView *pasterView;

@property(nonatomic,weak)id<cutout_editCollageViewDelegate>   delegate;

@property (nonatomic, strong)RDNavigationViewController *navigationController;

//抠图
@property(nonatomic,strong)UIView   *cutoutLabelView;
@property(nonatomic,strong)UIImageView * cutoutImageView;
@property(nonatomic,strong)UILabel  *cutoutLabel;

@property(nonatomic,strong)RDZSlider*cutout_Accuracy_Slider;  //精度
@property(nonatomic,strong)UILabel *cutout_AccuracyCurrentLabel;

@property(nonatomic,strong)UIButton             *cutoutCloseBtn;
@property(nonatomic,strong)UIButton             *cutoutConfirmBtn;

@property(nonatomic,strong)UIButton             *cutoutCancelBtn;

-(void)setCutoutColor:(float) colorRed atColorGreen:(float) colorGreen atColorBlue:(float) colorBlue atAlpha:(float) colorApha;

@end

NS_ASSUME_NONNULL_END
