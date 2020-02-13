
#include <string.h>
#include "TTextCipher.h"
#include "aes.h"
#include "sha2.h"
#include "md5.h"
#include <algorithm>

static void bufferToString(const uint8_t* data, uint32_t len, std::string &result);
static uint8_t* stringToBuffer(std::string& str, uint32_t &len);

static const unsigned char pre_key[64] =
{
	0xE4, 0xA8, 0x6E, 0x56, 0x87, 0x62, 0x5A, 0xBD,
	0xBF, 0x17, 0xD9, 0xA2, 0xC4, 0x17, 0x1A, 0x01,
	0x94, 0xED, 0x8F, 0x1E, 0x11, 0xB3, 0xD7, 0x09,
	0x0C, 0xB6, 0xE9, 0x00, 0x6F, 0x22, 0xEE, 0x13,
	0xCA, 0xB3, 0x07, 0x05, 0x76, 0xC9, 0xFA, 0x31,
	0x6C, 0x08, 0x34, 0xFF, 0x8D, 0xC2, 0x6C, 0xC8,
	0x00, 0x43, 0xE9, 0xf4, 0x97, 0xAF, 0x50, 0x4B,
	0xD1, 0x41, 0xBA, 0x95, 0x31, 0x5A, 0x0B, 0x97
};

std::string RDCipherEncrypt(uint8_t* saltInfo, uint32_t saltInfoLen, const char* plaintext)
{
	std::string resultString;
	if (NULL == plaintext || NULL == saltInfo || 0 == saltInfoLen)
	{
		return resultString;
	}
	uint8_t key[33] = { 0 };
	aes_context aes; //AES 加解密上下文
	uint8_t iv[17] = { 0 };
	uint32_t len = strlen(plaintext);

	sha2_hmac(saltInfo, saltInfoLen, pre_key, sizeof(pre_key), (uint8_t *)key, 0);
	MD5 md5Key((char*)key);
	memcpy(iv, md5Key.toStr().substr(12, 16).c_str(), 16);

	uint32_t resultLen = (len + 0xF) & ~0xF; //需要16倍数，用0填充
	uint8_t *result = (uint8_t *)malloc(resultLen);
	memset(result, 0, resultLen);
	memcpy(result, plaintext, len);

	aes_setkey_enc(&aes, (uint8_t *)key, 256); //密钥(key)和向量(iv)的长度是256位，即32字节。
	if (0 == aes_crypt_cbc(&aes, AES_ENCRYPT, resultLen, iv, result, result)) 	//加密数据
	{
		bufferToString(result, resultLen, resultString);
	}
	free(result);
	return resultString;
}

std::string RDCipherDecrypt(uint8_t* saltInfo, uint32_t saltInfoLen, const char* ciphertext)
{
	std::string resultString;
	if (NULL == ciphertext || strlen(ciphertext) == 0 || NULL == saltInfo || 0 == saltInfoLen)
	{
		return resultString;
	}
	uint8_t key[33] = { 0 };
	aes_context aes; //AES 加解密上下文
	uint8_t iv[17] = { 0 };
	uint32_t len = 0;

	std::string strCipherText(ciphertext);
	uint8_t * result = stringToBuffer(strCipherText, len);

	if (result)
	{
		sha2_hmac(saltInfo, saltInfoLen, pre_key, sizeof(pre_key), (uint8_t *)key, 0);
		MD5 md5Key((char*)key);
		memcpy(iv, md5Key.toStr().substr(12, 16).c_str(), 16);


		aes_setkey_dec(&aes, (uint8_t *)key, 256); //密钥(key)和向量(iv)的长度是256位，即32字节。											   
		if (0 == aes_crypt_cbc(&aes, AES_DECRYPT, len, iv, result, result)) //解密数据
		{
			resultString.assign((char*)result);
		}
		free(result);
		if (resultString.length() > len) //FIXME: 解密后数据长度大于密文长度，判断为解密失败
		{
			resultString.assign("");
		}
	}
	return resultString;
}


void bufferToString(const uint8_t* data, uint32_t len, std::string &result)
{
	static const char HEX_NUMBERS[] = "0123456789abcdef";
	result.reserve(len << 1);
	for (size_t i = 0; i < len; ++i) {
		int t = data[i];
		int a = t / 16;
		int b = t % 16;
		result.append(1, HEX_NUMBERS[a]);
		result.append(1, HEX_NUMBERS[b]);
	}
}

uint8_t* stringToBuffer(std::string& str,uint32_t &len)
{	
	//忽略部分无效字符
	str.erase(std::remove(str.begin(), str.end(), '\r'), str.end());
	str.erase(std::remove(str.begin(), str.end(), '\n'), str.end());
	str.erase(std::remove(str.begin(), str.end(), '\t'), str.end());
	str.erase(std::remove(str.begin(), str.end(), ' '), str.end());
	//忽略结束

	len = ((str.length() / 2) + 0xF) & ~0xF; //需要16倍数，用0填充
	uint8_t* resultBuffer = (uint8_t*)malloc(len);
	memset(resultBuffer, 0, len);
	for (size_t i = 0; i < str.length(); i += 2)
	{
		std::string byte = str.substr(i, 2);
		uint8_t chr = (uint8_t)strtol(byte.c_str(), NULL, 16);
		resultBuffer[i / 2] = chr;
	}
	return resultBuffer;
}

