//
//  editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/7.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "filter_editCollageView.h"
#import "toni_editCollageView.h"
#import "volume_editCollageView.h"
#import "beautay_editCollageView.h"
#import "transparency_editCollageView.h"

#import "cutout_editCollageView.h"

#import "mixed_editCollageView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol editCollageViewDelegate <NSObject>

@optional
//显示控件
-(void)showCollageBarItem:( RDPIPFunctionType ) pipType;
//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

//返回
-(void)editCollage_back;

@end


@interface editCollageView : UIView<filter_editCollageViewDelegate,toni_editCollageViewDelegate,volume_editCollageViewDelegate,beautay_editCollageViewDelegate,cutout_editCollageViewDelegate,mixed_editCollageViewDelegate>

@property(nonatomic,strong)UIScrollView     *toolBarView;

@property(nonatomic,weak)id<editCollageViewDelegate>   delegate;

@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画

/** 媒体
 */
@property (nonatomic,strong) VVAsset*  currentVvAsset;

@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core

//滤镜
@property(nonatomic,strong)filter_editCollageView           *collage_filter_View;
//调色
@property(nonatomic,strong)toni_editCollageView             *collage_toni_View;
//抠图
@property(nonatomic,strong)cutout_editCollageView             *collage_cutout_View;
//声音
@property(nonatomic,strong)volume_editCollageView           *collage_volume_View;
//美颜
@property(nonatomic,strong)beautay_editCollageView          *collage_beautay_View;
//透明度
@property(nonatomic,strong)transparency_editCollageView     *collage_transparency_View;
//混合模式
@property(nonatomic,strong)mixed_editCollageView            *collage_mixed_View;
@end

NS_ASSUME_NONNULL_END
