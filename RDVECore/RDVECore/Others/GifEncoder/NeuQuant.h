// NeuQuant.h: interface for the CNeuQuant class.
//
//////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

typedef void* RDGIFHANDLE;

RDGIFHANDLE NeQuantCreator(uint8_t *thepic, int len, int sample);
uint8_t*  NeQuantProcess(RDGIFHANDLE handle);
int	   NeQuantMap(RDGIFHANDLE handle,int b, int g, int r);
int	   NeQuantClose(RDGIFHANDLE handle);

#ifdef __cplusplus
}
#endif



