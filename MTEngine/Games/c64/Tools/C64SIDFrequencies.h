#include "SYS_Defs.h"

//
typedef struct sid_frequency_s
{
	const char *name;
	float frequency;
	int sidValue;
} sid_frequency_t;

void SID_FrequenciesInit();
const sid_frequency_t *SidValueToNote(uint16 sidValue);

