#include "SYS_CommandLine.h"
#include "SYS_Defs.h"

int sysArgc;
char **sysArgv;

std::vector<char *> sysCommandLineArguments;

// Warning: any console output here slows down startup by one second

void SYS_SetCommandLineArguments(int argc, char **argv)
{
	sysArgc = argc;
	sysArgv = argv;
	
	for (int i = 1; i < argc; i++)
	{
		sysCommandLineArguments.push_back(argv[i]);
	}
}

