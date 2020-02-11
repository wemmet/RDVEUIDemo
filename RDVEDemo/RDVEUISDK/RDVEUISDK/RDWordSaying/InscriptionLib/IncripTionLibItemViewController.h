//
//  IncripTionLibItemViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/21.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDIncripTionLibItemViewControllerDelegate <NSObject>

-(void)select:(NSArray *)str atIsCustomize:(bool)isCustomize;

-(void)DisplayText:(NSArray *) str;

@end

@interface IncripTionLibItemViewController : UIViewController
{
    UITableView                 *_IncripTionLibTableView;
}
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign) int vcIndex;
@property (nonatomic, strong) NSArray *sourceList;

@property (nonatomic, weak)id<RDIncripTionLibItemViewControllerDelegate> IncripTionLibItemDelegate;

@property (nonatomic, copy) NSString * id;
@property (nonatomic, assign) BOOL  isSound;                //是否 音效
@property (nonatomic,copy)NSString *soundMusicResourceURL;

@property (nonatomic, assign)BOOL    isPlaying;
@property (nonatomic, assign)BOOL    isDisappear;

@property (nonatomic, assign)BOOL    isLocal;
@end
