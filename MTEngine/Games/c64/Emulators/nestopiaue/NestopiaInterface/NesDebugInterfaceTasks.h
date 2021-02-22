#ifndef _NESDEBUGINTERFACETASKS_H_
#define _NESDEBUGINTERFACETASKS_H_

#include "CDebugInterfaceTask.h"

class CSlrString;
class NesDebugInterface;

class NesDebugInterfaceTaskInsertCartridge : public CDebugInterfaceTask
{
public:
	NesDebugInterfaceTaskInsertCartridge(NesDebugInterface *debugInterface, CSlrString *pathToCart);
	~NesDebugInterfaceTaskInsertCartridge();
	
	NesDebugInterface *debugInterface;
	CSlrString *pathToCart;

	virtual void ExecuteTask();
};

class NesDebugInterfaceTaskReset : public CDebugInterfaceTask
{
public:
	NesDebugInterfaceTaskReset(NesDebugInterface *debugInterface);
	NesDebugInterface *debugInterface;
	virtual void ExecuteTask();
};

class NesDebugInterfaceTaskHardReset : public CDebugInterfaceTask
{
public:
	NesDebugInterfaceTaskHardReset(NesDebugInterface *debugInterface);
	NesDebugInterface *debugInterface;
	virtual void ExecuteTask();
};


#endif
