//
//  RDCustomButton.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/8/16.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDCustomButton.h"
#import "RDHelpClass.h"
#define DELETE_BTN_NORMAL_IAMGE @"拍摄_删除视频片段默认_"
#define DELETE_BTN_DELETE_IAMGE @"拍摄_删除视频片段点击_"
#define DELETE_BTN_DISABLE_IMAGE @"拍摄_删除视频片段不可用_"

@interface RDCustomButton ()


@end

@implementation RDCustomButton
- (id)initWithItem:(NSString *)item itemName:(NSString *)itemName itemPath:(NSString *)itemPath
{
    self = [super init];
    if (self) {
        _item = item;
        _itemName = itemName;
        _itemPath = itemPath;
        [self setImage:nil forState:UIControlStateNormal];
        [self setImage:nil forState:UIControlStateHighlighted];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize
{
    [self setImage:[RDHelpClass getBundleImage:DELETE_BTN_DISABLE_IMAGE] forState:UIControlStateNormal];
    [self setImage:[RDHelpClass getBundleImage:DELETE_BTN_DELETE_IAMGE] forState:UIControlStateHighlighted];
    
}


- (void)setButtonStyle:(DeleteButtonStyle)style
{
    self.style = style;
    switch (style) {
        case DeleteButtonStyleNormal:
        {
            self.enabled = YES;
            [self setImage:[RDHelpClass getBundleImage:DELETE_BTN_NORMAL_IAMGE] forState:UIControlStateNormal];
        }
            break;
        case DeleteButtonStyleDisable:
        {
            self.enabled = NO;
            [self setImage:[RDHelpClass getBundleImage:DELETE_BTN_DISABLE_IMAGE] forState:UIControlStateNormal];

        }
            break;
        case DeleteButtonStyleDelete:
        {
            self.enabled = YES;
            [self setImage:[RDHelpClass getBundleImage:DELETE_BTN_DELETE_IAMGE] forState:UIControlStateNormal];
        }
            break;
        default:
            break;
    }
}

- (void)selected:(BOOL)selected{
    if(selected){
        self.layer.borderColor = ((UIColor*)Main_Color).CGColor;
        self.layer.borderWidth = 2;
        self.layer.cornerRadius = 4;
    }else{
        self.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
        self.layer.borderWidth = 2;
        self.layer.cornerRadius = 4;
    }
}

@end
