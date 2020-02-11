//
//  RD_SortViewController.h
//  RDVEUISDK
//
//  Created by emmet on 16/7/7.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDReorderableCollectionViewFlowLayout.h"
typedef void(^RD_SortFinishAction) (NSMutableArray *thumbImageFilelist);

@interface RD_SortViewController : UIViewController

@property (nonatomic,assign)bool isShowDelete;          //是否显示删除按钮

@property (nonatomic,strong)NSMutableArray *allThumbFiles;
@property (nonatomic,assign)CGSize editorVideoSize;//20161013 bug74
@property (nonatomic,copy)RD_SortFinishAction finishAction;
@property (nonatomic,copy)RD_SortFinishAction cancelAction;
@property (nonatomic,assign)int maxImageCount;

@end
