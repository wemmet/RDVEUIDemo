//
//  SubtitleScrollView.h
//  RDVEUISDK
//
//  Created by emmet on 2017/11/20.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptionRangeView.h"
#import "RDPasterTextView.h"
@class SubtitleScrollView;

typedef NS_ENUM(NSInteger, DownFileType) {
    DownFileCapption = 0,
    DownFileFont,
    
};

@protocol SubtitleScrollViewDelegate <NSObject>

/**选择字幕样式*/
- (void)changeType:(NSString *)configPath index:(NSInteger)index subtitleScrollView:(SubtitleScrollView *)subtitleScrollView Name:(NSString *) name coverPath:(NSString *)coverPath;

- (void)changeAlpha:(float)alpha subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

- (void)changeSubtitleColor:(UIColor *)color alpha:(float)alpha contentType:(RDSubtitleContentType)contentType subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**选择字幕颜色*/
- (void)changeColor:(UIColor *)color alpha:(float)alpha subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**选择字幕描边*/
- (void)changeBorder:(UIColor *)borderColor alpha:(float)alpha borderWidth:(float)borderWidth subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**选择字幕字体*/
- (void)setFontWithName:(NSString *)fontName fontCode:(NSString *)fontCode fontPath:(NSString *)fontPath subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**选择字幕大小*/
- (void)changeSize:(float)value subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**选择字幕位置*/
- (void)changePosition:(RDSubtitleAlignment )postion subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;
- (void)changeMoveSlightlyPosition:(RDMoveSlightlyDirection)direction subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**改变字幕内容*/
- (void)changeSubtitleContentString:(NSString *)contentString subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**改变字幕内容是否加粗，是否斜体，是否有阴影*/
- (void) changeWithIsBold:(BOOL)isBold isItalic:(BOOL )isItalic isShadow:(BOOL)isShadow subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**预览动画*/
- (void)previewAnimation:(CaptionAnimateType)inType outType:(CaptionAnimateType)outType subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**是否应用到所有字幕*/
- (void)useToAllWithSubtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**保存字幕信息*/
- (void)saveSubtitleConfig:(NSInteger)index subtitleScrollView:(SubtitleScrollView *)subtitleScrollView;

/**下载字幕和字体*/
- (void)downloadFile:(NSString *)fileUrl cachePath:(NSString *)cachePath fileName:(NSString *)fileName timeunix:(NSString *)timeunix fileType:(DownFileType)type sender:(UIView *)sender subtitleScrollView:(SubtitleScrollView *)subtitleScrollView progress:(void(^)(float progress))progressBlock finishBlock:(void(^)())finishBlock failBlock:(void(^)(void))failBlock;

/** 字幕删除 退出时需要的操作 **/
- (void)changeClose:(SubtitleScrollView *)subtitleScrollView;

@end

@interface SubtitleScrollView : UIView
@property (nonatomic,copy  ) NSString     *fontResourceURL;
@property (nonatomic,strong) UIView *topView;
@property (nonatomic,strong) UIScrollView *toolBarView;
@property (nonatomic,strong) UIScrollView *bottomView;
//@property (nonatomic,strong) UITextField  *contentTextField;
@property (nonatomic,strong) UIView       *contentTextView;
@property(nonatomic,strong)  UITextView   *textView;              //输入框
@property (nonatomic,strong) UIButton     *okBtn;
@property (nonatomic,assign) BOOL          isFieldChanged;
@property (nonatomic,assign) BOOL          isEditting;
@property (nonatomic,assign) BOOL          isBold;
@property (nonatomic,assign) BOOL          isItalic;
@property (nonatomic,assign) BOOL          isShadow;
@property (nonatomic,assign) float         subtitleAlpha;
@property (nonatomic,assign) float         textAlpha;
@property (nonatomic,assign) float         strokeAlpha;
@property (nonatomic,assign) float         strokeWidth;
@property (nonatomic,assign) float         shadowWidth;
@property (nonatomic,assign) float         subtitleSize;
@property (nonatomic,assign) int           selectedTypeId;
@property (nonatomic,assign) NSInteger     selectColorItemIndex;
@property (nonatomic,assign) NSInteger     selectBorderColorItemIndex;
@property (nonatomic,assign) NSInteger     selectShadowColorIndex;
@property (nonatomic,assign) NSInteger     selectBgColorIndex;
@property (nonatomic,assign) CaptionAnimateType inAnimationIndex;
@property (nonatomic,assign) CaptionAnimateType outAnimationIndex;
@property (nonatomic,assign) NSInteger     selectFontItemIndex;
@property (nonatomic,strong) RDPasterTextView *pasterTextView;
@property (nonatomic,strong) CaptionRangeView *captionRangeView;
@property (nonatomic,assign)id<SubtitleScrollViewDelegate> delegate;
@property (nonatomic,assign,readonly)BOOL      useTypeToAll;
@property (nonatomic,assign,readonly)BOOL      useAnimationToAll;
@property (nonatomic,assign,readonly)BOOL      useColorToAll;
@property (nonatomic,assign,readonly)BOOL      useBorderToAll;
@property (nonatomic,assign,readonly)BOOL      useFontToAll;
@property (nonatomic,assign,readonly)BOOL      useSizeToAll;
@property (nonatomic,assign,readonly)BOOL      usePositionToAll;
@property (nonatomic,assign,readonly)BOOL      isModifyText;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)showInView;

- (void)clickToolItem:(UIButton *)sender;

- (void)clickSubtitleFontItem:(UIButton *)sender;

- (void)touchescaptionTypeViewChildWithIndex:(NSInteger)index;

- (void)clear;

- (void)setContentTextFieldText:(NSString *)contentText;

- (NSString *)contentTextFieldText;

- (void)setSubtitleSize:(float)value;

- (void)setIsVerticalText:(BOOL)isVerticalText;

- (NSMutableArray <NSDictionary *>*)typeList;

//保存文字编辑框 文字
-(void) saveTextFieldTxt;
- (void)setProgressSize:(float)value;

- (void)save;

-(void)setStrokeColor:( UIColor * ) strokeColor atWidth:( int ) width atAlpha:( float ) alpha;
@end


