/*
 *  SYS_CFileSystem.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifdef WIN32
#include <windows.h>
#endif

#include "SYS_CFileSystem.h"
#include "SYS_Startup.h"
#ifndef WIN32
#include "TargetConditionals.h"
#endif
#include <stdio.h>
#include <tchar.h>
#include <strsafe.h>
#include <algorithm>
#include <functional>
#include <Shlobj.h>

#include "SYS_Startup.h"
#include "SYS_DocsVsRes.h"
#include "VID_GLViewController.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <io.h>

#include "mman.h"

#include "CGuiMain.h"

std::list<CHttpFileUploadedCallback *> httpFileUploadedCallbacks;

CFileSystem *gFileSystem;
UTFString *gPathToDocuments;
char *gCPathToDocuments;
CSlrString *gUTFPathToDocuments;

UTFString *gPathToResources;

UTFString *gPathToTemp;
char *gCPathToTemp;
CSlrString *gUTFPathToTemp;

UTFString *gPathToSettings;
char *gCPathToSettings;
CSlrString *gUTFPathToSettings;

UTFString *gPathToCurrentDirectory;
char *gCPathToCurrentDirectory;
CSlrString *gUTFPathToCurrentDirectory;

bool sysInitFileSystemDone = false;

void SYS_InitFileSystem()
{
	if (sysInitFileSystemDone == true)
		return;

	sysInitFileSystemDone = true;

	LOGM("SYS_InitFileSystem\n");

	TCHAR curDir[MAX_PATH];
	DWORD dwRet;

	dwRet = GetCurrentDirectory(MAX_PATH, curDir);

	LOGD("curDir='%s'", curDir);

	gPathToCurrentDirectory = new char[MAX_PATH];
	strcpy(gPathToCurrentDirectory, curDir);
	gCPathToCurrentDirectory = gPathToCurrentDirectory;
	gUTFPathToCurrentDirectory = new CSlrString(gCPathToCurrentDirectory);

	gPathToResources = new char[MAX_PATH];
	sprintf(gPathToResources, "%s\\Resources\\", curDir);
	LOGM("pathToResource=%s", gPathToResources);

	gPathToDocuments = new char[MAX_PATH];
	sprintf(gPathToDocuments, "%s\\Documents\\", curDir);
	LOGM("pathToDocuments=%s", gPathToDocuments);
	gCPathToDocuments = gPathToDocuments;
	gUTFPathToDocuments = new CSlrString(gCPathToDocuments);

	gPathToTemp = new char[MAX_PATH];
	sprintf(gPathToTemp, "%s\\Temp\\", curDir);
	LOGM("gPathToTemp=%s", gPathToTemp);
	gCPathToTemp = gPathToTemp;
	gUTFPathToTemp = new CSlrString(gCPathToTemp);

	gPathToSettings = new char[MAX_PATH];
	if (!SUCCEEDED(SHGetFolderPath(NULL, CSIDL_COMMON_APPDATA, NULL, 0, gPathToSettings)))
	{
		LOGError("failed to get app setings folder");
		sprintf(gPathToSettings, "%s\\", curDir);
	}
	else
	{
		strcat(gPathToSettings, "\\C64Debugger");

		// check if folder exists & create new if needed
		DWORD dwAttrib = GetFileAttributes(gPathToSettings);
		if (dwAttrib == INVALID_FILE_ATTRIBUTES)
		{
			if (!CreateDirectory(gPathToSettings, NULL))
			{
				LOGError("failed to create app setings folder");
				sprintf(gPathToSettings, "%s\\", curDir);
			}
		}
		strcat(gPathToSettings, "\\");
	}

	LOGM("pathToSettings=%s", gPathToSettings);

	gCPathToSettings = gPathToSettings;
	gUTFPathToSettings = new CSlrString(gCPathToSettings);

	gFileSystem = new CFileSystem();
}

CFileItem::CFileItem(UTFString *name, UTFString *modDate, bool isDir)
{
	this->name = name;
	this->modDate = modDate;
	this->isDir = isDir;
}

CFileItem::~CFileItem()
{
	delete this->name;
	delete this->modDate;
}

CFileSystem::CFileSystem()
{
	this->dataLen = 0;
	this->data = NULL;
	this->fileHandle = NULL;
	this->fileNameNoExt = NULL;
	this->tempPath = NULL;
	this->fullPath = NULL;
	this->fileSize = 0;
}

CFileSystem::~CFileSystem()
{
}

void CFileSystem::CleanTempStorage()
{
	// delete all files in temp storage:
	/* TODO:
	 You should call contentsOfDirectoryAtPath on the directory in question, and then use removeItemAtPath on all of the paths it returns.

	 NSFileManager *deleteMgr = [NSFileManager defaultManager];
	 NSString *path = @"~/test/";
	 [deleteMgr removeItemAtPath:path error:&error];
	 */
}

bool CFileSystem::OpenResourceForRead(UTFString *fileName) //, UTFString *extension)
{
	LOGR("CFileSystem::OpenResourceForRead: '%s'", fileName);
	char filePath[4096];

#if defined(USE_DOCS_INSTEAD_OF_RESOURCES)
	sprintf(filePath, "%s%s", gPathToDocuments, fileName);
#else
	sprintf(filePath, "%s%s", gPathToResources, fileName);
#endif
	LOGD("CFileSystem::OpenResourceForRead: filePath='%s'", filePath); 

	LOGD("CFileSystem::OpenResourceForRead: filePath='%s'", filePath);
	this->fileHandle = fopen(filePath, "rb");

	if (this->fileHandle == NULL)
		return false;

	fseek(this->fileHandle, 0, SEEK_END);
	this->fileSize = ftell(this->fileHandle);
	fseek(this->fileHandle, 0, SEEK_SET);

	dataLen = fileSize;
	data = (byte*)malloc(dataLen);
	fread(data, 1, fileSize, this->fileHandle);
	filePos = 0;

	return true;
}

bool CFileSystem::OpenForRead(UTFString *fileName)
{
	if (data != NULL)
	{
		LOGError("OpenForRead: file not closed");
		this->Close();
	}

	UTFString *path = fileName; //[gPathToDocuments stringByAppendingPathComponent:fileName];
	LOGR("CFileSystem::OpenForRead: path=");
	LOGR(path);

	if (this->fileHandle != NULL)
	{
		LOGError("CFileSystem::OpenForRead: file not closed");
		LOGError(fileName);
		this->Close();
	}

	this->data = NULL;
	this->fileHandle = fopen(fileName, "rb");
	filePos = 0;

	return true;
}

bool CFileSystem::ReadAllToBuffer(UTFString *fileName)
{
	if (this->data != NULL)
		free(this->data);

	this->fileHandle = fopen(fileName, "rb");

	if (this->fileHandle == NULL)
		return false;

	fseek(this->fileHandle, 0, SEEK_END);
	this->fileSize = ftell(this->fileHandle);
	fseek(this->fileHandle, 0, SEEK_SET);

	dataLen = fileSize;
	data = (byte*)malloc(dataLen);
	fread(data, 1, fileSize, this->fileHandle);
	filePos = 0;

	return true;
}

void CFileSystem::Seek(unsigned int newFilePos)
{
	fseek(this->fileHandle, newFilePos, SEEK_SET);
	this->filePos = newFilePos;
}

bool CFileSystem::OpenForWrite(UTFString *fileName)
{
	LOGR("CFileSystem::OpenForWrite:");
	LOGR(fileName);

	if (data != NULL)
	{
		LOGError("OpenForWrite: file not closed");
		this->Close();
	}

	UTFString *path = fileName; //[gPathToDocuments stringByAppendingPathComponent:fileName];
	LOGR("CFileSystem::OpenForWrite: path=");
	LOGR(path);

	if (this->fileHandle != NULL)
	{
		LOGError("CFileSystem::OpenForWrite: file not closed");
		LOGError(fileName);
		this->Close();
	}

	this->data = NULL;
	this->fileHandle = fopen(fileName, "wb");
	filePos = 0;

	return true;
}

bool CFileSystem::InitInTempStorage(UTFString *fileName, int fileId)
{
	if (this->fileNameNoExt != NULL)
	{
		free(this->fileNameNoExt);
	}

	if (this->fullPath != NULL)
	{
		free(this->fullPath);
	}

	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}

	if (this->data != NULL)
	{
		LOGError("CFileSystem::InitInTempStorage: data != NULL");
		free(this->data);
	}

	this->fullPath = strdup(fileName);

	char buf[4096];
	strcpy(buf, fileName);

	for (int i = strlen(buf)-1; i > 0; i--)
	{
		if (buf[i] == '.')
		{
			buf[i] = '\0';
			break;
		}
	}
	this->fileNameNoExt = strdup(buf);

	sprintf(buf, "%s%08d", gPathToTemp, fileId);
	this->tempPath = strdup(buf);

	// copy file
	FILE *fp = fopen(fullPath, "rb");

	if (fp == NULL)
		return false;

	fseek(fp, 0, SEEK_END);
	this->fileSize = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	this->dataLen = fileSize;
	this->data = (byte*)malloc(fileSize);
	fread(data, 1, fileSize, fp);
	filePos = 0;

	fclose(fp);

	fp = fopen(tempPath, "wb");
	if (fp == NULL)
		return false;

	fwrite(data, 1, fileSize, fp);
	fclose(fp);

	this->fileHandle = fopen(tempPath, "rb");

	if (this->fileHandle == NULL)
		return false;

	fseek(this->fileHandle, 0, SEEK_END);
	this->fileSize = ftell(this->fileHandle);
	fseek(this->fileHandle, 0, SEEK_SET);

	return true;
}

bool CFileSystem::OpenForReadFromTempStorage(int fileId)
{
	LOGD("CFileSystem::OpenForReadFromTempStorage");
	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}

	char buf[4096];
	sprintf(buf, "%s/%08d", gPathToTemp, fileId);
	tempPath = strdup(buf);

	LOGD(this->tempPath);

	this->fileHandle = fopen(this->tempPath, "rb");

	if (this->fileHandle == NULL)
		return false;

	fseek(this->fileHandle, 0, SEEK_END);
	this->fileSize = ftell(this->fileHandle);
	fseek(this->fileHandle, 0, SEEK_SET);

	return true;
}

bool CFileSystem::OpenForWriteFromTempStorage(int fileId)
{
	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}
	char buf[4096];
	sprintf(buf, "%s/%08d", gPathToTemp, fileId);
	tempPath = strdup(buf);

	this->fileHandle = fopen(this->tempPath, "wb");

	if (this->fileHandle)
		return true;

	return false;
}

bool CFileSystem::OpenForWriteInTempStorage(char *fileName)
{
	LOGR("CFileSystem::OpenForWriteInTempStorage: '%s'", fileName);

	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}
	char buf[4096];
	sprintf(buf, "%s/%s", gPathToTemp, fileName);
	tempPath = strdup(buf);

	this->fileHandle = fopen(this->tempPath, "wb");
	this->filePos = 0;

	if (this->fileHandle)
		return true;

	return false;
}

bool CFileSystem::OpenForReadInTempStorage(char *fileName)
{
	LOGR("CFileSystem::OpenForReadInTempStorage: '%s'", fileName);

	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}
	char buf[4096];
	sprintf(buf, "%s/%s", gPathToTemp, fileName);
	tempPath = strdup(buf);

	this->fileHandle = fopen(this->tempPath, "rb");
	this->filePos = 0;

	if (this->fileHandle)
		return true;

	return false;
}

bool CFileSystem::OpenForWriteInDocuments(char *fileName, bool appendPath)
{
	LOGR("CFileSystem::OpenForWriteInDocuments: '%s'", fileName);

	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}
	char buf[4096];
	if (appendPath == true)
	{
		sprintf(buf, "%s/%s", gPathToDocuments, fileName);
	}
	else
	{
		sprintf(buf, "%s", fileName);
	}
	tempPath = strdup(buf);

	this->fileHandle = fopen(this->tempPath, "wb");
	this->filePos = 0;

	if (this->fileHandle)
		return true;

	return false;
}

bool CFileSystem::OpenForReadInDocuments(char *fileName)
{
	LOGR("CFileSystem::OpenForReadInDocuments: '%s'", fileName);

	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}
	char buf[4096];
	sprintf(buf, "%s/%s", gPathToDocuments, fileName);
	tempPath = strdup(buf);

	this->fileHandle = fopen(this->tempPath, "rb");
	this->filePos = 0;

	if (this->fileHandle)
		return true;

	return false;
}

void CFileSystem::Close()
{
	//LOGR("CFileSystem::Close()");
	if (this->data != NULL)
		free(this->data);

	this->dataLen = 0;
	this->data = NULL;

	if (this->fileNameNoExt != NULL)
	{
		free(this->fileNameNoExt);
	}

	if (this->fullPath != NULL)
	{
		free(this->fullPath);
	}

	if (this->tempPath != NULL)
	{
		free(this->tempPath);
	}

	this->fileNameNoExt = NULL;
	this->fullPath = NULL;
	this->tempPath = NULL;

	if (this->fileHandle != NULL)
	{
		fclose(this->fileHandle);
		this->fileHandle = NULL;
	}
}

bool CFileSystem::WriteBytes(byte *buf, unsigned int numBytes)
{
	return this->Write(buf, numBytes);
}

bool CFileSystem::Write(byte *buf, unsigned int numBytes)
{
	//size_t fwrite ( const void * ptr, size_t size, size_t count, FILE * stream );
	if (fwrite(buf, 1, numBytes, this->fileHandle) == numBytes)
	{
		filePos += numBytes;
		//LOGF("Write: bytes written\n");
		return true;
	}

	LOGError("Write: error\n");
	return false;
}

bool CFileSystem::WriteByte(byte val)
{
	return Write(&val, 1);
}

bool CFileSystem::WriteInt(int val)
{
	void *valI = &val;
	unsigned *valI2 = ((unsigned int *)valI);
	unsigned int valI3 = *valI2;

	byte buf[4];

	buf[0] =  valI3 & 0x000000FF;
	buf[1] = (valI3 & 0x0000FF00) >> 8;
	buf[2] = (valI3 & 0x00FF0000) >> 16;
	buf[3] = (valI3 & 0xFF000000) >> 24;

	return Write(buf, 4);
}

int CFileSystem::ReadInt()
{
	byte buf[4];
	Read(buf, 4);
	return buf[0] | (buf[1] << 8) | (buf[2] << 16) | (buf[3] << 24);
}

bool CFileSystem::WriteUInt(unsigned int val)
{
	byte buf[4];

	buf[0] =  val & 0x000000FF;
	buf[1] = (val & 0x0000FF00) >> 8;
	buf[2] = (val & 0x00FF0000) >> 16;
	buf[3] = (val & 0xFF000000) >> 24;

	return Write(buf, 4);
}

void CFileSystem::WriteFloat(float val)
{
	byte *temp = ( byte* ) &val;
	for( int i = 0; i < 4; i++ )
	{
		WriteByte(*temp);
		temp++;
	}
}

float CFileSystem::ReadFloat()
{
	byte temp[4];
	for (int i = 0; i < 4; i++)
	{
		temp[i] = ReadByte();
	}

	float *val = (float*)temp;
	float val2 = *val;
	return val2;
}

void CFileSystem::WriteLong(long long val)
{
	WriteByte((byte)((val >> 56) & 0x00000000000000FFL));
	WriteByte((byte)((val >> 48) & 0x00000000000000FFL));
	WriteByte((byte)((val >> 40) & 0x00000000000000FFL));
	WriteByte((byte)((val >> 32) & 0x00000000000000FFL));
	WriteByte((byte)((val >> 24) & 0x00000000000000FFL));
	WriteByte((byte)((val >> 16) & 0x00000000000000FFL));
	WriteByte((byte)((val >> 8 ) & 0x00000000000000FFL));
	WriteByte((byte)((val      ) & 0x00000000000000FFL));
}

long long CFileSystem::ReadLong()
{
	long long l = this->ReadInt() & 0x00000000FFFFFFFFL;
	l = ((l << 32)) | (this->ReadInt() & 0x00000000FFFFFFFFL);
	return l;
}

/*bool CFileSystem::WriteShortInt(int val)
 {
 byte buf[2];

 buf[0] = val & 0x00FF;
 buf[1] = (val & 0xFF00) >> 8;
 return Write(buf, 2);
 }*/


bool CFileSystem::WriteShortUInt(unsigned int val)
{
	byte buf[2];

	buf[0] = val & 0x00FF;
	buf[1] = (val & 0xFF00) >> 8;
	return Write(buf, 2);
}

bool CFileSystem::Read(byte *buf, unsigned int numBytes)
{
	//size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );.
	fread(buf, 1, numBytes, this->fileHandle);
	filePos += numBytes;

	return true;
}

bool CFileSystem::ReadBytes(byte *buf, unsigned int numBytes)
{
	return Read(buf, numBytes);
}

/* szybsze?
 byte CFileSystem::ReadByte()
 {
 byte b;

 Read(&b, 1);
 return b;
 }
 */
byte CFileSystem::ReadByte()
{
	char c;
	fread(&c, 1, 1, this->fileHandle);

	return c;
}

unsigned int CFileSystem::ReadUInt()
{
	byte buf[4];
	Read(buf, 4);
	return buf[0] | (buf[1] << 8) | (buf[2] << 16) | (buf[3] << 24);
}

bool CFileSystem::ReadSignedShorts(signed short *buf, unsigned int numSamples)
{
	fread((unsigned char*)buf, 2, numSamples, this->fileHandle);	//sizeof(signed short)
	filePos += numSamples*2;

	return true;
}

bool CFileSystem::WriteSignedShorts(signed short *buf, unsigned int numSamples)
{
	if (fwrite((unsigned char*)buf, 2, numSamples, this->fileHandle) == numSamples*2)
	{
		filePos += numSamples*2;
		//LOGF("Write: bytes written\n");
		return true;
	}

	LOGError("WriteSignedShorts: error\n");
	return false;
}

bool CFileSystem::ReadSignedShorts(signed short *buf, unsigned int sampleStartPos, unsigned int sampleEndPos)
{
	unsigned int startPos = (sampleStartPos << 1);
	unsigned int endPos = (sampleEndPos << 1);

	if (endPos  >= this->fileSize)
	{
		SYS_FatalExit("CFileSystem::ReadSignedShorts: outside file startPos=%d endPos=%d", startPos, endPos);
		return false;
	}

	this->Seek(startPos);
	int len = sampleEndPos - sampleStartPos;

	fread(buf, 2, len, this->fileHandle);
	filePos += len*2;

	return true;
}

bool CFileSystem::WriteSignedShorts(signed short *buf, unsigned int sampleStartPos, unsigned int sampleEndPos)
{
	unsigned int startPos = (sampleStartPos << 1);
	unsigned int endPos = (sampleEndPos << 1);

	if (endPos >= this->fileSize)
	{
		SYS_FatalExit("CFileSystem::ReadSignedShorts: outside file startPos=%d endPos=%d", startPos, endPos);
		return false;
	}

	this->Seek(startPos);
	int len = sampleStartPos - sampleEndPos;

	if (fwrite(buf, 2, len, this->fileHandle) == len*2)
	{
		filePos += len*2;
		//LOGF("Write: bytes written\n");
		return true;
	}

	LOGError("WriteSignedShorts: error\n");
	return false;
}

void CFileSystem::WriteBool(bool val)
{
	if (val == true)
	{
		this->WriteByte(0xFF);
	}
	else
	{
		this->WriteByte(0x00);
	}
}

bool CFileSystem::ReadBool()
{
	byte b = ReadByte();
	if (b == 0xFF)
		return true;
	return false;
}


// comparison, not case sensitive.
bool compare_CFileItem_nocase (CFileItem *first, CFileItem *second)
{
	if (first->isDir == second->isDir)
	{
		unsigned int i=0;
		u32 l1 = strlen(first->name);
		u32 l2 = strlen(second->name);
		while ( (i < l1) && ( i < l2) )
		{
			if (tolower(first->name[i]) < tolower(second->name[i]))
			{
				return true;
			}
			else if (tolower(first->name[i]) > tolower(second->name[i]))
			{
				return false;
			}
			++i;
		}

		if (l1 < l2)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	if (first->isDir)
		return true;

	return false;
}

std::vector<CFileItem *> *CFileSystem::GetFiles(UTFString *directoryPath, std::list<UTFString *> *extensions)
{
	LOGD("CFileSystem::GetFiles: %s", directoryPath);
	std::vector<CFileItem *> *files = new std::vector<CFileItem *>();

	WIN32_FIND_DATA ffd;
	LARGE_INTEGER filesize;
	TCHAR szDir[MAX_PATH];
	size_t length_of_arg;
	HANDLE hFind = INVALID_HANDLE_VALUE;
	DWORD dwError =0;

	StringCchLength(directoryPath, MAX_PATH, &length_of_arg);
	if (length_of_arg > (MAX_PATH-3))
	{
		SYS_FatalExit("CFileSystem::GetFiles: directoryPath too long");
	}

	StringCchCopy(szDir, MAX_PATH, directoryPath);
	StringCchCat(szDir, MAX_PATH, TEXT("\\*"));

	hFind = FindFirstFile(szDir, &ffd);

	if (hFind == INVALID_HANDLE_VALUE)
	{
		SYS_FatalExit("CFileSystem::GetFiles: FindFirstFile");
	}

	do
	{
		if (ffd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		{
			LOGD("<DIR> %s", ffd.cFileName);

			if (!strcmp(ffd.cFileName, ".") || !strcmp(ffd.cFileName, ".."))
			{
			}
			else
			{
				UTFString *fileNameDup = strdup(ffd.cFileName);
				UTFString *modDateDup = strdup("");

				CFileItem *item = new CFileItem(fileNameDup, modDateDup, true);
				files->push_back(item);
			}
		}
		else
		{
			char *fileExtension = this->GetExtension(ffd.cFileName);

			if (fileExtension != NULL)
			{
				for (std::list<UTFString *>::iterator itExtensions = extensions->begin();
					 itExtensions !=  extensions->end(); itExtensions++)
				{
					UTFString *extension = *itExtensions;

					//LOGD("fileExtension='%s' extension='%s'", fileExtension, extension);
					if (!strcmp(extension, fileExtension))
					{
						//LOGD("adding");
						//LOGD(fname);

						filesize.LowPart = ffd.nFileSizeLow;
						filesize.HighPart = ffd.nFileSizeHigh;
						LOGD("     %s %ld", ffd.cFileName, filesize.QuadPart);

						UTFString *fileNameDup = strdup(ffd.cFileName);
						UTFString *modDateDup = strdup("");

						CFileItem *item = new CFileItem(fileNameDup, modDateDup, false);
						files->push_back(item);
						break;
					}
				}
				free(fileExtension);
			}
		}
	}
	while(FindNextFile(hFind, &ffd) != 0);

	dwError = GetLastError();
	if (dwError != ERROR_NO_MORE_FILES)
	{
		LOGError("CFileSystem::GetFiles: FindNextFile %d", dwError);
	}

	FindClose(hFind);

	LOGD("CFileSystem::GetFiles done");

	std::sort(files->begin(), files->end(), compare_CFileItem_nocase);

	return files;
}

char *CFileSystem::GetExtension(char *fileName)
{
	int index = -1;
	for (int i = strlen(fileName)-1; i >= 0; i--)
	{
		if (fileName[i] == '.')
		{
			index = i+1;
			break;
		}
	}

	if (index == -1)
		return NULL;

	char *buf = (char*)malloc(strlen(fileName)-index+1);
	int z = 0;
	for (int i = index; i < strlen(fileName); i++)
	{
		if (fileName[i] == '/' || fileName[i] == '\\')
			break;

		buf[z] = fileName[i];
		z++;
	}
	buf[z] = 0x00;
	return buf;
}

void CFileSystem::Flush()
{
	fflush(this->fileHandle);
}

static char szFileName[MAX_PATH] = "";

char *SYS_DialogOpenAnimFile()
{
	OPENFILENAME ofn;

	ZeroMemory(&ofn, sizeof(ofn));

	ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
	ofn.hwndOwner = hWnd;
	ofn.lpstrFilter = "Anim Files (*.anim)\0*.anim\0All Files (*.*)\0*.*\0";
	ofn.lpstrFile = szFileName;
	ofn.nMaxFile = MAX_PATH;
	ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
	ofn.lpstrDefExt = "anim";

	if(GetOpenFileName(&ofn))
	{
		return szFileName;
	}
	return NULL;
}

char *SYS_DialogSaveAnimFile()
{
	OPENFILENAME ofn;

	ZeroMemory(&ofn, sizeof(ofn));

	ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
	ofn.hwndOwner = hWnd;
	ofn.lpstrFilter = "Anim Files (*.anim)\0*.anim\0All Files (*.*)\0*.*\0";
	ofn.lpstrFile = szFileName;
	ofn.nMaxFile = MAX_PATH;
	ofn.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;
	ofn.lpstrDefExt = "anim";

	if(GetSaveFileName(&ofn))
	{
		return szFileName;
	}
	return NULL;
}

char *SYS_DialogOpenElemFile()
{
	OPENFILENAME ofn;

	ZeroMemory(&ofn, sizeof(ofn));

	ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
	ofn.hwndOwner = hWnd;
	ofn.lpstrFilter = "Elem Files (*.elem)\0*.elem\0All Files (*.*)\0*.*\0";
	ofn.lpstrFile = szFileName;
	ofn.nMaxFile = MAX_PATH;
	ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
	ofn.lpstrDefExt = "elem";

	if(GetOpenFileName(&ofn))
	{
		return szFileName;
	}
	return NULL;
}

char *SYS_DialogSaveElemFile()
{
	OPENFILENAME ofn;

	ZeroMemory(&ofn, sizeof(ofn));

	ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
	ofn.hwndOwner = hWnd;
	ofn.lpstrFilter = "Elem Files (*.elem)\0*.elem\0All Files (*.*)\0*.*\0";
	ofn.lpstrFile = szFileName;
	ofn.nMaxFile = MAX_PATH;
	ofn.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;
	ofn.lpstrDefExt = "elem";

	if(GetSaveFileName(&ofn))
	{
		return szFileName;
	}
	return NULL;
}

void CHttpFileUploadedCallback::HttpFileUploadedCallback()
{
}

void SYS_RefreshFiles()
{
	for(std::list<CHttpFileUploadedCallback *>::iterator itCallback = httpFileUploadedCallbacks.begin(); itCallback != httpFileUploadedCallbacks.end(); itCallback++)
	{
		CHttpFileUploadedCallback *callback = *itCallback;
		callback->HttpFileUploadedCallback();
	}
}

void GUI_KeyUpAllModifiers()
{
	guiMain->isShiftPressed = false;
	guiMain->isControlPressed = false;
	guiMain->isAltPressed = false;

	guiMain->isLeftShiftPressed = false;
	guiMain->isLeftControlPressed = false;
	guiMain->isLeftAltPressed = false;

	guiMain->isRightShiftPressed = false;
	guiMain->isRightControlPressed = false;
	guiMain->isRightAltPressed = false;

}

bool SYS_windowAlwaysOnTopBeforeFileDialog = false;

void SYS_DialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions, CSlrString *defaultFolder, CSlrString *windowTitle)
{
	LOGD("SYS_DialogOpenFile");

	OPENFILENAME ofn;
    char szFileName[MAX_PATH] = "";

	// temporary remove always on top window flag
	SYS_windowAlwaysOnTopBeforeFileDialog = VID_IsWindowAlwaysOnTop();
	//VID_SetWindowAlwaysOnTopTemporary(false);

    ZeroMemory(&ofn, sizeof(ofn));

    ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
    ofn.hwndOwner = hWnd;

	char *initialFolder = NULL;

	char *buf = SYS_GetCharBuf();
	char *ext = NULL;

	if (extensions != NULL)
	{
		char *filterExtAll = new char[1024];
		filterExtAll[0] = 0x00;

		char *filterExtSingle = new char[1024];
		filterExtSingle[0] = 0x00;
		
		for (std::list<CSlrString *>::iterator it = extensions->begin();
			it != extensions->end(); it++)
		{
			CSlrString *extStr = *it;
			ext = extStr->GetStdASCII();

			char extBuf[128];
			if (it == extensions->begin())
			{
				sprintf(extBuf, "*.%s", ext);
			}
			else
			{
				sprintf(extBuf, ";*.%s", ext);
			}
			strcat(filterExtAll, extBuf);

			sprintf(extBuf, "Only %s files$*.%s$", ext, ext);
			strcat(filterExtSingle, extBuf);

			free(ext); ext = NULL;
		}
		
		if (extensions->size() == 1)
		{
			sprintf(buf, "Supported files$%s$All Files(*.*)$*.*$", filterExtAll);
		}
		else
		{
			sprintf(buf, "Supported files$%s$%sAll Files(*.*)$*.*$", filterExtAll, filterExtSingle);
		}

		delete [] filterExtAll;
		delete [] filterExtSingle;

		int z = strlen(buf);
		for (int i = 0; i < z; i++)
		{
			if (buf[i] == '$')
				buf[i] = '\0';
		}

		ofn.lpstrFilter = buf;
	    ofn.lpstrDefExt = NULL;
	}

	char *title = NULL;

	if (windowTitle != NULL)
	{
		title = windowTitle->GetStdASCII();
		ofn.lpstrTitle = title;
	}

    ofn.lpstrFile = szFileName;

	if (defaultFolder != NULL)
	{
		initialFolder = defaultFolder->GetStdASCII();
		ofn.lpstrInitialDir = initialFolder;

		LOGD(">> set ofn.lpstrInitialDir='%s'", initialFolder);
	}
	else
	{
		LOGD(">> defaultFolder is NULL");
	}

    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
    
    // workaround
    GUI_KeyUpAllModifiers();
    
    LOGD("...... GetOpenFileName");
    if(GetOpenFileName(&ofn))
    {
    	LOGD("..... callback: file open selected");
		VID_SetWindowAlwaysOnTopTemporary(SYS_windowAlwaysOnTopBeforeFileDialog);

		if (title != NULL)
			free(title);

		LOGD("szFileName='%s'", szFileName);
		SYS_ReleaseCharBuf(buf);
		CSlrString *outPath = new CSlrString(szFileName);
		callback->SystemDialogFileOpenSelected(outPath);
		if (initialFolder != NULL)
			delete initialFolder;
	}
	else
	{
		LOGD("..... callback: file open cancelled");
		VID_SetWindowAlwaysOnTopTemporary(SYS_windowAlwaysOnTopBeforeFileDialog);

		if (title != NULL)
			free(title);
		SYS_ReleaseCharBuf(buf);
		callback->SystemDialogFileOpenCancelled();
	}
}

void SYS_DialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions, CSlrString *defaultFileName, CSlrString *defaultFolder, CSlrString *windowTitle)
{
	OPENFILENAME ofn;
    char szFileName[MAX_PATH] = "";

	// temporary remove always on top window flag
	SYS_windowAlwaysOnTopBeforeFileDialog = VID_IsWindowAlwaysOnTop();
	//VID_SetWindowAlwaysOnTopTemporary(false);

    ZeroMemory(&ofn, sizeof(ofn));

    ofn.lStructSize = sizeof(ofn); // SEE NOTE BELOW
    ofn.hwndOwner = hWnd;

	char *initialFolder = NULL;
	char *buf = SYS_GetCharBuf();
	char *ext = NULL;
	char defExt[16];

	if (extensions != NULL)
	{
		char *filterExtAll = new char[1024];
		filterExtAll[0] = 0x00;

		char *filterExtSingle = new char[1024];
		filterExtSingle[0] = 0x00;
		
		for (std::list<CSlrString *>::iterator it = extensions->begin();
			it != extensions->end(); it++)
		{
			CSlrString *extStr = *it;
			ext = extStr->GetStdASCII();

			char extBuf[128];
			if (it == extensions->begin())
			{
				sprintf(extBuf, "*.%s", ext);
				strcpy(defExt, ext);
			}
			else
			{
				sprintf(extBuf, ";*.%s", ext);
			}
			strcat(filterExtAll, extBuf);

			sprintf(extBuf, "Only %s files$*.%s$", ext, ext);
			strcat(filterExtSingle, extBuf);

			free(ext); ext = NULL;
		}
		
		if (extensions->size() == 1)
		{
			sprintf(buf, "%s file$%s$All Files(*.*)$*.*$", defExt, filterExtAll);
		}
		else
		{
			sprintf(buf, "Supported files$%s$%sAll Files(*.*)$*.*$", filterExtAll, filterExtSingle);
		}

		delete [] filterExtAll;
		delete [] filterExtSingle;

		int z = strlen(buf);
		for (int i = 0; i < z; i++)
		{
			if (buf[i] == '$')
				buf[i] = '\0';
		}

		ofn.lpstrFilter = buf;
	    ofn.lpstrDefExt = defExt;
	}

	char *title = NULL;

	if (windowTitle != NULL)
	{
		title = windowTitle->GetStdASCII();
		ofn.lpstrTitle = title;
	}

    ofn.lpstrFile = szFileName;
	if (defaultFolder != NULL)
	{
		initialFolder = defaultFolder->GetStdASCII();
		ofn.lpstrInitialDir = initialFolder;
	}
    ofn.nMaxFile = MAX_PATH;
	ofn.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;
	
	
	// workaround
	GUI_KeyUpAllModifiers();
	
	LOGD("....... GetSaveFileName");
    if(GetSaveFileName(&ofn))
    {
    	LOGD("     ...callback OK");
		VID_SetWindowAlwaysOnTopTemporary(SYS_windowAlwaysOnTopBeforeFileDialog);

		if (title != NULL)
			free(title);

		LOGD("szFileName='%s'", szFileName);
		SYS_ReleaseCharBuf(buf);
		CSlrString *outPath = new CSlrString(szFileName);
		callback->SystemDialogFileSaveSelected(outPath);

		if (initialFolder != NULL)
			delete initialFolder;
	}
	else
	{
		LOGD("    ...callback cancelled");
		VID_SetWindowAlwaysOnTopTemporary(SYS_windowAlwaysOnTopBeforeFileDialog);

		if (title != NULL)
			free(title);

		SYS_ReleaseCharBuf(buf);
		callback->SystemDialogFileSaveCancelled();
	}
}


void CSystemFileDialogCallback::SystemDialogFileOpenSelected(CSlrString *path)
{
}

void CSystemFileDialogCallback::SystemDialogFileOpenCancelled()
{
}

void CSystemFileDialogCallback::SystemDialogFileSaveSelected(CSlrString *path)
{
}

void CSystemFileDialogCallback::SystemDialogFileSaveCancelled()
{
}

bool SYS_FileExists(char *cPath)
{
	struct stat info;

	LOGD("SYS_FileExists, cPath='%s'", cPath);
	
	if(stat( cPath, &info ) != 0)
	{
		LOGD("..false");
		return false;
	}
	else 
	{
		LOGD("..true");
		return true;
	}
}

bool SYS_FileExists(CSlrString *path)
{
	char *cPath = path->GetStdASCII();
	
	struct stat info;
	
	if(stat( cPath, &info ) != 0)
	{
		delete [] cPath;
		return false;
	}
	else 
	{
		delete [] cPath;
		return true;
	}
}

bool SYS_FileDirExists(char *cPath)
{
	struct stat info;
	
	if(stat( cPath, &info ) != 0)
		return false;
	else if(info.st_mode & S_IFDIR)
		return true;
	else
		return false;
}

bool SYS_FileDirExists(CSlrString *path)
{
	char *cPath = path->GetStdASCII();
	
	struct stat info;
	
	if(stat( cPath, &info ) != 0)
		return false;
	else if(info.st_mode & S_IFDIR)
		return true;
	else
		return false;
	
	delete [] cPath;
}

uint8 *SYS_MapMemoryToFile(int memorySize, char *filePath, void **fileDescriptor)
{
	int *fileHandle = (int*)malloc(sizeof(int));
	fileDescriptor = (void**)(&fileHandle);
	
	*fileHandle = open(filePath, O_RDWR | O_CREAT | O_TRUNC, _S_IREAD | S_IWRITE);
	
	if(*fileHandle == -1)
	{
		LOGError("SYS_MapMemoryToFile: error opening file for writing, path=%s", filePath);
		return NULL;
	}
	
	if(lseek(*fileHandle, memorySize - 1, SEEK_SET) == -1)
	{
		LOGError("SYS_MapMemoryToFile: error in seeking the file, path=%s", filePath);
		return NULL;
	}
	
	if(write(*fileHandle, "", 1) != 1)
	{
		LOGError("SYS_MapMemoryToFile: error in writing the file, path=%s", filePath);
		return NULL;
	}
	
	uint8 *memoryMap = (uint8*)mmap(0, memorySize, PROT_READ | PROT_WRITE, MAP_SHARED, *fileHandle, 0);
	
	if (memoryMap == MAP_FAILED)
	{
		close(*fileHandle);
		
		LOGError("SYS_MapMemoryToFile: error mmaping the file, path=%s", filePath);
		return NULL;
	}

	close(*fileHandle);

	return memoryMap;
}

void SYS_UnMapMemoryFromFile(uint8 *memoryMap, int memorySize, void **fileDescriptor)
{
	if (munmap(memoryMap, memorySize) == -1)
	{
		LOGError("SYS_UnMapMemoryFromFile: error unmapping the file");
		return;
	}
	
	int *fileHandle = (int*)*fileDescriptor;
	
	close(*fileHandle);
}

void SYS_SetCurrentFolder(CSlrString *path)
{
	LOGD("SYS_SetCurrentFolder");
	path->DebugPrint("SYS_SetCurrentFolder: ");
	char *cPath = path->GetStdASCII();
	SetCurrentDirectory(cPath);

	delete [] cPath;
}
