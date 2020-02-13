
#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef void* RDGIFHANDLE;

RDGIFHANDLE LZWEncoderLoad(int width, int height, uint8_t *pixels, int color_depth);
void LZWEncoderEncode(RDGIFHANDLE handle, int hFile);
void LZWEncoderUnLoad(RDGIFHANDLE handle);

#ifdef __cplusplus
}
#endif
