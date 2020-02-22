#ifdef WIN32
#include <windows.h>
#endif

#include "CBufferOffsets.h"
#include "./../SYS_Funct.h"
#include "CImageData.h"
#include <list>
#include <map>

std::map<unsigned int, CBufferOffsetsList * > bufferOffsetsMap;

CBufferOffsets::CBufferOffsets(byte imageType, unsigned int height, unsigned int width)
{
	this->height = height;
	this->width = width;
	this->type = imageType;
	
	this->offsets = allocate2DArray<unsigned int>(this->width, this->height);	
	//logger->debug("CBufferOffsets: allocated %d %d", this->height, this->width);
	
	if (this->type == IMG_TYPE_GRAYSCALE
		|| this->type == IMG_TYPE_SHORT_INT
		|| this->type == IMG_TYPE_LONG_INT)
	{
		//unsigned int offset = 0;
		for (unsigned int y = 0; y < this->height; y++)
		{
			for (unsigned int x = 0; x < this->width; x++)
			{
				this->offsets[x][y] = y*this->width + x; //offset + x;
			}
			//offset += this->width;
		}
	}
	else if (this->type == IMG_TYPE_RGB
		|| this->type == IMG_TYPE_CIELAB)
	{
		for (unsigned int y = 0; y < this->height; y++)
		{
			for (unsigned int x = 0; x < this->width; x++)
			{
				this->offsets[x][y] = y * width * 3 + x * 3;
			}
		}		
	}
	else if (this->type == IMG_TYPE_RGBA)
	{
		for (unsigned int y = 0; y < this->height; y++)
		{
			for (unsigned int x = 0; x < this->width; x++)
			{
				this->offsets[x][y] = y * width * 4 + x * 4;
			}
		}		
	}
	else
	{
		LOGError("CBufferOffsets: unknown image type: %2.2x", type);
		SYS_FatalExit();
	}
}

CBufferOffsets::~CBufferOffsets()
{
	//logger->debug("CBufferOffsets: deallocating %d %d", this->height, this->width);
	free2DArray<unsigned int>(this->offsets);
}

CBufferOffsetsList::CBufferOffsetsList()
{
	this->first = NULL;
	this->last = NULL;
}

CBufferOffsetsList::~CBufferOffsetsList()
{
	//if (this->first)
		//logger->error("~CBufferOffsetsList() - list is not empty");		
}

CBufferOffsets * IMG_GetBufferOffsets(byte imageType, unsigned int height, unsigned int width)
{
	//logger->debug("IMG_GetBufferOffsets");
	CBufferOffsets *bufferOffsets = NULL;
	unsigned int val = imageType * (height % 100) * (width % 100);
	std::map<unsigned int, CBufferOffsetsList * >::iterator bufferOffsetsListIter = bufferOffsetsMap.find(val);
	if (bufferOffsetsListIter == bufferOffsetsMap.end())
	{
		//logger->debug("CBufferOffsets %d %d %d was not found in the map, creating new one", imageType, width, height);
		bufferOffsets = new CBufferOffsets(imageType, height, width);
		CBufferOffsetsList *list = new CBufferOffsetsList();
		LINK(bufferOffsets, list->first, list->last, next, prev);
		bufferOffsetsMap[val] = list;
		return bufferOffsets;
	}
	else
	{
		CBufferOffsetsList *list = (*bufferOffsetsListIter).second;
		for(bufferOffsets = list->first; bufferOffsets; bufferOffsets = bufferOffsets->next)
		{
			if (bufferOffsets->type == imageType
				&& bufferOffsets->height == height
				&& bufferOffsets->width == width)
			{
				//logger->debug("found buffer offsets");
				return bufferOffsets;
			}
		}
		//logger->debug("CBufferOffsets %d %d %d was not found in the list, creating new one", imageType, width, height);
		bufferOffsets = new CBufferOffsets(imageType, height, width);
		LINK(bufferOffsets, list->first, list->last, next, prev);
		return bufferOffsets;
	}
	return NULL;
}

void IMG_FreeAllBufferOffsets()
{
	LOGD("IMG_FreeAllBufferOffsets");	
		
	for (std::map<unsigned int, CBufferOffsetsList * >::iterator bufferOffsetsListIter = bufferOffsetsMap.begin();
			bufferOffsetsListIter != bufferOffsetsMap.end(); bufferOffsetsListIter++)
	{
		CBufferOffsetsList *list = (*bufferOffsetsListIter).second;
		CBufferOffsets *bufferOffsets_next = NULL;
				
		for(CBufferOffsets *bufferOffsets = list->first; ; bufferOffsets = bufferOffsets_next)
		{
			bufferOffsets_next = bufferOffsets->next;
			delete bufferOffsets;
			if (bufferOffsets_next == NULL)
				break;
		}
		delete list;
	}
}
