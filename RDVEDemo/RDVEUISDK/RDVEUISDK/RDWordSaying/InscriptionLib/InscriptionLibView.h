//
//  InscriptionLibView.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/21.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RDInscriptionLibViewDelegate <NSObject>

-(void)select:(NSArray *)str atIsCustomize:(bool)isCustomize;
-(void)CustomInscription;
@end

@interface InscriptionLibView : UIView

//标题
@property(nonatomic,strong)UIView               *titleView;

@property (nonatomic,assign)NSInteger   selectedIndex;
@property (nonatomic, weak)id<RDInscriptionLibViewDelegate> InscriptionLibDelegate;
@end

NS_ASSUME_NONNULL_END
