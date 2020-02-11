//
//  CustomButton.h
//  RDVEUISDK
//
//  Created by emmet on 16/1/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@interface CustomButton : UIButton
@property (nonatomic,strong)NSMutableDictionary *paramsDic;
@property (nonatomic,strong)NSIndexPath *indexPath;
@property (nonatomic,assign)NSInteger indexRow;
@property (nonatomic,strong)id object;
@end
