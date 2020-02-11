//
//  editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/7.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "editCollageView.h"

@interface editCollageView()
{
    
    
    NSMutableArray          *toolItems;
}


@end

@implementation editCollageView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        [self initUI];
    }
    return self;
}

#pragma mark- 初始化 公共控件
-(void) initUI
{
    [self getToolBarItemArray];
}

-(void)getToolBarItemArray
{
    toolItems = [NSMutableArray array];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"替换",@"title",@(KPIP_REPLACE),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"截取",@"title",@(KPIP_TRIM),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"滤镜",@"title",@(kPIP_SINGLEFILTER),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"混合模式",@"title",@(kPIP_MIXEDMODE),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"调色",@"title",@(kPIP_ADJUST),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"抠图",@"title",@(kPIP_CUTOUT),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"变速",@"title",@(KPIP_CHANGESPEED),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"音量",@"title",@(kPIP_VOLUME),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"美颜",@"title",@(kPIP_BEAUTY),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"透明度",@"title",@(kPIP_TRANSPARENCY),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"删除",@"title",@(KPIP_DELETE),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"裁切",@"title",@(KPIP_EDIT),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"旋转",@"title",@(kPIP_ROTATE),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"左右翻转",@"title",@(kPIP_MIRROR),@"id", nil]];
    [toolItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"上下翻转",@"title",@(kPIP_FLIPUPANDDOWN),@"id", nil]];
    
    UIButton * _otherReturnBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 3, 60/2.0, 60 )];
    _otherReturnBtn.layer.cornerRadius = 3;
    _otherReturnBtn.layer.masksToBounds = YES;
    
    [_otherReturnBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
    [_otherReturnBtn addTarget:self action:@selector(otherReturn_Btn) forControlEvents:UIControlEventTouchUpInside];
    _otherReturnBtn.backgroundColor = UIColorFromRGB(0x202020);
    [self addSubview:_otherReturnBtn];
    
    _toolBarView =  [UIScrollView new];
    _toolBarView.frame = CGRectMake(40, 0, kWIDTH - 30, 60 );
    _toolBarView.showsVerticalScrollIndicator = NO;
    _toolBarView.showsHorizontalScrollIndicator = NO;
    [self addSubview:_toolBarView];
    NSInteger count = (toolItems.count>5)?toolItems.count:5;
    if( (count == 5) && (toolItems.count%2) == 0.0 )
    {
        count = 4;
    }
    __block float toolItemBtnWidth = MAX(kWIDTH/count, 60 + 5);//_toolBarView.frame.size.height
    __block int iIndex = kWIDTH/toolItemBtnWidth + 1.0;
    __block float width = toolItemBtnWidth;
    toolItemBtnWidth = toolItemBtnWidth - ((toolItems.count > iIndex)?(toolItemBtnWidth/2.0/(iIndex)):0);
    __block float contentsWidth = 0;
    NSInteger offset = (count - toolItems.count)/2;
    [toolItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *title = [self->toolItems[idx] objectForKey:@"title"];
        
        float ItemBtnWidth = [RDHelpClass widthForString:RDLocalizedString(title, nil) andHeight:12 fontSize:12] + 15 ;
        
        if( ItemBtnWidth < toolItemBtnWidth )
            ItemBtnWidth = toolItemBtnWidth;
        
        UIButton *toolItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        toolItemBtn.tag = [[toolItems[idx] objectForKey:@"id"] integerValue];
        toolItemBtn.backgroundColor = [UIColor clearColor];
        toolItemBtn.exclusiveTouch = YES;
        toolItemBtn.frame = CGRectMake(contentsWidth + ((toolItems.count > iIndex)?(width/2.0/(iIndex)):0), 0, ItemBtnWidth, _toolBarView.frame.size.height);
        [toolItemBtn addTarget:self action:@selector(clickToolItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        NSString *imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@默认_@3x", title] Type:@"png"];
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        imagePath = [RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/jianji/scrollViewChildImage/剪辑_剪辑%@选中_@3x", title] Type:@"png"];
        
       
        
        [toolItemBtn setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateSelected];
        [toolItemBtn setTitle:RDLocalizedString(title, nil) forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [toolItemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
        toolItemBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [toolItemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, (ItemBtnWidth - 44)/2.0, 16, (ItemBtnWidth - 44)/2.0)];
        [toolItemBtn setTitleEdgeInsets:UIEdgeInsetsMake(32, -44, 0, 0)];
        
        [_toolBarView addSubview:toolItemBtn];
        contentsWidth += ItemBtnWidth;
    }];
    
    if( contentsWidth <= kWIDTH )
        contentsWidth = kWIDTH + 10;
    
    _toolBarView.contentSize = CGSizeMake(contentsWidth, 0);
}

-(void)clickToolItemBtn:(UIButton *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(showCollageBarItem:)]) {
        [_delegate showCollageBarItem:sender.tag];
    }
}

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave
{
   if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:pipType isSave:isSave];
    }
}

-(void)dealloc
{
    if( _videoCoreSDK )
    {
        [_videoCoreSDK stop];
        _videoCoreSDK = nil;
    }
    
    if( _currentVvAsset )
    {
        _currentVvAsset = nil;
    }
}

-( void )otherReturn_Btn
{
    if( _delegate && [_delegate respondsToSelector:@selector(editCollage_back)] )
    {
        [_delegate editCollage_back];
    }
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
