//
//  PictureMovieViewController_json.h
//  RDVEUISDK
//
//  Created by apple on 2018/6/21.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVECore.h"
#import "RDZSlider.h"
#import "RDExportProgressView.h"
#import "RDAlertView.h"
#import "RDVEUISDKConfigure.h"

@interface AETemplateMovieViewController : UIViewController

/**文件列表
 */
@property(nonatomic,strong)NSMutableArray <RDFile *>*fileList;
/**视频导出分辨率
 */
@property (nonatomic, assign ) CGSize      exportVideoSize;

/**是否是带有Mask的模板
 */
@property (nonatomic, assign) BOOL isMask;

@property(nonatomic,copy) void (^cancelActionBlock)(void);

@end
