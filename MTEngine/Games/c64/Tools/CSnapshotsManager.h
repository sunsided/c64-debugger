#ifndef _CSNAPSHOTSMANAGER_H_
#define _CSNAPSHOTSMANAGER_H_

#include "CDebugInterface.h"

class CSnapshotsManager;

class CStoredSnapshot
{
public:
	CStoredSnapshot(CSnapshotsManager *manager);
	virtual ~CStoredSnapshot();
	
	CSnapshotsManager *manager;
	
	virtual void Use(u32 frame, u64 cycle);
	virtual void ClearSnapshot();
	
	CByteBuffer *byteBuffer;
	
	u32 frame;
	u64 cycle;
};

class CStoredDiskSnapshot : public CStoredSnapshot
{
public:
	CStoredDiskSnapshot(CSnapshotsManager *manager, u32 frame, u64 cycle);
	
	int numLinkedChipsSnapshots;
	
	void AddReference();
	void RemoveReference();
};

class CStoredChipsSnapshot : public CStoredSnapshot
{
public:
	CStoredChipsSnapshot(CSnapshotsManager *manager, u32 frame, u64 cycle, CStoredDiskSnapshot *diskSnapshot);
	
	virtual void Use(u32 frame, u64 cycle, CStoredDiskSnapshot *diskSnapshot);
	
	CStoredDiskSnapshot *diskSnapshot;

	virtual void ClearSnapshot();
};


class CSnapshotsManager
{
public:
	CSnapshotsManager(CDebugInterface *debugInterface);
	~CSnapshotsManager();
	
	CDebugInterface *debugInterface;
	
	std::map<u32, CStoredChipsSnapshot *> chipSnapshotsByFrame;
	std::list<CStoredChipsSnapshot *> chipsSnapshotsToReuse;

	std::map<u32, CStoredDiskSnapshot *> diskSnapshotsByFrame;
	std::list<CStoredDiskSnapshot *> diskSnapshotsToReuse;
	
	virtual bool CheckSnapshotInterval();
	
	CStoredDiskSnapshot *currentDiskSnapshot;
	
	CStoredChipsSnapshot *snapshotToRestore;
	virtual bool CheckSnapshotRestore();
	
	virtual void StoreSnapshot();
	virtual void RestoreSnapshot(CStoredChipsSnapshot *snapshot);
	virtual bool RestoreSnapshotByFrame(int frame, long cycleNum);
	virtual bool RestoreSnapshotByCycle(u64 cycle);
	
	CStoredChipsSnapshot *GetNewChipSnapshot(u32 frame, u64 cycle, CStoredDiskSnapshot *diskSnapshot);
	CStoredDiskSnapshot *GetNewDiskSnapshot(u32 frame, u64 cycle);
	
	bool CheckMainCpuCycle();
	
	void ResetLastStoredFrameCounter();
	void ClearSnapshotsHistory();
	
	void RestoreSnapshotByNumFramesOffset(int numFramesOffset);
	void RestoreSnapshotBackstepInstruction();
	
	int pauseNumFrame;
	long pauseNumCycle;
	volatile bool skipFrameRender;
	bool SkipRefreshOfVideoFrame();
	
	volatile bool isPerformingSnapshotRestore;
	bool IsPerformingSnapshotRestore();
	void CancelRestore();
	
//	volatile bool skipSavingSnapshots;
	
	void LockMutex();
	void UnlockMutex();
	
	void DebugPrintDiskSnapshots();
	void DebugPrintChipsSnapshots();

	void SetRecordingIsActive(bool isActive);
	void SetRecordingStoreInterval(int recordingInterval);
	void SetRecordingLimit(int recordingLimit);
	
	void GetFramesLimits(int *minFrame, int *maxFrame);

//	void StoreToFile(CSlrString *filePath);
//	void RestoreFromFile(CSlrString *filePath);

private:
	CSlrMutex *mutex;
	u32 lastStoredFrame;
	u32 lastStoredFrameCounter;
};

#endif //_CSNAPSHOTSMANAGER_H_

