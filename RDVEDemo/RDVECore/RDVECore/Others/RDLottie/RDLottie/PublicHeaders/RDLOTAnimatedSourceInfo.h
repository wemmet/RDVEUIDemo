//
//  RDLOTAnimatedSourceInfo.h
//  RDLottie
//
//  Created by wuixaoxia on 2018/10/26.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDLOTAnimatedFrameInfo : NSObject

/** 前一个资源名称
 */
@property (nonatomic, copy) NSString *prevName;

/** 开始显示帧数
 */
@property (nonatomic, assign) int inFrame;

/** 结束显示帧数
 */
@property (nonatomic, assign) int outFrame;

@end

@interface RDLOTAnimatedSourceInfo : NSObject

/** 名称
 */
@property (nonatomic, copy) NSString *name;

/** 类型名称
 */
@property (nonatomic, copy) NSString *typeName;

/** 资源所在文件夹名称
 */
@property (nonatomic, copy) NSString *directoryName;

/** 宽度
 */
@property (nonatomic, assign) float width;

/** 高度
 */
@property (nonatomic, assign) float height;

/** 开始显示帧数
 */
@property (nonatomic, assign) int inFrame;

/** 结束显示帧数
 */
@property (nonatomic, assign) int outFrame;

/** 显示总帧数
 */
@property (nonatomic, assign) int totalFrame;

/** 多次显示帧信息(除第一次外)
 */
@property (nonatomic, strong) NSMutableArray <RDLOTAnimatedFrameInfo*>*frameArray;

/** 除第一次外,第几次显示
 *  用于求重复显示的资源的显示时长
 */
@property (nonatomic, assign) float index;

@end

NS_ASSUME_NONNULL_END
