//
//  MainTableViewCell.h
//  RDVEUISDK
//
//  Created by emmet on 16/3/5.
//  Copyright © 2016年 emmet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RD_MainTableViewCell : UITableViewCell


@property (weak) id delegate;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier cellMixSpan:(float)mixSpan cellCount:(NSInteger )cellCount items:(NSInteger)items;

- (void)click:(UIButton *)sender;

@end

@protocol RDcellIetmDelegate <NSObject>

@optional
- (void)onTableView:(UITableView *)tableview cellItem:(id)item index:(NSInteger)index;

@end
