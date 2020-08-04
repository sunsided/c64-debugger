#ifndef _CViewNesStateCPU_H_
#define _CViewNesStateCPU_H_

#include "CViewBaseStateCPU.h"

class NesDebugInterface;

class CViewNesStateCPU : public CViewBaseStateCPU
{
public:
	CViewNesStateCPU(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, NesDebugInterface *debugInterface);
	
	virtual void RenderRegisters();
	virtual void SetRegisterValue(StateCPURegister reg, int value);
	virtual int GetRegisterValue(StateCPURegister reg);
};



#endif

