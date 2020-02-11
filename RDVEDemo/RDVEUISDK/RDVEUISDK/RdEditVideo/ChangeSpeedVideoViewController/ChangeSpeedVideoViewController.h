//
//  ChangeSpeedVideoViewController.h
//  RDVEUISDK
//
//  Created by emmet on 16/7/12.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^RD_changeSpeedVideoFinishAction) (RDFile *thumbFile,BOOL useAllFile);
@interface ChangeSpeedVideoViewController : UIViewController
/**滤镜
 */
@property (nonatomic, strong) NSMutableArray  *globalFilters;
/**选中的当前文件
 */
@property (nonatomic, copy ) RDFile                             *selectFile;
/**选中的滤镜
 */
@property (nonatomic, copy   ) NSString                           *lastACVPath;
/**预览视频尺寸
 */
@property (nonatomic, assign ) CGSize                             editVideoSize;
/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;
/**改变视频(或图片)的播放速度
 */
@property (nonatomic, copy   ) RD_changeSpeedVideoFinishAction    changeSpeedVideoFinishAction;

-(void)setVideoCoreSDK:(RDVECore *) core;
-(void)seekTime:(CMTime) time;
@end
