//
//  toni_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "toni_editCollageView.h"

@interface toni_editCollageView ()<UIAlertViewDelegate>
{
    NSMutableArray<UIImageView *>   *TrackImageArray;        //调色显示图片
    NSMutableArray<NSString *>      *InitProgressArray;         //调色初始值数组
    NSMutableArray<NSString *>      *ProgressInitArray;         //调色默认值
    NSMutableArray<UISlider *>      *SliderArray;               //调色滚动条数组
    UIScrollView                    *AdjusetScrollView;         //调色
    
    float                           currentFontSize;                     //显示当前修改的字体大小
    UILabel                         *currentValueLbl;                     //显示正在修改的数值
    
    UIButton                        *ContrastBtn;               //对比按钮
}
@property(nonatomic       )UIAlertView      *commonAlertView;
@end

@implementation toni_editCollageView

#pragma mark--提示
-(void)ArerShow:(NSString *)str atValue:(NSString *) strValue
{
    if(currentValueLbl != nil)
    {
        if( strValue )
            currentValueLbl.text = [NSString stringWithFormat:@"%@ %@",str,strValue];
        else
            currentValueLbl.text = str;
        currentValueLbl.hidden = NO;
    }
    else
    {
        
        currentValueLbl = [[UILabel alloc] initWithFrame:CGRectMake((kWIDTH - 80)/2.0, 0, 80, 20)];
        currentValueLbl.textAlignment = NSTextAlignmentCenter;
        currentValueLbl.textColor = [UIColor whiteColor];
        //阴影颜色
        currentValueLbl.layer.shadowColor = [UIColor blackColor].CGColor;
        //阴影偏移量
        currentValueLbl.layer.shadowOffset = CGSizeMake(0, 1);
        //阴影不透明度
        currentValueLbl.layer.shadowOpacity = 0.5;
        //阴影半径
        currentValueLbl.layer.shadowRadius = 2;
        if( strValue != nil )
            currentValueLbl.text = strValue;
        currentValueLbl.font = [UIFont systemFontOfSize:currentFontSize];
        [AdjusetScrollView addSubview:currentValueLbl];
        
    }
}

+ (toni_editCollageView *)initWithFrame:(CGRect)frame atVVAsset:(VVAsset *)  vvAsset
{
    toni_editCollageView * collage_toni_View =  [[toni_editCollageView alloc] initWithFrame:frame];
    if ( self )
    {
        collage_toni_View.backgroundColor = TOOLBAR_COLOR;
        collage_toni_View.currentVvAsset = vvAsset;
        [collage_toni_View initBottomView];
        [collage_toni_View initAdjustScrollView];
        [collage_toni_View initToolBarView];
    }
    return collage_toni_View;
}


//- (instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if ( self )
//    {
//        self.backgroundColor = TOOLBAR_COLOR;
//
//        [self initBottomView];
//        [self initAdjustScrollView];
//        [self initToolBarView];
//        [RDHelpClass animateView: AdjusetScrollView atUP:NO];
//    }
//    return self;
//}

- (void)initToolBarView{
    UIView *toolBarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - kToolbarHeight, kWIDTH, kToolbarHeight)];
    toolBarView.backgroundColor = TOOLBAR_COLOR;
    [self addSubview:toolBarView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    titleLbl.text = RDLocalizedString(@"调色", nil);
    titleLbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    titleLbl.font = [UIFont boldSystemFontOfSize:17.0];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [toolBarView addSubview:titleLbl];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 0, 44, 44);
    [cancelBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:cancelBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
    finishBtn.frame = CGRectMake(kWIDTH - 44, 0, 44, 44);
    [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [toolBarView addSubview:finishBtn];
    [RDHelpClass animateView:toolBarView atUP:NO];
}
#pragma mark-调色 对应的控件 滚动条 初始化
-(void)initAdjustScrollView
{
    AdjusetScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 110 - kToolbarHeight , kWIDTH,110)];
    AdjusetScrollView.showsHorizontalScrollIndicator = NO;
    AdjusetScrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:AdjusetScrollView];
    
    ProgressInitArray = [NSMutableArray array];
    SliderArray = [NSMutableArray array];
    InitProgressArray = [NSMutableArray array];
    TrackImageArray = [NSMutableArray array];
    
    _featuresScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20+30, kWIDTH, 60)];
    _featuresScroll.showsVerticalScrollIndicator = NO;
    _featuresScroll.showsHorizontalScrollIndicator = NO;
    float toolItemBtnWidth = MAX(_featuresScroll.frame.size.width/5, 60 + 5);
    toolItemBtnWidth -= 10;
    _featuresScroll.contentSize = CGSizeMake(toolItemBtnWidth*7 + 25, 0);
    [AdjusetScrollView addSubview:_featuresScroll];
    
//    [self initBtn:0 atString:@"还原"];
    
    //亮度
    [self initBtn:0 atString:@"亮度"];
    [self InitSliberValue:Adjust_Brightness
                  atValue:_currentVvAsset.brightness
              atInitValue:0.0
              atFileValue:_currentVvAsset.brightness
                   atName:@"亮度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
//    SliderArray[SliderArray.count-1].hidden = NO;
    
    
    //对比度
    [self initBtn:1 atString:@"对比度"];
    [self InitSliberValue:Adjust_Contrast
                  atValue:(_currentVvAsset.contrast - 1.0)
              atInitValue:1.0 - 1.0
              atFileValue:_currentVvAsset.contrast
                   atName:@"对比度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    //饱和度
    [self initBtn:2 atString:@"饱和度"];
    [self InitSliberValue:Adjust_Saturation
                  atValue:(_currentVvAsset.saturation/2.0) - 0.5
              atInitValue:(float)( 1.0 /2.0) - 0.5
              atFileValue:_currentVvAsset.saturation
                   atName:@"饱和度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    // 锐度
    [self initBtn:3 atString:@"锐度"];
    [self InitSliberValue:Adjust_Sharpness
                  atValue:(_currentVvAsset.sharpness + 4.0)/8.0 - 0.5
              atInitValue:(float)(0.0 + 4.0)/8.0 - 0.5
              atFileValue:_currentVvAsset.sharpness
                   atName:@"锐度"
               atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    // 色温
    [self initBtn:4 atString:@"色温"];
    [self InitSliberValue:Adjust_WhiteBalance
                  atValue:(_currentVvAsset.whiteBalance + 1.0)/2.0 - 0.5
              atInitValue:(float)(0.0 + 1.0)/2.0 - 0.5
              atFileValue:_currentVvAsset.whiteBalance
                   atName:@"色温" atMaxValue:0.5
               atMinValue:-0.5
               atIsMiddle:YES];
    //暗角
    [self initBtn:5 atString:@"暗角"];
    [self InitSliberValue:Adjust_Vignette
                  atValue:_currentVvAsset.vignette
              atInitValue:0.0
              atFileValue:_currentVvAsset.vignette
                   atName:@"暗角"
               atMaxValue:1.0
               atMinValue:0.0
               atIsMiddle:NO];
    
    AdjusetScrollView.contentSize=  CGSizeMake(0, 110);
    
    [self clickToolItemBtn:[_featuresScroll viewWithTag:0]];
}

#pragma mark-滑杆控件初始化
-(void)InitSliberValue:(AdjustType) adjustType atValue:(float) value atInitValue:(float) InitValue atFileValue:(float) flieValue atName:(NSString *) name atMaxValue:(float) MaximumValue atMinValue:(float) MinValue atIsMiddle:(BOOL) IsMiddle
{
    NSString * str = @"选中";
    if( value == InitValue )
        str = @"默认";
    
    
    
    [InitProgressArray addObject:[NSString stringWithFormat:@"%.1f",flieValue] ];
    [ ProgressInitArray addObject: [NSString stringWithFormat:@"%.1f",InitValue] ];
    [SliderArray addObject:[self InitSlider:adjustType atMaxValue:MaximumValue atMinValue:MinValue atValue:value
                                    atImage:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@%@@3x",name,str] Type:@"png"] atIsMiddle:IsMiddle atHeight:AdjusetScrollView.bounds.size.height/2.5]];
}

-(void)clickToolItemBtn:(UIButton *) btn
{
    [SliderArray enumerateObjectsUsingBlock:^(UISlider * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.hidden = YES;
        
    }];
    [TrackImageArray enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.hidden = YES;
        
    }];
//    if( btn.tag == 0 )
//    {
//        [self SetReduction];
//    }
//    else
    {
        int i = btn.tag;
        SliderArray[i].hidden = NO;
        TrackImageArray[i].hidden = NO;
    }
    
    [_featuresScroll.subviews enumerateObjectsUsingBlock:^(__kindof UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == btn.tag){
            obj.selected = YES;
        }else{
            obj.selected = NO;
        }
    }];
}

-(void)initBtn:(int) idx atString:(NSString *) title
{
    float toolItemBtnWidth = MAX(_featuresScroll.frame.size.width/5, 60 + 5);
    toolItemBtnWidth -= 10;
    
    UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    toolItemBtn.tag = idx;
    toolItemBtn.backgroundColor = [UIColor clearColor];
    toolItemBtn.exclusiveTouch = YES;
    toolItemBtn.frame = CGRectMake(idx * toolItemBtnWidth + 25, 0, toolItemBtnWidth, _featuresScroll.frame.size.height);
    [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
    NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@默认@3x", title] Type:@"png"];
    [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
    imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@选中@3x", title] Type:@"png"];
    [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
    [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
    [toolItemBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
    [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (toolItemBtnWidth - 44)/2.0, 16, (toolItemBtnWidth - 44)/2.0)];
    [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
    [_featuresScroll addSubview:toolItemBtn];
}

#pragma mark-设置滚动条设置
-(UISlider *)InitSlider:(int) index atMaxValue:(float) MaximumValue atMinValue:(float) MinValue atValue:(float) value atImage:(NSString *) Image atIsMiddle:(BOOL) IsMiddle atHeight:(float) height
{
    RDZSlider * slider = [[RDZSlider alloc] init];
    slider.frame = CGRectMake( 40, 20, kWIDTH - 80, 30);
    slider.layer.cornerRadius = 2.0;
    slider.layer.masksToBounds = YES;
    slider.maximumValue = MaximumValue;
    slider.minimumValue = MinValue;
    slider.value = value;
    slider.tag = index;
    UIImage *theImage = nil;
    
    
    
    
    slider.hidden = YES;
    
    if( value == [ProgressInitArray[slider.tag] floatValue] )
       theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]];
    else
       theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球2@3x" Type:@"png"]];
    
    [slider setThumbImage:theImage forState:UIControlStateNormal];
    if( IsMiddle )
        [slider setMinimumTrackImage: [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道1@1x" Type:@"png"]] forState:UIControlStateNormal];
    else
        [slider setMinimumTrackImage: [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道2@1x" Type:@"png"]] forState:UIControlStateNormal];
    
    [slider setMaximumTrackImage: [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道1@1x" Type:@"png"]] forState:UIControlStateNormal];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    //[slider setThumbImage: [UIImage imageNamed: forState:UIControlStateHighlighted];
    //滑块拖动时的事件
    //[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    //滑动拖动后的事件
    //[slider addTarget:self action:@selector(ChangeSlider:) forControlEvents:UIControlEventValueChanged];
    
    [slider addTarget:self action:@selector(beginScrub:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(endScrub:) forControlEvents:UIControlEventTouchCancel];
    [AdjusetScrollView addSubview:slider];
    
    UIImageView * imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake( slider.frame.size.width/2.0 ,(slider.frame.size.height-3.0)/2.0, 0.1, 0.1)];
    imageView1.backgroundColor = Main_Color;
    imageView1.hidden = YES;
    //    imageView1.image = [UIImage imageNamed: [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_轨道2@1x" Type:@"png"]];
    [TrackImageArray addObject:imageView1];
    [AdjusetScrollView addSubview:imageView1];
    
    if(IsMiddle)
    {
        if( slider.value <= 0.0 )
        {
            float with = slider.frame.size.width/2.0 - (slider.frame.size.width + 38)*( (slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue) ) ;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3) ];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0,0, 3)];
            }
            
        }
        else
        {
            float with = (slider.frame.size.width  - 19 )*((slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue)) - slider.frame.size.width/2.0;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3)];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, 0, 3)];
            }
        }
    }
    
    return slider;
}

- (void)initBottomView {
    ContrastBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    ContrastBtn.frame = CGRectMake(kWIDTH - (64 + 15), self.bounds.size.height - 35 - 110 - kToolbarHeight + ( 35 - 28 )/2.0, 64, 28);
    [ContrastBtn setTitle:RDLocalizedString(@"toning_compare", nil) forState:UIControlStateNormal];
    [ContrastBtn setTitleColor:Main_Color forState:UIControlStateNormal];
    [ContrastBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateHighlighted];
    ContrastBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    ContrastBtn.layer.cornerRadius = 28/2.0;
    ContrastBtn.layer.borderColor = UIColorFromRGB(0x626267).CGColor;
    ContrastBtn.layer.borderWidth = 1.0;
    [ContrastBtn addTarget:self action:@selector(Contrast_Btn_click) forControlEvents:UIControlEventTouchDown];
    [ContrastBtn addTarget:self action:@selector(Contrast_Btn_Release) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self addSubview:ContrastBtn];
    
    UIButton * reductionBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, self.bounds.size.height - 35 - 110 - kToolbarHeight + ( 35 - 28 )/2.0, 50, 28)];
    reductionBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [reductionBtn setTitle:RDLocalizedString(@"还原", nil) forState:UIControlStateNormal];
    [reductionBtn setTitleColor:UIColorFromRGB(0xbebebe) forState:UIControlStateNormal];
    [reductionBtn setTitleColor:Main_Color  forState:UIControlStateHighlighted];
    [reductionBtn addTarget:self action:@selector(SetReduction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:reductionBtn];
}


- (void)back{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_ADJUST isSave:NO];
    }
}
#pragma mark-还原设置
-( void )SetReduction
{
    //亮度
    [SliderArray[0] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[0] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    //对比度
    [SliderArray[1] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[1] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    //饱和度
    [SliderArray[2] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[2] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    // 锐度
    [SliderArray[3] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[3] setFrame:CGRectMake( 1,1, 0.1, 0.1) ];
    // 色温
    [SliderArray[4] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[4] setFrame:CGRectMake( 1,1, 0.1, 0.1) ];
    //暗角
    [SliderArray[5] setThumbImage:[UIImage
                                   imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]]
                         forState:UIControlStateNormal];
    [TrackImageArray[5] setFrame:CGRectMake( 0,0, 0.1, 0.1) ];
    
    //亮度
    SliderArray[0].value  = [ProgressInitArray[0] floatValue];
    _currentVvAsset.brightness = SliderArray[0].value;
    //对比度
    SliderArray[1].value  = [ProgressInitArray[1] floatValue];
    _currentVvAsset.contrast = (SliderArray[1].value + 1.0);
    //饱和度
    SliderArray[2].value  = [ProgressInitArray[2] floatValue];
    _currentVvAsset.saturation = (SliderArray[2].value+0.5) * 2.0;
    // 锐度
    SliderArray[3].value  = [ProgressInitArray[3] floatValue];
    _currentVvAsset.sharpness = (SliderArray[3].value + 0.5)*8.0 - 4.0;
    // 色温
    SliderArray[4].value  = [ProgressInitArray[4] floatValue];
    _currentVvAsset.whiteBalance = (SliderArray[4].value + 0.5)*2.0 - 1.0;
    //暗角
    SliderArray[5].value  = [ProgressInitArray[5] floatValue];
    _currentVvAsset.vignette = SliderArray[5].value;
    
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            //亮度
            asset.brightness = self->_currentVvAsset.brightness;
            //对比度
            asset.contrast = self->_currentVvAsset.contrast;
            //饱和度
            asset.saturation = self->_currentVvAsset.saturation;
            // 锐度
            asset.sharpness = self->_currentVvAsset.sharpness;
            // 色温
            asset.whiteBalance = self->_currentVvAsset.whiteBalance;
            //暗角
            asset.vignette = self->_currentVvAsset.vignette;
        }];
        *stop1 = YES;
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
        }
        if( _pasterView )
        {
            [self performSelector:@selector(ImageRef) withObject:nil afterDelay:0.2];
        }
    });
}

#pragma mark-调色 事件
#pragma mark-还原按钮事件
-(void)Reduction_Btn
{
    [self initCommonAlertViewWithTitle:RDLocalizedString(@"确认要重置吗?",nil)
                               message:@""
                     cancelButtonTitle:RDLocalizedString(@"取消",nil)
                     otherButtonTitles:RDLocalizedString(@"确定",nil)
                          alertViewTag:1];
}
#pragma mark-对比按钮事件
#pragma mark--点击事件
-(void)Contrast_Btn_click
{
    
    [self ArerShow:RDLocalizedString(@"原始效果",nil) atValue:nil];
    
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            //亮度
            asset.brightness    =   ([self->ProgressInitArray[0] floatValue]);
            //对比度
            asset.contrast      =   ([self->ProgressInitArray[1] floatValue] + 1.0);
            //饱和度
            asset.saturation    =   ([self->ProgressInitArray[2] floatValue]+0.5) * 2.0;
            // 锐度
            asset.sharpness     =   ([self->ProgressInitArray[3] floatValue] + 0.5)*8.0 - 4.0;
            // 色温
            asset.whiteBalance  =   ([self->ProgressInitArray[4] floatValue] + 0.5)*2.0 - 1.0;
            //暗角
            asset.vignette      =   ([self->ProgressInitArray[5] floatValue]);
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
        }
        if( _pasterView )
        {
            [self performSelector:@selector(ImageRef) withObject:nil afterDelay:0.2];
        }
    });
}

#pragma mark--关闭提示
- (void)performDismiss{
    currentValueLbl.hidden = YES;
}


#pragma mark--松开事件
-(void)Contrast_Btn_Release
{
    
    [self performDismiss];
    [[_videoCoreSDK getScenes] enumerateObjectsUsingBlock:^(RDScene *  _Nonnull scene, NSUInteger idx1, BOOL * _Nonnull stop1) {
        [scene.vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull asset, NSUInteger idx2, BOOL * _Nonnull stop2) {
            //亮度
            asset.brightness    =   (self->SliderArray[0].value);
            //对比度
            asset.contrast      =   (self->SliderArray[1].value + 1.0);
            //饱和度
            asset.saturation    =   (self->SliderArray[2].value+0.5) * 2.0 ;
            // 锐度
            asset.sharpness     =   (self->SliderArray[3].value + 0.5)*8.0 - 4.0;
            // 色温
            asset.whiteBalance  =   (self->SliderArray[4].value + 0.5)*2.0 - 1.0;
            //暗角
            asset.vignette      =   (self->SliderArray[5].value);
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![self->_videoCoreSDK isPlaying]){
            [self->_videoCoreSDK filterRefresh:self->_videoCoreSDK.currentTime];
        }
        if( _pasterView )
        {
            [self performSelector:@selector(ImageRef) withObject:nil afterDelay:0.2];
        }
    });
}

#pragma mark-滑动进度条
- (void)beginScrub:(UISlider *)slider{
    [self sliderValueChanged:slider];
}

- (void)scrub:(UISlider *)slider{
    [self sliderValueChanged:slider];
}

- (void)endScrub:(UISlider *)slider{
    [self sliderValueChanged:slider];
    [self performSelector:@selector(performDismiss) withObject:nil afterDelay:1.0];
}
#pragma mark-滑块和标志颜色的改变
-(void)sliderValueChanged:(UISlider *)slider
{
    AdjustType adjustType = slider.tag;
    if( adjustType != Adjust_Vignette )
    {
        if( slider.value < 0.0 )
        {
            float with = slider.frame.size.width/2.0 - (slider.frame.size.width  - 21 )*( (slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue))  - 20  ;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3) ];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 - with+ slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0,0, 3)];
            }
        }
        else
        {
            
            float with = (slider.frame.size.width  - 20 )*((slider.value - slider.minimumValue )/(slider.maximumValue - slider.minimumValue)) - slider.frame.size.width/2.0;
            if( with >= 0 )
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, with, 3)];
            }
            else
            {
                [TrackImageArray[slider.tag] setFrame:CGRectMake( slider.frame.size.width/2.0 + slider.frame.origin.x, slider.frame.origin.y + (slider.frame.size.height-3.0)/2.0 - 1.0, 0, 3)];
            }
        }
    }
    
    switch (adjustType) {
        case Adjust_Brightness:             //亮度
            [self ArerShow:RDLocalizedString(@"亮度", nil) atValue: [NSString stringWithFormat:@"%.1f",slider.value] ];
            _currentVvAsset.brightness    =   (slider.value);
            break;
        case Adjust_Contrast:               //对比度
            [self ArerShow:RDLocalizedString(@"对比度", nil) atValue: [NSString stringWithFormat:@"%.1f",slider.value + 1.0] ];
            _currentVvAsset.contrast      =   (slider.value + 1.0);
            break;
        case Adjust_Saturation:             //饱和度
            [self ArerShow:RDLocalizedString(@"饱和度", nil) atValue: [NSString stringWithFormat:@"%.1f",(slider.value+0.5) * 2.0] ];
            _currentVvAsset.saturation    =   (slider.value+0.5) * 2.0 ;
            break;
        case Adjust_Sharpness:              //锐度
            [self ArerShow:RDLocalizedString(@"锐度", nil) atValue: [NSString stringWithFormat:@"%.1f",(slider.value + 0.5)*8.0 - 4.0] ];
            _currentVvAsset.sharpness     =   (slider.value + 0.5)*8.0 - 4.0;
            break;
        case Adjust_WhiteBalance:           // 色温
            [self ArerShow:RDLocalizedString(@"白平衡", nil) atValue: [NSString stringWithFormat:@"%.1f",(slider.value + 0.5)*2.0 - 1.0] ];
            _currentVvAsset.whiteBalance  =   (slider.value + 0.5)*2.0 - 1.0;
            break;
        case Adjust_Vignette:               //暗角
            [self ArerShow:RDLocalizedString(@"暗角", nil) atValue: [NSString stringWithFormat:@"%.1f",slider.value] ];
            _currentVvAsset.vignette      =   (slider.value);
            break;
        default:
            break;
    }

    float value =  [((NSString*)ProgressInitArray[slider.tag]) floatValue];
    NSString * image = nil;
    NSString * Name = @"亮度";
    NSString * Type = @"选中";
    
    UIImage *theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球2@3x" Type:@"png"]];
    [slider setThumbImage:theImage forState:UIControlStateNormal];
    if( ((value+0.01) >=  slider.value)  && ( (value-0.01) <=  slider.value ) )
    {
        Type =  @"默认";
        UIImage *theImage = [UIImage imageNamed:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/Adjust/剪辑-调色_球1@3x" Type:@"png"]];
        [slider setThumbImage:theImage forState:UIControlStateNormal];
    }

    //组装
    switch (adjustType) {
        case Adjust_Brightness:             //亮度
            Name = [NSString stringWithFormat:@"亮度%@",Type];
            break;
        case Adjust_Contrast:               //对比度
            Name = [NSString stringWithFormat:@"对比度%@",Type];
            break;
        case Adjust_Saturation:             //饱和度
            Name = [NSString stringWithFormat:@"饱和度%@",Type];
            break;
        case Adjust_Sharpness:              //锐度
            Name = [NSString stringWithFormat:@"锐度%@",Type];
            break;
        case Adjust_WhiteBalance:           //色温
            Name = [NSString stringWithFormat:@"色温%@",Type];
            break;
        case Adjust_Vignette:               //暗角
            Name = [NSString stringWithFormat:@"暗角%@",Type];
            break;
        default:
            break;
    }
    image = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/Adjust/剪辑-调色_%@@3x",Name] Type:@"png"];
    
    if( self.currentCollage )
    {
        self.currentCollage.vvAsset.brightness = self->_currentVvAsset.brightness;
        self.currentCollage.vvAsset.contrast = self->_currentVvAsset.contrast;
        self.currentCollage.vvAsset.saturation = self->_currentVvAsset.saturation;
        self.currentCollage.vvAsset.sharpness = self->_currentVvAsset.sharpness;
        self.currentCollage.vvAsset.whiteBalance = self->_currentVvAsset.whiteBalance;
        self.currentCollage.vvAsset.vignette = self->_currentVvAsset.vignette;
        [_videoCoreSDK refreshCurrentFrame];
    }
}
/**保存
 */
- (void)save{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_ADJUST isSave:YES];
    }
}


#pragma mark-提示消息处理
- (void)initCommonAlertViewWithTitle:(nullable NSString *)title
                             message:(nullable NSString *)message
                   cancelButtonTitle:(nullable NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSString *)otherButtonTitles
                        alertViewTag:(NSInteger)alertViewTag
{
    if (_commonAlertView) {
        _commonAlertView.delegate = nil;
        _commonAlertView = nil;
    }
    _commonAlertView = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:cancelButtonTitle
                                        otherButtonTitles:otherButtonTitles, nil];
    _commonAlertView.tag = alertViewTag;
    [_commonAlertView show];
}

-(void)ImageRef
{
    [_videoCoreSDK getImageWithTime:CMTimeMake(0.2, TIMESCALE) scale:1.0 completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _pasterView.contentImage.image = nil;
            _pasterView.contentImage.image = image;
        });
    }];
}

-(void)dealloc
{
    if( TrackImageArray )
    {
        [TrackImageArray enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            obj.image = nil;
            [obj removeFromSuperview];
            obj = nil;
            
        }];
        
    }
    
    if( SliderArray )
    {
        [SliderArray enumerateObjectsUsingBlock:^(UISlider * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            [obj removeFromSuperview];
            obj = nil;
            
        }];
        
    }
    
    if( AdjusetScrollView )
    {
        [AdjusetScrollView removeFromSuperview];
        AdjusetScrollView = nil;
    }
    
    if( currentValueLbl )
    {
        [currentValueLbl removeFromSuperview];
        currentValueLbl = nil;
    }
    
    if( _commonAlertView )
    {
        [_commonAlertView removeFromSuperview];
        _commonAlertView = nil;
    }
    
}

@end
