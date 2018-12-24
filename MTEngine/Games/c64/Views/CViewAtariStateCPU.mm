#include "CViewAtariStateCPU.h"
#include "SYS_Main.h"
#include "CSlrFont.h"
#include "CViewC64.h"
#include "AtariDebugInterface.h"

register_def atari_cpu_regs[7] = {
	{	STATE_CPU_REGISTER_PC,		0.0,  4 },
	{	STATE_CPU_REGISTER_A,		5.0,  2 },
	{	STATE_CPU_REGISTER_X,		8.0,  2 },
	{	STATE_CPU_REGISTER_Y,		11.0, 2 },
	{	STATE_CPU_REGISTER_SP,		14.0, 2 },
	{	STATE_CPU_REGISTER_FLAGS,	17.0, 8 },
	{	STATE_CPU_REGISTER_IRQ,		20.0, 2 }
};

CViewAtariStateCPU::CViewAtariStateCPU(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface)
: CViewBaseStateCPU(posX, posY, posZ, sizeX, sizeY, debugInterface)
{
	this->name = "CViewAtariStateCPU";
	
	this->numRegisters = 6;
	
	regs = (register_def*)&atari_cpu_regs;
}

void CViewAtariStateCPU::RenderRegisters()
{
	float px = this->posX;
	float py = this->posY;
	
	/// Atari CPU
	u16 pc;
	u8 a, x, y, flags, sp, irq;
	((AtariDebugInterface*)debugInterface)->GetCpuRegs(&pc, &a, &x, &y, &flags, &sp, &irq);
	
	
	char buf[128];
	strcpy(buf, "PC   AR XR YR SP NV-BDIZC  IRQ");

	font->BlitText(buf, px, py, -1, fontSize);
	py += fontSize;
	
	////////////////////////////
	// TODO: SHOW Atari CPU CYCLE
	//		Byte2Bits(diskCpuState.processorFlags, flags);
	//		sprintf(buf, "%4.4x %2.2x %2.2x %2.2x %2.2x %s  %2.2x",
	//				diskCpuState.pc, diskCpuState.a, diskCpuState.x, diskCpuState.y, (diskCpuState.sp & 0x00ff),
	//				flags, diskState.headTrackPosition);
	
	char *bufPtr = buf;
	sprintfHexCode16WithoutZeroEnding(bufPtr, pc); bufPtr += 5;
	sprintfHexCode8WithoutZeroEnding(bufPtr, a); bufPtr += 3;
	sprintfHexCode8WithoutZeroEnding(bufPtr, x); bufPtr += 3;
	sprintfHexCode8WithoutZeroEnding(bufPtr, y); bufPtr += 3;
	sprintfHexCode8WithoutZeroEnding(bufPtr, sp); bufPtr += 3;
	Byte2BitsWithoutEndingZero(flags, bufPtr); bufPtr += 10;
	*bufPtr = ' '; bufPtr += 1;
	sprintfHexCode8WithoutZeroEnding(bufPtr, irq); bufPtr += 3;
	
	font->BlitText(buf, px, py, -1, fontSize);
}

extern "C" {
	void c64d_atari_set_cpu_pc(u16 addr);
	void c64d_atari_set_cpu_reg_a(u8 val);
	void c64d_atari_set_cpu_reg_x(u8 val);
	void c64d_atari_set_cpu_reg_y(u8 val);
	void c64d_atari_set_cpu_reg_p(u8 val);
	void c64d_atari_set_cpu_reg_s(u8 val);
}


void CViewAtariStateCPU::SetRegisterValue(StateCPURegister reg, int value)
{
	debugInterface->LockMutex();
	
	
	switch (reg)
	{
		case STATE_CPU_REGISTER_PC:
			c64d_atari_set_cpu_pc(value);
			break;
		case STATE_CPU_REGISTER_A:
			c64d_atari_set_cpu_reg_a(value);
			break;
		case STATE_CPU_REGISTER_X:
			c64d_atari_set_cpu_reg_x(value);
			break;
		case STATE_CPU_REGISTER_Y:
			c64d_atari_set_cpu_reg_y(value);
			break;
		case STATE_CPU_REGISTER_SP:
			c64d_atari_set_cpu_reg_s(value);
			break;
		case STATE_CPU_REGISTER_FLAGS:
			c64d_atari_set_cpu_reg_p(value);
			break;
		case STATE_CPU_REGISTER_NONE:
		default:
			return;
	}
	debugInterface->UnlockMutex();
}

int CViewAtariStateCPU::GetRegisterValue(StateCPURegister reg)
{
	LOGD("CViewAtariStateCPU::GetRegisterValue: reg=%d", reg);
	
	u16 pc;
	u8 a, x, y, flags, sp, irq;
	((AtariDebugInterface*)debugInterface)->GetCpuRegs(&pc, &a, &x, &y, &flags, &sp, &irq);

	switch (reg)
	{
		case STATE_CPU_REGISTER_PC:
			return pc;
		case STATE_CPU_REGISTER_A:
			return a;
		case STATE_CPU_REGISTER_X:
			return x;
		case STATE_CPU_REGISTER_Y:
			return y;
		case STATE_CPU_REGISTER_SP:
			return sp;
		case STATE_CPU_REGISTER_FLAGS:
			return flags;
		case STATE_CPU_REGISTER_IRQ:
			return irq;
		case STATE_CPU_REGISTER_NONE:
		default:
			return -1;
	}

	return 0x00FA;
}

