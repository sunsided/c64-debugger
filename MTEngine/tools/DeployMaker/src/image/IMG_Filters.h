#ifndef IMG_FILTERGAUSSIANBLUR_H_
#define IMG_FILTERGAUSSIANBLUR_H_

#include "./../SYS_Main.h"

#include "CImageData.h"
#include "CImageKernel.h"

CImageKernel *FLT_GetGaussianKernel(double sigma);

void FLT_Convolve(CImageData *imageData, CImageKernel *imageKernel);
void FLT_GradientMagnitude(CImageData *image, float *kern_h, float *kern_v);
void FLT_Dilate(CImageData *imageData, CImageKernel *imageKernel);
void FLT_Erode(CImageData *imageData, CImageKernel *imageKernel);
void FLT_Subtract(CImageData *image, CImageData *subImage);
void FLT_Add(CImageData *image, CImageData *subImage);
CImageData *FLT_Convolve_old(CImageData *imageData, CImageKernel *imageKernel);
CImageData *IMG_FilterGaussianBlur(CImageData *imageData, double sigma);
CImageData *IMG_FilterSobelEdgeDetect(CImageData *image);
void IMG_FilterThreshold(CImageData *image, int threshold);
void IMG_FilterEqualize(CImageData *image);
void IMG_SpotRotate(CImageData *image, float angle);
CImageData *IMG_CropToBoundingBox(CImageData *image);
CImageData *IMG_CropImage(CImageData *image, int posX, int posY, int width, int height);
CImageData *IMG_SpotCropImage(CImageData *image, int posX, int posY, int spotRadius);
void IMG_CircleSpot(CImageData *image);
CImageData * IMG_MorphologicalGradient(CImageData *cielabRaster);
CImageData * IMG_SimpleSegmentation(CImageData *image);
void IMG_FindBound(CImageData *img, bool invert, int *retMinX, int *retMinY, int *retMaxX, int *retMaxY);
void IMG_ScaleNearest(CImageData *img, double factor);

#endif /*IMG_FILTERGAUSSIANBLUR_H_*/
