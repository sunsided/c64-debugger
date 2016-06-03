#ifndef _SYS_ACCELEROMETER_H_
#define _SYS_ACCELEROMETER_H_

class CAccelerometerListener
{
public:
	virtual void ProcessAcceleration(float x, float y, float z);
};

void SYS_InitAccelerometer();
void SYS_StartAccelerometer();
void SYS_StopAccelerometer();
void SYS_AddAccelerometerListener(CAccelerometerListener *callback);
void SYS_RemoveAccelerometerListener(CAccelerometerListener *callback);
void SYS_ProcessAccelerometerListeners(float x, float y, float z);

#endif
