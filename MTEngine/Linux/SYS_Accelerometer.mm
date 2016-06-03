#include "DBG_Log.h"
#include "SYS_Accelerometer.h"
#include <pthread.h>
#include <list>

//#define ACCELEROMETER_TWEAK_VALUES 0.083

std::list<CAccelerometerListener *> accelerometerListeners;
pthread_mutex_t accelerometerListenersMutex;
volatile bool accelerometerInit = false;

void SYS_InitAccelerometer()
{
	LOGD("SYS_InitAccelerometer()");
	accelerometerListeners.clear();
	pthread_mutex_init(&accelerometerListenersMutex, NULL);

	//[gAppDelegate initAccelerometer];
	accelerometerInit = true;
}

void SYS_StartAccelerometer()
{
	LOGD("SYS_StartAccelerometer()");
	if (accelerometerInit == false)
		SYS_InitAccelerometer();

	//[gAppDelegate startAccelerometer];
}

void SYS_StopAccelerometer()
{
	LOGD("SYS_StopAccelerometer()");
	//[gAppDelegate stopAccelerometer];
}

void LockAccelerometerListenersListMutex()
{
#ifdef LOG_ACCEL_LIST
	LOGD("LockAccelerometerListenersListMutex");
#endif

	pthread_mutex_lock(&accelerometerListenersMutex);
}

void UnlockAccelerometerListenersListMutex()
{
#ifdef LOG_ACCEL_LIST
	LOGD("UnlockAccelerometerListenersListMutex");
#endif

	pthread_mutex_unlock(&accelerometerListenersMutex);
}

void SYS_AddAccelerometerListener(CAccelerometerListener *callback)
{
	LockAccelerometerListenersListMutex();
	accelerometerListeners.push_back(callback);
	UnlockAccelerometerListenersListMutex();
}

void SYS_RemoveAccelerometerListener(CAccelerometerListener *callback)
{
	LockAccelerometerListenersListMutex();
	accelerometerListeners.remove(callback);
	UnlockAccelerometerListenersListMutex();
}

void SYS_ProcessAccelerometerListeners(float x, float y, float z)
{
//	LOGD("SYS_ProcessAccelerometerListeners: x=%f y=%f z=%f", x, y, z);
	
//	x *= ACCELEROMETER_TWEAK_VALUES;
//	y *= ACCELEROMETER_TWEAK_VALUES;
//	z *= ACCELEROMETER_TWEAK_VALUES;

	LockAccelerometerListenersListMutex();
	for (std::list<CAccelerometerListener *>::iterator itListener = accelerometerListeners.begin();
			itListener != accelerometerListeners.end(); itListener++)
	{
		CAccelerometerListener *listener = *itListener;

		listener->ProcessAcceleration(x, y, z);
	}
	UnlockAccelerometerListenersListMutex();
}

void CAccelerometerListener::ProcessAcceleration(float x, float y, float z)
{
}

