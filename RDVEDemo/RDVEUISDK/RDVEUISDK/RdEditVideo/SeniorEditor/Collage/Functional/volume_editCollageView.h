//
//  volume_editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterTextView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol volume_editCollageViewDelegate <NSObject>

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

@end


@interface volume_editCollageView : UIView


@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core
@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画
/** 媒体
 */
@property (nonatomic,strong) VVAsset*  currentVvAsset;

@property(nonatomic,strong)RDPasterTextView *pasterView;

@property(nonatomic,weak)id<volume_editCollageViewDelegate>   delegate;

@property (nonatomic, strong)RDNavigationViewController *navigationController;


//音量
@property(nonatomic,strong)UIView               *volumeView;  //音量界面
//@property(nonatomic,strong)UIView               *vloumeBtnView;
@property(nonatomic,strong)UIButton             *volumeCloseBtn;
@property(nonatomic,strong)UIButton             *volumeConfirmBtn;

@property(nonatomic,strong)UILabel              *vloumeCurrentLabel;
@property(nonatomic,strong)RDZSlider            *volumeProgressSlider;

//淡入淡出
@property(nonatomic,strong)RDZSlider            *fadeInVolumeSlider;
@property(nonatomic,strong)RDZSlider            *fadeOutVolumeSlider;

//选择器
@property(nonatomic,strong)UIView               *vloume_navagatio_View;
@property(nonatomic,strong)UIButton             *vloumeBtn;
@property(nonatomic,strong)UIButton             *fadeInOrOutBtn;
@property(nonatomic,strong)UIView               *volumeFadeView;

@end

NS_ASSUME_NONNULL_END
