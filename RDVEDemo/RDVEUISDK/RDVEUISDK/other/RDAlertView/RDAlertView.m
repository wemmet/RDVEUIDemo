//
//  RDAlertView.m
//  RDVEUISDK
//
//  Created by emmet on 2017/3/29.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//


#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#import "RDAlertView.h"
#import "RDHelpClass.h"
@interface RDAlertView ()<CAAnimationDelegate>
{
    
}
@property (nonatomic, strong, readonly) UIWindow                        *overlayWindow;
@property (nonatomic, strong, readonly) UIView                          *topBar;
@property (nonatomic, weak) NSObject<RDAlertViewDelegate>               *delegate;
@property (nonatomic, strong) UIImageView                               *alertViewBg;
@property (nonatomic, strong) UILabel                                   *messageLabel;
@property (nonatomic, strong) UIButton                                  *cancelButton;
@end

@implementation RDAlertView

@synthesize topBar, overlayWindow;

+ (RDAlertView*)sharedView {
    static dispatch_once_t once;
    static RDAlertView *sharedView;
    dispatch_once(&once, ^ { sharedView = [[RDAlertView alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
    return sharedView;
}

- (id)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (UIWindow *)overlayWindow {
    if(!overlayWindow) {
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayWindow.backgroundColor = [UIColor colorWithRed:1/255.0 green:1/255.0 blue:1/255.0 alpha:0.5];
        overlayWindow.userInteractionEnabled = YES;
        overlayWindow.windowLevel = UIWindowLevelStatusBar;
        overlayWindow.rootViewController = [UIViewController new];
    }
    overlayWindow.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    return overlayWindow;
}

- (UIView *)topBar {
    if(!topBar) {
        topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, overlayWindow.frame.size.width, 20.0)];
        [overlayWindow addSubview:topBar];
    }
    return topBar;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor{
    _alertViewBg.backgroundColor     = backgroundColor;

}

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
}

- (void)deviceOrientationDidChange:(NSNotification *)notification{
    CGRect rect = _alertViewBg.frame;
    [UIView animateWithDuration:0.1 animations:^{
        _alertViewBg.alpha = 0;
    } completion:^(BOOL finished) {
        _alertViewBg.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - rect.size.width)/2.0, ([UIScreen mainScreen].bounds.size.height - rect.size.height)/2.0, rect.size.width, rect.size.height);
        [UIView animateWithDuration:0.1 animations:^{
            _alertViewBg.alpha = 1;
            

        } completion:^(BOOL finished) {
            
        }];
    }];
}

//- (void)setBackguoundImage:(UIImage *)backguoundImage{
//    _alertViewBg.image = backguoundImage;
//}

- (id)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message delegate:(nullable id)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle otherButtonTitleLists:(NSArray *)titleLists{
    self = [RDAlertView sharedView];
    _delegate=delegate;
    if(!self.superview)
        [self.overlayWindow addSubview:self];
    [self.overlayWindow setHidden:NO];
    [self.topBar setHidden:NO];
    
    [self addNotification];
    
    NSArray *otherButtonTitlesList = titleLists;
    
    float totalButtonHeight;
    float buttonHeight = 44;
    if(cancelButtonTitle){
        if(otherButtonTitlesList.count>1){
            totalButtonHeight = otherButtonTitlesList.count * (buttonHeight + 1) + buttonHeight;
        }else{
            totalButtonHeight = buttonHeight;
        }
    }else{
        if(otherButtonTitlesList.count<=2 && otherButtonTitlesList.count > 0){
            totalButtonHeight = buttonHeight;
        }else if(otherButtonTitlesList.count>2){
            totalButtonHeight = (otherButtonTitlesList.count - 1) * (buttonHeight + 1) + buttonHeight;
        }else{
            totalButtonHeight = 0;
        }
    }
    float bgWidth = 320 - 48;
    UIFont *font = [UIFont systemFontOfSize:15];
    CGSize constraintSize = CGSizeMake(bgWidth - 28 - 10, MAXFLOAT);
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect rect = [message boundingRectWithSize:constraintSize
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:attributes
                                        context:nil];
    
    float messageHeight = rect.size.height > 0 ? rect.size.height : 20;
    float selfHeight = totalButtonHeight + messageHeight + 70;
    if(message.length==0){
        messageHeight =0;
        selfHeight = totalButtonHeight + 60;
    }
    
    if (_alertViewBg == nil) {
        CGFloat alertViewy=([[UIScreen mainScreen]applicationFrame].size.height - selfHeight)/2.0;
        _alertViewBg =[[UIImageView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - bgWidth)/2.0, alertViewy, bgWidth, selfHeight)];
        _alertViewBg.userInteractionEnabled=YES;
        _alertViewBg.backgroundColor     = [UIColor colorWithWhite:1 alpha:0.9];
        _alertViewBg.layer.borderColor   = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
        _alertViewBg.layer.borderWidth   = 0;
        _alertViewBg.layer.masksToBounds = YES;
        _alertViewBg.layer.cornerRadius  = 10;
        _alertViewBg.layer.shadowColor   = [UIColor grayColor].CGColor;
        _alertViewBg.layer.shadowOffset  = CGSizeMake(1, 1);
        _alertViewBg.layer.shadowRadius  = 2;
        _alertViewBg.userInteractionEnabled = YES;
        
        UILabel *tishiTitle=[[UILabel alloc] initWithFrame:CGRectMake(20,20, _alertViewBg.frame.size.width-40, 20)];
        tishiTitle.font=[UIFont fontWithName:@"Helvetica" size:17];
        tishiTitle.textAlignment=NSTextAlignmentCenter;
        tishiTitle.text= title;
        tishiTitle.textColor=[UIColor colorWithWhite:0 alpha:1.0];
        tishiTitle.backgroundColor=[UIColor clearColor];
        [_alertViewBg addSubview:tishiTitle];
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 45, _alertViewBg.frame.size.width-28, messageHeight)];
        _messageLabel.textColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = [UIFont systemFontOfSize:14.0];
        _messageLabel.text = message;
        _messageLabel.numberOfLines = 0;
        _messageLabel.backgroundColor=[UIColor colorWithWhite:0.0 alpha:0.0];
        [_alertViewBg addSubview:_messageLabel];
        
        UIImage *colorImageForNormal = [RDHelpClass rdImageWithColor:[UIColor colorWithRed:227.0/255.0 green:229.0/255.0 blue:230.0/255.0 alpha:0.0] cornerRadius:0];
        UIImage *colorImageForHeighted=[RDHelpClass rdImageWithColor:[UIColor colorWithRed:6.0/255.0 green:6.0/255.0 blue:6.0/255.0 alpha:0.1] cornerRadius:0.0];
        
        float spanHeight = selfHeight - totalButtonHeight - messageHeight - _messageLabel.frame.origin.y;
        
        if(cancelButtonTitle){
            _cancelButton=[UIButton buttonWithType:UIButtonTypeCustom];
            if(otherButtonTitlesList.count == 1){
                _cancelButton.frame = CGRectMake(0, _alertViewBg.frame.size.height-buttonHeight, _alertViewBg.frame.size.width/2-0.5, buttonHeight);
            }else{
                _cancelButton.frame = CGRectMake(0, _alertViewBg.frame.size.height-buttonHeight, _alertViewBg.frame.size.width, buttonHeight);
            }
            UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, _cancelButton.frame.origin.y - 1, _alertViewBg.frame.size.width, 1)];
            spanImage.backgroundColor = [UIColor lightGrayColor];
            [_alertViewBg addSubview:spanImage];
            
            
            _cancelButton.tag = 0;
            [_cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
            [_cancelButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
            [_cancelButton addTarget:self action:@selector(cancelButtonTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
            [_cancelButton setBackgroundImage:colorImageForNormal forState:UIControlStateNormal];
            [_cancelButton setBackgroundImage:colorImageForHeighted forState:UIControlStateHighlighted];
            [_alertViewBg addSubview:_cancelButton];
        }
        CGRect otherRect;
        for (int i = 0; i<otherButtonTitlesList.count; i++) {
            UIButton * otherButton=[UIButton buttonWithType:UIButtonTypeCustom];
            if(cancelButtonTitle){
                if(otherButtonTitlesList.count>1){
                    otherRect = CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height + spanHeight + i*(buttonHeight + 1), _alertViewBg.frame.size.width, buttonHeight);
                    UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, otherRect.origin.y - 1, _alertViewBg.frame.size.width, 1)];
                    spanImage.backgroundColor = [UIColor lightGrayColor];
                    [_alertViewBg addSubview:spanImage];
                }else{
                    otherRect = CGRectMake(_alertViewBg.frame.size.width/2 + 0.5, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width/2.0-0.5, buttonHeight);
                }
            }else{
                if(otherButtonTitlesList.count<=2 && otherButtonTitlesList.count > 0){
                    if(otherButtonTitlesList.count == 1){
                        otherRect = CGRectMake(0, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width, buttonHeight);
                        
                    }else{
                        if(i == 0){
                            otherRect = CGRectMake(0, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width/2.0-0.5, buttonHeight);
                        }else{
                            otherRect = CGRectMake(_alertViewBg.frame.size.width/2 + 0.5, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width/2.0-0.5, buttonHeight);
                        }
                    }
                    
                }else if(otherButtonTitlesList.count>2){
                    otherRect = CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height + spanHeight + i*(buttonHeight + 1), _alertViewBg.frame.size.width, buttonHeight);
                    UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, otherRect.origin.y - 1, _alertViewBg.frame.size.width, 1)];
                    spanImage.backgroundColor = [UIColor lightGrayColor];
                    [_alertViewBg addSubview:spanImage];
                }else{
                    otherRect = CGRectZero;
                }
            }
            otherButton.tag = i + 1;
            otherButton.frame = otherRect;
            [otherButton setTitle:otherButtonTitlesList[i] forState:UIControlStateNormal];
            [otherButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
            [otherButton addTarget:self action:@selector(otherButtonTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
            [otherButton setBackgroundImage:colorImageForNormal forState:UIControlStateNormal];
            [otherButton setBackgroundImage:colorImageForHeighted forState:UIControlStateHighlighted];
            [_alertViewBg addSubview:otherButton];
            
        }
        if(totalButtonHeight == buttonHeight){
            if(!cancelButtonTitle){
                UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, _alertViewBg.frame.size.height - buttonHeight - 1, _alertViewBg.frame.size.width, 1)];
                spanImage.backgroundColor = [UIColor lightGrayColor];
                [_alertViewBg addSubview:spanImage];
            }
            if(_cancelButton.frame.size.width<_alertViewBg.frame.size.width/2.0){
                UIImageView *spanImageMiddle=[[UIImageView alloc] initWithFrame:CGRectMake(_alertViewBg.frame.size.width/2-0.5, _alertViewBg.frame.size.height-buttonHeight, 1,buttonHeight)];
                spanImageMiddle.backgroundColor = [UIColor lightGrayColor];
                [_alertViewBg addSubview:spanImageMiddle];
            }
            
        }
        
    }
    
    if(!_alertViewBg.superview)
        [self.overlayWindow addSubview:_alertViewBg];
    
    return self;
}

- (id)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message delegate:(nullable id)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle otherButtonTitles:(nullable NSString *)otherButtonTitles,...{
    self = [RDAlertView sharedView];
    _delegate=delegate;
    if(!self.superview)
        [self.overlayWindow addSubview:self];
    [self.overlayWindow setHidden:NO];
    [self.topBar setHidden:NO];
    [self addNotification];
    NSMutableArray *otherButtonTitlesList = [[NSMutableArray alloc] init];
    
    va_list args;
    // 获取第一个可选参数的地址，此时参数列表指针指向函数参数列表中的第一个可选参数
    va_start(args, otherButtonTitles);
    if(otherButtonTitles)
    {
        // 遍历参数列表中的参数，并使参数列表指针指向参数列表中的下一个参数
        [otherButtonTitlesList addObject:otherButtonTitles];
        
        NSString *nextArg;
        @try {
            while((nextArg = va_arg(args, NSString *)))
            {
                NSLog(@"ARG :%@", nextArg);
                if(!nextArg){
                    break;
                }
                [otherButtonTitlesList addObject:nextArg];
                
            }
        } @catch (NSException *exception) {
            
        }
    }
    // 结束可变参数的获取(清空参数列表)
    va_end(args);
    
    
    
//    NSInteger count = otherButtonTitlesList.count + (cancelButtonTitle.length>0 ? 1:0);
    float totalButtonHeight;
    float buttonHeight = 44;
    if(cancelButtonTitle){
        if(otherButtonTitlesList.count>1){
            totalButtonHeight = otherButtonTitlesList.count * (buttonHeight + 1) + buttonHeight;
        }else{
            totalButtonHeight = buttonHeight;
        }
    }else{
        if(otherButtonTitlesList.count<=2 && otherButtonTitlesList.count > 0){
            totalButtonHeight = buttonHeight;
        }else if(otherButtonTitlesList.count>2){
            totalButtonHeight = (otherButtonTitlesList.count - 1) * (buttonHeight + 1) + buttonHeight;
        }else{
            totalButtonHeight = 0;
        }
    }
    float bgWidth = 320 - 48;
    UIFont *font = [UIFont systemFontOfSize:15];
    CGSize constraintSize = CGSizeMake(bgWidth - 28 - 10, MAXFLOAT);
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect rect = [message boundingRectWithSize:constraintSize
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:attributes
                                        context:nil];
    
    float messageHeight = rect.size.height > 0 ? rect.size.height : 20;
    float selfHeight = totalButtonHeight + messageHeight + 70;
    
    if (_alertViewBg == nil) {
        CGFloat alertViewy=([[UIScreen mainScreen]applicationFrame].size.height - selfHeight)/2.0;
        _alertViewBg =[[UIImageView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - bgWidth)/2.0, alertViewy, bgWidth, selfHeight)];
        _alertViewBg.userInteractionEnabled=YES;
        _alertViewBg.backgroundColor     = [UIColor colorWithWhite:1 alpha:0.9];
        _alertViewBg.layer.borderColor   = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
        _alertViewBg.layer.borderWidth   = 0;
        _alertViewBg.layer.masksToBounds = YES;
        _alertViewBg.layer.cornerRadius  = 10;
        _alertViewBg.layer.shadowColor   = [UIColor grayColor].CGColor;
        _alertViewBg.layer.shadowOffset  = CGSizeMake(1, 1);
        _alertViewBg.layer.shadowRadius  = 2;
        _alertViewBg.userInteractionEnabled = YES;
        
        UILabel *tishiTitle=[[UILabel alloc] initWithFrame:CGRectMake(20,20, _alertViewBg.frame.size.width-40, 20)];
        tishiTitle.font=[UIFont fontWithName:@"Helvetica" size:17];
        tishiTitle.textAlignment=NSTextAlignmentCenter;
        tishiTitle.text= title;
        tishiTitle.textColor=[UIColor colorWithWhite:0 alpha:1.0];
        tishiTitle.backgroundColor=[UIColor clearColor];
        [_alertViewBg addSubview:tishiTitle];
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 45, _alertViewBg.frame.size.width-28, messageHeight)];
        _messageLabel.textColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = [UIFont systemFontOfSize:14.0];
        _messageLabel.text = message;
        _messageLabel.numberOfLines = 0;
        _messageLabel.backgroundColor=[UIColor colorWithWhite:0.0 alpha:0.0];
        [_alertViewBg addSubview:_messageLabel];
        
        UIImage *colorImageForNormal = [RDHelpClass rdImageWithColor:[UIColor colorWithRed:227.0/255.0 green:229.0/255.0 blue:230.0/255.0 alpha:0.0] cornerRadius:1];
        UIImage *colorImageForHeighted=[RDHelpClass rdImageWithColor:[UIColor colorWithRed:6.0/255.0 green:6.0/255.0 blue:6.0/255.0 alpha:0.1] cornerRadius:1.0];
        
        float spanHeight = selfHeight - totalButtonHeight - messageHeight - _messageLabel.frame.origin.y;
        
        if(cancelButtonTitle){
            _cancelButton=[UIButton buttonWithType:UIButtonTypeCustom];
            if(otherButtonTitlesList.count == 1){
                _cancelButton.frame = CGRectMake(0, _alertViewBg.frame.size.height-buttonHeight, _alertViewBg.frame.size.width/2-0.5, buttonHeight);
            }else{
                _cancelButton.frame = CGRectMake(0, _alertViewBg.frame.size.height-buttonHeight, _alertViewBg.frame.size.width, buttonHeight);
            }
            UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, _cancelButton.frame.origin.y - 1, _alertViewBg.frame.size.width, 1)];
            spanImage.backgroundColor = [UIColor lightGrayColor];
            [_alertViewBg addSubview:spanImage];
            
            
            _cancelButton.tag = 0;
            [_cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
            [_cancelButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
            [_cancelButton addTarget:self action:@selector(cancelButtonTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
            [_cancelButton setBackgroundImage:colorImageForNormal forState:UIControlStateNormal];
            [_cancelButton setBackgroundImage:colorImageForHeighted forState:UIControlStateHighlighted];
            [_alertViewBg addSubview:_cancelButton];
        }
        CGRect otherRect;
        for (int i = 0; i<otherButtonTitlesList.count; i++) {
            UIButton * otherButton=[UIButton buttonWithType:UIButtonTypeCustom];
            if(cancelButtonTitle){
                if(otherButtonTitlesList.count>1){
                    otherRect = CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height + spanHeight + i*(buttonHeight + 1), _alertViewBg.frame.size.width, buttonHeight);
                    UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, otherRect.origin.y - 1, _alertViewBg.frame.size.width, 1)];
                    spanImage.backgroundColor = [UIColor lightGrayColor];
                    [_alertViewBg addSubview:spanImage];
                }else{
                    otherRect = CGRectMake(_alertViewBg.frame.size.width/2 + 0.5, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width/2.0-0.5, buttonHeight);
                }
            }else{
                if(otherButtonTitlesList.count<=2 && otherButtonTitlesList.count > 0){
                    if(otherButtonTitlesList.count == 1){
                        otherRect = CGRectMake(0, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width, buttonHeight);
                        
                    }else{
                        if(i == 0){
                            otherRect = CGRectMake(0, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width/2.0-0.5, buttonHeight);
                        }else{
                            otherRect = CGRectMake(_alertViewBg.frame.size.width/2 + 0.5, _alertViewBg.frame.size.height - buttonHeight, _alertViewBg.frame.size.width/2.0-0.5, buttonHeight);
                        }
                    }
                    
                }else if(otherButtonTitlesList.count>2){
                    otherRect = CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height + spanHeight + i*(buttonHeight + 1), _alertViewBg.frame.size.width, buttonHeight);
                    UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, otherRect.origin.y - 1, _alertViewBg.frame.size.width, 1)];
                    spanImage.backgroundColor = [UIColor lightGrayColor];
                    [_alertViewBg addSubview:spanImage];
                }else{
                    otherRect = CGRectZero;
                }
            }
            otherButton.tag = i + 1;
            otherButton.frame = otherRect;
            [otherButton setTitle:otherButtonTitlesList[i] forState:UIControlStateNormal];
            [otherButton setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
            [otherButton addTarget:self action:@selector(otherButtonTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
            [otherButton setBackgroundImage:colorImageForNormal forState:UIControlStateNormal];
            [otherButton setBackgroundImage:colorImageForHeighted forState:UIControlStateHighlighted];
            [_alertViewBg addSubview:otherButton];
            
        }
        if(totalButtonHeight == buttonHeight){
            if(!cancelButtonTitle){
                UIImageView *spanImage     = [[UIImageView alloc] initWithFrame:CGRectMake(0, _alertViewBg.frame.size.height - buttonHeight - 1, _alertViewBg.frame.size.width, 1)];
                spanImage.backgroundColor = [UIColor lightGrayColor];
                [_alertViewBg addSubview:spanImage];
            }
            if(_cancelButton.frame.size.width<_alertViewBg.frame.size.width/2.0){
                UIImageView *spanImageMiddle=[[UIImageView alloc] initWithFrame:CGRectMake(_alertViewBg.frame.size.width/2-0.5, _alertViewBg.frame.size.height-buttonHeight, 1,buttonHeight)];
                spanImageMiddle.backgroundColor = [UIColor lightGrayColor];
                [_alertViewBg addSubview:spanImageMiddle];
            }
            
        }else{
        
        }
        
    }
    
    if(!_alertViewBg.superview)
        [self.overlayWindow addSubview:_alertViewBg];
    
    return self;
}

- (void)changeMessage:(NSString *)string{
    _messageLabel.text = string;
}

- (void)show{
    CAKeyframeAnimation * animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.5;
    animation.delegate = self;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
    //        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    
    animation.values = values;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: @"easeInEaseOut"];
    [_alertViewBg.layer addAnimation:animation forKey:nil];
    
}
- (void) dismiss
{
    [UIView animateWithDuration:0.25 animations:^{
        self.alertViewBg.alpha=0;
        self.overlayWindow.alpha=0;
    } completion:^(BOOL finished) {
        [topBar removeFromSuperview];
        topBar = nil;
        [_alertViewBg removeFromSuperview];
        _alertViewBg=nil;
        [overlayWindow removeFromSuperview];
        overlayWindow = nil;
        _delegate = nil;
    }];
}

- (void)otherButtonTouchUpInSide:(UIButton *)sender{
    NSLog(@"点击otherButton:%ld",(long)sender.tag);
    if(_delegate){
        if([_delegate respondsToSelector:@selector(rdAlertView:clickedButtonAtIndex:)]){
            
            [_delegate rdAlertView:self clickedButtonAtIndex:sender.tag];
        }
    }
    [[RDAlertView sharedView] dismiss];
}

- (void)cancelButtonTouchUpInSide:(UIButton *)sender{
    NSLog(@"点击CancelButton:%ld",(long)sender.tag);
   
    if(_delegate){
        if([_delegate respondsToSelector:@selector(rdAlertViewCancel:)]){
            [_delegate rdAlertViewCancel:self];
        }else{
            if([_delegate respondsToSelector:@selector(rdAlertView:clickedButtonAtIndex:)]){
                [_delegate rdAlertView:self clickedButtonAtIndex:sender.tag];
            }
        }
    }
    [[RDAlertView sharedView] dismiss];
}
- (void)dealloc{
    [self removeNotification];
    _delegate = nil;
    NSLog(@"%s",__func__);
}
@end
