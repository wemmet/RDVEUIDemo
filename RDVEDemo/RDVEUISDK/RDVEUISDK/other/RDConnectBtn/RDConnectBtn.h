//
//  RDConnectBtn.h
//  RDVEUISDK
//
//  Created by emmet on 2017/6/28.
//  Copyright © 2017年 com.rd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDConnectBtn : UIButton
@property(nonatomic,copy)NSString  *transitionTypeName;
@property(nonatomic,copy  )NSString  *transitionTitle;
@property(nonatomic,copy  )NSURL     *maskURL;
@property(nonatomic,assign)NSInteger  fileIndex;
@end
