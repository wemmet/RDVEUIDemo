//
//  InscriptionLibView.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/21.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "InscriptionLibView.h"
#import "RDScollTitleView.h"
#import "RDScrollContentView.h"
#import "IncripTionLibItemViewController.h"

@interface InscriptionLibView()<RDIncripTionLibItemViewControllerDelegate>
{
    UIButton        *cancelBtn;
    NSMutableArray *_inscriptionLibList;
    NSMutableArray *_vcs;
    
    UIView          *displayTextView;
    UIScrollView    *displayTextScrollView;
    UILabel         *titleLabel;
    
    NSArray         *currentStr;
}
@property (nonatomic, strong) RDScollTitleView *inscriptionLibView;

@property (nonatomic, strong) RDScrollContentView *inscriptionLibcontentView;

@property (nonatomic, strong) UIButton          *customizeBtn;
@end
@implementation InscriptionLibView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addSubview:self.titleView];
        
        _inscriptionLibView = [[RDScollTitleView alloc] initWithFrame:CGRectZero];
        __weak typeof(self) weakSelf = self;
        _inscriptionLibView.selectedBlock = ^(NSInteger index){
            __weak typeof(self) strongSelf = weakSelf;
            strongSelf.inscriptionLibcontentView.currentIndex = index;
        };
        _inscriptionLibView.backgroundColor = SCREEN_BACKGROUND_COLOR;
        _inscriptionLibView.tintColor = Main_Color;
        _inscriptionLibView.normalColor = UIColorFromRGB(0xffffff);
        _inscriptionLibView.selectedColor = UIColorFromRGB(0x000000);
        
        _inscriptionLibView.selectedIndex = _selectedIndex;
        [self addSubview:_inscriptionLibView];
        
        _inscriptionLibcontentView = [[RDScrollContentView alloc] initWithFrame:CGRectZero];
        _inscriptionLibcontentView.backgroundColor = [UIColor clearColor];
        _inscriptionLibcontentView.scrollBlock = ^(NSInteger index){
            __block typeof(self) strongSelf = weakSelf;
            strongSelf.inscriptionLibView.selectedIndex = index;
        };
        [self addSubview:_inscriptionLibcontentView];
        _inscriptionLibView.bottomLineView.hidden = YES;
        
        _inscriptionLibView.frame = CGRectMake(0, _titleView.frame.origin.y+_titleView.frame.size.height, self.frame.size.width, 55);
        
        _customizeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, _inscriptionLibView.frame.origin.y+_inscriptionLibView.frame.size.height, kWIDTH-20, 40)];
        _customizeBtn.backgroundColor = TOOLBAR_COLOR;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(_customizeBtn.frame.size.width/2.0 - 30.0, 0, _customizeBtn.frame.size.width/2.0, 40)];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = RDLocalizedString(@"自定义题词", nil);
        label.textColor = Main_Color;
        [_customizeBtn addSubview:label];
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake( _customizeBtn.frame.size.width/2.0-60.0, 5, 30, 30)];
        imageView.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_添加默认_@3x" Type:@"png"]];
        [_customizeBtn addSubview:imageView];
        [_customizeBtn addTarget:self action:@selector(customize_Btn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_customizeBtn];
        
        _inscriptionLibcontentView.frame = CGRectMake(0, _customizeBtn.frame.origin.y+5+_customizeBtn.frame.size.height, kWIDTH, self.frame.size.height - (_customizeBtn.frame.origin.y+5+_customizeBtn.frame.size.height));
        
        [self reloadData];
    }
    return self;
}
-(void)customize_Btn
{
    if( [_InscriptionLibDelegate respondsToSelector:@selector(CustomInscription)] )
    {
        [_InscriptionLibDelegate CustomInscription];
    }
    self.hidden = YES;
}

#pragma mark-
- (UIView *)titleView{
    if(!_titleView){
        _titleView = [[UIView alloc] initWithFrame:CGRectMake(0, (iPhone_X ? 44 : 0), kWIDTH, 44)];
        
        titleLabel = [UILabel new];
        titleLabel.frame = CGRectMake(0, 0, kWIDTH, 44);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:20];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.text = RDLocalizedString(@"题词库", nil);
        //titleLabel.text = RDLocalizedString(@"视频编辑", nil);
        [_titleView addSubview:titleLabel];
        
        cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.exclusiveTouch = YES;
        cancelBtn.backgroundColor = [UIColor clearColor];
        cancelBtn.frame = CGRectMake(iPhone4s?0:5, (_titleView.frame.size.height - 44), 44, 44);
        [cancelBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        [_titleView addSubview:cancelBtn];
    }
    return _titleView;
}

+(id)maskDictionary:(NSString *) path
{
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:path];
    id  configDic = [RDHelpClass objectForData:jsonData];
    return configDic;
}

-(void)back:(UIButton*) btn
{
    if( (displayTextView) && (displayTextView.hidden == NO) )
    {
        displayTextView.hidden = YES;
        titleLabel.text = RDLocalizedString(@"题词库", nil);
        _titleView.backgroundColor = [UIColor clearColor];
    }
    else
        self.hidden = YES;
}

- (void)reloadData{
    _inscriptionLibList =  [InscriptionLibView maskDictionary:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/inscription" Type:@"json"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshContentView];
    });
}

- (void)refreshContentView {
    NSMutableArray *titles = [NSMutableArray new];
    for (int i = 0; i<_inscriptionLibList.count; i ++){
        NSString *title = [_inscriptionLibList[i] objectForKey:@"name"];
        [titles addObject:title];
        title = nil;
    }
    
    if (_inscriptionLibList.count > 0) {
        [_inscriptionLibView reloadViewWithTitles:titles];
    }else {
        [_inscriptionLibView removeFromSuperview];
    }
    
    _vcs = [[NSMutableArray alloc] init];
    for (int i = 0; i<titles.count; i ++) {
        NSString *title = titles[i];
        IncripTionLibItemViewController *vc = [[IncripTionLibItemViewController alloc] init];
        vc.category = title;
        vc.vcIndex  = i;
        vc.IncripTionLibItemDelegate = self;
        vc.sourceList = [_inscriptionLibList[i] objectForKey:@"data"];

        [_vcs addObject:vc];
    }
    if (_vcs.count > 0) {
        [_inscriptionLibcontentView reloadViewWithChildVcs:_vcs parentVC:_InscriptionLibDelegate];
    }
}

#pragma mark- RDIncripTionLibItemViewControllerDelegate
-(void)select:(NSArray *)str atIsCustomize:(bool)isCustomize
{
    if( [_InscriptionLibDelegate respondsToSelector:@selector(select: atIsCustomize:)] )
    {
        [_InscriptionLibDelegate  select:str atIsCustomize:isCustomize];
    }
    self.hidden = YES;
}

-(void)CreatedisplayTextView:(NSArray *) str
{
    if( displayTextView )
    {
        [displayTextView removeFromSuperview];
        displayTextView = nil;
    }
    
    displayTextView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _titleView.frame.size.height + _titleView.frame.origin.y, self.frame.size.width, self.frame.size.height - _titleView.frame.size.height - _titleView.frame.origin.y)];
    displayTextView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    [displayTextScrollView removeFromSuperview];
    displayTextScrollView = nil;
    
    float height = self.frame.size.height - _titleView.frame.size.height - _titleView.frame.origin.y - kNavigationBarHeight - 30;
    
    displayTextScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, height)];
    displayTextScrollView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    [displayTextView addSubview:displayTextScrollView];
    
    UIButton *constBtn = [[UIButton alloc] initWithFrame:CGRectMake((60)/2.0,  displayTextScrollView.frame.size.height + displayTextScrollView.frame.origin.y + (44+30-44)/2.0, displayTextView.frame.size.width - 60 , 44)];
    [constBtn setTitle:RDLocalizedString(@"使用", nil) forState:UIControlStateNormal];
    [constBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    constBtn.backgroundColor = Main_Color;
    constBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    constBtn.layer.masksToBounds = YES;
    constBtn.layer.cornerRadius = 5;
    [constBtn addTarget:self action:@selector(const_Btn) forControlEvents:UIControlEventTouchUpInside];
    [displayTextView addSubview:constBtn];
    
    for ( int i = 0 ; i < str.count; i++) {
        [self CreaTextteLabel:i str:str[i]];
    }
    
    displayTextScrollView.contentSize = CGSizeMake(0, 40*str.count +displayTextScrollView.frame.size.height/3.0 );
    
    [self addSubview:displayTextView];
}
-(void)const_Btn
{
    if( [_InscriptionLibDelegate respondsToSelector:@selector(select: atIsCustomize:)] )
    {
        [_InscriptionLibDelegate  select:currentStr atIsCustomize:false];
    }
    self.hidden = YES;
}

-(UILabel *)CreaTextteLabel:(int) index str:(NSString *) str
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, index*40, displayTextScrollView.frame.size.width, 40)];
//    label.textColor = UIColorFromRGB(0x838383);
    label.text = str;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15];
    
    label.textColor = UIColorFromRGB(0xffffff);
    
    [displayTextScrollView addSubview:label];
    
    return label;
}

//详细
-(void)DisplayText:(NSArray *) str
{
    if( str.count )
    {
        titleLabel.text = RDLocalizedString(@"详细", nil);
        [self CreatedisplayTextView:str];
        currentStr = str;
        displayTextScrollView.hidden = NO;
        _titleView.backgroundColor = TOOLBAR_COLOR;
    }
}

@end
