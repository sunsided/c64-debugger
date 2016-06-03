/*
 *  SYS_CFileSystem.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-20.
 *  Copyright 2009. All rights reserved.
 *
 */

#include "SYS_GetFilesFromDirectory.h"
#include <stdio.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <algorithm>
#include <functional>
#include <string.h>
#include <cstring>

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

std::vector<CFileItem *> *SYS_GetFilesFromDirectory(UTFString *directoryPathOrig)
{
	LOGD("CFileSystem::GetFiles: directoryPath=%s", directoryPathOrig);
	char directoryPath[2048];
	sprintf(directoryPath, "%s", directoryPathOrig);

	u32 l = strlen(directoryPath)-1;
	if (directoryPath[l] != '/')
	{
		l++;
		directoryPath[l++] = '/';
		directoryPath[l] = 0x00;
	}

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
    	LOGD("d_name=%s", buf);
    	struct stat st;
    	lstat(buf, &st);

    	if (S_ISDIR(st.st_mode))
    	{
    		LOGD("<DIR> %s", dirp->d_name);

    		UTFString *fileNameDup = strdup(dirp->d_name);
			UTFString *modDateDup = strdup("");

			CFileItem *item = new CFileItem(fileNameDup, modDateDup, true);
			files->push_back(item);
    	}
    	else if (dirp->d_type == DT_REG || dirp->d_type == DT_UNKNOWN)
		{
			UTFString *fileNameDup = strdup(dirp->d_name);
			UTFString *modDateDup = strdup("");

			CFileItem *item = new CFileItem(fileNameDup, modDateDup, false);
			files->push_back(item);
		}
    }

    closedir(dp);

	std::sort(files->begin(), files->end(), compare_CFileItem_nocase);

	LOGD("CFileSystem::GetFiles done");

	return files;
}
