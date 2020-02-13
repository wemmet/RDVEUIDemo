#include <string.h>
#ifdef WIN32
#include <time.h>
#include <windows.h>
static int gettimeofday(struct timeval *tp, void *tzp)
{
	time_t clock;
	struct tm tm;
	SYSTEMTIME wtm;
	GetLocalTime(&wtm);
	tm.tm_year = wtm.wYear - 1900;
	tm.tm_mon = wtm.wMonth - 1;
	tm.tm_mday = wtm.wDay;
	tm.tm_hour = wtm.wHour;
	tm.tm_min = wtm.wMinute;
	tm.tm_sec = wtm.wSecond;
	tm.tm_isdst = -1;
	clock = mktime(&tm);
	tp->tv_sec = clock;
	tp->tv_usec = wtm.wMilliseconds * 1000;
	return (0);
}
#else
#  include <sys/time.h>
#endif
#include "TSerialKey.h"
#include "TGenerateKey.h"
#include "TValidateKey.h"

int RDGenerateKey(char *key, int keyLen, const char *secret, unsigned char feature,
                int days, const char *userInfo)
{
    if (key == NULL || secret == NULL || days < 0 || days > 999)
    {
        return -1;
    }
    TGenerateKey generate(secret, feature);
    std::string sUserInfo;
    if (userInfo != NULL)
    {
        sUserInfo = userInfo;
    }
    std::string sKey;
    if (!generate.EncodeKey(sKey, days, sUserInfo)
        || (unsigned int) keyLen < sKey.length())
    {
        return -1;
    }
    strncpy(key, sKey.c_str(), keyLen);
    return 0;
}

int RDValidateKey(const char *key, const char *secret, unsigned char feature,
                int *days, const char *userInfo)
{
    if (key == NULL || secret == NULL)
    {
        return -1;
    }
    TValidateKey validate(secret, feature);
    std::string sUserInfo;
    if (userInfo != NULL)
    {
        sUserInfo = userInfo;
    }
    if (!validate.DecodeKey(key, sUserInfo))
    {
        return -1;
    }

    if (validate.Days() > 0)
    {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        if (tv.tv_sec > (validate.getCreateTime() + validate.Days() * 24 * 60 * 60))
        {//已过期
            return -2;
        }
    }
    if (days != NULL)
    {
        *days = validate.Days();
    }
    return validate.IsValid() ? 0 : -1;
}

