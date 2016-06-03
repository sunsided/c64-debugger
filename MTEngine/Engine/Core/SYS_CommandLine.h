#ifndef _SYS_COMMANDLINE_H_
#define _SYS_COMMANDLINE_H_

#include <vector>
extern std::vector<char *> sysCommandLineArguments;

extern int sysArgc;
extern char **sysArgv;

void SYS_SetCommandLineArguments(int argc, char **argv);

#endif
