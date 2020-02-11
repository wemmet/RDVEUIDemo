//
//  RD_AssetModel.h
//  TZImagePickerController
//
//  Created by com.rdtd on 15/12/24.
//  Copyright © 2015年 com.rdtd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    RD_AssetModelMediaTypePhoto = 0,
    RD_AssetModelMediaTypeLivePhoto,
    RD_AssetModelMediaTypePhotoGif,
    RD_AssetModelMediaTypeVideo,
    RD_AssetModelMediaTypeAudio
} RD_AssetModelMediaType;

@class PHAsset;
@interface RD_AssetModel : NSObject

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) BOOL isSelected;      ///< The select status of a photo, default is No
@property (nonatomic, assign) RD_AssetModelMediaType type;
@property (assign, nonatomic) BOOL needOscillatoryAnimation;
@property (nonatomic, copy) NSString *timeLength;
@property (strong, nonatomic) UIImage *cachedImage;

/// Init a photo dataModel With a PHAsset
/// 用一个PHAsset实例，初始化一个照片模型
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(RD_AssetModelMediaType)type;
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(RD_AssetModelMediaType)type timeLength:(NSString *)timeLength;

@end


@class PHFetchResult;
@interface RDTZAlbumModel : NSObject

@property (nonatomic, strong) NSString *name;        ///< The album name
@property (nonatomic, assign) NSInteger count;       ///< Count of photos the album contain
@property (nonatomic, strong) PHFetchResult *result;

@property (nonatomic, strong) NSArray *models;
@property (nonatomic, strong) NSArray *selectedModels;
@property (nonatomic, assign) NSUInteger selectedCount;

@property (nonatomic, assign) BOOL isCameraRoll;

- (void)setResult:(PHFetchResult *)result needFetchAssets:(BOOL)needFetchAssets;

@end
