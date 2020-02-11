//
//  RDRecordSetViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/4.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#define kMinBitrate 400
#define kMaxBitrate 3000

#import "RDRecordSetViewController.h"
#import "RDZSlider.h"

@interface RDRecordSetViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray      *setList;
    UITableView         *setTableView;
    UILabel             *bitrateLbl;
    UIImageView         *bitrateBackIV;
    int                  setBitrate;
    int                  setResolutionIndex;
    UISlider            *slider;
}

@end

@implementation RDRecordSetViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate{
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColorFromRGB(0x2b2b33);
    
    [self refreshNavgation];
    [self setValue];
    [self initSetTableView];
}

- (void)refreshNavgation{
    self.title = RDLocalizedString(@"设置", nil);
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationController.navigationBar.translucent = iPhone4s;
    [[UIApplication sharedApplication] setStatusBarHidden:!iPhone_X];
    [self.navigationItem setHidesBackButton:YES];
    //设置导航栏背景图片
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    
    //设置导航栏为半透明效果
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:[UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)] cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    [leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [leftBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回默认_@3x"] forState:UIControlStateNormal];
    [leftBtn setImage:[RDHelpClass getBundleImagePNG:@"拍摄_返回点击_@3x"] forState:UIControlStateHighlighted];
    leftBtn.exclusiveTouch = YES;
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width=-9;
    self.navigationItem.leftBarButtonItems = @[spaceItem,leftButton];
}

- (void)setValue {
    NSArray *setArray = [[NSUserDefaults standardUserDefaults] objectForKey:kRDRecordSet];
    setBitrate = [setArray[0] intValue];
    setResolutionIndex = [setArray[1] intValue];
    
    setList = [NSMutableArray array];
    
    NSMutableArray *itemArray1 = [NSMutableArray array];
    [itemArray1 addObject:RDLocalizedString(@"码率(kbps)", nil)];
    NSDictionary *itemDic1 = [NSDictionary dictionaryWithObjectsAndKeys:
                              RDLocalizedString(@"码率(kbps)", nil), @"title",
                              itemArray1, @"itemList",
                              nil];
    [setList addObject:itemDic1];
    
    NSMutableArray *itemArray2 = [NSMutableArray array];
    [itemArray2 addObject:@"360P"];
    [itemArray2 addObject:@"480P"];
    [itemArray2 addObject:@"720P"];
    [itemArray2 addObject:@"1080P"];
    NSDictionary *itemDic2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              RDLocalizedString(@"分辨率", nil), @"title",
                              itemArray2, @"itemList",
                              nil];
    [setList addObject:itemDic2];
}

- (void)initSetTableView {
    setTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, kHEIGHT - (iPhone_X ? 88 : 44)) style:UITableViewStylePlain];
    setTableView.backgroundColor    = [UIColor clearColor];
    setTableView.backgroundView     = nil;
    setTableView.delegate           = self;
    setTableView.dataSource         = self;
    setTableView.separatorStyle     = UITableViewCellAccessoryNone;
    [self.view addSubview:setTableView];
}

- (void)back {
    NSArray *setArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:setBitrate], [NSNumber numberWithInt:setResolutionIndex], nil];
    [[NSUserDefaults standardUserDefaults] setObject:setArray forKey:kRDRecordSet];
    if (_changeRecordSetFinish) {
        _changeRecordSetFinish(setBitrate, setResolutionIndex);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark- UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return setList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[setList[section] objectForKey:@"itemList"] count];;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return 100;
    }
    return 56;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
    headView.backgroundColor = [UIColor clearColor];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, headView.frame.size.width - 20, 44)];
    titleLabel.font = [UIFont systemFontOfSize:18];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.text = [setList[section] objectForKey:@"title"];
    titleLabel.layer.masksToBounds = YES;
    [headView addSubview:titleLabel];
    return headView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.backgroundColor = UIColorFromRGB(0x33333b);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.section == 0) {
        float value = (setBitrate/1000 - kMinBitrate)/(float)(kMaxBitrate - kMinBitrate);
        slider = [[UISlider alloc] initWithFrame:CGRectMake(35, (100 - 30)/2.0, tableView.frame.size.width - 70, 30)];
        slider.backgroundColor = [UIColor clearColor];
        slider.minimumTrackTintColor = Main_Color;
        slider.maximumTrackTintColor = TOOLBAR_COLOR;
        [slider setThumbImage:[RDHelpClass getBundleImagePNG:@"拍摄_轨道球_@3x"] forState:UIControlStateNormal];
        [slider setMaximumValue:1];
        [slider setMinimumValue:0];
        [slider setValue:value];
        [slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:slider];
        
        float progress = ((slider.value - slider.minimumValue ) /(slider.maximumValue - slider.minimumValue));
        float x = progress * (slider.frame.size.width - 20) + slider.frame.origin.x-10;
        bitrateBackIV = [[UIImageView alloc] initWithFrame:CGRectMake(x, slider.frame.origin.y - 22, 34, 22)];
        bitrateBackIV.image = [RDHelpClass getBundleImagePNG:@"拍摄_提示_@3x"];
        [cell.contentView addSubview:bitrateBackIV];
        
        bitrateLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 34, 17)];
        bitrateLbl.backgroundColor = [UIColor clearColor];
        bitrateLbl.text = [NSString stringWithFormat:@"%d", setBitrate/1000];
        bitrateLbl.textColor = Main_Color;
        bitrateLbl.font = [UIFont systemFontOfSize:12];
        bitrateLbl.textAlignment = NSTextAlignmentCenter;
        [bitrateBackIV addSubview:bitrateLbl];
        
        UILabel *minLbl = [[UILabel alloc] initWithFrame:CGRectMake(35, slider.frame.origin.y + 30, 100, 15)];
        minLbl.backgroundColor = [UIColor clearColor];
        minLbl.text = @"400k";
        minLbl.textColor = [UIColor whiteColor];
        minLbl.font = [UIFont systemFontOfSize:12];
        [cell.contentView addSubview:minLbl];
        
        UILabel *maxLbl = [[UILabel alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 135, slider.frame.origin.y + 30, 100, 15)];
        maxLbl.backgroundColor = [UIColor clearColor];
        maxLbl.text = @"3000k";
        maxLbl.textColor = [UIColor whiteColor];
        maxLbl.font = [UIFont systemFontOfSize:12];
        maxLbl.textAlignment = NSTextAlignmentRight;
        [cell.contentView addSubview:maxLbl];
        
    }else {
        cell.textLabel.text = [[setList[indexPath.section] objectForKey:@"itemList"] objectAtIndex:indexPath.row];
        cell.textLabel.textColor = [UIColor whiteColor];
        
        UIImageView *accessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
        accessoryView.image = [RDHelpClass getBundleImagePNG:@"拍摄_设置勾_@3x"];
        if (indexPath.row == setResolutionIndex) {
            accessoryView.hidden = NO;
        }else {
            accessoryView.hidden = YES;
        }
        cell.accessoryView = accessoryView;
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(35, 56-0.5, tableView.frame.size.width - 35, 0.5)];
        line.backgroundColor = UIColorFromRGB(0x414141);
        [cell addSubview:line];
    }
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1) {
        UITableViewCell *prevCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:setResolutionIndex inSection:1]];
        prevCell.accessoryView.hidden = YES;
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:1]];
        cell.accessoryView.hidden = NO;
        setResolutionIndex = indexPath.row;
        switch (indexPath.row) {
            case 0:
                setBitrate = 400*1000;
                break;
            case 1:
                setBitrate = 850*1000;
                break;
            case 2:
                setBitrate = 1800*1000;
                break;
            case 3:
                setBitrate = 3000*1000;
                break;
                
            default:
                break;
        }
        [self refreshSliderValue];
    }
}

- (void)refreshSliderValue {
    float value = (setBitrate/1000 - kMinBitrate)/(float)(kMaxBitrate - kMinBitrate);
    slider.value = value;
    
    float progress = ((value - slider.minimumValue ) /(slider.maximumValue - slider.minimumValue));
    bitrateBackIV.frame = CGRectMake(progress * (slider.frame.size.width - 20) + slider.frame.origin.x-10, bitrateBackIV.frame.origin.y, bitrateBackIV.frame.size.width, bitrateBackIV.frame.size.height);
    bitrateLbl.text = [NSString stringWithFormat:@"%d", setBitrate/1000];
}

- (void)scrub:(UISlider *)slider{
    float progress = ((slider.value - slider.minimumValue ) /(slider.maximumValue - slider.minimumValue));
    bitrateBackIV.frame = CGRectMake(progress * (slider.frame.size.width - 20) + slider.frame.origin.x-10, bitrateBackIV.frame.origin.y, bitrateBackIV.frame.size.width, bitrateBackIV.frame.size.height);
    
    float bitrate = kMinBitrate + slider.value * (kMaxBitrate - kMinBitrate);
    bitrateLbl.text = [NSString stringWithFormat:@"%.f", bitrate];
    setBitrate = bitrate*1000;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end
