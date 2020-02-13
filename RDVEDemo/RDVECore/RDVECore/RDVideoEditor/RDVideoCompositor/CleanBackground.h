#pragma once
#include <stdint.h>
//#include "ColorSpace.h"
class CleanBackground
{
public:
	CleanBackground();
	~CleanBackground();

	struct BkRange
	{
		int16_t	begin;
		int16_t	end;
	};
	struct BackgroundInfo
	{
		int32_t bgMode;
		BkRange	thresholdA;
		BkRange	thresholdB;
		BkRange	thresholdC;
	};

	BackgroundInfo selectSolid(const uint8_t* sour, int32_t width, int32_t height, int32_t pitch = 0);
	BackgroundInfo selectSky(const uint8_t* sour, int32_t width, int32_t height, int32_t pitch = 0);
private:
	const uint8_t* m_image;
	int32_t m_width;
	int32_t m_height;
	int32_t m_pitch;

	uint8_t* m_hsv;
	int32_t m_baseWidth;
	int32_t m_baseHeight;
	int32_t m_allocSize;

	BackgroundInfo	m_bkInfo;

	int32_t	otsuHistogram(int32_t hisCount, uint32_t* hisTab);



	BkRange beginRanged(uint16_t hisCount, uint32_t* hisTab);	//初始计算饱和度范围
	BkRange circleRanged(uint16_t hisCount, uint32_t* hisTab);	//初始计算色相的范围
	BkRange lineRanged(uint16_t hisCount, uint32_t* hisTab, bool asHue );	//以饱和度范围为基础，计算亮度范围。 以色相范围为基础，计算饱合度范围。

	//HSV(Hue, Saturation, Value)
	void blurHisTable(int32_t hisCount, uint32_t * sourTab, uint32_t * destTab, int32_t radius, bool isCricle = false );
	void maxHisTable(int32_t hisCount, uint32_t* sourTab, uint32_t* destTab, int32_t radius, bool isCricle = false);
};

