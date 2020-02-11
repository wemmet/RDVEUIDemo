//
//  UITextFieldKeybordDelete.m
//  RDVEUISDK
//
//  Created by apple on 2019/9/4.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "UITextFieldKeybordDelete.h"

@implementation UITextFieldKeybordDelete

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
     // Drawing code
 }
 */

- (void) deleteBackward{
    [super deleteBackward];
    if (_keyInputDelegate && [_keyInputDelegate respondsToSelector:@selector(deleteBackward:)]) {
        [_keyInputDelegate deleteBackward:self];
    }
}

@end
