#ifndef _CGUIFOLDERFAVORITE_H_
#define _CGUIFOLDERFAVORITE_H_

class CGuiFolderFavorite
{
public:
	char *name;
	char *folderPath;
	
	CGuiFolderFavorite(char *name, char *folderPath) { this->name=name; this->folderPath=folderPath; };
};

#endif
        
