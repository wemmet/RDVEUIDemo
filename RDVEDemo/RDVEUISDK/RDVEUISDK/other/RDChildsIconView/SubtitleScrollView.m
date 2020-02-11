//
//  SubtitleScrollView.m
//  RDVEUISDK
//
//  Created by emmet on 2017/11/20.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//
//
#import "SubtitleScrollView.h"
#import "RDSVProgressHUD.h"
#import "RDZSlider.h"
#import "UIButton+RDWebCache.h"
#import "UIImageView+RDWebCache.h"
#import "RDNavigationViewController.h"
#import "RDColorControlView.h"
#import "RDSubtitleCollectionViewCell.h"

#define kFONTCHILDTAG 200000
#define kFontTitleImageViewTag 100000

@interface SubtitleScrollView()<UITextViewDelegate,RDColorControlViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource>
{
    BOOL       isDowning;
    
    NSString   *oldText;
   
    UIColor    *oldFontColor;        //旧 字幕颜色
    UIColor    *oldBorderColor;      //旧 字幕边框颜色
    int         topHeight;
    int         toolBarHeight;
    int         toolItemsViewWidth;
    int         toolItemsSpanWidth;
    int         toolCount;
    float       subtitleDefaultSize;
    float       maxBorderWidth;
    float       maxShadowWidth;
    UIScrollView    *categoryScrollView;
    NSInteger        selectedCategoryIndex;
    UIScrollView    *animationScrollView;
    UIButton        *inAnimationBtn;
    UIButton        *outAnimationBtn;
    UIView          *selectedFontView;
    UIButton        *noneColorBtn;
    UIScrollView    *presetColorScrollView;
    UILabel         *alphaLbl;
    NSInteger        selectedContentType;
    UICollectionViewCell *firstSelectedCell;
}
@property (nonatomic,assign)BOOL isVerticalText;
@property (nonatomic,strong)NSMutableArray<NSDictionary *> *subtitleTypes;
@property (nonatomic,strong)NSMutableArray<UIColor *> *colors;
@property (nonatomic,strong)NSMutableArray<UIColor *> *borderColors;
@property (nonatomic,strong)NSMutableArray<NSDictionary *> *fonts;
@property (nonatomic,strong)NSDictionary *fontIcons;
@property (nonatomic,strong)UIButton     *selectOldSender;

@property (nonatomic,strong)UIView       *typeView;
@property (nonatomic,strong)UIScrollView *typeScrollView;
@property (nonatomic,strong)UIView       *subtitleAnimationView;
@property (nonatomic,strong)UIView       *subtitleColorView;
@property (nonatomic,strong)RDColorControlView *subtitleColorControl;
@property (nonatomic,strong)UIButton     *cancelFontColorBtn;
@property (nonatomic,strong)RDZSlider    *alphaSlider;
@property (nonatomic,strong)UIView       *subtitleFontTypeView;
@property (nonatomic,strong)UIScrollView *subtitleFontTypeScrollView;
@property (nonatomic,strong)UIView       *subtitlePositionView;
@property (nonatomic,assign)NSInteger     selectAnimationItemIndex;

@end

@implementation SubtitleScrollView
-(void) saveTextFieldTxt
{
//    oldText = _contentTextField.text;
    oldText = _textView.text;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = UIColorFromRGB(0x27262c);
        _selectColorItemIndex = -1;
        _selectBorderColorItemIndex = -1;
        _selectShadowColorIndex = -1;
        _selectBgColorIndex = -1;
        _selectFontItemIndex = 0;
        _subtitleSize = 0;
        _isModifyText = false;
        topHeight = 48;
        toolBarHeight = 47;
        toolItemsViewWidth = 55;
        toolItemsSpanWidth = 5;
        toolCount = 5;
        subtitleDefaultSize = 22;
        maxBorderWidth = 26;
        maxShadowWidth = 5;
        _subtitleAlpha = 1.0;
    }
    return self;
}

- (void)showInView{
    [self addSubview:self.topView];
    [self addSubview:self.toolBarView];
    [self addSubview:self.bottomView];
}

- (void)setHidden:(BOOL)hidden{
    [super setHidden:hidden];
    if(hidden){
        _isModifyText = false;
    }
}

- (void)setSubtitleSize:(float)value{
//    _subtitleSizeSlider.value = value;
//    float progress = ((_subtitleSizeSlider.value - _subtitleSizeSlider.minimumValue ) /(_subtitleSizeSlider.maximumValue - _subtitleSizeSlider.minimumValue));
//
//    _subtitleSizePopView.frame = CGRectMake(progress * (_subtitleSizeSlider.frame.size.width - 20) + _subtitleSizeSlider.frame.origin.x-10, _subtitleSizeView.frame.size.height/2.0 - 30, 40, 30);
//
//
//    float size = subtitleDefaultSize + _subtitleSizeSlider.value * 8.0;
//    _subtitleSizePopView.text = [NSString stringWithFormat:@"%.f",size];
//    if([_delegate respondsToSelector:@selector(changeSize:subtitleScrollView:)]){
//        [_delegate changeSize:value subtitleScrollView:self];
//    }
}

- (NSMutableArray<NSDictionary *> *)subtitleTypes{
    if(!_subtitleTypes){
        _subtitleTypes = [NSMutableArray arrayWithContentsOfFile:kSubtitlePlistPath];
    }
    return _subtitleTypes;
}

#pragma mark- 多行文本
-(UIView *)contentTextView
{
    if(!_contentTextView){
        _contentTextView = [UIView new];
        _contentTextView.frame = CGRectMake(6+topHeight, (topHeight - 36)/2.0, _topView.frame.size.width - 6 - 13*2 - 54 - topHeight, 36);
        _contentTextView.layer.borderColor    = [UIColor clearColor].CGColor;
        _contentTextView.layer.borderWidth    = 1;
        _contentTextView.layer.cornerRadius   = 3;
        _contentTextView.layer.masksToBounds  = YES;
        _contentTextView.backgroundColor      = UIColorFromRGB(0x3c3b43);
        
        _textView = [UITextView new];
        _textView.frame = CGRectMake(0, 0,_contentTextView.frame.size.width - 26, 36);
//        _textView.b
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        clearButton.backgroundColor = [UIColor clearColor];
        [clearButton setImage:[RDHelpClass imageWithContentOfFile:@"/next_jianji/剪辑-字幕删除输入内容默认_"] forState:UIControlStateNormal];
        [clearButton setImage:[RDHelpClass imageWithContentOfFile:@"/next_jianji/剪辑-字幕删除输入内容点击_"] forState:UIControlStateHighlighted];
        [clearButton setFrame:CGRectMake(_contentTextView.frame.size.width - 26, 5, 26, 26)];
        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
        [_contentTextView addSubview:clearButton];
        _textView.textAlignment = NSTextAlignmentLeft;
//        [_textView setRightView:clearButton];
        
        _textView.layer.borderColor    = [UIColor clearColor].CGColor;
        _textView.layer.borderWidth    = 1;
        _textView.layer.cornerRadius   = 0;
        _textView.layer.masksToBounds  = YES;
        _textView.textColor            = UIColorFromRGB(0xffffff);
        _textView.backgroundColor      = UIColorFromRGB(0x3c3b43);
//        _textView.returnKeyType        = UIReturnKeyDone;
        _textView.delegate             = self;
        NSMutableAttributedString* attrstr = [[NSMutableAttributedString alloc] initWithString:RDLocalizedString(@"点击输入字幕", nil)];
        [attrstr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x888888) range:NSMakeRange(0, attrstr.length)];
        _textView.delegate = self;
        _textView.attributedText = attrstr;
        [_contentTextView addSubview:_textView];
    }
    return _contentTextView;
}

- (void)setIsVerticalText:(BOOL)isVerticalText {
    _isVerticalText = isVerticalText;
    if (isVerticalText) {
        _textView.returnKeyType = UIReturnKeyDone;
    }else {
        _textView.returnKeyType = UIReturnKeyDefault;
    }
}

#pragma mark- 编辑文字
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (_isVerticalText && [text isEqualToString:@"\n"]){
        if([_delegate respondsToSelector:@selector(changeSubtitleContentString:subtitleScrollView:)]){
            [_delegate changeSubtitleContentString:textView.text subtitleScrollView:self];
        }
        [self ok_Btn];
        //禁止输入换行
        return NO;
    }
    return YES;
}
- (void)textViewDidChange:(UITextView *)textView
{
  if (textView.markedTextRange == nil) {
      NSString * str  = [NSString stringWithFormat:@"%@",textView.text];
      _isModifyText = true;
      if([_delegate respondsToSelector:@selector(changeSubtitleContentString:subtitleScrollView:)]){
          [_delegate changeSubtitleContentString:str subtitleScrollView:self];
      }
  }
}

#pragma mark- 单行文本
//- (UITextField *)contentTextField{
//    if(!_contentTextField){
//        _contentTextField = [UITextField new];
//        _contentTextField.frame = CGRectMake(6+topHeight, (topHeight - 36)/2.0, _topView.frame.size.width - 6 - 13*2 - 54 - topHeight, 36);
//
//        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        clearButton.backgroundColor = [UIColor clearColor];
//        [clearButton setImage:[RDHelpClass imageWithContentOfFile:@"/next_jianji/剪辑-字幕删除输入内容默认_"] forState:UIControlStateNormal];
//        [clearButton setImage:[RDHelpClass imageWithContentOfFile:@"/next_jianji/剪辑-字幕删除输入内容点击_"] forState:UIControlStateHighlighted];
//        [clearButton setFrame:CGRectMake(0, 0, 26, 26)];
//        [clearButton addTarget:self action:@selector(clearTextField:) forControlEvents:UIControlEventTouchUpInside];
//        _contentTextField.rightViewMode = UITextFieldViewModeAlways;
//        [_contentTextField setRightView:clearButton];
//
//        _contentTextField.layer.borderColor    = [UIColor clearColor].CGColor;
//        _contentTextField.layer.borderWidth    = 1;
//        _contentTextField.layer.cornerRadius   = 3;
//        _contentTextField.layer.masksToBounds  = YES;
//        _contentTextField.textColor            = UIColorFromRGB(0xffffff);
//        _contentTextField.backgroundColor      = UIColorFromRGB(0x3c3b43);
//        _contentTextField.returnKeyType        = UIReturnKeyDone;
//        _contentTextField.delegate             = self;
//        NSMutableAttributedString* attrstr = [[NSMutableAttributedString alloc] initWithString:RDLocalizedString(@"点击输入字幕", nil)];
//        [attrstr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x888888) range:NSMakeRange(0, attrstr.length)];
//        _contentTextField.attributedPlaceholder = attrstr;
//        [_contentTextField addTarget:self action:@selector(contentTextFieldValueChange:) forControlEvents:UIControlEventEditingChanged];
//
//    }
//    return _contentTextField;
//}

- (UIButton *)okBtn{
    if(!_okBtn){
        _okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _okBtn.frame = CGRectMake(self.frame.size.width - 54 - 13 , (self.topView.frame.size.height - 28)/2.0, 54, 28);
        [_okBtn addTarget:self action:@selector(ok_Btn) forControlEvents:UIControlEventTouchUpInside];
        _okBtn.layer.cornerRadius = 28/2;
        _okBtn.layer.masksToBounds = YES;
        _okBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _okBtn.backgroundColor = Main_Color;
        [_okBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateNormal];
        [_okBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateHighlighted];
        //[_okBtn setTitle:RDLocalizedString(_isEditting ? @"完成" : @"添加", nil) forState:UIControlStateNormal];
        //[_okBtn setTitle:RDLocalizedString(_isEditting ? @"完成" : @"添加", nil) forState:UIControlStateHighlighted];
        [_okBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateNormal];
        [_okBtn setTitleColor:UIColorFromRGB(0x27262c) forState:UIControlStateHighlighted];
    }
    return _okBtn;
}

- (UIView *)topView{
    if(!_topView){
        _topView = [UIView new];
        _topView.frame = CGRectMake(0, 0, self.frame.size.width, topHeight);
        _topView.backgroundColor = [UIColor clearColor];
        
        
//        UIView *topLineView = [UIView new];
//        topLineView.frame = CGRectMake(0, topHeight-1, _topView.frame.size.width, 1);
//        topLineView.backgroundColor = UIColorFromRGB(0xffffff);
//        [_topView addSubview:topLineView];
//        [_topView addSubview:self.contentTextField];
        [_topView addSubview:self.contentTextView];
        [_topView addSubview:self.okBtn];
        
        UIButton * closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(6, (self.topView.frame.size.height - topHeight)/2.0, topHeight, topHeight);
        [closeBtn addTarget:self action:@selector(Close_Btn) forControlEvents:UIControlEventTouchUpInside];
        [closeBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_topView addSubview:closeBtn];
        _topView.hidden = YES;
        
    }
    return _topView;
}

- (UIScrollView *)toolBarView{
    if(!_toolBarView){
        _toolBarView = [UIScrollView new];
        _toolBarView.frame = CGRectMake(0, self.frame.size.height - (kToolbarHeight - (LastIphone5?0:14)), self.frame.size.width, (kToolbarHeight - (LastIphone5?0:14)));
        _toolBarView.backgroundColor = TOOLBAR_COLOR;
        _toolBarView.showsHorizontalScrollIndicator = NO;
        _toolBarView.showsVerticalScrollIndicator = NO;
        
        float height = LastIphone5 ? 44 : (kToolbarHeight - 14);
        
        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake((LastIphone5?0:7), 0, height, height)];
        [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(TextClose) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:cancelBtn];
        
        UIButton *finishBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - height - (LastIphone5?0:7), 0, height, height)];
        [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
        [_toolBarView addSubview:finishBtn];
        
        UIScrollView *toolItemsView = [UIScrollView new];
        toolItemsView.frame = CGRectMake(44 ,0, _toolBarView.frame.size.width - 44*2.0, height);
        toolItemsView.backgroundColor = [UIColor clearColor];
        toolItemsView.showsHorizontalScrollIndicator = NO;
        toolItemsView.showsVerticalScrollIndicator = NO;
        toolItemsView.contentSize = CGSizeMake(toolItemsView.frame.size.width, 0);
        toolItemsView.tag = 10000;
        [_toolBarView addSubview:toolItemsView];
        
        float fheight = toolItemsView.frame.size.width/toolCount;
        for (int i = 0; i<toolCount; i++) {
            UIButton *item = [UIButton new];
            [item setFrame:CGRectMake((fheight) * i,  (toolItemsView.frame.size.height-fheight-15)/2.0  , fheight, fheight+15)];
            [item setBackgroundColor:[UIColor clearColor]];
            [item setTag:i];
            [item setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_%02i_n_",i]] forState:UIControlStateNormal];
            [item setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_%02i_s_",i]] forState:UIControlStateSelected];
            [item addTarget:self action:@selector(clickToolItem:) forControlEvents:UIControlEventTouchUpInside];
            [toolItemsView addSubview:item];
        }
    }
    return _toolBarView;
}


- (UIScrollView *)bottomView{
    if(!_bottomView){
        _bottomView = [UIScrollView new];
        _bottomView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - kToolbarHeight + (LastIphone5?0:14));
        _bottomView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _bottomView.showsHorizontalScrollIndicator = NO;
        _bottomView.showsVerticalScrollIndicator = NO;
        _bottomView.pagingEnabled = YES;
        _bottomView.scrollEnabled = NO;
        _bottomView.contentSize = CGSizeMake(_bottomView.frame.size.width * toolCount, _bottomView.frame.size.height);
        
        for (int i = 0; i<toolCount; i++) {
            UIView *item = [UIView new];
            [item setFrame:CGRectMake(_bottomView.frame.size.width * i, 0, _bottomView.frame.size.width, _bottomView.frame.size.height)];
            [item setTag:i];
            switch (i) {
                case 0://样式
                {
                    [item addSubview:self.typeView];
                }
                    break;
                case 1://动画
                {
                    [item addSubview:self.subtitleAnimationView];
                }
                    break;
                case 2://字幕颜色
                {
                    [item addSubview:self.subtitleColorView];
                }
                    break;
                case 3://字体
                {
                    [item addSubview:self.subtitleFontTypeView];
                }
                    break;
                case 4://位置
                {
                    [item addSubview:self.subtitlePositionView];
                }
                    break;
                default:
                {
                    
                }
                    break;
            }
            [_bottomView addSubview:item];
        }
    }
    return _bottomView;
}

#pragma mark - 字幕样式
- (UIView *)typeView {
    if (!_typeView) {
        _typeView = [[UIView alloc] initWithFrame:_bottomView.bounds];
        categoryScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(15, 0, _typeView.frame.size.width - 30, 48)];
        categoryScrollView.showsVerticalScrollIndicator = NO;
        categoryScrollView.showsHorizontalScrollIndicator = NO;
        [_typeView addSubview:categoryScrollView];
        [_typeView addSubview:self.typeScrollView];
    }
    return _typeView;
}

- (UIScrollView *)typeScrollView{
    if(!_typeScrollView){
        _typeScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, categoryScrollView.frame.size.height, _bottomView.frame.size.width, _bottomView.frame.size.height - categoryScrollView.frame.size.height)];
        _typeScrollView.backgroundColor = [UIColor clearColor];
        _typeScrollView.showsHorizontalScrollIndicator = NO;
        _typeScrollView.showsVerticalScrollIndicator = NO;
        _typeScrollView.scrollEnabled = NO;
        _typeScrollView.contentSize = CGSizeMake(self.subtitleTypes.count * _bottomView.frame.size.width, 0);
        
        float width = _bottomView.frame.size.height*0.4;
        [_subtitleTypes enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            itemBtn.frame = CGRectMake(5 + (5 + categoryScrollView.frame.size.height)*idx, 0, categoryScrollView.frame.size.height, categoryScrollView.frame.size.height);
            [itemBtn rd_sd_setImageWithURL:[NSURL URLWithString:obj[@"icon_unchecked"]] forState:UIControlStateNormal];
            [itemBtn rd_sd_setImageWithURL:[NSURL URLWithString:obj[@"icon_checked"]] forState:UIControlStateSelected];
            [itemBtn setTitle:obj[@"typeName"] forState:UIControlStateNormal];
            [itemBtn setTitleColor:UIColorFromRGB(0x8888888) forState:UIControlStateNormal];
            [itemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            itemBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
            itemBtn.tag = idx + 1;
            [itemBtn addTarget:self action:@selector(catogeryBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [categoryScrollView addSubview:itemBtn];
            
            UICollectionViewFlowLayout * flow = [[UICollectionViewFlowLayout alloc] init];
            flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            flow.itemSize = CGSizeMake(width, width);
            flow.sectionInset = UIEdgeInsetsMake(0.0, 15.0, 0.0, 0.0);
            
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame: CGRectMake(_typeScrollView.bounds.size.width*idx, (_typeScrollView.frame.size.height - width)/2.0, _typeScrollView.bounds.size.width, width) collectionViewLayout: flow];
            collectionView.tag = idx + 1;
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.alwaysBounceVertical = NO;
            collectionView.alwaysBounceHorizontal = YES;
            collectionView.showsVerticalScrollIndicator = NO;
            collectionView.showsHorizontalScrollIndicator = NO;
            [collectionView registerClass:[RDSubtitleCollectionViewCell class] forCellWithReuseIdentifier:@"typeCell"];
            collectionView.contentSize = CGSizeMake((15 + width)*[obj[@"data"] count], 0);
            [_typeScrollView addSubview:collectionView];
        }];
        categoryScrollView.contentSize = CGSizeMake(5 + (5 + categoryScrollView.frame.size.height)*_subtitleTypes.count, 0);
    }
    return _typeScrollView;
}

#pragma mark - 字幕动画
- (UIView *)subtitleAnimationView{
    if(!_subtitleAnimationView){
        _subtitleAnimationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height)];
        _subtitleAnimationView.backgroundColor = [UIColor clearColor];

        for (int i = 0; i < 2; i++) {
            UIButton *animationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            if (i == 0) {
                inAnimationBtn = animationBtn;
                animationBtn.frame = CGRectMake(_subtitleAnimationView.frame.size.width - 55*2 - 2, 0, 55, 48);
                [animationBtn setTitle:RDLocalizedString(@"入场", nil) forState:UIControlStateNormal];
                animationBtn.selected = YES;
            }else {
                outAnimationBtn = animationBtn;
                animationBtn.frame = CGRectMake(_subtitleAnimationView.frame.size.width - 55 - 2, 0, 55, 48);
                [animationBtn setTitle:RDLocalizedString(@"出场", nil) forState:UIControlStateNormal];
            }
            [animationBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
            [animationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            animationBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
            animationBtn.tag = i + 1;
            [animationBtn addTarget:self action:@selector(animationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_subtitleAnimationView addSubview:animationBtn];
            
            UIView *setAnimationView = [[UIView alloc] initWithFrame:CGRectMake((55 - 4)/2.0, (48 + 12)/2.0 + 6, 4, 4)];
            setAnimationView.backgroundColor = [UIColor whiteColor];
            setAnimationView.layer.cornerRadius = 2.0;
            setAnimationView.layer.masksToBounds = YES;
            setAnimationView.tag = 66;
            if (i == 0) {
                setAnimationView.hidden = (_inAnimationIndex == 0);
            }else {
                setAnimationView.hidden = (_outAnimationIndex == 0);
            }
            [animationBtn addSubview:setAnimationView];
        }
        
        UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake(_subtitleAnimationView.frame.size.width - 55 - 2, (48 - 12)/2.0, 2, 12)];
        spanView.backgroundColor = UIColorFromRGB(0x888888);
        [_subtitleAnimationView addSubview:spanView];
        
        animationScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 48, _subtitleAnimationView.frame.size.width, _subtitleAnimationView.frame.size.height - 48)];
        animationScrollView.showsHorizontalScrollIndicator = NO;
        animationScrollView.showsVerticalScrollIndicator = NO;
        [_subtitleAnimationView addSubview:animationScrollView];
        
        NSArray *animationArray = [NSArray arrayWithObjects:@"无", @"左推", @"右推", @"上推", @"下推", @"放大", @"滚动", @"淡入", nil];
        float width = 44;
        float height = 70;
        for (int i = 0; i < animationArray.count; i++) {
            NSString *title = animationArray[i];
            UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
            [item setFrame:CGRectMake(12 + (12 + width)*i, (animationScrollView.frame.size.height - height)/2.0, width, height)];
            [item setBackgroundColor:[UIColor clearColor]];
            [item setTag:i + 1];
            [item setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
            [item setTitle:RDLocalizedString(title, nil) forState:UIControlStateSelected];
            [item setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
            [item setTitleColor:Main_Color forState:UIControlStateSelected];
            [item.titleLabel setFont:[UIFont systemFontOfSize:14]];
            [item setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_动画_%@_", title]] forState:UIControlStateNormal];
            [item setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_动画_%@_", title]] forState:UIControlStateSelected];
            [item setImageEdgeInsets:UIEdgeInsetsMake(-(height - width), 0, 0, 0)];
            [item setTitleEdgeInsets:UIEdgeInsetsMake(44, -44, 0, 0)];
            [item addTarget:self action:@selector(animationTypeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [animationScrollView addSubview:item];
            if(i== _inAnimationIndex)
                [item setSelected:YES];
        }
        [animationScrollView setContentSize:CGSizeMake(12 + (12 + width) * animationArray.count, 0)];
        
    }
    return _subtitleAnimationView;
}

#pragma mark - 字幕颜色
- (UIView *)subtitleColorView{
    if(!_subtitleColorView){
        _subtitleColorView = [UIView new];
        _subtitleColorView.backgroundColor = [UIColor clearColor];
        _subtitleColorView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        
        NSArray *colorTypeArray = [NSArray arrayWithObjects:@"文本", @"描边", @"阴影", @"标签", @"透明度", nil];
        float x = 10 + 15;
        for (int i = 0; i < colorTypeArray.count; i++) {
            UIButton *contentTypeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            contentTypeBtn.backgroundColor = nil;
            [contentTypeBtn setTitle:RDLocalizedString(colorTypeArray[i], nil) forState:UIControlStateNormal];
            [contentTypeBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
            [contentTypeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            contentTypeBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
            float width = [contentTypeBtn sizeThatFits:CGSizeZero].width + 10;
            contentTypeBtn.frame = CGRectMake(x, 0, width, 38);
            x += width;
            if (i == 0) {
                contentTypeBtn.selected = YES;
            }
            contentTypeBtn.tag = i + 1;
            [contentTypeBtn addTarget:self action:@selector(contentTypeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_subtitleColorView addSubview:contentTypeBtn];
            
            UIView *setColorView = [[UIView alloc] initWithFrame:CGRectMake((width - 4)/2.0, (38 + 12)/2.0 + 6, 4, 4)];
            setColorView.backgroundColor = [UIColor whiteColor];
            setColorView.layer.cornerRadius = 2.0;
            setColorView.layer.masksToBounds = YES;
            setColorView.tag = 66;
            if (i == 0) {
                setColorView.hidden = (_selectColorItemIndex == -1);
            }else if (i == 1) {
                setColorView.hidden = (_selectBorderColorItemIndex == -1);
            }else if (i == 2) {
                setColorView.hidden = (_selectShadowColorIndex == -1);
            }else if (i == 3) {
                setColorView.hidden = (_selectBgColorIndex == -1);
            }else {
                setColorView.hidden = (_subtitleAlpha == 1.0);
            }
            [contentTypeBtn addSubview:setColorView];
        }
        
        float height = (_subtitleColorView.frame.size.height - 38)/2.0;
        noneColorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        noneColorBtn.frame = CGRectMake(20, 38 + height*0.4/2.0, height*0.6*0.65, height*0.6);
        [noneColorBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/Subtitles/剪辑-字幕_颜色_无_"] forState:UIControlStateNormal];
        [noneColorBtn addTarget:self action:@selector(noneColorBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_subtitleColorView addSubview:noneColorBtn];
        
        _subtitleColorControl = [[RDColorControlView alloc] initWithFrame:CGRectMake(57, noneColorBtn.frame.origin.y, _subtitleColorView.frame.size.width - 57, noneColorBtn.frame.size.height)];
        _subtitleColorControl.colorArray = self.colors;
        _subtitleColorControl.delegate = self;
        [_subtitleColorView addSubview:_subtitleColorControl];
        
        presetColorScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(15, 38 + height, _subtitleColorView.frame.size.width - 30, height)];
        presetColorScrollView.showsVerticalScrollIndicator = NO;
        presetColorScrollView.showsHorizontalScrollIndicator = NO;
        [_subtitleColorView addSubview:presetColorScrollView];
        
        for (int i = 0; i < 7; i++) {
            UIButton *presetTypeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            presetTypeBtn.frame = CGRectMake(25 + (25 + 26)*i, (height - 26)/2.0, 26, 26);
            if (i < 5) {
                [presetTypeBtn setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_预设效果_%02i_", i]] forState:UIControlStateNormal];
            }else if (i == 5) {
                presetTypeBtn.frame = CGRectMake(25 + (25 + 26)*i, (height - 26)/2.0, 50, 26);
                [presetTypeBtn setTitle:RDLocalizedString(@"加粗", nil) forState:UIControlStateNormal];
                [presetTypeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [presetTypeBtn setTitleColor:Main_Color forState:UIControlStateSelected];
                presetTypeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
                presetTypeBtn.selected = _isBold;
                
                UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake(presetTypeBtn.frame.origin.x + 50, presetTypeBtn.frame.origin.y, 1, 26)];
                spanView.backgroundColor = [UIColor whiteColor];
                [presetColorScrollView addSubview:spanView];
            }else {
                presetTypeBtn.frame = CGRectMake(25 + (25 + 26)*5 + 50, (height - 26)/2.0, 50, 26);
                [presetTypeBtn setTitle:RDLocalizedString(@"斜体", nil) forState:UIControlStateNormal];
                [presetTypeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [presetTypeBtn setTitleColor:Main_Color forState:UIControlStateSelected];
                presetTypeBtn.selected = _isItalic;
                
                CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
                UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:[UIFont systemFontOfSize:10].fontName matrix:matrix];
                presetTypeBtn.titleLabel.font = [UIFont fontWithDescriptor:desc size:17.0];
                
                presetColorScrollView.contentSize = CGSizeMake(presetTypeBtn.frame.origin.x + 50 + 25, 0);
            }
            presetTypeBtn.tag = i + 1;
            [presetTypeBtn addTarget:self action:@selector(presetTypeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [presetColorScrollView addSubview:presetTypeBtn];
        }
        
        alphaLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 38 + height + (height - 30)/2.0, 80, 30)];
        alphaLbl.backgroundColor = [UIColor clearColor];
        alphaLbl.textColor = [UIColor whiteColor];
        alphaLbl.textAlignment = NSTextAlignmentCenter;
        alphaLbl.font = [UIFont systemFontOfSize:10];
        alphaLbl.text = @"100%";
        alphaLbl.hidden = YES;
        [_subtitleColorView addSubview:alphaLbl];
        
        _alphaSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(80, alphaLbl.frame.origin.y, _subtitleColorView.frame.size.width - (80 + 33), 30)];
        _alphaSlider.minimumTrackTintColor = [UIColor whiteColor];
        _alphaSlider.maximumTrackTintColor = [UIColor grayColor];
        _alphaSlider.backgroundColor = [UIColor clearColor];
        [_alphaSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        _alphaSlider.minimumValue = 0;
        _alphaSlider.maximumValue = 1.0;
        [_alphaSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        _alphaSlider.hidden = YES;
        [_subtitleColorView addSubview:_alphaSlider];
    }
    return _subtitleColorView;
}

- (NSMutableArray *)colors{
    if(!_colors){
        _colors = [NSMutableArray array];
        [_colors addObject:UIColorFromRGB(0xffffff)];
        [_colors addObject:UIColorFromRGB(0xbfbfbf)];
        [_colors addObject:UIColorFromRGB(0x878787)];
        [_colors addObject:UIColorFromRGB(0x535353)];
        [_colors addObject:UIColorFromRGB(0x000000)];
        [_colors addObject:UIColorFromRGB(0xf8bfc7)];
        [_colors addObject:UIColorFromRGB(0xf1736d)];
        [_colors addObject:UIColorFromRGB(0xee3842)];
        [_colors addObject:UIColorFromRGB(0xed002b)];//预设效果_02
        [_colors addObject:UIColorFromRGB(0xa50816)];
        [_colors addObject:UIColorFromRGB(0xfad9a2)];
        [_colors addObject:UIColorFromRGB(0xf4c76c)];
        [_colors addObject:UIColorFromRGB(0xf17732)];
        [_colors addObject:UIColorFromRGB(0xed260b)];
        [_colors addObject:UIColorFromRGB(0xaf160d)];
        [_colors addObject:UIColorFromRGB(0xfdf9b8)];
        [_colors addObject:UIColorFromRGB(0xfeff7a)];
        [_colors addObject:UIColorFromRGB(0xfbe80d)];//预设效果_03
        [_colors addObject:UIColorFromRGB(0xf5af0a)];
        [_colors addObject:UIColorFromRGB(0xef5409)];
        [_colors addObject:UIColorFromRGB(0xf5aac4)];
        [_colors addObject:UIColorFromRGB(0xf1679a)];
        [_colors addObject:UIColorFromRGB(0xee246e)];
        [_colors addObject:UIColorFromRGB(0xed0045)];
        [_colors addObject:UIColorFromRGB(0x94004f)];
        [_colors addObject:UIColorFromRGB(0xd9aee1)];
        [_colors addObject:UIColorFromRGB(0xe261fa)];
        [_colors addObject:UIColorFromRGB(0xd40dfa)];
        [_colors addObject:UIColorFromRGB(0xb000f5)];
        [_colors addObject:UIColorFromRGB(0x4900a1)];
        [_colors addObject:UIColorFromRGB(0xc6b4e2)];
        [_colors addObject:UIColorFromRGB(0xa36bff)];
        [_colors addObject:UIColorFromRGB(0x723cff)];
        [_colors addObject:UIColorFromRGB(0x5000fe)];
        [_colors addObject:UIColorFromRGB(0x2e00a9)];
        [_colors addObject:UIColorFromRGB(0xaed6fa)];
        [_colors addObject:UIColorFromRGB(0x6f9eff)];
        [_colors addObject:UIColorFromRGB(0x3671ff)];
        [_colors addObject:UIColorFromRGB(0x2353fd)];
        [_colors addObject:UIColorFromRGB(0x162cbd)];
        [_colors addObject:UIColorFromRGB(0xa4e6ed)];
        [_colors addObject:UIColorFromRGB(0x76fffc)];
        [_colors addObject:UIColorFromRGB(0x51ffff)];
        [_colors addObject:UIColorFromRGB(0x47dfff)];
        [_colors addObject:UIColorFromRGB(0x1f6469)];
        [_colors addObject:UIColorFromRGB(0xa3d9a0)];
        [_colors addObject:UIColorFromRGB(0xa4d7d3)];
        [_colors addObject:UIColorFromRGB(0x9aff82)];
        [_colors addObject:UIColorFromRGB(0x59ffd0)];
        [_colors addObject:UIColorFromRGB(0x47e6a6)];//预设效果_04
        [_colors addObject:UIColorFromRGB(0x206750)];
        [_colors addObject:UIColorFromRGB(0xbce2bc)];
        [_colors addObject:UIColorFromRGB(0xacf5bc)];
        [_colors addObject:UIColorFromRGB(0x5cf19d)];//预设效果_04
        [_colors addObject:UIColorFromRGB(0x44e462)];
        [_colors addObject:UIColorFromRGB(0x247930)];
        [_colors addObject:UIColorFromRGB(0xecf3b6)];
        [_colors addObject:UIColorFromRGB(0xf1ff6e)];
        [_colors addObject:UIColorFromRGB(0xeaff33)];
        [_colors addObject:UIColorFromRGB(0xbcff0b)];
        [_colors addObject:UIColorFromRGB(0x5c7e04)];
        [_colors addObject:UIColorFromRGB(0xccbfbc)];
        [_colors addObject:UIColorFromRGB(0x8f746b)];
        [_colors addObject:UIColorFromRGB(0x654338)];
        [_colors addObject:UIColorFromRGB(0x4a302a)];
        [_colors addObject:UIColorFromRGB(0x2f1c1b)];
    }
    return _colors;
}

#pragma mark - 字体
- (NSMutableArray<NSDictionary *> *)fonts{
    if(!_fonts){
        _fonts = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
        __block BOOL hasMoren = NO;
        WeakSelf(self);
        [_fonts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj[@"code"] isEqualToString:@"morenziti"]){
                hasMoren = YES;
                [weakSelf.fonts replaceObjectAtIndex:idx withObject:[NSDictionary dictionaryWithObjectsAndKeys:RDLocalizedString(@"默认", nil),@"fontname",RDLocalizedString(@"默认", nil),@"name", nil]];
                *stop = YES;
            }
        }];
        if(!hasMoren){
            [_fonts insertObject:[NSDictionary dictionaryWithObjectsAndKeys:RDLocalizedString(@"默认", nil),@"fontname",RDLocalizedString(@"默认", nil),@"name", nil] atIndex:0];
        }
    }
    return _fonts;
}

- (NSDictionary*)fontIcons{
    if(!_fontIcons){
        _fontIcons = [NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath];
    }
    return _fontIcons;
}

- (UIView *)subtitleFontTypeView{
    if(!_subtitleFontTypeView){
        _subtitleFontTypeView = [UIView new];
        _subtitleFontTypeView.backgroundColor = [UIColor clearColor];
        _subtitleFontTypeView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        
        [_subtitleFontTypeView addSubview:self.subtitleFontTypeScrollView];
    }
    return _subtitleFontTypeView;
}
- (UIScrollView *)subtitleFontTypeScrollView{
   
    if(!_subtitleFontTypeScrollView){
        _subtitleFontTypeScrollView = [UIScrollView new];
        _subtitleFontTypeScrollView.backgroundColor = [UIColor clearColor];
        _subtitleFontTypeScrollView.showsHorizontalScrollIndicator = NO;
        _subtitleFontTypeScrollView.showsVerticalScrollIndicator = NO;
        _subtitleFontTypeScrollView.frame = CGRectMake(12, 5, _subtitleFontTypeView.frame.size.width - 24, _subtitleFontTypeView.frame.size.height - 10);
        
        NSFileManager *manager = [NSFileManager defaultManager];
        float spaceW = 7.0;
        float spaceH = 8.0;
        float width = (_subtitleFontTypeScrollView.frame.size.width - spaceW*4)/3.0;
        float height = (_subtitleFontTypeScrollView.frame.size.height - spaceH*4)/3.0;
        CGPoint  selectedFontViewOrigin = CGPointMake(spaceW, spaceH);
        for (int i = 0; i < self.fonts.count; i++) {
            int cellIdx = i%3;
            UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
            [item setFrame:CGRectMake(spaceW + (width + spaceW)*cellIdx, spaceH + (height + spaceH)*(i/3), width, height)];
            item.backgroundColor = UIColorFromRGB(0x333333);
            item.layer.cornerRadius = 4.0;
            item.layer.masksToBounds = YES;
            item.tag = i+kFONTCHILDTAG;
            [item addTarget:self action:@selector(clickSubtitleFontItem:) forControlEvents:UIControlEventTouchUpInside];
            [_subtitleFontTypeScrollView addSubview:item];
            if (i == _selectFontItemIndex) {
                selectedFontViewOrigin = item.frame.origin;
            }
            
            NSDictionary *itemDic = [_fonts objectAtIndex:i];
            if(i == 0){
                UILabel *label = [[UILabel alloc] initWithFrame:item.bounds];
                label.text = itemDic[@"name"];
                label.tag = 3;
                label.font = [UIFont boldSystemFontOfSize:14.0];
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = Main_Color;
                [item addSubview:label];
            }else{
                BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
                NSString *fileName = hasNew ? [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension] : itemDic[@"name"];
                UIImageView *imageV = [[UIImageView alloc] initWithFrame:item.bounds];
                imageV.contentMode = UIViewContentModeScaleAspectFit;
                imageV.backgroundColor = [UIColor clearColor];
                if(hasNew){
                    [imageV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,fileName];
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_1_%@_n_",fileName]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        imageV.image = image;
                    }
                }
                imageV.tag = kFontTitleImageViewTag;
                imageV.layer.masksToBounds = YES;
                [item addSubview:imageV];
                
                NSString *timeunix = [NSString stringWithFormat:@"%ld",[(hasNew ? itemDic[@"updatetime"] : itemDic[@"timeunix"]) integerValue]];
                NSString *configPath = kFontCheckPlistPath;
                NSMutableDictionary *configDic = [[NSMutableDictionary alloc] initWithContentsOfFile:configPath];
                BOOL check = [timeunix isEqualToString:[configDic objectForKey:fileName]] ? YES : NO;
                
                NSString *fontPath = [self pathForURL_font:fileName extStr:@"ttf" hasNew:hasNew];
                
                if(![manager fileExistsAtPath:fontPath] || !check){
                    NSError *error;
                    if([manager fileExistsAtPath:fontPath]){
                        [manager removeItemAtPath:fontPath error:&error];
                        NSLog(@"error:%@",error);
                    }
                }
                fileName = hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]] : itemDic[@"name"];
                
                BOOL suc = [self hasCachedFont:fileName extStr:@"ttf" hasNew:hasNew];
            
                float downloadW = height*0.45;;
                UIImageView *downloadIV = [[UIImageView alloc] initWithFrame:CGRectMake(item.frame.size.width - downloadW, 0, downloadW, downloadW)];
                downloadIV.backgroundColor = UIColorFromRGB(0x414141);
                downloadIV.image = [RDHelpClass imageWithContentOfFile:@"next_jianji/Subtitles/剪辑-字体下载_"];
                downloadIV.contentMode = UIViewContentModeCenter;
                downloadIV.tag = 40000;
                
                UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(downloadW, 0) radius:downloadW startAngle:0 endAngle:1.0 clockwise:NO];
                path.lineCapStyle  = kCGLineCapRound;
                path.lineJoinStyle = kCGLineCapRound;
                CAShapeLayer *maskLayer = [CAShapeLayer layer];
                maskLayer.frame = downloadIV.bounds;
                maskLayer.path = path.CGPath;
                downloadIV.layer.mask = maskLayer;
                
                downloadIV.hidden = !suc;
                [item addSubview:downloadIV];
            }
        }
        [_subtitleFontTypeScrollView setContentSize:CGSizeMake(0, spaceH + (height + spaceH)*ceilf(_fonts.count/3.0))];
        selectedFontView = [[UIView alloc] initWithFrame:CGRectMake(selectedFontViewOrigin.x, selectedFontViewOrigin.y, width, height)];
        selectedFontView.backgroundColor = [UIColor clearColor];
        selectedFontView.layer.borderColor = Main_Color.CGColor;
        selectedFontView.layer.borderWidth = 2.0;
        [_subtitleFontTypeScrollView addSubview:selectedFontView];
    }
    return _subtitleFontTypeScrollView;
}

//- (UIView *)subtitleSizeView{
//    if(!_subtitleSizeView){
//        _subtitleSizeView = [UIView new];
//        _subtitleSizeView.backgroundColor = [UIColor clearColor];
//        _subtitleSizeView.frame = CGRectMake(0, 27, self.bottomView.frame.size.width, self.bottomView.frame.size.height - 27);
////        CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height - (LASTIPHONE_5 ? 50 : 30));
//
//        UILabel * fontsizeMin = [UILabel new];
//        fontsizeMin.textColor = UIColorFromRGB(0x888888);
//        fontsizeMin.textAlignment = NSTextAlignmentRight;
//        fontsizeMin.font = [UIFont systemFontOfSize:13];
//        fontsizeMin.frame = CGRectMake(24, _subtitleSizeView.frame.size.height/2.0 + 10, 50, 30);
//        fontsizeMin.text = RDLocalizedString(@"小", nil);
//        fontsizeMin.backgroundColor = [UIColor clearColor];
//
//        UILabel * fontsizeMax = [UILabel new];
//        fontsizeMax.textColor = UIColorFromRGB(0x888888);
//        fontsizeMax.textAlignment = NSTextAlignmentLeft;
//        fontsizeMax.font = [UIFont systemFontOfSize:13];
//        fontsizeMax.frame = CGRectMake((_subtitleSizeView.frame.size.width - 40), _subtitleSizeView.frame.size.height/2.0 + 10, 40, 30);
//        fontsizeMax.text = RDLocalizedString(@"大", nil);
//        fontsizeMax.backgroundColor = [UIColor clearColor];
//
//        [_subtitleSizeView addSubview:fontsizeMin];
//        [_subtitleSizeView addSubview:fontsizeMax];
//
//
//        _subtitleSizeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(44 + 30, _subtitleSizeView.frame.size.height/2.0 + 10, _subtitleSizeView.frame.size.width - (74 + 50), 30)];
//        [_subtitleSizeSlider setMaximumValue:4.0];
//        [_subtitleSizeSlider setMinimumValue:-1.0];
//        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
//        [_subtitleSizeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
//        _subtitleSizeSlider.layer.cornerRadius = 2.0;
//        _subtitleSizeSlider.layer.masksToBounds = YES;
//        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
//        [_subtitleSizeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
//
//        [_subtitleSizeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
//        [_subtitleSizeSlider setValue:0];
//
//        _subtitleSizeSlider.backgroundColor = [UIColor clearColor];
//
//        [_subtitleSizeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
//        [_subtitleSizeView addSubview:_subtitleSizeSlider];
//
//
//
//
//        _subtitleSizePopView = [UILabel new];
//        _subtitleSizePopView.textColor = UIColorFromRGB(0x888888);
//        _subtitleSizePopView.textAlignment = NSTextAlignmentCenter;
//        _subtitleSizePopView.font = [UIFont systemFontOfSize:13];
//        _subtitleSizePopView.frame = CGRectMake(((_subtitleSizeSlider.value - _subtitleSizeSlider.minimumValue) /(_subtitleSizeSlider.maximumValue - _subtitleSizeSlider.minimumValue)) * _subtitleSizeSlider.frame.size.width + _subtitleSizeSlider.frame.origin.x - 20, _subtitleSizeView.frame.size.height/2.0 - 30, 40, 30);
//        _subtitleSizePopView.text = [NSString stringWithFormat:@"%.f",subtitleDefaultSize];
//        _subtitleSizePopView.backgroundColor = [UIColor clearColor];
//        [_subtitleSizeView addSubview:_subtitleSizePopView];
//
//    }
//    return _subtitleSizeView;
//}


#pragma mark - 字幕位置
- (UIView *)subtitlePositionView{
    if(!_subtitlePositionView){
        _subtitlePositionView = [UIView new];
        _subtitlePositionView.backgroundColor = [UIColor clearColor];
        _subtitlePositionView.frame = CGRectMake(0, 0, self.bottomView.frame.size.width, self.bottomView.frame.size.height);
        
        UILabel *alignmentLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, (_subtitlePositionView.frame.size.width - 40)/2.0, 48)];
        alignmentLbl.text = RDLocalizedString(@"画布对齐", nil);
        alignmentLbl.textColor = UIColorFromRGB(0x888888);
        alignmentLbl.font = [UIFont systemFontOfSize:14.0];
        [_subtitlePositionView addSubview:alignmentLbl];
        
        float spaceH = 48 + (_subtitlePositionView.frame.size.height - 48 - 20*3 - 20)/3.0;
        float spaceW = (_subtitlePositionView.frame.size.width/2.0 - 40*3 - 20)/2.0;
        for (int i = 0; i < 4; i++) {
            int cellIdx = i%2;
            int rowIdx = ceil(i/2);
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(spaceW + 20 + 50 * cellIdx - ((cellIdx == 0) ? 0 : 2), spaceH + 10 + 30 * (rowIdx%2) - (((rowIdx%2) == 0) ? 0 : 2), 50, 30)];
            bgView.backgroundColor = [UIColor clearColor];
            bgView.layer.borderColor = UIColorFromRGB(0x202020).CGColor;
            bgView.layer.borderWidth = 2.0;
            [_subtitlePositionView addSubview:bgView];
        }
        for (int i = 0; i < 9; i++) {
            int cellIdx = i%3;
            int rowIdx = ceil(i/3);
            UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
            item.frame = CGRectMake(spaceW + (10 + 40) * cellIdx, spaceH + (10 + 20) * (rowIdx%3), 40, 20);
            item.backgroundColor = UIColorFromRGB(0x333333);
            item.tag = i + 1;
            [item addTarget:self action:@selector(clickSubtitlePositionItem:) forControlEvents:UIControlEventTouchUpInside];
            [_subtitlePositionView addSubview:item];
        }
        float width = 33.0;
        float y = 48;
        float height = _subtitlePositionView.frame.size.height - y - 10;
        float x = _subtitlePositionView.frame.size.width/2.0 + (_subtitlePositionView.frame.size.width/2.0 - height)/2.0;
        
        UILabel *moveLbl = [[UILabel alloc] initWithFrame:CGRectMake(x - 10, 0, (_subtitlePositionView.frame.size.width - 40)/2.0, 48)];
        moveLbl.text = RDLocalizedString(@"轻移", nil);
        moveLbl.textColor = UIColorFromRGB(0x888888);
        moveLbl.font = [UIFont systemFontOfSize:14.0];
        [_subtitlePositionView addSubview:moveLbl];
        
        for (int i = 0; i < 4; i++) {
            UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            if (i == 0) {
                itemBtn.frame = CGRectMake(x, y + (height - width)/2.0, width, width);
            }else if (i == 1) {
                itemBtn.frame = CGRectMake(x + (x/2.0 - width)/2.0, y, width, width);
            }else if (i == 2) {
                itemBtn.frame = CGRectMake(x + (x/2.0 - width)/2.0, _subtitlePositionView.frame.size.height - 10 - width, width, width);
            }else {
                itemBtn.frame = CGRectMake(x + x/2.0 - width, y + (height - width)/2.0, width, width);
            }
            [itemBtn setImage:[RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"next_jianji/Subtitles/剪辑-字幕_位置_%02i_", i]] forState:UIControlStateNormal];
            itemBtn.tag = i + 1;
            [itemBtn addTarget:self action:@selector(moveSlightlyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_subtitlePositionView addSubview:itemBtn];
        }
    }
    return _subtitlePositionView;
}

- (NSMutableArray *)borderColors{
    if(!_borderColors){
        _borderColors = [NSMutableArray array];
        
        [_borderColors addObject:[UIColor clearColor]];
        [_borderColors addObject:UIColorFromRGB(0x000000)];
        [_borderColors addObject:UIColorFromRGB(0xf9edb1)];
        [_borderColors addObject:UIColorFromRGB(0xffa078)];
        [_borderColors addObject:UIColorFromRGB(0xfe6c6c)];
        [_borderColors addObject:UIColorFromRGB(0xfe4241)];
        [_borderColors addObject:UIColorFromRGB(0x7cddfe)];
        [_borderColors addObject:UIColorFromRGB(0x41c5dc)];
        
        [_borderColors addObject:UIColorFromRGB(0x0695b5)];
        [_borderColors addObject:UIColorFromRGB(0x2791db)];
        [_borderColors addObject:UIColorFromRGB(0x0271fe)];
        [_borderColors addObject:UIColorFromRGB(0xdcffa3)];
        [_borderColors addObject:UIColorFromRGB(0xc7fe64)];
        [_borderColors addObject:UIColorFromRGB(0x82e23a)];
        [_borderColors addObject:UIColorFromRGB(0x25ba66)];
        [_borderColors addObject:UIColorFromRGB(0x017e54)];
        
        [_borderColors addObject:UIColorFromRGB(0xfdbacc)];
        [_borderColors addObject:UIColorFromRGB(0xff5a85)];
        [_borderColors addObject:UIColorFromRGB(0xff5ab0)];
        [_borderColors addObject:UIColorFromRGB(0xb92cec)];
        [_borderColors addObject:UIColorFromRGB(0x7e01ff)];
        [_borderColors addObject:UIColorFromRGB(0x848484)];
        [_borderColors addObject:UIColorFromRGB(0x88754d)];
        [_borderColors addObject:UIColorFromRGB(0x164c6e)];
    }
    return _borderColors;
}
#pragma mark - 按钮事件
- (void)clickToolItem:(UIButton *)sender{
    [_textView resignFirstResponder];
    
    if(!sender){
        sender = [[_toolBarView viewWithTag:10000] viewWithTag:0];
    }
    if(_selectOldSender){
        [_selectOldSender setSelected:NO];
    }
    _selectOldSender = sender;
    [sender setSelected:YES];
    NSInteger index = sender.tag;
    [self.bottomView setContentOffset:CGPointMake(index * self.bottomView.frame.size.width, 0) animated:NO];
    if (index == 2 && selectedContentType == 0) {
        noneColorBtn.hidden = YES;
        [_subtitleColorControl refreshFrame:CGRectMake(20, noneColorBtn.frame.origin.y, _subtitleColorView.frame.size.width - 20, noneColorBtn.frame.size.height)];
    }
}

#pragma mark - 字幕样式
- (void)catogeryBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        UIButton *prevBtn = [categoryScrollView viewWithTag:selectedCategoryIndex + 1];
        prevBtn.selected = NO;
        sender.selected = YES;
        selectedCategoryIndex = sender.tag - 1;
        _typeScrollView.contentOffset = CGPointMake((sender.tag - 1)*_typeScrollView.frame.size.width, 0);
    }
}

- (void)touchescaptionTypeViewChildWithIndex:(NSInteger)index{
    if (index == 0) {
        UIButton *categoryBtn = [categoryScrollView viewWithTag:1];
        categoryBtn.selected = YES;
        UICollectionView *collectionView = [_typeScrollView viewWithTag:1];
        [self collectionView:collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        firstSelectedCell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }else {
        [self.typeList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj1[@"id"] integerValue] == index) {
                    UICollectionView *collectionView = [_typeScrollView viewWithTag:(idx + 1)];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx1 inSection:0];
                    [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    firstSelectedCell = [collectionView cellForItemAtIndexPath:indexPath];
                    [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
                    selectedCategoryIndex = idx;
                    UIButton *categoryBtn = [categoryScrollView viewWithTag:idx + 1];
                    categoryBtn.selected = YES;
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
    }
}

#pragma mark - Animation
- (void)animationBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        sender.selected = YES;
        
        NSInteger tag = 1;
        if (sender.tag == 1) {
            tag = 2;
            if (_inAnimationIndex != _selectAnimationItemIndex) {
                UIButton *prevBtn = [animationScrollView viewWithTag:_selectAnimationItemIndex + 1];
                prevBtn.selected = NO;
                UIButton *selectedBtn = [animationScrollView viewWithTag:_inAnimationIndex + 1];
                selectedBtn.selected = YES;
                _selectAnimationItemIndex = _inAnimationIndex;
            }
            UIButton *fadeInOutBtn = [animationScrollView.subviews lastObject];
            [fadeInOutBtn setTitle:RDLocalizedString(@"淡入", nil) forState:UIControlStateNormal];
            [fadeInOutBtn setTitle:RDLocalizedString(@"淡入", nil) forState:UIControlStateSelected];
        }else if (_outAnimationIndex != _selectAnimationItemIndex) {
            UIButton *prevBtn = [animationScrollView viewWithTag:_selectAnimationItemIndex + 1];
            prevBtn.selected = NO;
            UIButton *selectedBtn = [animationScrollView viewWithTag:_outAnimationIndex + 1];
            selectedBtn.selected = YES;
            _selectAnimationItemIndex = _outAnimationIndex;
            UIButton *fadeInOutBtn = [animationScrollView.subviews lastObject];
            [fadeInOutBtn setTitle:RDLocalizedString(@"淡出", nil) forState:UIControlStateNormal];
            [fadeInOutBtn setTitle:RDLocalizedString(@"淡出", nil) forState:UIControlStateSelected];
        }
        UIButton *prevBtn = [_subtitleAnimationView viewWithTag:tag];
        prevBtn.selected = NO;
    }
}

- (void)animationTypeBtnAction:(UIButton *)sender{
    if (!sender.selected) {
        UIButton *prevBtn = [animationScrollView viewWithTag:_selectAnimationItemIndex + 1];
        prevBtn.selected = NO;
        sender.selected = YES;
        _selectAnimationItemIndex = sender.tag - 1;
        if (inAnimationBtn.selected) {
            _inAnimationIndex = _selectAnimationItemIndex;
            UIView *setAnimationView = [inAnimationBtn viewWithTag:66];
            setAnimationView.hidden = (_selectAnimationItemIndex == 0);
            if (_selectAnimationItemIndex > 0 && _outAnimationIndex == 0) {
                _outAnimationIndex = _selectAnimationItemIndex;
                UIView *setAnimationView = [outAnimationBtn viewWithTag:66];
                setAnimationView.hidden = NO;
            }
        }else {
            _outAnimationIndex = _selectAnimationItemIndex;
            UIView *setAnimationView = [outAnimationBtn viewWithTag:66];
            setAnimationView.hidden = (_selectAnimationItemIndex == 0);
        }
        if (_delegate && [_delegate respondsToSelector:@selector(previewAnimation:outType:subtitleScrollView:)]) {
            [_delegate previewAnimation:_inAnimationIndex outType:_outAnimationIndex subtitleScrollView:self];
        }
    }
}

#pragma mark - 字幕颜色
- (void)contentTypeBtnAction:(UIButton *)sender {
    if (!sender.selected) {
        UIButton *prevBtn = [_subtitleColorView viewWithTag:selectedContentType + 1];
        prevBtn.selected = NO;
        sender.selected = YES;
        selectedContentType = sender.tag - 1;
        switch (selectedContentType) {
            case RDSubtitleContentType_text:
            case RDSubtitleContentType_stroke:
            case RDSubtitleContentType_shadow:
            {
                float height = (_subtitleColorView.frame.size.height - 38)/2.0;
                CGRect frame = noneColorBtn.frame;
                frame.origin.y = 38 + height*0.4/2.0;
                noneColorBtn.frame = frame;
                
                _subtitleColorControl.frame = CGRectMake(_subtitleColorControl.frame.origin.x, frame.origin.y, _subtitleColorControl.frame.size.width, _subtitleColorControl.frame.size.height);
                _subtitleColorControl.hidden = NO;
                if (selectedContentType == RDSubtitleContentType_text) {
                    presetColorScrollView.hidden = NO;
                    alphaLbl.hidden = YES;
                    _alphaSlider.hidden = YES;
                }else {
                    _alphaSlider.minimumValue = 0.0;
                    if (selectedContentType == RDSubtitleContentType_stroke) {
                        _alphaSlider.value = _strokeWidth;
                    }else {
                        _alphaSlider.value = _shadowWidth;
                    }
                    alphaLbl.text = [NSString stringWithFormat:@"%.f%%", _alphaSlider.value*100.0];
                    CGRect frame = alphaLbl.frame;
                    frame.origin.y = 38 + height + (height - 30)/2.0;
                    alphaLbl.frame = frame;
                    _alphaSlider.frame = CGRectMake(_alphaSlider.frame.origin.x, frame.origin.y, _alphaSlider.frame.size.width, _alphaSlider.frame.size.height);
                    presetColorScrollView.hidden = YES;
                    alphaLbl.hidden = NO;
                    _alphaSlider.hidden = NO;
                }
            }
                break;
            case RDSubtitleContentType_bg:
            {
                CGRect frame = noneColorBtn.frame;
                frame.origin.y = 38 + (_subtitleColorView.frame.size.height - 38 - frame.size.height)/2.0;
                noneColorBtn.frame = frame;
                
                _subtitleColorControl.frame = CGRectMake(_subtitleColorControl.frame.origin.x, frame.origin.y, _subtitleColorControl.frame.size.width, _subtitleColorControl.frame.size.height);
                _subtitleColorControl.hidden = NO;
                presetColorScrollView.hidden = YES;
                alphaLbl.hidden = YES;
                _alphaSlider.hidden = YES;
            }
                break;
            case RDSubtitleContentType_alpha:
            {
                _alphaSlider.value = _subtitleAlpha;
                alphaLbl.text = [NSString stringWithFormat:@"%.f%%", _alphaSlider.value*100.0];
                _alphaSlider.minimumValue = 0.1;
                CGRect frame = alphaLbl.frame;
                frame.origin.y = 38 + (_subtitleColorView.frame.size.height - 38 - frame.size.height)/2.0;
                alphaLbl.frame = frame;
                _alphaSlider.frame = CGRectMake(_alphaSlider.frame.origin.x, frame.origin.y, _alphaSlider.frame.size.width, _alphaSlider.frame.size.height);
                noneColorBtn.hidden = YES;
                _subtitleColorControl.hidden = YES;
                presetColorScrollView.hidden = YES;
                alphaLbl.hidden = NO;
                _alphaSlider.hidden = NO;
            }
                break;
            default:
                break;
        }
        if (selectedContentType == 0) {
            noneColorBtn.hidden = YES;
            [_subtitleColorControl refreshFrame:CGRectMake(20, noneColorBtn.frame.origin.y, _subtitleColorView.frame.size.width - 20, noneColorBtn.frame.size.height)];
        }else if (selectedContentType != RDSubtitleContentType_alpha && noneColorBtn.hidden) {
            noneColorBtn.hidden = NO;
            [_subtitleColorControl refreshFrame:CGRectMake(57, noneColorBtn.frame.origin.y, _subtitleColorView.frame.size.width - 57, noneColorBtn.frame.size.height)];
        }
    }
}

- (void)noneColorBtnAction:(UIButton *)sender {
    UIButton *contentTypeBtn = [_subtitleColorView viewWithTag:(selectedContentType + 1)];
    UIView *setColorView = [contentTypeBtn viewWithTag:66];
    setColorView.hidden = YES;
    if (selectedContentType == RDSubtitleContentType_shadow) {
        _selectShadowColorIndex = -1;
        _isShadow = NO;
        _shadowWidth = 0.0;
        _alphaSlider.value = 0.0;
        alphaLbl.text = @"0%";
        if (_delegate && [_delegate respondsToSelector:@selector(changeWithIsBold:isItalic:isShadow:subtitleScrollView:)]) {
            [_delegate changeWithIsBold:_isBold isItalic:_isItalic isShadow:_isShadow subtitleScrollView:self];
        }
    }else {
        if (selectedContentType == RDSubtitleContentType_stroke) {
            _selectBorderColorItemIndex = -1;
            _strokeWidth = 0.0;
            _alphaSlider.value = 0.0;
            alphaLbl.text = @"0%";
        }else {
            _selectBgColorIndex = -1;
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(changeSubtitleColor:alpha:contentType:subtitleScrollView:)]) {
        [_delegate changeSubtitleColor:[UIColor clearColor] alpha:0 contentType:selectedContentType subtitleScrollView:self];
    }
}

- (void)presetTypeBtnAction:(UIButton *)sender {
    if (sender.tag != 6 || sender.tag != 7) {
        if (_delegate && [_delegate respondsToSelector:@selector(changeAlpha:subtitleScrollView:)]) {
            [_delegate changeAlpha:1.0 subtitleScrollView:self];
        }
    }
    switch (sender.tag) {
        case 1://白字、黑阴影、阴影50%
        {
            _selectColorItemIndex = 0;
            _selectBorderColorItemIndex = -1;
            _selectShadowColorIndex = 4;
            _selectBgColorIndex = -1;
            _alphaSlider.value = 0.5;
            _strokeWidth = 0.0;
            _shadowWidth = _alphaSlider.value;
            _subtitleAlpha = 1.0;
            _isShadow = YES;
            [self setColorViewHidden:NO contentIndex:1];
            [self setColorViewHidden:YES contentIndex:2];
            [self setColorViewHidden:NO contentIndex:3];
            [self setColorViewHidden:YES contentIndex:4];
        }
            break;
        case 2://黑字、白描边、描边50%
            _selectColorItemIndex = 4;
            _selectBorderColorItemIndex = 0;
            _selectShadowColorIndex = -1;
            _selectBgColorIndex = -1;
            _alphaSlider.value = 0.5;
            _strokeWidth = _alphaSlider.value;
            _shadowWidth = 0.0;
            _subtitleAlpha = 1.0;
            _isShadow = NO;
            [self setColorViewHidden:NO contentIndex:1];
            [self setColorViewHidden:NO contentIndex:2];
            [self setColorViewHidden:YES contentIndex:3];
            [self setColorViewHidden:YES contentIndex:4];
            break;
        case 3://白字、红描边、描边50%
            _selectColorItemIndex = 0;
            _selectBorderColorItemIndex = 8;
            _selectShadowColorIndex = -1;
            _selectBgColorIndex = -1;
            _alphaSlider.value = 0.5;
            _strokeWidth = _alphaSlider.value;
            _shadowWidth = 0.0;
            _subtitleAlpha = 1.0;
            _isShadow = NO;
            [self setColorViewHidden:NO contentIndex:1];
            [self setColorViewHidden:NO contentIndex:2];
            [self setColorViewHidden:YES contentIndex:3];
            [self setColorViewHidden:YES contentIndex:4];
            break;
        case 4://黑字、黄背景
            _selectColorItemIndex = 4;
            _selectBorderColorItemIndex = -1;
            _selectShadowColorIndex = -1;
            _selectBgColorIndex = 17;
            _strokeWidth = 0.0;
            _shadowWidth = 0.0;
            _subtitleAlpha = 1.0;
            _isShadow = NO;
            [self setColorViewHidden:NO contentIndex:1];
            [self setColorViewHidden:YES contentIndex:2];
            [self setColorViewHidden:YES contentIndex:3];
            [self setColorViewHidden:NO contentIndex:4];
            break;
        case 5://绿字、黑背景
            _selectColorItemIndex = 49;//53//34AA8E
            _selectBorderColorItemIndex = -1;
            _selectShadowColorIndex = -1;
            _selectBgColorIndex = 4;
            _strokeWidth = 0.0;
            _shadowWidth = 0.0;
            _subtitleAlpha = 1.0;
            _isShadow = NO;
            [self setColorViewHidden:NO contentIndex:1];
            [self setColorViewHidden:YES contentIndex:2];
            [self setColorViewHidden:YES contentIndex:3];
            [self setColorViewHidden:NO contentIndex:4];
            break;
        case 6:
            sender.selected = !sender.selected;
            _isBold = sender.selected;
            if([_delegate respondsToSelector:@selector(changeWithIsBold:isItalic:isShadow:subtitleScrollView:)]){
                [_delegate changeWithIsBold:_isBold isItalic:_isItalic isShadow:_isShadow subtitleScrollView:self];
            }
            break;
        case 7:
            sender.selected = !sender.selected;
            _isItalic = sender.selected;
            if([_delegate respondsToSelector:@selector(changeWithIsBold:isItalic:isShadow:subtitleScrollView:)]){
                [_delegate changeWithIsBold:_isBold isItalic:_isItalic isShadow:_isShadow subtitleScrollView:self];
            }
            break;
        default:
            break;
    }
}

- (void)setColorViewHidden:(BOOL)hidden contentIndex:(NSInteger)contentIndex {
    UIButton *contentTypeBtn = [_subtitleColorView viewWithTag:contentIndex];
    UIView *setColorView = [contentTypeBtn viewWithTag:66];
    setColorView.hidden = hidden;
    NSInteger colorIndex;
    RDSubtitleContentType contentType = (RDSubtitleContentType)(contentIndex - 1);
    float alpha = _alphaSlider.value;
    UIColor *color = [UIColor clearColor];
    switch (contentType) {
        case RDSubtitleContentType_stroke:
            colorIndex = _selectBorderColorItemIndex;
            alpha *= maxBorderWidth;
            break;
        case RDSubtitleContentType_shadow:
            colorIndex = _selectShadowColorIndex;
            alpha *= maxShadowWidth;
            break;
        case RDSubtitleContentType_bg:
            colorIndex = _selectBgColorIndex;
            alpha = 1.0;
            break;
        default:
            colorIndex = _selectColorItemIndex;
            alpha = 1.0;
            break;
    }
    if (colorIndex >= 0) {
        color = _colors[colorIndex];
    }else {
        alpha = 0;
    }
    alphaLbl.text = [NSString stringWithFormat:@"%.f%%", _alphaSlider.value*100.0];
    if (_delegate) {
        if([_delegate respondsToSelector:@selector(changeWithIsBold:isItalic:isShadow:subtitleScrollView:)]){
            [_delegate changeWithIsBold:_isBold isItalic:_isItalic isShadow:_isShadow subtitleScrollView:self];
        }
        if ([_delegate respondsToSelector:@selector(changeSubtitleColor:alpha:contentType:subtitleScrollView:)]) {
            [_delegate changeSubtitleColor:color alpha:alpha contentType:contentType subtitleScrollView:self];
        }
    }
}

#pragma mark - RDColorControlViewDelegate
- (void)colorChanged:(UIColor *)color index:(NSInteger)index colorControlView:(UIView *)colorControlView {
    float alpha;
    switch (selectedContentType) {
        case RDSubtitleContentType_stroke:
            _selectBorderColorItemIndex = index;
            if (_alphaSlider.value == 0) {
                _alphaSlider.value = 0.5;
            }
            alpha = _alphaSlider.value * maxBorderWidth;
            break;
        case RDSubtitleContentType_shadow:
            _selectShadowColorIndex = index;
            if (_alphaSlider.value == 0) {
                _alphaSlider.value = 0.5;
            }
            alpha = _alphaSlider.value * maxShadowWidth;
            _isShadow = YES;
            if (_delegate && [_delegate respondsToSelector:@selector(changeWithIsBold:isItalic:isShadow:subtitleScrollView:)]) {
                [_delegate changeWithIsBold:_isBold isItalic:_isItalic isShadow:_isShadow subtitleScrollView:self];
            }
            break;
        case RDSubtitleContentType_bg:
            _selectBgColorIndex = index;
            alpha = 1.0;
            break;
        default:
            _selectColorItemIndex = index;
            alpha = 1.0;
            break;
    }
    UIButton *contentTypeBtn = [_subtitleColorView viewWithTag:(selectedContentType + 1)];
    UIView *setColorView = [contentTypeBtn viewWithTag:66];
    setColorView.hidden = NO;
    alphaLbl.text = [NSString stringWithFormat:@"%.f%%", _alphaSlider.value*100.0];
    if (_delegate && [_delegate respondsToSelector:@selector(changeSubtitleColor:alpha:contentType:subtitleScrollView:)]) {
        [_delegate changeSubtitleColor:color alpha:alpha contentType:selectedContentType subtitleScrollView:self];
    }
}

- (void)scrub:(RDZSlider *)slider{
    alphaLbl.text = [NSString stringWithFormat:@"%.f%%",slider.value*100];
    if (slider.value > 0.0) {
        UIButton *contentTypeBtn = [_subtitleColorView viewWithTag:(selectedContentType + 1)];
        UIView *setColorView = [contentTypeBtn viewWithTag:66];
        setColorView.hidden = NO;
    }
    if(_delegate){
        if (selectedContentType == RDSubtitleContentType_alpha) {
            _subtitleAlpha = slider.value;
            if ([_delegate respondsToSelector:@selector(changeAlpha:subtitleScrollView:)]) {
                [_delegate changeAlpha:slider.value subtitleScrollView:self];
            }
        }else if ([_delegate respondsToSelector:@selector(changeSubtitleColor:alpha:contentType:subtitleScrollView:)]) {
            UIColor *color = [UIColor clearColor];
            float alpha = slider.value;
            if (selectedContentType == RDSubtitleContentType_stroke) {
                _strokeWidth = slider.value;
                if (_selectBorderColorItemIndex < 0) {
                    _selectBorderColorItemIndex = 0;
                }
                color = _colors[_selectBorderColorItemIndex];
                alpha *= maxBorderWidth;
            }else {
                _shadowWidth = slider.value;
                if (_selectShadowColorIndex < 0) {
                    _selectShadowColorIndex = 4;
                }
                color = _colors[_selectShadowColorIndex];
                alpha *= maxShadowWidth;
                _isShadow = YES;
            }
            [_delegate changeSubtitleColor:color alpha:alpha contentType:selectedContentType subtitleScrollView:self];
        }
    }
}

#pragma mark - 字体
- (void)clickSubtitleFontItem:(UIButton *)sender{
    if(!sender){
        sender = [_subtitleFontTypeScrollView viewWithTag:kFONTCHILDTAG + _selectFontItemIndex];
    }
    if(!sender){
        return;
    }
    
    NSDictionary *itemDic = [self.fonts objectAtIndex:sender.tag-kFONTCHILDTAG];
    NSString *pExtension = [[itemDic[@"file"] lastPathComponent] pathExtension];
    BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
    NSString *fileName = hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]] : itemDic[@"name"];
    
    UIImageView *imageView = (UIImageView *)[sender viewWithTag:40000];
    BOOL suc = [self hasCachedFont:fileName extStr:@"ttf" hasNew:hasNew];
    NSInteger index = sender.tag - kFONTCHILDTAG;
    if(index == 0){
        _selectFontItemIndex = index;
        selectedFontView.center = sender.center;
        [self setFont:index];
    }else if(!suc){
        
        if([_delegate respondsToSelector:@selector(downloadFile:cachePath:fileName:timeunix:fileType:sender:subtitleScrollView:progress:finishBlock:failBlock:)]){
            
            NSString *time = [NSString stringWithFormat:@"%ld",[(hasNew ? itemDic[@"updatetime"] : itemDic[@"timeunix"]) integerValue]];
            
            NSString * path = [self pathForURL_font_down:fileName extStr: hasNew ? [[itemDic[@"file"] lastPathComponent] pathExtension] : pExtension];
            if(![[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingLastPathComponent]]){
                [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            }
            imageView.hidden = YES;
            [_delegate downloadFile:(hasNew ? itemDic[@"file"] : itemDic[@"caption"]) cachePath:path fileName:hasNew ? @"" : fileName timeunix:time fileType:DownFileFont sender:sender subtitleScrollView:self progress:^(float progress) {
                
            }  finishBlock:^{
                [imageView removeFromSuperview];
                [self clickSubtitleFontItem:sender];
            } failBlock:^{
                imageView.hidden = NO;
           }  ];
        }
    }else{
        _selectFontItemIndex = index;
        selectedFontView.center = sender.center;
        [self setFont:index];
    }
}

//根据ID设置字体
- (void)setFont:(NSInteger)index{
    NSString *selectFontName;
    
    for (int k=0;k<self.fonts.count;k++) {
        
        UIButton *sender = (UIButton *)[self.subtitleFontTypeScrollView viewWithTag:k + kFONTCHILDTAG];
        NSDictionary *itemDic = [self.fonts objectAtIndex:sender.tag-kFONTCHILDTAG];
        UIImageView *imagev = (UIImageView *)[sender viewWithTag:40000];
        
        UIImageView *selectView = (UIImageView *)[sender viewWithTag:50000];
        
        NSString *title = itemDic[@"name"];
        BOOL isCached = NO;
        if(k !=0){
            BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
            title = hasNew ? [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension] : itemDic[@"name"];
            
            isCached = [self hasCachedFont:hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]] : itemDic[@"name"] extStr:@"ttf" hasNew:hasNew];
        }
        UIImageView *titleIV = (UIImageView *)[sender viewWithTag:kFontTitleImageViewTag];
        
        if ([titleIV isKindOfClass:[UIImageView class]]) {
            if(isCached && sender.tag - kFONTCHILDTAG == index){
                NSString *path = [NSString stringWithFormat:@"%@/%@/selected",kFontFolder,title];
                BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
                if(hasNew){
                    [titleIV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_",title]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        titleIV.image = image;
                    }
                }
                
            }else if (sender.tag - kFONTCHILDTAG != 0) {
                NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[self.fontIcons objectForKey:@"name"]];
                BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
                if(hasNew){
                    [titleIV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_",title]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        titleIV.image = image;
                    }
                }
                
            }else {
                UILabel *titleLbl = (UILabel *)[sender viewWithTag:3];
                if ([titleLbl isKindOfClass:[UILabel class]]) {
                    if (sender.tag - kFONTCHILDTAG == index) {
                        titleLbl.textColor = Main_Color;
                    }else {
                        titleLbl.textColor = UIColorFromRGB(0xbdbdbd);
                    }
                }
            }
            
        }
        if([imagev isKindOfClass:[UIImageView class]]){
            if((sender.tag - kFONTCHILDTAG == index) ||!isCached){
                if(sender.tag - kFONTCHILDTAG == index){
                    imagev.hidden = YES;
                    
                }else if(!isCached && sender.tag - kFONTCHILDTAG != 0 ){
                    imagev.hidden = NO;
                    
                }else{
                    imagev.hidden = YES;
                }
            }else{
                imagev.hidden = YES;
            }
        }
        if([selectView isKindOfClass:[UIImageView class]]){
            if((sender.tag - kFONTCHILDTAG == index) ||!isCached){
                if(sender.tag - kFONTCHILDTAG == index){
                    selectView.hidden = NO;
                    
                }else if(!isCached && sender.tag - kFONTCHILDTAG != 0 ){
                    selectView.hidden = YES;
                    
                }else{
                    selectView.hidden = NO;
                }
            }else{
                selectView.hidden = YES;
            }
        }
        if(k == 0 && index !=0){
            selectView.hidden = YES;
        }
    }
    
    if(index==0){
        selectFontName = [[UIFont systemFontOfSize:10] fontName];// @"Baskerville-BoldItalic";
        NSLog(@"selectFontName==%@",selectFontName);
        
        if([_delegate respondsToSelector:@selector(setFontWithName:fontCode:fontPath:subtitleScrollView:)]){
            [_delegate setFontWithName:selectFontName fontCode:@"morenziti" fontPath:nil subtitleScrollView:self];
        }
        
        return;
    }
    
    NSString *fontCode;
    NSString *path;
    NSDictionary *itemDic = [self.fonts objectAtIndex:index];
    
    BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
    
    fontCode = hasNew ? [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension] : itemDic[@"name"];
    path = [self pathForURL_font:fontCode extStr:@"ttf" hasNew:hasNew];
    if(hasNew){
        NSString *n = [[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent];
        NSString *f = [NSString stringWithFormat:@"%@/%@",kFontFolder,n];
        __block NSString *fn;
        NSArray *dirList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:f error:nil];
        [dirList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([fontCode isEqualToString:@"file"]) {
                if ([[[obj pathExtension] lowercaseString] isEqualToString:@"ttf"]) {
                    fn = obj;
                    *stop = YES;
                }else{
                    NSString * ipath = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],obj];
                    [[NSFileManager defaultManager] removeItemAtPath:ipath error:nil];
                }
            }
            else if([[obj stringByDeletingPathExtension] isEqualToString:fontCode]){
                fn = obj;
                *stop = YES;
            }else{
              NSString * ipath = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],obj];
                [[NSFileManager defaultManager] removeItemAtPath:ipath error:nil];
            }
        }];
        path = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],fn];
    }
    NSArray *fontNames = [RDHelpClass customFontArrayWithPath:path];
    NSLog(@"fontName:%@",fontNames);
    selectFontName = [fontNames firstObject];
    fontNames = nil;
    
    if([_delegate respondsToSelector:@selector(setFontWithName:fontCode:fontPath:subtitleScrollView:)]){
        [_delegate setFontWithName:selectFontName fontCode:fontCode fontPath:path subtitleScrollView:self];
    }
}


- (NSString *)pathForURL_font_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,name,extStr];
}

- (NSString *)pathForURL_Subtitle_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kSubtitleFolder,name,extStr];
}


-(NSString *)pathForURL_font:(NSString *)name extStr:(NSString *)extStr hasNew:(BOOL)hasNew{
    NSString *filePath = nil;
    if(!hasNew){
        filePath = [NSString stringWithFormat:@"%@/%@/%@.%@",kFontFolder,name,name,extStr];
    }else{
        filePath = [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,name,extStr];
    }
    return filePath;
}

//判断是否已经缓存过这个URL
-(BOOL) hasCachedFont:(NSString *)name extStr:(NSString *)extStr hasNew:(BOOL)hasNew{
    if(extStr.length == 0){
        return NO;
    }
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(hasNew){
       NSString * filePath = [NSString stringWithFormat:@"%@/%@",kFontFolder,name];
        if (![[name lastPathComponent] isEqualToString:@"file"]) {
            if ([fileManager fileExistsAtPath:[filePath stringByAppendingPathExtension:extStr]]) {
                return YES;
            }
        }
        else if(([[fileManager contentsOfDirectoryAtPath:[filePath stringByDeletingLastPathComponent] error:nil] count]>0)){
            return YES;
        }
        return NO;
    }
    if ([fileManager fileExistsAtPath:[self pathForURL_font:name extStr:extStr hasNew:hasNew]]) {
        return YES;
    }
    else return NO;
}

#pragma mark - 字幕位置
- (void)moveSlightlyBtnAction:(UIButton *)sender {
    if ([_delegate respondsToSelector:@selector(changeMoveSlightlyPosition:subtitleScrollView:)]) {
        [_delegate changeMoveSlightlyPosition:(RDMoveSlightlyDirection)(sender.tag - 1) subtitleScrollView:self];
    }
}

- (void)setCaptionRangeView:(CaptionRangeView *)captionRangeView{
    _captionRangeView = captionRangeView;
    oldFontColor  = captionRangeView.file.tColor;
    oldBorderColor = captionRangeView.file.strokeColor;
}

- (void)clickSubtitlePositionItem:(UIButton *)sender{
    if([_delegate respondsToSelector:@selector(changePosition:subtitleScrollView:)]){
        [_delegate changePosition:(RDSubtitleAlignment)(sender.tag) subtitleScrollView:self];
    }
}

- (void)TextClose
{
    if([_delegate respondsToSelector:@selector(changeClose:)]){
        [_delegate changeClose:self];
    }

    self.hidden = YES;
    [_textView resignFirstResponder];
}

-(void)Close_Btn
{
        if( oldText.length )
            _textView.text = oldText;
        else
            _textView.text = RDLocalizedString(@"点击输入字幕", nil);

    [_textView resignFirstResponder];
    _topView.hidden = YES;
    _bottomView.hidden = NO;
    [self contentTextValueChange:_textView];
}

-(void)ok_Btn
{
    [self saveTextFieldTxt];
    [_textView resignFirstResponder];
    _topView.hidden = YES;
    _bottomView.hidden = NO;
}

- (void)save{
    if(_textView.text.length>0){
        self.hidden = YES;
    }
    [_textView resignFirstResponder];
    if([_delegate respondsToSelector:@selector(changeSubtitleContentString:subtitleScrollView:)]){
        [_delegate changeSubtitleContentString:[self contentTextFieldText] subtitleScrollView:self];
    }
    if([_delegate respondsToSelector:@selector(useToAllWithSubtitleScrollView:)] && _textView.text.length>0){
        if(_useTypeToAll || _useAnimationToAll || _useColorToAll || _useBorderToAll || _useFontToAll || _useSizeToAll || _usePositionToAll){
            [_delegate useToAllWithSubtitleScrollView:self];
        }
    }
    if([_delegate respondsToSelector:@selector(saveSubtitleConfig:subtitleScrollView:)]){
        [_delegate saveSubtitleConfig:_selectedTypeId subtitleScrollView:self];
    }
}

- (void)clear{
    [_typeScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [obj removeFromSuperview];
        obj = nil;
    }];
    [_subtitleAnimationView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    [_subtitlePositionView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    [_toolBarView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    [_bottomView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    
}

- (void)contentTextValueChange:(UITextView *)textfiled{
    if([_delegate respondsToSelector:@selector(changeSubtitleContentString:subtitleScrollView:)]){
        [_delegate changeSubtitleContentString:textfiled.text subtitleScrollView:self];
    }
}

- (void)contentTextFieldValueChange:(UITextField *)textfiled{
    if([_delegate respondsToSelector:@selector(changeSubtitleContentString:subtitleScrollView:)]){
        [_delegate changeSubtitleContentString:textfiled.text subtitleScrollView:self];
    }
}

//- (BOOL)textFieldShouldReturn:(UITextField *)textField{
//    [self.contentTextField resignFirstResponder];
//    return YES;
//}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    _isFieldChanged = YES;
    return YES;
}

-(void)setStrokeColor:( UIColor * ) strokeColor atWidth:( int ) width atAlpha:( float ) alpha
{
//    [_subtitleBorderColorControl setValue: strokeColor ];
//    _selectBorderColorItemIndex = _subtitleBorderColorControl.currentColorIndex;
//    _strokeWidth = 2.0;
//    _strokeAlpha = 1.0;
//    [_borderWidthSlider setValue:_strokeWidth/maxBorderWidth];
//    if([_delegate respondsToSelector:@selector(changeBorder:alpha:borderWidth:subtitleScrollView:)]){
//        [_delegate changeBorder:self.borderColors[_selectBorderColorItemIndex] alpha:_borderAlphaSlider.value borderWidth:_borderWidthSlider.value * maxBorderWidth subtitleScrollView:self];
//    }
}

- (void)setContentTextFieldText:(NSString *)contentText{
    if (![contentText isEqualToString:RDLocalizedString(@"点击输入字幕", nil)]) {
        self.textView.text = contentText;
    }else{
        self.textView.text = @"";
    }
}

- (NSString *)contentTextFieldText{
    if (_textView.text.length == 0) {
        return RDLocalizedString(@"点击输入字幕", nil);
    }
    return self.textView.text;

}

- (void)clearTextField:(UIButton *)sender{
    self.textView.text = @"";
    if([_delegate respondsToSelector:@selector(changeSubtitleContentString:subtitleScrollView:)]){
        [_delegate changeSubtitleContentString:[self contentTextFieldText] subtitleScrollView:self];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)theSectionIndex {
    return [[_subtitleTypes[collectionView.tag - 1] objectForKey:@"data"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"typeCell";
    RDSubtitleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = UIColorFromRGB(0x232323);
    cell.layer.cornerRadius = 2.0;
    cell.layer.masksToBounds = YES;
    cell.layer.borderColor = Main_Color.CGColor;
    [[cell viewWithTag:666] removeFromSuperview];
    
    NSDictionary *items = [[_subtitleTypes[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    [cell.coverIV rd_sd_setImageWithURL:[NSURL URLWithString:items[@"cover"]]];
#if 0
    NSString *fileName = items[@"name"];
    NSString *path = [NSString stringWithFormat:@"%@/%@/config.json",[NSString stringWithFormat:@"%@%@",kSubtitleFolder, [NSString stringWithFormat:@"/%@",[[items[@"file"] stringByDeletingLastPathComponent] lastPathComponent]]], fileName];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSError *error;
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            NSLog(@"manager_error:%@",error);
        }
        cell.downloadIV.hidden = NO;
    }else {
        cell.downloadIV.hidden = YES;
    }
#endif
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    int typId = [[[[_subtitleTypes[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row] objectForKey:@"id"] intValue];
    if (_selectedTypeId == typId) {
        cell.layer.borderWidth = 2.0;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderWidth = 0.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(isDowning){
        return;
    }
    NSDictionary *itemDic = [[_subtitleTypes[collectionView.tag - 1] objectForKey:@"data"] objectAtIndex:indexPath.row];
    int typId = [[itemDic objectForKey:@"id"] intValue];
//    if (_selectedTypeId != typId) {
        if (firstSelectedCell) {
            firstSelectedCell.layer.borderWidth = 0.0;
            firstSelectedCell = nil;
        }
        _selectedTypeId = typId;
        RDSubtitleCollectionViewCell *cell = (RDSubtitleCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.layer.borderWidth = 2.0;
        
        NSString *pExtension = [[itemDic[@"file"] lastPathComponent] pathExtension];
        NSString *fileName =[[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension];
        fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *folderName = [NSString stringWithFormat:@"/%@",[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent]];
        NSString *path = [NSString stringWithFormat:@"%@%@/%@.%@",kSubtitleFolder,folderName,fileName,pExtension];
        NSFileManager *manager = [[NSFileManager alloc] init];
        NSString *configPath = [NSString stringWithFormat:@"%@/config.json", [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[itemDic objectForKey:@"name"]]];
        if(![manager fileExistsAtPath:[path stringByDeletingLastPathComponent]]){
            [manager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if(![manager fileExistsAtPath:configPath]){
            cell.downloadIV.hidden = YES;
            if([_delegate respondsToSelector:@selector(downloadFile:cachePath:fileName:timeunix:fileType:sender:subtitleScrollView:progress:finishBlock:failBlock:)]){
                NSString *timeS = itemDic[@"updatetime"];
                NSString *time = [NSString stringWithFormat:@"%ld",(long)[timeS integerValue]];
                self.okBtn.enabled = NO;
                isDowning = YES;
                [_delegate downloadFile:itemDic[@"file"] cachePath:path fileName:@"" timeunix:time fileType:DownFileCapption sender:cell subtitleScrollView:self progress:^(float progress) {
                    
                }  finishBlock:^{
                    isDowning = NO;
                    self.okBtn.enabled = YES;
                    [self setSubtitleSize:MAX(_subtitleSize, 0)];
                    if([_delegate respondsToSelector:@selector(changeType:index:subtitleScrollView:Name:coverPath:)]){
                        [_delegate changeType:configPath index:typId subtitleScrollView:self Name:itemDic[@"name"] coverPath:itemDic[@"cover"]];
                    }
                } failBlock:^{
                    isDowning = NO;
                    cell.downloadIV.hidden = NO;
                }];
            }
        }else{
            self.okBtn.enabled = YES;
             [self setSubtitleSize:MAX(_subtitleSize, 0)];
            if([_delegate respondsToSelector:@selector(changeType:index:subtitleScrollView:Name:coverPath:)]){
                [_delegate changeType:configPath index:typId subtitleScrollView:self Name:itemDic[@"name"] coverPath:itemDic[@"cover"]];
            }
        }
//    }
}

//TODO:应用到所有
#if 0
- (void)useTypeToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _useTypeToAll = sender.selected;
}
- (void)useAnimationToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _useAnimationToAll = sender.selected;

}
- (void)useColorToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _useColorToAll = sender.selected;

}
- (void)useBorderColorToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _useBorderToAll = sender.selected;

}

- (void)useFontToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _useFontToAll = sender.selected;
}

- (void)useSizeToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _useSizeToAll = sender.selected;
}

- (void)usePositionToAllSubtitle:(UIButton *)sender{
    sender.selected = !sender.selected;
    _usePositionToAll = sender.selected;
}
#endif

- (void)setProgressSize:(float)value{
//    _subtitleSizeSlider.value = value;
//    float progress = ((_subtitleSizeSlider.value - _subtitleSizeSlider.minimumValue ) /(_subtitleSizeSlider.maximumValue - _subtitleSizeSlider.minimumValue));
//
//    _subtitleSizePopView.frame = CGRectMake(progress * (_subtitleSizeSlider.frame.size.width - 20) + _subtitleSizeSlider.frame.origin.x-10, _subtitleSizeView.frame.size.height/2.0 - 30, 40, 30);
//
//
//    float size = subtitleDefaultSize + _subtitleSizeSlider.value * 8.0;
//    _subtitleSizePopView.text = [NSString stringWithFormat:@"%.f",size];
}

//- (void)setIsBold:(BOOL)isBold {
//    _isBold = isBold;
//    UIButton *boldBtn = [presetColorScrollView viewWithTag:6];
//    boldBtn.selected = YES;
//}
//
//- (void)setIsItalic:(BOOL)isItalic {
//    _isItalic = isItalic;
//    UIButton *italicBtn = [presetColorScrollView viewWithTag:7];
//    italicBtn.selected = YES;
//}
//
//- (void)setIsShadow:(BOOL)isShadow {
//    _isShadow = isShadow;
//}

- (void)setShadowWidth:(float)shadowWidth {
    _shadowWidth = shadowWidth/maxShadowWidth;
}

- (void)setStrokeWidth:(float)strokeWidth {
    _strokeWidth = strokeWidth / maxBorderWidth;
}

- (NSMutableArray <NSDictionary *>*)typeList{
    return _subtitleTypes;
}

- (void)dealloc{
    NSLog(@"subtitleScrollView-->%s",__func__);
}

@end
