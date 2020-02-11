//
//  RDWordSayViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDStrTimeRange : NSObject

@property (nonatomic, assign)CMTime     startTime;
@property (nonatomic, assign)CMTime     AnimationTime;
@property (nonatomic, assign)CMTime     showTime;

@end

@interface RDAudioPathTimeRange : NSObject

@property (nonatomic, assign)CMTimeRange     timeRang;
@property (nonatomic, assign)NSString       *audioPath;

@end

@interface RDWordSayViewController : UIViewController

//@property(nonatomic,strong)NSMutableArray<RDFile*>               *fileList;
//@property(nonatomic,assign)BOOL                                  isFileList;

@property(nonatomic,strong)NSMutableArray<RDAudioPathTimeRange*> *audioPathArray;
@property(nonatomic,strong)NSMutableArray<NSString*>             *strArrry;
@property(nonatomic,strong)NSMutableArray<RDStrTimeRange *>      *strTimeRangeArray;



@property(nonatomic,copy) void (^cancelBlock)(void);

@end

NS_ASSUME_NONNULL_END
