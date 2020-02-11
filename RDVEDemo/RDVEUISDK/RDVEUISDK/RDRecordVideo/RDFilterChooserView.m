//
//  RDFilterChooserView.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import "RDFilterChooserView.h"
#import "RDHelpClass.h"
static float const cell_width = 80.0f;

@interface RDFilterChooserView () {
    NSArray *_filters;
    NSArray *_items;
    NSArray *_names;
    NSMutableArray<RDFilterChooserViewCell *> *_cells;
    NSInteger _currentSelectIndex;
    
    
    RDDownTool* tool;
    BOOL isDownloading;
}

@end

@implementation RDFilterChooserView


- (void)setCurrentIndex:(NSInteger)currentIndex{
    _currentIndex = currentIndex;
    
    [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(_currentIndex == idx){
            [obj setState:UIControlStateSelected value:1.0];
        }else{
            [obj setState:UIControlStateNormal value:0.0];
        }
    }];
}


- (void) removeItems;
{
    _type  = -1;
    _currentSelectIndex = -1;
    _cells = [NSMutableArray arrayWithCapacity:0];
    
    self.showsHorizontalScrollIndicator = NO;
    
    if (self.subviews.count)
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.contentSize = CGSizeMake(self.frame.size.width, 0);


}
- (void)addItemToChooser:(NSArray *)items itemNames:(NSArray*)names itemPaths:(NSArray*)itemPaths;
{
    if(names.count==0){
        return;
    }
    _type = 1;
    _currentSelectIndex = -1;
    _items = items;
    _names = names;
    _cells = [NSMutableArray arrayWithCapacity:0];
    isDownloading = NO;
    self.showsHorizontalScrollIndicator = NO;
    if (self.subviews.count)
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.contentSize = CGSizeMake(cell_width * _items.count, 0);

    [_items enumerateObjectsUsingBlock:^(NSString*  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        RDFilterChooserViewCell *cell = [[RDFilterChooserViewCell alloc] initWithFrame:CGRectMake(self.contentSize.width + idx * cell_width, 0.0f, cell_width, self.bounds.size.height)];
        cell.tag = idx + 1;
        cell.titleLabel.text = names[idx];
        [cell setImage:itemPaths[idx] name:names[idx]];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clicked:)];
        [cell addGestureRecognizer:tap];
        [self addSubview:cell];
        [_cells addObject:cell];
    }];
    
    RDFilterChooserViewCell *cell = _cells[_currentIndex];
    [cell setState:UIControlStateSelected value:1.0];

    
}

- (void) addFiltersToChooser: (NSArray<RDFilter*> *)filters{
    if(filters.count==0){
        return;
    }
    _type = 2;
    _currentSelectIndex = -1;
    _filters = filters;
    _cells = [NSMutableArray arrayWithCapacity:0];
    
    self.showsHorizontalScrollIndicator = NO;
    if (self.subviews.count)
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.contentSize = CGSizeMake(cell_width * _filters.count, 0);
    [_filters enumerateObjectsUsingBlock:^(RDFilter *filter, NSUInteger idx, BOOL *stop) {
        RDFilterChooserViewCell *cell = [[RDFilterChooserViewCell alloc] initWithFrame:CGRectMake(self.contentSize.width + idx * cell_width, 0.0f, cell_width, self.bounds.size.height)];
        cell.tag = idx + 1;
        //cell.titleLabel.text = filter.name;
        [cell setFilter:filter];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clicked:)];
        [cell addGestureRecognizer:tap];
        [self addSubview:cell];
        [_cells addObject:cell];
    }];
    
    RDFilterChooserViewCell *cell = _cells[_currentIndex];
    [cell setState:UIControlStateSelected value:1.0];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        cell.frame = CGRectMake((cell.tag - 1) * cell_width , cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);

    }];
    
}
- (void)clicked:(UITapGestureRecognizer *)tap {
    if (tap.view.tag == _currentSelectIndex) return;
    
    
    NSUInteger index = tap.view.tag -1 ;
    
    NSLog(@"%ld",(long)_type);
    RDFilterChooserViewCell *currentcell = (RDFilterChooserViewCell *)tap.view;

    if (_type == 1) {
        if (isDownloading) {
            return;
        }
        // 判断是否需要下载 绘制进度
        NSString* bundlePath = [_items objectAtIndex:index];
        if ([bundlePath hasPrefix:@"http"]) {
            NSString* bundleName = [_names objectAtIndex:index];
            NSString* bundleSavePath = [RDHelpClass getFaceUFilePathString:bundleName type:@"bundle"];
            NSFileManager* fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:bundleSavePath]) {
                
                [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell *  _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (!(idx == tap.view.tag -1)) {
                        [cell setState:UIControlStateNormal value:0.0];
                    }
                }];

                [currentcell setState:UIControlStateSelected value:1.0];
                _currentSelectIndex = currentcell.tag;

                if ([self ChooserBlock]) {
                    _ChooserBlock(currentcell.tag - 1,YES);
                }
                
            }else{
                
                [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell *  _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (!(idx == tap.view.tag -1)) {
                        [cell setState:UIControlStateNormal value:0.0];
                    }
                }];

                
                tool = [[RDDownTool alloc] initWithURLPath:bundlePath savePath:bundleSavePath];
                isDownloading = YES;
                currentcell.isDowning = YES;
                [tool setProgress:^(float value) {
                    [currentcell setState:UIControlStateSelected value:value];

                }];
                __weak typeof(self) weakSelf = self;
                [tool setFinish:^{
                    __strong typeof(self) selfBlock = weakSelf;
                    isDownloading = NO;
                    currentcell.isDowning = NO;

                    _currentSelectIndex = currentcell.tag;
                    
                    if ([selfBlock ChooserBlock]) {
                        weakSelf.ChooserBlock(currentcell.tag - 1,YES);
                    }

                }];
               
                [tool start];
                
                // 下载
            }

            
        }else{
            
            [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell *  _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!(idx == tap.view.tag -1)) {
                    [cell setState:UIControlStateNormal value:0.0];
                }
            }];

            _currentSelectIndex = currentcell.tag;

            [currentcell setState:UIControlStateSelected value:1.0];
            
            if ([self ChooserBlock]) {
                _ChooserBlock(currentcell.tag - 1,YES);
            }
        }

    }else{
        
        if(_filters){
            RDFilter *itemFilter = ((RDFilter *)_filters[currentcell.tag-1]);
            if(itemFilter.netFile.length>0){
                //NSString* bundleName = [_names objectAtIndex:index];
                NSString* bundleSavePath = itemFilter.filterPath;//[RDHelpClass getFaceUFilePathString:bundleName type:@"bundle"];
                NSFileManager* fileManager = [NSFileManager defaultManager];
                if (![fileManager fileExistsAtPath:bundleSavePath]) {
                    
                    tool = [[RDDownTool alloc] initWithURLPath:itemFilter.netFile savePath:bundleSavePath];
//                    isDownloading = YES;
                    currentcell.isDowning = YES;
                    [tool setProgress:^(float value) {
                        [currentcell setState:UIControlStateSelected value:value];
                        
                    }];
                    __weak typeof(self) weakSelf = self;
                    [tool setFinish:^{
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            __strong typeof(self) selfBlock = weakSelf;
//                        isDownloading = NO;
                            currentcell.isDowning = NO;
                            
                            NSInteger downCount = [selfBlock downingCount];
                            if(downCount <1){
                                [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell *  _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
                                    if ((idx == _currentSelectIndex -1)) {
                                        [cell setState:UIControlStateNormal value:0.0];
                                    }else if(_currentSelectIndex == -1){
                                        if(idx == 0){
                                            [cell setState:UIControlStateNormal value:0.0];
                                        }
                                    }
                                }];
                                _currentSelectIndex = currentcell.tag;
                            }else{
                                [currentcell setState:UIControlStateNormal value:0.0];
                            }
                            if ([selfBlock ChooserBlock]) {
                                NSLog(@"选中滤镜");
                                weakSelf.ChooserBlock(currentcell.tag - 1,(downCount<1 ? YES : NO));
                            }
                            
                        });
                    }];
                    
                    [tool start];
                    
                    return;
                }
            }
            [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell *  _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!(idx == tap.view.tag -1)) {
                    [cell setState:UIControlStateNormal value:0.0];
                }
            }];
            
            
            _currentSelectIndex = currentcell.tag;
            
            [currentcell setState:UIControlStateSelected value:1.0];
            
            if ([self ChooserBlock]) {
                _ChooserBlock(currentcell.tag - 1,YES);
            }
        }
    }
}

- (NSInteger )downingCount{
    __block NSInteger count = 0;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[RDFilterChooserViewCell class]]){
            if(((RDFilterChooserViewCell *)obj).isDowning){
                count +=1;
            }
        }
    }];
    return count;
}


- (void) deleteDownload
{
    tool.Progress = nil;
    tool.Finish = nil;
    tool = nil;
    [_cells enumerateObjectsUsingBlock:^(RDFilterChooserViewCell * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
}
- (void)dealloc{
    NSLog(@"%s",__func__);
//    _filterChooserBlock = nil;
    
}

@end
