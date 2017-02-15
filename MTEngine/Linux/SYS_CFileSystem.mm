/*
 *  SYS_CFileSystem.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "SYS_CFileSystem.h"
#include "SYS_DocsVsRes.h"
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <algorithm>
#include <functional>
#include "CSlrString.h"
#include "SYS_Funct.h"

#include <gtk/gtk.h>
#include <pwd.h>
#include <sys/mman.h>


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


std::list<CHttpFileUploadedCallback *> httpFileUploadedCallbacks;

void SYS_InitFileSystem()
{
	LOGM("SYS_InitFileSystem");

	// get current folder
	gPathToCurrentDirectory = new char[PATH_MAX];
	getcwd(gPathToCurrentDirectory, PATH_MAX);

	LOGD("gPathToCurrentDirectory=%s", gPathToCurrentDirectory);

	gCPathToCurrentDirectory = gPathToCurrentDirectory;
	gUTFPathToCurrentDirectory = new CSlrString(gCPathToCurrentDirectory);

	gPathToResources = new char[256];

//#if !defined(USE_DOCS_INSTEAD_OF_RESOURCES)
//	sprintf(gPathToResources, "./Resources/");
//#else
	sprintf(gPathToResources, "./Documents/");
//#endif

	LOGF(DBGLVL_MAIN, "pathToResources=");
	LOGF(DBGLVL_MAIN, gPathToResources);



	gPathToDocuments = new char[256];
	sprintf(gPathToDocuments, "./Documents/");
	gCPathToDocuments = gPathToDocuments;
	gUTFPathToDocuments = new CSlrString(gCPathToDocuments);


	LOGF(DBGLVL_MAIN, "pathToDocuments=");
	LOGF(DBGLVL_MAIN, gPathToDocuments);

	gPathToTemp = new char[256];
//	sprintf(gPathToTemp, "./Temp/");
	sprintf(gPathToTemp, "./Documents/");
	gCPathToTemp = gPathToTemp;
	gUTFPathToTemp = new CSlrString(gCPathToTemp);
	LOGF(DBGLVL_MAIN, "gPathToTemp=");
	LOGF(DBGLVL_MAIN, gPathToTemp);

	const char *homeDir;

	if ((homeDir = getenv("HOME")) == NULL)
	{
	    homeDir = getpwuid(getuid())->pw_dir;
	}

	gPathToSettings = new char[256];
	sprintf(gPathToSettings, "%s/.C64Debugger", homeDir);
	LOGF(DBGLVL_MAIN, "pathToSettings=");
	LOGF(DBGLVL_MAIN, gPathToSettings);
	gCPathToSettings = gPathToSettings;
	gUTFPathToSettings = new CSlrString(gCPathToSettings);

	struct stat st = {0};
	if (stat(gCPathToSettings, &st) == -1)
	{
		LOGD("create settings folder: %s", gCPathToSettings);
	    int result = mkdir(gCPathToSettings, S_IRUSR | S_IWUSR | S_IXUSR);

	    LOGD("result=%d", result);
	}


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
	free(this->name);
	free(this->modDate);
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
	char filePath[4096];
	sprintf(filePath, "%s%s", gPathToResources, fileName); //, extension);

	LOGD("CFileSystem::OpenResourceForRead: '%s'", filePath);
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

void CFileSystem::Flush()
{
	fflush(this->fileHandle);
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
	if (appendPath)
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

bool CFileSystem::WriteUInt(unsigned int val)
{
	byte buf[4];

	buf[0] =  val & 0x000000FF;
	buf[1] = (val & 0x0000FF00) >> 8;
	buf[2] = (val & 0x00FF0000) >> 16;
	buf[3] = (val & 0xFF000000) >> 24;

	return Write(buf, 4);
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

int CFileSystem::ReadInt()
{
	byte buf[4];
	Read(buf, 4);
	return buf[0] | (buf[1] << 8) | (buf[2] << 16) | (buf[3] << 24);
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
	u32 len = sampleStartPos - sampleEndPos;

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
	LOGD("CFileSystem::GetFiles: directoryPath=%s", directoryPath);
	std::vector<CFileItem *> *files = new std::vector<CFileItem *>();

	DIR *dp;
    struct dirent *dirp;

    if((dp  = opendir(directoryPath)) == NULL)	//dir.c_str()
    	SYS_FatalExit("Error opening dir: %s", directoryPath);

    while((dirp = readdir(dp)) != NULL)
    {
    	if (!strcmp(dirp->d_name, "..") || !strcmp(dirp->d_name, "."))
    	{
    		continue;
    	}

    	char buf[1024];
    	sprintf(buf, "%s%s", directoryPath, dirp->d_name);
    	//LOGD("d_name=%s", buf);
    	struct stat st;
    	lstat(buf, &st);

    	if (S_ISDIR(st.st_mode))
    	{
    		//LOGD("<DIR> %s", dirp->d_name);

    		UTFString *fileNameDup = strdup(dirp->d_name);
			UTFString *modDateDup = strdup("");

			CFileItem *item = new CFileItem(fileNameDup, modDateDup, true);
			files->push_back(item);
    	}
    	else if (dirp->d_type == DT_REG || dirp->d_type == DT_UNKNOWN)
		{
			char *fileExtension = this->GetExtension(dirp->d_name);

			if (fileExtension != NULL)
			{
				for (std::list<UTFString *>::iterator itExtensions = extensions->begin();
								 itExtensions !=  extensions->end(); itExtensions++)
				{
					UTFString *extension = *itExtensions;

					if (!strcmp(extension, fileExtension))
					{
						//LOGD("adding");
						//LOGD(fname);

						//filesize.LowPart = ffd.nFileSizeLow;
						//filesize.HighPart = ffd.nFileSizeHigh;
						//LOGD("     %s %ld", ffd.cFileName, filesize.QuadPart);
						//LOGD("     %s", dirp->d_name);

						UTFString *fileNameDup = strdup(dirp->d_name);
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

    closedir(dp);

	std::sort(files->begin(), files->end(), compare_CFileItem_nocase);

	LOGD("CFileSystem::GetFiles done");

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

//GTK_FILE_CHOOSER_ACTION_OPEN
//GTK_FILE_CHOOSER_ACTION_SAVE
//GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER
//GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER:

// example code in:
// https://sourceforge.net/p/xournal/svn/200/tree/trunk/xournalpp/src/control/stockdlg/XojOpenDlg.cpp#l49

void SYS_DialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions, CSlrString *defaultFolder, CSlrString *windowTitle)
{
	GtkWidget *dialog;

	dialog = gtk_file_chooser_dialog_new("Open file", NULL, GTK_FILE_CHOOSER_ACTION_OPEN,
									  "Cancel", GTK_RESPONSE_CANCEL,
									  "Open", GTK_RESPONSE_OK,
									  NULL);

	// add extensions
	GtkFileFilter *filterAll = gtk_file_filter_new();
	gtk_file_filter_set_name(filterAll, "All files");
	gtk_file_filter_add_pattern(filterAll, "*");

	char *bufName = SYS_GetCharBuf();
	char *bufPattern = SYS_GetCharBuf();
	for (std::list<CSlrString *>::iterator it = extensions->begin(); it != extensions->end(); it++)
	{
		CSlrString *strExt = *it;
		char *p = strExt->GetStdASCII();
		
		sprintf(bufName, "%s files", p);
		sprintf(bufPattern, "*.%s", p);
		
		
		GtkFileFilter *filter = gtk_file_filter_new();
		gtk_file_filter_set_name(filter, bufName);
		gtk_file_filter_add_pattern(filter, bufPattern);

		gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);

		delete p;
	}
	SYS_ReleaseCharBuf(bufName);
	SYS_ReleaseCharBuf(bufPattern);
	
	if (defaultFolder != NULL)
	{
		char *strDefaultFolder = defaultFolder->GetStdASCII();
		gtk_file_chooser_set_current_folder_uri(GTK_FILE_CHOOSER(dialog), strDefaultFolder);
		delete [] strDefaultFolder;
	}
	
	if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_OK)
	{
		char *filePath = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
		
		gtk_widget_destroy(dialog);
		
		CSlrString *outPath = new CSlrString(filePath);
		callback->SystemDialogFileOpenSelected(outPath);
	}
	else
	{
		gtk_widget_destroy(dialog);
		
		callback->SystemDialogFileOpenCancelled();
	}

	// ohh that's nasty hack but works for me...
	for (int i = 0; i < 10; i++)
	{
		gtk_main_iteration_do(false);
		SYS_Sleep(10);
	}
}

void SYS_DialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions, CSlrString *defaultFileName, CSlrString *defaultFolder, CSlrString *windowTitle)
{
	GtkWidget *dialog;
	
	dialog = gtk_file_chooser_dialog_new("Save file", NULL, GTK_FILE_CHOOSER_ACTION_SAVE,
									  "Cancel", GTK_RESPONSE_CANCEL,
									  "Save", GTK_RESPONSE_OK,
									  NULL);
	
	
	//
	// add extensions
	GtkFileFilter *filterAll = gtk_file_filter_new();
	gtk_file_filter_set_name(filterAll, "All files");
	gtk_file_filter_add_pattern(filterAll, "*");
	
	CSlrString *defaultExtension = NULL;

	char *bufName = SYS_GetCharBuf();
	char *bufPattern = SYS_GetCharBuf();
	for (std::list<CSlrString *>::iterator it = extensions->begin(); it != extensions->end(); it++)
	{
		CSlrString *strExt = *it;

		if (defaultExtension == NULL)
			defaultExtension = strExt;

		char *p = strExt->GetStdASCII();
		
		sprintf(bufName, "%s files", p);
		sprintf(bufPattern, "*.%s", p);
		
		
		GtkFileFilter *filter = gtk_file_filter_new();
		gtk_file_filter_set_name(filter, bufName);
		gtk_file_filter_add_pattern(filter, bufPattern);
		
		gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
		
		delete p;
	}
	SYS_ReleaseCharBuf(bufName);
	SYS_ReleaseCharBuf(bufPattern);
	//
	
	if (defaultFolder != NULL)
	{
		char *strDefaultFolder = defaultFolder->GetStdASCII();
		gtk_file_chooser_set_current_folder_uri(GTK_FILE_CHOOSER(dialog), strDefaultFolder);
		delete [] strDefaultFolder;
	}
	
	if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_OK)
	{
		char *filePath = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
		
		gtk_widget_destroy(dialog);
		
		CSlrString *outPath = new CSlrString(filePath);

		// TODO: workaround gtk_dialog does not add default extension...
		if (defaultExtension != NULL)
		{
			outPath->Concatenate(".");
			outPath->Concatenate(defaultExtension);
		}

		callback->SystemDialogFileSaveSelected(outPath);
	}
	else
	{
		gtk_widget_destroy(dialog);
		
		callback->SystemDialogFileSaveCancelled();
	}

	// ohh that's nasty hack but works for me...
	for (int i = 0; i < 10; i++)
	{
		gtk_main_iteration_do(false);
		SYS_Sleep(10);
	}

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

        *fileHandle = open(filePath, O_RDWR | O_CREAT | O_TRUNC, (mode_t)0600);

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
	chdir(cPath);

	delete [] cPath;
}



