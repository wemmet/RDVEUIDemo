//
//  RDTranstionCollectionViewCell.h
//  RDVEUISDK
//
//  Created by emmet on 16/2/25.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//


#import <UIKit/UIKit.h>


@protocol RDTranstionCollectionViewCellDelegate<NSObject>

- (void)tapSelectedImage:(id)cell;

@end

@interface RDTranstionCollectionViewCell : UICollectionViewCell

@property (nonatomic , strong)UIImageView *customImageView;

@property (strong , nonatomic)UIImageView *selectImageView;

@property (strong , nonatomic)NSURL *musicUrl;

@property (nonatomic , weak)NSObject<RDTranstionCollectionViewCellDelegate> *delegate;

- (void)initwithRect:(CGRect )rect;


@property (nonatomic , strong)UILabel *customDetailTextLabel;
@property(nonatomic,strong)UILabel *moveTitleLabel;
//文字滚动显示
@property (nonatomic,assign,readonly) BOOL   isStartMove;
- (void)startScrollTitle;

- (void)stopScrollTitle;
-(void)delete;

-(void)textColor:(UIColor *)color;
@end
