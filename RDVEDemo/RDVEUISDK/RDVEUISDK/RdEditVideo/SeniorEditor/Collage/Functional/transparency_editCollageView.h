//
//  transparency_editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterTextView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol transparency_editCollageViewDelegate <NSObject>

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

@end

@interface transparency_editCollageView : UIView

@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core
@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画
/** 媒体
 */
@property (nonatomic,strong) VVAsset*  currentVvAsset;

@property(nonatomic,strong)RDPasterTextView *pasterView;

@property(nonatomic,weak)id<transparency_editCollageViewDelegate>   delegate;

@property (nonatomic, strong)RDNavigationViewController *navigationController;

//透明度
@property(nonatomic,strong)UIView               *transparencyView;
@property(nonatomic,strong)UIButton               *transparencyBtn;
@property(nonatomic,strong)UILabel              *transparencyCurrentLabel;
@property(nonatomic,strong)RDZSlider            *transparencyProgressSlider;
@property(nonatomic,strong)UIButton             *transparencyCloseBtn;
@property(nonatomic,strong)UIButton             *transparencyConfirmBtn;


@end

NS_ASSUME_NONNULL_END
