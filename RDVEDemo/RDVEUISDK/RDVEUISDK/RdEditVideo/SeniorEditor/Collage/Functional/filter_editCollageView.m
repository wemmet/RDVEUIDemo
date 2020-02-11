//
//  filter_editCollageView.m
//  RDVEUISDK
//
//  Created by apple on 2020/1/7.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "filter_editCollageView.h"
#import "UIImageView+RDWebCache.h"
#import "RDNextEditVideoViewController.h"
#import "RDDownTool.h"

@interface filter_editCollageView()<ScrollViewChildItemDelegate>
{
    //新滤镜
    NSMutableArray              *newFilterSortArray;
    NSMutableArray              *newFiltersNameSortArray;
    
    int                         currentlabelFilter;
    int                         currentFilterIndex;
//    NSInteger                   selectFilterIndex;
    NSInteger                   oldFilterType;         //滤镜
    float                       filterStrength;        //滤镜强度
    float                       oldFilterStrength;     //旧 滤镜强度
}


@end
@implementation filter_editCollageView

-(NSMutableArray *)getNewFilterSortArray
{
    return newFilterSortArray;
}

-(NSInteger)getCurrentlabelFilter
{
    return currentlabelFilter;
}

-(NSInteger)getCurrentFilterIndex
{
    return currentFilterIndex;
}

-(void)setNewFilterSortArray:(NSMutableArray *) filterSortArray
{
    newFilterSortArray = filterSortArray;
}
-(void)setNewFiltersNameSortArray:(NSMutableArray *) filtersNameSortArray
{
    newFiltersNameSortArray = filtersNameSortArray;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = TOOLBAR_COLOR;
        
        _toolFilterView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - kToolbarHeight, frame.size.width, kToolbarHeight)];
        
        [self addSubview:_toolFilterView];
        
        _toolFilterCloseBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [_toolFilterCloseBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [_toolFilterCloseBtn addTarget:self action:@selector(toolFilterClose_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_toolFilterView addSubview:_toolFilterCloseBtn];
        
        _toolFilterConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kWIDTH - 44, 0, 44, 44)];
        [_toolFilterConfirmBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [_toolFilterConfirmBtn addTarget:self action:@selector(toolFilterConfirm_Btn) forControlEvents:UIControlEventTouchUpInside];
        [_toolFilterView addSubview:_toolFilterConfirmBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, self.bounds.size.width - 88, 44)];
        [_toolFilterView addSubview:label];
        label.text = RDLocalizedString(@"滤镜", nil);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        

  
    }
    return self;
}

-(void)setCollageFilters
{
    if (((RDNavigationViewController *)self.navigationController).isSingleFunc)
      {
          [self setFilters];
      }
}

- (void)setFilters{
    _globalFilters = [NSMutableArray array];
    NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
    UIImage* inputImage = [UIImage imageWithContentsOfFile:bundlePath];
    
    NSString *appKey = ((RDNavigationViewController *)self.navigationController).appKey;
    EditConfiguration *editConfig = ((RDNavigationViewController *)self.navigationController).editConfiguration;
    RDNavigationViewController *nav = (RDNavigationViewController *)self.navigationController;
    RD_RDReachabilityLexiu *lexiu = [RD_RDReachabilityLexiu reachabilityForInternetConnection];
    if([lexiu currentReachabilityStatus] != RDNotReachable && nav.editConfiguration.filterResourceURL.length>0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary * dic = [RDHelpClass classificationParams:@"filter2" atAppkey: appKey atURl:editConfig.netMaterialTypeURL];
            if( !dic )
            {
                NSDictionary *filterList = [RDHelpClass getNetworkMaterialWithType:@"filter"
                                                                            appkey:appKey
                                                                           urlPath:editConfig.filterResourceURL];
                if ([filterList[@"code"] intValue] == 0) {
                    _filtersName = [filterList[@"data"] mutableCopy];
                    
                    NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                    if(appKey.length > 0)
                        [itemDic setObject:appKey forKey:@"appkey"];
                    [itemDic setObject:@"" forKey:@"cover"];
                    [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                    [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                    [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                    [_filtersName insertObject:itemDic atIndex:0];
                }
            }
            else
            {
                newFilterSortArray = [NSMutableArray arrayWithArray:dic];
                newFiltersNameSortArray = [NSMutableArray new];
                for (int i = 0; i < newFilterSortArray.count; i++) {
                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    [params setObject:@"filter2" forKey:@"type"];
                    [params setObject:[newFilterSortArray[i] objectForKey:@"id"]  forKey:@"category"];
                    [params setObject:[NSString stringWithFormat:@"%d" ,0] forKey: @"page_num"];
                    NSDictionary *dic2 = [RDHelpClass getNetworkMaterialWithParams:params
                                                                            appkey:appKey urlPath:editConfig.effectResourceURL];
                    if(dic2 && [[dic2 objectForKey:@"code"] integerValue] == 0)
                    {
                        NSMutableArray * currentStickerList = [dic2 objectForKey:@"data"];
                        [newFiltersNameSortArray addObject:currentStickerList];
                    }
                    else
                    {
                        NSString * message = RDLocalizedString(@"下载失败，请检查网络!", nil);
                    }
                }
                _filtersName = [NSMutableArray new];
                NSMutableDictionary *itemDic = [[NSMutableDictionary alloc] init];
                if(appKey.length > 0)
                    [itemDic setObject:appKey forKey:@"appkey"];
                [itemDic setObject:@"" forKey:@"cover"];
                [itemDic setObject:RDLocalizedString(@"原始", nil) forKey:@"name"];
                [itemDic setObject:@"1530073782429" forKey:@"timestamp"];
                [itemDic setObject:@"1530073782429" forKey:@"updatetime"];
                [_filtersName addObject:itemDic];
                
                for (int i = 0; newFiltersNameSortArray.count > i; i++) {
                    [_filtersName addObjectsFromArray:newFiltersNameSortArray[i]];
                }
            }
            
            
            
                NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:filterPath]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:filterPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                [_filtersName enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    RDFilter* filter = [RDFilter new];
                    if([obj[@"name"] isEqualToString:RDLocalizedString(@"原始", nil)]){
                        filter.type = kRDFilterType_YuanShi;
                    }else{
                        NSString *itemPath = [[[filterPath stringByAppendingPathComponent:[obj[@"name"] lastPathComponent]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
                        if (![[[obj[@"file"] pathExtension] lowercaseString] isEqualToString:@"acv"]){
                            filter.type = kRDFilterType_LookUp;
                        }
                        else{
                            filter.type = kRDFilterType_ACV;
                        }
                        filter.filterPath = itemPath;
                    }
                    filter.netCover = obj[@"cover"];
                    filter.name = obj[@"name"];
                    [_globalFilters addObject:filter];
                    [self AdjGlobalFilters:filter atIndex:_globalFilters.count - 1];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (((RDNavigationViewController *)self.navigationController).isSingleFunc)
//                        [self.view addSubview:self.filterView];
                    _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
                });
        });
    }else{
        _filtersName = [@[@"原始",@"黑白",@"香草",@"香水",@"香檀",@"飞花",@"颜如玉",@"韶华",@"露丝",@"霓裳",@"雨后"] mutableCopy];
        [_filtersName enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            RDFilter* filter = [RDFilter new];
            if ([obj isEqualToString:@"原始"]) {
                filter.type = kRDFilterType_YuanShi;
            }
            else{
                filter.type = kRDFilterType_LookUp;
                filter.filterPath = [RDHelpClass getResourceFromBundle:[NSString stringWithFormat:@"lookupFilter/%@",obj] Type:@"png"];
            }
            filter.name = obj;
            [_globalFilters addObject:filter];
            
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",filter.name]];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:photoPath]){
                [RDCameraManager returnImageWith:inputImage Filter:filter withCompletionHandler:^(UIImage *processedImage) {
                    NSData* imagedata = UIImageJPEGRepresentation(processedImage, 1.0);
                    [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
                }];
            }
            [self AdjGlobalFilters:filter atIndex:_globalFilters.count - 1];
        }];
        if (((RDNavigationViewController *)self.navigationController).isSingleFunc)
//            [self.view addSubview:self.filterView];
        _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    }
    
}

-(void)AdjGlobalFilters:(RDFilter *) obj atIndex:(NSUInteger) idx
{
    dispatch_async(dispatch_get_main_queue(), ^{
            ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(self.filterChildsView.frame.size.height - 15)+10, 0, (self.filterChildsView.frame.size.height - 25), self.filterChildsView.frame.size.height)];
            item.backgroundColor        = [UIColor clearColor];
            item.fontSize       = 12;
            item.type           = 2;
            item.delegate       = self;
            item.selectedColor  = Main_Color;
            item.normalColor    = UIColorFromRGB(0x888888);
            item.cornerRadius   = item.frame.size.width/2.0;
            item.exclusiveTouch = YES;
            item.itemIconView.backgroundColor   = [UIColor clearColor];
            item.itemTitleLabel.text            = RDLocalizedString(obj.name, nil);
            item.tag                            = idx + 1;
            item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
                if(idx == 0){
                    NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                    NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                    NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                    item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
                }else{
                    [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
                }
            }else{
                NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                }
                NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
            }
            [self.filterChildsView addSubview:item];
            [item setSelected:(idx == currentFilterIndex ? YES : NO)];
        
        _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (self.filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    });
}


#pragma mark- 滤镜
- (UIView *)filterView{
    if(!_filterView){
        if( !newFilterSortArray )
        {
            _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - kToolbarHeight)];
            _filterView.backgroundColor = TOOLBAR_COLOR;
            [self addSubview:_filterView];
            _filterChildsView           = [UIScrollView new];
            
            float height = (_filterView.frame.size.height - 40) > 100 ? 100 : 90 ;
            _filterChildsView.frame     = CGRectMake(0,40 + ( (_filterView.frame.size.height - 40) - height )/2.0, _filterView.frame.size.width, height);
            _filterChildsView.backgroundColor                   = [UIColor clearColor];
            _filterChildsView.showsHorizontalScrollIndicator    = NO;
            _filterChildsView.showsVerticalScrollIndicator      = NO;
            _filterView.hidden = YES;
            
            if(!self.filterProgressSlider.superview)
                [_filterView addSubview:_filterProgressSlider ];
            
            [_filterView addSubview:_filterChildsView];
            [self initFilterChildsView];
        }
        else{
            _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - kToolbarHeight)];
            _filterView.backgroundColor = TOOLBAR_COLOR;
            [self addSubview:_filterView];
            
            [_filterView addSubview:self.fileterNewView];
            
            if(!self.filterProgressSlider.superview)
                [_filterView addSubview:_filterProgressSlider ];
            _filterStrengthLabel.hidden = YES;
            _percentageLabel.hidden =  YES;
            _filterProgressSlider.frame = CGRectMake(60, _filterView.frame.size.height*( 0.337 + 0.462 ) + (_filterView.frame.size.height*( 0.203 ) - 30)/2.0 + 5, self.filterView.frame.size.width - 60 - 60, 30);
            
        }
    }
    return _filterView;
}

-(void)filterLabelBtn:(UIButton *) btn
{
    [_fileterLabelNewScroView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
         if([obj isKindOfClass:[UIButton class]]){
             ((UIButton*)obj).selected = NO;
             ((UIButton*)obj).font = [UIFont systemFontOfSize:14];
         }
    }];
    
    int index = 0;
    for (int i = 0; i < newFiltersNameSortArray.count; i++) {
        NSArray * array = (NSArray *)newFiltersNameSortArray[i];
        index += array.count;
        if( i == btn.tag )
        {
            currentlabelFilter = i;
            index -= array.count;
            currentFilterIndex = index;
            break;
        }
    }
    
    self.fileterScrollView.hidden = NO;
    
    btn.selected = YES;
    btn.font = [UIFont boldSystemFontOfSize:14];
//    [self scrollViewChildItemTapCallBlock:_originalItem];
}

-(void)scrollViewIndex:(int) fileterindex
{
    __block int index = 0;
    for (int i = 0; i < newFiltersNameSortArray.count; i++) {
        NSArray * array = (NSArray *)newFiltersNameSortArray[i];
        index += array.count;
        if( fileterindex < index )
        {
            currentlabelFilter = i;
            index -= array.count;
            currentFilterIndex = index;
            break;
        }
    }
}

-(UIView *)fileterNewView
{
    if( !_fileterNewView )
    {
        _fileterNewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _filterView.frame.size.height*( 0.337 + 0.462 ))];
        [_filterView addSubview:_fileterNewView];
        
        _fileterLabelNewScroView  = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, _filterView.frame.size.height*( 0.337 ))];
        _fileterLabelNewScroView.tag = 1000;
        _fileterLabelNewScroView.showsVerticalScrollIndicator  =NO;
        _fileterLabelNewScroView.showsHorizontalScrollIndicator = NO;
        
        
        [self scrollViewIndex:_selectFilterIndex-1];
        
        float contentWidth = 0 + _fileterLabelNewScroView.frame.size.height*2.0/5.0 + 20;
        
        for (int i = 0; newFilterSortArray.count > i; i++) {
            
            NSString *str = [newFilterSortArray[i] objectForKey:@"name"];
            
            float ItemBtnWidth = [RDHelpClass widthForString:str andHeight:14 fontSize:14] + 20;
            
            
            UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(contentWidth, 0, ItemBtnWidth, _fileterLabelNewScroView.frame.size.height)];
            btn.font = [UIFont systemFontOfSize:14];
            [btn setTitle:str forState:UIControlStateNormal];
            [btn setTitleColor: [UIColor colorWithWhite:1.0 alpha:0.5]  forState:UIControlStateNormal];
            [btn setTitleColor:Main_Color forState:UIControlStateSelected];
            [btn addTarget:self action:@selector(filterLabelBtn:) forControlEvents:UIControlEventTouchUpInside];
            btn.titleLabel.textAlignment = NSTextAlignmentLeft;
            
            btn.tag = i;
            if( i == currentlabelFilter )
            {
                btn.font = [UIFont boldSystemFontOfSize:14];
                btn.selected = YES;
            }
            contentWidth += ItemBtnWidth;
            [_fileterLabelNewScroView addSubview:btn];
        }
        
        UIButton *noBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _fileterLabelNewScroView.frame.size.height*3.0/7.0 + 20, _fileterLabelNewScroView.frame.size.height)];
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, _fileterLabelNewScroView.frame.size.height*4.0/7.0/2.0, _fileterLabelNewScroView.frame.size.height*3.0/7.0, _fileterLabelNewScroView.frame.size.height*3.0/7.0)];
        imageView.image = [UIImage imageWithContentsOfFile:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Proportion/比例无@3x" Type:@"png"]];
        noBtn.tag                            = 100;
        [noBtn addTarget:self action:@selector(noBtn_onclik) forControlEvents:UIControlEventTouchUpInside];
        [noBtn addSubview:imageView];
        
        [_fileterLabelNewScroView addSubview:noBtn];
        
        _fileterLabelNewScroView.contentSize = CGSizeMake(contentWidth+20, 0);
        
        float fileterNewScroViewHeight = _filterView.frame.size.height * 0.462;
        {
            _originalItem  = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(10, 0, fileterNewScroViewHeight - 20, fileterNewScroViewHeight)];
            _originalItem.backgroundColor        = [UIColor clearColor];


            {
                _originalItem.itemIconView.backgroundColor = UIColorFromRGB(0x27262c);
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _originalItem.itemIconView.frame.size.width, _originalItem.itemIconView.frame.size.height)];
                label.text = RDLocalizedString(@"无", nil);
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                label.font = [UIFont systemFontOfSize:15.0];
                [_originalItem.itemIconView addSubview:label];
            }

            _originalItem.fontSize       = 12;
            _originalItem.type           = 2;
            _originalItem.delegate       = self;
            _originalItem.selectedColor  = Main_Color;
            _originalItem.normalColor    = [UIColor colorWithWhite:1.0 alpha:0.5];
            _originalItem.cornerRadius   = _originalItem.frame.size.width/2.0;
            _originalItem.exclusiveTouch = YES;
//            _originalItem.itemIconView.backgroundColor   = [UIColor clearColor];
            _originalItem.itemTitleLabel.text            = RDLocalizedString(@"无滤镜", nil);
            _originalItem.tag                            = 0 + 1;
            _originalItem.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
            [_originalItem setSelected:(0 == self->_selectFilterIndex ? YES : NO)];
            [_originalItem setCornerRadius:5];
//            [_fileterNewView addSubview:_originalItem];
        }
//
        [_fileterNewView addSubview:_fileterLabelNewScroView];
        self.fileterScrollView.hidden = NO;
    }
    return _fileterNewView;
}

-(void)noBtn_onclik
{
    [self scrollViewChildItemTapCallBlock:_originalItem];
}

-( void )setNewFilterChildsView:( bool ) isYES atTypeIndex:(NSInteger) tag
{
    
    for (UIView *subview in _fileterScrollView.subviews) {
        if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
            [(ScrollViewChildItem*)subview setSelected:NO];
    }
    
    if( tag == 0 )
    {
        [_originalItem setSelected:isYES];
        return;
    }
}

-(UIScrollView *)fileterScrollView
{
    if( !_fileterScrollView )
    {
        float fileterNewScroViewHeight = _filterView.frame.size.height * 0.462;
//        (fileterNewScroViewHeight - 20) + 20
        _fileterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _fileterLabelNewScroView.frame.origin.y + _fileterLabelNewScroView.frame.size.height, kWIDTH, fileterNewScroViewHeight)];
        [_fileterNewView addSubview:_fileterScrollView];
        _fileterScrollView.showsVerticalScrollIndicator = NO;
        _fileterScrollView.showsHorizontalScrollIndicator = NO;
        
        
//        [_fileterScrollView addSubview:_originalItem];
        
    }
    else{
        for (UIView *subview in _fileterScrollView.subviews) {
            if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                
                if( subview != _originalItem )
                    [subview removeFromSuperview];
            
        }
    }
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *str = [newFilterSortArray[currentlabelFilter] objectForKey:@"name"];
    if( isEnglish )
        str = [str substringToIndex:1];
    
    NSArray * array = (NSArray *)newFiltersNameSortArray[ currentlabelFilter ];
    __block int index = 0;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*((_fileterScrollView.frame.size.height - 20) + 10) + 10 , 0, (_fileterScrollView.frame.size.height  - 20 ), _fileterScrollView.frame.size.height)];
        item.backgroundColor        = [UIColor clearColor];
        
        [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:[obj  objectForKey:@"cover"]]];
        item.fontSize       = 12;
        item.type           = 2;
        item.delegate       = self;
        item.selectedColor  = Main_Color;
        item.itemTitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        item.normalColor    = [UIColor colorWithWhite:1.0 alpha:0.5];
        //            item.normalColor    = UIColorFromRGB(0x888888);
        item.cornerRadius   = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor   = [UIColor clearColor];
        
        item.tag                            = idx + currentFilterIndex + 2;
        
        item.itemTitleLabel.text = [NSString stringWithFormat:@"%@%d",str,idx+1];
        
        if( (item.tag-1)  == self->_selectFilterIndex )
        {
            [item setSelected:YES];
        }
        
        item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
        
        if( (item.tag-1) == self->_selectFilterIndex )
            index = idx;
        
        [item setCornerRadius:5];
        dispatch_async(dispatch_get_main_queue(), ^{
            [item setSelected:((item.tag-1) == self->_selectFilterIndex ? YES : NO)];
            [_fileterScrollView addSubview:item];
        });
    
    }];
    
    float contentWidth = (_fileterScrollView.frame.size.height - 20 + 10 )*(array.count+1)+10;
    if( contentWidth <=  _fileterScrollView.frame.size.width )
    {
        contentWidth = _fileterScrollView.frame.size.width + 20;
    }
    
    _fileterScrollView.contentSize = CGSizeMake(contentWidth, 0);
    _fileterScrollView.delegate = self;
    
    float draggableX = _fileterScrollView.contentSize.width - _fileterScrollView.frame.size.width;
    if( draggableX >0 )
    {
        float x = (_fileterScrollView.frame.size.height - 20 + 10 ) *  index;
        
        if( x > draggableX )
            x = draggableX;
        
        _fileterScrollView.contentOffset = CGPointMake(x, 0);
    }
    //    });
    
    return _fileterScrollView;
}

//滤镜进度条
- (RDZSlider *)filterProgressSlider{
    if(!_filterProgressSlider){
        float height = (_filterView.frame.size.height - 40) > 120 ? 120 : 90 ;
        
        _filterStrengthLabel = [[UILabel alloc] init];
        _filterStrengthLabel.frame = CGRectMake(15, ((40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 20 )/2.0, 50, 20);
        _filterStrengthLabel.textAlignment = NSTextAlignmentLeft;
        _filterStrengthLabel.textColor = UIColorFromRGB(0xffffff);
        _filterStrengthLabel.font = [UIFont systemFontOfSize:12];
        _filterStrengthLabel.text = RDLocalizedString(@"滤镜强度", nil);
        [_filterView addSubview:_filterStrengthLabel];
        
        _filterProgressSlider = [[RDZSlider alloc] initWithFrame:CGRectMake(75, ( (40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 30 )/2.0, self.filterView.frame.size.width - 65 - 65, 30)];
        [_filterProgressSlider setMaximumValue:1];
        [_filterProgressSlider setMinimumValue:0];
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道3"];
        image = [image imageWithTintColor];
        [_filterProgressSlider setMinimumTrackImage:image forState:UIControlStateNormal];
        _filterProgressSlider.layer.cornerRadius = 2.0;
        _filterProgressSlider.layer.masksToBounds = YES;
        image = [RDHelpClass imageWithContentOfFile:@"jianji/视频编辑-播放进度轨道2"];
        [_filterProgressSlider setMaximumTrackImage:image forState:UIControlStateNormal];
        
        [_filterProgressSlider  setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
        [_filterProgressSlider setValue:oldFilterStrength];
        _filterProgressSlider.alpha = 1.0;
        _filterProgressSlider.backgroundColor = [UIColor clearColor];
        
        [_filterProgressSlider addTarget:self action:@selector(filterscrub) forControlEvents:UIControlEventValueChanged];
        [_filterProgressSlider addTarget:self action:@selector(filterendScrub) forControlEvents:UIControlEventTouchUpInside];
        [_filterProgressSlider addTarget:self action:@selector(filterendScrub) forControlEvents:UIControlEventTouchCancel];
        
        _percentageLabel = [[UILabel alloc] init];
        _percentageLabel.frame = CGRectMake(self.filterView.frame.size.width - 55, ( (40 + ( (_filterView.frame.size.height - 40) - height )/2.0) - 20 )/2.0, 50, 20);
        _percentageLabel.textAlignment = NSTextAlignmentCenter;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.font = [UIFont systemFontOfSize:12];
        
        float percent = oldFilterStrength*100.0;
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int)percent];
        [_filterView addSubview:_percentageLabel];
    }
    return _filterProgressSlider;
}
//滤镜强度 滑动进度条
- (void)filterscrub{
    CGFloat current = _filterProgressSlider.value;
    float percent = current*100.0;
    if( !newFilterSortArray )
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
    else
    {
        _percentageLabel.hidden = NO;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.frame = CGRectMake(current*_filterProgressSlider.frame.size.width+_filterProgressSlider.frame.origin.x - _percentageLabel.frame.size.width/2.0, _filterProgressSlider.frame.origin.y - _percentageLabel.frame.size.height + 5, _percentageLabel.frame.size.width, _percentageLabel.frame.size.height);
        _percentageLabel.text = [NSString stringWithFormat:@"%d%",(int)percent];
    }
    [_videoCoreSDK setGlobalFilterIntensity:current];
    filterStrength = current;
    [_videoCoreSDK refreshCurrentFrame];
}

- (void)filterendScrub{
    CGFloat current = _filterProgressSlider.value;
    float percent = current*100.0;
    if( !newFilterSortArray )
        _percentageLabel.text = [NSString stringWithFormat:@"%d%%",(int)percent];
    else
    {
        _percentageLabel.hidden = YES;
        _percentageLabel.textColor = Main_Color;
        _percentageLabel.frame = CGRectMake(current*_filterProgressSlider.frame.size.width+_filterProgressSlider.frame.origin.x - _percentageLabel.frame.size.width/2.0, _filterProgressSlider.frame.origin.y - _percentageLabel.frame.size.height + 5, _percentageLabel.frame.size.width, _percentageLabel.frame.size.height);
        _percentageLabel.text = [NSString stringWithFormat:@"%d%",(int)percent];
    }
//    [_videoCoreSDK setGlobalFilterIntensity:current];
    if( self.currentCollage )
    {
        self.currentCollage.vvAsset.filterIntensity = current;
        _videoCoreSDK.watermarkArray[_videoCoreSDK.watermarkArray.count].vvAsset.filterIntensity = current;
        [_videoCoreSDK refreshCurrentFrame];
    }
}

- (void)refreshFilterChildItem{
    __weak typeof(self) myself = self;
    [_globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [myself.filterChildsView viewWithTag:(idx + 1)];
        item.backgroundColor        = [UIColor clearColor];
        if(!item.itemIconView.image){
            if(_navigationController.editConfiguration.filterResourceURL.length>0){
                if(idx == 0){
                    NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                    NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                    NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                    item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
                }else{
                    [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
                }
            }else{
                NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
                }
                NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
            }
        }
    }];
}

- (void)initFilterChildsView {
    [_globalFilters enumerateObjectsUsingBlock:^(RDFilter*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ScrollViewChildItem *item   = [[ScrollViewChildItem alloc] initWithFrame:CGRectMake(idx*(self.filterChildsView.frame.size.height - 15)+10, 0, (self.filterChildsView.frame.size.height - 25), self.filterChildsView.frame.size.height)];
        item.backgroundColor        = [UIColor clearColor];
        if(_navigationController.editConfiguration.filterResourceURL.length>0){
            if(idx == 0){
                NSString* bundlePath    = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle"];
                NSBundle *bundle        = [NSBundle bundleWithPath:bundlePath];
                NSString *filePath      = [bundle pathForResource:[NSString stringWithFormat:@"%@",@"原图"] ofType:@"png"];
                item.itemIconView.image = [UIImage imageWithContentsOfFile:filePath];
            }else{
                [item.itemIconView rd_sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
            }
        }else{
            NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *photoPath     = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",obj.name]];
            item.itemIconView.image = [UIImage imageWithContentsOfFile:photoPath];
        }
        item.fontSize       = 12;
        item.type           = 2;
        item.delegate       = self;
        item.selectedColor  = Main_Color;
        item.normalColor    = UIColorFromRGB(0x888888);
        item.cornerRadius   = item.frame.size.width/2.0;
        item.exclusiveTouch = YES;
        item.itemIconView.backgroundColor   = [UIColor clearColor];
        item.itemTitleLabel.text            = RDLocalizedString(obj.name, nil);
        item.tag                            = idx + 1;
        item.itemTitleLabel.adjustsFontSizeToFitWidth = YES;
        [item setSelected:(idx == self->_selectFilterIndex ? YES : NO)];
        
//        item.itemIconView.layer.cornerRadius = 5;
//        item.itemIconView.layer.masksToBounds = YES;
//        item.itemIconView.userInteractionEnabled = YES;
        [self.filterChildsView addSubview:item];
    }];
    _filterChildsView.contentSize = CGSizeMake(_globalFilters.count * (_filterChildsView.frame.size.height - 15)+20, _filterChildsView.frame.size.height);
    
    if( 0 == self->_selectFilterIndex )
    {
        _filterProgressSlider.enabled = NO;
    }
    
    UIImageView *image;
    image.contentMode = UIViewContentModeScaleAspectFit;
}

#pragma mark- scrollViewChildItemDelegate  水印 配乐 变声 滤镜
- (void)scrollViewChildItemTapCallBlock:(ScrollViewChildItem *)item{
    //滤镜
    if( _fileterScrollView )
        [self setNewFilterChildsView:NO atTypeIndex:currentFilterIndex];
    
    
    __weak typeof(self) myself = self;
    if(((RDNavigationViewController *)self.navigationController).editConfiguration.filterResourceURL.length>0){
        NSDictionary *obj = self.filtersName[item.tag - 1];
        NSString *filterPath = [RDHelpClass pathInCacheDirectory:@"filters"];
        if(item.tag-1 == 0){
            if( _fileterScrollView )
            {
                [self setNewFilterChildsView:NO atTypeIndex:currentFilterIndex];
            }
            else
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:currentFilterIndex+1]) setSelected:NO];
            [item setSelected:YES];
            [self refreshFilter:item.tag - 1];
            return ;
        }
        
        if( filterPath )
        {
            NSString *itemPath = [[[filterPath stringByAppendingPathComponent:obj[@"name"]] stringByAppendingString:@"."] stringByAppendingString:[obj[@"file"] pathExtension]];
            if([[NSFileManager defaultManager] fileExistsAtPath:itemPath]){
                if( _fileterScrollView )
                {
                    [self setNewFilterChildsView:NO atTypeIndex:currentFilterIndex];
                }
                else
                    [((ScrollViewChildItem *)[_filterChildsView viewWithTag:currentFilterIndex+1]) setSelected:NO];
                [item setSelected:YES];
                [self refreshFilter:item.tag - 1];
                return ;
            }
            CGRect rect = [item getIconFrame];
            //            CircleView *ddprogress = [[CircleView alloc]initWithFrame:rect];
            UIView * progress = [RDHelpClass loadProgressView:rect];
            item.downloading = YES;
            if( _fileterScrollView )
            {
                [self setNewFilterChildsView:NO atTypeIndex:currentFilterIndex];
            }
            else
                [((ScrollViewChildItem *)[_filterChildsView viewWithTag:currentFilterIndex+1]) setSelected:NO];
            
            //            ddprogress.progressColor = Main_Color;
            //            ddprogress.progressWidth = 2.f;
            //            ddprogress.progressBackgroundColor = [UIColor clearColor];
            //            [item addSubview:ddprogress];
            [item addSubview:progress];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                RDDownTool *tool = [[RDDownTool alloc] initWithURLPath:obj[@"file"] savePath:itemPath];
                tool.Progress = ^(float numProgress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if( (numProgress >= 0.0) && (numProgress <= 1.0)   )
                        {
                            [progress.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if( [obj isKindOfClass:[UILabel class]] )
                                {
                                    UILabel * label = (UILabel*)obj;
                                    if(label.tag == 1)
                                    {
                                        label.text = [NSString stringWithFormat:@"%d%%", (int)(numProgress*100.0)];
                                    }
                                }
                            }];
                        }
                    });
                };
                
                tool.Finish = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //                        [ddprogress removeFromSuperview];
                        [progress removeFromSuperview];
                        item.downloading = NO;
                        if([myself downLoadingFilterCount]>=1){
                            return ;
                        }
                        if( _fileterScrollView )
                        {
                            for (UIView *subview in _fileterScrollView.subviews) {
                                if( [subview isKindOfClass:[ScrollViewChildItem class] ] )
                                    [(ScrollViewChildItem*)subview setSelected:NO];
                            }
                        }
                        else{
                            [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if([obj isKindOfClass:[ScrollViewChildItem class]]){
                                    
                                    [(ScrollViewChildItem *)obj setSelected:NO];
                                }
                            }];
                        }
                        
                        [item setSelected:YES];
                        [myself refreshFilter:item.tag - 1];
                    });
                };
                [tool start];
            });
        }
    }else{
        if( _fileterScrollView )
        {
            [self setNewFilterChildsView:NO atTypeIndex:currentFilterIndex];
        }
        else
            [((ScrollViewChildItem *)[_filterChildsView viewWithTag:currentFilterIndex+1]) setSelected:NO];
        [item setSelected:YES];
        [self refreshFilter:item.tag - 1];
    }
    
}

/**检测有多少个Filter正在下载
 */
- (NSInteger)downLoadingFilterCount{
    __block int count = 0;
    [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[ScrollViewChildItem class]]){
            if(((ScrollViewChildItem *)obj).downloading){
                count +=1;
            }
        }
    }];
    return count;
}

- (void)refreshFilter:(NSInteger)filterIndex {
    _selectFilterIndex = filterIndex;
    RDFilter* filter = _globalFilters[filterIndex];
    
    if( self.currentCollage )
    {
        if (filter.type == kRDFilterType_LookUp) {
            self.currentCollage.vvAsset.filterType = VVAssetFilterLookup;
        }else if (filter.type == kRDFilterType_ACV) {
            self.currentCollage.vvAsset.filterType = VVAssetFilterACV;
        }else {
            self.currentCollage.vvAsset.filterType = VVAssetFilterEmpty;
        }
        self.currentCollage.vvAsset.filterIntensity = 1.0;
        if (filter.filterPath.length > 0) {
            self.currentCollage.vvAsset.filterUrl = [NSURL fileURLWithPath:filter.filterPath];
        }
//        _videoCoreSDK.watermarkArray[_videoCoreSDK.watermarkArray.count].vvAsset.filterType = self.currentCollage.vvAsset.filterType;
//        _videoCoreSDK.watermarkArray[_videoCoreSDK.watermarkArray.count].vvAsset.filterUrl = self.currentCollage.vvAsset.filterUrl;
//
//        _videoCoreSDK.watermarkArray[_videoCoreSDK.watermarkArray.count].vvAsset.filterIntensity = self.currentCollage.vvAsset.filterIntensity;
        
        [_videoCoreSDK refreshCurrentFrame];
    }
    [_filterProgressSlider setValue:1.0];
}

#pragma mark- 退出
-(void)toolFilterClose_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_SINGLEFILTER isSave:NO];
    }
}
-(void)toolFilterConfirm_Btn
{
    if (_delegate && [_delegate respondsToSelector:@selector(hiddenCollageBarItem: isSave:)]) {
        [_delegate hiddenCollageBarItem:kPIP_SINGLEFILTER isSave:YES];
    }
}

-(void)dealloc
{
    if( _filterChildsView )
    {
        [_filterChildsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if( [obj isKindOfClass: [ScrollViewChildItem class]] )
            {
                [obj removeFromSuperview];
                obj = nil;
            }
        }];
        [_filterChildsView removeFromSuperview];
    }
    if( _filterProgressSlider )
    {
        [_filterProgressSlider removeFromSuperview];
        _filterProgressSlider = nil;
    }
    if( _percentageLabel )
    {
        [_percentageLabel removeFromSuperview];
        _percentageLabel = nil;
    }
    if( _toolFilterView )
    {
        [_toolFilterView removeFromSuperview];
        _toolFilterView = nil;
    }
    if( _fileterLabelNewScroView )
    {
        [_fileterLabelNewScroView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            [obj removeFromSuperview];
            
        }];
        [_fileterLabelNewScroView removeFromSuperview];
        _fileterLabelNewScroView = nil;
    }
    if( _originalItem )
    {
        [_originalItem removeFromSuperview];
        _originalItem = nil;
    }
    if( _filterStrengthLabel )
    {
        [_filterStrengthLabel removeFromSuperview];
        _filterStrengthLabel = nil;
    }
    if( _fileterNewView )
    {
        [_fileterNewView removeFromSuperview];
        _fileterNewView = nil;
    }
    if( _filterView )
    {
        [_filterView removeFromSuperview];
        _filterView = nil;
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
