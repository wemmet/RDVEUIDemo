//
//  IncripTionLibItemViewController.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/21.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "IncripTionLibItemViewController.h"

#define kProgressViewTag 1000
#define kCellNormalHeight 50
#define kCellSelectHeight 117
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface IncripTionLibItemViewController ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation IncripTionLibItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _IncripTionLibTableView.frame = self.view.bounds;
}

- (void)setupUI{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.20*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{
    
                       if(_IncripTionLibTableView.superview){
                           [_IncripTionLibTableView removeFromSuperview];
                       }
                       
                       _IncripTionLibTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
                       _IncripTionLibTableView.backgroundColor    = [UIColor clearColor];
                       _IncripTionLibTableView.backgroundView     = nil;
                       _IncripTionLibTableView.delegate           = self;
                       _IncripTionLibTableView.dataSource         = self;
                       _IncripTionLibTableView.tag                = kProgressViewTag;
                       _IncripTionLibTableView.separatorStyle     = UITableViewCellAccessoryNone;
                       _IncripTionLibTableView.translatesAutoresizingMaskIntoConstraints = NO;
                       if (@available(iOS 11.0, *)) {
                           _IncripTionLibTableView.estimatedRowHeight = 0;
                           _IncripTionLibTableView.estimatedSectionFooterHeight = 0;
                           _IncripTionLibTableView.estimatedSectionHeaderHeight = 0;
                       }
                       [self.view addSubview:_IncripTionLibTableView];
                   });
}

#pragma mark- UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _sourceList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kCellSelectHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    @autoreleasepool {
        static NSString *identifier_ = @"cell_";
        UITableViewCell *cell_ = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier_];
        NSDictionary *dic = [_sourceList objectAtIndex:indexPath.row];
        
        NSString *title = [dic objectForKey:@"title"];
        NSArray  *content = [dic objectForKey:@"content"];
        NSString *num = [dic objectForKey:@"num"];
        
        cell_ = [self CreateTableViewCell:title content:content row:indexPath.row];
        return cell_;
    }
}

-(UITableViewCell*)CreateTableViewCell:(NSString *)title content:(NSArray*)content row:(int) row
{
    static NSString *identifier_ = @"cell_";
    UITableViewCell *cell_ = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier_];
    
    cell_.backgroundColor = SCREEN_BACKGROUND_COLOR;
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(10, 5, kWIDTH - 20, kCellSelectHeight-10)];
    view.backgroundColor = TOOLBAR_COLOR;
    
    UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(10, 5, kWIDTH - 20, kCellSelectHeight-10)];
    btn.tag = row;
    [btn addTarget:self action:@selector(btn:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor clearColor];
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, view.frame.size.width - 20, 30)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:15];
    [view addSubview:titleLabel];
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = 5;
    
    UIButton *constBtn = [[UIButton alloc] initWithFrame:CGRectMake(view.frame.size.width - 64 - 10, (view.frame.size.height-30)/2.0, 64, 30)];
    [constBtn setTitle:RDLocalizedString(@"使用", nil) forState:UIControlStateNormal];
    [constBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    constBtn.backgroundColor = Main_Color;
    constBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    constBtn.layer.masksToBounds = YES;
    constBtn.tag = row;
    constBtn.layer.cornerRadius = 5;
    [constBtn addTarget:self action:@selector(const_Btn:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UILabel *content1 = [[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.size.height + 10 + titleLabel.frame.origin.y, view.frame.size.width/2.0 - 10 , 20)];
    content1.textColor = TEXT_COLOR;
    content1.text = content[0];
    content1.font = [UIFont systemFontOfSize:10];
    [view addSubview:content1];
    
    UILabel *content2 = [[UILabel alloc] initWithFrame:CGRectMake(10, content1.frame.size.height + 1 + content1.frame.origin.y, view.frame.size.width/2.0 - 10 , 20)];
    content2.textColor = TEXT_COLOR;
    content2.text = [NSString stringWithFormat:@"%@...",content[1]];
    content2.font = [UIFont systemFontOfSize:10];
    [view addSubview:content2];
    
    
    [view addSubview:btn];
    [view addSubview:constBtn];
    
    [cell_ addSubview:view];
    
    
    cell_.selectionStyle=UITableViewCellSelectionStyleNone;
    return cell_;
}
-(void)btn:(UIButton *)Btn
{
    NSLog(@"详细");
    if( [_IncripTionLibItemDelegate respondsToSelector:@selector(DisplayText:)] )
    {
        NSDictionary *dic = [_sourceList objectAtIndex:Btn.tag];
        NSArray  *content = [dic objectForKey:@"content"];
        [_IncripTionLibItemDelegate  DisplayText:content];
    }
}

-(void)const_Btn:(UIButton *) Btn
{
    NSLog(@"使用");
    if( [_IncripTionLibItemDelegate respondsToSelector:@selector(select: atIsCustomize:)] )
    {
        NSDictionary *dic = [_sourceList objectAtIndex:Btn.tag];
        NSArray  *content = [dic objectForKey:@"content"];
        
        [_IncripTionLibItemDelegate  select:content atIsCustomize:false];
    }
}


@end
