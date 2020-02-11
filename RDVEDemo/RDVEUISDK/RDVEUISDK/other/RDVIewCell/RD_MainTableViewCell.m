//
//  MainTableViewCell.m
//  RDVEUISDK
//
//  Created by emmet on 16/3/5.
//  Copyright © 2016年 emmet. All rights reserved.
//

#import "RD_MainTableViewCell.h"
#import "RD_CustomItem.h"
#define kCELLWIDTH [UIScreen mainScreen].bounds.size.width
#define kMINSPAN 5 //item 与item之间的间隙
#define kCELLCOUNT 4//每一个cell 需要显示的item个数
#define kCellBUTTONTAG 1000
@implementation RD_MainTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier cellMixSpan:(float)mixSpan cellCount:(NSInteger )cellCount items:(NSInteger)items{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        self.backgroundView = nil;
        self.backgroundColor = [UIColor clearColor];
        float width =(kCELLWIDTH - (cellCount+1) *mixSpan)/cellCount;
        
        for (int i = 0;i<items; i++) {
            
            float orginX = (i *width) + ((i+1) * mixSpan);
            CGRect itemRect = CGRectMake(orginX, 0, width, width);
            RD_CustomItem * cellButton = [[RD_CustomItem alloc] initWithFrame:itemRect];
            cellButton.backgroundColor = [UIColor redColor];
            cellButton.tag = kCellBUTTONTAG + i;
            [cellButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:cellButton];
        }
    }
    return self;
}

- (void)click:(RD_CustomItem *)sender{
    sender.selected = !sender.selected;
    [self setSelectMode:sender.selected sender:sender];
    if(_delegate){
        if([_delegate respondsToSelector:@selector(onTableView:cellItem:index:)]){
            
            UITableView *supTableView = nil;
            if([self.superview.superview isKindOfClass:[UITableView class]]){
                supTableView = (UITableView *)self.superview.superview;
            }
            [_delegate onTableView:supTableView cellItem:sender index:sender.tag];
        }
    }
}

- (void)setSelectMode:(BOOL)bSelect sender:(RD_CustomItem *)sender
{
    if (bSelect){
        
        sender.videoMark.hidden = NO;
        sender.ivImageView.layer.borderColor = [UIColor clearColor].CGColor;
        [UIView animateWithDuration:0.1 animations:^{
            sender.ivImageView.layer.borderWidth = 3;
            sender.ivImageView.alpha = 0.9;
            sender.videoMark.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }
    else{
        sender.ivImageView.layer.borderColor = [UIColor clearColor].CGColor;
        [UIView animateWithDuration:0.1 animations:^{
            sender.ivImageView.layer.borderWidth = 0;
            sender.videoMark.alpha = 0;
        } completion:^(BOOL finished) {
            sender.ivImageView.alpha = 1.0;
            sender.videoMark.hidden = YES;
        }];
        
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)dealloc{
    _delegate = nil;
    NSLog(@"%s",__func__);
}
@end
