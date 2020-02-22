/*
 * SYS_Startup.cpp
 *
 *  Created on: Jun 9, 2011
 *      Author: mars
 */

#include "DBG_Log.h"
#include "./image/CImageData.h"
#include "./image/IMG_Filters.h"
#include "./image/IMG_Scale.h"
#include "GFX_WriteImage.h"
#include "GFX_ReadImage.h"
#include "CSegmentedObject.h"
#include <string>
#include <cstring>
#include <map>
#include <sys/types.h>
#include <sys/stat.h>
#include "CSlrFileFromSystem.h"
#include "CByteBuffer.h"
#include "RES_DeployFile.h"
#include "CSlrImageDummy.h"
#include "./platform/Linux/SYS_GetFilesFromDirectory.h"
#include "CSlrDate.h"

void ParseFileName(char *fileName, char *fileNameNoExt, char *fileExt)
{
//	LOGD("ParseFileName: '%s'", fileName);

	int pos = -1;
	for (int i = strlen(fileName)-1; i >= 0; i--)
	{
//		LOGD("i=%d", i);
		if (fileName[i] == '.')
		{
			pos = i;
			break;
		}
	}

	if (pos == -1)
	{
		u32 j = 0;
		for (u32 i = 0; i < strlen(fileName); i++)
		{
			fileNameNoExt[j++] = fileName[i];
		}
		fileNameNoExt[j] = 0x00;
		fileExt[0] = 0x00;
		return;
	}

	u32 j = 0;
	for (u32 i = pos+1; i < strlen(fileName); i++)
	{
		fileExt[j++] = fileName[i];
	}
	fileExt[j] = 0x00;
	j = 0;
	for (u32 i = 0; i < pos; i++)
	{
		fileNameNoExt[j++] = fileName[i];
	}
	fileNameNoExt[j] = 0x00;
}

void printUsage()
{
	LOGM("Usage: DeployMaker <deploy-file.txt>");
	LOGM("       DeployMaker <image-file.png>");
	LOGM("       DeployMaker embed <file>");
	LOGM("       DeployMaker scan <deploy-file.txt> <deploy-dir> <root-folder> [prefix]");
	LOGM("");
	LOGM("Deploy file structure:");
	LOGM("");
	LOGM("<folder with files>               <-- folder where are files currently");
	LOGM("<root folder>                     <-- root folder for deploy file names");
	LOGM("<source screen width>");
	LOGM("[resolutions]");
	LOGM("<dest screen width #1>");
	LOGM("<dest screen width #2...>");
	LOGM("[files]");
	LOGM("<file path.ext #1>");
	LOGM("!<file path.ext #2>  <-- gfx keep raster ^2");
	LOGM("@<file path.ext #3>  <-- force original resolution");
	LOGM("j<file path.ext #4>  <-- compress jpeg");
	LOGM("j!<file path.ext #5> <-- compress jpeg & keep raster ^2");
	LOGM("j@<file path.ext #6> <-- compress jpeg & force original resolution");
	LOGM("# blah blah          <-- comment");
	LOGM("<file path.ext #7...>");
	LOGM("");
	LOGM("Available extensions: png, anim, vec, ogg, txt, ...");

}

void ScanFolder(FILE *fp, char *folderPath, char *prefix)
{
	LOGD("============ scan folder %s", folderPath);

	char buf[MAX_STRING_LENGTH];
	char buf2[MAX_STRING_LENGTH];
	vector<CFileItem *> *fileItems = SYS_GetFilesFromDirectory(folderPath);

	for (std::vector<CFileItem *>::iterator it = fileItems->begin(); it != fileItems->end(); it++)
	{
		CFileItem *fileItem = *it;
		LOGD("%s", fileItem->name);

		if (fileItem->isDir)
		{
			LOGD("   ... is folder");
			//sprintf(buf, "%s%s", folderPath, fileItem->name);

			sprintf(buf, "%s", folderPath);

			u32 l = strlen(buf)-1;

			if (buf[l] != '/')
			{
				l++;
				buf[l++] = '/';
				buf[l] = 0x00;
			}
			strcat(buf, fileItem->name);

			sprintf(buf2, "%s/%s", prefix, fileItem->name);
			ScanFolder(fp, buf, buf2);
		}
		else
		{
			if (!strcmp(fileItem->name, ".DS_Store"))
				continue;
			sprintf(buf, "%s/%s", prefix, fileItem->name);
			fprintf(fp, "%s\n", buf);
		}
	}
}

void MakeScan(char *deployFile, char *folder, char *rootFolder, char *prefix)
{
	LOGM("Scanning %s to %s (prefix='%s')", folder, deployFile, prefix);

	FILE *fp = fopen(deployFile, "wb");
	fprintf(fp, ".\n");
	fprintf(fp, "%s\n", rootFolder);
	fprintf(fp, "2048\n");
	fprintf(fp, "[resolutions]\n");
	fprintf(fp, "1024\n");
	fprintf(fp, "2048\n");
	fprintf(fp, "[files]\n");
	ScanFolder(fp, folder, prefix);
	fclose(fp);

}

void DoEmbed(char *fileName)
{
	CSlrFileFromSystem *fpIn = new CSlrFileFromSystem(fileName);
	if (!fpIn->Exists())
	{
		exit(-1);
	}
	
	int fsize = fpIn->GetFileSize();

	char safeFileName[4096];
	char safeFileNameNoExt[4096];
	
	// create new filename
	sprintf(safeFileName, "%s", fileName);
	int l = strlen(safeFileName);
	for (int i = 0; i < l; i++)
	{
		if (safeFileName[i] == '.' || safeFileName[i] == '-')
		{
			safeFileName[i] = '_';
		}
	}

	sprintf(safeFileNameNoExt, "%s", fileName);
	l = strlen(safeFileNameNoExt);
	for (int i = 0; i < l; i++)
	{
		if (safeFileNameNoExt[i] == '-')
		{
			safeFileNameNoExt[i] = '_';
		}
		else if (safeFileNameNoExt[i] == '.')
		{
			safeFileNameNoExt[i] = 0x00;
			break;
		}
	}

	char buf[4096];
	sprintf(buf, "%s.h", safeFileName);

	LOGD("Out file name: %s", buf);

	FILE *fpOut = fopen(buf, "wb");
	fprintf(fpOut, "// Embedded file name: %s\n", fileName);
	fprintf(fpOut, "// #include \"%s.h\"\n", safeFileName);
	fprintf(fpOut, "// RES_AddEmbeddedDataToDeploy(\"/gfx/%s\", DEPLOY_FILE_TYPE_GFX, %s, %s_length);\n", safeFileNameNoExt, safeFileName, safeFileName);
	fprintf(fpOut, "int %s_length = %d;\n", safeFileName, fsize);
	fprintf(fpOut, "uint8 %s[%d] = {\n", safeFileName, fsize);

	int lt = fsize-1;
	int b = 0;
	fprintf(fpOut, "\t");
	for (int i = 0;  ; i++)
	{
		u8 v = fpIn->ReadByte();
		fprintf(fpOut, "0x%02x", v);
		
		if (i == lt)
		{
			fprintf(fpOut, "\n};\n\n");
			break;
		}
		
		if (b == 0x0F)
		{
			fprintf(fpOut, ",\n\t");
			b = 0;
			continue;
		}
		
		b++;
		fprintf(fpOut, ", ");
	}
	
	delete fpIn;
	fflush(fpOut);
	fclose(fpOut);
}

int main( int argc, char **argv )
{
	LOG_Init();

	LOGM("DeployMaker v" VERSION ", (C)2012 Marcin Skoczylas");

	if (argc < 2)
	{
		printUsage();
		exit(-1);
	}

	char fileName[1024] = {0};
	char extension[1024] = {0};

	if (!strcmp(argv[1], "embed"))
	{
		if (argc != 3)
		{
			printUsage();
			exit(-1);
		}

		DoEmbed(argv[2]);
		LOGM("Done!");
		exit(0);
	}
	
	if (!strcmp(argv[1], "scan"))
	{
		char *prefix = "";

		if (argc == 6)
		{
			prefix = argv[5];
		}
		else if (argc != 5)
		{
			printUsage();
			exit(-1);
		}
		char *deployFile = argv[2];
		char *folder = argv[3];
		if (folder[strlen(folder)-1] != '/')
		{
			sprintf(fileName, "%s/", folder);
		}
		else
		{
			sprintf(fileName, "%s", folder);
		}
		char *rootFolder = argv[4];
		MakeScan(deployFile, fileName, rootFolder, prefix);
		LOGM("Done!");
		exit(0);
	}

	char *fileNameIn = argv[1];

	u32 len = strlen(fileNameIn);

	u32 cnt = 0;
	bool name = true;
	for (u32 i = 0; i < len; i++)
	{
		if (fileNameIn[i] == '.')
		{
			name = false;
			cnt = 0;
			continue;
		}

		if (name)
		{
			fileName[cnt] = fileNameIn[i];
		}
		else
		{
			extension[cnt] = fileNameIn[i];
		}
		cnt++;
	}

	LOGD("fileName='%s' extension='%s'", fileName, extension);

	if (!strcmp(extension, "png"))
	{
		CImageData *imageIn = new CImageData(fileNameIn);

		char buf[1024];

		//CImageData *imageOut = IMG_Scale(imageIn, 0.5f, 0.5f);
		//sprintf(buf, "%s-small.png", fileName);
		//imageOut->Save(buf);

		sprintf(buf, "%s.gfx", fileName);

		GFX_WriteImage(buf, imageIn, 2048, 2048, GFX_COMPRESSION_TYPE_ZLIB, false);
	//	GFX_WriteImage(buf, imageIn, 2048, destScreenWidths, GFX_COMPRESSION_TYPE_LZMPI);
	}
	else
	{
		// deploy file
		time_t rawtime;
		struct tm * timeinfo;
		time ( &rawtime );
		timeinfo = localtime ( &rawtime );
		char deployFolderName[1024];
		sprintf(deployFolderName, "./deploy/"); //-%02d%02d%02d-%02d%02d/", (timeinfo->tm_year-100), (timeinfo->tm_mon+1), timeinfo->tm_mday, timeinfo->tm_hour, timeinfo->tm_min);
		int status;
		status = mkdir(deployFolderName, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);

		LOGM("Deploy folder: %s", deployFolderName);
		char buf2[MAX_STRING_LENGTH];
		sprintf(buf2, "rm %s*", deployFolderName);
		LOGD("%s", buf2);
		system(buf2);

		std::list<u16> destScreenWidths;
		std::list<char *> fileNames;

		char filesFolder[MAX_STRING_LENGTH];
		char rootFolder[MAX_STRING_LENGTH];
		char bufLine[MAX_STRING_LENGTH];
		CSlrFileFromSystem *file = new CSlrFileFromSystem(fileNameIn);

		bool v = false;
		v = file->ReadLine(filesFolder, MAX_STRING_LENGTH);
		LOGM("Files folder: %s", filesFolder);
		v = file->ReadLine(rootFolder, MAX_STRING_LENGTH);
		LOGM("Root folder: %s", rootFolder);

		v = file->ReadLine(bufLine, MAX_STRING_LENGTH);

		u16 sourceScreenWidth = atoi(bufLine);

		LOGM("Source screen width=%d", sourceScreenWidth);

		while(!file->Eof())
		{
			v = file->ReadLine(bufLine, MAX_STRING_LENGTH);

			if (!strcmp(bufLine, "[resolutions]"))
			{
				LOGD("[resolutions]");
				while(!file->Eof())
				{
					v = file->ReadLine(bufLine, MAX_STRING_LENGTH);

					if (bufLine[0] == '[')
						break;

					u32 res = atoi(bufLine);
					LOGD("...adding %d", res);
					destScreenWidths.push_back(res);

					if (v)
						break;

				}
			}

			if (!strcmp(bufLine, "[files]"))
			{
				LOGD("[files]");
				while(!file->Eof())
				{
					v = file->ReadLine(bufLine, MAX_STRING_LENGTH);

					if (bufLine[0] == '#')
						continue;
					
					if (bufLine[0] == '['
						|| bufLine[0] == '\0'
						|| bufLine[0] == '\n'
						|| bufLine[0] == '\r'
						|| bufLine[0] == 0x0B)
						break;

					fileNames.push_back(strdup(bufLine));

					LOGD("...adding '%s'", bufLine);
//					for (int i = 0; i < strlen(bufLine); i++)
//						LOGD("i=%d %2.2x", i, bufLine[i]);

					if (v)
						break;

				}
			}

//			if (!strcmp(bufLine, "[others]"))
//			{
//				LOGD("[others]");
//				while(!file->Eof())
//				{
//					v = file->ReadLine(bufLine, MAX_STRING_LENGTH);
//
//					if (bufLine[0] == '[')
//						break;
//
//					if (bufLine[0] == '\0')
//						break;
//
//					otherFileNames.push_back(strdup(bufLine));
//
//					LOGD("...adding '%s'", bufLine);
//
//					if (v)
//						break;
//
//				}
//			}

			if (v)
				break;
		}

		LOGM("---- DEPLOYING FILES TO %s ----", deployFolderName);
		// make deploy, scale images
		CByteBuffer *deployBuffer = new CByteBuffer();

		deployBuffer->putByte(DEPLOY_FILE_MAGIC1);
		deployBuffer->putByte(DEPLOY_FILE_VERSION);
		
		CSlrDate *currentDate = new CSlrDate();
		LOGM("Deploy date=%d-%d-%d %02d:%02d:%02d", currentDate->day, currentDate->month, currentDate->year, currentDate->hour, currentDate->minute, currentDate->second);

		deployBuffer->PutDate(currentDate);
		delete currentDate;
		
		u32 fileNum = 0;

		deployBuffer->putUnsignedShort(destScreenWidths.size());
		for (std::list<u16>::iterator itWidth = destScreenWidths.begin();
				itWidth != destScreenWidths.end(); itWidth++)
		{
			u16 destWidth = *itWidth;
			deployBuffer->putUnsignedShort(destWidth);
		}

		char deployedFileName[MAX_STRING_LENGTH];
		char hashcodeFileName[MAX_STRING_LENGTH];

		// std::map< fileType,   std::map<u64, u64> > hashCodesInDeploy;
		
		deployBuffer->putUnsignedInt((u32)fileNames.size());
		for (std::list<char *>::iterator itFiles = fileNames.begin();
				itFiles != fileNames.end(); itFiles++)
		{
			char *currentFileName = *itFiles;

			char ext[MAX_STRING_LENGTH];
			char noExt[MAX_STRING_LENGTH];
			char filePathInDeploy[MAX_STRING_LENGTH];
			
			char *noExtFileName = noExt;

			ParseFileName(currentFileName, noExt, ext);

			u64 hashCode = 0;
			if (noExtFileName[0] == 'j' || noExtFileName[0] == 'J'
				|| noExtFileName[0] == 'i' || noExtFileName[0] == 'I')
			{
				noExtFileName++;
			}
			
			if (noExtFileName[0] == '!' || noExtFileName[0] == '@')
			{
				noExtFileName++;
			}

			sprintf(filePathInDeploy, "%s%s", rootFolder, noExtFileName);

			hashCode = GetHashCode64(filePathInDeploy);

			LOGM("%s: DeployPath='%s' Ext='%s' hashCode=%lld", currentFileName, filePathInDeploy, ext, hashCode);

//			std::map<u64, u64>::iterator itHash = hashCodesInDeploy.find(hashCode);
//			if (itHash != hashCodesInDeploy.end())
//			{
//				SYS_FatalExit("HashCode / File duplicated: fileName=%s DeployPath=%s", currentFileName, filePathInDeploy);
//			}
//			hashCodesInDeploy[hashCode] = hashCode;
			
			deployBuffer->PutU64(hashCode); //String(noExt);

			if (!strcmp(ext, "png") || !strcmp(ext, "PNG"))
			{
				deployBuffer->putUnsignedShort(DEPLOY_FILE_TYPE_GFX);

				char buf[MAX_STRING_LENGTH];

				bool isSheet = false;
				bool forceOriginal = false;
				byte compressionType = GFX_COMPRESSION_TYPE_ZLIB;
				
				if (currentFileName[0] == 'j' || currentFileName[0] == 'J')
				{
					compressionType = GFX_COMPRESSION_TYPE_JPEG_ZLIB;
					currentFileName = currentFileName+1;
				}
				else if (currentFileName[0] == 'i' || currentFileName[0] == 'I')
				{
					compressionType = GFX_COMPRESSION_TYPE_JPEG;
					currentFileName = currentFileName+1;
				}

				if (currentFileName[0] == '!')
				{
					isSheet = true;
					sprintf(buf, "%s%s", filesFolder, currentFileName+1);
				}
				else if (currentFileName[0] == '@')
				{
					forceOriginal = true;
					sprintf(buf, "%s%s", filesFolder, currentFileName+1);
				}
				else
				{
					sprintf(buf, "%s%s", filesFolder, currentFileName);
				}
				deployBuffer->putBoolean(forceOriginal);

				LOGM("PNG %s", buf);

				if (forceOriginal == false)
				{
					CImageData *imageIn = new CImageData(buf);

					u32 imgNum = 0;
					for (std::list<u16>::iterator itWidth = destScreenWidths.begin();
							itWidth != destScreenWidths.end(); itWidth++)
					{
						u16 destWidth = *itWidth;

						//sprintf(deployedFileName, "%016llx%c%2.2x", hashCode, imgNum + 65, DEPLOY_FILE_TYPE_GFX);

						sprintfHexCode64(hashcodeFileName, hashCode);
						sprintf(deployedFileName, "%s%c%2.2X", hashcodeFileName, imgNum + 65, DEPLOY_FILE_TYPE_GFX);

						imgNum++;
						fileNum++;

						char buf[MAX_STRING_LENGTH];
						sprintf(buf, "%s%s", deployFolderName, deployedFileName);
						GFX_WriteImage(buf, imageIn, sourceScreenWidth, destWidth, compressionType, isSheet);
					}
				}
				else
				{
					CImageData *imageIn = new CImageData(buf);
					//sprintf(deployedFileName, "%016llx%2.2x", hashCode, DEPLOY_FILE_TYPE_GFX);

					sprintfHexCode64(hashcodeFileName, hashCode);
					sprintf(deployedFileName, "%s%2.2X", hashcodeFileName, DEPLOY_FILE_TYPE_GFX);

					fileNum++;

					char buf[MAX_STRING_LENGTH];
					sprintf(buf, "%s%s", deployFolderName, deployedFileName);
					GFX_WriteImage(buf, imageIn, sourceScreenWidth, sourceScreenWidth, compressionType, isSheet);
				}
			}
			else if (!strcmp(ext, "gfx") || !strcmp(ext, "GFX"))
			{
				deployBuffer->putUnsignedShort(DEPLOY_FILE_TYPE_GFX);
				
				char buf[MAX_STRING_LENGTH];
				
				bool isSheet = false;
				bool forceOriginal = false;
				byte compressionType = GFX_COMPRESSION_TYPE_ZLIB;
				
				if (currentFileName[0] == 'j' || currentFileName[0] == 'J')
				{
					compressionType = GFX_COMPRESSION_TYPE_JPEG_ZLIB;
					currentFileName = currentFileName+1;
				}
				else if (currentFileName[0] == 'i' || currentFileName[0] == 'I')
				{
					compressionType = GFX_COMPRESSION_TYPE_JPEG;
					currentFileName = currentFileName+1;
				}
				
				if (currentFileName[0] == '!')
				{
					isSheet = true;
					sprintf(buf, "%s%s", filesFolder, currentFileName+1);
				}
				else if (currentFileName[0] == '@')
				{
					forceOriginal = true;
					sprintf(buf, "%s%s", filesFolder, currentFileName+1);
				}
				else
				{
					sprintf(buf, "%s%s", filesFolder, currentFileName);
				}
				
				
				deployBuffer->putBoolean(forceOriginal);
				
				LOGM("GFX %s", buf);
				
				if (forceOriginal == false)
				{
					CSlrImageDummy *imageIn = GFX_ReadImage(buf);
					LOGD("%s width=%d height=%d", buf, imageIn->loadImgWidth, imageIn->loadImgHeight);
					
					u32 imgNum = 0;
					for (std::list<u16>::iterator itWidth = destScreenWidths.begin();
						 itWidth != destScreenWidths.end(); itWidth++)
					{
						u16 destWidth = *itWidth;
						
						//sprintf(deployedFileName, "%016llx%c%2.2x", hashCode, imgNum + 65, DEPLOY_FILE_TYPE_GFX);
						
						sprintfHexCode64(hashcodeFileName, hashCode);
						sprintf(deployedFileName, "%s%c%2.2x", hashcodeFileName, imgNum + 65, DEPLOY_FILE_TYPE_GFX);
						
						imgNum++;
						fileNum++;
						
						char buf[MAX_STRING_LENGTH];
						sprintf(buf, "%s%s", deployFolderName, deployedFileName);
						GFX_WriteImage(buf, imageIn, sourceScreenWidth, destWidth, compressionType, isSheet);
					}
				}
				else
				{
					CSlrImageDummy *imageIn = GFX_ReadImage(buf);
					LOGD("%s width=%d height=%d", buf, imageIn->loadImgWidth, imageIn->loadImgHeight);
					//sprintf(deployedFileName, "%016llx%2.2x", hashCode, DEPLOY_FILE_TYPE_GFX);
					
					sprintfHexCode64(hashcodeFileName, hashCode);
					sprintf(deployedFileName, "%s%2.2x", hashcodeFileName, DEPLOY_FILE_TYPE_GFX);
					
					fileNum++;
					
					char buf[MAX_STRING_LENGTH];
					sprintf(buf, "%s%s", deployFolderName, deployedFileName);
					GFX_WriteImage(buf, imageIn, sourceScreenWidth, sourceScreenWidth, compressionType, isSheet);
				}
			}
			else
			{
				char src[MAX_STRING_LENGTH];
				sprintf(src, "%s%s", filesFolder, currentFileName);

				byte fileType = DEPLOY_FILE_TYPE_UNKNOWN;
				if (!strcmp(ext, "ogg") || !strcmp(ext, "OGG"))
				{
					fileType = DEPLOY_FILE_TYPE_OGG;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("OGG %s", src);
				}
				else if (!strcmp(ext, "anim") || !strcmp(ext, "ANIM"))
				{
					fileType = DEPLOY_FILE_TYPE_ANIM;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("ANIM %s", src);
				}
				else if (!strcmp(ext, "txt") || !strcmp(ext, "TXT"))
				{
					fileType = DEPLOY_FILE_TYPE_TXT;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("TXT %s", src);
				}
				else if (!strcmp(ext, "vec") || !strcmp(ext, "VEC"))
				{
					fileType = DEPLOY_FILE_TYPE_VEC;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("VEC %s", src);
				}
				else if (!strcmp(ext, "fnt") || !strcmp(ext, "font")
						 || !strcmp(ext, "FNT") || !strcmp(ext, "FONT"))
				{
					fileType = DEPLOY_FILE_TYPE_FONT;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("FONT %s", src);
				}
				else if (!strcmp(ext, "cnut") || !strcmp(ext, "CNUT"))
				{
					fileType = DEPLOY_FILE_TYPE_SQSCRIPT_SOURCE;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("CNUT %s", src);
				}
				else if (!strcmp(ext, "nut") || !strcmp(ext, "NUT"))
				{
					fileType = DEPLOY_FILE_TYPE_SQSCRIPT;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("NUT %s", src);
				}
				else if (!strcmp(ext, "xm") || !strcmp(ext, "XM"))
				{
					fileType = DEPLOY_FILE_TYPE_XM;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("XM %s", src);
				}
				else if (!strcmp(ext, "dat") || !strcmp(ext, "data")
						 || !strcmp(ext, "DAT") || !strcmp(ext, "DATA"))
				{
					fileType = DEPLOY_FILE_TYPE_DATA;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("DATA %s", src);
				}
				else if (!strcmp(ext, "csv") || !strcmp(ext, "CSV"))
				{
					fileType = DEPLOY_FILE_TYPE_CSV;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("CSV %s", src);
				}
				else if (!strcmp(ext, ""))
				{
					fileType = DEPLOY_FILE_TYPE_NOEXT;
					deployBuffer->putUnsignedShort(fileType);
					LOGM("NOEXT %s", src);
				}
				else
				{
					fileType = DEPLOY_FILE_TYPE_UNKNOWN;
					deployBuffer->putUnsignedShort(DEPLOY_FILE_TYPE_UNKNOWN);
					deployBuffer->putString(ext);
					LOGM("UNKNOWN %s", src);
				}

				//sprintf(deployedFileName, "%016llx%2.2x", hashCode, fileType);
				sprintfHexCode64(hashcodeFileName, hashCode);
				sprintf(deployedFileName, "%s%2.2X", hashcodeFileName, fileType);

				fileNum++;
				char buf[MAX_STRING_LENGTH];
				sprintf(buf, "%s%s", deployFolderName, deployedFileName);

				char cmd[MAX_STRING_LENGTH];
				sprintf(cmd, "cp %s %s", src, buf);
				LOGD(cmd);
				int ret = system(cmd);
				int status = WEXITSTATUS(ret);

				if (ret != 0 || status != 0)
				{
					SYS_FatalExit("System call '%s' failed (ret=%d status=%d)", cmd, ret, status);
				}
			}
		}

		char buf[MAX_STRING_LENGTH];
		sprintf(buf, "%sdeploy", deployFolderName);
		deployBuffer->storeToFile(buf);

		LOGM("Deploy file stored to: %s", buf);
		
		// debug:
		deployBuffer->Rewind();
		
		LOGM("Sanity checking deploy file:");
		RES_DeployFileLoad(deployBuffer, 600);
	}

	LOGM("All OK. Done!");

	return 0;							// Exit The Program
}

