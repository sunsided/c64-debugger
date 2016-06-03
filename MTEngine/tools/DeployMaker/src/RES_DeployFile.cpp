#include "RES_DeployFile.h"
#include "SYS_Main.h"
#include "CSlrDate.h"
#include <math.h>
#include <stdlib.h>
#include <list>
#include <map>

std::map< u64, CDeployFileDetails * > *deployFilesByHashcode[DEPLOY_FILE_TYPE_MAXIMUM];

void RES_DeployFileLoad(CByteBuffer *deployBuffer, u16 destScreenWidth)
{
	LOGM("RES_DeployFileLoad: dest screen width %d", destScreenWidth);

	for (u16 i = 0; i < DEPLOY_FILE_TYPE_MAXIMUM; i++)
	{
		deployFilesByHashcode[i] = new std::map< u64, CDeployFileDetails * >();
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

	std::list<u16> destScreenWidths;
	u16 numWidths = deployBuffer->getUnsignedShort();

	int selWidth = -1;
	int selWidthDiff = 65535;
	u16 selWidthNum = 0;

	for (u16 i = 0; i < numWidths; i++)
	{
		u16 oneWidth = deployBuffer->getUnsignedShort();

		LOGD("%d: checking %d", i, oneWidth);

		int diff = abs(destScreenWidth - oneWidth);
		if (diff < selWidthDiff)
		{
			selWidth = oneWidth;
			selWidthDiff = diff;
			selWidthNum = i;
		}
	}

	LOGD("selWidth=%d selWidthDiff=%d selWidthNum=%d", selWidth, selWidthDiff, selWidthNum);

	u32 numFiles = deployBuffer->getUnsignedInt();

	CDeployFileDetails *deployFileDetails = NULL;

	u32 fileIdNum = 0;
	for (u32 i = 0; i < numFiles; i++)
	{
		LOGD("i=%d", i);
		u64 hashCode = deployBuffer->GetU64();
//		char *fileName = deployBuffer->getString();

		u16 type = deployBuffer->getUnsignedShort();
		if (type == DEPLOY_FILE_TYPE_GFX)
		{
			LOGD("DEPLOY_FILE_TYPE_GFX");
			bool forceOriginal = deployBuffer->getBoolean();

			u32 fileId = fileIdNum + selWidthNum;

			deployFileDetails =
					new CDeployFileDetails(hashCode, type, NULL);

			fileIdNum += numWidths;
		}
		else if (type == DEPLOY_FILE_TYPE_UNKNOWN)
		{
			LOGD("DEPLOY_FILE_TYPE_UNKNOWN");
			u32 fileId = fileIdNum;
			char *ext = deployBuffer->getString();
			deployFileDetails =
					new CDeployFileDetails(hashCode, type, ext);
			fileIdNum++;
		}
		else
		{
			LOGD("DEPLOY_FILE_TYPE %2.2x", type);
			u32 fileId = fileIdNum;
			LOGD("fileId=%d", fileIdNum);
			//LOGD("fileName=%s", fileName);
			deployFileDetails =
					new CDeployFileDetails(hashCode, type, NULL);
			fileIdNum++;
		}

		std::map< u64, CDeployFileDetails * >::iterator it = deployFilesByHashcode[type]->find(hashCode);

		if (it != deployFilesByHashcode[type]->end())
		{
			SYS_FatalExit("RES_DeployFileLoad: deploy file repeated, already added (hash=%16.16llx)", hashCode);
		}

		deployFilesByHashcode[type]->insert(std::pair<u64, CDeployFileDetails *>(hashCode, deployFileDetails));
	}
}

