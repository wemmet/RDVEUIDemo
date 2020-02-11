//
//  RDFilterChooserView.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import <UIKit/UIKit.h>
#import "RDDownTool.h"
#import "RDFilterChooserViewCell.h"

//#import <RDRecordGPUImage.h>
@interface RDFilterChooserView : UIScrollView

@property (nonatomic,strong) UIImage* filterImage;
@property (nonatomic,assign,readonly) NSInteger  type;
@property (nonatomic,assign) NSInteger currentIndex;
//@property (nonatomic,copy) void(^ChooserBlock) (NSInteger idx);
@property (nonatomic,copy) void(^ChooserBlock) (NSInteger idx,BOOL selectFilter);
//@property (nonatomic,copy) void(^ResetFilterBlock) (NSInteger idx);
- (void) removeItems;
- (void) addFiltersToChooser: (NSArray<RDFilter*> *)filters;
- (void) addItemToChooser:(NSArray *)items itemNames:(NSArray*)names itemPaths:(NSArray*)itemPaths;
- (void) deleteDownload;
@end
