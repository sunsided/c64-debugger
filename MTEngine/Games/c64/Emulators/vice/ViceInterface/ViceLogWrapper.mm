#include "DBG_Log.h"

extern "C" {
#include "ViceLogWrapper.h"
}

void vice_wrapper_log_message(char *message)
{
	LOGVM(message);
}

void vice_wrapper_log_warning(char *message)
{
	LOGWarning(message);
}

void vice_wrapper_log_error(char *message)
{
	LOGError(message);
}

void vice_wrapper_log_debug(char *message)
{
	LOGVD(message);
}

void vice_wrapper_log_verbose(char *message)
{
	LOGVV(message);
}

void vice_wrapper_mt_debug(char *message)
{
	LOGD(message);
}

void vice_wrapper_mt_main(char *message)
{
	LOGM(message);
}

void vice_wrapper_mt_todo(char *message)
{
	LOGTODO(message);
}
