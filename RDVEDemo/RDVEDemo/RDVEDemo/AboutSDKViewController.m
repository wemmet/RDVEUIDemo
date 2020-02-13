//
//  AboutSDKViewController.m
//  RDVEDemo
//
//  Created by wuxiaoxia on 2019/6/21.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AboutSDKViewController.h"

@interface AboutSDKViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    NSArray *listArray;
}

@end

@implementation AboutSDKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationItem setHidesBackButton:YES];
    self.view.backgroundColor = UIColorFromRGB(0x33333b);
    
    UIButton *leftItemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftItemBtn.frame = CGRectMake(0, 0, 44, 44);
    [leftItemBtn setImage:[UIImage imageNamed:@"返回默认_"] forState:UIControlStateNormal];
    [leftItemBtn setImage:[UIImage imageNamed:@"返回点击_"] forState:UIControlStateHighlighted];
    [leftItemBtn addTarget:self action:@selector(leftItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarItem = [[UIBarButtonItem alloc] initWithCustomView:leftItemBtn];
    self.navigationItem.leftBarButtonItem = leftBarItem;
    
    float height = (SCREEN_HEIGHT - kNavigationBarHeight)/3.0;
    UIImageView *iconIV = [[UIImageView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 76)/2.0, (height - 76)/2.0, 76, 76)];
    iconIV.image = [UIImage imageNamed:@"icon"];
    [self.view addSubview:iconIV];
    
    UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, iconIV.frame.origin.y + 86, SCREEN_WIDTH, 30)];
    nameLbl.text = NSLocalizedString(@"iOS视频编辑SDK", nil);
    nameLbl.textColor = [UIColor whiteColor];
    nameLbl.font = [UIFont boldSystemFontOfSize:20];
    nameLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:nameLbl];
    
    listArray = [NSArray arrayWithObjects:
                 NSLocalizedString(@"功能详述", nil),
                 NSLocalizedString(@"源码地址", nil),
                 NSLocalizedString(@"技术咨询: ", nil),
                 NSLocalizedString(@"商务合作: ", nil),nil];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(20, height, SCREEN_WIDTH - 40, height) style:UITableViewStyleGrouped];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.contentSize = CGSizeMake(0, listArray.count*44);
    [self.view addSubview:tableView];
    
    UILabel *companyLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - kNavigationBarHeight - (iPhone_X ? 34 : 0) - 60, SCREEN_WIDTH, 20)];
    companyLbl.text = @"北京锐动天地信息技术有限公司";
    companyLbl.textColor = UIColorFromRGB(0x888888);
    companyLbl.font = [UIFont systemFontOfSize:15.0];
    companyLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:companyLbl];
}

- (void)leftItemBtnAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return listArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *iCell = @"cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:iCell];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];
    if (indexPath.row == 0 || indexPath.row == 1) {
        cell.textLabel.text = [listArray objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else {
        NSString *str = [listArray objectAtIndex:indexPath.row];
        NSString *qqStr;
        if (indexPath.row == 2) {
            qqStr = @"45644590@qq.com";
        }else {
            qqStr = @"2637433751@qq.com";
        }
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", str, qqStr]];
        [attrTitle addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, str.length)];
        [attrTitle addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0xffd500) range:NSMakeRange(str.length, qqStr.length)];
        cell.textLabel.attributedText = attrTitle;
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.rdsdk.com/contrast/editsdk.html"]];
    }else if (indexPath.row == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.rdsdk.com/home/business/registers"]];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
