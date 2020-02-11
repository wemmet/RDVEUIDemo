//
//  RDRecordTypeView.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDRecordTypeViewDelegate <NSObject>

- (void)selectedTypeIndex:(NSInteger)typeIndex;

@end

@interface RDRecordTypeView : UIView

@property (nonatomic, weak)id <RDRecordTypeViewDelegate> delegate;

- (void)setItemTitleArray:(NSArray *)itemTitleArray selectedIndex:(NSInteger)index;
- (UIScrollView*)RecordTypeScrollView;
@end
