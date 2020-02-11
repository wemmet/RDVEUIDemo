//
//  RDRecordTypeView.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/6/5.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDRecordTypeView.h"

@interface RDRecordTypeView()<UIScrollViewDelegate>
{    
    UIScrollView                *recordTypeScrollView;
    bool                        isTextToSpeech;
}

@end

@implementation RDRecordTypeView

-(UIScrollView*)RecordTypeScrollView
{
    isTextToSpeech = YES;
    return recordTypeScrollView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        isTextToSpeech = NO;
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = @[(id)[UIColor colorWithWhite:0 alpha:0.3].CGColor,(id)[UIColor clearColor].CGColor];
        gradient.startPoint = CGPointMake(0, 1.0);
        gradient.endPoint = CGPointMake(0, 1.0);
        [self.layer addSublayer:gradient];
        
        UIView *pointView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - 6)/2.0, frame.size.height - 6, 6, 6)];
        pointView.backgroundColor = [UIColor whiteColor];
        pointView.layer.cornerRadius = 3;
        [self addSubview:pointView];
    }
    return self;
}

- (void)setItemTitleArray:(NSArray *)itemTitleArray selectedIndex:(NSInteger)index {
    NSInteger typeCount = itemTitleArray.count;
    __block float width = 40;
    recordTypeScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake((kWIDTH - (width + 20)*(typeCount*2 - 1))/2.0, 0, (width + 20)*(typeCount*2 - 1), 44)];
    recordTypeScrollView.showsHorizontalScrollIndicator = NO;
    recordTypeScrollView.showsVerticalScrollIndicator = NO;
    recordTypeScrollView.delegate = self;
    [self addSubview:recordTypeScrollView];
    
    __block float contentWidth = 0.0;
    [itemTitleArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake((recordTypeScrollView.bounds.size.width - width)/2.0 + (width + 20) * idx, 0, width, 44);
        [itemBtn setTitle:obj forState:UIControlStateNormal];
        [itemBtn setTitleColor:CUSTOM_GRAYCOLOR forState:UIControlStateNormal];
        [itemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        itemBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
        itemBtn.tag = idx+1;
        if (idx == index) {
            itemBtn.selected = YES;
        }
        [itemBtn sizeToFit];
        if (itemBtn.bounds.size.width > width) {
            CGRect frame = recordTypeScrollView.frame;
            frame.size.width += (itemBtn.bounds.size.width - width) + 40;
            frame.origin.x = (kWIDTH - frame.size.width)/2.0;
            recordTypeScrollView.frame = frame;
            itemBtn.frame = CGRectMake((recordTypeScrollView.bounds.size.width - width)/2.0 + contentWidth, 0, itemBtn.bounds.size.width, 44);
        }else {
            itemBtn.frame = CGRectMake((recordTypeScrollView.bounds.size.width - width)/2.0 + contentWidth, 0, width, 44);
        }
        contentWidth += itemBtn.bounds.size.width + 20;
        [itemBtn addTarget:self action:@selector(recordTypeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [recordTypeScrollView addSubview:itemBtn];
    }];
    float firstW = [recordTypeScrollView viewWithTag:1].frame.size.width + 20;
    recordTypeScrollView.contentSize = CGSizeMake(contentWidth*2 + firstW, 0);
    if (index != 0) {
        [self recordTypeBtnAction:((UIButton *)[recordTypeScrollView viewWithTag:index + 1])];
    }
}

- (void)recordTypeBtnAction:(UIButton *)sender {
    sender.selected = YES;
    __block float firstX = 0;
    [recordTypeScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *itemBtn = (UIButton *)obj;
            if (itemBtn.tag == 1) {
                firstX = itemBtn.frame.origin.x;
            }
            if (itemBtn != sender) {
                itemBtn.selected = NO;
            }
        }
    }];
    
    if (_delegate && [_delegate respondsToSelector:@selector(selectedTypeIndex:)]) {
        [_delegate selectedTypeIndex:sender.tag - 1];
    }
    WeakSelf(self);
    [UIView animateWithDuration:0.3 animations:^{
        StrongSelf(self);
        if( isTextToSpeech )
        {
            strongSelf->recordTypeScrollView.contentOffset = CGPointMake(sender.frame.origin.x - (recordTypeScrollView.bounds.size.width - sender.frame.size.width)/2.0, 0);
        }
        else
            strongSelf->recordTypeScrollView.contentOffset = CGPointMake(sender.frame.origin.x - firstX, 0);
    }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self resetContenOffset:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self resetContenOffset:scrollView];
}

- (void)resetContenOffset:(UIScrollView *)scrollView {
    float firstX = [scrollView viewWithTag:1].frame.origin.x;
    WeakSelf(self);
    [scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            if (firstX + scrollView.contentOffset.x <= obj.frame.origin.x + (obj.bounds.size.width + 20)/2.0) {
                [weakSelf recordTypeBtnAction:(UIButton *)obj];
                *stop = YES;
            }
        }
    }];
}

@end
