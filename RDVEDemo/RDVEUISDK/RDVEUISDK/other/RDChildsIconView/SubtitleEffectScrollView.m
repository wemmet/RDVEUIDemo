//
//  SubtitleEffectScrollView.m
//  RDVEUISDK
//
//  Created by emmet on 2017/7/4.
//  Copyright © 2017年 com.rd. All rights reserved.
//
#define kcaptionBUTTOMSCROLLVIEWTAG 2000
#define kCAPTIONTYPEVIEWCHILDTAG 3000
#define kCaptionFONTCOLORCHILDTAG 4000
#define kcaptionFONTMIAOBIANBTNTAG 5000
#define kKXFXCLASSIFICATIONBTNTAG 6000
#define kKXFXSCROLLVIEWCHILDSBTNTAG 7000
#define kKXFXSCENESCROLLVIEWCHILDSDETAILBTNTAG 700
#define kCAPTIONTYPECHILDTAG 8000
#define KTYPECOUNT 17
#define kPasterViewControlSize 28.0
#define KFONTCOLORCOUNT 24
#define KCELLFONTCOLORCOUNT 6
#define KCOLORBTNWIDTH 28
#define kFontTitleImageViewTag   10000

#import "RDHelpClass.h"
#import "SubtitleEffectScrollView.h"
#import "UIButton+RDWebCache.h"
#import "RDYYWebImage.h"

@interface SubtitleEffectScrollView()<UITextFieldDelegate,UIScrollViewDelegate>{
    UIView          *selectFontColorView;
    NSDictionary    *fontIconList;
    NSArray<NSDictionary *> *modleTypes;
    NSArray         *fonts;
    NSArray         *colors;
    NSInteger       selectTypeIndex;
    UIFont          *selectFont;
    UIColor         *selectColor;
    NSInteger       selectpointSize;
    float           sizeScale;
    BOOL            isDowning;
    
    NSArray         *stickerListTypes;
    NSMutableArray  *stickersListArray;
    NSMutableArray  *stickersIndexArray;
    int             currentSelectLabelIndex;
    NSMutableArray<NSNumber *>  *stickersListIndexArray;
    NSMutableArray<UIScrollView *>  *stickersScrollArray;
    
    
    NSMutableArray<UIButton *>  *stickersLabelBtnArray;
    NSMutableArray<UIImageView *> * stickersImageViewArray;
    BOOL            isNewSticker;
    
    
    NSMutableArray<UIImageView *> *uncheckedBtnArray;
    NSMutableArray<UIImageView *> *checkedBtnArray;
}
/**1:特效 0:字幕
 */
@property(nonatomic,assign) NSInteger type;
@property(nonatomic,strong) UIView *topView;
@property(nonatomic,strong) UIView *middleView;

@property(nonatomic,strong) UITextField *contentTextField;
@property(nonatomic,strong) UIButton    *okBtn;

@property(nonatomic,strong) UIButton    *typeIconsBtn;
@property(nonatomic,strong) UIButton    *fontsBtn;
@property(nonatomic,strong) UIButton    *colorsBtn;
@property(nonatomic,strong) UIButton    *pointSizeBtn;
@property(nonatomic,strong) UIButton    *animateBtn;
@property(nonatomic,strong) UIView      *selectView;

@property(nonatomic,strong) UIScrollView      *bottomView;
@property(nonatomic,strong) UIScrollView      *typeIconsScrollView;
@property(nonatomic,strong) UIImageView       *selectTypeView;
@property(nonatomic,strong) UIScrollView      *fontsScrollView;
@property(nonatomic,strong) UIScrollView      *colorsScrollView;
@property(nonatomic,strong) UIView            *pointSizeView;
@property(nonatomic,strong) UIScrollView      *pointSizeScrollView;
@property(nonatomic,strong) UILabel           *pointSizelabel;
@property(nonatomic,strong) UIScrollView      *animateScrollView;
@property(nonatomic,strong) UIButton          *fadeAnimateBtn;

@property (nonatomic,strong) UIScrollView *toolBarView;

//新贴纸界面
@property(nonatomic,strong) UIView              *stickerView;
@property(nonatomic,strong) UIScrollView        *stickerLabelScrollView;
@property(nonatomic,strong) UIScrollView        *stickerListScrollView;
@end
@implementation SubtitleEffectScrollView

- (void)TextClose
{
    if([_delegate respondsToSelector:@selector(changeCloseScrollView:)]){
        [_delegate changeCloseScrollView:self];
    }
    
    self.hidden = YES;
    _isAnimateFade = NO;
    [_contentTextField resignFirstResponder];
}

- (UIScrollView *)toolBarView{
    if(!_toolBarView){
        _toolBarView = [UIScrollView new];
        _toolBarView.frame = CGRectMake(0, self.frame.size.height - (kToolbarHeight - (LastIphone5?0:14)), self.frame.size.width, (kToolbarHeight - (LastIphone5?0:14)));
        _toolBarView.backgroundColor = TOOLBAR_COLOR;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        _toolBarView.showsVerticalScrollIndicator = NO;
        float height = LastIphone5 ? 44 : (kToolbarHeight - 14);
        
        if( !isNewSticker )
            [_toolBarView addSubview:self.middleView];
        else
        {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((LastIphone5?0:7) + height, 0, _toolBarView.frame.size.width - height*2.0 - (LastIphone5?0:7), height)];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:17];
            label.textColor = [UIColor  colorWithWhite:1.0 alpha:0.5];
            label.text = RDLocalizedString(@"贴纸", nil);
            [_toolBarView addSubview:label];
        }
        
        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake((LastIphone5?0:7), 0, height, height)];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(TextClose) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:cancelBtn];
        
        UIButton *finishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - height - (LastIphone5?0:7), 0, height, height)];
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:finishBtn];
        
        UIScrollView *toolItemsView = [UIScrollView new];
        toolItemsView.frame = CGRectMake( 44 ,0, _toolBarView.frame.size.width - 44*2.0, height);
        toolItemsView.backgroundColor = [UIColor clearColor];
        toolItemsView.showsHorizontalScrollIndicator = NO;
        toolItemsView.showsVerticalScrollIndicator = NO;
        toolItemsView.contentSize = CGSizeMake(toolItemsView.frame.size.width, 0); 
    }
    return _toolBarView;
}

- (instancetype)initWithFrame:(CGRect)frame withType:(NSInteger)type{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _type = type;
        isNewSticker = false;
        if(_type == 0){
            [self addSubview:self.topView];
        }
        if(_type == 1){
        
            [self addSubview:self.bottomView];
            [self addSubview:self.toolBarView];
        }
        else
        {
            [self addSubview:self.middleView];
            [self addSubview:self.bottomView];
        }
    }
    return self;
}

- (CGSize)contentSize{
    return self.pointSizeScrollView.contentSize;
}

- (void)setContentSize:(CGSize)contentSize{
    self.pointSizeScrollView.contentSize = contentSize;
}

- (CGPoint)contentOffset{
    return self.pointSizeScrollView.contentOffset;
}

- (void)setContentOffset:(CGPoint)contentOffset{
    self.pointSizeScrollView.contentOffset = contentOffset;
}

- (void)setContentTextFieldText:(NSString *)contentText{
    if(_type != 1){
        if(contentText.length == 0 || [contentText isEqualToString:RDLocalizedString(@"点击输入字幕", nil)]){
            contentText = @"";
        }
    }
    
    self.contentTextField.text = contentText;
    
}
- (NSString *)contentTextFieldText{
    if(_type != 1){
        if(self.contentTextField.text.length == 0){
            return RDLocalizedString(@"点击输入字幕", nil);
        }
    }
    return self.contentTextField.text;
}

- (void)setIsEditSubtitleEffect:(BOOL)isEditSubtitleEffect{
    _isEditSubtitleEffect = isEditSubtitleEffect;
    
    if(_isEditSubtitleEffect){
        [self.okBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateNormal];
        [self.okBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateHighlighted];
    }else{
        [self.okBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
        [self.okBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateHighlighted];
    }
}

- (void)setIsAnimateFade:(BOOL)isAnimateFade {
    _fadeAnimateBtn.selected = isAnimateFade;
    _isAnimateFade = NO;//isAnimateFade;
}

- (void)setSelectedAnimateIndex:(NSInteger)selectedAnimateIndex {
    UIButton *prevBtn = [_animateScrollView viewWithTag:(_selectedAnimateIndex + 1)];
    prevBtn.selected = NO;
    
    _selectedAnimateIndex = selectedAnimateIndex;
    UIButton *selectedBtn = [_animateScrollView viewWithTag:(_selectedAnimateIndex + 1)];
    selectedBtn.selected = YES;    
}

- (UIView *)selectView{
    if(!_selectView){
        _selectView = [UIView new];
        _selectView.frame = CGRectMake(0, self.middleView.frame.size.height - 2, 44, 2);
        if( _type != 1 )
            _selectView.backgroundColor = Main_Color;
        else
            _selectView.backgroundColor = TOOLBAR_COLOR;
        _selectView.hidden = YES;
    }
    return _selectView;
}

- (UIView *)topView{
    if(!_topView){
        _topView = [UIView new];
        _topView.frame = CGRectMake(0, 0, self.frame.size.width, 48);
        _topView.backgroundColor = UIColorFromRGB(NV_Color);
        [_topView addSubview:self.contentTextField];
        [_topView addSubview:self.okBtn];
    
    }
    return _topView;
}

- (UITextField *)contentTextField{
    if(!_contentTextField){
        _contentTextField = [UITextField new];
        _contentTextField.frame = CGRectMake(6, (48 - 36)/2.0, self.frame.size.width - 6 - 13*2 - 54, 36);
        
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        clearButton.backgroundColor = [UIColor clearColor];
        [clearButton setImage:[RDHelpClass imageWithContentOfFile:@"/next_jianji/剪辑-字幕删除输入内容默认_"] forState:UIControlStateNormal];
        [clearButton setImage:[RDHelpClass imageWithContentOfFile:@"/next_jianji/剪辑-字幕删除输入内容点击_"] forState:UIControlStateHighlighted];
        [clearButton setFrame:CGRectMake(0, 0, 26, 26)];
        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
        _contentTextField.rightViewMode = UITextFieldViewModeAlways;
        [_contentTextField setRightView:clearButton];
        
        _contentTextField.layer.borderColor    = [UIColor clearColor].CGColor;
        _contentTextField.layer.borderWidth    = 1;
        _contentTextField.layer.cornerRadius   = 3;
        _contentTextField.layer.masksToBounds  = YES;
        _contentTextField.textColor            = UIColorFromRGB(0xffffff);
        _contentTextField.backgroundColor      = UIColorFromRGB(0x3c3b43);
        _contentTextField.returnKeyType        = UIReturnKeyDone;
        _contentTextField.delegate             = self;
        NSMutableAttributedString* attrstr = [[NSMutableAttributedString alloc] initWithString:RDLocalizedString(@"点击输入字幕", nil)];
        [attrstr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x888888) range:NSMakeRange(0, attrstr.length)];
        _contentTextField.attributedPlaceholder = attrstr;
        
        
    }
    return _contentTextField;
}

- (UIButton *)okBtn{
    if(!_okBtn){
        _okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _okBtn.frame = CGRectMake(self.frame.size.width - 54 - 13 , (self.topView.frame.size.height - 28)/2.0, 54, 28);
        [_okBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
        _okBtn.layer.cornerRadius = 28/2;
        _okBtn.layer.masksToBounds = YES;
        _okBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _okBtn.backgroundColor = Main_Color;
        [_okBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateNormal];
        [_okBtn setTitle:RDLocalizedString(@"添加", nil) forState:UIControlStateHighlighted];
        [_okBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
        [_okBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateHighlighted];
    }
    return _okBtn;
}

- (UIView *)middleView{
    if(!_middleView){
        _middleView = [UIView new];
        _middleView.frame = CGRectMake(0, _type==1 ? 0 : self.topView.frame.size.height, self.frame.size.width, _type==1 ? 44 : 35);
        _middleView.backgroundColor = TOOLBAR_COLOR;
        if(_type == 1){
            _middleView.frame = CGRectMake(44, 0, self.frame.size.width - 44*2.0, (LastIphone5?44:30));
            //[_middleView addSubview:self.okBtn];
            [_middleView addSubview:self.typeIconsBtn];
            [_middleView addSubview:self.pointSizeBtn];
//            UIView *span1 = [[UIView alloc] initWithFrame:CGRectMake(self.typeIconsBtn.frame.size.width + self.typeIconsBtn.frame.origin.x - 0.25, self.typeIconsBtn.frame.origin.y + self.typeIconsBtn.frame.size.height/2.0 - 10, 0.5, 20)];
//            span1.backgroundColor = UIColorFromRGB(0x61616e);
//            [_middleView addSubview:span1];
            
        }else{
            
            [_middleView addSubview:self.typeIconsBtn];
            [_middleView addSubview:self.fontsBtn];
            [_middleView addSubview:self.colorsBtn];
            [_middleView addSubview:self.pointSizeBtn];
            [_middleView addSubview:self.animateBtn];
            
            UIView *span1 = [[UIView alloc] initWithFrame:CGRectMake(self.typeIconsBtn.frame.size.width + self.typeIconsBtn.frame.origin.x - 0.25, self.typeIconsBtn.frame.origin.y + self.typeIconsBtn.frame.size.height/2.0 - 10, 0.5, 20)];
            span1.backgroundColor = UIColorFromRGB(0x61616e);
            UIView *span2 = [[UIView alloc] initWithFrame:CGRectMake(self.fontsBtn.frame.size.width + self.fontsBtn.frame.origin.x - 0.25, self.fontsBtn.frame.origin.y + self.fontsBtn.frame.size.height/2.0 - 10, 0.5, 20)];
            span2.backgroundColor = UIColorFromRGB(0x61616e);
            UIView *span3 = [[UIView alloc] initWithFrame:CGRectMake(self.colorsBtn.frame.size.width + self.colorsBtn.frame.origin.x - 0.25, self.colorsBtn.frame.origin.y + self.colorsBtn.frame.size.height/2.0 - 10, 0.5, 20)];
            span3.backgroundColor = UIColorFromRGB(0x61616e);
            UIView *span4 = [[UIView alloc] initWithFrame:CGRectMake(self.pointSizeBtn.frame.size.width + self.pointSizeBtn.frame.origin.x - 0.25, self.pointSizeBtn.frame.origin.y + self.pointSizeBtn.frame.size.height/2.0 - 10, 0.5, 20)];
            span4.backgroundColor = UIColorFromRGB(0x61616e);
            
            [_middleView addSubview:span1];
            [_middleView addSubview:span2];
            [_middleView addSubview:span3];
            [_middleView addSubview:span4];
            
        }
        
    }
    return _middleView;
}

- (UIButton *)typeIconsBtn{
    if(!_typeIconsBtn){
        _typeIconsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if(_type == 1){
            _typeIconsBtn.frame = CGRectMake(self.middleView.frame.size.width/6.0 ,(self.middleView.frame.size.height - 30)/2.0, self.middleView.frame.size.width/3.0, 30);
        }
        else
            _typeIconsBtn.frame = CGRectMake(21 ,(self.middleView.frame.size.height - 30)/2.0, 65, 30);
        [_typeIconsBtn addTarget:self action:@selector(tapTypeIconsBtn) forControlEvents:UIControlEventTouchUpInside];
        _typeIconsBtn.layer.cornerRadius = 15.0;
        _typeIconsBtn.layer.masksToBounds = YES;
        _typeIconsBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _typeIconsBtn.backgroundColor = [UIColor clearColor];
        [_typeIconsBtn setTitle:RDLocalizedString(@"样式", nil) forState:UIControlStateNormal];
        [_typeIconsBtn setTitle:RDLocalizedString(@"样式", nil) forState:UIControlStateHighlighted];
        [_typeIconsBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_typeIconsBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
        [_typeIconsBtn setTitle:RDLocalizedString(@"样式", nil) forState:UIControlStateSelected];
        [_typeIconsBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        if( _type == 1 )
            _typeIconsBtn.backgroundColor = TOOLBAR_COLOR;
    }
    return _typeIconsBtn;
}

- (UIButton *)fontsBtn{
    if(!_fontsBtn){
        _fontsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fontsBtn.frame = CGRectMake(self.typeIconsBtn.frame.origin.x + self.typeIconsBtn.frame.size.width ,(self.middleView.frame.size.height - 30)/2.0, 65, 30);
        [_fontsBtn addTarget:self action:@selector(tapFontsBtn) forControlEvents:UIControlEventTouchUpInside];
        _fontsBtn.layer.cornerRadius = 15.0;
        _fontsBtn.layer.masksToBounds = YES;
        _fontsBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _fontsBtn.backgroundColor = [UIColor clearColor];
        [_fontsBtn setTitle:RDLocalizedString(@"字体", nil) forState:UIControlStateNormal];
        [_fontsBtn setTitle:RDLocalizedString(@"字体", nil) forState:UIControlStateHighlighted];
        [_fontsBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_fontsBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
        [_fontsBtn setTitle:RDLocalizedString(@"字体", nil) forState:UIControlStateSelected];
        [_fontsBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    }
    return _fontsBtn;
}

- (UIButton *)colorsBtn{
    if(!_colorsBtn){
        _colorsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _colorsBtn.frame = CGRectMake(self.fontsBtn.frame.origin.x + self.fontsBtn.frame.size.width ,(self.middleView.frame.size.height - 30)/2.0, 65, 30);
        [_colorsBtn addTarget:self action:@selector(tapColorsBtn) forControlEvents:UIControlEventTouchUpInside];
        _colorsBtn.layer.cornerRadius = 15.0;
        _colorsBtn.layer.masksToBounds = YES;
        _colorsBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _colorsBtn.backgroundColor = [UIColor clearColor];
        [_colorsBtn setTitle:RDLocalizedString(@"颜色", nil) forState:UIControlStateNormal];
        [_colorsBtn setTitle:RDLocalizedString(@"颜色", nil) forState:UIControlStateHighlighted];
        [_colorsBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_colorsBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
        [_colorsBtn setTitle:RDLocalizedString(@"颜色", nil) forState:UIControlStateSelected];
        [_colorsBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    }
    return _colorsBtn;
}

- (UIButton *)pointSizeBtn{
    if(!_pointSizeBtn){
        _pointSizeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if( _type == 1 )
            _pointSizeBtn.frame = CGRectMake( _middleView.frame.size.width - _middleView.frame.size.width*3.0/6.0 ,(self.middleView.frame.size.height - 30)/2.0, _middleView.frame.size.width/3.0, 30);
        else
            _pointSizeBtn.frame = CGRectMake(_type == 1 ? self.typeIconsBtn.frame.origin.x + self.typeIconsBtn.frame.size.width : self.colorsBtn.frame.origin.x + self.colorsBtn.frame.size.width ,(self.middleView.frame.size.height - 30)/2.0, 65, 30);
        [_pointSizeBtn addTarget:self action:@selector(tapPointSizeBtn) forControlEvents:UIControlEventTouchUpInside];
        _pointSizeBtn.layer.cornerRadius = 15.0;
        _pointSizeBtn.layer.masksToBounds = YES;
        _pointSizeBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _pointSizeBtn.backgroundColor = [UIColor clearColor];
        [_pointSizeBtn setTitle:RDLocalizedString(@"大小", nil) forState:UIControlStateNormal];
        [_pointSizeBtn setTitle:RDLocalizedString(@"大小", nil) forState:UIControlStateHighlighted];
        [_pointSizeBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_pointSizeBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
        [_pointSizeBtn setTitle:RDLocalizedString(@"大小", nil) forState:UIControlStateSelected];
        [_pointSizeBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        if( _type == 1 )
            _pointSizeBtn.backgroundColor = TOOLBAR_COLOR;
    }
    return _pointSizeBtn;
}

- (UIButton *)animateBtn {
    if (!_animateBtn) {
        _animateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _animateBtn.frame = CGRectMake(self.pointSizeBtn.frame.origin.x + self.pointSizeBtn.frame.size.width ,(self.middleView.frame.size.height - 30)/2.0, 65, 30);
        [_animateBtn addTarget:self action:@selector(tapAnimateBtn) forControlEvents:UIControlEventTouchUpInside];
        _animateBtn.layer.cornerRadius = 15.0;
        _animateBtn.layer.masksToBounds = YES;
        _animateBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _animateBtn.backgroundColor = [UIColor clearColor];
        [_animateBtn setTitle:RDLocalizedString(@"动画", nil) forState:UIControlStateNormal];
        [_animateBtn setTitle:RDLocalizedString(@"动画", nil) forState:UIControlStateHighlighted];
        [_animateBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_animateBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateHighlighted];
        [_animateBtn setTitle:RDLocalizedString(@"动画", nil) forState:UIControlStateSelected];
        [_animateBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    }
    return _animateBtn;
}

- (UIScrollView *)bottomView{
    if(!_bottomView){
        _bottomView = [UIScrollView new];
        if(_type == 1){
            _bottomView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - (kToolbarHeight - (LastIphone5?0:14)));
        }
        else
            _bottomView.frame = CGRectMake(0, self.middleView.frame.origin.y + self.middleView.frame.size.height, self.frame.size.width, self.frame.size.height - (self.middleView.frame.origin.y + self.middleView.frame.size.height));
        _bottomView.backgroundColor = [UIColor clearColor];
        _bottomView.showsVerticalScrollIndicator = NO;
        _bottomView.showsHorizontalScrollIndicator = NO;
        _bottomView.contentSize = CGSizeMake(_type == 1 ? _bottomView.frame.size.width * 2.0 : _bottomView.frame.size.width * 4.0, _bottomView.frame.size.height);
        _bottomView.pagingEnabled = YES;
        _bottomView.delegate = self;
        if(_type == 1){
            stickerListTypes = [NSMutableArray arrayWithContentsOfFile:kStickerTypesPath];
            if( stickerListTypes == nil )
            {
                isNewSticker = false;
                [_bottomView addSubview:self.typeIconsScrollView];
                [_bottomView addSubview:self.pointSizeView];
                
            }
            else
            {
                isNewSticker = true;
                stickersListArray = [NSMutableArray arrayWithContentsOfFile:kNewStickerPlistPath];
                [_bottomView addSubview:self.stickerView];
                _bottomView.contentSize = CGSizeMake(self.bottomView.frame.size.width, 0);
            }
        }else{
            [_bottomView addSubview:self.typeIconsScrollView];
            [_bottomView addSubview:self.fontsScrollView];
            [_bottomView addSubview:self.colorsScrollView];
            [_bottomView addSubview:self.pointSizeView];
            [_bottomView addSubview:self.fadeAnimateBtn];
            [_bottomView addSubview:self.animateScrollView];
        }
        self.isAnimateFade = YES;
    }
    
    return _bottomView;
}


- (UIScrollView *)typeIconsScrollView{
    if(!_typeIconsScrollView){
        _typeIconsScrollView = [UIScrollView new];
        _typeIconsScrollView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        
        _typeIconsScrollView.backgroundColor = [UIColor clearColor];
        
        
        _typeIconsScrollView.contentSize = CGSizeMake(_typeIconsScrollView.frame.size.width, _bottomView.frame.size.height);
        if(_type == 1){
            modleTypes = [NSMutableArray arrayWithContentsOfFile:kStickerPlistPath];
        }else{
            modleTypes = [NSMutableArray arrayWithContentsOfFile:kSubtitlePlistPath];
        }
        [_typeIconsScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        NSFileManager *manager = [[NSFileManager alloc] init];
        int cellCounts = kWIDTH > 375.0 ? 5 : (4+(LastIphone5?3:0));
        float width = (_typeIconsScrollView.frame.size.width)/(cellCounts);
        
        if( (width*2 + 10) > _typeIconsScrollView.frame.size.height )
        {
            width = (_typeIconsScrollView.frame.size.height-20.0)/2.0;
            cellCounts = _typeIconsScrollView.frame.size.width/width ;
            if( cellCounts > 5 )
            {
                cellCounts = 5;
            }
        }
//        cellCounts++;
        
        
        NSInteger subtitleCount = modleTypes.count;
        int pages = ceilf(subtitleCount / ((cellCounts)*2.0));
        float spanwidth = (_typeIconsScrollView.frame.size.width - width*cellCounts - width*(iPhone_X?(-(1.0/2.0)):1))/(cellCounts - 1);
        __weak  typeof(self) myself = self;
        
        [modleTypes enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL hasNew = [[obj allKeys] containsObject:@"cover"] ? YES : NO;
            int i = idx;
            int cellIdx = i%cellCounts;
            int rowIdx = ceil(i/cellCounts);
            int pageIdx = floor(i/(cellCounts*2));
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.backgroundColor = [UIColor clearColor];
            btn.tag = kCAPTIONTYPEVIEWCHILDTAG+idx;
//            indexCount = idx%((int)cellTypeCount);
            [btn addTarget:self action:@selector(touchescaptionTypeViewChild:) forControlEvents:UIControlEventTouchUpInside];
//            btn.frame = CGRectMake(indexCount*captionTypeBtnWidth+((myself.typeIconsScrollView.frame.size.width - captionTypeBtnWidth*cellTypeCount)/(cellTypeCount+1)*(indexCount+1)), (captionTypeBtnWidth+5)*floor(idx/cellTypeCount)+5, captionTypeBtnWidth, captionTypeBtnWidth);
            [btn setFrame:CGRectMake( 20 + (width + spanwidth) * cellIdx + pageIdx * (_typeIconsScrollView.frame.size.width - width*(iPhone_X?(-(1.0/2.0)):1) + spanwidth), (_typeIconsScrollView.frame.size.height - (width*2+10))/2.0 + (width + 10) * (rowIdx%2), width, width)];

            NSString *fileName =  obj[@"name"];
            NSString *iconPath = nil;
            NSString *path = nil;
            if(myself.type == 1){
//                if(hasNew){
//                    fileName = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[RDHelpClass pathInCacheDirectory:[NSString stringWithFormat:@"SubtitleEffect/Effect%@",hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""]] error:nil] lastObject];
//                }
               iconPath = [NSString stringWithFormat:@"%@/%@",kStickerIconPath,fileName];
                path = [NSString stringWithFormat:@"%@/%@/config.json",[NSString stringWithFormat:@"%@%@",kStickerFolder,hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""],fileName];
            }else{
                if(hasNew){
                    fileName = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@%@",kSubtitleFolder,hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""] error:nil] lastObject];
                }
               iconPath = [NSString stringWithFormat:@"%@/%@",kSubtitleIconPath,fileName];
               path = [NSString stringWithFormat:@"%@/%@/config.json",[NSString stringWithFormat:@"%@%@",kSubtitleFolder,hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""],fileName];
            }
            BOOL check = YES;//emmet 屏蔽更新字幕
            if(hasNew){
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    __block NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:obj[@"cover"]]];
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [btn setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
//                        data = nil;
//                    });
//                });
                [btn rd_sd_setImageWithURL:[NSURL URLWithString:obj[@"cover"]] forState:UIControlStateNormal];
            }else{
                [btn setImage:[UIImage imageWithContentsOfFile:iconPath] forState:UIControlStateNormal];
            }
            if(![manager fileExistsAtPath:path] || !check){
                NSError *error;
                if([manager fileExistsAtPath:path]){
                    [manager removeItemAtPath:path error:&error];
                    NSLog(@"manager_error:%@",error);
                }
                UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
                UIImageView *accessoryView = [[UIImageView alloc] initWithImage:accessory];
                accessoryView.tag = 1;
                accessoryView.frame = CGRectMake(btn.frame.size.width-accessory.size.width, btn.frame.size.height - accessory.size.height, accessory.size.width, accessory.size.height);
                [btn addSubview:accessoryView];
            }
            [myself.typeIconsScrollView addSubview:btn];
        }];
        _selectTypeView = [[UIImageView alloc] init];
        _selectTypeView.backgroundColor = [UIColor clearColor];
        _selectTypeView.frame = CGRectMake(0, 5, width+4, width+4);
        _selectTypeView.layer.cornerRadius = 2;
        _selectTypeView.layer.borderColor = ((UIColor*)Main_Color).CGColor;
        _selectTypeView.layer.borderWidth = 1.0;
        _selectTypeView.layer.masksToBounds = YES;
        _selectTypeView.center = ([(UIButton *)_typeIconsScrollView viewWithTag:kCAPTIONTYPEVIEWCHILDTAG]).center;
        
        [_typeIconsScrollView addSubview:_selectTypeView];
        _typeIconsScrollView.contentSize = CGSizeMake(pages * (_typeIconsScrollView.frame.size.width - width*(iPhone_X?(-(1.0/2.0)):1) + spanwidth) + 20,_typeIconsScrollView.frame.size.height);
        
    }
    
    return _typeIconsScrollView;
}

- (UIScrollView *)fontsScrollView{
    if(!_fontsScrollView){
        _fontsScrollView = [UIScrollView new];
        _fontsScrollView.frame = CGRectMake(self.frame.size.width, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        _fontsScrollView.backgroundColor = [UIColor clearColor];
        _fontsScrollView.contentSize = CGSizeMake(_fontsScrollView.frame.size.width, _fontsScrollView.frame.size.height);
        _fontsScrollView.showsVerticalScrollIndicator = YES;
        _fontsScrollView.showsHorizontalScrollIndicator = NO;
        if(_type == 1){
            _fontsScrollView.hidden = YES;
        }
        
        fonts = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
        fontIconList = [NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath];
        [self initFontIconListView];
        
    }
    
    return _fontsScrollView;
}

- (void)initFontIconListView{
    
    int cellcaptionTypeCount = 1;
    NSInteger indextypeCount;
    float height = 40.0;
    NSFileManager *manager = [NSFileManager defaultManager];
    for (int k = 0; k<fonts.count; k++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [UIColor clearColor];
        [btn addTarget:self action:@selector(touchesFontListViewChild:) forControlEvents:UIControlEventTouchUpInside];
        float width = (self.fontsScrollView.frame.size.width - 10 * (cellcaptionTypeCount + 1))/(float)cellcaptionTypeCount;
        indextypeCount = k%cellcaptionTypeCount;
        btn.frame = CGRectMake(indextypeCount * width + 10 * (indextypeCount + 1), (height+1)*(k/cellcaptionTypeCount), width, height);
        btn.layer.cornerRadius = 0;
        btn.layer.masksToBounds = YES;
        
        BOOL suc = NO;
        UIImageView *imageV = [[UIImageView alloc] init];
        imageV.contentMode = UIViewContentModeScaleAspectFit;
        imageV.frame = CGRectMake(10, 0, 110, btn.frame.size.height);
        
        imageV.backgroundColor = [UIColor clearColor];
        
        NSString *fileName = [[fonts objectAtIndex:k] objectForKey:@"name"];
        NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[fontIconList objectForKey:@"name"]];
        NSString *imagePath;
        imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_1_%@_n_",fileName]];
        
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        if (image) {
            imageV.image = image;
        }
        imageV.tag = kFontTitleImageViewTag;
        imageV.layer.masksToBounds = YES;
        
        if(k==0){
            NSString *title = [[fonts objectAtIndex:k] objectForKey:@"title"];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, 145, btn.frame.size.height)];
            label.text = title;
            label.tag = 3;
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = Main_Color;
            
            label.font = [UIFont systemFontOfSize:16.0];
            [btn addSubview:label];
        }else{
            
            NSString *timeunix = [NSString stringWithFormat:@"%ld",[[fonts[k] objectForKey:@"timeunix"] longValue]];
            
            
            NSString *configPath = kFontCheckPlistPath;
            NSMutableDictionary *configDic = [[NSMutableDictionary alloc] initWithContentsOfFile:configPath];
            BOOL check = [timeunix isEqualToString:[configDic objectForKey:fileName]] ? YES : NO;
            
            NSString *path = [self pathForURL_font:fileName extStr:@"ttf"];
            
            if(![manager fileExistsAtPath:path] || !check){
                NSError *error;
                if([manager fileExistsAtPath:path]){
                    [manager removeItemAtPath:path error:&error];
                    NSLog(@"error:%@",error);
                }
            }
            suc = [self hasCachedFont:fileName extStr:@"ttf"];
        }
        
        UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
        UIImageView *markV = [[UIImageView alloc] initWithFrame:CGRectMake(btn.frame.size.width - 35, (btn.frame.size.height-accessory.size.height)/2, accessory.size.width, accessory.size.height)];
        markV.backgroundColor = [UIColor clearColor];
        markV.tag = 40000;
        [markV setImage:accessory];
        [btn addSubview:markV];
        
        
        if(!suc && k != 0){
            markV.hidden = NO;
        }else{
            markV.hidden = YES;
        }
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        btn.tag = k+kCAPTIONTYPECHILDTAG;
        UIView *span = [[UIView alloc] initWithFrame:CGRectMake(0, btn.frame.size.height-1, btn.frame.size.width, 1)];
        span.backgroundColor = UIColorFromRGB(NV_Color);
        
        [btn addSubview:imageV];
        [btn addSubview:span];
        [self.fontsScrollView addSubview:btn];
    }
    
    int cellCounts = ceil(fonts.count/(float)cellcaptionTypeCount);
    
    self.fontsScrollView.contentSize = CGSizeMake(self.fontsScrollView.frame.size.width, ((height + 1) * cellCounts + 10));
}

-(NSString *)pathForURL_font:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@/%@.%@",kFontFolder,name,name,extStr];
}

//判断是否已经缓存过这个URL
-(BOOL) hasCachedFont:(NSString *)name extStr:(NSString *)extStr{
    if(extStr.length == 0){
        return NO;
    }
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self pathForURL_font:name extStr:extStr]]) {
        return YES;
    }
    else return NO;
}

- (UIScrollView *)colorsScrollView{
    if(!_colorsScrollView){
        _colorsScrollView = [UIScrollView new];
        _colorsScrollView.frame = CGRectMake(self.frame.size.width * 2, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        _colorsScrollView.backgroundColor = [UIColor clearColor];
        _colorsScrollView.showsVerticalScrollIndicator = NO;
        _colorsScrollView.showsHorizontalScrollIndicator = NO;
        _colorsScrollView.contentSize = CGSizeMake(_colorsScrollView.frame.size.width, _colorsScrollView.frame.size.height);
        if(_type == 1){
            _colorsScrollView.hidden = YES;
        }
        
        selectFontColorView = [[UIView alloc] init];
        selectFontColorView.backgroundColor = [UIColor clearColor];
        selectFontColorView.frame = CGRectMake(0, 0, KCOLORBTNWIDTH+10, KCOLORBTNWIDTH+10);
        selectFontColorView.layer.cornerRadius = 3.0;
        selectFontColorView.layer.masksToBounds = YES;
        
        UIView *cornerRadius = [[UIView alloc] initWithFrame:CGRectMake(4, 4, KCOLORBTNWIDTH+2, KCOLORBTNWIDTH+2)];
        cornerRadius.backgroundColor = UIColorFromRGB(0x33333b);
        cornerRadius.layer.cornerRadius = 3.0;
        cornerRadius.layer.masksToBounds = YES;
        [selectFontColorView addSubview:cornerRadius];
        [_colorsScrollView addSubview:selectFontColorView];
        
        int indexColorCount = 0;
        for (int j=0;j<KFONTCOLORCOUNT;j++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.backgroundColor = [self returnColor:j];
            btn.tag = kCaptionFONTCOLORCHILDTAG+j;
            indexColorCount = j%KCELLFONTCOLORCOUNT;
            int cellIndex = j/KCELLFONTCOLORCOUNT;
            [btn addTarget:self action:@selector(touchesColorViewChild:) forControlEvents:UIControlEventTouchUpInside];
            if(cellIndex%2==0){
                btn.frame = CGRectMake(indexColorCount*KCOLORBTNWIDTH+((_colorsScrollView.frame.size.width - (KCOLORBTNWIDTH/2) - KCOLORBTNWIDTH*KCELLFONTCOLORCOUNT)/(KCELLFONTCOLORCOUNT+1)*(indexColorCount+1)), (KCOLORBTNWIDTH+10)*(j/KCELLFONTCOLORCOUNT)+10, KCOLORBTNWIDTH, KCOLORBTNWIDTH);
                if(_colorsScrollView.frame.size.height > 210){
                    float height = (_colorsScrollView.frame.size.height - (KCOLORBTNWIDTH*5))/6;
                    btn.frame = CGRectMake(indexColorCount*KCOLORBTNWIDTH+((_colorsScrollView.frame.size.width - (KCOLORBTNWIDTH/2) - KCOLORBTNWIDTH*KCELLFONTCOLORCOUNT)/(KCELLFONTCOLORCOUNT+1)*(indexColorCount+1)), (KCOLORBTNWIDTH+height)*(j/KCELLFONTCOLORCOUNT)+height, KCOLORBTNWIDTH, KCOLORBTNWIDTH);
                }
            }else{
                btn.frame = CGRectMake((KCOLORBTNWIDTH/2) + indexColorCount*KCOLORBTNWIDTH+((_colorsScrollView.frame.size.width - (KCOLORBTNWIDTH/2) - KCOLORBTNWIDTH*KCELLFONTCOLORCOUNT)/(KCELLFONTCOLORCOUNT+1)*(indexColorCount+1)), (KCOLORBTNWIDTH+10)*(j/KCELLFONTCOLORCOUNT)+10, KCOLORBTNWIDTH, KCOLORBTNWIDTH);
                if(_colorsScrollView.frame.size.height > 210){
                    float height = (_colorsScrollView.frame.size.height - (KCOLORBTNWIDTH*5))/6;
                    btn.frame = CGRectMake((KCOLORBTNWIDTH/2) + indexColorCount*KCOLORBTNWIDTH+((_colorsScrollView.frame.size.width - (KCOLORBTNWIDTH/2) - KCOLORBTNWIDTH*KCELLFONTCOLORCOUNT)/(KCELLFONTCOLORCOUNT+1)*(indexColorCount+1)), (KCOLORBTNWIDTH+height)*(j/KCELLFONTCOLORCOUNT)+height, KCOLORBTNWIDTH, KCOLORBTNWIDTH);
                }
            }
            if(j==0){
                selectFontColorView.backgroundColor = btn.backgroundColor;
                selectFontColorView.center = btn.center;
            }
            btn.layer.borderColor = UIColorFromRGB(0x33333b).CGColor;
            btn.layer.borderWidth = 0;
            btn.layer.cornerRadius = 3.0;//KCOLORBTNWIDTH/2;
            btn.layer.masksToBounds = YES;
            [_colorsScrollView addSubview:btn];
            
        }
        
        
        
    }
    return _colorsScrollView;
}

- (UIView *)pointSizeView{
    if(!_pointSizeView){
        _pointSizeView = [UIView new];
        _pointSizeView.frame = CGRectMake( _type == 1 ? self.frame.size.width : self.frame.size.width * 3, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        _pointSizeView.backgroundColor = [UIColor clearColor];
    
        [_pointSizeView addSubview:self.pointSizeScrollView];
        [_pointSizeView addSubview:self.pointSizelabel];
        
        UIView *span = [UIView new];
        span.frame = CGRectMake(self.pointSizelabel.frame.origin.x + self.pointSizelabel.frame.size.width/2.0 - 1, self.pointSizelabel.frame.origin.y+self.pointSizelabel.frame.size.height+5, 2,25);
        span.backgroundColor = Main_Color;
        
        [_pointSizeView addSubview:span];
    }
    
    return _pointSizeView;
}

- (UIScrollView *)pointSizeScrollView{
    if(!_pointSizeScrollView){
        _pointSizeScrollView = [UIScrollView new];
        _pointSizeScrollView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        _pointSizeScrollView.backgroundColor = [UIColor clearColor];
        _pointSizeScrollView.contentSize = CGSizeMake(_pointSizeScrollView.frame.size.width, _pointSizeScrollView.frame.size.height);
        _pointSizeScrollView.delegate = self;
        _pointSizeScrollView.showsVerticalScrollIndicator = NO;
        _pointSizeScrollView.showsHorizontalScrollIndicator = NO;
        float tmpHeight = _pointSizeScrollView.frame.size.height*2/5 - (iPhone4s ? 0 : 10);
        float tmpOrginX = (_pointSizeScrollView.frame.size.height-_pointSizeScrollView.frame.size.height*2/5)/2.0+20;
        
        for (int k=0; k<=16; k++) {
            
            UIView *sizeImageView_1 = [[UIView alloc] init];
            sizeImageView_1.frame = CGRectMake(_pointSizeScrollView.frame.size.width/2+k*3*15,tmpOrginX , 2, tmpHeight);//
            
            sizeImageView_1.backgroundColor = [UIColor whiteColor];
            
            [_pointSizeScrollView addSubview:sizeImageView_1];
            if(k<16){
                UIView *sizeImageView_2 = [[UIView alloc] init];
                sizeImageView_2.frame = CGRectMake(_pointSizeScrollView.frame.size.width/2+(k*3+1)*15,tmpOrginX+10, 2, tmpHeight - 10);//
                
                sizeImageView_2.backgroundColor = [UIColor whiteColor];
                
                [_pointSizeScrollView addSubview:sizeImageView_2];
                
                UIView *sizeImageView_3 = [[UIView alloc] init];
                sizeImageView_3.frame = CGRectMake(_pointSizeScrollView.frame.size.width/2+(k*3+2)*15,tmpOrginX+10, 2, tmpHeight - 10);//
                
                sizeImageView_3.backgroundColor = [UIColor whiteColor];
                
                [_pointSizeScrollView addSubview:sizeImageView_3];
            }
        }
        _pointSizeScrollView.contentSize = CGSizeMake(_pointSizeScrollView.frame.size.width+15*((30-14)*3), 0);
    }
    
    return _pointSizeScrollView;
}
- (UILabel *)pointSizelabel{
    if(!_pointSizelabel){
        _pointSizelabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2.0 - 30 ,  30, 60, 15)];
        _pointSizelabel.textAlignment = NSTextAlignmentCenter;
        _pointSizelabel.textColor = UIColorFromRGB(0xffffff);
        _pointSizelabel.text = @"0";
        _pointSizelabel.font = [UIFont systemFontOfSize:12];
    }
    return _pointSizelabel;
}

- (UIButton *)fadeAnimateBtn {
    if (!_fadeAnimateBtn) {
        _fadeAnimateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fadeAnimateBtn.backgroundColor = UIColorFromRGB(0x3c3b43);
        _fadeAnimateBtn.frame = CGRectMake(self.frame.size.width * 4 + (self.frame.size.width - 100)/2.0, 10, 100, 30);
        _fadeAnimateBtn.layer.cornerRadius = 15.0;
        [_fadeAnimateBtn setTitle:RDLocalizedString(@"淡入淡出", nil) forState:UIControlStateNormal];
        [_fadeAnimateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_fadeAnimateBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        [_fadeAnimateBtn addTarget:self action:@selector(fadeAnimateBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        _fadeAnimateBtn.selected = YES;
    }
    return _fadeAnimateBtn;
}

- (UIScrollView *)animateScrollView {
    if (!_animateScrollView) {
        _animateScrollView = [UIScrollView new];
        _animateScrollView.frame = CGRectMake(self.frame.size.width * 4, 50, self.bottomView.frame.size.width, self.bottomView.frame.size.height - 50);
        _animateScrollView.backgroundColor = [UIColor clearColor];
        _animateScrollView.showsVerticalScrollIndicator = NO;
        _animateScrollView.showsHorizontalScrollIndicator = NO;
        _animateScrollView.contentSize = CGSizeMake(_animateScrollView.frame.size.width, _animateScrollView.frame.size.height);
        
        NSArray *animateArray = [NSArray arrayWithObjects:
                                 RDLocalizedString(@"无", nil),
                                 RDLocalizedString(@"左推", nil),
                                 RDLocalizedString(@"右推", nil),
                                 RDLocalizedString(@"上推", nil),
                                 RDLocalizedString(@"下推", nil),
                                 RDLocalizedString(@"缩放入出", nil),
                                 RDLocalizedString(@"滚动入出", nil),
                                 nil];
        
        int rowCount = 4;
        if([UIScreen mainScreen].bounds.size.width>320){
            rowCount = 5;
        }
        
        float animateTypeBtnWidth = 80;
        float animateTypeBtnHeight = 30;
        __block int indexRow = 0;
        WeakSelf(self);
        [animateArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            StrongSelf(self);
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.backgroundColor = [UIColor clearColor];
            btn.tag = idx + 1;
            indexRow = idx%rowCount;
            [btn addTarget:strongSelf action:@selector(touchesAnimateTypeViewChild:) forControlEvents:UIControlEventTouchUpInside];
            btn.frame = CGRectMake(indexRow*animateTypeBtnWidth+((strongSelf.animateScrollView.frame.size.width - animateTypeBtnWidth*rowCount)/(rowCount+1)*(indexRow+1)), (animateTypeBtnHeight+15)*(idx/rowCount)+5, animateTypeBtnWidth, animateTypeBtnHeight);
            [btn setTitle:[NSString stringWithFormat:@"%@", obj] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn setTitleColor:Main_Color forState:UIControlStateSelected];
            if (idx == 0) {
                btn.selected = YES;
            }
            [strongSelf.animateScrollView addSubview:btn];
        }];
        NSInteger count = ceilf(animateArray.count/rowCount);
        _animateScrollView.contentSize = CGSizeMake(_animateScrollView.frame.size.width,(animateTypeBtnWidth+10) * count + (_type == 1 ? -20 : 20));
    }
    return _animateScrollView;
}

- (void)fadeAnimateBtnAction:(UIButton *)sender {
    _fadeAnimateBtn.selected = !_fadeAnimateBtn.selected;
    self.isAnimateFade = _fadeAnimateBtn.selected;
}

- (void)touchesAnimateTypeViewChild:(UIButton *)sener {
    if (sener.tag != (_selectedAnimateIndex + 1)) {
        UIButton *prevBtn = [_animateScrollView viewWithTag:(_selectedAnimateIndex + 1)];
        prevBtn.selected = NO;
        
        sener.selected = YES;
        _selectedAnimateIndex = sener.tag - 1;
        if (_delegate && [_delegate respondsToSelector:@selector(changeSubtitleAnimateType:)]) {
            [_delegate changeSubtitleAnimateType:_selectedAnimateIndex];
        }
    }
}

- (void)clearTextField:(UIButton *)sender{
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:RDLocalizedString(@"点击输入字幕", nil)];//[self contentTextFieldText]];
        _contentTextField.text = @"";
    }
}

- (void)save{
    self.hidden = YES;
    [_contentTextField resignFirstResponder];
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:[self contentTextFieldText]];
    }
    if([_delegate respondsToSelector:@selector(saveSubtitleEffect:)]){
        [_delegate saveSubtitleEffect:selectTypeIndex];
    }
}

-(void)tapTypeIconsBtn{
    _bottomView.contentOffset = CGPointMake(0, 0);
    [_contentTextField resignFirstResponder];
    [_middleView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIButton class]]){
            ((UIButton *)obj).selected = NO;
        }
    }];
    [_middleView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIButton class]]){
            ((UIButton *)obj).selected = NO;
        }
    }];
    if(!self.selectView.superview){
        [_middleView addSubview:self.selectView];
    }
    self.selectView.center = CGPointMake(self.typeIconsBtn.center.x, self.selectView.center.y);
    self.selectView.hidden = NO;
    self.typeIconsBtn.selected = YES;
}

-(void)tapFontsBtn{
    [_contentTextField resignFirstResponder];
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:[self contentTextFieldText]];
    }
    _bottomView.contentOffset = CGPointMake(_bottomView.frame.size.width, 0);
    [_middleView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIButton class]]){
            ((UIButton *)obj).selected = NO;
        }
    }];
    if(!self.selectView.superview){
        [_middleView addSubview:self.selectView];
    }
    self.selectView.center = CGPointMake(self.fontsBtn.center.x, self.selectView.center.y);
    self.selectView.hidden = NO;
    self.fontsBtn.selected = YES;
}

-(void)tapColorsBtn{
    [_contentTextField resignFirstResponder];
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:[self contentTextFieldText]];
    }
    _bottomView.contentOffset = CGPointMake(_bottomView.frame.size.width*2, 0);
    [_middleView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIButton class]]){
            ((UIButton *)obj).selected = NO;
        }
    }];
    if(!self.selectView.superview){
        [_middleView addSubview:self.selectView];
    }
    self.selectView.center = CGPointMake(self.colorsBtn.center.x, self.selectView.center.y);
    self.selectView.hidden = NO;
    self.colorsBtn.selected = YES;
}

-(void)tapPointSizeBtn{
    [_contentTextField resignFirstResponder];
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:[self contentTextFieldText]];
    }
    _bottomView.contentOffset = CGPointMake(_bottomView.frame.size.width * (_type == 1? 1 : 3), 0);
    [_middleView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIButton class]]){
            ((UIButton *)obj).selected = NO;
        }
    }];
    if(!self.selectView.superview){
        [_middleView addSubview:self.selectView];
    }
    self.selectView.center = CGPointMake(self.pointSizeBtn.center.x, self.selectView.center.y);
    self.selectView.hidden = NO;
    self.pointSizeBtn.selected = YES;
}

- (void)tapAnimateBtn {
    _bottomView.contentOffset = CGPointMake(_bottomView.frame.size.width * 4, 0);
    [_middleView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIButton class]]){
            ((UIButton *)obj).selected = NO;
        }
    }];
    if(!self.selectView.superview){
        [_middleView addSubview:self.selectView];
    }
    self.selectView.center = CGPointMake(_animateBtn.center.x, self.selectView.center.y);
    self.selectView.hidden = NO;
    _animateBtn.selected = YES;
}

/**选择字体颜色
 */
- (void)touchesColorViewChild:(UIButton *)sender{
    selectColor = sender.backgroundColor;
    selectFontColorView.backgroundColor = sender.backgroundColor;
    selectFontColorView.center = sender.center;
    
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentTextColor:shadowColor:)]){
        [_delegate changeSubtitleEffectContentTextColor:selectColor shadowColor:UIColorFromRGB(0x888888)];
    }
}

//根据ID设置字体
- (void)setFont:(NSInteger)index{
    NSString *selectFontName;
    for (int k=0;k<fonts.count;k++) {
        UIButton *sender = (UIButton *)[self.fontsScrollView viewWithTag:k + kCAPTIONTYPECHILDTAG];
        UIImageView *imagev = (UIImageView *)[sender viewWithTag:4000];
        NSString *title = [[fonts objectAtIndex:sender.tag - kCAPTIONTYPECHILDTAG] objectForKey:@"name"];
        UIImageView *titleIV = (UIImageView *)[sender viewWithTag:kFontTitleImageViewTag];
        BOOL isCached = [self hasCachedFont:title extStr:@"ttf"];
        if ([titleIV isKindOfClass:[UIImageView class]]) {
            if(isCached && sender.tag - kCAPTIONTYPECHILDTAG == index){
                NSString *path = [NSString stringWithFormat:@"%@/%@/selected",kFontFolder,title];
                NSString *imagePath;
                imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_",title]];
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                if (image) {
                    titleIV.image = image;
                }
            }else if (sender.tag - kCAPTIONTYPECHILDTAG != 0) {
                NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[fontIconList objectForKey:@"name"]];
                NSString *imagePath;
                
                imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_",title]];
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                if (image) {
                    titleIV.image = image;
                }
            }else {
                UILabel *titleLbl = (UILabel *)[sender viewWithTag:3];
                if ([titleLbl isKindOfClass:[UILabel class]]) {
                    if (sender.tag - kCAPTIONTYPECHILDTAG == index) {
                        titleLbl.textColor = Main_Color;
                    }else {
                        titleLbl.textColor = UIColorFromRGB(0xbdbdbd);
                    }
                }
            }
            
        }
        if([imagev isKindOfClass:[UIImageView class]]){
            if((sender.tag - kCAPTIONTYPECHILDTAG == index) ||!isCached){
                if(sender.tag - kCAPTIONTYPECHILDTAG == index){
                    imagev.image = [RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"];
                    imagev.hidden = YES;
                    
                }else if(!isCached && sender.tag - kCAPTIONTYPECHILDTAG != 0 ){
                    imagev.image = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
                    imagev.hidden = NO;
                    
                }else{
                    imagev.hidden = YES;
                }
            }else{
                imagev.hidden = YES;
            }
        }
        
        
    }
    if(index==0){
        selectFontName = [[UIFont systemFontOfSize:10] fontName];//@"Baskerville-BoldItalic";
        NSLog(@"selectFontName==%@",selectFontName);
        
        if([_delegate respondsToSelector:@selector(setFontWithName:fontCode:isSystem:)]){
            [_delegate setFontWithName:selectFontName fontCode:@"morenziti" isSystem:YES];
        }
        
        return;
    }
    
    NSString *fontCode;
    NSString *path;
    fontCode = [[fonts objectAtIndex:index] objectForKey:@"name"];
    path = [self pathForURL_font:fontCode extStr:@"ttf"];
   
    NSArray *fontNames = [RDHelpClass customFontArrayWithPath:path];
    NSLog(@"fontName:%@",fontNames);
    selectFontName = [fontNames lastObject];
    fontNames = nil;

    if([_delegate respondsToSelector:@selector(setFontWithName:fontCode:isSystem:)]){
        [_delegate setFontWithName:selectFontName fontCode:fontCode isSystem:NO];
    }
    
    
    
}


/**选择字体
 */
- (void)touchesFontListViewChild:(UIButton *)sender{
   
    if(!sender){
        sender = [_fontsScrollView viewWithTag:kCAPTIONTYPECHILDTAG];
    }
    if(!sender){
        return;
    }
    NSString *title = [[fonts objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG] objectForKey:@"name"];
    UIImageView *imageView = (UIImageView *)[sender viewWithTag:40000];
    BOOL suc = [self hasCachedFont:title extStr:@"ttf"];
    NSInteger index = sender.tag - kCAPTIONTYPECHILDTAG;
    if(index == 0){
        [self setFont:index];
        
    }else if(!suc){
        
        if([_delegate respondsToSelector:@selector(downloadFile:cachePath:fileName:timeunix:type:sender:progress:finishBlock:failBlock:)]){
            NSString *fileName = [[fonts objectAtIndex:index] objectForKey:@"name"];
            
            NSString *pExtension = [[[fonts objectAtIndex:index][@"file"] lastPathComponent] pathExtension];
            NSString *time = [NSString stringWithFormat:@"%ld",[[[fonts objectAtIndex:index] objectForKey:@"timeunix"] longValue]];

            NSString * path = [self pathForURL_font_down:fileName extStr:pExtension];
            
            [_delegate downloadFile:[[fonts objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG] objectForKey:@"caption"] cachePath:path fileName:fileName timeunix:time type:3 sender:imageView progress:^(float progress) {
                
            }  finishBlock:^{
                imageView.hidden = YES;
                [imageView removeFromSuperview];
            } failBlock:^{
                imageView.hidden = NO;
            }];
        }
    }else{
        [self setFont:index];
    }
}

- (NSString *)pathForURL_font_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,name,extStr];
}

- (NSString *)pathForURL_Effect_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kStickerFolder,name,extStr];
}

- (NSString *)pathForURL_Subtitle_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kSubtitleFolder,name,extStr];
}

- (void)touchescaptionTypeViewChildWithIndex:(NSInteger)index{
    UIButton *sender = nil;
    if( isNewSticker )
    {
        bool isLast = true;
        for (int i = 0; i < stickersIndexArray.count; i++) {
            if( [stickersIndexArray[i] intValue] > index )
            {
                [self stickListScrollView:i-1];
                isLast = false;
                break;
            }
        }
        
        if( isLast )
           [self stickListScrollView:stickersIndexArray.count-1];
        
        [self stickerLabel_Btn:nil];
        
        sender = (UIButton *)[stickersScrollArray[currentSelectLabelIndex] viewWithTag:kCAPTIONTYPEVIEWCHILDTAG+index];
        stickersScrollArray[currentSelectLabelIndex].contentOffset = CGPointMake(sender.frame.origin.x - 15, 0);
    }
    else
        sender = (UIButton *)[_typeIconsScrollView viewWithTag:kCAPTIONTYPEVIEWCHILDTAG+index];
    [self touchescaptionTypeViewChild:sender];
}

- (void)touchesColorViewChildWithColor:(UIColor *)color{
    NSInteger index = [self returnColorIndex:color];
    UIButton *sender = (UIButton *)[_colorsScrollView viewWithTag:kCaptionFONTCOLORCHILDTAG+index];
    
    [self touchesColorViewChild:sender];
    
}

- (void)clear{
    [_typeIconsScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[UIImageView class]]){
            ((UIImageView *)obj).image = nil;
            [obj removeFromSuperview];
//            obj = nil;
        }
    }];
    [_pointSizeScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
//            obj = nil;
    }];
    
    [_colorsScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
//        obj = nil;
    }];
}
/**选择样式
 */
- (void)touchescaptionTypeViewChild:(UIButton *)sender{
    if(isDowning){
        return;
    }
    
    NSInteger index = sender.tag - kCAPTIONTYPEVIEWCHILDTAG;
    if(!sender){
        index = 0;
        [self tapTypeIconsBtn];
        if( isNewSticker )
        {
            sender = (UIButton *)[stickersScrollArray[currentSelectLabelIndex] viewWithTag:kCAPTIONTYPEVIEWCHILDTAG+index];
        }
        else
            sender = (UIButton *)[_typeIconsScrollView viewWithTag:kCAPTIONTYPEVIEWCHILDTAG+index];
    }
    _selectTypeView.center = sender.center;
    
    NSLog(@"index:%d",(int)index);
    __block typeof(self) bself = self;
    NSDictionary *itemDic = modleTypes[index];
    NSString *pExtension = [[itemDic[@"file"] lastPathComponent] pathExtension];
    
    BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
    NSString *fileName = hasNew ? [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension] : [modleTypes[index] objectForKey:@"name"];
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *folderName =hasNew ? [NSString stringWithFormat:@"/%@",[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@/%@.%@",kSubtitleFolder,folderName,fileName,pExtension];
    if(_type == 1){
        path = [NSString stringWithFormat:@"%@%@/%@.%@",kStickerFolder,folderName,fileName,pExtension];
    }
    NSFileManager *manager = [[NSFileManager alloc] init];
    if(![manager fileExistsAtPath:[path stringByDeletingLastPathComponent]]){
        [manager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSArray *fileArray = [manager contentsOfDirectoryAtPath:[path stringByDeletingLastPathComponent] error:nil];
    NSString *name;
    if(fileArray.count > 0){
        for (NSString *fileName in fileArray) {
            if (![fileName isEqualToString:@"__MACOSX"]) {
                NSString *folderPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
                BOOL isDirectory = NO;
                BOOL isExists = [manager fileExistsAtPath:folderPath isDirectory:&isDirectory];
                if (isExists && isDirectory) {
                    name = fileName;
                    break;
                }
            }
        }
    }
    NSString *configPath = [NSString stringWithFormat:@"%@/config.json",hasNew ? [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name] : [path stringByDeletingPathExtension]];
    if(![manager fileExistsAtPath:configPath]){
        if([_delegate respondsToSelector:@selector(downloadFile:cachePath:fileName:timeunix:type:sender:progress:finishBlock:failBlock:)]){

            NSString *time = [NSString stringWithFormat:@"%ld",[(hasNew ? itemDic[@"updatetime"] : itemDic[@"timeunix"]) integerValue]];
            isDowning = YES;
            [_delegate downloadFile:hasNew ? itemDic[@"file"] : itemDic[(_type == 1 ? @"caption" : @"zimu")] cachePath:path fileName:hasNew ? @"" : fileName timeunix:time type:(_type + 1) sender:sender progress:^(float progress) {
                
            }  finishBlock:^{
                bself->isDowning = NO;
                [self touchescaptionTypeViewChild:sender];
            } failBlock:^{
                bself->isDowning = NO;
            }];
        }
    }else if([_delegate respondsToSelector:@selector(changeSubtitleEffect:type:index:)]){
        [_delegate changeSubtitleEffect:configPath type:_type+1 index:index];
    }
}
#pragma mark- 根据索引获取字幕颜色
/*
 根据索引获取字幕颜色
 */
- (UIColor *)returnColor:(NSInteger)index{
    
    NSString *colorStr= @"";
    
    switch (index) {
        case 0:
            colorStr= @"ffffff";
            break;
        case 1:
            colorStr= @"e8ce6b";
            break;
        case 2:
            colorStr= @"f9b73c";
            break;
        case 3:
            colorStr= @"e3573b";
            break;
        case 4:
            colorStr= @"be213b";
            break;
        case 5:
            colorStr= @"00ffff";
            break;
        case 6:
            colorStr= @"5da9cf";
            break;
        case 7:
            colorStr= @"0695b5";
            break;
        case 8:
            colorStr= @"2791db";
            break;
        case 9:
            colorStr= @"3564b7";
            break;
        case 10:
            colorStr= @"e9c930";
            break;
        case 11:
            colorStr= @"a6b45c";
            break;
        case 12:
            colorStr= @"87a522";
            break;
        case 13:
            colorStr= @"32b16c";
            break;
        case 14:
            colorStr= @"017e54";
            break;
        case 15:
            colorStr= @"fdbacc";
            break;
        case 16:
            colorStr= @"ff5a85";
            break;
        case 17:
            colorStr= @"ca4f9b";
            break;
        case 18:
            colorStr= @"71369a";
            break;
        case 19:
            colorStr= @"6720d4";
            break;
        case 20:
            colorStr= @"164c6e";
            break;
        case 21:
            colorStr= @"9f9f9f";
            break;
        case 22:
            colorStr= @"484848";
            break;
        case 23:
            colorStr= @"000000";
            break;
        default:
            break;
    }
    return [self colorWithHexString:colorStr];
}
#pragma mark- 根据颜色返回索引
- (NSInteger)returnColorIndex:(UIColor *)color{
    
    NSInteger index;
    
    if([color isEqual:[self colorWithHexString:@"ffffff"]]){
        index= 0;
    }
    else if([color isEqual:[self colorWithHexString:@"e8ce6b"]]){
        index= 1;
    }
    else if([color isEqual:[self colorWithHexString:@"f9b73c"]]){
        index= 2;
    }
    else if([color isEqual:[self colorWithHexString:@"e3573b"]]){
        index= 3;
    }
    else if([color isEqual:[self colorWithHexString:@"be213b"]]){
        index= 4;
    }
    else if([color isEqual:[self colorWithHexString:@"00ffff"]]){
        index= 5;
    }
    else if([color isEqual:[self colorWithHexString:@"5da9cf"]]){
        index= 6;
    }
    else if([color isEqual:[self colorWithHexString:@"0695b5"]]){
        index= 7;
    }
    else if([color isEqual:[self colorWithHexString:@"2791db"]]){
        index= 8;
    }
    else if([color isEqual:[self colorWithHexString:@"3564b7"]]){
        index= 9;
    }
    else if([color isEqual:[self colorWithHexString:@"e9c930"]]){
        index= 10;
    }
    else if([color isEqual:[self colorWithHexString:@"a6b45c"]]){
        index= 11;
    }
    else if([color isEqual:[self colorWithHexString:@"87a522"]]){
        index= 12;
    }
    else if([color isEqual:[self colorWithHexString:@"32b16c"]]){
        index= 13;
    }
    else if([color isEqual:[self colorWithHexString:@"017e54"]]){
        index= 14;
    }
    else if([color isEqual:[self colorWithHexString:@"fdbacc"]]){
        index= 15;
    }
    else if([color isEqual:[self colorWithHexString:@"ff5a85"]]){
        index= 16;
    }
    else if([color isEqual:[self colorWithHexString:@"ca4f9b"]]){
        index= 17;
    }
    else if([color isEqual:[self colorWithHexString:@"71369a"]]){
        index= 18;
    }
    else if([color isEqual:[self colorWithHexString:@"6720d4"]]){
        index= 19;
    }
    else if([color isEqual:[self colorWithHexString:@"164c6e"]]){
        index= 20;
    }
    else if([color isEqual:[self colorWithHexString:@"9f9f9f"]]){
        index= 21;
    }
    else if([color isEqual:[self colorWithHexString:@"484848"]]){
        index= 22;
    }
    else if([color isEqual:[self colorWithHexString:@"000000"]]){
        index= 23;
    }else{
        index = 23;
    }
    return index;
}

- (UIColor *) colorWithHexString: (NSString *)color
{
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if( scrollView == stickersScrollArray[currentSelectLabelIndex] )
    {
        
        
        if( stickersScrollArray[currentSelectLabelIndex].contentOffset.x > (stickersScrollArray[currentSelectLabelIndex].contentSize.width - stickersScrollArray[currentSelectLabelIndex].frame.size.width + KScrollHeight) )
        {
            if(  currentSelectLabelIndex <  (stickersScrollArray.count - 1)  )
            {
                stickersScrollArray[currentSelectLabelIndex].delegate = nil;
                [self stickerLabel_Btn:[_stickerLabelScrollView viewWithTag:currentSelectLabelIndex+1]];
            }
        }
        else if(  stickersScrollArray[currentSelectLabelIndex].contentOffset.x < - KScrollHeight )
        {
            if( currentSelectLabelIndex > 0 )
            {
                stickersScrollArray[currentSelectLabelIndex].delegate = nil;
                [self stickerLabel_Btn:[_stickerLabelScrollView viewWithTag:currentSelectLabelIndex-1]];
            }
        }
        
        return;
    }
    
    if( scrollView == _stickerListScrollView )
    {
        if( _type == 1 )
        {
            float fWidth = scrollView.contentOffset.x;
            
            for (int i  = stickersListIndexArray.count-1; i >= 0 ; i -- ) {
                if( ([stickersListIndexArray[i] floatValue]-16.0) <= fWidth )
                {
                    if( stickersLabelBtnArray[ i ].isSelected != true )
                    {
                        [_stickerLabelScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if( [obj isKindOfClass:[UIButton class]] )
                            {
                                ( (UIButton*)obj ).selected = NO;
                            }
                        }];
                        stickersLabelBtnArray[ i ].selected = YES;
                    }
                    break;
                }
            }
        }
        return;
    }
    
    if(scrollView == _bottomView){
        if(_type == 1){
            if(scrollView.contentOffset.x == 0){
                [self tapTypeIconsBtn];
            }
            else if(scrollView.contentOffset.x == _bottomView.frame.size.width){
                [self tapPointSizeBtn];
            }
        }else{
            if(scrollView.contentOffset.x == 0){
                [self tapTypeIconsBtn];
            }
            else if(scrollView.contentOffset.x == _bottomView.frame.size.width){
                [self tapFontsBtn];
            }
            else if(scrollView.contentOffset.x == _bottomView.frame.size.width*2){
                [self tapColorsBtn];
            }
            else if(scrollView.contentOffset.x == _bottomView.frame.size.width*3){
                [self tapPointSizeBtn];
            }
        }
        
        return;
    }
    
    if (scrollView.contentOffset.x <= 0) {
        sizeScale = kStickerMinScale;
    }else {
        sizeScale = scrollView.contentOffset.x / (scrollView.contentSize.width - scrollView.frame.size.width) * (kStickerMaxScale - kStickerMinScale) + kStickerMinScale;
    }
    _pointSizelabel.text = [NSString stringWithFormat:@"%2.2lf",22+8*sizeScale];
//    NSLog(@"scale:%f x:%.2f w:%.2f", sizeScale, scrollView.contentOffset.x, scrollView.contentSize.width);
    if( scrollView == _pointSizeScrollView )
    {
        if( !_pointSizeScrollView.dragging  )
            return;
    }
    if([_delegate respondsToSelector:@selector(changePointSizeScale:)]){
        [_delegate changePointSizeScale:sizeScale];
    }
    
}

-(void)setPointSizeScrollView_contentOffset:(float) scale
{
    sizeScale = scale;
    if (sizeScale < kStickerMinScale) {
        sizeScale = kStickerMinScale;
    }
    _pointSizeScrollView.contentOffset = CGPointMake((sizeScale - kStickerMinScale)*((_pointSizeScrollView.contentSize.width - _pointSizeScrollView.frame.size.width) / (kStickerMaxScale - kStickerMinScale)), _pointSizeScrollView.contentOffset.y);
    _pointSizelabel.text = [NSString stringWithFormat:@"%2.2lf",22+8*sizeScale];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:textField.text];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [_contentTextField resignFirstResponder];
    if([_delegate respondsToSelector:@selector(changeSubtitleEffectContentText:)]){
        [_delegate changeSubtitleEffectContentText:textField.text];
    }
    return YES;
}

- (NSMutableArray <NSDictionary *>*)typeList{
    return [modleTypes mutableCopy];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

#pragma mark- 新贴纸界面
-(UIView*)stickerView
{
    if( !_stickerView )
    {
        _stickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bottomView.frame.size.width,self.bottomView.frame.size.height)];
        
        [_stickerView addSubview:self.stickerLabelScrollView];
    }
    return  _stickerView;
}

-(UIScrollView *)stickerLabelScrollView
{
    if( !_stickerLabelScrollView )
    {
        float width = 45;
        
        if( !iPhone_X )
        {
            width = 45;
        }
        
        _stickerLabelScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, width)];
        _stickerLabelScrollView.backgroundColor = TOOLBAR_COLOR;
        _stickerLabelScrollView.showsVerticalScrollIndicator = NO;
        _stickerLabelScrollView.showsHorizontalScrollIndicator = NO;
        stickersLabelBtnArray = [NSMutableArray new];
        stickersImageViewArray = [NSMutableArray new];
        uncheckedBtnArray = [NSMutableArray new];
        checkedBtnArray = [NSMutableArray new];
        _stickerLabelScrollView.tag = 10000;
        for (int i = 0; i < stickerListTypes.count; i++) {
            
            UIButton   * btn = [[UIButton alloc] initWithFrame:CGRectMake(i*(width+5), 0, width, _stickerLabelScrollView.frame.size.height)];
            btn.titleLabel.textAlignment = NSTextAlignmentCenter;
            
            btn.tag = i;
//            [btn setTitle:[stickerListTypes[i] objectForKey:@"name"] forState:UIControlStateNormal];
            [btn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            
//            [btn rd_sd_setImageWithURL:[NSURL URLWithString:[stickerListTypes[i] objectForKey:@"icon_unchecked"] ] forState:UIControlStateNormal];
//            [btn rd_sd_setImageWithURL:[NSURL URLWithString:[stickerListTypes[i] objectForKey:@"icon_checked"] ] forState:UIControlStateSelected];
            {
                UIImageView *imageView = [RDYYAnimatedImageView new];
                imageView.frame = CGRectMake(0, 0, btn.frame.size.width, btn.frame.size.height);
                imageView.yy_imageURL = [NSURL URLWithString:[stickerListTypes[i] objectForKey:@"icon_unchecked"] ];
                [btn addSubview:imageView];
                [uncheckedBtnArray addObject:imageView];
                if( i == 0 )
                    imageView.hidden = YES;
                else
                    imageView.hidden = NO;
            }
            
            {
                UIImageView *imageView = [RDYYAnimatedImageView new];
                imageView.frame = CGRectMake(0, 0, btn.frame.size.width, btn.frame.size.height);
                imageView.yy_imageURL = [NSURL URLWithString:[stickerListTypes[i] objectForKey:@"icon_checked"] ];
                [btn addSubview:imageView];
                [checkedBtnArray addObject:imageView];
                if( i != 0 )
                    imageView.hidden = YES;
                else
                    imageView.hidden = NO;
            }
            
            
            [btn setTitleColor:Main_Color forState:UIControlStateSelected];
            btn.titleLabel.font = [UIFont systemFontOfSize:12];
            
            [btn addTarget:self action:@selector(stickerLabel_Btn:) forControlEvents:UIControlEventTouchUpInside];
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((width-5)/2.0, _stickerLabelScrollView.frame.size.height - 2, 5, 2)];
            imageView.backgroundColor = Main_Color;
            [btn addSubview:imageView];
            
            imageView.hidden = YES;
            
            if( i == 0 )
            {
                btn.selected = true;
                imageView.hidden = NO;
            }
            [stickersImageViewArray addObject:imageView];
            [stickersLabelBtnArray addObject:btn];
            [_stickerLabelScrollView addSubview:btn];
        }
        width = (width+5)*stickerListTypes.count;
        if( width <= _stickerLabelScrollView.frame.size.width )
            width = _stickerLabelScrollView.frame.size.width+1;
        _stickerLabelScrollView.contentSize = CGSizeMake(width, 0);
        
        [_stickerView addSubview:self.stickerListScrollView];
        
//        [self performSelector:@selector(initStickerListScrollView) withObject:nil afterDelay:0.05];
        
    }
    return _stickerLabelScrollView;
}

-(void)initStickerListScrollView
{
    [self stickListScrollView:0];
}

-(void)stickerLabel_Btn:(UIButton *) btn
{
    if( btn != nil )
    {
        [self stickListScrollView:btn.tag];
        [self touchescaptionTypeViewChild:(UIButton *)[stickersScrollArray[currentSelectLabelIndex] viewWithTag:kCAPTIONTYPEVIEWCHILDTAG+[stickersIndexArray[currentSelectLabelIndex] intValue]]];
        stickersScrollArray[currentSelectLabelIndex].contentOffset = CGPointZero;
    }
    else
    {
        btn = (UIButton *)[_stickerLabelScrollView viewWithTag:currentSelectLabelIndex];
    }
    
    [_stickerLabelScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass:[UIButton class]] )
        {
            ( (UIButton*)obj ).selected = NO;
            stickersImageViewArray[( (UIButton*)obj ).tag].hidden = YES;
            uncheckedBtnArray[( (UIButton*)obj ).tag].hidden = NO;
            checkedBtnArray[( (UIButton*)obj ).tag].hidden = YES;
        }
    }];
    
    btn.selected = YES;
    stickersImageViewArray[btn.tag].hidden = NO;
    stickersScrollArray[btn.tag].delegate = self;
    uncheckedBtnArray[btn.tag].hidden = YES;
    checkedBtnArray[btn.tag].hidden = NO;
    
//    _stickerListScrollView.contentOffset = CGPointMake( [stickersListIndexArray[btn.tag] floatValue] - 15.0, 0);
}

-(UIScrollView *)stickerListScrollView
{
    if( !_stickerListScrollView )
    {
        _stickerListScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _stickerLabelScrollView.frame.origin.y+_stickerLabelScrollView.frame.size.height, _stickerLabelScrollView.frame.size.width, _bottomView.frame.size.height -  _stickerLabelScrollView.frame.size.height - _stickerLabelScrollView.frame.origin.y)];
        _stickerListScrollView.delegate = self;
        _stickerLabelScrollView.tag = 10000;
        _stickerListScrollView.tag  = 10001;
        stickersListIndexArray = [NSMutableArray new];
        stickersIndexArray = [NSMutableArray new];
        stickersScrollArray = [NSMutableArray new];
        NSFileManager *manager = [[NSFileManager alloc] init];
        
        __block float width = ( _stickerListScrollView.frame.size.width )/5.0;
        width = (_stickerListScrollView.frame.size.width + width/2.0)/5.0;
        __block float contentWidth = 15;
        NSMutableArray<NSDictionary *> *oldModleTypes = [NSMutableArray new];
        [stickersListArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableArray * array = (NSMutableArray*)obj;
            [stickersListIndexArray addObject:[ NSNumber numberWithFloat:contentWidth ]];
            
            [stickersIndexArray addObject:[NSNumber numberWithInt:oldModleTypes.count]];
            
            [stickersScrollArray addObject:[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _stickerListScrollView.frame.size.width, _stickerListScrollView.frame.size.height)]];
            stickersScrollArray[stickersScrollArray.count - 1].tag = 1000;
            
            
            [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [oldModleTypes addObject:obj];
            }];
            if( idx == (stickersListArray.count-1) )
            {
                modleTypes = [NSArray arrayWithArray:oldModleTypes];
                _stickerListScrollView.contentSize = CGSizeMake(contentWidth, 0);
            }
        }];
        _stickerListScrollView.showsVerticalScrollIndicator = NO;
        _stickerListScrollView.showsHorizontalScrollIndicator = NO;
        
        
        currentSelectLabelIndex = 0;
        _stickerListScrollView.backgroundColor = TOOLBAR_COLOR;
        _stickerListScrollView.contentSize = CGSizeMake(_stickerListScrollView.frame.size.width, 0);
    }
    return _stickerListScrollView;
}

-(void)stickListScrollView:(int) index
{
    __block float width = ( _stickerListScrollView.frame.size.width )/5.0;
    width = (_stickerListScrollView.frame.size.width + width/2.0)/5.0;
    if( stickersScrollArray[index].subviews.count == 0  )
    {
        NSFileManager *manager = [[NSFileManager alloc] init];
        NSMutableArray * array = (NSMutableArray*)stickersListArray[index];
        
        __block float contentWidth = 15;
        
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary * objDic = (NSDictionary*)obj;
            
            BOOL hasNew = [[objDic allKeys] containsObject:@"cover"] ? YES : NO;
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.backgroundColor = [UIColor clearColor];
            
            
            btn.tag = kCAPTIONTYPEVIEWCHILDTAG + idx + [stickersIndexArray[index] intValue];
            [btn addTarget:self action:@selector(touchescaptionTypeViewChild:) forControlEvents:UIControlEventTouchUpInside];
            
            [btn setFrame:CGRectMake(contentWidth, (_stickerListScrollView.frame.size.height-(width - 30))/2.0, width - 30, width - 30)];
            
            NSString *fileName =  objDic[@"name"];
            NSString *iconPath = nil;
            NSString *path = nil;
            if(self.type == 1){
                iconPath = [NSString stringWithFormat:@"%@/%@",kStickerIconPath,fileName];
                path = [NSString stringWithFormat:@"%@/%@/config.json",[NSString stringWithFormat:@"%@%@",kStickerFolder,hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""],fileName];
            }else{
                if(hasNew){
                    fileName = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@%@",kSubtitleFolder,hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""] error:nil] lastObject];
                }
                iconPath = [NSString stringWithFormat:@"%@/%@",kSubtitleIconPath,fileName];
                path = [NSString stringWithFormat:@"%@/%@/config.json",[NSString stringWithFormat:@"%@%@",kSubtitleFolder,hasNew ? [NSString stringWithFormat:@"/%@",[[obj[@"file"] stringByDeletingLastPathComponent] lastPathComponent]] : @""],fileName];
            }
            BOOL check = YES;//emmet 屏蔽更新字幕
            if(hasNew){
                UIImageView *imageView = [RDYYAnimatedImageView new];
                imageView.frame = CGRectMake(0, 0, btn.frame.size.width, btn.frame.size.height);
                imageView.yy_imageURL = [NSURL URLWithString:obj[@"cover"]];
                [btn addSubview:imageView];
                //                    [btn rd_sd_setImageWithURL:[NSURL URLWithString:obj[@"cover"]] forState:UIControlStateNormal];
            }else{
                [btn setImage:[UIImage imageWithContentsOfFile:iconPath] forState:UIControlStateNormal];
            }
            if(![manager fileExistsAtPath:path] || !check){
                NSError *error;
                if([manager fileExistsAtPath:path]){
                    [manager removeItemAtPath:path error:&error];
                    NSLog(@"manager_error:%@",error);
                }
                UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
                UIImageView *accessoryView = [[UIImageView alloc] initWithImage:accessory];
                accessoryView.tag = 1;
                accessoryView.image = nil;
                accessoryView.frame = CGRectMake(btn.frame.size.width-accessory.size.width, btn.frame.size.height - accessory.size.height, accessory.size.width, accessory.size.height);
                [btn addSubview:accessoryView];
            }
            [stickersScrollArray[index] addSubview:btn];
            contentWidth += width;
        }];
        
        stickersScrollArray[index].contentSize = CGSizeMake(contentWidth, 0);
        stickersScrollArray[index].showsVerticalScrollIndicator = NO;
        stickersScrollArray[index].showsHorizontalScrollIndicator = NO;
        [_stickerListScrollView addSubview:stickersScrollArray[index]];
    }
    
    [stickersScrollArray enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if( obj != nil )
            obj.hidden = YES;
        
    }];
    currentSelectLabelIndex = index;
    stickersScrollArray[index].hidden = NO;
    stickersScrollArray[index].delegate = self;
    
    if( _selectTypeView )
       [_selectTypeView removeFromSuperview];
    _selectTypeView = nil;
        
    _selectTypeView = [[UIImageView alloc] init];
    _selectTypeView.backgroundColor = [UIColor clearColor];
    _selectTypeView.frame = CGRectMake(0+5, 5+5, width+4 - 10 , width+4 - 10);
    _selectTypeView.layer.cornerRadius = 5;
    _selectTypeView.layer.borderColor = ((UIColor*)Main_Color).CGColor;
    _selectTypeView.layer.borderWidth = 1.0;
    _selectTypeView.layer.masksToBounds = YES;
    _selectTypeView.center = ([(UIButton *)stickersScrollArray[index] viewWithTag:kCAPTIONTYPEVIEWCHILDTAG+[stickersIndexArray[index] intValue]]).center;
    
    [stickersScrollArray[index] addSubview:_selectTypeView];
}

@end
