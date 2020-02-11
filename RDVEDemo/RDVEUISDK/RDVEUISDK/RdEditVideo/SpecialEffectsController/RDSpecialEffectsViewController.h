//
//  SpecialEffectsViewController.h
//  RDVEUISDK
//
//  Created by apple on 2018/12/25.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDSpecialEffectsViewController : UIViewController

@property (nonatomic, strong) NSMutableArray  *globalFilters;
@property (nonatomic, assign) CGSize exportSize;
@property (nonatomic, copy) RDFile *file;

@property (nonatomic,copy) void (^changeSpecialEffectFinish)( NSInteger customFilterIndex, int customFilterId, TimeFilterType timeFilter, CMTimeRange timeRange , BOOL useToAll);

@end
