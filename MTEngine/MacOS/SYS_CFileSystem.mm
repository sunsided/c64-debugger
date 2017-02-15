/*
 *  SYS_CFileSystem.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

// iCloud: http://stackoverflow.com/questions/8375891/apple-icloud-implementation-on-mac-apps

#include "SYS_CFileSystem.h"
#include "TargetConditionals.h"
#include "CSlrFileFromResources.h"
#include "CSlrString.h"
#include "SYS_Funct.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syslimits.h>

CFileSystem *gFileSystem;
NSString *gOSPathToDocuments;
char *gPathToDocuments;
char *gCPathToDocuments;
CSlrString *gUTFPathToDocuments;
NSString *gOSPathToTemp;
char *gPathToTemp;
char *gCPathToTemp;
CSlrString *gUTFPathToTemp;
NSString *gOSPathToSettings;
char *gPathToSettings;
char *gCPathToSettings;
CSlrString *gUTFPathToSettings;

UTFString *gPathToCurrentDirectory;
char *gCPathToCurrentDirectory;
CSlrString *gUTFPathToCurrentDirectory;


std::list<CHttpFileUploadedCallback *> httpFileUploadedCallbacks;

void SYS_InitFileSystem()
{
	LOGM("SYS_InitFileSystem");
	//	NSString *folder = [path stringByExpandingTildeInPath];

#if defined(FINAL_RELEASE)
	// use resources in final release
	
	// get current folder
	gPathToCurrentDirectory = new char[PATH_MAX];
	getcwd(gPathToCurrentDirectory, PATH_MAX);
	
	LOGD("gPathToCurrentDirectory=%s", gPathToCurrentDirectory);
	
	gCPathToCurrentDirectory = gPathToCurrentDirectory;
	gUTFPathToCurrentDirectory = new CSlrString(gCPathToCurrentDirectory);
	
	NSError *error;
	
	/// get temp folder
	NSString *bundleId = [[NSRunningApplication runningApplicationWithProcessIdentifier:getpid()] bundleIdentifier];
	NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:bundleId] isDirectory:YES];
	
	//NSLog(@"Create temp folder at: %@", directoryURL);
	[[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	
	//gOSPathToTemp = [[NSString alloc] initWithFormat:@"%@/", [directoryURL path]];
	gOSPathToTemp = [[NSString alloc] initWithFormat:@"%@", [directoryURL path]];
	
	//NSLog(@"gOSPathToTemp=%@", gOSPathToTemp);
	
	/// get documents folder
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths firstObject];
	
	//gOSPathToDocuments = [[NSString alloc] initWithFormat:@"%@/", documentsDirectory];
	gOSPathToDocuments = [[NSString alloc] initWithFormat:@"%@", documentsDirectory];
	
	//NSLog(@"gOSPathToDocuments=%@", gOSPathToDocuments);
	
	
	/// get settings folder
	paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);		//NSApplicationSupportDirectory,
	NSString *settingsDirectory = [paths firstObject];
	directoryURL = [NSURL fileURLWithPath:[settingsDirectory stringByAppendingPathComponent:bundleId] isDirectory:YES];
	
	//NSLog(@"Create settings folder at: %@", directoryURL);
	[[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	
	//gOSPathToSettings = [[NSString alloc] initWithFormat:@"%@/", [directoryURL path]];
	gOSPathToSettings = [[NSString alloc] initWithFormat:@"%@", [directoryURL path]];

	//NSLog(@"gOSPathToSettings=%@", gOSPathToSettings);

	
	// create CSlrString / ANSI-C versions
	const char *path = (const char *)[gOSPathToDocuments UTF8String];
	gCPathToDocuments = strdup(path);
	gPathToDocuments = gCPathToDocuments;
	gUTFPathToDocuments = FUN_ConvertNSStringToCSlrString(gOSPathToDocuments);

	const char *pathTemp = (const char *)[gOSPathToTemp UTF8String];
	gCPathToTemp = strdup(pathTemp);
	gPathToTemp = gCPathToTemp;
	gUTFPathToTemp = FUN_ConvertNSStringToCSlrString(gOSPathToTemp);
	
	const char *pathSettings = (const char *)[gOSPathToSettings UTF8String];
	gCPathToSettings = strdup(pathSettings);
	gPathToSettings = gCPathToSettings;
	gUTFPathToSettings = FUN_ConvertNSStringToCSlrString(gOSPathToSettings);
	
#else
	
	/////////////////////////////////////
	/// development version, use Documents folder
	
//	//gOSPathToDocuments = @"/Users/mars/develop/RockinChristmasTree/_RUNTIME_/Documents/";
	gOSPathToDocuments = @"/Users/mars/develop/MTEngine/_RUNTIME_/Documents/";

//
////#if defined(IS_TRACKER)
////#if !defined(FINAL_RELEASE)
////	gOSPathToDocuments = @"/Users/mars/Documents/ft209/xms/";
////#endif
////#endif
//
	LOGM(@"gOSPathToDocuments=%@", gOSPathToDocuments);
	LOGM(gOSPathToDocuments);
	
	const char *path = (const char *)[gOSPathToDocuments UTF8String];
	gCPathToDocuments = strdup(path);
	gPathToDocuments = gCPathToDocuments;
	//LOGD("gCPathToDocuments='%s'", gCPathToDocuments);
	
	gOSPathToTemp = gOSPathToDocuments; //NSTemporaryDirectory();
	LOGM(@"gOSPathToTemp=%@", gOSPathToTemp);
	const char *pathTemp = (const char *)[gOSPathToTemp UTF8String];
	gCPathToTemp = strdup(pathTemp);

	gOSPathToSettings = gOSPathToDocuments; //NSTemporaryDirectory();
	LOGM(@"gOSPathToSettings=%@", gOSPathToSettings);
	const char *pathSettings = (const char *)[gOSPathToSettings UTF8String];
	gCPathToSettings = strdup(pathSettings);
	

	
#endif

	
	gFileSystem = new CFileSystem();
}

void SYS_DeleteFile(CSlrString *filePath)
{
	filePath->DebugPrint("SYS_DeleteFile: ");
	
	NSString *str = FUN_ConvertCSlrStringToNSString(filePath);
	remove([str fileSystemRepresentation]);
	[str release];
	
	LOGD("SYS_DeleteFile done");
}

CFileItem::CFileItem(char *name, char *modDate, bool isDir)
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

NSString *CFileSystem::GetPathForResource(char *fileNameX)
{
	char resNameNoPath[2048];
	int i = strlen(fileNameX)-1;
	
	char fileNamePath[MAX_STRING_LENGTH];
	
	bool isSlash = false;
	for(u16 j = 0; j < i; j++)
	{
		if (fileNameX[j] == '/')
		{
			isSlash = true;
			break;
		}
	}
	
	if (isSlash)
	{
		strcpy(fileNamePath, fileNameX);
	}
	else
	{
		sprintf(fileNamePath, "/%s", fileNameX);
	}
	
	for (  ; i >= 0; i--)
	{
		if (fileNamePath[i] == '/')
			break;
	}
	
	int j = 0;
	while(true)
	{
		if (fileNamePath[i] == '.')
		{
			resNameNoPath[j] = '\0';
			break;			
		}
		resNameNoPath[j] = fileNamePath[i];
		if (fileNamePath[i] == '\0')
			break;
		j++;
		i++;
	}
	
	char ext[16] = {0};	
	if (fileNamePath[i] == '.')
	{
		i++;
		j = 0;
		while(true)
		{
			ext[j] = fileNamePath[i];
			if (fileNamePath[i] == '\0')
				break;
			j++;
			i++;
		}
	}
	else
	{
		ext[0] = '\0';
	}
	
	NSString *nsFileName = [NSString stringWithCString:resNameNoPath encoding:NSASCIIStringEncoding];
	NSString *nsExtName = [NSString stringWithCString:ext encoding:NSASCIIStringEncoding];
	
	// iOS3.2
	NSString *fileNameNoSlash = [nsFileName stringByReplacingOccurrencesOfString:@"/" withString:@""];
	
	LOGR("fileNameNoSlash:");
	LOGR(fileNameNoSlash);
	
	//NSString *path = [[NSBundle mainBundle] pathForResource:nsFileName ofType:nsExtName];
	NSString *path = [[NSBundle mainBundle] pathForResource:fileNameNoSlash ofType:nsExtName inDirectory:@""];

	return path;
}

bool CFileSystem::OpenResourceForRead(char *fileName)
{
	CSlrFileFromResources *file = new CSlrFileFromResources(fileName);
	
	this->dataLen = file->fileSize;
	this->data = (byte*)malloc(this->dataLen);
	file->Read(data, dataLen);
	file->Close();
	delete file;
	return true;
	
//	NSString *path = this->GetPathForResource(fileName);
//	LOGD("CFileSystem::OpenResourceForRead: path=");
//	LOGD(path);

	/*
	 v1:
	 
	 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	 NSString *documentsDirectory = [paths objectAtIndex:0];
	 if (!documentsDirectory) {
	 NSLog(@"Documents directory not found!");
	 return NO;
	 }
	 NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	 return ([data writeToFile:appFile atomically:YES]);
	 */

	/*
	 v2
	 LOGD(path);
	NSData *nsData = [[NSData alloc] initWithContentsOfFile:path];
    if (nsData == nil)
	{
		LOGError("File not found");
		LOGError(fileName);
		return false;
	}
	dataLen = [nsData length];
	data = (Byte*)malloc(dataLen);
	memcpy(data, [nsData bytes], dataLen);
	
	[nsData release];
	filePos = 0;
	 */
	//return true;
}

bool CFileSystem::OpenForRead(char *fileName)
{
	if (data != NULL)
	{
		LOGError("OpenForRead: file not closed");
		this->Close();
	}
	
	NSString *path = [NSString stringWithUTF8String:fileName] ;
	LOGR("CFileSystem::OpenForRead: path=");
	LOGR(path);

	if (this->fileHandle != NULL)
	{
		LOGError("CFileSystem::OpenForRead: file not closed");
		LOGError(fileName);
		this->Close();
	}

	this->data = NULL;	
	this->fileHandle = fopen([path fileSystemRepresentation], "rb");
	filePos = 0;
	
	return true;
}

void CFileSystem::Flush()
{
	fflush(this->fileHandle);
}

bool CFileSystem::ReadAllToBuffer(char *fileName)
{
	if (this->data != NULL)
		free(this->data);
	
	NSString *fileNameStr = [[NSString alloc] initWithCString:fileName encoding:NSUTF8StringEncoding];	
	NSData *nsData = [[NSData alloc] initWithContentsOfFile:fileNameStr];
    if (nsData == nil)
	{
		[fileNameStr release];
		LOGError("File not found");
		LOGError(fileName);
		return false;
	}
	dataLen = [nsData length];
	data = (Byte*)malloc(dataLen);
	memcpy(data, [nsData bytes], dataLen);
	
	[nsData release];
	filePos = 0;
	
	[fileNameStr release];
	
	return true;
}

void CFileSystem::Seek(unsigned int newFilePos)
{
	fseek(this->fileHandle, newFilePos, SEEK_SET);
	this->filePos = newFilePos;
}

bool CFileSystem::OpenForWrite(NSString *fileName)
{
	LOGR("CFileSystem::OpenForWrite:");
	LOGR(fileName);
	
	if (data != NULL)
	{
		LOGError("OpenForWrite: file not closed");
		this->Close();
	}
	
	NSString *path = fileName; //[gOSPathToDocuments stringByAppendingPathComponent:fileName];
	LOGR("CFileSystem::OpenForWrite: path=");
	LOGR(path);
	
	if (this->fileHandle != NULL)
	{
		LOGError("CFileSystem::OpenForWrite: file not closed");
		LOGError(fileName);
		this->Close();
	}
	
	this->data = NULL;	
	this->fileHandle = fopen([fileName fileSystemRepresentation], "wb");
	filePos = 0;
	
	return true;	
}

bool CFileSystem::InitInTempStorage(char *fileName, int fileId)
{
	NSString *nsFileName = [NSString stringWithUTF8String:fileName];
	
	if (this->fileNameNoExt != NULL)
	{
		[this->fileNameNoExt release];
	}
	
	if (this->fullPath != NULL)
	{
		[this->fullPath release];
	}
	
	if (this->tempPath != NULL)
	{
		[this->tempPath release];
	}
	
	this->fullPath = [[NSString alloc] initWithString:nsFileName];	
	this->fileNameNoExt = [[NSString alloc] 
							   initWithString:
							   [[nsFileName stringByDeletingPathExtension] lastPathComponent]
							   ];

	this->tempPath = [[NSString alloc] initWithFormat:@"%08d", fileId];
	
	//[gOSPathToTemp stringByAppendingPathComponent:fileNameNoExt];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	
	BOOL success = [fileManager copyItemAtPath:fullPath toPath:tempPath error:&error];

	if (success == FALSE)
		return false;
	
	this->fileHandle = fopen([this->tempPath fileSystemRepresentation], "rb");
	
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
		[this->tempPath release];
	}
	this->tempPath = [[NSString alloc] initWithFormat:@"%@/%08d", gOSPathToTemp, fileId];

	LOGD(this->tempPath);
	
	this->fileHandle = fopen([this->tempPath fileSystemRepresentation], "rb");	
	
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
		[this->tempPath release];
	}
	this->tempPath = [[NSString alloc] initWithFormat:@"%08d", fileId];
	
	this->fileHandle = fopen([this->tempPath fileSystemRepresentation], "wb");	
}

bool CFileSystem::OpenForWriteInTempStorage(char *fileName)
{
	LOGR("CFileSystem::OpenForWriteInTempStorage: '%s'", fileName);
	
	NSString *fnameS = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSASCIIStringEncoding];
//	NSLog(@"%@", fnameS);
	
	NSString *path = [gOSPathToTemp stringByAppendingPathComponent:fnameS];
	//	NSString *path = [NSString stringWithFormat:@"%@%@", gOSPathToTemp, fnameS];
//	NSLog(@"%@", path);
	
	this->fileHandle = fopen([path fileSystemRepresentation], "wb");

	this->filePos = 0;
	[fnameS release];
	
	if (this->fileHandle)
		return true;
	
	return false;
}

bool CFileSystem::OpenForReadInTempStorage(char *fileName)
{
	LOGR("CFileSystem::OpenForReadInTempStorage: '%s'", fileName);
	
	NSString *fnameS = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSASCIIStringEncoding];
	//NSLog(@"%@", fnameS);
	
	NSString *path = [gOSPathToTemp stringByAppendingPathComponent:fnameS];
//	NSString *path = [NSString stringWithFormat:@"%@%@", gOSPathToTemp, fnameS];
	//NSLog(@"%@", path);
	
	this->fileHandle = fopen([path fileSystemRepresentation], "rb");
	
	this->filePos = 0;
	[fnameS release];
	
	if (this->fileHandle)
		return true;
	
	return false;
}

bool CFileSystem::OpenForWriteInDocuments(char *fileName, bool appendPath)
{
	LOGR("CFileSystem::OpenForWriteInDocuments: '%s'", fileName);
	
	NSString *fnameS = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSASCIIStringEncoding];
	//	NSLog(@"%@", fnameS);
	
	LOGM("fnameS=");
	LOGM(fnameS);

	// TODO: this for sure leaks
	NSString *path; 
	if (appendPath)
	{
		path = [gOSPathToDocuments stringByAppendingPathComponent:fnameS];
	
		//	NSString *path = [NSString stringWithFormat:@"%@%@", gOSPathToTemp, fnameS];
		//	NSLog(@"%@", path);
	}
	else
	{
		path = fnameS;
	}
	
	LOGM("path=");
	LOGM(path);
	this->fileHandle = fopen([path fileSystemRepresentation], "wb");
	
	this->filePos = 0;
	[fnameS release];
	
	if (this->fileHandle)
		return true;
	
	LOGError("fileHandle NULL!!");
	
	return false;
}

bool CFileSystem::OpenForReadInDocuments(char *fileName)
{
	LOGR("CFileSystem::OpenForReadInDocuments: '%s'", fileName);
	
	NSString *fnameS = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSASCIIStringEncoding];
	//NSLog(@"%@", fnameS);
	
	LOGM("fnameS=");
	LOGM(fnameS);

	NSString *path = [gOSPathToDocuments stringByAppendingPathComponent:fnameS];
	//	NSString *path = [NSString stringWithFormat:@"%@%@", gOSPathToTemp, fnameS];	
	//NSLog(@"%@", path);
	
	LOGM("path=");
	LOGM(path);

	LOGM("check file exists:");
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		this->fileHandle = fopen([path fileSystemRepresentation], "rb");
		
		this->filePos = 0;
		[fnameS release];
		
		if (this->fileHandle)
			return true;
		
		LOGError("fileHandle NULL!!");
		
		return false;		
	}

	[fnameS release];
	LOGM("file does not exist");
	
	return false;
}

void CFileSystem::Close()
{
	//LOGR("CFileSystem::Close()");
	if (this->data != NULL)
		free(this->data);
	
	this->dataLen = 0;
	this->data = NULL;
	
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

int CFileSystem::ReadInt()
{
	byte buf[4];
	Read(buf, 4);
	return buf[0] | (buf[1] << 8) | (buf[2] << 16) | (buf[3] << 24);
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

std::vector<CFileItem *> *CFileSystem::GetFiles(char *directoryPath, std::list<char *> *extensions)
{
	std::vector<CFileItem *> *files = new std::vector<CFileItem *>();
	
	NSString *nsDirectoryPath = [NSString stringWithUTF8String:directoryPath];
	
	NSArray *array = [[NSFileManager defaultManager] directoryContentsAtPath:nsDirectoryPath];
	
	for (NSString *fname in array)
    {
		//LOGD("check file:");
		//LOGD(fname);
        NSDictionary *fileDict =
		[[NSFileManager defaultManager] fileAttributesAtPath:[nsDirectoryPath stringByAppendingPathComponent:fname] traverseLink:NO];
		//NSString *modDate = [[fileDict objectForKey:NSFileModificationDate] description];
		
		NSString* pathExt = [fname pathExtension];
		
		NSString *modDate = [[fileDict objectForKey:NSFileModificationDate] description];
		
		if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"])
		{
			//fname = [fname stringByAppendingString:@"/"];
			
			//LOGD("adding");
			//LOGD(fname);
			
			char *fileNameDup = strdup([fname UTF8String]);
			char *modDateDup = strdup([modDate UTF8String]);
			
			CFileItem *item = new CFileItem(fileNameDup, modDateDup, true); 
			files->push_back(item);
		}
		else
		{
			for (std::list<char *>::iterator itExtensions = extensions->begin();
				 itExtensions !=  extensions->end(); itExtensions++)                                                       
			{
				char *extension = *itExtensions;
				NSString *nsExtension = [NSString stringWithUTF8String:extension];
				
				if ([pathExt localizedCaseInsensitiveCompare:nsExtension] == NSOrderedSame)
					//		if ([pathExt isEqualToString:@"xm"])
				{
					//LOGD("adding");
					//LOGD(fname);
					
					char *fileNameDup = strdup([fname UTF8String]);
					char *modDateDup = strdup([modDate UTF8String]);
					
					CFileItem *item = new CFileItem(fileNameDup, modDateDup, false); 
					files->push_back(item);
				}
			}
		}
	}
	
	std::sort(files->begin(), files->end(), compare_CFileItem_nocase);
	
	return files;
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

void SYS_DialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
						CSlrString *defaultFolder,
						CSlrString *windowTitle)
{
	NSMutableArray *extensionsArray = nil;
	
	if (extensions != NULL && !extensions->empty())
	{
		extensionsArray = [[NSMutableArray alloc] init];
		
		for (std::list<CSlrString *>::iterator it = extensions->begin(); it != extensions->end(); it++)
		{
			CSlrString *str = *it;
			NSString *nsStr = FUN_ConvertCSlrStringToNSString(str);
			[extensionsArray addObject:nsStr];
		}
		
		NSLog(@"%@", extensionsArray);
	}

	NSString *wtitle = nil;
	if (windowTitle != NULL)
	{
		wtitle = FUN_ConvertCSlrStringToNSString(windowTitle);
	}
	
	NSString *dfolder = nil;
	
	if (defaultFolder != NULL)
	{
		dfolder = FUN_ConvertCSlrStringToNSString(defaultFolder);
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSOpenPanel *panel = [[NSOpenPanel openPanel] retain];
		
		// Configure your panel the way you want it
		[panel setCanChooseFiles:YES];
		[panel setCanChooseDirectories:NO];
		[panel setAllowsMultipleSelection:NO];
		
		if (extensionsArray != nil)
			[panel setAllowedFileTypes:extensionsArray];
		
		if (wtitle != nil)
			[panel setTitle:wtitle];
		
		if (dfolder != nil)
			[panel setDirectoryURL:[NSURL URLWithString:dfolder]];
		
		[panel beginWithCompletionHandler:^(NSInteger result)
		{
			LOGD("SYS_DialogOpenFile: dialog result=%d", result);
			if (result == NSFileHandlingPanelOKButton)
			{
				for (NSURL *fileURL in [panel URLs])
				{
					NSString *strPath = [fileURL path];
					CSlrString *outPath = FUN_ConvertNSStringToCSlrString(strPath);
					callback->SystemDialogFileOpenSelected(outPath);
				}
			}
			else
			{
				callback->SystemDialogFileOpenCancelled();
			}
			
			[panel release];
			if (wtitle != nil)
				[wtitle release];
			if (dfolder != nil)
				[dfolder release];
			
			if (extensionsArray != nil)
				[extensionsArray release];
		}];
		
		[NSApp activateIgnoringOtherApps:YES];
		
	});
}




void SYS_DialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
						CSlrString *defaultFileName, CSlrString *defaultFolder,
						CSlrString *windowTitle)
{
	NSMutableArray *extensionsArray = [[NSMutableArray alloc] init];
	
	for (std::list<CSlrString *>::iterator it = extensions->begin(); it != extensions->end(); it++)
	{
		CSlrString *str = *it;
		NSString *nsStr = FUN_ConvertCSlrStringToNSString(str);
		[extensionsArray addObject:nsStr];
	}
	
	NSLog(@"%@", extensionsArray);

	NSString *fname = nil;
	NSString *wtitle = nil;
	NSString *dfolder = nil;
	
	if (defaultFileName != NULL)
	{
		fname = FUN_ConvertCSlrStringToNSString(defaultFileName);
	}
	if (windowTitle != NULL)
	{
		wtitle = FUN_ConvertCSlrStringToNSString(windowTitle);
	}
	
	if (defaultFolder != NULL)
	{
		dfolder = FUN_ConvertCSlrStringToNSString(defaultFolder);
	}
	


	dispatch_async(dispatch_get_main_queue(), ^{
		NSSavePanel *panel = [[NSSavePanel savePanel] retain];
		
		// Configure your panel the way you want it
		[panel setAllowsOtherFileTypes:NO];
		[panel setExtensionHidden:YES];
		[panel setCanCreateDirectories:YES];
		[panel setAllowedFileTypes:extensionsArray];

		if (fname != nil)
		{
			[panel setNameFieldStringValue:fname];
		}
		if (wtitle != nil)
		{
			[panel setTitle:wtitle];
		}
		
		if (dfolder != nil)
		{
			[panel setDirectoryURL:[NSURL URLWithString:dfolder]];
		}

		[panel beginWithCompletionHandler:^(NSInteger result)
		 {
			 LOGD("SYS_DialogSaveFile: dialog result=%d", result);
			 if (result == NSFileHandlingPanelOKButton)
			 {
				 NSString *strPath = [[panel URL] path];
				 CSlrString *outPath = FUN_ConvertNSStringToCSlrString(strPath);
				 callback->SystemDialogFileSaveSelected(outPath);
			 }
			 else
			 {
				 callback->SystemDialogFileSaveCancelled();
			 }
			 
			 [panel release];
			 if (fname != nil)
				 [fname release];
			 if (wtitle != nil)
				 [wtitle release];
			 if (dfolder != nil)
				 [dfolder release];
			 [extensionsArray release];
		 }];
		
		[NSApp activateIgnoringOtherApps:YES];
		
	});
	
	LOGD("SYS_DialogSaveFile: done");
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

