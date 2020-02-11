//
//  RDOtherAlbumsViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/3/15.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDOtherAlbumInfo : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) NSMutableArray *videoOrPicArray;

@end

@interface RDOtherAlbumsViewController : UIViewController

@property (nonatomic, assign) SUPPORTFILETYPE supportFileType;

@property (nonatomic, strong) void(^finishBlock)(NSURL *url, UIImage *thumbImage);

@property (nonatomic, strong) void(^finishBlock_main)(PHAsset *asset, UIImage *thumbImage ,BOOL isImage);

@end
