//
//  RDTextFontEditor.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/16.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDZSlider.h"
#import "RDZipArchive.h"
#import "RDVECore.h"
#import "UITextTypesetViewCell.h"

@protocol RDTextFontEditorDelegate<NSObject>

@optional

-(void)textOut:(BOOL) isRotate;
-(void)seekToTime:(CGFloat)current;

-(void)play:(bool) isPlay;
@end

@interface RDTextFontEditor : UIView
@property (nonatomic,assign) NSInteger     selectFontItemIndex;
@property (nonatomic,copy  ) NSString     *fontResourceURL;
@property(nonatomic,strong)UIView                   *textTimeView;      //时间进度 和 确认界面

@property(nonatomic,strong)UIButton                 *textCancelSelectBtn;
@property(nonatomic,strong)UIButton                 *textSelectCallBtn;

@property(nonatomic,strong)UIButton                 *textBackBtn;
@property(nonatomic,strong)UIButton                 *textCarryOutBtn;

@property(nonatomic,strong)UIButton                 *textPlayBtn;
@property(nonatomic,strong)RDZSlider                *textVideoProgress;
@property(nonatomic,strong)UILabel                  *textTimeLabel;

@property(nonatomic,strong)UIView                   *textTypesetView;
@property(nonatomic,strong)UIScrollView             *textTypesetScrollView;
@property(nonatomic,assign)BOOL                     isRenewRotate;
@property(nonatomic,assign)bool                     isDeleteRow;
@property(nonatomic,strong)NSMutableArray<RDTextObject *> *textObjectViewArray;                //数组
@property(nonatomic,strong)NSMutableArray<UITextTypesetViewCell *> *textTypesetViewArray;      //数组

@property(nonatomic,strong)UIView                   *fontEditView;
@property(nonatomic,strong)NSMutableArray<UIButton *> *mutabArray;
//文字描边
@property(nonatomic,strong)UIView                   *strokeView;
@property(nonatomic,strong)RDZSlider                *strokeSlider;
//文字阴影
@property(nonatomic,strong)UIView                   *shadowView;
@property(nonatomic,strong)RDZSlider                *shadowSlider;
//颜色
@property(nonatomic,strong)UIScrollView                 *textColorScrollView;
@property(nonatomic,strong)NSMutableArray<UIButton *>   *textColorBtnArray;
@property(nonatomic,strong)NSMutableArray<UIColor *>    *textColorArray;
//字体
@property(nonatomic,strong)UIScrollView                 *textFontScrollView;
@property(nonatomic,strong)NSMutableArray<UIButton *>   *textFontBtnArray;

@property (nonatomic, assign)int                        currentTextEditTag;

@property (nonatomic, assign)NSString                  *currentfontName;
@property (nonatomic, assign)UIColor                   *currentfontColor;

@property (nonatomic,assign)float                       currentShadow;
@property (nonatomic,assign)UIColor                    *currentShadowColor;

@property (nonatomic, assign)float                     currentfontStroke;
@property (nonatomic, assign)UIColor                   *currentfontStrokeColor;

//字体
@property(nonatomic,strong)NSArray                 *fonts;
@property(nonatomic,strong)NSDictionary            *fontIconList;

@property(nonatomic,strong)RDVECore                * rdPlayer;

@property (nonatomic,weak) id<RDTextFontEditorDelegate> delegate;

@property(nonatomic,strong)UIView                   *editTxtView;
-(void)CreateEditTxtView;

- (NSString *)IntTimeToStringFormat:(float)time;
-(void)initScrollView;
@end

