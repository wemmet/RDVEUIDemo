//
//  RD_AssetModel.m
//  TZImagePickerController
//
//  Created by com.rdtd on 15/12/24.
//  Copyright © 2015年 com.rdtd. All rights reserved.
//

#import "RD_AssetModel.h"
#import "RD_ImageManager.h"

@implementation RD_AssetModel

+ (instancetype)modelWithAsset:(PHAsset *)asset type:(RD_AssetModelMediaType)type{
    RD_AssetModel *model = [[RD_AssetModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(PHAsset *)asset type:(RD_AssetModelMediaType)type timeLength:(NSString *)timeLength {
    RD_AssetModel *model = [self modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    return model;
}

@end



@implementation RDTZAlbumModel

- (void)setResult:(PHFetchResult *)result needFetchAssets:(BOOL)needFetchAssets {
    _result = result;
    if (needFetchAssets) {
        [[RD_ImageManager manager] getAssetsFromFetchResult:result completion:^(NSArray<RD_AssetModel *> *models) {
            self->_models = models;
            if (self->_selectedModels) {
                [self checkSelectedModels];
            }
        }];
    }
}

- (void)setSelectedModels:(NSArray *)selectedModels {
    _selectedModels = selectedModels;
    if (_models) {
        [self checkSelectedModels];
    }
}

- (void)checkSelectedModels {
    self.selectedCount = 0;
    NSMutableArray *selectedAssets = [NSMutableArray array];
    for (RD_AssetModel *model in _selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (RD_AssetModel *model in _models) {
        if ([selectedAssets containsObject:model.asset]) {
            self.selectedCount ++;
        }
    }
}

- (NSString *)name {
    if (_name) {
        return _name;
    }
    return @"";
}

@end
