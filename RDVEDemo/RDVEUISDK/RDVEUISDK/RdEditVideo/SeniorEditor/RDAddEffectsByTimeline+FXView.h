//
//  RDAddEffectsByTimeline+FXView.h
//  RDVEUISDK
//
//  Created by apple on 2019/11/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//
#import "RDAddEffectsByTimeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDAddEffectsByTimeline (FXView)<UIScrollViewDelegate>

//初始化
- (void)initFXView;

//添加
- (void)addEffectAction_FX;
//取消
- (void)cancelEffectAction_FX;
//完成
- (void)finishEffectAction_FX;
//删除
- (void)deleteEffectAction_FX;
//保存
- (void)editAddedEffect_FX;

@end

NS_ASSUME_NONNULL_END
