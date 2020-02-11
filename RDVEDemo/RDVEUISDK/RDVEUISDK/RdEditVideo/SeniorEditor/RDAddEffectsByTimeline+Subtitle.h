//
//  RDAddEffectsByTimeline+Subtitle.h
//  RDVEUISDK
//
//  Created by apple on 2019/5/6.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline.h"

@interface RDAddEffectsByTimeline (Subtitle)<SubtitleScrollViewDelegate>

- (void)initSubtitleConfigEditView:(BOOL)showInView;
- (void)getSpeechRecogCallBackWithDic:(NSDictionary *)dic;


/**添加字幕
 */
- (void)addSubtitle;
//保存字幕
- (void)saveSubtitle:(BOOL)isFinish;
- (void)saveSubtitleTimeRange;
//编辑字幕
- (void)editSubtitle;
//初始化字幕
- (void)checkSubtitleEditBefor:(NSInteger)typeIndex;
- (void)startSpeechRecog;//开始语音识别

@end
