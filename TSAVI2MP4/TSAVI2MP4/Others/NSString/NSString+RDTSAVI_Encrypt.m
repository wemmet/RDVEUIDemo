//
//  NSString+RDTSAVI_Encrypt.m
//  RDVECoreHelper
//
//  Created by emmet on 2017/9/22.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#import "NSString+RDTSAVI_Encrypt.h"
#import "NSData+RDTSAVIEncrypt.h"
#import "NSData+RDTSAVIBase64.h"

@implementation NSString (RDTSAVI_Encrypt)
- (NSString*)rdTSAVIDecryptedWithAESUsingKey:(NSString*)key andIV:(NSData*)iv{
    NSData *decrypted = [[NSData rdDataWithTSAVIBase64EncodedString:self] rdTSAVI_decryptedWithAESUsingKey:key andIV:iv];
    NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    return decryptedString;
    
}
@end
