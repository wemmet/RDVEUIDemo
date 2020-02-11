//
//  RDDraftManager.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDDraftManager.h"
#import <Photos/Photos.h>

@implementation RDDraftManager

+ (instancetype)sharedManager
{
    static RDDraftManager *singleOjbect = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleOjbect = [[self alloc] init];
    });
    return singleOjbect;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self prepare];
    }
    return self;
}

//初始化数据
- (void)prepare {
    NSFileManager *fman = [NSFileManager defaultManager];
    NSString *draftPlistPath = kRDDraftListPath;
    if (![fman fileExistsAtPath:draftPlistPath]) {
        [fman createFileAtPath:draftPlistPath contents:nil attributes:nil];
        _draftPlistArray = [NSMutableArray array];
        _draftList = [NSMutableArray array];
    }else {
        _draftPlistArray = [NSMutableArray arrayWithContentsOfFile:draftPlistPath];
        if (!_draftPlistArray) {
            _draftPlistArray = [NSMutableArray array];
        }
        if (!_draftList) {
            _draftList = [NSMutableArray array];
        }
        WeakSelf(self);
        [_draftPlistArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *error = nil;
            RDDraftInfo *draft = [[RDDraftInfo alloc] initWithDictionary:obj error:&error];
            [draft.fileList enumerateObjectsUsingBlock:^(RDFile*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.contentURL = [RDHelpClass getFileURLFromAbsolutePath:obj.contentURL.absoluteString];
                if( obj.filtImagePatch )
                    obj.filtImagePatch = [RDHelpClass getFileURLFromAbsolutePath_str:obj.filtImagePatch];
                obj.reverseVideoURL = [RDHelpClass getFileURLFromAbsolutePath:obj.reverseVideoURL.path];
                obj.customTextPhotoFile.filePath = [RDHelpClass getFileURLFromAbsolutePath:obj.customTextPhotoFile.filePath].path;
                obj.customTextPhotoFile.fontPath = [RDHelpClass getFileURLFromAbsolutePath:obj.customTextPhotoFile.fontPath].path;
                if( obj.BackgroundFile )
                    obj.BackgroundFile.contentURL = [RDHelpClass getFileURLFromAbsolutePath:obj.BackgroundFile.contentURL.absoluteString];
                if (obj.customTextPhotoFile.fontPath.length > 0) {
                    [RDHelpClass customFontArrayWithPath:obj.customTextPhotoFile.fontPath];
                }
            }];
            if (error) {
                NSLog(@"加载草稿失败:%@", error);
            }else if (draft) {
                [weakSelf.draftList addObject:draft];
            }
        }];
    }
}

- (void)saveDraft:(RDDraftInfo *)draft completion:(void (^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        BOOL isExists = NO;
        if (draft.draftUUID && draft.draftUUID.length > 0) {
            isExists = YES;
        }else {
            draft.draftUUID = [RDHelpClass getVideoUUID];
        }
        
        draft.modifyTime = [NSDate date];
        
        NSDictionary *draftDic = [draft toDictionary];
        
        NSString *plistPath = kRDDraftListPath;
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        if(![fm fileExistsAtPath:kRDDraftDirectory]){
            [fm createDirectoryAtPath:kRDDraftDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (plistPath && ![fm fileExistsAtPath:plistPath]) {
            [fm createFileAtPath:plistPath contents:nil attributes:nil];
        }
        
        BOOL writeToFileResult;
        if (isExists) {
            if (self.draftPlistArray.count == 0) {
                [self.draftList addObject:draft];
                [self.draftPlistArray addObject:draftDic];
            }else if (self.draftPlistArray.count == 1) {
                [self.draftList replaceObjectAtIndex:0 withObject:draft];
                [self.draftPlistArray replaceObjectAtIndex:0 withObject:draftDic];
            }else {
                __block NSUInteger index = 0;
                [self.draftList enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.draftUUID isEqualToString:draft.draftUUID]) {
                        index = idx;
                        *stop = YES;
                    }
                }];
                [self.draftPlistArray replaceObjectAtIndex:index withObject:draftDic];
                [self.draftPlistArray exchangeObjectAtIndex:index withObjectAtIndex:0];
                [self.draftList replaceObjectAtIndex:index withObject:draft];
                [self.draftList exchangeObjectAtIndex:index withObjectAtIndex:0];
            }
        }else {
            [self.draftList insertObject:draft atIndex:0];
            if(!self.draftPlistArray){
                self.draftPlistArray = [[NSMutableArray alloc] initWithObjects:draftDic, nil];
            }else{
                [self.draftPlistArray insertObject:draftDic atIndex:0];
            }
        }
        writeToFileResult = [self.draftPlistArray writeToFile:plistPath atomically:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(writeToFileResult);
            }
        });
    });
}

#pragma mark- 获取草稿箱内所有视频信息

- (NSMutableArray *)getALLDraftVideosInfo {
#if 1
    return _draftList;
#else
    [_draftPlistArray removeAllObjects];
    [_draftList removeAllObjects];
    _draftPlistArray = [NSMutableArray arrayWithContentsOfFile:kRDDraftListPath];
    
     [_draftPlistArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSError *error = nil;
        RDDraftInfo *draft = [[RDDraftInfo alloc] initWithDictionary:obj error:&error];
        [draft.fileList enumerateObjectsUsingBlock:^(RDFile*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.contentURL = [RDHelpClass getFileURLFromAbsolutePath:obj.contentURL.absoluteString];
            if( obj.filtImagePatch )
                obj.filtImagePatch = [RDHelpClass getFileURLFromAbsolutePath_str:obj.filtImagePatch];
            obj.reverseVideoURL = [RDHelpClass getFileURLFromAbsolutePath:obj.reverseVideoURL.path];
            obj.customTextPhotoFile.filePath = [RDHelpClass getFileURLFromAbsolutePath:obj.customTextPhotoFile.filePath].path;
            obj.customTextPhotoFile.fontPath = [RDHelpClass getFileURLFromAbsolutePath:obj.customTextPhotoFile.fontPath].path;
            if( obj.BackgroundFile )
                obj.BackgroundFile.contentURL = [RDHelpClass getFileURLFromAbsolutePath:obj.BackgroundFile.contentURL.absoluteString];
            if (obj.customTextPhotoFile.fontPath.length > 0) {
                [RDHelpClass customFontArrayWithPath:obj.customTextPhotoFile.fontPath];
            }
        }];
        if (error) {
            NSLog(@"加载草稿失败:%@", error);
        }else if (draft) {
            [_draftList addObject:draft];
        }
    }];
    
    if (!_draftPlistArray) {
        _draftPlistArray = [NSMutableArray array];
    }
    
    return _draftList;
#endif
}

- (void)deleteDraftVideos:(RDDraftInfo *)draftVideoInfo completion:(void (^)(void))completion {
    if (draftVideoInfo) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self deleteDraft:draftVideoInfo isRefreshPlist:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        });
    }else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSMutableArray *tempArray = [_draftList mutableCopy];
            [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self deleteDraftVideos:obj completion:nil];
            }];
            [_draftList removeAllObjects];
            [_draftPlistArray removeAllObjects];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:kRDDraftDirectory error:&error];
            if (error) {
                NSLog(@"删除草稿箱plist失败：%@", error);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        });
    }
}

- (void)deleteDraft:(NSMutableArray<RDDraftInfo *> *)draftsInfo completion:(void (^)(void))completion {
    if (draftsInfo) {
        __block NSInteger count = draftsInfo.count;
        __weak typeof(self) weakSelf = self;
        [draftsInfo enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [weakSelf deleteDraft:obj isRefreshPlist:(count == (idx + 1))];
            if (idx + 1 == count) {
                if (completion) {
                    completion();
                }
            }
        }];
    }else {
        __block NSInteger count = _draftList.count;
        __weak typeof(self) weakSelf = self;
        NSMutableArray *tempArray = [_draftList mutableCopy];
        [tempArray enumerateObjectsUsingBlock:^(RDDraftInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [weakSelf deleteDraft:obj isRefreshPlist:(count == (idx + 1))];
            if (idx + 1 == count) {
                if (completion) {
                    completion();
                }
            }
        }];
    }
}

- (void)deleteDraft:(RDDraftInfo *)draft isRefreshPlist:(BOOL)isRefreshPlist {
    //清除文件
    for (RDFile *file in draft.fileList) {
        [file remove];
    }
    for (DubbingRangeViewFile *file in draft.dubbings) {
        [[NSFileManager defaultManager] removeItemAtPath:file.musicPath error:nil];
    }
    for (RDDraftEffectFilterItem *filterEffect in draft.filterArray) {
        if (filterEffect.currentFrameTexturePath.length > 0) {
            [[NSFileManager defaultManager] removeItemAtPath:filterEffect.currentFrameTexturePath error:nil];
        }
    }
    
    [draft.fileList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if( ((RDFile*)obj).filtImagePatch )
            [RDHelpClass deleteMaterialThumbnail:((RDFile*)obj).filtImagePatch];
        
    }];
    
    //BUG 特效 2019 12 6
//    for (RDCaptionRangeViewFile *filterEffect in draft.customFilterMusicFiles) {
//        if (filterEffect.currentFrameTexturePath.length > 0) {
//            [[NSFileManager defaultManager] removeItemAtPath:filterEffect.currentFrameTexturePath error:nil];
//        }
//    }
    
    //更新草稿箱列表
    NSUInteger index = [_draftList indexOfObject:draft];
    if (_draftList.count > 0 && index < _draftList.count) {
        [_draftList removeObjectAtIndex:index];
    }
    if (_draftPlistArray.count > 0 && index < _draftPlistArray.count) {
        [_draftPlistArray removeObjectAtIndex:index];
        if (isRefreshPlist) {
            if (_draftPlistArray.count > 0) {
                [_draftPlistArray writeToFile:kRDDraftListPath atomically:NO];
            }else {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:kRDDraftDirectory error:&error];
            }
        }
    }
}

- (BOOL)isEnableDraft:(RDDraftInfo *)draft {
    __block BOOL isEnable = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    [draft.fileList enumerateObjectsUsingBlock:^(RDFile*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURL *url = [RDHelpClass getFileURLFromAbsolutePath:obj.contentURL.absoluteString];
        if ([RDHelpClass isSystemPhotoUrl:url]) {
            if ([RDHelpClass isImageUrl:url]) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.synchronous = YES;
                options.resizeMode = PHImageRequestOptionsResizeModeFast;
                PHFetchResult *phAsset = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
                [[PHImageManager defaultManager] requestImageForAsset:[phAsset firstObject] targetSize:CGSizeMake(50, 50) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    if (!result) {
                        isEnable = NO;
                        *stop = YES;
                    }
                }];
                options = nil;
                phAsset = nil;
            }else {
                AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] == 0) {
                    isEnable = NO;
                    *stop = YES;
                }
                asset = nil;
            }
        }
        else if ([url.path containsString:@"RDVEUISDK.bundle"]) {
            NSRange range = [url.path rangeOfString:@"RDVEUISDK.bundle" options:NSCaseInsensitiveSearch];
            NSString *imagePath = [url.path substringFromIndex:(range.location + range.length + 1)];
            imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:imagePath Type:@""];
            if (!imagePath) {
                isEnable = NO;
                *stop = YES;
            }
        }
        else if (![fm fileExistsAtPath:url.path]) {
            isEnable = NO;
            *stop = YES;
        }
    }];
    
    return isEnable;
}

@end
