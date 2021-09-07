#include "NesDebugInterfaceTasks.h"
#include "NesWrapper.h"
#include "NesDebugInterface.h"
#include "CSnapshotsManager.h"
#include "CSlrString.h"

NesDebugInterfaceTaskInsertCartridge::NesDebugInterfaceTaskInsertCartridge(NesDebugInterface *debugInterface, CSlrString *pathToCart)
{
	this->debugInterface = debugInterface;
	this->pathToCart = new CSlrString(pathToCart);
}
NesDebugInterfaceTaskInsertCartridge::~NesDebugInterfaceTaskInsertCartridge()
{
	delete this->pathToCart;
}

void NesDebugInterfaceTaskInsertCartridge::ExecuteTask()
{
	char *cPathToCart = this->pathToCart->GetStdASCII();
	bool ret = nesd_insert_cartridge(cPathToCart);

	delete cPathToCart;
	
	debugInterface->ResetEmulationFrameCounter();
	debugInterface->ResetClockCounters();
	debugInterface->snapshotsManager->ClearSnapshotsHistory();
}

//
NesDebugInterfaceTaskReset::NesDebugInterfaceTaskReset(NesDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
}

void NesDebugInterfaceTaskReset::ExecuteTask()
{
	nesd_reset();
}

//
NesDebugInterfaceTaskHardReset::NesDebugInterfaceTaskHardReset(NesDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
}

void NesDebugInterfaceTaskHardReset::ExecuteTask()
{
	nesd_reset();
	
	debugInterface->ResetEmulationFrameCounter();
	debugInterface->ResetClockCounters();
	debugInterface->snapshotsManager->ClearSnapshotsHistory();
}

