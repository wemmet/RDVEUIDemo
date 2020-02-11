//
//  RDDraftManager.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/11/7.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDDraftInfo.h"

@interface RDDraftManager : NSObject

@property (nonatomic, strong) NSMutableArray <RDDraftInfo *> *draftList;
@property (nonatomic, strong) NSMutableArray *draftPlistArray;

+ (instancetype)sharedManager;

/** 保存草稿
 */
- (void)saveDraft:(RDDraftInfo *)draft completion:(void (^)(BOOL success))completion;

/**获取草稿箱内所有视频信息
 */
- (NSMutableArray *)getALLDraftVideosInfo;



/**
 *  删除草稿箱内视频
 *
 *  @param draftVideoInfo   要删除的草稿视频信息。如果为空，代表删除所有草稿视频。
 */
//- (void)deleteDraftVideos:(RDDraftInfo *)draftVideoInfo completion:(void (^)(void))completion;
- (void)deleteDraft:(NSMutableArray <RDDraftInfo *>*)draftsInfo completion:(void (^)(void))completion;

/**
 *  检测草稿箱内视频是否被删除
 *
 *  @param draft   要检测的草稿视频信息
 */
- (BOOL)isEnableDraft:(RDDraftInfo *)draft;

@end
