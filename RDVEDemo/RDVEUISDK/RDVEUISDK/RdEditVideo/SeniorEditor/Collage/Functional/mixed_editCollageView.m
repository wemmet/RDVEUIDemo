//
//  mixed_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/20.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "mixed_editCollageView.h"
#import "RDAddItemButton.h"

@implementation mixed_editCollageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        
        _mixed_Array = [NSMutableArray new];
        
        [_mixed_Array addObject:@"无"];
        [_mixed_Array addObject:@"变暗"];
        [_mixed_Array addObject:@"滤色"];
        [_mixed_Array addObject:@"叠加"];
        [_mixed_Array addObject:@"正片叠底"];
        [_mixed_Array addObject:@"变亮"];
        [_mixed_Array addObject:@"强光"];
        [_mixed_Array addObject:@"柔光"];
        [_mixed_Array addObject:@"线性加深"];
        [_mixed_Array addObject:@"颜色加深"];
        [_mixed_Array addObject:@"颜色减淡"];
        
        self.mixed_ScrollView.hidden = NO;
        self.mixed_Ttansparency_slider.hidden = NO;
        
        _mixed_CloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height - kToolbarHeight, 44, 44)];
        [_mixed_CloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_mixed_CloseBtn addTarget:self action:@selector(mixed_Close_Btn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_mixed_CloseBtn];
        
        _mixed_ConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, self.frame.size.height - kToolbarHeight, 44, 44)];
        [_mixed_ConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_mixed_ConfirmBtn addTarget:self action:@selector(mixed_Confirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_mixed_ConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, self.frame.size.height - kToolbarHeight + ( 44 - 44 )/2.0, kWIDTH - 44 * 2, 44)];
        label.text = RDLocalizedString(@"混合模式", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        [self addSubview:label];
    }
    return self;
}

-( UIScrollView * )mixed_ScrollView
{
    if( !_mixed_ScrollView )
    {
        float fHeight = self.frame.size.height - kToolbarHeight;
        
        _mixed_ScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, fHeight * 0.75)];
        _mixed_ScrollView.tag = 10000;
        _mixed_ScrollView.backgroundColor = [UIColor clearColor];
        _mixed_ScrollView.showsVerticalScrollIndicator = NO;
        _mixed_ScrollView.showsHorizontalScrollIndicator = NO;
        
        float height = _mixed_ScrollView.frame.size.height * 0.7;
        
        float width = height*0.7;
        [_mixed_Array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            RDAddItemButton *fxItemBtn = [RDAddItemButton initFXframe: CGRectMake( idx * (width+15) + 10 , _mixed_ScrollView.frame.size.height * 0.2, width, height) atpercentage:0.7];
            if( idx == 0 )
                fxItemBtn.tag = idx;
            else
                fxItemBtn.tag = idx + RDBlendAIChromaColor;
            
            fxItemBtn.label.text = RDLocalizedString(obj, nil);
            UIImage * image = nil;
            if( idx == 0 )
            {
                image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无@3x" Type:@"png"]];
            }
            else{
               image = [RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"/jianji/mixed/剪辑-混合-%@", obj]];
            }
            fxItemBtn.thumbnailIV.image = image;
           
            if( idx == 0 )
            {
                fxItemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
                fxItemBtn.label.textColor = [UIColor whiteColor];
            }
            
            [_mixed_ScrollView addSubview:fxItemBtn];
            [fxItemBtn addTarget:self action:@selector(mixed_Btn:) forControlEvents:UIControlEventTouchUpInside];
            
            float ItemBtnWidth = [RDHelpClass widthForString:fxItemBtn.label.text andHeight:12 fontSize:12];
            
            if( ItemBtnWidth > fxItemBtn.label.frame.size.width )
                [fxItemBtn startScrollTitle];
            
        }];
        
        _mixed_ScrollView.delegate = self;
        
        float contentWidth = (_mixed_Array.count ) * (width+15) + 10;
        if( contentWidth <=  _mixed_ScrollView.frame.size.width )
        {
            contentWidth = _mixed_ScrollView.frame.size.width + 20;
        }
        _mixed_ScrollView.contentSize = CGSizeMake( contentWidth, 0);
        
        [self addSubview:_mixed_ScrollView];
    }
    return _mixed_ScrollView;
}

-(void)setcurrentMixedIndex:(int) mixedIndex
{
    RDAddItemButton * iteBtn = [_mixed_ScrollView viewWithTag:self.currentMixedIndex];
    
    if( iteBtn )
    {
        iteBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
        iteBtn.label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    
    iteBtn = nil;
    
    iteBtn = [_mixed_ScrollView viewWithTag:mixedIndex];
    if( iteBtn )
    {
        iteBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
        iteBtn.label.textColor = [UIColor whiteColor];
    
        self.currentMixedIndex = mixedIndex;
    }
}

-(void)mixed_Btn:(RDAddItemButton *) sender
{
    RDAddItemButton * iteBtn = [_mixed_ScrollView viewWithTag:self.currentMixedIndex];
    iteBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
    iteBtn.label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    self.currentMixedIndex = sender.tag;
    sender.thumbnailIV.layer.borderColor = Main_Color.CGColor;
    sender.label.textColor = [UIColor whiteColor];
    
    self.currentCollage.vvAsset.blendType = sender.tag;
    self.currentCollage.vvAsset.alpha = 1.0;
    [_mixed_Ttansparency_slider setValue:1.0];
    
    [_videoCoreSDK refreshCurrentFrame];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

//滤镜进度条
- (RDZSlider *)mixed_Ttansparency_slider{
    if(!_mixed_Ttansparency_slider){
        
        float fHeight = self.frame.size.height - kToolbarHeight;
        
        float height = fHeight * 0.25 ;
        
        UILabel * Label = [[UILabel alloc] init];
        Label.frame = CGRectMake(30, fHeight * 0.75 + ( height - 20 )/2.0, 50, 20);
        Label.textAlignment = NSTextAlignmentLeft;
        Label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        Label.font = [UIFont systemFontOfSize:12];
        Label.text = RDLocalizedString(@"不透明度", nil);
        [self addSubview:Label];
        
        _mixed_Ttansparency_slider = [[RDZSlider alloc] initWithFrame:CGRectMake(90, fHeight * 0.75 + ( height - 30 )/2.0, self.frame.size.width - 65 - 65, 30)];
        [_mixed_Ttansparency_slider setMaximumValue:1];
        [_mixed_Ttansparency_slider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_mixed_Ttansparency_slider setMinimumTrackImage:image forState:UIControlStateNormal];
        _mixed_Ttansparency_slider.layer.cornerRadius = 2.0;
        _mixed_Ttansparency_slider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_mixed_Ttansparency_slider setMaximumTrackImage:image forState:UIControlStateNormal];
        
        [_mixed_Ttansparency_slider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_mixed_Ttansparency_slider setValue:1.0];
        _mixed_Ttansparency_slider.alpha = 1.0;
        _mixed_Ttansparency_slider.backgroundColor = [UIColor clearColor];
        
        [_mixed_Ttansparency_slider addTarget:self action:@selector(mixed_Ttansparency_scrub) forControlEvents:UIControlEventValueChanged];
        [_mixed_Ttansparency_slider addTarget:self action:@selector(mixed_Ttansparency_endScrub) forControlEvents: UIControlEventTouchUpInside];
        [_mixed_Ttansparency_slider addTarget:self action:@selector(mixed_Ttansparency_endScrub) forControlEvents:UIControlEventTouchCancel];
        [self addSubview: _mixed_Ttansparency_slider];
    }
    return _mixed_Ttansparency_slider;
}

-(void)mixed_Ttansparency_scrub
{
    
}
-(void)mixed_Ttansparency_endScrub
{
    self.currentCollage.vvAsset.alpha = _mixed_Ttansparency_slider.value;
    [_videoCoreSDK refreshCurrentFrame];
}

-(void)dealloc
{
    if( _mixed_ScrollView )
    {
        [_mixed_ScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if( [obj isKindOfClass: [RDAddItemButton class]] )
           {
               RDAddItemButton *fxItemBtn = (RDAddItemButton*)obj;
               
               fxItemBtn.thumbnailIV.image = nil;
               
               [obj removeFromSuperview];
               obj = nil;
           }
            
        }];
    }
    
    if( _mixed_Ttansparency_slider )
    {
        [_mixed_Ttansparency_slider removeFromSuperview];
        _mixed_Ttansparency_slider = nil;
    }
}


#pragma mark- 抠图
-(void)mixed_Close_Btn
{
    
    
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_MIXEDMODE isSave:NO];
    }
}
-(void)mixed_Confirm_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_MIXEDMODE isSave:YES];
    }
}
@end
