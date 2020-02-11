//
//  TMVerticallyCenteredTextView.m
//  RDVEUISDK
//
//  Created by 王全洪 on 2018/10/16.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "TMVerticallyCenteredTextView.h"

@interface TMVerticallyCenteredTextView()<UITextViewDelegate>
{
    BOOL _isCenter;
}
@end

@implementation TMVerticallyCenteredTextView

- (id)initWithFrame:(CGRect)frame isCenter:(BOOL)isCenter {
    
    if (self = [super initWithFrame:frame]) {
        _isCenter = isCenter;
        if(_isCenter){
            self.textAlignment = NSTextAlignmentCenter;
            [self addObserver:self forKeyPath:@"contentSize" options: (NSKeyValueObservingOptionNew) context:NULL];
        }
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]){
        
        self.textAlignment = NSTextAlignmentCenter;
        //[self addObserver:self forKeyPath:@"contentSize" options: (NSKeyValueObservingOptionNew) context:NULL];
    }
    return self;
    
}

- (void)refreshContentSize{
    if(_isCenter){
        CGFloat deadSpace = ([self bounds].size.height - [self contentSize].height);
        
        CGFloat inset = MAX(0, deadSpace/2.0);
        
        self.contentInset = UIEdgeInsetsMake(inset, self.contentInset.left, inset, self.contentInset.right);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"contentSize"]) {
        
        UITextView *tv = object;
        
        CGFloat deadSpace = ([tv bounds].size.height - [tv contentSize].height);
        
        CGFloat inset = MAX(0, deadSpace/2.0);
        
        tv.contentInset = UIEdgeInsetsMake(inset, tv.contentInset.left, inset, tv.contentInset.right);
        
    }
    
}

- (void)dealloc {
    if(_isCenter){
        [self removeObserver:self forKeyPath:@"contentSize"];
    }
}

@end

