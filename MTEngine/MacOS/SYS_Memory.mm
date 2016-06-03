#include "SYS_Memory.h"
#include "DBG_Log.h"
#import "mach/mach.h"

u64 SYS_GetUsedMemory()
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (u64)((kerr == KERN_SUCCESS) ? info.resident_size : 0); // size in bytes
}

u64 SYS_GetFreeMemory()
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
	
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return (u64)(vm_stat.free_count * pagesize);
}

u64 SYS_GetTotalMemory()
{
	mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
	
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
	
	natural_t mem_used = (vm_stat.active_count +
						  vm_stat.inactive_count +
						  vm_stat.wire_count) * pagesize;
	natural_t mem_free = vm_stat.free_count * pagesize;
	natural_t mem_total = mem_used + mem_free;
	
    return (u64)mem_total;
}

