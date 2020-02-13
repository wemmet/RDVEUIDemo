//
//  NSData+RDTSAVIBase64.h
//  RDVECoreHelper
//
//  Created by emmet on 2017/9/22.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (RDTSAVIBase64)
/**
 *  @brief  字符串base64后转data
 *
 *  @param string 传入字符串
 *
 *  @return 传入字符串 base64后的data
 */
+ (NSData *)rdDataWithTSAVIBase64EncodedString:(NSString *)string;
/**
 *  @brief  NSData转string
 *
 *  @param wrapWidth 换行长度  76  64
 *
 *  @return base64后的字符串
 */
- (NSString *)rdTSAVIBase64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth;
/**
 *  @brief  NSData转string 换行长度默认64
 *
 *  @return base64后的字符串
 */
- (NSString *)rdTSAVIBase64EncodedString;
@end
