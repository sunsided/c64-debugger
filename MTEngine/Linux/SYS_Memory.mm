#include "SYS_Memory.h"
#include "DBG_Log.h"
#include <execinfo.h>
#include <sys/param.h>
#include <sys/times.h>
#include <sys/types.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <stdint.h>
#include <fstream>

#include <unistd.h>

size_t _LinuxGetTotalSystemMemory()
{
    long pages = sysconf(_SC_PHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);
    return pages * page_size;
}

uint64_t _LinuxGetFreeMem()
{
    uint64_t vm_size = 0;
    FILE *statm = fopen("/proc/self/statm", "r");
    if (!statm)
        return 0;
    if (fscanf(statm, "%ld", &vm_size) != 1)
    {
        fclose(statm);
        return 0;
    }
    vm_size = (vm_size + 1) * 1024;

    fclose(statm);

    rlimit lim;
    if (getrlimit(RLIMIT_AS, &lim) != 0)
        return 0;
    if (lim.rlim_cur <= vm_size)
        return 0;
    if (lim.rlim_cur >= 0xC000000000000000ull) // most systems cannot address more than 48 bits
        lim.rlim_cur  = 0xBFFFFFFFFFFFFFFFull;
    return lim.rlim_cur - vm_size;
}

void _LinuxProcess_mem_usage(double& vm_usage, double& resident_set)
{
   using std::ios_base;
   using std::ifstream;
   using std::string;

   vm_usage     = 0.0;
   resident_set = 0.0;

   // 'file' stat seems to give the most reliable results
   //
   ifstream stat_stream("/proc/self/stat",ios_base::in);

   // dummy vars for leading entries in stat that we don't care about
   //
   string pid, comm, state, ppid, pgrp, session, tty_nr;
   string tpgid, flags, minflt, cminflt, majflt, cmajflt;
   string utime, stime, cutime, cstime, priority, nice;
   string O, itrealvalue, starttime;

   // the two fields we want
   //
   unsigned long vsize;
   long rss;

   stat_stream >> pid >> comm >> state >> ppid >> pgrp >> session >> tty_nr
               >> tpgid >> flags >> minflt >> cminflt >> majflt >> cmajflt
               >> utime >> stime >> cutime >> cstime >> priority >> nice
               >> O >> itrealvalue >> starttime >> vsize >> rss; // don't care about the rest

   stat_stream.close();

   long page_size_kb = sysconf(_SC_PAGE_SIZE); // / 1024; // in case x86-64 is configured to use 2MB pages
   vm_usage     = vsize;	// / 1024.0
   resident_set = rss * page_size_kb;
}

u64 SYS_GetUsedMemory()
{
	double vm, rss;
	_LinuxProcess_mem_usage(vm, rss);

	//LOGMEM("MEMORY VM=%d RSS=%d", (int)vm, (int)rss);
	return rss;
}

u64 SYS_GetFreeMemory()
{
	return _LinuxGetFreeMem();
}

u64 SYS_GetTotalMemory()
{
	return _LinuxGetTotalSystemMemory();
}
