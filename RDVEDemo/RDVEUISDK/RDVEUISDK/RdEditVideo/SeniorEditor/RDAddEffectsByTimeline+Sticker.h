//
//  RDAddEffectsByTimeline+Sticker.h
//  RDVEUISDK
//
//  Created by apple on 2019/5/7.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDAddEffectsByTimeline (Sticker)<SubtitleEffectScrollViewDelegate>

- (void)initStickerEditView;
/**添加贴纸
 */
- (void)addSticker;
/**完成贴纸
 */
- (void)saveStickerTouchUp;
/**编辑贴纸
 */
- (void)editSticker;

- (void)checkEffectEditBefor:(NSInteger)typeIndex;

@end

NS_ASSUME_NONNULL_END
