#ifndef _TTEXTCIPHER_H_
#define _TTEXTCIPHER_H_

#include <stdint.h>
#include <string>

	/*
	加密指定数据
		saltInfo     : [in] 密钥
		saltInfoLen  : [in] 密钥数据字节长度
		plaintext  : [in] 明文
		return  : 返回加密后数据，如果长度为0，则代表加密失败
	*/
	std::string RDCipherEncrypt(uint8_t* saltInfo, uint32_t saltInfoLen,const char* plaintext);

	/*
	解密指定数据
		saltInfo     : [in] 密钥
		saltInfoLen  : [in] 密钥数据字节长度
		ciphertext  : [in] 密文
		return  : 返回解密后数据 ，如果长度为0，则代表解密失败
	*/
	std::string RDCipherDecrypt(uint8_t* saltInfo, uint32_t saltInfoLen,const char* ciphertext);

#endif // _TTEXTCIPHER_H_
