#include "CSlrImageMask2.h"
#include "SYS_Main.h"
#include "CSlrImage.h"

CSlrImageMask2::CSlrImageMask2(char *fileName, bool fromResources, bool doThreshold)
{
	CSlrImage *image = new CSlrImage(true, false);
    image->DelayedLoadImage(fileName, fromResources);

	this->width = image->width;
	this->height = image->height;

	CImageData *imageData = image->GetImageData(&this->gfxScale, &this->dataWidth, &this->dataHeight);
	this->maskData = (byte*)malloc(this->dataWidth * this->dataHeight);

	//LOGR("gfxScale=%3.2f dataWidth=%d dataHeight=%d", gfxScale, dataWidth, dataHeight);

	//FILE *fp = fopen("debug-mask.txt", "wb");

	if (doThreshold)
	{
		for (int y = 0; y < dataHeight; y++)
		{
			for (int x = 0; x < dataWidth; x++)
			{
				byte red, green, blue, alpha;
				imageData->GetPixelResultRGBA(x, y, &red, &green, &blue, &alpha);

				if (red > 128)
				{
					this->maskData[((this->dataHeight-y-1)*dataWidth) + x] = IMG_MASK_PIXEL_ON;
					//LOGD("%03d %03d %02x %02x %02x -> %02x", x, y, red, green, blue, 0xFF);
					//fprintf(fp, "X");
				}
				else
				{
					this->maskData[((this->dataHeight-y-1)*dataWidth) + x] = IMG_MASK_PIXEL_OFF;
					//LOGD("%03d %03d %02x %02x %02x -> %02x", x, y, red, green, blue, 0xFF);
					//fprintf(fp, ".");
				}
			}
			//fprintf(fp, "\n");
		}
		//fclose(fp);
	}
	else
	{
		for (int y = 0; y < dataHeight; y++)
		{
			for (int x = 0; x < dataWidth; x++)
			{
				byte red, green, blue, alpha;
				imageData->GetPixelResultRGBA(x, y, &red, &green, &blue, &alpha);

				this->maskData[((this->dataHeight-y-1)*dataWidth) + x] = red;
			}
			//fprintf(fp, "\n");
		}
		//fclose(fp);
	}

    delete image;

}

CSlrImageMask2::~CSlrImageMask2()
{
	free(this->maskData);
}

void CSlrImageMask2::GetImageRealPos(int pX, int pY, int *imageX, int *imageY)
{
	*imageX = (float)pX * (float)gfxScale;
    *imageY = (float)pY * (float)gfxScale;
}

byte CSlrImageMask2::GetMaskValue(int pX, int pY)
{
 //   LOGD("CSlrImageMask2::GetMaskValue: %d %d", pX, pY);

    int posX = (float)pX * (float)gfxScale;
    int posY = (float)pY * (float)gfxScale;

	//LOGD("posX=%d posY=%d", posX, posY);

    if (posX >= 0 && posX < this->dataWidth
		&& posY >= 0 && posY < this->dataHeight)
    {
		byte val = this->maskData[(posY*dataWidth) + posX];
		//LOGD("GetMaskValue2: %d %d val=%2.2x", posX, posY, this->maskData[(posY*dataWidth) + posX]);
		//LOGD(".....return %2.2x, offset=%d width=%d", val, (posY*width) + posX, width);
		return val;
    }

    //LOGD("GetMaskValue2: %d %d outside", posX, posY);
    return 0x00;
}

