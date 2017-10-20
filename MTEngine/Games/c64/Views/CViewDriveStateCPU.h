#ifndef _CViewDriveStateCPU_H_
#define _CViewDriveStateCPU_H_

#include "CViewBaseStateCPU.h"

class CViewDriveStateCPU : public CViewBaseStateCPU
{
public:
	CViewDriveStateCPU(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	
	virtual void RenderRegisters();
	virtual void SetRegisterValue(StateCPURegister reg, int value);
	virtual int GetRegisterValue(StateCPURegister reg);
};



#endif

