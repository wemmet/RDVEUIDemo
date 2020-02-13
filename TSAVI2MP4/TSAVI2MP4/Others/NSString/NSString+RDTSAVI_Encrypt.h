//
//  NSString+RDTSAVI_Encrypt.h
//  RDVECoreHelper
//
//  Created by emmet on 2017/9/22.
//  Copyright © 2017年 Solaren. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface NSString (RDTSAVI_Encrypt)
- (NSString*)rdTSAVIDecryptedWithAESUsingKey:(NSString*)key andIV:(NSData*)iv;

@end
