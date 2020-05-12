#include "RES_DeployFile.h"
#include "SYS_Main.h"
#include "CSlrFileFromResources.h"
#include "CSlrFileFromDocuments.h"
#include "CSlrFileFromOS.h"
#include "CSlrFileFromMemory.h"
#include "CSlrDate.h"
#include "CImageData.h"
#include "SYS_Funct.h"
#include <list>
#include <map>

std::map< u64, CDeployFileDetails * > *deployFilesByHashcode[DEPLOY_FILE_TYPE_MAXIMUM];

bool initDeployFilesDone = false;

// max size, 960x480 is 960, 1024x768 is 1024, etc
u16 gDestScreenSize;
char gDestScreenSizeNum;

void RES_InitDeployFile(u16 destScreenSize)
{
	LOGM("RES_InitDeployFile");

	for (u16 i = 0; i < DEPLOY_FILE_TYPE_MAXIMUM; i++)
	{
		deployFilesByHashcode[i] = new std::map< u64, CDeployFileDetails * >();
	}

	CByteBuffer *deployBuffer = new CByteBuffer(true, "/deploy/deploy", DEPLOY_FILE_TYPE_OUTSIDE_DEPLOY);
	if (deployBuffer->data == NULL)
	{
		LOGWarning("Deploy file does not exist.");
		delete deployBuffer;
		return;
	}
	RES_DeployFileLoad(deployBuffer, destScreenSize);
	delete deployBuffer;

//	exit(0);
}

void RES_DeployFileLoad(CByteBuffer *deployBuffer, u16 destScreenSize)
{
	LOGM("RES_DeployFileLoad: dest screen size %d", destScreenSize);

	for (u16 i = 0; i < DEPLOY_FILE_TYPE_MAXIMUM; i++)
	{
		deployFilesByHashcode[i]->clear();
	}

	byte m = deployBuffer->getByte();
	if (m != DEPLOY_FILE_MAGIC1)
	{
		SYS_FatalExit("RES_DeployFileLoad: wrong deploy magic %2.2x", m);
	}

	byte v = deployBuffer->getByte();
	if (v > DEPLOY_FILE_VERSION)
	{
		SYS_FatalExit("RES_DeployFileLoad: wrong version %2.2x", v);
	}
	
	CSlrDate *deployDate = deployBuffer->GetDate();
	
	LOGM("RES_DeployFileLoad: deploy file date is %d-%d-%d %02d:%02d:%02d", deployDate->day, deployDate->month, deployDate->year, deployDate->hour, deployDate->minute, deployDate->second);

	delete deployDate;
	
	std::list<u16> destScreenSizes;
	u16 numSizes = deployBuffer->getUnsignedShort();

	int selSize = -1;
	int selSizeDiff = 65535;
	u16 selSizeNum = 0;

	for (u16 i = 0; i < numSizes; i++)
	{
		u16 oneSize = deployBuffer->getUnsignedShort();

		//LOGD("%d: checking %d", i, oneSize);

		int diff = abs(destScreenSize - oneSize);
		if (diff < selSizeDiff)
		{
			selSize = oneSize;
			selSizeDiff = diff;
			selSizeNum = i;
		}
	}

	gDestScreenSize = selSize;
	gDestScreenSizeNum = selSizeNum + 65;

	//NSLog(@"gDestScreenSize=%d", gDestScreenSize);
	
	LOGD("RES_DeployFileLoad: selSize=%d selSizeDiff=%d selSizeNum=%d", selSize, selSizeDiff, selSizeNum);

	u32 numFiles = deployBuffer->getUnsignedInt();

	u32 fileIdNum = 0;
	for (u32 i = 0; i < numFiles; i++)
	{
		LOGTODO("add Deploy resource size parameter (for resource manager)");

		//LOGD("i=%d", i);
		//char *fileName = deployBuffer->getString();
		u64 hashCode = deployBuffer->getU64();

		CDeployFileDetails *deployFileDetails = NULL;

		u16 type = deployBuffer->getUnsignedShort();
		if (type == DEPLOY_FILE_TYPE_GFX)
		{
			//LOGD("DEPLOY_FILE_TYPE_GFX");
			bool forceOriginal = deployBuffer->getBoolean();

			u32 fileId = fileIdNum + selSizeNum;

			deployFileDetails =
					new CDeployFileDetails(hashCode, type, NULL, forceOriginal);

			fileIdNum += numSizes;
		}
		else if (type == DEPLOY_FILE_TYPE_UNKNOWN)
		{
			//LOGD("DEPLOY_FILE_TYPE_UNKNOWN");
			u32 fileId = fileIdNum;
			char *ext = deployBuffer->getString();
			deployFileDetails =
					new CDeployFileDetails(hashCode, type, ext, false);
			fileIdNum++;
		}
		else
		{
			//LOGD("DEPLOY_FILE_TYPE %2.2x", type);
			u32 fileId = fileIdNum;
			//LOGD("fileId=%d", fileIdNum);
			//LOGD("fileName=%s", fileName);
			deployFileDetails =
					new CDeployFileDetails(hashCode, type, NULL, false);
			fileIdNum++;
		}

		std::map< u64, CDeployFileDetails * >::iterator it = deployFilesByHashcode[type]->find(hashCode);

		if (it != deployFilesByHashcode[type]->end())
		{
			SYS_FatalExit("RES_DeployFileLoad: deploy file already added (hash=%lld)", hashCode);
		}

		deployFilesByHashcode[type]->insert(std::pair<u64, CDeployFileDetails *>(hashCode, deployFileDetails));

#if !defined(FINAL_RELEASE)
		char *buf = SYS_GetCharBuf();
		sprintfHexCode64(buf, hashCode);
		LOGR("RES_DeployFileLoad: resource added %s hashCode=%lld type=%2.2x", buf, hashCode, type);
		SYS_ReleaseCharBuf(buf);
#endif
	}
}

void RES_AddFileToDeploy(char *fileName, u16 fileType)
{
	CDeployFileDetails *deployFileDetails = NULL;
	
	LOGD("RES_AddFileToDeploy: %s %d", fileName, fileType);
	
	u64 hashCode = GetHashCode64(fileName);

#if !defined(FINAL_RELEASE)
	char *buf = SYS_GetCharBuf();
	sprintfHexCode64(buf, hashCode);
	LOGR("hashCode=%s =%lld", buf, hashCode);
	SYS_ReleaseCharBuf(buf);
#endif
	
	u16 type = fileType;
	if (type == DEPLOY_FILE_TYPE_GFX)
	{
		//LOGD("DEPLOY_FILE_TYPE_GFX");
		deployFileDetails = new CDeployFileDetails(hashCode, type, NULL, true);
	}
	else if (type == DEPLOY_FILE_TYPE_UNKNOWN)
	{
		SYS_FatalExit("RES_AddFileToDeploy: DEPLOY_FILE_TYPE_UNKNOWN not implemented");
//		//LOGD("DEPLOY_FILE_TYPE_UNKNOWN");
//		char *ext = deployBuffer->getString();
//		deployFileDetails =
//		new CDeployFileDetails(hashCode, type, ext, false);
//		fileIdNum++;
	}
	else
	{
		//LOGD("DEPLOY_FILE_TYPE %2.2x", type);
		//LOGD("fileId=%d", fileIdNum);
		//LOGD("fileName=%s", fileName);
		deployFileDetails = new CDeployFileDetails(hashCode, type, NULL, false);
	}
	
	std::map< u64, CDeployFileDetails * >::iterator it = deployFilesByHashcode[type]->find(hashCode);
	
	if (it != deployFilesByHashcode[type]->end())
	{
		SYS_FatalExit("RES_AddFileToDeploy: deploy file already added (hash=%ld)", hashCode);
	}
	
	deployFilesByHashcode[type]->insert(std::pair<u64, CDeployFileDetails *>(hashCode, deployFileDetails));
	
	LOGD("RES_AddFileToDeploy: resource added %lld-%2.2x", hashCode, type);
}

void RES_AddEmbeddedDataToDeploy(char *fileName, u16 fileType, uint8 *embeddedData, int embeddedDataLength)
{
	CDeployFileDetails *deployFileDetails = NULL;
	
	LOGD("RES_AddFileToDeploy: %s %d", fileName, fileType);
	
	u64 hashCode = GetHashCode64(fileName);
	
#if !defined(FINAL_RELEASE)
	char *buf = SYS_GetCharBuf();
	sprintfHexCode64(buf, hashCode);
	LOGR("hashCode=%s =%lld", buf, hashCode);
	SYS_ReleaseCharBuf(buf);
#endif
	
	u16 type = fileType;
	if (type == DEPLOY_FILE_TYPE_GFX)
	{
		deployFileDetails = new CDeployFileDetails(hashCode, type, NULL, true, embeddedData, embeddedDataLength);
	}
	else if (type == DEPLOY_FILE_TYPE_UNKNOWN)
	{
		SYS_FatalExit("RES_AddFileToDeploy: DEPLOY_FILE_TYPE_UNKNOWN not implemented");
		//		//LOGD("DEPLOY_FILE_TYPE_UNKNOWN");
		//		char *ext = deployBuffer->getString();
		//		deployFileDetails =
		//		new CDeployFileDetails(hashCode, type, ext, false);
		//		fileIdNum++;
	}
	else
	{
		//LOGD("DEPLOY_FILE_TYPE %2.2x", type);
		//LOGD("fileId=%d", fileIdNum);
		//LOGD("fileName=%s", fileName);
		deployFileDetails = new CDeployFileDetails(hashCode, type, NULL, false, embeddedData, embeddedDataLength);
	}
	
	std::map< u64, CDeployFileDetails * >::iterator it = deployFilesByHashcode[type]->find(hashCode);
	
	if (it != deployFilesByHashcode[type]->end())
	{
		SYS_FatalExit("RES_AddFileToDeploy: deploy file already added (hash=%ld)", hashCode);
	}
	
	deployFilesByHashcode[type]->insert(std::pair<u64, CDeployFileDetails *>(hashCode, deployFileDetails));
	
	LOGD("RES_AddFileToDeploy: resource added %lld-%2.2x", hashCode, type);
}

CSlrFile *RES_GetFileFromDeploy(char *fileName, byte fileType)
{
	LOGR("RES_GetFileFromDeploy: %s", fileName);
	
//	if (!strcmp(fileName, "/TetroPuzzles/levels/basic/images/basic-0000"))
//	{
//		LOGD("FILE !");
//	}

	if (fileType == DEPLOY_FILE_TYPE_OUTSIDE_DEPLOY)
	{
		return NULL;
	}

	u64 hashCode = GetHashCode64(fileName);

	LOGR("RES_GetFileFromDeploy: ... hashCode=%lld fileType=%2.2x", hashCode, fileType);

	std::map< u64, CDeployFileDetails * >::iterator it = deployFilesByHashcode[fileType]->find(hashCode);
	if (it == deployFilesByHashcode[fileType]->end())
	{
		LOGR("RES_GetFileFromDeploy: .. file %lld type=%2.2x (path='%s') not found in deploy", hashCode, fileType, fileName);
		return NULL;
	}

	CDeployFileDetails *deployFileDetails = (CDeployFileDetails *) (*it).second;
	
	if (deployFileDetails->embeddedData != NULL)
	{
		// file is embedded
		CSlrFileFromMemory *file = new CSlrFileFromMemory(deployFileDetails->embeddedData, deployFileDetails->embeddedDataLength);
		return file;
	}
	
	char *buf = SYS_GetCharBuf();
	char *hashCodeBuf = SYS_GetCharBuf();

	sprintfHexCode64(hashCodeBuf, hashCode);
	
	if (deployFileDetails->fileType == DEPLOY_FILE_TYPE_GFX)
	{
		LOGR("DEPLOY_FILE_TYPE_GFX");
		if (deployFileDetails->forceOriginal == false)
		{
			//LOGD("=======================================>>> gDestScreenSizeNum=%2.2x '%c'", gDestScreenSizeNum, gDestScreenSizeNum);
			sprintf(buf, "/deploy/%s%c%2.2X", hashCodeBuf, gDestScreenSizeNum, deployFileDetails->fileType);
		}
		else
		{
			sprintf(buf, "/deploy/%s%2.2X", hashCodeBuf, deployFileDetails->fileType);
		}
	}
	else
	{
		//LOGR("DEPLOY_FILE_TYPE=%2.2x", deployFileDetails->fileType);
		sprintf(buf, "/deploy/%s%2.2X", hashCodeBuf, deployFileDetails->fileType);
	}
	
	LOGR("RES_GetFileFromDeploy: open %s", buf);
	CSlrFile *file = NULL;
	
	CSlrFileFromResources *fileFromResources = new CSlrFileFromResources(buf);
	if (fileFromResources->Exists())
	{
		file = fileFromResources;

		LOGR("RES_GetFileFromDeploy: opened from resources: %s", buf);
	}
	else
	{
		delete fileFromResources;
		file = new CSlrFileFromDocuments(buf);
		
		if (file && file->Exists())
		{
			LOGR("RES_GetFileFromDeploy: opened from documents: %s", buf);
		}
	}
	
	SYS_ReleaseCharBuf(hashCodeBuf);
	SYS_ReleaseCharBuf(buf);
	
	// keep original fileName
	strcpy(file->fileName, fileName);

	return file;
}

char *RES_GetFileTypeExtension(byte fileType)
{
	switch(fileType)
	{
	case DEPLOY_FILE_TYPE_GFX:
		return ".gfx";
	case DEPLOY_FILE_TYPE_ANIM:
		return ".anim";
	case DEPLOY_FILE_TYPE_VEC:
		return ".vec";
	case DEPLOY_FILE_TYPE_FONT:
		return ".fnt";
	case DEPLOY_FILE_TYPE_OGG:
		return ".ogg";
	case DEPLOY_FILE_TYPE_TXT:
		return ".txt";
	case DEPLOY_FILE_TYPE_SQSCRIPT_SOURCE:
		return ".nut";
	case DEPLOY_FILE_TYPE_SQSCRIPT:
		return ".cnut";
	case DEPLOY_FILE_TYPE_XM:
		return ".xm";
	case DEPLOY_FILE_TYPE_DATA:
		return ".data";
	case DEPLOY_FILE_TYPE_CSV:
		return ".csv";
	case DEPLOY_FILE_TYPE_JSON:
		return ".json";
	case DEPLOY_FILE_TYPE_IMAGE_PYRAMID:
		return ".pyramid";
	case DEPLOY_FILE_TYPE_SID:
		return ".sid";

	case DEPLOY_FILE_TYPE_UNKNOWN:
	case DEPLOY_FILE_TYPE_NOEXT:
	default:
		return "";

	}
}

CDeployFileDetails::CDeployFileDetails(u64 hashCode, uint8 fileType, char *fileExtStr, bool forceOriginal)
{
#if !defined(FINAL_RELEASE)
	char hashcodeStr[512];
	sprintfHexCode64(hashcodeStr, hashCode);
	
	LOGD("... adding %s hashCode=%lld type=%2.2x", hashcodeStr, hashCode, fileType); //,(fileExtStr == NULL ? "" : fileExtStr));
#endif
	
	this->hashCode = hashCode;
	this->fileType = fileType;
	this->fileExtStr = fileExtStr;
	this->forceOriginal = forceOriginal;
	this->embeddedData = NULL;
	this->embeddedDataLength = 0;
}

CDeployFileDetails::CDeployFileDetails(u64 hashCode, uint8 fileType, char *fileExtStr, bool forceOriginal, byte *embeddedData, int embeddedDataLength)
{
#if !defined(FINAL_RELEASE)
	char hashcodeStr[512];
	sprintfHexCode64(hashcodeStr, hashCode);
	
	LOGD("... adding %s hashCode=%lld type=%2.2x (embedded data length=%d)", hashcodeStr, hashCode, fileType, embeddedDataLength); //,(fileExtStr == NULL ? "" : fileExtStr));
#endif
	
	this->hashCode = hashCode;
	this->fileType = fileType;
	this->fileExtStr = fileExtStr;
	this->forceOriginal = forceOriginal;
	this->embeddedData = embeddedData;
	this->embeddedDataLength = embeddedDataLength;
}

//
// functions to generate embedded data
//

void RES_GenerateSourceFromData(CByteBuffer *data, char *filePathOut, char *embedName)
{
	FILE *fp = fopen(filePathOut, "wb");
	
	data->Rewind();
	
	fprintf(fp, "int %s_length = %d;\n", embedName, data->length);
	fprintf(fp, "uint8 %s[%d] = {\n\t", embedName, data->length);
	
	int count = 0;
	while (!data->IsEof())
	{
		if (count != 0)
		{
			fprintf(fp, ",");
			if (count == 16)
			{
				fprintf(fp, "\n\t");
				count = 0;
			}
			else
			{
				fprintf(fp, " ");
			}
		}
		
		fprintf(fp, "0x%02X", data->GetByte());
		count++;
	}
	
	fprintf(fp, "\n};\n\n");
	
	fclose(fp);
}

void RES_GenerateSourceFromData(char *filePathIn, char *filePathOut, char *embedName)
{
	CSlrFileFromOS *file = new CSlrFileFromOS(filePathIn);
	if (!file->Exists())
	{
		LOGError("RES_GenerateSourceFromData: file does not exist (path='%s')", filePathIn);
		return;
	}
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	RES_GenerateSourceFromData(byteBuffer, filePathOut, embedName);
	delete byteBuffer;
	delete file;
}

void RES_GenerateEmbedDefaults()
{
	LOGM("RES_GenerateEmbedDefaults");
	RES_GenerateSourceFromData("/Users/mars/develop/MTEngine/_RUNTIME_/Documents/Engine/console-plain.gfx",
							   "/Users/mars/Desktop/console-plain-gfx.h",
							   "console_plain_gfx");

	RES_GenerateSourceFromData("/Users/mars/develop/MTEngine/_RUNTIME_/Documents/Engine/default-font.gfx",
							   "/Users/mars/Desktop/default-font-gfx.h",
							   "default_font_gfx");

	RES_GenerateSourceFromData("/Users/mars/develop/MTEngine/_RUNTIME_/Documents/Engine/default-font.fnt",
							   "/Users/mars/Desktop/default-font-fnt.h",
							   "default_font_fnt");

	LOGM("RES_GenerateEmbedDefaults finished");
	SYS_CleanExit();
}

