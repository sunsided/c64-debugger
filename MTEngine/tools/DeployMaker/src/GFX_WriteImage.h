#include "SYS_Defs.h"
#include "image/CImageData.h"
#include <list>
#include "GFX_Types.h"

class CSlrImageDummy;

void GFX_WriteImage(char *saveFileName, CImageData *imageIn, u16 screenWidth, u16 destScreenWidth, byte compressionType, bool isSheet);

void GFX_WriteImage(char *saveFileName, CSlrImageDummy *imageIn, u16 screenWidth, u16 destScreenWidth, byte compressionType, bool isSheet);

//void GFX_WriteImage(char *fileName, CImageData *imageIn, u32 screenWidth, std::list<u32> destScreenWidths, byte compressionType); //, u32 screenHeight, , std::list<u32> destScreenHeights)



//// write image and perform all necessary conversion (pow ^2, flip vertically)
//void GFX_WriteImage(char *saveFileName, CImageData *imageIn, u16 screenWidth, u16 destScreenWidth, byte compressionType, bool isSheet);
//
//// "clone" original image. that means original image is already converted. just perform data recompression.
//void GFX_WriteImageClone(char *saveFileName, CImageData *imageIn, u16 screenWidth, u16 destScreenWidth, byte compressionType, bool isSheet);
//
////void GFX_WriteImage(char *fileName, CImageData *imageIn, u32 screenWidth, std::list<u32> destScreenWidths, byte compressionType); //, u32 screenHeight, , std::list<u32> destScreenHeights)
//
