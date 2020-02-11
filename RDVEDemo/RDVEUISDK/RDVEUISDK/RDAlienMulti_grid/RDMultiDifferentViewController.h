//
//  RDMultiDifferentViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/5/29.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"



NS_ASSUME_NONNULL_BEGIN

@interface RDMultiDifferentViewController : UIViewController

@property(nonatomic,strong)NSMutableArray <RDFile *>*fileList;

@property(nonatomic,copy) void (^cancelBlock)();
/**视频导出分辨率
 */
@property (nonatomic, assign ) CGSize      exportVideoSize;
/**音乐音量
 */
@property(nonatomic,assign)float            musicVolume;
/**音乐地址
 */
@property(nonatomic,strong)NSURL            *musicURL;
/**音乐时间范围
 */
@property(nonatomic,assign)CMTimeRange      musicTimeRange;

+ (NSString *)saveImage:(NSURL *)fileURL image:(UIImage *)image atPosition:(NSString *) str;
@end


NS_ASSUME_NONNULL_END
