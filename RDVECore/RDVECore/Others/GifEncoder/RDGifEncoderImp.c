#include "NeuQuant.h"
#include "RDGifEncoderImp.h"
#include <fcntl.h>
#include <string.h>

typedef uint32_t COLORREF;

typedef struct GIF_Encoder_Ctx
{
    int width; // image size
    int height;
    
    COLORREF transparent; // transparent color if given
    int transIndex; // transparent index in color table
    int repeat; // no repeat
    int delay; // frame delay (hundredths)
    int fps;
    
    //    protected BinaryWriter bw;
    int fs;
    uint8_t *pixels; // BGR byte array from frame
    uint8_t *indexedPixels; // converted frame indexed to palette
    int colorDepth; // number of bit planes
    uint8_t *colorTab; // RGB palette
    int *usedEntry; // active palette entries
    int palSize; // color table size (bits-1)
    int dispose; // disposal code (-1 = use default)
    int firstFrame ;
    int sample; // default sample interval for quantizer
    int    acccurate;
    int progress;
    int stop;
}GIF_Encoder_Ctx;

void AnalyzePixels(RDGIFHANDLE handle);
void WriteLSD(RDGIFHANDLE handle);
void WritePalette(RDGIFHANDLE handle);
void WriteNetscapeExt(RDGIFHANDLE handle);
void WriteGraphicCtrlExt(RDGIFHANDLE handle);
void WriteImageDesc(RDGIFHANDLE handle);
void WritePixels(RDGIFHANDLE handle);

RDGIFHANDLE RDGIFEncoderCreator()
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)malloc(sizeof(GIF_Encoder_Ctx));
    memset(pEncoderCtx,0,sizeof(GIF_Encoder_Ctx));
    
    pEncoderCtx->repeat = -1;
    pEncoderCtx->usedEntry = (int*)malloc(256*sizeof(int));
    memset(pEncoderCtx->usedEntry,0,256*sizeof(int));
    pEncoderCtx->palSize = 7;
    pEncoderCtx->dispose = -1;
    pEncoderCtx->firstFrame = 1;
    pEncoderCtx->sample = 10;
    pEncoderCtx->delay = 50;
    pEncoderCtx->transIndex = 0;
    return pEncoderCtx;
}

void SetDelay(RDGIFHANDLE handle, int ms)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    pEncoderCtx->delay = ( int ) (ms / 10.0f);
}

int RDGIFEncoderSetFps(RDGIFHANDLE handle, int fps)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (fps<=0) return 0;
    pEncoderCtx->fps = fps;
    SetDelay(handle,1000/fps);
    return 1;
}

void SetDispose(RDGIFHANDLE handle,int code)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (code >= 0)
    {
        pEncoderCtx->dispose = code;
    }
}

void SetRepeat(RDGIFHANDLE handle,int iter)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (iter >= 0)
        pEncoderCtx->repeat = iter;
}

void SetTransparent(RDGIFHANDLE handle, COLORREF c)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    pEncoderCtx->transparent = c;
}

int RDGIFEncoderAddFrame(RDGIFHANDLE handle, uint8_t* pBuff, int width, int height, int bpp)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    int firstFrame = pEncoderCtx->firstFrame;
    int repeat = pEncoderCtx->repeat;
    long len;
    
    if (width != pEncoderCtx->width || height != pEncoderCtx->height)
        return -1;
    if (32 == bpp)
    {
        int8_t *buffRGB24Tmp=NULL,*buffRGB32Tmp=NULL;
        int m=0;
        buffRGB24Tmp=pEncoderCtx->pixels;
        buffRGB32Tmp=pBuff;
        for (m=0; m<pEncoderCtx->width*pEncoderCtx->height; m++)
        {
            *buffRGB24Tmp = *(buffRGB32Tmp+2);
            *(buffRGB24Tmp+1) = *(buffRGB32Tmp+1);
            *(buffRGB24Tmp+2) = *buffRGB32Tmp;
            
            buffRGB24Tmp += 3;
            buffRGB32Tmp += 4;
        }
        
    }
    else if (24 == bpp)
    {
        memcpy(pEncoderCtx->pixels,pBuff,width*height*3);
    }
    else
        return -1;
    
    AnalyzePixels(handle); // build color table & map pixels
    if (firstFrame)
    {
        WriteLSD(handle); // logical screen descriptior
        WritePalette(handle); // global color table
        if (repeat >= 0)
        {
            // use NS app extension to indicate reps
            WriteNetscapeExt(handle);
        }
    }
    WriteGraphicCtrlExt(handle); // write graphic control extension
    WriteImageDesc(handle); // image descriptor
    if (!firstFrame)
    {
        WritePalette(handle); // local color table
    }
    WritePixels(handle); // encode and write pixel data
    pEncoderCtx->firstFrame = 0;
    return 1;
}

int RDGIFEncoderFinish(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    uint8_t byteVal = 0x3b;
    write(pEncoderCtx->fs,&byteVal,1);
    close(pEncoderCtx->fs);
    if (pEncoderCtx->usedEntry) free(pEncoderCtx->usedEntry);
    if (pEncoderCtx->indexedPixels) free(pEncoderCtx->indexedPixels);
    free(pEncoderCtx);
    return 1;
}

int RDGIFEncoderSetSize(RDGIFHANDLE handle, int w, int h)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (NULL==pEncoderCtx) return 0;
    if (w<=0 || h<=0) return 0;
    pEncoderCtx->width = w;
    pEncoderCtx->height = h;
    return 1;
}

int RDGIFEncoderSetRepeat(RDGIFHANDLE handle,int repeat)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (NULL==pEncoderCtx) return 0;
    if (repeat)
        pEncoderCtx->repeat = 1;
    else
        pEncoderCtx->repeat = -1;
    return 1;
}

int RDGIFEncoderSetDelay(RDGIFHANDLE handle, int64_t delay)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (NULL==pEncoderCtx) return 0;
    pEncoderCtx->delay = (delay/1000)/10.0;
    return 1;
}

#define O_BINARY    0x8000

int RDGIFEncoderStart(RDGIFHANDLE handle, char *path)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    char *szHeader = "GIF89a";
    unsigned int i = 0;
    int64_t duration= 0;
    int ret;
    
    int is_start = 1;
    int64_t syn_ipts = 0;
    int64_t syn_opts = 0;
    int64_t nb_count_need = 0;
    int access;
    int8_t *buffRGB24=NULL,*buffRGB32=NULL;
    
    access = O_CREAT | O_TRUNC | O_RDWR ;
    //#ifdef O_BINARY
    access |= O_BINARY;
    //#endif
    pEncoderCtx->fs = open(path,access,0666);
    if (pEncoderCtx->fs == -1)
        return -__LINE__;
    
    write(pEncoderCtx->fs,szHeader,strlen(szHeader));
    
    //分配内存
    pEncoderCtx->pixels = malloc(pEncoderCtx->width*pEncoderCtx->height*3);
    if (!pEncoderCtx->pixels)
        return -__LINE__;
    
    return 1;
}

int RDGIFEncoderGetProgress(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (!pEncoderCtx) return 0;
    return pEncoderCtx->progress;
}

int RDGIFEncoderStop(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    if (!pEncoderCtx) return 0;
    pEncoderCtx->stop = 1;
    return 1;
}

void AnalyzePixels(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    int len = pEncoderCtx->width*pEncoderCtx->height*3;
    int nPix = len / 3;
    RDGIFHANDLE hNeuQuant;
    uint8_t *indexedPixels;
    int *usedEntry = pEncoderCtx->usedEntry;
    uint8_t *colorTab;
    uint8_t *pixels = pEncoderCtx->pixels;
    int k = 0;
    int i;
    
    if (!pEncoderCtx->indexedPixels)
    {
        pEncoderCtx->indexedPixels = (uint8_t*)malloc(nPix);
        memset(pEncoderCtx->indexedPixels,0,nPix);
    }
    else
        memset(pEncoderCtx->indexedPixels,0,nPix);
    
    indexedPixels = pEncoderCtx->indexedPixels;
    
    hNeuQuant = NeQuantCreator(pEncoderCtx->pixels,len,pEncoderCtx->sample);
    pEncoderCtx->colorTab = NeQuantProcess(hNeuQuant);
    
    colorTab = pEncoderCtx->colorTab;
    for (i = 0; i < nPix; i++)
    {
        int index = 0;
        int r,g,b;
        if (64368 == i)
        {
            i = 64368;
        }
        b = pixels[k++];
        g = pixels[k++];
        r = pixels[k++];
        
        index =
        NeQuantMap(hNeuQuant, b & 0xff,
                   g & 0xff,
                   r & 0xff);
        usedEntry[index] = 1;
        indexedPixels[i] = (uint8_t)index;
    }
    
    NeQuantClose(hNeuQuant);
    
    pEncoderCtx->colorDepth = 8;
    pEncoderCtx->palSize = 7;
}

int FindClosest(RDGIFHANDLE handle, COLORREF c)
{
    int r = c&0xFF; //c.R;
    int g = c>>8&0xFF;
    int b = c>>16&0xFF;
    int minpos = 0;
    int dmin = 256 * 256 * 256;
    int len = 256;
    int i;
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    uint8_t *colorTab = pEncoderCtx->colorTab;
    int* usedEntry = pEncoderCtx->usedEntry;
    
    if (colorTab == NULL) return -1;
    
    for (i = 0; i < len;)
    {
        int dr = r - (colorTab[i++] & 0xff);
        int dg = g - (colorTab[i++] & 0xff);
        int db = b - (colorTab[i] & 0xff);
        int d = dr * dr + dg * dg + db * db;
        int index = i / 3;
        if (usedEntry[index] && (d < dmin))
        {
            dmin = d;
            minpos = index;
        }
        i++;
    }
    return minpos;
}

void WriteGraphicCtrlExt(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    uint8_t byteVal;
    int fs = pEncoderCtx->fs;
    int dispose = pEncoderCtx->dispose;
    int transp, disp;
    short shortVal;
    
    byteVal = 0x21;
    write(fs,&byteVal,1);
    byteVal = 0xf9;
    write(fs,&byteVal,1);
    byteVal = 4;
    write(fs,&byteVal,1);
    
    transp = 0;
    disp = 0; // dispose = no action
    
    if (dispose >= 0)
    {
        disp = dispose & 7; // user override
    }
    disp <<= 2;
    
    byteVal = 0 | // 1:3 reserved
    disp | // 4:6 disposal
    0 | // 7   user input - 0 = none
    transp;
    write(fs,&byteVal,1);
    
    shortVal = pEncoderCtx->delay;
    write(fs,&shortVal,2);
    byteVal = pEncoderCtx->transIndex;
    write(fs,&byteVal,1);
    byteVal = 0;
    write(fs,&byteVal,1);
}

void WriteImageDesc(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    uint8_t byteVal;
    int fs = pEncoderCtx->fs;
    int palSize = pEncoderCtx->palSize;
    short shortVal;
    
    byteVal = 0x2c;
    write(fs,&byteVal,1);
    
    shortVal = 0;
    write(fs,&shortVal,2);
    shortVal = 0;
    write(fs,&shortVal,2);
    shortVal = pEncoderCtx->width;
    write(fs,&shortVal,2);
    shortVal = pEncoderCtx->height;
    write(fs,&shortVal,2);
    
    // packed fields
    if (pEncoderCtx->firstFrame)
    {
        // no LCT  - GCT is used for first (or only) frame
        byteVal = 0;
        write(fs,&byteVal,1);
    }
    else
    {
        // specify normal LCT
        byteVal = 0x80 | // 1 local color table  1=yes
        0 | // 2 interlace - 0=no
        0 | // 3 sorted - 0=no
        0 | // 4-5 reserved
        palSize;
        write(fs,&byteVal,1);
    }
}

void WriteLSD(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    uint8_t byteVal;
    int fs = pEncoderCtx->fs;
    int palSize = pEncoderCtx->palSize;
    short shortVal;
    // logical screen size
    
    shortVal = pEncoderCtx->width;
    write(fs,&shortVal,2);
    shortVal = pEncoderCtx->height;
    write(fs,&shortVal,2);
    
    byteVal = 0x80 | // 1   : global color table flag = 1 (gct used)
    0x70 | // 2-4 : color resolution = 7
    0x00 | // 5   : gct sort flag = 0
    palSize;
    write(fs,&byteVal,1);
    
    
    byteVal = 0;
    write(fs,&byteVal,1);
    byteVal = 0;
    write(fs,&byteVal,1);
}

void WriteNetscapeExt(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    uint8_t byteVal;
    int fs = pEncoderCtx->fs;
    short shortVal;
    char *szVal;
    
    byteVal = 0x21;
    write(fs,&byteVal,1);
    byteVal = 0xff;
    write(fs,&byteVal,1);
    byteVal = 11;
    write(fs,&byteVal,1);
    szVal = "NETSCAPE2.0";
    write(fs,szVal,strlen(szVal));
    
    byteVal = 3;
    write(fs,&byteVal,1);
    byteVal = 1;
    write(fs,&byteVal,1);
    
    
    shortVal = pEncoderCtx->repeat;
    write(fs,&shortVal,2);
    byteVal = 0;
    write(fs,&byteVal,1);
    
}

void WritePalette(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    int len = 256;
    int fs = pEncoderCtx->fs;
    int n;
    uint8_t byteVal;
    int colorTab_len = 256*3;
    int i;
    write(fs,pEncoderCtx->colorTab,colorTab_len);
    
    n = (3 * 256) - colorTab_len;
    for (i = 0; i < n; i++)
    {
        byteVal = 0;
        write(fs,&byteVal,1);
    }
    
    if (pEncoderCtx->colorTab)
    {
        free(pEncoderCtx->colorTab);
        pEncoderCtx->colorTab = NULL;
    }
}

void WritePixels(RDGIFHANDLE handle)
{
    GIF_Encoder_Ctx *pEncoderCtx = (GIF_Encoder_Ctx*)handle;
    RDGIFHANDLE hLZWencoder =  LZWEncoderLoad(pEncoderCtx->width,pEncoderCtx->height,
                                         pEncoderCtx->indexedPixels,pEncoderCtx->colorDepth);
    LZWEncoderEncode(hLZWencoder,pEncoderCtx->fs);
    LZWEncoderUnLoad(hLZWencoder);
}
