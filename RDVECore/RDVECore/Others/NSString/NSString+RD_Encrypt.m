//
//  NSString+Encrypt.m
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 15/1/26.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import "NSString+RD_Encrypt.h"
#import "NSData+RDEncrypt.h"
#import "NSData+RDBase64.h"

@implementation NSString (RD_Encrypt)

-(NSString*)encryptedWithAESUsingKey:(NSString*)key andIV:(NSData*)iv {
    NSData *encrypted = [[self dataUsingEncoding:NSUTF8StringEncoding] rd_encryptedWithAESUsingKey:key andIV:iv];
    NSString *encryptedString = [encrypted rdBase64EncodedString];
    
    return encryptedString;
}

- (NSString*)rd_DecryptedWithAESUsingKey:(NSString*)key andIV:(NSData*)iv {
    
    NSData *decrypted = [[NSData rdDataWithBase64EncodedString:self] rd_decryptedWithAESUsingKey:key andIV:iv];
    NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    return decryptedString;
}

- (NSString*)encryptedWith3DESUsingKey:(NSString*)key andIV:(NSData*)iv {
    NSData *encrypted = [[self dataUsingEncoding:NSUTF8StringEncoding] rd_encryptedWith3DESUsingKey:key andIV:iv];
    NSString *encryptedString = [encrypted rdBase64EncodedString];
    
    return encryptedString;
}

- (NSString*)decryptedWith3DESUsingKey:(NSString*)key andIV:(NSData*)iv {
    NSData *decrypted = [[NSData rdDataWithBase64EncodedString:self] rd_decryptedWith3DESUsingKey:key andIV:iv];
    NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    return decryptedString;
}

@end
