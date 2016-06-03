#ifndef _BIT_BUFFER_H_
#define _BIT_BUFFER_H_

#include "SYS_Defs.h"

class CBitBuffer
{
public:
	CBitBuffer();
	~CBitBuffer();
	
	byte *data;
	
	int bloc;
	void AddBit(byte bit);
	byte GetBit();
	
};

#endif

