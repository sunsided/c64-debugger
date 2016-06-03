#include "SND_WavReader.h"

bool read_wav_header(FILE *fp, unsigned int *samp_rate, unsigned int *bits_per_samp,
					 unsigned int *num_samp);
bool read_wav_data(FILE *fp, int *data, unsigned int samp_rate,
				   unsigned int bits_per_samp, unsigned int num_samp);
int conv_bit_size(unsigned int in, int bps);

byte *SND_ReadWav(FILE *fp, u32 *numSamples, u32 *sampleRate, u8 *bitsPerSamp)
{
	unsigned int samp_rate, bits_per_samp, num_samp;
	if(!read_wav_header(fp, &samp_rate, &bits_per_samp, &num_samp))
	{
		LOGError("read_wav_header: false");
		return NULL;
	}
	printf("samp_rate=[%d] bits_per_samp=[%d] num_samp=[%d]\n",
		   samp_rate, bits_per_samp, num_samp);
	
	int *data = (int *) malloc(num_samp * sizeof(int));
	if (!read_wav_data(fp, data, samp_rate, bits_per_samp, num_samp))
	{
		LOGError("read_wav_data: false");
		return NULL;
	}
	
	/*unsigned int i;
	for (i = 0; i < num_samp; ++i) {
		LOGD("%03d: %d\n", i, data[i]);
	}*/
	
	*numSamples = num_samp;
	*sampleRate = samp_rate;
	*bitsPerSamp = bits_per_samp;
	
	return (byte *)data;
}

bool read_wav_header(FILE *fp, unsigned int *samp_rate, unsigned int *bits_per_samp,
					 unsigned int *num_samp)
{
	unsigned char buf[5];
	
	/* ChunkID (RIFF for little-endian, RIFX for big-endian) */
	fread(buf, 1, 4, fp);
	buf[4] = '\0';
	if (strcmp((char*)buf, "RIFF"))
	{
		LOGError("read_wav_header: RIFF not found");
		return false;	
	}
	
	/* ChunkSize */
	fread(buf, 1, 4, fp);
	
	/* Format */
	fread(buf, 1, 4, fp);
	buf[4] = '\0';
	if (strcmp((char*)buf, "WAVE"))
	{
		LOGError("read_wav_header: WAVE not found");
		return false;
	}
	
	/* Subchunk1ID */
	fread(buf, 1, 4, fp);
	buf[4] = '\0';
	if (strcmp((char*)buf, "fmt "))
	{
		LOGError("fmt");
		return false;	
	}
	
	/* Subchunk1Size (16 for PCM) */
	fread(buf, 1, 4, fp);
	if (buf[0] != 16 || buf[1] || buf[2] || buf[3])
	{
		LOGError("subchunksize buf[0]=%d", buf[0]);
		return false;
	}
	
	/* AudioFormat (PCM = 1, other values indicate compression) */
	fread(buf, 1, 2, fp);
	if (buf[0] != 1 || buf[1]) 
	{
		LOGError("AudioFormat (PCM = 1, other values indicate compression)");
		return false;
	}
	
	/* NumChannels (Mono = 1, Stereo = 2, etc) */
	fread(buf, 1, 2, fp);
	unsigned int num_ch = buf[0] + (buf[1] << 8);
	if (num_ch != 1)
	{
		LOGError("NumChannels=%d", num_ch);
		return false;
	}
	
	/* SampleRate (8000, 44100, etc) */
	fread(buf, 1, 4, fp);
	*samp_rate = buf[0] + (buf[1] << 8) +
	(buf[2] << 16) + (buf[3] << 24);
	
	/* ByteRate (SampleRate * NumChannels * BitsPerSample / 8) */
	fread(buf, 1, 4, fp);
	const unsigned int byte_rate = buf[0] + (buf[1] << 8) +
	(buf[2] << 16) + (buf[3] << 24);
	
	/* BlockAlign (NumChannels * BitsPerSample / 8) */
	fread(buf, 1, 2, fp);
	const unsigned int block_align = buf[0] + (buf[1] << 8);
	
	/* BitsPerSample */
	fread(buf, 1, 2, fp);
	*bits_per_samp = buf[0] + (buf[1] << 8);
	
	if (byte_rate != ((*samp_rate * num_ch * *bits_per_samp) >> 3))
	{
		LOGError("if (byte_rate != ((*samp_rate * num_ch * *bits_per_samp) >> 3))");
		return false;	
	}
	if (block_align != ((num_ch * *bits_per_samp) >> 3))
	{
		LOGError("(block_align != ((num_ch * *bits_per_samp) >> 3))");
		return false;
	}
	/* Subchunk2ID */
	fread(buf, 1, 4, fp);
	buf[4] = '\0';
	if (strcmp((char*)buf, "data")) 
	{
		LOGError("Subchunk2ID != data");
		return false;
	}
	
	/* Subchunk2Size (NumSamples * NumChannels * BitsPerSample / 8) */
	fread(buf, 1, 4, fp);
	const unsigned int subchunk2_size = buf[0] + (buf[1] << 8) +
	(buf[2] << 16) + (buf[3] << 24);
	*num_samp = (subchunk2_size << 3) / (
										 num_ch * *bits_per_samp);
	
	return true;
}


bool read_wav_data(FILE *fp, int *data, unsigned int samp_rate,
				   unsigned int bits_per_samp, unsigned int num_samp)
{
	unsigned char buf;
	unsigned int i, j;
	for (i=0; i < num_samp; ++i) {
		unsigned int tmp = 0;
		for (j=0; j != bits_per_samp; j+=8) {
			fread(&buf, 1, 1, fp);
			tmp += buf << j;
		}
		data[i] = conv_bit_size(tmp, bits_per_samp);
	}
	
	return true;
}


int conv_bit_size(unsigned int ink, int bps)
{
	const unsigned int max = (1 << (bps-1)) - 1;
	return ink > max ? ink - (max<<1) : ink;
}

