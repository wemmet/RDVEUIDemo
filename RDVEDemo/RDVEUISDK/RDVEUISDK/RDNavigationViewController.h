//
//  RDNavigationViewController.h
//  RDVEUISDK
//
//  Created by 周晓林 on 2016/11/4.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

@interface RDNavigationViewController : UINavigationController

/**UI设置
 */
@property (nullable,strong) NSMutableArray        *edit_functionLists;
@property (nullable,strong) ExportConfiguration   *exportConfiguration;
@property (nullable,strong) EditConfiguration     *editConfiguration;
@property (nullable,strong) CameraConfiguration   *cameraConfiguration;
/**视频输出路径
 */
@property (copy,nullable)NSString  * outPath;
/*app缓存视频文件夹名称
 */
@property (copy,nullable)NSString  * appAlbumCacheName;
@property (copy,nullable)NSString  * appKey;
@property (copy,nullable)NSString  * licenceKey;
@property (copy,nullable)NSString  * appSecret;

@property (nonatomic, assign) BOOL       statusBarHidden;
@property (nonatomic, assign) FolderType folderType;
@property (nonatomic, assign) float      videoAverageBitRate;
@property (nonatomic, assign) CGRect     waterLayerRect;

@property (nonatomic, copy, nullable) RdVECallbackBlock   callbackBlock;
@property(nonatomic,copy, nullable) RdVECancelBlock cancelHandler;

@property (nonatomic, weak,nullable) id<RDVEUISDKDelegate> rdVeUiSdkDelegate;

@property (nonatomic, assign) BOOL isSingleFunc;


-(nullable UIViewController *)rdPopViewControllerAnimated:(BOOL)animated;

@end
