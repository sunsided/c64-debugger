/*
 *  SYS_CFileSystem.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __SYS_GET_FILES_FROM_DIR_H__
#define __SYS_GET_FILES_FROM_DIR_H__

#include "./../../SYS_Main.h"
#include "./../../SYS_Defs.h"
#define UTFString char
#include <list>
#include <vector>

#define MAX_FILENAME_LENGTH 512

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

std::vector<CFileItem *> *SYS_GetFilesFromDirectory(UTFString *directoryPath);

#endif

//__SYS_GET_FILES_FROM_DIR_H__
