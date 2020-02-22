#include "CBitBuffer.h"

CBitBuffer::CBitBuffer()
{
	this->data = new byte[1024];
	//this->maxSize = 1024;
}

//void CBitBuffer::WriteBits(int value, int bits)
//{
//	int i;
//	
//	if (this->maxSize - this->curSize < 4)
//	{
//		// auto resize?
//		this->overflowed = true;
//		return;
//	}
//	
//	if (bits == 0 || bits < -31 || bits > 32)
//	{
//		LOGError("Bad WriteBits: %i", bits);
//		return;
//	}
//	
//	// check for overflows
//	if (bits != 32)
//	{
//		if (bits > 0)
//		{
//			if (value > (( 1 << bits ) -1) || value < 0)
//			{
//				LOGError("overflows(1)");
//				//overflows++;
//			}
//		}
//		else
//		{
//			int r;
//			
//			r = 1 << (bits-1);
//			
//			if (value > r-1 || value < -r)
//			{
//				LOGError("overflows(2)");
//				//overflows++;
//			}
//		}
//	}
//}

void CBitBuffer::AddBit(byte bit) 
{                                                                      
	if ((bloc&7) == 0) 
	{
		data[(bloc>>3)] = 0;
	}                                                                                                         
	data[(bloc>>3)] |= bit << (bloc&7);                                                                       
	bloc++;                                                                                                   
}                                                                                                                 

byte CBitBuffer::GetBit()
{
	int t;
	t = (data[(bloc>>3)] >> (bloc&7)) & 0x1;
	bloc++;
	return t;
}

