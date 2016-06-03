#ifndef _SLRRESOURCEBASE_H_
#define _SLRRESOURCEBASE_H_

#include "SYS_Defs.h"

// can not be removed from memory, highest priority
#define RESOURCE_PRIORITY_STATIC	0

// can be removed from memory at any time
// and then recreated (priority > 0)
#define RESOURCE_PRIORITY_NORMAL	100

#define RESOURCE_STATE_DEALLOCATED	0
#define RESOURCE_STATE_PRELOADING	1
#define RESOURCE_STATE_PRELOADING_LOADED		2
#define RESOURCE_STATE_LOADING		3
#define RESOURCE_STATE_LOADED		4

#define RESOURCE_TYPE_UNKNOWN	0
#define RESOURCE_TYPE_IMAGE		1
#define RESOURCE_TYPE_IMAGE_DYNAMIC	2
#define RESOURCE_TYPE_TEXTURE	3
#define RESOURCE_TYPE_FONT		4
#define RESOURCE_TYPE_MUSIC		5

class CSlrResourceBase
{
public:
	CSlrResourceBase();
	virtual ~CSlrResourceBase();

	volatile bool resourceIsActive;
	u64 resourceId;

	u64 resourceHashCode;
	bool resourceIsFromAppResources;
	char *resourcePath;
	
	byte resourceType;
	
	byte resourceState;
	
	// mem needed for loading (decompres...)
	u32 resourceLoadingSize;
	
	// mem occupied when in idle
	u32 resourceIdleSize;
	
	// last time active (image displayed, etc)
	u64 resourceActivatedTime;

	// real memory used reported by os
	u32 resourceBindSize;

	byte resourcePriority;

	virtual void ResourceSetPriority(byte newPriority);
	
	// should preload resource and set resource size
	virtual bool ResourcePreload(char *fileName, bool fromResources);
	
	// resource should load itself, @returns memory allocated
	virtual u32 ResourceActivate(bool async);

	virtual void ResourcePrepare();
	
	// get size of resource in bytes
	virtual u32 ResourceGetLoadingSize();
	virtual u32 ResourceGetIdleSize();

	// resource should free memory, @returns memory freed
	virtual u32 ResourceDeactivate(bool async);
	
	void ResourceSetPath(char *path, bool fromResources);
	char *ResourceGetPath();
	
	virtual char *ResourceGetTypeName();
	virtual char *ResourceGetStateName();
	
};


#endif
// _RESOURCEBASE_H_
