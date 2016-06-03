#ifndef _CCONFIG_READER_H_
#define _CCONFIG_READER_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"
#include <vector>

#define MAX_NAME_LEN 255
#define MAX_VALUE_LEN 511

class CConfigValue
{
public:
	char name[MAX_NAME_LEN];
	char val[MAX_VALUE_LEN];

	CConfigValue();
};

class CConfigStorage
{
public:
	char fileName[MAX_VALUE_LEN];
	
	CConfigStorage();
	CConfigStorage(bool fromResources, char *fileName);
	CConfigStorage(CSlrFile *file);
	~CConfigStorage();

	void Save();

	void ReadFromFile(CSlrFile *file);

	std::vector<CConfigValue *> *values;

	CConfigValue *GetConfigValue(char *name);

	bool GetBoolValue(char *name, bool def);
	float GetFloatValue(char *name, float def);
	int GetIntValue(char *name, int def);
	void GetStringValue(char *name, char *value, int numChars, char *def);

	void SetBoolValue(char *name, bool def);
	void SetFloatValue(char *name, float def);
	void SetIntValue(char *name, int def);
	void SetStringValue(char *name, char *value, int numChars);

	void DumpToFile(char *filePath);
	void DumpToLog();
};


#endif

//_CCONFIG_READER_H_

