//
//  UIButton+Block.h
//  RDVEDemo
//
//  Created by 周晓林 on 2017/3/23.
//  Copyright © 2017年 RDVEDemo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (Block)
@property (nonatomic,copy) void(^block)(UIButton *sender);
-(void) addTapBlock:(void(^)(UIButton * btn) )block;
@end
