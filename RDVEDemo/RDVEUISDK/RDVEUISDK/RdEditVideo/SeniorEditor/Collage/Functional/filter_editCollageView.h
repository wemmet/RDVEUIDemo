//
//  filter_editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/7.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScrollViewChildItem.h"
#import "RDPasterTextView.h"


NS_ASSUME_NONNULL_BEGIN
@protocol filter_editCollageViewDelegate <NSObject>

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

@end


@interface filter_editCollageView : UIView

@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core

@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画

//滤镜
@property(nonatomic,strong)UIView           *filterView;
@property(nonatomic,strong)UIScrollView     *filterChildsView;
@property(nonatomic,strong)NSMutableArray   *filtersName;
@property(nonatomic,strong)NSMutableArray   *filters;
@property(nonatomic,strong)RDZSlider        *filterProgressSlider;
@property(nonatomic,strong)UILabel          *percentageLabel;

@property(nonatomic,strong)NSMutableArray   *globalFilters;

@property(nonatomic,strong)UIView           *toolFilterView;
@property(nonatomic,strong)UIButton         *toolFilterCloseBtn;
@property(nonatomic,strong)UIButton         *toolFilterConfirmBtn;

@property(nonatomic,assign)NSInteger         selectFilterIndex;

//新滤镜
@property (nonatomic, strong) UIView    * fileterNewView;
@property (nonatomic, strong) UIScrollView    *fileterLabelNewScroView;

@property (nonatomic, strong) UIScrollView    *fileterScrollView;
@property(nonatomic,strong)ScrollViewChildItem *originalItem;

@property (nonatomic, strong) UILabel   *filterStrengthLabel;

@property(nonatomic,weak)id<filter_editCollageViewDelegate>   delegate;

@property (nonatomic, strong)RDNavigationViewController *navigationController;

-(void)setNewFilterSortArray:(NSMutableArray *) filterSortArray;
-(void)setNewFiltersNameSortArray:(NSMutableArray *) filtersNameSortArray;

@property(nonatomic,strong)RDPasterTextView *pasterView;


-(NSMutableArray *)getNewFilterSortArray;

-(void)scrollViewIndex:(int) fileterindex;
-(void)filterLabelBtn:(UIButton *) btn;
-(NSInteger)getCurrentlabelFilter;
-(NSInteger)getCurrentFilterIndex;

-(void)setCollageFilters;
@end

NS_ASSUME_NONNULL_END
