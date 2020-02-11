//
//  SubtitleEffectScrollView.h
//  RDVEUISDK
//
//  Created by emmet on 2017/7/4.
//  Copyright © 2017年 com.rd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterTextView.h"

@class SubtitleEffectScrollView;

@protocol SubtitleEffectScrollViewDelegate <NSObject>

@optional
/**type: 1: 字幕  2:特效 3:字体
 */
- (void)downloadFile:(NSString *)fileUrl cachePath:(NSString *)cachePath fileName:(NSString *)fileName timeunix:(NSString *)timeunix type:(NSInteger)type sender:(UIView *)sender progress:(void(^)(float progress))progressBlock finishBlock:(void(^)())finishBlock failBlock:(void(^)(void))failBlock;
/**type: 1: 字幕  2:特效
 */
- (void)changeSubtitleEffect:(NSString*)configPath type:(NSInteger)type index:(NSInteger)index;
/**改变内容字体颜色
 */
- (void)changeSubtitleEffectContentTextColor:(UIColor *)textColor shadowColor:(UIColor *)shadowColor;
/**改变内容
 */
- (void)changeSubtitleEffectContentText:(NSString *)text;
/**改变大小
 */
- (void)changePointSizeScale:(float)value;
/**设置字体
 */
- (void)setFontWithName:(NSString *)fontName fontCode:(NSString *)fontCode isSystem:(BOOL)isSystem;
/**改变动画
 */
- (void)changeSubtitleAnimateType:(NSInteger)typeIndex;
/**隐藏编辑控件
 */
- (void)saveSubtitleEffect:(NSInteger)index;
/** 贴纸删除 退出时需要的操作 **/
- (void)changeCloseScrollView:(SubtitleEffectScrollView *)subtitleScrollView;
@end

@interface SubtitleEffectScrollView : UIView

@property(nonatomic,assign)BOOL isEditSubtitleEffect;
@property(nonatomic,assign)CGSize contentSize;
@property(nonatomic,assign)CGPoint contentOffset;
@property(nonatomic,assign)BOOL isAnimateFade;
@property(nonatomic,assign)NSInteger selectedAnimateIndex;
@property (nonatomic,strong) RDPasterTextView *pasterTextView;
@property(nonatomic,weak)id<SubtitleEffectScrollViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame withType:(NSInteger)type;
- (void)touchescaptionTypeViewChild:(UIButton *)sender;
- (void)touchescaptionTypeViewChildWithIndex:(NSInteger)index;
- (void)setContentTextFieldText:(NSString *)contentText;

- (void)touchesColorViewChildWithColor:(UIColor *)color;
-(void)setPointSizeScrollView_contentOffset:(float) scale;

- (NSString *)contentTextFieldText;
- (NSMutableArray <NSDictionary *>*)typeList;
- (void)clear;

-(void)save;
@end
