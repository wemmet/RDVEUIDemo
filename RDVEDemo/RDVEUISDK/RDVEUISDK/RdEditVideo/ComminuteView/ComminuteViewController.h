//
//  ComminuteViewController.h
//  RDVEUISDK
//
//  Created by emmet on 15/8/24.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

/* 截取 */

#import <UIKit/UIKit.h>
#import "RDThumbImageView.h"
typedef void(^ VideoForComminute)(NSMutableArray *childs);
@protocol ComminuteViewControllerDelegate;

@interface ComminuteViewController : UIViewController
/**滤镜
 */
@property (nonatomic, strong) NSMutableArray  *globalFilters;
/**分割完成
 */
@property (nonatomic, strong ) VideoForComminute            comminuteVideoFinishBlock;
/**acv滤镜
 */
@property (nonatomic, copy   ) NSString                     *lastACVPath;
/**需要分割的文件
 */
@property (nonatomic, strong ) RDFile                       *originFile;
/**视频预览尺寸
 */
@property (nonatomic, assign ) CGSize                       editVideoSize;
/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;

-(void)setVideoCoreSDK:(RDVECore *) core;
-(void)seekTime:(CMTime) time;
@end
