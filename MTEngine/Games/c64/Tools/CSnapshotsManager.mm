#include "CSnapshotsManager.h"
#include "SYS_Threading.h"
#include "VID_Main.h"
#include "CGuiMain.h"
#include "SND_SoundEngine.h"
#include "C64SettingsStorage.h"

/// TODO:

//DONE: zmiana dyskietki  ->  zapisywac zmiany dyskietek / modul osobno i przy przewijaniu wczytac modul dyskietki ostatni dobry (?)
//TRZYMAC MODUL DYSKIETKI int c64_snapshot_read_from_memory(int event_mode, int read_roms, int read_disks, int read_reu_data, unsigned char *snapshot_data, int snapshot_size)
//
//DONE:  GCR_dirty_track_for_snapshot P64_dirty_for_snapshot
//
//DONE: c64_snapshot_write_in_memory -> confirm if store disk state is OK, or we should only store *disk contents*... nope we need to store full state
//
//TODO BUG: when rewind the F7 disk directory view is not updated

// TODO: rewriting map frame snapshot...  (?)
// DONE?: attach regular snapshots -> clear rewind data
// DONE?: store roms on cart change
// TODO: what to do with REU?

//CPU JAM - odwieszanie przy przewijaniu ?
//DONE?: DUMP all snapshots & history => fix problem with cycle on frame# change

extern "C" {
extern volatile unsigned int c64d_previous_instruction_maincpu_clk;
extern volatile unsigned int c64d_previous2_instruction_maincpu_clk;
};

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

void CStoredSnapshot::Use(u32 frame, u32 cycle)
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

CStoredDiskSnapshot::CStoredDiskSnapshot(CSnapshotsManager *manager, u32 frame, u32 cycle)
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
	LOGD("CStoredDiskSnapshot::RemoveReference: numLinkedChipsSnapshots=%d", numLinkedChipsSnapshots);
	this->numLinkedChipsSnapshots--;

	manager->DebugPrintDiskSnapshots();
	
	if (this->numLinkedChipsSnapshots == 0)
	{
		LOGD("CStoredDiskSnapshot::RemoveReference linked=0, Clear");
		manager->diskSnapshotsByFrame.erase(this->frame);
		manager->diskSnapshotsToReuse.push_back(this);
		this->ClearSnapshot();
	}

	LOGD("CStoredDiskSnapshot::RemoveReference finished: numLinkedChipsSnapshots=%d", numLinkedChipsSnapshots);
}


CStoredChipsSnapshot::CStoredChipsSnapshot(CSnapshotsManager *manager, u32 frame, u32 cycle, CStoredDiskSnapshot *diskSnapshot)
: CStoredSnapshot(manager)
{
	this->Use(frame, cycle, diskSnapshot);
}

void CStoredChipsSnapshot::Use(u32 frame, u32 cycle, CStoredDiskSnapshot *diskSnapshot)
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
	lastStoredFrameCounter = 0;
	
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

extern "C" {
	unsigned int c64d_get_vice_maincpu_clk();
	void c64d_refresh_screen_no_callback();
}

// CheckSnapshotInterval should be run each frame from within code that can store snapshots,
// check if we are exactly in a new frame cycle should be done by the caller
bool CSnapshotsManager::CheckSnapshotInterval()
{
//	LOGD("CSnapshotsManager::CheckSnapshotInterval");
	
	if (snapshotToRestore || pauseNumCycle != -1) // || skipSavingSnapshots)
		return false;
	
	u32 currentFrame = debugInterface->GetEmulationFrameNumber();
	
	if (pauseNumFrame == currentFrame)
	{
		LOGD("pauseNumFrame == currentFrame");
		debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
		pauseNumFrame = -1;
		skipFrameRender = false;
		c64d_refresh_screen_no_callback();
		isPerformingSnapshotRestore = false;
		return false;
	}

	if (c64SettingsSnapshotsRecordIsActive == false)
		return false;

	lastStoredFrameCounter++;
	
	// check if we should store snapshot (the frame interval is hit)
	if (lastStoredFrameCounter >= c64SettingsSnapshotsIntervalNumFrames)
	{
		LOGD("CSnapshotsManager::CheckSnapshotInterval: LockMutex");
		this->LockMutex();
		
		if (snapshotToRestore == NULL)
		{
			LOGD("CSnapshotsManager::CheckSnapshotInterval: snapshotToRestore=NULL");

			isPerformingSnapshotRestore = false;
			lastStoredFrameCounter = 0;
			
			u32 currentCycle = c64d_get_vice_maincpu_clk();
			
			LOGD("CSnapshotsManager::CheckSnapshotInterval: store snapshot, currentFrame=%d", currentFrame);
			lastStoredFrame = currentFrame;
			
			long t1 = SYS_GetCurrentTimeInMillis();
			
			// we are in CPU interrupt check, we can safely store snapshot now
			if (currentDiskSnapshot == NULL
				|| debugInterface->IsDriveDirtyForSnapshot())
			{
				LOGD("....... create new disk snapshot");
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
				
				DebugPrintDiskSnapshots();
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
			
			LOGD("CSnapshotsManager stored snapshot t=%d", t2-t1);
		}
		
		LOGD("CSnapshotsManager::CheckSnapshotInterval: UnlockMutex");

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
	LOGD("CSnapshotsManager::RestoreSnapshot");
	this->LockMutex();

	snapshotToRestore = snapshot;
	
	this->UnlockMutex();

	LOGD("CSnapshotsManager::RestoreSnapshot done");
}

void CSnapshotsManager::CheckMainCpuCycle()
{
//	LOGD("CSnapshotsManager::CheckMainCpuCycle");
	
	if (snapshotToRestore)
		return;
	
	if (pauseNumCycle == -1)
		return;

	u32 currentCycle = c64d_get_vice_maincpu_clk();

	LOGD("previous_instr_maincpu_clk=%d pauseNumCycle=%d maincpu_clk=%d",  c64d_previous_instruction_maincpu_clk, pauseNumCycle, currentCycle);
	
	if (pauseNumCycle <= currentCycle)
	{
		LOGD("STOP: pauseNumCycle=%d currentCycle=%d frame=%d", pauseNumCycle, currentCycle, debugInterface->GetEmulationFrameNumber());
		debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
		pauseNumCycle = -1;
		pauseNumFrame = -1;
		skipFrameRender = false;
		c64d_refresh_screen_no_callback();
		isPerformingSnapshotRestore = false;
	}
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
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!! RESTORING SNAPSHOT frame=%d", snapshotToRestore->frame);
		
		gSoundEngine->LockMutex("CSnapshotsManager::CheckSnapshotRestore: restore snapshot");

		// restore disk
		CStoredDiskSnapshot *diskSnapshot = snapshotToRestore->diskSnapshot;
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!!     -> diskSnapshot frame=%d", diskSnapshot->frame);
		debugInterface->LoadDiskDataSnapshotSynced(diskSnapshot->byteBuffer);
		
		debugInterface->LoadChipsSnapshotSynced(snapshotToRestore->byteBuffer);
		
		snapshotToRestore = NULL;
		
		LOGD("!!!!!!!!!!!!!!!!!!!!!!!!     restored, currentFrame=%d %d", debugInterface->GetEmulationFrameNumber(), pauseNumFrame);

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
bool CSnapshotsManager::RestoreSnapshotByFrame(int frame, int cycleNum)
{
	LOGD("RestoreSnapshotByFrame: %d %d, LockMutex", frame, cycleNum);
	this->LockMutex();

	if (snapshotToRestore)
	{
		LOGD("RestoreSnapshotByFrame: UnlockMutex (1)");
		this->UnlockMutex();
		return false;
	}
	
	if (chipSnapshotsByFrame.empty())
	{
		LOGD("RestoreSnapshotByFrame: UnlockMutex (2)");
		this->UnlockMutex();
		return false;
	}

	LOGD("***** CSnapshotsManager::RestoreSnapshotByFrame frame=%d ***", frame);

	isPerformingSnapshotRestore = true;

	if (frame < 0)
		frame = 0;
	
	LOGD("frame=%d", frame);
	
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
		
		if (chipSnapshot->frame <= frame)
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
		LOGD(".... found snapshot frame %d", nearestChipSnapshot->frame);
		snapshotToRestore = nearestChipSnapshot;
	}
	
	lastStoredFrameCounter = 0;
	
	if (pauseNumFrame != -1 || debugInterface->GetDebugMode() == DEBUGGER_MODE_PAUSED)
	{
		LOGD("nearestChipSnapshot->frame=%d frame=%d", nearestChipSnapshot->frame, frame);
		if (nearestChipSnapshot->frame < frame)
		{
			LOGD("......... nearestChipSnapshot->frame=%d but we are looking for %d", nearestChipSnapshot->frame, frame);
			
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
			LOGD("... found frame, going to cycle cycleNum=%d", cycleNum);
			if (cycleNum == -1)
			{
				skipFrameRender = false;
				pauseNumCycle = -1;
				pauseNumFrame = -1;
				debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
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
	
	LOGD("RestoreSnapshotByFrame: UnlockMutex (3)");
	this->UnlockMutex();

	return true;
}

bool CSnapshotsManager::IsPerformingSnapshotRestore()
{
	return this->isPerformingSnapshotRestore;
}

CStoredChipsSnapshot *CSnapshotsManager::GetNewChipSnapshot(u32 frame, u32 cycle, CStoredDiskSnapshot *diskSnapshot)
{
	LOGD("*************************** CSnapshotsManager::GetNewChipSnapshot: frame=%d        << CHIPS", frame);

	LOGD("chipSnapshotsByFrame=%d chipSnapshotsLimit=%d chipsSnapshotsToReuse=%d", chipSnapshotsByFrame.size(), c64SettingsSnapshotsLimit, chipsSnapshotsToReuse.size());
	LOGD("diskSnapshotsByFrame=%d diskSnapshotsToReuse=%d", diskSnapshotsByFrame.size(), diskSnapshotsToReuse.size());
	
	CStoredChipsSnapshot *chipSnapshot = NULL;
	
	std::map<u32, CStoredChipsSnapshot *>::iterator it = chipSnapshotsByFrame.find(frame);

	if (it == chipSnapshotsByFrame.end())
	{
		int f = chipSnapshotsByFrame.size();
		
		if (f < c64SettingsSnapshotsLimit)
		{
			LOGD("...create new CStoredChipsSnapshot");
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
			LOGD("...reuse CStoredChipsSnapshot chipsSnapshotsToReuse.size=%d", chipsSnapshotsToReuse.size());
			int s = chipsSnapshotsToReuse.size();

			LOGD("s=%d", s);
			
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

	LOGD("CSnapshotsManager::GetNewChipSnapshot: done");
	return chipSnapshot;
}

CStoredDiskSnapshot *CSnapshotsManager::GetNewDiskSnapshot(u32 frame, u32 cycle)
{
	LOGD("*************************** CSnapshotsManager::GetNewDiskSnapshot: frame=%d        << DISK", frame);
	LOGD("diskSnapshotsToReuse=%d", diskSnapshotsToReuse.size());
	
	CStoredDiskSnapshot *diskSnapshot = NULL;
	
	if (diskSnapshotsToReuse.size() == 0)
	{
		LOGD("...create new CStoredDiskSnapshot");
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
		LOGD("...reuse CStoredDiskSnapshot");
		diskSnapshot = diskSnapshotsToReuse.front();
		
		diskSnapshotsToReuse.pop_front();

		diskSnapshot->ClearSnapshot();
		diskSnapshot->Use(frame, cycle);
	}
	
	LOGD("CSnapshotsManager::GetNewDiskSnapshot: done");
	return diskSnapshot;
}

void CSnapshotsManager::ClearSnapshotsHistory()
{
	LOGD("CSnapshotsManager::ClearSnapshotsHistory");
	// this will completely remove all history, used when new PRG is loaded or cart is inserted/detached
	
	this->LockMutex();
	LOGD("CSnapshotsManager::ClearSnapshotsHistory: locked");
	
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

	lastStoredFrameCounter = 0;
	pauseNumCycle = -1;
	pauseNumFrame = -1;
	skipFrameRender = false;

	LOGD("CSnapshotsManager::ClearSnapshotsHistory: Unlock");
	this->UnlockMutex();
}

void CSnapshotsManager::RestoreSnapshotByNumFramesOffset(int numFramesOffset)
{
	LOGD("CSnapshotsManager::RestoreSnapshotByNumFramesOffset: numFramesOffset=%d", numFramesOffset);
	this->LockMutex();
	
	LOGD("CSnapshotsManager::RestoreSnapshotByNumFramesOffset: locked");
	int currentFrame = debugInterface->GetEmulationFrameNumber();
	int restoreToFrame = currentFrame + numFramesOffset;
	
	if (restoreToFrame < 0)
		restoreToFrame = 0;
	
	LOGD(">>>>>>>>>................ currentFrame=%d restoreToFrame=%d", currentFrame, restoreToFrame);
	debugInterface->snapshotsManager->RestoreSnapshotByFrame(restoreToFrame, -1);

	LOGD("CSnapshotsManager::RestoreSnapshotByNumFramesOffset: unlock");
	this->UnlockMutex();
}

void CSnapshotsManager::RestoreSnapshotBackstepInstruction()
{
	LOGD("CSnapshotsManager::RestoreSnapshotBackstepInstruction");
	this->LockMutex();
	LOGD("CSnapshotsManager::RestoreSnapshotBackstepInstruction: locked");
	
	int currentFrame = debugInterface->GetEmulationFrameNumber();
	int restoreToFrame = currentFrame-1;
	
	if (restoreToFrame < 0)
		restoreToFrame = 0;
	
	unsigned int viceMainCpuClk = c64d_get_vice_maincpu_clk();
	unsigned int previousInstructionClk = c64d_previous_instruction_maincpu_clk;
	unsigned int previous2InstructionClk = c64d_previous2_instruction_maincpu_clk;
	LOGD(">>>>>>>>>................ currentFrame=%d restoreToFrame=%d previous_inst_clk=%d previous2InstructionClk=%d | mainclk=%d", currentFrame, restoreToFrame, previousInstructionClk, previous2InstructionClk, viceMainCpuClk);
	
	if (previousInstructionClk == viceMainCpuClk)
	{
		LOGWarning("previousInstructionClk=%d == viceMainCpuClk=%d, previousInstructionClk will be previous2InstructionClk=%d", previousInstructionClk, viceMainCpuClk, previous2InstructionClk);
		
		// snapshot was recently restored and debug pause was moved forward or we have no data (i.e. snapshot restored etc)
		previousInstructionClk = previous2InstructionClk;
	}
	
	
	debugInterface->snapshotsManager->RestoreSnapshotByFrame(restoreToFrame, previousInstructionClk);
	
	LOGD("CSnapshotsManager::RestoreSnapshotBackstepInstruction: unlock");
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
	// snapshot was not found, not possible to restore
	return false;
}

