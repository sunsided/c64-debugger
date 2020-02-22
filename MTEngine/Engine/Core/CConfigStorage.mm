#include "CConfigStorage.h"
#include "RES_ResourceManager.h"
#include "SYS_CFileSystem.h"
#include <algorithm>

CConfigValue::CConfigValue()
{
	memset(name, 0x00, MAX_NAME_LEN);
	memset(val, 0x00, MAX_VALUE_LEN);
}

CConfigStorage::CConfigStorage()
{
	this->values = new std::vector<CConfigValue *>();
}

CConfigStorage::CConfigStorage(bool fromResources, char *fileName)
{
	sprintf(this->fileName, "%s.txt", fileName);

	this->values = new std::vector<CConfigValue *>();

	CSlrFile *file = RES_OpenFile(fromResources, fileName, DEPLOY_FILE_TYPE_TXT);
	if (file->Eof())
	{
		LOGError("config file '%s' not found", fileName);
	}
	else
	{
		this->ReadFromFile(file);
	}
	delete file;
}

CConfigStorage::CConfigStorage(CSlrFile *file)
{
	strcpy(this->fileName, file->fileName);

	this->values = new std::vector<CConfigValue *>();

	this->ReadFromFile(file);
}

void CConfigStorage::Save()
{
	this->DumpToFile(this->fileName);
}

void CConfigStorage::ReadFromFile(CSlrFile *file)
{
	//LOGM("============ reading config %s ============", this->fileName);
	if (file->Eof())
	{
		LOGError("file is EOF");
		return;
	}

	bool v = false;
	char buf[512];
	while(!file->Eof())
	{
		v = file->ReadLine(buf, 512);

		//LOGD("ReadLine: '%s'", buf);
		if (buf[0] == '\0')
			continue;

		u32 len = strlen(buf);
		// search for =
		u32 p = 0;
		for (p = 0; p < len; p++)
		{
			if (buf[p] == '=')
				break;
		}

		if (p == len && v)
			break;

		if (p == len)
		{
			if (buf[0] != '#')
			{
				LOGError("'=' not found: '%s', file name='%s'", buf, file->fileName);
			}
			continue;
		}

		if (p >= MAX_NAME_LEN)
		{
			LOGError("config name too long: p=%d MAX_LEN=%d", p, MAX_NAME_LEN);
			continue;
		}

		if (len-p >= MAX_VALUE_LEN)
		{
			LOGError("value too long: p=%d MAX_LEN=%d", p, MAX_NAME_LEN);
			continue;
		}

		CConfigValue *value = new CConfigValue();
		for (u32 i = 0; i < p; i++)
		{
			value->name[i] = buf[i];
		}

		u32 t = 0;
		for (u32 i = p+1; i < len; i++)
		{
			value->val[t++] = buf[i];
		}

		//LOGM("%s=%s", value->name, value->val);
		this->values->push_back(value);

		if (v)
			break;
	}

	//LOGM("============ config %s finished ============", this->fileName);
}

CConfigValue *CConfigStorage::GetConfigValue(char *name)
{
	for (std::vector<CConfigValue *>::iterator it = this->values->begin();
			it != this->values->end(); it++)
	{
		CConfigValue *v = *it;
		if (!strcmp(v->name, name))
		{
			return v;
		}
	}
	return NULL;
}

bool CConfigStorage::GetBoolValue(char *name, bool def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		sprintf(v->name, "%s", name);
		if (def == true)
		{
			sprintf(v->val, "true");
		}
		else
		{
			sprintf(v->val, "false");
		}
		values->push_back(v);
		return def;
	}

	if (!strcmp(v->val, "y")
			|| !strcmp(v->val, "Y")
			|| !strcmp(v->val, "yes")
			|| !strcmp(v->val, "YES")
			|| !strcmp(v->val, "t")
			|| !strcmp(v->val, "T")
			|| !strcmp(v->val, "true")
			|| !strcmp(v->val, "TRUE"))
		return true;

	return false;
}

float CConfigStorage::GetFloatValue(char *name, float def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		strcpy(v->name, name);
		sprintf(v->val, "%3.5f", def);
		values->push_back(v);
		return def;
	}

	return atof(v->val);
}

int CConfigStorage::GetIntValue(char *name, int def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		strcpy(v->name, name);
		sprintf(v->val, "%d", def);
		values->push_back(v);
		return def;
	}

	return atoi(v->val);
}

void CConfigStorage::GetStringValue(char *name, char *value, int numChars, char *def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		strcpy(v->name, name);
		sprintf(v->val, "%s", def);
		values->push_back(v);
		strcpy(value, def);
		return;
	}

	// TODO: snprintf with numChars !
	strcpy(value, v->val);
	return;
}

void CConfigStorage::SetBoolValue(char *name, bool def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		sprintf(v->name, "%s", name);
		if (def == true)
		{
			sprintf(v->val, "true");
		}
		else
		{
			sprintf(v->val, "false");
		}
		values->push_back(v);
		return;
	}
	else
	{
		if (def == true)
		{
			sprintf(v->val, "true");
		}
		else
		{
			sprintf(v->val, "false");
		}
	}
}

void CConfigStorage::SetFloatValue(char *name, float def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		strcpy(v->name, name);
		sprintf(v->val, "%3.5f", def);
		values->push_back(v);
	}
	else
	{
		strcpy(v->name, name);
		sprintf(v->val, "%3.5f", def);
	}
}

void CConfigStorage::SetIntValue(char *name, int def)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		strcpy(v->name, name);
		sprintf(v->val, "%d", def);
		values->push_back(v);
	}
	else
	{
		strcpy(v->name, name);
		sprintf(v->val, "%d", def);
	}
}

void CConfigStorage::SetStringValue(char *name, char *value, int numChars)
{
	CConfigValue *v = GetConfigValue(name);
	if (v == NULL)
	{
		v = new CConfigValue();
		strcpy(v->name, name);
		sprintf(v->val, "%s", value);
		values->push_back(v);
	}
	else
	{
		strcpy(v->name, name);
		sprintf(v->val, "%s", value);
	}
}


bool compare_CConfigValue_nocase (CConfigValue *first, CConfigValue *second)
{
	int ret = strcmp(first->name, second->name);
	return ret < 0;
}


void CConfigStorage::DumpToFile(char *filePath)
{
	LOGM("CConfigReader::DumpToFile: %s", filePath);
	char buf[512];
	sprintf(buf, "%s%s", gCPathToDocuments, filePath);
	FixFileNameSlashes(buf);

	FILE *fp = fopen(buf, "wb");
	if (!fp)
	{
		LOGError("CConfigReader::DumpToFile: %s not opened", buf);
		return;
	}

	std::sort(values->begin(), values->end(), compare_CConfigValue_nocase);

	for (std::vector<CConfigValue *>::iterator it = this->values->begin();
				it != this->values->end(); it++)
	{
		CConfigValue *v = *it;
		fprintf(fp, "%s=%s\n", v->name, v->val);
	}
	fclose(fp);

	LOGM("CConfigReader::DumpToFile: stored to '%s'", buf);
}

void CConfigStorage::DumpToLog()
{
	LOGM("============ dumping %s config ============", this->fileName);

	std::sort(values->begin(), values->end(), compare_CConfigValue_nocase);

	for (std::vector<CConfigValue *>::iterator it = this->values->begin();
		 it != this->values->end(); it++)
	{
		CConfigValue *v = *it;
		LOGM("%s=%s", v->name, v->val);
	}

	LOGM("============ finished %s config ============", this->fileName);
}

CConfigStorage::~CConfigStorage()
{
	//LOGD("~CConfigStorage");
	while(!this->values->empty())
	{
		CConfigValue *b = this->values->front();
		this->values->erase(this->values->begin());
		delete b;
	}

	delete this->values;
	//LOGD("~CConfigStorage done");
}

