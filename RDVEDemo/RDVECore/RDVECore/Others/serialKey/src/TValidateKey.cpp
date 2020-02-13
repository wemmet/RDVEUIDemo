#include <stdio.h>
#include <time.h>
#include "TMiscUtils.h"
#include "TValidateKey.h"

TValidateKey::TValidateKey(const std::string& sSecretPhase, unsigned char feature)
	: TBaseConfiguration(sSecretPhase, feature), m_tCreateTime(0)
{
	mnDays = 0;
	m_nUserId = 0;
	m_bValid = false;
	mbDebuggerPresent = false;

#if defined(ANTI_CRACK) && defined(WIN32)
	if (IsDebuggerPresent_self())
	{
		mbDebuggerPresent = true;
	}
#endif
}

bool TValidateKey::DecodeKey(const std::string& sKey, const std::string& sUserInfo)
{
	if (sKey.empty())
	{
		return false;
	}
	if (!sUserInfo.empty())
	{
		m_nUserId = GetEightByteHash(sUserInfo, 100000);
	}
	else
	{
		m_nUserId = 0;
	}
	std::string sText = sKey;

	int nPos = 0;
	while ((nPos = (int)sText.find('-', nPos)) != -1)
	{
		sText.erase(nPos, 1);
	}

	return Decrypt(sText);
}

bool TValidateKey::Decrypt(const std::string& sEncryptedText)
{
	std::string sText = Base26ToBase10(sEncryptedText);

#if defined(ANTI_CRACK) && defined(WIN32) && !defined(_WIN64)
	// Junk code
	__asm
	{
		mov eax, edx;
		inc eax;
		shl eax, 2;
		mov ecx, 0x32;
		add eax, ecx;
		shr ecx, 2;
	}
#endif

	if (!msSecretPhase.empty())
	{
		sText = sText.substr(0, 9) + DecText(sText.substr(9), msSecretPhase);
	}
	if (sText.size() < 33)
	{
		return false;
	}

	std::string sDecodeText = sText.substr(0, 9);
	std::string sInfo = sText.substr(9);

	unsigned char feature = 0;
	unsigned int  nFeature = 0;
	unsigned int  nUserId = 0;
	unsigned int  nDecodeInfo = 0;

	tm tm_;
	int year, month, day;
	memset(&tm_, 0, sizeof(tm));
	sscanf(sInfo.substr(0, 4).c_str(), "%d", &year);
	sscanf(sInfo.substr(4, 2).c_str(), "%d", &month);
	sscanf(sInfo.substr(6, 2).c_str(), "%d", &day);
	tm_.tm_year = year - 1900;
	tm_.tm_mon = month - 1;
	tm_.tm_mday = day;
	tm_.tm_isdst = 0;
	m_tCreateTime = mktime(&tm_);

	sscanf(sInfo.substr(8, 4).c_str(), "%u", &mnDays);
	sscanf(sInfo.substr(12, 5).c_str(), "%u", &nFeature);
	sscanf(sInfo.substr(17, 7).c_str(), "%u", &nUserId);
	sscanf(sDecodeText.c_str(), "%u", &nDecodeInfo);
	uint32_t nUserIdFlag = nUserId / 100000;
	nUserId %= 100000;

	feature = (unsigned char)nFeature;
	if (mFeature == feature && GetEightByteHash(sInfo) == nDecodeInfo
		&& (((nUserIdFlag & 0x8) == 0x8 && m_nUserId ==0) || nUserId == m_nUserId))
	{
		m_bValid = true;
	}
	return true;
}

unsigned int TValidateKey::Days()
{
	return mnDays;
}

bool TValidateKey::IsValid()
{
#if defined(ANTI_CRACK) && defined(WIN32) && defined(NDEBUG)
	if (mbDebuggerPresent)
	{
		// exit(-1);
		// 如果检测到Release版本处于调试状态，则直接返回序列号验证成功，让破解者误以为破解成功。
		// 比直接退出可能更好。
		return true;
	}
#endif // defined(ANTI_CRACK)

	return m_bValid;
}
