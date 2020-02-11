//
//  mixed_editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/20.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterTextView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol mixed_editCollageViewDelegate <NSObject>

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

@end


@interface mixed_editCollageView : UIView<UIScrollViewDelegate>

@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core
@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画
/** 媒体
 */
@property (nonatomic,strong) VVAsset*  currentVvAsset;

@property(nonatomic,strong)RDPasterTextView *pasterView;

@property(nonatomic,weak)id<mixed_editCollageViewDelegate>   delegate;

@property (nonatomic, strong)RDNavigationViewController        *navigationController;

@property (nonatomic, assign)int                                currentMixedIndex;

//不透明度
@property( nonatomic,strong )RDZSlider                          *mixed_Ttansparency_slider;
//混合 样式
@property(nonatomic,strong)UIScrollView                         *mixed_ScrollView;


@property(nonatomic,strong)UIButton                             *mixed_CloseBtn;
@property(nonatomic,strong)UIButton                             *mixed_ConfirmBtn;


@property(nonatomic,strong)NSMutableArray<NSString *>           *mixed_Array;

-(void)setcurrentMixedIndex:(int) mixedIndex;

@end

NS_ASSUME_NONNULL_END
