//
//  RDScollTitleView.m

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "RDScollTitleView.h"
#define kTITLEBTNTAG 1000
@interface RDScollTitleView()
{
    NSArray *_titles;
    
    UIScrollView *_scrollView;
    
    
    
    NSMutableArray *_titleButtons;
    
    UIView *_selectionIndicator;
}
//@property (nonatomic, strong) NSArray *titles;
//
//@property (nonatomic, strong) UIScrollView *scrollView;
//
//@property (nonatomic, strong) NSMutableArray *titleButtons;
//
//@property (nonatomic, strong) UIView *selectionIndicator;

@end

@implementation RDScollTitleView

- (void)awakeFromNib{
    [super awakeFromNib];
    [self initData];
    [self setupUI];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initData];
        [self setupUI];
    }
    return self;
}

- (void)initData{
    _selectedIndex = 0;
    _normalColor = [UIColor blackColor];
    _selectedColor = [UIColor redColor];
    _titleWidth = 85.f;
    _tintColor = UIColorFromRGB(0xffffff);
    _indicatorHeight = 2.f;
    _titleFont = [UIFont systemFontOfSize:16.f];
    _titleButtons = [[NSMutableArray alloc] init];
}

- (void)setupUI{
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.scrollsToTop = NO;
    _scrollView.scrollEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:_scrollView];
    _selectionIndicator = [[UIView alloc] initWithFrame:CGRectZero];
    _selectionIndicator.backgroundColor = _tintColor;
    [_scrollView addSubview:_selectionIndicator];
    _bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomLineView.backgroundColor = UIColorFromRGB(0x888888);
    
    [self addSubview:_bottomLineView];
}

- (void)reloadViewWithTitles:(NSArray *)titles{
    for (UIButton *btn in _titleButtons) {
        [btn removeFromSuperview];
    }
    _titles = titles;
    NSInteger i = 0;
    for (NSString *title in titles) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (i == _selectedIndex) {
            btn.selected = YES;
        }
        btn.tag = kTITLEBTNTAG + i++;
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        btn.titleLabel.font = _titleFont;
        [btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:_normalColor forState:UIControlStateNormal];
        [btn setTitleColor:_selectedColor forState:UIControlStateSelected];
        [_scrollView addSubview:btn];
        [_titleButtons addObject:btn];
    }
    [self layoutSubviews];
}

- (void)btnClick:(UIButton *)btn{
    NSInteger btnIndex = btn.tag - kTITLEBTNTAG;
    if (btnIndex == _selectedIndex) {
        return;
    }
    
    [self setSelectedIndex:btnIndex];
    [self layoutSubviews];

    if (_selectedBlock) {
        _selectedBlock(btnIndex);
    }
}


- (void)layoutSubviews{
    [super layoutSubviews];
    _scrollView.frame = self.bounds;
    _bottomLineView.frame = CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1);
    float width = 10;
    for (int i = 0 ; i < _titles.count ; i++) {
        
        UIButton *btn = _titleButtons[i];
        NSString *title = _titles[i];
        
        float titleWidth = [title boundingRectWithSize:CGSizeMake(self.bounds.size.width, 40) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:_titleFont.fontName size:_titleFont.pointSize]} context:nil].size.width + 20;

        
        
        btn.frame = CGRectMake(width, 10, titleWidth, self.frame.size.height - 20);
        
        width += titleWidth;
        
        //NSLog(@"width : %f",width);
    }
    _scrollView.contentSize = CGSizeMake(width, self.frame.size.height);

    [self setSelectedIndicator:NO];
    //[_scrollView bringSubviewToFront:_selectionIndicator];
}

- (void)setSelectedIndicator:(BOOL)animated {
    float width = 10;
    float titleWidth = _titleWidth;
    for (int i = 0 ; i < _titles.count ; i++) {
        
        UIButton *btn = _titleButtons[i];
        NSString *title = _titles[i];
        
        titleWidth = [title boundingRectWithSize:CGSizeMake(self.bounds.size.width, 40) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:_titleFont.fontName size:_titleFont.pointSize]} context:nil].size.width + 20;
        
        btn.frame = CGRectMake(width, 10, titleWidth, self.frame.size.height - 20);
        
        //NSLog(@"width : %f",width);
        if(i>=_selectedIndex){
            break;
        }
        width += titleWidth;

    }
    _indicatorHeight = self.frame.size.height - 28;
    [UIView animateWithDuration:(animated? 0.02 : 0) delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        
        _selectionIndicator.frame = CGRectMake(width, (self.frame.size.height - _indicatorHeight)/2.0, titleWidth, _indicatorHeight);
    } completion:^(BOOL finished) {
        _selectionIndicator.backgroundColor = _tintColor;
        _selectionIndicator.layer.cornerRadius = MIN(_selectionIndicator.frame.size.width,_selectionIndicator.frame.size.height)/2.0;
        _selectionIndicator.layer.masksToBounds = YES;
        [self scrollRectToVisibleCenteredOn:_selectionIndicator.frame animated:YES];
    }];
}

- (void)scrollRectToVisibleCenteredOn:(CGRect)visibleRect animated:(BOOL)animated {
    CGRect centeredRect = CGRectMake(visibleRect.origin.x + visibleRect.size.width / 2.0 - _scrollView.frame.size.width / 2.0,
                                     visibleRect.origin.y + visibleRect.size.height / 2.0 - _scrollView.frame.size.height / 2.0,
                                     _scrollView.frame.size.width,
                                     _scrollView.frame.size.height);
    [_scrollView scrollRectToVisible:centeredRect animated:animated];
}

#pragma mark - setter

- (void)setSelectedIndex:(NSInteger)selectedIndex{
    if (_selectedIndex == selectedIndex) {
        
        return;
    }
    UIButton *btn = [_scrollView viewWithTag:_selectedIndex + kTITLEBTNTAG];
    btn.selected = NO;
    _selectedIndex = selectedIndex;
    UIButton *selectedBtn = [_scrollView viewWithTag:_selectedIndex + kTITLEBTNTAG];
    selectedBtn.selected = YES;
    [self setSelectedIndicator:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTitleIndex" object:nil];
}

- (void)setNormalColor:(UIColor *)normalColor{
    _normalColor = normalColor;
}

- (void)setSelectedColor:(UIColor *)selectedColor{
    _selectedColor = selectedColor;
}

- (void)setTitleWidth:(CGFloat)titleWidth{
    _titleWidth = titleWidth;
    [self setNeedsLayout];
}

- (void)setIndicatorHeight:(CGFloat)indicatorHeight{
    _indicatorHeight = indicatorHeight;
    [self setNeedsLayout];
}

- (void)setTitleFont:(UIFont *)titleFont{
    _titleFont = titleFont;
}

@end

