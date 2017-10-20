#ifndef _CViewC64StateCPU_H_
#define _CViewC64StateCPU_H_

#include "CViewBaseStateCPU.h"

class CViewC64StateCPU : public CViewBaseStateCPU
{
public:
	CViewC64StateCPU(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);

	virtual void RenderRegisters();
	virtual void SetRegisterValue(StateCPURegister reg, int value);
	virtual int GetRegisterValue(StateCPURegister reg);	
};

#endif

