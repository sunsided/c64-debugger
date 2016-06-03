#ifndef _RES_DEPLOY_FILE_H_
#define _RES_DEPLOY_FILE_H_

#include "CSlrFile.h"
#include "CByteBuffer.h"
#include "DBG_Log.h"

#if !defined(FINAL_RELEASE)
#include "SYS_Funct.h"
#endif

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
	DEPLOY_FILE_TYPE_JSON,
	DEPLOY_FILE_TYPE_IMAGE_PYRAMID,
	DEPLOY_FILE_TYPE_SID,

	DEPLOY_FILE_TYPE_OUTSIDE_DEPLOY,	// force manual read not from deploy
	DEPLOY_FILE_TYPE_MAXIMUM
} deployFileTypes;


//void RES_DeployFileLoad(CSlrFile *file);
void RES_InitDeployFile(u16 destScreenSize);
void RES_DeployFileLoad(CByteBuffer *deployBuffer, u16 destScreenSize);
CSlrFile *RES_GetFileFromDeploy(char *fileName, byte fileType);
void RES_AddEmbeddedDataToDeploy(char *fileName, u16 fileType, uint8 *embeddedData, int embeddedDataLength);

char *RES_GetFileTypeExtension(byte fileType);

class CDeployFileDetails
{
public:
	u64 hashCode;
	uint8 fileType;
	char *fileExtStr;
	bool forceOriginal;
	uint8 *embeddedData;
	int embeddedDataLength;
	CDeployFileDetails(u64 hashCode, uint8 fileType, char *fileExtStr, bool forceOriginal);
	CDeployFileDetails(u64 hashCode, uint8 fileType, char *fileExtStr, bool forceOriginal, byte *embeddedData, int embeddedDataLength);
};

void RES_GenerateSourceFromData(CByteBuffer *data, char *filePath);
void RES_GenerateEmbedDefaults();

#endif
//_RES_DEPLOY_FILE_H_
