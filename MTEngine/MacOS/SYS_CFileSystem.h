/*
 *  SYS_CFileSystem.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009 Rabidus. All rights reserved.
 *
 */

#ifndef __SYS_CFILESYSTEM_H__
#define __SYS_CFILESYSTEM_H__

#include "SYS_Main.h"
//#include "M_CSlrList.h"
#include <list>
#include <vector>

#define MAX_FILENAME_LENGTH 512

#define SYS_FILE_SYSTEM_PATH_SEPARATOR	'/'
#define SYS_FILE_SYSTEM_EXTENSION_SEPARATOR	'.'

void SYS_InitFileSystem();

class CSlrString;

extern NSString *gOSPathToDocuments;
extern char *gPathToDocuments;
extern char *gCPathToDocuments;
extern CSlrString *gUTFPathToDocuments;

extern UTFString *gPathToDesktop;
extern char *gCPathToDesktop;
extern CSlrString *gUTFPathToDesktop;

extern NSString *gOSPathToTemp;
extern char *gPathToTemp;
extern char *gCPathToTemp;
extern CSlrString *gUTFPathToTemp;

extern NSString *gOSPathToSettings;
extern char *gPathToSettings;
extern char *gCPathToSettings;
extern CSlrString *gUTFPathToSettings;

extern UTFString *gPathToCurrentDirectory;
extern char *gCPathToCurrentDirectory;
extern CSlrString *gUTFPathToCurrentDirectory;

void SYS_DeleteFile(CSlrString *filePath);

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
	CFileItem(char *name, char *modDate, bool isDir);
	~CFileItem();
	
	char *name;
	char *modDate;
	bool isDir;
};

class CFileSystem
{
public:
	CFileSystem();
	~CFileSystem();
	
	void CleanTempStorage();
	
	std::vector<CFileItem *> *GetFiles(char *directoryPath, std::list<char *> *extensions, bool withFolders);
	bool OpenForRead(char *fileName);
	bool ReadAllToBuffer(char *fileName);
	bool OpenResourceForRead(char *fileName);
	bool OpenForWrite(NSString *fileName);
	bool OpenForWriteInTempStorage(char *fileName);
	bool OpenForReadInTempStorage(char *fileName);
	bool OpenForWriteInDocuments(char *fileName, bool appendPath);
	bool OpenForReadInDocuments(char *fileName);
	void Close();
	bool Write(byte *buf, unsigned int numBytes);
	bool WriteBytes(byte *buf, unsigned int numBytes);
	bool WriteInt(int val);
	bool WriteUInt(unsigned int val);
	bool WriteByte(byte val);
	bool WriteShortInt(int val);
	bool WriteShortUInt(unsigned int val);
	bool Read(byte *buf, unsigned int numBytes);
	bool ReadBytes(byte *buf, unsigned int numBytes);
	bool ReadSignedShorts(signed short *buf, unsigned int numSamples);
	bool WriteSignedShorts(signed short *buf, unsigned int numSamples);
	bool ReadSignedShorts(signed short *buf, unsigned int sampleStartPos, unsigned int sampleEndPos);
	bool WriteSignedShorts(signed short *buf, unsigned int sampleStartPos, unsigned int sampleEndPos);
	byte ReadByte();
	int ReadInt();
	float ReadFloat();
	void WriteFloat(float val);
	void WriteLong(long long val);
	long long ReadLong();	
	unsigned int ReadUInt();	
	void WriteBool(bool val);
	bool ReadBool();
	
	unsigned int filePos;
	unsigned int fileSize;
	bool fileOpened;
	
	void Flush();
	void Seek(unsigned int newFilePos);
	
	unsigned char *data;
	unsigned int dataLen;
	
	FILE *fileHandle;
	
	NSString *fileNameNoExt;
	NSString *fullPath;
	NSString *tempPath;
	
	bool InitInTempStorage(char *filePath, int fileId);
	bool OpenForReadFromTempStorage(int fileId);
	bool OpenForWriteFromTempStorage(int fileId);
	
	NSString *GetPathForResource(char *fileName);

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

class CSlrString;

class CSystemFileDialogCallback
{
public:
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();
};


void SYS_DialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
						CSlrString *defaultFolder, CSlrString *windowTitle);
void SYS_DialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
						CSlrString *defaultFileName, CSlrString *defaultFolder, CSlrString *windowTitle);

bool SYS_FileExists(char *path);
bool SYS_FileExists(CSlrString *path);
bool SYS_FileDirExists(CSlrString *path);
bool SYS_FileDirExists(char *cPath);

uint8 *SYS_MapMemoryToFile(int memorySize, char *filePath, void **fileDescriptor);
void SYS_UnMapMemoryFromFile(uint8 *memoryMap, int memorySize, void **fileDescriptor);

void SYS_SetCurrentFolder(CSlrString *path);

#endif //__SYS_CFILESYSTEM_H__
