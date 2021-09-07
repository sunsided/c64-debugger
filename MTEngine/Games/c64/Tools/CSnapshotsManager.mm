#include "CSnapshotsManager.h"
#include "SYS_Threading.h"
#include "VID_Main.h"
#include "CGuiMain.h"
#include "SND_SoundEngine.h"
#include "C64SettingsStorage.h"

#include "M_Circlebuf.h"

// TODO: rewriting map frame snapshot...  (?)
// DONE?: attach regular snapshots -> clear rewind data
// DONE?: store roms on cart change
// TODO: what to do with REU?

//CPU JAM - un-jam when rewind ?
//DONE?: DUMP all snapshots & history => fix problem with cycle on frame# change

// this is to debug snapshots manager, as it is quite heavy it normally should be switched off
//#undef LOGS
#define LOGS LOGD
#define LOGS {}

CStoredSnapshot::CStoredSnapshot(CSnapshotsManager *manager)
{
	this->manager = manager;
	byteBuffer = new CByteBuffer();

	this->frame = -1;
	this->cycle = -1;
}

CStoredSnapshot::~CStoredSnapshot()
{
}

void CStoredSnapshot::Use(u32 frame, u64 cycle)
{
	this->frame = frame;
	this->cycle = cycle;
}

void CStoredSnapshot::ClearSnapshot()
{
	this->frame = -1;
	this->cycle = -1;
	byteBuffer->Clear();
}

CStoredDiskSnapshot::CStoredDiskSnapshot(CSnapshotsManager *manager, u32 frame, u64 cycle)
: CStoredSnapshot(manager)
{
	numLinkedChipsSnapshots = 0;
	
	this->Use(frame, cycle);
}

void CStoredDiskSnapshot::AddReference()
{
	this->numLinkedChipsSnapshots++;
}

void CStoredDiskSnapshot::RemoveReference()
{
//	LOGD("CStoredDiskSnapshot::RemoveReference: numLinkedChipsSnapshots=%d", numLinkedChipsSnapshots);
	this->numLinkedChipsSnapshots--;

//	manager->DebugPrintDiskSnapshots();
	
	if (this->numLinkedChipsSnapshots == 0)
	{
		LOGD("CStoredDiskSnapshot::RemoveReference linked=0, Clear");
		manager->diskSnapshotsByFrame.erase(this->frame);
		manager->diskSnapshotsToReuse.push_back(this);
		this->ClearSnapshot();
	}

//	LOGD("CStoredDiskSnapshot::RemoveReference finished: numLinkedChipsSnapshots=%d", numLinkedChipsSnapshots);
}


CStoredChipsSnapshot::CStoredChipsSnapshot(CSnapshotsManager *manager, u32 frame, u64 cycle, CStoredDiskSnapshot *diskSnapshot)
: CStoredSnapshot(manager)
{
	this->Use(frame, cycle, diskSnapshot);
}

void CStoredChipsSnapshot::Use(u32 frame, u64 cycle, CStoredDiskSnapshot *diskSnapshot)
{
	this->frame = frame;
	this->cycle = cycle;
	this->diskSnapshot = diskSnapshot;
	this->diskSnapshot->AddReference();
}


void CStoredChipsSnapshot::ClearSnapshot()
{
	if (this->diskSnapshot)
	{
		this->diskSnapshot->RemoveReference();
	}
}

CSnapshotsManager::CSnapshotsManager(CDebugInterface *debugInterface)
{
	this->mutex = new CSlrMutex("CSnapshotsManager");
	this->debugInterface = debugInterface;
	
	currentDiskSnapshot = NULL;
	snapshotToRestore = NULL;

	lastStoredFrame = 0;
	ResetLastStoredFrameCounter();
	
	// pause on frame num
	pauseNumCycle = -1;
	pauseNumFrame = -1;
	skipFrameRender = false;
	
	isPerformingSnapshotRestore = false;
//	skipSavingSnapshots = false;
	
	LOGD("CSnapshotsManager::CSnapshotsManager: snapshotsIntervalInFrames=%d snapshotsLimit=%d",
		 c64SettingsSnapshotsIntervalNumFrames, c64SettingsSnapshotsLimit);
}

CSnapshotsManager::~CSnapshotsManager()
{
}

void CSnapshotsManager::ResetLastStoredFrameCounter()
{
	lastStoredFrameCounter = c64SettingsSnapshotsIntervalNumFrames-1;
}

void CSnapshotsManager::CancelRestore()
{
	LockMutex();
	snapshotToRestore = NULL;
	isPerformingSnapshotRestore = false;
	pauseNumFrame = -1;
	pauseNumCycle = -1;
	skipFrameRender = false;
	UnlockMutex();

	debugInterface->RefreshScreenNoCallback();
}

// CheckSnapshotInterval should be run each frame from within code that can store snapshots,
// check if we are exactly in a new frame cycle should be done by the caller
bool CSnapshotsManager::CheckSnapshotInterval()
{
	LOGS("CSnapshotsManager::CheckSnapshotInterval: pauseNumCycle=%d currentCycle=%d", pauseNumCycle, debugInterface->GetMainCpuCycleCounter());
	
	if (snapshotToRestore || pauseNumCycle != -1) // || skipSavingSnapshots)
	{
		LOGS("snapshotToRestore=%x pauseNumCycle=%d", snapshotToRestore, pauseNumCycle);
		return false;
	}
	
	u32 currentFrame = debugInterface->GetEmulationFrameNumber();
	
	if (pauseNumFrame == currentFrame)
	{
		LOGD("CSnapshotsManager::CheckSnapshotInterval: pauseNumFrame == currentFrame");
		debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
		pauseNumFrame = -1;
		skipFrameRender = false;
		debugInterface->RefreshScreenNoCallback();
		isPerformingSnapshotRestore = false;
		return false;
	}

	if (c64SettingsSnapshotsRecordIsActive == false)
		return false;

	lastStoredFrameCounter++;
	
	// check if we should store snapshot (the frame interval is hit)
	if (lastStoredFrameCounter >= c64SettingsSnapshotsIntervalNumFrames)
	{
		LOGS("CSnapshotsManager::CheckSnapshotInterval: LockMutex");
		this->LockMutex();
		
		if (snapshotToRestore == NULL)
		{
			LOGS("CSnapshotsManager::CheckSnapshotInterval: snapshotToRestore=NULL");

			isPerformingSnapshotRestore = false;
			lastStoredFrameCounter = 0;
			
			u64 currentCycle = debugInterface->GetMainCpuCycleCounter();
			
			LOGS("CSnapshotsManager::CheckSnapshotInterval: store snapshot, currentFrame=%d", currentFrame);
			lastStoredFrame = currentFrame;
			
			long t1 = SYS_GetCurrentTimeInMillis();
			
			// we are in CPU interrupt check, we can safely store snapshot now
			if (currentDiskSnapshot == NULL
				|| debugInterface->IsDriveDirtyForSnapshot())
			{
//				LOGD("....... create new disk snapshot");
				CStoredDiskSnapshot *diskSnapshot = GetNewDiskSnapshot(currentFrame, currentCycle);
				if (diskSnapshot == NULL)
				{
					LOGError("CSnapshotsManager::CheckSnapshotInterval failed");
					this->UnlockMutex();
					return false;
				}
				
				// store disk snapshot now, in a synced manner
				debugInterface->SaveDiskDataSnapshotSynced(diskSnapshot->byteBuffer);
				
				//	TODO: add int save_chips and store only disk GCR data      <- nope don't do this
				//int drive_snapshot_write_module(snapshot_t *s, int save_disks, int save_roms)
				
				debugInterface->ClearDriveDirtyForSnapshotFlag();
				
				currentDiskSnapshot = diskSnapshot;
				diskSnapshotsByFrame[currentFrame] = diskSnapshot;
				
//				DebugPrintDiskSnapshots();
			}
			
			CStoredChipsSnapshot *chipSnapshot = GetNewChipSnapshot(currentFrame, currentCycle, currentDiskSnapshot);
			
			if (chipSnapshot == NULL)
			{
				LOGError("CSnapshotsManager::CheckSnapshotInterval failed");
				this->UnlockMutex();
				return false;
			}
			
			// store snapshot now, in a synced manner
			debugInterface->SaveChipsSnapshotSynced(chipSnapshot->byteBuffer);
			
			chipSnapshotsByFrame[currentFrame] = chipSnapshot;
			
//			DebugPrintChipsSnapshots();
			
			long t2 = SYS_GetCurrentTimeInMillis();
			
//			LOGD("CSnapshotsManager stored snapshot t=%d", t2-t1);
		}
		
		LOGS("CSnapshotsManager::CheckSnapshotInterval: UnlockMutex");

		this->UnlockMutex();
		
		return true;
	}
	
	// snapshot not stored
	return false;
}

void CSnapshotsManager::StoreSnapshot()
{
	
}

void CSnapshotsManager::RestoreSnapshot(CStoredChipsSnapshot *snapshot)
{
	LOGS("CSnapshotsManager::RestoreSnapshot (set snapshotToRestore only)");
	this->LockMutex();

	snapshotToRestore = snapshot;
	
	this->UnlockMutex();

	LOGS("CSnapshotsManager::RestoreSnapshot done");
}

bool CSnapshotsManager::CheckMainCpuCycle()
{
//	LOGD("CSnapshotsManager::CheckMainCpuCycle prev clk=%d now clk=%d", debugInterface->GetPreviousCpuInstructionCycleCounter(), debugInterface->GetMainCpuCycleCounter());
	
	if (snapshotToRestore)
		return false;
	
	if (pauseNumCycle == -1)
		return false;

	u64 currentCycle = debugInterface->GetMainCpuCycleCounter();

//	LOGD("previous_instr_maincpu_clk=%d pauseNumCycle=%d maincpu_clk=%d", debugInterface->GetPreviousCpuInstructionCycleCounter(), pauseNumCycle, currentCycle);
	
	if (pauseNumCycle <= currentCycle)
	{
		if (pauseNumCycle != currentCycle)
		{
			LOGError("Could not hit cycle %d, now we are at %d", pauseNumCycle, currentCycle);
		}
		
		LOGD("STOP: pauseNumCycle=%d currentCycle=%d frame=%d", pauseNumCycle, currentCycle, debugInterface->GetEmulationFrameNumber());
		debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
		pauseNumCycle = -1;
		pauseNumFrame = -1;
		skipFrameRender = false;
		debugInterface->RefreshScreenNoCallback();
		isPerformingSnapshotRestore = false;
		return true;
	}
	
	return false;
}

extern "C" {
	void c64d_reset_sound_clk();
}

bool CSnapshotsManager::CheckSnapshotRestore()
{
//	LOGD("CSnapshotsManager::CheckSnapshotRestore");
	this->LockMutex();

//	LOGD("CSnapshotsManager::CheckSnapshotRestore: after LockMutex");

	if (snapshotToRestore)
	{
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!! RESTORING SNAPSHOT frame=%d cycle=%d", snapshotToRestore->frame, snapshotToRestore->cycle);
		
		gSoundEngine->LockMutex("CSnapshotsManager::CheckSnapshotRestore: restore snapshot");

		// restore disk
		CStoredDiskSnapshot *diskSnapshot = snapshotToRestore->diskSnapshot;
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!!     -> diskSnapshot frame=%d", diskSnapshot->frame);
		debugInterface->LoadDiskDataSnapshotSynced(diskSnapshot->byteBuffer);
		
		// restore chips
		debugInterface->LoadChipsSnapshotSynced(snapshotToRestore->byteBuffer);
		
		snapshotToRestore = NULL;
		
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!!     restored, currentFrame=%d pauseNumFrame=%d currentCycle=%d", debugInterface->GetEmulationFrameNumber(), pauseNumFrame, debugInterface->GetMainCpuCycleCounter());

		if (pauseNumFrame == -1 && pauseNumCycle == -1)
		{
			isPerformingSnapshotRestore = false;
		}

		c64d_reset_sound_clk();
		
		gSoundEngine->UnlockMutex("CSnapshotsManager::CheckSnapshotRestore: restore snapshot");

		LOGD("CSnapshotsManager::CheckSnapshotRestore: UnlockMutex (1)");

		this->UnlockMutex();
		
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!      SNAPSHOT RESTORED / FINISHED");
		return true;
	}
	
//	LOGD("CSnapshotsManager::CheckSnapshotRestore: UnlockMutex (2)");
	this->UnlockMutex();
	return false;
}

// @returns false=snapshot was not found, not possible to restore. cycleNum is optional, if -1 only frame will be searched.
bool CSnapshotsManager::RestoreSnapshotByFrame(int frame, long cycleNum)
{
	LOGD("RestoreSnapshotByFrame: frame=%d cycle=%d, LockMutex", frame, cycleNum);
	this->LockMutex();

	if (snapshotToRestore)
	{
		LOGS("RestoreSnapshotByFrame: UnlockMutex (1)");
		this->UnlockMutex();
		return false;
	}
	
	if (chipSnapshotsByFrame.empty())
	{
		LOGS("RestoreSnapshotByFrame: UnlockMutex (2)");
		this->UnlockMutex();
		return false;
	}

	LOGS("***** CSnapshotsManager::RestoreSnapshotByFrame frame=%d ***", frame);

	isPerformingSnapshotRestore = true;

	int minFrame, maxFrame;
	GetFramesLimits(&minFrame, &maxFrame);
	
	if (frame <= minFrame)
		frame = minFrame + 1;
	
	///////
	CStoredChipsSnapshot *nearestChipSnapshot = NULL;

	std::map<u32, CStoredChipsSnapshot *>::iterator it = chipSnapshotsByFrame.begin();

	//if (frame == 0)
	{
		nearestChipSnapshot = it->second;
	}
	
	// find nearest snapshot, just go through list now. TODO: optimize this
	int nearestChipSnapshotDist = INT_MAX;
	for( ; it != chipSnapshotsByFrame.end(); it++)
	{
		CStoredChipsSnapshot *chipSnapshot = it->second;
		
		// TODO BUG: when scrubbing to exact frame we need to be able to restore snapshot immediately, so we have to restore to previous one
		// (note, this does not affect C64). wrong, this may lock the emulation engine due to threads chase. workaround for now.
//#if defined(RUN_COMMODORE64)
//		if (chipSnapshot->frame <= frame)
//#else
		if (chipSnapshot->frame < frame)
//#endif
		{
			int d2 = frame - chipSnapshot->frame;
			if (d2 >= 0 && d2 < nearestChipSnapshotDist)
			{
				nearestChipSnapshot = chipSnapshot;
				nearestChipSnapshotDist = d2;
			}
		}
	}
	////////////
	
	if (nearestChipSnapshot != NULL)
	{
		LOGS(".... found snapshot frame %d", nearestChipSnapshot->frame);
		snapshotToRestore = nearestChipSnapshot;
	}
	
	lastStoredFrameCounter = 0;
	
	if (pauseNumFrame != -1 || debugInterface->GetDebugMode() == DEBUGGER_MODE_PAUSED)
	{
		LOGS("nearestChipSnapshot->frame=%d frame=%d", nearestChipSnapshot->frame, frame);
		if (nearestChipSnapshot->frame < frame)
		{
			LOGS("......... nearestChipSnapshot->frame=%d but we are looking for %d", nearestChipSnapshot->frame, frame);
			
			if (cycleNum == -1)
			{
				// do not go to cycle
				pauseNumCycle = -1;
				pauseNumFrame = frame;
			}
			else
			{
				// go to cycle
				pauseNumCycle = cycleNum;
				pauseNumFrame = -1;
			}
			
			debugInterface->SetDebugMode(DEBUGGER_MODE_RUNNING);
			
			CStoredChipsSnapshot *lastChipsSnapshot = (--chipSnapshotsByFrame.end())->second;
			if (lastChipsSnapshot->frame + c64SettingsSnapshotsIntervalNumFrames < frame)
			{
				// do not skip render
			}
			else
			{
				skipFrameRender = true;
			}
		}
		else
		{
			LOGS("... found frame, going to cycle cycleNum=%d", cycleNum);
			if (cycleNum == -1)
			{
//#if defined(RUN_COMMODORE64)
//				// TODO BUG: we can't restore exact frame, the code below restores synchronously, although we are paused we are not sure if we are in a situation that we can restore snapshot synchronously
//				skipFrameRender = false;
//				pauseNumCycle = -1;
//				pauseNumFrame = -1;
//				// restore snapshot immediately
//				this->CheckSnapshotRestore();
//				debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
//				isPerformingSnapshotRestore = false;
//#else
				// TODO BUG: this below does not work now and thus we can't restore to exact frame, TODO: allow restore to exact frame
				// just run one cycle, we are already where we should be
				skipFrameRender = true;
				pauseNumCycle = -1;
				
				// BUG: note this does not restore correctly and sometimes does not stop at all
				pauseNumFrame = frame;
				debugInterface->SetDebugMode(DEBUGGER_MODE_RUNNING);
//#endif
			}
			else
			{
				skipFrameRender = true;
				pauseNumCycle = cycleNum;
				pauseNumFrame = -1;
				debugInterface->SetDebugMode(DEBUGGER_MODE_RUNNING);
			}
		}
	}
	
	LOGS("RestoreSnapshotByFrame: UnlockMutex (3)");
	this->UnlockMutex();

	return true;
}

bool CSnapshotsManager::IsPerformingSnapshotRestore()
{
	// ??
	if (this->isPerformingSnapshotRestore && debugInterface->GetDebugMode() != DEBUGGER_MODE_RUNNING)
	{
		LOGError("isPerformingSnapshotRestore && debugMode=%d, frame=%d pauseNumFrame=%d pauseNumCycle=%d", debugInterface->GetDebugMode(),
				 debugInterface->GetEmulationFrameNumber(), pauseNumFrame, pauseNumCycle);
		
		if (pauseNumFrame != -1 && pauseNumFrame < debugInterface->GetEmulationFrameNumber())
		{
			debugInterface->SetDebugMode(DEBUGGER_MODE_RUNNING);
		}
		if (pauseNumCycle != -1 && pauseNumCycle < debugInterface->GetMainCpuCycleCounter())
		{
			debugInterface->SetDebugMode(DEBUGGER_MODE_RUNNING);
		}
	}
	
	return this->isPerformingSnapshotRestore;
}

CStoredChipsSnapshot *CSnapshotsManager::GetNewChipSnapshot(u32 frame, u64 cycle, CStoredDiskSnapshot *diskSnapshot)
{
	LOGS("*************************** CSnapshotsManager::GetNewChipSnapshot: frame=%d        << CHIPS", frame);

//	LOGD("chipSnapshotsByFrame=%d chipSnapshotsLimit=%d chipsSnapshotsToReuse=%d", chipSnapshotsByFrame.size(), c64SettingsSnapshotsLimit, chipsSnapshotsToReuse.size());
//	LOGD("diskSnapshotsByFrame=%d diskSnapshotsToReuse=%d", diskSnapshotsByFrame.size(), diskSnapshotsToReuse.size());
	
	CStoredChipsSnapshot *chipSnapshot = NULL;
	
	std::map<u32, CStoredChipsSnapshot *>::iterator it = chipSnapshotsByFrame.find(frame);

	if (it == chipSnapshotsByFrame.end())
	{
		int f = chipSnapshotsByFrame.size();
		
		if (f < c64SettingsSnapshotsLimit)
		{
//			LOGD("...create new CStoredChipsSnapshot");
			// create new
			chipSnapshot = new CStoredChipsSnapshot(this, frame, cycle, diskSnapshot);
			if (chipSnapshot == NULL)
			{
				LOGError("CSnapshotsManager::GetNewChipSnapshot: failed");
				return NULL;
			}
		}
		else
		{
//			LOGD("...reuse CStoredChipsSnapshot chipsSnapshotsToReuse.size=%d", chipsSnapshotsToReuse.size());
			int s = chipsSnapshotsToReuse.size();

//			LOGD("s=%d", s);
			
			if (s == 0)
			{
				it = chipSnapshotsByFrame.begin();
				chipSnapshot = it->second;
				chipSnapshotsByFrame.erase(chipSnapshot->frame);
			}
			else
			{
				chipSnapshot = chipsSnapshotsToReuse.front();
				chipsSnapshotsToReuse.pop_front();
			}
			chipSnapshot->ClearSnapshot();
			chipSnapshot->Use(frame, cycle, diskSnapshot);

		}
	}
	else
	{
		chipSnapshot = it->second;
		chipSnapshotsByFrame.erase(chipSnapshot->frame);
		chipSnapshot->ClearSnapshot();
		chipSnapshot->Use(frame, cycle, diskSnapshot);
	}

//	LOGD("CSnapshotsManager::GetNewChipSnapshot: done");
	return chipSnapshot;
}

CStoredDiskSnapshot *CSnapshotsManager::GetNewDiskSnapshot(u32 frame, u64 cycle)
{
	LOGS("*************************** CSnapshotsManager::GetNewDiskSnapshot: frame=%d        << DISK", frame);
//	LOGD("diskSnapshotsToReuse=%d", diskSnapshotsToReuse.size());
	
	CStoredDiskSnapshot *diskSnapshot = NULL;
	
	if (diskSnapshotsToReuse.size() == 0)
	{
//		LOGD("...create new CStoredDiskSnapshot");
		// create new
		diskSnapshot = new CStoredDiskSnapshot(this, frame, cycle);
		if (diskSnapshot == NULL)
		{
			LOGError("CSnapshotsManager::GetNewChipSnapshot: failed");
			return NULL;
		}
	}
	else
	{
//		LOGD("...reuse CStoredDiskSnapshot");
		diskSnapshot = diskSnapshotsToReuse.front();
		
		diskSnapshotsToReuse.pop_front();

		diskSnapshot->ClearSnapshot();
		diskSnapshot->Use(frame, cycle);
	}
	
//	LOGD("CSnapshotsManager::GetNewDiskSnapshot: done");
	return diskSnapshot;
}

void CSnapshotsManager::ClearSnapshotsHistory()
{
	// this will completely remove all history, used when new PRG is loaded or cart is inserted/detached
	LOGD("CSnapshotsManager::ClearSnapshotsHistory");
	
	this->LockMutex();
//	LOGD("CSnapshotsManager::ClearSnapshotsHistory: locked");
	
	snapshotToRestore = NULL;
	currentDiskSnapshot = NULL;
	
	for (std::map<u32, CStoredDiskSnapshot *>::iterator it = diskSnapshotsByFrame.begin(); it != diskSnapshotsByFrame.end(); it++)
	{
		CStoredDiskSnapshot *diskSnapshot = it->second;
		diskSnapshot->numLinkedChipsSnapshots = 0;
		diskSnapshotsToReuse.push_back(diskSnapshot);
	}
	diskSnapshotsByFrame.clear();

	for (std::map<u32, CStoredChipsSnapshot *>::iterator it = chipSnapshotsByFrame.begin(); it != chipSnapshotsByFrame.end(); it++)
	{
		CStoredChipsSnapshot *chipsSnapshot = it->second;
		chipsSnapshot->diskSnapshot = NULL;
		chipsSnapshot->ClearSnapshot();
		chipsSnapshotsToReuse.push_back(chipsSnapshot);
	}
	chipSnapshotsByFrame.clear();

	ResetLastStoredFrameCounter();
	
	pauseNumCycle = -1;
	pauseNumFrame = -1;
	skipFrameRender = false;

//	LOGD("CSnapshotsManager::ClearSnapshotsHistory: unlock");
	this->UnlockMutex();
}

void CSnapshotsManager::RestoreSnapshotByNumFramesOffset(int numFramesOffset)
{
	LOGD("CSnapshotsManager::RestoreSnapshotByNumFramesOffset: numFramesOffset=%d", numFramesOffset);
	this->LockMutex();
	
	LOGD("CSnapshotsManager::RestoreSnapshotByNumFramesOffset: locked");
	int currentFrame = debugInterface->GetEmulationFrameNumber();
	int restoreToFrame = currentFrame + numFramesOffset;
	
	int minFrame, maxFrame;
	GetFramesLimits(&minFrame, &maxFrame);
	
	if (restoreToFrame <= minFrame)
		restoreToFrame = minFrame + 1;
	
	LOGD(">>>>>>>>>................ currentFrame=%d restoreToFrame=%d", currentFrame, restoreToFrame);
	debugInterface->snapshotsManager->RestoreSnapshotByFrame(restoreToFrame, -1);

	LOGD("CSnapshotsManager::RestoreSnapshotByNumFramesOffset: unlock");
	this->UnlockMutex();
}

void CSnapshotsManager::RestoreSnapshotBackstepInstruction()
{
	LOGD("CSnapshotsManager::RestoreSnapshotBackstepInstruction");
	this->LockMutex();
	LOGS("CSnapshotsManager::RestoreSnapshotBackstepInstruction: locked");
	
//	int currentFrame = debugInterface->GetEmulationFrameNumber();
//	int restoreToFrame = currentFrame-1;
//
//	int minFrame, maxFrame;
//	GetFramesLimits(&minFrame, &maxFrame);
//
//	if (restoreToFrame <= minFrame)
//	{
//		LOGS("CSnapshotsManager::RestoreSnapshotBackstepInstruction: unlock");
//		this->UnlockMutex();
//		return;
//	}
	
//	LOGD(">>>>>>>>>................ currentFrame=%d restoreToFrame=%d", currentFrame, restoreToFrame);

	unsigned int previousInstructionClk = debugInterface->GetPreviousCpuInstructionCycleCounter();
	
	LOGD(">>>>>>>>>................ previousInstructionClk=%d", previousInstructionClk);
	
//	debugInterface->snapshotsManager->RestoreSnapshotByFrame(restoreToFrame, previousInstructionClk);
	debugInterface->snapshotsManager->RestoreSnapshotByCycle(previousInstructionClk);
	
	LOGS("CSnapshotsManager::RestoreSnapshotBackstepInstruction: unlock");
	this->UnlockMutex();
}

bool CSnapshotsManager::SkipRefreshOfVideoFrame()
{
//	if (skipFrameRender)
//	{
//		int targetFrame = debugInterface->GetEmulationFrameNumber()+1;
//		if (pauseNumFrame == targetFrame)
//		{
////			LOGD("SkipRefreshOfVideoFrame: FALSE: pauseNumFrame=%d targetFrame=%d", pauseNumFrame, targetFrame);
//			return false;
//		}
//	}
//	LOGD("SkipRefreshOfVideoFrame: %s", STRBOOL(skipFrameRender));
	return skipFrameRender;
}

void CSnapshotsManager::GetFramesLimits(int *minFrame, int *maxFrame)
{
	this->LockMutex();
	
	if (chipSnapshotsByFrame.size() < 1)
	{
		*minFrame = 0;
		*maxFrame = 0;
		this->UnlockMutex();
		return;
	}
	
	std::map<u32, CStoredChipsSnapshot *>::iterator itFirst = chipSnapshotsByFrame.begin();
	*minFrame = itFirst->first;

	std::map<u32, CStoredChipsSnapshot *>::iterator itLast = --chipSnapshotsByFrame.end();
	*maxFrame = itLast->first;
	
	this->UnlockMutex();
}


void CSnapshotsManager::SetRecordingIsActive(bool isActive)
{
	debugInterface->LockMutex();

	this->ClearSnapshotsHistory();
	c64SettingsSnapshotsRecordIsActive = isActive;

	debugInterface->UnlockMutex();
}

void CSnapshotsManager::SetRecordingStoreInterval(int recordingInterval)
{
	if (recordingInterval < 1)
	{
		recordingInterval = 1;
	}
	debugInterface->LockMutex();
	this->ClearSnapshotsHistory();
	c64SettingsSnapshotsIntervalNumFrames = recordingInterval;
	debugInterface->UnlockMutex();
}

void CSnapshotsManager::SetRecordingLimit(int recordingLimit)
{
	if (recordingLimit < 2)
	{
		recordingLimit = 2;
	}
	debugInterface->LockMutex();
	this->ClearSnapshotsHistory();
	c64SettingsSnapshotsLimit = recordingLimit;
	debugInterface->UnlockMutex();
}


void CSnapshotsManager::DebugPrintDiskSnapshots()
{
	LOGD(" ====== CSnapshotsManager::DebugPrintDiskSnapshots   DISKS ======");
	for (std::map<u32, CStoredDiskSnapshot *>::iterator it = diskSnapshotsByFrame.begin(); it != diskSnapshotsByFrame.end(); it++)
	{
		CStoredDiskSnapshot *diskSnapshot = it->second;
		
		LOGD("    | frame=%d ref=%d %x", diskSnapshot->frame, diskSnapshot->numLinkedChipsSnapshots, diskSnapshot);
	}
	LOGD("  diskSnapshotsToReuse=%d", diskSnapshotsToReuse.size());
	LOGD(" ===============================");

}

void CSnapshotsManager::DebugPrintChipsSnapshots()
{
	LOGD(" ====== CSnapshotsManager::DebugPrintChipsSnapshots   CHIPS ======");
	for (std::map<u32, CStoredChipsSnapshot *>::iterator it = chipSnapshotsByFrame.begin(); it != chipSnapshotsByFrame.end(); it++)
	{
		CStoredChipsSnapshot *chipsSnapshot = it->second;
		
		LOGD("    | frame=%d %x  disk frame=%d", chipsSnapshot->frame, chipsSnapshot, chipsSnapshot->diskSnapshot->frame);
	}
	LOGD(" ===============================");
}

void CSnapshotsManager::LockMutex()
{
//	LOGD("CSnapshotsManager::LockMutex");
	debugInterface->LockMutex();
//	mutex->Lock();
//	LOGD("CSnapshotsManager::LockMutex locked");
}

void CSnapshotsManager::UnlockMutex()
{
//	LOGD("CSnapshotsManager::UnlockMutex");
	debugInterface->UnlockMutex();
//	mutex->Unlock();
//	LOGD("CSnapshotsManager::UnlockMutex unlocked");
}

bool CSnapshotsManager::RestoreSnapshotByCycle(u64 cycle)
{
	LOGD("CSnapshotsManager::RestoreSnapshotByCycle: cycle=%d", cycle);
	// TODO: fixme and reuse code considering that we have found the snapshot, thus pass it further
	//       the RestoreSnapshotByFrame searches this again, so it is twice.
	
	// to have this working we need to find cycle within frame, i.e. iterate over frames to find cycle
	this->LockMutex();

	if (snapshotToRestore)
	{
		LOGS("RestoreSnapshotByFrame: UnlockMutex (1)");
		this->UnlockMutex();
		return false;
	}
	
	if (chipSnapshotsByFrame.empty())
	{
		LOGS("RestoreSnapshotByFrame: UnlockMutex (2)");
		this->UnlockMutex();
		return false;
	}

	LOGD("***** CSnapshotsManager::RestoreSnapshotByCycle cycle=%d ***", cycle);

	std::map<u32, CStoredChipsSnapshot *>::iterator it = chipSnapshotsByFrame.begin();
	CStoredChipsSnapshot *nearestChipSnapshot = NULL;

	//if (frame == 0)
	{
		nearestChipSnapshot = it->second;
	}
	
	// find nearest snapshot frame, just go through list now. TODO: optimize this
	for( ; it != chipSnapshotsByFrame.end(); it++)
	{
		CStoredChipsSnapshot *chipSnapshot = it->second;
		
		if (chipSnapshot->cycle < cycle)
		{
			nearestChipSnapshot = chipSnapshot;
		}
	}
	
	if (nearestChipSnapshot == NULL)
	{
		this->UnlockMutex();
		return false;
	}

	LOGD(".... FOUND nearestChipSnapshot->cycle=%d, run to cycle=%d", nearestChipSnapshot->cycle, cycle);

	LOGD("RestoreSnapshotByCycle: OK run RestoreSnapshotByFrame frame=%d cycle=%d", nearestChipSnapshot->frame, cycle);
	bool ret = RestoreSnapshotByFrame(nearestChipSnapshot->frame-2, cycle);
	
	this->UnlockMutex();
	
	return ret;
}

