#include "IMG_Scale.h"
#include "resampler.h"
#include "DBG_Log.h"
#include "SYS_Funct.h"
#include <vector>

#if defined(WIN32)
#define NOMINMAX
#include <windows.h>
#endif

using namespace std;
// isSheet: file has to keep aspect in raster
CImageData *IMG_Scale(CImageData *imgIn, float scaleX, float scaleY, bool isSheet)
{
	int dst_width = (int)((float)imgIn->width * scaleX);
	int dst_height = (int)((float)imgIn->height * scaleY);

	if (dst_width < 1)
		dst_width = 1;
	if (dst_height < 1)
		dst_height = 1;

	if (isSheet)
	{
		u16 rasterWidth = NextPow2(dst_width);
		u16 rasterHeight = NextPow2(dst_height);
		LOGD("isSheet: dW=%d dH=%d rasW=%d rasH=%d", dst_width, dst_height, rasterWidth, rasterHeight);
		dst_width = rasterWidth;
		dst_height = rasterHeight;
	}

	return IMG_Scale(imgIn, dst_width, dst_height);
}

CImageData *IMG_Scale(CImageData *imgIn, int destWidth, int destHeight)
{
	if (imgIn->getImageType() != IMG_TYPE_RGBA)
	{
		LOGError("Invalid image type %2.2x", imgIn->getImageType());
		return NULL;
	}

	float scaleX = (float)imgIn->width / (float)destWidth;
	float scaleY = (float)imgIn->height / (float)destHeight;

	int dst_width = destWidth;
	int dst_height = destHeight;

	if ((UMIN(dst_width, dst_height) < 1) || (UMAX(dst_width, dst_height) > RESAMPLER_MAX_DIMENSION))
	{
		LOGError("Invalid output: width=%d height=%d", dst_width, dst_height);
		return NULL;
	}

	int src_width = imgIn->width;
	int src_height = imgIn->height;
	int n = 4;

	unsigned char *pSrc_image = imgIn->getRGBAResultData();

	LOGD("resolution: %ux%u, channels: %u", src_width, src_height, n);

	const int max_components = 4;

	if ((UMAX(src_width, src_height) > RESAMPLER_MAX_DIMENSION) || (n > max_components))
	{
		LOGError("Image is too large");
		return NULL;
	}

	// Partial gamma correction looks better on mips. Set to 1.0 to disable gamma correction.
	const float source_gamma = 1.75f;

	// Filter scale - values < 1.0 cause aliasing, but create sharper looking mips.
	const float filter_scale = 1.0f;//.75f;

	const char* pFilter = RESAMPLER_DEFAULT_FILTER;

	float srgb_to_linear[256];
	for (int i = 0; i < 256; ++i)
	{
		srgb_to_linear[i] = (float)pow(i * 1.0f/255.0f, source_gamma);
	}

	const int linear_to_srgb_table_size = 4096;
	unsigned char linear_to_srgb[linear_to_srgb_table_size];

	const float inv_linear_to_srgb_table_size = 1.0f / linear_to_srgb_table_size;
	const float inv_source_gamma = 1.0f / source_gamma;

	for (int i = 0; i < linear_to_srgb_table_size; ++i)
	{
		int k = (int)(255.0f * pow(i * inv_linear_to_srgb_table_size, inv_source_gamma) + .5f);
		if (k < 0) k = 0; else if (k > 255) k = 255;
		linear_to_srgb[i] = (unsigned char)k;
	}

	Resampler* resamplers[max_components];
	std::vector<float> samples[max_components];

	resamplers[0] = new Resampler(src_width, src_height, dst_width, dst_height,
								  Resampler::BOUNDARY_CLAMP, 0.0f, 1.0f, pFilter, NULL, NULL, filter_scale, filter_scale);
	samples[0].resize(src_width);
	for (int i = 1; i < n; i++)
	{
		resamplers[i] = new Resampler(src_width, src_height, dst_width, dst_height, Resampler::BOUNDARY_CLAMP, 0.0f, 1.0f, pFilter, resamplers[0]->get_clist_x(), resamplers[0]->get_clist_y(), filter_scale, filter_scale);
		samples[i].resize(src_width);
	}

	std::vector<unsigned char> dst_image(dst_width * n * dst_height);

	const int src_pitch = src_width * n;
	const int dst_pitch = dst_width * n;
	int dst_y = 0;

	LOGD("resampling to %ux%u", dst_width, dst_height);

	CImageData *imgDest = new CImageData(dst_width, dst_height, IMG_TYPE_RGBA); //, &dst_image[0]);
	imgDest->AllocImage(false, true);

	for (int src_y = 0; src_y < src_height; src_y++)
	{
		const unsigned char* pSrc = &pSrc_image[src_y * src_pitch];

		for (int x = 0; x < src_width; x++)
		{
			for (int c = 0; c < n; c++)
			{
				if ((c == 3) || ((n == 2) && (c == 1)))
					samples[c][x] = *pSrc++ * (1.0f/255.0f);
				else
					samples[c][x] = srgb_to_linear[*pSrc++];
			}
		}

		for (int c = 0; c < n; c++)
		{
			if (!resamplers[c]->put_line(&samples[c][0]))
			{
				LOGError("Out of memory!");
				return NULL;
			}
		}

		byte r, g, b, a;
		for ( ; ; )
		{
			int c;
			for (c = 0; c < n; c++)
			{
				const float* pOutput_samples = resamplers[c]->get_line();
				if (!pOutput_samples)
					break;

				const bool alpha_channel = (c == 3) || ((n == 2) && (c == 1));

				if (dst_y >= dst_height)
				{
					LOGError("assertion: (dst_y=%d >= dst_height=%d)", dst_y, dst_height);
				}

				unsigned char* pDst = &dst_image[dst_y * dst_pitch + c];

				for (int x = 0; x < dst_width; x++)
				{
					imgDest->GetPixelResultRGBA(x, dst_y, &r, &g, &b, &a);

					if (alpha_channel)
					{
						byte inR, inG, inB, inA;
						
						// nearest for alpha
						//int inX = (int)((float)x * scaleX);
						//int inY = (int)((float)dst_y * scaleY);
						//imgIn->GetPixelResultRGBA(inX, inY, &inR, &inG, &inB, &inA);
						//a = inA;
						
						//LOGD("a=%2.2x", inA);
						
						
						int v = (int)(255.0f * pOutput_samples[x] + .5f);
						if (v < 0)
						{
							v = 0;
						}
						else if (v > 255)
						{
							v = 255;
						}
						*pDst = (unsigned char)v;						
						
						a = (byte)v;
						
						
						imgDest->SetPixelResultRGBA(x, dst_y, r, g, b, a);
					}
					else
					{
						int j = (int)(linear_to_srgb_table_size * pOutput_samples[x] + .5f);
						if (j < 0)
							j = 0;
						else if (j >= linear_to_srgb_table_size)
							j = linear_to_srgb_table_size - 1;
						*pDst = linear_to_srgb[j];

						if (c == 0)
							r = linear_to_srgb[j];
						else if (c == 1)
							g = linear_to_srgb[j];
						else if (c == 2)
							b = linear_to_srgb[j];

						imgDest->SetPixelResultRGBA(x, dst_y, r, g, b, a);
					}

					pDst += n;
				}
			}
			if (c < n)
				break;

			dst_y++;
		}
	}

	/*
	char *pDst_filename = "test.tga";
	printf("Writing TGA file: %s\n", pDst_filename);

	if (!stbi_write_tga(pDst_filename, dst_width, dst_height, n, &dst_image[0]))
	{
		printf("Failed writing output image!\n");
		return NULL;
	}
	*/

	return imgDest;
}

/// imgOut is imgIn width/2
void IMG_ScaleShrinkHalfWidth(CImageData *imgIn, CImageData *imgOut)
{
	for (int py = 0; py < imgIn->height; py++)
	{
		unsigned int offsetIn = py * imgIn->width * 4;
		uint8 *data_in = imgIn->GetResultDataAsRGBA();
		
		unsigned int offsetOut = py * imgOut->width * 4;
		uint8 *data_out = imgOut->GetResultDataAsRGBA();
		
		for (int px = 0; px < imgIn->width; px++)
		{
			uint8 r1,g1,b1,a1;
			uint8 r2,g2,b2,a2;
			
			r1 = data_in[offsetIn++];
			g1 = data_in[offsetIn++];
			b1 = data_in[offsetIn++];
			a1 = data_in[offsetIn++];
			
			r2 = data_in[offsetIn++];
			g2 = data_in[offsetIn++];
			b2 = data_in[offsetIn++];
			a2 = data_in[offsetIn++];
			
			data_out[offsetOut++] = (r1 + r2) / 2;
			data_out[offsetOut++] = (g1 + g2) / 2;
			data_out[offsetOut++] = (b1 + b2) / 2;
			data_out[offsetOut++] = (a1 + a2) / 2;
		}
	}
}

/// imgOut is imgIn width*2
void IMG_ScaleExpandTwiceWidth(CImageData *imgIn, CImageData *imgOut)
{
	for (int py = 0; py < imgIn->height; py++)
	{
		unsigned int offsetIn = py * imgIn->width * 4;
		uint8 *data_in = imgIn->GetResultDataAsRGBA();
		
		unsigned int offsetOut = py * imgOut->width * 4;
		uint8 *data_out = imgOut->GetResultDataAsRGBA();
		
		for (int px = 0; px < imgIn->width; px++)
		{
			uint8 r,g,b,a;
			
			r = data_in[offsetIn++];
			g = data_in[offsetIn++];
			b = data_in[offsetIn++];
			a = data_in[offsetIn++];
			
			data_out[offsetOut++] = r;
			data_out[offsetOut++] = g;
			data_out[offsetOut++] = b;
			data_out[offsetOut++] = a;
			
			data_out[offsetOut++] = r;
			data_out[offsetOut++] = g;
			data_out[offsetOut++] = b;
			data_out[offsetOut++] = a;

		}
	}
}

