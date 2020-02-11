//
//  SelectionCollectionViewCell.h
//  RDVEUISDK
//
//  Created by emmet on 16/6/29.
//  Copyright © 2016年 com.rd.emmet. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,RD_SelectionBtnState){
    Normal,
    Selected
};

typedef void(^RD_BtnAction) (UIButton * btn);
@interface RD_SelectionCollectionViewCell : UICollectionViewCell
@property (nonatomic,strong ) RDFile          *thumbfile;
@property (nonatomic,assign ) RD_SelectionBtnState state;
@property (nonatomic,copy ) NSString             * title;

@property (nonatomic,strong ) UIImageView          *coverView;

@property (nonatomic,strong ) UIImageView          *thumbIconView;

@property (strong, nonatomic) UILabel              *thumbIdlabel;

@property (nonatomic,strong ) UIImageView          *fileTypeView;
@property (nonatomic,strong ) UIView               *durationBackView;
@property (strong, nonatomic) UILabel              *thumbDurationlabel;

@property (strong, nonatomic) UIButton             *thumbDeletedBtn;
/** 设置删除按钮
 */
-(void)setDeleteBtn:(bool)isShow deleteAction:(void(^) (RDFile * file)) DeleteBtnAction;


@property (assign, nonatomic) BOOL                 canAddTouch;
@end
