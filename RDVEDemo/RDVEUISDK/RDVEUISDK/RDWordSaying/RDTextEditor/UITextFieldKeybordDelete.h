//
//  UITextFieldKeybordDelete.h
//  RDVEUISDK
//
//  Created by apple on 2019/9/4.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITextFieldKeybordDelete;

@protocol keyInputTextFieldDelegate <NSObject>

- (void) deleteBackward:(UITextFieldKeybordDelete *) textField;

@end

@interface UITextFieldKeybordDelete : UITextField
@property (nonatomic,weak) id<keyInputTextFieldDelegate>keyInputDelegate;
@end

