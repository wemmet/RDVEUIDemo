//
//  RDMainViewController.h
//  RDVEUISDK
//
//  Created by emmet on 16/1/12.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocalPhotoCell.h"
#import "RDSVProgressHUD.h"
#import "RDATMHud.h"
#import "RDVEUISDKConfigure.h"

#import "RDOtherAlbumsViewController.h"

typedef void(^RD_selectFinishAction) (NSMutableArray <RDFile *>*filelist);
typedef void(^RD_selectAndTrimFinishAction) (RDFile *videoFile);//20170912 画中画

@interface RDMainViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate>
{
    RDATMHud            *_hud;
    
    //相机胶卷
    UIButton            *_cameraRollBtn;    //相机胶卷 按钮
    
    UIButton            *_selectVideoBtn;
    UILabel             *_selectVideoLabel;
    UIButton            *_selectPhotoBtn;
    UILabel             *_selectPhotoLabel;
    UIButton            *_selectPhotoAndVideoBtn;
    UILabel             *_selectPhotoAndVideoLabel;
    
    UIView              *_navagationTitleView;
    
    UIButton            *_backButton;
    
    UIImageView         *_moreContentView;
    
    UIButton            *_selectOkBtn;
    
    UIScrollView        *_collectionScrollView;
    UICollectionView    *_videoCollection;
    UICollectionView    *_photoCollection;
    UICollectionView    *_VideoAndPhotoCollection;
    
    UIView              *_bottomView;
    UILabel             *_selectCountLabel;

}

@property(nonatomic, strong) CameraConfiguration            *cameraConfig;
@property(nonatomic, strong) EditConfiguration              *editConfig;
@property(nonatomic, strong) ExportConfiguration            *exportConfig;
@property(nonatomic,assign)BOOL                             needPush;
@property(nonatomic,assign)BOOL                             showPhotos;
@property(nonatomic,copy) RD_selectFinishAction             selectFinishActionBlock;    //选择素材后，可编辑，返回RDFile数组
@property(nonatomic, copy) RdVECancelBlock                  cancelBlock;
@property(nonatomic, copy) RdVECallbackBlock                rdVECallbackBlock;
@property (nonatomic,copy) OnAlbumCallbackBlock             onAlbumCallbackBlock;   //直接返回素材地址
@property (nonatomic, assign) BOOL isDisableEdit;   //是否禁止编辑
@property (nonatomic, copy) RD_selectAndTrimFinishAction    selectAndTrimFinishBlock;//20170912 画中画
/**媒体在video中的大小
 */
@property(nonatomic, assign) CGSize         inVideoSize;
@property(nonatomic, copy) NSString         *videoTrimPath;//20170912 画中画 截取后的视频路径
@property (nonatomic,assign)float textPhotoProportion;//文字板比例

/**选择视频的最大个数
 */
@property (nonatomic,assign) int videoCountLimit;

/**选择图片的最大张数
 */
@property (nonatomic,assign) int picCountLimit;

/**选择的最小数目
 */
@property (nonatomic,assign) int minCountLimit;

@end
