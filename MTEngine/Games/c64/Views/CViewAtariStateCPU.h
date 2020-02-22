#ifndef _CViewAtariStateCPU_H_
#define _CViewAtariStateCPU_H_

#include "CViewBaseStateCPU.h"

class AtariDebugInterface;

class CViewAtariStateCPU : public CViewBaseStateCPU
{
public:
	CViewAtariStateCPU(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface);
	
	virtual void RenderRegisters();
	virtual void SetRegisterValue(StateCPURegister reg, int value);
	virtual int GetRegisterValue(StateCPURegister reg);
};



#endif

