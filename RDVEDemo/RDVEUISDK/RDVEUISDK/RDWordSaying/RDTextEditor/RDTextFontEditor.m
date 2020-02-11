//
//  RDTextFontEditor.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/16.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTextFontEditor.h"
#import "RDATMHud.h"
#import "RDFileDownloader.h"
#import "UIImage+RDGIF.h"
//#import "UITextTypesetViewCell.h"

#import "UIButton+RDWebCache.h"
#import "UIImageView+RDWebCache.h"

#define kFONTCHILDTAG 200000
#define kFontTitleImageViewTag 100000

@interface RDTextFontEditor()<UICollectionViewDelegate, UICollectionViewDataSource,UITextTypesetViewCellDelegate,UITextFieldDelegate,keyInputTextFieldDelegate>
{
    int         currentIndex;
    
    //编辑文本框
    UIButton    *confirmEditTxtBtn;
     UIView              *MainCircleView;
    
}
@property(nonatomic,strong)RDATMHud *hud;
@end

@implementation RDTextFontEditor

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:nil];
        [self addSubview:_hud.view];
    }
    return _hud;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        currentIndex = 0;
        self.backgroundColor =  SCREEN_BACKGROUND_COLOR;
        _currentTextEditTag = -1;
        [self addSubview:self.textTimeView];
        [self addSubview:self.textTypesetView];
    }
    return self;
}

-(UIView*) textTimeView
{
    if( !_textTimeView )
    {
        _textTimeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 88)];
        _textTimeView.backgroundColor = TOOLBAR_COLOR;
        
        _textBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _textBackBtn.exclusiveTouch = YES;
        _textBackBtn.backgroundColor = [UIColor clearColor];
        _textBackBtn.frame = CGRectMake(5, 0, 44, 44);
        [_textBackBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_textBackBtn addTarget:self action:@selector(textBack) forControlEvents:UIControlEventTouchUpInside];
        [_textTimeView addSubview:_textBackBtn];
        
        _textCancelSelectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _textCancelSelectBtn.exclusiveTouch = YES;
        _textCancelSelectBtn.backgroundColor = [UIColor clearColor];
        _textCancelSelectBtn.frame = CGRectMake(5, 0, 80, 44);
        _textCancelSelectBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_textCancelSelectBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [_textCancelSelectBtn setTitle:RDLocalizedString(@"取消选择", nil) forState:UIControlStateNormal];
        [_textCancelSelectBtn addTarget:self action:@selector(Cancel_Select) forControlEvents:UIControlEventTouchUpInside];
        [_textTimeView addSubview:_textCancelSelectBtn];
        _textCancelSelectBtn.hidden = YES;
        
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(69, 0, kWIDTH - 69*2, 44)];
        textLabel.text = RDLocalizedString(@"文本", nil);
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.textColor = [UIColor whiteColor];
        [_textTimeView addSubview:textLabel];
        
        _textCarryOutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _textCarryOutBtn.exclusiveTouch = YES;
        _textCarryOutBtn.backgroundColor = [UIColor clearColor];
        _textCarryOutBtn.frame = CGRectMake(kWIDTH - 69, 0, 64, 44);
        _textCarryOutBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_textCarryOutBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_textCarryOutBtn setTitle:RDLocalizedString(@"完成", nil) forState:UIControlStateNormal];
        [_textCarryOutBtn addTarget:self action:@selector(textCarryOut) forControlEvents:UIControlEventTouchUpInside];
        [_textTimeView addSubview:_textCarryOutBtn];
        
        _textSelectCallBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _textSelectCallBtn.exclusiveTouch = YES;
        _textSelectCallBtn.backgroundColor = [UIColor clearColor];
        _textSelectCallBtn.frame = CGRectMake(kWIDTH - 69, 0, 64, 44);
        _textSelectCallBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_textSelectCallBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [_textSelectCallBtn setTitle:RDLocalizedString(@"全选", nil) forState:UIControlStateNormal];
        [_textSelectCallBtn addTarget:self action:@selector(Select_Call) forControlEvents:UIControlEventTouchUpInside];
        [_textTimeView addSubview:_textSelectCallBtn];
        _textSelectCallBtn.hidden = YES;
        
        _textPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _textPlayBtn.backgroundColor = [UIColor clearColor];
        _textPlayBtn.frame = CGRectMake( 20, 44, 44, 44);
        [_textPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateNormal];
        [_textPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_播放_"] forState:UIControlStateHighlighted];
        [_textPlayBtn setImage:[RDHelpClass imageWithContentOfFile:@"/jianji/music/剪辑-剪辑-音乐_暂停_"] forState:UIControlStateSelected];
        [_textPlayBtn addTarget:self action:@selector(Play_Btn:) forControlEvents:UIControlEventTouchUpInside];
        [_textTimeView addSubview:_textPlayBtn];
        
        _textVideoProgress = [[RDZSlider alloc] initWithFrame:CGRectMake(74, 44 + (44 - 30)/2.0, _textTimeView.frame.size.width - 84*2.0, 30)];
        _textVideoProgress.backgroundColor = [UIColor clearColor];
        [_textVideoProgress setMaximumValue:1];
        [_textVideoProgress setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_textVideoProgress setMinimumTrackImage:image forState:UIControlStateNormal];
        _textVideoProgress.layer.cornerRadius = 2.0;
        _textVideoProgress.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_textVideoProgress setMaximumTrackImage:image forState:UIControlStateNormal];
        [_textVideoProgress  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_textVideoProgress setValue:0];
        _textVideoProgress.alpha = 1.0;
        
        _textTimeLabel = [[UILabel alloc] init];
        _textTimeLabel.frame = CGRectMake(_textVideoProgress.frame.size.width + _textVideoProgress.frame.origin.x + 10, 44 + (44 - 20)/2.0, 74, 20);
        _textTimeLabel.text = [RDHelpClass timeToStringNoSecFormat:0.0];
        _textTimeLabel.textAlignment = NSTextAlignmentLeft;
        _textTimeLabel.textColor = UIColorFromRGB(0xffffff);
        _textTimeLabel.font = [UIFont systemFontOfSize:8];
        [_textTimeView addSubview:_textTimeLabel];
        
        _textTimeLabel.text = [NSString stringWithFormat:@"%@/%@",[self IntTimeToStringFormat:CMTimeGetSeconds([_rdPlayer currentTime])],[self IntTimeToStringFormat:_rdPlayer.duration]];
        
        [_textVideoProgress addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_textVideoProgress addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_textVideoProgress addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_textVideoProgress addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        [_textTimeView addSubview:_textVideoProgress];
    }
    return _textTimeView;
}

- (NSString *)IntTimeToStringFormat:(float)time{
    @autoreleasepool {
        if(time<=0){
            time = 0;
        }
        int secondsInt  = floorf(time);
        float haomiao=time-secondsInt;
        int hour        = secondsInt/3600;
        secondsInt     -= hour*3600;
        int minutes     =(int)secondsInt/60;
        secondsInt     -= minutes * 60;
        NSString *strText;
        if(haomiao==1){
            secondsInt+=1;
            haomiao=0.f;
        }
        if (hour>0)
        {
            strText=[NSString stringWithFormat:@"%02i:%02i:%02i",hour,minutes, secondsInt];
        }else{
            
            strText=[NSString stringWithFormat:@"%02i:%02i",minutes, secondsInt];
        }
        return strText;
    }
}

-(void)textBack
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    if( [_delegate respondsToSelector:@selector(textOut:)] )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate textOut: _isRenewRotate ];
        });
    }
}

-(void)textObjectSave
{
    for (int i = 0; i< _textTypesetViewArray.count; i++) {
        //字体
        _textObjectViewArray[i].fontName = _textTypesetViewArray[i].textObject.fontName;
        _textObjectViewArray[i].textFontSize = _textTypesetViewArray[i].textObject.textFontSize;
        //阴影
        _textObjectViewArray[i].textFontshadow = _textTypesetViewArray[i].textObject.textFontshadow;
        _textObjectViewArray[i].textColorShadow = _textTypesetViewArray[i].textObject.textColorShadow;
        //描边
        _textObjectViewArray[i].textFontStroke = _textTypesetViewArray[i].textObject.textFontStroke;
        _textObjectViewArray[i].textFontStrokeColor = _textTypesetViewArray[i].textObject.textFontStrokeColor;
        
        //字体颜色
        _textObjectViewArray[i].strText = nil;
        _textObjectViewArray[i].strText = [[NSString alloc] initWithFormat:@"%@",_textTypesetViewArray[i].textField.attributedText.string];
        _textObjectViewArray[i].textColor = _textTypesetViewArray[i].textObject.textColor ;
    }
}

-(void)textCarryOut
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self textObjectSave];
    if( [_delegate respondsToSelector:@selector(textOut:)] )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate textOut: _isRenewRotate ];
        });
    }
}
-(void)Play_Btn:(UIButton *) btn
{
    btn.selected = !btn.selected;
    if( [_delegate respondsToSelector:@selector(play:)] )
    {
        if( btn.selected )
            [_delegate play:YES];
        else
            [_delegate play:NO];
    }
}

#pragma mark- 文字编辑
-(UIView*)fontEditView
{
    if( !_fontEditView )
    {
        _fontEditView = [[UIView alloc] initWithFrame:CGRectMake(0, _textTypesetScrollView.frame.size.height + _textTypesetScrollView.frame.origin.y, _textTypesetView.frame.size.width, kToolbarHeight + 21)];
        
        _fontEditView.backgroundColor =  TOOLBAR_COLOR;
        
        _mutabArray = [NSMutableArray new];
        
        [_mutabArray addObject:[self btn:@"字体" atTag:0]];
        [_mutabArray addObject:[self btn:@"描边" atTag:1]];
        [_mutabArray addObject:[self btn:@"阴影" atTag:2]];
        
        [_fontEditView addSubview:_mutabArray[0]];
        [_fontEditView addSubview:_mutabArray[1]];
        [_fontEditView addSubview:_mutabArray[2]];
    }
    return _fontEditView;
}

-(UIButton *)btn:(NSString *) str atTag:(int) tag
{
    float toolItemBtnWidth = 65;
    float width = _fontEditView.frame.size.width/3.0;
    
    NSString *title = str;
    UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    toolItemBtn.tag = tag;
    toolItemBtn.backgroundColor = [UIColor clearColor];
    toolItemBtn.exclusiveTouch = YES;
    toolItemBtn.frame = CGRectMake( tag*width + (width-toolItemBtnWidth)/2.0 , 0, toolItemBtnWidth, toolItemBtnWidth);
    [toolItemBtn addTarget:self action:@selector(textClickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
    NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/TextToSpeech/文转音_%@_默认_@3x", title] Type:@"png"];
    [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/TextToSpeech/文转音_%@_选中_@3x", title] Type:@"png"];
    [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
    [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
    [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
    [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
    
    return toolItemBtn;
}
-(void)textClickToolItemBtn:(UIButton *) btn
{
    if( _currentTextEditTag == btn.tag )
    {
        _currentTextEditTag = -1;
        btn.selected = NO;
        _strokeView.hidden = YES;
        _shadowView.hidden = YES;
        _textFontScrollView.hidden = YES;
        _textColorScrollView.hidden = YES;
        return;
    }
    
    _textCancelSelectBtn.hidden = YES;
    _textSelectCallBtn.hidden = YES;
    _textBackBtn.hidden = NO;
    _textCarryOutBtn.hidden = NO;
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setSelect:NO];
    }];
    
    switch ( btn.tag ) {
        case 0://字体
        {
            _strokeView.hidden = YES;
            _shadowView.hidden = YES;
            _textColorScrollView.hidden = YES;
            self.textFontScrollView.hidden = NO;
        }
            break;
        case 1://描边
        {
            self.strokeView.hidden = NO;
            self.textColorScrollView.hidden = NO;
            _shadowView.hidden = YES;
            _textFontScrollView.hidden = YES;
            _textColorScrollView.frame = CGRectMake(_textTypesetView.frame.size.width - 40, 0, 40, _textTypesetView.frame.size.height -  _fontEditView.frame.size.height - 44 );
        }
            break;
        case 2://阴影
        {
            self.shadowView.hidden = NO;
            _strokeView.hidden = YES;
            self.textColorScrollView.hidden = NO;
            _textFontScrollView.hidden = YES;
            _textColorScrollView.frame = CGRectMake(_textTypesetView.frame.size.width - 40, 0, 40, _textTypesetView.frame.size.height -  _fontEditView.frame.size.height - 44 );
        }
            break;
        default:
            break;
    }
    _currentTextEditTag = btn.tag;
    
    [_mutabArray enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == btn.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

-(UIView*)strokeView
{
    if( !_strokeView )
    {
        _strokeView = [[UIView alloc] initWithFrame:CGRectMake(0, _fontEditView.frame.origin.y - 44 , _fontEditView.frame.size.width, 44)];
        _strokeView.backgroundColor =  TOOLBAR_COLOR;
        
        UILabel * strokeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (_strokeView.frame.size.height-20)/2.0, 44, 20)];
        strokeLabel.textAlignment = NSTextAlignmentRight;
        strokeLabel.font = [UIFont systemFontOfSize:12];
        strokeLabel.textColor = [UIColor whiteColor];
        strokeLabel.text = RDLocalizedString(@"粗细", nil);
        [_strokeView  addSubview:strokeLabel];
        
        _strokeSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(74, (_strokeView.frame.size.height - 30)/2.0, _textTimeView.frame.size.width - 84 - 20, 30)];
        _strokeSlider.backgroundColor = [UIColor clearColor];
        [_strokeSlider setMaximumValue:1];
        [_strokeSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_strokeSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        _strokeSlider.layer.cornerRadius = 2.0;
        _strokeSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_strokeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_strokeSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_strokeSlider setValue:0];
        _strokeSlider.alpha = 1.0;
        [_strokeSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_strokeSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_strokeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_strokeSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        [_strokeView addSubview:_strokeSlider];
        
        [_textTypesetView addSubview:_strokeView];
        _strokeView.hidden = YES;
    }
    return _strokeView;
}

-(void)setShadow:(float) shadowWidth atShadowColor:(UIColor *) shadowColor
{
    _currentShadowColor = shadowColor;
    _currentShadow = shadowWidth;
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setshadow:_currentShadow secondColor:shadowColor];
    }];
}

-(void)setStroke:(float) strokeWidth atStrokeColor:(UIColor *) strokeColor
{
    _currentfontStroke = strokeWidth;
    _currentfontStrokeColor = strokeColor;
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setTextStroke:_currentfontStrokeColor atStrokeSize:_currentfontStroke];
    }];
}

-(UIView*)shadowView
{
    if( !_shadowView )
    {
        _shadowView = [[UIView alloc] initWithFrame:CGRectMake(0,  _fontEditView.frame.origin.y - 44 , _fontEditView.frame.size.width, 44)];
        _shadowView.backgroundColor =  TOOLBAR_COLOR;
        
        UILabel * shadowLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (_shadowView.frame.size.height-20)/2.0, 44, 20)];
        shadowLabel.textAlignment = NSTextAlignmentRight;
        shadowLabel.font = [UIFont systemFontOfSize:12];
        shadowLabel.textColor = [UIColor whiteColor];
        shadowLabel.text = RDLocalizedString(@"透明度", nil);
        [_shadowView  addSubview:shadowLabel];
        
        _shadowSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(74, (_shadowView.frame.size.height - 30)/2.0, _textTimeView.frame.size.width - 84 - 20, 30)];
        _shadowSlider.backgroundColor = [UIColor clearColor];
        [_shadowSlider setMaximumValue:1];
        [_shadowSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_shadowSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        _shadowSlider.layer.cornerRadius = 2.0;
        _shadowSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_shadowSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        [_shadowSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_shadowSlider setValue:0];
        _shadowSlider.alpha = 1.0;
        [_shadowSlider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
        [_shadowSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [_shadowSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
        [_shadowSlider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
        [_shadowView addSubview:_shadowSlider];
        
        [_textTypesetView addSubview:_shadowView];
        _shadowView.hidden = YES;
    }
    return _shadowView;
}
//TODO: 滑动进度条
/**开始滑动
 */
- (void)beginScrub:(RDZSlider *)slider{
    if( _textVideoProgress == slider )
    {
        CGFloat current = slider.value*_rdPlayer.duration;
        if( [_delegate respondsToSelector:@selector(seekToTime:)] )
        {
            [_delegate seekToTime:current];
        }
    }
    else if( _strokeSlider == slider )
    {
        [self setStroke:slider.value*2.0 atStrokeColor:_currentfontStrokeColor];
    }
    else if( _shadowSlider == slider )
    {
        [self setShadow:slider.value*3.0 atShadowColor:_currentShadowColor];
    }
}
/**正在滑动
 */
- (void)scrub:(RDZSlider *)slider{
    if( _textVideoProgress == slider )
    {
        CGFloat current = slider.value*_rdPlayer.duration;
        if( [_delegate respondsToSelector:@selector(seekToTime:)] )
        {
            [_delegate seekToTime:current];
        }
    }
    else if( _strokeSlider == slider )
    {
        [self setStroke:slider.value*2.0 atStrokeColor:_currentfontStrokeColor];
    }
    else if( _shadowSlider == slider )
    {
        [self setShadow:slider.value*3.0 atShadowColor:_currentShadowColor];
    }
}
/**滑动结束
 */
- (void)endScrub:(RDZSlider *)slider{
    if( _textVideoProgress == slider )
    {
        CGFloat current = slider.value*_rdPlayer.duration;
        if( [_delegate respondsToSelector:@selector(seekToTime:)] )
        {
            [_delegate seekToTime:current];
        }
    }
    else if( _strokeSlider == slider )
    {
        [self setStroke:slider.value*7.0 atStrokeColor:_currentfontStrokeColor];
    }
    else if( _shadowSlider == slider )
    {
        [self setShadow:slider.value*3.0 atShadowColor:_currentShadowColor];
    }
}


-(UIScrollView*)textColorScrollView
{
    if( !_textColorScrollView )
    {
        _textColorScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(_textTypesetView.frame.size.width - 40, 0, 40, _textTypesetView.frame.size.height -  _fontEditView.frame.size.height)];
        
        [_textTypesetView addSubview:_textColorScrollView];
        
        _textColorScrollView.hidden = YES;
        
        _textColorBtnArray = [NSMutableArray<UIButton*> new];
        _textColorArray    = [NSMutableArray<UIColor*> new];
        
        [_textColorArray addObject:UIColorFromRGB(0xffffff)];
        [_textColorArray addObject:UIColorFromRGB(0x827f8e)];
        [_textColorArray addObject:UIColorFromRGB(0x4a4758)];
        [_textColorArray addObject:UIColorFromRGB(0x000000)];
        [_textColorArray addObject:UIColorFromRGB(0xa90116)];
        [_textColorArray addObject:UIColorFromRGB(0xec001c)];
        [_textColorArray addObject:UIColorFromRGB(0xff441c)];
        [_textColorArray addObject:UIColorFromRGB(0xff8514)];
        [_textColorArray addObject:UIColorFromRGB(0xffbd18)];
        [_textColorArray addObject:UIColorFromRGB(0xfff013)];
        [_textColorArray addObject:UIColorFromRGB(0xadd321)];
        [_textColorArray addObject:UIColorFromRGB(0x23c203)];
        [_textColorArray addObject:UIColorFromRGB(0x007f23)];
        [_textColorArray addObject:UIColorFromRGB(0x0ce397)];
        [_textColorArray addObject:UIColorFromRGB(0x06a998)];
        [_textColorArray addObject:UIColorFromRGB(0x00d0ff)];
        [_textColorArray addObject:UIColorFromRGB(0x1975ff)];
        [_textColorArray addObject:UIColorFromRGB(0x2c2ad4)];
        [_textColorArray addObject:UIColorFromRGB(0x4a07b7)];
        [_textColorArray addObject:UIColorFromRGB(0xb52fe3)];
        [_textColorArray addObject:UIColorFromRGB(0xff5ab0)];
        [_textColorArray addObject:UIColorFromRGB(0xde07a2)];
        [_textColorArray addObject:UIColorFromRGB(0xde0755)];
        [_textColorArray addObject:UIColorFromRGB(0x7b0039)];
        [_textColorArray addObject:UIColorFromRGB(0x422922)];
        [_textColorArray addObject:UIColorFromRGB(0x602c12)];
        [_textColorArray addObject:UIColorFromRGB(0x8b572a)];
        [_textColorArray addObject:UIColorFromRGB(0xae7a28)];
        
        [_textColorArray enumerateObjectsUsingBlock:^(UIColor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self colorBtn:obj];
        }];
        
        _textColorScrollView.contentSize = CGSizeMake(_textColorScrollView.frame.size.width, (5+30)*(_textColorArray.count) + 5);
    }
    return _textColorScrollView;
}

-(UIButton*)colorBtn:(UIColor*) color
{
    UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake( 5 , 5 + (5+30)*_textColorBtnArray.count, 30, 30)];
    colorBtn.backgroundColor = color;
    colorBtn.layer.cornerRadius = 5;
    colorBtn.layer.masksToBounds = YES;
    colorBtn.layer.borderColor = TOOLBAR_COLOR.CGColor;
    colorBtn.layer.borderWidth = 2;
    colorBtn.tag = _textColorBtnArray.count;
    [colorBtn addTarget:self action:@selector(color_Btn:) forControlEvents:UIControlEventTouchUpInside];
    
    [_textColorBtnArray addObject:colorBtn];
    
    [_textColorScrollView addSubview:colorBtn];
    
    return colorBtn;
}
-(void)color_Btn:(UIButton *) btn
{
    [_textColorBtnArray enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( obj.tag == btn.tag )
            obj.layer.borderColor = Main_Color.CGColor;
        else
            obj.layer.borderColor = TOOLBAR_COLOR.CGColor;
    }];
    
    if( (_shadowView != nil) && !_shadowView.hidden )
        [self setShadow:_currentShadow atShadowColor:btn.backgroundColor];
    else if( (_strokeView != nil) && !_strokeView.hidden )
        [self setStroke:_currentfontStroke atStrokeColor:btn.backgroundColor];
    else
        [self setSelectTextColor:btn.backgroundColor];
}
-(void)setSelectTextColor:(UIColor *) color
{
    _currentfontColor = color;
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if( obj.selectBtn.isSelected )
            [obj setTextColor:_currentfontColor];
    }];
}
#pragma makr- 字体
-(UIScrollView*)textFontScrollView
{
    if( !_textFontScrollView )
    {
        _textFontScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(_textTypesetView.frame.size.width - 130, 0, 130, _textTypesetView.frame.size.height -  _fontEditView.frame.size.height)];
        
        _fonts = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
        _fontIconList = [NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath];
        
        [self initFontIconListView];
        _textFontScrollView.hidden = YES;
        _textFontScrollView.backgroundColor = BOTTOM_COLOR;
        [_textTypesetView addSubview:_textFontScrollView];
    }
    return _textFontScrollView;
}
- (void)initFontIconListView{
    
    int cellcaptionTypeCount = 1;
    NSInteger indextypeCount;
    float height = 40.0;
    NSFileManager *manager = [NSFileManager defaultManager];
    for (int k = 0; k<_fonts.count; k++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [UIColor clearColor];
        [btn addTarget:self action:@selector(touchesFontListViewChild:) forControlEvents:UIControlEventTouchUpInside];
        float width = 80;
        btn.frame = CGRectMake( 0, 10 + ( 40+10 )*k , 130, 40);
        btn.layer.cornerRadius = 0;
        btn.layer.masksToBounds = YES;
        
        BOOL suc = NO;
        UIImageView *imageV = [[UIImageView alloc] init];
        imageV.contentMode = UIViewContentModeScaleAspectFit;
        imageV.frame = CGRectMake(10, 0, 110, btn.frame.size.height);
        
        imageV.backgroundColor = [UIColor clearColor];
        NSDictionary *itemDic = [_fonts objectAtIndex:k];
        BOOL hasNew = [[itemDic allKeys] containsObject:@"cover"] ? YES : NO;
        NSString *fileName = hasNew ? [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension] : itemDic[@"name"];
        NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[[NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath] objectForKey:@"name"]];
        NSString *imagePath;
        imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_1_%@_n_",fileName]];
        if(hasNew){
            [imageV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
        }else{
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            if (image) {
                imageV.image = image;
            }
        }
        
        imageV.tag = kFontTitleImageViewTag;
        
        imageV.layer.masksToBounds = YES;
        
        if(k==0){
            NSString *title = RDLocalizedString(@"默认", nil);
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, btn.frame.size.width - 50, btn.frame.size.height)];
            label.text = title;
            label.tag = 3;
            label.font = [UIFont systemFontOfSize:13];
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = Main_Color;
            imageV.hidden = YES;
            [btn addSubview:label];
        }else{
            NSString *timeunix = [NSString stringWithFormat:@"%ld",[(hasNew ? itemDic[@"updatetime"] : itemDic[@"timeunix"]) integerValue]];
            
            
            NSString *configPath = kFontCheckPlistPath;
            NSMutableDictionary *configDic = [[NSMutableDictionary alloc] initWithContentsOfFile:configPath];
            BOOL check = [timeunix isEqualToString:[configDic objectForKey:fileName]] ? YES : NO;
            
            NSString *path = [self pathForURL_font:fileName extStr:@"ttf" hasNew:hasNew];
            
            if(![manager fileExistsAtPath:path] || !check){
                NSError *error;
                if([manager fileExistsAtPath:path]){
                    [manager removeItemAtPath:path error:&error];
                    NSLog(@"error:%@",error);
                }
            }
            fileName = hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent: [[itemDic[@"file"] lastPathComponent] stringByDeletingPathExtension]] : itemDic[@"name"];
            
            suc = [self hasCachedFont:fileName extStr:@"ttf" hasNew:hasNew];
        }
        
        {
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
            imageV.frame = CGRectMake(10, 0, (btn.frame.size.width-10-accessory.size.width), btn.frame.size.height);
        }
        
        if(_fontResourceURL.length>0){
            UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"];
            UIImageView *markV = [[UIImageView alloc] initWithFrame:CGRectMake(btn.frame.size.width - accessory.size.width, (btn.frame.size.height-accessory.size.height)/2, accessory.size.width, accessory.size.height)];
            markV.backgroundColor = [UIColor clearColor];
            markV.tag = 50000;
            [markV setImage:accessory];
            [btn addSubview:markV];
            markV.hidden = YES;
            imageV.frame = CGRectMake(10, 0, (btn.frame.size.width-accessory.size.width), btn.frame.size.height);
        }
        
        
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        btn.tag = k+kFONTCHILDTAG;
        UIView *span = [[UIView alloc] initWithFrame:CGRectMake(0, btn.frame.size.height-1, btn.frame.size.width, 1)];
        span.backgroundColor = UIColorFromRGB(NV_Color);
        
        [btn addSubview:imageV];
        [btn addSubview:span];
        [_textFontScrollView addSubview:btn];
    }
    _textFontScrollView.contentSize = CGSizeMake( 100, (40+10)*_fonts.count+10);
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

/**下载字幕和字体*/
- (void)downloadFile:(NSString *)fileUrl
           cachePath:(NSString *)cachePath
            fileName:(NSString *)fileName
            timeunix:(NSString *)timeunix
              sender:(UIView *)sender
            progress:(void(^)(float progress))progressBlock
         finishBlock:(void(^)())finishBlock
           failBlock:(void(^)(void))failBlock
{
    if(!fileUrl){
        return;
    }
    UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
    CGRect rect = CGRectMake(sender.frame.size.width-accessory.size.width, sender.frame.size.height - accessory.size.height, accessory.size.width, accessory.size.height);
    RDSectorProgressView *ddprogress = [[RDSectorProgressView alloc] initWithFrame:rect];
    
    [sender addSubview:ddprogress];
    
    NSString *url_str=[NSString stringWithString:[fileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSString * path = cachePath;
    __weak typeof(self) weakSelf= self;
    
    NSString *cacheFolderPath = [path stringByDeletingLastPathComponent];
    [RDFileDownloader downloadFileWithURL:url_str cachePath:cacheFolderPath httpMethod:GET progress:^(NSNumber *numProgress) {
        [ddprogress setProgress:[numProgress floatValue]];
    } finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载完成");
            
            NSString *openzipPath;
            [RDHelpClass OpenZip:fileCachePath unzipto:[fileCachePath stringByDeletingLastPathComponent] caption:NO];
            
            NSString *fname = fileName;
            if(fname.length == 0){
                fname = [[fileCachePath stringByDeletingLastPathComponent] lastPathComponent];
            }
            openzipPath = [kFontFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",fname]];
            if([[[NSFileManager defaultManager] contentsOfDirectoryAtPath:openzipPath error:nil] count]>0){
                NSString *path = kFontCheckPlistPath;
                NSMutableDictionary *checkConfigDic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                if(!checkConfigDic){
                    checkConfigDic = [[NSMutableDictionary alloc] init];
                }
                if(timeunix.length==0 || !timeunix){
                    [checkConfigDic setObject:@"2015-02-03" forKey:fname];
                }else{
                    [checkConfigDic setObject:timeunix forKey:fname];
                }
                [checkConfigDic writeToFile:path atomically:YES];
                
                [ddprogress removeFromSuperview];
                finishBlock();
            }else{
                StrongSelf(self);
                NSLog(@"下载失败");
                [strongSelf.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                [strongSelf.hud show];
                [strongSelf.hud hideAfter:2];
                
                [ddprogress removeFromSuperview];
                sender.hidden = NO;
                failBlock();
            }
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载失败");
            [self.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
            
            [ddprogress removeFromSuperview];
            sender.hidden = NO;
            failBlock();
        });
    }];
}
- (NSString *)pathForURL_font_down:(NSString *)name extStr:(NSString *)extStr{
    return [NSString stringWithFormat:@"%@/%@.%@",kFontFolder,name,extStr];
}
/**选择字体
 */
- (void)touchesFontListViewChild:(UIButton *)sender{
    if(!sender){
        sender = [_textFontScrollView viewWithTag:kFONTCHILDTAG + _selectFontItemIndex];
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
        [self setFont:index];
    }else if(!suc){
        NSString *time = [NSString stringWithFormat:@"%ld",[(hasNew ? itemDic[@"updatetime"] : itemDic[@"timeunix"]) integerValue]];
        
        NSString * path = [self pathForURL_font_down:fileName extStr: hasNew ? [[itemDic[@"file"] lastPathComponent] pathExtension] : pExtension];
        if(![[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingLastPathComponent]]){
            [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        [self downloadFile:(hasNew ? itemDic[@"file"] : itemDic[@"caption"]) cachePath:path fileName:hasNew ? @"" : fileName timeunix:time sender:imageView progress:^(float progress) {
            
        }  finishBlock:^{
            imageView.hidden = YES;
            [imageView removeFromSuperview];
            [self touchesFontListViewChild:sender];
        } failBlock:^{
            imageView.hidden = NO;
        }];
    }else{
        _selectFontItemIndex = index;
        [self setFont:index];
    }
}

//根据ID设置字体
- (void)setFont:(NSInteger)index{
    NSString *selectFontName;
    
    for (int k=0;k<self.fonts.count;k++) {
        
        UIButton *sender = (UIButton *)[_textFontScrollView viewWithTag:k + kFONTCHILDTAG];
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
                NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[[NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath] objectForKey:@"name"]];
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
        
       self.currentfontName = selectFontName;
        
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
    
    self.currentfontName = selectFontName;
}

-(void)setCurrentfontName:(NSString *) currentfontName
{
    _currentfontName = currentfontName;
    
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj setTextFont:_currentfontName];
        
    }];
}


#pragma mark- 文本操作
-(void)Select_Call
{
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setSelect:YES];
    }];
}
-(void)Cancel_Select
{
    _textCancelSelectBtn.hidden = YES;
    _textSelectCallBtn.hidden = YES;
    
    _textCarryOutBtn.hidden = NO;
    _textBackBtn.hidden = NO;
    
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setSelect:NO];
    }];
    
    _currentTextEditTag = -1;
    _strokeView.hidden = YES;
    _shadowView.hidden = YES;
    _textFontScrollView.hidden = YES;
    _textColorScrollView.hidden = YES;
}

-(void)CreateEditTxtView
{
    if( !_editTxtView )
    {
        _editTxtView = [[UIView alloc] initWithFrame:CGRectMake(0,kHEIGHT - 44, kWIDTH, 44)];
        [self addSubview:_editTxtView];
        _editTxtView.hidden = YES;
        _editTxtView.backgroundColor = TOOLBAR_COLOR;
        confirmEditTxtBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        confirmEditTxtBtn.exclusiveTouch = YES;
        confirmEditTxtBtn.backgroundColor = [UIColor clearColor];
        confirmEditTxtBtn.frame = CGRectMake(kWIDTH - 69, 0, 64, 44);
        confirmEditTxtBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [confirmEditTxtBtn setTitleColor:Main_Color forState:UIControlStateNormal];
        [confirmEditTxtBtn setTitle:RDLocalizedString(@"确定", nil) forState:UIControlStateNormal];
        [confirmEditTxtBtn addTarget:self action:@selector(confirm_EditTxt) forControlEvents:UIControlEventTouchUpInside];
        [_editTxtView addSubview:confirmEditTxtBtn];
    }
}
-(void)confirm_EditTxt
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}
#pragma mark- UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSInteger existedLength = textField.text.length;
    NSInteger selectedLength = range.length;
    NSInteger replaceLength = string.length;
    NSInteger pointLength = existedLength - selectedLength + replaceLength;
    //超过8位 就不能在输入了
    if (pointLength > 7) {
        return NO;
    }else{
        
        if( pointLength > 0 )
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_textTypesetViewArray[textField.tag] setEndle:false];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_textTypesetViewArray[textField.tag] setEndle:true];
            });
        }
        return YES;
    }
    
}

- (int)getRandomNumber:(int)from to:(int)to {
    return (int)(from + (arc4random() % (to - from + 1)));
}

- (NSRange) selectedRange:(UITextField *)textField
{
    UITextPosition* beginning = textField.beginningOfDocument;
    
    UITextRange* selectedRange = textField.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [textField offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if( textField.text.length > 0 )
        _isDeleteRow = false;
    else
        _isDeleteRow = true;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField.text.length > 0)
    {
        _isRenewRotate = true;
        [self textObjectSave];
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        RDTextObject *textObject = [_textObjectViewArray[textField.tag] mutableCopy];
        
        if( CMTimeGetSeconds(textObject.AnimationTime) != 0 )
        {
            textObject.startTime = textObject.AnimationTime;
            textObject.AnimationTime = kCMTimeZero;
        }
        
//        if(
        textObject.textRadian = 0;
//           )
//            textObject.textRadian = [self getRandomNumber:-1 to:1]*(90.0/180.0*3.14);
//        else if( textObject.textRadian > 0 )
//            textObject.textRadian = [self getRandomNumber:-1 to:0]*(90.0/180.0*3.14);
//        else
//            textObject.textRadian = [self getRandomNumber:0 to:1]*(90.0/180.0*3.14);
        NSRange range = [self selectedRange:textField];
        
        range.length = textField.text.length - range.location;
        
        if( range.length == 0 )
            textObject.strText = @"";
        else
        {
            if( range.length < textField.text.length )
            {
            _textObjectViewArray[textField.tag].strText = [NSString stringWithFormat:@"%@",[textObject.strText substringWithRange:NSMakeRange(0, range.location)]];
            }
            textObject.strText = [NSString stringWithFormat:@"%@",[[textObject.strText substringWithRange:range] mutableCopy]];
        }
        [_textObjectViewArray insertObject:textObject atIndex:textField.tag+1];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
            [self initScrollView];
            _editTxtView.frame = CGRectMake(0,kHEIGHT - 44, kWIDTH, 44);
            [_textTypesetViewArray[textField.tag+1].textField becomeFirstResponder];
//        });
    }
    
    return NO;
}

#pragma mark- keyInputTextFieldDelegate
- (void) deleteBackward:(UITextFieldKeybordDelete *) textField
{
    if( textField.text.length == 0 )
    {
        if(_isDeleteRow)
        {
            _isRenewRotate = true;
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            [self textObjectSave];
            
            CMTime     startTime = _textObjectViewArray[textField.tag].startTime;
            CMTime     AnimationTime = _textObjectViewArray[textField.tag].AnimationTime;
            CMTime     showTime =  _textObjectViewArray[textField.tag].showTime;
            
            [_textObjectViewArray removeObjectAtIndex:textField.tag];
            [self initScrollView];
            _editTxtView.frame = CGRectMake(0,kHEIGHT - 44, kWIDTH, 44);
            
            
            
            if( textField.tag > 0 )
                [_textTypesetViewArray[textField.tag-1].textField becomeFirstResponder];
            else
                [_textTypesetViewArray[textField.tag].textField becomeFirstResponder];
            
            if( textField.tag > 0 )
                _textObjectViewArray[textField.tag-1].showTime = showTime;
            else
            {
                _textObjectViewArray[textField.tag].startTime = startTime;
                _textObjectViewArray[textField.tag].AnimationTime = AnimationTime;
            }
            
            
            _isDeleteRow = false;
        }
        else
        {
            _isDeleteRow = true;
        }
    }
}

#pragma mark- 文本编辑
#pragma mark- 文本排版
-( UIView * )textTypesetView
{
    if( !_textTypesetView )
    {
        _textTypesetView = [[UIView alloc] initWithFrame:CGRectMake(0, _textTimeView.frame.size.height + _textTimeView.frame.origin.y, kWIDTH, self.frame.size.height - _textTimeView.frame.size.height - _textTimeView.frame.origin.y)];
        [_textTypesetView addSubview:self.textTypesetScrollView];
        [_textTypesetView addSubview:self.fontEditView];
    }
    return _textTypesetView;
}

-(UIScrollView*)textTypesetScrollView
{
    if( !_textTypesetScrollView )
    {
        _textTypesetScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _textTypesetView.frame.size.width, _textTypesetView.frame.size.height - kToolbarHeight - 21 )];
        _textTypesetScrollView.backgroundColor = [UIColor clearColor];
        _textTypesetScrollView.tag = -1;
        _textTypesetScrollView.delegate = self;
        _textTypesetScrollView.showsVerticalScrollIndicator = NO;
        _textTypesetScrollView.showsHorizontalScrollIndicator = NO;
        
        _textTypesetScrollView.contentSize = CGSizeMake(0, _textTypesetScrollView.frame.size.height-40 + 40*5);
    }
    return _textTypesetScrollView;
}

-(void)initScrollView
{
    if( _textTypesetViewArray != nil )
    {
        [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
            obj = nil;
        }];
        [_textTypesetViewArray removeAllObjects];
        _textTypesetViewArray = nil;
    }
    
    _textTypesetViewArray = [NSMutableArray<UITextTypesetViewCell *> new];
    
    [_textObjectViewArray enumerateObjectsUsingBlock:^(RDTextObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [_textTypesetViewArray addObject:[self CreateTextTypesetView:obj atIndex:(int)idx]];
        [_textTypesetScrollView addSubview:_textTypesetViewArray[_textTypesetViewArray.count-1]];
        [_textTypesetViewArray[_textTypesetViewArray.count-1] dottedLine: (idx == (_textObjectViewArray.count-1))?false:true ];
        
    }];
    
    _textTypesetScrollView.contentSize = CGSizeMake(0, _textTypesetScrollView.frame.size.height-(50+5) + (50+5)*_textTypesetViewArray.count);
}

-(UITextTypesetViewCell *)CreateTextTypesetView:(RDTextObject *) textObject atIndex:(int) index
{
    UITextTypesetViewCell * textTypesetView = [[UITextTypesetViewCell alloc] initWithFrame:CGRectMake(0, index*50, _textTypesetScrollView.frame.size.width - 90, 50)];
    
    textTypesetView.delegate = self;
    [textTypesetView setTextFieldTag:index];
    [textTypesetView setText:textObject.strText];
    textTypesetView.textObject = [textObject copy];
    textTypesetView.textField.delegate = self;
    textTypesetView.textField.keyInputDelegate = self;
    return textTypesetView;
}
#pragma mark- UITextTypesetViewCellDelegate
-(void)select
{
    _currentTextEditTag = -1;
    __block bool isShow = false;
    
    [_textTypesetViewArray enumerateObjectsUsingBlock:^(UITextTypesetViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( obj.selectBtn.isSelected )
            isShow = true;
    }];
    
    [_mutabArray enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selected = NO;
    }];
    _strokeView.hidden = YES;
    _shadowView.hidden = YES;
    _textFontScrollView.hidden = YES;
    if( isShow )
    {
        self.textColorScrollView.hidden = NO;
        _textCancelSelectBtn.hidden = NO;
        _textSelectCallBtn.hidden = NO;
        _textBackBtn.hidden = YES;
        _textCarryOutBtn.hidden = YES;
    }
    else
    {
        self.textColorScrollView.hidden = YES;
        _textCancelSelectBtn.hidden = YES;
        _textSelectCallBtn.hidden = YES;
        _textBackBtn.hidden = NO;
        _textCarryOutBtn.hidden = NO;
    }
}
#pragma mark- UIScrollViewDelegate
@end
