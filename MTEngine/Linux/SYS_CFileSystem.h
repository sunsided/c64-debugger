/*
 *  SYS_CFileSystem.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009. All rights reserved.
 *
 */

#ifndef __SYS_CFILESYSTEM_H__
#define __SYS_CFILESYSTEM_H__

#include "SYS_Main.h"
//#include "M_CSlrList.h"
#include <list>
#include <vector>

class CSlrString;

#define MAX_FILENAME_LENGTH 512

#define SYS_FILE_SYSTEM_PATH_SEPARATOR	'/'

void SYS_InitFileSystem();

extern UTFString *gPathToDocuments;
extern char *gCPathToDocuments;
extern UTFString *gPathToResources;
extern UTFString *gPathToTemp;
extern char *gCPathToTemp;

extern CSlrString *gUTFPathToDocuments;
extern CSlrString *gUTFPathToTemp;
extern CSlrString *gUTFPathToSettings;

class CHttpFileUploadedCallback
{
public:
	virtual void HttpFileUploadedCallback();
};

extern std::list<CHttpFileUploadedCallback *> httpFileUploadedCallbacks;

class CFileItem		//: public CSlrListElement
{
public:
	CFileItem();
	CFileItem(UTFString *name, UTFString *modDate, bool isDir);
	~CFileItem();

	UTFString *name;
	UTFString *modDate;
	bool isDir;
};

class CFileSystem
{
public:
	CFileSystem();
	~CFileSystem();

	void CleanTempStorage();

	std::vector<CFileItem *> *GetFiles(UTFString *directoryPath, std::list<UTFString *> *extensions);
	bool OpenForRead(UTFString *fileName);
	bool ReadAllToBuffer(UTFString *fileName);
	bool OpenResourceForRead(UTFString *fileName); //, UTFString *extension);
	bool OpenForWrite(UTFString *fileName);
	bool OpenForWriteInDocuments(char *fileName, bool appendPath);
	bool OpenForReadInDocuments(char *fileName);
	bool OpenForWriteInTempStorage(char *fileName);
	bool OpenForReadInTempStorage(char *fileName);
	void Close();
	bool WriteByte(byte val);
	byte ReadByte();
	bool Write(byte *buf, unsigned int numBytes);
	bool WriteBytes(byte *buf, unsigned int numBytes);
	bool WriteInt(int val);
	int ReadInt();
	bool WriteUInt(unsigned int val);
	unsigned int ReadUInt();
	bool WriteShortInt(int val);
	bool WriteShortUInt(unsigned int val);
	bool Read(byte *buf, unsigned int numBytes);
	bool ReadBytes(byte *buf, unsigned int numBytes);
	bool ReadSignedShorts(signed short *buf, unsigned int numSamples);
	bool WriteSignedShorts(signed short *buf, unsigned int numSamples);
	bool ReadSignedShorts(signed short *buf, unsigned int sampleStartPos, unsigned int sampleEndPos);
	bool WriteSignedShorts(signed short *buf, unsigned int sampleStartPos, unsigned int sampleEndPos);
	float ReadFloat();
	void WriteFloat(float val);
	void WriteLong(long long val);
	long long ReadLong();
	void WriteBool(bool val);
	bool ReadBool();
	void Flush();

	unsigned int filePos;
	unsigned int fileSize;
	bool fileOpened;

	void Seek(unsigned int newFilePos);

	unsigned char *data;
	unsigned int dataLen;

	FILE *fileHandle;

	UTFString *fileNameNoExt;
	UTFString *fullPath;
	UTFString *tempPath;

	char *GetExtension(char *fileName);

	bool InitInTempStorage(UTFString *filePath, int fileId);
	bool OpenForReadFromTempStorage(int fileId);
	bool OpenForWriteFromTempStorage(int fileId);

	//CSlrList *GetDrives();
	//CSlrList *GetDirectory(char *dirName, char *wildcard);

	//TBuf16<256> CharsToTBuf16(char *text);

	class compareFiles
	{
		// simple comparison function
	public:
		bool operator()(const CFileItem *f1, const CFileItem *f2)
		{
			if (f1->isDir && !f2->isDir)
			{
				return -1;
			}
			if (!f1->isDir && f2->isDir)
			{
				return 1;
			}

			return 0;
		}
	};

private:
	//RFs	fs;
	//RFile rfile;
};

extern CFileSystem *gFileSystem;

void SYS_RefreshFiles();

class CSystemFileDialogCallback
{
public:
        virtual void SystemDialogFileOpenSelected(CSlrString *path);
        virtual void SystemDialogFileOpenCancelled();
        virtual void SystemDialogFileSaveSelected(CSlrString *path);
        virtual void SystemDialogFileSaveCancelled();
};

void SYS_DialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions, CSlrString *defaultFolder, CSlrString *windowTitle);
void SYS_DialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions, CSlrString *defaultFileName, CSlrString *defaultFolder, CSlrString *windowTitle);

bool SYS_FileDirExists(CSlrString *path);

#endif //__SYS_CFILESYSTEM_H__
