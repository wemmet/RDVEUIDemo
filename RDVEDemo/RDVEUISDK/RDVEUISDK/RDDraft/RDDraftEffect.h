//
//  RDDraftEffect.h
//  RDVEUISDK
//
//  Created by apple on 2018/12/27.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDDraftDataModel.h"

@interface RDDraftEffectFilterItem : RDDraftDataModel

/**自定义滤镜特效 持续时间
 */
@property(assign,nonatomic)CMTimeRange  effectiveTimeRange;

/**自定义滤镜特效
 */
@property(assign,nonatomic)int  filterIndex;
@property(assign,nonatomic)int  customFilterId;

/**当前帧图片地址
 */
@property(strong,nonatomic)NSString *currentFrameTexturePath;

@end

@protocol RDDraftEffectFilterItem <NSObject>

@end



@interface RDDraftEffectTime : RDDraftDataModel

/**时间特效 持续时间
 */
@property(assign,nonatomic)CMTimeRange  effectiveTimeRange;

/**时间特效 类型
 */
@property(assign,nonatomic)int  timeType;

@end

@protocol RDDraftEffectTime <NSObject>

@end
