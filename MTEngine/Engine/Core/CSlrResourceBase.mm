#include "CSlrResourceBase.h"
#include "SYS_Funct.h"
#include "DBG_Log.h"
#include "RES_ResourceManager.h"

CSlrResourceBase::CSlrResourceBase()
{
	//LOGR("CSlrResourceBase::CSlrResourceBase()");
	this->resourceIsActive = true;
	this->resourceId = 0;
	this->resourceLoadingSize = 0;
	this->resourceIdleSize = 0;
	this->resourceActivatedTime = 0;
	this->resourceHashCode = 0;
	this->resourceBindSize = 0;
	this->resourcePriority = RESOURCE_PRIORITY_NORMAL;
	this->resourcePath = NULL;
	this->resourceIsFromAppResources = true;
	this->resourceState = RESOURCE_STATE_DEALLOCATED;
}

CSlrResourceBase::~CSlrResourceBase()
{
	if (resourcePath != NULL)
	{
		STRFREE(resourcePath);
	}
}

void CSlrResourceBase::ResourceSetPriority(byte newPriority)
{
	this->resourcePriority = newPriority;
}

void CSlrResourceBase::ResourceSetPath(char *path, bool fromResources)
{
	this->resourceIsFromAppResources = fromResources;
	
	if (resourcePath != NULL)
	{
		// do nothing to allow realloc ( ResourceSetPath(this->resourcePath) )
		// resources name should not change anyway!
		//STRFREE(resourcePath);
	}
	else
	{
		resourcePath = STRALLOC(path);
	}
}

char *CSlrResourceBase::ResourceGetPath()
{
	if (resourcePath != NULL)
		return resourcePath;
	else
		return "NULL";

	return NULL;
}

// should preload resource and set resource size
bool CSlrResourceBase::ResourcePreload(char *fileName, bool fromResources)
{
	LOGWarning("CSlrResourceBase::ResourcePreload: %s", fileName);
	this->resourceIdleSize = 0;
	this->resourceLoadingSize = 0;
	this->resourceState = RESOURCE_STATE_PRELOADING;
	return false;
}

u32 CSlrResourceBase::ResourceDeactivate(bool async)
{
	LOGWarning("CSlrResourceBase::ResourceDeactivate");
	this->resourceState = RESOURCE_STATE_DEALLOCATED;
	return 0;
}

u32 CSlrResourceBase::ResourceActivate(bool async)
{
	LOGWarning("CSlrResourceBase::ResourceActivate");
	this->resourceIdleSize = 0;
	this->resourceLoadingSize = 0;
	this->resourceState = RESOURCE_STATE_LOADED;
	return 0;
}

void CSlrResourceBase::ResourcePrepare()
{
	RES_ResourcePrepare(this);
}

u32 CSlrResourceBase::ResourceGetLoadingSize()
{
	LOGWarning("CSlrResourceBase::ResourceGetLoadingSize");
	return this->resourceLoadingSize;
}

u32 CSlrResourceBase::ResourceGetIdleSize()
{
	LOGWarning("CSlrResourceBase::ResourceGetIdleSize");
	return this->resourceIdleSize;
}

char *CSlrResourceBase::ResourceGetTypeName()
{
	SYS_FatalExit("CSlrResourceBase::ResourceGetTypeName: path=%s type=%d", ResourceGetPath(), this->resourceType);
	return "";
}

char *CSlrResourceBase::ResourceGetStateName()
{
	switch(resourceState)
	{
		case RESOURCE_STATE_DEALLOCATED:
			return "DEALLOCATED";
		case RESOURCE_STATE_PRELOADING:
			return "PRELOADED";
		case RESOURCE_STATE_PRELOADING_LOADED:
			return "LOADED-PRE";
		case RESOURCE_STATE_LOADING:
			return "...LOADING...";
		case RESOURCE_STATE_LOADED:
			return "LOADED";
		default:
			return "UNKNOWN";
	}
}


