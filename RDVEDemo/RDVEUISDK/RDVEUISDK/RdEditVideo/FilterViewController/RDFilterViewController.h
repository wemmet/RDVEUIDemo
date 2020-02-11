//
//  RDFilterViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/3.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDFilterViewController : UIViewController

@property (nonatomic, strong) NSMutableArray  *globalFilters;
@property (nonatomic, strong) NSMutableArray *filtersName;
//新滤镜
@property (nonatomic, strong) NSMutableArray              *NewFilterSortArray;
@property (nonatomic, strong) NSMutableArray              *NewFiltersNameSortArray;


@property (nonatomic, assign) CGSize exportSize;

@property (nonatomic, copy) RDFile *file;

@property (nonatomic,copy) void (^changeFilterFinish)(NSInteger filterIndex, VVAssetFilter filterType, float filterIntensity,  NSURL *filterUrl, BOOL useToAll);

-(void)seekTime:(CMTime) time;
-(void)setVideoCoreSDK:(RDVECore *) core;

@end
