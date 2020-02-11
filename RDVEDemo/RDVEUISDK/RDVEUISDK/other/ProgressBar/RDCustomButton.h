//
//  RDCustomButton.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/8/16.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
    DeleteButtonStyleDelete,
    DeleteButtonStyleNormal,
    DeleteButtonStyleDisable,
}DeleteButtonStyle;

@interface RDCustomButton : UIButton
@property (strong, nonatomic) NSString *item;
@property (strong, nonatomic) NSString *itemName;
@property (strong, nonatomic) NSString *itemPath;

@property (assign, nonatomic) DeleteButtonStyle style;
- (id)initWithItem:(NSString *)item itemName:(NSString *)itemName itemPath:(NSString *)itemPath;
- (void)setButtonStyle:(DeleteButtonStyle)style;
- (void)selected:(BOOL)selected;
@end
