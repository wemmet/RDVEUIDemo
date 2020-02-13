
#include "LZWEncoder.h"

int BITS = 12;
int HSIZE = 5003; // 80% occupancy
#define EOF	-1

int masks[]  =
{
		0x0000,
		0x0001,
		0x0003,
		0x0007,
		0x000F,
		0x001F,
		0x003F,
		0x007F,
		0x00FF,
		0x01FF,
		0x03FF,
		0x07FF,
		0x0FFF,
		0x1FFF,
		0x3FFF,
		0x7FFF,
		0xFFFF };


typedef struct LZWEncoder_Context 
{
	int imgW;
	int imgH;
	uint8_t *pixAry ;
	int initCodeSize;
	int remaining;
	int curPixel;
	
	// GIFCOMPR.C       - GIF Image compression routines
	//
	// Lempel-Ziv compression based on 'compress'.  GIF modifications by
	// David Rowley (mgardi@watdcsu.waterloo.edu)
	
	// General DEFINEs	
	// GIF Image compression - modified 'compress'
	//
	// Based on: compress.c - File compression ala IEEE Computer, June 1984.
	//
	// By Authors:  Spencer W. Thomas      (decvax!harpo!utah-cs!utah-gr!thomas)
	//              Jim McKie              (decvax!mcvax!jim)
	//              Steve Davies           (decvax!vax135!petsd!peora!srd)
	//              Ken Turkowski          (decvax!decwrl!turtlevax!ken)
	//              James A. Woods         (decvax!ihnp4!ames!jaw)
	//              Joe Orost              (decvax!vax135!petsd!joe)
	
	int n_bits; // number of bits/code
	int maxbits; // user settable max # bits/code
	int maxcode; // maximum code, given n_bits
	int maxmaxcode; // should NEVER generate this code
	
	int *htab;
	int *codetab;
	
	int hsize; // for dynamic table sizing	
	int free_ent; // first unused entry
	
	// block compression parameters -- after all codes are used up,
	// and compression rate changes, start over.
	int clear_flg;
	
	// Algorithm:  use open addressing double hashing (no chaining) on the
	// prefix code / next character combination.  We do a variant of Knuth's
	// algorithm D (vol. 3, sec. 6.4) along with G. Knott's relatively-prime
	// secondary probe.  Here, the modular division first probe is gives way
	// to a faster exclusive-or manipulation.  Also do block compression with
	// an adaptive reset, whereby the code table is cleared when the compression
	// ratio decreases, but after the table fills.  The variable-length output
	// codes are re-sized at this point, and a special CLEAR code is generated
	// for the decompressor.  Late addition:  construct the table according to
	// file size for noticeable speed improvement on small files.  Please direct
	// questions about this implementation to ames!jaw.
	
	int g_init_bits;
	
	int ClearCode;
	int EOFCode;
	
	// output
	//
	// Output the given code.
	// Inputs:
	//      code:   A n_bits-bit integer.  If == -1, then EOF.  This assumes
	//              that n_bits =< wordsize - 1.
	// Outputs:
	//      Outputs code to the file.
	// Assumptions:
	//      Chars are 8 bits long.
	// Algorithm:
	//      Maintain a BITS character long buffer (so that 8 codes will
	// fit in it exactly).  Use the VAX insv instruction to insert each
	// code in turn.  When the buffer fills up empty it and start over.
	
	int cur_accum;
	int cur_bits;	
	int a_count; // Number of characters so far in this 'packet'		
	uint8_t *accum; // Define the storage for the packet accumulator		
}LZWEncoder_Context;

int MaxCode(int n_bits) 
{
	return (1 << n_bits) - 1;
}

#define max(a,b)    (((a) > (b)) ? (a) : (b))

RDGIFHANDLE LZWEncoderLoad(int width, int height, uint8_t *pixels, int color_depth)
{
	LZWEncoder_Context *pLZWEncoder = (LZWEncoder_Context*)malloc(sizeof(LZWEncoder_Context));
	if (!pLZWEncoder)
		return NULL;
	pLZWEncoder->maxbits = BITS;
	pLZWEncoder->maxmaxcode = 1 << BITS;
	pLZWEncoder->htab = malloc(HSIZE*sizeof(int)); //new int[HSIZE];
	memset(pLZWEncoder->htab,0,HSIZE*sizeof(int));
	pLZWEncoder->codetab = malloc(HSIZE*sizeof(int));//new int[HSIZE];
	memset(pLZWEncoder->codetab,0,HSIZE*sizeof(int));
	pLZWEncoder->hsize = HSIZE;
	pLZWEncoder->free_ent = 0;
	pLZWEncoder->clear_flg = 0;
	pLZWEncoder->cur_accum = 0;
	pLZWEncoder->cur_bits = 0;	
	pLZWEncoder->accum = malloc(256); 
	memset(pLZWEncoder->accum,0,256);
	pLZWEncoder->imgW = width;
	pLZWEncoder->imgH = height;
	pLZWEncoder->pixAry = pixels;
	pLZWEncoder->initCodeSize = max(2, color_depth);
	return pLZWEncoder;
}

void LZWEncoderUnLoad(RDGIFHANDLE handle)
{
	LZWEncoder_Context *pLZWEncoder = (LZWEncoder_Context*)handle;
	if (!pLZWEncoder)
		return;
	if (pLZWEncoder->accum) 
		free(pLZWEncoder->accum);
	if (pLZWEncoder->codetab) 
		free(pLZWEncoder->codetab);
	if (pLZWEncoder->htab) 
		free(pLZWEncoder->htab);
	free(pLZWEncoder);
}

void Flush(LZWEncoder_Context *pLZWEncoder,int hFile)
{	
	if (pLZWEncoder->a_count > 0) 
	{		
		write(hFile,&pLZWEncoder->a_count,1);		
		write(hFile,pLZWEncoder->accum,pLZWEncoder->a_count);		
		pLZWEncoder->a_count = 0;
	}
}

void Add(LZWEncoder_Context *pLZWEncoder,uint8_t c, int hFile)
{
	pLZWEncoder->accum[pLZWEncoder->a_count++] = c;
	if (pLZWEncoder->a_count >= 254)
		Flush(pLZWEncoder,hFile);
}

void ResetCodeTable(LZWEncoder_Context *pLZWEncoder,int hsize) 
{
	int i;
	for (i = 0; i < hsize; ++i)
		pLZWEncoder->htab[i] = -1;
}

void Output(LZWEncoder_Context *pLZWEncoder,int code, int hFile)
{
	pLZWEncoder->cur_accum &= masks[pLZWEncoder->cur_bits];
	
	if (pLZWEncoder->cur_bits > 0)
		pLZWEncoder->cur_accum |= (code << pLZWEncoder->cur_bits);
	else
		pLZWEncoder->cur_accum = code;
	
	pLZWEncoder->cur_bits += pLZWEncoder->n_bits;
	
	while (pLZWEncoder->cur_bits >= 8) 
	{
		Add(pLZWEncoder, (uint8_t) (pLZWEncoder->cur_accum & 0xff), hFile);
		pLZWEncoder->cur_accum >>= 8;
		pLZWEncoder->cur_bits -= 8;
	}
	
	// If the next entry is going to be too big for the code size,
	// then increase it, if possible.
	if ((pLZWEncoder->free_ent > pLZWEncoder->maxcode)|| pLZWEncoder->clear_flg) 
	{
		if (pLZWEncoder->clear_flg) 
		{
			pLZWEncoder->maxcode = MaxCode(pLZWEncoder->n_bits = pLZWEncoder->g_init_bits);
			pLZWEncoder->clear_flg = 0;
		} 
		else 
		{
			++pLZWEncoder->n_bits;
			if (pLZWEncoder->n_bits == pLZWEncoder->maxbits)
				pLZWEncoder->maxcode = pLZWEncoder->maxmaxcode;
			else
				pLZWEncoder->maxcode = MaxCode(pLZWEncoder->n_bits);
		}
	}
	
	if (code == pLZWEncoder->EOFCode) 
	{
		// At EOF, write the rest of the buffer.
		while (pLZWEncoder->cur_bits > 0) 
		{
			Add(pLZWEncoder, (uint8_t) (pLZWEncoder->cur_accum & 0xff), hFile);
			pLZWEncoder->cur_accum >>= 8;
			pLZWEncoder->cur_bits -= 8;
		}		
		Flush(pLZWEncoder, hFile);
	}
}

void ClearTable(LZWEncoder_Context *pLZWEncoder,int hFile)
{
	ResetCodeTable(pLZWEncoder,pLZWEncoder->hsize);

	pLZWEncoder->free_ent = pLZWEncoder->ClearCode + 2;
	pLZWEncoder->clear_flg = 1;
	
	Output(pLZWEncoder,pLZWEncoder->ClearCode, hFile);
}

int NextPixel(LZWEncoder_Context *pLZWEncoder) 
{
	int temp;
	if (pLZWEncoder->remaining == 0)
		return EOF;	
	--pLZWEncoder->remaining;	
	temp = pLZWEncoder->curPixel + 1;
	if ( temp < pLZWEncoder->imgW * pLZWEncoder->imgH-1)
	{
		uint8_t pix = pLZWEncoder->pixAry[pLZWEncoder->curPixel++];		
		return pix & 0xff;
	}
	return 0xff;
}

void Compress(LZWEncoder_Context *pLZWEncoder,int init_bits, int hFile)
{
	int fcode;
	int i /* = 0 */;
	int c;
	int ent;
	int disp;
	int hsize_reg;
	int hshift;
	
	

	// Set up the globals:  g_init_bits - initial number of bits
	pLZWEncoder->g_init_bits = init_bits;
	
	// Set up the necessary values
	pLZWEncoder->clear_flg = 0;
	pLZWEncoder->n_bits = pLZWEncoder->g_init_bits;
	pLZWEncoder->maxcode = MaxCode(pLZWEncoder->n_bits);
	
	pLZWEncoder->ClearCode = 1 << (init_bits - 1);
	pLZWEncoder->EOFCode = pLZWEncoder->ClearCode + 1;
	pLZWEncoder->free_ent = pLZWEncoder->ClearCode + 2;
	
	pLZWEncoder->a_count = 0; // clear packet	
	ent = NextPixel(pLZWEncoder);	
	hshift = 0;
	for (fcode = pLZWEncoder->hsize; fcode < 65536; fcode *= 2)
		++hshift;
	hshift = 8 - hshift; // set hash code range bound
	
	hsize_reg = pLZWEncoder->hsize;
	ResetCodeTable(pLZWEncoder,hsize_reg); // clear hash table	
	Output(pLZWEncoder,pLZWEncoder->ClearCode, hFile);
	
outer_loop : 
	while ((c = NextPixel(pLZWEncoder)) != EOF) 
	{
		fcode = (c << pLZWEncoder->maxbits) + ent;
		i = (c << hshift) ^ ent; // xor hashing
		
		if (pLZWEncoder->remaining == 350350)
		{
			int debug;
			debug = 1;
		}

		if (pLZWEncoder->htab[i] == fcode) 
		{
			ent = pLZWEncoder->codetab[i];
			continue;
		} 
		else if (pLZWEncoder->htab[i] >= 0) // non-empty slot
		{
			disp = hsize_reg - i; // secondary hash (after G. Knott)
			if (i == 0)
				disp = 1;
			do 
			{
				if ((i -= disp) < 0)
					i += hsize_reg;
				
				if (pLZWEncoder->htab[i] == fcode) 
				{
					ent = pLZWEncoder->codetab[i];
					goto outer_loop;
				}
			} while (pLZWEncoder->htab[i] >= 0);
		}
		Output(pLZWEncoder,ent, hFile);
		ent = c;
		if (pLZWEncoder->free_ent < pLZWEncoder->maxmaxcode) 
		{
			pLZWEncoder->codetab[i] = pLZWEncoder->free_ent++; // code -> hashtable
			pLZWEncoder->htab[i] = fcode;
		} 
		else
			ClearTable(pLZWEncoder,hFile);
	}
			 
	// Put out the final code.			
	Output(pLZWEncoder,ent, hFile);			 
	Output(pLZWEncoder,pLZWEncoder->EOFCode, hFile);
}

void LZWEncoderEncode(RDGIFHANDLE handle, int hFile)
{
	uint8_t byteVal;
	LZWEncoder_Context *pLZWEncoder = (LZWEncoder_Context*)handle;
	int len;
	write(hFile,&pLZWEncoder->initCodeSize,1);

	pLZWEncoder->remaining = pLZWEncoder->imgW * pLZWEncoder->imgH; // reset navigation variables
	pLZWEncoder->curPixel = 0;	
	Compress(pLZWEncoder,pLZWEncoder->initCodeSize + 1, hFile); // compress and write the pixel data	
	byteVal = 0;
	write(hFile,&byteVal,1);
}

