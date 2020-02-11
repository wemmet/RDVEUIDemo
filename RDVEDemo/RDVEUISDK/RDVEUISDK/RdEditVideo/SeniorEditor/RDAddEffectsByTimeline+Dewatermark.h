//
//  RDAddEffectsByTimeline+Dewatermark.h
//  RDVEUISDK
//
//  Created by apple on 2019/5/8.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline.h"

@interface RDAddEffectsByTimeline (Dewatermark)<CropDelegate>

/** 添加去水印
 */
- (void)addDewatermark;
/** 完成添加去水印
 */
- (void)addDewatermarkFinishAction:(UIButton *)sender;

//去水印 编辑
- (void)editDewatermark;

- (void)initDewatermarkTypeView;

//点击发布按钮 添加
- (void)startAddDewatermark;

- (void)preAddDewatermark:(CMTimeRange)timeRange
                    blurs:(NSMutableArray *)blurs
                  mosaics:(NSMutableArray *)mosaics
             dewatermarks:(NSMutableArray *)dewatermarks;

@end
