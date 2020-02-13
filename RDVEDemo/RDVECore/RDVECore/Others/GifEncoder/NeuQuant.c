// NeuQuant.cpp: implementation of the CNeuQuant class.
//
//////////////////////////////////////////////////////////////////////

#include "NeuQuant.h"
#include <stdlib.h>
#include <string.h>

int netsize = 256; /* number of colours used */
/* four primes near 500 - assume no image has a length so large */
/* that it is divisible by all four primes */
int prime1 = 499;
int prime2 = 491;
int prime3 = 487;
int prime4 = 503;
const int minpicturebytes = ( 3 * 503 ); //( 3 * prime4 );
/* minimum size for input image */
/* Program Skeleton
----------------
[select samplefac in range 1..30]
[read image from input file]
pic = (unsigned char*) malloc(3*width*height);
initnet(pic,3*width*height,samplefac);
learn();
unbiasnet();
[write output image header, using writecolourmap(f)]
inxbuild();
write output image using inxsearch(b,g,r)      */

/* Network Definitions
------------------- */
int maxnetpos = 256-1; //(netsize - 1);
int netbiasshift = 4; /* bias for colour values */
int ncycles = 100; /* no. of learning cycles */

/* defs for freq and bias */
int intbiasshift = 16; /* bias for fractions */
int intbias = (((int) 1) << 16); //(((int) 1) << intbiasshift);
int gammashift = 10; /* gamma = 1024 */
//int gamma = (((int) 1) << 10);//(((int) 1) << gammashift);
int betashift = 10;
int beta = (((int) 1) << 16)>>10; //(intbias >> betashift); /* beta = 1/1024 */
int betagamma = (((int) 1) << 16); //(intbias << (gammashift - betashift));

/* defs for decreasing radius factor */
int initrad = 256>>3; //(netsize >> 3); /* for 256 cols, radius starts */
int radiusbiasshift = 6; /* at 32.0 biased by 6 bits */
int radiusbias = (((int) 1) << 6);  //(((int) 1) << radiusbiasshift);
int initradius = ((256>>3) * (((int) 1) << 6)); //(initrad * radiusbias); /* and decreases by a */
int radiusdec = 30; /* factor of 1/30 each cycle */

/* defs for decreasing alpha factor */
int alphabiasshift = 10; /* alpha starts at 1.0 */
int initalpha = (((int) 1) << 10); //(((int) 1) << alphabiasshift);

int alphadec; /* biased by 10 bits */

/* radbias and alpharadbias used for radpower calculation */
int radbiasshift = 8;
int radbias = (((int) 1) << 8); //(((int) 1) << radbiasshift);
int alpharadbshift = 10+8; //(alphabiasshift + radbiasshift);
int alpharadbias = (((int) 1) << (10+8)); //(((int) 1) << alpharadbshift);

typedef struct NeuQuant_Context 
{
	uint8_t *mapTable;
	uint8_t *thepicture; /* the input image itself */
	int lengthcount; /* lengthcount = H*W*3 */
	int samplefac; /* sampling factor 1..30 */
	//   typedef int pixel[4]; /* BGRc */
	int **network; /* the network itself - [netsize][4] */	
	int *netindex; /* for network lookup - really 256 */

	int *bias; /* bias and freq arrays for learning */
	int *freq; 
	int *radpower; 
}NeuQuant_Context;

void Unbiasnet(NeuQuant_Context *pNeuQuantCtx) ;
void Alterneigh(NeuQuant_Context *pNeuQuantCtx,int rad, int i, int b, int g, int r) ;
void Altersingle(NeuQuant_Context *pNeuQuantCtx,int alpha, int i, int b, int g, int r) ;
int Contest(NeuQuant_Context *pNeuQuantCtx,int b, int g, int r) ;

RDGIFHANDLE NeQuantCreator(uint8_t *thepic, int len, int sample)
{
	NeuQuant_Context *pNeuQuantCtx = (NeuQuant_Context*)malloc(sizeof(NeuQuant_Context));
	int i;
	int *p;
	
	pNeuQuantCtx->thepicture = thepic;
	pNeuQuantCtx->lengthcount=len;
	pNeuQuantCtx->samplefac = sample;
	
	pNeuQuantCtx->netindex = (int*)malloc(256*sizeof(int));
	memset(pNeuQuantCtx->netindex,0,256*sizeof(int));
	pNeuQuantCtx->bias = (int*)malloc(netsize*sizeof(int));
	memset(pNeuQuantCtx->bias,0,netsize*sizeof(int));
	pNeuQuantCtx->freq = (int*)malloc(netsize*sizeof(int));
	memset(pNeuQuantCtx->freq,0,netsize*sizeof(int));
	pNeuQuantCtx->radpower = (int*)malloc(initrad*sizeof(int));
	memset(pNeuQuantCtx->radpower,0,initrad*sizeof(int));
	
	pNeuQuantCtx->network = (int**)malloc(netsize*sizeof(int*));
	for (i = 0; i < netsize; i++) 
	{
		pNeuQuantCtx->network[i] = (int*)malloc(4*sizeof(int));
		p = pNeuQuantCtx->network[i];
		//p[0] = p[1] = p[2] = (i << (netbiasshift + 8)) / netsize;
		*p = *(p+1) = *(p+2) = (i << (netbiasshift + 8)) / netsize;
		pNeuQuantCtx->freq[i] = intbias / netsize; /* 1/netsize */
		pNeuQuantCtx->bias[i] = 0;
	}
	return pNeuQuantCtx;
}

uint8_t* CreateColorMap(NeuQuant_Context *pNeuQuantCtx) 
{
	int i;
	int k = 0;
	int tmp = 0;
	int *index = (int*)malloc(netsize*sizeof(int));
	
	pNeuQuantCtx->mapTable = (uint8_t*)malloc(3*netsize);	
	for (i = 0; i < netsize; i++)
	{
		tmp = pNeuQuantCtx->network[i][3];
		index[tmp] = i;
	}
	
	for (i = 0; i < netsize; i++) 
	{
		int j = index[i];
		pNeuQuantCtx->mapTable[k++] = (uint8_t) (pNeuQuantCtx->network[j][0]);
		pNeuQuantCtx->mapTable[k++] = (uint8_t) (pNeuQuantCtx->network[j][1]);
		pNeuQuantCtx->mapTable[k++] = (uint8_t) (pNeuQuantCtx->network[j][2]);
	}
	free(index);
	return pNeuQuantCtx->mapTable;
}

void Inxbuild(NeuQuant_Context *pNeuQuantCtx) 
{	
	int i, j, smallpos, smallval;
	int *p;
	int *q;
	int previouscol, startpos;
	
	int **network = pNeuQuantCtx->network;
	int *netindex  = pNeuQuantCtx->netindex;

	previouscol = 0;
	startpos = 0;
	for (i = 0; i < netsize; i++) 
	{
		p = network[i];
		smallpos = i;
		smallval = p[1]; /* index on g */
		/* find smallest in i..netsize-1 */
		for (j = i + 1; j < netsize; j++) 
		{
			q = network[j];
			if (q[1] < smallval) 
			{ /* index on g */
				smallpos = j;
				smallval = q[1]; /* index on g */
			}
		}
		q = network[smallpos];
		/* swap p (i) and q (smallpos) entries */
		if (i != smallpos) 
		{
			j = q[0];
			q[0] = p[0];
			p[0] = j;
			j = q[1];
			q[1] = p[1];
			p[1] = j;
			j = q[2];
			q[2] = p[2];
			p[2] = j;
			j = q[3];
			q[3] = p[3];
			p[3] = j;
		}
		/* smallval entry is now in position i */
		if (smallval != previouscol) 
		{
			netindex[previouscol] = (startpos + i) >> 1;
			for (j = previouscol + 1; j < smallval; j++)
				netindex[j] = i;
			previouscol = smallval;
			startpos = i;
		}
	}
	netindex[previouscol] = (startpos + maxnetpos) >> 1;
	for (j = previouscol + 1; j < 256; j++)
		netindex[j] = maxnetpos; /* really 256 */
}

void Learn(NeuQuant_Context *pNeuQuantCtx) 
{	
	int i, j, b, g, r;
	int radius, rad, alpha, step, delta, samplepixels;
	uint8_t *p;
	int pix, lim;
	
	int *radpower = pNeuQuantCtx->radpower;
	int lengthcount = pNeuQuantCtx->lengthcount;
	int samplefac = pNeuQuantCtx->samplefac;
	uint8_t *thepicture = pNeuQuantCtx->thepicture;
	
	if (lengthcount < minpicturebytes)
		samplefac = 1;
	alphadec = 30 + ((samplefac - 1) / 3);
	p = thepicture;
	pix = 0;
	lim = lengthcount;
	samplepixels = lengthcount / (3 * samplefac);
	delta = samplepixels / ncycles;
	alpha = initalpha;
	radius = initradius;
	
	rad = radius >> radiusbiasshift;
	if (rad <= 1)
		rad = 0;
	for (i = 0; i < rad; i++)
		radpower[i] = alpha * (((rad * rad - i * i) * radbias) / (rad * rad));
	
	if (lengthcount < minpicturebytes)
		step = 3;
	else if ((lengthcount % prime1) != 0)
		step = 3 * prime1;
	else 
	{
		if ((lengthcount % prime2) != 0)
			step = 3 * prime2;
		else 
		{
			if ((lengthcount % prime3) != 0)
				step = 3 * prime3;
			else
				step = 3 * prime4;
		}
	}
	
	i = 0;
	while (i < samplepixels) 
	{
		b = (p[pix + 0] & 0xff) << netbiasshift;
		g = (p[pix + 1] & 0xff) << netbiasshift;
		r = (p[pix + 2] & 0xff) << netbiasshift;
		j = Contest(pNeuQuantCtx, b, g, r);
		
		Altersingle(pNeuQuantCtx,alpha, j, b, g, r);
		if (rad != 0)
			Alterneigh(pNeuQuantCtx,rad, j, b, g, r); /* alter neighbours */
		
		pix += step;
		if (pix >= lim)
			pix -= lengthcount;
		
		i++;
		if (delta == 0)
			delta = 1;
		if (i % delta == 0) 
		{
			alpha -= alpha / alphadec;
			radius -= radius / radiusdec;
			rad = radius >> radiusbiasshift;
			if (rad <= 1)
				rad = 0;
			for (j = 0; j < rad; j++)
				radpower[j] =
				alpha * (((rad * rad - j * j) * radbias) / (rad * rad));
		}
	}
}

int NeQuantMap(RDGIFHANDLE handle ,int b, int g, int r)
{	
	NeuQuant_Context *pNeuQuantCtx = (NeuQuant_Context *)handle;
	int i, j, dist, a, bestd;
	int *p;
	int best;
	int **network = pNeuQuantCtx->network;
	int *netindex = pNeuQuantCtx->netindex; 
	
	bestd = 1000; /* biggest possible dist is 256*3 */
	best = -1;
	i = netindex[g]; /* index on g */
	j = i - 1; /* start at netindex[g] and work outwards */
	
	while ((i < netsize) || (j >= 0)) 
	{
		if (i < netsize) 
		{
			p = network[i];
			dist = p[1] - g; /* inx key */
			if (dist >= bestd)
				i = netsize; /* stop iter */
			else 
			{
				i++;
				if (dist < 0)
					dist = -dist;
				a = p[0] - b;
				if (a < 0)
					a = -a;
				dist += a;
				if (dist < bestd) 
				{
					a = p[2] - r;
					if (a < 0)
						a = -a;
					dist += a;
					if (dist < bestd) 
					{
						bestd = dist;
						best = p[3];
					}
				}
			}
		}
		if (j >= 0) 
		{
			p = network[j];
			dist = g - p[1]; /* inx key - reverse dif */
			if (dist >= bestd)
				j = -1; /* stop iter */
			else 
			{
				j--;
				if (dist < 0)
					dist = -dist;
				a = p[0] - b;
				if (a < 0)
					a = -a;
				dist += a;
				if (dist < bestd) 
				{
					a = p[2] - r;
					if (a < 0)
						a = -a;
					dist += a;
					if (dist < bestd) 
					{
						bestd = dist;
						best = p[3];
					}
				}
			}
		}
	}
	return (best);
}


uint8_t *NeQuantProcess(RDGIFHANDLE handle)
{
	NeuQuant_Context *pNeuQuantCtx = (NeuQuant_Context *)handle;
	Learn(pNeuQuantCtx);
	Unbiasnet(pNeuQuantCtx);
	Inxbuild(pNeuQuantCtx);
	return CreateColorMap(pNeuQuantCtx);
}

void Unbiasnet(NeuQuant_Context *pNeuQuantCtx) 
{
	int **network = pNeuQuantCtx->network;
	int i;	
	for (i = 0; i < netsize; i++) 
	{
		network[i][0] >>= netbiasshift;
		network[i][1] >>= netbiasshift;
		network[i][2] >>= netbiasshift;
		network[i][3] = i; /* record colour no */
	}
}

void Alterneigh(NeuQuant_Context *pNeuQuantCtx,int rad, int i, int b, int g, int r) 
{	
	int j, k, lo, hi, a, m;
	int *p;
	int *radpower = pNeuQuantCtx->radpower;
	int **network = pNeuQuantCtx->network;
	
	lo = i - rad;
	if (lo < -1)
		lo = -1;
	hi = i + rad;
	if (hi > netsize)
		hi = netsize;
	
	j = i + 1;
	k = i - 1;
	m = 1;
	while ((j < hi) || (k > lo)) 
	{
		a = radpower[m++];
		if (j < hi) 
		{
			p = network[j++];

			p[0] -= (a * (p[0] - b)) / alpharadbias;
			p[1] -= (a * (p[1] - g)) / alpharadbias;
			p[2] -= (a * (p[2] - r)) / alpharadbias;
		

		}
		if (k > lo) 
		{
			p = network[k--];

			p[0] -= (a * (p[0] - b)) / alpharadbias;
			p[1] -= (a * (p[1] - g)) / alpharadbias;
			p[2] -= (a * (p[2] - r)) / alpharadbias;

		}
	}
}

void Altersingle(NeuQuant_Context *pNeuQuantCtx,int alpha, int i, int b, int g, int r) 
{	
	int **network = pNeuQuantCtx->network;
	/* alter hit neuron */
	int *n = network[i];
	n[0] -= (alpha * (n[0] - b)) / initalpha;
	n[1] -= (alpha * (n[1] - g)) / initalpha;
	n[2] -= (alpha * (n[2] - r)) / initalpha;
}		

int Contest(NeuQuant_Context *pNeuQuantCtx,int b, int g, int r) 
{
	
	/* finds closest neuron (min dist) and updates freq */
	/* finds best neuron (min dist-bias) and returns position */
	/* for frequently chosen neurons, freq[i] is high and bias[i] is negative */
	/* bias[i] = gamma*((1/netsize)-freq[i]) */
	
	int i, dist, a, biasdist, betafreq;
	int bestpos, bestbiaspos, bestd, bestbiasd;
	int *n;
	int **network = pNeuQuantCtx->network;
	int *bias = pNeuQuantCtx->bias;
	int *freq = pNeuQuantCtx->freq;
	
	bestd = ~(((int) 1) << 31);
	bestbiasd = bestd;
	bestpos = -1;
	bestbiaspos = bestpos;
	
	for (i = 0; i < netsize; i++) 
	{
		n = network[i];
		dist = n[0] - b;
		if (dist < 0)
			dist = -dist;
		a = n[1] - g;
		if (a < 0)
			a = -a;
		dist += a;
		a = n[2] - r;
		if (a < 0)
			a = -a;
		dist += a;
		if (dist < bestd) 
		{
			bestd = dist;
			bestpos = i;
		}
		biasdist = dist - ((bias[i]) >> (intbiasshift - netbiasshift));
		if (biasdist < bestbiasd) 
		{
			bestbiasd = biasdist;
			bestbiaspos = i;
		}
		betafreq = (freq[i] >> betashift);
		freq[i] -= betafreq;
		bias[i] += (betafreq << gammashift);
	}
	freq[bestpos] += beta;
	bias[bestpos] -= betagamma;
	return (bestbiaspos);
}

int	NeQuantClose(RDGIFHANDLE handle)
{
	NeuQuant_Context *pNeuQuantCtx = (NeuQuant_Context *)handle;
	if (pNeuQuantCtx->netindex) free((int8_t*)pNeuQuantCtx->netindex);
	if (pNeuQuantCtx->bias) free((int8_t*)pNeuQuantCtx->bias);
	if (pNeuQuantCtx->freq) free((int8_t*)pNeuQuantCtx->freq);
	if (pNeuQuantCtx->radpower) free((int8_t*)pNeuQuantCtx->radpower);	
	if (pNeuQuantCtx->network)
	{
		int i;
		for (i = 0; i < netsize; i++) 
			free((int8_t*)pNeuQuantCtx->network[i]);
		free((int8_t*)pNeuQuantCtx->network);
	}
	free(pNeuQuantCtx);
	return 1;
}
