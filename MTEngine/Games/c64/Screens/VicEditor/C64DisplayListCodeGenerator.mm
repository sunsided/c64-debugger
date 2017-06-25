#include "C64DisplayListCodeGenerator.h"
#include "C64DebugInterface.h"
#include "CViewVicEditor.h"
#include "CViewDisassemble.h"
#include "CViewC64.h"

// THIS IS START OF POC, not used

#define B(b) dataAdapter->AdapterWriteByte(addr++, (b))
#define A(b) strcpy(buf, (b)); addr += viewDisassemble->Assemble(addr, (buf));

void C64GenerateDisplayListCode(CViewVicEditor *vicEditor)
{
	LOGD("C64GenerateDisplayListCode");

	C64DebugInterface *debugInterface = vicEditor->viewVicDisplayMain->debugInterface;
	CSlrDataAdapter *dataAdapter = debugInterface->dataAdapterC64;

	// TODO: move Assemble from view to specific assemble class in C64DebugInterface / MemoryAdapter
	CViewDisassemble *viewDisassemble = viewC64->viewC64Disassemble;

	char buf[128];
	
	u16 addr = 0x0801;

	// BASIC
	B(	0x00	);
	B(	0x00	);
	
	// Init CODE
	A(	"SEI"	);
	A(	"NOP"	);
	A(	"NOP"	);
	A(	"NOP"	);

	
	LOGD("C64GenerateDisplayListCode done");
}
