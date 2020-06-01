#include "IMG_SimpleSegmentation.h"
#include "CImageData.h"

#include <list>

struct ivec2
{
	int x, y;
};

// returns vector of segmented objects and coloring as ulong-image
std::vector<CSimpleSegmentedObject *> *IMG_SimpleSegmentation(CImageData *imageIn, CImageData **segmentedImageULong)
{
	LOGD("IMG_SimpleSegmentation");
	
	// this is simple segmentation, will find a pixel which was not yet colored, and do a coloring using flood-fill
	CImageData *imageOut = new CImageData(imageIn->width, imageIn->height, IMG_TYPE_LONG_INT);
	imageOut->AllocImage(false, true);
	
//	for (int xx = 0; xx < imageIn->width; xx++)
//	{
//		for (int yy = 0; yy < imageIn->height; yy++)
//		{
//			u8 r,g,b,a;
//			imageIn->GetPixelResultRGBA(xx, yy, &r, &g, &b, &a);
//			LOGD("%d %d: %d", xx, yy, a);
//		}
//	}

//	//
//	LOGD("---");
	
	int countObject = 0;
	std::vector<CSimpleSegmentedObject *> *segmentedObjects = new std::vector<CSimpleSegmentedObject *>();
	
	for (int y = 0; y < imageIn->height; y++)
	{
		for (int x = 0; x < imageIn->width; x++)
		{
			unsigned long objectId = imageOut->GetPixelResultLong(x, y);
			if (objectId != 0)
				continue;
			
			// pixel is not colored
			u8 r,g,b,a;
			imageIn->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
			
			if (a == 0)
				continue;
			
			// found first not colored pixel
			countObject++;
//			LOGD("obj... #%d", countObject);

			int minx = INT_MAX;
			int miny = INT_MAX;
			int maxx = INT_MIN;
			int maxy = INT_MIN;
			int volume = 0;
			
			// do a floodfill
			std::list<ivec2> queue;
			
			ivec2 pstart;
			pstart.x = x;
			pstart.y = y;
			queue.push_back(pstart);
			
//			LOGD("..push %d %d", pstart.x, pstart.y);
			while(!queue.empty())
			{
				ivec2 p = queue.back();
				queue.pop_back();
				
//				LOGD("..pop  %d %d", p.x, p.y);
				
				imageOut->SetPixelResultLong(p.x, p.y, countObject);
				volume++;
				
				minx = UMIN(p.x, minx);
				miny = UMIN(p.y, miny);
				maxx = UMAX(p.x, maxx);
				maxy = UMAX(p.y, maxy);
				
				// check surrounding pixels
				if (p.x < imageIn->width-1)
				{
					imageIn->GetPixelResultRGBA(p.x + 1, p.y, &r, &g, &b, &a);
					if (a != 0 && imageOut->GetPixelResultLong(p.x + 1, p.y) == 0)
					{
						ivec2 pp;
						pp.x = p.x + 1;
						pp.y = p.y;
						queue.push_back(pp);
//						LOGD("..push %d %d", pp.x, pp.y);
					}
				}

				if (p.x > 0)
				{
					imageIn->GetPixelResultRGBA(p.x - 1, p.y, &r, &g, &b, &a);
					if (a != 0 && imageOut->GetPixelResultLong(p.x - 1, p.y) == 0)
					{
						ivec2 pp;
						pp.x = p.x - 1;
						pp.y = p.y;
						queue.push_back(pp);
//						LOGD("..push %d %d", pp.x, pp.y);
					}
				}

				if (p.y < imageIn->height-1)
				{
					imageIn->GetPixelResultRGBA(p.x, p.y + 1, &r, &g, &b, &a);
					if (a != 0 && imageOut->GetPixelResultLong(p.x, p.y + 1) == 0)
					{
						ivec2 pp;
						pp.x = p.x;
						pp.y = p.y + 1;
						queue.push_back(pp);
//						LOGD("..push %d %d", pp.x, pp.y);
					}
				}
				
				if (p.y > 0)
				{
					imageIn->GetPixelResultRGBA(p.x, p.y - 1, &r, &g, &b, &a);
					if (a != 0 && imageOut->GetPixelResultLong(p.x, p.y - 1) == 0)
					{
						ivec2 pp;
						pp.x = p.x;
						pp.y = p.y - 1;
						queue.push_back(pp);
//						LOGD("..push %d %d", pp.x, pp.y);
					}
				}
			}
			
			// store object
			LOGD("object #%d: %d %d %d %d (%d)", countObject, minx, miny, maxx, maxy, volume);
			
			CSimpleSegmentedObject *obj = new CSimpleSegmentedObject();
			obj->volume = volume;
			obj->posLTX = minx;
			obj->posLTY = miny;
			obj->posRBX = maxx;
			obj->posRBY = maxy;
			
			segmentedObjects->push_back(obj);
		}
	}
	
	*segmentedImageULong = imageOut;
	LOGD("IMG_SimpleSegmentation: done");
	
	return segmentedObjects;
}

