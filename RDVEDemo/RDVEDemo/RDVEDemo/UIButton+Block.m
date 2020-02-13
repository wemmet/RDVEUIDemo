//
//  UIButton+Block.m
//  RDVEDemo
//
//  Created by 周晓林 on 2017/3/23.
//  Copyright © 2017年 RDVEDemo. All rights reserved.
//

#import "UIButton+Block.h"
#import<objc/runtime.h>
@implementation UIButton (Block)
-(void)setBlock:(void(^)(UIButton*))block

{
    
    objc_setAssociatedObject(self,@selector(block), block,OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self addTarget: self action:@selector(click:)forControlEvents:UIControlEventTouchUpInside];
    
}

-(void(^)(UIButton*))block

{
    
    return objc_getAssociatedObject(self,@selector(block));
    
}

-(void)addTapBlock:(void(^)(UIButton*))block

{
    
    self.block= block;
    
    [self addTarget: self action:@selector(click:)forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)click:(UIButton*)btn

{
    
    if(self.block) {
        
        self.block(btn);
        
    }
    
}
@end
