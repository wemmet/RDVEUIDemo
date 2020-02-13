//
//  NSString+Encrypt.m
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 15/1/26.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import "NSString+RDTSAVI_Encrypt.h"
#import "NSData+RDTSAVIEncrypt.h"
#import "NSData+RDTSAVIBase64.h"

@implementation NSString (RDTSAVI_Encrypt)

-(NSString*)encryptedTSAVIWithAESUsingKey:(NSString*)key andIV:(NSData*)iv {
    NSData *encrypted = [[self dataUsingEncoding:NSUTF8StringEncoding] rdTSAVI_encryptedWithAESUsingKey:key andIV:iv];
    NSString *encryptedString = [encrypted rdTSAVIBase64EncodedString];
    
    return encryptedString;
}

- (NSString*)rdTSAVIDecryptedWithAESUsingKey:(NSString*)key andIV:(NSData*)iv{
    NSData *decrypted = [[NSData rdDataWithTSAVIBase64EncodedString:self] rdTSAVI_decryptedWithAESUsingKey:key andIV:iv];
    NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    return decryptedString;
    
}
- (NSString*)encryptedWith3DESUsingKey:(NSString*)key andIV:(NSData*)iv {
    NSData *encrypted = [[self dataUsingEncoding:NSUTF8StringEncoding] rdTSAVI_encryptedWith3DESUsingKey:key andIV:iv];
    NSString *encryptedString = [encrypted rdTSAVIBase64EncodedString];
    
    return encryptedString;
}

- (NSString*)decryptedWith3DESUsingKey:(NSString*)key andIV:(NSData*)iv {
    NSData *decrypted = [[NSData rdDataWithTSAVIBase64EncodedString:self] rdTSAVI_decryptedWith3DESUsingKey:key andIV:iv];
    NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    return decryptedString;
}

@end
