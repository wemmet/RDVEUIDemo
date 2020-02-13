//
//  NSString+Encrypt.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 15/1/26.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RDTSAVI_Encrypt)

- (NSString*)rdTSAVIDecryptedWithAESUsingKey:(NSString*)key andIV:(NSData*)iv;



@end
