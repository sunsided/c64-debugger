#ifndef _IMG_SIMPLESEGMENTATION_
#define _IMG_SIMPLESEGMENTATION_

#include <vector>

class CImageData;

class CSimpleSegmentedObject
{
public:
	unsigned long objectId;
	int volume;
	int posLTX, posLTY;	// left-top
	int posRBX, posRBY; // right-bottom
	
};

// in: RGBA image, returns vector of segmented objects and coloring as ulong-image
std::vector<CSimpleSegmentedObject *> *IMG_SimpleSegmentation(CImageData *imageIn, CImageData **segmentedImageULong);

#endif
