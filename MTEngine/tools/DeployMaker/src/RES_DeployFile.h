#ifndef _RES_DEPLOY_FILE_H_
#define _RES_DEPLOY_FILE_H_

#include "CSlrFile.h"
#include "CByteBuffer.h"
#include "DBG_Log.h"
#include "SYS_Funct.h"

#define DEPLOY_FILE_MAGIC1	'D'
#define DEPLOY_FILE_VERSION	0x02

typedef enum
{
	DEPLOY_FILE_TYPE_UNKNOWN = 0x01,
	DEPLOY_FILE_TYPE_NOEXT,
	DEPLOY_FILE_TYPE_GFX,
	DEPLOY_FILE_TYPE_ANIM,
	DEPLOY_FILE_TYPE_VEC,
	DEPLOY_FILE_TYPE_FONT,
	DEPLOY_FILE_TYPE_OGG,
	DEPLOY_FILE_TYPE_TXT,
	DEPLOY_FILE_TYPE_SQSCRIPT_SOURCE,
	DEPLOY_FILE_TYPE_SQSCRIPT,
	DEPLOY_FILE_TYPE_XM,
	DEPLOY_FILE_TYPE_DATA,
	DEPLOY_FILE_TYPE_CSV,

	DEPLOY_FILE_TYPE_MAXIMUM
} deployFileTypes;


//void RES_DeployFileLoad(CSlrFile *file);
void RES_DeployFileLoad(CByteBuffer *deployBuffer, u16 destScreenWidth);

class CDeployFileDetails
{
public:
	u64 hashCode;
	//char *fileName;
	byte fileType;
	char *fileExtStr;

	CDeployFileDetails(u64 hashCode, byte fileType, char *fileExtStr)	//char *fileName,
	{
		//LOGD("CDeployFileDetails: file=%s", fileExtStr);
		
		char hashcodeStr[512];
		sprintfHexCode64(hashcodeStr, hashCode);

		LOGD("... adding %s hashCode=%lld type=%2.2x", hashcodeStr, hashCode, fileType); //,(fileExtStr == NULL ? "" : fileExtStr));

		this->hashCode = hashCode;
		this->fileType = fileType;
		this->fileExtStr = fileExtStr;
	}
};

#endif
//_RES_DEPLOY_FILE_H_
