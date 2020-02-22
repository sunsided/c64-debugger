#ifndef _CFILEFROMTEMP_H_
#define _CFILEFROMTEMP_H_

#include "SYS_Defs.h"
#include "CSlrFileFromDocuments.h"

class CSlrFileFromTemp : public CSlrFileFromDocuments
{
public:
	CSlrFileFromTemp(char *fileName);
	CSlrFileFromTemp(char *fileName, byte fileMode);
	virtual void Open(char *fileName);
	virtual void OpenForWrite(char *fileName);
};

#endif
//_CFILEFROMDOCUMENTS_H_

